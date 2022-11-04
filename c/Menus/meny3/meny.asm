;*****************************************************************************
;*                                                                           *
;* MENY.COM er selve styringsprogrammet i forbindelse med MENY III.          *
;* Det utf›rer f›lgende:                                                     *
;*                                                                           *
;*    1. Kaller MENYPROG.EXE og overf›rer adressen til en                    *
;*       "konversasjonsblokk" hvor navn p† menyer og programmer              *
;*       utveksles.                                                          *
;*                                                                           *
;*    2. Hvis ›nsket program eksisterer, kalles COMMAND.COM med /C           *
;*       og programnavnet (+ parametre).                                     *
;*                                                                           *
;*    3. G†r tilbake til steg 1.                                             *
;*                                                                           *
;*****************************************************************************

        IDEAL
        MODEL   TINY
        SEGMENT CODE

        ORG     0100h
        ASSUME  cs:CODE, ds:CODE, es:CODE


NAVN    EQU     "MENY III"
VER     EQU     "v1.7"
DATO    EQU     "15/5/95"


STACKL  EQU     0100h


start:  jmp     NEAR main       ; Hopp til programstart

        ORG     0105h

menydsk DB      2                   ; Disken menyprogrammet er p†
menydir DB      "\MENY", 0          ; Directoryet menyprogrammet er p†
        DB      35 DUP (?)          ;   Dir'en kan v‘re 40+1 tegn.
command DB      "C:\COMMAND.COM", 0 ; Path for COMMAND.COM. Kan v‘re
        DB      26 DUP (?)          ; inntil 40+1 tegn.

menyprg DB      "MENYPROG.EXE", 0   ; Navn p† menyprogrammet

LABEL transblokk BYTE               ; Blokk som veksler data mellom
                                    ; de to programmene
id      DB      "MENY III  ", 0     ; Identifikasjon
menynvn DB      "MENY0000.MNY", 0   ; Navnet til hovedmenyen f›rste gang
feilkod DW      0                   ; Feil som skal vises av MENYPROG.EXE
menyvlg DW      0                   ; Valgets nummer
progdsk DB      ?                   ; Disken hvor programmet ligger.
progdir DB      0, 50 DUP (?)       ; Dir for ›nsket program
prognvn DB      0, 13, 54 DUP (?)   ; Lstring med "\C" + navn + param.
                                    ; (F›rste byte er lengden, siste er 0Dh)
vent    DW      0

epb     DW      0                   ; EXEC parameter block
        DW      OFFSET prognvn, 0
        DW      0, 0
        DW      0, 0

tmpss   DW      ?                   ; Midlertidig stacksegment
tmpsp   DW      ?                   ; Midlertidig stackpointer

feil1   DB      13, "Feil under fors›k p† oppstart av MENYPROG.EXE", 13, 10, 10, "$"

;
; STARTPROGRAM starter programmet hvis navn dx peker til (ASCIIZ).
;
; Det er kun cs, ip og ds som er uendret !
;
PROC    startprogram NEAR
        push    ds

        mov     [tmpss], ss         ; Save stack
        mov     [tmpsp], sp

        push    ds
        pop     es
        mov     [epb + 4], ds
        mov     bx, OFFSET epb
        mov     ax, 4B00h
        int     21h

        jc      @@j1
        xor     ax, ax              ; Hvis ikke feil, nullstill AX.

@@j1:   mov     ss, [cs: tmpss]     ; Restore stack
        mov     sp, [cs: tmpsp]

        pop     ds
        ret
ENDP    startprogram



omstart:
        mov     ax, cs
        mov     ds, ax

        mov     ah, 0Eh                 ; Set default diskdrive
        mov     dl, [menydsk]
        int     21h

        mov     ah, 3Bh                 ; Set current directory
        mov     dx, OFFSET menydir
        int     21h

        mov     ax, 0040h                            ; Sett peker
        mov     es, ax                               ; til transblokk
        mov     [WORD es: 00F0h], OFFSET transblokk  ; i BIOS
        mov     [WORD es: 00F2h], ds                 ; ICA

        mov     dx, OFFSET menyprg
        call    startprogram
        cmp     ax, 0
        je      @@ikke_feil_menyprog

        mov     dx, OFFSET feil1
        mov     ah, 9
        int     21h
        jmp     SHORT slutt

@@ikke_feil_menyprog:
        mov     ah, 0Eh                 ; Set diskdrive for program
        mov     dl, [progdsk]
        int     21h

        mov     ah, 3Bh                 ; Set directory
        mov     dx, OFFSET progdir
        int     21h

        cmp     [BYTE prognvn], 0
        je      slutt

        mov     dx, OFFSET command
        call    startprogram
        cmp     ax, 0
        je      @@ikke_feil_command

        mov     [WORD feilkod], 1

@@ikke_feil_command:
        jmp     SHORT omstart

slutt:
        mov     ax, 4C00h               ; Avslutt programmet
        int     21h                     ;

ALIGN   16
LABEL   egenstack WORD



main:
        mov     dx, OFFSET idtxt
        mov     ah, 9
        int     21h
        mov     ax, cs
        mov     es, ax
        mov     bx, OFFSET egenstack    ; Finn antall paragrafer
        add     bx, STACKL              ;
        mov     cl, 4                   ;
        shr     bx, cl                  ;
        inc     bx                      ;
        mov     ah, 4Ah                 ; Krymp programmet til n›dv.
        int     21h                     ; st›rrelse
        mov     [WORD egenstack + STACKL - 2], 0
        mov     [WORD egenstack + STACKL - 4], 0
        mov     sp, OFFSET egenstack + STACKL - 4
        jmp     NEAR omstart


idtxt   DB      13, NAVN, " ", VER, "  --  (C) ", DATO
        DB      " - Sverre H. Huseby, Oslo, Norge", 13, 10, 10, "$"



        ENDS
        END     start
