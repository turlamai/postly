# Hello postly

This is the first post in the example blog. It exercises the whole dialect:

- a **wikilink** to [[another-post]] (unresolvable → plain text)
- an image embed placeholder: ![[pic.png]]
- a ==highlight== and a #racket #postly tag
- [x] a done task

> [!tip] Callout title
> Callout **content** keeps full markdown.

```racket
;; code stays literal: [[raw]] ==raw== #raw ![[raw]]
(displayln "hello")
```
