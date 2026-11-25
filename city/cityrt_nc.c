/* cityrt_nc.c - ncurses calls SVR4 curses lacks (ttycity only) */
#include <curses.h>
#include <stdlib.h>

/* recolour n cells in place, keeping their characters */
int mvchgat(int y, int x, int n, chtype attr, short pair, const void *opts)
{
	int oy, ox, my, mx, i;
	chtype c;

	getyx(stdscr, oy, ox);
	getmaxyx(stdscr, my, mx);
	if (n < 0 || x + n > mx)
		n = mx - x;
	if (getenv("NOCHGAT")) return OK;
	for (i = 0; i < n; i++) {
		c = mvinch(y, x + i) & A_CHARTEXT;
		mvaddch(y, x + i, c | attr | COLOR_PAIR(pair));
	}
	move(oy, ox);
	return OK;
}
