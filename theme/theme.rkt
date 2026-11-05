#lang racket/base

;; The default theme: Yinwang-style restraint at an Apple-HIG bar.
;; One 38em column, system font stack, automatic dark mode, zero runtime
;; JavaScript.
;;
;; Pages are xexpr trees with one extension: (raw <string>) splices trusted
;; HTML verbatim (the rendered body of a Markdown document). The renderer
;; here is deliberately tiny — raw passthrough and void tags are all it
;; needs beyond the standard xexpr shape.

(require racket/format
         racket/list
         racket/match
         racket/string
         "../config.rkt"
         "../content.rkt")

(provide page-shell
         page->html
         post-page
         index-page
         blog-index-page
         plain-page)

;; ---------------------------------------------------------------------------
;; rendering
;; ---------------------------------------------------------------------------

(define void-tags '(img br hr input meta link area col embed source wbr))

(define (escape-html s)
  (string-append*
   (for/list ((c (in-string s)))
     (match c
       (#\& "&amp;")
       (#\< "&lt;")
       (#\> "&gt;")
       (#\" "&quot;")
       (_ (string c))))))

(define (attrs->html attrs)
  (string-append*
   (for/list ((a (in-list attrs)))
     (format " ~a=\"~a\"" (car a) (escape-html (format "~a" (second a)))))))

;; x->html : any/c -> string?
(define (x->html x)
  (cond
    ((string? x) (escape-html x))
    ((and (pair? x) (eq? (car x) 'raw)) (second x))
    ((pair? x)
     (match x
       ((list tag attrs elems ...)
        (define open (string-append "<" (symbol->string tag)
                                    (attrs->html attrs) ">"))
        (if (memq tag void-tags)
            open
            (string-append open
                           (apply string-append (map x->html elems))
                           "</" (symbol->string tag) ">")))))
    (else "")))

;; page->html : any/c -> string?
;; Takes the single document element produced by the layout functions.
(define (page->html page)
  (string-append "<!DOCTYPE html>\n" (x->html page)))

;; ---------------------------------------------------------------------------
;; layout
;; ---------------------------------------------------------------------------

;; page-shell : site? (or/c string? #f) (listof any/c) -> (listof any/c)
;; A complete document as xexpr elements.
(define (page-shell st title content)
  (define t (or title (site-title st)))
  `(html ((lang "zh-CN"))
         (head ()
               (meta ((charset "utf-8")))
               (meta ((name "viewport")
                      (content "width=device-width, initial-scale=1")))
               (meta ((name "color-scheme") (content "light dark")))
               (title () ,t)
               (link ((rel "stylesheet") (href "/static/style.css")))
               (link ((rel "alternate") (type "application/rss+xml")
                      (title ,(site-title st)) (href "/feed.xml"))))
         (body ()
               (header ((class "site-header"))
                       (nav ((class "site-nav"))
                            (a ((class "site-title") (href "/"))
                               ,(site-title st))
                            ,@(for/list ((entry (in-list (site-nav st))))
                                `(a ((href ,(cdr entry))) ,(car entry)))))
               (main () ,@content)
               (footer ((class "site-footer"))
                       (p () "© " ,(site-title st)
                          " · " (a ((href "/feed.xml")) "RSS"))))))

;; post-page : site? doc? -> (listof any/c)
(define (post-page st d)
  (define t (doc-title d))
  (define ts (doc-tags d))
  (page-shell
   st t
   `((article ()
              (header ((class "post-header"))
                      (p ((class "post-date"))
                         ,(string-join (doc-date d) "-"))
                      (h1 ((class "post-title")) ,(or t "（无标题）")))
              (raw ,(doc-html d))
              ,@(if (null? ts)
                    '()
                    `((footer ((class "post-tags"))
                              ,@(for/list ((tag (in-list ts)))
                                  `(span ((class "tag")) "#" ,tag)))))))))

;; index-page : site? (listof doc?) exact-nonnegative-integer? -> (listof any/c)
;; The homepage: recent posts listed plain — a date, a title, a link.
(define (index-page st posts n)
  (page-shell
   st #f
   `((section ((class "post-list"))
              (h2 () "最近文章")
              (ul ((class "post-list-items"))
                  ,@(for/list ((d (in-list (take posts (min n (length posts))))))
                      `(li ()
                           (span ((class "post-date"))
                                 ,(string-join (doc-date d) "-"))
                           (a ((href ,(post-permalink (doc-date d) (doc-slug d))))
                              ,(or (doc-title d) (doc-slug d))))))
              ,@(if (> (length posts) n)
                    `((p () (a ((href "/blog/")) "全部文章 →")))
                    '())))))

;; blog-index-page : site? (listof doc?) -> (listof any/c)
(define (blog-index-page st posts)
  (page-shell
   st "文章"
   `((h1 () "文章")
     (ul ((class "post-list-items"))
         ,@(for/list ((d (in-list posts)))
             `(li ()
                  (span ((class "post-date")) ,(string-join (doc-date d) "-"))
                  (a ((href ,(post-permalink (doc-date d) (doc-slug d))))
                     ,(or (doc-title d) (doc-slug d)))))))))

;; plain-page : site? string? string? -> (listof any/c)
;; A standalone page (about, products) from a rendered Markdown body.
(define (plain-page st page-title body-html)
  (page-shell
   st page-title
   `((article ()
              (h1 () ,page-title)
              (raw ,(string-append body-html "\n"))))))
