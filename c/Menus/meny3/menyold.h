#ifndef MENYOLD_H
#define MENYOLD_H

#define OLD_ANTVALG 14

typedef struct {
    char tekst [31];
    int  meny;             /* Sann hvis valget er en undermeny */
    char menyfil  [13];    /* Navn p† evt. menyfil */
    char progdir  [51];    /* Programmets directory (hvis ikke meny) */
    char prognavn [51];    /* Startkommando uten /C (hvis ikke meny) */
    int  vent;             /* Vent etter at programmet har avsluttet? */
} valgdatastruct_pre_1_7;

typedef struct {
    char typetekst[30];    /* Vises hvis bruker pr›ver † TYPE *.MNY */
    unsigned versjon;
    char overskrift [77];
    unsigned rattr, vattr, oattr, tattr; /* Attributt p† ramme, valgtekst,
                                            overskrift og annen tekst. */
    valgdatastruct_pre_1_7 valg [OLD_ANTVALG];
} menydatastruct_pre_1_7;

typedef struct {
    char tekst [31];
    int  meny;             /* Sann hvis valget er en undermeny */
    char menyfil  [13];    /* Navn p† evt. menyfil */
    char progdir  [51];    /* Programmets directory (hvis ikke meny) */
    char prognavn [51];    /* Startkommando uten /C (hvis ikke meny) */
} valgdatastruct_pre_1_5;

typedef struct {
    char typetekst[30];    /* Vises hvis bruker pr›ver † TYPE *.MNY */
    char overskrift [77];
    unsigned rattr, vattr, oattr, tattr; /* Attributt p† ramme, valgtekst,
                                            overskrift og annen tekst. */
    valgdatastruct_pre_1_5 valg [OLD_ANTVALG];
} menydatastruct_pre_1_5;

#endif
