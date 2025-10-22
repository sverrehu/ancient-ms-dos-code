        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING

INCLUDE "DIR.INC"

;
; Hvis DEGUG NE 0, gis det meldinger om hva som skjer.
;
DEBUG   EQU     0



;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        EXTRN   strip: PROC, strcpy: PROC, strupr: PROC, strlen: PROC

        PUBLIC  mkfullpath


;
; mkfullpath
;
; Hva prosedyren gj�r:
;   Lager fullstendig path av en ufullstendig.
;
; Kall med:
;   SI : Ufullstendig path
;   DI : �nsket m�lsted for full path. Hvis denne endre i \ er pathen
;        et directory, hvis ikke er den en fil. Det er ikke sikkert denne
;        filen eksisterer eller er lovlig, men pathen opp til den er
;        garantert i orden.
;
;   Begge er relativt til DS.
;
; Returnerer:
;   AX : 0 - OK
;      : 1 - Ugyldig drive
;      : 2 - Ugyldig directory
;      : 3 - Ingenting er angitt
;
; Merk:
;   Bruker stacken til lokale variabler.
;
; Endrer innholdet i:
;   AX
;
PROC    mkfullpath

    ; Sett opp for lokale variabler.
    ;   dskdir: Tar vare p� current directory p� disken det gjelder
    ;           mens det nye directoryet utpr�ves.
    ;   orgpth: Renset versjon av angitt path

    LOCAL   dskdir: BYTE: MAXPATH, orgpth: BYTE: MAXPATH, dstadr: WORD = LSIZE

        push    bp
        mov     bp, sp
        sub     sp, LSIZE

        push    bx
        push    cx
        push    dx
        push    di
        push    si
        push    es

    ; Sett opp s� ES = DS
        push    ds
        pop     es

    ; Spar m�ladressen
        mov     [dstadr], di

    ; Lag en renset versjon av angitt path, og legg denne i orgpth.
    ; Rensingen best�r i � skippe blanke i starten, p� slutten,
    ; samt � oversette til store bokstaver.

    ; Skip blanke
        cld
  @@skip_blank:
        lodsb
        or      al, al
        jnz     @@more_left
  @@empty_line:
        mov     ax, 3
        jmp     @@ret
  @@more_left:
        cmp     al, ' '
        je      @@skip_blank

        dec     si

    ; Kopier strengen over i orgpth
        push    di
        lea     di, [orgpth]
        mov     dx, di
        call    strcpy
        pop     di

    ; Gj�r den "pen"
        call    strip
        call    strupr

    ; Null ut m�lpathen.
        mov     [BYTE di], 0

    ; Sett SI til den nye strengen. DI peker allerede til m�lomr�det.
        lea     si, [orgpth]

    ; Sjekk om det er noe igjen av strengen.
        cmp     [BYTE si], 0
        jz      @@empty_line

    ; Sjekk om drive er angitt.
        cmp     [BYTE si + 1], ':'
        jne     @@no_drive_given

    ; Drive er angitt. Legg denne over i den nye linjen.
        cld
        lodsb
        stosb   ; Drive-bokstaven

    ; Legg drivenummeret i DL
        mov     dl, al
        sub     dl, 'A'

    ; Overf�r kolonet ogs�
        lodsb
        stosb   ; ':'

        jmp     SHORT @@read_direct

  @@no_drive_given:
    ; Det var ikke angitt noen drive. Bruk n�v�rende.
        mov     ah, 19h         ; Get Current Disk
        int     21h

        mov     dl, al          ; Funnet disk i DL

    ; Legg diskbokstaven og et kolon inn i arrayet
        add     al, 'A'
        cld
        stosb
        mov     al, ':'
        stosb

    ; N� har m�lstrengen f�tt en diskbokstav og et kolon, og
    ; DL inneholder drivenummeret (0=A:, 1=B:, ...)
    ; Leser current directory p� angitt disk inn i dskdir
  @@read_direct:
    ; Legg f�rst inn diskbokstaven, kolon og en leading backslash, siden
    ; ikke DOS-funksjonen inkluderer dette.
        push    si
        lea     si, [dskdir]
        mov     [BYTE si], dl
        add     [BYTE si], 'A'
        inc     si
        mov     [WORD si], ':' + 256 * '\'
        add     si, 2

        mov     ah, 47h         ; Get Current Directory
        inc     dl              ; trenger 0=default, 1=A:, 2=B:, ...
        int     21h

        pop     si
        jnc     @@drive_ok

    ; Angitt drive var ikke gyldig. Returner med feilkode.
        mov     ax, 1
        jmp     @@ret

  @@drive_ok:
    ; Sjekk om backslash er angitt. Hvis ikke, skal det tas utgangspunkt
    ; i current directory.
        cmp     [BYTE si], '\'
        je      @@root_given

    ; Kopier fra n�v�rende directory. Bruker ikke strcpy, for DI
    ; skal oppdateres.
        push    si
        lea     si, [dskdir + 2]
        cld
  @@copy_more_1:
        lodsb
        stosb
        or      al, al
        jnz     @@copy_more_1
        pop     si

    ; Og legg p� en backslash hvis ikke det allerede er sist.
        mov     dx, [dstadr]
        call    mkbackslash
        mov     di, dx
        call    strlen
        add     di, ax

  @@root_given:
    ; Kopier fra orginallinjen. Bruker ikke strcpy n� heller.
        cld
  @@copy_more_2:
        lodsb
        stosb
        or      al, al
        jnz     @@copy_more_2

    ; N� er hele angitte path "brukt opp". Fors�k f�rst � chdir'e
    ; til denne i tilfelle bare en path er angitt.

    ; Kopier den genererte linjen over i det midlertidige bufferet.
        push    di
        mov     si, [dstadr]
        lea     di, [orgpth]
        call    strcpy
        pop     di

    ; Fjen evt backslash siden ChDir ikke liker dette.
        mov     dx, [dstadr]
        call    rmbackslash

    IF DEBUG
        push    dx
        mov     dx, OFFSET tstdir
        call    print
        pop     dx
        call    print
        call    crlf
    ENDIF

        mov     ah, 3Bh         ; Set Current Directory
        int     21h
        jc      @@try_without

    ; Det var mulig � bytte til directoryet. Hent n�v�rende directory
    ; inn i m�lstrengen for � bli kvitt evt \..\ osv.
        mov     si, dx
        mov     dl, [si]
        sub     dl, 'A' - 1
        add     si, 3           ; Forbi x:\
        mov     ah, 47h
        int     21h

    ; Legg p� en backslash for � indikere at directory, og returner.
        mov     dx, [dstadr]
        call    mkbackslash

    ; Marker at OK.
        xor     ax, ax
        jmp     SHORT @@restore_directory

    ; Det gikk ikke � chdir'e til hele pathen. Fjern siste del,
    ; og pr�v igjen.
  @@try_without:
    ; S�k bakover i den midlertidige linjen etter backslash. Dette
    ; skal helt sikkert finnes. Ikke fjern den hvis det er root-
    ; backslashen!
        lea     dx, [orgpth]
        call    strlen
        mov     si, dx
        add     si, ax
        std
  @@find_backslash:
        lodsb
        cmp     al, '\'
        jne     @@find_backslash

    ; Hvis den backslashen er rootbackslash, skal den ikke fjernes. Da
    ; skal en nullbyte settes inn ETTER backslashen.
    ; Dette vil imidlertid overskrive et tegn som vi kanskje
    ; trenger senere. Lagrer derfor dette i AL. Hvis ikke noe tegn
    ; skal lagres, settes AL=0.

        xor     al, al

    ; Sjekk om root-backslash
        cmp     [BYTE si], ':'  ; Hvis tegnet f�r er :, skal ikke \ fjernes.
        jne     @@remove_backslash

    ; Nullen skal settes inn etter backslashen.
        inc     si
        mov     al, [si + 1]    ; Spar tegnet

  @@remove_backslash:
    ; Kutt strengen p� det stedet.
        inc     si
        mov     [BYTE si], 0
        inc     si

    ; Pr�v � bytte til dette directoryet.
        push    ax
        mov     ah, 3Bh         ; Set Current Directory
        lea     dx, [orgpth]

    IF DEBUG
        push    dx
        mov     dx, OFFSET tstdir
        call    print
        pop     dx
        call    print
        call    crlf
    ENDIF

        int     21h
        pop     ax
        jc      @@not_valid

    ; Det gikk. Da er det som er angitt en fil. Hent n�v�rende directory
    ; inn i m�lstrengen for � bli kvitt evt \..\ osv.
    ; Men f�rst: Legg evt tilbake det tegnet som ble overskrevet. Hvis
    ; det var noe tegn, skal ogs� SI minkes med 1 for � f� med dette.
        or      al, al
        jz      @@no_saved_char
        dec     si
        mov     [si], al

  @@no_saved_char:
        push    si
        mov     si, [dstadr]
        mov     dl, [si]
        sub     dl, 'A' - 1
        add     si, 3           ; Forbi x:\
        mov     ah, 47h
        int     21h
        pop     si

    ; Legg p� en backslash for � indikere at directory.
        mov     dx, [dstadr]
        call    mkbackslash

    ; Kopier over den delen av pathen som ble fjernet
        call    strlen
        mov     di, dx
        add     di, ax
        call    strcpy

    ; Marker at OK.
        xor     ax, ax
        jmp     SHORT @@restore_directory

  @@not_valid:
    ; Det som er angitt er ikke noe gyldig directory. Marker dette.
        mov     ax, 2

  @@restore_directory:
    ; Sett tilbake current directory
        push    ax
        mov     ah, 3Bh         ; Set Current Directory
        lea     dx, [dskdir]
        int     21h
        pop     ax

  @@ret:
        pop     es
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     bx

        add     sp, LSIZE
        pop     bp
        ret
ENDP    mkfullpath



;
; rmbackslash
;
; Hva prosedyren gj�r:
;   Sjekker om siste tegn i angitt streng er en backslash, og fjerner
;   is�fall denne hvis strengen er lenger enn 3 tegn. (S� ikke evt.
;   root-backslash blir borte.)
;
;   Intern rutine.
;
; Kall med:
;   DX : Peker til strengen
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    rmbackslash
        push    ax
        push    di

    ; Finn lengden, og sjekk om denne er mer enn 3 tegn.
        call    strlen
        cmp     ax, 3
        jbe     @@ret

    ; Finn siste tegnet.
        mov     di, dx
        add     di, ax
        dec     di

    ; Sjekk om dette er backslash
        cmp     [BYTE di], '\'
        jne     @@ret

    ; Kutt strengen p� denne posisjonen
        mov     [BYTE di], 0

  @@ret:
        pop     di
        pop     ax
        ret
ENDP    rmbackslash



;
; mkbackslash
;
; Hva prosedyren gj�r:
;   Sjekker om siste tegn i angitt streng er en backslash. Hvis ikke,
;   legges en til.
;
;   Intern rutine.
;
; Kall med:
;   DX : Peker til strengen
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    mkbackslash
        push    ax
        push    di

    ; Finn lengden, og sjekk om denne er mer enn 3 tegn.
        call    strlen

    ; Finn siste tegnet.
        mov     di, dx
        add     di, ax
        dec     di

    ; Sjekk om dette er backslash
        cmp     [BYTE di], '\'
        je      @@ret

    ; Legg inn backslash og terminerende nullbyte
        inc     di
        mov     [WORD di], '\' + 256 * 0

  @@ret:
        pop     di
        pop     ax
        ret
ENDP    mkbackslash


IF DEBUG

  ; Viser det DX peker til.
  PROC  print
        push    ax
        push    bx
        push    cx
        call    strlen
        mov     cx, ax
        mov     ah, 40h         ; Write File or Device
        mov     bx, 1           ; stdout
        int     21h
        pop     cx
        pop     bx
        pop     ax
        ret
  ENDP  print


  ; Flytter til neste skjermlinje
  PROC  crlf
        push    dx
        mov     dx, OFFSET newl
        call    print
        pop     dx
        ret
  ENDP  crlf


DATASEG

newl    DB      13, 10, 0
tstdir  DB      "Fors�ker � flytte til ", 0



ENDIF




ENDS
        END
