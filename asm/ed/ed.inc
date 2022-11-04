  ; Hvis tekster og innlesning av valg skal v‘re p† norsk, defineres
  ; NORSK <> 0.
NORSK       EQU 0


NAVN        EQU "SHH ED"
VER         EQU "v2.5"
DATO        EQU "4/10/93"




; ************************************************************************
; *                                                                      *
; *                F›lgende gjelder styring av editoren.                 *
; *                                                                      *
; ************************************************************************

MAXLIN      EQU 10000   ; Antall linjer det allokeres plass til. max 32767 !
MAXLEN      EQU 255     ; Maks linjelengde

MINMEM      EQU 1536    ; Minne som skal v‘re ledig i paragrafer. 24kb

BPLS        EQU 14      ; Bytes Per Line Segment. Antall bytes med tekst i hver
                        ; del av en linje.

STRUC   linseg          ; LineSegment. Del av linje.
 next       DW  ?
 text       DB  BPLS DUP(?)
ENDS    linseg


; OBS OBS: Hvis ED noen gang skal assembleres med TASM v1.0, m† neste linje
;          assmebleres med MASM p†, siden IDEAL ga feil tall med SIZE.
LINSEGSIZ   =   SIZE linseg     ; Antall bytes totalt pr linjesegment.

; Finn antall paragrafer som brukes av hvert linjesegment
IF (LINSEGSIZ MOD 16) EQ 0
  LINSEGPARA = LINSEGSIZ / 16
ELSE
  LINSEGPARA = 1 + (LINSEGSIZ / 16)
ENDIF

QUITKEY     EQU -45     ; Tast for † avslutte programmet





; ************************************************************************
; *                                                                      *
; *                          Filbehandling                               *
; *                                                                      *
; ************************************************************************

BUFSIZ      EQU 16384   ; Filbufferst›rrelse i bytes

MAXFILE     EQU 80      ; Maks lengde p† filnavn, uten avsluttende 0

MAXCHOOSE   EQU 100     ; Maks antall filer † velge i. (Maks 255 !!)
CHOOSEX     EQU 5       ; Antall filnavn i bredden under valg
CHOOSEY     EQU 12      ; Antall filnavn i h›yden under valg





; ************************************************************************
; *                                                                      *
; *                         S›k og erstatt                               *
; *                                                                      *
; ************************************************************************

FINDLEN     EQU 32      ; Maks lengde p† tekst for s›k/erstatt





; ************************************************************************
; *                                                                      *
; *                           Plukkfiler                                 *
; *                                                                      *
; ************************************************************************

  ; Navn p† pickfilen
PICKFILENAME EQU "ED.PCK", 0

  ;
  ; En linje i pickfilen. Denne m† v‘re <256 bytes !!!
  ;
STRUC   pickrec
  filenm    DB  (MAXFILE + 1) DUP (?)
  fromlin   DW  ?
  fromcol   DW  ?
  curlin    DW  ?
  curcol    DW  ?
  blockon   DB  ?
  blklin1   DW  ?
  blkcol1   DW  ?
  blklin2   DW  ?
  blkcol2   DW  ?
  poslin1   DW  ?
  poscol1   DW  ?
  poslin2   DW  ?
  poscol2   DW  ?
ENDS    pickrec

PICKRECSIZ  =   SIZE pickrec


MAXPICK     EQU 14      ; Antall elementer i en pickfil





; ************************************************************************
; *                                                                      *
; *                         Diverse annet                                *
; *                                                                      *
; ************************************************************************

  ; Bestem hvilke av biblioteksfunksjonene som skal kalles
  ; for at spr†ket skal bli som ›nsket.
IF NORSK
 CHOICE     EQU valg
ELSE
 CHOICE     EQU choice
ENDIF

; Skal musfunksjoner v‘re med?
MOUSE       EQU 1       ; Definer, eller ikke definer.

; Konstanter for bruk under uttesting

SHOW_EOL    EQU 0       ; Viser linjesluttmerke.
SHOW_MEM    EQU 0       ; Skal ledig minne vises ›verst p† skjermen?
SHOW_ALL    EQU 0       ; Skal hele skjermen vises hver gang?
