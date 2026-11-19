# monitoring

Monitoreo y alertas, en el namespace `monitoring` y en **k8s-w3** (rol
`metricas`). Los instalan dos Applications de Argo CD:

| Application | Qué instala | Origen |
|---|---|---|
| `kube-prometheus-stack` | Prometheus, Alertmanager, Grafana, Prometheus Operator, kube-state-metrics y node-exporter (en los 4 nodos) | chart `kube-prometheus-stack` **92.18.0** + [`kube-prometheus-stack/values.yaml`](kube-prometheus-stack/values.yaml) |
| `monitoring` | Lo propio de la boletera (esta carpeta, con Kustomize) | [`kustomization.yaml`](kustomization.yaml) |

| Carpeta | Qué es |
|---|---|
| [`servicemonitors/`](servicemonitors/) | Un **ServiceMonitor** por microservicio: Prometheus lee su `/metrics` cada 15 s |
| [`reglas/`](reglas/) | **PrometheusRule** con las 6 alertas: microservicio caído, pod reiniciándose, nodo NotReady, disco arriba de 80 % (nodos y NFS), errores 5xx arriba de 5 % y evento con más de 90 % vendido |
| [`alertmanager/`](alertmanager/) | **AlertmanagerConfig**: envía esas 6 alertas, y su resolución, al grupo de Telegram |
| [`dashboards/`](dashboards/) | Los 3 dashboards de Grafana en JSON: **infraestructura**, **aplicación** y **negocio** (carpeta "Boletera" en Grafana) |

| Componente | Versión |
|---|---|
| Prometheus / Alertmanager | v3.15.1 / v0.34.2 |
| Prometheus Operator | v0.94.2 |
| Grafana | 13.3.0 |
| kube-state-metrics / node-exporter | v2.20.0 / v1.12.1 |

## Accesos (solo desde la tailnet)

| Aplicación | URL |
|---|---|
| Grafana | http://grafana.100.103.221.107.nip.io |
| Prometheus | http://prometheus.100.103.221.107.nip.io |
| Alertmanager | http://alertmanager.100.103.221.107.nip.io |

## Secrets (no están en Git)

Se crean una vez, a mano, en k8s-cp:

```bash
# Contraseña de Grafana (usuario admin)
read -rsp "Contraseña para Grafana: " P; echo
kubectl -n monitoring create secret generic grafana-admin \
  --from-literal=admin-user=admin --from-literal=admin-password="$P"; unset P

# Token del bot de Telegram (lo da @BotFather)
read -rsp "Token del bot: " T; echo
kubectl -n monitoring create secret generic telegram-bot --from-literal=token="$T"; unset T
```

El chat ID del grupo sí está en `alertmanager/telegram.yaml`: sin el token no
sirve para enviar mensajes.
