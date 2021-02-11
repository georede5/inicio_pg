

-- ############################################################################
-- INSERT TRIGGER nas LINHAS
-- ############################################################################

CREATE FUNCTION base.linhas_insert()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
	DECLARE
		v_start geometry;
		v_end geometry;
		v_testpt geometry;
		v_tol numeric;
		v_rec record;
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
		
		-- Encontrar linhas proximas do ponto inicial
		for v_rec in (
			select gid, geom
			from base.linhas l
			where st_DWithin(l.geom, v_start, v_tol)
			and ST_Length(geom) > v_tol
		) loop
			-- Obter o ponto inicial da linha proxima encontrada
			select ST_StartPoint(v_rec.geom) into v_testpt;

			v_node_gid := null;
			select gid into v_node_gid
			from base.nos n
			where st_DWithin(n.geom, v_testpt, v_tol)
			LIMIT 1;
				
			-- Se ambos os pontos iniciais forem proximos ...
			if st_distance(v_testpt, v_start) < v_tol then
			
				-- Ajustar o ponto inicial para cima do inicio da linha proxima
				NEW.geom := ST_SetSRID(ST_SetPoint(NEW.geom, 0, v_testpt), v_srid);
			
				if not v_node_gid is null then
					begin
						insert into base.nos_linhas
						(no_gid, linha_gid, ordem)
						values (v_node_gid, NEW.gid, 0);
					exception
						when unique_violation then
							null;
					end;
				ELSE
					insert into base.nos
					(geom) values (v_testpt)
					returning gid into v_node_gid;
					
					insert into base.nos_linhas
					(no_gid, linha_gid, ordem)
					values (v_node_gid, NEW.gid, 0);
				end if;

				-- garantir que a outra linha esta representad na tabela de ligacao
				begin
					insert into base.nos_linhas
					(no_gid, linha_gid, ordem)
					values (v_node_gid, v_rec.gid, 0);
				exception
					when unique_violation then
						null;
				end;

			end if;

			-- Se ambos o pontos final da nova e o inical da outra forem proximos ...
			if st_distance(v_testpt, v_end) < v_tol then

				-- Ajustar o ponto final para cima do inicio da linha proxima
				NEW.geom := ST_SetSRID(ST_SetPoint(NEW.geom, 1, v_testpt), v_srid);

				if not v_node_gid is null then
					begin
						insert into base.nos_linhas
						(no_gid, linha_gid, ordem)
						values (v_node_gid, NEW.gid, 1);
					exception
						when unique_violation then
							null;
					end;
				ELSE
					insert into base.nos
					(geom) values (v_testpt)
					returning gid into v_node_gid;
					
					insert into base.nos_linhas
					(no_gid, linha_gid, ordem)
					values (v_node_gid, NEW.gid, 1);
				end if;
				
				-- garantir que a outra linha esta representad na tabela de ligacao
				begin
					insert into base.nos_linhas
					(no_gid, linha_gid, ordem)
					values (v_node_gid, v_rec.gid, 0);
				exception
					when unique_violation then
						null;
				end;				
			end if;

			-- Obter o ponto final da linha proxima encontrada
			select ST_EndPoint(v_rec.geom) into v_testpt;

			v_node_gid := null;
			select gid into v_node_gid
			from base.nos n
			where st_DWithin(n.geom, v_testpt, v_tol)
			LIMIT 1;
				
			-- Se ponto final da proxima e o inicio desta forem proximos ...
			if st_distance(v_testpt, v_start) < v_tol then
			
				-- Ajustar o ponto inicial para cima do inicio da linha proxima
				NEW.geom := ST_SetSRID(ST_SetPoint(NEW.geom, 0, v_testpt), v_srid);
			
				if not v_node_gid is null then
					begin
						insert into base.nos_linhas
						(no_gid, linha_gid, ordem)
						values (v_node_gid, NEW.gid, 0);
					exception
						when unique_violation then
							null;
					end;
				ELSE
					insert into base.nos
					(geom) values (v_testpt)
					returning gid into v_node_gid;
					
					insert into base.nos_linhas
					(no_gid, linha_gid, ordem)
					values (v_node_gid, NEW.gid, 0);
				end if;

				-- garantir que a outra linha esta representad na tabela de ligacao
				begin
					insert into base.nos_linhas
					(no_gid, linha_gid, ordem)
					values (v_node_gid, v_rec.gid, 1);
				exception
					when unique_violation then
						null;
				end;				

			end if;
			
			if st_distance(v_testpt, v_end) < v_tol then

				-- Ajustar o ponto final para cima do inicio da linha proxima
				NEW.geom := ST_SetSRID(ST_SetPoint(NEW.geom, 1, v_testpt), v_srid);

				if not v_node_gid is null then
					begin
						insert into base.nos_linhas
						(no_gid, linha_gid, ordem)
						values (v_node_gid, NEW.gid, 1);
					exception
						when unique_violation then
							null;
					end;
				ELSE
					insert into base.nos
					(geom) values (v_testpt)
					returning gid into v_node_gid;
					
					insert into base.nos_linhas
					(no_gid, linha_gid, ordem)
					values (v_node_gid, NEW.gid, 1);
				end if;

				-- garantir que a outra linha esta representad na tabela de ligacao
				begin
					insert into base.nos_linhas
					(no_gid, linha_gid, ordem)
					values (v_node_gid, v_rec.gid, 1);
				exception
					when unique_violation then
						null;
				end;				

			end if;

		end loop;

	RETURN NEW;
	END;
	$BODY$;

ALTER FUNCTION base.linhas_insert()
    OWNER TO georede5;
