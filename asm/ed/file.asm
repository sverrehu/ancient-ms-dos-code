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

        PUBLIC  filenm, tmpfile

filenm  DB      (MAXFILE + 1) DUP (?) ; Filnavnet
askrfil DB      (MAXFILE + 1) DUP (?) ; Filnavn under spõrring om lesing
askwfil DB      (MAXFILE + 1) DUP (?) ; Filnavn under spõrring om skriving
blkfil  DB      (MAXFILE + 1) DUP (?) ; For spõrring pÜ blokkles/skriv
tmpfile DB      (MAXFILE + 1) DUP (?) ; Midlertidig filnavn. Brukes feks
                                      ; av make_bak_file



DATASEG

        EXTRN   notopen: PTR, ovrwrt: PTR
        EXTRN   readfhd: PTR, writfhd: PTR
        EXTRN   readbhd: PTR, writbhd: PTR, illegal: PTR
        EXTRN   antlin: WORD
        EXTRN   r_file: PTR, w_file: PTR
        EXTRN   changed: BYTE
        EXTRN   blockon: BYTE, blockmv: BYTE
        EXTRN   xlin: PTR

  ; Standard extension. Det er denne som legges til pÜ filnavn
  ; som ikke har angitt extension.
stdext  DB      ".", 4 DUP (0)





CODESEG

;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

        EXTRN   strcpy: PROC, strlen: PROC, strupr: PROC, strip: PROC
        EXTRN   closewindow: PROC
        EXTRN   CHOICE: PROC
        EXTRN   mkfullpath: PROC

        EXTRN   error: PROC, message: PROC
        EXTRN   getline: PROC, appendline: PROC

        EXTRN   openreadfile: PROC, readline: PROC, closereadfile: PROC
        EXTRN   openwritefile: PROC, writeline: PROC, closewritefile: PROC

        EXTRN   setchanged: PROC, showchanged: PROC, showfilename: PROC
        EXTRN   checksaved: PROC
        EXTRN   userinput: PROC

        EXTRN   reset_ed: PROC, show_info: PROC, fetchline: PROC
        EXTRN   newfile: PROC

        EXTRN   choosefile: PROC

        EXTRN   updatepickitem: PROC, newpickitem: PROC, checkifpick: PROC
        EXTRN   loadfrompick: PROC

        EXTRN   readblock: PROC, writeblock: PROC

        PUBLIC  initfile, endfile
        PUBLIC  readfilelow, readfile, savefile, loadfile, expandfilename
        PUBLIC  make_bak_file, append_std_ext, make_short_path
        PUBLIC  loadblock, saveblock



;
; initfile
;
; Hva prosedyren gjõr:
;   Setter opp for bruk av filer. (hõyt nivÜ)
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
PROC    initfile
        push    ax
        xor     al, al
        mov     [blkfil], al
        mov     [askrfil], al
        mov     [askwfil], al
        pop     ax
        ret
ENDP    initfile



;
; endfile
;
; Hva prosedyren gjõr:
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
PROC    endfile
        ret
ENDP    endfile



;
; readfilelow
;
; Hva prosedyren gjõr:
;   Leser inn en fil i minnet.
;   Filens navn skal ligge i [filenm]
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
PROC    readfilelow
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    es

    ; SlÜ av blokkoppdatering nÜr en fil leses. Da gjelder jo allikevel
    ; ikke nÜvërende blokkmarkõrer.
        mov     [blockmv], 0

    ; Sett opp ES:DI til Ü peke pÜ xlin
        push    ds
        pop     es
        mov     di, OFFSET xlin

    ; Sjekk om filen eksisterer. Hvis den _ikke_ gjõr det, regnes dette som
    ; en ny fil, ellers gjõres det forsõk pÜ Ü lese den inn.
        mov     ax, 4300h          ; Get File Attribute
        mov     dx, OFFSET filenm
        int     21h
        jnc     @@file_exists

    ; Hvis Get File Attribute ga en annen feilmelding enn at filen ikke
    ; eksisterer, antas det at filen heller ikke kan Üpnes, og det
    ; gis melding om dette.
        cmp     ax, 2              ; File not found
        je      @@make_empty_line

  @@open_error:
    ; Filen kunne ikke Üpnes. Siden openreadfile ikke gir melding om dette,
    ; mÜ vi gjõre det selv.
        mov     dx, OFFSET notopen
        call    error

    ; Nullstill filnavnet siden dette allikevel er feil. Senere bõr det
    ; kanskje velges annen strategi her.
        mov     [BYTE filenm], 0
        call    showfilename

    ; Lag en tom linje sÜ teksten ikke er helt tom.
        jmp     SHORT @@make_empty_line

  @@file_exists:
    ; Filen eksisterer. Les den inn fra fil. DX inneholder fortsatt filnavn.
        call    openreadfile
        jc      @@open_error

  @@open_ok:
    ; Sett opp for registeroverfõring til readline
        mov     dx, di          ; DS:DX til xlin. Brukt av readline
        mov     cx, MAXLEN
        mov     ax, 1           ; Marker at siste linje endte i newline.
                                ; PÜ den mÜten unngÜr jeg tom editor
                                ; hvis filen er tom.
  @@next_line:
    ; Les en linje fra fil
        call    readline
        jc      @@close_file

    ; Sett inn linjen pÜ slutten. ES:DI peker til xlin
        call    appendline
        jnc     @@next_line

  @@close_file:
    ; Det er ikke mer Ü lese. Lukk filen
        call    closereadfile

    ; Hvis siste linje endte med newline, skal en tom linje legges til
        or      ax, ax          ; Satt av readline
        jz      @@get_extension

  @@make_empty_line:
    ; Sett inn tom linje.
        mov     [BYTE di], 0
        call    appendline

  @@get_extension:
    ; Filen er lest. Sett denne filens extension som standard.
        mov     dx, OFFSET filenm
        call    get_std_ext

  @@ret:
    ; Marker at teksten er uendret
        mov     [changed], 0
        call    showchanged

    ; SlÜ pÜ blokkoppdatering igjen.
        mov     [blockmv], 1

        pop     es
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    readfilelow



;
; readfile
;
; Hva prosedyren gjõr:
;   Kaller readfilelow etter Ü ha sjekket picklisten
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
PROC    readfile
        push    ax
        push    dx

    ; Oppdater fõrst informasjonen om evt nÜvërende fil i picklisten.
    ; Sjekk om det er noen fil her.
        cmp     [antlin], 0
        jz      @@check_pick
        call    updatepickitem

  @@check_pick:
    ; Sjekk om angitt filnavn svarer til et som ligger i picklisten.
    ; Hvis det er tilfelle, skal filen leses inn med det oppsett
    ; som er beskrevet i pickfilen.
        mov     dx, OFFSET filenm
        call    checkifpick
        cmp     ax, -1
        je      @@read_normal

    ; Her er filnavnet funnet i picklisten. La filen leses av
    ; pickprosedyrene.
        call    loadfrompick
        jmp     SHORT @@ret

  @@read_normal:
    ; Les inn den nye filen pÜ normalt vis.
        call    readfilelow

    ; Legg det leste eller nullstilte fõrst i picklisten
        call    newpickitem

  @@ret:
        pop     dx
        pop     ax
        ret
ENDP    readfile



;
; writefile
;
; Hva prosedyren gjõr:
;   Skriver teksten til filen med navn angitt i [filenm].
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
PROC    writefile
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    es

    ; èpne filen for skriving
        call    openwritefile
        jnc     @@open_ok

    ; Filen lot seg ikke Üpne. Feilmelding er allerede vist av openwritefile.
    ; Nullstill filnavnet siden dette allikevel er feil.
        mov     [BYTE filenm], 0
        call    showfilename
        jmp     SHORT @@ret

  @@open_ok:
    ; Sett opp ES:DI (brukes av getline) og DS:DX (brukes av writeline)
    ; til Ü peke pÜ xlin.
        push    ds
        pop     es
        mov     di, OFFSET xlin
        mov     dx, di

    ; Start lõkke som gÜr gjennom alle linjer i teksten.
        mov     cx, [antlin]
        xor     ax, ax      ; Linjenummeret

  @@next_line:
    ; Hent ny linje fra teksten
        call    getline
        inc     ax

    ; Sjekk om dette er siste linje. IsÜfall skal ikke
    ; CR LF vises. Dette angis ved at AX=0
        push    ax
        sub     ax, [antlin]
        call    writeline
        pop     ax
        jc      @@close_file

        loop    @@next_line

  @@close_file:
    ; Alt er skrevet. Lukk filen.
        call    closewritefile

    ; Marker at teksten nÜ er lagret, og derved ikke endret.
        mov     [changed], 0
        call    showchanged

@@ret:
        pop     es
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    writefile



;
; wildcards
;
; Hva prosedyren gjõr:
;   Sjekker angitt filnavn for Ü finne ut om det inneholder wildcards.
;
; Kall med:
;   DS:DX - peker til filnavnet
;
; Returnerer:
;   Carry : clear - Ikke wildcards
;           set - wildcards
;
; Endrer innholdet i:
;   Ingenting
;
PROC    wildcards
        push    ax
        push    si

    ; Finn slutten pÜ linjen, slik at det kan sõkes bakover.
        call    strlen
        mov     si, dx
        add     si, ax          ; DS:SI peker til slutten av linjen

    ; Let bakover til et av fõlgende inntreffer:
    ;   1. Begynnelsen pÜ navnet finnes
    ;   2. / eller \ finnes
    ;   3. * eller ? finnes
    ; I tilfellene 1 og 2, har ikke filen wildcards.
    ; I tilfelle 3, har den det.

        dec     si
        std
  @@prev_char:
    ; Har vi nÜdd begynnelsen pÜ navnet?
        cmp     si, dx
        jb      @@not_found

        lodsb

        cmp     al, '?'
        je      @@found

        cmp     al, '*'
        je      @@found

        cmp     al, '/'
        je      @@not_found

        cmp     al, '\'
        jne     @@prev_char

  @@not_found:
    ; Ingen wildcards funnet. Marker dette og hopp ut.
        clc
        jmp     SHORT @@ret

  @@found:
    ; Fant wildcards. Marker dette.
        stc

  @@ret:
        pop     si
        pop     ax
        ret
ENDP    wildcards



;
; make_bak_file
;
; Hva prosedyren gjõr:
;   Renamer angitt fil slik at den fÜr etternavnet BAK. Teksten som
;   DX peker pÜ endres ikke.
;
; Kall med:
;   DX : Peker til filnavnet
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    make_bak_file
        push    ax
        push    bx
        push    dx
        push    si
        push    di
        push    es

    ; Husk angitt filnavn i BX
        mov     bx, dx

    ; Legg angitt filnavn over i tmpfile for redigering.
        push    ds
        pop     es
        mov     di, OFFSET tmpfile
        mov     si, dx
        call    strcpy

    ; Finn slutten pÜ linjen, slik at det kan sõkes bakover.
        mov     dx, di
        call    strlen
        add     di, ax          ; DS:DI peker til slutten av linjen
        mov     si, di          ; og det gjõr DS:SI ogsÜ.

    ; Let bakover til et av fõlgende inntreffer:
    ;   1. Begynnelsen pÜ navnet finnes
    ;   2. / eller \ finnes
    ;   3. . finnes
    ; I tilfellene 1 og 2, skal .BAK legges til pÜ slutten av linjen.
    ; I tilfelle 3, skal BAK legges til etter .
  @@prev_char:
        dec     di

    ; Har vi nÜdd begynnelsen pÜ navnet?
        cmp     di, OFFSET tmpfile
        jb      @@append_BAK

        mov     al, [di]
        cmp     al, '/'
        je      @@append_BAK

        cmp     al, '\'
        je      @@append_BAK

        cmp     al, '.'
        jne     @@prev_char

    ; Her er '.' funnet. Legg inn BAK etter denne.
        jmp     SHORT @@store_BAK

  @@append_BAK:
    ; Legg til BAK etter hele navnet, siden ikke noe navn var
    ; angitt fra fõr. Slutten pÜ strengen er midlertidig lagret i SI
        mov     di, si

  @@store_BAK:
    ; Her er endelig DI satt til der .BAK skal legges inn!
        cld
        mov     ax, '.' + 'B' * 256     ; .B
        stosw
        mov     ax, 'A' + 'K' * 256     ; AK
        stosw
        xor     al, al                  ; '\0'
        stosb

    ; Utfõr sletting av evt. gammel BAK-fil.
    ; DX peker fremdeles til tmpfile
        mov     ah, 41h         ; Delete file
        int     21h

    ; Rename filen
        mov     dx, bx                  ; DS:DX til angitt filnavn
        mov     di, OFFSET tmpfile      ; ES:DI til BAK-filnavn
        mov     ah, 56h                 ; Rename file
        int     21h

  @@ret:
        pop     es
        pop     di
        pop     si
        pop     dx
        pop     bx
        pop     ax
        ret
ENDP    make_bak_file



;
; get_std_ext
;
; Hva prosedyren gjõr:
;   Legger extension til angitt fil inn i stdext, slik at
;   denne blir standard.
;
; Kall med:
;   DS:DX - peker til filnavnet
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    get_std_ext
        push    ax
        push    cx
        push    di
        push    si
        push    es

    ; Finn slutten pÜ linjen, slik at det kan sõkes bakover.
        call    strlen
        mov     si, dx
        add     si, ax          ; DS:SI peker til slutten av linjen

    ; Let bakover til et av fõlgende inntreffer:
    ;   1. Begynnelsen pÜ navnet finnes
    ;   2. / eller \ finnes
    ;   3. . finnes
    ; I tilfellene 1 og 2, har ikke filen etternavn, og det gamle
    ; skal forbli uendret.
    ; I tilfelle 3, skal etternavnet hentes.
    ; Oppdater CX sÜ den senere kan brukes under kopiering.
        mov     cx, 1   ; Start pÜ 1 for Ü fÜ med 0'en
  @@prev_char:
        dec     si
        inc     cx

    ; Har vi nÜdd begynnelsen pÜ navnet?
        cmp     si, dx
        jb      @@ret

        mov     al, [si]

        cmp     al, '/'
        je      @@ret

        cmp     al, '\'
        je      @@ret

        cmp     al, '.'
        jne     @@prev_char

    ; Her er '.' funnet. Hent ut extension
        cmp     cx, 5   ; punktum, 3 tegn, og 0.
        ja      @@ret   ; Da har jeg glemt Ü sjekke at navnet er lovlig!

        push    ds
        pop     es
        mov     di, OFFSET stdext
        cld
        rep     movsb

  @@ret:
        pop     es
        pop     si
        pop     di
        pop     cx
        pop     ax
        ret
ENDP    get_std_ext



;
; append_std_ext
;
; Hva prosedyren gjõr:
;   Legger standard extenion bak angitt filnavn hvis det
;   ikke allerede har en extension.
;   Hvis filnavnet slutter med '.', fjernes denne.
;
; Kall med:
;   DS:DX - peker til filnavnet
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    append_std_ext
        push    ax
        push    cx
        push    di
        push    si
        push    es

    ; Sett ES = DS
        push    ds
        pop     es

    ; Finn slutten pÜ linjen, slik at det kan sõkes bakover.
        call    strlen
        mov     si, dx
        add     si, ax          ; DS:SI peker til slutten av linjen
        mov     di, si          ; og det gjõr DS:DI ogsÜ.

    ; Let bakover til et av fõlgende inntreffer:
    ;   1. Begynnelsen pÜ navnet finnes
    ;   2. / eller \ finnes
    ;   3. . finnes
    ; I tilfellene 1 og 2, har ikke filen etternavn, og skal derfor fÜ det.
    ; I tilfelle 3, har filen allerede et etternavn.
  @@prev_char:
        dec     si
    ; Har vi nÜdd begynnelsen pÜ navnet?
        cmp     si, dx
        jb      @@append

        mov     al, [si]

        cmp     al, '.'
        je      @@check_if_dot

        cmp     al, '/'
        je      @@append

        cmp     al, '\'
        jne     @@prev_char

  @@append:
    ; Etternavn skal legges inn. Sjekk fõrst om etternavnet er blankt.
    ; Hvis det er det, og wildcards er angitt, skal .* legges til.
        mov     si, OFFSET stdext
        cmp     [BYTE si], 0
        je      @@check_if_dot
        cmp     [BYTE si + 1], 0
        jne     @@no_wildcards

    ; Sjekk om wildcards er angitt
        call    wildcards
        jnc     @@no_wildcards

    ; Legg til ".*" og avslutt. ES:DI peker til slutten.
        mov     ax, '.' + 256 * '*'
        cld
        stosw
        xor     al, al
        stosb

        jmp     SHORT @@ret

  @@no_wildcards:
    ; Legg inn standard etternavn. ES:DI peker allerede til slutten.
        call    strcpy

  @@check_if_dot:
    ; Sjekk om navnet nÜ ender med en '.'
    ; Den skal isÜfall fjernes for Ü unngÜ problemer i picklisten.
    ; Oppdaget at filer blir lagre i listen to ganger hvis de
    ; fõrst ble lagt inn fra bruker med '.' og sÜ senere hentet
    ; via choosefile uten dot.
        mov     di, dx
        call    strlen
        add     di, ax
        dec     di
        cmp     [BYTE di], '.'
        jne     @@ret

        mov     [BYTE di], 0

  @@ret:
        pop     es
        pop     si
        pop     di
        pop     cx
        pop     ax
        ret
ENDP    append_std_ext



;
; make_short_path
;
; Hva prosedyren gjõr:
;   Hvis angitt path er lenger enn angitt antall tegn, forkortes
;   den visuelt inntil den er innenfor õnsket lengde.
;   Den nye pathen legges i angitt mÜlomrÜde uansett om den er
;   endret eller ikke.
;   Hvis pathen starter med current directory, fjernes dette.
;
; Kall med:
;   AX - maks lengde. Mè vëre minst 19 !!!
;   SI - kildepath. orginalen. Denne mÜ vëre en fullpath. (mkfullpath)
;   DI - mÜlomrÜde.
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    make_short_path

    ; Setter opp lokal variabel for current directory.
        LOCAL   curdir: BYTE: MAXFILE = LSIZE

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

    ; Spar maks lengde i CX
        mov     cx, ax

    ; Hent path til nÜvërende directory, og legg denne i curdir.
    ; Pathen skal inneholde drive og avsluttende backslash
        push    di
        lea     di, [curdir]

        mov     ah, 19h         ; Get Current disk
        int     21h
        mov     dl, al
        inc     dl
        add     al, 'A'

        cld
        stosb
        mov     ax, ':' + 256 * '\'
        stosw

        push    si
        mov     ah, 47h         ; Get Current Directory
        mov     si, di
        int     21h

    ; Sjekk om root, isÜfall skal ikke backslash legges til.
        mov     dx, si
        call    strlen
        add     si, ax
        cmp     [BYTE si - 1], '\'
        je      @@root_dir
        mov     [WORD si], '\' + 256 * 0
  @@root_dir:
        pop     si
        pop     di

    ; Sjekk om angitt path starter med funnet nÜvërende dir.
        lea     bx, [curdir]
        mov     dx, si          ; Lagre SI i DX

        cld
  @@still_equal:
        mov     ah, [bx]
        or      ah, ah
        jz      @@contains_curdir
        inc     bx
        lodsb
        cmp     al, ah
        je      @@still_equal

    ; Her er ikke current path en del av angitt path. Sett SI tilbake
    ; til startet av strengen, og hopp til kopiering av hele strengen.
        mov     si, dx
        jmp     SHORT @@copy_all

  @@contains_curdir:
    ; Angitt path starter med current dir. Sjekk om lengden pÜ strengen
    ; nÜr curdir er fjernet er innenfor angitt grense
        push    dx
        mov     dx, si
        call    strlen
        pop     dx
        cmp     ax, cx
        jbe     @@remove_curdir

    ; Det var den ikke. Sett tilbake SI til starten av strengen, og velg
    ; den andre metoden.
        mov     si, dx
        jmp     SHORT @@copy_all

  @@remove_curdir:
    ; Fjern current directory. SI peker nÜ til fõrste tegn etter
    ; dette, sÜ det er bare Ü kopiere resten.
        call    strcpy
        jmp     SHORT @@ret

  @@copy_all:
    ; Kopier hele kildestrengen over i mÜlstrengen, og prõver Ü korte
    ; den ned pÜ en annen mÜte.
        push    ds
        pop     es
        call    strcpy

    ; Finn lengden pÜ strengen og legg denne i DX
        mov     dx, di
        call    strlen
        mov     dx, ax

    ; Det er ikke sikkert vi trenger Ü gjõre noe som helst
        cmp     dx, cx
        jbe     @@ret

    ; Hopp forbi C:\
        add     di, 3

    ; Legg inn elipsis (tre punktum) og en backslash
        mov     ax, '.' + 256 * '.'
        cld
        stosw
        mov     ah, '\'
        stosw

    ; Alt arbeidet skal nÜ skje innenfor mÜlstrengen.
        mov     si, di

    ; Hopp over tegn framover til lengden blir mindre eller lik CX.
  @@still_too_long:
        inc     si
        dec     dx
        cmp     dx, cx
        ja      @@still_too_long

    ; Scan til neste backslash blir funnet.
        cld
  @@look_for_backslash:
        lodsb
        cmp     al, '\'
        jne     @@look_for_backslash

    ; Kopier over resten av strengen.
        call    strcpy

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
ENDP    make_short_path



;
; askoverwrite
;
; Hva prosedyren gjõr:
;   Sjekker om angitt fil eksisterer, og spõr isÜfall om den skal
;   overskrives.
;
; Kall med:
;   DS:DX : peker til filnavn
;
; Returnerer:
;   AX : Tast som evt. avsluttet spõrringen. Hvis filen ikke
;        eksisterer, returneres ogsÜ 'Y'.
;
; Endrer innholdet i:
;   AX
;
PROC    askoverwrite
        push    dx

    ; Sjekk om filen eksisterer.
        mov     ax, 4300h          ; Get File Attribute
        int     21h
        jnc     @@file_exists

    ; Avslutt med 'Y' returnert.
        mov     ax, 'Y'
        jmp     SHORT @@ret

  @@file_exists:
    ; Spõr om filen skal overskrives.
        mov     dx, OFFSET ovrwrt
        call    message
        call    CHOICE
        call    closewindow

  @@ret:
        pop     dx
        ret
ENDP    askoverwrite



;
; expandfilename
;
; Hva prosedyren gjõr:
;   Utvider angitt filnavn til full path, legger til standard extension,
;   og, hvis wildcards er angitt, gir liste over matchende filer.
;
;   Hvis denne returnerer uten feilkode, er filnavnet uten wildcards.
;
; Kall med:
;   SI - Peker til filnavnet
;
; Returnerer:
;   Carry : clear - Ok, og ikke avbrutt av bruker
;           set   - Avbrutt av bruker, eller ikke lovlig path.
;                   Innholdet i strengen settes til 0
;
; Endrer innholdet i:
;   Ingenting
;
PROC    expandfilename
        push    ax
        push    dx
        push    di
        push    si

    ; Lag full path, og sjekk at den er lovlig.
        mov     di, si
        call    mkfullpath
        or      ax, ax
        jz      @@path_ok

    ; Deler av pathen var ikke lovlig. Vis dette, nullstill,
    ; og returner med feilkode.
        mov     dx, OFFSET illegal
        call    error

        mov     [BYTE di], 0
        stc
        jmp     SHORT @@ret

  @@path_ok:
    ; Sjekk om pathen er et directory. IsÜfall skal * legges til.
        mov     dx, di
        call    strlen
        add     di, ax
        dec     di
        cmp     [BYTE di], '\'
        jne     @@append_ext

        inc     di
        mov     [WORD di], '*' + 256 * 0

  @@append_ext:
    ; Legg evt pÜ standard etternavn.
        call    append_std_ext

    ; Sjekk om wildcards er angitt. IsÜfall skal brukeren fÜ mulighet
    ; for Ü velge fil.
        call    wildcards       ; Setter Carry akkurat som vi vil ha det!
        jnc     @@ret

        call    choosefile      ; Det gjõr denne ogsÜ!

  @@ret:
        pop     si
        pop     di
        pop     dx
        pop     ax

        ret
ENDP    expandfilename



;
; getfilename
;
; Hva prosedyren gjõr:
;   Ber bruker om et filnavn. Viser feilmelding hvis ulovlig path.
;
; Kall med:
;   DX - Peker til streng som skal vëre header i vinduet
;   SI - Peker til dit filnavnet skal legges
;
; Returnerer:
;   Carry : clear - Ikke avbrutt av bruker
;           set   - Avbrutt av bruker, eller ikke lovlig path.
;                   Det som lÜ i SI er ikke endret.
;
; Endrer innholdet i:
;   Ingenting
;
PROC    getfilename

    ; Bruk en lokal variabel til midlertidig filnavn.
        LOCAL   tmpf: BYTE: MAXFILE = LSIZE

        push    ax
        push    bp
        mov     bp, sp
        sub     sp, LSIZE

        push    bx
        push    di
        push    si
        push    es

    ; Kopier innholdet over i tmpf
        push    ds
        pop     es
        lea     di, [tmpf]
        call    strcpy

    ; Be bruker om filnavn
        xchg    si, di
        mov     ax, MAXFILE     ; Maks lengde pÜ et filnavn
        mov     bx, 40          ; Antall tegn som vises av gangen
        call    userinput
        jc      @@ret

    ; Lag full path, og sjekk at den er lovlig osv.
        call    expandfilename
        jc      @@ret

    ; Alt er ok, sÜ kopier over filnavnet.
        call    strcpy

    ; Marker at ok.
        clc

  @@ret:
        pop     es
        pop     si
        pop     di
        pop     bx

        lahf
        add     sp, LSIZE
        sahf

        pop     bp
        pop     ax
        ret
ENDP    getfilename



;
; loadfile
;
; Hva prosedyren gjõr:
;   Ber bruker om et filnavn, som sÜ leses inn.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   AX - tast som avsluttet spõrring pÜ filnavn
;
; Endrer innholdet i:
;   AX
;
PROC    loadfile
        push    cx
        push    dx
        push    di
        push    si
        push    es

    ; Oppdater fõrst informasjonen om nÜvërende fil i picklisten
        call    updatepickitem

    ; Nullstill svarvariabel
        xor     ax, ax

    ; Les inn filnavn i variablen [askrfil]
    ; Sjekk fõrst hva som ligger her fra fõr. Hvis det som ligger her
    ; inneholder wildcards, skal det beholdes. Hvis ikke, skal
    ; det settes til "*." + standard etternavn.
        mov     dx, OFFSET askrfil
        call    wildcards
        jc      @@get_it

    ; Sett askrfil til "*.xxx"
        mov     [WORD askrfil], '*' + 256 * 0

  @@get_it:
        call    append_std_ext
        mov     dx, OFFSET readfhd
        mov     si, OFFSET askrfil
        call    getfilename
        jnc     @@filename_given

    ; Marker at abrutt
        mov     ax, 27
        jmp     SHORT @@ret

  @@filename_given:
    ; Fõr nÜvërende fil forkastes, mÜ bruker fÜ mulighet til Ü lagre.
        call    checksaved
        cmp     ax, 27  ; Er Esc trykket? Avbryt isÜfall innlesningen.
        je      @@ret

    ; Nullstill variabler for editoren
        call    newfile
        call    show_info

    ; Kopier nytt filnavn over i [filenm]
        mov     si, OFFSET askrfil
        push    ds
        pop     es
        mov     di, OFFSET filenm
        call    strcpy
        mov     dx, di
        call    strupr
        call    showfilename

    ; Les inn filen.
        call    readfile

    ; Hent nÜvërende linje inn i linjebufferet
        call    fetchline
        call    show_info

  @@ret:
        pop     es
        pop     si
        pop     di
        pop     dx
        pop     cx
        ret
ENDP    loadfile



;
; savefile
;
; Hva prosedyren gjõr:
;   Lagrer nÜvërende fil.
;   Hvis filnavnet er tomt, bes det om nytt filnavn.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   AX - tast som evt avsluttet spõrring pÜ filnavn
;
; Endrer innholdet i:
;   AX
;
PROC    savefile
        push    cx
        push    dx
        push    di
        push    si
        push    es

    ; Nullstill svarvariabel
        xor     ax, ax

    ; Sjekk om filnavn er angitt
        cmp     [filenm], 0
        jne     @@file_given

  @@input_filename:
    ; Les inn filnavn i variablen [askwfil]
    ; Sjekk fõrst hva som ligger her fra fõr. Hvis det som ligger her
    ; inneholder wildcards, skal det beholdes. Hvis ikke, skal
    ; det settes til "*." + standard etternavn.
        mov     dx, OFFSET askwfil
        call    wildcards
        jc      @@get_it

    ; Sett askwfil til "*.xxx"
        mov     [WORD askwfil], '*' + 256 * 0

  @@get_it:
        call    append_std_ext
        mov     dx, OFFSET writfhd
        mov     si, OFFSET askwfil
        call    getfilename
        jnc     @@new_filename

    ; Marker at avbrutt
        mov     ax, 27
        jmp     SHORT @@ret

  @@new_filename:
    ; Sjekk om filen eksisterer
        mov     dx, si
        call    askoverwrite
        cmp     ax, 'N'
        je      @@input_filename
        cmp     ax, 27
        je      @@ret

    ; Kopier nytt filnavn over i [filenm]
        mov     si, OFFSET askwfil
        push    ds
        pop     es
        mov     di, OFFSET filenm
        call    strcpy
        mov     dx, di
        call    strupr
        call    showfilename

    ; Fõr filen lagres, mÜ den gamle renames til en BAK-fil
        mov     dx, OFFSET filenm
        call    make_bak_file

    ; Skriv filen
        call    writefile

    ; Siden filen nÜ har fÜtt navn, mÜ picktabellen oppdateres.
        call    newpickitem

        jmp     SHORT @@ret

  @@file_given:
    ; Fõr filen lagres, mÜ den gamle renames til en BAK-fil
        mov     dx, OFFSET filenm
        call    make_bak_file

    ; Skriv filen
        call    writefile

  @@ret:
        pop     es
        pop     si
        pop     di
        pop     dx
        pop     cx
        ret
ENDP    savefile



;
; loadblock
;
; Hva prosedyren gjõr:
;   Ber om navn pÜ og leser blokk fra fil.
;
; Kall med:
;   AX : linjen blokken skal leses inn pÜ
;   BX : kolonnen blokken skal leses inn pÜ
;
; Returnerer:
;   Carry - clear : Fullfõrt lesing
;           set   : Avbrutt av bruker
;
; Endrer innholdet i:
;   Ingenting
;
PROC    loadblock
        push    ax
        push    dx
        push    si

    ; Les inn filnavn i variablen blkfil
    ; Sjekk fõrst hva som ligger her fra fõr. Hvis ikke det ligger noe her,
    ; skal det settes til "*." + standard etternavn.
        cmp     [BYTE blkfil], 0
        jnz     @@get_it

    ; Sett blkfil til "*.xxx"
        mov     dx, OFFSET blkfil
        mov     [WORD blkfil], '*' + 256 * 0

  @@get_it:
    ; Les inn filnavn i variablen blkfil
        call    append_std_ext
        mov     dx, OFFSET readbhd
        mov     si, OFFSET blkfil
        call    getfilename
        jc      @@ret

  @@check_exists:
    ; Sjekk om filen eksisterer.
        push    ax
        mov     ax, 4300h          ; Get File Attribute
        mov     dx, OFFSET blkfil
        int     21h
        pop     ax
        jnc     @@file_exists

    ; Vis melding om at filen ikke eksisterer, og hopp ut.
        mov     dx, OFFSET notopen
        call    error

    ; Marker at avbrutt av bruker, siden ikke filen er Üpnet engang.
        stc
        jmp     SHORT @@ret

  @@file_exists:
    ; Les inn blokken
        mov     dx, OFFSET blkfil
        call    readblock

    ; Marker at ikke avbrutt av bruker.
        clc

  @@ret:
        pop     si
        pop     dx
        pop     ax
        ret
ENDP    loadblock



;
; saveblock
;
; Hva prosedyren gjõr:
;   Lagrer nÜvërende blokk hvis blokken er pÜ.
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
PROC    saveblock
        push    ax
        push    dx
        push    si

    ; Sjekk om blokken er pÜ. Den skal ikke skrives hvis ikke.
        cmp     [blockon], 0
        jz      @@ret

  @@input_filename:
    ; Les inn filnavn i variablen blkfil
        mov     dx, OFFSET writbhd
        mov     si, OFFSET blkfil
        call    getfilename
        jc      @@ret

  @@check_exists:
    ; Sjekk om filen eksisterer
        mov     dx, si
        call    askoverwrite
        cmp     ax, 'N'
        je      @@input_filename
        cmp     ax, 27
        je      @@ret

    ; Fõr blokken kan lagres, mÜ den gamle renames til en BAK-fil
        mov     dx, OFFSET blkfil
        call    make_bak_file

    ; Skriv blokken
        call    writeblock

  @@ret:
        pop     si
        pop     dx
        pop     ax
        ret
ENDP    saveblock





ENDS

        END
