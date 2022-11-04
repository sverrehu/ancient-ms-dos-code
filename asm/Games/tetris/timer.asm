
;==========================================================================
;
;   FILE:           TIMER.ASM
;
;   MODULE OF:      TETRIS
;
;   DESCRIPTION:    Timer interrupt routine that increases a counter.
;                   The timer is reprogrammed to be faster than normal.
;
;
;   WRITTEN BY:     Sverre H. Huseby
;
;==========================================================================

        IDEAL

        MODEL   MDL, C

        ASSUME  cs: @code, ds: @data





SPEED_FACT  EQU 16                              ; times faster than normal
CLOCK_FREQ  EQU 1193182                         ; IBM's timer clockfrequency
TIMER_LOW   EQU ((65536 / SPEED_FACT) AND 255)  ; Highbyte til timer
TIMER_HIGH  EQU ((65536 / SPEED_FACT) SHR 8)    ; Lowbyte til timer





UDATASEG



;==========================================================================
;
;                        P R I V A T E    D A T A
;
;==========================================================================


OldTimerInt DD  ?       ; Old address of timer interrupt (08)
TicksLeft   DW  ?       ; Number of ticks left to wait until old routine
                        ; is called










;==========================================================================
;
;                         P U B L I C    D A T A
;
;==========================================================================


            PUBLIC  TimerTicks




TimerTicks  DW  ?       ; Increased for each timer tick










CODESEG



;==========================================================================
;
;                    P R I V A T E    F U N C T I O N S
;
;==========================================================================


;--------------------------------------------------------------------------
;
;   NAME:           NewTimerInt
;
;   DESCRIPTION:    New timer interrupt-routine.
;                   All it does is increase the TimerTicks-counter,
;                   and call the original routine if it's time to do so.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    NewTimerInt FAR

        inc     [cs: TimerTicks]
        dec     [cs: TicksLeft]
        jz      @@jmp_old

    ; Since this is a hardware-interrupt coming from the 8259 PIC,
    ; we must tell this processor that the interrupt is finished.
        push    ax
        push    dx
        mov     al, 20h       ; EOI
        mov     dx, 20h
        out     20h, al
        pop     dx
        pop     ax

        iret

  @@jmp_old:
    ; It's time to invoke the original routine.
    ; Just jump to it, and leave all EOI-handling to it.
        mov     [cs: TicksLeft], SPEED_FACT
        jmp     [DWORD FAR cs: OldTimerInt]

ENDP    NewTimerInt










;==========================================================================
;
;                     P U B L I C    F U N C T I O N S
;
;==========================================================================


;--------------------------------------------------------------------------
;
;   NAME:           InitTimer
;
;   C-DECL:         void cdecl InitTimer(void);
;
;   DESCRIPTION:    Install the new timer interrupthander.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    InitTimer
PUBLIC  InitTimer

    ; Set up startvalues for counters
        mov     [TimerTicks], 0
        mov     [TicksLeft], SPEED_FACT

    ; Fetch address of original interrupt routine
        mov     ax, 3508h       ; Get Interrupt Vector 8
        int     21h
        mov     [WORD OldTimerInt], bx
        mov     [WORD OldTimerInt + 2], es

    ; Enter address of our routine
        mov     ax, 2508h       ; Set Interrupt Vector 8
        mov     dx, OFFSET NewTimerInt
        int     21h

    ; Tell the timerchip to interrupt SPEED_FACT times faster
    ; than normal
        mov     al, 36h         ; Square Wave
        out     43h, al         ; Timer Mode Register
        mov     al, TIMER_LOW
        out     40h, al
        mov     al, TIMER_HIGH
        out     40h, al

        ret

ENDP    InitTimer





;--------------------------------------------------------------------------
;
;   NAME:           ResetTimer
;
;   C-DECL:         void cdecl ResetTimer(void);
;
;   DESCRIPTION:    Restore original timer interrupthandler.
;                   !!! This _must_ be done before the program terminates
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    ResetTimer
PUBLIC  ResetTimer

    ; Set normal timerspeed, 18.2 times a second
        mov     al, 36h         ; Square Wave
        out     43h, al         ; Timer Mode Register
        xor     al, al          ; 65536 gives 18.2 ticks/sec
        out     40h, al
        out     40h, al

    ; Put back original routine
        mov     ax, 2508h       ; Set Interrupt Vector
        push    ds
        mov     dx, [WORD OldTimerInt]
        mov     ds, [WORD OldTimerInt + 2]
        int     21h
        pop     ds

        ret

ENDP    ResetTimer





ENDS



        END
