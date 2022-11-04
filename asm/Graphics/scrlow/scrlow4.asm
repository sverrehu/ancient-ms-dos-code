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
        EXTRN   txtattr: BYTE



CODESEG

;-----------------------;
;                       ;
;  P R O S E D Y R E R  ;
;                       ;
;-----------------------;

        PUBLIC  _textattr, _textcolor, _textbackground


;
; _textattr
;
; endrer attributten i [txtattr], slik at senere utskrift f†r ›nsket farge.
;
; Definert som:
;     void  cdecl textattr(int attr);
;
; Ingen registre ›delagt.
;
PROC    _textattr
        ARG     attr: WORD
        push    bp
        mov     bp, sp
        SETT_DS
        TEST_INIT
        push    ax
        mov     ax, [attr]
        mov     [txtattr], al
        pop     ax
        RESETT_DS
        pop     bp
        ret
ENDP    _textattr


;
; _textcolor
;
; endrer forgrunnsfargen i [txtattr], slik at senere utskrift f†r ›nsket farge.
;
; Definert som:
;     void  cdecl textcolor(int color);
;
; Ingen registre ›delagt.
;
PROC    _textcolor
        ARG     color: WORD
        push    bp
        mov     bp, sp
        SETT_DS
        TEST_INIT
        push    ax
        mov     ax, [color]
        and     al, 15
        and     [BYTE txtattr], 240
        or      [txtattr], al
        pop     ax
        RESETT_DS
        pop     bp
        ret
ENDP    _textcolor


;
; _textbackground
;
; endrer forgrunnsfargen i [txtattr], slik at senere utskrift f†r ›nsket farge.
;
; Definert som:
;     void  cdecl textbackground(int color);
;
; Ingen registre ›delagt.
;
PROC    _textbackground
        ARG     color: WORD
        push    bp
        mov     bp, sp
        SETT_DS
        TEST_INIT
        push    ax
        push    cx
        mov     ax, [color]
        and     al, 15
        mov     cl, 4
        shl     al, cl
        and     [BYTE txtattr], 15
        or      [txtattr], al
        pop     cx
        pop     ax
        RESETT_DS
        pop     bp
        ret
ENDP    _textbackground



        END
