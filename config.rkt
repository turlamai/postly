#lang racket/base

;; Site configuration. Deliberately tiny: a handful of values, no YAML, no
;; frontmatter dependency — the content files stay pure Markdown and the
;; site config lives in one Racket file (postly.rkt in the content root).

(require racket/date
         racket/format
         racket/list
         racket/string)

(provide (struct-out site)
         default-site
         site-args->site
         today-ymd)

;; site : string? string? (listof (cons/c string? string?)) -> site?
;; title = site name shown in the header; base-url = canonical origin
;; (no trailing slash); nav = label -> url pairs, rendered in order.
(struct site (title base-url nav) #:transparent)

(define (default-site)
  (site "A postly blog"
        "https://example.com"
        '(("文章" . "/blog/") ("订阅" . "/feed.xml"))))

;; site-args->site : (or/c #f (hash/c symbol? any/c)) -> site?
;; Accepts the hash a user postly.rkt typically builds with `hasheq`.
;; Missing keys fall back to the defaults; the file itself is optional.
(define (site-args->site args)
  (if (not args)
      (default-site)
      (site (hash-ref args 'title (site-title (default-site)))
            (string-trim (hash-ref args 'base-url (site-base-url (default-site)))
                         "/" #:left? #f)
            (hash-ref args 'nav (site-nav (default-site))))))

;; today-ymd : -> (listof string?)  ; (Y M D) strings, zero padded
(define (today-ymd)
  (define d (seconds->date (current-seconds) #f))
  (list (~a (date-year d))
        (~r (date-month d) #:min-width 2 #:pad-string "0")
        (~r (date-day d) #:min-width 2 #:pad-string "0")))
