-- Ejecutar conectado a la base "postgres", no a otra base de trabajo.
-- PostgreSQL no admite CREATE DATABASE IF NOT EXISTS.
CREATE DATABASE cabana_porcina_db
  WITH
  OWNER = postgres
  ENCODING = 'UTF8'
  TEMPLATE = template0;

