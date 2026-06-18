#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path
from urllib.parse import urlsplit


HREF_RE = re.compile(r'href="([^"]+)"')


def external_module_url(external_home: str, rel_path: str, query: str, fragment: str) -> str:
    url = f'{external_home.rstrip("/")}/{rel_path}'
    if query:
        url += f"?{query}"
    if fragment:
        url += f"#{fragment}"
    return url


def rewrite_html(path: Path, doc_dir: Path, external_home: str) -> bool:
    original = path.read_text(encoding="utf-8")
    doc_root = doc_dir.resolve()

    def repl(match: re.Match[str]) -> str:
        href = match.group(1)
        parts = urlsplit(href)
        if parts.scheme or parts.netloc or not parts.path.endswith(".html"):
            return match.group(0)

        target = (path.parent / parts.path).resolve()
        try:
            rel_path = target.relative_to(doc_root).as_posix()
        except ValueError:
            return match.group(0)

        if target.exists() or rel_path == "NoteKsk.html" or rel_path.startswith("NoteKsk/"):
            return match.group(0)

        return f'href="{external_module_url(external_home, rel_path, parts.query, parts.fragment)}"'

    rewritten = HREF_RE.sub(repl, original)
    if rewritten == original:
        return False
    path.write_text(rewritten, encoding="utf-8")
    return True


def rewrite_declaration_index(doc_dir: Path, external_home: str) -> bool:
    path = doc_dir / "declarations" / "declaration-data.bmp"
    if not path.exists():
        return False

    data = json.loads(path.read_text(encoding="utf-8"))
    changed = False
    modules = data.get("modules", {})
    for name, info in modules.items():
        if name.startswith("NoteKsk."):
            continue
        url = info.get("url")
        if not isinstance(url, str) or url.startswith("http"):
            continue
        rel_path = url.removeprefix("./")
        info["url"] = f'{external_home.rstrip("/")}/{rel_path}'
        changed = True

    if changed:
        path.write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    return changed


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Rewrite non-NoteKsk module links in local doc-gen4 output to external docs."
    )
    parser.add_argument("doc_dir", type=Path)
    parser.add_argument(
        "--external-home",
        default="https://leanprover-community.github.io/mathlib4_docs",
    )
    args = parser.parse_args()

    changed_html = 0
    for path in sorted(args.doc_dir.rglob("*.html")):
        if rewrite_html(path, args.doc_dir, args.external_home):
            changed_html += 1
    changed_index = rewrite_declaration_index(args.doc_dir, args.external_home)

    print(
        "Rewrote external doc-gen4 links in "
        f"{changed_html} HTML files"
        f"{' and declaration index' if changed_index else ''}."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
