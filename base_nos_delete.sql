CREATE OR REPLACE FUNCTION base.nos_delete()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
declare 
	v_stack text;
	v_check_func_pos int;
begin
	-- Verificar se função nos_clean está a invocar esta
	get diagnostics v_stack = PG_CONTEXT;
	select position(' function base.nos_clean() ' in v_stack) into v_check_func_pos;

	if v_check_func_pos > 0 then 
		-- se estivermos a ser invocados pela limpeza de nós, deixar seguir
		return old;
	else
		-- caso contrário, vetar a operação: proibido apagar nós sem ser via nos_clean
		return null;
	end if;
	
END;
$function$
;

-- Permissions

ALTER FUNCTION base.nos_delete() OWNER TO georede5;

