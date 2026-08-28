# Authentification et autorisation

[Deutsch](../de/02-authentication.md) | [English](../en/02-authentication.md) | [Español](../es/02-authentication.md) | [Français](02-authentication.md) | [Italiano](../it/02-authentication.md) | [日本語](../ja/02-authentication.md) | [한국어](../ko/02-authentication.md) | [Polski](../pl/02-authentication.md) | [Português (Brasil)](../pt-BR/02-authentication.md) | [Русский](../ru/02-authentication.md) | [中文](../zh/02-authentication.md)

## Vue d'ensemble

L'accès à MCP utilise l'authentification standard par clé API Redmine. Toutes les opérations s'exécutent au nom de l'utilisateur propriétaire de la clé.

## Objectif

Garantir que MCP ne contourne pas la sécurité Redmine et que les utilisateurs ne peuvent effectuer que les actions qui leur sont autorisées.

## Domaines concernés

- Permissions
- API
- Utilisateurs

## Règles métier

### Authentification

- L'API REST Redmine doit être activée pour accéder à `/mcp`.
- La clé API est transmise dans l'en-tête `X-Redmine-API-Key` (pas depuis le corps de la requête JSON ni la chaîne de requête).
- Seules les clés d'utilisateurs actifs sont acceptées.
- Les requêtes sans clé ou avec une clé invalide sont rejetées.

### Permission MCP globale

- L'utilisateur doit avoir la permission globale **Use MCP** (`use_mcp`), ou être administrateur Redmine.
- La permission `use_mcp` est activée manuellement pour les rôles requis dans **Administration → Rôles et permissions**.
- Les administrateurs ont toujours l'accès MCP : la vérification standard des permissions globales Redmine autorise l'administrateur indépendamment des rôles.
- Pour les autres utilisateurs sans `use_mcp`, la requête est rejetée même avec une clé API valide.

### Permissions des outils

- Chaque outil a sa propre exigence de permission Redmine.
- Un outil apparaît dans `tools/list` uniquement si l'utilisateur a la permission de l'utiliser.
- Les permissions sont vérifiées à nouveau lors de l'appel de l'outil.
- Les données sont filtrées selon les règles de visibilité Redmine (projets, tickets, membres).

### Permissions des ressources et prompts

- Les ressources et prompts peuvent avoir leurs propres exigences de permission.
- Sans permission, une ressource ou un prompt n'est pas listé et ne peut pas être lu.
- Les vérifications de permission des ressources et prompts prennent en compte l'URI et les arguments d'entrée (y compris `project` / `project_id`). Si le projet n'est pas spécifié dans les arguments, la permission dans au moins un projet visible est suffisante.
- Une extension peut définir une règle explicite pour résoudre le projet depuis l'URI et les arguments.

## Cas limites

- Un utilisateur inactif ne peut pas utiliser MCP même avec une clé précédemment émise.
- Un administrateur a l'accès MCP sans attribution séparée de `use_mcp`.
- Un outil avec des vérifications de permission liées à une entité (par exemple, un ticket) peut être visible dans `tools/list` avec des arguments vides si l'utilisateur a la permission correspondante dans au moins un projet.
- Si un tel outil exige également un module de projet Redmine, « au moins un projet » signifie un projet visible où l'utilisateur a la permission et le module spécifié est activé. Sans exigence de module, la permission dans au moins un projet visible suffit. La présence dans `tools/list` ne signifie pas la permission pour un ticket spécifique : les permissions et la disponibilité de l'objet sont vérifiées à nouveau lors de l'appel.

## Gestion des erreurs

| Situation | Résultat |
|----------|-----------|
| API REST désactivée | HTTP 401 |
| Clé API invalide ou manquante | HTTP 401 |
| Pas de permission Use MCP | HTTP 403 |
| Pas de permission pour un outil spécifique | Outil absent de `tools/list` ; appel direct — erreur « Permission denied » |
| Entité indisponible pour l'utilisateur | Réponse d'outil avec une description d'erreur (par exemple, « Issue not found ») |

## Scénarios de test

1. Requête avec une clé valide et la permission Use MCP — accès réussi.
2. Requête sans en-tête de clé API — HTTP 401.
3. Requête avec une clé non-admin sans permission Use MCP — HTTP 403.
4. Clé administrateur sans rôle avec `use_mcp` — accès réussi.
5. L'utilisateur voit dans `tools/list` uniquement les outils pour lesquels il a la permission.
6. L'appel d'un outil pour un ticket inaccessible retourne une erreur, pas les données d'un autre utilisateur.
7. Un outil lié à un ticket avec exigence de module de projet n'est pas visible dans `tools/list` si l'utilisateur a la permission mais aucun projet visible avec le module activé ; il est visible si un tel projet existe.
