        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING



;--------------------------;
;                          ;
;         D A T A          ;
;                          ;
;--------------------------;

UDATASEG

        PUBLIC  vx1, vy1, vx2, vy2
        PUBLIC  antkol2
        PUBLIC  curx, cury
        PUBLIC  sadr
        PUBLIC  txtattr, stdattr

vx1     DB      ?   ; �verste venstre X-koordinat
vy1     DB      ?   ; �verste venstre Y-koordinat
vx2     DB      ?   ; Nederste h�yre X-koordinat
vy2     DB      ?   ; Nederste h�yre Y-koordinat
antkol2 DW      ?   ; Antall kolonner p� skjermen * 2
curx    DB      ?   ; Cursor X
cury    DB      ?   ; Cursor Y
sadr    DD      ?   ; Startadresse for n�v�rende skjermside
txtattr DB      ?   ; N�v�rende attributt
stdattr DB      ?   ; Tekstattributt fra initscreen ble kalt opp





;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        PUBLIC  initscreen, endscreen
        PUBLIC  addr_of_pos, lowchar
        PUBLIC  setcurs, getcurs
        PUBLIC  screenrows, screencols



;
; setcurs
;
; Hva prosedyren gj�r:
;   Flytter mark�ren til koordinatene i ([curx], [cury]).
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
PROC    setcurs
        push    ax
        push    bx
        push    dx
        push    es
        mov     dl, [curx]
        mov     dh, [cury]
        xor     ax, ax
        mov     es, ax
        mov     bh, [es: 0462h]
        mov     ah, 2
        int     10h
        pop     es
        pop     dx
        pop     bx
        pop     ax
        ret
ENDP    setcurs


;
; getcurs
;
; Hva prosedyren gj�r:
;   Finner mark�rens skjermposisjon og legger denne i [curx], [cury]
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   [curx], [cury]
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
; screencols
;
; Hva prosedyren gj�r:
;   Finner antall kolonner p� skjermen.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   AX : Antall kolonner
;
; Endrer innholdet i:
;   AX
;
PROC    screencols
        push    es
        xor     ax, ax
        mov     es, ax
        mov     ax, [es: 044Ah]
        pop     es
        ret
ENDP    screencols


;
; screenrows
;
; Hva prosedyren gj�r:
;   Finner antall linjer p� skjermen.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   AX : Antall linjer
;
; Endrer innholdet i:
;   AX
;
PROC    screenrows
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
ENDP    screenrows


;
; initscreen
;
; Hva prosedyren gj�r:
;   Setter startvariablene for funksjonene. M� kalles f�r noe annet brukes.
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
PROC    initscreen
        push    ax
        push    bx
        push    cx
        push    dx
        push    es
        xor     ax, ax
        mov     es, ax
        mov     ax, 0B000h
        cmp     [BYTE es: 0449h], 7  ; N�v�rende skjerm-modus
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
        mov     bh, [BYTE es: 0462h] ; N�v�rende skjermside
        mov     ah, 8
        int     10h
        mov     [stdattr], ah
        mov     [txtattr], ah
        xor     al, al
        mov     [vx1], al
        mov     [vy1], al
        call    screencols
        dec     al
        mov     [vx2], al
        inc     al
        shl     ax, 1
        mov     [antkol2], ax
        call    screenrows
        dec     al
        mov     [vy2], al
        call    getcurs
        pop     es
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    initscreen


;
; endscreen
;
; Hva prosedyren gj�r:
;   Skal rydde opp etter at skjermrutinene er brukt. Forel�pig gj�r den
;   ingenting.
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
PROC    endscreen
        ret
ENDP    endscreen


;
; addr_of_pos
;
; Hva prosedyren gj�r:
;   Finner skjermadressen til angitt posisjon (i forhold til hele skjermen)
;
; Kall med:
;   AL : X-posisjon
;   AH : Y-posisjon
;
; Returnerer:
;   ES:DI : Adressen til tegnet
;
; Endrer innholdet i:
;   ES, DI
;
PROC    addr_of_pos
        push    ax
        push    bx
        push    cx
        push    dx
        mov     cx, ax
        mov     al, ah
        xor     ah, ah
        mov     bx, [antkol2]
        mul     bx
        mov     bl, cl
        shl     bl, 1
        xor     bh, bh
        add     ax, bx
        les     di, [DWORD sadr]
        add     di, ax
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    addr_of_pos


;
; lowchar
;
; Hva prosedyren gj�r:
;   Viser angitt tegn i n�v�rende farge p� n�v�rende skjermposisjon.
;   Tegnet tolkes, slik at CR og LF utf�res riktig.
;   Oppdaterer skjermposisjonen (NB!) uten � flytte mark�ren.
;
; Kall med:
;   AL : tegnet som skal vises
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   [curx], [cury]
;
PROC    lowchar
        push    ax
        push    bx
        push    cx
        push    dx
        push    es
        push    di
        cmp     al, 10
        jne     @@not_LF
@@LF:   mov     al, [cury]
        inc     al
        cmp     al, [vy2]
        jbe     @@savenew_y
        mov     ax, 0601h
        mov     bh, [txtattr]
        mov     cl, [vx1]
        mov     ch, [vy1]
        mov     dl, [vx2]
        mov     dh, [vy2]
        int     10h
        mov     al, [vy2]
@@savenew_y:
        mov     [cury], al
        jmp     SHORT @@ret
@@not_LF:
        cmp     al, 13
        jne     @@not_CR
        mov     al, [vx1]
        jmp     SHORT @@savenew_x
@@not_CR:
        mov     cx, ax
        mov     al, [curx]
        mov     ah, [cury]
        call    addr_of_pos
        mov     ax, cx
        mov     ah, [txtattr]
        mov     [es: di], ax
        mov     al, [curx]
        inc     al
        cmp     al, [vx2]
        jbe     @@savenew_x
        mov     al, [vx1]
        mov     [curx], al
        jmp     SHORT @@LF
@@savenew_x:
        mov     [curx], al
@@ret:  pop     di
        pop     es
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    lowchar


        END
