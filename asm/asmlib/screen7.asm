        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING



;--------------------------;
;                          ;
;         D A T A          ;
;                          ;
;--------------------------;

UDATASEG

        EXTRN   antkol2: WORD
        EXTRN   sadr: DWORD





;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        PUBLIC  gettext, puttext



;
; gettext
;
; Hva prosedyren gjõr:
;   Kopierer deler av skjermen til angitt buffer.
;   Koordinatene starter pÜ 0, og er uavhengige at evt. vindu.
;
; Kall med:
;   AL    : ùverste venstre X-koordinat
;   AH    : ùverste venstre Y-koordinat
;   DL    : Nederste hõyre X-koordinat
;   DH    : Nederste hõyre Y-koordinat
;   ES:DI : ùnsket buffer
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    gettext
        push    ax
        push    bx
        push    cx
        push    dx
        push    es
        push    ds
        push    si
        push    di
        mov     cx, ax     ; Spar AX i CX.
        mov     al, ah
        xor     ah, ah
        mov     bx, [antkol2]
        push    dx
        mul     bx
        pop     dx
        mov     bl, cl     ; bl=X1
        xor     bh, bh
        shl     bx, 1
        add     ax, bx

        mov     bx, [antkol2]
        lds     si, [DWORD sadr]
        add     si, ax
        mov     ax, bx     ; ax=antkol2

        sub     dl, cl     ; dl=X2-X1
        mov     cl, dh     ; cl=Y2
        xor     dh, dh
        inc     dx
        sub     cl, ch     ; cl-=Y1
        xor     ch, ch
        inc     cx
@@l1:   push    cx
        mov     cx, dx
        push    si
        cld
        rep     movsw
        pop     si
        add     si, ax
        pop     cx
        loop    @@l1
        pop     di
        pop     si
        pop     ds
        pop     es
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    gettext


;
; puttext
;
; Hva prosedyren gjõr:
;   Kopierer tekst fra angitt buffer til angitt omrÜde pÜ skjermen.
;   Koordinatene starter pÜ 0, og er uavhengige av evt. vindu.
;
; Kall med:
;   AL    : ùverste venstre X-koordinat
;   AH    : ùverste venstre Y-koordinat
;   DL    : Nederste hõyre X-koordinat
;   DH    : Nederste hõyre Y-koordinat
;   ES:DI : ùnsket buffer
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    puttext
        push    ax
        push    bx
        push    cx
        push    dx
        push    es
        push    ds
        push    si
        push    di
        mov     cx, ax     ; Spar AX i CX.
        mov     al, ah
        xor     ah, ah
        mov     bx, [antkol2]
        push    dx
        mul     bx
        pop     dx
        mov     bl, cl     ; bl=X1
        xor     bh, bh
        shl     bx, 1
        add     ax, bx

        mov     bx, [antkol2]
        push    es
        push    di
        les     di, [DWORD sadr]
        add     di, ax
        mov     ax, bx     ; ax=antkol2

        pop     si
        pop     ds
        sub     dl, cl     ; dl=X2-X1
        mov     cl, dh     ; cl=Y2
        xor     dh, dh
        inc     dx
        sub     cl, ch     ; cl-=Y1
        xor     ch, ch
        inc     cx
@@l1:   push    cx
        mov     cx, dx
        push    di
        cld
        rep     movsw
        pop     di
        add     di, ax
        pop     cx
        loop    @@l1
        pop     di
        pop     si
        pop     ds
        pop     es
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    puttext


        END
