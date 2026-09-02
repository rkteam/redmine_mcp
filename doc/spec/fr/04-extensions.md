# API d'extension pour d'autres plugins

[Deutsch](../de/04-extensions.md) | [English](../en/04-extensions.md) | [Español](../es/04-extensions.md) | [Français](04-extensions.md) | [Italiano](../it/04-extensions.md) | [日本語](../ja/04-extensions.md) | [한국어](../ko/04-extensions.md) | [Polski](../pl/04-extensions.md) | [Português (Brasil)](../pt-BR/04-extensions.md) | [Русский](../ru/04-extensions.md) | [中文](../zh/04-extensions.md)

## Vue d'ensemble

Redmine MCP fournit un mécanisme d'extension qui permet aux autres plugins Redmine installés d'enregistrer leurs propres outils, ressources et prompts, et d'étendre les outils existants.

## Objectif

Fournir une approche unique pour intégrer les plugins Redmine avec l'IA sans dupliquer un serveur MCP et sans modifier le code de Redmine MCP.

## Domaines concernés

- Plugins
- API
- Permissions

## Règles métier

### Découverte automatique

- Au démarrage de Redmine (lorsque MCP est activé), le système vérifie tous les plugins installés.
- Un plugin est considéré comme ayant une extension MCP s'il contient un fichier `mcp.rb` à l'un de ces chemins :
  - `lib/<plugin.id>/mcp.rb` ;
  - `lib/<plugin directory basename>/mcp.rb` ;
  - `lib/<plugin.id without redmine_ prefix>/mcp.rb` si l'identifiant commence par `redmine_` (schéma typique comme `redmine_advanced_checklists` → `lib/advanced_checklists/mcp.rb`).
- Le plugin `redmine_mcp` ne se charge pas lui-même comme extension.
- Les plugins dont la case d'extension MCP est décochée dans les paramètres sont ignorés.
- Un échec dans l'extension d'un plugin ne bloque pas le chargement des autres, y compris une erreur de syntaxe dans le fichier d'extension.

### Enregistrement des outils

- Un plugin d'extension peut enregistrer un nombre quelconque d'outils.
- Chaque outil a : nom, description, schéma d'entrée, schéma de sortie, exigence de permission et handler.
- Nom complet de l'outil : `redmine_<plugin_id>_<name>`, par exemple `redmine_redmine_advanced_checklists_get_issue_checklists`, `redmine_advanced_search_semantic_search_issues`.
- Les noms d'outils en double sont interdits.
- Un outil apparaît dans MCP uniquement pour les utilisateurs avec les permissions correspondantes.
- Un outil d'extension lié à un ticket peut exiger un module de projet Redmine activé (l'identifiant du module ne doit pas correspondre à l'id du plugin). Dans `tools/list`, un tel outil est visible si l'utilisateur a la permission déclarée dans au moins un projet visible avec ce module. Sans exigence de module, la permission dans au moins un projet visible suffit. L'appel vérifie encore le ticket spécifique : visibilité, permission dans son projet et module activé ; sinon la réponse est « not found ».
- Les outils d'écriture d'extension en mode lecture seule MCP ne exécutent pas le handler : le refus est identique aux outils d'écriture de base.

### Extension d'outils existants

- Un plugin peut étendre un outil déjà enregistré.
- Une extension peut :
  - ajouter des paramètres d'entrée supplémentaires ;
  - exécuter du code avant le handler principal ;
  - exécuter du code après le handler et modifier le résultat.
- Plusieurs plugins peuvent étendre le même outil simultanément.
- Les paramètres supplémentaires sont fusionnés dans le schéma d'entrée partagé.
- Un nom de paramètre supplémentaire ne doit pas correspondre à un paramètre d'outil de base ni à un paramètre d'une autre extension pour le même outil.
- Le schéma résultant est normalisé avant publication dans `tools/list`.
- L'ordre d'exécution des extensions correspond à l'ordre de chargement des plugins.

### Enregistrement des ressources

- Un plugin peut publier des ressources avec un URI unique. La ré-enregistrement du même URI est rejeté.
- Une ressource doit avoir un handler de lecture.
- Schéma URI recommandé : `redmine://<plugin_id>/<type>/<id>`.
- Une ressource peut exiger des vérifications de permission ; sans permission la ressource est indisponible.
- Les vérifications de permission reçoivent l'URI et les arguments. Le projet est pris depuis `project` / `project_id`, depuis l'URI (`project`/`project_id` dans la requête ou segment `/projects/:id`), ou depuis un résolveur de projet explicite défini par l'extension. `resources/read` passe `{uri: ...}` à la vérification.
- Si un projet est spécifié dans l'appel mais introuvable ou inaccessible pour l'utilisateur actuel, l'accès est refusé. La vérification « au moins un projet » s'applique uniquement lorsqu'aucun projet n'est spécifié (découverte avec arguments vides).
- La lecture d'une ressource retourne le contenu en format texte ou JSON.

### Enregistrement des prompts

- Un plugin peut ajouter des prompts avec nom, description, arguments et handler.
- Nom complet du prompt : `redmine_<plugin_id>_<name>`.
- Les prompts sont disponibles aux utilisateurs avec les permissions correspondantes. Les vérifications de permission reçoivent les arguments d'appel, y compris `project` / `project_id`. Si un projet est spécifié mais introuvable ou inaccessible, l'accès est refusé ; sans projet spécifié la même règle de découverte que pour les ressources s'applique.

### Événements (hooks)

- Un plugin peut s'abonner aux événements du cycle de vie MCP, par exemple :
  - enregistrement d'outils ;
  - enregistrement de ressources ;
  - enregistrement de prompts ;
  - fin du chargement de toutes les extensions.
- Une erreur dans un handler d'événement est journalisée et ne interrompt pas le processus principal.

### Dépendances

- Un plugin d'extension n'a pas à déclarer une dépendance stricte sur Redmine MCP.
- Il est recommandé de vérifier `RedmineMcp::ExtensionApi` / `mcp_extension_enabled?` avant l'enregistrement.
- Le plugin d'extension n'a pas besoin d'inclure le gem MCP — l'API Redmine MCP suffit.

### Capacités de l'API d'extension

Via l'API d'extension, un plugin d'extension peut :

- vérifier que MCP est activé et que l'extension n'est pas désactivée ;
- enregistrer un outil une fois (sans duplication au rechargement) ;
- enregistrer un outil lié à un ticket avec des vérifications de permission standard et recherche de ticket ; si le ticket a disparu avant l'exécution du handler, la réponse est « not found », pas une erreur interne ;
- étendre un outil de base existant avec des paramètres et des handlers before/after ;
- enregistrer des modes de capacité pour `redmine_get_mcp_info` (par exemple `issue_search.semantic`) ;
- appeler l'API REST Redmine ou plugin en processus au nom de l'utilisateur actuel via `internal_request` (`GET`, `POST`, `PUT`, `PATCH`, `DELETE` ; le point de terminaison cible doit accepter l'auth API) ; les erreurs REST sont mappées aux codes MCP canoniques sans le statut HTTP de la requête interne ;
- publier `outputSchema` au format d'enveloppe `{ ok, data | error }`.

La liste des méthodes de l'API Ruby et les exemples de code sont dans le README du plugin et dans [mcp_tool_development.md](mcp_tool_development.md) (guide dev, pas SPEC comportementale).

## Cas limites

- Un plugin sans fichier d'extension est ignoré.
- Si un fichier d'extension existe mais que `require` échoue — entrée de journal, l'extension n'est pas considérée comme chargée ; l'enregistrement d'outils est un effet secondaire d'un `require` réussi.
- Tentative d'étendre un outil inexistant — erreur lors de l'enregistrement de l'extension.
- Un plugin avec la case d'extension MCP décochée dans les paramètres n'est pas chargé même si le fichier d'extension existe.
- Après installation d'une nouvelle extension, un redémarrage de Redmine est requis ; le client MCP peut avoir besoin de se reconnecter.

## Gestion des erreurs

- Erreur de chargement du fichier d'extension — entrée de journal, continuer le chargement des autres plugins.
- Erreur d'enregistrement d'outil au démarrage — entrée de journal.
- Erreur dans un handler `before` d'extension — interrompt l'exécution de l'outil.
- Erreur dans un handler `after` — journalisée ; le résultat du handler principal est conservé sauf si le handler a modifié le flux de contrôle.

## Scénarios de test

8. La découverte de ressources et prompts avec arguments vides reste disponible si la permission existe dans au moins un projet.
9. Un plugin avec `plugin.id` comme `redmine_*` et fichier `lib/<id without redmine_ prefix>/mcp.rb` est considéré comme ayant une intégration MCP et apparaît dans les paramètres d'extension MCP.
10. Un outil lié à un ticket avec exigence de module n'est pas dans `tools/list` pour un utilisateur sans aucun projet visible avec ce module, même s'il a la permission sur un autre projet.

## Exemples d'extensions

| Plugin | Outil | Objectif |
|--------|------------|------------|
| `advanced_search` | `semantic_search_issues` | Recherche sémantique de tickets |
