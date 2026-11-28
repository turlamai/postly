#lang racket/base

;; Development preview server: build once, serve the output statically.
;; Re-run `raco postly build` to refresh — no watcher in v0.1 by design
;; (the build is fast enough to just run again).

(require racket/file
         racket/match
         racket/list
         racket/path
         racket/string
         web-server/http
         web-server/servlet
         web-server/servlet-env
         "build.rkt"
         "config.rkt")

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
    (#".webp" "image/webp")
    (#".avif" "image/avif")
    (#".svg" "image/svg+xml")
    (#".ico" "image/x-icon")
    (#".woff2" "font/woff2")
    (_ "application/octet-stream")))

;; serve! : path? exact-nonnegative-integer? -> void?
(define (serve! content-dir port)
  (define out-dir (make-temporary-file "postly-serve~a" 'directory))
  (define st (load-site content-dir))
  (define mount (site-path st "/"))
  (define prefix (string-split mount "/"))
  (build! content-dir out-dir st)
  (eprintf "postly: serving ~a on http://localhost:~a~a\n" out-dir port mount)
  (serve/servlet
   (lambda (req)
     (define parts
       (filter non-empty-string?
               (map path/param-path (url-path (request-uri req)))))
     (define file
       (and (list-prefix? prefix parts)
            (andmap (lambda (part)
                      (and (not (member part '("." "..")))
                           (not (string-contains? part "/"))
                           (not (string-contains? part "\\"))
                           (not (string-contains? part (string #\nul)))))
                    parts)
            (let* ((relative (drop parts (length prefix)))
                   (path (apply build-path out-dir relative))
                   (candidate (if (directory-exists? path)
                                  (build-path path "index.html")
                                  path)))
              (and (file-exists? candidate) candidate))))
     (if file
         (response/output
          (lambda (op) (write-bytes (file->bytes file) op))
          #:mime-type (string->bytes/utf-8 (mime-type file)))
         (response/full 404
                        (string->bytes/utf-8
                         (format "<h1>404</h1><p><a href=\"~a\">home</a></p>" mount))
                        (current-seconds)
                        TEXT/HTML-MIME-TYPE
                        '()
                        '())))
   #:servlet-regexp #rx""
   #:listen-ip "127.0.0.1"
   #:port port
   #:command-line? #t))
