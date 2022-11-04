
;==========================================================================
;
;   FILE:           LOGO.ASM
;
;   MODULE OF:      TETRIS
;
;   DESCRIPTION:    Shows the logo on the screen
;
;
;   WRITTEN BY:     Sverre H. Huseby
;
;==========================================================================

        IDEAL

        MODEL   MDL, C

        ASSUME  cs: @code, ds: @data





INCLUDE "SCREENLW.INC"





SCROFFS     EQU 80 * 11 + 39    ; The logo's offset from screenstart





DATASEG



            EXTRN LogoData: PTR, LOGOX: ABS, LOGOY: ABS
            EXTRN ScreenSeg: WORD










CODESEG



;==========================================================================
;
;                    P R I V A T E    F U N C T I O N S
;
;==========================================================================


;--------------------------------------------------------------------------
;
;   NAME:           ShowBitPlane
;
;   C-DECL:         void cdecl ShowBitPlane(void);
;
;   DESCRIPTION:    Shows one of the logo's bitplanes
;
;   PARAMETERS:     None
;
;   REGISTERS:      ES:DI - Pointer to start of screen
;                   DS:SI - Pointer to start of bitplanedata
;
;                   SI is left after the data
;
;   RETURNS:        Nothing
;
;
PROC    ShowBitPlane

        push    di

        cld
        mov     cx, LOGOY
  @@y_loop:
        push    cx
        push    di

        mov     cx, LOGOX
        rep     movsb

        pop     di
        add     di, 80
        pop     cx
        loop    @@y_loop

  @@ret:
        pop     di
        ret

ENDP    ShowBitPlane










;==========================================================================
;
;                     P U B L I C    F U N C T I O N S
;
;==========================================================================


;--------------------------------------------------------------------------
;
;   NAME:           ShowLogo
;
;   C-DECL:         void cdecl ShowLogo(void);
;
;   DESCRIPTION:    Shows the logo at it's screen position
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    ShowLogo
PUBLIC  ShowLogo

        push    di
        push    si

        xor     ax, ax
        push    ax
        call    EnableSetReset
        add     sp, 2

        mov     ax, 255
        push    ax
        call    BitMask
        add     sp, 2

        mov     es, [ScreenSeg]
        mov     di, SCROFFS

        mov     si, OFFSET LogoData

        mov     ax, 1
        push    ax
        call    MapMask
        add     sp, 2

        call    ShowBitPlane

        mov     ax, 2
        push    ax
        call    MapMask
        add     sp, 2

        call    ShowBitPlane

        mov     ax, 4
        push    ax
        call    MapMask
        add     sp, 2

        call    ShowBitPlane

        mov     ax, 8
        push    ax
        call    MapMask
        add     sp, 2

        call    ShowBitPlane

        mov     ax, 15
        push    ax
        call    MapMask
        call    EnableSetReset
        add     sp, 2

  @@ret:
        pop     si
        pop     di
        ret

ENDP    ShowLogo










ENDS





        END
