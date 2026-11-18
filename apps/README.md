# apps

Applications de **Argo CD**, con el patrón **app-of-apps**: la Application
`root` lee esta carpeta y crea todas las demás. Para agregar un componente al
clúster basta con un archivo nuevo aquí y un `git push`.

`root.yaml` se aplicó a mano **una sola vez** (`kubectl apply -f apps/root.yaml`).
Es el único `kubectl apply` del proyecto, y `root` se excluye a sí misma.

## Applications

| Archivo | Application | Qué instala | Origen | Namespace |
|---|---|---|---|---|
| [`root.yaml`](root.yaml) | `root` | Todas las de esta carpeta | `apps/` de este repo | `argocd` |
| [`namespaces.yaml`](namespaces.yaml) | `namespaces` | `tienda`, `monitoring`, `logging` | `plataforma/namespaces` | — |
| [`traefik.yaml`](traefik.yaml) | `traefik` | Ingress controller | chart `traefik` 42.2.0 + `plataforma/traefik/values.yaml` | `traefik` |
| [`argocd-ingress.yaml`](argocd-ingress.yaml) | `argocd-ingress` | Ingress de la interfaz de Argo CD | `plataforma/argocd-ingress` | `argocd` |
| [`nfs-csi.yaml`](nfs-csi.yaml) | `nfs-csi` | Driver CSI de NFS | chart `csi-driver-nfs` 4.13.6 + `plataforma/nfs/values.yaml` | `kube-system` |
| [`storageclasses.yaml`](storageclasses.yaml) | `storageclasses` | StorageClass `nfs` (predeterminado) | `plataforma/storageclasses` | — |
| [`local-path.yaml`](local-path.yaml) | `local-path` | StorageClass `local-path` | `plataforma/local-path/chart` (v0.0.37) | `local-path-storage` |
| [`postgres.yaml`](postgres.yaml) | `postgres` | PostgreSQL 18.7 (StatefulSet) | `tienda/postgres` (Kustomize) | `tienda` |
| [`svc-eventos.yaml`](svc-eventos.yaml) | `svc-eventos` | Catálogo (2 réplicas) | `tienda/svc-eventos` (Kustomize) | `tienda` |
| [`svc-reservaciones.yaml`](svc-reservaciones.yaml) | `svc-reservaciones` | Carrito: bloqueo temporal de asientos | `tienda/svc-reservaciones` (Kustomize) | `tienda` |
| [`svc-ordenes.yaml`](svc-ordenes.yaml) | `svc-ordenes` | Pago y pedidos | `tienda/svc-ordenes` (Kustomize) | `tienda` |
| [`frontend.yaml`](frontend.yaml) | `frontend` | Sitio web (2 réplicas) e Ingress de la tienda | `tienda/frontend` (Kustomize) | `tienda` |
| [`tekton-pipelines.yaml`](tekton-pipelines.yaml) | `tekton-pipelines` | Tekton Pipelines v1.18.0 | `plataforma/tekton/pipelines` (Kustomize sobre el manifiesto oficial) | `tekton-pipelines` |
| [`tekton-triggers.yaml`](tekton-triggers.yaml) | `tekton-triggers` | Tekton Triggers v0.37.2 + interceptores | `plataforma/tekton/triggers` | `tekton-pipelines` |
| [`tekton-dashboard.yaml`](tekton-dashboard.yaml) | `tekton-dashboard` | Tekton Dashboard v0.74.0 (solo lectura) e Ingress | `plataforma/tekton/dashboard` | `tekton-pipelines` |
| [`ci.yaml`](ci.yaml) | `ci` | Tasks, Pipeline y Triggers de la boletera | **`equipoEmpiroso-app/tekton`** | `ci` |

Todas sincronizan solas (`automated`) con `selfHeal`: si alguien cambia algo a
mano en el clúster, Argo CD lo regresa a lo que dice Git. Todas usan `prune`
salvo `storageclasses`, para que borrar un StorageClass de Git por error no
afecte a los volúmenes existentes.

Más detalle en [`docs/02-argocd.md`](../docs/02-argocd.md),
[`docs/03-ingress-y-almacenamiento.md`](../docs/03-ingress-y-almacenamiento.md),
[`docs/04-postgresql.md`](../docs/04-postgresql.md) y
[`docs/05-microservicios.md`](../docs/05-microservicios.md).
