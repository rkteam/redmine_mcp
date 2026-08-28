# Redmine MCP — 一般仕様

[Deutsch](../de/00-general.md) | [English](../en/00-general.md) | [Español](../es/00-general.md) | [Français](../fr/00-general.md) | [Italiano](../it/00-general.md) | [日本語](00-general.md) | [한국어](../ko/00-general.md) | [Polski](../pl/00-general.md) | [Português (Brasil)](../pt-BR/00-general.md) | [Русский](../ru/00-general.md) | [中文](../zh/00-general.md)

## 概要

Redmine MCP プラグインは、Redmine インストール内に MCP サーバー（Model Context Protocol）を提供します。AI クライアントは単一の HTTP エンドポイントに接続し、ツール、リソース、プロンプトを通じて Redmine データにアクセスします。

プラグインには、プロジェクト、課題、ユーザー向けの基本ツールセットが含まれます。他のインストール済み Redmine プラグインは、Redmine MCP のコードを変更せずに MCP を拡張できます。

## 目的

次を満たす、Redmine と AI システム間の単一の統合メカニズムを提供すること:

- ユーザーは Redmine の権限の範囲内で操作する;
- プラグイン開発者は独自の MCP 機能を追加できる;
- 別途 MCP サーバーやインストール固有のフォークは不要である。

## 主なシナリオ

1. **AI クライアントの接続** — 管理者が MCP を有効化し、必要なロールに `use_mcp` 権限を付与し、API キーを発行する。ユーザーはクライアント（Cursor など）を `/mcp` エンドポイントに接続する。
2. **Redmine データの操作** — クライアントがツールを呼び出してプロジェクト、課題、ユーザーを取得する。
3. **他プラグインによる拡張** — MCP 拡張を持つプラグインがインストールされると、そのツールは共有リストに自動的に表示される。
4. **管理** — MCP の有効化/無効化、個別プラグインの MCP 統合の有効化。

## 影響範囲

- API（HTTP 上の MCP）
- 権限
- 設定
- 課題
- プロジェクト
- ユーザー
- 掲示板
- プラグイン（拡張）

## ビジネスルール

- MCP はプラグイン設定で明示的に有効化された場合のみ利用可能である。
- すべての操作は認証済み Redmine ユーザーとして実行される。
- MCP 経由の書き込みは Redmine モデルを通る: モデルコールバックは実行される。コントローラフック（`controller_issues_*_save`、`controller_journals_edit_post` など）は MCP からは呼び出されない。
- データの可視性は Redmine ルールに従う: ユーザーは Web UI で見られる以上の情報を受け取らない。
- ツール名とプロンプト名は `<plugin_id>_<name>` 形式を使用する（例: `redmine_list_projects`）。
- コアツールの `title` と `description` は LLM 選択用に英語で公開され、`en.yml`/`ru.yml` による**ローカライズは行わない**（MCP ツールカタログに関する i18n 標準の例外）。エラーメッセージと設定 UI はローカライズされる。
- 他プラグインの拡張はハード依存を作らない: Redmine MCP が存在しなくても、サードパーティプラグインは引き続き動作する。

## エッジケース

- MCP が無効の場合、`/mcp` へのすべてのリクエストは拒否される。
- 1 つの拡張が失敗しても、他の拡張とコアツールは引き続き動作する。
- 拡張の新しいツールは Redmine 再起動後に利用可能になる。MCP クライアントはツールリストを更新するために再接続が必要な場合がある。
- ステートレスモードでは、各 HTTP リクエストは独立して処理され、リクエスト間でセッションは保持されない。

## エラー処理

- 認証および認可エラーは HTTP レベルで返される。
- ツール実行エラーは MCP 形式でエラーフラグ付きで返される。
- 拡張の読み込みエラーはログに記録され、Redmine の起動をブロックしない。

## 仕様ファイル

| ファイル | 内容 |
|------|---------|
| [console-commands.md](console-commands.md) | インストール、検証、メンテナンスコマンド |
| [01-mcp-server.md](01-mcp-server.md) | HTTP エンドポイント、MCP プロトコル、トランスポート |
| [02-authentication.md](02-authentication.md) | 認証とアクセス制御 |
| [03-core-tools.md](03-core-tools.md) | 組み込み Redmine ツール |
| [04-extensions.md](04-extensions.md) | 他プラグイン向け拡張 API |
| [05-settings.md](05-settings.md) | プラグイン設定とログ |
| [mcp_tool_development.md](mcp_tool_development.md) | MCP ツール開発要件（開発ガイド） |
| [extension_guide.md](extension_guide.md) | 拡張開発者ガイド |

## テストシナリオ

1. インストールと MCP 有効化後、クライアントが `initialize` を正常に実行し、サーバー情報を受け取る。
2. Use MCP 権限と有効な API キーを持つユーザーが、利用可能なツールリストを確認できる。
3. Use MCP 権限のないユーザーは `/mcp` へのアクセスを拒否される。
4. 拡張プラグインがインストールされている場合、対応する権限を持つユーザーの `tools/list` にそのツールが含まれる。
