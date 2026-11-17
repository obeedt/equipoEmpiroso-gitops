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

Todas sincronizan solas (`automated`) con `selfHeal`: si alguien cambia algo a
mano en el clúster, Argo CD lo regresa a lo que dice Git. Todas usan `prune`
salvo `storageclasses`, para que borrar un StorageClass de Git por error no
afecte a los volúmenes existentes.

Más detalle en [`docs/02-argocd.md`](../docs/02-argocd.md) y
[`docs/03-ingress-y-almacenamiento.md`](../docs/03-ingress-y-almacenamiento.md).
