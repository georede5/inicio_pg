CREATE OR REPLACE FUNCTION base.criar_associar_nos(p_new_line_geom geometry, p_new_line_gid uuid)
 RETURNS geometry
 LANGUAGE plpgsql
AS $function$

declare
	v_ret geometry;
	v_start geometry;
	v_end geometry;
	v_testpt geometry;
	v_term_geom geometry;
	v_tol numeric;
	v_dist numeric;
	v_rec1 record;
	v_rec2 record;
	v_rec0 record;
	v_node_count integer;
	v_srid integer;
	v_node_gid uuid;
	v_term_gid uuid;
	v_newnode bool;
	v_linha_mais_proxima_gid uuid;
	v_ponto_mais_proximo_geom geometry;
	v_linhas_proximas_gid uuid[];
	v_linhas_proximas_ord int[];
	v_mindist_linha_mais_proxima numeric;
	v_npts integer;
begin
	v_ret := null;
	
	-- Obter tolerancia de pesquisa de proximidade entre elementos
	SELECT valor::NUMERIC into v_tol
	FROM base.config
	where parametro = 'TOLERANCIA';

	SELECT valor::int into v_srid
	FROM base.config
	where parametro = 'SRID';

	-- Comprimento da nova linha tem de ser,
	--	no mínimo, o dobro da tolerância
	if ST_Length(p_new_line_geom) < 2.0 * v_tol then
		raise notice 'comprimento (%) abaixo do mínimo permitido: %', ST_Length(p_new_line_geom), 2.0 * v_tol;
		return v_ret;
	end if;

	v_ret := p_new_line_geom;

	-- Obter os pontos inicial e final da nova linha
	select ST_StartPoint(p_new_line_geom) Into v_start;
	select ST_EndPoint(p_new_line_geom) Into v_end;

	-- loop entre ponto inicial e final
	for v_rec0 in (			
		with presel2 as (
			select 0 ord, v_start geom
			union
			select 1 ord, v_end geom
		)
		select ord, geom from presel2
		order by ord
	) loop

		v_mindist_linha_mais_proxima := 999999999;
		v_linhas_proximas_gid := ARRAY[]::uuid[];
		v_linhas_proximas_ord := ARRAY[]::int[];
		v_linha_mais_proxima_gid := null;
		v_ponto_mais_proximo_geom := null;

		-- Encontrar linhas proximas do ponto corrente (inicial ou final)
		for v_rec1 in (
			select gid, geom
			from base.linhas l
			where ST_DWithin(l.geom, v_rec0.geom, v_tol)
			and ST_Length(geom) > v_tol
			and gid != p_new_line_gid
		) loop
	
			-- loop entre ponto inicial e final de cada linha proxima encontrada
			for v_rec2 in (			
				with presel1 as (
					select 0 ord, ST_StartPoint(v_rec1.geom) geom
					union
					select 1 ord, ST_EndPoint(v_rec1.geom) geom
				)
				select ord, geom from presel1
				order by ord
			) loop
		
				-- Obter os pontos inicial e final da linha proxima encontrada
				v_testpt := v_rec2.geom;			
				v_dist := st_distance(v_testpt, v_rec0.geom);
			
				-- Se ambos os pontos forem proximos ...
				if v_dist < v_tol then

					v_linhas_proximas_gid := v_linhas_proximas_gid || v_rec1.gid;
					v_linhas_proximas_ord := v_linhas_proximas_ord || v_rec2.ord;
			
					if v_dist < v_mindist_linha_mais_proxima then
						v_mindist_linha_mais_proxima := v_dist;
						v_linha_mais_proxima_gid := v_rec1.gid;
						v_ponto_mais_proximo_geom := v_rec2.geom;
					
					end if;
				end if; -- st_distance(v_testpt, v_rec3.geom) < v_tol 
				
			end loop; -- v_rec2

		end loop; -- v_rec1
		
		-- para um dado ponto extremo da nova linha
		if not v_ponto_mais_proximo_geom is null and not v_linha_mais_proxima_gid is null then

			v_node_gid := null;
		
			FOR i IN 1 .. array_upper(v_linhas_proximas_gid, 1) loop
				delete from base.terminais
				where linha_gid = v_linhas_proximas_gid[i]
				and ordem = v_linhas_proximas_ord[i];
			end loop; 
	
			delete from base.terminais
			where linha_gid = p_new_line_gid
			and ordem = v_rec0.ord;
					
			-- Ajustar o ponto da nova linha para cima do ponto da linha mais proxima encontrada
			if v_rec0.ord = 0 then
				v_ret := ST_SetSRID(ST_SetPoint(p_new_line_geom, 0, v_ponto_mais_proximo_geom), v_srid);
			else
				v_npts := ST_NPoints(p_new_line_geom);
				v_ret := ST_SetSRID(ST_SetPoint(p_new_line_geom, v_npts-1, v_ponto_mais_proximo_geom), v_srid);
			end if;

			if ST_Length(v_ret) < 2.0 * v_tol then
				raise notice 'comprimento (%) abaixo do mínimo permitido: %', ST_Length(v_ret), 2.0 * v_tol;
				v_ret := null;
				return v_ret;
			end if;
		
			-- procurar nó próximo
			select gid into v_node_gid
			from base.nos n
			where st_DWithin(n.geom, v_ponto_mais_proximo_geom, v_tol)
			LIMIT 1;
		
			v_newnode := false;

			-- Criar nó se não existir
			if v_node_gid is null then
			
				v_node_gid := uuid_generate_v4();
				insert into base.nos
				(gid, geom) values (v_node_gid, v_ponto_mais_proximo_geom);
			
				v_newnode := true;
			
			end if;

			-- popular tabela de ligacao com no corrente (possivelmente acabado de criar) e a nova linha
			insert into base.nos_linhas
			(no_gid, linha_gid, ordem)
			values (v_node_gid, p_new_line_gid, v_rec0.ord)
			on conflict on constraint nos_linhas_pkey do nothing;
				
			-- garantir que todas as linhas próximas ficam representadas na tabela de ligacao para o novo no'
			if v_newnode then
				FOR i IN 1 .. array_upper(v_linhas_proximas_gid, 1) loop
					insert into base.nos_linhas
					(no_gid, linha_gid, ordem)
					values (v_node_gid, v_linhas_proximas_gid[i], v_linhas_proximas_ord[i])
					on conflict on constraint nos_linhas_pkey do nothing;
				end loop; -- for
			end if;
		
		else -- é um TERMINAL - aberto -- v_ponto_mais_proximo_geom is null or v_linha_mais_proxima_gid is null
		
			-- Verificar se o terminal já existe
			select gid into v_term_gid
			from base.terminais
			where linha_gid = p_new_line_gid
			and ordem = v_rec0.ord;
		
			if v_term_gid is null then

				-- Criar terminal 
				v_term_gid := uuid_generate_v4();			
	
				insert into base.terminais (gid, geom, tipo, linha_gid, ordem) 
				values (v_term_gid, v_rec0.geom, 'aberto', p_new_line_gid, v_rec0.ord);
		
			else
			
				if v_rec0.ord = 0 then
					v_term_geom := ST_StartPoint(p_new_line_geom);
				else
					v_term_geom := ST_EndPoint(p_new_line_geom);
				end if;
			
				update base.terminais
				set geom = v_term_geom
				where linha_gid = p_new_line_gid
				and ordem = v_rec0.ord;
			
			end if;
		
		end if;

	end loop; -- v_rec0

	return v_ret;
END;
$function$
;

-- Permissions

ALTER FUNCTION base.criar_associar_nos(geometry,uuid) OWNER TO georede5;

