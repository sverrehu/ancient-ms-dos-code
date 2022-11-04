        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data


INCLUDE "SNAKE3.INC"



UDATASEG

        PUBLIC  quit


quit    DB      ?       ; Skal spillet stoppes?


DATASEG

        EXTRN   score: WORD, lives: WORD, level: WORD, antledd: WORD
        EXTRN   rmspid: WORD

strtmsg DB      NAVN, " ", VER, "  --  (C) ", DATO
        DB      " - Sverre H. Huseby, Larvik, Norway", 13, 10, "$"
notega  DB      "Sorry, can't find EGA-color.", 13, 10, "$"



CODESEG

        EXTRN   init_ega10_graph: PROC, closegraph: PROC
        EXTRN   randomize: PROC

        EXTRN   drawscreen: PROC
        EXTRN   clearsmem: PROC
        EXTRN   init_timer: PROC, reset_timer: PROC
        EXTRN   readhgh: PROC, writehgh: PROC, testhgh: PROC
        EXTRN   clearprocs: PROC, newproc: PROC, procloop: PROC
        EXTRN   clearbouncer: PROC, newbouncer: PROC, rmbouncer: PROC
        EXTRN   clearbanger: PROC, newbanger: PROC, rmbanger: PROC
        EXTRN   clearsnake: PROC, showsnake: PROC
        EXTRN   movesnake: PROC, growsnake: PROC, rmlensnake: PROC
        EXTRN   clearmush: PROC, rndmkmush: PROC, rndrmmush: PROC
        EXTRN   rmallmush: PROC
        EXTRN   clearfood: PROC, mkfood: PROC, rndmkfood: PROC
        EXTRN   rndrmfood: PROC, rmallfood: PROC
        EXTRN   showscore: PROC, showlength: PROC
        EXTRN   showlives: PROC, showlevel: PROC
        EXTRN   asklevel: PROC, clearplayground: PROC
        EXTRN   clearsound: PROC, stopsound: PROC, mksound: PROC
        EXTRN   instructions: PROC
        EXTRN   clearmessage: PROC


        ORG     0100h

start:  jmp     main


        DB      8, 8, 8, 13, 10, "--> Hi, I understand you like peeking "
        DB      "into other peoples programs? <--", 13, 10, 26



;
; newgame
;
; Hva prosedyren gj›r:
;   Initierer alle variabler og klargj›r til nytt spill.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   Ingenting
;
;  Endrer innholdet i:
;    Ingenting
;
PROC    newgame
        call    clearplayground
        call    clearprocs
        call    clearsnake
        call    clearbouncer
        call    clearbanger
        call    clearmush
        call    clearfood
        call    clearsound
        mov     [score], 0
        mov     [lives], 3
        call    showscore
        call    showlength
        call    showlives
        call    showlevel
        call    showsnake
        ret
ENDP    newgame



;
; newround
;
; Hva prosedyren gj›r:
;   Setter opp til ny runde. Plasserer slangen "sammenkveilet" midt
;   p† skjermen, osv.
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
PROC    newround
        call    clearprocs
        mov     ax, [antledd]
        sub     ax, 3           ; Slangens startlengde
        call    clearsnake
        call    growsnake
        call    clearbouncer
        call    clearbanger
        call    clearmush
        call    clearfood
        call    showsnake
        call    showlength
        call    mkfood
        ret
ENDP    newround



;
; play
;
; Hva prosedyren gj›r:
;   Tar seg av et helt spill: Sp›r etter level, kj›rer alle runder, og
;   sjekker om highscore.
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
PROC    play
        push    ax
        push    dx

        mov     [quit], 0

  ; Vis instruksjoner
        call    instructions

  ; Sp›r etter ›nsket niv†
        call    asklevel
        cmp     [quit], ESCAPE
        jne     @@not_esc
        jmp     @@ret
@@not_esc:

  ; Sett opp startverdier
        call    newgame
        call    mkfood

@@start_round:
  ; Sett opp prosesser for spill
        call    newbouncer
        call    newbanger

        mov     dx, OFFSET movesnake
        mov     ax, 11
        sub     ax, [level]
        call    newproc

        mov     dx, OFFSET rndmkmush
        mov     ax, 130
        call    newproc

        mov     dx, OFFSET rndrmmush
        mov     ax, 130
        call    newproc

        mov     dx, OFFSET rndmkfood
        mov     ax, 100
        call    newproc

        mov     dx, OFFSET rndrmfood
        mov     ax, 100
        call    newproc

  ; Start en runde
        call    procloop

  ; Rydd opp etter runden
        call    rmbouncer
        call    rmbanger
        call    rmallfood
        call    rmallmush
        call    stopsound
        call    clearmessage
        call    clearprocs

  ; Lag kollisjonslyd hvis ikke avbrutt med ESC.
        cmp     [quit], ESCAPE
        je      @@no_explode
        mov     ax, 1
        mov     bx, 300
        mov     cx, 100
        mov     dx, -3
        call    mksound
        call    procloop
@@no_explode:

  ; Fjern gjenv‘rende ledd og gi bonus
        mov     [rmspid], -1    ; S›rg for at ny prosess opprettes
        mov     ax, [antledd]
        call    rmlensnake
        call    procloop
        mov     [antledd], ax
        call    showlength

  ; Rydd opp i r†tten mat osv.
        call    clearplayground
        call    clearmessage

  ; T›m tastebufferet
@@keys_present:
        mov     ah, 1
        int     16h
        jz      @@nokey
        xor     ah, ah
        int     16h
        jmp     @@keys_present
@@nokey:

  ; Sjekk om spillet ble avbrutt av bruker
        cmp     [quit], ESCAPE
        je      @@ret_zero_quit

  ; Sjekk om flere liv
        dec     [lives]
        call    showlives
        cmp     [lives], 0
        jz      @@chk_high

  ; Sett opp for ny runde
        call    newround
        jmp     @@start_round

  ; Sjekk om highscore
@@chk_high:
        call    testhgh

@@ret_zero_quit:
        mov     [quit], 0

@@ret:  pop     dx
        pop     ax
        ret
ENDP    play






main:
        mov     dx, OFFSET strtmsg
        mov     ah, 9
        int     21h
  ; Sjekk om mulig † initiere EGA mode 10h.
        call    init_ega10_graph
        or      ax, ax
        jz      @@ega10_OK

  ; Nei. Vis feilmelding og avslutt.
        mov     dx, OFFSET notega
        mov     ah, 9
        int     21h
        jmp     SHORT exit

@@ega10_OK:
        call    readhgh
        call    randomize
        call    clearsmem
        call    clearprocs
        call    drawscreen
        call    init_timer

@@new_game:
        call    play
        cmp     [quit], 0
        jz      @@new_game

@@finish:
        call    reset_timer
        call    writehgh

        call    closegraph

        mov     dx, OFFSET strtmsg
        mov     ah, 9
        int     21h

exit:   mov     ax, 4C00h
        int     21h



ENDS

        END     start
