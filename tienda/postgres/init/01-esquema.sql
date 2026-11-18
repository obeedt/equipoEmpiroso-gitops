-- ─────────────────────────────────────────────────────────────────────
-- Esquema de la boletera de conciertos · versión 001
--
-- Se ejecuta UNA sola vez, cuando PostgreSQL inicializa su directorio de
-- datos vacío. Los cambios posteriores se hacen con migraciones
-- (ALTER TABLE ...) y se registran en esquema_version.
--
-- Flujo de compra y qué microservicio escribe en cada tabla:
--   1. svc-eventos        lee eventos y el mapa de asientos     (solo lectura)
--   2. svc-reservaciones  crea una reservación y BLOQUEA asientos unos
--                         minutos: es el "carrito" de la boletera
--   3. svc-ordenes        convierte la reservación en una orden pagada y
--                         marca los asientos como VENDIDOS
-- ─────────────────────────────────────────────────────────────────────

CREATE TABLE esquema_version (
    version      TEXT        PRIMARY KEY,
    descripcion  TEXT        NOT NULL,
    aplicada_en  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Catálogo ─────────────────────────────────────────────────────────
CREATE TABLE eventos (
    id            INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre        TEXT          NOT NULL,
    artista       TEXT          NOT NULL,
    genero        TEXT          NOT NULL,
    descripcion   TEXT          NOT NULL DEFAULT '',
    recinto       TEXT          NOT NULL,
    ciudad        TEXT          NOT NULL,
    fecha         TIMESTAMPTZ   NOT NULL,
    precio_base   NUMERIC(10,2) NOT NULL CHECK (precio_base > 0),  -- sección General ("desde $...")
    capacidad     INTEGER       NOT NULL CHECK (capacidad > 0),     -- = número de asientos del evento
    activo        BOOLEAN       NOT NULL DEFAULT true,              -- false: no se muestra ni se vende
    creado_en     TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- ── Carrito: reservación temporal de asientos (svc-reservaciones) ────
-- "sesion" identifica el carrito del navegador (la genera el frontend).
-- Al vencer expira_en, sus asientos vuelven a estar disponibles.
CREATE TABLE reservaciones (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    evento_id   INTEGER     NOT NULL REFERENCES eventos (id),
    sesion      TEXT        NOT NULL,
    estado      TEXT        NOT NULL DEFAULT 'activa'
                CHECK (estado IN ('activa', 'confirmada', 'expirada', 'cancelada')),
    expira_en   TIMESTAMPTZ NOT NULL,
    creada_en   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Pedidos (svc-ordenes) ────────────────────────────────────────────
-- reservacion_id es UNIQUE: una reservación solo puede pagarse una vez,
-- aunque el navegador reintente la petición. Las órdenes de ejemplo no
-- tienen reservación (venta inicial).
CREATE TABLE ordenes (
    id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    evento_id       INTEGER       NOT NULL REFERENCES eventos (id),
    reservacion_id  UUID          UNIQUE REFERENCES reservaciones (id),
    cliente_nombre  TEXT          NOT NULL,
    cliente_email   TEXT          NOT NULL,
    cantidad        INTEGER       NOT NULL CHECK (cantidad BETWEEN 1 AND 10),
    total           NUMERIC(10,2) NOT NULL CHECK (total >= 0),
    estado          TEXT          NOT NULL DEFAULT 'pagada'
                    CHECK (estado IN ('pendiente', 'pagada', 'cancelada')),
    creada_en       TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- ── Asientos: uno por lugar de cada evento ───────────────────────────
-- Cada asiento tiene su precio (depende de la sección). El estado y las
-- columnas relacionadas deben ser coherentes (CHECK asiento_coherente):
--   disponible → sin reservación, sin bloqueo y sin orden
--   bloqueado  → con reservación y con fecha de vencimiento del bloqueo
--   vendido    → con orden
CREATE TABLE asientos (
    id               INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    evento_id        INTEGER       NOT NULL REFERENCES eventos (id) ON DELETE CASCADE,
    seccion          TEXT          NOT NULL CHECK (seccion IN ('VIP', 'Preferente', 'General')),
    fila             TEXT          NOT NULL,
    numero           INTEGER       NOT NULL CHECK (numero > 0),
    precio           NUMERIC(10,2) NOT NULL CHECK (precio > 0),
    estado           TEXT          NOT NULL DEFAULT 'disponible'
                     CHECK (estado IN ('disponible', 'bloqueado', 'vendido')),
    reservacion_id   UUID          REFERENCES reservaciones (id),
    bloqueado_hasta  TIMESTAMPTZ,
    orden_id         INTEGER       REFERENCES ordenes (id),
    UNIQUE (evento_id, fila, numero),
    CONSTRAINT asiento_coherente CHECK (
        (estado = 'disponible' AND reservacion_id IS NULL AND bloqueado_hasta IS NULL AND orden_id IS NULL)
     OR (estado = 'bloqueado'  AND reservacion_id IS NOT NULL AND bloqueado_hasta IS NOT NULL AND orden_id IS NULL)
     OR (estado = 'vendido'    AND orden_id IS NOT NULL)
    )
);

-- Para "mejores lugares disponibles" de una sección (estadios de miles de asientos)
CREATE INDEX asientos_evento_seccion_estado ON asientos (evento_id, seccion, estado);
CREATE INDEX asientos_reservacion   ON asientos (reservacion_id) WHERE reservacion_id IS NOT NULL;
CREATE INDEX asientos_orden         ON asientos (orden_id) WHERE orden_id IS NOT NULL;
CREATE INDEX ordenes_evento         ON ordenes (evento_id);
CREATE INDEX reservaciones_activas  ON reservaciones (expira_en) WHERE estado = 'activa';

-- ── Vistas ───────────────────────────────────────────────────────────
-- Estado real de cada asiento: un bloqueo vencido cuenta como disponible
-- aunque nadie lo haya liberado todavía. Todos los servicios deben leer
-- la disponibilidad de aquí, para que coincidan entre sí.
CREATE VIEW asientos_estado_actual AS
SELECT a.id,
       a.evento_id,
       a.seccion,
       a.fila,
       a.numero,
       a.precio,
       CASE WHEN a.estado = 'bloqueado' AND a.bloqueado_hasta <= now()
            THEN 'disponible'
            ELSE a.estado
       END AS estado,
       a.reservacion_id,
       a.bloqueado_hasta,
       a.orden_id
FROM asientos a;

-- Métrica de negocio del proyecto 3: boletos vendidos por evento.
-- La alerta de negocio se dispara con más del 90 % vendido.
CREATE VIEW ventas_por_evento AS
SELECT e.id,
       e.nombre,
       e.artista,
       e.recinto,
       e.ciudad,
       e.capacidad,
       count(*) FILTER (WHERE a.estado = 'vendido')                                 AS vendidos,
       count(*) FILTER (WHERE a.estado = 'bloqueado')                               AS bloqueados,
       count(*) FILTER (WHERE a.estado = 'disponible')                              AS disponibles,
       round(100.0 * count(*) FILTER (WHERE a.estado = 'vendido') / e.capacidad, 1) AS porcentaje_vendido
FROM eventos e
JOIN asientos_estado_actual a ON a.evento_id = e.id
GROUP BY e.id;

INSERT INTO esquema_version (version, descripcion)
VALUES ('001', 'Esquema inicial: eventos, reservaciones, ordenes, asientos y vistas');
