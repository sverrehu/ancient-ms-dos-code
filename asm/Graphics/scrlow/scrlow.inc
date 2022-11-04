
MACRO   TEST_INIT
        cmp     [BYTE init], 0
        jne     @@init_er_utfort
        call    PROC _init_scrlow
  @@init_er_utfort:
ENDM    TEST_INIT


MACRO   SETT_DS
 IF @DataSize NE 0
        push    ds
        push    ax
        mov     ax, @data
        mov     ds, ax
        pop     ax
 ENDIF
ENDM    SETT_DS


MACRO   RESETT_DS
 IF @DataSize NE 0
        pop     ds
 ENDIF
ENDM    RESETT_DS
