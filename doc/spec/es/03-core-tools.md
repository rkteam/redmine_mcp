# Herramientas integradas (herramientas del núcleo)

[Deutsch](../de/03-core-tools.md) | [English](../en/03-core-tools.md) | [Español](03-core-tools.md) | [Français](../fr/03-core-tools.md) | [Italiano](../it/03-core-tools.md) | [日本語](../ja/03-core-tools.md) | [한국어](../ko/03-core-tools.md) | [Polski](../pl/03-core-tools.md) | [Português (Brasil)](../pt-BR/03-core-tools.md) | [Русский](../ru/03-core-tools.md) | [中文](../zh/03-core-tools.md)

## Descripción general

El plugin Redmine MCP proporciona un conjunto de herramientas para trabajar con proyectos Redmine, incidencias, registro de tiempo, wiki, foros, archivos y datos de referencia (lectura y escritura).

## Objetivo

Ofrecer a los clientes de IA operaciones de gestión de proyectos, operaciones de incidencias, registro de tiempo, descubrimiento, búsqueda y wiki, foros, operaciones con archivos y meta sin instalar plugins adicionales.

## Áreas afectadas

- Proyectos
- Versiones
- Miembros / Roles
- Incidencias (CRUD, relaciones, observadores, notas, categorías, opciones de formulario, validación dry-run, consultas guardadas)
- Entradas de tiempo
- Trackers, estados, prioridades, consultas
- Actividad del proyecto
- Páginas wiki
- Foros / mensajes
- Archivos del proyecto / adjuntos
- Usuarios
- Permisos
- Configuración (modo de solo lectura)

## Reglas de negocio

### Reglas generales

- Nombre completo de la herramienta: `redmine_<name>` (por ejemplo `redmine_get_issue`).
- El resultado se devuelve como envoltorio JSON en `structuredContent` y se duplica como texto en `content`.
- Los datos se filtran mediante la visibilidad de proyectos/incidencias y los permisos de Redmine.
- El parámetro `project` es una cadena: id numérico como cadena (por ejemplo `"1"`) o identificador de proyecto (por ejemplo `"ecookbook"`).
- Cuando el **modo de solo lectura** está activado, las herramientas de escritura devuelven un error. Las herramientas de solo lectura, incluidas `list_issue_relations`, `get_issue_form_options`, `validate_issue_create` y `validate_issue_update`, siguen disponibles.

### Gestión de proyectos

| Herramienta | R/W | Permiso |
|------|-----|------------|
| `list_projects` | R | `view_project` |
| `get_project` | R | `view_project` |
| `list_project_issue_custom_fields` | R | `view_issues` |
| `summarize_project_status` | R | `view_issues` |
| `list_project_activities` | R | `view_project` |
| `list_versions` | R | `view_issues` |
| `get_version` | R | `view_issues` |
| `create_version` | W | `manage_versions` |
| `update_version` | W | `manage_versions` |
| `delete_version` | W | `manage_versions` |
| `list_project_members` | R | `view_members` |
| `list_project_member_candidates` | R | `manage_members` |
| `list_roles` | R | `manage_members` + `project` |
| `get_project_modules` | R | `view_project` |
| `add_project_member` | W | `manage_members` |
| `update_project_member` | W | `manage_members` |
| `remove_project_member` | W | `manage_members` |

### Operaciones de incidencias

| Herramienta | R/W | Permiso |
|------|-----|------------|
| `get_issue` | R | `view_issues` |
| `list_issues` | R | `view_issues` |
| `search_issues` | R | `view_issues` |
| `run_issue_query` | R | `view_issues` |
| `get_issue_form_options` | R | `view_issues` |
| `validate_issue_create` | R | `add_issues` |
| `validate_issue_update` | R | `edit_issues` |
| `create_issue` | W | `add_issues` |
| `update_issue` | W | atributos — si son editables; `uploads` solo — si se pueden añadir adjuntos |
| `add_issue_note` | W | `add_issue_notes`; `private_notes=true` además requiere `set_notes_private` |
| `delete_issue` | W | `delete_issues` |
| `copy_issue` | W | `copy_issues` en el proyecto origen y `add_issues` en el destino |
| `list_issue_relations` | R | `view_issues` |
| `create_issue_relation` | W | `manage_issue_relations` |
| `delete_issue_relation` | W | `manage_issue_relations` |
| `list_subtasks` | R | `view_issues` |
| `add_issue_watcher` | W | `add_issue_watchers` |
| `remove_issue_watcher` | W | `delete_issue_watchers` |
| `update_issue_note` | W | la entrada del diario es visible y editable (`edit_issue_notes` / `edit_own_issue_notes`); `private_notes` además requiere `set_notes_private` |
| `set_issue_note_private` | W | la entrada del diario es visible y editable, más `set_notes_private` |
| `get_private_notes` | R | `view_private_notes` |
| `list_issue_categories` | R | `view_issues` |
| `create_issue_category` | W | `manage_categories` |
| `update_issue_category` | W | `manage_categories` |
| `delete_issue_category` | W | `manage_categories` |

### Usuarios

| Herramienta | R/W | Permiso |
|------|-----|------------|
| `list_users` | R | `view_members` + `project`; sin `project` — solo administrador |
| `list_groups` | R | `manage_members` (en cualquier proyecto) o administrador |

### Registro de tiempo

| Herramienta | R/W | Permiso |
|------|-----|------------|
| `list_time_entries` | R | `view_time_entries` |
| `create_time_entry` | W | `log_time` |
| `update_time_entry` | W | la entrada es editable por el usuario actual (`edit_time_entries` / `edit_own_time_entries`) |
| `list_time_entry_activities` | R | `log_time` |
| `import_time_entries` | W | `log_time` |

### Descubrimiento / Enumeración

| Herramienta | R/W | Permiso |
|------|-----|------------|
| `list_trackers` | R | `view_issues` |
| `list_project_trackers` | R | `view_issues` |
| `list_issue_statuses` | R | `view_issues` |
| `list_issue_priorities` | R | `view_issues` |
| `list_all_users` | R | admin |
| `get_current_user` | R | `use_mcp` |
| `list_queries` | R | `view_issues` |

### Búsqueda y Wiki

| Herramienta | R/W | Permiso |
|------|-----|------------|
| `search_all` | R | acceso a al menos uno de los tipos buscados (`view_issues` y/o `view_wiki_pages`) |
| `list_wiki_pages` | R | `view_wiki_pages` |
| `get_wiki_page` | R | `view_wiki_pages`; `version` histórica además requiere `view_wiki_edits` |
| `create_wiki_page` | W | `edit_wiki_pages` y la página debe ser editable |
| `update_wiki_page` | W | `edit_wiki_pages` y la página debe ser editable |
| `delete_wiki_page` | W | `delete_wiki_pages` y la página debe ser editable |
| `rename_wiki_page` | W | `rename_wiki_pages` y la página debe ser editable |

### Foros

| Herramienta | R/W | Permiso |
|------|-----|------------|
| `list_boards` | R | `view_messages` |
| `list_board_topics` | R | `view_messages` |
| `get_board_message` | R | `view_messages` |

### Operaciones con archivos

| Herramienta | R/W | Permiso |
|------|-----|------------|
| `list_files` | R | `view_files` |
| `upload_file` | W | `manage_files` |
| `delete_file` | W | `manage_files` (o permisos del contenedor) |
| `get_attachment` | R | permisos sobre el contenedor del adjunto |
| `download_attachment` | R | permisos sobre el contenedor del adjunto |

### Meta

| Herramienta | R/W | Permiso |
|------|-----|------------|
| `get_server_info` | R | `use_mcp` |

`get_server_info` devuelve `server_version`, `read_only_mode`, `auth_mode`, datos breves del usuario actual y `capabilities.issue_search`. La instalación de plugins de terceros no aparece en la respuesta: sus herramientas MCP son visibles mediante `tools/list` y mediante las `capabilities` que las extensiones registran por sí mismas.

`capabilities.issue_search` contiene los modos de búsqueda:

| Modo | Por defecto | Nota |
|------|---------|------|
| `keyword` | `available: true`, herramienta `redmine_search_issues` | Siempre |
| `cross_resource` | `available: true`, herramienta `redmine_search_all` | Siempre |
| `semantic` | `available: false` | Los plugins pueden sobrescribir mediante `register_capability(:issue_search, :semantic)` |

Cuando `semantic.available: true`, la capacidad DEBE incluir `tool`, `provider` y `use_when` / `avoid_when` — indicaciones breves sobre cuándo elegir la búsqueda semántica. `Registry#apply_capabilities` normaliza la respuesta del proveedor: si se viola el contrato, se publica `{ available: false }`.

### Aclaraciones

- `delete_issue` sin `confirm_delete` devuelve una vista previa del impacto; si hay **alguna** subtarea (incluidas las invisibles para el usuario), se requiere `confirm_delete_with_children`. Los contadores en `impact` cubren solo diarios, relaciones, entradas de tiempo, hijos y adjuntos visibles para el usuario actual.
- `search_issues` con `scope=subprojects` requiere `project` y busca en ese proyecto y sus descendientes. Sin `project`, ese alcance es un error de parámetro. `scope=my_project` limita la búsqueda a proyectos en los que el usuario es miembro.
- `get_issue`: los diarios, adjuntos, observadores, relaciones, hijos y campos personalizados se incluyen solo con `include_*` explícito. Las listas anidadas tienen `limit`/`offset` separados y un campo `*_pagination` (diarios: límite por defecto 25, máximo 100; otras listas anidadas: por defecto y máximo 100). Sin el `include_*` correspondiente, la lista está vacía y la paginación es `null`. Los campos opcionales (`custom_fields`, `journals`, `attachments`, `watchers`, `relations`, `children`) siempre están presentes en la respuesta. Campos personalizados — solo los visibles para el usuario actual. Diarios — la misma visibilidad que el historial de la incidencia en Redmine: una entrada aparece en `journals` y `journal_pagination` solo si tiene texto o al menos un cambio de detalle visible para el usuario. El texto compuesto únicamente por espacios, tabulaciones o saltos de línea se trata como vacío. Las entradas vacías y las que solo tienen detalles ocultos (incluidos campos personalizados ocultos) se excluyen de la lista y de `total_count` / `offset` / `has_more`. Comentarios privados — comentarios propios o con permiso `view_private_notes`. Los elementos del diario contienen solo cambios de detalle visibles. Relaciones — solo enlaces cuyos dos extremos son visibles para el usuario. La misma regla de visibilidad de relaciones se aplica a `list_issue_relations`.
- `get_private_notes` devuelve solo comentarios privados con texto no vacío (espacios, tabulaciones y saltos de línea sin otro contenido cuentan como texto vacío). La página se limita por `limit`/`offset` sin cargar el historial completo de la incidencia.
- `list_project_issue_custom_fields` devuelve los campos visibles para el usuario en el proyecto. Si `tracker_id` está definido, el tracker debe pertenecer al proyecto.
- `copy_issue` requiere permiso para copiar incidencias en el proyecto **origen** y permiso para crear incidencias en el **destino**. Los observadores se copian solo si el usuario tiene permiso para añadir observadores en el proyecto destino. El enlace al original y la copia de adjuntos siguen la configuración de Redmine `link_copied_issue` y `copy_attachments_on_issue_copy` (`yes` / `no` / `ask`). Sin sobrescritura de campos, la copia sigue pasando por las reglas de escritura del formulario. El padre de la incidencia origen se conserva cuando está permitido (incluido al copiar dentro del mismo proyecto).
- `create_issue_relation` aplica solo atributos de relación permitidos y escribe el cambio en el diario de la incidencia. `delete_issue_relation` está permitido solo si la relación puede eliminarse por el usuario actual (ambas incidencias son visibles y el usuario tiene permiso para gestionar relaciones en al menos un extremo); la eliminación también se escribe en el diario.
- `add_project_member` / `update_project_member` aceptan solo roles que el usuario actual puede gestionar en el proyecto. Un rol fuera de ese conjunto se rechaza; los roles no se asignan parcialmente.
- `create_issue_category` / `update_issue_category`: `assigned_to_id` es un ID de principal (usuario o grupo), no solo un usuario.
- `delete_file` para un adjunto de incidencia sigue la regla «¿se pueden eliminar adjuntos en esta incidencia?» (incluidas incidencias propias y permisos del tracker), no solo `edit_issues` global. En `tools/list`, la herramienta es visible si el usuario puede eliminar al menos un adjunto (archivos de proyecto, incidencias o wiki), no solo con `manage_files` global.
- `get_wiki_page`: `attachments` siempre está en la respuesta; por defecto `[]` y `attachments_pagination: null`; con `include_attachments=true` — lista paginada de adjuntos con `attachment_limit`/`attachment_offset` (por defecto y máximo 100). `version` histórica requiere permiso para ver ediciones wiki. Cambiar, renombrar o eliminar una página protegida requiere permiso para proteger páginas wiki.
- `list_issues`, `search_issues`, `list_subtasks`, `run_issue_query`: campos resumidos por defecto; descripción completa mediante `fields` o `get_issue`.
- `create_issue` y `update_issue` aceptan **atributos** de incidencia explícitos (`subject`, `description`, `tracker_id`, `status_id`, `custom_fields`, etc.). Todos los atributos pasados explícitamente, incluidos `subject` y `description` al crear, pasan por las mismas reglas de escritura que el formulario web de Redmine. Antes de create/update, el agente DEBERÍA llamar a `get_issue_form_options` cuando los valores permitidos de campos son desconocidos. Un valor pasado explícitamente que Redmine no aplicó resulta en un error, no en éxito parcial.
- Si el cliente **no pasó** `start_date` en `create_issue` / `validate_issue_create`, y Redmine tiene activado «fecha de inicio = fecha de creación» (`default_issue_start_date_to_creation_date`), MCP establece `start_date` al día de hoy del usuario — como el formulario de nueva incidencia. Un `start_date` explícito (incluido `null`) desactiva esta sustitución. `copy_issue` y `update_issue` no sustituyen la fecha por sí mismos.
- `update_issue` no acepta `notes`, `private_notes` ni `watcher_user_ids`. Comentarios — `add_issue_note`; observadores — `add_issue_watcher` / `remove_issue_watcher`.
- `update_issue` también admite `uploads` para adjuntar archivos a una incidencia. Los adjuntos se procesan solo tras validación exitosa de atributos (incluido `rejected_fields`). Una llamada solo con `uploads` (sin atributos) está permitida si el usuario puede añadir adjuntos a la incidencia — incluso cuando comentar está permitido pero los atributos no se pueden editar. `idempotency_key` opcional protege contra reintentos tras una respuesta perdida (incluida la nueva subida de los mismos archivos). `journal_id` en la respuesta es la entrada del diario de **esta** llamada, no la última entrada de la incidencia.
- Para limpiar un campo opcional, pasar `null` para `assigned_to_id`, `category_id`, `fixed_version_id`, `parent_issue_id`, `start_date`, `due_date` o `estimated_hours`. Lo mismo para `update_version.due_date` / `wiki_page_title` y `update_issue_category.assigned_to_id`.
- `create_issue` no admite `uploads`.
- `update_issue` acepta `uploads[*].content_base64` y `uploads[*].filename`. Tras una subida exitosa, la respuesta contiene `added_attachments` — solo archivos de esta llamada, no la lista completa de adjuntos de la incidencia. Base64 corrupto es un error de parámetro.
- `update_issue` acepta `status_name` y lo resuelve a `status_id`.
- `upload_file` acepta `content_base64` (hasta 20 MiB); `project`, `filename` y `content_base64` son obligatorios.
- `get_attachment` devuelve `attachment_id`, `filename`, `content_type`, `size` (tamaño del archivo del adjunto) y `content_url` (sin bytes del archivo).
- `download_attachment` devuelve `attachment_id`, `filename`, `content_type`, `size` (tamaño real del contenido en bytes) y `content_base64` para un adjunto visible para el usuario actual. Si el MIME es desconocido — `application/octet-stream`. No incrementa el contador `downloads`. El límite de tamaño es 10 MiB (verifica `File.size` en disco antes de leer y `bytesize` después de leer); si se excede — `FILE_TOO_LARGE`. Las rutas del filesystem del servidor no se devuelven en la respuesta. `attachment_id` viene de `redmine_get_issue` / `redmine_get_wiki_page` con `include_attachments=true`, `redmine_list_files` o `redmine_get_attachment`. Para leer, parsear o procesar un adjunto como archivo, decodificar `content_base64` localmente. Adjuntos inexistentes e inaccesibles devuelven la misma respuesta «not found».
- `create_time_entry` y los elementos de `import_time_entries.entries` requieren `hours` y `project` o `issue_id`. `hours` puede ser 0; la validez de cero y el máximo diario son verificados por Redmine (`timelog_accept_0_hours`, `timelog_max_hours_per_day`).
- `assigned_to_id` al crear/actualizar incidencia es un ID de principal (usuario o grupo de `get_issue_form_options.assignees`); `null` limpia el asignado. `user_id` en `add_issue_watcher` / `remove_issue_watcher` es un ID de principal (usuario o grupo). En otras herramientas, `user_id` es un ID de usuario. Para el usuario actual, usar `assignee_ref` o `user_ref` con valor `me`.
- `expected_updated_at` (opcional) en update/delete sensible: si no coincide con `updated_on`, devuelve `CONFLICT`.
- `idempotency_key` (opcional) en `create_issue`, `copy_issue`, `update_issue`, `add_issue_note`, `create_time_entry`, `import_time_entries`, `upload_file`: un reintento con la misma clave y **el mismo conjunto de argumentos** (excepto la clave misma) devuelve el resultado exitoso en caché (TTL 24 h). La misma clave con un payload diferente — `CONFLICT`, sin escritura duplicada. Mientras la primera solicitud sigue en curso, un reintento con la misma clave no realiza otra escritura (el marcador «en curso» dura las mismas 24 h que un resultado exitoso). Una entrada en caché sin huella (caché de antes de esta versión) con la misma clave se devuelve como antes hasta que expire el TTL. El timeout del servidor de 60 s se aplica a las **lecturas**. Las operaciones de escritura no se interrumpen por el timeout del servidor para que tras un guardado exitoso se pueda registrar el resultado de idempotencia; el cliente puede reintentar con la misma clave si perdió la conexión. Una excepción inesperada en `import_time_entries` revierte las entradas ya insertadas en esa llamada; los errores de validación normales de filas individuales se recopilan sin revertir las exitosas.
- `delete_file` por defecto elimina solo archivos de proyecto/versión; para adjuntos de incidencia/wiki, se requiere `confirm_delete_any_attachment=true`.
- List/search usan `limit`/`offset`. Para consultas DB, la página se limita a nivel de consulta, no truncando una lista completa ya cargada. Cualquier colección MCP paginada tiene un orden estable explícito; el último criterio es siempre `id` para que las páginas no omitan ni dupliquen elementos.
- La búsqueda por subcadena (`query`, `login`, `name` y texto `search_issues`) coincide con los caracteres literalmente: `%` y `_` no son wildcards SQL.
- Límites MCP: timeout 60 s en herramientas de lectura, rate limit 120 solicitudes/min por usuario, cuerpo HTTP de solicitud MCP 36 MiB, tamaño máximo de argumentos JSON de herramienta 32 MiB, upload base64 hasta 20 MiB, download base64 hasta 10 MiB. Base64 corrupto en cualquier `content_base64` es un error de parámetro antes de la ejecución de la herramienta.
- Cada llamada a herramienta, incluida la denegación de acceso, se escribe en un registro de auditoría estructurado (herramienta, usuario, IDs objetivo, resultado, duración, correlation_id) y cuenta para el rate limit; el contenido base64 y las notas privadas no se registran. Los IDs objetivo incluyen `board_id`, `message_id`, `query_id`, `user_id`, `group_id`, entre otros.
- El `outputSchema` de cada herramienta del núcleo describe el nivel superior de `data` (para listas — campos de elementos `items`), no un objeto arbitrario abierto. El conjunto de campos del esquema coincide con la respuesta real: `list_users` sin `created_on`, `list_all_users` con `created_on`; `get_attachment` incluye `size` y `content_url`. Los campos que pueden estar vacíos en la respuesta real permiten `null` (incluido `time_entry.issue`, `*_pagination` sin include, `estimation_accuracy`, `content_type` del adjunto). Los valores de campos personalizados y `possible_values` no están limitados a objetos. `attachments_not_saved` es un array de nombres de archivo.
- `summarize_project_status.days` en el esquema: por defecto 30, mínimo 1, máximo 365.
- `search_all.resources`: máximo dos valores únicos.
- `version_id`, `file_id`, `tracker_id` son enteros no menores que 1.

### `get_project`

- Entrada: `project` (obligatorio).
- Salida: `id`, `name`, `identifier`, `description`, `homepage`, `status`, `is_public`, `inherit_members`, `created_on`, `updated_on`, `parent` (objeto `id`/`name`/`identifier` o `null`), `subprojects` (lista breve de proyectos hijos visibles: `id`/`name`/`identifier`), `custom_fields`, `last_activity_date`.
- `parent` se rellena solo si el proyecto padre es visible para el usuario actual; de lo contrario `null`.
- No devuelve miembros, módulos activados ni estadísticas de incidencias. Para módulos — `get_project_modules`; para miembros — `list_project_members`; para agregados de incidencias — `summarize_project_status`.

### `get_issue_form_options`

- Una llamada en lugar de varias consultas de referencia antes de create/update. `list_project_trackers`, `list_issue_statuses`, `list_issue_priorities`, `list_issue_categories`, `list_versions`, `list_users`, `list_project_issue_custom_fields` por separado siguen disponibles.
- Entrada: `project` (obligatorio); opcionalmente `tracker_id`, `issue_id`.
- La instantánea refleja el **formulario de incidencia para el usuario actual**, no la configuración completa del proyecto: los mismos valores permitidos que ofrece la interfaz de Redmine.
- `tracker_id` sin `issue_id` establece el contexto del formulario de creación. El tracker debe estar disponible para selección por el usuario actual en el formulario; de lo contrario — error de parámetro.
- `issue_id` establece el formulario para una incidencia existente visible en este proyecto. Con `issue_id`, `tracker_id` está permitido solo si coincide con el tracker actual de la incidencia; de lo contrario — error de parámetro (el cambio de tracker no se modela mediante esta herramienta).
- Salida — instantánea del formulario sin paginación:
  - `project`: `id`, `name`, `identifier`;
  - `trackers`: trackers que el usuario actual puede seleccionar en este formulario (`id`, `name`), no todos los trackers activados para el proyecto;
  - `priorities`: prioridades activas (`id`, `name`, `is_default`);
  - `categories`: categorías del proyecto (`id`, `name`);
  - `versions`: versiones disponibles para selección en este formulario (`id`, `name`, `status`, `due_date`);
  - `assignees`: principales que pueden asignarse en este contexto de formulario. Elemento: `id`, `name`, `type` (`user` o `group`); para `user`, además `login`. Los grupos se incluyen si Redmine tiene activada la asignación de incidencias a grupos;
  - `custom_fields`: solo campos que el usuario actual puede editar en el formulario, considerando proyecto/tracker, visibilidad, solo lectura del workflow. Elemento: `id`, `name`, `field_format`, `required` (campo obligatorio o obligatorio por workflow), `readonly` (siempre `false` en esta lista), `multiple`, `default_value`, `possible_values`, `trackers`. Contexto del formulario — incidencia de `issue_id` o borrador de creación considerando `tracker_id`;
  - `possible_values` — array de objetos `{ "label": "...", "value": "..." }`. Para listas sin etiquetas separadas, `label` coincide con `value`. Para user/version/enumeración, `label` es el nombre mostrado, `value` es el identificador;
  - `statuses`: estados permitidos por el workflow para el usuario actual. Con `issue_id` — transiciones para esta incidencia visible. Sin `issue_id` — estados iniciales para creación (considerando `tracker_id` si está definido);
  - `editable_fields`: nombres de atributos que este contrato MCP acepta en create/update que el usuario actual puede establecer en el formulario, más ids de campos personalizados editables como cadenas. No incluye `notes`, `private_notes`, `watcher_user_ids` y otros campos del formulario web ausentes de las herramientas de escritura MCP;
  - `required_fields`: nombres de campos obligatorios en este formulario para el usuario actual, en la misma forma de nombre que `editable_fields`.
- `tracker_id` inexistente, tracker no permitido para el usuario, o `issue_id` fuera del proyecto / no visible — error de parámetro.

### `add_issue_note`

- Añade un comentario a una incidencia existente visible sin cambiar atributos de la incidencia.
- Entrada: `issue_id` (obligatorio), `notes` (obligatorio), opcionalmente `private_notes`, `uploads` e `idempotency_key`.
- Permiso: el usuario puede añadir comentarios a esta incidencia. `private_notes=true` requiere permiso para hacer comentarios privados; de lo contrario — denegado, no se crea comentario. Adjuntos en la misma llamada están permitidos si el usuario puede añadir adjuntos a la incidencia.
- No acepta campos de incidencia ni listas de observadores.
- Salida: `issue_id`, `journal_id`, `notes`, `private_notes`; con `uploads` — `added_attachments` (solo archivos de esta llamada).
- No disponible en modo de solo lectura.

### `update_issue_note` / `set_issue_note_private`

- Trabajan solo con una entrada del diario que el usuario actual **ve** (comentarios privados de otro usuario sin permiso para ver notas privadas son inaccesibles).
- La entrada debe ser editable por el usuario actual (permiso para editar comentarios o comentarios propios).
- `update_issue_note.notes` puede ser una cadena vacía (limpiar texto de una entrada existente). Un nuevo comentario mediante `add_issue_note` no puede estar vacío.
- Cambiar la privacidad (`private_notes` / `is_private`) requiere permiso separado para hacer comentarios privados; de lo contrario denegado, el texto no se cambia parcialmente.
- Registra quién editó la entrada del diario.
- No disponible en modo de solo lectura.

### `validate_issue_create` / `validate_issue_update`

- Herramientas de solo lectura separadas, no un parámetro `validate_only` en herramientas de escritura. Disponibles en modo de solo lectura.
- `validate_issue_create`: mismos campos que `create_issue`, sin `idempotency_key`. `project` y `subject` son obligatorios. Permiso `add_issues`.
- `validate_issue_update`: dry-run solo para **atributos de incidencia** (como `update_issue`, sin `uploads`). `issue_id` es obligatorio. La incidencia debe ser editable por el usuario actual. Antes de la validación, se crea un contexto de diario de usuario sin escritura DB (como en una actualización real).
- Comportamiento: aplicar atributos a la incidencia sin guardar. Los datos de Redmine no se modifican.
- Los atributos siguen pasando por las mismas reglas de escritura que el formulario web de Redmine. Si el cliente **pasó explícitamente** un valor y Redmine no lo aplicó, eso es un error MCP, no éxito.
- Un campo explícito que no está entre los editables en la incidencia (desactivado / solo lectura del workflow / fechas derivadas, etc.) va en `rejected_fields`. Para `tracker_id`, `status_id`, `assigned_to_id`, `is_private`, `parent_issue_id` y `custom_fields`, además se verifica que el valor solicitado se aplicó realmente.
- La misma regla se aplica a `create_issue`, `update_issue` y `copy_issue`: sin escritura si un valor solicitado explícitamente no se aplicó.
- Éxito: `{ "valid": true, "errors": [] }`.
- Fallo: `{ "valid": false, "errors": ["..."] }`. Si algunos campos explícitos no se aplicaron — también `rejected_fields` (nombres de campos, por ejemplo `["tracker_id"]`) y, para errores típicos — `missing_required_fields` / `hint` en la misma forma que create/update.
- También detecta: tracker no disponible para el usuario actual; valor de campo personalizado inválido o no disponible; transición de estado prohibida por el workflow; asignado no disponible para asignación.

### `list_issues` — filtros extendidos

- Los filtros planos existentes (`project`, `status_id`, `tracker_id`, `assigned_to_id` / `assignee_ref`, `priority_id`, `fixed_version_id`, `sort`, `fields`) se conservan.
- `filters` opcional: array de objetos `{ "field": "...", "operator": "...", "values": ["..."] }`. `values` es un array de cadenas; un array vacío está permitido para operadores sin valores.
- `field` permitido: `status_id`, `tracker_id`, `assigned_to_id`, `priority_id`, `fixed_version_id`, `category_id`, `subject`, `due_date`, `start_date`, `created_on`, `updated_on`, `estimated_hours`, `done_ratio`, `author_id`, `watcher_id`, y `cf_<id>` para campos personalizados de incidencia.
- Los operadores son operadores de consulta Redmine estándar, incluidos `=`, `!`, `>=`, `<=`, `><`, `~`, `!~`, `o`, `c`, `*`, `!*`. El operador debe ser válido para el tipo de campo; de lo contrario — error de parámetro.
- `field` desconocido u `operator` inválido — error de parámetro, la consulta no se ejecuta.
- Filtros planos y `filters` se combinan con AND.
- Los filtros se aplican solo a incidencias visibles para el usuario actual.

### `run_issue_query`

- Entrada: `query_id` (obligatorio, de `list_queries`); opcionalmente `project`, `fields`, `limit`/`offset`.
- Ejecuta una consulta de incidencias guardada visible para el usuario actual. El formato de respuesta es el mismo envoltorio de lista que `list_issues`.
- Si la consulta está limitada a un proyecto, los resultados se limitan a ese proyecto (y reglas de visibilidad de la consulta). `project` opcional para una consulta de proyecto debe coincidir con el proyecto de la consulta; de lo contrario — error de parámetro.
- Si la consulta es global, `project` opcional restringe la selección a ese proyecto visible.
- `query_id` invisible o inexistente — error.
- `list_queries` no ejecuta la consulta; usar `run_issue_query` para la ejecución.

### `list_project_activities`

- Entrada: `project` (obligatorio); opcionalmente `from`, `to` (fechas `YYYY-MM-DD`), `author_id`, `event_types` (array de cadenas), `limit`/`offset`.
- Ventana por defecto — últimos 7 días (`to` = hoy, `from` = hoy menos 6 días). Longitud máxima de ventana — 90 días; si se excede — error de parámetro.
- Eventos del feed de actividad del proyecto: tipo, hora, autor (`id`/`name`), `title`, `description`, `url`. Orden — eventos más recientes primero; para tiempo igual — `id` mayor primero.
- Envoltorio como otros `list_*`.
- `event_types` limita tipos de evento. Un tipo no disponible para el usuario o desactivado en el proyecto se excluye de la selección (sin error).
- `author_id` inexistente — lista vacía, no un error.

### `summarize_project_status`

Campos existentes conservados: `project_id`, `project_name`, `analysis_period_days`, `recent_activity` (`created_count`, `updated_count`), `totals` (`issues_count`, `open_count`, `closed_count`), `status_breakdown`, `priority_breakdown`, `assignee_breakdown`.

La ventana `days` (por defecto 30, rango 1–365) sigue afectando `recent_activity` y las métricas de período listadas abajo. Un valor fuera del rango es rechazado por el esquema. `totals` y desgloses se calculan sobre todas las incidencias visibles del proyecto sin filtro de fecha, mediante agregación DB, sin cargar todas las incidencias en memoria. Los subproyectos no se incluyen.

Campos adicionales:

- `overdue_count` — número de incidencias abiertas visibles con `due_date` estrictamente anterior al día de hoy del usuario.
- `unassigned_count` — número de incidencias abiertas visibles sin asignado.
- `stale_issues_count` — número de incidencias abiertas visibles con `updated_on` anterior al inicio de la ventana `days`.
- `issues_closed_during_period` — número de incidencias visibles con `closed_on` dentro de la ventana `days`.
- `estimated_hours` — suma de estimaciones de incidencias visibles del proyecto (`null` si ninguna tiene estimación, de lo contrario un número incluyendo 0).
- `spent_hours` — suma de tiempo registrado en incidencias visibles del proyecto (0 si no hay entradas). Requiere `view_time_entries` en el proyecto; sin permiso el campo es `null`.
- `average_resolution_hours` — media de `(closed_on - created_on)` en horas para incidencias cerradas en la ventana `days`; `null` si no hay tales incidencias.
- `estimation_accuracy` — para incidencias cerradas en la ventana que tienen estimación y tiempo no cero/registrado: `{ "issues_count", "total_estimated", "total_spent" }`. Si no hay incidencias coincidentes — `{ "issues_count": 0, "total_estimated": 0, "total_spent": 0 }`. Requiere `view_time_entries` en el proyecto; sin permiso el campo es `null`.
- `reopened_count` — número de incidencias visibles cuyo estado en el diario cambió de cerrado a abierto dentro de la ventana `days`. Cada incidencia se cuenta máximo una vez.

La herramienta devuelve hechos, no un «análisis de salud del proyecto» textual.

### `get_version`

- Entrada: `version_id` (obligatorio); opcionalmente `project`. Si `project` está definido, la versión es accesible cuando está en las versiones compartidas de ese proyecto visible (incluso si el proyecto origen de la versión no es visible para el usuario). Sin `project`, la versión debe ser visible en su proyecto origen.
- Salida: campos como un elemento de `list_versions` (`id`, `name`, `description`, `status`, `due_date`, `sharing`, `wiki_page_title`, `project`, `created_on`, `updated_on`) más agregados: `issues_count`, `open_issues_count`, `closed_issues_count`, `estimated_hours`, `spent_hours`, `completed_percent`.
- Los agregados se calculan solo sobre incidencias de la versión visibles para el usuario actual.
- No se devuelve la lista de incidencias.
- `spent_hours` requiere `view_time_entries` en el proyecto de la versión; sin permiso — `null`. Suma solo sobre incidencias visibles de la versión y solo entradas de tiempo que el usuario actual puede ver (incluido `time_entries_visibility=own`).

### Foros

- El módulo de foros del proyecto debe estar activado; de lo contrario error «Boards module is not enabled for this project» (análogo wiki).
- Permiso `view_messages`. Sin operaciones de escritura en foros.
- `list_boards`: `project` obligatorio; paginación. Elemento: `id`, `name`, `description`, `parent_id` (`null` para foro raíz), `topics_count`, `messages_count`.
- `list_board_topics`: `board_id` obligatorio; paginación. Solo mensajes raíz (sin padre). Elemento: `id`, `subject`, `author`, `created_on`, `updated_on`, `replies_count`, `board_id`.
- `get_board_message`: `message_id` obligatorio. Salida: `id`, `subject`, `content`, `author`, `created_on`, `updated_on`, `board` (`id`/`name`), `project` (`id`/`name`/`identifier`), `parent_id`, `replies` — lista breve de respuestas (`id`, `subject`, `author`, `created_on`) sin texto completo de cada respuesta, con `replies_limit`/`replies_offset` (por defecto y máximo 100) y `replies_pagination`.
- Foro/mensaje invisible o foro de otro proyecto — error «not found».

### `list_users`

- Con `project`: miembros **usuarios** activos del proyecto (permiso `view_members`). La pertenencia a grupo en el proyecto no aparece como grupo; usuarios de un grupo solo si son miembros ellos mismos. Sin `project` — solo administrador.
- Elemento: `id`, `login`, `firstname`, `lastname`, `mail`. No incluye `created_on` (ese campo está en `list_all_users`).
- `query` opcional: subcadena sin distinguir mayúsculas en `login`, `firstname` y `lastname`.
- `login` opcional se conserva (solo subcadena de login) por compatibilidad. Si `query` y `login` están definidos, ambas condiciones se aplican (AND).

### `list_groups`

- Lista paginada de grupos asignables (`id`, `name`), **visibles** para el usuario actual, para seleccionar `group_id` en `add_project_member`.
- `query` opcional: subcadena sin distinguir mayúsculas en el nombre del grupo; `%` y `_` se coinciden literalmente.
- Permiso: administrador o `manage_members` en al menos un proyecto visible.
- No devuelve pertenencia a grupos ni memberships.

### `list_project_member_candidates`

- Candidatos para añadir al proyecto: usuarios y grupos activos visibles que aún no están en el proyecto.
- Entrada: `project` (obligatorio); opcionalmente `query` (subcadena, como en el selector de miembros de Redmine).
- Envoltorio de lista de salida: `id`, `name`, `type` (`user` o `group`); para usuario, además `login`.
- Permiso `manage_members` en el proyecto.
- `add_project_member`: `user_id` solo para usuario, `group_id` solo para grupo. ID de tipo incorrecto — error de parámetro. Antes de añadir, tomar IDs de esta herramienta (o de `list_users` / `list_groups` si el candidato ya se conoce).

### `list_roles`

- Solo roles que el usuario actual puede gestionar en el proyecto especificado.
- Entrada: `project` (obligatorio).
- Permiso `manage_members` en el proyecto.
- Para administrador, el conjunto coincide con roles de proyecto asignables (sin Non member / Anonymous).

## Casos límite

- Proyecto o incidencia inexistente/inaccesible — `{ "error": "..." }`.
- Modo de solo lectura — `{ "error": "MCP is in read-only mode..." }` para herramientas de escritura **antes** de llamar al handler, incluidas herramientas Extension API; validate/form options/list/get siguen disponibles.
- Resultado de lista/búsqueda vacío — `{ "ok": true, "data": { "items": [] }, "meta": { ... } }`.
- Lista/búsqueda con paginación siempre devuelven `data.items` y `meta` (`total_count`, `limit`, `offset`, `has_more`, `next_offset`). Límite por defecto 25, máximo 100.
- Todas las herramientas `list_*` (incluidas referencias: trackers, estados, roles, consultas, foros, temas de foro, etc.) usan el mismo envoltorio. `get_issue_form_options`, `get_project`, `get_version`, `get_board_message`, `summarize_project_status` y herramientas validate — objetos únicos, no envoltorio de lista.
- `download_attachment`: adjunto inexistente e inaccesible — mismo error «not found»; archivo ilegible en disco — error; tamaño en disco o tras lectura superior a 10 MiB — `FILE_TOO_LARGE` (el límite no se evita con un `filesize` DB menor). Misma regla indistinguible «ausente / sin acceso» — para `get_attachment`.
- `list_project_activities`: ventana mayor que 90 días — error de parámetro; `from` después de `to` — error de parámetro.
- `run_issue_query`: consulta invisible — tratada como inexistente.
- `get_issue_form_options` con `issue_id` para una incidencia de otro proyecto — error de parámetro.
- `get_issue_form_options` con `issue_id` y `tracker_id` distinto del tracker de esa incidencia — error de parámetro.
- Las herramientas validate no crean una incidencia, no actualizan una incidencia, no crean entradas del diario y no consumen `idempotency_key`.
- Las escrituras mediante MCP pasan por los modelos de Redmine. Se ejecutan callbacks de modelo; no se llaman hooks del controlador de la interfaz web.

## Manejo de errores

- Permiso faltante — herramienta no visible en `tools/list` o «Permission denied».
- Errores de validación del modelo — `{ "error": "<messages>" }` (para create/update de incidencia y herramientas validate además `missing_required_fields` como nombres de campos desde símbolos de error del modelo, sin parsear texto de traducción, y `hint`).
- Módulo wiki/foros desactivado — mensaje de error separado, no «not found».
- El código de error canónico en el envoltorio se establece explícitamente por el handler; el código no se deriva del texto del mensaje y no depende del idioma del usuario.

## Escenarios de prueba

1. `list_projects` / `list_issues` devuelven envoltorio `data.items` + `meta` con paginación.
2. `get_issue` sin `include_*` no devuelve diarios/adjuntos; con `include_journals` — diarios con paginación.
3. `search_issues` por texto encuentra incidencias; `search_all` incluye wiki al buscar múltiples tipos.
4. `create_issue` / `update_issue` con campos válidos tienen éxito; sin permiso o en solo lectura — error.
4a. `create_issue` sin `start_date` con configuración de fecha de inicio activada establece la fecha de hoy; `start_date` explícito o `null` no se sobrescribe por esa configuración.
5. `delete_issue` sin `confirm_delete` devuelve `INVALID_STATE` e impacto; con confirmación elimina.
6. `create_time_entry` requiere `hours` y `project` o `issue_id`; `import_time_entries` acepta un lote.
7. `list_wiki_pages` / `get_wiki_page` / `create_wiki_page` funcionan con módulo Wiki activado.
8. `upload_file` requiere `filename` y `content_base64`; `delete_file` para adjunto de incidencia requiere confirmación.
9. Usuario sin `use_mcp` no pasa autenticación MCP; sin permiso de herramienta no la ve en `tools/list`.
10. Reintento de `create_issue` con el mismo `idempotency_key` y mismos argumentos no crea duplicado; misma clave con subject distinto — `CONFLICT`.
11. `download_attachment` para adjunto de incidencia visible devuelve `content_base64` con `size` del contenido real; para archivo > 10 MiB en disco (incluso con metadatos pequeños) — `FILE_TOO_LARGE`; adjunto inexistente e inaccesible son indistinguibles.
12. `get_project` por identificador devuelve descripción, subproyectos y `last_activity_date`; proyecto inaccesible — error.
13. `get_issue_form_options` para proyecto devuelve trackers/estados/prioridades/categorías/versiones/asignados/campos personalizados y listas `editable_fields` / `required_fields`; `trackers` — solo los disponibles para el usuario actual; con `issue_id` los estados reflejan transiciones permitidas para esa incidencia; `issue_id` + `tracker_id` distinto — error; `possible_values` — objetos `label`/`value`.
14. `validate_issue_create` con tracker o estado inválido devuelve `valid: false` y `rejected_fields`, no crea incidencia; en modo de solo lectura la llamada tiene éxito.
15. `list_issues` con `filters` (`due_date` `<=` fecha, `priority_id` `!`) devuelve solo incidencias visibles coincidentes; `field` desconocido — error.
16. `run_issue_query` con `query_id` visible devuelve las mismas incidencias que la consulta guardada en la UI; consulta invisible — error.
17. `list_project_activities` para 3 días devuelve eventos del proyecto con paginación; ventana de 91 días — error.
18. `summarize_project_status` incluye `overdue_count`, `unassigned_count`, `stale_issues_count`, `issues_closed_during_period` y `reopened_count`.
19. `get_version` devuelve agregados `open_issues_count` / `completed_percent` sin lista de incidencias.
20. `list_boards` / `list_board_topics` / `get_board_message` funcionan con módulo Boards activado; cuando está desactivado — error de módulo.
21. `list_users` con `project` y `query` por nombre encuentra miembro sin conocer login.
22. `get_issue_form_options` devuelve asignados con `type` user/group y solo campos personalizados editables con `required`/`readonly`.
23. `create_issue` / `update_issue` / `copy_issue` / `validate_issue_create` con valor pasado explícitamente que Redmine no aplica (incluidos campos base desactivados/solo lectura, incluido `description` al crear) devuelven error y no guardan cambio parcial.
24. `validate_issue_update` no acepta notas; comentario creado por `add_issue_note`. `add_issue_note` con `add_issue_notes` tiene éxito sin `edit_issues`; `private_notes` sin `set_notes_private` — denegado. `update_issue` solo con `uploads` tiene éxito con permiso para añadir adjuntos sin `edit_issues`.
25. `list_groups` devuelve grupos asignables para usuario con `manage_members`.
26. `update_issue` con `assigned_to_id`/`category_id`/`fixed_version_id`/`parent_issue_id`/`start_date`/`due_date`/`estimated_hours` = `null` limpia el campo si es editable.
27. `update_issue_note` / `set_issue_note_private` no cambian comentario privado de otro usuario si el usuario carece de permiso para ver comentarios privados.
28. Usuario con permiso para editar comentarios pero no para hacerlos privados puede cambiar texto de comentario público y no puede cambiar flag de privacidad.
29. `add_issue_note` con `uploads` crea comentario y adjunto en una llamada; reintento con el mismo `idempotency_key` no los duplica.
30. `update_issue` con `uploads` e `idempotency_key`: reintento con mismo payload no duplica adjunto; archivo distinto con misma clave — `CONFLICT`. Base64 corrupto — error de parámetro.
31. `get_issue` no devuelve campos personalizados ocultos, detalles de diario invisibles ni relaciones con incidencias invisibles. `get_version` agrega solo sobre incidencias visibles.
32. `copy_issue` sin permiso para copiar en proyecto origen — denegado, incluso con `add_issues` en destino.
33. `add_project_member` / `update_project_member` con rol que el usuario no puede gestionar — denegado sin asignación parcial.
34. `create_version` / `update_version` con `sharing` no permitido para el usuario — denegado. `delete_version` para versión ocupada — denegado sin eliminación.
35. Autor de entrada de tiempo con `edit_own_time_entries` puede actualizar su propia entrada mediante `update_time_entry`.
36. `search_all` disponible para usuario con permiso wiki sin `view_issues`, si la búsqueda incluye wiki.
37. `list_project_member_candidates` devuelve usuarios y grupos que aún no están en el proyecto; `add_project_member` con `user_id` de grupo — error.
38. `list_roles` para proyecto devuelve solo roles que el usuario puede gestionar; sin `project` — error de esquema. No incluye Non member y Anonymous integrados.
39. Reintento de `copy_issue` / `create_time_entry` con el mismo `idempotency_key` no crea duplicado; payload distinto con misma clave — `CONFLICT`.
40. `search_issues` y búsqueda de usuario/grupo para `%` o `_` coinciden con esos caracteres literalmente, no como wildcards.
41. `get_version.spent_hours` con `time_entries_visibility=own` cuenta solo entradas de tiempo propias.
42. `search_issues` con `scope=subprojects` sin `project` — error; con `project` encuentra incidencias en descendientes.
43. `list_project_activities` devuelve eventos más recientes antes que los más antiguos.
44. Impacto de `delete_issue` no incluye diarios ocultos, relaciones y entradas de tiempo de otros; subtareas ocultas aún requieren `confirm_delete_with_children`.
45. `get_project` no devuelve padre invisible para el usuario actual.
46. `update_version` con `due_date`/`wiki_page_title` = `null` limpia el campo.
47. `update_issue_category` con `assigned_to_id` = `null` limpia asignado por defecto.
48. El esquema acepta `hours` de 0 y valores superiores a 24; solo la validación de Redmine rechaza.
49. `update_issue_note` con `notes` vacío limpia texto de comentario existente.
50. `list_users` con `project` devuelve solo usuarios, incluso si el proyecto tiene pertenencia a grupo.
51. Versión histórica de página wiki sin `view_wiki_edits` es inaccesible; página protegida no puede cambiarse sin permiso para proteger wiki.
52. `copy_issue` sin permiso para añadir observadores no copia observadores; `link_copied_issue` / `copy_attachments_on_issue_copy` = `no` prohíben enlace y adjuntos; padre en el mismo proyecto se conserva.
53. Herramienta de escritura de extensión en modo de solo lectura no invoca el handler.
54. `delete_file` visible en `tools/list` para usuario que puede eliminar adjuntos de incidencia, sin `manage_files`.
55. `add_issue_watcher` / `remove_issue_watcher` aceptan principal de grupo.
56. `get_version` con `project` devuelve versión compartida que `list_versions` para ese proyecto devolvió.
57. `get_issue` / `get_wiki_page` / `get_board_message` limitan listas anidadas con `limit`/`offset` y devuelven `*_pagination`; sin include la paginación es `null`.
58. Las respuestas reales de herramientas, incluidos campos nullable, coinciden con el `outputSchema` publicado.
59. `get_issue` con `include_journals`: diario con solo detalle de campo personalizado oculto no está en la lista y no se cuenta en `journal_pagination.total_count`.
60. Diario oculto entre dos visibles no crea hueco de página: con `journal_limit=2` se devuelven dos entradas visibles, `total_count` iguala el conteo visible.
61. Comentario privado de otro usuario no se devuelve en `get_issue` sin permiso `view_private_notes`.
62. `get_private_notes` devuelve una página por `limit`/`offset` sin cargar historial completo de la incidencia.
63. `get_issue` con diarios `attr`, `cf` y `relation` simultáneamente no falla y devuelve solo entradas visibles.
64. Diario con detalle de campo personalizado oculto y notas de espacios, tabulaciones o saltos de línea no se incluye en `get_issue`.
65. `get_private_notes` no devuelve comentario compuesto solo de espacios, tabulaciones o saltos de línea.
