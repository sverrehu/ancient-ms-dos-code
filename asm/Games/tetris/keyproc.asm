
;==========================================================================
;
;   FILE:           KEYPROC.ASM
;
;   MODULE OF:      TETRIS
;
;   DESCRIPTION:    This file contains the "process" that reads
;                   the userinput and acts according to it.
;
;
;   WRITTEN BY:     Sverre H. Huseby
;
;==========================================================================

        IDEAL

        MODEL   MDL, C

        ASSUME  cs: @code, ds: @data





INCLUDE "PROCESS.INC"
INCLUDE "KEYLW.INC"
INCLUDE "MOVEOBJ.INC"
INCLUDE "TETRIS.INC"





DATASEG


            EXTRN FinishGame: WORD



;==========================================================================
;
;                        P R I V A T E    D A T A
;
;==========================================================================



KeyPID      DW  -1              ; Process ID of KeyProcess









CODESEG



;==========================================================================
;
;                    P R I V A T E    F U N C T I O N S
;
;==========================================================================


;--------------------------------------------------------------------------
;
;   NAME:           KeyProcess
;
;   C-DECL:         void cdecl KeyProcess(void);
;
;   DESCRIPTION:    This is the "process" that reads the keyboard
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    KeyProcess

    ; Check if there's a key waiting
        call    KeyPressed
        or      ax, ax
        jnz     @@key_waiting
        jmp     @@ret

  @@key_waiting:
    ; A key is waiting. Read it and convert to upper case
        call    GetKey

        cmp     ax, 'a'
        jb      @@check_key
        cmp     ax, 'z'
        ja      @@check_key

    ; Convert to uppercase
        sub     ax, 'a' - 'A'

  @@check_key:
    ; Check what it can be
        cmp     ax, 27
        jne     @@not_esc

    ; Escape is pressed. Finish this round
        mov     [FinishGame], ESCAPE
        call    StopProcesses
        jmp     SHORT @@ret

  @@not_esc:
        cmp     ax, 'H'
        jne     @@not_H

  @@move_left:
    ; Move left
        call    MoveLeft
        jmp     SHORT @@ret

  @@not_H:
        cmp     ax, 'L'
        jne     @@not_L

  @@move_right:
    ; Move right
        call    MoveRight
        jmp     SHORT @@ret

  @@not_L:
        cmp     ax, 'J'
        jne     @@not_J

  @@rotate_left:
    ; Rotate left
        call    RotateLeft
        jmp     SHORT @@ret

  @@not_J:
        cmp     ax, 'K'
        jne     @@not_K

  @@rotate_right:
    ; Rotate right
        call    RotateRight
        jmp     SHORT @@ret

  @@not_K:
        cmp     ax, ' '
        jne     @@not_space

  @@drop_object:
    ; Move object all the way down
        call    MoveAllWayDown
        jmp     SHORT @@ret

  @@not_space:
        cmp     ax, 'P'
        jne     @@not_P
        call    GetKey          ; Wait for another key
        jmp     SHORT @@ret

  @@not_P:
        cmp     ax, 'V'
        je      @@move_left
        cmp     ax, 'M'
        je      @@move_right
        cmp     ax, 'B'
        je      @@rotate_left
        cmp     ax, 'N'
        je      @@rotate_right
        cmp     ax, 13
        je      @@drop_object

    ; Added v1.1: Some keys suggested by Hansi
        cmp     ax, '4'
        je      @@move_left
        cmp     ax, '6'
        je      @@move_right
        cmp     ax, '5'
        je      @@rotate_left
        cmp     ax, '2'
        je      @@drop_object

    ; Added v1.11: Some keys suggested by Lena
        cmp     ax, -75
        je      @@move_left
        cmp     ax, -77
        je      @@move_right
        cmp     ax, -72
        je      @@rotate_left
        cmp     ax, -80
        je      @@drop_object

  @@ret:
        ret

ENDP    KeyProcess













;==========================================================================
;
;                     P U B L I C    F U N C T I O N S
;
;==========================================================================


;--------------------------------------------------------------------------
;
;   NAME:           NewKeyProcess
;
;   C-DECL:         void cdecl NewKeyProcess(void);
;
;   DESCRIPTION:    Starts a new process that reads the keyboard.
;                   There must only be one such at a time!
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    NewKeyProcess
PUBLIC  NewKeyProcess

    ; Start the process
        mov     ax, 1           ; Frequency. Very often!
        push    ax
        mov     ax, OFFSET KeyProcess
        push    ax
        call    AddProcess
        add     sp, 4

    ; Store process id so the process can be killed later
        mov     [KeyPID], ax

  @@ret:
        ret

ENDP    NewKeyProcess





;--------------------------------------------------------------------------
;
;   NAME:           KillKeyProcess
;
;   C-DECL:         void cdecl KillKeyProcess(void);
;
;   DESCRIPTION:    Stops the process that moves the objects down.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    KillKeyProcess
PUBLIC  KillKeyProcess

    ; Get the process ID
        mov     ax, [KeyPID]
        cmp     ax, -1
        je      @@ret

    ; Stop the process
        push    ax
        call    RemoveProcess
        add     sp, 2

    ; Mark that the process is not running
        mov     [KeyPID], -1

  @@ret:
        ret

ENDP    KillKeyProcess










ENDS





        END
