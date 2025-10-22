        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING



;--------------------------;
;                          ;
;         D A T A          ;
;                          ;
;--------------------------;

UDATASEG

        EXTRN   txtattr: BYTE





;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        PUBLIC  textattr, textcolor, textbackground



;
; textattr
;
; Hva prosedyren gjõr:
;   Endrer attributten for senere utskrift
;
; Kall med:
;   AL : ùnsket attributt
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    textattr
        mov     [txtattr], al
        ret
ENDP    textattr


;
; textcolor
;
; Hva prosedyren gjõr:
;   Endrer forgrunnsfargen for senere utskrift
;
; Kall med:
;   AL : Ny forgrunnsfarge
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    textcolor
        push    ax
        and     al, 00001111b
        and     [BYTE txtattr], 11110000b
        or      [txtattr], al
        pop     ax
        ret
ENDP    textcolor


;
; textbackground
;
; Hva prosedyren gjõr:
;   Endrer bakgrunnsfargen for senere utskrift
;
; Kall med:
;   AL : Ny bakgrunnsfarge
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    textbackground
        push    ax
        push    cx
        mov     cl, 4
        shl     al, cl
        and     [BYTE txtattr], 00001111b
        or      [txtattr], al
        pop     cx
        pop     ax
        ret
ENDP    textbackground


        END
