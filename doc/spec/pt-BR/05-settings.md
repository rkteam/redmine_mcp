# Configurações e logging

[Deutsch](../de/05-settings.md) | [English](../en/05-settings.md) | [Español](../es/05-settings.md) | [Français](../fr/05-settings.md) | [Italiano](../it/05-settings.md) | [日本語](../ja/05-settings.md) | [한국어](../ko/05-settings.md) | [Polski](../pl/05-settings.md) | [Português (Brasil)](05-settings.md) | [Русский](../ru/05-settings.md) | [中文](../zh/05-settings.md)

## Visão geral

O plugin Redmine MCP é configurado pela interface padrão de configurações de plugins do Redmine. A operação do MCP é adicionalmente registrada em log.

## Objetivo

Dar ao administrador controle sobre habilitar o MCP e habilitar a integração MCP para plugins individuais.

## Áreas afetadas

- Configurações
- UI
- Plugins

## Regras de negócio

### Parâmetros de configuração

As configurações estão disponíveis em **Administração → Plugins → Redmine MCP → Configurar**.

| Parâmetro | Padrão | Descrição |
|----------|--------------|----------|
| Habilitar MCP | desligado | Habilita ou desabilita o endpoint `/mcp`. Quando habilitado, extensões MCP de plugins instalados são carregadas automaticamente |
| Modo somente leitura | desligado | Bloqueia ferramentas de escrita e ações de escrita |
| Extensões MCP | todas habilitadas | Checkboxes ao lado dos nomes de plugins instalados com integração MCP |

### Extensões MCP na UI

- Um campo de texto para lista de identificadores ("Disabled extensions") e uma lista de referência de todos os plugins instalados não são usados.
- Uma checkbox separada de auto-carga de extensões não é usada.
- Em vez disso, a página de configurações mostra uma lista de plugins instalados que têm integração MCP.
- Um plugin é considerado com integração MCP se uma fonte de extensão for encontrada pela convenção de auto-carga: `mcp.rb` no plugin ou o arquivo integrado `lib/redmine_mcp/extensions/<plugin.id>.rb` em `redmine_mcp` (ver [04-extensions.md](04-extensions.md)).
- O plugin `redmine_mcp` não é mostrado nesta lista.
- Cada item tem uma checkbox e o nome do plugin.
- A legenda da lista tem um toggle Marcar todos / Desmarcar todos, como projetos e trackers em um formulário de campo customizado.
- Uma checkbox marcada significa que a extensão MCP do plugin é carregada quando o MCP está habilitado.
- Uma checkbox desmarcada significa que a extensão do plugin não é carregada mesmo se o arquivo de extensão existe.
- Se nenhum plugin instalado tem integração MCP, a lista está vazia: a mensagem padrão do Redmine "sem dados" é exibida; o toggle Marcar todos / Desmarcar todos fica oculto.
- Identificadores de plugins desabilitados salvos anteriormente continuam aplicando: as checkboxes correspondentes aparecem desmarcadas.

### Comportamento ao alterar configurações

- Desabilitar o MCP bloqueia imediatamente todas as requisições a `/mcp` (HTTP 503).
- Quando o MCP está habilitado, extensões carregam na inicialização do Redmine. Quando o MCP está desabilitado, auto-carga de extensões não executa.
- Alterar checkboxes de extensões MCP tem efeito após reinício do Redmine.

## Registro

### O que é registrado

- início e fim da carga de extensões;
- registro bem-sucedido de ferramentas, recursos, prompts;
- extensão de ferramentas existentes;
- erros de registro e carga de extensões;
- erros de execução de ferramentas;
- negações de acesso ao MCP e a ferramentas.

### Formato

- Mensagens são escritas no log Rails padrão.
- Cada mensagem tem o prefixo `[redmine_mcp]`.
- Uma configuração separada de nível de logging não é usada: o plugin escreve todas as suas mensagens.

## Casos extremos

- Se todas as checkboxes de extensões MCP estão habilitadas (ou nenhum plugin tem integração), todas as extensões encontradas carregam quando o MCP está habilitado.
- Um plugin sem extensão MCP (nem `mcp.rb` nem integração integrada) não é mostrado na lista e não é desabilitado por essas configurações.
- Se um plugin posteriormente ganha integração MCP, sua checkbox é habilitada por padrão a menos que o plugin foi desabilitado anteriormente.
- Identificadores de plugins desconhecidos ou removidos em listas desabilitadas salvas são ignorados.
- Uma flag de auto-carga de extensões salva anteriormente é ignorada: a carga de extensões segue Habilitar MCP.
- Um nível de logging salvo anteriormente é ignorado e removido ao salvar configurações.
- Com Modo somente leitura habilitado, ferramentas de escrita permanecem em `tools/list` (se o usuário tem permissões) mas retornam erro quando chamadas; ações de leitura de ferramentas combinadas continuam funcionando.

## Tratamento de erros

- Erros de configurações não devem bloquear a inicialização do Redmine.
- Erros de logging não afetam o processamento de requisições MCP.

## Cenários de teste

1. MCP desabilitado — requisições a `/mcp` retornam HTTP 503.
2. MCP habilitado — requisições são processadas.
3. Plugin com integração MCP desmarcado — suas ferramentas estão ausentes após reinício.
4. A página de configurações não tem campo de nível de logging; mensagens MCP são escritas no log Rails.
5. A página de configurações mostra nomes apenas de plugins instalados com integração MCP; cada um tem uma checkbox.
6. Plugin sem integração MCP não é mostrado na página de configurações.
7. Quando o MCP está desabilitado, extensões de outros plugins não são carregadas na inicialização.
