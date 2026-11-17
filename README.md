# equipoEmpiroso-gitops

Repositorio GitOps del **Proyecto 3 · Boletera de conciertos**.

Aquí viven los manifiestos de Kubernetes de toda la plataforma. **Argo CD lee
este repositorio y lo aplica al clúster**: ningún cambio se hace con
`kubectl apply`, todo entra por Git.

El código de los microservicios y el pipeline de Tekton están en
[equipoEmpiroso-app](https://github.com/obeedt/equipoEmpiroso-app).

## Estructura

| Carpeta | Qué va ahí |
|---|---|
| [`cluster/`](cluster/) | Instalación del clúster con Ansible (4 nodos, kubeadm, Flannel sobre Tailscale) y su documentación |
| [`apps/`](apps/) | Applications de Argo CD (patrón app-of-apps) |
| [`plataforma/`](plataforma/) | Ingress controller, StorageClasses y namespaces |
| [`tienda/`](tienda/) | Microservicios de la boletera y la base de datos PostgreSQL |
| [`monitoring/`](monitoring/) | Prometheus, Grafana, alertas y Telegram |
| [`logging/`](logging/) | Logs centralizados y trazas (OpenSearch, Fluent Bit, Jaeger) |
| [`docs/`](docs/) | Diagrama de arquitectura, evidencias y presentación |

## Estado

| Etapa | Estado |
|---|---|
| 1 · Clúster de 4 nodos | ✅ Listo · [documentación](cluster/docs/01-cluster-desde-cero.md) |
| 2 · Argo CD (app-of-apps) | ✅ Listo · [documentación](docs/02-argocd.md) |
| 3 · Ingress y StorageClasses | ✅ Listo · [documentación](docs/03-ingress-y-almacenamiento.md) |
| Base de datos y tienda | Pendiente |
| CI con Tekton | Pendiente |
| Monitoreo y alertas | Pendiente |
| Logs y trazas | Pendiente |

## Accesos

Solo desde equipos conectados a la tailnet del equipo:

| Aplicación | URL |
|---|---|
| Argo CD | http://argocd.100.103.221.107.nip.io |

## Equipo

| Integrante | Rol |
|---|---|
| Obed Torres Pimentel | Plataforma / CD + SRE / Observabilidad |
| Héctor Saul Hernández Saldívar | Desarrollo / CI |
