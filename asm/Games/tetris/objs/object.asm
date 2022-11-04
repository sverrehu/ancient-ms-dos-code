        IDEAL

        MODEL   SMALL

        ASSUME  cs: @code, ds: @data, es: NOTHING

; Setter opp konstanter og makroer som gjelder for mode 10h

INCLUDE "EGA10DEF.INC"


DATASEG

        EXTRN   segadr: WORD



CODESEG

        PUBLIC  _showobj16x11


;
; _showobj16x11
;
; Hva prosedyren gj›r:
;   Viser et objekt i angitte koordinater
;
; Kall med:
;   DL : X-koordinat  (0-79)
;   DH : Y-koordinat  (0-57)
;   SI : Peker til data om objekt
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   bitmask
;
ALIGN WORD
PROC    _showobj16x11
        ARG     x: WORD, y: WORD, p: WORD
        push    bp
        mov     bp, sp
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    si
        push    es

        mov     si, [p]

    ; Calculate the screenaddress, and save it in DI. The address is:
    ;         (80 * 11 * y + 2 * x)
    ;       = (880 * y + 2 * x)
    ;       = (512 * y + 256 * y + 64 * y + 32 * y + 16 * y + 2 * x)
        mov     di, [x]
        shl     di, 1           ;                   x * 2

        mov     ax, [y]
        mov     cl, 4
        shl     ax, cl          ;                   y * 16
        add     di, ax
        shl     ax, 1           ; (y * 16)  * 2 =   y * 32
        add     di, ax
        shl     ax, 1           ; (y * 32)  * 2 =   y * 64
        add     di, ax
        shl     ax, 1
        shl     ax, 1           ; (y * 64)  * 4 =   y * 256
        add     di, ax
        shl     ax, 1           ; (y * 256) * 2 =   y * 512
        add     di, ax

        mov     es, [segadr]
        mov     dx, GCONAP
        mov     ax, ESETRES + 0 * 256
        out     dx, ax

        mov     cx, 4
@@l1:   push    cx

        mov     ah, 00001000b
        dec     cl
        shr     ah, cl
        inc     cl
        mov     dx, SEQAP
        mov     al, MAPMSK
        out     dx, ax

  ; Tegn selve figuren ved † vise de fire bitplanene i riktig farge
        mov     dx, GCONAP
        push    di
        mov     cx, 11
        cld
@@l3:   lodsb
        stosb
        lodsb
        stosb
        add     di, 78
        loop    @@l3
        pop     di

        pop     cx
        loop    @@l1

        mov     dx, SEQAP
        mov     ax, MAPMSK + 15 * 256
        out     dx, ax

        mov     dx, GCONAP
        mov     ax, ESETRES + 15 * 256
        out     dx, ax

@@ret:  pop     es
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        pop     bp
        ret
ENDP    _showobj16x11



        END
