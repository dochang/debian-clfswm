#!/bin/sh
#
# CLFSWM startup file.  Check /usr/share/doc/clfswm/README.Debian to
# know how to setup the Common Lisp implementation CLFSWM should use.


EVAL_LOAD="(asdf:load-system :clfswm)"
EVAL_RUN="(clfswm:main)"

load_cmucl ()
{
	cmucl -eval '(require :clx) (require :asdf)' -eval "$EVAL_LOAD $EVAL_RUN"
}

load_sbcl ()
{
	sbcl --eval '(require :asdf)' --eval "$EVAL_LOAD" --eval "$EVAL_RUN" --eval '(quit)'
}

load_clisp ()
{
	clisp -x '(require "clx") (require :asdf)' -x "$EVAL_LOAD $EVAL_RUN"
}

if_load ()
{
	if ! which "$1" > /dev/null; then
		echo "$1 is not found."
		exit 1
	else
		"$2"
	fi
}

load_clfswm ()
{
	case "$1" in
		cmucl)
			if_load cmucl load_cmucl
			;;
		sbcl)
			if_load sbcl load_sbcl
			;;
		clisp)
			if_load clisp load_clisp
			;;
		*)
			if_load "clfswm-$1" "clfswm-$1"
			;;
	esac
}

usage ()
{
	echo "usage: $0 [implementation]"
	exit 2
}

main_clfswm ()
{
	local clfswmrc clfswm_impl rc_impl

	if [ $# -gt 1 ]; then
		usage
	fi

	clfswmrc=${XDG_CONFIG_HOME:-$HOME/.config}/clfswm/clfswmrc

	if [ ! -f "$clfswmrc" ]; then
		clfswmrc="$HOME/.clfswmrc"
	fi

	clfswm_impl=${1:-$LISP}

	if [ -z "$clfswm_impl" -a -r "$clfswmrc" ]; then
		rc_impl=$(sed -n '/^.*debian=\([A-Za-z0-9._][A-Za-z0-9._+-]*\).*$/{s//\1/p;q}' "$clfswmrc")
		clfswm_impl=${rc_impl}
	fi

	load_clfswm ${clfswm_impl:-clisp}
}

main_clfswm "$@"
