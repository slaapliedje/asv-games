/* x11r4.h - forced ahead of NetHack's X11 sources: AMIX's X is X11R4 */
#ifndef NH_X11R4_H
#define NH_X11R4_H
#include <X11/Xlib.h>
#include <X11/Xresource.h>
#ifndef XlibSpecificationRelease
#define XPointer char *
#define XrmGetDatabase(d) ((d)->db)
#endif
#endif
