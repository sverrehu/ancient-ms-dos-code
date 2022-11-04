        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data


INCLUDE "SNAKE3.INC"


STRUC   leddpos
 direct DB      ?       ; Hvilken retning har dette punktet ?
 x      DB      ?       ; X-posisjon, relativt til hele skjermen
 y      DB      ?       ; Y-posisjon
ENDS    leddpos

LEDDSIZ EQU     SIZE leddpos
MAXLEDD EQU     ((MAXX - MINX + 1) * (MAXY - MINY + 1)) ; Maks antall ledd


;
; MACRO Incptr
;
; ùker angitt register slik at det peker pÜ neste
; lovlige posisjon i leddarrayen.
;
MACRO   Incptr  Reg
LOCAL @@inc_ok
        add     Reg, LEDDSIZ
        cmp     Reg, OFFSET snkledd + LEDDSIZ * MAXLEDD
        jb      @@inc_ok
        mov     Reg, OFFSET snkledd
@@inc_ok:
ENDM    Incptr


;
; MACRO Decptr
;
; Minker angitt register slik at det peker pÜ forrige
; lovlige posisjon i leddarrayen
;
MACRO   Decptr  Reg
LOCAL @@dec_ok
        sub     Reg, LEDDSIZ
        cmp     Reg, OFFSET snkledd
        jae     @@dec_ok
        mov     Reg, OFFSET snkledd + (MAXLEDD - 1) * LEDDSIZ
@@dec_ok:
ENDM    Decptr





UDATASEG

        PUBLIC  headx, heady, antledd, rmspid


snkledd DB      (MAXLEDD * LEDDSIZ) DUP (?)     ; Slangens ledd
antledd DW      ?       ; Antall ledd for õyeblikket
leddinn DW      ?       ; Peker i arrayen hvor neste ledd settes inn
leddut  DW      ?       ; Peker i arrayen hvor siste ledd hentes ut
headx   DB      ?       ; Slangehodets X-posisjon
heady   DB      ?       ; Slangehodets Y-posisjon
direct  DB      ?       ; Slangens bevegelsesretning
ldirect DB      ?       ; Forrige retning
rmspid  DW      ?       ; Midlertidig prosessnummer
fjernes DW      ?       ; Antall ledd som skal fjernes bakerst i slangen



DATASEG

        EXTRN   quit: BYTE, stop: BYTE
        EXTRN   level: WORD
        EXTRN   soundon: BYTE
        EXTRN   blank: PTR
        EXTRN   slange1: PTR, slange2: PTR, slange3: PTR, slange4: PTR
        EXTRN   slange5: PTR, slange6: PTR, slange7: PTR, slange8: PTR
        EXTRN   slange9: PTR, slangeA: PTR, slangeB: PTR
        EXTRN   slangeC: PTR, slangeD: PTR, slangeE: PTR


heads   DW      slange1, slange2, slange3, slange4
tails   DW      slange5, slange6, slange7, slange8

LABEL   snkbody WORD
fromd   DW      slangeA,       0, slangeE, slangeB
fromu   DW            0, slangeA, slangeD, slangeC
fromr   DW      slangeC, slangeB, slange9,       0
froml   DW      slangeD, slangeE,       0, slange9

bonmsg  DB      "     B O N U S", 0



CODESEG

        EXTRN   showobj8x6: PROC, shownum8x6: PROC
        EXTRN   setpos: PROC, getpos: PROC
        EXTRN   newproc: PROC, procloop: PROC, rmproc: PROC
        EXTRN   mkfood: PROC, rmfoodpos: PROC
        EXTRN   rmbouncer: PROC, newbouncer: PROC
        EXTRN   addscore: PROC, showlength: PROC, showsound: PROC
        EXTRN   mksound: PROC, sound: PROC, nosound: PROC, stopsound: PROC
        EXTRN   showmessage: PROC, clearmessage: PROC

        PUBLIC  clearsnake, newsnkpos, showsnake, movesnake, growsnake
        PUBLIC  rmlensnake



;
; showhead
;
; Hva prosedyren gjõr:
;   Viser leddet BX peker pÜ som et slangehode.
;
; Kall med:
;   BX : Peker til et ledd
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    showhead
        push    ax
        push    bx
        push    dx
        push    si
        mov     dl, [(leddpos PTR bx).x]
        mov     dh, [(leddpos PTR bx).y]
        mov     bl, [(leddpos PTR bx).direct]
        xor     bh, bh
        shl     bx, 1
        mov     si, [heads + bx]
        call    showobj8x6
        mov     al, SNAKE
        call    setpos
        pop     si
        pop     dx
        pop     bx
        pop     ax
        ret
ENDP    showhead



;
; showtail
;
; Hva prosedyren gjõr:
;   Viser leddet BX peker pÜ som en slangehale.
;
; Kall med:
;   BX : Peker til et ledd
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    showtail
        push    ax
        push    bx
        push    dx
        push    si
        mov     dl, [(leddpos PTR bx).x]
        mov     dh, [(leddpos PTR bx).y]
        mov     bl, [(leddpos PTR bx).direct]
        xor     bh, bh
        shl     bx, 1
        mov     si, [tails + bx]
        call    showobj8x6
        mov     al, SNAKE
        call    setpos
        pop     si
        pop     dx
        pop     bx
        pop     ax
        ret
ENDP    showtail



;
; showmiddle
;
; Hva prosedyren gjõr:
;   Viser del av slangekropp som ikke er hode eller hale.
;
; Kall med:
;   BX : Peker til et ledd
;   AL : Forrige ledds retning (leddet som er nërmere halen)
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    showmiddle
        push    ax
        push    bx
        push    cx
        push    dx
        push    si

        push    bx

        mov     bl, al
        xor     bh, bh
        mov     cl, 3
        shl     bx, cl
        mov     ax, bx

        pop     bx
        push    bx

        mov     bl, [(leddpos PTR bx).direct]
        xor     bh, bh
        shl     bx, 1

        add     bx, ax

        mov     si, [snkbody + bx]

        pop     bx

        mov     dl, [(leddpos PTR bx).x]
        mov     dh, [(leddpos PTR bx).y]
        call    showobj8x6
        mov     al, SNAKE
        call    setpos

        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    showmiddle



;
; showsnake
;
; Hva prosedyren gjõr:
;   Viser hele slangen pÜ skjermen ved Ü gÜ gjennom alle posisjonene.
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
PROC    showsnake
        push    bx
        push    dx

        mov     dx, [leddinn]
        Decptr  dx      ; DX peker pÜ forrige som ble lagt inn (hodet)

        mov     bx, [leddut]
@@next: mov     al, [(leddpos PTR bx).direct]
        Incptr  bx
        cmp     bx, dx
        je      @@head
        call    showmiddle
        jmp     @@next
@@head: call    showhead

  ; Vis halen til slutt, i tilfelle flere av de siste leddene er oppÜ
  ; hverandre.
        mov     bx, [leddut]
        call    showtail

        pop     dx
        pop     bx
        ret
ENDP    showsnake



;
; newsnkpos
;
; Hva prosedyren gjõr:
;   Setter inn ny slangeposisjon i ringbufferet.
;
; Kall med:
;   DL : X-koordinat
;   DH : Y-koordinat
;   AL : Retningskode
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    newsnkpos
        push    bx
        cmp     [antledd], MAXLEDD
        je      @@ret
        mov     bx, [leddinn]
        mov     [(leddpos PTR bx).direct], al
        mov     [(leddpos PTR bx).x], dl
        mov     [(leddpos PTR bx).y], dh
        Incptr  bx
        mov     [leddinn], bx
        inc     [antledd]
@@ret:  pop     bx
        ret
ENDP    newsnkpos



;
; growsnake
;
; Hva prosedyren gjõr:
;   Kopierer data i slangens siste ledd bakover, slik at slangen
;   blir lenger.
;
; Kall med:
;   AX : Antall nye ledd
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    growsnake
        push    ax
        push    bx
        push    cx
        push    dx

        mov     bx, [leddut]
        mov     cx, ax
        jcxz    @@ret

        mov     dl, [(leddpos PTR bx).x]
        mov     dh, [(leddpos PTR bx).y]
        mov     al, [(leddpos PTR bx).direct]

@@fler: cmp     [antledd], MAXLEDD
        je      @@ret
        Decptr  bx
        mov     [(leddpos PTR bx).x], dl
        mov     [(leddpos PTR bx).y], dh
        mov     [(leddpos PTR bx).direct], al
        inc     [antledd]
        loop    @@fler

        call    showlength

@@ret:  mov     [leddut], bx
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    growsnake



;
; clearsnake
;
; Hva prosedyren gjõr:
;   Nullstiller slangen, slik at den bestÜr av tre ledd (hode, kropp
;   og hale),  og gir disse posisjon midt pÜ skjermen.
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
PROC    clearsnake
        push    ax
        push    dx
        mov     [direct], NOMOVE
        mov     [ldirect], NOMOVE
        mov     [antledd], 0
        mov     ax, OFFSET snkledd
        mov     [leddinn], ax
        mov     [leddut], ax
        mov     dl, (MINX + MAXX) / 2 - 1
        mov     dh, (MINY + MAXY) / 2
        mov     al, RIGHT
        call    newsnkpos
        inc     dl
        call    newsnkpos
        inc     dl
        mov     [headx], dl
        mov     [heady], dh
        call    newsnkpos
        mov     [rmspid], -1
        mov     [fjernes], 0
        pop     dx
        pop     ax
        ret
ENDP    clearsnake



;
; rmlast
;
; Hva prosedyren gjõr:
;   Fjerner siste ledd i, og gir bonus for dette.
;   Prosedyren fjerner seg selv fra prosesslisten nÜr hele slangen er vekk.
;
; Kall med:
;   Ingenting. Denne skal ikke kalles direkte, men legges i prosesslisten.
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    rmlast
        push    ax
        push    bx
        push    dx
        push    si

        cmp     [fjernes], 0
        jz      @@stop_it
        cmp     [antledd], 0
        jz      @@stop_it

        mov     bx, [leddut]
        mov     dl, [(leddpos PTR bx).x]
        mov     dh, [(leddpos PTR bx).y]

  ; Sjekk om posisjonen er opptatt av en slangedel. Hvis rmlensnake kalles
  ; nÜr slangen har kollidert, vil nemlig siste ledd peke pÜ noe som ikke
  ; er slange, og det skal ikke fjernes.
        call    getpos
        cmp     al, SNAKE
        jne     @@dont_remove

        mov     si, OFFSET blank
        call    showobj8x6
        mov     al, BLANK
        call    setpos

@@dont_remove:
  ; Gi bonus for leddet
        mov     ax, 10
        call    addscore

        Incptr  bx
        mov     [leddut], bx
        dec     [antledd]
        jz      @@stop_it
        dec     [fjernes]
        jz      @@show_tail_stop

        jmp     SHORT @@flere_ledd

@@show_tail_stop:
  ; Slangen har flere ledd, men resten skal ikke fjernes. Vis halen.
        call    showtail

@@stop_it:
  ; Her er õnsket antall ledd vekk. Fjern rmlast fra prosesslisten.
        mov     ax, [rmspid]
        call    rmproc
        mov     [rmspid], -1

  ; Fjern blinkemelding med bonus
        call    clearmessage

        call    nosound
        jmp     SHORT @@ret

@@flere_ledd:
  ; Gi pipetone hvis antall ledd er delelig med 8
        test    [antledd], 7
        jnz     @@nosnd
        mov     ax, 1400
        call    sound
        jmp     SHORT @@show_tail

@@nosnd:
        call    nosound

@@show_tail:
  ; Sett det nye sisteleddet til en slangehale hvis det er opptatt av
  ; en slangedel.
        mov     dl, [(leddpos PTR bx).x]
        mov     dh, [(leddpos PTR bx).y]
        call    getpos
        cmp     al, SNAKE
        jne     @@ret

        call    showtail

@@ret:  call    showlength
        pop     si
        pop     dx
        pop     bx
        pop     ax
        ret
ENDP    rmlast



;
; rmlensnake
;
; Hva prosedyren gjõr:
;   Fjerner, hvis mulig, angitt antall ledd bakerst pÜ slagen og gir
;   bonus for hvert ledd.
;
; Kall med:
;   AX : Antall ledd som õnskes fjernet
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    rmlensnake
        push    ax
        push    dx

  ; Sjekk om en fjerning allerede er igang.
        cmp     [rmspid], -1
        je      @@sett_inn_ny

  ; En tilsvarende prosess kjõrer. ùk antallet ledd som skal fjernes
  ; med det som ble angitt
        add     [fjernes], ax
        jmp     SHORT @@ret

@@sett_inn_ny:
  ; Sett fjerningsprosessen inn i prosesslisten
        mov     [fjernes], ax
        mov     dx, OFFSET rmlast
        mov     ax, 1
        call    newproc
        mov     [rmspid], ax

  ; Vis blinkemelding med bonus
        mov     si, OFFSET bonmsg
        call    showmessage

@@ret:  pop     dx
        pop     ax
        ret
ENDP    rmlensnake



;
; movesnake
;
; Hva prosedyren gjõr:
;   Leser tastaturet (hvis en tast venter) og flytter slangen slik
;   som er riktig.
;   Det er denne rutinen som legges inn som en prosess.
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
PROC    movesnake
        push    ax
        push    bx
        push    cx
        push    dx
        push    si

  ; Legg forrige retning i ldirec, slik at utseendet pÜ leddet
  ; kan bestemmes.
        mov     al, [direct]
        mov     [ldirect], al

  ; Sjekk om tast er trykket.
@@read_key:
        mov     ah, 1
        int     16h
        jnz     @@keypressed
        jmp     @@nokey

@@keypressed:
  ; Tast er trykket. Les koden og tolk.
        xor     ah, ah
        int     16h
        or      al, al  ; Er utvidet tast trykket?
        jnz     @@normal_tast
        mov     al, ah
        xor     ah, ah
        neg     ax
        jmp     SHORT @@ikke_liten
@@normal_tast:
        xor     ah, ah

  ; Gjõr evt. om fra smÜ til store bokstaver
        cmp     ax, 'a'
        jl      @@ikke_liten
        cmp     ax, 'z'
        jg      @@ikke_liten
        sub     ax, 'a' - 'A'

@@ikke_liten:
  ; Sjekk om ESC for programavslutning
        cmp     ax, 27
        jne     @@ikke_ESC
        mov     [quit], ESCAPE
        mov     [stop], ESCAPE
        jmp     @@ret

@@ikke_ESC:
  ; Sjekk hvilken tast dette kan vëre.
        cmp     ax, 'A'
        je      @@move_up
        cmp     ax, 'Z'
        je      @@move_down
        cmp     ax, 'N'
        je      @@move_left
        cmp     ax, 'M'
        je      @@move_right
        cmp     ax, -72
        je      @@move_up
        cmp     ax, -80
        je      @@move_down
        cmp     ax, -75
        je      @@move_left
        cmp     ax, -77
        je      @@move_right
        cmp     ax, 'S'         ; Sound on/off
        je      @@chg_sound
        cmp     ax, ' '         ; Pause
        je      @@pause

  ; Ukjent tast trykket. Sjekk om flere venter.
        jmp     SHORT @@read_key

@@move_up:
        cmp     [ldirect], DOWN
        je      @@dont_turn
        mov     [direct], UP
        jmp     SHORT @@do_move
@@move_down:
        cmp     [ldirect], UP
        je      @@dont_turn
        mov     [direct], DOWN
        jmp     SHORT @@do_move
@@move_left:
        cmp     [ldirect], RIGHT
        je      @@dont_turn
        cmp     [ldirect], NOMOVE       ; I starten kan det ikke flyttes
        je      @@dont_turn             ; mot venstre.
        mov     [direct], LEFT
        jmp     SHORT @@do_move
@@move_right:
        cmp     [ldirect], LEFT
        je      @@dont_turn
        mov     [direct], RIGHT
        jmp     SHORT @@do_move
@@chg_sound:
        xor     [soundon], 1
        call    showsound
        jnz     @@do_move
        call    stopsound
        jmp     @@read_key

@@pause:
  ; Vent til space er trykket
@@wait_key:
        xor     ah, ah
        int     16h
        cmp     al, ' '
        jne     @@wait_key

        jmp     @@read_key

  ; Det er gjort forsõk pÜ Ü brÜsnu. Det er ikke mulig.
  ; Gi pipetone, og fortsett i samme retning.
@@dont_turn:
        mov     ax, 1
        mov     bx, 300
        mov     cx, 100
        mov     dx, -30
        call    mksound

@@nokey:
@@do_move:
  ; Utfõr flytting av slangen
        mov     al, [direct]
        cmp     al, NOMOVE
        jne     @@remove_tail
        jmp     @@ret

@@remove_tail:
  ; Fjern halen
        mov     bx, [leddut]
        mov     dl, [(leddpos PTR bx).x]
        mov     dh, [(leddpos PTR bx).y]
        mov     si, OFFSET blank
        call    showobj8x6
        mov     al, BLANK
        call    setpos
        Incptr  bx
        mov     [leddut], bx
        dec     [antledd]

  ; Sett ny hale, BX peker til nytt haleledd.
        call    showtail

  ; Overskriv nÜvërende hode med riktig ledd.
        mov     bx, [leddinn]
        Decptr  bx      ; Peker til nÜvërende hode
        mov     dl, [(leddpos PTR bx).x]
        mov     dh, [(leddpos PTR bx).y]
        mov     al, [(leddpos PTR bx).direct]
        mov     ah, [direct]
        mov     [(leddpos PTR bx).direct], ah
        call    showmiddle

  ; Finn posisjonen til nytt hode.
        cmp     ah, UP
        je      @@new_up
        cmp     ah, DOWN
        je      @@new_down
        cmp     ah, LEFT
        je      @@new_left

@@new_right:
        inc     dl
        jmp     SHORT @@new_head
@@new_up:
        dec     dh
        jmp     SHORT @@new_head
@@new_down:
        inc     dh
        jmp     SHORT @@new_head
@@new_left:
        dec     dl

  ; Legg inn nytt hode.
@@new_head:
        mov     [headx], dl
        mov     [heady], dh
        mov     al, ah
        call    newsnkpos

@@chk_pos:
  ; Finn ut hva som evt befinner seg pÜ skjermen i nÜvërende pos.
        call    getpos

  ; Sjekk om slangen har kollidert med noe
        cmp     al, BLANK
        jne     @@test_what
        jmp     @@show_head
@@test_what:
        cmp     al, SNAKE
        je      @@die
        cmp     al, BORDER
        je      @@die
        cmp     al, MUSH
        je      @@die
        cmp     al, ROTTEN
        je      @@die
        cmp     al, BANGER
        je      @@die
        cmp     al, BOUNCER
        je      @@bnc
        cmp     al, FOOD1
        je      @@food
        cmp     al, FOOD2
        je      @@food
        cmp     al, FOOD3
        je      @@food
        cmp     al, FOOD4
        je      @@food

        jmp     SHORT @@show_head

  ; Noe "dõdelig" er truffet. Gi bonus, og avslutt runden.
@@die:
        mov     [stop], DEAD
        mov     [quit], DEAD

  ; Hvis slangen gikk iveggen, skal ikke hodet vises
        cmp     al, BORDER
        je      @@ret
        jmp     SHORT @@show_head

  ; Ballen er truffet. ùk poengsummen og kutt ut bouncer.
  ; Slangen skal miste 1/5 av halen.
@@bnc:
        call    rmbouncer
        call    newbouncer
        mov     ax, [antledd]
        cmp     ax, 3
        jbe     @@ikke_mink
        mov     bl, 5
        div     bl
        xor     ah, ah
        call    rmlensnake
@@ikke_mink:
        mov     ax, 1
        mov     bx, 800
        mov     cx, 1200
        mov     dx, 20
        call    mksound
        jmp     SHORT @@show_head

  ; Noe spiselig er truffet. ùk slangelengde og poengsum, fjern maten
  ; som ble spist, og plasser en ny matbit.
  ; Gi lyd.
@@food:
        call    rmfoodpos
        sub     al, FOOD1
        inc     al
        xor     ah, ah

  ; ùk lengden med 3 * matnummeret
        push    ax
        mov     dx, ax
        shl     ax, 1
        add     ax, dx
        call    growsnake
        pop     ax

  ; Lag ny matbit. Det mÜ alltid vëre minst Çn.
        call    mkfood

  ; ùk score med 5 * matnummeret
        mov     bl, 5
        mul     bl
        mov     bl, [BYTE level]
        mul     bl
        call    addscore

  ; Sett igang en lydeffekt.
        mov     ax, 1   ; Hastighet
        mov     bx, 800
        mov     cx, 1000
        mov     dx, 20
        call    mksound

@@show_head:
        mov     bx, [leddinn]
        Decptr  bx
        call    showhead

@@ret:  pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    movesnake



ENDS


        END
