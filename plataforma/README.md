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
| [`local-path/`](local-path/) | StorageClass **`local-path`** (disco de cada worker). El chart está copiado en `local-path/chart/` (ver abajo). | local-path-provisioner v0.0.37 | `local-path` |
| [`tekton/`](tekton/) | **CI**: Tekton Pipelines, Triggers y Dashboard (solo lectura) en k8s-w3 | v1.18.0 · v0.37.2 · v0.74.0 | `tekton-pipelines`, `tekton-triggers`, `tekton-dashboard` |

## StorageClasses

| Nombre | Dónde quedan los datos | Si el pod cambia de nodo | Para qué |
|---|---|---|---|
| `nfs` (predeterminado) | `/srv/nfs/k8s/<namespace>-<pvc>` en k8s-cp | los datos lo siguen | PostgreSQL |
| `local-path` | `/opt/local-path-provisioner` en el worker | los datos **no** lo siguen | OpenSearch, Prometheus |

### Por qué el chart de local-path está copiado en este repo

Rancher no publica un repositorio de Helm para local-path-provisioner. Al
principio Argo CD leía el chart directo de su GitHub, pero para eso clonaba el
repositorio completo de Rancher (historial y dependencias de Go) y se rendía
por tiempo (`context deadline exceeded`).

Por eso `local-path/chart/` es una copia **sin modificar** de
`deploy/chart/local-path-provisioner` en la etiqueta `v0.0.37`
(commit `49b2be8`), con su licencia Apache 2.0 en `local-path/chart/LICENSE`.
Nuestra configuración va aparte, en `local-path/values.yaml`. Para actualizar
de versión se reemplaza la carpeta `chart/` por la de la etiqueta nueva.

## Imágenes de Docker Hub

Traefik, local-path-provisioner y busybox vienen de Docker Hub. Los nodos las
descargan por el espejo de Google (`mirror.gcr.io`), configurado en containerd
por el playbook 01 del clúster. Así no dependen de Cloudflare ni del límite de
descargas de Docker Hub. Ver `cluster/docs/01-cluster-desde-cero.md`,
sección 15.1.

## Acceso por Ingress

Traefik escucha en el puerto 80 de **k8s-w1**, por su IP de Tailscale
(`100.103.221.107`). Cada aplicación usa un nombre `nip.io` que apunta a esa IP:

| Aplicación | URL |
|---|---|
| Argo CD | http://argocd.100.103.221.107.nip.io |
| Tekton Dashboard (solo lectura) | http://tekton.100.103.221.107.nip.io |

Solo se abre desde equipos conectados a la tailnet.
