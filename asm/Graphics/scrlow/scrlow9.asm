        IDEAL

%       MODEL   MDL

        ASSUME  cs: @code, ds: @data, es: NOTHING


INCLUDE "SCRLOW.INC"  ; Makroer

NORSK   EQU     0     ; Skal norsk ù lages ved 43/50-mode ?


        EXTRN   _init_scrlow: PROC
        EXTRN   _screenrows: PROC, _screencols: PROC


DATASEG

;-----------;
;           ;
;  D A T A  ;
;           ;
;-----------;

        EXTRN   init: BYTE

;
; Riktig õ/ù pÜ 43/50-linjer skjerm
;
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



CODESEG

;-----------------------;
;                       ;
;  P R O S E D Y R E R  ;
;                       ;
;-----------------------;

        PUBLIC  _textmode


;
; _textmode
;
; setter angitt (tekst)modus
; Hvis mode>0100h -> Forsõker pÜ 43/50 linjer.
;
; Definert som:
;     void  cdecl textmode(int mode);
;
; Ingen registre õdelagt.
;
PROC    _textmode
        ARG     mode: WORD
        push    bp
        mov     bp, sp
        SETT_DS
        TEST_INIT

        push    ax
        push    bx
        push    cx
        push    dx
        push    es

        mov     ax, [mode]
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

@@ret:  call    _init_scrlow

        pop     es
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        RESETT_DS
        pop     bp
        ret
ENDP    _textmode


        END
