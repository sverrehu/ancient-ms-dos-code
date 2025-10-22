        ; !!  NB NB NB NB NB  !!!
        ; De to f›lgende m† ikke v‘re definert samtidig!
FIRSTFIT    EQU 1       ; Definer denne for first fit
;BESTFIT    EQU 1       ; Definer denne for best fit


STRUC   ledig_blk
 paragr     DW  ?       ; Antall paragrafer ledig her, inkl denne headeren.
 next       DW  ?       ; Neste ledige blokk. 0=dette er siste.
ENDS    ledig_blk

