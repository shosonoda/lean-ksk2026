# lean-ksk2026

Public materials for the 2026 lecture notes on measure and integration.

The generated website is served from `docs/` on the `main` branch. The Lean
formalization is the `NoteKsk` Lake project at the repository root.

```bash
lake exe cache get
lake build NoteKsk
```

The local API documentation under `docs/docs/` is generated only for `NoteKsk`.
Links to mathlib declarations point to the public mathlib documentation.
