# Configuración y registro

[Deutsch](../de/05-settings.md) | [English](../en/05-settings.md) | [Español](05-settings.md) | [Français](../fr/05-settings.md) | [Italiano](../it/05-settings.md) | [日本語](../ja/05-settings.md) | [한국어](../ko/05-settings.md) | [Polski](../pl/05-settings.md) | [Português (Brasil)](../pt-BR/05-settings.md) | [Русский](../ru/05-settings.md) | [中文](../zh/05-settings.md)

## Descripción general

El plugin Redmine MCP se configura mediante la interfaz estándar de configuración de plugins de Redmine. El funcionamiento de MCP se registra adicionalmente.

## Objetivo

Dar al administrador control sobre la habilitación de MCP y la integración MCP para plugins individuales.

## Áreas afectadas

- Configuración
- Interfaz de usuario
- Plugins

## Reglas de negocio

### Parámetros de configuración

La configuración está disponible en **Administración → Plugins → Redmine MCP → Configurar**.

| Parámetro | Valor por defecto | Descripción |
|----------|--------------|----------|
| Enable MCP | desactivado | Habilita o deshabilita el endpoint `/mcp`. Cuando está habilitado, las extensiones MCP de los plugins instalados se cargan automáticamente |
| Read-only mode | desactivado | Bloquea herramientas de escritura y acciones de escritura |
| MCP extensions | todas habilitadas | Casillas junto a los nombres de plugins instalados con integración MCP |

### Extensiones MCP en la interfaz

- No se usa un campo de texto para una lista de identificadores («Disabled extensions») ni una lista de referencia de todos los plugins instalados.
- No se usa una casilla separada de carga automática de extensiones.
- En su lugar, la página de configuración muestra una lista de plugins instalados que tienen integración MCP.
- Un plugin se considera con integración MCP si se encuentra una fuente de extensión según la convención de carga automática: `mcp.rb` en el plugin o el archivo integrado `lib/redmine_mcp/extensions/<plugin.id>.rb` en `redmine_mcp` (véase [04-extensions.md](04-extensions.md)).
- El plugin `redmine_mcp` no aparece en esta lista.
- Cada elemento tiene una casilla y el nombre del plugin.
- La leyenda de la lista tiene un conmutador Marcar todo / Desmarcar todo, como en proyectos y trackers en un formulario de campo personalizado.
- Una casilla marcada significa que la extensión MCP del plugin se carga cuando MCP está habilitado.
- Una casilla desmarcada significa que la extensión del plugin no se carga aunque exista el archivo de extensión.
- Si ningún plugin instalado tiene integración MCP, la lista está vacía: se muestra el mensaje estándar de Redmine «no data»; el conmutador Marcar todo / Desmarcar todo está oculto.
- Los identificadores de plugins deshabilitados guardados previamente siguen aplicándose: las casillas correspondientes aparecen desmarcadas.

### Comportamiento al cambiar la configuración

- Deshabilitar MCP bloquea inmediatamente todas las solicitudes a `/mcp` (HTTP 503).
- Cuando MCP está habilitado, las extensiones se cargan al arrancar Redmine. Cuando MCP está deshabilitado, no se ejecuta la carga automática de extensiones.
- Cambiar las casillas de extensiones MCP surte efecto tras reiniciar Redmine.

## Registro

### Qué se registra

- inicio y fin de la carga de extensiones;
- registro correcto de herramientas, recursos, prompts;
- ampliación de herramientas existentes;
- errores de registro y carga de extensiones;
- errores de ejecución de herramientas;
- denegaciones de acceso a MCP y a herramientas.

### Formato

- Los mensajes se escriben en el registro estándar de Rails.
- Cada mensaje tiene el prefijo `[redmine_mcp]`.
- No se usa un ajuste de nivel de registro aparte: el plugin escribe todos sus mensajes.

## Casos límite

- Si todas las casillas de extensiones MCP están habilitadas (o ningún plugin tiene integración), se cargan todas las extensiones encontradas cuando MCP está habilitado.
- Un plugin sin extensión MCP (ni `mcp.rb` ni integración integrada) no aparece en la lista y no se deshabilita por esta configuración.
- Si un plugin adquiere después integración MCP, su casilla está habilitada por defecto salvo que el plugin estuviera deshabilitado previamente.
- Los identificadores de plugins desconocidos o eliminados en listas de deshabilitados guardadas se ignoran.
- Se ignora una bandera de carga automática de extensiones guardada previamente: la carga de extensiones depende de Enable MCP.
- Se ignora y elimina un nivel de registro guardado previamente al guardar la configuración.
- Con el modo de solo lectura habilitado, las herramientas de escritura siguen en `tools/list` (si el usuario tiene permisos) pero devuelven un error al invocarlas; las acciones de lectura de herramientas combinadas siguen funcionando.

## Manejo de errores

- Los errores de configuración no deben bloquear el arranque de Redmine.
- Los errores de registro no afectan al procesamiento de solicitudes MCP.

## Escenarios de prueba

1. MCP deshabilitado — las solicitudes a `/mcp` devuelven HTTP 503.
2. MCP habilitado — las solicitudes se procesan.
3. Un plugin con integración MCP desmarcado — sus herramientas están ausentes tras el reinicio.
4. La página de configuración no tiene campo de nivel de registro; los mensajes MCP se escriben en el registro de Rails.
5. La página de configuración muestra nombres solo de plugins instalados con integración MCP; cada uno tiene una casilla.
6. Un plugin sin integración MCP no aparece en la página de configuración.
7. Cuando MCP está deshabilitado, las extensiones de otros plugins no se cargan al arrancar.
