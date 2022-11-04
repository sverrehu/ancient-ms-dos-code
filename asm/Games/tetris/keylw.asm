
;==========================================================================
;
;   FILE:           KEYLW.ASM
;
;   MODULE OF:      TETRIS
;
;   DESCRIPTION:    Routines to read from the keyboard
;
;
;   WRITTEN BY:     Sverre H. Huseby
;
;==========================================================================

        IDEAL

        MODEL   MDL, C

        ASSUME  cs: @code, ds: @data










CODESEG



;==========================================================================
;
;                     P U B L I C    F U N C T I O N S
;
;==========================================================================


;--------------------------------------------------------------------------
;
;   NAME:           KeyPressed
;
;   C-DECL:         int cdecl KeyPressed(void);
;
;   DESCRIPTION:    Check if a key is waiting
;
;   PARAMETERS:     None
;
;   RETURNS:        0 - no key waiting, 1 - key waiting
;
;
PROC    KeyPressed
PUBLIC  KeyPressed

        mov     ah, 1           ; Get Keyboard Status
        int     16h

        jz      @@no_key

    ; A key is waiting. Return "true"
        mov     ax, 1
        jmp     SHORT @@ret

  @@no_key:
    ; No ket is waiting. Return "false"
        xor     ax, ax

  @@ret:
        ret

ENDP    KeyPressed





;--------------------------------------------------------------------------
;
;   NAME:           GetKey
;
;   C-DECL:         int cdecl GetKey(void);
;
;   DESCRIPTION:    Reads a key from the keyboard. If no key is
;                   available, the function waits for one.
;
;   PARAMETERS:     None
;
;   RETURNS:        ASCII-code of key, or negative scancode if
;                   "special" key.
;
;
PROC    GetKey
PUBLIC  GetKey

    ; Get a key
        xor     ah, ah          ; Read a Character from Keyboard
        int     16h

    ; Check if extended key
        or      al, al
        jnz     @@not_extended

    ; This is an extended key. Return its negative scancode
        mov     al, ah
        xor     ah, ah
        neg     ax
        jmp     SHORT @@ret

  @@not_extended:
    ; Return ASCII-code only
        xor     ah, ah

  @@ret:
        ret

ENDP    GetKey










ENDS





        END
