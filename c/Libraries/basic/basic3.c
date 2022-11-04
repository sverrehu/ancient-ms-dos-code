#include <conio.h>

#include "basic.h"


static int cursmd = 1;


int xmax(void)
{
    struct text_info ti;

    gettextinfo(&ti);
    return ti.screenwidth;
}



int ymax(void)
{
    struct text_info ti;

    gettextinfo(&ti);
    return ti.screenheight;
}



void curson(void)
{
    _setcursortype(_NORMALCURSOR);
    cursmd = 1;
}



void cursoff(void)
{
    _setcursortype(_NOCURSOR);
    cursmd = 0;
}



int cursor(void)
{
    return cursmd;
}
