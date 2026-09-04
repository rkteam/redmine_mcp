# Extensions MCP pour les plugins Redmine

[Deutsch](../de/extension_guide.md) | [English](../en/extension_guide.md) | [Español](../es/extension_guide.md) | [Français](extension_guide.md) | [Italiano](../it/extension_guide.md) | [日本語](../ja/extension_guide.md) | [한국어](../ko/extension_guide.md) | [Polski](../pl/extension_guide.md) | [Português (Brasil)](../pt-BR/extension_guide.md) | [Русский](../ru/extension_guide.md) | [中文](../zh/extension_guide.md)

`redmine_mcp` permet aux autres plugins Redmine d'ajouter leurs propres outils MCP et, si nécessaire, d'enregistrer des ressources, des prompts et des capacités sans serveur MCP séparé et sans modifications de `redmine_mcp` lui-même.

## Fonctionnement

`redmine_mcp` fournit un Registry MCP partagé où les plugins Redmine tiers enregistrent des outils via `RedmineMcp::ExtensionApi`.

Un appel typique se déroule ainsi :

```text
client → tools/list
client → tools/call {name, arguments}
        → Registry validates arguments against the schema
        → checks permission
        → invokes the handler
        → builds the standard MCP response
```

`redmine_mcp` ne doit pas connaître la logique métier d'un plugin tiers : le plugin enregistre ses propres outils via l'API d'extension.

## Stabilité et rétrocompatibilité

Depuis `redmine_mcp 1.0.0`, l'API d'extension publique est considérée comme stable.

Seules les méthodes et contrats de `RedmineMcp::ExtensionApi` décrits dans ce guide sont l'API publique. Les classes, modules et méthodes internes de `redmine_mcp` qui ne sont pas documentés comme partie de l'API d'extension ne sont pas l'API publique et peuvent changer sans garanties de rétrocompatibilité.

Dans une même version majeure de `redmine_mcp` :

- les méthodes existantes de l'API d'extension publique ne sont pas supprimées ni modifiées de manière incompatible ;
- de nouvelles méthodes et paramètres optionnels peuvent être ajoutés ;
- les méthodes obsolètes sont marquées d'abord et restent disponibles au moins jusqu'à la prochaine version majeure ;
- les changements qui nécessitent des mises à jour dans les plugins tiers sont publiés uniquement dans une nouvelle version majeure.

Tous les changements de l'API d'extension sont listés dans `CHANGELOG.md`.

Les plugins tiers sont recommandés de déclarer la version minimale de `redmine_mcp` requise et de consulter `CHANGELOG.md` lors des mises à niveau.

## Démarrage rapide

1. Créer un fichier `mcp.rb` à l'un de ces chemins :
   - `lib/<plugin.id>/mcp.rb`
   - `lib/<plugin_directory_basename>/mcp.rb`
   - `lib/<plugin.id without the redmine_ prefix>/mcp.rb` si `plugin.id` commence par `redmine_`
2. Définir le module `<PluginName>::Mcp`.
3. Étendre `RedmineMcp::ExtensionApi`.
4. Définir `plugin_id`.
5. Enregistrer le premier outil.

Exemple minimal d'extension liée à un ticket :

```ruby
module RedmineMyPlugin
  module Mcp
    extend RedmineMcp::ExtensionApi

    plugin_id :my_plugin

    register_issue_tool(
      name: 'get_plugin_data',
      title: 'Get plugin data',
      description: 'Returns plugin data for an issue.',
      output_schema: RedmineMcp::SchemaNormalizer.envelope_output(
        type: 'object',
        properties: {
          issue_id: {type: 'integer', minimum: 1}
        },
        required: ['issue_id']
      ),
      permission: :view_issues,
      annotations: RedmineMcp::Core::Helpers::READ_ONLY_ANNOTATIONS
    ) do |issue, _args, _context|
      {issue_id: issue.id}
    end
  end
end
```

L'exemple utilise `register_issue_tool`, l'helper recommandé pour les outils qui travaillent avec des tickets. Le contrat complet de l'outil est dans [mcp_tool_development.md](mcp_tool_development.md).

### Le nom du module `Mcp`

Le fichier d'extension est `mcp.rb`. Zeitwerk déduit `Mcp` de ce nom de fichier, donc écrire `module Mcp`.

Les outils sont enregistrés lorsque le fichier est requis. Le chargeur ne recherche pas le nom de constante du module.

## Nommage

Pour les outils et prompts, utiliser un nom court :

```ruby
name: 'search_issues'
```

Le nom MCP complet est généré automatiquement :

```text
redmine_<plugin_id>_<name>
```

Pour les outils, préférer `name` au format `<verb>_<entity>`.

Verbes préférés :

`get`, `list`, `search`, `create`, `update`, `set`, `delete`, `add`, `remove`, `copy`, `upload`, `download`, `send`, `summarize`.

Ne pas utiliser des `manage_*`, `process_*`, `handle_*` vagues, ni des outils avec un paramètre comme `action: create | update | delete` lorsque les opérations peuvent être séparées en outils distincts et clairs.

Par exemple :

```text
plugin_id :advanced_search
name: 'semantic_search_issues'

-> redmine_advanced_search_semantic_search_issues
```

Si `plugin_id` commence déjà par `redmine_` (par exemple `redmine_advanced_checklists`), le nom complet suit encore `redmine_<plugin_id>_<name>` : `redmine_redmine_advanced_checklists_<name>`.

Pour les ressources, utiliser un URI unique, par exemple :

```text
redmine://<plugin_id>/<type>/<id>
```

Les noms d'outils/prompts et les URI de ressources doivent être uniques. Le comportement de double enregistrement dépend de la méthode utilisée ; `register_tool_once` n'enregistre pas le même outil deux fois.

## Enregistrement des outils

### Outil ordinaire

Utiliser `register_tool_once` lorsqu'un outil MCP ordinaire non lié à un ticket spécifique est nécessaire.

Cas typiques :

- recherche de données du plugin ;
- retour d'un résumé ;
- validation ou calcul côté serveur.

Exemple de base :

```ruby
register_tool_once(
  name: 'get_summary',
  title: 'Get plugin summary',
  description: 'Returns plugin summary.',
  input_schema: {
    type: 'object',
    additionalProperties: false,
    properties: {}
  },
  output_schema: RedmineMcp::SchemaNormalizer.envelope_output(
    type: 'object',
    additionalProperties: false,
    properties: {
      summary: {type: 'string'}
    },
    required: ['summary']
  ),
  permission: :view_issues,
  annotations: RedmineMcp::Core::Helpers::READ_ONLY_ANNOTATIONS,
  handler: lambda { |_args, _context| {summary: 'ok'} }
)
```

Le contrat complet de l'outil — `additionalProperties: false`, annotations de risque et enveloppe via `SchemaNormalizer.envelope_output` — est décrit dans [mcp_tool_development.md](mcp_tool_development.md).

### Outil lié à un ticket

Utiliser `register_issue_tool` lorsque l'outil accepte `issue_id` et travaille avec un ticket.

C'est l'option recommandée pour les scénarios liés à un ticket car elle :

- trouve le ticket via `Issue.visible(user)` ;
- vérifie le module de projet si nécessaire ;
- vérifie la permission donnée dans le projet du ticket ;
- passe le `issue` trouvé au bloc ;
- retourne une erreur si le ticket est indisponible ou introuvable.

Voir aussi la section Permissions.

`module_name` dans `register_issue_tool` est un identifiant optionnel de module de projet Redmine. Il ne doit pas correspondre à `plugin_id`. S'il est défini, l'outil apparaît dans `tools/list` uniquement lorsque l'utilisateur peut voir au moins un projet avec ce module et la permission déclarée.

### Ce que le handler retourne

Le handler retourne un hash de données de succès sans enveloppe, ou une enveloppe prête `{ok: true, data: ...}` / `{ok: false, error: ...}`. Le Registry normalise le résultat via `ToolResponse.from_handler_result` : un hash simple est enveloppé dans `{ok: true, data: ...}` ; pour les listes vous pouvez retourner le résultat prêt de `paginated_list`, qui contient déjà `data` et `meta`.

Pour les erreurs, utiliser `RedmineMcp::Core::Helpers.error_result`, `mcp_error`, ou `{ok: false, error: ...}`.

## Input schema

`SchemaNormalizer.normalize_input` normalise le schéma objet et ajoute des contraintes de service, mais le contrat public des paramètres doit être décrit explicitement.

Règles principales :

- chaque paramètre doit avoir un type défini ;
- les champs numériques `*_id` utilisent `type: integer`, `minimum: 1`, et une description avec un chemin de découverte ;
- les ensembles de valeurs finis sont définis via `enum` / `const`, pas seulement en prose ;
- les tableaux doivent avoir `items` ;
- les champs interdépendants et mutuellement exclusifs sont définis via JSON Schema (`oneOf`, `if/then/else`, etc.), pas seulement dans la description ;
- le verrouillage optimiste utilise `expected_updated_at`, pas `updated_at` ;
- `null` est utilisé uniquement avec une sémantique explicitement documentée, par exemple pour effacer un champ ;
- ne pas utiliser des `fields`, `payload` ou `data` ouverts au lieu de paramètres métier typés ;
- ne pas accepter un objet comme chaîne JSON ;
- ne pas accepter un `file_path` arbitraire dans un outil public.

Les exigences complètes de `inputSchema` sont dans [mcp_tool_development.md](mcp_tool_development.md).

## Output schema

Chaque nouvel outil doit avoir un `output_schema`.

Pour un résultat ordinaire, utiliser l'enveloppe standard :

```ruby
RedmineMcp::SchemaNormalizer.envelope_output(
  type: 'object',
  properties: {
    summary: {type: 'string'}
  },
  required: ['summary']
)
```

Pour les listes, utiliser `SchemaNormalizer.list_envelope_output(item_schema)`.

Les champs de résultat stables connus doivent être décrits explicitement. Ne pas utiliser `REST_OBJECT_SCHEMA` / `REST_ARRAY_SCHEMA` au lieu d'un contrat typé lorsque la structure de réponse est connue. Ces schémas sont acceptables uniquement pour des structures vraiment ouvertes ou instables.

Les exigences complètes de `outputSchema` sont dans [mcp_tool_development.md](mcp_tool_development.md).

## Annotations

| Type d'opération | read_only | destructive | idempotent | open_world |
|---|---|---|---|---|
| get / list / search | `true` | `false` | `true` | `false` |
| create / add | `false` | `false` | `false` | `false` |
| update / rename / set | `false` | `false` | dépend de l'implémentation | `false` |
| delete / purge | `false` | `true` | uniquement si une répétition est réellement sûre | `false` |
| effet externe | `false` | dépend | généralement `false` | `true` |

`destructive` signifie une perte de données irréversible, pas n'importe quelle écriture.

`open_world` signifie aller au-delà de l'installation Redmine connue, pas créer un nouvel objet dans Redmine.

Les annotations ne remplacent pas les vérifications de permission dans le handler.

## Permissions

`permission` est utilisé par le Registry pour la disponibilité de l'outil et les vérifications préliminaires, mais ne remplace pas les vérifications d'accès à un objet spécifique dans le handler.

Pour les outils liés à un ticket, utiliser `register_issue_tool`, qui vérifie la visibilité du ticket, le module de projet et la permission.

Pour d'autres entités, le handler doit revérifier l'accès à l'objet trouvé.

## Erreurs

Utiliser les codes d'erreur MCP standard :

`VALIDATION_ERROR`, `NOT_FOUND`, `FORBIDDEN`, `CONFLICT`, `RATE_LIMITED`, `REDMINE_API_ERROR`, `TIMEOUT`, `FILE_TOO_LARGE`, `UNSUPPORTED_MEDIA_TYPE`, `INVALID_STATE`, `PARTIAL_FAILURE`, `INTERNAL_ERROR`.

Pour les erreurs standard, utiliser les helpers `error_result`.
Pour un code personnalisé, utiliser `mcp_error`.
Pour le verrouillage optimiste, utiliser `conflict_if_stale`.

Le handler retourne une erreur structurée, pas une trace de pile ou une exception non gérée.

## Helpers intégrés

`RedmineMcp::Core::Helpers` contient des helpers partagés à réutiliser plutôt que dupliquer :

- `find_project`
- `any_project_allows?`
- `resolve_user_ref`
- `clamp_limit` / `clamp_offset`
- `paginated_list` / `paginate_collection`
- `integer_id`
- `serialize_named_ref`
- `error_result`
- `mcp_error`
- `model_errors`
- `conflict_if_stale`
- `truthy?`

Des fragments de schéma prêts à l'emploi sont également disponibles :

- `PROJECT_SCHEMA`
- `USER_ID_SCHEMA`
- `USER_REF_SCHEMA`
- `ISSUE_ID_SCHEMA`
- `PAGINATION_INPUT`
- `EXPECTED_UPDATED_AT_SCHEMA`
- `IDEMPOTENCY_KEY_SCHEMA`

Avant de créer votre propre helper, vérifier si un helper approprié existe déjà dans `redmine_mcp`.

Consultez l'ensemble actuel de helpers dans `RedmineMcp::Core::Helpers` et [04-extensions.md](04-extensions.md) : cette liste montre les capacités principales disponibles et ne remplace pas la documentation API de ExtensionApi.

## Mode lecture seule et idempotence

Les outils mutants doivent respecter le mode lecture seule global :

```ruby
blocked = RedmineMcp::Core::ReadOnly.guard_write!
return blocked if blocked
```

Pour les opérations où un appel répété peut créer un doublon, vous pouvez utiliser `idempotency_key` et `RedmineMcp::IdempotencyStore`.

`idempotentHint: true` est autorisé uniquement lorsqu'un appel répété est réellement sûr en tenant compte de tous les effets secondaires.

## Organisation du code

`mcp.rb` doit contenir principalement l'enregistrement d'outils : schémas, descriptions, permissions, annotations et handlers courts.

La récupération, l'agrégation et la normalisation de données spécifiques à MCP peuvent être déplacées vers :

- `mcp_tools.rb` ;
- lorsque le fichier grossit — `mcp_tools/*.rb`.

La logique métier ordinaire doit rester dans les modèles/services du plugin et ne doit pas dépendre de MCP.

Si le plugin a déjà un point de terminaison REST approprié qui implémente l'opération nécessaire et prend en charge les appels au nom de l'utilisateur actuel, vous DEVRIEZ le réutiliser via `internal_request` (ou `internal_get` pour les appels `GET` en lecture seule).

C'est l'option préférée : MCP utilise les mêmes vérifications de permission, la récupération de données et le comportement métier que l'API existante du plugin.

```ruby
result = internal_request(
  method: 'POST',
  path: '/my_plugin/items.json',
  user: context[:user],
  body: JSON.generate(item: {name: args[:name]})
)
return result if internal_request_error?(result)
```

Pour `POST`, `PUT` et `PATCH`, passer une chaîne de corps de requête JSON (ou `nil` lorsque le point de terminaison n'attend pas un corps). Les paramètres de requête passent dans `params`.

Appeler un modèle/service directement lorsque :

- il n'existe pas de point de terminaison REST approprié ;
- le point de terminaison ne prend pas en charge l'opération ou les données nécessaires ;
- l'utilisation de REST crée une couche inutile ou incorrecte pour l'opération ;
- la logique métier partagée est déjà intentionnellement extraite dans un service et le point de terminaison REST n'est qu'un wrapper fin autour de ce service.

Ne pas implémenter la même logique métier séparément pour REST et MCP. Si les deux couches ont besoin de logique partagée, l'extraire dans un service commun.

## Capacités supplémentaires

`RedmineMcp::ExtensionApi` fournit également :

| Méthode | Quand l'utiliser |
|---|---|
| `register_resource` | vous avez besoin d'une ressource MCP |
| `register_prompt` | vous avez besoin d'un prompt MCP |
| `register_capability` | vous devez ajouter une capacité à `redmine_get_mcp_info` |
| `extend_tool` | vous devez étendre un outil existant plutôt que créer un nouveau |
| `on` | vous avez besoin d'un hook de cycle de vie |
| `internal_request` | vous devez appeler un point de terminaison REST Redmine ou plugin en processus en tant qu'utilisateur actuel (`method`, `path`, `params` et `body` optionnels) |
| `internal_get` | raccourci pour `internal_request(method: 'GET', ...)` |
| `internal_request_error?` | vérifier si un résultat REST en processus est une enveloppe d'erreur MCP |

Définir `plugin_id` une fois en haut du module. Avant d'enregistrer des outils, vous DEVRIEZ vérifier `mcp_extension_enabled?` lorsque l'enregistrement est effectué par l'extension elle-même. Le `ExtensionLoader` standard ne charge pas non plus `mcp.rb` pour les extensions désactivées.

### Étendre un outil existant

Utiliser `extend_tool` uniquement lorsqu'un outil séparé n'est pas approprié.

```ruby
extend_tool(
  'redmine_search_issues',
  extra_params: {
    semantic_hint: {
      type: 'string',
      description: 'Optional semantic hint for ranking.'
    }
  }
)
```

`before` s'exécute avant le handler, `after` s'exécute après. `extra_params` sont ajoutés au schéma d'entrée. Les noms de paramètres ne doivent pas entrer en conflit avec l'outil de base ni avec d'autres extensions de cet outil.

Si l'extension est requise depuis `after_initialize` d'un plugin avant que `redmine_mcp` enregistre les outils de base, différer `extend_tool` pour un outil de base (par exemple `redmine_get_issue`) jusqu'à la fin de l'initialisation — utiliser un `Rails.application.config.after_initialize` imbriqué et vérifier `Registry.instance.tool(...)` d'abord.

## Chargement et désactivation d'une extension

`redmine_mcp` recherche automatiquement le fichier d'extension dans les chemins pris en charge au démarrage de Redmine.

Deux variantes d'intégration :

1. **Extension dans un plugin tiers** — `lib/<...>/mcp.rb` dans le répertoire du plugin cible (voir « Démarrage rapide »).
2. **Intégration intégrée dans `redmine_mcp`** — `lib/redmine_mcp/extensions/<plugin.id>.rb` pour les cas où le plugin tiers ne peut pas être modifié. Le fichier enregistre tools/resources/prompts via le même `RedmineMcp::ExtensionApi`. Si le plugin cible a déjà son propre `mcp.rb`, l'intégration intégrée n'est utilisée que si le chargement de ce fichier échoue.

Exemple d'intégration intégrée :

```ruby
module RedmineMcp
  module Extensions
    module AdvancedSearch
      extend RedmineMcp::ExtensionApi

      plugin_id :advanced_search

      if mcp_extension_enabled?
        register_tool_once(
          name: 'semantic_search_issues',
          description: 'Semantic search for issues.',
          input_schema: {type: 'object', properties: {}},
          output_schema: RedmineMcp::SchemaNormalizer.envelope_output(type: 'object', properties: {}),
          permission: :view_issues,
          handler: ->(_args, _context) { {} }
        )
      end
    end
  end
end
```

Le code auxiliaire de l'intégration peut être placé dans `lib/redmine_mcp/extensions/<plugin_id>/` et importé par `require` explicite depuis le fichier principal.

Vérifier `redmine_mcp` uniquement au point d'entrée `mcp.rb` (généralement `lib/<plugin>.rb` ou `after_initialize` du chargeur du plugin). Les fichiers chargés uniquement depuis `mcp.rb` (`mcp_tools.rb`, `mcp_tools/*.rb`, etc.) ne doivent pas répéter les mêmes vérifications. Pour les intégrations intégrées dans `redmine_mcp`, une vérification séparée au point d'entrée n'est pas nécessaire : le fichier n'est chargé que par `ExtensionLoader`.

Ne pas appeler `ExtensionLoader.load_plugin_extension` manuellement depuis un plugin tiers : `ExtensionLoader` est un mécanisme interne de `redmine_mcp`. Un `require` conditionnel de votre `mcp.rb` suffit ; si l'ordre de chargement des plugins a empêché ce `require`, le `ExtensionLoader` standard de `redmine_mcp` sert de repli.

Exemple de point d'entrée :

```ruby
# lib/my_plugin.rb

Rails.application.config.after_initialize do
  require "#{File.dirname(__FILE__)}/my_plugin/mcp" if Redmine::Plugin.installed?(:redmine_mcp) && defined?(RedmineMcp)
end
```

L'extension est enregistrée uniquement si :

- MCP est activé dans les paramètres de `redmine_mcp` ;
- un fichier d'extension est trouvé (`mcp.rb` dans le plugin ou `lib/redmine_mcp/extensions/<plugin.id>.rb` dans `redmine_mcp`, avec priorité au `mcp.rb` du plugin) ;
- le module d'extension se charge correctement ;
- l'extension n'est pas désactivée dans la liste `MCP extensions`.

Après installation d'une nouvelle extension ou modification de `mcp.rb`, Redmine a généralement besoin d'un redémarrage. Le client MCP peut ensuite avoir besoin de se reconnecter. Dans certaines applications, comme Cursor, recharger le serveur MCP ne suffit pas pour prendre en charge les nouveaux outils : s'ils n'apparaissent pas, redémarrer complètement l'application.

## Vérification d'une extension

Après implémentation, vérifier l'outil via un appel MCP réel pour contrôler non seulement le handler, mais aussi :

- l'enregistrement dans `tools/list` ;
- le schéma d'entrée ;
- la permission ;
- l'enveloppe de sortie ;
- les erreurs.

Vérifier les journaux Redmine pour les erreurs d'enregistrement d'outils et de chargement d'extensions.

Pour chaque nouvel outil, au minimum :

- un scénario de schéma réussi ;
- un scénario de schéma négatif.

Les exigences détaillées de tests automatisés sont dans [mcp_tool_development.md](mcp_tool_development.md) (§13).

### Tests automatisés d'extension

Les tests automatisés pour une extension MCP de plugin DOIVENT exercer le **chemin Registry complet** (validation `inputSchema` → permission → handler → enveloppe `{ok, data | error}`), pas seulement un appel direct au handler.

Si `redmine_mcp` n'est pas installé ou chargé, la classe de test **ignore** les scénarios (`skip` dans `setup`) au lieu d'échouer lors du chargement du fichier :

```ruby
def setup
  skip('redmine_mcp is not installed') unless Redmine::Plugin.installed?(:redmine_mcp) && defined?(RedmineMcp)
  # ...
end
```

Dans le `setup` de test, appeler `RedmineMcp::ExtensionLoader.load_plugin_extension(Redmine::Plugin.find(:your_plugin))` est acceptable pour enregistrer des outils dans `Registry`. Ne pas appeler `ExtensionLoader` depuis le code de production du plugin (voir « Chargement et désactivation d'une extension »).

Pour comparer la réponse réelle avec le `outputSchema` publié (`mcp_tool_development.md` §7.1), utiliser `json_schemer` — la même bibliothèque que `RedmineMcp::InputValidator` applique aux schémas d'entrée.

Le chargement paresseux de `json_schemer` dans un helper de test est autorisé. Si la bibliothèque n'est pas disponible dans l'environnement, la vérification doit être explicitement ignorée pour que les tests du plugin ne échouent pas à cause d'une dépendance optionnelle.

Tests automatisés minimum pour un outil d'extension en lecture seule :

- un appel Registry réussi avec validation `outputSchema` ;
- un appel négatif rejeté par `inputSchema` (par exemple violation de `oneOf`, enum ou `maxItems`) ;
- si nécessaire — un test de validation serveur au niveau handler séparé (le schéma ne remplace pas les vérifications côté serveur ; voir `mcp_tool_development.md` §3.4).

## Dépannage

| Problème | Ce qu'il faut vérifier |
|---|---|
| Extension non chargée | chemin `mcp.rb` ou `lib/redmine_mcp/extensions/<plugin.id>.rb`, nom de module, si MCP est activé, si l'extension est activée dans les paramètres, erreurs dans le journal Rails |
| Outil/ressource/prompt n'a pas apparu | si `plugin_id` est défini, si l'extension est désactivée, collisions de noms ou URI, si l'utilisateur a les permissions requises |
| Changements non visibles après modifications | redémarrer Redmine ; dans Cursor et clients similaires, recharger le serveur MCP peut ne pas prendre en charge les nouveaux outils — redémarrer complètement l'application |
| `extend_tool` ne fonctionne pas | si l'outil de base est enregistré, si `extra_params` entrent en conflit avec le schéma existant |

### Checklist avant fusion

- [ ] L'outil a `title`, `description`, `input_schema`, `output_schema`, `permission` et `annotations`.
- [ ] Chaque `*_id` a un chemin de découverte.
- [ ] Description, output_schema et la réponse réelle sont cohérents.
- [ ] Un outil mutant respecte le mode lecture seule.
- [ ] La logique spécifique à MCP ne grossit pas dans un lambda/handler.
- [ ] Les helpers partagés sont réutilisés depuis `redmine_mcp`, pas copiés.
- [ ] Au moins un scénario de schéma réussi et un négatif ont été exécutés.
