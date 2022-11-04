
;==========================================================================
;
;   FILE:           RANDOM.ASM
;
;   MODULE OF:      TETRIS
;
;   DESCRIPTION:    Routines for generating "random" numbers
;
;
;   WRITTEN BY:     Sverre H. Huseby
;
;==========================================================================

        IDEAL

        MODEL   MDL, C

        ASSUME  cs: @code, ds: @data










UDATASEG



;==========================================================================
;
;                        P R I V A T E    D A T A
;
;==========================================================================


RndNum1     DW  ?
RndNum2     DW  ?










CODESEG



;==========================================================================
;
;                     P U B L I C    F U N C T I O N S
;
;==========================================================================


;--------------------------------------------------------------------------
;
;   NAME:           Randomize
;
;   C-DECL:         void cdecl Randomize(void);
;
;   DESCRIPTION:    Changes the random numbers according
;                   to the current timervalue.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    Randomize
PUBLIC  Randomize

    ; Read the current lowbyte-value of the timer, and
    ; enter it in one of the random numbers
        xor     ax, ax
        mov     es, ax
        mov     ax, [es: 046Ch]

        add     [RndNum1], ax

    ; Read the current highbyte-value of the timer, and
    ; enter it in the other random number
        xor     ax, ax
        mov     es, ax
        mov     ax, [es: 046Eh]

        add     [RndNum1], ax

        ret

ENDP    Randomize





;--------------------------------------------------------------------------
;
;   NAME:           Random
;
;   C-DECL:         int cdecl Random(int upto);
;
;   DESCRIPTION:    Gets a random number up to the given limit.
;
;   PARAMETERS:     upto - Upper limit. Numbers returned are  0 <= z < upto
;
;   RETURNS:        Random number
;
;
PROC    Random
PUBLIC  Random

        ARG     upto: WORD

    ; Create a random number
        mov     ax, [RndNum1]
        add     ax, [RndNum2]

    ; Divide to get the reminder
        xor     dx, dx
        mov     cx, [upto]
        div     cx

    ; Change the random numbers to get new values next time
        add     [RndNum1], ax
        add     [RndNum2], dx

        mov     ax, dx          ; Reminder now in AX

        ret

ENDP    Random










ENDS





        END
