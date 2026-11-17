# argocd

Configuración de **Argo CD v3.6.1** (chart `argo/argo-cd` 10.18.0).

Es el único componente que **no** instala Argo CD: se instaló a mano una vez,
con Helm, desde el control plane. Después de eso, todo lo demás llega por Git.

```bash
helm repo add argo https://argoproj.github.io/argo-helm && helm repo update
helm install argocd argo/argo-cd --version 10.18.0 -n argocd --create-namespace \
  -f ~/equipoEmpiroso-gitops/plataforma/argocd/values.yaml
kubectl apply -f ~/equipoEmpiroso-gitops/apps/root.yaml
```

| Archivo | Qué hace |
|---|---|
| [`values.yaml`](values.yaml) | Argo CD en k8s-w1 (rol `app`), sirviendo HTTP (`server.insecure`) para el Ingress, sin Dex ni notificaciones |

Para cambiar esta configuración: editar `values.yaml` y, en k8s-cp, aplicar el
cambio con `helm upgrade argocd argo/argo-cd --version 10.18.0 -n argocd -f ...`
(misma versión, mismos valores).

- Interfaz: http://argocd.100.103.221.107.nip.io (Ingress en [`../argocd-ingress/`](../argocd-ingress/))
- Documentación completa: [`docs/02-argocd.md`](../../docs/02-argocd.md)
