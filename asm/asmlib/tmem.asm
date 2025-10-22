        IDEAL

        MODEL   TINY

CODESEG

        ORG     0100h
        ASSUME  cs: @code, ds: @code, es: @code

        EXTRN   initmem: PROC, endmem: PROC, getmem: PROC, freemem: PROC

start:  jmp     main

segmnt  DW      8 DUP (0)
sizes   DW      8 DUP (0)

main:
        call    initmem

        mov     ax, 1
        call    getmem
        mov     bx, 0
        mov     [segmnt + bx], es
        mov     [sizes + bx], ax

        nop
        nop
        nop

        mov     bx, 0
        mov     es, [segmnt + bx]
        mov     ax, [sizes + bx]
        call    freemem
        mov     [WORD segmnt + bx], 0
        mov     [WORD sizes + bx], 0


@@end:
        call    endmem

        mov     ax, 4C00h
        int     21h

ENDS

        END     start
