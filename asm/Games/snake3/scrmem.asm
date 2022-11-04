        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING


UDATASEG

smem    DB      (80 * 58) DUP (?)       ; Buffer for koder p† skjermen



CODESEG

        PUBLIC  clearsmem, setpos, getpos



PROC    clearsmem
        push    ax
        push    cx
        push    di
        push    es
        push    ds
        pop     es
        mov     di, OFFSET smem
        mov     cx, 80 * 58 / 2
        xor     ax, ax
        cld
        rep     stosw
        pop     es
        pop     di
        pop     cx
        pop     ax
        ret
ENDP    clearsmem



;
; setpos
;
; Hva prosedyren gj›r:
;   Setter angitt kode inn i smem p† angitt koordinatpar.
;
; Kall med:
;   DL : X-koordinat  (0-79)
;   DH : Y-koordinat  (0-57)
;   AL : Kode som skal settes inn
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
ALIGN WORD
PROC    setpos
        push    ax
        push    bx
        push    cx
        push    dx
        push    di

  ; Beregn skjermadressen og legg denne i DI. Dette er 80*y+x, som er
  ; 64 * y + 16 * y + x = y << 6 + y << 4 + x
        mov     cl, dl
        xor     ch, ch
        mov     di, cx

        mov     bl, dh
        xor     bh, bh
        mov     cl, 4
        shl     bx, cl
        mov     dx, bx
        shl     dx, 1
        shl     dx, 1
        add     dx, bx
        add     di, dx

  ; Sett inn angitt kode p† funnet posisjon
        mov     [smem + di], al

@@ret:
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    setpos



;
; getpos
;
; Hva prosedyren gj›r:
;   Returnerer koden for det som befinner seg i angitt posisjon p† skjermen.
;
; Kall med:
;   DL : X-pos (0-79)
;   DH : Y-pos (0-57)
;
; Returnerer:
;   AL : Innholdet i angitt posisjon
;
; Endrer innholdet i:
;   AX
;
PROC    getpos
        push    bx
        push    cx
        push    dx
        push    si

        mov     cl, dl
        xor     ch, ch
        mov     si, cx

        mov     bl, dh
        xor     bh, bh
        mov     cl, 4
        shl     bx, cl
        mov     dx, bx
        shl     dx, 1
        shl     dx, 1
        add     dx, bx
        add     si, dx

        mov     al, [smem + si]
        xor     ah, ah

        pop     si
        pop     dx
        pop     cx
        pop     bx
        ret
ENDP    getpos



        END
