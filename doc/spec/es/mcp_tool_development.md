# Requisitos de desarrollo de herramientas Redmine MCP

[Deutsch](../de/mcp_tool_development.md) | [English](../en/mcp_tool_development.md) | [Español](mcp_tool_development.md) | [Français](../fr/mcp_tool_development.md) | [Italiano](../it/mcp_tool_development.md) | [日本語](../ja/mcp_tool_development.md) | [한국어](../ko/mcp_tool_development.md) | [Polski](../pl/mcp_tool_development.md) | [Português (Brasil)](../pt-BR/mcp_tool_development.md) | [Русский](../ru/mcp_tool_development.md) | [中文](../zh/mcp_tool_development.md)

**Estado:** guía del desarrollador (dev-guide), no una SPEC comportamental del plugin  
**Versión:** 1.6  
**Fecha:** 2026-08-20  
**Aplicabilidad:** todas las nuevas herramientas Redmine MCP y cambios sustanciales en herramientas existentes  
**Versión base de MCP:** Protocol Revision `2025-11-25`

Los contratos comportamentales de las herramientas del núcleo están en `03-core-tools.md` y SPECs relacionadas. Este documento define reglas para diseñar e implementar herramientas.

---

## 1. Objetivo de este documento

Este documento establece requisitos unificados para diseñar, implementar, describir, probar y publicar herramientas MCP para Redmine. Los patrones de implementación arquitectónica se recogen en el apéndice A y no se mezclan con los requisitos obligatorios del texto principal.

El objetivo de este estándar es que las herramientas sean:

- inequívocas para la selección por modelos de lenguaje;
- seguras cuando se invocan automáticamente;
- predecibles para los clientes MCP;
- estrictamente validadas;
- fáciles de mantener y compatibles con versiones anteriores;
- resilientes a llamadas repetidas, errores del modelo y argumentos parcialmente rellenados.

Los requisitos se formulan teniendo en cuenta una auditoría del Redmine MCP actual. En el momento de preparar este documento, el servidor publica 46 herramientas; el contrato reveló parámetros sin `type`, listas de cadenas de valores permitidos en lugar de `enum`, herramientas universales `manage_*` y ausencia de `outputSchema`.

---

## 2. Terminología de obligatoriedad

En este documento se usan los siguientes niveles:

- **MUST / DEBE** — requisito obligatorio. La violación bloquea la fusión.
- **MUST NOT / PROHIBIDO** — prohibición obligatoria.
- **SHOULD / DEBERÍA** — requisito por defecto; la desviación debe justificarse en la solicitud de fusión.
- **MAY / PUEDE** — opción aceptable.

Los patrones arquitectónicos e de implementación que no son obligatorios para cada herramienta se recogen en el **apéndice A**. No bloquean la fusión si no se adoptan conscientemente para una herramienta concreta.

---

## 3. Principios básicos de diseño

### 3.1. Una herramienta — una acción clara

Una herramienta DEBE representar una intención atómica del usuario.

Bueno:

- `redmine_get_issue`
- `redmine_create_issue`
- `redmine_update_issue`
- `redmine_add_issue_note`
- `redmine_delete_issue`
- `redmine_list_issue_relations`
- `redmine_create_issue_relation`
- `redmine_delete_issue_relation`

Malo:

- `redmine_manage_issue`
- `redmine_manage_relation`
- `redmine_execute_action`

Las herramientas con un parámetro como `action: create | update | delete | list` están PROHIBIDAS si las operaciones:

- requieren argumentos obligatorios diferentes;
- tienen distintos niveles de riesgo;
- deben tener anotaciones MCP diferentes;
- devuelven estructuras de datos diferentes;
- requieren permisos Redmine diferentes.

Solo se permite una excepción para una operación semánticamente homogénea donde todas las variantes tienen el mismo riesgo y un único contrato. La excepción debe justificarse explícitamente.

### 3.2. Lectura, adición, actualización y eliminación están separadas

En una herramienta está PROHIBIDO combinar:

- operaciones de solo lectura y de escritura;
- operaciones de adición y de eliminación;
- operaciones de usuario habitual y administrativas;
- operaciones locales de Redmine y envío de datos al exterior.

Por ejemplo, `list/create/delete relation` deben ser tres herramientas separadas.

### 3.3. El contrato importa más que la comodidad de implementación del servidor

No publique directamente la estructura de un método interno Ruby/Python/REST solo porque es más fácil implementar el handler así.

El contrato MCP se diseña para el modelo y el cliente; un adaptador dentro del servidor lo convierte al formato de la API de Redmine.

Los valores técnicos internos de un plugin o Redmine DEBEN normalizarse si no forman parte de un contrato externo significativo.

No publique sin necesidad:

- nombres de clases Ruby/Rails y tipos STI;
- nombres internos de enum si MCP ya usa otro valor en la entrada;
- fechas dependientes del locale;
- representaciones REST del mismo campo si MCP ya define un formato canónico;
- nombres técnicos cuando MCP ya usa un valor normalizado.

Ejemplo: filtro de entrada `type` — `contact` / `company`; en la respuesta también `contact` / `company`, no `Clientdesk::Contact` / `Clientdesk::Company`. Si un serializador devuelve una clase STI o una fecha localizada, el adaptador MCP DEBE llevar el valor al esquema publicado.

### 3.4. El servidor no confía en el modelo

Todos los argumentos se consideran no confiables. El servidor DEBE volver a comprobar:

- tipos;
- rangos;
- interdependencias de campos;
- derechos del usuario actual;
- pertenencia del objeto a un proyecto;
- disponibilidad de un valor en un workflow concreto;
- restricciones de Redmine;
- si la operación está permitida en el estado actual del objeto.

JSON Schema, descripciones, anotaciones y confirmaciones del cliente no reemplazan la validación del lado del servidor.

---

## 4. Nomenclatura de herramientas

### 4.1. Formato del nombre

Todos los nombres de herramientas publicados DEBEN empezar por `redmine_`.

Para las herramientas del núcleo del plugin `redmine_mcp` se usa el prefijo corto `redmine_`:

```text
redmine_<verb>_<entity>
```

Para herramientas de plugins de terceros, el nombre completo DEBE empezar por `redmine_`:

- `redmine_<plugin_id>_<verb>_<entity>`.

Requisitos:

- solo `lower_snake_case`;
- el prefijo `redmine_` es obligatorio para todas las herramientas, incluidas extensiones de plugins de terceros;
- el nombre es único dentro del servidor;
- límite interno — no más de 64 caracteres;
- el nombre no cambia sin un procedimiento de deprecación.

Ejemplos:

```text
redmine_get_issue
redmine_list_projects
redmine_search_issues
redmine_create_time_entry
redmine_delete_wiki_page
redmine_advanced_search_semantic_search_issues
```

### 4.2. Verbos permitidos

Verbos preferidos:

| Verbo | Propósito |
|---|---|
| `get` | recuperar un objeto por identificador exacto |
| `list` | recuperar una colección mediante filtros estructurados |
| `search` | realizar búsqueda de texto o texto completo |
| `create` | crear un objeto |
| `update` | modificar un objeto existente |
| `set` | establecer un campo o flag concreto a un valor dado |
| `delete` | eliminar un objeto |
| `add` | añadir una relación o miembro a un objeto existente |
| `remove` | eliminar una relación sin borrar el objeto principal |
| `copy` | crear una copia |
| `upload` | subir un archivo |
| `download` | recuperar el contenido de un archivo |
| `send` | enviar un mensaje o datos a un destinatario externo |
| `summarize` | construir un informe agregado en el servidor |

No use verbos vagos (`manage`, `process`, `handle`, `execute`, `do`) — véase §3.1.

El verbo DEBE coincidir con la semántica real de la operación. Si una herramienta alterna un flag booleano (parámetro como `enabled: true | false`), DEBERÍA nombrarse con `set`, no con un verbo que implica solo un valor.

Malo:

```text
redmine_advanced_search_enable_semantic_index
```

`enable` implica solo `enabled = true`, aunque el parámetro también permite `false`. El nombre no coincide con la acción real.

Bueno:

```text
redmine_advanced_search_set_semantic_index_enabled
```

El nombre `set_*` refleja con honestidad que la operación establece un flag al valor pasado.

### 4.3. Nombres de parámetros identificadores

Un nombre de parámetro DEBE coincidir con su tipo real:

- `issue_id` — solo ID entero;
- `project_id` — solo ID entero;
- `project_identifier` — identificador de cadena de Redmine;
- `project` — cadena que deliberadamente permite ambas representaciones y se documenta como referencia.

Un parámetro llamado `*_id` no puede aceptar un identificador de cadena ni el valor `"me"`.

Los IDs numéricos DEBEN tener `minimum: 1` y una `description` significativa. Formulaciones como `"Issue id"` sin `minimum` están PROHIBIDAS.

Malo:

```json
"issue_id": {
  "type": "integer",
  "description": "Issue id"
}
```

Bueno:

```json
"issue_id": {
  "type": "integer",
  "minimum": 1,
  "description": "ID numérico de incidencia.",
  "examples": [1]
}
```

La opción unificada recomendada para proyecto es el parámetro `project`, que acepta ID numérica (como cadena) o identificador de cadena:

```json
"project": {
  "type": "string",
  "minLength": 1,
  "description": "ID de proyecto como cadena o identificador de proyecto. Llame a redmine_list_projects cuando el valor sea desconocido.",
  "examples": ["1", "ecookbook"]
}
```

El array `examples` (§6.15) muestra al modelo ambas formas de valor permitidas y reduce la probabilidad de entrada incorrecta.

### 4.4. Bloqueo optimista: `expected_updated_at`

Un parámetro que pasa una marca de tiempo de objeto conocida previamente para rechazar un cambio obsoleto DEBE llamarse `expected_updated_at` en todas las herramientas del núcleo y extensiones.

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Rechazar la operación si el objeto cambió después de esta marca de tiempo."
}
```

El nombre `updated_at` para este significado está PROHIBIDO: parece «nueva hora de modificación», aunque en realidad es un valor para bloqueo optimista.

Malo (checklist y cualquier extensión):

```json
"updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "updated_at actual del elemento de checklist."
}
```

Bueno:

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Rechazar la operación si el objeto cambió después de esta marca de tiempo."
}
```

Un campo de respuesta que reporta la hora real de modificación del objeto PUEDE seguir llamándose `updated_at` / `updated_on` — la confusión solo surge para el parámetro de entrada de bloqueo.

El comportamiento normativo en conflicto está en el apéndice A.2.

---

## 5. `title` y `description`

### 5.1. `title`

`title` DEBE ser un nombre corto legible para humanos, no una copia del nombre técnico.

```json
{
  "name": "redmine_get_issue",
  "title": "Get Redmine issue"
}
```

### 5.2. Descripción de la herramienta

`description` DEBE responder brevemente a preguntas clave:

1. ¿Qué hace la herramienta y qué objeto se lee o modifica?
2. ¿Qué no se incluye por defecto y cómo solicitarlo?
3. ¿Hay efectos secundarios significativos?
4. ¿Qué herramienta previa invocar si el ID o un valor permitido es desconocido?

La descripción DEBE ser breve y fácil de leer. Está PROHIBIDO convertirla en un párrafo largo de media página que liste todos los campos y todas las opciones include: una descripción sobrecargada es más difícil de leer para el modelo que una corta y estructurada.

DEBERÍA escribir varias líneas cortas o una lista, no texto continuo. Los valores por defecto y cómo cambiarlos se muestran de forma compacta.

Ejemplo bueno:

```text
Devuelve una incidencia.

Por defecto:
- sin diarios
- sin adjuntos

Use include_* para solicitarlos.
Use redmine_search_issues cuando issue_id sea desconocido.
```

Ejemplo malo — demasiado corto, no explica el resultado ni el comportamiento por defecto:

```text
Gets issue.
```

Ejemplo malo — párrafo sobrecargado que lista todos los campos:

```text
Devuelve una incidencia Redmine por issue_id numérico con campos de detalle del núcleo incluyendo
asunto, descripción, estado, prioridad, tracker, proyecto, asignado, autor,
fechas, ratio hecho, campos personalizados y opcionalmente diarios, adjuntos,
relaciones, observadores, incidencias hijas y estados de workflow permitidos según los
parámetros include pasados a la llamada ...
```

### 5.2.1. Referencias a otras herramientas

Cuando la descripción, la descripción de un parámetro o las instrucciones del servidor referencian otra herramienta, DEBE usarse el nombre registrado completo de `tools/list`, no un `name` corto sin prefijo.

Malo:

```text
Use list_projects when project is unknown.
Use semantic_search_issues before update.
```

Bueno:

```text
Use redmine_list_projects when project is unknown.
Use redmine_advanced_search_semantic_search_issues before update.
```

Los nombres cortos son ambiguos entre plugins y obligan al modelo a adivinar el prefijo. Esto es especialmente importante para extensiones: `semantic_search_issues` sin el prefijo `redmine_advanced_search_` se confunde fácilmente con una herramienta del núcleo inexistente.

### 5.2.2. Descripción del resultado devuelto

La descripción DEBE explicar brevemente el resultado de la herramienta para que el modelo entienda si una llamada basta o se necesita otra herramienta.

La descripción del resultado debe indicar:

- si se devuelve un objeto, colección, agregado, confirmación de cambio o referencia a recurso;
- qué datos relacionados se incluyen por defecto;
- qué datos grandes o sensibles no se incluyen sin un parámetro explícito;
- si existe paginación y cuál es el límite estándar;
- si una herramienta de escritura devuelve el objeto actualizado completo o solo identificador, URL y hora de modificación;
- si es posible un éxito parcial en una operación masiva.

Ejemplo de lectura:

```text
Devuelve una incidencia con campos del núcleo y personalizados.

No incluido por defecto: diarios, adjuntos, relaciones, observadores, incidencias hijas.
Solicítelos con include_*.
```

Ejemplo de lista:

```text
Devuelve una lista paginada de incidencias que coinciden con los filtros estructurados suministrados.
Cada elemento contiene solo campos resumidos; use redmine_get_issue para detalles completos.
El resultado incluye total_count, limit, offset y has_more.
```

Ejemplo de escritura:

```text
Crea una incidencia y devuelve su ID numérico, URL canónica y marca de tiempo de creación.
La respuesta no incluye diarios ni adjuntos.
```

Sobre la relación entre descripción y `outputSchema` — véase §7.1 y §7.1.1. Si una lista ya devuelve un campo, la descripción NO DEBE enviar el modelo a `get_*` solo por ese campo.

### 5.3. La descripción no reemplaza el esquema

Está PROHIBIDO establecer restricciones solo en texto:

```json
{
  "type": "string",
  "description": "Operation: create, update, delete"
}
```

Use `enum`, `const`, rangos y esquemas condicionales.

Lo mismo aplica a campos mutuamente excluyentes. Si `description` dice «exactamente uno de `user_id` o `group_id`» pero `required` contiene solo campos comunes — el esquema y el texto divergen. La restricción DEBE formalizarse en `inputSchema` (§6.12).

### 5.4. Selección predecible

Las descripciones de herramientas similares deben explicar explícitamente la diferencia.

Por ejemplo:

- `redmine_list_project_members` — miembros de un proyecto concreto y sus roles;
- `redmine_admin_list_users` — lista global de usuarios de la instalación, requiere derechos administrativos.

### 5.5. Instrucciones a nivel de servidor

El servidor PUEDE publicar instrucciones generales breves que explican relaciones entre herramientas y reglas de workflow.

Las instrucciones deben añadir contexto no presente en descripciones individuales y referir herramientas por nombres completos (§5.2.1), por ejemplo:

```text
Use redmine_search_issues antes de redmine_get_issue cuando el ID de incidencia sea desconocido.
Antes de crear o actualizar una incidencia, llame a redmine_list_project_trackers y
redmine_list_project_issue_custom_fields cuando sus IDs aún no se conozcan.
Las notas privadas solo deben solicitarse cuando el usuario las necesite explícitamente y tenga
el permiso requerido.
```

PROHIBIDO:

- repetir descripciones de todas las herramientas en instrucciones del servidor;
- colocar instrucciones de comportamiento general del modelo no relacionadas con el servidor;
- escribir una guía larga en lugar de reglas de routing breves;
- usar declaraciones de marketing;
- referir herramientas por nombres cortos sin prefijo (`list_projects` en lugar de `redmine_list_projects`).

### 5.6. Estudiar la API REST de Redmine antes del desarrollo

Antes de crear o cambiar sustancialmente una herramienta, el desarrollador DEBERÍA realizar investigación de documentación. No se recomienda diseñar el contrato solo desde código MCP existente, memoria del desarrollador o un único ejemplo de solicitud HTTP.

DEBERÍA estudiar:

1. Página principal de la API REST de Redmine: autenticación general, paginación, `include`, campos personalizados, archivos y reglas de error de validación.
2. Página API separada para el recurso correspondiente, por ejemplo Issues, Time Entries, Versions, Wiki Pages o Project Memberships.
3. Sección de historial de cambios de la API y cambios para versiones soportadas de Redmine.
4. Versión real de Redmine usada por MCP y versión mínima soportada.
5. API REST y código fuente de plugins Redmine usados si la herramienta trabaja con una entidad o campos de plugin. Antes de publicar una herramienta de extensión, DEBE verificar el serializador / servicio / endpoint REST de origen y al menos una respuesta real exitosa para cada forma de resultado (list y get, si ambos se publican).
6. Permisos reales, workflow, módulos activados, trackers, campos personalizados y restricciones de la instalación objetivo.
7. Herramientas MCP ya publicadas para evitar crear un contrato duplicado o conflictivo.

La página principal `https://www.redmine.org/projects/redmine/wiki/rest_api` es el punto de entrada pero suele ser insuficiente para una herramienta concreta. DEBERÍA ir a la página del recurso correspondiente y verificar operaciones, parámetros de consulta, `include`, campos de solicitud, estructura de respuesta, códigos de error y restricciones de versión.

### 5.7. Informe de cobertura de API

Antes de implementar una nueva herramienta, el desarrollador DEBERÍA adjuntar una tabla breve de cobertura de API a la solicitud de fusión:

| Campo | Contenido |
|---|---|
| Recurso Redmine | Recurso y enlace a la página oficial de API |
| Endpoint | Método HTTP y ruta |
| Soportado desde | Versión mínima de Redmine |
| Parámetros de solicitud | Todos los parámetros documentados |
| Filtros de consulta | Todos los filtros documentados y valores especiales |
| Valores include | Datos relacionados permitidos |
| Obligatorio/por defecto | Campos obligatorios y valores por defecto |
| Respuesta | Campos principales y variantes de respuesta |
| Errores | Códigos HTTP y estructura de error |
| Permisos | Derechos requeridos y particularidades de impersonación |
| Exposición MCP | Qué parámetros se publican en MCP |
| Omitido intencionalmente | Qué parámetros no se publican y por qué |
| Diferencias plugin/versión | Diferencias de plugin y versión soportada |

El objetivo de la tabla no es necesariamente publicar cada parámetro de Redmine en MCP. El objetivo es no olvidar parámetros accidentalmente y tomar decisiones de publicación conscientemente.

Un parámetro de Redmine puede excluirse de MCP si:

- es peligroso o administrativo;
- duplica una herramienta de limpieza separada;
- es instable entre versiones soportadas;
- crea un esquema ambiguo;
- no se necesita para escenarios de usuario objetivo;
- produce respuestas excesivamente grandes.

Cada exclusión sustancial se registra en `Intencionalmente omitido` con una breve justificación.

### 5.8. Instrucciones para un agente de IA que desarrolla herramientas

Si una herramienta es creada o modificada por un agente de IA, las instrucciones de trabajo DEBERÍAN referirse a este documento: investigación API (§5.6–5.7), contrato (§3–§8), pruebas (§13), checklist (§14).

Texto recomendado:

```text
Antes de implementar o cambiar una herramienta Redmine MCP, siga MCP_TOOL_DEVELOPMENT.md:
estudie la API REST de Redmine para el recurso objetivo (§5.6–5.7), diseñe una intención
de usuario en lugar de copiar el payload REST (§3), compare con tools/list, luego
implemente schema/anotaciones/errores. Para extensiones de plugins, inspeccione el serializador
o la respuesta REST y alinee description con outputSchema (§7, §18). Pase el checklist de
revisión de código (§14).
```

---

## 6. Requisitos de `inputSchema`

### 6.1. Estructura base

Cada herramienta DEBE tener un JSON Schema válido.

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {},
  "required": []
}
```

Para una herramienta sin argumentos:

```json
{
  "type": "object",
  "additionalProperties": false
}
```

### 6.2. Prohibición de propiedades no documentadas

En el nivel superior y en todos los objetos anidados:

```json
"additionalProperties": false
```

Un diccionario abierto solo se permite conscientemente. En ese caso, el esquema del valor se define explícitamente:

```json
"additionalProperties": {
  "type": "string"
}
```

### 6.3. Tipo de cada parámetro

Cada propiedad DEBE contener `type`, `$ref` o una composición `oneOf` / `anyOf` / `allOf`.

PROHIBIDO:

```json
"project_id": {
  "description": "Project ID or identifier"
}
```

### 6.4. Parámetros obligatorios

El array `required` debe reflejar la llamada mínimamente ejecutable.

Si la operación es imposible sin un parámetro, el parámetro DEBE estar en `required`.

Por ejemplo, la subida de archivos requiere al menos:

```json
"required": ["project", "filename", "content_base64"]
```

La verificación `confirm=true` para eliminación se realiza en el servidor (§3.4), incluso si el campo está en `required`.

### 6.5. Enumeraciones

Para un conjunto finito de valores, DEBE usarse `enum` o `const` (no solo texto en la descripción — ver §5.3).

```json
"status": {
  "type": "string",
  "enum": ["open", "locked", "closed"]
}
```

### 6.6. Cadenas

Las cadenas deben tener restricciones apropiadas:

- `minLength` para valores no vacíos;
- `maxLength` según las restricciones de Redmine o límites internos;
- `pattern` cuando el formato está estrictamente definido;
- `format` cuando aplica un formato estándar.

```json
"due_date": {
  "type": "string",
  "format": "date",
  "description": "Due date in YYYY-MM-DD format."
}
```

La restricción `format` en el esquema no reemplaza la validación en el servidor (§3.4).

### 6.7. Números

Para parámetros numéricos, DEBEN establecerse límites razonables.

```json
"limit": {
  "type": "integer",
  "default": 25,
  "minimum": 1,
  "maximum": 100
}
```

```json
"hours": {
  "type": "number",
  "exclusiveMinimum": 0,
  "maximum": 24
}
```

El valor `default` es parte del contrato y la documentación. El servidor no debe asumir que el cliente sustituirá el valor por defecto por su cuenta.

### 6.8. Arrays

Cada array DEBE tener `items`.

Cuando sea necesario, establecer:

- `minItems`;
- `maxItems`;
- `uniqueItems`.

```json
"role_ids": {
  "type": "array",
  "minItems": 1,
  "maxItems": 20,
  "uniqueItems": true,
  "items": {
    "type": "integer",
    "minimum": 1
  }
}
```

Un array como `entries: array` sin esquema de elementos está PROHIBIDO.

### 6.9. Objetos anidados

Todos los objetos anidados se describen completamente.

```json
"custom_fields": {
  "type": "array",
  "items": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "id": {"type": "integer", "minimum": 1},
      "value": {
        "oneOf": [
          {"type": "string"},
          {"type": "number"},
          {"type": "boolean"},
          {
            "type": "array",
            "items": {"type": "string"}
          }
        ]
      }
    },
    "required": ["id", "value"]
  }
}
```

### 6.10. No aceptar «objeto o cadena JSON»

Está PROHIBIDO describir un parámetro como «objeto o cadena JSON».

MCP ya pasa JSON estructurado. La herramienta debe aceptar un objeto, no una cadena que el servidor vuelve a parsear.

### 6.11. `fields` y `extra_fields` universales

Los parámetros `fields`, `extra_fields`, `payload`, `data` y objetos abiertos similares están PROHIBIDOS para las operaciones de negocio principales.

Los campos de incidencia deben listarse explícitamente con `description` significativa (§6.14) y, cuando sea útil, `examples` (§6.15):

```json
{
  "tracker_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Tracker ID returned by redmine_list_trackers.",
    "examples": [1, 2]
  },
  "status_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Issue status ID returned by redmine_list_issue_statuses; must be allowed by the workflow for the current tracker and role.",
    "examples": [1, 2]
  },
  "priority_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Issue priority ID returned by redmine_list_issue_priorities.",
    "examples": [3, 4]
  },
  "assigned_to_id": {
    "type": "integer",
    "minimum": 1,
    "description": "User ID of the assignee, from redmine_list_project_members."
  },
  "fixed_version_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Target version ID returned by redmine_list_versions."
  },
  "parent_issue_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Numeric ID of the parent issue."
  },
  "estimated_hours": {"type": "number", "minimum": 0},
  "start_date": {"type": "string", "format": "date"},
  "due_date": {"type": "string", "format": "date"}
}
```

Los campos poco usados pueden pasarse mediante `custom_fields` estrictamente descrito.

### 6.12. Campos interdependientes

Prefiera dividir herramientas. Si la división es imposible, la dependencia se formaliza mediante:

- `dependentRequired`;
- `if` / `then` / `else`;
- `oneOf` con ramas mutuamente excluyentes.

El texto en `description` («exactamente uno de …») no reemplaza el esquema (§5.3).

Caso típico — «exactamente uno de dos campos». Malo: `required` lista solo campos comunes, el XOR queda en prosa:

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "project": {"type": "string", "minLength": 1},
    "user_id": {"type": "integer", "minimum": 1},
    "group_id": {"type": "integer", "minimum": 1},
    "role_ids": {
      "type": "array",
      "minItems": 1,
      "items": {"type": "integer", "minimum": 1}
    }
  },
  "required": ["project", "role_ids"]
}
```

Tal esquema permite una llamada sin `user_id`/`group_id` y una llamada con ambos campos a la vez.

Bueno — `required` común más `oneOf` en el nivel superior:

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "project": {
      "type": "string",
      "minLength": 1,
      "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown."
    },
    "user_id": {
      "type": "integer",
      "minimum": 1,
      "description": "User ID from redmine_list_users to add as a project member."
    },
    "group_id": {
      "type": "integer",
      "minimum": 1,
      "description": "Group ID to add as a project member."
    },
    "role_ids": {
      "type": "array",
      "minItems": 1,
      "uniqueItems": true,
      "items": {"type": "integer", "minimum": 1},
      "description": "Role IDs from redmine_list_roles."
    }
  },
  "required": ["project", "role_ids"],
  "oneOf": [
    {
      "required": ["user_id"],
      "not": {"required": ["group_id"]}
    },
    {
      "required": ["group_id"],
      "not": {"required": ["user_id"]}
    }
  ]
}
```

La validación en el servidor (§3.4) DEBE rechazar ambas variantes incorrectas. El esquema es necesario para que el cliente y el modelo vean la restricción antes de la llamada.

Debe verificarse la compatibilidad de los constructos elegidos con los clientes y SDK MCP soportados.

### 6.13. Campos con valor `null` y limpieza de valores

`null` solo se permite cuando tiene un significado documentado separado, por ejemplo «limpiar fecha de vencimiento» o «quitar asignación».

```json
"due_date": {
  "oneOf": [
    {"type": "string", "format": "date"},
    {"type": "null"}
  ],
  "description": "New due date in YYYY-MM-DD format, or null to clear it."
}
```

```json
"assigned_to_id": {
  "oneOf": [
    {"type": "integer", "minimum": 1},
    {"type": "null"}
  ],
  "description": "Assignee user ID from redmine_list_users, or null to unassign."
}
```

No use cadena vacía como equivalente implícito de `null`.

Para herramientas `set_*` que establecen un campo opcional (fecha de vencimiento, asignado, etc.), el contrato DEBE decidir explícitamente la limpieza. Se permiten tres opciones — en orden de preferencia:

1. **La misma herramienta acepta `null`** (preferido), como arriba: una intención «establecer o limpiar».
2. **Herramienta separada clear/unassign**, si la API o la UX separan mejor las operaciones, por ejemplo `redmine_advanced_search_clear_saved_query` y `redmine_advanced_search_unassign_search_owner`.
3. **Rechazo explícito**: si la limpieza vía MCP no está soportada, DEBE indicarse en la `description` de la herramienta y/o en la descripción del parámetro. El contrato silencioso «solo cadena/entero sin null» sin explicación está PROHIBIDO — el modelo pensará erróneamente que la limpieza es imposible o intentará pasar `""` / `0`.

Malo — puede establecer fecha de vencimiento, no puede limpiar, y en ningún sitio se indica:

```json
"due_date": {
  "type": "string",
  "format": "date"
}
```

### 6.14. Descripciones de parámetros

Cada parámetro en `inputSchema.properties` DEBE tener una `description` significativa. Parámetros sin `description` están PROHIBIDOS, incluidos en extensiones (elementos de checklist `done`, `sort_order`, `due_date`, campos ID, etc.) y campos opcionales con `enum` claro.

Descripciones como «Filter by tracker ID», «Tracker id» o «Issue id» son insuficientes: no indican dónde obtener un valor permitido ni qué restricciones existen.

La descripción de un parámetro identificador DEBE indicar qué herramienta o campo de respuesta usar para valores permitidos (nombre completo — §5.2.1; descubrimiento — §6.16), y anotar restricciones significativas (workflow, permisos, pertenencia al proyecto).

Malo:

```json
"tracker_id": {
  "type": "integer",
  "description": "Filter by tracker ID."
}
```

```json
"done": {
  "type": "boolean"
}
```

```json
"user_id": {
  "type": "integer",
  "minimum": 1
}
```

```json
"resources": {
  "type": "array",
  "items": {"type": "string", "enum": ["issues", "wiki_pages"]}
}
```

Bueno:

```json
"tracker_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Tracker ID returned by redmine_list_trackers."
}
```

```json
"done": {
  "type": "boolean",
  "description": "true marks the item done; false marks it undone."
}
```

```json
"user_id": {
  "type": "integer",
  "minimum": 1,
  "description": "User ID from redmine_list_users to add as a project member."
}
```

```json
"resources": {
  "type": "array",
  "items": {"type": "string", "enum": ["issues", "wiki_pages"]},
  "description": "Resource types to search. Omit to search all supported resource types."
}
```

Bueno, con restricción anotada:

```json
"status_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Issue status ID returned by redmine_list_issue_statuses; must be allowed by the workflow for the current tracker and role."
}
```

La descripción del parámetro no reemplaza el esquema (§5.3) ni la validación en el servidor (§3.4).

### 6.15. Ejemplos de valores (`examples`)

Para parámetros cuyo formato de valor no es obvio o permite múltiples representaciones, DEBERÍA añadirse `examples` — clave estándar del array en JSON Schema. Los ejemplos ayudan al modelo a introducir un valor correcto y son especialmente útiles para parámetros de referencia, identificadores, fechas y cadenas tipo enum.

```json
"project": {
  "type": "string",
  "minLength": 1,
  "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown.",
  "examples": ["1", "ecookbook"]
}
```

```json
"due_date": {
  "type": "string",
  "format": "date",
  "description": "Due date in YYYY-MM-DD format.",
  "examples": ["2026-07-30"]
}
```

Requisitos:

- los valores de `examples` DEBEN ser válidos contra el esquema del parámetro;
- `examples` ilustran el formato pero no reemplazan `enum`, rangos y otras restricciones (§5.3, §6.5);
- para parámetros con `enum`, `examples` separados suelen ser redundantes.

Si un cliente o SDK MCP no soporta `examples` en el esquema, PUEDE usarse `x-examples` como clave de extensión con la misma semántica.

### 6.16. Ruta de descubrimiento para parámetros ID

Un parámetro de la forma `*_id` que el modelo no puede adivinar DEBE tener una ruta de descubrimiento explícita: una herramienta read/list separada o un campo en la respuesta de otra herramienta read referenciado en la `description` del parámetro (§6.14).

Opciones permitidas (en orden de preferencia para un conjunto de herramientas):

1. **Herramienta list/discovery separada** — `redmine_list_issue_statuses`, `redmine_list_roles`, `redmine_advanced_search_list_search_providers`.
2. **Opciones dentro de la respuesta get/list** — por ejemplo, array `provider` con `id` y `name` en la respuesta de `redmine_advanced_search_semantic_search_issues`. Entonces la descripción DEBE referir ese campo de respuesta con el nombre completo de la herramienta.
3. **Enum estable en el esquema**, si el conjunto de valores es fijo y pequeño.

PROHIBIDO publicar una herramienta de escritura con `status_id` / `role_ids` / similar si ninguna de las opciones anteriores se cumple: el modelo se ve forzado a adivinar IDs.

Malo — escritura sin descubrimiento:

- existe `redmine_advanced_search_set_search_provider` con `provider_id`;
- no hay `redmine_advanced_search_list_search_providers`;
- `semantic_search_issues` devuelve solo el nombre del proveedor actual (`provider: "…"`), sin lista de valores permitidos y sus `id`.

En ese caso una descripción como `"Search provider ID."` es insuficiente. Añadir una herramienta list, o incluir opciones de proveedor en la respuesta get y escribir, por ejemplo:

```text
Search provider ID returned in the provider options from
redmine_advanced_search_semantic_search_issues.
```

La regla aplica al core y a las extensiones (§18).

---

## 7. `outputSchema` y requisitos del resultado

### 7.1. `outputSchema`

Una herramienta nueva DEBE publicar `outputSchema`. El esquema describe un contrato de respuesta público estable, no solo la forma del envoltorio `{ ok, data | error }`.

Si `description` afirma que la herramienta devuelve campos nombrados o estructura anidada, `outputSchema` DEBE formalizar esos campos, no limitarse a `data` / `items` de nivel superior como «objeto arbitrario».

Malo: la descripción lista `query`, `results`, fragmentos y extractos de adjuntos, pero `outputSchema` falta o describe `items` solo como `{ "type": "object", "additionalProperties": true }`.

Para cada campo de resultado estable:

- el tipo DEBE especificarse;
- un campo garantizado DEBE estar en `required`;
- un conjunto finito de valores DEBE establecerse mediante `enum` o `const`;
- una fecha DEBE tener `format: date` o `date-time` si el servidor garantiza el formato correspondiente;
- el ID numérico DEBE mantener un tipo unificado;
- nullable y optional son contratos distintos: si un campo siempre se devuelve pero puede no tener valor, debe ser `required` y permitir `null`;
- para valores de negocio numéricos, DEBEN especificarse unidades si no son obvias por el nombre del campo;
- un valor monetario DEBE tener semántica inequívoca: unidades principales/secundarias y cómo se determina la moneda.

`additionalProperties: true` NO DEBE usarse en lugar de describir campos de resultado estables conocidos. Se permite por compatibilidad hacia atrás o estructuras verdaderamente extensibles, pero los campos de negocio conocidos dentro de tal objeto deben listarse en `properties`, y los garantizados en `required`.

Para herramientas de lista, los elementos `items` DEBEN describir al menos los campos que el modelo necesita para identificación, filtrado y llamadas posteriores a herramientas.

Bueno — fragmento de tipado de `data` (envoltorio completo de éxito/error — §7.2 y §12):

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "ok": {"type": "boolean"},
    "data": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "query": {"type": "string"},
        "results": {
          "type": "array",
          "items": {
            "type": "object",
            "additionalProperties": true,
            "properties": {
              "id": {"type": "integer"},
              "subject": {"type": "string"},
              "url": {"type": "string"}
            },
            "required": ["id", "subject"]
          }
        }
      },
      "required": ["query", "results"]
    }
  },
  "required": ["ok"]
}
```

El resultado DEBERÍA devolver:

- `structuredContent` — objeto legible por máquina si los clientes necesitan estructura estable;
- texto `content` — representación breve para compatibilidad hacia atrás y humanos.

### 7.1.1. Consistencia del contrato público

Antes de completar una herramienta, el desarrollador DEBE comparar tres representaciones:

1. respuesta real del handler / REST / servicio;
2. `description` de la herramienta;
3. `outputSchema`.

No deben contradecirse.

Si la descripción dice que un campo siempre se devuelve, debe ser `required` en `outputSchema`.

Si el esquema establece `enum` / `const` / `format`, el serializador real DEBE normalizar el valor a ese contrato. No se puede publicar `format: date` y simultáneamente prometer cadena formateada según locale.

Si una lista ya devuelve datos, la descripción NO DEBE enviar el modelo a una herramienta get solo por los mismos datos.

Las invariantes de negocio del resultado DEBEN reflejarse en el esquema mediante `const`, `enum`, `required` o esquema condicional, no solo inferirse del nombre de la herramienta. Ejemplo: si una herramienta de suscripción por definición devuelve solo productos de tipo `subscription`, `product_type` debe ser `const: "subscription"`, no `enum` con valores imposibles.

### 7.2. Envoltorio unificado

Resultado exitoso recomendado:

```json
{
  "ok": true,
  "data": {},
  "meta": {}
}
```

Error:

```json
{
  "ok": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "status_id 17 is not available for tracker 3",
    "field": "status_id",
    "retryable": false
  }
}
```

En error, además establecer:

```json
"isError": true
```

Si se publica `outputSchema` y el error también se devuelve en `structuredContent`, el esquema DEBE describir ambas ramas — éxito y error. No se puede publicar un esquema solo de éxito y devolver un objeto de error estructurado incompatible. Alternativa: en error de ejecución de herramienta devolver solo texto `content` con `isError: true` y no devolver `structuredContent`. Opción preferida — envoltorio tipado unificado con dos ramas.

### 7.3. Estabilidad de campos

Los campos de salida son un contrato público. PROHIBIDO:

- cambiar el tipo de campo sin un cambio mayor;
- renombrar un campo sin período de deprecación;
- devolver a veces objeto, a veces array;
- devolver el ID como número a veces, como cadena otras veces;
- devolver respuesta ilimitada sin procesar de la API de Redmine.

### 7.4. Resultado de objeto único

Formato recomendado:

```json
{
  "ok": true,
  "data": {
    "id": 12345,
    "subject": "Fix authorization error",
    "status": {"id": 2, "name": "In Progress"},
    "project": {"id": 10, "identifier": "bank-site", "name": "Bank Site"},
    "url": "https://redmine.example/issues/12345",
    "updated_at": "2026-07-22T09:20:00Z"
  }
}
```

### 7.5. Resultado de lista

```json
{
  "ok": true,
  "data": {
    "items": []
  },
  "meta": {
    "total_count": 143,
    "limit": 25,
    "offset": 0,
    "next_offset": 25,
    "has_more": true
  }
}
```

El esquema de elementos `items` sigue §7.1: identificadores, campos de routing y campos de negocio estables se describen explícitamente. `{ "type": "object", "additionalProperties": true }` vacío como única descripción de elemento está PROHIBIDO.

### 7.6. Volumen mínimamente necesario

Las herramientas list/search deben por defecto devolver registros breves. Descripción completa, diarios, adjuntos y campos de texto grandes deben obtenerse mediante `get_*` separado.

Esto reduce tokens, latencia y el riesgo de pasar datos sensibles en exceso.

### 7.7. Datos sensibles

El resultado no debe contener sin necesidad explícita:

- tokens API;
- cabeceras Authorization;
- cookies;
- rutas del filesystem del servidor;
- stack traces internos;
- contraseñas y secretos;
- campos de Redmine no disponibles para el usuario actual;
- notas privadas sin permiso separado.

---

## 8. Anotaciones MCP

Las anotaciones son indicaciones para el cliente y no son un mecanismo de autorización ni protección.

### 8.1. Matriz de valores

| Tipo de operación | `readOnlyHint` | `destructiveHint` | `idempotentHint` | `openWorldHint` |
|---|---:|---:|---:|---:|
| Obtener/buscar/listar datos de Redmine | `true` | `false` | `true` | `false` |
| Crear incidencia/versión/checklist | `false` | `false` | `false` | `false` |
| Añadir comentario/observador/relación | `false` | `false` | `false` | `false` |
| Cambiar campo, renombrar, establecer flag (`update`, `rename`, `set`) | `false` | `false` | depende de la implementación | `false` |
| Eliminar, limpiar, resetear (`delete`, `purge`, `reset`) | `false` | `true` | solo con idempotencia garantizada | `false` |
| Enviar email a destinatario externo | `false` | `false` | `false` | `true` |
| Acceder a URL arbitraria / sistema externo | depende | depende | depende | `true` |

### 8.2. Reglas

- `readOnlyHint: true` solo si la herramienta no cambia el estado y no causa efectos secundarios.
- `destructiveHint` describe pérdida irreversible o destrucción de datos, no el hecho de escribir. `destructiveHint: true` DEBERÍA establecerse solo para operaciones irreversibles — `delete`, `purge`, `reset`, limpieza completa de campos o relaciones.
- `update`, `rename` y `set` ordinarios NO son destructivos: para ellos `destructiveHint: false`. Por ejemplo, `update_checklist_title` o `rename_wiki_page` es actualización ordinaria, no destrucción, y la anotación destructiva es incorrecta para ellos.
- `idempotentHint: true` solo si la llamada repetida es verdaderamente segura; DEBERÍA confirmarse con un test.
- `openWorldHint` describe si la herramienta accede a un mundo externo abierto y previamente desconocido, no si se crea un nuevo objeto. Trabajar con una instalación Redmine configurada es un mundo cerrado: `openWorldHint: false`.
- Por tanto `create_issue`, `create_time_entry` y otras herramientas de escritura dentro de su Redmine usan `openWorldHint: false`, aunque creen nuevos objetos. Crear un objeto en un sistema conocido no abre el mundo.
- `openWorldHint: true` solo cuando el destinatario o la fuente de datos no están limitados al sistema conocido: email a destinatario externo, petición HTTP arbitraria, acceso a servicio externo.
- El valor de `openWorldHint` DEBERÍA establecerse conscientemente para cada herramienta, no copiarse por defecto: verificar si la herramienta realmente va más allá de su instalación Redmine.
- No se puede copiar un conjunto de anotaciones a todas las herramientas de escritura.

### 8.3. Efectos secundarios de Redmine

Al evaluar idempotencia, considerar no solo los campos finales sino también:

- creación de entradas de diario;
- envío de notificaciones;
- webhooks;
- registro de auditoría;
- subida repetida de archivos;
- creación repetida de relaciones;
- registro repetido de entradas de tiempo.

Si una llamada repetida crea un registro o notificación adicional, la herramienta no es idempotente.

---

## 9. Seguridad

### 9.1. Autorización

Cada llamada DEBE ejecutarse en el contexto de un usuario autenticado o una cuenta de servicio explícitamente documentada.

El servidor DEBE verificar los permisos de Redmine para el proyecto y objeto específicos. La presencia de una herramienta en `tools/list` no implica permiso para la operación.

Las herramientas administrativas deberían:

- publicarse solo para administradores;
- o trasladarse a un perfil/servidor MCP administrativo separado;
- o protegerse con un scope separado.

### 9.2. Derechos mínimos

El servidor MCP y el token API de Redmine deben tener los derechos mínimamente necesarios. No se puede usar un token administrativo global para todos los usuarios si debe preservarse el modelo de acceso por usuario.

### 9.3. Rutas arbitrarias del filesystem prohibidas

Parámetros como:

```json
{"file_path": "/etc/app/.env"}
```

están PROHIBIDOS en herramientas MCP públicas.

Opciones seguras:

1. `content_base64` con límite de tamaño;
2. `upload_token` opaco emitido por mecanismo de subida confiable;
3. URI de recurso MCP donde el host verifica el acceso;
4. archivo solo desde directorio temporal dedicado con verificación `realpath` y lista de permitidos.

El servidor DEBE verificar:

- tamaño máximo;
- tipo MIME;
- extensión permitida;
- nombre de archivo;
- ausencia de path traversal;
- verificación antivirus/contenido si lo exige la política de la organización.

### 9.4. URLs arbitrarias y SSRF

Una herramienta no debe aceptar URL arbitraria salvo que sea su propósito principal.

Cuando se necesita acceso HTTP:

- usar lista de permitidos de dominio y esquema;
- prohibir loopback, link-local, endpoints de metadatos y redes internas si no son necesarios;
- limitar redirecciones;
- establecer timeout y límite de respuesta;
- no pasar credenciales internas a otro origen.

### 9.5. Eliminación y operaciones peligrosas

Para operaciones irreversibles, OBLIGATORIO:

- herramienta separada;
- `destructiveHint: true`;
- descripción explícita de irreversibilidad;
- verificación precisa de permisos en el servidor;
- registro de auditoría;
- protección contra eliminar objeto fuera del proyecto esperado;
- verificación de objetos hijos y consecuencias relacionadas.

El booleano `confirm_delete: true` PUEDE usarse como protección adicional contra llamadas accidentales, pero no puede considerarse mecanismo de autorización.

Eliminación en dos fases, bloqueo optimista y clave de idempotencia — ver apéndice A.

### 9.6. Registros

Los registros de auditoría incluyen:

- nombre de herramienta;
- usuario autenticado;
- IDs de proyecto/objeto destino;
- resultado;
- duración;
- código de error;
- ID de correlación de la petición.

PROHIBIDO registrar:

- token de acceso;
- cabecera Authorization;
- cookies;
- contenido de archivo en base64;
- campos personalizados secretos;
- texto completo de notas privadas sin necesidad separada.

### 9.7. Límite de tasa y timeout

Cada herramienta DEBE tener:

- límite de tamaño de entrada;
- límite de tasa por usuario/token;
- límite del número de registros devueltos;
- límites de operaciones masivas.

El timeout del servidor de 60 s aplica a herramientas de lectura. Las herramientas de escritura no se interrumpen por timeout del servidor para que tras guardar con éxito se pueda registrar el resultado de idempotencia.

---

## 10. Errores

### 10.1. Separación de errores

Se usan dos niveles:

1. **Error de protocolo** — herramienta desconocida, JSON-RPC corrupto, incapacidad de procesar la petición MCP.
2. **Error de ejecución de herramienta** con `isError: true` — error de argumentos, API de Redmine, permisos, workflow o lógica de negocio.

Los errores que el modelo puede corregir cambiando argumentos deben devolverse como errores de ejecución de herramienta.

### 10.2. Estructura de error

```json
{
  "ok": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "User cannot edit issues in project bank-site.",
    "field": null,
    "retryable": false,
    "details": {
      "project": "bank-site",
      "required_permission": "edit_issues"
    }
  }
}
```

### 10.3. Códigos recomendados

```text
VALIDATION_ERROR
NOT_FOUND
FORBIDDEN
CONFLICT
RATE_LIMITED
REDMINE_API_ERROR
TIMEOUT
FILE_TOO_LARGE
UNSUPPORTED_MEDIA_TYPE
INVALID_STATE
PARTIAL_FAILURE
INTERNAL_ERROR
```

### 10.4. El mensaje debe ser reparable

Malo:

```text
Invalid request.
```

Bueno:

```text
field status_id must be one of [2, 4, 7] for tracker_id=3 in project bank-site.
Call redmine_list_allowed_issue_transitions to retrieve current values.
```

No devolver stack trace al usuario. El stack trace se guarda solo en el registro protegido del servidor con ID de correlación.

---

## 11. Paginación y volumen de datos

### 11.1. Herramientas list/search

Parámetros OBLIGATORIOS:

```json
"limit": {
  "type": "integer",
  "default": 25,
  "minimum": 1,
  "maximum": 100
}
```

Para la API existente de Redmine, se permite `offset`. Para implementación personalizada, se prefiere cursor opaco si los datos pueden cambiar activamente durante el recorrido.

### 11.2. Metadatos de paginación

El resultado debe contener:

- `limit` real;
- `offset` o `next_cursor`;
- `has_more`;
- `total_count` si obtenerlo no crea carga significativa.

### 11.3. Selección de campos

El parámetro `fields` solo se permite como array de lista cerrada de permitidos:

```json
"fields": {
  "type": "array",
  "uniqueItems": true,
  "items": {
    "type": "string",
    "enum": ["id", "subject", "status", "assignee", "updated_at"]
  }
}
```

No se pueden pasar nombres de campo arbitrarios directamente a SQL, ActiveRecord `select`, serializador o API de Redmine sin lista de permitidos.

### 11.4. Resultados grandes

Diarios, adjuntos y archivos grandes deben:

- tener paginación separada;
- devolverse mediante herramienta/recurso separado;
- para datos binarios, devolver enlace de recurso u otra referencia limitada en lugar de incrustar base64 grande en la respuesta cuando sea posible;
- o soportar ejecución aumentada por tarea si la operación es verdaderamente larga y el cliente lo soporta.

`execution.taskSupport` no se establece automáticamente. El valor por defecto es `forbidden`.

---

## 12. Referencia para una herramienta nueva

Ejemplo abreviado de herramienta de escritura con `title` obligatorio y `outputSchema` tipado según §7.1. Formato de error — §10. JSON completo — en apéndice B.

```json
{
  "name": "redmine_create_issue",
  "title": "Create Redmine issue",
  "description": "Create one issue in a Redmine project. Use redmine_list_project_trackers and redmine_list_project_issue_custom_fields when valid IDs are unknown.",
  "inputSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "project": {
        "type": "string",
        "minLength": 1,
        "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown.",
        "examples": ["1", "ecookbook"]
      },
      "subject": {
        "type": "string",
        "minLength": 1,
        "maxLength": 255,
        "description": "Issue subject."
      }
    },
    "required": ["project", "subject"]
  },
  "outputSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "ok": {"type": "boolean"},
      "data": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "id": {"type": "integer", "minimum": 1},
          "url": {"type": "string", "format": "uri"},
          "created_at": {"type": "string", "format": "date-time"}
        },
        "required": ["id", "url", "created_at"]
      },
      "error": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "code": {"type": "string"},
          "message": {"type": "string"},
          "field": {
            "oneOf": [
              {"type": "string"},
              {"type": "null"}
            ]
          },
          "retryable": {"type": "boolean"}
        },
        "required": ["code", "message", "retryable"]
      }
    },
    "required": ["ok"],
    "oneOf": [
      {
        "properties": {"ok": {"const": true}},
        "required": ["data"],
        "additionalProperties": true,
        "not": {"required": ["error"]}
      },
      {
        "properties": {"ok": {"const": false}},
        "required": ["error"],
        "additionalProperties": true,
        "not": {"required": ["data"]}
      }
    ]
  },
  "annotations": {
    "readOnlyHint": false,
    "destructiveHint": false,
    "idempotentHint": false,
    "openWorldHint": false
  }
}
```

---

## 13. Pruebas

### 13.1. Pruebas de esquema

Para cada herramienta, OBLIGATORIO:

- al menos una llamada válida;
- al menos una llamada negativa (por ejemplo, campo obligatorio faltante o tipo incorrecto).

DEBERÍA cubrir según aplique al esquema:

- llamada válida completa;
- ausencia de cada campo obligatorio;
- tipo incorrecto de parámetros clave;
- campo adicional desconocido;
- valor fuera de enum;
- valor fuera de rango;
- fecha/date-time incorrecta;
- exceder `maxItems`, `maxLength` y tamaño de archivo;
- violación de interdependencia de campos (ambos campos XOR a la vez; ninguno de un par obligatorio).

### 13.2. Pruebas de permisos

Para operaciones de escritura, destructivas y lectura sensible DEBERÍA verificar:

- usuario sin acceso al proyecto;
- usuario con acceso solo de lectura;
- usuario con permiso de edición;
- administrador si la herramienta toca escenarios admin;
- acceso a notas privadas si la herramienta las devuelve o cambia;
- intento de cambiar objeto de otro proyecto mediante ID sustituido.

Para herramientas simples de solo lectura sin datos sensibles, las pruebas de permisos PUEDEN limitarse a un escenario negativo u omitirse con justificación breve en el MR.

### 13.3. Pruebas de idempotencia

Para `idempotentHint: true`, DEBERÍA haber prueba automática o manual de dos o más llamadas secuenciales idénticas.

Verificar ausencia de efectos secundarios declarados como idempotentes, por ejemplo:

- entradas de diario adicionales;
- emails repetidos;
- duplicados de archivos;
- duplicados de relaciones;
- entradas de tiempo repetidas;
- eventos webhook extra si forman parte de la garantía.

### 13.4. Pruebas de contrato

DEBERÍA mantener `tools/list` como snapshot u otro seguimiento de cambios de contrato incompatibles. CI PUEDE detectar:

- cambio de nombre;
- eliminación de parámetro;
- cambio de tipo;
- cambio de `required`;
- aumento del nivel de riesgo en anotaciones;
- desaparición de `outputSchema`;
- cambio incompatible de campos, tipos, `required`, `enum` / `const`, o ramas de éxito/error de `outputSchema`.

### 13.5. Pruebas de selección LLM

Para herramientas similares o fácilmente confundibles DEBERÍA haber un conjunto de peticiones de usuario y llamadas de herramienta esperadas. La ejecución LLM automática completa PUEDE reemplazarse por ejemplos estáticos en el MR o revisión de descripción.

Ejemplos:

| Petición | Herramienta esperada |
|---|---|
| «Mostrar incidencia 123» | `redmine_get_issue` |
| «Buscar incidencias sobre OAuth» | `redmine_search_issues` |
| «Añadir observador 15 a incidencia 123» | `redmine_add_issue_watcher` |
| «Eliminar relación entre incidencias» | `redmine_delete_issue_relation` |
| «Buscar incidencias similares» | `redmine_advanced_search_semantic_search_issues` |

La prueba o revisión falla si el modelo con alta probabilidad elige una herramienta destructiva universal para intención de solo lectura o se ve forzado a adivinar valores `action`.

### 13.6. Pruebas de recuperación de errores

DEBERÍA verificar que tras errores típicos el modelo recibe información suficiente para reintentar correctamente:

- ID faltante;
- estado inválido;
- conflicto `expected_updated_at`;
- permisos insuficientes;
- límite excedido;
- tipo MIME incorrecto.

---

## 14. Checklist de revisión de código

Una herramienta nueva no puede fusionarse hasta que todos los elementos obligatorios reciban respuesta «sí».

### Propósito

- [ ] Una acción; sin mezclar operaciones `action`/`manage` (§3.1–3.2).
- [ ] Operación administrativa separada de la ordinaria.

### Nombre y descripción

- [ ] El nombre empieza con `redmine_`: core — `redmine_<verb>_<entity>`; plugin de terceros — `redmine_<plugin_id>_…` (§4.1).
- [ ] Descripción: propósito, efectos secundarios, resultado breve; herramientas similares distinguibles (§5).
- [ ] Referencias cruzadas a otras herramientas usan nombres completos de `tools/list` (§5.2.1).

### Investigación del contrato fuente

- [ ] Para herramienta core, API REST del recurso, versiones y plugins si hace falta estudiados; informe de cobertura DEBERÍA adjuntarse al MR (§5.6–5.7).
- [ ] Para herramienta de extensión, serializador / servicio / endpoint REST fuente y al menos una respuesta exitosa real para cada forma de resultado DEBEN verificarse (§18.5).
- [ ] Contrato comparado con `tools/list` actual.

### Esquema de entrada

- [ ] El esquema cumple §6 (`additionalProperties: false`, tipos, `required`, `enum`/`const`, restricciones).
- [ ] Cada parámetro tiene `description` significativa (§6.14); `*_id` tiene `minimum: 1` (§4.3).
- [ ] Para `*_id` y otros valores de lookup, ruta de descubrimiento especificada (§6.16): herramienta list, campo de respuesta get/list, o `enum`.
- [ ] Restricciones «exactamente uno de …» / interdependencia formalizadas en esquema, no solo en descripción (§5.3, §6.12).
- [ ] Bloqueo optimista — solo `expected_updated_at`, no `updated_at` (§4.4).
- [ ] Para campos opcionales `set_*`, limpieza decidida: `null`, herramienta clear separada, o rechazo explícito (§6.13).
- [ ] Sin «objeto o cadena JSON» y `fields`/`payload` arbitrarios.
- [ ] `*_id` — entero; validación en servidor según §3.4.

### Salida y errores

- [ ] La herramienta nueva tiene `outputSchema` con envoltorio éxito/error (§7.1–7.2).
- [ ] Campos de resultado estables conocidos descritos en `properties`; `additionalProperties: true` no usado en lugar del contrato conocido.
- [ ] Todos los campos garantizados están en `required`.
- [ ] Campos nullable y optional distinguidos conscientemente.
- [ ] `enum`/`const`, `date`/`date-time`, rangos y otras restricciones conocidas formalizadas en esquema.
- [ ] Para valores monetarios y de negocio numéricos, unidades, moneda y unidades principales/secundarias claras.
- [ ] Invariantes de negocio del resultado reflejadas en esquema (`const`, `enum`, `required`, o esquema condicional), no solo inferidas del nombre de herramienta.
- [ ] Descripción, `outputSchema` y respuesta real handler/REST/servicio no contradicen (§7.1.1).
- [ ] Valores internos REST/Ruby/plugin normalizados a contrato MCP estable; sin filtración de nombres STI/clase o formatos dependientes de locale (§3.3).
- [ ] Herramienta list devuelve estructura breve pero suficiente; descripción explica correctamente cuándo la herramienta get correspondiente es verdaderamente necesaria.
- [ ] Errores: `isError`, código estable, mensaje reparable; sin secretos ni stack trace (§10).

### Anotaciones

- [ ] Anotaciones coinciden con el riesgo (§8); test recomendado para `idempotentHint: true`.

### Seguridad

- [ ] Permisos, ruta de archivo, SSRF, límites, registros, destructivo/auditoría — según §9; patrones del apéndice A según necesidad.

### Pruebas

- [ ] Pruebas de esquema mínimas; el resto según riesgo (§13).

---

## 15. Compatibilidad y cambio de herramientas existentes

### 15.1. Cambios incompatibles

Cambio incompatible:

- renombrar herramienta;
- eliminar campo;
- cambiar tipo;
- añadir nuevo campo obligatorio;
- cambiar significado de campo;
- cambio de salida incompatible;
- fusionar varias operaciones en una;
- aumentar riesgo sin actualizar anotaciones y documentación.

### 15.2. Migración de nombres

Al migrar, por ejemplo, del prefijo antiguo `redmine_mcp_`:

```text
redmine_mcp_get_issue
```

al prefijo corto `redmine_`:

```text
redmine_get_issue
```

seguir:

1. añadir nuevo nombre;
2. mantener temporalmente alias antiguo;
3. marcar herramienta antigua como obsoleta en la descripción **o no publicarla en `tools/list`** si el alias solo se necesita para `tools/call`;
4. recopilar métricas de llamadas al nombre antiguo (el audit log existente por nombre de herramienta invocada es suficiente);
5. eliminar alias tras período acordado (no antes de la siguiente versión major, salvo que se acuerde otro período);
6. enviar `notifications/tools/list_changed` si el servidor declara `listChanged`.

Ejemplos actuales (véase [03-core-tools.md](03-core-tools.md)): `redmine_list_all_users` → `redmine_admin_list_users`; `redmine_list_files` → `redmine_list_project_files`; `redmine_delete_file` → `redmine_delete_attachment`; `redmine_get_server_info` → `redmine_get_mcp_info`. Un alias se acepta en `tools/call` y no se publica en `tools/list`.

### 15.3. Cambio de descripciones

La descripción afecta la selección de herramientas del modelo y se considera cambio de comportamiento. En cambio sustancial de descripción DEBERÍA revisar ejemplos de selección LLM o realizar revisión repetida de selección.

### 15.4. Versión del servidor

La versión del plugin MCP la devuelve `redmine_get_mcp_info` (o metadatos del servidor). No añadir `v1`, `v2` a cada nombre sin necesidad real de soportar contratos incompatibles en paralelo.

---

## 16. Reglas para problemas actuales de Redmine MCP

Al desarrollar herramientas nuevas, está prohibido repetir patrones de la auditoría del contrato actual. Las reglas canónicas están en las secciones correspondientes; abajo solo un mapa de problemas:

| Problema de auditoría | Sección |
|---|---|
| Nombres sin prefijo `redmine_` (incluidos plugins de terceros) / estilo mixto dentro de un plugin | §4.1 |
| Verbo no coincide con semántica (`complete_*` con `done=true/false` en lugar de `set_*`) | §4.2 |
| ID numérico sin `minimum: 1` o con descripción «Issue id» | §4.3 |
| Bloqueo optimista como `updated_at` en lugar de `expected_updated_at` | §4.4, A.2 |
| `manage_*` / `patch_*` universal y parámetro `action` | §3.1, §4.2 |
| Parámetros sin `type`, enum solo en descripción, arrays sin `items` | §5.3, §6 |
| Parámetros sin `description`; descripciones demasiado cortas sin referencia a herramienta lookup | §6.14 |
| Sin `examples` en parámetros de referencia e identificadores | §6.15 |
| Herramienta de escritura con `*_id` sin ruta de descubrimiento (sin herramienta list y opciones en respuesta get) | §6.16 |
| Descripción promete «exactamente uno de A o B», esquema no lo codifica | §5.3, §6.12 |
| Nombres cortos de herramientas en referencias cruzadas (`list_projects` en lugar de `redmine_list_projects`) | §5.2.1 |
| Descripción de herramienta sobrecargada media página | §5.2 |
| `fields` / `extra_fields` sin esquema; `required` extra | §6.4, §6.11 |
| `set_*` sin forma de limpiar campo y sin rechazo explícito | §6.13 |
| Un conjunto de anotaciones en todas las herramientas de escritura; `openWorldHint` excesivo | §8 |
| `destructiveHint: true` en `update` / `rename` ordinarios; `openWorldHint` incorrecto en `create_*` | §8.1, §8.2 |
| Descripción promete estructura de respuesta, pero `outputSchema` falta o describe solo objeto arbitrario | §7.1 |
| Descripción, esquema y respuesta real contradicen | §7.1.1 |
| Nombres STI/clase o fechas locale en respuesta MCP | §3.3 |
| `additionalProperties: true` en lugar de campos list/get conocidos | §7.1 |
| `file_path` arbitrario, bypass de scope de proyecto, SSRF | §9 |
| Efecto email/externo en una herramienta con cambio local | §3.2 |
| Pares ambiguos de herramientas similares | §5.4 |

---

## 17. Estructura del conjunto de herramientas

La lista completa actual de herramientas no se duplica en este documento — queda obsoleta rápidamente.

**Fuente de verdad:**

- herramientas core — [03-core-tools.md](03-core-tools.md) y `tools/list` real en la instalación;
- herramientas de plugins de terceros — §18 y respuesta MCP `tools/list` en la instalación.

**Principios de agrupación** (cada grupo — herramientas atómicas separadas según §3):

| Grupo | Intenciones de ejemplo | Prefijo |
|---|---|---|
| Incidencias | get, list, search, create, update, delete, copy, subtareas | `redmine_` |
| Relaciones y observadores | list/create/delete relación; add/remove observador | `redmine_` |
| Proyectos y miembros | proyectos, módulos, miembros, roles | `redmine_` |
| Versiones y categorías | versiones; categorías de incidencia | `redmine_` |
| Entradas de tiempo | list, create, update, import, actividades | `redmine_` |
| Wiki | list, get, create, update, rename, delete | `redmine_` |
| Archivos y adjuntos | list, upload, delete, download | `redmine_` |
| Administración | usuarios, roles, info de sesión MCP | `redmine_admin_` o `redmine_get_mcp_info` |
| Entidades de plugin | checklists, búsqueda, etc. | `redmine_` + `plugin_id`, por ejemplo `redmine_advanced_search_` |

Antes de añadir una herramienta nueva DEBERÍA verificar la respuesta MCP `tools/list` y el grupo correspondiente: no duplicar herramienta existente ni mezclar intenciones distintas en un nombre.

Si un grupo tiene herramienta de escritura con parámetro ID (`status_id`, `role_ids`, …), el mismo grupo DEBE tener ruta de descubrimiento (§6.16).

Las herramientas administrativas se publican solo para usuarios con los derechos requeridos (§9.1).

---

## 18. Extensiones de plugins de terceros

Sección para autores de plugins Redmine que añaden herramientas vía Extension API. Descripción técnica de API, hooks y casos límite — en [04-extensions.md](04-extensions.md).

Las extensiones siguen las mismas reglas de contrato, seguridad y nombres (§3–§10, §4.1) que las herramientas core de `redmine_mcp`.

### 18.1. Qué publicar cuándo

| Primitiva | Cuándo usar |
|---|---|
| **Tool** | Una acción sobre entidad de plugin o Redmine: create, get, update, delete, search |
| **Resource** | Contenido grande o estático por URI estable: cuerpo wiki, archivo, informe largo |
| **Prompt** | Plantilla de escenario repetible para el usuario, no operación con efecto secundario |
| **`extend_tool`** | Parámetro o hook lógicamente parte de herramienta core existente (por ejemplo `include_*` al leer incidencia) |

Si el modelo puede cumplir la intención con herramienta separada sin adivinar `action` — preferir **herramienta propia**, no `extend_tool` que infla otro esquema.

### 18.2. Registro

- El archivo de extensión se carga al inicio de Redmine (ver `ExtensionLoader`):
  - en un plugin de terceros — `lib/<plugin_id>/mcp.rb` (y otras rutas compatibles, ver [04-extensions.md](04-extensions.md));
  - en una integración integrada de `redmine_mcp` — `lib/redmine_mcp/extensions/<plugin.id>.rb`, si el plugin destino no tiene su propio `mcp.rb`, o como fallback si falla la carga de su `mcp.rb`.
- El módulo en `mcp.rb` DEBE ser `PluginName::Mcp` (`extend RedmineMcp::ExtensionApi`): Zeitwerk deriva el nombre del archivo.
- Antes del registro DEBERÍA verificar `mcp_extension_enabled?` — dependencia dura de `redmine_mcp` en gemspec no es obligatoria.
- Usar `register_tool_once` para el registro, así el reload no duplica la herramienta.
- El nombre completo en `tools/list` DEBE empezar con `redmine_` (§4.1).
- La herramienta DEBE tener `title`, `description`, `input_schema`, `output_schema`, `permission` y `annotations`; prohibida la duplicación de nombre.
- La herramienta es visible en la respuesta MCP `tools/list` solo para usuarios con el permiso correspondiente.

### 18.3. Nombres

- El nombre DEBE empezar con `redmine_`; luego — `plugin_id` y `<verb>_<entity>`: `redmine_redmine_advanced_checklists_<verb>_<entity>`, `redmine_advanced_search_<verb>_<entity>`.
- Verbos y prohibición de `manage_*` — según §4.2 y §3.1.
- No copiar nombres de herramientas core ni publicar segunda herramienta con la misma intención bajo otro nombre.

Antes del registro DEBERÍA comparar con la respuesta `tools/list` en la instalación destino.

### 18.4. Permisos y seguridad

- `permission` DEBE coincidir con permisos reales de Redmine o del plugin, no rol separado «solo mcp».
- Para operaciones con incidencias DEBERÍA usar `register_issue_tool` y `find_accessible_issue` en lugar de copiar verificaciones de visibilidad y módulo de proyecto.
- Si `module_name` está establecido, la herramienta DEBE estar en `tools/list` solo cuando el usuario tiene el permiso declarado en al menos un proyecto visible con módulo habilitado. Sin `module_name`, permiso en al menos un proyecto visible es suficiente. El handler sigue verificando la incidencia específica, incluido su módulo de proyecto.
- Validación repetida de argumentos y permisos en el servidor en el handler — según §3.4 y §9, incluso si la herramienta está oculta de `tools/list` para otros usuarios.

### 18.5. Implementación limpia

**Capa MCP delgada.** `mcp.rb` debe contener principalmente registro de herramientas: esquemas, descripciones, permisos, anotaciones y handlers cortos. El handler valida argumentos, verifica contexto y delega la ejecución a clase/servicio separado.

La lógica de negocio del plugin debe permanecer en modelos y servicios ordinarios y no depender de MCP.

Si la lógica solo se necesita para MCP — por ejemplo, fusionar datos de varios modelos, normalizar respuesta REST al contrato MCP, calcular campos derivados o preparar resultado de herramienta — PUEDE trasladarse a `mcp_tools.rb` separado. Si tal archivo crece, DEBERÍA dividirse en clases por entidad u operación, por ejemplo `mcp_tools/clients.rb`, `mcp_tools/deals.rb`, `mcp_tools/subscriptions.rb`.

No colocar lógica de negocio y transformaciones grandes directamente en lambda/handler dentro de `mcp.rb`.

**Acceso a datos.**

- Modelos y servicios del plugin — si la lógica ya está ahí.
- `internal_request` / `internal_get` / REST — si hay que reutilizar controlador API existente; el endpoint debe soportar `accept_api_auth`. Usar `internal_request` para `POST`, `PUT`, `PATCH` y `DELETE`; usar `internal_get` o `internal_request(method: 'GET', ...)` para lecturas. Verificar fallos con `internal_request_error?`.

**`extend_tool` — con moderación.** Apropiado cuando el parámetro es parte de una intención con la herramienta core. Inapropiado cuando el plugin esencialmente añade subsistema separado: mejor prefijo propio y herramientas propias, enlace al core descrito en `description` o instrucciones del servidor.

**Contrato como core.** Entrada — según §6. Salida — según §7.1 y §7.1.1: campos estables, `required`, `enum`/`const`, unidades, normalización de API interna. Anotaciones por riesgo, errores reparables (§8, §10). Bloqueo optimista — `expected_updated_at` (§4.4). Cada parámetro — `description` (§6.14). Referencias cruzadas — nombres completos (§5.2.1). Cada parámetro de escritura `*_id` — ruta de descubrimiento (§6.16): `list_*` separado u opciones con `id` en respuesta get/list, y referencia explícita en descripción del parámetro.

Antes de publicar herramienta de extensión DEBE verificarse serializador / servicio / endpoint REST fuente y al menos una respuesta exitosa real para cada forma de resultado.

**Código compartido — en `redmine_mcp`.** Al desarrollar extensión, si un fragmento puede necesitarse en otro plugin MCP, DEBERÍA añadirse al core `redmine_mcp` de inmediato, no copiarse a `lib/<plugin>/mcp*.rb`.

Criterio: la lógica no está ligada a un dominio de plugin (checklists, búsqueda, …) y describe contrato MCP, Extension API o patrón de integración típico.

| Dónde | Qué |
|------|-----|
| **`redmine_mcp`** | `SchemaNormalizer.envelope_output`, `REST_OBJECT_SCHEMA` / `REST_ARRAY_SCHEMA`, extensión `ExtensionApi` (`register_issue_tool`, `issue_permission`, `internal_request`, …), `ToolResponse`, helpers comunes de permisos por `issue_id` / `project_id` |
| **Extensión de plugin** | `mcp.rb` — registro de herramientas y handlers cortos; `mcp_tools.rb` / `mcp_tools/*.rb` — obtención, agregación y normalización específica MCP; modelos/servicios ordinarios — lógica de negocio sin depender de MCP |

**Ubicación recomendada para extensión:**

- `mcp.rb` — registro de herramientas y handlers cortos;
- `mcp_tools.rb` / `mcp_tools/*.rb` — obtención, agregación y normalización de datos específica MCP;
- modelos/servicios ordinarios — lógica de negocio sin depender de MCP.

Antes de copiar helper de otra extensión DEBERÍA verificar si el análogo ya existe en `redmine_mcp`; si falta — trasladar al core en el mismo PR, no duplicar.

Más sobre Extension API — [04-extensions.md](04-extensions.md) (§ «ExtensionApi helper methods»).

### 18.6. Anti-patrones

PROHIBIDO o no recomendado:

- registrar herramientas en cada petición HTTP;
- fallar por error de plugin vecino al inicio;
- mezclar lectura, escritura y admin en una herramienta;
- duplicar herramienta core «con otro nombre»;
- extender otra herramienta con parámetros opcionales «para el futuro»;
- devolver en MCP campos internos no disponibles al usuario en UI/API del plugin;
- publicar nombres de clases STI, fechas locale o representación REST si el esquema MCP define contrato distinto (§3.3, §7.1.1);
- describir elemento de lista solo como `{ "type": "object", "additionalProperties": true }` (§7.1);
- publicar `set_*_status` / similar con `status_id` sin dar al modelo forma de conocer IDs permitidos (§6.16);
- duplicar helpers MCP comunes en extensión (envoltorio `outputSchema`, wrappers `internal_request`, permiso de incidencia) si su lugar es en `redmine_mcp` — ver §18.5.

### 18.7. Verificación pre-merge

- [ ] El nombre de herramienta empieza con `redmine_` según §4.1 / §18.3.
- [ ] La extensión carga al inicio; la herramienta aparece en `tools/list` para usuario con derechos.
- [ ] La herramienta está ausente para usuario sin derechos y cuando el flag de extensión MCP del plugin está deshabilitado.
- [ ] Contrato y checklist (§14) cumplidos, incluida comparación descripción / outputSchema / respuesta real (§7.1.1); pruebas según §13 si hace falta.
- [ ] Serializador / REST / servicio verificado en al menos una respuesta exitosa real para cada forma de resultado publicada (por ejemplo list y get si ambos se publican).
- [ ] Sin duplicación de herramienta existente en `tools/list`.
- [ ] Para cada parámetro de escritura `*_id` hay ruta de descubrimiento (§6.16).

---

## 19. Fuentes y base normativa

Documento preparado a fecha 2026-07-22 basado en las siguientes fuentes primarias:

1. Model Context Protocol, **Protocol Revision 2025-11-25**  
   https://modelcontextprotocol.io/specification/2025-11-25

2. Model Context Protocol, **Tools**  
   https://modelcontextprotocol.io/specification/2025-11-25/server/tools

3. Model Context Protocol, **Schema Reference**  
   https://modelcontextprotocol.io/specification/2025-11-25/schema

4. Model Context Protocol, **Security Best Practices**  
   https://modelcontextprotocol.io/docs/tutorials/security/security_best_practices

5. Model Context Protocol, **Understanding Authorization in MCP**  
   https://modelcontextprotocol.io/docs/tutorials/security/authorization

6. Model Context Protocol Blog, **Tool Annotations as Risk Vocabulary: What Hints Can and Can't Do**  
   https://blog.modelcontextprotocol.io/posts/2026-03-16-tool-annotations/

7. Model Context Protocol Blog, **Server Instructions: Giving LLMs a user manual for your server**  
   https://blog.modelcontextprotocol.io/posts/2025-11-03-using-server-instructions/

8. JSON Schema, **Reference**  
   https://json-schema.org/understanding-json-schema/reference

9. JSON Schema, **Enumerated values**  
   https://json-schema.org/understanding-json-schema/reference/enum

10. JSON Schema, **Conditional schema validation**  
    https://json-schema.org/understanding-json-schema/reference/conditionals

11. Redmine, **REST API overview**  
    https://www.redmine.org/projects/redmine/wiki/rest_api

12. Redmine, **REST Issues**  
    https://www.redmine.org/projects/redmine/wiki/Rest_Issues

13. Redmine, **REST API changes**  
    Enlace `API changes for each version` en la página REST API; verificado para todas las versiones soportadas.

---

## 20. Criterio de preparación de herramienta nueva

Una herramienta MCP nueva se considera lista cuando se cumplen los elementos obligatorios del checklist de revisión de código (§14).

Para herramientas de plugins de terceros además — checklist §18.7.

Recomendaciones de riesgo: informe de cobertura (§5.7), pruebas adicionales §13.2–13.6 y apéndice A. Pruebas de esquema mínimas (§13.1) y reglas de `outputSchema` (§7.1, §7.1.1) son obligatorias.

---

## Apéndice A. Patrones de implementación recomendados

Los patrones abajo no son obligatorios para cada herramienta MCP. DEBERÍA considerarlos para riesgo elevado: operaciones destructivas, herramientas admin, escritura masiva, efectos secundarios externos, llamadas repetidas por timeout.

### A.1. Eliminación en dos fases (prepare / confirm)

Para operaciones administrativas especialmente peligrosas:

1. `redmine_prepare_delete_*` devuelve descripción breve de consecuencias y token de un solo uso;
2. `redmine_confirm_delete_*` acepta token con TTL corto.

Requisitos normativos para operaciones destructivas — en §9.5.

### A.2. Bloqueo optimista

Para update/delete bajo cambio concurrente, el parámetro DEBE llamarse `expected_updated_at` (§4.4), no `updated_at`:

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

El nombre es unificado para herramientas core y extensiones (incluidas herramientas de escritura de checklist).

En conflicto devuelve `CONFLICT`, hora real de modificación del objeto (`updated_at` / `updated_on` en la respuesta) y recomendación de volver a leer el objeto.

### A.3. Clave de idempotencia

Para operaciones donde la repetición por timeout puede crear duplicado:

```json
"idempotency_key": {
  "type": "string",
  "minLength": 8,
  "maxLength": 128
}
```

Especialmente apropiado para:

- creación de incidencias;
- importación de entradas de tiempo;
- subida de archivos;
- operaciones masivas;
- envío de email.

Si la herramienta publica `idempotentHint: true`, la llamada repetida debe ser segura (§8.2); `idempotency_key` es una forma de garantizarlo.

---

## Apéndice B. Ejemplo completo de herramienta

Referencia `redmine_create_issue`. Cuando cambie el formato de error o el envoltorio, actualizar §7, §10 y esta sección; §12 permanece abreviado.

```json
{
  "name": "redmine_create_issue",
  "title": "Create Redmine issue",
  "description": "Create one issue in a Redmine project. Use redmine_list_project_trackers and redmine_list_project_issue_custom_fields when valid IDs are unknown. This operation may create notifications and is not idempotent unless idempotency_key is supplied.",
  "inputSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "project": {
        "type": "string",
        "minLength": 1,
        "maxLength": 255,
        "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown.",
        "examples": ["1", "ecookbook"]
      },
      "subject": {
        "type": "string",
        "minLength": 1,
        "maxLength": 255,
        "description": "Issue subject."
      },
      "description": {
        "type": "string",
        "maxLength": 100000,
        "description": "Issue description in Redmine text format."
      },
      "tracker_id": {
        "type": "integer",
        "minimum": 1,
        "description": "Tracker ID returned by redmine_list_project_trackers.",
        "examples": [1, 2]
      },
      "priority_id": {
        "type": "integer",
        "minimum": 1,
        "description": "Issue priority ID returned by redmine_list_issue_priorities.",
        "examples": [3, 4]
      },
      "assigned_to_id": {
        "type": "integer",
        "minimum": 1,
        "description": "User ID of the assignee, from redmine_list_project_members."
      },
      "due_date": {
        "type": "string",
        "format": "date",
        "description": "Due date in YYYY-MM-DD format.",
        "examples": ["2026-07-30"]
      },
      "custom_fields": {
        "type": "array",
        "maxItems": 100,
        "items": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "id": {"type": "integer", "minimum": 1},
            "value": {
              "oneOf": [
                {"type": "string"},
                {"type": "number"},
                {"type": "boolean"},
                {
                  "type": "array",
                  "items": {"type": "string"}
                }
              ]
            }
          },
          "required": ["id", "value"]
        }
      },
      "idempotency_key": {
        "type": "string",
        "minLength": 8,
        "maxLength": 128
      }
    },
    "required": ["project", "subject"]
  },
  "outputSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "ok": {"type": "boolean"},
      "data": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "id": {"type": "integer"},
          "url": {"type": "string", "format": "uri"},
          "created_at": {"type": "string", "format": "date-time"}
        },
        "required": ["id", "url", "created_at"]
      },
      "error": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "code": {"type": "string"},
          "message": {"type": "string"},
          "field": {
            "oneOf": [
              {"type": "string"},
              {"type": "null"}
            ]
          },
          "retryable": {"type": "boolean"}
        },
        "required": ["code", "message", "retryable"]
      }
    },
    "required": ["ok"],
    "oneOf": [
      {
        "properties": {"ok": {"const": true}},
        "required": ["data"],
        "additionalProperties": true,
        "not": {"required": ["error"]}
      },
      {
        "properties": {"ok": {"const": false}},
        "required": ["error"],
        "additionalProperties": true,
        "not": {"required": ["data"]}
      }
    ]
  },
  "annotations": {
    "readOnlyHint": false,
    "destructiveHint": false,
    "idempotentHint": false,
    "openWorldHint": false
  },
  "execution": {
    "taskSupport": "forbidden"
  }
}
```

Nota: si el servidor garantiza idempotencia cuando `idempotency_key` está presente, la anotación sigue describiendo la herramienta en su totalidad. Por tanto el valor seguro permanece `false` si se permite llamada sin clave.

