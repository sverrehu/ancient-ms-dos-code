        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @code


INCLUDE "SNAKE3.INC"


INSX    EQU     6       ; Instruksjonenes startkoordinater
INSY    EQU     8


DATASEG


insmsg  DB      11, 14  ; Sett farge gul
        DB      "       --->  I N S T R U C T I O N S  <---"
        DB      13, 10, 10, 10, 10, 10, 10, 10

        DB      11, 7
        DB      "MOVE THE SNAKE AROUND THE SCREEN AND EAT THE FOOD", 13, 10
        DB      "WITHOUT  HITTING THE  FENCE, EATING  MUSHROOMS OR", 13, 10
        DB      "ROTTEN FOOD (SYMBOLISED BY SKULLS) OR BITING YOUR", 13, 10
        DB      "OWN TAIL.", 13, 10, 10, 10, 10

        DB      11, 5
        DB      "NOW AND THEN A ", 11, 13, "SLIM-PILL", 11, 5
        DB      "  WILL BOUNCE  AROUND. IF", 13, 10
        DB      "YOU EAT THIS, THE SNAKE  WILL BECOME 1/5 SHORTER,", 13, 10
        DB      "AND YOU WILL BE GIVEN 10 PTS FOR EACH  LENGTH YOU", 13, 10
        DB      "LOOSE.  THIS BONUS IS ALSO GIVEN  WHEN A ROUND IS", 13, 10
        DB      "OVER.", 13, 10, 10, 10, 10

        DB      11, 2
        DB      "WHEN FOOD  STARTS  BLINKING, IT WILL SOON  BECOME", 13, 10
        DB      "ROTTEN, AND THUS UNEATABLE. AS LONG AS IT BLINKS,", 13, 10
        DB      "IT CAN STILL BE EATEN, GIVING NORMAL POINTS."
        DB      13, 10, 10, 10, 10

        DB      11, 4
        DB      "OH, YES - I ALMOST FORGOT : YOU MAY BE VISITED BY", 13, 10
        DB      11, 12, "THE EVIL HEADBANGER", 11, 4
        DB      ".  TAKE MY ADVICE AND RUN AWAY", 13, 10
        DB      "FROM HIM BEFORE HE GETS YOU! HE WON'T STAY LONG!"
        DB      13, 10, 10, 10, 10, 10, 10

        DB      11, 8
        DB      "WRITTEN  IN  TURBO  ASSEMBLER 2.0  ", DATO, "  BY", 13, 10, 10
        DB      "                SVERRE H. HUSEBY", 13, 10
        DB      "                FRANKENDALSVN. 21", 13, 10
        DB      "                N - 3250 LARVIK", 13, 10
        DB      "                NORWAY", 13, 10, 10
        DB      "THX TO BROTHER REIDAR FOR INVENTING THE SLIM-PILL"

        DB      0




CODESEG

        EXTRN   showtxt8x6: PROC

        PUBLIC  instructions



;
; instructions
;
; Hva prosedyren gj›r:
;   Viser hovedinstruksjonene i spillomr†det.
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
PROC    instructions
        push    ax
        push    dx
        push    si

        mov     dx, INSX + 256 * INSY
        mov     si, OFFSET insmsg
        call    showtxt8x6

        pop     si
        pop     dx
        pop     ax
        ret
ENDP    instructions




ENDS

        END
