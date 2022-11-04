;
; Denne filen inneholder forel�pig bare en enkel utgave av s�king
; etter tekst. Senere skal det (forh�pentligvis) fylles opp med
; s�k/erstatt, options osv.
;
; F�lgende options skal v�re med (de med * er ferdige):
;
;   S�king:
;      B - Backwards. Fra n�v�rende posisjon og bakover i teksten.
;    * G - Global. Fra starten av filen, og stopper ikke f�r siste forekomst.
;      L - Local. S�ker i evt. markert blokk etter neste forekomst.
;      U - Skiller ikke mellom upper/lower-case.
;      W - Sjekker bare hele ord.
;
;   S�k/erstatt: (som under s�k, men i tillegg)
;    * N - Noresponse. Erstatt uten sp�rsm�l.
;      L - Local. Erstatt ALLE i blokken fra mark�ren.
;

        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @code, es: NOTHING


INCLUDE "ED.INC"


;--------------------------;
;                          ;
;         D A T A          ;
;                          ;
;--------------------------;

UDATASEG

        EXTRN   findhd: PTR, replhd: PTR, opthd: PROC, replc: PTR
        EXTRN   opterr: PROC
        EXTRN   mtattr: BYTE, mrattr: BYTE
        EXTRN   antlin: WORD
        EXTRN   curlin: WORD, curcol: WORD, fromlin: WORD
        EXTRN   wrklin: PTR, wrklen: WORD



replace DB      ?       ; Er det s�k og erstatt?
glob    DB      ?       ; Skal global s�king foretas
block   DB      ?       ; S�k kun i markert tekst (blokk)
back    DB      ?       ; Skal det s�kes bakover?
nocase  DB      ?       ; S�k uavhengig av case?
words   DB      ?       ; S�k kun etter hele ord?
dontask DB      ?       ; Skal ikke utbytting bekreftes?
findlin DW      ?       ; Linjen det skal s�kes fra
findcol DW      ?       ; Kolonnen det skal s�kes fra
lastlin DW      ?       ; Siste linje med match
lastcol DW      ?       ; Siste kolonne med match
key     DW      ?       ; Innlest tast fra bruker
curspos DW      ?       ; Midlertidig mark�rposisjon
matches DW      ?       ; Antall forekomster funnet i denne runden

  ; Teksten som skal s�kes etter
findtxt DB      (FINDLEN + 1) DUP (?)

  ; Teksten som skal settes inn
repltxt DB      (FINDLEN + 1) DUP (?)

  ; Opsjonsstrengen
optstr  DB      11 DUP (?)





;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        EXTRN   strlen: PROC, strstr: PROC, strupr: PROC
        EXTRN   outchar: PROC, outtext: PROC
        EXTRN   openwindow: PROC, closewindow: PROC
        EXTRN   window: PROC, screencols: PROC, screenrows: PROC
        EXTRN   wherex: PROC, wherey: PROC, gotoxy: PROC
        EXTRN   CHOICE: PROC

        EXTRN   removefromline: PROC, insertinline: PROC
        EXTRN   userinput: PROC, error: PROC
        EXTRN   getwrklin: PROC
        EXTRN   movetoposcentre: PROC, setchanged: PROC, showcursor: PROC

        PUBLIC  initfind, endfind
        PUBLIC  setupfind, findtext
        PUBLIC  setupreplace, replacetext
        PUBLIC  findnext



;
; initfind
;
; Hva prosedyren gj�r:
;   Initierer alt som har med s�king etter tekst � gj�re
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
PROC    initfind
        push    ax

        xor     ax, ax
        mov     [findtxt], al
        mov     [repltxt], al
        mov     [optstr], al

        pop     ax
        ret
ENDP    initfind



;
; endfind
;
; Hva prosedyren gj�r:
;   Avslutter alt som har med s�king � gj�re
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
PROC    endfind
        ret
ENDP    endfind



;
; getoptions
;
; Hva prosedyren gj�r:
;   Ber bruker om opsjoner, og setter opp variabler i henhold til disse.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Carry : clear - Ikke avbrutt av bruker, og ikke feil.
;           set   - Avbrutt, eller feil input.
;
; Endrer innholdet i:
;   Ingenting
;
PROC    getoptions
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    si

    ; Les inn opsjonsstrengen fra bruker.
        mov     ax, 10
        mov     bx, ax
        mov     dx, OFFSET opthd
        mov     si, OFFSET optstr
        call    userinput
        jc      @@ret

    ; Oversett til store bokstaver
        mov     dx, si
        call    strupr

  @@still_more:
    ; Tolk neste tegn i strengen
        cld
        lodsb

    ; Sjekk om slutten p� strengen er n�dd.
        or      al, al
        jz      @@ret_ok

        cmp     al, 'N'
        jne     @@not_N
        mov     [dontask], 1
        jmp     @@still_more

  @@not_N:
        cmp     al, 'G'
        jne     @@not_G
        mov     [glob], 1
        xor     ax, ax
        mov     [findlin], ax
        mov     [findcol], ax
        jmp     @@still_more

  @@not_G:

    ; Ukjent opsjon er angitt. Vis feilmelding.
        mov     dx, OFFSET opterr
        call    error

  @@ret_err:
    ; Noe er galt. Returner med Carry set.
        stc
        jmp     SHORT @@ret

  @@ret_ok:
    ; Alt er ok. Returner med Carry clear.
        clc

  @@ret:
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    getoptions



;
; setupfind
;
; Hva prosedyren gj�r:
;   Ber bruker om tekst som skal s�kes etter.
;   Senere skal det ogs� bes om options.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Carry : clear - Ikke avbrutt av bruker
;           set   - Avbrutt, tom linje angitt, eller feil i options.
;
; Endrer innholdet i:
;   Ingenting
;
PROC    setupfind
        push    ax
        push    bx
        push    dx
        push    si

    ; Nullstill opsjoner til default
        xor     ax, ax
        mov     [replace], al   ; Dette er bare s�k, ikke s�k og erstatt.
        mov     [glob], al
        mov     [block], al
        mov     [back], al
        mov     [nocase], al
        mov     [words], al
        mov     [dontask], al

    ; Les inn linjen som skal s�kes etter.
        mov     ax, FINDLEN
        mov     bx, ax
        mov     dx, OFFSET findhd
        mov     si, OFFSET findtxt
        call    userinput
        jc      @@ret

    ; Sjekk om linjen er tom, og returner is�fall med Carry satt.
        mov     dx, si
        call    strlen
        or      ax, ax
        jnz     @@ikke_tom
        stc
        jmp     SHORT @@ret

  @@ikke_tom:
    ; Sett startvariabler til n�v�rende mark�rposisjon.
        mov     ax, [curlin]
        mov     [findlin], ax
        mov     ax, [curcol]
        mov     [findcol], ax

    ; Sp�r etter options, og tolk disse.
        call    getoptions

  @@ret:
        pop     si
        pop     dx
        pop     bx
        pop     ax
        ret
ENDP    setupfind



;
; findtext
;
; Hva prosedyren gj�r:
;   Leter etter tekst if�lge variabler som er satt opp med setupfind.
;   S�ker fra (findlin, findcol) og ut dokumentet.
;   Oppdaterer posisjonen i (findlin, findcol) slik at den
;   peker etter teksten.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Carry : clear - teksten ble funnet
;           set   - teksten ble ikke funnet  (lager pipetone)
;   AX : Linjenummeret
;   BX : Kolonnenummeret
;
; Endrer innholdet i:
;   AX, BX
;
PROC    findtext
        push    cx
        push    dx
        push    di
        push    si
        push    es

        push    ds
        pop     es

    ; Sett opp diverse variabler
        mov     [matches], 0
        mov     ax, [curlin]
        mov     [lastlin], ax
        mov     ax, [curcol]
        mov     [lastcol], ax

    ; Sjekk om s�ketekst er angitt
        mov     si, OFFSET findtxt
        cmp     [BYTE si], 0
        jz      @@ret

        mov     ax, [findlin]
        mov     bx, [findcol]

  @@let_i_linje:
    ; Sjekk om angitt linje eksisterer.
        cmp     ax, [antlin]
        jae     @@ret

    ; Hent inn linjen
        call    getwrklin
        mov     di, OFFSET wrklin

    ; Sjekk om angitt kolonne eksisterer
        cmp     bx, [wrklen]
        jae     @@neste_linje
        add     di, bx

    ; Let i linjen
        push    ax
        call    strstr
        mov     cx, ax
        pop     ax
        jcxz    @@neste_linje

    ; Teksten er funnet. Oppdater telleren.
        inc     [matches]

    ; Finn ut hvilken kolonne den slutter i.
        mov     bx, cx
        sub     bx, OFFSET wrklin       ; Finner offset fra linjestart
        push    ax
        mov     dx, OFFSET findtxt
        call    strlen
        add     bx, ax          ; Legger til s�ketekstens lengde
        pop     ax

    ; Lagre funnet posisjon
        mov     [findcol], bx

        mov     [lastlin], ax
        mov     [lastcol], bx

    ; Sjekk om muligens globalt. Hopp is�fall til neste.
        cmp     [glob], 0
        jnz     @@let_i_linje

  @@not_global:

        jmp     SHORT @@ret

  @@neste_linje:
    ; Oppdatere pekere til neste linje. Kolonnen nullstilles, for det er
    ; bare f�rste gang ikke hele linjen skal regnes med.
        inc     ax
        mov     [findlin], ax
        xor     bx, bx
        mov     [findcol], bx
        jmp     @@let_i_linje

  @@ret:
    ; Sjekk om noen er funnet, og sett opp Carry flag etter dette.
        cmp     [matches], 0
        jnz     @@ret_found

    ; Teksten er ikke funnet. Marker dette.
        stc
        jmp     SHORT @@final_ret

  @@ret_found:
    ; Marker at teksten er funnet.
        clc

  @@final_ret:
    ; S�rg for � returnere siste funnet posisjon.
        mov     ax, [lastlin]
        mov     bx, [lastcol]

        pop     es
        pop     si
        pop     di
        pop     dx
        pop     cx
        ret
ENDP    findtext



;
; setupreplace
;
; Hva prosedyren gj�r:
;   Ber bruker om tekst som skal s�kes etter, og tekst som skal erstatte denne.
;   Senere skal det ogs� bes om options.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Carry : clear - Ikke avbrutt av bruker
;           set   - Avbrutt, tom linje angitt, eller feil i options.
;
; Endrer innholdet i:
;   Ingenting
;
PROC    setupreplace
        push    ax
        push    bx
        push    dx
        push    si

    ; Nullstill opsjoner til default
        xor     ax, ax
        mov     [replace], 1    ; Dette er s�k og erstatt.
        mov     [glob], al
        mov     [block], al
        mov     [back], al
        mov     [nocase], al
        mov     [words], al
        mov     [dontask], al

    ; Les inn linjen som skal s�kes etter.
        mov     ax, FINDLEN
        mov     bx, ax
        mov     dx, OFFSET findhd
        mov     si, OFFSET findtxt
        call    userinput
        jc      @@ret

    ; Sjekk om linjen er tom, og returner is�fall med Carry satt.
        mov     dx, si
        call    strlen
        or      ax, ax
        jnz     @@ikke_tom
        stc
        jmp     SHORT @@ret

  @@ikke_tom:
    ; Les inn linjen som skal erstatte angitt tekst.
        mov     ax, FINDLEN
        mov     bx, ax
        mov     dx, OFFSET replhd
        mov     si, OFFSET repltxt
        call    userinput
        jc      @@ret

    ; Sett startvariabler til n�v�rende mark�rposisjon.
        mov     ax, [curlin]
        mov     [findlin], ax
        mov     ax, [curcol]
        mov     [findcol], ax

    ; Sp�r etter options, og tolk disse.
        call    getoptions

  @@ret:
        pop     si
        pop     dx
        pop     bx
        pop     ax
        ret
ENDP    setupreplace



;
; replacetext
;
; Hva prosedyren gj�r:
;   Leter etter tekst if�lge variabler som er satt opp med setupreplace.
;   S�ker fra (findlin, findcol) og ut dokumentet.
;   Oppdaterer posisjonen i (findlin, findcol) slik at den
;   peker etter teksten.
;   N�r teksten er funnet, erstattes den med angitt erstattekst.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Carry : clear - teksten ble funnet
;           set   - teksten ble ikke funnet
;   AX : Linjenummeret
;   BX : Kolonnenummeret
;
; Endrer innholdet i:
;   AX, BX
;
PROC    replacetext
        push    cx
        push    dx
        push    di
        push    si
        push    es

        push    ds
        pop     es

    ; Sett opp diverse variabler
        mov     [matches], 0
        mov     ax, [curlin]
        mov     [lastlin], ax
        mov     ax, [curcol]
        mov     [lastcol], ax

    ; Sjekk om s�ketekst er angitt
        mov     si, OFFSET findtxt
        cmp     [BYTE si], 0
        jnz     @@tekst_angitt

  @@jmp_ikke_funnet:
        jmp      @@ret

  @@tekst_angitt:
        mov     ax, [findlin]
        mov     bx, [findcol]

  @@let_i_linje:
    ; Sjekk om angitt linje eksisterer.
        cmp     ax, [antlin]
        jae     @@jmp_ikke_funnet

    ; Hent inn linjen
        call    getwrklin
        mov     di, OFFSET wrklin

    ; Sjekk om angitt kolonne eksisterer
        cmp     bx, [wrklen]
        jb      @@kol_eksisterer

  @@jmp_neste_linje:
        jmp     @@neste_linje

  @@kol_eksisterer:
        add     di, bx

    ; Let i linjen
        push    ax
        call    strstr
        mov     cx, ax
        pop     ax
        jcxz    @@jmp_neste_linje

    ; Teksten er funnet. �k telleren
        inc     [matches]

    ; Finn ut hvilken kolonne den starter i.
        mov     bx, cx
        sub     bx, OFFSET wrklin       ; Finner offset fra linjestart

    ; Finn lengden p� s�keteksten. Lagre denne i CX.
        push    ax
        mov     dx, OFFSET findtxt
        call    strlen
        mov     cx, ax
        pop     ax

    ; Hvis brukeren skal bekrefte byttingen, skal mark�ren plasseres
    ; etter teksten som ble funnet.
        cmp     [dontask], 0
        jz      @@ask_user
        jmp     @@do_not_ask

  @@ask_user:
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    si

    ; Plasser mark�ren etter funnet tekst.
        add     bx, cx
        call    movetoposcentre

    ; Viktig at mark�ren flyttes.
        call    showcursor

    ; Lagre denne posisjonen, i tilfelle avbrutt av bruker.
        mov     [findlin], ax
        mov     [findcol], bx
        mov     [lastlin], ax
        mov     [lastcol], bx

    ; Finn n�v�rende mark�rposisjon, slik at denne kan settes
    ; tilbake etterp�.
        push    ax
        call    wherex
        call    wherey
        mov     [curspos], ax
        pop     ax

    ; �pne et spesialvindu hvor brukeren sp�rres om
    ; teksten skal byttes. Mark�ren plasseres UTENFOR
    ; vinduet, etter teksten som ble funnet.
    ; Vinduet plasseres p� vanlig messageposisjon, med
    ; mindre den endrede teksten er p� en av linjene som
    ; da blir overdekket.

    ; Beregn skjermlinjen til funnet tekst.
        sub     ax, [fromlin]
        inc     ax
        mov     cx, ax

    ; Sett opp normale vinduskoordinater
        mov     dx, OFFSET replc
        call    strlen

        mov     dx, 0806h

        add     dl, al
        mov     ax, 0603h

    ; Sjekk om denne linjen er <= nederste vinduslinje,
    ; is�fall m� vinduet flyttes ned.
        cmp     cl, dh
        ja      @@winpos_ok

        add     ah, 3
        add     dh, 3

  @@winpos_ok:
    ; Gj�r resten av vindus�pningen.
        mov     bl, 1
        mov     cl, [mtattr]
        mov     ch, [mrattr]
        call    openwindow
        mov     al, ' '
        call    outchar
        mov     dx, OFFSET replc
        call    outtext

    ; Gj�r hele skjermen til window, slik at mark�ren kan plasseres
    ; ved funnet tekst.
        call    screencols
        dec     al
        mov     dl, al
        call    screenrows
        dec     al
        mov     dh, al
        xor     ax, ax
        call    window

    ; Plasser mark�ren der den skal v�re.
        mov     ax, [curspos]
        call    gotoxy

    ; Les inn svar fra bruker.
        call    CHOICE
        mov     [key], ax

    ; Lukk vinduet
        call    closewindow

        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax

    ; Sjekk hva brukeren svarte.
        cmp     [key], 27
        je      @@ret

        cmp     [key], 'Y'
        jne     @@finished_this_one

  @@do_not_ask:
    ; Fjern teksten fra linjen
        call    removefromline

    ; Sett inn den nye teksten
        mov     di, OFFSET repltxt
        call    insertinline
        jc      @@ret

    ; Finn slutten p� den nye teksten
        push    ax
        mov     dx, OFFSET repltxt
        call    strlen
        add     bx, ax
        pop     ax

    ; Lagre funnet posisjon
        mov     [findcol], bx

        mov     [lastlin], ax
        mov     [lastcol], bx

    ; Marker at teksten er endret.
        call    setchanged

  @@finished_this_one:
    ; Sjekk om muligens globalt. Hopp is�fall til neste.
        cmp     [glob], 0
        jz      @@not_global
        jmp     @@tekst_angitt

  @@not_global:


        jmp     SHORT @@ret

  @@neste_linje:
    ; Oppdatere pekere til neste linje. Kolonnen nullstilles, for det er
    ; bare f�rste gang ikke hele linjen skal regnes med.
        inc     ax
        mov     [findlin], ax
        xor     bx, bx
        mov     [findcol], bx
        jmp     @@let_i_linje

  @@ret:
    ; Sjekk om noen er funnet, og sett opp Carry flag etter dette.
        cmp     [matches], 0
        jnz     @@ret_found

    ; Teksten er ikke funnet. Marker dette.
        stc
        jmp     SHORT @@final_ret

  @@ret_found:
    ; Marker at teksten er funnet.
        clc

  @@final_ret:
        mov     ax, [lastlin]
        mov     bx, [lastcol]

        pop     es
        pop     si
        pop     di
        pop     dx
        pop     cx
        ret
ENDP    replacetext



;
; findnext
;
; Hva prosedyren gj�r:
;   Kaller findtext eller replacetext avhengig av hva forrige s�k var.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Samme som findtext/replacetext
;
; Endrer innholdet i:
;   Samme som findtext/replacetext
;
PROC    findnext

    ; Operasjon skal v�re relativt til n�v�rende posisjon.
        mov     ax, [curlin]
        mov     [findlin], ax
        mov     ax, [curcol]
        mov     [findcol], ax

    ; Finn ut om det er s�k eller s�k/erstatt som skal utf�res.
        cmp     [replace], 0
        jnz     @@do_replace

    ; Bare s�k, ikke erstatt ogs�.
        call    findtext
        jmp     SHORT @@ret

  @@do_replace:
    ; S�k og erstatt
        call    replacetext

  @@ret:
        ret
ENDP    findnext





ENDS

        END
