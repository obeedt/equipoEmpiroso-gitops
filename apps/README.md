# apps

Applications de **Argo CD**.

Aquí irá una Application "raíz" (patrón **app-of-apps**) que apunta a esta
carpeta, y una Application por cada componente de la plataforma: Ingress,
StorageClasses, tienda, monitoreo y logs. Cada una le dice a Argo CD qué
carpeta de este repositorio desplegar y en qué namespace.

Sincronización automática con `prune` y `selfHeal`: si alguien cambia algo a
mano en el clúster, Argo CD lo regresa a lo que dice Git.
