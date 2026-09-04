# Extensiones MCP para plugins de Redmine

[Deutsch](../de/extension_guide.md) | [English](../en/extension_guide.md) | [Español](extension_guide.md) | [Français](../fr/extension_guide.md) | [Italiano](../it/extension_guide.md) | [日本語](../ja/extension_guide.md) | [한국어](../ko/extension_guide.md) | [Polski](../pl/extension_guide.md) | [Português (Brasil)](../pt-BR/extension_guide.md) | [Русский](../ru/extension_guide.md) | [中文](../zh/extension_guide.md)

`redmine_mcp` permite que otros plugins de Redmine añadan sus propias herramientas MCP y, si es necesario, registren recursos, prompts y capacidades sin un servidor MCP separado y sin cambios en `redmine_mcp` mismo.

## Cómo funciona

`redmine_mcp` proporciona un Registro MCP compartido donde los plugins de Redmine de terceros registran herramientas mediante `RedmineMcp::ExtensionApi`.

Una llamada típica fluye así:

```text
client → tools/list
client → tools/call {name, arguments}
        → Registry valida argumentos contra el esquema
        → comprueba permiso
        → invoca el manejador
        → construye la respuesta MCP estándar
```

`redmine_mcp` no debe conocer la lógica de negocio de un plugin de terceros: el plugin registra sus propias herramientas mediante la API de extensión.

## Estabilidad y compatibilidad hacia atrás

A partir de `redmine_mcp 1.0.0`, la API de extensión pública se considera estable.

Solo los métodos y contratos de `RedmineMcp::ExtensionApi` descritos en esta guía son API pública. Las clases, módulos y métodos internos de `redmine_mcp` que no estén documentados como parte de la API de extensión no son API pública y pueden cambiar sin garantías de compatibilidad hacia atrás.

Dentro de una misma versión mayor de `redmine_mcp`:

- los métodos públicos existentes de la API de extensión no se eliminan ni cambian de forma incompatible;
- pueden añadirse nuevos métodos y parámetros opcionales;
- los métodos obsoletos se marcan primero y permanecen disponibles al menos hasta la siguiente versión mayor;
- los cambios que requieren actualizaciones en plugins de terceros solo se publican en una nueva versión mayor.

Todos los cambios de la API de extensión se listan en `CHANGELOG.md`.

Se recomienda a los plugins de terceros declarar la versión mínima de `redmine_mcp` que requieren y revisar `CHANGELOG.md` al actualizar.

## Inicio rápido

1. Cree un archivo `mcp.rb` en una de estas rutas:
   - `lib/<plugin.id>/mcp.rb`
   - `lib/<plugin_directory_basename>/mcp.rb`
   - `lib/<plugin.id sin el prefijo redmine_>/mcp.rb` si `plugin.id` empieza por `redmine_`
2. Defina el módulo `<PluginName>::Mcp`.
3. Extienda `RedmineMcp::ExtensionApi`.
4. Establezca `plugin_id`.
5. Registre la primera herramienta.

Ejemplo mínimo de extensión en el ámbito de incidencias:

```ruby
module RedmineMyPlugin
  module Mcp
    extend RedmineMcp::ExtensionApi

    plugin_id :my_plugin

    register_issue_tool(
      name: 'get_plugin_data',
      title: 'Get plugin data',
      description: 'Returns plugin data for an issue.',
      output_schema: RedmineMcp::SchemaNormalizer.envelope_output(
        type: 'object',
        properties: {
          issue_id: {type: 'integer', minimum: 1}
        },
        required: ['issue_id']
      ),
      permission: :view_issues,
      annotations: RedmineMcp::Core::Helpers::READ_ONLY_ANNOTATIONS
    ) do |issue, _args, _context|
      {issue_id: issue.id}
    end
  end
end
```

El ejemplo usa `register_issue_tool`, el helper recomendado para herramientas que trabajan con incidencias. El contrato completo de la herramienta está en [mcp_tool_development.md](mcp_tool_development.md).

### El nombre del módulo `Mcp`

El archivo de extensión es `mcp.rb`. Zeitwerk infiere `Mcp` de ese nombre de archivo, así que escriba `module Mcp`.

Las herramientas se registran cuando se requiere el archivo. El cargador no busca el nombre de la constante del módulo.

## Nomenclatura

Para herramientas y prompts, use un nombre corto:

```ruby
name: 'search_issues'
```

El nombre MCP completo se genera automáticamente:

```text
redmine_<plugin_id>_<name>
```

Para herramientas, prefiera `name` en el formato `<verb>_<entity>`.

Verbos preferidos:

`get`, `list`, `search`, `create`, `update`, `set`, `delete`, `add`, `remove`, `copy`, `upload`, `download`, `send`, `summarize`.

No use `manage_*`, `process_*`, `handle_*` vagos, ni herramientas con un parámetro como `action: create | update | delete` cuando las operaciones puedan dividirse en herramientas separadas y claras.

Por ejemplo:

```text
plugin_id :advanced_search
name: 'semantic_search_issues'

-> redmine_advanced_search_semantic_search_issues
```

Si `plugin_id` ya empieza por `redmine_` (por ejemplo `redmine_advanced_checklists`), el nombre completo sigue `redmine_<plugin_id>_<name>`: `redmine_redmine_advanced_checklists_<name>`.

Para recursos, use un URI único, por ejemplo:

```text
redmine://<plugin_id>/<type>/<id>
```

Los nombres de herramientas/prompts y los URI de recursos deben ser únicos. El comportamiento ante registro duplicado depende del método usado; `register_tool_once` no registra la misma herramienta dos veces.

## Registro de herramientas

### Herramienta regular

Use `register_tool_once` cuando necesite una herramienta MCP regular no vinculada a una incidencia concreta.

Casos típicos:

- búsqueda de datos del plugin;
- devolución de un resumen;
- validación o cálculo en el servidor.

Ejemplo básico:

```ruby
register_tool_once(
  name: 'get_summary',
  title: 'Get plugin summary',
  description: 'Returns plugin summary.',
  input_schema: {
    type: 'object',
    additionalProperties: false,
    properties: {}
  },
  output_schema: RedmineMcp::SchemaNormalizer.envelope_output(
    type: 'object',
    additionalProperties: false,
    properties: {
      summary: {type: 'string'}
    },
    required: ['summary']
  ),
  permission: :view_issues,
  annotations: RedmineMcp::Core::Helpers::READ_ONLY_ANNOTATIONS,
  handler: lambda { |_args, _context| {summary: 'ok'} }
)
```

El contrato completo de la herramienta — `additionalProperties: false`, anotaciones de riesgo y el sobre mediante `SchemaNormalizer.envelope_output` — se describe en [mcp_tool_development.md](mcp_tool_development.md).

### Herramienta de incidencia

Use `register_issue_tool` cuando la herramienta acepta `issue_id` y trabaja con una incidencia.

Es la opción recomendada para escenarios en el ámbito de incidencias porque:

- encuentra la incidencia mediante `Issue.visible(user)`;
- comprueba el módulo de proyecto cuando es necesario;
- comprueba el permiso dado en el proyecto de la incidencia;
- pasa la `issue` encontrada al bloque;
- devuelve un error si la incidencia no está disponible o no se encuentra.

Véase también la sección Permisos.

`module_name` en `register_issue_tool` es un identificador opcional de módulo de proyecto de Redmine. No tiene que coincidir con `plugin_id`. Si se establece, la herramienta aparece en `tools/list` solo cuando el usuario puede ver al menos un proyecto con ese módulo y el permiso declarado.

### Qué devuelve el manejador

El manejador devuelve un hash de datos de éxito sin sobre, o un sobre listo `{ok: true, data: ...}` / `{ok: false, error: ...}`. El Registro normaliza el resultado mediante `ToolResponse.from_handler_result`: un hash simple se envuelve en `{ok: true, data: ...}`; para listas puede devolver el resultado listo de `paginated_list`, que ya contiene `data` y `meta`.

Para errores, use `RedmineMcp::Core::Helpers.error_result`, `mcp_error` o `{ok: false, error: ...}`.

## Esquema de entrada

`SchemaNormalizer.normalize_input` normaliza el esquema de objeto y añade restricciones de servicio, pero el contrato público de parámetros debe describirse explícitamente.

Reglas principales:

- cada parámetro debe tener un tipo definido;
- los campos numéricos `*_id` usan `type: integer`, `minimum: 1` y una descripción con ruta de descubrimiento;
- los conjuntos finitos de valores se definen mediante `enum` / `const`, no solo en prosa;
- los arrays deben tener `items`;
- los campos interdependientes y mutuamente excluyentes se definen mediante JSON Schema (`oneOf`, `if/then/else`, etc.), no solo en la descripción;
- el bloqueo optimista usa `expected_updated_at`, no `updated_at`;
- `null` solo se usa con semántica documentada explícitamente, por ejemplo para limpiar un campo;
- no use `fields`, `payload` o `data` abiertos en lugar de parámetros de negocio tipados;
- no acepte un objeto como cadena JSON;
- no acepte un `file_path` arbitrario en una herramienta pública.

Los requisitos completos de `inputSchema` están en [mcp_tool_development.md](mcp_tool_development.md).

## Esquema de salida

Toda herramienta nueva debe tener un `output_schema`.

Para un resultado regular, use el sobre estándar:

```ruby
RedmineMcp::SchemaNormalizer.envelope_output(
  type: 'object',
  properties: {
    summary: {type: 'string'}
  },
  required: ['summary']
)
```

Para listas, use `SchemaNormalizer.list_envelope_output(item_schema)`.

Los campos de resultado estables conocidos deben describirse explícitamente. No use `REST_OBJECT_SCHEMA` / `REST_ARRAY_SCHEMA` en lugar de un contrato tipado cuando la estructura de respuesta es conocida. Estos esquemas son aceptables solo para estructuras verdaderamente abiertas o inestables.

Los requisitos completos de `outputSchema` están en [mcp_tool_development.md](mcp_tool_development.md).

## Anotaciones

| Tipo de operación | read_only | destructive | idempotent | open_world |
|---|---|---|---|---|
| get / list / search | `true` | `false` | `true` | `false` |
| create / add | `false` | `false` | `false` | `false` |
| update / rename / set | `false` | `false` | depende de la implementación | `false` |
| delete / purge | `false` | `true` | solo si una repetición es realmente segura | `false` |
| efecto secundario externo | `false` | depende | normalmente `false` | `true` |

`destructive` significa pérdida irreversible de datos, no cualquier escritura.

`open_world` significa ir más allá de la instalación conocida de Redmine, no crear un nuevo objeto dentro de Redmine.

Las anotaciones no sustituyen las comprobaciones de permiso en el manejador.

## Permisos

`permission` lo usa el Registro para la disponibilidad de la herramienta y comprobaciones preliminares, pero no sustituye las comprobaciones de acceso a un objeto concreto dentro del manejador.

Para herramientas en el ámbito de incidencias, use `register_issue_tool`, que comprueba la visibilidad de la incidencia, el módulo de proyecto y el permiso.

Para otras entidades, el manejador debe volver a comprobar el acceso al objeto encontrado.

## Errores

Use los códigos de error MCP estándar:

`VALIDATION_ERROR`, `NOT_FOUND`, `FORBIDDEN`, `CONFLICT`, `RATE_LIMITED`, `REDMINE_API_ERROR`, `TIMEOUT`, `FILE_TOO_LARGE`, `UNSUPPORTED_MEDIA_TYPE`, `INVALID_STATE`, `PARTIAL_FAILURE`, `INTERNAL_ERROR`.

Para errores estándar, use los helpers `error_result`.
Para un código personalizado, use `mcp_error`.
Para bloqueo optimista, use `conflict_if_stale`.

El manejador devuelve un error estructurado, no un stack trace ni una excepción no manejada.

## Helpers integrados

`RedmineMcp::Core::Helpers` contiene helpers compartidos que deben reutilizarse en lugar de duplicarse:

- `find_project`
- `any_project_allows?`
- `resolve_user_ref`
- `clamp_limit` / `clamp_offset`
- `paginated_list` / `paginate_collection`
- `integer_id`
- `serialize_named_ref`
- `error_result`
- `mcp_error`
- `model_errors`
- `conflict_if_stale`
- `truthy?`

También hay fragmentos de esquema listos:

- `PROJECT_SCHEMA`
- `USER_ID_SCHEMA`
- `USER_REF_SCHEMA`
- `ISSUE_ID_SCHEMA`
- `PAGINATION_INPUT`
- `EXPECTED_UPDATED_AT_SCHEMA`
- `IDEMPOTENCY_KEY_SCHEMA`

Antes de crear su propio helper, compruebe si ya existe uno adecuado en `redmine_mcp`.

Consulte el conjunto actual de helpers en `RedmineMcp::Core::Helpers` y [04-extensions.md](04-extensions.md): esta lista muestra las capacidades principales disponibles y no sustituye la documentación de la API ExtensionApi.

## Modo de solo lectura e idempotencia

Las herramientas mutadoras deben respetar el modo de solo lectura global:

```ruby
blocked = RedmineMcp::Core::ReadOnly.guard_write!
return blocked if blocked
```

Para operaciones donde una llamada repetida puede crear un duplicado, puede usar `idempotency_key` y `RedmineMcp::IdempotencyStore`.

`idempotentHint: true` solo está permitido cuando una llamada repetida es realmente segura considerando todos los efectos secundarios.

## Organización del código

`mcp.rb` debe contener principalmente registro de herramientas: esquemas, descripciones, permisos, anotaciones y manejadores breves.

La obtención, agregación y normalización de datos específicos de MCP pueden trasladarse a:

- `mcp_tools.rb`;
- cuando el archivo crece — `mcp_tools/*.rb`.

La lógica de negocio regular debe permanecer en los modelos/servicios del plugin y no debe depender de MCP.

Si el plugin ya tiene un endpoint REST adecuado que implementa la operación necesaria y admite llamadas en nombre del usuario actual, DEBERÍA reutilizarlo mediante `internal_request` (o `internal_get` para llamadas `GET` de solo lectura).

Esta es la opción preferida: MCP usa las mismas comprobaciones de permiso, obtención de datos y comportamiento de negocio que la API existente del plugin.

```ruby
result = internal_request(
  method: 'POST',
  path: '/my_plugin/items.json',
  user: context[:user],
  body: JSON.generate(item: {name: args[:name]})
)
return result if internal_request_error?(result)
```

Para `POST`, `PUT` y `PATCH`, pase una cadena de cuerpo de solicitud JSON (o `nil` cuando el endpoint no espera cuerpo). Los parámetros de consulta van en `params`.

Llame directamente a un modelo/servicio cuando:

- no hay un endpoint REST adecuado;
- el endpoint no admite la operación o datos necesarios;
- usar REST crea una capa innecesaria o incorrecta para la operación;
- la lógica de negocio compartida ya está extraída intencionalmente en un servicio y el endpoint REST es solo un envoltorio fino de ese servicio.

No implemente la misma lógica de negocio por separado para REST y MCP. Si ambas capas necesitan lógica compartida, extráigala en un servicio común.

## Capacidades adicionales

`RedmineMcp::ExtensionApi` también proporciona:

| Método | Cuándo usar |
|---|---|
| `register_resource` | necesita un recurso MCP |
| `register_prompt` | necesita un prompt MCP |
| `register_capability` | necesita añadir una capacidad a `redmine_get_mcp_info` |
| `extend_tool` | necesita ampliar una herramienta existente en lugar de crear una nueva |
| `on` | necesita un hook del ciclo de vida |
| `internal_request` | necesita llamar a un endpoint REST de Redmine o del plugin en proceso como el usuario actual (`method`, `path`, `params` y `body` opcionales) |
| `internal_get` | atajo para `internal_request(method: 'GET', ...)` |
| `internal_request_error?` | comprobar si un resultado REST en proceso es un sobre de error MCP |

Establezca `plugin_id` una vez al inicio del módulo. Antes de registrar herramientas, DEBERÍA comprobar `mcp_extension_enabled?` cuando el registro lo realiza la extensión misma. El `ExtensionLoader` estándar tampoco carga `mcp.rb` para extensiones deshabilitadas.

### Ampliar una herramienta existente

Use `extend_tool` solo cuando una herramienta separada no encaje bien.

```ruby
extend_tool(
  'redmine_search_issues',
  extra_params: {
    semantic_hint: {
      type: 'string',
      description: 'Optional semantic hint for ranking.'
    }
  }
)
```

`before` se ejecuta antes del manejador, `after` después. `extra_params` se añaden al esquema de entrada. Los nombres de parámetros no deben entrar en conflicto con la herramienta base ni con otras extensiones de esa herramienta.

Si la extensión se requiere desde `after_initialize` de un plugin antes de que `redmine_mcp` registre las herramientas principales, difiera `extend_tool` para una herramienta principal (por ejemplo `redmine_get_issue`) hasta que finalice la inicialización — use un `Rails.application.config.after_initialize` anidado y compruebe primero `Registry.instance.tool(...)`.

## Carga y deshabilitación de una extensión

`redmine_mcp` busca automáticamente el archivo de extensión en las rutas compatibles al arrancar Redmine.

Dos variantes de integración:

1. **Extensión en un plugin de terceros** — `lib/<...>/mcp.rb` en el directorio del plugin destino (véase «Inicio rápido»).
2. **Integración integrada en `redmine_mcp`** — `lib/redmine_mcp/extensions/<plugin.id>.rb` para casos en los que no se puede modificar el plugin de terceros. El archivo registra tools/resources/prompts mediante el mismo `RedmineMcp::ExtensionApi`. Si el plugin destino ya tiene su propio `mcp.rb`, la integración integrada se usa solo si falla la carga de ese archivo.

Ejemplo de integración integrada:

```ruby
module RedmineMcp
  module Extensions
    module AdvancedSearch
      extend RedmineMcp::ExtensionApi

      plugin_id :advanced_search

      if mcp_extension_enabled?
        register_tool_once(
          name: 'semantic_search_issues',
          description: 'Semantic search for issues.',
          input_schema: {type: 'object', properties: {}},
          output_schema: RedmineMcp::SchemaNormalizer.envelope_output(type: 'object', properties: {}),
          permission: :view_issues,
          handler: ->(_args, _context) { {} }
        )
      end
    end
  end
end
```

El código auxiliar de la integración puede colocarse en `lib/redmine_mcp/extensions/<plugin_id>/` e importarse con `require` explícito desde el archivo principal.

Compruebe `redmine_mcp` solo en el punto de entrada `mcp.rb` (normalmente `lib/<plugin>.rb` o el `after_initialize` del cargador del plugin). Los archivos cargados solo desde `mcp.rb` (`mcp_tools.rb`, `mcp_tools/*.rb`, etc.) no deben repetir las mismas comprobaciones. Para integraciones integradas en `redmine_mcp` no hace falta una comprobación aparte en el punto de entrada: el archivo solo lo carga `ExtensionLoader`.

No llame `ExtensionLoader.load_plugin_extension` manualmente desde un plugin de terceros: `ExtensionLoader` es un mecanismo interno de `redmine_mcp`. Un `require` condicional de su `mcp.rb` es suficiente; si el orden de carga de plugins impidió ese `require`, el `ExtensionLoader` estándar de `redmine_mcp` actúa como respaldo.

Ejemplo de punto de entrada:

```ruby
# lib/my_plugin.rb

Rails.application.config.after_initialize do
  require "#{File.dirname(__FILE__)}/my_plugin/mcp" if Redmine::Plugin.installed?(:redmine_mcp) && defined?(RedmineMcp)
end
```

La extensión se registra solo si:

- MCP está habilitado en la configuración de `redmine_mcp`;
- se encuentra el archivo de extensión (`mcp.rb` en el plugin o `lib/redmine_mcp/extensions/<plugin.id>.rb` en `redmine_mcp`, con prioridad del `mcp.rb` del plugin);
- el módulo de extensión se carga correctamente;
- la extensión no está deshabilitada en la lista `MCP extensions`.

Tras instalar una nueva extensión o cambiar `mcp.rb`, Redmine suele necesitar un reinicio. El cliente MCP puede necesitar reconectarse. En algunas aplicaciones, como Cursor, recargar el servidor MCP no basta para detectar nuevas herramientas: si no aparecen, reinicie completamente la aplicación.

## Verificación de una extensión

Tras la implementación, verifique la herramienta mediante una llamada MCP real para comprobar no solo el manejador, sino también:

- registro en `tools/list`;
- esquema de entrada;
- permiso;
- sobre de salida;
- errores.

Compruebe los registros de Redmine para errores de registro de herramientas y carga de extensiones.

Para cada herramienta nueva, como mínimo:

- un escenario de esquema exitoso;
- un escenario de esquema negativo.

Los requisitos detallados de pruebas automatizadas están en [mcp_tool_development.md](mcp_tool_development.md) (§13).

### Pruebas automatizadas de extensiones

Las pruebas automatizadas de una extensión MCP de plugin DEBEN ejercitar la **ruta completa del Registro** (validación `inputSchema` → permiso → manejador → sobre `{ok, data | error}`), no solo una llamada directa al manejador.

Si `redmine_mcp` no está instalado o no está cargado, la clase de prueba **omite** escenarios (`skip` en `setup`) en lugar de fallar al cargar el archivo:

```ruby
def setup
  skip('redmine_mcp is not installed') unless Redmine::Plugin.installed?(:redmine_mcp) && defined?(RedmineMcp)
  # ...
end
```

En el `setup` de pruebas, llamar `RedmineMcp::ExtensionLoader.load_plugin_extension(Redmine::Plugin.find(:your_plugin))` es aceptable para registrar herramientas en el `Registry`. No llame `ExtensionLoader` desde código de producción del plugin (véase «Carga y deshabilitación de una extensión»).

Para comparar la respuesta real con el `outputSchema` publicado (`mcp_tool_development.md` §7.1), use `json_schemer` — la misma biblioteca que `RedmineMcp::InputValidator` aplica a los esquemas de entrada.

La carga diferida de `json_schemer` dentro de un helper de prueba está permitida. Si la biblioteca no está disponible en el entorno, la comprobación debe omitirse explícitamente para que las pruebas del plugin no fallen por una dependencia opcional.

Pruebas automatizadas mínimas para una herramienta de extensión de solo lectura:

- una llamada exitosa al Registro con validación `outputSchema`;
- una llamada negativa rechazada por `inputSchema` (por ejemplo violación de `oneOf`, enum o `maxItems`);
- cuando sea necesario — una prueba separada de validación en servidor a nivel de manejador (el esquema no sustituye las comprobaciones en servidor; véase `mcp_tool_development.md` §3.4).

## Solución de problemas

| Problema | Qué comprobar |
|---|---|
| La extensión no se cargó | ruta de `mcp.rb` o `lib/redmine_mcp/extensions/<plugin.id>.rb`, nombre del módulo, si MCP está habilitado, si la extensión está habilitada en la configuración, errores en el log de Rails |
| La herramienta/recurso/prompt no apareció | si `plugin_id` está establecido, si la extensión está deshabilitada, colisiones de nombre o URI, si el usuario tiene los permisos requeridos |
| Los cambios no aparecieron tras editar | reinicie Redmine; en Cursor y clientes similares, recargar el servidor MCP puede no detectar nuevas herramientas — reinicie completamente la aplicación |
| `extend_tool` no funciona | si la herramienta base está registrada, si `extra_params` entran en conflicto con el esquema existente |

### Lista de comprobación previa al merge

- [ ] La herramienta tiene `title`, `description`, `input_schema`, `output_schema`, `permission` y `annotations`.
- [ ] Cada `*_id` tiene una ruta de descubrimiento.
- [ ] Descripción, `output_schema` y la respuesta real son coherentes.
- [ ] Una herramienta mutadora respeta el modo de solo lectura.
- [ ] La lógica específica de MCP no crece dentro de un lambda/manejador.
- [ ] Los helpers compartidos se reutilizan desde `redmine_mcp`, no se copian.
- [ ] Se ejecutó al menos un escenario de esquema exitoso y uno negativo.
