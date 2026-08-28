# Authentifizierung und Autorisierung

[Deutsch](02-authentication.md) | [English](../en/02-authentication.md) | [Español](../es/02-authentication.md) | [Français](../fr/02-authentication.md) | [Italiano](../it/02-authentication.md) | [日本語](../ja/02-authentication.md) | [한국어](../ko/02-authentication.md) | [Polski](../pl/02-authentication.md) | [Português (Brasil)](../pt-BR/02-authentication.md) | [Русский](../ru/02-authentication.md) | [中文](../zh/02-authentication.md)

## Überblick

Der MCP-Zugriff nutzt die standardmäßige Redmine-API-Schlüssel-Authentifizierung. Alle Operationen laufen im Namen des Benutzers, dem der Schlüssel gehört.

## Ziel

Sicherstellen, dass MCP die Redmine-Sicherheit nicht umgeht und Benutzer nur erlaubte Aktionen ausführen können.

## Betroffene Bereiche

- Permissions
- API
- Users

## Geschäftsregeln

### Authentifizierung

- Die Redmine-REST-API muss aktiviert sein, um auf `/mcp` zugreifen zu können.
- Der API-Schlüssel wird im Header `X-Redmine-API-Key` übergeben (nicht aus dem JSON-Anfragebody oder Query-String).
- Nur Schlüssel aktiver Benutzer werden akzeptiert.
- Anfragen ohne Schlüssel oder mit ungültigem Schlüssel werden abgelehnt.

### Globale MCP-Berechtigung

- Der Benutzer muss die globale Berechtigung **Use MCP** (`use_mcp`) haben oder Redmine-Administrator sein.
- Die Berechtigung `use_mcp` wird manuell für die erforderlichen Rollen unter **Administration → Roles and permissions** aktiviert.
- Administratoren haben immer MCP-Zugriff: die standardmäßige globale Redmine-Berechtigungsprüfung erlaubt Admin unabhängig von Rollen.
- Für andere Benutzer ohne `use_mcp` wird die Anfrage abgelehnt, auch mit gültigem API-Schlüssel.

### Tool-Berechtigungen

- Jedes Tool hat eine eigene Redmine-Berechtigungsanforderung.
- Ein Tool erscheint in `tools/list` nur, wenn der Benutzer die Berechtigung zur Nutzung hat.
- Berechtigungen werden beim Tool-Aufruf erneut geprüft.
- Daten werden nach Redmine-Sichtbarkeitsregeln gefiltert (Projekte, Vorgänge, Mitglieder).

### Resource- und Prompt-Berechtigungen

- Resources und Prompts können eigene Berechtigungsanforderungen haben.
- Ohne Berechtigung wird eine Resource oder ein Prompt nicht gelistet und kann nicht gelesen werden.
- Berechtigungsprüfungen für Resources und Prompts berücksichtigen URI und Eingabeargumente (einschließlich `project` / `project_id`). Ist kein Projekt in den Argumenten angegeben, genügt die Berechtigung in mindestens einem sichtbaren Projekt.
- Eine Erweiterung kann eine explizite Regel zur Projektauflösung aus URI und Argumenten definieren.

## Randfälle

- Ein inaktiver Benutzer kann MCP nicht nutzen, auch nicht mit zuvor ausgestelltem Schlüssel.
- Ein Administrator hat MCP-Zugriff ohne separate `use_mcp`-Zuweisung.
- Ein Tool mit entitätsbezogenen Berechtigungsprüfungen (z. B. Vorgang) kann in `tools/list` mit leeren Argumenten sichtbar sein, wenn der Benutzer die entsprechende Berechtigung in mindestens einem Projekt hat.
- Erfordert ein solches Tool zusätzlich ein Redmine-Projektmodul, bedeutet „mindestens ein Projekt“ ein sichtbares Projekt, in dem der Benutzer die Berechtigung hat und das angegebene Modul aktiviert ist. Ohne Modulanforderung genügt die Berechtigung in mindestens einem sichtbaren Projekt. Die Anwesenheit in `tools/list` bedeutet keine Berechtigung für einen bestimmten Vorgang: Berechtigungen und Objektverfügbarkeit werden beim Aufruf erneut geprüft.

## Fehlerbehandlung

| Situation | Ergebnis |
|----------|-----------|
| REST-API deaktiviert | HTTP 401 |
| Ungültiger oder fehlender API-Schlüssel | HTTP 401 |
| Keine Use-MCP-Berechtigung | HTTP 403 |
| Keine Berechtigung für ein bestimmtes Tool | Tool fehlt in `tools/list`; direkter Aufruf — Fehler „Permission denied“ |
| Entität für Benutzer nicht verfügbar | Tool-Antwort mit Fehlerbeschreibung (z. B. „Issue not found“) |

## Testszenarien

1. Anfrage mit gültigem Schlüssel und Use-MCP-Berechtigung — erfolgreicher Zugriff.
2. Anfrage ohne API-Schlüssel-Header — HTTP 401.
3. Anfrage mit Nicht-Admin-Schlüssel ohne Use-MCP-Berechtigung — HTTP 403.
4. Administrator-Schlüssel ohne Rolle mit `use_mcp` — erfolgreicher Zugriff.
5. Der Benutzer sieht in `tools/list` nur Tools, für die er berechtigt ist.
6. Aufruf eines Tools für einen nicht zugänglichen Vorgang liefert einen Fehler, nicht die Daten eines anderen Benutzers.
7. Ein vorgangsbezogenes Tool mit Projektmodul-Anforderung ist nicht in `tools/list` sichtbar, wenn der Benutzer die Berechtigung hat, aber kein sichtbares Projekt mit aktiviertem Modul; es ist sichtbar, wenn ein solches Projekt existiert.
