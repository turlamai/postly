# postly

[English](README.md) · 简体中文

Racket 写的极简静态博客引擎：输入 Obsidian Markdown，输出纯 HTML 站点。

```
raco postly build <站点目录> [--out DIR]   # 构建为 HTML
raco postly serve <站点目录> [--port N]    # 构建 + 预览服务器
```

站点目录三件事，除 Markdown 外全部可选：

```
site/
├── postly.rkt        # 站点配置（title、base-url、nav）—— 可选
├── blog/*.md         # 文章：YYYY-MM-DD-slug.md → /blog/Y/M/D/slug/
└── pages/*.md        # 独立页：about.md → /about/
```

## 设计

- **文件是纯 Markdown。** 永远不用 frontmatter。标题 = 正文第一个 H1；日期 = 文件名 `YYYY-MM-DD-` 前缀；slug = 文件名。发布语义在命令里，不在文件里。
- **Obsidian 方言完整渲染**，走 [`obsidian`](https://pkgs.racket-lang.org/pkg/obsidian) 包：wikilinks、embed、callout、标签、高亮、任务列表——代码块永远安全。
- **yinwang 式克制 + Apple HIG 执行**：单栏 38em、系统字体、自动暗色、零运行时 JS。
- **编辑器无关**：Obsidian、Typora 或 `ed`——引擎只见 Markdown。

## 许可

MIT，见 `LICENSE`。
