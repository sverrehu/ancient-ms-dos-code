;
; Holder orden pÜ tellere; poeng, lengde, nivÜ og liv igjen.
;

        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data


INCLUDE "SNAKE3.INC"



UDATASEG

        EXTRN   antledd: WORD

        PUBLIC  score, lives, level


score   DW      ?       ; Poengsum
lives   DW      ?       ; Liv igjen
level   DW      ?       ; SpillnivÜ. 0-9, hvor 0 er lettest
hghchg  DB      ?       ; Er highscore endret?


DATASEG

        PUBLIC  hghtab


hghname DB      NAVN, ".HGH", 0

LABEL   highrecord BYTE
hghid   DB      "Highscores, ", NAVN, 13, 10, 26
hghtab  DB      (10 * (10 + 2)) DUP (0)
LABEL   highrecend BYTE



CODESEG

        EXTRN   showtxt8x6: PROC, shownum8x6: PROC
        EXTRN   showhgh: PROC, inputlin9: PROC

        PUBLIC  showscore, showlength, showlives, showlevel
        PUBLIC  addscore
        PUBLIC  readhgh, writehgh, testhgh




;
; showscore
;
; Hva prosedyren gjõr:
;   Viser poengsummen pÜ skjermen
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
PROC    showscore
        push    ax
        push    cx
        push    dx
        mov     ax, [score]
        mov     cl, 7
        mov     dx, 75 + 256 * 11
        call    shownum8x6
        pop     dx
        pop     cx
        pop     ax
        ret
ENDP    showscore



;
; showlength
;
; Hva prosedyren gjõr:
;   Viser slangelengden pÜ skjermen
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
PROC    showlength
        push    ax
        push    cx
        push    dx
        mov     ax, [antledd]
        mov     cl, 7
        mov     dx, 75 + 256 * 12
        call    shownum8x6
        pop     dx
        pop     cx
        pop     ax
        ret
ENDP    showlength



;
; showlives
;
; Hva prosedyren gjõr:
;   Viser antall liv pÜ skjermen
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
PROC    showlives
        push    ax
        push    cx
        push    dx
        mov     ax, [lives]
        mov     cl, 7
        mov     dx, 75 + 256 * 13
        call    shownum8x6
        pop     dx
        pop     cx
        pop     ax
        ret
ENDP    showlives



;
; showlevel
;
; Hva prosedyren gjõr:
;   Viser spillnivÜ pÜ skjermen
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
PROC    showlevel
        push    ax
        push    cx
        push    dx
        mov     ax, [level]
        mov     cl, 7
        mov     dx, 75 + 256 * 14
        call    shownum8x6
        pop     dx
        pop     cx
        pop     ax
        ret
ENDP    showlevel



;
; addscore
;
; Hva prosedyren gjõr:
;   Legger angitt antall til score, og viser ny score pÜ skjermen.
;
; Kall med:
;   AX : Tall som skal legges til
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    addscore
        add     [score], ax
        call    showscore
        ret
ENDP    addscore



;
; readhgh
;
; Hva prosedyren gjõr:
;   Leser, hvis mulig, highscorefilen.
;   Det gjõres ingen feiltesting pÜ filbehandling.
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
PROC    readhgh
        push    ax
        push    bx
        push    cx
        push    dx

  ; Marker at tabellen ikke er endret
        mov     [hghchg], 0

  ; èpne filen for lesing
        mov     dx, OFFSET hghname
        mov     ax, 3D00h       ; Open File, Read Access
        int     21h
        jc      @@ret           ; Finnes ikke

  ; Les highscoretabellen
        mov     bx, ax
        mov     dx, OFFSET highrecord
        mov     cx, OFFSET highrecend - OFFSET highrecord
        mov     ah, 3Fh         ; Read File or Device
        int     21h

  ; Lukk filen
        mov     ah, 3Eh         ; Close file
        int     21h

@@ret:
  ; Vis tabellen pÜ skjermen
        call    showhgh

        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    readhgh



;
; writehgh
;
; Hva prosedyren gjõr:
;   Skriver highscoretabellen til fil hvis den er endret.
;   Det gjõres ingen feiltesting pÜ filbehandling.
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
PROC    writehgh
        push    ax
        push    bx
        push    cx
        push    dx

  ; Sjekk om highscore er endret. Hvis ikke, hopp ut.
        cmp     [hghchg], 0
        jz      @@ret

  ; èpne highscore-filen.
        mov     dx, OFFSET hghname
        xor     cx, cx          ; Normal file
        mov     ah, 3Ch         ; Create or Truncate File
        int     21h
        jc      @@ret

  ; Skriv highscoretabellen til filen
        mov     bx, ax
        mov     dx, OFFSET highrecord
        mov     cx, OFFSET highrecend - OFFSET highrecord
        mov     ah, 40h         ; Write File or Device
        int     21h

  ; Lukk filen
        mov     ah, 3Eh         ; Close file
        int     21h

  ; Marker at filen er lagret
        mov     [hghchg], 0

@@ret:  pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    writehgh



;
; testhgh
;
; Hva prosedyren gjõr:
;   Tester om highscore, og isÜfall oppdaterer highscoretabellen.
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
PROC    testhgh
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    si
        push    es

  ; Let fra toppen og nedover i highscoretabellen for Ü finne ut
  ; hvor den nye evt. skal plasseres
        mov     bx, OFFSET hghtab
        mov     cx, 10
@@test_neste:
        mov     ax, [bx + 10]
        cmp     ax, [score]
        jb      @@plass_funnet
        add     bx, 12
        loop    @@test_neste

  ; Hvis vi kommer hit, er ikke nÜvërende score med i tabellen. Hopp ut.
        jmp     SHORT @@ret

@@plass_funnet:
  ; Flytt resterende plasser nedover.
        push    cx
        dec     cx
        push    ds
        pop     es
        mov     di, OFFSET highrecend - 1
        mov     si, OFFSET highrecend - 13
        mov     ax, cx
        mov     dl, 12
        mul     dl
        mov     cx, ax
        std
        rep     movsb
        pop     cx

  ; Legg inn ny score
        mov     ax, [score]
        mov     [bx + 10], ax
        mov     [BYTE bx], 0    ; Fjern nÜvërende navn
        call    showhgh

  ; Les inn navn
        mov     di, bx  ; Peker til linjen
        mov     ah, 3   ; Farge
        mov     dl, INSTRX + 4
        mov     dh, 10
        sub     dh, cl
        add     dh, 47
        call    inputlin9

  ; Marker at tabellen er endret
        mov     [hghchg], 1

  ; Vis ny tabell
        call    showhgh

@@ret:  pop     es
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    testhgh



ENDS

        END
