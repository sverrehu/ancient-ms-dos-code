        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING



INCLUDE "WINDOW.INC"



;--------------------------;
;                          ;
;         D A T A          ;
;                          ;
;--------------------------;

UDATASEG

        PUBLIC  wtattr, wrattr, upleft, loright

        EXTRN   vx1: BYTE, vy1: BYTE, vx2: BYTE, vy2: BYTE
        EXTRN   antkol2: WORD
        EXTRN   curx: BYTE, cury: BYTE
        EXTRN   sadr: DWORD
        EXTRN   txtattr: BYTE

; Data for nÜvërende vindu
wtattr  DB      ?   ; Tekstattributt som skal brukes i vinduet
wrattr  DB      ?   ; Rammeattributt som skal brukes i vinduet
upleft  DW      ?   ; Koordinater for upper left corner  (innenfor rammen)
loright DW      ?   ; Koordinater for lower right corner (innenfor rammen)





DATASEG

        PUBLIC  ramme

ramme   DB      0   ; Rammetypen som skal brukes i vinduet
; Vinduer lagres i en stack. wstack peker til toppen pÜ stacken.
wstack  DW      0   ; Seg-Peker til data om forrige vindu (Toppen pÜ stacken)
; Koder for rammesymboler:
; upleft, vannrett, upright, loddrett, lowright, lowleft
ramme1  DB      218, 196, 191, 179, 217, 192
ramme2  DB      201, 205, 187, 186, 188, 200





;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        PUBLIC  initwindow, endwindow, openwindow, closewindow
        PUBLIC  draw_border

        EXTRN   setcurs   : PROC
        EXTRN   addr_of_pos: PROC
        EXTRN   screenrows: PROC, screencols: PROC
        EXTRN   window    : PROC
        EXTRN   outtext   : PROC
        EXTRN   gettext   : PROC, puttext   : PROC

        EXTRN   getmem    : PROC, freemem   : PROC


;
; initwindow
;
; Hva prosedyren gjõr:
;   Setter opp variabler ol. slik at vindusfunksjonene kan brukes.
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
PROC    initwindow
        push    ax
  ; Sett data om nÜvërende vindu slik hele skjermen er.
        mov     al, [txtattr]
        mov     [wtattr], al
        mov     [wrattr], al
        mov     al, [vx1]
        mov     ah, [vy1]
        mov     [upleft], ax
        mov     al, [vx2]
        mov     ah, [vy2]
        mov     [loright], ax
        pop     ax
        ret
ENDP    initwindow


;
; endwindow
;
; Hva prosedyren gjõr:
;   Rydder opp etter at vindusfunksjonene er brukt
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
PROC    endwindow
@@lukk_neste:                      ; Lukk evt vinduer som er Üpne
        cmp     [wstack], 0
        je      @@alle_lukket
        call    closewindow
        jmp     SHORT @@lukk_neste
@@alle_lukket:
        ret
ENDP    endwindow


;
; draw_border
;
; Hva prosedyren gjõr:
;   Tegner ramme i angitte koordinater. (Ikke relativt til vinduet)
;   Rammen fÜr nÜvërende attributt (txtattr).
;
; Kall med:
;   AL : ùverste venstre X-koordinat
;   AH : ùverste venstre Y-koordinat
;   DL : Nederste hõyre X-koordinat
;   DH : Nederste hõyre Y-koordinat
;   BL : 1, 2 = Enkel eller dobbel ramme.
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    draw_border
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    es
        cmp     bl, 1
        jne     @@dobbel_ramme
        mov     bx, OFFSET ramme1
        jmp     SHORT @@enkel_ramme
@@dobbel_ramme:
        mov     bx, OFFSET ramme2
@@enkel_ramme:
        call    addr_of_pos
        push    ax
        push    dx
        xor     ch, ch
        mov     cl, dl
        sub     cl, al
        mov     si, cx          ; Differansen X2-X1.
        shl     si, 1
        dec     cl              ; Antall i X-retningen
        push    cx
        cld
        mov     ah, [txtattr]
        mov     al, [bx + 0]
        stosw
        jcxz    @@ikke_horisontal_1
        mov     al, [bx + 1]
        rep     stosw
@@ikke_horisontal_1:
        mov     al, [bx + 2]
        stosw
        pop     cx
        pop     dx
        pop     ax
        push    ax
        mov     ah, dh
        call    addr_of_pos
        push    dx
        cld
        mov     ah, [txtattr]
        mov     al, [bx + 5]
        stosw
        jcxz    @@ikke_horisontal_2
        mov     al, [bx + 1]
        rep     stosw
@@ikke_horisontal_2:
        mov     al, [bx + 4]
        stosw
        pop     dx
        pop     ax
        call    addr_of_pos
        add     di, [antkol2]
        xor     ch, ch
        mov     cl, dh
        sub     cl, ah
        dec     cl              ; Antall i Y-retningen
        jcxz    @@ret
        cld
        mov     ah, [txtattr]
        mov     al, [bx + 3]
@@l1:   stosw
        add     di, si
        dec     di
        dec     di
        stosw
        sub     di, si
        dec     di
        dec     di
        add     di, [antkol2]
        loop    @@l1

@@ret:  pop     es
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    draw_border


;
; openwindow
;
; Hva prosedyren gjõr:
;   èpner (hvis mulig) et vindu med angitte koordinater, etter Ü ha spart
;   nõdvendige opplysninger om det forrige vinduet.
;
; Kall med:
;   AL : ùverste venstre X-koordinat
;   AH : ùverste venstre Y-koordinat
;   DL : Nederste hõyre X-koordinat
;   DH : Nederste hõyre Y-koordinat
;   CL : Tekstattributt
;   CH : Rammeattributt
;   BL : 0, 1, 2 = Ingen, enkel, el dobbel ramme.
;
; Returnerer:
;   AX : 0=ok, annet=feil
;
; Endrer innholdet i:
;   AX
;
PROC    openwindow
        push    bx
        push    cx
        push    dx
        push    di
        push    es
        mov     [ramme], bl
        mov     [wtattr], cl
        mov     [wrattr], ch
        mov     [upleft], ax
        mov     [loright], dx
  ; Fõrst mÜ minne settes av til vindudata og buffer.
        sub     dl, al
        inc     dl
        sub     dh, ah
        inc     dh
        mov     al, dh
        mul     dl
        shl     ax, 1            ; Antall bytes til buffer i AX
        add     ax, w_data_size  ; + antall bytes til data
        call    getmem           ; Alloker nõdvendig minne
        or      ax, ax           ; 0 betyr: ikke nok minne
        jnz     @@allok_OK
        mov     ax, 1
        jmp     @@ret
@@allok_OK:
        mov     bl, [ramme]
        mov     [es: (w_data PTR 0).ramme], bl
        mov     [es: (w_data PTR 0).size], ax
        mov     ax, [wstack]
        mov     [es: (w_data PTR 0).next], ax
        mov     al, [vx1]
        mov     [es: (w_data PTR 0).vx1], al
        mov     al, [vy1]
        mov     [es: (w_data PTR 0).vy1], al
        mov     al, [vx2]
        mov     [es: (w_data PTR 0).vx2], al
        mov     al, [vy2]
        mov     [es: (w_data PTR 0).vy2], al
        mov     al, [curx]
        mov     [es: (w_data PTR 0).curx], al
        mov     al, [cury]
        mov     [es: (w_data PTR 0).cury], al
        mov     al, [txtattr]
        mov     [es: (w_data PTR 0).tattr], al
        mov     di, w_data_size  ; Teksten kopieres etter dataene
        mov     ax, [upleft]
        mov     dx, [loright]
        call    gettext
        mov     [wstack], es

        mov     bh, [wtattr]
        mov     cx, [upleft]
        mov     dx, [loright]
        mov     ax, 0600h
        int     10h

        cmp     [ramme], 0
        je      @@ingen_ramme
        mov     al, [wrattr]
        mov     [txtattr], al
        mov     ax, [upleft]
        mov     dx, [loright]
        mov     bl, [ramme]
        call    draw_border
        inc     al               ; Juster vinduets koordinater, slik at
        inc     ah               ; de blir innenfor rammen.
        mov     [upleft], ax
        dec     dl
        dec     dh
        mov     [loright], dx
@@ingen_ramme:
        mov     al, [wtattr]
        mov     [txtattr], al

        mov     ax, [upleft]
        mov     dx, [loright]
        call    window

        call    setcurs
        xor     ax, ax           ; Betyr OK
@@ret:  pop     es
        pop     di
        pop     dx
        pop     cx
        pop     bx
        ret
ENDP    openwindow


;
; closewindow
;
; Hva prosedyren gjõr:
;   Lukker et tidligere Üpnet vindu ved Ü kopiere tilbake tidliger lagret
;   del av skjermen, flytte markõren til til riktig pos, og sette riktig
;   attributt.
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
PROC    closewindow
        push    ax
        push    dx
        push    di
        push    es
        mov     ax, [wstack]
        or      ax, ax
        jz      @@ret
        mov     es, ax
        mov     al, [vx1]
        mov     ah, [vy1]
        mov     dl, [vx2]
        mov     dh, [vy2]
        cmp     [es: (w_data PTR 0).ramme], 0
        je      @@koord_OK
        dec     al
        dec     ah
        inc     dl
        inc     dh
@@koord_OK:
        mov     di, w_data_size
        call    puttext
        mov     al, [es: (w_data PTR 0).vx1]
        mov     ah, [es: (w_data PTR 0).vy1]
        mov     dl, [es: (w_data PTR 0).vx2]
        mov     dh, [es: (w_data PTR 0).vy2]
        call    window
        mov     al, [es: (w_data PTR 0).curx]
        mov     [curx], al
        mov     ah, [es: (w_data PTR 0).cury]
        mov     [cury], ah
        call    setcurs
        mov     al, [es: (w_data PTR 0).tattr]
        mov     [txtattr], al
        mov     ax, [es: (w_data PTR 0).next]
        mov     [wstack], ax
        mov     ax, [es: (w_data PTR 0).size]
        call    freemem
@@ret:  pop     es
        pop     di
        pop     dx
        pop     ax
        ret
ENDP    closewindow


        END
