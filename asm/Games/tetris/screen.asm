
;==========================================================================
;
;   FILE:           SCREEN.ASM
;
;   MODULE OF:      TETRIS
;
;   DESCRIPTION:    Miscellaneous screen-routines.
;
;
;   WRITTEN BY:     Sverre H. Huseby
;
;==========================================================================

        IDEAL

        MODEL   MDL, C

        ASSUME  cs: @code, ds: @data





INCLUDE "PROCESS.INC"
INCLUDE "SCREENLW.INC"
INCLUDE "KEYLW.INC"
INCLUDE "BOARD.INC"
INCLUDE "SCORE.INC"
INCLUDE "TETRIS.INC"





UDATASEG



        EXTRN   FinishGame: BYTE
        EXTRN   UpperLeft: PTR, Upper: PTR, UpperRight: PTR, Left: PTR
        EXTRN   LowerLeft: PTR, Lower: PTR, LowerRight: PTR, Right: PTR



;==========================================================================
;
;                        P R I V A T E    D A T A
;
;==========================================================================


WaitKeyPID  DW  ?               ; Processnumber when reading a key
ClearBrdPID DW  ?               ; Processnumber when clearing gameboard
Key         DW  ?               ; Key that were read
CursorX     DW  ?               ; Cursor position
CursorY     DW  ?
CursorColor DW  ?               ; Just that
OnOrOff     DB  ?               ; Next cursorblink on or off?
ClrBrdLine  DW  ?               ; Current line to clear (0 - BOARDHEIGHT-1)
ClrBrdCol   DW  ?               ; Color of block to display





DATASEG





MessagePID  DW  -1              ; Processid for messageblinker

EmptyText   DB  "                   ", 0
EmpHighLine DB  "                     ", 0

NextObjText DB  11, 10, "NEXT:", 0

AskLevText  DB  11, 15, "CHOOSE LEVEL (0-9) OR ESC TO QUIT", 0

EmpAskLev   DB  "                                   ", 0

StatusText  DB  11, 10, "STATUS:", 13, 10, 11, 7
            DB  "  SCORE:       0", 13, 10
            DB  "  LEVEL:       0", 13, 10, 0

KeyText     DB  11, 10, "KEYS:", 13, 10, 11, 2
            DB  "  MOVE LEFT    -     V OR H", 13, 10
            DB  "  MOVE RIGHT   -     M OR L", 13, 10
            DB  "  ROTATE LEFT  -     B OR J", 13, 10
            DB  "  ROTATE RIGHT -     N OR K", 13, 10
            DB  "  DROP         - SPACE OR RETURN", 13, 10
            DB  "  PAUSE        -       P", 13, 10
            DB  "  STOP GAME    -       ESC", 13, 10, 0

AuthorText  DB  11, 13, "WRITTEN IN TURBO ASSEMBLER 2.0 BY", 13, 10, 10, 11, 5
            DB  "        SVERRE H. HUSEBY", 13, 10
            DB  "        DALSVN. 7", 13, 10
            DB  "        N-0376 OSLO", 13, 10
            DB  "        NORWAY", 0

HighText    DB  11, 9, " ------ HIGHSCORES ------", 13, 10, 10, 11, 3
            DB  " 1.", 13, 10
            DB  " 2.", 13, 10
            DB  " 3.", 13, 10
            DB  " 4.", 13, 10
            DB  " 5.", 13, 10
            DB  " 6.", 13, 10
            DB  " 7.", 13, 10
            DB  " 8.", 13, 10
            DB  " 9.", 13, 10
            DB  "10.", 0










CODESEG



            EXTRN ShowLogo: PROC



;==========================================================================
;
;                    P R I V A T E    F U N C T I O N S
;
;==========================================================================


;--------------------------------------------------------------------------
;
;   NAME:           WaitKeyProcess
;
;   C-DECL:         void cdecl WaitKeyProcess(void);
;
;   DESCRIPTION:    Blinks a cursor and waits for the user to press
;                   a key.
;
;                   The key is stored in the global Key-variable
;
;                   !!! This is not supposed to be called directly
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    WaitKeyProcess

    ; Check if cursor should be turned on or off
        mov     ax, '#'
        mov     cx, [CursorColor]
        cmp     [OnOrOff], 0
        jnz     @@turn_on
        mov     ax, ' '
        mov     cx, 15

  @@turn_on:
    ; Show the cursor
        push    cx
        push    ax
        push    [CursorY]
        push    [CursorX]
        call    ShowChar8x6
        add     sp, 8

    ; Next time it should be off if it's on and vice versa
        xor     [OnOrOff], 1

    ; Check if a key is pressed
        call    KeyPressed
        or      ax, ax
        jz      @@ret

    ; Read the key pressed
        call    GetKey

    ; and store it
        mov     [Key], ax

    ; Kill this process
        mov     ax, [WaitKeyPID]
        call    RemoveProcess

  @@ret:
        ret

ENDP    WaitKeyProcess





;--------------------------------------------------------------------------
;
;   NAME:           ClearBoardProcess
;
;   C-DECL:         void cdecl ClearBoardProcess(void);
;
;   DESCRIPTION:    Blinks a cursor and waits for the user to press
;                   a key.
;
;                   The key is stored in the global Key-variable
;
;                   !!! This is not supposed to be called directly
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    ClearBoardProcess

    ; Show a line of blocks
        mov     cx, BOARDWIDTH
        mov     si, UPPERX
        mov     di, UPPERY
        add     di, [ClrBrdLine]

  @@next_block:
        push    cx

        push    [ClrBrdCol]
        push    di
        push    si
        call    ShowBlock
        add     sp, 6

        inc     si

        pop     cx
        loop    @@next_block

    ; Update linenumber, and check if we should stop
        mov     ax, [ClrBrdLine]
        inc     ax
        mov     [ClrBrdLine], ax
        cmp     ax, BOARDHEIGHT
        jne     @@ret

    ; Kill this process
        mov     ax, [ClearBrdPID]
        call    RemoveProcess

  @@ret:
        ret

ENDP    ClearBoardProcess










;==========================================================================
;
;                     P U B L I C    F U N C T I O N S
;
;==========================================================================


;--------------------------------------------------------------------------
;
;   NAME:           ShowBoard
;
;   C-DECL:         void cdecl ShowBoard(void);
;
;   DESCRIPTION:    Shows the entire gameboard. For use after a line
;                   is deleted, or when a new game should start.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    ShowBoard
PUBLIC  ShowBoard

        mov     bx, BOARDHEIGHT - 1     ; BX is Y
  @@next_line:

        mov     cx, BOARDWIDTH - 1      ; CX is X
  @@next_column:
    ; Find color of current point
        push    bx
        push    cx

        push    bx
        push    cx
        call    IsOccupied
        add     sp, 4

        pop     cx
        pop     bx

    ; Write the block
        push    bx
        push    cx

        push    ax
        add     bx, UPPERY
        push    bx
        add     cx, UPPERX
        push    cx
        call    ShowBlock
        add     sp, 6

        pop     cx
        pop     bx

        dec     cx
        jns     @@next_column

        dec     bx
        jns     @@next_line

  @@ret:
        ret

ENDP    ShowBoard





;--------------------------------------------------------------------------
;
;   NAME:           VisuallyClearBoard
;
;   C-DECL:         void cdecl VisuallyClearBoard(void);
;
;   DESCRIPTION:    Clears the entire gameboard by first filling
;                   it with blocks, and then removing them.
;
;                   Used after a game is over
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    VisuallyClearBoard
PUBLIC  VisuallyClearBoard

    ; First fill the screen with boxes

    ; Set up variables for ClearBoardProcess
        xor     ax, ax
        mov     [ClrBrdLine], ax
        mov     ax, 8
        mov     [ClrBrdCol], ax

    ; Start the ClearBoardProcess
        mov     ax, 2
        push    ax
        mov     ax, OFFSET ClearBoardProcess
        push    ax
        call    AddProcess
        add     sp, 4
        mov     [ClearBrdPID], ax

        call    ProcessLoop

    ; Then clear the board

    ; Set up variables for ClearBoardProcess
        xor     ax, ax
        mov     [ClrBrdLine], ax
        mov     [ClrBrdCol], ax

    ; Start the ClearBoardProcess
        mov     ax, 2
        push    ax
        mov     ax, OFFSET ClearBoardProcess
        push    ax
        call    AddProcess
        add     sp, 4
        mov     [ClearBrdPID], ax

        call    ProcessLoop

    ; Really clear the boardarray
        call    ClearBoard

  @@ret:
        ret

ENDP    VisuallyClearBoard





;--------------------------------------------------------------------------
;
;   NAME:           DrawScreen
;
;   C-DECL:         void cdecl DrawScreen(void);
;
;   DESCRIPTION:    Show the entire screen. Called before the first game.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    DrawScreen
PUBLIC  DrawScreen

        push    di
        push    si

    ; Draw the border around the playground
        mov     ax, OFFSET UpperLeft
        push    ax
        mov     ax, UPPERY - 1
        push    ax
        mov     ax, UPPERX - 1
        push    ax
        call    ShowObj16x11
        add     sp, 6

        mov     ax, OFFSET UpperRight
        push    ax
        mov     ax, UPPERY - 1
        push    ax
        mov     ax, UPPERX + BOARDWIDTH
        push    ax
        call    ShowObj16x11
        add     sp, 6

        mov     ax, OFFSET LowerLeft
        push    ax
        mov     ax, UPPERY + BOARDHEIGHT
        push    ax
        mov     ax, UPPERX - 1
        push    ax
        call    ShowObj16x11
        add     sp, 6

        mov     ax, OFFSET LowerRight
        push    ax
        mov     ax, UPPERY + BOARDHEIGHT
        push    ax
        mov     ax, UPPERX + BOARDWIDTH
        push    ax
        call    ShowObj16x11
        add     sp, 6

        mov     cx, BOARDWIDTH
  @@top_and_bott:
        push    cx

        add     cx, UPPERX - 1
        push    cx

        mov     ax, OFFSET Upper
        push    ax
        mov     ax, UPPERY - 1
        push    ax
        push    cx
        call    ShowObj16x11
        add     sp, 6

        pop     cx

        mov     ax, OFFSET Lower
        push    ax
        mov     ax, UPPERY + BOARDHEIGHT
        push    ax
        push    cx
        call    ShowObj16x11
        add     sp, 6

        pop     cx
        loop    @@top_and_bott


        mov     cx, BOARDHEIGHT
  @@left_and_right:
        push    cx

        add     cx, UPPERY - 1
        push    cx

        mov     ax, OFFSET Left
        push    ax
        push    cx
        mov     ax, UPPERX - 1
        push    ax
        call    ShowObj16x11
        add     sp, 6

        pop     cx

        mov     ax, OFFSET Right
        push    ax
        push    cx
        mov     ax, UPPERX + BOARDWIDTH
        push    ax
        call    ShowObj16x11
        add     sp, 6

        pop     cx
        loop    @@left_and_right

    ; Show the cleared board
        call    ShowBoard

    ; Show the logo
        call    ShowLogo

    ; Show "NEXT:" above where the next object is showed
        xor     ax, ax          ; Color is part of the text
        push    ax
        mov     ax, OFFSET NextObjText
        push    ax
        mov     ax, 2 * NEXTY - 2
        push    ax
        mov     ax, 2 * NEXTX + 1
        push    ax
        call    ShowText8x6
        add     sp, 8

    ; Show text for score, level etc.
        xor     ax, ax          ; Color is part of the text
        push    ax
        mov     ax, OFFSET StatusText
        push    ax
        mov     ax, 14
        push    ax
        mov     ax, INSTRX
        push    ax
        call    ShowText8x6
        add     sp, 8

    ; Keys
        xor     ax, ax          ; Color is part of the text
        push    ax
        mov     ax, OFFSET KeyText
        push    ax
        mov     ax, 21
        push    ax
        mov     ax, INSTRX
        push    ax
        call    ShowText8x6
        add     sp, 8

    ; Show who wrote this game (me!)
        xor     ax, ax          ; Color is part of the text
        push    ax
        mov     ax, OFFSET AuthorText
        push    ax
        mov     ax, 34
        push    ax
        mov     ax, INSTRX + 2
        push    ax
        call    ShowText8x6
        add     sp, 8

    ; Header for highscore
        xor     ax, ax          ; Color is part of the text
        push    ax
        mov     ax, OFFSET HighText
        push    ax
        mov     ax, 45
        push    ax
        mov     ax, INSTRX + 4
        push    ax
        call    ShowText8x6
        add     sp, 8

  @@ret:
        pop     si
        pop     di
        ret

ENDP    DrawScreen





;--------------------------------------------------------------------------
;
;   NAME:           InputKey
;
;   C-DECL:         int cdecl InputKey(int x, int y, int color);
;
;   DESCRIPTION:    Blinks a cursor and waits for the user to press a key
;                   The key is _not_ displayed on the screen
;
;   PARAMETERS:     (x,y) - position on screen
;                   color - color of cursor
;
;   RETURNS:        Key pressed
;
;
PROC    InputKey
PUBLIC  InputKey

        ARG     x: WORD, y: WORD, color: WORD

    ; Set up variables for WaitKeyProcess
        mov     ax, [x]
        mov     [CursorX], ax
        mov     ax, [y]
        mov     [CursorY], ax
        mov     ax, [color]
        mov     [CursorColor], ax
        mov     [OnOrOff], 1

    ; Start the WaitKeyProcess
        mov     ax, 15
        push    ax
        mov     ax, OFFSET WaitKeyProcess
        push    ax
        call    AddProcess
        add     sp, 4
        mov     [WaitKeyPID], ax

        call    ProcessLoop

    ; Remove the cursor
        mov     ax, 15
        push    ax
        mov     ax, ' '
        push    ax
        push    [CursorY]
        push    [CursorX]
        call    ShowChar8x6
        add     sp, 8

    ; Fetch the returnvalue
        mov     ax, [Key]

  @@ret:
        ret

ENDP    InputKey





;--------------------------------------------------------------------------
;
;   NAME:           InputLine14
;
;   C-DECL:         void cdecl InputLine14(int x, int y, char *s, int color);
;
;   DESCRIPTION:    Inputs a line of up to 14 characters from the user
;
;   PARAMETERS:     (x,y) - Position on screen
;                   s     - Pointer to where the string should go
;                   color - Color of the characters
;
;   RETURNS:        Nothing
;
;
PROC    InputLine14
PUBLIC  InputLine14

        ARG     x: WORD, y: WORD, s: PTR, color: WORD

        push    di
        push    si

        mov     di, [s]
        mov     si, di
        add     si, 14          ; For comparing

        mov     dx, [x]

  @@read_key:
        push    dx
        push    [color]
        push    [y]
        push    dx
        call    InputKey
        add     sp, 6
        pop     dx

    ; Check what key was pressed
        cmp     ax, 27
        je      @@terminate
        cmp     ax, 13
        je      @@terminate
        cmp     ax, 8
        je      @@backspace
        cmp     ax, 'a'
        jl      @@not_lower_case
        cmp     ax, 'z'
        jg      @@read_key

    ; Translate to upper case
        sub     ax, 'a' - 'A'

  @@not_lower_case:
        cmp     ax, 32
        jl      @@read_key
        cmp     ax, 'Z'
        jg      @@read_key

    ; Show character on screen
        push    ax
        push    dx

        push    [color]
        push    ax
        push    [y]
        push    dx
        call    ShowChar8x6
        add     sp, 8

        pop     dx
        pop     ax

    ; Move to next position
        inc     dx

    ; Store character in string
        mov     [di], al
        inc     di
        cmp     di, si
        je      @@terminate

        jmp     SHORT @@read_key

  @@backspace:
    ; The user pressed backspace
        mov     ax, si
        sub     ax, 14
        cmp     di, ax
        je      @@read_key

        dec     dx
        dec     di
        jmp     SHORT @@read_key

  @@terminate:
    ; Enter terminating '\0'-byte
        mov     [BYTE di], 0

  @@ret:
        pop     di
        pop     si
        ret

ENDP    InputLine14





;--------------------------------------------------------------------------
;
;   NAME:           AskLevel
;
;   C-DECL:         void cdecl AskLevel(void);
;
;   DESCRIPTION:    Asks user what level to play at
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    AskLevel
PUBLIC  AskLevel

        push    si

    ; Show message
        xor     ax, ax          ; Color is part of the text
        push    ax
        mov     ax, OFFSET AskLevText
        push    ax
        mov     ax, 42
        push    ax
        mov     ax, INSTRX + 1
        push    ax
        call    ShowText8x6
        add     sp, 8

  @@read_key:
    ; Read a key until a legal value is given
        mov     ax, 15
        push    ax
        mov     ax, 42
        push    ax
        mov     ax, INSTRX + 35
        push    ax
        call    InputKey
        add     sp, 6

    ; Check what the key was
        cmp     ax, 27
        jne     @@not_esc

    ; ESC is pressed. Finish the game
        mov     [FinishGame], ESCAPE
        jmp     SHORT @@ret

  @@not_esc:
        cmp     ax, '0'
        jb      @@read_key
        cmp     ax, '9'
        ja      @@read_key

    ; Calculate real level, and store it
        sub     ax, '0'
        mov     [Level], ax

    ; Remove the text
        mov     ax, 15
        push    ax
        mov     ax, OFFSET EmpAskLev
        push    ax
        mov     ax, 42
        push    ax
        mov     ax, INSTRX + 1
        push    ax
        call    ShowText8x6
        add     sp, 8

  @@ret:
        pop     si
        ret

ENDP    AskLevel





;--------------------------------------------------------------------------
;
;   NAME:           ShowHighScores
;
;   C-DECL:         void cdecl ShowHighScores(void);
;
;   DESCRIPTION:    Shows the current highscoretable
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    ShowHighScores
PUBLIC  ShowHighScores

        mov     bx, OFFSET HighTable
        mov     dx, 47                  ; Y-coordinate
        mov     ax, INSTRX + 4 + 4      ; X-coordinate

        mov     cx, 10

  @@next_line:
        push    cx

    ; Remove whatever is on the line
        push    ax
        push    bx
        push    dx

        mov     cx, 15
        push    cx
        mov     cx, OFFSET EmpHighLine
        push    cx
        push    dx
        push    ax
        call    ShowText8x6
        add     sp, 8

        pop     dx
        pop     bx
        pop     ax

    ; Show the text (name)
        push    ax
        push    bx
        push    dx

        mov     cx, 3
        push    cx
        push    bx
        push    dx
        push    ax
        call    ShowText8x6
        add     sp, 8

        pop     dx
        pop     bx
        pop     ax

    ; Show scorevalue
        add     bx, 15

        push    ax
        push    bx
        push    dx

        add     ax, 15

        mov     cx, 3
        push    cx
        push    [WORD bx + 2]
        push    [WORD bx]
        push    dx
        push    ax
        call    ShowNum8x6
        add     sp, 10

        pop     dx
        pop     bx
        pop     ax

    ; Update scoretablepointer and screenline
        inc     dx
        add     bx, 4

        pop     cx
        loop    @@next_line

  @@ret:
        ret

ENDP    ShowHighScores










ENDS





        END
