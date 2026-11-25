# Games for Atari System V and AMIX

Three games built as static AMIX (Amiga UNIX, SVR4 on 68k) programs and
packed for `pkgadd`.  On Atari System V on the TT030 they run through
the amx module of the [service pack](https://github.com/slaapliedje/atari-sysv-sp1).

| package | what | upstream, at the commit built |
|---|---|---|
| `NETHACK` | NetHack 5.0: terminal, and X11 with tiles (`nethack -x`) | [NetHack/NetHack](https://github.com/NetHack/NetHack) `m68k-wip`, `a0db7a1` |
| `TTYCITY` | Micropolis for curses terminals | [tenox7/ttycity](https://github.com/tenox7/ttycity) `fd84313` |
| `VTCITY` | Micropolis for DEC VT terminals with soft fonts | [tenox7/vtcity](https://github.com/tenox7/vtcity) `9aa2e99` |

This repository holds no upstream source: `fetch.sh` gets each at the
commit above and applies the patch here.  That, with the scripts, is the
complete source of the packages.

## Installing

Copy a `.pkg` from the releases to the machine and, as root:

    pkgadd -d nethack-VERSION.pkg NETHACK
    pkgadd -d ttycity-VERSION.pkg TTYCITY
    pkgadd -d vtcity-VERSION.pkg VTCITY

Each installs under `/opt/NAME` with a link in `/usr/bin`, and a README in
`/opt/NAME/doc`.  `pkgrm NETHACK` (and so on) removes one; NetHack's
scores and saved games in `/var/opt/nethack` stay.

## Tested

In Hatari running Atari System V with the service pack: `pkgadd`,
`pkgchk` and `pkgrm` of each package; NetHack played, saved and quit in
a terminal, and played by keyboard with tiles on a remote X display,
to a death and its graphical tombstone; the same played, saved, restored
and quit by a user other than root; ttycity in colour; vtcity's output
checked for its soft fonts.  On the ATW800/2's X server (Xatw, X11R6.3):
`nethack -x` played by keyboard from an xdm session in Hatari, and on
the TT030 MiSTer core it starts, takes a mouse click and draws the map
in tiles.  Not yet tried: a real TT030, and AMIX on an Amiga.

A game started from a telnet or serial login ends when that login does,
`nohup` or not: NetHack takes the hangup itself.

## Building

On a Linux PC, with:

- [manx](https://github.com/slaapliedje/manx) (`toolchain/sysv4-cc`,
  `sysv4-ld`: a current GCC writing SVR4 m68k objects),
- the `m68k-cbm-sysv4` binutils from
  [ashnazag](https://github.com/slaapliedje/ashnazag) (`toolchain/amix`),
- a sysroot of headers and libraries copied from an AMIX or ASV system
  (libc, curses, X11R4),
- a native C compiler with X11 development files (NetHack builds once on
  the PC for its data files).

Paths are in `common/env.sh`; override them in the environment.

    ./fetch.sh      # upstream sources into upstream/, patched; NetHack's host build
    ./mkpkg.sh      # build all three, write dist/*.pkg

## What was changed

- **NetHack**, `nethack/nethack-asv.patch`, all in `win/X11`:
  - SVR4's `bsearch()` calls the comparison once on an empty table;
  - X11R4 has no `XtNreportCallback`;
  - the map window freed the widget's own font when the X server had no
    Unicode variant of it, so the end-of-game windows died of `BadFont`;
  - three status-column arrays were one `int` short, so a column width
    overwrote the next column's first field: harmless with a small font,
    "create_widget: unknown type" with a larger one;
  - "dark cyan" and "web gray" are not in X11R4's `rgb.txt`.
- **ttycity**, `city/ttycity-svr4-curses.patch`: SVR4 curses takes the
  terminal's foreground for black until it has set one.
- **vtcity**: nothing.

Beside the sources: `common/nhfix.h` and `common/rt.c` (what SVR4.0's
headers and libc lack, and the calls whose floating-point return the
compiler reads from the wrong register), `city/cityrt*.c` (`index`,
`rindex`, `mvchgat`).  Everything is built at `-O1`: GCC 15.2 for m68k
miscompiled NetHack at `-O2`.

`city/xterm-color` is `city/xterm-color.ti` compiled by `tic` on ASV (its
`xterm` entry has no colour); it installs under `/opt/ttycity`, and the
`ttycity` command points `TERMINFO` at it when `TERM=xterm-color`.

`tools/asvpkg.py` writes the package datastream on the PC.  It comes from
[OpenUA](https://github.com/slaapliedje/OpenUA) (GPL-2.0), with directory
modes and symbolic links added.

## Licences

NetHack is under the NetHack General Public License, ttycity and vtcity
under GPL-3.0 with the Micropolis additional terms; each package carries
its licence.  The scripts and glue files here are offered under the same
terms as the program they build; `tools/asvpkg.py` is GPL-2.0.
