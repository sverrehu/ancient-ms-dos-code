        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING


SCROFFS EQU     80 * 6 + 61     ; Logoens offset fra skjermstart


DATASEG

        EXTRN   segadr: WORD
        EXTRN   logodata: PTR, LOGOX: ABS, LOGOY: ABS


CODESEG

        EXTRN   mapmask: PROC, bitmask: PROC, esetreset: PROC


        PUBLIC  showlogo



;
; showbitplan
;
; Hva prosedyren gj›r:
;   Viser et bitplan av logoen i henhold til variablene BYTESX og BYTESY
;   Planet m† v‘re satt av kalleren.
;
; Kall med:
;   ES:DI - Peker til start p† skjermen
;   DS:SI - Peker til data.
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   SI - peker etter brukt dataomr†de
;
PROC    showbitplan
        push    cx
        push    di

        cld
        mov     cx, LOGOY
@@y_loop:
        push    cx
        push    di

        mov     cx, LOGOX
        rep     movsb

        pop     di
        add     di, 80
        pop     cx
        loop    @@y_loop

@@ret:  pop     di
        pop     cx
        ret
ENDP    showbitplan



;
; showlogo
;
; Hva prosedyren gj›r:
;   Viser spillogoen p† skjermen
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    showlogo
        push    ax
        push    di
        push    si
        push    es

        xor     ah, ah
        call    esetreset

        mov     ah, 255
        call    bitmask

        mov     es, [segadr]
        mov     di, SCROFFS

        mov     si, OFFSET logodata

        mov     ah, 1
        call    mapmask
        call    showbitplan

        mov     ah, 2
        call    mapmask
        call    showbitplan

        mov     ah, 4
        call    mapmask
        call    showbitplan

        mov     ah, 8
        call    mapmask
        call    showbitplan

        mov     ah, 15
        call    mapmask
        call    esetreset

@@ret:  pop     es
        pop     si
        pop     di
        pop     ax
        ret
ENDP    showlogo




ENDS

        END
