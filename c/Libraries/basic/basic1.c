#include <dos.h>
#include <conio.h>

#include "basic.h"

#define byte unsigned char
#define ON 1
#define OFF 0


int  snowchecking = OFF;
unsigned far * scr_addr = (unsigned far *) 0xB8000000;
     /* Peker til skjermminnet for raskere tegning av ramme. Avhengig av
        om skjermem er MONO eller ikke. find_scr_addr() Mè kalles! */
unsigned width = 80;
     /* Skjermens vidde, dvs antall kolonner */



/*
    SHOWCHAR skriver tegn direkte til skjermminnet. Det er viktig
    at find_scr_addr() er kalt fõrst, ellers er ikke skjermadressen
    kjent.
    Det er mulig Ü foreta snowcheck. Settes med setsnowchecking().
        <x, y> - posisjon (x:1-80, y:1-25)
        <c>    - tegnet som skal vises
        <a>    - attributt for tegnet
*/
void showchar(int x, int y, byte c, byte a)
{
    if (snowchecking)
        while (!(inportb(0x3DA) & 8))
             ;
    *(scr_addr + width * (y - 1) + x - 1) = c + 256 * a;
}


/*
    SETSNOWCHECKING setter snowchecking enten av eller pÜ. Vanlig er AV.
*/
void setsnowchecking(int status)
{
    snowchecking = status;
}


void far * find_scr_addr(void) /* Finner skjermadressen */
{
    struct text_info ti;

    gettextinfo(&ti);
    if (ti.currmode == MONO)
        scr_addr = (unsigned far *) MK_FP(0xB000, peek(0, 0x44E));
    else
        scr_addr = (unsigned far *) MK_FP(0xB800, peek(0, 0x44E));
    width = ti.screenwidth;
    return(scr_addr);
}
