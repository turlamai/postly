#lang info

(define collection "postly")
(define version "0.1")
(define pkg-desc
  "A minimal static blog engine in Racket: Obsidian Markdown in, a plain HTML site out. Yinwang-style restraint, zero runtime JavaScript.")
(define license '(MIT))

(define deps '("base"
               "markdown"
               "obsidian"
               "web-server-lib"
               "rackunit-lib"))
(define build-deps '("racket-doc"
                     "scribble-lib"))

(define raco-commands
  '(("postly" postly/main "build or serve a postly blog" #f)))

(define test-omit-paths '("test" "example"))
