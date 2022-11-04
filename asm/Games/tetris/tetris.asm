
;==========================================================================
;
;   FILE:           .ASM
;
;   MODULE OF:
;
;   DESCRIPTION:
;
;
;   WRITTEN BY:     Sverre H. Huseby
;
;==========================================================================

        IDEAL

        MODEL   MDL, C

        ASSUME  cs: @code, ds: @data





INCLUDE "TETRIS.INC"
INCLUDE "SCREENLW.INC"
INCLUDE "TIMER.INC"
INCLUDE "PROCESS.INC"
INCLUDE "RANDOM.INC"
INCLUDE "KEYLW.INC"
INCLUDE "BOARD.INC"
INCLUDE "MOVEOBJ.INC"
INCLUDE "MOVEPROC.INC"
INCLUDE "KEYPROC.INC"
INCLUDE "SCREEN.INC"
INCLUDE "SCORE.INC"





DATASEG



;==========================================================================
;
;                        P R I V A T E    D A T A
;
;==========================================================================


StartMsg    DB  PROGNAME, " ", PROGVER, "  --  (C) ", PROGDATE
            DB  " - Sverre H. Huseby, Oslo, Norway", 13, 10, 10
            DB  "This program is FreeWare. Copy it!", 13, 10, 10, "$"

ErrNotEGA   DB  "Sorry, can't find EGA-color-card with "
            DB  "at least 128 kb RAM.", 13, 10, "$"










UDATASEG



;==========================================================================
;
;                         P U B L I C    D A T A
;
;==========================================================================


            PUBLIC  FinishGame




FinishGame  DB  ?               ; Should the game stop?










CODESEG


            ORG 0100h

start:      jmp     main


            DB  8, 8, 8, "   ", 13, 10, 10, 10, 10, 10, "      "
            DB  "--> Hi, there's nothing here for "
            DB  "you, pal! Just play the game! <--"
            DB  13, 10, 10, 10, 10, 10, 26



;==========================================================================
;
;                    P R I V A T E    F U N C T I O N S
;
;==========================================================================


;--------------------------------------------------------------------------
;
;   NAME:           PlayGame
;
;   C-DECL:         void cdecl PlayGame(void);
;
;   DESCRIPTION:    Handles a complete game. Asks for level,
;                   checks highscore etc.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    PlayGame

    ; We're not supposed to finish before we even start
        mov     [FinishGame], 0

    ; Ask for level
        call    AskLevel

    ; Did we stop already?
        cmp     [FinishGame], ESCAPE
        je      @@ret

    ; Set up startvalues, variables etc.
        call    Randomize
        call    ClearProcTable
        call    ClearBoard
        call    ShowBoard
        call    InitObjects
        call    ClearScore
        call    ShowScore
        call    ShowLevel

    ; Create the next object. This must be done twice, else the user
    ; will know the first object from the last round.
        call    CreateNextObject
        call    CreateNextObject

    ; Set up gameprocesses
        call    NewMoveDownProcess
        call    NewKeyProcess

    ; Start all processes
        call    ProcessLoop

    ; Game is over. Tidy up
        call    ClearProcTable

    ; Clear the gameboard
        call    VisuallyClearBoard

  @@test_keys_present:
    ; Clear keyboardbuffer
        call    KeyPressed
        or      ax, ax
        jz      @@no_key_present
        call    GetKey
        jmp     @@test_keys_present

  @@no_key_present:
    ; If the game was aborted, we don't care for a new highscore
        cmp     [FinishGame], ESCAPE
        je      @@dont_check_high

    ; Check if this was a new highscore
        call    TestHighScore

  @@dont_check_high:
    ; We shouldn't yet finish the entire program
        mov     [FinishGame], 0

  @@ret:
        ret

ENDP    PlayGame








;==========================================================================
;
;                     P U B L I C    F U N C T I O N S
;
;==========================================================================



main:
    ; In case of debuging an EXE-file
        push    cs
        pop     ds

    ; Show startmessage
        mov     dx, OFFSET StartMsg
        mov     ah, 9
        int     21h

    ; Try to enter EGA mode 10h, 640x350x16
        call    EnterGraphics
        or      ax, ax
        jnz     @@graph_ok

    ; Couldn't enter EGA-mode. Show errormessage and abort.
        mov     dx, OFFSET ErrNotEGA
        mov     ah, 9
        int     21h
        jmp     SHORT exit

  @@graph_ok:
        call    ReadHighScore
        call    ClearBoard
        call    DrawScreen
        call    InitTimer
        call    ClearProcTable

  @@new_game:
        call    PlayGame
        cmp     [FinishGame], 0
        jz      @@new_game

  @@finish:
        call    ResetTimer
        call    WriteHighScore

        call    EnterText

    ; Show the "copyright-message" after the game has finished.
        mov     dx, OFFSET StartMsg
        mov     ah, 9
        int     21h

exit:
    ; Tell DOS to kill the program
        mov     ax, 4C00h
        int     21h





ENDS





        END     start
