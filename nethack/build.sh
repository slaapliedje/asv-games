#!/bin/bash
# build.sh [x11] - NetHack 5.0 as a static AMIX program (runs on Atari System V
# through the amx module), cross-built on the PC.  Needs ../fetch.sh run
# first (it builds NetHack natively: data files, date.h, tile.c).
set -e
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../common/env.sh"; C=$here/../common
src=$here/../upstream/nethack
obj=$here/../build/nethack-obj${1:+-$1}${TAG:+-$TAG}; out=$here/../build/nethack${1:+-$1}${TAG:+-$TAG}
mkdir -p "$obj"
HACKDIR=${HACKDIR:-/opt/nethack/lib}; VARDIR=${VARDIR:-/var/opt/nethack}
core="allmain alloc apply artifact attrib ball bones botl calendar cfgfiles cmd coloratt date dbridge decl detect dig display dlb dogmove dog dokick do_name do dothrow do_wear drawing dungeon earlyarg eat end engrave exper explode extralev files fountain getline getpos glyphs hacklib hack iactions insight invent isaac64 light lock mail makemon mcastu mdlib mhitm mhitu minion mklev mkmap mkmaze mkobj mkroom mondata monmove mon monst mplayer mthrowu muse music nhlobj nhlsel nhlua nhmd4 objects objnam o_init options pager pickup pline polyself potion pray priest quest questpgr read rect region report restore revision rip rnd role rumors save selvar sfbase sfstruct shknam shk sit sounds spell sp_lev stairs steal steed strutil symbols sys teleport timeout topten track trap uhitm u_init utf8map vault version vision weapon were wield windows wizard wizcmds worm worn write zap"
sysobjs="ioctl unixmain unixres unixtty unixunix pmatchregex"
tty="getline termcap topl wintty"
x11="Window dialogs winX winmap winmenu winmesg winmisc winstat wintext winval winlabel tile tileset bmptiles giftiles"
lua=$(cd "$src/nhlua/lua/src" && ls *.c | grep -v -e '^lua\.c' -e '^luac\.c' | sed 's/\.c$//' | tr '\n' ' ')
wins="$tty"; WDEF='-DDEFAULT_WINDOW_SYS=\"tty\"'; XLIBS=
if [ "$1" = x11 ]; then
	wins="$tty $x11"; WDEF='-DX11_GRAPHICS -DUSE_XPM -I'$here'/../build/xpm/include -DDEFAULT_WINDOW_SYS=\"tty\"'
	XLIBS="-lXaw -lXmu -lXt -lXext $here/../build/xpm/libXpm.a -lX11 -lsocket"
fi
CF="-m68030 -m68881 ${OPT:--O1} -fomit-frame-pointer -std=gnu99 -include $C/nhfix.h \
 -I$C/include -I$src/include -I$src/nhlua/lua/src -I$src/sys/unix -I$src/win/share \
 -DAMIX_ASV -DDLB -DHACKDIR=\\\"$HACKDIR\\\" -DVAR_PLAYGROUND=\\\"$VARDIR\\\" $WDEF -DSYSCF -DSYSCF_FILE=\\\"$HACKDIR/sysconf\\\" \
 -DNOMAIL -DDUMPLOG -DCONFIG_ERROR_SECURE=FALSE -DCROSSCOMPILE -DCROSSCOMPILE_TARGET \
 -Wno-incompatible-pointer-types -Wno-implicit-int"
{
	echo "CC=$NHCC"; echo "CF=$CF"; echo "O=$obj"
	all=
	for n in $core $sysobjs $wins; do
		f=$(ls "$src/src/$n.c" "$src/sys/unix/$n.c" "$src/sys/share/$n.c" "$src/win/tty/$n.c" "$src/win/X11/$n.c" "$src/win/share/$n.c" 2>/dev/null | head -1)
		[ -n "$f" ] || { echo "no source for $n" >&2; exit 1; }
		all="$all \$(O)/$n.o"
		xf=; case "$f" in */win/X11/*) xf="-DX11_BUILD -include $here/x11r4.h";; esac
		printf '$(O)/%s.o: %s\n\t@echo %s; $(CC) $(CF) %s -c %s -o $@\n' "$n" "$f" "$n" "$xf" "$f"
	done
	for n in $lua; do
		all="$all \$(O)/lua_$n.o"
		printf '$(O)/lua_%s.o: %s\n\t@echo lua %s; $(CC) $(CF) -c %s -o $@\n' "$n" "$src/nhlua/lua/src/$n.c" "$n" "$src/nhlua/lua/src/$n.c"
	done
	printf '$(O)/rt.o: %s\n\t$(CC) -m68030 -m68881 -O2 -std=gnu99 -c %s -o $@\n' "$C/rt.c" "$C/rt.c"
	printf '$(O)/sysv_rt.o: %s\n\t$(CC) -m68030 -m68881 -O2 -std=gnu99 -c %s -o $@\n' "$MANX/os/sysv4/sysv_rt.c" "$MANX/os/sysv4/sysv_rt.c"
	echo "all: $all \$(O)/rt.o \$(O)/sysv_rt.o"
} > "$obj/Makefile"
make -k -j"$(nproc)" -f "$obj/Makefile" all > "$out.build.log" 2>&1 || { echo "compile errors: see $out.build.log"; exit 1; }
"$NHLD" -o "$out" "$obj"/*.o $XLIBS -ltermlib -lm > "$out.link.log" 2>&1 || { echo "link errors: see $out.link.log"; exit 1; }
cp "$out" "$out.sym"; "$NHSTRIP" "$out"; ls -l "$out"
