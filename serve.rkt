#lang racket/base

;; Development preview server: build once, serve the output statically.
;; Re-run `raco postly build` to refresh — no watcher in v0.1 by design
;; (the build is fast enough to just run again).

(require racket/file
         racket/match
         racket/string
         racket/path
         racket/string
         web-server/http
         web-server/servlet
         web-server/servlet-env
         "build.rkt")

(provide serve!)

;; mime-type : path? -> string?
(define (mime-type path)
  (match (path-get-extension path)
    (#".html" "text/html; charset=utf-8")
    (#".xml" "application/xml; charset=utf-8")
    (#".css" "text/css; charset=utf-8")
    (#".js" "text/javascript; charset=utf-8")
    (#".png" "image/png")
    (#".jpg" "image/jpeg")
    (#".jpeg" "image/jpeg")
    (#".gif" "image/gif")
    (#".svg" "image/svg+xml")
    (#".ico" "image/x-icon")
    (#".woff2" "font/woff2")
    (_ "application/octet-stream")))

;; serve! : path? exact-nonnegative-integer? -> void?
(define (serve! content-dir port)
  (define out-dir (make-temporary-file "postly-serve~a" 'directory))
  (build! content-dir out-dir)
  (eprintf "postly: serving ~a on http://localhost:~a/\n" out-dir port)
  (serve/servlet
   (lambda (req)
     (define rel
       (string-join
        (filter (lambda (s) (not (string=? s "")))
                (map path/param-path (url-path (request-uri req))))
        "/"))
     (define candidates
       (if (string=? rel "")
           (list (build-path out-dir "index.html"))
           (list (build-path out-dir rel)
                 (build-path out-dir rel "index.html"))))
     (define file
       (for*/first ((c (in-list candidates))
                    #:when (file-exists? c))
         c))
     (if file
         (response/output
          (lambda (op) (write-bytes (file->bytes file) op))
          #:mime-type (string->bytes/utf-8 (mime-type file)))
         (response/full 404
                        (string->bytes/utf-8
                         "<h1>404</h1><p><a href=\"/\">home</a></p>")
                        (current-seconds)
                        TEXT/HTML-MIME-TYPE
                        '()
                        '())))
   #:servlet-regexp #rx""
   #:port port
   #:command-line? #t))
