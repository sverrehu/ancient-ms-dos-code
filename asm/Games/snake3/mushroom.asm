        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data


INCLUDE "SNAKE3.INC"



MAXMUSH EQU     15      ; Maks antall sopper p† skjermen


UDATASEG

        EXTRN   headx: BYTE, heady: BYTE
        EXTRN   mush1: PTR, mush2: PTR, mush3: PTR, mush4: PTR
        EXTRN   mush5: PTR, mush6: PTR, blank: PTR


mushs   DW      MAXMUSH DUP (?) ; Soppenes koordinater.
antmush DW      ?       ; Antall sopper
pid     DW      ?       ; Prosessid under oppdukking av sopp
mushno  DW      ?       ; Hvilken sopp skal vises under oppdukking?


DATASEG

mtypes  DW      mush1, mush2, mush3, mush4, mush5, mush6



CODESEG

        EXTRN   rnd: PROC
        EXTRN   newproc: PROC, rmproc: PROC
        EXTRN   setpos: PROC, getpos: PROC
        EXTRN   showobj8x6: PROC

        PUBLIC  clearmush, mkmush, rmmush, rndmkmush, rndrmmush, rmallmush


;
; clearmush
;
; Hva prosedyren gj›r:
;   Nullstiller det som har med sopper † gj›re.
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
PROC    clearmush
        mov     [pid], -1
        mov     [antmush], 0
        ret
ENDP    clearmush



;
; popup
;
; Hva prosedyren gj›r:
;   Kalles som en prosess og viser neste sopp i en sekvens for oppdukking.
;   Fjerner seg selv n†r hele serien er vist.
;
; Kall med:
;   Ingenting.
;   Verdier for [pid] og [mushno] m† v‘re satt riktig.
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    popup
        push    ax
        push    dx
        push    si

  ; Finn koordinater til den nyeste soppen
        mov     si, [antmush]
        dec     si
        shl     si, 1
        mov     dx, [mushs + si]

  ; Finn peker til riktig sopptegning
        mov     si, [mushno]
        shl     si, 1
        mov     si, [mtypes + si]
        call    showobj8x6
        mov     al, MUSH
        call    setpos

        inc     [mushno]
        cmp     [mushno], 6
        jb      @@ret

  ; Her er hele serien vist. Fjern popup fra prosesslisten slik at
  ; ny serie kan starte.
        mov     ax, [pid]
        call    rmproc
        mov     [pid], -1

@@ret:  pop     si
        pop     dx
        pop     ax
        ret
ENDP    popup



;
; mkmush
;
; Hva prosedyren gj›r:
;   Lager en sopp p† brettet i en viss avstand fra slangehodet.
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
PROC    mkmush
        push    ax
        push    bx
        push    dx
        push    si


  ; Sjekk f›rst om en sopp er iferd med † dukke opp. Da er det ikke
  ; mulig † generere en til.
        cmp     [pid], -1
        jne     @@ret

@@ok_to_popup:
        cmp     [antmush], MAXMUSH
        je      @@ret

@@try_again:
  ; Finn en tilfeldig posisjon p† skjermen
        mov     ax, MAXX - MINX + 1
        call    rnd
        add     ax, MINX
        mov     dl, al
        mov     ax, MAXY - MINY + 1
        call    rnd
        add     ax, MINY
        mov     dh, al

  ; Sjekk om det er noe her fra f›r
        call    getpos
        cmp     al, BLANK
        jne     @@try_again

  ; Sjekk om dette er i n‘rheten av slangehodet.
  ; M† v‘re minst 12 posisjoner fra i hver retning.
        mov     al, dl
        sub     al, [headx]
        jns     @@not_neg_1
        neg     al
@@not_neg_1:
        cmp     al, 12
        jb      @@try_again

        mov     al, dh
        sub     al, [heady]
        jns     @@not_neg_2
        neg     al
@@not_neg_2:
        cmp     al, 12
        jb      @@try_again

  ; OK, posisjon er funnet. Lagre denne i sopparrayen.
        mov     bx, [antmush]
        shl     bx, 1
        mov     [mushs + bx], dx

  ; Sett igang en serie med oppdukkinger.
        mov     [mushno], 0
        mov     dx, OFFSET popup
        mov     ax, 15
        call    newproc
        mov     [pid], ax

        inc     [antmush]

@@ret:  pop     si
        pop     dx
        pop     bx
        pop     ax
        ret
ENDP    mkmush



;
; rmmush
;
; Hva prosedyren gj›r:
;   Fjerner den soppen som har st†tt lengst p† skjermen.
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
PROC    rmmush
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    si
        push    es

  ; Sjekker at ingen sopp er iferd med † dukke opp eller ned i ›yeblikket.
        cmp     [pid], -1
        jne     @@ret

        cmp     [antmush], 0
        je      @@ret

  ; Finn posisjonen til den f›rste soppen i arrayen.
        mov     dx, [mushs]

  ; Flytt de andre et hakk nedover.
        mov     cx, [antmush]
        dec     cx
        mov     si, OFFSET mushs + 2
        mov     di, OFFSET mushs
        push    ds
        pop     es
        cld
        rep     movsw

  ; Sett en blank p† skjermen og i skjermtabellen
        mov     si, OFFSET blank
        call    showobj8x6
        mov     al, BLANK
        call    setpos

        dec     [antmush]

@@ret:  pop     es
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    rmmush



;
; popdown
;
; Hva prosedyren gj›r:
;   Kalles som en prosess og fjerner soppen som har st†tt lengst p† skjermen
;   i en sekvens for oppdukking.
;   Fjerner seg selv n†r hele serien er vist.
;
; Kall med:
;   Ingenting.
;   Verdier for [pid] og [mushno] m† v‘re satt riktig.
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    popdown
        push    ax
        push    dx
        push    si

  ; Finn koordinater til den nyeste soppen
        mov     dx, [mushs]

  ; Finn peker til riktig sopptegning
        mov     si, [mushno]
        shl     si, 1
        mov     si, [mtypes + si]
        call    showobj8x6
        mov     al, MUSH
        call    setpos

        dec     [mushno]
        cmp     [mushno], -1
        jne     @@ret

  ; Her er hele serien vist. Fjern popup fra prosesslisten slik at
  ; ny serie kan starte.
        mov     ax, [pid]
        call    rmproc
        mov     [pid], -1

  ; Fjern soppen helt
        call    rmmush

@@ret:  pop     si
        pop     dx
        pop     ax
        ret
ENDP    popdown



;
; slowrmmush
;
; Hva prosedyren gj›r:
;   Fjerner den soppen som har st†tt lengst p† skjermen ved † trykke den ned.
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
PROC    slowrmmush
        push    ax
        push    dx


  ; Sjekk f›rst om en sopp er iferd med † dukke opp eller ned. Da er det ikke
  ; mulig † fjerne en til.
        cmp     [pid], -1
        jne     @@ret

@@ok_to_popdown:
        cmp     [antmush], 0
        jz      @@ret

  ; Sett igang en serie med oppdukkinger.
        mov     [mushno], 5
        mov     dx, OFFSET popdown
        mov     ax, 15
        call    newproc
        mov     [pid], ax

@@ret:  pop     dx
        pop     ax
        ret
ENDP    slowrmmush



;
; rmallmush
;
; Hva prosedyren gj›r:
;   Fjerner alle soppene.
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
PROC    rmallmush
        push    ax
        mov     ax, [pid]
        cmp     ax, -1
        je      @@ingen_oppdukkende
        call    rmproc
        mov     [pid], -1

@@ingen_oppdukkende:
@@en_til:
        cmp     [antmush], 0
        jz      @@ret
        call    rmmush
        jmp     @@en_til

@@ret:  pop     ax
        ret
ENDP    rmallmush



;
; rndmkmush
;
; Hva prosedyren gj›r:
;   Kaller mkmush hvis tilfeldighetene vil det.
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
PROC    rndmkmush
        push    ax
        mov     ax, 5
        call    rnd
        or      ax, ax
        jnz     @@ret
        call    mkmush
@@ret:  pop     ax
        ret
ENDP    rndmkmush



;
; rndrmmush
;
; Hva prosedyren gj›r:
;   Kaller rmmush hvis tilfeldighetene vil det.
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
PROC    rndrmmush
        push    ax
        mov     ax, 15
        call    rnd
        or      ax, ax
        jnz     @@ret
        call    slowrmmush
@@ret:  pop     ax
        ret
ENDP    rndrmmush



ENDS

        END
