#include <conio.h>

#include "basic.h"

#define byte unsigned char
#define ON 1
#define OFF 0


int invmd = OFF;



void setfgrnd(int color)
{
    int md;

    if ((md = gettextmode()) == BW40 || md == BW80 || md == MONO)
        textcolor(7);
    else
        textcolor(color);
}

void setbgrnd(int color)
{
    int md;

    if ((md = gettextmode()) == BW40 || md == BW80 || md == MONO)
        textbackground(0);
    else
        textbackground(color);
}

void setblink(int status)
{
    if (status)
        textattr(gettextattr() | 128);
    else
        textattr(gettextattr() & 127);
}

int getinv(void)
{
    return(invmd);
}

void setinv(int status)
{
    byte temp;
    int md;

    md = gettextmode();
    if (status != invmd && md != BW40 && md != BW80 && md != MONO) {
        temp = gettextcolor();
        textcolor(gettextbackground());
        textbackground(temp);
    }
    if (md == BW40 || md == BW80 || md == MONO) {
        if (status)
            textattr((gettextattr() & 128) | 112);
        else
            textattr((gettextattr() & 128) | 7);
    }
    invmd = status;
}

void border(int x1, int y1, int x2, int y2)
{
    int q, a;

    find_scr_addr();
    a = gettextattr();
    showchar(x1, y1, 218, a);
    showchar(x1, y2, 192, a);
    for (q = x1 + 1; q < x2; q++) {
        showchar(q, y1, 196, a);
        showchar(q, y2, 196, a);
    }
    showchar(x2, y1, 191, a);
    showchar(x2, y2, 217, a);
    for (q = y1 + 1; q < y2; q++) {
        showchar(x1, q, 179, a);
        showchar(x2, q, 179, a);
    }
}
