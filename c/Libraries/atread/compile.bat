CD \C\MYLIBS
COPY \C\SHHLIB\ATREAD\ATREAD.H
BCC -c -mt -v- \C\SHHLIB\ATREAD\ATREAD%1.C
TLIB SHHLIB_T -+ATREAD%1
DEL ATREAD%1.OBJ
BCC -c -ms -v- \C\SHHLIB\ATREAD\ATREAD%1.C
TLIB SHHLIB_S -+ATREAD%1
DEL ATREAD%1.OBJ
BCC -c -mm -v- \C\SHHLIB\ATREAD\ATREAD%1.C
TLIB SHHLIB_M -+ATREAD%1
DEL ATREAD%1.OBJ
BCC -c -mc -v- \C\SHHLIB\ATREAD\ATREAD%1.C
TLIB SHHLIB_C -+ATREAD%1
DEL ATREAD%1.OBJ
BCC -c -ml -v- \C\SHHLIB\ATREAD\ATREAD%1.C
TLIB SHHLIB_L -+ATREAD%1
DEL ATREAD%1.OBJ
BCC -c -mh -v- \C\SHHLIB\ATREAD\ATREAD%1.C
TLIB SHHLIB_H -+ATREAD%1
DEL ATREAD%1.OBJ
DEL *.BAK
CD \C\SHHLIB\ATREAD
