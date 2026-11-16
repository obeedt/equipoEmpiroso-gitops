#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Verificación de la red del clúster (correr en k8s-cp como root).
# Prueba lo que de verdad falla en un clúster sobre VPN:
#   1. pod ↔ pod entre CADA par de workers (laptop ↔ Proxmox y
#      Proxmox ↔ Proxmox)
#   2. paquetes grandes con "no fragmentar" en cada par (detecta MTU mal puesto)
#   3. DNS interno desde CADA worker (CoreDNS vive en el control plane,
#      así que esto prueba también worker ↔ control plane)
#   4. salida a internet desde un pod en cada worker
#
# Uso:   sudo bash ./verificar-red.sh                 # todos los workers
#        sudo bash ./verificar-red.sh k8s-w1 k8s-w3   # solo esos
# ─────────────────────────────────────────────────────────────────────
set -uo pipefail
export KUBECONFIG=/etc/kubernetes/admin.conf
NS=prueba-red

# Workers: los que se pasen como argumento o, si no, los que tengan la
# etiqueta de worker (la pone el playbook 04).
if [ "$#" -gt 0 ]; then
  WORKERS=("$@")
else
  mapfile -t WORKERS < <(kubectl get nodes -l node-role.kubernetes.io/worker \
    -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
fi
[ "${#WORKERS[@]}" -ge 2 ] || { echo "Se necesitan al menos 2 workers (encontrados: ${WORKERS[*]:-ninguno})"; exit 1; }

# Flannel escribe el MTU que calculó para los pods en este archivo
MTU_POD=$(sed -n 's/^FLANNEL_MTU=//p' /run/flannel/subnet.env 2>/dev/null)
MTU_POD=${MTU_POD:-1230}
GRANDE=$((MTU_POD - 28))          # 20 IP + 8 ICMP
OK=0; FALLA=0
pasa(){ echo "  ✓ $1"; OK=$((OK+1)); }
falla(){ echo "  ✗ $1"; FALLA=$((FALLA+1)); }

limpiar(){ kubectl delete ns "$NS" --wait=false >/dev/null 2>&1; }
trap limpiar EXIT

echo "== Nodos =="
kubectl get nodes -o wide -L boletera.io/zona -L boletera.io/app -L boletera.io/logs -L boletera.io/metricas
echo; echo "Workers a probar: ${WORKERS[*]}"

kubectl create ns "$NS" >/dev/null 2>&1
for n in "${WORKERS[@]}"; do
  kubectl -n "$NS" run "p-$n" --image=docker.io/library/alpine:3 --restart=Never \
    --overrides="{\"spec\":{\"nodeName\":\"$n\"}}" -- sleep 900 >/dev/null
done
echo; echo "== Esperando pods (la 1a vez descarga la imagen en cada worker) =="
kubectl -n "$NS" wait --for=condition=Ready pod --all --timeout=300s || { falla "los pods de prueba no arrancaron"; exit 1; }
X(){ kubectl -n "$NS" exec "p-$1" -- sh -c "$2"; }
declare -A IP
for n in "${WORKERS[@]}"; do
  IP[$n]=$(kubectl -n "$NS" get pod "p-$n" -o jsonpath='{.status.podIP}')
done

# El ping de busybox no tiene "-M do"; se instala iputils en cada pod.
SIN_IPUTILS=""
for n in "${WORKERS[@]}"; do
  X "$n" "apk add -q --no-cache iputils >/dev/null 2>&1" || SIN_IPUTILS="$SIN_IPUTILS $n"
done
[ -z "$SIN_IPUTILS" ] || falla "no se pudo instalar iputils en:$SIN_IPUTILS (¿el pod tiene salida a internet?)"

echo; echo "== 1 y 2. Pod ↔ pod entre cada par de workers (MTU de los pods = $MTU_POD) =="
for ((i=0; i<${#WORKERS[@]}; i++)); do
  for ((j=i+1; j<${#WORKERS[@]}; j++)); do
    A=${WORKERS[$i]}; B=${WORKERS[$j]}
    X "$A" "ping -c3 -W2 ${IP[$B]}" >/dev/null 2>&1 \
      && pasa "ping $A → $B (${IP[$B]})" \
      || { falla "ping $A → $B (revisa VXLAN 8472/udp, ACL de Tailscale, firewalld y --iface de Flannel)"; continue; }
    X "$A" "ping -c2 -W2 -M do -s $GRANDE ${IP[$B]}" >/dev/null 2>&1 \
      && pasa "paquete de $MTU_POD bytes sin fragmentar $A → $B" \
      || falla "paquete de $MTU_POD bytes NO pasa $A → $B → MTU de los pods demasiado alto para la VPN"
  done
done

echo; echo "== 3. DNS interno desde cada worker (CoreDNS está en el control plane) =="
for n in "${WORKERS[@]}"; do
  X "$n" "nslookup kubernetes.default.svc.cluster.local >/dev/null 2>&1" \
    && pasa "DNS interno desde $n" \
    || falla "DNS interno desde $n (revisa cni0/flannel.1 en la zona trusted y --accept-dns=false)"
done

echo; echo "== 4. Salida a internet desde cada worker =="
for n in "${WORKERS[@]}"; do
  X "$n" "wget -q -T5 -O /dev/null https://registry-1.docker.io/v2/ 2>&1 | grep -q 401 || wget -q -T5 --spider https://github.com" \
    && pasa "salida HTTPS a internet desde $n" || falla "salida a internet desde $n (--ip-masq de Flannel)"
done

echo; echo "== Camino de Tailscale entre los nodos (direct = bien, relay = lento) =="
tailscale status | grep -E "$(IFS='|'; echo "${WORKERS[*]}")" || true

echo; echo "Resultado: $OK correctas, $FALLA fallidas"
[ "$FALLA" -eq 0 ]
