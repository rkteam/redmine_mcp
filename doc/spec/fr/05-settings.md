# Paramètres et journalisation

[Deutsch](../de/05-settings.md) | [English](../en/05-settings.md) | [Español](../es/05-settings.md) | [Français](05-settings.md) | [Italiano](../it/05-settings.md) | [日本語](../ja/05-settings.md) | [한국어](../ko/05-settings.md) | [Polski](../pl/05-settings.md) | [Português (Brasil)](../pt-BR/05-settings.md) | [Русский](../ru/05-settings.md) | [中文](../zh/05-settings.md)

## Vue d'ensemble

Le plugin Redmine MCP est configuré via l'interface standard des paramètres de plugin Redmine. L'opération MCP est également journalisée.

## Objectif

Donner à l'administrateur le contrôle de l'activation de MCP et de l'activation de l'intégration MCP pour des plugins individuels.

## Domaines concernés

- Paramètres
- UI
- Plugins

## Règles métier

### Paramètres

Les paramètres sont disponibles dans **Administration → Plugins → Redmine MCP → Configurer**.

| Paramètre | Par défaut | Description |
|----------|--------------|----------|
| Activer MCP | désactivé | Active ou désactive le point de terminaison `/mcp`. Lorsqu'il est activé, les extensions MCP des plugins installés sont chargées automatiquement |
| Mode lecture seule | désactivé | Bloque les outils d'écriture et les actions d'écriture |
| Extensions MCP | toutes activées | Cases à cocher à côté des noms des plugins installés avec intégration MCP |

### Extensions MCP dans l'interface

- Un champ texte pour une liste d'identifiants (« Disabled extensions ») et une liste de référence de tous les plugins installés ne sont pas utilisés.
- Une case à cocher séparée de chargement automatique des extensions n'est pas utilisée.
- Au lieu de cela, la page des paramètres affiche une liste des plugins installés qui ont une intégration MCP.
- Un plugin est considéré comme ayant une intégration MCP si une source d'extension est trouvée selon la convention de chargement automatique : `mcp.rb` dans le plugin ou le fichier intégré `lib/redmine_mcp/extensions/<plugin.id>.rb` dans `redmine_mcp` (voir [04-extensions.md](04-extensions.md)).
- Le plugin `redmine_mcp` n'est pas affiché dans cette liste.
- Chaque élément a une case à cocher et le nom du plugin.
- La légende de la liste a un toggle Tout cocher / Tout décocher, comme les projets et les trackers sur un formulaire de champ personnalisé.
- Une case cochée signifie que l'extension MCP du plugin est chargée lorsque MCP est activé.
- Une case non cochée signifie que l'extension du plugin n'est pas chargée même si le fichier d'extension existe.
- Si aucun plugin installé a une intégration MCP, la liste est vide : le message standard Redmine « aucune donnée » est affiché ; le toggle Tout cocher / Tout décocher est masqué.
- Les identifiants de plugins désactivés précédemment sauvegardés continuent de s'appliquer : les cases correspondantes apparaissent non cochées.

### Comportement lors des changements de paramètres

- La désactivation de MCP bloque immédiatement toutes les requêtes vers `/mcp` (HTTP 503).
- Lorsque MCP est activé, les extensions se chargent au démarrage de Redmine. Lorsque MCP est désactivé, le chargement automatique des extensions ne s'exécute pas.
- Le changement des cases des extensions MCP prend effet après un redémarrage de Redmine.

## Journalisation

### Ce qui est journalisé

- début et fin du chargement des extensions ;
- enregistrement réussi d'outils, ressources, prompts ;
- extension d'outils existants ;
- erreurs d'enregistrement et de chargement des extensions ;
- erreurs d'exécution d'outils ;
- refus d'accès MCP et aux outils.

### Format

- Les messages sont écrits dans le journal Rails standard.
- Chaque message a le préfixe `[redmine_mcp]`.
- Un paramètre de niveau de journalisation séparé n'est pas utilisé : le plugin écrit tous ses messages.

## Cas limites

- Si toutes les cases des extensions MCP sont activées (ou aucun plugin a une intégration), toutes les extensions trouvées se chargent lorsque MCP est activé.
- Un plugin sans extension MCP (ni `mcp.rb` ni intégration intégrée) n'est pas affiché dans la liste et n'est pas désactivé par ces paramètres.
- Si un plugin obtient ultérieurement une intégration MCP, sa case est activée par défaut sauf si le plugin avait été précédemment désactivé.
- Les identifiants de plugins inconnus ou supprimés dans les listes désactivées sauvegardées sont ignorés.
- Un flag de chargement automatique d'extensions précédemment sauvegardé est ignoré : le chargement des extensions suit Activer MCP.
- Un niveau de journalisation précédemment sauvegardé est ignoré et supprimé lors de la sauvegarde des paramètres.
- Avec le mode lecture seule activé, les outils d'écriture restent dans `tools/list` (si l'utilisateur a les permissions) mais retournent une erreur lors de l'appel ; les actions de lecture des outils combinés continuent de fonctionner.

## Gestion des erreurs

- Les erreurs de paramètres ne doivent pas bloquer le démarrage de Redmine.
- Les erreurs de journalisation n'affectent pas le traitement des requêtes MCP.

## Scénarios de test

1. MCP désactivé — les requêtes vers `/mcp` retournent HTTP 503.
2. MCP activé — les requêtes sont traitées.
3. Un plugin avec intégration MCP non cochée — ses outils sont absents après redémarrage.
4. La page des paramètres n'a pas de champ de niveau de journalisation ; les messages MCP sont écrits dans le journal Rails.
5. La page des paramètres affiche les noms uniquement des plugins installés avec intégration MCP ; chacun a une case à cocher.
6. Un plugin sans intégration MCP n'est pas affiché sur la page des paramètres.
7. Lorsque MCP est désactivé, les extensions d'autres plugins ne sont pas chargées au démarrage.
