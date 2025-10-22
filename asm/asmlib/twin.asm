        IDEAL

        MODEL   TINY

CODESEG

        ORG     0100h
        ASSUME  cs: @code, ds: @code, es: @code

INCLUDE "SCREEN.INC"
        EXTRN   initwindow: PROC, endwindow: PROC, openwindow: PROC, closewindow: PROC
        EXTRN   bordertext: PROC
        EXTRN   initmem: PROC, endmem: PROC
        EXTRN   getkey: PROC

start:  jmp     main

fyll    DB      "Ingeborg Wittussen ", 0
msg1    DB      "Dette er en melding som er skrevet i et testvindu "
        DB      "skrevet i assembly.", 13, 10, 0
msg2    DB      "Dette er skrevet etter at headeren er vist.", 0
header  DB      " VINDUSOVERSKRIFT ", 0



PROC    fyllskjerm
        call    screencols
        mov     dx, ax
        call    screenrows
        mul     dx
        mov     bx, 18
        div     bx
        mov     cx, ax
        mov     dx, OFFSET fyll
@@l1:   call    outtext
        loop    @@l1
        ret
ENDP    fyllskjerm



main:
        mov     ax, cs
        mov     ds, ax
        mov     es, ax

        call    initmem
        call    initscreen
        call    initwindow

        mov     al, 2 * 16 + 15
        call    textattr
        call    fyllskjerm

        mov     cx, 6
@@lokke:
        push    cx
        mov     al, 5
        mov     ah, 5
        mov     dl, 34
        mov     dh, 10
        mov     cl, 1 * 16 + 14
        mov     ch, 3 * 16 + 9
        mov     bl, 2
        call    openwindow
        mov     dx, OFFSET msg1
        call    outtext
        mov     dx, OFFSET header
        mov     al, 6
        pop     cx
        push    cx
        sub     al, cl
        mov     ch, 4 * 16 + 15
        call    bordertext
        mov     dx, OFFSET msg2
        call    outtext
        call    getkey
        call    closewindow
        pop     cx
        loop    @@lokke

exit:   call    endwindow
        mov     al, 13
        call    outchar
        mov     al, 10
        call    outchar
        call    endscreen
        call    endmem

        mov     ax, 4C00h
        int     21h

ENDS

        END     start
