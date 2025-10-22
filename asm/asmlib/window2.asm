        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING



INCLUDE "WINDOW.INC"



;--------------------------;
;                          ;
;         D A T A          ;
;                          ;
;--------------------------;

UDATASEG

        EXTRN   vx1: BYTE, vy1: BYTE, vx2: BYTE, vy2: BYTE
        EXTRN   curx: BYTE, cury: BYTE
        EXTRN   txtattr: BYTE

        EXTRN   ramme: BYTE, wtattr: BYTE, wrattr: BYTE
        EXTRN   upleft: WORD, loright: WORD





;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        PUBLIC  bordertext, drawborder

        EXTRN   window     : PROC, gotoxy    : PROC
        EXTRN   wherex     : PROC, wherey    : PROC
        EXTRN   outtext    : PROC
        EXTRN   strlen     : PROC

        EXTRN   draw_border: PROC



;
; bordertext
;
; Hva prosedyren gj›r:
;   Viser tekst p† vindusrammen til n†v‘rende vindu
;
; Kall med:
;   AL    : 0 = Sentrert, topp
;           1 = Venstre, topp
;           2 = H›yre, topp
;           3 = Sentrert, bunn
;           4 = Venstre, bunn
;           5 = H›yre, bunn
;   CH    : Attributt
;   DS:DX : Peker til teksten (ASCIIZ). Teksten m† v‘re liten nok til at hele
;           f†r plass p† rammen.
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    bordertext
        push    ax
        push    bx
        push    cx
        push    dx
        cmp     [ramme], 0      ; Kan ikke sette tekst p† ramme som
        jne     @@vistekst      ; ikke finnes
        jmp     @@ret
@@vistekst:
  ; Spar n†v‘rende mark›rposisjon
        mov     bx, ax
        call    wherex
        call    wherey
        push    ax
        mov     ax, bx
  ; Sett window slik at det er mulig † skrive p† rammen.
        push    ax
        push    dx
        mov     ax, [upleft]
        dec     al
        dec     ah
        mov     dx, [loright]
        inc     dl
        inc     dh
        call    window
        pop     dx
        pop     ax
  ; Endre txtattr til ›nsket attributt
        mov     bl, [txtattr]
        push    bx
        mov     [txtattr], ch

        mov     bl, al          ; Posisjonskode i BL
        mov     al, 1           ; Anta venstre side
        cmp     bl, 1
        je      @@finn_bunn
        cmp     bl, 4
        je      @@finn_bunn
        call    strlen
        mov     bh, [vx2]
        sub     bh, [vx1]
        or      bl, bl
        jz      @@senter
        cmp     bl, 3
        je      @@senter
@@hoyre:
        sub     bh, al
        mov     al, bh
        jmp     SHORT @@finn_bunn
@@senter:
        inc     bh
    ;    inc     al
        shr     bh, 1
        shr     al, 1
        sub     bh, al
        mov     al, bh
@@finn_bunn:
        xor     ah, ah          ; Anta ›verst
        cmp     bl, 2
        jbe     @@toppen
        mov     ah, [vy2]
        sub     ah, [vy1]
@@toppen:
        call    gotoxy
        call    outtext
  ; Sett tilbake tidligere attributt
        pop     bx
        mov     [txtattr], bl
  ; Sett window tilbake til innenfor rammen
        mov     ax, [upleft]
        mov     dx, [loright]
        call    window
  ; Sett tilbake mark›rposisjonen
        pop     ax
        call    gotoxy
@@ret:  pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    bordertext


;
; drawborder
;
; Hva prosedyren gj›r:
;   Tegner rammen p† n†v‘rende vindu.
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
PROC    drawborder
        push    ax
        push    bx
        push    dx
        cmp     [ramme], 0
        je      @@ret
        mov     al, [txtattr]
        push    ax
        mov     al, [wrattr]
        mov     [txtattr], al
        mov     bl, [ramme]
        mov     ax, [upleft]
        dec     al
        dec     ah
        mov     dx, [loright]
        inc     dl
        inc     dh
        call    draw_border
        pop     ax
        mov     [txtattr], al
@@ret:  pop     dx
        pop     bx
        pop     ax
        ret
ENDP    drawborder


        END
