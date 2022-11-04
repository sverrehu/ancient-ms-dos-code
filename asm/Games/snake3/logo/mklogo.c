/*
    Dette programmet tar et pakket EGA-paint-bilde og lager data
    p† assemblyform av det som befinner seg i ›verste venstre hj›rne.
    Hvor stor del av skjermen som brukes, angis i BYTESX og BYTESY.

    Dataene legges med bitplan 0 f›rst, deretter bitplan 1 osv.
*/
#include <stdio.h>
#include <io.h>
#include <fcntl.h>
#include <mem.h>
#include <dos.h>
#include <dir.h>
#include <alloc.h>

#include <ega10.h>

#define byte unsigned char

#define NAVN "MKLOGO"
#define VER  "v1.0"
#define DATO "3/1-1991"



#define BYTESX 19
#define BYTESY 43




unsigned seg;


void visbuffer(unsigned seg);



void fatal(char *msg)
{
    int q;

    freemem(seg);
    closegraph();
    printf("FEIL: %s.\n", msg);
    exit(-1);
}


void les_egapaint_fil(char *fil)
{
    int q;
    int hdl;
    size_t bufflen;

    hdl = open(fil, O_RDONLY | O_BINARY);
    bufflen = filelength(hdl);
    if (allocmem(bufflen / 16 + 1, &seg) != -1)
        fatal("For lite minne");
    read(hdl, MK_FP(seg, 0), bufflen);
    close(hdl);
}


void laglogo(void)
{
  #define MAXPRLIN 10
    int w, e, r, q, antl = 0, byt, c;
    FILE *f;

    visbuffer(seg);
    freemem(seg);
    if ((f = fopen("LOGODATA.ASM", "wt")) == NULL)
        fatal("Kunne ikke †pne fil");
    fprintf(f, "        IDEAL\n\n        MODEL   TINY\n\n");
    fprintf(f, "        ASSUME  ds: @data\n\n\n");
    fprintf(f, "DATASEG\n\n");
    fprintf(f, "LOGOX   =       %d ; Bytes i X-retn.\n", BYTESX);
    fprintf(f, "LOGOY   =       %d ; Bytes i Y-retn.\n\n", BYTESY);
    fprintf(f, "PUBLIC  logodata, LOGOX, LOGOY\n");
    fprintf(f, "LABEL   logodata BYTE\n");

    for (q = 0; q < 4; q++) {
        fprintf(f, "  ; Data for bitplan %d\n", q);
        fprintf(f, "        DB      ");
        antl = 0;
        for (w = 0; w < BYTESY; w++)
            for (e = 0; e < BYTESX; e++) {
                byt = 0;
                for (r = 0; r < 8; r++) {
                    c = getpixel(e * 8 + r, w);
                    if (c & (1 << q))
                        byt |= (128 >> r);
                }
                if (antl > 0)
                    fprintf(f, ", ");
                fprintf(f, "%03Xh", byt);
                if (++antl >= MAXPRLIN) {
                    fprintf(f, "\n        DB      ");
                    antl = 0;
                }
            }
        fprintf(f, "\n\n");
    }
    fprintf(f, "\nENDS\n\n        END\n");

    fclose(f);
}



int main(int argc, char *argv[])
{
    int  q;
    char kilde[MAXPATH];
    char drv[MAXDRIVE], dir[MAXDIR], name[MAXFILE];

    printf("%s %s  --  (C) %s - Sverre H. Huseby, Larvik, Norge\n\n",
           NAVN, VER, DATO);
    if (argc > 1) {
        if (init_ega10_graph() != 0)
            fatal("Kunne ikke installere EGA-mode 10h");
        strcpy(kilde, argv[1]);
        fnsplit(kilde, drv, dir, name, NULL);
        fnmerge(kilde, drv, dir, name, ".PEP");
        strupr(kilde);
        les_egapaint_fil(kilde);
        laglogo();
        closegraph();
    } else {
        printf("Lager logodata av EGAPAINT-bilde som er pakket med PAKKEGA\n");
        printf("Spesiallaget til SNAKE3.\n\n");
        printf("Syntaks:  %s <filnavn>\n\n", NAVN);
        printf("          <filnavn> : Navnet (og evt. path) p† PAKKEGA-filen\n\n");
    }
    return 0;
}
