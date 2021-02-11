

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

CREATE TABLE base.linhas
(
    gid uuid NOT NULL DEFAULT uuid_generate_v4(),
    geom geometry(LineString,3763) NOT NULL,
    utilizador character varying(64) COLLATE pg_catalog."default",
    CONSTRAINT linhas_pkey PRIMARY KEY (gid)
        USING INDEX TABLESPACE georede5
)

TABLESPACE georede5;

ALTER TABLE base.linhas
    OWNER to georede5;

-- Trigger: base_linhas_tr_criacao

-- DROP TRIGGER base_linhas_tr_criacao ON base.linhas;

CREATE TRIGGER base_linhas_tr_criacao
    BEFORE INSERT
    ON base.linhas
    FOR EACH ROW
    EXECUTE PROCEDURE base.linhas_insert();

-- ############################################################################
-- Tabela genérica de NÓS em PT-TM06 ETRS89
-- ############################################################################

CREATE TABLE base.nos
(
    gid uuid NOT NULL DEFAULT uuid_generate_v4(),
    geom geometry(Point,3763) NOT NULL,
    CONSTRAINT nos_pkey PRIMARY KEY (gid)
        USING INDEX TABLESPACE georede5
)

TABLESPACE georede5;

ALTER TABLE base.nos
    OWNER to georede5;

-- ############################################################################
-- Tabela de ligação NÓS - LINHAS 
-- ############################################################################

CREATE TABLE base.nos_linhas
(
    no_gid uuid NOT NULL,
    linha_gid uuid NOT NULL,
    ordem smallint NOT NULL,
    CONSTRAINT nos_linhas_pkey PRIMARY KEY (no_gid, linha_gid, ordem)
        USING INDEX TABLESPACE georede5
)

TABLESPACE georede5;

ALTER TABLE base.nos_linhas
    OWNER to georede5;

