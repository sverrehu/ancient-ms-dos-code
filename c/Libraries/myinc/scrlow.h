void        cdecl   init_scrlow(void);
int         cdecl   screenrows(void);
int         cdecl   screencols(void);
void far *  cdecl   screen_addr(void);
void        cdecl   wrtscreen(int c, int a, int x, int y);
int         cdecl   rdscreen(int x, int y);
