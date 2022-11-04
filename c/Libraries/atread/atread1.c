#include <string.h>
#include <conio.h>

#include <basic.h>

#include "atread.h"



#define ON 1
#define OFF 0



int insertmd = 1;
int showins_x = 0, showins_y = 0, dontshowins = 0, showinsattr = -1;



/* Headere til funksjoner som ikke er definert i atread.h */
int  changepos(int *strengpos, int pluss, int maks, int linlen);
void show(char *lin, int maks, int linlen);



int getinsert(void)
{
    return insertmd;
}



void setinsert(int status)
{
    insertmd = status;
}



void showins(void)
{
    int ta, x, y, x1, y1, x2, y2, curs;
    struct text_info ti;

    if (!dontshowins && showins_x > 0 && showins_y > 0) {
        gettextinfo(&ti);
        x1 = ti.winleft;
        y1 = ti.wintop;
        x2 = ti.winright;
        y2 = ti.winbottom;
        x = wherex();
        y = wherey();
        curs = cursor();
        ta = ti.attribute;
        if (showinsattr >= 0)
            textattr(showinsattr);
        cursoff();
        window(1, 1, xmax(), ymax());
        gotoxy(showins_x, showins_y);
        if (insertmd)
            cprintf("Innsett");
        else
            cprintf("Erstatt");
        window(x1, y1, x2, y2);
        gotoxy(x, y);
        textattr(ta);
        if (curs)
            curson();
    }
}



void setshowins(int status)
{
    dontshowins = status ? 0 : 1;
}



void setshowinspos(int x, int y)
{
    showins_x = x;
    showins_y = y;
}



void setshowinsattr(int attr)
{
    showinsattr = attr;
}



int changepos(int *strengpos, int pluss, int maks, int linelen)
{
    int x, y, ret;

    if (*strengpos + pluss < maks && *strengpos + pluss >= 0) {
        *strengpos += pluss;
        y = *strengpos / linelen + 1;
        x = *strengpos - (y - 1) * linelen + 1;
        gotoxy(x, y);
        ret = 1;
    } else
        ret = 0;
    return ret;
}



void show(char *lin, int maks, int linelen)
{
    int x, y;

    x = wherex();
    y = wherey();
    cprintf("%.*s", maks - ((y - 1) * linelen + (x - 1)), lin + (y - 1) * linelen + x - 1);
    gotoxy(x, y);
}



int lineinput(char *lin, int maks, int attr, int key, int func)
{
    int q, l, c, numoflines, oldX, oldY, oldX1, oldY1, oldX2, oldY2;
    int linelen, linepos, curs, finish, tempattr;
    char oldlin[300];
    struct text_info ti;

    strcpy(oldlin, lin);
    gettextinfo(&ti);
    oldX1 = ti.winleft;
    oldY1 = ti.wintop;
    oldX2 = ti.winright;
    oldY2 = ti.winbottom;
    oldX = wherex();
    oldY = wherey();
    curs = cursor();
    tempattr = ti.attribute;
    l = strlen(lin);
    linelen = oldX2 - oldX1 - wherex() + 2;
    numoflines = maks / linelen;
    if (maks % linelen > 0)
        ++numoflines;
    if (numoflines > oldY2 - (oldY + oldY1 - 1) + 1)   /* Hvis det ikke er plass p† skjermen */
        return 0;
    for (q = l; q < maks; q++)
      *(lin + q) = ' ';
    *(lin + q) = '\0';
    window(oldX + oldX1 - 1, oldY + oldY1 - 1, oldX2, oldY2);
    textattr(attr);
    cursoff();
    show(lin, maks, linelen);
    finish = 0;
    linepos = 0;
    showins();
    while (!finish) {
        curson();
        c = getkey();
        cursoff();
        switch (c) {
            case  13 : finish = 1; break;
            case  25 : for (q = 0; q < l; q++)
                           *(lin + q) = ' ';
                       l = 0;
                       show(lin, maks, linelen);
                       if (!changepos(&linepos, -linepos, maks, linelen))
                           finish = 1;
                       break;
            case  27 : finish = 1; break;
            case -72 : if (!changepos(&linepos, -linelen, maks, linelen) && key)
                           finish = 1;
                       break;
            case -80 : if (!changepos(&linepos, linelen, maks, linelen) && key)
                           finish = 1;
                       break;
            case -75 : if (!changepos(&linepos, -1, maks, linelen) && key) {
                           finish = 1;
                           c = -72;
                       }
                       break;
            case -77 : if (!changepos(&linepos, 1, maks, linelen) && key) {
                           finish = 1;
                           c = -80;
                       }
                       break;
            case -71 : if (!changepos(&linepos, -linepos, maks, linelen))
                           finish = 1;
                       break;
            case -79 : if (!changepos(&linepos, l - linepos, maks, linelen))
                           if (!changepos(&linepos, l - linepos, maks, linelen))
                               finish = 1;
                       break;
            case -82 : insertmd = !insertmd;
                       showins();
                       break;
            case   8 : if (!changepos(&linepos, -1, maks, linelen))
                           break;
            case -83 : if (linepos < l) {
                           for (q = linepos; q < l - 1; q++)
                               *(lin + q) = *(lin + q + 1);
                           *(lin + --l) = ' ';
                           show(lin, maks, linelen);
                       }
                       break;
            default  : if (c < 0 && key)
                           finish = 1;
                       else if (-c >= 59 && -c <= 58 + func)
                           finish = 1;
                       else if (insertmd) {
                           for (q = maks - 1; q > linepos; --q)
                               *(lin + q) = *(lin + q - 1);
                           if (l < maks)
                               ++l;
                       }
                       if (c >= 0) {
                           *(lin + linepos) = (char) c;
                           if (linepos >= l)
                               l = linepos + 1;
                           if (l > maks)
                               l = maks;
                           show(lin, maks, linelen);
                           if (!changepos(&linepos, 1, maks, linelen)) {
                               finish = 1;
                               c = 13;
                           }
                       }
                       break;
        }
    }
    if (c == 27)
      strcpy(lin, oldlin);
    l = strlen(lin);
    for (q = l; q < maks; q++)
        *(lin + q) = ' ';
    *(lin + q) = '\0';
    gotoxy(1, 1);
    textattr(tempattr);
    show(lin, maks, linelen);
    while (*(lin + l - 1) == ' ' && l > 0)
      --l;
    *(lin + l) = '\0';
    window(oldX1, oldY1, oldX2, oldY2);
    gotoxy(oldX, oldY);
    if (curs)
      curson();
    return c;
}
