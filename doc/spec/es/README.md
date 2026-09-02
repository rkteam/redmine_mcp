# Redmine MCP

[Sitio web](https://redmine-kanban.com/)

[Deutsch](../de/README.md) | [English](../en/README.md) | Español | [Français](../fr/README.md) | [Italiano](../it/README.md) | [日本語](../ja/README.md) | [한국어](../ko/README.md) | [Polski](../pl/README.md) | [Português (Brasil)](../pt-BR/README.md) | [Русский](../ru/README.md) | [中文](../zh/README.md)

Un servidor MCP (Model Context Protocol) dentro de Redmine. Permite a los clientes de IA trabajar con incidencias, proyectos y usuarios a través de los permisos estándar de Redmine. Otros plugins pueden añadir sus propias herramientas, recursos, prompts y capacidades sin modificar este plugin.

## Requisitos

| Componente | Versión |
|---|---|
| Redmine | Redmine 6.0+ (probado: 6.0–6.1) |
| MCP protocol | 2025-11-25 |
| Ruby MCP SDK (`mcp`) | 0.23.x |

Este plugin utiliza MCP protocol `2025-11-25` y Ruby MCP SDK `0.23.x`.
La compatibilidad con versiones más recientes de MCP protocol y SDK no está declarada actualmente.

- API REST habilitada en Redmine
- la gema `mcp` está declarada en `plugins/redmine_mcp/Gemfile` y se instala con `bundle install`

## Instalación y configuración

### 1. Instalar el plugin

Clone el repositorio git en el directorio `plugins` de Redmine:

```bash
cd /path/to/redmine/plugins
git clone https://github.com/rkteam/redmine_mcp.git
```

Desde el directorio raíz de Redmine, instale las dependencias y reinicie la aplicación:

```bash
cd /path/to/redmine
bundle install
```

Reinicie Redmine.

### 2. Habilitar en Administración

**Administración → Plugins → Redmine MCP → Configurar**

| Parámetro | Descripción |
|---------|-------------|
| Activar MCP | Habilita el endpoint `/mcp`. Cuando está habilitado, se cargan las extensiones MCP de los plugins instalados |
| Modo de solo lectura | Bloquea herramientas de escritura y acciones de escritura (create/update/delete, etc.) |
| Extensiones MCP | Casillas para habilitar la integración MCP de los plugins instalados |

### 3. API REST

**Administración → Configuración → API** — habilitar «Activar servicio web REST».

### 4. Permisos

**Administración → Roles y permisos** — para los roles necesarios, habilitar manualmente el permiso global **Usar MCP** (`use_mcp`). Los administradores de Redmine siempre tienen acceso a MCP.

### 5. Clave API del usuario

Cada usuario que vaya a trabajar a través de MCP debe tener una clave API:

**Mi cuenta → Clave de acceso de la API** (o a través de la API REST de usuario).

Pase la clave en la cabecera:

```
X-Redmine-API-Key: <your_key>
```

## Conectar un cliente MCP

El servidor utiliza **Streamable HTTP** (stateless). Endpoint:

```
https://<your-redmine>/mcp
```

Métodos compatibles: `GET`, `POST`, `DELETE`.

### Ejemplo para Cursor

En la configuración MCP (`.cursor/mcp.json` o la configuración global), añada un servidor con transporte HTTP. El formato exacto depende de la versión del cliente; un ejemplo típico:

```json
{
  "mcpServers": {
    "redmine": {
      "url": "https://your-redmine.example.com/mcp",
      "headers": {
        "X-Redmine-API-Key": "your_api_key"
      }
    }
  }
}
```

Tras conectarse, el cliente llamará a `initialize` y luego podrá invocar `tools/list`, `tools/call`, `resources/list`, `prompts/list`, etc.

### Comprobación manual

```bash
curl -s -X POST 'https://your-redmine.example.com/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'MCP-Protocol-Version: 2025-11-25' \
  -H 'X-Redmine-API-Key: your_key' \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2025-11-25",
      "capabilities": {},
      "clientInfo": { "name": "curl", "version": "1.0" }
    }
  }'
```

Una respuesta correcta contiene `serverInfo.name: "redmine_mcp"`.

### Host y proxy inverso

El transporte MCP valida HTTP `Host` y `Origin` para proteger contra DNS rebinding.

El host permitido se toma de la configuración de Redmine:

**Administración → Configuración → General → Nombre y ruta del servidor**

El valor debe coincidir con la URL pública de Redmine.

Por ejemplo, si Redmine está disponible en:

```
https://redmine.example.com
```

en la configuración debería usarse:

```
redmine.example.com
```

Si Redmine se ejecuta detrás de un proxy inverso, el proxy debe reenviar la cabecera `Host` original del cliente.

Si el host no coincide, el endpoint MCP puede devolver HTTP `403 Forbidden`.

Los clientes sin cabecera `Origin` no se ven afectados por la comprobación de Origin.

## Herramientas integradas (herramientas del núcleo)

Los nombres completos usan el formato `redmine_<tool_name>` (por ejemplo `redmine_get_issue`).

El servidor proporciona herramientas para proyectos, incidencias, usuarios, registro de tiempo, wiki, foros y archivos. La lista siguiente es un resumen breve de las herramientas integradas. Los esquemas de entrada y descripciones completos están disponibles para el cliente MCP mediante `tools/list`.

### Parámetros comunes

- `project` — ID de proyecto en cadena o identificador.
- `assignee_ref` / `user_ref` con el valor `me` — el usuario actual.
- `assigned_to_id` — usuario o grupo al que se asigna la incidencia; `null` borra campos opcionales.
- `create_time_entry` requiere `project` o `issue_id`.
- `upload_file` requiere `filename` y `content_base64`.

### Fiabilidad de las operaciones

- `expected_updated_at` — en operaciones sensibles de actualización/eliminación.
- `idempotency_key` — en `create_issue`, `copy_issue`, `update_issue`, `add_issue_note`, `create_time_entry`, `import_time_entries`, `upload_file`.

### Límites

- timeout de lectura de 60 s;
- 120 solicitudes/min por usuario;
- cuerpo HTTP de solicitud MCP hasta 36 MiB;
- args JSON de herramienta hasta 32 MiB;
- adjuntos en base64 hasta 20 MiB;
- descargas de adjuntos hasta 10 MiB.

### Despliegue en producción

La limitación de velocidad y la idempotencia usan `Rails.cache`.

Para instalaciones con varios workers de aplicación o varias instancias de Redmine, debería usarse un almacén de caché compartido.

Con una caché local al proceso, las garantías de limitación de velocidad e idempotencia solo se aplican dentro de un proceso de aplicación individual.

### Gestión de proyectos

| Herramienta | Descripción |
|------|-------------|
| `list_projects` | Listar proyectos |
| `get_project` | Detalles del proyecto |
| `list_project_issue_custom_fields` | Campos personalizados de incidencias del proyecto |
| `summarize_project_status` | Resumen de métricas del proyecto generado por el servidor para N días |
| `list_project_activities` | Feed de actividad del proyecto (eventos, no tipos de registro de tiempo) |
| `list_versions` | Versiones del roadmap (hitos) |
| `get_version` | Detalles de versión del roadmap con agregados |
| `create_version` | Crear una versión |
| `update_version` | Actualizar una versión |
| `delete_version` | Eliminar una versión |
| `list_project_members` | Miembros del proyecto y sus roles |
| `list_project_member_candidates` | Usuarios y grupos que pueden añadirse al proyecto |
| `list_roles` | Roles gestionables en el proyecto |
| `get_project_modules` | Módulos del proyecto habilitados |
| `add_project_member` | Añadir un miembro |
| `update_project_member` | Cambiar roles de miembro |
| `remove_project_member` | Eliminar un miembro |

### Incidencias

| Herramienta | Descripción |
|------|-------------|
| `get_issue` | Detalles de la incidencia (diario, adjuntos, campos personalizados, etc.) |
| `list_issues` | Listar incidencias con filtros y paginación |
| `search_issues` | Búsqueda de texto en incidencias |
| `run_issue_query` | Ejecutar una consulta de incidencias guardada |
| `get_issue_form_options` | Valores permitidos de los campos del formulario de incidencia (una sola llamada) |
| `validate_issue_create` | Validar parámetros de creación de incidencia sin escribir |
| `validate_issue_update` | Validar parámetros de actualización de incidencia sin escribir |
| `create_issue` | Crear una incidencia |
| `update_issue` | Actualizar atributos de incidencia y adjuntos |
| `add_issue_note` | Añadir un comentario a una incidencia (opcionalmente con adjuntos) |
| `delete_issue` | Eliminar una incidencia con confirmación |
| `copy_issue` | Copiar una incidencia |
| `list_issue_relations` | Listar relaciones de incidencias |
| `create_issue_relation` | Crear una relación entre incidencias |
| `delete_issue_relation` | Eliminar una relación de incidencias |
| `list_subtasks` | Subtareas |
| `add_issue_watcher` | Añadir un observador |
| `remove_issue_watcher` | Eliminar un observador |
| `update_issue_note` | Editar una entrada del diario |
| `set_issue_note_private` | Cambiar la privacidad de una entrada del diario |
| `get_private_notes` | Solo comentarios privados |
| `list_issue_categories` | Categorías de incidencias del proyecto |
| `create_issue_category` | Crear una categoría |
| `update_issue_category` | Actualizar una categoría |
| `delete_issue_category` | Eliminar una categoría |

### Usuarios

| Herramienta | Descripción |
|------|-------------|
| `list_users` | Miembros del proyecto; filtros `query` (nombre/login) y `login`; la búsqueda global es solo para administradores |
| `list_groups` | Grupos givable para `group_id` en `add_project_member` |

### Registro de tiempo

| Herramienta | Descripción |
|------|-------------|
| `list_time_entries` | Listar entradas de tiempo |
| `create_time_entry` | Crear una entrada de tiempo |
| `update_time_entry` | Actualizar una entrada de tiempo |
| `list_time_entry_activities` | Tipos de actividad para registro de tiempo (no el feed de eventos del proyecto) |
| `import_time_entries` | Importación masiva de entradas de tiempo |

### Datos de referencia

| Herramienta | Descripción |
|------|-------------|
| `list_trackers` | Todos los trackers |
| `list_project_trackers` | Trackers del proyecto |
| `list_issue_statuses` | Estados de incidencias |
| `list_issue_priorities` | Prioridades de incidencias |
| `admin_list_users` | Usuarios con filtros (solo administrador) |
| `get_current_user` | Usuario actual |
| `list_queries` | Consultas guardadas (metadatos; la ejecución es `run_issue_query`) |

### Búsqueda y wiki

| Herramienta | Descripción |
|------|-------------|
| `search_all` | Buscar incidencias y páginas wiki |
| `list_wiki_pages` | Páginas wiki del proyecto |
| `get_wiki_page` | Obtener una página wiki |
| `create_wiki_page` | Crear una página wiki |
| `update_wiki_page` | Actualizar una página wiki |
| `delete_wiki_page` | Eliminar una página wiki |
| `rename_wiki_page` | Renombrar una página wiki |

### Foros

| Herramienta | Descripción |
|------|-------------|
| `list_boards` | Tableros del foro del proyecto |
| `list_board_topics` | Temas del tablero seleccionado |
| `get_board_message` | Mensaje del foro con respuestas breves |

### Archivos

| Herramienta | Descripción |
|------|-------------|
| `list_project_files` | Archivos del proyecto |
| `upload_file` | Subir un archivo |
| `delete_attachment` | Eliminar un adjunto |
| `get_attachment` | Metadatos del adjunto y `content_url` |
| `download_attachment` | Contenido del adjunto (`content_base64`, hasta 10 MiB) |

### Utilidades

| Herramienta | Descripción |
|------|-------------|
| `get_mcp_info` | Versión del plugin MCP, modo de solo lectura, usuario actual y capacidades disponibles |

### Acceso y respuestas

Las herramientas devuelven un envoltorio JSON en `structuredContent` y una representación de texto en `content`.

Las operaciones de escritura se bloquean mediante la configuración **Modo de solo lectura**.

Además de los permisos específicos de cada herramienta, siempre se comprueba el permiso global **Usar MCP**.

El acceso a los datos se aplica mediante los permisos estándar de Redmine y las reglas de visibilidad. Para datos de proyectos e incidencias se usan `Project.visible` e `Issue.visible`.

## Extensiones de otros plugins

Cualquier plugin de Redmine instalado puede añadir sus propias herramientas MCP y, si es necesario, registrar recursos, prompts y capacidades.

Guía detallada: [extension_guide.md](extension_guide.md).

Para el desarrollo asistido por IA en Cursor o agentes similares, copie el directorio de skill incluido [`redmine-mcp-plugin-integration`](../../skills/redmine-mcp-plugin-integration/) en la carpeta de skills de su agente, o úselo como base para su propio skill.

## Registro

Los mensajes se escriben en el log estándar de Rails con el prefijo `[redmine_mcp]`:

- carga de extensiones
- registro de herramientas/recursos/prompts
- errores de registro y ejecución
- denegaciones de acceso

## Solución de problemas

| Síntoma | Posible causa |
|---------|----------------|
| HTTP 503 «MCP is disabled» | MCP no está habilitado en la configuración del plugin |
| HTTP 401 | Clave API ausente o no válida; la API REST está deshabilitada |
| HTTP 403 (permiso) | El usuario no tiene el permiso **Usar MCP** |
| HTTP 403 (`Host`/`Origin`) | **Nombre y ruta del servidor** no coincide con la URL pública de Redmine; el proxy inverso no reenvía el `Host` original; la URL MCP en el cliente no coincide — el transporte rechaza hosts desconocidos (protección DNS rebinding) |
| La herramienta no es visible en `tools/list` | Faltan permisos necesarios; la extensión que proporciona la herramienta está deshabilitada |
| Las nuevas herramientas no aparecieron tras recargar MCP | En Cursor y clientes similares, recargar el servidor puede no actualizar la lista de herramientas — reinicie completamente la aplicación |
| La extensión no se carga | Falta `lib/.../mcp.rb`; el módulo no hace `extend RedmineMcp::ExtensionApi`; asegúrese de que la casilla de extensión esté habilitada en **Extensiones MCP**; si el archivo tiene un error, consulte el log |
| `Issue not found` / `Project not found` | La incidencia o el proyecto no es visible para el usuario actual según las reglas de visibilidad de Redmine |

## Licencia

Este plugin está licenciado bajo la GNU General Public License,
versión 2 o cualquier versión posterior.

Consulte [LICENSE](../../../LICENSE) para más detalles.
