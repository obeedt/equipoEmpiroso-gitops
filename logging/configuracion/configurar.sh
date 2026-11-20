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
# Incluye los índices internos del plugin de retención: su configuración y
# su historial diario, que el plugin crea con 1 réplica.
curl -s -X PUT "$OS/_cluster/settings" -H "$JSON" \
  -d '{"persistent":{"plugins.index_state_management.history.number_of_replicas":0}}'; echo
curl -s -X PUT "$OS/boletera-logs-*,cluster-logs-*,.opendistro-ism-config,.opendistro-ism-managed-index-history-*/_settings?expand_wildcards=all" \
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

# Lista de campos de cada index pattern (nombre y tipo: @timestamp es fecha,
# servicio es keyword...). Sin ella, Discover no encuentra @timestamp y
# muestra todos los campos con tipo desconocido. Se lee de los índices
# reales, así que se espera a que Fluent Bit haya creado el primero.
campos() {   # $1 = id del index pattern, $2 = patrón de índices
  URL="$OSD/api/index_patterns/_fields_for_wildcard?pattern=$2&meta_fields=_source&meta_fields=_id&meta_fields=_type&meta_fields=_index&meta_fields=_score"
  i=0
  until curl -sf -o /dev/null "$URL"; do
    i=$((i + 1))
    if [ "$i" -gt 60 ]; then echo "  $2: todavía no hay índices; Dashboards leerá los campos después"; return 0; fi
    sleep 5
  done
  # {"fields":[...]} → el arreglo, como texto JSON dentro del atributo "fields"
  LISTA=$(curl -s "$URL" | sed 's/^{"fields"://; s/}$//' | sed 's/\\/\\\\/g; s/"/\\"/g')
  curl -sS --fail-with-body -o /dev/null -X PUT "$OBJETOS/index-pattern/$1" -H "$XSRF" -H "$JSON" \
    -d "{\"attributes\":{\"fields\":\"$LISTA\"}}"
  echo "  $1: $(echo "$LISTA" | grep -o 'name\\":' | wc -l) campos"
}
campos boletera-logs 'boletera-logs-*'
campos cluster-logs 'cluster-logs-*'

echo "5. Búsqueda guardada \"Errores de la tienda\""
curl -sS --fail-with-body -X POST "$OBJETOS/search/errores-tienda?overwrite=true" \
  -H "$XSRF" -H "$JSON" --data-binary @"$D/busqueda-errores.json"; echo

echo "6. boletera-logs-* como index pattern predeterminado y hora de México"
curl -sS --fail-with-body -X POST "$OSD/api/opensearch-dashboards/settings" \
  -H "$XSRF" -H "$JSON" --data-binary @"$D/ajustes-dashboards.json"; echo

echo "Configuración lista."
