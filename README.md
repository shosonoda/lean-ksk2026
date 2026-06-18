# lean-ksk2026

2026 年度の測度論・積分論講義資料の公開用リポジトリです。

GitHub Pages 用の生成済みサイトは、`main` branch の `docs/` 配下に置いています。
Lean 形式化はリポジトリ直下の `NoteKsk` Lake project です。

```bash
lake exe cache get
lake build NoteKsk
```

`docs/docs/` 以下のローカル API documentation は `NoteKsk` モジュールだけを対象に
生成しています。mathlib 宣言へのリンクは公開 mathlib documentation を指します。
