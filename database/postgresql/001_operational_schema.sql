BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SCHEMA IF NOT EXISTS operacional;

CREATE OR REPLACE FUNCTION operacional.actualizar_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  NEW.version = OLD.version + 1;
  RETURN NEW;
END;
$$;

CREATE TABLE IF NOT EXISTS operacional.granjas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  id_local varchar(64),
  nombre varchar(150) NOT NULL,
  codigo varchar(40) NOT NULL UNIQUE,
  propietario varchar(150),
  departamento varchar(100),
  municipio varchar(100),
  zona_horaria varchar(60) NOT NULL DEFAULT 'America/La_Paz',
  moneda char(3) NOT NULL DEFAULT 'BOB',
  activa boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS operacional.usuarios (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  id_local varchar(64),
  nombre varchar(150) NOT NULL,
  correo varchar(200),
  telefono varchar(30),
  rol varchar(30) NOT NULL DEFAULT 'operador'
    CHECK (rol IN ('propietario', 'administrador', 'veterinario', 'operador', 'consulta')),
  activo boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1,
  UNIQUE (granja_id, correo)
);

CREATE TABLE IF NOT EXISTS operacional.dispositivos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  usuario_id uuid REFERENCES operacional.usuarios(id),
  identificador varchar(150) NOT NULL,
  plataforma varchar(30) NOT NULL,
  nombre varchar(100),
  ultimo_sync_at timestamptz,
  activo boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1,
  UNIQUE (granja_id, identificador)
);

CREATE TABLE IF NOT EXISTS operacional.configuraciones (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  clave varchar(100) NOT NULL,
  valor jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1,
  UNIQUE (granja_id, clave)
);

CREATE TABLE IF NOT EXISTS operacional.ubicaciones (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  id_local varchar(64),
  codigo varchar(40) NOT NULL,
  nombre varchar(120) NOT NULL,
  tipo varchar(30) NOT NULL
    CHECK (tipo IN (
      'galpon', 'gestacion', 'maternidad', 'pre_destete',
      'parrilla', 'engorde', 'verracos', 'almacen', 'otro'
    )),
  capacidad integer CHECK (capacidad IS NULL OR capacidad >= 0),
  activa boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1,
  UNIQUE (granja_id, codigo)
);

CREATE TABLE IF NOT EXISTS operacional.corrales_jaulas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  ubicacion_id uuid NOT NULL REFERENCES operacional.ubicaciones(id),
  id_local varchar(64),
  codigo varchar(40) NOT NULL,
  numero integer NOT NULL CHECK (numero > 0),
  lado varchar(15) CHECK (lado IN ('izquierdo', 'derecho', 'centro')),
  posicion integer CHECK (posicion IS NULL OR posicion > 0),
  tipo varchar(20) NOT NULL CHECK (tipo IN ('jaula', 'corral', 'comedero')),
  capacidad integer CHECK (capacidad IS NULL OR capacidad >= 0),
  activa boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1,
  UNIQUE (granja_id, codigo),
  UNIQUE (ubicacion_id, numero)
);

CREATE TABLE IF NOT EXISTS operacional.animales (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  corral_jaula_id uuid REFERENCES operacional.corrales_jaulas(id),
  id_local varchar(64),
  numero_arete varchar(60) NOT NULL,
  nombre varchar(100),
  tipo varchar(20) NOT NULL
    CHECK (tipo IN ('cerda', 'verraco', 'lechon', 'crecimiento', 'engorde')),
  sexo char(1) CHECK (sexo IN ('H', 'M')),
  raza varchar(80),
  linea_sangre varchar(120),
  fecha_nacimiento date,
  estado varchar(30) NOT NULL DEFAULT 'activo',
  montas_acumuladas integer NOT NULL DEFAULT 0 CHECK (montas_acumuladas >= 0),
  activo boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1,
  UNIQUE (granja_id, numero_arete)
);

CREATE TABLE IF NOT EXISTS operacional.historial_ubicaciones (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  animal_id uuid REFERENCES operacional.animales(id),
  lote_id uuid,
  origen_id uuid REFERENCES operacional.corrales_jaulas(id),
  destino_id uuid NOT NULL REFERENCES operacional.corrales_jaulas(id),
  cantidad integer NOT NULL DEFAULT 1 CHECK (cantidad > 0),
  fecha timestamptz NOT NULL DEFAULT now(),
  motivo varchar(200),
  responsable_id uuid REFERENCES operacional.usuarios(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1,
  CHECK (animal_id IS NOT NULL OR lote_id IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS operacional.productos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  id_local varchar(64),
  codigo varchar(50) NOT NULL,
  nombre varchar(160) NOT NULL,
  categoria varchar(40) NOT NULL
    CHECK (categoria IN (
      'ingrediente_alimento', 'alimento_preparado', 'medicamento',
      'vacuna', 'producto_manejo', 'servicio_gasto'
    )),
  subcategoria varchar(80),
  unidad_base varchar(20) NOT NULL,
  tipo_control varchar(30) NOT NULL DEFAULT 'stock',
  stock_actual numeric(16,4) NOT NULL DEFAULT 0,
  costo_promedio numeric(16,6) NOT NULL DEFAULT 0,
  stock_minimo numeric(16,4) NOT NULL DEFAULT 0,
  fecha_vencimiento date,
  permite_stock_negativo boolean NOT NULL DEFAULT false,
  activo boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1,
  CHECK (stock_actual >= 0 OR permite_stock_negativo),
  CHECK (costo_promedio >= 0),
  UNIQUE (granja_id, codigo)
);

CREATE TABLE IF NOT EXISTS operacional.conversiones_unidad (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  producto_id uuid NOT NULL REFERENCES operacional.productos(id),
  unidad_origen varchar(30) NOT NULL,
  unidad_destino varchar(30) NOT NULL,
  factor numeric(16,6) NOT NULL CHECK (factor > 0),
  activa boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1,
  UNIQUE (producto_id, unidad_origen, unidad_destino)
);

CREATE TABLE IF NOT EXISTS operacional.proveedores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  nombre varchar(160) NOT NULL,
  documento varchar(40),
  telefono varchar(30),
  direccion varchar(250),
  activo boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS operacional.compras (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  id_local varchar(64),
  proveedor_id uuid REFERENCES operacional.proveedores(id),
  fecha timestamptz NOT NULL DEFAULT now(),
  numero_factura varchar(80),
  total numeric(16,4) NOT NULL CHECK (total >= 0),
  observacion text,
  responsable_id uuid REFERENCES operacional.usuarios(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS operacional.compra_detalles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  compra_id uuid NOT NULL REFERENCES operacional.compras(id),
  producto_id uuid NOT NULL REFERENCES operacional.productos(id),
  cantidad_compra numeric(16,4) NOT NULL CHECK (cantidad_compra > 0),
  unidad_compra varchar(30) NOT NULL,
  conversion_unidad_base numeric(16,6) NOT NULL CHECK (conversion_unidad_base > 0),
  cantidad_base numeric(16,4) NOT NULL CHECK (cantidad_base > 0),
  precio_total numeric(16,4) NOT NULL CHECK (precio_total >= 0),
  precio_unitario_base numeric(16,6) NOT NULL CHECK (precio_unitario_base >= 0),
  lote_fabricante varchar(80),
  fecha_vencimiento date,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS operacional.movimientos_inventario (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  id_local varchar(64),
  producto_id uuid NOT NULL REFERENCES operacional.productos(id),
  fecha timestamptz NOT NULL DEFAULT now(),
  tipo varchar(20) NOT NULL
    CHECK (tipo IN ('entrada', 'salida', 'ajuste', 'preparacion', 'consumo', 'merma')),
  cantidad numeric(16,4) NOT NULL CHECK (cantidad <> 0),
  unidad_base varchar(20) NOT NULL,
  costo_unitario numeric(16,6) NOT NULL CHECK (costo_unitario >= 0),
  costo_total numeric(16,4) NOT NULL CHECK (costo_total >= 0),
  stock_anterior numeric(16,4),
  stock_posterior numeric(16,4),
  referencia_tipo varchar(40),
  referencia_id uuid,
  observacion text,
  responsable_id uuid REFERENCES operacional.usuarios(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS operacional.formulas_alimento (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  id_local varchar(64),
  nombre varchar(160) NOT NULL,
  etapa varchar(30) NOT NULL,
  version_formula integer NOT NULL DEFAULT 1 CHECK (version_formula > 0),
  activa boolean NOT NULL DEFAULT true,
  fecha_creacion date NOT NULL DEFAULT CURRENT_DATE,
  observacion text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1,
  UNIQUE (granja_id, nombre, version_formula)
);

CREATE TABLE IF NOT EXISTS operacional.formula_ingredientes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  formula_id uuid NOT NULL REFERENCES operacional.formulas_alimento(id),
  producto_id uuid NOT NULL REFERENCES operacional.productos(id),
  porcentaje numeric(7,4) NOT NULL CHECK (porcentaje > 0 AND porcentaje <= 100),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1,
  UNIQUE (formula_id, producto_id)
);

CREATE TABLE IF NOT EXISTS operacional.preparaciones_alimento (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  id_local varchar(64),
  codigo_lote varchar(60) NOT NULL,
  formula_id uuid NOT NULL REFERENCES operacional.formulas_alimento(id),
  producto_preparado_id uuid NOT NULL REFERENCES operacional.productos(id),
  fecha timestamptz NOT NULL DEFAULT now(),
  cantidad_producida_kg numeric(16,4) NOT NULL CHECK (cantidad_producida_kg > 0),
  cantidad_disponible_kg numeric(16,4) NOT NULL CHECK (cantidad_disponible_kg >= 0),
  costo_total numeric(16,4) NOT NULL CHECK (costo_total >= 0),
  costo_por_kg numeric(16,6) NOT NULL CHECK (costo_por_kg >= 0),
  responsable_id uuid REFERENCES operacional.usuarios(id),
  observacion text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1,
  UNIQUE (granja_id, codigo_lote)
);

CREATE TABLE IF NOT EXISTS operacional.preparacion_ingredientes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  preparacion_id uuid NOT NULL REFERENCES operacional.preparaciones_alimento(id),
  producto_id uuid NOT NULL REFERENCES operacional.productos(id),
  cantidad_kg numeric(16,4) NOT NULL CHECK (cantidad_kg > 0),
  costo_unitario numeric(16,6) NOT NULL CHECK (costo_unitario >= 0),
  costo_total numeric(16,4) NOT NULL CHECK (costo_total >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS operacional.ciclos_reproductivos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  id_local varchar(64),
  cerda_id uuid NOT NULL REFERENCES operacional.animales(id),
  fecha_inicio date NOT NULL,
  fecha_confirmacion_prenez date,
  fecha_parto_estimada date,
  fecha_parto_real date,
  estado varchar(30) NOT NULL
    CHECK (estado IN ('celo', 'monta', 'observacion', 'confirmada', 'parto', 'aborto', 'cerrado')),
  costo_gestacion numeric(16,4) NOT NULL DEFAULT 0 CHECK (costo_gestacion >= 0),
  observacion text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS operacional.montas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  id_local varchar(64),
  ciclo_id uuid NOT NULL REFERENCES operacional.ciclos_reproductivos(id),
  cerda_id uuid NOT NULL REFERENCES operacional.animales(id),
  verraco_id uuid REFERENCES operacional.animales(id),
  numero_monta smallint NOT NULL CHECK (numero_monta BETWEEN 1 AND 10),
  fecha_hora timestamptz NOT NULL,
  tipo varchar(25) NOT NULL DEFAULT 'natural'
    CHECK (tipo IN ('natural', 'inseminacion', 'mixta')),
  costo numeric(16,4) NOT NULL DEFAULT 0 CHECK (costo >= 0),
  responsable_id uuid REFERENCES operacional.usuarios(id),
  observacion text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1,
  UNIQUE (ciclo_id, numero_monta)
);

CREATE TABLE IF NOT EXISTS operacional.lotes_produccion (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  id_local varchar(64),
  codigo varchar(60) NOT NULL,
  madre_id uuid REFERENCES operacional.animales(id),
  ciclo_reproductivo_id uuid REFERENCES operacional.ciclos_reproductivos(id),
  fecha_nacimiento date NOT NULL,
  nacidos_totales integer NOT NULL DEFAULT 0 CHECK (nacidos_totales >= 0),
  nacidos_vivos integer NOT NULL DEFAULT 0 CHECK (nacidos_vivos >= 0),
  nacidos_muertos integer NOT NULL DEFAULT 0 CHECK (nacidos_muertos >= 0),
  machos integer NOT NULL DEFAULT 0 CHECK (machos >= 0),
  hembras integer NOT NULL DEFAULT 0 CHECK (hembras >= 0),
  destetados integer NOT NULL DEFAULT 0 CHECK (destetados >= 0),
  muertos_acumulados integer NOT NULL DEFAULT 0 CHECK (muertos_acumulados >= 0),
  animales_actuales integer NOT NULL DEFAULT 0 CHECK (animales_actuales >= 0),
  etapa_actual varchar(30) NOT NULL,
  ubicacion_actual_id uuid REFERENCES operacional.corrales_jaulas(id),
  estado varchar(30) NOT NULL DEFAULT 'activo',
  costo_acumulado numeric(16,4) NOT NULL DEFAULT 0 CHECK (costo_acumulado >= 0),
  peso_total_vendido_kg numeric(16,4) NOT NULL DEFAULT 0 CHECK (peso_total_vendido_kg >= 0),
  fecha_cierre date,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1,
  UNIQUE (granja_id, codigo),
  CHECK (nacidos_vivos + nacidos_muertos <= nacidos_totales)
);

ALTER TABLE operacional.historial_ubicaciones
  DROP CONSTRAINT IF EXISTS historial_ubicaciones_lote_id_fkey;
ALTER TABLE operacional.historial_ubicaciones
  ADD CONSTRAINT historial_ubicaciones_lote_id_fkey
  FOREIGN KEY (lote_id) REFERENCES operacional.lotes_produccion(id);

CREATE TABLE IF NOT EXISTS operacional.partos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  id_local varchar(64),
  ciclo_id uuid NOT NULL REFERENCES operacional.ciclos_reproductivos(id),
  cerda_id uuid NOT NULL REFERENCES operacional.animales(id),
  lote_id uuid NOT NULL UNIQUE REFERENCES operacional.lotes_produccion(id),
  fecha_hora timestamptz NOT NULL,
  nacidos_totales integer NOT NULL CHECK (nacidos_totales >= 0),
  nacidos_vivos integer NOT NULL CHECK (nacidos_vivos >= 0),
  nacidos_muertos integer NOT NULL CHECK (nacidos_muertos >= 0),
  machos integer NOT NULL DEFAULT 0 CHECK (machos >= 0),
  hembras integer NOT NULL DEFAULT 0 CHECK (hembras >= 0),
  costo_parto numeric(16,4) NOT NULL DEFAULT 0 CHECK (costo_parto >= 0),
  observacion text,
  responsable_id uuid REFERENCES operacional.usuarios(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS operacional.abortos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  id_local varchar(64),
  ciclo_id uuid NOT NULL REFERENCES operacional.ciclos_reproductivos(id),
  cerda_id uuid NOT NULL REFERENCES operacional.animales(id),
  fecha_hora timestamptz NOT NULL,
  dias_gestacion integer CHECK (dias_gestacion IS NULL OR dias_gestacion >= 0),
  cantidad_fetos integer CHECK (cantidad_fetos IS NULL OR cantidad_fetos >= 0),
  causa varchar(200),
  costo numeric(16,4) NOT NULL DEFAULT 0 CHECK (costo >= 0),
  observacion text,
  responsable_id uuid REFERENCES operacional.usuarios(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS operacional.movimientos_lote (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  id_local varchar(64),
  lote_id uuid NOT NULL REFERENCES operacional.lotes_produccion(id),
  fecha timestamptz NOT NULL DEFAULT now(),
  etapa_origen varchar(30),
  etapa_destino varchar(30) NOT NULL,
  ubicacion_origen_id uuid REFERENCES operacional.corrales_jaulas(id),
  ubicacion_destino_id uuid REFERENCES operacional.corrales_jaulas(id),
  animales_movidos integer NOT NULL CHECK (animales_movidos > 0),
  observacion text,
  responsable_id uuid REFERENCES operacional.usuarios(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS operacional.consumos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  id_local varchar(64),
  fecha timestamptz NOT NULL DEFAULT now(),
  tipo_destino varchar(20) NOT NULL
    CHECK (tipo_destino IN ('corral', 'lote', 'animal', 'ciclo')),
  etapa varchar(30) NOT NULL,
  producto_id uuid NOT NULL REFERENCES operacional.productos(id),
  corral_jaula_id uuid REFERENCES operacional.corrales_jaulas(id),
  lote_id uuid REFERENCES operacional.lotes_produccion(id),
  animal_id uuid REFERENCES operacional.animales(id),
  ciclo_reproductivo_id uuid REFERENCES operacional.ciclos_reproductivos(id),
  cantidad numeric(16,4) NOT NULL CHECK (cantidad > 0),
  unidad varchar(20) NOT NULL,
  conversion_unidad_base numeric(16,6) NOT NULL DEFAULT 1
    CHECK (conversion_unidad_base > 0),
  cantidad_base numeric(16,4) NOT NULL CHECK (cantidad_base > 0),
  costo_unitario numeric(16,6) NOT NULL CHECK (costo_unitario >= 0),
  costo_total numeric(16,4) NOT NULL CHECK (costo_total >= 0),
  animales_atendidos integer CHECK (animales_atendidos IS NULL OR animales_atendidos >= 0),
  responsable_id uuid REFERENCES operacional.usuarios(id),
  observacion text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1,
  CHECK (
    (tipo_destino = 'corral' AND corral_jaula_id IS NOT NULL) OR
    (tipo_destino = 'lote' AND lote_id IS NOT NULL) OR
    (tipo_destino = 'animal' AND animal_id IS NOT NULL) OR
    (tipo_destino = 'ciclo' AND ciclo_reproductivo_id IS NOT NULL)
  )
);

CREATE TABLE IF NOT EXISTS operacional.costos_lote (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  lote_id uuid NOT NULL REFERENCES operacional.lotes_produccion(id),
  fecha timestamptz NOT NULL DEFAULT now(),
  etapa varchar(30) NOT NULL,
  categoria varchar(40) NOT NULL,
  descripcion varchar(250) NOT NULL,
  costo numeric(16,4) NOT NULL CHECK (costo >= 0),
  origen_tipo varchar(40) NOT NULL,
  origen_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS operacional.mortalidades (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  id_local varchar(64),
  lote_id uuid NOT NULL REFERENCES operacional.lotes_produccion(id),
  fecha timestamptz NOT NULL DEFAULT now(),
  etapa varchar(30) NOT NULL,
  cantidad_muertos integer NOT NULL CHECK (cantidad_muertos > 0),
  causa varchar(200),
  observacion text,
  responsable_id uuid REFERENCES operacional.usuarios(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS operacional.protocolos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  nombre varchar(160) NOT NULL,
  etapa varchar(30) NOT NULL,
  dia_recomendado integer CHECK (dia_recomendado IS NULL OR dia_recomendado >= 0),
  aplica_a varchar(20) NOT NULL
    CHECK (aplica_a IN ('lote', 'cerda', 'verraco', 'animal', 'corral')),
  activo boolean NOT NULL DEFAULT true,
  observacion text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS operacional.protocolo_detalles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  protocolo_id uuid NOT NULL REFERENCES operacional.protocolos(id),
  producto_id uuid NOT NULL REFERENCES operacional.productos(id),
  cantidad numeric(16,4) NOT NULL CHECK (cantidad > 0),
  unidad varchar(20) NOT NULL,
  observacion text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS operacional.ejecuciones_protocolo (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  protocolo_id uuid NOT NULL REFERENCES operacional.protocolos(id),
  fecha timestamptz NOT NULL DEFAULT now(),
  lote_id uuid REFERENCES operacional.lotes_produccion(id),
  animal_id uuid REFERENCES operacional.animales(id),
  corral_jaula_id uuid REFERENCES operacional.corrales_jaulas(id),
  cantidad_animales integer CHECK (cantidad_animales IS NULL OR cantidad_animales > 0),
  costo_total numeric(16,4) NOT NULL DEFAULT 0 CHECK (costo_total >= 0),
  responsable_id uuid REFERENCES operacional.usuarios(id),
  observacion text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS operacional.raciones_referencia (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  etapa varchar(30) NOT NULL,
  tipo_animal varchar(30) NOT NULL,
  condicion varchar(100),
  kg_por_dia numeric(10,4) CHECK (kg_por_dia IS NULL OR kg_por_dia >= 0),
  kg_manana numeric(10,4) CHECK (kg_manana IS NULL OR kg_manana >= 0),
  kg_tarde numeric(10,4) CHECK (kg_tarde IS NULL OR kg_tarde >= 0),
  activa boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS operacional.pesajes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  lote_id uuid NOT NULL REFERENCES operacional.lotes_produccion(id),
  fecha timestamptz NOT NULL DEFAULT now(),
  cantidad_animales integer NOT NULL CHECK (cantidad_animales > 0),
  peso_total_kg numeric(16,4) NOT NULL CHECK (peso_total_kg > 0),
  peso_promedio_kg numeric(16,4) NOT NULL CHECK (peso_promedio_kg > 0),
  etapa varchar(30) NOT NULL,
  responsable_id uuid REFERENCES operacional.usuarios(id),
  observacion text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS operacional.ventas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  id_local varchar(64),
  lote_id uuid NOT NULL REFERENCES operacional.lotes_produccion(id),
  fecha timestamptz NOT NULL DEFAULT now(),
  animales_vendidos integer NOT NULL CHECK (animales_vendidos > 0),
  peso_total_kg numeric(16,4) NOT NULL CHECK (peso_total_kg > 0),
  peso_promedio_kg numeric(16,4) NOT NULL CHECK (peso_promedio_kg > 0),
  precio_por_kg numeric(16,4) NOT NULL CHECK (precio_por_kg >= 0),
  total_venta numeric(16,4) NOT NULL CHECK (total_venta >= 0),
  comprador varchar(160),
  observacion text,
  responsable_id uuid REFERENCES operacional.usuarios(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version bigint NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS operacional.cursores_sincronizacion (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  granja_id uuid NOT NULL REFERENCES operacional.granjas(id),
  dispositivo_id uuid NOT NULL REFERENCES operacional.dispositivos(id),
  entidad varchar(80) NOT NULL,
  ultimo_updated_at timestamptz,
  ultima_version bigint NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (dispositivo_id, entidad)
);

CREATE INDEX IF NOT EXISTS idx_animales_granja_tipo
  ON operacional.animales (granja_id, tipo) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_productos_granja_categoria
  ON operacional.productos (granja_id, categoria) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_movimientos_producto_fecha
  ON operacional.movimientos_inventario (producto_id, fecha DESC)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_consumos_lote_fecha
  ON operacional.consumos (lote_id, fecha DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_consumos_animal_fecha
  ON operacional.consumos (animal_id, fecha DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_costos_lote_fecha
  ON operacional.costos_lote (lote_id, fecha DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_mortalidades_lote_fecha
  ON operacional.mortalidades (lote_id, fecha DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_ventas_lote_fecha
  ON operacional.ventas (lote_id, fecha DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_sync_productos
  ON operacional.productos (granja_id, updated_at, version);
CREATE INDEX IF NOT EXISTS idx_sync_lotes
  ON operacional.lotes_produccion (granja_id, updated_at, version);

DO $$
DECLARE
  tabla text;
BEGIN
  FOREACH tabla IN ARRAY ARRAY[
    'granjas', 'usuarios', 'dispositivos', 'configuraciones',
    'ubicaciones', 'corrales_jaulas', 'animales', 'historial_ubicaciones',
    'productos', 'conversiones_unidad', 'proveedores', 'compras',
    'compra_detalles', 'movimientos_inventario', 'formulas_alimento',
    'formula_ingredientes', 'preparaciones_alimento',
    'preparacion_ingredientes', 'ciclos_reproductivos', 'montas',
    'lotes_produccion', 'partos', 'abortos', 'movimientos_lote',
    'consumos', 'costos_lote', 'mortalidades', 'protocolos',
    'protocolo_detalles', 'ejecuciones_protocolo',
    'raciones_referencia', 'pesajes', 'ventas'
  ]
  LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS trg_%1$s_updated_at ON operacional.%1$I',
      tabla
    );
    EXECUTE format(
      'CREATE TRIGGER trg_%1$s_updated_at
       BEFORE UPDATE ON operacional.%1$I
       FOR EACH ROW EXECUTE FUNCTION operacional.actualizar_updated_at()',
      tabla
    );
  END LOOP;
END;
$$;

INSERT INTO operacional.granjas (
  nombre,
  codigo,
  propietario,
  departamento,
  municipio
)
VALUES (
  'Cabaña La Pampita',
  'LA_PAMPITA',
  NULL,
  NULL,
  NULL
)
ON CONFLICT (codigo) DO UPDATE
SET nombre = EXCLUDED.nombre;

INSERT INTO operacional.configuraciones (granja_id, clave, valor)
SELECT id, 'margen_ganancia', '{"porcentaje": 20}'::jsonb
FROM operacional.granjas
WHERE codigo = 'LA_PAMPITA'
ON CONFLICT (granja_id, clave) DO NOTHING;

INSERT INTO operacional.configuraciones (granja_id, clave, valor)
SELECT id, 'permitir_stock_negativo', '{"activo": false}'::jsonb
FROM operacional.granjas
WHERE codigo = 'LA_PAMPITA'
ON CONFLICT (granja_id, clave) DO NOTHING;

COMMIT;
