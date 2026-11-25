# env.sh - the cross tools for AMIX / Atari System V.  Override any of these
# in the environment.
#   MANX          github.com/slaapliedje/manx (sysv4-cc, sysv4-ld: GCC for
#                 m68k that writes SVR4 objects)
#   ASV_CROSS     binutils for m68k-cbm-sysv4, from
#                 github.com/slaapliedje/ashnazag (toolchain/amix)
#   AMIX_SYSROOT  headers and libraries copied off an AMIX or ASV system
export MANX=${MANX:-$HOME/dev/manx}
export ASV_CROSS=${ASV_CROSS:-$HOME/dev/amix/ashnazag/toolchain/amix}
export AMIX_SYSROOT=${AMIX_SYSROOT:-$HOME/opt/amix-sysroot/sysroot}
export SVR4_AS=$ASV_CROSS/bin/m68k-cbm-sysv4-as
export NHCC=$MANX/toolchain/sysv4-cc NHLD=$MANX/toolchain/sysv4-ld
export NHAR=$ASV_CROSS/bin/m68k-cbm-sysv4-ar NHSTRIP=$ASV_CROSS/bin/m68k-cbm-sysv4-strip
