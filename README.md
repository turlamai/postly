# Postly

**English** · [简体中文](README.zh-CN.md)

Postly builds a static blog from Markdown or Obsidian notes. Use the CLI to build and preview a site. The optional [Obsidian plugin](https://github.com/turlamai/obsidian-postly) publishes selected notes and images to a GitHub content branch.

## Install and run

Install Racket, then install the Markdown parser and Postly:

```sh
raco pkg install --auto --name obsidian https://github.com/turlamai/obsidian.git
raco pkg install --auto --name postly https://github.com/turlamai/postly.git
raco postly build ./site --out ./public
raco postly serve ./site --port 8080
```

Open `http://localhost:8080/` to preview. If the canonical base URL includes a path such as `/articles`, preview at `http://localhost:8080/articles/`. The preview server binds to the local machine. By default, build output goes to `site/_site`. Use a fresh output directory for every deployment and replace the previous published output so withdrawn articles disappear.

## Content layout

```text
site/
├── postly.rkt                     # Optional title, base-url and nav
├── blog/2026-11-28-first-note.md  # /blog/2026/11/28/first-note/
├── pages/about.md                # /about/
└── assets/photo.png              # Reference as ![](/assets/photo.png)
```

Write pure Markdown. The first H1 supplies the title. A `YYYY-MM-DD-` filename prefix supplies the publication date. Postly generates HTML, CSS, RSS and a sitemap. Explicitly staged assets are copied into the output. Under a base URL such as `https://example.com/articles`, asset links and built-in navigation use the `/articles/` prefix.

Use the [example](example/) as a starting point. Run `raco test test` and `raco setup --check-pkg-deps postly` from a linked source checkout to verify the build.

MIT · [License](LICENSE)
