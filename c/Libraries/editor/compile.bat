copy editor.h ..\myfunc
tcc -c -mt -o\tc\work\myfunc\editor_t editor
tcc -c -ms -o\tc\work\myfunc\editor_s editor
tcc -c -mm -o\tc\work\myfunc\editor_m editor
tcc -c -mc -o\tc\work\myfunc\editor_c editor
tcc -c -ml -o\tc\work\myfunc\editor_l editor
tcc -c -mh -o\tc\work\myfunc\editor_h editor
cd \tc\work\myfunc
TLIB /E shhlib_t -+editor_t
TLIB /E shhlib_s -+editor_s
TLIB /E shhlib_m -+editor_m
TLIB /E shhlib_c -+editor_c
TLIB /E shhlib_l -+editor_l
TLIB /E shhlib_h -+editor_h
del editor_?.obj
cd \tc\work\editor
del *.bak
