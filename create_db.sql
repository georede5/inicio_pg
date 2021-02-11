
-- ############################################################################
-- Criar Role / Login raíz
-- ############################################################################

CREATE ROLE georede5 WITH
  LOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION;

-- ############################################################################
-- Criar Tablespace
-- ############################################################################

-- !! ATENÇÃO -- Alterar LOCATION !!
CREATE TABLESPACE georede5
  OWNER georede5
  LOCATION '/var/lib/postgresql/data/tablespaces/georede5';

ALTER TABLESPACE georede5
  OWNER TO georede5;

-- ############################################################################
-- Criar base de dados
-- ############################################################################

CREATE DATABASE georede5
    WITH 
    OWNER = georede5
    ENCODING = 'UTF8'
    TABLESPACE = georede5
    CONNECTION LIMIT = -1;  

-- ############################################################################
-- Criar primeiro schema e instalação de extensões
-- ############################################################################

CREATE SCHEMA base
    AUTHORIZATION georede5;	

create extension "uuid-ossp";

create extension "postgis";

