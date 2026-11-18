# docs

Documentación del proyecto: un documento por etapa, escrito al terminarla.
Cada uno explica qué se instaló, con qué versión, qué archivos se crearon,
por qué se tomó cada decisión y cómo se comprobó que funciona.

## Etapas

| # | Etapa | Documento | Rubro que cubre |
|---|---|---|---|
| 1 | Clúster de 4 nodos (kubeadm, Flannel, Tailscale, NFS) | [`cluster/docs/01-cluster-desde-cero.md`](../cluster/docs/01-cluster-desde-cero.md) | Clúster |
| 2 | Argo CD y el patrón app-of-apps | [`02-argocd.md`](02-argocd.md) | CD con Argo CD (+ punto extra) |
| 3 | Ingress (Traefik) y almacenamiento (NFS y local-path) | [`03-ingress-y-almacenamiento.md`](03-ingress-y-almacenamiento.md) | Clúster |
| 4 | PostgreSQL en StatefulSet, esquema y datos de ejemplo | [`04-postgresql.md`](04-postgresql.md) | BD y persistencia |
| 5 | Los cuatro microservicios y la tienda | [`05-microservicios.md`](05-microservicios.md) | Tienda y microservicios |

El documento de la etapa 1 está dentro de `cluster/` porque acompaña a los
playbooks de Ansible: quien copie esa carpeta se lleva también su explicación.

## Cómo se escribe cada documento

Misma estructura en todas las etapas, para que se puedan comparar y revisar:

1. **Resultado**: cómo quedó, con la salida de los comandos de verificación.
2. **Versiones y compatibilidad** contra Kubernetes 1.37, con sus fuentes.
3. **Archivos** de la etapa y qué hace cada uno.
4. **Pasos y decisiones**: qué se configuró y para qué.
5. **Verificación** y pruebas.
6. **Cómo reproducirla** y qué **evidencias** guardar.

## Otros contenidos

- **[evidencias/](evidencias/)**: capturas y archivos que muestran que cada parte funciona.
- **Diagrama de arquitectura** de la plataforma (pendiente).
- **Presentación** final en PDF (pendiente).
- Enlace al **video de respaldo** de la demo (pendiente).
