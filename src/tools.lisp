;;; --------------------------------------------------------------------------
;;; CLFSWM - FullScreen Window Manager
;;;
;;; --------------------------------------------------------------------------
;;; Documentation: General tools
;;; --------------------------------------------------------------------------
;;;
;;; (C) 2005 Philippe Brochard <hocwp@free.fr>
;;;
;;; This program is free software; you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or
;;; (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program; if not, write to the Free Software
;;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;;;
;;; --------------------------------------------------------------------------


(in-package :common-lisp-user)

(defpackage tools
  (:use common-lisp)
  (:export :it
	   :awhen
	   :aif
	   :call-hook
	   :dbg
	   :dbgnl
	   :setf/=
	   :create-symbol
	   :split-string
	   :expand-newline
	   :ensure-list
	   :ensure-printable
	   :ensure-n-elems
	   :string-equal-p
	   :find-assoc-word
	   :print-space
	   :escape-string
	   :first-position
	   :find-free-number
	   :date-string
	   :do-execute
	   :do-shell
	   :getenv
	   :uquit
	   :urun-prog
	   :ushell
	   :ush
	   :ushell-loop
	   :cldebug
	   :get-command-line-words
	   :string-to-list
	   :near-position
	   :string-to-list-multichar
	   :list-to-string
	   :list-to-string-list
	   :clean-string
	   :one-in-list
	   :exchange-one-in-list
	   :rotate-list
	   :anti-rotate-list
	   :append-formated-list
	   :shuffle-list
	   :parse-integer-in-list
	   :convert-to-number
	   :next-in-list :prev-in-list
	   :find-string
	   :find-all-strings
	   :subst-strings
	   :test-find-string))

	    
(in-package :tools)


(setq *random-state* (make-random-state t))



(defmacro awhen (test &body body)
  `(let ((it ,test))
     (when it
       ,@body)))

(defmacro aif (test then &optional else)
  `(let ((it ,test)) (if it ,then ,else)))


;;;,-----
;;;| Minimal hook
;;;`-----
(defun call-hook (hook &optional args)
  "Call a hook (a function, a symbol or a list of functions)
Return the result of the last hook"
  (let ((result nil))
    (labels ((rec (hook)
	       (when hook
		 (typecase hook
		   (cons (dolist (h hook)
			   (rec h)))
		   (t (setf result (apply hook args)))))))
      (rec hook)
      result)))



;;;,-----
;;;| Debuging tools
;;;`-----
(defvar *%dbg-name%* "dbg")
(defvar *%dbg-count%* 0)


(defmacro dbg (&rest forms)
  `(progn
     ,@(mapcar #'(lambda (form)
		   (typecase form
		     (string `(setf *%dbg-name%* ,form))
		     (number `(setf *%dbg-count%* ,form))))
	       forms)
     (format t "~&DEBUG[~A - ~A]  " (incf *%dbg-count%*) *%dbg-name%*)
     ,@(mapcar #'(lambda (form)
		   (typecase form
		     ((or string number) nil)
		     (t `(format t "~A=~S   " ',form ,form))))
	       forms)
     (format t "~%")
     (force-output)
     ,@forms))

(defmacro dbgnl (&rest forms)
  `(progn
     ,@(mapcar #'(lambda (form)
		   (typecase form
		     (string `(setf *%dbg-name%* ,form))
		     (number `(setf *%dbg-count%* ,form))))
	       forms)
     (format t "~&DEBUG[~A - ~A] --------------------~%" (incf *%dbg-count%*) *%dbg-name%*)
     ,@(mapcar #'(lambda (form)
		   (typecase form
		     ((or string number) nil)
		     (t `(format t "  -  ~A=~S~%" ',form ,form))))
	       forms)
     (force-output)
     ,@forms))






;;; Tools


(defmacro setf/= (var val)
  "Set var to val only when var not equal to val"
  (let ((gval (gensym)))
    `(let ((,gval ,val))
       (when (/= ,var ,gval)
	 (setf ,var ,gval)))))


(defun create-symbol (&rest names)
  "Return a new symbol from names"
  (intern (string-upcase (apply #'concatenate 'string names))))


(defun split-string (string &optional (separator #\Space))
  "Return a list from a string splited at each separators"
  (loop for i = 0 then (1+ j)
     as j = (position separator string :start i)
     as sub = (subseq string i j)
     unless (string= sub "") collect sub
     while j))


(defun expand-newline (list)
  "Expand all newline in strings in list"
  (let ((acc nil))
    (dolist (l list)
      (setf acc (append acc (split-string l #\Newline))))
    acc))

(defun ensure-list (object)
  "Ensure an object is a list"
  (if (listp object)
      object
      (list object)))


(defun ensure-printable (string &optional (new #\?))
  "Ensure a string is printable in ascii"
  (or (substitute-if-not new #'standard-char-p (or string "")) ""))


(defun ensure-n-elems (list n)
  "Ensure that list has exactly n elements"
  (let ((length (length list)))
    (cond ((= length n) list)
	  ((< length n) (ensure-n-elems (append list '(nil)) n))
	  ((> length n) (ensure-n-elems (butlast list) n)))))

(defun string-equal-p (x y)
  (when (stringp y) (string-equal x y)))




(defun find-assoc-word (word line &optional (delim #\"))
  "Find a word pair"
  (let* ((pos (search word line))
	 (pos-1 (position delim line :start (or pos 0)))
	 (pos-2 (position delim line :start (1+ (or pos-1 0)))))
    (when (and pos pos-1 pos-2)
      (subseq line (1+ pos-1) pos-2))))
    

(defun print-space (n &optional (stream *standard-output*))
  "Print n spaces on stream"
  (dotimes (i n)
    (princ #\Space stream)))


(defun escape-string (string &optional (escaper '(#\/ #\: #\) #\( #\Space #\; #\,)) (char #\_))
  "Replace in string all characters found in the escaper list"
  (if escaper
      (escape-string (substitute char (car escaper) string) (cdr escaper) char)
      string))



(defun first-position (word string)
  "Return true only if word is at position 0 in string"
  (zerop (or (search word string) -1)))


(defun find-free-number (l)		; stolen from stumpwm - thanks
  "Return a number that is not in the list l."
  (let* ((nums (sort l #'<))
	 (new-num (loop for n from 0 to (or (car (last nums)) 0)
		     for i in nums
		     when (/= n i)
		     do (return n))))
    (if new-num
	new-num
	;; there was no space between the numbers, so use the last + 1
	(if (car (last nums))
	    (1+ (car (last nums)))
	    0))))





;;; Shell part (taken from ltk)
(defun do-execute (program args &optional (wt nil))
  "execute program with args a list containing the arguments passed to
the program   if wt is non-nil, the function will wait for the execution
of the program to return.
   returns a two way stream connected to stdin/stdout of the program"
  (let ((fullstring program))
    (dolist (a args)
      (setf fullstring (concatenate 'string fullstring " " a)))
    #+:cmu (let ((proc (ext:run-program program args :input :stream
							    :output :stream :wait wt)))
             (unless proc
               (error "Cannot create process."))
             (make-two-way-stream
              (ext:process-output proc)
              (ext:process-input proc)))
    #+:clisp (let ((proc (ext:run-program program :arguments args
						  :input :stream :output
						  :stream :wait (or wt t))))
	       (unless proc
		 (error "Cannot create process."))
	       proc)
    #+:sbcl (let ((proc (sb-ext:run-program program args :input
							 :stream :output
							 :stream :wait wt)))
	      (unless proc
		(error "Cannot create process."))
	      (make-two-way-stream 
	       (sb-ext:process-output proc)              
	       (sb-ext:process-input proc)))
    #+:lispworks (system:open-pipe fullstring :direction :io)
    #+:allegro (let ((proc (excl:run-shell-command
			    (apply #'vector program program args)
			    :input :stream :output :stream :wait wt)))
		 (unless proc
		   (error "Cannot create process."))   
		 proc)
    #+:ecl(ext:run-program program args :input :stream :output :stream
			   :error :output)
    #+:openmcl (let ((proc (ccl:run-program program args :input
							 :stream :output
							 :stream :wait wt)))
		 (unless proc
		   (error "Cannot create process."))
		 (make-two-way-stream
		  (ccl:external-process-output-stream proc)
		  (ccl:external-process-input-stream proc)))))

(defun do-shell (program &optional args (wt nil))
  (do-execute "/bin/sh" `("-c" ,program ,@args) wt))







(defun getenv (var)
  "Return the value of the environment variable."
  #+allegro (sys::getenv (string var))
  #+clisp (ext:getenv (string var))
  #+(or cmu scl)
  (cdr (assoc (string var) ext:*environment-list* :test #'equalp
              :key #'string))
  #+gcl (si:getenv (string var))
  #+lispworks (lw:environment-variable (string var))
  #+lucid (lcl:environment-variable (string var))
  #+mcl (ccl::getenv var)
  #+sbcl (sb-posix:getenv (string var))
  #-(or allegro clisp cmu gcl lispworks lucid mcl sbcl scl)
  (error 'not-implemented :proc (list 'getenv var)))


(defun (setf getenv) (val var)
  "Set an environment variable."
  #+allegro (setf (sys::getenv (string var)) (string val))
  #+clisp (setf (ext:getenv (string var)) (string val))
  #+(or cmu scl)
  (let ((cell (assoc (string var) ext:*environment-list* :test #'equalp
							 :key #'string)))
    (if cell
        (setf (cdr cell) (string val))
        (push (cons (intern (string var) "KEYWORD") (string val))
              ext:*environment-list*)))
  #+gcl (si:setenv (string var) (string val))
  #+lispworks (setf (lw:environment-variable (string var)) (string val))
  #+lucid (setf (lcl:environment-variable (string var)) (string val))
  #+sbcl (sb-posix:putenv (format nil "~A=~A" (string var) (string val)))
  #-(or allegro clisp cmu gcl lispworks lucid sbcl scl)
  (error 'not-implemented :proc (list '(setf getenv) var)))







(defun uquit ()
  #+(or clisp cmu) (ext:quit)
  #+sbcl (sb-ext:quit)
  #+ecl (si:quit)
  #+gcl (lisp:quit)
  #+lispworks (lw:quit)
  #+(or allegro-cl allegro-cl-trial) (excl:exit))
  
  


(defun remove-plist (plist &rest keys)
  "Remove the keys from the plist.
Useful for re-using the &REST arg after removing some options."
  (do (copy rest)
      ((null (setq rest (nth-value 2 (get-properties plist keys))))
       (nreconc copy plist))
    (do () ((eq plist rest))
      (push (pop plist) copy)
      (push (pop plist) copy))
    (setq plist (cddr plist))))




(defun urun-prog (prog &rest opts &key args (wait t) &allow-other-keys)
  "Common interface to shell. Does not return anything useful."
  #+gcl (declare (ignore wait))
  (setq opts (remove-plist opts :args :wait))
  #+allegro (apply #'excl:run-shell-command (apply #'vector prog prog args)
                   :wait wait opts)
  #+(and clisp      lisp=cl)
  (apply #'ext:run-program prog :arguments args :wait wait opts)
  #+(and clisp (not lisp=cl))
  (if wait
      (apply #'lisp:run-program prog :arguments args opts)
      (lisp:shell (format nil "~a~{ '~a'~} &" prog args)))
  #+cmu (apply #'ext:run-program prog args :wait wait :output *standard-output* opts)
  #+gcl (apply #'si:run-process prog args)
  #+liquid (apply #'lcl:run-program prog args)
  #+lispworks (apply #'sys::call-system-showing-output
                     (format nil "~a~{ '~a'~}~@[ &~]" prog args (not wait))
                     opts)
  #+lucid (apply #'lcl:run-program prog :wait wait :arguments args opts)
  #+sbcl (apply #'sb-ext:run-program prog args :wait wait :output *standard-output* opts)
  #-(or allegro clisp cmu gcl liquid lispworks lucid sbcl)
  (error 'not-implemented :proc (list 'run-prog prog opts)))


;;(defparameter *shell-cmd* "/usr/bin/env")
;;(defparameter *shell-cmd-opt* nil)

#+UNIX (defparameter *shell-cmd* "/bin/sh")
#+UNIX (defparameter *shell-cmd-opt* '("-c"))

#+WIN32 (defparameter *shell-cmd* "cmd.exe")
#+WIN32 (defparameter *shell-cmd-opt* '("/C"))


(defun ushell (&rest strings)
  (urun-prog *shell-cmd* :args (append *shell-cmd-opt* strings)))

(defun ush (string)
  (urun-prog *shell-cmd* :args (append *shell-cmd-opt* (list string))))


(defun set-shell-dispatch (&optional (shell-fun 'ushell))
  (labels ((|shell-reader| (stream subchar arg)
	     (declare (ignore subchar arg))
	     (list shell-fun (read stream t nil t))))
    (set-dispatch-macro-character #\# #\# #'|shell-reader|)))


(defun ushell-loop (&optional (shell-fun #'ushell))
  (loop
     (format t "UNI-SHELL> ")
     (let* ((line (read-line)))
       (cond ((zerop (or (search "quit" line) -1)) (return))
	     ((zerop (or (position #\! line) -1))
	      (funcall shell-fun (subseq line 1)))
	     (t (format t "~{~A~^ ;~%~}~%"
			(multiple-value-list 
			 (ignore-errors (eval (read-from-string line))))))))))






(defun cldebug (&rest rest)
  (princ "DEBUG: ")
  (dolist (i rest)
    (princ i))
  (terpri))


(defun get-command-line-words ()
  #+CLISP ext:*args*
  #+CMU (nthcdr 3 extensions:*command-line-strings*)
  #+SBCL sb-ext:*posix-argv*)



(defun string-to-list (str &key (split-char #\space))
  (do* ((start 0 (1+ index))
	(index (position split-char str :start start)
	       (position split-char str :start start))
	(accum nil))
       ((null index)
	(unless (string= (subseq str start) "")
	  (push (subseq str start) accum))
	(nreverse accum))
    (when (/= start index)
      (push (subseq str start index) accum))))


(defun near-position (chars str &key (start 0))
  (do* ((char chars (cdr char))
	(pos (position (car char) str :start start)
	     (position (car char) str :start start))
	(ret (when pos pos)
	     (if pos
		 (if ret
		     (if (< pos ret)
			 pos
			 ret)
		     pos)
		 ret)))
       ((null char) ret)))

  
;;;(defun near-position2 (chars str &key (start 0))
;;;  (loop for i in chars
;;;	minimize (position i str :start start)))

;;(format t "~S~%" (near-position '(#\! #\. #\Space #\;) "klmsqk ppii;dsdsqkl.jldfksj lkm" :start 0))
;;(format t "~S~%" (near-position '(#\Space) "klmsqk ppii;dsdsqkl.jldfksj lkm" :start 0))
;;(format t "~S~%" (near-position '(#\; #\l #\m) "klmsqk ppii;dsdsqkl.jldfksj lkm" :start 0))
;;(format t "result=~S~%" (string-to-list-multichar "klmsqk ppii;dsdsqkl.jldfksj lkm" :preserve t))
;;(format t "result=~S~%" (string-to-list-multichar "klmsqk ppii;dsd!sqkl.jldfksj lkm"
;;						  :split-chars '(#\k  #\! #\. #\; #\m)
;;						  :preserve nil))


(defun string-to-list-multichar (str &key (split-chars '(#\space)) (preserve nil))
  (do* ((start 0 (1+ index))
	(index (near-position split-chars str :start start)
	       (near-position split-chars str :start start))
	(accum nil))
       ((null index)
	(unless (string= (subseq str start) "")
	  (push (subseq str start) accum))
	(nreverse accum))
    (let ((retstr (subseq str start (if preserve (1+ index) index))))
      (unless (string= retstr "")
	(push retstr accum)))))





(defun list-to-string (lst)
  (string-trim " () " (format nil "~A" lst)))



(defun clean-string (string)
  "Remove Newline and upcase string"
  (string-upcase
   (string-right-trim '(#\Newline) string)))

(defun one-in-list (lst)
  (nth (random (length lst)) lst))

(defun exchange-one-in-list (lst1 lst2)
  (let ((elem1 (one-in-list lst1))
	(elem2 (one-in-list lst2)))
    (setf lst1 (append (remove elem1 lst1) (list elem2)))
    (setf lst2 (append (remove elem2 lst2) (list elem1)))
    (values lst1 lst2)))


(defun rotate-list (list)
  (when list
    (append (cdr list) (list (car list)))))

(defun anti-rotate-list (list)
  (when list
    (append (last list) (butlast list))))


(defun append-formated-list (base-str
			     lst 
			     &key (test-not-fun #'(lambda (x) x nil))
			     (print-fun #'(lambda (x) x))
			     (default-str ""))
  (let ((str base-str) (first t))
    (dolist (i lst)
      (cond ((funcall test-not-fun i) nil)
	    (t (setq str 
		     (concatenate 'string str
				  (if first "" ", ")
				  (format nil "~A"
					  (funcall print-fun i))))
	       (setq first nil))))
    (if (string= base-str str)
	(concatenate 'string str default-str) str)))


(defun shuffle-list (list &key (time 1))
  "Shuffle a list by swapping elements time times"
  (let ((result (copy-list list))
	(ind1 0) (ind2 0) (swap 0))
    (dotimes (i time)
      (setf ind1 (random (length result)))
      (setf ind2 (random (length result)))

      (setf swap (nth ind1 result))
      (setf (nth ind1 result) (nth ind2 result))
      (setf (nth ind2 result) swap))
    result))



(defun convert-to-number (str)
  (cond ((stringp str) (parse-integer str :junk-allowed t))
	((numberp str) str)))

(defun parse-integer-in-list (lst)
  "Convert all integer string in lst to integer"
  (mapcar #'(lambda (x) (convert-to-number x)) lst))



(defun next-in-list (item lst)
  (do ((x lst (cdr x)))
      ((null x))
    (when (equal item (car x))
      (return (if (cadr x) (cadr x) (car lst))))))

(defun prev-in-list (item lst)
  (next-in-list item (reverse lst)))


(let ((jours '("Lundi" "Mardi" "Mercredi" "Jeudi" "Vendredi" "Samedi" "Dimanche"))
      (mois '("Janvier" "Fevrier" "Mars" "Avril" "Mai" "Juin" "Juillet"
	      "Aout" "Septembre" "Octobre" "Novembre" "Decembre"))
      (days '("Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday"))
      (months '("January" "February" "March" "April" "May" "June" "July"
		 "August" "September" "October" "November" "December")))
  (defun date-string ()
    (multiple-value-bind (second minute hour date month year day)
	(get-decoded-time)
      (if (search "fr" (getenv "LANG") :test #'string-equal)
	  (format nil "   ~2,'0D:~2,'0D:~2,'0D    ~A ~2,'0D ~A ~A "
		  hour minute second
		  (nth day jours) date (nth (1- month) mois) year)
	  (format nil "   ~2,'0D:~2,'0D:~2,'0D    ~A ~A ~2,'0D ~A "
		  hour minute second
		  (nth day days) (nth (1- month) months) date year)))))

