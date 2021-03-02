CREATE OR REPLACE FUNCTION base.linhas_insert()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_tmpgeom geometry;
BEGIN
	-- Registar utilizador responsável pela criação do elemento
	NEW.utilizador := current_user;

	-- Criar / associar nós, este processo pode gerar um ajuste da geometria da linha ....
	v_tmpgeom := base.criar_associar_nos(new.geom, new.gid);

	-- Pode haver uma "ordem de saída": o método de criar / associar nós pode
	--   descobrir que regras como a do comprimento mínimo duma linha
	--   estão a ser violadas e, por isso, a alteração não pode ser gravada
	if v_tmpgeom is null then
		return null;
	end if;

	new.geom := v_tmpgeom;

	return new;

		
END;
$function$
;

-- Permissions

ALTER FUNCTION base.linhas_insert() OWNER TO georede5;

