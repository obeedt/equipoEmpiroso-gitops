-- ─────────────────────────────────────────────────────────────────────
-- Datos de ejemplo: 22 conciertos (la rúbrica pide mínimo 20 productos),
-- sus asientos por sección y órdenes ya pagadas.
--
-- DATOS DE EJEMPLO PARA UNA DEMO ACADÉMICA. No es una venta real.
-- Artistas y recintos son reales; la capacidad de cada evento es el aforo
-- del recinto (Wikipedia, nov 2026; los marcados "aprox." no se pudieron
-- confirmar). Precios y ventas son inventados. Los eventos 1-3, 5, 8-11 y
-- 22 (nombre, fecha y recinto) vienen de la cartelera que reunió el equipo;
-- los demás son conciertos imaginarios de artistas reales.
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO eventos (nombre, artista, genero, descripcion, recinto, ciudad, fecha, precio_base, capacidad) VALUES
-- 1-3
('Dueño del Cielo Tour Finale', 'Humbe',                     'Pop',               'Cierre de la gira Dueño del Cielo.',           'Arena CDMX',                       'Ciudad de México',       '2026-12-04 21:00-06', 1200.00, 22300),
('Enjambre en concierto',       'Enjambre',                  'Rock alternativo',  'Rock alternativo en Monterrey.',               'Auditorio Banamex',                'Monterrey',              '2026-12-17 21:00-06',  950.00,  7000),
('La Despedida',                'Los Bukis',                 'Grupera',           'La gira de despedida de Los Bukis.',           'Coliseo GNP Seguros',              'Zapopan',                '2026-12-18 21:00-06', 1500.00, 15000), -- aforo aprox.
-- 4
('Café Tacvba en concierto',    'Café Tacvba',               'Rock alternativo',  'Un recorrido por toda su discografía.',        'Auditorio Nacional',               'Ciudad de México',       '2027-01-09 20:30-06', 1100.00, 10000),
-- 5
('NSQK en concierto',           'NSQK',                      'Pop',               'Concierto en estadio.',                        'Estadio GNP Seguros',              'Ciudad de México',       '2027-01-23 21:00-06', 1100.00, 65000),
-- 6-7
('Natalia Lafourcade en concierto', 'Natalia Lafourcade',    'Pop folk',          'Formato acústico con orquesta.',               'Teatro Metropólitan',              'Ciudad de México',       '2027-01-29 20:30-06',  980.00,  3165),
('Zoé en concierto',            'Zoé',                       'Rock alternativo',  'Zoé en la Arena Monterrey.',                   'Arena Monterrey',                  'Monterrey',              '2027-02-13 21:00-06', 1050.00, 17599),
-- 8-11
('Urbano Fest',                 'Varios artistas',           'Urbano',            'Festival de música urbana.',                   'Pepsi Center WTC',                 'Ciudad de México',       '2027-02-20 19:00-06', 1300.00,  7500), -- aforo aprox.
('I''m Back',                   'Pitbull',                   'Pop urbano',        'Pitbull de regreso en Monterrey.',             'Auditorio Banamex',                'Monterrey',              '2027-02-21 20:00-06', 1600.00,  7000),
('Deadbeat Tour',               'Tame Impala',               'Rock psicodélico',  'La gira Deadbeat llega a Jalisco.',            'Arena VFG',                        'Tlajomulco de Zúñiga',   '2027-02-23 21:00-06', 1450.00, 15000),
('Interpol & Queens of the Stone Age', 'Interpol & Queens of the Stone Age', 'Rock alternativo', 'Dos bandas en una sola noche.', 'Estadio Ciudad de los Deportes', 'Ciudad de México', '2027-03-06 19:30-06', 1700.00, 33000), -- aforo aprox.
-- 12-21
('Molotov en concierto',        'Molotov',                   'Rap rock',          'Molotov en el Auditorio Telmex.',              'Auditorio Telmex',                 'Zapopan',                '2027-03-13 21:00-06',  850.00, 11500),
('Siddhartha en concierto',     'Siddhartha',                'Rock alternativo',  'Concierto íntimo en el Lunario.',              'Lunario del Auditorio Nacional',   'Ciudad de México',       '2027-03-20 21:00-06',  650.00,  1000),
('Julieta Venegas en concierto','Julieta Venegas',           'Pop',               'Julieta Venegas en el Teatro Diana.',          'Teatro Diana',                     'Guadalajara',            '2027-03-27 20:30-06',  900.00,  2345),
('Carín León en concierto',     'Carín León',                'Regional mexicano', 'Concierto en estadio.',                        'Estadio Akron',                    'Zapopan',                '2027-04-17 21:00-06', 1250.00, 49850),
('Los Ángeles Azules en concierto', 'Los Ángeles Azules',    'Cumbia',            'Cumbia sinfónica para bailar.',                'Arena CDMX',                       'Ciudad de México',       '2027-04-24 21:00-06',  890.00, 22300),
('Caifanes en concierto',       'Caifanes',                  'Rock',              'Los clásicos del rock mexicano.',              'Palacio de los Deportes',          'Ciudad de México',       '2027-05-08 21:00-06', 1150.00, 20000),
('Panteón Rococó en concierto', 'Panteón Rococó',            'Ska',               'Ska para toda la noche.',                      'Arena Monterrey',                  'Monterrey',              '2027-05-15 21:00-06',  750.00, 17599),
('Belanova en concierto',       'Belanova',                  'Pop electrónico',   'Belanova en el Auditorio Telmex.',             'Auditorio Telmex',                 'Zapopan',                '2027-05-22 21:00-06',  820.00, 11500),
('Kinky en concierto',          'Kinky',                     'Electrónica',       'Kinky en casa, en Monterrey.',                 'Auditorio Banamex',                'Monterrey',              '2027-06-05 21:00-06',  780.00,  7000),
('Ximena Sariñana en concierto','Ximena Sariñana',           'Pop',               'Ximena Sariñana en el Teatro Metropólitan.',   'Teatro Metropólitan',              'Ciudad de México',       '2027-06-12 20:30-06',  850.00,  3165),
-- 22
('Flakk Tour 2027',             'Rels B',                    'Pop urbano',        'La gira Flakk llega a la Ciudad de México.',   'Palacio de los Deportes',          'Ciudad de México',       '2027-09-07 20:00-06', 1350.00, 20000);

-- Asientos: uno por lugar del aforo, en filas de 50. La sección depende de
-- la posición en el recinto (los primeros lugares son los mejores):
--   primer 5 %       → VIP         × 2.0
--   siguiente 25 %   → Preferente  × 1.5
--   resto (70 %)     → General     × 1.0
-- En recintos de miles de asientos el usuario elige sección y cantidad, y
-- svc-reservaciones asigna los mejores lugares disponibles.
INSERT INTO asientos (evento_id, seccion, fila, numero, precio)
SELECT e.id,
       s.seccion,
       ((n - 1) / 50 + 1)::text,
       ((n - 1) % 50) + 1,
       e.precio_base * s.factor
FROM eventos e
CROSS JOIN LATERAL generate_series(1, e.capacidad) AS n
CROSS JOIN LATERAL (
    SELECT CASE WHEN n <= e.capacidad * 0.05 THEN 'VIP'
                WHEN n <= e.capacidad * 0.30 THEN 'Preferente'
                ELSE 'General' END AS seccion,
           CASE WHEN n <= e.capacidad * 0.05 THEN 2.0
                WHEN n <= e.capacidad * 0.30 THEN 1.5
                ELSE 1.0 END AS factor
) AS s;

-- Venta inicial por evento (porcentaje de cada sección; se vende en pares):
--   eventos 1 y 3 arriba del 90 %  → la alerta de negocio ya está activa
--   evento 13 (Lunario, 1,000)     → queda en 89.8 %: comprar 4 boletos en
--                                    vivo lo pasa a 90.2 % y dispara la alerta
CREATE TEMP TABLE venta_inicial (evento_id INTEGER, porcentaje NUMERIC);
INSERT INTO venta_inicial VALUES
    (1, 92), (2, 80), (3, 96), (4, 75), (5, 70), (6, 64), (7, 58), (8, 50),
    (9, 45), (10, 85), (11, 66), (12, 40), (13, 90), (14, 35), (15, 30),
    (16, 26), (17, 22), (18, 15), (19, 10), (20, 6), (21, 2), (22, 0);

-- Asientos vendidos: en CADA sección se venden los primeros lugares hasta
-- el porcentaje del evento (redondeado a pares, porque cada orden es de 2).
-- "s" numera los vendidos de cada evento; como los ids van por sección,
-- cada par (s, s+1) queda en la misma sección.
CREATE TEMP TABLE vendidos AS
SELECT id, evento_id, row_number() OVER (PARTITION BY evento_id ORDER BY id) AS s
FROM (
    SELECT a.id,
           a.evento_id,
           row_number() OVER (PARTITION BY a.evento_id, a.seccion ORDER BY a.id) AS lugar,
           count(*)     OVER (PARTITION BY a.evento_id, a.seccion)                AS lugares,
           v.porcentaje
    FROM asientos a
    JOIN venta_inicial v ON v.evento_id = a.evento_id
) x
WHERE lugar <= floor(lugares * porcentaje / 100 / 2) * 2;

-- Órdenes de 2 boletos cada una (el total se calcula abajo)
INSERT INTO ordenes (evento_id, cliente_nombre, cliente_email, cantidad, total, creada_en)
SELECT e.evento_id,
       'Cliente de prueba ' || g,
       'cliente' || e.evento_id || '-' || g || '@ejemplo.com',
       2,
       0,
       now() - g * interval '1 minute'
FROM (SELECT evento_id, count(*) / 2 AS ordenes FROM vendidos GROUP BY evento_id) e
CROSS JOIN LATERAL generate_series(1, e.ordenes::int) AS g;

-- La orden n de cada evento se queda con los vendidos 2n-1 y 2n
WITH o AS (
    SELECT id, evento_id, row_number() OVER (PARTITION BY evento_id ORDER BY id) AS n
    FROM ordenes
)
UPDATE asientos a
SET estado = 'vendido',
    orden_id = o.id
FROM vendidos v
JOIN o ON o.evento_id = v.evento_id AND o.n = (v.s + 1) / 2
WHERE a.id = v.id;

-- Total de cada orden = suma de los precios de sus asientos
UPDATE ordenes o
SET total = t.total
FROM (SELECT orden_id, sum(precio) AS total FROM asientos WHERE orden_id IS NOT NULL GROUP BY orden_id) AS t
WHERE t.orden_id = o.id;

ANALYZE;
