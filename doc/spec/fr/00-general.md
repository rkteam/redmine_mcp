# Redmine MCP — spécification générale

[Deutsch](../de/00-general.md) | [English](../en/00-general.md) | [Español](../es/00-general.md) | [Français](00-general.md) | [Italiano](../it/00-general.md) | [日本語](../ja/00-general.md) | [한국어](../ko/00-general.md) | [Polski](../pl/00-general.md) | [Português (Brasil)](../pt-BR/00-general.md) | [Русский](../ru/00-general.md) | [中文](../zh/00-general.md)

## Vue d'ensemble

Le plugin Redmine MCP fournit un serveur MCP (Model Context Protocol) dans une installation Redmine. Les clients IA se connectent à un seul point de terminaison HTTP et accèdent aux données Redmine via des outils, des ressources et des prompts.

Le plugin inclut un ensemble de base d'outils pour travailler avec les projets, les tickets et les utilisateurs. D'autres plugins Redmine installés peuvent étendre MCP sans modifier le code de Redmine MCP.

## Objectif

Fournir un mécanisme d'intégration unique entre Redmine et les systèmes IA où :

- l'utilisateur opère dans le cadre de ses permissions Redmine ;
- les développeurs de plugins peuvent ajouter leurs propres capacités MCP ;
- aucun serveur MCP séparé ni fork spécifique à l'installation n'est requis.

## Scénarios principaux

1. **Connexion d'un client IA** — un administrateur active MCP, attribue la permission `use_mcp` aux rôles requis et émet une clé API ; l'utilisateur connecte un client (Cursor, etc.) au point de terminaison `/mcp`.
2. **Travail avec les données Redmine** — le client appelle des outils pour récupérer des projets, des tickets et des utilisateurs.
3. **Extension par d'autres plugins** — lorsqu'un plugin avec une extension MCP est installé, ses outils apparaissent automatiquement dans la liste partagée.
4. **Administration** — activation/désactivation de MCP et activation de l'intégration MCP pour des plugins individuels.

## Domaines concernés

- API (MCP over HTTP)
- Permissions
- Paramètres
- Tickets
- Projets
- Utilisateurs
- Forums
- Plugins (extensions)

## Règles métier

- MCP n'est disponible que lorsqu'il est explicitement activé dans les paramètres du plugin.
- Toutes les opérations s'exécutent au nom de l'utilisateur Redmine authentifié.
- Les écritures via MCP passent par les modèles Redmine : les callbacks de modèle s'exécutent. Les hooks de contrôleur (`controller_issues_*_save`, `controller_journals_edit_post`, etc.) ne sont pas invoqués par MCP.
- La visibilité des données suit les règles Redmine : l'utilisateur ne reçoit pas plus que ce qu'il peut voir dans l'interface web.
- Les noms d'outils et de prompts utilisent le format `<plugin_id>_<name>`, par exemple `redmine_list_projects`.
- Les `title` et `description` des outils de base sont publiés en anglais pour la sélection par les LLM et **ne sont pas localisés** via `en.yml`/`ru.yml` (exception à la norme i18n pour le catalogue d'outils MCP). Les messages d'erreur et l'interface des paramètres sont localisés.
- Les extensions d'autres plugins ne créent pas une dépendance stricte : si Redmine MCP est absent, le plugin tiers continue de fonctionner.

## Cas limites

- Lorsque MCP est désactivé, toutes les requêtes vers `/mcp` sont rejetées.
- Lorsqu'une extension échoue, les autres extensions et les outils de base continuent de fonctionner.
- Les nouveaux outils des extensions deviennent disponibles après un redémarrage de Redmine ; le client MCP peut avoir besoin de se reconnecter pour actualiser la liste d'outils.
- En mode stateless, chaque requête HTTP est traitée indépendamment ; aucune session n'est conservée entre les requêtes.

## Gestion des erreurs

- Les erreurs d'authentification et d'autorisation sont retournées au niveau HTTP.
- Les erreurs d'exécution d'outils sont retournées au format MCP avec un indicateur d'erreur.
- Les erreurs de chargement d'extensions sont journalisées et ne bloquent pas le démarrage de Redmine.

## Fichiers de spécification

| Fichier | Contenu |
|------|---------|
| [console-commands.md](console-commands.md) | Commandes d'installation, de vérification et de maintenance |
| [01-mcp-server.md](01-mcp-server.md) | Point de terminaison HTTP, protocole MCP, transport |
| [02-authentication.md](02-authentication.md) | Authentification et contrôle d'accès |
| [03-core-tools.md](03-core-tools.md) | Outils Redmine intégrés |
| [04-extensions.md](04-extensions.md) | API d'extension pour d'autres plugins |
| [05-settings.md](05-settings.md) | Paramètres du plugin et journalisation |
| [mcp_tool_development.md](mcp_tool_development.md) | Exigences de développement d'outils MCP (guide dev) |
| [extension_guide.md](extension_guide.md) | Guide du développeur d'extensions |

## Scénarios de test

1. Après installation et activation de MCP, le client exécute avec succès `initialize` et reçoit les informations du serveur.
2. Un utilisateur avec la permission Use MCP et une clé API valide voit la liste des outils disponibles pour lui.
3. Un utilisateur sans la permission Use MCP est refusé à l'accès à `/mcp`.
4. Lorsqu'un plugin d'extension est installé, ses outils sont présents dans `tools/list` pour un utilisateur avec les permissions correspondantes.
