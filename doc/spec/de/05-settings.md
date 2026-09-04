# Einstellungen und Protokollierung

[Deutsch](05-settings.md) | [English](../en/05-settings.md) | [Español](../es/05-settings.md) | [Français](../fr/05-settings.md) | [Italiano](../it/05-settings.md) | [日本語](../ja/05-settings.md) | [한국어](../ko/05-settings.md) | [Polski](../pl/05-settings.md) | [Português (Brasil)](../pt-BR/05-settings.md) | [Русский](../ru/05-settings.md) | [中文](../zh/05-settings.md)

## Überblick

Das Redmine-MCP-Plugin wird über die standardmäßige Redmine-Plugin-Einstellungsoberfläche konfiguriert. Der MCP-Betrieb wird zusätzlich protokolliert.

## Ziel

Dem Administrator Kontrolle über die Aktivierung von MCP und die MCP-Integration einzelner Plugins geben.

## Betroffene Bereiche

- Settings
- UI
- Plugins

## Geschäftsregeln

### Einstellungsparameter

Einstellungen sind unter **Administration → Plugins → Redmine MCP → Configure** verfügbar.

| Parameter | Standard | Beschreibung |
|----------|--------------|----------|
| Enable MCP | aus | Aktiviert oder deaktiviert den Endpunkt `/mcp`. Bei Aktivierung werden MCP-Erweiterungen installierter Plugins automatisch geladen |
| Read-only mode | aus | Blockiert Schreib-Tools und Schreibaktionen |
| MCP extensions | alle aktiviert | Checkboxen neben Namen installierter Plugins mit MCP-Integration |

### MCP-Erweiterungen in der UI

- Ein Textfeld für eine Liste von Identifikatoren („Disabled extensions“) und eine Referenzliste aller installierten Plugins werden nicht verwendet.
- Eine separate Auto-Load-Erweiterungen-Checkbox wird nicht verwendet.
- Stattdessen zeigt die Einstellungsseite eine Liste installierter Plugins mit MCP-Integration.
- Ein Plugin gilt als MCP-integriert, wenn eine Erweiterungsquelle nach der Auto-Load-Konvention gefunden wird: `mcp.rb` im Plugin oder die eingebaute Datei `lib/redmine_mcp/extensions/<plugin.id>.rb` in `redmine_mcp` (siehe [04-extensions.md](04-extensions.md)).
- Das Plugin `redmine_mcp` erscheint nicht in dieser Liste.
- Jedes Element hat eine Checkbox und den Plugin-Namen.
- Die Listenlegende hat einen Check all / Uncheck all-Schalter wie bei Projekten und Trackern in einem Custom-Field-Formular.
- Aktivierte Checkbox bedeutet: die MCP-Erweiterung des Plugins wird geladen, wenn MCP aktiviert ist.
- Deaktivierte Checkbox bedeutet: die Erweiterung des Plugins wird nicht geladen, auch wenn die Erweiterungsdatei existiert.
- Hat kein installiertes Plugin MCP-Integration, ist die Liste leer: die standardmäßige Redmine-„no data“-Meldung wird angezeigt; der Check all / Uncheck all-Schalter ist ausgeblendet.
- Zuvor gespeicherte deaktivierte Plugin-Identifikatoren gelten weiter: die entsprechenden Checkboxen erscheinen deaktiviert.

### Verhalten bei Einstellungsänderungen

- Deaktivierung von MCP blockiert sofort alle Anfragen an `/mcp` (HTTP 503).
- Ist MCP aktiviert, werden Erweiterungen beim Redmine-Start geladen. Ist MCP deaktiviert, läuft kein Extension-Auto-Load.
- Änderungen an MCP-Erweiterungs-Checkboxen werden nach einem Redmine-Neustart wirksam.

## Protokollierung

### Was protokolliert wird

- Start und Ende des Ladens von Erweiterungen;
- erfolgreiche Registrierung von Tools, Resources, Prompts;
- Erweiterung bestehender Tools;
- Registrierungs- und Ladefehler für Erweiterungen;
- Fehler bei der Tool-Ausführung;
- MCP- und Tool-Zugriffsverweigerungen.

### Format

- Meldungen werden in das standardmäßige Rails-Log geschrieben.
- Jede Meldung hat das Präfix `[redmine_mcp]`.
- Eine separate Logging-Level-Einstellung wird nicht verwendet: das Plugin schreibt alle seine Meldungen.

## Randfälle

- Sind alle MCP-Erweiterungs-Checkboxen aktiviert (oder hat kein Plugin Integration), werden beim Aktivieren von MCP alle gefundenen Erweiterungen geladen.
- Ein Plugin ohne MCP-Erweiterung (weder `mcp.rb` noch eingebaute Integration) erscheint nicht in der Liste und wird durch diese Einstellungen nicht deaktiviert.
- Erhält ein Plugin später MCP-Integration, ist seine Checkbox standardmäßig aktiviert, sofern das Plugin nicht zuvor deaktiviert war.
- Unbekannte oder entfernte Plugin-Identifikatoren in gespeicherten Deaktivierungslisten werden ignoriert.
- Ein zuvor gespeichertes Extension-Auto-Load-Flag wird ignoriert: das Laden von Erweiterungen folgt Enable MCP.
- Ein zuvor gespeichertes Logging-Level wird ignoriert und beim Speichern der Einstellungen entfernt.
- Bei aktiviertem Read-only-Modus bleiben Schreib-Tools in `tools/list` (wenn der Benutzer Berechtigungen hat), liefern beim Aufruf aber einen Fehler; Leseaktionen kombinierter Tools funktionieren weiter.

## Fehlerbehandlung

- Einstellungsfehler dürfen den Redmine-Start nicht blockieren.
- Protokollierungsfehler beeinflussen die MCP-Anfrageverarbeitung nicht.

## Testszenarien

1. MCP deaktiviert — Anfragen an `/mcp` liefern HTTP 503.
2. MCP aktiviert — Anfragen werden verarbeitet.
3. Plugin mit MCP-Integration deaktiviert — dessen Tools fehlen nach Neustart.
4. Die Einstellungsseite hat kein Logging-Level-Feld; MCP-Meldungen werden ins Rails-Log geschrieben.
5. Die Einstellungsseite zeigt nur Namen installierter Plugins mit MCP-Integration; jedes hat eine Checkbox.
6. Ein Plugin ohne MCP-Integration erscheint nicht auf der Einstellungsseite.
7. Ist MCP deaktiviert, werden Erweiterungen anderer Plugins beim Start nicht geladen.
