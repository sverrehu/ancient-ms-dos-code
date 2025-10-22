        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING


INCLUDE "MEM.INC"



;--------------------------;
;                          ;
;         D A T A          ;
;                          ;
;--------------------------;

UDATASEG

        EXTRN   freelst: WORD





;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        PUBLIC  memleft



;
; memleft
;
; Hva prosedyren gj›r:
;   Finner ut hvor mye minne som er ledig (i paragrafer)
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   AX : Antall ledige paragrafer
;
; Endrer innholdet i:
;   AX
;
PROC    memleft
        push    bx
        push    es

        xor     ax, ax          ; Nullstill teller
        mov     es, [freelst]
@@sjekk_neste:
        mov     bx, es
        or      bx, bx
        jz      @@alle_ferdig
        add     ax, [es: (ledig_blk PTR 0).paragr]
        mov     es, [es: (ledig_blk PTR 0).next]
        jmp     SHORT @@sjekk_neste
@@alle_ferdig:

        pop     es
        pop     bx
        ret
ENDP    memleft



        END
