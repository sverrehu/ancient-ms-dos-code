
; Compilation:
;   TASM /ml/m2 DOSED
;   TLINK /x/m DOSED

        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @code, es: @code



;==========================================================================

    ; Her fõlger konstanter som brukes diverse steder i programmet.

PRGNAME EQU     "DOSED"         ; Programmets navn
PRGVER  EQU     "v5.2"          ; Programmets versjon (· = 225)
PRGVERI EQU     0520h           ; Integer program version.
PRGDATE EQU     "7/9/94"        ; Programmets versjonsdato
;BETA   EQU     1               ; Undefine if not a BETA-version.

MAXPARA EQU     15              ; Maks antall kommandolinje-parametre

IDINT   EQU     021h            ; Interrupt for spõrsmÜl om installert
IDFUNC  EQU     0FFh            ; AH-verdi under spõrsmÜl om installert fra fõr

    ; Fõlgende konstanter bestemmer kompileringen av programmet. De mÜ
    ; enten vëre definert til 1, eller vëre udefinert. Det hjelper altsÜ
    ; ikke Ü sette dem til 0.
FREENV  EQU     1               ; Skal environmentet frigis?



PRMPTC  EQU     80              ; Max number of characters stored from prompt.
BUFSIZ  EQU     500             ; Antall bytes som settes av til kommando-
                                ; lageret
DTA     EQU     200             ; Adressen til midl. DTA i PSP.

INSERT  EQU     1
OVERWRT EQU     0





CODESEG

        ORG     0100h

start:
    ; Dette er inngangsadressen i programmet. Hopp til starten
    ; av den ikke-residente initialiseringsrutinen.
        jmp     main



;==========================================================================

    ; Data som brukes av den residente delen av programmet

idstring    DB  PRGNAME, 0      ; Brukes for Ü sjekke om installert
            DW  PRGVERI

IFNDEF FREENV
  envseg    DW  0               ; Adressen til environmentet, for bruk
                                ; under deinstallering.
ENDIF

enabled     DB  1               ; Skal rutinene utfõres?
old_id_int  DD  0               ; Gammel adresse til IDINT.

    ; Variabler for linjeeditoren
stdmode     DB  ?               ; Standardmode for Insert/Overwrite
insmode     DB  ?               ; NÜvërende mode for Insert/overwrite
SkipCtrlP   DB  ?               ; No Printer echo for Ctrl-P when Emacs mode.
    ; Fõlgende 2 mÜ ligge etter hverandre, for de utgjõr en
    ; FAR PTR til den orginale linjen.
loff        DW  ?               ; Offset til orginalt linjebuffer
lseg        DW  ?               ; Segment til orginalt linjebuffer
from        DW  ?               ; Nummeret til fõrste tegn som vises
pos         DW  ?               ; NÜvërende tegn
   ; Fõlgende 3 variabler mÜ ligge i rekkefõlge!!!
maxlen      DB  ?               ; Maks linjelengde, INKL. CR
linlen      DB  ?               ; Linjens lengde UTEN CR
tmplin      DB  256 DUP(?)      ; Linjen som editeres.

    ; Variabler for "kommandobanken"
MinChars    DB  ?               ; Minimum number of characters in stored lines.
next_com    DW  0               ; Nummeret til neste kommando som lagres
curr_com    DW  0               ; Nummeret til kommandoen som pekes til nÜ
                                ; (Gjelder bruk av pil opp/ned)

    ; Variabler for filnavnutfylling
PrevKey     DB  ?               ; Previous key pressed.
old_DTA     DD  ?               ; Gammel DTA-adresse
IsDir       DB  ?               ; Is name found a directory?
NameStart   DW  ?               ; Address of start of given name
found       DW  ?               ; Antall matchende filer
fname       DB  13 DUP (?)      ; Funnet filnavn
tmp         DB  ?               ; Midlertidig variabel for insertmode
DirDelim    DB  ?               ; Directory delimiter?
LowerCase   DB  ?               ; Convert characters to lowercase?
DoBeep      DB  ?               ; Beep when incomplete or no match?
DispName    DB  0               ; Display all matching names?
EntrCnt     DB  ?               ; Number of matches output on a line.
DoRmBkslsh  DB  1               ; Remove trailing backslashes?
DoSkipBak   DB  1               ; Skip files ending in .BAK?

    ; De neste variablene har med skjermutskrift Ü gjõre.
curx        DB  ?               ; Cursor X
cury        DB  ?               ; Cursor Y
lencol2     DB  ?               ; Antall kolonner pÜ skjermen * 2
scr_addr    DD  ?               ; Skjermadresse hvor fõrste tegn skal vises
LineAddr    DW  ?               ; (Offset-)address of current screen line.
scr_page    DB  ?               ; NÜvërende skjermside
text_attr   DB  ?               ; Tekstattributt
visible_chr DW  ?               ; Antall tegn pÜ linjen etter prompt
PromptBuf   DW  PRMPTC DUP (?)  ; Storage for prompt when displaying matches.
direct      DB  ?               ; Skal utskrift gÜ direkte til skjermen?


    ; Tabeller som brukes for Ü tolke tastetrykk.
    ; Den fõrste inneholder de forskjellige redigeringsprosedyrene.
    ; De to neste inneholder en rekke tall (tastekoder), den fõrste for
    ; utvidede taster, og den andre for kontroll-taster.
    ; NÜr en tast skal tolkes, ses det etter om tastens kode finnes i
    ; riktig tabell. Gjõr den det, kalles prosedyren som har samme nummer
    ; i prosedyretabellen som tasten har i tastetabellen.
NUMKEYS     EQU 18

LABEL   key_commands WORD

            DW  expand_filename, DisplayMatches
            DW  change_ins, char_left, char_right, word_left, word_right
            DW  beg_line, end_line, backspace, delete
            DW  get_prev_com, get_next_com, ClearEOL, clear_line, clear_line
            DW  prev_home, get_prev_com

LABEL   exp_keys BYTE

            DB  0, 15
            DB  82, 75, 77, 115, 116
            DB  71, 79, 0, 83
            DB  72, 80, 117, 0, 0
            DB  59,  61 ; F1 og F3 for dem som er vant til Ü bruke DOS

LABEL   ctrl_keys BYTE
    ; Default control-keys are WordStar-like.
    ; Kopied from below...
            DB  NUMKEYS DUP (?)





;==========================================================================

    ; Prosedyrer som brukes av den residente delen av programmet



;--------------------------------------------------------------------------
;
;   NAME:           Beep
;
;   DESCRIPTION:    Sound a beep.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    Beep

        push    ax
        push    bx

        mov     ax, 0E07h       ; Write Character 7 in Teletype Mode
        xor     bx, bx
        int     10h

        pop     bx
        pop     ax

  @@ret:
        ret

ENDP    Beep





;
; get_line_info
;
; Hva prosedyren gjõr:
;   Henter info om orginal linje, og legger dette i riktige variabler.
;
;   !!! OBS OBS !!! Etter dette, settes ogsÜ DS=ES=CS!!!
;
; Kall med:
;   DS:DX - peker til orginal linje
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt
;
PROC    get_line_info

        mov     bx, dx

    ; Finn maks lengde pÜ linjen, det som er angitt fõrst i det
    ; formatet DOS bruker.
        mov     al, [bx]
        mov     [cs: maxlen], al

    ; Ta vare pÜ segmentet til den orginale tekstlinjen.
        mov     [cs: lseg], ds

    ; Sett DS=ES=CS
        mov     ax, cs
        mov     ds, ax
        mov     es, ax

    ; Spar ogsÜ orginalt linjeoffset
        mov     [loff], dx

    ; Initier andre variabler
        mov     [tmplin], 13            ; Linjeslutt - tom linje
        xor     ax, ax
        mov     [linlen], al            ; Start med tom linje
        mov     [pos], ax               ; Markõren pÜ begynnelsen
        mov     [from], ax              ; Vis fra begynnelsen

        ret
ENDP    get_line_info



;
; get_screen_info
;
; Hva prosedyren gjõr:
;   Finner nõdvendige data om skjermen. Hvis ikke tekstmodus, settes
;   direct=0, slik at edit_line overlater kontrollen til den gamle INT 21h.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt, utenom ES
;
PROC    get_screen_info
        push    es

    ; Anta at tekstmode.
        mov     [direct], 1

    ; Sjekk hvilket skjermmode det er ved Ü se etter i BIOS-omrÜdet.
        xor     ax, ax
        mov     es, ax
        mov     bl, [es: 0449h]

    ; Anta fõrst at mono, og sjekk om det stemmer.
        mov     ax, 0B000h
        cmp     bl, 7
        je      @@textmode

    ; Ikke mono. Anta at farger, og sjekk om det stemmer.
        mov     ax, 0B800h
        cmp     bl, 3

    ; Nei, ikke farger heller. Marker at normal INT 21h skal brukes.
        jbe     @@textmode
        mov     [direct], 0
        jmp     SHORT @@ret

  @@textmode:
    ; Det er tekstmode. Lagre skjermadressen, og legg til
    ; offset til nÜvërende page.
        mov     [WORD scr_addr + 2], ax
        mov     ax, [es: 044Eh]         ; Offset of Current Page
        mov     [WORD scr_addr], ax
        mov     [LineAddr], ax

    ; Finn nÜvërende skjermside
        mov     bl, [es: 0462h]         ; Current Active Video Page
        mov     [scr_page], bl

    ; NÜvërende markõrposisjon
        xor     bh, bh
        shl     bx, 1
        mov     cx, [es: 0450h + bx]
        mov     [curx], cl
        mov     [cury], ch

    ; Finn antall kolonner, og gang dette med 2 for Ü finne hvor mye
    ; som mÜ legges til for hver linje.
        mov     al, [es: 044Ah]         ; Number of Columns
        mov     dl, al
        shl     al, 1
        mov     [lencol2], al

    ; Finn ut hvor mange tegn som kan vises pÜ linjen etter prompt.
        xor     dh, dh
        sub     dl, cl
        mov     [visible_chr], dx

    ; Oppdater skjermadressen slik at den starter pÜ fõrste tegn
    ; som skal vises av linjen. Fõrst colonnen.
        mov     al, cl
        xor     ah, ah
        shl     ax, 1
        add     [WORD scr_addr], ax

    ; og sÜ linjen.
        mov     al, ch
        xor     ah, ah
        mov     dl, [lencol2]
        mul     dl
        add     [WORD scr_addr], ax
        add     [LineAddr], ax

    ; Finn attributtet pÜ nÜvërende skjermposisjon, slik at hele linjen
    ; kan vises med dette attributtet.
        les     di, [scr_addr]
        inc     di
        mov     al, [es: di]
        mov     [text_attr], al

  @@ret:
        pop     es
        ret
ENDP    get_screen_info



;
; ega43
;
; Hva prosedyren gjõr:
;   Sjekker om skjermen er EGA med 43 linjer pÜ skjermen.
;   (Ikke VGA med 50 linje, BAAAARE EGA med 43 linjer.)
;   Grunnen til at dette sjekkes, er at det blir kluss med
;   cursoren nÜr den endres i akkurat dette mode.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   ZF=0 -> Ikke EGA med 43 linjers skjerm
;   ZF=1 -> EGA med 43 linjer
;
; Endrer innholdet i:
;   Alt, utenom ES
;
PROC    ega43

    ; Sjekk fõrst om VGA. Da skal det isÜfall hoppes ut.
        mov     ax, 1A00h               ; Get Display Combination Code
        int     10h
        cmp     al, 1Ah
        je      @@not_EGA

    ; Sjekk sÜ om EGA.
        mov     ah, 12h                 ; Get Configuration Information
        mov     bl, 10h                 ;
        int     10h
        cmp     bl, 10h                 ; Hvis BL=10h (som fõr kallet),
        je      @@not_EGA               ; er ikke det EGA/VGA

    ; Det er EGA. Sjekk om 43 linjer.
        push    es
        xor     ax, ax
        mov     es, ax
        cmp     [BYTE es: 0484h], 42    ; Er det 43 linjer (42 + 1) ?
        pop     es
        ret                             ; Her er ZF=1 hvis 43 linjer

  @@not_EGA:
        and     bl, bl                  ; Setter ZF=0 (siden BL <> 0)
        ret
ENDP    ega43



;
; set_emul_bit
;
; Hva prosedyren gjõr:
;   Enabler eller disabler cursor emulation
;
; Kall med:
;   AL=0 - sett 0:487h bit 0 til 0   (enable emulation)
;   AL=1 - sett 0:487h bit 0 til 1   (disable emulation)
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt, utenom ES
;
PROC    set_emul_bit
        push    es

        xor     bx, bx
        mov     es, bx
        and     [BYTE es: 0487h], 0FEh  ; Clear bit 0
        or      [BYTE es: 0487h], al    ; Set bit 0 if AL=1

        pop     es
        ret
ENDP    set_emul_bit



;
; set_cursor_type
;
; Hva prosedyren gjõr:
;   Setter markõren som angitt i CX ved Ü kalle INT 10, funk 1.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   AH, CX
;
PROC    set_cursor_type
        and     cx, 1F1Fh               ; Sõrg for riktige verdier (0-31)
        mov     ah, 1
        int     10h
        ret
ENDP    set_cursor_type



;
; small_cursor
;
; Hva prosedyren gjõr:
;   Lager cursor under tegnet. Spesialbehandler EGA med 43 linjer.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt, utenom ES
;
PROC    small_cursor

    ; Sjekk om EGA med 43 linjer
        call    ega43
        jne     @@not_ega43

    ; EGA med 43 linjer. Spesialbehandle dette.
        mov     cx, 0600h               ; Passer EGA med 43 linjer
        mov     al, 1
        call    set_emul_bit            ; Disable cursor emulation
        call    set_cursor_type
        xor     al, al
        call    set_emul_bit            ; Enable cursor emulation
        ret

  @@not_ega43:
    ; Alt annet, sett <start scan line> = <end scan line - 1>
        mov     ah, 3                   ; Finn markõrens utseende
        int     10h
        mov     ch, cl                  ; Start scan line = end scan line - 1
        dec     ch
        call    set_cursor_type
        ret
ENDP    small_cursor



;
; big_cursor
;
; Hva prosedyren gjõr:
;   Lager cursor som blokk. Spesialbehandler EGA med 43 linjer.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt, utenom ES
;
PROC    big_cursor

    ; Sjekk om EGA med 43 linjer.
        call    ega43
        jne     @@not_ega43

    ; EGA med 43 linjer. Spesialbehandle dette.
        mov     cx, 0007h               ; Passer EGA med 43 linjer
        mov     al, 1
        call    set_emul_bit            ; Disable cursor emulation
        call    set_cursor_type
        xor     al, al
        call    set_emul_bit            ; Enable cursor emulation
        ret

  @@not_ega43:
    ; Alt annet, sett <start scan line>=0
        mov     ah, 3                   ; Finn markõrens utseende
        int     10h
        xor     ch, ch                  ; Start scan line = 0
        call    set_cursor_type
        ret
ENDP    big_cursor



;
; set_correct_cursor
;
; Hva prosedyren gjõr:
;   Setter riktig cursorstõrrelse, dvs:
;     Liten hvis insmode == stdmode
;     Stor  hvis insmode != stdmode
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt, utenom ES
;
PROC    set_correct_cursor

    ; Sjekk hva slags cursortype som skal settes.
        mov     al, [insmode]
        cmp     al, [stdmode]
        jne     @@big_cursor

    ; Sett liten cursor, siden insmode == stdmode
        call    small_cursor
        ret

  @@big_cursor:
    ; Sett stor cursor, siden insmode != stdmode
        call    big_cursor
        ret
ENDP    set_correct_cursor



;
; show_line
;
; Hva prosedyren gjõr:
;   Viser nÜvërende editeringslinje pÜ skjermen fra posisjonen from.
;   Markõren endres ikke.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt, utenom ES
;
PROC    show_line
        push    es

    ; Hent riktig tekstattributt og skjermadresse.
        mov     ah, [text_attr]
        les     di, [scr_addr]

    ; Finn adressen til fõrste tegn som skal vises i den midlertidige
    ; linjen, samt antall tegn fra fõrste som vises og til linjeslutt.
        mov     si, [from]
        mov     cl, [linlen]
        xor     ch, ch
        sub     cx, si
        add     si, OFFSET tmplin

    ; Sjekk om CX er mindre enn eller lik antall tegn som kan vises.
        mov     dx, [visible_chr]
        cmp     cx, dx
        jbe     @@cx_ok

    ; Antall tegn som vises er for stort, og justeres til maks mulig.
        mov     cx, dx

  @@cx_ok:
    ; Finn ut hvor mange blanke som skal vises etter siste tegn.
        sub     dx, cx

    ; Vis det som skal vises av linjen
        jcxz    @@all_written
        cld

  @@more_characters:
        lodsb
        stosw
        loop    @@more_characters

  @@all_written:
    ; Fyll skjermlinjen med blanke.
        mov     cx, dx
        jcxz    @@ret
        mov     al, ' '
        cld
        rep     stosw

  @@ret:
        pop     es
        ret
ENDP    show_line





    ; Her fõlger en rekke prosedyrer som tar seg av de forskjellige
    ; redigeringkommandoene.



;
; change_ins
;
; Hva prosedyren gjõr:
;   Bytter insertmode, og viser riktig cursorstõrrelse.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt
;
PROC    change_ins
        xor     [insmode], 1
        call    set_correct_cursor
        ret
ENDP    change_ins



;
; char_left
;
; Hva prosedyren gjõr:
;   Flytter et tegn til venstre hvis mulig.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt
;
PROC    char_left

    ; Sjekk om allerede pÜ starten pÜ linjen.
        cmp     [pos], 0
        jbe     @@ret

    ; Det var vi ikke. Flytt til venstre.
        dec     [pos]

  @@ret:
        ret
ENDP    char_left



;
; word_left
;
; Hva prosedyren gjõr:
;   Flytter et ord til venstre hvis mulig.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt
;
PROC    word_left

    ; Flytt fõrst over evt blanke.
        mov     bx, [pos]

  @@skip_blanks:
    ; Sjekk om linjestart er nÜdd
        or      bx, bx
        jz      @@ret

    ; Flytt til venstre, og sjekk om fortsatt blank.
        dec     bx
        cmp     [tmplin + bx], ' '
        je      @@skip_blanks

  @@find_start:
    ; Har kommet til et ord. Flytt bakover til starten er nÜdd.
        or      bx, bx
        jz      @@ret

    ; Er tegnet til venstre blankt ?
        cmp     [tmplin + bx - 1], ' '
        je      @@ret

    ; Nei, flytt videre til venstre.
        dec     bx
        jmp     SHORT @@find_start

  @@ret:
    ; Lagre funnet posisjon som ny.
        mov     [pos], bx
        ret
ENDP    word_left



;
; char_right
;
; Hva prosedyren gjõr:
;   Flytter et tegn til hõyre hvis mulig.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt
;
PROC    char_right

    ; Sjekk om allerede pÜ slutten av linjen.
        mov     al, [linlen]
        xor     ah, ah
        cmp     [pos], ax
        jae     @@ret

    ; Det var vi ikke. Flytt til hõyre.
        inc     [pos]

  @@ret:
        ret
ENDP    char_right



;
; word_right
;
; Hva prosedyren gjõr:
;   Flytter et ord til venstre hvis mulig.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt
;
PROC    word_right

    ; Flytt fõrst ut av nÜvërende ord.
        mov     dl, [linlen]
        xor     dh, dh
        mov     bx, [pos]

  @@skip_non_blanks:
    ; Er linjeslutt nÜdd ?
        cmp     bx, dx
        jae     @@ret

    ; Sjekk om vi er ute av ordet.
        cmp     [tmplin + bx], ' '
        je      @@find_start

    ; Flytt til hõyre og hopp over flere tegn.
        inc     bx
        jmp     @@skip_non_blanks

  @@find_start:
    ; Har kommet til blanke. Finn evt starten pÜ neste ord.
        inc     bx
        cmp     bx, dx
        jae     @@ret

    ; Er vi fortsatt pÜ blanke ?
        cmp     [tmplin + bx], ' '
        je      @@find_start

  @@ret:
    ; Lagre funnet posisjon som ny.
        mov     [pos], bx
        ret
ENDP    word_right



;
; beg_line
;
; Hva prosedyren gjõr:
;   Flytter til starten pÜ linjen.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt
;
PROC    beg_line
        mov     [pos], 0
        ret
ENDP    beg_line



;
; end_line
;
; Hva prosedyren gjõr:
;   Flytter til slutten pÜ linjen.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt
;
PROC    end_line
        mov     al, [linlen]
        xor     ah, ah
        mov     [pos], ax
        ret
ENDP    end_line



;
; clear_line
;
; Hva prosedyren gjõr:
;   Tõmmer hele linjen.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt
;
PROC    clear_line
        mov     [linlen], 0
        mov     [pos], 0
        ret
ENDP    clear_line



;--------------------------------------------------------------------------
;
;   NAME:           ClearEOL
;
;   DESCRIPTION:    Clears line from current position.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    ClearEOL
        mov     al, [BYTE pos]
        mov     [linlen], al
        ret
ENDP    ClearEOL



;
; delete
;
; Hva prosedyren gjõr:
;   Sletter tegnet pÜ nÜvërende posisjon.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt
;
PROC    delete

    ; Sjekk om bak linjeslutt. Da kan ikke tegn slettes.
        mov     al, [linlen]
        xor     ah, ah
        cmp     [pos], ax
        jae     @@ret

    ; Flytt tegnene til hõyre et hakk til venstre.
        mov     bx, [pos]
        mov     di, OFFSET tmplin
        add     di, bx
        mov     si, di
        inc     si
        mov     cx, 255
        sub     cx, bx
        cld
        rep     movsb

    ; Linjen har blitt et tegn kortere.
        dec     [linlen]

  @@ret:
        ret
ENDP    delete



;
; backspace
;
; Hva prosedyren gjõr:
;   Flytter et tegn til venstre, og sletter dette.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt
;
PROC    backspace

    ; Er vi alt pÜ begynnelsen av linjen?
        cmp     [pos], 0
        jbe     @@ret

    ; Flytt til venstre, og slett tegnet.
        dec     [pos]
        call    delete

  @@ret:
        ret
ENDP    backspace



;
; store_character
;
; Hva prosedyren gjõr:
;   Setter angitt tegn inn i nÜvërende pos i tmplin.
;   Strengen behandles i forhold til nÜvërende insertmode.
;
; Kall med:
;   AL - tegnet som skal settes inn i linjen
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt
;
PROC    store_character

    ; Sjekk om plass til flere tegn
        mov     bx, [pos]
        mov     dl, [maxlen]
        xor     dh, dh
        dec     dx
        cmp     bx, dx
        jb      @@more_free

    ; Det er ikke plass til mer. Lag et Beep, og hopp ut.
        call    Beep
        jmp     SHORT @@ret

  @@more_free:
    ; Sjekk om tegnet skal overskrive nÜvërende, eller "trykkes inn".
        cmp     [insmode], OVERWRT
        je      @@not_insert

    ; Tegnet skal trykkes inn. Lag plass.
        mov     di, OFFSET tmplin + 255
        mov     si, OFFSET tmplin + 254
        mov     cx, 255
        sub     cx, bx
        std
        rep     movsb

  @@not_insert:
    ; Sett tegnet oppÜ nÜvërende, og flytt til neste posisjon.
        mov     [tmplin + bx], al
        inc     bx
        mov     [pos], bx

    ; Oppdater linjelengden. Hvis insert er pÜ, skal den õkes.
        cmp     [insmode], 0
        jne     @@inc_linlen

    ; Insert er ikke pÜ, men lengden skal õkes hvis posisjonen er
    ; etter siste tegn i linjen.
        cmp     [linlen], bl
        jae     @@ret

  @@inc_linlen:
    ; ùk linjelengden hvis dette ikke medfõrer at linjen blir for lang.
    ; (men det kan den vel ikke bli ????)
        cmp     [linlen], dl
        jae     @@ret
        inc     [linlen]

  @@ret:
        ret
ENDP    store_character





;--------------------------------------------------------------------------
;
;   NAME:           PossiblyBeep
;
;   DESCRIPTION:    Possibly sound a beep.
;                   Only done if the beep-option is given.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    PossiblyBeep

        cmp     [DoBeep], 0
        je      @@ret

        call    Beep

  @@ret:
        ret

ENDP    PossiblyBeep





;--------------------------------------------------------------------------
;
;   NAME:           PossiblyLowercase
;
;   DESCRIPTION:    Possibly convert the character in AL to lowercase.
;                   Only done if it is uppercase 'A' - 'Z', and if the
;                   lowercase-option is given.
;
;   PARAMETERS:     AL   Character to convert.
;
;   RETURNS:        AL   Possibly converted character.
;
;
PROC    PossiblyLowercase

        cmp     [LowerCase], 0
        je      @@ret

        cmp     al, 'A'
        jb      @@ret
        cmp     al, 'Z'
        ja      @@ret

        add     al, 'a' - 'A'

  @@ret:
        ret

ENDP    PossiblyLowercase





;--------------------------------------------------------------------------
;
;   NAME:           MatchNames
;
;   DESCRIPTION:    Tries to match filenames with what the user have
;                   entered on the command line. This function is used
;                   both for completing and displaying filenames.
;                   Uses (and updates) global variables to find out
;                   what to do.
;
;                   Always does what is needed for completion, since
;                   this is invisible for the user.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    MatchNames

    ; Anta fõrst at ingen match er funnet.
        mov     [found], 0

    ; Set up for copying given path to PSP.
        xor     di, di

    ; Gjõr fõrst en del testing for Ü se om det er mulig Ü gjõre alt
    ; klart til kopiering av angitt path til midlertidig strengbuffer

    ; Check if at linestart.
        mov     bx, [pos]
        mov     [NameStart], bx
        or      bx, bx
        jz      @@add_wildcards

    ; Sjekk om vi stÜr pÜ en blank eller pÜ linjeslutt.
    ; Hvis ikke, skal ikke navnet kunne fylles ut.
        cmp     [tmplin + bx], ' '
        je      @@on_a_blank
        cmp     [linlen], bl
        je      @@on_a_blank
        jmp     @@ret

  @@on_a_blank:
    ; Check if previous character is a blank. In that case we try
    ; to match all filenames.
        cmp     [tmplin + bx - 1], ' '
        je      @@add_wildcards

    ; Finn starten pÜ angitt path ved Ü sõke bakover til fõrste blank,
    ; eller starten pÜ linjen.
        xor     cx, cx

  @@search_back:
    ; Er starten pÜ linjen nÜdd ?
        or      bx, bx
        jz      @@copy_path

    ; Hent nÜvërende tegn, og sjekk om blank.
        mov     al, [tmplin + bx - 1]
        cmp     al, ' '
        je      @@copy_path

    ; Sjekk om jokertegn. Da er utfylling isÜfall ikke mulig,
    ; siden MS-DOS bare tillater et sett med wildcards.
        cmp     al, '?'
        je      @@jmp_to_ret
        cmp     al, '*'
        jne     @@no_wildcards
  @@jmp_to_ret:
        jmp     @@ret

  @@no_wildcards:
    ; Begynnelsen er ikke funnet. Let videre bakover.
        inc     cx
        dec     bx
        jmp     @@search_back

  @@copy_path:
    ; NÜ skal angitt path kopieres over i PSP (mellomlager), slik
    ; at evt. matcher kan finnes. DX skal brukes for Ü finne ut
    ; hvor filnavndelen av path'en starter.
        mov     dx, di
        push    bx
        cld

  @@copy_loop:
    ; Det skal finnes ut hvor filnavndelen starter.
    ; Registrerer derfor hver gang '\', '/' eller ':' pÜtreffes.
        mov     al, [tmplin + bx]
        stosb
        inc     bx
        cmp     al, '\'
        je      @@note_character
        cmp     al, '/'
        je      @@note_character
        cmp     al, ':'
        jne     @@copy_further

  @@note_character:
    ; "Husk" at nÜvërende tegn er sett (lagrer fõrste tegn _etter_).
        mov     dx, di

  @@copy_further:
        loop    @@copy_loop

    ; Adjust BX to point to the start of the name given.
        pop     bx
        add     bx, dx
        mov     [NameStart], bx

    ; NÜ er angitt path kopiert over i PSP. Juster DI til Ü peke pÜ
    ; starten av filnavnet.
        mov     di, dx

  @@add_wildcards:
    ; Legg til "*.*\0"
        mov     ax, '*' + 256 * '.'
        stosw
        xor     ah, ah
        stosw

    ; Residente programmer mÜ ikke rote til nÜvërende DTA. Opprett
    ; derfor en egen.
    ; Finn nÜvërende DTA-adresse, og lagre denne.
        push    es
        mov     ah, 2Fh                 ; Get DTA Address
        int     21h
        mov     [WORD old_DTA], bx
        mov     [WORD old_DTA + 2], es
        pop     es

        mov     ah, 1Ah                 ; Set DTA Address
        mov     dx, DTA
        int     21h

    ; Utfõr Find First pÜ path'en som er fõrst i PSP.
        mov     ah, 4Eh                 ; Find first
        mov     cx, 00010000b           ; Directory bit
        xor     dx, dx                  ; Start av PSP
        int     21h
  @@test_if_found:
        jnc     @@found_a_name
        jmp     @@resett_DTA            ; Ikke funnet en eneste fil

  @@found_a_name:
    ; Dot-files should only be counted for if a dot is given first
    ; in the name.
        cmp     [BYTE DTA + 30], '.'
        jne     @@possibly_skip_bak
        mov     bx, [NameStart]
        cmp     bl, [linlen]
        je      @@jmp_no_match
        cmp     [BYTE tmplin + bx], '.'
        jne     @@jmp_no_match

  @@possibly_skip_bak:
        cmp     [DoSkipBak], 0
        je      @@check_match

    ; Skip names with extension .BAK
        mov     si, DTA + 30            ; Navnets start i DTA'en
        cld
  @@find_dot:
        lodsb
        or      al, al
        je      @@check_match
        cmp     al, '.'
        jne     @@find_dot
        lodsb
        and     al, 0DFh
        cmp     al, 'B'
        jne     @@check_match
        lodsb
        and     al, 0DFh
        cmp     al, 'A'
        jne     @@check_match
        lodsb
        and     al, 0DFh
        cmp     al, 'K'
        jne     @@check_match
  @@jmp_no_match:
        jmp     @@no_match

  @@check_match:
    ; Check if this name is a match.
        mov     si, DTA + 30            ; Navnets start i DTA'en
        mov     bx, [NameStart]
  @@cmp_char:
        cmp     [linlen], bl
        je      @@match
        mov     al, [tmplin + bx]
        cmp     al, ' '
        je      @@match
        cmp     al, 13
        je      @@match
        mov     ah, [si]
        and     ax, 0DFDFh
        cmp     ah, al
        je      @@more_cmp
        jmp     @@no_match

  @@more_cmp:
        inc     bx
        inc     si
        jmp     @@cmp_char

  @@match:
    ; Har funnet et navn som passer. NÜ er det to muligheter: Hvis ingen
    ; navn er funnet fra fõr, skal hele dette navnet kopieres over i
    ; omrÜdet for filnavn. Hvis tidligere match er funnet, skal denne
    ; kuttes der den er ulik den nyeste.
        mov     al, [DTA + 21]
        and     al, 00010000b           ; Directory?
        mov     [IsDir], al
        mov     si, DTA + 30            ; Navnets start i DTA'en
        mov     di, OFFSET fname

        cmp     [found], 0
        jne     @@compare_and_chop
    ; Her kopierer vi navnet, siden ingen andre ble funnet.
        mov     [EntrCnt], 0            ; Number of entries on this line.
        push    es
        push    ds
        pop     es
        mov     cx, 13                  ; Opptil 13 tegn inkludert 0
        cld
        rep     movsb
        pop     es
        jmp     SHORT @@inc_found

  @@compare_and_chop:
        mov     [IsDir], 0
  @@still_equal:
        mov     al, [si]
        or      al, al                  ; Er slutten nÜdd ?
        jz      @@difference_found
        mov     ah, [di]
        and     ax, 0DFDFh
        cmp     ah, al
        jne     @@difference_found
        inc     si
        inc     di
        jmp     @@still_equal

  @@difference_found:
    ; Ulikheten er funnet. Kutt strengen her.
        mov     [BYTE di], 0

  @@inc_found:
    ; Marker at minst et navn er funnet.
        inc     [found]

  @@find_next:
    ; A legal name is currently in the DTA. Possibly display it
    ; on the screen.
        cmp     [DispName], 0
        jz      @@after_disp

    ; First: If there are no more room on the current line, a CR/LF
    ; must be output.
        cmp     [EntrCnt], 0
        jne     @@theres_room

        mov     ah, 2                   ; Character Output
        mov     dl, 13
        int     21h
        mov     dl, 10
        int     21h

        mov     [EntrCnt], 5

  @@theres_room:
        mov     cx, 15                  ; Characters pr entry.
        mov     si, DTA + 30            ; Name found.
  @@disp_next_char:
        mov     al, [si]
        or      al, al
        jz      @@entire_name_output
        call    PossiblyLowercase
        mov     dl, al
        mov     ah, 2                   ; Character Output
        int     21h
        inc     si
        dec     cx
        jmp     @@disp_next_char

  @@entire_name_output:
    ; If this was a directory, a '\' should be added.
        mov     dl, ' '
        and     [BYTE DTA + 21], 00010000b      ; Directory?
        jz      @@not_dir
        mov     dl, '\'

  @@not_dir:
    ; Output it, and fill up with spaces.
        mov     ah, 2                   ; Character Output
        int     21h
        mov     dl, ' '
        loop    @@not_dir

        dec     [EntrCnt]

  @@no_match:
  @@after_disp:
    ; Prõv Ü finne fler som matcher.
        mov     ah, 4Fh                 ; Find next
        int     21h
        jmp     @@test_if_found

  @@resett_DTA:
    ; Sett DTA'en dit den opprinnelig var.
        push    ds
        mov     ah, 1Ah                 ; Set DTA Address
        lds     dx, [old_DTA]
        int     21h
        pop     ds

    ; If we have displayed some names, advance to the next line.
        cmp     [DispName], 0
        jz      @@ret

        mov     ah, 2                   ; Character Output
        mov     dl, 13
        int     21h
        mov     dl, 10
        int     21h

  @@ret:
        ret

ENDP    MatchNames





;--------------------------------------------------------------------------
;
;   NAME:           DisplayMatches
;
;   DESCRIPTION:    Display the matching filenames according to what
;                   the user has typed so far.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    DisplayMatches

        push    es

    ; Store the prompt.
        push    ds
        pop     es
        mov     di, OFFSET PromptBuf
        mov     si, [LineAddr]
        mov     ax, [WORD scr_addr]
        sub     ax, si
        push    ax
        push    ds
        mov     ds, [WORD scr_addr + 2]
        mov     cx, PRMPTC
        cld
        rep     movsw
        pop     ds

    ; Display names
        mov     [DispName], 1
        call    MatchNames
        mov     [DispName], 0

    ; Restore the prompt.
        mov     al, [curx]
        push    ax
        call    get_screen_info
        pop     ax
        mov     [curx], al
        mov     si, OFFSET PromptBuf
        mov     es, [WORD scr_addr + 2]
        mov     di, [LineAddr]
        mov     cx, PRMPTC
        cld
        rep     movsw
        pop     ax
        add     ax, [LineAddr]
        mov     [WORD scr_addr], ax

  @@ret:
        pop     es
        ret

ENDP    DisplayMatches





;
; expand_filename
;
; Hva prosedyren gjõr:
;   Fyller (hvis mulig) ut det delvis angitte filnavnet pÜ kommandolinjen,
;   slik at det blir fullstendig.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt
;
PROC    expand_filename

    ; If the last key was a Tab, and there were several matches,
    ; we display all matches.
        cmp     [PrevKey], 9
        jne     @@normal_expand
        cmp     [found], 1
        jbe     @@normal_expand
        call    DisplayMatches
        jmp     SHORT @@ret

  @@normal_expand:
    ; Get a match
        call    MatchNames

    ; Hvis noe ble funnet, skal det kopieres inn i linjen.
        cmp     [found], 0
        je      @@possibly_beep_and_ret

    ; Innsettmodus mÜ settes pÜ, slik at ingenting overskrives nÜr
    ; bokstaver legges til.
        mov     al, [insmode]
        mov     [tmp], al
        mov     [insmode], 1

    ; Fjern filnavndelen av angitt path. Det mÜ sõkes bakover
    ; for Ü finne ut hvor denne starter.

  @@remove_old_name:
    ; Er starten pÜ linjen nÜdd ?
        mov     bx, [pos]
        or      bx, bx
        jz      @@insert_new_name

    ; Hent forrige tegn og sjekk om skilletegn eller blank.
        mov     al, [tmplin + bx - 1]
        cmp     al, '\'
        je      @@insert_new_name
        cmp     al, '/'
        je      @@insert_new_name
        cmp     al, ':'
        je      @@insert_new_name
        cmp     al, ' '
        je      @@insert_new_name

    ; Fjern forrige tegn, og let videre etter skilletegn eller blank.
        call    backspace
        jmp     @@remove_old_name

  @@insert_new_name:
    ; Sett inn filnavnet som ble funnet i strengen.
        mov     si, OFFSET fname        ; Start pÜ funnet navn

  @@insert_character:
    ; Hent neste tegn fra funnet filnavn
        cld
        lodsb

    ; Sjekk om slutten er nÜdd
        or      al, al
        jz      @@all_inserted

    ; Sett tegnet inn i linjen
        call    PossiblyLowercase
        push    si
        call    store_character
        pop     si

    ; Kopier mer
        jmp     @@insert_character

  @@all_inserted:
    ; Sjekk om det skal settes inn en blank (filen er en fil), en
    ; backslash (filen er directory), eller ingenting (flere er funnet)
        cmp     [found], 1
        ja      @@nothing

        mov     al, ' '
        cmp     [IsDir], 0     ; Er det directory
        je      @@not_dir
        cmp     [DirDelim], 0
        je      @@nothing
        mov     al, '\'

  @@not_dir:
    ; Sett inn ' ' eller '\'
        call    store_character

  @@nothing:
    ; Sett tilbake insertmode til det det var fõr expand_filename.
        mov     al, [tmp]
        mov     [insmode], al

  @@possibly_beep_and_ret:
    ; If other than one match was found, it might be that the
    ; user wants a beep.
        cmp     [found], 1
        je      @@ret
        call    PossiblyBeep

  @@ret:
        ret
ENDP    expand_filename






;--------------------------------------------------------------------------
;
;   NAME:           RemoveBackslashes
;
;   DESCRIPTION:    Remove any backslashes that are followed by whitespace,
;                   and has non-space or non-colon in front. In addition, we
;                   must try to keep the special way command.com treats
;                   internal commands. Absolute paths may follow directly
;                   after for instance CD:
;
;                     CD\
;
;                   This backslash should not be removed. If more than one
;                   \ is given however, the last one should be removed as
;                   in:
;
;                     CD\DOS\
;
;                   In all other words but the first, backslashes should be
;                   removed.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    RemoveBackslashes

        push    ds
        pop     es
        mov     si, OFFSET tmplin
        mov     di, si
        cld

    ; If the first character is a space, we leave the line alone.
        lodsb
        stosb
        cmp     al, ' '
        je      @@ret

        mov     cl, [linlen]
        xor     ch, ch
        jcxz    @@ret
        dec     cx              ; Compensate for the one just copied.
        jcxz    @@ret
        xor     bl, bl          ; Count characters removed.
        xor     dx, dx          ; Count spaces seen (DL), to be able to skip
                                ; removal after the first word, and back-
                                ; slashes seen (DH) to anyway remove the
                                ; last in the first word if it's not the
                                ; only one.

  @@more_left:
        mov     ah, al          ; Previous character.
        lodsb
        cmp     al, ' '
        jne     @@not_space
        inc     dl
  @@not_space:
        cmp     al, '\'
        jne     @@store_it
        inc     dh
        cmp     cx, 1           ; This is the last character on the line.
        je      @@possibly_remove
        mov     bh, [BYTE si]   ; Following character.
        cmp     bh, ' '
        je      @@possibly_remove
        cmp     bh, ','
        je      @@possibly_remove
        cmp     bh, ';'
        jne     @@store_it
  @@possibly_remove:
        cmp     ah, ' '
        je      @@store_it
        cmp     ah, ':'
        je      @@store_it
        or      dl, dl          ; Part of first word?
        jne     @@skip_it       ; No? Always skip the last backslash.
        cmp     dh, 1           ; Is this the first (and last) backslash?
        je      @@store_it      ; Yep, one and only backslash in first word.

  @@skip_it:
        inc     bl
        jmp     SHORT @@loop

  @@store_it:
        stosb
  @@loop:
        loop    @@more_left

        sub     [linlen], bl

  @@ret:
        ret

ENDP    RemoveBackslashes





;
; find_line
;
; Hva prosedyren gjõr:
;   Sõker seg fram til kommandolinjen med angitt nummer,
;   og returnerer OFFSET fra command_list til denne. Hvis ikke
;   funnet, returneres peker til der neste linje evt skal havne.
;
; Kall med:
;   AX - ùnsket linjenummer (0 ...)
;
; Returnerer:
;   DI - Offset til linjen fra command_list, eller dit neste
;        linje skal havne hvis ikke funnet.
;
; Endrer innholdet i:
;   Alt, utenom AX
;
PROC    find_line
        push    ax

    ; Finn terminerende 0-byte angitt antall ganger.
        mov     di, OFFSET command_list
        mov     cx, ax
        jcxz    @@ret
        xor     al, al
        cld

  @@more_left:
        push    cx
        mov     cx, 255
        repne   scasb
        pop     cx

    ; Sjekk om slutten pÜ hele listen er nÜdd.
        cmp     [di], al
        je      @@ret
        loop    @@more_left

  @@ret:
    ; Juster DI sÜ den er relativ til command_list.
        sub     di, OFFSET command_list

        pop     ax
        ret
ENDP    find_line



;
; copy_from_list
;
; Hva prosedyren gjõr:
;   Kopierer linjen (merk:) DI peker pÜ til tmplin og oppdaterer
;   linlen. Det kopieres ikke fler tegn enn at maxlen blir riktig.
;   pos settes til slutten av linjen.
;
; Kall med:
;   ES=DS=CS
;   DI - peker til linjen.
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt, utenom AX, DI
;
PROC    copy_from_list
        push    ax
        push    di

        mov     dl, [maxlen]
        dec     dl

    ; DS:SI skal peke til start pÜ kilden
        mov     si, di
        add     si, OFFSET command_list

    ; ES:DI skal peke til mÜlet, templin
        mov     di, OFFSET tmplin

    ; Kopier tegn, og tell antallet.
        cld
        xor     cl, cl                  ; Brukes for Ü telle opp
  @@more_left:
        lodsb
        or      al, al
        jz      @@copy_finished
        stosb
        inc     cl
        cmp     cl, dl
        jb      @@more_left

  @@copy_finished:
    ; Legg inn en Carriage Return som avsluttende tegn.
        mov     al, 13
        stosb

    ; Oppdater variabler.
        mov     [linlen], cl
        xor     ax, ax
        mov     [from], ax
        mov     [pos], ax
        call    end_line

  @@ret:
        pop     di
        pop     ax
        ret
ENDP    copy_from_list



;
; get_prev_com
;
; Hva prosedyren gjõr:
;   Kopierer forrige kommando til tmplin, og oppdaterer curr_com.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt
;
PROC    get_prev_com

    ; Sjekk om det ikke er noen forrige kommando.
        mov     ax, [curr_com]
        or      ax, ax
        jz      @@rotate

    ; Det er tidligere kommandoer. Hent den forrige.
        dec     ax
        jmp     SHORT @@fetch_command

  @@rotate:
    ; Hent siste kommando siden det ikke er noen forrige.
        mov     ax, [next_com]
        or      ax, ax
        jz      @@fetch_command
        dec     ax

  @@fetch_command:
    ; Hent kommandoen med nummer AX, hva nÜ det mÜtte vëre.
    ; Sett denne kommandoen til nÜvërende.
        mov     [curr_com], ax
        call    find_line
        call    copy_from_list

        ret
ENDP    get_prev_com



;
; prev_home
;
; Hva prosedyren gjõr:
;   Henter forrige kommando, og flytter markõren til linjestart.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt
;
PROC    prev_home
        call    get_prev_com
        call    beg_line
        ret
ENDP    prev_home



;
; get_next_com
;
; Hva prosedyren gjõr:
;   Kopierer neste kommando (relativt til curr_com) til tmplin, og
;   oppdaterer curr_com.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt
;
PROC    get_next_com

    ; Finn ut hvilket nummer "neste" kommando har.
        mov     ax, [curr_com]
        inc     ax

    ; Er dette utenfor listen?
        cmp     ax, [next_com]
        jb      @@fetch_command

    ; Ja det er det. Roter rundt ved Ü hente inn fõrste isteden.
        xor     ax, ax

  @@fetch_command:
    ; Hent kommandoen med nummer AX, hva nÜ det mÜtte vëre.
    ; Sett denne kommandoen til nÜvërende.
        mov     [curr_com], ax
        call    find_line
        call    copy_from_list

        ret
ENDP    get_next_com



;
; remove_first_com
;
; Hva prosedyren gjõr:
;   Sletter den fõrste kommandoen i listen (dvs den eldste) for
;   Ü gi plass til ny bakerst. Oppdaterer alle pekere til listen.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt
;
PROC    remove_first_com

    ; Sjekk fõrst om listen er tom, slik at det ikke er mer Ü fjerne.
        cmp     [next_com], 0
        je      @@ret

    ; Finn ut hvor 2. kommando starter.
        mov     ax, 1
        call    find_line

    ; Fjern den 1. ved Ü trekke byte for byte fra den 2. og oppover.
        mov     cx, BUFSIZ
        sub     cx, di

        mov     si, di
        add     si, OFFSET command_list
        mov     di, OFFSET command_list
        cld
        rep     movsb

    ; Oppdater pekere til listen.
        dec     [next_com]
        cmp     [curr_com], 0
        je      @@ret
        dec     [curr_com]

  @@ret:
        ret
ENDP    remove_first_com



;
; store_line
;
; Hva prosedyren gjõr:
;   Legger til ny kommando bakerst, etter evt Ü ha slettet de eldste
;   for Ü gi plass. Oppdaterer alle pekere til listen.
;   Det sjekkes fõrst om kommandoen er lang nok til Ü lagres.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt
;
PROC    store_line

    ; Sjekk fõrst om linjen er lang nok til Ü skulle lagres.
        mov     dl, [linlen]
        cmp     dl, [MinChars]
        jb      @@ret

        xor     dh, dh

  @@try_again:
    ; Finn ut hvor linjen skal settes inn.
        mov     ax, [next_com]
        call    find_line

    ; Sjekk om det er nõdvendig Ü fjerne noen for Ü fÜ plass til den nye
        mov     ax, BUFSIZ - 2
        sub     ax, di
        js      @@not_enough_free
        cmp     ax, dx
        jae     @@enough_free

  @@not_enough_free:
    ; Det er ikke nok ledig plass i listen. Fjern den eldste
    ; linjen, og prõv igjen.
        call    remove_first_com
        jmp     @@try_again

  @@enough_free:
    ; Det er nok plass. Kopier inn linjen pÜ funnet posisjon.
        mov     si, OFFSET tmplin
        add     di, OFFSET command_list
        mov     cx, dx
        cld
        rep     movsb

    ; Marker slutten pÜ lista.
        xor     ax, ax
        stosw

    ; Oppdater variabler.
        inc     [next_com]
        mov     ax, [next_com]
        mov     [curr_com], ax

  @@ret:
        ret
ENDP    store_line



;
; edit_line
;
; Hva prosedyren gjõr:
;   Lar brukeren editere linjen tmplin, i den posisjonen, og den lengden
;   som er funnet av get_screen_info. Linjens maksimale lengde er tidligere
;   bestemt pÜ grunnlag av data fra kalleren.
;   linlen er hele tiden oppdatert.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt
;
PROC    edit_line

    ; Sjekk om det skal skrives direkte til skjermminnet. Hvis det skal det,
    ; dvs. at skjermen er i tekstmode, brukes DOSED. Hvis ikke, kalles den
    ; gamle interruptrutinen.
        cmp     [direct], 0
        jne     @@textmode

    ; Det er ikke tekstmode. Bruk den orginale rutinen.
        mov     dx, OFFSET maxlen
        mov     ah, 0Ah
        pushf
        call    [DWORD FAR old_id_int]
        ret

  @@textmode:
        mov     [PrevKey], 0

    ; Det er tekstmode. Sett riktig markõr.
        mov     al, [stdmode]
        mov     [insmode], al
        call    set_correct_cursor

  @@edit_line_loop:
    ; Her er lõkken som gÜr helt til innlesning av linjen er ferdig.
    ; Vis fõrst riktig del av linjen pÜ nÜvërende form.
        call    show_line

  @@no_key_waiting:
    ; Mens det ventes pÜ tastetrykk, kalles INT 28h. Dette
    ; gjõr MS-DOS, og mange TSR's er avhengig av at det gjõres.
        int     28h

    ; Finn ut om det er noe i keyboard-bufferet.
        mov     ah, 1
        int     16h
        jz      @@no_key_waiting

    ; Sjekk om tasten som ligger i bufferet er Ctrl-P eller Ctrl-C.
    ; IsÜfall skal tegnet _tolkes_ av DOS (cooked) sÜ printeren slÜs pÜ/av,
    ; evt. programmet avbrytes.
    ; Hvis ikke skal tegnet leses raw.
    ; Anta fõrst at tegnet skal leses cooked.
        mov     ah, 8           ; Character Input Without Echo
        cmp     al, 'C' - 'A' + 1
        je      @@read_key
        cmp     al, 'P' - 'A' + 1
        jne     @@read_key_raw
        cmp     [SkipCtrlP], 0  ; Skip Ctrl-P printer echo in Emacs-mode.
        je      @@read_key

  @@read_key_raw:
    ; Tegnet skal leses raw.
        mov     ah, 7           ; Unfiltered Character Input Without Echo

  @@read_key:
    ; Kall gammelt INT 21h. Dette kan gjõres direkte sÜ lenge
    ; funksjonen ikke er 0Ah.
        int     21h

    ; Hvis tasten som ble trykket var Ctrl-C, kommer vi ikke hit.

    ; Sjekk hvilken tast som er trykket. Tolk evt extended ASCII-taster,
    ; Hvis AL=0, er en spesialtast trykket.
        or      al, al
        jnz     @@normal_key

    ; Siden det var en extended key, leses et tegn til for Ü
    ; fÜ koden til denne.
        mov     ah, 7           ; Unfiltered Character Input Without Echo
        int     21h

    ; SlÜ opp i tabellen over extended keys, og sjekk om denne finnes.
        mov     di, OFFSET exp_keys
        mov     cx, NUMKEYS
        cld
        repne   scasb
        jne     @@edit_line_loop

    ; Tasten finnes. Kall prosedyren som utfõrer det som õnskes.
        sub     di, 1 + OFFSET exp_keys

  @@call_proc:
        shl     di, 1
        add     di, OFFSET key_commands
        push    ax
        call    [WORD di]
        pop     ax
        mov     [PrevKey], al
        jmp     SHORT @@corr_pos

  @@normal_key:
    ; Sjekk om tasten finnes i listen over kontroll-komandoer.
        mov     di, OFFSET ctrl_keys
        mov     cx, NUMKEYS
        cld
        repne   scasb
        jne     @@not_wordstar_key

    ; En kontrollkode er trykket. Kall riktig prosedyre.
        sub     di, 1 + OFFSET ctrl_keys
        jmp     @@call_proc

  @@not_wordstar_key:
    ; Sjekk om det kan vëre return
        cmp     al, 13
        je      @@ret

    ; Tegnet skal lagres.
        call    store_character
        mov     [PrevKey], al

  @@corr_pos:
    ; Her skal evt ny pos vëre funnet, og det er derfor nõdvendig Ü sjekke
    ; om from skal endres slik at nÜvërende posisjon er innenfor linjen.
        mov     ax, [pos]
        sub     ax, [from]
        js      @@outside_left
        cmp     ax, [visible_chr]
        jb      @@not_outside

  @@outside_right:
    ; Ny posisjon er utenfor hõyre side av skjermen. Legg til
    ; riktig antall pÜ from.
        sub     ax, [visible_chr]
        inc     ax
        add     [from], ax
        jmp     SHORT @@pos_corrected

  @@outside_left:
    ; Ny posisjon er utenfor venstre side av skjermen. Trekk fra
    ; riktig antall fra from.
        neg     ax
        sub     [from], ax

  @@pos_corrected:
    ; from er rettet pÜ. Gjõr det mulig Ü sette riktig markõrposisjon.
        mov     ax, [pos]
        sub     ax, [from]

  @@not_outside:
    ; SÜ settes markõren pÜ riktig sted. AL mÜ inneholde avstanden i X-
    ; retningen fra markõrens utgangsposisjon.
        mov     ah, 2           ; Set Cursor Position
        mov     dl, [curx]
        add     dl, al
        mov     dh, [cury]
        mov     bh, [scr_page]
        int     10h

    ; Les flere tegn.
        jmp     @@edit_line_loop

  @@ret:
    ; Fõr det returneres, sõrges det for at markõren blir normal, slik at
    ; et evt startet program ikke fÜr stor markõr.
        mov     al, [stdmode]
        mov     [insmode], al
        call    set_correct_cursor

        ret
ENDP    edit_line



;
; build_line
;
; Hva prosedyren gjõr:
;   Bygger opp den orginale linjens data vha tmplin.
;   Setter ogsÜ ASCII 13 pÜ slutten av linjen.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt, ogsÜ ES
;
PROC    build_line

    ; Kopier tmplin sÜ den blir pÜ formen MS-DOS bruker.
        les     di, [DWORD loff]
        mov     si, OFFSET maxlen
        mov     cl, [linlen]
        xor     ch, ch
        inc     cx                      ; Legg til: maxlen, linlen
        inc     cx
        cld
        rep     movsb

    ; Legg til CR
        mov     al, 13
        stosb

        ret
ENDP    build_line



;
; send_to_stdout
;
; Hva prosedyren gjõr:
;   Viser linjen ved Ü sende den til STDOUT. PÜ denne mÜten oppnÜs to ting:
;     * Hvis printing er pÜ, sendes den endelige linjen ogsÜ til skriver.
;     * Redirigering og piping virker skikkelig.
;     * Linjen vises om nõdvendig over flere linjer.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Alt
;
PROC    send_to_stdout

    ; Vis fõrst linjen pÜ vanlig mÜte, slik at den evt. blir blanket
    ; hvis Esc eller Ctrl-C er trykket.
        call    show_line

    ; Plasser markõren riktig.
        mov     ah, 2                   ; Set Cursor Position
        mov     dl, [curx]
        mov     dh, [cury]
        mov     bh, [scr_page]
        int     10h

    ; Vis linjen pÜ stdout
        mov     ah, 40h                 ; Write File or Device
        mov     bx, 1                   ; stdout
        mov     cl, [linlen]
        xor     ch, ch
        mov     dx, OFFSET tmplin
        int     21h

    ; Vis ogsÜ Carriage Return.
        mov     ah, 2                   ; Character Output
        mov     dl, 13
        int     21h

        ret
ENDP    send_to_stdout



;
; id_int
;
; Hva prosedyren gjõr:
;   Dette er en interruptprosedyre som ikke skal kalles direkte.
;   Denne installeres med det nummeret som er angitt i IDINT,
;   og det er denne som mottar spõrsmÜl om programmet er installert.
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
PROC    id_int  FAR

        sti
    ; Sjekk om det kan vëre spõrsmÜl om programmet er installert
        cmp     ah, IDFUNC
        je      @@test_installed

  @@test_enabled:
    ; Sjekk om programmet er enabled
        cmp     [cs: enabled], 0
        jz      @@jmp_old

    ; Her legges koden interruptrutinen skal utfõre inn.

        cmp     ah, 0Ah                 ; Er det innlesing av linje?
        jne     @@jmp_old

        push    ax
        push    bx
        push    cx
        push    dx
        push    es
        push    ds
        push    si
        push    di

    ; Finn ut hva brukeren har angitt om linjen. Maks lengde osv.
        call    get_line_info

    ; Finn nõdvendig skjermdata, bla. adressen til fõrste tegn i linjen.
        call    get_screen_info

    ; Utfõr selve linjeediteringen.
        call    edit_line

    ; Oppdater history-listen
        call    store_line

    ; Vis linjen ved Ü sende tegn til stdout, slik at den evt. vises
    ; pÜ skriver eller havner i fil hvis output er redirigert.
        call    send_to_stdout

    ; Possibly remove any trailing backslashes, since many commands
    ; don't like them.
        cmp     [DoRmBkslsh], 0
        je      @@after_rmslsh
        call    RemoveBackslashes
  @@after_rmslsh:

    ; Kopier den midlertidige linjen til brukerens buffer
        call    build_line

        pop     di
        pop     si
        pop     ds
        pop     es
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        iret


  @@jmp_old:
    ; Hopp til orginal rutine
        jmp     [DWORD FAR cs: old_id_int]

  @@test_installed:
    ; Sjekk om det virkelig er spõrsmÜl om programmet er installert.
    ; Det er det hvis DS:SI peker til det samme som ASCIIZ-stringen
    ; idstring.
        push    si
        push    di
        push    es

        push    cs
        pop     es
        mov     di, OFFSET idstring
        cld

  @@more_left:
        cmpsb
        jne     @@not_request
        cmp     [BYTE si - 1], 0
        jnz     @@more_left

    ; Her er det funnet at det er spõrsmÜl om programmet er installert.
    ; Returner med ES:DI som peker til idstring.
        mov     di, OFFSET idstring
        add     sp, 4
        pop     si
        iret

  @@not_request:
    ; Det var allikevel ikke spõrsmÜl om programmet er installert.
    ; Hopp opp for test om interruptet skal utfõres.
        pop     es
        pop     di
        pop     si
        jmp     @@test_enabled

ENDP    id_int





;==========================================================================

; Her vil kommandoene komme til Ü ligge etter at programmet er insallert.
; Hver kommando lagres som ASCIIZ-string. To nuller etter hverandre markerer
; slutten pÜ listen.
; De to nullene er for Ü sõrge for at listen er tom nÜr programmet startes.

LABEL   command_list BYTE
        DB         0, 0





;==========================================================================

LABEL   not_resident    BYTE
    ; Det som fõlger her er data og prosedyrer som brukes av
    ; initialiseringsrutinen, og som dermed ikke trenger Ü
    ; legges resident.



;==========================================================================

    ; Data som brukes av den ikke-residente delen av programmet

argc        DW  0               ; Antall parametre pÜ kommandolinjen
argv        DW  MAXPARA DUP (0) ; Adressene til parametrene
            DW  5328h, 4848h, 29h ; Magic

currarg     DW  0               ; NÜvërende parameter under tolking av
                                ; kommandolinjen. Kan endres av evt. prosedyrer
                                ; for utfõring av kommandoer.
argoffs     DW  0               ; NÜvërende offset inn i nÜvërende parameter.

crlf        DB  13, 10, 0       ; Brukes i meldinger
colon       DB  ": ", 0         ;      -- " --

TmpIntStr   DB  6 DUP (0)       ; ASCII characters in integer when printing it.

quiet       DB  0               ; Skal ikke meldinger vises?

installed   DB  0               ; Er programmet allerede installert?
segmaddr    DW  0               ; Segmentadresse for evt. tidligere resident
                                ; versjon av programmet, eller denne hvis
                                ; ikke installert fra fõr.
exitfunc    DW  4C00h           ; Funksjon som skal avslutte programmet.
res_size    DW  0               ; Antall paragrafer som legges resident.

LABEL   WordStarKeys BYTE
    ; Default control-keys: WordStar-like.
            DB  9, 26
            DB  22, 19, 4, 1, 6
            DB  0, 0, 8, 7
            DB  5, 24, 17, 25, 27
            DB  0, 0

LABEL   EmacsKeys BYTE
    ; Optional control-keys: Emacs-like.
            DB  9, 26
            DB  0, 2, 6, 0, 0
            DB  1, 5, 8, 4
            DB  16, 14, 11, 21, 27
            DB  0, 0

    ; Liste over lovlige kommandoer som ASCIIZ-strenger.
    ; Avsluttes med en 0.
    ; Hvis en av disse blir funnet, vil tilsvarende prosedyre
    ; i procedure-tabellen kalles.
commands    DB  "?",   0
            DB  "B-",  0
            DB  "B",   0
            DB  "D-",  0
            DB  "D",   0
            DB  "E-",  0
            DB  "E",   0
            DB  "H",   0
            DB  "I-",  0
            DB  "I",   0
            DB  "L-",  0
            DB  "L",   0
            DB  "M",   0
            DB  "OFF", 0
            DB  "Q",   0
            DB  "R-",  0
            DB  "R",   0
            DB  "S-",  0
            DB  "S",   0
            DB  "U",   0
            DB         0

procedures  DW  OFFSET show_help
            DW  OFFSET SetBeepOff
            DW  OFFSET SetBeepOn
            DW  OFFSET SetDirDelimOn
            DW  OFFSET SetDirDelimOff
            DW  OFFSET SetWordStarKeys
            DW  OFFSET SetEmacsKeys
            DW  OFFSET show_help
            DW  OFFSET SetInsDefOff
            DW  OFFSET SetInsDefOn
            DW  OFFSET SetLowerCaseOff
            DW  OFFSET SetLowerCaseOn
            DW  OFFSET SetMinChars
            DW  OFFSET turn_off
            DW  OFFSET do_quiet
            DW  OFFSET SetRmBkslshOff
            DW  OFFSET SetRmBkslshOn
            DW  OFFSET SetSkipBakOff
            DW  OFFSET SetSkipBakOn
            DW  OFFSET uninstall


  id_line   DB  PRGNAME, " ", PRGVER, "  --  (C) ", PRGDATE
            DB  " - Sverre H. Huseby, Norway.    ", PRGNAME, " -? for help."
            DB  13, 10, 10
IFDEF BETA
            DB  "    This is a BETA-version. See the file BETA.TXT for "
            DB      "details.", 13, 10
            DB  "    Should not be used longer than 3 months after the "
            DB       "above date.", 13, 10
            DB  10
ENDIF
            DB  0

  usage     DB  "* Commandline editor. Use left, right, home, end etc.", 13, 10
            DB  "* Historyfunction. Press up or down to cycle through commands."
            DB  13, 10
            DB  "* Filename completion. Press Tab. A second Tab lists all matches."
            DB  13, 10
            DB  10
            DB  "Usage: ", PRGNAME, " [options]", 13, 10, 10
            DB  "       Options:", 13, 10
            DB  "         -b   Beep when filename is incomplete.", 13, 10
            DB  "         -d   Disable appending '\' to directory names."
            DB                 13, 10
            DB  "         -e   Use Emacs-like control keys.", 13, 10
            DB  "         -i   Make 'Insert on' default.", 13, 10
            DB  "         -l   Lowercase letters in completed filenames."
            DB                 13, 10
            DB  "         -m   Min. number of character for stored lines. Default: -m3"
            DB          13, 10
            DB  "         -off Temporarily disable program. "
            DB                 "Enable with ", PRGNAME, ".", 13, 10
            DB  "         -q   Quiet. Supress messages. ", 13, 10
            DB  "         -r   Remove trailing backslashes (default).", 13, 10
            DB  "         -s   Skip .BAK-files when completing (default).", 13, 10
            DB  "         -u   Uninstall if possible.", 13, 10
            DB  10
            DB  "Append `-' to disable previously enabled options.", 13, 10
            DB  0

  On        DB  "On", 0
  Off       DB  "Off", 0
  BeepIs    DB  "    Beep when filename completion is incomplete is ", 0
  DirDelmIs DB  "    Appending of '\' to directorynames is ", 0
  EmacsIs   DB  "    Use Emacs-like control keys instead of WordStar-like is "
            DB  0
  InsertIs  DB  "    Use 'Insert on' as default is ", 0
  LCaseConv DB  "    Convert characters in completed filenames to lowercase is "
            DB  0
  RmTrSlsh  DB  "    Remove trailing backslashes is ", 0
  SkpBak    DB  "    Skip .BAK-files when completing is ", 0
  MinChrAre DB  "    Minimum number of characters in stored lines are ", 0
  disabled  DB  "    The program is temporarily disabled. "
            DB       "Enable with ", PRGNAME, ".", 13, 10, 0
  now_inst  DB  "    The program is now installed.", 13, 10, 0
  uninst    DB  "    The program is removed from memory.", 13, 10, 0

  toomany   DB  "Too many options given.", 0
  unknown   DB  "Unknown option.", 0
  missquote DB  "Missing end-quote.", 0
  uninsterr DB  "Can't uninstall.", 0
  IntExp    DB  "Missing or incorrect number.", 0
  DiffVer   DB  "A different version of ", PRGNAME, " is already running. "
            DB  "Can't continue!", 13, 10, 0



;==========================================================================

    ; Prosedyrer som brukes av den ikke-residente delen av programmet



;--------------------------------------------------------------------------
;
;   NAME:           DisplaySettings
;
;   DESCRIPTION:    Displays what the current settings are.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    DisplaySettings

        mov     es, [segmaddr]

        mov     dx, OFFSET BeepIs
        call    print
        mov     bx, OFFSET DoBeep
        call    PrintOnOff
        call    PrintCrLf

        mov     dx, OFFSET DirDelmIs
        call    print
        mov     bx, OFFSET DirDelim
        call    PrintOnOff
        call    PrintCrLf

        mov     dx, OFFSET EmacsIs
        call    print
        mov     bx, OFFSET SkipCtrlP
        call    PrintOnOff
        call    PrintCrLf

        mov     dx, OFFSET InsertIs
        call    print
        mov     bx, OFFSET stdmode
        call    PrintOnOff
        call    PrintCrLf

        mov     dx, OFFSET LCaseConv
        call    print
        mov     bx, OFFSET LowerCase
        call    PrintOnOff
        call    PrintCrLf

        mov     dx, OFFSET MinChrAre
        call    print
        mov     al, [es: MinChars]
        call    PrintInt
        call    PrintCrLf

        mov     dx, OFFSET RmTrSlsh
        call    print
        mov     bx, OFFSET DoRmBkslsh
        call    PrintOnOff
        call    PrintCrLf

        mov     dx, OFFSET SkpBak
        call    print
        mov     bx, OFFSET DoSkipBak
        call    PrintOnOff
        call    PrintCrLf

        call    PrintCrLf

  @@ret:
        ret

ENDP    DisplaySettings





;--------------------------------------------------------------------------
;
;   NAME:           SetDefaults
;
;   DESCRIPTION:    Set default options in this instance of the program.
;                   Will thus only have effect if this is the instance that
;                   gets resident.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    SetDefaults

    ; 'Insert off'
        mov     [stdmode], OVERWRT

    ; Default minimum number of characters for stored lines:
        mov     [MinChars], 3

        xor     ax, ax

    ; Do not convert completed filename characters to lowercase.
        mov     [LowerCase], al

    ; Use '\' to delimit directories in filename completion.
        mov     [DirDelim], 1

    ; Do not beep for matches that are not complete.
        mov     [DoBeep], al

    ; Remove trailing backslashes.
        mov     [DoRmBkslsh], 1

    ; Skip .bak-files when completing.
        mov     [DoSkipBak], 1

    ; and use WordStar-like control keys.
        mov     [SkipCtrlP], al
        push    ds
        pop     es
        mov     di, OFFSET ctrl_keys
        mov     si, OFFSET WordStarKeys
        mov     cx, NUMKEYS
        cld
        rep     movsb

  @@ret:
        ret

ENDP    SetDefaults





;
; turn_off
;
; Hva prosedyren gjõr:
;   Deaktiviserer programmet ved Ü sette status til 0.
;   Segmentadressen til kjõrende program, eller dette programmet
;   mÜ vëre funnet og ligge i segmaddr.
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
PROC    turn_off
        push    dx
        push    es

        mov     es, [segmaddr]
        mov     [es: enabled], 0

        mov     dx, OFFSET disabled
        call    print

    ; Now we probably won't need to see all the settings.
        mov     [quiet], 1

        pop     es
        pop     dx
        ret
ENDP    turn_off



;
; SetInsDefOn
;
; Hva prosedyren gjõr:
;   Setter insert on som default.
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
PROC    SetInsDefOn
        push    es

        mov     es, [segmaddr]
        mov     [es: stdmode], INSERT

        pop     es
        ret
ENDP    SetInsDefOn





;
; SetInsDefOff
;
; Hva prosedyren gjõr:
;   Setter insert on som ikke default.
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
PROC    SetInsDefOff
        push    es

        mov     es, [segmaddr]
        mov     [es: stdmode], OVERWRT

        pop     es
        ret
ENDP    SetInsDefOff





;--------------------------------------------------------------------------
;
;   NAME:           SetMinChars
;
;   DESCRIPTION:    Sets minimum number of characters in a line before
;                   it is stored in the history buffer.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    SetMinChars

        push    dx
        push    es

        call    GetIntParam

        mov     es, [segmaddr]
        mov     [es: MinChars], al

        pop     es
        pop     dx
        ret

ENDP    SetMinChars





;--------------------------------------------------------------------------
;
;   NAME:           SetDirDelimOn
;
;   DESCRIPTION:    Enables automatic '\' when completing directory names.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    SetDirDelimOn

        push    es

        mov     es, [segmaddr]
        mov     [es: DirDelim], 1

        pop     es
        ret

ENDP    SetDirDelimOn





;--------------------------------------------------------------------------
;
;   NAME:           SetDirDelimOff
;
;   DESCRIPTION:    Disables automatic '\' when completing directory names.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    SetDirDelimOff

        push    es

        mov     es, [segmaddr]
        mov     [es: DirDelim], 0

        pop     es
        ret

ENDP    SetDirDelimOff





;--------------------------------------------------------------------------
;
;   NAME:           SetBeepOn
;
;   DESCRIPTION:    Enables beep when incomplete filename completion.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    SetBeepOn

        push    es

        mov     es, [segmaddr]
        mov     [es: DoBeep], 1

        pop     es
        ret

ENDP    SetBeepOn





;--------------------------------------------------------------------------
;
;   NAME:           SetBeepOff
;
;   DESCRIPTION:    Disables beep when incomplete filename completion.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    SetBeepOff

        push    es

        mov     es, [segmaddr]
        mov     [es: DoBeep], 0

        pop     es
        ret

ENDP    SetBeepOff





;--------------------------------------------------------------------------
;
;   NAME:           SetLowerCaseOn
;
;   DESCRIPTION:    Enables conversion of completed filename character
;                   to lowercase.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    SetLowerCaseOn

        push    es

        mov     es, [segmaddr]
        mov     [es: LowerCase], 1

        pop     es
        ret

ENDP    SetLowerCaseOn





;--------------------------------------------------------------------------
;
;   NAME:           SetLowerCaseOff
;
;   DESCRIPTION:    Disables conversion of completed filename character
;                   to lowercase.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    SetLowerCaseOff

        push    es

        mov     es, [segmaddr]
        mov     [es: LowerCase], 0

        pop     es
        ret

ENDP    SetLowerCaseOff





;--------------------------------------------------------------------------
;
;   NAME:           SetRmBkslshOn
;
;   DESCRIPTION:    Enables removal of trailing backslashes.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    SetRmBkslshOn

        push    es

        mov     es, [segmaddr]
        mov     [es: DoRmBkslsh], 1

        pop     es
        ret

ENDP    SetRmBkslshOn





;--------------------------------------------------------------------------
;
;   NAME:           SetRmBkslshOff
;
;   DESCRIPTION:    Disables removal of trailing backslashes.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    SetRmBkslshOff

        push    es

        mov     es, [segmaddr]
        mov     [es: DoRmBkslsh], 0

        pop     es
        ret

ENDP    SetRmBkslshOff





;--------------------------------------------------------------------------
;
;   NAME:           SetSkipBakOn
;
;   DESCRIPTION:    Enables skipping .bak-files when completing.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    SetSkipBakOn

        push    es

        mov     es, [segmaddr]
        mov     [es: DoSkipBak], 1

        pop     es
        ret

ENDP    SetSkipBakOn





;--------------------------------------------------------------------------
;
;   NAME:           SetSkipBakOff
;
;   DESCRIPTION:    Disables skipping .bak-files when completing.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    SetSkipBakOff

        push    es

        mov     es, [segmaddr]
        mov     [es: DoSkipBak], 0

        pop     es
        ret

ENDP    SetSkipBakOff





;--------------------------------------------------------------------------
;
;   NAME:           SetEmacsKeys
;
;   DESCRIPTION:    Copies the Emacs key subset to the control key table.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    SetEmacsKeys

        push    cx
        push    di
        push    si
        push    es

        mov     es, [segmaddr]
        mov     di, OFFSET ctrl_keys
        mov     si, OFFSET EmacsKeys
        mov     cx, NUMKEYS
        cld
        rep     movsb

    ; Ctrl-P has special meaning in Emacs. Dont start printer echo for it!
        mov     [es: SkipCtrlP], 1

        pop     es
        pop     si
        pop     di
        pop     cx
        ret

ENDP    SetEmacsKeys





;--------------------------------------------------------------------------
;
;   NAME:           SetWordStarKeys
;
;   DESCRIPTION:    Copies the WordStar key subset to the control key table.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    SetWordStarKeys

        push    cx
        push    di
        push    si
        push    es

        mov     es, [segmaddr]
        mov     di, OFFSET ctrl_keys
        mov     si, OFFSET WordStarKeys
        mov     cx, NUMKEYS
        cld
        rep     movsb

    ; Ctrl-P has no special meaning in WordStar.
    ; Start printer echo for it!
        mov     [es: SkipCtrlP], 0

        pop     es
        pop     si
        pop     di
        pop     cx
        ret

ENDP    SetWordStarKeys





;
; do_quiet
;
; Hva prosedyren gjõr:
;   SlÜr av visning av meldinger
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
PROC   do_quiet
       mov     [quiet], 1
       ret
ENDP   do_quiet



;
; show_help
;
; Hva prosedyren gjõr:
;   Viser hva programmet gjõr, og hvordan det brukes.
;
;   !!! OBS OBS OBS !!!   Returnerer direkte til operativsystemet.
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
PROC    show_help

    ; Sõrg for at hjelpeteksten helt sikkert vises.
        mov     [quiet], 0

    ; Vis hjelpeteksten
        mov     dx, OFFSET usage
        call    print

    ; Avslutt programmet etter at hjelpen er vist.
        mov     ax, 4C00h
        int     21h

    ; Hit kommer vi aldri

ENDP    show_help



;
; unknown_para
;
; Hva prosedyren gjõr:
;   Utfõrer det som skal gjõres nÜr en ikke fastsatt parameter er angitt.
;   Dette kan feks. vëre Ü lagre et filnavn ell.
;   I rammeprogrammet, avbrytes programmet med en feilmelding, siden
;   det ikke finnes ikke faste parametre.
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
PROC    unknown_para

        mov     dx, OFFSET unknown
        call    fatal

    ; Hit kommer vi aldri.

ENDP    unknown_para



;
; install
;
; Hva prosedyren gjõr:
;   Installerer interruptvektorer. Programmet mÜ ikke
;   vëre installert fra fõr.
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
PROC    install
        push    ax
        push    bx
        push    dx
        push    es

    ; Installer interruptet som mottar spõrsmÜl om installert.
        mov     ax, 3500h + IDINT       ; Get Interrupt Vector
        int     21h
        mov     [WORD old_id_int + 0], bx
        mov     [WORD old_id_int + 2], es

        mov     ah, 25h                 ; Set Interrupt Vector
        mov     dx, OFFSET id_int
        int     21h

    ; Vis melding om at programmet er installert.
        mov     dx, OFFSET now_inst
        call    print

        pop     es
        pop     dx
        pop     bx
        pop     ax
        ret
ENDP    install



;
; uninstall
;
; Hva prosedyren gjõr:
;   Forsõker Ü deinstallere programmet. For at det skal vëre mulig, mÜ
;   ingen andre residente programmer ha overtatt de samme interrupt-
;   vektorene. Dette sjekkes fõrst.
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
PROC    uninstall
        push    ax
        push    bx
        push    dx
        push    es

    ; Sjekk aller fõrst at programmet virkelig er installert.
        cmp     [installed], 0
        jnz     @@test_vectors

  @@cant_uninstall:
    ; Av en eller annen grunn kan ikke programmet deinstalleres.
    ; Avbryt med en feilmelding.
        mov     dx, OFFSET uninsterr
        call    fatal

    ; Kommer aldri hit.

  @@test_vectors:
    ; Sjekk om interruptvektorene fortsatt peker til det installerte prog.
        mov     ax, 3500h + IDINT       ; Get Interrupt Vector
        int     21h
        mov     ax, es
        cmp     [segmaddr], ax
        jne     @@cant_uninstall
        cmp     bx, OFFSET id_int
        jne     @@cant_uninstall

    ; Her skal evt. andre interrupt sjekkes.



  @@uninstall_vectors:
    ; Sett interruptvektorene til det som er angitt i de gamle variablene.
    ; ES peker nÜ til segmentet hvor det installerte programmet ligger.
        push    ds

        mov     ax, 2500h + IDINT       ; Set Interrupt Vector
        mov     dx, [WORD es: old_id_int + 0]
        mov     ds, [WORD es: old_id_int + 2]
        int     21h

    ; Her skal evt. andre interrupt resettes. Merk at DS ikke peker
    ; til nÜvërende segment!



        pop     ds

  @@free_memory:
    ; Her frigjõres minne som er brukt av det installerte programmet.
IFNDEF FREENV
        push    es
        mov     ah, 49h         ; Release Memory Block
        mov     es, [es: envseg]
        int     21h
        pop     es
ENDIF

        mov     ah, 49h         ; Release Memory Block
        int     21h

    ; Vis melding om at programmet er fjernet fra minnet.
        mov     dx, OFFSET uninst
        call    print

    ; Marker at programmet ikke lenger er installert
;        mov     [installed], 0
;        mov     [segmaddr], cs
;        mov     [exitfunc], 4C00h

    ; Exit the program
        mov     ax, 4C00h
        int     21h

    ; Never get here...

        pop     es
        pop     dx
        pop     bx
        pop     ax
        ret
ENDP    uninstall



;
; strlen
;
; Hva prosedyren gjõr:
;   Finner lengden pÜ en ASCIIZ-string (uten 0'en, selvsagt)
;
; Kall med:
;   DX - peker til strengen
;
; Returnerer:
;   AX - lengden pÜ strengen
;
; Endrer innholdet i:
;   AX
;
PROC    strlen
        push    cx
        push    di
        push    es

        mov     ax, ds
        mov     es, ax

        mov     di, dx

        xor     al, al       ; Let etter 0'en
        mov     cx, 0FFFFh   ; Sõk et helt segment om nõdvendig
        cld
        repne   scasb

        mov     ax, di
        dec     ax
        sub     ax, dx

        pop     es
        pop     di
        pop     cx
        ret
ENDP    strlen



;
; print
;
; Hva prosedyren gjõr:
;   Viser en ASCIIZ-string pÜ stdout.
;
; Kall med:
;   DX - peker til strengen
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    print
        push    ax
        push    bx
        push    cx

        cmp     [quiet], 0
        jnz     @@ret

        call    strlen
        mov     cx, ax
        mov     ah, 40h         ; Write File or Device
        mov     bx, 1           ; stdout
        int     21h

  @@ret:
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    print





;--------------------------------------------------------------------------
;
;   NAME:           PrintCrLf
;
;   DESCRIPTION:    Output a newline.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    PrintCrLf

        push    dx

        mov     dx, OFFSET crlf
        call    print

        pop     dx
        ret

ENDP    PrintCrLf





;--------------------------------------------------------------------------
;
;   NAME:           PrintOnOff
;
;   DESCRIPTION:    Display `on' or `off' according to the byte found at
;                   location ES:BX
;
;   PARAMETERS:     ES:BX   Pointer to `boolean' byte.
;
;   RETURNS:        Nothing
;
;
PROC    PrintOnOff

        push    dx

        mov     dx, OFFSET On
        cmp     [BYTE es: bx], 0
        jne     @@print_it
        mov     dx, OFFSET Off
  @@print_it:
        call    print

        pop     dx
        ret

ENDP    PrintOnOff





;--------------------------------------------------------------------------
;
;   NAME:           PrintInt
;
;   DESCRIPTION:    Print an integer.
;
;   PARAMETERS:     AX   Integer to print.
;
;   RETURNS:        Nothing
;
;
PROC    PrintInt

        push    ax
        push    cx
        push    dx
        push    di

        mov     di, OFFSET TmpIntStr + 5

  @@more_left:
        dec     di
        xor     dx, dx
        mov     cx, 10
        div     cx
        add     dl, '0'
        mov     [di], dl
        or      ax, ax
        jnz     @@more_left

        mov     dx, di
        call    print

  @@ret:
        pop     di
        pop     dx
        pop     cx
        pop     ax

        ret

ENDP    PrintInt





;
; printerr
;
; Hva prosedyren gjõr:
;   Viser en ASCIIZ-string pÜ stderr.
;
; Kall med:
;   DX - peker til strengen
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    printerr
        push    ax
        push    bx
        push    cx

        call    strlen
        mov     cx, ax
        mov     ah, 40h         ; Write File or Device
        mov     bx, 2           ; stderr
        int     21h

        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    printerr



;
; fatal
;
; Hva prosedyren gjõr:
;   Viser en feilmelding pÜ stderr og avbryter programmet.
;
;   OBS OBS!   MÜ ikke kalles etter at noen interruptvektorer er overtatt !!!
;
; Kall med:
;   DX - peker til feilmelding
;
; Returnerer:
;   Aldri
;
; Endrer innholdet i:
;   Ingenting
;
PROC    fatal

    ; Vis fõrst crlf, navnet pÜ programmet, og kolon.
        push    dx

        mov     dx, OFFSET crlf
        call    printerr

        mov     dx, OFFSET idstring
        call    printerr

        mov     dx, OFFSET colon
        call    printerr

        pop     dx

    ; Vis sÜ feilmeldingen
        call    printerr

    ; og ny crlf
        mov     dx, OFFSET crlf
        call    printerr

    ; Avbryt programmet med exitcode = -1
        mov     ax, 4CFFh
        int     21h

    ; Hit kommer vi aldri !

ENDP    fatal





;--------------------------------------------------------------------------
;
;   NAME:           GetIntParam
;
;   DESCRIPTION:    Gets a 16 bit (unsigned) integer value from the current
;                   position in the command line. If an illegal value is
;                   encountered, the program is aborted.
;
;   PARAMETERS:     None
;
;   RETURNS:        AX   Integer found.
;
;
PROC    GetIntParam

        push    cx
        push    dx
        push    di

    ; Get current position within current argument.
        mov     di, [currarg]
        shl     di, 1
        mov     di, [argv + di]
        add     di, [argoffs]

    ; Check if at least one digit is present.
        mov     cl, [di]
        cmp     cl, '0'
        jb      @@error
        cmp     cl, '9'
        ja      @@error

    ; Collect a number until a non-digit is found.
        xor     ax, ax
        xor     ch, ch

  @@add_digit:
        mov     dx, 10
        mul     dx
        sub     cl, '0'
        add     ax, cx

        inc     [argoffs]
        inc     di
        mov     cl, [di]
        or      cl, cl
        jz      @@ret

        cmp     cl, '0'
        jb      @@error
        cmp     cl, '9'
        ja      @@error

        jmp     @@add_digit

  @@error:
        mov     dx, OFFSET IntExp
        call    fatal

    ; We never get here.

  @@ret:
        pop     di
        pop     dx
        pop     cx
        ret

ENDP    GetIntParam





;
; get_params
;
; Hva prosedyren gjõr:
;   Deler opp kommandolinjen i angitte parametre, slik at hver av
;   dem blir en ASCIIZ-string, og ingen begynner eller slutter med
;   blanke. Oppdaterer argc og argv, men disse regner ikke med at
;   programnavnet er nummer 0 i arrayen slik som det gjõres i C.
;   Tekst mellom evt. anfõrselstegn bevares som den er, mens annen
;   tekst oversettes til store bokstaver.
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
PROC    get_params
        push    ax
        push    bx

    ; Start pÜ begynnelsen av kommandolinjen, og let til CR er funnet.
        mov     bx, 81h
        mov     al, [bx]

  @@more_left:
    ; Sjekk om slutten pÜ linjen er nÜdd.
        cmp     al, 13
        je      @@no_more

  @@skip_blank:
    ; Skip evt. blanke fõr en parameter
        cmp     al, ' '
        jne     @@found_one
        inc     bx
        mov     al, [bx]
        jmp     @@skip_blank

  @@found_one:
    ; Funnet noe som ikke er blank. Sjekk om linjeslutt.
        cmp     al, 13
        je      @@no_more

    ; Sjekk om anfõrselstegn.
        cmp     al, '"'
        jne     @@store_address

  @@quote_found:
    ; Anfõrselstegn er funnet. Sett pekeren til tegnet etter, og
    ; let til avsluttende anfõrselstegn er funnet.
        mov     ax, bx
        inc     ax
        mov     bx, [argc]
        cmp     bx, MAXPARA
        jae     @@too_many
        shl     bx, 1
        mov     [argv + bx], ax
        mov     bx, ax
        dec     bx
        inc     [argc]

  @@find_quote:
        inc     bx
        mov     al, [bx]

    ; Sjekk om linjeslutt uten avsluttende anfõrselstegn.
        cmp     al, 13
        je      @@missing_quote

        cmp     al, '"'
        jne     @@find_quote

    ; Overskriv anfõrselstegnet med en 0 for Ü terminere strengen.
        mov     [BYTE bx], 0
        inc     bx
        mov     al, [bx]
        jmp     @@more_left

  @@missing_quote:
    ; Linjeslutt uten avsluttende anfõrselstegn. Avslutt med feilmelding.
        mov     dx, OFFSET missquote
        call    fatal

    ; Kommer aldri hit.

  @@store_address:
    ; Sett nÜvërende adresse inn i argv, og õk argc.
    ; Det mÜ testes at det er lov Ü sette inn flere.
        mov     ax, bx
        mov     bx, [argc]
        cmp     bx, MAXPARA
        jb      @@more_room

    ; Det er ikke plass til flere args. Avbryt med feilmelding.
  @@too_many:
        mov     dx, OFFSET toomany
        call    fatal

    ; Kommer aldri hit.

  @@more_room:
        shl     bx, 1
        mov     [argv + bx], ax
        mov     bx, ax
        inc     [argc]

    ; Flytt forover til blank eller CR er funnet, og oversett til
    ; store bokstaver.
  @@check_character:
        mov     al, [bx]
        cmp     al, ' '
        je      @@end_of_param
        cmp     al, 13
        je      @@end_of_param
        cmp     al, 'a'
        jb      @@move_foreward
        cmp     al, 'z'
        ja      @@move_foreward
        sub     al, 'a' - 'A'
        mov     [bx], al
  @@move_foreward:
        inc     bx
        jmp     @@check_character

  @@end_of_param:
    ; Slutten pÜ en parameter er funnet. Sett inn 0, og let etter mer.
        mov     [BYTE bx], 0
        jmp     @@more_left

  @@no_more:
    ; Ingen flere tegn pÜ kommandolinjen.

        pop     bx
        pop     ax
        ret
ENDP    get_params



;
; do_params
;
; Hva prosedyren gjõr:
;   GÜr gjennom alle parametrene og utfõrer det som ligger i dem.
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
PROC    do_params
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    si
        push    es

        mov     [currarg], 0

  @@do_next:
    ; Sammenlikne nÜvërende parameter med alle lovlige kommandoer
    ; til en som har samme start som parameteren blir funnet.
    ; Sjekk fõrst om det er fler parametre.
        mov     ax, [currarg]
        cmp     ax, [argc]
        jae     @@ret

        mov     si, OFFSET commands
        mov     dx, OFFSET procedures

  @@comp_next_command:
        cmp     [BYTE si], 0
        jz      @@not_found

        mov     di, [currarg]   ; Nummeret til nÜvërende parameter
        shl     di, 1
        mov     di, [argv + di]

    ; All arguments starts with a '-' or a '/'. Nothing else is
    ; recognised, so we check this out first.
        cmp     [BYTE di], '-'
        je      @@start_ok
        cmp     [BYTE di], '/'
        jne     @@not_found

  @@start_ok:
        inc     di              ; Skip '-' or '/'

        cld
  @@comp_next_byte:
        lodsb
        or      al, al
        jz      @@found_match

        cmp     al, [di]
        jne     @@find_next
        inc     di
        jmp     @@comp_next_byte

  @@find_next:
    ; Finn starten pÜ neste kommando i tabellen.
        lodsb
        or      al, al
        jnz     @@find_next

    ; Oppdater peker i prosedyretabellen
        add     dx, 2
        jmp     @@comp_next_command

  @@not_found:
    ; Kommandoen ble ikke funnet i listen over lovlige kommandoer.
        mov     [argoffs], 0
        call    unknown_para
        jmp     SHORT @@advance_to_next

  @@found_match:
    ; Har funnet riktig kommando. DX peker til adressen hvor prosedyrens
    ; adresse er lagret, og DI peker til etter den delen av parameteren
    ; som passet med en lovlig kommando, i tilfelle dette trengs for
    ; Ü finne evt tilleggsopplysninger.
        mov     ax, di
        mov     di, [currarg]
        shl     di, 1
        mov     di, [argv + di]
        sub     ax, di
        mov     [argoffs], ax

        mov     bx, dx
        call    [WORD bx]

  @@advance_to_next:
    ; Sjekk at hele nÜvërende parameter er oppbrukt, og finn neste.
        mov     di, [currarg]
        shl     di, 1
        mov     di, [argv + di]
        add     di, [argoffs]
        cmp     [BYTE di], 0
        jz      @@all_used

    ; Hele nÜvërende parameter er ikke brukt opp. Avbryt med feilmelding.
        mov     dx, OFFSET unknown
        call    fatal

    ; Hit kommer vi aldri.

  @@all_used:
    ; ùk til neste parameter.
        inc     [currarg]
        jmp     @@do_next

  @@ret:
        pop     es
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    do_params



;
; test_installed
;
; Hva prosedyren gjõr:
;   Sjekker om programmet er installert fra fõr, og fyller inn fõlgende
;   variabler:
;       segmaddr:  Segmentadressen til evt. tidligere installert program,
;                  eller til nÜvërende hvis ikke installert fra fõr.
;       exitfunc:  Verdien til AX ved programavslutning. Dette er enten
;                  3100h for TSR, eller 4C00h for normal avslutning,
;                  avhengig av om programmet er installert fra fõr.
;       res_size:  Antall paragrafer som skal legges resident.
;       installed: 1=allerede installert, 0=ikke installert.
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
PROC    test_installed
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    si
        push    es

    ; Anta fõrst at ikke installert tidligere, og legg
    ; nÜvërende segmentadresse inn i segmaddr.
        mov     [segmaddr], cs

    ; Finn antall paragrafer som evt skal legges resident.
        mov     ax, OFFSET not_resident

    ; Her skal evt. flere paragrafer legges til.
        add     ax, BUFSIZ

        mov     cl, 4
        shr     ax, cl
        inc     ax
        mov     [res_size], ax

    ; Kall interruptet for spõrsmÜl om allerede installert
    ; med riktig funksjon, og DS:SI pekende til id-strengen.
        mov     ah, IDFUNC
        mov     si, OFFSET idstring
        int     IDINT

    ; Sjekk om returnert ES:DI peker til samme streng som id-strengen
        mov     si, OFFSET idstring
        cld

  @@more_left:
        cmpsb
        jne     @@not_installed
        cmp     [BYTE si - 1], 0
        jnz     @@more_left

    ; The program is already installed. Save segment of installed instance,
    ; and set up some other variables.
        mov     [segmaddr], es
        mov     [exitfunc], 4C00h
        mov     [installed], 1

    ; Check if the installed instance version is not the same as this one.
        cmp     [WORD es: di], PRGVERI
        je      @@ret

    ; A different version is running. Can not continue.
        mov     dx, OFFSET DiffVer
        call    fatal

    ; Never get here . . .

  @@not_installed:
    ; Programmet er ikke installert fra fõr. Sett opp riktige variabler.
        mov     [exitfunc], 3100h
        mov     [installed], 0

  @@ret:
        pop     es
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    test_installed







;==========================================================================

main:
    ; Her fõlger selve initialiseringsrutinen.

  IFDEF FREENV
    ; Frigjõr environmentet
        mov     ax, [002Ch]     ; Segment address of environment
        or      ax, ax
        jz      @@no_enviro

        mov     es, ax
        mov     ah, 49h         ; Release Memory Block
        int     21h

        mov     [WORD 002Ch], 0

  @@no_enviro:
  ELSE
        mov     ax, [WORD 002Ch]
        mov     [envseg], ax
  ENDIF

    ; Sjekk om installert tidligere, og finn evt. segmentadresse for dette.
        call    test_installed

    ; Sett programmet til enabled. Det skal det alltid vëre nÜr det starter.
        push    es
        mov     es, [segmaddr]
        mov     [es: enabled], 1
        pop     es

    ; Set defaults in this instance.
        call    SetDefaults

    ; Vis identifikasjonslinjen
        mov     dx, OFFSET id_line
        call    print

    ; Finn evt. parametre som er angitt pÜ kommandolinjen.
        call    get_params

    ; Tolk parametrene
        call    do_params

    ; If an uninstall-option was given, we never get here.

        call    DisplaySettings

  @@install_it:
    ; Sjekk om programmet skal installeres.
        cmp     [exitfunc], 3100h
        jnz     @@already_installed

        call    install

  @@already_installed:

exit:
    ; Avslutt programmet enten ved Ü legge det resident,
    ; eller pÜ vanlig mÜte.
        mov     ax, [exitfunc]
        mov     dx, [res_size]
        int     21h


ENDS

        END     start
