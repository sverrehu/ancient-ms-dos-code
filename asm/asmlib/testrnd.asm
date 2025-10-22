        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data

DATASEG

antall  DW      20 DUP (0)



CODESEG

        EXTRN   initscreen: PROC, endscreen: PROC
        EXTRN   outword: PROC, outchar: PROC
        EXTRN   rnd: PROC, randomize: PROC



        ORG     0100h

start:  jmp     main


main:   call    initscreen
        call    randomize
        mov     cx, 1000
@@loekke1:
        mov     ax, 20
        call    rnd
        mov     bx, ax
        shl     bx, 1
        inc     [antall + bx]
        loop    @@loekke1

        mov     cx, 20
        xor     bx, bx
@@loekke2:
        mov     ax, bx
        shr     ax, 1
        inc     ax
        call    outword
        mov     al, ':'
        call    outchar
        mov     al, ' '
        call    outchar
        mov     ax, [antall + bx]
        add     bx, 2
        call    outword
        mov     al, 13
        call    outchar
        mov     al, 10
        call    outchar
        loop    @@loekke2


exit:   call    endscreen
        mov     ax, 4C00h
        int     21h


ENDS

        END     start
