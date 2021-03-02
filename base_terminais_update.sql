CREATE OR REPLACE FUNCTION base.terminais_update()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
declare 
	v_stack text;
	v_check_func_pos1 int;
begin

	-- Verificar se as funções autorizadas estão a invocar esta
	get diagnostics v_stack = PG_CONTEXT;
	select position(' function base.linhas_update() ' in v_stack) into v_check_func_pos1;

	if v_check_func_pos1 > 0 and not new.gid is null then 
		-- se estivermos a ser invocados por linhas_update, deixar seguir
		return new;
	else
		-- caso contrário, vetar a operação: proibido atualizar terminais manualmente
		return null;
	end if;
		
END;
$function$
;

-- Permissions

ALTER FUNCTION base.terminais_update() OWNER TO georede5;

