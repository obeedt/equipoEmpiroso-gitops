# logging

Logs centralizados y trazas distribuidas, en el namespace `logging` y en
**k8s-w2** (rol `logs`). Stack del proyecto 3: **Fluent Bit → OpenSearch** y
**Jaeger** guardando en OpenSearch.

| Application | Qué instala | Origen |
|---|---|---|
| `opensearch` | OpenSearch 3.9.0, un nodo, 20 GiB en `local-path` | chart `opensearch` 3.9.0 + [`opensearch/values.yaml`](opensearch/values.yaml) |
| `opensearch-dashboards` | OpenSearch Dashboards 3.9.0 (consulta de logs) | chart `opensearch-dashboards` 3.9.0 + [`opensearch-dashboards/values.yaml`](opensearch-dashboards/values.yaml) |
| `fluent-bit` | Fluent Bit 5.1.2 en los 4 nodos | chart `fluent-bit` 0.58.2 + [`fluent-bit/values.yaml`](fluent-bit/values.yaml) |
| `logging` | Jaeger 2.22.0 y el Job de configuración (esta carpeta, con Kustomize) | [`kustomization.yaml`](kustomization.yaml) |

| Carpeta | Qué es |
|---|---|
| [`jaeger/`](jaeger/) | Jaeger: recibe trazas por OTLP (4317/4318), las guarda en OpenSearch y sirve la UI. `ui.json` enlaza cada traza con sus logs |
| [`configuracion/`](configuracion/) | Job que configura OpenSearch y Dashboards después de cada sincronización: retención de 7 días, plantilla de índices, index patterns, búsqueda "Errores de la tienda" y `trace_id` como enlace a Jaeger |

## Índices en OpenSearch

| Índice | Qué guarda |
|---|---|
| `boletera-logs-AAAA.MM.DD` | Logs de la tienda, con su JSON como campos: `nivel`, `servicio`, `mensaje`, `trace_id`… |
| `cluster-logs-AAAA.MM.DD` | Logs del resto del clúster (texto en `log`), sin `logging` |
| `boletera-jaeger-span-AAAA-MM-DD`… | Trazas de Jaeger |

Todos se borran a los 7 días (política ISM `retencion-7-dias`).

## Accesos (solo desde la tailnet)

| Aplicación | URL |
|---|---|
| OpenSearch Dashboards (logs) | http://opensearch.100.103.221.107.nip.io |
| Jaeger UI (trazas) | http://jaeger.100.103.221.107.nip.io |

**De un log a su traza:** en Dashboards → Discover → búsqueda guardada
**"Errores de la tienda"**, el `trace_id` de cada log es un enlace que abre la
traza en Jaeger. **De una traza a sus logs:** en Jaeger, el menú de la traza
tiene "Ver los logs de esta traza en OpenSearch".

Los servicios envían sus trazas con `OTEL_EXPORTER_OTLP_ENDPOINT=http://jaeger.logging:4318`
(`tienda/<servicio>/config.env`).

OpenSearch corre sin su plugin de seguridad; activarlo es la primera de las
[mejoras siguientes](../docs/mejoras.md).
