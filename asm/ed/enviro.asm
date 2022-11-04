        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING


INCLUDE "ED.INC"


;--------------------------;
;                          ;
;         D A T A          ;
;                          ;
;--------------------------;

UDATASEG

        PUBLIC  cpl, lpp

cpl     DW      ?            ; Antall tegn som skal vises pr linje i vinduet
lpp     DW      ?            ; Antall linjer som skal vises pr tekstside

tmplseg DW      ?            ; Segment til midl. linje under visning av skjerm
tmplpar DW      ?            ; Antall paragafer allokert til midl. linje

old1B   DD      ?            ; Adressen til gammelt BREAK-interrupt.




DATASEG

        EXTRN   doquit: BYTE
        EXTRN   sadr: DWORD, antkol2: WORD
        EXTRN   vx1: BYTE, vy1: BYTE, vx2: BYTE, vy2: BYTE
        EXTRN   curx: BYTE

        EXTRN   antlin: WORD, fromlin: WORD, fromcol: WORD
        EXTRN   curlin: WORD, curcol: WORD
        EXTRN   changed: BYTE
        EXTRN   filenm: PTR

        EXTRN   quit: PROC
        EXTRN   errorhd: PTR, criterr: PTR
        EXTRN   grmode: PTR, screrr: PTR
        EXTRN   outmem: PTR, toptxt: PTR, bottxt: PTR, prsesc: PTR
        EXTRN   inson: PTR, insoff: PTR, indon: PTR, indoff: PTR
        EXTRN   pairon: PTR, pairoff: PTR

        EXTRN   helphd: PTR
        EXTRN   help1: PTR, help2: PTR, help3: PTR
        EXTRN   help4: PTR, help5: PTR, help6: PTR
        EXTRN   help7: PTR

        EXTRN   pgup: PTR, pgupdn: PTR, pgdn: PTR
        EXTRN   idtxt: PTR
        EXTRN   notsvd: PTR

        PUBLIC  mtattr, mrattr, uattr, criticl
        PUBLIC  insert, indent, pair, tabul
IF MOUSE
        PUBLIC  resmouse
ENDIF


; Her fõlger data som kan endres av et setup-program.
; Fõrst en header som sõkes etter av setup-programmet, og en versjons-
; kode for Ü sjekke at det er riktig setup-program som brukes.

idstr   DB      "SETUPBUF", 0, VER, 0

LABEL   attributes BYTE
sattr   DB      14 + 1 * 16  ; Skjermattributtene i editorvinduet
battr   DB      14 + 7 * 16  ; Attributt pÜ uthevet tekst (blokk)
hattr   DB       4 + 7 * 16  ; Header-attributter
uattr   DB      15 + 0 * 16  ; Attributt pÜ uthevet valg i menyer
ftattr  DB      15 + 4 * 16  ; Feilvindu, textattr
frattr  DB      14 + 4 * 16  ; Feilvindu, rammeattr
htattr  DB       0 + 7 * 16  ; Hjelpevindu, textattr
hrattr  DB       0 + 7 * 16  ; Hjelpevindu, rammeattr
mtattr  DB       0 + 7 * 16  ; Meldingsvindu, textattr
mrattr  DB       0 + 7 * 16  ; Meldingsvindu, rammeattr

insert  DB      1            ; Er innsett pÜ?
indent  DB      1            ; Er autoindent pÜ?
pair    DB      1            ; Er parentesparring pÜ?
tabul   DB      0            ; Er tabulatormode pÜ? Dvs. Tab eller innrykk
                             ; nÜr Tab trykkes. Forelõpig ikke i bruk.
IF MOUSE
resmouse DB     0            ; Skal musa resettes?
ENDIF


; Attributter brukt pÜ skjerm som ikke viser farger.
; Disse kan ikke endres av et setup-program.
LABEL   monoattr BYTE
        DB      15 + 0 * 16  ; Skjermattributtene i editorvinduet
        DB       0 + 7 * 16  ; Attributt pÜ uthevet tekst (blokk)
        DB       0 + 7 * 16  ; Header-attributter
        DB       0 + 7 * 16  ; Uthevet valg i menyer
        DB      15 + 0 * 16  ; Feilvindu, textattr
        DB      15 + 0 * 16  ; Feilvindu, rammeattr
        DB      15 + 0 * 16  ; Hjelpevindu, textattr
        DB      15 + 0 * 16  ; Hjelpevindu, rammeattr
        DB       7 + 0 * 16  ; Meldingsvindu, textattr
        DB       7 + 0 * 16  ; Meldingsvindu, rammeattr
MONOLEN =       $ - monoattr

NUMHELP EQU     7       ; Antall hjelpeskjermer
helpnr  DB      ?       ; NÜvërende hjelpeskjerm
  ; Adressene til hjelpeskjermene
helps   DW      help1, help2, help3, help4, help5, help6, help7

  ; Taster som kan avbryte innlesning med lineinput
quitkey DW      -45, 0

criticl DB      0            ; Var det en kritisk feil? Brukes av error
                             ; Slik at en egen melding vises hvis det var
                             ; en critical error som inntraff.



CODESEG

;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

        EXTRN   getmem: PROC, freemem: PROC
        EXTRN   openwindow: PROC, closewindow: PROC
        EXTRN   bordertext: PROC, drawborder: PROC
        EXTRN   lineinput: PROC
        EXTRN   clrscr: PROC
        EXTRN   screenrows: PROC, screencols: PROC
        EXTRN   addr_of_pos: PROC
        EXTRN   textattr: PROC, clreol: PROC, gotoxy: PROC
        EXTRN   getkey: PROC, CHOICE: PROC
        EXTRN   outchar: PROC, outtext: PROC, outword: PROC
        EXTRN   strlen: PROC

        EXTRN   getline: PROC
        EXTRN   savefile: PROC
        EXTRN   inblock: PROC

        PUBLIC  initenviro, endenviro, openscreen
        PUBLIC  error, message, beep
        PUBLIC  showline, showscreen, showcursor
        PUBLIC  showlinnr, showcolnr, showinsert, showindent, showchanged
        PUBLIC  showpair
        PUBLIC  showfilename
        PUBLIC  showctrl, unshowctrl
        PUBLIC  help, showid
        PUBLIC  checksaved
        PUBLIC  userinput
IF SHOW_MEM
        EXTRN   memleft: PROC
        PUBLIC  showmemleft
ENDIF



;
; initenviro
;
; Hva prosedyren gjõr:
;   Finner attributter etter hvilken skjermtype som finnes.
;   Initierer denne modulen ved Ü Üpne vindu over hele skjermen osv.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    initenviro
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    es

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
        add     sp, 2                   ; Fjern kall fra stacken
        jmp     quit
  @@tekstmode_ok:
        call    screencols              ; Sjekk om minst 80 kolonner
        cmp     ax, 80
        jae     @@kolonner_ok
    ; Her har skjermen mindre enn 80 kolonner. Det er ogsÜ feil.
        mov     dx, OFFSET screrr
        jmp     @@show_error
  @@kolonner_ok:
        mov     ah, 0Fh
        int     10h
        or      al, al                  ; Sjekk om farger skal
        jz      @@sett_mono             ; vises. Hvis ikke, kopieres
        cmp     al, 2                   ; monoattributtene over
        je      @@sett_mono             ; fargeattributtene.
        cmp     al, 7
        jne     @@ikke_endre_attr
  @@sett_mono:
        push    ds
        pop     es
        mov     di, OFFSET attributes
        mov     si, OFFSET monoattr
        mov     cx, MONOLEN
        cld
        rep     movsb
  @@ikke_endre_attr:
        call    openscreen              ; èpne vindu over hele skjermen
        jnc      @@open_OK

    ; Vinduet kunne ikke Üpnes.
        mov     dx, OFFSET outmem
        call    error
        jmp     quit

  @@open_OK:
        mov     al, [vx2]
        sub     al, [vx1]
        xor     ah, ah
        inc     ax
        mov     [cpl], ax
        mov     al, [vy2]
        sub     al, [vy1]
        dec     al                      ; Trekk fra õverste linje
        xor     ah, ah
        mov     [lpp], ax

        mov     ax, MAXLEN + 1
        call    getmem
        or      ax, ax
        jne     @@allok_lin_ok
        mov     dx, OFFSET outmem
        call    error
        jmp     quit
  @@allok_lin_ok:
        mov     [tmplseg], es
        mov     [tmplpar], ax

    ; Sett ny Ctrl-C og Ctrl-Break -handler. Adressen til INT 1Bh mÜ
    ; fõrst lagres slik at den kan resettes nÜr programmet avslutter.
    ; Det er ikke nõdvendig Ü lagre adressen til INT 23h, siden MS-DOS
    ; resetter denne etter alle programmer.
        mov     ax, 351Bh               ; Get Interrupt Handler 1Bh
        int     21h
        mov     [WORD old1B], bx
        mov     [WORD old1B + 2], es

        push    ds
        push    cs
        pop     ds
        mov     dx, OFFSET ctrlbreak
        mov     ax, 251Bh               ; Set Interrupt Handler 1Bh
        int     21h
        mov     ax, 2523h               ; Set Interrupt Handler 23h
        int     21h
        pop     ds

        pop     es
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    initenviro



;
; endenviro
;
; Hva prosedyren gjõr:
;   Rydder opp etter denne modulen
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    endenviro
        push    ax
        push    dx
        push    es
        mov     es, [tmplseg]
        mov     ax, [tmplpar]
        call    freemem
        call    closewindow             ; Lukk vinduet over hele skjermen

    ; Resett gammel INT 1Bh -handler
        push    ds
        mov     ax, 251Bh               ; Set Interrupt Handler 1Bh
        mov     dx, [WORD old1B]
        mov     ds, [WORD old1B + 2]
        int     21h
        pop     ds

        pop     es
        pop     dx
        pop     ax
        ret
ENDP    endenviro



;
; ctrlbreak
;
; Hva interruptprosedyren gjõr:
;   Ingenting. Legges inn istedenfor den ordinëre rutinen, slik at det
;   ikke oppstÜr problemer med ctrl-C og ctrl-break
;
; Kall med:
;   Skal ikke kalles
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    ctrlbreak FAR
        iret
ENDP    ctrlbreak



;
; openscreen
;
; Hva prosedyren gjõr:
;   èpner editeringsvinduet ifõlge de verdier som er funnet av initenviro.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Carry : clear - ok
;           set   - kunne ikke Üpne vindu
;
; Endrer innholdet i:
;   Ingenting
;
PROC    openscreen
        push    ax
        push    bx
        push    cx
        push    dx

        call    screenrows              ; èpne vindu over hele skjermen
        mov     dh, al
        dec     dh
        call    screencols
        mov     dl, al
        dec     dl
        xor     ax, ax
        xor     bl, bl
        mov     cl, [sattr]
        call    openwindow
        or      ax, ax                  ; Er vinduet Üpnet?
        jz      @@open_window_ok

    ; Vinduet kunne ikke Üpnes. Marker dette, og hopp ut.
        stc
        jmp     SHORT @@ret

  @@open_window_ok:
        mov     al, [hattr]
        call    textattr
        mov     dx, OFFSET toptxt
        call    outtext
        call    clreol
        call    screenrows
        mov     ah, al
        dec     ah
        xor     al, al
        call    gotoxy
        mov     dx, OFFSET bottxt
        call    outtext
        call    clreol
        mov     al, [sattr]
        call    textattr
        mov     ax, 0100h               ; (0, 1) - skjermkoordinat
        call    gotoxy

    ; Alt er som det skal. Marker dette
        clc

  @@ret:
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    openscreen



;
; error
;
; Hva prosedyren gjõr:
;   èpner et vindu og viser en feilmelding. Venter til ESC er trykket.
;
; Kall med:
;   DS:DX - peker til feilmeldingen
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    error
        push    ax
        push    bx
        push    cx
        push    dx

    ; Sjekk om det nylig har skjedd en critical error. Hvis det er tilfellet,
    ; er det sannsynligvis den som var Ürsak til en eller annen ny feil.
    ; Vis en egen melding.
        cmp     [criticl], 0
        jz      @@not_critical

        mov     dx, OFFSET criterr
        mov     [criticl], 0

  @@not_critical:
        push    dx

        call    strlen
        mov     dx, 0B12h
        add     dl, al
        mov     ax, 0903h
        mov     bl, 1
        mov     cl, [ftattr]
        mov     ch, [frattr]
        call    openwindow
        mov     dx, OFFSET errorhd
        xor     al, al
        call    bordertext
        mov     al, ' '
        call    outchar
        pop     dx
        call    outtext
        mov     al, '.'
        call    outchar
        mov     al, ' '
        call    outchar
        call    outchar
        mov     dx, OFFSET prsesc
        call    outtext
  @@keyloop:
        call    getkey
        cmp     ax, 27
        jne     @@keyloop
        call    closewindow
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    error



;
; message
;
; Hva prosedyren gjõr:
;   èpner et vindu og viser en melding. Vinduet forblir Üpent til
;   det lukkes pÜ vanlig mÜte.
;
; Kall med:
;   DS:DX - peker til meldingen
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    message
        push    ax
        push    bx
        push    cx
        push    dx
        push    dx
        call    strlen
        mov     dx, 0806h
        add     dl, al
        mov     ax, 0603h
        mov     bl, 1
        mov     cl, [mtattr]
        mov     ch, [mrattr]
        call    openwindow
        mov     al, ' '
        call    outchar
        pop     dx
        call    outtext
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    message



;
; beep
;
; Hva prosedyren gjõr:
;   Lager pipetone
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    beep
        push    ax
        push    bx

        mov     ax, 0E07h       ; Write Character (bell) in Teletype Mode
        int     10h

        pop     bx
        pop     ax
        ret
ENDP    beep



;
; showline
;
; Hva prosedyren gjõr:
;   Viser angitt ASCIIZ-streng pÜ angitt linje pÜ skjermen.
;
; Kall med:
;   AX    - ùnsket skjermlinje. Dette er virkelig skjermlinje, slik at 0
;           betyr helt õverst i vinduet.
;   BX    - Offset fra starten av strengen. De fõrste BX tegnene vises ikke.
;   DX    - Linjens nummer (brukes for Ü sjekke om i blokk)
;   ES:DI - peker til ASCIIZ-strengen.
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    showline
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    es
        push    bp

        mov     cx, bx          ; CX = offset fra linjestart
        mov     bx, di          ; Spar linjestart

        mov     si, ax          ; Spar AX i SI midlertidig
        jcxz    @@mer_igjen
        cld                     ; Skip de fõrste CX tegnene
        xor     al, al
        repne   scasb
        jne     @@mer_igjen     ; Hvis 0 ikke ble funnet, skal tekst vises.
        dec     di              ; Peker pÜ 0, slik at linjen er tom.
  @@mer_igjen:

        mov     ax, si          ; Hent tilbake AX

        mov     si, di
        mov     bp, es          ; BP:SI peker midlertidig til linjen

        add     al, [vy1]       ; Finn adressen til fõrste tegn
        mov     ah, al
        xor     al, al
        call    addr_of_pos     ; Adressen i ES:DI

        mov     cx, [cpl]       ; Antall tegn som skal vises

        cld                     ; Vis riktig antall tegn
  @@neste_tegn:
        mov     ah, [sattr] ; Anta utenfor blokk
        push    ax
        push    dx
        mov     ax, dx
        mov     dx, si
        sub     dx, bx          ; Finner kolonnen nÜvërende tegn hentes fra
        call    inblock
        pop     dx
        pop     ax
        jnc     @@ikke_i_blokk
        mov     ah, [battr]
  @@ikke_i_blokk:
        push    ds
        mov     ds, bp
        lodsb
        pop     ds
        or      al, al          ; Slutten pÜ linjen?
        je      @@clr_eol
        stosw
        loop    SHORT @@neste_tegn
  @@clr_eol:

IF SHOW_EOL
        jcxz    @@ret
        or      al, al
        jnz     @@ikke_vis_eol
        mov     al, 249                ; Dette er bare i testfasen.
        stosw                          ; Markerer linjeslutt.
        dec     cx
  @@ikke_vis_eol:
ENDIF

        jcxz    @@ret
        mov     al, ' '         ; Fyll ut resten av linjen med blanke
        rep     stosw

  @@ret:
        pop     bp
        pop     es
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    showline



;
; showscreen
;
; Hva prosedyren gjõr:
;   Viser riktig del av filen pÜ skjermen. Dette bestemmes av innholdet
;   i [fromlin] og [fromcol].
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    showscreen
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    es

        mov     es, [tmplseg]
        mov     dx, 1            ; Linjenummeret pÜ skjermen
        mov     cx, [lpp]
        mov     ax, [fromlin]
        mov     bx, [fromcol]
        xor     di, di
  @@neste_linje:
        cmp     ax, [antlin]
        jae     @@forbi_slutten
        call    getline
        jmp     SHORT @@vis_linje
  @@forbi_slutten:
        xor     di, di
        mov     [BYTE es: di], 0 ; Tom linje
  @@vis_linje:
        xchg    ax, dx
        call    showline
        xchg    ax, dx
        inc     dx
        inc     ax
        loop    @@neste_linje

  @@ret:
        pop     es
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    showscreen



;
; showcursor
;
; Hva prosedyren gjõr:
;    Setter markõren pÜ riktig sted pÜ skjermen.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    showcursor
        push    ax
        push    bx
        mov     ax, [curlin]
        sub     ax, [fromlin]
        inc     al              ; Forbi overskriften
        mov     bl, al          ; Lagre Y-koordinat midlertidig i BL
        mov     ax, [curcol]
        sub     ax, [fromcol]
        mov     ah, bl
        call    gotoxy
        pop     bx
        pop     ax
        ret
ENDP    showcursor



;
; showlinnr
;
; Hva prosedyren gjõr:
;   Viser nÜvërende linjenummer pÜ riktig plass pÜ skjermen.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    showlinnr
        push    ax
        mov     al, [hattr]
        call    textattr
        mov     ax, 8           ; (8, 0)
        call    gotoxy
        mov     ax, [curlin]
        inc     ax
        call    outword
  @@vis_blank:
        cmp     [curx], 13
        jae     @@ret
        mov     al, ' '
        call    outchar
        jmp     SHORT @@vis_blank
  @@ret:
        mov     al, [sattr]
        call    textattr
        call    showcursor
        pop     ax
        ret
ENDP    showlinnr



;
; showcolnr
;
; Hva prosedyren gjõr:
;   Viser nÜvërende kolonnenummer pÜ riktig plass pÜ skjermen.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    showcolnr
        push    ax
        mov     al, [hattr]
        call    textattr
        mov     ax, 18          ; (18, 0)
        call    gotoxy
        mov     ax, [curcol]
        inc     ax
        call    outword
  @@vis_blank:
        cmp     [curx], 21
        jae     @@ret
        mov     al, ' '
        call    outchar
        jmp     SHORT @@vis_blank
  @@ret:
        mov     al, [sattr]
        call    textattr
        call    showcursor
        pop     ax
        ret
ENDP    showcolnr



;
; showinsert
;
; Hva prosedyren gjõr:
;   Viser status for insertmode
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    showinsert
        push    ax
        push    dx
        mov     al, [hattr]
        call    textattr
        mov     ax, 22          ; (22, 0)
        call    gotoxy
        mov     dx, OFFSET inson
        cmp     [insert], 0
        jne     @@innsett
        mov     dx, OFFSET insoff
  @@innsett:
        call    outtext
        mov     al, [sattr]
        call    textattr
        call    showcursor
        pop     dx
        pop     ax
        ret
ENDP    showinsert



;
; showindent
;
; Hva prosedyren gjõr:
;   Viser status for indentmode
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    showindent
        push    ax
        push    dx
        mov     al, [hattr]
        call    textattr
        mov     ax, 30          ; (30, 0)
        call    gotoxy
        mov     dx, OFFSET indon
        cmp     [indent], 0
        jne     @@innrykk
        mov     dx, OFFSET indoff
  @@innrykk:
        call    outtext
        mov     al, [sattr]
        call    textattr
        call    showcursor
        pop     dx
        pop     ax
        ret
ENDP    showindent



;
; showpair
;
; Hva prosedyren gjõr:
;   Viser status for parentesparringsmode
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    showpair
        push    ax
        push    dx
        mov     al, [hattr]
        call    textattr
        mov     ax, 38          ; (38, 0)
        call    gotoxy
        mov     dx, OFFSET pairon
        cmp     [pair], 0
        jne     @@parring
        mov     dx, OFFSET pairoff
  @@parring:
        call    outtext
        mov     al, [sattr]
        call    textattr
        call    showcursor
        pop     dx
        pop     ax
        ret
ENDP    showpair



;
; showchanged
;
; Hva prosedyren gjõr:
;   Viser * hvis teksten er endret
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    showchanged
        push    ax
        mov     al, [hattr]
        call    textattr
        mov     ax, 63          ; (63, 0)
        call    gotoxy
        mov     al, '*'
        cmp     [changed], 0
        jne     @@endret
        mov     al, ' '
  @@endret:
        call    outchar
        mov     al, [sattr]
        call    textattr
        call    showcursor
        pop     ax
        ret
ENDP    showchanged



;
; showctrl
;
; Hva prosedyren gjõr:
;   Viser ^x fõrst pÜ õverste linje, og lar markõren stÜ bak dette.
;
; Kall med:
;   AL : ASCII-koden til bokstaven som skal vises
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    showctrl
        push    ax
        mov     al, [hattr]
        call    textattr
        xor     ax, ax          ; (0, 0)
        call    gotoxy
        mov     al, '^'
        call    outchar
        pop     ax
        call    outchar
        ret
ENDP    showctrl



;
; unshowctrl
;
; Hva prosedyren gjõr:
;   Fjerner tidligere vist ^xy fõrst pÜ õverste linje, og flytter markõren
;   til riktig posisjon pÜ skjermen.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    unshowctrl
        push    ax
        mov     al, [hattr]
        call    textattr
        xor     ax, ax          ; (0, 0)
        call    gotoxy
        mov     al, ' '
        call    outchar
        call    outchar
        call    outchar
        mov     al, [sattr]
        call    textattr
        call    showcursor
        pop     ax
        ret
ENDP    unshowctrl



;
; showfilename
;
; Hva prosedyren gjõr:
;   Viser navnet pÜ nÜvërende fil. Det som vises, er bare siste delen av
;   en evt path, pluss driven.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    showfilename
        push    ax
        push    cx
        push    dx
        push    di
        push    si
        mov     al, [hattr]
        call    textattr
        mov     ax, 65          ; (65, 0)
        call    gotoxy
        mov     dx, OFFSET filenm
        mov     si, dx
        mov     di, dx
        call    strlen
        mov     cx, ax
        jcxz    @@clr_to_end_of_line
        add     si, cx
        inc     cx
        cmp     [BYTE di + 1], ':'
        jne     @@neste
        mov     al, [di]
        call    outchar
        mov     al, ':'
        call    outchar
  @@neste:
        cmp     [BYTE si], '\'
        je      @@visnavn
        cmp     [BYTE si], ':'
        je      @@visnavn
        dec     si
        loop    @@neste
  @@visnavn:
        mov     dx, si
        inc     dx
        call    outtext
  @@clr_to_end_of_line:
        call    clreol
        mov     al, [sattr]
        call    textattr
        call    showcursor
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     ax
        ret
ENDP    showfilename



IF SHOW_MEM
;
; showmemleft
;
; Hva prosedyren gjõr:
;   Viser antall ledige paragrafer õverst pÜ skjermen.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    showmemleft
        push    ax
        mov     al, [hattr]
        call    textattr
        mov     ax, 50          ; (50, 0)
        call    gotoxy
        call    memleft
        call    outword
@@vis_blank:
        cmp     [curx], 56
        jae     @@ret
        mov     al, ' '
        call    outchar
        jmp     SHORT @@vis_blank
@@ret:  mov     al, [sattr]
        call    textattr
        call    showcursor
        pop     ax
        ret
ENDP    showmemleft
ENDIF



;
; showid
;
; Hva prosedyren gjõr:
;   Viser identifikasjonsvindu
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    showid
        push    ax
        push    bx
        push    cx
        push    dx
        mov     ax, 26 + 5  * 256
        mov     dx, 53 + 17 * 256
        mov     bl, 2
        mov     cl, [htattr]
        mov     ch, [hrattr]
        call    openwindow
        mov     dx, OFFSET idtxt
        call    outtext
        call    getkey
        call    closewindow
  @@ret:
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    showid


;
; checksaved
;
; Hva prosedyren gjõr:
;   Sjekker om teksten er endret. Gir isÜfall mulighet for Ü lagre.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   AX : Tasten brukeren evt. svarte pÜ spõrsmÜl.
;
; Endrer innholdet i:
;   AX
;
PROC    checksaved
        push    dx
        xor     ax, ax
        cmp     [changed], 0
        je      @@ret
        mov     dx, OFFSET notsvd
        call    message
        call    CHOICE
        cmp     ax, 'Y'
        jne     @@closew
        call    closewindow
        call    savefile
        jmp     SHORT @@ret
  @@closew:
        call    closewindow
        call    showchanged
  @@ret:
        pop     dx
        ret
ENDP    checksaved



;
; help
;
; Hva prosedyren gjõr:
;   Viser hjelpevindu
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    help
        push    ax
        push    bx
        push    cx
        push    dx
        mov     [helpnr], 0
        mov     ax, 16 + 3  * 256
        mov     dx, 63 + 21 * 256
        mov     bl, 1
        mov     cl, [htattr]
        mov     ch, [hrattr]
        call    openwindow
  @@help_loop:
        call    clrscr
        call    drawborder
        mov     dx, OFFSET helphd
        xor     al, al          ; Sentrert, topp
        call    bordertext
        mov     bl, [helpnr]
        xor     bh, bh
        or      bl, bl
        jne     @@ikke_forste
        mov     dx, OFFSET pgdn
        jmp     SHORT @@vis_hjelp
  @@ikke_forste:
        cmp     bl, NUMHELP - 1
        jne     @@ikke_siste
        mov     dx, OFFSET pgup
        jmp     SHORT @@vis_hjelp
  @@ikke_siste:
        mov     dx, OFFSET pgupdn
  @@vis_hjelp:
        mov     al, 5   ; Nederst til hõyre
        call    bordertext
    ; Vis selve hjelpen
        shl     bx, 1
        mov     dx, [helps + bx]
        call    outtext
  @@nytt_tegn:
        call    getkey
        cmp     ax, 27
        je      @@ferdig
        cmp     ax, QUITKEY
        jne     @@ikke_quit
        mov     [doquit], 1
        jmp     SHORT @@ferdig
  @@ikke_quit:
        cmp     ax, -73 ; PgUp
        jne     @@ikke_pgup
        cmp     [helpnr], 0
        je      @@neste
        dec     [helpnr]
        jmp     SHORT @@neste
  @@ikke_pgup:
        cmp     ax, -81 ; PgDn
        jne     @@nytt_tegn
        cmp     [helpnr], NUMHELP - 1
        je      @@neste
        inc     [helpnr]
  @@neste:
        jmp     @@help_loop

  @@ferdig:
        call    closewindow
  @@ret:
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    help



;
; userinput
;
; Hva prosedyren gjõr:
;   èpner et vindu hvor brukeren fÜr skrive inn et eller annet.
;
; Kall med:
;   AX - Maks lengde pÜ det som leses inn
;   BX - Antall tegn som vises pÜ skjermen
;   DX - Peker til streng som skal vëre header i vinduet
;   SI - Peker til dit teksten skal legges
;        Det som evt finnes her fra fõr, kan redigeres.
;
;   Kalleren mÜ passe pÜ at teksten som vises pÜ rammen er mindre enn
;   det som blir lengden pÜ det Üpnede vinduet.
;
; Returnerer:
;   Carry : clear - ikke avbrutt av bruker
;           set   - avbrutt av bruker
;
; Endrer innholdet i:
;   Ingenting
;
PROC    userinput
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    si
        push    es

        push    ax

    ; èpne vindu for spõrring etter input fra bruker
        push    bx
        push    dx
        mov     ax, 0303h       ; ùverste venstre hjõrne: (3, 3)
        mov     dx, 0506h       ; Nederste hõyre hjõrne:  (6+, 5)
        add     dl, bl
        mov     bl, 1           ; Enkel ramme
        mov     cl, [mtattr]
        mov     ch, [mrattr]
        call    openwindow
        pop     dx
        pop     bx

        xor     al, al          ; Sentrert header
        call    bordertext

    ; Les inn tekst
        mov     ax, 1           ; Posisjon (1, 0)
        call    gotoxy

        pop     ax

        mov     di, OFFSET quitkey
        mov     cl, [uattr]     ; Attributt fõr tidligere tekst godtas
        mov     ch, [mtattr]    ; Attributt etter at tidligere tekst er godtatt
    ; Hvis linjen er tom fra fõr, skal startattributten ikke vëre ulik.
        cmp     [BYTE si], 0
        jnz     @@les_inn
        mov     cl, ch
  @@les_inn:
        call    lineinput
        call    closewindow

    ; Sjekk om QUITKEY er trykket
        cmp     ax, QUITKEY
        jne     @@dont_quit
        mov     [doquit], 1
        stc                     ; Marker at avbrutt
        jmp     SHORT @@ret

  @@dont_quit:
    ; Sjekk om ESC er trykket
        cmp     ax, 27
        jne     @@not_esc
        stc                     ; Marker at avbrutt
        jmp     SHORT @@ret

  @@not_esc:
        clc                     ; Marker at ikke avbrutt

  @@ret:
        pop     es
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    userinput





ENDS

        END
