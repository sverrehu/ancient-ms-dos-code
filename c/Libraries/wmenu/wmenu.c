#include <string.h>
#include <conio.h>
#include <dos.h>
#include <basic.h>
#include <window.h>
#include "wmenu.h"


struct menudata {
    char tekst[20][41];  /* nr. 0 er menyens navn */
    int  antvalg;
};

struct menudata menu[10];
int numofmenus = 0;
int m_ta = 112, m_tau = 7; /* Attr p† topplinjen (u er uthevet) */
int m_fa = 112, m_wta = 112, m_wtau = 7;



void setmenus(int ant)
{
    numofmenus = ant;
}

void newmenu(void)
{
    int q;

    for (q = 0; q < 10; q++)
        menu[q].antvalg = 0;
}

void addmitem(int m, char *txt)
{
    strncpy(menu[m].tekst[menu[m].antvalg++], txt, 40);
}

void showmenu(int m, int i)
{
    int q, x = 5, l = 0, ta;

    ta = gettextattr();
    for (q = 0; q < m; q++)
        x += strlen(menu[q].tekst[0]) + 4;
    gotoxy(x, 1);
    textattr(m_tau);
    cprintf(menu[m].tekst[0]);
    textattr(ta);
    if (i <= 0)
        return;
    for (q = 1; q < menu[m].antvalg; q++)
        if (strlen(menu[m].tekst[q]) > l)
            l = strlen(menu[m].tekst[q]);
    while (x + l + 4 > 80)
        --x;
    makewindow(x, 2, x + l + 4, 2 + menu[m].antvalg, m_wta, m_fa, "", 1);
    textattr(m_wta);
    for (q = 1; q < menu[m].antvalg; q++) {
        gotoxy(2, q);
        if (i == q)
            textattr(m_wtau);
        cprintf("%s ", menu[m].tekst[q]);
        if (i == q)
            textattr(m_wta);
    }
    textattr(ta);
}

void hidemenu(int m, int i)
{
    int q, x = 5, ta;

    ta = gettextattr();
    if (i > 0)
        removewindow();
    for (q = 0; q < m; q++)
        x += strlen(menu[q].tekst[0]) + 4;
    gotoxy(x, 1);
    textattr(m_ta);
    cprintf(menu[m].tekst[0]);
    textattr(ta);
}

void showmenuline(int m)
{
    int q;
    struct text_info ti;

    gettextinfo(&ti);
    window(1, 1, ti.screenwidth, ti.screenheight);
    if (gettextmode() == C80) {
        m_ta = 30;
        m_tau = 94;
        m_fa = 25;
        m_wta = 30;
        m_wtau = 94;
    }
    textattr(m_ta);
    lattr(1, m_ta);
    for (q = 0; q < numofmenus; q++) {
        cprintf("    ");
        if (q == m)
            textattr(m_tau);
        cprintf(menu[q].tekst[0]);
        if (q == m)
            textattr(m_ta);
    }
    textattr(ti.attribute);
    window(ti.winleft, ti.wintop, ti.winright, ti.winbottom);
    gotoxy(ti.curx, ti.cury);
}

char upcase(char chr)
{
    if (chr >= 'a' && chr <= 'z')
        return(chr + 'A' - 'a');
    switch (chr) {
        case '‘' : return('’');
        case '›' : return('');
        case '†' : return('');
        default  : return(chr);
    }
}

int menuchoice(int *m, int *i)
{
    int q, l, stopp = 0, c, curs;
    struct text_info ti;

    curs = cursor();
    cursoff();
    gettextinfo(&ti);
    window(1, 1, ti.screenwidth, ti.screenheight);
    if (gettextmode() == C80) {
        m_ta = 30;
        m_tau = 94;
        m_fa = 25;
        m_wta = 30;
        m_wtau = 94;
    }
    showmenuline(*m);
    showmenu(*m, *i);
    do {
        l = 0;
        for (q = 1; q < menu[*m].antvalg; q++)
            if (strlen(menu[*m].tekst[q]) > l)
                l = strlen(menu[*m].tekst[q]);
        c = getkey();
        switch (c) {
            case  13 : if (*i == 0 && menu[*m].antvalg > 1) {
                           *i = 1;
                           showmenu(*m, *i);
                       } else
                           stopp = 1;
                       break;
            case  27 : if (*i > 0)
                           removewindow();
                       *i = 0;
                       stopp = 1;
                       showmenuline(-1);
                       break;
            case -72 : if (*i == 0)
                           break;
                       gotoxy(2, *i);
                       textattr(m_wta);
                       cprintf("%s ", menu[*m].tekst[*i]);
                       if (*i == 1)
                           *i = menu[*m].antvalg - 1;
                       else if (*i > 1)
                           --*i;
                       gotoxy(2, *i);
                       textattr(m_wtau);
                       cprintf("%s ", menu[*m].tekst[*i]);
                       break;
            case -80 : if (menu[*m].antvalg == 1)
                           break;
                       if (*i > 0) {
                           gotoxy(2, *i);
                           textattr(m_wta);
                           cprintf("%s ", menu[*m].tekst[*i]);
                       }
                       if (*i == menu[*m].antvalg - 1 && *i > 1)
                           *i = 1;
                       else if (*i < menu[*m].antvalg - 1) {
                           ++*i;
                           if (*i == 1)
                               showmenu(*m, *i);
                       }
                       gotoxy(2, *i);
                       textattr(m_wtau);
                       cprintf("%s ", menu[*m].tekst[*i]);
                       break;
            case -75 : hidemenu(*m, *i);
                       --*m;
                       if (*m < 0)
                           *m = numofmenus - 1;
                       *i = 1;
                       if (*i >= menu[*m].antvalg)
                           *i = menu[*m].antvalg - 1;
                       showmenu(*m, *i);
                       break;
            case -77 : hidemenu(*m, *i);
                       ++*m;
                       if (*m >= numofmenus)
                           *m = 0;
                       *i = 1;
                       if (*i >= menu[*m].antvalg)
                           *i = menu[*m].antvalg - 1;
                       showmenu(*m, *i);
                       break;
            default  : if (menu[*m].antvalg < 2)
                           break;
                       gotoxy(2, *i);
                       textattr(m_wta);
                       cprintf("%s ", menu[*m].tekst[*i]);
                       q = *i + 1;
                       while (q < menu[*m].antvalg && upcase(menu[*m].tekst[q][0]) != upcase(c))
                           ++q;
                       if (q == menu[*m].antvalg) {
                           q = 1;
                           while (q < *i && upcase(menu[*m].tekst[q][0]) != upcase(c))
                               ++q;
                       }
                       *i = q;
                       gotoxy(2, *i);
                       textattr(m_wtau);
                       cprintf("%s ", menu[*m].tekst[*i]);
        }
    } while (!stopp);
    if (*i > 0)
        removewindow();
    textattr(ti.attribute);
    window(ti.winleft, ti.wintop, ti.winright, ti.winbottom);
    gotoxy(ti.curx, ti.cury);
    if (curs)
        curson();
    if (c == 27)
        return(c);
    else
        return(0);
}
