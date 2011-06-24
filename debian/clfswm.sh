#!/bin/sh
#
# CLFSWM startup file.  Check /usr/share/doc/clfswm/README.Debian to
# know how to setup the Common Lisp implementation CLFSWM should use.


LOADER="/usr/lib/clfswm/load.lisp"

load_clfswm ()
{
	case "$1" in
		cmucl)
			cmucl -load "$LOADER"
			;;
		sbcl)
			sbcl --load "$LOADER"
			;;
		clisp)
			clisp "$LOADER"
			;;
		*)
			"clfswm-$1"
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
