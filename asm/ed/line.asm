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

        PUBLIC  wrklin, wrklen


linptr  DW      ?       ; Peker til alle linjepekerne
linpara DW      ?       ; Antall paragrafer allokert til linjepekerne
wrklin  DB      (MAXLEN + 1) DUP (?)    ; Intern arbeidslinje
wrklen  DW      ?                       ; Lengden pÜ arbeidslinjen
wrklin2 DB      (MAXLEN + 1) DUP (?)    ; Intern arbeidslinje
wrklen2 DW      ?                       ; Lengden pÜ arbeidslinjen



DATASEG

        EXTRN   blockmv: BYTE
        EXTRN   outmem: PTR, outlins: PTR, trnclin: PTR
        EXTRN   xlin: PTR, xlinlen: WORD

        PUBLIC  antlin, nostrip

antlin  DW      0       ; Antall linjer
nostrip DB      0       ; Skal ikke linjene strippes nÜr de legges inn?





CODESEG

;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

        EXTRN   getmem: PROC, freemem: PROC, memleft: PROC
        EXTRN   strlen: PROC, strip: PROC

        EXTRN   error: PROC, quit: PROC
        EXTRN   reset_ed: PROC
        EXTRN   blockcontract: PROC, blockexpand: PROC

        PUBLIC  initline, endline
        PUBLIC  chkmem
        PUBLIC  getline
        PUBLIC  setline, insertinline, appendline, removefromline, removeline
        PUBLIC  splitline, splicelines
        PUBLIC  newfile
        PUBLIC  getwrklin



;
; initline
;
; Hva prosedyren gjõr:
;   Allokerer plass til linjepekere osv.
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
PROC    initline
        push    ax
        push    es
        mov     ax, MAXLIN
        shl     ax, 1               ; 2 bytes pr peker
        call    getmem
        or      ax, ax
        jne     @@allok_lin_ok

        push    dx
        mov     dx, OFFSET outmem
        call    error
        pop     dx
        jmp     quit

  @@allok_lin_ok:
        mov     [linptr], es
        mov     [linpara], ax

        pop     es
        pop     ax
        ret
ENDP    initline



;
; endline
;
; Hva prosedyren gjõr:
;   Frigjõr linjepekere osv.
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
PROC    endline
        push    ax
        push    es
        mov     es, [linptr]
        mov     ax, [linpara]
        call    freemem
        pop     es
        pop     ax
        ret
ENDP    endline



;
; chkmem
;
; Hva prosedyren gjõr:
;   Sjekker om ledig minne er innenfor grensen satt i MINMEM.
;   Gir feilmelding hvis ikke.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Carry: clear - OK
;          set   - Feil
;
; Endrer innholdet i:
;   Ingenting
;
PROC    chkmem
        push    ax
        call    memleft
        cmp     ax, MINMEM
        pop     ax
        jb      @@ikke_nok_minne
        clc
        ret

  @@ikke_nok_minne:
        push    dx
        mov     dx, OFFSET outmem
        call    error
        pop     dx

        stc
        ret
ENDP    chkmem



;
; freeline
;
; Hva prosedyren gjõr:
;   Frigir minnet som er brukt av angitt linje.
;
; Kall med:
;   ES - Peker til fõrste linjesegment. Kan vëre 0.
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    freeline
        push    ax
        push    es

  @@neste_linje_segment:
        mov     ax, es
        or      ax, ax          ; Er linjen tom?
        jz      @@ret
        mov     ax, [es: (linseg PTR 0).next]
        push    ax
        mov     ax, LINSEGPARA
        call    freemem
        pop     es
        jmp     SHORT @@neste_linje_segment

  @@ret:
        pop     es
        pop     ax
        ret
ENDP    freeline



;
; getline
;
; Hva prosedyren gjõr:
;   Henter ut õnsket linje, og lager ASCIIZ-string av denne.
;
; Kall med:
;   AX    - ùnsket linjenummer
;   ES:DI - peker til der linjen (ASCIIZ) skal legges. MÜ vëre nok plass
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    getline
        push    ax
        push    bx
        push    si
        push    di
        push    ds
        push    es

    ; Sjekk om linjen eksisterer.
        cmp     ax, [antlin]
        jb      @@eksisterer
    ; Nei, returner tom linje
        mov     [BYTE es: di], 0
        jmp     SHORT @@ret

  @@eksisterer:
        push    es
        mov     es, [linptr]
        mov     bx, ax
        shl     bx, 1
        cmp     [WORD es: bx], 0 ; Er linjen tom?
        jne     @@ikke_tom
        xor     al, al
        pop     es
        cld
        stosb                    ; Lagre 0, slutt pÜ strengen.
        jmp     SHORT @@ret
  @@ikke_tom:
        mov     ds, [es: bx]     ; DS peker til fõrste linjepeker
        pop     es
  @@start_linje:
        mov     si, OFFSET (linseg).text
        cld
  @@neste_tegn:
        lodsb
        stosb
        or      al, al
        jz      @@ret            ; Slutt pÜ strengen
        cmp     si, OFFSET (linseg).text + BPLS
        jb      @@neste_tegn
        mov     ds, [(linseg PTR 0).next]
        jmp     @@start_linje

  @@ret:
        pop     es
        pop     ds
        pop     di
        pop     si
        pop     bx
        pop     ax
        ret
ENDP    getline



;
; getwrklin
;
; Hva prosedyren gjõr:
;   Intern prosedyre som henter angitt linje inn i wrklin og oppdaterer
;   wrklen
;
; Kall med:
;   AX - ùnsket linjenummer
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    getwrklin
        push    ax
        push    dx
        push    di
        push    es

    ; Hent linjen
        push    ds
        pop     es
        mov     di, OFFSET wrklin
        call    getline

    ; Finn lengden
        mov     dx, di
        call    strlen
        mov     [wrklen], ax

        pop     es
        pop     di
        pop     dx
        pop     ax
        ret
ENDP    getwrklin



;
; getwrklin2
;
; Hva prosedyren gjõr:
;   Intern prosedyre som henter angitt linje inn i wrklin2 og oppdaterer
;   wrklen2
;
; Kall med:
;   AX - ùnset linjenummer
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    getwrklin2
        push    ax
        push    dx
        push    di
        push    es

    ; Hent linjen
        push    ds
        pop     es
        mov     di, OFFSET wrklin2
        call    getline

    ; Finn lengden
        mov     dx, di
        call    strlen
        mov     [wrklen2], ax

        pop     es
        pop     di
        pop     dx
        pop     ax
        ret
ENDP    getwrklin2



;
; allocline
;
; Hva prosedyren gjõr:
;   Gjõr om ASCIIZ-streng til riktig linjeformat ved Ü allokere plass og
;   dele opp linjen.
;   Hvis linjen er tom, settes det ikke av noe plass.
;
; Kall med:
;   ES:DI - peker til linjen (ASCIIZ)
;
; Returnerer:
;   Carry: clear - OK
;          set   - Feil
;   AX   : Segmentadressen til begynnelsen pÜ linjen.
;          Hvis det ikke er satt av noe plass, returneres 0.
;
; Endrer innholdet i:
;   AX
;
PROC    allocline
        push    dx
        push    bp
        push    si
        push    di
        push    es

        xor     bp, bp
        cmp     [BYTE es: di], 0        ; Er linjen tom?
        je      @@ret_OK

        call    chkmem          ; Sjekk om det er nok minne igjen
        jc      @@ret

        mov     si, di          ; Klargjõr for (DS):SI til kildelinjen
        mov     dx, es          ; DX brukes som "holder" for DS

        mov     ax, LINSEGSIZ
        call    getmem
        or      ax, ax
        jnz     @@plass_til_forste
  @@ikke_plass:
        mov     dx, OFFSET outmem
        call    error
  @@ret_error:
        stc                     ; Indikerer feil
        jmp     SHORT @@ret
  @@plass_til_forste:
        mov     bp, es          ; Ta vare pÜ segmentadressen i BP (midl)
  @@plass_i_minnet:
        mov     di, OFFSET (linseg).text ; Til 0'te tegn i dette linjesegmentet
  @@neste_tegn:
        push    ds
        mov     ds, dx          ; Til tekstlinjen (DX er det ES var ved kallet)
        cld
        lodsb
        pop     ds
        stosb
        or      al, al          ; Var dette siste byten? (0 -byten)
        je      @@ret_OK
        cmp     di, OFFSET (linseg).text + BPLS ; Er det mer plass i segmentet?
        jb      @@neste_tegn
        mov     di, es          ; "Husk" innholdet i ES
        mov     ax, LINSEGSIZ
        call    getmem
        or      ax, ax
        jz      @@ikke_plass
        push    ds
        mov     ds, di          ; Peker til forrige linjesegment
        mov     [(linseg PTR 0).next], es
        pop     ds
        jmp     SHORT @@plass_i_minnet

  @@ret_OK:
        mov     [es: (linseg PTR 0).next], 0
        mov     ax, bp          ; Inneholdt midlertidig riktig segmentadresse
        clc                     ; Indikerer OK

  @@ret:
        pop     es
        pop     di
        pop     si
        pop     bp
        pop     dx
        ret
ENDP    allocline



;
; setline
;
; Hva prosedyren gjõr:
;   Setter nytt innhold i en eksisterende linje. Det tidligere innholdet
;   frigis fõr det allokeres plass til det nye.
;
;   OBS OBS
;   Linjen strippes, og blir derved muligens endret fõr den legges inn.
;
; Kall med:
;   AX    - nummeret pÜ õnsket linje
;   ES:DI - peker til ny ASCIIZ-linje
;
; Returnerer:
;   Carry: clear - OK
;          set   - Feil
;
; Endrer innholdet i:
;   Ingenting
;
PROC    setline
        push    ax
        push    bx
        push    cx
        push    dx

        cmp     [nostrip], 0
        jnz     @@ikke_strippet

    ; Linjen skal strippes, og hvis lengden endres, skal blokkpekere
    ; oppdateres.
        push    ax
        push    ds
        push    es
        pop     ds
        mov     dx, di
        call    strlen
        call    strip
        mov     bx, ax
        call    strlen
        pop     ds
        mov     dx, ax
        pop     ax
        cmp     dx, bx
        je      @@ikke_strippet
        mov     cx, ax
        call    blockcontract
  @@ikke_strippet:

        mov     bx, ax
        shl     bx, 1
        push    es
        mov     es, [linptr]
        mov     es, [es: bx]
        call    freeline
        pop     es

        call    allocline
        jc      @@ret

        push    es
        mov     es, [linptr]
        mov     [es: bx], ax
        pop     es

        clc

  @@ret:
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    setline



;
; insertline
;
; Hva prosedyren gjõr:
;   Setter inn en tom ny linje i linjepekerarrayen.
;   Viser evt feilmelding.
;
; Kall med:
;   AX - Nummeret den nye linjen fÜr. Flytter nÜvërende AX et hakk ned.
;
; Returnerer:
;   Carry : clear - OK
;           set - Feil.
;
; Endrer innholdet i:
;   Ingenting
;
PROC    insertline
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    si
        push    es

    ; Sjekk fõrst at det er plass til flere linjer
        mov     cx, [antlin]
        cmp     cx, MAXLIN
        jb      @@plass_i_linjetabell
        mov     dx, OFFSET outlins
        call    error
  @@ret_error:
        stc                     ; Indikerer feil
        jmp     SHORT @@ret

  @@plass_i_linjetabell:
        cmp     ax, [antlin]
        ja      @@ret_error

    ; Flytt linjepekerne utover slik at det blir plass til en ny linje
        mov     es, [linptr]    ; ES:0 peker til fõrste linjepeker
        sub     cx, ax          ; Antall linjer som skal flyttes i CX
        jcxz    @@ingen_flytting

        mov     di, [antlin]
        shl     di, 1           ; ES:DI peker dit siste linjepeker skal flyttes
        mov     si, di
        sub     si, 2           ; (DS):SI peker til siste linjepeker
        push    ds
        push    es
        pop     ds              ; ES=DS=segmentet til linjepekerne
        std
        rep     movsw
        pop     ds

  @@ingen_flytting:               ; ES peker fortsatt til linjepekerne
    ; Legg inn en 0 for Ü indikere at linjen er tom.
        mov     di, ax
        shl     di, 1
        mov     [WORD es: di], 0

        inc     [WORD antlin]

    ; Oppdater posisjonspekere
        xor     bx, bx
        mov     cx, ax
        inc     cx
        xor     dx, dx
        call    blockexpand

        clc                     ; Indikerer OK

  @@ret:
        pop     es
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    insertline



;
; splitline
;
; Hva prosedyren gjõr:
;   Setter inn et linjeskift pÜ angitt posisjon.
;
; Kall med:
;   AX - linjenummer
;   BX - kolonnenummer
;
; Returnerer:
;   Carry: clear - OK
;          set   - Feil
;
; Endrer innholdet i:
;   wrklin
;
PROC    splitline
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    si
        push    es

    ; Lag plass til linjen
        inc     ax
        mov     cl, [blockmv]
        mov     [blockmv], 0
        call    insertline
        jc      @@ret
        mov     [blockmv], cl
        dec     ax

    ; Hent linjen som skal splittes inn i hjelpelinjen
        call    getwrklin

    ; Finn starten pÜ det som skal ned pÜ neste linje
        mov     di, bx          ; Kolonnen linjen skal splittes pÜ
        cmp     di, [wrklen]
        jb      @@ikke_forbi_slutt
        mov     di, [wrklen]
  @@ikke_forbi_slutt:
        add     di, OFFSET wrklin
    ; Her peker di inn i wrklin, enten pÜ linjeslutt, eller pÜ
    ; õnsket tegn.

    ; Sett av minne til den delen av linjen som skal flyttes ned
        mov     cx, ax          ; Spar linjenummeret i CX
        push    ds
        pop     es
        call    allocline       ; Alloker minne og del linjen i segmenter
        jc      @@ret

    ; Sett pekeren til den nye linjen inn i linjetabellen pÜ den
    ; plassen som ble ryddet over.
        mov     es, [linptr]
        mov     si, cx          ; Linjenummeret
        inc     si
        shl     si, 1
        mov     [es: si], ax
        mov     ax, cx          ; AX er igjen lik linjenummeret

    ; Oppdater posisjonspekere. AX og BX er forsatt start -linje og -kolonne.
        mov     cx, ax
        inc     cx
        xor     dx, dx
        call    blockexpand

    ; Kutt linjen som skal splittes
        push    ds
        pop     es
        mov     [BYTE di], 0    ; Sett inn linjesluttmerke
        mov     di, OFFSET wrklin
        call    setline
        jc      @@ret

  @@ret_OK:
        clc                     ; Indikerer OK

  @@ret:
        pop     es
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    splitline



;
; insertinline
;
; Hva prosedyren gjõr:
;   Setter tekst inn i angitt linje pÜ angitt posisjon.
;   Viser riktig feilmelding hvis noe gÜr galt.
;   Hvis linjen blir for lang, avkortes den, og en melding gis til brukeren.
;
; Kall med:
;   ES:DI - peker til linjen teksten som skal settes inn
;   AX    - linjenummeret
;   BX    - kolonnenummeret
;
; Returnerer:
;   Carry: clear - OK
;          set   - Feil, ikke mer plass. Denne gis ikke hvis det
;                  er linjen som er full!
;
; Endrer innholdet i:
;   wrklin
;
PROC    insertinline
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    si
        push    es

    ; Hent õnsket linje inn i hjelpelinjen for endring
        call    getwrklin

    ; Hvis angitt kolonne er forbi slutten pÜ linjen, skal linjen
    ; utvides med riktig antall blanke.
        cmp     bx, [wrklen]
        jbe     @@ikke_fyll_ut

        push    ax
        push    di
        push    es

        mov     cx, bx
        sub     cx, [wrklen]
        push    ds
        pop     es
        mov     di, OFFSET wrklin
        add     di, [wrklen]
        add     [wrklen], cx
        mov     al, ' '
        cld
        rep     stosb
        xor     al, al
        stosb

        pop     es
        pop     di
        pop     ax
  @@ikke_fyll_ut:

    ; Finn lengden pÜ teksten som skal settes inn
        push    ax
        push    ds
        push    es
        pop     ds
        mov     dx, di
        call    strlen
        mov     cx, ax  ; Lengden i CX
        pop     ds
        pop     ax

    ; Sjekk om lengdesummen er innenfor grensen av en linje.
        mov     dx, cx
        add     dx, [wrklen]
        cmp     dx, MAXLEN
        jbe     @@make_space

    ; Linjen blir for lang. Gi melding om dette, og juster CX slik at
    ; passe antall flyttes/kopieres.
        mov     dx, OFFSET trnclin
        call    error
        mov     dx, bx          ; Startposisjon pÜ teksten som skal settes inn
        add     dx, cx
        cmp     dx, MAXLEN
        jbe     @@make_space
        sub     dx, MAXLEN
        sub     cx, dx

  @@make_space:
    ; Forskyv tegn i nÜvërende linje CX plasser
        push    cx
        push    di
        push    es

        push    ds
        pop     es

        mov     si, [wrklen]
        mov     di, si
        add     di, cx
        mov     cx, [wrklen]
        sub     cx, bx
        inc     cx
        cmp     di, MAXLEN
        jbe     @@inside_lin

    ; Har funnet ut at tegn vil bli flyttet lenger enn lovlig. Finn ut
    ; hvor mye som er overskytende, og trekk fra dette.
        mov     dx, di
        sub     dx, MAXLEN
        sub     si, dx
        sub     di, dx
        sub     cx, dx

  @@inside_lin:
        add     si, OFFSET wrklin
        add     di, OFFSET wrklin

        std
        rep     movsb

    ; Legg in 0 pÜ slutten, for den er overskrevet hvis linjen var full.
        mov     [BYTE wrklin + MAXLEN], 0

        pop     es
        pop     di
        pop     cx

    ; Sett inn teksten i linjen
        push    cx
        push    di
        push    si
        push    ds

        mov     si, es
        push    ds
        pop     es
        mov     ds, si
        mov     si, di
        mov     di, OFFSET wrklin
        add     di, bx
        cld
        rep     movsb

        pop     ds
        pop     si
        pop     di
        pop     cx

    ; Sett linjen inn igjen.
        push    ds
        pop     es
        mov     di, OFFSET wrklin
        call    setline
        jc      @@ret

    ; Oppdater posisjonspekere. AX,BX peker fortsatt til starten,
    ; og cx har fortsatt den nye strengens lengde.
        mov     dx, cx
        add     dx, bx
        mov     cx, ax
        call    blockexpand

  @@ret_OK:
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
ENDP    insertinline



;
; splicelines
;
; Hva prosedyren gjõr:
;   Spleiser angitt linje med den neste
;
; Kall med:
;   AX - linjenummer
;   BX - kolonnenummer. Hvis dette ikke er bak linjens slutt, settes
;        det lik linjens slutt.
;
; Returnerer:
;   Carry: clear - OK
;          set   - Feil
;
; Endrer innholdet i:
;   wrklin, wrklin2
;
PROC    splicelines
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    es

    ; MÜ fõrst finne lengden pÜ angitt linje. Dette gjõres ved Ü
    ; lese den inn i den fõrste hjelpelinjen.
        call    getwrklin

        cmp     bx, [wrklen]
        jae     @@etter_slutten
        mov     bx, [wrklen]
  @@etter_slutten:

    ; Flytt posisjonspekere
        push    ax
        push    bx
        mov     cx, ax
        mov     dx, bx
        inc     ax
        xor     bx, bx
        call    blockcontract
        pop     bx
        pop     ax

    ; SlÜ av videre posisjonsoppdatering.
        mov     cl, [blockmv]
        mov     [blockmv], 0

    ; Hent linjen som skal trekkes opp inn i den andre hjelpelinjen
        inc     ax
        call    getwrklin2

    ; Fjern linjen under
        call    removeline
        dec     ax

    ; Sett inn teksten fra denne linjen pÜ slutten av angitt linje.
        push    ds
        pop     es
        mov     di, OFFSET wrklin2
        call    insertinline

    ; Resett posisjonsoppdatering
        mov     [blockmv], cl

  @@ret:
        pop     es
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    splicelines



;
; removefromline
;
; Hva prosedyren gjõr:
;   Fjerner angitt antall tegn fra angitt linje og kolonne
;   Viser riktig feilmelding hvis noe gÜr galt.
;   Fjerningen skjer bare innenfor en linje. Hvis flere tegn
;   enn ut til linjeslutt angis, slettes bare til linjeslutt.
;   Ingen linjer fjernes eller legges til.
;
; Kall med:
;   AX - linjenummeret
;   BX - kolonnenummeret
;   CX - antall tegn som skal fjernes
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   wrklin
;
PROC    removefromline
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    si
        push    es

    ; Hent õnsket linje inn i hjelpelinjen for endring
        call    getwrklin

    ; Hvis angitt kolonne er forbi slutten pÜ linjen, skal ingenting skje
        cmp     bx, [wrklen]
        jae     @@ret

    ; Sjekk om angitt antall er for stort.
        mov     dx, bx
        add     dx, cx
        cmp     dx, [wrklen]
        jbe     @@antall_ok

    ; Antallet er for stort. Korriger sÜ det blir riktig.
        sub     dx, [wrklen]
        sub     cx, dx

  @@antall_ok:
    ; Oppdater posisjonspekere. AX,BX peker fortsatt til starten,
    ; og CX har fortsatt riktig antall.
        push    bx
        push    cx
        mov     dx, bx
        add     bx, cx
        mov     cx, ax
        call    blockcontract
        pop     cx
        pop     bx

    ; Forskyv tegn i nÜvërende linje angitt antall plasser til venstre,
    ; fra angitt posisjon + angitt antall
        push    ds
        pop     es

        mov     di, OFFSET wrklin
        add     di, bx
        mov     si, cx
        mov     cx, [wrklen]
        sub     cx, bx
        add     si, di
        cld
        rep     movsb

    ; Sett linjen inn igjen.
        mov     di, OFFSET wrklin
        call    setline

  @@ret:
        pop     es
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    removefromline



;
; appendline
;
; Hva prosedyren gjõr:
;   Legger til linje pÜ slutten
;
; Kall med:
;   ES:DI - peker til linjen (ASCIIZ)
;
; Returnerer:
;   Carry: clear - OK
;          set   - Feil
;
; Endrer innholdet i:
;   Ingenting
;
PROC    appendline
        push    ax

    ; Legg til tom linje pÜ slutten
        mov     ax, [antlin]
        call    insertline
        jc      @@ret

    ; Sett inn den nye teksten. AX har den nye linjens nummer
        call    setline         ; Carry blir satt riktig av setline

  @@ret:
        pop     ax
        ret
ENDP    appendline



;
; removeline
;
; Hva prosedyren gjõr:
;   Fjerner linjen med angitt nummer.
;
; Kall med:
;   AX : Linjenummeret
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    removeline
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    si
        push    es

        mov     cx, [antlin]
        cmp     ax, cx          ; Sjekk om lovlig linjenummer
        jae     @@ret

        mov     bx, ax
        shl     bx, 1
        mov     es, [linptr]    ; ES:0 peker til fõrste linjepeker
        push    es
        mov     es, [es: bx]
        call    freeline
        pop     es
        mov     [WORD es: bx], 0
        sub     cx, ax
        dec     cx              ; Antall linjer som skal flyttes i CX
        jcxz    @@ingen_flytting
        mov     di, ax
        shl     di, 1           ; ES:DI peker dit siste linjepeker skal flyttes
        mov     si, di
        add     si, 2           ; (DS):SI peker til siste linjepeker
        push    ds
        push    es
        pop     ds              ; ES=DS=segmentet til linjepekerne
        cld
        rep     movsw
        pop     ds

    ; Oppdater posisjonspekere
        mov     cx, ax
        inc     ax
        xor     bx, bx
        xor     dx, dx
        call    blockcontract

  @@ingen_flytting:
        dec     [WORD antlin]

  @@ret:
        pop     es
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    removeline



;
; newfile
;
; Hva prosedyren gjõr:
;   Fjerner alle linjer, og nullstiller variabler.
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
PROC    newfile
        push    ax
        push    bx
        push    cx
        push    es

        mov     cx, [antlin]
        jcxz    @@ret
        xor     bx, bx  ; Peker til startsegment til gjeldende linje

  @@next_line:
    ; Finn segmentet til starten pÜ neste linje
        mov     es, [linptr]
        mov     es, [es: bx]
        inc     bx
        inc     bx

  @@next_line_segment:
        mov     ax, es
        or      ax, ax          ; Er linjen tom?
        jz      @@loop_next
        mov     ax, [es: (linseg PTR 0).next]
        push    ax
        mov     ax, LINSEGPARA
        call    freemem
        pop     es
        jmp     SHORT @@next_line_segment

  @@loop_next:
        loop    @@next_line

    ; Alle linjene er nÜ borte. Nullstill linjetelleren
        mov     [antlin], 0

    ; Nullstill ogsÜ info til bruk for editoren
        call    reset_ed

  @@ret:
        pop     es
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    newfile





ENDS

        END
