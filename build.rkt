#lang racket/base

;; Build orchestration: a content directory in, a static site out.
;;
;; Site layout produced:
;;   /index.html            homepage (recent posts)
;;   /blog/index.html       all posts
;;   /blog/YYYY/M/D/slug/   one permalink per post
;;   /<page>/               one page per content/pages/<page>.md
;;   /feed.xml, /sitemap.xml
;;   /static/               theme assets

(require racket/file
         racket/list
         racket/match
         racket/path
         racket/runtime-path
         racket/string
         obsidian
         "config.rkt"
         "content.rkt"
         "rss.rkt"
         "theme/theme.rkt")

(provide build!
         load-site)

;; Resolved at compile time relative to this file: works both installed and
;; linked from source.
(define-runtime-path theme-static-dir "theme/static")

;; load-site : path? -> site?
;; Reads an optional postly.rkt in the content root. The file must provide
;; `config`: a hash of site fields (title, base-url, nav). Absent file = a
;; default site, so a bare folder of Markdown still builds.
(define (load-site content-dir)
  (define cfg-file (build-path content-dir "postly.rkt"))
  (site-args->site
   (and (file-exists? cfg-file)
        (dynamic-require cfg-file 'config))))

;; write-file* : path? bytes? -> void?
(define (write-file* path content)
  (make-directory* (path-only path))
  (with-output-to-file path (lambda () (write-bytes content)) #:exists 'replace))

;; page-path : string? -> path?
;; /blog/2026/11/05/slug/ -> <out>/blog/2026/11/05/slug/index.html
(define (out-page out url-path)
  (build-path out
              (string->path (substring (string-trim url-path "/") 0))
              "index.html"))

;; build! : path? path? [site?] -> void?
(define (build! content-dir out-dir (st #f))
  (define site-cfg (or st (load-site content-dir)))
  (define posts-dir (build-path content-dir "blog"))
  (define pages-dir (build-path content-dir "pages"))

  (define posts (if (directory-exists? posts-dir)
                    (scan-docs posts-dir)
                    '()))

  ;; homepage
  (write-file* (build-path out-dir "index.html")
               (string->bytes/utf-8
                (page->html (index-page site-cfg posts 10))))

  ;; blog index
  (when (not (null? posts))
    (write-file* (out-page out-dir "/blog/")
                 (string->bytes/utf-8
                  (page->html (blog-index-page site-cfg posts)))))

  ;; post permalinks
  (for ((d (in-list posts)))
    (write-file* (out-page out-dir (post-permalink (doc-date d) (doc-slug d)))
                 (string->bytes/utf-8
                  (page->html (post-page site-cfg d)))))

  ;; standalone pages from content/pages/*.md
  (when (directory-exists? pages-dir)
    (for ((p (in-list (directory-list pages-dir #:build? #t)))
          #:when (equal? (path-get-extension p) #".md"))
      (define slug
        (path->string (path-replace-extension (file-name-from-path p) #"")))
      (define src (file->string p))
      (define t (or (document-title src) (string-titlecase slug)))
      (write-file* (out-page out-dir (format "/~a/" slug))
                   (string->bytes/utf-8
                    (page->html (plain-page site-cfg t (obsidian->html src)))))))

  ;; feeds
  (write-file* (build-path out-dir "feed.xml")
               (string->bytes/utf-8 (rss-xml site-cfg posts)))
  (write-file* (build-path out-dir "sitemap.xml")
               (string->bytes/utf-8 (sitemap-xml site-cfg posts)))

  ;; theme assets
  (define static-dir theme-static-dir)
  (when (directory-exists? static-dir)
    (for ((f (in-list (directory-list static-dir #:build? #t)))
          #:when (file-exists? f))
      (define dest (build-path out-dir "static" (file-name-from-path f)))
      (make-directory* (path-only dest))
      (copy-file f dest 'replace)))
)
