        IDEAL

        MODEL   TINY

        ASSUME  cs: NOTHING, ds: @data, es: NOTHING


INCLUDE "ED.INC"


;--------------------------;
;                          ;
;         D A T A          ;
;                          ;
;--------------------------;

DATASEG

        PUBLIC  toptxt, bottxt, prsesc
        PUBLIC  inson, insoff, indon, indoff, pairon, pairoff
        PUBLIC  errorhd, readfhd, writfhd, linehd, findhd, replhd, opthd
        PUBLIC  readbhd, writbhd, pickhd
        PUBLIC  grmode, screrr, toomany
        PUBLIC  outmem, readerr, notopen, writerr, closerr, illegal
        PUBLIC  longlin, trnclin, outlins, opterr
        PUBLIC  helphd, help1, help2, help3, help4, help5, help6, help7
        PUBLIC  pgup, pgupdn, pgdn
        PUBLIC  idtxt
        PUBLIC  r_file, w_file
        PUBLIC  notsvd, ovrwrt, replc
        PUBLIC  criterr


IF NORSK

idtxt   DB     13, 10, "    ", NAVN, " ", VER, 13, 10, 10
        DB     "    (C) ", DATO, 13, 10, 10
        DB     "    Sverre H. Huseby", 13, 10
        DB     "    Bj›lsengt. 17", 13, 10
        DB     "    N-0468 Oslo", 13, 10
        DB     "    Norge", 13, 10
        DB     "    ", 0
toptxt  DB     "    Lin 0     Kol 0", 0
bottxt  DB     " ", NAVN, " ", VER, " ", 186
        DB     "   F1-hjelp  F2-lagre"
        DB     "  F3-hent"
        DB     "  F4-plukk"
        DB     "  Alt/X-slutt", 0
prsesc  DB     "Trykk ESC", 0

inson   DB     "Innsett", 0
insoff  DB     "Erstatt", 0
indon   DB     "Innrykk", 0
indoff  DB     "       ", 0
pairon  DB     "Parring", 0
pairoff DB     "       ", 0

pgup    DB     "PgUp", 0
pgupdn  DB     "PgUp/PgDn", 0
pgdn    DB     "PgDn", 0

r_file  DB     "Leser fil", 0
w_file  DB     "Skriver fil", 0

notsvd  DB     "Filen er endret. Lagre? (J/N) ", 0
ovrwrt  DB     "Filen eksisterer. Overskriv? (J/N) ", 0
replc   DB     "Erstatt? (J/N) ", 0

errorhd DB     " FEIL ", 0
readfhd DB     " Angi filnavn ", 0
writfhd DB     " Nytt filnavn ", 0
readbhd DB     " Les blokk fra fil ", 0
writbhd DB     " Skriv blokk til fil ", 0
pickhd  DB     " Velg fil ", 0
linehd  DB     " Linje ", 0
findhd  DB     " S›k etter ", 0
replhd  DB     " Erstatt med ", 0
opthd   DB     " Opsjoner ", 0

grmode  DB     "Skjermen m† v‘re i tekstmodus", 13, 10, "$"
screrr  DB     "Skjermen m† ha 80 kolonner", 13, 10, "$"

outmem  DB     "Ikke nok minne", 0
readerr DB     "Skrivefeil", 0
writerr DB     "Lesefeil", 0
notopen DB     "Kunne ikke †pne filen", 0
closerr DB     "Feil under lukking av fil", 0
illegal DB     "Ukjent s›kevei angitt", 0
longlin DB     "For lang linje - setter inn linjeskift", 0
trnclin DB     "For lang linje - kutter av", 0
outlins DB     "Ikke plass til flere linjer", 0
toomany DB     "For mange filer", 0
opterr  DB     "Ukjent opsjon angitt", 0

criterr DB     "Kritisk feil! Sjekk disken", 0

helphd  DB     " HJELP ", 0
help1   DB     13, 10
        DB     "  Grunnleggende mark›rflytting", 13, 10
        DB     "  ----------------------------", 13, 10
        DB     "  Tegn venstre Ctl-S el ", 27, 13, 10
        DB     "  Tegn h›yre   Ctl-D el ", 26, 13, 10
        DB     "  Ord venstre  Ctl-A el Ctl- ", 27, 13, 10
        DB     "  Ord h›yre    Ctl-F el Ctl- ", 26, 13, 10
        DB     "  Linje opp    Ctl-E el ", 24, 13, 10
        DB     "  Linje ned    Ctl-X el ", 25, 13, 10
        DB     "  Scroll opp   Ctl-W", 13, 10
        DB     "  Scroll ned   Ctl-Z", 13, 10
        DB     "  Side opp     Ctl-R el PgUp", 13, 10
        DB     "  Side ned     Ctl-C el PgDn", 13, 10
        DB     "  ", 0
help2   DB     13, 10
        DB     "  Annen mark›rflytting", 13, 10
        DB     "  --------------------", 13, 10
        DB     "  Linjestart   Home", 13, 10
        DB     "  Linjeslutt   End", 13, 10
        DB     "  Skjermstart  Ctl-Home", 13, 10
        DB     "  Skjermslutt  Ctl-End", 13, 10
        DB     "  Tekststart   Ctl-PgUp", 13, 10
        DB     "  Tekstslutt   Ctl-PgDn", 13, 10
        DB     "  Blokkstart   Ctl-Q B", 13, 10
        DB     "  Blokkslutt   Ctl-Q K", 13, 10
        DB     "  G† til linje Ctl-Q G", 13, 10
        DB     "  ", 0
help3   DB     13, 10
        DB     "  Kommandoer for innsetting og sletting", 13, 10
        DB     "  -------------------------------------", 13, 10
        DB     "  Innsett av/p†          Ctl-V el Ins", 13, 10
        DB     "  Sett inn linje         Ctl-N", 13, 10
        DB     "  Slett linje            Ctl-Y", 13, 10
        DB     "  Slett til linjeslutt   Ctl-Q Y", 13, 10
        DB     "  Slett tegn til venstre Ctl-H el BackSpace", 13, 10
        DB     "  Slett tegn             Ctl-G el Del", 13, 10
        DB     "  Slett ord til h›yre    Ctl-T", 13, 10
        DB     "  ", 0
help4   DB     13, 10
        DB     "  Blokkommandoer", 13, 10
        DB     "  --------------", 13, 10
        DB     "  Marker blokkstart    Ctl-K B", 13, 10
        DB     "  Marker blokkslutt    Ctl-K K", 13, 10
  ;     DB     "  Marker enkelt ord    Ctl-K T", 13, 10
        DB     "  Kopier blokk         Ctl-K C", 13, 10
        DB     "  Flytt blokk          Ctl-K V", 13, 10
        DB     "  Slett blokk          Ctl-K Y", 13, 10
        DB     "  Les blokk fra disk   Ctl-K R", 13, 10
        DB     "  Skriv blokk til disk Ctl-K W", 13, 10
        DB     "  Skjul/vis blokk      Ctl-K H", 13, 10
        DB     "  Rykk blokk inn       Ctl-K I", 13, 10
        DB     "  Rykk blokk ut        Ctl-K U", 13, 10
  ;     DB     "  Print blokk          Ctl-K P", 13, 10
        DB     "  ", 0
help5   DB     13, 10
        DB     "  Diverse kommandoer", 13, 10
        DB     "  ------------------", 13, 10
        DB     "  Innrykk               Ctl-I el Tab", 13, 10
        DB     "  Auto innrykk av/p†    Ctl-O I", 13, 10
        DB     "  Parentesparring av/p† Ctl-O P", 13, 10
        DB     "  Sett posisjonsmerke   Ctl-K 1,2", 13, 10
        DB     "  Finn posisjonsmerke   Ctl-Q 1,2", 13, 10
        DB     "  Kontrolltegn-prefix   Ctl-P", 13, 10
        DB     "  S›k                   Ctl-Q F", 13, 10
        DB     "  S›k og erstatt        Ctl-Q A", 13, 10
        DB     "  Gjenta siste s›k      Ctl-L", 13, 10
        DB     "  Vis brukerskjerm      F5", 13, 10
        DB     "  ", 0
help6   DB     13, 10
        DB     "  Filh†ndtering", 13, 10
        DB     "  -------------", 13, 10
        DB     "  Lagre fil         F2", 13, 10
        DB     "  Hent fil          F3", 13, 10
        DB     "  Plukk frem fil    F4", 13, 10
        DB     "  Lagre plukklisten Alt-F4", 13, 10
        DB     "  ", 0
help7   DB     13, 10
        DB     "  Opsjoner ved s›k/erstatt", 13, 10
        DB     "  ------------------------", 13, 10
        DB     "  G - Globalt, dvs alle forekomster", 13, 10
        DB     "  N - Erstatt uten bekreft", 13, 10
        DB     "  ", 0

ELSE
idtxt   DB     13, 10, "    ", NAVN, " ", VER, 13, 10, 10
        DB     "    (C) ", DATO, 13, 10, 10
        DB     "    Sverre H. Huseby", 13, 10
        DB     "    Bjoelsengt. 17", 13, 10
        DB     "    N-0468 Oslo", 13, 10
        DB     "    Norway", 13, 10
        DB     "    ", 0
toptxt  DB     "    Lin 0     Col 0", 0
bottxt  DB     " ", NAVN, " ", VER, " ", 186
        DB     "   F1-help  F2-save"
        DB     "  F3-load"
        DB     "  F4-pick"
        DB     "  Alt/X-exit", 0
prsesc  DB     "Press ESC", 0

inson   DB     "Insert ", 0
insoff  DB     "Overwrt", 0
indon   DB     "Indent ", 0
indoff  DB     "       ", 0
pairon  DB     "Pairing", 0
pairoff DB     "       ", 0

pgup    DB     "PgUp", 0
pgupdn  DB     "PgUp/PgDn", 0
pgdn    DB     "PgDn", 0

r_file  DB     "Reading file", 0
w_file  DB     "Writing file", 0

notsvd  DB     "File is changed. Save? (Y/N) ", 0
ovrwrt  DB     "File exists. Overwrite? (Y/N) ", 0
replc   DB     "Replace? (Y/N) ", 0

errorhd DB     " ERROR ", 0
readfhd DB     " Give name of file to read ", 0
writfhd DB     " New filename ", 0
readbhd DB     " Read block from file ", 0
writbhd DB     " Write block to file ", 0
pickhd  DB     " Pick file ", 0
linehd  DB     " Line ", 0
findhd  DB     " Search for ", 0
replhd  DB     " Replace with ", 0
opthd   DB     " Options ", 0

grmode  DB     "Screen must be in textmode", 13, 10, "$"
screrr  DB     "Screen must have 80 columns", 13, 10, "$"

outmem  DB     "Out of memory", 0
readerr DB     "Read error", 0
writerr DB     "Write error", 0
notopen DB     "Couldn't open file", 0
closerr DB     "Couldn't close file", 0
illegal DB     "Unknown path", 0
longlin DB     "Line too long - inserting newline", 0
trnclin DB     "Line too long - truncating", 0
outlins DB     "Not room for more lines", 0
toomany DB     "Too many files", 0
opterr  DB     "Unknown option given", 0

criterr DB     "Critical error! Check your disk", 0

helphd  DB     " HELP ", 0
help1   DB     13, 10
        DB     "  Basic Cursor Movement", 13, 10
        DB     "  ---------------------", 13, 10
        DB     "  Char Left   Ctl-S or ", 27, 13, 10
        DB     "  Char Right  Ctl-D or ", 26, 13, 10
        DB     "  Word Left   Ctl-A or Ctl- ", 27, 13, 10
        DB     "  Word Right  Ctl-F or Ctl- ", 26, 13, 10
        DB     "  Line Up     Ctl-E or ", 24, 13, 10
        DB     "  Line Down   Ctl-X or ", 25, 13, 10
        DB     "  Scroll Up   Ctl-W", 13, 10
        DB     "  Scroll Down Ctl-Z", 13, 10
        DB     "  Page Up     Ctl-R or PgUp", 13, 10
        DB     "  Page Down   Ctl-C or PgDn", 13, 10
        DB     "  ", 0
help2   DB     13, 10
        DB     "  Other Cursor Movement", 13, 10
        DB     "  ---------------------", 13, 10
        DB     "  Beg of Line   Home", 13, 10
        DB     "  End of Line   End", 13, 10
        DB     "  Top of Screen Ctl-Home", 13, 10
        DB     "  Bot of Screen Ctl-End", 13, 10
        DB     "  Beg of File   Ctl-PgUp", 13, 10
        DB     "  End of File   Ctl-PgDn", 13, 10
        DB     "  Beg of Block  Ctl-Q B", 13, 10
        DB     "  End of Block  Ctl-Q K", 13, 10
        DB     "  Go to Line    Ctl-Q G", 13, 10
        DB     "  ", 0
help3   DB     13, 10
        DB     "  Insert and Delete Commands", 13, 10
        DB     "  --------------------------", 13, 10
        DB     "  Insert Off/On         Ctl-V or Ins", 13, 10
        DB     "  Insert Line           Ctl-N", 13, 10
        DB     "  Delete Line           Ctl-Y", 13, 10
        DB     "  Delete to End of Line Ctl-Q Y", 13, 10
        DB     "  Delete Char Left      Ctl-H or BackSpace", 13, 10
        DB     "  Delete Char           Ctl-G or Del", 13, 10
        DB     "  Delete Word Right     Ctl-T", 13, 10
        DB     "  ", 0
help4   DB     13, 10
        DB     "  Block Commands", 13, 10
        DB     "  --------------", 13, 10
        DB     "  Mark Blockstart      Ctl-K B", 13, 10
        DB     "  Mark Blockend        Ctl-K K", 13, 10
  ;     DB     "  Mark Single Word     Ctl-K T", 13, 10
        DB     "  Copy Block           Ctl-K C", 13, 10
        DB     "  Move Block           Ctl-K V", 13, 10
        DB     "  Delete Block         Ctl-K Y", 13, 10
        DB     "  Read Block from File Ctl-K R", 13, 10
        DB     "  Write Block to File  Ctl-K W", 13, 10
        DB     "  Hide/Display Block   Ctl-K H", 13, 10
        DB     "  Indent Block         Ctl-K I", 13, 10
        DB     "  Unindent Block       Ctl-K U", 13, 10
  ;     DB     "  Print Block          Ctl-K P", 13, 10
        DB     "  ", 0
help5   DB     13, 10
        DB     "  Other Editing Commands", 13, 10
        DB     "  ----------------------", 13, 10
        DB     "  Indent             Ctl-I or Tab", 13, 10
        DB     "  Auto Indent Off/On Ctl-O I", 13, 10
        DB     "  Pairmaking Off/On  Ctl-O P", 13, 10
        DB     "  Set Place Marker   Ctl-K 1,2", 13, 10
        DB     "  Find Place Marker  Ctl-Q 1,2", 13, 10
        DB     "  Contol Char Prefix Ctl-P", 13, 10
        DB     "  Search             Ctl-Q F", 13, 10
        DB     "  Search and replace Ctl-Q A", 13, 10
        DB     "  Repeat Last Search Ctl-L", 13, 10
        DB     "  Show User Screen   F5", 13, 10
        DB     "  ", 0
help6   DB     13, 10
        DB     "  File Handling", 13, 10
        DB     "  -------------", 13, 10
        DB     "  Save File     F2", 13, 10
        DB     "  Load File     F3", 13, 10
        DB     "  Pick File     F4", 13, 10
        DB     "  Save Picklist Alt-F4", 13, 10
        DB     "  ", 0
help7   DB     13, 10
        DB     "  Options to search/replace", 13, 10
        DB     "  -------------------------", 13, 10
        DB     "  G - Global; all occurences", 13, 10
        DB     "  N - No confirmation from user", 13, 10
        DB     "  ", 0
ENDIF



ENDS

        END
