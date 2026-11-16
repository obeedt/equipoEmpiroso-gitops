#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
#  Script de emergencia:
#  Borra algún clúster anterior de Kubernetes para reinstalarlo.
#
#   ⚠  Destruye el clúster de esta máquina: etcd, certificados, pods.
#      No toca tus archivos personales ni paquetes instalados.
#
# Uso:   sudo ./99-reset-nodo.sh
# ─────────────────────────────────────────────────────────────────────
set -euo pipefail
read -rp "Esto borra el clúster Kubernetes de $(hostname). Escribe SI para continuar: " r
[ "$r" = "SI" ] || { echo "Cancelado."; exit 1; }

kubeadm reset -f
rm -rf /etc/cni/net.d /root/.kube /var/lib/calico /run/flannel
# Interfaces que dejan Calico y Flannel
for i in tunl0 vxlan.calico flannel.1 cni0; do ip link delete "$i" 2>/dev/null || true; done
# Reglas de iptables/nftables del clúster viejo
for t in filter nat mangle; do iptables -t "$t" -F 2>/dev/null || true; done
iptables -X 2>/dev/null || true
systemctl restart containerd
# El flush también borra las cadenas de Tailscale; reiniciarlo las recrea
systemctl restart tailscaled 2>/dev/null || true
systemctl restart firewalld
echo "Listo. Reinicia la VM antes de correr el playbook: sudo reboot"
