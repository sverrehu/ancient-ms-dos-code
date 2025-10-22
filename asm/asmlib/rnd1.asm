        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING


RNDNUMS EQU     100     ; Antall tall i bufferet


DATASEG

rndndex DW      0
rndbuf  DW      01F10h, 0A6E0h, 0DE6Dh, 0BAD1h, 0CC81h, 012DDh, 07D85h, 0745Bh
        DW      01B74h, 0F354h, 0B430h, 08828h, 0F89Eh, 05228h, 0F4C4h, 0EF3Ch
        DW      088F1h, 0907Dh, 0ABD4h, 0B3DBh, 0BDA3h, 0AAB8h, 07435h, 0558Ah
        DW      02827h, 0BC7Ch, 08AFAh, 06D0Ch, 00E31h, 0C4ADh, 08377h, 09065h
        DW      0BDB6h, 0A96Fh, 03B40h, 076D9h, 020E9h, 07C27h, 00E29h, 05CEDh
        DW      0923Eh, 0FD77h, 04A47h, 0A864h, 0F069h, 06145h, 0E3EDh, 0CC42h
        DW      0F25Fh, 052B5h, 069AFh, 06CCBh, 0BB53h, 03829h, 03862h, 0C384h
        DW      0AEB9h, 0B747h, 0EF18h, 04330h, 08445h, 078F2h, 02327h, 07BD3h
        DW      09BECh, 02D4Eh, 05422h, 03EB1h, 091E0h, 0CFC0h, 01FDEh, 0024Fh
        DW      01297h, 02AEAh, 0B66Eh, 08670h, 0EEC5h, 09CB2h, 08E26h, 0B818h
        DW      06F5Ch, 01A3Ch, 0579Ah, 0D58Ch, 0E992h, 073EAh, 0319Eh, 0D24Eh
        DW      092DAh, 0D962h, 01D47h, 0FB24h, 094E9h, 09D87h, 0B1E8h, 0DA11h
        DW      061B1h, 03A7Dh, 01115h, 05A5Ah


CODESEG

        PUBLIC  rnd, randomize

;
; rnd
;
; Hva prosedyren gj›r:
;   Finner tilfeldig tall
;
; Kall med:
;   AX : Tallgrense. Brukes som modulo.
;
; Returnerer:
;   AX : Tall mellom 0 og AX-1
;
; Endrer innholdet i:
;   AX
;
PROC    rnd
        push    bx
        push    cx
        push    dx
        mov     bx, [rndndex]
        mov     cx, ax
        mov     ax, [rndbuf + bx]
        xor     dx, dx
        div     cx
        mov     ax, dx  ; Resten i AX. Dette er tallet som skal returneres.
        inc     bx
        inc     bx
        cmp     bx, 2 * RNDNUMS
        jb      @@bx_ok
        xor     bx, bx
@@bx_ok:mov     [rndndex], bx
        mov     cl, al
        and     cl, 15
        rol     [rndbuf + bx], cl
        pop     dx
        pop     cx
        pop     bx
        ret
ENDP    rnd



;
; randomize
;
; Hva prosedyren gj›r:
;   Tar utgangspunkt i timer, og forandrer tallene i rndbuf ut fra dette.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    randomize
        push    ax
        push    bx
        push    cx
        push    es
        xor     ax, ax
        mov     es, ax
        mov     al, [es: 046Ch]
        and     al, 15
        xor     bx, bx
        mov     cx, RNDNUMS
@@next: push    cx
        mov     cl, al
        rol     [rndbuf + bx], cl
        inc     bx
        inc     bx
        pop     cx
        loop    @@next
        pop     es
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    randomize


        END
