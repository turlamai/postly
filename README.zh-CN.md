# Postly

[English](README.md) · **简体中文**

Postly 将 Markdown 或 Obsidian 笔记构建为静态博客。CLI 负责构建和预览。可选的 [Obsidian 插件](https://github.com/turlamai/obsidian-postly) 将选中的笔记和图片发布到 GitHub 内容分支。

## 安装和运行

安装 Racket，然后安装 Markdown 解析器和 Postly。

```sh
raco pkg install --auto --name obsidian https://github.com/turlamai/obsidian.git
raco pkg install --auto --name postly https://github.com/turlamai/postly.git
raco postly build ./site --out ./public
raco postly serve ./site --port 8080
```

访问 `http://localhost:8080/` 预览。如果站点地址含有 `/articles` 这样的路径，则访问 `http://localhost:8080/articles/`。预览服务仅监听本机。构建默认输出到 `site/_site`。部署时每次使用新的输出目录，并替换上一版发布产物，确保撤回的文章消失。

## 内容目录

```text
site/
├── postly.rkt                     # 可选配置 title、base-url 和 nav
├── blog/2026-11-28-first-note.md  # /blog/2026/11/28/first-note/
├── pages/about.md                # /about/
└── assets/photo.png              # 用 ![](/assets/photo.png) 引用
```

正文使用纯 Markdown。第一处一级标题提供文章标题，文件名的 `YYYY-MM-DD-` 前缀提供发布日期。Postly 生成 HTML、CSS、RSS 和站点地图，并复制明确放入 `assets/` 的资源。部署到 `https://example.com/articles` 等子路径时，资源链接和内置导航会使用 `/articles/` 前缀。

可从[示例](example/)开始。将源码目录链接安装后，运行 `raco test test` 和 `raco setup --check-pkg-deps postly` 验证构建。

MIT · [许可证](LICENSE)
