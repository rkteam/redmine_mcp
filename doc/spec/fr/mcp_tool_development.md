# Exigences de développement d'outils Redmine MCP

[Deutsch](../de/mcp_tool_development.md) | [English](../en/mcp_tool_development.md) | [Español](../es/mcp_tool_development.md) | [Français](mcp_tool_development.md) | [Italiano](../it/mcp_tool_development.md) | [日本語](../ja/mcp_tool_development.md) | [한국어](../ko/mcp_tool_development.md) | [Polski](../pl/mcp_tool_development.md) | [Português (Brasil)](../pt-BR/mcp_tool_development.md) | [Русский](../ru/mcp_tool_development.md) | [中文](../zh/mcp_tool_development.md)

**Statut :** guide développeur (dev-guide), pas une SPEC comportementale du plugin  
**Version :** 1.6  
**Date :** 2026-08-20  
**Applicabilité :** tous les nouveaux outils Redmine MCP et changements substantiels aux outils existants  
**Version MCP de base :** révision du protocole `2025-11-25`

Les contrats comportementaux des outils de base sont dans `03-core-tools.md` et les SPECs associées. Ce document définit les règles de conception et d'implémentation des outils.

---

## 1. Objet de ce document

Ce document établit des exigences unifiées pour la conception, la mise en œuvre, la description, les tests et la publication des outils MCP pour Redmine. Les modèles de mise en œuvre architecturale sont rassemblés dans l'annexe A et ne sont pas mélangés avec les exigences obligatoires du texte principal.

Le but de cette norme est de réaliser des outils :

- sans ambiguïté pour la sélection du modèle de langage ;
- sûr lorsqu'il est invoqué automatiquement ;
- prévisible pour les clients MCP ;
- strictement validé ;
- facile à entretenir et rétrocompatible ;
- résistant aux appels répétés, aux erreurs de modèle et aux arguments partiellement remplis.

Les exigences sont formulées en gardant à l'esprit un audit du Redmine MCP actuel. Au moment de la préparation de ce document, le serveur publie 46 outils ; le contrat révélait des paramètres sans `type`, des listes de chaînes de valeurs autorisées au lieu de `enum`, des outils universels `manage_*` et un `outputSchema` manquant.

---

## 2. Terminologie des obligations

Les niveaux suivants sont utilisés dans ce document :

- **DOIT / MUST** — exigence obligatoire. La violation bloque la fusion.
- **MUST NOT / INTERDIT** — interdiction obligatoire.
- **SHOULD / DEVRAIT** — exigence par défaut ; tout écart doit être justifié dans la merge request.
- **PEUT / MAY** — option acceptable.

Les modèles d'architecture et de mise en œuvre qui ne sont pas obligatoires pour chaque outil sont rassemblés dans l'**annexe A**. Ils ne bloquent pas la fusion s’ils ne sont pas délibérément adoptés pour un outil spécifique.

---

## 3. Principes de conception de base

### 3.1. Un outil – une action claire

Un outil DOIT représenter une intention atomique d’utilisateur.

Bon :

- `redmine_get_issue`
- `redmine_create_issue`
- `redmine_update_issue`
- `redmine_add_issue_note`
- `redmine_delete_issue`
- `redmine_list_issue_relations`
- `redmine_create_issue_relation`
- `redmine_delete_issue_relation`

Mauvais:

- `redmine_manage_issue`
- `redmine_manage_relation`
- `redmine_execute_action`

Outils avec un paramètre comme `action: create | update | delete | list` sont INTERDITS si les opérations :

- exiger différents arguments obligatoires ;
- ont différents niveaux de risque ;
- devrait avoir des annotations MCP différentes ;
- renvoyer différentes structures de données ;
- nécessitent des autorisations Redmine différentes.

Une exception n'est autorisée que pour une opération sémantiquement homogène où toutes les variantes présentent le même risque et un seul contrat. L'exception doit être explicitement justifiée.

### 3.2. Lecture, ajout, mise à jour et suppression sont séparés

Dans un seul outil, il est INTERDIT de combiner :

- les opérations de lecture seule et d'écriture ;
- ajout et suppression d'opérations ;
- les opérations régulières d'utilisation et d'administration ;
- les opérations locales de Redmine et l'envoi de données vers le monde extérieur.

Par exemple, « `list/create/delete relation` » doit être trois outils distincts.

### 3.3. Le contrat compte plus que la commodité de mise en œuvre du serveur

Ne publiez pas directement la structure d'une méthode interne Ruby/Python/REST simplement parce qu'il est plus facile d'implémenter le gestionnaire de cette façon.

Le contrat MCP est conçu pour le modèle et le client ; un adaptateur dans le serveur le convertit au format API Redmine.

Les valeurs techniques internes d'un plugin ou de Redmine DOIVENT être normalisées si elles ne font pas partie d'un contrat externe significatif.

Ne publiez pas sans nécessité :

- Noms de classe Ruby/Rails et types STI ;
- noms d'énumérations internes si MCP utilise déjà une valeur différente en entrée ;
- dates dépendant des paramètres régionaux ;
- Représentations spécifiques à REST du même champ si MCP définit déjà un format canonique ;
- noms techniques lorsque MCP utilise déjà une valeur normalisée.

Exemple : filtre d'entrée `type` — `contact` / `company` ; dans la réponse également `contact` / `company`, et non `Clientdesk::Contact` / `Clientdesk::Company`. Si un sérialiseur renvoie une classe STI ou une date localisée, l'adaptateur MCP DOIT apporter la valeur au schéma publié.

### 3.4. Le serveur ne fait pas confiance au modèle

Tous les arguments sont considérés comme non fiables. Le serveur DOIT revérifier :

- types ;
- les gammes ;
- les interdépendances des domaines ;
- les droits de l'utilisateur actuel ;
- objet appartenant à un projet ;
- disponibilité d'une valeur dans un workflow spécifique ;
- Contraintes Redmine ;
- si l'opération est autorisée dans l'état actuel de l'objet.

Le schéma JSON, les descriptions, les annotations et les confirmations du client ne remplacent pas la validation côté serveur.

---

## 4. Dénomination des outils

### 4.1. Format du nom

Tous les noms d'outils publiés DOIVENT commencer par `redmine_`.

Pour les outils de base du plugin `redmine_mcp`, le préfixe court `redmine_` est utilisé :

```text
redmine_<verb>_<entity>
```

Pour les outils issus de plugins tiers, le nom complet DOIT commencer par `redmine_` :

- `redmine_<plugin_id>_<verb>_<entity>`.

Exigences:

- uniquement `lower_snake_case` ;
- le préfixe `redmine_` est obligatoire pour tous les outils, y compris les extensions de plugins tiers ;
- le nom est unique au sein du serveur ;
- limite interne — pas plus de 64 caractères ;
- le nom ne change pas sans procédure de dépréciation.

Exemples :

```text
redmine_get_issue
redmine_list_projects
redmine_search_issues
redmine_create_time_entry
redmine_delete_wiki_page
redmine_advanced_search_semantic_search_issues
```

### 4.2. Verbes autorisés

Verbes préférés :

| Verbe | Objectif |
|---|---|
| `get` | récupérer un objet par identifiant exact |
| `list` | récupérer une collection via des filtres structurés |
| `search` | effectuer une recherche textuelle ou en texte intégral |
| `create` | créer un objet |
| `update` | modifier un objet existant |
| `set` | définir un champ ou indicateur spécifique à une valeur donnée |
| `delete` | supprimer un objet |
| `add` | ajouter une relation ou un membre à un objet existant |
| `remove` | supprimer une relation sans supprimer l'objet principal |
| `copy` | créer une copie |
| `upload` | téléverser un fichier |
| `download` | récupérer le contenu d'un fichier |
| `send` | envoyer un message ou des données à un destinataire externe |
| `summarize` | construire un rapport agrégé côté serveur |

Ne pas utiliser des verbes vagues (`manage`, `process`, `handle`, `execute`, `do`) — voir §3.1.

Le verbe DOIT correspondre à la vraie sémantique de l'opération. Si un outil active un indicateur booléen (paramètre comme `enabled: true | false`), il DEVRAIT être nommé avec `set`, pas avec un verbe impliquant une seule valeur.

Mauvais:

```text
redmine_advanced_search_enable_semantic_index
```

`enable` implique uniquement `enabled = true`, bien que le paramètre autorise aussi `false`. Le nom ne correspond pas à l'action réelle.

Bon :

```text
redmine_advanced_search_set_semantic_index_enabled
```

Le nom `set_*` reflète honnêtement que l'opération définit un indicateur sur la valeur transmise.

### 4.3. Noms des paramètres d'identification

Un nom de paramètre DOIT correspondre à son type réel :

- `issue_id` — ID entier uniquement ;
- `project_id` — ID entier uniquement ;
- `project_identifier` — Identificateur de chaîne Redmine ;
- `project` — chaîne qui autorise délibérément les deux représentations et est documentée comme référence.

Un paramètre nommé `*_id` ne peut pas accepter un identifiant de chaîne ou la valeur `"me"`.

Les identifiants numériques DOIVENT avoir `minimum: 1` et une `description` significative. Les formulations telles que `"Issue id"` sans `minimum` sont INTERDITES.

Mauvais:

```json
"issue_id": {
  "type": "integer",
  "description": "Issue id"
}
```

Bon :

```json
"issue_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Numeric issue ID.",
  "examples": [1]
}
```

L'option unifiée recommandée pour le projet est le paramètre `project`, acceptant un identifiant numérique (sous forme de chaîne) ou un identifiant de chaîne :

```json
"project": {
  "type": "string",
  "minLength": 1,
  "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown.",
  "examples": ["1", "ecookbook"]
}
```

Le tableau `examples` (§6.15) montre le modèle dans les deux formes de valeurs autorisées et réduit le risque de saisie incorrecte.

### 4.4. Optimistic locking: `expected_updated_at`

Un paramètre qui transmet l'horodatage connu d'un objet pour rejeter une modification obsolète DOIT être nommé `expected_updated_at` dans tous les outils de base et extensions.

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

Le nom `updated_at` pour cette signification est INTERDIT : il ressemble à "nouvelle heure de modification", bien qu'il s'agisse en fait d'une valeur de verrouillage optimiste.

Mauvais (liste de contrôle et éventuelles extensions) :

```json
"updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Current updated_at of the checklist item."
}
```

Bon :

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

Un champ de réponse qui rapporte l'heure de modification réelle de l'objet PEUT encore être nommé `updated_at` / `updated_on` — la confusion ne concerne que le paramètre d'entrée de verrouillage.

Le comportement normatif sur les conflits se trouve en annexe A.2.

---

## 5. `title` et `description`

### 5.1. `title`

`title` DOIT être un nom court lisible par l'homme, et non une copie du nom technique.

```json
{
  "name": "redmine_get_issue",
  "title": "Get Redmine issue"
}
```

### 5.2. Description de l'outil

`description` DOIT répondre brièvement aux questions clés :

1. Que fait l'outil et quel objet est lu ou modifié ?
2. Qu'est-ce qui n'est pas inclus par défaut et comment le demander ?
3. Y a-t-il des effets secondaires importants ?
4. Quel outil préliminaire appeler si l'ID ou une valeur autorisée est inconnu ?

La description DOIT être brève et facile à lire. Il est INTERDIT d'en faire un long paragraphe d'une demi-page listant tous les champs et tous incluant des options : une description surchargée est plus difficile à lire pour le modèle qu'une description courte et structurée.

DEVRAIT écrire plusieurs lignes courtes ou une liste, pas un texte continu. Les valeurs par défaut et comment les modifier sont affichées de manière compacte.

Bon exemple :

```text
Renvoie un ticket.

Par défaut :
- pas de journaux
- pas de pièces jointes

Utilisez include_* pour les demander.
Utilisez redmine_search_issues lorsque issue_id est inconnu.
```

Mauvais exemple — trop court, n'explique pas le résultat et le comportement par défaut :

```text
Récupère un ticket.
```

Mauvais exemple : paragraphe long et surchargé répertoriant tous les champs :

```text
Renvoie un ticket Redmine par issue_id numérique avec les champs de détail du noyau, notamment
sujet, description, statut, priorité, tracker, projet, assigné, auteur,
dates, ratio terminé, champs personnalisés, et optionnellement journaux, pièces jointes,
relations, observateurs, tickets enfants et statuts de workflow autorisés selon les
paramètres include passés à l'appel ...
```

### 5.2.1. Références vers d'autres outils

Lorsque la description, la description du paramètre ou les instructions du serveur font référence à un autre outil, le nom complet enregistré de `tools/list` DOIT être utilisé, et non un `name` court sans préfixe.

Mauvais :

```text
Utilisez list_projects lorsque le projet est inconnu.
Utilisez semantic_search_issues avant la mise à jour.
```

Bon :

```text
Utilisez redmine_list_projects lorsque le projet est inconnu.
Utilisez redmine_advanced_search_semantic_search_issues avant la mise à jour.
```

Les noms courts sont ambigus entre les plugins et obligent le modèle à deviner le préfixe. Ceci est particulièrement important pour les extensions : `semantic_search_issues` sans le préfixe `redmine_advanced_search_` est facilement confondu avec un outil principal inexistant.

### 5.2.2. Description du résultat renvoyé

La description DOIT expliquer brièvement le résultat de l'outil afin que le modèle comprenne si un appel est suffisant ou si un outil suivant est nécessaire.

La description du résultat doit indiquer :

- si un objet, une collection, un agrégat, une confirmation de modification ou une référence de ressource est renvoyé ;
- quelles données associées sont incluses par défaut ;
- quelles données volumineuses ou sensibles ne sont pas incluses sans paramètre explicite ;
- si la pagination existe et quelle est la limite standard ;
- si un outil d'écriture renvoie l'objet entièrement mis à jour ou uniquement l'identifiant, l'URL et l'heure de modification ;
- si une réussite partielle est possible pour une opération groupée.

Exemple de lecture :

```text
Renvoie un ticket avec les champs du noyau et personnalisés.

Non inclus par défaut : journaux, pièces jointes, relations, observateurs, tickets enfants.
Demandez-les avec include_*.
```

Exemple de liste :

```text
Renvoie une liste paginée de tickets correspondant aux filtres structurés fournis.
Chaque élément contient uniquement des champs résumé ; utilisez redmine_get_issue pour les détails complets.
Le résultat inclut total_count, limit, offset et has_more.
```

Exemple d'écriture :

```text
Crée un ticket et renvoie son ID numérique, l'URL canonique et l'horodatage de création.
La réponse n'inclut pas les journaux ni les pièces jointes.
```

Sur la relation entre la description et `outputSchema` — voir §7.1 et §7.1.1. Si une liste renvoie déjà un champ, la description NE DOIT PAS envoyer le modèle à `get_*` uniquement pour ce champ.

### 5.3. La description ne remplace pas le schéma

Il est INTERDIT de définir des contraintes uniquement dans le texte :

```json
{
  "type": "string",
  "description": "Operation: create, update, delete"
}
```

Utilisez `enum`, `const`, des plages et des schémas conditionnels.

Il en va de même pour les domaines mutuellement exclusifs. Si `description` dit "exactement l'un des `user_id` ou `group_id`" mais que `required` ne contient que des champs communs, le schéma et le texte divergent. La contrainte DOIT être formalisée dans `inputSchema` (§6.12).

### 5.4. Sélection prévisible

Les descriptions d'outils similaires doivent expliquer explicitement la différence.

Par exemple:

- `redmine_list_project_members` — membres d'un projet spécifique et leurs rôles ;
- `redmine_admin_list_users` — liste globale des utilisateurs d'installation, nécessite des droits d'administrateur.

### 5.5. Instructions au niveau du serveur

Le serveur PEUT publier de brèves instructions générales qui expliquent les relations entre les outils et les règles de flux de travail.

Les instructions doivent ajouter un contexte non présent dans les descriptions individuelles et faire référence aux outils par leurs noms complets (§5.2.1), par exemple :

```text
Utilisez redmine_search_issues avant redmine_get_issue lorsque l'ID du ticket est inconnu.
Avant de créer ou mettre à jour un ticket, appelez redmine_list_project_trackers et
redmine_list_project_issue_custom_fields lorsque leurs IDs ne sont pas déjà connus.
Les notes privées ne doivent être demandées que lorsque l'utilisateur en a explicitement besoin et a
la permission requise.
```

INTERDIT :

- répéter les descriptions de tous les outils dans les instructions du serveur ;
- y placer des instructions générales de comportement du modèle sans rapport avec le serveur ;
- rédiger un long guide au lieu de brèves règles de routage ;
- utiliser des déclarations marketing ;
- faisant référence aux outils par des noms courts sans préfixe (`list_projects` au lieu de `redmine_list_projects`).

### 5.6. Étudiez l’API Redmine REST avant le développement

Avant de créer ou de modifier substantiellement un outil, le développeur DEVRAIT effectuer une recherche documentaire. Il n'est pas recommandé de concevoir le contrat uniquement à partir du code MCP existant, de la mémoire du développeur ou d'un seul exemple de requête HTTP.

DEVRAIT étudier :

1. Page principale de l'API REST Redmine : authentification générale, pagination, `include`, champs personnalisés, fichiers et règles d'erreur de validation.
2. Page API séparée pour la ressource correspondante, par ex. Problèmes, entrées de temps, versions, pages wiki ou adhésions à un projet.
3. Section de l'historique des modifications de l'API et modifications des versions de Redmine prises en charge.
4. Version réelle de Redmine utilisée par MCP et version minimale prise en charge.
5. API REST et code source des plugins Redmine utilisés si l'outil fonctionne avec une entité ou des champs de plugin. Avant de publier un outil d'extension, DOIT vérifier le sérialiseur source/service/point de terminaison REST et au moins une réponse réelle réussie pour chaque formulaire de résultat (liste et get, si les deux sont publiés).
6. Autorisations réelles, flux de travail, modules activés, trackers, champs personnalisés et contraintes de l'installation cible.
7. Outils MCP déjà publiés pour éviter de créer un contrat en double ou conflictuel.

La page principale `https://www.redmine.org/projects/redmine/wiki/rest_api` est le point d'entrée mais est généralement insuffisante pour un outil spécifique. DEVRAIT accéder à la page de ressources correspondante et vérifier les opérations, les paramètres de requête, `include`, les champs de requête, la structure de réponse, les codes d'erreur et les contraintes de version.

### 5.7. Rapport de couverture API

Avant d'implémenter un nouvel outil, le développeur DEVRAIT joindre un bref tableau de couverture API à la demande de fusion :

| Champ | Contenu |
|---|---|
| Ressource Redmine | Ressource et lien vers la page officielle de l'API |
| Point de terminaison | Méthode et chemin HTTP |
| Pris en charge depuis | Version minimale de Redmine |
| Paramètres de la demande | Tous les paramètres de demande documentés |
| Filtres de requête | Tous les filtres documentés et valeurs spéciales |
| Inclure des valeurs | Données associées autorisées |
| Obligatoire/par défaut | Champs obligatoires et valeurs par défaut |
| Réponse | Principaux champs et variantes de réponse |
| Erreurs | Codes HTTP et structure des erreurs |
| Autorisations | Droits requis et détails de l'usurpation d'identité |
| Exposition MCP | Quels paramètres sont publiés dans MCP |
| Intentionnellement omis | Quels paramètres ne sont pas publiés et pourquoi |
| Différences de plugin/version | Différences entre les plugins et les versions prises en charge |

Le but du tableau n'est pas nécessairement de publier tous les paramètres Redmine dans MCP. L’objectif est de ne pas oublier accidentellement des paramètres et de prendre des décisions de publication en toute connaissance de cause.

Un paramètre Redmine peut être exclu du MCP s'il :

- est dangereux ou administratif ;
- duplique un outil plus clair distinct ;
- est instable dans les versions prises en charge ;
- crée un schéma ambigu ;
- n'est pas nécessaire pour les scénarios d'utilisateurs cibles ;
- conduit à des réponses excessivement larges.

Chaque exclusion substantielle est enregistrée dans `Intentionally omitted` avec une brève justification.

### 5.8. Instructions pour un agent IA développant des outils

Si un outil est créé ou modifié par un agent IA, les instructions de travail DEVRAIENT faire référence à ce document : recherche API (§5.6–5.7), contrat (§3–§8), tests (§13), checklist (§14).

Texte recommandé :

```text
Avant d'implémenter ou modifier un outil Redmine MCP, suivez MCP_TOOL_DEVELOPMENT.md :
étudiez l'API REST Redmine pour la ressource cible (§5.6–5.7), concevez une intention
utilisateur plutôt que de copier le payload REST (§3), comparez avec tools/list, puis
implémentez schéma/annotations/erreurs. Pour les extensions de plugins, inspectez le sérialiseur
ou la réponse REST et alignez description avec outputSchema (§7, §18). Passez la checklist
de revue de code (§14).
```

---

## 6. Exigences `inputSchema`

### 6.1. Structure de base

Chaque outil DOIT avoir un schéma JSON valide.

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {},
  "required": []
}
```

Pour un outil sans arguments :

```json
{
  "type": "object",
  "additionalProperties": false
}
```

### 6.2. Interdiction des propriétés non documentées

Au niveau supérieur et dans tous les objets imbriqués :

```json
"additionalProperties": false
```

Un dictionnaire ouvert n'est autorisé que consciemment. Dans ce cas, le schéma de valeurs est défini explicitement :

```json
"additionalProperties": {
  "type": "string"
}
```

### 6.3. Type de chaque paramètre

Chaque propriété DOIT contenir `type`, `$ref` ou une composition `oneOf` / `anyOf` / `allOf`.

INTERDIT:

```json
"project_id": {
  "description": "Project ID or identifier"
}
```

### 6.4. Paramètres requis

Le tableau `required` doit refléter l'appel minimalement exécutable.

Si l'opération est impossible sans un paramètre, le paramètre DOIT être dans `required`.

Par exemple, le téléchargement de fichiers nécessite au moins :

```json
"required": ["project", "filename", "content_base64"]
```

La vérification `confirm=true` de suppression est effectuée sur le serveur (§3.4), même si le champ est à `required`.

### 6.5. Énumérations

Pour un ensemble fini de valeurs, DOIT utiliser `enum` ou `const` (pas seulement le texte dans la description — voir §5.3).

```json
"status": {
  "type": "string",
  "enum": ["open", "locked", "closed"]
}
```

### 6.6. Chaînes

Les chaînes doivent avoir des contraintes appropriées :

- `minLength` pour les valeurs non vides ;
- `maxLength` selon les contraintes Redmine ou limites internes ;
- `pattern` lorsque le format est strictement défini ;
- `format` lorsqu'un format standard s'applique.

```json
"due_date": {
  "type": "string",
  "format": "date",
  "description": "Due date in YYYY-MM-DD format."
}
```

La contrainte `format` dans le schéma ne remplace pas la validation côté serveur (§3.4).

### 6.7. Nombres

Pour les paramètres numériques, des limites raisonnables DOIVENT être définies.

```json
"limit": {
  "type": "integer",
  "default": 25,
  "minimum": 1,
  "maximum": 100
}
```

```json
"hours": {
  "type": "number",
  "exclusiveMinimum": 0,
  "maximum": 24
}
```

La valeur `default` fait partie du contrat et de la documentation. Le serveur ne doit pas supposer que le client remplacera lui-même la valeur par défaut.

### 6.8. Tableaux

Chaque tableau DOIT avoir `items`.

Si nécessaire, définissez :

- `minItems` ;
- `maxItems` ;
- `uniqueItems`.

```json
"role_ids": {
  "type": "array",
  "minItems": 1,
  "maxItems": 20,
  "uniqueItems": true,
  "items": {
    "type": "integer",
    "minimum": 1
  }
}
```

Un tableau comme `entries: array` sans schéma d'élément est INTERDIT.

### 6.9. Objets imbriqués

Tous les objets imbriqués sont décrits entièrement.

```json
"custom_fields": {
  "type": "array",
  "items": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "id": {"type": "integer", "minimum": 1},
      "value": {
        "oneOf": [
          {"type": "string"},
          {"type": "number"},
          {"type": "boolean"},
          {
            "type": "array",
            "items": {"type": "string"}
          }
        ]
      }
    },
    "required": ["id", "value"]
  }
}
```

### 6.10. Impossible d'accepter "un objet ou une chaîne JSON"

Il est INTERDIT de décrire un paramètre comme « objet ou chaîne JSON ».

MCP transmet déjà le JSON structuré. L'outil doit accepter un objet, pas une chaîne que le serveur analyse ensuite à nouveau.

### 6.11. Universal `fields` and `extra_fields`

Les paramètres `fields`, `extra_fields`, `payload`, `data` et les objets ouverts similaires sont INTERDITS pour les principales opérations commerciales.

Les champs de problèmes doivent être répertoriés explicitement avec une `description` significative (§6.14) et, lorsque cela est utile, des `examples` (§6.15) :

```json
{
  "tracker_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Tracker ID returned by redmine_list_trackers.",
    "examples": [1, 2]
  },
  "status_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Issue status ID returned by redmine_list_issue_statuses; must be allowed by the workflow for the current tracker and role.",
    "examples": [1, 2]
  },
  "priority_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Issue priority ID returned by redmine_list_issue_priorities.",
    "examples": [3, 4]
  },
  "assigned_to_id": {
    "type": "integer",
    "minimum": 1,
    "description": "User ID of the assignee, from redmine_list_project_members."
  },
  "fixed_version_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Target version ID returned by redmine_list_versions."
  },
  "parent_issue_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Numeric ID of the parent issue."
  },
  "estimated_hours": {"type": "number", "minimum": 0},
  "start_date": {"type": "string", "format": "date"},
  "due_date": {"type": "string", "format": "date"}
}
```

Les champs rarement utilisés peuvent être transmis via un `custom_fields` strictement décrit.

### 6.12. Champs interdépendants

Préférez les outils de fractionnement. Si le fractionnement est impossible, la dépendance est formalisée par :

- `dependentRequired` ;
- `if` / `then` / `else` ;
- `oneOf` avec des branches mutuellement exclusives.

Le texte dans `description` ("exactement l'un des …") ne remplace pas le schéma (§5.3).

Cas typique — "exactement un des deux champs". Mauvais : `required` ne répertorie que les champs courants, XOR reste en prose :

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "project": {"type": "string", "minLength": 1},
    "user_id": {"type": "integer", "minimum": 1},
    "group_id": {"type": "integer", "minimum": 1},
    "role_ids": {
      "type": "array",
      "minItems": 1,
      "items": {"type": "integer", "minimum": 1}
    }
  },
  "required": ["project", "role_ids"]
}
```

Un tel schéma permet un appel sans `user_id`/`group_id` et un appel avec les deux champs à la fois.

Bon – commun `required` plus `oneOf` de niveau supérieur :

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "project": {
      "type": "string",
      "minLength": 1,
      "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown."
    },
    "user_id": {
      "type": "integer",
      "minimum": 1,
      "description": "User ID from redmine_list_users to add as a project member."
    },
    "group_id": {
      "type": "integer",
      "minimum": 1,
      "description": "Group ID to add as a project member."
    },
    "role_ids": {
      "type": "array",
      "minItems": 1,
      "uniqueItems": true,
      "items": {"type": "integer", "minimum": 1},
      "description": "Role IDs from redmine_list_roles."
    }
  },
  "required": ["project", "role_ids"],
  "oneOf": [
    {
      "required": ["user_id"],
      "not": {"required": ["group_id"]}
    },
    {
      "required": ["group_id"],
      "not": {"required": ["user_id"]}
    }
  ]
}
```

La validation côté serveur (§3.4) DOIT toujours rejeter les deux variantes incorrectes. Le schéma est nécessaire pour que le client et le modèle voient la contrainte avant l'appel.

Il faut vérifier la compatibilité des constructions choisies avec les clients MCP et SDK pris en charge.

### 6.13. Champs avec une valeur `null` et effacement des valeurs

`null` est autorisé uniquement lorsqu'il a une signification documentée distincte, par ex. "effacer la date d'échéance" ou "annuler l'attribution".

```json
"due_date": {
  "oneOf": [
    {"type": "string", "format": "date"},
    {"type": "null"}
  ],
  "description": "New due date in YYYY-MM-DD format, or null to clear it."
}
```

```json
"assigned_to_id": {
  "oneOf": [
    {"type": "integer", "minimum": 1},
    {"type": "null"}
  ],
  "description": "Assignee user ID from redmine_list_users, or null to unassign."
}
```

N'utilisez pas de chaîne vide comme équivalent implicite de `null`.

Pour les outils `set_*` qui définissent un champ facultatif (date d'échéance, cessionnaire, etc.), le contrat DOIT décider explicitement de la compensation. Trois options sont autorisées, par ordre de préférence :

1. **Le même outil accepte `null`** (de préférence), comme ci-dessus : une intention "définir ou effacer".
2. **Outil d'effacement/annulation d'attribution séparé**, si l'API ou l'UX séparent mieux les opérations, par ex. `redmine_advanced_search_clear_saved_query` et `redmine_advanced_search_unassign_search_owner`.
3. **Refus explicite** : si la compensation via MCP n'est pas prise en charge, cela DOIT être indiqué dans la `description` de l'outil et/ou la description du paramètre. Le contrat silencieux "uniquement chaîne/entier sans null" sans explication est INTERDIT — le modèle pensera à tort que la compensation est impossible ou essaiera de passer `""` / `0`.

Mauvais : peut définir une date d'échéance, ne peut pas effacer et n'est indiqué nulle part :

```json
"due_date": {
  "type": "string",
  "format": "date"
}
```

### 6.14. Descriptions des paramètres

Chaque paramètre dans `inputSchema.properties` DOIT avoir une `description` significative. Les paramètres sans `description` sont INTERDITS, y compris dans les extensions (élément de liste de contrôle `done`, `sort_order`, `due_date`, champs d'ID, etc.) et les champs facultatifs avec `enum` clair.

Les descriptions telles que « Filtrer par ID de tracker », « ID de tracker » ou « ID de problème » sont insuffisantes : elles n'indiquent pas où obtenir une valeur autorisée ni quelles contraintes existent.

Une description du paramètre d'identifiant DOIT indiquer quel outil ou champ de réponse utiliser pour les valeurs autorisées (nom complet — §5.2.1 ; découverte — §6.16), et noter les contraintes importantes (flux de travail, autorisations, appartenance au projet).

Mauvais:

```json
"tracker_id": {
  "type": "integer",
  "description": "Filter by tracker ID."
}
```

```json
"done": {
  "type": "boolean"
}
```

```json
"user_id": {
  "type": "integer",
  "minimum": 1
}
```

```json
"resources": {
  "type": "array",
  "items": {"type": "string", "enum": ["issues", "wiki_pages"]}
}
```

Bon :

```json
"tracker_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Tracker ID returned by redmine_list_trackers."
}
```

```json
"done": {
  "type": "boolean",
  "description": "true marks the item done; false marks it undone."
}
```

```json
"user_id": {
  "type": "integer",
  "minimum": 1,
  "description": "User ID from redmine_list_users to add as a project member."
}
```

```json
"resources": {
  "type": "array",
  "items": {"type": "string", "enum": ["issues", "wiki_pages"]},
  "description": "Resource types to search. Omit to search all supported resource types."
}
```

Bon, avec contrainte notée :

```json
"status_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Issue status ID returned by redmine_list_issue_statuses; must be allowed by the workflow for the current tracker and role."
}
```

La description des paramètres ne remplace pas le schéma (§5.3) et la validation côté serveur (§3.4).

### 6.15. Exemples de valeurs (`examples`)

Pour les paramètres où le format de valeur n'est pas évident ou permet plusieurs représentations, DEVRAIT ajouter des `examples` – clé de tableau de schéma JSON standard. Les exemples aident le modèle à saisir une valeur correcte et sont particulièrement utiles pour les paramètres de référence, les identifiants, les dates et les chaînes de type énumération.

```json
"project": {
  "type": "string",
  "minLength": 1,
  "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown.",
  "examples": ["1", "ecookbook"]
}
```

```json
"due_date": {
  "type": "string",
  "format": "date",
  "description": "Due date in YYYY-MM-DD format.",
  "examples": ["2026-07-30"]
}
```

Exigences:

- Les valeurs des `examples` DOIVENT être valides par rapport au schéma de paramètres lui-même ;
- Les `examples` illustrent le format mais ne remplacent pas `enum`, les plages et autres contraintes (§5.3, §6.5) ;
- pour les paramètres avec `enum`, des `examples` séparés sont généralement redondants.

Si un client ou SDK MCP ne prend pas en charge `examples` dans le schéma, `x-examples` PEUT être utilisé comme clé d'extension avec la même sémantique.

### 6.16. Chemin de découverte pour les paramètres d'ID

Un paramètre de la forme `*_id` que le modèle ne peut deviner DOIT avoir un chemin de découverte explicite : un outil read/list séparé ou un champ dans la réponse d'un autre outil read référencé dans la `description` du paramètre (§6.14).

Options autorisées (par ordre de préférence pour un ensemble d'outils) :

1. **Outil list/discovery séparé** — `redmine_list_issue_statuses`, `redmine_list_roles`, `redmine_advanced_search_list_search_providers`.
2. **Options dans la réponse get/list** — par ex. tableau provider avec `id` et `name` dans la réponse de `redmine_advanced_search_semantic_search_issues`. La description DOIT alors référencer ce champ de réponse avec le nom complet de l'outil.
3. **Enum stable dans le schéma**, si l'ensemble de valeurs est fixe et petit.

INTERDIT de publier un outil d'écriture avec `status_id` / `role_ids` / similaire si aucune des conditions ci-dessus n'est satisfaite : le modèle est obligé de deviner les identifiants.

Mauvais — écriture sans découverte :

- `redmine_advanced_search_set_search_provider` existe avec `provider_id` ;
- pas de `redmine_advanced_search_list_search_providers` ;
- `semantic_search_issues` renvoie uniquement le nom du fournisseur actuel (`provider: "…"`), sans liste des valeurs autorisées et leur `id`.

Dans ce cas, une description telle que `"Search provider ID."` est insuffisante. Ajoutez un outil de liste ou incluez des options de fournisseur dans get réponse et écriture, par exemple :

```text
ID du fournisseur de recherche renvoyé dans les options provider de
redmine_advanced_search_semantic_search_issues.
```

La règle s'applique au noyau et aux extensions (§18).

---

## 7. `outputSchema` et exigences de résultats

### 7.1. `outputSchema`

Un nouvel outil DOIT publier `outputSchema`. Le schéma décrit un contrat de réponse publique stable, pas seulement la forme de l'enveloppe `{ ok, data | error }`.

Si `description` prétend que l'outil renvoie des champs nommés ou une structure imbriquée, `outputSchema` DOIT formaliser ces champs, et ne pas se limiter aux `data`/`items` de niveau supérieur en tant qu'« objet arbitraire ».

Mauvais : la description liste `query`, `results`, des extraits et des excerpts de pièces jointes, mais `outputSchema` est absent ou décrit `items` uniquement comme `{ "type": "object", "additionalProperties": true }`.

Pour chaque champ de résultat stable :

- le type DOIT être spécifié ;
- un champ garanti DOIT être à `required` ;
- un ensemble de valeurs finies DOIT être défini via `enum` ou `const` ;
- une date DOIT avoir `format: date` ou `date-time` si le serveur garantit le format correspondant ;
- l'ID numérique DOIT conserver un type unifié ;
- nullable et facultatif sont des contrats différents : si un champ est toujours renvoyé mais ne peut avoir aucune valeur, il doit être `required` et autoriser `null` ;
- pour les valeurs commerciales numériques, les unités DOIVENT être spécifiées si elles ne ressortent pas clairement du nom du champ ;
- la valeur monétaire DOIT avoir une sémantique sans ambiguïté : unités majeures/mineurs et comment la monnaie est déterminée.

`additionalProperties: true` NE DOIT PAS être utilisé à la place de décrire des champs de résultats stables connus. Il est autorisé pour une compatibilité ascendante ou des structures véritablement extensibles, mais les champs métiers connus à l'intérieur d'un tel objet doivent toujours être répertoriés dans `properties`, et ceux garantis dans `required`.

Pour les outils de liste, les éléments `items` DOIVENT décrire au moins les champs nécessaires au modèle pour l'identification, le filtrage et les appels d'outils ultérieurs.

Bon — typage de fragments `data` (enveloppe complète de réussite/erreur — §7.2 et §12) :

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "ok": {"type": "boolean"},
    "data": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "query": {"type": "string"},
        "results": {
          "type": "array",
          "items": {
            "type": "object",
            "additionalProperties": true,
            "properties": {
              "id": {"type": "integer"},
              "subject": {"type": "string"},
              "url": {"type": "string"}
            },
            "required": ["id", "subject"]
          }
        }
      },
      "required": ["query", "results"]
    }
  },
  "required": ["ok"]
}
```

Le résultat DEVRAIT renvoyer :

- `structuredContent` — objet lisible par machine si les clients ont besoin d'une structure stable ;
- texte `content` — brève représentation pour la compatibilité ascendante et les humains.

### 7.1.1. Cohérence du contrat public

Avant de compléter un outil, le développeur DOIT comparer trois représentations :

1. réponse réelle du gestionnaire/REST/service ;
2. `description` de l'outil ;
3. `outputSchema`.

Ils ne doivent pas se contredire.

Si la description indique qu'un champ est toujours renvoyé, il doit être `required` dans `outputSchema`.

Si le schéma définit `enum` / `const` / `format`, le sérialiseur réel DOIT normaliser la valeur par rapport à ce contrat. Impossible de publier `format: date` et de promettre simultanément une chaîne au format local.

Si une liste renvoie déjà des données, la description NE DOIT PAS envoyer le modèle à un outil d'obtention uniquement pour les mêmes données.

Les invariants métier du résultat DOIVENT être reflétés dans le schéma via `const`, `enum`, `required` ou un schéma conditionnel, et pas seulement déduits du nom de l'outil. Exemple : si un outil d'abonnement renvoie par définition uniquement des produits de type `subscription`, `product_type` doit être `const: "subscription"`, et non `enum` avec des valeurs impossibles.

### 7.2. Enveloppe unifiée

Résultat réussi recommandé :

```json
{
  "ok": true,
  "data": {},
  "meta": {}
}
```

Erreur:

```json
{
  "ok": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "status_id 17 is not available for tracker 3",
    "field": "status_id",
    "retryable": false
  }
}
```

En cas d'erreur, définissez en plus :

```json
"isError": true
```

Si `outputSchema` est publié et qu'une erreur est également renvoyée dans `structuredContent`, le schéma DOIT décrire les deux branches : succès et erreur. Impossible de publier un schéma de réussite uniquement et de renvoyer un objet d'erreur structuré incompatible. Alternative : en cas d'erreur d'exécution de l'outil, renvoyez uniquement le texte `content` avec `isError: true` et ne renvoyez pas `structuredContent`. Option préférée — enveloppe dactylographiée unifiée à deux branches.

### 7.3. Stabilité des champs

Les champs de sortie sont un contrat public. INTERDIT:

- changer de type de champ sans changement majeur ;
- renommer un champ sans période de dépréciation ;
- renvoyant parfois un objet, parfois un tableau ;
- renvoyer l'ID sous forme de numéro parfois, de chaîne parfois ;
- renvoi d'une réponse API Redmine non traitée et illimitée.

### 7.4. Résultat d'un objet unique

Format recommandé :

```json
{
  "ok": true,
  "data": {
    "id": 12345,
    "subject": "Fix authorization error",
    "status": {"id": 2, "name": "In Progress"},
    "project": {"id": 10, "identifier": "bank-site", "name": "Bank Site"},
    "url": "https://redmine.example/issues/12345",
    "updated_at": "2026-07-22T09:20:00Z"
  }
}
```

### 7.5. Résultat de la liste

```json
{
  "ok": true,
  "data": {
    "items": []
  },
  "meta": {
    "total_count": 143,
    "limit": 25,
    "offset": 0,
    "next_offset": 25,
    "has_more": true
  }
}
```

Le schéma des éléments `items` suit le §7.1 : les identifiants, les champs de routage et les champs commerciaux stables sont décrits explicitement. Le `{ "type": "object", "additionalProperties": true }` vide comme seule description d'élément est INTERDIT.

### 7.6. Volume minimum nécessaire

Les outils de liste/recherche doivent par défaut renvoyer de brefs enregistrements. La description complète, les journaux, les pièces jointes et les grands champs de texte doivent être obtenus via `get_*` séparé.

Cela réduit les jetons, la latence et le risque de transmission de données sensibles excessives.

### 7.7. Données sensibles

Le résultat ne doit pas contenir sans besoin explicite :

- Jetons API ;
- En-têtes d'autorisation ;
- les cookies ;
- chemins du système de fichiers du serveur ;
- traces de pile internes ;
- mots de passe et secrets ;
- Champs Redmine non disponibles pour l'utilisateur actuel ;
- notes privées sans autorisation séparée.

---

## 8. Annotations MCP

Les annotations sont des indications pour le client et ne constituent pas un mécanisme d'autorisation ou de protection.

### 8.1. Matrice de valeurs

| Type d'opération | `readOnlyHint` | `destructiveHint` | `idempotentHint` | `openWorldHint` |
|---|---:|---:|---:|---:|
| Obtenir/trouver/lister les données Redmine | `true` | `false` | `true` | `false` |
| Créer un problème/une version/une liste de contrôle | `false` | `false` | `false` | `false` |
| Ajouter un commentaire/observateur/relation | `false` | `false` | `false` | `false` |
| Changer le champ, renommer, définir l'indicateur (`update`, `rename`, `set`) | `false` | `false` | dépend de la mise en œuvre | `false` |
| Supprimer, effacer, réinitialiser (`delete`, `purge`, `reset`) | `false` | `true` | uniquement avec une idempotence garantie | `false` |
| Envoyer un e-mail à un destinataire externe | `false` | `false` | `false` | `true` |
| Accéder à une URL arbitraire/à un système externe | dépend | dépend | dépend | `true` |

### 8.2. Règles

- `readOnlyHint: true` uniquement si l'outil ne change pas d'état et ne provoque pas d'effets secondaires.
- `destructiveHint` décrit la perte ou la destruction irréversible de données, et non le fait de les écrire. `destructiveHint: true` DEVRAIT être défini uniquement pour les opérations irréversibles — `delete`, `purge`, `reset`, champ complet ou effacement de relation.
- Les `update`, `rename` et `set` ordinaires ne sont PAS destructeurs : pour eux `destructiveHint: false`. Par exemple, `update_checklist_title` ou `rename_wiki_page` est une mise à jour ordinaire, pas une destruction, et les annotations destructives ne leur conviennent pas.
- `idempotentHint: true` uniquement si l'appel répété est vraiment sûr ; DEVRAIT confirmer avec un test.
- `openWorldHint` décrit si l'outil accède à un monde externe ouvert et inconnu, et non si un nouvel objet est créé. Travailler avec une installation Redmine configurée est un monde fermé : `openWorldHint: false`.
- Par conséquent, `create_issue`, `create_time_entry` et d'autres outils d'écriture dans leur Redmine utilisent `openWorldHint: false`, malgré la création de nouveaux objets. Créer un objet dans un système connu ne rend pas le monde ouvert.
- `openWorldHint: true` uniquement lorsque le destinataire ou la source de données n'est pas limité au système connu : envoi d'e-mail à un destinataire externe, requête HTTP arbitraire, accès à un service externe.
- La valeur `openWorldHint` DEVRAIT être définie consciemment pour chaque outil, et non copiée par défaut : vérifiez si l'outil va réellement au-delà de son installation Redmine.
- Impossible de copier un jeu d'annotations sur tous les outils d'écriture.

### 8.3. Effets secondaires de Redmine

Lors de l’évaluation de l’idempotence, tenez compte non seulement des champs finaux, mais également :

- création d'écritures de journal ;
- envoi de notifications ;
- les webhooks ;
- journal d'audit ;
- téléchargement répété de fichiers ;
- création répétée de relations ;
- enregistrement répété des entrées de temps.

Si un appel répété crée un enregistrement ou une notification supplémentaire, l'outil n'est pas idempotent.

---

## 9. Sécurité

### 9.1. Autorisation

Chaque appel DOIT être exécuté dans le contexte d'un utilisateur authentifié ou d'un compte de service explicitement documenté.

Le serveur DOIT vérifier les autorisations Redmine pour le projet et l'objet spécifiques. La présence de l'outil dans `tools/list` ne signifie pas l'autorisation pour l'opération.

Les outils administratifs doivent :

- être publié uniquement aux administrateurs ;
- ou être déplacé vers un profil/serveur MCP administratif distinct ;
- soit être protégé par un scope distinct.

### 9.2. Droits minimaux

Le serveur MCP et le jeton API Redmine doivent disposer des droits minimaux nécessaires. Impossible d'utiliser un jeton d'administration global pour tous les utilisateurs si le modèle d'accès utilisateur doit être préservé.

### 9.3. Chemins arbitraires du système de fichiers interdits

Des paramètres tels que :

```json
{"file_path": "/etc/app/.env"}
```

sont INTERDITS dans les outils MCP publics.

Options sûres :

1. `content_base64` avec limite de taille ;
2. `upload_token` opaque émis par un mécanisme de téléchargement fiable ;
3. URI de la ressource MCP où l'accès est vérifié par l'hôte ;
4. fichier uniquement à partir d'un répertoire temporaire dédié avec vérification `realpath` et liste autorisée.

Le serveur DOIT vérifier :

- taille maximale ;
-Type MIME ;
- prolongation autorisée ;
- nom de fichier;
- absence de parcours de chemin ;
- vérification antivirus/contenu si la politique de l'organisation l'exige.

### 9.4. URL arbitraires et SSRF

Un outil ne doit pas accepter d’URL arbitraire, sauf si tel est son objectif principal.

Lorsqu'un accès HTTP est nécessaire :

- utiliser la liste autorisée de domaine et de schéma ;
- interdire le bouclage, le lien local, les points de terminaison de métadonnées et les réseaux internes s'ils ne sont pas nécessaires ;
- limiter les redirections ;
- définir le délai d'attente et la limite de réponse ;
- ne transmettez pas les informations d'identification internes à une autre origine.

### 9.5. Suppression et opérations dangereuses

Pour les opérations irréversibles, OBLIGATOIRE :

- outil séparé ;
- `destructiveHint: true` ;
- description explicite de l'irréversibilité ;
- vérification précise des autorisations côté serveur ;
- journal d'audit ;
- protection contre la suppression d'objet en dehors du projet attendu ;
- vérification des objets enfants et conséquences associées.

Le booléen `confirm_delete: true` PEUT être utilisé comme protection supplémentaire contre les appels accidentels, mais ne peut pas être considéré comme un mécanisme d'autorisation.

Suppression en deux phases, verrouillage optimiste et clé d'idempotence — voir annexe A.

### 9.6. Journaux

Enregistrements du journal d'audit :

- nom de l'outil ;
- utilisateur authentifié ;
- ID de projet/objet cible ;
- résultat;
- durée;
-code d'erreur ;
- demander l'ID de corrélation.

INTERDIT de consigner :

- jeton d'accès ;
- En-tête d'autorisation ;
- les cookies ;
- le contenu du fichier base64 ;
- des champs personnalisés secrets ;
- texte intégral des notes privées sans besoin séparé.

### 9.7. Limite de débit et délai d'attente

Chaque outil DOIT avoir :

- limite de taille d'entrée ;
- limite de débit par utilisateur/jeton ;
- limite du nombre d'enregistrements renvoyés ;
- les limites des opérations en masse.

Un délai d'attente du serveur de 60 s s'applique aux outils de lecture. Les outils d'écriture ne sont pas interrompus par le délai d'attente du serveur, de sorte qu'après une sauvegarde réussie, le résultat de l'idempotence peut être enregistré.

---

## 10. Erreurs

### 10.1. Séparation des erreurs

Deux niveaux sont utilisés :

1. **Erreur de protocole** — outil inconnu, JSON-RPC corrompu, incapacité à traiter la requête MCP.
2. **Erreur d'exécution de l'outil** avec `isError: true` — erreur d'argument, API Redmine, autorisations, flux de travail ou erreur de logique métier.

Les erreurs que le modèle peut corriger en modifiant les arguments doivent être renvoyées sous forme d'erreurs d'exécution de l'outil.

### 10.2. Structure d'erreur

```json
{
  "ok": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "User cannot edit issues in project bank-site.",
    "field": null,
    "retryable": false,
    "details": {
      "project": "bank-site",
      "required_permission": "edit_issues"
    }
  }
}
```

### 10.3. Codes recommandés

```text
VALIDATION_ERROR
NOT_FOUND
FORBIDDEN
CONFLICT
RATE_LIMITED
REDMINE_API_ERROR
TIMEOUT
FILE_TOO_LARGE
UNSUPPORTED_MEDIA_TYPE
INVALID_STATE
PARTIAL_FAILURE
INTERNAL_ERROR
```

### 10.4. Le message doit être réparable

Mauvais:

```text
Invalid request.
```

Bon :

```text
field status_id must be one of [2, 4, 7] for tracker_id=3 in project bank-site.
Call redmine_list_allowed_issue_transitions to retrieve current values.
```

Ne renvoie pas la trace de la pile à l'utilisateur. La trace de la pile est stockée uniquement dans le journal du serveur protégé avec l'ID de corrélation.

---

## 11. Pagination et volume de données

### 11.1. Outils de liste/recherche

Paramètres OBLIGATOIRES :

```json
"limit": {
  "type": "integer",
  "default": 25,
  "minimum": 1,
  "maximum": 100
}
```

Pour l'API Redmine existante, `offset` est autorisé. Pour une implémentation personnalisée, un curseur opaque est préféré si les données peuvent changer activement pendant le parcours.

### 11.2. Métadonnées de pagination

Le résultat doit contenir :

- `limit` réelle ;
- `offset` ou `next_cursor` ;
- `has_more` ;
- `total_count` si son obtention ne crée pas de charge significative.

### 11.3. Sélection des champs

Le paramètre `fields` n'est autorisé qu'en tant que tableau de la liste verte fermée :

```json
"fields": {
  "type": "array",
  "uniqueItems": true,
  "items": {
    "type": "string",
    "enum": ["id", "subject", "status", "assignee", "updated_at"]
  }
}
```

Impossible de transmettre des noms de champs arbitraires directement à SQL, ActiveRecord `select`, au sérialiseur ou à l'API Redmine sans liste autorisée.

### 11.4. Résultats importants

Les journaux, pièces jointes et fichiers volumineux doivent :

- avoir une pagination distincte ;
- être renvoyé par un outil/ressource séparé ;
- pour les données binaires, renvoyer un lien de ressource ou une autre référence limitée au lieu d'intégrer une grande base64 en réponse lorsque cela est possible ;
- ou prendre en charge l'exécution augmentée des tâches si l'opération est vraiment longue et que le client la prend en charge.

`execution.taskSupport` n'est pas défini automatiquement. La valeur par défaut est `forbidden`.

---

## 12. Référence pour un nouvel outil

Exemple d'outil d'écriture abrégé avec `title` obligatoire et `outputSchema` saisi selon §7.1. Format d'erreur — §10. JSON complet — en annexe B.

```json
{
  "name": "redmine_create_issue",
  "title": "Create Redmine issue",
  "description": "Create one issue in a Redmine project. Use redmine_list_project_trackers and redmine_list_project_issue_custom_fields when valid IDs are unknown.",
  "inputSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "project": {
        "type": "string",
        "minLength": 1,
        "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown.",
        "examples": ["1", "ecookbook"]
      },
      "subject": {
        "type": "string",
        "minLength": 1,
        "maxLength": 255,
        "description": "Issue subject."
      }
    },
    "required": ["project", "subject"]
  },
  "outputSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "ok": {"type": "boolean"},
      "data": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "id": {"type": "integer", "minimum": 1},
          "url": {"type": "string", "format": "uri"},
          "created_at": {"type": "string", "format": "date-time"}
        },
        "required": ["id", "url", "created_at"]
      },
      "error": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "code": {"type": "string"},
          "message": {"type": "string"},
          "field": {
            "oneOf": [
              {"type": "string"},
              {"type": "null"}
            ]
          },
          "retryable": {"type": "boolean"}
        },
        "required": ["code", "message", "retryable"]
      }
    },
    "required": ["ok"],
    "oneOf": [
      {
        "properties": {"ok": {"const": true}},
        "required": ["data"],
        "additionalProperties": true,
        "not": {"required": ["error"]}
      },
      {
        "properties": {"ok": {"const": false}},
        "required": ["error"],
        "additionalProperties": true,
        "not": {"required": ["data"]}
      }
    ]
  },
  "annotations": {
    "readOnlyHint": false,
    "destructiveHint": false,
    "idempotentHint": false,
    "openWorldHint": false
  }
}
```

---

## 13. Tests

### 13.1. Tests de schéma

Pour chaque outil, OBLIGATOIRE :

- au moins un appel valide ;
- au moins un appel négatif (par exemple champ obligatoire manquant ou mauvais type).

DEVRAIT couvrir, selon le cas, le schéma :

- appel complet et valide ;
- absence de chaque champ obligatoire ;
- mauvais type de paramètres clés ;
- champ supplémentaire inconnu ;
- valeur en dehors de l'énumération ;
- valeur hors plage ;
- date/date-heure erronée ;
- dépassement de `maxItems`, `maxLength` et de la taille du fichier ;
- violation de l'interdépendance des champs (les deux champs XOR à la fois ; aucun des deux champs obligatoires).

### 13.2. Tests d'autorisation

Pour les opérations d’écriture, de lecture destructrices et sensibles DEVRAIT vérifier :

- utilisateur sans accès au projet ;
- utilisateur avec accès en lecture seule ;
- utilisateur avec autorisation de modification ;
- administrateur si l'outil touche les scénarios d'administration ;
- accès aux notes privées si l'outil les renvoie ou les modifie ;
- tenter de changer l'objet d'un autre projet via un ID substitué.

Pour les outils simples en lecture seule sans données sensibles, les tests d'autorisation PEUVENT être limités à un scénario négatif ou omis avec une brève justification dans MR.

### 13.3. Tests d'idempotence

Pour `idempotentHint: true`, DEVRAIT avoir un test automatique ou manuel de deux ou plusieurs appels séquentiels identiques.

Vérifier l'absence d'effets secondaires déclarés idempotents, par exemple :

- des écritures de journal supplémentaires ;
- des emails répétés ;
- fichiers en double ;
- les doublons de relation ;
- des saisies de temps répétées ;
- événements webhook supplémentaires s'ils font partie de la garantie.

### 13.4. Essais contractuels

DEVRAIT conserver `tools/list` comme instantané ou suivre les modifications du contrat en cas de rupture. CI PEUT détecter :

- changement de nom ;
- suppression des paramètres ;
- changement de type ;
- changement `required` ;
- augmentation du niveau de risque d'annotation ;
- disparition de `outputSchema` ;
- changement incompatible des champs, types, `required`, `enum` / `const` ou branches de réussite/erreur de `outputSchema`.

### 13.5. Tests de sélection LLM

Pour des outils similaires ou facilement confondus, DEVRAIT avoir un ensemble de demandes d'utilisateurs et d'appels d'outils attendus. L'exécution entièrement automatique du LLM PEUT être remplacée par des exemples statiques dans la revue MR ou la description.

Exemples :

| Demande | Outil attendu |
|---|---|
| "Afficher le numéro 123" | `redmine_get_issue` |
| « Rechercher des problèmes concernant OAuth » | `redmine_search_issues` |
| "Ajouter l'observateur 15 au numéro 123" | `redmine_add_issue_watcher` |
| "Supprimer la relation entre les problèmes" | `redmine_delete_issue_relation` |
| "Trouver des problèmes similaires" | `redmine_advanced_search_semantic_search_issues` |

Le test ou l'examen échoue si le modèle avec une probabilité élevée choisit un outil destructeur universel pour une intention de lecture seule ou est obligé de deviner les valeurs `action`.

### 13.6. Tests de récupération d'erreur

DEVRAIT vérifier qu'après des erreurs typiques, le modèle reçoit suffisamment d'informations pour une nouvelle tentative correcte :

- pièce d'identité manquante ;
- statut invalide ;
- Conflit `expected_updated_at` ;
- autorisations insuffisantes ;
- limite dépassée ;
- mauvais type MIME.

---

## 14. Liste de contrôle de révision du code

Un nouvel outil ne peut pas fusionner tant que tous les éléments obligatoires n'ont pas reçu une réponse « oui ».

### But

- [ ] Une action ; pas d'opérations de mixage `action`/`manage` (§3.1–3.2).
- [ ] Opération administrative séparée de l'ordinaire.

### Nom et description

- [ ] Le nom commence par `redmine_` : core — `redmine_<verb>_<entity>`; plugin tiers — `redmine_<plugin_id>_…` (§4.1).
- [ ] Description : objectif, effets secondaires, bref résultat ; outils similaires distinguables (§5).
- [ ] Les références croisées vers d'autres outils utilisent les noms complets de `tools/list` (§5.2.1).

### Recherche contractuelle de sources

- [ ] Pour l'outil de base, l'API REST des ressources, les versions et les plugins si nécessaire étudiés ; le rapport de couverture DEVRAIT être joint au MR (§5.6–5.7).
- [ ] Pour l'outil d'extension, le sérialiseur source/service/point de terminaison REST et au moins une véritable réponse réussie pour chaque formulaire de résultat DOIVENT être vérifiés (§18.5).
- [ ] Contrat comparé aux `tools/list` actuels.

### Input schema

- [ ] Le schéma correspond au §6 (`additionalProperties: false`, types, `required`, `enum`/`const`, contraintes).
- [ ] Chaque paramètre a une `description` significative (§6.14) ; `*_id` a `minimum: 1` (§4.3).
- [ ] Pour `*_id` et d'autres valeurs de recherche, chemin de découverte spécifié (§6.16) : outil de liste, champ de réponse get/list ou `enum`.
- [ ] "Exactement une des …" / contraintes d'interdépendance formalisées dans le schéma, pas seulement dans la description (§5.3, §6.12).
- [ ] Verrouillage optimiste — uniquement `expected_updated_at`, pas `updated_at` (§4.4).
- [ ] Pour les champs optionnels `set_*`, clearing décidé : `null`, outil d'effacement séparé, ou refus explicite (§6.13).
- [ ] Pas d'"objet ou de chaîne JSON" et arbitraires `fields`/`payload`.
- [ ] `*_id` — entier ; validation côté serveur selon §3.4.

### Sortie et erreurs

- [ ] Le nouvel outil a `outputSchema` avec une enveloppe succès/erreur (§7.1–7.2).
- [ ] Champs de résultats stables connus décrits dans `properties` ; `additionalProperties: true` non utilisé à la place du contrat connu.
- [ ] Tous les champs garantis sont en `required`.
- [ ] Champs nullables et facultatifs distingués consciemment.
- [ ] `enum`/`const`, `date`/`date-time`, plages et autres contraintes connues formalisées dans le schéma.
- [ ] Pour les valeurs monétaires et autres valeurs commerciales numériques, les unités, la devise et les unités majeures/mineures sont claires.
- [ ] Invariants métier du résultat reflétés dans le schéma (`const`, `enum`, `required` ou schéma conditionnel), non seulement déduits du nom de l'outil.
- [ ] La description, `outputSchema` et la réponse réelle du gestionnaire/REST/service ne contredisent pas (§7.1.1).
- [ ] Valeurs internes REST/Ruby/plugin normalisées selon un contrat MCP stable ; pas de fuite de nom STI/classe ou de format dépendant des paramètres régionaux (§3.3).
- [ ] L'outil Liste renvoie une structure brève mais suffisante ; la description explique correctement quand l'outil d'obtention correspondant est vraiment nécessaire.
- [ ] Erreurs : `isError`, code stable, message réparable ; pas de secrets ni de trace de pile (§10).

### Annotations

- [ ] Les annotations correspondent au risque (§8) ; test recommandé pour `idempotentHint: true`.

### Sécurité

- [ ] Autorisations, chemin de fichier, SSRF, limites, journaux, destructif/audit — conformément au §9 ; modèles de l’annexe A, au besoin.

### Tests

- [ ] Tests de schéma minimum ; repos par risque (§13).

---

## 15. Compatibilité et modification des outils existants

### 15.1. Modifications radicales

Changement radical :

- renommer l'outil ;
- suppression de terrain ;
- changement de type ;
- ajout d'un nouveau champ obligatoire ;
- changer la signification du champ ;
- changement de sortie incompatible ;
- fusionner plusieurs opérations en une seule ;
- augmenter le risque sans mettre à jour les annotations et la documentation.

### 15.2. Migration de nom

Lors d'une migration, par exemple, depuis l'ancien préfixe `redmine_mcp_` :

```text
redmine_mcp_get_issue
```

au préfixe court `redmine_` :

```text
redmine_get_issue
```

suivre:

1. ajouter un nouveau nom ;
2. conserver temporairement l'ancien alias ;
3. marquer l'ancien outil comme obsolète dans la description **ou ne pas le publier dans `tools/list`** si l'alias n'est nécessaire que pour `tools/call` ;
4. collecter les métriques des appels de l'ancien nom (l'audit log existant par nom d'outil invoqué suffit) ;
5. supprimer l'alias après la période convenue (pas avant la prochaine version majeure, sauf période convenue séparément) ;
6. envoyer `notifications/tools/list_changed` si le serveur déclare `listChanged`.

Exemples actuels (voir [03-core-tools.md](03-core-tools.md)) : `redmine_list_all_users` → `redmine_admin_list_users` ; `redmine_list_files` → `redmine_list_project_files` ; `redmine_delete_file` → `redmine_delete_attachment` ; `redmine_get_server_info` → `redmine_get_mcp_info`. Un alias est accepté dans `tools/call` et n'est pas publié dans `tools/list`.

### 15.3. Modification des descriptions

La description affecte la sélection des outils de modèle et est considérée comme un changement de comportement. En cas de changement substantiel dans la description, DEVRAIT examiner les exemples de sélection LLM ou procéder à un nouvel examen de la sélection.

### 15.4. Version du serveur

La version du plugin MCP est retournée par `redmine_get_mcp_info` (ou les métadonnées serveur). N'ajoutez pas `v1`, `v2` à chaque nom sans besoin réel de supporter des contrats incompatibles en parallèle.

---

## 16. Règles pour les problèmes actuels de Redmine MCP

Lors du développement de nouveaux outils, il est interdit de répéter des schémas issus de l'audit du contrat en cours. Les règles canoniques se trouvent dans les sections correspondantes ; ci-dessous est seulement une carte des problèmes :

| Problème d'audit | Rubrique |
|---|---|
| Noms sans préfixe `redmine_` (y compris les plugins tiers) / style mixte au sein d'un même plugin | §4.1 |
| Le verbe ne correspond pas à la sémantique (`complete_*` avec `done=true/false` au lieu de `set_*`) | §4.2 |
| ID numérique sans `minimum: 1` ou avec la description « Identifiant du problème » | §4.3 |
| Verrouillage optimiste en tant que `updated_at` au lieu de `expected_updated_at` | §4.4, A.2 |
| Paramètres universels `manage_*` / `patch_*` et `action` | §3.1, §4.2 |
| Paramètres sans `type`, énumération uniquement dans la description, tableaux sans `items` | §5.3, §6 |
| Paramètres sans `description` ; descriptions trop courtes sans référence à l'outil de recherche | §6.14 |
| Pas de `examples` sur les paramètres de référence et les identifiants | §6.15 |
| Outil d'écriture avec `*_id` sans chemin de découverte (pas d'outil de liste ni d'options dans la réponse d'obtention) | §6.16 |
| La description promet "exactement l'un des A ou B", le schéma ne l'encode pas | §5.3, §6.12 |
| Noms d'outils courts dans les références croisées (`list_projects` au lieu de `redmine_list_projects`) | §5.2.1 |
| Description de l'outil surchargée d'une demi-page | §5.2 |
| `fields` / `extra_fields` sans schéma ; supplémentaire `required` | §6.4, §6.11 |
| `set_*` sans moyen de vider le champ et sans refus explicite | §6.13 |
| Une annotation définie sur tous les outils d'écriture ; excès `openWorldHint` | §8 |
| `destructiveHint: true` lors d'une `update` / `rename` ordinaire ; mauvais `openWorldHint` sur `create_*` | §8.1, §8.2 |
| La description promet une structure de réponse, mais `outputSchema` manque ou décrit uniquement un objet arbitraire | §7.1 |
| La description, le schéma et la réponse réelle sont contradictoires | §7.1.1 |
| Noms STI/classe ou dates de paramètres régionaux dans la réponse MCP | §3.3 |
| `additionalProperties: true` au lieu des champs de liste/obtention connus | §7.1 |
| `file_path` arbitraire, contournement de la portée du projet, SSRF | §9 |
| E-mail/effet externe dans un seul outil avec changement local | §3.2 |
| Paires ambiguës d'outils similaires | §5.4 |

---

## 17. Structure de l'ensemble d'outils

La liste complète des outils actuels n’est pas dupliquée dans ce document : elle devient rapidement obsolète.

**Source de vérité :**

- outils de base — [03-core-tools.md](03-core-tools.md) et `tools/list` réels sur l'installation ;
- Outils de plugin tiers — §18 et réponse MCP `tools/list` sur l'installation.

**Principes de regroupement** (chaque groupe — outils atomiques distincts selon §3) :

| Groupe | Exemples d'intentions | Préfixe |
|---|---|---|
| Problèmes | obtenir, lister, rechercher, créer, mettre à jour, supprimer, copier, sous-tâches | `redmine_` |
| Relations et observateurs | relation liste/création/suppression ; ajouter/supprimer un observateur | `redmine_` |
| Projets et membres | projets, modules, membres, rôles | `redmine_` |
| Versions et catégories | variantes ; catégories de problèmes | `redmine_` |
| Entrées de temps | lister, créer, mettre à jour, importer, activités | `redmine_` |
| Wiki | lister, obtenir, créer, mettre à jour, renommer, supprimer | `redmine_` |
| Fichiers et pièces jointes | lister, télécharger, supprimer, télécharger | `redmine_` |
| Administrateur | utilisateurs, rôles, info de session MCP | `redmine_admin_` ou `redmine_get_mcp_info` |
| Entités de plugin | listes de contrôle, recherche, etc. | `redmine_` + `plugin_id`, par ex. `redmine_advanced_search_` |

Avant d'ajouter un nouvel outil, DEVRAIT vérifier la réponse MCP `tools/list` et le groupe correspondant : ne dupliquez pas l'outil existant et ne mélangez pas différentes intentions dans un seul nom.

Si un groupe dispose d'un outil d'écriture avec un paramètre ID (`status_id`, `role_ids`, …), le même groupe DOIT avoir un chemin de découverte (§6.16).

Les outils d'administration sont publiés uniquement pour les utilisateurs disposant des droits requis (§9.1).

---

## 18. Extensions de plugins tiers

Section destinée aux auteurs de plugins Redmine qui ajoutent des outils via l'API d'extension. Description technique de l'API, des hooks et des cas extrêmes — dans [04-extensions.md](04-extensions.md).

Les extensions suivent les mêmes règles de contrat, de sécurité et de dénomination (§3–§10, §4.1) que les outils de base de `redmine_mcp`.

### 18.1. Quand publier quoi

| Primitif | Quand utiliser |
|---|---|
| **Outil** | Une action sur l'entité plugin ou Redmine : créer, obtenir, mettre à jour, supprimer, rechercher |
| **Ressource** | Contenu volumineux ou statique par URI stable : corps du wiki, fichier, rapport long |
| **Invite** | Modèle de scénario reproductible pour l'utilisateur, pas d'opération avec effet secondaire |
| **`extend_tool`** | Paramètre ou hook faisant logiquement partie de l'outil de base existant (par exemple `include_*` lors de la lecture du problème) |

Si le modèle peut réaliser l'intention avec un outil séparé sans deviner `action` — préférez **propre outil**, pas `extend_tool` qui gonfle un autre schéma.

### 18.2. Inscription

- Le fichier d'extension se charge au démarrage de Redmine : `lib/<plugin_id>/mcp.rb` (voir `ExtensionLoader`).
- Le module dans `mcp.rb` DOIT être `PluginName::Mcp` (`extend RedmineMcp::ExtensionApi`) : Zeitwerk dérive le nom du fichier.
- Avant l'enregistrement DEVRAIT vérifier `mcp_extension_enabled?` — une dépendance dure sur `redmine_mcp` dans gemspec n'est pas requise.
- Utilisez `register_tool_once` pour l'enregistrement afin que le rechargement ne duplique pas l'outil.
- Le nom complet dans `tools/list` DOIT commencer par `redmine_` (§4.1).
- L'outil DOIT avoir `title`, `description`, `input_schema`, `output_schema`, `permission` et `annotations` ; duplication de nom interdite.
- L'outil est visible dans la réponse MCP `tools/list` uniquement pour les utilisateurs disposant de l'autorisation correspondante.

### 18.3. Appellation

- Le nom DOIT commencer par `redmine_` ; puis — `plugin_id` et `<verb>_<entity>` : `redmine_redmine_advanced_checklists_<verb>_<entity>`, `redmine_advanced_search_<verb>_<entity>`.
- Verbes et interdiction `manage_*` — selon §4.2 et §3.1.
- Ne copiez pas les noms des outils principaux et ne publiez pas de deuxième outil avec la même intention sous un nom différent.

Avant l'enregistrement DEVRAIT comparer avec la réponse `tools/list` sur l'installation cible.

### 18.4. Autorisations et sécurité

- `permission` DOIT correspondre aux autorisations réelles de Redmine ou du plugin, et non à un rôle distinct "mcp uniquement".
- Pour les opérations de problème DEVRAIT utiliser `register_issue_tool` et `find_accessible_issue` au lieu de copier les vérifications de visibilité et de module de projet.
- Si `module_name` est défini, l'outil DOIT être dans `tools/list` uniquement lorsque l'utilisateur a déclaré l'autorisation dans au moins un projet visible avec le module activé. Sans `module_name`, l'autorisation dans au moins un projet visible est suffisante. Le gestionnaire vérifie toujours un problème spécifique, y compris son module de projet.
- Arguments répétés côté serveur et validation des autorisations dans le gestionnaire — conformément aux §3.4 et §9, même si l'outil est masqué dans `tools/list` pour les autres utilisateurs.

### 18.5. Mise en œuvre propre

**Couche MCP fine.** `mcp.rb` doit contenir principalement l'enregistrement des outils : schémas, descriptions, autorisations, annotations et gestionnaires courts. Le gestionnaire valide les arguments, vérifie le contexte et délègue l’exécution à une classe/un service séparé.

La logique métier du plugin doit rester dans les modèles et services ordinaires et ne pas dépendre de MCP.

Si la logique n'est nécessaire que pour MCP - par ex. fusionner les données de plusieurs modèles, normaliser la réponse REST au contrat MCP, calculer les champs dérivés ou préparer le résultat de l'outil — PEUT le déplacer pour séparer `mcp_tools.rb`. Si un tel fichier devient volumineux, DEVRAIT être divisé en classes par entité ou opération, par ex. `mcp_tools/clients.rb`, `mcp_tools/deals.rb`, `mcp_tools/subscriptions.rb`.

Ne placez pas la logique métier et les transformations importantes directement dans lambda/handler à l'intérieur de `mcp.rb`.

**Accès aux données.**

- Modèles et services de plugins — si la logique est déjà là.
- `internal_request` / `internal_get` / REST — s'il est nécessaire de réutiliser le contrôleur API existant ; le point de terminaison doit prendre en charge `accept_api_auth`. Utilisez `internal_request` pour `POST`, `PUT`, `PATCH` et `DELETE` ; utilisez `internal_get` ou `internal_request(method: 'GET', ...)` pour les lectures. Vérifiez les échecs avec `internal_request_error?`.

**`extend_tool` — modérément.** Approprié lorsque le paramètre fait partie d'une intention avec l'outil principal. Inapproprié lorsque le plugin ajoute essentiellement un sous-système séparé : il est préférable de posséder son propre préfixe et ses propres outils, un lien vers le noyau décrit dans la `description` ou les instructions du serveur.

**Contrat comme noyau.** Entrée — selon §6. Sortie — selon §7.1 et §7.1.1 : champs stables, `required`, `enum`/`const`, unités, normalisation interne de l'API. Annotations par risque, erreurs réparables (§8, §10). Verrouillage optimiste — `expected_updated_at` (§4.4). Chaque paramètre — `description` (§6.14). Références croisées — noms complets (§5.2.1). Chaque paramètre d'écriture `*_id` — chemin de découverte (§6.16) : séparez `list_*` ou options avec `id` dans la réponse get/list et référence explicite dans la description du paramètre.

Avant de publier, l'outil d'extension DOIT vérifier le sérialiseur source/le service/le point de terminaison REST et au moins une véritable réponse réussie pour chaque formulaire de résultat.

**Code partagé — dans `redmine_mcp`.** Lors du développement d'une extension, si un fragment peut être nécessaire à un autre plugin MCP, DEVRAIT l'ajouter immédiatement au noyau `redmine_mcp`, et non le copier dans `lib/<plugin>/mcp*.rb`.

Critère : la logique n'est pas liée à un seul domaine de plugin (listes de contrôle, recherche, …) et décrit le contrat MCP, l'API d'extension ou le modèle d'intégration typique.

| Où | Quoi |
|------|-----|
| **`redmine_mcp`** | `SchemaNormalizer.envelope_output`, `REST_OBJECT_SCHEMA` / `REST_ARRAY_SCHEMA`, extension `ExtensionApi` (`register_issue_tool`, `issue_permission`, `internal_request`, …), `ToolResponse`, aides aux autorisations communes par `issue_id` / `project_id` |
| **Extension du plugin** | `mcp.rb` — enregistrement des outils et gestionnaires courts ; `mcp_tools.rb` / `mcp_tools/*.rb` — Récupération, agrégation, normalisation spécifiques à MCP ; modèles/services ordinaires — logique métier ne dépendant pas de MCP |

**Emplacement recommandé pour l'extension :**

- `mcp.rb` — enregistrement des outils et gestionnaires courts ;
- `mcp_tools.rb` / `mcp_tools/*.rb` — récupération, agrégation et normalisation des données spécifiques à MCP ;
- modèles/services ordinaires — logique métier ne dépendant pas de MCP.

Avant de copier l'assistant d'une autre extension DEVRAIT vérifier si l'analogue existe déjà dans `redmine_mcp` ; en cas d'absence, déplacez-vous vers le noyau dans le même PR, ne dupliquez pas.

En savoir plus sur l'API d'extension — [04-extensions.md](04-extensions.md) (§ "Méthodes d'assistance ExtensionApi").

### 18.6. Anti-modèles

INTERDIT ou déconseillé :

- enregistrer des outils sur chaque requête HTTP ;
- échec en cas d'erreur du plugin voisin au démarrage ;
- mélanger la lecture, l'écriture et l'administration dans un seul outil ;
- duplication de l'outil de base "avec un nom différent" ;
- étendre un autre outil avec des paramètres optionnels « pour le futur » ;
- retour dans les champs internes de MCP non disponibles pour l'utilisateur dans l'interface utilisateur/API du plugin ;
- publier les noms de classe STI, les dates de paramètres régionaux ou la représentation REST si le schéma MCP définit un contrat différent (§3.3, §7.1.1) ;
- décrivant l'élément de liste uniquement comme `{ "type": "object", "additionalProperties": true }` (§7.1) ;
- publication de `set_*_status` / similaire avec `status_id` sans donner au modèle le moyen de connaître les identifiants autorisés (§6.16) ;
- duplication des helpers MCP communs dans l'extension (enveloppe `outputSchema`, wrappers `internal_request`, autorisation d'émission) si leur place est dans `redmine_mcp` — voir §18.5.

### 18.7. Vérification avant la fusion

- [ ] Le nom de l'outil commence par `redmine_` selon §4.1 / §18.3.
- [ ] Charges d'extension au démarrage ; l'outil apparaît dans `tools/list` pour l'utilisateur disposant de droits.
- [ ] Outil absent pour les utilisateurs sans droits et lorsque le flag d'extension MCP du plugin est désactivé.
- [ ] Contrat et liste de contrôle (§14) satisfaits, y compris comparaison description / schéma de sortie / réponse réelle (§7.1.1) ; tests selon §13 si nécessaire.
- [ ] Sérialiseur / REST / service vérifié sur au moins une réponse réellement réussie pour chaque formulaire de résultat publié (par exemple, lister et obtenir si les deux sont publiés).
- [ ] Aucune duplication de l'outil existant dans `tools/list`.
- [ ] Pour chaque paramètre d'écriture `*_id` il y a un chemin de découverte (§6.16).

---

## 19. Sources et socle normatif

Document préparé le 2026-07-22 basé sur les sources primaires suivantes :

1. Protocole de contexte modèle, **Révision du protocole 2025-11-25**  
   https://modelcontextprotocol.io/spécification/2025-11-25

2. Protocole de contexte de modèle, **Outils**  
   https://modelcontextprotocol.io/spécification/2025-11-25/server/tools

3. Protocole de contexte de modèle, **Référence de schéma**  
   https://modelcontextprotocol.io/spécification/2025-11-25/schema

4. Protocole de contexte modèle, **Meilleures pratiques de sécurité**  
   https://modelcontextprotocol.io/docs/tutorials/security/security_best_practices

5. Protocole de contexte modèle, **Comprendre l'autorisation dans MCP**  
   https://modelcontextprotocol.io/docs/tutorials/security/authorization

6. Blog du protocole de contexte modèle, **Annotations d'outils comme vocabulaire des risques : ce que les indices peuvent et ne peuvent pas faire**  
   https://blog.modelcontextprotocol.io/posts/2026-03-16-tool-annotations/

7. Blog Model Context Protocol, **Instructions du serveur : donner aux LLM un manuel d'utilisation pour votre serveur**  
   https://blog.modelcontextprotocol.io/posts/2025-11-03-using-server-instructions/

8. Schéma JSON, **Référence**  
   https://json-schema.org/understanding-json-schema/reference

9. Schéma JSON, **Valeurs énumérées**  
   https://json-schema.org/understanding-json-schema/reference/enum

10. Schéma JSON, **Validation conditionnelle du schéma**  
    https://json-schema.org/understanding-json-schema/reference/conditionals

11. Redmine, **Présentation de l'API REST**  
    https://www.redmine.org/projects/redmine/wiki/rest_api

12. Redmine, **Problèmes REST**  
    https://www.redmine.org/projects/redmine/wiki/Rest_Issues

13. Redmine, **Modifications de l'API REST**  
    Lien `API changes for each version` sur la page de l'API REST ; vérifié pour toutes les versions prises en charge.

---

## 20. Nouveau critère de préparation des outils

Un nouvel outil MCP est considéré comme prêt lorsque les éléments obligatoires de la liste de contrôle de révision du code (§14) sont satisfaits.

Pour les outils de plug-in tiers également – liste de contrôle §18.7.

Recommandations sur les risques : rapport de couverture (§5.7), tests complémentaires §13.2–13.6 et annexe A. Les tests de schéma minimum (§13.1) et les règles `outputSchema` (§7.1, §7.1.1) sont obligatoires.

---

## Annexe A. Modèles de mise en œuvre recommandés

Les modèles ci-dessous ne sont pas obligatoires pour chaque outil MCP. DEVRAIT les considérer pour un risque élevé : opérations destructrices, outils d'administration, écriture en masse, effets secondaires externes, appels répétés en raison d'un délai d'attente.

### A.1. Suppression en deux phases (préparer / confirmer)

Pour les opérations administratives particulièrement dangereuses :

1. `redmine_prepare_delete_*` renvoie une brève description des conséquences et un jeton unique ;
2. `redmine_confirm_delete_*` accepte les jetons avec un TTL court.

Exigences normatives pour les opérations destructives — au §9.5.

### A.2. Verrouillage optimiste

Pour la mise à jour/suppression sous changement simultané, le paramètre DOIT être nommé `expected_updated_at` (§4.4), et non `updated_at` :

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

Le nom est unifié pour les outils de base et les extensions (y compris les outils d'écriture de liste de contrôle).

En cas de conflit, renvoie `CONFLICT`, l'heure réelle de modification de l'objet (`updated_at` / `updated_on` en réponse) et une recommandation de relire l'objet.

### A.3. Clé d'idempotence

Pour les opérations où la répétition en raison d'un délai d'attente peut créer un doublon :

```json
"idempotency_key": {
  "type": "string",
  "minLength": 8,
  "maxLength": 128
}
```

Particulièrement approprié pour :

- création de problèmes ;
- importation de saisie de temps ;
- téléchargement de fichiers ;
- les opérations en vrac ;
- envoi d'email.

Si l'outil publie `idempotentHint: true`, l'appel répété doit être sûr (§8.2) ; `idempotency_key` est un moyen de garantir cela.

---

## Annexe B. Exemple d'outil complet

Référencez `redmine_create_issue`. Lorsque le format ou l'enveloppe d'une erreur change, mettez à jour les §7, §10 et cette section ; Le §12 reste abrégé.

```json
{
  "name": "redmine_create_issue",
  "title": "Create Redmine issue",
  "description": "Create one issue in a Redmine project. Use redmine_list_project_trackers and redmine_list_project_issue_custom_fields when valid IDs are unknown. This operation may create notifications and is not idempotent unless idempotency_key is supplied.",
  "inputSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "project": {
        "type": "string",
        "minLength": 1,
        "maxLength": 255,
        "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown.",
        "examples": ["1", "ecookbook"]
      },
      "subject": {
        "type": "string",
        "minLength": 1,
        "maxLength": 255,
        "description": "Issue subject."
      },
      "description": {
        "type": "string",
        "maxLength": 100000,
        "description": "Issue description in Redmine text format."
      },
      "tracker_id": {
        "type": "integer",
        "minimum": 1,
        "description": "Tracker ID returned by redmine_list_project_trackers.",
        "examples": [1, 2]
      },
      "priority_id": {
        "type": "integer",
        "minimum": 1,
        "description": "Issue priority ID returned by redmine_list_issue_priorities.",
        "examples": [3, 4]
      },
      "assigned_to_id": {
        "type": "integer",
        "minimum": 1,
        "description": "User ID of the assignee, from redmine_list_project_members."
      },
      "due_date": {
        "type": "string",
        "format": "date",
        "description": "Due date in YYYY-MM-DD format.",
        "examples": ["2026-07-30"]
      },
      "custom_fields": {
        "type": "array",
        "maxItems": 100,
        "items": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "id": {"type": "integer", "minimum": 1},
            "value": {
              "oneOf": [
                {"type": "string"},
                {"type": "number"},
                {"type": "boolean"},
                {
                  "type": "array",
                  "items": {"type": "string"}
                }
              ]
            }
          },
          "required": ["id", "value"]
        }
      },
      "idempotency_key": {
        "type": "string",
        "minLength": 8,
        "maxLength": 128
      }
    },
    "required": ["project", "subject"]
  },
  "outputSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "ok": {"type": "boolean"},
      "data": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "id": {"type": "integer"},
          "url": {"type": "string", "format": "uri"},
          "created_at": {"type": "string", "format": "date-time"}
        },
        "required": ["id", "url", "created_at"]
      },
      "error": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "code": {"type": "string"},
          "message": {"type": "string"},
          "field": {
            "oneOf": [
              {"type": "string"},
              {"type": "null"}
            ]
          },
          "retryable": {"type": "boolean"}
        },
        "required": ["code", "message", "retryable"]
      }
    },
    "required": ["ok"],
    "oneOf": [
      {
        "properties": {"ok": {"const": true}},
        "required": ["data"],
        "additionalProperties": true,
        "not": {"required": ["error"]}
      },
      {
        "properties": {"ok": {"const": false}},
        "required": ["error"],
        "additionalProperties": true,
        "not": {"required": ["data"]}
      }
    ]
  },
  "annotations": {
    "readOnlyHint": false,
    "destructiveHint": false,
    "idempotentHint": false,
    "openWorldHint": false
  },
  "execution": {
    "taskSupport": "forbidden"
  }
}
```

Remarque : si le serveur garantit l'idempotence lorsque `idempotency_key` est présent, l'annotation décrit toujours l'outil dans son ensemble. Par conséquent, la valeur sûre reste `false` si l'appel sans clé est autorisé.

