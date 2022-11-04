#include <stdio.h>
#include <stdlib.h>
#include <dos.h>
#include <string.h>
#include <ctype.h>
#include <conio.h>

#include <basic.h>

#include "atread.h"



#define ON 1
#define OFF 0



struct sp {
    int posx, posy, direction, typ, len;
    char *ptr;
} spos[100];
int vis_hver_gang = 1;
int sposp = 0;
int (* userinput_func)(void *p, int maks, int attr, int key, int func);
void (* useroutput_func)(void *p, int len);



/* Headere til funksjoner som ikke er definert i atread.h */
int  schoice(int tst, int funk, int stnd);
int  sgetsex(int tst, int funk, int stnd);



int schoice(int key, int func, int stnd)
{
    int c = '\0', x, y, stop = 0;

    x = wherex();
    y = wherey();
    if (stnd == 'J' || stnd == 'N')
        cprintf("%s", (stnd == 'J') ? "Ja " : "Nei");
    gotoxy(x, y);
    curson();
    while (!stop) {
        if ((c = getkey()) > 0)
            c = toupper(c);
        if (c == 'J' || c == 'N' || c == 13)
            stop = 1;
        else if (c == 27 || (-c >= 59 && -c <= 58 + func))
            stop = 1;
        else if (key && c < 0)
            stop = 1;
    }
    if (c == 13)
        c = stnd;
    if (c == 'J' || c == 'N')
        cprintf("%s", (c == 'J') ? "Ja " : "Nei");
    cursoff();
    return(c);
}

int sgetsex(int key, int func, int stnd)
{
    int c = '\0', x, y, stop = 0;

    x = wherex();
    y = wherey();
    if (stnd == 'K' || stnd == 'M')
        cprintf("%s", (stnd == 'K') ? "Kvinne" : "Mann  ");
    gotoxy(x, y);
    curson();
    while (!stop) {
        if ((c = getkey()) > 0)
            c = toupper(c);
        if (c == 'K' || c == 'M' || c == 13)
            stop = 1;
        else if (c == 27 || (-c >= 59 && -c <= 58 + func))
            stop = 1;
        else if (key && c < 0)
            stop = 1;
    }
    if (c == 13)
        c = stnd;
    if (c == 'K' || c == 'M')
        cprintf("%s", (c == 'K') ? "Kvinne" : "Mann  ");
    cursoff();
    return(c);
}

int floatinp(float *var, int len, int attr, int key, int func)
{
    char temp[20];
    int  c, x, y;

    x = wherex();
    y = wherey();
    sprintf(temp, "%*.2f", len, *var);
    c = lineinput(temp, len, attr, key, func);
    if (c != 27)
        *var = (float) atof(temp);
    gotoxy(x, y);
    cprintf("%*.2f", len, *var);
    gotoxy(x, y);
    return(c);
}

int doubleinp(double *var, int len, int attr, int key, int func)
{
    char temp[41];
    int  c, x, y;

    x = wherex();
    y = wherey();
    sprintf(temp, "%*.2f", len, *var);
    c = lineinput(temp, len, attr, key, func);
    if (c != 27)
        *var = atof(temp);
    gotoxy(x, y);
    cprintf("%*.2f", len, *var);
    gotoxy(x, y);
    return(c);
}

void def_atread(int (*infunc)(), void (*outfunc)())
                         /* Definerer funksjonene som skal kalles hvis
                            type = 7 i at() */
{
    userinput_func = infunc;
    useroutput_func = outfunc;
}

void outfloat(float *num, int len)
{
    char temp[20];

    sprintf(temp, "%*.2f", len, *num);
    cprintf("%s", temp);
}

void outdouble(double *num, int len)
{
    char temp[20];

    sprintf(temp, "%*.2f", len, *num);
    cprintf("%s", temp);
}

void atzero(void)
{
    sposp = 0;
    spos[sposp].typ = -1;
}

void at(int x, int y, int direction, void *ptr, int typ, int len)
{
    spos[sposp].posx = x;
    spos[sposp].posy = y;
    spos[sposp].direction = direction;
    spos[sposp].typ = typ;
    spos[sposp].len = len;
    spos[sposp].ptr = ptr;
    spos[++sposp].typ = 0;
}

void atread_show_fields(int status)
{
    vis_hver_gang = status;
}

void atread_visfelt(int nr)
{
    gotoxy(spos[nr].posx, spos[nr].posy);
    cprintf("%-*s", spos[nr].len, "\0");
    gotoxy(spos[nr].posx, spos[nr].posy);
    switch (spos[nr].typ) {
        case 1  : cprintf("%s", (char *) spos[nr].ptr);                              break;
        case 2  : cprintf("%*d", spos[nr].len, *((int *) spos[nr].ptr));            break;
        case 3  : outfloat((float *) spos[nr].ptr, spos[nr].len);                   break;
        case 4  : cprintf("%s", *((int *) spos[nr].ptr) == 0 ? "Kvinne" : "Mann  "); break;
        case 5  : cprintf("%s", *((int *) spos[nr].ptr) == 0 ? "Nei" : "Ja ");       break;
        case 6  : cprintf("%*ld", spos[nr].len, *((long *) spos[nr].ptr));          break;
        case 7  : useroutput_func(spos[nr].ptr, spos[nr].len);                      break;
        case 8  : outdouble((double *) spos[nr].ptr, spos[nr].len);                   break;
        default : ;
    }
}

int atread(int start)
{
    int q, pek = -1, c = 0, stop = 0;

    while (spos[++pek].typ > 0)
        atread_visfelt(pek);
    pek = start;
    while (spos[pek].typ > 0 && !stop) {
        for (q = 0; vis_hver_gang && spos[q].typ > 0; q++)
            if (spos[q].direction > 1)
                atread_visfelt(q);
        while (spos[pek].typ > 0 && spos[pek].direction != 2)
            ++pek;
        if (spos[pek].typ <= 0)
            stop = 1;
        gotoxy(spos[pek].posx, spos[pek].posy);
        switch (spos[pek].typ) {
            case 1  : c = lineinput(spos[pek].ptr, spos[pek].len, markattr(), 1, 0);          break;
            case 2  : c = intinp((int *) spos[pek].ptr, spos[pek].len, markattr(), 1, 0);     break;
            case 3  : c = floatinp((float *) spos[pek].ptr, spos[pek].len, markattr(), 1, 0); break;
            case 4  : c = sexinp((int *) spos[pek].ptr, markattr(), 1, 0);                    break;
            case 5  : c = yesnoinp((int *) spos[pek].ptr, markattr(), 1, 0);                  break;
            case 6  : c = longinp((long *) spos[pek].ptr, spos[pek].len, markattr(), 1, 0);   break;
            case 7  : c = userinput_func(spos[pek].ptr, spos[pek].len, markattr(), 1, 0);     break;
            case 8  : c = doubleinp((double *) spos[pek].ptr, spos[pek].len, markattr(), 1, 0); break;
            default : ;
        }
        if (c == -73)
            pek = 0;
        if (c == -81 || c == 27)
            stop = 1;
        if (c == -80 || c == 13)
            ++pek;
        if (c == -72)
            while (--pek > 0 && spos[pek].direction == 1)
                ;
    }
    atzero();
    return(c);
}
