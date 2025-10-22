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

        PUBLIC  strcpy


;
; strcpy
;
; Hva prosedyren gj›r:
;   Kopierer en ASCIIZ-streng til en annen andresse
;
; Kall med:
;   DS:SI - Peker til strengen som skal kopieres
;   ES:DI - Peker til omr†det strengen skal kopieres til. Det m†
;           v‘re nok plass.
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    strcpy
        push    ax
        push    cx
        push    dx
        push    si
        push    di
        push    es
        mov     dx, si
        call    strlen
        mov     cx, ax
        inc     cx      ; Ta med \0 -en p† slutten ogs†.
        cld
        repne   movsb
        pop     es
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     ax
        ret
ENDP    strcpy


        END
