/*
        ega10.h

        (C) Sverre H. Huseby
*/

#if __STDC__
#define _Cdecl
#else
#define _Cdecl  cdecl
#endif

#if     !defined(__GRAPHX_DEF_)
#define __GRAPHX_DEF_


/* Colors for setpalette and setallpalette */

#if     !defined(__COLORS)
#define __COLORS

enum COLORS {
    BLACK,                  /* dark colors */
    BLUE,
    GREEN,
    CYAN,
    RED,
    MAGENTA,
    BROWN,
    LIGHTGRAY,
    DARKGRAY,               /* light colors */
    LIGHTBLUE,
    LIGHTGREEN,
    LIGHTCYAN,
    LIGHTRED,
    LIGHTMAGENTA,
    YELLOW,
    WHITE
};
#endif


enum EGA_COLORS {
    EGA_BLACK            =  0,      /* dark colors */
    EGA_BLUE             =  1,
    EGA_GREEN            =  2,
    EGA_CYAN             =  3,
    EGA_RED              =  4,
    EGA_MAGENTA          =  5,
    EGA_BROWN            =  20,
    EGA_LIGHTGRAY        =  7,
    EGA_DARKGRAY         =  56,     /* light colors */
    EGA_LIGHTBLUE        =  57,
    EGA_LIGHTGREEN       =  58,
    EGA_LIGHTCYAN        =  59,
    EGA_LIGHTRED         =  60,
    EGA_LIGHTMAGENTA     =  61,
    EGA_YELLOW           =  62,
    EGA_WHITE            =  63
};

enum WRITE_MODES {
    NORMAL_PLOT,
    AND_PLOT,
    OR_PLOT,
    XOR_PLOT,
};

#define MAXCOLORS 15

struct palettetype {
        unsigned char size;
        signed char colors[MAXCOLORS+1];
};


void      _Cdecl cleardevice(void);
void      _Cdecl closegraph(void);
int       _Cdecl detect_ega10_graph(void);
int       _Cdecl getmaxx(void);
int       _Cdecl getmaxy(void);
int       _Cdecl init_ega10_graph(void);
void      _Cdecl line(int x1, int y1, int x2, int y2);
void      _Cdecl rline(int x1, int y1, int x2, int y2);
void      _Cdecl plot(int x, int y);
void      _Cdecl rplot(int x, int y);
void      _Cdecl putpixel(int x, int y, int color);
unsigned  _Cdecl getpixel(int x, int y);
void      _Cdecl setactivepage(int page);
void      _Cdecl setcolor(int color);
void      _Cdecl setviewport(int left, int top, int right, int bottom);
void      _Cdecl setvisualpage(int page);
void      _Cdecl bitmask(int mask);
void      _Cdecl mapmask(int mask);
void      _Cdecl setwritemode(int mode);
void      _Cdecl getpalette(struct palettetype *palette);
void      _Cdecl setpalette(int colornum, int color);
void      _Cdecl setallpalette(struct palettetype *palette);
int       _Cdecl getmaxpage(void);
void      _Cdecl showobject(int x, int y, unsigned char *p);


  /* The following functions are not yet available */
  /* (Coming soon to a cinema near you!)           */

void      _Cdecl clearviewport(void);
int       _Cdecl getbkcolor(void);
int       _Cdecl getcolor(void);
struct palettetype *_Cdecl getdefaultpalette( void );
void      _Cdecl rectangle(int left, int top, int right, int bottom);
void      _Cdecl restorecrtmode(void);
void      _Cdecl setbkcolor(int color);
void      _Cdecl setgraphmode(void);


#endif
