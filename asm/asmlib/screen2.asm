        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING




;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        PUBLIC  outchar, outtext

        EXTRN   lowchar: PROC, setcurs: PROC



;
; outchar
;
; Hva prosedyren gj›r:
;   Viser tegn p† skjermen, og oppdaterer mark›rposisjonen.
;
; Kall med:
;   AL : Tegn som skal vises
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    outchar
        call    lowchar
        call    setcurs
        ret
ENDP    outchar


;
; outtext
;
; Hva prosedyren gj›r:
;   Viser ASCIIZ-string p† skjermen, og oppdaterer mark›rposisjon.
;
; Kall med:
;   DS:DX : Peker til strengen
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    outtext
        push    ax
        push    bx
        mov     bx, dx
@@neste:mov     al, [bx]
        or      al, al
        jz      @@ret
        call    lowchar
        inc     bx
        jmp     SHORT @@neste
@@ret:  call    setcurs
        pop     bx
        pop     ax
        ret
ENDP    outtext




        END
