        IDEAL

%       MODEL   MDL

        ASSUME  cs: @code, ds: @data, es: NOTHING


INCLUDE "SCRLOW.INC"  ; Makroer


        EXTRN   _init_scrlow: PROC
        EXTRN   getcurs: PROC


DATASEG

;-----------;
;           ;
;  D A T A  ;
;           ;
;-----------;

        EXTRN   init: BYTE
        EXTRN   vx1: BYTE, vy1: BYTE, vx2: BYTE, vy2: BYTE
        EXTRN   curx: BYTE, cury: BYTE
        EXTRN   txtattr: BYTE


CODESEG

;-----------------------;
;                       ;
;  P R O S E D Y R E R  ;
;                       ;
;-----------------------;


        PUBLIC  _insline, _delline, _clreol


;
; _insline
;
; setter inn blank linje ved mark›rposisjonen
;
; Definert som:
;     int  cdecl insline(void);
;
; Ingen registre ›delagt.
;
PROC    _insline
        SETT_DS
        TEST_INIT
        push    ax
        push    bx
        push    cx
        push    dx
        call    getcurs
        mov     ax, 0701h
        mov     bh, [txtattr]
        mov     cl, [vx1]
        mov     ch, [cury]
        mov     dl, [vx2]
        mov     dh, [vy2]
        int     10h
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        RESETT_DS
        ret
ENDP    _insline


;
; _delline
;
; fjerner linjen mark›ren st†r p†
;
; Definert som:
;     int  cdecl delline(void);
;
; Ingen registre ›delagt.
;
PROC    _delline
        SETT_DS
        TEST_INIT
        push    ax
        push    bx
        push    cx
        push    dx
        call    getcurs
        mov     ax, 0601h
        mov     bh, [txtattr]
        mov     cl, [vx1]
        mov     ch, [cury]
        mov     dl, [vx2]
        mov     dh, [vy2]
        int     10h
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        RESETT_DS
        ret
ENDP    _delline


;
; _clreol
;
; renser linjen mark›ren st†r p† fra mark›rposisjonen og ut
;
; Definert som:
;     int  cdecl clreol(void);
;
; Ingen registre ›delagt.
;
PROC    _clreol
        SETT_DS
        TEST_INIT
        push    ax
        push    bx
        push    cx
        push    dx
        call    getcurs
        mov     ax, 0600h
        mov     bh, [txtattr]
        mov     cl, [curx]
        mov     ch, [cury]
        mov     dl, [vx2]
        mov     dh, [cury]
        int     10h
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        RESETT_DS
        ret
ENDP    _clreol


        END
