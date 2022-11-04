        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data


INCLUDE "SNAKE3.INC"



UDATASEG

        EXTRN   pill: PTR, blank: PTR

living  DB      ?       ; Er bounceren p† skjermen?
x       DB      ?
y       DB      ?
addx    DB      ?
addy    DB      ?
left    DW      ?       ; Antall flyttinger igjen f›r bounceren d›r
pid     DW      ?       ; Bouncerens prosessnummer



CODESEG

        EXTRN   showobj8x6: PROC
        EXTRN   setpos: PROC, getpos: PROC
        EXTRN   newproc: PROC, rmproc: PROC
        EXTRN   rnd: PROC

        PUBLIC  bouncer, clearbouncer, newbouncer
        PUBLIC  mkbouncer, rndmkbouncer, rmbouncer



;
; clearbouncer
;
; Hva prosedyren gj›r:
;   Klargj›r for bruk av bouncer.
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
PROC    clearbouncer
        mov     [pid], -1
        mov     [living], 0
        ret
ENDP    clearbouncer



;
; newbouncer
;
; Hva prosedyren gj›r:
;   Setter rndmkbouncer inn i prosessk›en, og tar vare p† prosessid'en.
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
PROC    newbouncer
        push    ax
        push    dx
        mov     dx, OFFSET rndmkbouncer
        mov     ax, 200
        call    newproc
        mov     [pid], ax
        pop     dx
        pop     ax
        ret
ENDP    newbouncer



;
; mkbouncer
;
; Hva prosedyren gj›r:
;   Setter opp variabler for bounceren, og setter bouncer inn i
;   prosesslisten.
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
PROC    mkbouncer
        push    ax
        push    dx
        push    si

@@try_again:
        mov     ax, MAXX - MINX + 1
        call    rnd
        add     ax, MINX
        mov     dl, al
        mov     ax, MAXY - MINY + 1
        call    rnd
        add     ax, MINY
        mov     dh, al

        call    getpos
        cmp     al, BLANK
        jne     @@try_again

        mov     [x], dl
        mov     [y], dh

@@is_zero_1:
        mov     ax, 3
        call    rnd
        sub     ax, 1
        jz      @@is_zero_1
        mov     [addx], al

@@is_zero_2:
        mov     ax, 3
        call    rnd
        sub     ax, 1
        jz      @@is_zero_2
        mov     [addy], al

  ; Bestem hvor mange steg bounceren skal g†
        mov     ax, 300
        call    rnd
        add     ax, 200
        mov     [left], ax

  ; Sett inn bouncer i prosesslisten med tilfeldig hastighet
        mov     dx, OFFSET bouncer
        mov     ax, 4
        call    rnd
        add     ax, 2
        mov     cl, 3
        shl     ax, cl
        call    newproc
        mov     [pid], ax
        mov     [living], 1

@@ret:  pop     si
        pop     dx
        pop     ax
        ret
ENDP    mkbouncer



;
; rmbouncer
;
; Hva prosedyren gj›r:
;   Fjerner bounceren fra skjermen og prosesslisten.
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
PROC    rmbouncer
        push    ax
        push    dx
        push    si

  ; Sjekk om en eller annen av bouncer-prosedyrene er aktive.
        mov     ax, [pid]
        cmp     ax, -1
        je      @@ret

  ; Ja, fjern denne.
        call    rmproc

  ; Sjekk om bounceren er p† skjermen
        cmp     [living], 0
        jz      @@ret

  ; Fjern bounceren.
        mov     dl, [x]
        mov     dh, [y]
        mov     si, OFFSET blank
        call    showobj8x6
        mov     al, BLANK
        call    setpos
        mov     [living], 0

@@ret:  pop     si
        pop     dx
        pop     ax
        ret
ENDP    rmbouncer



;
; rndmkbouncer
;
; Hva prosedyren gj›r:
;   Kaller mkbouncer hvis tilfeldighetene vil det.
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
PROC    rndmkbouncer
        push    ax

        mov     ax, 50
        call    rnd
        or      ax, ax
        jnz     @@ret

  ; Fjern rndmkbouncer fra prosesslisten
        mov     ax, [pid]
        call    rmproc

  ; Lag ny bouncer
        call    mkbouncer

@@ret:  pop     ax
        ret
ENDP    rndmkbouncer



;
; bouncer
;
; Hva prosedyren gj›r:
;   Flytter bounceren til neste posisjon. Hvis det ikke er fler
;   flyttinger igjen, fjernes bounceren, og rndmkbouncer settes
;   inn i prosesslisten.
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
PROC    bouncer
        push    ax
        push    bx
        push    dx
        push    si

        dec     [left]
        jnz     @@still_more

  ; Bounceren skal forsvinne.
        call    rmbouncer

  ; Sett rndmkbouncer inn i prosesslisten igjen.
        call    newbouncer
        jmp     @@ret

@@still_more:
        mov     dl, [x]
        mov     dh, [y]
        mov     bx, dx
        mov     si, OFFSET blank
        call    showobj8x6
        mov     al, BLANK
        call    setpos

        add     dl, [addx]
        add     dh, [addy]
        call    getpos
        cmp     al, BLANK
        je      @@show

  ; Fors›k om det hjelper † snu X'en
        mov     dx, bx
        sub     dl, [addx]
        add     dh, [addy]
        call    getpos
        cmp     al, BLANK
        jne     @@ikke_bare_x
  ; OK † snu X'en.
        neg     [addx]
        jmp     SHORT @@show

@@ikke_bare_x:
  ; Fors›k om det hjelper † snu Y'en
        mov     dx, bx
        sub     dh, [addy]
        add     dl, [addx]
        call    getpos
        cmp     al, BLANK
        jne     @@ikke_bare_y
  ; OK † snu Y'en.
        neg     [addy]
        jmp     SHORT @@show

@@ikke_bare_y:
  ; Sjekk med snudd X og Y.
        mov     dx, bx
        sub     dl, [addx]
        sub     dh, [addy]
        call    getpos
        cmp     al, BLANK
        jne     @@frys
        neg     [addx]
        neg     [addy]
        jmp     SHORT @@show
@@frys:
  ; Ikke mulig. Frys fast.
        mov     dx, bx

@@show: mov     si, OFFSET pill
        call    showobj8x6
        mov     al, BOUNCER
        call    setpos
        mov     [x], dl
        mov     [y], dh

@@ret:  pop     si
        pop     dx
        pop     bx
        pop     ax
        ret
ENDP    bouncer



ENDS

        END
