;
; I denne filen er det rutiner for Ü Üpne, lukke, lese linjer fra og
; skrive linjer til en fil.
;
; Filen bufres.
;
; Det er ikke mulig Ü ha mer enn Çn fil Üpen om gangen, og det er svërt
; viktig at filen lukkes etter bruk.
;

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


hdl     DW      ?       ; File handle
bufptr  DW      ?       ; (segment-)Peker til filbuffer
bufpara DW      ?       ; Antall allokerte paragrafer
bufidx  DW      ?       ; Indeks i filbuffer. Peker dit neste tegn
                        ; skal settes inn eller hentes ut.
inbuf   DW      ?       ; Antall tegn i bufferet.



DATASEG

        EXTRN   r_file: PTR, w_file: PTR
        EXTRN   notopen: PTR, closerr: PTR
        EXTRN   readerr: PTR, writerr: PTR
        EXTRN   outmem: PTR, longlin: PTR
        EXTRN   criticl: BYTE





CODESEG

;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

        EXTRN   getmem: PROC, freemem: PROC
        EXTRN   closewindow: PROC

        EXTRN   message: PROC, error: PROC, quit: PROC

        PUBLIC  initfilelow, endfilelow
        PUBLIC  openreadfile, readline, closereadfile
        PUBLIC  openwritefile, writeline, closewritefile




;
; initfilelow
;
; Hva prosedyren gjõr:
;   Allokerer filbuffer osv.
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
PROC    initfilelow
        push    ax
        push    bx
        push    cx
        push    dx
        push    es

   ; Alloker plass til filbuffer
        mov     ax, BUFSIZ
        call    getmem
        or      ax, ax
        jne     @@allok_buf_ok
        mov     dx, OFFSET outmem
        call    error
        jmp     quit
  @@allok_buf_ok:
        mov     [bufptr], es
        mov     [bufpara], ax

    ; Sjekk MS-DOS-versjonen, og installer Critical Error-handler hvis
    ; 3.1 eller hõyere. Det er ikke nõdvendig Ü resette denne senere,
    ; for MS-DOS gjõr det nÜr programmet avsluttes.
        mov     ax, 3000h       ; Get MS-DOS Version Number
        int     21h
        cmp     al, 3           ; AL = Major Version Number
        ja      @@install_crit
        cmp     ah, 10          ; AH = Minor Version Number
        jb      @@ret

  @@install_crit:
    ; MS-DOS v3.1 eller senere er funnet. Installer handler.
        push    ds
        mov     ax, 2524h       ; Set Interrupt 24h
        mov     dx, OFFSET criterr
        push    cs
        pop     ds
        int     21h
        pop     ds

  @@ret:
        pop     es
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    initfilelow



;
; endfilelow
;
; Hva prosedyren gjõr:
;   Frigjõr filbuffer osv.
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
PROC    endfilelow
        push    ax
        push    es
    ; Frigjõr filbuffer
        mov     es, [bufptr]
        mov     ax, [bufpara]
        call    freemem
        pop     es
        pop     ax
        ret
ENDP    endfilelow



;
; criterr
;
; Hva prosedyren gjõr:
;   Dette er en Critical Error Handler som sõrger for at det, ved
;   diskfeil, returneres Fail til MS-DOS. Denne installeres bare
;   hvis MS-DOS versjon 3.1 eller hõyere er installert.
;   Markerer ogsÜ at det har vërt en kritisk feil ved Ü sette et flagg.
;
; Kall med:
;   Ingenting - skal ikke kalles direkte
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    criterr FAR
        push    ds
        push    cs
        pop     ds
        mov     [criticl], 1
        pop     ds

        mov     al, 3           ; Fail
        iret
ENDP    criterr



;
; openreadfile
;
; Hva prosedyren gjõr:
;   èpner en fil for lesing.
;
;   OBS OBS OBS
;     Viser _IKKE_ feilmelding hvis filen ikke kan Üpnes!
;     Det kan tenkes at dette er en ny fil.
;
; Kall med:
;   DS:DX - Peker til filnavnet
;
; Returnerer:
;   Carry : clear - OK. Filen er Üpen.
;           set - Feil. Kunne ikke Üpne filen.
;
; Endrer innholdet i:
;   Ingenting
;
PROC    openreadfile
        push    ax
        push    dx

    ; Vis melding om at det leses fra fil.
        push    dx
        mov     dx, OFFSET r_file
        call    message
        pop     dx

    ; Prõv Ü Üpne filen
        mov     ax, 3D00h       ; Open, read-access
        int     21h
        jnc     @@open_ok

    ; Filen kunne ikke Üpnes. Fjern melding om at det leses.
        call    closewindow

    ; Marker at feil
        stc
        jmp     SHORT @@ret

  @@open_ok:
    ; Filen er Üpnet. Lagre filehandle for senere bruk.
        mov     [hdl], ax

    ; Nullstill variabler for bufferet.
        xor     ax, ax
        mov     [inbuf], ax     ; Ingenting i bufferet
        mov     [bufidx], ax    ; Pek pÜ starten av bufferet

    ; Marker at ok
        clc

  @@ret:
        pop     dx
        pop     ax
        ret
ENDP    openreadfile



;
; fillbuffer
;
; Hva prosedyren gjõr:
;   Hent filbufferet til disk. Viser feilmelding hvis noe gÜr galt.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   CF : clear - OK. Dette er ogsÜ tilfelle hvis ingenting ble lest.
;                    Kalleren mÜ sjekke inbuf.
;        set - feil.
;
; Endrer innholdet i:
;   Ingenting
;
PROC    fillbuffer
        push    ax
        push    bx
        push    cx
        push    dx

        mov     ah, 3Fh         ; Read file or device
        mov     bx, [hdl]
        mov     cx, BUFSIZ      ; Maks antall tegn i bufferet
        xor     dx, dx          ; Bufferstart

        push    ds
        mov     ds, [bufptr]    ; DS:DX peker nÜ til bufferet
        int     21h
        pop     ds

        jnc     @@ret

    ; Ikke vellykket lesing. Vis feilmelding
        mov     dx, OFFSET readerr
        call    error

    ; og marker at feil.
        stc
        jmp     SHORT @@ret

  @@ret:
    ; Lagre antall tegn lest og nullstill indeksen uansett om det
    ; gikk bra eller ikke. mov endrer ikke flaggene!
        mov     [inbuf], ax
        mov     [bufidx], 0

        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    fillbuffer



;
; readline
;
; Hva prosedyren gjõr:
;   Leser en tekstlinje fra filen som er Üpen. Hvis linjen er pÜ fler enn
;   angitt antall tegn (uten avsluttende 0), vises melding om at
;   linjeskift settes inn, og dette gjõres ogsÜ.
;   Viser ogsÜ feilmelding hvis noe galt skjer.
;
; Kall med:
;   CX    - Maks lengde uten avsluttende 0.
;   DS:DX - Peker til mÜlomrÜde for ASCIIZ-linjen. CR LF pÜ filen byttes
;           ut med terminerende 0.
;
; Returnerer:
;   AX    : 0 - linjen endte ikke med newline
;         : 1 - linjen endte med newline
;
;   OBS: Denne endres bare hvis ikke EOF er nÜdd. Det kan nyttegjõres:
;        NÜr ikke det er mer igjen Ü lese, kan det sjekkes om siste
;        leste linje sluttet med newline, selv om readline er kalt
;        en gang til.
;
;   Carry : clear - OK.
;           set - Feil, eller slutt pÜ filen.
;
;   NÜr carry returneres satt, inneholder ikke linjen noe.
;
; Endrer innholdet i:
;   AX hvis ikke EOF
;
PROC    readline
        push    bx
        push    cx
        push    di
        push    si
        push    es

        mov     di, dx
        mov     bx, ax          ; Midlertidig boolsk: newline eller ikke
                                ; Hvis EOF skal denne vëre uforandret

    ; Sett opp ES:SI som bufferindeks
        mov     es, [bufptr]
        mov     si, [bufidx]


  @@next_character:
    ; Les neste tegn fra fil.
    ; Sjekk om det er mer i bufferet
        cmp     si, [inbuf]
        jb      @@fetch_character

    ; Det var det ikke. Forsõk Ü hente mer fra disk.
        call    fillbuffer
        jc      @@ret           ; Feil.

        mov     si, [bufidx]

    ; Sjekk om det ikke var mer igjen pÜ filen
        cmp     [inbuf], 0
        jz      @@end_of_file

    ; Hent neste tegn fra bufferet
  @@fetch_character:
        mov     al, [es: si]
        inc     si

    ; Sjekk om end of file.
        cmp     al, 26          ; Ctrl-Z
        je      @@end_of_file

    ; Sjekk om linjeslutt. CR overses, mens LF markerer slutt.
        cmp     al, 13
        je      @@next_character

        cmp     al, 10
        je      @@newline_character

        xor     bx, bx          ; Forelõpig ikke linjeskift

    ; Legg inn tegnet i linjen
    ; Sjekk om linjen blir for lang
        dec     cx
        jz      @@line_too_long

        mov     [di], al
        inc     di

        jmp     @@next_character

  @@newline_character:
    ; Marker at linjen sluttet med newline.
        inc     bx
        jmp     SHORT @@end_of_line

  @@end_of_file:
    ; Filslutt er nÜdd. Hvis ingen tegn ble lagt inn i strengen,
    ; skal EOF markeres ved at carryflagget blir satt. Ellers skal
    ; linjen avsluttes og carry vëre clear, slik at neste lesing
    ; gir EOF
        cmp     di, dx
        jne     @@end_of_line

    ; Marker EOF
        stc
        jmp     SHORT @@ret

  @@line_too_long:
    ; Linjen har blitt for lang. Vis melding om dette.
        push    dx
        mov     dx, OFFSET longlin
        call    error
        pop     dx

    ; Sett inn 0-terminator og hopp ut.

  @@end_of_line:
    ; Slutten pÜ linjen er nÜdd. Legg inn 0-terminator
        mov     [BYTE di], 0

    ; Marker at ok
        clc

  @@ret:
        mov     [bufidx], si
        mov     ax, bx
        pop     es
        pop     si
        pop     di
        pop     cx
        pop     bx
        ret
ENDP    readline



;
; closereadfile
;
; Hva prosedyren gjõr:
;   Lukker filen som er Üpen for lesing.
;   Viser feilmelding hvis noe gÜr galt.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Carry : clear - OK. Filen er lukket.
;           set - Feil. Kunne ikke lukke filen.
;
; Endrer innholdet i:
;   Ingenting
;
PROC    closereadfile
        push    ax
        push    bx

    ; Lukk filen
        mov     ah, 3Eh         ; Close file
        mov     bx, [hdl]
        int     21h
        jnc     @@ret

    ; Filen kunne ikke lukkes. Vis feilmelding
        push    dx
        mov     dx, OFFSET closerr
        call    error
        pop     dx

    ; og marker at feil.
        stc

  @@ret:
    ; Fjern melding om at det leses fra fil
        pushf
        call    closewindow
        popf

        pop     bx
        pop     ax
        ret
ENDP    closereadfile



;
; openwritefile
;
; Hva prosedyren gjõr:
;   èpner en fil for skriving.
;   Viser feilmeldinding hvis filen ikke kan Üpnes.
;
; Kall med:
;   DS:DX - Peker til filnavnet
;
; Returnerer:
;   Carry : clear - OK. Filen er Üpen.
;           set - Feil. Kunne ikke Üpne filen.
;
; Endrer innholdet i:
;   Ingenting
;
PROC    openwritefile
        push    ax
        push    cx
        push    dx

    ; Vis melding om at det skrives til fil.
        push    dx
        mov     dx, OFFSET w_file
        call    message
        pop     dx

    ; Gjõr forsõk pÜ Ü Üpne filen
        mov     ah, 3Ch         ; Create file (trunc til 0 hvis eksisterer)
        xor     cx, cx          ; Normal
        int     21h
        jnc     @@open_ok

    ; Filen kunne ikke Üpnes. Fjern melding om at det leses
        call    closewindow

    ; Vis feilmelding
        mov     dx, OFFSET notopen
        call    error

    ; og marker at feil.
        stc
        jmp     SHORT @@ret

  @@open_ok:
    ; Filen er Üpnet. Lagre filehandle for senere bruk.
        mov     [hdl], ax

    ; Nullstill variabler for bufferet.
        xor     ax, ax
        mov     [inbuf], ax     ; Ingenting i bufferet
        mov     [bufidx], ax    ; Pek pÜ starten av bufferet

    ; Marker at ok
        clc

  @@ret:
        pop     dx
        pop     cx
        pop     ax
        ret
ENDP    openwritefile



;
; flushbuffer
;
; Hva prosedyren gjõr:
;   Skriver filbufferet til disk. Viser feilmelding hvis noe gÜr galt.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   CF : 0 - OK, 1 - feil
;
; Endrer innholdet i:
;   Ingenting
;
PROC    flushbuffer
        push    ax
        push    bx
        push    cx
        push    dx

        mov     ah, 40h         ; Write file or device
        mov     bx, [hdl]
        mov     cx, [bufidx]    ; Antall tegn i bufferet
        xor     dx, dx          ; Bufferstart

    ; Sjekk om bufferet er tomt. Forsõk pÜ Ü skrive 0 bytes
    ; vill trunkere filen.
        jcxz    @@ret_ok

        push    ds
        mov     ds, [bufptr]    ; DS:DX peker nÜ til bufferet
        int     21h
        pop     ds

    ; Sjekk at alle tegnene ble skrevet. DOS kan returnerer OK selv om
    ; ikke alt er tatt med!
        jc      @@write_error
        cmp     ax, [bufidx]
        je      @@ret_ok

  @@write_error:
        mov     dx, OFFSET writerr
        call    error

        stc
        jmp     SHORT @@ret

  @@ret_ok:
    ; Marker at ok
        clc

  @@ret:
    ; Nullstill bufferet uansett om det gikk bra eller ikke.
    ; mov endrer ikke flaggene!
        mov     [bufidx], 0

        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    flushbuffer



;
; putc
;
; Hva prosedyren gjõr:
;   Setter et tegn inn i filbufferet. Hvis bufferet er fullt, skrives
;   det til disk fõr tegnet settes inn.
;
; Kall med:
;   AL : Tegn som skal settes inn i bufferet
;
; Returnerer:
;   CF : 0 - OK, 1 - feil
;
; Endrer innholdet i:
;   Ingenting
;
PROC    putc
        push    di
        push    es

    ; Sjekk om det er plass i bufferet
        cmp     [bufidx], BUFSIZ
        jb      @@store_character

    ; Det var det ikke. Skriv bufferet til disk.
        call    flushbuffer
        jc      @@ret

    ; Sett tegnet inn i bufferet
  @@store_character:
        mov     es, [bufptr]
        mov     di, [bufidx]
        cld
        stosb
        mov     [bufidx], di

    ; Marker at ok
        clc

  @@ret:
        pop     es
        pop     di
        ret
ENDP    putc



;
; writeline
;
; Hva prosedyren gjõr:
;   Skriver angitt tekstlinje til filen som er Üpen.
;
; Kall med:
;   AX    - 0    : Ikke legg pÜ CR LF
;           <> 0 : Legg pÜ CR LF
;   DS:DX - ASCIIZ-linje som skal skrives til filen.
;
; Returnerer:
;   Carry : clear - OK.
;           set - Feil.
;
; Endrer innholdet i:
;   Ingenting
;
PROC    writeline
        push    ax
        push    bx
        push    di
        push    si
        push    es

        mov     si, dx
        mov     bx, ax
        mov     es, [bufptr]
        mov     di, [bufidx]

        cld
  @@next_char:
    ; Hent neste tegn fra linjen
        lodsb

    ; Sjekk om linjen er slutt
        or      al, al
        jz      @@end_of_line

    ; Skriv tegnet til fil.
    ; Sjekk om det er plass i bufferet
        cmp     di, BUFSIZ
        jb      @@store_character

    ; Det var det ikke. Skriv bufferet til disk.
        mov     [bufidx], di
        call    flushbuffer
        mov     di, [bufidx]
        jc      @@ret
        cld

    ; Sett tegnet inn i bufferet
  @@store_character:
        stosb
        jmp     @@next_char

  @@end_of_line:
    ; Lagre bufferindeksen for senere bruk.
        mov     [bufidx], di

    ; Sjekk om CR LF skal skrives ut
        or      bx, bx
        jz      @@ret

    ; Skriv ut CR LF
        mov     al, 13
        call    putc
        jc      @@ret

        mov     al, 10
        call    putc

  @@ret:
        pop     es
        pop     si
        pop     di
        pop     bx
        pop     ax
        ret
ENDP    writeline



;
; closewritefile
;
; Hva prosedyren gjõr:
;   Flusher bufferet og lukker filen som er Üpen for skriving.
;   Viser feilmelding hvis noe gÜr galt.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Carry : clear - OK. Filen er lukket.
;           set - Feil. Kunne ikke lukke filen.
;
; Endrer innholdet i:
;   Ingenting
;
PROC    closewritefile
        push    ax
        push    bx

    ; Flush bufferet
        call    flushbuffer

    ; Lukk filen
        mov     ah, 3Eh         ; Close file
        mov     bx, [hdl]
        int     21h
        jnc     @@ret

    ; Filen kunne ikke lukkes. Vis feilmelding
        push    dx
        mov     dx, OFFSET closerr
        call    error
        pop     dx

    ; og marker at feil.
        stc

  @@ret:
    ; Fjern melding om at det skrives til fil
        pushf
        call    closewindow
        popf

        pop     bx
        pop     ax
        ret
ENDP    closewritefile





ENDS

        END
