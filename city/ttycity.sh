#!/bin/sh
# ttycity - Micropolis in a terminal, on Atari System V / AMIX.
# TERM=xterm-color gives 8 colours; the system has no such entry, so the
# one that came with the package is used unless the system has its own.
SIMHOME=/opt/ttycity/share
export SIMHOME
if [ "$TERM" = xterm-color ] && [ ! -f /usr/share/lib/terminfo/x/xterm-color ]
then
	TERMINFO=/opt/ttycity/share/terminfo
	export TERMINFO
fi
exec /opt/ttycity/lib/ttycity "$@"
