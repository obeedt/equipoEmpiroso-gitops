# Mejoras siguientes

Lo que sigue después de cumplir todos los rubros. Si nos da tiempo antes de
la presentación, estas son las mejoras que vamos a hacer, en este orden. Cada
una dice qué cambia y en qué parte del repositorio.

## 1. Seguridad

| Mejora | Qué cambia | Dónde |
|---|---|---|
| **Plugin de seguridad de OpenSearch** | TLS entre componentes, usuarios con permisos (Fluent Bit solo escribe, Jaeger solo en sus índices) y login en OpenSearch Dashboards. La contraseña de administrador va en un Secret. | `logging/opensearch`, `logging/opensearch-dashboards`, `logging/fluent-bit`, `logging/jaeger` |
| **Login en Prometheus, Alertmanager y Jaeger UI** | Hoy no tienen usuario: se protegen solo porque se abren desde la tailnet. Un *middleware* `basicAuth` de Traefik, con el usuario en un Secret, les pondría login sin cambiarlos. | Ingress de `monitoring` y `logging` |
| **NetworkPolicies** | Que cada namespace solo acepte las conexiones que necesita, por ejemplo PostgreSQL solo desde los 3 servicios. Flannel no aplica NetworkPolicies, así que antes hay que agregar un componente que sí lo haga sin chocar con Tailscale. | `cluster/` y un `networkpolicy.yaml` por namespace |
| **HTTPS en los Ingress** | Certificados para `*.nip.io` o nombres de la tailnet con su certificado automático. | `plataforma/traefik` |
| **Sealed Secrets** *(punto extra)* | Los Secrets que hoy se crean a mano (tokens, contraseñas) se guardarían cifrados en Git y Argo CD los aplicaría como todo lo demás. | `plataforma/sealed-secrets` + un `*-sealed.yaml` por Secret |

## 2. Operación

| Mejora | Qué cambia | Dónde |
|---|---|---|
| **Despliegue en segundos** | Un webhook de GitHub hacia Argo CD (por el mismo Tailscale Funnel que usa Tekton) haría que Argo CD sincronice al instante, sin esperar su revisión de cada 2–3 minutos. | `plataforma/argocd`, Funnel en k8s-w3 |
| **Limpieza de ejecuciones de Tekton** | Cada PipelineRun deja su volumen de trabajo de 1 GiB en k8s-w3 hasta que se borra. Un pruner que conserve solo las últimas 10 ejecuciones. | `plataforma/tekton/pipelines` |
| **Respaldo de PostgreSQL** | Un CronJob con `pg_dump` diario a una carpeta del NFS, con retención de una semana, y la prueba de restaurarlo. | `tienda/postgres` |
| **Alertas de la propia observabilidad** | Avisar si Fluent Bit no puede escribir en OpenSearch, si el disco de OpenSearch pasa de 80 % o si Jaeger deja de recibir trazas. | `monitoring/reglas` |
| **Trazas más limpias** | Cerca del 40 % de los tramos son internos de FastAPI (`http send` / `http receive`) y no dicen nada útil. `FastAPIInstrumentor.instrument_app(..., exclude_spans=["send", "receive"])` los quita: trazas más fáciles de leer y menos espacio en OpenSearch. | `equipoEmpiroso-app/*/app/main.py` |
| **Trazas desde Grafana** | Jaeger como fuente de datos en Grafana: desde un pico de errores en el dashboard de aplicación, abrir las trazas de ese momento. | `monitoring/kube-prometheus-stack/values.yaml` |

## 3. Escala y disponibilidad

| Mejora | Qué cambia | Dónde |
|---|---|---|
| **HPA con prueba de carga** *(punto extra)* | metrics-server y un HorizontalPodAutoscaler para el frontend y svc-eventos; el generador de tráfico con más clientes sirve como prueba de carga. | `plataforma/metrics-server`, `tienda/*` |
| **Entorno staging + producción** *(punto extra)* | Un namespace `staging` con su propia copia de la tienda; Tekton despliega primero ahí y un commit lo promueve a producción. | `tienda/` con overlays de Kustomize |
| **Más de un nodo para lo crítico** | Prometheus, OpenSearch y Tekton viven cada uno en un solo worker. Con más memoria, réplicas en dos nodos. | `monitoring/`, `logging/` |

## 4. Detalles por pulir

Pequeños ajustes en todo el proyecto antes de entregar:

- Revisar que cada README tenga los comandos actualizados y las URLs correctas.
- Guardar todas las capturas de `docs/evidencias/` con nombres que digan qué muestran.
- Diagrama de arquitectura completo (clúster, CI/CD, tienda, observabilidad) para el README principal y la presentación.
- Ensayar las 3 demos completas con el guion de cada documento y cronometrarlas.
- Video de respaldo de la demo (máx. 5 min).
