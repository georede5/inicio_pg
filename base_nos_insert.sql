CREATE OR REPLACE FUNCTION base.nos_insert()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
declare 
	v_stack text;
	v_check_func_pos int;
begin

	-- Verificar se função criar_associar_nos está a invocar esta
	get diagnostics v_stack = PG_CONTEXT;
	select position(' function base.criar_associar_nos(' in v_stack) into v_check_func_pos;

	if v_check_func_pos > 0 and not new.gid is null then 
		-- se estivermos a ser invocados por criar_associar_nos, deixar seguir
		return new;
	else
		-- caso contrário, vetar a operação: proibido inserir novos nós sem ser via criar_associar_nos
		return null;
	end if;
		
END;
$function$
;

-- Permissions

ALTER FUNCTION base.nos_insert() OWNER TO georede5;

