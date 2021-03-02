CREATE OR REPLACE FUNCTION base.terminais_delete()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
declare 
	v_stack text;
	v_check_func_pos1 int;
	v_check_func_pos2 int;
begin
	-- Verificar se função linhas_delete está a invocar esta
	get diagnostics v_stack = PG_CONTEXT;
	select position(' function base.linhas_delete() ' in v_stack) into v_check_func_pos1;
	select position(' function base.criar_associar_nos(' in v_stack) into v_check_func_pos2;

	if v_check_func_pos1 > 0 or v_check_func_pos2 > 0 then 
		-- se estivermos a ser invocados pelas funções autorizadas, deixar seguir
		return old;
	else
		-- caso contrário, vetar a operação: proibido apagar nós sem ser via nos_clean
		return null;
	end if;
	
END;
$function$
;

-- Permissions

ALTER FUNCTION base.terminais_delete() OWNER TO georede5;

