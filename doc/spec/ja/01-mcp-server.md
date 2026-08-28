# MCP サーバーと HTTP エンドポイント

[Deutsch](../de/01-mcp-server.md) | [English](../en/01-mcp-server.md) | [Español](../es/01-mcp-server.md) | [Français](../fr/01-mcp-server.md) | [Italiano](../it/01-mcp-server.md) | [日本語](01-mcp-server.md) | [한국어](../ko/01-mcp-server.md) | [Polski](../pl/01-mcp-server.md) | [Português (Brasil)](../pt-BR/01-mcp-server.md) | [Русский](../ru/01-mcp-server.md) | [中文](../zh/01-mcp-server.md)

## 概要

Redmine MCP は、リクエスト間でセッションを保持しない（ステートレス）Streamable HTTP モードで MCP（Model Context Protocol）を実装する HTTP エンドポイント `/mcp` を提供します。

## 目的

別途サーバープロセスなしで、外部 AI クライアントが標準 MCP プロトコルを使用して Redmine とやり取りできるようにすること。

## 影響範囲

- API
- プラグイン

## ビジネスルール

- エンドポイントは Redmine ルートからの相対パス `/mcp` で利用可能である。
- Streamable HTTP 仕様に従い、HTTP メソッド `GET`、`POST`、`DELETE` がサポートされる。
- 各リクエストは現在の認証済みユーザーのコンテキストで処理される。
- 各リクエストについて、ユーザーの権限に応じた最新のツール、リソース、プロンプトセットが構築される。
- サーバーは名前 `redmine_mcp` とプラグインバージョンに一致するバージョンを通知する。
- MCP Protocol Revision は `2025-11-25`（ヘッダー `MCP-Protocol-Version` と `initialize` の `protocolVersion`）。
- 標準 MCP メソッドがサポートされる: `initialize`、`tools/list`、`tools/call`、`resources/list`、`resources/read`、`prompts/list`、`prompts/get`、およびサポートされるプロトコルバージョンが提供するその他のメソッド。
- ツール応答は `structuredContent` に JSON エンベロープ（`ok`、`data` または `error`）を返し、`content` には短いテキスト表現（成功時は JSON 文字列、失敗時はエラーメッセージ）を返す。
- API キーは `X-Redmine-API-Key` ヘッダーからのみ受け付ける。JSON-RPC ボディは認証に使用されず、リクエストサイズチェック前にパースされない。
- HTTP ボディサイズは JSON パース前に制限される: 上限超過時はリクエストが拒否され、MCP トランスポートはボディを読み込まない。

## エッジケース

- MCP が無効の場合、エンドポイントは HTTP 503 を返し、MCP リクエストを処理しない。
- ステートレスモードでは、スタンドアロン SSE ストリーム用の `GET` リクエストはサポートされない（HTTP 405）— これは想定される動作である。
- ロードバランサー配下でも、スティッキーセッションは不要である。
- ツールリストは権限によってユーザーごとに異なる場合がある。

## エラー処理

- 無効な JSON-RPC リクエスト — MCP プロトコルエラー応答。
- 内部リクエスト処理エラー — エラーメッセージ付き HTTP 500。
- ツール実行エラー — `isError: true` とテキスト説明付き MCP 応答。
- プロセス内 REST（`InternalRequest`）: 404 → `NOT_FOUND`; バージョン競合 → `CONFLICT`; 競合なしの 401/403 → `FORBIDDEN`; `errors` 配列 → `VALIDATION_ERROR`。エンベロープには内部リクエストの HTTP ステータスや生の例外メッセージは含まれない。
- 無効なツール引数（必須フィールド欠落、型不一致、`additionalProperties: false` 時の余分なプロパティ、min/max 範囲外）— `structuredContent` に `VALIDATION_ERROR` 付き実行エラー。`content` のテキストは `error.message` と一致し、生の JSON Schema メッセージは含まない。

## テストシナリオ

1. メソッド `initialize` の `POST /mcp` は capabilities、`serverInfo`、`protocolVersion` `2025-11-25` を返す。
2. メソッド `tools/list` の `POST /mcp` は現在のユーザーのツールリストを返す。
3. 有効なツール名でメソッド `tools/call` の `POST /mcp` は `structuredContent` 付き結果を返す。
4. MCP 無効時の `/mcp` リクエストは HTTP 503 を返す。
5. 存在しないツールの呼び出しは "Tool not found" エラーを返す。
6. ツール権限のない `tools/call` はアクセス拒否コード付き実行エラーを返す。呼び出しはレート制限と構造化監査にカウントされる。
7. 上限を超える HTTP ボディは JSON パース前に拒否される。
8. 読み取り専用モード有効時の書き込みツールは、同じ HTTP/`tools/call` パスでエラーを返す。
9. アクセス不可プロジェクトの URI による `resources/read` はリソース内容を返さない。
10. アクセス不可プロジェクト引数による `prompts/get` はアクセスを拒否する。
11. 空の引数、余分なフィールド、または誤った引数型の `tools/call` は `isError: true` と `structuredContent.error.code` `VALIDATION_ERROR` を返す。
