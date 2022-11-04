        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data


TIMES   EQU     16              ; Ny timer g†r TIMES ganger raskere enn vanlig.
IBM_FRQ EQU     1193182         ; IBM's klokkefrekvens
CNT_LO  EQU     ((65536 / TIMES) AND 255)       ; Highbyte til timer
CNT_HI  EQU     ((65536 / TIMES) SHR 8)         ; Lowbyte til timer



UDATASEG

        PUBLIC  counter

old08   DD      ?       ; Gammel adresse for timerinterrupt
counter DW      ?       ; Teller som ›kes for hvert timertick
oldcnt  DW      ?       ; Antall ticks igjen f›r gammel rutine skal kalles



CODESEG

        PUBLIC  init_timer, reset_timer


PROC    new08   FAR
        inc     [cs: counter]
        dec     [cs: oldcnt]
        jz      @@jmp_old

  ; Siden dette er et hardware-interrupt som kommer fra 8259 PIC, m†
  ; det gis beskjed til denne at interruptet er ferdig.
        push    ax
        push    dx
        mov     al, 20h
        mov     dx, 20h
        out     20h, al
        pop     dx
        pop     ax

        iret
@@jmp_old:
        mov     [cs: oldcnt], TIMES
        jmp     [DWORD FAR cs: old08]
ENDP    new08



PROC    init_timer
  ; Sett opp startverdier for ny timer
        mov     [counter], 0
        mov     [oldcnt], TIMES

  ; Finn adressen til gammelt timerinterrupt
        mov     ax, 3508h
        int     21h
        mov     [WORD old08], bx
        mov     [WORD old08 + 2], es

  ; Sett inn adressen til nytt timerinterrupt
        mov     ax, 2508h
        mov     dx, OFFSET new08
        int     21h

  ; Initier timerchipen til † gj›re avbrudd TIMES ganger oftere enn normalt
        mov     al, 36h         ; Square wave
        out     43h, al         ; Ut til Timer Mode Register
        mov     al, CNT_LO
        out     40h, al
        mov     al, CNT_HI
        out     40h, al

        ret
ENDP    init_timer



PROC    reset_timer
  ; Sett timerhastigheten til normalt, 18.2 ganger i sekundet.
        mov     al, 36h         ; Square wave
        out     43h, al
        xor     al, al          ; 65536 gir 18.2 ticks/sec
        out     40h, al
        out     40h, al
  ; Sett tilbake gammelt timer-interrupt
        mov     ax, 2508h
        push    ds
        mov     dx, [WORD old08]
        mov     ds, [WORD old08 + 2]
        int     21h
        pop     ds

        ret
ENDP    reset_timer



ENDS

        END
