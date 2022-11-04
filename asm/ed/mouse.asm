        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @code, es: NOTHING

INCLUDE "ED.INC"

IF MOUSE

;--------------------------;
;                          ;
;         D A T A          ;
;                          ;
;--------------------------;

UDATASEG

        EXTRN   resmouse: BYTE

        PUBLIC  xmouse, ymouse, mbutt

xmouse  DW      ?       ; Musas X-tegn p† skjermen
ymouse  DW      ?       ; Musas Y-tegn p† skjermen
mbutt   DB      ?       ; Taster som er trykket p† musa.
                        ; bits: 0-left, 1-right, 2-centre



DATASEG

mouseok DB      0       ; Er mus installert ??
xpix    DW      640     ; Antall pixels i X-retningen
ypix    DW      200     ; Antall pixels i Y-retningen
xchrpix DB      8       ; Antall pixels/tegn i X-retningen
ychrpix DB      8       ; Antall pixels/tegn i Y-retningen





;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        EXTRN   screenrows: PROC, screencols: PROC

        PUBLIC  initmouse, endmouse, getmouse
        PUBLIC  hidemouse, showmouse



;
; initmouse
;
; Hva prosedyren gj›r:
;   Sjekker om musdriver finnes, og is†fall resetter denne og viser
;   musmark›ren.
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
PROC    initmouse
    ; Musa skal muligens resettes
        cmp     [resmouse], 0
        je      @@dont_reset

        xor     ax, ax  ; Reset Mouse and Get Status
        int     33h
        cmp     ax, 0FFFFh
        jne     @@no_mouse
        jmp     SHORT @@setup_mouse

  @@dont_reset:
    ; Musa skal ikke resettes. Kall en musfunksjon for † se om musa finnes.
        mov     ax, 3           ; Get Mouse Position and Button Status
        mov     bx, 0FFFFh
        int     33h
        cmp     bx, 0FFFFh
        je      @@no_mouse

  @@setup_mouse:
        mov     [mouseok], 1
    ; Hvis det n† er EGA-skjerm, skal musas Y-grense oppdateres med
    ; riktig pixeltall.
        mov     ah, 12h         ; Get Configuration Info
        mov     bl, 10h
        int     10h
        cmp     bl, 10h
        je      @@not_ega
; Her har jeg opprinnelig lest antall scan-lines pr tegn fra BIOS-data-
; omr†det, men det ser ut som om musa alltid regner med 8, s† da bl†ser
; jeg i lesingen.
;        push    es
;        xor     ax, ax
;        mov     es, ax
;        mov     cx, [es: 0485h] ; Antall bytes (scan lines) pr. tegn
;        pop     es
;        mov     [ychrpix], cl
    mov cl, [ychrpix]  ; som er 8 fast
        call    screenrows
        mul     cl
        mov     [ypix], ax
  @@not_ega:
        mov     dx, [ypix]      ; Max Y-coordinate
        dec     dx
        xor     cx, cx          ; Min Y-coordinate
        mov     ax, 8           ; Set Vertical Limits for Pointer
        int     33h
        mov     dx, [xpix]      ; Max X-coordinate
        dec     dx
        xor     cx, cx          ; Min X-coordinate
        mov     ax, 7           ; Set Horizontal Limits for Pointer
        int     33h
        mov     ax, 0Ah         ; Set Text Pointer Type
        xor     bx, bx          ; Software Cursor
        mov     cx, 77FFh       ; AND mask value
        mov     dx, 7700h       ; XOR mask value
        int     33h

    ; Hvis musa ikke er resatt, m† vi s›rge for at mark›ren blir
    ; synlig ved neste kall til showmouse. Flytter ogs† mark›ren til
    ; midten av skjermen.
        cmp     [resmouse], 0
        jne     @@ret

        call    hidemouse
        mov     cx, 10
  @@show_mouse:
        call    showmouse
        loop    @@show_mouse
        call    hidemouse

        mov     cx, [xpix]
        shr     cx, 1
        mov     dx, [ypix]
        shr     dx, 1
        mov     ax, 4           ; Set Mouse Pointer Position
        int     33h

  @@no_mouse:
  @@ret:
        ret
ENDP    initmouse



;
; endmouse
;
; Hva prosedyren gj›r:
;   Skjuler musmark›ren (hvis musa finnes)
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
PROC    endmouse
        cmp     [mouseok], 0
        jz      @@no_mouse
        mov     ax, 2   ; Hide Mouse Pointer
        int     33h
  @@no_mouse:
        ret
ENDP    endmouse



;
; getmouse
;
; Hva prosedyren gj›r:
;   Finner musas n†v‘rende posisjon og tastestatus, og legger dette i
;   riktige globale variabler.
;
; Kall med:
;   Ingenting
;
; Returnerer:
;   CF : 0 - Mus finnes og den skal leses (er endret/flyttet)
;        1 - Mus finnes ikke, eller er ikke endret/flyttet
;
; Endrer innholdet i:
;   Ingenting
;
PROC    getmouse
        push    ax
        push    bx
        push    cx
        push    dx
        cmp     [mouseok], 0
        jz      @@ret_no_mouse
        mov     ax, 3   ; Get Mouse Position and Button Status
        int     33h
        mov     ax, dx  ; Y-pixel
        div     [ychrpix]
        mov     [ymouse], ax
        mov     ax, cx  ; X-pixel
        div     [xchrpix]
        mov     [xmouse], ax
        and     bl, 7   ; Maske slik at bare tastene er igjen
        mov     [mbutt], bl
        or      bl, bl  ; Er ingen mustast trykket ??
        jz      @@ret_no_mouse
  @@ret_mouse:
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        clc
        ret
  @@ret_no_mouse:
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        stc
        ret
ENDP    getmouse



;
; showmouse
;
; Hva prosedyren gj›r:
;   Viser musmark›ren (hvis musa finnes)
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
PROC    showmouse
        cmp     [mouseok], 0
        jz      @@no_mouse
        push    ax
        mov     ax, 1   ; Show Mouse Pointer
        int     33h
        pop     ax
  @@no_mouse:
        ret
ENDP    showmouse



;
; hidemouse
;
; Hva prosedyren gj›r:
;   Skjuler musmark›ren (hvis musa finnes)
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
PROC    hidemouse
        cmp     [mouseok], 0
        jz      @@no_mouse
        push    ax
        mov     ax, 2   ; Hide Mouse Pointer
        int     33h
        pop     ax
  @@no_mouse:
        ret
ENDP    hidemouse





ENDS

ENDIF

        END
