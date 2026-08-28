# Serveur MCP et point de terminaison HTTP

[Deutsch](../de/01-mcp-server.md) | [English](../en/01-mcp-server.md) | [Español](../es/01-mcp-server.md) | [Français](01-mcp-server.md) | [Italiano](../it/01-mcp-server.md) | [日本語](../ja/01-mcp-server.md) | [한국어](../ko/01-mcp-server.md) | [Polski](../pl/01-mcp-server.md) | [Português (Brasil)](../pt-BR/01-mcp-server.md) | [Русский](../ru/01-mcp-server.md) | [中文](../zh/01-mcp-server.md)

## Vue d'ensemble

Redmine MCP fournit un point de terminaison HTTP `/mcp` implémentant le MCP (Model Context Protocol) en mode Streamable HTTP sans persistance de session entre les requêtes (stateless).

## Objectif

Permettre aux clients IA externes d'interagir avec Redmine en utilisant le protocole MCP standard sans processus serveur séparé.

## Domaines concernés

- API
- Plugins

## Règles métier

- Le point de terminaison est disponible à `/mcp` par rapport à la racine de Redmine.
- Les méthodes HTTP `GET`, `POST` et `DELETE` sont prises en charge selon la spécification Streamable HTTP.
- Chaque requête est traitée dans le contexte de l'utilisateur authentifié actuel.
- Pour chaque requête, un ensemble à jour d'outils, de ressources et de prompts est construit selon les permissions de l'utilisateur.
- Le serveur annonce le nom `redmine_mcp` et une version correspondant à la version du plugin.
- La révision du protocole MCP est `2025-11-25` (en-tête `MCP-Protocol-Version` et `protocolVersion` dans `initialize`).
- Les méthodes MCP standard sont prises en charge : `initialize`, `tools/list`, `tools/call`, `resources/list`, `resources/read`, `prompts/list`, `prompts/get`, et autres fournies par la version du protocole prise en charge.
- Les réponses d'outils retournent une enveloppe JSON dans `structuredContent` (`ok`, `data` ou `error`) et une courte représentation textuelle dans `content` (chaîne JSON en cas de succès, message d'erreur en cas d'échec).
- La clé API est acceptée uniquement depuis l'en-tête `X-Redmine-API-Key`. Le corps JSON-RPC n'est pas utilisé pour l'authentification et n'est pas parsé avant la vérification de la taille de la requête.
- La taille du corps HTTP est limitée avant le parsing JSON : lorsque la limite est dépassée, la requête est rejetée et le transport MCP ne lit pas le corps.

## Cas limites

- Lorsque MCP est désactivé, le point de terminaison retourne HTTP 503 et ne traite pas les requêtes MCP.
- En mode stateless, les requêtes `GET` pour un flux SSE autonome ne sont pas prises en charge (HTTP 405) — comportement attendu.
- Lors d'un fonctionnement derrière un load balancer, les sessions persistantes ne sont pas requises.
- La liste d'outils peut différer entre les utilisateurs selon les permissions.

## Gestion des erreurs

- Requête JSON-RPC invalide — réponse d'erreur du protocole MCP.
- Erreur interne de traitement de requête — HTTP 500 avec un message d'erreur.
- Erreur d'exécution d'outil — réponse MCP avec `isError: true` et une description textuelle.
- REST interne (`InternalRequest`) : 404 → `NOT_FOUND` ; conflit de version → `CONFLICT` ; 401/403 sans conflit → `FORBIDDEN` ; tableau `errors` → `VALIDATION_ERROR`. L'enveloppe n'inclut pas le statut HTTP de la requête interne ni un message d'exception brut.
- Arguments d'outil invalides (champs requis manquants, type incorrect, propriétés supplémentaires lorsque `additionalProperties: false`, hors plage min/max) — erreur d'exécution avec `VALIDATION_ERROR` dans `structuredContent`. Le texte dans `content` correspond à `error.message` et ne contient pas les messages JSON Schema bruts.

## Scénarios de test

1. `POST /mcp` avec la méthode `initialize` retourne les capacités, `serverInfo` et `protocolVersion` `2025-11-25`.
2. `POST /mcp` avec la méthode `tools/list` retourne la liste d'outils de l'utilisateur actuel.
3. `POST /mcp` avec la méthode `tools/call` et un nom d'outil valide retourne un résultat avec `structuredContent`.
4. Une requête vers `/mcp` lorsque MCP est désactivé retourne HTTP 503.
5. L'appel d'un outil inexistant retourne une erreur « Tool not found ».
6. `tools/call` sans permission pour l'outil retourne une erreur d'exécution avec un code d'accès refusé ; l'appel est compté dans le rate limit et l'audit structuré.
7. Un corps HTTP plus grand que la limite est rejeté avant le parsing JSON.
8. Un outil d'écriture avec le mode lecture seule activé retourne une erreur via le même chemin HTTP/`tools/call`.
9. `resources/read` avec un URI pour un projet inaccessible ne retourne pas le contenu de la ressource.
10. `prompts/get` avec un argument de projet inaccessible refuse l'accès.
11. `tools/call` avec des args vides, un champ supplémentaire ou un type d'argument incorrect retourne `isError: true` et `structuredContent.error.code` `VALIDATION_ERROR`.
