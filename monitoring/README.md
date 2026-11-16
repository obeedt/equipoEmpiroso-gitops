# monitoring

Monitoreo y alertas (namespace `monitoring`). Corren en el worker con el rol
`metricas`.

- **kube-prometheus-stack**: Prometheus, Alertmanager, Grafana, node-exporter y kube-state-metrics.
- **ServiceMonitors**: uno por microservicio, para que Prometheus lea su `/metrics`.
- **PrometheusRules**: las 6 alertas mínimas (servicio caído, pod reiniciándose, nodo NotReady, disco arriba de 80 %, errores 5xx arriba de 5 % y la alerta de negocio: evento con más de 90 % vendido).
- **Alertmanager → Telegram**: envío de alertas y de su resolución al grupo del equipo.
- **Dashboards** de Grafana exportados en JSON: infraestructura, aplicación y negocio.

El token del bot de Telegram **no** se guarda aquí: va en un Secret creado fuera de Git.
