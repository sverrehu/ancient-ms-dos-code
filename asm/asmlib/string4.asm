        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING



;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        PUBLIC  strupr


;
; strupr
;
; Hva prosedyren gj›r:
;   Oversetter en streng til store bokstaver. Norske tegn blir _ikke_ riktig.
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
PROC    strupr
        push    ax
        push    si
        push    di
        push    es
        push    ds
        pop     es
        mov     si, dx
        mov     di, dx
        cld
@@neste:
        lodsb
        or      al, al
        jz      @@ret
        cmp     al, 'a'
        jb      @@lagre
        cmp     al, 'z'
        ja      @@lagre
        sub     al, 'a' - 'A'
@@lagre:
        stosb
        jmp     @@neste
@@ret:  pop     es
        pop     di
        pop     si
        pop     ax
        ret
ENDP    strupr


        END
