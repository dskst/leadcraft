---
name: compose-initiative
description: Objective 配下に置く Initiative（Objective を実現するための大きな取り組み）を 1 件、対話を通じて整え、プラグイン同梱の `initiative.md` テンプレートから `<root>/<objective>/<initiative>/README.md` として生成・更新する。インセプションデッキ 10 の問い（なぜここにいるのか / エレベーターピッチ / やらないことリスト / ご近所さん / 解決策 / 夜も眠れない問題 / 期間 / 諦めること / 必要なリソース 等）を丁寧に詰めることに集中する。「Initiative を作る」「Initiative を立ち上げる」「Initiative README を書く」「インセプションデッキを書く」「取り組みを言語化する」「Objective を Initiative に分解する」「エレベーターピッチを整える」「やらないことリストを作る」「Initiative を見直す」「Initiative を更新する」と言われたら起動する。Objective を整えたい場合は `compose-objective`、配下の Epic を整えたい場合は `compose-epic` を案内する。
argument-hint: "（任意：Initiative の概要メモ md パス、ID 候補、URL、親 Objective ID）"
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion, Bash
---

# compose-initiative

5 階層（Objective > Initiative > Epic > Story > Task）における **Initiative** を 1 件、丁寧に作り込むための専用スキル。

Objective が「達成したい状態（What / Why）」を語る場であるのに対して、Initiative は「**どう取り組むか**（How）」を関係者で合意するための場である。具体的には、**インセプションデッキ 10 の問い** に対する答えをこの README に集約する。Epic や Story では繰り返さず、Initiative README を一次情報源（Single Source of Truth）として扱う方針を取る。

Objective の更新には `compose-objective`、配下の Epic を整えたい場合は `compose-epic` を案内する。Initiative はトラッカー項目を持たない（README のみで管理する）。

## 想定する利用シーン

- 親 Objective は決まっており、配下に新しい Initiative を立ち上げたい（キックオフ用ドラフトを作る）
- インセプションデッキを 1 から組むので、対話で各問いを順番に深掘りしてほしい
- 既存 Initiative の「やらないことリスト」「夜も眠れない問題」「諦めること」が薄くなっており、現状に合わせて見直したい
- 関連 Epic が複数走り始めて Initiative README が古くなっているので、現状の Epic 一覧やマイルストーンを更新したい
- 旧形式の単一 md（インセプションデッキだけ書かれた `docs/inception/<initiative>.md` 等）を新形式の Initiative README に移行したい

## 出力

| 項目 | 値 |
|------|----|
| ファイル | `<root>/<objective>/<initiative>/README.md` |
| 雛形 | `${CLAUDE_PLUGIN_ROOT}/skills/compose-initiative/templates/initiative.md` |
| `<root>` | 設定ファイル `.claude/leadcraft.md` の `output.root_dir`（既定 `docs/objectives`、未設定時は compose-objective が対話で確定） |
| 既存ファイル | 上書きせず、差分提案 → ユーザー承認後に `Edit` で部分更新 |

恒久 Initiative（hotfix の受け皿となる `maintenance` 等）を扱う場合も本スキルで編集する。新規作成と更新の判定はユーザーに確認する。

## 実行手順

### 1. 入力ソースの特定

引数または対話で以下のいずれかを取得する。引数が空ならまず `AskUserQuestion` で選択肢を提示する。

- チャットに書かれた Initiative の概要テキスト
- Markdown / メモ ファイルパス（`Read`）
- 親 Objective README のパス（`<root>/<objective>/README.md`）
- トラッカー Issue / Discussion URL（`Bash` でトラッカー抽象操作 `get_item` を使うか、または `WebFetch`）
- 戦略資料・キックオフ資料 URL（`WebFetch`）
- 「ゼロから対話で組み立てる」（入力なし）

Notion ページが渡された場合は、現セッションで利用可能な MCP ツール（`mcp__*__notion-fetch` 等）を動的に検出し、あれば呼び出す。無ければ `WebFetch` に切り替える。

### 2. 親 Objective の特定

Initiative は必ず Objective の下にぶら下がる。先に親 Objective を確定する。

`Glob` で次の構造を列挙して候補を提示する。

```
<root>/*/README.md       # 既存 Objective
<root>/*/*/README.md     # 既存 Initiative（重複防止のため確認）
```

`AskUserQuestion` で次を確認する。

- どの Objective の下に Initiative を置くか（既存から選択 / 新規）
- Objective README（`<root>/<objective>/README.md`）が存在するか

存在しない上位階層がある場合の方針:

- **Objective README が無い**: 「Objective を先に整えるのが望ましい」と案内し、`compose-objective` の利用を提案する。それでも続行する場合は、Initiative フロントマターの `objective` には予定 ID を入れ、メモ欄に「親 Objective README 未作成」を TODO として残す
- **Objective README はあるが「関連 Initiative」表に未掲載**: ステップ 8 で親 Objective README の表を更新するための作業対象としてマーク

新規作成の入力が薄い場合、親 Objective README の本文・KPI を `Read` で読み、その内容を踏まえて Initiative の方向性をユーザーに確認する（例: 「親 Objective の KPI ①にどう寄与する Initiative か」）。Initiative は **親 Objective の KPI のどれに寄与するか** を明確にしておくと、後続の Epic / Story の優先度判断がぶれない。

### 3. 既存 Initiative の確認とモード判定

ステップ 2 で決めた親 Objective 配下の既存 Initiative を `Glob` で列挙する。

```
<root>/<objective>/*/README.md
```

ユーザー入力と突き合わせ、`AskUserQuestion` で次の 3 択を確認する。

- **新規作成**: 新しいディレクトリと README を作る
- **既存を更新**: 既存 README を読み込み、インセプションデッキ・関連 Epic・マイルストーン等の不足項目を埋める／見直す
- **既存を置き換え**: 互換性が無い大改訂（バックアップ提案を行ったうえで承認を得る）

更新モードでは、現状の README を `Read` で読み込み、フロントマター・各見出し配下のテキストを保持したうえで差分提案する。**全体上書きはしない**。

### 4. Initiative ID とタイトルの確定

新規作成の場合は次を確定する。決められなければ `AskUserQuestion` で確認する。

- **base_id（ベース ID）**: kebab-case の英小文字。例: `framework-modernization`, `frontend-backend-decoupling`, `maintenance`
- **ID（フロントマター・ディレクトリ名に用いる正式 ID）**: 親 Objective YAML の `id_suffix` を末尾に付けた `<base_id>-<id_suffix>` 形式（suffix 未設定なら `<base_id>` のまま）。例: 親 Objective の `id_suffix: "a1b2c"` なら `framework-modernization-a1b2c`
- **タイトル**: 日本語可。取り組みの内容を端的に。例: 「フレームワーク刷新（自動変換 + 追加改修）」「フロント／基幹分離と EOL 依存解消」
- **オーナー（推進責任者）**: 推進責任者の氏名 or ロール
- **target_date**: 完了目標時期（`YYYY-Q?` か `YYYY-MM` 推奨）

ID の候補が思いつかない場合は、タイトルから base_id を 2〜3 案提示してユーザーに選ばせる。

#### 4-1. 親 Objective から id_suffix を継承する

親 Objective README（`<root>/<objective>/README.md`）を `Read` し、YAML フロントマターの `id_suffix` を取得する:

- **`id_suffix` が設定されている**（例: `a1b2c`）: Initiative の正式 ID を `<base_id>-<id_suffix>` で組み立てる（例: `framework-modernization-a1b2c`）。ディレクトリ名・YAML `id` フィールド・親 Objective README の「関連 Initiative」表のリンクすべてにこの正式 ID を使う
- **`id_suffix` が未設定 or 空文字**（後方互換 / 旧 Objective）: `base_id` をそのまま正式 ID として使う（従来動作）。ただし「スコープ衝突回避のため `compose-objective` で id_suffix を追加することを推奨」とユーザーに案内する
- **親 Objective README が存在しない**: 先に `compose-objective` で作成することを案内（既存案内ステップに合流）

確認: 親 Objective 配下に同名の正式 ID が無いことを `Glob` で確認する（`<root>/<objective>/<full-id>/README.md`）。

> `base_id` は **フロントマターに保存しない**。理由: ID は単一の真実値として `id` フィールドに集約し、suffix の有無で経路分岐するロジックを下流スキルに作らせないため。`id` から `id_suffix` を末尾削除すれば base_id は機械的に復元できる（必要なら親 Objective の id_suffix と突き合わせる）。

### 5. Initiative 本文の項目埋め（インセプションデッキ中心）

`${CLAUDE_PLUGIN_ROOT}/skills/compose-initiative/templates/initiative.md` の構成を骨格として、以下を埋めにいく。判明している範囲で書き、不明部分は `<!-- TODO: ... -->` で明示する。

Initiative の本体価値は **インセプションデッキ 10 の問い** にあるため、各問いを丁寧に対話で深掘りする。1 つの問いに対して回答が薄い場合、すぐ次に進まず、`AskUserQuestion` で 1〜2 段深く確認するのが望ましい。

#### 5-1. 概要 / 目的・期待される成果

- **概要**: この Initiative の取り組み全体像（3〜5 行）
- **目的・期待される成果**: ユーザー価値 / 事業価値、および親 Objective の **どの KPI に、どう寄与するか** を明示する

親 Objective の KPI 表と紐づけて記述する。Initiative 単体での成果指標を別途持たせたい場合はここで宣言する（KPI が増えるほど追跡コストが上がるため、無理に増やさなくてよい）。

#### 5-2. インセプションデッキ 10 の問い

順番は重要ではないが、入力の濃淡を見て **手薄な問いから深掘り** していくと対話の密度が上がる。

1. **なぜここにいるのか**: この Initiative に取り組む本質的な理由・ミッション。親 Objective の課題提起と一貫しているか確認する
2. **エレベーターピッチ**: 「対象 / 問題 / 取り組み名 / カテゴリ / 競合・代替案との違い」を 5 行以内で。30 秒で説明できる粒度を目指す
3. **パッケージデザイン**: リリース時のキャッチコピー、社内外への訴求ポイント。社外公開しない Initiative では「社内向けの一言で言うと？」に置き換えてもよい
4. **やらないことリスト**: 明示的にスコープ外とする事項。最低 3 件は出すよう促す。曖昧な「やらないこと」はステークホルダーの認識ズレを生むので具体的に書く
5. **ご近所さんを探せ**: 関係者・推進責任者・依存する他チーム・他システム・外部ベンダー等。氏名や組織名まで踏み込めるとよい（**Initiative のステークホルダー情報の一次情報源**。本 README で独立した「ステークホルダー」セクションは持たない）
6. **解決策を描く**: 採用するアプローチ / 技術スタック / 大まかな実装方針。詳細設計は Epic / Story の責務なので、**Initiative では選択肢の比較と決定理由まで** で止める
7. **夜も眠れない問題**: 主要リスク。詳細は本文末尾の「リスクと留意点」表に展開する（ここでは概観のみ）
8. **期間を見極める**: 想定期間と主要マイルストーン。詳細は「マイルストーン」セクションに展開する
9. **何を諦めるのか**: トレードオフ（スコープ・期日・予算・品質の優先順位）。これが書けない場合、Initiative の優先度設計ができていないサイン
10. **何がどれだけ必要なのか**: 必要なリソース（人員・コスト・外部依存・期間）。概算でよいが、複数桁の精度差は明記する（例: 「3〜4.5 人月」など範囲表記）

各問いについて、入力が薄い場合の深掘り例:

- 4（やらないこと）が空 → 「逆に何を含むかは決まっている？それと混同しがちなものは？」
- 7（リスク）が一般論 → 「最悪のシナリオはどんな失敗？それが起きると誰が何を失う？」
- 9（諦めるもの）が「何も諦めない」 → 「スコープ・期日・品質・予算の 4 つで、最も妥協できないのはどれ？逆に最初に削るのはどれ？」

#### 5-3. 関連 Epic

現時点で予定／走っている Epic を列挙する。**未確定なら空表＋「Epic はこれから整える」旨を記載** する。

ステップ 8 でリンク整合性を確認する際、各 Epic README の有無を `Glob` でチェックして、不在ならば `<!-- TODO: Epic README 未作成 -->` を併記する。

#### 5-4. マイルストーン / 依存関係

- **マイルストーン**: 着手 / MVP / 中間成果 / 完了の 3〜4 ポイント
- **依存関係**: 前提となる他 Initiative / Epic、本 Initiative がブロックするもの

「夜も眠れない問題」や「何を諦めるのか」と整合が取れているかを軽く確認する（期日が厳しいなら品質を諦める覚悟がある等）。

#### 5-5. リスクと留意点

`identify-risks` が Story 単位のリスクを後で詰めることを想定し、ここでは **Initiative レベルの戦略的リスク** のみ書く。表の形式（`ID / リスク / 影響 / 対応方針`）は維持する。初期は 1〜3 行で十分。

#### 5-6. 参考資料 / メモ

- **参考資料**: 戦略資料・キックオフ議事録・Notion / SharePoint URL
- **メモ**: 補足、決定事項、検討中事項

ステークホルダー情報（推進責任者・協力部署・関係者）は **インセプションデッキ「ご近所さんを探せ」（5-2 の 5）に集約** する。独立した節は持たない。

### 6. YAML フロントマターの設定

雛形のフロントマターを次のルールで初期化／更新する。

- `type: initiative`（固定）
- `id`: ステップ 4 で組み立てた正式 ID（親 Objective の `id_suffix` を末尾に付けた `<base_id>-<id_suffix>`、suffix 未設定なら `<base_id>` のまま）
- `title`: ステップ 4 で決めたタイトル
- `description`: **OKF 推奨。1 文の要約**（`index.md` の progressive disclosure と AI 関連度判定の土台になる）。`AskUserQuestion` で確認するか、タイトル・概要から自動生成して提案する
- `tags`: 横断検索用タグ（任意。関連チーム名・領域名等）
- `resource`: Initiative の基礎資産 URI（Epic 一覧フィルタ URL 等）。無ければ `null`
- `timestamp`: `updated_at` と同値の ISO 8601 文字列（OKF 標準キー）
- `objective`: ステップ 2 で確定した親 Objective ID（kebab-case。親 Objective の `id` フィールドをそのまま使う。Objective 自体は suffix を付けない設計）
- `status`: 新規は `planning`。更新時はユーザー確認のうえ `planning | in_progress | done | cancelled` から選択
- `created_at`: 新規時のみ実行日（`Bash` で `date -u +%FT%TZ`）
- `updated_at`: 常に実行日で上書き
- `owner`: ステップ 4 で取得
- `target_date`: ステップ 4 で取得（未確定なら空）
- `epic_count`: 関連 Epic の現存数（README が実在するもののみカウント。予定段階のものは含めない）
- `total_points`: 配下 Story の合計ポイント。本スキルでは触らない（`compose-stories` / `estimate-points` 側で更新される想定。初期は 0）

`created_at` / `updated_at` / `timestamp` の値は `Bash` で取得する。例:

```bash
date -u +%FT%TZ
```

### 7. ファイル出力

設定ファイル `.claude/leadcraft.md` を読み、`output.root_dir` を取得する。設定済みなら保存値を使い、未設定なら `compose-objective` で確定してくることを案内する（フォールバックは `docs/objectives`）。

- **新規作成**: `<root>/<objective>/<initiative>/` を `Bash` の `mkdir -p` で作成し、雛形を読み込んで本文を埋めたうえで `Write` する
- **既存更新**: 差分パッチを提案し、ユーザー承認の後に `Edit` で部分更新する。フロントマター・既存記述を破壊しない

ディレクトリ作成前に、作成先パスをユーザーに提示して承認を得る。

### 8. リンク整合性の確認

新規 / 更新で Initiative README に手を入れた場合、上位・配下の整合性を取る。

#### 8-1. 親 Objective README の「関連 Initiative」表を更新

`<root>/<objective>/README.md` を `Read` し、当該 Initiative の行があるかを確認する:

- **行が無い**: ユーザーに承認を取って `Edit` で 1 行追加（Status / Link を含む）
- **行はあるが Link が未作成 TODO のまま**: 実 README へのリンクと Status を更新
- **タイトル / ID が表と一致しない**: 表側を Initiative の値に揃える

加えて、親 Objective README の `initiative_count`（YAML フロントマター）を `Glob` で配下 README を再カウントして更新する。0 → 1 になるケースなどは特に注意する。

リンクは **バンドル絶対パス（`/` 始まり）** で書く（`okf.link_style: absolute` に対応）。

例:
```markdown
[/customer-retention-2026/framework-modernization-a1b2c/README.md](/customer-retention-2026/framework-modernization-a1b2c/README.md)
```

#### 8-2. 関連 Epic の整合性

Initiative README に書いた「関連 Epic」表の各 Epic について、`<root>/<objective>/<initiative>/<epic-id>/README.md` の存在を `Glob` で確認する:

- 表に書いたが README が無い Epic: `<!-- TODO: Epic README 未作成 -->` を併記し、次のステップで `compose-epic` を案内する
- README が存在するが表に無い Epic: 検出してユーザーに「表に追加するか」を確認する

`epic_count` フロントマターは、README が実在する Epic のみをカウントして反映する。

### 9. log.md への追記

設定ファイルの `okf.emit_log` が `true` のとき、`<root>/<objective>/log.md` に今回の操作を追記する。

- **新規作成**: `Creation: <initiative-id> Initiative を作成`
- **既存更新**: `Update: <initiative-id> Initiative を更新（変更概要を簡潔に）`

`log.md` が存在しない場合は新規作成する。エントリは ISO 8601 日付（`YYYY-MM-DD`）でグルーピングし、新しい順に並べる（`okf-conformance.md §3` 参照）。

### 10. 次のステップ案内

完成 / 更新したファイルパスを表示し、状況に応じて次のスキル候補を提示する。

- 親 Objective の見直し: `/compose-objective`
- 配下に新しい Epic を立てたい: `/compose-epic`
- 既存 Epic 計画書を取り込みたい: `/compose-epic <epic-readme-path>`
- Epic 配下に Story を詳細設計したい: `/compose-stories <epic-readme-path>`
- Initiative レベルの戦略リスクをさらに洗い出したい: `/identify-risks`（通常は Story 単位だが、Initiative リスクの整理にも応用可）

## 注意事項

- Initiative はトラッカー項目を持たない。本スキルはトラッカー操作を行わない（README md の生成・更新のみ）
- 既存 README を **上書きしない**。差分提案 → 承認 → `Edit` の流れを徹底する
- **Initiative の正式 ID は親 Objective の `id_suffix` を末尾に付ける**（スコープ識別子による衝突回避）。親 Objective に `id_suffix` が未設定なら従来通り base_id をそのまま使う（後方互換）。ID 規約は途中で変更しない（ディレクトリ rename と各 README の `id` フィールド更新が大規模になるため）
- 入力が薄くても作成は可能とする。空欄部分は `<!-- TODO: ... -->` を残し、ユーザーが後で埋めやすくする
- **インセプションデッキ 10 の問いは Initiative の中核** である。Epic README で重複して書かないよう、Epic 設計時には Initiative README を参照する運用を推奨する（`compose-epic` 側でも同様の方針）
- 「やらないことリスト」「何を諦めるのか」は **空欄で完成扱いにしない** ことを強く推奨する。これらが空のままだとステークホルダー間の認識ズレの温床になる。書けない場合でも、`<!-- TODO: キックオフで合意する -->` のように、次の意思決定機会を明示するメモを残す
- `target_date` を空のまま完成させてもよい。ただし `AskUserQuestion` で一度は確認する
- 親 Objective の KPI に寄与しない Initiative は、本来 Objective 自体を見直すサイン。`compose-objective` で Objective 側の KPI を追加するか、Initiative 自体の必要性をユーザーに再確認する
- 恒久運用 Initiative（hotfix の受け皿 `maintenance` 等）を扱う場合は、ユーザーに性格を確認し、不要セクション（マイルストーン等）を「（恒久 Initiative のため設定しない）」と明示する形で残す
- `total_points` は本スキルで触らない（`compose-stories` / `estimate-points` の責務）
- 内部リンクは設定ファイルの `okf.link_style` に従う（既定 `absolute`。バンドルルートからの `/` 始まりパスで書く）
- OKF 推奨フィールド（`description` / `tags` / `resource` / `timestamp`）は必ず埋める。`description` が空のまま完成扱いにしない
- 出力先 `<root>` は `output.root_dir` 設定を必ず確認する。未設定なら `compose-objective` を先に実行して確定するのが正しい流れである旨をユーザーに伝える
