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
| 4 · PostgreSQL (StatefulSet + NFS) | ✅ Listo · [documentación](docs/04-postgresql.md) |
| 5 · Microservicios de la tienda | ✅ Listo · [documentación](docs/05-microservicios.md) |
| 6 · CI con Tekton (webhook por Tailscale Funnel) | ✅ Listo · [documentación](docs/06-tekton.md) |
| 7 · Monitoreo y alertas (Prometheus, Grafana, Telegram) | ✅ Listo · [documentación](docs/07-monitoreo-y-alertas.md) |
| Logs y trazas | Pendiente |

## Accesos

Solo desde equipos conectados a la tailnet del equipo:

| Aplicación | URL |
|---|---|
| **Tienda** | http://tienda.100.103.221.107.nip.io |
| Argo CD | http://argocd.100.103.221.107.nip.io |
| Tekton Dashboard (solo lectura) | http://tekton.100.103.221.107.nip.io |
| Grafana | http://grafana.100.103.221.107.nip.io |
| Prometheus | http://prometheus.100.103.221.107.nip.io |
| Alertmanager | http://alertmanager.100.103.221.107.nip.io |

## Equipo

| Integrante | Rol |
|---|---|
| Obed Torres Pimentel | Plataforma / CD + SRE / Observabilidad |
| Héctor Saul Hernández Saldívar | Desarrollo / CI |
