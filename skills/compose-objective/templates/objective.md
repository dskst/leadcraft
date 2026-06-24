---
# OKF 必須: 概念の種別
type: objective
# leadcraft 拡張: バンドルルートからの相対パス（.md 除く）が Concept ID になる
id: "{{OBJECTIVE_ID}}"
# leadcraft 拡張: 配下 Initiative / Epic の id 末尾に付与する 5 文字（小文字英数字）。スコープ識別子として Objective 作成時に一度だけ確定し、以後不変
id_suffix: "{{OBJECTIVE_ID_SUFFIX}}"
# OKF 推奨: 人間可読の表示名
title: "{{OBJECTIVE_TITLE}}"
# OKF 推奨: 1 文の要約。index.md の progressive disclosure と AI 関連度判定の土台
description: ""
# OKF 推奨: 横断検索用タグ（トラッカーラベルをミラーリングする運用も可）
tags: []
# OKF 推奨: Objective の基礎資産 URI（Projects URL 等）。無ければ null
resource: null
# OKF 推奨: ISO 8601 最終更新日時。updated_at と同値
timestamp: "{{UPDATED_AT}}"
# leadcraft 拡張: ステータス
status: planning  # planning | in_progress | done | cancelled
# leadcraft 拡張: 作成・更新日時
created_at: "{{CREATED_AT}}"
updated_at: "{{UPDATED_AT}}"
# leadcraft 拡張: 経営・事業責任者など
owner: ""
# leadcraft 拡張: 達成目標時期（YYYY-Q? や YYYY-MM 等）
target_date: ""
# leadcraft 拡張: KPI リスト
kpis: []
# leadcraft 拡張: 配下 Initiative 件数（compose-initiative 追加時に更新）
initiative_count: 0
---

# {{OBJECTIVE_TITLE}}

この README は **生きたドキュメント** として運用する。事業環境・KPI 実績・関連 Initiative の進捗に応じて継続的に最新化する。

> 更新タイミングの目安: KPI / 目標値の見直し、関連 Initiative の追加・終了、戦略の見直しが発生したとき。

## 概要

（この Objective が解決する経営・事業・プロダクト上の課題と、達成したい状態を簡潔に記述する）

## 背景

（なぜ今この Objective を掲げるのか、外部環境・市場・組織状況）

## 達成基準（KPI / 成果指標）

| 指標 | 目標値 | 現状 | 計測方法 |
|------|--------|------|----------|
| （指標名） | （目標） | （現状） | （計測の仕方） |

## 関連 Initiative

| # | Initiative | Status | Link |
|---|------------|--------|------|
| 1 | （Initiative 名） | planning | [/{{OBJECTIVE_ID}}/{{INITIATIVE_ID}}/README.md](/{{OBJECTIVE_ID}}/{{INITIATIVE_ID}}/README.md) |

## マイルストーン

- **着手目標**: （いつまでに開始）
- **中間レビュー**: （中間チェックポイント）
- **達成目標**: （最終ゴール時期）

## やらないこと（スコープ外）

- （明示的にこの Objective には含めない事項）

## 参考資料

- （関連ドキュメント、議事録、ダッシュボード等のリンク）

## メモ

（補足、今後の検討事項など）
