; ====================================================================
;
; Her f›lger prosedyrer for de forskjellige editeringsfunksjonene.
; De har ingen egen header hvis det ikke er spesielle forbehold som
; m† tas f›r eller etter at de kalles.
;
; Hvis det er n›dvendig, s›rger prosedyrene for † lagre n†v‘rende
; editeringslinje f›r de gj›r det de skal.
; Det kan ogs† tenkes at ny editeringslinje er hentet n†r prosedyrene
; avsluttes.
;
; ====================================================================
;

        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING

INCLUDE "ED.INC"

;--------------------------;
;                          ;
;         D A T A          ;
;                          ;
;--------------------------;

DATASEG

        EXTRN   savepck: BYTE
        EXTRN   blockon: BYTE
        EXTRN   blklin1: WORD, blkcol1: WORD, blklin2: WORD, blkcol2: WORD
        EXTRN   poslin1: WORD, poscol1: WORD, poslin2: WORD, poscol2: WORD
        EXTRN   syslin: WORD, syscol: WORD
        EXTRN   antlin: WORD
        EXTRN   linehd: PTR
        EXTRN   cpl: WORD, lpp: WORD

        EXTRN   doquit: BYTE
        EXTRN   fromlin: WORD, fromcol: WORD, curlin: WORD, curcol: WORD
        EXTRN   numinp: PTR, linlen: WORD, tmplin: PTR
        EXTRN   insert: BYTE, indent: BYTE, pair: BYTE, tabul: BYTE

        PUBLIC  ctrltbl, functbl

; Her f›lger tables for de forskjellige tastetrykkene. Her er adresser
; til prosedyrer som kalles for riktig tastetrykk.
ctrltbl DW      leftwrd , none    , downpage, rightchr, upline  , rightwrd ;A-F
        DW      del     , backspc , tab     , none    , block   , next     ;G-L
        DW      return  , newline , options , prefix  , quick   , uppage   ;M-R
        DW      leftchr , delwrd  , none    , ins     , downscrl, downline ;S-X
        DW      delline , upscrl                                           ;Y-Z

functbl DW      help    , savefile, loadfile, pick    , userscr ; F1-F5
        DW      none    , none    , none    , none    , showid  ; F6-F10


        DW      none    , none                                  ; udefinert

        DW      begline , upline  , uppage  , none    , leftchr ; 71-75
        DW      none    , rightchr, none    , endline , downline; 76-80
        DW      downpage, ins     , del                         ; 81-83

        DW      none    , none    , none    , none    , none    ; Shift F1-F5
        DW      none    , none    , none    , none    , none    ; Shift F6-F10

        DW      none    , none    , none    , none    , none    ; Ctrl F1-F5
        DW      none    , none    , none    , none    , none    ; Ctrl F6-F10

        DW      none    , none    , pick    , mkpick  , userscr ; Alt F1-F5
        DW      none    , none    , none    , none    , none    ; Alt F6-F10

        DW      none    , leftwrd , rightwrd, endpage , endtext ; 114-118
        DW      begpage                                         ; 115

        DW      begtext                                         ; 132


delim   DB      0, 9, " <>,;.:()[]{}^'=*+-/\$#"
LABEL   dlmend  BYTE
DELIMS  EQU     (OFFSET dlmend - OFFSET delim)        ; Antall skilletegn

blank   DB      0, 9, " "
LABEL   blnkend  BYTE
BLANKS  EQU     (OFFSET blnkend - OFFSET blank)       ; Antall blanktegn





CODESEG

;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

        EXTRN   getkey: PROC
        EXTRN   outchar: PROC
        EXTRN   strlen: PROC
        EXTRN   atoui: PROC
        EXTRN   closewindow: PROC

        EXTRN   insertinline: PROC, removefromline: PROC, removeline: PROC
        EXTRN   splitline: PROC, splicelines: PROC

        EXTRN   openscreen: PROC, beep: PROC
        EXTRN   showline: PROC, showscreen: PROC, showcursor: PROC
        EXTRN   showlinnr: PROC, showcolnr: PROC
        EXTRN   showinsert: PROC, showindent: PROC, showchanged: PROC
        EXTRN   showpair: PROC, showfilename: PROC
        EXTRN   showctrl: PROC, unshowctrl: PROC
        EXTRN   help: PROC, showid: PROC

        EXTRN   resetblock: PROC, blockcontract: PROC, blockexpand: PROC
        EXTRN   setupfind: PROC, findtext: PROC, findnext: PROC
        EXTRN   setupreplace: PROC, replacetext: PROC

        EXTRN   savefile: PROC, loadfile: PROC
        EXTRN   saveblock: PROC, loadblock: PROC
        EXTRN   deleteblock: PROC, copyblock: PROC, moveblock: PROC
        EXTRN   indentblock: PROC, unindentblock: PROC
        EXTRN   savepickfile: PROC, choosepick: PROC

        EXTRN   userinput: PROC

        EXTRN   none: PROC, movetopos: PROC, justpos: PROC, setchanged: PROC
        EXTRN   fetchline: PROC, show_info: PROC, showthisline: PROC
        EXTRN   storechar: PROC, movetoposcentre: PROC

        PUBLIC  upscrl, downscrl, leftchr



;
; left_al / right_al
; Flytting av mark›ren "across lines". Flytter selv om mark›ren er
; p† begynnelsen/slutten av linjen, men endrer da til forrige linje.
; Har ingen egen tast, men kalles av andre prosedyrer.
;
; Returnerer:
;   CF : 1 = Flytting foretatt
;        0 = Ingen flytting
;
; OBS!!!
; Disse kaller ikke justpos eller showcolnr   !!!!
;
PROC    left_al
        push    ax
        mov     ax, [curcol]
        or      ax, ax
        je      @@til_forrige
        dec     ax
        mov     [curcol], ax
        stc
        jmp     SHORT @@ret
  @@til_forrige:
        cmp     [curlin], 0
        je      @@ingen_flytting
        call    upline
        call    endline
        stc
        jmp     SHORT @@ret
  @@ingen_flytting:
        clc
  @@ret:
        pop     ax
        ret
ENDP    left_al



PROC    right_al
        push    ax
        mov     ax, [curcol]
        inc     ax
        cmp     ax, [linlen]
        ja      @@til_neste
        mov     [curcol], ax
        stc
        jmp     SHORT @@ret
  @@til_neste:
        push    ax
        mov     ax, [curlin]
        inc     ax
        cmp     ax, [antlin]
        pop     ax
        jae     @@ingen_flytting
        call    downline
        call    begline
        stc
        jmp     SHORT @@ret
  @@ingen_flytting:
        clc
  @@ret:
        pop     ax
        ret
ENDP    right_al



;
; isdelim
; Dette er heller ingen funksjon som kan n†s fra tastaturet. Den brukes
; av leftwrd/rightwrd for † finne ut om et tegn er et skilletegn.
; Tegnet som skal testes m† ligge i AL
;
; Returnerer:
;   ZF = 0 : Ikke skilletegn
;   ZF = 1 : Skilletegn
;
PROC    isdelim
        push    cx
        push    di
        push    es

        push    ds
        pop     es
        mov     di, OFFSET delim
        mov     cx, DELIMS
        cld
        repne   scasb

        pop     es
        pop     di
        pop     cx
        ret
ENDP    isdelim



;
; isblank
; Dette er heller ingen funksjon som kan n†s fra tastaturet. Den brukes
; av doindent for † finne ut om et tegn er en blank.
; Tegnet som skal testes m† ligge i AL
;
; Returnerer:
;   ZF = 0 : Ikke blank
;   ZF = 1 : Blank
;
PROC    isblank
        push    cx
        push    di
        push    es

        push    ds
        pop     es
        mov     di, OFFSET blank
        mov     cx, BLANKS
        cld
        repne   scasb

        pop     es
        pop     di
        pop     cx
        ret
ENDP    isblank



;
; currchr
; Returnerer tegnet mark›ren st†r p†.
; Er mark›ren etter linjeslutt, returneres 0.
; Tegnet returneres i AL.
;
PROC    currchr
        push    si
        xor     al, al
        mov     si, [curcol]
        cmp     si, [linlen]
        jae     @@ret
        mov     al, [BYTE tmplin + si]
  @@ret:
        pop     si
        ret
ENDP    currchr



;
; ctrlcomm
;
; Hva prosedyren gj›r:
;   Brukes av prosedyrene for kontrollkommandoer som best†r av mer enn
;   et tastetrykk. (feks: blokkommandoer, Ctrl-K ...)
;   Det er her mulig † trykke enten bare ›nsket tast, eller Ctrl-›nsket tast.
;   Det som returneres er allikevel koden til ›nsket tast.
;
; Kall med:
;   AL : ASCII-koden til kommandogruppen (feks 'Q' hvis Ctrl-Q)
;
; Returnerer:
;   AL : ASCII-koden til den siste kommandoen (feks 'Y' hvis Ctrl-Q Y)
;        Returnerer alltid stor bokstav
;
; Endrer innholdet i:
;   AL
;
PROC    ctrlcomm
        call    showctrl
        call    getkey
        cmp     al, 1   ; Ctrl-A
        jl      @@ret
        cmp     al, 32
        jg      @@ikke_ctrl
        add     al, 64  ; Gj›r om fra Ctrl-kode til stor ASCII-bokstav
        call    outchar
        jmp     SHORT @@ret
  @@ikke_ctrl:
        cmp     al, 'a'
        jl      @@ikke_liten
        cmp     al, 'z'
        jg      @@ret   ; Ikke bokstav
        sub     al, 'a' - 'A'   ; Gj›r om fra liten bokstav til stor
        call    outchar
        jmp     SHORT @@ret
  @@ikke_liten:
        cmp     al, 'A'
        jl      @@ret
        cmp     al, 'Z'
        jg      @@ret
        call    outchar
  @@ret:
        ret
ENDP    ctrlcomm



;---------------------------------------------------------------------



PROC    leftwrd
        push    ax
  @@forbi_blanke:
        call    left_al
        jnc     @@ret
        call    currchr
        call    isdelim
        je      @@forbi_blanke
  @@forbi_tegn:
        call    left_al
        jnc     @@ret
        call    currchr
        call    isdelim
        jne     @@forbi_tegn
        call    right_al
  @@ret:
        call    justpos
        call    showcolnr
        pop     ax
        ret
ENDP    leftwrd



PROC    rightwrd
        push    ax
        call    currchr
        call    isdelim
        je      @@forbi_blanke
  @@forbi_tegn:
        call    right_al
        jnc     @@ret
        call    currchr
        call    isdelim
        jne     @@forbi_tegn
  @@forbi_blanke:
        call    right_al
        jnc     @@ret
        call    currchr
        call    isdelim
        je      @@forbi_blanke
  @@ret:
        call    justpos
        call    showcolnr
        pop     ax
        ret
ENDP    rightwrd



PROC    leftchr
        push    ax
        mov     ax, [curcol]
        or      ax, ax
        je      @@ret
        dec     ax
        mov     [curcol], ax
        call    justpos
  @@ret:
        call    showcolnr
        pop     ax
        ret
ENDP    leftchr



PROC    rightchr
        push    ax
        mov     ax, [curcol]
        inc     ax
        cmp     ax, MAXLEN
        ja      @@ret
        mov     [curcol], ax
        call    justpos
  @@ret:
        call    showcolnr
        pop     ax
        ret
ENDP    rightchr



PROC    upline
        push    ax
        mov     ax, [curlin]
        or      ax, ax
        je      @@ret
        dec     ax
        mov     [curlin], ax
        call    justpos
  @@ret:
        call    showlinnr
        call    fetchline
        pop     ax
        ret
ENDP    upline



PROC    downline
        push    ax
        mov     ax, [curlin]
        inc     ax
        cmp     ax, [antlin]
        je      @@ret
        mov     [curlin], ax
        call    justpos
  @@ret:
        call    showlinnr
        call    fetchline
        pop     ax
        ret
ENDP    downline



PROC    uppage
        push    ax
        mov     ax, [lpp]
        dec     ax              ; Skal flytte lpp - 1 linjer
        cmp     [fromlin], ax
        jae     @@sub_fromlin_OK
        mov     [WORD fromlin], 0
        jmp     SHORT @@flytt_curlin
  @@sub_fromlin_OK:
        sub     [fromlin], ax
  @@flytt_curlin:
        cmp     [curlin], ax
        jae     @@sub_curlin_OK
        mov     [WORD curlin], 0
        jmp     SHORT @@ret
  @@sub_curlin_OK:
        sub     [curlin], ax
  @@ret:
        call    showlinnr
        call    showscreen
        call    fetchline
        pop     ax
        ret
ENDP    uppage



PROC    downpage
        push    ax
        mov     ax, [lpp]
        dec     ax              ; Skal flytte lpp - 1 linjer
        add     ax, [fromlin]
        mov     [fromlin], ax
        cmp     ax, [antlin]
        jbe     @@flytt_curlin
        mov     ax, [antlin]
        dec     ax
        mov     [fromlin], ax
  @@flytt_curlin:
        mov     ax, [lpp]
        dec     ax              ; Skal flytte lpp - 1 linjer
        add     ax, [curlin]
        mov     [curlin], ax
        cmp     ax, [antlin]
        jbe     @@ret
        mov     ax, [antlin]
        dec     ax
        mov     [curlin], ax
  @@ret:
        call    showlinnr
        call    showscreen
        call    fetchline
        pop     ax
        ret
ENDP    downpage



PROC    upscrl
        push    ax
        push    bx
        mov     bx, [antlin]
        cmp     bx, [lpp]
        jbe     @@ret
        sub     bx, [lpp]
        mov     ax, [fromlin]
        cmp     ax, bx
        jae     @@ret
        inc     ax
        mov     [fromlin], ax
        mov     ax, [curlin]
        cmp     ax, [fromlin]
        jae     @@ret
        inc     ax
        mov     [curlin], ax
  @@ret:
        call    showlinnr
        call    showscreen
        call    fetchline
        pop     bx
        pop     ax
        ret
ENDP    upscrl


PROC    downscrl
        push    ax
        push    bx
        mov     ax, [fromlin]
        or      ax, ax
        je      @@ret
        dec     ax
        mov     [fromlin], ax
        mov     bx, ax
        add     bx, [lpp]
        mov     ax, [curlin]
        cmp     ax, bx
        jb      @@ret
        dec     ax
        mov     [curlin], ax
  @@ret:
        call    showlinnr
        call    showscreen
        call    fetchline
        pop     bx
        pop     ax
        ret
ENDP    downscrl



PROC    del
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    es

    ; Marker teksten som endret
        call    setchanged

    ; Sjekk om mark›ren er bak eller p† linjeslutt. Is†fall skal teksten
    ; p† neste linje trekkes opp.
        mov     bx, [curcol]
        cmp     bx, [linlen]
        jb      @@ikke_trekk_opp

    ; Sjekk om det er noen neste linje
        mov     ax, [curlin]
        inc     ax
        cmp     ax, [antlin]
        jae     @@ret

    ; Trekk opp
        dec     ax
        call    splicelines
        call    fetchline
        call    showscreen
        jmp     SHORT @@ret

    ; Her skal n†v‘rende tegn fjernes.
  @@ikke_trekk_opp:

        mov     ax, [curlin]
        mov     cx, 1
        call    removefromline
        call    fetchline
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
ENDP    del



PROC    backspc
        push    ax
        mov     ax, [curlin]
        call    left_al
        jnc     @@ret
        call    justpos
        call    showcolnr
    ; Hvis linjenummeret er endret, skal del helt sikkert kalles.
        cmp     ax, [curlin]
        jne     @@do_del
    ; Hvis mark›ren er bak linjeslutt, skal ikke del kalles.
    ; Da ville is†fall neste linje trekkes opp, og det skal den ikke
    ; under bruk av backspace.
        mov     ax, [curcol]
        cmp     ax, [linlen]
        jae     @@ret
  @@do_del:
        call    del
  @@ret:
        pop     ax
        ret
ENDP    backspc



PROC    delwrd
        push    ax

    ; Sjekk f›rst om mark›ren er etter linjeslutt. Da skal neste
    ; linje trekkes opp.
        call    currchr
        or      al, al
        jnz     @@start_del

        call    del
        jmp     SHORT @@ret

  @@start_del:
    ; Hvis mark›ren st†r p† en delimiter som ikke er blank, skal
    ; bare denne slettes.
        call    currchr
        call    isdelim
        jne     @@del_notdelim
        call    isblank
        je      @@del_notdelim
        call    del
        jmp     SHORT @@ret

  @@del_notdelim:
    ; Slett s† lenge ikke delimiter
        call    currchr
        call    isdelim
        je      @@del_blank
        call    del
        jmp     @@del_notdelim

  @@del_blank:
    ; Slett s† lenge blank
        call    currchr
    ; Sjekk om tegnet som evt skal fjernes er linjeslutt.
    ; Dette skal ikke fjernes med mindre det var det f›rste som skulle
    ; fjernes. (hm!)
        or      al, al
        jz      @@ret
        call    isblank
        jne     @@ret
        call    del
        jmp     @@del_blank

  @@ret:
        pop     ax
        ret
ENDP    delwrd



PROC    delline
        push    ax

        call    setchanged

        mov     ax, [curlin]
        call    removeline
    ; Hvis mark›ren st†r p† siste linje, m† ikke antall linjer endres.
    ; Da vil jo is†fall mark›ren st† bak filen.
        cmp     ax, [antlin]
        jb      @@ikke_siste
        inc     [antlin]
  @@ikke_siste:
        call    showscreen
        call    fetchline
        call    begline

        pop     ax
        ret
ENDP    delline



PROC    deleol
        push    ax
        push    bx
        push    cx

    ; Marker teksten som endret
        call    setchanged

    ; Sjekk om mark›ren er f›r linjeslutt. Hvis ikke, skal ingenting gj›res.
        mov     ax, [curlin]
        mov     bx, [curcol]
        mov     cx, [linlen]
        cmp     bx, cx
        jae     @@ret

        sub     cx, bx
        call    removefromline
        call    fetchline
        call    showthisline

  @@ret:
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    deleol



PROC    newline
        push    ax
        push    bx

    ; Marker teksten som endret
        call    setchanged

        mov     ax, [curlin]
        mov     bx, [curcol]
        call    splitline
        call    fetchline
        call    showscreen

        pop     bx
        pop     ax
        ret
ENDP    newline


;
; doindent er ikke en egen tastefunksjon, men kalles av et par andre
; funksjoner hvis indent er p†.
;
; Kalles med:
;   AL = 0 : Utf›r uten begrensning
;   AL = 1 : Ikke utf›r indent hvis curcol=0 og f›rste tegn p† styrelinjen
;            ikke er blank. Brukes n†r indent utf›res etter at Return
;            er trykket.
;
PROC    doindent
        push    ax
        push    bx
        push    cx
        push    dx
        push    bp
        mov     dl, al
        xor     cx, cx  ; Bruk CX som teller
        mov     ax, [curlin]
        mov     bp, ax  ; Spar n†v‘rende linjenummer i BP
        mov     bx, [curcol]
    ; Finn en tidligere linje som er lenger enn n†v‘rende
  @@forrige_linje:
        sub     ax, 1   ; Bruker SUB siden DEC ikke setter Carry-flag
        jc      @@ret
        mov     [curlin], ax
        call    fetchline
        cmp     [linlen], bx
        jbe     @@forrige_linje

    ; Tell opp antall tegn som skal flyttes
        call    currchr
        call    isblank
        je      @@forbi_blanke
        or      dl, dl
        jz      @@forbi_tegn
        cmp     [curcol], 0
        je      @@ret
  @@forbi_tegn:
        call    right_al
        jnc     @@ret
        inc     cx
        call    currchr
        call    isblank
        jne     @@forbi_tegn
  @@forbi_blanke:
        or      al, al
        jz      @@ret
        call    right_al
        jnc     @@ret
        inc     cx
        call    currchr
        call    isblank
        je      @@forbi_blanke

    ; Hent tilbake n†v‘rende linje og sett tilbake curcol
  @@ret:
        mov     ax, bp  ; Hent tilbake n†v‘rende linjenummer
        mov     [curlin], ax
        call    fetchline
        mov     [curcol], bx
    ; Flytt riktig antall plasser til h›yre, eller sett inn riktig antall
    ; blanke avhengig av om innsett er av eller p†
        jcxz    @@ingen_flytting
        cmp     [insert], 0
        je      @@flytt_til_hoyre
  @@sett_inn_blanke:
        mov     al, ' '
        call    storechar
        loop    @@sett_inn_blanke
        jmp     SHORT @@ingen_flytting
  @@flytt_til_hoyre:
        call    rightchr
        loop    @@flytt_til_hoyre
  @@ingen_flytting:
        call    justpos
        call    showcolnr
        pop     bp
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    doindent



PROC    dotab
        ret
ENDP    dotab



PROC    return
        push    ax

    ; Hvis vi er p† siste linje, skal newline utf›res uansett om
    ; innsett er av eller p†.
        mov     ax, [curlin]
        inc     ax
        cmp     ax, [antlin]
        je      @@newline

        cmp     [insert], 0
        jz      @@ikke_newline

  @@newline:
        mov     al, 1   ; Flagg: Anta at indent skal utf›res
        cmp     [curcol], 0
        jne     @@indent_skal_utfores
        xor     al, al  ; Flagg: Indent skal ikke utf›res
  @@indent_skal_utfores:
        call    newline
  @@ikke_newline:
        call    downline
        call    begline
    ; Sjekk om indent skal utf›res
        or      al, al
        jz      @@ret
        cmp     [indent], 0
        je      @@ret
        mov     al, 1
        call    doindent
  @@ret:
        pop     ax
        ret
ENDP    return



PROC    tab
        push    ax
        cmp     [tabul], 0
        je      @@indent
        call    dotab
        jmp     SHORT @@ret
  @@indent:
        xor     al, al
        call    doindent
  @@ret:
        pop     ax
        ret
ENDP    tab



PROC    ins
        xor     [insert], 1
        call    showinsert
        ret
ENDP    ins



PROC    begline
        push    ax
        xor     ax, ax
        mov     [curcol], ax
        call    justpos
        call    showcolnr
        pop     ax
        ret
ENDP    begline



PROC    endline
        push    ax
        mov     ax, [linlen]
        mov     [curcol], ax
        call    justpos
        call    showcolnr
        pop     ax
        ret
ENDP    endline



PROC    begpage
        push    ax
        mov     ax, [fromlin]
        mov     [curlin], ax
        call    fetchline
        call    showlinnr
        pop     ax
        ret
ENDP    begpage



PROC    endpage
        push    ax
        mov     ax, [fromlin]
        add     ax, [lpp]
        cmp     ax, [antlin]
        jbe     @@set_curlin
        mov     ax, [antlin]
  @@set_curlin:
        dec     ax
        mov     [curlin], ax
        call    fetchline
        call    showlinnr
        pop     ax
        ret
ENDP    endpage



PROC    begtext
        push    ax
        push    bx

        xor     ax, ax
        xor     bx, bx
        call    movetopos

        pop     bx
        pop     ax
        ret
ENDP    begtext



PROC    endtext
        push    ax
        mov     ax, [antlin]
        or      ax, ax
        je      @@no_lines
        dec     ax
  @@no_lines:
        mov     [curlin], ax
        call    justpos
        call    fetchline
        call    endline
        call    showlinnr
        pop     ax
        ret
ENDP    endtext



PROC    find
        push    ax
        push    bx

        call    setupfind
        jc      @@ret

        call    findtext
        jnc     @@funnet
    ; Teksten er ikke funnet. Lag pipetone.
        call    beep
        jmp     SHORT @@ret

  @@funnet:
        call    movetoposcentre

  @@ret:
        pop     bx
        pop     ax
        ret
ENDP    find



PROC    replace
        push    ax
        push    bx

        call    setupreplace
        jc      @@ret

        call    replacetext
        jnc     @@funnet
    ; Teksten er ikke funnet. Lag pipetone.
        call    beep
        jmp     SHORT @@ret

  @@funnet:
        call    movetoposcentre

  @@ret:
        pop     bx
        pop     ax
        ret
ENDP    replace



PROC    next
        push    ax

        call    findnext
        jnc     @@funnet
    ; Teksten er ikke funnet. Lag pipetone
        call    beep
        jmp     SHORT @@ret

  @@funnet:
        call    movetoposcentre

  @@ret:
        pop     ax
        ret
ENDP    next



PROC    prefix
        push    ax

        mov     al, 'P'
        call    ctrlcomm

        cmp     al, 'A'
        jb      @@ret
        cmp     al, 'A' + 30
        ja      @@ret

        sub     al, 'A' - 1
        call    storechar

  @@ret:
        call    unshowctrl
        pop     ax
        ret
ENDP    prefix



PROC    setposmrk
        push    bx
        push    cx

        mov     bx, [curlin]
        mov     cx, [curcol]

        cmp     al, '1'
        jne     @@set_mark_2

        mov     [poslin1], bx
        mov     [poscol1], cx
        jmp     SHORT @@ret

  @@set_mark_2:
        mov     [poslin2], bx
        mov     [poscol2], cx

  @@ret:
        pop     cx
        pop     bx
        ret
        ret
ENDP    setposmrk



PROC    findposmrk
        push    ax
        push    bx
        push    cx

    ; Anta f›rste
        mov     cx, [poslin1]
        mov     bx, [poscol1]

        cmp     al, '1'
        je      @@goto_pos

        mov     cx, [poslin2]
        mov     bx, [poscol2]

  @@goto_pos:
        mov     ax, cx
        call    movetoposcentre

        pop     cx
        pop     bx
        pop     ax
        ret
        ret
ENDP    findposmrk



PROC    blkstrt
        push    ax
        mov     ax, [curcol]
        cmp     ax, [linlen]
        jb      @@col_ok
        mov     ax, [linlen]
  @@col_ok:
        mov     [blkcol1], ax
        mov     ax, [curlin]
        mov     [blklin1], ax
        mov     [blockon], 1
        call    showscreen
        pop     ax
        ret
ENDP    blkstrt



PROC    blkend
        push    ax
        mov     ax, [curcol]
        cmp     ax, [linlen]
        jb      @@col_ok
        mov     ax, [linlen]
  @@col_ok:
        mov     [blkcol2], ax
        mov     ax, [curlin]
        mov     [blklin2], ax
        mov     [blockon], 1
        call    showscreen
        pop     ax
        ret
ENDP    blkend



PROC    mvblkstrt
        push    ax
        push    bx

        cmp     [blockon], 0
        jz      @@ret

        mov     ax, [blklin1]
        mov     bx, [blkcol1]
        call    movetoposcentre

  @@ret:
        pop     bx
        pop     ax
        ret
ENDP    mvblkstrt



PROC    mvblkend
        push    ax
        push    bx

        cmp     [blockon], 0
        jz      @@ret

        mov     ax, [blklin2]
        mov     bx, [blkcol2]
        call    movetoposcentre

  @@ret:
        pop     bx
        pop     ax
        ret
ENDP    mvblkend



PROC    blkhide
        xor     [blockon], 1
        call    showscreen
        ret
ENDP    blkhide



PROC    dodeleteblock
        push    ax
        push    bx

    ; Marker teksten som endret
        call    setchanged

    ; S›rg for at mark›rposisjonen oppdateres
        mov     ax, [curlin]
        mov     [syslin], ax
        mov     ax, [curcol]
        mov     [syscol], ax
        call    deleteblock
        mov     ax, [syslin]
        mov     bx, [syscol]
        call    movetopos

        pop     bx
        pop     ax
        ret
ENDP    dodeleteblock



PROC    docopyblock
        push    ax
        push    bx

    ; Marker teksten som endret
        call    setchanged

    ; Ikke n›dvendig † s›rge for at mark›rposisjonen oppdateres
        mov     ax, [curlin]
        mov     bx, [curcol]
        call    copyblock
        call    fetchline
        call    showscreen

        pop     bx
        pop     ax
        ret
ENDP    docopyblock



PROC    domoveblock
        push    ax
        push    bx

    ; Marker teksten som endret
        call    setchanged

    ; S›rg for at mark›rposisjonen oppdateres
        mov     ax, [curlin]
        mov     [syslin], ax
        mov     bx, [curcol]
        mov     [syscol], bx
        call    moveblock
        mov     ax, [syslin]
        mov     bx, [syscol]
        call    movetopos

        pop     bx
        pop     ax
        ret
ENDP    domoveblock



PROC    doindentblock
        push    ax
        push    bx

    ; Marker teksten som endret
        call    setchanged

    ; S›rg for at mark›rposisjonen oppdateres
        mov     ax, [curlin]
        mov     [syslin], ax
        mov     bx, [curcol]
        mov     [syscol], bx
        call    indentblock
        mov     ax, [syslin]
        mov     bx, [syscol]
        call    movetopos

        pop     bx
        pop     ax
        ret
ENDP    doindentblock



PROC    dounindentblock
        push    ax
        push    bx

    ; Marker teksten som endret
        call    setchanged

    ; S›rg for at mark›rposisjonen oppdateres
        mov     ax, [curlin]
        mov     [syslin], ax
        mov     bx, [curcol]
        mov     [syscol], bx
        call    unindentblock
        mov     ax, [syslin]
        mov     bx, [syscol]
        call    movetopos

        pop     bx
        pop     ax
        ret
ENDP    dounindentblock



PROC    doloadblock
        push    ax
        push    bx

    ; Ikke n›dvendig † s›rge for at mark›rposisjonen oppdateres
        mov     ax, [curlin]
        mov     bx, [curcol]
        call    loadblock

    ; Sjekk om avbrutt av bruker. Is†fall skal ikke teksten markeres som
    ; endret, og det er heller ikke n›dvendig † oppdatere skjermen.
        jc      @@ret

    ; Blokk er lest fra fil.
        call    fetchline
        call    showscreen

    ; Marker teksten som endret
        call    setchanged

  @@ret:
        pop     bx
        pop     ax
        ret
ENDP    doloadblock



PROC    gotoline
        push    ax
        push    bx
        push    dx
        push    si

    ; Be bruker oppgi linjenummer det skal flyttes til
        mov     ax, 5
        mov     bx, 5
        mov     dx, OFFSET linehd
        mov     si, OFFSET numinp
        mov     [BYTE si], 0
        call    userinput
        jc      @@ret

    ; Gj›r om nummeret til et tall
        mov     dx, OFFSET numinp
        call    atoui
        or      ax, ax
        jz      @@ret
        dec     ax

    ; Sjekk om gyldig linjenummer
        cmp     ax, [antlin]
        jb      @@move

    ; Lag pipetone og avslutt
        call    beep
        jmp     SHORT @@ret

  @@move:
    ; Flytt til linjen, med samme kolonne som n†.
        mov     bx, [curcol]
        call    movetoposcentre

  @@ret:
        pop     si
        pop     dx
        pop     bx
        pop     ax
        ret
ENDP    gotoline



PROC    pick
        call    choosepick
        ret
ENDP    pick



PROC    mkpick
        mov     [savepck], 1
        call    savepickfile
        ret
ENDP    mkpick



PROC    userscr
        push    ax

    ; Lukk vinduet. Dette g†r bra, for n†r denne kalles, er det bare
    ; et vindu som er †pent, nemlig selve editoren.
        call    closewindow

    ; Vent til brukeren trykker en tast
        call    getkey
        cmp     ax, QUITKEY
        jne     @@dont_quit

    ; Tasten var Alt-X. Marker dette
        mov     [doquit], 1

  @@dont_quit:
    ; Vis editoren igjen.
        call    openscreen
        call    show_info

        pop     ax
        ret
ENDP    userscr



PROC    block
        push    ax
        mov     al, 'K'
        call    ctrlcomm
        cmp     al, 'B'
        jne     @@ikke_B
        call    blkstrt
        jmp     SHORT @@ret
  @@ikke_B:
        cmp     al, 'K'
        jne     @@ikke_K
        call    blkend
        jmp     SHORT @@ret
  @@ikke_K:
        cmp     al, 'H'
        jne     @@ikke_H
        call    blkhide
        jmp     SHORT @@ret
  @@ikke_H:
        cmp     al, '1'
        jne     @@ikke_1
        call    setposmrk
        jmp     SHORT @@ret
  @@ikke_1:
        cmp     al, '2'
        jne     @@ikke_2
        call    setposmrk
        jmp     SHORT @@ret
  @@ikke_2:
        cmp     al, 'Y'
        jne     @@ikke_Y
        call    dodeleteblock
        jmp     SHORT @@ret
  @@ikke_Y:
        cmp     al, 'C'
        jne     @@ikke_C
        call    docopyblock
        jmp     SHORT @@ret
  @@ikke_C:
        cmp     al, 'V'
        jne     @@ikke_V
        call    domoveblock
        jmp     SHORT @@ret
  @@ikke_V:
        cmp     al, 'W'
        jne     @@ikke_W
        call    saveblock
        jmp     SHORT @@ret
  @@ikke_W:
        cmp     al, 'R'
        jne     @@ikke_R
        call    doloadblock
        jmp     SHORT @@ret
  @@ikke_R:
        cmp     al, 'I'
        jne     @@ikke_I
        call    doindentblock
        jmp     SHORT @@ret
  @@ikke_I:
        cmp     al, 'U'
        jne     @@ikke_U
        call    dounindentblock
        jmp     SHORT @@ret
  @@ikke_U:

  @@ret:
        call    unshowctrl
        pop     ax
        ret
        ret
ENDP    block



PROC    quick
        push    ax
        mov     al, 'Q'
        call    ctrlcomm
        cmp     al, 'Y'
        jne     @@ikke_Y
        call    deleol
        jmp     SHORT @@ret
  @@ikke_Y:
        cmp     al, 'B'
        jne     @@ikke_B
        call    mvblkstrt
        jmp     SHORT @@ret
  @@ikke_B:
        cmp     al, 'K'
        jne     @@ikke_K
        call    mvblkend
        jmp     SHORT @@ret
  @@ikke_K:
        cmp     al, '1'
        jne     @@ikke_1
        call    findposmrk
        jmp     SHORT @@ret
  @@ikke_1:
        cmp     al, '2'
        jne     @@ikke_2
        call    findposmrk
        jmp     SHORT @@ret
  @@ikke_2:
        cmp     al, 'F'
        jne     @@ikke_F
        call    find
        jmp     SHORT @@ret
  @@ikke_F:
        cmp     al, 'A'
        jne     @@ikke_A
        call    replace
        jmp     SHORT @@ret
  @@ikke_A:
        cmp     al, 'G'
        jne     @@ikke_G
        call    gotoline
        jmp     SHORT @@ret
  @@ikke_G:

  @@ret:
        call    unshowctrl
        pop     ax
        ret
ENDP    quick



PROC    options
        push    ax
        mov     al, 'O'
        call    ctrlcomm
        cmp     al, 'I'
        jne     @@ikke_I
        xor     [indent], 1
        call    showindent
        jmp     SHORT @@ret
  @@ikke_I:
        cmp     al, 'P'
        jne     @@ikke_P
        xor     [pair], 1
        call    showpair
        jmp     SHORT @@ret
  @@ikke_P:

  @@ret:
        call    unshowctrl
        pop     ax
        ret
ENDP    options





ENDS

        END
