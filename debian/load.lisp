(in-package :cl-user)

#+clisp
(require "clx")

#+cmu
(require :clx)

#-asdf
(require :asdf #+clisp '(#P"/usr/share/common-lisp/source/cl-asdf/asdf.lisp"))

(asdf:oos 'asdf:load-op :clfswm)

(clfswm:main)

#+(or clisp sbcl cmu)
(quit)
