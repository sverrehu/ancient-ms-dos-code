#define makslinjer 1500    /* Maksimum antall linjer */
#define makskolonner 160   /* Maksimum antall tegn pr. linje */


int   ed_antlinjer(void);
int   ed_editer(int status, int ins, int ind, int sattr);
int   ed_leggtil(unsigned char * tekst);
unsigned char * ed_linje(int nr);
void  ed_ryddopp(void);
void  ed_startopp(void);
void  ed_visstatus(void);
void  ed_vistekst(void);
