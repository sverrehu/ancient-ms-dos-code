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

        PUBLIC  strcmp


;
; strcmp
;
; Hva prosedyren gjõr:
;   Sammenlikner to strenger.
;
; Kall med:
;   DS:SI - s1
;   ES:DI - s2
;
; Returnerer:
;   AX : Som C. AX = 0 => like
;               AX < 0 => s1 < s2
;               AX > 0 => s1 > s2
;
; Endrer innholdet i:
;   AX
;
PROC    strcmp
        push    cx
        push    dx
        push    di
        push    si

    ; Finn lengden pÜ en av strengene.
        mov     dx, si
        call    strlen

    ; ùk denne med 1, siden 0'en pÜ slutten ogsÜ teller.
        inc     ax
        mov     cx, ax

    ; Anta at like
        xor     ax, ax

    ; Sammenlikne strengene.
        cld
        repe    cmpsb

    ; Sett AX ut fra innholdet i flaggene.
        je      @@ret

        jc      @@s2_greatest

  @@s1_greatest:
        mov     ax, 1
        jmp     SHORT @@ret

  @@s2_greatest:
        mov     ax, -1

  @@ret:
        pop     si
        pop     di
        pop     dx
        pop     cx
        ret
ENDP    strcmp


        END
