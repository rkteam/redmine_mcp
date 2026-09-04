# Redmine MCP

[Sito](https://redmine-kanban.com/)

[Deutsch](../de/README.md) | [English](../../../README.md) | [Español](../es/README.md) | [Français](../fr/README.md) | Italiano | [日本語](../ja/README.md) | [한국어](../ko/README.md) | [Polski](../pl/README.md) | [Português (Brasil)](../pt-BR/README.md) | [Русский](../ru/README.md) | [中文](../zh/README.md)

Un server MCP (Model Context Protocol) all'interno di Redmine. Consente ai client AI di lavorare con issue, progetti e utenti tramite i permessi standard di Redmine. Altri plugin possono aggiungere i propri tools, resources, prompts e capabilities senza modificare questo plugin. Per plugin di terze parti che non possono essere modificati, `redmine_mcp` può fornire integrazioni MCP integrate in `lib/redmine_mcp/extensions/`.

## Requisiti

| Componente | Versione |
|---|---|
| Redmine | Redmine 6.0–7.0 |
| MCP protocol | 2025-11-25 |
| Ruby MCP SDK (`mcp`) | 0.23.x |

Questo plugin utilizza MCP protocol `2025-11-25` e Ruby MCP SDK `0.23.x`.
Il supporto per versioni più recenti di MCP protocol e SDK non è attualmente dichiarato.

- API REST abilitata in Redmine
- la gem `mcp` è dichiarata in `plugins/redmine_mcp/Gemfile` e installata con `bundle install`

## Installazione e configurazione

### 1. Installare il plugin

Clonare il repository git nella directory `plugins` di Redmine:

```bash
cd /path/to/redmine/plugins
git clone https://github.com/rkteam/redmine_mcp.git
```

Dalla directory radice di Redmine, installare le dipendenze e riavviare l'applicazione:

```bash
cd /path/to/redmine
bundle install
```

Riavviare Redmine.

### 2. Abilitazione in Amministrazione

**Amministrazione → Plugin → Redmine MCP → Configura**

| Impostazione | Descrizione |
|---------|-------------|
| Abilita MCP | Abilita l'endpoint `/mcp`. Quando abilitato, vengono caricate le estensioni MCP dei plugin installati |
| Modalità read-only | Blocca gli strumenti di scrittura e le azioni di scrittura (create/update/delete, ecc.) |
| Estensioni MCP | Caselle di controllo per abilitare l'integrazione MCP dei plugin installati |

### 3. REST API

**Amministrazione → Impostazioni → API** — abilitare «Abilita servizio web REST».

### 4. Permessi

**Amministrazione → Ruoli e permessi** — per i ruoli necessari, abilitare manualmente il permesso globale **Usa MCP** (`use_mcp`). Gli amministratori Redmine hanno sempre accesso a MCP.

### 5. Chiave API utente

Ogni utente che lavorerà tramite MCP deve avere una chiave API:

**Il mio account → Chiave di accesso API** (oppure tramite la REST API utente).

Passare la chiave nell'header:

```
X-Redmine-API-Key: <la_tua_chiave>
```

## Connessione di un client MCP

Il server utilizza **Streamable HTTP** (stateless). Endpoint:

```
https://<il-tuo-redmine>/mcp
```

Metodi supportati: `GET`, `POST`, `DELETE`.

### Esempio per Cursor

Nelle impostazioni MCP (`.cursor/mcp.json` o la configurazione globale), aggiungere un server con trasporto HTTP. Il formato esatto dipende dalla versione del client; un esempio tipico:

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

Dopo la connessione, il client eseguirà `initialize`, quindi potrà chiamare `tools/list`, `tools/call`, `resources/list`, `prompts/list` e così via.

### Verifica manuale

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

Una risposta riuscita contiene `serverInfo.name: "redmine_mcp"`.

### Host e reverse proxy

Il transport MCP convalida HTTP `Host` e `Origin` per proteggere da DNS rebinding.

L'host consentito è preso dall'impostazione Redmine:

**Amministrazione → Impostazioni → Generali → Nome host e percorso**

Il valore deve corrispondere all'URL pubblico di Redmine.

Ad esempio, se Redmine è disponibile su:

```
https://redmine.example.com
```

l'impostazione dovrebbe usare:

```
redmine.example.com
```

Se Redmine è dietro un reverse proxy, il proxy deve inoltrare l'header `Host` originale del client.

Se l'host non corrisponde, l'endpoint MCP può restituire HTTP `403 Forbidden`.

I client senza header `Origin` non sono interessati dal controllo Origin.

## Strumenti integrati (core tools)

I nomi completi usano il formato `redmine_<tool_name>` (ad esempio `redmine_get_issue`).

Il server fornisce strumenti per progetti, issue, utenti, registrazione del tempo, Wiki, forum e file. L'elenco seguente è una breve panoramica degli strumenti integrati. Gli schemi di input completi e le descriptions sono disponibili al client MCP tramite `tools/list`.

### Parametri comuni

- `project` — ID stringa o identifier del progetto.
- `assignee_ref` / `user_ref` con il valore `me` — l'utente corrente.
- `assigned_to_id` — utente o gruppo a cui è assegnata la segnalazione; `null` cancella i campi opzionali.
- `create_time_entry` richiede `project` o `issue_id`.
- `upload_file` richiede `filename` e `content_base64`.

### Affidabilità delle operazioni

- `expected_updated_at` — sulle operazioni sensibili di update/delete.
- `idempotency_key` — su `create_issue`, `copy_issue`, `update_issue`, `add_issue_note`, `create_time_entry`, `import_time_entries`, `upload_file`.

### Limiti

- timeout di lettura 60 s;
- 120 richieste/min per utente;
- corpo HTTP della richiesta MCP fino a 36 MiB;
- JSON args dello strumento fino a 32 MiB;
- allegati base64 fino a 20 MiB;
- download degli allegati fino a 10 MiB.

### Distribuzione in produzione

Il rate limiting e l'idempotenza usano `Rails.cache`.

Per installazioni con più worker dell'applicazione o più istanze Redmine, dovrebbe essere usato un cache store condiviso.

Con una cache locale al processo, le garanzie di rate limiting e idempotenza si applicano solo all'interno di un singolo processo dell'applicazione.

### Gestione progetti

| Strumento | Descrizione |
|------|-------------|
| `list_projects` | Elenco progetti |
| `get_project` | Dettagli progetto |
| `list_project_issue_custom_fields` | Campi personalizzati issue del progetto |
| `summarize_project_status` | Riepilogo metriche del progetto generato dal server per N giorni |
| `list_project_activities` | Feed attività del progetto (eventi, non tipi di attività di registrazione tempo) |
| `list_versions` | Versioni della roadmap (milestone) |
| `get_version` | Dettagli versione roadmap con aggregati |
| `create_version` | Creare una versione |
| `update_version` | Aggiornare una versione |
| `delete_version` | Eliminare una versione |
| `list_project_members` | Membri del progetto e i loro ruoli |
| `list_project_member_candidates` | Utenti e gruppi che possono essere aggiunti al progetto |
| `list_roles` | Ruoli gestibili nel progetto |
| `get_project_modules` | Moduli del progetto abilitati |
| `add_project_member` | Aggiungere un membro |
| `update_project_member` | Modificare i ruoli di un membro |
| `remove_project_member` | Rimuovere un membro |

### Issue

| Strumento | Descrizione |
|------|-------------|
| `get_issue` | Dettagli issue (journal, allegati, campi personalizzati, ecc.) |
| `list_issues` | Elenco issue con filtri e paginazione |
| `search_issues` | Ricerca testuale sulle issue |
| `run_issue_query` | Eseguire una query issue salvata |
| `get_issue_form_options` | Valori consentiti dei campi del form issue (una sola chiamata) |
| `validate_issue_create` | Validare i parametri di creazione issue senza scrivere |
| `validate_issue_update` | Validare i parametri di aggiornamento issue senza scrivere |
| `create_issue` | Creare un'issue |
| `update_issue` | Aggiornare attributi e allegati dell'issue |
| `add_issue_note` | Aggiungere un commento a un'issue (opzionalmente con allegati) |
| `delete_issue` | Eliminare un'issue con conferma |
| `copy_issue` | Copiare un'issue |
| `list_issue_relations` | Elenco relazioni dell'issue |
| `create_issue_relation` | Creare una relazione tra issue |
| `delete_issue_relation` | Eliminare una relazione tra issue |
| `list_subtasks` | Sottoattività |
| `add_issue_watcher` | Aggiungere un osservatore |
| `remove_issue_watcher` | Rimuovere un osservatore |
| `update_issue_note` | Modificare una voce del journal |
| `set_issue_note_private` | Modificare la privacy di una voce del journal |
| `get_private_notes` | Solo commenti privati |
| `list_issue_categories` | Categorie issue del progetto |
| `create_issue_category` | Creare una categoria |
| `update_issue_category` | Aggiornare una categoria |
| `delete_issue_category` | Eliminare una categoria |

### Utenti

| Strumento | Descrizione |
|------|-------------|
| `list_users` | Membri del progetto; filtri `query` (nome/login) e `login`; la ricerca globale è solo per amministratori |
| `list_groups` | Gruppi givable per `group_id` in `add_project_member` |

### Registrazione del tempo

| Strumento | Descrizione |
|------|-------------|
| `list_time_entries` | Elenco voci di tempo |
| `create_time_entry` | Creare una voce di tempo |
| `update_time_entry` | Aggiornare una voce di tempo |
| `list_time_entry_activities` | Tipi di attività per la registrazione del tempo (non il feed eventi del progetto) |
| `import_time_entries` | Importazione massiva di voci di tempo |

### Dati di riferimento

| Strumento | Descrizione |
|------|-------------|
| `list_trackers` | Tutti i tracker |
| `list_project_trackers` | Tracker del progetto |
| `list_issue_statuses` | Stati delle issue |
| `list_issue_priorities` | Priorità delle issue |
| `admin_list_users` | Utenti con filtri (solo amministratore) |
| `get_current_user` | Utente corrente |
| `list_queries` | Query salvate (metadati; l'esecuzione è `run_issue_query`) |

### Ricerca e Wiki

| Strumento | Descrizione |
|------|-------------|
| `search_all` | Ricerca issue e pagine Wiki |
| `list_wiki_pages` | Pagine Wiki del progetto |
| `get_wiki_page` | Ottenere una pagina Wiki |
| `create_wiki_page` | Creare una pagina Wiki |
| `update_wiki_page` | Aggiornare una pagina Wiki |
| `delete_wiki_page` | Eliminare una pagina Wiki |
| `rename_wiki_page` | Rinominare una pagina Wiki |

### Forum

| Strumento | Descrizione |
|------|-------------|
| `list_boards` | Board del forum del progetto |
| `list_board_topics` | Argomenti della board selezionata |
| `get_board_message` | Messaggio del forum con risposte brevi |

### File

| Strumento | Descrizione |
|------|-------------|
| `list_project_files` | File del progetto |
| `upload_file` | Caricare un file |
| `delete_attachment` | Eliminare un allegato |
| `get_attachment` | Metadati dell'allegato e `content_url` |
| `download_attachment` | Contenuto dell'allegato (`content_base64`, fino a 10 MiB) |

### Utilità

| Strumento | Descrizione |
|------|-------------|
| `get_mcp_info` | Versione del plugin MCP, modalità read-only, utente corrente e capabilities disponibili |

### Accesso e risposte

Gli strumenti restituiscono un envelope JSON in `structuredContent` e una rappresentazione testuale in `content`.

Le operazioni di scrittura sono bloccate dall'impostazione **Modalità read-only**.

Oltre ai permessi specifici dello strumento, viene sempre verificato il permesso globale **Usa MCP**.

L'accesso ai dati è applicato tramite i permessi standard e le regole di visibilità di Redmine. Per i dati di progetti e issue vengono usati `Project.visible` e `Issue.visible`.

## Estensioni da altri plugin

Qualsiasi plugin Redmine installato può aggiungere i propri MCP tools e, se necessario, registrare resources, prompts e capabilities.

Per i plugin che non possono essere modificati, le integrazioni integrate si trovano in `redmine_mcp/lib/redmine_mcp/extensions/` e si registrano tramite la stessa Extension API.

Guida dettagliata: [extension_guide.md](extension_guide.md).

Per lo sviluppo assistito da AI in Cursor o agenti simili, copiare la directory skill [`redmine-mcp-plugin-integration`](../../skills/redmine-mcp-plugin-integration/) nella cartella skills del proprio agente, oppure usarla come base per uno skill personalizzato.

Quando invocate lo skill, indicate nel prompt se integrare tramite il plugin di destinazione (`mcp.rb`) o come integrazione integrata in `redmine_mcp` (`lib/redmine_mcp/extensions/`). Se non specificate, l'agente sceglierà il percorso.

## Logging

I messaggi vengono scritti nel log Rails standard con il prefisso `[redmine_mcp]`:

- caricamento delle estensioni
- registrazione di tools/resources/prompts
- errori di registrazione ed esecuzione
- negazioni di accesso

## Risoluzione dei problemi

| Sintomo | Possibile causa |
|---------|----------------|
| HTTP 503 «MCP is disabled» | MCP non è abilitato nelle impostazioni del plugin |
| HTTP 401 | Chiave API mancante o non valida; REST API disabilitata |
| HTTP 403 (permesso) | L'utente non ha il permesso **Usa MCP** |
| HTTP 403 (`Host`/`Origin`) | **Nome host e percorso** non corrisponde all'URL pubblico di Redmine; il reverse proxy non inoltra l'`Host` originale; l'URL MCP nel client non corrisponde — il transport rifiuta host sconosciuti (protezione DNS rebinding) |
| Lo strumento non è visibile in `tools/list` | Permessi mancanti; l'estensione che fornisce lo strumento è disabilitata |
| I nuovi tools non sono comparsi dopo il reload MCP | In Cursor e client simili, il reload del server potrebbe non aggiornare l'elenco degli strumenti — riavviare completamente l'applicazione |
| L'estensione non si carica | Manca `lib/.../mcp.rb` o `lib/redmine_mcp/extensions/<plugin.id>.rb`; il modulo non fa `extend RedmineMcp::ExtensionApi`; assicurarsi che la casella dell'estensione sia abilitata in **Estensioni MCP**; se il file ha un errore, controllare il log |
| `Issue not found` / `Project not found` | L'issue o il progetto non è visibile all'utente corrente secondo le regole di visibilità di Redmine |

## Licenza

Questo plugin è distribuito sotto GNU General Public License,
versione 2 o qualsiasi versione successiva.

Per i dettagli, vedere [LICENSE](../../../LICENSE).
