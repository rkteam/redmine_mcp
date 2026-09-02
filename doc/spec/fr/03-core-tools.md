# Outils intégrés (outils de base)

[Deutsch](../de/03-core-tools.md) | [English](../en/03-core-tools.md) | [Español](../es/03-core-tools.md) | [Français](03-core-tools.md) | [Italiano](../it/03-core-tools.md) | [日本語](../ja/03-core-tools.md) | [한국어](../ko/03-core-tools.md) | [Polski](../pl/03-core-tools.md) | [Português (Brasil)](../pt-BR/03-core-tools.md) | [Русский](../ru/03-core-tools.md) | [中文](../zh/03-core-tools.md)

## Vue d'ensemble

Le plugin Redmine MCP fournit un ensemble d'outils pour travailler avec les projets Redmine, les tickets, le suivi du temps, le wiki, les forums, les fichiers et les données de référence (lecture et écriture).

## Objectif

Offrir aux clients IA les opérations de gestion de projet, opérations sur les tickets, suivi du temps, découverte, recherche et wiki, forums, opérations sur les fichiers et meta sans installer des plugins supplémentaires.

## Domaines concernés

- Projets
- Versions
- Membres / Rôles
- Tickets (CRUD, relations, observateurs, notes, catégories, options de formulaire, validation dry-run, requêtes sauvegardées)
- Entrées de temps
- Trackers, statuts, priorités, requêtes
- Activité de projet
- Pages wiki
- Forums / messages
- Fichiers de projet / pièces jointes
- Utilisateurs
- Permissions
- Paramètres (mode lecture seule)

## Règles métier

### Règles générales

- Nom complet de l'outil : `redmine_<name>` (par exemple `redmine_get_issue`).
- Le résultat est retourné comme enveloppe JSON dans `structuredContent` et dupliqué en texte dans `content`.
- Les données sont filtrées via la visibilité projet/ticket Redmine et les permissions.
- Le paramètre `project` est une chaîne : id numérique en chaîne (par exemple `"1"`) ou identifiant de projet (par exemple `"ecookbook"`).
- Lorsque le **mode lecture seule** est activé, les outils d'écriture retournent une erreur. Les outils en lecture seule, y compris `list_issue_relations`, `get_issue_form_options`, `validate_issue_create` et `validate_issue_update`, restent disponibles.

### Gestion de projet

| Outil | R/W | Permission |
|------|-----|------------|
| `list_projects` | R | `view_project` |
| `get_project` | R | `view_project` |
| `list_project_issue_custom_fields` | R | `view_issues` |
| `summarize_project_status` | R | `view_issues` |
| `list_project_activities` | R | `view_project` |
| `list_versions` | R | `view_issues` |
| `get_version` | R | `view_issues` |
| `create_version` | W | `manage_versions` |
| `update_version` | W | `manage_versions` |
| `delete_version` | W | `manage_versions` |
| `list_project_members` | R | `view_members` |
| `list_project_member_candidates` | R | `manage_members` |
| `list_roles` | R | `manage_members` + `project` |
| `get_project_modules` | R | `view_project` |
| `add_project_member` | W | `manage_members` |
| `update_project_member` | W | `manage_members` |
| `remove_project_member` | W | `manage_members` |

### Opérations sur les tickets

| Outil | R/W | Permission |
|------|-----|------------|
| `get_issue` | R | `view_issues` |
| `list_issues` | R | `view_issues` |
| `search_issues` | R | `view_issues` |
| `run_issue_query` | R | `view_issues` |
| `get_issue_form_options` | R | `view_issues` |
| `validate_issue_create` | R | `add_issues` |
| `validate_issue_update` | R | `edit_issues` |
| `create_issue` | W | `add_issues` |
| `update_issue` | W | attributs — s'ils sont modifiables ; `uploads` uniquement — si des pièces jointes peuvent être ajoutées |
| `add_issue_note` | W | `add_issue_notes` ; `private_notes=true` exige en plus `set_notes_private` |
| `delete_issue` | W | `delete_issues` |
| `copy_issue` | W | `copy_issues` sur le projet source et `add_issues` sur la cible |
| `list_issue_relations` | R | `view_issues` |
| `create_issue_relation` | W | `manage_issue_relations` |
| `delete_issue_relation` | W | `manage_issue_relations` |
| `list_subtasks` | R | `view_issues` |
| `add_issue_watcher` | W | `add_issue_watchers` |
| `remove_issue_watcher` | W | `delete_issue_watchers` |
| `update_issue_note` | W | l'entrée de journal est visible et modifiable (`edit_issue_notes` / `edit_own_issue_notes`) ; `private_notes` exige en plus `set_notes_private` |
| `set_issue_note_private` | W | l'entrée de journal est visible et modifiable, plus `set_notes_private` |
| `get_private_notes` | R | `view_private_notes` |
| `list_issue_categories` | R | `view_issues` |
| `create_issue_category` | W | `manage_categories` |
| `update_issue_category` | W | `manage_categories` |
| `delete_issue_category` | W | `manage_categories` |

### Utilisateurs

| Outil | R/W | Permission |
|------|-----|------------|
| `list_users` | R | `view_members` + `project` ; sans `project` — admin uniquement |
| `list_groups` | R | `manage_members` (sur n'importe quel projet) ou admin |

### Suivi du temps

| Outil | R/W | Permission |
|------|-----|------------|
| `list_time_entries` | R | `view_time_entries` |
| `create_time_entry` | W | `log_time` |
| `update_time_entry` | W | l'entrée est modifiable par l'utilisateur actuel (`edit_time_entries` / `edit_own_time_entries`) |
| `list_time_entry_activities` | R | `log_time` |
| `import_time_entries` | W | `log_time` |

`list_time_entry_activities` — catalogue des types d'activité de travail pour la saisie du temps, pas le flux d'événements du projet (`list_project_activities`).

### Découverte / énumération

| Outil | R/W | Permission |
|------|-----|------------|
| `list_trackers` | R | `view_issues` |
| `list_project_trackers` | R | `view_issues` |
| `list_issue_statuses` | R | `view_issues` |
| `list_issue_priorities` | R | `view_issues` |
| `admin_list_users` | R | admin |
| `get_current_user` | R | `use_mcp` |
| `list_queries` | R | `view_issues` |

### Recherche et wiki

| Outil | R/W | Permission |
|------|-----|------------|
| `search_all` | R | accès à au moins un des types recherchés (`view_issues` et/ou `view_wiki_pages`) |
| `list_wiki_pages` | R | `view_wiki_pages` |
| `get_wiki_page` | R | `view_wiki_pages` ; `version` historique exige en plus `view_wiki_edits` |
| `create_wiki_page` | W | `edit_wiki_pages` et la page doit être modifiable |
| `update_wiki_page` | W | `edit_wiki_pages` et la page doit être modifiable |
| `delete_wiki_page` | W | `delete_wiki_pages` et la page doit être modifiable |
| `rename_wiki_page` | W | `rename_wiki_pages` et la page doit être modifiable |

### Forums

| Outil | R/W | Permission |
|------|-----|------------|
| `list_boards` | R | `view_messages` |
| `list_board_topics` | R | `view_messages` |
| `get_board_message` | R | `view_messages` |

### Opérations sur les fichiers

| Outil | R/W | Permission |
|------|-----|------------|
| `list_project_files` | R | `view_files` |
| `upload_file` | W | `manage_files` |
| `delete_attachment` | W | `manage_files` (ou permissions du conteneur) |
| `get_attachment` | R | permissions sur le conteneur de la pièce jointe |
| `download_attachment` | R | permissions sur le conteneur de la pièce jointe |

### Meta

| Outil | R/W | Permission |
|------|-----|------------|
| `get_mcp_info` | R | `use_mcp` |

`get_mcp_info` retourne les métadonnées du plugin MCP de la session actuelle, pas la version ni les paramètres de l'application Redmine : `server_version` (version du plugin MCP), `read_only_mode`, `auth_mode`, des données brèves sur l'utilisateur actuel et `capabilities.issue_search`. L'installation de plugins tiers n'est pas listée dans la réponse : leurs outils MCP sont visibles via `tools/list` et via les `capabilities` que les extensions enregistrent elles-mêmes.

Nom complet canonique — `redmine_get_mcp_info`. L'ancien nom `get_server_info` (`redmine_get_server_info`) reste un alias appelable au moins jusqu'à la prochaine version majeure : mêmes permissions, entrée, sortie et comportement ; `tools/call` avec l'ancien nom exécute la même opération ; l'alias n'est pas publié dans `tools/list` ; les appels alias sont distinguables dans l'audit log par le nom de l'outil invoqué. Les liens depuis d'autres outils utilisent le nom canonique.

`capabilities.issue_search` contient les modes de recherche :

| Mode | Par défaut | Note |
|------|---------|------|
| `keyword` | `available: true`, outil `redmine_search_issues` | Toujours |
| `cross_resource` | `available: true`, outil `redmine_search_all` | Toujours |
| `semantic` | `available: false` | Les plugins peuvent surcharger via `register_capability(:issue_search, :semantic)` |

Lorsque `semantic.available: true`, la capacité DOIT inclure `tool`, `provider`, et `use_when` / `avoid_when` — indications brèves sur quand choisir la recherche sémantique. `Registry#apply_capabilities` normalise la réponse du provider : si le contrat est violé, `{ available: false }` est publié.

### Clarifications

- `delete_issue` sans `confirm_delete` retourne un aperçu d'impact ; s'il existe **des** sous-tâches (y compris celles invisibles pour l'utilisateur), `confirm_delete_with_children` est requis. Les compteurs dans `impact` couvrent uniquement les journaux, relations, entrées de temps, enfants et pièces jointes visibles pour l'utilisateur actuel.
- `search_issues` avec `scope=subprojects` exige `project` et recherche dans ce projet et ses descendants. Sans `project`, ce scope est une erreur de paramètre. `scope=my_project` limite la recherche aux projets où l'utilisateur est membre.
- `get_issue` : les journaux, pièces jointes, observateurs, relations, enfants et champs personnalisés sont inclus uniquement avec `include_*` explicite. Les listes imbriquées ont des `limit`/`offset` séparés et un champ `*_pagination` (journaux : limite par défaut 25, maximum 100 ; autres listes imbriquées : défaut et maximum 100). Sans le `include_*` correspondant, la liste est vide et la pagination est `null`. Les champs optionnels (`custom_fields`, `journals`, `attachments`, `watchers`, `relations`, `children`) sont toujours présents dans la réponse. Champs personnalisés — uniquement ceux visibles pour l'utilisateur actuel. Journaux — même visibilité que l'historique du ticket dans Redmine : une entrée apparaît dans `journals` et `journal_pagination` uniquement si elle a du texte ou au moins un changement de détail visible pour l'utilisateur. Un texte composé uniquement d'espaces, tabulations ou sauts de ligne est traité comme vide. Les entrées vides et celles avec uniquement des détails masqués (y compris champs personnalisés masqués) sont exclues de la liste et de `total_count` / `offset` / `has_more`. Commentaires privés — propres commentaires ou avec permission `view_private_notes`. Les éléments de journal contiennent uniquement les changements de détail visibles. Relations — uniquement les liens dont les deux côtés sont visibles pour l'utilisateur. La même règle de visibilité des relations s'applique à `list_issue_relations`.
- `get_private_notes` retourne uniquement les commentaires privés avec texte non vide (espaces, tabulations et sauts de ligne sans autre contenu comptent comme texte vide). La page est limitée par `limit`/`offset` sans charger l'historique complet du ticket.
- `list_project_issue_custom_fields` retourne les champs visibles pour l'utilisateur dans le projet. Si `tracker_id` est défini, le tracker doit appartenir au projet.
- `copy_issue` exige la permission de copier des tickets sur le projet **source** et la permission de créer des tickets sur la **cible**. Les observateurs sont copiés uniquement si l'utilisateur a la permission d'ajouter des observateurs sur le projet cible. Le lien vers l'original et la copie des pièces jointes suivent les paramètres Redmine `link_copied_issue` et `copy_attachments_on_issue_copy` (`yes` / `no` / `ask`). Sans surcharge de champs, la copie passe encore par les règles d'écriture du formulaire. Le parent du ticket source est conservé lorsque c'est permis (y compris lors d'une copie dans le même projet).
- `create_issue_relation` applique uniquement les attributs de relation autorisés et écrit le changement dans le journal du ticket. `delete_issue_relation` est autorisé uniquement si la relation peut être supprimée par l'utilisateur actuel (les deux tickets sont visibles et l'utilisateur a la permission de gérer les relations sur au moins un côté) ; la suppression est également écrite dans le journal.
- `add_project_member` / `update_project_member` acceptent uniquement les rôles que l'utilisateur actuel peut gérer dans le projet. Un rôle hors de cet ensemble est rejeté ; les rôles ne sont pas assignés partiellement.
- `create_issue_category` / `update_issue_category` : `assigned_to_id` est un ID de principal (utilisateur ou groupe), pas seulement un utilisateur.
- `delete_attachment` pour une pièce jointe de ticket suit la règle « peut-on supprimer les pièces jointes sur ce ticket » (y compris propres tickets et permissions de tracker), pas seulement `edit_issues` global. Dans `tools/list`, l'outil est visible si l'utilisateur peut supprimer au moins une pièce jointe (fichiers de projet, tickets ou wiki), pas seulement avec `manage_files` global.
- `get_wiki_page` : `attachments` est toujours dans la réponse ; par défaut `[]` et `attachments_pagination: null` ; avec `include_attachments=true` — liste paginée de pièces jointes avec `attachment_limit`/`attachment_offset` (défaut et maximum 100). `version` historique exige la permission de voir les modifications wiki. Modifier, renommer ou supprimer une page protégée exige la permission de protéger les pages wiki.
- `list_issues`, `search_issues`, `list_subtasks`, `run_issue_query` : champs résumé par défaut ; description complète via `fields` ou `get_issue`.
- Les objets demande de `get_issue`, `list_issues`, `search_issues`, `list_subtasks`, `run_issue_query`, `create_issue`, `update_issue` et `copy_issue` incluent `url` — un lien absolu vers l'UI web. L'hôte provient des paramètres Redmine « Nom d'hôte et chemin » et du protocole, comme dans les e-mails. Si « Nom d'hôte et chemin » est vide, `url` vaut `null` au lieu d'un lien incorrect. Le résumé list/search inclut `url` par défaut. Les éléments `search_all` de `type` `issues` et les `children` imbriqués de `get_issue` incluent aussi `url`. Pour citer une demande à l'utilisateur, le client copie `url` depuis le résultat du tool.
- `create_issue` et `update_issue` acceptent des **attributs** de ticket explicites (`subject`, `description`, `tracker_id`, `status_id`, `custom_fields`, etc.). Tous les attributs explicitement passés, y compris `subject` et `description` à la création, passent par les mêmes règles d'écriture que le formulaire web Redmine. Avant create/update, l'agent DEVRAIT appeler `get_issue_form_options` lorsque les valeurs de champs autorisées sont inconnues. Une valeur explicitement passée que Redmine n'a pas appliquée entraîne une erreur, pas un succès partiel.
- Si le client **n'a pas passé** `start_date` dans `create_issue` / `validate_issue_create`, et que Redmine a « date de début = date de création » activée (`default_issue_start_date_to_creation_date`), MCP définit `start_date` à aujourd'hui pour l'utilisateur — comme le formulaire de nouveau ticket. Un `start_date` explicite (y compris `null`) désactive cette substitution. `copy_issue` et `update_issue` ne substituent pas la date eux-mêmes.
- `update_issue` n'accepte pas `notes`, `private_notes` ou `watcher_user_ids`. Commentaires — `add_issue_note` ; observateurs — `add_issue_watcher` / `remove_issue_watcher`.
- `update_issue` prend également en charge `uploads` pour attacher des fichiers à un ticket. Les pièces jointes sont traitées uniquement après validation réussie des attributs (y compris `rejected_fields`). Un appel avec uniquement `uploads` (sans attributs) est autorisé si l'utilisateur peut ajouter des pièces jointes au ticket — y compris lorsque commenter est autorisé mais les attributs ne peuvent pas être modifiés. `idempotency_key` optionnel protège contre les relances après une réponse perdue (y compris ré-upload des mêmes fichiers). `journal_id` dans la réponse est l'entrée de journal pour **cet** appel, pas la dernière entrée du ticket.
- Pour effacer un champ optionnel, passer `null` pour `assigned_to_id`, `category_id`, `fixed_version_id`, `parent_issue_id`, `start_date`, `due_date` ou `estimated_hours`. Idem pour `update_version.due_date` / `wiki_page_title` et `update_issue_category.assigned_to_id`.
- `create_issue` ne prend pas en charge `uploads`.
- `update_issue` accepte `uploads[*].content_base64` et `uploads[*].filename`. Après un upload réussi, la réponse contient `added_attachments` — uniquement les fichiers de cet appel, pas la liste complète des pièces jointes du ticket. Base64 corrompu est une erreur de paramètre.
- `update_issue` accepte `status_name` et le résout vers `status_id`.
- `upload_file` accepte `content_base64` (jusqu'à 20 MiB) ; `project`, `filename` et `content_base64` sont requis.
- `get_attachment` retourne `attachment_id`, `filename`, `content_type`, `size` (filesize de la pièce jointe) et `content_url` (sans octets du fichier). Si « Nom d'hôte et chemin » est vide, `content_url` vaut `null`.
- `download_attachment` retourne `attachment_id`, `filename`, `content_type`, `size` (taille réelle du contenu en octets) et `content_base64` pour une pièce jointe visible par l'utilisateur actuel. Si MIME inconnu — `application/octet-stream`. Ne incrémente pas le compteur `downloads`. La limite de taille est 10 MiB (vérifie `File.size` sur disque avant lecture et `bytesize` après lecture) ; si dépassée — `FILE_TOO_LARGE`. Les chemins filesystem serveur ne sont pas retournés dans la réponse. `attachment_id` vient de `redmine_get_issue` / `redmine_get_wiki_page` avec `include_attachments=true`, `redmine_list_project_files` ou `redmine_get_attachment`. Pour lire, parser ou traiter une pièce jointe comme fichier, décoder `content_base64` localement. Pièces jointes inexistantes et inaccessibles retournent la même réponse « not found ».
- `create_time_entry` et les éléments de `import_time_entries.entries` exigent `hours` et soit `project` soit `issue_id`. `hours` peut être 0 ; la validité de zéro et le maximum quotidien sont vérifiés par Redmine (`timelog_accept_0_hours`, `timelog_max_hours_per_day`).
- `assigned_to_id` à la création/modification de ticket est un ID de principal (utilisateur ou groupe depuis `get_issue_form_options.assignees`) ; `null` efface l'assigné. Pour `add_issue_watcher` / `remove_issue_watcher`, l'entrée canonique est `principal_id` (utilisateur ou groupe). L'ancien `user_id` est accepté comme alias du même ID ; les deux ne peuvent pas être passés en même temps. La réponse inclut `principal_id` et un doublon `user_id` avec la même valeur. Dans les autres outils, `user_id` est un ID utilisateur. Pour l'utilisateur actuel, utiliser `assignee_ref` ou `user_ref` avec valeur `me`.
- `expected_updated_at` (optionnel) sur update/delete sensible : s'il ne correspond pas à `updated_on`, retourne `CONFLICT`.
- `idempotency_key` (optionnel) sur `create_issue`, `copy_issue`, `update_issue`, `add_issue_note`, `create_time_entry`, `import_time_entries`, `upload_file` : une relance avec la même clé et **le même ensemble d'arguments** (sauf la clé elle-même) retourne le résultat réussi en cache (TTL 24 h). La même clé avec un payload différent — `CONFLICT`, pas d'écriture en double. Pendant que la première requête est encore en cours, une relance avec la même clé ne effectue pas une autre écriture (le marqueur « en cours » vit les mêmes 24 h qu'un résultat réussi). Une entrée en cache sans empreinte (cache d'avant cette version) avec la même clé est retournée comme avant jusqu'à expiration du TTL. Le timeout serveur de 60 s s'applique aux **lectures**. Les opérations d'écriture ne sont pas interrompues par le timeout serveur afin qu'après une sauvegarde réussie le résultat d'idempotence puisse être enregistré ; le client peut relancer avec la même clé s'il a perdu la connexion. Une exception inattendue dans `import_time_entries` annule les entrées déjà insérées dans cet appel ; les erreurs de validation normales pour des lignes individuelles sont encore collectées sans annuler les réussites.
- `delete_attachment` par défaut supprime uniquement les fichiers projet/version ; pour les pièces jointes ticket/wiki, `confirm_delete_any_attachment=true` est requis. Nom complet canonique — `redmine_delete_attachment`. L'ancien nom `delete_file` (`redmine_delete_file`) reste un alias appelable au moins jusqu'à la prochaine version majeure : mêmes permissions, entrée, sortie et comportement ; `tools/call` avec l'ancien nom exécute la même opération ; l'alias n'est pas publié dans `tools/list` ; les appels alias sont distinguables dans l'audit log par le nom de l'outil invoqué. Les liens depuis d'autres outils utilisent le nom canonique.
- List/search utilisent `limit`/`offset`. Pour les requêtes DB, la page est limitée au niveau requête, pas par troncature d'une liste complète déjà chargée. Toute collection MCP paginée a un ordre stable explicite ; le dernier critère est toujours `id` pour que les pages ne sautent ni dupliquent pas des éléments.
- La recherche par sous-chaîne (`query`, `login`, `name`, et texte `search_issues`) correspond aux caractères littéralement : `%` et `_` ne sont pas des wildcards SQL.
- Limites MCP : timeout 60 s sur outils de lecture, rate limit 120 requêtes/min par utilisateur, corps HTTP requête MCP 36 MiB, taille max arguments JSON outil 32 MiB, upload base64 jusqu'à 20 MiB, download base64 jusqu'à 10 MiB. Base64 corrompu dans n'importe quel `content_base64` est une erreur de paramètre avant exécution de l'outil.
- Chaque appel d'outil, y compris refus d'accès, est écrit dans un journal d'audit structuré (outil, utilisateur, IDs cibles, résultat, durée, correlation_id) et compté dans le rate limit ; contenu base64 et notes privées ne sont pas journalisés. Les IDs cibles incluent `board_id`, `message_id`, `query_id`, `user_id`, `group_id`, entre autres.
- Chaque `outputSchema` d'outil de base décrit le niveau supérieur de `data` (pour les listes — champs des éléments `items`), pas un objet arbitraire ouvert. L'ensemble des champs du schéma correspond à la réponse réelle : `list_users` sans `created_on`, `admin_list_users` avec `created_on` ; `get_attachment` inclut `size` et `content_url`. Les champs pouvant être vides dans la réponse réelle permettent `null` (y compris `time_entry.issue`, `*_pagination` sans include, `estimation_accuracy`, `content_type` de pièce jointe). Les valeurs de champs personnalisés et `possible_values` ne sont pas limitées aux objets. `attachments_not_saved` est un tableau de noms de fichiers.
- `summarize_project_status.days` dans le schéma : défaut 30, minimum 1, maximum 365.
- `search_all.resources` : au maximum deux valeurs uniques.
- `version_id`, `file_id`, `tracker_id` sont des entiers pas inférieurs à 1.

### `get_project`

- Entrée : `project` (requis).
- Sortie : `id`, `name`, `identifier`, `description`, `homepage`, `status`, `is_public`, `inherit_members`, `created_on`, `updated_on`, `parent` (objet `id`/`name`/`identifier` ou `null`), `subprojects` (liste brève des projets enfants visibles : `id`/`name`/`identifier`), `custom_fields`, `last_activity_date`.
- `parent` est rempli uniquement si le projet parent est visible pour l'utilisateur actuel ; sinon `null`.
- Ne retourne pas les membres, modules activés ni statistiques de tickets. Pour les modules — `get_project_modules` ; pour les membres — `list_project_members` ; pour les agrégats de tickets — `summarize_project_status`.

### `get_issue_form_options`

- Un appel au lieu de plusieurs recherches de référence avant create/update. `list_project_trackers`, `list_issue_statuses`, `list_issue_priorities`, `list_issue_categories`, `list_versions`, `list_users`, `list_project_issue_custom_fields` séparés restent disponibles.
- Entrée : `project` (requis) ; optionnellement `tracker_id`, `issue_id`.
- L'instantané reflète le **formulaire de ticket pour l'utilisateur actuel**, pas la configuration complète du projet : les mêmes valeurs autorisées que l'interface Redmine offre.
- `tracker_id` sans `issue_id` définit le contexte du formulaire de création. Le tracker doit être disponible pour sélection par l'utilisateur actuel sur le formulaire ; sinon — erreur de paramètre.
- `issue_id` définit le formulaire pour un ticket existant visible dans ce projet. Avec `issue_id`, `tracker_id` est autorisé uniquement s'il correspond au tracker actuel du ticket ; sinon — erreur de paramètre (changement de tracker non modélisé via cet outil).
- Sortie — instantané de formulaire sans pagination :
  - `project` : `id`, `name`, `identifier` ;
  - `trackers` : trackers que l'utilisateur actuel peut sélectionner sur ce formulaire (`id`, `name`), pas tous les trackers activés pour le projet ;
  - `priorities` : priorités actives (`id`, `name`, `is_default`) ;
  - `categories` : catégories du projet (`id`, `name`) ;
  - `versions` : versions disponibles pour sélection sur ce formulaire (`id`, `name`, `status`, `due_date`) ;
  - `assignees` : principaux pouvant être assignés dans ce contexte de formulaire. Élément : `id`, `name`, `type` (`user` ou `group`) ; pour `user`, en plus `login`. Les groupes sont inclus si Redmine a l'assignation de tickets à des groupes activée ;
  - `custom_fields` : uniquement les champs que l'utilisateur actuel peut modifier sur le formulaire, en tenant compte projet/tracker, visibilité, lecture seule workflow. Élément : `id`, `name`, `field_format`, `required` (champ requis ou requis par workflow), `readonly` (toujours `false` dans cette liste), `multiple`, `default_value`, `possible_values`, `trackers`. Contexte de formulaire — ticket depuis `issue_id` ou brouillon de création en tenant compte de `tracker_id` ;
  - `possible_values` — tableau d'objets `{ "label": "...", "value": "..." }`. Pour les listes sans labels séparés, `label` correspond à `value`. Pour user/version/énumération, `label` est le nom affiché, `value` est l'identifiant ;
  - `statuses` : statuts autorisés par le workflow pour l'utilisateur actuel. Avec `issue_id` — transitions pour ce ticket visible. Sans `issue_id` — statuts initiaux pour création (en tenant compte de `tracker_id` si défini) ;
  - `editable_fields` : noms d'attributs que ce contrat MCP accepte sur create/update que l'utilisateur actuel peut définir sur le formulaire, plus les ids de champs personnalisés modifiables en chaînes. N'inclut pas `notes`, `private_notes`, `watcher_user_ids` et autres champs de formulaire web absents des outils d'écriture MCP ;
  - `required_fields` : noms de champs requis sur ce formulaire pour l'utilisateur actuel, dans la même forme de nom que `editable_fields`.
- `tracker_id` inexistant, tracker non autorisé pour l'utilisateur, ou `issue_id` hors projet / non visible — erreur de paramètre.

### `add_issue_note`

- Ajoute un commentaire à un ticket existant visible sans modifier les attributs du ticket.
- Entrée : `issue_id` (requis), `notes` (requis), optionnellement `private_notes`, `uploads` et `idempotency_key`.
- Permission : l'utilisateur peut ajouter des commentaires à ce ticket. `private_notes=true` exige la permission de rendre les commentaires privés ; sinon — refusé, aucun commentaire créé. Les pièces jointes dans le même appel sont autorisées si l'utilisateur peut ajouter des pièces jointes au ticket.
- N'accepte pas les champs de ticket ni les listes d'observateurs.
- Sortie : `issue_id`, `journal_id`, `notes`, `private_notes` ; avec `uploads` — `added_attachments` (uniquement fichiers de cet appel).
- Non disponible en mode lecture seule.

### `update_issue_note` / `set_issue_note_private`

- Travaillent uniquement avec une entrée de journal que l'utilisateur actuel **voit** (commentaires privés d'un autre utilisateur sans permission de voir les notes privées sont inaccessibles).
- L'entrée doit être modifiable par l'utilisateur actuel (permission de modifier les commentaires ou propres commentaires).
- `update_issue_note.notes` peut être une chaîne vide (effacement du texte d'une entrée existante). Un nouveau commentaire via `add_issue_note` ne peut pas être vide.
- Changer la confidentialité (`private_notes` / `is_private`) exige une permission séparée pour rendre les commentaires privés ; sinon refusé, le texte n'est pas partiellement modifié.
- Enregistre qui a modifié l'entrée de journal.
- Non disponible en mode lecture seule.

### `validate_issue_create` / `validate_issue_update`

- Outils en lecture seule séparés, pas un paramètre `validate_only` sur les outils d'écriture. Disponibles en mode lecture seule.
- `validate_issue_create` : mêmes champs que `create_issue`, sans `idempotency_key`. `project` et `subject` sont requis. Permission `add_issues`.
- `validate_issue_update` : dry-run pour **attributs de ticket** uniquement (comme `update_issue`, sans `uploads`). `issue_id` est requis. Le ticket doit être modifiable par l'utilisateur actuel. Avant validation, un contexte de journal utilisateur est créé sans écriture DB (comme dans une mise à jour réelle).
- Comportement : appliquer les attributs au ticket sans sauvegarder. Les données Redmine ne sont pas modifiées.
- Les attributs passent encore par les mêmes règles d'écriture que le formulaire web Redmine. Si le client **a explicitement passé** une valeur et Redmine ne l'a pas appliquée, c'est une erreur MCP, pas un succès.
- Un champ explicite hors de ceux modifiables sur le ticket (désactivé / lecture seule workflow / dates dérivées, etc.) va dans `rejected_fields`. Pour `tracker_id`, `status_id`, `assigned_to_id`, `is_private`, `parent_issue_id` et `custom_fields`, il est en plus vérifié que la valeur demandée a été réellement appliquée.
- La même règle s'applique à `create_issue`, `update_issue` et `copy_issue` : pas d'écriture si une valeur explicitement demandée n'a pas été appliquée.
- Succès : `{ "valid": true, "errors": [] }`.
- Échec : `{ "valid": false, "errors": ["..."] }`. Si certains champs explicites n'ont pas été appliqués — aussi `rejected_fields` (noms de champs, par exemple `["tracker_id"]`) et, pour erreurs typiques — `missing_required_fields` / `hint` dans la même forme que create/update.
- Capture aussi : tracker non disponible pour l'utilisateur actuel ; valeur de champ personnalisé invalide ou indisponible ; transition de statut interdite par le workflow ; assigné non disponible pour assignation.

### `list_issues` — filtres étendus

- Filtres plats existants (`project`, `status_id`, `tracker_id`, `assigned_to_id` / `assignee_ref`, `priority_id`, `fixed_version_id`, `sort`, `fields`) sont conservés.
- `filters` optionnel : tableau d'objets `{ "field": "...", "operator": "...", "values": ["..."] }`. `values` est un tableau de chaînes ; un tableau vide est autorisé pour les opérateurs sans valeurs.
- `field` autorisé : `status_id`, `tracker_id`, `assigned_to_id`, `priority_id`, `fixed_version_id`, `category_id`, `subject`, `due_date`, `start_date`, `created_on`, `updated_on`, `estimated_hours`, `done_ratio`, `author_id`, `watcher_id`, et `cf_<id>` pour les champs personnalisés de ticket.
- Les opérateurs sont les opérateurs de requête Redmine standard, y compris `=`, `!`, `>=`, `<=`, `><`, `~`, `!~`, `o`, `c`, `*`, `!*`. L'opérateur doit être valide pour le type de champ ; sinon — erreur de paramètre.
- `field` inconnu ou `operator` invalide — erreur de paramètre, la requête n'est pas exécutée.
- Filtres plats et `filters` sont combinés avec AND.
- Les filtres s'appliquent uniquement aux tickets visibles pour l'utilisateur actuel.

### `run_issue_query`

- Entrée : `query_id` (requis, depuis `list_queries`) ; optionnellement `project`, `fields`, `limit`/`offset`.
- Exécute une requête de tickets sauvegardée visible pour l'utilisateur actuel. Le format de réponse est la même enveloppe de liste que `list_issues`.
- Si la requête est liée à un projet, les résultats sont limités à ce projet (et règles de visibilité de la requête). `project` optionnel pour une requête de projet doit correspondre au projet de la requête ; sinon — erreur de paramètre.
- Si la requête est globale, `project` optionnel restreint la sélection à ce projet visible.
- `query_id` invisible ou inexistant — erreur.
- `list_queries` n'exécute pas la requête ; utiliser `run_issue_query` pour l'exécution.

### `list_project_activities`

- Il s'agit du flux d'événements du projet (« ce qui s'est passé »), pas du catalogue des types d'activité de travail pour la saisie du temps. Les types d'activité de travail — `list_time_entry_activities`.
- Entrée : `project` (requis) ; optionnellement `from`, `to` (dates `YYYY-MM-DD`), `author_id`, `event_types` (tableau de chaînes), `limit`/`offset`.
- Fenêtre par défaut — derniers 7 jours (`to` = aujourd'hui, `from` = aujourd'hui moins 6 jours). Longueur maximale de fenêtre — 90 jours ; si dépassée — erreur de paramètre.
- Événements du flux d'activité du projet : type, heure, auteur (`id`/`name`), `title`, `description`, `url`. Ordre — événements plus récents en premier ; pour temps égal — `id` plus élevé en premier.
- Enveloppe comme les autres `list_*`.
- `event_types` limite les types d'événements. Un type indisponible pour l'utilisateur ou désactivé dans le projet est exclu de la sélection (sans erreur).
- `author_id` inexistant — liste vide, pas une erreur.

### `summarize_project_status`

Ce n'est pas un objet Redmine, mais une agrégation côté serveur sur les tickets et entrées de temps visibles du projet.

Champs existants conservés : `project_id`, `project_name`, `analysis_period_days`, `recent_activity` (`created_count`, `updated_count`), `totals` (`issues_count`, `open_count`, `closed_count`), `status_breakdown`, `priority_breakdown`, `assignee_breakdown`.

La fenêtre `days` (défaut 30, plage 1–365) affecte encore `recent_activity` et les métriques de période listées ci-dessous. Une valeur hors plage est rejetée par le schéma. `totals` et breakdowns sont calculés sur tous les tickets visibles du projet sans filtre de date, via agrégation DB, sans charger tous les tickets en mémoire. Les sous-projets ne sont pas inclus.

Champs supplémentaires :

- `overdue_count` — nombre de tickets ouverts visibles avec `due_date` strictement avant aujourd'hui de l'utilisateur.
- `unassigned_count` — nombre de tickets ouverts visibles sans assigné.
- `stale_issues_count` — nombre de tickets ouverts visibles avec `updated_on` plus ancien que le début de la fenêtre `days`.
- `issues_closed_during_period` — nombre de tickets visibles avec `closed_on` dans la fenêtre `days`.
- `estimated_hours` — somme des estimations des tickets visibles du projet (`null` si aucun a une estimation, sinon un nombre incluant 0).
- `spent_hours` — somme du temps passé sur les tickets visibles du projet (0 si aucune entrée). Exige `view_time_entries` sur le projet ; sans permission le champ est `null`.
- `average_resolution_hours` — moyenne `(closed_on - created_on)` en heures pour les tickets fermés dans la fenêtre `days` ; `null` s'il n'y a pas de tels tickets.
- `estimation_accuracy` — pour les tickets fermés dans la fenêtre qui ont une estimation et du temps non nul/enregistré : `{ "issues_count", "total_estimated", "total_spent" }`. Si aucun ticket correspondant — `{ "issues_count": 0, "total_estimated": 0, "total_spent": 0 }`. Exige `view_time_entries` sur le projet ; sans permission le champ est `null`.
- `reopened_count` — nombre de tickets visibles dont le statut dans le journal a changé de fermé à ouvert dans la fenêtre `days`. Chaque ticket est compté au maximum une fois.

L'outil retourne des faits, pas une « analyse de santé du projet » textuelle.

### `list_versions` / `get_version`

`Version` dans ces outils est une entité Redmine (étape du roadmap / jalon), pas une version de produit logiciel. `list_versions` retourne les versions roadmap du projet, y compris les partagées.

### `get_version`

- Entrée : `version_id` (requis) ; optionnellement `project`. Si `project` est défini, la version est accessible lorsqu'elle est dans les versions partagées de ce projet visible (même si le projet source de la version n'est pas visible pour l'utilisateur). Sans `project`, la version doit être visible sur son projet source.
- Sortie : champs comme un élément de `list_versions` (`id`, `name`, `description`, `status`, `due_date`, `sharing`, `wiki_page_title`, `project`, `created_on`, `updated_on`) plus agrégats : `issues_count`, `open_issues_count`, `closed_issues_count`, `estimated_hours`, `spent_hours`, `completed_percent`.
- Les agrégats sont calculés uniquement sur les tickets de version visibles pour l'utilisateur actuel.
- La liste de tickets n'est pas retournée.
- `spent_hours` exige `view_time_entries` sur le projet de la version ; sans permission — `null`. Somme uniquement sur les tickets de version visibles et uniquement les entrées de temps que l'utilisateur actuel peut voir (y compris `time_entries_visibility=own`).

### Forums

- Le module forums du projet doit être activé ; sinon erreur « Boards module is not enabled for this project » (analogue wiki).
- Permission `view_messages`. Pas d'opérations d'écriture sur les forums.
- `list_boards` : `project` requis ; pagination. Élément : `id`, `name`, `description`, `parent_id` (`null` pour forum racine), `topics_count`, `messages_count`.
- `list_board_topics` : `board_id` requis ; pagination. Messages racine uniquement (sans parent). Élément : `id`, `subject`, `author`, `created_on`, `updated_on`, `replies_count`, `board_id`.
- `get_board_message` : `message_id` requis. Sortie : `id`, `subject`, `content`, `author`, `created_on`, `updated_on`, `board` (`id`/`name`), `project` (`id`/`name`/`identifier`), `parent_id`, `replies` — liste brève des réponses (`id`, `subject`, `author`, `created_on`) sans texte complet de chaque réponse, avec `replies_limit`/`replies_offset` (défaut et maximum 100) et `replies_pagination`.
- Forum/message invisible ou forum d'un autre projet — erreur « not found ».

### `list_users`

- Avec `project` : membres **utilisateurs** actifs du projet (permission `view_members`). L'appartenance à un groupe dans le projet n'apparaît pas comme groupe ; utilisateurs d'un groupe uniquement s'ils sont membres eux-mêmes. Sans `project` — administrateur uniquement.
- Élément : `id`, `login`, `firstname`, `lastname`, `mail`. N'inclut pas `created_on` (ce champ est sur `admin_list_users`).
- `query` optionnel : sous-chaîne insensible à la casse sur `login`, `firstname` et `lastname`.
- `login` optionnel est conservé (sous-chaîne login uniquement) pour compatibilité. Si `query` et `login` sont définis, les deux conditions s'appliquent (AND).

### `admin_list_users`

- Catalogue global des utilisateurs actifs de l'installation. Administrateur uniquement. Pour les membres de projet et l'affectation projet, utilisez `list_users` avec `project`.
- Entrée : optionnellement `name` (substring insensible à la casse sur login, firstname, lastname ou email), `group_id`, pagination.
- Élément : `id`, `login`, `firstname`, `lastname`, `mail`, `created_on`.
- Nom complet canonique — `redmine_admin_list_users`.
- L'ancien nom `list_all_users` (`redmine_list_all_users`) reste un alias appelable au moins jusqu'à la prochaine version majeure : mêmes permissions, entrée, sortie et comportement ; `tools/call` avec l'ancien nom exécute la même opération ; l'alias n'est pas publié dans `tools/list` ; les appels alias sont distinguables dans l'audit log par le nom de l'outil invoqué.
- Les instructions serveur et les liens depuis d'autres outils utilisent le nom canonique.

### `list_project_files`

- Liste paginée des fichiers de la section Fichiers du projet et des pièces jointes de ses versions. N'inclut pas les pièces jointes de tickets ni Wiki — lisez-les via `get_issue` / `get_wiki_page` avec `include_attachments`.
- Entrée : `project` (obligatoire), pagination. Permission `view_files`.
- Nom complet canonique — `redmine_list_project_files`.
- L'ancien nom `list_files` (`redmine_list_files`) reste un alias appelable au moins jusqu'à la prochaine version majeure : mêmes permissions, entrée, sortie et comportement ; `tools/call` avec l'ancien nom exécute la même opération ; l'alias n'est pas publié dans `tools/list` ; les appels alias sont distinguables dans l'audit log par le nom de l'outil invoqué.
- Les liens depuis d'autres outils utilisent le nom canonique.

### `list_groups`

- Liste paginée des groupes attribuables (`id`, `name`), **visibles** pour l'utilisateur actuel, pour sélectionner `group_id` dans `add_project_member`.
- `query` optionnel : sous-chaîne insensible à la casse sur le nom du groupe ; `%` et `_` sont correspondus littéralement.
- Permission : administrateur ou `manage_members` sur au moins un projet visible.
- Ne retourne pas l'appartenance aux groupes ni les memberships.

### `list_project_member_candidates`

- Candidats pour ajout au projet : utilisateurs et groupes actifs visibles pas encore dans le projet.
- Entrée : `project` (requis) ; optionnellement `query` (sous-chaîne, comme dans le sélecteur de membres Redmine).
- Enveloppe de liste de sortie : `id`, `name`, `type` (`user` ou `group`) ; pour utilisateur, en plus `login`.
- Permission `manage_members` sur le projet.
- `add_project_member` : `user_id` pour utilisateur uniquement, `group_id` pour groupe uniquement. ID de mauvais type — erreur de paramètre. Avant ajout, prendre les IDs depuis cet outil (ou depuis `list_users` / `list_groups` si le candidat est déjà connu).

### `list_roles`

- Uniquement les rôles que l'utilisateur actuel peut gérer dans le projet spécifié.
- Entrée : `project` (requis).
- Permission `manage_members` sur le projet.
- Pour administrateur, l'ensemble correspond aux rôles de projet attribuables (sans Non member / Anonymous).

## Cas limites

- Projet ou ticket inexistant/inaccessible — `{ "error": "..." }`.
- Mode lecture seule — `{ "error": "MCP is in read-only mode..." }` pour les outils d'écriture **avant** l'appel du handler, y compris les outils Extension API ; validate/form options/list/get restent disponibles.
- Résultat de liste/recherche vide — `{ "ok": true, "data": { "items": [] }, "meta": { ... } }`.
- Liste/recherche avec pagination retournent toujours `data.items` et `meta` (`total_count`, `limit`, `offset`, `has_more`, `next_offset`). Limite par défaut 25, maximum 100.
- Tous les outils `list_*` (y compris références : trackers, statuts, rôles, requêtes, forums, sujets de forum, etc.) utilisent la même enveloppe. `get_issue_form_options`, `get_project`, `get_version`, `get_board_message`, `summarize_project_status` et outils validate — objets uniques, pas enveloppe de liste.
- `download_attachment` : pièce jointe inexistante et inaccessible — même erreur « not found » ; fichier illisible sur disque — erreur ; taille sur disque ou après lecture au-dessus de 10 MiB — `FILE_TOO_LARGE` (la limite n'est pas contournée par un `filesize` DB plus petit). Même règle indiscernable « absent / pas d'accès » — pour `get_attachment`.
- `list_project_activities` : fenêtre plus longue que 90 jours — erreur de paramètre ; `from` après `to` — erreur de paramètre.
- `run_issue_query` : requête invisible — traitée comme inexistante.
- `get_issue_form_options` avec `issue_id` pour un ticket d'un autre projet — erreur de paramètre.
- `get_issue_form_options` avec `issue_id` et `tracker_id` différent du tracker de ce ticket — erreur de paramètre.
- Les outils validate ne créent pas un ticket, ne mettent pas à jour un ticket, ne créent pas des entrées de journal et ne consomment pas `idempotency_key`.
- Les écritures via MCP passent par les modèles Redmine. Les callbacks de modèle s'exécutent ; les hooks de contrôleur de l'interface web ne sont pas appelés.

## Gestion des erreurs

- Permission manquante — outil non visible dans `tools/list` ou « Permission denied ».
- Erreurs de validation de modèle — `{ "error": "<messages>" }` (pour create/update de ticket et outils validate en plus `missing_required_fields` comme noms de champs depuis les symboles d'erreur du modèle, sans parser le texte de traduction, et `hint`).
- Module wiki/forums désactivé — message d'erreur séparé, pas « not found ».
- Le code d'erreur canonique dans l'enveloppe est défini explicitement par le handler ; le code n'est pas dérivé du texte du message et ne dépend pas de la langue de l'utilisateur.

## Scénarios de test

1. `list_projects` / `list_issues` retournent enveloppe `data.items` + `meta` avec pagination.
2. `get_issue` sans `include_*` ne retourne pas journaux/pièces jointes ; avec `include_journals` — journaux avec pagination.
3. `search_issues` par texte trouve des tickets ; `search_all` inclut wiki lors de recherche sur plusieurs types.
4. `create_issue` / `update_issue` avec champs valides réussissent ; sans permission ou en lecture seule — erreur.
4a. `create_issue` sans `start_date` avec paramètre date de début activé définit la date d'aujourd'hui ; `start_date` explicite ou `null` n'est pas remplacé par ce paramètre.
5. `delete_issue` sans `confirm_delete` retourne `INVALID_STATE` et impact ; avec confirmation supprime.
6. `create_time_entry` exige `hours` et `project` ou `issue_id` ; `import_time_entries` accepte un lot.
7. `list_wiki_pages` / `get_wiki_page` / `create_wiki_page` fonctionnent avec module Wiki activé.
8. `upload_file` exige `filename` et `content_base64` ; `delete_attachment` pour pièce jointe de ticket exige confirm.
9. Utilisateur sans `use_mcp` ne passe pas l'authentification MCP ; sans permission d'outil ne le voit pas dans `tools/list`.
10. Relance `create_issue` avec le même `idempotency_key` et mêmes arguments ne crée pas un doublon ; même clé avec sujet différent — `CONFLICT`.
11. `download_attachment` pour pièce jointe de ticket visible retourne `content_base64` avec `size` du contenu réel ; pour fichier > 10 MiB sur disque (même avec métadonnées petites) — `FILE_TOO_LARGE` ; pièce jointe inexistante et inaccessible sont indiscernables.
12. `get_project` par identifiant retourne description, sous-projets et `last_activity_date` ; projet inaccessible — erreur.
13. `get_issue_form_options` pour projet retourne trackers/statuts/priorités/catégories/versions/assignés/champs personnalisés et listes `editable_fields` / `required_fields` ; `trackers` — uniquement ceux disponibles pour l'utilisateur actuel ; avec `issue_id` les statuts reflètent les transitions autorisées pour ce ticket ; `issue_id` + `tracker_id` différent — erreur ; `possible_values` — objets `label`/`value`.
14. `validate_issue_create` avec tracker ou statut invalide retourne `valid: false` et `rejected_fields`, ne crée pas le ticket ; en mode lecture seule l'appel réussit.
15. `list_issues` avec `filters` (`due_date` `<=` date, `priority_id` `!`) retourne uniquement les tickets visibles correspondants ; `field` inconnu — erreur.
16. `run_issue_query` avec `query_id` visible retourne les mêmes tickets que la requête sauvegardée dans l'UI ; requête invisible — erreur.
17. `list_project_activities` pour 3 jours retourne les événements du projet avec pagination ; fenêtre de 91 jours — erreur.
18. `summarize_project_status` inclut `overdue_count`, `unassigned_count`, `stale_issues_count`, `issues_closed_during_period` et `reopened_count`.
19. `get_version` retourne agrégats `open_issues_count` / `completed_percent` sans liste de tickets.
20. `list_boards` / `list_board_topics` / `get_board_message` fonctionnent avec module Boards activé ; lorsque désactivé — erreur de module.
21. `list_users` avec `project` et `query` par nom trouve un membre sans connaître le login.
22. `get_issue_form_options` retourne assignés avec `type` user/group et uniquement champs personnalisés modifiables avec `required`/`readonly`.
23. `create_issue` / `update_issue` / `copy_issue` / `validate_issue_create` avec valeur explicitement passée que Redmine n'applique pas (y compris champs de base désactivés/lecture seule, y compris `description` à la création) retournent erreur et ne sauvegardent pas un changement partiel.
24. `validate_issue_update` n'accepte pas les notes ; commentaire créé par `add_issue_note`. `add_issue_note` avec `add_issue_notes` réussit sans `edit_issues` ; `private_notes` sans `set_notes_private` — refusé. `update_issue` avec uniquement `uploads` réussit avec permission d'ajouter des pièces jointes sans `edit_issues`.
25. `list_groups` retourne les groupes attribuables pour utilisateur avec `manage_members`.
26. `update_issue` avec `assigned_to_id`/`category_id`/`fixed_version_id`/`parent_issue_id`/`start_date`/`due_date`/`estimated_hours` = `null` efface le champ si modifiable.
27. `update_issue_note` / `set_issue_note_private` ne modifient pas le commentaire privé d'un autre utilisateur si l'utilisateur n'a pas la permission de voir les commentaires privés.
28. Utilisateur avec permission de modifier les commentaires mais pas de les rendre privés peut changer le texte d'un commentaire public et ne peut pas changer le flag de confidentialité.
29. `add_issue_note` avec `uploads` crée commentaire et pièce jointe en un appel ; relance avec le même `idempotency_key` ne les duplique pas.
30. `update_issue` avec `uploads` et `idempotency_key` : relance avec même payload ne duplique pas la pièce jointe ; fichier différent avec même clé — `CONFLICT`. Base64 corrompu — erreur de paramètre.
31. `get_issue` ne retourne pas champs personnalisés masqués, détails de journal invisibles ni relations avec tickets invisibles. `get_version` agrège uniquement sur tickets visibles.
32. `copy_issue` sans permission de copier sur projet source — refusé, même avec `add_issues` sur cible.
33. `add_project_member` / `update_project_member` avec rôle que l'utilisateur ne peut pas gérer — refusé sans assignation partielle.
34. `create_version` / `update_version` avec `sharing` non autorisé pour l'utilisateur — refusé. `delete_version` pour version occupée — refusé sans suppression.
35. Auteur d'entrée de temps avec `edit_own_time_entries` peut mettre à jour sa propre entrée via `update_time_entry`.
36. `search_all` disponible pour utilisateur avec permission wiki sans `view_issues`, si la recherche inclut wiki.
37. `list_project_member_candidates` retourne utilisateurs et groupes pas encore dans le projet ; `add_project_member` avec `user_id` de groupe — erreur.
38. `list_roles` pour projet retourne uniquement les rôles que l'utilisateur peut gérer ; sans `project` — erreur de schéma. N'inclut pas Non member et Anonymous intégrés.
39. Relance `copy_issue` / `create_time_entry` avec le même `idempotency_key` ne crée pas un doublon ; payload différent avec même clé — `CONFLICT`.
40. `search_issues` et recherche utilisateur/groupe pour `%` ou `_` correspondent à ces caractères littéralement, pas comme wildcards.
41. `get_version.spent_hours` avec `time_entries_visibility=own` compte uniquement les entrées de temps propres.
42. `search_issues` avec `scope=subprojects` sans `project` — erreur ; avec `project` trouve des tickets dans les descendants.
43. `list_project_activities` retourne les événements plus récents avant les plus anciens.
44. Impact de `delete_issue` n'inclut pas journaux masqués, relations et entrées de temps d'autres ; sous-tâches masquées exigent encore `confirm_delete_with_children`.
45. `get_project` ne retourne pas un parent invisible pour l'utilisateur actuel.
46. `update_version` avec `due_date`/`wiki_page_title` = `null` efface le champ.
47. `update_issue_category` avec `assigned_to_id` = `null` efface l'assigné par défaut.
48. Le schéma accepte `hours` de 0 et valeurs au-dessus de 24 ; seule la validation Redmine rejette.
49. `update_issue_note` avec `notes` vide efface le texte d'un commentaire existant.
50. `list_users` avec `project` retourne uniquement des utilisateurs, même si le projet a une appartenance de groupe.
51. Version historique de page wiki sans `view_wiki_edits` est inaccessible ; page protégée ne peut pas être modifiée sans permission de protéger le wiki.
52. `copy_issue` sans permission d'ajouter des observateurs ne copie pas les observateurs ; `link_copied_issue` / `copy_attachments_on_issue_copy` = `no` interdisent lien et pièces jointes ; parent dans le même projet est conservé.
53. Outil d'écriture d'extension en mode lecture seule n'invoke pas le handler.
54. `delete_attachment` visible dans `tools/list` pour utilisateur qui peut supprimer des pièces jointes de ticket, sans `manage_files`.
55. `add_issue_watcher` / `remove_issue_watcher` acceptent le principal de groupe via `principal_id` ou l'ancien `user_id`.
56. `get_version` avec `project` retourne une version partagée que `list_versions` pour ce projet a retournée.
57. `get_issue` / `get_wiki_page` / `get_board_message` limitent les listes imbriquées avec `limit`/`offset` et retournent `*_pagination` ; sans include la pagination est `null`.
58. Les réponses réelles d'outils, y compris champs nullable, correspondent au `outputSchema` publié.
59. `get_issue` avec `include_journals` : journal avec uniquement un détail de champ personnalisé masqué n'est pas dans la liste et n'est pas compté dans `journal_pagination.total_count`.
60. Journal masqué entre deux visibles ne crée pas un gap de page : avec `journal_limit=2` deux entrées visibles sont retournées, `total_count` égale le nombre visible.
61. Commentaire privé d'un autre utilisateur n'est pas retourné dans `get_issue` sans permission `view_private_notes`.
62. `get_private_notes` retourne une page par `limit`/`offset` sans charger l'historique complet du ticket.
63. `get_issue` avec journaux `attr`, `cf` et `relation` simultanément ne échoue pas et retourne uniquement les entrées visibles.
64. Journal avec détail de champ personnalisé masqué et notes d'espaces, tabulations ou sauts de ligne n'est pas inclus dans `get_issue`.
65. `get_private_notes` ne retourne pas un commentaire composé uniquement d'espaces, tabulations ou sauts de ligne.
66. L'administrateur appelle `admin_list_users` et obtient le catalogue global ; le non-administrateur ne voit pas l'outil dans `tools/list` et reçoit un refus à l'appel.
67. Appeler l'alias `list_all_users` retourne le même résultat que `admin_list_users` ; `redmine_list_all_users` est absent de `tools/list`.
68. Appeler l'alias `list_files` retourne le même résultat que `list_project_files` ; `redmine_list_files` est absent de `tools/list`.
69. Appeler l'alias `delete_file` retourne le même résultat que `delete_attachment` ; `redmine_delete_file` est absent de `tools/list`.
70. Appeler l'alias `get_server_info` retourne le même résultat que `get_mcp_info` ; `redmine_get_server_info` est absent de `tools/list`.
