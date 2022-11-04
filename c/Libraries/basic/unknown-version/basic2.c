#include <bios.h>
#include <dos.h>

#include "basic.h"

#define byte unsigned char
#define ON 1
#define OFF 0


void (*fkey_func[10])(void);
int  fkey[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
int  call_getkey_func = 0;
void (*getkey_func)(void);
int  (*getkey_handler)(int);



int getkey(void)
{
    int ch;
    struct REGPACK regs;

  restart:
    do {
        geninterrupt(0x28); /* Kalles av DOS mens det ventes p†
                               tastetrykk. Diverse residente programmer
                               benytter seg av dette. */
        regs.r_ax = 0x0100;
        intr(0x16, &regs);
        if (call_getkey_func && regs.r_flags & 64)
            getkey_func();
    } while (regs.r_flags & 64);
    if (((ch = bioskey(0)) & 255) == 0)  /* Hvis ext. key */
        ch = -((unsigned) ch / 256);
    else
        ch &= 255;
    if (getkey_handler && !(ch = getkey_handler(ch)))
        goto restart;
    if (-ch >= 59 && -ch < 69) {
        if (fkey[-ch - 59])
            fkey_func[-ch - 59]();
    }
    pokeb(0x0040, 0x0071, (peekb(0x0040, 0x0071) & 127));
    return(ch);
}


void def_fkey(int nr, void (* ft)())
{
    fkey[nr - 1] = 1;
    fkey_func[nr - 1] = ft;
}


void undef_fkey(int nr)
{
    fkey[nr - 1] = 0;
}


void def_getkey(void (* fnk)())
{
    call_getkey_func = 1;
    getkey_func = fnk;
}


void undef_getkey(void)
{
    call_getkey_func = 0;
}



/*
 *  Function to call when a key is read. The function should return
 *  the (possibly translated) code to return, or 0 to skip this key.
 */
void def_getkey_handler(int (* fnk)(int))
{
    getkey_handler = fnk;
}


void undef_getkey_handler(void)
{
    getkey_handler = 0;
}
