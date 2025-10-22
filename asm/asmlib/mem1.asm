        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING


INCLUDE "MEM.INC"



;--------------------------;
;                          ;
;         D A T A          ;
;                          ;
;--------------------------;

UDATASEG

        PUBLIC  freelst

freelst     DW  ?       ; F›rste ledige blokk. OBS: Kan v‘re 0 !!

IFDEF BESTFIT
 bestsiz    DW  ?       ; Midl. var. Beste st›rrelse under GETMEM
 bestseg    DW  ?       ; Midl. var. Segment til _BLOKKEN FR_ beste blokk
                        ; under GETMEM
ENDIF



;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        PUBLIC  initmem, endmem
        PUBLIC  getmem, freemem



;
; initmem
;
; Hva prosedyren gj›r:
;   Setter opp alt som m† v‘re klart for at minnerutinene skal brukes.
;
; Kall med:
;   ES : Peker til PSP
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    initmem
        push    ax
        push    bx
        push    es

        mov     ax, [es: 0002h]  ; End of allocated block
        mov     bx, es
        add     bx, 1000h        ; Forbi programmets 64k
        mov     [freelst], bx
        mov     es, bx
        sub     ax, bx           ; Finn antall bytes
        mov     [es: (ledig_blk PTR 0).paragr], ax
        mov     [es: (ledig_blk PTR 0).next], 0

        pop     es
        pop     bx
        pop     ax
        ret
ENDP    initmem



;
; endmem
;
; Hva prosedyren gj›r:
;   Rydder opp etter at minnerutiner er brukt.
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
PROC    endmem
        ret
ENDP    endmem



;
; getmem
;
; Hva prosedyren gj›r:
;   Allokerer minne etter angitt st›rrelse.
;   Minste enhet som allokeres, er en paragraf.
;
; Kall med:
;   AX : nsket antall BYTES (!)
;
; Returnerer:
;   ES : Peker (Segmentadresse) til start p† allokert blokk, eller
;        0 hvis ikke OK.
;   AX : Antall allokerte paragrafer. Denne skal brukes n†r freemem kalles.
;        Denne er ogs† 0 hvis ikke OK.
;
; Endrer innholdet i:
;   AX, ES
;
PROC    getmem
        push    bx
        push    dx

        or      ax, ax        ; Det er ikke tillatt † allokere 0 bytes.
IFDEF FIRSTFIT
        jz      @@feil
ENDIF
IFDEF BESTFIT
        jnz     @@mer_enn_null
        jmp     @@feil
ENDIF
  @@mer_enn_null:
    ; Gj›r om antall bytes til paragrafer
        mov     bx, ax
        push    cx
        mov     cl, 4
        shr     ax, cl        ; Del p† 16.
        pop     cx
        and     bx, 15
        jz      @@gikk_opp
        inc     ax            ; Noen bytes var rest, s† vi legger til 16 bytes.
  @@gikk_opp:

IFDEF FIRSTFIT
    ; G† gjennom ledige blokker til den f›rste som er stor nok blir funnet.
        mov     es, [freelst]
        xor     dx, dx        ; Brukes for † huske forrige peker

  @@sjekk_neste:
    ; Er det flere ledige blokker?
        mov     bx, es
        or      bx, bx
        jz      @@feil

    ; Sjekk om n†v‘rende er stor nok.
        mov     bx, [es: (ledig_blk PTR 0).paragr]
        cmp     ax, bx
        jbe     @@plass_funnet

    ; Blokken var for liten. Hopp videre til neste.
        mov     dx, es        ; Spar forrige i DX
        mov     es, [es: (ledig_blk PTR 0).next]
        jmp     SHORT @@sjekk_neste

ENDIF
IFDEF BESTFIT
    ; G† gjennom ledige blokker og finn den som passer best, dvs. den
    ; minste som er >= ›nsket antall paragrafer.
        mov     [WORD bestsiz], 0FFFFh
        mov     [WORD bestseg], 0
        mov     es, [freelst]
        mov     bx, es
        or      bx, bx        ; Er det ikke noe ledig i det hele tatt?
        jnz     @@noe_er_ledig
        jmp     @@feil
  @@noe_er_ledig:
        xor     dx, dx        ; Brukes for † huske forrige peker
  @@sjekk_neste:
        mov     bx, es
        or      bx, bx
        jz      @@alle_testet
        mov     bx, [es: (ledig_blk PTR 0).paragr]
        cmp     ax, bx        ; Er funnet blokk n›yaktig stor nok?
        je      @@plass_funnet; stopp is†fall s›kingen.
        ja      @@finn_neste  ; Her er blokken for liten.
        cmp     bx, [bestsiz]
        ja      @@finn_neste
        mov     [bestsiz], bx
        mov     [bestseg], dx
  @@finn_neste:
        mov     dx, es        ; Spar forrige i DX
        mov     es, [es: (ledig_blk PTR 0).next]
        jmp     SHORT @@sjekk_neste

  @@alle_testet:
        cmp     [WORD bestsiz], 0FFFFh ; Er ingen passende blokk funnet?
        je      @@feil
        mov     dx, [bestseg]
        mov     es, [freelst]
        or      dx, dx
        jz      @@bruk_freelst
        mov     es, dx
        mov     es, [es: (ledig_blk PTR 0).next]
  @@bruk_freelst:
ENDIF

  @@plass_funnet:
        mov     bx, [es: (ledig_blk PTR 0).paragr]
        sub     bx, ax
        jz      @@hele_blokken_tatt
    ; Oppdater forrige peker, slik at den peker p† begynnelsen av den
    ; innskrenkede ledige blokken.
        push    cx
        mov     cx, es        ; Finn seg.adressen til forkortet ledig blokk.
        add     cx, ax
        or      dx, dx        ; Er det ingen forrige peker?
        jz      @@lagre_i_freelst1
        push    es
        mov     es, dx
        mov     [es: (ledig_blk PTR 0).next], cx
        pop     es
        jmp     SHORT @@oppdat_ledig
  @@lagre_i_freelst1:
        mov     [freelst], cx
  @@oppdat_ledig:
        push    ds
        mov     ds, cx
        mov     [(ledig_blk PTR 0).paragr], bx
        mov     cx, [es: (ledig_blk PTR 0).next]
        mov     [(ledig_blk PTR 0).next], cx
        pop     ds
        pop     cx
        jmp     SHORT @@ret
  @@hele_blokken_tatt:
        mov     bx, [es: (ledig_blk PTR 0).next]
        or      dx, dx        ; Er det ingen forrige peker?
        jz      @@lagre_i_freelst2
        push    es
        mov     es, dx
        mov     [es: (ledig_blk PTR 0).next], bx
        pop     es
        jmp     SHORT @@ret
  @@lagre_i_freelst2:
        mov     [freelst], bx
        jmp     SHORT @@ret

  @@feil:
        xor     ax, ax
        mov     es, ax

  @@ret:
        pop     dx
        pop     bx
        ret
ENDP    getmem



;
; freemem
;
; Hva prosedyren gj›r:
;   Frigj›r tidligere allokert minne.
;
; Kall med:
;   ES : Peker til minneblokk
;   AX : Antall paragrafer som skal frigis.
;
; Returnerer:
;   Ingenting
;
; Endrer innholdet i:
;   Ingenting
;
PROC    freemem
        push    ax
        push    bx
        push    cx
        push    dx
        push    bp
        push    es

        or      ax, ax
        jnz     @@ikke_0_para
  @@jmp_ret:
        jmp     @@ret

  @@ikke_0_para:
        mov     bx, es
        or      bx, bx
        jz      @@jmp_ret
    ; Sjekk f›rst spesialtilfellet der det ikke er noe ledig minne fra f›r.
    ; Da skal freelst peke p† den nye blokken.
        cmp     [freelst], 0
        jne     @@noe_er_ledig
        mov     [es: (ledig_blk PTR 0).paragr], ax
        mov     [es: (ledig_blk PTR 0).next], 0
        mov     [freelst], es
        jmp     @@ret
  @@noe_er_ledig:
    ; Under frigivelsen skal det sjekkes om blokken er nabo til en annen fri
    ; blokk. Is†fall skal disse sl†s sammen.
    ; Frilisten ligger sortert etter stigende segmentadresse, derfor sjekkes
    ; f›rst spesialtilfellet hvor blokken ligger f›r f›rste i frilisten.
        cmp     bx, [freelst]
        jae     @@etter_forste
    ; Her er blokken som skal frigis f›r f›rste blokk i frilisten. Sjekk om
    ; disse er naboer.
        add     bx, ax  ; Legg til antall paragrafer
        cmp     bx, [freelst]
        jne     @@ikke_naboer_1
    ; Sl† sammen blokken med f›rste blokk
        push    es
        mov     es, [freelst]
        add     ax, [es: (ledig_blk PTR 0).paragr]
        mov     bx, [es: (ledig_blk PTR 0).next]
        pop     es
        mov     [freelst], es
        mov     [es: (ledig_blk PTR 0).paragr], ax
        mov     [es: (ledig_blk PTR 0).next], bx
        jmp     SHORT @@ret
  @@ikke_naboer_1:
    ; Legg blokken f›rst i frilisten
        mov     [es: (ledig_blk PTR 0).paragr], ax
        mov     ax, [freelst]
        mov     [es: (ledig_blk PTR 0).next], ax
        mov     [freelst], es
        jmp     SHORT @@ret
  @@etter_forste:
    ; Blokken som skal frigis kommer etter f›rste blokk i frilisten. G†
    ; gjennom listen til blokken f›r den aktuelle blokken er funnet.
        mov     bp, es  ; Segment til blokk som skal frigis i BP.
        mov     es, [freelst]
        xor     dx, dx        ; Brukes for † huske forrige peker
  @@sjekk_neste:
        mov     bx, es
        or      bx, bx
        jz      @@alle_testet
        cmp     bx, bp
        jae     @@funnet
  @@finn_neste:
        mov     dx, es        ; Spar forrige i DX
        mov     es, [es: (ledig_blk PTR 0).next]
        jmp     SHORT @@sjekk_neste
  @@alle_testet:
  @@funnet:
    ; Her ligger blokken f›r i DX, mens blokken etter ligger i ES og BX.
    ; (Hvis ES/BX er 0, er det ikke noen blokk etter denne.)
    ; Legg f›rst blokken inn i listen.
        mov     es, dx  ; Forrige blokk
        mov     [es: (ledig_blk PTR 0).next], bp
        mov     es, bp  ; N†v‘rende blokk
        mov     [es: (ledig_blk PTR 0).next], bx
        mov     [es: (ledig_blk PTR 0).paragr], ax
    ; Fors›k † sl† sammen med neste blokk. (Hvis denne finnes)
        or      bx, bx
        jz      @@proev_forrige
    ; Her finnes en blokk etter. Sjekk om disse kan sl†s sammen.
        mov     cx, bp  ; Segment til blokk som skal frigis
        add     cx, ax
        cmp     cx, bx
        jne     @@proev_forrige
    ; Sl† sammen med neste
        mov     es, bx  ; Neste blokk
        add     ax, [es: (ledig_blk PTR 0).paragr]
        mov     bx, [es: (ledig_blk PTR 0).next]
        mov     es, bp  ; N†v‘rende blokk
        mov     [es: (ledig_blk PTR 0).paragr], ax
        mov     [es: (ledig_blk PTR 0).next], bx
  @@proev_forrige:
    ; Sjekk om det er mulig † sl† sammen forrige blokk og den n†v‘rende.
        mov     es, dx  ; Forrige blokk
        mov     cx, dx
        add     cx, [es: (ledig_blk PTR 0).paragr]
        cmp     cx, bp
        jne     @@ikke_naboer_2
    ; Her kan blokken sl†s sammen med forrige.
        add     [es: (ledig_blk PTR 0).paragr], ax
        mov     [es: (ledig_blk PTR 0).next], bx
  @@ikke_naboer_2:

  @@ret:
        pop     es
        pop     bp
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ENDP    freemem



        END
