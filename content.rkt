#lang racket/base

;; Content scanning: pure-Markdown files in, document records out.
;;
;; No frontmatter, ever. What the engine needs comes from where it is
;; editor-neutral:
;;   title  = the first H1 in the body (else the filename)
;;   date   = the filename's YYYY-MM-DD- prefix (else today)
;;   slug   = the filename without the date prefix and .md extension

(require racket/date
         racket/file
         racket/format
         racket/list
         racket/match
         racket/path
         racket/string
         obsidian
         "config.rkt")

(provide (struct-out doc)
         scan-docs
         post-permalink
         slugify-filename)

;; doc : string? string? (list Y M D) string? (listof string?) path?
;; title may be #f (untitled); body is the raw Markdown source.
(struct doc (slug title date html tags source-path) #:transparent)

;; slugify-filename : path? -> string?
;; Strips a leading YYYY-MM-DD- prefix and the .md extension.
(define (slugify-filename path)
  (define name (path->string (path-replace-extension (file-name-from-path path) #"")))
  (regexp-replace* #px"^[0-9]{4}-[0-9]{2}-[0-9]{2}-" name ""))

;; file-date : path? -> (list Y M D)
;; Filename date prefix wins; otherwise today (simple, predictable).
;; (The doc struct's own accessor is doc-date — hence the different name.)
(define (file-date path)
  (match (regexp-match #px"^([0-9]{4})-([0-9]{2})-([0-9]{2})-"
                       (path->string (file-name-from-path path)))
    ((list _ y m d) (list y m d))
    (_ (today-ymd))))

;; date-desc : (list Y M D) (list Y M D) -> boolean?
;; Newest first, lexicographic on the zero-padded strings.
(define (date-desc a b)
  (string>=? (string-join a "") (string-join b "")))

;; scan-docs : path? -> (listof doc?)
;; Every .md file directly inside dir (no recursion — the layout IS the IA).
(define (scan-docs dir)
  (sort
   (for/list ((p (in-list (directory-list dir #:build? #t)))
              #:when (equal? (path-get-extension p) #".md"))
     (define src (file->string p))
     (doc (slugify-filename p)
          (document-title src)
          (file-date p)
          (obsidian->html src)
          (document-tags src)
          p))
   date-desc
   #:key doc-date
   #:cache-keys? #t))

;; post-permalink : (list Y M D) string? -> string?
;; Yinwang-style date permalink: /blog/YYYY/MM/DD/slug/
(define (post-permalink date slug)
  (match-define (list y m d) date)
  (format "/blog/~a/~a/~a/~a/" y m d slug))
