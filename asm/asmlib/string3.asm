        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING



;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        EXTRN   strlen: PROC

        PUBLIC  strip


;
; strip
;
; Hva prosedyren gj›r:
;   Fjerner blanke i slutten av en ASCIIZ-string
;
; Kall med:
;   DS:DX - Peker til strengen
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    strip
        push    ax
        push    cx
        push    di
        push    es

        push    ds
        pop     es
        call    strlen
        mov     cx, ax
        jcxz    @@ret        ; strlen=0
        mov     di, dx
        add     di, cx
        dec     di
        mov     al, ' '      ; S›k bakover s† lenge blank er funnet
        std
        repe    scasb
        je      @@inc_en
        inc     di
@@inc_en:
        inc     di
@@ikke_inc:
        mov     [BYTE di], 0 ; Sett ny slutt p† strengen
@@ret:  pop     es
        pop     di
        pop     cx
        pop     ax
        ret
ENDP    strip


        END
