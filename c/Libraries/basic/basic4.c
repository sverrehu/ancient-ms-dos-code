#include <dos.h>
#include <conio.h>

#include "basic.h"

#define byte unsigned char
#define ON 1
#define OFF 0



void scrollu(byte x1, byte y1, byte x2, byte y2)
{
    _BH = gettextattr();
    _CH = y1 - 1;
    _CL = x1 - 1;
    _DH = y2 - 1;
    _DL = x2 - 1;
    _AX = 0x0601;
    geninterrupt(0x10);
}

void scrolld(byte x1, byte y1, byte x2, byte y2)
{
    _BH = gettextattr();
    _CH = y1 - 1;
    _CL = x1 - 1;
    _DH = y2 - 1;
    _DL = x2 - 1;
    _AX = 0x0701;
    geninterrupt(0x10);
}

void clrarea(byte x1, byte y1, byte x2, byte y2)
{
    _BH = gettextattr();
    _CH = y1 - 1;
    _CL = x1 - 1;
    _DH = y2 - 1;
    _DL = x2 - 1;
    _AX = 0x0600;
    geninterrupt(0x10);
}

void lattr(int line, int attr)
{
    int  x, y;
    byte numofchar;

    numofchar = (byte) xmax() - 1;
    x = wherex();
    y = wherey();
    _DL = numofchar;
    _DH = line - 1;
    _CL = 0;
    _CH = line - 1;
    _BH = attr;
    _AX = 0x0600;
    geninterrupt(0x10);
    gotoxy(x, y);
}
