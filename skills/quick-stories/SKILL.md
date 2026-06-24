---
name: quick-stories
description: 既存 Epic 配下に Story を **1 件以上、対話最小限・最短手数でトラッカーへ作業項目としてまとめて登録する** 簡易版スキル。`compose-stories` の詳細設計（タスク / 見積もり / リスク / 依存関係）を意図的に省き、**タイトル・1〜2 行の概要・受け入れ基準 2〜4 項目** だけで Story を生成する。複数件の Story 候補（箇条書きで列挙されたもの等）を一度に渡されたら、各 Story を順に登録する。出力先は `tracker.provider` 設定または `--local` / `--github` 引数で切り替える。既定の `local` プロバイダでは `<epic-dir>/<story-slug>.md`（OKF concept。frontmatter の `mode: quick`）を生成し、`github`（opt-in）では `quick` ラベル付き Issue を作成する。「とりあえず叩き台として項目だけ立てたい」「思いついた要件を忘れないうちに残したい」「打ち合わせ中に話に出た Story をその場で起票したい」「素早く項目を作って」「サクッと Story を切る」「あとで詳細詰めるけど一旦記録だけ」「Story 候補をまとめて登録」「叩き台でいくつか起票」「簡易作成」「ライトな項目を複数作る」「ローカルに叩き台 Story を素早く作る」「オフラインで Story 候補を一気にメモする」と言われたら起動する。**Epic がすでに存在することが前提**（無ければ `compose-epic` を案内して中止する）。`compose-stories` との使い分け: 設計の手応えが必要な Story は `compose-stories`、まずは記録だけ残したい Story 群は本スキル。
argument-hint: "（任意：親 Epic README のパス / Epic ID。モード指定は --local | --github）"
allowed-tools: Read, Write, Glob, Grep, AskUserQuestion, Bash
---

# quick-stories

Story を **1 件以上、最短手数でトラッカーへ登録** するための簡易版スキル。`compose-stories` の完全版とは目的が異なる:

- `compose-stories`: 受け入れ基準・タスク・依存・見積もり・リスクまで設計し切ってから登録する（時間をかけて作り込む）
- `quick-stories`（本スキル）: タイトルと概要と AC だけで登録し、後から肉付けする運用を許容する（叩き台を素早く残す）

トラッカー操作は **抽象契約**（`references/tracker-contract.md`）経由で行う。スキル本文は `create_item` / `set_field` / `add_label` / `ensure_label` 等の **抽象操作名** で記述し、provider 固有の具体手順は各アダプタ（`references/backends/<provider>.md`）に委譲する。

「打ち合わせ中に出た Story 群」「忘れないうちに残したい思いつき」「あとで詳細を詰める前提の項目」を扱うのに向いている。`compose-stories` の対話量がオーバーキルに感じる場面で使う。

入力形式: 1 件だけの Story でも複数件の列挙でも受け付ける。箇条書きで複数 Story 候補が渡された場合は、各 Story について順に最小情報を確定して登録する。

> **github プロバイダについて**: `github` プロバイダのアダプタ（`references/backends/github.md`）は実装済みであり、`--github` 指定時は `quick` ラベル付き Issue 作成・Projects 連携を実行できる（未設定の項目は graceful degradation でスキップ・警告する）。`compose-stories` で詳細化したあとの `review-stories`、hook 連携（`notify-draft-added.sh`）、`sync-stories` もすべて現行スキル / hook として提供済みであり、本スキルからは現行のものとして参照してよい。

## 想定する利用シーン

- スプリント計画中・打ち合わせ中に Story の存在だけ確定させたい
- バックログを早く積み上げたい（詳細は後で詰める前提）
- 簡単な要件メモを項目化して関係者に共有したい
- Epic 直後のブレインストーミングで Story 候補を一気に登録したい
- 朝会で「これ Story 化しておこう」となった瞬間にその場で立てる

「Story を一件一件丁寧に詰める」モードに入る必要があるなら `compose-stories` を案内する。

## 出力

### local モード（既定）

| 項目 | 値 |
|------|----|
| Story 項目 | `create_item` でトラッカーに作成。local アダプタは `<epic-dir>/<story-slug>.md` を生成。本文は 3 セクション（階層 / 背景・目的 / 受け入れ基準）のみ |
| テンプレート | `${CLAUDE_PLUGIN_ROOT}/skills/compose-stories/templates/story-local.md` を共有利用（quick モードでは タスク / 見積もり詳細 / リスクと対応策 / 依存関係 / DoD セクションを **省略**） |
| frontmatter | OKF 必須 `type: story` + `description`（1 文要約）+ `tags`（labels をミラー）+ `timestamp` + `resource: null` + `tracker_ref`（自身のバンドル絶対パス）。leadcraft 拡張 `status: draft` / `mode: quick` / 階層 ID / `points: 0` / `risk_score: 0` |
| ラベル | `story` + `quick`（簡易作成マーカー）を `add_label`。`epic:<epic-id>` も `add_label` |
| 階層フィールド | `set_field` で `objective` / `initiative` / `epic` をセット。`points` / `risk_score` は 0 |
| DoD | **付与しない**（速度優先） |
| log.md | Epic 階層の `log.md` に `Creation: Story <slug> を作成` を追記（OKF 規約 §3） |

### github モード（opt-in）

| 項目 | 値 |
|------|----|
| Story 項目 | `create_item` で GitHub Issue を作成（本文 3 セクションのみ） |
| ラベル | `story` + `epic:<epic-id>` + `quick` を `add_label` |
| 階層フィールド | `set_field` で Projects フィールドに反映。`points` / `risk_score` は 0 |
| DoD | **付与しない**（速度優先） |

> **ID 規約について**: 本スキルが付与する `epic:<epic-id>` ラベルおよび階層フィールド `objective` / `initiative` / `epic` の値は、すべて **親 Epic README の YAML frontmatter（`id` / `initiative` / `objective`）からそのまま** Read して使う。親 Objective に `id_suffix` が設定されていれば、Initiative / Epic 側の `id` は `<base>-<suffix>` 形式（例: `oauth-login-a1b2c`）になっており、本スキルから見ると suffix の有無は透過で扱える。

## 前提

### 共通

- **親 Epic が既存** であること（Epic README が `<root>/<objective>/<initiative>/<epic>/README.md` に存在する）
- `.claude/leadcraft.md` が設定済み

Epic が無い場合は本スキルでは続行しない。`compose-epic` の利用を案内して終了する（簡易スキルなので「Epic は後で整える」のフォールバックを持たない。曖昧な親階層で登録すると後の整理コストが増えるため）。

### local モード時（既定）

- Epic ディレクトリへの書き込み権限
- 既存 Story md と slug が衝突しないこと（衝突時はアダプタが `-2`, `-3` を自動付与）
- 外部依存ゼロのため全操作が常に成功する（`references/tracker-contract.md` §5）

### github モード時

- `references/backends/github.md` の前提を満たすこと
- 未設定の操作は graceful degradation（アダプタがスキップして警告）

## 出力モード（provider）の解決

ステップ実行の最初に provider を以下の優先順位で解決する（`compose-stories` と同じロジック。`references/tracker-contract.md` §1）:

1. 引数で `--local` / `--github` が指定されていれば、それを採用
2. `.claude/leadcraft.md` の `tracker.provider` が設定されていれば、それを採用
3. どちらも未設定なら、`local`（既定）

解決した provider に対応するアダプタ（`references/backends/<provider>.md`）の実装で抽象操作を行う。

## ラベルとライフサイクル

`quick` ラベルは「叩き台として起票された Story」を示す。`draft` とは別系統で運用する:

| ラベル | 意図 | 解除タイミング |
|--------|------|----------------|
| `quick` | 簡易作成された Story。詳細は未記入 | `compose-stories <item_ref>` で肉付けする際に `quick` を外して `draft` を付与（または `quick` のまま完成扱いにすることも可） |
| `draft` | 詳細記入済みだが品質ゲート未通過 | `review-stories` でレビュー通過時に削除 |

**標準的な昇格パス**:

```
quick-stories 登録 → quick ラベル付き
  ↓ （詳細を詰めたくなったら）
compose-stories <item_ref> で肉付け → quick を draft に置き換え
  ↓
review-stories でレビュー → draft 削除（卒業）
```

ただし「quick で登録したまま計画に組み込む」運用も許容する。チームの好み次第。

> **hook との関係**: プラグイン同梱の `notify-draft-added.sh` は `draft` ラベル付与のみを検知する設計であり、`quick` ラベル付与では反応しない（叩き台に見積もりを強制しないため）。したがって本スキルで起票した quick Story では hook は発火せず、`compose-stories` で肉付けして `draft` に昇格した時点で遷移が促される。

## 実行手順

### 1. 親 Epic の特定

引数または対話で次のいずれかを取得する:

- 親 Epic README の絶対 / 相対パス（推奨。例: `<root>/<objective>/<initiative>/<epic>/README.md`）
- Epic ID（`Glob` で `<root>/*/*/*/README.md` を列挙して ID マッチ）

引数が空なら `AskUserQuestion` で「既存 Epic 一覧から選ぶ」を提示する。

Epic README が見つからない / 指定されない場合は **本スキルを中止し、`compose-epic` の実行を案内する**。簡易スキルの設計上、曖昧な親階層では登録しない。

Epic README を `Read` し、以下を取得する:

- `objective` / `initiative` / `epic` ID（frontmatter）
- Epic タイトル（本文の H1 または `title` frontmatter）

### 2. 設定読み込み

`.claude/leadcraft.md` から以下を読み込む:

- `tracker.provider`（および `tracker.github.*`。github プロバイダ時のみ）
- `output.root_dir`
- `issue.default_labels`（既定 `["story"]`）

provider 固有の前提チェックはアダプタに委ねる（local は追加チェック不要、github は未設定操作を graceful degradation でスキップ）。

### 3. Story 候補の抽出と件数の確定

入力（引数のチャット / 直前の会話 / ファイル）から **Story 候補を抽出** する。次のいずれかのパターンを想定:

- **単一 Story**: 1 つの要件文 → 1 件登録
- **箇条書き / リスト**: 「- X したい」「- Y を追加したい」「- Z を直したい」のような複数行 → 各行を 1 件として複数登録
- **段落形式**: 1 つの段落に複数のアイデアが詰まっている → Claude が分割案を提示し、ユーザーに確認

候補リストを内部表現にしたら、以下を **1 回の `AskUserQuestion`** でまとめて確認する（往復回数削減が速度の核）:

- 抽出した候補リスト（仮タイトル一覧）でよいか
- マージ / 分割 / 削除したいものはあるか
- 何件登録するか（全件 / 一部選択）

候補が 1 件なら確認をスキップして次のステップへ。

### 4. 各 Story の最小情報を確定

確定した候補それぞれについて、以下を埋める。**Claude が Epic README の文脈から第一案を作り、ユーザーは差分だけ指摘する** のが速度を出すコツ。

#### 4-1. タイトル（必須）

- 日本語可。1 行で Story の提供価値を表す
- 引数や直前のチャットから読み取れる場合は質問しない

#### 4-2. 背景・目的（必須、1〜2 行）

- なぜこの Story が必要か / 何を実現したいかを 1〜2 行で
- ユーザーストーリー形式（"\<role\> として、\<goal\> したい"）は推奨だが必須ではない

#### 4-3. 受け入れ基準（必須、2〜4 項目）

- チェックリスト形式
- 外部から観測できる振る舞いで書く
- 入力が薄ければ Claude が Epic README の文脈から 2〜3 件提案 → ユーザーが採否を判断

これら以外（タスク / 見積もり / リスク / 依存）は **本スキルでは扱わない**。本気で必要なら `compose-stories` を勧める。

#### 4-4. 複数件処理時の対話設計

3 件以上を一度に登録する場合は、対話の往復を以下のように圧縮する:

- 全件の仮タイトル + 各候補ごとの「背景 1 行 + AC 案 2〜3 件」を **一度にまとめて提示**
- ユーザーは「全件 OK」「個別に修正」「特定件だけ修正」のいずれかで応答
- 個別修正が必要なものだけを `AskUserQuestion` でフォローアップ

「1 件ずつ詳細を詰める」モードに入ったら、それはもう `quick-stories` の役割ではない。`compose-stories` を案内する。

### 5. Story 本文の組み立て

各 Story について、`${CLAUDE_PLUGIN_ROOT}/skills/compose-stories/templates/story-local.md` を `Read` し、**quick モード向けに簡略化**して本文を組み立てる。

quick モードでの簡略化ルール:

- **frontmatter（OKF + 拡張）**:
  - `type: story`（OKF 必須）/ `title` / `description`（1 文要約。OKF 推奨。必ず埋める）
  - `tags: ["story", "quick"]`（labels をミラー）
  - `timestamp`: 現在時刻（ISO 8601）/ `resource: null` / `tracker_ref`: 自身の item_ref（アダプタが書き込む）
  - `status: draft` / `mode: quick`（`composed` ではない）
  - 階層 ID（`objective_id` / `initiative_id` / `epic_id`）は Epic README から転記
  - `labels: ["story", "quick"]`（`draft` ではない）
  - その他は composed と同じ初期値（`points: 0` / `risk_score: 0` / `risks: []` 等）
- **本文**:
  - 残す: H1 タイトル / `## 階層` / `## 背景・目的` / `## 受け入れ基準（Acceptance Criteria）`
  - **省略**: `## タスク` / `## 見積もり詳細` / `## リスクと対応策` / `## 依存関係` / `## Definition of Done` / `## 参考`
  - `## 階層` セクションでは Epic README へのリンクを **バンドル絶対パス**（`/{{OBJECTIVE_ID}}/{{INITIATIVE_ID}}/{{EPIC_ID}}/README.md`）で書く（OKF クロスリンク規約 §4）
  - 「階層」セクションの直後に、quick 起票である旨のコールアウトを 1 つ入れる:
    ```markdown
    > 本項目は `quick-stories` で簡易作成された。詳細（タスク / 見積もり / リスク / 依存）は未記入。
    > 詳細を詰める場合は `/compose-stories <本項目の item_ref>` を実行する。
    ```
  - 末尾フッターは quick モードであることを明示するものに差し替える:
    ```markdown
    ---
    *Generated by `quick-stories`. 詳細を詰める場合は `/compose-stories <本項目の item_ref>` を実行する。*
    ```

github モードでも本文構造は同一（frontmatter は付けず、本文 3 セクション + コールアウト）。テンプレートファイルは持たず、本スキル内の構造定義で完結させる（簡易さを最優先）。

### 6. トラッカーへの登録（抽象操作・候補ごとにループ）

確定した Story 候補それぞれについて、provider に応じたアダプタ（`references/backends/<provider>.md`）の実装で以下の抽象操作を順に実行する。複数件登録時は 1 件成功するごとに次へ進む（途中失敗時は失敗した件だけ結果サマリーに残し、残りの登録は続行する。速度優先のためリトライは個別に手動で行う方が単純）。

1. **`ensure_label`**: `story` / `quick` / `epic:<epic-id>` の存在を保証する。
   - local アダプタでは no-op（ラベルは frontmatter の文字列）
   - github アダプタでは `quick` ラベル未存在時にユーザー確認のうえ作成（淡い青系 `C5DEF5` を推奨。`draft` の黄色・`epic:*` の濃い青と視覚的に区別）。`epic:<epic-id>` も同様
2. **`create_item(title, body, "story", ["story", "quick"])`**: ステップ 5 の本文で Story 項目を作成。戻り値は item_ref。local アダプタはこのとき Story md を生成し、`tracker_ref` を書き込み、Epic の `log.md` に `Creation` 行を追記する
3. **`add_label(item_ref, "epic:<epic-id>")`**: Epic 絞り込みタグを付与
4. **`set_field`**: 階層フィールドと初期メトリクスをセット（`tracker-contract.md` §3）:
   - `set_field(item_ref, "objective", <objective-id>)`
   - `set_field(item_ref, "initiative", <initiative-id>)`
   - `set_field(item_ref, "epic", <epic-id>)`
   - `set_field(item_ref, "points", 0)`（簡易作成なので未見積もり）
   - `set_field(item_ref, "risk_score", 0)`（簡易作成なのでリスク未識別）
   - 未設定のフィールドはアダプタがスキップする（graceful degradation）

DoD フォローコメント（`add_comment`）は **付与しない**（速度優先。理由は後述）。

複数 Story を一括処理する場合、Epic は最初に 1 度だけ確認すれば以降は引き継ぐ（往復回数を減らすため）。local モードで slug が必要な場合、slug 候補生成 → ユーザー確認は **複数 Story 分まとめて 1 回の `AskUserQuestion`** で済ませる（個別確認しない）。slug 生成・衝突回避（`-2` / `-3` 付与）は local アダプタの `create_item` が担う（`references/backends/local.md`）。

### 9. 結果サマリー

- 登録成功: 各 Story のタイトル / item_ref（local: 書き出し先の絶対パス / github: Issue URL）/ provider / セットしたフィールド一覧
- 登録失敗: 各失敗ごとにエラー内容と次のアクション
- 複数件登録時は **件数集計**（例: 「5 件のうち 4 件登録成功、1 件失敗」）も併記

次のアクション候補:

- 別の Story も簡易作成: 本スキル再実行
- 詳細を詰めたい: `/compose-stories <item_ref>`（既存項目の肉付けフロー）
- 簡易作成した項目を後で一覧: `list_items({label: "quick"})`
- GitHub に上げる: `sync-stories`
- OKF バンドルの目次・履歴を整える: `build-bundle`

## DoD コメントを付与しない理由

`compose-stories` は項目作成直後に DoD を `add_comment` で付与するが、本スキルでは省略する。理由:

- 速度優先の設計に追加ステップは合わない
- 叩き台 Story の段階では「完了基準」を意識する場面が薄い
- 後から `compose-stories <item_ref>` で肉付けする際に同じ仕組みで DoD を付与できる

DoD をどうしても付けたい場合は `compose-stories <item_ref>` で肉付けに進む。

## 注意事項

- **抽象操作で記述する**: 本スキル本文は `create_item` / `set_field` / `add_label` / `ensure_label` 等の抽象操作だけを使う（`references/tracker-contract.md` §2）。`gh` 等の具体コマンドを直書きしない。provider 固有手順はアダプタに委譲する
- **provider 別の出力先**:
  - local（既定）: `<epic-dir>/<story-slug>.md`（OKF concept）のみ生成
  - github: GitHub Issue のみ
- **OKF 準拠**: local の Story md は OKF concept として `references/okf-conformance.md` §2 を満たす（パース可能な frontmatter + 非空 `type` + `description`）。内部リンクは **バンドル絶対パス**（§4）。Story 作成時は Epic 階層の `log.md` に `Creation` 行を追記（§3）。`index.md` は `build-bundle` の責務
- 本スキルは **Story 登録のみ** を扱う。Epic / Initiative / Objective の作成・更新には踏み込まない
- **Epic 必須**。Epic README が無ければ本スキルを中止し `compose-epic` を案内する（曖昧な親階層を許容しない）
- 受け入れ基準が 0 件で登録するのは禁止 → 最低 1 件はユーザーから引き出すか、Claude が Epic 文脈から提案する
- **タスク / 見積もり / リスク / 依存関係は本スキルで埋めない**。空欄で出力するのではなく、本文に該当セクションを「持たない」設計（後から `compose-stories` で肉付けする際にセクションが追加される）
- ラベルが存在しない場合の扱いはアダプタに委ねる（local は no-op、github は作成可否をユーザー確認）
- 既存項目の更新には本スキルを使わない。詳細を詰めたい場合は `compose-stories <item_ref>` を使う
- 複数件を一括出力する際、**1 件の失敗で全体を中止しない**。失敗した件だけ結果サマリーに残し、残りの出力は続行する
- 複数件出力で順序が重要な依存関係がある Story 群を含む場合、本スキルでは依存リンクを張らない。`compose-stories` で個別に肉付けする際に依存セクションを追加する

### local モード固有の注意

- **ファイル名 slug は kebab-case 英数字のみ**。複数件登録時は slug 候補生成 → 確認を 1 回でまとめて済ませる（速度優先）。slug 生成・衝突回避は local アダプタの `create_item` が担う
- **既存 md と slug が衝突する場合は自動的に `-2` / `-3` を付与**。既存 md を上書きしない
- **frontmatter の `mode: quick`**。`compose-stories` でローカル肉付けする際に `mode: composed` に切り替え、`labels` / `tags` の `quick` も `draft` に置き換える
- **DoD は付与しない**（速度優先）。`sync-stories` で github 化する際も DoD コメント付与はスキップする
- **`tracker_ref` は local アダプタが書き込む**（自身のバンドル絶対パス）。`github_issue` / `uploaded_at` は本スキルでは触らない（`sync-stories` が github 同期時に書き戻す）
