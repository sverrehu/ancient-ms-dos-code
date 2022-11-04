        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING


INCLUDE "ED.INC"


;--------------------------;
;                          ;
;         D A T A          ;
;                          ;
;--------------------------;

UDATASEG

        EXTRN   doquit: BYTE
        EXTRN   pickhd: PTR
        EXTRN   mtattr: BYTE, mrattr: BYTE, uattr: BYTE
        EXTRN   filenm: PTR
        EXTRN   tmpfile: PTR
        EXTRN   antlin: WORD
        EXTRN   changed: BYTE
        EXTRN   fromlin: WORD, fromcol: WORD, curlin: WORD, curcol: WORD
        EXTRN   blockon: BYTE
        EXTRN   blklin1: WORD, blkcol1: WORD, blklin2: WORD, blkcol2: WORD
        EXTRN   poslin1: WORD, poscol1: WORD, poslin2: WORD, poscol2: WORD

        PUBLIC  savepck


  ;
  ; Her f�lger det som ligger i en pickfil. F�rst en header,
  ; s� selve dataene.
  ;
LABEL pickfilestart BYTE
        DB      40 DUP (?)      ; Plass til filehead
antpick DW      ?       ; Antall valgmuligheter i pickfilen
LABEL pickarr BYTE
        DB      (PICKRECSIZ * MAXPICK) DUP (?)
LABEL pickfileend BYTE


savepck DB      ?       ; Er pickfil p� disk, slik at den skal lagres?



DATASEG

  ; Header som legges f�rst i en pickfil. Gidder ikke � ha egen
  ; versjon for norsk.
pickfhd DB      NAVN, " pickfile.", 13, 10, 26, 0

  ; Navn p� pickfilen. Dette er fast, og kan ikke endres.
picknme DB      PICKFILENAME





CODESEG

;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

        EXTRN   strcpy: PROC, strlen: PROC
        EXTRN   outtext: PROC, outchar: PROC, gotoxy: PROC
        EXTRN   textattr: PROC, clreol: PROC
        EXTRN   getkey: PROC
        EXTRN   openwindow: PROC, closewindow: PROC, bordertext: PROC

        EXTRN   make_short_path: PROC
        EXTRN   loadfile: PROC, readfilelow: PROC, checksaved: PROC
        EXTRN   newfile: PROC, show_info: PROC
        EXTRN   showfilename: PROC, justpos: PROC, fetchline: PROC


        PUBLIC  initpick, endpick
        PUBLIC  loadpickfile, savepickfile
        PUBLIC  loadfrompick, updatepickitem, newpickitem
        PUBLIC  choosepick, checkifpick



;
; initpick
;
; Hva prosedyren gj�r:
;   Setter opp for bruk av pickfil
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
PROC    initpick
        mov     [savepck], 0
        call    clearpick
        ret
ENDP    initpick



;
; endpick
;
; Hva prosedyren gj�r:
;   Rydder opp.
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
PROC    endpick
        ret
ENDP    endpick



;
; clearpick
;
; Hva prosedyren gj�r:
;   Nullstiller pickarrayen, og kopierer headeren inn f�rst.
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
PROC    clearpick
        push    ax
        push    cx
        push    di
        push    si
        push    es

    ; Nullstill pickarrayet
        push    ds
        pop     es
        mov     di, OFFSET pickfilestart
        mov     cx, OFFSET pickfileend
        sub     cx, di
        xor     al, al
        cld
        rep     stosb

    ; Kopier filheaderen inn f�rst
        mov     di, OFFSET pickfilestart
        mov     si, OFFSET pickfhd
        call    strcpy

        pop     es
        pop     si
        pop     di
        pop     cx
        pop     ax
        ret
ENDP    clearpick



;
; loadpickfile
;
; Hva prosedyren gj�r:
;   Leser en pickfile inn i minnet hvis den finnes.
;   Det gis ikke meldinger hvis noe g�r galt, men arrayet nullstilles.
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
PROC    loadpickfile
        push    ax
        push    bx
        push    cx
        push    dx

    ; Gj�r fors�k p� � �pne filen.
        mov     ax, 3D00h       ; Open File, Read Access
        mov     dx, OFFSET picknme
        int     21h
        jnc     @@open_ok

  @@clear_pick:
    ; Kunne ikke �pnes. T�m pikkfilarrayen.
        call    clearpick
        jmp     SHORT @@ret

  @@open_ok:
        mov     bx, ax          ; Filehandle

    ; Les inn data.
        mov     ah, 3Fh         ; Read File or Device
        mov     dx, OFFSET pickfilestart
        mov     cx, OFFSET pickfileend
        sub     cx, dx
        int     21h

    ; Lukk i alle tilfeller filen. For at det etterp� skal kunne sjekkes
    ; om lesingen var suksessfull, m� flaggene og antall bytes lest spares.
        pushf
        push    ax

        mov     ah, 3Eh         ; Close File
        int     21h

        pop     ax
        popf

    ; Sjekk resultatet av lesingen. Hvis ikke denne var vellykket,
    ; skal pickarrayen nullstilles.
        jc      @@clear_pick    ; Feil under lesing?
        cmp     ax, cx
        jne     @@clear_pick    ; Ikke riktig antall bytes lest?

    ; Her er alt ok. Filen er lest fra disk. Siden det fantes en fil,
    ; skal denne oppdateres. Marker dette.
        mov     [savepck], 1

  @@ret:
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    loadpickfile



;
; savepickfile
;
; Hva prosedyren gj�r:
;   Lagrer pickfilen hvis savepck er true. Det gis ikke meldinger hvis
;   noe g�r galt.
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
PROC    savepickfile
        push    ax
        push    bx
        push    cx
        push    dx

    ; Sjekk om filen skal lagres
        cmp     [savepck], 0
        jz      @@ret

    ; Oppdater s� det gjeldende milj�et lagres
        call    updatepickitem

    ; Gj�r fors�k p� � �pne (lage) filen.
        mov     ah, 3Ch         ; Create File
        xor     cx, cx          ; Normal File
        mov     dx, OFFSET picknme
        int     21h
        jc      @@ret

    ; Det var mulig � lage filen.
        mov     bx, ax          ; Filehandle

    ; Skriv data.
        mov     ah, 40h         ; Write File or Device
        mov     dx, OFFSET pickfilestart
        mov     cx, OFFSET pickfileend
        sub     cx, dx
        int     21h

    ; Lukk filen.
        mov     ah, 3Eh         ; Close File
        int     21h

  @@ret:
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    savepickfile



;
; updatepickitem
;
; Hva prosedyren gj�r:
;   Oppdaterer n�v�rende f�rste element med det som ligger i
;   variablene for �yeblikket.
;   Det m� v�re noe i picklisten.
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
PROC    updatepickitem
        push    ax
        push    di
        push    si
        push    es

    ; Sjekk om et filnavn er angitt. Det skal ikke v�re mulig
    ; � regisrere et tomt navn
        cmp     [BYTE filenm], 0
        jz      @@ret

    ; Sjekk om det er noe � oppdatere.
        cmp     [antpick], 0
        jz      @@ret

    ; Kopier over n�v�rende filnavn
        mov     si, OFFSET filenm
        push    ds
        pop     es
        lea     di, [(pickrec PTR pickarr).filenm]
        call    strcpy

    ; Og alle posisjonsvariablene
        mov     ax, [fromlin]
        mov     [(pickrec PTR pickarr).fromlin], ax

        mov     ax, [fromcol]
        mov     [(pickrec PTR pickarr).fromcol], ax

        mov     ax, [curlin]
        mov     [(pickrec PTR pickarr).curlin], ax

        mov     ax, [curcol]
        mov     [(pickrec PTR pickarr).curcol], ax

        mov     ax, [blklin1]
        mov     [(pickrec PTR pickarr).blklin1], ax

        mov     ax, [blkcol1]
        mov     [(pickrec PTR pickarr).blkcol1], ax

        mov     ax, [blklin2]
        mov     [(pickrec PTR pickarr).blklin2], ax

        mov     ax, [blkcol2]
        mov     [(pickrec PTR pickarr).blkcol2], ax

        mov     ax, [poslin1]
        mov     [(pickrec PTR pickarr).poslin1], ax

        mov     ax, [poscol1]
        mov     [(pickrec PTR pickarr).poscol1], ax

        mov     ax, [poslin2]
        mov     [(pickrec PTR pickarr).poslin2], ax

        mov     ax, [poscol2]
        mov     [(pickrec PTR pickarr).poscol2], ax

        mov     al, [blockon]
        mov     [(pickrec PTR pickarr).blockon], al

  @@ret:
        pop     es
        pop     si
        pop     di
        pop     ax
        ret
ENDP    updatepickitem



;
; newpickitem
;
; Hva prosedyren gj�r:
;   Legger n�v�rende oppsett inn f�rst i pickarrayen etter � ha
;   forskj�vet de �vrige et hakk ned.
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
PROC    newpickitem
        push    cx
        push    di
        push    si
        push    es

    ; Sjekk om et filnavn er angitt. Det skal ikke v�re mulig
    ; � regisrere et tomt navn
        cmp     [BYTE filenm], 0
        jz      @@ret

    ; Flytt alt et hakk ned.
        push    ds
        pop     es
        mov     di, OFFSET pickfileend
        dec     di              ; ES:DI peker til siste tegn i siste linje
        mov     si, di
        sub     si, PICKRECSIZ  ; DS:SI til siste tegn i nest siste linje
        mov     cx, si
        inc     cx
        sub     cx, OFFSET pickarr
        std
        rep     movsb

    ; Hvis linjetallet fra f�r ikke var max, skal det �kes med 1.
        cmp     [antpick], MAXPICK
        jae     @@already_full

        inc     [antpick]

  @@already_full:
    ; Sett inn n�v�rende data f�rst.
        call    updatepickitem

  @@ret:
        pop     es
        pop     si
        pop     di
        pop     cx
        ret
ENDP    newpickitem



;
; loadfrompick
;
; Hva prosedyren gj�r:
;   Leser inn fil fra angitt linje i pickarrayen, og setter opp
;   alle variabler etter dette.
;   Hvis filen ikke er angitt, dvs strengen er tom, kalles loadfile
;   som ber bruker om filnavn og leser inn en ny fil.
;
; Kall med:
;   AX - �nsket linje i pickarrayen
;
; Returnerer:
;   Carry : clear - Ikke avbrutt av bruker. Enten er filen lest inn,
;                   ellers er editoren blanket (hvis filen ikke eksisterte
;                   eller liknende)
;           set   - avbrutt av bruker
;
; Endrer innholdet i:
;
PROC    loadfrompick
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    si
        push    es

    ; Sjekk om det er noe � velge i
        cmp     [antpick], 0
        jz      @@ask_filename

    ; Finn indeks inn i pickarrayen
        mov     bl, PICKRECSIZ
        mul     bl
        mov     bx, OFFSET pickarr
        add     bx, ax

    ; Sjekk om det her er angitt et filnavn
        cmp     [(pickrec PTR bx).filenm], 0
        jnz     @@filename_given

  @@ask_filename:
    ; Filnavn er ikke angitt. Les inn fil p� vanlig m�te ved �
    ; sp�rre bruker f�rst.
        call    loadfile
        cmp     ax, 27
        je      @@ret_aborted
        cmp     ax, QUITKEY
        je      @@ret_aborted
        jmp     @@ret_not_aborted

  @@ret_aborted:
    ; Marker at avbrutt av bruker
        stc
        jmp     @@ret

  @@filename_given:
    ; Det er et eller annet (forh�pentligvis et filnavn) p� angitt
    ; linje i pickarrayen. Fors�k � lese inn denne filen.

    ; F�r n�v�rende fil forkastes, m� bruker f� mulighet til � lagre.
        call    checksaved
        cmp     ax, 27  ; Er Esc trykket? Avbryt is�fall innlesningen.
        je      @@ret_aborted

    ; Nullstill variabler for editoren
        call    newfile
        call    show_info

    ; Kopier nytt filnavn over i [filenm]
        lea     si, [(pickrec PTR bx).filenm]
        push    ds
        pop     es
        mov     di, OFFSET filenm
        call    strcpy
        call    showfilename

    ; Les inn den nye filen
        call    readfilelow

    ; Oppdater annen data fra pickfilen.
        mov     al, [(pickrec PTR bx).blockon]
        mov     [blockon], al

    ; Det er en del data som skal testes mot siste linjenummer. Les
    ; dette inn i DX for enkelthets skyld.
        mov     dx, [antlin]    ; Antall linjer
        dec     dx              ; minus 1 = siste lovlige linje

        mov     ax, [(pickrec PTR bx).fromcol]
        mov     [fromcol], ax

        mov     ax, [(pickrec PTR bx).curcol]
        mov     [curcol], ax

        mov     ax, [(pickrec PTR bx).blkcol1]
        mov     [blkcol1], ax

        mov     ax, [(pickrec PTR bx).blkcol2]
        mov     [blkcol2], ax

        mov     ax, [(pickrec PTR bx).poscol1]
        mov     [poscol1], ax

        mov     ax, [(pickrec PTR bx).poscol2]
        mov     [poscol2], ax

        mov     ax, [(pickrec PTR bx).fromlin]
        cmp     ax, dx
        jbe     @@fromlin_ok
        mov     ax, dx
        mov     [fromcol], 0
  @@fromlin_ok:
        mov     [fromlin], ax

        mov     ax, [(pickrec PTR bx).curlin]
        cmp     ax, dx
        jbe     @@curlin_ok
        mov     ax, dx
        mov     [curcol], 0
  @@curlin_ok:
        mov     [curlin], ax

        mov     ax, [(pickrec PTR bx).blklin1]
        cmp     ax, dx
        jbe     @@blklin1_ok
        mov     ax, dx
        mov     [blkcol1], 0
  @@blklin1_ok:
        mov     [blklin1], ax

        mov     ax, [(pickrec PTR bx).blklin2]
        cmp     ax, dx
        jbe     @@blklin2_ok
        mov     ax, dx
        mov     [blkcol2], 0
  @@blklin2_ok:
        mov     [blklin2], ax

        mov     ax, [(pickrec PTR bx).poslin1]
        cmp     ax, dx
        jbe     @@poslin1_ok
        mov     ax, dx
        mov     [poscol1], 0
  @@poslin1_ok:
        mov     [poslin1], ax

        mov     ax, [(pickrec PTR bx).poslin2]
        cmp     ax, dx
        jbe     @@poslin2_ok
        mov     ax, dx
        mov     [poscol2], 0
  @@poslin2_ok:
        mov     [poslin2], ax

    ; Hopp til angitt posisjon
        call    justpos
        call    fetchline
        call    show_info

    ; Den valgte linjen skal n� fjernes fra pickarrayen, og
    ; s� legges inn f�rst.
        mov     di, bx
        mov     si, di
        add     si, PICKRECSIZ
        mov     cx, OFFSET pickfileend
        sub     cx, si
        cld
        rep     movsb

    ; Det er n� en linje mindre.
        dec     [antpick]

    ; Sett inn n�v�rende data �verst.
        call    newpickitem

  @@ret_not_aborted:
    ; Marker at ikke avbrutt av bruker
        clc

  @@ret:
        pop     es
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    loadfrompick



;
; show_one
;
; Hva prosedyren gj�r:
;   Lokal prosedyre som brukes av choosepick. Viser angitt pickelement
;   p� riktig linje i vinduet i angitt farge.
;
; Kall med:
;   AL : elementnummer. m� eksistere.
;   AH : attributt
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   tmpfile
;
PROC    show_one
        push    ax
        push    dx
        push    di
        push    si

    ; Sett angitt attributt
        push    ax
        mov     al, ah
        call    textattr
        pop     ax

    ; Flytt til riktig linje og skriv ut en blank
        push    ax
        mov     ah, al
        xor     al, al
        call    gotoxy
        mov     al, ' '
        call    outchar
        pop     ax

    ; Finn starten p� filnavnet
        xor     ah, ah
        mov     dl, PICKRECSIZ
        mul     dl
        lea     si, [(pickrec PTR pickarr).filenm]
        add     si, ax

    ; Lag kort versjon av navnet
        mov     ax, 50          ; Maks lengde
        mov     di, OFFSET tmpfile
        call    make_short_path

    ; Vis navnet
        mov     dx, di
        call    outtext
        call    clreol

  @@ret:
        pop     si
        pop     di
        pop     dx
        pop     ax
        ret
ENDP    show_one



;
; choosepick
;
; Hva prosedyren gj�r:
;   Setter opp en liste over tidligere filer p� skjermen, og lar brukeren
;   velge en av disse. Denne leses inn.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Carry : clear - ikke avbrutt av bruker
;           set   - avbrutt
;
; Endrer innholdet i:
;   tmpfile
;
PROC    choosepick
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    si
        push    es

    ; Sjekk om det er noe � velge fra.
        mov     cx, [antpick]
        or      cx, cx
        jnz     @@something
        jmp     @@ret

  @@something:
    ; M� f�rst finne ut hvor stort vindu som skal vises. Dette er bestemt
    ; av det lengste filnavnet n�r filene er forkortet med make_short_path
    ; s� de ikke er lenger enn 50 tegn.

        xor     bx, bx          ; Maks lengde. CX = antall
        lea     si, [(pickrec PTR pickarr).filenm]
        push    ds
        pop     es
        mov     di, OFFSET tmpfile
        mov     dx, di

  @@check_next_length:
        mov     ax, 50
        call    make_short_path
        call    strlen
        cmp     ax, bx
        jbe     @@inc_to_next_length
        mov     bx, ax
  @@inc_to_next_length:
        add     si, PICKRECSIZ
        loop    @@check_next_length

    ; Det lengste filnavnets lengde ligger n� i BX. Dette skal minst
    ; v�re 12. (bla for headeren i vinduet)
        cmp     bx, 12
        jae     @@open_window
        mov     bx, 12

  @@open_window:
    ; �pne vinduet.
        mov     ax, 5 + 5 * 256
        mov     dx, ax
        add     dx, 0103h       ; Vinduets kanter skal st� fra hverandre
        add     dl, bl          ; St�rste lengde
        add     dh, [BYTE antpick]
        mov     cl, [mtattr]
        mov     ch, [mrattr]
        mov     bl, 1           ; Enkel ramme
        call openwindow

        mov     dx, OFFSET pickhd
        xor     ah, ah          ; Sentrert p� toppen.
        call    bordertext

    ; Vis alle filnavnene
        mov     ah, [mtattr]
        xor     al, al          ; Start med f�rste
        mov     cx, [antpick]

  @@show_next:
        call    show_one
        inc     al
        loop    @@show_next

    ; N� er alle navnene vist, s� her begynner hovedl�kken.

  @@first_line:
        mov     ax, 1           ; (x,y) -posisjon for n�v�rende valg. Start p�
                                ; den andre, siden den f�rste er i editoren.
    ; Kan ikke hoppe over f�rste linje hvis det bare er en linje.
        cmp     [antpick], 1
        ja      @@main_loop
        xor     ax, ax

  @@main_loop:
    ; Vis n�v�rende valg uthevet.
        push    ax
        mov     ah, [uattr]
        call    show_one
        pop     ax

    ; Vent til tast er trykket
        push    ax
        call    getkey
        mov     bx, ax
        pop     ax

    ; Vis n�v�rende valg ikke uthevet.
        push    ax
        mov     ah, [mtattr]
        call    show_one
        pop     ax

    ; Sjekk om avbrutt av bruker
        cmp     bx, 27
        je      @@ret_aborted
        cmp     bx, QUITKEY
        jne     @@not_aborted
        mov     [doquit], 1
  @@ret_aborted:
    ; Lukk vinduet
        call    closewindow

    ; Marker at avbrutt
        clc
        jmp     SHORT @@ret

  @@not_aborted:
    ; Sjekk hva for en tast som ble trykket.
        cmp     bx, 13
        je      @@choice_done
        cmp     bx, -71         ; Home
        je      @@first_line
        cmp     bx, -73         ; PgUp
        je      @@first_line
        cmp     bx, -79         ; End
        je      @@last_line
        cmp     bx, -81         ; PgDn
        je      @@last_line
        cmp     bx, -72         ; Pil opp
        je      @@prev_line
        cmp     bx, -80         ; Pil ned
        je      @@next_line
        jmp     @@main_loop

  @@next_line:
    ; Flytt til neste linje hvis dette ikke er forbi siste
        inc     ax
        cmp     ax, [antpick]
        jb      @@jmp_main_loop
        dec     ax
        jmp     @@main_loop

  @@prev_line:
    ; Flytt til forrige linje hvis dette ikke er f�r f�rste
        or      ax, ax
        jz      @@jmp_main_loop
        dec     ax
  @@jmp_main_loop:
        jmp     @@main_loop

  @@last_line:
    ; Flytt til siste linje
        mov     ax, [antpick]
        dec     ax
        jmp     @@main_loop

  @@choice_done:
    ; Fjern f�rst vinduet.
        call    closewindow

    ; Her er et valg gjort. AX inneholder linjenummeret.

        call    updatepickitem
        call    loadfrompick

  @@ret_ok:
    ; Marker at ikke avbrutt
        clc

  @@ret:
        pop     es
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    choosepick



;
; checkifpick
;
; Hva prosedyren gj�r:
;   Sjekk om en fil finnes i picklisten. For at dette skal v�re
;   bombesikkert, m� alle filer best� av full path.
;
; Kall med:
;   DS:DX - Peker til filnavnet som skal testes.
;
; Returnerer:
;   AX : Posisjon i picklisten, eller -1 hvis filen ikke er der.
;
; Endrer innholdet i:
;   AX
;
PROC    checkifpick
        push    bx
        push    cx
        push    dx
        push    bp
        push    di
        push    si
        push    es

    ; M� sammenlikne strlen + 1, for � v�re sikker p� at begge
    ; strengene slutter p� samme sted. Husk lengden i BX
        call    strlen
        inc     ax
        mov     bx, ax

    ; Start p� 0 og f�rste filnavn
        xor     ax, ax
        lea     bp, [(pickrec PTR pickarr).filenm]

    ; G� gjennom alle filer i picklisten.
        push    ds
        pop     es
        mov     cx, [antpick]
        jcxz    @@not_found

  @@check_next:
        mov     di, dx
        mov     si, bp
        push    cx
        mov     cx, bx
        cld
        repe    cmpsb
        pop     cx
        je      @@ret           ; Funnet en som er lik.
        inc     ax
        add     bp, PICKRECSIZ  ; Klargj�r for neste.
        loop    @@check_next

  @@not_found:
    ; Her er ikke strengen funnet. Marker dette.
        mov     ax, -1

  @@ret:
        pop     es
        pop     si
        pop     di
        pop     bp
        pop     dx
        pop     cx
        pop     bx
        ret
ENDP    checkifpick





ENDS

        END
