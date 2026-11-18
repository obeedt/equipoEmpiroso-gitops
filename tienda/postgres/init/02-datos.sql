-- ─────────────────────────────────────────────────────────────────────
-- Datos de ejemplo: 22 conciertos (la rúbrica pide mínimo 20 productos),
-- sus asientos por sección y órdenes ya pagadas, para que la métrica de
-- negocio tenga datos reales desde el primer día. Artistas ficticios.
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO eventos (nombre, artista, genero, descripcion, recinto, ciudad, fecha, precio_base, capacidad) VALUES
('Gira Faro del Norte',        'Los Faroles',             'Pop rock',     'La banda regresa con su gira más grande.',                    'Auditorio Nacional',        'Ciudad de México', '2026-12-05 21:00-06',  850.00, 100),
('Noche de Cumbia Sideral',    'Sonido Galaxia',          'Cumbia',       'Cumbia electrónica para bailar toda la noche.',               'Arena Monterrey',           'Monterrey',        '2026-12-12 20:30-06',  600.00, 150),
('Acústico en el Bosque',      'Marea Lenta',             'Folk',         'Formato íntimo, solo guitarras y voces.',                     'Teatro Metropólitan',       'Ciudad de México', '2026-12-18 20:00-06',  450.00,  80),
('Rock de los 90 Revive',      'Voltaje Sur',             'Rock',         'Los himnos de una década, en vivo.',                          'Palacio de los Deportes',   'Ciudad de México', '2027-01-16 21:00-06',  750.00, 200),
('Sinfonía de Videojuegos',    'Orquesta Pixel',          'Orquestal',    'Bandas sonoras de videojuegos con orquesta completa.',        'Auditorio Telmex',          'Guadalajara',      '2027-01-23 19:00-06',  650.00, 120),
('Jazz al Atardecer',          'Cuarteto Brisa',          'Jazz',         'Estándares de jazz y composiciones propias.',                 'Teatro Diana',              'Guadalajara',      '2027-01-30 20:00-06',  480.00,  60),
('Electrónica sin Fin',        'DJ Aurora Boreal',        'Electrónica',  'Set de cuatro horas con producción visual.',                  'Foro Sol',                  'Ciudad de México', '2027-02-06 22:00-06',  990.00, 200),
('Boleros para Siempre',       'Trío Luna Llena',         'Bolero',       'Los boleros clásicos, como en los años cincuenta.',           'Teatro de la Ciudad',       'Ciudad de México', '2027-02-13 19:30-06',  380.00,  70),
('Metal Volcánico',            'Fuego Andesita',          'Metal',        'Presentación de su nuevo disco.',                             'Arena CDMX',                'Ciudad de México', '2027-02-20 20:00-06',  880.00, 150),
('Regional en Grande',         'Banda Tres Ríos',         'Regional',     'Banda sinaloense con invitados especiales.',                  'Estadio Akron',             'Guadalajara',      '2027-03-06 21:00-06',  700.00, 200),
('Pop de Verano',              'Mía Solana',              'Pop',          'El concierto de cierre de su gira por Latinoamérica.',        'Arena Monterrey',           'Monterrey',        '2027-03-13 20:30-06', 1100.00, 180),
('Indie en la Azotea',         'Los Cometas Tardíos',     'Indie',        'Lanzamiento de su segundo álbum.',                            'Lunario',                   'Ciudad de México', '2027-03-20 21:00-06',  350.00,  60),
('Trova bajo las Estrellas',   'Canto Rodado',            'Trova',        'Canciones de autor en un teatro histórico.',                  'Teatro Juárez',             'Guanajuato',       '2027-03-27 20:00-06',  360.00,  60),
('Salsa Brava',                'Orquesta Malecón',        'Salsa',        'Salsa dura con orquesta de quince músicos.',                  'Explanada del Fórum',       'Mérida',           '2027-04-03 21:00-06',  520.00, 120),
('Hip Hop del Barrio',         'Rima Firme',              'Hip hop',      'Rimas, scratch y graffiti en vivo.',                          'Pepsi Center WTC',          'Ciudad de México', '2027-04-10 21:30-06',  620.00, 140),
('Clásicos del Rock Nacional', 'Generación Vinilo',       'Rock',         'Homenaje al rock mexicano de los ochenta.',                   'Auditorio Citibanamex',     'Monterrey',        '2027-04-17 20:30-06',  780.00, 160),
('Reggae a la Orilla',         'Raíces de Arena',         'Reggae',       'Concierto frente al mar.',                                    'Foro Playa',                'Cancún',           '2027-04-24 19:00-06',  470.00, 100),
('Ópera para Todos',           'Compañía Bel Canto',      'Ópera',        'Arias famosas con subtítulos en pantalla.',                   'Palacio de Bellas Artes',   'Ciudad de México', '2027-05-01 19:00-06', 1700.00,  60),
('Ska Total',                  'Los Tremendos',           'Ska',          'Dos horas de ska sin pausas.',                                'Auditorio Benito Juárez',   'Zapopan',          '2027-05-08 20:00-06',  420.00, 130),
('Noche de Mariachi',          'Mariachi Nuevo Amanecer', 'Mariachi',     'Mariachi tradicional con ballet folclórico.',                 'Plaza de los Mariachis',    'Guadalajara',      '2027-05-15 20:00-06',  300.00, 100),
('Festival Sonidos del Sur',   'Varios artistas',         'Festival',     'Ocho bandas en un día al aire libre.',                        'Parque Fundidora',          'Monterrey',        '2027-05-29 16:00-06', 1250.00, 200),
('Despedida de Gira',          'Los Faroles',             'Pop rock',     'Último concierto de la gira, con canciones inéditas.',        'Foro Sol',                  'Ciudad de México', '2027-06-12 21:00-06',  950.00, 200);

-- Asientos en filas de 10 lugares (A, B, C, ...), tantos como la
-- capacidad del evento. Secciones y precio (sobre el precio base):
--   filas A-B  → VIP         × 2.0
--   filas C-E  → Preferente  × 1.5
--   filas F-…  → General     × 1.0
INSERT INTO asientos (evento_id, seccion, fila, numero, precio)
SELECT e.id,
       CASE WHEN f < 2 THEN 'VIP' WHEN f < 5 THEN 'Preferente' ELSE 'General' END,
       chr(65 + f),
       ((n - 1) % 10) + 1,
       e.precio_base * CASE WHEN f < 2 THEN 2.0 WHEN f < 5 THEN 1.5 ELSE 1.0 END
FROM eventos e
CROSS JOIN LATERAL generate_series(1, e.capacidad) AS n
CROSS JOIN LATERAL (SELECT (n - 1) / 10 AS f) AS fila;

-- Venta inicial por evento (porcentaje de la capacidad). Los eventos 1 y 2
-- quedan arriba del 90 % para poder demostrar la alerta de negocio.
CREATE TEMP TABLE venta_inicial (evento_id INTEGER, porcentaje INTEGER);
INSERT INTO venta_inicial VALUES
    (1, 96), (2, 92), (3, 80), (4, 70), (5, 64), (6, 50), (7, 45), (8, 40),
    (9, 34), (10, 30), (11, 26), (12, 20), (13, 16), (14, 12), (15, 10),
    (16, 8), (17, 6), (18, 4), (19, 2), (20, 0), (21, 0), (22, 0);

-- Órdenes de 2 boletos cada una (el total se calcula abajo, con los
-- precios de los asientos que le toquen)
INSERT INTO ordenes (evento_id, cliente_nombre, cliente_email, cantidad, total, creada_en)
SELECT e.id,
       'Cliente de prueba ' || g,
       'cliente' || e.id || '-' || g || '@ejemplo.com',
       2,
       0,
       now() - g * interval '37 minutes'
FROM venta_inicial v
JOIN eventos e ON e.id = v.evento_id
CROSS JOIN LATERAL generate_series(1, (e.capacidad * v.porcentaje / 100) / 2) AS g;

-- Cada orden se queda con 2 asientos consecutivos de su evento
WITH o AS (
    SELECT id, evento_id, row_number() OVER (PARTITION BY evento_id ORDER BY id) AS n
    FROM ordenes
), a AS (
    SELECT id, evento_id, row_number() OVER (PARTITION BY evento_id ORDER BY id) AS n
    FROM asientos
)
UPDATE asientos s
SET estado = 'vendido',
    orden_id = o.id
FROM a
JOIN o ON o.evento_id = a.evento_id AND o.n = (a.n + 1) / 2
WHERE s.id = a.id;

-- Total de cada orden = suma de los precios de sus asientos
UPDATE ordenes o
SET total = t.total
FROM (SELECT orden_id, sum(precio) AS total FROM asientos WHERE orden_id IS NOT NULL GROUP BY orden_id) AS t
WHERE t.orden_id = o.id;
