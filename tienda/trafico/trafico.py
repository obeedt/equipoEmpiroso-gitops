"""Generador de tráfico de la boletera.

Recorre la tienda como lo haría un cliente, para que los dashboards de
aplicación tengan peticiones, latencia y (con ERROR_RATE) errores 5xx:

  1. catálogo          GET  frontend /                 → svc-eventos
  2. un concierto      GET  frontend /evento/<id>      → svc-eventos
  3. cada N vueltas:   aparta 2 lugares (POST /carrito → svc-reservaciones),
                       ve el carrito y lo cancela (los lugares se liberan)
  4. un pedido         GET  svc-ordenes /ordenes/<id>  (solo lectura)

Nunca paga: no cambia los boletos vendidos ni la alerta de negocio.
Se detiene solo al cumplir DURACION_MIN.
"""
import http.cookiejar
import json
import os
import random
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import Counter

FRONTEND = "http://frontend.tienda.svc"
EVENTOS = "http://svc-eventos.tienda.svc"
ORDENES = "http://svc-ordenes.tienda.svc"

DURACION = int(os.environ.get("DURACION_MIN", "20")) * 60
PAUSA = float(os.environ.get("PAUSA_SEG", "2"))
CARRITO_CADA = int(os.environ.get("CARRITO_CADA", "5"))
ORDEN_ID = os.environ.get("ORDEN_ID", "")

conteo = Counter()


def pedir(navegador, metodo, url, datos=None):
    """Hace la petición y cuenta su resultado (código HTTP o 'sin respuesta')."""
    cuerpo = urllib.parse.urlencode(datos).encode() if datos else None
    req = urllib.request.Request(url, data=cuerpo, method=metodo,
                                 headers={"User-Agent": "boletera-trafico/1.0"})
    try:
        with navegador.open(req, timeout=10) as r:
            r.read()
            conteo[str(r.status)] += 1
            return r.status
    except urllib.error.HTTPError as e:
        conteo[str(e.code)] += 1
        return e.code
    except (urllib.error.URLError, TimeoutError, ConnectionError):
        conteo["sin respuesta"] += 1
        return None


def leer_json(url):
    try:
        with urllib.request.urlopen(url, timeout=10) as r:
            return json.load(r)
    except Exception:  # noqa: BLE001 · si falla, se reintenta en la siguiente vuelta
        return None


def carrito(navegador, evento_id):
    """Aparta 2 lugares, ve el carrito y lo cancela."""
    detalle = leer_json(f"{EVENTOS}/eventos/{evento_id}")
    if not detalle:
        return
    secciones = [s["seccion"] for s in detalle.get("secciones", []) if s.get("disponibles", 0) >= 2]
    if not secciones:
        return
    datos = {"evento_id": evento_id, "seccion": random.choice(secciones), "cantidad": 2}
    if pedir(navegador, "POST", f"{FRONTEND}/carrito", datos) == 200:   # redirige a /carrito
        pedir(navegador, "POST", f"{FRONTEND}/carrito/cancelar")


def main():
    print(f"Tráfico durante {DURACION // 60} min · pausa {PAUSA} s · carrito cada {CARRITO_CADA} vueltas", flush=True)
    fin = time.monotonic() + DURACION
    siguiente_resumen = time.monotonic() + 60
    ids, vuelta = [], 0
    while time.monotonic() < fin:
        vuelta += 1
        if not ids or vuelta % 30 == 0:
            ids = [e["id"] for e in (leer_json(f"{EVENTOS}/eventos") or [])] or ids
        # Cada vuelta es un "cliente" nuevo, con sus propias cookies
        navegador = urllib.request.build_opener(
            urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
        pedir(navegador, "GET", f"{FRONTEND}/")
        if ids:
            evento_id = random.choice(ids)
            pedir(navegador, "GET", f"{FRONTEND}/evento/{evento_id}")
            if vuelta % CARRITO_CADA == 0:
                carrito(navegador, evento_id)
        if ORDEN_ID:
            pedir(navegador, "GET", f"{ORDENES}/ordenes/{ORDEN_ID}")
        if time.monotonic() >= siguiente_resumen:
            print(f"vuelta {vuelta} · respuestas: {dict(sorted(conteo.items()))}", flush=True)
            siguiente_resumen += 60
        time.sleep(PAUSA)
    print(f"Fin · {vuelta} vueltas · respuestas: {dict(sorted(conteo.items()))}", flush=True)


if __name__ == "__main__":
    main()
