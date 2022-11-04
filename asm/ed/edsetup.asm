;
; Setup-program for ED. Skriver endringer rett inn i ED.COM
;

        IDEAL

        MODEL    TINY

        ASSUME   cs: @code, ds: @data


INCLUDE "ED.INC"

NAVN    EQU    "EDSETUP"
MAXSIZ  EQU    32767           ; Maks lengde pÜ ED.COM





UDATASEG

buffer  DB     MAXSIZ DUP (?)  ; Buffer for ED.COM
filelen DW     ?               ; Lengden pÜ innlest ED.COM
hdl     DW     ?               ; Filehandle
ftime   DW     ?               ; Filens tid
fdate   DW     ?               ; Filens dato
area    DW     ?               ; Offset til strukturen i bufferet
attr    DB     ?               ; Attributt brukt av get_color()
tmpattr DB     ?               ;         -- " --




DATASEG

IF NORSK

prsesc  DB     "Trykk ESC", 0
errorhd DB     " FEIL ", 0
readerr DB     "Skrivefeil", 0
writerr DB     "Lesefeil", 0
openerr DB     "Kunne ikke Üpne ED.COM for skriving/lesing", 0
closerr DB     "Feil under lukking av fil", 0
nosterr DB     "Ukjent innhold i ED.COM", 0
vererr  DB     "Ulik versjon pÜ EDSETUP.COM og ED.COM", 0
on      DB     "PÜ", 0
off     DB     "Av", 0
coltxt  DB     " Abcd ", 0

head    DB     " ", NAVN, " ", VER, "  --  (C) ", DATO, " ", 0
explain DB     13, 10, 10
        DB     "  Dette programmet gir mulighet for Ü konfigurere", 13, 10
        DB     "  SHH ED slik at editoren starter med õnskede inn-", 13, 10
        DB     "  stillinger.", 13, 10, 10
        DB     "  Det som kan endres, er: modus for innsett, auto-", 13, 10
        DB     "  innrykk, parentesparring, samt fargeoppsett.", 13, 10, 10
        DB     "  Endring av farger gjelder kun for fargeskjerm.", 13, 10, 10
        DB     "  MERK: Oppsettet skrives direkte inn i ED.COM, og", 13, 10
        DB     "  evt. sjekksumprogrammer mot datavirus vil derfor", 13, 10
        DB     "  si ifra at programmet er forandret. Det er i dette", 13, 10
        DB     "  tilfellet helt ok.", 13, 10, 10
        DB     "          Trykk en tast for Ü fortsette,", 13, 10
        DB     "             eller Esc for Ü avbryte: ", 0

expcol  DB     13, 10
        DB     "              Forgrunn", 13, 10
        DB     "          ________________", 13, 10
        DB     " B |", 13, 10
        DB     " a |", 13, 10
        DB     " k |      ", 27, "/", 26, ":      forgrunn", 13, 10
        DB     " g |      ", 24, "/", 25, ":      bakgrunn", 13, 10
        DB     " r |      Return:   ferdig", 13, 10
        DB     " u |", 13, 10
        DB     " n |      Eksempel: Abcd ", 13, 10
        DB     " n |", 13, 10
        DB     " ", 0

menutxt DB     13, 10
        DB     "                                    NÜvërende", 13, 10
        DB     "  A.  Resett mus ved start", 13, 10
        DB     "  B.  Innsettmode", 13, 10
        DB     "  C.  Autoinnrykk", 13, 10
        DB     "  D.  Parentesparring", 13, 10
        DB     "  E.  Tekstattributt", 13, 10
        DB     "  F.  Blokkattributt", 13, 10
        DB     "  G.  Topp/bunn-tekst", 13, 10
        DB     "  H.  Feilvindu, tekst", 13, 10
        DB     "  I.  Feilvindu, ramme", 13, 10
        DB     "  J.  Hjelpevindu, tekst", 13, 10
        DB     "  K.  Hjelpevindu, ramme", 13, 10
        DB     "  L.  Meldingsvindu, tekst", 13, 10
        DB     "  M.  Meldingsvindu, ramme", 13, 10
        DB     "  N.  Standardoppsett", 13, 10
        DB     "  Q.  Lagre endringer og avslutt", 13, 10, 10
        DB     "  Velg: ", 0

screrr  DB     NAVN, ": Skjermen mÜ ha minst 80 kolonner", 13, 10, "$"
grmode  DB     NAVN, ": Skjermen mÜ vëre i tekstmode", 13, 10, "$"
changed DB     "ED.COM er oppdatert", 13, 10, "$"
aborted DB     "Avbrutt av bruker. ED.COM er uendret", 13, 10, "$"

ELSE

prsesc  DB     "Press ESC", 0
errorhd DB     " ERROR ", 0
readerr DB     "Read error", 0
writerr DB     "Write error", 0
openerr DB     "Couldn't open ED.COM for reading/writing", 0
closerr DB     "Couldn't close file", 0
nosterr DB     "Unknown ED.COM", 0
vererr  DB     "Different versions of EDSETUP.COM and ED.COM", 0
on      DB     "On ", 0
off     DB     "Off", 0
coltxt  DB     " Abcd ", 0

head    DB     " ", NAVN, " ", VER, "  --  (C) ", DATO, " ", 0
explain DB     13, 10, 10
        DB     "  This program makes it possible to configure SHH ED", 13, 10
        DB     "  to start with your favourite settings.", 13, 10, 10
        DB     "  Changing of colors is for colordisplay only.", 13, 10, 10
        DB     "  Be aware that the changes are written directly to", 13, 10
        DB     "  ED.COM, so if you use any checksumprograms to test", 13, 10
        DB     "  for virus, these will probably complain about ED.", 13, 10, 10
        DB     "             Press any key to continue,", 13, 10
        DB     "                  or Esc to quit: ", 0

expcol  DB     13, 10
        DB     "             Foreground", 13, 10
        DB     "          ________________", 13, 10
        DB     " B |", 13, 10
        DB     " a |", 13, 10
        DB     " c |      ", 27, "/", 26, ":      foreground", 13, 10
        DB     " k |      ", 24, "/", 25, ":      background", 13, 10
        DB     " g |      Return:   finished", 13, 10
        DB     " r |", 13, 10
        DB     " n |      Example:  Abcd ", 13, 10
        DB     " d |", 13, 10
        DB     " ", 0

menutxt DB     13, 10
        DB     "                                    Current setting", 13, 10
        DB     "  A.  Reset mouse at start", 13, 10
        DB     "  B.  Insertmode", 13, 10
        DB     "  C.  Autoindent", 13, 10
        DB     "  D.  Parenthesis Pairing", 13, 10
        DB     "  E.  Textattribute", 13, 10
        DB     "  F.  Blockattribute", 13, 10
        DB     "  G.  Top/bottom", 13, 10
        DB     "  H.  Errorwindow, text", 13, 10
        DB     "  I.  Errorwindow, border", 13, 10
        DB     "  J.  Helpwindow, text", 13, 10
        DB     "  K.  Helpwindow, border", 13, 10
        DB     "  L.  Messagewindow, text", 13, 10
        DB     "  M.  Messagewindow, border", 13, 10
        DB     "  N.  Default setup", 13, 10
        DB     "  Q.  Save changes and quit", 13, 10, 10
        DB     "  Choose: ", 0

screrr  DB     NAVN, ": Screen must have at least 80 columns", 13, 10, "$"
grmode  DB     NAVN, ": Need textmode", 13, 10, "$"
changed DB     "ED.COM is updated", 13, 10, "$"
aborted DB     "Aborted by user. ED.COM is unchanged", 13, 10, "$"

ENDIF

filenm  DB     "ED.COM", 0

; Her fõlger data som kan endres.
; Fõrst en header som sõkes etter av setup-programmet, og en versjons-
; kode for Ü sjekke at det er riktig setup-program som brukes.

idstr   DB      "SETUPBUF", 0, VER, 0

STRUC   setupdata
 sattr  DB      14 + 1 * 16  ; Skjermattributtene i editorvinduet
 battr  DB      14 + 7 * 16  ; Attributt pÜ uthevet tekst (blokk)
 hattr  DB       4 + 7 * 16  ; Header-attributter
 uattr  DB      15 + 0 * 16  ; Attributt pÜ uthevet valg i menyer
 ftattr DB      15 + 4 * 16  ; Feilvindu, textattr
 frattr DB      14 + 4 * 16  ; Feilvindu, rammeattr
 htattr DB       0 + 7 * 16  ; Hjelpevindu, textattr
 hrattr DB       0 + 7 * 16  ; Hjelpevindu, rammeattr
 mtattr DB       0 + 7 * 16  ; Meldingsvindu, textattr
 mrattr DB       0 + 7 * 16  ; Meldingsvindu, rammeattr

 insert DB      1            ; Er innsett pÜ?
 indent DB      1            ; Er autoindent pÜ?
 pair   DB      1            ; Er parentesparring pÜ?
 tabul  DB      0            ; Er tabulatormode pÜ? Dvs. Tab eller innrykk
 resmouse DB    0            ; Skal musa resettes?
ENDS

default setupdata <>





CODESEG

        EXTRN   initmem: PROC, endmem: PROC
        EXTRN   initscreen: PROC, endscreen: PROC
        EXTRN   initwindow: PROC, endwindow: PROC

        EXTRN   getkey: PROC
        EXTRN   outchar: PROC, outtext: PROC, screencols: PROC, textattr: PROC
        EXTRN   clrscr: PROC, gotoxy: PROC, wherex: PROC, wherey: PROC
        EXTRN   openwindow: PROC, closewindow: PROC, bordertext: PROC
        EXTRN   strlen: PROC, strcmp: PROC


        ORG     0100h

start:  jmp     main



;
; exit
;
; Hva prosedyren gjõr:
;   Rydder opp etter eksterne moduler, og avslutter programmet.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting, returnerer ikke
;
PROC    exit

    ; Rydd opp etter eksterne moduler
        call    endwindow       ; Lukker evt. Üpne vinduer
        call    endscreen
        call    endmem

    ; Avslutt programmet med exitcode=0
        mov     ax, 4C00h
        int     21h

ENDP    exit



;
; fatal
;
; Hva prosedyren gjõr:
;   èpner et vindu og viser en feilmelding. Venter til ESC er trykket,
;   og avbryter sÜ programmet.
;
; Kall med:
;   DS:DX - peker til feilmeldingen
;
; Returnerer:
;   Ingenting, returnerer ikke.
;
PROC    fatal

        push    dx

    ; èpne et vindu som har riktig stõrrelse.
        call    strlen
        mov     dx, 0B12h
        add     dl, al
        mov     ax, 0903h
        mov     bl, 1
        mov     cx, 7070h       ; Tekst/ramme: svart pÜ hvit
        call    openwindow
        mov     dx, OFFSET errorhd
        xor     al, al
        call    bordertext

    ; Vis meldingen
        mov     al, ' '
        call    outchar
        pop     dx
        call    outtext
        mov     al, '.'
        call    outchar

    ; Vis "Trykk Esc"
        mov     al, ' '
        call    outchar
        call    outchar
        mov     dx, OFFSET prsesc
        call    outtext

  @@key_loop:
    ; Vent til Esc er trykket
        call    getkey
        cmp     ax, 27
        jne     @@key_loop

    ; Lukk vinduet
        call    closewindow

    ; og avbryt programmet.
        call    exit

    ; Kommer aldri hit.

ENDP    fatal



;
; find_area
;
; Hva prosedyren gjõr:
;   Leter gjennom lest buffer etter strengens som skal identifisere
;   omrÜdet hvor endringer skal foretas.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt
;
PROC    find_area


    ; Let etter idstringen i bufferet.
        mov     cx, [filelen]

        mov     dx, OFFSET idstr
        call    strlen
        sub     cx, ax

        mov     si, OFFSET idstr
        mov     di, OFFSET buffer
        push    ds
        pop     es

  @@test_next:
        call    strcmp
        or      ax, ax
        jz      @@found
        inc     di
        loop    @@test_next

    ; Her er ikke strengen funnet. Avbryt med feilmelding.
        mov     dx, OFFSET nosterr
        call    fatal

  @@found:
    ; Strengen er funnet. Sjekk at versjonene ogsÜ stemmer over ens.
        mov     dx, OFFSET idstr
        call    strlen
        add     si, ax
        add     di, ax
        inc     si
        inc     di
        call    strcmp
        or      ax, ax
        jz      @@version_ok

    ; Her stemmer ikke versjonsnummerene. Avbryt med feilmelding.
        mov     dx, OFFSET vererr
        call    fatal

  @@version_ok:
    ; Her stemmer versjonen. Lagre starten pÜ tabellen.
    ; SI peker til versjonsdelen av idstr.
        mov     dx, si
        call    strlen
        add     di, ax
        inc     di
        mov     [area], di

        ret
ENDP    find_area



;
; show_status
;
; Hva prosedyren gjõr:
;   Viser nÜvërende oppsett i vinduet
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt
;
PROC    show_status

    ; Finn nÜvërende posisjon
        call    wherex
        call    wherey
        push    ax

    ; Finn adressen til omrÜdet
        mov     bx, [area]

    ; Vis status for mus
        mov     ax, 39 + 2 * 256
        call    gotoxy
        mov     dx, OFFSET off
        cmp     [(setupdata PTR bx).resmouse], 0
        jz      @@show_resmouse
        mov     dx, OFFSET on
  @@show_resmouse:
        call    outtext

    ; Vis status for innsett
        mov     ax, 39 + 3 * 256
        call    gotoxy
        mov     dx, OFFSET off
        cmp     [(setupdata PTR bx).insert], 0
        jz      @@show_insert
        mov     dx, OFFSET on
  @@show_insert:
        call    outtext

    ; Vis status for indent
        mov     ax, 39 + 4 * 256
        call    gotoxy
        mov     dx, OFFSET off
        cmp     [(setupdata PTR bx).indent], 0
        jz      @@show_indent
        mov     dx, OFFSET on
  @@show_indent:
        call    outtext

    ; Vis status for parring
        mov     ax, 39 + 5 * 256
        call    gotoxy
        mov     dx, OFFSET off
        cmp     [(setupdata PTR bx).pair], 0
        jz      @@show_pair
        mov     dx, OFFSET on
  @@show_pair:
        call    outtext

    ; Vis diverse attributter
        mov     dx, OFFSET coltxt

        mov     ax, 38 + 6 * 256
        call    gotoxy
        mov     al, [(setupdata PTR bx).sattr]
        call    textattr
        call    outtext

        mov     ax, 38 + 7 * 256
        call    gotoxy
        mov     al, [(setupdata PTR bx).battr]
        call    textattr
        call    outtext

        mov     ax, 38 + 8 * 256
        call    gotoxy
        mov     al, [(setupdata PTR bx).hattr]
        call    textattr
        call    outtext

        mov     ax, 38 + 9 * 256
        call    gotoxy
        mov     al, [(setupdata PTR bx).ftattr]
        call    textattr
        call    outtext

        mov     ax, 38 + 10 * 256
        call    gotoxy
        mov     al, [(setupdata PTR bx).frattr]
        call    textattr
        call    outtext

        mov     ax, 38 + 11 * 256
        call    gotoxy
        mov     al, [(setupdata PTR bx).htattr]
        call    textattr
        call    outtext

        mov     ax, 38 + 12 * 256
        call    gotoxy
        mov     al, [(setupdata PTR bx).hrattr]
        call    textattr
        call    outtext

        mov     ax, 38 + 13 * 256
        call    gotoxy
        mov     al, [(setupdata PTR bx).mtattr]
        call    textattr
        call    outtext

        mov     ax, 38 + 14 * 256
        call    gotoxy
        mov     al, [(setupdata PTR bx).mrattr]
        call    textattr
        call    outtext


    ; Sett tilbake markõrposisjonen
        pop     ax
        call    gotoxy

    ; Sett riktig attributt
        mov     al, 0Fh
        call    textattr

        ret
ENDP    show_status



;
; get_color
;
; Hva prosedyren gjõr:
;   èpner et vindu hvor brukeren fÜr velge en farge.
;
; Kall med:
;   AL : NÜvërende attributt
;
; Returnerer:
;   AL : Valgt attributt
;
; Endrer innholdet i:
;   AX
;
PROC    get_color
        push    bx
        push    cx
        push    dx

    ; Spar angitt attributt
        mov     [attr], al
        mov     [tmpattr], al

    ; èpne vindu for innlesing av farge
        xor     ax, ax
        mov     dx, 33 + 13 * 256
        mov     bl, 1
        mov     cx, 0D0Fh
        call    openwindow

    ; Vis instruksjoner
        mov     dx, OFFSET expcol
        call    outtext

    ; Vis farge-bars.
        call    wherex
        call    wherey
        push    ax

        mov     ax, 10 + 2 * 256
        call    gotoxy

        mov     cx, 16
  @@next_fgrnd:
        mov     al, 16
        sub     al, cl
        call    textattr
        mov     al, 219
        call    outchar
        loop    @@next_fgrnd

        mov     ax, 3 + 3 * 256
        call    gotoxy

        mov     cx, 8
  @@next_bgrnd:
        mov     al, 8
        sub     al, cl
        call    textattr
        mov     al, 219
        call    outchar
        call    wherey
        inc     ah
        mov     al, 3
        call    gotoxy
        loop    @@next_bgrnd

        mov     al, 0Fh
        call    textattr

        pop     ax
        call    gotoxy

  @@main_loop:
    ; Vis markõrer for nÜvërende attributt
        call    wherex
        call    wherey
        push    ax

        mov     al, [attr]
        and     ax, 000Fh
        add     ax, 10 + 3 * 256
        call    gotoxy
        mov     al, 24
        call    outchar

        mov     ah, [attr]
        shr     ah, 1
        shr     ah, 1
        shr     ah, 1
        shr     ah, 1
        and     ax, 0F00h
        add     ax, 4 + 3 * 256
        call    gotoxy
        mov     al, 27
        call    outchar

    ; Vis eksempel pÜ nÜvërende attributt
        mov     ax, 19 + 9 * 256
        call    gotoxy
        mov     al, [attr]
        call    textattr
        mov     dx, OFFSET coltxt
        call    outtext
        mov     al, 0Fh
        call    textattr

        pop     ax
        call    gotoxy

    ; Les en tast fra brukeren
        call    getkey
        push    ax

    ; Fjern markõrer for nÜvërende attributt
        call    wherex
        call    wherey
        push    ax

        mov     al, [attr]
        and     ax, 000Fh
        add     ax, 10 + 3 * 256
        call    gotoxy
        mov     al, ' '
        call    outchar

        mov     ah, [attr]
        shr     ah, 1
        shr     ah, 1
        shr     ah, 1
        shr     ah, 1
        and     ax, 0F00h
        add     ax, 4 + 3 * 256
        call    gotoxy
        mov     al, ' '
        call    outchar

        pop     ax
        call    gotoxy

    ; Tolk tasten til brukeren
        pop     ax
        cmp     ax, 27
        jne     @@not_aborted

    ; Avbrutt av bruker. Sett tidliger attributt, og hopp ut.
        mov     al, [tmpattr]
        mov     [attr], al
        jmp     SHORT @@ret

  @@not_aborted:
        cmp     ax, 13
        je      @@ret

  @@not_finished:
        cmp     ax, -75
        jne     @@not_left
        mov     al, [attr]
        and     al, 0Fh
        dec     al
        js      @@jmp_main_loop
        and     [attr], 0F0h
        or      [attr], al
  @@jmp_main_loop:
        jmp     @@main_loop

  @@not_left:
        cmp     ax, -77
        jne     @@not_right
        mov     al, [attr]
        and     al, 0Fh
        inc     al
        cmp     al, 15
        ja      @@jmp_main_loop
        and     [attr], 0F0h
        or      [attr], al
        jmp     @@main_loop

  @@not_right:
        cmp     ax, -72
        jne     @@not_up
        mov     al, [attr]
        and     al, 0F0h
        sub     al, 010h
        cmp     al, 070h
        ja      @@jmp_main_loop
        and     [attr], 0Fh
        or      [attr], al
        jmp     @@main_loop

  @@not_up:
        cmp     ax, -80
        jne     @@not_down
        mov     al, [attr]
        and     al, 0F0h
        add     al, 010h
        cmp     al, 070h
        ja      @@jmp_main_loop
        and     [attr], 0Fh
        or      [attr], al
        jmp     @@main_loop

  @@not_down:

        jmp     @@main_loop

  @@ret:
    ; Lukk vinduet
        call    closewindow

    ; Hent ut õnsket attributt
        mov     al, [attr]

        pop     dx
        pop     cx
        pop     bx
        ret
ENDP    get_color



;
; do_changes
;
; Hva prosedyren gjõr:
;   Gjõr de endringer i oppsettet som brukeren õnsker.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt
;
PROC    do_changes

    ; èpne et vindu av passelig stõrrelse, og vis overskrift
        mov     ax, 12 +  2 * 256
        mov     dx, 67 + 23 * 256
        mov     bl, 2
        mov     cx, 0E0Fh
        call    openwindow

        mov     dx, OFFSET head
        xor     al, al          ; Sentrert, topp
        call    bordertext

    ; Vis forklaring
        mov     dx, OFFSET explain
        call    outtext

    ; Vent til tast er trykket
        call    getkey
        cmp     ax, 27
        jne     @@not_aborted

  @@abort:
    ; Avbrutt av bruker.
        call    closewindow

        mov     dx, OFFSET aborted
        mov     ah, 9
        int     21h

        call    exit

  @@not_aborted:
    ; Vis selve menyen
        call    clrscr
        mov     dx, OFFSET menutxt
        call    outtext

  @@main_loop:
    ; Overskriv evt. tidligere valg
        call    wherex
        call    wherey
        push    ax
        mov     al, ' '
        call    outchar
        pop     ax
        call    gotoxy

    ; Vis nÜvërende status
        call    show_status

    ; Les tast fra brukeren
        call    getkey
        cmp     ax, 27
        je      @@abort

    ; Oversett til stor bokstav
        or      ah, ah          ; Extended key ?
        jnz     @@main_loop

        cmp     al, 'a'
        jb      @@check_key
        cmp     al, 'z'
        ja      @@main_loop
        sub     al, 'a' - 'A'

  @@check_key:
        cmp     al, 'A'
        jb      @@main_loop
        cmp     al, 'Z'
        ja      @@main_loop

    ; Vis trykket tast
        push    ax
        call    outchar
        call    wherex
        dec     al
        call    wherey
        call    gotoxy
        pop     ax

    ; Finn adressen til dataomrÜdet
        mov     bx, [area]

    ; Sjekk hva som er trykket. Dette er oversatt til stor bokstav.
        cmp     al, 'A'
        jne     @@not_resmouse
        xor     [(setupdata PTR bx).resmouse], 1
        jmp     @@main_loop

  @@not_resmouse:
        cmp     al, 'B'
        jne     @@not_insert
        xor     [(setupdata PTR bx).insert], 1
        jmp     @@main_loop

  @@not_insert:
        cmp     al, 'C'
        jne     @@not_indent
        xor     [(setupdata PTR bx).indent], 1
        jmp     @@main_loop

  @@not_indent:
        cmp     al, 'D'
        jne     @@not_pair
        xor     [(setupdata PTR bx).pair], 1
        jmp     @@main_loop

  @@not_pair:
        cmp     al, 'E'
        jne     @@not_tattr
        mov     al, [(setupdata PTR bx).sattr]
        call    get_color
        mov     [(setupdata PTR bx).sattr], al
        jmp     @@main_loop

  @@not_tattr:
        cmp     al, 'F'
        jne     @@not_battr
        mov     al, [(setupdata PTR bx).battr]
        call    get_color
        mov     [(setupdata PTR bx).battr], al
        jmp     @@main_loop

  @@not_battr:
        cmp     al, 'G'
        jne     @@not_hattr
        mov     al, [(setupdata PTR bx).hattr]
        call    get_color
        mov     [(setupdata PTR bx).hattr], al
        jmp     @@main_loop

  @@not_hattr:
        cmp     al, 'H'
        jne     @@not_ftattr
        mov     al, [(setupdata PTR bx).ftattr]
        call    get_color
        mov     [(setupdata PTR bx).ftattr], al
        jmp     @@main_loop

  @@not_ftattr:
        cmp     al, 'I'
        jne     @@not_frattr
        mov     al, [(setupdata PTR bx).frattr]
        call    get_color
        mov     [(setupdata PTR bx).frattr], al
        jmp     @@main_loop

  @@not_frattr:
        cmp     al, 'J'
        jne     @@not_htattr
        mov     al, [(setupdata PTR bx).htattr]
        call    get_color
        mov     [(setupdata PTR bx).htattr], al
        jmp     @@main_loop

  @@not_htattr:
        cmp     al, 'K'
        jne     @@not_hrattr
        mov     al, [(setupdata PTR bx).hrattr]
        call    get_color
        mov     [(setupdata PTR bx).hrattr], al
        jmp     @@main_loop

  @@not_hrattr:
        cmp     al, 'L'
        jne     @@not_mtattr
        mov     al, [(setupdata PTR bx).mtattr]
        call    get_color
        mov     [(setupdata PTR bx).mtattr], al
        jmp     @@main_loop

  @@not_mtattr:
        cmp     al, 'M'
        jne     @@not_mrattr
        mov     al, [(setupdata PTR bx).mrattr]
        call    get_color
        mov     [(setupdata PTR bx).mrattr], al
        jmp     @@main_loop

  @@not_mrattr:
        cmp     al, 'N'
        jne     @@not_default
    ; Kopier data fra standardomrÜdet.
        mov     cx, SIZE setupdata
        push    ds
        pop     es
        mov     si, OFFSET default
        mov     di, [area]
        cld
        rep     movsb
        jmp     @@main_loop

  @@not_default:
        cmp     al, 'Q'
        je      @@quit

        jmp     @@main_loop

  @@quit:
    ; Lukk vinduet
        call    closewindow

        ret
ENDP    do_changes





main:

    ; Sjekk om skjermen har riktig oppsett.
        mov     ah, 0Fh                 ; Sjekk om tekstmode
        int     10h
        cmp     al, 3
        jbe     @@tekstmode_ok
        cmp     al, 7
        je      @@tekstmode_ok

    ; Her er skjermen i grafikkmode. Dette er feil.
        mov     dx, OFFSET grmode

  @@show_error:
        mov     ah, 9
        int     21h
        call    exit

  @@tekstmode_ok:
    ; Sjekk om minst 80 kolonner
        call    screencols
        cmp     ax, 80
        jae     @@kolonner_ok

    ; Her har skjermen mindre enn 80 kolonner. Det er ogsÜ feil.
        mov     dx, OFFSET screrr
        jmp     @@show_error

  @@kolonner_ok:
    ; Initier eksterne moduler
        call    initmem         ; Brukes av window
        call    initscreen
        call    initwindow

    ; èpne ED.COM for lesing/skriving
        mov     ax, 3D02h       ; Open File, Read/Write
        mov     dx, OFFSET filenm
        int     21h
        jnc     @@open_ok

    ; Filen lot seg ikke Üpne. Avbryt med feilmelding.
        mov     dx, OFFSET openerr
        call    fatal

  @@open_ok:
    ; Hent filens dato/tid, sÜ dette kan settes tilbake senere.
        mov     [hdl], ax
        mov     bx, ax
        mov     ax, 5700h       ; Get File Date and Time
        int     21h
        mov     [ftime], cx
        mov     [fdate], dx

    ; Les inn filen i bufferet.
        mov     ah, 3Fh
        mov     bx, [hdl]
        mov     cx, MAXSIZ
        mov     dx, OFFSET buffer
        int     21h
        jnc     @@read_ok

    ; Kunne ikke lese fra fil. Avbryt med feilmelding.
        mov     dx, OFFSET readerr
        call    fatal

  @@read_ok:
    ; Lagre antall leste bytes
        mov     [filelen], ax

    ; Finn starten pÜ omrÜdet som kan endres
        call    find_area

    ; Utfõr evt. endringer
        call    do_changes

    ; Skriv bufferet til filen igjen. Flytt fõrst til filstart.
        mov     ax, 4200h       ; Set File Pointer, rel Start of File
        mov     bx, [hdl]
        xor     cx, cx
        xor     dx, dx
        int     21h
        jnc     @@seek_ok

    ; Kunne ikke flytte filpeker. Avbryt med feilmelding.
        mov     dx, OFFSET writerr
        call    fatal

  @@seek_ok:
    ; Skriv bufferet til disk
        mov     ah, 40h
        mov     bx, [hdl]
        mov     cx, [filelen]
        mov     dx, OFFSET buffer
        int     21h
        jnc     @@write_ok

  @@write_error:
    ; Kunne ikke skrive til disk. Avbryt med feilmelding.
        mov     dx, OFFSET writerr
        call    fatal

  @@write_ok:
    ; Sjekk at riktig antall bytes er skrevet
        cmp     ax, cx
        jne     @@write_error

    ; Sett tilbake filens dato/tid
        mov     ax, 5701h       ; Set File Date and Time
        mov     bx, [hdl]
        mov     cx, [ftime]
        mov     dx, [fdate]
        int     21h

    ; Lukk filen
        mov     ah, 3Eh         ; Close File
        int     21h
        jnc     @@close_ok

    ; Filen kunne ikke lukkes. Avbryt med feilmelding.
        mov     dx, OFFSET closerr
        call    fatal

  @@close_ok:
    ; Vis melding om at ED.COM er endret.
        mov     dx, OFFSET changed
        mov     ah, 9
        int     21h

    ; Rydd opp etter eksterne moduler, og avslutt.
        call    exit


ENDS



        END     start
