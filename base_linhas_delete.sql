CREATE OR REPLACE FUNCTION base.linhas_delete()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin

	-- Apagar todas as entradas do gid da linha na tabela de ligação nos_linhas.
	delete from base.nos_linhas
	where linha_gid = old.gid; 

	delete from base.terminais
	where linha_gid = old.gid; 

	-- Limpar nós já não mais necessários e entradas "solitárias" na tabela de ligação nos_linhas
	perform base.nos_clean();

	return old;
		
END;
$function$
;

-- Permissions

ALTER FUNCTION base.linhas_delete() OWNER TO georede5;

