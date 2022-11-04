        IDEAL

%       MODEL   MDL

        ASSUME  cs: @code, ds: @data, es: NOTHING

STRUC   text_info
        winleft      DB ?
        wintop       DB ?
        winright     DB ?
        winbottom    DB ?
        attribute    DB ?
        normattr     DB ?
        currmode     DB ?
        screenheight DB ?
        screenwidth  DB ?
        curx         DB ?
        cury         DB ?
ENDS    text_info

INCLUDE "SCRLOW.INC"  ; Makroer


        EXTRN   _init_scrlow: PROC
        EXTRN   _screenrows: PROC, _screencols: PROC
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
        EXTRN   stdattr: BYTE


CODESEG

;-----------------------;
;                       ;
;  P R O S E D Y R E R  ;
;                       ;
;-----------------------;

        PUBLIC  _gettextinfo


;
; _gettextinfo
;
; finner diverse opplysninger om skjermen
;
; Definert som:
;     void  cdecl gettextinfo(struct text_info  *ti);
;
; Ingen registre ›delagt.
;
PROC    _gettextinfo
        IF @DataSize NE 0
            ARG     ti: DWORD
        ELSE
            ARG     ti: WORD
        ENDIF
        push    bp
        mov     bp, sp
        SETT_DS
        TEST_INIT
        push    ax
        push    bx
        IF @DataSize NE 0
            les     bx, [ti]
        ELSE
            mov     bx, [ti]
            push    ds
            pop     es
        ENDIF
        call    getcurs
        mov     al, [vx1]
        inc     al
        mov     [es: (text_info PTR bx).winleft], al
        mov     al, [vy1]
        inc     al
        mov     [es: (text_info PTR bx).wintop], al
        mov     al, [vx2]
        inc     al
        mov     [es: (text_info PTR bx).winright], al
        mov     al, [vy2]
        inc     al
        mov     [es: (text_info PTR bx).winbottom], al
        mov     al, [txtattr]
        mov     [es: (text_info PTR bx).attribute], al
        mov     al, [stdattr]
        mov     [es: (text_info PTR bx).normattr], al
        push    ds
        xor     ax, ax
        mov     ds, ax
        mov     al, [0449h]
        pop     ds
        mov     [es: (text_info PTR bx).currmode], al
        call    _screenrows
        mov     [es: (text_info PTR bx).screenheight], al
        call    _screencols
        mov     [es: (text_info PTR bx).screenwidth], al
        mov     al, [curx]
        sub     al, [vx1]
        inc     al
        mov     [es: (text_info PTR bx).curx], al
        mov     al, [cury]
        sub     al, [vy1]
        inc     al
        mov     [es: (text_info PTR bx).cury], al
@@ret:  pop     bx
        pop     ax
        RESETT_DS
        pop     bp
        ret
ENDP    _gettextinfo



        END
