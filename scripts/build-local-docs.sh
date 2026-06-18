#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCBUILD="$ROOT/docbuild"
BUILD_DIR="$DOCBUILD/.lake/build"
DOCGEN="$ROOT/.lake/packages/doc-gen4/.lake/build/bin/doc-gen4"
PUBLIC_REPO_URL="${PUBLIC_REPO_URL:-https://github.com/shosonoda/lean-ksk2026}"
PUBLIC_SOURCE_BASE="${PUBLIC_REPO_URL%.git}"
MATHLIB_DOC_HOME="${MATHLIB_DOC_HOME:-https://leanprover-community.github.io/mathlib4_docs}"

source_ref() {
  printf '%s\n' "${DOCGEN_SOURCE_REF:-main}"
}

source_base() {
  if [ -n "${DOCGEN_SOURCE_BASE:-}" ]; then
    printf '%s\n' "${DOCGEN_SOURCE_BASE%.git}"
    return
  fi

  printf '%s\n' "$PUBLIC_SOURCE_BASE"
}

module_source_url() {
  local rel="$1"
  if [ -n "$SOURCE_BASE" ]; then
    printf '%s/blob/%s/%s\n' "$SOURCE_BASE" "$SOURCE_REF" "$rel"
  else
    printf 'file://%s/%s\n' "$ROOT" "$rel"
  fi
}

run_docgen() {
  (
    cd "$DOCBUILD"
    lake env "$DOCGEN" "$@"
  )
}

module_args=(
  "NoteKsk|NoteKsk.lean"
)

while IFS= read -r file; do
  rel="${file#$ROOT/}"
  component="${rel#NoteKsk/}"
  component="${component%.lean}"
  module_args+=("NoteKsk.«${component}»|$rel")
done < <(find "$ROOT/NoteKsk" -maxdepth 1 -name '*.lean' -print | sort)

cd "$ROOT"
lake build NoteKsk

(
  cd "$DOCBUILD"
  lake build «doc-gen4»
)

SOURCE_REF="$(source_ref)"
SOURCE_BASE="$(source_base)"

rm -rf \
  "$BUILD_DIR/doc" \
  "$BUILD_DIR/doc-data" \
  "$BUILD_DIR/api-docs.db" \
  "$BUILD_DIR/api-docs.db-shm" \
  "$BUILD_DIR/api-docs.db-wal" \
  "$BUILD_DIR/doc-manifest.json"
mkdir -p "$BUILD_DIR"

for entry in "${module_args[@]}"; do
  module="${entry%%|*}"
  rel="${entry#*|}"
  run_docgen single --build "$BUILD_DIR" "$module" api-docs.db "$(module_source_url "$rel")"
done

run_docgen fromDb --build "$BUILD_DIR" "$BUILD_DIR/api-docs.db"
python3 "$ROOT/scripts/rewrite-docgen-external-links.py" \
  "$BUILD_DIR/doc" \
  --external-home "$MATHLIB_DOC_HOME"

echo "Lean API documentation written to $BUILD_DIR/doc"
