        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING



MAXLEN  EQU     256     ; Maks linjelengde, inkludert 0 p† slutten

;--------------------------;
;                          ;
;         D A T A          ;
;                          ;
;--------------------------;

UDATASEG

tmplin  DB      MAXLEN DUP (?)  ; Linjen som editeres.
orgadr  DW      ?               ; Adressen (offset) til orginal linje
keys    DW      ?               ; Adressen til tastene som skal testes
curr    DW      ?               ; N†v‘rende tegn
from    DW      ?               ; Tegnet linjen skal vises fra
length  DW      ?               ; Linjens lengde (uten 0)
maxlen  DW      ?               ; Maks lengde (uten 0)
maxshow DW      ?               ; Antall som vises av gangen.
posxy   DW      ?               ; Linjens f›rste (X, Y)-posisjon p† gotoxy-
                                ; form. (X i AL og Y i AH)
tmpxy   DW      ?               ; Midl. posisjon brukt av showline
retrn   DW      ?               ; Returvariabel for lineinput
attr    DB      ?               ; Attributt etter at teksten er godtatt
oldattr DB      ?               ; For † "huske" attributten som var
ok      DB      ?               ; 0=ikke godtatt enn†, 1=godtatt


DATASEG

        EXTRN   txtattr: BYTE


;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        PUBLIC  initlineinput, endlineinput
        PUBLIC  lineinput

        EXTRN   textattr: PROC, outchar: PROC, getkey: PROC
        EXTRN   wherex: PROC, wherey: PROC, gotoxy: PROC
        EXTRN   strlen: PROC, strcpy: PROC



;
; initlineinput
;
; Hva prosedyren gj›r:
;   Setter opp variabler ol. slik at linjeediteringsfunksjonen kan brukes.
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
PROC    initlineinput
        ret
ENDP    initlineinput


;
; endlineinput
;
; Hva prosedyren gj›r:
;   Rydder opp etter at linjeediteringsfunksjonen er brukt
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
PROC    endlineinput
        ret
ENDP    endlineinput


;
; showline
;
; Hva prosedyren gj›r:
;   Viser linjen fra riktig posisjon p† skjermen.
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
PROC    showline
        push    ax

  ; Lagre n†v‘rende posisjon
        call    wherex
        call    wherey
        mov     [tmpxy], ax

  ; Flytt til starten av editeringslinjen
        mov     ax, [posxy]
        call    gotoxy

  ; Sett opp start for tellevariabel og pekervariabel
        mov     cx, [maxshow]
        mov     bx, [from]
        cmp     bx, [length]
        jae     @@fill_blank
        add     bx, OFFSET tmplin

  ; Vis tegn til enten 0 p†treffes, eller nok er skrevet.
@@put_char:
        mov     al, [bx]
        or      al, al  ; Er dette nullen?
        jz      @@fill_blank
        call    outchar
        inc     bx
        loop    @@put_char
        jmp     SHORT @@reset_cursor

  ; Fyll ut resten av linjen med blanke
@@fill_blank:
        jcxz    @@reset_cursor
        mov     al, ' '
@@put_blank:
        call    outchar
        loop    @@put_blank

  ; Sett tilbake riktig mark›rposisjon
@@reset_cursor:
        mov     ax, [tmpxy]
        call    gotoxy

        pop     ax
        ret
ENDP    showline


;
; lineinput
;
; Hva prosedyren gj›r:
;   Gir mulighet for enkel editering av en linje. Hvis den f›rste tasten som
;   trykkes er et tegn, slettes hele den tidligere linjen. Hvis ikke beholdes
;   den. Dette er alts† det samme som n†r editoren i Turbo C 2.0 ber om
;   filnavn osv.
;   Linjen editeres fra n†v‘rende mark›rposisjon, og BX plasser frem.
;
;   OBS OBS OBS
;     * Ingenting spesielt gj›res hvis linjen g†r over en skjermlinje
;     * Linjen strippes ikke
;
; Kall med:
;   AX    - Maks lengde p† strengen (uten avsluttende 0), men ikke mer enn
;           255 tegn.
;   BX    - Antall tegn som vises   gangen
;   CL    - Attributt f›r teksten godtas/forkastes (som i Turbo C; hvis ikke
;           mark›ren er flyttet n†r nytt tegn skrives, forkastes gammel tekst)
;   CH    - Attributt etter at teksten er godtatt/forkastet
;   SI    - Peker til linjen som skal editeres (ASCIIZ)
;   DI    - Peker til en rekke taster (WORD) som kan avbryte redigeringen,
;           etterfulgt av 0.
;           Return og Esc kan *alltid* brukes til † avslutte redigeringen,
;           selv om de ikke er med her.
;           Hvis listen er tom, kan isteden DI settes til 0. (Det bli alts†
;           un›dvendig † opprette en tom liste).
;
; Returnerer:
;   AX : Tasten som avsluttet redigeringen. Hvis dette er Esc, returneres
;        linjen uforandret.
;
; Endrer innholdet i:
;   AX
;
PROC    lineinput
        push    bx
        push    cx
        push    dx
        push    di
        push    si
        push    es

  ; Lagre opplysningene som er oversent
        mov     [orgadr], si    ; adressen til linjen som skal editeres
        mov     [keys], di      ; adressen til tastene som skal testes
        mov     [maxlen], ax    ; maks antall tegn (uten 0)
        mov     [maxshow], bx   ; antall tegn som vises av gangen
        mov     [attr], ch      ; Attributt etter at teksten er godtatt

  ; Husk n†v‘rende attributt
        mov     al, [txtattr]
        mov     [oldattr], al

  ; Sett starttextattributt
        mov     al, cl
        call    textattr

  ; Kopier linjen over i bufferet
        mov     di, OFFSET tmplin
        push    ds
        pop     es
        call    strcpy
        mov     si, [maxlen]
        mov     [BYTE si + OFFSET tmplin], 0

  ; Sett opp startverdier
        xor     ax, ax
        mov     [from], ax
        mov     [ok], al
        mov     dx, OFFSET tmplin
        call    strlen
        mov     [length], ax
        mov     [curr], ax
        call    wherex
        call    wherey
        mov     [posxy], ax

  ; Her f›lger l›kken for editering av strengen
@@next_char:

  ; Juster f›rst posisjonen strengen vises fra
        mov     ax, [curr]
        cmp     [from], ax
        jbe     @@low_OK
        mov     [from], ax
        jmp     SHORT @@justified
@@low_OK:
        sub     ax, [from]
        cmp     ax, [maxshow]
        jb      @@justified
        mov     ax, [curr]
        sub     ax, [maxshow]
        inc     ax
        mov     [from], ax
@@justified:

        call    showline
        mov     ax, [posxy]
        add     al, [BYTE curr]
        sub     al, [BYTE from]
        call    gotoxy

        call    getkey
        mov     [retrn], ax

        cmp     ax, 27
        je      @@jmp_end_edit
        cmp     ax, 13
        jne     @@dont_end
@@jmp_end_edit:
        jmp     @@end_edit

@@dont_end:
  ; Sjekk om tasten er i listen over taster som kan avbryte redigering
        mov     di, [keys]
        or      di, di  ; Er listen tom?
        jz      @@do_key
@@test_next_key:
        mov     bx, [di]
        inc     di
        inc     di
        or      bx, bx  ; Slutten p† listen?
        jz      @@do_key
        cmp     ax, bx
        jne     @@test_next_key
        jmp     @@end_edit

  ; Behandle innlest tast
@@do_key:
        cmp     [ok], 0
        jne     @@godtatt
  ; Hvis dette er et tegn, og teksten ikke tidligere er godtatt,
  ; skal strengen t›mmes.
        cmp     ax, 32
        jl      @@godtatt
        xor     bx, bx
        mov     [tmplin], bl
        mov     [from], bx
        mov     [length], bx
        mov     [curr], bx
@@godtatt:
        mov     [ok], 1

  ; Sett tekstattributt som angir at linjen n† er godtatt/forkastet
        push    ax
        mov     al, [attr]
        call    textattr
        pop     ax

        cmp     ax, 4           ; Ctrl-D = Right
        je      @@right
        cmp     ax, 7           ; Ctrl-G = Del
        je      @@del
        cmp     ax, 8           ; Ctrl-H = BackSpace
        je      @@backspace
        cmp     ax, 19          ; Ctrl-S = Left
        je      @@left
        cmp     ax, -71         ; Home
        je      @@home
        cmp     ax, -75         ; Left
        je      @@left
        cmp     ax, -77         ; Right
        je      @@right
        cmp     ax, -79         ; End
        je      @@end
        cmp     ax, -83         ; Del
        je      @@del

        cmp     ax, 32
        jge     @@store

@@jmp_next_char:
        jmp     @@next_char

@@left: cmp     [curr], 0
        je      @@jmp_next_char
        dec     [curr]
        jmp     @@next_char

@@right:mov     ax, [curr]
        cmp     ax, [length]
        jae     @@jmp_next_char
        inc     [curr]
        jmp     @@next_char

@@home: mov     [curr], 0
        jmp     @@next_char

@@end:  mov     ax, [length]
        mov     [curr], ax
        jmp     @@next_char

@@del:  mov     ax, [length]
        sub     ax, [curr]
        jle     @@jmp_next_char
        mov     cx, ax
        mov     di, OFFSET tmplin
        add     di, [curr]
        mov     si, di
        inc     si
        cld
        rep     movsb
        dec     [length]
        jmp     @@next_char

@@backspace:
        cmp     [curr], 0
        je      @@jmp_next_char
        dec     [curr]
        jmp     @@del

@@store:mov     ax, [curr]
        cmp     ax, [maxlen]
        jae     @@jmp_next_char
        mov     cx, [length]
        cmp     cx, [maxlen]
        jb      @@dont_cut
        mov     cx, [maxlen]
        dec     cx
@@dont_cut:
        mov     si, cx
        sub     cx, ax
        inc     cx
        add     si, OFFSET tmplin
        mov     di, si
        inc     di
        std
        rep     movsb
        mov     ax, [retrn]
        mov     [di], al
        mov     di, [maxlen]
        mov     [BYTE di + OFFSET tmplin], 0
        cmp     [length], di
        jae     @@dont_inc_len
        inc     [length]
@@dont_inc_len:
        inc     [curr]
        jmp     @@next_char

  ; Avslutt editeringen. Hvis det ikke er Esc som er trykket, skal den
  ; nye linjen kopieres over i den gamle.
@@end_edit:
        cmp     ax, 27
        je      @@set_cursor
        mov     si, OFFSET tmplin
        mov     di, [orgadr]
        call    strcpy

@@set_cursor:
        mov     ax, [posxy]
        call    gotoxy

  ; Sett tilbake orginal attributt
        mov     al, [oldattr]
        call    textattr

@@ret:  mov     ax, [retrn]
        pop     es
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     bx
        ret
ENDP    lineinput



        END
