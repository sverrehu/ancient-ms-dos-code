;
; Name, version and date
;
PROGNAME    EQU "TETRIS"
PROGVER     EQU "v1.11"
PROGDATE    EQU "5/1-1992"



;
; Size of gameboard
;
BOARDWIDTH  EQU 10
BOARDHEIGHT EQU 28

BOARDSIZE   EQU (BOARDWIDTH * BOARDHEIGHT)



;
; Start of gameboard
;
UPPERX      EQU 8
UPPERY      EQU 2



;
; Where to show the "next" object
;
NEXTX       EQU 0
NEXTY       EQU 4



;
; Constants regarding objects
;
NUMOBJ      EQU 7



;
; Reasons for the game to stop
;
BOARDFULL   EQU 1
ESCAPE      EQU 27



;
; Regarding level etc.
;
MAXLEVEL    EQU 11
COUNTLEVEL  EQU 14              ; Number of lines to remove for each level



;
; For showing instructinons and other text
;
INSTRX      EQU 40              ; First column of instructions on the right
