

-- ############################################################################
-- Tabela de parâmetros gerais de configuração
-- ############################################################################

CREATE TABLE base.config
(
    parametro character varying(64) COLLATE pg_catalog."default" NOT NULL,
    valor character varying(128) COLLATE pg_catalog."default" NOT NULL,
    "desc" character varying(128) COLLATE pg_catalog."default",
    CONSTRAINT config_pkey PRIMARY KEY (parametro)
        USING INDEX TABLESPACE georede5
)

TABLESPACE georede5;

ALTER TABLE base.config
    OWNER to georede5;

-- ############################################################################
-- Tabela genérica de LINHAS em PT-TM06 ETRS89
-- ############################################################################

CREATE TABLE base.linhas (
	gid uuid NOT NULL DEFAULT uuid_generate_v4(),
	geom geometry(LINESTRING, 3763) NOT NULL,
	utilizador varchar(64) NULL,
	estado uuid NULL,
	bloqueio uuid NULL,
	CONSTRAINT linhas_pkey PRIMARY KEY (gid)
);

-- Table Triggers

create trigger base_linhas_tr_criacao before
insert
    on
    base.linhas for each row execute function base.linhas_insert();
create trigger base_linhas_tr_apagamento before
delete
    on
    base.linhas for each row execute function base.linhas_delete();
create trigger base_linhas_tr_atualizacao before
update
    of geom on
    base.linhas for each row execute function base.linhas_update();

-- Permissions

ALTER TABLE base.linhas OWNER TO georede5;

-- ############################################################################
-- Tabela genérica de NÓS em PT-TM06 ETRS89
-- ############################################################################

CREATE TABLE base.nos (
	gid uuid NOT NULL,
	geom geometry(POINT, 3763) NOT NULL,
	fechado bool NOT NULL DEFAULT false,
	CONSTRAINT nos_pkey PRIMARY KEY (gid)
);

-- Table Triggers

create trigger nos_tr_criacao before
insert
    on
    base.nos for each row execute function base.nos_insert();
create trigger nos_tr_atualizacao before
update
    of geom on
    base.nos for each row execute function base.nos_update();
create trigger nos_tr_apagamento before
delete
    on
    base.nos for each row execute function base.nos_delete();

-- Permissions

ALTER TABLE base.nos OWNER TO georede5;

-- ############################################################################
-- Tabela de ligação NÓS - LINHAS 
-- ############################################################################

CREATE TABLE base.nos_linhas (
	ordem int2 NOT NULL,
	no_gid uuid NOT NULL,
	linha_gid uuid NOT NULL,
	CONSTRAINT nos_linhas_pkey PRIMARY KEY (no_gid, linha_gid, ordem)
);

-- Permissions

ALTER TABLE base.nos_linhas OWNER TO georede5;

-- ############################################################################
-- Tabela de terminais
-- ############################################################################

CREATE TABLE base.terminais (
	gid uuid NOT NULL DEFAULT uuid_generate_v4(),
	geom geometry(POINT, 3763) NOT NULL,
	ordem int2 NOT NULL,
	tipo base."tipo_terminal" NULL,
	linha_gid uuid NOT NULL,
	CONSTRAINT term_pkey PRIMARY KEY (gid)
);

-- Table Triggers

create trigger terminais_tr_apagamento before
delete
    on
    base.terminais for each row execute function base.terminais_delete();
create trigger terminais_tr_criacao before
insert
    on
    base.terminais for each row execute function base.terminais_insert();
create trigger terminais_tr_atualizacao before
update
    on
    base.terminais for each row execute function base.terminais_update();

-- Permissions

ALTER TABLE base.terminais OWNER TO georede5;

