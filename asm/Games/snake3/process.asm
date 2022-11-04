        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data

TSTFAST EQU     0;2000       ; Skal timer utelukkes ?

STRUC   process
 padr   DW      ?       ; Adressen til prosedyren som skal kalles
 pcnt   DW      ?       ; Nedtelling f›r neste kall
 pstrt  DW      ?       ; Startverdi for nedtelling
ENDS    process

PROCSIZ EQU     SIZE process
MAXPROC EQU     40      ; Maks antall prosesser g†ende


UDATASEG

        EXTRN   counter: WORD   ; Fra timer tick


        PUBLIC  stop


procs   DB      (MAXPROC * PROCSIZ) DUP (?)     ; Alle prosessene
antproc DW      ?       ; Antall prosesser
stop    DB      ?       ; Skal prosessene stoppes?



CODESEG


        PUBLIC  clearprocs, newproc, rmproc, procloop


;
; clearprocs
;
; Hva prosedyren gj›r:
;   T›mmer listen med prosesser ved † sette alles padr=0.
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
PROC    clearprocs
        push    bx
        push    cx
        mov     [antproc], 0
        mov     bx, OFFSET procs
        mov     cx, MAXPROC
@@next: mov     [(process PTR bx).padr], 0
        add     bx, PROCSIZ
        loop    @@next
        pop     cx
        pop     bx
        mov     [stop], 0
        ret
ENDP    clearprocs



;
; newproc
;
; Legger ny prosess inn i prosesslisten.
;
; Kall med:
;   DX : Peker til prosedyreadressen.
;   AX : Frekvens. Kalles for hvert AX'te runde. Minste er 1 !!
;
; Returnerer:
;   AX : <  0 : Feil, ikke plass til flere prosesser.
;        >= 0 : Prosess ID som brukes n†r prosessen skal fjernes.
;
; Endrer innholdet i:
;   AX
;
PROC    newproc
        push    bx
        push    cx
        push    di

        cmp     [antproc], MAXPROC
        je      @@ret_feil

  ; Finn ledig plass
        xor     di, di
        mov     bx, OFFSET procs
        mov     cx, MAXPROC
@@next: cmp     [(process PTR bx).padr], 0
        jz      @@legg_inn
        inc     di
        add     bx, PROCSIZ
        loop    @@next

  ; Her er det ikke plass til fler, returner med feilkode.
@@ret_feil:
        mov     ax, -1
        jmp     SHORT @@ret

  ; Legg inn den nye prosessen.
@@legg_inn:
        mov     [(process PTR bx).padr], dx
        mov     [(process PTR bx).pstrt], ax
        mov     [(process PTR bx).pcnt], ax
        inc     [antproc]
        mov     ax, di

@@ret:  pop     di
        pop     cx
        pop     bx
        ret
ENDP    newproc



;
; rmproc
;
; Hva prosedyren gj›r:
;   Fjerner prosess med angitt nummer.
;
; Kall med:
;   AX : Nummer p† prosessen som skal fjernes.
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    rmproc
        push    ax
        push    bx

        cmp     ax, 0
        jl      @@ret

        mov     bl, PROCSIZ
        mul     bl
        mov     bx, ax
        add     bx, OFFSET procs
        mov     [(process PTR bx).padr], 0
        dec     [antproc]

@@ret:  pop     bx
        pop     ax
        ret
ENDP    rmproc



;
; procloop
;
; Hva prosedyren gj›r:
;   Utf›rer alle prosesser inntil stop blir <> 0, eller det ikke
;   er flere prosesser igjen.
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
PROC    procloop
        push    ax
        push    bx
        push    cx
@@next: cmp     [stop], 0
        jnz     @@ret
        cmp     [antproc], 0
        jz      @@ret

        mov     [counter], 0

        mov     cx, MAXPROC
        mov     bx, OFFSET procs
@@next_proc:
        push    cx
        push    bx

        cmp     [(process PTR bx).padr], 0
        jz      @@loop_next

        dec     [(process PTR bx).pcnt]
        jnz     @@loop_next

        mov     ax, [(process PTR bx).pstrt]
        mov     [(process PTR bx).pcnt], ax
        call    [(process PTR bx).padr]

@@loop_next:
        pop     bx
        add     bx, PROCSIZ
        pop     cx
        loop    @@next_proc

IF TSTFAST EQ 0
@@wait_timer:
        cmp     [counter], 2
        jb      @@wait_timer
        jmp     @@next
ELSE
        mov     cx, TSTFAST
@@wait: nop
        nop
        nop
        nop
        nop
        loop    @@wait
        jmp     @@next
ENDIF

@@ret:  pop     cx
        pop     bx
        pop     ax
        ret
ENDP    procloop


ENDS

        END
