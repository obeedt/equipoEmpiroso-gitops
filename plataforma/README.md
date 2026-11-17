# plataforma

La base que usan todos los demás componentes. Cada carpeta la instala una
Application de Argo CD en [`apps/`](../apps/).

| Carpeta | Qué es | Versión | Application |
|---|---|---|---|
| [`argocd/`](argocd/) | Valores de Helm de Argo CD (se instaló a mano una vez) | Argo CD v3.6.1 · chart 10.18.0 | — |
| [`argocd-ingress/`](argocd-ingress/) | Ingress de la interfaz de Argo CD | — | `argocd-ingress` |
| [`namespaces/`](namespaces/) | Namespaces `tienda`, `monitoring` y `logging` | — | `namespaces` |
| [`traefik/`](traefik/) | **Ingress controller**: escucha en el puerto 80 de k8s-w1 | Traefik v3.7.17 · chart 42.2.0 | `traefik` |
| [`nfs/`](nfs/) | Driver CSI de NFS (aprovisionamiento dinámico) | csi-driver-nfs 4.13.6 | `nfs-csi` |
| [`storageclasses/`](storageclasses/) | StorageClass **`nfs`** (predeterminado) | — | `storageclasses` |
| [`local-path/`](local-path/) | StorageClass **`local-path`** (disco de cada worker) | local-path-provisioner v0.0.37 | `local-path` |

## StorageClasses

| Nombre | Dónde quedan los datos | Si el pod cambia de nodo | Para qué |
|---|---|---|---|
| `nfs` (predeterminado) | `/srv/nfs/k8s/<namespace>-<pvc>` en k8s-cp | los datos lo siguen | PostgreSQL |
| `local-path` | `/opt/local-path-provisioner` en el worker | los datos **no** lo siguen | OpenSearch, Prometheus |

## Acceso por Ingress

Traefik escucha en el puerto 80 de **k8s-w1**, por su IP de Tailscale
(`100.103.221.107`). Cada aplicación usa un nombre `nip.io` que apunta a esa IP:

| Aplicación | URL |
|---|---|
| Argo CD | http://argocd.100.103.221.107.nip.io |

Solo se abre desde equipos conectados a la tailnet.
