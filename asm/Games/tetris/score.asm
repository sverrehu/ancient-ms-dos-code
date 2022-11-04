
;==========================================================================
;
;   FILE:           SCORE.ASM
;
;   MODULE OF:      TETRIS
;
;   DESCRIPTION:    Routines to read and write highscore, update
;                   and show score etc.
;
;
;   WRITTEN BY:     Sverre H. Huseby
;
;==========================================================================

        IDEAL

        MODEL   MDL, C

        ASSUME  cs: @code, ds: @data





INCLUDE "SCREENLW.INC"
INCLUDE "SCREEN.INC"
INCLUDE "TETRIS.INC"





UDATASEG



;==========================================================================
;
;                        P R I V A T E    D A T A
;
;==========================================================================


Score       DD  ?               ; Current score
HighChanged DB  ?               ; Is highscore table changed?





DATASEG


HighFile    DB  PROGNAME, ".HGH", 0










;==========================================================================
;
;                         P U B L I C    D A T A
;
;==========================================================================


            PUBLIC Level, HighTable


Level       DW  ?               ; Current level

LABEL HighRecord BYTE
  HighID    DB  "Highscores, ", PROGNAME, 13, 10, 26
  HighTable DB  (10 * (15 + 4)) DUP (0)
LABEL HighRecEnd BYTE










CODESEG



;==========================================================================
;
;                     P U B L I C    F U N C T I O N S
;
;==========================================================================


;--------------------------------------------------------------------------
;
;   NAME:           ShowScore
;
;   C-DECL:         void cdecl ShowScore(void);
;
;   DESCRIPTION:    Shows the current score at the correct screenposition
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    ShowScore
PUBLIC  ShowScore

        mov     ax, 7
        push    ax
        push    [WORD Score + 2]
        push    [WORD Score]
        mov     ax, 15
        push    ax
        mov     ax, INSTRX + 10
        push    ax
        call    ShowNum8x6
        add     sp, 10

  @@ret:
        ret

ENDP    ShowScore





;--------------------------------------------------------------------------
;
;   NAME:           ShowLevel
;
;   C-DECL:         void cdecl ShowLevel(void);
;
;   DESCRIPTION:    Shows the current level at the correct screenposition
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    ShowLevel
PUBLIC  ShowLevel

        mov     ax, 7
        push    ax
        xor     ax, ax
        push    ax
        push    [WORD Level]
        mov     ax, 16
        push    ax
        mov     ax, INSTRX + 10
        push    ax
        call    ShowNum8x6
        add     sp, 10

  @@ret:
        ret

ENDP    ShowLevel





;--------------------------------------------------------------------------
;
;   NAME:           ClearScore
;
;   C-DECL:         void cdecl ClearScore(void);
;
;   DESCRIPTION:    Zeroes the score for a new game.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    ClearScore
PUBLIC  ClearScore

        xor     ax, ax
        mov     [WORD Score], ax
        mov     [WORD Score + 2], ax

  @@ret:
        ret

ENDP    ClearScore





;--------------------------------------------------------------------------
;
;   NAME:           AddScore
;
;   C-DECL:         void cdecl AddScore(long x);
;
;   DESCRIPTION:    Adds the given value to the score, and shows it
;                   on screen.
;
;   PARAMETERS:     x - Value to add
;
;   RETURNS:        Nothing
;
;
PROC    AddScore
PUBLIC  AddScore

        ARG     x: DWORD

        mov     ax, [WORD x]
        add     [WORD Score], ax
        mov     ax, [WORD x + 2]
        adc     [WORD Score + 2], ax

        call    ShowScore

  @@ret:
        ret

ENDP    AddScore





;--------------------------------------------------------------------------
;
;   NAME:           ReadHighScore
;
;   C-DECL:         void cdecl ReadHighScore(void);
;
;   DESCRIPTION:    Reads (if possible) the highscore file.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    ReadHighScore
PUBLIC  ReadHighScore

    ; The highscores has not changed
        mov     [HighChanged], 0

    ; Open highscorefile
        mov     ax, 3D00h       ; Open File, Read Access
        mov     dx, OFFSET HighFile
        int     21h
        jc      @@ret           ; Doesn't exist

        push    ax

    ; Read the table
        mov     ah, 3Fh         ; Read File or Device
        pop     bx
        mov     dx, OFFSET HighRecord
        mov     cx, OFFSET HighRecEnd - OFFSET HighRecord
        int     21h

    ; Close highscorefile
        mov     ah, 3Eh         ; Close file
        int     21h

  @@ret:
    ; Show table
        call    ShowHighScores

        ret

ENDP    ReadHighScore





;--------------------------------------------------------------------------
;
;   NAME:           WriteHighScore
;
;   C-DECL:         void cdecl WriteHighScore(void);
;
;   DESCRIPTION:    Writes the highscore file if highscores are changed
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    WriteHighScore
PUBLIC  WriteHighScore

    ; Check if highscores have changed. Don't write if not
        cmp     [HighChanged], 0
        jz      @@ret

    ; Open highscorefile
        mov     ah, 3Ch         ; Create or Truncate File
        mov     dx, OFFSET HighFile
        xor     cx, cx          ; Normal file
        int     21h
        jc      @@ret

        push    ax

    ; Write highscores
        mov     ah, 40h         ; Write File or Device
        pop     bx
        mov     dx, OFFSET HighRecord
        mov     cx, OFFSET HighRecEnd - OFFSET HighRecord
        int     21h

    ; Close the highscorefile
        mov     ah, 3Eh         ; Close file
        int     21h

    ; We no longer need to write it before it changes again
        mov     [HighChanged], 0

  @@ret:
        ret

ENDP    WriteHighScore





;--------------------------------------------------------------------------
;
;   NAME:           TestHighScore
;
;   C-DECL:         void cdecl TestHighScore(void);
;
;   DESCRIPTION:    Tests if the current score is a highscore, and updates
;                   the table if it is.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    TestHighScore
PUBLIC  TestHighScore

        push    si
        push    es

    ; Search from the top of the highscoretable to find where
    ; eventually the current score should be positioned
        mov     bx, OFFSET HighTable
        mov     cx, 10          ; There are 10 saved scores

  @@test_next:
        mov     ax, [bx + 17]   ; First test highbyte
        cmp     ax, [WORD Score + 2]
        jb      @@pos_found
        ja      @@loop_test_next
        mov     ax, [bx + 15]   ; Then lowbyte
        cmp     ax, [WORD Score]
        jb      @@pos_found
  @@loop_test_next:
        add     bx, 19
        loop    @@test_next

    ; If we get here, the current score isn't good enough. Jump out
        jmp     SHORT @@ret

  @@pos_found:
    ; Move the rest of the scores down
        push    cx
        dec     cx
        push    ds
        pop     es
        mov     di, OFFSET HighRecEnd - 1
        mov     si, OFFSET HighRecEnd - 19 - 1
        mov     ax, cx
        mov     dl, 19
        mul     dl
        mov     cx, ax
        std
        rep     movsb
        pop     cx

    ; Enter new score
        push    bx
        push    cx

        mov     ax, [WORD Score + 2]
        mov     [bx + 17], ax
        mov     ax, [WORD Score]
        mov     [bx + 15], ax
        mov     [BYTE bx], 0    ; Remove current name
        call    ShowHighScores

        pop     cx
        pop     bx

    ; Read name from user
        mov     ax, 3
        push    ax
        push    bx
        mov     ax, 10 + 47
        sub     ax, cx
        push    ax
        mov     ax, INSTRX + 4 + 4
        push    ax
        call    InputLine14
        add     sp, 8

    ; Tell that highscores have changed, so they are written to disk later
        mov     [HighChanged], 1

    ; Show new table
        call    ShowHighScores

    ; And, added in version 1.1: Write highscore now, in case the
    ; user turns the machine off before the game is finished.
        call    WriteHighScore

  @@ret:
        pop     si
        pop     di

        ret

ENDP    TestHighScore








ENDS





        END
