#define  NAVN "MENYKONF"
#include "versjon.h"


typedef struct {
    unsigned char disk;  /* Disken programmet er p† */
    char path [41];      /* Path til menyprog.exe (uten disk) */
    char compath [41];   /* Path til command.com (med disk) */
} konfigdatastruct;




void settoppskjerm(void);
void feilmelding(char *s);
void fjernblanke(char *s);
int  inplin(char *lin, int max, int attr1, int attr2);
int  ja_nei(int *std, int attr1, int attr2);
void skrivmenycom(void);
void redigerdata(void);
void konfigurer(void);
