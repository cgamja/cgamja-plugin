#!/usr/bin/env python3
"""정적 빌드 결과(HTML)에서 SEO 기본 항목을 뽑는다. 에이전트 감사 전후로 같은 숫자를 비교하는 용도.

사용:
  python3 inspect_html.py <out_dir>            # 폴더 안 모든 index.html + 404.html
  python3 inspect_html.py <out_dir> / /blog/   # 경로를 지정하면 그 페이지만
  python3 inspect_html.py --url http://localhost:3100/ [/blog/ ...]

표준 라이브러리만 쓴다. 결과는 페이지당 한 블록. 숫자가 0이어야 하는 것: NO-ALT, 본문 opacity:0, 반복 문장, H1≠1.
"""
import re
import sys
import urllib.request
from html import unescape
from pathlib import Path


def fetch(url: str) -> str:
    with urllib.request.urlopen(url, timeout=20) as r:
        return r.read().decode("utf-8", "replace")


def pages_from_dir(root: Path, paths: list[str]) -> list[tuple[str, str]]:
    if paths:
        out = []
        for p in paths:
            f = root / p.strip("/") / "index.html" if p != "/" else root / "index.html"
            out.append((p, f.read_text(encoding="utf-8")))
        return out
    out = [(f"/{f.parent.relative_to(root)}/".replace("/./", "/"), f.read_text(encoding="utf-8"))
           for f in sorted(root.rglob("index.html")) if "_next" not in f.parts]
    nf = root / "404.html"
    if nf.exists():
        out.append(("/404.html", nf.read_text(encoding="utf-8")))
    return out


def attr(tag: str, name: str) -> str | None:
    m = re.search(rf'\b{name}="([^"]*)"', tag)
    return unescape(m.group(1)) if m else None


def text_of(html: str) -> str:
    body = re.sub(r"<(script|style|svg)\b.*?</\1>", " ", html, flags=re.S | re.I)
    body = re.sub(r"<!--.*?-->", "", body, flags=re.S)
    body = re.sub(r"<[^>]+>", "", body)
    return re.sub(r"\s+", " ", unescape(body)).strip()


def inspect(path: str, html: str) -> None:
    head = html.split("</head>", 1)[0]
    metas = re.findall(r"<meta\b[^>]*>", head)
    links = re.findall(r"<link\b[^>]*>", head)

    def meta(key: str, kind: str = "name") -> list[str]:
        return [attr(m, "content") or "" for m in metas if attr(m, kind) == key]

    title = re.search(r"<title>(.*?)</title>", head, re.S)
    title = unescape(title.group(1)).strip() if title else None
    desc = meta("description")
    canonical = [attr(l, "href") for l in links if attr(l, "rel") == "canonical"]
    robots = meta("robots")
    og_url, og_title, og_image = meta("og:url", "property"), meta("og:title", "property"), meta("og:image", "property")
    font_preloads = [l for l in links if attr(l, "rel") == "preload" and attr(l, "as") == "font"]
    lang = re.search(r'<html\b[^>]*\blang="([^"]*)"', html)

    h1 = [text_of(h) for h in re.findall(r"<h1\b[^>]*>(.*?)</h1>", html, re.S)]
    h2 = [text_of(h) for h in re.findall(r"<h2\b[^>]*>(.*?)</h2>", html, re.S)]
    imgs = re.findall(r"<img\b[^>]*>", html)
    no_alt = [attr(i, "src") for i in imgs if attr(i, "alt") is None]
    empty_alt = sum(1 for i in imgs if attr(i, "alt") == "")

    body_html = html.split("<body", 1)[-1]
    svg_free = re.sub(r"<svg\b.*?</svg>", "", body_html, flags=re.S | re.I)
    hidden_total = len(re.findall(r'style="[^"]*opacity:\s*0(?![.\d])', body_html))
    hidden_text = len(re.findall(r'style="[^"]*opacity:\s*0(?![.\d])', svg_free))

    text = text_of(body_html)
    repeats = sorted({m.group(1) for m in re.finditer(r"(\S.{7,60}?)\1", text)})
    jsonld = [re.findall(r'"@type":"([^"]+)"', b)[:1] for b in re.findall(r'<script type="application/ld\+json">(.*?)</script>', html, re.S)]

    def ln(label: str, value) -> None:
        print(f"  {label:<14} {value}")

    print(f"\n== {path}")
    ln("title", f"{title!r} ({len(title or '')}자)")
    ln("description", f"{desc[0][:80]!r} ({len(desc[0])}자)" if desc else "NONE")
    ln("canonical", canonical or "NONE")
    ln("robots", robots or "(inherit)")
    ln("og", f"url={og_url} title={[t[:30] for t in og_title]} image={og_image}")
    ln("lang", lang.group(1) if lang else "NONE")
    ln("h1", f"{len(h1)}개 {h1}")
    ln("h2", f"{len(h2)}개 {[h[:24] for h in h2]}")
    ln("img", f"{len(imgs)}개 · NO-ALT {len(no_alt)} {no_alt} · 장식(alt='') {empty_alt}")
    ln("opacity:0", f"본문 {hidden_text} · 전체(SVG 포함) {hidden_total}")
    ln("font preload", len(font_preloads))
    ln("json-ld", [t[0] if t else "?" for t in jsonld])
    ln("반복 문장", f"{len(repeats)}개 {[r[:30] for r in repeats[:5]]}")
    ln("본문 글자수", len(text))


def main(argv: list[str]) -> int:
    if not argv:
        print(__doc__)
        return 1
    if argv[0] == "--url":
        base = argv[1].rstrip("/")
        paths = argv[2:] or ["/"]
        pages = [(p, fetch(base + p)) for p in paths]
    else:
        pages = pages_from_dir(Path(argv[0]), argv[1:])
    for path, html in pages:
        inspect(path, html)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
