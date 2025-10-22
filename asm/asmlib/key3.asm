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

        PUBLIC  valg



;
; valg
;
; Hva prosedyren gj›r:
;   Leser JA/NEI-svar fra tastaturet.
;
;   OBS OBS OBS
;   Dette er norsk versjon av choice. For at det skal v‘re lett †
;   bytte mellom bruk av dem, returnerer denne engelsk svar selv
;   om det er norsk svar som er gitt!!
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   AX : 'Y' : JA  svart
;        'N' : NEI svart
;        27  : Esc trykket
;
; Endrer innholdet i:
;   AX
;
PROC    valg

  @@les_tegn:
        call    getkey
        cmp     ax, 27
        je      @@ret
        and     ax, 11011111b
        cmp     ax, 'N'
        je      @@ret
        cmp     ax, 'J'
        jne     @@les_tegn
        mov     ax, 'Y'

  @@ret:
        ret
ENDP    valg


        END
