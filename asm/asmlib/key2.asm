        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING



;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        EXTRN   getkey: PROC

        PUBLIC  choice



;
; choice
;
; Hva prosedyren gj›r:
;   Leser YES/NO-svar fra tastaturet.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   AX : 'Y' : Yes  svart
;        'N' : No   svart
;        27  : Esc trykket
;
; Endrer innholdet i:
;   AX
;
PROC    choice

  @@les_tegn:
        call    getkey
        cmp     ax, 27
        je      @@ret
        and     ax, 11011111b
        cmp     ax, 'Y'
        je      @@ret
        cmp     ax, 'N'
        jne     @@les_tegn

  @@ret:
        ret
ENDP    choice


        END
