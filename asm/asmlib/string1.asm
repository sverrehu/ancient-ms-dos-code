        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING



;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        PUBLIC  strlen


;
; strlen
;
; Hva prosedyren gj›r:
;   Finner lengden p† en ASCIIZ-streng.
;
; Kall med:
;   DS:DX - Peker til strengen
;
; Returnerer:
;   AX : Lengden p† strengen
;
; Endrer innholdet i:
;   AX
;
PROC    strlen
        push    cx
        push    di
        push    es
        mov     cx, ds
        mov     es, cx
        mov     di, dx
        xor     al, al       ; Let etter 0'en
        mov     cx, 0FFFFh   ; S›k et helt segment om n›dvendig
        cld
        repne   scasb
        mov     ax, di
        dec     ax
        sub     ax, dx
        pop     es
        pop     di
        pop     cx
        ret
ENDP    strlen


        END
