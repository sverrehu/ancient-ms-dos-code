;
; Navn, versjon og dato.
;
NAVN    EQU     "SNAKE3"
VER     EQU     "v1.01"
DATO    EQU     "12/01-1991"



;
; Grenser for hvor pÜ skjermen spillet foregÜr.
; Dette er tegngrenser som brukes av showobjXxX-rutinen
;
MINX    EQU     1
MAXX    EQU     58
MINY    EQU     1
MAXY    EQU     56

INSTRX  EQU     (MAXX + 3)      ; Fõrste kolonne for instruksjoner



;
; Koder for objekter som kan vises pÜ skjermen.
;
BLANK   EQU     0
BORDER  EQU     1
SNAKE   EQU     2
MUSH    EQU     3
BOUNCER EQU     4
ROTTEN  EQU     5
BANGER  EQU     6

FOOD1   EQU     20
FOOD2   EQU     21
FOOD3   EQU     22
FOOD4   EQU     23



;
; Mulige bevegelsesretninger
;
NOMOVE  EQU    -1
UP      EQU     0
DOWN    EQU     1
LEFT    EQU     2
RIGHT   EQU     3



;
; èrsak til spillavbrudd
;
DEAD    EQU     1
ESCAPE  EQU     27
