#lang racket/base

;; postly — a minimal static blog engine.
;;
;;   raco postly build <content-dir> [--out DIR]   build a site
;;   raco postly serve <content-dir> [--port N]    build + preview server

(require racket/cmdline
         racket/match
         racket/string
         "build.rkt"
         "serve.rkt")

(module+ main
  (define out-flag (make-parameter #f))
  (define port (make-parameter 8080))

  ;; Racket's option parser stops at the first positional argument.
  ;; Accept the two documented command forms without changing option values.
  (define argv
    (match (vector->list (current-command-line-arguments))
      ((list* (and mode (or "build" "serve")) content options)
       #:when (not (string-prefix? content "-"))
       (list->vector (append options (list mode content))))
      (_ (current-command-line-arguments))))

  (define-values (mode content-dir-string)
    (command-line
     #:program "postly"
     #:argv argv
     #:once-each
     (("--port") p "Port for serve (default 8080)"
      (define n (string->number p))
      (unless (and (exact-integer? n) (<= 1 n 65535))
        (raise-user-error 'postly "port must be an integer from 1 to 65535"))
      (port n))
     (("--out") o "Output directory for build (default <content-dir>/_site)"
      (out-flag o))
     #:args (mode content) (values mode content)))

  (define content-dir (string->path content-dir-string))

  (match mode
    ("build"
     (define out (or (and (out-flag) (string->path (out-flag)))
                     (build-path content-dir "_site")))
     (build! content-dir out)
     (eprintf "postly: built ~a → ~a\n" content-dir out))
    ("serve"
     (serve! content-dir (port)))
    (other
     (eprintf "postly: unknown mode ~a (use build or serve)\n" other)
     (exit 1))))
