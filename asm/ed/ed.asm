        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @code, es: NOTHING

INCLUDE "ED.INC"


;--------------------------;
;                          ;
;         D A T A          ;
;                          ;
;--------------------------;

DATASEG

        EXTRN  filenm: PTR

        PUBLIC quit





;--------------------------;
;                          ;
;   P R O S E D Y R E R    ;
;                          ;
;--------------------------;

CODESEG

        ORG     0100h

start:  jmp     SHORT main


        EXTRN  SetupStack: PROC
        EXTRN  initscreen: PROC, endscreen: PROC
        EXTRN  initmem: PROC, endmem: PROC
        EXTRN  initwindow: PROC, endwindow: PROC
        EXTRN  strlen: PROC, strcpy: PROC, strip: PROC, strupr: PROC

        EXTRN  initenviro: PROC, endenviro: PROC
   IF MOUSE
        EXTRN  initmouse: PROC, endmouse: PROC
   ENDIF
        EXTRN  initfilelow: PROC, endfilelow: PROC
        EXTRN  initfile: PROC, endfile: PROC
        EXTRN  initline: PROC, endline: PROC
        EXTRN  initedit: PROC, endedit: PROC
        EXTRN  initblock: PROC, endblock: PROC
        EXTRN  initfind: PROC, endfind: PROC
        EXTRN  initpick: PROC, endpick: PROC, newpickitem: PROC
        EXTRN  loadpickfile: PROC, savepickfile: PROC, loadfrompick: PROC
        EXTRN  showfilename: PROC
        EXTRN  readfile: PROC, loadfile: PROC, reset_ed: PROC
        EXTRN  expandfilename: PROC
        EXTRN  edit: PROC


;---------------------------------;
;                                 ;
;  H O V E D P R O G R A M M E T  ;
;                                 ;
;---------------------------------;

main:
        mov     ax, cs
        mov     ds, ax                  ;
        mov     es, ax                  ; I tilfelle debugging (ikke Tiny)

        call    SetupStack

        call    initmem                 ; Initier moduler fra ASMLIB
        call    initscreen
        call    initwindow

        cmp     [BYTE 0080h], 0         ; Er ingen parameter angitt p†
        jne     @@get_filename          ;   kommandolinjen?

  @@no_filename:
        mov     [filenm], 0             ; Angi tom streng
        jmp     SHORT @@initiate

  @@get_filename:
    ; Les inn filen som er angitt p† kommandolinjen. F›rst m† linjen endres
    ; slik at CR p† slutten byttes ut med 0. Alts†: lag ASCIIZ-string.
        mov     bl, [80h]
        xor     bh, bh
        add     bx, 81h
        mov     [BYTE bx], 0
        mov     dx, 81h                 ; DX peker til starten av filnavnet
        call    strip                   ; Sjekk om bare blanke
        call    strlen
        or      ax, ax
        je      @@no_filename
        mov     bx, dx                  ; Fjern blanke i beg. av linjen
  @@sjekk_om_blank:
        cmp     [BYTE bx], ' '
        jne     @@ikke_fler_blanke
        inc     bx
        jmp     SHORT @@sjekk_om_blank
  @@ikke_fler_blanke:
        mov     si, bx
        mov     di, OFFSET filenm
        mov     dx, di
        call    strcpy
        call    strupr

  @@initiate:
        call    initenviro              ; Initier interne moduler
        call    initfilelow
        call    initfile
        call    initline
        call    initedit
   IF MOUSE
        call    initmouse
   ENDIF
        call    initblock
        call    initfind
        call    initpick

    ; Les inn en evt pickfil
        call    loadpickfile

    ; Hvis det ikke er angitt noe filnavn, skal det f›rste i pickfilen
    ; leses inn. Hvis ikke dette er noe, skal bruker angi et navn.
    ; Dette tar readfrompick seg av.
        cmp     [BYTE filenm], 0        ; Tom streng?
        jz      @@no_name_given

        mov     si, OFFSET filenm
        call    expandfilename          ; Dette gj›r vanligvis getfilename
        jc      @@end_edit
        call    readfile
        jmp     SHORT @@start_edit

  @@no_name_given:
        xor     ax, ax                  ; Angi at f›rste i pickfilen
        call    loadfrompick
        jc      @@end_edit              ; Hvis avbrutt av bruker

  @@start_edit:
        call    edit

    ; Lagre evt pickfilen
        call    savepickfile

  @@end_edit:
        call    endpick
        call    endfind
        call    endblock
   IF MOUSE
        call    endmouse
   ENDIF
        call    endedit
        call    endline
        call    endfile
        call    endfilelow
        call    endenviro               ; Rydd opp etter interne moduler

quit:   call    endwindow               ; Rydd opp etter moduler fra ASMLIB
        call    endscreen
        call    endmem
        mov     ax, 4C00h
        int     21h

ENDS

        END     start
