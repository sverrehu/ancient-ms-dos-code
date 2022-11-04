#pragma inline
/*
     Program som bruker det n†v‘rende vindu som editor.


         void ed_startopp(void);

     Sletter alle linjer og nullstiller variabler. Brukes kun en gang.


         int ed_leggtil(unsigned char * tekst);

     Legger til en angitt linje f›r editerin. Hvis det er mulig
     † gjennomf›re tillegget, returneres 0. Hvis ikke returneres
     et annet tall.


         int ed_editer (int status, int ins, int ind, int sattr);

     Hvis status er satt, brukes nederste linje i vinduet som statuslinje.
     For at dette skal v‘re mulig, m† det v‘re minst to linjer i
     vinduet, og det m† v‘re minst 40 tegn i bredden. Hvis dette ikke
     er oppfylt, returneres et annet tall enn 0.
     Hvis ins er satt, er innsettmodus p† ved oppstart.
     Hvis ind er satt, er indent p† ved oppstart.
     sattr er attributten som brukes p† statuslinjen.
     Hvis null returneres, er editeringen en suksess.


         int ed_antlinjer(void);

     Returnerer antall linjer etter rettingen.


         unsigned char * ed_linje(int nr);

     Denne funksjonen returnerer en peker til angitt linje i teksten.
     Den f›rste linjen er 0. Hvis linjen ikke eksisterer, returneres
     NULL.
     OBS: Linjene er ikke avsluttet med annet enn \0 !!

         void ed_ryddopp(void);

     Frigj›r alt brukt minne. Skal brukes for hver gang en tekst er
     editert som ikke skal editeres mer.
*/


#include <conio.h>
#include <stdlib.h>
#include <alloc.h>
#include <dos.h>
#include <string.h>

#include <basic.h>

#include "editor.h"


/*
     Alle globale variabler starter med ed_ for at de ikke skal blandes med
     andre under linking
*/


int ed_vinvidde;  /* Antall tegn som kan vises p† hver linje */
int ed_vinhoyde;  /* Antall linjer som kan vises */
int ed_relx;      /* X-posisjon i teksten relativt til venstre side av vinduet */
int ed_rely;      /* Y-posisjon i teksten relativt til toppen av vinduet */
int ed_linjenr;   /* Mark›rens posisjon i Y-retningen. Fra 0 !!! */
int ed_kolonne;   /* Mark›rens posisjon i X-retningen. Fra 0 !!! */
int ed_antlin;    /* Antall linjer under editering */
int ed_stat;      /* Skal status vises */
int ed_insstatus; /* Innsettmodus */
int ed_indent;    /* Indentstatus */
byte ed_sattr;    /* Attributt p† statuslinje */
unsigned char * ed_ln[makslinjer]; /* Pekere til hver linje */
unsigned char far * ed_skjerm;     /* Peker til skjermen */
unsigned char * scroll_buff;
int ed_origx, ed_origy;
byte ed_attr;

/* Headere til funksjoner som ikke er definert i editor.h */
int   ed_edlin(void);
void  ed_hent_skjermdata(void);
void  ed_nydelline(void);
void  ed_nyinsline(void);
int   ed_nylinje(void);
int   ed_ordtegn(int c);
void  ed_scrollhoyre(void);
void  ed_scrollned(void);
void  ed_scrollopp(void);
void  ed_scrollvenstre(void);
int   ed_settinnlinje(int l);
void  ed_slettlinje(int nr);
int   ed_tolktegn(int c);
void  ed_trim(int nr);
void  ed_visindent(void);
void  ed_visinsstatus(void);
void  ed_viskolonnenr(void);
void  ed_vislinje(int nr);
void  ed_vislinjenr(void);

#include "taster.c"   /* Inkluderer egen fil med funksjoner for hver
                         spesialtast */



void ed_hent_skjermdata(void)
{
    struct text_info ti;

    clrscr();
    gettextinfo(&ti);
    ed_skjerm = (unsigned char huge *) find_scr_addr();
    ed_origx = ti.winleft - 1;
    ed_origy = ti.wintop - 1;
    ed_attr = ti.attribute;
    ed_vinvidde = ti.winright - ti.winleft + 1;
    ed_vinhoyde = ti.winbottom - ti.wintop + 1;
    ed_relx = 0;
    ed_rely = 0;
    ed_linjenr = 0;
    ed_kolonne = 0;
    ed_stat = ed_insstatus = ed_indent = 1;
}

int ed_nylinje(void)
{
    if (ed_antlin >= makslinjer)
        return(1);
    if (coreleft() < 4096)
        return(1);
    ed_ln[ed_antlin] = (unsigned char *) malloc(makskolonner + 1); /* +1 for '\0' */
    if (ed_ln[ed_antlin] == NULL)
        return(1);
    ed_ln[ed_antlin][0] = '\0';   /* S›rger for at den nye linjen er tom */
    ++ed_antlin;
    return(0);
}

int ed_settinnlinje(int l)
{
    int q;
    unsigned char * tmp;

    if (ed_antlin >= makslinjer)
        return(1);
    if (coreleft() < 4096)
        return(1);
    tmp = (unsigned char *) malloc(makskolonner + 1); /* +1 for '\0' */
    if (tmp == NULL)
        return(1);
    for (q = ed_antlin; q > l; q--)
        ed_ln[q] = ed_ln[q - 1];
    if (ed_kolonne < strlen(ed_ln[l]))
        strcpy(tmp, ed_ln[l + 1] + ed_kolonne);
    else
        tmp[0] = '\0';   /* S›rger for at den nye linjen er tom */
    ed_ln[l][ed_kolonne] = '\0';
    ed_ln[l + 1] = tmp;
    ++ed_antlin;
    return(0);
}

void ed_slettlinje(int nr)
{
    int q;

    if (ed_ln[nr] != NULL)
        free(ed_ln[nr]);
    for (q = nr; q < ed_antlin; q++)
        ed_ln[q] = ed_ln[q + 1];
    --ed_antlin;
}

void ed_print(unsigned char far * s, int maks)
{
    byte y;

    y = wherey() - 1 + ed_origy;
    asm mov   cx, maks;
    asm cld;
    asm mov   al, 160;
    asm mul   BYTE PTR y;
    asm mov   bx, ed_origx;
    asm shl   bx, 1;
    asm add   ax, bx;
    asm les   di, ed_skjerm;
    asm add   di, ax;
    asm mov   ah, ed_attr;
    asm push  ds;
    asm lds   si, s;
    Gjenta:
    asm lodsb;
    asm cmp   al, 0;
    asm je    SHORT Alletegn;
    asm stosw;
    asm dec   cx;
    asm jnz   Gjenta;
    Alletegn:
    asm jcxz  SHORT Ferdig;
    asm mov   al, ' ';
    Gjenta2:
    asm stosw;
    asm dec   cx;
    asm jnz   Gjenta2;
    Ferdig:
    asm pop   ds;
}

void ed_print2(unsigned char far * s, byte attr, int x, int y)
{
    y += ed_origy - 1;
    x += ed_origx - 1;
    asm mov   al, 160;
    asm mul   BYTE PTR y;
    asm mov   bx, x;
    asm shl   bx, 1;
    asm add   ax, bx;
    asm les   di, ed_skjerm;
    asm add   di, ax;
    asm mov   ah, attr;
    asm push  ds;
    asm lds   si, s;
    asm cld;
    Gjenta:
    asm lodsb;
    asm cmp   al, 0;
    asm je    SHORT Ferdig;
    asm stosw;
    asm jmp   SHORT Gjenta;
    Ferdig:
    asm pop   ds;
}

void ed_vislinje(int nr)
{
    int c;

    c = cursor();
    cursoff();
    if (nr < ed_antlin && strlen(ed_ln[nr]) > ed_relx)
        ed_print((unsigned char far *) (ed_ln[nr] + ed_relx), ed_vinvidde - 1);
    else
        ed_print((unsigned char far *) " ", ed_vinvidde - 1);
    if (c)
        curson();
}

void ed_vistekst(void)
{
    int q, x, y;

    x = wherex();
    y = wherey();
    cursoff();
    for (q = 0; q < ed_vinhoyde; q++) {
        gotoxy(1, q + 1);
        ed_vislinje(q + ed_rely);
    }
    gotoxy(x, y);
    curson();
}

void ed_vislinjenr(void)
{
    char s[20];

    if (!ed_stat)
        return;
    sprintf(s, "%-5d", ed_linjenr + 1);
    ed_print2(s, ed_sattr, 11, ed_vinhoyde + 1);
}

void ed_viskolonnenr(void)
{
    char s[20];

    if (!ed_stat)
        return;
    sprintf(s, "%-3d", ed_kolonne + 1);
    ed_print2(s, ed_sattr, 27, ed_vinhoyde + 1);
}

void ed_visinsstatus(void)
{
    char s[20];

    if (!ed_stat)
        return;
    sprintf(s, "%s", ed_insstatus ? "Innsett" : "Erstatt");
    ed_print2(s, ed_sattr, 33, ed_vinhoyde + 1);
}

void ed_visindent(void)
{
    char s[20];

    if (!ed_stat)
        return;
    sprintf(s, "%s", ed_indent ? "Indent" : "      ");
    ed_print2(s, ed_sattr, 43, ed_vinhoyde + 1);
}

void ed_visstatus(void)
{
    int x, y, c, ta;

    if (!ed_stat)
        return;
    c = cursor();
    x = wherex();
    y = wherey();
    ta = gettextattr();
    cursoff();
    textattr(ed_sattr);
    gotoxy(1, ed_vinhoyde + 1);
    clreol();
    textattr(ta);
    ed_print2("    Linje 00000   Kolonne 000   Innsett   Indent ", ed_sattr, 1, ed_vinhoyde + 1);
    ed_vislinjenr();
    ed_viskolonnenr();
    ed_visinsstatus();
    ed_visindent();
    gotoxy(x, y);
    if (c)
        curson();
}

void ed_scrollopp(void)
{
    struct text_info ti;
    int x, y;

    if (ed_rely >= ed_antlin - ed_vinhoyde + 1)
        return;
    x = wherex();
    y = wherey();
    cursoff();
    gettextinfo(&ti);
    scrollu(ti.winleft, ti.wintop, ti.winright, ti.winbottom - ed_stat);
    gotoxy(1, ed_vinhoyde);
    ++ed_rely;
    ++ed_linjenr;
    ed_vislinje(ed_rely + ed_vinhoyde - 1);
    gotoxy(x, y);
    curson();
    ed_vislinjenr();
}

void ed_scrollned(void)
{
    struct text_info ti;
    int x, y;

    if (ed_rely == 0)
        return;
    x = wherex();
    y = wherey();
    cursoff();
    gettextinfo(&ti);
    scrolld(ti.winleft, ti.wintop, ti.winright, ti.winbottom - ed_stat);
    gotoxy(1, 1);
    --ed_rely;
    --ed_linjenr;
    ed_vislinje(ed_rely);
    gotoxy(x, y);
    curson();
    ed_vislinjenr();
}

void ed_scrollvenstre(void)
{
    int q, x, y;
    struct text_info ti;

    if (ed_relx >= makskolonner - ed_vinvidde + 1)
        return;
    x = wherex();
    y = wherey();
    cursoff();
    gettextinfo(&ti);
    gettext(ti.winleft + 1, ti.wintop, ti.winright, ti.winbottom - ed_stat, scroll_buff);
    puttext(ti.winleft, ti.wintop, ti.winright - 1, ti.winbottom - ed_stat, scroll_buff);
    ++ed_relx;
    ++ed_kolonne;
    for (q = 0; q < ed_vinhoyde; q++) {
        gotoxy(ed_vinvidde - 1, q + 1);
        if (ed_rely + q < ed_antlin && strlen(ed_ln[ed_rely + q]) >= ed_relx + ed_vinvidde - 1)
            putch(ed_ln[ed_rely + q][ed_relx + ed_vinvidde - 2]);
        else
            putch(' ');
    }
    gotoxy(x, y);
    curson();
    ed_viskolonnenr();
}

void ed_scrollhoyre(void)
{
    int q, x, y;
    struct text_info ti;

    if (ed_relx == 0)
        return;
    x = wherex();
    y = wherey();
    cursoff();
    gettextinfo(&ti);
    gettext(ti.winleft, ti.wintop, ti.winright - 2, ti.winbottom - ed_stat, scroll_buff);
    puttext(ti.winleft + 1, ti.wintop, ti.winright - 1, ti.winbottom - ed_stat, scroll_buff);
    --ed_relx;
    --ed_kolonne;
    for (q = 0; q < ed_vinhoyde; q++) {
        gotoxy(1, q + 1);
        if (ed_rely + q < ed_antlin && strlen(ed_ln[ed_rely + q]) >= ed_relx)
            putch(ed_ln[ed_rely + q][ed_relx]);
        else
            putch(' ');
    }
    gotoxy(x, y);
    curson();
    ed_viskolonnenr();
}

void ed_startopp(void)
{
    int q;

    ed_antlin = 0;
    for (q = 0; q < makslinjer; q++)  /* Nullstilling av linjepekere */
        ed_ln[q] = NULL;
    ed_hent_skjermdata();
}

void ed_ryddopp(void)
{
    int q;

    for (q = 0; q < ed_antlin; q++) {
        if (ed_ln[q] != NULL)
            free(ed_ln[q]);
        ed_ln[q] = NULL;
    }
    ed_antlin = 0;
    ed_relx = 0;
    ed_rely = 0;
    ed_linjenr = 0;
    ed_kolonne = 0;
}

int ed_leggtil(unsigned char * tekst)
{
    if (ed_nylinje())
        return(1);
    strncpy(ed_ln[ed_antlin - 1], tekst, makskolonner);
    if (ed_ln[ed_antlin - 1][strlen(ed_ln[ed_antlin - 1]) - 1] == '\n')
        ed_ln[ed_antlin - 1][strlen(ed_ln[ed_antlin - 1]) - 1] = '\0';
    return(0);
}

void ed_trim(int nr)
{
    int l;

    l = strlen(ed_ln[nr]);
    while (ed_ln[nr][--l] == ' ')
        ed_ln[nr][l] = '\0';
}

int ed_ordtegn(int c)
{
    if ((c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= 128 && c <= 173))
        return(1);
    else
        return(0);
}

void ed_nydelline(void)  /* Setter vindu uten statuslinje hvis n›dv */
{
    int y;
    struct text_info ti;

    y = wherey();
    if (ed_stat) {
        gettextinfo(&ti);
        window(ti.winleft, ti.wintop, ti.winright, ti.winbottom - 1);
    }
    gotoxy(1, y);
    delline();
    if (ed_stat)
        window(ti.winleft, ti.wintop, ti.winright, ti.winbottom);
    gotoxy(1, y);
}

void ed_nyinsline(void)  /* Setter vindu uten statuslinje hvis n›dv */
{
    int y, x;
    struct text_info ti;

    y = wherey();
    x = wherex();
    if (ed_stat) {
        gettextinfo(&ti);
        window(ti.winleft, ti.wintop, ti.winright, ti.winbottom - 1);
    }
    gotoxy(1, y);
    insline();
    if (ed_stat)
        window(ti.winleft, ti.wintop, ti.winright, ti.winbottom);
    gotoxy(x, y);
}

int ed_tolktegn(int c)
{
    int q, l;
    int ret = 0;

    if (ed_kolonne < makskolonner) {
        for (q = strlen(ed_ln[ed_linjenr]); q < ed_kolonne; q++)
            ed_ln[ed_linjenr][q] = ' ';
        ed_ln[ed_linjenr][q] = '\0';
    }
    if (c < 0) {                 /* Utvidet tastetrykk */
        switch (-c) {
            case 71 : ed_home();          break;
            case 72 : ed_pilopp();        break;
            case 73 : ed_pgup();          break;
            case 75 : ed_pilvenstre();    break;
            case 77 : ed_pilhoyre();      break;
            case 79 : ed_end();           break;
            case 80 : ed_pilned();        break;
            case 81 : ed_pgdn();          break;
            case 82 : ed_ins();           break;
            case 83 : ed_del();           break;
            case 115: ed_ordvenstre();    break;
            case 116: ed_ordhoyre();      break;
            case 117: ed_ctrlend();       break;
            case 118: ed_ctrlpgdn();      break;
            case 119: ed_ctrlhome();      break;
            case 132: ed_ctrlpgup();      break;
        }
    } else if (c >= 32)     /* Vanlig tegn */
        ret = ed_vanligtegn(c);
    else if (c < 32)        /* Ctrl - tast */
        switch (c) {
            case  8 : ed_bs();            break;
            case  9 : ed_tab();           break;
            case 10 : ed_ctrlJ();         break;
            case 13 : ed_return();        break;
            case 14 : ed_ctrlN();         break;
            case 25 : ed_ctrlY();         break;
        }
    return(ret);
}

int ed_edlin(void)
{
    int q, c = 0;

    while (c != 27)
        ed_tolktegn((c = getkey()));
    ed_trim(ed_linjenr);
    return(c);
}

int ed_editer(int status, int ins, int ind, int sattr)
{
    int c;

    ed_stat = status;
    ed_insstatus = ins;
    ed_indent = ind;
    ed_sattr = (byte) sattr;
    if (status && (ed_vinvidde < 50 || ed_vinhoyde < 2))
        return(1);
    if (status) {
        --ed_vinhoyde;
        ed_visstatus();
    }
    scroll_buff = malloc(ed_vinvidde * ed_vinhoyde * 2);
    if (scroll_buff == NULL)
        return(1);
    gotoxy(1, 1);
    ed_vistekst();
    ed_edlin();
    free(scroll_buff);
    if (status)
        ++ed_vinhoyde;
    return(0);
}

int ed_antlinjer(void)
{
    return(ed_antlin);
}

unsigned char * ed_linje(int nr)
{
    return(ed_ln[nr]);
}
