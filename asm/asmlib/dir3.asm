        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING

INCLUDE "DIR.INC"


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

    ; Null ut m�lpathen.
        mov     [BYTE di], 0

    ; Lag en renset versjon av angitt path, og legg denne i orgpth.
    ; Rensingen best�r i � skippe blanke i starten, p� slutten,
    ; samt � oversette til store bokstaver.

    ; Skip blanke
        cld
  @@skip_blank:
        lodsb
        or      al, al
        jnz     @@more_left
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

    ; Sett SI til den nye strengen. DI peker allerede til m�lomr�det.
        lea     si, [orgpth]

    ; Sjekk om det er noe igjen av strengen.
        cmp     [BYTE si], 0
        jnz     @@still_more
        jmp     @@ret

  @@still_more:
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
    ; Legg f�rst inn en leading backslash, siden ikke DOS-funksjonen
    ; inkluderer denne.
        push    si
        lea     si, [dskdir]
        mov     [BYTE si], '\'
        inc     si

        mov     ah, 47h         ; Get Current Directory
        inc     dl              ; trenger 0=default, 1=A:, 2=B:, ...
        int     21h

        pop     si
        jnc     @@drive_ok

    ; Angitt drive var ikke gyldig. Returner med feilkode.
        mov     ax, 1
        jmp     SHORT @@ret

  @@drive_ok:
    ; Sjekk om backslash er angitt. Hvis ikke, skal det tas utgangspunkt
    ; i current directory.
        cmp     [BYTE si], '\'
        je      @@root_given

    ; Kopier fra n�v�rende directory. Bruker ikke strcpy, for DI
    ; skal oppdateres.
        push    si
        lea     si, [dskdir]
        cld
  @@copy_more_1:
        lodsb
        stosb
        or      al, al
        jnz     @@copy_more_1
        pop     si

        dec     di

    ; Og legg p� en backslash hvis ikke det allerede er sist.
        cmp     [BYTE di - 1], '\'
        je      @@root_given
        mov     al, '\'
        stosb

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

        mov     ah, 3Bh         ; Set Current Directory
        lea     dx, [orgpth]
        int     21h
        jc      @@try_without

    ; Det var mulig � bytte til directoryet. Legg p� en backslash
    ; for � indikere at directory, og returner.
        dec     di
        mov     al, '\' + 0 * 256
        cld
        stosw

    ; Marker at OK.
        xor     ax, ax
        jmp     SHORT @@restore_directory

    ; Det gikk ikke � chdir'e til hele pathen. Fjern siste del,
    ; og pr�v igjen.
  @@try_without:
    ; S�k bakover i den midlertidige linjen etter backslash. Dette
    ; skal helt sikkert finnes.
        call    strlen
        mov     si, dx
        add     si, ax
        std
  @@find_backslash:
        lodsb
        cmp     al, '\'
        jne     @@find_backslash

    ; Kutt strengen p� det stedet.
        inc     si
        inc si
        mov     [BYTE si], 0

    ; Pr�v � bytte til dette directoryet.
        mov     ah, 3Bh         ; Set Current Directory
        lea     dx, [orgpth]
        int     21h
        jc      @@not_valid

    ; Det gikk. Da er det som er angitt en fil. Marker at OK.
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


        END
