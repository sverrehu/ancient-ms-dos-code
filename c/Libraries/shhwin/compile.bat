copy shhwin.h \c\mylibs
bcc -c -mt -v- -O2 -o\c\mylibs\shhwin_t shhwin.c
bcc -c -ms -v- -O2 -o\c\mylibs\shhwin_s shhwin.c
bcc -c -mm -v- -O2 -o\c\mylibs\shhwin_m shhwin.c
bcc -c -mc -v- -O2 -o\c\mylibs\shhwin_c shhwin.c
bcc -c -ml -v- -O2 -o\c\mylibs\shhwin_l shhwin.c
bcc -c -mh -v- -O2 -o\c\mylibs\shhwin_h shhwin.c
cd \c\mylibs
tlib shhlib_t -+shhwin_t
tlib shhlib_s -+shhwin_s
tlib shhlib_m -+shhwin_m
tlib shhlib_c -+shhwin_c
tlib shhlib_l -+shhwin_l
tlib shhlib_h -+shhwin_h
del shhwin_?.obj
del *.bak
cd \c\shhlib\shhwin