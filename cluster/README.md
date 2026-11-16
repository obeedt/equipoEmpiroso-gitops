# Clúster Boletera · Kubernetes sobre Tailscale

Clúster kubeadm de 4 nodos (1 control plane + 3 workers) repartido entre una
laptop con VMware y un servidor Proxmox, unidos por Tailscale. Los nodos usan
su **IP de Tailscale** como IP de nodo, así que el clúster funciona igual en
casa, en la escuela o con un hotspot, y cualquier worker se puede mover a otra
máquina (por ejemplo, la laptop de un compañero) sin rehacer el clúster.

> **Por qué se hizo así:** las decisiones (clúster nuevo, 4 nodos, Flannel,
> Tailscale, MTU, DNS, configuración de VMware y Proxmox) y todo el proceso
> están explicados en [docs/01-cluster-desde-cero.md](docs/01-cluster-desde-cero.md).

## Topología

| Nodo   | Dónde           | vCPU | RAM    | Disco                               | Rol (`boletera_roles`)        |
|--------|-----------------|------|--------|-------------------------------------|-------------------------------|
| k8s-cp | Laptop (VMware) | 2    | 3.5 GB | 30 GB + **2º disco de 20 GB (NFS)** | control plane + servidor NFS  |
| k8s-w1 | Laptop (VMware) | 2    | 4.5 GB | 40 GB, sin swap                     | `app`                         |
| k8s-w2 | Proxmox (VM)    | 2    | 5 GB   | 50 GB, sin swap                     | `logs`                        |
| k8s-w3 | Proxmox (VM)    | 2    | 5 GB   | 50 GB, sin swap                     | `metricas`                    |

Todos con Rocky Linux 10.2, containerd 2.4.2, Kubernetes 1.37.2 y Flannel v0.28.10.

### Por qué 4 nodos y no un worker grande

- **Portabilidad:** cada worker cabe en una máquina modesta. Si el servidor
  Proxmox no está disponible, k8s-w2 o k8s-w3 se recrean en otra laptop con
  el mismo nombre y roles, y los manifiestos no cambian.
- **Aislamiento:** OpenSearch y Prometheus son los que más RAM usan; en nodos
  separados, si uno se queda sin memoria no tumba al otro ni a la tienda.
- **Costo:** cada nodo extra gasta ~1 GB de RAM en sistema operativo,
  kubelet, containerd, kube-proxy y Flannel.

### Qué correrá en cada worker (siguiente etapa, repo GitOps)

| Rol | Nodo hoy | Cargas | Almacenamiento |
|---|---|---|---|
| `app` | k8s-w1 · laptop | Tienda (frontend, eventos, órdenes, reservaciones), PostgreSQL, Traefik, Argo CD | StorageClass `nfs` (2º disco del control plane, en la misma laptop) |
| `logs` | k8s-w2 · Proxmox | OpenSearch + Dashboards, Jaeger | StorageClass `local-path` (disco de la VM) |
| `metricas` | k8s-w3 · Proxmox | Prometheus, Grafana, Alertmanager, builds de Tekton | StorageClass `local-path` (disco de la VM) |

### Etiquetas que pone el playbook 04

| Etiqueta | Valor | Para qué |
|---|---|---|
| `boletera.io/app`, `boletera.io/logs`, `boletera.io/metricas` | `"true"` según `boletera_roles` | `nodeSelector` de cada carga en el repo GitOps |
| `boletera.io/zona` | `laptop` / `proxmox` | informativa: dónde vive la VM |
| `node-role.kubernetes.io/worker` | (vacío) | que `kubectl get nodes` muestre el rol |

En los manifiestos se fija el **rol**, no el nodo ni la zona:

```yaml
nodeSelector:
  boletera.io/logs: "true"
```

Así, mover una carga es editar `boletera_roles` en `inventario.ini` y volver a
correr `ansible-playbook 04-workers.yml`. Un worker puede tener varios roles
(`boletera_roles=logs,metricas`, sin espacios, por ejemplo si se juntan en una sola máquina);
el playbook quita los que ya no tiene y falla si algún rol queda sin worker.

> Ojo con `local-path`: el volumen vive en el disco del worker. Si un rol con
> `local-path` (`logs` o `metricas`) cambia de nodo, sus datos no se mueven;
> el pod arranca vacío en el nodo nuevo (para el proyecto basta con eso).

## Decisiones de red (y por qué)

| Problema | Solución | Dónde |
|---|---|---|
| Los nodos están en redes distintas (VMware NAT en la laptop, LAN de casa en Proxmox) | Tailscale como red de los nodos; kubelet con `node-ip` = IP de Tailscale | `templates/kubeadm-*.yaml.j2` |
| Flannel usa por defecto la interfaz de la ruta por defecto (la LAN) | `--iface=tailscale0` en el DaemonSet | `templates/kube-flannel.yml.j2` |
| Las ACL de Tailscale sin `proto` solo dejan pasar TCP, UDP e ICMP | Flannel en **VXLAN** (UDP 8472), que sí pasa | `templates/kube-flannel.yml.j2` |
| Doble encapsulado (VXLAN dentro de WireGuard) | Flannel calcula solo el MTU: 1280 (tailscale0) − 50 = **1230**; el playbook 03 lo verifica | `03-control-plane.yml` |
| Tailscale puede reescribir `/etc/resolv.conf` y CoreDNS lo hereda | `tailscale up --accept-dns=false` | `00-tailscale-bootstrap.sh` |
| El subnet router (Kali → red OpenVPN) podría anunciar rutas que choquen con el clúster | `--accept-routes=false` en los nodos | `00-tailscale-bootstrap.sh` |
| La IP del control plane podría cambiar | `controlPlaneEndpoint` por **nombre** (`k8s-api.boletera`) en `/etc/hosts` | `templates/kubeadm-init.yaml.j2` |
| firewalld activo | `tailscale0`, `cni0`, `flannel.1` y las redes del clúster en la zona `trusted` (mismo arreglo que el troubleshooting de la clase 1) | `01-prerequisitos.yml` |

### Por qué Flannel y no Calico

Es el CNI que se usó en la clase. Sobre Tailscale, Calico necesitaba tres
ajustes extra (desactivar IPIP, fijar el MTU a mano y mover su máscara de
marcas de netfilter, que choca con la de Tailscale); Flannel no usa esas
marcas y calcula el MTU solo. Además consume mucho menos RAM (un pod por nodo).
**Lo que se pierde:** Flannel no aplica `NetworkPolicy`. El proyecto no la
pide; en producción, con políticas de red, usaríamos Calico.

## Antes de empezar

1. **VMs:** Rocky Linux 10.2 minimal, usuario `ansible` como administrador,
   particionado manual **sin swap** (todo en `/`).
2. **VMs en Proxmox (k8s-w2 y k8s-w3):** tipo de CPU **`host`** (Rocky 10
   exige x86-64-v3; con el tipo por defecto el instalador muere con
   `Fatal glibc error: CPU does not support x86-64-v3`), 2 cores, memoria fija
   de 5120 MiB con **ballooning desactivado**, disco VirtIO SCSI de 50 GB, red
   en el bridge con salida a internet (no la red interna de OPNsense) y
   "Start at boot". Deben ser **VMs**, no contenedores LXC.
3. **Control plane:** agrégale un segundo disco virtual de 20 GB en VMware.
   Revisa su nombre con `lsblk` (en VMware con NVMe suele ser `nvme0n2`) y
   ajusta `nfs_disk` en `group_vars/all.yml` si es otro.
   Va aparte del sistema para que, si los volúmenes NFS se llenan, no se
   llene también el disco de etcd y del API server.
4. **Consola de Tailscale:**
   - Si tu política de acceso no es la de "todo permitido", agrega una regla
     que permita **TCP y UDP** entre los cuatro nodos.
   - Verifica que ninguna ruta anunciada choque con `10.244.0.0/16` (pods) ni
     con `10.96.0.0/12` (services).

## Instalación

```bash
# 0) En CADA VM, desde su consola (una sola vez). También deja a `ansible`
#    con sudo sin contraseña, que Ansible necesita:
sudo bash ./00-tailscale-bootstrap.sh k8s-cp      # k8s-w1 / k8s-w2 / k8s-w3 en las otras
#    Luego, en la consola de Tailscale: "Disable key expiry" en los 4 nodos.

# 1) En k8s-cp, como el usuario ansible (NO como root):
sudo dnf install -y ansible-core
ssh-keygen -t ed25519
ssh-copy-id ansible@<IP-tailscale-w1>
ssh-copy-id ansible@<IP-tailscale-w2>
ssh-copy-id ansible@<IP-tailscale-w3>

# 2) Pon las 4 IPs de Tailscale en inventario.ini (y revisa boletera_roles)
#    y prueba la conexión
ansible all -m ansible.builtin.ping

# 3) Todo el clúster, SIN sudo (los playbooks ya usan become).
#    Con sudo, Ansible usaría la llave SSH de root, que no está en los workers.
ansible-playbook site.yml

# 4) Verificar la red (prueba todos los workers; o pásale nombres)
sudo bash ./verificar-red.sh
```

`site.yml` debe dar `changed=0` en una segunda corrida (idempotencia).

## Qué valida cada paso

- **01:** que cada nodo tenga su IP de Tailscale y que containerd quede con `SystemdCgroup = true`.
- **02:** que el disco NFS quede montado (solo formatea un disco **vacío**) y lo exporta solo a los nodos del inventario.
- **03:** que Flannel arranque, que el nodo se registre con su IP de Tailscale, que Flannel encapsule por esa IP y que el MTU de los pods sea el de `tailscale0` − 50.
- **04:** antes de unir nada, que los roles del inventario sean válidos y que cada rol tenga al menos un worker; después, que los 4 nodos estén `Ready`, que cada uno use su IP de Tailscale (kubelet y Flannel) y que tenga sus etiquetas de rol.
- **verificar-red.sh:** ping entre pods de cada par de workers (laptop ↔ Proxmox y Proxmox ↔ Proxmox), paquete del MTU completo sin fragmentar en cada par, DNS interno y salida a internet desde cada worker.

## Versiones fijadas

| Componente | Versión | Dónde se fija |
|---|---|---|
| Rocky Linux | 10.2 | instalación de las VMs |
| Kubernetes (kubelet, kubeadm, kubectl) | 1.37.2 | `group_vars/all.yml` → `k8s_version` |
| containerd.io | 2.4.2 | `group_vars/all.yml` → `containerd_version` |
| Flannel | v0.28.10 | `templates/kube-flannel.yml.j2` (manifiesto oficial) |
| Tailscale | estable al momento de instalar | — |

## Lo que este paquete NO instala todavía

El rubro de Clúster también pide **Ingress controller** y **StorageClass**
funcionando. Este paquete deja listo el servidor NFS, pero el provisioner NFS,
el StorageClass `local-path` y Traefik van en la siguiente etapa (repo GitOps
con Argo CD), igual que el resto del proyecto.

Pendiente de decidir al instalar Traefik: la interfaz física de cada nodo
queda en la zona `public` de firewalld (solo con 41641/udp abierto). Si la
tienda debe verse desde equipos fuera de Tailscale, hay que abrir 80/443 ahí.

