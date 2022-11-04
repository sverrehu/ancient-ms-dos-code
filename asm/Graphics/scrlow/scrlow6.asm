        IDEAL

%       MODEL   MDL

        ASSUME  cs: @code, ds: @data, es: NOTHING


INCLUDE "SCRLOW.INC"  ; Makroer


        EXTRN   _init_scrlow: PROC
        EXTRN   setcurs: PROC, getcurs: PROC


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

        PUBLIC  _window, _clrscr, _gotoxy, _wherex, _wherey


;
; _window
;
; setter koordinater for skjerm-vinduet.
;
; Definert som:
;     void  cdecl window(int x1, int y1, int x2, int y2);
;
; Ingen registre ›delagt
;
PROC    _window
        ARG     x1: WORD, y1: WORD, x2: WORD, y2: WORD
        push    bp
        mov     bp, sp
        push    ax
        SETT_DS
        TEST_INIT
        mov     ax, [x1]
        dec     al
        mov     [vx1], al
        mov     [curx], al
        mov     ax, [y1]
        dec     al
        mov     [vy1], al
        mov     [cury], al
        mov     ax, [x2]
        dec     al
        mov     [vx2], al
        mov     ax, [y2]
        dec     al
        mov     [vy2], al
        call    setcurs
        RESETT_DS
        pop     ax
        pop     bp
        ret
ENDP    _window


;
; _clrscr
;
; renser hele vinduet til attributten i [txtattr].
;
; Definert som:
;     void  cdecl clrscr(void);
;
; Ingen registre ›delagt.
;
PROC    _clrscr
        SETT_DS
        TEST_INIT
        push    ax
        push    bx
        push    cx
        push    dx
        mov     ax, 0600h
        mov     bh, [txtattr]
        mov     cl, [vx1]
        mov     ch, [vy1]
        mov     dl, [vx2]
        mov     dh, [vy2]
        int     10h
        mov     al, [vx1]
        mov     [curx], al
        mov     al, [vy1]
        mov     [cury], al
        call    setcurs
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        RESETT_DS
        ret
ENDP    _clrscr


;
; _gotoxy
;
; endrer mark›rposisjonen til angitte koordinater.
;
; Definert som:
;     void  cdecl gotoxy(int x, int y);
;
; Ingen registre ›delagt.
;
PROC    _gotoxy
        ARG     x: WORD, y: WORD
        push    bp
        mov     bp, sp
        SETT_DS
        TEST_INIT
        push    ax
        push    bx
        xor     ah, ah
        mov     al, [vx1]
        add     ax, [x]
        dec     ax
        cmp     al, [vx2]
        ja      @@ret
        xor     bh, bh
        mov     bl, [vy1]
        add     bx, [y]
        dec     bx
        cmp     bl, [vy2]
        ja      @@ret
        mov     [curx], al
        mov     [cury], bl
        call    setcurs
@@ret:  pop     bx
        pop     ax
        RESETT_DS
        pop     bp
        ret
ENDP    _gotoxy


;
; _wherex
;
; returnerer [curx] + 1 - [vx1].
;
; Definert som:
;     int  cdecl wherex(void);
;
; Ingen registre ›delagt.
;
PROC    _wherex
        SETT_DS
        TEST_INIT
        mov     al, [curx]
        inc     al
        sub     al, [vx1]
        xor     ah, ah
        RESETT_DS
        ret
ENDP    _wherex


;
; _wherey
;
; returnerer [cury] + 1 - [vy1].
;
; Definert som:
;     int  cdecl wherey(void);
;
; Ingen registre ›delagt.
;
PROC    _wherey
        SETT_DS
        TEST_INIT
        mov     al, [cury]
        inc     al
        sub     al, [vy1]
        xor     ah, ah
        RESETT_DS
        ret
ENDP    _wherey


        END
