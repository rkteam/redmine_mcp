# Estensioni MCP per plugin Redmine

[Deutsch](../de/extension_guide.md) | [English](../en/extension_guide.md) | [Español](../es/extension_guide.md) | [Français](../fr/extension_guide.md) | [Italiano](extension_guide.md) | [日本語](../ja/extension_guide.md) | [한국어](../ko/extension_guide.md) | [Polski](../pl/extension_guide.md) | [Português (Brasil)](../pt-BR/extension_guide.md) | [Русский](../ru/extension_guide.md) | [中文](../zh/extension_guide.md)

`redmine_mcp` consente ad altri plugin Redmine di aggiungere i propri strumenti MCP e, se necessario, registrare risorse, prompt e capacità senza un server MCP separato e senza modifiche a `redmine_mcp` stesso.

## Come funziona

`redmine_mcp` fornisce un MCP Registry condiviso in cui i plugin Redmine di terze parti registrano strumenti tramite `RedmineMcp::ExtensionApi`.

Una chiamata tipica segue questo flusso:

```text
client → tools/list
client → tools/call {name, arguments}
        → Registry validates arguments against the schema
        → checks permission
        → invokes the handler
        → builds the standard MCP response
```

`redmine_mcp` non deve conoscere la logica di business di un plugin di terze parti: il plugin registra i propri strumenti tramite l'Extension API.

## Stabilità e compatibilità retroattiva

A partire da `redmine_mcp 1.0.0`, l'Extension API pubblica è considerata stabile.

Solo i metodi e i contratti di `RedmineMcp::ExtensionApi` descritti in questa guida sono API pubblica. Le classi, i moduli e i metodi interni di `redmine_mcp` non documentati come parte dell'Extension API non sono API pubblica e possono cambiare senza garanzie di compatibilità retroattiva.

Nella stessa versione major di `redmine_mcp`:

- i metodi esistenti dell'Extension API pubblica non vengono rimossi o modificati in modo incompatibile;
- possono essere aggiunti nuovi metodi e parametri opzionali;
- i metodi deprecati vengono contrassegnati per primi e rimangono disponibili almeno fino alla successiva versione major;
- le modifiche che richiedono aggiornamenti nei plugin di terze parti vengono rilasciate solo in una nuova versione major.

Tutte le modifiche all'Extension API sono elencate in `CHANGELOG.md`.

Ai plugin di terze parti è consigliato dichiarare la versione minima di `redmine_mcp` richiesta e consultare `CHANGELOG.md` durante l'aggiornamento.

## Avvio rapido

1. Creare un file `mcp.rb` in uno di questi percorsi:
   - `lib/<plugin.id>/mcp.rb`
   - `lib/<plugin_directory_basename>/mcp.rb`
   - `lib/<plugin.id senza prefisso redmine_>/mcp.rb` se `plugin.id` inizia con `redmine_`
2. Definire il modulo `<PluginName>::Mcp`.
3. Estendere `RedmineMcp::ExtensionApi`.
4. Impostare `plugin_id`.
5. Registrare il primo strumento.

Esempio minimo di estensione legata alle issue:

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

L'esempio usa `register_issue_tool`, l'helper consigliato per gli strumenti che operano sulle issue. Il contratto completo dello strumento è in [mcp_tool_development.md](mcp_tool_development.md).

### Il nome del modulo `Mcp`

Il file di estensione è `mcp.rb`. Zeitwerk deduce `Mcp` da quel nome file, quindi scrivere `module Mcp`.

Gli strumenti vengono registrati quando il file viene richiesto. Il loader non cerca il nome della costante del modulo.

## Denominazione

Per strumenti e prompt, usare un nome breve:

```ruby
name: 'search_issues'
```

Il nome MCP completo viene generato automaticamente:

```text
redmine_<plugin_id>_<name>
```

Per gli strumenti, preferire `name` nel formato `<verb>_<entity>`.

Verbi preferiti:

`get`, `list`, `search`, `create`, `update`, `set`, `delete`, `add`, `remove`, `copy`, `upload`, `download`, `send`, `summarize`.

Non usare `manage_*`, `process_*`, `handle_*` generici, né strumenti con un parametro come `action: create | update | delete` quando le operazioni possono essere suddivise in strumenti separati e chiari.

Ad esempio:

```text
plugin_id :advanced_search
name: 'semantic_search_issues'

-> redmine_advanced_search_semantic_search_issues
```

Se `plugin_id` inizia già con `redmine_` (ad esempio `redmine_advanced_checklists`), il nome completo segue comunque `redmine_<plugin_id>_<name>`: `redmine_redmine_advanced_checklists_<name>`.

Per le risorse, usare un URI univoco, ad esempio:

```text
redmine://<plugin_id>/<type>/<id>
```

I nomi di strumenti/prompt e gli URI delle risorse devono essere univoci. Il comportamento in caso di registrazione duplicata dipende dal metodo usato; `register_tool_once` non registra lo stesso strumento due volte.

## Registrazione degli strumenti

### Strumento regolare

Usare `register_tool_once` quando serve uno strumento MCP regolare non legato a una issue specifica.

Casi tipici:

- ricerca di dati del plugin;
- restituzione di un riepilogo;
- validazione o calcolo sul server.

Esempio base:

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

Il contratto completo dello strumento — `additionalProperties: false`, annotazioni di rischio e envelope tramite `SchemaNormalizer.envelope_output` — è descritto in [mcp_tool_development.md](mcp_tool_development.md).

### Strumento per issue

Usare `register_issue_tool` quando lo strumento accetta `issue_id` e opera su una issue.

È l'opzione consigliata per scenari legati alle issue perché:

- trova la issue tramite `Issue.visible(user)`;
- verifica il modulo di progetto quando necessario;
- verifica il permesso indicato nel progetto della issue;
- passa la `issue` trovata al blocco;
- restituisce un errore se la issue non è disponibile o non è trovata.

Vedere anche la sezione Permessi.

`module_name` in `register_issue_tool` è un identificatore opzionale del modulo di progetto Redmine. Non deve corrispondere a `plugin_id`. Se impostato, lo strumento compare in `tools/list` solo quando l'utente può vedere almeno un progetto con quel modulo e il permesso dichiarato.

### Cosa restituisce l'handler

L'handler restituisce un hash di dati di successo senza envelope, oppure un envelope già pronto `{ok: true, data: ...}` / `{ok: false, error: ...}`. Il Registry normalizza il risultato tramite `ToolResponse.from_handler_result`: un hash semplice viene avvolto in `{ok: true, data: ...}`; per le liste si può restituire il risultato già pronto di `paginated_list`, che contiene già `data` e `meta`.

Per gli errori, usare `RedmineMcp::Core::Helpers.error_result`, `mcp_error` o `{ok: false, error: ...}`.

## Schema di input

`SchemaNormalizer.normalize_input` normalizza lo schema dell'oggetto e aggiunge vincoli di servizio, ma il contratto pubblico dei parametri deve essere descritto esplicitamente.

Regole principali:

- ogni parametro deve avere un tipo definito;
- i campi numerici `*_id` usano `type: integer`, `minimum: 1` e una descrizione con un percorso di discovery;
- i set di valori finiti sono definiti tramite `enum` / `const`, non solo nel testo;
- gli array devono avere `items`;
- i campi interdipendenti e mutuamente esclusivi sono definiti tramite JSON Schema (`oneOf`, `if/then/else` e così via), non solo nella descrizione;
- l'ottimistic locking usa `expected_updated_at`, non `updated_at`;
- `null` è usato solo con semantica esplicitamente documentata, ad esempio per azzerare un campo;
- non usare `fields`, `payload` o `data` aperti invece di parametri di business tipizzati;
- non accettare un oggetto come stringa JSON;
- non accettare un `file_path` arbitrario in uno strumento pubblico.

I requisiti completi di `inputSchema` sono in [mcp_tool_development.md](mcp_tool_development.md).

## Schema di output

Ogni nuovo strumento deve avere un `output_schema`.

Per un risultato regolare, usare l'envelope standard:

```ruby
RedmineMcp::SchemaNormalizer.envelope_output(
  type: 'object',
  properties: {
    summary: {type: 'string'}
  },
  required: ['summary']
)
```

Per le liste, usare `SchemaNormalizer.list_envelope_output(item_schema)`.

I campi di risultato stabili noti devono essere descritti esplicitamente. Non usare `REST_OBJECT_SCHEMA` / `REST_ARRAY_SCHEMA` invece di un contratto tipizzato quando la struttura della risposta è nota. Questi schemi sono accettabili solo per strutture veramente aperte o instabili.

I requisiti completi di `outputSchema` sono in [mcp_tool_development.md](mcp_tool_development.md).

## Annotazioni

| Tipo di operazione | read_only | destructive | idempotent | open_world |
|---|---|---|---|---|
| get / list / search | `true` | `false` | `true` | `false` |
| create / add | `false` | `false` | `false` | `false` |
| update / rename / set | `false` | `false` | dipende dall'implementazione | `false` |
| delete / purge | `false` | `true` | solo se una ripetizione è effettivamente sicura | `false` |
| effetto esterno | `false` | dipende | di solito `false` | `true` |

`destructive` indica perdita irreversibile di dati, non qualsiasi scrittura.

`open_world` indica andare oltre l'installazione Redmine nota, non creare un nuovo oggetto all'interno di Redmine.

Le annotazioni non sostituiscono i controlli di permesso nell'handler.

## Permessi

`permission` è usato dal Registry per la disponibilità dello strumento e i controlli preliminari, ma non sostituisce i controlli di accesso a un oggetto specifico nell'handler.

Per gli strumenti legati alle issue, usare `register_issue_tool`, che verifica la visibilità della issue, il modulo di progetto e il permesso.

Per altre entità, l'handler deve verificare nuovamente l'accesso all'oggetto trovato.

## Errori

Usare i codici di errore MCP standard:

`VALIDATION_ERROR`, `NOT_FOUND`, `FORBIDDEN`, `CONFLICT`, `RATE_LIMITED`, `REDMINE_API_ERROR`, `TIMEOUT`, `FILE_TOO_LARGE`, `UNSUPPORTED_MEDIA_TYPE`, `INVALID_STATE`, `PARTIAL_FAILURE`, `INTERNAL_ERROR`.

Per gli errori standard, usare gli helper `error_result`.
Per un codice personalizzato, usare `mcp_error`.
Per l'ottimistic locking, usare `conflict_if_stale`.

L'handler restituisce un errore strutturato, non uno stack trace o un'eccezione non gestita.

## Helper integrati

`RedmineMcp::Core::Helpers` contiene helper condivisi che devono essere riutilizzati invece di duplicati:

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

Sono disponibili anche frammenti di schema già pronti:

- `PROJECT_SCHEMA`
- `USER_ID_SCHEMA`
- `USER_REF_SCHEMA`
- `ISSUE_ID_SCHEMA`
- `PAGINATION_INPUT`
- `EXPECTED_UPDATED_AT_SCHEMA`
- `IDEMPOTENCY_KEY_SCHEMA`

Prima di creare un helper proprio, verificare se esiste già uno adatto in `redmine_mcp`.

Consultare l'insieme attuale degli helper in `RedmineMcp::Core::Helpers` e [04-extensions.md](04-extensions.md): questa lista mostra le principali capacità disponibili e non sostituisce la documentazione API di ExtensionApi.

## Modalità read-only e idempotenza

Gli strumenti mutanti devono rispettare la modalità read-only globale:

```ruby
blocked = RedmineMcp::Core::ReadOnly.guard_write!
return blocked if blocked
```

Per operazioni in cui una chiamata ripetuta può creare un duplicato, si può usare `idempotency_key` e `RedmineMcp::IdempotencyStore`.

`idempotentHint: true` è consentito solo quando una chiamata ripetuta è effettivamente sicura considerando tutti gli effetti collaterali.

## Organizzazione del codice

`mcp.rb` dovrebbe contenere principalmente la registrazione degli strumenti: schemi, descrizioni, permessi, annotazioni e handler brevi.

Il recupero, l'aggregazione e la normalizzazione dei dati specifici MCP possono essere spostati in:

- `mcp_tools.rb`;
- quando il file cresce — `mcp_tools/*.rb`.

La logica di business regolare dovrebbe rimanere nei modelli/servizi del plugin e non deve dipendere da MCP.

Se il plugin ha già un endpoint REST adatto che implementa l'operazione necessaria e supporta chiamate per conto dell'utente corrente, DOVREBBE riutilizzarlo tramite `internal_request` (o `internal_get` per chiamate read-only `GET`).

È l'opzione preferita: MCP usa gli stessi controlli di permesso, recupero dei dati e comportamento di business dell'API del plugin esistente.

```ruby
result = internal_request(
  method: 'POST',
  path: '/my_plugin/items.json',
  user: context[:user],
  body: JSON.generate(item: {name: args[:name]})
)
return result if internal_request_error?(result)
```

Per `POST`, `PUT` e `PATCH`, passare una stringa body JSON (o `nil` quando l'endpoint non prevede un body). I parametri di query vanno in `params`.

Chiamare direttamente un modello/servizio quando:

- non esiste un endpoint REST adatto;
- l'endpoint non supporta l'operazione o i dati necessari;
- usare REST crea uno strato superfluo o errato per l'operazione;
- la logica di business condivisa è già estratta intenzionalmente in un servizio e l'endpoint REST è solo un wrapper leggero su quel servizio.

Non implementare la stessa logica di business separatamente per REST e MCP. Se entrambi i livelli necessitano logica condivisa, estrarla in un servizio comune.

## Capacità aggiuntive

`RedmineMcp::ExtensionApi` fornisce anche:

| Metodo | Quando usarlo |
|---|---|
| `register_resource` | serve una risorsa MCP |
| `register_prompt` | serve un prompt MCP |
| `register_capability` | serve aggiungere una capacità a `redmine_get_mcp_info` |
| `extend_tool` | serve estendere uno strumento esistente invece di crearne uno nuovo |
| `on` | serve un hook del ciclo di vita |
| `internal_request` | serve chiamare un endpoint REST di Redmine o del plugin in-process come utente corrente (`method`, `path`, `params` e `body` opzionali) |
| `internal_get` | scorciatoia per `internal_request(method: 'GET', ...)` |
| `internal_request_error?` | verifica se un risultato REST in-process è un envelope di errore MCP |

Impostare `plugin_id` una volta all'inizio del modulo. Prima di registrare gli strumenti, DOVREBBE verificare `mcp_extension_enabled?` quando la registrazione è eseguita dall'estensione stessa. Lo standard `ExtensionLoader` non carica `mcp.rb` anche per le estensioni disabilitate.

### Estendere uno strumento esistente

Usare `extend_tool` solo quando uno strumento separato non è adatto.

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

`before` viene eseguito prima dell'handler, `after` dopo. `extra_params` vengono aggiunti allo schema di input. I nomi dei parametri non devono entrare in conflitto con lo strumento base o con altre estensioni dello stesso strumento.

Se l'estensione viene richiesta dall'`after_initialize` di un plugin prima che `redmine_mcp` registri gli strumenti core, differire `extend_tool` per uno strumento core (ad esempio `redmine_get_issue`) fino al completamento dell'inizializzazione — usare un `Rails.application.config.after_initialize` annidato e verificare prima `Registry.instance.tool(...)`.

## Caricamento e disabilitazione di un'estensione

`redmine_mcp` cerca automaticamente il file di estensione nei percorsi supportati all'avvio di Redmine.

Verificare `redmine_mcp` solo nel punto di ingresso `mcp.rb` (di solito `lib/<plugin>.rb` o l'`after_initialize` del loader del plugin). I file caricati solo da `mcp.rb` (`mcp_tools.rb`, `mcp_tools/*.rb` e così via) non devono ripetere gli stessi controlli.

Non chiamare `ExtensionLoader.load_plugin_extension` manualmente da un plugin di terze parti: `ExtensionLoader` è un meccanismo interno di `redmine_mcp`. Un `require` condizionale del proprio `mcp.rb` è sufficiente; se l'ordine di caricamento dei plugin impedisce quel `require`, lo standard `ExtensionLoader` di `redmine_mcp` funge da fallback.

Esempio di punto di ingresso:

```ruby
# lib/my_plugin.rb

Rails.application.config.after_initialize do
  require "#{File.dirname(__FILE__)}/my_plugin/mcp" if Redmine::Plugin.installed?(:redmine_mcp) && defined?(RedmineMcp)
end
```

L'estensione viene registrata solo se:

- MCP è abilitato nelle impostazioni di `redmine_mcp`;
- il file `mcp.rb` è trovato;
- il modulo `<PluginName>::Mcp` in `mcp.rb` viene caricato correttamente;
- l'estensione non è disabilitata nell'elenco `MCP extensions`.

Dopo l'installazione di una nuova estensione o la modifica di `mcp.rb`, Redmine di solito richiede un riavvio. Il client MCP potrebbe poi dover riconnettersi. In alcune applicazioni, come Cursor, ricaricare il server MCP non basta per rilevare nuovi strumenti: se non compaiono, riavviare completamente l'applicazione.

## Verifica di un'estensione

Dopo l'implementazione, verificare lo strumento tramite una chiamata MCP reale per controllare non solo l'handler, ma anche:

- la registrazione in `tools/list`;
- lo schema di input;
- il permesso;
- l'envelope di output;
- gli errori.

Controllare i log di Redmine per errori di registrazione degli strumenti e di caricamento delle estensioni.

Per ogni nuovo strumento, almeno:

- uno scenario di schema con esito positivo;
- uno scenario di schema negativo.

I requisiti dettagliati dei test automatizzati sono in [mcp_tool_development.md](mcp_tool_development.md) (§13).

### Test automatizzati delle estensioni

I test automatizzati per un'estensione MCP di un plugin DEVONO esercitare il **percorso completo del Registry** (validazione `inputSchema` → permesso → handler → envelope `{ok, data | error}`), non solo una chiamata diretta all'handler.

Se `redmine_mcp` non è installato o non è caricato, la classe di test **salta** gli scenari (`skip` in `setup`) invece di fallire durante il caricamento del file:

```ruby
def setup
  skip('redmine_mcp is not installed') unless Redmine::Plugin.installed?(:redmine_mcp) && defined?(RedmineMcp)
  # ...
end
```

Nel `setup` dei test, chiamare `RedmineMcp::ExtensionLoader.load_plugin_extension(Redmine::Plugin.find(:your_plugin))` è accettabile per registrare gli strumenti nel `Registry`. Non chiamare `ExtensionLoader` dal codice di produzione del plugin (vedere «Caricamento e disabilitazione di un'estensione»).

Per confrontare la risposta effettiva con l'`outputSchema` pubblicato (`mcp_tool_development.md` §7.1), usare `json_schemer` — la stessa libreria che `RedmineMcp::InputValidator` applica agli schemi di input.

Il lazy loading di `json_schemer` all'interno di un helper di test è consentito. Se la libreria non è disponibile nell'ambiente, il controllo deve essere esplicitamente saltato così i test del plugin non falliscono per una dipendenza opzionale.

Test automatizzati minimi per uno strumento di estensione read-only:

- una chiamata Registry con esito positivo con validazione `outputSchema`;
- una chiamata negativa rifiutata da `inputSchema` (ad esempio violazione di `oneOf`, enum o `maxItems`);
- quando necessario — un test separato di validazione server-side a livello handler (lo schema non sostituisce i controlli sul server; vedere `mcp_tool_development.md` §3.4).

## Risoluzione dei problemi

| Problema | Cosa verificare |
|---|---|
| L'estensione non è stata caricata | percorso di `mcp.rb`, nome del modulo `Mcp`, se MCP è abilitato, log di Rails |
| Strumento/risorsa/prompt non è apparso | se `plugin_id` è impostato, se l'estensione è disabilitata, collisioni di nome o URI, se l'utente ha i permessi richiesti |
| Le modifiche non sono visibili dopo gli edit | riavviare Redmine; in Cursor e client simili, ricaricare il server MCP potrebbe non rilevare nuovi strumenti — riavviare completamente l'applicazione |
| `extend_tool` non funziona | se lo strumento base è registrato, se `extra_params` entrano in conflitto con lo schema esistente |

### Checklist pre-merge

- [ ] Lo strumento ha `title`, `description`, `input_schema`, `output_schema`, `permission` e `annotations`.
- [ ] Ogni `*_id` ha un percorso di discovery.
- [ ] Descrizione, `output_schema` e la risposta effettiva sono coerenti.
- [ ] Uno strumento mutante rispetta la modalità read-only.
- [ ] La logica specifica MCP non cresce all'interno di una lambda/handler.
- [ ] Gli helper condivisi sono riutilizzati da `redmine_mcp`, non copiati.
- [ ] È stato eseguito almeno uno scenario di schema positivo e uno negativo.
