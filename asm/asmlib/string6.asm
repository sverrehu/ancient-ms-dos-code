        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING



;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        PUBLIC  atoui


;
; atoui
;
; Hva prosedyren gj›r:
;   Konverterer en streng til en unsigned int (word)
;
; Kall med:
;   DS:DX - Peker til strengen
;
; Returnerer:
;   AX : Verdien.
;        Denne er 0 hvis ingen siffer fantes, eller 0FFFFh hvis
;        tallet er for stort.
;
; Endrer innholdet i:
;   AX
;
PROC    atoui
        push    bx
        push    dx
        push    si

        xor     ax, ax
        mov     si, dx

@@mer_igjen:
  ; Hent neste siffer
        mov     bl, [si]
        xor     bh, bh
        inc     si

  ; Sjekk om det er et siffer
        cmp     bl, '0'
        jb      @@ret
        cmp     bl, '9'
        ja      @@ret

  ; Gj›r om til tall
        sub     bl, '0'

  ; Multipliser AX med 10
        mov     dx, 10
        mul     dx
        jo      @@ret_overflow

  ; og legg til neste siffer
        add     ax, bx
        jo      @@ret_overflow

        jmp     @@mer_igjen

@@ret_overflow:
        mov     ax, 0FFFFh

@@ret:  pop     si
        pop     dx
        pop     bx
        ret
ENDP    atoui


        END
