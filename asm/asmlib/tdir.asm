        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @code, es: NOTHING



CODESEG

        ORG     0100h

start:  jmp     main


entmsg  DB      13, 10, 10, "Angi del av path> ", 0
retmsg1 DB      "Full path: ", 0
retmsg2 DB      "Returkode: ", 0

oldpath DB      80 DUP (?)
newpath DB      80 DUP (?)


        EXTRN   initscreen: PROC, endscreen: PROC
        EXTRN   initlineinput: PROC, endlineinput: PROC

        EXTRN   outtext: PROC, lineinput: PROC
        EXTRN   outchar: PROC, outint: PROC
        EXTRN   gotoxy: PROC, wherex: PROC, wherey: PROC

        EXTRN   mkfullpath: PROC


;---------------------------------;
;                                 ;
;  H O V E D P R O G R A M M E T  ;
;                                 ;
;---------------------------------;

main:   push    ds
        pop     es

        call    initscreen
        call    initlineinput

next:
        mov     dx, OFFSET entmsg
        call    outtext

        mov     ax, 80  ; Maks lengde
        mov     bx, 60  ; Antall tegn av gangen
        mov     si, OFFSET oldpath
        mov     [BYTE si], 0
        xor     di, di          ; Taster
        mov     cl, 7           ; Attr f›r linjen godtas
        mov     ch, 7           ; Attr etter at linjen er godtatt
        call    lineinput

        cmp     ax, 27
        je      quit

        mov     al, 13
        call    outchar
        mov     al, 10
        call    outchar

        mov     si, OFFSET oldpath
        mov     di, OFFSET newpath
        call    mkfullpath

        push    ax
        call    wherex
        call    wherey
        call    gotoxy
        pop     ax

        mov     dx, OFFSET retmsg1
        call    outtext

        push    ax
        mov     al, 13
        call    outchar
        mov     al, 10
        call    outchar
        pop     ax

        mov     dx, OFFSET newpath
        call    outtext

        push    ax
        mov     al, 13
        call    outchar
        mov     al, 10
        call    outchar
        pop     ax

        mov     dx, OFFSET retmsg2
        call    outtext
        call    outint

        jmp     next


quit:   call    endlineinput
        call    endscreen

        mov     ax, 4C00h
        int     21h

ENDS

        END     start
