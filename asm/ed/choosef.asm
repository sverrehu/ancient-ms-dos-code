        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @code, es: NOTHING


INCLUDE "ED.INC"


;--------------------------;
;                          ;
;         D A T A          ;
;                          ;
;--------------------------;

UDATASEG

        EXTRN   doquit: BYTE
        EXTRN   mtattr: BYTE, mrattr: BYTE, uattr: BYTE
        EXTRN   toomany: PTR


numfile DW      ?               ; Antall filer Ü velge i.
full    DB      ?               ; For mange filer?
from    DW      ?               ; Fõrste element i vinduet
curr    DW      ?               ; NÜvërende elementnummer

  ; Plass til filer som kan velges
files   DB      (MAXCHOOSE * 14) DUP (?)
dispbuf DB      15 DUP (?)      ; For visning av filnavnet



DATASEG

allmask DB      "*.*", 0        ; For Ü finne alle directories.





;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        EXTRN   strlen: PROC, strcpy: PROC, strcat: PROC
        EXTRN   openwindow: PROC, closewindow: PROC
        EXTRN   drawborder: PROC, bordertext: PROC
        EXTRN   outtext: PROC, outchar: PROC, textattr: PROC, gotoxy: PROC
        EXTRN   mkfullpath: PROC
        EXTRN   getkey: PROC

        EXTRN   make_short_path: PROC

        PUBLIC  choosefile



;
; choosefile
;
; Hva prosedyren gjõr:
;   Gir mulighet for valg av fil som passer til angitt path
;   med wildcards. Det SKAL vëre angitt wildcards nÜr denne
;   kalles, og drive og full path SKAL vëre angitt.
;   Dvs. at amn mÜ kjõre rmfullpath, og sÜ evt. legge til
;   *.* hvis pathen ender i en backslash.
;
; Kall med:
;   DX - Peker til strengen
;
; Returnerer:
;   DX    : Modifisert streng, hvor wildcards er byttet ut
;           med valgt filnavn.
;   Carry : clear - OK. Ikke avbrutt av bruker.
;           set   - Avbrutt av bruker.
;
; Endrer innholdet i:
;   Ingenting
;
PROC    choosefile

        push    ax

    ; Sett opp en lokal variabel som inneholder directoryet
    ; filene skal leses fra. cat er sammenslÜingen av dir og mask
    ; evt i forkortet form.
        LOCAL   dir: BYTE: MAXFILE, mask: BYTE: 13, cat: BYTE: MAXFILE = LSIZE

        push    bp
        mov     bp, sp
        sub     sp, LSIZE

        push    bx
        push    cx
        push    dx
        push    di
        push    si
        push    es

    ; Sett ES = DS
        push    ds
        pop     es

    ; Kopier angitt path over i den interne
        lea     di, [dir]
        mov     si, dx
        call    strcpy

    ; Kopier den delen som ikke er directory over i mask. MÜ fõrst lete
    ; bakover etter siste backslash.
        mov     si, di
        call    strlen
        add     si, ax
        std
  @@not_backslash:
        lodsb
        cmp     al, '\'
        jne     @@not_backslash

        add     si, 2
        lea     di, [mask]
        call    strcpy

    ; Fjern den delen som ikke er directory ved Ü sette inn en
    ; 0-byte etter den siste backslashen
        mov     [BYTE si], 0

    ; èpne et vindu med riktig stõrellse.
        push    dx
        ANTX    EQU     (14 * CHOOSEX + 1)
        mov     al, 38 - ANTX / 2
        mov     ah, 11 - CHOOSEY / 2
        mov     dx, ax
        add     dl, ANTX + 1
        add     dh, CHOOSEY + 1
        mov     bl, 1           ; Enkel ramme
        mov     cl, [mtattr]
        mov     ch, [mrattr]
        call    openwindow
        pop     dx

    ; Hit hoppes det etter at directoryet er endret. Tegner rammen pÜ
    ; nytt, setter path õverst og evt "too many files" nederst, resetter
    ; posisjonen, og viser teksten.

  @@new_directory:
        push    dx

    ; Tegn vindusrammen for Ü fjerne rester etter evt tidligere omganger.
        call    drawborder

    ; SlÜ sammen directory og maske for Ü kunne vise dette
    ; õverst i vinduet. Legg en blank pÜ hver side.
        lea     si, [dir]
        lea     di, [cat]
        mov     [WORD di], ' ' + 256 * 0
        call    strcat
        lea     si, [mask]
        call    strcat
        mov     dx, di
        call    strlen
        push    di
        add     di, ax
        mov     [WORD di], ' ' + 256 * 0
        pop     di

    ; Forkort hvis nõdvendig
        mov     si, di
        mov     ax, ANTX
        call    make_short_path

    ; Vis õverst i vinduet
        mov     dx, di
        xor     al, al          ; Sentrert õverst
        mov     ch, [mrattr]
        call    bordertext

    ; Les inn filnavn i minnet
        lea     di,[dir]
        lea     si,[mask]
        call    collectfiles

    ; Sjekk om for mange, og vis isÜfall melding om dette.
        cmp     [full], 0
        jz      @@not_too_many
        mov     dx, OFFSET toomany
        mov     al, 5           ; Nederst til hõyre
        mov     ch, [mrattr]
        call    bordertext

  @@not_too_many:
    ; Nullstill posisjonspekere
        mov     [from], 0
        mov     [curr], 0

    ; Vis alle i vinduet
        call    show_all_files

        pop     dx

  @@main_loop:
    ; Vis nÜvërende valg uthevet.
        mov     al, [BYTE curr]
        mov     ah, [uattr]
        call    show_one_file

    ; Vent til tast er trykket
        call    getkey

    ; Vis nÜvërende valg ikke uthevet.
        push    ax
        mov     al, [BYTE curr]
        mov     ah, [mtattr]
        call    show_one_file
        pop     ax

    ; Sjekk om avbrutt av bruker
        cmp     ax, 27
        je      @@ret_aborted
        cmp     ax, QUITKEY
        jne     @@not_aborted
        mov     [doquit], 1
  @@ret_aborted:
    ; Lukk vinduet
        call    closewindow

    ; Marker at avbrutt
        stc
        jmp     @@ret

  @@not_aborted:
    ; Sjekk hva for en tast som ble trykket.
        cmp     ax, 13
        jne     @@not_finished
        jmp     @@choice_done
  @@not_finished:
    ; Hvis ikke det er noe Ü velge i, skal ikke markõren kunne flyttes.
        cmp     [numfile], 0
        jz      @@main_loop

        cmp     ax, -71         ; Home
        jne     @@not_home
    ; Flytt til fõrste i listen
        mov     [curr], 0
        jmp     SHORT @@just_pos

  @@not_home:
        cmp     ax, -73         ; PgUp
        jne     @@not_page_up
    ; Flytt til forrige side
        sub     [curr], CHOOSEX * CHOOSEY
        jmp     SHORT @@just_pos

  @@not_page_up:
        cmp     ax, -79         ; End
        jne     @@not_end
    ; Flytt til siste i listen
        mov     ax, [numfile]
        dec     ax
        mov     [curr], ax
        jmp     SHORT @@just_pos

  @@not_end:
        cmp     ax, -81         ; PgDn
        jne     @@not_page_down
    ; Flytt til neste side
        add     [curr], CHOOSEX * CHOOSEY
        jmp     SHORT @@just_pos

  @@not_page_down:
        cmp     ax, -72         ; Pil opp
        jne     @@not_up
    ; Flytt til forrige linje hvis dette ikke er fõr fõrste
        sub     [curr], CHOOSEX
        jmp     SHORT @@just_pos

  @@not_up:
        cmp     ax, -80         ; Pil ned
        jne     @@not_down
    ; Flytt til neste linje hvis dette ikke er forbi siste
        add     [curr], CHOOSEX
        jmp     SHORT @@just_pos

  @@not_down:
        cmp     ax, -75         ; Pil venstre
        jne     @@not_left
    ; Flytt til venstre
        dec     [curr]
        jmp     SHORT @@just_pos

  @@not_left:
        cmp     ax, -77         ; Pil hõyre
        jne     @@not_right
    ; Flytt til hõyre
        inc     [curr]
        jmp     SHORT @@just_pos

  @@not_right:
        jmp     @@main_loop

  @@just_pos:
    ; Juster posisjonen slik at den er innenfor skjermen. Utfõrer
    ; all testing med signed compare. Spar from slik at det kan sjekkes
    ; om denne er endret.
        mov     bx, [from]
        cmp     [curr], 0
        jge     @@curr_not_below
        mov     [curr], 0
        jmp     SHORT @@just_from
    @@curr_not_below:
        mov     ax, [numfile]
        dec     ax
        cmp     [curr], ax
        jle     @@just_from
        mov     [curr], ax
    @@just_from:
        mov     ax, [from]
        add     ax, CHOOSEX * CHOOSEY
        cmp     ax, [curr]
        jg      @@from_not_below
        add     [from], CHOOSEX
        jmp     @@just_from
    @@from_not_below:
        mov     ax, [curr]
        cmp     [from], ax
        jle     @@show_it
        sub     [from], CHOOSEX
        jmp     @@from_not_below

    @@show_it:
        cmp     [from], bx
        je      @@need_not_display
        call    show_all_files
    @@need_not_display:
        jmp     @@main_loop

  @@choice_done:
    ; Hvis ikke det var noe Ü velge, skal vi returnere med
    ; avbruttkode.
        cmp     [numfile], 0
        jnz     @@something_choosen
        jmp     @@ret_aborted

  @@something_choosen:
    ; Et eller annet er valgt. Dette skal legges til pÜ slutten av
    ; dir og gjõres om til fullpath. Hvis dette ender i \, skal
    ; ny filtabell leses inn, ellers skal det angitte navnet
    ; returneres.
        mov     ax, [curr]
        mov     bl, 14
        mul     bl
        mov     si, OFFSET files
        add     si, ax
        lea     di, [dir]
        call    strcat

    ; Sjekk slutten pÜ navnet.
        push    dx
        mov     dx, di
        call    strlen
        pop     dx
        mov     si, di
        add     di, ax
        dec     di
        cmp     [BYTE di], '\'
        jne     @@filename_given

    ; Det som ble valgt var et directory. Lag ny full path.
        mov     di, si
        call    mkfullpath

    ; Hopp til ny runde.
        jmp     @@new_directory

  @@filename_given:
    ; Endelig har vi fÜtt et filnavn. Dette skal kopieres over i
    ; angitt streng.
        mov     di, dx
        call    strcpy

    ; Fjern fõrst vinduet.
        call    closewindow

    ; Returner med OK-kode.
        clc

  @@ret:
        pop     es
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     bx

        lahf
        add     sp, LSIZE
        sahf

        pop     bp
        pop     ax
        ret
ENDP    choosefile



;
; collectfiles
;
; Hva prosedyren gjõr:
;   Setter opp filarrayen med passende filer fra angitt directory
;
; Kall med:
;   DI : Peker til path som inkluderer terminerende backslash
;   SI : Peker til sõkemaske.
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    collectfiles
    ; Sett opp en lokal variabel som inneholder path med wildcards
        LOCAL   dir: BYTE: MAXFILE = LSIZE

        push    bp
        mov     bp, sp
        sub     sp, LSIZE

        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    si
        push    es

    ; Sett ES = DS
        push    ds
        pop     es

    ; Nullstill antall
        mov     [numfile], 0
        mov     [full], 0

    ; Skal fõrst finne alle filnavn som passer til angitt maske.
    ; Kopier angitt path over i den interne, og legg til masken
        push    di
        push    si

        mov     si, di
        lea     di, [dir]
        call    strcpy

        pop     si

        lea     di, [dir]
        call    strcat

        pop     di

    ; La BX peke dit navnet skal legges inn.
        mov     bx, OFFSET files

    ; Bruk findfirst/next og legg alle filnavn inn i arrayen
        mov     ah, 4Eh
        xor     cx, cx          ; Normal Files
        lea     dx, [dir]
        int     21h
        jc      @@no_more_files

  @@store_filename:
    ; Lagre funnet filnavn i arrayen.
        cmp     [numfile], MAXCHOOSE
        jae     @@too_many_files
        push    di
        push    si
        mov     di, bx          ; ES:DI peker til posisjon i arrayen
        mov     si, 0080h + 30  ; DS:SI peker til filnavnet i DTA.
        call    strcpy
        pop     si
        pop     di

    ; Oppdater telleren og pekeren
        inc     [numfile]
        add     bx, 14          ; Stõrrelsen pÜ hvert element

  @@find_next_filename:
    ; Finn evt neste filnavn
        mov     ah, 4Fh         ; Find Next File
        int     21h
        jnc     @@store_filename
        jmp     SHORT @@no_more_files

  @@too_many_files:
    ; Antallet filer ble for stort. Sett flagg om dette, og hopp ut.
        inc     [full]
        jmp     SHORT @@ret

  @@no_more_files:
    ; Skal sÜ finne alle directorynavn i current dir.
    ; Kopier angitt path over i den interne, og legg til *.*
        push    di
        push    si

        mov     si, di
        lea     di, [dir]
        call    strcpy

        mov     si, OFFSET allmask
        lea     di, [dir]
        call    strcat

        pop     si
        pop     di

    ; Bruk findfirst/next og legg alle directoryer inn i arrayen
        mov     ah, 4Eh
        mov     cx, 16          ; Bit 4 = Directory
        lea     dx, [dir]
        int     21h
        jc      @@ret

  @@store_dir:
    ; Sjekk om dette er et directory. Finner det ut fra DTA'ens
    ; attributtbyte.
        test    [BYTE 0080h + 21], 16   ; Bit 4 = Directory
        jz      @@find_next_dir

    ; Sjekk om dette er directoryet som bestÜr av en prikk. Dette
    ; skal ikke vëre med. Ser etter i DTA'en.
        cmp     [WORD 0080h + 30], '.' + 256 * 0
        je      @@find_next_dir

    ; Lagre funnet directory i arrayen.
        cmp     [numfile], MAXCHOOSE
        jae     @@too_many_files
        push    si
        push    di
        mov     di, bx          ; ES:DI peker til posisjon i arrayen
        mov     si, 0080h + 30  ; DS:SI peker til filnavnet i DTA.
        call    strcpy
    ; Legg pÜ backslash for Ü markere at directory
        mov     dx, di
        call    strlen
        add     di, ax
        mov     [WORD di], '\' + 256 * 0
        pop     di
        pop     si

    ; Oppdater telleren og pekeren
        inc     [numfile]
        add     bx, 14          ; Stõrrelsen pÜ hvert element

  @@find_next_dir:
    ; Finn evt neste directory
        mov     ah, 4Fh         ; Find Next File
        int     21h
        jnc     @@store_dir

  @@ret:
        pop     es
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax

        add     sp, LSIZE
        pop     bp
        ret
ENDP    collectfiles



;
; show_one_file
;
; Hva prosedyren gjõr:
;   Viser filnavn med angitt nummer i den posisjonen som stemmer med from.
;   Hvis filnavnet ikke finnes, vises en blank post.
;
; Kall med:
;   AL : Nummeret pÜ filen
;   AH : ùnsket attributt
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    show_one_file
        push    ax
        push    cx
        push    dx
        push    di
        push    si
        push    es

    ; Sett ES=DS
        push    ds
        pop     es

    ; Filnavnet skal vises vha. dispbuf. Fyll denne med blanke, og en
    ; null-byte pÜ slutten.
        push    ax
        mov     di, OFFSET dispbuf
        mov     cx, 7           ; 14 / 2
        mov     ax, ' ' + 256 * ' '
        cld
        rep     stosw
        xor     al, al
        stosb
        pop     ax

    ; Sett attributten.
        mov     cx, ax          ; Spar AX i CX
        mov     al, ah
        call    textattr
        mov     ax, cx

    ; Finn ut hvilken posisjon den skal vises pÜ. Finner offset fra
    ; fõrste i vinduet, og deler pÜ antall i x-retningen. Dette
    ; gir y-posisjon som svar, og x-posisjon som rest.
        xor     ah, ah
        sub     ax, [from]
        js      @@ret           ; Utenfor vinduet
        mov     dl, CHOOSEX
        div     dl
        xchg    al, ah          ; AL=X, AH=Y

        cmp     ah, CHOOSEY
        jae     @@ret           ; Utenfor vinduet

        mov     ch, ah          ; Spar Y-posisjonen

        mov     dl, 14          ; Antall tegn pÜ hver
        mul     dl
        mov     ah, ch
        call    gotoxy

    ; Det skal flyttes hit etterpÜ ogsÜ. Spar AX pÜ stacken
        push    ax

    ; Hent tilbake nummeret
        mov     al, cl

    ; Hvis nummeret er for stort, skal bare blanke vises.
        cmp     al, [BYTE numfile]
        jae     @@showname

    ; Finn adressen i tabellen
        mul     dl
        add     ax, OFFSET files
        mov     si, ax
        mov     di, OFFSET dispbuf + 1

    ; Kopier navnet over i displaybufferet uten nullbyten
        cld
  @@still_more:
        lodsb
        or      al, al
        jz      @@showname
        stosb
        jmp     @@still_more

  @@showname:
    ; Vis linjen med navnet
        mov     dx, OFFSET dispbuf
        call    outtext

    ; Flytt markõren til begynnelsen av navnet.
        pop     ax
        inc     al
        call    gotoxy

  @@ret:
        pop     es
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     ax
        ret
ENDP    show_one_file



;
; show_all_files
;
; Hva prosedyren gjõr:
;   Oppdaterer hele vinduet ved Ü vise alle filnavn, og fylle ut
;   med blanke pÜ det som er igjen.
;   Visningen starter med filnummeret i from i õverste venstre
;   hjõrne.
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
PROC    show_all_files
        push    ax
        push    cx

        mov     cx, CHOOSEX * CHOOSEY
        mov     al, [BYTE from]
        mov     ah, [mtattr]
  @@still_more:
        call    show_one_file
        inc     al
        loop    @@still_more

        pop     cx
        pop     ax
        ret
ENDP    show_all_files





ENDS

        END
