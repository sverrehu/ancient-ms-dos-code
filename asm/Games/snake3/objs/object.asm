        IDEAL

        MODEL   SMALL

        ASSUME  cs: @code, ds: @data, es: NOTHING

; Setter opp konstanter og makroer som gjelder for mode 10h

INCLUDE "EGA10DEF.INC"


DATASEG

        EXTRN   segadr: WORD



CODESEG

        PUBLIC  _showobj8x6


;
; _showobj8x6
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
PROC    _showobj8x6
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

        mov     dl, [BYTE x]
        mov     dh, [BYTE y]
        mov     si, [p]

  ; Beregn skjermadressen og legg denne i DI. Dette er 80*6*y+x, som er
  ; 480*y+x, som er 512*y-32*y+x=(y<<8)<<2-y<<5+x
        mov     cl, dl
        xor     ch, ch
        mov     di, cx

        mov     bl, dh
        xor     bh, bh
        mov     cl, 5
        shl     bx, cl
        xor     dl, dl
        add     dx, dx
        sub     dx, bx
        add     di, dx

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
        mov     cx, 6
        cld
@@l3:   lodsb
        mov     [es: di], al
        add     di, 80
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
ENDP    _showobj8x6



        END
