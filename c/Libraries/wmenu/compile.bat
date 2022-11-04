copy wmenu.h \c\work\myfunc
tcc -c -mt -o\c\work\myfunc\wmenu_t wmenu
tcc -c -ms -o\c\work\myfunc\wmenu_s wmenu
tcc -c -mm -o\c\work\myfunc\wmenu_m wmenu
tcc -c -mc -o\c\work\myfunc\wmenu_c wmenu
tcc -c -ml -o\c\work\myfunc\wmenu_l wmenu
tcc -c -mh -o\c\work\myfunc\wmenu_h wmenu
cd \c\work\myfunc
tlib shhlib_t -+wmenu_t
tlib shhlib_s -+wmenu_s
tlib shhlib_m -+wmenu_m
tlib shhlib_c -+wmenu_c
tlib shhlib_l -+wmenu_l
tlib shhlib_h -+wmenu_h
del wmenu_?.obj
del *.bak
cd \c\work\wmenu
