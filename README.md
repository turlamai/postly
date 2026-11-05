# postly

[English](README.md) · [简体中文](README.zh-CN.md)

A minimal static blog engine in Racket: Obsidian Markdown in, a plain HTML
site out.

```
raco postly build <site-dir> [--out DIR]   # build to HTML
raco postly serve <site-dir> [--port N]    # build + preview server
```

A site directory is three things, all optional beyond the Markdown:

```
site/
├── postly.rkt        # site config (title, base-url, nav) — optional
├── blog/*.md         # posts: YYYY-MM-DD-slug.md → /blog/Y/M/D/slug/
└── pages/*.md        # standalone pages: about.md → /about/
```

## Design

- **Files are pure Markdown.** No frontmatter, ever. Title = first H1; date =
  the filename's `YYYY-MM-DD-` prefix; slug = the filename. Publishing
  semantics live in the command you run, not in the file.
- **The Obsidian dialect is fully rendered** through the
  [`obsidian`](https://pkgs.racket-lang.org/pkg/obsidian) package: wikilinks,
  embeds, callouts, tags, highlights, task lists — with code blocks always
  safe.
- **Yinwang-style restraint, Apple-HIG execution**: one 38em column, system
  fonts, automatic dark mode, zero runtime JavaScript.
- **Editor-independent**: Obsidian, Typora, or `ed` — the engine only sees
  Markdown.

## License

MIT — see `LICENSE`.
