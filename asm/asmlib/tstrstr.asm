        IDEAL

        MODEL   TINY

CODESEG

        ORG     0100h
        ASSUME  cs: @code, ds: @code, es: @code

        EXTRN   strcmp: PROC

start:  jmp     SHORT main

s1      DB      8 DUP (0)
s2      DB      8 DUP (0)

main:
        mov     si, OFFSET s1
        mov     di, OFFSET s2
  @@en_til:
        call    strcmp
        jmp     @@en_til

ENDS

        END     start
