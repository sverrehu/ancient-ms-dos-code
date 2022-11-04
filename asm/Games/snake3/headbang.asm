        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data


INCLUDE "SNAKE3.INC"


DATASEG

headmsg DB      "DANGER: HEADBANGER!", 0
bangs   DW      hbang2, hbang3, hbang4, hbang3, hbang2, hbang1

ANTBNG  EQU     6



UDATASEG

        EXTRN   hbang1: PTR, hbang2: PTR, hbang3: PTR, hbang4: PTR
        EXTRN   headx: BYTE, heady: BYTE
        EXTRN   blank: PTR
        EXTRN   level: WORD, stop: BYTE, quit: BYTE


living  DB      ?       ; Er headbangeren p† skjermen?
pos     DW      ?
left    DW      ?       ; Antall flyttinger igjen f›r headbangeren d›r
pid     DW      ?       ; Flyttingens prosessnummer
apid    DW      ?       ; Animeringens prosessnummer
bangnr  DW      ?       ; Hvilken figur vises?



CODESEG

        EXTRN   showobj8x6: PROC
        EXTRN   setpos: PROC, getpos: PROC
        EXTRN   newproc: PROC, rmproc: PROC
        EXTRN   rnd: PROC
        EXTRN   showmessage: PROC, clearmessage: PROC
        EXTRN   mksound: PROC

        PUBLIC  banger, clearbanger, newbanger
        PUBLIC  mkbanger, rndmkbanger, rmbanger



;
; clearbanger
;
; Hva prosedyren gj›r:
;   Klargj›r for bruk av headbanger.
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
PROC    clearbanger
        mov     [pid], -1
        mov     [apid], -1
        mov     [living], 0
        ret
ENDP    clearbanger



;
; newbanger
;
; Hva prosedyren gj›r:
;   Setter rndmkbanger inn i prosesslisten.
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
PROC    newbanger
        push    ax
        push    dx

        mov     dx, OFFSET rndmkbanger
        mov     ax, 300
        call    newproc
        mov     [pid], ax

        pop     dx
        pop     ax
        ret
ENDP    newbanger



;
; mkbanger
;
; Hva prosedyren gj›r:
;   Setter opp variabler for headbangeren, og setter banger inn i
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
PROC    mkbanger
        push    ax
        push    cx
        push    dx
        push    si

        mov     cx, 50  ; Maks 50 fors›k

@@try_again:
        dec     cx
        jcxz    @@ret

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
        mov     al, dl
        sub     al, [headx]
        jns     @@not_neg_1
        neg     al
@@not_neg_1:
        cmp     al, (MAXX - MINX) / 2 - 15
        jb      @@try_again

        mov     al, dh
        sub     al, [heady]
        jns     @@not_neg_2
        neg     al
@@not_neg_2:
        cmp     al, (MAXY - MINY) / 2 - 15
        jb      @@try_again

        mov     [pos], dx

  ; Bestem hvor mange steg bangeren skal g†
        mov     ax, 3 * (MAXX - MINX + 1)
        call    rnd
        add     ax, (MAXX - MINX + 1)
        mov     [left], ax

  ; Sett inn banger i prosesslisten med hastighet lik ca 0.65*spillerens --
        mov     dx, OFFSET banger
        mov     cx, 11
        sub     cx, [level]
        mov     ax, cx
        shr     cx, 1
        add     ax, cx
        add     ax, 2
        call    newproc
        mov     [pid], ax
        mov     [living], 1

  ; Sett animbanger inn i prosesslisten
        mov     [bangnr], 0
        mov     dx, OFFSET animbanger
        mov     ax, 12
        call    newproc
        mov     [apid], ax

  ; Vis melding om headbangeren
        mov     si, OFFSET headmsg
        call    showmessage

@@ret:  pop     si
        pop     dx
        pop     cx
        pop     ax
        ret
ENDP    mkbanger



;
; rmbanger
;
; Hva prosedyren gj›r:
;   Fjerner headbangeren fra skjermen og prosesslisten.
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
PROC    rmbanger
        push    ax
        push    dx
        push    si

  ; Sjekk om en eller annen av banger-prosedyrene er aktive.
        mov     ax, [pid]
        cmp     ax, -1
        je      @@ret

  ; Ja, fjern denne.
        call    rmproc

  ; Sjekk om animeringsprosessen er aktiv
        mov     ax, [apid]
        cmp     ax, -1
        je      @@ikke_anim

  ; Fjern denne
        call    rmproc

@@ikke_anim:
  ; Sjekk om bangeren er p† skjermen
        cmp     [living], 0
        jz      @@ret

  ; Fjern bangeren.
        mov     dx, [pos]
        mov     si, OFFSET blank
        call    showobj8x6
        mov     al, BLANK
        call    setpos
        mov     [living], 0

  ; Fjern bangermeldingen
        call    clearmessage

@@ret:  pop     si
        pop     dx
        pop     ax
        ret
ENDP    rmbanger



;
; rndmkbanger
;
; Hva prosedyren gj›r:
;   Kaller mkbanger hvis tilfeldighetene vil det.
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
PROC    rndmkbanger
        push    ax

        mov     ax, 80
        call    rnd
        or      ax, ax
        jnz     @@ret

  ; Fjern rndmkbanger fra prosesslisten
        mov     ax, [pid]
        call    rmproc
        mov     [pid], -1

  ; Lag ny headbanger
        call    mkbanger

@@ret:  pop     ax
        ret
ENDP    rndmkbanger



;
; banger
;
; Hva prosedyren gj›r:
;   Flytter headbangeren til neste posisjon. Hvis det ikke er fler
;   flyttinger igjen, fjernes bangeren, og rndmkbanger settes
;   inn i prosesslisten.
;   Flyttingen er helt uintelligent, men det blir sikkert guffent
;   nok allikevel!
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
PROC    banger
        push    ax
        push    bx
        push    dx
        push    si

        dec     [left]
        jnz     @@still_more

  ; Bounceren skal forsvinne.
        call    rmbanger

  ; Sett rndmkbanger inn i prosesslisten igjen.
        call    newbanger
        jmp     @@ret

@@still_more:
        mov     dx, [pos]

  ; Sjekk hvor neste posisjon blir.
        cmp     dl, [headx]
        je      @@move_y
        jb      @@move_right
@@move_left:
        dec     dl
        jmp     SHORT @@move_y
@@move_right:
        inc     dl

@@move_y:
        cmp     dh, [heady]
        je      @@chk_pos
        jb      @@move_down
@@move_up:
        dec     dh
        jmp     SHORT @@chk_pos
@@move_down:
        inc     dh
        jmp     SHORT @@chk_pos

@@traff_hodet:
  ; Slangen er tatt. Utf›r avslutning av runde som i mvsnake.
        mov     [stop], DEAD
        mov     [quit], DEAD
        jmp     @@ret

@@chk_pos:
  ; Sjekk om hodet n† er truffet
        mov     al, [headx]
        mov     ah, [heady]
        cmp     dx, ax
        je      @@traff_hodet

  ; Sjekk om det finnes noe p† den nye posisjonen
        call    getpos
        cmp     al, BLANK
        je      @@flytt_ok

  ; Fors›k † flytte bare i X-retningen.
@@bare_x:
        mov     dx, [pos]
        cmp     dl, [headx]
        je      @@bare_y
        jb      @@move_right_2
@@move_left_2:
        dec     dl
@@test_x_2:
        mov     al, [headx]
        mov     ah, [heady]
        cmp     dx, ax
        je      @@traff_hodet

        call    getpos
        cmp     al, BLANK
        je      @@flytt_ok
        jmp     SHORT @@bare_y
@@move_right_2:
        inc     dl
        jmp     @@test_x_2

  ; Fors›k † flytte bare i Y-retningen.
@@bare_y:
        mov     dx, [pos]
        cmp     dh, [heady]
        je      @@ret
        jb      @@move_down_2
@@move_up_2:
        dec     dh
@@test_y_2:
        mov     al, [headx]
        mov     ah, [heady]
        cmp     dx, ax
        je      @@traff_hodet

        call    getpos
        cmp     al, BLANK
        je      @@flytt_ok
        jmp     SHORT @@ret
@@move_down_2:
        inc     dh
        jmp     @@test_y_2

@@flytt_ok:
  ; Fjern f›rst gammel posisjon
        push    dx
        mov     dx, [pos]
        mov     si, OFFSET blank
        call    showobj8x6
        mov     al, BLANK
        call    setpos
        pop     dx

  ; Lagre ny posisjon
        mov     [pos], dx

@@show: mov     si, [bangnr]
        shl     si, 1
        mov     si, [bangs + si]
        call    showobj8x6
        mov     al, BANGER
        call    setpos

@@ret:  pop     si
        pop     dx
        pop     bx
        pop     ax
        ret
ENDP    banger



;
; animbanger
;
; Hva prosedyren gj›r:
;   Viser bangeren i riktig posisjon.
;
; Kall med:
;   Ingenting. Skal ikke kalles.
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    animbanger
        push    ax
        push    bx
        push    cx
        push    dx
        push    si

        mov     dx, [pos]
        mov     si, [bangnr]
        shl     si, 1
        mov     si, [bangs + si]
        call    showobj8x6

        inc     [bangnr]
        cmp     [bangnr], ANTBNG
        jb      @@ret
        mov     [bangnr], 0

  ; Lag banglyd.
        mov     ax, 1
        mov     bx, 200
        mov     cx, 50
        mov     dx, -30
        call    mksound

@@ret:  pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    animbanger




ENDS

        END
