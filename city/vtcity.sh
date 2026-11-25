#!/bin/sh
# vtcity - Micropolis in a terminal, on Atari System V / AMIX.
SIMHOME=/opt/vtcity/share
export SIMHOME
exec /opt/vtcity/lib/vtcity "$@"
