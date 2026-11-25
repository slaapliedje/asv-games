/* curses.h - AMIX's, kept from tripping over NetHack: its TRUE/FALSE test
 * cannot take a cast in #if, and its mini-curses declares m_move() */
#ifndef NH_CURSES_WRAP_H
#define NH_CURSES_WRAP_H
#pragma push_macro("TRUE")
#pragma push_macro("FALSE")
#undef TRUE
#undef FALSE
#define m_move curses_m_move
#include_next <curses.h>
#undef m_move
#undef TRUE
#undef FALSE
#pragma pop_macro("FALSE")
#pragma pop_macro("TRUE")
#endif
