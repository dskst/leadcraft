---
name: compose-objective
description: 経営・事業・プロダクト上の大きな目標（Objective）を 1 件、対話を通じて整え、プラグイン同梱の `objective.md` テンプレートから `<root>/<objective>/README.md` として生成・更新する。「Objective を作る」「目的を定義する」「事業目標を立てる」「KPI を整理して Objective README を書く」「経営目標を起票する」「Objective を整える」「Objective を更新する」「Objective を見直す」と言われたら起動する。Epic を整えたい場合は `compose-epic` を、Epic 配下に Story を詳細設計したい場合は `compose-stories` を案内する。
argument-hint: "（任意：Objective の概要メモ md パス、ID 候補、URL）"
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion, Bash
---

# compose-objective

5 階層（Objective > Initiative > Epic > Story > Task）の最上位である **Objective** を 1 件、丁寧に作り込むための専用スキル。

Epic 設計を担う `compose-epic` や、Story を詳細化する `compose-stories` とは目的が異なる。本スキルは「方向性そのものをどう言語化するか」「KPI をどう設計するか」を対話で詰めることに集中し、結果を `<root>/<objective>/README.md` に落とす。ステークホルダー情報は **Initiative 層の責務** とし、Objective には持たせない（`compose-initiative` のインセプションデッキ「ご近所さんを探せ」が一次情報源）。

## 想定する利用シーン

- 期初・四半期キックオフで新しい Objective を立てる
- 既存 Objective の KPI / マイルストーン / スコープ外を見直して README を最新化する
- Initiative 群が複数走っているが Objective README が薄いまま放置されている状態を整える
- `compose-epic` / `compose-stories` 実行時に「Objective を先に整えてから上位 → 下位の順で並べたい」と感じたとき

Epic を整えたい場合は `compose-epic` を、Epic 配下に Story を詳細設計したい場合は `compose-stories` を案内する。

## 出力

| 項目 | 値 |
|------|----|
| ファイル | `<root>/<objective>/README.md` |
| 雛形 | `${CLAUDE_PLUGIN_ROOT}/skills/compose-objective/templates/objective.md` |
| `<root>` | 設定ファイル `.claude/leadcraft.md` の `output.root_dir`（既定 `docs/objectives`、未設定時は compose-objective が対話で確定） |
| 既存ファイル | 上書きせず、差分提案 → ユーザー承認後に `Edit` で部分更新 |

恒久 Objective（hotfix の受け皿となる `operations` 等）を扱う場合も、本スキルで README を編集する。新規作成と更新の判定はユーザーに確認する。

## 実行手順

### 1. 入力ソースの特定

引数または対話で以下のいずれかを取得する。引数が空ならまず `AskUserQuestion` で選択肢を提示する。

- チャットに書かれた目標の概要テキスト
- Markdown / メモ ファイルパス（`Read`）
- トラッカー Issue / Discussion URL（`Bash` でトラッカー抽象操作 `get_item` を使うか、または `WebFetch`）
- 戦略資料 URL（`WebFetch`）
- 「ゼロから対話で組み立てる」（入力なし）

Notion ページが渡された場合は、現セッションで利用可能な MCP ツール（`mcp__*__notion-fetch` など）を動的に検出し、あれば呼び出す。無ければ `WebFetch` に切り替える。

### 2. 既存 Objective の確認

`<root>` を `Glob` で `*/README.md` 直下まで列挙し、既存 Objective を一覧する。

```
<root>/*/README.md
```

ユーザー入力と既存 Objective を突き合わせ、`AskUserQuestion` で次の 3 択を確認する。

- **新規作成**: 新しいディレクトリと README を作る
- **既存を更新**: 既存 README を読み込み、不足項目を埋める／KPI を見直す
- **既存を置き換え**: 互換性が無い大改訂（バックアップ提案を行ったうえで承認を得る）

更新モードでは、現状の README を `Read` で読み込み、フロントマター・各見出し配下のテキストを保持したうえで差分提案する。**全体上書きはしない**。

### 3. ID とタイトルの確定

新規作成の場合は次を確定する。決められなければ `AskUserQuestion` で確認する。

- **ID（ディレクトリ名）**: kebab-case の英小文字。例: `customer-retention-2026`, `payment-modernization`
- **タイトル**: 日本語可。経営・事業の言葉で簡潔に。例: 「2026 上期の解約率改善」
- **オーナー**: 経営・事業責任者の氏名 / ロール
- **目標時期**: 達成目標時期。`YYYY-Q?` か `YYYY-MM` を推奨

ID の候補が思いつかない場合は、タイトルから 2〜3 案を提示してユーザーに選ばせる。

### 3-1. id_suffix の確定（スコープ識別子）

**新規 Objective 作成時のみ実行**。Objective YAML フロントマターの `id_suffix` フィールドに 5 文字の小文字英数字を保存する。これは配下 Initiative / Epic の id 末尾に付与され、同じ slug が別の Objective 配下に存在しても衝突を回避する。

#### 3-1-1. 生成

`Bash` でランダムな 5 文字小文字英数字を生成する:

```bash
LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 5
```

#### 3-1-2. ユーザー確認

生成値を `AskUserQuestion` で提示し、次の 3 択から確認する:

1. **自動生成値を採用**（Recommended、デフォルト推奨）— ランダム性が最も高く、衝突確率が低い
2. **カスタム入力** — 5 文字程度の英数字小文字をユーザーが直接指定（例: タイトル略号 `crt26`、プロジェクト固有のコードネーム等）
3. **suffix を付けない** — バンドル内でしか概念を管理しない、または衝突を許容できる場合に限る（**非推奨**。後から suffix を導入する場合、配下 Initiative / Epic の id 全体を rename する必要があり手戻りが大きい）

選択結果を `OBJECTIVE_ID_SUFFIX` 変数に保持する（3 を選んだ場合は空文字）。バリデーション: 1〜2 を選んだ場合は **`^[a-z0-9]{5}$` に正確にマッチすること**（5 文字小文字英数字、固定）。マッチしない場合はユーザーに再入力を求める。

#### 3-1-3. 不変原則

`id_suffix` は **Objective 作成時に一度だけ確定** し、以後変更しない。変更すると配下 Initiative / Epic のディレクトリ名・各 README の `id` フィールド・トラッカー参照すべてに rename が波及する。**既存 Objective を更新する際は本ステップをスキップし、現行値を尊重する**。

#### 3-1-4. 既存 Objective に suffix が未設定の場合（**後付け追加は非推奨**）

`Read` した既存 README のフロントマターに `id_suffix` キーが存在しない、または空文字の場合:

**既定の挙動: 何もしない**（フィールドを省略のまま残し、後方互換動作で配下 Initiative / Epic は suffix なしで作成し続ける）。

ユーザーが「どうしても suffix を追加したい」と明示要望した場合のみ進める:

- 既存配下の Initiative / Epic / ADR / Design Doc を `Glob` で網羅列挙し、rename 対象ファイル数を提示
- 「現状この移行は手動。対話の中で一つひとつ進めることになる」と明確に伝える
- それでも続行するか最終確認を取る。続行する場合、本スキルでは Objective README に `id_suffix` を書き込むまでを行い、**配下の rename は本スキルの範囲外**とする

### 4. Objective 本文の項目埋め

雛形（`${CLAUDE_PLUGIN_ROOT}/skills/compose-objective/templates/objective.md`）の構成を骨格として、以下を埋めにいく。判明している範囲で書き、不明部分は `<!-- TODO: ... -->` で明示する。

- **概要**: 解決したい課題と、達成したい状態を 3〜5 行
- **背景**: なぜ今この Objective を掲げるのか（市場・組織・KPI 実績）
- **達成基準（KPI / 成果指標）**: 表で「指標 / 目標値 / 現状 / 計測方法」を最低 1 行
- **関連 Initiative**: 現時点で予定／走っているものを列挙。未確定なら空表＋「Initiative はこれから整える」旨を記載
- **マイルストーン**: 着手目標 / 中間レビュー / 達成目標
- **やらないこと（スコープ外）**: この Objective に含めない事項（明示が重要）
- **参考資料**: 関連ドキュメント・ダッシュボード URL
- **メモ**: 今後の検討事項

KPI の整理が薄い場合、`AskUserQuestion` で「先行指標 / 遅行指標」「定量化できない目標を定量化する代替指標」を聞き出す。最低 1 つは数値で測れる指標を持たせるよう促す。

### 5. YAML フロントマターの設定

雛形のフロントマターを次のルールで初期化／更新する。

- `type: objective`（固定）
- `id`: ステップ 3 で決めた kebab-case
- `id_suffix`: ステップ 3-1 で決めた 5 文字小文字英数字（suffix を付けない選択の場合は省略 or 空文字）
- `title`: ステップ 3 で決めたタイトル
- `description`: **OKF 推奨。1 文の要約**（`index.md` の progressive disclosure と AI 関連度判定の土台になる）。`AskUserQuestion` で確認するか、タイトル・概要から自動生成して提案する
- `tags`: 横断検索用タグ（任意。関連チーム名・領域名等）
- `resource`: Objective の基礎資産 URI（`tracker.provider == github` の場合は Projects URL 等）。無ければ `null`
- `timestamp`: `updated_at` と同値の ISO 8601 文字列（OKF 標準キー）
- `status`: 新規は `planning`。更新時はユーザー確認のうえ `planning | in_progress | done | cancelled` から選択
- `created_at`: 新規時のみ実行日（`Bash` の `date -u +%FT%TZ`）
- `updated_at`: 常に実行日で上書き
- `owner`: ステップ 3 で取得
- `target_date`: ステップ 3 で取得
- `kpis`: KPI 名のリスト（短い ID または指標名）。本文の達成基準表とずれないように注意
- `initiative_count`: 関連 Initiative の現存数（未確定なら 0）

`created_at` / `updated_at` / `timestamp` の値は `Bash` で取得する。例:

```bash
date -u +%FT%TZ
```

### 6. 出力ルート `<root>` の確定（初回実行時のみ対話）

設定ファイル `.claude/leadcraft.md` を `Read` し、`output.root_dir` を取得する。

#### 6-1. 未確定の場合の対話

`output.root_dir` が空文字 / 未定義 / プレースホルダ（例: `""`）の場合、**本スキルの責務として `AskUserQuestion` で確定する**。`compose-objective` は階層モデルのルート起点なので、ここで確定して以降のスキルから参照させる設計。

選択肢（順序通り提示）:

1. **`docs/objectives`**（Recommended）— `docs/` 配下に置くことで、リポジトリ内のドキュメント資産として可視管理しやすい。README やオンボーディングからの導線が作りやすい
2. **`.objectives`** — ドット付き隠しディレクトリ。トップレベルのファイル一覧を散らかしたくない場合
3. **Other** — 自由入力（例: `planning/objectives`、`docs/plans` など）

#### 6-2. 選択結果の保存

ユーザーが選んだ値を `.claude/leadcraft.md` の `output.root_dir` に書き戻す。`Edit` で `output:` ブロックの `root_dir:` 行のみを書き換える（他のキーは触らない）。設定ファイル自体が存在しない場合は、雛形（`${CLAUDE_PLUGIN_ROOT}/skills/setup-baseline/templates/leadcraft.md`）をコピーしてから書き換える。

書き戻し例:

```yaml
output:
  root_dir: "docs/objectives"  # 確定済み（compose-objective 初回実行時に設定）
```

#### 6-3. 確定後の使用

確定した `<root>` を以降の本スキル内ステップ、および後続スキル（`compose-initiative` / `compose-epic` / `compose-stories` / `compose-hotfix` / `write-adr` / `write-dd` / `convert-points-to-time`）から共有設定として参照する。**一度確定したら以後は対話しない**（設定ファイルから読むだけ）。

#### 6-4. ファイル出力

- **新規作成**: `<root>/<objective>/` を作成し、`${CLAUDE_PLUGIN_ROOT}/skills/compose-objective/templates/objective.md` を読み込んで本文を埋めたうえで `Write` する
- **既存更新**: 差分パッチを提案し、ユーザー承認の後に `Edit` で部分更新する。フロントマター・既存記述を破壊しない

ディレクトリが存在しない場合は `Bash` で `mkdir -p` する前に、ユーザーに作成先を提示して承認を得る。

### 7. リンク整合性の確認

新規 / 更新で「関連 Initiative」表に手を入れた場合、各 Initiative の README が `<root>/<objective>/<initiative-id>/README.md` に存在するかを `Glob` で確認する。

- 表に書いたが README が無い Initiative: `<!-- TODO: Initiative README 未作成 -->` を併記し、次のステップで `compose-initiative` を案内する
- README が存在するが表に無い Initiative: 検出してユーザーに「表に追加するか」を確認する

「関連 Initiative」表のリンクは **バンドル絶対パス（`/` 始まり）** で書く（`okf.link_style: absolute` に対応）。

例:
```markdown
[/customer-retention-2026/framework-modernization-a1b2c/README.md](/customer-retention-2026/framework-modernization-a1b2c/README.md)
```

### 8. log.md への追記

設定ファイルの `okf.emit_log` が `true` のとき、`<root>/log.md` に今回の操作を追記する。

- **新規作成**: `Creation: <objective-id> Objective を作成`
- **既存更新**: `Update: <objective-id> Objective を更新（変更概要を簡潔に）`

`log.md` が存在しない場合は新規作成する。エントリは ISO 8601 日付（`YYYY-MM-DD`）でグルーピングし、新しい順に並べる（`okf-conformance.md §3` 参照）。

### 9. 次のステップ案内

完成 / 更新したファイルパスを表示し、状況に応じて次のスキル候補を提示する。

- Initiative の README を整えたい: `/compose-initiative`（インセプションデッキ 10 の問いを対話で詰める）
- 配下に新しい Epic を立てたい: `/compose-epic`
- 既存 Epic 計画書を取り込みたい: `/compose-epic <epic-readme-path>`（Epic を整えつつ Story 候補も抽出）
- Epic 配下に Story を詳細設計したい: `/compose-stories <epic-readme-path>`

## 注意事項

- Objective は独立したトラッカー項目を持たない。本スキルはトラッカー操作を行わない（README md の生成・更新のみ）
- 既存 README を **上書きしない**。差分提案 → 承認 → `Edit` の流れを徹底する
- 入力が薄くても作成は可能とする。空欄部分は `<!-- TODO: ... -->` を残し、ユーザーが後で埋めやすくする
- `id_suffix` は **Objective 作成時に一度だけ確定** し、以後不変。配下 Initiative / Epic のディレクトリ名・各 README の `id` フィールドに波及するため、変更すると大規模 rename が必要になる。**更新モードでは現行値を尊重し、本スキルから書き換えない**
- KPI は「定量化できる指標を最低 1 つ」を推奨するが、強制はしない。定性的な指標しか無い場合は、`目標値` 列に「定性: 〜の状態」と書いて測定方法を併記する
- `target_date` を空のまま完成させてもよい。ただし `AskUserQuestion` で一度は確認する
- 恒久運用の特殊 Objective（例: hotfix の受け皿 `operations`）を扱う場合は、ユーザーに性格を確認し、「やらないこと」「DoD」相当が当てはまらないセクションは「（恒久 Objective のため設定しない）」と明示する形で残す
- 内部リンクは設定ファイルの `okf.link_style` に従う（既定 `absolute`。バンドルルートからの `/` 始まりパスで書く）
- OKF 推奨フィールド（`description` / `tags` / `resource` / `timestamp`）は必ず埋める。`description` が空のまま完成扱いにしない
- 出力先 `<root>` は `output.root_dir` 設定を必ず確認する。`output.root_dir` が未設定なら本スキルが対話で確定する（フォールバックは `docs/objectives`）
