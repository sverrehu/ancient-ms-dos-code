
;==========================================================================
;
;   FILE:           MOVEOBJ.ASM
;
;   MODULE OF:      TETRIS
;
;   DESCRIPTION:    Routines to move a "tetris-object"
;
;
;   WRITTEN BY:     Sverre H. Huseby
;
;==========================================================================

        IDEAL

        MODEL   MDL, C

        ASSUME  cs: @code, ds: @data





INCLUDE "SCREENLW.INC"
INCLUDE "RANDOM.INC"
INCLUDE "PROCESS.INC"
INCLUDE "SCORE.INC"
INCLUDE "BOARD.INC"
INCLUDE "MOVEPROC.INC"
INCLUDE "TETRIS.INC"





UDATASEG


            EXTRN Objects: PTR
            EXTRN FinishGame: BYTE



;==========================================================================
;
;                        P R I V A T E    D A T A
;
;==========================================================================


CurrObj     DW  ?               ; Number of current object
CurrRot     DW  ?               ; Rotation of object. 4*(4*CurrObj+CurrRot)
                                ; Gives the index into the Object-array
PosX        DW  ?               ; X-position in gameboard
PosY        DW  ?               ; Y-position in gameboard
NextObj     DW  ?               ; Number of next object
NextRot     DW  ?               ; Rotation of next object





DATASEG



Colors      DW  7, 9, 10, 11, 13, 14, 15        ; Objectcolors










CODESEG



;==========================================================================
;
;                    P R I V A T E    F U N C T I O N S
;
;==========================================================================


;--------------------------------------------------------------------------
;
;   NAME:           ObjectFits
;
;   C-DECL:         int cdecl ObjectFits(int x, int y, int obj, int rot);
;
;   DESCRIPTION:    Check if an object fits on the gameboard
;
;   PARAMETERS:     (x,y) - position on gameboard
;                   obj   - object number
;                   rot   - rotation number
;
;   RETURNS:        0 - object doesn't fit, 1 - object fits
;
;
PROC    ObjectFits

        ARG     x: WORD, y: WORD, obj: WORD, rot: WORD

        push    di
        push    si

    ; Calculate the address of the object-data
        mov     ax, [obj]
        shl     ax, 1
        shl     ax, 1
        add     ax, [rot]
        mov     cl, 4
        shl     ax, cl
        add     ax, OFFSET Objects
        mov     bx, ax

    ; Treat the 4x4-object
        mov     di, [y]         ; DI contains Y-position on gameboard

        mov     cx, 4
  @@next_line:
        push    cx

        mov     si, [x]         ; SI contains X-position on gameboard

        mov     cx, 4
  @@next_col:

        cmp     [BYTE bx], 0
        jz      @@next_point

    ; Check if this position is free
        push    bx
        push    cx

        push    di
        push    si
        call    IsOccupied
        add     sp, 4

        pop     cx
        pop     bx

        or      ax, ax
        jnz     @@doesnt_fit

  @@next_point:
        inc     bx
        inc     si
        loop    @@next_col

        inc     di
        pop     cx
        loop    @@next_line

    ; The object fits.
        mov     ax, 1
        jmp     SHORT @@ret

  @@doesnt_fit:
    ; The object doesn't fit. There's a CX pushed on the stack
    ; that we must remove
        pop     cx

    ; Return "false"
        xor     ax, ax

  @@ret:
        pop     si
        pop     di
        ret

ENDP    ObjectFits





;--------------------------------------------------------------------------
;
;   NAME:           OccupyObject
;
;   C-DECL:         void cdecl OccupyObject(int x, int y,
;                                           int obj, int rot,
;                                           int color);
;
;   DESCRIPTION:    Enter an object in the gameboardarray
;
;   PARAMETERS:     (x,y) - position on gameboard
;                   obj   - object number
;                   rot   - rotation number
;                   color - color code to enter in the gameboard
;
;   RETURNS:        Nothing
;
;
PROC    OccupyObject

        ARG     x: WORD, y: WORD, obj: WORD, rot: WORD, color: WORD

        push    di
        push    si

    ; Calculate the address of the object-data
        mov     ax, [obj]
        shl     ax, 1
        shl     ax, 1
        add     ax, [rot]
        mov     cl, 4
        shl     ax, cl
        add     ax, OFFSET Objects
        mov     bx, ax

    ; Put the color in AX
        mov     ax, [color]

    ; Treat the 4x4-object
        mov     di, [y]         ; DI contains Y-position on gameboard

        mov     cx, 4
  @@next_line:
        push    cx

        mov     si, [x]         ; SI contains X-position on gameboard

        mov     cx, 4
  @@next_col:

        cmp     [BYTE bx], 0
        jz      @@next_point

    ; Enter this position
        push    ax
        push    bx
        push    cx

        push    ax
        push    di
        push    si
        call    OccupyPos
        add     sp, 6

        pop     cx
        pop     bx
        pop     ax

  @@next_point:
        inc     bx
        inc     si
        loop    @@next_col

        inc     di
        pop     cx
        loop    @@next_line

  @@ret:
        pop     si
        pop     di
        ret

ENDP    OccupyObject





;--------------------------------------------------------------------------
;
;   NAME:           FreeObject
;
;   C-DECL:         void cdecl FreeObject(int x, int y, int obj, int rot);
;
;   DESCRIPTION:    Remove an object from the gameboardarray
;
;   PARAMETERS:     (x,y) - position on gameboard
;                   obj   - object number
;                   rot   - rotation number
;
;   RETURNS:        Nothing
;
;
PROC    FreeObject

        ARG     x: WORD, y: WORD, obj: WORD, rot: WORD

        push    di
        push    si

    ; Calculate the address of the object-data
        mov     ax, [obj]
        shl     ax, 1
        shl     ax, 1
        add     ax, [rot]
        mov     cl, 4
        shl     ax, cl
        add     ax, OFFSET Objects
        mov     bx, ax

    ; Treat the 4x4-object
        mov     di, [y]         ; DI contains Y-position on gameboard

        mov     cx, 4
  @@next_line:
        push    cx

        mov     si, [x]         ; SI contains X-position on gameboard

        mov     cx, 4
  @@next_col:

        cmp     [BYTE bx], 0
        jz      @@next_point

    ; Enter this position
        push    bx
        push    cx

        push    di
        push    si
        call    FreePos
        add     sp, 4

        pop     cx
        pop     bx

  @@next_point:
        inc     bx
        inc     si
        loop    @@next_col

        inc     di
        pop     cx
        loop    @@next_line

  @@ret:
        pop     si
        pop     di
        ret

ENDP    FreeObject





;--------------------------------------------------------------------------
;
;   NAME:           ShowObject
;
;   C-DECL:         void cdecl ShowObject(int x, int y,
;                                         int obj, int rot,
;                                         int color);
;
;   DESCRIPTION:    Show the object at the given position.
;                   This function does nothing more. Nothing is
;                   done to the board.
;
;   PARAMETERS:     (x,y) - position on screenboard. (0,0) is upper
;                           left corner of _screen_, not gameboard!
;                   obj   - object number
;                   rot   - rotation number
;                   color - Color to show object in. This could be
;                           calculated as above, but now we get the
;                           chance to use this one to clear an object too.
;
;   RETURNS:        Nothing
;
;
PROC    ShowObject
PUBLIC  ShowObject

        ARG     x: WORD, y: WORD, obj: WORD, rot: WORD, color: WORD

        push    di
        push    si

    ; Calculate the address of the object-data
        mov     ax, [obj]
        shl     ax, 1
        shl     ax, 1
        add     ax, [rot]
        mov     cl, 4
        shl     ax, cl
        add     ax, OFFSET Objects
        mov     bx, ax

    ; Put the color in AX
        mov     ax, [color]

    ; Treat the 4x4-object
        mov     di, [y]         ; DI contains Y-position on screen

        mov     cx, 4
  @@next_line:
        push    cx

        mov     si, [x]         ; SI contains X-position on screen

        mov     cx, 4
  @@next_col:

        cmp     [BYTE bx], 0
        jz      @@next_point

    ; Show this block
        push    ax
        push    bx
        push    cx

        push    ax
        push    di
        push    si
        call    ShowBlock
        add     sp, 6

        pop     cx
        pop     bx
        pop     ax

  @@next_point:
        inc     bx
        inc     si
        loop    @@next_col

        inc     di
        pop     cx
        loop    @@next_line

  @@ret:
        pop     si
        pop     di
        ret

ENDP    ShowObject










;==========================================================================
;
;                     P U B L I C    F U N C T I O N S
;
;==========================================================================


;--------------------------------------------------------------------------
;
;   NAME:           ObjectColor
;
;   C-DECL:         int cdecl ObjectColor(int obj);
;
;   DESCRIPTION:    Get the correct color for the given object
;
;   PARAMETERS:     obj - Object number to get color of
;
;   RETURNS:        Color of the object
;
;
PROC    ObjectColor
PUBLIC  ObjectColor

        ARG     obj: WORD

        mov     bx, [obj]
        shl     bx, 1
        mov     ax, [Colors + bx]

  @@ret:
        ret

ENDP    ObjectColor





;--------------------------------------------------------------------------
;
;   NAME:           CreateNextObject
;
;   C-DECL:         int cdecl CreateNextObject(void);
;
;   DESCRIPTION:    Copy the already created "next"-object into the
;                   current, and create a new "next".
;                   Do neccesary screen-update.
;
;   PARAMETERS:     None
;
;   RETURNS:        0 - new object doesn't fit on screen, 1 - ok
;
;
PROC    CreateNextObject
PUBLIC  CreateNextObject

    ; Clear the previously showed next object
        xor     ax, ax          ; Display it in black
        push    ax
        push    [NextRot]
        push    [NextObj]
        mov     ax, NEXTY
        push    ax
        mov     ax, NEXTX
        push    ax
        call    ShowObject
        add     sp, 10

    ; Copy the "next" object to the current
        mov     ax, [NextObj]
        mov     [CurrObj], ax
        mov     ax, [NextRot]
        mov     [CurrRot], ax
        mov     [PosX], BOARDWIDTH / 2 - 2
        mov     [PosY], 0

    ; Create new "next" object
        mov     ax, NUMOBJ
        push    ax
        call    Random
        add     sp, 2
        mov     [NextObj], ax

        mov     ax, 4
        push    ax
        call    Random
        add     sp, 2
        mov     [NextRot], ax

    ; Show next object
        push    [NextObj]
        call    ObjectColor
        add     sp, 2
        push    ax

        push    [NextRot]
        push    [NextObj]
        mov     ax, NEXTY
        push    ax
        mov     ax, NEXTX
        push    ax
        call    ShowObject
        add     sp, 10

    ; Check if the new object touches something (game is over)
        push    [CurrRot]
        push    [CurrObj]
        push    [PosY]
        push    [PosX]
        call    ObjectFits
        add     sp, 8

  @@ret:
        ret

ENDP    CreateNextObject





;--------------------------------------------------------------------------
;
;   NAME:           ClearCurrObject
;
;   C-DECL:         void cdecl ClearCurrObject(void);
;
;   DESCRIPTION:    Clear the current object at its position. Update
;                   both gameboard and screen.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    ClearCurrObject
PUBLIC  ClearCurrObject

    ; Free the bytes used in the gameboard-table
        push    [CurrRot]
        push    [CurrObj]
        push    [PosY]
        push    [PosX]
        call    FreeObject
        add     sp, 8

    ; Show the current object without color.
        xor     ax, ax
        push    ax
        push    [CurrRot]
        push    [CurrObj]
        mov     ax, [PosY]
        add     ax, UPPERY
        push    ax
        mov     ax, [PosX]
        add     ax, UPPERX
        push    ax
        call    ShowObject
        add     sp, 10

  @@ret:
        ret

ENDP    ClearCurrObject





;--------------------------------------------------------------------------
;
;   NAME:           ShowCurrObject
;
;   C-DECL:         void cdecl ShowCurrObject(void);
;
;   DESCRIPTION:    Show the current object at its position. Update
;                   both gameboard and screen.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    ShowCurrObject
PUBLIC  ShowCurrObject

    ; Occupy the bytes in the gameboard-table
        push    [CurrObj]
        call    ObjectColor
        add     sp, 2
        push    ax

        push    [CurrRot]
        push    [CurrObj]
        push    [PosY]
        push    [PosX]
        call    OccupyObject
        add     sp, 10

    ; Show the current object with correct color.
        push    [CurrObj]
        call    ObjectColor
        add     sp, 2
        push    ax

        push    [CurrRot]
        push    [CurrObj]
        mov     ax, [PosY]
        add     ax, UPPERY
        push    ax
        mov     ax, [PosX]
        add     ax, UPPERX
        push    ax
        call    ShowObject
        add     sp, 10

  @@ret:
        ret

ENDP    ShowCurrObject





;--------------------------------------------------------------------------
;
;   NAME:           RotateLeft
;
;   C-DECL:         void cdecl RotateLeft(void);
;
;   DESCRIPTION:    Rotate the object to the left if possible
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    RotateLeft
PUBLIC  RotateLeft

    ; First clear the old object
        call    ClearCurrObject

    ; Rotate to the left
        mov     bx, [CurrRot]
        dec     bx
        jns     @@rot_ok
        mov     bx, 3

  @@rot_ok:
    ; Check if the "new" object fits on the board
        push    bx

        push    bx
        push    [CurrObj]
        push    [PosY]
        push    [PosX]
        call    ObjectFits
        add     sp, 8

        pop     bx

        or      ax, ax
        jz      @@show_object   ; Didn't fit

    ; Update new rotation
        mov     [CurrRot], bx

  @@show_object:
    ; Show new position
        call    ShowCurrObject

  @@ret:
        ret

ENDP    RotateLeft





;--------------------------------------------------------------------------
;
;   NAME:           RotateRight
;
;   C-DECL:         void cdecl RotateRight(void);
;
;   DESCRIPTION:    Rotate the object to the right if possible
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    RotateRight
PUBLIC  RotateRight

    ; First clear the old object
        call    ClearCurrObject

    ; Rotate to the right
        mov     bx, [CurrRot]
        inc     bx
        cmp     bx, 3
        jbe     @@rot_ok
        mov     bx, 0

  @@rot_ok:
    ; Check if the "new" object fits on the board
        push    bx

        push    bx
        push    [CurrObj]
        push    [PosY]
        push    [PosX]
        call    ObjectFits
        add     sp, 8

        pop     bx

        or      ax, ax
        jz      @@show_object   ; Didn't fit

    ; Update new rotation
        mov     [CurrRot], bx

  @@show_object:
    ; Show new position
        call    ShowCurrObject

  @@ret:
        ret

ENDP    RotateRight





;--------------------------------------------------------------------------
;
;   NAME:           MoveLeft
;
;   C-DECL:         int cdecl MoveLeft(void);
;
;   DESCRIPTION:    Move object left if possible
;
;   PARAMETERS:     None
;
;   RETURNS:        0 - Couldn't move, 1 - Move OK.
;
;
PROC    MoveLeft
PUBLIC  MoveLeft

    ; First clear the old object
        call    ClearCurrObject

    ; Move left
        mov     bx, [PosX]
        dec     bx

    ; Check if the "new" object fits on the board
        push    bx

        push    [CurrRot]
        push    [CurrObj]
        push    [PosY]
        push    bx
        call    ObjectFits
        add     sp, 8

        pop     bx

        or      ax, ax
        jz      @@show_object   ; Didn't fit

    ; Update new position
        mov     [PosX], bx

    ; Set up returnvalue to "true"
        mov     ax, 1

  @@show_object:
    ; Show at new position
        push    ax
        call    ShowCurrObject
        pop     ax

  @@ret:
        ret

ENDP    MoveLeft





;--------------------------------------------------------------------------
;
;   NAME:           MoveRight
;
;   C-DECL:         int cdecl MoveRight(void);
;
;   DESCRIPTION:    Move object left if possible
;
;   PARAMETERS:     None
;
;   RETURNS:        0 - Couldn't move, 1 - Move OK.
;
;
PROC    MoveRight
PUBLIC  MoveRight

    ; First clear the old object
        call    ClearCurrObject

    ; Move left
        mov     bx, [PosX]
        inc     bx

    ; Check if the "new" object fits on the board
        push    bx

        push    [CurrRot]
        push    [CurrObj]
        push    [PosY]
        push    bx
        call    ObjectFits
        add     sp, 8

        pop     bx

        or      ax, ax
        jz      @@show_object   ; Didn't fit

    ; Update new position
        mov     [PosX], bx

    ; Set up returnvalue to "true"
        mov     ax, 1

  @@show_object:
    ; Show at new position
        push    ax
        call    ShowCurrObject
        pop     ax

  @@ret:
        ret

ENDP    MoveRight





;--------------------------------------------------------------------------
;
;   NAME:           MoveDown
;
;   C-DECL:         int cdecl MoveDown(void);
;
;   DESCRIPTION:    Move object one line down if possible
;
;   PARAMETERS:     None
;
;   RETURNS:        0 - Couldn't move, 1 - Move OK.
;
;
PROC    MoveDown
PUBLIC  MoveDown

    ; First clear the old object
        call    ClearCurrObject

    ; Move down
        mov     bx, [PosY]
        inc     bx

    ; Check if the "new" object fits on the board
        push    bx

        push    [CurrRot]
        push    [CurrObj]
        push    bx
        push    [PosX]
        call    ObjectFits
        add     sp, 8

        pop     bx

        or      ax, ax
        jz      @@show_object   ; Didn't fit

    ; Update new position
        mov     [PosY], bx

    ; Set up returnvalue to "true"
        mov     ax, 1

  @@show_object:
    ; Show at new position
        push    ax
        call    ShowCurrObject
        pop     ax

  @@ret:
        ret

ENDP    MoveDown





;--------------------------------------------------------------------------
;
;   NAME:           MoveAllWayDown
;
;   C-DECL:         void cdecl MoveAllWayDown(void);
;
;   DESCRIPTION:    Move an object all the way down, and create a
;                   new objectprocess.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    MoveAllWayDown
PUBLIC  MoveAllWayDown

  @@one_more:
    ; Move down one line
        call    MoveDown

    ; Check if it was possible
        or      ax, ax
        jz      @@no_more

    ; Give score for this step
        xor     ax, ax
        push    ax
        mov     ax, [Level]
        inc     ax
        push    ax
        call    AddScore
        add     sp, 4

        jmp     @@one_more

  @@no_more:
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

ENDP    MoveAllWayDown










ENDS





        END
