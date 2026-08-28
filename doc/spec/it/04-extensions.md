# API di estensione per altri plugin

[Deutsch](../de/04-extensions.md) | [English](../en/04-extensions.md) | [Español](../es/04-extensions.md) | [Français](../fr/04-extensions.md) | [Italiano](04-extensions.md) | [日本語](../ja/04-extensions.md) | [한국어](../ko/04-extensions.md) | [Polski](../pl/04-extensions.md) | [Português (Brasil)](../pt-BR/04-extensions.md) | [Русский](../ru/04-extensions.md) | [中文](../zh/04-extensions.md)

## Panoramica

Redmine MCP fornisce un meccanismo di estensione che consente ad altri plugin Redmine installati di registrare i propri strumenti, risorse e prompt ed estendere gli strumenti esistenti.

## Obiettivo

Fornire un unico approccio all'integrazione dei plugin Redmine con l'AI senza duplicare un server MCP e senza modificare il codice di Redmine MCP.

## Aree interessate

- Plugin
- API
- Permessi

## Regole di business

### Rilevamento automatico

- All'avvio di Redmine (quando MCP è abilitato), il sistema controlla tutti i plugin installati.
- Un plugin è considerato dotato di estensione MCP se contiene un file `mcp.rb` in uno di questi percorsi:
  - `lib/<plugin.id>/mcp.rb`;
  - `lib/<nome directory del plugin>/mcp.rb`;
  - `lib/<plugin.id senza prefisso redmine_>/mcp.rb` se l'identificatore inizia con `redmine_` (schema tipico come `redmine_advanced_checklists` → `lib/advanced_checklists/mcp.rb`).
- Il plugin `redmine_mcp` non si carica come estensione.
- I plugin la cui casella di controllo dell'estensione MCP è deselezionata nelle impostazioni vengono ignorati.
- Un errore nell'estensione di un plugin non blocca il caricamento degli altri, incluso un errore di sintassi nel file di estensione.

### Registrazione degli strumenti

- Un plugin di estensione può registrare un numero qualsiasi di strumenti.
- Ogni strumento ha: nome, descrizione, schema di input, schema di output, requisito di permesso e handler.
- Nome completo dello strumento: `redmine_<plugin_id>_<name>`, ad esempio `redmine_redmine_advanced_checklists_get_issue_checklists`, `redmine_advanced_search_semantic_search_issues`.
- I nomi di strumento duplicati sono vietati.
- Uno strumento compare in MCP solo per gli utenti con i permessi corrispondenti.
- Uno strumento di estensione legato alle issue può richiedere un modulo di progetto Redmine abilitato (l'identificatore del modulo non deve necessariamente corrispondere all'id del plugin). In `tools/list`, tale strumento è visibile se l'utente ha il permesso dichiarato in almeno un progetto visibile con quel modulo. Senza requisito di modulo, è sufficiente il permesso in almeno un progetto visibile. La chiamata verifica comunque l'issue specifica: visibilità, permesso nel suo progetto e modulo abilitato; altrimenti la risposta è "not found".
- Gli strumenti di scrittura delle estensioni in modalità read-only MCP non eseguono l'handler: il rifiuto è lo stesso degli strumenti di scrittura core.

### Estensione degli strumenti esistenti

- Un plugin può estendere uno strumento già registrato.
- Un'estensione può:
  - aggiungere parametri di input extra;
  - eseguire codice prima dell'handler principale;
  - eseguire codice dopo l'handler e modificare il risultato.
- Più plugin possono estendere lo stesso strumento contemporaneamente.
- I parametri extra vengono uniti nello schema di input condiviso.
- Il nome di un parametro extra non deve corrispondere a un parametro dello strumento core né a un parametro di un'altra estensione per lo stesso strumento.
- Lo schema risultante viene normalizzato prima della pubblicazione in `tools/list`.
- L'ordine di esecuzione delle estensioni corrisponde all'ordine di caricamento dei plugin.

### Registrazione delle risorse

- Un plugin può pubblicare risorse con un URI univoco. La ri-registrazione dello stesso URI viene rifiutata.
- Una risorsa deve avere un handler di lettura.
- Schema URI consigliato: `redmine://<plugin_id>/<type>/<id>`.
- Una risorsa può richiedere controlli di permesso; senza permesso la risorsa non è disponibile.
- I controlli di permesso ricevono l'URI e gli argomenti. Il progetto viene preso da `project` / `project_id`, dall'URI (`project`/`project_id` nella query o segmento `/projects/:id`), o da un resolver di progetto esplicito definito dall'estensione. `resources/read` passa `{uri: ...}` al controllo.
- Se un progetto è specificato nella chiamata ma non trovato o non accessibile all'utente corrente, l'accesso viene negato. Il controllo "almeno un progetto" si applica solo quando nessun progetto è specificato (discovery con argomenti vuoti).
- La lettura di una risorsa restituisce il contenuto in formato testo o JSON.

### Registrazione dei prompt

- Un plugin può aggiungere prompt con nome, descrizione, argomenti e handler.
- Nome completo del prompt: `redmine_<plugin_id>_<name>`.
- I prompt sono disponibili agli utenti con i permessi corrispondenti. I controlli di permesso ricevono gli argomenti della chiamata, inclusi `project` / `project_id`. Se un progetto è specificato ma non trovato o non accessibile, l'accesso viene negato; senza un progetto specificato si applica la stessa regola di discovery delle risorse.

### Eventi (hook)

- Un plugin può sottoscriversi agli eventi del ciclo di vita MCP, ad esempio:
  - registrazione degli strumenti;
  - registrazione delle risorse;
  - registrazione dei prompt;
  - completamento del caricamento di tutte le estensioni.
- Un errore in un handler di evento viene registrato nei log e non interrompe il processo principale.

### Dipendenze

- Un plugin che estende non deve dichiarare una dipendenza rigida da Redmine MCP.
- Si raccomanda di verificare `RedmineMcp::ExtensionApi` / `mcp_extension_enabled?` prima della registrazione.
- Il plugin che estende non ha bisogno di includere la gem MCP — è sufficiente l'API di Redmine MCP.

### Capacità dell'API di estensione

Tramite l'Extension API, un plugin di estensione può:

- verificare che MCP sia abilitato e che l'estensione non sia disabilitata;
- registrare uno strumento una sola volta (senza duplicazione al reload);
- registrare uno strumento legato alle issue con controlli di permesso standard e ricerca dell'issue; se l'issue è scomparsa prima dell'esecuzione dell'handler, la risposta è "not found", non un errore interno;
- estendere uno strumento core esistente con parametri e handler before/after;
- registrare modalità di capability per `redmine_get_server_info` (ad esempio `issue_search.semantic`);
- chiamare l'API REST di Redmine o del plugin in-process per conto dell'utente corrente tramite `internal_request` (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`; l'endpoint di destinazione deve accettare l'autenticazione API); gli errori REST vengono mappati ai codici MCP canonici senza lo stato HTTP della richiesta interna;
- pubblicare `outputSchema` nel formato envelope `{ ok, data | error }`.

L'elenco dei metodi dell'API Ruby e gli esempi di codice sono nel README del plugin e in [mcp_tool_development.md](mcp_tool_development.md) (una dev guide, non SPEC comportamentale).

## Casi limite

- Un plugin senza file di estensione viene ignorato.
- Se esiste un file di estensione ma `require` fallisce — voce di log, l'estensione non è considerata caricata; la registrazione degli strumenti è un effetto collaterale di un `require` riuscito.
- Il tentativo di estendere uno strumento inesistente — errore durante la registrazione dell'estensione.
- Un plugin con la casella di controllo dell'estensione MCP deselezionata nelle impostazioni non viene caricato anche se il file di estensione esiste.
- Dopo l'installazione di una nuova estensione, è necessario un riavvio di Redmine; il client MCP potrebbe dover riconnettersi.

## Gestione degli errori

- Errore di caricamento del file di estensione — voce di log, continuare il caricamento degli altri plugin.
- Errore di registrazione dello strumento all'avvio — voce di log.
- Errore in un handler `before` dell'estensione — interrompe l'esecuzione dello strumento.
- Errore in un handler `after` — registrato nei log; il risultato dell'handler principale viene preservato a meno che l'handler non abbia modificato il flusso di controllo.

## Scenari di test

8. La discovery di risorse e prompt con argomenti vuoti resta disponibile se esiste il permesso in almeno un progetto.
9. Un plugin con `plugin.id` come `redmine_*` e file `lib/<id senza prefisso redmine_>/mcp.rb` è considerato dotato di integrazione MCP e compare nelle impostazioni delle estensioni MCP.
10. Uno strumento legato alle issue con requisito di modulo non è in `tools/list` per un utente senza alcun progetto visibile con quel modulo, anche se ha il permesso su un altro progetto.

## Esempi di estensione

| Plugin | Strumento | Scopo |
|--------|------------|------------|
| `advanced_search` | `semantic_search_issues` | Ricerca semantica delle issue |
