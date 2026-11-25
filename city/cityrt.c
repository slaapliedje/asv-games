/* cityrt.c - what AMIX libc lacks for vtcity/ttycity */
#include <string.h>
char *rindex(const char *s, int c) { return strrchr(s, c); }
char *index(const char *s, int c) { return strchr(s, c); }
