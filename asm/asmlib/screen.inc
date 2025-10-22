        EXTRN  initscreen: PROC, endscreen : PROC
        EXTRN  screenrows: PROC, screencols: PROC
        EXTRN  window    : PROC, clrscr    : PROC
        EXTRN  gotoxy    : PROC, wherex    : PROC, wherey        : PROC
        EXTRN  outchar   : PROC, outtext   : PROC, outword       : PROC
        EXTRN  textattr  : PROC, textcolor : PROC, textbackground: PROC
        EXTRN  textmode  : PROC
        EXTRN  insline   : PROC, delline   : PROC, clreol        : PROC
        EXTRN  gettext   : PROC, puttext   : PROC
