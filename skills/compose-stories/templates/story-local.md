---
# leadcraft local story
# 本ファイルは compose-stories / quick-stories のローカルモードで生成される Story md。
# - 配置: <epic-dir>/<story-slug>.md（Epic README と同階層）
# - 見積もり詳細・リスクは estimate-points / identify-risks のローカルモードで更新される
# - sync-stories でトラッカー（既定 local / 任意 github）へ同期（新規作成 or 既存項目更新）できる

# OKF 必須: 概念の種別
type: story
# leadcraft 拡張: ステータス
status: draft               # draft | ready（review-stories 卒業時に ready）
# leadcraft 拡張: 生成モード
mode: composed              # composed | quick（quick-stories から生成された場合は quick）

# leadcraft 拡張: 階層 ID（compose-epic までで確定した値をそのまま転記）
objective_id: "{{OBJECTIVE_ID}}"
initiative_id: "{{INITIATIVE_ID}}"
epic_id: "{{EPIC_ID}}"

# OKF 推奨: 人間可読の表示名
title: "{{STORY_TITLE}}"
# OKF 推奨: 1 文の要約。index.md の progressive disclosure と AI 関連度判定の土台
description: ""
# OKF 推奨: 横断検索用タグ（トラッカーラベルをミラーリングする運用も可）
tags: []
# OKF 推奨: 同期済みトラッカー項目の URI（resource_uri 操作で取得）。未同期は null
resource: null
# OKF 推奨: ISO 8601 最終更新日時。updated_at と同値
timestamp: "{{UPDATED_AT}}"

# leadcraft 拡張: 作成・更新日時
created_at: "{{CREATED_AT}}"
updated_at: "{{UPDATED_AT}}"

# leadcraft 拡張: 見積もり（estimate-points が更新する）
points: 0
estimation:
  mode: "pert"              # pert | simple
  o: 0
  m: 0
  p: 0
  e: 0
  stddev: 0
  baseline_comparison: ""

# leadcraft 拡張: リスク（identify-risks が更新する）
risk_score: 0
risks: []
  # 例:
  # - id: R1
  #   risk: "外部 API 仕様未確定"
  #   probability: "M"
  #   impact: "H"
  #   score: 6
  #   mitigation: "プロトタイプで早期検証"
  #   p_delta: 1

# leadcraft 拡張: 依存関係（他 Story md のバンドル絶対パス、または item_ref）
dependencies:
  blocked_by: []
  blocks: []

# leadcraft 拡張: トラッカー項目参照（tracker-contract の item_ref。local: バンドル絶対パス / github: Issue 番号）
tracker_ref: null
# leadcraft 拡張: GitHub アップロード状態（sync-stories が更新する。github アダプタ使用時のみ）
github_issue: null          # 数値の Issue 番号（例: 123）
github_issue_url: null
uploaded_at: null           # ISO 8601 タイムスタンプ

# leadcraft 拡張: 同期時に付与するラベル（sync-stories が利用）
# `epic:<epic_id>` は sync-stories が自動付与するためここでは省略
labels:
  - story
  - draft                   # mode が quick の場合は "quick" に置き換える
---

# {{STORY_TITLE}}

<!--
本ファイルは leadcraft のローカル Story md。
- 編集は手動でも可。ただし frontmatter のスキーマを壊さないこと
- 見積もり詳細・リスクと対応策のセクションは estimate-points / identify-risks のローカルモードが書き換える
- sync-stories でトラッカー（既定 local / 任意 github）へ同期される際は、本文の HTML コメントは除去される
-->

## 階層

- **Objective**: {{OBJECTIVE_TITLE}}
- **Initiative**: {{INITIATIVE_TITLE}}
- **Epic**: {{EPIC_TITLE}} （[README](/{{OBJECTIVE_ID}}/{{INITIATIVE_ID}}/{{EPIC_ID}}/README.md)）

## 背景・目的

{{STORY_PURPOSE}}

> 参考形式: 「**\<role\>** として、**\<goal\>** したい。なぜなら **\<reason\>** だから。」（必須ではない）

## 受け入れ基準（Acceptance Criteria）

- [ ] {{ACCEPTANCE_CRITERIA_1}}
- [ ] {{ACCEPTANCE_CRITERIA_2}}
- [ ] {{ACCEPTANCE_CRITERIA_3}}

<!--
以下のセクションは composed モード（compose-stories 経由）で生成される。
quick モード（quick-stories 経由）では本文を 3 セクション（階層 / 背景・目的 / 受け入れ基準）に留めるため、
compose-stories で肉付けするまで以下は出力しないか、空の雛形のみ残す。
-->

## タスク

- [ ] {{TASK_1}}
- [ ] {{TASK_2}}
- [ ] テスト追加・実行
- [ ] ドキュメント更新

## 見積もり詳細

| 項目 | 値 |
|------|-----|
| Points | {{POINTS}} |
| 見積もりモード | {{ESTIMATION_MODE}}（pert / simple） |
| 楽観値 (O) | {{O}} |
| 最頻値 (M) | {{M}} |
| 悲観値 (P) | {{P}} |
| 期待値 (E) | {{E}} |
| 標準偏差 (σ) | {{STDDEV}} |
| 基準点比較 | {{BASELINE_COMPARISON}} |

> frontmatter の `points` / `estimation.*` と本セクションは連動する。`estimate-points` のローカルモードが両方を同時に更新する。

## リスクと対応策

| ID | リスク | 確率 (H/M/L) | 影響 (H/M/L) | スコア (1-9) | 対応策 | P 反映 |
|----|--------|---------------|----------------|----------------|--------|--------|
| R1 | {{RISK_1}} | {{PROB_1}} | {{IMPACT_1}} | {{SCORE_1}} | {{MITIGATION_1}} | {{P_DELTA_1}} |

**最大リスクスコア**: {{MAX_RISK_SCORE}}
**P 反映合計**: +{{P_REFLECTED_TOTAL}}

> frontmatter の `risk_score` / `risks[]` と本セクションは連動する。`identify-risks` のローカルモードが両方を同時に更新する。

## 依存関係

- **前提 Story**: {{DEPENDENCY_ITEMS}} <!-- 他 Story md のバンドル絶対パス（/obj/init/epic/story.md）、または item_ref -->
- **ブロックする Story**: {{BLOCKING_ITEMS}}

## Definition of Done

<!--
compose-stories のローカルモードでは `setup-dod` で登録された DoD をチェックリストとして本セクションに展開する。
github アダプタでは Issue 起票直後にフォローコメントとして投稿するが、ローカルモードでは本文末尾に保持する。
sync-stories でトラッカーにアップロードする際、本セクションの内容は **フォローコメント** として投稿される（本文には含めない）。
-->

{{DOD_ITEMS}}

## 参考

- 親 Epic README: [/{{OBJECTIVE_ID}}/{{INITIATIVE_ID}}/{{EPIC_ID}}/README.md](/{{OBJECTIVE_ID}}/{{INITIATIVE_ID}}/{{EPIC_ID}}/README.md)
- 親 Initiative README: [/{{OBJECTIVE_ID}}/{{INITIATIVE_ID}}/README.md](/{{OBJECTIVE_ID}}/{{INITIATIVE_ID}}/README.md)

---
*Generated / managed by `leadcraft` local mode (compose-stories / quick-stories / estimate-points / identify-risks / sync-stories).*
