---
# OKF 必須: 概念の種別
type: initiative
# leadcraft 拡張: 親 Objective の id_suffix を末尾に付けた正式 ID（例: framework-modernization-a1b2c）
id: "{{INITIATIVE_ID}}"
# OKF 推奨: 人間可読の表示名
title: "{{INITIATIVE_TITLE}}"
# OKF 推奨: 1 文の要約。index.md の progressive disclosure と AI 関連度判定の土台
description: ""
# OKF 推奨: 横断検索用タグ（トラッカーラベルをミラーリングする運用も可）
tags: []
# OKF 推奨: Initiative の基礎資産 URI（Epic 一覧フィルタ URL 等）。無ければ null
resource: null
# OKF 推奨: ISO 8601 最終更新日時。updated_at と同値
timestamp: "{{UPDATED_AT}}"
# leadcraft 拡張: 親 Objective の id（Objective 自体は suffix を付けない設計）
objective: "{{OBJECTIVE_ID}}"
# leadcraft 拡張: ステータス
status: planning  # planning | in_progress | done | cancelled
# leadcraft 拡張: 作成・更新日時
created_at: "{{CREATED_AT}}"
updated_at: "{{UPDATED_AT}}"
# leadcraft 拡張: 推進責任者
owner: ""
# leadcraft 拡張: 完了目標時期
target_date: ""
# leadcraft 拡張: 配下 Epic 件数
epic_count: 0
# leadcraft 拡張: 配下 Story の合計ポイント
total_points: 0
---

# {{INITIATIVE_TITLE}}

この README は **生きたドキュメント** として運用する。インセプションデッキで合意した前提や、関連 Epic の進捗・学び・スコープ変更を継続的に反映し、常に最新の状態を保つ。

> 更新タイミングの目安: 新規 Epic 追加 / 既存 Epic の完了・破棄、インセプションデッキ各項目の見直し、マイルストーン・リスクの変化が発生したとき（関係者・推進責任者の異動はインセプションデッキ「ご近所さんを探せ」を更新する）。

## 親 Objective

[{{OBJECTIVE_TITLE}}](/{{OBJECTIVE_ID}}/README.md)

## 概要

（この Initiative が担う取り組みの全体像と、達成しようとする状態を簡潔に記述する）

## 目的・期待される成果

- （取り組みによって生み出すユーザー価値 / 事業価値）
- （関連する Objective の KPI への寄与）

## インセプションデッキ

Initiative を立ち上げるにあたり、関係者間で目線合わせを行うための 10 の問いに答える。
未確定の項目は空欄のままで構わない。確定するたびに更新する。

### 1. なぜここにいるのか

（この Initiative に取り組む理由、ミッション、解こうとしている本質的な課題）

### 2. エレベーターピッチ

- **対象**: （誰のためか）
- **問題**: （どんな問題を解決するか）
- **製品名 / 取り組み名**: （社内通称・呼び方）
- **カテゴリ**: （プロダクト・機能の分類）
- **競合・代替案との違い**: （差別化ポイント）

### 3. パッケージデザイン

（リリース / ローンチ時のキャッチコピー、訴求ポイント、共有資料の表紙イメージ）

### 4. やらないことリスト

- （明示的にこの Initiative には含めない事項。スコープ外の宣言）

### 5. ご近所さんを探せ

（関係者・ステークホルダー・依存する他チームや他システム）

### 6. 解決策を描く

（採用するアプローチ / 技術スタック / 大まかな実装方針の概要）

### 7. 夜も眠れない問題

（プロジェクトの主要リスク。詳細は下記「リスクと留意点」に展開）

### 8. 期間を見極める

（想定期間、主要マイルストーン。詳細は下記「マイルストーン」に展開）

### 9. 何を諦めるのか

（トレードオフ: スコープ・期日・予算・品質のどれを優先し、どれを諦めるか）

### 10. 何がどれだけ必要なのか

（必要なリソース・人員・コスト・外部依存）

## 関連 Epic

| # | Epic | Status | Points | Link |
|---|------|--------|--------|------|
| 1 | （Epic 名） | planning | 0 | [/{{OBJECTIVE_ID}}/{{INITIATIVE_ID}}/{{EPIC_ID}}/README.md](/{{OBJECTIVE_ID}}/{{INITIATIVE_ID}}/{{EPIC_ID}}/README.md) |

**合計ポイント**: 0

## マイルストーン

- **着手**: （いつまでに開始）
- **MVP / 中間成果**: （途中のチェックポイント）
- **完了**: （目標時期）

## 依存関係

- **前提となる Initiative / Epic**: なし
- **本 Initiative がブロックするもの**: なし

## リスクと留意点

| ID | リスク / 留意点 | 影響 | 対応方針 |
|----|------------------|------|----------|
| R1 | （リスク内容） | High | （回避・軽減策） |

## 参考資料

- （関連ドキュメントへのリンク）

## メモ

（補足、決定事項、検討中事項など）
