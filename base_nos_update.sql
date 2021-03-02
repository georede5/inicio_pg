CREATE OR REPLACE FUNCTION base.nos_update()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_tol numeric;
	v_srid integer;
	v_other_node_gid uuid;
	v_row record;
	v_l_geom geometry;
	v_exec_context text;
	v_npts integer;
begin

	-- Obter tolerancia de pesquisa de proximidade entre elementos
	SELECT valor::NUMERIC into v_tol
	FROM base.config
	where parametro = 'TOLERANCIA';
	
	SELECT valor::int into v_srid
	FROM base.config
	where parametro = 'SRID';

	-- Garantir que o gid é mesmo 
	assert new.gid = old.gid, format("nos_update: gid difentes antigo:%, novo:%", old.gid, new.gid);

	-- procurar nó próximo
	select gid into v_other_node_gid
	from base.nos n
	where st_DWithin(n.geom, new.geom, v_tol)
	LIMIT 1;

	-- se houver outro nó nas redondezas, abortar
	if not v_other_node_gid is null and v_other_node_gid != new.gid then 
		raise notice 'proximidade excessiva ao no:%, dist.limite:%', v_other_node_gid, v_tol;
		return null;
	end if;

	-- por cada extremo de linha associado a este nó vamos arrastá-lo para a 
	-- geometria de nó que está a ser atualizada.
	for v_row in (
		select l.geom, linha_gid, ordem
		from base.nos_linhas nl 
		inner join base.linhas l
		on nl.linha_gid = l.gid 
		where nl.no_gid = new.gid
	)
	loop 

		if v_row.ordem = 0 then
			v_l_geom := ST_SetSRID(ST_SetPoint(v_row.geom, 0, new.geom), v_srid);
		else
			v_npts := ST_NPoints(v_row.geom);
			v_l_geom := ST_SetSRID(ST_SetPoint(v_row.geom, v_npts-1, new.geom), v_srid);
		end if;
	
		update base.linhas
		set geom = v_l_geom
		where gid = v_row.linha_gid;
	
	end loop;
	
	
	return new;
		
END;
$function$
;

-- Permissions

ALTER FUNCTION base.nos_update() OWNER TO georede5;

