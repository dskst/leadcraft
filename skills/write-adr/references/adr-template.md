---
type: adr                       # OKF 必須。非空の type。ADR は固定で adr
id: "{{ADR_ID}}"                # <YYYYMMDD>-<kebab-title> 形式（例: 20260519-introduce-structured-logging）。ファイル名（拡張子抜き）と一致させる
title: "{{TITLE}}"              # OKF 推奨。人間可読の表示名
description: "{{DESCRIPTION}}"  # OKF 推奨。決定内容の 1 文要約（index.md の progressive disclosure と AI 関連度判定の土台）
resource: null                 # OKF 推奨。関連 Issue があれば URL、無ければ null
tags: []                        # OKF 推奨。横断検索用（例: [backend, security, migration]）
timestamp: "{{TIMESTAMP}}"     # OKF 標準キー。ISO 8601 の最終更新日時（例: 2026-05-19T09:30:00Z）。updated_at と同値
status: accepted                # 拡張。accepted | deprecated | superseded
created_at: "{{CREATED_AT}}"    # 拡張。YYYY-MM-DD
updated_at: "{{UPDATED_AT}}"    # 拡張。YYYY-MM-DD。本文に手を入れたタイミングで更新
owner: ""                       # 拡張。提案者（個人 or ロール）
level: "{{LEVEL}}"              # 拡張。cross-objective | objective | initiative | epic
objective: "{{OBJECTIVE_ID}}"   # 拡張。level=cross-objective の場合は空
initiative: "{{INITIATIVE_ID}}" # 拡張。level=cross-objective|objective の場合は空
epic: "{{EPIC_ID}}"             # 拡張。level=cross-objective|objective|initiative の場合は空
affected_objectives: []         # 拡張。level=cross-objective 時に推奨。影響を受ける Objective ID（例: [checkout, growth]）
supersedes: ""                  # 拡張。この ADR が置き換える元 ADR の ID（例: 20250812-introduce-text-logging）
superseded_by: ""               # 拡張。この ADR を置き換えた別 ADR の ID
related_stories: []             # 拡張。関連 Story を item_ref 語彙で（local: バンドル絶対パス / github: #番号）。例: ["/obj/init/epic/password-reset.md"] または ["#123", "#145"]
---

# {{TITLE}}

<!-- ファイル名規則: adr/{id}.md（{id} = <YYYYMMDD>-<kebab-case-title>。例: adr/20260519-introduce-structured-logging.md） -->
<!-- 配置先（level に応じる）:
       cross-objective → <root>/adr/...
       objective       → <root>/<objective>/adr/...
       initiative      → <root>/<objective>/<initiative>/adr/...
       epic            → <root>/<objective>/<initiative>/<epic>/adr/... -->
<!-- タイトルに ADR-XXXX のような ID プレフィックスを付けない。ID は frontmatter の `id` とファイル名 prefix で管理する -->
<!-- 内部リンク（親 README・関連 Story・supersedes 先 ADR）はバンドル絶対パス（`/` 始まり）で書く -->

## Context

<!-- 背景・現状の課題・なぜ今この決定が必要かを記述する -->
<!-- 親階層（Objective / Initiative / Epic）の文脈と接続して書く -->
<!-- level=cross-objective の場合は、影響を受ける Objective を 2 件以上明示し、それぞれの KPI / スコープへの関連を記述する -->
<!-- Grep / Glob で取得した実データ（ファイル数・参照箇所数・依存関係）を含める -->
<!-- 検討した選択肢があれば、ここで比較する -->

## Decision

<!-- 何を選んだか、なぜかを記述する -->
<!-- 移行の方針（段階的に行う等）は記載するが、具体的なフェーズ・工数・担当は Story に分離する -->

## Consequences

<!-- この決定によって生じる結果をすべて記載する -->
<!-- ポジティブ・ネガティブ・中立の影響を区別して書く -->
<!-- ロールバック手順を 1〜2 行で書く -->

<!-- # Citations（任意）
       コードベース調査で得た file:line 根拠をこの慣用見出し下にまとめる。
       本文中に都度埋め込んでも、ここに集約しても良い（okf-conformance.md § 5）。 -->
