# Autenticación y autorización

[Deutsch](../de/02-authentication.md) | [English](../en/02-authentication.md) | [Español](02-authentication.md) | [Français](../fr/02-authentication.md) | [Italiano](../it/02-authentication.md) | [日本語](../ja/02-authentication.md) | [한국어](../ko/02-authentication.md) | [Polski](../pl/02-authentication.md) | [Português (Brasil)](../pt-BR/02-authentication.md) | [Русский](../ru/02-authentication.md) | [中文](../zh/02-authentication.md)

## Descripción general

El acceso a MCP utiliza la autenticación estándar por clave API de Redmine. Todas las operaciones se ejecutan en nombre del usuario propietario de la clave.

## Objetivo

Garantizar que MCP no eluda la seguridad de Redmine y que los usuarios solo puedan realizar las acciones permitidas para ellos.

## Áreas afectadas

- Permisos
- API
- Usuarios

## Reglas de negocio

### Autenticación

- La API REST de Redmine debe estar activada para acceder a `/mcp`.
- La clave API se pasa en la cabecera `X-Redmine-API-Key` (no en el cuerpo JSON de la solicitud ni en la cadena de consulta).
- Solo se aceptan claves de usuarios activos.
- Las solicitudes sin clave o con clave inválida se rechazan.

### Permiso global MCP

- El usuario debe tener el permiso global **Use MCP** (`use_mcp`), o ser administrador de Redmine.
- El permiso `use_mcp` se activa manualmente para los roles necesarios en **Administración → Roles y permisos**.
- Los administradores siempre tienen acceso MCP: la comprobación global de permisos de Redmine permite al administrador independientemente de los roles.
- Para otros usuarios sin `use_mcp`, la solicitud se rechaza incluso con una clave API válida.

### Permisos de herramientas

- Cada herramienta tiene su propio requisito de permiso de Redmine.
- Una herramienta aparece en `tools/list` solo si el usuario tiene permiso para usarla.
- Los permisos se comprueban de nuevo al invocar la herramienta.
- Los datos se filtran por las reglas de visibilidad de Redmine (proyectos, incidencias, miembros).

### Permisos de recursos y prompts

- Los recursos y prompts pueden tener sus propios requisitos de permiso.
- Sin permiso, un recurso o prompt no se lista y no puede leerse.
- Las comprobaciones de permiso de recursos y prompts consideran el URI y los argumentos de entrada (incluidos `project` / `project_id`). Si el proyecto no se especifica en los argumentos, basta con permiso en al menos un proyecto visible.
- Una extensión puede definir una regla explícita para resolver el proyecto desde el URI y los argumentos.

## Casos límite

- Un usuario inactivo no puede usar MCP incluso con una clave emitida anteriormente.
- Un administrador tiene acceso MCP sin una asignación separada de `use_mcp`.
- Una herramienta con comprobaciones de permiso por entidad (por ejemplo, una incidencia) puede ser visible en `tools/list` con argumentos vacíos si el usuario tiene el permiso correspondiente en al menos un proyecto.
- Si dicha herramienta también requiere un módulo de proyecto de Redmine, «al menos un proyecto» significa un proyecto visible donde el usuario tiene el permiso y el módulo especificado está activado. Sin requisito de módulo, basta con permiso en al menos un proyecto visible. La presencia en `tools/list` no implica permiso para una incidencia concreta: los permisos y la disponibilidad del objeto se comprueban de nuevo en la llamada.

## Manejo de errores

| Situación | Resultado |
|----------|-----------|
| API REST desactivada | HTTP 401 |
| Clave API inválida o ausente | HTTP 401 |
| Sin permiso Use MCP | HTTP 403 |
| Sin permiso para una herramienta concreta | Herramienta ausente de `tools/list`; llamada directa — error «Permission denied» |
| Entidad no disponible para el usuario | Respuesta de herramienta con descripción de error (por ejemplo, «Issue not found») |

## Escenarios de prueba

1. Solicitud con clave válida y permiso Use MCP — acceso exitoso.
2. Solicitud sin cabecera de clave API — HTTP 401.
3. Solicitud con clave no administrador sin permiso Use MCP — HTTP 403.
4. Clave de administrador sin rol con `use_mcp` — acceso exitoso.
5. El usuario ve en `tools/list` solo las herramientas para las que tiene permiso.
6. Invocar una herramienta para una incidencia inaccesible devuelve un error, no los datos de otro usuario.
7. Una herramienta de alcance de incidencia con requisito de módulo de proyecto no es visible en `tools/list` si el usuario tiene el permiso pero no hay proyecto visible con el módulo activado; es visible si existe tal proyecto.
