        IDEAL

        MODEL   TINY

        ASSUME  ds: @data


DATASEG

LOGOX   =       19 ; Bytes i X-retn.
LOGOY   =       43 ; Bytes i Y-retn.

PUBLIC  logodata, LOGOX, LOGOY
LABEL   logodata BYTE
  ; Data for bitplan 0
        DB      000h, 007h, 0F9h, 09Fh, 000h, 0FFh, 080h, 00Ch, 000h, 03Fh
        DB      0F0h, 0FFh, 03Fh, 0FFh, 0F8h, 000h, 000h, 0FFh, 000h, 000h
        DB      00Fh, 0FFh, 0BFh, 081h, 0FFh, 080h, 01Ch, 000h, 07Fh, 0F1h
        DB      0FFh, 07Fh, 0FFh, 0F8h, 000h, 003h, 0FFh, 0C0h, 000h, 038h
        DB      01Fh, 08Fh, 080h, 07Eh, 000h, 03Ch, 000h, 01Fh, 0C0h, 078h
        DB      01Fh, 083h, 0F8h, 000h, 007h, 0C7h, 0C0h, 000h, 0F0h, 01Fh
        DB      00Fh, 0C0h, 078h, 000h, 07Ch, 000h, 01Fh, 001h, 0E0h, 01Fh
        DB      001h, 0F0h, 000h, 00Eh, 007h, 0E0h, 001h, 0F0h, 00Fh, 00Fh
        DB      0C0h, 078h, 000h, 0FCh, 000h, 01Fh, 003h, 0C0h, 01Fh, 000h
        DB      0F0h, 000h, 01Fh, 003h, 0E0h, 003h, 0F8h, 00Eh, 01Fh, 0E0h
        DB      0F0h, 001h, 0FCh, 000h, 03Eh, 00Fh, 000h, 03Eh, 000h, 0E0h
        DB      000h, 03Fh, 007h, 0C0h, 003h, 0FCh, 00Eh, 01Fh, 0E0h, 0F0h
        DB      003h, 0FCh, 000h, 03Eh, 01Eh, 000h, 03Eh, 018h, 000h, 000h
        DB      01Fh, 007h, 0C0h, 003h, 0FFh, 000h, 03Fh, 0F1h, 0E0h, 007h
        DB      0FCh, 000h, 07Ch, 078h, 000h, 07Ch, 038h, 000h, 000h, 000h
        DB      01Fh, 000h, 001h, 0FFh, 080h, 03Fh, 0F1h, 0E0h, 00Fh, 07Ch
        DB      000h, 07Ch, 0F0h, 000h, 07Ch, 078h, 000h, 000h, 001h, 0FEh
        DB      000h, 000h, 0FFh, 0E0h, 07Bh, 0FBh, 0C0h, 01Eh, 07Ch, 000h
        DB      0FBh, 0E0h, 000h, 0FFh, 0F0h, 000h, 000h, 003h, 0FEh, 000h
        DB      000h, 03Fh, 0E0h, 079h, 0FBh, 0C0h, 03Ch, 07Ch, 000h, 0FFh
        DB      0E0h, 000h, 0FFh, 0F0h, 000h, 000h, 000h, 07Eh, 000h, 000h
        DB      01Fh, 0F0h, 0F1h, 0FFh, 080h, 078h, 07Ch, 001h, 0FFh, 0F0h
        DB      001h, 0F1h, 0E0h, 000h, 000h, 000h, 07Eh, 000h, 000h, 007h
        DB      0F0h, 0F0h, 0FFh, 080h, 0FFh, 0FCh, 001h, 0FFh, 0F0h, 001h
        DB      0F0h, 0E0h, 000h, 000h, 000h, 03Eh, 000h, 018h, 007h, 0F1h
        DB      0E0h, 0FFh, 001h, 0FFh, 0FCh, 003h, 0F3h, 0F8h, 003h, 0E1h
        DB      0C0h, 000h, 000h, 000h, 07Eh, 000h, 038h, 003h, 0F1h, 0E0h
        DB      07Fh, 003h, 0C0h, 07Ch, 003h, 0E1h, 0F8h, 003h, 0E0h, 006h
        DB      000h, 001h, 0E0h, 07Eh, 000h, 078h, 003h, 0E3h, 0C0h, 07Eh
        DB      007h, 080h, 07Ch, 007h, 0C1h, 0FCh, 007h, 0C0h, 00Eh, 000h
        DB      003h, 0E0h, 0FCh, 000h, 078h, 003h, 0E3h, 0C0h, 03Eh, 00Fh
        DB      000h, 07Ch, 007h, 0C0h, 0FCh, 007h, 0C0h, 03Eh, 000h, 007h
        DB      0E1h, 0F8h, 000h, 0FCh, 007h, 087h, 080h, 07Ch, 01Eh, 000h
        DB      07Eh, 00Fh, 0C0h, 0FEh, 00Fh, 080h, 0FCh, 000h, 00Fh, 083h
        DB      0F0h, 000h, 0FFh, 0FFh, 03Fh, 0E0h, 03Ch, 0FFh, 001h, 0FFh
        DB      07Fh, 0E3h, 0FFh, 0FFh, 0FFh, 0FCh, 000h, 007h, 0FFh, 0E0h
        DB      000h, 0DFh, 0F8h, 07Fh, 0E0h, 079h, 0FFh, 003h, 0FFh, 0FFh
        DB      0E7h, 0FFh, 0FFh, 0FFh, 0F8h, 000h, 003h, 0FFh, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 0C0h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 0C0h, 001h, 060h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 0E0h, 001h, 020h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 01Eh, 000h, 000h, 000h
        DB      000h, 000h, 001h, 0B0h, 001h, 010h, 000h, 000h, 080h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 031h, 080h, 000h, 000h, 000h
        DB      000h, 03Dh, 010h, 001h, 010h, 000h, 000h, 080h, 000h, 0C0h
        DB      000h, 000h, 000h, 000h, 030h, 080h, 000h, 000h, 000h, 000h
        DB      00Dh, 010h, 03Dh, 030h, 000h, 000h, 080h, 000h, 030h, 000h
        DB      00Fh, 091h, 000h, 01Eh, 000h, 00Eh, 000h, 000h, 000h, 009h
        DB      010h, 005h, 020h, 000h, 000h, 0C0h, 000h, 010h, 000h, 004h
        DB      04Ah, 000h, 003h, 0DFh, 00Bh, 079h, 0C3h, 000h, 009h, 030h
        DB      005h, 060h, 000h, 000h, 0C0h, 000h, 008h, 000h, 007h, 084h
        DB      000h, 000h, 051h, 049h, 04Dh, 072h, 080h, 03Fh, 0E0h, 005h
        DB      0C0h, 000h, 000h, 0C0h, 000h, 008h, 000h, 004h, 044h, 000h
        DB      0C0h, 053h, 07Fh, 04Dh, 032h, 080h, 0E5h, 000h, 03Fh, 002h
        DB      03Ch, 018h, 0C0h, 000h, 008h, 000h, 00Fh, 084h, 000h, 071h
        DB      0C6h, 04Ch, 049h, 022h, 080h, 0C5h, 000h, 065h, 013h, 023h
        DB      014h, 0C9h, 000h, 010h, 000h, 000h, 000h, 000h, 00Fh, 007h
        DB      0C6h, 0CDh, 033h, 000h, 07Dh, 008h, 064h, 091h, 029h, 015h
        DB      04Fh, 010h, 030h, 000h, 000h, 000h, 000h, 000h, 000h, 003h
        DB      087h, 01Eh, 0D8h, 001h, 0C0h, 03Ch, 091h, 02Dh, 009h, 059h
        DB      090h, 040h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 030h, 000h, 0C0h, 000h, 06Fh, 0A7h, 0FEh, 070h, 0F7h
        DB      080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 060h, 000h, 000h, 03Ch, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 001h, 0F0h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 001h, 010h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 001h, 090h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 070h, 000h, 000h

  ; Data for bitplan 1
        DB      000h, 007h, 0F9h, 09Fh, 000h, 0FFh, 080h, 00Ch, 000h, 03Fh
        DB      0F0h, 0FFh, 03Fh, 0FFh, 0F8h, 000h, 000h, 0FFh, 000h, 000h
        DB      000h, 00Ch, 081h, 080h, 000h, 080h, 004h, 000h, 000h, 010h
        DB      001h, 000h, 000h, 008h, 000h, 003h, 001h, 0C0h, 000h, 000h
        DB      000h, 080h, 080h, 002h, 000h, 004h, 000h, 000h, 040h, 008h
        DB      000h, 080h, 008h, 000h, 004h, 040h, 040h, 000h, 010h, 001h
        DB      000h, 0C0h, 008h, 000h, 004h, 000h, 001h, 000h, 020h, 001h
        DB      000h, 010h, 000h, 002h, 000h, 060h, 000h, 010h, 001h, 000h
        DB      040h, 008h, 000h, 004h, 000h, 001h, 000h, 040h, 001h, 000h
        DB      010h, 000h, 003h, 000h, 020h, 000h, 018h, 002h, 000h, 060h
        DB      010h, 000h, 004h, 000h, 002h, 001h, 000h, 002h, 000h, 020h
        DB      000h, 001h, 000h, 040h, 000h, 00Ch, 002h, 000h, 020h, 010h
        DB      000h, 004h, 000h, 002h, 002h, 000h, 002h, 018h, 000h, 000h
        DB      001h, 000h, 040h, 000h, 007h, 000h, 000h, 030h, 020h, 000h
        DB      084h, 000h, 004h, 008h, 000h, 004h, 008h, 000h, 000h, 000h
        DB      001h, 000h, 000h, 001h, 080h, 004h, 010h, 020h, 001h, 004h
        DB      000h, 004h, 010h, 000h, 004h, 048h, 000h, 000h, 001h, 0C2h
        DB      000h, 000h, 000h, 0E0h, 008h, 018h, 040h, 002h, 004h, 000h
        DB      008h, 060h, 000h, 00Fh, 010h, 000h, 000h, 000h, 00Eh, 000h
        DB      000h, 000h, 020h, 008h, 008h, 040h, 004h, 004h, 000h, 008h
        DB      020h, 000h, 000h, 010h, 000h, 000h, 000h, 002h, 000h, 000h
        DB      000h, 030h, 010h, 008h, 080h, 008h, 004h, 000h, 000h, 030h
        DB      000h, 010h, 020h, 000h, 000h, 000h, 002h, 000h, 000h, 000h
        DB      010h, 010h, 000h, 080h, 01Fh, 084h, 000h, 004h, 010h, 000h
        DB      010h, 020h, 000h, 000h, 000h, 002h, 000h, 018h, 000h, 010h
        DB      020h, 001h, 000h, 000h, 004h, 000h, 010h, 018h, 000h, 020h
        DB      040h, 000h, 000h, 000h, 002h, 000h, 008h, 000h, 010h, 020h
        DB      001h, 000h, 040h, 004h, 000h, 020h, 008h, 000h, 020h, 006h
        DB      000h, 001h, 0E0h, 002h, 000h, 018h, 000h, 020h, 040h, 002h
        DB      000h, 080h, 004h, 000h, 040h, 00Ch, 000h, 040h, 002h, 000h
        DB      000h, 020h, 004h, 000h, 008h, 000h, 020h, 040h, 002h, 001h
        DB      000h, 004h, 000h, 040h, 004h, 000h, 040h, 022h, 000h, 000h
        DB      020h, 008h, 000h, 00Ch, 000h, 080h, 080h, 004h, 002h, 000h
        DB      006h, 000h, 0C0h, 006h, 000h, 080h, 084h, 000h, 001h, 080h
        DB      010h, 000h, 007h, 0F1h, 030h, 060h, 004h, 0C3h, 001h, 083h
        DB      060h, 063h, 083h, 0E0h, 0FEh, 004h, 000h, 000h, 0F8h, 020h
        DB      000h, 040h, 008h, 000h, 020h, 008h, 001h, 000h, 001h, 000h
        DB      020h, 000h, 000h, 000h, 008h, 000h, 000h, 001h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 0C0h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 0C0h, 001h, 060h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 0E0h, 001h, 020h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 01Eh, 000h, 000h, 000h
        DB      000h, 000h, 001h, 0B0h, 001h, 010h, 000h, 000h, 080h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 031h, 080h, 000h, 000h, 000h
        DB      000h, 03Dh, 010h, 001h, 010h, 000h, 000h, 080h, 000h, 0C0h
        DB      000h, 000h, 000h, 000h, 030h, 080h, 000h, 000h, 000h, 000h
        DB      00Dh, 010h, 03Dh, 030h, 000h, 000h, 080h, 000h, 030h, 000h
        DB      00Fh, 091h, 000h, 01Eh, 000h, 00Eh, 000h, 000h, 000h, 009h
        DB      010h, 005h, 020h, 000h, 000h, 0C0h, 000h, 010h, 000h, 004h
        DB      04Ah, 000h, 003h, 0DFh, 00Bh, 079h, 0C3h, 000h, 009h, 030h
        DB      005h, 060h, 000h, 000h, 0C0h, 000h, 008h, 000h, 007h, 084h
        DB      000h, 000h, 051h, 049h, 04Dh, 072h, 080h, 03Fh, 0E0h, 005h
        DB      0C0h, 000h, 000h, 0C0h, 000h, 008h, 000h, 004h, 044h, 000h
        DB      0C0h, 053h, 07Fh, 04Dh, 032h, 080h, 0E5h, 000h, 03Fh, 002h
        DB      03Ch, 018h, 0C0h, 000h, 008h, 000h, 00Fh, 084h, 000h, 071h
        DB      0C6h, 04Ch, 049h, 022h, 080h, 0C5h, 000h, 065h, 013h, 023h
        DB      014h, 0C9h, 000h, 010h, 000h, 000h, 000h, 000h, 00Fh, 007h
        DB      0C6h, 0CDh, 033h, 000h, 07Dh, 008h, 064h, 091h, 029h, 015h
        DB      04Fh, 010h, 030h, 000h, 000h, 000h, 000h, 000h, 000h, 003h
        DB      087h, 01Eh, 0D8h, 001h, 0C0h, 03Ch, 091h, 02Dh, 009h, 059h
        DB      090h, 040h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 030h, 000h, 0C0h, 000h, 06Fh, 0A7h, 0FEh, 070h, 0F7h
        DB      080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 060h, 000h, 000h, 03Ch, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 001h, 0F0h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 001h, 010h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 001h, 090h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 070h, 000h, 000h

  ; Data for bitplan 2
        DB      000h, 007h, 0F9h, 09Fh, 000h, 0FFh, 080h, 00Ch, 000h, 03Fh
        DB      0F0h, 0FFh, 03Fh, 0FFh, 0F8h, 000h, 000h, 0FFh, 000h, 000h
        DB      000h, 00Ch, 081h, 080h, 000h, 080h, 004h, 000h, 000h, 010h
        DB      001h, 000h, 000h, 008h, 000h, 003h, 001h, 0C0h, 000h, 000h
        DB      000h, 080h, 080h, 002h, 000h, 004h, 000h, 000h, 040h, 008h
        DB      000h, 080h, 008h, 000h, 004h, 040h, 040h, 000h, 010h, 001h
        DB      000h, 0C0h, 008h, 000h, 004h, 000h, 001h, 000h, 020h, 001h
        DB      000h, 010h, 000h, 002h, 000h, 060h, 000h, 010h, 001h, 000h
        DB      040h, 008h, 000h, 004h, 000h, 001h, 000h, 040h, 001h, 000h
        DB      010h, 000h, 003h, 000h, 020h, 000h, 018h, 002h, 000h, 060h
        DB      010h, 000h, 004h, 000h, 002h, 001h, 000h, 002h, 000h, 020h
        DB      000h, 001h, 000h, 040h, 000h, 00Ch, 002h, 000h, 020h, 010h
        DB      000h, 004h, 000h, 002h, 002h, 000h, 002h, 018h, 000h, 000h
        DB      001h, 000h, 040h, 000h, 007h, 000h, 000h, 030h, 020h, 000h
        DB      084h, 000h, 004h, 008h, 000h, 004h, 008h, 000h, 000h, 000h
        DB      001h, 000h, 000h, 001h, 080h, 004h, 010h, 020h, 001h, 004h
        DB      000h, 004h, 010h, 000h, 004h, 048h, 000h, 000h, 001h, 0C2h
        DB      000h, 000h, 000h, 0E0h, 008h, 018h, 040h, 002h, 004h, 000h
        DB      008h, 060h, 000h, 00Fh, 010h, 000h, 000h, 000h, 00Eh, 000h
        DB      000h, 000h, 020h, 008h, 008h, 040h, 004h, 004h, 000h, 008h
        DB      020h, 000h, 000h, 010h, 000h, 000h, 000h, 002h, 000h, 000h
        DB      000h, 030h, 010h, 008h, 080h, 008h, 004h, 000h, 000h, 030h
        DB      000h, 010h, 020h, 000h, 000h, 000h, 002h, 000h, 000h, 000h
        DB      010h, 010h, 000h, 080h, 01Fh, 084h, 000h, 004h, 010h, 000h
        DB      010h, 020h, 000h, 000h, 000h, 002h, 000h, 018h, 000h, 010h
        DB      020h, 001h, 000h, 000h, 004h, 000h, 010h, 018h, 000h, 020h
        DB      040h, 000h, 000h, 000h, 002h, 000h, 008h, 000h, 010h, 020h
        DB      001h, 000h, 040h, 004h, 000h, 020h, 008h, 000h, 020h, 006h
        DB      000h, 001h, 0E0h, 002h, 000h, 018h, 000h, 020h, 040h, 002h
        DB      000h, 080h, 004h, 000h, 040h, 00Ch, 000h, 040h, 002h, 000h
        DB      000h, 020h, 004h, 000h, 008h, 000h, 020h, 040h, 002h, 001h
        DB      000h, 004h, 000h, 040h, 004h, 000h, 040h, 022h, 000h, 000h
        DB      020h, 008h, 000h, 00Ch, 000h, 080h, 080h, 004h, 002h, 000h
        DB      006h, 000h, 0C0h, 006h, 000h, 080h, 084h, 000h, 001h, 080h
        DB      010h, 000h, 007h, 0F1h, 030h, 060h, 004h, 0C3h, 001h, 083h
        DB      060h, 063h, 083h, 0E0h, 0FEh, 004h, 000h, 000h, 0F8h, 020h
        DB      000h, 040h, 008h, 000h, 020h, 008h, 001h, 000h, 001h, 000h
        DB      020h, 000h, 000h, 000h, 008h, 000h, 000h, 001h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 0C0h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 0C0h, 001h, 060h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 0E0h, 001h, 020h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 01Eh, 000h, 000h, 000h
        DB      000h, 000h, 001h, 0B0h, 001h, 010h, 000h, 000h, 080h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 031h, 080h, 000h, 000h, 000h
        DB      000h, 03Dh, 010h, 001h, 010h, 000h, 000h, 080h, 000h, 0C0h
        DB      000h, 000h, 000h, 000h, 030h, 080h, 000h, 000h, 000h, 000h
        DB      00Dh, 010h, 03Dh, 030h, 000h, 000h, 080h, 000h, 030h, 000h
        DB      00Fh, 091h, 000h, 01Eh, 000h, 00Eh, 000h, 000h, 000h, 009h
        DB      010h, 005h, 020h, 000h, 000h, 0C0h, 000h, 010h, 000h, 004h
        DB      04Ah, 000h, 003h, 0DFh, 00Bh, 079h, 0C3h, 000h, 009h, 030h
        DB      005h, 060h, 000h, 000h, 0C0h, 000h, 008h, 000h, 007h, 084h
        DB      000h, 000h, 051h, 049h, 04Dh, 072h, 080h, 03Fh, 0E0h, 005h
        DB      0C0h, 000h, 000h, 0C0h, 000h, 008h, 000h, 004h, 044h, 000h
        DB      0C0h, 053h, 07Fh, 04Dh, 032h, 080h, 0E5h, 000h, 03Fh, 002h
        DB      03Ch, 018h, 0C0h, 000h, 008h, 000h, 00Fh, 084h, 000h, 071h
        DB      0C6h, 04Ch, 049h, 022h, 080h, 0C5h, 000h, 065h, 013h, 023h
        DB      014h, 0C9h, 000h, 010h, 000h, 000h, 000h, 000h, 00Fh, 007h
        DB      0C6h, 0CDh, 033h, 000h, 07Dh, 008h, 064h, 091h, 029h, 015h
        DB      04Fh, 010h, 030h, 000h, 000h, 000h, 000h, 000h, 000h, 003h
        DB      087h, 01Eh, 0D8h, 001h, 0C0h, 03Ch, 091h, 02Dh, 009h, 059h
        DB      090h, 040h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 030h, 000h, 0C0h, 000h, 06Fh, 0A7h, 0FEh, 070h, 0F7h
        DB      080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 060h, 000h, 000h, 03Ch, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 001h, 0F0h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 001h, 010h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 001h, 090h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 070h, 000h, 000h

  ; Data for bitplan 3
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      00Fh, 0F3h, 03Eh, 001h, 0FFh, 000h, 018h, 000h, 07Fh, 0E1h
        DB      0FEh, 07Fh, 0FFh, 0F0h, 000h, 000h, 0FEh, 000h, 000h, 038h
        DB      01Fh, 00Fh, 000h, 07Ch, 000h, 038h, 000h, 01Fh, 080h, 070h
        DB      01Fh, 003h, 0F0h, 000h, 003h, 087h, 080h, 000h, 0E0h, 01Eh
        DB      00Fh, 000h, 070h, 000h, 078h, 000h, 01Eh, 001h, 0C0h, 01Eh
        DB      001h, 0E0h, 000h, 00Ch, 007h, 080h, 001h, 0E0h, 00Eh, 00Fh
        DB      080h, 070h, 000h, 0F8h, 000h, 01Eh, 003h, 080h, 01Eh, 000h
        DB      0E0h, 000h, 01Ch, 003h, 0C0h, 003h, 0E0h, 00Ch, 01Fh, 080h
        DB      0E0h, 001h, 0F8h, 000h, 03Ch, 00Eh, 000h, 03Ch, 000h, 0C0h
        DB      000h, 03Eh, 007h, 080h, 003h, 0F0h, 00Ch, 01Fh, 0C0h, 0E0h
        DB      003h, 0F8h, 000h, 03Ch, 01Ch, 000h, 03Ch, 000h, 000h, 000h
        DB      01Eh, 007h, 080h, 003h, 0F8h, 000h, 03Fh, 0C1h, 0C0h, 007h
        DB      078h, 000h, 078h, 070h, 000h, 078h, 030h, 000h, 000h, 000h
        DB      01Eh, 000h, 001h, 0FEh, 000h, 03Bh, 0E1h, 0C0h, 00Eh, 078h
        DB      000h, 078h, 0E0h, 000h, 078h, 030h, 000h, 000h, 000h, 03Ch
        DB      000h, 000h, 0FFh, 000h, 073h, 0E3h, 080h, 01Ch, 078h, 000h
        DB      0F3h, 080h, 000h, 0F0h, 0E0h, 000h, 000h, 003h, 0F0h, 000h
        DB      000h, 03Fh, 0C0h, 071h, 0F3h, 080h, 038h, 078h, 000h, 0F7h
        DB      0C0h, 000h, 0FFh, 0E0h, 000h, 000h, 000h, 07Ch, 000h, 000h
        DB      01Fh, 0C0h, 0E1h, 0F7h, 000h, 070h, 078h, 001h, 0FFh, 0C0h
        DB      001h, 0E1h, 0C0h, 000h, 000h, 000h, 07Ch, 000h, 000h, 007h
        DB      0E0h, 0E0h, 0FFh, 000h, 0E0h, 078h, 001h, 0FBh, 0E0h, 001h
        DB      0E0h, 0C0h, 000h, 000h, 000h, 03Ch, 000h, 000h, 007h, 0E1h
        DB      0C0h, 0FEh, 001h, 0FFh, 0F8h, 003h, 0E3h, 0E0h, 003h, 0C1h
        DB      080h, 000h, 000h, 000h, 07Ch, 000h, 030h, 003h, 0E1h, 0C0h
        DB      07Eh, 003h, 080h, 078h, 003h, 0C1h, 0F0h, 003h, 0C0h, 000h
        DB      000h, 000h, 000h, 07Ch, 000h, 060h, 003h, 0C3h, 080h, 07Ch
        DB      007h, 000h, 078h, 007h, 081h, 0F0h, 007h, 080h, 00Ch, 000h
        DB      003h, 0C0h, 0F8h, 000h, 070h, 003h, 0C3h, 080h, 03Ch, 00Eh
        DB      000h, 078h, 007h, 080h, 0F8h, 007h, 080h, 01Ch, 000h, 007h
        DB      0C1h, 0F0h, 000h, 0F0h, 007h, 007h, 000h, 078h, 01Ch, 000h
        DB      078h, 00Fh, 000h, 0F8h, 00Fh, 000h, 078h, 000h, 00Eh, 003h
        DB      0E0h, 000h, 0F8h, 00Eh, 00Fh, 080h, 038h, 03Ch, 000h, 07Ch
        DB      01Fh, 080h, 07Ch, 01Fh, 001h, 0F8h, 000h, 007h, 007h, 0C0h
        DB      000h, 09Fh, 0F0h, 07Fh, 0C0h, 071h, 0FEh, 003h, 0FEh, 0FFh
        DB      0C7h, 0FFh, 0FFh, 0FFh, 0F0h, 000h, 003h, 0FEh, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 0C0h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 0C0h, 001h, 060h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 0E0h, 001h, 020h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 01Eh, 000h, 000h, 000h
        DB      000h, 000h, 001h, 0B0h, 001h, 010h, 000h, 000h, 080h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 031h, 080h, 000h, 000h, 000h
        DB      000h, 03Dh, 010h, 001h, 010h, 000h, 000h, 080h, 000h, 0C0h
        DB      000h, 000h, 000h, 000h, 030h, 080h, 000h, 000h, 000h, 000h
        DB      00Dh, 010h, 03Dh, 030h, 000h, 000h, 080h, 000h, 030h, 000h
        DB      00Fh, 091h, 000h, 01Eh, 000h, 00Eh, 000h, 000h, 000h, 009h
        DB      010h, 005h, 020h, 000h, 000h, 0C0h, 000h, 010h, 000h, 004h
        DB      04Ah, 000h, 003h, 0DFh, 00Bh, 079h, 0C3h, 000h, 009h, 030h
        DB      005h, 060h, 000h, 000h, 0C0h, 000h, 008h, 000h, 007h, 084h
        DB      000h, 000h, 051h, 049h, 04Dh, 072h, 080h, 03Fh, 0E0h, 005h
        DB      0C0h, 000h, 000h, 0C0h, 000h, 008h, 000h, 004h, 044h, 000h
        DB      0C0h, 053h, 07Fh, 04Dh, 032h, 080h, 0E5h, 000h, 03Fh, 002h
        DB      03Ch, 018h, 0C0h, 000h, 008h, 000h, 00Fh, 084h, 000h, 071h
        DB      0C6h, 04Ch, 049h, 022h, 080h, 0C5h, 000h, 065h, 013h, 023h
        DB      014h, 0C9h, 000h, 010h, 000h, 000h, 000h, 000h, 00Fh, 007h
        DB      0C6h, 0CDh, 033h, 000h, 07Dh, 008h, 064h, 091h, 029h, 015h
        DB      04Fh, 010h, 030h, 000h, 000h, 000h, 000h, 000h, 000h, 003h
        DB      087h, 01Eh, 0D8h, 001h, 0C0h, 03Ch, 091h, 02Dh, 009h, 059h
        DB      090h, 040h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 030h, 000h, 0C0h, 000h, 06Fh, 0A7h, 0FEh, 070h, 0F7h
        DB      080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 060h, 000h, 000h, 03Ch, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 001h, 0F0h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 001h, 010h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 001h, 090h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
        DB      000h, 000h, 000h, 000h, 070h, 000h, 000h


ENDS

        END
