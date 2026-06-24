---
type: adr
id: "20251101-introduce-structured-logging"
title: "ログ出力の構造化ライブラリ導入"
description: "全アプリで不統一なログ出力を共通の構造化ログライブラリへ統合し、MTTR 短縮に寄与する決定"
resource: null
tags: ["logging", "observability", "migration"]
timestamp: "2025-11-08T09:30:00Z"
status: accepted
created_at: "2025-11-01"
updated_at: "2025-11-08"
owner: "テックリード"
level: "epic"
objective: "platform-modernization"
initiative: "observability-overhaul"
epic: "structured-logging"
affected_objectives: []
supersedes: ""
superseded_by: ""
related_stories: ["/platform-modernization/observability-overhaul-a1b2c/structured-logging-a1b2c/replace-print-statements.md", "/platform-modernization/observability-overhaul-a1b2c/structured-logging-a1b2c/add-log-aggregation.md"]
---

# ログ出力の構造化ライブラリ導入

## Context

本 Epic（`structured-logging`）の前提として、アプリケーション全体でログ出力が統一されていない。`Grep` による調査では 38 ファイル / 72 箇所で `print()` や `console.log()` が直接呼び出されており、ログレベル（debug / info / error）の区別がない。

親 Initiative（`observability-overhaul`）の KPI である「障害検知から原因特定までの平均時間（MTTR）を 50% 短縮」に対し、現状のログでは:

- 本番環境でデバッグ用の詳細ログが出力され、パフォーマンスとセキュリティに影響する
- エラー発生時にログからの原因特定が困難（タイムスタンプやコンテキスト情報の欠落）
- ログのフォーマットが不統一で、ログ集約基盤でのパースが難しい

### 検討した選択肢

- **A: 構造化ログライブラリの導入（推奨）** — 共通の `Logger` モジュールを作成し、ログレベル・タイムスタンプ・呼び出し元情報を自動付与する。JSON 形式での出力にも対応でき、ログ集約基盤との連携が容易になる
- **B: 既存コードに手動でログレベルを追加** — ライブラリ導入なしで各ファイルを修正。ただし統一の強制力がなく、新規コードで再び不統一になるリスクがある
- **C: 現状維持** — ログの不統一とデバッグ困難が継続する。障害対応のたびに調査コストが増大する（MTTR 目標達成不能）

## Decision

**選択肢A: 構造化ログライブラリの導入** を採用する。

- ログレベルを統一的に管理でき、環境ごとの出力制御（本番では info 以上のみ等）が容易
- JSON 構造化により、既存のログ集約基盤との連携がそのまま可能
- 段階的に移行: Logger モジュール作成 → 新規コードから使用 → 既存の `print()` / `console.log()` を順次置換（個別の置換タスクは関連 Story に分離）

## Consequences

- ログレベルの統一により、本番環境での不要なログ出力が抑制される
- タイムスタンプ・呼び出し元情報の自動付与で、障害時の原因特定が迅速になる（Initiative KPI に直接寄与）
- ログフォーマットが統一され、ログ集約基盤での分析が容易になる
- 既存 38 ファイルの段階的な置換作業が必要（機能単位で順次対応）
- ロールバックは各ファイルで直接出力に戻すのみで可能

# Citations

- `src/api/handler.py:42` — `print()` による直接出力（置換対象）
- `web/components/cart.js:118` — `console.log()` によるデバッグ出力（置換対象）
- `package.json:24` — 既存のログ関連依存なし（新規導入の余地あり）
