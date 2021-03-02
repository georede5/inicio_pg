CREATE OR REPLACE FUNCTION base.linhas_update()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_tmpgeom geometry;
	v_stack text;
	v_check_func_pos int;
	v_trow record;
	v_tgeom geometry;
	v_tol numeric;
begin
	-- Garantir que o gid é mesmo 
	assert new.gid = old.gid, format("linhas_update: gid difentes antigo:%, novo:%", old.gid, new.gid);

	-- Obter tolerancia de pesquisa de proximidade entre elementos
	SELECT valor::NUMERIC into v_tol
	FROM base.config
	where parametro = 'TOLERANCIA';

	-- Comprimento da nova linha tem de ser,
	--	no mínimo, o dobro da tolerância
	if ST_Length(new.geom) < 2.0 * v_tol then
		raise notice 'comprimento (%) abaixo do mínimo permitido: %', ST_Length(new.geom), 2.0 * v_tol;
		return null;
	end if;

	-- Registar utilizador responsável pela criação do elemento
	NEW.utilizador := current_user;

	-- Verificar se função nos_update está a invocar esta
	get diagnostics v_stack = PG_CONTEXT;
	select position(' function base.nos_update() ' in v_stack) into v_check_func_pos;

	-- se isto não estiver a ser invocado pela ataualização de nós ...
	if v_check_func_pos = 0 then

		-- Apagar todas as entradas do gid da linha na tabela de ligação nos_linhas
		delete from base.nos_linhas
		where linha_gid = old.gid;

		-- Apagar todas as entradas do gid da linha na tabela de terminais
		/*delete from base.terminais
		where linha_gid = old.gid;*/
	
		-- Criar / associar nós e corrigir geometria se necessário
		v_tmpgeom := base.criar_associar_nos(new.geom, new.gid);
	
		-- Limpar nós já não mais necessários e entradas "solitárias" na tabela de ligação nos_linhas
		perform base.nos_clean();
	
		-- Pode haver uma "ordem de saída": o método de criar / associar nós pode
		--   descobrir que regras como a do comprimento mínimo duma linha
		--   estão a ser violadas e, por isso, envia uma geometria nula
		if not v_tmpgeom is null then				
			-- ... se a geometria tiver sido alterada, há que gravá-la
			new.geom := v_tmpgeom;
		else
			return null;
		end if;
	
		-- Mover os terminais que tenham subsistido
		for v_trow in (
			select gid, ordem
			from base.terminais t 
			where linha_gid = new.gid
		) loop 
		
			if v_trow.ordem = 0 then				
				v_tgeom := ST_StartPoint(new.geom);
			else
				v_tgeom := ST_EndPoint(new.geom);
			end if;
		
			update base.terminais
			set geom = v_tgeom
			where gid = v_trow.gid;
		
		end loop;

	end if; -- v_check_func_pos = 0
	
	return new;
		
END;
$function$
;

-- Permissions

ALTER FUNCTION base.linhas_update() OWNER TO georede5;

