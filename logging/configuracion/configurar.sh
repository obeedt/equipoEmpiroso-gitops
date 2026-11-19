#!/bin/sh
# Configura OpenSearch y OpenSearch Dashboards. Lo corre el Job
# "configurar-opensearch" después de cada sincronización de la Application
# "logging". Se puede repetir sin problema: cada paso crea o reemplaza.
set -eu

OS=http://opensearch-cluster-master.logging.svc:9200
OSD=http://opensearch-dashboards.logging.svc:5601
D=/configuracion
JSON="Content-Type: application/json"

esperar() {   # $1 = nombre, $2 = URL que debe responder 200
  echo "Esperando a $1..."
  i=0
  until curl -sf -o /dev/null "$2"; do
    i=$((i + 1))
    if [ "$i" -gt 120 ]; then echo "$1 no respondió en 10 minutos" >&2; exit 1; fi
    sleep 5
  done
  echo "$1 listo"
}

# ── OpenSearch ────────────────────────────────────────────────────────
esperar OpenSearch "$OS/_cluster/health?wait_for_status=yellow&timeout=5s"

echo "1. Plantilla de los índices de logs (1 shard, sin réplicas, campos keyword)"
curl -sS --fail-with-body -X PUT "$OS/_index_template/logs-boletera" -H "$JSON" \
  --data-binary @"$D/plantilla-logs.json"; echo

echo "2. Política de retención: borrar a los 7 días (logs y trazas)"
# Si ya existe, OpenSearch pide su versión actual (seq_no y primary_term)
ACTUAL=$(curl -s "$OS/_plugins/_ism/policies/retencion-7-dias")
SEQ=$(echo "$ACTUAL" | sed -n 's/.*"_seq_no":\([0-9]*\).*/\1/p')
TERM=$(echo "$ACTUAL" | sed -n 's/.*"_primary_term":\([0-9]*\).*/\1/p')
VERSION=""
[ -n "$SEQ" ] && VERSION="?if_seq_no=$SEQ&if_primary_term=$TERM"
curl -sS --fail-with-body -X PUT "$OS/_plugins/_ism/policies/retencion-7-dias$VERSION" -H "$JSON" \
  --data-binary @"$D/retencion-7-dias.json"; echo

echo "3. La política también para los índices que ya existían"
for p in 'boletera-logs-*' 'cluster-logs-*' 'boletera-jaeger-*'; do
  curl -s -X POST "$OS/_plugins/_ism/add/$p" -H "$JSON" -d '{"policy_id":"retencion-7-dias"}'; echo
done
# Con un solo nodo, una réplica nunca se puede asignar (índice en amarillo).
# Incluye el índice interno de la política de retención (.opendistro-ism-config),
# que el plugin crea con 1 réplica.
curl -s -X PUT "$OS/boletera-logs-*,cluster-logs-*,.opendistro-ism-config/_settings?expand_wildcards=all" \
  -H "$JSON" -d '{"index":{"number_of_replicas":0}}'; echo
curl -s "$OS/_cluster/health?wait_for_status=green&timeout=30s" | grep -o '"status":"[a-z]*"'

# ── OpenSearch Dashboards ─────────────────────────────────────────────
esperar "OpenSearch Dashboards" "$OSD/api/status"
OBJETOS="$OSD/api/saved_objects"
XSRF="osd-xsrf: true"

echo "4. Index patterns (trace_id como enlace a Jaeger)"
curl -sS --fail-with-body -X POST "$OBJETOS/index-pattern/boletera-logs?overwrite=true" \
  -H "$XSRF" -H "$JSON" --data-binary @"$D/patron-boletera-logs.json"; echo
curl -sS --fail-with-body -X POST "$OBJETOS/index-pattern/cluster-logs?overwrite=true" \
  -H "$XSRF" -H "$JSON" --data-binary @"$D/patron-cluster-logs.json"; echo

echo "5. Búsqueda guardada \"Errores de la tienda\""
curl -sS --fail-with-body -X POST "$OBJETOS/search/errores-tienda?overwrite=true" \
  -H "$XSRF" -H "$JSON" --data-binary @"$D/busqueda-errores.json"; echo

echo "6. boletera-logs-* como index pattern predeterminado y hora de México"
curl -sS --fail-with-body -X POST "$OSD/api/opensearch-dashboards/settings" \
  -H "$XSRF" -H "$JSON" --data-binary @"$D/ajustes-dashboards.json"; echo

echo "Configuración lista."
