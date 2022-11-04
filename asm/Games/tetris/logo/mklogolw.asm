        IDEAL
        MODEL   COMPACT

        ASSUME  cs: @code, ds: @data, es: NOTHING


DATASEG

page    DW      0

CODESEG

        EXTRN   setsegaddr: PROC, setvispage: PROC, mapmask: PROC
        EXTRN   setallpalette: PROC


        PUBLIC  _visbuffer

PROC    dekomprimer
        xor     di, di
        add     dx, si
        cld
@@whle: cmp     si, dx
        jae     @@ret
        lodsb
        cmp     al, 128
        jbe     @@ulike
        sub     al, 128
        xor     ch, ch
        mov     cl, al
        cmp     si, dx
        jae     @@ret
        lodsb
        rep     stosb
        jmp     @@whle
 ALIGN WORD
@@ulike:
        xor     ah, ah
        mov     cx, ax
        add     ax, si
        cmp     ax, dx
        jb      @@OK
        mov     cx, dx
        sub     cx, si
@@OK:   rep     movsb
        jmp     @@whle

@@ret:  ret
ENDP    dekomprimer


PROC    _visbuffer
        ARG     seg: WORD
        push    bp
        mov     bp, sp
        push    di
        push    si
        mov     bx, [page]
        xor     bx, 1
        mov     [page], bx
        call    setsegaddr
        push    ds
        mov     ds, [seg]
        mov     si, 18      ; Etter paletten

        mov     ah, 1
        call    mapmask
        mov     dx, [si]    ; Antall
        inc     si
        inc     si
        call    dekomprimer

        mov     ah, 4
        call    mapmask
        mov     dx, [si]    ; Antall
        inc     si
        inc     si
        call    dekomprimer


        mov     ah, 2
        call    mapmask
        mov     dx, [si]    ; Antall
        inc     si
        inc     si
        call    dekomprimer

        mov     ah, 8
        call    mapmask
        mov     dx, [si]    ; Antall
        inc     si
        inc     si
        call    dekomprimer


@@ret:  pop     ds
        mov     es, [seg]
        xor     di, di
        call    setallpalette
        mov     ax, [page]
        call    setvispage
        pop     si
        pop     di
        pop     bp
        ret
ENDP    _visbuffer


ENDS

        END
