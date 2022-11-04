PROG      = dosed
EXE       = com

RM        = del
AS        = tasm
LD        = tlink

ASOPT     = /ml /m2
LDOPT     = /t /x

OBJS      =
LIBS      =


.AUTODEPEND



$(PROG).$(EXE): $(PROG).obj $(OBJS)
    $(LD) $(LDOPT) $(PROG).obj $(OBJS), $(PROG).$(EXE),, $(LIBS)

clean:
    $(RM) *.obj
    $(RM) *.bak

veryclean: clean
    $(RM) $(PROG).$(EXE)


.asm.obj:
    $(AS) $(ASOPT) $<
