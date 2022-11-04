#pragma inline

#include <mem.h>
#include <stdlib.h>
#include <dos.h>
#include <conio.h>
#include <stdarg.h>
#include <string.h>

#include <basic.h>

#include "shhwin.h"



typedef struct {
    void * buf;
    int  wx1, wy1, wx2, wy2;
    int  cx1, cy1, cx2, cy2;
    int  pos_x, pos_y;
    int  attr;
    int  curs, inv;
} windowdata;

windowdata wind[NUM_OF_WIND + 1];
int        curr_wind = 0, exploding_windows = 1, window_shadow = 1;
unsigned far * lokal_scr_addr;




/*
    SET_EXPLODING_WINDOWS bestemmer om vinduene skal eksplodere eller ikke.
*/
void set_exploding_windows(int status)
{
    exploding_windows = status;
}


/*
    SET_WINDOW_SHADOW bestemmer om vinduene skal kaste skygge eller ikke.
*/
void set_window_shadow(int status)
{
    window_shadow = status;
}


/*
    CLRBOX er en hjelpefunksjon i forbindelse med vinduene. Den er ikke
    laget for Ü kalles av andre enn vindusfunksjonene.
    (x1, y1) - ùverste venstre hjõrne
    (x2, y2) - Nederste hõyre hjõrne
    tattr    - tekstattributt
    fattr    - rammeattributt
    frm      - Rammetype (0 - ingen, 1 - enkel, 2 - dobbel)
*/
void clrbox(int x1, int y1, int x2, int y2, int tattr, int fattr, int frm)
{
    unsigned char rammetegn[2][6] = { 'ƒ', '≥', '⁄', 'ø', '¿', 'Ÿ',
                                      'Õ', '∫', '…', 'ª', '»', 'º'  };
    unsigned xmx, ymx, col2;

    xmx = xmax() - 1;
    ymx = ymax() - 1;
    col2 = (xmx + 1) * 2;
    --x1; --y1; --x2; --y2;
    asm   push   ds
    asm   mov    ax, 0600h
    asm   mov    ch, BYTE PTR y1
    asm   mov    cl, BYTE PTR x1
    asm   mov    dh, BYTE PTR y2
    asm   mov    dl, BYTE PTR x2
    asm   mov    bh, BYTE PTR tattr
    asm   int    10h
    asm   cmp    BYTE PTR frm, 0
    asm   jne    fortsett
    asm   jmp    retur_fra_clrbox
fortsett:
    asm   mov    ax, [WORD PTR lokal_scr_addr + 2]
    asm   mov    es, ax
    asm   mov    ax, WORD PTR y1
    asm   mov    cx, WORD PTR col2
    asm   mul    cx
    asm   mov    di, WORD PTR x1
    asm   shl    di, 1
    asm   add    di, [WORD PTR lokal_scr_addr]
    asm   add    di, ax
    asm   push   di
    asm   lea    bx, rammetegn
    asm   cmp    WORD PTR frm, 2
    asm   jne    enkelramme
    asm   add    bx, 6
enkelramme:
    asm   mov    ah, BYTE PTR fattr
    asm   mov    al, [BYTE PTR ss: bx + 2]
    asm   stosw
    asm   mov    cx, WORD PTR x2
    asm   sub    cx, WORD PTR x1
    asm   dec    cx
    asm   js     hopp1
    asm   jcxz   hopp1
    asm   mov    al, [BYTE PTR ss: bx]
    asm   rep stosw
hopp1:
    asm   mov    al, [BYTE PTR ss: bx + 3]
    asm   stosw
    asm   pop    dx
    asm   mov    cx, WORD PTR y2
    asm   sub    cx, WORD PTR y1
    asm   dec    cx
    asm   js     hopp2
    asm   jcxz   hopp2
    asm   mov    al, [BYTE PTR ss: bx + 1]
    asm   push   bx
    asm   mov    bx, WORD PTR x2
    asm   sub    bx, WORD PTR x1
    asm   shl    bx, 1
loop1:
    asm   push   ax
    asm   mov    ax, WORD PTR col2
    asm   add    dx, ax
    asm   pop    ax
    asm   mov    di, dx
    asm   stosw
    asm   dec    di
    asm   dec    di
    asm   add    di, bx
    asm   stosw
    asm   cmp    [WORD PTR window_shadow], 0
    asm   je     foretaloop
    asm   push   ax
    asm   mov    ax, WORD PTR xmx
    asm   cmp    WORD PTR x2, ax
    asm   pop    ax
    asm   jae    foretaloop
    asm   push   ax
    asm   mov    al, 7
    asm   inc    di
    asm   stosb
    asm   pop    ax
    asm   push   ax
    asm   mov    ax, WORD PTR xmx
    asm   dec    ax
    asm   cmp    WORD PTR x2, ax
    asm   pop    ax
    asm   jae    foretaloop
    asm   push   ax
    asm   mov    al, 7
    asm   inc    di
    asm   stosb
    asm   pop    ax
foretaloop:
    asm   loop   loop1
    asm   push   ax
    asm   mov    ax, WORD PTR col2
    asm   add    dx, ax
    asm   pop    ax
    asm   pop    bx
hopp2:
    asm   mov    di, dx
    asm   mov    al, [BYTE PTR ss: bx + 4]
    asm   stosw
    asm   mov    cx, WORD PTR x2
    asm   sub    cx, WORD PTR x1
    asm   dec    cx
    asm   js     hopp3
    asm   jcxz   hopp3
    asm   mov    al, [BYTE PTR ss: bx]
    asm   rep stosw
hopp3:
    asm   mov    al, [BYTE PTR ss: bx + 5]
    asm   stosw
    asm   cmp    [WORD PTR window_shadow], 0
    asm   je     retur_fra_clrbox
    asm   push   ax
    asm   mov    ax, WORD PTR xmx
    asm   cmp    WORD PTR x2, ax
    asm   pop    ax
    asm   jae    tegn_skygge_nederst
    asm   push   ax
    asm   mov    al, 7
    asm   inc    di
    asm   stosb
    asm   pop    ax
    asm   push   ax
    asm   mov    ax, WORD PTR xmx
    asm   dec    ax
    asm   cmp    WORD PTR x2, ax
    asm   pop    ax
    asm   jae    tegn_skygge_nederst
    asm   push   ax
    asm   mov    al, 7
    asm   inc    di
    asm   stosb
    asm   pop    ax
tegn_skygge_nederst:
    asm   push   ax
    asm   mov    ax, WORD PTR ymx
    asm   cmp    WORD PTR y2, ax
    asm   pop    ax
    asm   jae    retur_fra_clrbox
    asm   add    dx, WORD PTR col2
    asm   add    dx, 5
    asm   mov    cx, WORD PTR x2
    asm   sub    cx, WORD PTR x1
    asm   dec    cx
    asm   js     retur_fra_clrbox
    asm   push   ax
    asm   mov    ax, WORD PTR xmx
    asm   cmp    WORD PTR x2, ax
    asm   pop    ax
    asm   jae    start_skygge_nederst
    asm   inc    cx
    asm   push   ax
    asm   mov    ax, WORD PTR xmx
    asm   dec    ax
    asm   cmp    WORD PTR x2, ax
    asm   pop    ax
    asm   jae    start_skygge_nederst
    asm   inc    cx
start_skygge_nederst:
    asm   jcxz   retur_fra_clrbox
    asm   mov    di, dx
    asm   mov    al, 7
loop2:
    asm   stosb
    asm   inc    di
    asm   loop   loop2
retur_fra_clrbox:
    asm   pop    ds
}

int makewindow(int x1, int y1, int x2, int y2, int txtattr, int frmattr,
               char * head, int frm)
{   /* Returnerer 1 hvis OK, 0 hvis ikke */

    int step = 6, minusx, minusy, x, y, wsize;
    struct text_info ti;

    if (x2 < x1 + (frm ? 2 : 0) || y2 < y1 + (frm ? 2 : 0))
        return(0);
    if (curr_wind >= NUM_OF_WIND)
        return(0);
    if (frm < 0 || frm > 2)
        return(0);
    lokal_scr_addr = find_scr_addr();
    wind[curr_wind].curs = cursor();
    cursoff();
    wsize = (x2 - x1 + 3) * (y2 - y1 + 2) * 2;
    wind[curr_wind].buf = (void *)malloc(wsize);
    if (wind[curr_wind].buf == NULL)
        return(0);
    x = y = 0;
    if (window_shadow && x2 <= xmax() - 2)
        ++x;
    if (window_shadow && x2 <= xmax() - 1)
        ++x;
    if (window_shadow && y2 <= ymax() - 1)
        ++y;
    gettext(x1, y1, x2 + x, y2 + y, wind[curr_wind].buf);
    gettextinfo(&ti);
    wind[curr_wind].pos_x = wherex();
    wind[curr_wind].pos_y = wherey();
    wind[curr_wind].inv = getinv();
    wind[curr_wind].attr = gettextattr();
    wind[curr_wind].wx1 = ti.winleft;
    wind[curr_wind].wy1 = ti.wintop;
    wind[curr_wind].wx2 = ti.winright;
    wind[curr_wind].wy2 = ti.winbottom;
    ++curr_wind;
    wind[curr_wind].cx1 = x1;
    wind[curr_wind].cy1 = y1;
    wind[curr_wind].cx2 = x2 + x;
    wind[curr_wind].cy2 = y2 + y;
    window(1, 1, ti.screenwidth, ti.screenheight);
    setinv(0);
    textattr(frmattr);
    if (exploding_windows) {
        x = (x2 - x1) / 2;
        y = (y2 - y1) / 2;
        if (x >= 3 && y >= 3) {
            if (step > x)
                step = x;
            if (step > y)
                step = y;
            minusx = x / step;
            minusy = y / step;
            delay(1);
            while (x >= 0 && y >= 0) {
                clrbox(x1 + x, y1 + y, x2 - x, y2 - y, txtattr, frmattr, frm);
                x -= minusx;
                y -= minusy;
                delay(20);
            }
        }
    }
    clrbox(x1, y1, x2, y2, txtattr, frmattr, frm);
    if (frm > 0) {
        gotoxy((x2 - x1 + 1) / 2 + x1 - (strlen(head) / 2), y1);
        cputs(head);
    }
    textattr(txtattr);
    if (frm == 0)
        window(x1, y1, x2, y2);
    else
        window(x1 + 1, y1 + 1, x2 - 1, y2 - 1);
    clrscr();
    if (wind[curr_wind - 1].curs)
        curson();
    return(1);
}

void removewindow(void)
{
    if (curr_wind <= 0)
        return;
    puttext(wind[curr_wind].cx1, wind[curr_wind].cy1, wind[curr_wind].cx2, wind[curr_wind].cy2, wind[curr_wind - 1].buf);
    --curr_wind;
    free(wind[curr_wind].buf);
    textattr(wind[curr_wind].attr);
    window(wind[curr_wind].wx1, wind[curr_wind].wy1, wind[curr_wind].wx2, wind[curr_wind].wy2);
    gotoxy(wind[curr_wind].pos_x, wind[curr_wind].pos_y);
    if (wind[curr_wind].curs)
        curson();
    else
        cursoff();
    setinv(wind[curr_wind].inv);
}
