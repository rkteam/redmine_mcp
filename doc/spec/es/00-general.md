# Redmine MCP — especificación general

[Deutsch](../de/00-general.md) | [English](../en/00-general.md) | [Español](00-general.md) | [Français](../fr/00-general.md) | [Italiano](../it/00-general.md) | [日本語](../ja/00-general.md) | [한국어](../ko/00-general.md) | [Polski](../pl/00-general.md) | [Português (Brasil)](../pt-BR/00-general.md) | [Русский](../ru/00-general.md) | [中文](../zh/00-general.md)

## Descripción general

El plugin Redmine MCP proporciona un servidor MCP (Model Context Protocol) dentro de una instalación de Redmine. Los clientes de IA se conectan a un único endpoint HTTP y acceden a los datos de Redmine mediante herramientas, recursos y prompts.

El plugin incluye un conjunto base de herramientas para trabajar con proyectos, incidencias y usuarios. Otros plugins de Redmine instalados pueden ampliar MCP sin modificar el código de Redmine MCP.

## Objetivo

Proporcionar un mecanismo de integración único entre Redmine y sistemas de IA donde:

- el usuario opera dentro de sus permisos de Redmine;
- los desarrolladores de plugins pueden añadir sus propias capacidades MCP;
- no se requiere un servidor MCP separado ni un fork específico de la instalación.

## Escenarios principales

1. **Conectar un cliente de IA** — un administrador activa MCP, concede el permiso `use_mcp` a los roles necesarios y emite una clave API; el usuario conecta un cliente (Cursor, etc.) al endpoint `/mcp`.
2. **Trabajar con datos de Redmine** — el cliente invoca herramientas para obtener proyectos, incidencias y usuarios.
3. **Extensión por otros plugins** — cuando se instala un plugin con extensión MCP, sus herramientas aparecen automáticamente en la lista compartida.
4. **Administración** — activar/desactivar MCP y activar la integración MCP de plugins individuales.

## Áreas afectadas

- API (MCP sobre HTTP)
- Permisos
- Configuración
- Incidencias
- Proyectos
- Usuarios
- Foros
- Plugins (extensiones)

## Reglas de negocio

- MCP solo está disponible cuando se activa explícitamente en la configuración del plugin.
- Todas las operaciones se ejecutan en nombre del usuario autenticado de Redmine.
- Las escrituras mediante MCP pasan por los modelos de Redmine: se ejecutan callbacks de modelo. Los hooks del controlador (`controller_issues_*_save`, `controller_journals_edit_post`, etc.) no son invocados por MCP.
- La visibilidad de datos sigue las reglas de Redmine: el usuario no recibe más de lo que puede ver en la interfaz web.
- Los nombres de herramientas y prompts usan el formato `<plugin_id>_<name>`, por ejemplo `redmine_list_projects`.
- Los `title` y `description` de las herramientas del núcleo se publican en inglés para la selección por LLM y **no se localizan** mediante `en.yml`/`ru.yml` (excepción al estándar i18n para el catálogo de herramientas MCP). Los mensajes de error y la UI de configuración sí se localizan.
- Las extensiones de otros plugins no crean una dependencia fuerte: si Redmine MCP no está presente, el plugin de terceros sigue funcionando.

## Casos límite

- Cuando MCP está desactivado, todas las solicitudes a `/mcp` se rechazan.
- Cuando una extensión falla, otras extensiones y las herramientas del núcleo siguen funcionando.
- Las nuevas herramientas de extensiones están disponibles tras reiniciar Redmine; el cliente MCP puede necesitar reconectarse para actualizar la lista de herramientas.
- En modo sin estado, cada solicitud HTTP se procesa de forma independiente; no se conserva sesión entre solicitudes.

## Manejo de errores

- Los errores de autenticación y autorización se devuelven a nivel HTTP.
- Los errores de ejecución de herramientas se devuelven en formato MCP con un flag de error.
- Los errores de carga de extensiones se registran y no bloquean el arranque de Redmine.

## Archivos de especificación

| Archivo | Contenido |
|------|---------|
| [console-commands.md](console-commands.md) | Comandos de instalación, verificación y mantenimiento |
| [01-mcp-server.md](01-mcp-server.md) | Endpoint HTTP, protocolo MCP, transporte |
| [02-authentication.md](02-authentication.md) | Autenticación y control de acceso |
| [03-core-tools.md](03-core-tools.md) | Herramientas integradas de Redmine |
| [04-extensions.md](04-extensions.md) | API de extensión para otros plugins |
| [05-settings.md](05-settings.md) | Configuración del plugin y registro |
| [mcp_tool_development.md](mcp_tool_development.md) | Requisitos de desarrollo de herramientas MCP (guía dev) |
| [extension_guide.md](extension_guide.md) | Guía para desarrolladores de extensiones |

## Escenarios de prueba

1. Tras instalar y activar MCP, el cliente ejecuta `initialize` con éxito y recibe información del servidor.
2. Un usuario con el permiso Use MCP y una clave API válida ve la lista de herramientas disponibles para él.
3. Un usuario sin el permiso Use MCP se le deniega el acceso a `/mcp`.
4. Cuando un plugin de extensión está instalado, sus herramientas están presentes en `tools/list` para un usuario con los permisos correspondientes.
