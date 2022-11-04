#include <stdlib.h>
#include <stdio.h>
#include <conio.h>
#include <io.h>
#include <fcntl.h>
#include <sys\stat.h>
#include <string.h>
#include <alloc.h>
#include <dos.h>

#include <basic.h>
#include <shhwin.h>
#include <scrlow.h>

#include "menykonf.h"


int feil, avbrutt = 0;

unsigned wuattr; /* Attributt p† det som er uthevet i vindu */
unsigned ftattr, frattr; /* Attributter p† feilmeldingsvinduet */
unsigned itattr, irattr; /* Attributter p† Info/Input-vinduer */

konfigdatastruct konfig;



/*
    SETTOPPSKJERM setter 80-tegns tekstmode.
*/
static void settoppskjerm(void)
{
    int md;

    md = (int) peekb(0x0040, 0x0049);
    if (md == BW40)
        textmode(BW80);
    else if (md == C40)
        textmode(C80);
    else if (md != MONO && md != C80 && md != BW80) {
        if ((unsigned) (peek(0x0040, 0x0010) & 48) == 48)
            textmode(MONO);
        else
            textmode(C80);
    }
    md = (int) peekb(0x0040, 0x0049);
    if (md == C80) {
        ftattr = 15 + 16 * 4;
        frattr = 14 + 16 * 4;
        itattr = 7 + 16 * 1;
        irattr = 14 + 16 * 1;
        wuattr = 15;
    } else {
        ftattr = frattr = itattr = irattr = 7 * 16;
        wuattr = 7;
    }
}


/*
    FEILMELDING lager et feilmeldingsvindu hvor s vises. Brukeren
    m† trykke Esc for † komme videre.
*/
static void feilmelding(char *s)
{
    makewindow(10, 6, 10 + strlen(s) + 17, 8, ftattr, frattr, " Feil ", 2);
    sent("%s.  Trykk ESC", s);
    curson();
    while (getkey() != 27)
        ;
    removewindow();
}


/*
    FJERNBLANKE fjerner alle Space fra en streng.
*/
static void fjernblanke(char *s)
{
    char *p1, *p2;

    p1 = p2 = s;
    while (*p1 != '\0')
        if (*p1 == ' ')
            ++p1;
        else
            *(p2++) = *(p1++);
    *p2 = *p1;
}


/*
    INPLIN er en erstatning for lineinput.
    max   - maks antall tegn i strengen.
    attr1 - attributt f›r gammel streng tas med
    attr2 - attributt etter at gammel streng er med eller forkastet.
*/
static int inplin(char *lin, int max, int attr1, int attr2)
{
    int q, l, c, stopp = 0, attr, ok = 0, nr, cur;
    int rx, ry; /* Virkelige x- og y-koordinater */
    struct text_info ti;
    char tmp[81];

    attr = attr1;
    gettextinfo(&ti);
    rx = ti.winleft + ti.curx - 1;
    ry = ti.wintop + ti.cury - 1;
    strcpy(tmp, lin);
    l = strlen(tmp);
    nr = l;
    if (nr >= max)
        nr = max - 1;
    cur = cursor();
    curson();
    while (!stopp) {
        for (q = 0; q < l && q < max; q++)
            showchar(rx + q, ry, *(tmp + q), attr);
        for (q = l; q < max; q++)
            showchar(rx + q, ry, ' ', attr);
        gotoxy(ti.curx + nr, ti.cury);
        c = getkey();
        if (!ok && c < 32)
            ok = 1;
        else if (!ok) {
            ok = 1;
            strcpy(tmp, "");
            l = 0;
            nr = 0;
        }
        attr = attr2;
        if (c == 9)
            c = -80;
        if (c > 0 && c < 32)
            switch (c) {
                case  8 : if (nr > 0) {         /* Ctrl-H - Backspace */
                              --nr;
                              c = -83;
                          }
                          break;
                case 13 : stopp = 1;    break;  /* Ctrl-M - Return */
                case 27 : stopp = 1;    break;  /* ESC */
                default : c = 0;        break;
            }
        if (c < 0)
            switch (c) {
                case  -71 : nr = 0;        break;
                case  -75 : if (nr > 0)
                                --nr;
                            break;
                case  -77 : if (nr < l)
                                ++nr;
                            break;
                case  -79 : nr = l;        break;
                case  -83 : if (l <= 0)
                                break;
                            for (q = nr; q < l; q++)
                                *(tmp + q) = *(tmp + q + 1);
                            l = strlen(tmp);
                            break;
                case  -72 :
                case  -80 :
                case  -81 : stopp = 1; break;

            }
        if (c >= 32) {
            for (q = max - 1; q >= nr; q--)
                *(tmp + q + 1) = *(tmp + q);
            *(tmp + nr) = c;
            *(tmp + max) = '\0';
            ++nr;
            if (l < max)
                ++l;
        }
        if (nr >= max)
            nr = max - 1;
    }
    q = strlen(tmp) - 1;
    while (q >= 0 && *(tmp + q) == ' ')
        *(tmp + q--) = '\0';
    if (c != 27)
        strcpy(lin, tmp);
    if (!cur)
        cursoff();
    return(c);
}


/*
    SKRIVMENYCOM oppdaterer dataomr†det i MENY.COM.
*/
static void skrivmenycom(void)
{
    FILE *f;
    int hdl;
    struct ftime ft;

    f = fopen("MENY.COM", "r+b");
    if (f != NULL) {
        getftime(fileno(f), &ft);
        fseek(f, 5L, SEEK_SET);
        if (fwrite(&konfig, sizeof(konfigdatastruct), 1, f) != 1) {
            feilmelding("Kunne ikke skrive til MENY.COM");
            feil = 1;
        }
        fclose(f);
        hdl = open("MENY.COM", O_RDWR);
        setftime(hdl, &ft);
        close(hdl);
    } else {
        feilmelding("Kunne ikke †pne MENY.COM");
        feil = 1;
    }
}


/*
    REDIGERDATA lar brukeren redigere opplysninger om hvor programmet
    skal installeres.
*/
static void redigerdata(void)
{
    int q, c, felt = 0, slutt = 0, l, attr;

    if (gettextmode() == C80)
        attr = (itattr & 240) + 11;
    else
        attr = itattr;
    gotoxy(1, 18);
    sent("Trykk ESC for † avbryte (utelate endringer)");
    gotoxy(15, 12);
    textattr(attr);
    cprintf("Diskenhet for menyprogrammet:");
    gotoxy(15, 13);
    cprintf("Katalog for menyprogrammet:");
    gotoxy(15, 15);
    cprintf("Diskenhet, katalog og navn p† COMMAND.COM:");
    do {
        textattr(attr);
        gotoxy(53, 12);
        putch('[');
        textattr(itattr);
        cprintf("%c:", konfig.disk + 'A');
        textattr(attr);
        putch(']');
        gotoxy(15, 14);
        putch('[');
        textattr(itattr);
        cprintf("%-40.40s", konfig.path);
        textattr(attr);
        putch(']');
        gotoxy(15, 16);
        putch('[');
        textattr(itattr);
        cprintf("%-40.40s", konfig.compath);
        textattr(attr);
        putch(']');
        textattr(itattr);
        switch (felt) {
            case 0 : gotoxy(54, 12);
                     textattr(wuattr);
                     putch('A' + konfig.disk);
                     gotoxy(54, 12);
                     textattr(itattr);
                     do {
                         curson();
                         c = getkey();
                         if (c == 9)
                             c = -80;
                         cursoff();
                         if (c >= 'a' && c <= 'z')
                             c = 'A' + c - 'a';
                     } while (c != 27 && c != 13 && c != -80 && c != -81 && (c < 'A' || c > 'Z'));
                     if (c >= 'A' && c <= 'Z') {
                         konfig.disk = c - 'A';
                         c = 13;
                     }
                     putch('A' + konfig.disk);
                     break;
            case 1 : gotoxy(16, 14);
                     c = inplin(konfig.path, 40, wuattr, itattr);
                     fjernblanke(konfig.path);
                     strupr(konfig.path);
                     if (konfig.path[strlen(konfig.path) - 1] == '\\')
                         konfig.path[strlen(konfig.path) - 1] = '\0';
                     l = strlen(konfig.path);
                     if (konfig.path[0] != '\\') {
                         for (q = l; q >= 0; q--)
                             *(konfig.path + q + 1) = *(konfig.path + q);
                         *(konfig.path) = '\\';
                     }
                     break;
            case 2 : gotoxy(16, 16);
                     c = inplin(konfig.compath, 40, wuattr, itattr);
                     fjernblanke(konfig.compath);
                     strupr(konfig.compath);
                     break;
        }
        switch (c) {
            case -80 :
            case  13 : ++felt; break;
            case -72 : if (felt > 0)
                           --felt;
                       break;
            case -81 : felt = 3; break;
            case  27 : slutt = 1; break;
        }
        if (felt > 2)
            slutt = 1;
    } while (!slutt);
    if (c == 27)
        avbrutt = 1;
}


/*
    KONFIGURER er selve hovedrutinen. Den popper opp konfigurasjons-
    vinduet p† skjermen, og lar brukeren angi ›nskede data.
*/
static void konfigurer(void)
{
    feil = 1;
    if (access("MENY.COM", 0) != 0) {
        feilmelding("Finner ikke MENY.COM i denne katalogen");
        return;
    }
    if (access("MENY.COM", 2) != 0) {
        feilmelding("MENY.COM er skrivebeskyttet");
        return;
    }
    if (access("MENYPROG.EXE", 0) != 0) {
        feilmelding("Finner ikke MENYPROG.EXE i denne katalogen");
        return;
    }
    feil = 0;
    konfig.disk = 2;
    strcpy(konfig.path, "\\MENY");
    strcpy(konfig.compath, "C:\\COMMAND.COM");
    makewindow(5, 3, 76, 22, itattr, irattr, " KONFIGURASJON AV MENY III ", 2);
    cursoff();
    cprintf("\r\n");
    sentln("Dette programmet gj›r det mulig † bestemme annen diskenhet");
    sentln("og katalog  for menyprogrammet  enn det som er standard. I");
    sentln("tillegg er det mulig † angi hvor  menyprogrammet skal lete");
    sentln("etter filen  COMMAND.COM,  som brukes  for †  starte andre");
    sentln("programmer.                                               ");
    cprintf("\r\n");
    sentln("Det er  viktig at alt  som tastes  inn her  er riktig, for");
    sentln("MENY.COM  gir ingen  feilmeldinger  hvis det  ikke  finner");
    sentln("filene der det er forventet.                              ");
    sentln("\r\n");
    redigerdata();
    if (!avbrutt)
        skrivmenycom();
    removewindow();
}




int main()
{
    settoppskjerm();
    cprintf("%s %s  --  (C) - %s Sverre H. Huseby, Oslo\r\n\n", NAVN, VER, DATO);
    if (coreleft() < 10000) {
        cprintf("For lite minne tilgjengelig.\r\n");
        exit(-1);
    }
    konfigurer();
    if (avbrutt)
        cprintf("Konfigureringen avbrutt av bruker.\r\n");
    else if (feil)
        cprintf("Konfigureringen avbrutt pga. feil.\r\n");
    else {
        cprintf("Menyprog.exe : %c:%s", 'A' + konfig.disk, konfig.path);
        if (konfig.path[strlen(konfig.path) - 1] != '\\')
            putch('\\');
        cprintf("MENYPROG.EXE\r\n");
        cprintf("Command.com  : %s\r\n", konfig.compath);
    }

    return 0;
}
