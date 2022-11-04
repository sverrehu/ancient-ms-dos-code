#include <dos.h>
#include <conio.h>

#include "basic.h"

#define byte unsigned char
#define ON 1
#define OFF 0



int gettextmode(void)
{
    struct text_info ti;

    gettextinfo(&ti);
    return(ti.currmode);
}

int getpage(void)
{
    return(peekb(0, 0x462));
}

void setpage(byte page)
{
    _AL = page;
    _AH = 5;
    geninterrupt(0x10);
}

int gettextbackground(void)
{
    struct text_info ti;

    gettextinfo(&ti);
    return((ti.attribute / 16) & 7);
}

int gettextcolor(void)
{
    struct text_info ti;

    gettextinfo(&ti);
    return(ti.attribute & 15);
}

int gettextattr(void)
{
    struct text_info ti;

    gettextinfo(&ti);
    return(ti.attribute);
}
