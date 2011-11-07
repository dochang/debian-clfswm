(in-package :cl-user)

#+clisp
(require "clx")

#+cmu
(require :clx)

#-asdf
(require :asdf #+clisp '(#P"/usr/share/common-lisp/source/cl-asdf/asdf.lisp"))

;; Hot-upgrade ASDF.
;;
;; It's useful if user has a local version of ASDF.
;;
;; Currently only available in ASDF2.
#+asdf2
(asdf:oos 'asdf:load-op :asdf)

;; Cleanups after hot-upgrade.
#+asdf2
(asdf:clear-configuration)

(asdf:oos 'asdf:load-op :clfswm)

(clfswm:main)

#+(or clisp sbcl cmu)
(quit)
