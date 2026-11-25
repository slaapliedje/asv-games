/*
 * nhfix.h - forced ahead of every NetHack and Lua source: what AMIX's
 * SVR4.0 headers leave out, and the library calls that go through rt.c.
 */
#ifndef NHFIX_H
#define NHFIX_H
#undef __MINT__
#undef __atarist__
#undef atarist
#include <sys/types.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
typedef int ssize_t;

struct rlimit;
struct timeval;
int getrlimit(int, struct rlimit *);
int setrlimit(int, const struct rlimit *);
int fchmod(int, mode_t);
int seteuid(uid_t);
int setegid(gid_t);
char *tgoto(char *, int, int);
char *tparm();

/* these return a double in fp0; the mint GCC reads d0:d1 (rt.c) */
#define strtod	amix_strtod
#define sqrt	amix_sqrt
#define pow	amix_pow
#define exp	amix_exp
#define log	amix_log
#define log10	amix_log10
#define floor	amix_floor
#define ceil	amix_ceil
#define fmod	amix_fmod
#define sin	amix_sin
#define cos	amix_cos
#define tan	amix_tan
#define asin	amix_asin
#define acos	amix_acos
#define atan	amix_atan
#define atan2	amix_atan2
#define frexp	amix_frexp
#define ldexp	amix_ldexp
#define fabs	amix_fabs
#define difftime amix_difftime

#define NHD(f) double amix_##f()
NHD(strtod); NHD(sqrt); NHD(pow); NHD(exp); NHD(log); NHD(log10); NHD(floor);
NHD(ceil); NHD(fmod); NHD(sin); NHD(cos); NHD(tan); NHD(asin); NHD(acos);
NHD(atan); NHD(atan2); NHD(frexp); NHD(ldexp); NHD(fabs); NHD(difftime);
#undef NHD
#define log2(x) (amix_log(x) / 0.69314718055994530942)

/* AMIX's printf has no ll, z, snprintf (rt.c) */
int amx_vsnprintf(char *, size_t, const char *, va_list);
int amx_snprintf(char *, size_t, const char *, ...);
int amx_vsprintf(char *, const char *, va_list);
int amx_sprintf(char *, const char *, ...);
int amx_vfprintf(FILE *, const char *, va_list);
int amx_fprintf(FILE *, const char *, ...);
int amx_printf(const char *, ...);
#define vsnprintf amx_vsnprintf
#define snprintf amx_snprintf
#define vsprintf amx_vsprintf
#define sprintf amx_sprintf
#define vfprintf amx_vfprintf
#define fprintf amx_fprintf
#define printf amx_printf
#endif
