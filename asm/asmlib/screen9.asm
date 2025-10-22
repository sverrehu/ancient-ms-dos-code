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

        PUBLIC  insline, delline, clreol



;
; insline
;
; Hva prosedyren gj›r:
;   Setter inn en blank linje ved mark›rposisjonen
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
PROC    insline
        push    ax
        push    bx
        push    cx
        push    dx
        mov     ax, 0701h
        mov     bh, [txtattr]
        mov     cl, [vx1]
        mov     ch, [cury]
        mov     dl, [vx2]
        mov     dh, [vy2]
        int     10h
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    insline


;
; delline
;
; Hva prosedyren gj›r:
;   Fjerner linjen mark›ren st†r p†
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
PROC    delline
        push    ax
        push    bx
        push    cx
        push    dx
        mov     ax, 0601h
        mov     bh, [txtattr]
        mov     cl, [vx1]
        mov     ch, [cury]
        mov     dl, [vx2]
        mov     dh, [vy2]
        int     10h
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    delline


;
; clreol
;
; Hva prosedyren gj›r:
;   Blanker linjen fra mark›ren og ut
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
PROC    clreol
        push    ax
        push    bx
        push    cx
        push    dx
        mov     ax, 0600h
        mov     bh, [txtattr]
        mov     cl, [curx]
        mov     ch, [cury]
        mov     dl, [vx2]
        mov     dh, [cury]
        int     10h
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    clreol


        END
