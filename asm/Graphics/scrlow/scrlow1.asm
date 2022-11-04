        IDEAL

%       MODEL   MDL

        ASSUME  cs: @code, ds: @data, es: NOTHING


INCLUDE "SCRLOW.INC"  ; Makroer


DATASEG

;-----------;
;           ;
;  D A T A  ;
;           ;
;-----------;

        PUBLIC  init
        PUBLIC  vx1, vy1, vx2, vy2
        PUBLIC  antkol2
        PUBLIC  curx, cury
        PUBLIC  sadr
        PUBLIC  txtattr
        PUBLIC  stdattr

init    DB      0   ; Er init utfõrt?
vx1     DB      ?   ; ùverste venstre X-koordinat
vy1     DB      ?   ; ùverste venstre Y-koordinat
vx2     DB      ?   ; Nederste hõyre X-koordinat
vy2     DB      ?   ; Nederste hõyre Y-koordinat
antkol2 DW      ?   ; Antall kolonner pÜ skjermen * 2
curx    DB      ?   ; Cursor X
cury    DB      ?   ; Cursor Y
sadr    DD      ?   ; Startadresse for nÜvërende skjermside
txtattr DB      ?   ; NÜvërende attributt
stdattr DB      ?   ; Tekstattributt fra init_scrlow ble kalt opp



CODESEG

;-----------------------;
;                       ;
;  P R O S E D Y R E R  ;
;                       ;
;-----------------------;

        PUBLIC  _init_scrlow
        PUBLIC  _screenrows, _screencols
        PUBLIC  _screen_addr
        PUBLIC  setcurs, getcurs, vistegn


;
; setcurs flytter markõren til ([curx], [cury]).
;
; Det er viktig at kallefunksjonen har satt DS riktig!!!
;
; Ingen registre õdelagt
;
PROC    setcurs
        push    ax
        push    bx
        push    es
        mov     dl, [curx]
        mov     dh, [cury]
        xor     ax, ax
        mov     es, ax
        mov     bh, [es: 0462h]
        mov     ah, 2
        int     10h
        pop     es
        pop     bx
        pop     ax
        ret
ENDP    setcurs


;
; getcurs markõrens posisjon til [curx], [cury]
;
; Det er viktig at kallefunksjonen har satt DS riktig!!!
;
; Ingen andre registre õdelagt
;
PROC    getcurs
        push    ax
        push    bx
        push    es
        xor     ax, ax
        mov     es, ax
        mov     bl, [es: 0462h]
        xor     bh, bh
        shl     bx, 1
        mov     ax, [es: 0450h + bx]
        mov     [curx], al
        mov     [cury], ah
        pop     es
        pop     bx
        pop     ax
        ret
ENDP    getcurs


;
; _screencols
;
; returnerer antall cols (linjer) pÜ skjermen.
;
; Definert som:
;     int  cdecl screencols(void);
;
; Ingen registre õdelagt, bortsett fra AX, som er returregistret.
;
PROC    _screencols
        SETT_DS
        TEST_INIT
        RESETT_DS
        push    es
        xor     ax, ax
        mov     es, ax
        mov     ax, [es: 044Ah]
        pop     es
        ret
ENDP    _screencols


;
; _screenrows
;
; returnerer antall rows (linjer) pÜ skjermen.
;
; Definert som:
;     int  cdecl screenrows(void);
;
; Ingen registre õdelagt, bortsett fra AX, som er returregistret.
;
PROC    _screenrows
        SETT_DS
        TEST_INIT
        RESETT_DS
        push    bx
        push    cx
        mov     ah, 12h             ; Sjekk om EGA/VGA finnes
        mov     bl, 10h
        int     10h
        cmp     bl, 10h
        pop     cx
        pop     bx
        je      @@ikke_EGA          ; Fant ikke EGA - sett 25 linjer
        xor     ax, ax
        push    es
        mov     es, ax
        mov     al, [es: 0484h]
        pop     es
        inc     al
        ret
@@ikke_EGA:
        mov     ax, 25
        ret
ENDP    _screenrows


;
; _init_scrlow
;
; setter startvariablene for funksjonene.
; Mè kalles fõr noen av de andre funksjonene brukes.
;
; Definert som:
;     void  cdecl init_scrlow(void);
;
; Ingen registre õdelagt
;
PROC    _init_scrlow
        push    ax
        push    bx
        push    es
        SETT_DS
        mov     [BYTE init], 1
        xor     ax, ax
        mov     es, ax
        mov     ax, 0B000h
        cmp     [BYTE es: 0449h], 7  ; NÜvërende skjerm-modus
        je      @@j1
        mov     ax, 0B800h
@@j1:   mov     [WORD sadr + 2], ax
        mov     ax, [es: 044Eh]      ; Offset fra skjermsegment
        mov     bx, ax
        mov     cl, 4
        shr     ax, cl
        add     [WORD sadr + 2], ax
        shl     ax, cl
        sub     bx, ax
        mov     [WORD sadr], bx
        xor     ax, ax
        mov     es, ax
        mov     bh, [BYTE es: 0462h] ; NÜvërende skjermside
        mov     ah, 8
        int     10h
        mov     [stdattr], ah
        mov     [txtattr], ah
        xor     al, al
        mov     [vx1], al
        mov     [vy1], al
        call    _screencols
        dec     al
        mov     [vx2], al
        inc     al
        shl     ax, 1
        mov     [antkol2], ax
        call    _screenrows
        dec     al
        mov     [vy2], al
        call    getcurs
        RESETT_DS
        pop     es
        pop     bx
        pop     ax
        ret
ENDP    _init_scrlow



;
; vistegn viser tegn i al pÜ posisjonen pÜ skjermen angitt med (curx, cury).
; Tegnet vises i currattr. Markõrens posisjon oppdateres i [curx], [cury],
; men markõren flyttes ikke.
;
; Det er viktig at prosedyren som kaller denne har satt DS riktig!!!
;
; Ingen registre õdelagt
;
PROC    vistegn
        push    ax
        push    bx
        push    cx
        push    es
        push    di
        cmp     al, 10
        jne     @@ikke_LF
  @@LF:
        mov     al, [cury]
        inc     al
        cmp     al, [vy2]
        jbe     @@lagre_ny_y
        mov     ax, 0601h
        mov     bh, [txtattr]
        mov     cl, [vx1]
        mov     ch, [vy1]
        mov     dl, [vx2]
        mov     dh, [vy2]
        int     10h
        mov     al, [vy2]
  @@lagre_ny_y:
        mov     [cury], al
        jmp     SHORT @@ret
  @@ikke_LF:
        cmp     al, 13
        jne     @@ikke_CR
        mov     al, [vx1]
        jmp     SHORT @@lagre_ny_x
  @@ikke_CR:
        cmp     al, 7
        jne     @@ikke_BEL
  @@BEL:
    ; Lag pipetone
        mov     ax, 0E07h       ; Write Character (Bell) in Teletype Mode
        xor     bx, bx
        int     10h
        jmp     SHORT @@ret
  @@ikke_BEL:
        cmp     al, 8
        jne     @@ikke_DEL
  @@DEL:
    ; Flytt en til venstre hvis mulig.
        mov     al, [curx]
        cmp     [vx1], al
        jae     @@lagre_ny_x
        dec     al
        jmp     SHORT @@lagre_ny_x
  @@ikke_DEL:
        mov     cx, ax
        xor     ah, ah
        mov     al, [cury]
        mov     bx, [antkol2]
        mul     bx
        mov     bl, [curx]
        shl     bl, 1
        xor     bh, bh
        add     ax, bx
        les     di, [DWORD sadr]
        add     di, ax
        mov     ax, cx
        mov     ah, [txtattr]
        mov     [es: di], ax
        mov     al, [curx]
        inc     al
        cmp     al, [vx2]
        jbe     @@lagre_ny_x
        mov     al, [vx1]
        mov     [curx], al
        jmp     @@LF
  @@lagre_ny_x:
        mov     [curx], al
  @@ret:
        pop     di
        pop     es
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    vistegn



;
; _screen_addr
;
; Hva prosedyren gjõr:
;   Returnerer skjermens startadresse
;
; Definert som:
;   void far * cdecl screen_addr(void);
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   DX:AX - Peker til starten pÜ skjermminnet
;
; Endrer innholdet i:
;   AX, DX
;
PROC    _screen_addr
        SETT_DS
        TEST_INIT
        mov     dx, [WORD sadr + 2]
        mov     ax, [WORD sadr]
        RESETT_DS
        ret
ENDP    _screen_addr



        END
