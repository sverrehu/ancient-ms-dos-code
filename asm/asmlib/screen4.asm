        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING




;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        PUBLIC  outint

        EXTRN   lowchar: PROC, outword: PROC



;
; outint
;
; Hva prosedyren gjõr:
;   Viser et heltall (signed) pÜ skjermen.
;
; Kall med:
;   AX : ùnsket tall
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    outint
        push    ax
        or      ax, ax     ; Er tallet negativt ?
        jns     @@ikke_negativ
        push    ax
        mov     al, '-'
        call    lowchar
        pop     ax
        neg     ax
@@ikke_negativ:
        call    outword
        pop     ax
        ret
ENDP    outint


        END
