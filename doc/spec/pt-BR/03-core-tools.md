# Ferramentas integradas (core tools)

[Deutsch](../de/03-core-tools.md) | [English](../en/03-core-tools.md) | [Español](../es/03-core-tools.md) | [Français](../fr/03-core-tools.md) | [Italiano](../it/03-core-tools.md) | [日本語](../ja/03-core-tools.md) | [한국어](../ko/03-core-tools.md) | [Polski](../pl/03-core-tools.md) | [Português (Brasil)](03-core-tools.md) | [Русский](../ru/03-core-tools.md) | [中文](../zh/03-core-tools.md)

## Visão geral

O plugin Redmine MCP fornece um conjunto de ferramentas para trabalhar com projetos Redmine, problemas, controle de tempo, wiki, fóruns, arquivos e dados de referência (leitura e gravação).

## Objetivo

Ofereça aos clientes de IA gerenciamento de projetos, operações de problemas, controle de tempo, descoberta, pesquisa e wiki, quadros, operações de arquivos e operações Meta sem instalar plug-ins adicionais.

## Áreas afetadas

- Projetos
- Versões
- Membros / Funções
- Issues (CRUD, relações, observadores, notas, categorias, opções de formulário, validação de simulação, consultas salvas)
- Entradas de tempo
- Rastreadores, status, prioridades, consultas
- Atividade de projeto
- Páginas Wiki
- Quadros / mensagens
- Arquivos/anexos do projeto
- Usuários
- Permissões
- Configurações (modo somente leitura)

## Regras de negócios

### Regras gerais

- Nome completo da ferramenta: `redmine_<name>` (por exemplo `redmine_get_issue`).
- O resultado é retornado como um envelope JSON em `structuredContent` e duplicado como texto em `content`.
- Os dados são filtrados através da visibilidade e permissões do projeto/problema Redmine.
- O parâmetro `project` é uma string: id numérico como string (por exemplo `"1"`) ou identificador de projeto (por exemplo `"ecookbook"`).
- Quando o **modo somente leitura** está ativado, as ferramentas de gravação retornam um erro. Ferramentas somente leitura, incluindo `list_issue_relations`, `get_issue_form_options`, `validate_issue_create` e `validate_issue_update`, permanecem disponíveis.

### Gerenciamento de projetos

| Ferramenta | R/W | Permissão |
|------|-----|------------|
| `list_projects` | R | `view_project` |
| `get_project` | R | `view_project` |
| `list_project_issue_custom_fields` | R | `view_issues` |
| `summarize_project_status` | R | `view_issues` |
| `list_project_activities` | R | `view_project` |
| `list_versions` | R | `view_issues` |
| `get_version` | R | `view_issues` |
| `create_version` | W | `manage_versions` |
| `update_version` | W | `manage_versions` |
| `delete_version` | W | `manage_versions` |
| `list_project_members` | R | `view_members` |
| `list_project_member_candidates` | R | `manage_members` |
| `list_roles` | R | `manage_members` + `project` |
| `get_project_modules` | R | `view_project` |
| `add_project_member` | W | `manage_members` |
| `update_project_member` | W | `manage_members` |
| `remove_project_member` | W | `manage_members` |

### Operações de emissão

| Ferramenta | R/W | Permissão |
|------|-----|------------|
| `get_issue` | R | `view_issues` |
| `list_issues` | R | `view_issues` |
| `search_issues` | R | `view_issues` |
| `run_issue_query` | R | `view_issues` |
| `get_issue_form_options` | R | `view_issues` |
| `validate_issue_create` | R | `add_issues` |
| `validate_issue_update` | R | `edit_issues` |
| `create_issue` | W | `add_issues` |
| `update_issue` | W | atributos — se forem editáveis; `uploads` apenas — se anexos puderem ser adicionados |
| `add_issue_note` | W | `add_issue_notes`; `private_notes=true` requer adicionalmente `set_notes_private` |
| `delete_issue` | W | `delete_issues` |
| `copy_issue` | W | `copy_issues` no projeto de origem e `add_issues` no destino |
| `list_issue_relations` | R | `view_issues` |
| `create_issue_relation` | W | `manage_issue_relations` |
| `delete_issue_relation` | W | `manage_issue_relations` |
| `list_subtasks` | R | `view_issues` |
| `add_issue_watcher` | W | `add_issue_watchers` |
| `remove_issue_watcher` | W | `delete_issue_watchers` |
| `update_issue_note` | W | registro do diário visível e editável (`edit_issue_notes` / `edit_own_issue_notes`); `private_notes` exige adicionalmente `set_notes_private` |
| `set_issue_note_private` | W | o lançamento contábil manual é visível e editável, além de `set_notes_private` |
| `get_private_notes` | R | `view_private_notes` |
| `list_issue_categories` | R | `view_issues` |
| `create_issue_category` | W | `manage_categories` |
| `update_issue_category` | W | `manage_categories` |
| `delete_issue_category` | W | `manage_categories` |

### Usuários

| Ferramenta | R/W | Permissão |
|------|-----|------------|
| `list_users` | R | `view_members` + `project`; sem `project` — somente administrador |
| `list_groups` | R | `manage_members` (em qualquer projeto) ou admin |

### Controle de tempo

| Ferramenta | R/W | Permissão |
|------|-----|------------|
| `list_time_entries` | R | `view_time_entries` |
| `create_time_entry` | W | `log_time` |
| `update_time_entry` | W | a entrada é editável pelo usuário atual (`edit_time_entries` / `edit_own_time_entries`) |
| `list_time_entry_activities` | R | `log_time` |
| `import_time_entries` | W | `log_time` |

### Descoberta/Enumeração

| Ferramenta | R/W | Permissão |
|------|-----|------------|
| `list_trackers` | R | `view_issues` |
| `list_project_trackers` | R | `view_issues` |
| `list_issue_statuses` | R | `view_issues` |
| `list_issue_priorities` | R | `view_issues` |
| `list_all_users` | R | administrador |
| `get_current_user` | R | `use_mcp` |
| `list_queries` | R | `view_issues` |

### Pesquisa e Wiki

| Tool | R/W | Permissão |
|------|-----|------------|
| `search_all` | R | acesso a pelo menos um dos tipos pesquisados (`view_issues` e/ou `view_wiki_pages`) |
| `list_wiki_pages` | R | `view_wiki_pages` |
| `get_wiki_page` | R | `view_wiki_pages`; `version` histórica exige adicionalmente `view_wiki_edits` |
| `create_wiki_page` | W | `edit_wiki_pages` e a página deve ser editável |
| `update_wiki_page` | W | `edit_wiki_pages` e a página deve ser editável |
| `delete_wiki_page` | W | `delete_wiki_pages` e a página deve ser editável |
| `rename_wiki_page` | W | `rename_wiki_pages` e a página deve ser editável |

### Quadros

| Ferramenta | R/W | Permissão |
|------|-----|------------|
| `list_boards` | R | `view_messages` |
| `list_board_topics` | R | `view_messages` |
| `get_board_message` | R | `view_messages` |

### Operações de arquivo

| Ferramenta | R/W | Permissão |
|------|-----|------------|
| `list_files` | R | `view_files` |
| `upload_file` | W | `manage_files` |
| `delete_file` | W | `manage_files` (ou permissões do contêiner) |
| `get_attachment` | R | permissões no contêiner de anexos |
| `download_attachment` | R | permissões no contêiner de anexos |

### Meta

| Ferramenta | R/W | Permission |
|------|-----|------------|
| `get_server_info` | R | `use_mcp` |

`get_server_info` retorna `server_version`, `read_only_mode`, `auth_mode`, dados resumidos do usuário atual e `capabilities.issue_search`. A instalação de plug-ins de terceiros não está listada na resposta: suas ferramentas MCP são visíveis por meio de `tools/list` e por meio de `capabilities` essas extensões são registradas.

`capabilities.issue_search` contém modos de pesquisa:

| Modo | Padrão | Note |
|------|---------|------|
| `keyword` | `available: true`, tool `redmine_search_issues` | Sempre |
| `cross_resource` | `available: true`, ferramenta `redmine_search_all` | Sempre |
| `semantic` | `available: false` | Plugins podem ser substituídos via `register_capability(:issue_search, :semantic)` |

Quando `semantic.available: true`, o recurso DEVE incluir `tool`, `provider` e `use_when` / `avoid_when` – breves dicas sobre quando escolher a pesquisa semântica. `Registry#apply_capabilities` normaliza a resposta do provedor: se o contrato for violado, `{ available: false }` é publicado.

### Esclarecimentos

- `delete_issue` sem `confirm_delete` retorna uma prévia do impacto; se houver **qualquer** subtarefa (incluindo aquelas invisíveis para o usuário), `confirm_delete_with_children` será necessário. Os contadores em `impact` cobrem apenas diários, relações, entradas de tempo, filhos e anexos visíveis para o usuário atual.
- `search_issues` com `scope=subprojects` requer `project` e pesquisa nesse projeto e seus descendentes. Sem `project`, esse escopo é um erro de parâmetro. `scope=my_project` limita a busca a projetos dos quais o usuário é membro.
- `get_issue`: diários, anexos, observadores, relações, filhos e campos personalizados são incluídos apenas com `include_*` explícito. Listas aninhadas possuem campos `limit`/`offset` separados e um campo `*_pagination` (diários: limite padrão 25, máximo 100; outras listas aninhadas: padrão e máximo 100). Sem o `include_*` correspondente, a lista fica vazia e a paginação é `null`. Campos opcionais (`custom_fields`, `journals`, `attachments`, `watchers`, `relations`, `children`) estão sempre presentes na resposta. Campos personalizados — apenas aqueles visíveis para o usuário atual. Diários — mesma visibilidade do histórico de problemas no Redmine: uma entrada aparece em `journals` e `journal_pagination` somente se tiver texto ou pelo menos uma alteração de detalhe visível para o usuário. Texto que consiste apenas em espaços, tabulações ou quebras de linha é tratado como vazio. Entradas vazias e entradas apenas com detalhes ocultos (incluindo campos personalizados ocultos) são excluídas da lista e de `total_count` / `offset` / `has_more`. Comentários privados – comentários próprios ou com permissão de `view_private_notes`. Os elementos do diário contêm apenas alterações de detalhes visíveis. Relações — apenas links onde ambos os lados são visíveis para o usuário. A mesma regra de visibilidade de relação se aplica a `list_issue_relations`.
- `get_private_notes` retorna apenas comentários privados com texto não vazio (espaços, tabulações e quebras de linha sem outro conteúdo contam como texto vazio). A página é limitada por `limit`/`offset` sem carregar o histórico completo de problemas.
- `list_project_issue_custom_fields` retorna campos visíveis ao usuário no projeto. Se `tracker_id` estiver definido, o rastreador deverá pertencer ao projeto.
- `copy_issue` requer permissão para copiar problemas no projeto de **origem** e permissão para criar problemas no projeto de **destino**. Os inspetores serão copiados somente se o usuário tiver permissão para adicionar inspetores no projeto de destino. O link para a cópia do original e do anexo segue as configurações do Redmine `link_copied_issue` e `copy_attachments_on_issue_copy` (`yes` / `no` / `ask`). Sem substituições de campo, a cópia ainda passa pelas regras de gravação do formulário. O pai do problema de origem é preservado quando permitido (inclusive ao copiar dentro do mesmo projeto).
- `create_issue_relation` aplica apenas atributos de relação permitidos e grava a alteração no diário de problemas. `delete_issue_relation` é permitido somente se a relação puder ser excluída pelo usuário atual (ambos os problemas são visíveis e o usuário tem permissão para gerenciar relações em pelo menos um lado); a exclusão também é gravada no diário.
- `add_project_member` / `update_project_member` aceitam apenas funções que o usuário atual pode gerenciar no projeto. Uma função fora desse conjunto é rejeitada; as funções não são atribuídas parcialmente.
- `create_issue_category` / `update_issue_category`: `assigned_to_id` é um ID principal (usuário ou grupo), não apenas um usuário.
- `delete_file` para um anexo de problema segue a regra "os anexos sobre este problema podem ser excluídos" (incluindo problemas próprios e permissões de rastreador), não apenas `edit_issues` global. Em `tools/list`, a ferramenta fica visível se o usuário puder excluir pelo menos um anexo (arquivos de projeto, problemas ou wiki), não apenas com `manage_files` global.
- `get_wiki_page`: `attachments` está sempre na resposta; por padrão `[]` e `attachments_pagination: null`; com `include_attachments=true` — uma lista de anexos paginada com `attachment_limit`/`attachment_offset` (padrão e máximo 100). O histórico `version` requer permissão para visualizar as edições do wiki. Alterar, renomear ou excluir uma página protegida requer permissão para proteger páginas wiki.
- `list_issues`, `search_issues`, `list_subtasks`, `run_issue_query`: campos de resumo por padrão; descrição completa via `fields` ou `get_issue`.
- `create_issue` e `update_issue` aceitam **atributos** de problema explícito (`subject`, `description`, `tracker_id`, `status_id`, `custom_fields`, etc.). Todos os atributos passados explicitamente, incluindo `subject` e `description` na criação, passam pelas mesmas regras de gravação do formulário web Redmine. Antes de criar/atualizar, o agente DEVERIA chamar `get_issue_form_options` quando os valores dos campos permitidos são desconhecidos. Um valor passado explicitamente que o Redmine não aplicou resulta em um erro, não em sucesso parcial.
- Se o cliente **não passou** `start_date` em `create_issue` / `validate_issue_create`, e o Redmine tem "data de início = data de criação" habilitada (`default_issue_start_date_to_creation_date`), o MCP define `start_date` para o dia de hoje do usuário - como o novo formulário de emissão. Um `start_date` explícito (incluindo `null`) desativa esta substituição. `copy_issue` e `update_issue` não substituem a data.
- `update_issue` não aceita `notes`, `private_notes` ou `watcher_user_ids`. Comentários — `add_issue_note`; observadores — `add_issue_watcher` / `remove_issue_watcher`.
- `update_issue` também suporta `uploads` para anexar arquivos a um problema. Os anexos são processados somente após a validação bem-sucedida do atributo (incluindo `rejected_fields`). Uma chamada com apenas `uploads` (sem atributos) é permitida se o usuário puder adicionar anexos ao problema — inclusive quando comentários são permitidos, mas os atributos não podem ser editados. O `idempotency_key` opcional protege contra novas tentativas após uma resposta perdida (incluindo o reenvio dos mesmos arquivos). `journal_id` na resposta é o lançamento no diário para **esta** chamada, não o lançamento do último problema.
- Para limpar um campo opcional, passe `null` para `assigned_to_id`, `category_id`, `fixed_version_id`, `parent_issue_id`, `start_date`, `due_date` ou `estimated_hours`. O mesmo para `update_version.due_date` / `wiki_page_title` e `update_issue_category.assigned_to_id`.
- `create_issue` não suporta `uploads`.
- `update_issue` aceita `uploads[*].content_base64` e `uploads[*].filename`. Após um upload bem-sucedido, a resposta contém `added_attachments` — apenas os arquivos desta chamada, não a lista completa de anexos do problema. Base64 corrompido é um erro de parâmetro.
- `update_issue` aceita `status_name` e resolve para `status_id`.
- `upload_file` aceita `content_base64` (até 20 MiB); `project`, `filename` e `content_base64` são obrigatórios.
- `get_attachment` retorna `attachment_id`, `filename`, `content_type`, `size` (tamanho do arquivo do anexo) e `content_url` (sem bytes de arquivo).
- `download_attachment` retorna `attachment_id`, `filename`, `content_type`, `size` (tamanho real do conteúdo em bytes) e `content_base64` para um único anexo visível para o usuário atual. Se MIME for desconhecido — `application/octet-stream`. Não incrementa o contador `downloads`. O limite de tamanho é 10 MiB (verifica `File.size` no disco antes da leitura e `bytesize` após a leitura); se excedido — `FILE_TOO_LARGE`. Os caminhos do sistema de arquivos do servidor não são retornados na resposta. `attachment_id` vem de `redmine_get_issue` / `redmine_get_wiki_page` com `include_attachments=true`, `redmine_list_files` ou `redmine_get_attachment`. Para ler, analisar ou processar um anexo como um arquivo, decodifique `content_base64` localmente. Anexos inexistentes e inacessíveis retornam a mesma resposta “não encontrado”.
- `create_time_entry` e os itens de `import_time_entries.entries` exigem `hours` e `project` ou `issue_id`. `hours` pode ser 0; a validade zero e o máximo diário são verificados pelo Redmine (`timelog_accept_0_hours`, `timelog_max_hours_per_day`).
- `assigned_to_id` em caso de criação/atualização é um ID principal (usuário ou grupo de `get_issue_form_options.assignees`); `null` limpa o destinatário. `user_id` em `add_issue_watcher` / `remove_issue_watcher` é um ID principal (usuário ou grupo). Em outras ferramentas, `user_id` é um ID de usuário. Para o usuário atual, use `assignee_ref` ou `user_ref` com valor `me`.
- `expected_updated_at` (opcional) em atualização/exclusão sensível: se não corresponder a `updated_on`, retorna `CONFLICT`.
- `idempotency_key` (opcional) em `create_issue`, `copy_issue`, `update_issue`, `add_issue_note`, `create_time_entry`, `import_time_entries`, `upload_file`: uma nova tentativa com a mesma chave e **o mesmo conjunto de argumentos** (exceto a própria chave) retorna o resultado bem-sucedido armazenado em cache (TTL 24 h). A mesma chave com uma carga diferente — `CONFLICT`, sem gravação duplicada. Enquanto a primeira solicitação ainda está em execução, uma nova tentativa com a mesma chave não executa outra gravação (o marcador "em andamento" dura as mesmas 24 horas que um resultado bem-sucedido). Uma entrada em cache sem impressão digital (cache anterior a esta versão) com a mesma chave é retornada como antes até que o TTL expire. O tempo limite do servidor de 60 s aplica-se a **leituras**. As operações de gravação não são interrompidas pelo tempo limite do servidor para que, após um salvamento bem-sucedido, o resultado da idempotência possa ser registrado; o cliente poderá tentar novamente com a mesma chave se perder a conexão. Uma exceção inesperada em `import_time_entries` reverte entradas já inseridas naquela chamada; erros normais de validação para linhas individuais ainda são coletados sem reverter os erros bem-sucedidos.
- `delete_file` por padrão exclui apenas arquivos de projeto/versão; para anexos de issue/wiki, `confirm_delete_any_attachment=true` é necessário.
- Lista/pesquisa usa `limit`/`offset`. Para consultas de banco de dados, a página é limitada no nível da consulta, não cortando uma lista completa já carregada. Qualquer coleção MCP paginada possui uma ordem estável explícita; o último critério é sempre `id` para que as páginas não pulem ou dupliquem itens.
- A pesquisa de substring (`query`, `login`, `name` e texto `search_issues`) corresponde literalmente aos caracteres: `%` e `_` não são curingas SQL.
- Limites de MCP: tempo limite de 60 s em ferramentas de leitura, limite de taxa de 120 solicitações/min por usuário, corpo HTTP de solicitação de MCP de 36 MiB, tamanho máximo de argumentos da ferramenta JSON de 32 MiB, upload de base64 até 20 MiB, download de base64 de até 10 MiB. Base64 corrompido em qualquer `content_base64` é um erro de parâmetro antes da execução da ferramenta.
- Cada chamada de ferramenta, incluindo negação de acesso, é gravada em um log de auditoria estruturado (ferramenta, usuário, IDs de destino, resultado, duração, correlação_id) e contada para o limite de taxa; conteúdo base64 e notas privadas não são registrados. Os IDs de destino incluem `board_id`, `message_id`, `query_id`, `user_id`, `group_id`, entre outros.
- `outputSchema` de cada ferramenta principal descreve o nível superior de `data` (para listas - campos de elemento `items`), não um objeto arbitrário aberto. O conjunto de campos do esquema corresponde à resposta real: `list_users` sem `created_on`, `list_all_users` com `created_on`; `get_attachment` inclui `size` e `content_url`. Os campos que podem estar vazios na resposta real permitem `null` (incluindo `time_entry.issue`, `*_pagination` sem inclusão, `estimation_accuracy`, anexo `content_type`). Os valores dos campos personalizados e `possible_values` não estão limitados a objetos. `attachments_not_saved` é uma matriz de nomes de arquivos.
- `summarize_project_status.days` no esquema: padrão 30, mínimo 1, máximo 365.
- `search_all.resources`: no máximo dois valores únicos.
- `version_id`, `file_id`, `tracker_id` são inteiros não inferiores a 1.

### `get_project`

- Entrada: `project` (obrigatório).
- Saída: `id`, `name`, `identifier`, `description`, `homepage`, `status`, `is_public`, `inherit_members`, `created_on`, `updated_on`, `parent` (objeto `id`/`name`/`identifier` ou `null`), `subprojects` (breve lista de projetos filhos visíveis: `id`/`name`/`identifier`), `custom_fields`, `last_activity_date`.
- `parent` é preenchido somente se o projeto pai estiver visível para o usuário atual; caso contrário, `null`.
- Não retorna membros, módulos habilitados ou estatísticas de issues. Para módulos — `get_project_modules`; para membros — `list_project_members`; para agregados de issues — `summarize_project_status`.

### `get_issue_form_options`

- Uma chamada em vez de várias pesquisas de referência antes da criação/atualização. `list_project_trackers`, `list_issue_statuses`, `list_issue_priorities`, `list_issue_categories`, `list_versions`, `list_users`, `list_project_issue_custom_fields` separados permanecem disponíveis.
- Entrada: `project` (obrigatório); opcionalmente `tracker_id`, `issue_id`.
- O instantâneo reflete o **formulário de problema para o usuário atual**, não a configuração completa do projeto: os mesmos valores permitidos que a UI do Redmine oferece.
- `tracker_id` sem `issue_id` define o contexto de criação do formulário. O rastreador deve estar disponível para o usuário atual selecionar no formulário; caso contrário — erro de parâmetro.
- `issue_id` define o formulário para um problema visível existente neste projeto. Com `issue_id`, `tracker_id` é permitido somente se corresponder ao rastreador atual do problema; caso contrário — erro de parâmetro (a alteração do rastreador não é modelada por meio desta ferramenta).
- Saída — instantâneo do formulário sem paginação:
- `project`: `id`, `name`, `identifier`;
- `trackers`: trackers que o usuário atual pode selecionar neste formulário (`id`, `name`), nem todos os trackers habilitados para o projeto;
- `priorities`: prioridades ativas (`id`, `name`, `is_default`);
- `categories`: categorias de projetos (`id`, `name`);
- `versions`: versões disponíveis para seleção neste formulário (`id`, `name`, `status`, `due_date`);
- `assignees`: principais que podem ser atribuídos neste contexto de formulário. Elemento: `id`, `name`, `type` (`user` ou `group`); para `user`, adicionalmente `login`. Os grupos serão incluídos se o Redmine tiver a atribuição de problemas a grupos habilitada;
- `custom_fields`: somente campos que o usuário atual pode editar no formulário, considerando projeto/rastreador, visibilidade, fluxo de trabalho somente leitura. Elemento: `id`, `name`, `field_format`, `required` (campo obrigatório ou exigido pelo fluxo de trabalho), `readonly` (sempre `false` nesta lista), `multiple`, `default_value`, `possible_values`, `trackers`. Contexto do formulário — emitir a partir de `issue_id` ou criar rascunho considerando `tracker_id`;
- `possible_values` — matriz de objetos `{ "label": "...", "value": "..." }`. Para listas sem rótulos separados, `label` corresponde a `value`. Para usuário/versão/enumeração, `label` é o nome de exibição, `value` é o identificador;
- `statuses`: status permitidos pelo workflow para o usuário atual. Com `issue_id` — transições para este problema visível. Sem `issue_id` — status iniciais para criação (considerando `tracker_id` se definido);
- `editable_fields`: nomes de atributos que este contrato MCP aceita na criação/atualização que o usuário atual pode definir no formulário, além de ids de campos personalizados editáveis como strings. Não inclui `notes`, `private_notes`, `watcher_user_ids` e outros campos de formulário da web ausentes nas ferramentas de gravação do MCP;
- `required_fields`: nomes dos campos obrigatórios neste formulário para o usuário atual, no mesmo formato de nome de `editable_fields`.
- `tracker_id` inexistente, rastreador não permitido para o usuário, ou `issue_id` fora do projeto/não visível — erro de parâmetro.

### `add_issue_note`

- Adiciona um comentário a um problema visível existente sem alterar os atributos do problema.
- Entrada: `issue_id` (obrigatório), `notes` (obrigatório), opcionalmente `private_notes`, `uploads` e `idempotency_key`.
- Permissão: o usuário pode adicionar comentários a esta questão. `private_notes=true` requer permissão para fazer comentários privados; caso contrário — negado, nenhum comentário será criado. Anexos na mesma chamada serão permitidos se o usuário puder adicionar anexos ao problema.
- Não aceita campos de problemas ou listas de observadores.
- Saída: `issue_id`, `journal_id`, `notes`, `private_notes`; com `uploads` — `added_attachments` (somente arquivos desta chamada).
- Não disponível no modo somente leitura.

### `update_issue_note` / `set_issue_note_private`

- Trabalhe apenas com uma entrada de diário que o usuário atual **vê** (os comentários privados de outro usuário sem permissão para visualizar notas privadas são inacessíveis).
- A entrada deve ser editável pelo usuário atual (permissão para editar comentários ou comentários próprios).
- `update_issue_note.notes` pode ser uma string vazia (limpando o texto de uma entrada existente). Um novo comentário via `add_issue_note` não pode ficar vazio.
- Alterar a privacidade (`private_notes` / `is_private`) requer permissão separada para tornar os comentários privados; caso contrário, negado, o texto não será parcialmente alterado.
- Registra quem editou o lançamento contábil manual.
- Não disponível no modo somente leitura.

### `validate_issue_create` / `validate_issue_update`

- Ferramentas somente leitura separadas, não um parâmetro `validate_only` nas ferramentas de gravação. Disponível no modo somente leitura.
- `validate_issue_create`: mesmos campos de `create_issue`, sem `idempotency_key`. `project` e `subject` são obrigatórios. Permissão `add_issues`.
- `validate_issue_update`: simulação apenas para **atributos de problema** (como `update_issue`, sem `uploads`). `issue_id` é obrigatório. O problema deve ser editável pelo usuário atual. Antes da validação, um contexto de diário do usuário é criado sem gravação no banco de dados (como em uma atualização real).
- Comportamento: aplique atributos ao problema sem salvar. Os dados do Redmine não são alterados.
- Os atributos ainda seguem as mesmas regras de gravação do formulário web Redmine. Se o cliente **passou explicitamente** um valor e o Redmine não o aplicou, isso é um erro de MCP, sem sucesso.
- Um campo explícito que não esteja entre aqueles graváveis no problema (desabilitado/fluxo de trabalho somente leitura/datas derivadas, etc.) entra em `rejected_fields`. Para `tracker_id`, `status_id`, `assigned_to_id`, `is_private`, `parent_issue_id` e `custom_fields`, é verificado adicionalmente se o valor solicitado foi realmente aplicado.
- A mesma regra se aplica a `create_issue`, `update_issue` e `copy_issue`: nenhuma gravação se um valor solicitado explicitamente não foi aplicado.
- Sucesso: `{ "valid": true, "errors": [] }`.
- Falha: `{ "valid": false, "errors": ["..."] }`. Se alguns campos explícitos não foram aplicados — também `rejected_fields` (nomes de campos, por exemplo `["tracker_id"]`) e, para erros típicos — `missing_required_fields` / `hint` no mesmo formato de criação/atualização.
- Captura também: rastreador não disponível para o usuário atual; valor de campo personalizado inválido ou indisponível; transição de status proibida pelo fluxo de trabalho; cessionário não disponível para atribuição.

### `list_issues` — filtros estendidos

- Os filtros planos existentes (`project`, `status_id`, `tracker_id`, `assigned_to_id` / `assignee_ref`, `priority_id`, `fixed_version_id`, `sort`, `fields`) são preservados.
- Opcional `filters`: array de objetos `{ "field": "...", "operator": "...", "values": ["..."] }`. `values` é um array de strings; uma matriz vazia é permitida para operadores sem valores.
- Permitido `field`: `status_id`, `tracker_id`, `assigned_to_id`, `priority_id`, `fixed_version_id`, `category_id`, `subject`, `due_date`, `start_date`, `created_on`, `updated_on`, `estimated_hours`, `done_ratio`, `author_id`, `watcher_id` e `cf_<id>` para campos personalizados de emissão.
- Os operadores são operadores de consulta Redmine padrão, incluindo `=`, `!`, `>=`, `<=`, `><`, `~`, `!~`, `o`, `c`, `*`, `!*`. O operador deve ser válido para o tipo de campo; caso contrário — erro de parâmetro.
- `field` desconhecido ou `operator` inválido — erro de parâmetro, a consulta não é executada.
- Filtros planos e `filters` são combinados com AND.
- Os filtros aplicam-se apenas a problemas visíveis para o usuário atual.

### `run_issue_query`

- Entrada: `query_id` (obrigatório, de `list_queries`); opcionalmente `project`, `fields`, `limit`/`offset`.
- Executa uma consulta de problema salva e visível para o usuário atual. O formato de resposta é o mesmo envelope de lista de `list_issues`.
- Se a consulta estiver no escopo do projeto, os resultados serão limitados a esse projeto (e às regras de visibilidade da consulta). O `project` opcional para uma consulta de projeto deve corresponder ao projeto da consulta; caso contrário — erro de parâmetro.
- Se a consulta for global, o opcional `project` restringe a seleção a esse projeto visível.
- Invisível ou inexistente `query_id` — erro.
- `list_queries` não executa a consulta; use `run_issue_query` para execução.

### `list_project_activities`

- Entrada: `project` (obrigatório); opcionalmente `from`, `to` (datas `YYYY-MM-DD`), `author_id`, `event_types` (matriz de strings), `limit`/`offset`.
- Janela padrão — últimos 7 dias (`to` = hoje, `from` = hoje menos 6 dias). Duração máxima da janela — 90 dias; se excedido — erro de parâmetro.
- Eventos do feed de atividades do projeto: tipo, horário, autor (`id`/`name`), `title`, `description`, `url`. Ordem – eventos mais recentes primeiro; por tempo igual - maior `id` primeiro.
- Envelope como outro `list_*`.
- `event_types` limita os tipos de eventos. Um tipo indisponível ao usuário ou desabilitado no projeto é excluído da seleção (sem erro).
- `author_id` inexistente — lista vazia, não é um erro.

### `summarize_project_status`

Os campos existentes são preservados: `project_id`, `project_name`, `analysis_period_days`, `recent_activity` (`created_count`, `updated_count`), `totals` (`issues_count`, `open_count`, `closed_count`), `status_breakdown`, `priority_breakdown`, `assignee_breakdown`.

A janela `days` (padrão 30, intervalo de 1 a 365) ainda afeta `recent_activity` e as métricas do período listadas abaixo. Um valor fora do intervalo é rejeitado pelo esquema. `totals` e detalhamentos são calculados sobre todos os problemas visíveis do projeto sem filtro de data, por meio de agregação de banco de dados, sem carregar todos os problemas na memória. Os subprojetos não estão incluídos.

Campos adicionais:

- `overdue_count` — número de problemas visíveis abertos com `due_date` estritamente antes do usuário hoje.
- `unassigned_count` — número de problemas visíveis abertos sem responsável.
- `stale_issues_count` — número de problemas visíveis abertos com `updated_on` anteriores ao início da janela `days`.
- `issues_closed_during_period` — número de problemas visíveis com `closed_on` na janela `days`.
- `estimated_hours` — soma das estimativas de problemas visíveis do projeto (`null` se nenhum tiver uma estimativa, caso contrário, um número incluindo 0).
- `spent_hours` — soma do tempo gasto em questões visíveis do projeto (0 se não houver entradas). Requer `view_time_entries` no projeto; sem permissão o campo é `null`.
- `average_resolution_hours` — média de `(closed_on - created_on)` em horas para problemas fechados na janela `days`; `null` se não houver tais problemas.
- `estimation_accuracy` — para problemas fechados na janela que possuem estimativa e tempo diferente de zero/registrado: `{ "issues_count", "total_estimated", "total_spent" }`. Se não houver problemas de correspondência — `{ "issues_count": 0, "total_estimated": 0, "total_spent": 0 }`. Requer `view_time_entries` no projeto; sem permissão o campo é `null`.
- `reopened_count` — número de fascículos visíveis cujo status do diário mudou de fechado para aberto na janela `days`. Cada edição é contada no máximo uma vez.

A ferramenta retorna fatos, não uma "análise de saúde do projeto" textual.

### `get_version`

- Entrada: `version_id` (obrigatório); opcionalmente `project`. Se `project` estiver definido, a versão estará acessível quando estiver nas versões compartilhadas deste projeto visível (mesmo que o projeto de origem da versão não esteja visível para o usuário). Sem `project`, a versão deve estar visível em seu projeto de origem.
- Saída: campos como um elemento `list_versions` (`id`, `name`, `description`, `status`, `due_date`, `sharing`, `wiki_page_title`, `project`, `created_on`, `updated_on`) mais agregados: `issues_count`, `open_issues_count`, `closed_issues_count`, `estimated_hours`, `spent_hours`, `completed_percent`.
- As agregações são calculadas apenas sobre problemas de versão visíveis para o usuário atual.
- A lista de problemas não é retornada.
- `spent_hours` requer `view_time_entries` no projeto da versão; sem permissão - `null`. Soma apenas os problemas de versão visíveis e apenas as entradas de tempo que o usuário atual pode ver (incluindo `time_entries_visibility=own`).

### Quadros

- O módulo de fóruns do projeto deve estar habilitado; caso contrário, erro "O módulo Boards não está habilitado para este projeto" (wiki análogo).
- Permissão `view_messages`. Nenhuma operação de gravação no fórum.
- `list_boards`: `project` obrigatório; paginação. Elemento: `id`, `name`, `description`, `parent_id` (`null` para placa raiz), `topics_count`, `messages_count`.
- `list_board_topics`: `board_id` obrigatório; paginação. Apenas mensagens raiz (sem pai). Elemento: `id`, `subject`, `author`, `created_on`, `updated_on`, `replies_count`, `board_id`.
- `get_board_message`: `message_id` obrigatório. Saída: `id`, `subject`, `content`, `author`, `created_on`, `updated_on`, `board` (`id`/`name`), `project` (`id`/`name`/`identifier`), `parent_id`, `replies` — breve lista de respostas (`id`, `subject`, `author`, `created_on`) sem texto completo de cada resposta, com `replies_limit`/`replies_offset` (padrão e máximo 100) e `replies_pagination`.
- Quadro/mensagem invisível ou quadro de outro projeto — erro "não encontrado".

### `list_users`

- Com `project`: **usuários** membros ativos do projeto (permissão `view_members`). A associação ao grupo no projeto não aparece como um grupo; usuários de um grupo somente se eles próprios forem membros. Sem `project` — apenas administrador.
- Elemento: `id`, `login`, `firstname`, `lastname`, `mail`. Não inclui `created_on` (esse campo está em `list_all_users`).
- `query` opcional: substring que não diferencia maiúsculas de minúsculas em `login`, `firstname` e `lastname`.
- Opcional `login` é preservado (somente substring de login) para compatibilidade. Se `query` e `login` estiverem definidos, ambas as condições se aplicam (AND).

### `list_groups`

- Lista paginada de grupos disponíveis (`id`, `name`), **visíveis** para o usuário atual, para selecionar `group_id` em `add_project_member`.
- Opcional `query`: substring que não diferencia maiúsculas de minúsculas no nome do grupo; `%` e `_` são correspondidos literalmente.
- Permissão: administrador ou `manage_members` em pelo menos um projeto visível.
- Não retorna associação ou associação a grupos.

### `list_project_member_candidates`

- Candidatos para adição ao projeto: usuários visíveis ativos e grupos que ainda não estão no projeto.
- Entrada: `project` (obrigatório); opcionalmente `query` (substring, como no seletor de membro Redmine).
- Envelope da lista de saída: `id`, `name`, `type` (`user` ou `group`); para usuário, adicionalmente `login`.
- Permissão `manage_members` no projeto.
- `add_project_member`: `user_id` apenas para usuário, `group_id` apenas para grupo. ID do tipo errado — erro de parâmetro. Antes de adicionar, pegue os IDs desta ferramenta (ou de `list_users` / `list_groups` se o candidato já for conhecido).

### `list_roles`

- Somente funções que o usuário atual pode gerenciar no projeto especificado.
- Entrada: `project` (obrigatório).
- Permissão `manage_members` no projeto.
- Para administrador, o conjunto corresponde às funções atribuíveis do projeto (sem Não membro/Anônimo).

## Casos extremos

- Projeto ou problema inexistente/inacessível — `{ "error": "..." }`.
- Modo somente leitura — `{ "error": "MCP is in read-only mode..." }` para ferramentas de gravação **antes** de chamar o manipulador, incluindo ferramentas de API de extensão; validar/formulário opções/listar/obter permanecem disponíveis.
- Lista vazia/resultado da pesquisa — `{ "ok": true, "data": { "items": [] }, "meta": { ... } }`.
- Lista/busca com paginação sempre retorna `data.items` e `meta` (`total_count`, `limit`, `offset`, `has_more`, `next_offset`). Limite padrão 25, máximo 100.
- Todas as ferramentas `list_*` (incluindo referências: rastreadores, status, funções, consultas, quadros, tópicos de quadro, etc.) usam o mesmo envelope. `get_issue_form_options`, `get_project`, `get_version`, `get_board_message`, `summarize_project_status` e ferramentas de validação – objetos únicos, não envelope de lista.
- `download_attachment`: anexo inexistente e inacessível — mesmo erro “não encontrado”; arquivo ilegível no disco — erro; tamanho no disco ou após leitura acima de 10 MiB — `FILE_TOO_LARGE` (o limite não é ignorado por um banco de dados inferior `filesize`). A mesma regra indistinguível de "ausente/sem acesso" - para `get_attachment`.
- `list_project_activities`: janela superior a 90 dias — erro de parâmetro; `from` após `to` — erro de parâmetro.
- `run_issue_query`: consulta invisível — tratada como inexistente.
- `get_issue_form_options` com `issue_id` para um problema de outro projeto — erro de parâmetro.
- `get_issue_form_options` com `issue_id` e `tracker_id` diferentes do rastreador desse problema — erro de parâmetro.
- As ferramentas de validação não criam um problema, não atualizam um problema, não criam lançamentos contábeis manuais e não consomem `idempotency_key`.
- As gravações através do MCP passam pelos modelos Redmine. Os retornos de chamada do modelo são executados; os ganchos do controlador de interface da web não são chamados.

## Tratamento de erros

- Permissão ausente — ferramenta não visível em `tools/list` ou "Permissão negada".
- Erros de validação de modelo — `{ "error": "<messages>" }` (para ferramentas de criação/atualização e validação de problemas, adicionalmente `missing_required_fields` como nomes de campo de símbolos de erro de modelo, sem análise de texto de tradução, e `hint`).
- Módulo wiki/boards desativado — mensagem de erro separada, não "não encontrada".
- O código de erro canônico no envelope é definido explicitamente pelo manipulador; o código não é derivado do texto da mensagem e não depende do idioma do usuário.

## Cenários de teste

1. Envelope de devolução `list_projects` / `list_issues` `data.items` + `meta` com paginação.
2. `get_issue` sem `include_*` não retorna diários/anexos; com `include_journals` — periódicos com paginação.
3. `search_issues` por texto encontra problemas; `search_all` inclui wiki ao pesquisar vários tipos.
4. `create_issue` / `update_issue` com campos válidos são bem-sucedidos; sem permissão ou somente leitura - erro.
4a. `create_issue` sem `start_date` com configuração de data de início habilitada define a data de hoje; explícito `start_date` ou `null` não é substituído por essa configuração.
5. `delete_issue` sem `confirm_delete` retorna `INVALID_STATE` e impacto; com exclusões de confirmação.
6. `create_time_entry` requer `hours` e `project` ou `issue_id`; `import_time_entries` aceita um lote.
7. `list_wiki_pages` / `get_wiki_page` / `create_wiki_page` funcionam com o módulo Wiki ativado.
8. `upload_file` requer `filename` e `content_base64`; `delete_file` para anexo de problema requer confirmação.
9. Usuário sem `use_mcp` não passa na autenticação MCP; sem permissão da ferramenta não o vê em `tools/list`.
10. Tentar novamente `create_issue` com o mesmo `idempotency_key` e os mesmos argumentos não cria uma duplicata; mesma chave com assunto diferente - `CONFLICT`.
11. `download_attachment` para retornos de anexos de problemas visíveis `content_base64` com conteúdo real `size`; para arquivo > 10 MiB em disco (mesmo com metadados pequenos) — `FILE_TOO_LARGE`; apegos inexistentes e inacessíveis são indistinguíveis.
12. `get_project` por identificador retorna descrição, subprojetos e `last_activity_date`; projeto inacessível - erro.
13. `get_issue_form_options` para rastreadores/status/prioridades/categorias/versões/designados/campos_personalizados de retornos de projeto e listas `editable_fields` / `required_fields`; `trackers` — apenas aqueles disponíveis para o usuário atual; com status `issue_id` refletem as transições permitidas para esse problema; `issue_id` + `tracker_id` diferente — erro; `possible_values` — objetos `label`/`value`.
14. `validate_issue_create` com rastreador ou status inválido retorna `valid: false` e `rejected_fields`, não cria problema; no modo somente leitura, a chamada é bem-sucedida.
15. `list_issues` com `filters` (data `due_date` `<=`, `priority_id` `!`) retorna apenas problemas visíveis correspondentes; desconhecido `field` — erro.
16. `run_issue_query` com `query_id` visível retorna os mesmos problemas da consulta salva na UI; consulta invisível - erro.
17. `list_project_activities` por 3 dias retorna eventos do projeto com paginação; Janela de 91 dias – erro.
18. `summarize_project_status` inclui `overdue_count`, `unassigned_count`, `stale_issues_count`, `issues_closed_during_period` e `reopened_count`.
19. `get_version` retorna agregados `open_issues_count` / `completed_percent` sem lista de problemas.
20. `list_boards` / `list_board_topics` / `get_board_message` funcionam com o módulo Boards habilitado; quando desabilitado — erro do módulo.
21. `list_users` com `project` e `query` por nome encontra membro sem saber o login.
22. `get_issue_form_options` retorna destinatários com usuário/grupo `type` e apenas campos personalizados editáveis com `required`/`readonly`.
23. `create_issue` / `update_issue` / `copy_issue` / `validate_issue_create` com valor passado explicitamente que Redmine não se aplica (incluindo campos principais desabilitados/somente leitura, incluindo `description` na criação) retornam erro e não salvam alterações parciais.
24. `validate_issue_update` não aceita notas; o comentário é criado por `add_issue_note`. `add_issue_note` com `add_issue_notes` é bem-sucedido sem `edit_issues`; `private_notes` sem `set_notes_private` — negado. `update_issue` com apenas `uploads` consegue permissão para adicionar anexos sem `edit_issues`.
25. `list_groups` retorna grupos que podem ser fornecidos para usuários com `manage_members`.
26. `update_issue` com `assigned_to_id`/`category_id`/`fixed_version_id`/`parent_issue_id`/`start_date`/`due_date`/`estimated_hours` = `null` limpa o campo se for gravável.
27. `update_issue_note` / `set_issue_note_private` não altere o comentário privado de outro usuário se o usuário não tiver permissão para visualizar comentários privados.
28. O usuário com permissão para editar comentários, mas não para torná-los privados, pode alterar o texto do comentário público e não pode alterar o sinalizador de privacidade.
29. `add_issue_note` com `uploads` cria comentário e anexo em uma chamada; tente novamente com o mesmo `idempotency_key` não os duplica.
30. `update_issue` com `uploads` e `idempotency_key`: tentar novamente com a mesma carga não duplica o anexo; arquivo diferente com a mesma chave — `CONFLICT`. Base64 corrompido – erro de parâmetro.
31. `get_issue` não retorna campos personalizados ocultos, detalhes de diários invisíveis ou relações com problemas invisíveis. `get_version` agrega apenas problemas visíveis.
32. `copy_issue` sem permissão para copiar no projeto de origem — negado, mesmo com `add_issues` no destino.
33. `add_project_member` / `update_project_member` com função que o usuário não pode gerenciar — negado sem atribuição parcial.
34. `create_version` / `update_version` com `sharing` não permitido para usuário – negado. `delete_version` para versão ocupada — negado sem exclusão.
35. O autor da entrada de tempo com `edit_own_time_entries` pode atualizar a própria entrada via `update_time_entry`.
36. `search_all` disponível para usuário com permissão de wiki sem `view_issues`, se a pesquisa incluir wiki.
37. `list_project_member_candidates` retorna usuários e grupos que ainda não estão no projeto; `add_project_member` com grupo `user_id` — erro.
38. `list_roles` para projeto retorna apenas funções que o usuário pode gerenciar; sem `project` — erro de esquema. Não inclui não membros e anônimos integrados.
39. Tentar novamente `copy_issue` / `create_time_entry` com o mesmo `idempotency_key` não cria duplicata; carga útil diferente com a mesma chave - `CONFLICT`.
40. `search_issues` e a pesquisa de usuário/grupo por `%` ou `_` correspondem a esses caracteres literalmente, não como curingas.
41. `get_version.spent_hours` com `time_entries_visibility=own` conta apenas entradas de tempo próprias.
42. `search_issues` com `scope=subprojects` sem `project` — erro; com `project` encontra problemas em descendentes.
43. `list_project_activities` retorna eventos mais recentes antes dos mais antigos.
44. O impacto de `delete_issue` não inclui diários ocultos, relações e registros de horas de outros; subtarefas ocultas ainda exigem `confirm_delete_with_children`.
45. `get_project` não retorna pai invisível para o usuário atual.
46. `update_version` com `due_date`/`wiki_page_title` = `null` limpa o campo.
47. `update_issue_category` com `assigned_to_id` = `null` limpa o destinatário padrão.
48. O esquema aceita `hours` de 0 e valores acima de 24; apenas a validação do Redmine é rejeitada.
49. `update_issue_note` com `notes` vazio limpa o texto do comentário existente.
50. `list_users` com `project` retorna apenas usuários, mesmo que o projeto tenha participação em grupo.
51. A versão histórica da página wiki sem `view_wiki_edits` está inacessível; a página protegida não pode ser alterada sem permissão para proteger o wiki.
52. `copy_issue` sem permissão para adicionar observadores não copia observadores; `link_copied_issue` / `copy_attachments_on_issue_copy` = `no` proíbe link e anexos; pai no mesmo projeto é preservado.
53. A ferramenta de gravação de extensão no modo somente leitura não invoca o manipulador.
54. `delete_file` visível em `tools/list` para usuário que pode excluir anexos de problemas, sem `manage_files`.
55. `add_issue_watcher` / `remove_issue_watcher` aceita o principal do grupo.
56. `get_version` com `project` retorna a versão compartilhada que `list_versions` para aquele projeto retornou.
57. `get_issue` / `get_wiki_page` / `get_board_message` limitam listas aninhadas com `limit`/`offset` e retornam `*_pagination`; sem inclusão de paginação é `null`.
58. As respostas reais da ferramenta, incluindo campos anuláveis, correspondem às publicadas `outputSchema`.
59. `get_issue` com `include_journals`: diário com apenas detalhes de campo personalizado ocultos não está na lista e não é contado em `journal_pagination.total_count`.
60. O diário oculto entre dois visíveis não cria um intervalo de página: com `journal_limit=2` duas entradas visíveis são retornadas, `total_count` é igual à contagem visível.
61. O comentário privado de outro usuário não é retornado em `get_issue` sem a permissão de `view_private_notes`.
62. `get_private_notes` retorna uma página de `limit`/`offset` sem carregar o histórico completo de problemas.
63. `get_issue` com diários `attr`, `cf` e `relation` simultaneamente não falha e retorna apenas entradas visíveis.
64. Diário com detalhes de campos personalizados ocultos e notas de espaços, tabulações ou quebras de linha não está incluído em `get_issue`.
65. `get_private_notes` não retorna um comentário apenas de espaços, tabulações ou quebras de linha.
