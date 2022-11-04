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
askrfil DB      (MAXFILE + 1) DUP (?) ; Filnavn under sp�rring om lesing
askwfil DB      (MAXFILE + 1) DUP (?) ; Filnavn under sp�rring om skriving
blkfil  DB      (MAXFILE + 1) DUP (?) ; For sp�rring p� blokkles/skriv
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

  ; Standard extension. Det er denne som legges til p� filnavn
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
; Hva prosedyren gj�r:
;   Setter opp for bruk av filer. (h�yt niv�)
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
PROC    endfile
        ret
ENDP    endfile



;
; readfilelow
;
; Hva prosedyren gj�r:
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

    ; Sl� av blokkoppdatering n�r en fil leses. Da gjelder jo allikevel
    ; ikke n�v�rende blokkmark�rer.
        mov     [blockmv], 0

    ; Sett opp ES:DI til � peke p� xlin
        push    ds
        pop     es
        mov     di, OFFSET xlin

    ; Sjekk om filen eksisterer. Hvis den _ikke_ gj�r det, regnes dette som
    ; en ny fil, ellers gj�res det fors�k p� � lese den inn.
        mov     ax, 4300h          ; Get File Attribute
        mov     dx, OFFSET filenm
        int     21h
        jnc     @@file_exists

    ; Hvis Get File Attribute ga en annen feilmelding enn at filen ikke
    ; eksisterer, antas det at filen heller ikke kan �pnes, og det
    ; gis melding om dette.
        cmp     ax, 2              ; File not found
        je      @@make_empty_line

  @@open_error:
    ; Filen kunne ikke �pnes. Siden openreadfile ikke gir melding om dette,
    ; m� vi gj�re det selv.
        mov     dx, OFFSET notopen
        call    error

    ; Nullstill filnavnet siden dette allikevel er feil. Senere b�r det
    ; kanskje velges annen strategi her.
        mov     [BYTE filenm], 0
        call    showfilename

    ; Lag en tom linje s� teksten ikke er helt tom.
        jmp     SHORT @@make_empty_line

  @@file_exists:
    ; Filen eksisterer. Les den inn fra fil. DX inneholder fortsatt filnavn.
        call    openreadfile
        jc      @@open_error

  @@open_ok:
    ; Sett opp for registeroverf�ring til readline
        mov     dx, di          ; DS:DX til xlin. Brukt av readline
        mov     cx, MAXLEN
        mov     ax, 1           ; Marker at siste linje endte i newline.
                                ; P� den m�ten unng�r jeg tom editor
                                ; hvis filen er tom.
  @@next_line:
    ; Les en linje fra fil
        call    readline
        jc      @@close_file

    ; Sett inn linjen p� slutten. ES:DI peker til xlin
        call    appendline
        jnc     @@next_line

  @@close_file:
    ; Det er ikke mer � lese. Lukk filen
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

    ; Sl� p� blokkoppdatering igjen.
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
; Hva prosedyren gj�r:
;   Kaller readfilelow etter � ha sjekket picklisten
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

    ; Oppdater f�rst informasjonen om evt n�v�rende fil i picklisten.
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
    ; Les inn den nye filen p� normalt vis.
        call    readfilelow

    ; Legg det leste eller nullstilte f�rst i picklisten
        call    newpickitem

  @@ret:
        pop     dx
        pop     ax
        ret
ENDP    readfile



;
; writefile
;
; Hva prosedyren gj�r:
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

    ; �pne filen for skriving
        call    openwritefile
        jnc     @@open_ok

    ; Filen lot seg ikke �pne. Feilmelding er allerede vist av openwritefile.
    ; Nullstill filnavnet siden dette allikevel er feil.
        mov     [BYTE filenm], 0
        call    showfilename
        jmp     SHORT @@ret

  @@open_ok:
    ; Sett opp ES:DI (brukes av getline) og DS:DX (brukes av writeline)
    ; til � peke p� xlin.
        push    ds
        pop     es
        mov     di, OFFSET xlin
        mov     dx, di

    ; Start l�kke som g�r gjennom alle linjer i teksten.
        mov     cx, [antlin]
        xor     ax, ax      ; Linjenummeret

  @@next_line:
    ; Hent ny linje fra teksten
        call    getline
        inc     ax

    ; Sjekk om dette er siste linje. Is�fall skal ikke
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

    ; Marker at teksten n� er lagret, og derved ikke endret.
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
; Hva prosedyren gj�r:
;   Sjekker angitt filnavn for � finne ut om det inneholder wildcards.
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

    ; Finn slutten p� linjen, slik at det kan s�kes bakover.
        call    strlen
        mov     si, dx
        add     si, ax          ; DS:SI peker til slutten av linjen

    ; Let bakover til et av f�lgende inntreffer:
    ;   1. Begynnelsen p� navnet finnes
    ;   2. / eller \ finnes
    ;   3. * eller ? finnes
    ; I tilfellene 1 og 2, har ikke filen wildcards.
    ; I tilfelle 3, har den det.

        dec     si
        std
  @@prev_char:
    ; Har vi n�dd begynnelsen p� navnet?
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
; Hva prosedyren gj�r:
;   Renamer angitt fil slik at den f�r etternavnet BAK. Teksten som
;   DX peker p� endres ikke.
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

    ; Finn slutten p� linjen, slik at det kan s�kes bakover.
        mov     dx, di
        call    strlen
        add     di, ax          ; DS:DI peker til slutten av linjen
        mov     si, di          ; og det gj�r DS:SI ogs�.

    ; Let bakover til et av f�lgende inntreffer:
    ;   1. Begynnelsen p� navnet finnes
    ;   2. / eller \ finnes
    ;   3. . finnes
    ; I tilfellene 1 og 2, skal .BAK legges til p� slutten av linjen.
    ; I tilfelle 3, skal BAK legges til etter .
  @@prev_char:
        dec     di

    ; Har vi n�dd begynnelsen p� navnet?
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
    ; angitt fra f�r. Slutten p� strengen er midlertidig lagret i SI
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

    ; Utf�r sletting av evt. gammel BAK-fil.
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
; Hva prosedyren gj�r:
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

    ; Finn slutten p� linjen, slik at det kan s�kes bakover.
        call    strlen
        mov     si, dx
        add     si, ax          ; DS:SI peker til slutten av linjen

    ; Let bakover til et av f�lgende inntreffer:
    ;   1. Begynnelsen p� navnet finnes
    ;   2. / eller \ finnes
    ;   3. . finnes
    ; I tilfellene 1 og 2, har ikke filen etternavn, og det gamle
    ; skal forbli uendret.
    ; I tilfelle 3, skal etternavnet hentes.
    ; Oppdater CX s� den senere kan brukes under kopiering.
        mov     cx, 1   ; Start p� 1 for � f� med 0'en
  @@prev_char:
        dec     si
        inc     cx

    ; Har vi n�dd begynnelsen p� navnet?
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
        ja      @@ret   ; Da har jeg glemt � sjekke at navnet er lovlig!

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
; Hva prosedyren gj�r:
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

    ; Finn slutten p� linjen, slik at det kan s�kes bakover.
        call    strlen
        mov     si, dx
        add     si, ax          ; DS:SI peker til slutten av linjen
        mov     di, si          ; og det gj�r DS:DI ogs�.

    ; Let bakover til et av f�lgende inntreffer:
    ;   1. Begynnelsen p� navnet finnes
    ;   2. / eller \ finnes
    ;   3. . finnes
    ; I tilfellene 1 og 2, har ikke filen etternavn, og skal derfor f� det.
    ; I tilfelle 3, har filen allerede et etternavn.
  @@prev_char:
        dec     si
    ; Har vi n�dd begynnelsen p� navnet?
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
    ; Etternavn skal legges inn. Sjekk f�rst om etternavnet er blankt.
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
    ; Sjekk om navnet n� ender med en '.'
    ; Den skal is�fall fjernes for � unng� problemer i picklisten.
    ; Oppdaget at filer blir lagre i listen to ganger hvis de
    ; f�rst ble lagt inn fra bruker med '.' og s� senere hentet
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
; Hva prosedyren gj�r:
;   Hvis angitt path er lenger enn angitt antall tegn, forkortes
;   den visuelt inntil den er innenfor �nsket lengde.
;   Den nye pathen legges i angitt m�lomr�de uansett om den er
;   endret eller ikke.
;   Hvis pathen starter med current directory, fjernes dette.
;
; Kall med:
;   AX - maks lengde. M� v�re minst 19 !!!
;   SI - kildepath. orginalen. Denne m� v�re en fullpath. (mkfullpath)
;   DI - m�lomr�de.
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

    ; Hent path til n�v�rende directory, og legg denne i curdir.
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

    ; Sjekk om root, is�fall skal ikke backslash legges til.
        mov     dx, si
        call    strlen
        add     si, ax
        cmp     [BYTE si - 1], '\'
        je      @@root_dir
        mov     [WORD si], '\' + 256 * 0
  @@root_dir:
        pop     si
        pop     di

    ; Sjekk om angitt path starter med funnet n�v�rende dir.
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
    ; Angitt path starter med current dir. Sjekk om lengden p� strengen
    ; n�r curdir er fjernet er innenfor angitt grense
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
    ; Fjern current directory. SI peker n� til f�rste tegn etter
    ; dette, s� det er bare � kopiere resten.
        call    strcpy
        jmp     SHORT @@ret

  @@copy_all:
    ; Kopier hele kildestrengen over i m�lstrengen, og pr�ver � korte
    ; den ned p� en annen m�te.
        push    ds
        pop     es
        call    strcpy

    ; Finn lengden p� strengen og legg denne i DX
        mov     dx, di
        call    strlen
        mov     dx, ax

    ; Det er ikke sikkert vi trenger � gj�re noe som helst
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

    ; Alt arbeidet skal n� skje innenfor m�lstrengen.
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
; Hva prosedyren gj�r:
;   Sjekker om angitt fil eksisterer, og sp�r is�fall om den skal
;   overskrives.
;
; Kall med:
;   DS:DX : peker til filnavn
;
; Returnerer:
;   AX : Tast som evt. avsluttet sp�rringen. Hvis filen ikke
;        eksisterer, returneres ogs� 'Y'.
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
    ; Sp�r om filen skal overskrives.
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
; Hva prosedyren gj�r:
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
    ; Sjekk om pathen er et directory. Is�fall skal * legges til.
        mov     dx, di
        call    strlen
        add     di, ax
        dec     di
        cmp     [BYTE di], '\'
        jne     @@append_ext

        inc     di
        mov     [WORD di], '*' + 256 * 0

  @@append_ext:
    ; Legg evt p� standard etternavn.
        call    append_std_ext

    ; Sjekk om wildcards er angitt. Is�fall skal brukeren f� mulighet
    ; for � velge fil.
        call    wildcards       ; Setter Carry akkurat som vi vil ha det!
        jnc     @@ret

        call    choosefile      ; Det gj�r denne ogs�!

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
; Hva prosedyren gj�r:
;   Ber bruker om et filnavn. Viser feilmelding hvis ulovlig path.
;
; Kall med:
;   DX - Peker til streng som skal v�re header i vinduet
;   SI - Peker til dit filnavnet skal legges
;
; Returnerer:
;   Carry : clear - Ikke avbrutt av bruker
;           set   - Avbrutt av bruker, eller ikke lovlig path.
;                   Det som l� i SI er ikke endret.
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
        mov     ax, MAXFILE     ; Maks lengde p� et filnavn
        mov     bx, 40          ; Antall tegn som vises av gangen
        call    userinput
        jc      @@ret

    ; Lag full path, og sjekk at den er lovlig osv.
        call    expandfilename
        jc      @@ret

    ; Alt er ok, s� kopier over filnavnet.
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
; Hva prosedyren gj�r:
;   Ber bruker om et filnavn, som s� leses inn.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   AX - tast som avsluttet sp�rring p� filnavn
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

    ; Oppdater f�rst informasjonen om n�v�rende fil i picklisten
        call    updatepickitem

    ; Nullstill svarvariabel
        xor     ax, ax

    ; Les inn filnavn i variablen [askrfil]
    ; Sjekk f�rst hva som ligger her fra f�r. Hvis det som ligger her
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
    ; F�r n�v�rende fil forkastes, m� bruker f� mulighet til � lagre.
        call    checksaved
        cmp     ax, 27  ; Er Esc trykket? Avbryt is�fall innlesningen.
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

    ; Hent n�v�rende linje inn i linjebufferet
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
; Hva prosedyren gj�r:
;   Lagrer n�v�rende fil.
;   Hvis filnavnet er tomt, bes det om nytt filnavn.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   AX - tast som evt avsluttet sp�rring p� filnavn
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
    ; Sjekk f�rst hva som ligger her fra f�r. Hvis det som ligger her
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

    ; F�r filen lagres, m� den gamle renames til en BAK-fil
        mov     dx, OFFSET filenm
        call    make_bak_file

    ; Skriv filen
        call    writefile

    ; Siden filen n� har f�tt navn, m� picktabellen oppdateres.
        call    newpickitem

        jmp     SHORT @@ret

  @@file_given:
    ; F�r filen lagres, m� den gamle renames til en BAK-fil
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
; Hva prosedyren gj�r:
;   Ber om navn p� og leser blokk fra fil.
;
; Kall med:
;   AX : linjen blokken skal leses inn p�
;   BX : kolonnen blokken skal leses inn p�
;
; Returnerer:
;   Carry - clear : Fullf�rt lesing
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
    ; Sjekk f�rst hva som ligger her fra f�r. Hvis ikke det ligger noe her,
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

    ; Marker at avbrutt av bruker, siden ikke filen er �pnet engang.
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
; Hva prosedyren gj�r:
;   Lagrer n�v�rende blokk hvis blokken er p�.
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

    ; Sjekk om blokken er p�. Den skal ikke skrives hvis ikke.
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

    ; F�r blokken kan lagres, m� den gamle renames til en BAK-fil
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
