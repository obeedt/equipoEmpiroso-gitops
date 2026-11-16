# plataforma

La base que usan todos los demás componentes:

- **Ingress controller** (Traefik): da acceso por nombre (`nip.io`) a la tienda, Grafana, Argo CD, OpenSearch Dashboards y Jaeger.
- **StorageClasses**:
  - `nfs`: volúmenes en el servidor NFS del control plane, para PostgreSQL.
  - `local-path`: volúmenes en el disco de cada worker, para OpenSearch y Prometheus.
- **Namespaces**: `tienda`, `monitoring`, `logging`, `tekton-pipelines` y `argocd`.
