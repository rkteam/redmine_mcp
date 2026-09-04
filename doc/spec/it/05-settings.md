# Impostazioni e logging

[Deutsch](../de/05-settings.md) | [English](../en/05-settings.md) | [Español](../es/05-settings.md) | [Français](../fr/05-settings.md) | [Italiano](05-settings.md) | [日本語](../ja/05-settings.md) | [한국어](../ko/05-settings.md) | [Polski](../pl/05-settings.md) | [Português (Brasil)](../pt-BR/05-settings.md) | [Русский](../ru/05-settings.md) | [中文](../zh/05-settings.md)

## Panoramica

Il plugin Redmine MCP viene configurato tramite l'interfaccia standard delle impostazioni dei plugin di Redmine. Il funzionamento di MCP viene inoltre registrato nei log.

## Obiettivo

Dare all'amministratore il controllo sull'abilitazione di MCP e sull'abilitazione dell'integrazione MCP per singoli plugin.

## Aree interessate

- Impostazioni
- UI
- Plugin

## Regole di business

### Parametri delle impostazioni

Le impostazioni sono disponibili in **Amministrazione → Plugin → Redmine MCP → Configura**.

| Parametro | Predefinito | Descrizione |
|----------|--------------|----------|
| Abilita MCP | disattivato | Abilita o disabilita l'endpoint `/mcp`. Quando abilitato, le estensioni MCP dei plugin installati vengono caricate automaticamente |
| Modalità read-only | disattivato | Blocca gli strumenti di scrittura e le azioni di scrittura |
| Estensioni MCP | tutte abilitate | Caselle di controllo accanto ai nomi dei plugin installati con integrazione MCP |

### Estensioni MCP nell'interfaccia

- Non viene usato un campo di testo per un elenco di identificatori ("Estensioni disabilitate") né un elenco di riferimento di tutti i plugin installati.
- Non viene usata una casella di controllo separata per il caricamento automatico delle estensioni.
- Al contrario, la pagina delle impostazioni mostra un elenco dei plugin installati che hanno integrazione MCP.
- Un plugin è considerato dotato di integrazione MCP se viene trovata una fonte di estensione secondo la convenzione di caricamento automatico: `mcp.rb` nel plugin o il file integrato `lib/redmine_mcp/extensions/<plugin.id>.rb` in `redmine_mcp` (vedi [04-extensions.md](04-extensions.md)).
- Il plugin `redmine_mcp` non viene mostrato in questo elenco.
- Ogni voce ha una casella di controllo e il nome del plugin.
- La legenda dell'elenco ha un interruttore Seleziona tutto / Deseleziona tutto, come per progetti e tracker in un modulo di campo personalizzato.
- Una casella selezionata significa che l'estensione MCP del plugin viene caricata quando MCP è abilitato.
- Una casella deselezionata significa che l'estensione del plugin non viene caricata anche se il file di estensione esiste.
- Se nessun plugin installato ha integrazione MCP, l'elenco è vuoto: viene mostrato il messaggio standard Redmine "nessun dato"; l'interruttore Seleziona tutto / Deseleziona tutto è nascosto.
- Gli identificatori di plugin precedentemente salvati come disabilitati continuano ad applicarsi: le caselle di controllo corrispondenti appaiono deselezionate.

### Comportamento al cambio delle impostazioni

- La disabilitazione di MCP blocca immediatamente tutte le richieste a `/mcp` (HTTP 503).
- Quando MCP è abilitato, le estensioni vengono caricate all'avvio di Redmine. Quando MCP è disabilitato, il caricamento automatico delle estensioni non viene eseguito.
- La modifica delle caselle di controllo delle estensioni MCP ha effetto dopo un riavvio di Redmine.

## Registrazione

### Cosa viene registrato

- inizio e fine del caricamento delle estensioni;
- registrazione riuscita di strumenti, risorse, prompt;
- estensione degli strumenti esistenti;
- errori di registrazione e caricamento delle estensioni;
- errori di esecuzione degli strumenti;
- negazioni di accesso a MCP e agli strumenti.

### Formato

- I messaggi vengono scritti nel log Rails standard.
- Ogni messaggio ha il prefisso `[redmine_mcp]`.
- Non viene usata un'impostazione separata del livello di logging: il plugin scrive tutti i suoi messaggi.

## Casi limite

- Se tutte le caselle di controllo delle estensioni MCP sono abilitate (o nessun plugin ha integrazione), tutte le estensioni trovate vengono caricate quando MCP è abilitato.
- Un plugin senza estensione MCP (né `mcp.rb` né integrazione integrata) non viene mostrato nell'elenco e non viene disabilitato da queste impostazioni.
- Se un plugin acquisisce successivamente l'integrazione MCP, la sua casella di controllo è abilitata per impostazione predefinita a meno che il plugin non fosse stato precedentemente disabilitato.
- Identificatori di plugin sconosciuti o rimossi negli elenchi salvati di disabilitati vengono ignorati.
- Un flag di caricamento automatico delle estensioni precedentemente salvato viene ignorato: il caricamento delle estensioni segue Abilita MCP.
- Un livello di logging precedentemente salvato viene ignorato e rimosso al salvataggio delle impostazioni.
- Con la modalità Read-only abilitata, gli strumenti di scrittura restano in `tools/list` (se l'utente ha i permessi) ma restituiscono un errore alla chiamata; le azioni di lettura degli strumenti combinati continuano a funzionare.

## Gestione degli errori

- Gli errori delle impostazioni non devono bloccare l'avvio di Redmine.
- Gli errori di logging non influiscono sull'elaborazione delle richieste MCP.

## Scenari di test

1. MCP disabilitato — le richieste a `/mcp` restituiscono HTTP 503.
2. MCP abilitato — le richieste vengono elaborate.
3. Un plugin con integrazione MCP deselezionata — i suoi strumenti sono assenti dopo il riavvio.
4. La pagina delle impostazioni non ha un campo per il livello di logging; i messaggi MCP vengono scritti nel log Rails.
5. La pagina delle impostazioni mostra i nomi solo dei plugin installati con integrazione MCP; ognuno ha una casella di controllo.
6. Un plugin senza integrazione MCP non viene mostrato nella pagina delle impostazioni.
7. Quando MCP è disabilitato, le estensioni di altri plugin non vengono caricate all'avvio.
