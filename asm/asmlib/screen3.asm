        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING




;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        PUBLIC  outword

        EXTRN   lowchar: PROC, setcurs: PROC



;
; outword
;
; Hva prosedyren gjõr:
;   Viser et heltall (unsigned) pÜ skjermen.
;
; Kall med:
;   AX : ùnsket tall
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    outword
        push    ax
        push    bx
        push    cx
        push    dx

        or      ax, ax     ; Er tallet bare 0 ?
        jnz     @@ikke_0
        mov     al, '0'
        call    lowchar
        jmp     SHORT @@ret
@@ikke_0:
        mov     cx, 10000
        xor     bl, bl     ; BL=0 : Ikke vis nuller, BL=1 vis nuller

@@lokke:
        xor     dx, dx
        div     cx

        or      ax, ax     ; Er sifferet 0 ?
        jnz     @@vis_siffer
        or      bl, bl
        jz      @@neste
@@vis_siffer:
        add     al, '0'
        call    lowchar
        mov     bl, 1      ; Videre nuller skal vises
@@neste:
        mov     ax, dx     ; Bruk resten av forrige divisjon
        push    ax
        mov     ax, cx
        mov     cx, 10
        xor     dx, dx
        div     cx
        mov     cx, ax
        pop     ax
        jcxz    @@ret
        jmp     @@lokke

@@ret:  call    setcurs
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    outword


        END
