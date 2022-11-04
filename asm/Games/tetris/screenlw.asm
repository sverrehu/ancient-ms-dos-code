
;==========================================================================
;
;   FILE:           SCREENLW.ASM
;
;   MODULE OF:      TETRIS
;
;   DESCRIPTION:    Contains low level routines that takes care of
;                   screen output
;
;
;   WRITTEN BY:     Sverre H. Huseby
;
;==========================================================================

        IDEAL

        MODEL   MDL, C

        ASSUME  cs: @code, ds: @data





MAXX        EQU 639
MAXY        EQU 349
PLANES      EQU 2
PLANE0      EQU 0A000h
PLANE1      EQU 0A800h
PLENGTH     EQU 8000h   ; Length of each plane-buffer

SEQAP       EQU 03C4h   ; Sequencer Registers Address Port
MAPMSK      EQU 2       ; Map Mask Register Index (Sequencer Reg.)
GCONAP      EQU 03CEh   ; Graphics Controller Registers Address Port
SETRES      EQU 0       ; Set/Reset Register Index (Graphics Contr. Reg.)
ENBLSETRES  EQU 1       ; Enable Set/Reset Register Index (Graphics Contr. Reg.)
FSDR        EQU 3       ; Function Select / Data Rotate (Graphics Contr. Reg.)
READMAP     EQU 4       ; Read Map Select Register Index (Graphics Contr. Reg.)
BITMSK      EQU 8       ; Bit Mask Register Index (Graphics Contr. Reg.)
CRTCAP      EQU 03D4h   ; CRT Controller Registers Address Port
SADHI       EQU 0Ch     ; Start Address High
SADLO       EQU 0Dh     ; Start Address Low





DATASEG


            EXTRN Characters: PTR



;==========================================================================
;
;                        P R I V A T E    D A T A
;
;==========================================================================


OldScrMode  DB  -1      ; Original screenmode
LeftMost    DB  0       ; Leftmost character pos. Used when CR/LF is showed










;==========================================================================
;
;                         P U B L I C    D A T A
;
;==========================================================================


           PUBLIC  ScreenSeg


ScreenSeg  DW  PLANE0   ; Current screensegmentaddress










CODESEG



;==========================================================================
;
;                     P U B L I C    F U N C T I O N S
;
;==========================================================================


;--------------------------------------------------------------------------
;
;   NAME:           EnterGraphics
;
;   C-DECL:         int cdecl EnterGraphics(void);
;
;   DESCRIPTION:    Switch to EGA mode 10h, 640x350x16, color.
;                   Must be at least 126 kb on EGA-card to get 16 colors.
;
;   PARAMETERS:     None
;
;   RETURNS:        0 - Error, 1 - OK
;
;
PROC    EnterGraphics
PUBLIC  EnterGraphics

        mov     ah, 12h         ; Get Configuration Info
        mov     bl, 10h
        int     10h

        cmp     bl, 10h         ; If equal: Not EGA
        je      @@no_graph

        cmp     bh, 1           ; If equal: Monochrome
        je      @@no_graph

        or      bl, bl          ; If equal: Only 64 kb on EGA. Not 16 colors
        jne     @@graph_ok

  @@no_graph:
    ; Couldn't enter graphics mode. Return with error code.
        xor     ax, ax
        jmp     SHORT @@ret

  @@graph_ok:
    ; Get the current video mode so this can be set back later.
        mov     ah, 0Fh         ; Get video mode
        int     10h
        mov     [OldScrMode], al

    ; Enter the correct mode
        mov     ax, 10h         ; Set Video Mode 10h
        int     10h

    ; Perform an extra test, just in case ...
        mov     ah, 0Fh         ; Get video mode
        int     10h
        cmp     al, 10h
        jne     @@no_graph

    ; Return with OK-code
        mov     ax, 1

  @@ret:
        ret

ENDP    EnterGraphics





;--------------------------------------------------------------------------
;
;   NAME:           EnterText
;
;   C-DECL:         void cdecl EnterText(void);
;
;   DESCRIPTION:    Reenter textmode after graphicsmode
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    EnterText
PUBLIC  EnterText

    ; Fetch the original mode, and test if it is set.
        mov     al, [OldScrMode]
        cmp     al, -1
        je      @@ret

    ; Set original screenmode
        xor     ah, ah          ; Set Video Mode
        int     10h

    ; And, to be sure, mark that it is set back.
        mov     [BYTE OldScrMode], -1

  @@ret:
        ret

ENDP    EnterText





;--------------------------------------------------------------------------
;
;   NAME:           MapMask
;
;   C-DECL:         void cdecl MapMask(int planes);
;
;   DESCRIPTION:    Decide what bitplanes are to be set during writing
;                   to screen memory.
;
;   PARAMETERS:     planes - bitmask that indicates the planes. 0-15
;
;   RETURNS:        Nothing
;
;
PROC    MapMask
PUBLIC  MapMask

        ARG     planes: WORD

        mov     dx, SEQAP
        mov     al, MAPMSK
        mov     ah, [BYTE planes]
        out     dx, ax
        ret

ENDP    MapMask





;--------------------------------------------------------------------------
;
;   NAME:           BitMask
;
;   C-DECL:         void cdecl BitMask(int mask);
;
;   DESCRIPTION:    Decide what bits are to be updated during writing
;                   to screen memory.
;
;   PARAMETERS:     mask - bitmask that indicates the bits. 0-255
;
;   RETURNS:        Nothing
;
;
PROC    BitMask
PUBLIC  BitMask

        ARG     mask: WORD

        mov     dx, GCONAP
        mov     al, BITMSK
        mov     ah, [BYTE mask]
        out     dx, ax
        ret

ENDP    BitMask





;--------------------------------------------------------------------------
;
;   NAME:           SetReset
;
;   C-DECL:         void cdecl SetReset(int color);
;
;   DESCRIPTION:    Specify what colorvalue the planes given by EnableSetReset
;                   should get for each bit written to screen memory.
;
;   PARAMETERS:     color - Color code 0-15
;
;   RETURNS:        Nothing
;
;
PROC    SetReset
PUBLIC  SetReset

        ARG     color: WORD

        mov     dx, GCONAP
        mov     al, SETRES
        mov     ah, [BYTE color]
        out     dx, ax
        ret

ENDP    SetReset





;--------------------------------------------------------------------------
;
;   NAME:           EnableSetReset
;
;   C-DECL:         void cdecl EnableSetReset(int planes);
;
;   DESCRIPTION:    Specify what planes are to be updated by the
;                   SetReset-color when data is written to screen memory.
;                   Planes not set here, gets the value that is written.
;
;   PARAMETERS:     planes - bitmask for planes, 0-15
;
;   RETURNS:        Nothing
;
;
PROC    EnableSetReset
PUBLIC  EnableSetReset

        ARG     planes: WORD

        mov     dx, GCONAP
        mov     al, ENBLSETRES
        mov     ah, [BYTE planes]
        out     dx, ax
        ret

ENDP    EnableSetReset





;--------------------------------------------------------------------------
;
;   NAME:           ShowBlock
;
;   C-DECL:         void cdecl ShowBlock(int x, int y, int color);
;
;   DESCRIPTION:    Displays an 16x11-size tetrisblock at the given position
;
;   PARAMETERS:     (x, y) - Position.    0 <= x <= 39    0 <= y <= 30
;                   color  - Color of block
;
;   RETURNS:        Nothing
;
;
PROC    ShowBlock
PUBLIC  ShowBlock

        ARG     x: WORD, y: WORD, color: WORD

        push    di

    ; Calculate the screenaddress, and save it in DI. The address is:
    ;         (80 * 11 * y + 2 * x)
    ;       = (880 * y + 2 * x)
    ;       = (512 * y + 256 * y + 64 * y + 32 * y + 16 * y + 2 * x)
        mov     di, [x]
        shl     di, 1           ;                   x * 2

        mov     ax, [y]
        mov     cl, 4
        shl     ax, cl          ;                   y * 16
        add     di, ax
        shl     ax, 1           ; (y * 16)  * 2 =   y * 32
        add     di, ax
        shl     ax, 1           ; (y * 32)  * 2 =   y * 64
        add     di, ax
        shl     ax, 1
        shl     ax, 1           ; (y * 64)  * 4 =   y * 256
        add     di, ax
        shl     ax, 1           ; (y * 256) * 2 =   y * 512
        add     di, ax

    ; Fetch the screensegment
        mov     es, [ScreenSeg]

    ; First remove whatever is on the same location. Zero out all bitplanes
        mov     dx, SEQAP
        mov     al, MAPMSK
        mov     ah, 15          ; All bitplanes
        out     dx, ax
        mov     dx, GCONAP
        mov     ax, ENBLSETRES + 0 * 256
        out     dx, ax

    ; Clear the 11 lines
        mov     cx, 11
        xor     al, al
        cld

        push    di
  @@clear_next_line:
        stosb
        stosb
        add     di, 78
        loop    @@clear_next_line
        pop     di

    ; Set up for correct color
        mov     dx, SEQAP
        mov     al, MAPMSK
        mov     ah, [BYTE color]
        out     dx, ax

    ; Show the 10 first lines - the last one should not be colored
        mov     cx, 10
        cld

        mov     ax, 1111111011111111b   ; The rightmost bit should not be set
  @@next_line:
        stosw
        add     di, 78
        loop    @@next_line

    ; Set back default values for the EGA-card
        mov     ax, MAPMSK + 15 * 256
        out     dx, ax
        mov     dx, GCONAP
        mov     ax, ENBLSETRES + 15 * 256
        out     dx, ax

  @@ret:
        pop     di

        ret

ENDP    ShowBlock





;--------------------------------------------------------------------------
;
;   NAME:           ShowObj16x11
;
;   C-DECL:         void cdecl ShowObj16x11(int x, int y, char *data);
;
;   DESCRIPTION:    Displays an 16x11-size "object" at the given position
;
;   PARAMETERS:     (x, y) - Position.    0 <= x <= 39    0 <= y <= 30
;                   data   - Pointer to objectdata
;
;   RETURNS:        Nothing
;
;
PROC    ShowObj16x11
PUBLIC  ShowObj16x11

        ARG     x: WORD, y: WORD, objdata: PTR

        push    di
        push    si

    ; Calculate the screenaddress, and save it in DI. The address is:
    ;         (80 * 11 * y + 2 * x)
    ;       = (880 * y + 2 * x)
    ;       = (512 * y + 256 * y + 64 * y + 32 * y + 16 * y + 2 * x)
        mov     di, [x]
        shl     di, 1           ;                   x * 2

        mov     ax, [y]
        mov     cl, 4
        shl     ax, cl          ;                   y * 16
        add     di, ax
        shl     ax, 1           ; (y * 16)  * 2 =   y * 32
        add     di, ax
        shl     ax, 1           ; (y * 32)  * 2 =   y * 64
        add     di, ax
        shl     ax, 1
        shl     ax, 1           ; (y * 64)  * 4 =   y * 256
        add     di, ax
        shl     ax, 1           ; (y * 256) * 2 =   y * 512
        add     di, ax

    ; Fetch the segmentaddress
        mov     es, [ScreenSeg]

    ; Get address of the objectdata
        mov     si, [objdata]

    ; Make sure exactly the bits we send to the screen are displayed
        mov     dx, GCONAP
        mov     ax, ENBLSETRES + 0 * 256
        out     dx, ax

    ; There are 4 bitplanes to copy data onto
        mov     cx, 4

  @@next_plane:
        push    cx

    ; Make the correct bitplane active
        mov     ah, 00001000b
        dec     cl
        shr     ah, cl
        inc     cl
        mov     dx, SEQAP
        mov     al, MAPMSK
        out     dx, ax

    ; Output the 11 lines of data for this bitplane
        mov     dx, GCONAP

        push    di

        mov     cx, 11
        cld

  @@next_line:
        lodsb
        stosb
        lodsb
        stosb
        add     di, 78
        loop    @@next_line

        pop     di

        pop     cx
        loop    @@next_plane

    ; Make all bitplanes active (as default)
        mov     dx, SEQAP
        mov     ax, MAPMSK + 15 * 256
        out     dx, ax

    ; And let all planes be updated by the SetReset-value (as default)
        mov     dx, GCONAP
        mov     ax, ENBLSETRES + 15 * 256
        out     dx, ax

  @@ret:
        pop     si
        pop     di

        ret

ENDP    ShowObj16x11





;--------------------------------------------------------------------------
;
;   NAME:           ShowChar8x6
;
;   C-DECL:         void cdecl ShowChar8x6(int x, int y, int chr, int color);
;
;   DESCRIPTION:    Show a character at the given position in the
;                   given color.
;
;   PARAMETERS:     (x, y) - Position.    0 <= x <= 79    0 <= y <= 57
;                   chr    - ASCII-code for character
;                   color  - Color 0-15
;
;   RETURNS:        Nothing
;
;
PROC    ShowChar8x6
PUBLIC  ShowChar8x6

        ARG     x: WORD, y: WORD, chr: WORD, color: WORD

        push    di
        push    si

    ; Get the coordinates
        mov     dl, [BYTE x]
        mov     dh, [BYTE y]

    ; Calculate the screenaddress, and save it in DI. The address is:
    ;         (80 * 6 * y + x)
    ;       = (480 * y + x)
    ;       = (512 * y - 32 * y + x)
    ;       = ((y << 8) << 1 - y << 5 + x)
        mov     di, [x]

        mov     bx, [y]
        mov     cl, 5
        shl     bx, cl

        xor     dl, dl
        mov     dh, [BYTE y]
        add     dx, dx

        sub     dx, bx
        add     di, dx

    ; Find the address of the character
        mov     al, [BYTE chr]
        sub     al, 32          ; First character is space
        mov     bl, 6
        mul     bl
        mov     bx, ax
        mov     si, bx
        add     si, OFFSET Characters

    ; Fetch the screensegment
        mov     es, [ScreenSeg]

    ; Set up for correct color
        mov     dx, SEQAP
        mov     al, MAPMSK
        mov     ah, [BYTE color]
        out     dx, ax
        mov     dx, GCONAP
        mov     ax, ENBLSETRES + 0 * 256
        out     dx, ax

    ; Show the 6 lines
        mov     cx, 6
        cld

  @@next_line:
        lodsb
        mov     [es: di], al
        add     di, 80
        loop    @@next_line

    ; Set back default values for the EGA-card
        mov     ax, ENBLSETRES + 15 * 256
        out     dx, ax
        mov     dx, SEQAP
        mov     ax, MAPMSK + 15 * 256
        out     dx, ax

  @@ret:
        pop     si
        pop     di

        ret

ENDP    ShowChar8x6





;--------------------------------------------------------------------------
;
;   NAME:           ShowText8x6
;
;   C-DECL:         void cdecl ShowText8x6(int x, int y, char *s, int col);
;
;   DESCRIPTION:    Shows an ASCIIZ-string with the first character at
;                   the given position, in the given color.
;
;                   The string might contain a value 11 to indicate
;                   a change of color. The next byte should give the
;                   color value.
;
;   PARAMETERS:     (x, y) - Position.    0 <= x <= 79    0 <= y <= 57
;                   s      - Pointer to the string
;                   color  - Color 0-15
;
;   RETURNS:        Nothing
;
;
PROC    ShowText8x6
PUBLIC  ShowText8x6

        ARG     x: WORD, y: WORD, s: PTR, color: WORD

        push    si

    ; Get the coordinates, the color and the address of the string
        mov     dl, [BYTE x]
        mov     dh, [BYTE y]

        mov     ah, [BYTE color]

        mov     si, [s]

    ; Store X-value so we can take care of CR/LF later
        mov     [LeftMost], dl

  @@more_chars:
    ; Check if there are more characters
        mov     al, [si]
        inc     si
        or      al, al
        jz      @@ret

    ; Check if special character
        cmp     al, 11          ; New color follows
        je      @@new_color
        cmp     al, 13
        je      @@do_CR
        cmp     al, 10
        je      @@do_LF

        jmp     SHORT @@normal_character

  @@new_color:
    ; Next byte is color code
        mov     ah, [si]
        inc     si
        jmp     @@more_chars

  @@do_LF:
    ; Perform lineshift
        inc     dh
        jmp     @@more_chars

  @@do_CR:
    ; Perform carriage return
        mov     dl, [LeftMost]
        jmp     @@more_chars

  @@normal_character:
    ; Show character at correct position
        push    ax
        push    dx
        xor     ch, ch
        mov     cl, ah
        push    cx
        mov     cl, al
        push    cx
        mov     cl, dh
        push    cx
        mov     cl, dl
        push    cx
        call    ShowChar8x6
        add     sp, 8
        pop     dx
        pop     ax

    ; Go to next position
        inc     dl
        jmp     @@more_chars

  @@ret:
        pop     si
        ret

ENDP    ShowText8x6





;--------------------------------------------------------------------------
;
;   NAME:           ShowNum8x6
;
;   C-DECL:         void cdecl ShowNum8x6(int x, int y,
;                                         unsigned long num,
;                                         int col);
;
;   DESCRIPTION:    Shows a number with the first character at
;                   the given position, in the given color.
;
;                   The number is right justified to 6 positions
;
;                   !!! The number must be <= 655350 !!!
;
;   PARAMETERS:     (x, y) - Position.    0 <= x <= 79    0 <= y <= 57
;                   num    - Number to show
;                   color  - Color 0-15
;
;   RETURNS:        Nothing
;
;
PROC    ShowNum8x6
PUBLIC  ShowNum8x6

        ARG     x: WORD, y: WORD, num: DWORD, color: WORD

        push    si

    ; Get the coordinates and the number
        mov     cx, [x]

        mov     ax, [WORD num]
        mov     dx, [WORD num + 2]

        mov     si, cx          ; For comparing position
        add     cx, 5           ; Position of last digit

  @@next_digit:
        mov     bx, 10
        div     bx
        mov     bx, dx
        xor     dx, dx

    ; Show this digit
        push    ax
        push    bx
        push    cx
        push    dx

        push    [color]
        add     bl, '0'
        push    bx
        push    [y]
        push    cx
        call    ShowChar8x6
        add     sp, 8

        pop     dx
        pop     cx
        pop     bx
        pop     ax

        dec     cx
        or      ax, ax
        jnz     @@next_digit

  @@fill_blanks:
    ; Fill out with blanks
        cmp     cx, si
        jb      @@ret

        push    cx

        push    [color]
        mov     ax, ' '
        push    ax
        push    [y]
        push    cx
        call    ShowChar8x6
        add     sp, 8

        pop     cx

        dec     cx
        jmp     @@fill_blanks

  @@ret:
        pop     si
        ret

ENDP    ShowNum8x6










ENDS





        END
