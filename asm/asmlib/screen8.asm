        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING



NORSK   EQU     0       ; Skal norsk ù defineres for 43/50-mode ?



;--------------------------;
;                          ;
;         D A T A          ;
;                          ;
;--------------------------;

UDATASEG

mode    DW      ?            ; Midlertidig lagerplass for õnsket mode





DATASEG


IF NORSK
l_oe    DB      00000000b    ; Definisjon av liten õ i 8x8 tegnsett
        DB      00000000b
        DB      01111100b
        DB      11001110b
        DB      11010110b
        DB      11100110b
        DB      01111100b
        DB      00000000b

s_oe    DB      00111010b    ; Definisjon av stor ù i 8x8 tegnsett
        DB      01101100b
        DB      11001110b
        DB      11010110b
        DB      11100110b
        DB      01101100b
        DB      10111000b
        DB      00000000b
ENDIF





;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        PUBLIC  textmode

        EXTRN   initscreen: PROC
        EXTRN   screenrows: PROC, screencols: PROC




;
; textmode
;
; Hva prosedyren gjõr:
;   Setter angitt tekstmodus. Hvis õnsket mode > 0100h, forsõkes det med
;   43/50 linjer.
;
; Kall med:
;   AX : ùnsket modus
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    textmode
        mov     [mode], ax
        push    ax
        push    bx
        push    cx
        push    dx
        push    bp
        push    es

        xor     ah, ah              ; Set video mode
        int     10h

        mov     ax, [mode]          ; Er 43/50 linjer õnsket?
        test    ah, 1
        jz      @@ret

        mov     ah, 12h             ; Sjekk om EGA/VGA finnes
        mov     bl, 10h
        int     10h
        cmp     bl, 10h
        je      @@ret               ; Fant ikke EGA - hopp ut

@@EGA_funnet:
        mov     ax, 0500h           ; Sett page 0 aktiv
        int     10h

        mov     ax, 1112h           ; Sett opp til 8x8 character set
        xor     bl, bl
        int     10h

IF NORSK
        mov     bh, 8               ; Omdefiner liten õ
        xor     bl, bl
        mov     cx, 1
        mov     dx, 'õ'
        mov     ax, ds
        mov     es, ax
        mov     bp, OFFSET l_oe
        mov     ax, 1110h
        int     10h

        mov     dx, 'ù'             ; Omdefiner stor ù
        mov     bp, OFFSET s_oe
        mov     ax, 1110h
        int     10h
ENDIF

        xor     ax, ax              ; Riktig markõr
        mov     es, ax
        cmp     [BYTE es: 0484h], 42; Er det 43 (42 + 1) linjer?
        jne     @@ikke_43linjer
        mov     bl, [es: 0487h]     ; IsÜfall sett markõr for EGA 43 linjer.
        or      [BYTE es: 0487h], 1
        mov     ah, 1
        mov     cx, 0600h
        int     10h
        mov     [es: 0487h], bl
@@ikke_43linjer:                    ; VGA fikser markõren selv.
        mov     dx, 03D4h           ; Juster understrek-linjen
        mov     ax, 0714h
        out     dx, ax

@@ret:  call    initscreen
        pop     es
        pop     bp
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    textmode


        END
