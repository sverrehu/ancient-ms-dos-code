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

        EXTRN   savepck: BYTE
   IF MOUSE
        EXTRN   xmouse: WORD, ymouse: WORD, mbutt: BYTE
   ENDIF
        EXTRN   blockon: BYTE
        EXTRN   blklin1: WORD, blkcol1: WORD, blklin2: WORD, blkcol2: WORD
        EXTRN   poslin1: WORD, poscol1: WORD, poslin2: WORD, poscol2: WORD
        EXTRN   syslin: WORD, syscol: WORD

        PUBLIC  doquit, xlin, xlinlen, changed, numinp
        PUBLIC  fromlin, fromcol, curlin, curcol, tmplin, linlen


  ; Skal programmet avsluttes? Settes av diverse funksjoner hvis
  ; QUITKEY er trykket.
doquit  DB      ?

  ; Buffer for innlesing av et tall
numinp  DB      6 DUP (?)

  ; Midlertidig linje for editering
tmplin  DB      (MAXLEN + 1) DUP (?)
linlen  DW      ?       ; Lengden pÜ ASCIIZ-stringen i tmplin

  ; Midlertidig hjelpelinje for bruk innen prosedyrer
xlin    DB      (MAXLEN + 1) DUP (?)
xlinlen DW      ?

  ; Variabler som angir hvor dokumentet skal vises fra
fromlin DW      ?       ; Hvilken linje som er õverst pÜ skjermen
fromcol DW      ?       ; Hvilken kolonne som er lengst til venstre

  ; NÜvërende posisjon i teksten
curlin  DW      ?
curcol  DW      ?
changed DB      ?       ; 1 hvis hele _teksten_ er endret



DATASEG

        EXTRN   antlin: WORD
        EXTRN   cpl: WORD, lpp: WORD
        EXTRN   ctrltbl: PTR, functbl: PTR
        EXTRN   insert: BYTE, indent: BYTE, pair: BYTE, tabul: BYTE

  ; Tegn som skal settes inn, lagret som en streng
chrin   DB      ?, 0

; Fõlgende to brukes under parentesparring
lpara   DB      '({["'
rpara   DB      ')}]"'
LABEL   paraend BYTE
PARAS   EQU     (OFFSET paraend - OFFSET rpara)       ; Antall parenteser





CODESEG

;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

        EXTRN   getkey: PROC
        EXTRN   strlen: PROC
        EXTRN   atoui: PROC
        EXTRN   screenrows: PROC

        EXTRN   chkmem: PROC
        EXTRN   getline: PROC, setline: PROC
        EXTRN   insertinline: PROC

        EXTRN   beep: PROC
        EXTRN   showline: PROC, showscreen: PROC, showcursor: PROC
        EXTRN   showlinnr: PROC, showcolnr: PROC
        EXTRN   showinsert: PROC, showindent: PROC, showchanged: PROC
        EXTRN   showpair: PROC, showfilename: PROC

        EXTRN   resetblock: PROC
   IF MOUSE
        EXTRN   getmouse: PROC, showmouse: PROC, hidemouse: PROC
   ENDIF

        EXTRN   checksaved: PROC
   IF SHOW_MEM
        EXTRN   showmemleft: PROC
   ENDIF
        EXTRN   downscrl: PROC, upscrl: PROC, leftchr: PROC



        PUBLIC  initedit, endedit
        PUBLIC  edit, reset_ed, show_info
        PUBLIC  setchanged, fetchline, storechar
        PUBLIC  movetopos, movetoposcentre, justpos, showthisline, none




;
; initedit
;
; Hva prosedyren gjõr:
;   Setter opp variabler for editeringsfunksjonene
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
PROC    initedit
        mov     [doquit], 0
        call    reset_ed
        ret
ENDP    initedit



;
; endedit
;
; Hva prosedyren gjõr:
;   Rydder opp etter editoren fõr avslutning
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
PROC    endedit
        ret
ENDP    endedit



;
; none
;
; Hva prosedyren gjõr:
;   Ingenting, bare utfõrer RET.
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
PROC    none
        ret
ENDP    none



;
; quit
;
; Hva prosedyren gjõr:
;   Sjekker om teksten er endret, og gir isÜfall mulighet for Ü lagre.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   AX : Tast som evt avsluttet spõrsmÜl om filen skulle lagres
;
; Endrer innholdet i:
;   AX
;
PROC    quit
        call    checksaved
        mov     [doquit], 0
        ret
ENDP    quit



;
; reset_ed
;
; Hva prosedyren gjõr:
;   Nullstiller alle variabler som har med editeringen Ü gjõre.
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
PROC    reset_ed
        push    ax
        xor     ax, ax
        mov     [fromlin], ax
        mov     [fromcol], ax
        mov     [curlin], ax
        mov     [curcol], ax
        mov     [changed], al
        call    resetblock
        pop     ax
        ret
ENDP    reset_ed



;
; show_info
;
; Hva prosedyren gjõr:
;   Viser alle variabler som har med editeringen Ü gjõre (statuslinjen)
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
PROC    show_info
        call    showscreen
        call    showcursor
        call    showlinnr
        call    showcolnr
        call    showinsert
        call    showindent
        call    showpair
        call    showchanged
        call    showfilename
        ret
ENDP    show_info



;
; showthisline
;
; Hva prosedyren gjõr:
;   Viser nÜvërende linje pÜ riktig sted pÜ skjermen. Det som vises
;   hentes fra tmplin
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
PROC    showthisline
        push    ax
        push    bx
        push    dx
        push    di
        push    es

        mov     bx, [fromcol]
        mov     ax, [curlin]
        mov     dx, ax
        sub     ax, [fromlin]
        inc     ax

        push    ds
        pop     es
        mov     di, OFFSET tmplin
        call    showline

        pop     es
        pop     di
        pop     dx
        pop     bx
        pop     ax
        ret
ENDP    showthisline



;
; setchanged
;
; Hva prosedyren gjõr:
;   Setter endretstatus og viser dette.
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
PROC    setchanged
        mov     [changed], 1
        call    showchanged
        ret
ENDP    setchanged



;
; storechar
;
; Hva prosedyren gjõr:
;   Setter in et tegn i teksten. Tar hensyn til innsett/erstatt, osv.
;
; Kall med:
;   AL - Tegnet som skal settes inn
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    storechar
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    es

        push    ds
        pop     es
        call    chkmem
        jc      @@ret

    ; Marker at teksten er endret
        call    setchanged

        mov     cx, [curcol]
        cmp     cx, MAXLEN
        jb      @@plass_nok
        call    beep
        jmp     SHORT @@ret
  @@plass_nok:
    ; Hvis markõren er bak linjens slutt, eller innsett er pÜ, skal
    ; Tegnet SETTES INN i teksten, og ikke overskrive noe. Dette
    ; overlates til insertinline
        cmp     [insert], 0
        jnz     @@sett_inn
        cmp     cx, [linlen]
        jae     @@sett_inn

  @@overskriv:
        mov     di, OFFSET tmplin
        add     di, [curcol]
        mov     [di], al
        call    storeline

        jmp     SHORT @@oppdater
  @@sett_inn:
        mov     [chrin], al
        mov     ax, [curlin]
        mov     bx, [curcol]
        mov     di, OFFSET chrin
        call    insertinline
        jc      @@ret
        call    fetchline

  @@oppdater:
    ; Tegnet er satt inn. Oppdater curlin og evt. markõren.
        cmp     [curcol], MAXLEN
        ja      @@ikke_flytt_cursor
        inc     [curcol]
        call    justpos
        call    showcolnr
  @@ikke_flytt_cursor:

        call    showthisline

  @@ret:
        pop     es
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    storechar



;
; storeline
;
; Hva prosedyren gjõr:
;   Lagrer nÜvërende editeringslinje (buffer) pÜ riktig plass i minnet.
;   Kalles hver gang linjen er endret.
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
PROC    storeline
        push    ax
        push    dx
        push    di
        push    es

        mov     ax, [curlin]
        mov     di, OFFSET tmplin
        call    setline
        call    setchanged
        mov     dx, di
        call    strlen
        mov     [linlen], ax

        pop     es
        pop     di
        pop     dx
        pop     ax
        ret
ENDP    storeline



;
; fetchline
;
; Hva prosedyren gjõr:
;   Henter linjen som skal bli nÜvërende editeringslinje utfra info i curlin.
;   Kalles nÜr linjenummeret er endret.
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
PROC    fetchline
        push    ax
        push    dx
        push    di
        mov     ax, [curlin]
        mov     di, OFFSET tmplin
        call    getline
        mov     dx, OFFSET tmplin
        call    strlen
        mov     [linlen], ax
        pop     di
        pop     dx
        pop     ax
        ret
ENDP    fetchline



;
; fetchxline
;
; Hva prosedyren gjõr:
;   Henter angitt linje inn i det midlertidige linjebufferet [xlin].
;
; Kall med:
;   AX : ùnsket linjenummer
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   xlin, xlinlen
;
PROC    fetchxline
        push    ax
        push    dx
        push    di
        mov     di, OFFSET xlin
        call    getline
        mov     dx, OFFSET xlin
        call    strlen
        mov     [xlinlen], ax
        pop     di
        pop     dx
        pop     ax
        ret
ENDP    fetchxline



;
; edit
;
; Hva prosedyren gjõr:
;
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
PROC    edit
        push    ds
        pop     es
        call    fetchline
        call    show_info
  @@next_key:
    ; Sjekk om en eller annen funksjon har bestemt at programmet
    ; skal avsluttes.
        cmp     [doquit], 0
        jz      @@dont_quit
        jmp     @@do_quit

  @@dont_quit:
   IF SHOW_MEM
        call    showmemleft
   ENDIF
   IF SHOW_ALL
        call    showscreen
   ENDIF
        call    showcursor
   IF MOUSE
        call    showmouse
   ENDIF
  @@key_loop:
    ; Fõrst sjekker vi musa inntil en tast er trykket.
        mov     ah, 1   ; Get Keyboard Status
        int     16h
        jnz     @@key_pressed

        int     28h     ; Dette gjõr DOS mens det ventes pÜ tastetrykk
        stc

   IF MOUSE
        call    getmouse
   ENDIF
        jc      @@key_loop

   IF MOUSE
        call    hidemouse
    ; Finn ut hvor muspekeren er
        cmp     [ymouse], 0     ; Er vi pÜ õverste statuslinje ??
        je      @@scroll_mus
        call    screenrows
        dec     ax
        cmp     [ymouse], ax
        jb      @@ikke_scroll_mus
  @@scroll_mus:
    ; Musa er pÜ õverste eller nederste statuslinje. Utfõr scrolling av linje
    ; enten opp eller ned avhengig av hvilken mustast som er trykket.
        test    [mbutt], 1      ; Er venstre mustast trykket ??
        jz      @@ikke_linje_opp
    ; Scroll en linje opp.
        call    downscrl
        jmp     SHORT @@next_key
  @@ikke_linje_opp:
        test    [mbutt], 2      ; Er hõyre mustast trykket ??
        jz      @@next_key
    ; Scroll en linje ned
        call    upscrl
        jmp     SHORT @@next_key

  @@ikke_scroll_mus:
    ; Musa er plassert i teksten. Flytt markõren til angitt posisjon, eller
    ; sÜ nërt som mulig hvis posisjonen er nedenfor siste tekstlinje hvis
    ; venstre tast er trykket.
        test    [mbutt], 1      ; Er venstre mustast trykket ??
        jz      @@next_key
    ; Flytt markõren til musas posisjon.
        mov     ax, [ymouse]
        dec     ax
        add     ax, [fromlin]
        mov     [curlin], ax
        cmp     ax, [antlin]
        jbe     @@ypos_ok
        mov     ax, [antlin]
        dec     ax
        mov     [curlin], ax
  @@ypos_ok:
        mov     ax, [xmouse]
        add     ax, [fromcol]
        mov     [curcol], ax
        call    justpos
        call    showlinnr
        call    showcolnr
        call    showscreen
        call    fetchline
        jmp     @@next_key
   ENDIF

  @@key_pressed:
   IF MOUSE
        call    hidemouse
   ENDIF
        call    getkey
        cmp     ax, 32
        jl      @@ikke_tegn     ; jl - tester ogsÜ pÜ sign.
        call    storechar
    ; Sjekk om tasten er en parentes, og om denne da skal parres.
        cmp     [pair], 0
        je      @@ikke_parring
        cmp     [insert], 0
        je      @@ikke_parring
        mov     di, OFFSET lpara
        mov     cx, PARAS
        cld
        repne   scasb
        jne     @@ikke_parring
        dec     di
        sub     di, OFFSET lpara
        add     di, OFFSET rpara
        mov     al, [di]
        call    storechar
        call    leftchr
  @@ikke_parring:
        jmp     @@next_key

  @@ikke_tegn:
    ; Her er det en eller annen tastekommando som er trykket.
    ; Denne skal tolkes.
        cmp     ax, 26
        jg      @@next_key_2   ; Muligens ESC
        or      ax, ax
        jz      @@next_key_2   ; Ctrl-Break returnerer 0
        js      @@utvidet_tast
    ; Her er en Ctrl-kombinasjon trykket. (0 <= AX < 32)
        xor     ah, ah
        mov     bx, OFFSET ctrltbl
        dec     al     ; Hopp over kode 0
        shl     ax, 1
        add     bx, ax
        call    [WORD bx]
        jmp     @@next_key

  @@utvidet_tast:
    ; Her er en utvidet tast trykket (AX < 0)
        neg     ax
        cmp     al, 45  ; Test spesielt pÜ Alt-X
        jne     @@ikke_quit
  @@do_quit:
        call    quit
        cmp     ax, 27
        jne     @@ret
  @@next_key_2:
        jmp     @@next_key
  @@ikke_quit:
        cmp     al, 59
        jb      @@next_key_2
        cmp     al, 132
        ja      @@next_key_2
        cmp     al, 119     ; Under eller lik Ctrl-Home ?
        jbe     @@tolk_tast
        cmp     al, 132
        jne     @@next_key_2
  @@spesial_132:
        sub     al, (132-120)
  @@tolk_tast:
        sub     al, 59      ; Start pÜ F1
        xor     ah, ah
        mov     bx, OFFSET functbl
        shl     ax, 1
        add     bx, ax
        call    [WORD bx]
        jmp     @@next_key
  @@ret:
        ret
ENDP    edit



;
; justpos
;
; Hva prosedyren gjõr:
;   Justerer fromlin/fromcol slik at nÜvërende posisjon er innenfor
;   skjermomrÜdet.
;   Viser skjermen til slutt.
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
PROC    justpos
        push    ax
        mov     ax, [curcol]
        cmp     ax, [fromcol]
        jae     @@sjekk_col_left
    ; Her er X-posisjonen til venstre for fõrste skjermkolonne
        mov     [fromcol], ax
        call    showscreen
        jmp     SHORT @@sjekk_lin_top
  @@sjekk_col_left:
        mov     ax, [fromcol]
        add     ax, [cpl]
        cmp     ax, [curcol]
        ja      @@sjekk_lin_top
    ; Her er X-posisjonen til hõyre for siste skjermkolonne
        mov     ax, [curcol]
        sub     ax, [cpl]
        inc     ax
        mov     [fromcol], ax
        call    showscreen
  @@sjekk_lin_top:
        mov     ax, [curlin]
        cmp     ax, [fromlin]
        jae     @@sjekk_lin_bott
    ; Her er Y-posisjonen over (mindre enn) fõrste skjermlinje
        mov     [fromlin], ax
        call    showscreen
        jmp     SHORT @@ret
  @@sjekk_lin_bott:
        mov     ax, [fromlin]
        add     ax, [lpp]
        cmp     ax, [curlin]
        ja      @@ret
    ; Her er X-posisjonen til hõyre for siste skjermkolonne
        mov     ax, [curlin]
        sub     ax, [lpp]
        inc     ax
        mov     [fromlin], ax
        call    showscreen
  @@ret:
        pop     ax
        ret
ENDP    justpos



;
; movetopos
;
; Hva prosedyren gjõr:
;   Flytter til posisjonen som er angitt, og oppdaterer ALT.
;   Hele skjermen tegnes!
;   Posisjonen mÜ eksistere!
;
; Kall med:
;   AX - ùnsket linjenummer
;   BX - ùnsket kolonnenummer
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    movetopos
        mov     [curlin], ax
        mov     [curcol], bx
        call    fetchline
        call    showlinnr
        call    showcolnr
        call    justpos
        call    showscreen
        ret
ENDP    movetopos



;
; movetoposcentre
;
; Hva prosedyren gjõr:
;   Flytter til posisjonen som er angitt, og oppdaterer ALT.
;   fromlin justeres sÜ markõren stÜr omtrent pÜ midterste linje.
;   Hele skjermen tegnes!
;   Posisjonen mÜ eksistere!
;
; Kall med:
;   AX - ùnsket linjenummer
;   BX - ùnsket kolonnenummer
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    movetoposcentre
        push    ax
        push    bx

        call    movetopos

    ; Prõv Ü justere fromlin sÜ markõren havner midt pÜ skjermen.
        mov     ax, [curlin]
        sub     ax, [fromlin]   ; Avstand fra toppen av skjermen

        mov     bx, [lpp]
        shr     bx, 1           ; Halvparten av antall synlige linjer

        sub     ax, bx          ; Differansen fra idealet

    ; Oppdater fromlin
        add     [fromlin], ax
        jns     @@show_screen

    ; fromlin ble negativ. Null ut.
        mov     [fromlin], 0

  @@show_screen:
        call    showscreen

        pop     bx
        pop     ax
        ret
ENDP    movetoposcentre





ENDS

        END
