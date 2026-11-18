# tienda

Manifiestos de la boletera de conciertos (namespace `tienda`). Corren en el
worker con el rol `app` (k8s-w1).

| Carpeta | Qué es | Estado |
|---|---|---|
| [`postgres/`](postgres/) | PostgreSQL 18.7 en StatefulSet, volumen en NFS, esquema y datos de ejemplo | ✅ |
| `frontend/`, `svc-eventos/`, `svc-ordenes/`, `svc-reservaciones/` | Deployment, Service y ConfigMap de cada microservicio | pendiente |
| Ingress de la tienda | `tienda.100.103.221.107.nip.io` | pendiente |

El tag de cada imagen lo actualizará el pipeline de Tekton con el SHA del commit.

## PostgreSQL (`postgres/`)

| Archivo | Qué hace |
|---|---|
| `kustomization.yaml` | Junta los manifiestos y convierte `init/` en el ConfigMap `postgres-init` |
| `statefulset.yaml` | PostgreSQL 18.7, 1 réplica, volumen de 5 GiB en el StorageClass `nfs` |
| `services.yaml` | `postgres` (lo usan los microservicios) y `postgres-headless` (lo usa el StatefulSet) |
| `configmap.yaml` | Base `boletera`, usuario `boletera_app`, zona horaria |
| `init/01-esquema.sql` | Tablas, restricciones, índices y vistas (esquema versión `001`) |
| `init/02-datos.sql` | 22 conciertos, 2,840 asientos en 3 secciones y 444 órdenes de ejemplo |
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

1. **Catálogo** (svc-eventos): `eventos WHERE activo`, y el mapa de asientos desde `asientos_estado_actual`.
2. **Agregar al carrito** (svc-reservaciones): crear una `reservacion` y bloquear los asientos en **un solo `UPDATE`**, que solo toma los que siguen libres:
   ```sql
   UPDATE asientos
   SET estado = 'bloqueado', reservacion_id = $1, bloqueado_hasta = now() + interval '10 minutes'
   WHERE evento_id = $2 AND id = ANY($3)
     AND (estado = 'disponible' OR (estado = 'bloqueado' AND bloqueado_hasta <= now()));
   ```
   Si actualiza menos filas que asientos pedidos, alguien más los ganó: se deshace la operación y se avisa al usuario. Así dos personas nunca bloquean el mismo asiento.
3. **Pagar** (svc-ordenes), en una transacción: insertar la `orden` con su `reservacion_id`, pasar sus asientos a `vendido` con `orden_id`, y marcar la reservación como `confirmada`. Si el navegador reintenta, `reservacion_id UNIQUE` impide cobrar dos veces.

La base también se protege sola. La restricción `asiento_coherente` rechaza,
por ejemplo, un asiento `vendido` sin orden.

### Métrica y alerta de negocio

- **Métrica:** boletos vendidos por evento → `ventas_por_evento.vendidos` y `porcentaje_vendido`.
- **Alerta:** evento con más del 90 % vendido. Los eventos 1 (96 %) y 2 (92 %) ya la cumplen con los datos de ejemplo.
