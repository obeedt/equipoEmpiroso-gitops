# evidencias

Capturas de pantalla de que cada parte de la plataforma funciona:

- **Clúster**: `kubectl get nodes -o wide`, `verificar-red.sh` y la segunda corrida de Ansible con `changed=0`.
- **Argo CD**: Applications en `Synced` / `Healthy`.
- **Tekton**: PipelineRun exitoso e imagen nueva en Docker Hub.
- **Prometheus**: targets en `UP`.
- **Telegram**: mensaje de alerta y de resolución.
