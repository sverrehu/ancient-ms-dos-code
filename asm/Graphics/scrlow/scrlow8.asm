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

        PUBLIC  _gettext, _puttext


;
; _gettext
;
; kopierer tekst fra angitt omr†de p† skjermen til angitt buffer.
;
; Definert som:
;     void gettext(int x1, int y1, int x2, int y2, void *buf);
;
; Ingen registre ›delagt
;
PROC    _gettext
        IF @DataSize NE 0
            ARG     x1: WORD, y1: WORD, x2: WORD, y2: WORD, buf: DWORD
        ELSE
            ARG     x1: WORD, y1: WORD, x2: WORD, y2: WORD, buf: WORD
        ENDIF
        push    bp
        mov     bp, sp
        SETT_DS
        TEST_INIT
        push    ax
        push    bx
        push    cx
        push    dx
        push    es
        push    ds
        push    si
        push    di
        IF @DataSize NE 0
            les     di, [buf]
        ELSE
            mov     di, [buf]
            push    ds
            pop     es
        ENDIF
        mov     ax, [y1]
        dec     ax
        mov     bx, [antkol2]
        mul     bx
        mov     bx, [x1]
        dec     bx
        shl     bx, 1
        add     ax, bx
        push    [antkol2]
        lds     si, [DWORD sadr]
        add     si, ax
        pop     ax      ; antkol2
        mov     cx, [y2]
        sub     cx, [y1]
        inc     cx
@@l1:   push    cx
        mov     cx, [x2]
        sub     cx, [x1]
        inc     cx
        push    si
        cld
        rep     movsw
        pop     si
        add     si, ax
        pop     cx
        loop    @@l1
        pop     di
        pop     si
        pop     ds
        pop     es
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        RESETT_DS
        pop     bp
        ret
ENDP    _gettext


;
; _puttext
;
; kopierer tekst fra angitt omr†de p† skjermen til angitt buffer.
;
; Definert som:
;     void puttext(int x1, int y1, int x2, int y2, void *buf);
;
; Ingen registre ›delagt
;
PROC    _puttext
        IF @DataSize NE 0
            ARG     x1: WORD, y1: WORD, x2: WORD, y2: WORD, buf: DWORD
        ELSE
            ARG     x1: WORD, y1: WORD, x2: WORD, y2: WORD, buf: WORD
        ENDIF
        push    bp
        mov     bp, sp
        SETT_DS
        TEST_INIT
        push    ax
        push    bx
        push    cx
        push    dx
        push    es
        push    ds
        push    si
        push    di
        mov     ax, [y1]
        dec     ax
        mov     bx, [antkol2]
        mul     bx
        mov     bx, [x1]
        dec     bx
        shl     bx, 1
        add     ax, bx
        les     di, [DWORD sadr]
        add     di, ax
        mov     ax, [antkol2]
        mov     cx, [y2]
        sub     cx, [y1]
        inc     cx
        IF @DataSize NE 0
            lds     si, [buf]
        ELSE
            mov     si, [buf]
        ENDIF
@@l1:   push    cx
        mov     cx, [x2]
        sub     cx, [x1]
        inc     cx
        push    di
        cld
        rep     movsw
        pop     di
        add     di, ax
        pop     cx
        loop    @@l1
        pop     di
        pop     si
        pop     ds
        pop     es
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        RESETT_DS
        pop     bp
        ret
ENDP    _puttext


        END
