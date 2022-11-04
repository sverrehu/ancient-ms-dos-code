#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <conio.h>

#include <basic.h>

#include "atread.h"

#define ON 1
#define OFF 0


extern int schoice(int key, int func, int std);
extern int sgetsex(int key, int func, int std);




int getsex(int key, int func)
{
    int c = '\0', stop = 0;

    curson();
    while (!stop) {
        if ((c = getkey()) > 0)
            c = toupper(c);
        if (c == 'M' || c == 'K')
            stop = 1;
        else if (c == 27 || (-c >= 59 && -c <= 58 + func))
            stop = 1;
        else if (key && (c < 0 || c == 13))
            stop = 1;
    }
    if (c == 'M' || c == 'K')
        cprintf("%s", (c == 'M') ? "Mann  " : "Kvinne");
    cursoff();
    return(c);
}

int intinp(int *var, int len, int attr, int key, int func)
{
    char temp[20];
    int  c, x, y;

    x = wherex();
    y = wherey();
    sprintf(temp, "%*d", len, *var);
    c = lineinput(temp, len, attr, key, func);
    if (c != 27)
        *var = atoi(temp);
    gotoxy(x, y);
    cprintf("%*d", len, *var);
    gotoxy(x, y);
    return(c);
}

int longinp(long *var, int len, int attr, int key, int func)
{
    char temp[20];
    int  c, x, y;

    x = wherex();
    y = wherey();
    sprintf(temp, "%*ld", len, *var);
    c = lineinput(temp, len, attr, key, func);
    if (c != 27)
        *var = atol(temp);
    gotoxy(x, y);
    cprintf("%*ld", len, *var);
    gotoxy(x, y);
    return(c);
}

int sexinp(int *var, int attr, int key, int func)
{
    int  c, x, y;
    struct text_info ti;

    gettextinfo(&ti);
    x = wherex();
    y = wherey();
    textattr(attr);
    c = sgetsex(key, func, (*var == 0 ? 'K' : 'M'));
    textattr(ti.attribute);
    if (c == 'M' || c == 'K') {
        *var = (c == 'M') ? 1 : 0;
        c = 13;
    }
    gotoxy(x, y);
    cprintf("%s", *var == 0 ? "Kvinne" : "Mann  ");
    gotoxy(x, y);
    return(c);
}

int yesnoinp(int *var, int attr, int key, int func)
{
    int  c, x, y;
    struct text_info ti;

    gettextinfo(&ti);
    x = wherex();
    y = wherey();
    textattr(attr);
    c = schoice(key, func, (*var == 0 ? 'N' : 'J'));
    textattr(ti.attribute);
    if (c == 'J' || c == 'N') {
        *var = (c == 'J') ? 1 : 0;
        c = 13;
    }
    gotoxy(x, y);
    cprintf("%s", *var == 0 ? "Nei" : "Ja ");
    gotoxy(x, y);
    return(c);
}
