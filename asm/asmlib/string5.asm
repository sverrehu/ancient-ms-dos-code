        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data, es: NOTHING



;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        EXTRN   strlen: PROC

        PUBLIC  strstr


;
; strstr
;
; Hva prosedyren gj›r:
;   S›ker etter en streng i en annen.
;
; Kall med:
;   DS:SI - Substring som det s›kes etter
;   ES:DI - Streng substringen skal finnes i.
;
; Returnerer:
;   AX : Peker til elementet, slik at ES:AX peker til det.
;        0 hvis ikke funnet.
;
; Endrer innholdet i:
;   AX
;
PROC    strstr
        push    bx
        push    cx
        push    dx
        push    di
        push    si



  ; Finn lengden p† substrengen, og legg denne i BX
        mov     dx, si
        call    strlen
        or      ax, ax          ; Hvis 0: de er like.
        jnz     @@ikke_tom
        mov     ax, di
        jmp     SHORT @@ret
@@ikke_tom:
        mov     bx, ax

  ; Finn lengden p† hovedstrengen, og legg denne i CX
        push    ds
        push    es
        pop     ds
        mov     dx, di
        call    strlen
        mov     cx, ax
        pop     ds

  ; Finn hvor mange s›k som maks m† foretas. Det er ikke n›dvendig
  ; † lete hvis substringen er lenger enn hovedstrengen.
        sub     cx, bx
        jc      @@ret_ikke_funnet
        inc     cx

  ; Utf›r tester bortover hovedstrengen til det ikke er mer igjen
  ; † teste, eller til strengene er like.

  ; AX "passer p†" posisjonen i hovedstrengen, og DX peker til
  ; starten p† substrengen.
        mov     ax, di
        mov     dx, si

        cld
@@ny_runde:
  ; Sjekk om like
        push    cx
        mov     cx, bx          ; Lengden p† substringen
        repe    cmpsb
        pop     cx
        je      @@ret

  ; Forel›pig ikke like, pr›v ny runde.
        mov     si, dx
        inc     ax
        mov     di, ax

        loop    @@ny_runde

@@ret_ikke_funnet:
        xor     ax, ax

@@ret:  pop     si
        pop     di
        pop     dx
        pop     cx
        pop     bx
        ret
ENDP    strstr


        END
