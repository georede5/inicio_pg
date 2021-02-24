

-- ############################################################################
-- INSERT TRIGGER nas LINHAS
-- ############################################################################

CREATE OR REPLACE FUNCTION base.linhas_insert()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_start geometry;
	v_end geometry;
	v_testpt geometry;
	v_tol numeric;
	v_rec1 record;
	v_rec2 record;
	v_rec0 record;
	v_node_count integer;
	v_srid integer;
	v_node_gid uuid;
BEGIN
	-- Registar utilizador responsável pela criação do elemento
	NEW.utilizador := current_user;
	
	-- Obter tolerancia de pesquisa de proximidade entre elementos
	SELECT valor::NUMERIC into v_tol
	FROM base.config
	where parametro = 'TOLERANCIA';

	SELECT valor::int into v_srid
	FROM base.config
	where parametro = 'SRID';

	-- Obter os pontos inicial e final da nova linha
	select ST_StartPoint(NEW.geom) Into v_start;
	select ST_EndPoint(NEW.geom) Into v_end;

	-- Comprimento da nova linha tem de ser,
	--	no mínimo, o dobro da tolerância
	if ST_Length(NEW.geom) < 2.0 * v_tol then
		return null;
	end if;

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
		
		-- Encontrar linhas proximas do ponto corrente (inicial ou final)
		for v_rec1 in (
			select gid, geom
			from base.linhas l
			where ST_DWithin(l.geom, v_rec0.geom, v_tol)
			and ST_Length(geom) > v_tol
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
				v_node_gid := null;
			
				select gid into v_node_gid
				from base.nos n
				where st_DWithin(n.geom, v_testpt, v_tol)
				LIMIT 1;
			
				-- Se ambos os pontos forem proximos ...
				if st_distance(v_testpt, v_rec0.geom) < v_tol then
				
					-- Ajustar o ponto correspondente da nova linha  para cima do ponto da linha proxima a ser testado
					NEW.geom := ST_SetSRID(ST_SetPoint(NEW.geom, v_rec0.ord, v_testpt), v_srid);

					if v_node_gid is null then
						insert into base.nos
						(geom) values (v_testpt)
						returning gid into v_node_gid;
					end if;
				
					-- popular tabela de ligacao ente no corrente (possivelmente acabado de criar) e a nova linhas
					begin
						insert into base.nos_linhas
						(no_gid, linha_gid, ordem)
						values (v_node_gid, NEW.gid, v_rec0.ord);
					exception
						when unique_violation then
							null;
					end;

					-- garantir que a outra linha esta representada na tabela de ligacao
					begin
						insert into base.nos_linhas
						(no_gid, linha_gid, ordem)
						values (v_node_gid, v_rec1.gid, v_rec2.ord);
					exception
						when unique_violation then
							null;
					end;

				end if; -- st_distance(v_testpt, v_rec3.geom) < v_tol 
				
			end loop; -- v_rec2

		end loop; -- v_rec1

	end loop; -- v_rec0
		
RETURN NEW;
END;
$function$;

ALTER FUNCTION base.linhas_insert() OWNER TO georede5;
