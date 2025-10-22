        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING



;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        PUBLIC  getkey



;
; getkey
;
; Hva prosedyren gj›r:
;   Leser tegn fra tastaturet.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   AX : Tasten som er trykket. Hvis det er en spesialtast, returneres
;        dennes negative verdi.
;
; Endrer innholdet i:
;   AX
;
PROC    getkey

  @@no_key_waiting:
        int     28h     ; Dette utf›res av DOS n†r det ventes p† tastetrykk.
        mov     ah, 1
        int     16h
        jz      @@no_key_waiting
        xor     ah, ah
        int     16h
        or      al, al  ; Er spesialtast trykket?
        jnz     @@ikke_spestast
        mov     al, ah
        xor     ah, ah
        neg     ax
        ret
  @@ikke_spestast:
        xor     ah, ah  ; Null ut scancode
        ret
ENDP    getkey


        END
