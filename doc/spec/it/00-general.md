# Redmine MCP — specifica generale

[Deutsch](../de/00-general.md) | [English](../en/00-general.md) | [Español](../es/00-general.md) | [Français](../fr/00-general.md) | [Italiano](00-general.md) | [日本語](../ja/00-general.md) | [한국어](../ko/00-general.md) | [Polski](../pl/00-general.md) | [Português (Brasil)](../pt-BR/00-general.md) | [Русский](../ru/00-general.md) | [中文](../zh/00-general.md)

## Panoramica

Il plugin Redmine MCP fornisce un server MCP (Model Context Protocol) all'interno di un'installazione Redmine. I client AI si connettono a un unico endpoint HTTP e accedono ai dati Redmine tramite strumenti, risorse e prompt.

Il plugin include un insieme di base di strumenti per lavorare con progetti, issue e utenti. Altri plugin Redmine installati possono estendere MCP senza modificare il codice di Redmine MCP.

## Obiettivo

Fornire un unico meccanismo di integrazione tra Redmine e i sistemi AI in cui:

- l'utente opera entro i propri permessi Redmine;
- gli sviluppatori di plugin possono aggiungere le proprie capacità MCP;
- non è richiesto un server MCP separato né un fork specifico dell'installazione.

## Scenari principali

1. **Connessione di un client AI** — un amministratore abilita MCP, concede il permesso `use_mcp` ai ruoli necessari ed emette una chiave API; l'utente collega un client (Cursor, ecc.) all'endpoint `/mcp`.
2. **Lavoro con i dati Redmine** — il client chiama gli strumenti per recuperare progetti, issue e utenti.
3. **Estensione da altri plugin** — quando è installato un plugin con estensione MCP, i suoi strumenti compaiono automaticamente nell'elenco condiviso.
4. **Amministrazione** — abilitazione/disabilitazione di MCP e abilitazione dell'integrazione MCP per singoli plugin.

## Aree interessate

- API (MCP su HTTP)
- Permessi
- Impostazioni
- Issue
- Progetti
- Utenti
- Forum
- Plugin (estensioni)

## Regole di business

- MCP è disponibile solo se esplicitamente abilitato nelle impostazioni del plugin.
- Tutte le operazioni vengono eseguite per conto dell'utente Redmine autenticato.
- Le scritture tramite MCP passano attraverso i modelli Redmine: vengono eseguiti i callback dei modelli. Gli hook dei controller (`controller_issues_*_save`, `controller_journals_edit_post`, ecc.) non vengono invocati da MCP.
- La visibilità dei dati segue le regole Redmine: l'utente non riceve più di quanto possa vedere nell'interfaccia web.
- I nomi di strumenti e prompt usano il formato `<plugin_id>_<name>`, ad esempio `redmine_list_projects`.
- I campi `title` e `description` degli strumenti core sono pubblicati in inglese per la selezione da parte dell'LLM e **non sono localizzati** tramite `en.yml`/`ru.yml` (un'eccezione allo standard i18n per il catalogo degli strumenti MCP). I messaggi di errore e l'interfaccia delle impostazioni sono localizzati.
- Le estensioni di altri plugin non creano una dipendenza rigida: se Redmine MCP è assente, il plugin di terze parti continua a funzionare.

## Casi limite

- Quando MCP è disabilitato, tutte le richieste a `/mcp` vengono rifiutate.
- Quando un'estensione fallisce, le altre estensioni e gli strumenti core continuano a funzionare.
- I nuovi strumenti delle estensioni diventano disponibili dopo un riavvio di Redmine; il client MCP potrebbe dover riconnettersi per aggiornare l'elenco degli strumenti.
- In modalità stateless, ogni richiesta HTTP viene gestita in modo indipendente; non viene preservata alcuna sessione tra le richieste.

## Gestione degli errori

- Gli errori di autenticazione e autorizzazione vengono restituiti a livello HTTP.
- Gli errori di esecuzione degli strumenti vengono restituiti in formato MCP con un flag di errore.
- Gli errori di caricamento delle estensioni vengono registrati nei log e non bloccano l'avvio di Redmine.

## File della specifica

| File | Contenuto |
|------|---------|
| [console-commands.md](console-commands.md) | Comandi di installazione, verifica e manutenzione |
| [01-mcp-server.md](01-mcp-server.md) | Endpoint HTTP, protocollo MCP, trasporto |
| [02-authentication.md](02-authentication.md) | Autenticazione e controllo degli accessi |
| [03-core-tools.md](03-core-tools.md) | Strumenti Redmine integrati |
| [04-extensions.md](04-extensions.md) | API di estensione per altri plugin |
| [05-settings.md](05-settings.md) | Impostazioni del plugin e logging |
| [mcp_tool_development.md](mcp_tool_development.md) | Requisiti per lo sviluppo di strumenti MCP (dev-guide) |
| [extension_guide.md](extension_guide.md) | Guida per sviluppatori di estensioni |

## Scenari di test

1. Dopo l'installazione e l'abilitazione di MCP, il client esegue con successo `initialize` e riceve le informazioni del server.
2. Un utente con il permesso Use MCP e una chiave API valida vede l'elenco degli strumenti a lui disponibili.
3. Un utente senza il permesso Use MCP viene negato l'accesso a `/mcp`.
4. Quando è installato un plugin di estensione, i suoi strumenti sono presenti in `tools/list` per un utente con i permessi corrispondenti.
