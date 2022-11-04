
;==========================================================================
;
;   FILE:           MOVEPROC.ASM
;
;   MODULE OF:      TETRIS
;
;   DESCRIPTION:    This file contains the "process" that moves the
;                   objects down the screen. The actual movements
;                   are defined in MOVEOBJ.ASM
;
;
;   WRITTEN BY:     Sverre H. Huseby
;
;==========================================================================

        IDEAL

        MODEL   MDL, C

        ASSUME  cs: @code, ds: @data





INCLUDE "PROCESS.INC"
INCLUDE "MOVEOBJ.INC"
INCLUDE "BOARD.INC"
INCLUDE "SCORE.INC"
INCLUDE "SCREEN.INC"
INCLUDE "TETRIS.INC"





UDATASEG



            EXTRN FinishGame: BYTE



;==========================================================================
;
;                        P R I V A T E    D A T A
;
;==========================================================================



MoveDownPID DW  ?               ; Process ID of MoveDownProcess





DATASEG


    ; Processpeed for each level
Speeds      DW  100, 90, 80, 70, 60, 50, 39, 28, 17, 11, 9, 6









CODESEG



;==========================================================================
;
;                    P R I V A T E    F U N C T I O N S
;
;==========================================================================


;--------------------------------------------------------------------------
;
;   NAME:           MoveDownProcess
;
;   C-DECL:         void cdecl MoveDownProcess(void);
;
;   DESCRIPTION:    This is the "process" that moves the current object
;                   down one line.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    MoveDownProcess

    ; Move down one line
        call    MoveDown

    ; Check if it was possible
        or      ax, ax
        jnz     @@ret

    ; The object landed.
        call    KillMoveDownProcess

    ; Give score
        xor     ax, ax
        push    ax
        mov     ax, [Level]
        inc     ax
        mov     cl, 2
        shl     ax, cl
        push    ax
        call    AddScore
        add     sp, 4

    ; Remove any filled lines
        call    RemoveFullLines

    ; Create a new one
        call    CreateNextObject
        or      ax, ax
        jnz     @@new_object_ok

    ; The new object hit something. Game is over
        mov     [FinishGame], BOARDFULL
        call    StopProcesses
        call    ShowCurrObject
        jmp     SHORT @@ret

  @@new_object_ok:
        call    ShowCurrObject
        call    NewMoveDownProcess

  @@ret:
        ret

ENDP    MoveDownProcess













;==========================================================================
;
;                     P U B L I C    F U N C T I O N S
;
;==========================================================================


;--------------------------------------------------------------------------
;
;   NAME:           NewMoveDownProcess
;
;   C-DECL:         void cdecl NewMoveDownProcess(void);
;
;   DESCRIPTION:    Starts a new process that moves the objects down.
;                   There must only be one such at a time!
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    NewMoveDownProcess
PUBLIC  NewMoveDownProcess

    ; Start the process
        mov     bx, [Level]
        shl     bx, 1
        push    [Speeds + bx]
        mov     ax, OFFSET MoveDownProcess
        push    ax
        call    AddProcess
        add     sp, 4

    ; Store process id so the process can be killed later
        mov     [MoveDownPID], ax

  @@ret:
        ret

ENDP    NewMoveDownProcess





;--------------------------------------------------------------------------
;
;   NAME:           KillMoveDownProcess
;
;   C-DECL:         void cdecl KillMoveDownProcess(void);
;
;   DESCRIPTION:    Stops the process that moves the objects down.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    KillMoveDownProcess
PUBLIC  KillMoveDownProcess

    ; Get the process ID
        mov     ax, [MoveDownPID]
        cmp     ax, -1
        je      @@ret

    ; Stop the process
        push    ax
        call    RemoveProcess
        add     sp, 2

    ; Mark that the process is not running
        mov     [MoveDownPID], -1

  @@ret:
        ret

ENDP    KillMoveDownProcess





;--------------------------------------------------------------------------
;
;   NAME:           InitObjects
;
;   C-DECL:         void cdecl InitObjects(void);
;
;   DESCRIPTION:    Set up variables for a new game
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    InitObjects
PUBLIC  InitObjects

        mov     [MoveDownPID], -1

  @@ret:
        ret

ENDP    InitObjects










ENDS





        END
