#lang racket/base
;; postly.rkt — site configuration. Optional: absent file = defaults.
;; Must provide `config`.
(provide config)
(define config
  (hasheq 'title "A postly blog"
          'base-url "https://blog.example.com"
          'nav '(("文章" . "/blog/")
                 ("关于" . "/about/")
                 ("产品" . "/products/")
                 ("订阅" . "/feed.xml"))))
