;
; OBS OBS OBS!
;
; Denne er ikke ferdig, og den blir det sikkert ikke med det f›rste!
;


        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING



;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        EXTRN   strcpy: PROC, strcat: PROC

        PUBLIC  fnsplit


;
; fnsplit
;
; Hva prosedyren gj›r:
;   Deler en path i drive, dir, name, og ext.
;   Hvis pathen ikke egentlig inneholder et filnavn, bare directory,
;   vil siste delen av directoryet bli tolket som filnavn. Det
;   gj›res ingen testing p† hva tingene egentlig er.
;
; Kall med:
;   SI : Peker til pathen
;   BX : Peker dit drive skal legges
;   CX : Peker dit dir skal legges
;   DX : Peker dit name skal legges
;   DI : Peker dit ext skal legges
;
;   Alt er innenfor DS.
;
;   De fire siste pekerne kan v‘re 0 for † indikere at elementet ikke
;   skal hentes ut.
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    fnsplit
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    si

    ; Nullstill de variablene som skal registreres.
        push    si
        or      bx, bx
        jz      @@dont_zero_drive
        mov     [BYTE bx], 0

  @@dont_zero_drive:
        jcxz    @@dont_zero_dir
        mov     si, cx
        mov     [BYTE si], 0

  @@dont_zero_dir:
        or      dx, dx
        jz      @@dont_zero_nme
        mov     si, dx
        mov     [BYTE si], 0

  @@dont_zero_nme:
        or      di, di
        jz      @@dont_zero_ext
        mov     [BYTE di], 0

  @@dont_zero_ext:
        pop     si

    ; Hopp over evt blanke i starten.
        cld

  @@skip_blank:
        lodsb
        or      al, al
        jz      @@ret
        cmp     al, ' '
        je      @@skip_blank

    ; Sjekk om drive er angitt
        cmp     [BYTE si], ':'
        jne     @@no_drive

    ; Sjekk om drive skal lagres
        or      bx, bx
        jz      @@skip_drive

    ; Drive skal lagres.
        mov     [bx], al
        mov     [WORD bx + 1], ':' + 256 * 0    ; Kolon og null

  @@skip_drive:
        inc     si
        lodsb

  @@no_drive:

    ; G† n† f›rst til slutten og finn evt extension. BX er ledig for bruk.
        push    dx
        mov     dx, si
        call    strlen
        pop     dx




  @@ret:
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    fnsplit


        END
