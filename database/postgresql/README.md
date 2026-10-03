# PostgreSQL - Cabana Porcina

Base recomendada: `cabana_porcina_db`.

## Orden de ejecucion en pgAdmin

1. Conectarse a la base `postgres`.
2. Ejecutar `000_create_database.sql`.
3. Refrescar `Databases` y abrir `cabana_porcina_db`.
4. Abrir `Query Tool` dentro de `cabana_porcina_db`.
5. Ejecutar `001_operational_schema.sql`.
6. Ejecutar `002_data_warehouse_schema.sql`.
7. Si se creo el usuario `cabana_dev`, ejecutar
   `003_grants_cabana_dev.sql` como `postgres`.

El esquema `operacional` guarda los CRUD y movimientos diarios.
El esquema `dw` guarda copias analiticas para reportes y promedios sectoriales.

La aplicacion Flutter no debe conectarse directamente con el usuario y la
contrasena de PostgreSQL. La sincronizacion se realizara mediante una API.
