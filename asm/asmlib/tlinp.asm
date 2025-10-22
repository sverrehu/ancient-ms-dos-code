        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @code, es: NOTHING



CODESEG

        ORG     0100h

start:  jmp     main


line    DB      "1234567890", 0
testtxt DB      "Er dette ok?", 0
keycode DB      13, 10, "Avslutningskode: ", 0
keys    DW      -45, -59, 0


        EXTRN   initscreen: PROC, endscreen: PROC
        EXTRN   initlineinput: PROC, endlineinput: PROC

        EXTRN   outtext: PROC, lineinput: PROC
        EXTRN   outchar: PROC, outint: PROC
        EXTRN   gotoxy: PROC, wherey: PROC
        EXTRN   strlen: PROC


;---------------------------------;
;                                 ;
;  H O V E D P R O G R A M M E T  ;
;                                 ;
;---------------------------------;

main:
        call    initscreen
        call    initlineinput

        mov     al, '['
        call    outchar
        mov     al, 6
        call    wherey
        call    gotoxy
        mov     al, ']'
        call    outchar
        mov     al, 1
        call    gotoxy

        mov     ax, 10  ; Maks lengde
        mov     bx, 5   ; Antall tegn av gangen
        mov     si, OFFSET line
        mov     di, OFFSET keys ; Taster
        mov     cl, 16 + 7      ; Attr f›r linjen godtas
        mov     ch, 32 + 14     ; Attr etter at linjen er godtatt
        call    lineinput
        push    ax

        mov     al, 13
        call    outchar
        mov     al, 10
        call    outchar
        mov     al, '['
        call    outchar
        mov     dx, OFFSET line
        call    outtext
        mov     al, ']'
        call    outchar

        mov     dx, OFFSET keycode
        call    outtext
        pop     ax
        call    outint

        mov     al, 13
        call    outchar
        mov     al, 10
        call    outchar
        mov     dx, OFFSET testtxt
        call    outtext

quit:   call    endlineinput
        call    endscreen

        mov     ax, 4C00h
        int     21h

ENDS

        END     start
