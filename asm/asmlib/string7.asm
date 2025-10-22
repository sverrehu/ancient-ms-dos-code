        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING



;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        PUBLIC  strcat


;
; strcat
;
; Hva prosedyren gj›r:
;   Legger en streng p† slutten av en annen
;
; Kall med:
;   ES:DI - Peker til strengen
;   DS:SI - Peker til det som skal legges til
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    strcat
        push    ax
        push    cx
        push    di
        push    si

        xor     al, al       ; Let etter 0'en
        mov     cx, 0FFFFh   ; S›k et helt segment om n›dvendig
        cld
        repne   scasb

    ; Nullen skal v‘re funnet, s† ingen testing utf›res.
        dec     di

  @@next_char:
        lodsb
        stosb
        or      al, al
        jnz     @@next_char

        pop     si
        pop     di
        pop     cx
        pop     ax
        ret
ENDP    strcat


        END
