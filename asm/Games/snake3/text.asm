        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING

; Setter opp konstanter og makroer som gjelder for mode 10h

INCLUDE "EGA10DEF.INC"


UDATASEG


leftmst DB      ?       ; F›rste X-verdi, for utf›ring av linjskift



DATASEG

        EXTRN   segadr: WORD

LABEL   chrs    BYTE

        DB      00000000b
        DB      00000000b
        DB      00000000b
        DB      00000000b
        DB      00000000b
        DB      00000000b

        DB      00010000b
        DB      00010000b
        DB      00010000b
        DB      00000000b
        DB      00010000b
        DB      00000000b

        DB      00101000b
        DB      00101000b
        DB      00000000b
        DB      00000000b
        DB      00000000b
        DB      00000000b

        DB      01000100b
        DB      11111110b
        DB      01000100b
        DB      11111110b
        DB      01000100b
        DB      00000000b

        DB      00111100b
        DB      01001000b
        DB      00111000b
        DB      00010100b
        DB      01111000b
        DB      00000000b

        DB      00000010b
        DB      01001100b
        DB      00010000b
        DB      01100100b
        DB      10000000b
        DB      00000000b

        DB      01110000b
        DB      10001000b
        DB      01110010b
        DB      10001100b
        DB      01111000b
        DB      00000000b

        DB      00001000b
        DB      00010000b
        DB      00000000b
        DB      00000000b
        DB      00000000b
        DB      00000000b

        DB      00001000b
        DB      00010000b
        DB      00010000b
        DB      00010000b
        DB      00001000b
        DB      00000000b

        DB      01000000b
        DB      00100000b
        DB      00100000b
        DB      00100000b
        DB      01000000b
        DB      00000000b

        DB      00000000b
        DB      00101000b
        DB      00010000b
        DB      00101000b
        DB      00000000b
        DB      00000000b

        DB      00000000b
        DB      00010000b
        DB      00111000b
        DB      00010000b
        DB      00000000b
        DB      00000000b

        DB      00000000b
        DB      00000000b
        DB      00000000b
        DB      00000000b
        DB      00010000b
        DB      00100000b

        DB      00000000b
        DB      00000000b
        DB      00111000b
        DB      00000000b
        DB      00000000b
        DB      00000000b

        DB      00000000b
        DB      00000000b
        DB      00000000b
        DB      00000000b
        DB      00100000b
        DB      00000000b

        DB      00000010b
        DB      00001100b
        DB      00010000b
        DB      01100000b
        DB      10000000b
        DB      00000000b

        DB      01111100b
        DB      10000010b
        DB      10000010b
        DB      10000010b
        DB      01111100b
        DB      00000000b

        DB      00010000b
        DB      00110000b
        DB      00010000b
        DB      00010000b
        DB      00111000b
        DB      00000000b

        DB      01111100b
        DB      10000010b
        DB      00001100b
        DB      01110000b
        DB      11111110b
        DB      00000000b

        DB      11111110b
        DB      00001100b
        DB      00111100b
        DB      10000010b
        DB      01111100b
        DB      00000000b

        DB      00011100b
        DB      01100100b
        DB      11111110b
        DB      00000100b
        DB      00000100b
        DB      00000000b

        DB      11111100b
        DB      10000000b
        DB      01111100b
        DB      00000010b
        DB      11111100b
        DB      00000000b

        DB      01111100b
        DB      10000000b
        DB      11111100b
        DB      10000010b
        DB      01111100b
        DB      00000000b

        DB      11111110b
        DB      00000110b
        DB      00011000b
        DB      01100000b
        DB      10000000b
        DB      00000000b

        DB      01111100b
        DB      10000010b
        DB      01111100b
        DB      10000010b
        DB      01111100b
        DB      00000000b

        DB      01111100b
        DB      10000010b
        DB      01111110b
        DB      00000010b
        DB      01111100b
        DB      00000000b

        DB      00000000b
        DB      00010000b
        DB      00000000b
        DB      00000000b
        DB      00010000b
        DB      00000000b

        DB      00000000b
        DB      00010000b
        DB      00000000b
        DB      00000000b
        DB      00010000b
        DB      00100000b

        DB      00010000b
        DB      00100000b
        DB      01000000b
        DB      00100000b
        DB      00010000b
        DB      00000000b

        DB      00000000b
        DB      00111000b
        DB      00000000b
        DB      00111000b
        DB      00000000b
        DB      00000000b

        DB      00100000b
        DB      00010000b
        DB      00001000b
        DB      00010000b
        DB      00100000b
        DB      00000000b

        DB      01111100b
        DB      10000010b
        DB      00011100b
        DB      00000000b
        DB      00010000b
        DB      00000000b

        DB      01111100b
        DB      10100010b
        DB      10111100b
        DB      10000000b
        DB      01111100b
        DB      00000000b

        DB      00111000b
        DB      01000100b
        DB      11111110b
        DB      10000010b
        DB      10000010b
        DB      00000000b

        DB      11111100b
        DB      01000010b
        DB      01111100b
        DB      01000010b
        DB      11111100b
        DB      00000000b

        DB      01111110b
        DB      10000000b
        DB      10000000b
        DB      10000000b
        DB      01111110b
        DB      00000000b

        DB      11111100b
        DB      01000010b
        DB      01000010b
        DB      01000010b
        DB      11111100b
        DB      00000000b

        DB      11111110b
        DB      01000000b
        DB      01111000b
        DB      01000000b
        DB      11111110b
        DB      00000000b

        DB      11111110b
        DB      01000000b
        DB      01111000b
        DB      01000000b
        DB      01000000b
        DB      00000000b

        DB      01111110b
        DB      10000000b
        DB      10000110b
        DB      10000010b
        DB      01111110b
        DB      00000000b

        DB      10000010b
        DB      10000010b
        DB      11111110b
        DB      10000010b
        DB      10000010b
        DB      00000000b

        DB      00111000b
        DB      00010000b
        DB      00010000b
        DB      00010000b
        DB      00111000b
        DB      00000000b

        DB      00001000b
        DB      00001000b
        DB      00001000b
        DB      01001000b
        DB      00110000b
        DB      00000000b

        DB      10000110b
        DB      10011000b
        DB      11100000b
        DB      10011000b
        DB      10000110b
        DB      00000000b

        DB      10000000b
        DB      10000000b
        DB      10000000b
        DB      10000000b
        DB      11111110b
        DB      00000000b

        DB      11000110b
        DB      10101010b
        DB      10010010b
        DB      10000010b
        DB      10000010b
        DB      00000000b

        DB      11000010b
        DB      10100010b
        DB      10010010b
        DB      10001010b
        DB      10000110b
        DB      00000000b

        DB      01111100b
        DB      10000010b
        DB      10000010b
        DB      10000010b
        DB      01111100b
        DB      00000000b

        DB      11111100b
        DB      01000010b
        DB      01111100b
        DB      01000000b
        DB      01000000b
        DB      00000000b

        DB      01111100b
        DB      10000010b
        DB      10001010b
        DB      10000110b
        DB      01111110b
        DB      00000000b

        DB      11111100b
        DB      01000010b
        DB      01111100b
        DB      01001000b
        DB      01000110b
        DB      00000000b

        DB      01111110b
        DB      10000000b
        DB      01111100b
        DB      00000010b
        DB      11111100b
        DB      00000000b

        DB      11111110b
        DB      00010000b
        DB      00010000b
        DB      00010000b
        DB      00010000b
        DB      00000000b

        DB      10000010b
        DB      10000010b
        DB      10000010b
        DB      10000010b
        DB      01111100b
        DB      00000000b

        DB      10000010b
        DB      01000100b
        DB      01000100b
        DB      00101000b
        DB      00010000b
        DB      00000000b

        DB      10000010b
        DB      10000010b
        DB      10010010b
        DB      10101010b
        DB      01000100b
        DB      00000000b

        DB      10000010b
        DB      01101100b
        DB      00010000b
        DB      01101100b
        DB      10000010b
        DB      00000000b

        DB      10000010b
        DB      01101100b
        DB      00010000b
        DB      00010000b
        DB      00010000b
        DB      00000000b

        DB      11111110b
        DB      00001100b
        DB      00010000b
        DB      01100000b
        DB      11111110b
        DB      00000000b


CODESEG

        PUBLIC  showchr8x6, showtxt8x6, shownum8x6


;
; showchr8x6
;
; Hva prosedyren gj›r:
;   Viser et tegn i angitte koordinater
;
; Kall med:
;   DL : X-koordinat  (0-79)
;   DH : Y-koordinat  (0-57)
;   AL : ASCII-koden til tegnet
;   AH : Fargekode (0-15)
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   bitmask
;
ALIGN WORD
PROC    showchr8x6
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    si
        push    es

  ; Beregn skjermadressen og legg denne i DI. Dette er 80*6*y+x, som er
  ; 480*y+x, som er 512*y-32*y+x=(y<<8)<<2-y<<5+x
        mov     cl, dl
        xor     ch, ch
        mov     di, cx

        mov     bl, dh
        xor     bh, bh
        mov     cl, 5
        shl     bx, cl
        xor     dl, dl
        add     dx, dx
        sub     dx, bx
        add     di, dx

  ; Hent adressen til tegnet, og legg denne i SI
        push    ax
        sub     al, 32  ; F›rste tegnet er space
        mov     bl, 6
        mul     bl
        mov     bx, ax
        pop     ax
        mov     si, bx
        add     si, OFFSET chrs

        mov     es, [segadr]
        mov     dx, SEQAP
        mov     al, MAPMSK
        out     dx, ax
        mov     dx, GCONAP
        mov     ax, ESETRES + 0 * 256
        out     dx, ax

  ; Tegn selve figuren ved † vise de fire bitplanene i riktig farge
        mov     cx, 6
        cld
@@l3:   lodsb
        mov     [es: di], al
        add     di, 80
        loop    @@l3

        mov     ax, ESETRES + 15 * 256
        out     dx, ax
        mov     dx, SEQAP
        mov     ax, MAPMSK + 15 * 256
        out     dx, ax

@@ret:  pop     es
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    showchr8x6


;
; showtxt8x6
;
; Hva prosedyren gj›r:
;   Viser en ASCIIZ-string i angitt posisjon.
;
; Kall med:
;   DL : X-pos
;   DH : Y-pos
;   AH : Fargekode
;   SI : Peker til tegnstrengen
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    showtxt8x6
        push    ax
        push    dx
        push    si

  ; Ta vare p† f›rste X-verdi, slik at det er mulig † utf›re CR siden.
        mov     [leftmst], dl

@@fler_tegn:
        mov     al, [si]
        inc     si
        or      al, al
        jz      @@ret

  ; Sjekk om spesialtegn
        cmp     al, 11  ; Ny farge
        je      @@new_color
        cmp     al, 13
        je      @@do_CR
        cmp     al, 10
        je      @@do_LF

        jmp     SHORT @@normalt_tegn

@@new_color:
  ; Neste tegn er ny fargekode.
        mov     ah, [si]
        inc     si
        jmp     @@fler_tegn

@@do_LF:
  ; Utf›r linjeskift
        inc     dh
        jmp     @@fler_tegn

@@do_CR:
  ; Utf›r carriage return
        mov     dl, [leftmst]
        jmp     @@fler_tegn

@@normalt_tegn:
        call    showchr8x6
        inc     dl
        jmp     @@fler_tegn

@@ret:  pop     si
        pop     dx
        pop     ax
        ret
ENDP    showtxt8x6



;
; shownum8x6
;
; Hva prosedyren gj›r:
;   Viser et tall, h›yrejustert til 5 plasser.
;
; Kall med:
;   DL : X-pos for venstre siffer
;   DH : Y-pos
;   AX : Tallet som skal vises
;   CL : Fargen p† tallet
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    shownum8x6
        push    ax
        push    bx
        push    dx
        push    bp

        mov     bp, dx  ; For sammenlikning
        add     dl, 4   ; Posisjon til siste siffer

@@mer_igjen:
        push    dx
        xor     dx, dx
        mov     bx, 10
        div     bx
        mov     bx, dx
        pop     dx

        push    ax
        mov     ah, cl
        mov     al, bl
        add     al, '0'
        call    showchr8x6
        pop     ax

        dec     dl
        or      ax, ax
        jnz     @@mer_igjen

  ; Fyll ut med blanke
        mov     ah, cl
        mov     al, ' '

@@skriv_blank:
        cmp     dx, bp
        jb      @@ret
        call    showchr8x6
        dec     dl
        jmp     @@skriv_blank

@@ret:  pop     bp
        pop     dx
        pop     bx
        pop     ax
        ret
ENDP    shownum8x6



ENDS

        END
