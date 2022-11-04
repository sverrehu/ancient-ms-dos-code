        IDEAL

%       MODEL   MDL

        ASSUME  cs: @code, ds: @data, es: NOTHING


INCLUDE "SCRLOW.INC"  ; Makroer


        EXTRN   _init_scrlow: PROC


DATASEG

;-----------;
;           ;
;  D A T A  ;
;           ;
;-----------;

        EXTRN   init: BYTE
        EXTRN   txtattr: BYTE
        EXTRN   stdattr: BYTE



CODESEG

;-----------------------;
;                       ;
;  P R O S E D Y R E R  ;
;                       ;
;-----------------------;

        PUBLIC  _highvideo, _lowvideo, _normvideo


;
; _highvideo
;
; setter intensity-biten i [txtattr]
;
; Definert som:
;     int  cdecl highvideo(void);
;
; Ingen registre ›delagt.
;
PROC    _highvideo
        SETT_DS
        TEST_INIT
        or      [BYTE txtattr], 00001000b
        RESETT_DS
        ret
ENDP    _highvideo


;
; _lowvideo
;
; clearer intensity-biten i [txtattr]
;
; Definert som:
;     int  cdecl lowvideo(void);
;
; Ingen registre ›delagt.
;
PROC    _lowvideo
        SETT_DS
        TEST_INIT
        and     [BYTE txtattr], 11110111b
        RESETT_DS
        ret
ENDP    _lowvideo


;
; _normvideo
;
; setter intensity-biten i [txtattr] slik som i [stdattr]
;
; Definert som:
;     int  cdecl normvideo(void);
;
; Ingen registre ›delagt.
;
PROC    _normvideo
        SETT_DS
        TEST_INIT
        push    ax
        mov     al, 00001000b
        and     al, [stdattr]
        and     [BYTE txtattr], 11110111b
        or      [txtattr], al
        pop     ax
        RESETT_DS
        ret
ENDP    _normvideo


        END
