# tienda

Manifiestos de la boletera de conciertos (namespace `tienda`). Corren en el
worker con el rol `app`.

- **Microservicios**: Deployment y Service de cada uno.
  - `frontend`
  - `svc-eventos`
  - `svc-ordenes`
  - `svc-reservaciones` (bloqueo temporal de asientos)
- **Base de datos**: PostgreSQL en un StatefulSet con volumen persistente (NFS) y su script de datos de ejemplo.
- **Ingress** de la tienda.
- **ConfigMaps** con la configuración de cada servicio.

Las contraseñas **no** se guardan aquí: van en Secrets creados fuera de Git.
El tag de cada imagen lo actualiza el pipeline de Tekton con el SHA del commit.
