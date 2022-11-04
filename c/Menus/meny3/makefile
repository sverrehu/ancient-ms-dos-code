CC        = bcc
RM        = rm -f
AS        = tasm
LD        = tlink

CMODEL    = c
AMODEL    = TINY

OPTIM     = -G -O2 -vi
# DEBUG   = -v

CCOPT     = -c -m$(CMODEL) $(OPTIM) $(DEBUG)
LDOPT     = -m$(CMODEL) $(DEBUG)
ASOPT     = /ml /zi /m2 /dMDL=$(AMODEL)

LIBS      = shhlib_c.lib scrlow_c.lib
OBJS      =


.AUTODEPEND


all: meny.com menyprog.exe menykonf.exe

meny.com: meny.obj
    $(LD) /c /t /x meny

menyprog.exe: menyprog.obj $(OBJS)
    $(CC) $(LDOPT) -emenyprog menyprog.obj $(OBJS) $(LIBS)

menykonf.exe: menykonf.obj $(OBJS)
    $(CC) $(LDOPT) -emenykonf menykonf.obj $(OBJS) $(LIBS)

clean:
    $(RM) *.obj
    $(RM) *.bak

veryclean: clean
    $(RM) meny.com menyprog.exe menykonf.exe


.c.obj:
    $(CC) $(CCOPT) {$< }

.asm.obj:
    $(AS) $(ASOPT) $<
