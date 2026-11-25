#!/bin/bash
# fetch.sh - the upstream sources at the commits these ports were made from,
# into upstream/, with the patches applied, and NetHack built once natively
# (its data files, date.h and tile.c come from a host build).
set -e
here=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$here/upstream"; cd "$here/upstream"
get() {	# get DIR URL COMMIT [PATCH]
	if [ ! -d "$1/.git" ]; then
		git init -q "$1"
		git -C "$1" fetch -q --depth 1 "$2" "$3"
		git -C "$1" checkout -q FETCH_HEAD
		[ -z "$4" ] || git -C "$1" apply "$4"
	fi
}
get nethack https://github.com/NetHack/NetHack.git a0db7a140893677091f161391b018aef7e542d55 "$here/nethack/nethack-asv.patch"
get ttycity https://github.com/tenox7/ttycity.git fd843137beaa7fc2ae7cc31b6c1e5a17f21e97d8 "$here/city/ttycity-svr4-curses.patch"
get vtcity  https://github.com/tenox7/vtcity.git  9aa2e9965f62851b4ab5f3d51202a97efcc9d3c7
if [ ! -d xpm-3.4k ]; then
	for u in https://archive.debian.org/debian/pool/main/x/xpm/xpm_3.4k.orig.tar.gz \
	         https://snapshot.debian.org/archive/debian/20050312T000000Z/pool/main/x/xpm/xpm_3.4k.orig.tar.gz; do
		curl -sfL -m 90 -o xpm-3.4k.tar.gz "$u" && break
	done
	mkdir x && tar xzf xpm-3.4k.tar.gz -C x && mv x/* xpm-3.4k && rmdir x
fi
if [ ! -f nethack/dat/nhdat ]; then
	(cd nethack/sys/unix && sh setup.sh hints/linux.501)
	(cd nethack && make -j"$(nproc)" WANT_WIN_TTY=1 WANT_WIN_X11=1 all && make nhtiles.bmp) > nethack-host-build.log 2>&1 ||
		{ echo "NetHack host build failed: see upstream/nethack-host-build.log"; exit 1; }
fi
ls nethack/dat/nhdat nethack/dat/nhtiles.bmp nethack/src/tile.c nethack/include/date.h
