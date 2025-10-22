        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING



;--------------------------;
;                          ;
;         D A T A          ;
;                          ;
;--------------------------;

UDATASEG

        EXTRN   vx1: BYTE, vy1: BYTE, vx2: BYTE, vy2: BYTE
        EXTRN   curx: BYTE, cury: BYTE
        EXTRN   txtattr: BYTE




;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        PUBLIC  window, clrscr
        PUBLIC  gotoxy, wherex, wherey

        EXTRN   setcurs: PROC



;
; clrscr
;
; Hva prosedyren gjõr:
;   Clearer hele vinduet til attributten i [txtattr].
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
PROC    clrscr
        push    ax
        push    bx
        push    cx
        push    dx
        mov     ax, 0600h
        mov     bh, [txtattr]
        mov     cl, [vx1]
        mov     ch, [vy1]
        mov     dl, [vx2]
        mov     dh, [vy2]
        int     10h
        mov     al, [vx1]
        mov     [curx], al
        mov     al, [vy1]
        mov     [cury], al
        call    setcurs
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    clrscr


;
; window
;
; Hva prosedyren gjõr:
;   Setter koordinater for skjermvinduet, relativt til hele skjermen.
;   Koordinatene starter pÜ 0.
;
; Kall med:
;   AL : ùverste venstre X
;   AH : ùverste venstre Y
;   DL : Nederste hõyre X
;   DH : Nederste hõyre Y
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    window
        mov     [vx1], al
        mov     [curx], al
        mov     [vy1], ah
        mov     [cury], ah
        mov     [vx2], dl
        mov     [vy2], dh
        call    setcurs
        ret
ENDP    window


;
; gotoxy
;
; Hva prosedyren gjõr:
;   Endrer markõrposisjonen til angitte koordinater. (Relativt til vinduet).
;   Koordinatene starter pÜ 0.
;
; Kall med:
;   AL : X-koordinat
;   AH : Y-koordinat
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    gotoxy
        push    ax
        add     al, [vx1]
        cmp     al, [vx2]
        ja      @@ret
        add     ah, [vy1]
        cmp     ah, [vy2]
        ja      @@ret
        mov     [curx], al
        mov     [cury], ah
        call    setcurs
@@ret:  pop     ax
        ret
ENDP    gotoxy


;
; wherex
;
; Hva prosedyren gjõr:
;   Returnerer nÜvërende X-posisjon i vinduet.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   AL : X-posisjonen
;
; Endrer innholdet i:
;   AL
;
PROC    wherex
        mov     al, [curx]
        sub     al, [vx1]
        ret
ENDP    wherex


;
; wherey
;
; Hva prosedyren gjõr:
;   Returnerer nÜvërende Y-posisjon i vinduet.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   AH : Y-posisjon
;
; Endrer innholdet i:
;   AH
;
PROC    wherey
        mov     ah, [cury]
        sub     ah, [vy1]
        ret
ENDP    wherey


        END
