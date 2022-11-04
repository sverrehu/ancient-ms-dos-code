
;==========================================================================
;
;   FILE:           BOARD.ASM
;
;   MODULE OF:      TETRIS
;
;   DESCRIPTION:    Functions and data to handle the "playground"
;
;
;   WRITTEN BY:     Sverre H. Huseby
;
;==========================================================================

        IDEAL

        MODEL   MDL, C

        ASSUME  cs: @code, ds: @data





INCLUDE "SCORE.INC"
INCLUDE "SCREEN.INC"
INCLUDE "TETRIS.INC"





UDATASEG



;==========================================================================
;
;                        P R I V A T E    D A T A
;
;==========================================================================


Board       DB  BOARDSIZE DUP (?)       ; The board itself
LineBlocks  DB  BOARDHEIGHT DUP (?)     ; Number of blocks on each line
WaitLevChg  DW  ?                       ; Count untill level changes










CODESEG



;==========================================================================
;
;                    P R I V A T E    F U N C T I O N S
;
;==========================================================================


;--------------------------------------------------------------------------
;
;   NAME:           RemoveLine
;
;   C-DECL:         void cdecl RemoveLine(int line);
;
;   DESCRIPTION:    Remove the given line by pushing the lines above
;                   one step down, and filling in blanks at the
;                   topline.
;
;                   !!! The screen is not updated
;
;   PARAMETERS:     line - number of the line to remove
;
;   RETURNS:        Nothing
;
;
PROC    RemoveLine

        ARG     line: WORD

        push    di
        push    si

        push    ds
        pop     es

    ; First remove the "number of blocks on line"-entry
        mov     cx, [line]
        jcxz    @@clear_1
        mov     di, cx
        add     di, OFFSET LineBlocks
        mov     si, di
        dec     si

        std
        rep     movsb

  @@clear_1:
    ; Clear the first entry
        mov     [LineBlocks], 0

    ; Then remove the line itself
        mov     ax, [line]
        mov     bl, BOARDWIDTH
        mul     bl
        mov     cx, ax
        jcxz    @@clear_2
        mov     si, ax
        add     si, OFFSET Board - 1
        mov     di, si
        add     di, BOARDWIDTH

        rep     movsb

  @@clear_2:
    ; Clear the topline
        mov     cx, BOARDWIDTH
        xor     al, al
        mov     di, OFFSET Board

        cld
        rep     stosb

    ; A line is removed. First give score
        xor     ax, ax
        push    ax
        mov     ax, [Level]
        inc     ax
        mov     cl, 5
        shl     ax, cl
        push    ax
        call    AddScore
        add     sp, 4

    ; then decrease the "level change counter"
        dec     [WaitLevChg]
        jns     @@ret

    ; The level should be increased
        mov     ax, [Level]
        cmp     ax, MAXLEVEL
        jae     @@ret

        inc     ax
        mov     [Level], ax
        call    ShowLevel

        mov     [WaitLevChg], COUNTLEVEL

  @@ret:
        pop     si
        pop     di
        ret

ENDP    RemoveLine










;==========================================================================
;
;                     P U B L I C    F U N C T I O N S
;
;==========================================================================


;--------------------------------------------------------------------------
;
;   NAME:           ClearBoard
;
;   C-DECL:         void cdecl ClearBoard(void);
;
;   DESCRIPTION:    Clear the entire board by entering 0's in all positions
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    ClearBoard
PUBLIC  ClearBoard

        push    di

        push    ds
        pop     es

        xor     al, al

        cld

    ; Clear the board itself
        mov     cx, BOARDSIZE
        mov     di, OFFSET Board
        rep     stosb

    ; Clear the number of blocks on each line
        mov     cx, BOARDHEIGHT
        mov     di, OFFSET LineBlocks
        rep     stosb

    ; Initiate the levelcounter
        mov     [WaitLevChg], COUNTLEVEL

        pop     di

        ret

ENDP    ClearBoard





;--------------------------------------------------------------------------
;
;   NAME:           OccupyPos
;
;   C-DECL:         void cdecl OccupyPos(int x, int y, int color);
;
;   DESCRIPTION:    Mark a position on the board as used by entering
;                   a color
;
;   PARAMETERS:     (x, y) - Position. (0,0) is upper left
;                   color  - Color code
;
;   RETURNS:        Nothing
;
;
PROC    OccupyPos
PUBLIC  OccupyPos

        ARG     x: WORD, y: WORD, color: WORD

    ; Calculate position in the boardarray
        mov     ax, [y]
        mov     bl, BOARDWIDTH
        mul     bl

        add     ax, [x]

        add     ax, OFFSET Board

        mov     bx, ax

    ; Mark it as occupied
        mov     ax, [color]
        mov     [BYTE bx], al

    ; Update number of blocks on this line
        mov     bx, [y]
        inc     [LineBlocks + bx]

  @@ret:
        ret

ENDP    OccupyPos





;--------------------------------------------------------------------------
;
;   NAME:           FreePos
;
;   C-DECL:         void cdecl FreePos(int x, int y);
;
;   DESCRIPTION:    Mark a position on the board as free
;
;   PARAMETERS:     (x, y) - Position. (0,0) is upper left
;
;   RETURNS:        Nothing
;
;
PROC    FreePos
PUBLIC  FreePos

        ARG     x: WORD, y: WORD

    ; Calculate position in the boardarray
        mov     ax, [y]
        mov     bl, BOARDWIDTH
        mul     bl

        add     ax, [x]

        add     ax, OFFSET Board

        mov     bx, ax

    ; Mark it as free
        mov     [BYTE bx], 0

    ; Update number of blocks on this line
        mov     bx, [y]
        dec     [LineBlocks + bx]

  @@ret:
        ret

ENDP    FreePos





;--------------------------------------------------------------------------
;
;   NAME:           IsOccupied
;
;   C-DECL:         int cdecl IsOccupied(int x, int y);
;
;   DESCRIPTION:    Check if a cell is occupied.
;                   If the cell is outside the board, it is
;                   considered occupied.
;
;   PARAMETERS:     (x, y) - Position. (0,0) is upper left
;
;   RETURNS:        0 - not occupied, otherwise color of cell
;
;
PROC    IsOccupied
PUBLIC  IsOccupied

        ARG     x: WORD, y: WORD

    ; Check if outside board
        mov     ax, [x]
        cmp     ax, BOARDWIDTH
        jae     @@outside
        mov     ax, [y]
        cmp     ax, BOARDHEIGHT
        jb      @@not_outside

  @@outside:
    ; The location is outside the board. Consider it occupied.
        mov     ax, 1
        jmp     SHORT @@ret

  @@not_outside:
    ; Calculate position in the boardarray
        mov     ax, [y]
        mov     bl, BOARDWIDTH
        mul     bl

        add     ax, [x]

        add     ax, OFFSET Board

        mov     bx, ax

    ; Get returnvalue
        mov     al, [BYTE bx]
        xor     ah, ah

  @@ret:
        ret

ENDP    IsOccupied





;--------------------------------------------------------------------------
;
;   NAME:           RemoveFullLines
;
;   C-DECL:         void cdecl RemoveFullLines(void);
;
;   DESCRIPTION:    Removes any lines with all positions occupied.
;                   If lines are moved, the entire board is redrawn,
;                   and score is updated.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    RemoveFullLines
PUBLIC  RemoveFullLines

        mov     bx, BOARDHEIGHT - 1
  @@next_line:

    ; Check if this line should be removed
        cmp     [LineBlocks + bx], BOARDWIDTH
        jb      @@goto_next_line

    ; This line should be removed
        push    bx

        push    bx
        call    RemoveLine
        add     sp, 2

        call    ShowBoard

        pop     bx

    ; When a line is removed, we should not move to the previous line,
    ; since that one has now become the current.
        jmp     @@next_line

  @@goto_next_line:
        dec     bx
        jns     @@next_line

  @@ret:
        ret

ENDP    RemoveFullLines










ENDS





        END
