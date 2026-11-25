#!/bin/bash
# build.sh vtcity|ttycity - tenox7's Micropolis terminal ports as static AMIX
# programs (run on Atari System V through the amx module), cross-built on the
# PC.  Needs ../fetch.sh run first.
set -e
here=$(cd "$(dirname "$0")" && pwd)
C=$here/../common
. "$C/env.sh"
name=${1:?vtcity or ttycity}
src=$here/../upstream/$name/src
obj=$here/../build/$name-obj; out=$here/../build/$name
mkdir -p "$obj"
engine="s_alloc s_disast s_eval s_fileio s_gen s_init s_msg s_power s_scan s_sim s_traf s_zone g_ani w_con w_tool w_sprite w_budget w_eval w_keys w_resrc w_update w_stubs w_util w_sound rand random"
case $name in
vtcity)  front="vt_main vt_term vt_render vt_input vt_status vt_minimap vt_menu vt_dialogs vt_stubs"; LIBS="-lm";;
ttycity) front="nc_main nc_render nc_gfx nc_aa nc_input nc_status nc_minimap nc_menu nc_dialogs nc_stubs"; LIBS="$ASV_CROSS/m68k-cbm-sysv4/sysroot/usr/ccs/lib/libcurses.a -lm";;
*) echo "unknown: $name" >&2; exit 1;;
esac
CF="-m68030 -m68881 ${OPT:--O1} -fomit-frame-pointer -std=gnu89 -include $C/nhfix.h \
 -I$C/include -I$src/headers -DAMIX_ASV -w \
 -Wno-implicit-int -Wno-implicit-function-declaration -Wno-return-type \
 -Wno-return-mismatch -Wno-int-conversion -Wno-incompatible-pointer-types"
{
	echo "CC=$NHCC"; echo "CF=$CF"; echo "O=$obj"
	all=
	for n in $engine $front; do
		all="$all \$(O)/$n.o"
		printf '$(O)/%s.o: %s %s\n\t@echo %s; $(CC) $(CF) -c %s -o $@\n' "$n" "$src/$n.c" "$C/nhfix.h" "$n" "$src/$n.c"
	done
	printf '$(O)/rt.o: %s\n\t$(CC) -m68030 -m68881 -O2 -std=gnu99 -c %s -o $@\n' "$C/rt.c" "$C/rt.c"
	printf '$(O)/cityrt.o: %s\n\t$(CC) -m68030 -m68881 -O1 -std=gnu99 -c %s -o $@\n' "$here/cityrt.c" "$here/cityrt.c"
	printf '$(O)/sysv_rt.o: %s\n\t$(CC) -m68030 -m68881 -O2 -std=gnu99 -c %s -o $@\n' "$MANX/os/sysv4/sysv_rt.c" "$MANX/os/sysv4/sysv_rt.c"
	if [ $name = ttycity ]; then
		all="$all \$(O)/cityrt_nc.o"
		printf '$(O)/cityrt_nc.o: %s\n\t$(CC) $(CF) -c %s -o $@\n' "$here/cityrt_nc.c" "$here/cityrt_nc.c"
	fi
	echo "all: $all \$(O)/rt.o \$(O)/cityrt.o \$(O)/sysv_rt.o"
} > "$obj/Makefile"
make -k -j"$(nproc)" -f "$obj/Makefile" all > "$out.build.log" 2>&1 || { echo "compile errors: see $out.build.log"; exit 1; }
"$NHLD" -o "$out" "$obj"/*.o $LIBS > "$out.link.log" 2>&1 || { echo "link errors: see $out.link.log"; exit 1; }
cp "$out" "$out.sym"; "$NHSTRIP" "$out"; ls -l "$out"
