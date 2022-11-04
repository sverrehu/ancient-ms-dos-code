        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data


INCLUDE "SNAKE3.INC"




UDATASEG

pid     DW      ?       ; Prosessnummer under lesing av tast
key     DW      ?       ; Tast som ble trykket
curspos DW      ?       ; Mark›rens X/Y-posisjon
curscol DB      ?       ; Mark›rens farge
onoff   DB      ?       ; Skal neste av eller p†?
monoff  DB      ?       ; Skal neste melding av eller p†?
maddr   DW      ?       ; Peker til n†v‘rende melding



DATASEG

        EXTRN   level: WORD
        EXTRN   quit: BYTE, soundon: BYTE
        EXTRN   hghtab: PTR
        EXTRN   blank: PTR, mush6: PTR, pill: PTR, skull: PTR, hbang1: PTR
        EXTRN   strwbrry: PTR, pear: PTR, banana: PTR, lemon: PTR
        EXTRN   ramme1: PTR, ramme2: PTR, ramme3: PTR, ramme4: PTR
        EXTRN   ramme5: PTR, ramme6: PTR, ramme7: PTR, ramme8: PTR


mpid    DW      -1      ; Prosessid for meldingsblinker

empmsg  DB      "                   ", 0
empmsg2 DB      "               ", 0

alvmsg  DB      11, 15, "CHOOSE LEVEL (1-9)", 13, 10
        DB      "OR ESC TO QUIT", 0

statmsg DB      11, 10, "STATUS:", 13, 10, 11, 7
        DB      "  SCORE:          0", 13, 10
        DB      "  LENGTH:         0", 13, 10
        DB      "  LIVES:          0", 13, 10
        DB      "  LEVEL:          0", 13, 10
        DB      "  SOUND:         ON", 0
onmsg   DB      " ON", 0
offmsg  DB      "OFF", 0


foodmsg DB      11, 10, "FOOD:", 13, 10, 11, 5
        DB      "  BANANA        5*L", 13, 10
        DB      "  PEAR         10*L", 13, 10
        DB      "  LEMON        15*L", 13, 10
        DB      "  STRAWBERRY   20*L", 13, 10
        DB      "  SLIM-PILL", 13, 10, 10, 11, 3
        DB      "            L=LEVEL", 0

poismsg DB      11, 10, "NON-FOOD:", 13, 10, 11, 4
        DB      "  LETHAL MUSHROOM", 13, 10
        DB      "  ROTTEN FOOD", 13, 10
        DB      "  HEADBANGER", 0

keymsg  DB      11, 10, "KEYS:", 13, 10, 11, 2
        DB      "  ARROWS  -    MOVE", 13, 10
        DB      "  OR AZNM -    MOVE", 13, 10
        DB      "  SPACE   -   PAUSE", 13, 10
        DB      "  S       -   SOUND", 13, 10
        DB      "  ESC     -    STOP", 0

hghmsg  DB      11, 9, " -- HIGHSCORES --", 13, 10, 10, 11, 3
        DB      " 1.", 13, 10
        DB      " 2.", 13, 10
        DB      " 3.", 13, 10
        DB      " 4.", 13, 10
        DB      " 5.", 13, 10
        DB      " 6.", 13, 10
        DB      " 7.", 13, 10
        DB      " 8.", 13, 10
        DB      " 9.", 13, 10
        DB      "10.", 0




CODESEG

        EXTRN   showobj8x6: PROC, showtxt8x6: PROC, shownum8x6: PROC
        EXTRN   showchr8x6: PROC
        EXTRN   setpos: PROC, getpos: PROC
        EXTRN   newproc: PROC, procloop: PROC, rmproc: PROC
        EXTRN   showlogo: PROC

        PUBLIC  drawscreen, asklevel, showhgh, inputlin9, showsound
        PUBLIC  clearplayground
        PUBLIC  showmessage, clearmessage



;
; drawscreen
;
; Hva prosedyren gj›r:
;   Tegner skjermbildet rundt spillet
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
PROC    drawscreen
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    si

  ; Tegn rammen rundt selve spillomr†det
        mov     al, BORDER
        mov     dx, (MINX - 1) + 256 * (MINY - 1)
        mov     si, OFFSET ramme1
        call    showobj8x6
        call    setpos
        mov     dh, MAXY + 1
        mov     si, OFFSET ramme3
        call    showobj8x6
        call    setpos

        mov     cx, MAXX - MINX + 1
@@top_and_bott:
        mov     dx, (MINX - 1) + 256 * (MINY - 1)
        add     dl, cl
        mov     si, OFFSET ramme5
        call    showobj8x6
        call    setpos
        mov     dx, (MINX - 1) + 256 * (MAXY + 1)
        add     dl, cl
        mov     si, OFFSET ramme6
        call    showobj8x6
        call    setpos
        loop    @@top_and_bott

        mov     dx, (MAXX + 1) + 256 * (MINY - 1)
        mov     si, OFFSET ramme2
        call    showobj8x6
        call    setpos
        mov     dh, MAXY + 1
        mov     si, OFFSET ramme4
        call    showobj8x6
        call    setpos

        mov     cx, MAXY - MINY + 1
@@left_and_right:
        mov     dx, (MINX - 1) + 256 * (MINY - 1)
        add     dh, cl
        mov     si, OFFSET ramme7
        call    showobj8x6
        call    setpos
        mov     dx, (MAXX + 1) + 256 * (MINY - 1)
        add     dh, cl
        mov     si, OFFSET ramme8
        call    showobj8x6
        call    setpos
        loop    @@left_and_right

  ; Vis logo og instruksjoner p† h›yre side.
        call    showlogo

  ; Tekst for poeng, lengde, liv igjen, niv† og lyd
        mov     dx, INSTRX + 256 * 10
        mov     si, OFFSET statmsg
        call    showtxt8x6

  ; Forklaring til hvert spiselig objekt som finnes p† skjermen.
        mov     dx, INSTRX + 256 * 17
        mov     si, OFFSET foodmsg
        call    showtxt8x6

        mov     dx, INSTRX + 256 * 18
        mov     si, OFFSET banana
        call    showobj8x6

        inc     dh
        mov     si, OFFSET pear
        call    showobj8x6

        inc     dh
        mov     si, OFFSET lemon
        call    showobj8x6

        inc     dh
        mov     si, OFFSET strwbrry
        call    showobj8x6

        inc     dh
        mov     si, OFFSET pill
        call    showobj8x6

  ; Forklaring til ikke-spiselige objekter.
        mov     dx, INSTRX + 256 * 26
        mov     si, OFFSET poismsg
        call    showtxt8x6

        mov     dx, INSTRX + 256 * 27
        mov     si, OFFSET mush6
        call    showobj8x6

        inc     dh
        mov     si, OFFSET skull
        call    showobj8x6

        inc     dh
        mov     si, OFFSET hbang1
        call    showobj8x6

  ; Taster
        mov     dx, INSTRX + 256 * 32
        mov     si, OFFSET keymsg
        call    showtxt8x6

  ; Vis header til highscores
        mov     ah, 9
        mov     dx, INSTRX + 256 * 45
        mov     si, OFFSET hghmsg
        call    showtxt8x6

@@ret:  pop     si
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    drawscreen



;
; waitkey
;
; Hva prosedyren gj›r:
;   Blinker en mark›r av eller p†, avhengig av innholdet i onoff.
;   Hvis en tast er trykket, leses denne inn i key, og waitkey
;   fjerner seg selv fra prosesslisten.
;
; Kall med:
;   Denne skal ikke kalles, er beregnet p† † ligge i prosessk›en.
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    waitkey
        push    ax
        push    dx

  ; Hent mark›rverdiene
        mov     dx, [curspos]
        mov     ah, [curscol]

  ; Sjekk om mark›r skal sl†s av eller p†
        mov     al, '#'
        cmp     [onoff], 0
        jnz     @@turn_on
        mov     al, ' '
        mov     ah, 15

  ; Sett riktig mark›r
@@turn_on:
        call    showchr8x6

  ; S›rg for at den sl†s p†/av (motsatt) neste gang
        xor     [onoff], 1

  ; Sjekk om tast er trykket
        mov     ah, 1
        int     16h
        jz      @@ret

  ; Les og tolk tasten som er trykket
        xor     ah, ah
        int     16h
        or      al, al
        jnz     @@normal_tast
        mov     al, ah
        xor     ah, ah
        neg     ax
        jmp     SHORT @@store_key
@@normal_tast:
        xor     ah, ah

  ; Lagre tastekoden
@@store_key:
        mov     [key], ax

  ; Fjern waitkey fra prosesslisten
        mov     ax, [pid]
        call    rmproc

@@ret:  pop     dx
        pop     ax
        ret
ENDP    waitkey



;
; inputkey
;
; Hva prosedyren gj›r:
;   Blinker en mark›r og venter til tast er trykket.
;   Krever at prosesslisten er tom!
;
; Kall med:
;   DL : X-posisjon for mark›r
;   DH : Y-posisjon for mark›r
;   AH : Farge mark›ren skal vises med
;
; Returnerer:
;   AX : Tasten som ble trykket
;
; Endrer innholdet i:
;   AX
;
PROC    inputkey
        push    dx
        push    si

  ; Sett opp variabler som brukes av waitkey
        mov     [curspos], dx
        mov     [curscol], ah
        mov     [onoff], 1

  ; Sett waitkey inn i prosesslisten
        mov     dx, OFFSET waitkey
        mov     ax, 15
        call    newproc
        mov     [pid], ax

  ; Start ventingen
        call    procloop

  ; Fjern mark›ren
        mov     dx, [curspos]
        mov     al, ' '
        mov     ah, 15
        call    showchr8x6

  ; Hent returverdien
        mov     ax, [key]

        pop     si
        pop     dx
        ret
ENDP    inputkey



;
; inputlin9
;
; Hva prosedyren gj›r:
;   Ber bruker om en linje p† opptil 9 tegn.
;
; Kall med:
;   DL : X-posisjon for f›rste tegn p† skjermen
;   DH : Y-posisjon for f›rste tegn
;   AH : Farge
;   DI : Peker til linjebuffer. Blir nullterminert.
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    inputlin9
        push    ax
        push    bx
        push    dx
        push    bp
        push    di

        mov     bp, di
        add     bp, 9   ; For sammenlikning

@@les_tast:
        push    ax
        call    inputkey
        mov     bx, ax
        pop     ax

        cmp     bx, 27
        je      @@terminer
        cmp     bx, 13
        je      @@terminer
        cmp     bx, 8
        je      @@backspace
        cmp     bx, 'a'
        jl      @@not_small
        cmp     bx, 'z'
        jg      @@les_tast
  ; Oversett til stor bokstav
        sub     bx, 'a' - 'A'
@@not_small:
        cmp     bx, 32
        jl      @@les_tast
        cmp     bx, 'Z'
        jg      @@les_tast

  ; Vis tegnet p† skjermen
        mov     al, bl
        call    showchr8x6
        inc     dl

  ; Legg inn tegnet
        mov     [di], al
        inc     di
        cmp     di, bp
        je      @@terminer

        jmp     SHORT @@les_tast

@@backspace:
        mov     bx, bp
        sub     bx, 9
        cmp     di, bx
        je      @@les_tast

        dec     dl
        dec     di
        jmp     SHORT @@les_tast

@@terminer:
        mov     [BYTE di], 0

@@ret:  pop     di
        pop     bp
        pop     dx
        pop     bx
        pop     ax
        ret
ENDP    inputlin9



;
; asklevel
;
; Hva prosedyren gj›r:
;   Ber bruker om ›nsket level. Venter til lovlig tast er trykket.
;   Hvis dette er Esc, legges ESC inn i quit.
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
PROC    asklevel
        push    ax
        push    dx
        push    si

  ; Vis melding som ber om niv†
        mov     dx, INSTRX + 256 * 41
        mov     si, OFFSET alvmsg
        call    showtxt8x6

  ; Les tast til lovlig kode er valgt
@@read_key:
        mov     dx, INSTRX + 15 + 256 * 42
        mov     ah, 15
        call    inputkey

        cmp     al, 27
        jne     @@not_esc
        mov     [quit], ESCAPE
        jmp     SHORT @@ret

@@not_esc:
  ; Sjekk om s eller S for † endre lydstatus
        cmp     al, 's'
        je      @@chg_sound
        cmp     al, 'S'
        jne     @@test_numbers

@@chg_sound:
        xor     [soundon], 1
        call    showsound
        jmp     @@read_key

@@test_numbers:
        cmp     al, '1'
        jb      @@read_key
        cmp     al, '9'
        ja      @@read_key

  ; Lagre valgt niv†
        sub     al, '0'
        xor     ah, ah
        mov     [level], ax

  ; Fjern teksten
        mov     dx, INSTRX + 256 * 41
        mov     ah, 15
        mov     si, OFFSET empmsg
        call    showtxt8x6

        inc     dh
        call    showtxt8x6

@@ret:  pop     si
        pop     dx
        pop     ax
        ret
ENDP    asklevel



;
; showhgh
;
; Hva prosedyren gj›r:
;   Viser highscoretabellen p† skjermen
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
PROC    showhgh
        push    ax
        push    bx
        push    cx
        push    dx
        push    si

        mov     si, OFFSET hghtab
        mov     dx, INSTRX + 4 + 256 * 47
        mov     cx, 10

@@neste:
        push    cx

  ; Fjern det som evt. er p† linjen fra f›r
        push    si
        mov     si, OFFSET empmsg2
        mov     ah, 15
        call    showtxt8x6
        pop     si

  ; Vis teksten
        mov     ah, 3
        call    showtxt8x6

  ; Vis score
        push    ax
        push    dx
        add     dl, 10
        mov     cl, ah
        mov     ax, [si + 10]
        call    shownum8x6
        pop     dx
        pop     ax

  ; Oppdater pekere
        inc     dh      ; Skjermen
        add     si, 12  ; Highscores

        pop     cx
        loop    @@neste

@@ret:  pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    showhgh



;
; showsound
;
; Hva prosedyren gj›r:
;   Viser lydstatus
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
PROC    showsound
        push    ax
        push    dx
        push    si

        mov     dx, 77 + 256 * 15
        mov     ah, 7
        mov     si, OFFSET onmsg

        cmp     [soundon], 0
        jnz     @@show

        mov     si, OFFSET offmsg

@@show: call    showtxt8x6

        pop     si
        pop     dx
        pop     ax
        ret
ENDP    showsound



;
; clearplayground
;
; Hva prosedyren gj›r:
;   Fjerner det som befinner seg innenfor gjerdet p† skjermen.
;   Fjernes ogs† fra scrmem.
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
PROC    clearplayground
        push    ax
        push    cx
        push    dx
        push    si

        mov     si, OFFSET blank
        mov     al, BLANK

        mov     dh, MINY
        mov     cx, MAXY - MINY + 1
@@next_y:
        push    cx

        mov     dl, MINX
        mov     cx, MAXX - MINX + 1

@@next_x:
        call    showobj8x6
        call    setpos
        inc     dl
        loop    @@next_x

        inc     dh
        pop     cx
        loop    @@next_y

@@ret:  pop     si
        pop     dx
        pop     cx
        pop     ax
        ret
ENDP    clearplayground



;
; blinkmessage
;
; Hva prosedyren gj›r:
;   Blinker n†v‘rende melding p† skjermen.
;   Skal ligge i prosesslisten.
;
; Kall med:
;   Ingenting. Skal ikke kalles direkte.
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC   blinkmessage
       push    ax
       push    dx
       push    si

       mov     si, [maddr]
       cmp     [monoff], 0
       jnz     @@show

       mov     si, OFFSET empmsg

@@show:
       mov     ah, 7
       mov     dx, INSTRX + 256 * 41
       call    showtxt8x6

       xor     [monoff], 1

       pop     si
       pop     dx
       pop     ax
       ret
ENDP   blinkmessage



;
; showmessage
;
; Hva prosedyren gj›r:
;   Setter opp for † blinke en melding p† skjermen.
;
; Kall med:
;   SI - peker til strengen som skal vises.
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    showmessage
        push    ax
        push    dx

        mov     [maddr], si
        mov     [monoff], 1

        cmp     [mpid], -1
        jne     @@ret

        mov     ax, 25
        mov     dx, OFFSET blinkmessage
        call    newproc
        mov     [mpid], ax

@@ret:  pop     dx
        pop     ax
        ret
ENDP    showmessage



;
; clearmessage
;
; Hva prosedyren gj›r:
;   Fjerner blinkemeldingen fra skjermen.
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
PROC    clearmessage
        push    ax
        push    dx
        push    si

        mov     ax, [mpid]
        cmp     ax, -1
        je      @@ret

        call    rmproc
        mov     [mpid], -1

        mov     ah, 15
        mov     dx, INSTRX + 256 * 41
        mov     si, OFFSET empmsg
        call    showtxt8x6

@@ret:  pop     si
        pop     dx
        pop     ax
        ret
ENDP    clearmessage




ENDS

        END
