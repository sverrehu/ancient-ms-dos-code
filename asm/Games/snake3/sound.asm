        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data


TIMER2  EQU     42h     ; Portadressen til timer nr 2
TIMER3  EQU     43h     ; Portadressen til timer nr 3
PORT_B  EQU     61h     ; Portadressen til 8255 port B, som styrer h›yttaleren



UDATASEG

pid     DW      ?       ; Prosess-id for n†v‘rende lydeffekt
frafrq  DW      ?       ; N†v‘rende frekvens
tilfrq  DW      ?       ; Stoppfrekvenst
frqstp  DW      ?       ; Endring i frekvens




DATASEG

        PUBLIC  soundon


soundon DB      1       ; Skal lyd gis?




CODESEG


        EXTRN   newproc: PROC, rmproc: PROC


        PUBLIC  sound, nosound, clearsound, mksound, stopsound




;
; sound
;
; Hva prosedyren gj›r:
;   Setter opp timer og h›ytaler til † lage en pipetone med angitt frekvens.
;   Dette gj›res bare hvis soundon <> 0.
;
; Kall med:
;   AX : Frekvensen
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    sound
        push    ax
        push    bx
        push    dx

  ; Sjekk om lyd skal gis
        cmp     [soundon], 0
        jz      @@ret

  ; Beregn verdier for angitt frekvens
        mov     bx, ax
        mov     dx, 1193182 SHR 16
        mov     ax, 1193182 AND 0FFFFh
        div     bx

  ; Sjekk om en lyd allerede er igang
        push    ax
        in      al, PORT_B
        test    al, 3           ; Er h›yttaler koplet til timer?
        pop     ax
        jnz     @@give_freq

        push    ax

  ; Kople h›yttaleren til timeren.
        in      al, PORT_B
        or      al, 3
        out     PORT_B, al

  ; Programmer timeren til riktig mode
        mov     al, 0B6h        ; Set up timer channel 2 mode
        out     TIMER3, al

        pop     ax

@@give_freq:
  ; Gi opplysninger om frekvens til timeren
        out     TIMER2, al      ; Lowbyte first
        mov     al, ah
        out     TIMER2, al      ; then Highbyte

@@ret:  pop     dx
        pop     bx
        pop     ax
        ret
ENDP    sound



;
; nosound
;
; Hva prosedyren gj›r:
;   Stopper lyden ved † kople h›yttaleren fra timeren.
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
PROC    nosound
        push    ax

        in      al, PORT_B
        and     al, 252
        out     PORT_B, al

        pop     ax
        ret
ENDP    nosound



;
; clearsound
;
; Hva prosedyren gj›r:
;   Setter opp det som har med lyden † gj›re.
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
PROC    clearsound
        mov     [pid], -1
        call    nosound
        ret
ENDP    clearsound



;
; dosound
;
; Hva prosedyren gj›r:
;   Utf›ren nytt step i n†v‘rende lydeffekt. Kalles fra procloop.
;
; Kall med:
;   Skal ikke kalles.
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    dosound
        push    ax

  ; Oppdater variablen
        mov     ax, [frqstp]
        add     [frafrq], ax

  ; Gj›r test p† om den siste frekvensen er passert. Denne testen blir litt
  ; spesiell, siden den er avhengig av om tellingen g†r oppover eller
  ; nedover.

  ; Sjekk fortegnet p† frqstp.
        test    [frqstp], 10000000b
        jz      @@positiv

@@negativ:
  ; Endringen er negativ. Sjekk om n†dd frekvens er mindre enn sluttfrekvensen.
        mov     ax, [frafrq]
        cmp     ax, [tilfrq]
        jl      @@ret_nosound
        jmp     SHORT @@ret_sound

@@positiv:
  ; Endringen er positiv. Sjekk om n†dd frekvens er st›rre enn sluttfrekvensen.
        mov     ax, [frafrq]
        cmp     ax, [tilfrq]
        jg      @@ret_nosound

@@ret_sound:
  ; Det er mer lyd igjen. Gi n†v‘rende lydtone.
        call    sound
        jmp     SHORT @@ret

@@ret_nosound:
  ; Effekten er ferdig. Sl† av lyden og fjern prosessen.
        call    nosound
        mov     ax, [pid]
        call    rmproc
        mov     [pid], -1

@@ret:  pop     ax
        ret
ENDP    dosound



;
; mksound
;
; Hva prosedyren gj›r:
;   Setter opp til angitt lydeffekt. Forkaster dermed evt. tidligere
;   igangsatte effekter.
;
; Kall med:
;   AX : Hastighet for frekvensendring, passende til procloop
;   BX : Startfrekvens  (0-32767)
;   CX : Sluttfrekvens
;   DX : Frekvensstep
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    mksound
        push    ax
        push    dx

  ; Sett opp variablene til angitte verdier.
        mov     [frafrq], bx
        mov     [tilfrq], cx
        mov     [frqstp], dx

  ; Sjekk om en lyprosess g†r
        cmp     [pid], -1
        jne     @@ret

  ; Nei, start en ny en.
        mov     dx, OFFSET dosound
        call    newproc
        mov     [pid], ax

@@ret:  pop     dx
        pop     ax
        ret
ENDP    mksound



;
; stopsound
;
; Hva prosedyren gj›r:
;   Kutter ut n†v‘rende lydeffekt.
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
PROC    stopsound
        push    ax

        call    nosound

  ; Sjekk om en lydprosess g†r.
        mov     ax, [pid]
        cmp     ax, -1
        je      @@ret           ; Nei.

  ; Fjern prosessen
        call    rmproc
        mov     [pid], -1

@@ret:  pop     ax
        ret
ENDP    stopsound








ENDS

        END
