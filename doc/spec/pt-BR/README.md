# Redmine MCP

[Site](https://redmine-kanban.com/)

[Deutsch](../de/README.md) | [English](../en/README.md) | [Español](../es/README.md) | [Français](../fr/README.md) | [Italiano](../it/README.md) | [日本語](../ja/README.md) | [한국어](../ko/README.md) | [Polski](../pl/README.md) | Português (Brasil) | [Русский](../ru/README.md) | [中文](../zh/README.md)

Um servidor MCP (Model Context Protocol) dentro do Redmine. Permite que clientes de IA trabalhem com tarefas, projetos e usuários pelas permissões padrão do Redmine. Outros plugins podem adicionar suas próprias tools, resources, prompts e capabilities sem alterar este plugin.

## Requisitos

| Componente | Versão |
|---|---|
| Redmine | Redmine 6.0+ (testado: 6.0–6.1) |
| MCP protocol | 2025-11-25 |
| Ruby MCP SDK (`mcp`) | 0.23.x |

Este plugin usa MCP protocol `2025-11-25` e Ruby MCP SDK `0.23.x`.
O suporte a versões mais recentes de MCP protocol e SDK não está declarado atualmente.

- REST API habilitada no Redmine
- a gem `mcp` é declarada em `plugins/redmine_mcp/Gemfile` e instalada com `bundle install`

## Instalação e configuração

### 1. Instalar o plugin

Clone o repositório git no diretório `plugins` do Redmine:

```bash
cd /path/to/redmine/plugins
git clone https://github.com/rkteam/redmine_mcp.git
```

A partir do diretório raiz do Redmine, instale as dependências e reinicie a aplicação:

```bash
cd /path/to/redmine
bundle install
```

Reinicie o Redmine.

### 2. Habilitar na Administração

**Administração → Plugins → Redmine MCP → Configurar**

| Configuração | Descrição |
|---------|-------------|
| Habilitar MCP | Habilita o endpoint `/mcp`. Quando habilitado, extensões MCP de plugins instalados são carregadas |
| Modo somente leitura | Bloqueia ferramentas de escrita e ações de escrita (create/update/delete, etc.) |
| Extensões MCP | Checkboxes para habilitar a integração MCP de plugins instalados |

### 3. REST API

**Administração → Configurações → API** — habilite «Habilitar serviço web REST».

### 4. Permissões

**Administração → Funções e permissões** — para as funções necessárias, habilite manualmente a permissão global **Usar MCP** (`use_mcp`). Administradores do Redmine sempre têm acesso ao MCP.

### 5. Chave de API do usuário

Cada usuário que trabalhará via MCP deve ter uma chave de API:

**Minha conta → Chave de acesso à API** (ou via REST API do usuário).

Passe a chave no header:

```
X-Redmine-API-Key: <sua_chave>
```

## Conectando um cliente MCP

O servidor usa **Streamable HTTP** (stateless). Endpoint:

```
https://<seu-redmine>/mcp
```

Métodos suportados: `GET`, `POST`, `DELETE`.

### Exemplo para Cursor

Nas configurações MCP (`.cursor/mcp.json` ou a configuração global), adicione um servidor com transporte HTTP. O formato exato depende da versão do cliente; um exemplo típico:

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

Após conectar, o cliente executará `initialize`, depois poderá chamar `tools/list`, `tools/call`, `resources/list`, `prompts/list` e assim por diante.

### Verificação manual

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

Uma resposta bem-sucedida contém `serverInfo.name: "redmine_mcp"`.

### Host e reverse proxy

O transport MCP valida HTTP `Host` e `Origin` para proteger contra DNS rebinding.

O host permitido é obtido da configuração do Redmine:

**Administração → Configurações → Geral → Nome do host e caminho**

O valor deve corresponder à URL pública do Redmine.

Por exemplo, se o Redmine está disponível em:

```
https://redmine.example.com
```

a configuração deveria usar:

```
redmine.example.com
```

Se o Redmine roda atrás de um reverse proxy, o proxy deve encaminhar o header `Host` original do cliente.

Se o host não corresponder, o endpoint MCP pode retornar HTTP `403 Forbidden`.

Clientes sem header `Origin` não são afetados pela verificação Origin.

## Ferramentas integradas (core tools)

Nomes completos usam o formato `redmine_<tool_name>` (por exemplo `redmine_get_issue`).

O servidor fornece ferramentas para projetos, tarefas, usuários, registro de tempo, Wiki, fóruns e arquivos. A lista abaixo é uma visão geral breve das ferramentas integradas. Schemas de entrada completos e descriptions estão disponíveis ao cliente MCP via `tools/list`.

### Parâmetros comuns

- `project` — ID string ou identifier do projeto.
- `assignee_ref` / `user_ref` com o valor `me` — o usuário atual.
- `assigned_to_id` — usuário ou grupo atribuído à tarefa; `null` limpa campos opcionais.
- `create_time_entry` requer `project` ou `issue_id`.
- `upload_file` requer `filename` e `content_base64`.

### Confiabilidade das operações

- `expected_updated_at` — em operações sensíveis de update/delete.
- `idempotency_key` — em `create_issue`, `copy_issue`, `update_issue`, `add_issue_note`, `create_time_entry`, `import_time_entries`, `upload_file`.

### Limites

- timeout de leitura 60 s;
- 120 requisições/min por usuário;
- corpo HTTP da requisição MCP até 36 MiB;
- JSON args da ferramenta até 32 MiB;
- anexos base64 até 20 MiB;
- download de anexos até 10 MiB.

### Implantação em produção

Rate limiting e idempotência usam `Rails.cache`.

Para instalações com múltiplos workers da aplicação ou múltiplas instâncias do Redmine, deveria ser usado um cache store compartilhado.

Com cache local ao processo, as garantias de rate limiting e idempotência se aplicam apenas dentro de um processo individual da aplicação.

### Gerenciamento de projetos

| Ferramenta | Descrição |
|------|-------------|
| `list_projects` | Listar projetos |
| `get_project` | Detalhes do projeto |
| `list_project_issue_custom_fields` | Campos customizados de tarefas do projeto |
| `summarize_project_status` | Resumo de métricas do projeto gerado pelo servidor por N dias |
| `list_project_activities` | Feed de atividade do projeto (eventos, não tipos de atividade de registro de tempo) |
| `list_versions` | Versões do roadmap (marcos) |
| `get_version` | Detalhes da versão do roadmap com agregados |
| `create_version` | Criar uma versão |
| `update_version` | Atualizar uma versão |
| `delete_version` | Excluir uma versão |
| `list_project_members` | Membros do projeto e suas roles |
| `list_project_member_candidates` | Usuários e grupos que podem ser adicionados ao projeto |
| `list_roles` | Roles que podem ser gerenciadas no projeto |
| `get_project_modules` | Módulos do projeto habilitados |
| `add_project_member` | Adicionar um membro |
| `update_project_member` | Alterar roles do membro |
| `remove_project_member` | Remover um membro |

### Tarefas

| Ferramenta | Descrição |
|------|-------------|
| `get_issue` | Detalhes da tarefa (journal, anexos, campos customizados, etc.) |
| `list_issues` | Listar tarefas com filtros e paginação |
| `search_issues` | Busca textual em tarefas |
| `run_issue_query` | Executar uma query de tarefas salva |
| `get_issue_form_options` | Valores permitidos dos campos do formulário de tarefa (uma chamada) |
| `validate_issue_create` | Validar parâmetros de criação de tarefa sem gravar |
| `validate_issue_update` | Validar parâmetros de atualização de tarefa sem gravar |
| `create_issue` | Criar uma tarefa |
| `update_issue` | Atualizar atributos e anexos da tarefa |
| `add_issue_note` | Adicionar um comentário a uma tarefa (opcionalmente com anexos) |
| `delete_issue` | Excluir uma tarefa com confirmação |
| `copy_issue` | Copiar uma tarefa |
| `list_issue_relations` | Listar relações da tarefa |
| `create_issue_relation` | Criar uma relação entre tarefas |
| `delete_issue_relation` | Excluir uma relação entre tarefas |
| `list_subtasks` | Subtarefas |
| `add_issue_watcher` | Adicionar um observador |
| `remove_issue_watcher` | Remover um observador |
| `update_issue_note` | Editar uma entrada do journal |
| `set_issue_note_private` | Alterar privacidade da entrada do journal |
| `get_private_notes` | Apenas comentários privados |
| `list_issue_categories` | Categorias de tarefas do projeto |
| `create_issue_category` | Criar uma categoria |
| `update_issue_category` | Atualizar uma categoria |
| `delete_issue_category` | Excluir uma categoria |

### Usuários

| Ferramenta | Descrição |
|------|-------------|
| `list_users` | Membros do projeto; filtros `query` (nome/login) e `login`; busca global é apenas para administrador |
| `list_groups` | Grupos givable para `group_id` em `add_project_member` |

### Registro de tempo

| Ferramenta | Descrição |
|------|-------------|
| `list_time_entries` | Listar registros de tempo |
| `create_time_entry` | Criar um registro de tempo |
| `update_time_entry` | Atualizar um registro de tempo |
| `list_time_entry_activities` | Tipos de atividade de registro de tempo (não o feed de eventos do projeto) |
| `import_time_entries` | Importação em massa de registros de tempo |

### Dados de referência

| Ferramenta | Descrição |
|------|-------------|
| `list_trackers` | Todos os trackers |
| `list_project_trackers` | Trackers do projeto |
| `list_issue_statuses` | Status das tarefas |
| `list_issue_priorities` | Prioridades das tarefas |
| `admin_list_users` | Usuários com filtros (apenas administrador) |
| `get_current_user` | Usuário atual |
| `list_queries` | Queries salvas (metadados; execução é `run_issue_query`) |

### Busca e Wiki

| Ferramenta | Descrição |
|------|-------------|
| `search_all` | Buscar tarefas e páginas Wiki |
| `list_wiki_pages` | Páginas Wiki do projeto |
| `get_wiki_page` | Obter uma página Wiki |
| `create_wiki_page` | Criar uma página Wiki |
| `update_wiki_page` | Atualizar uma página Wiki |
| `delete_wiki_page` | Excluir uma página Wiki |
| `rename_wiki_page` | Renomear uma página Wiki |

### Fóruns

| Ferramenta | Descrição |
|------|-------------|
| `list_boards` | Boards do fórum do projeto |
| `list_board_topics` | Tópicos do board selecionado |
| `get_board_message` | Mensagem do fórum com respostas breves |

### Arquivos

| Ferramenta | Descrição |
|------|-------------|
| `list_project_files` | Arquivos do projeto |
| `upload_file` | Enviar um arquivo |
| `delete_attachment` | Excluir um anexo |
| `get_attachment` | Metadados do anexo e `content_url` |
| `download_attachment` | Conteúdo do anexo (`content_base64`, até 10 MiB) |

### Utilitários

| Ferramenta | Descrição |
|------|-------------|
| `get_mcp_info` | Versão do plugin MCP, modo somente leitura, usuário atual e capabilities disponíveis |

### Acesso e respostas

Ferramentas retornam um envelope JSON em `structuredContent` e uma representação textual em `content`.

Operações de escrita são bloqueadas pela configuração **Modo somente leitura**.

Além das permissões específicas da ferramenta, a permissão global **Usar MCP** é sempre verificada.

O acesso a dados é aplicado pelas permissões padrão e regras de visibilidade do Redmine. Para dados de projetos e tarefas, `Project.visible` e `Issue.visible` são usados.

## Extensões de outros plugins

Qualquer plugin Redmine instalado pode adicionar suas próprias MCP tools e, se necessário, registrar resources, prompts e capabilities.

Guia detalhado: [extension_guide.md](extension_guide.md).

Para desenvolvimento assistido por IA no Cursor ou agentes similares, copie o diretório skill [`redmine-mcp-plugin-integration`](../../skills/redmine-mcp-plugin-integration/) para a pasta skills do seu agente, ou use-o como base para seu próprio skill.

## Logging

Mensagens são escritas no log Rails padrão com o prefixo `[redmine_mcp]`:

- carga de extensões
- registro de tools/resources/prompts
- erros de registro e execução
- negações de acesso

## Solução de problemas

| Sintoma | Possível causa |
|---------|----------------|
| HTTP 503 «MCP is disabled» | MCP não está habilitado nas configurações do plugin |
| HTTP 401 | Chave de API ausente ou inválida; REST API desabilitada |
| HTTP 403 (permissão) | O usuário não tem a permissão **Usar MCP** |
| HTTP 403 (`Host`/`Origin`) | **Nome do host e caminho** não corresponde à URL pública do Redmine; reverse proxy não encaminha o `Host` original; URL MCP no cliente não corresponde — transport rejeita hosts desconhecidos (proteção DNS rebinding) |
| Ferramenta não visível em `tools/list` | Permissões necessárias ausentes; extensão que fornece a ferramenta está desabilitada |
| Novas tools não apareceram após reload do MCP | No Cursor e clientes similares, recarregar o servidor pode não atualizar a lista de ferramentas — reinicie completamente a aplicação |
| Extensão não carrega | Falta `lib/.../mcp.rb`; módulo não faz `extend RedmineMcp::ExtensionApi`; certifique-se de que a checkbox da extensão está habilitada em **Extensões MCP**; se o arquivo tem erro, verifique o log |
| `Issue not found` / `Project not found` | A tarefa ou projeto não é visível ao usuário atual pelas regras de visibilidade do Redmine |

## Licença

Este plugin é licenciado sob a GNU General Public License,
versão 2 ou qualquer versão posterior.

Consulte [LICENSE](../../../LICENSE) para detalhes.
