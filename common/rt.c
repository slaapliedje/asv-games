/*
 * rt.c - what a static AMIX NetHack needs that no AMIX library has, and the
 * calls into AMIX's libraries that the mint GCC would get wrong.
 */
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* (__main, the memory limits, netconfig and gethostname are Manx's
 * os/sysv4/sysv_rt.c, linked in beside this) */

/* C99's trunc, which AMIX's libm predates: the FPU's round-toward-zero */
double trunc(double x)
{
	double r;

	__asm__("fintrz.x %1,%0" : "=f" (r) : "f" (x));
	return r;
}

/*
 * The mint GCC returns a double in d0:d1, even with -m68881. AMIX's libc
 * and libm return one in fp0. amixfix.h renames the functions vim calls to
 * amix_NAME, which are these: NAME is called with a copy of the arguments
 * (16 bytes, the most any of them takes: two doubles; for the others the
 * rest is the caller's frame, only read), and fp0 goes to d0:d1.
 */
#define FP0_TO_D0D1(f)					\
	"	.globl	amix_" #f "\n"			\
	"amix_" #f ":\n"				\
	"	move.l	16(%sp),-(%sp)\n"		\
	"	move.l	16(%sp),-(%sp)\n"		\
	"	move.l	16(%sp),-(%sp)\n"		\
	"	move.l	16(%sp),-(%sp)\n"		\
	"	jsr	" #f "\n"			\
	"	lea	16(%sp),%sp\n"			\
	"	fmove.d	%fp0,-(%sp)\n"			\
	"	move.l	(%sp)+,%d0\n"			\
	"	move.l	(%sp)+,%d1\n"			\
	"	rts\n"
__asm__("	.text\n"
	FP0_TO_D0D1(strtod)
	FP0_TO_D0D1(sqrt) FP0_TO_D0D1(pow) FP0_TO_D0D1(exp)
	FP0_TO_D0D1(log) FP0_TO_D0D1(log10)
	FP0_TO_D0D1(floor) FP0_TO_D0D1(ceil) FP0_TO_D0D1(fmod)
	FP0_TO_D0D1(sin) FP0_TO_D0D1(cos) FP0_TO_D0D1(tan)
	FP0_TO_D0D1(asin) FP0_TO_D0D1(acos) FP0_TO_D0D1(atan) FP0_TO_D0D1(atan2)
	FP0_TO_D0D1(frexp) FP0_TO_D0D1(ldexp) FP0_TO_D0D1(fabs)
	FP0_TO_D0D1(difftime));


/*
 * printf: AMIX's (1991) has no ll length, no snprintf and no z or j.  The
 * integer and string conversions are done here, bounded; a floating-point
 * conversion is handed to AMIX's sprintf one at a time.
 */
struct out { char *buf; size_t n, len; };

static void put(struct out *o, char c)
{
	if (o->len + 1 < o->n)
		o->buf[o->len] = c;
	o->len++;
}

static void emit(struct out *o, const char *s, int len, int width, int left, char padc)
{
	int k;

	if (!left)
		for (k = len; k < width; k++)
			put(o, padc);
	for (k = 0; k < len; k++)
		put(o, s[k]);
	if (left)
		for (k = len; k < width; k++)
			put(o, ' ');
}

int amx_vsnprintf(char *buf, size_t n, const char *fmt, va_list ap)
{
	struct out o;
	char t[400], spec[32];

	o.buf = buf; o.n = n; o.len = 0;
	for (; *fmt; fmt++) {
		int left = 0, zero = 0, plus = 0, space = 0, alt = 0;
		int width = 0, prec = -1, lng = 0, k = 0, neg = 0, base = 10;
		unsigned long long v;
		const char *dig = "0123456789abcdef", *s;
		char c;

		if (*fmt != '%') { put(&o, *fmt); continue; }
		for (fmt++;; fmt++) {
			if (*fmt == '-') left = 1;
			else if (*fmt == '0') zero = 1;
			else if (*fmt == '+') plus = 1;
			else if (*fmt == ' ') space = 1;
			else if (*fmt == '#') alt = 1;
			else break;
		}
		if (*fmt == '*') { width = va_arg(ap, int); fmt++; if (width < 0) { left = 1; width = -width; } }
		else while (*fmt >= '0' && *fmt <= '9') width = width * 10 + *fmt++ - '0';
		if (*fmt == '.') {
			fmt++; prec = 0;
			if (*fmt == '*') { prec = va_arg(ap, int); fmt++; }
			else while (*fmt >= '0' && *fmt <= '9') prec = prec * 10 + *fmt++ - '0';
		}
		for (;; fmt++) {
			if (*fmt == 'l') lng++;
			else if (*fmt == 'j' || *fmt == 'q') lng = 2;
			else if (*fmt == 'h' || *fmt == 'z' || *fmt == 't' || *fmt == 'L') ;
			else break;
		}
		c = *fmt;
		if (!c) break;
		switch (c) {
		case '%': put(&o, '%'); break;
		case 'c': t[0] = (char)va_arg(ap, int); emit(&o, t, 1, width, left, ' '); break;
		case 's':
			s = va_arg(ap, const char *);
			if (!s) s = "(null)";
			for (k = 0; s[k] && (prec < 0 || k < prec); k++) ;
			emit(&o, s, k, width, left, ' ');
			break;
		case 'd': case 'i': {
			long long sv = lng >= 2 ? va_arg(ap, long long) : lng ? va_arg(ap, long) : va_arg(ap, int);
			neg = sv < 0; v = neg ? -(unsigned long long)sv : (unsigned long long)sv;
			goto number;
		}
		case 'p': lng = 1; alt = 1; c = 'x';	/* FALLTHROUGH */
		case 'u': case 'o': case 'x': case 'X':
			v = lng >= 2 ? va_arg(ap, unsigned long long) : lng ? va_arg(ap, unsigned long) : va_arg(ap, unsigned);
			base = c == 'o' ? 8 : c == 'u' ? 10 : 16;
			if (c == 'X') dig = "0123456789ABCDEF";
		number: {
			char pre[4]; int np = 0, nd, zeros, total;

			do { t[k++] = dig[v % base]; v /= base; } while (v);
			if (prec == 0 && k == 1 && t[0] == '0') k = 0;
			nd = k;
			if (neg) pre[np++] = '-';
			else if (c == 'd' || c == 'i') { if (plus) pre[np++] = '+'; else if (space) pre[np++] = ' '; }
			if (alt && base == 16) { pre[np++] = '0'; pre[np++] = c == 'X' ? 'X' : 'x'; }
			zeros = prec > nd ? prec - nd : 0;
			if (alt && base == 8 && zeros == 0) zeros = 1;
			if (prec < 0 && zero && !left && width > np + nd) zeros = width - np - nd;
			total = np + zeros + nd;
			if (!left) for (; total < width; total++) put(&o, ' ');
			for (neg = 0; neg < np; neg++) put(&o, pre[neg]);
			while (zeros-- > 0) put(&o, '0');
			while (nd > 0) put(&o, t[--nd]);
			if (left) for (; total < width; total++) put(&o, ' ');
			break;
		}
		case 'e': case 'E': case 'f': case 'F': case 'g': case 'G': case 'a': case 'A': {
			double d = va_arg(ap, double);
			char *q = spec;

			*q++ = '%';
			if (left) *q++ = '-';
			if (zero) *q++ = '0';
			if (plus) *q++ = '+';
			if (space) *q++ = ' ';
			if (alt) *q++ = '#';
			if (width > 60) width = 60;
			if (prec > 40) prec = 40;
			if (c == 'a') c = 'g';
			if (c == 'A') c = 'G';
			if (c == 'F') c = 'f';
			if (prec >= 0) q += sprintf(q, "%d.%d", width, prec);
			else q += sprintf(q, "%d", width);
			*q++ = c; *q = '\0';
			emit(&o, t, sprintf(t, spec, d), 0, 0, ' ');
			break;
		}
		default: put(&o, '%'); put(&o, c); break;
		}
	}
	if (o.n)
		o.buf[o.len < o.n ? o.len : o.n - 1] = '\0';
	return (int)o.len;
}

int amx_snprintf(char *buf, size_t n, const char *fmt, ...)
{
	va_list ap; int r;
	va_start(ap, fmt); r = amx_vsnprintf(buf, n, fmt, ap); va_end(ap);
	return r;
}
int amx_vsprintf(char *buf, const char *fmt, va_list ap)
{
	return amx_vsnprintf(buf, (size_t)1 << 30, fmt, ap);
}
int amx_sprintf(char *buf, const char *fmt, ...)
{
	va_list ap; int r;
	va_start(ap, fmt); r = amx_vsnprintf(buf, (size_t)1 << 30, fmt, ap); va_end(ap);
	return r;
}
int amx_vfprintf(FILE *f, const char *fmt, va_list ap)
{
	char small[512], *p = small;
	va_list ap2;
	int r;

	va_copy(ap2, ap);
	r = amx_vsnprintf(small, sizeof small, fmt, ap);
	if (r >= (int)sizeof small) {
		p = malloc((size_t)r + 1);
		if (!p) { va_end(ap2); return -1; }
		amx_vsnprintf(p, (size_t)r + 1, fmt, ap2);
	}
	va_end(ap2);
	fwrite(p, 1, (size_t)r, f);
	if (p != small) free(p);
	return r;
}
int amx_fprintf(FILE *f, const char *fmt, ...)
{
	va_list ap; int r;
	va_start(ap, fmt); r = amx_vfprintf(f, fmt, ap); va_end(ap);
	return r;
}
int amx_printf(const char *fmt, ...)
{
	va_list ap; int r;
	va_start(ap, fmt); r = amx_vfprintf(stdout, fmt, ap); va_end(ap);
	return r;
}
