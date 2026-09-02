# API de extensión para otros plugins

[Deutsch](../de/04-extensions.md) | [English](../en/04-extensions.md) | [Español](04-extensions.md) | [Français](../fr/04-extensions.md) | [Italiano](../it/04-extensions.md) | [日本語](../ja/04-extensions.md) | [한국어](../ko/04-extensions.md) | [Polski](../pl/04-extensions.md) | [Português (Brasil)](../pt-BR/04-extensions.md) | [Русский](../ru/04-extensions.md) | [中文](../zh/04-extensions.md)

## Descripción general

Redmine MCP proporciona un mecanismo de extensión que permite a otros plugins de Redmine instalados registrar sus propias herramientas, recursos y prompts, y ampliar herramientas existentes.

## Objetivo

Ofrecer un enfoque único para integrar plugins de Redmine con IA sin duplicar un servidor MCP y sin modificar el código de Redmine MCP.

## Áreas afectadas

- Plugins
- API
- Permisos

## Reglas de negocio

### Descubrimiento automático

- Al arrancar Redmine (cuando MCP está habilitado), el sistema comprueba todos los plugins instalados.
- Un plugin se considera con extensión MCP si contiene un archivo `mcp.rb` en una de estas rutas:
  - `lib/<plugin.id>/mcp.rb`;
  - `lib/<nombre del directorio del plugin>/mcp.rb`;
  - `lib/<plugin.id sin prefijo redmine_>/mcp.rb` si el identificador empieza por `redmine_` (esquema típico como `redmine_advanced_checklists` → `lib/advanced_checklists/mcp.rb`).
- El plugin `redmine_mcp` no se carga a sí mismo como extensión.
- Se omiten los plugins cuya casilla de extensión MCP está desmarcada en la configuración.
- Un fallo en la extensión de un plugin no bloquea la carga de las demás, incluido un error de sintaxis en el archivo de extensión.

### Registro de herramientas

- Un plugin de extensión puede registrar cualquier número de herramientas.
- Cada herramienta tiene: nombre, descripción, esquema de entrada, esquema de salida, requisito de permiso y manejador.
- Nombre completo de la herramienta: `redmine_<plugin_id>_<name>`, por ejemplo `redmine_redmine_advanced_checklists_get_issue_checklists`, `redmine_advanced_search_semantic_search_issues`.
- Los nombres de herramienta duplicados están prohibidos.
- Una herramienta aparece en MCP solo para usuarios con los permisos correspondientes.
- Una herramienta de extensión en el ámbito de incidencias puede requerir un módulo de proyecto de Redmine habilitado (el identificador del módulo no tiene que coincidir con el id del plugin). En `tools/list`, dicha herramienta es visible si el usuario tiene el permiso declarado en al menos un proyecto visible con ese módulo. Sin requisito de módulo, basta con tener permiso en al menos un proyecto visible. La llamada sigue comprobando la incidencia concreta: visibilidad, permiso en su proyecto y módulo habilitado; en caso contrario la respuesta es «not found».
- Las herramientas de escritura de extensión en modo de solo lectura de MCP no ejecutan el manejador: la denegación es la misma que para las herramientas de escritura principales.

### Ampliación de herramientas existentes

- Un plugin puede ampliar una herramienta ya registrada.
- Una extensión puede:
  - añadir parámetros de entrada adicionales;
  - ejecutar código antes del manejador principal;
  - ejecutar código después del manejador y modificar el resultado.
- Varios plugins pueden ampliar la misma herramienta a la vez.
- Los parámetros adicionales se fusionan en el esquema de entrada compartido.
- El nombre de un parámetro adicional no debe coincidir con un parámetro de la herramienta principal ni con el de otra extensión para la misma herramienta.
- El esquema resultante se normaliza antes de publicarse en `tools/list`.
- El orden de ejecución de extensiones coincide con el orden de carga de plugins.

### Registro de recursos

- Un plugin puede publicar recursos con un URI único. Volver a registrar el mismo URI se rechaza.
- Un recurso debe tener un manejador de lectura.
- Esquema de URI recomendado: `redmine://<plugin_id>/<type>/<id>`.
- Un recurso puede requerir comprobaciones de permiso; sin permiso el recurso no está disponible.
- Las comprobaciones de permiso reciben el URI y los argumentos. El proyecto se toma de `project` / `project_id`, del URI (`project`/`project_id` en la consulta o segmento `/projects/:id`), o de un resolvedor de proyecto explícito definido por la extensión. `resources/read` pasa `{uri: ...}` a la comprobación.
- Si se especifica un proyecto en la llamada pero no se encuentra o no es accesible para el usuario actual, se deniega el acceso. La comprobación «al menos un proyecto» solo aplica cuando no se especifica proyecto (descubrimiento con argumentos vacíos).
- Leer un recurso devuelve contenido en formato texto o JSON.

### Registro de prompts

- Un plugin puede añadir prompts con nombre, descripción, argumentos y manejador.
- Nombre completo del prompt: `redmine_<plugin_id>_<name>`.
- Los prompts están disponibles para usuarios con los permisos correspondientes. Las comprobaciones de permiso reciben los argumentos de la llamada, incluidos `project` / `project_id`. Si se especifica un proyecto pero no se encuentra o no es accesible, se deniega el acceso; sin proyecto especificado aplica la misma regla de descubrimiento que para recursos.

### Eventos (hooks)

- Un plugin puede suscribirse a eventos del ciclo de vida de MCP, por ejemplo:
  - registro de herramientas;
  - registro de recursos;
  - registro de prompts;
  - finalización de la carga de todas las extensiones.
- Un error en un manejador de eventos se registra y no interrumpe el proceso principal.

### Dependencias

- Un plugin de extensión no tiene que declarar una dependencia estricta de Redmine MCP.
- Se recomienda comprobar `RedmineMcp::ExtensionApi` / `mcp_extension_enabled?` antes del registro.
- El plugin de extensión no necesita incluir la gema MCP — basta con la API de Redmine MCP.

### Capacidades de la API de extensión

Mediante la API de extensión, un plugin de extensión puede:

- verificar que MCP está habilitado y la extensión no está deshabilitada;
- registrar una herramienta una vez (sin duplicación al recargar);
- registrar una herramienta en el ámbito de incidencias con comprobaciones de permiso estándar y búsqueda de incidencia; si la incidencia desapareció antes de que se ejecute el manejador, la respuesta es «not found», no un error interno;
- ampliar una herramienta principal existente con parámetros y manejadores before/after;
- registrar modos de capacidad para `redmine_get_mcp_info` (por ejemplo `issue_search.semantic`);
- llamar a la REST API de Redmine o del plugin en proceso en nombre del usuario actual mediante `internal_request` (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`; el endpoint de destino debe aceptar autenticación API); los errores REST se mapean a códigos MCP canónicos sin el estado HTTP de la solicitud interna;
- publicar `outputSchema` en el formato de sobre `{ ok, data | error }`.

La lista de métodos de la API Ruby y los ejemplos de código están en el README del plugin y en [mcp_tool_development.md](mcp_tool_development.md) (guía de desarrollo, no SPEC de comportamiento).

## Casos límite

- Un plugin sin archivo de extensión se ignora.
- Si existe el archivo de extensión pero falla el `require` — entrada en el registro, la extensión no se considera cargada; el registro de herramientas es un efecto secundario de un `require` correcto.
- Intentar ampliar una herramienta inexistente — error durante el registro de la extensión.
- Un plugin con la casilla de extensión MCP desmarcada en la configuración no se carga aunque exista el archivo de extensión.
- Tras instalar una nueva extensión, se requiere reiniciar Redmine; el cliente MCP puede necesitar reconectarse.

## Manejo de errores

- Error de carga del archivo de extensión — entrada en el registro, continuar cargando otros plugins.
- Error de registro de herramienta al arrancar — entrada en el registro.
- Error en un manejador `before` de extensión — aborta la ejecución de la herramienta.
- Error en un manejador `after` — se registra; se conserva el resultado del manejador principal salvo que el manejador cambie el flujo de control.

## Escenarios de prueba

8. El descubrimiento de recursos y prompts con argumentos vacíos sigue disponible si existe permiso en al menos un proyecto.
9. Un plugin con `plugin.id` como `redmine_*` y archivo `lib/<id sin prefijo redmine_>/mcp.rb` se considera con integración MCP y aparece en la configuración de extensiones MCP.
10. Una herramienta en el ámbito de incidencias con requisito de módulo no está en `tools/list` para un usuario sin ningún proyecto visible con ese módulo, aunque tenga el permiso en otro proyecto.

## Ejemplos de extensiones

| Plugin | Herramienta | Propósito |
|--------|------------|------------|
| `advanced_search` | `semantic_search_issues` | Búsqueda semántica de incidencias |
