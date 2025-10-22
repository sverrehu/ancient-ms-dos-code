        IDEAL

        MODEL   TINY


CODESEG

        ORG     0100h
        ASSUME  cs: @code, ds: @code, es: @code

INCLUDE "SCREEN.INC"
        EXTRN   initwindow: PROC, endwindow: PROC, openwindow: PROC, closewindow: PROC
        EXTRN   initmem: PROC, endmem: PROC

start:  jmp     main

fyll    DB      "Ingeborg Wittussen ", 0
msg     DB      "Dette er en melding som er skrevet i et testvindu "
        DB      "skrevet i assembly.", 13, 10, 0
cmsg    DB      "Har lukket et vindu", 13, 10, 0

x1      DW      ?
y1      DW      ?
x2      DW      ?
y2      DW      ?
tattr   DB      ?
rattr   DB      ?
ramme   DB      ?
antall  DW      0



;
; Ret: AX=random tall mellom 0 og AX-1
;
PROC    rnd
        push    bx
        push    cx
        push    dx
        push    es
        push ax
        push ax
        EXTRN _rand:PROC
        call _rand
        add sp, 2
        pop bx
        xor     dx, dx
        div     bx
        mov     ax, dx
        pop     es
        pop     dx
        pop     cx
        pop     bx
        ret
ENDP    rnd


PROC    key
        xor     ah, ah
        int     16h
        ret
ENDP    key


PROC    stopesc
        mov     ah, 1
        int     16h
        jz      @@ret
        call    key
        cmp     al, 27
        jne     @@ret
        pop     ax
        jmp     exit
@@ret:  ret
ENDP    stopesc


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

@@lokke:
        mov     ax, 3
        call    rnd
        mov     [ramme], al

        call    screencols
        sub     ax, 10
        call    rnd
        mov     [x1], ax

        push    ax
        call    screencols
        mov     bx, ax
        pop     ax
        sub     bx, 2
        sub     bx, ax
        mov     ax, bx
        call    rnd
        add     ax, 2
        add     ax, [x1]
        mov     [x2], ax

        call    screenrows
        sub     ax, 10
        call    rnd
        mov     [y1], ax

        push    ax
        call    screenrows
        mov     bx, ax
        pop     ax
        sub     bx, 2
        sub     bx, ax
        mov     ax, bx
        call    rnd
        add     ax, 2
        add     ax, [y1]
        mov     [y2], ax

        mov     ax, 128
        call    rnd
        mov     [tattr], al

        mov     ax, 128
        call    rnd
        mov     [rattr], al

        mov     al, [BYTE x1]
        mov     ah, [BYTE y1]
        mov     dl, [BYTE x2]
        mov     dh, [BYTE y2]
        mov     cl, [tattr]
        mov     ch, [rattr]
        mov     bl, [ramme]
        call    openwindow
        cmp     ax, 0
        jne     @@ikke_inc
        inc     [WORD antall]
@@ikke_inc:
        mov     dx, OFFSET msg
        call    outtext
        call    stopesc
        mov     cx, 8000h
@@l1:   nop
        nop
        nop
        nop
        nop
        nop
        nop
;        loop    @@l1
        jmp     @@lokke

exit:   call    endwindow
        mov     al, 13
        call    outchar
        mov     al, 10
        call    outchar
        mov     ax, [antall]
        call    outword
        call    endscreen
        call    endmem

        mov     ax, 4C00h
        int     21h

ENDS

        END     start
