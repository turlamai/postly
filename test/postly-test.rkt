#lang racket/base

;; Build the example site into a temp dir and check the output surface.

(require rackunit
         obsidian
         racket/file
         racket/runtime-path
         racket/list
         racket/path
         racket/string
         "../build.rkt"
         "../config.rkt"
         "../content.rkt")

(define-runtime-path here ".")
(define example-dir (simplify-path (build-path here ".." "example")))

;; content scan -----------------------------------------------------------

(define posts (scan-docs (build-path example-dir "blog")))
(check-equal? (length posts) 2)
;; newest first
(check-equal? (doc-slug (first posts)) "hello-postly")
(check-equal? (doc-slug (second posts)) "second-post")
;; date from filename prefix
(check-equal? (doc-date (first posts)) '("2026" "11" "05"))
;; title = first H1
(check-equal? (doc-title (first posts)) "Hello postly")
;; tags collected
(check-not-false (member "racket" (doc-tags (first posts))) "has #racket")

;; build ------------------------------------------------------------------

(define out (make-temporary-file "postly-test~a" 'directory))
(build! example-dir out)

;; homepage exists and lists the newest post
(define home (file->string (build-path out "index.html")))
(check-true (string-contains? home "Hello postly"))
(check-true (string-contains? home "A postly blog"))
(check-true (string-contains? home "/static/style.css"))

;; permalink pages exist at the yinwang-style paths
(check-true (file-exists? (build-path out "blog" "2026" "11" "05"
                                     "hello-postly" "index.html")))
(check-true (file-exists? (build-path out "blog" "2026" "11" "01"
                                     "second-post" "index.html")))
(check-true (file-exists? (build-path out "blog" "index.html")))

;; dialect renders end-to-end
(define post-html
  (file->string (build-path out "blog" "2026" "11" "05" "hello-postly"
                            "index.html")))
(check-true (string-contains? post-html "callout-tip"))
(check-true (string-contains? post-html "Callout title"))
(check-true (string-contains? post-html "<strong>content</strong>"))
(check-true (string-contains? post-html "another-post")) ; label text, no <a>
(check-false (string-contains? post-html "<a href=\"/p/another-post"))
(check-true (string-contains? post-html "pic.png"))     ; default img src
(check-true (string-contains? post-html "checked"))     ; task list
(check-true (string-contains? post-html "[[raw]]"))     ; code literal

;; pages, feeds, assets
(check-true (file-exists? (build-path out "about" "index.html")))
(check-true (file-exists? (build-path out "products" "index.html")))
(check-true (file-exists? (build-path out "feed.xml")))
(check-true (file-exists? (build-path out "sitemap.xml")))
(check-true (file-exists? (build-path out "static" "style.css")))

(define feed (file->string (build-path out "feed.xml")))
(check-true (string-contains? feed "<rss version=\"2.0\">"))
(check-true (string-contains? feed "https://blog.example.com/blog/2026/11/05/hello-postly/"))

;; explicit site override wins over postly.rkt
(define out2 (make-temporary-file "postly-test2~a" 'directory))
(build! example-dir out2 (site "Custom" "https://custom.example" '()))
(check-true (string-contains? (file->string (build-path out2 "index.html"))
                              "Custom"))

;; wikilink resolution through the pipeline
(parameterize ((current-resolve-wikilink (lambda (t) (format "/p/~a" t))))
  (define out3 (make-temporary-file "postly-test3~a" 'directory))
  (build! example-dir out3)
  (check-true
   (string-contains?
    (file->string (build-path out3 "blog" "2026" "11" "05" "hello-postly"
                              "index.html"))
    "href=\"/p/another-post\"")))
