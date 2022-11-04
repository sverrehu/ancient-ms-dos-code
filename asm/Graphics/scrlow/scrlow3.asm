        IDEAL

%       MODEL   MDL

        ASSUME  cs: @code, ds: @data, es: NOTHING


INCLUDE "SCRLOW.INC"  ; Makroer

        EXTRN   _init_scrlow: PROC
        EXTRN   setcurs: PROC, getcurs: PROC, vistegn: PROC


DATASEG

;-----------;
;           ;
;  D A T A  ;
;           ;
;-----------;

        EXTRN   init: BYTE



CODESEG

;-----------------------;
;                       ;
;  P R O S E D Y R E R  ;
;                       ;
;-----------------------;


        PUBLIC  _putch, _cputs


;
; _putch
;
; viser angitt tegn p† skjermen (i n†v‘rende vindu), og bytter
; linje/scroller hvis n›dvendig.
;
; Definert som:
;     void  cdecl putch(int c);
;
; Ingen registre ›delagt.
;
PROC    _putch
        ARG     chr: WORD
        push    bp
        mov     bp, sp
        push    bx
        SETT_DS
        TEST_INIT
        call    getcurs
        mov     ax, [chr]
        call    vistegn
        call    setcurs
        RESETT_DS
        pop     bx
        pop     bp
        ret
ENDP    _putch


;
; _cputs
;
; viser angitt ASCIIZ-streng p† skjermen (i n†v‘rende vindu), og bytter
; linje/scroller hvis n›dvendig. Ingen CR/LF legges til p† slutten.
;
; Definert som:
;     void  cdecl cputs(char *s);
;
; Ingen registre ›delagt.
;
PROC    _cputs
        IF @DataSize NE 0
            ARG     s: DWORD
        ELSE
            ARG     s: WORD
        ENDIF
        push    bp
        mov     bp, sp
        SETT_DS
        TEST_INIT
        push    ax
        push    bx
        IF @DataSize NE 0
            les     bx, [s]
        ELSE
            mov     bx, [s]
            push    ds
            pop     es
        ENDIF
        call    getcurs
@@neste:
        mov     al, [es: bx]
        cmp     al, 0
        je      @@ret
        call    vistegn
        inc     bx
        jmp     SHORT @@neste
@@ret:  call    setcurs
        pop     bx
        pop     ax
        RESETT_DS
        pop     bp
        ret
ENDP    _cputs



        END
