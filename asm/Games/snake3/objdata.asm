        IDEAL

        MODEL   TINY

        ASSUME  cs: @code, ds: @data

DATASEG

        PUBLIC  blank

;
; Space, mellomromstegn.
;
blank:
        REPT 4
        DB      0, 0, 0, 0, 0, 0
        ENDM

;
; Sopp
;
PUBLIC  mush1
mush1   DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      00000h, 00000h, 00000h, 00000h, 00000h, 0003Ch
        DB      00000h, 00000h, 00000h, 00000h, 00000h, 00018h

PUBLIC  mush2
mush2   DB      00000h, 00000h, 00000h, 00000h, 00000h, 00010h
        DB      00000h, 00000h, 00000h, 00000h, 00000h, 00010h
        DB      00000h, 00000h, 00000h, 00000h, 0003Ch, 000FFh
        DB      00000h, 00000h, 00000h, 00000h, 00018h, 0007Eh

PUBLIC  mush3
mush3   DB      00000h, 00000h, 00000h, 00000h, 00010h, 00082h
        DB      00000h, 00000h, 00000h, 00000h, 00010h, 00082h
        DB      00000h, 00000h, 00000h, 0003Ch, 000FFh, 000FFh
        DB      00000h, 00000h, 00000h, 00018h, 0007Eh, 0007Fh

PUBLIC  mush4
mush4   DB      00000h, 00000h, 00000h, 00010h, 00082h, 00008h
        DB      00000h, 00000h, 00000h, 00010h, 00082h, 00008h
        DB      00000h, 00000h, 0003Ch, 000FFh, 000FFh, 00038h
        DB      00000h, 00000h, 00018h, 0007Eh, 0007Fh, 00030h

PUBLIC  mush5
mush5   DB      00000h, 00000h, 00010h, 00082h, 00008h, 00018h
        DB      00000h, 00000h, 00010h, 00082h, 00008h, 00018h
        DB      00000h, 0003Ch, 000FFh, 000FFh, 00038h, 00018h
        DB      00000h, 00018h, 0007Eh, 0007Fh, 00030h, 00010h

PUBLIC  mush6
mush6   DB      00000h, 00010h, 00082h, 00008h, 00018h, 0001Ch
        DB      00000h, 00010h, 00082h, 00008h, 00018h, 0001Ch
        DB      0003Ch, 000FFh, 000FFh, 00038h, 00018h, 0001Ch
        DB      00018h, 0007Eh, 0007Fh, 00030h, 00010h, 00018h

;
; Slankepille
;
PUBLIC  pill
pill    DB      0001Ch, 0005Eh, 000CFh, 000E3h, 0007Bh, 0001Ch
        DB      0001Ch, 0005Eh, 000CFh, 000E3h, 0007Bh, 0001Ch
        DB      0001Ch, 0005Eh, 000CFh, 000E3h, 0007Bh, 0001Ch
        DB      00010h, 0007Ch, 000FCh, 000FFh, 0007Eh, 00010h

;
; F›rste matvare, en p‘re
;
PUBLIC  pear
pear    DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      000E0h, 00078h, 0003Eh, 0007Fh, 0007Fh, 0003Ch
        DB      000E0h, 00020h, 00000h, 00000h, 00000h, 00000h
        DB      00000h, 00008h, 0000Eh, 00001h, 00000h, 00000h

;
; Andre matvare, et jordb‘r
;
PUBLIC  strwbrry
strwbrry DB     00007h, 00008h, 00000h, 00000h, 00000h, 00000h
        DB      00037h, 00038h, 00008h, 00000h, 00000h, 00000h
        DB      00007h, 0004Ah, 000F7h, 000FFh, 0007Eh, 00038h
        DB      00030h, 00030h, 00008h, 00000h, 00000h, 00000h

;
; Tredje matvare, en banan
;
PUBLIC  banana
banana  DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      00001h, 00001h, 00003h, 00007h, 000FFh, 0007Eh
        DB      00001h, 00001h, 00001h, 00003h, 000C6h, 0007Ch
        DB      00001h, 00001h, 00003h, 00007h, 000FEh, 0007Ch

;
; Fjerde matvare, en sitron
;
PUBLIC  lemon
lemon   DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      0001Fh, 0007Fh, 0007Fh, 000FFh, 000FEh, 000FCh
        DB      00016h, 0003Ah, 00078h, 0007Ch, 000F8h, 00040h
        DB      0001Fh, 0007Fh, 0007Fh, 000FFh, 000FEh, 000FCh

;
; En r†tten matvare. Hodeskalle.
;
PUBLIC  skull
skull   DB      0003Ch, 0006Ah, 000C9h, 0007Eh, 00020h, 00099h
        DB      0003Ch, 0006Ah, 000C9h, 0007Eh, 00020h, 00099h
        DB      0003Ch, 0006Ah, 000C9h, 0007Eh, 00020h, 00099h
        DB      0005Ah, 000EBh, 000C9h, 000BDh, 00020h, 00099h

;
; Rammetegn, ›verste venstre hj›rne
;
PUBLIC  ramme1
ramme1  DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      00000h, 00000h, 0000Fh, 00019h, 0001Dh, 00016h
        DB      00000h, 00000h, 0000Fh, 00019h, 0001Dh, 00016h
        DB      00000h, 00000h, 00010h, 00002h, 00000h, 00008h

;
; Rammetegn, ›verste h›yre hj›rne
;
PUBLIC  ramme2
ramme2  DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      00000h, 00000h, 000D8h, 00098h, 000B8h, 00058h
        DB      00000h, 00000h, 000D8h, 00098h, 000B8h, 00058h
        DB      00000h, 00000h, 00020h, 00040h, 00000h, 00020h

;
; Rammetegn, nederste venstre hj›rne
;
PUBLIC  ramme3
ramme3  DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      0001Eh, 00015h, 0001Ah, 0001Eh, 00000h, 00000h
        DB      0001Eh, 00015h, 0001Ah, 0001Eh, 00000h, 00000h
        DB      00000h, 00008h, 00001h, 00001h, 00000h, 00000h

;
; Rammetegn, nederste h›yre hj›rne
;
PUBLIC  ramme4
ramme4  DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      00078h, 000B0h, 000D0h, 00078h, 00000h, 00000h
        DB      00078h, 000B0h, 000D0h, 00078h, 00000h, 00000h
        DB      00000h, 00008h, 00008h, 00080h, 00000h, 00000h

;
; Rammetegn, ›verste linje
;
PUBLIC  ramme5
ramme5  DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      00000h, 00000h, 000FFh, 000BBh, 000E6h, 000DFh
        DB      00000h, 00000h, 000FFh, 000BBh, 000E6h, 000DFh
        DB      00000h, 00000h, 00000h, 00044h, 00019h, 00020h

;
; Rammetegn, nederste linje
;
PUBLIC  ramme6
ramme6  DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      000FBh, 00097h, 000EDh, 000FEh, 00000h, 00000h
        DB      000FBh, 00097h, 000EDh, 000FEh, 00000h, 00000h
        DB      00004h, 00068h, 00012h, 00001h, 00000h, 00000h

;
; Rammetegn, venstre side
;
PUBLIC  ramme7
ramme7  DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      00013h, 0001Bh, 0001Eh, 0001Dh, 00011h, 0001Fh
        DB      00013h, 0001Bh, 0001Eh, 0001Dh, 00011h, 0001Fh
        DB      0000Ch, 00004h, 00001h, 00002h, 0000Eh, 00000h

;
; Rammetegn, h›yre side
;
PUBLIC  ramme8
ramme8  DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      000F0h, 000B8h, 000C8h, 000F8h, 00098h, 000C8h
        DB      000F0h, 000B8h, 000C8h, 000F8h, 00098h, 000C8h
        DB      00008h, 00040h, 00030h, 00000h, 00060h, 00030h

;
; Slangehode opp
;
PUBLIC  slange1
slange1 DB      00000h, 00000h, 00000h, 00044h, 00000h, 00000h
        DB      00038h, 0007Ch, 000FEh, 000FEh, 000FEh, 0007Ch
        DB      00000h, 00000h, 00000h, 00044h, 00000h, 00000h
        DB      00000h, 00000h, 00000h, 00044h, 00000h, 00000h


;
; Slangehode ned
;
PUBLIC  slange2
slange2 DB      00000h, 00000h, 00044h, 00000h, 00000h, 00000h
        DB      0007Ch, 000FEh, 000FEh, 000FEh, 0007Ch, 00038h
        DB      00000h, 00000h, 00044h, 00000h, 00000h, 00000h
        DB      00000h, 00000h, 00044h, 00000h, 00000h, 00000h


;
; Slangehode mot venstre
;
PUBLIC  slange3
slange3 DB      00000h, 0000Ch, 00000h, 00000h, 0000Ch, 00000h
        DB      0001Eh, 0007Fh, 000FFh, 000FFh, 0007Fh, 0001Eh
        DB      00000h, 0000Ch, 00000h, 00000h, 0000Ch, 00000h
        DB      00000h, 0000Ch, 00000h, 00000h, 0000Ch, 00000h


;
; Slangehode mot h›yre
;
PUBLIC  slange4
slange4 DB      00000h, 00030h, 00000h, 00000h, 00030h, 00000h
        DB      00078h, 000FEh, 000FFh, 000FFh, 000FEh, 00078h
        DB      00000h, 00030h, 00000h, 00000h, 00030h, 00000h
        DB      00000h, 00030h, 00000h, 00000h, 00030h, 00000h


;
; Slangehale opp
;
PUBLIC  slange5
slange5 DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      0007Ch, 0007Ch, 00038h, 00038h, 00038h, 00010h
        DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      00000h, 00000h, 00044h, 00000h, 00000h, 00028h


;
; Slangehale ned
;
PUBLIC  slange6
slange6 DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      00010h, 00038h, 00038h, 00038h, 0007Ch, 0007Ch
        DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      00028h, 00000h, 00000h, 00044h, 00000h, 00000h


;
; Slangehale mot venstre
;
PUBLIC  slange7
slange7 DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      00000h, 000E0h, 000FCh, 000FFh, 000E0h, 00000h
        DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      00000h, 00018h, 00002h, 00000h, 00018h, 00000h


;
; Slangehale mot h›yre
;
PUBLIC  slange8
slange8 DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      00000h, 00007h, 000FFh, 0003Fh, 00007h, 00000h
        DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      00000h, 00018h, 00000h, 00040h, 00018h, 00000h


;
; Slangekropp horisontalt
;
PUBLIC  slange9
slange9 DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      00000h, 000FFh, 000FFh, 000FFh, 000FFh, 00000h
        DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      00000h, 00000h, 000FFh, 00000h, 00000h, 00000h


;
; Slangekropp vertikalt
;
PUBLIC  slangeA
slangeA DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      0007Ch, 0007Ch, 0007Ch, 0007Ch, 0007Ch, 0007Ch
        DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      00008h, 00008h, 00008h, 00008h, 00008h, 00008h


;
; Slangekropp nedenifra mot h›yre
;
PUBLIC  slangeB
slangeB DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      00000h, 0000Fh, 0003Fh, 0003Fh, 0007Fh, 0007Ch
        DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      00000h, 00010h, 00003h, 00044h, 00004h, 00006h


;
; Slangekropp fra h›yre og opp
;
PUBLIC  slangeC
slangeC DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      0007Ch, 0007Fh, 0003Fh, 0003Fh, 0000Fh, 00000h
        DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      00006h, 00004h, 00043h, 00000h, 00010h, 00000h


;
; Slangekropp ovenifra mot venstre
;
PUBLIC  slangeD
slangeD DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      0007Ch, 000FCh, 000F8h, 000F8h, 000E0h, 00000h
        DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      00008h, 00008h, 000F4h, 00000h, 00010h, 00000h

;
; Slangekropp fra venstre og ned
;
PUBLIC  slangeE
slangeE DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      00000h, 000E0h, 000F8h, 000F8h, 000FCh, 0007Ch
        DB      00000h, 00000h, 00000h, 00000h, 00000h, 00000h
        DB      00000h, 00010h, 000E0h, 00014h, 00008h, 00008h

;
; Headbanger, 1
;
PUBLIC  hbang1
hbang1  DB      00000h, 00004h, 00007h, 00007h, 00007h, 00007h
        DB      00000h, 00004h, 00007h, 00007h, 00007h, 00007h
        DB      00000h, 00004h, 00007h, 000FFh, 000FFh, 00007h
        DB      00000h, 00002h, 00000h, 00000h, 00000h, 00000h


;
; Headbanger, 2
;
PUBLIC  hbang2
hbang2  DB      00008h, 0000Ch, 0000Eh, 00007h, 00007h, 00000h
        DB      00008h, 0000Ch, 0000Eh, 00007h, 00007h, 00000h
        DB      00008h, 0000Ch, 0001Eh, 000FFh, 000C7h, 00000h
        DB      00000h, 00002h, 00001h, 00000h, 00020h, 00006h


;
; Headbanger, 3
;
PUBLIC  hbang3
hbang3  DB      00038h, 0001Ch, 0000Eh, 00007h, 00006h, 00000h
        DB      00038h, 0001Ch, 0000Eh, 00007h, 00006h, 00000h
        DB      00038h, 0001Ch, 0003Eh, 0007Fh, 000E6h, 000C0h
        DB      00000h, 00002h, 00001h, 00000h, 00001h, 00000h


;
; Headbanger, 4
;
PUBLIC  hbang4
hbang4  DB      00078h, 0001Ch, 0000Eh, 00006h, 00000h, 00000h
        DB      00078h, 0001Ch, 0000Eh, 00006h, 00000h, 00000h
        DB      00078h, 0003Ch, 0007Eh, 000E6h, 000C0h, 00080h
        DB      00000h, 00002h, 00001h, 00001h, 00000h, 00000h




ENDS

        END
