# Commandes d'installation, de vérification et de maintenance

[Deutsch](../de/console-commands.md) | [English](../en/console-commands.md) | [Español](../es/console-commands.md) | [Français](console-commands.md) | [Italiano](../it/console-commands.md) | [日本語](../ja/console-commands.md) | [한국어](../ko/console-commands.md) | [Polski](../pl/console-commands.md) | [Português (Brasil)](../pt-BR/console-commands.md) | [Русский](../ru/console-commands.md) | [中文](../zh/console-commands.md)

## Installation

```bash
bundle install
```

Après l'installation des dépendances, redémarrer Redmine.

## Vérification du point de terminaison

Vérification de l'initialisation MCP :

```bash
curl -s -X POST 'http://localhost:3000/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'MCP-Protocol-Version: 2025-11-25' \
  -H 'X-Redmine-API-Key: YOUR_API_KEY' \
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

Résultat attendu : HTTP 200, `serverInfo.name` dans la réponse est égal à `redmine_mcp`.

## Vérification de la liste d'outils

```bash
curl -s -X POST 'http://localhost:3000/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'MCP-Protocol-Version: 2025-11-25' \
  -H 'X-Redmine-API-Key: YOUR_API_KEY' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
```

## Vérification d'appel d'outil

```bash
curl -s -X POST 'http://localhost:3000/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'MCP-Protocol-Version: 2025-11-25' \
  -H 'X-Redmine-API-Key: YOUR_API_KEY' \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "redmine_list_projects",
      "arguments": { "limit": 5 }
    }
  }'
```

## Consultation des journaux

Les messages du plugin sont écrits dans le journal Rails standard avec le préfixe `[redmine_mcp]` :

```bash
tail -f log/production.log | grep redmine_mcp
```

## Maintenance

- Après modification des paramètres du plugin ou installation d'une nouvelle extension — redémarrer Redmine.
- Après ajout d'un nouvel outil MCP — reconnecter le client MCP (redémarrer Cursor ou supprimer/ajouter le serveur dans les paramètres MCP).
