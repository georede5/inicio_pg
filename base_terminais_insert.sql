CREATE OR REPLACE FUNCTION base.terminais_insert()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
declare 
	v_stack text;
	v_check_func_pos1 int;
	v_check_func_pos2 int;
begin

	-- Verificar se as funções autorizadas estão a invocar esta
	get diagnostics v_stack = PG_CONTEXT;
	select position(' function base.nos_clean() ' in v_stack) into v_check_func_pos1;
	select position(' function base.criar_associar_nos(' in v_stack) into v_check_func_pos2;

	if v_check_func_pos1 > 0 or v_check_func_pos2 > 0 and not new.gid is null then 
		-- se estivermos a ser invocados por criar_associar_nos, deixar seguir
		return new;
	else
		-- caso contrário, vetar a operação: proibido inserir novos terminais manualmente
		return null;
	end if;
		
END;
$function$
;

-- Permissions

ALTER FUNCTION base.terminais_insert() OWNER TO georede5;

