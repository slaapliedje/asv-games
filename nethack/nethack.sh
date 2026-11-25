#!/bin/sh
# nethack - NetHack 5.0 on Atari System V / AMIX.
# Terminal play by default; `nethack -x` plays in an X window with tiles
# (DISPLAY must be set).  Other arguments go to the game.
HACKDIR=/opt/nethack/lib
VAR=/var/opt/nethack
XAPPLRESDIR=$HACKDIR/
XFILESEARCHPATH=$HACKDIR/%N
export HACKDIR XAPPLRESDIR XFILESEARCHPATH
umask 0
[ -d $VAR/save ] || { mkdir $VAR/save; chmod 1777 $VAR/save; }
touch $VAR/record $VAR/logfile $VAR/xlogfile $VAR/livelog $VAR/perm 2>/dev/null
if [ "$1" = -x ]
then
	shift
	NETHACKOPTIONS="windowtype:X11${NETHACKOPTIONS:+,$NETHACKOPTIONS}"
	export NETHACKOPTIONS
fi
cd $HACKDIR
exec $HACKDIR/nethack "$@"
