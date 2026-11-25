#!/bin/bash
# mkpkg.sh [nethack] [ttycity] [vtcity] - build and write dist/NAME-VERSION.pkg,
# SVR4 package datastreams for `pkgadd -d FILE`.  Needs ./fetch.sh run first.
set -e
here=$(cd "$(dirname "$0")" && pwd); cd "$here"
[ $# -gt 0 ] || set -- nethack ttycity vtcity
mkdir -p dist build
U=upstream; B=build
info() {	# info PKGINFO VERSION -> build/pkginfo.NAME
	{ cat "$1"; echo "VERSION=$2"; echo "PSTAMP=asv-games-$(git rev-parse --short HEAD 2>/dev/null || echo local)"; } > "$3"
}
for p in "$@"; do case $p in
nethack)
	[ -f $B/xpm/libXpm.a ] || bash nethack/build-xpm.sh
	bash nethack/build.sh x11
	v=5.0.1wip.$(git -C $U/nethack rev-parse --short=7 HEAD)
	info nethack/pkginfo "$v" $B/pkginfo.nethack
	sed -e 's/^WIZARDS=.*/WIZARDS=root/' -e '/^GDBPATH=/d' -e '/^GREPPATH=/d' -e '/^PANICTRACE_/d' $U/nethack/sys/unix/sysconf > $B/sysconf
	# the X11 port reads its tiles from the BMP (the hints build x11tiles, an
	# XPM); the tombstone's Times font is not on every X server; "Dark cyan"
	# is not in X11R4's rgb.txt, which ASV's X servers read
	sed -e 's/^NetHack.tile_file: .*/NetHack.tile_file: nhtiles.bmp/' \
	    -e 's/^\(NetHack\*text\*rip\*font:  *\).*/\1fixed/' \
	    -e 's/^\(NetHack\*map\*cyan:  *\)Dark cyan/\1#008b8b/' $U/nethack/dat/NetHack.ad > $B/NetHack.ad
	L=/opt/nethack/lib D=$U/nethack/dat
	python3 tools/asvpkg.py dist/nethack-$v.pkg $B/pkginfo.nethack \
	    /opt/nethack/bin/nethack=nethack/nethack.sh:0755 \
	    /usr/bin/nethack=@/opt/nethack/bin/nethack \
	    $L/nethack=$B/nethack-x11:0755 \
	    $L/nhdat=$D/nhdat:0644 $L/license=$D/license:0644 $L/symbols=$D/symbols:0644 \
	    $L/sysconf=$B/sysconf:0644 $L/NetHack=$B/NetHack.ad:0644 \
	    $L/nhtiles.bmp=$D/nhtiles.bmp:0644 $L/rip.xpm=$D/rip.xpm:0644 \
	    $L/pet_mark.xbm=$D/pet_mark.xbm:0644 $L/pilemark.xbm=$D/pilemark.xbm:0644 \
	    /opt/nethack/doc/README=nethack/README:0644 \
	    /opt/nethack/doc/Guidebook.txt=$U/nethack/doc/Guidebook.txt:0644 \
	    /opt/nethack/doc/license=$D/license:0644 \
	    /var/opt/nethack/=:0777 /var/opt/nethack/save/=:0777
	;;
ttycity|vtcity)
	bash city/build.sh $p
	v=$(git -C $U/$p log -1 --format=%cd --date=format:%Y.%m.%d).$(git -C $U/$p rev-parse --short=7 HEAD)
	info city/pkginfo.$p "$v" $B/pkginfo.$p
	args=()
	for f in $U/$p/cities/*; do args+=("/opt/$p/share/cities/$(basename "$f")=$f:0644"); done
	if [ $p = ttycity ]; then
		args+=("/opt/$p/share/terminfo/x/xterm-color=city/xterm-color:0644" "/opt/$p/doc/xterm-color.ti=city/xterm-color.ti:0644")
	fi
	python3 tools/asvpkg.py dist/$p-$v.pkg $B/pkginfo.$p \
	    /opt/$p/bin/$p=city/$p.sh:0755 /usr/bin/$p=@/opt/$p/bin/$p \
	    /opt/$p/lib/$p=$B/$p:0755 \
	    /opt/$p/doc/README=city/README.$p:0644 /opt/$p/doc/LICENSE=$U/$p/LICENSE:0644 \
	    "${args[@]}"
	;;
*) echo "unknown: $p" >&2; exit 1;;
esac; done
ls -l dist
