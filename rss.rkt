#lang racket/base

;; RSS 2.0 and sitemap.xml generation. Hand-written output: the catalog's
;; `feed` package parses feeds, it doesn't write them, and a blog's feed is
;; a few dozen lines of XML.

(require racket/list
         racket/match
         racket/string
         "config.rkt"
         "content.rkt")

(provide rss-xml
         sitemap-xml)

;; xml-escape : string? -> string?
(define (xml-escape s)
  (string-append*
   (for/list ((c (in-string s)))
     (match c
       (#\& "&amp;")
       (#\< "&lt;")
       (#\> "&gt;")
       (#\" "&quot;")
       (_ (string c))))))

;; date->rfc822 : (list Y M D) -> string?
(define (date->rfc822 ymd)
  (match-define (list y m d) ymd)
  (define month-names
    '("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"))
  (format "~a, ~a ~a ~a 12:00:00 +0800"
          "Tue" d (list-ref month-names (sub1 (string->number m))) y))

;; rss-xml : site? (listof doc?) -> string?
(define (rss-xml st posts)
  (string-append
   "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
   "<rss version=\"2.0\">\n<channel>\n"
   "<title>" (xml-escape (site-title st)) "</title>\n"
   "<link>" (xml-escape (site-base-url st)) "/</link>\n"
   "<description>" (xml-escape (site-title st)) "</description>\n"
   "<language>zh-cn</language>\n"
   (string-append*
    (for/list ((d (in-list (take posts (min 20 (length posts))))))
      (format "<item>\n<title>~a</title>\n<link>~a~a</link>\n<pubDate>~a</pubDate>\n<guid>~a~a</guid>\n<description>~a</description>\n</item>\n"
              (xml-escape (or (doc-title d) (doc-slug d)))
              (site-base-url st)
              (post-permalink (doc-date d) (doc-slug d))
              (date->rfc822 (doc-date d))
              (site-base-url st)
              (post-permalink (doc-date d) (doc-slug d))
              (xml-escape (doc-slug d)))))
   "</channel>\n</rss>\n"))

;; sitemap-xml : site? (listof doc?) -> string?
(define (sitemap-xml st posts)
  (string-append
   "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
   "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n"
   (string-append*
    (for/list ((path (in-list (cons "/"
                                   (cons "/blog/"
                                         (for/list ((d (in-list posts)))
                                           (post-permalink (doc-date d) (doc-slug d))))))))
      (format "<url><loc>~a~a</loc></url>\n"
              (xml-escape (site-base-url st)) path)))
   "</urlset>\n"))
