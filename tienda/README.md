# tienda

Manifiestos de la boletera de conciertos (namespace `tienda`). Corren en el
worker con el rol `app` (k8s-w1).

| Carpeta | Qué es | Estado |
|---|---|---|
| [`postgres/`](postgres/) | PostgreSQL 18.7 en StatefulSet, volumen en NFS, esquema y datos de ejemplo | ✅ |
| [`svc-eventos/`](svc-eventos/) | Catálogo de conciertos y métrica de negocio · 2 réplicas | ✅ |
| [`svc-reservaciones/`](svc-reservaciones/) | Carrito: bloqueo temporal de asientos | ✅ |
| [`svc-ordenes/`](svc-ordenes/) | Pago y pedidos | ✅ |
| [`frontend/`](frontend/) | Sitio web · 2 réplicas · Ingress **http://tienda.100.103.221.107.nip.io** | ✅ |
| [`trafico/`](trafico/) | Generador de tráfico para pruebas y demos · **apagado por defecto** | ✅ |

Cada carpeta de servicio tiene su `kustomization.yaml` con la etiqueta de la
imagen (`newTag` = SHA del commit en `equipoEmpiroso-app`). Desplegar una
versión nueva es cambiar esa línea; el pipeline de Tekton lo hará solo.
Detalle en [`docs/05-microservicios.md`](../docs/05-microservicios.md).

## Generador de tráfico (`trafico/`)

Recorre la tienda como un cliente: catálogo, página de un concierto, cada 5
clientes aparta 2 lugares y cancela el carrito, y consulta un pedido. Así los
dashboards de aplicación tienen peticiones y latencia, y con `ERROR_RATE` se
pueden ver los errores 5xx. **Nunca paga**: no cambia los boletos vendidos.

Es un CronJob **suspendido**: no corre hasta que se lanza una ejecución, que
dura 20 minutos (unas 2 peticiones/s entre los 4 servicios) y termina sola.

```bash
kubectl -n tienda create job trafico-$(date +%H%M) --from=cronjob/trafico   # encender
kubectl -n tienda logs -f -l app.kubernetes.io/name=trafico                 # ver el resumen cada minuto
kubectl -n tienda delete job -l app.kubernetes.io/name=trafico              # apagar antes de tiempo
```

Lanzarlo o detenerlo no cambia nada de Git: Argo CD sigue en Synced. La
duración, la pausa entre clientes y el pedido que consulta están en
`trafico/cronjob.yaml`.

## PostgreSQL (`postgres/`)

| Archivo | Qué hace |
|---|---|
| `kustomization.yaml` | Junta los manifiestos y convierte `init/` en el ConfigMap `postgres-init` |
| `statefulset.yaml` | PostgreSQL 18.7, 1 réplica, volumen de 5 GiB en el StorageClass `nfs` |
| `services.yaml` | `postgres` (lo usan los microservicios) y `postgres-headless` (lo usa el StatefulSet) |
| `configmap.yaml` | Base `boletera`, usuario `boletera_app`, zona horaria |
| `init/01-esquema.sql` | Tablas, restricciones, índices y vistas (esquema versión `001`) |
| `init/02-datos.sql` | 22 conciertos de artistas reales en recintos reales, con su aforo: 368,823 asientos en 3 secciones y ~91,400 órdenes de ejemplo |
| `init/03-usuario-app.sh` | Crea `boletera_app`: lee y escribe datos, pero no puede cambiar tablas |

Los scripts de `init/` solo corren **la primera vez**, con el volumen vacío.
Los cambios de esquema posteriores se hacen con migraciones (`ALTER TABLE ...`)
y se registran en la tabla `esquema_version`.

### Secrets (no están en Git)

Se crean **una vez**, a mano, antes de que Argo CD despliegue PostgreSQL. Las
contraseñas se generan al azar y nunca se muestran:

```bash
kubectl -n tienda create secret generic postgres-admin \
  --from-literal=POSTGRES_PASSWORD="$(head -c 24 /dev/urandom | base64 | tr -d '/+=')"
kubectl -n tienda create secret generic postgres-app \
  --from-literal=APP_DB_PASSWORD="$(head -c 24 /dev/urandom | base64 | tr -d '/+=')"
```

| Secret | Contraseña de | Quién lo monta |
|---|---|---|
| `postgres-admin` | `postgres` (administrador) | solo el pod de PostgreSQL |
| `postgres-app` | `boletera_app` | PostgreSQL (al crear el usuario) y los microservicios |

No hay que borrarlos: la base guarda las contraseñas al inicializarse, y un
Secret nuevo con otra contraseña ya no coincidiría.

## Contrato de datos para los microservicios

### Conexión

| Variable | Valor |
|---|---|
| Host | `postgres.tienda.svc.cluster.local` (o `postgres` desde el namespace `tienda`) |
| Puerto | `5432` |
| Base | `boletera` |
| Usuario | `boletera_app` (ConfigMap `postgres-config`, clave `APP_DB_USER`) |
| Contraseña | Secret `postgres-app`, clave `APP_DB_PASSWORD` |

### Tablas y quién escribe en cada una

| Tabla / vista | Qué guarda | Escribe | Lee |
|---|---|---|---|
| `eventos` | Conciertos: artista, género, recinto, fecha, `precio_base`, `capacidad`, `activo` | — (datos iniciales) | svc-eventos |
| `asientos` | Un registro por lugar: `seccion` (VIP, Preferente, General), `fila`, `numero`, `precio`, `estado` | svc-reservaciones (bloquear), svc-ordenes (vender) | todos |
| `reservaciones` | El **carrito**: asientos apartados por una `sesion` del navegador hasta `expira_en` | svc-reservaciones | svc-ordenes |
| `ordenes` | Pedidos pagados: cliente, `cantidad`, `total`, `reservacion_id` (único) | svc-ordenes | svc-ordenes |
| `asientos_estado_actual` (vista) | Estado real de cada asiento: un bloqueo vencido cuenta como `disponible` | — | todos |
| `ventas_por_evento` (vista) | Métrica de negocio: `vendidos`, `bloqueados`, `disponibles`, `porcentaje_vendido` | — | svc-eventos (`/metrics`) |
| `esquema_version` | Versiones del esquema aplicadas | migraciones | — |

### Flujo de compra

1. **Catálogo** (svc-eventos): `eventos WHERE activo`, y por cada evento sus secciones con precio y lugares disponibles:
   ```sql
   SELECT seccion, precio, count(*) FILTER (WHERE estado = 'disponible') AS disponibles
   FROM asientos_estado_actual WHERE evento_id = $1 GROUP BY seccion, precio;
   ```
2. **Agregar al carrito** (svc-reservaciones): el usuario elige **sección y cantidad**, como en una boletera real. Los recintos tienen miles de lugares, así que no se elige asiento por asiento en un mapa. Se crea una `reservacion` y se bloquean los **mejores lugares disponibles** en una sola sentencia:
   ```sql
   WITH elegidos AS (
       SELECT id FROM asientos
       WHERE evento_id = $1 AND seccion = $2
         AND (estado = 'disponible' OR (estado = 'bloqueado' AND bloqueado_hasta <= now()))
       ORDER BY id                 -- los ids van de los mejores lugares a los peores
       LIMIT $3                    -- cantidad de boletos
       FOR UPDATE SKIP LOCKED      -- salta los que otra compra está tomando en ese instante
   )
   UPDATE asientos a
   SET estado = 'bloqueado', reservacion_id = $4, bloqueado_hasta = now() + interval '10 minutes'
   FROM elegidos e WHERE a.id = e.id
   RETURNING a.id, a.fila, a.numero, a.precio;
   ```
   Si regresa menos filas que boletos pedidos, ya no hay suficientes en esa sección: se deshace la operación y se avisa al usuario. Con `SKIP LOCKED`, dos compras simultáneas reciben lugares distintos sin esperarse entre sí. En un estadio de 65,000 lugares tarda unos 100 ms.
3. **Pagar** (svc-ordenes), en una transacción: insertar la `orden` con su `reservacion_id`, pasar sus asientos a `vendido` con `orden_id`, y marcar la reservación como `confirmada`. Si el navegador reintenta, `reservacion_id UNIQUE` impide cobrar dos veces.

La base también se protege sola. La restricción `asiento_coherente` rechaza,
por ejemplo, un asiento `vendido` sin orden.

### Métrica y alerta de negocio

- **Métrica:** boletos vendidos por evento → `ventas_por_evento.vendidos` y `porcentaje_vendido`.
- **Alerta:** evento con más del 90 % vendido. Con los datos de ejemplo ya la cumplen el evento 1 (Humbe, 92 %) y el 3 (Los Bukis, 96 %).
- **Demo en vivo:** el evento 13 (Siddhartha, Lunario, 1,000 lugares) queda en **89.8 %**. Comprar 4 boletos lo pasa a 90.2 % y dispara la alerta.

### Datos de ejemplo

Los artistas y recintos son reales, y la capacidad de cada evento es el aforo
del recinto. Precios y ventas son inventados para una demo académica; **no es
una venta real**. Los eventos 1-3, 5, 8-11 y 22 vienen de la cartelera que
reunió el equipo, y los demás son conciertos imaginarios de artistas reales.
