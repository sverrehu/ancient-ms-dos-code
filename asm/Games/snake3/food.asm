        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data


INCLUDE "SNAKE3.INC"



MAXFOOD EQU     4       ; Maks antall matvarer p† skjermen
FOODTYP EQU     4       ; Antall forskjellige matvarer


UDATASEG

        EXTRN   blank: PTR, strwbrry: PTR, pear: PTR, banana: PTR
        EXTRN   lemon: PTR
        EXTRN   skull: PTR


foods   DW      MAXFOOD DUP (?)         ; Matens koordinater.
antfood DW      ?                       ; Antall matvarer
pid     DW      ?       ; Prosessid under fjerning/omgj›ring av mat
misc    DW      ?       ; Brukt til diverse under fjerning/omgj›ring av mat



DATASEG

ftypes  DW      banana, pear, lemon, strwbrry   ; Matvaretypene



CODESEG

        EXTRN   rnd: PROC
        EXTRN   newproc: PROC, rmproc: PROC
        EXTRN   setpos: PROC, getpos: PROC
        EXTRN   showobj8x6: PROC
        EXTRN   mksound: PROC

        PUBLIC  clearfood, mkfood, rmfood, rndmkfood, rndrmfood, rmfoodpos
        PUBLIC  rmallfood


;
; clearfood
;
; Hva prosedyren gj›r:
;   Nullstiller det som har med matvarer † gj›re.
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
PROC    clearfood
        mov     [pid], -1
        mov     [antfood], 0
        ret
ENDP    clearfood



;
; mkfood
;
; Hva prosedyren gj›r:
;   Lager en matvare p† brettet.
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
PROC    mkfood
        push    ax
        push    bx
        push    dx
        push    si

        cmp     [antfood], MAXFOOD
        je      @@ret

@@try_again:
  ; Finn en tilfeldig posisjon p† skjermen, minst ‚n fra rammekanten.
        mov     ax, MAXX - MINX - 1
        call    rnd
        add     ax, MINX + 1
        mov     dl, al
        mov     ax, MAXY - MINY - 1
        call    rnd
        add     ax, MINY + 1
        mov     dh, al

  ; Sjekk om det er noe her fra f›r
        call    getpos
        cmp     al, BLANK
        jne     @@try_again

  ; OK, posisjon er funnet. Finn en tilfeldig matvare.
        mov     ax, FOODTYP
        call    rnd

        mov     si, ax
        shl     si, 1
        mov     si, [ftypes + si]

        mov     bx, [antfood]
        shl     bx, 1

        mov     [foods + bx], dx
        call    showobj8x6
        add     al, FOOD1
        call    setpos

        inc     [antfood]

@@ret:  pop     si
        pop     dx
        pop     bx
        pop     ax
        ret
ENDP    mkfood



;
; rmfood
;
; Hva prosedyren gj›r:
;   Fjerner den matvaren som har st†tt lengst p† skjermen.
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
PROC    rmfood
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    si
        push    es

  ; Sjekker at ingen matvare er iferd med † forsvinne eller
  ; r†tne i ›yeblikket.
        cmp     [pid], -1
        jne     @@ret

        cmp     [antfood], 0
        je      @@ret

  ; Finn posisjonen til den f›rste matvaren i arrayen.
        mov     dx, [foods]

  ; Flytt de andre et hakk nedover.
        mov     cx, [antfood]
        dec     cx
        mov     si, OFFSET foods + 2
        mov     di, OFFSET foods
        push    ds
        pop     es
        cld
        rep     movsw

  ; Sett en blank p† skjermen og i skjermtabellen
        mov     si, OFFSET blank
        call    showobj8x6
        mov     al, BLANK
        call    setpos

        dec     [antfood]

@@ret:  pop     es
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    rmfood



;
; rmallfood
;
; Hva prosedyren gj›r:
;   Fjerner all maten som ikke er spist opp
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
PROC    rmallfood
        push    ax

        mov     ax, [pid]
        cmp     ax, -1
        je      @@ingen_prosess
        call    rmproc
        mov     [pid], -1

@@ingen_prosess:
@@en_til:
        cmp     [antfood], 0
        jz      @@ret
        call    rmfood
        jmp     @@en_til

@@ret:  pop     ax
        ret
ENDP    rmallfood



;
; rmfoodpos
;
; Hva prosedyren gj›r:
;   Fjerner den maten som er i angitt posisjon.
;
; Kall med:
;   DL : X-posisjon
;   DH : Y-posisjon
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    rmfoodpos
        push    ax
        push    bx
        push    cx
        push    di
        push    si
        push    es

        mov     cx, [antfood]
        jcxz    @@ret
        mov     bx, OFFSET foods
@@ikke_funnet:
        cmp     [bx], dx
        je      @@funnet
        inc     bx
        inc     bx
        loop    @@ikke_funnet
        jmp     SHORT @@ret

@@funnet:
  ; Et problem: Hvis dette er den f›rste (eldste) maten, og den er iferd
  ; med † r†tne, m† forr†tnelsen stoppes, ellers vil denne overtas av den
  ; nest eldste maten. Sjekk om bx = OFFSET foods of pid != -1.
        cmp     bx, OFFSET foods
        jne     @@ikke_eldst
        cmp     [pid], -1
        je      @@rotner_ikke

  ; Stopp forr†tnelsen.
        mov     ax, [pid]
        call    rmproc
        mov     [pid], -1

@@rotner_ikke:
@@ikke_eldst:
        mov     si, OFFSET blank
        call    showobj8x6
        mov     al, BLANK
        call    setpos
        dec     cx
        mov     si, bx
        inc     si
        inc     si
        mov     di, bx
        push    ds
        pop     es
        cld
        rep     movsw
        dec     [antfood]

@@ret:  pop     es
        pop     si
        pop     di
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    rmfoodpos



;
; rndmkfood
;
; Hva prosedyren gj›r:
;   Kaller mkfood hvis tilfeldighetene vil det.
;   Det er denne som legges i prosesslisten.
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
PROC    rndmkfood
        push    ax
        mov     ax, 10
        call    rnd
        or      ax, ax
        jnz     @@ret
        call    mkfood
@@ret:  pop     ax
        ret
ENDP    rndmkfood



;
; rottenfood
;
; Hva prosedyren gj›r:
;   Kalles som en prosess og "r†tner" maten som har st†tt lengst p† skjermen
;   i en sekvens med blinking.
;   Fjerner seg selv n†r hele serien er vist.
;
; Kall med:
;   Ingenting.
;   Verdier for [pid] og [misc] m† v‘re satt riktig.
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    rottenfood
        push    ax
        push    bx
        push    cx
        push    dx
        push    si

  ; Finn koordinater til den eldste maten
        mov     dx, [foods]

  ; Sjekk om den n† skal blankes, vises eller r†tnes
        dec     [misc]
        jz      @@rotten
        test    [misc], 1
        jz      @@blank

  ; Finn peker til riktig mattegning
        call    getpos
        sub     al, FOOD1
        xor     ah, ah
        mov     si, ax
        shl     si, 1
        mov     si, [ftypes + si]

@@vis:
        call    showobj8x6
        jmp     SHORT @@ret

@@blank:
        mov     si, OFFSET blank
        jmp     @@vis

@@rotten:
  ; Her er hele serien vist. Fjern rottenfood fra prosesslisten slik at
  ; ny serie kan starte.
        mov     ax, [pid]
        call    rmproc
        mov     [pid], -1

  ; Fjern maten fra listen.
        call    rmfood

  ; Vis r†tten mat p† stedet.
        mov     si, OFFSET skull
        call    showobj8x6
        mov     al, ROTTEN
        call    setpos

  ; Lag en liten lyd
        mov     ax, 5
        mov     bx, 400
        mov     cx, 200
        mov     dx, -50
        call    mksound

@@ret:  pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    rottenfood



;
; rndrmfood
;
; Hva prosedyren gj›r:
;   Kaller rmfood hvis tilfeldighetene vil det. Det sjekkes at det er
;   mer enn en matvare p† skjermen, for det m† alltid v‘re minst en.
;   Det er denne som legges i prosesslisten.
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
PROC    rndrmfood
        push    ax
        push    dx

        cmp     [antfood], 1
        jbe     @@ret

  ; Sjekk om en matprosess g†r
        cmp     [pid], -1
        jne     @@ret

        mov     ax, 15
        call    rnd
        or      ax, ax
        jnz     @@ret

  ; Bestem om maten skal forsvinne eller r†tne.
        mov     ax, 4
        call    rnd
        or      ax, ax
        jnz     @@rotten

        call    rmfood
        jmp     SHORT @@ret

@@rotten:
  ; Sett igang en serie med blinkinger som ender med r†tten mat.
        mov     [misc], 31
        mov     dx, OFFSET rottenfood
        mov     ax, 30
        call    newproc
        mov     [pid], ax

@@ret:  pop     dx
        pop     ax
        ret
ENDP    rndrmfood



ENDS

        END
