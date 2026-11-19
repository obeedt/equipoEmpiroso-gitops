# tekton

Instalación de **Tekton** (la herramienta de CI) con Kustomize sobre los
manifiestos oficiales, en versión fija. Todo corre en k8s-w3 (rol `metricas`).

| Carpeta | Qué instala | Versión | Application |
|---|---|---|---|
| [`pipelines/`](pipelines/) | Tekton Pipelines: Tasks, Pipelines y sus ejecuciones | v1.18.0 (LTS, hasta oct 2027) | `tekton-pipelines` |
| [`triggers/`](triggers/) | Tekton Triggers + interceptores (github, cel…): webhooks → PipelineRuns | v0.37.2 (LTS v0.37) | `tekton-triggers` |
| [`dashboard/`](dashboard/) | Tekton Dashboard, **solo lectura**, en http://tekton.100.103.221.107.nip.io | v0.74.0 (LTS) | `tekton-dashboard` |

Compatibilidad: Pipelines v1.18 pide Kubernetes ≥ 1.28; el Dashboard v0.74.0
declara soporte para "Pipelines v1.18.x LTS, and Triggers v0.37.x LTS" y pide
Kubernetes ≥ 1.34. El clúster usa 1.37.2.

## Ajustes sobre los manifiestos oficiales

| Ajuste | Para qué |
|---|---|
| `nodeSelector: boletera.io/metricas: "true"` en todos los Deployments | Tekton en k8s-w3, lejos de la tienda (k8s-w1) |
| `config-defaults`: `default-pod-template` y `default-affinity-assistant-pod-template` | Los pods de cada ejecución también en k8s-w3 |
| `config-defaults`: `default-timeout-minutes: 30` | Ninguna ejecución corre más de 30 min |
| Se quita el HPA del webhook | Necesita metrics-server, que el clúster no tiene |

En las Applications, Argo CD **ignora** los campos que Tekton llena al arrancar
(certificados de sus webhooks, reglas de admisión, `caBundle` de las CRDs y de
los ClusterInterceptor). Si no, los vería como diferencias y los regresaría al
valor del manifiesto, rompiendo los webhooks.

Las Tasks, el Pipeline y los Triggers de la boletera están en
[`equipoEmpiroso-app/tekton`](https://github.com/obeedt/equipoEmpiroso-app/tree/main/tekton)
(Application `ci`). La documentación completa de la etapa está en
[`docs/06-tekton.md`](../../docs/06-tekton.md).
