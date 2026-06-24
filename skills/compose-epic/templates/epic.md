---
# OKF 必須: 概念の種別
type: epic
# leadcraft 拡張: 親 Objective の id_suffix を末尾に付けた正式 ID（例: oauth-login-a1b2c）
id: "{{EPIC_ID}}"
# OKF 推奨: 人間可読の表示名
title: "{{EPIC_TITLE}}"
# OKF 推奨: 1 文の要約。index.md の progressive disclosure と AI 関連度判定の土台
description: ""
# OKF 推奨: 横断検索用タグ（トラッカーラベルをミラーリングする運用も可）
tags: []
# OKF 推奨: Epic の基礎資産 URI（Issue 一覧フィルタ URL 等）。無ければ null
resource: null
# OKF 推奨: ISO 8601 最終更新日時。updated_at と同値
timestamp: "{{UPDATED_AT}}"
# leadcraft 拡張: 親 Objective の id（Objective 自体は suffix を付けない設計）
objective: "{{OBJECTIVE_ID}}"
# leadcraft 拡張: 親 Initiative の正式 ID（suffix 付き）
initiative: "{{INITIATIVE_ID}}"
# leadcraft 拡張: ステータス
status: planning  # planning | in_progress | done | cancelled
# leadcraft 拡張: 作成・更新日時
created_at: "{{CREATED_AT}}"
updated_at: "{{UPDATED_AT}}"
# leadcraft 拡張: プロダクトオーナー / リード
owner: ""
# leadcraft 拡張: リリース予定（バージョン or 時期）
target_release: ""
# leadcraft 拡張: Epic 絞り込みラベル（例: epic:oauth-login-a1b2c）。suffix 付きで他リポジトリの同名 Epic と衝突しない
label: "{{EPIC_LABEL}}"
---

# {{EPIC_TITLE}}

スクラム文脈での Epic は「単一スプリントに収まらない大きなプロダクトバックログアイテム」であり、複数の Story に分解されてはじめて開発可能になる単位を指す。
この README は **生きたドキュメント** として運用する。Story 設計前の計画段階だけでなく、Story が進行・完了する過程で得られる学び・スコープ変更・指標の実測値・新たに見えてきたリスクなどを継続的に反映し、常に最新の状態を保つ。インセプションデッキ等のプロジェクト方針は親 Initiative に記載する。

> 更新タイミングの目安: DoD・価値仮説・スコープの見直し / 主要ユーザーフローの変更 / Epic 規模のリスクや依存関係の変化が発生したとき。
> Story 単位の追加・完了で本 README を更新する必要はない（Story はトラッカーで管理する。下記「配下 Story の参照方法」を参照）。

## 親 Initiative

[{{INITIATIVE_TITLE}}](/{{OBJECTIVE_ID}}/{{INITIATIVE_ID}}/README.md)

## 配下 Story の参照方法

本 Epic に属する Story は既定でバンドル内の Story md（local アダプタ）として管理する。
github アダプタを有効にした場合は GitHub Issue + GitHub Projects に同期できる。

- **local（既定）**: 本 Epic ディレクトリ配下の `*.md`（README.md 以外）が Story
  ```
  ls /{{OBJECTIVE_ID}}/{{INITIATIVE_ID}}/{{EPIC_ID}}/
  ```
- **github（opt-in）**: ラベル `{{EPIC_LABEL}}` でフィルタ（`sync-stories` 実行後）

## 概要

（この Epic が解決する課題、提供する価値を 2〜3 行で記述する）

## ユーザーストーリーサマリー

> **\<role\>** として、**\<goal\>** したい。なぜなら **\<reason\>** だから。

Epic レベルでの大枠の物語を 1〜3 行で記述する。Story 設計の出発点となる。

## 解きたい問題と価値仮説

- **解きたい課題**: （現状の何が問題か）
- **価値仮説**: 〜することで、〜が改善されると考える
- **検証指標 / メトリクス**: （仮説の真偽を判定する指標。Objective の KPI とのつながり）

## 対象ユーザー / ペルソナ

- **主要ペルソナ**: （想定する利用者の属性・状況）
- **副次ペルソナ**: （影響を受ける周辺の利用者）

## スコープ

### 含むもの

- （この Epic で対応する機能・変更）

### 含まないもの（スコープ外）

- （混同しがちだが、この Epic では扱わない事項）

## Epic 完了の定義（Definition of Done）

Epic 全体が完了したと見なすための条件を列挙する。Story 単位の DoD とは独立。

- [ ] （ユーザー価値が実利用できる状態に到達している）
- [ ] （関連する計測・モニタリングが整備されている）
- [ ] （リリースノート・ドキュメントが更新されている）
- [ ] （ステークホルダーへのデモ / 共有が完了している）

## 主要ユーザーフロー

### UF-1: （フロー名）

- **トリガー**: （何が起点になるか）
- **主要ステップ**:
  1. （ステップ 1）
  2. （ステップ 2）
- **完了条件**: （ユーザーから見たゴール）

```mermaid
flowchart LR
    A[開始] --> B[操作 1]
    B --> C[操作 2]
    C --> D[完了]
```

## 依存関係（外部）

- **前提となる Epic / システム**: なし
- **本 Epic がブロックするもの**: なし

## リスクサマリー

Story 単位のリスクは各 Story md の frontmatter `risk_score` / `risks[]` で管理する。
ここでは Epic 全体に共通する横断的リスクのみを記録する。

| ID | リスク | 確率 | 影響 | スコア | 対応方針 |
|----|--------|------|------|--------|---------|
| R1 | （リスク内容） | High | High | 9 | （対応方針） |

## オープン課題 / 未決事項

- （Story 設計前に解消が必要な疑問・調査事項）

## メモ

（補足、検討経緯、決定理由など）
