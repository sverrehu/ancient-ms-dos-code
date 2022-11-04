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

        EXTRN   nostrip: BYTE
        EXTRN   wrklin: PTR, wrklen: WORD
        EXTRN   xlin: PTR

        PUBLIC  blockon, blockmv
        PUBLIC  blklin1, blkcol1, blklin2, blkcol2
        PUBLIC  poslin1, poscol1, poslin2, poscol2
        PUBLIC  syslin, syscol


blockon DB      ?       ; Skal blokken vises ?
blockmv DB      ?       ; Skal blokkpekere kunne oppdateres ?
blkofs  DW      ?       ; Brukes av nextblockline for � finne ut hvor
                        ; langt vi har kommet.

blklin1 DW      ?       ; Blokkmark�rens start-linjenummer
blkcol1 DW      ?       ; Blokkmark�rens start-kolonnenummer
blklin2 DW      ?       ; Blokkmark�rens slutt-linjenummer
blkcol2 DW      ?       ; Blokkmark�rens slutt-kolonnenummer

  ; Midlertidig blokkmark�r
tblkln1 DW      ?
tblkcl1 DW      ?
tblkln2 DW      ?
tblkcl2 DW      ?

  ; Det skal v�re 2 posisjonsmark�rer
poslin1 DW      ?       ; 1. posisjonsmark�rs linjenummer
poscol1 DW      ?       ; 1. posisjonsmark�rs kolonnenummer
poslin2 DW      ?       ; 2. posisjonsmark�rs linjenummer
poscol2 DW      ?       ; 2. posisjonsmark�rs kolonnenummer

  ; Posisjonspekere som brukes av EDIT.ASM for � holde styr p�
  ; current posisjon.
syslin  DW      ?
syscol  DW      ?





;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG
        EXTRN   strlen: PROC

        EXTRN   beep: PROC
        EXTRN   insertline: PROC, insertinline: PROC
        EXTRN   removeline: PROC, removefromline: PROC
        EXTRN   splitline: PROC, splicelines: PROC
        EXTRN   getwrklin: PROC, getline: PROC
        EXTRN   openreadfile: PROC, readline: PROC, closereadfile: PROC
        EXTRN   openwritefile: PROC, writeline: PROC, closewritefile: PROC

        PUBLIC  initblock, endblock, resetblock, inblock
        PUBLIC  blockcontract, blockexpand
        PUBLIC  deleteblock, copyblock, moveblock
        PUBLIC  firstblockline, nextblockline
        PUBLIC  readblock, writeblock
        PUBLIC  indentblock, unindentblock



;
; initblock
;
; Hva prosedyren gj�r:
;   Initierer alt som har med blokkh�ndtering � gj�re
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
PROC    initblock
        call    resetblock
        ret
ENDP    initblock



;
; endblock
;
; Hva prosedyren gj�r:
;   Avslutter alt som har med blokk � gj�re
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
PROC    endblock
        call    resetblock
        ret
ENDP    endblock



;
; resetblock
;
; Hva prosedyren gj�r:
;   Nullstiller alle variabler som har med blokkh�ndtering � gj�re
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
PROC    resetblock
        push    ax
        xor     ax, ax
        mov     [blockon], al
        mov     [blklin1], ax
        mov     [blkcol1], ax
        mov     [blklin2], ax
        mov     [blkcol2], ax
        mov     [poslin1], ax
        mov     [poscol1], ax
        mov     [poslin2], ax
        mov     [poscol2], ax
        mov     [syslin], ax
        mov     [syscol], ax
        mov     [blockmv], 1
        pop     ax
        ret
ENDP    resetblock



;
; inblock
;
; Hva prosedyren gj�r:
;   Finner ut om angitt posisjon er innenfor blokkgrensene.
;   Hvis blokken ikke vises, er ingen posisjon innenfor blokk-
;   grensene uansett.
;
; Kall med:
;   AX : Linjenummeret
;   DX : Kolonnenummeret
;
; Returnerer:
;   CF : 0 - Ikke i blokk
;        1 - I blokk
;
; Endrer innholdet i:
;   Ingenting
;
PROC    inblock
        cmp     [blockon], 0
        jnz     @@block_is_on

  @@ret_ikke:
        clc
        ret

  @@block_is_on:
        cmp     ax, [blklin1]   ; Er vi f�r f�rste blokklinje ?
        jb      @@ret_ikke

        cmp     ax, [blklin2]   ; Er vi etter siste blokklinje ?
        ja      @@ret_ikke

    ; Her er vi p� en linje som enten er f�rste eller siste eller midt i
    ; blokken. (Eller alle tre, hvis blokken bare er p� en linje.)
        cmp     ax, [blklin1]   ; Er vi p� f�rste blokklinje ?
        ja      @@ikke_forste_lin

    ; Her er vi p� f�rste linje i blokken.
        cmp     dx, [blkcol1]   ; Er vi f�r f�rste blokkolonne ?
        jb      @@ret_ikke

  @@ikke_forste_lin:
  @@sjekk_om_siste_linje:
        cmp     ax, [blklin2]   ; Er vi p� siste blokklinje ?
        jb      @@ret_i

        cmp     dx, [blkcol2]   ; Er vi etter siste blokkolonne ?
    ; Blokksluttmerket st�r ETTER siste tegn i blokken.
        jae     @@ret_ikke

  @@ret_i:
        stc
    ; OBS Dette er ikke eneste utgangspunktet av prosedyren!
        ret
ENDP    inblock



;
; blockexpand_1
;
; Hva prosedyren gj�r:
;   Intern prosedyre som utf�rer blockexpand p� en posisjonspeker.
;   Kalles av blockexpand for hver posisjonspeker.
;
; Kall med:
;   AX, BX, CX, DX som for blockexpand
;   SI - posisjonspeker, linje
;   DI - posisjonspeker, kolonne
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   SI, DI
;
PROC    blockexpand_1

    ; Sjekk om oppdatering i det hele tatt er n�dvendig. Det er det ikke
    ; hvis pekeren er f�r eller lik angitt start.
        cmp     si, ax
        jb      @@ret
        ja      @@after_start
        cmp     di, bx
        jbe     @@ret

  @@after_start:
    ; Pekeren er etter eller p� angitt start. Hvis pekeren ikke ligger
    ; p� start- eller sluttlinjen, skal ikke kolonnen oppdateres.
        cmp     si, ax
        je      @@on_startline
        cmp     si, cx
        jne     @@add_linediff

  @@on_endline:
    ; Legg til avtsanden fra kanten (sluttkolonnen)
        add     di, dx
        jmp     SHORT @@add_linediff

  @@on_startline:
    ; Legg til kolonnedifferansen
        sub     di, bx
        add     di, dx

  @@add_linediff:
    ; Legg til linjedifferansen.
        sub     si, ax
        add     si, cx

  @@ret:
        ret
ENDP    blockexpand_1



;
; blockexpand
;
; Hva prosedyren gj�r:
;   Oppdaterer alle posisjonspekere avhengig av opplysningen om
;   at teksten er utvidet.
;
; Kall med:
;   AX - Fralinjenummer
;   BX - Frakolonnenummer
;   CX - Tillinjenummer
;   DX - Tilkolonnenummer
;
;   Tegnet som befant seg p� (AX,BX) er flyttet ut til (CX,DX).
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    blockexpand
        push    di
        push    si

    ; Sjekk om posisjonsoppdatering er mulig
        cmp     [blockmv], 0
        jnz     @@update
        jmp     @@ret

  @@update:
    ; Oppdater blokkstart-pekeren
        mov     si, [blklin1]
        mov     di, [blkcol1]
        call    blockexpand_1
        mov     [blklin1], si
        mov     [blkcol1], di

    ; Oppdater blokkslutt-pekeren
        mov     si, [blklin2]
        mov     di, [blkcol2]
        call    blockexpand_1
        mov     [blklin2], si
        mov     [blkcol2], di

    ; Oppdater midlertidig blokkstart
        mov     si, [tblkln1]
        mov     di, [tblkcl1]
        call    blockexpand_1
        mov     [tblkln1], si
        mov     [tblkcl1], di

    ; Oppdater midlertidig blokkslutt
        mov     si, [tblkln2]
        mov     di, [tblkcl2]
        call    blockexpand_1
        mov     [tblkln2], si
        mov     [tblkcl2], di

    ; Oppdater 1. posisjonsmark�r
        mov     si, [poslin1]
        mov     di, [poscol1]
        call    blockexpand_1
        mov     [poslin1], si
        mov     [poscol1], di

    ; Oppdater 2. posisjonsmark�r
        mov     si, [poslin2]
        mov     di, [poscol2]
        call    blockexpand_1
        mov     [poslin2], si
        mov     [poscol2], di

    ; Oppdater systempekeren
        mov     si, [syslin]
        mov     di, [syscol]
        call    blockexpand_1
        mov     [syslin], si
        mov     [syscol], di

  @@ret:
        pop     si
        pop     di

        ret
ENDP    blockexpand



;
; blockcontract_1
;
; Hva prosedyren gj�r:
;   Intern prosedyre som utf�rer blockcontract p� en posisjonspeker.
;   Kalles av blockcontract for hver posisjonspeker.
;
; Kall med:
;   AX, BX, CX, DX som for blockcontract
;   SI - posisjonspeker, linje
;   DI - posisjonspeker, kolonne
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   SI, DI
;
PROC    blockcontract_1

    ; Sjekk om oppdatering i det hele tatt er n�dvendig. Det er det ikke
    ; hvis pekeren er f�r eller lik angitt slutt (den f�rste posisjonen).
        cmp     si, cx
        jb      @@ret
        ja      @@after_start
        cmp     di, dx
        jbe     @@ret

  @@after_start:
    ; Pekeren er etter eller p� angitt slutt. Hvis pekeren er innenfor
    ; omr�det som er fjernet, skal den settes lik slutten.
        cmp     si, ax
        jb      @@innenfor
        ja      @@utenfor
        cmp     di, bx
        jae     @@utenfor

  @@innenfor:
    ; Pekeren er innenfor angitt omr�de. Sett den lik slutten p� dette.
        mov     si, cx
        mov     di, dx
        jmp     SHORT @@ret

  @@utenfor:
    ; Hvis pekeren er p� linjen som trekkes opp, skal kolonnen justeres.
        cmp     si, ax
        jne     @@sub_linediff

        sub     di, bx
        add     di, dx

  @@sub_linediff:
    ; Trekk fra linjedifferansen.
        sub     si, ax
        add     si, cx

  @@ret:
        ret
ENDP    blockcontract_1



;
; blockcontract
;
; Hva prosedyren gj�r:
;   Oppdaterer alle posisjonspekere avhengig av opplysningen om
;   at teksten er utvidet.
;
; Kall med:
;   AX - Fralinjenummer
;   BX - Frakolonnenummer
;   CX - Tillinjenummer
;   DX - Tilkolonnenummer
;
;   Tegnet som befant seg p� (AX,BX) er trukket opp til (CX,DX).
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    blockcontract
        push    di
        push    si

    ; Sjekk om blokkoppdatering er mulig
        cmp     [blockmv], 0
        jnz     @@update
        jmp     @@ret

  @@update:
    ; Oppdater blokkstart-pekeren
        mov     si, [blklin1]
        mov     di, [blkcol1]
        call    blockcontract_1
        mov     [blklin1], si
        mov     [blkcol1], di

    ; Oppdater blokkslutt-pekeren
        mov     si, [blklin2]
        mov     di, [blkcol2]
        call    blockcontract_1
        mov     [blklin2], si
        mov     [blkcol2], di

    ; Oppdater midlertidig blokkstart
        mov     si, [tblkln1]
        mov     di, [tblkcl1]
        call    blockcontract_1
        mov     [tblkln1], si
        mov     [tblkcl1], di

    ; Oppdater midlertidig blokkslutt
        mov     si, [tblkln2]
        mov     di, [tblkcl2]
        call    blockcontract_1
        mov     [tblkln2], si
        mov     [tblkcl2], di

    ; Oppdater 1. posisjonsmark�r
        mov     si, [poslin1]
        mov     di, [poscol1]
        call    blockcontract_1
        mov     [poslin1], si
        mov     [poscol1], di

    ; Oppdater 2. posisjonsmark�r
        mov     si, [poslin2]
        mov     di, [poscol2]
        call    blockcontract_1
        mov     [poslin2], si
        mov     [poscol2], di

    ; Oppdater systempekeren
        mov     si, [syslin]
        mov     di, [syscol]
        call    blockcontract_1
        mov     [syslin], si
        mov     [syscol], di

  @@ret:
        pop     si
        pop     di

        ret
ENDP    blockcontract



;
; firstblockline
;
; Hva prosedyren gj�r:
;   Finner, hvis mulig, f�rste blokklinje og legger den markerte delen
;   av denne inn i angitt tekstbuffer.
;
; Kall med:
;   DS:DX - Omr�de teksten skal legges.
;
; Returnerer:
;   Carry : clear - linjen ble funnet.
;           set   - linjen ble ikke funnet. Blokken er enten ikke synlig,
;                   eller blockstart er etter blockend.
;   AX    : 0 - linjen ender ikke i newline. (siste i blokken)
;           1 - linjen ender i newline. Kan allikevel v�re siste i blokken.
;
; Endrer innholdet i:
;   AX, wrklin
;
PROC    firstblockline
        push    bx
        push    cx
        push    di
        push    si
        push    es

    ; Nullstill tilleggstallet fra blokkstart, s� nextblockline
    ; kan kalles siden
        mov     [blkofs], 0

    ; Sett opp registre som brukes flere steder
        push    ds
        pop     es
        mov     di, dx                  ; ES:DI til angitt linje
        mov     si, OFFSET wrklin       ; DS:SI til wrklin
        mov     bx, [blkcol1]

    ; Sjekk om blokken er p�
        cmp     [blockon], 0
        jz      @@ret_nothing

    ; Sjekk om blokkstart er f�r blokkslutt
        mov     ax, [blklin1]
        cmp     ax, [blklin2]
        ja      @@ret_nothing
        jb      @@several_lines

    ; Her er muligens blokken p� �n linje. Sjekk kolonnene.
        cmp     bx, [blkcol2]
        jb      @@one_line

  @@ret_nothing:
    ; Det er ikke noe � hente. Marker dette, og avslutt.
        stc
        jmp     SHORT @@ret

  @@one_line:
    ; Blokken best�r av en del av en linje. Hent ut denne.
        call    getwrklin

    ; Kopier over den delen av linjen som er markert.
        mov     cx, [blkcol2]
        sub     cx, bx          ; Trekk fra starten
        add     si, bx
        cld
        rep     movsb

    ; Marker at linjen ikke slutter med linjeskift, og legg inn en nullbyte
        xor     ax, ax
        stosb

    ; Marker at noe er funnet, og hopp ut.
        clc
        jmp     SHORT @@ret

  @@several_lines:
    ; Blokken g�r over flere linjer. Hent den f�rste av disse.
        call    getwrklin

    ; Kopier fra blkcol1 og ut linjen over i angitt tekstlinje
        mov     cx, [wrklen]
        sub     cx, bx          ; Trekk fra starten
        inc     cx              ; og legg til 1 for � f� med 0-byten.
        add     si, bx
        cld
        rep     movsb

    ; Marker at linjen slutter med linjeskift
        mov     ax, 1

    ; Marker at noe er funnet, og avslutt.
        clc

  @@ret:
        pop     es
        pop     si
        pop     di
        pop     cx
        pop     bx
        ret
ENDP    firstblockline



;
; nextblockline
;
; Hva prosedyren gj�r:
;   Finner, hvis mulig, neste blokklinje og legger den markerte delen
;   av denne inn i angitt tekstbuffer.
;   firstblockline M� ha blitt kalt f�rst, og returnert med carry clear
;
; Kall med:
;   DS:DX - Omr�de teksten skal legges.
;
; Returnerer:
;   Carry : clear - linjen ble funnet.
;           set   - linjen ble ikke funnet. Det er ikke mer � hente.
;   AX    : 0 - linjen ender ikke i newline. (siste i blokken)
;           1 - linjen ender i newline. Kan allikevel v�re siste i blokken.
;
; Endrer innholdet i:
;   AX, wrklin
;
PROC    nextblockline
        push    cx
        push    di
        push    si
        push    es

    ; �k indeksen som viser hvor langt vi er fra blokkstart
        inc     [blkofs]

    ; Sett opp registre som brukes flere steder
        push    ds
        pop     es
        mov     di, dx                  ; ES:DI til angitt linje
        mov     si, OFFSET wrklin       ; DS:SI til wrklin
        mov     cx, [blkcol2]

    ; Sjekk om blokken er p�
        cmp     [blockon], 0
        jz      @@ret_nothing

    ; Sjekk om blokkstart  pluss n�v�rende linje er f�r blokkslutt
        mov     ax, [blklin1]
        add     ax, [blkofs]
        cmp     ax, [blklin2]
        ja      @@ret_nothing
        jb      @@several_lines

    ; Her har vi n�dd siste linje i blokken. Sjekk om kolonnen er
    ; helt til venstre. Is�fall skal ingenting returneres.
        or      cx, cx
        jnz     @@last_line

  @@ret_nothing:
    ; Det er ikke mer � hente. Marker dette, og avslutt.
        stc
        jmp     SHORT @@ret

  @@last_line:
    ; Hent ut den siste linjen.
        call    getwrklin

    ; Kopier over den delen av linjen som er markert. CX inneholder
    ; allerede blkcol2.
        cld
        rep     movsb

    ; Marker at linjen ikke slutter med linjeskift, og legg inn en nullbyte
        xor     ax, ax
        stosb

    ; Marker at noe er funnet, og hopp ut.
        clc
        jmp     SHORT @@ret

  @@several_lines:
    ; Det er flere linjer igjen. Hent den f�rste av disse. Denne
    ; kan hentes rett inn i angitt linjebuffer siden ingenting
    ; skal fjernes.
        call    getline         ; ES:DI peker til angitt linje

    ; Marker at linjen slutter med linjeskift
        mov     ax, 1

    ; Marker at noe er funnet, og avslutt.
        clc

  @@ret:
        pop     es
        pop     si
        pop     di
        pop     cx
        ret
ENDP    nextblockline



;
; deleteblock
;
; Hva prosedyren gj�r:
;   Fjerner markert blokk hvis den er synlig.
;   Oppdaterer ikke skjermen.
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
PROC    deleteblock
        push    ax
        push    bx
        push    cx
        push    dx

        cmp     [blockon], 0
        jz      @@ret

    ; F�rst sjekkes det spesialtilfellet at blokken er innenfor en linje.
    ; Er den det, slettes riktig del av linjen.
    ; Er den ikke det, slettes f�rst slutten av f�rste linje, deretter
    ; alle linjene mellom blokkmerkene, og til slutt begynnelsen av
    ; siste blokklinje. S� spleises disse linjene sammen.

        mov     ax, [blklin1]
        mov     bx, [blkcol1]

        cmp     ax, [blklin2]
        ja      @@ret           ; Blokkslutt f�r blokkstart
        jb      @@several_lines

    ; Her er merkene p� samme linje.
        cmp     bx, [blkcol2]
        jae     @@ret

        mov     cx, [blkcol2]
        sub     cx, bx

        call    removefromline

        jmp     SHORT @@ret

  @@several_lines:
    ; Her er merkene p� forskjellige linjer.

    ; Slett slutten av f�rste linje. Her er det viktig at ikke evt. blanke
    ; p� slutten av linjen strippes.
        mov     dl, [nostrip]
        mov     [nostrip], 1
        mov     cx, MAXLEN
        call    removefromline
        mov     [nostrip], dl

    ; Slett linjer helt til blokksluttlinjen ligger rett etter blokkstart.
        inc     ax

  @@delete_line:
        cmp     ax, [blklin2]
        je      @@found_end

        call    removeline      ; Oppdaterer blklin2 og andre
        jmp     @@delete_line

  @@found_end:
    ; Har funnet siste blokklinje. Fjern starten av denne
        xor     bx, bx          ; Slett fra start
        mov     cx, [blkcol2]
        call    removefromline

    ; Sl� sammen f�rste og siste blokklinje.
        dec     ax
        call    splicelines

  @@ret:
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    deleteblock



;
; indentblock
;
; Hva prosedyren gj�r:
;   Legger inn en blank p� begynnelsen av hver linje i blokken.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   xlin
;
PROC    indentblock
        push    ax
        push    bx
        push    di
        push    es

        cmp     [blockon], 0
        jz      @@ret

    ; Sett opp xlin til � inneholde et blank tegn, og sett ES:DI til
    ; � peke til linjen, siden det er det som brukes av insertinline.
        push    ds
        pop     es
        mov     di, OFFSET xlin
        mov     [WORD di], ' ' + 0 * 256        ; Blank og nullbyte

        mov     ax, [blklin1]
        mov     bx, [blkcol1]

  @@indent_line:
    ; Lag innrykk p� n�v�rende linje. Hvis dette er siste linje, og
    ; blkcol2 er p� starten av linjen, skal ikke noe gj�res
        cmp     ax, [blklin2]
        ja      @@ret           ; Blokkslutt n�dd.
        jb      @@insert_space

    ; Her er vi p� siste linje.
        cmp     bx, [blkcol2]
        jae     @@ret

  @@insert_space:
    ; Sett inn et blankt tegn p� BX'te posisjon.
        call    insertinline

    ; Nullstill BX, for det er bare p� f�rste blokklinje at det
    ; blanke tegnet skal settes inn etter linjestart.
        xor     bx, bx

    ; G� til neste linje, og pr�v igjen.
        inc     ax
        jmp     @@indent_line

  @@ret:
        pop     es
        pop     di
        pop     bx
        pop     ax
        ret
ENDP    indentblock



;
; unindentblock
;
; Hva prosedyren gj�r:
;   Fjerner en blank fra begynnelsen av hver linje i blokken hvis dette
;   finnes.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   wrklin
;
PROC    unindentblock
        push    ax
        push    bx
        push    cx

        cmp     [blockon], 0
        jz      @@ret

    ; Det er alltid 1 tegn som skal fjernes hvis noe f�rst skal vekk.
        mov     cx, 1

        mov     ax, [blklin1]
        mov     bx, [blkcol1]

  @@unindent_line:
    ; Lag innrykk p� n�v�rende linje. Hvis dette er siste linje, og
    ; blkcol2 er p� starten av linjen, skal ikke noe gj�res
        cmp     ax, [blklin2]
        ja      @@ret           ; Blokkslutt n�dd.
        jb      @@remove_space

    ; Her er vi p� siste linje.
        cmp     bx, [blkcol2]
        jae     @@ret

  @@remove_space:
    ; Hent linjen inn i wrklin for � finne ut om det er et blankt tegn
    ; f�rst i blokken.
        call    getwrklin

    ; Sjekk om tegnet er blankt
        cmp     [BYTE wrklin + bx], ' '
        jne     @@advance_line

    ; Sett inn et blankt tegn p� BX'te posisjon.
        call    removefromline

  @@advance_line:
    ; Nullstill BX, for det er bare p� f�rste blokklinje at det
    ; blanke tegnet skal fjernes etter linjestart.
        xor     bx, bx

    ; G� til neste linje, og pr�v igjen.
        inc     ax
        jmp     @@unindent_line

  @@ret:
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    unindentblock



;
; readblock
;
; Hva prosedyren gj�r:
;   Leser ny blokk fra angitt fil.
;
; Kall med:
;   AX    - linjen blokken skal leses inn p�
;   BX    - kolonnen blokken skal leses inn p�
;   DS:DX - filnavn
;
; Returnerer:
;   Carry : clear - OK
;           set   - Feil under skriving
;
; Endrer innholdet i:
;   xlin
;
PROC    readblock
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    es

    ; �pne filen for lesing
        call    openreadfile
        jc      @@ret

    ; Sett en tom blokk p� angitt posisjon, og sl� p� blokken. Det som
    ; leses vil senere settes inn her.
        mov     [blklin1], ax
        mov     [blkcol1], bx
        mov     [blklin2], ax
        mov     [blkcol2], bx
        mov     [blockon], 1

    ; Kolonnen for blokkslutt m� settes en lenger til h�yre enn den
    ; egentlig skal v�re for at den skal bli flyttet utover n�r
    ; teksten settes inn. Dette justeres etterp�.
        inc     [blkcol2]

    ; Sett opp registre som brukes av readline
        mov     dx, OFFSET xlin

    ; og de som brukes av insertinline
        push    ds
        pop     es
        mov     di, dx

  @@read_next:
    ; Les en linje fra fil
        push    ax
        mov     cx, MAXLEN
        call    readline
    ; AX inneholder n� en boolsk variabel som angir om linjen sluttet
    ; med newline. Lagre denne i CX.
        mov     cx, ax
        pop     ax
        jc      @@close_file

    ; Legg inn linjen p� n�v�rende posisjon i n�v�rende linje
        call    insertinline
        jc      @@close_file

    ; Hvis linjen endte i newline skal linjeskift ogs� legges inn
    ; i teksten.
        jcxz    @@close_file

    ; Linjen skal splittes etter den innleste teksten. M� finne lengden
    ; p� denne.
        push    ax
        call    strlen
        add     bx, ax          ; Lengden p� innlest tekst
        pop     ax

    ; Splitt linjen p� riktig sted
        call    splitline
        jc      @@close_file

    ; �k linjeteller, og nullstill kolonneteller. Det er bare p� f�rste
    ; linje at noe kan leses inn etter linjestart.
        inc     ax
        xor     bx, bx

    ; Les inn neste linje fra filen
        jmp     @@read_next

  @@close_file:
    ; Lukk filen
        call    closereadfile
        jc      @@ret

    ; Juster sluttkolonnen til blokken. Se over.
        cmp     [blkcol2], 0
        jz      @@ret_ok
        dec     [blkcol2]

  @@ret_ok:
    ; Marker at ikke filfeil.
        clc

  @@ret:
        pop     es
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    readblock



;
; writeblock
;
; Hva prosedyren gj�r:
;   Lagrer blokken i angitt fil.
;
; Kall med:
;   DS:DX - filnavn
;
; Returnerer:
;   Carry : clear - OK
;           set   - Feil under skriving
;
; Endrer innholdet i:
;   xlin
;
PROC    writeblock
        push    ax
        push    dx

    ; �pne filen for skriving
        call    openwritefile
        jc      @@ret

    ; Sett opp registre som brukes av first/next-blockline
        mov     dx, OFFSET xlin

    ; Finn f�rste blokklinje
        call    firstblockline
        jc      @@ret_ok        ; Ingen blokk funnet.

  @@next_line:
    ; Skriv linjen til fil. AX settes som �nskelig av first/next-blockline
        call    writeline
        jc      @@close_file

    ; Finn neste linje hvis det er noen
        call    nextblockline
        jnc     @@next_line

  @@close_file:
    ; Lukk filen
        call    closewritefile
        jc      @@ret

  @@ret_ok:
    ; Marker at ikke filfeil.
        clc

  @@ret:
        pop     dx
        pop     ax
        ret
ENDP    writeblock



;
; copyblock
;
; Hva prosedyren gj�r:
;   Kopierer blokken til angitt omr�de hvis den er p�.
;
; Kall med:
;   AX    - linjen blokken skal settes inn p�
;   BX    - kolonnen blokken skal settes inn p�
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   xlin
;
PROC    copyblock
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    es

    ; Sjekk f�rst om angitt posisjon er inne i blokken. Da har det ingen
    ; mening � utf�re flyttingen.
        mov     dx, bx
        call    inblock
        jnc     @@not_in_block

    ; Lag pipetone og hopp ut.
        call    beep
        jmp     SHORT @@ret

  @@not_in_block:
    ; Under kopiering av blokk, endres ikke innsettingsposisjonen som
    ; bieffekt av noe annet. Kan derfor la (AX,BX) peke direkte til
    ; innsettingsstedet uten � la dem v�re offset fra noe som
    ; endres av blockexpand/contract.

    ; Sett midlertidige blokkpekere p� angitt posisjon, slik at det senere
    ; blir lett � finne de nye blokkoordinatene.
        mov     [tblkln1], ax
        mov     [tblkcl1], bx
        mov     [tblkln2], ax
        mov     [tblkcl2], bx

    ; Kolonnen for blokkslutt m� settes en lenger til h�yre enn den
    ; egentlig skal v�re for at den skal bli flyttet utover n�r
    ; teksten settes inn. Dette justeres etterp�.
        inc     [tblkcl2]

    ; Sett opp registre som brukes av first/next-blockline
        mov     dx, OFFSET xlin

    ; og de som brukes av insertinline
        push    ds
        pop     es
        mov     di, dx

    ; Finn f�rste blokklinje
        push    ax
        call    firstblockline

    ; AX inneholder n� en boolsk variabel som angir om linjen sluttet
    ; med newline. Lagre denne i CX.
        mov     cx, ax
        pop     ax
        jc      @@ret           ; Ingen blokk

  @@next_line:
    ; Legg inn linjen p� n�v�rende posisjon i n�v�rende linje
        call    insertinline
        jc      @@mark_new_block

    ; Hvis linjen endte i newline skal linjeskift ogs� legges inn
    ; i teksten.
        jcxz    @@mark_new_block

    ; Linjen skal splittes etter den innlagte teksten. M� finne lengden
    ; p� denne.
        push    ax
        call    strlen
        add     bx, ax          ; Lengden p� innlest tekst
        pop     ax

    ; Splitt linjen p� riktig sted
        call    splitline
        jc      @@mark_new_block

    ; �k linjeteller, og nullstill kolonneteller. Det er bare p� f�rste
    ; linje at noe kan leses inn etter linjestart.
        inc     ax
        xor     bx, bx

    ; Hent neste blokklinje
        push    ax
        call    nextblockline

    ; AX inneholder n� en boolsk variabel som angir om linjen sluttet
    ; med newline. Lagre denne i CX.
        mov     cx, ax
        pop     ax
        jnc     @@next_line

  @@mark_new_block:
    ; Juster sluttkolonnen til blokken. Se over.
        cmp     [tblkcl2], 0
        jz      @@mark_it
        dec     [tblkcl2]

  @@mark_it:
    ; Sett blokkpekere til den nye posisjonen.
        mov     ax, [tblkln1]
        mov     [blklin1], ax
        mov     ax, [tblkcl1]
        mov     [blkcol1], ax
        mov     ax, [tblkln2]
        mov     [blklin2], ax
        mov     ax, [tblkcl2]
        mov     [blkcol2], ax

  @@ret:
        pop     es
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    copyblock



;
; moveblock
;
; Hva prosedyren gj�r:
;   Flytter blokken til angitt omr�de hvis den er p�.
;
; Kall med:
;   AX    - linjen blokken skal settes inn p�
;   BX    - kolonnen blokken skal settes inn p�
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   xlin
;
PROC    moveblock
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    es

    ; Sjekk f�rst om angitt posisjon er inne i blokken. Da har det ingen
    ; mening � utf�re flyttingen.
        mov     dx, bx
        call    inblock
        jnc     @@not_in_block

    ; Lag pipetone og hopp ut.
        call    beep
        jmp     @@ret

  @@not_in_block:
    ; Under kopiering av blokk, endres innsettingsposisjonen som
    ; bieffekt av noe annet. Kan derfor ikke la (AX,BX) peke direkte til
    ; innsettingsstedet uten � la dem v�re offset fra noe som
    ; endres av blockexpand/contract.

    ; Sett midlertidige blokkpekere p� angitt posisjon, slik at det senere
    ; blir lett � finne de nye blokkoordinatene.
        mov     [tblkln1], ax
        mov     [tblkcl1], bx
        mov     [tblkln2], ax
        mov     [tblkcl2], bx

    ; Kolonnen for blokkslutt m� settes en lenger til h�yre enn den
    ; egentlig skal v�re for at den skal bli flyttet utover n�r
    ; teksten settes inn. Dette justeres etterp�.
        inc     [tblkcl2]

    ; Sett opp registre som brukes av first/next-blockline
        mov     dx, OFFSET xlin

    ; og de som brukes av insertinline
        push    ds
        pop     es
        mov     di, dx

    ; Finn f�rste blokklinje
        call    firstblockline
        jnc     @@block_exists
        jmp     @@ret           ; Ingen blokk

    ; AX inneholder n� en boolsk variabel som angir om linjen sluttet
    ; med newline.

  @@block_exists:
    ; Sjekk n� om linjen endte i newline. Hvis den gjorde det, er det
    ; flere linjer, og dette behandles spesielt.
        or      ax, ax
        jnz     @@several_lines

    ; Orginalblokken er innen en linje. Fjern blokken fra orginallinjen.
        mov     ax, [blklin1]
        mov     bx, [blkcol1]
        mov     cx, [blkcol2]
        sub     cx, bx
        call    removefromline

    ; Legg omr�det fra orginallinjen inn p� blokkposisjonen i
    ; den nye blokklinjen.
        mov     ax, [tblkln1]
        mov     bx, [tblkcl1]
        call    insertinline

        jmp     @@mark_new_block

  @@several_lines:
    ; Blokken best�r av mer enn en linje. Fjern f�rst slutten av
    ; orginallinjen. Her er det viktig at ikke evt. blanke
    ; p� slutten av linjen strippes.
        push    dx
        mov     dl, [nostrip]
        mov     [nostrip], 1
        mov     ax, [blklin1]
        mov     bx, [blkcol1]
        mov     cx, MAXLEN
        call    removefromline
        mov     [nostrip], dl
        pop     dx

    ; Legg inn linjen p� n�v�rende posisjon i n�v�rende linje
        mov     ax, [tblkln2]
        mov     bx, [tblkcl2]
        or      bx, bx
        jz      @@insert_first_line
        dec     bx
  @@insert_first_line:
        call    insertinline
        jc      @@mark_new_block

    ; Legg inn linjeskift, siden det her er klart at teksten best�r av
    ; flere linjer.
        push    ax
        call    strlen
        add     bx, ax          ; Lengden p� innlest tekst
        pop     ax

    ; Splitt linjen p� riktig sted
        call    splitline
        jc      @@mark_new_block

  @@next_line:
    ; Flytt n� hele linjer helt til siste orginallinje er n�dd. Det er
    ; alltid linjen etter blokkstart som skal hentes, siden linjene fjernes
    ; etterhvert. Sett derfor blkofs til 0, selv om det ikke er s�rlig pent!
        mov     [blkofs], 0     ; nextblockline �ker f�rst.
        call    nextblockline
        jnc     @@more_left

    ; Her er slutten n�dd, og den siste linjen endte i newline. Da skal
    ; de to linjene spleises sammen.
        mov     ax, [blklin1]
        xor     bx, bx
        call    splicelines

        jmp     SHORT @@mark_new_block

  @@more_left:
    ; Sjekk om linjen endte i newline. Hvis den gjorde det, fjernes hele.
        or      ax, ax
        jnz     @@remove_line

    ; Linjen endte ikke med newline. Da er dette siste linje. Fjern
    ; starten p� den, og spleis linjen sammen med forrige.
        mov     ax, [blklin1]
        inc     ax
        xor     bx, bx
        mov     cx, [blkcol2]
        call    removefromline

    ; Spleis sammen
        dec     ax
        call    splicelines

    ; Legg inn teksten i den nye blokken.
        mov     ax, [tblkln2]
        mov     bx, [tblkcl2]
        or      bx, bx
        jz      @@insert_last_line
        dec     bx
  @@insert_last_line:
        call    insertinline

        jmp     SHORT @@mark_new_block

  @@remove_line:
    ; Linjen endte i newline. Da skal hele vekk.
        mov     ax, [blklin1]
        inc     ax
        call    removeline

    ; Opprett en ny linje i den nye blokken.
        mov     ax, [tblkln2]
        xor     bx, bx
        call    splitline

    ; Legg inn det som ble fjernet fra den gamle blokken.
        call    insertinline

        jmp     @@next_line

  @@mark_new_block:
    ; Juster sluttkolonnen til blokken. Se over.
        cmp     [tblkcl2], 0
        jz      @@mark_it
        dec     [tblkcl2]

  @@mark_it:
    ; Sett blokkpekere til den nye posisjonen.
        mov     ax, [tblkln1]
        mov     [blklin1], ax
        mov     ax, [tblkcl1]
        mov     [blkcol1], ax
        mov     ax, [tblkln2]
        mov     [blklin2], ax
        mov     ax, [tblkcl2]
        mov     [blkcol2], ax

  @@ret:
        pop     es
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    moveblock





ENDS

        END
