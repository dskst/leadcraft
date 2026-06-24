---
name: identify-risks
description: **トラッカーに登録済みの Story**（既定の `local` プロバイダでは Epic 配下のローカル md ＝ OKF concept、`github` プロバイダは opt-in / Phase 2）単位でリスクを識別し、発生確率 × 影響度の 2 軸で評価して、PERT 見積もりの悲観値（P）に反映するスキル。本文の「リスクと対応策」セクションと、`set_field` 経由の `risk_score` フィールド（local では frontmatter の `risks` / `risk_score`、github では Projects の `Risk Score`）を同時に更新し、P 反映時はさらに「見積もり詳細」と `points` フィールドも再計算する。引数で対象（`local` の md ファイルパス / Epic ディレクトリ / `github` の item_ref `#N` / `epic:<id>` ラベル / `all`）を渡せば自動判定する。「リスクを洗い出す」「リスク識別する」「リスクスコアを評価する」「不確実性を見積もりに反映する」「P をリスクで調整する」「ローカル Story のリスクを洗い出す」「md ファイルのリスクを更新する」と言われたら起動する。
argument-hint: "（任意：local の md ファイルパス / Epic ディレクトリ / github の item_ref #N / `epic:<epic-id>` ラベル / `all`。モード指定は --local | --github）"
allowed-tools: Read, Edit, AskUserQuestion, Bash, Glob
---

# identify-risks

**トラッカーに登録済みの Story** 単位でリスクを洗い出し、PERT の悲観値（P）に定量的に反映するスキル。

リスク評価結果は **2 つの場所に同時に書き戻す**（P 反映時はさらに見積もりも再計算する）:

1. **本文の「リスクと対応策」セクション**（人間が読む表）
2. **`set_field(item_ref, "risk_score", <最大スコア>)`** による `risk_score` フィールド（`references/tracker-contract.md` §3 の正規語彙）

トラッカー操作は **抽象契約**（`references/tracker-contract.md`）経由で行う。スキル本文は `get_item` / `set_field` / `update_item` / `list_items` 等の **抽象操作名** で記述し、provider 固有の具体手順（`gh` コマンド・ファイル書き込み等）は各アダプタ（`references/backends/<provider>.md`）に委譲する。

**`risk_score` フィールドの保存先**（`references/tracker-contract.md` §3）:

| provider | `risk_score` の保存先 | `risks[]` の保存先 | P 反映時の `points` / `estimation.*` |
|----------|------------------------|---------------------|---------------------------------------|
| `local`（既定） | frontmatter `risk_score` | frontmatter `risks[]` | frontmatter `points` / `estimation.{p,e,stddev}` |
| `github`（opt-in / Phase 2） | Projects Number フィールド `Risk Score` | 本文「リスクと対応策」のみ | Projects `Points` + 本文「見積もり詳細」 |

local では **frontmatter が source of truth** であり、本文の表は frontmatter と完全に連動させる（`references/backends/local.md` の不変条件）。github はそこからの同期先である。

> **Phase 2 の注記**: `github` プロバイダのアダプタは現時点でスタブ（`references/backends/github.md`）であり、Issue / Projects の具体手順は未移植である。`--github` 指定時、アダプタが未実装の操作については「Phase 2 で提供予定。当面は `local` でリスクを識別し、後日 `sync-stories`（Phase 2）でアップロードする」と案内する（graceful degradation。`references/tracker-contract.md` §5）。`sync-stories`・`review-stories`・hook 連携も **Phase 2 以降に提供予定** であり、本スキルからは存在しない前提で手順を書かない。
> **本スキルと相互参照する `estimate-points` は現在有効** である（本フェーズで提供される）。

Story を local md と github Issue の両方で同時に管理することは想定しない（provider のいずれか一方が正）。`sync-stories`（Phase 2）でアップロード済みの local md は frontmatter に `github_issue` を持つが、リスクの正は引き続き local md 側とする（github 側のリスク詳細は次回の `sync-stories` で同期される設計）。

## リスク評価モデル

### 2 軸評価（発生確率 × 影響度）

各軸を High(3) / Medium(2) / Low(1) で評価し、スコア = 確率 × 影響度（1〜9）を算出する。

| スコア | 区分 | 対応 |
|--------|------|------|
| 6-9 | High | 必ず P に反映、対応策必須 |
| 3-5 | Medium | P に反映、対応策を検討 |
| 1-2 | Low | 記録のみ。P には反映しない（任意） |

### P への反映ルール（フィボナッチ整合）

各リスクのスコアから、P をフィボナッチ数列で何段階上げるかを決定する:

- **High（6-9）**: 1〜2 段階上げる（例: P=5 → 8 または 13）
- **Medium（3-5）**: 0〜1 段階上げる（例: P=5 → 5 または 8）
- **Low（1-2）**: 段階を上げない（記録のみ）

複数リスクがある場合のルール:

1. 最大スコアのリスクで基本段階を決定する
2. High が 3 件以上ある場合はさらに 1 段階追加で上げる
3. 最終 P は必ずフィボナッチ数列の値とする（5, 8, 13, 21, 34, 55, 89）
4. 最終 P が 89 を超える場合は分割を強く推奨する

各段階の確定（1 段階か 2 段階か等）は、リスク内容と元の P の規模感をもとにユーザーに確認する。

## 前提

### 共通

- 対象 Story がトラッカーに登録済み（`compose-stories` / `quick-stories` 経由）
- `tracker.provider` で対象を解決（`local` 既定 / `github` は Phase 2）

### local モード時（既定）

- 対象 Story が `<epic-dir>/<slug>.md`（OKF concept）として書き出し済み
- md ファイルが書き込み可能
- 外部依存ゼロのため全操作が常に成功する（`references/tracker-contract.md` §5）

### github モード時（Phase 2）

- `references/backends/github.md` の前提（`gh` CLI 認証 + `project` スコープ、`tracker.github.*`（owner / project number / `Risk Score` フィールド ID）の設定）を満たすこと
- 未設定・未実装の操作は graceful degradation（アダプタがスキップして警告。`tracker-contract.md` §5）

## 出力モード（provider）の解決

`estimate-points` と同じロジック（`references/tracker-contract.md` §1）:

1. 引数で `--local` / `--github` が指定されていれば、それを採用
2. `.claude/leadcraft.md` の `tracker.provider` が設定されていれば、それを採用
3. どちらも未設定なら、`local`（既定）

引数が常に最優先される。曖昧な場合は引数の形式から provider を推定する（`#<数値>` / `epic:<id>` / `all` は github、`*.md` パス / ディレクトリパスは local）。解決した provider に対応するアダプタの実装で抽象操作を行う。

## 実行手順

### 1. 対象の特定（対象タイプの自動判定）

`estimate-points` のステップ 2 と同じ判定ロジック:

| 引数 | provider / 対象 | 取得操作 |
|------|------------------|----------|
| `*.md` ファイルパス | local（1 件） | `get_item(item_ref)`（local では md を Read し frontmatter + 本文を返す） |
| ディレクトリパス（Epic ディレクトリ） | local（Epic 配下全件） | `list_items({epic: "<epic-id>"})` または `Glob` で `<dir>/*.md` を列挙し `type: story` でフィルタ |
| `#123` / 複数 item_ref | github（個別。**Phase 2**） | `get_item(item_ref)` |
| `epic:<epic-id>` ラベル | github（Epic 配下。**Phase 2**） | `list_items({label: "epic:<id>", status: "story"})` |
| `all` | github（全 story。**Phase 2**） | `list_items({label: "story"})` |
| 引数なし | 対話で確認（local md / Epic ディレクトリ / github の 3 択） | 上記のいずれか |

local の Epic ディレクトリ列挙では、Epic 本人の `README.md` および予約ファイル（`index.md` / `log.md`）を除外する（`references/backends/local.md` の `list_items` 実装に従う）。

対象を確定したら、`get_item(item_ref)` で現在の「リスクと対応策」セクションと既存のリスク状態を把握する:

- **local**: frontmatter の `risks` / `risk_score` と本文を取得する
- **github（Phase 2）**: Issue 本文を取得する

### 2. リスクの洗い出し

各 Story について以下のカテゴリを参考に質問する:

- **技術リスク**: 未経験技術、性能要件、互換性
- **依存リスク**: 外部 API、サードパーティライブラリ、他チーム成果物
- **要件リスク**: 仕様未確定、ステークホルダー間の認識齟齬
- **データリスク**: マイグレーション、データ品質、バックフィル
- **運用リスク**: デプロイ、ロールバック、モニタリング
- **人的リスク**: スキル不足、レビュー待ち、休暇

`AskUserQuestion` で「この Story で気になるリスクはあるか？」と尋ね、回答をリスト化する。プロンプトで上記カテゴリを例示し、思考を促す。

### 3. 各リスクの評価

リスクごとに 2 つの軸を質問する:

- 発生確率: High / Medium / Low
- 影響度: High / Medium / Low

スコア = 確率値 × 影響度値 を計算し、表示する。

### 4. 対応策の記述

各リスクに対して対応策（回避・軽減・移転・受容）を記述させる。特に High リスクは対応策必須とする。

### 5. PERT の P への反映

各リスクのスコアから P 加算ポイントを算出し、合計を出す。ユーザーに「現在の P=\<元の P\>、リスク反映後の P=\<元の P + 加算\> とする。よいか？」を確認する。

参照元（現在の P / 見積もりモード）は provider で異なる:

- **local**: frontmatter の `estimation.p` と `estimation.mode` を読む（こちらが正）
- **github（Phase 2）**: 本文「見積もり詳細」セクションの `悲観値 (P)` と `見積もりモード` を読む

PERT モードでない Story（`estimation.mode` / `見積もりモード` が `simple` の場合）:

- 「単純見積もりにリスクを反映するため、PERT に変更するか？」を提示する
- 受諾: O=Points, M=Points を初期値とし、P のみリスクで段階上げ。モードを `pert` に切り替える
- 拒否: リスクログのみ記載して P には反映しない

### 6. 書き戻し（provider に応じてアダプタへ委譲）

リスク評価結果を **本文の「リスクと対応策」セクション** と **`set_field` 経由の `risk_score` フィールド** の両方へ書き戻す。P を変更した場合はさらに **本文「見積もり詳細」** と **`points` フィールド** も再計算して更新する。これらは連動するため、片方だけ更新するのは禁止（不整合が発生し、`sync-stories`（Phase 2）の整合性チェックが警告を出す）。

#### 6-1. 本文「リスクと対応策」セクションの更新

`get_item(item_ref)` で本文を取得し、「リスクと対応策」セクションを次の表構造（テンプレート `story-local.md` 由来）に書き換える:

```markdown
## リスクと対応策

| ID | リスク | 確率 (H/M/L) | 影響 (H/M/L) | スコア (1-9) | 対応策 | P 反映 |
|----|--------|---------------|----------------|----------------|--------|--------|
| R1 | <内容> | <H/M/L> | <H/M/L> | <1-9> | <対応策> | <+N> |

**最大リスクスコア**: <最大値>
**P 反映合計**: +<合計>
```

provider 別の反映:

- **local**: 対象 md を `Edit` で更新する。これは `update_item(item_ref, {body})` に相当する。local アダプタは `updated_at` / `timestamp` を現在時刻に更新し、Epic 階層の `log.md` に `Update: Story <slug> のリスクを更新` を 1 行追記する（`references/backends/local.md` の `update_item`、`references/okf-conformance.md` §3）
- **github（Phase 2）**: `update_item(item_ref, {body})` で Issue 本文の該当セクションを更新する（github アダプタ。**Phase 2**）

#### 6-2. 本文「見積もり詳細」セクションの更新（P 反映時のみ）

P を変更した場合、「見積もり詳細」セクションの **悲観値 (P)** と **期待値 (E)** / **標準偏差 (σ)** / **Points** を再計算して書き換える:

- E = (O + 4M + P_new) / 6 をフィボナッチに丸めて Points
- σ = (P_new - O) / 6

「見積もり詳細」の他項目（O, M, 見積もりモード, 基準点比較）は触らない。

#### 6-3. `risk_score` フィールドの更新（`set_field`）

```
set_field(item_ref, "risk_score", <最大リスクスコア>)
```

P を変更した場合は合わせて:

```
set_field(item_ref, "points", <再計算後のフィボナッチ Points>)
```

provider 別の保存先（アダプタが振り分ける。`references/tracker-contract.md` §3）:

- **local**: frontmatter の `risk_score` と `risks[]` を `Edit` で更新する（本文「リスクと対応策」と完全に一致させる）。例:

  ```yaml
  # Before
  risk_score: 0
  risks: []

  # After
  risk_score: 6
  risks:
    - id: "R1"
      risk: "外部 API 仕様未確定"
      probability: "M"
      impact: "H"
      score: 6
      mitigation: "プロトタイプで早期検証"
      p_delta: 1
  ```

  P 反映時はさらに frontmatter の `estimation.p` / `estimation.e` / `estimation.stddev` / `points` を更新する（本文「見積もり詳細」と一致させる）。`estimation.mode` / `estimation.o` / `estimation.m` / `estimation.baseline_comparison` は触らない。他のキー（`type` / `status` / `mode` / 階層 ID / `title` / `dependencies` / `tracker_ref` / `github_issue` 等）も触らない

- **github（Phase 2）**: Projects の Number フィールド `Risk Score` に最大スコアを反映する。P 反映で Points も変わった場合は `Points` フィールドも合わせて更新する。Issue が Projects に未追加の場合や `tracker.github.fields.risk_score` 未設定の場合は、アダプタがスキップして警告する（graceful degradation）

### 7. 結果サマリーの表示

- 各 Story のリスクスコアと P 加算（更新前後）・item_ref（local: 書き戻した md の絶対パス / github: Issue URL）
- 対応策が未記入の High リスク（あれば警告）
- 次のステップ案内:
  - `estimate-points`: P を反映した見積もりを再確認・確定する（現在有効）
  - `compose-stories <item_ref>`: High リスク多数の Story を再分解する（現在有効）
  - `sync-stories`: ローカル Story を github トラッカーへアップロードする（**Phase 2**）
  - `build-bundle`: OKF バンドルの `index.md` / `log.md` を補完・検証する

## 注意事項

- **抽象操作で記述する**: 本スキル本文は `get_item` / `set_field` / `update_item` / `list_items` の抽象操作だけを使う（`references/tracker-contract.md` §2）。`gh` 等の具体コマンドを直書きしない。provider 固有手順はアダプタ（`references/backends/<provider>.md`）に委譲する
- **本文「リスクと対応策」と `risk_score` フィールドを必ず両方更新する**（P 反映時はさらに本文「見積もり詳細」と `points` フィールドも）。local では本文表と frontmatter の連動を保たないと `sync-stories`（Phase 2）のアップロード時に整合性チェックが警告を出す（`references/backends/local.md` の不変条件）
- **OKF 準拠**: local の Story md は更新後も OKF concept として `references/okf-conformance.md` §2 を満たす。更新時は Epic 階層の `log.md` に `Update` 行を追記する（§3）。`index.md` の更新は `build-bundle` の責務（本スキルは触らない）
- リスクは「あるか / ないか」ではなく「どの程度か」で評価する
- 0 件の Story も記録する（「リスクなしと判断」も明示的な情報）。`risk_score` = 0 を明示的にセットすることで「未評価」と区別できる
- High リスクが 3 件以上の Story は分割を検討するよう促す
- ユーザーが思いつかない場合、過去の同種 Story や一般的な落とし穴を提案する
- 本文の書き換えは「リスクと対応策」と「見積もり詳細」（P 反映時のみ）のみ。他のセクション（背景・受け入れ基準・タスク・依存関係・DoD・参考）を破壊しない
- local の frontmatter 書き換えは `risks` / `risk_score`（および P 反映時の `estimation.*` / `points`）のみ。他のキーは触らない
- Epic README の「リスクサマリー」は本スキルで触らない（Story 単位のリスクは `risk_score` フィールドで集計する。Epic スコープのリスクは Epic README に手動で記録する設計）
- **github（Phase 2）の注意**: `sync-stories`（Phase 2）でアップロード済みの local md（frontmatter に `github_issue` を持つ）を local モードでリスク識別しても、本スキルは github Issue 側を直接更新しない。次回 `sync-stories` で同期される設計。ユーザーに「github 側も同期する場合は `/sync-stories <md-path>` を実行してほしい（Phase 2）」と案内する。github Projects への反映・`project` スコープ要件・フィールド ID 解決は github アダプタの責務（`references/backends/github.md`、**Phase 2**）
