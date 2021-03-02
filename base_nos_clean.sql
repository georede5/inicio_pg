CREATE OR REPLACE FUNCTION base.nos_clean()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
declare
	v_row record;
	v_row2 record;
	v_term_gid uuid;
	v_geom geometry;
begin
	-- Listar gid de nó dos nós que já não se encontram representados na tabela de ligação
	--     nos_linhas
	for v_row in (
		select a.gid as no_gid
		from base.nos a
		left outer join base.nos_linhas b
		on a.gid = b.no_gid 
		where linha_gid is null
	) loop 
	
		-- Apagar o nó correspondente
		delete from base.nos 
		where gid = v_row.no_gid;
	
	end loop;

	-- Listar gid de nó os valores de gid de nó para os quais só existe uma entrada em nos_linhas
	--     (correspondentes a um nó que ficou "solitário" na ponta de uma única linha)
	for v_row in (
		select no_gid
		from
		(select no_gid, count(*) cnt
		from base.nos_linhas
		group by no_gid
		having count(*) = 1) a		
	) loop 
	
		-- Apagar o nó correspondente
		delete from base.nos 
		where gid = v_row.no_gid;
	
		-- inserir terminal a substituir o nó removido
		for v_row2 in (
			select a.linha_gid, a.ordem, b.geom
			from base.nos_linhas a
			join base.linhas b
			on a.linha_gid = b.gid 
			where a.no_gid = v_row.no_gid
		) loop 
		
			if v_row2.ordem = 0 then
				v_geom := ST_StartPoint(v_row2.geom);
			else
				v_geom := ST_EndPoint(v_row2.geom);
			end if;
		
			v_term_gid := uuid_generate_v4();	
			insert into base.terminais (gid, geom, tipo, linha_gid, ordem)
			values (v_term_gid, v_geom, 'aberto', v_row2.linha_gid, v_row2.ordem);
		
		end loop; -- v_row2
	
		-- Apagar a entrada "solitária" em nos_linhas
		delete from base.nos_linhas
		where no_gid = v_row.no_gid;
	
	end loop;

END;
$function$
;

-- Permissions

ALTER FUNCTION base.nos_clean() OWNER TO georede5;

