#ifndef MENYPROG_H
#define MENYPROG_H

#define  NAVN "MENY III"
#include "versjon.h"
#include "menyold.h"


#define ANTVALG 14
#define CONFIG_FILE "meny.cfg"
#define BLANK_LINES 5
#define BLANK_LEN 40



typedef struct {
    char id [11];          /* M† v‘re "MENY III  " */
    char menynavn [13];    /* Navn p† n†v‘rende menyfil */
    int  feilkode;         /* Feil som skal vises av programmet */
    int  menyvalg;         /* N†v‘rende menyvalg */
    unsigned char progdsk; /* Disken ›nsket program er p† */
    char progdir [51];     /* Directory for ›nsket program (med \) */
    unsigned char len;     /* Lengden p† programnavnet */
    char prognavn [55];    /* Navn p† ›nsket program. Dette er en string
                              p† formen:
                              " /C <navn> <parametre>\n"    */
    int  vent;
} transblokkstruct;

typedef struct {
    char tast;             /* Bokstavkode for dette valget */
    char tekst [31];
    int  meny;             /* Sann hvis valget er en undermeny */
    char menyfil  [13];    /* Navn p† evt. menyfil */
    char progdir  [51];    /* Programmets directory (hvis ikke meny) */
    char prognavn [51];    /* Startkommando uten /C (hvis ikke meny) */
    int  vent;             /* Vent etter at programmet har avsluttet? */
    char reserv[20];       /* seinere utvidelser: null */
} valgdatastruct;

typedef struct {
    char typetekst[30];    /* Vises hvis bruker pr›ver † TYPE *.MNY */
    unsigned versjon;
    char overskrift [77];
    unsigned rattr, vattr, oattr, tattr; /* Attributt p† ramme, valgtekst,
                                            overskrift og annen tekst. */
    valgdatastruct valg [ANTVALG];
    char reserv[20];       /* seinere utvidelser: null */
} menydatastruct;

typedef struct {
    int  blanker_min;      /* Minutter f›r screenblank, eller 0 hvis ingen */
    char blank_tekst[BLANK_LINES][BLANK_LEN];
    char reserv[200];      /* seinere utvidelser: null */
} configstruct;



void henttransblokk(void);
void sendtransblokk(void);
void settoppskjerm(void);
void feilmelding(char *s);
int  hvertast(int c);
void klokke(void);
void hjelp(void);
void minneoversikt(void);
void finn_reelle_attributter(void);
void tommeny(void);
char * finn_nytt_navn(void);
void fjernblanke(char *s);
void skrivmeny(void);
void hentmeny(void);
void vismeny(void);
int  inplin(char *lin, int max, int attr1, int attr2);
int  ja_nei(int *std, int attr1, int attr2);
void redigervalg(void);
void fargevalg(void);
int  inneholder_undermeny(char *menynavn);
void slettvalg(void);
void overskrift(void);
void velg(void);
void skrivconfig(void);
void lesconfig(void);
void redigerconfig(void);

#endif
