;
; w_data
;
; Struktur som inneholder data om et vindu
;
STRUC   w_data
 next   DW      ?   ; Segment til neste vindu-struct (hvis fler enn 1)
 size   DW      ?   ; Antall paragr. som skal sendes til freemem
 vx1    DB      ?   ; ùverste venstre X-koordinat
 vy1    DB      ?   ; ùverste venstre Y-koordinat
 vx2    DB      ?   ; Nederste hõyre X-koordinat
 vy2    DB      ?   ; Nederste hõyre Y-koordinat
 curx   DB      ?   ; Cursor X (Virkelige skjermkoordinater)
 cury   DB      ?   ; Cursor Y (Virkelige skjermkoordinater)
 ramme  DB      ?   ; Rammetypen pÜ gjeldende vindu
 tattr  DB      ?   ; Attributten som var aktiv i vinduet
ENDS    w_data

; SIZE fikk jeg ikke til Ü virke i IDEAL mode, sÜ her bytter vi over.
MASM
        w_data_size = SIZE w_data
IDEAL
