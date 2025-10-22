        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @code, es: NOTHING



CODESEG

        ORG     0100h

start:  jmp     main



        EXTRN   initscreen: PROC, endscreen: PROC

        EXTRN   outchar: PROC, outint: PROC


PROC    crlf
        push    ax
        mov     al, 13
        call    outchar
        mov     al, 10
        call    outchar
        pop     ax
        ret
ENDP    crlf


;---------------------------------;
;                                 ;
;  H O V E D P R O G R A M M E T  ;
;                                 ;
;---------------------------------;

main:
        call    initscreen

        xor     cx, cx
@@loekke:
        mov     ax, cx
        call    outint
        mov     al, ' '
        call    outchar
        loop    @@loekke

quit:   call    endscreen

        mov     ax, 4C00h
        int     21h

ENDS

        END     start
