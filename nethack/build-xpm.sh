#!/bin/bash
# build-xpm.sh - libXpm 3.4k as a static AMIX library (X11R4), into build/xpm/
set -e
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../common/env.sh"
src=$here/../upstream/xpm-3.4k/lib
out=$here/../build/xpm; mkdir -p "$out/obj" "$out/include/X11"
cp "$src/xpm.h" "$out/include/X11/xpm.h"
for f in "$src"/*.c; do
	n=$(basename "$f" .c)
	case $n in amigax|simx) continue;; esac
	"$NHCC" -m68030 -m68881 -O2 -std=gnu89 -DNO_ZPIPE -DNEED_STRCASECMP -DNEED_STRDUP \
		-Wno-implicit-int -Wno-implicit-function-declaration -Wno-incompatible-pointer-types \
		-Wno-int-conversion -Wno-return-mismatch -I"$src" -c "$f" -o "$out/obj/$n.o" || echo "FAILED $n"
done
rm -f "$out/libXpm.a"; "$NHAR" rc "$out/libXpm.a" "$out"/obj/*.o
ls -l "$out/libXpm.a"
