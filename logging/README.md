# logging

Logs centralizados y trazas distribuidas (namespace `logging`). Corren en el
worker con el rol `logs`.

- **Fluent Bit**: recoge los logs (JSON) de todos los pods y los envía a OpenSearch.
- **OpenSearch** y **OpenSearch Dashboards**: guardan y permiten consultar los logs.
- **Jaeger**: recibe las trazas de los microservicios (OpenTelemetry) y las guarda en OpenSearch.

Con el `trace_id` que va en cada log se puede pasar de un error a la traza
completa de la petición.
