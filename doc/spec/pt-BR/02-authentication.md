# Autenticação e autorização

[Deutsch](../de/02-authentication.md) | [English](../en/02-authentication.md) | [Español](../es/02-authentication.md) | [Français](../fr/02-authentication.md) | [Italiano](../it/02-authentication.md) | [日本語](../ja/02-authentication.md) | [한국어](../ko/02-authentication.md) | [Polski](../pl/02-authentication.md) | [Português (Brasil)](02-authentication.md) | [Русский](../ru/02-authentication.md) | [中文](../zh/02-authentication.md)

## Visão geral

O acesso ao MCP usa autenticação padrão por chave de API do Redmine. Todas as operações são executadas em nome do usuário dono da chave.

## Objetivo

Garantir que o MCP não contorne a segurança do Redmine e que usuários possam realizar apenas ações permitidas para eles.

## Áreas afetadas

- Permissões
- API
- Usuários

## Regras de negócio

### Autenticação

- A REST API do Redmine deve estar habilitada para acessar `/mcp`.
- A chave de API é passada no header `X-Redmine-API-Key` (não do corpo JSON da requisição nem da query string).
- Apenas chaves de usuários ativos são aceitas.
- Requisições sem chave ou com chave inválida são rejeitadas.

### Permissão global do MCP

- O usuário deve ter a permissão global **Use MCP** (`use_mcp`), ou ser administrador do Redmine.
- A permissão `use_mcp` é habilitada manualmente para as roles necessárias em **Administração → Roles e permissões**.
- Administradores sempre têm acesso ao MCP: a verificação padrão de permissão global do Redmine permite admin independentemente das roles.
- Para outros usuários sem `use_mcp`, a requisição é rejeitada mesmo com chave de API válida.

### Permissões de ferramentas

- Cada ferramenta tem seu próprio requisito de permissão do Redmine.
- Uma ferramenta aparece em `tools/list` apenas se o usuário tem permissão para usá-la.
- Permissões são verificadas novamente quando a ferramenta é chamada.
- Dados são filtrados pelas regras de visibilidade do Redmine (projetos, tarefas, membros).

### Permissões de recursos e prompts

- Recursos e prompts podem ter seus próprios requisitos de permissão.
- Sem permissão, um recurso ou prompt não é listado e não pode ser lido.
- Verificações de permissão de recursos e prompts consideram a URI e argumentos de entrada (incluindo `project` / `project_id`). Se o projeto não é especificado nos argumentos, permissão em pelo menos um projeto visível é suficiente.
- Uma extensão pode definir uma regra explícita para resolver o projeto da URI e argumentos.

## Casos extremos

- Um usuário inativo não pode usar o MCP mesmo com chave emitida anteriormente.
- Um administrador tem acesso ao MCP sem atribuição separada de `use_mcp`.
- Uma ferramenta com verificações de permissão por entidade (por exemplo, uma tarefa) pode ser visível em `tools/list` com argumentos vazios se o usuário tem a permissão correspondente em pelo menos um projeto.
- Se tal ferramenta também exige um módulo de projeto do Redmine, "pelo menos um projeto" significa um projeto visível onde o usuário tem a permissão e o módulo especificado está habilitado. Sem requisito de módulo, permissão em pelo menos um projeto visível é suficiente. Presença em `tools/list` não significa permissão para uma tarefa específica: permissões e disponibilidade do objeto são verificadas novamente na chamada.

## Tratamento de erros

| Situação | Resultado |
|----------|-----------|
| REST API desabilitada | HTTP 401 |
| Chave de API inválida ou ausente | HTTP 401 |
| Sem permissão Use MCP | HTTP 403 |
| Sem permissão para ferramenta específica | Ferramenta ausente de `tools/list`; chamada direta — erro "Permission denied" |
| Entidade indisponível ao usuário | Resposta da ferramenta com descrição de erro (por exemplo, "Issue not found") |

## Cenários de teste

1. Requisição com chave válida e permissão Use MCP — acesso bem-sucedido.
2. Requisição sem header de chave de API — HTTP 401.
3. Requisição com chave não-admin sem permissão Use MCP — HTTP 403.
4. Chave de administrador sem role com `use_mcp` — acesso bem-sucedido.
5. Usuário vê em `tools/list` apenas ferramentas para as quais tem permissão.
6. Chamar ferramenta para tarefa inacessível retorna erro, não dados de outro usuário.
7. Ferramenta com escopo de tarefa e requisito de módulo de projeto não é visível em `tools/list` se o usuário tem a permissão mas não tem projeto visível com o módulo habilitado; é visível se tal projeto existe.
