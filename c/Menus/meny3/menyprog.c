/*
#define DEBUG
*/

#ifndef __COMPACT__
#error Uriktig memory model! M† kompileres med Compact.
#endif
/* M† kompileres med Compact for at Minneoversikt skal virke */

#include <stdlib.h>
#include <stdio.h>
#include <conio.h>
#include <io.h>
#include <fcntl.h>
#include <sys\stat.h>
#include <dos.h>
#include <bios.h>
#include <string.h>
#include <alloc.h>
#include <dir.h>
#include <time.h>

#include <basic.h>
#include <shhwin.h>
#include <scrlow.h>

#include "menyprog.h"



configstruct config;
transblokkstruct transblokk;
transblokkstruct far * transadr; /* Adressen til blokken i MENY.COM */
menydatastruct meny, tmpmeny;
unsigned rattr, vattr, oattr, tattr; /* Virkelige attributter. Tar hensyn
                                        til skjermtype */
unsigned orig_rattr, orig_vattr, orig_oattr, orig_tattr;
unsigned uattr;  /* Attributt p† det som er uthevet */
unsigned wuattr; /* Attributt p† det som er uthevet i vindu */
unsigned ftattr, frattr; /* Attributter p† feilmeldingsvinduet */
unsigned htattr, hrattr; /* Attributter p† hjelpvinduet */
unsigned itattr, irattr; /* Attributter p† Info/Input-vinduer */

int visklokke = 1; /* Sann hvis hele klokke/dato m† vises */
int utgangskode;   /* 0 = avslutt, 1 = start program, 2 = DOS-skall */
int harvist = 0;   /* Er menyen vist f›rste gang? gjelder ved feilmeldinger. */
int tmode;         /* Orginalt tekstmodus */
char orig_overskrift [77];
int blanksek;      /* Antall sekunder til skjermblanking */




/*
    HENTTRANSBLOKK finner blokken fra MENY.COM og kopierer denne til
    en egen struct-variabel.
*/
static void henttransblokk(void)
{
  #ifndef DEBUG
    transadr = (transblokkstruct far *) MK_FP (peek(0x0040, 0x00F2), peek(0x0040, 0x00f0));
    movedata(FP_SEG(transadr), FP_OFF(transadr), _DS, (unsigned) &transblokk, sizeof(transblokkstruct));
    if (strcmp(transblokk.id, "MENY III  ") != 0) {
        clrscr();
        cprintf("Menyen m† startes med MENY.\r\n\n");
        exit(-1);
    }
    transblokk.prognavn[transblokk.len] = '\0';
  #else
    strcpy(transblokk.id, "MENY III  ");
    transblokk.feilkode = 0;
    strcpy(transblokk.menynavn, "MENY0000.MNY");
    transblokk.menyvalg = 0;
    strcpy(transblokk.progdir, "");
    transblokk.len = 0;
    strcpy(transblokk.prognavn, "\n");
    transblokk.vent = 0;
  #endif
}


/*
    SENDTRANSBLOKK kopierer dette programmets transblokk til den i
    programmet MENY.COM.
*/
static void sendtransblokk(void)
{
  #ifndef DEBUG
    int q, l;

    transblokk.len = (unsigned char) strlen(transblokk.prognavn);
    transblokk.progdsk = getdisk();
    /* Hvis ':' er en del av angitt directory, skal drive skilles ut */
    if (transblokk.progdir[1] == ':') {
        transblokk.progdsk = (transblokk.progdir[0] & 223) - 'A';
        l = strlen(transblokk.progdir) - 2;
        for (q = 0; q <= l; q++)
            transblokk.progdir[q] = transblokk.progdir[q + 2];
    }
    transblokk.prognavn[transblokk.len] = '\n';
    movedata(_DS, (unsigned) &transblokk, FP_SEG(transadr), FP_OFF(transadr), sizeof(transblokkstruct));
  #endif
}


static void trykkentast(void)
{
    struct text_info ti;

    gettextinfo(&ti);
    gotoxy(1, ti.screenheight);
    textattr(YELLOW + (RED << 4));
    cprintf("  Trykk en tast for † returnere til menyen ");
    clreol();
    getkey();
}


static void menyskjerm(void)
{
    tmode = gettextmode() & 255;
    if (tmode == BW40)
        textmode(BW80);
    else if (tmode == C40)
        textmode(C80);
    else if (tmode != MONO && tmode != C80 && tmode != BW80) {
        if ((unsigned) (peek(0x0040, 0x0010) & 48) == 48)
            textmode(MONO);
        else
            textmode(C80);
    } else if (screenrows() != 25) {
        textmode(tmode);
        tmode |= 0x100;
    }
    find_scr_addr();
    ftattr = 15 + 16 * 4;
    frattr = 14 + 16 * 4;
    htattr = 15 + 16 * 2;
    hrattr = 15 + 16 * 2;
    itattr =  0 + 16 * 7;
    irattr =  8 + 16 * 7;
    orig_rattr =  7 + 16 * 5;
    orig_vattr = 15 + 16 * 5;
    orig_oattr = 10 + 16 * 5;
    orig_tattr = 14 + 16 * 5;
    clrscr();
    cursoff();
    def_getkey(klokke);
    def_getkey_handler(hvertast);
    blanksek = 0;
}


static void dosskjerm(void)
{
    undef_getkey();
    undef_getkey_handler();
    textmode(tmode);
    textattr(7);
    clrscr();
    curson();
}


/*
    SETTOPPSKJERM finner skjermadressen, og setter 80-tegns, 25 linjers
    tekstmode. Tar vare p† original modus.

    Venter evt f›rst p† at brukeren trykker en tast
*/
static void settoppskjerm(void)
{
    menyskjerm();
}


static void systemvent(char *cmd)
{
    dosskjerm();
    cprintf("Utf›rer: \"%s\"\r\n", cmd);
    system(cmd);
    trykkentast();
    menyskjerm();
    vismeny();
}


/*
 *  Blanker skjermen, og venter til brukeren trykker en tast.
 */
static void skjermsparer(void)
{
    int q, l, x, y, vent = 0, width, height;
    struct text_info ti;

    blanksek = 0;
    undef_getkey();
    undef_getkey_handler();
    width = height = 0;
    for (q = 0; q < BLANK_LINES; q++) {
        if ((l = strlen(config.blank_tekst[q])) > width)
            width = l;
        if (!l)
            break;
        ++height;
    }
    gettextinfo(&ti);
    makewindow(1, 1, ti.screenwidth, ti.screenheight, 0, 0, "", 0);
    do {
        if (!vent) {
            clrscr();
            textcolor(random(7) + 1);
            x = 1 + random(ti.screenwidth - width);
            y = 1 + random(ti.screenheight - height);
            for (q = 0; q < height; q++) {
                gotoxy(x, y + q);
                cprintf("%s", config.blank_tekst[q]);
            }
            textattr(7);
            vent = 100;
        }
        delay(100);
        --vent;
    } while (!kbhit());
    getkey();
    removewindow();
    def_getkey(klokke);
    def_getkey_handler(hvertast);
}


/*
    FEILMELDING lager et feilmeldingsvindu hvor s vises. Brukeren
    m† trykke Esc for † komme videre.
*/
static void feilmelding(char *s)
{
    if (!harvist)
        vismeny();
    makewindow(10, 6, 10 + strlen(s) + 17, 8, ftattr, frattr, " Feil ", 2);
    sent("%s.  Trykk ESC", s);
    curson();
    while (getkey() != 27)
        ;
    removewindow();
}


/*
 *  Kalles for hvert tastetrykk, for † nullstille skjermblanker.
 */
static int hvertast(int c)
{
    blanksek = 0;
    return c;
}


/*
    KLOKKE g†r mens ingen tast er trykket. Viser tid og dato.
    Aktiviserer muligens en skjermbeskytter.
*/
static void klokke(void)
{
    int c;
    static struct time tid1;
    static struct date dato1;
    struct time tid2;
    struct date dato2;
    struct text_info ti;

    gettime(&tid2);
    getdate(&dato2);
    if (tid1.ti_sec != tid2.ti_sec || visklokke) {
        if (config.blanker_min && ++blanksek > config.blanker_min * 60)
            skjermsparer();
        c = cursor();
        cursoff();
        gettextinfo(&ti);
        window(1, 1, 80, 25);
        textattr(tattr);
        gotoxy(48, 3);
        cprintf("%02d", tid2.ti_sec);
        if (tid1.ti_min != tid2.ti_min || visklokke) {
            gotoxy(45, 3);
            cprintf("%02d:", tid2.ti_min);
            if (tid1.ti_hour != tid2.ti_hour || visklokke) {
                gotoxy(42, 3);
                cprintf("%02d:", tid2.ti_hour);
                if (dato1.da_day != dato2.da_day || visklokke) {
                    gotoxy(31, 3);
                    cprintf("%04d-%02d-%02d", dato2.da_year, dato2.da_mon, dato2.da_day);
                    dato1 = dato2;
                    visklokke = 0;
                }
            }
        }
        tid1 = tid2;
        textattr(ti.attribute);
        window(ti.winleft, ti.wintop, ti.winright, ti.winbottom);
        gotoxy(ti.curx, ti.cury);
        if (c)
            curson();
    }
}


/*
    HJELP viser hjelpeskjermen
*/
static void hjelp(void)
{
    int q;
    unsigned attr;

    if (gettextmode() == C80)
        attr = (htattr & 240) + 14;
    else
        attr = htattr;
    makewindow(10, 4, 71, 23, htattr, hrattr, "", 2);
    gotoxy(1, 2);
    textattr(attr);
    sentln("%s %s", NAVN, VER);
    sent("[versjon 1.0 ble laget i 1987]");
    gotoxy(1, 5);
    textattr(htattr);
    sentln("Skrevet i Borland C++ v3.1 (MENYPROG)");
    sentln("og Turbo Assembler v3.1 (MENY)");
    gotoxy(1, 8);
    sentln("Sverre H. Huseby");
    sentln("Lofthusvn. 11 B");
    sentln("0587 Oslo");
    sentln("Tlf: 901 63 579");
    sentln("E-mail: sverrehu@online.no");
    gotoxy(1, 13);
    for (q = 0; q < 60; q++)
        putch(196);
    textattr(attr);
    gotoxy(15, 14);
    cprintf("ESC");
    textattr(htattr);
    cprintf("       - Til hovedmenyen");
    textattr(attr);
    gotoxy(15, wherey() + 1);
    cprintf("Piltaster");
    textattr(htattr);
    cprintf(" - Flytt valgmark›r");
    textattr(attr);
    gotoxy(15, wherey() + 1);
    cprintf("Retur");
    textattr(htattr);
    cprintf("     - Utf›r uthevet valg");
    textattr(attr);
    gotoxy(15, wherey() + 1);
    cprintf("Bokstav");
    textattr(htattr);
    cprintf("   - Utf›r valg direkte");
    getkey();
    removewindow();
}


/*
    tegn_ok

    Sjekker om angitt tegn er OK som del av et filnavn.
    Brukes av minneoversikt3()
    Returnerer:
      0 - Ikke OK
      1 - OK
*/
static int tegn_ok(byte c)
{
    return ((c >= '@' && c <= 'Z') || (c >= '-' && c <= '9')
            || (c >= '#' && c <= ')') || c == '!' || c == '{' || c == '}'
            || c == '~' || c == '`' || c == '_');
}


/*
    MINNEOVERSIKT3 viser residente prgrammer i minnet. Dette er en rotete
    funksjon, fordi den er plukket ut og satt sammen av hele MMAP-programmet.
    Denne kalles bare for dosversjon <4, siden dos 4 og h›yere har andre m†ter
    † organisere minnet p†.
*/
static void minneoversikt3(void)
{
    #define MAXPRG 100
    #define ANTLIN 13

    int q, w;

    struct mcb_struct {
        char          type;
        unsigned      owner;
        unsigned      size;
        unsigned char reserved[11];
    } * mcb;

    struct prg_data {
        char     type;
        unsigned seg;
        unsigned owner;
        long     size;
        char     navn [13];
    } prg [MAXPRG];

    int antprg = 0;
    long ressize;
    long totmem;
    unsigned es, bx, meny_owner;
    char * env, * tnavn;
    char navn[120];


    if (_osmajor < 3) {
        feilmelding("Minneoversikt krever MS-DOS 3.00 eller h›yere");
        return;
    }
    memset(prg, 0, sizeof(struct prg_data) * MAXPRG);
    totmem = (long) (biosmemory() * 1024L);
    mcb = (struct mcb_struct *) MK_FP(_psp - 1, 0);
    meny_owner = mcb->owner;
    _AH = 0x52;
    geninterrupt(0x21);
    es = _ES;
    bx = _BX;
    mcb = (struct mcb_struct *) MK_FP(peek(es, bx - 2), 0);
    prg[antprg].type = 'M';
    prg[antprg].size = (long) ((unsigned) FP_SEG(mcb) * 16L);
    prg[antprg].owner = 0xFFFF;
    prg[antprg].seg = 0;
    strcpy(prg[antprg].navn, "SYSTEM");
    ++antprg;
    do {
        prg[antprg].type = mcb->type;
        prg[antprg].size = (long) ((unsigned) mcb->size * 16L);
        prg[antprg].owner = mcb->owner;
        prg[antprg].seg = (unsigned) FP_SEG(mcb);
        if (antprg == 1)
            strcpy(prg[antprg].navn, "CONFIG.SYS");
        else if (antprg == 2)
            strcpy(prg[antprg].navn, "DOS/SHELL");
        else if (mcb->owner == 0)
            strcpy(prg[antprg].navn, "???");
        else if (mcb->owner != meny_owner) {
            tnavn = navn;
            env = (char *) MK_FP(peek(mcb->owner, 0x2C), 0);
            for (q = 1; q < 32000 && !(*(env + q) == '\0' && *(env + q - 1) == '\0'); q++)
                ;
            if (*(env + q) == '\0' && *(env + q - 1) == '\0') {
                if (!strlen(env + q + 3))
                    strcpy(tnavn, "???");
                else {
                    strncpy(navn , env + q + 3, 118);
                    for (w = 0; w < strlen(navn); w++)
                        if (navn[w] == '\\' || navn[w] == ':')
                            tnavn = navn + w + 1;
                }
            } else
                strcpy(tnavn, "???");
            for (w = 0; w < strlen(tnavn) && tegn_ok(*(tnavn + w)); w++)
                ;
            if (w < strlen(tnavn))
                strcpy(tnavn, "???");
            strncpy(prg[antprg].navn, tnavn, 12);
        }
        if (mcb->owner != meny_owner)
            ++antprg;
        if (mcb->type != 'Z')
            mcb = (struct mcb_struct *) MK_FP(FP_SEG(mcb) + mcb->size + 1, 0);
    } while (mcb->type != 'Z' && antprg < MAXPRG);
    prg[antprg].type = 'Z';
    prg[antprg].size = totmem;
    prg[antprg].owner = 0xFFFE;
    prg[antprg].seg = 0;
    strcpy(prg[antprg].navn, "LEDIG MINNE");
    ++antprg;
    ressize = 0L;
    for (q = 0; q < antprg - 1; q++) {
        ressize += prg[q].size;
        if (prg[q].type != 'M' && prg[q].type != 'Z')
            continue;
        if (prg[q].owner == 0) {
            prg[q].type = ' ';
            continue;
        }
        for (w = q + 1; w < antprg; w++) {
            if (prg[w].type != 'M' && prg[w].type != 'Z')
                continue;
            if (prg[w].owner == prg[q].owner) {
                prg[q].size += prg[w].size;
                prg[w].type = ' ';
            }
        }
    }
    prg[antprg - 1].size -= ressize;
    makewindow(3, 5, 78, 8 + ANTLIN, itattr, irattr, " MINNEOVERSIKT ", 2);
    cursoff();
    for (q = 0; q < ANTLIN; q++) {
        gotoxy(38, 2 + q);
        putch(179);
    }
    q = 0;
    w = 1;
    while (q < antprg) {
        if (prg[q].type != 'M' && prg[q].type != 'Z') {
            ++q;
            continue;
        }
        gotoxy((w <= ANTLIN) ? 3 : 41, 1 + ((w > ANTLIN) ? (w - ANTLIN) : w));
        cprintf("  %-13.13s  %6ld  ", prg[q].navn, prg[q].size);
        if ((int) (prg[q].size * 100L / totmem) < 1)
            cprintf("(<1%%)");
        else
            cprintf("(%2d%%)", (int) (prg[q].size * 100L / totmem));
        ++q;
        ++w;
    }
    getkey();
    removewindow();
}


static void minneoversikt4(void)
{
    systemvent("mem /c | more");
}


static void minneoversikt(void)
{
    if (_osmajor < 4)
        minneoversikt3();
    else
        minneoversikt4();
}


/*
    FINN_REELLE_ATTRIBUTTER kopierer menyens attributter til
    de reelle. Hvis skjermen ikke skal vise farger, ordnes dette.
*/
static void finn_reelle_attributter(void)
{
    rattr = meny.rattr;
    vattr = meny.vattr;
    oattr = meny.oattr;
    tattr = meny.tattr;
    if (gettextmode() != C80) {
        rattr = vattr = oattr = tattr = 7;
        ftattr = frattr = htattr = hrattr = itattr = irattr = 7 * 16;
        wuattr = 7;
    } else
        wuattr = 15;
    if (vattr / 16 == 0)
        uattr = 7 * 16;
    else
        uattr = 15;
}


/*
    TOMMENY t›mmer alle valgene i menyen, og setter attributter til
    standard. De reelle attributtene oppdateres.
*/
static void tommeny(void)
{
    int q;

    memset(&meny, 0, sizeof(menydatastruct));
    sprintf(meny.typetekst, "Datafil for MENY III.\r\n%c", 26);
    meny.versjon = VER_NUM;
    meny.rattr = orig_rattr;
    meny.vattr = orig_vattr;
    meny.oattr = orig_oattr;
    meny.tattr = orig_tattr;
    if (strcmp(transblokk.menynavn, "MENY0000.MNY") == 0)
        strcpy(meny.overskrift, "H O V E D M E N Y");
    else
        strcpy(meny.overskrift, orig_overskrift);
    for (q = 0; q < ANTVALG; q++)
        meny.valg[q].tast = 'A' + q;
    finn_reelle_attributter();
}


/*
    FINN_NYTT_NAVN finner et nytt menyfilnavn.
*/
static char * finn_nytt_navn(void)
{
    int q = 0;
    static char navn[13];

    do {
        sprintf(navn, "MENY%04d.MNY", q++);
    } while (access(navn, 0) == 0);
    return(navn);
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
    SKRIVMENY skriver menyen med navn i transblokk.menynavn ut p† fil.
*/
static void skrivmeny(void)
{
    int fh;


    if (access(transblokk.menynavn, 0) == 0 && access(transblokk.menynavn, 2) != 0)
        chmod(transblokk.menynavn, S_IREAD | S_IWRITE);
    if ((fh = _creat(transblokk.menynavn, 0)) != -1) {
        if (_write(fh, &meny, sizeof(menydatastruct)) != sizeof(menydatastruct))
            feilmelding("Feil under skriving av menyfil");
        _close(fh);
    } else
        feilmelding("Kunne ikke †pne menyfil for skriving");
}


/*
    HENTMENY henter menyen i transblokk.menynavn og s›rger for
    at de reelle attributtene settes riktig.
*/
static void hentmeny(void)
{
    int q, fh;


    if (access(transblokk.menynavn, 0) != 0) {
        tommeny();
        skrivmeny();
    } else {
        if ((fh = _open(transblokk.menynavn, O_RDONLY)) != -1) {
            /*
             *  Sjekk om muligens menyfil fra en tidligere versjon
             */
            if (filelength(fh) == 2187L) {
                menydatastruct_pre_1_5 old_meny;
                tommeny();
                if (_read(fh, &old_meny, sizeof(menydatastruct_pre_1_5))
                    != sizeof(menydatastruct_pre_1_5))
                    feilmelding("Kunne ikke lese menyfil");
                else {
                    strcpy(meny.typetekst, old_meny.typetekst);
                    strcpy(meny.overskrift, old_meny.overskrift);
                    meny.rattr = old_meny.rattr;
                    meny.vattr = old_meny.vattr;
                    meny.oattr = old_meny.oattr;
                    meny.tattr = old_meny.tattr;
                    for (q = 0; q < ANTVALG; q++) {
                        strcpy(meny.valg[q].tekst, old_meny.valg[q].tekst);
                        meny.valg[q].meny = old_meny.valg[q].meny;
                        strcpy(meny.valg[q].menyfil, old_meny.valg[q].menyfil);
                        strcpy(meny.valg[q].progdir, old_meny.valg[q].progdir);
                        strcpy(meny.valg[q].prognavn, old_meny.valg[q].prognavn);
                        meny.valg[q].tast = 'A' + q;
                    }
                }
            } else if (filelength(fh) == 2217L) {
                menydatastruct_pre_1_7 old_meny;
                tommeny();
                if (_read(fh, &old_meny, sizeof(menydatastruct_pre_1_7))
                    != sizeof(menydatastruct_pre_1_7))
                    feilmelding("Kunne ikke lese menyfil");
                else {
                    strcpy(meny.typetekst, old_meny.typetekst);
                    strcpy(meny.overskrift, old_meny.overskrift);
                    meny.rattr = old_meny.rattr;
                    meny.vattr = old_meny.vattr;
                    meny.oattr = old_meny.oattr;
                    meny.tattr = old_meny.tattr;
                    for (q = 0; q < ANTVALG; q++) {
                        strcpy(meny.valg[q].tekst, old_meny.valg[q].tekst);
                        meny.valg[q].meny = old_meny.valg[q].meny;
                        strcpy(meny.valg[q].menyfil, old_meny.valg[q].menyfil);
                        strcpy(meny.valg[q].progdir, old_meny.valg[q].progdir);
                        strcpy(meny.valg[q].prognavn, old_meny.valg[q].prognavn);
                        meny.valg[q].tast = 'A' + q;
                    }
                }
            } else if (_read(fh, &meny, sizeof(menydatastruct)) != sizeof(menydatastruct)) {
                tommeny();
                feilmelding("Kunne ikke lese menyfil");
            }
            _close(fh);
        } else
            feilmelding("Kunne ikke †pne menyfil for lesing");
    }
    orig_rattr = meny.rattr;
    orig_tattr = meny.tattr;
    orig_oattr = meny.oattr;
    orig_vattr = meny.vattr;
    finn_reelle_attributter();
}


/*
    VISMENY viser n†v‘rende meny p† skjermen. Etter at menyen er vist, blir
    ogs† en feilmelding vist hvis transblokk.feilkode != 0.
*/
static void vismeny(void)
{
    int q;
    int keys_sep[] = { 17, 33, 48, 64 };

    textattr(rattr);
    clrscr();
    showchar(1, 1, 201, rattr);
    showchar(80, 1, 187, rattr);
    showchar(1, 25, 200, rattr);
    showchar(80, 25, 188, rattr);
    for (q = 2; q < 80; q++) {
        showchar(q, 1, 205, rattr);
        showchar(q, 4, 205, rattr);
        showchar(q, 6, 196, rattr);
        showchar(q, 22, 205, rattr);
        showchar(q, 25, 205, rattr);
    }
    for (q = 2; q < 25; q++) {
        showchar(1, q, 186, rattr);
        showchar(80, q, 186, rattr);
    }
    showchar(1, 4, 204, rattr);
    showchar(80, 4, 185, rattr);
    showchar(1, 6, 199, rattr);
    showchar(80, 6, 182, rattr);
    showchar(1, 22, 204, rattr);
    showchar(80, 22, 185, rattr);
    for (q = 7; q < 22; q++)
        showchar(41, q, 179, rattr);
    showchar(41, 6, 194, rattr);
    textattr(tattr);
    clrarea(2, 2, 79, 3);
    clrarea(2, 23, 79, 24);
    gotoxy(1, 2);
    sent("%s %s  --  (C) %s - Sverre H. Huseby, Oslo", NAVN, VER, DATO);
    gotoxy(2, 23);
    cprintf("F1 Informasjon   F3 Slett valg  F5 Fargevalg    F9 Minnebruk    F10 DOS-skall");
    gotoxy(2, 24);
    cprintf("F2 Rediger valg  F4 Overskrift  F6 Div.oppsett                  Alt+X Avslutt");
    for (q = 0; q < sizeof(keys_sep) / sizeof(int); q++) {
        showchar(keys_sep[q], 22, 209, rattr);
        showchar(keys_sep[q], 23, 179, rattr);
        showchar(keys_sep[q], 24, 179, rattr);
        showchar(keys_sep[q], 25, 207, rattr);
    }
    showchar(41, 22, 207, rattr);
    textattr(oattr);
    clrarea(2, 5, 79, 5);
    gotoxy(1, 5);
    sent(meny.overskrift);
    textattr(vattr);
    clrarea(2, 7, 40, 21);
    clrarea(42, 7, 79, 21);
    for (q = 0; q < 7; q++) {
        showchar(3, 8 + q * 2, meny.valg[q].tast, vattr);
        showchar(5, 8 + q * 2, '-', vattr);
        showchar(43, 8 + q * 2, meny.valg[q + 7].tast, vattr);
        showchar(45, 8 + q * 2, '-', vattr);
    }
    for (q = 0; q < 7; q++) {
        gotoxy(8, 8 + q * 2);
        cprintf("%s", meny.valg[q].tekst);
        gotoxy(48, 8 + q * 2);
        cprintf("%s", meny.valg[7 + q].tekst);
    }
    visklokke = 1;
    harvist = 1;
    if (transblokk.feilkode) {
        switch (transblokk.feilkode) {
            case 1 : feilmelding("Feil under fors›k p† oppstart av COMMAND.COM"); break;

        }
        transblokk.feilkode = 0;
    }
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
        else if (c == -15)
            c = -72;
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
    JA_NEI er en erstatning for choice.
    std er peker til variablen som skal endres. 1 = ja, 0 = nei.
*/
static int ja_nei(int *std, int attr1, int attr2)
{
    int c, cur, x, y;

    cur = cursor();
    x = wherex();
    y = wherey();
    textattr(attr1);
    cprintf("%s", *std ? "Ja " : "Nei");
    gotoxy(x, y);
    textattr(attr2);
    curson();
    do {
        c = getkey();
        if (c == 'n')
            c = 'N';
        else if (c == 'j')
            c = 'J';
    } while (c != 27 && c != 13 && c != -15 && c != 9 && c != -72 && c != -80 && c != -81 && c != 'J' && c != 'N');
    if (c == 9)
        c = -80;
    else if (c == -15)
        c = -72;
    else if (c == 'J' || c == 'N') {
        *std = (c == 'J') ? 1 : 0;
        c = 13;
    }
    cprintf("%s", *std ? "Ja " : "Nei");
    if (!cur)
        cursoff();
    return(c);
}


/*
    INNEHOLDER_UNDERMENY sjekker om angitt menyfil inneholder undermenyvalg,
    og returnerer bolsk verdi.
*/
static int inneholder_undermeny(char *menynavn)
{
    int q, ret = 0;
    int fh;

    if (access(menynavn, 0) == 0) {
        if ((fh = _open(menynavn, O_RDONLY)) != -1) {
            if (_read(fh, &tmpmeny, sizeof(menydatastruct)) == sizeof(menydatastruct))
                for (q = 0; q < ANTVALG; q++)
                    if (strlen(tmpmeny.valg[q].tekst) && tmpmeny.valg[q].meny)
                        ret = 1;
            _close(fh);
        }
    }
    return(ret);
}


static void insert_space(char *s, int maks)
{
    int l;
    char *p, tmp[81];

    l = (strlen(s) * 2) - 1;
    if (l > maks || l <= 1)
        return;
    strcpy(tmp, s);
    p = tmp;
    do {
        *s++ = *p;
        if (*(p + 1))
            *s++ = ' ';
    } while (*p++);
}


/*
    REDIGERVALG lar brukeren redigere uthevet menyvalg.
*/
static void redigervalg(void)
{
    int q, c, felt = 0, slutt = 0, l, attr;
    valgdatastruct tmp;
    transblokkstruct tmptrans;

    strcpy(tmp.tekst, meny.valg[transblokk.menyvalg].tekst);
    tmp.meny = meny.valg[transblokk.menyvalg].meny;
    strcpy(tmp.menyfil, meny.valg[transblokk.menyvalg].menyfil);
    strcpy(tmp.progdir, meny.valg[transblokk.menyvalg].progdir);
    strcpy(tmp.prognavn, meny.valg[transblokk.menyvalg].prognavn);
    tmp.vent = meny.valg[transblokk.menyvalg].vent;

    makewindow(5, 6, 76, 18, itattr, irattr, " REDIGERING AV UTHEVET VALG ", 2);
    if (gettextmode() == C80)
        attr = (itattr & 240) + 6;
    else
        attr = itattr;
    gotoxy(3, 2);
    textattr(attr);
    cprintf("Tekst");
    gotoxy(3, 4);
    cprintf("Er dette en undermeny?");
    do {
        textattr(attr);
        gotoxy(23, 2);
        putch('[');
        textattr(itattr);
        cprintf("%-30.30s", tmp.tekst);
        textattr(attr);
        putch(']');
        gotoxy(28, 4);
        putch('[');
        textattr(itattr);
        cprintf("%s", tmp.meny ? "Ja " : "Nei");
        textattr(attr);
        putch(']');
        if (!tmp.meny) {
            gotoxy(3, 6);
            cprintf("Diskenhet / katalog [");
            textattr(itattr);
            cprintf("%-45.45s", tmp.progdir);
            textattr(attr);
            putch(']');
            gotoxy(3, 8);
            cprintf("Startkommando       [");
            textattr(itattr);
            cprintf("%-45.45s", tmp.prognavn);
            textattr(attr);
            putch(']');
            gotoxy(3, 10);
            cprintf("Vent p† tast?       [");
            textattr(itattr);
            cprintf("%s", tmp.vent ? "Ja " : "Nei");
            textattr(attr);
            putch(']');
        } else {
            gotoxy(3, 6);
            clreol();
            gotoxy(3, 8);
            clreol();
            gotoxy(3, 10);
            clreol();
        }
        switch (felt) {
            case 0 : gotoxy(24, 2);
                     c = inplin(tmp.tekst, 30, wuattr, itattr);
                     if (!strlen(tmp.tekst))
                         c = 27;
                     break;
            case 1 : gotoxy(29, 4);
                     c = ja_nei(&tmp.meny, wuattr, itattr);
                     if (!tmp.meny && strlen(tmp.menyfil)) {
                         /* Velges NEI n†r tidligere undermeny ? */
                         if (inneholder_undermeny(tmp.menyfil)) {
                             feilmelding("Inneholder undermeny(er). Kan ikke fjernes");
                             tmp.meny = 1;
                         } else {
                             q = 0;
                             makewindow(10, 9, 71, 14, ftattr, frattr, " VERIFISERING ", 2);
                             gotoxy(1, 2);
                             sentln("OBS: Den tidligere undermenyen vil bli slettet!");
                             sent("Fortsette?     ");
                             gotoxy(wherex() - 2, wherey());
                             l = ja_nei(&q, wuattr, ftattr);
                             if (l != 27 && q)
                                 strcpy(tmp.menyfil, "");
                             else
                                 tmp.meny = 1;
                             removewindow();
                         }
                     } else if (tmp.meny && !strlen(tmp.menyfil)) {
                         /* Velges JA n†r IKKE tidligere undermeny ? */
                         strcpy(tmp.menyfil, finn_nytt_navn());
                     }
                     break;
            case 2 : gotoxy(24, 6);
                     c = inplin(tmp.progdir, 45, wuattr, itattr);
                     fjernblanke(tmp.progdir);
                     if (tmp.progdir[strlen(tmp.progdir) - 1] == '\\')
                         tmp.progdir[strlen(tmp.progdir) - 1] = '\0';
                     l = strlen(tmp.progdir);
                     break;
            case 3 : gotoxy(24, 8);
                     c = inplin(tmp.prognavn, 45, wuattr, itattr);
                     break;
            case 4 : gotoxy(24, 10);
                     c = ja_nei(&tmp.vent, wuattr, itattr);
                     break;
        }
        switch (c) {
            case -80 :
            case  13 : ++felt; break;
            case -72 : if (felt > 0)
                           --felt;
                       break;
            case -81 : felt = 5; break;
            case  27 : slutt = 1; break;
        }
        if ((!tmp.meny && felt > 4) || (tmp.meny && felt > 1))
            slutt = 1;
    } while (!slutt);
    removewindow();
    if (c != 27) {
        if (tmp.meny && !meny.valg[transblokk.menyvalg].meny) {
             tmpmeny = meny;
             tmptrans = transblokk;
             strcpy(transblokk.menynavn, tmp.menyfil);
             strcpy(orig_overskrift, tmp.tekst);
             strupr(orig_overskrift);
             insert_space(orig_overskrift, 76);
             tommeny();
             strcpy(orig_overskrift, "");
             skrivmeny();
             meny = tmpmeny;
             transblokk = tmptrans;
        }
        strcpy(meny.valg[transblokk.menyvalg].tekst, tmp.tekst);
        if (meny.valg[transblokk.menyvalg].meny && !tmp.meny)
            unlink(meny.valg[transblokk.menyvalg].menyfil);
        meny.valg[transblokk.menyvalg].meny = tmp.meny;
        strcpy(meny.valg[transblokk.menyvalg].menyfil, tmp.menyfil);
        strcpy(meny.valg[transblokk.menyvalg].progdir, "");
        strcpy(meny.valg[transblokk.menyvalg].progdir, tmp.progdir);
        strcpy(meny.valg[transblokk.menyvalg].prognavn, tmp.prognavn);
        meny.valg[transblokk.menyvalg].vent = tmp.vent;
        skrivmeny();
    }
}


/*
    FARGEVALG lar brukeren endre fargeoppsettet.
*/
static void fargevalg(void)
{
    int q, w, c;
    unsigned farge[5], attr;

    farge[0] = (meny.rattr / 16) & 7;
    farge[1] = meny.rattr & 15;
    farge[2] = meny.tattr & 15;
    farge[3] = meny.oattr & 15;
    farge[4] = meny.vattr & 15;
    makewindow(20, 4, 61, 24, itattr, irattr, " VALG AV FARGER ", 2);
    gotoxy(1, 18);
    sentln("Piler - flytt     Return - ferdig");
    sent("ESC - avbryt");
    gotoxy(3, 2);
    cprintf("Bakgrunn");
    gotoxy(3, 5);
    cprintf("Ramme");
    gotoxy(3, 8);
    cprintf("Topp- og bunntekst");
    gotoxy(3, 11);
    cprintf("Overskrift");
    gotoxy(3, 14);
    cprintf("Menyvalg");
    gotoxy(3, 3);
    for (q = 0; q < 8; q++) {
        textcolor(q);
        putch(219);
    }
    for (w = 0; w < 4; w++) {
        gotoxy(3, 6 + 3 * w);
        for (q = 0; q < 16; q++) {
            textcolor(q);
            putch(219);
        }
    }
    textattr(itattr);
    w = 0;
    do {
        textbackground(farge[0]);
        clrarea(47, 10, 57, 15);
        attr = farge[0] * 16 + farge[1];
        showchar(47, 10, 201, attr);
        for (q = 11; q <= 15; q++)
            showchar(47, q, 186, attr);
        showchar(47, 12, 204, attr);
        showchar(47, 14, 199, attr);
        for (q = 48; q <= 57; q++)
            showchar(q, 10, 205, attr);
        for (q = 48; q <= 57; q++)
            showchar(q, 12, 205, attr);
        for (q = 48; q <= 57; q++)
            showchar(q, 14, 196, attr);
        attr = farge[0] * 16 + farge[2];
        showchar(53, 11, 'M', attr);
        showchar(54, 11, 'E', attr);
        showchar(55, 11, 'N', attr);
        showchar(56, 11, 'Y', attr);
        attr = farge[0] * 16 + farge[3];
        showchar(50, 13, 'H', attr);
        showchar(52, 13, 'O', attr);
        showchar(54, 13, 'V', attr);
        showchar(56, 13, 'E', attr);
        attr = farge[0] * 16 + farge[4];
        showchar(54, 15, 'A', attr);
        showchar(56, 15, '-', attr);
        gotoxy(3 + farge[w], 4 + 3 * w);
        textattr(itattr);
        putch(24);
        c = getkey();
        gotoxy(3 + farge[w], 4 + 3 * w);
        putch(32);
        switch (c) {
            case -72 : if (w > 0)
                           --w;
                       break;
            case -80 : if (w < 4)
                           ++w;
                       break;
            case -75 : if (farge[w] > 0)
                           --farge[w];
                       break;
            case -77 : if ((w > 0 && farge[w] < 15) || (w == 0 && farge[w] < 7))
                           ++farge[w];
                       break;
        }
    } while (c != 27 && c != 13);
    removewindow();
    if (c != 27) {
        meny.rattr = orig_rattr = farge[0] * 16 + farge[1];
        meny.tattr = orig_tattr = farge[0] * 16 + farge[2];
        meny.oattr = orig_oattr = farge[0] * 16 + farge[3];
        meny.vattr = orig_vattr = farge[0] * 16 + farge[4];
        skrivmeny();
        finn_reelle_attributter();
        vismeny();
    }
}


/*
    SLETTVALG lar brukeren slette uthevet menyvalg.
*/
static void slettvalg(void)
{
    int c, svar = 0;

    if (!strlen(meny.valg[transblokk.menyvalg].tekst))
        return;
    if (meny.valg[transblokk.menyvalg].meny) {
        if (inneholder_undermeny(meny.valg[transblokk.menyvalg].menyfil)) {
            feilmelding("Kan ikke slettes. Inneholder undermeny(er)");
            return;
        } else {
            makewindow(10, 9, 71, 14, ftattr, frattr, " VERIFISERING ", 2);
            gotoxy(1, 2);
            sentln("OBS: Dette er en undermeny!");
        }
    } else {
        makewindow(20, 9, 61, 13, ftattr, frattr, " VERIFISERING ", 2);
        gotoxy(1, 2);
    }
    sent("Skal valget slettes?     ");
    gotoxy(wherex() - 2, wherey());
    c = ja_nei(&svar, wuattr, ftattr);
    if (c != 27 && svar) {
        strcpy(meny.valg[transblokk.menyvalg].tekst, "");
        if (meny.valg[transblokk.menyvalg].meny)
            unlink(meny.valg[transblokk.menyvalg].menyfil);
        meny.valg[transblokk.menyvalg].meny = 0;
        strcpy(meny.valg[transblokk.menyvalg].menyfil, "");
        strcpy(meny.valg[transblokk.menyvalg].progdir, "");
        strcpy(meny.valg[transblokk.menyvalg].progdir, "");
        strcpy(meny.valg[transblokk.menyvalg].prognavn, "");
        meny.valg[transblokk.menyvalg].vent = 0;
        skrivmeny();
    }
    removewindow();
}


/*
    OVERSKRIFT lar brukeren endre menyens overskrift.
*/
static void overskrift(void)
{
    int c;

    gotoxy(3, 5);
    c = inplin(meny.overskrift, 76, uattr, oattr);
    strupr(meny.overskrift);
    textattr(oattr);
    clrarea(2, 5, 79, 5);
    gotoxy(1, 5);
    sent(meny.overskrift);
    textattr(vattr);
    if (c != 27)
        skrivmeny();
}


/*
    VELG lar bruker pile seg rundt. Dette kan vi si er hovedrutinen.
*/
static void velg(void)
{
    int c, slutt = 0, x, y;

    vismeny();
    while (!slutt) {
        if (transblokk.menyvalg >= ANTVALG)
            transblokk.menyvalg = 0;
        x = (transblokk.menyvalg > 6) ? 48 : 8;
        y = 8;
        if (transblokk.menyvalg > 6)
            y += (transblokk.menyvalg - 7) * 2;
        else
            y += transblokk.menyvalg * 2;
        textattr(uattr);
        gotoxy(x, y);
        cprintf("%-30s", meny.valg[transblokk.menyvalg].tekst);
        textattr(vattr);
        gotoxy(x, y);
        c = getkey();
        if (c >= 'a' && c <= 'a' + ANTVALG)
            c = 'A' + c - 'a';
        if (c >= 'A' && c <= 'A' + ANTVALG) {
            cprintf("%-30s", meny.valg[transblokk.menyvalg].tekst);
            transblokk.menyvalg = c - 'A';
            c = 13;
        }
        switch (c) {
            case   13 : if (strlen(meny.valg[transblokk.menyvalg].tekst)) {
                            if (!meny.valg[transblokk.menyvalg].meny) {
                                slutt = 1;
                                utgangskode = 1;
                                strcpy(transblokk.progdir, meny.valg[transblokk.menyvalg].progdir);
                                sprintf(transblokk.prognavn, " /C %s", meny.valg[transblokk.menyvalg].prognavn);
                                transblokk.vent = meny.valg[transblokk.menyvalg].vent;
                            } else {
                                strcpy(orig_overskrift, meny.valg[transblokk.menyvalg].tekst);
                                strupr(orig_overskrift);
                                strcpy(transblokk.menynavn, meny.valg[transblokk.menyvalg].menyfil);
                                transblokk.menyvalg = 0;
                                hentmeny();
                                strcpy(orig_overskrift, "");
                                vismeny();
                            }
                        }
                        break;
            case   27 : if (strcmp(transblokk.menynavn, "MENY0000.MNY") != 0) {
                            strcpy(transblokk.menynavn, "MENY0000.MNY");
                            transblokk.menyvalg = 0;
                            hentmeny();
                            vismeny();
                        }
                        break;
            case  -45 : slutt = 1;
                        utgangskode = 0;
                        strcpy(transblokk.progdir, "\\");
                        strcpy(transblokk.prognavn, "");
                        break;
            case  -59 : hjelp(); break;
            case  -60 : redigervalg();
                        cprintf("%-30s", meny.valg[transblokk.menyvalg].tekst);
                        break;
            case  -61 : slettvalg();
                        cprintf("%-30s", meny.valg[transblokk.menyvalg].tekst);
                        break;
            case  -62 : overskrift(); break;
            case  -63 : fargevalg(); break;
            case  -64 : redigerconfig(); break;
            case  -67 : minneoversikt(); break;
            case  -68 : slutt = 1;
                        utgangskode = 2;
                        strcpy(transblokk.progdir, "\\");
                        strcpy(transblokk.prognavn, " ");
                        transblokk.vent = 0;
                        break;
            case  -15 :
            case  -72 : if (transblokk.menyvalg > 0)
                            cprintf("%-30s", meny.valg[transblokk.menyvalg--].tekst);
                        break;
            case    9 :
            case  -80 : if (transblokk.menyvalg < ANTVALG - 1)
                            cprintf("%-30s", meny.valg[transblokk.menyvalg++].tekst);
                        break;
            case  -75 : if (transblokk.menyvalg - 7 >= 0) {
                            cprintf("%-30s", meny.valg[transblokk.menyvalg].tekst);
                            transblokk.menyvalg -= 7;
                        }
                        break;
            case  -77 : if (transblokk.menyvalg + 7 < ANTVALG) {
                            cprintf("%-30s", meny.valg[transblokk.menyvalg].tekst);
                            transblokk.menyvalg += 7;
                        }
                        break;
            case  -71 : cprintf("%-30s", meny.valg[transblokk.menyvalg].tekst);
                        transblokk.menyvalg = 0;
                        break;
            case  -79 : cprintf("%-30s", meny.valg[transblokk.menyvalg].tekst);
                        transblokk.menyvalg = ANTVALG - 1;
                        break;
            case  -73 : cprintf("%-30s", meny.valg[transblokk.menyvalg].tekst);
                        transblokk.menyvalg = (x > 40) ? 7 : 0;
                        break;
            case  -81 : cprintf("%-30s", meny.valg[transblokk.menyvalg].tekst);
                        transblokk.menyvalg = (x > 40) ? ANTVALG - 1 : 6;
                        break;
        }
    }
}

static void redigerconfig(void)
{
    int q, c, felt = 0, slutt = 0, attr;
    configstruct tmp;
    char txt[10];

    tmp = config;

    makewindow(4, 6, 76, 11 + BLANK_LINES, itattr, irattr, " DIVERSE OPPSETT ", 2);
    if (gettextmode() == C80)
        attr = (itattr & 240) + 6;
    else
        attr = itattr;
    gotoxy(3, 2);
    textattr(attr);
    cprintf("Antall minutter f›r skjermblanking (0=ingen blanking)");
    gotoxy(3, 4);
    cprintf("Tekst ved skjermblanking");
    do {
        textattr(attr);
        gotoxy(57, 2);
        putch('[');
        textattr(itattr);
        cprintf("%3d", tmp.blanker_min);
        textattr(attr);
        putch(']');
        for (q = 0; q < BLANK_LINES; q++) {
            gotoxy(28, 4 + q);
            putch('[');
            textattr(itattr);
            cprintf("%-*.*s", BLANK_LEN, BLANK_LEN, tmp.blank_tekst[q]);
            textattr(attr);
            putch(']');
        }
        switch (felt) {
            case 0:
                sprintf(txt, "%3d", tmp.blanker_min);
                gotoxy(58, 2);
                c = inplin(txt, 3, wuattr, itattr);
                tmp.blanker_min = atoi(txt);
                break;
            default:
                gotoxy(29, 4 + felt - 1);
                c = inplin(tmp.blank_tekst[felt - 1], BLANK_LEN, wuattr, itattr);
                break;
        }
        switch (c) {
            case -80:
            case  13:
                ++felt;
                break;
            case -72:
                if (felt > 0)
                    --felt;
                break;
            case -81:
                felt = 999;
                break;
            case  27:
                slutt = 1;
                break;
        }
        if (felt > BLANK_LINES)
            slutt = 1;
    } while (!slutt);
    removewindow();
    if (c != 27) {
        config = tmp;
        skrivconfig();
    }
}


static void lesconfig(void)
{
    int fh;

    if ((fh = _open(CONFIG_FILE, O_RDONLY)) != -1) {
        if (_read(fh, &config, sizeof(configstruct)) == sizeof(configstruct)) {
        }
        _close(fh);
    } else {
        memset(&config, 0, sizeof(configstruct));
        blanksek = 0;
        config.blanker_min = 10;
        strcpy(config.blank_tekst[0], "-SKJERMBESKYTTER-");
        strcpy(config.blank_tekst[1], "Trykk en tast for");
        strcpy(config.blank_tekst[2], "retur til menyen!");
    }
}

static void skrivconfig(void)
{
    int fh;

    if (access(CONFIG_FILE, 0) == 0 && access(CONFIG_FILE, 2) != 0)
        chmod(CONFIG_FILE, S_IREAD | S_IWRITE);
    if ((fh = _creat(CONFIG_FILE, 0)) != -1) {
        if (_write(fh, &config, sizeof(configstruct)) != sizeof(configstruct))
            feilmelding("Feil under skriving av konfigurasjonsfil");
        _close(fh);
    } else
        feilmelding("Kunne ikke †pne konfigurasjonsfil for skriving");
}


int main()
{
    if (coreleft() < 15000L) {
        cprintf("For lite minne tilgjengelig.\r\n");
        exit(-1);
    }
    delay(1);
    randomize();
    lesconfig();
    strcpy(orig_overskrift, "");
    henttransblokk();
    if (transblokk.vent)
        trykkentast();
    settoppskjerm();
    tommeny();
    strcpy(meny.overskrift, "");
    hentmeny();
    velg();
    sendtransblokk();
    dosskjerm();
    switch (utgangskode) {
        case 0 : cprintf("Skriv MENY og trykk <Return> for †\r\n");
                 cprintf("starte menyen igjen hvis det er ›nskelig.\r\n\n");
                 break;
        case 2 : cprintf("Skriv EXIT og trykk <Return> for †\r\n");
                 cprintf("komme tilbake til menyen. . .\r\n\n");
    }

    return 0;
}
