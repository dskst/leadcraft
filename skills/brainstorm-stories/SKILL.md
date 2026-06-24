---
name: brainstorm-stories
description: 指定した Epic 配下に置く Story 候補を「タイトル + 1〜2 行の背景・目的」だけで「ざっくり」ブレストし、`<epic>/stories-draft.md` に一覧として書き出す軽量スキル。起票・受け入れ基準の詳細化・見積もり・タスク分解・依存関係の整理は一切行わない（`compose-stories` / `quick-stories` の前段として使う）。「Story をざっくり洗い出したい」「Story 候補をブレストしたい」「Epic を分解する叩き台がほしい」「とりあえず Story の輪郭だけ並べたい」「Story 群を眺めたい」「Epic の中身を発散させたい」「実装単位の発散だけしたい」「ブレストの結果を残しておきたい」「Story の見出しだけ列挙したい」「Epic を Story に分解したいがまだ起票したくない」と言われたら起動する。起票まで踏み込むなら `quick-stories`、AC・タスク・見積もりまで設計するなら `compose-stories` を案内する。`compose-epic` モード B は既存 Epic README 内の Story 候補を抽出して即起票するが、本スキルは「Epic README に書かれていない Story 候補も含めて新規にブレストし、md として残す（起票しない）」点で目的が異なる。
argument-hint: "（任意：親 Epic README のパス、Epic ID、ブレストの種となるメモ md パス、URL）"
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion, Bash, WebFetch
---

# brainstorm-stories

Epic 配下に置く Story 候補を **発散させて** 残すための軽量ブレストスキル。Story の「輪郭」だけを 1 つの markdown に並べることに特化する。

詳細設計や起票には踏み込まない。発散と収束を分けることで、ブレストの最中に「AC をどう書くか」「何ポイントか」といったレビューモードに引きずられず、思考の発散に集中できるようにする。

## 他スキルとの位置付け

| スキル | 主目的 | 出力 | 詳細化レベル |
|--------|--------|------|--------------|
| **brainstorm-stories**（本スキル） | Story 候補のブレスト・発散 | `<epic>/stories-draft.md`（タイトル + 背景・目的のみ） | 最小 |
| `quick-stories` | 叩き台 Story を起票 | トラッカー項目（`quick` ラベル） | 小（タイトル + 概要 + AC） |
| `compose-stories` | Story を詳細設計して起票 | トラッカー項目（`draft` ラベル）+ フィールド設定 + DoD コメント | 大（AC / タスク / 依存 / 見積もり / リスク） |
| `compose-epic` モード B | 既存 Epic README 内の Story 候補を抽出して起票 | トラッカー項目（`draft` ラベル）| 中（compose-stories に委譲） |

判断の指針:

- **まだ起票したくない / 発散したい**: 本スキル（`brainstorm-stories`）
- **発散済みで叩き台を素早く作りたい**: `quick-stories`
- **AC まで作り込んで起票したい**: `compose-stories`
- **既存 Epic README に Story 候補が並んでいて、それを起票したい**: `compose-epic` モード B

「本スキルで出した `stories-draft.md` を `compose-stories` または `quick-stories` の入力として渡す」運用が標準。

## 想定する利用シーン

- Epic を `compose-epic` で整え終えた直後で、配下に何を Story にすべきかまだ発散段階
- ステークホルダーとの打ち合わせで「Story の輪郭」だけ合意して、詳細化は後で進めたい
- 大きな Epic を前にして、思いつく Story 候補を一気に列挙したい
- Epic README に書かれていない観点（非機能要件・運用面・移行作業など）も Story 候補として残したい
- 詳細を詰める前に、まず候補の網羅性をユーザーと確認したい

## 出力

| 項目 | 値 |
|------|----|
| ファイル | `<root>/<objective>/<initiative>/<epic>/stories-draft.md` |
| 雛形 | `${CLAUDE_PLUGIN_ROOT}/skills/brainstorm-stories/templates/stories-draft.md` |
| 各候補の項目 | タイトル（H3）+ 1〜2 行の背景・目的のみ |
| 起票 | **行わない** |
| トラッカー連携 | **行わない** |
| ラベル付与 | **行わない** |

`<root>` は設定ファイル `.claude/leadcraft.md` の `output.root_dir`（既定 `docs/objectives`）から取得する。

> **AC / タスク / 見積もり / 依存関係を出さない理由**: ブレスト中にこれらを書こうとすると思考が収束モードに入り、候補の発散が止まる。詳細化は `compose-stories` / `quick-stories` の責務に集約することで、本スキルは「発散」に専念できる。

## 前提

- 親 Epic README（`<root>/<objective>/<initiative>/<epic>/README.md`）が既存
- Epic が無い場合は本スキルを中止し、`compose-epic` を案内する（曖昧な親階層では発散結果の置き場所が確定しないため）

## 実行手順

### 1. 設定ファイルの読み込み

`.claude/leadcraft.md` を `Read` し、以下を取得する。

- `output.root_dir` … Story 候補ファイルの出力先ルート（未設定なら `docs/objectives` をフォールバックとして使い、`compose-objective` の先行実行を推奨する旨を案内する）
- `okf.emit_log` … `log.md` 追記の要否（未設定なら `true` とみなす）

### 2. 親 Epic の特定

引数または対話で次のいずれかを取得する:

- 親 Epic README の絶対 / 相対パス（推奨）
- Epic ID（`Glob` で `<root>/*/*/*/README.md` を列挙して ID マッチ）
- 親 Epic ディレクトリのパス

引数が空なら `AskUserQuestion` で「既存 Epic 一覧から選ぶ / Epic ID を入力する」を提示する。

Epic README が見つからない場合は本スキルを中止し、`compose-epic` の利用を案内する。

Epic README を `Read` し、以下を発散の土台にする:

- 概要 / ユーザーストーリーサマリー / 価値仮説
- スコープ（含む / 含まない）
- 主要ユーザーフロー
- Epic DoD

これらは「Story 候補を出す視点」を Claude に提供する材料であり、機械的に Story を抽出する素材ではない（その役割は `compose-epic` モード B が担う）。

### 3. ブレストの材料収集（任意）

引数や対話で追加の材料を受け取る:

- 要件メモ / 仕様書（Markdown、`Read`）
- 既存の URL（`WebFetch`）
- Notion ページが渡された場合は利用可能な MCP ツール（`mcp__*__notion-fetch` 等）を動的に検出して呼び出す。無ければ `WebFetch`
- チャットでの直接記述

材料は「発散の刺激」として使う。必ずしも材料に書かれた内容だけから Story を出すのではなく、Epic の文脈を踏まえて Claude 自身が候補を補強する。

### 4. 既存 `stories-draft.md` の確認

同じ Epic で本スキルが過去に実行されている場合、`<epic>/stories-draft.md` が既存する可能性がある。

存在チェック:

```bash
test -f "<root>/<objective>/<initiative>/<epic>/stories-draft.md"
```

既存の場合は `Read` で取得し、既存候補を発散の出発点として読み込む。後続のステップでは「新規候補の追加」「既存候補の統合 / 削除提案」を扱う。

### 5. Story 候補の発散

Claude が以下の観点から Story 候補を提示する（網羅でなく刺激として）:

- Epic README の **スコープ（含むもの）** に書かれた機能を分解した候補
- 主要ユーザーフロー上の各ステップを Story 単位に切り出した候補
- 価値仮説の **検証** に必要な計測・分析系の候補
- 非機能要件（パフォーマンス / セキュリティ / アクセシビリティ）の候補
- 運用 / 移行 / ドキュメント / リリースノートの候補
- 既存仕様との互換性確保や移行作業の候補

各候補は次の最小フォーマットで出す:

```
### <Story タイトル>

<1〜2 行の背景・目的>
```

10 件前後を **一度に** 提示する（細切れに対話しない）。網羅性より発散の幅を優先する。

### 6. ユーザーによる選別・追加

提示した候補リストをユーザーに見せ、`AskUserQuestion` または自由記述で次を受け取る:

- 採用 / 不採用 / 統合（複数候補を 1 件に統合）
- 抜けている観点の追加
- タイトルや背景の修正

ユーザーが追加候補を出してきたら、本スキルが背景・目的を 1〜2 行に整える。

「個別の候補について詳細を詰めたい」とユーザーが言い始めたら、それはもう本スキルの役割ではない。`compose-stories` への切り替えを案内する。

### 7. `stories-draft.md` の出力

`${CLAUDE_PLUGIN_ROOT}/skills/brainstorm-stories/templates/stories-draft.md` をベースに本文を組み立て、`<root>/<objective>/<initiative>/<epic>/stories-draft.md` に書き出す。

- **新規作成**: `Write` で生成
- **既存更新**: 差分提案 → ユーザー承認後に `Edit` で部分更新。既存候補のうち統合・削除されたものは「採用判断ログ」セクションに移動して履歴を残す

OKF frontmatter（`references/okf-conformance.md` § 2 参照）:

- `type: stories-draft`（固定）
- `title`: `<epic-title> Story 候補ドラフト` の形式で設定
- `description`: 「<epic-title> の Story 候補を発散させたブレスト結果」の形式で **1 文**で記述。index.md と AI 関連度判定の土台になるため必ず埋める
- `tags`: Epic のタグをミラーリングする場合はリストを入れる（既定: `[]`）
- `resource`: `null`（stories-draft は外部トラッカー項目を持たない）
- `timestamp`: 実行日時（`Bash` で `date -u +%FT%TZ`）。`updated_at` と同値
- `epic`: Epic README の `id` フィールドそのまま（suffix の有無は透過）
- `initiative`: Epic README の `initiative` フィールドそのまま
- `objective`: Epic README の `objective` フィールドそのまま
- `created_at`: 新規時のみ `Bash` で `date -u +%FT%TZ`
- `updated_at`: 常に実行日で上書き

候補本文は H3 見出し + 1〜2 行の段落で記述する。**箇条書きやリストでの羅列は避ける**（次のスキルが H3 単位で候補を識別しやすいように）。

#### 7-1. log.md への追記

`okf.emit_log` が `true`（または未設定）の場合、Epic ディレクトリ（`<root>/<objective>/<initiative>/<epic>/log.md`）に以下を追記する:

新規作成時:
```
## YYYY-MM-DD
- Creation: stories-draft.md を作成（候補 N 件）
```

更新時:
```
## YYYY-MM-DD
- Update: stories-draft.md を更新（候補追加 N 件 / 統合 M 件）
```

`log.md` が存在しない場合は `# Log\n\n` ヘッダーから新規作成する。

### 8. 次のステップ案内

生成 / 更新したファイルパスを表示し、次のスキル候補を提示する:

- **個別に詳細設計して起票したい**: `/compose-stories <stories-draft.md のパス>`
- **複数件まとめて叩き台として起票したい**: `/quick-stories <stories-draft.md のパス>`

`stories-draft.md` は **発散のスナップショット** であり、Story が起票された後は更新しなくてよい（git log で経緯を追う）。

## ブレストを支援する問いかけの例

ユーザーから候補が出てこない場合、Claude は次のような問いかけを提案する:

- 「このユーザーフロー、エラー時のリカバリーはどう扱う?」
- 「リリース後の監視・ダッシュボードは Story として切り出す?」
- 「既存ユーザーへの周知・移行は誰が担当する?」
- 「権限が無いユーザーが触ったときの挙動は?」
- 「データ移行が必要なら、別 Story に切り出すべきでは?」
- 「KPI 計測のためのログ実装は Story として独立させる?」

これらは網羅チェックではなく **発散の引き金** として使う。ユーザーが「それは別 Epic だ」「不要だ」と判断したら深追いしない。

## 注意事項

- **詳細設計には踏み込まない**。AC・タスク・見積もり・依存関係・リスクは出さない。「ざっくり」を保つことが本スキルの価値
- **起票は行わない**。起票したくなったら `quick-stories` または `compose-stories` を案内する
- **Epic 必須**。Epic README が無ければ `compose-epic` を案内して中止する
- 既存 `stories-draft.md` は **上書きしない**。差分提案 → 承認 → `Edit` の流れ。削除した候補は「採用判断ログ」に移動して履歴を残す
- **OKF frontmatter の `description` / `tags` / `timestamp` / `resource` は必ず埋める**（OKF 適合の推奨フィールド）
- 出力先 `<root>` は `output.root_dir` 設定を確認する。未設定なら `compose-objective` を先に実行する流れを案内し、続行する場合のフォールバックは `docs/objectives`
- 候補は H3 見出しで列挙する。箇条書きでまとめない（後続スキルが H3 単位で候補を識別するため）
- **発散と収束を分ける**。1 件ずつ AC を詰める対話に入ったら、それは `compose-stories` の役割。早めに切り替えを案内する
- 本スキルは **Story 候補のみ** を扱う。Epic そのものの編集・Initiative の編集には踏み込まない
- `compose-epic` モード B との混同に注意: モード B は **既存 Epic README に書かれた候補を抽出して起票** する。本スキルは **書かれていない候補を含めて新規にブレストして md に残す**。目的と出力先が異なる
- **スキル本文にトラッカー固有コマンドを直書きしない**。本スキルは起票を行わないため操作呼び出しは不要だが、次スキルへの案内で `gh issue create` 等を具体コマンドとして誘導しない
