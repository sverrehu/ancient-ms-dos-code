
;==========================================================================
;
;   FILE:           STACK.ASM
;
;   MODULE OF:      ED
;
;   DESCRIPTION:    Sets up a stack for the program.
;
;
;   WRITTEN BY:     Sverre H. Huseby
;
;   LAST MODIFIED:
;
;==========================================================================

        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data





STKSIZE EQU     5120





UDATASEG

;==========================================================================
;
;                        P R I V A T E    D A T A
;
;==========================================================================


StackArea   DB  STKSIZE DUP(?)











CODESEG

;==========================================================================
;
;                     P U B L I C    F U N C T I O N S
;
;==========================================================================


;--------------------------------------------------------------------------
;
;   NAME:           SetupStack
;
;   DESCRIPTION:    Set up the stack. Preserves only the returnaddress
;                   of the caller of this function, and should thus be
;                   called before any other stack-instructions.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    SetupStack
PUBLIC  SetupStack

        pop     ax              ; Return address.
        push    ds
        pop     ss
        mov     sp, OFFSET StackArea + STKSIZE
        push    ax

  @@ret:
        ret

ENDP    SetupStack










ENDS





        END
