        IDEAL

%       MODEL   MDL

        ASSUME  cs: @code, ds: @data, es: NOTHING


INCLUDE "SCRLOW.INC"  ; Makroer

        EXTRN   _init_scrlow: PROC


DATASEG

;-----------;
;           ;
;  D A T A  ;
;           ;
;-----------;

        EXTRN   init: BYTE
        EXTRN   antkol2: WORD
        EXTRN   sadr: DWORD


CODESEG

;-----------------------;
;                       ;
;  P R O S E D Y R E R  ;
;                       ;
;-----------------------;

        PUBLIC  _wrtscreen, _rdscreen


;
; _wrtscreen
;
; Viser tegnet c med attributten a i posisjonen (x, y).
;
; Definert som:
;     void  cdecl wrtscreen(int c, int a, int x, int y);
;
; Ingen registre ›delagt.
;
PROC    _wrtscreen
        ARG     c: WORD, a: WORD, x: WORD, y: WORD
        push    bp
        mov     bp, sp
        SETT_DS
        TEST_INIT
        push    ax
        push    bx
        push    di
        push    es
        mov     ax, [y]
        mov     bx, [antkol2]
        mul     bx
        mov     bx, [x]
        shl     bx, 1
        add     ax, bx
        les     di, [DWORD sadr]
        add     di, ax
        mov     ax, [c]
        mov     bx, [a]
        mov     ah, bl
        mov     [es: di], ax
@@ret:  pop     es
        pop     di
        pop     bx
        pop     ax
        RESETT_DS
        pop     bp
        ret
ENDP    _wrtscreen


;
; _rdscreen
;
; Returnerer tegnet i posisjonen (x, y).
;
; Definert som:
;     int  cdecl rdscreen(int x, int y);
;
; Ingen registre ›delagt.
;
PROC    _rdscreen
        ARG     x: WORD, y: WORD
        push    bp
        mov     bp, sp
        SETT_DS
        TEST_INIT
        push    bx
        push    di
        push    es
        mov     ax, [y]
        mov     bx, [antkol2]
        mul     bx
        mov     bx, [x]
        shl     bx, 1
        add     ax, bx
        les     di, [DWORD sadr]
        add     di, ax
        mov     al, [es: di]
        xor     ah, ah
@@ret:  pop     es
        pop     di
        pop     bx
        RESETT_DS
        pop     bp
        ret
ENDP    _rdscreen




        END
