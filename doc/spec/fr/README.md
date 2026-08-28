# Redmine MCP

[Site web](https://redmine-kanban.com/)

[Deutsch](../de/README.md) | [English](../en/README.md) | [Español](../es/README.md) | Français | [Italiano](../it/README.md) | [日本語](../ja/README.md) | [한국어](../ko/README.md) | [Polski](../pl/README.md) | [Português (Brasil)](../pt-BR/README.md) | [Русский](../ru/README.md) | [中文](../zh/README.md)

Un serveur MCP (Model Context Protocol) au sein de Redmine. Il permet aux clients IA de travailler avec les tickets, les projets et les utilisateurs via les permissions Redmine standard. D'autres plugins peuvent ajouter leurs propres outils, ressources, prompts et capacités sans modifier ce plugin.

## Prérequis

| Composant | Version prise en charge |
|---|---|
| Redmine | 6.0–6.1 |
| MCP protocol | 2025-11-25 |
| Ruby MCP SDK (`mcp`) | 0.23.x |

Ce plugin utilise MCP protocol `2025-11-25` et Ruby MCP SDK `0.23.x`.
La prise en charge de versions plus récentes du MCP protocol et du SDK n'est pas actuellement déclarée.

- API REST activée dans Redmine
- la gem `mcp` est déclarée dans `plugins/redmine_mcp/Gemfile` et installée avec `bundle install`

## Installation et configuration

### 1. Installer le plugin

Clonez le dépôt git dans le répertoire `plugins` de Redmine :

```bash
cd /path/to/redmine/plugins
git clone https://github.com/rkteam/redmine_mcp.git
```

Depuis la racine de Redmine, installez les dépendances et redémarrez l'application :

```bash
cd /path/to/redmine
bundle install
```

Redémarrez Redmine.

### 2. Activer dans l'administration

**Administration → Plugins → Redmine MCP → Configurer**

| Paramètre | Description |
|---------|-------------|
| Activer MCP | Active le point de terminaison `/mcp`. Lorsqu'il est activé, les extensions MCP des plugins installés sont chargées |
| Mode lecture seule | Bloque les outils d'écriture et les actions d'écriture (create/update/delete, etc.) |
| Extensions MCP | Cases à cocher pour activer l'intégration MCP des plugins installés |

### 3. API REST

**Administration → Paramètres → API** — activer « Activer l'API REST ».

### 4. Permissions

**Administration → Rôles et permissions** — pour les rôles requis, activer manuellement la permission globale **Utiliser MCP** (`use_mcp`). Les administrateurs Redmine ont toujours accès à MCP.

### 5. Clé API utilisateur

Chaque utilisateur qui travaillera via MCP doit disposer d'une clé API :

**Mon compte → Clé d'accès API** (ou via l'API REST utilisateur).

Transmettez la clé dans l'en-tête :

```
X-Redmine-API-Key: <your_key>
```

## Connexion d'un client MCP

Le serveur utilise **Streamable HTTP** (stateless). Point de terminaison :

```
https://<your-redmine>/mcp
```

Méthodes prises en charge : `GET`, `POST`, `DELETE`.

### Exemple pour Cursor

Dans les paramètres MCP (`.cursor/mcp.json` ou la configuration globale), ajoutez un serveur avec transport HTTP. Le format exact dépend de la version du client ; un exemple typique :

```json
{
  "mcpServers": {
    "redmine": {
      "url": "https://your-redmine.example.com/mcp",
      "headers": {
        "X-Redmine-API-Key": "your_api_key"
      }
    }
  }
}
```

Après la connexion, le client appellera `initialize`, puis pourra invoquer `tools/list`, `tools/call`, `resources/list`, `prompts/list`, etc.

### Vérification manuelle

```bash
curl -s -X POST 'https://your-redmine.example.com/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'MCP-Protocol-Version: 2025-11-25' \
  -H 'X-Redmine-API-Key: your_key' \
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

Une réponse réussie contient `serverInfo.name: "redmine_mcp"`.

### Hôte et proxy inverse

Le transport MCP valide HTTP `Host` et `Origin` pour se protéger contre le DNS rebinding.

L'hôte autorisé est pris dans le paramètre Redmine :

**Administration → Paramètres → Général → Nom d'hôte et chemin**

La valeur doit correspondre à l'URL publique de Redmine.

Par exemple, si Redmine est accessible à :

```
https://redmine.example.com
```

le paramètre devrait utiliser :

```
redmine.example.com
```

Si Redmine fonctionne derrière un proxy inverse, le proxy doit transmettre l'en-tête `Host` d'origine du client.

Si l'hôte ne correspond pas, le point de terminaison MCP peut renvoyer HTTP `403 Forbidden`.

Les clients sans en-tête `Origin` ne sont pas concernés par la vérification Origin.

## Outils intégrés (outils de base)

Les noms complets utilisent le format `redmine_<tool_name>` (par exemple `redmine_get_issue`).

Le serveur fournit des outils pour les projets, les tickets, les utilisateurs, le suivi du temps, le wiki, les forums et les fichiers. La liste ci-dessous est un bref aperçu des outils intégrés. Les schémas d'entrée et descriptions complets sont disponibles pour le client MCP via `tools/list`.

### Paramètres communs

- `project` — ID de projet sous forme de chaîne ou identifiant.
- `assignee_ref` / `user_ref` avec la valeur `me` — l'utilisateur actuel.
- `assigned_to_id` — utilisateur ou groupe assigné au ticket ; `null` efface les champs optionnels.
- `create_time_entry` exige `project` ou `issue_id`.
- `upload_file` exige `filename` et `content_base64`.

### Fiabilité des opérations

- `expected_updated_at` — sur les opérations sensibles de mise à jour/suppression.
- `idempotency_key` — sur `create_issue`, `copy_issue`, `update_issue`, `add_issue_note`, `create_time_entry`, `import_time_entries`, `upload_file`.

### Limites

- timeout de lecture de 60 s ;
- 120 requêtes/min par utilisateur ;
- corps HTTP de requête MCP jusqu'à 36 MiB ;
- args JSON d'outil jusqu'à 32 MiB ;
- pièces jointes en base64 jusqu'à 20 MiB ;
- téléchargements de pièces jointes jusqu'à 10 MiB.

### Déploiement en production

La limitation de débit et l'idempotence utilisent `Rails.cache`.

Pour les installations avec plusieurs workers d'application ou plusieurs instances Redmine, un magasin de cache partagé devrait être utilisé.

Avec un cache local au processus, les garanties de limitation de débit et d'idempotence ne s'appliquent qu'au sein d'un processus d'application individuel.

### Gestion de projet

| Outil | Description |
|------|-------------|
| `list_projects` | Lister les projets |
| `get_project` | Détails du projet |
| `list_project_issue_custom_fields` | Champs personnalisés de tickets du projet |
| `summarize_project_status` | Résumé de l'activité et des métriques du projet sur N jours |
| `list_project_activities` | Flux d'activité du projet |
| `list_versions` | Versions du projet |
| `get_version` | Détails de la version avec agrégats |
| `create_version` | Créer une version |
| `update_version` | Mettre à jour une version |
| `delete_version` | Supprimer une version |
| `list_project_members` | Membres du projet et leurs rôles |
| `list_project_member_candidates` | Utilisateurs et groupes pouvant être ajoutés au projet |
| `list_roles` | Rôles gérables dans le projet |
| `get_project_modules` | Modules du projet activés |
| `add_project_member` | Ajouter un membre |
| `update_project_member` | Modifier les rôles d'un membre |
| `remove_project_member` | Retirer un membre |

### Tickets

| Outil | Description |
|------|-------------|
| `get_issue` | Détails du ticket (journal, pièces jointes, champs personnalisés, etc.) |
| `list_issues` | Lister les tickets avec filtres et pagination |
| `search_issues` | Recherche textuelle sur les tickets |
| `run_issue_query` | Exécuter une requête de tickets enregistrée |
| `get_issue_form_options` | Valeurs autorisées des champs du formulaire de ticket (un seul appel) |
| `validate_issue_create` | Valider les paramètres de création de ticket sans écriture |
| `validate_issue_update` | Valider les paramètres de mise à jour de ticket sans écriture |
| `create_issue` | Créer un ticket |
| `update_issue` | Mettre à jour les attributs du ticket et les pièces jointes |
| `add_issue_note` | Ajouter un commentaire à un ticket (optionnellement avec pièces jointes) |
| `delete_issue` | Supprimer un ticket avec confirmation |
| `copy_issue` | Copier un ticket |
| `list_issue_relations` | Lister les relations de tickets |
| `create_issue_relation` | Créer une relation entre tickets |
| `delete_issue_relation` | Supprimer une relation de tickets |
| `list_subtasks` | Sous-tâches |
| `add_issue_watcher` | Ajouter un observateur |
| `remove_issue_watcher` | Retirer un observateur |
| `update_issue_note` | Modifier une entrée de journal |
| `set_issue_note_private` | Modifier la confidentialité d'une entrée de journal |
| `get_private_notes` | Commentaires privés uniquement |
| `list_issue_categories` | Catégories de tickets du projet |
| `create_issue_category` | Créer une catégorie |
| `update_issue_category` | Mettre à jour une catégorie |
| `delete_issue_category` | Supprimer une catégorie |

### Utilisateurs

| Outil | Description |
|------|-------------|
| `list_users` | Membres du projet ; filtres `query` (nom/login) et `login` ; la recherche globale est réservée aux administrateurs |
| `list_groups` | Groupes givable pour `group_id` dans `add_project_member` |

### Suivi du temps

| Outil | Description |
|------|-------------|
| `list_time_entries` | Lister les entrées de temps |
| `create_time_entry` | Créer une entrée de temps |
| `update_time_entry` | Mettre à jour une entrée de temps |
| `list_time_entry_activities` | Types d'activité (globaux ou par projet) |
| `import_time_entries` | Import en masse d'entrées de temps |

### Données de référence

| Outil | Description |
|------|-------------|
| `list_trackers` | Tous les trackers |
| `list_project_trackers` | Trackers du projet |
| `list_issue_statuses` | Statuts de tickets |
| `list_issue_priorities` | Priorités de tickets |
| `list_all_users` | Utilisateurs avec filtres (administrateur uniquement) |
| `get_current_user` | Utilisateur actuel |
| `list_queries` | Requêtes enregistrées (métadonnées ; l'exécution passe par `run_issue_query`) |

### Recherche et wiki

| Outil | Description |
|------|-------------|
| `search_all` | Rechercher dans les tickets et les pages wiki |
| `list_wiki_pages` | Pages wiki du projet |
| `get_wiki_page` | Obtenir une page wiki |
| `create_wiki_page` | Créer une page wiki |
| `update_wiki_page` | Mettre à jour une page wiki |
| `delete_wiki_page` | Supprimer une page wiki |
| `rename_wiki_page` | Renommer une page wiki |

### Forums

| Outil | Description |
|------|-------------|
| `list_boards` | Tableaux du forum du projet |
| `list_board_topics` | Sujets du tableau sélectionné |
| `get_board_message` | Message du forum avec réponses brèves |

### Fichiers

| Outil | Description |
|------|-------------|
| `list_files` | Fichiers du projet |
| `upload_file` | Téléverser un fichier |
| `delete_file` | Supprimer un fichier ou une pièce jointe |
| `get_attachment` | Métadonnées de la pièce jointe et `content_url` |
| `download_attachment` | Contenu de la pièce jointe (`content_base64`, jusqu'à 10 MiB) |

### Utilitaires

| Outil | Description |
|------|-------------|
| `get_server_info` | Version du serveur, mode lecture seule, utilisateur actuel et capacités disponibles |

### Accès et réponses

Les outils renvoient une enveloppe JSON dans `structuredContent` et une représentation textuelle dans `content`.

Les opérations d'écriture sont bloquées par le paramètre **Mode lecture seule**.

En plus des permissions spécifiques à chaque outil, la permission globale **Utiliser MCP** est toujours vérifiée.

L'accès aux données est appliqué via les permissions Redmine standard et les règles de visibilité. Pour les données de projets et de tickets, `Project.visible` et `Issue.visible` sont utilisés.

## Extensions d'autres plugins

Tout plugin Redmine installé peut ajouter ses propres outils MCP et, si nécessaire, enregistrer des ressources, des prompts et des capacités.

Guide détaillé : [extension_guide.md](extension_guide.md).

Pour le développement assisté par IA dans Cursor ou des agents similaires, copiez le répertoire skill fourni [`redmine-mcp-plugin-integration`](../../skills/redmine-mcp-plugin-integration/) dans le dossier skills de votre agent, ou utilisez-le comme base pour votre propre skill.

## Journalisation

Les messages sont écrits dans le journal Rails standard avec le préfixe `[redmine_mcp]` :

- chargement des extensions
- enregistrement des outils/ressources/prompts
- erreurs d'enregistrement et d'exécution
- refus d'accès

## Dépannage

| Symptôme | Cause possible |
|---------|----------------|
| HTTP 503 « MCP is disabled » | MCP n'est pas activé dans les paramètres du plugin |
| HTTP 401 | Clé API manquante ou invalide ; l'API REST est désactivée |
| HTTP 403 (permission) | L'utilisateur n'a pas la permission **Utiliser MCP** |
| HTTP 403 (`Host`/`Origin`) | **Nom d'hôte et chemin** ne correspond pas à l'URL publique de Redmine ; le proxy inverse ne transmet pas le `Host` d'origine ; l'URL MCP dans le client ne correspond pas — le transport rejette les hôtes inconnus (protection DNS rebinding) |
| L'outil n'est pas visible dans `tools/list` | Permissions requises manquantes ; l'extension qui fournit l'outil est désactivée |
| Les nouveaux outils n'ont pas apparu après un rechargement MCP | Dans Cursor et clients similaires, recharger le serveur peut ne pas actualiser la liste d'outils — redémarrez complètement l'application |
| L'extension ne se charge pas | Fichier `lib/.../mcp.rb` manquant ; le module ne fait pas `extend RedmineMcp::ExtensionApi` ; assurez-vous que la case de l'extension est activée sous **Extensions MCP** ; en cas d'erreur dans le fichier, consultez le journal |
| `Issue not found` / `Project not found` | Le ticket ou le projet n'est pas visible pour l'utilisateur actuel selon les règles de visibilité Redmine |

## Licence

Ce plugin est distribué sous la GNU General Public License,
version 2 ou toute version ultérieure.

Voir [LICENSE](../../../LICENSE) pour plus de détails.
