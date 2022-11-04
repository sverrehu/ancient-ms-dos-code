PROG1    = MKLOGO
CMODEL   = c
AMODEL   = COMPACT

# DEBUG  = -v
# LNKMAP = -M

!if !$d(LANG)
LANG     = NORWEGIAN
!endif

CSWITCH  = -m$(CMODEL) -c -d -v -D$(LANG)
ASWITCH  = /ml /zi /m2 /d$(LANG) /dMDL=$(AMODEL)

LIBS     = EGA10_C.LIB
OBJS     = MKLOGOLW.OBJ



.AUTODEPEND




$(PROG1).EXE: $(PROG1).OBJ $(OBJS)
    TCC -m$(CMODEL) $(DEBUG) -e$(PROG1) $(PROG1).OBJ $(OBJS) $(LIBS)



.ASM.OBJ:
    TASM $(ASWITCH) $<

.C.OBJ:
    TCC $(CSWITCH) {$< }

.CPP.OBJ:
    TCC $(CSWITCH) {$< }
