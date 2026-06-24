# {{STORY_TITLE}}

<!--
本テンプレートは github プロバイダ（opt-in / Phase 2）で起票する Story Issue 本文の雛形である。
- frontmatter は付けない（GitHub Issue 本文には YAML frontmatter を載せないため）
- source of truth は local の Story md（OKF concept）側にあり、本 Issue はその同期先である
  （`references/backends/github.md` / `references/okf-conformance.md` を参照）
- 階層情報は GitHub Projects のカスタムフィールド（Objective / Initiative / Epic）にもセットする
- 見積もり詳細（O / M / P / E / σ）とリスクは本セクションを edit で書き換える形で更新する
- Definition of Done はチーム共通のため、Issue 作成直後にフォローコメントとして投稿される
- 本文の構造・プレースホルダ名は local モードの `story-local.md` と揃えている
  （唯一の差は frontmatter の有無。本文セクションは同一）
-->

## 階層

- **Objective**: {{OBJECTIVE_TITLE}}
- **Initiative**: {{INITIATIVE_TITLE}}
- **Epic**: {{EPIC_TITLE}} （[README]({{EPIC_README_LINK}})）

> 上位階層の Issue は作成しない。値は Projects のカスタムフィールド（`Objective` / `Initiative` / `Epic`）にもセットされる。
> Epic フィルタ用に `epic:{{EPIC_ID}}` ラベルが本 Issue に付与されている。
> Epic README へのリンクはバンドル絶対パス（`/{{OBJECTIVE_ID}}/{{INITIATIVE_ID}}/{{EPIC_ID}}/README.md`）で記述する（OKF クロスリンク規約）。

## 背景・目的

{{STORY_PURPOSE}}

> 参考形式: 「**\<role\>** として、**\<goal\>** したい。なぜなら **\<reason\>** だから。」（必須ではない）

## 受け入れ基準（Acceptance Criteria）

- [ ] {{ACCEPTANCE_CRITERIA_1}}
- [ ] {{ACCEPTANCE_CRITERIA_2}}
- [ ] {{ACCEPTANCE_CRITERIA_3}}

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

> Projects フィールドの `Points` と本セクションの `Points` は連動する。`estimate-points` スキルが両方を更新する。

## リスクと対応策

| ID | リスク | 確率 (H/M/L) | 影響 (H/M/L) | スコア (1-9) | 対応策 | P 反映 |
|----|--------|---------------|----------------|----------------|--------|--------|
| R1 | {{RISK_1}} | {{PROB_1}} | {{IMPACT_1}} | {{SCORE_1}} | {{MITIGATION_1}} | {{P_DELTA_1}} |

**最大リスクスコア**: {{MAX_RISK_SCORE}}（Projects フィールド `Risk Score` と連動）
**P 反映合計**: +{{P_REFLECTED_TOTAL}}（リスク識別による悲観値の追加）

## 依存関係

- **前提 Story**: {{DEPENDENCY_ISSUES}} <!-- 例: #123, #145。未定なら「なし」 -->
- **ブロックする Story**: {{BLOCKING_ISSUES}}

## 参考

- 親 Epic README: [/{{OBJECTIVE_ID}}/{{INITIATIVE_ID}}/{{EPIC_ID}}/README.md]({{EPIC_README_LINK}})
- 親 Initiative README: [/{{OBJECTIVE_ID}}/{{INITIATIVE_ID}}/README.md](/{{OBJECTIVE_ID}}/{{INITIATIVE_ID}}/README.md)

---
*Generated / managed by `leadcraft` github mode (compose-stories / estimate-points / identify-risks / sync-stories).*
