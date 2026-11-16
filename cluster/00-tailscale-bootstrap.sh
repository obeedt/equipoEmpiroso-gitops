#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Paso 0 — se corre A MANO en cada VM nueva (k8s-cp, k8s-w1, k8s-w2, k8s-w3),
# desde la consola de VMware / Proxmox, ANTES de usar Ansible.
#
# Uso:   sudo ./00-tailscale-bootstrap.sh k8s-w1
#
# Por qué a mano: Ansible va a conectarse a los nodos por su IP de
# Tailscale, así que Tailscale tiene que existir primero.
# ─────────────────────────────────────────────────────────────────────
set -euo pipefail

NOMBRE="${1:?Uso: $0 <nombre-del-nodo>  (k8s-cp | k8s-w1 | k8s-w2 | k8s-w3)}"

hostnamectl set-hostname "$NOMBRE"

# Ansible usa "become" (sudo) en todos los nodos. Al crear el usuario como
# administrador en el instalador de Rocky, sudo pide contraseña; sin esta
# regla los playbooks fallan con "Missing sudo password".
id ansible >/dev/null 2>&1 || { echo "Falta el usuario 'ansible'. Créalo primero."; exit 1; }
echo 'ansible ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/ansible
chmod 0440 /etc/sudoers.d/ansible
visudo -cf /etc/sudoers.d/ansible

# Repositorio oficial de Tailscale para RHEL/Rocky 10.
# dnf cambió la sintaxis de config-manager entre versiones; probamos ambas.
REPO=https://pkgs.tailscale.com/stable/rhel/10/tailscale.repo
dnf config-manager --add-repo "$REPO" 2>/dev/null \
  || dnf config-manager addrepo --from-repofile="$REPO"

dnf install -y tailscale
systemctl enable --now tailscaled

# --accept-dns=false  → Tailscale NO reescribe /etc/resolv.conf.
#                       Si lo hiciera, CoreDNS heredaría 100.100.100.100
#                       como servidor DNS y los pods podrían quedarse sin DNS.
# --accept-routes=false → los nodos NO aceptan las subredes que anuncia
#                       tu Kali (subnet router). Evita que una ruta de
#                       OpenVPN/OPNsense choque con 10.244.0.0/16 o 10.96.0.0/12.
tailscale up --hostname="$NOMBRE" --accept-dns=false --accept-routes=false

echo
echo "IP de Tailscale de $NOMBRE:"
tailscale ip -4
echo
echo "Siguiente paso: en https://login.tailscale.com/admin/machines"
echo "  → menú '...' de $NOMBRE → 'Disable key expiry'"
