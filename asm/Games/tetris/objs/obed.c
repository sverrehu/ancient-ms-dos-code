#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <io.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <mem.h>
#include <string.h>
#include <dir.h>
#include <stdarg.h>
#include <dos.h>

#include <ega10.h>
#include <basic.h>


#define byte unsigned char
#define TOTBYT 4 * 2 * 11

#define H  20   /* H›yde og bredde p† hver rute */
#define B  24
#define UX 20   /* Start p† gitteret */
#define UY 80
#define GC 1    /* Gridcolor */
#define PC 14   /* Positioncolor */

void showobj16x11(int x, int y, byte *p);

char filename[MAXPATH];
byte odata[TOTBYT];
int  changed = 0, usemouse = 0;
int  x, y, col;





void mouse(union REGS * r)
{
    int86(0x33, r, r);
}


void initmouse(void)
{
    union REGS r;

    r.x.ax = 0;   /* Reset mouse and get status */
    mouse(&r);
    if (r.x.ax == 0xFFFF) {
        usemouse = 1;
        r.x.ax = 7;  /* Set horizontal limits */
        r.x.cx = UX + B / 2;
        r.x.dx = UX + 16 * B;
        mouse(&r);
        r.x.ax = 8;  /* Set vertical limits */
        r.x.cx = UY + H / 2;
        r.x.dx = UY + 11 * H;
        mouse(&r);
    }
}


void resetmouse(void)
{
    union REGS r;

    if (!usemouse)
        return;
    r.x.ax = 0;   /* Reset mouse and get status */
    mouse(&r);
}


void setmouse(int x, int y)
{
    union REGS r;

    if (!usemouse)
        return;
    r.x.ax = 4;  /* Set mouse pointer position */
    r.x.cx = UX + B / 2 + x * B;
    r.x.dx = UY + H / 2 + y * H;
    mouse(&r);
}


void getmouse(int *x, int *y)
{
    union REGS r;

    if (!usemouse)
        return;
    r.x.ax = 3;  /* Get position and button status */
    mouse(&r);
    *x = (r.x.cx - UX - B / 2) / B;
    *y = (r.x.dx - UY - H / 2) / H;
}


int mouseleft(void)
{
    union REGS r;

    if (!usemouse)
        return(0);
    r.x.ax = 6;  /* Get button release info */
    r.x.bx = 0;  /* Left */
    mouse(&r);
    return(r.x.ax & 1);
}


int mousemiddle(void)
{
    union REGS r;

    if (!usemouse)
        return(0);
    r.x.ax = 6;  /* Get button release info */
    r.x.bx = 2;  /* Middle */
    mouse(&r);
    return(r.x.ax & 4);
}


int mouseright(void)
{
    union REGS r;

    if (!usemouse)
        return(0);
    r.x.ax = 6;  /* Get button release info */
    r.x.bx = 1;  /* Right */
    mouse(&r);
    return(r.x.ax & 2);
}


void gprintf(const char *format, ...)
{
    va_list argptr;

    bitmask(255);
    setcolor(15);
    /*
        P† EGA-skjermer m†tte ESETRESET settes til 0 under skriving.
        Hvis ikke ble tegnene helt fylte.
        Under skriving av tegn, sender BIOS plankoden. Det skal alts†
        ikke tas hensyn til fargekoden som ligger i SETRESET, derfor
        0-stilles EnableSETRESET.
    */
    outport(0x03CE, 1);
    va_start(argptr, format);
    vprintf(format, argptr);
    va_end(argptr);
}


int yesno(void)
{
    int c;

    do {
        c = getkey();
        if (c == 'y')
            c = 'Y';
        else if (c == 'n')
            c = 'N';
    } while (c != 'Y' && c != 'N' && c != 27);
    return(c);
}


void clear1(void)
{
    gotoxy(1, 1);
    gprintf("                                                      ");
}


void error(char *msg)
{
    gotoxy(1, 1);
    gprintf("Error: %s.  Press Esc", msg);
    while (getkey() != 27)
        ;
    clear1();
}


void newfilename(char *n)
{
    char drv[MAXDRIVE], dir[MAXDIR], nme[MAXFILE];

    strupr(n);
    if (strlen(n)) {
        fnsplit(n, drv, dir, nme, NULL);
        fnmerge(filename, drv, dir, nme, ".OB");
        gotoxy(1, 25);
        gprintf("File: %-40.40s", filename);
    }
}


void inputfilename(void)
{
    char n[MAXPATH];

    gotoxy(1, 1);
    gprintf("Give filename (without ext): ");
    gets(n);
    newfilename(n);
    clear1();
}


void cleardata(void)
{
    memset(&odata, 0, TOTBYT);
}


void resetvalues(void)
{
    col = 15;
    x = 4;
    y = 3;
    setmouse(x, y);
}


void readfile(void)
{
    int fh;

    cleardata();
    if ((fh = open(filename, O_RDONLY | O_BINARY)) != -1) {
        if (read(fh, &odata, TOTBYT) != TOTBYT)
            error("Read error");
        close(fh);
        changed = 0;
    } else
        error("Could not open file for reading");
}


void writefile(void)
{
    int fh, q, w;
    FILE *f;
    char incfile[MAXPATH], incdrv[MAXDRIVE], incdir[MAXDIR], incnme[MAXFILE];

    if (!strlen(filename))
        inputfilename();
    if ((fh = open(filename, O_WRONLY | O_BINARY | O_CREAT | O_TRUNC,
                             S_IREAD | S_IWRITE)) != -1) {

        if (write(fh, &odata, TOTBYT) != TOTBYT)
            error("Write error");
        close(fh);
        changed = 0;
    } else
        error("Could not open file for writing");

    fnsplit(filename, incdrv, incdir, incnme, NULL);
    fnmerge(incfile, incdrv, incdir, incnme, ".INC");
    if ((f = fopen(incfile, "wt")) != NULL) {
        strlwr(incnme);
        fprintf(f, "PUBLIC  %s\n", incnme);
        fprintf(f, "%-*.*sDB  ", 12, 12, incnme);
        for (q = 0; q < 22; q++) {
            fprintf(f, "%05Xh", odata[q]);
            if (q == 5 || q == 11 || q == 17)
                fprintf(f, "\n            DB  ");
            else if (q == 21)
                fprintf(f, "\n");
            else
                fprintf(f, ", ");
        }
        for (w = 1; w < 4; w++) {
            fprintf(f, "            DB  ");
            for (q = 0; q < 22; q++) {
                fprintf(f, "%05Xh", odata[q + 22 * w]);
                if (q == 5 || q == 11 || q == 17)
                    fprintf(f, "\n            DB  ");
                else if (q == 21)
                    fprintf(f, "\n");
                else
                    fprintf(f, ", ");
            }
        }
        fprintf(f, "\n");
        fclose(f);
        changed = 0;
    } else
        error("Could not open file for writing");
}


int chksaved(void)
{
    int ret = 0;

    if (changed) {
        gotoxy(1, 1);
        gprintf("Object is changed. Save? (Y/N) ");
        if ((ret = yesno()) == 'Y')
            writefile();
        clear1();
    }
    return(ret);
}


void box(int x1, int y1, int x2, int y2)
{
    line(x1, y1, x2, y1);
    line(x2, y1, x2, y2);
    line(x2, y2, x1, y2);
    line(x1, y2, x1, y1);
}


void fbox(int x1, int y1, int x2, int y2)
{
    int y;

    for (y = y1; y <= y2; y++)
        line(x1, y, x2, y);
}


void showpoint(int x, int y)
{
    int offs, c, a;

    offs = (y << 1) + (x > 7 ? 1 : 0);
    a = 128 >> (x & 7);
    c = 0;
    if (odata[offs + 0 * 22] & a)  c |= 1;
    if (odata[offs + 1 * 22] & a)  c |= 2;
    if (odata[offs + 2 * 22] & a)  c |= 4;
    if (odata[offs + 3 * 22] & a)  c |= 8;
    setcolor(c);
    fbox(UX + 1 + B * x, UY + 1 + H * y,
         UX - 1 + B * (x + 1), UY - 1 + H * (y + 1));
}


void setpoint(int x, int y, int col)
{
    int offs, a, o;

    offs = (y << 1) + (x > 7 ? 1 : 0);
    o = 128 >> (x & 7);
    a = 255 - o;
    if (col & 1) odata[offs + 0 * 22] |= o;
    else         odata[offs + 0 * 22] &= a;
    if (col & 2) odata[offs + 1 * 22] |= o;
    else         odata[offs + 1 * 22] &= a;
    if (col & 4) odata[offs + 2 * 22] |= o;
    else         odata[offs + 2 * 22] &= a;
    if (col & 8) odata[offs + 3 * 22] |= o;
    else         odata[offs + 3 * 22] &= a;
    showpoint(x, y);
}


void fillgrid(void)
{
    int x, y;

    for (y = 0; y < 11; y++)
        for (x = 0; x < 16; x++)
            showpoint(x, y);
}


void showpos(int x, int y)
{
    setcolor(PC);
    box(UX + B * x, UY + H * y, UX + B * (x + 1), UY + H * (y + 1));
}


void dontshowpos(int x, int y)
{
    setcolor(GC);
    box(UX + B * x, UY + H * y, UX + B * (x + 1), UY + H * (y + 1));
}


void showcolor(void)
{
    int q;
 #define CX 580
 #define CY 200
 #define CH 6
 #define CB 20

    for (q = 0; q < 16; q++) {
        setcolor(q);
        fbox(CX + CB + 1, CY + CH * q, CX + 2 * CB, CY + CH * (q + 1));
    }
    setcolor(0);
    fbox(CX, CY, CX + CB, CY + CH * 16);
    setcolor(15);
    q = CY + col * CH + CH / 2;
    line(CX, q, CX + CB - 1, q);
    line(CX + CB - 3, q - 1, CX + CB - 1, q);
    line(CX + CB - 3, q + 1, CX + CB - 1, q);
}


void showfig(void)
{
    setcolor(0);
    fbox(500 - 4, 200 - 3, 500 + 4, 200 + 3);
    bitmask(255);
    showobj16x11(500 / 16, 200 / 11, odata);
}


void showscreen(void)
{
    int xx, yy;

    cleardevice();
    gotoxy(1, 3);
    gprintf(" arrows : Move cursor     F2  : Save file      C : Clear grid\n");
    gprintf(" space  : Set dot         F3  : Load file      N : New filename\n");
    gprintf(" Alt/X  : Exit            +/- : Change color\n");
    gotoxy(1, 25);
    gprintf("File: %-40.40s", filename);
    setcolor(GC);
    for (xx = 0; xx < 17; xx++)
        line(UX + B * xx, UY, UX + B * xx, UY + H * 11);
    for (yy = 0; yy < 12; yy++)
        line(UX, UY + H * yy, UX + 16 * B, UY + H * yy);
    fillgrid();
    showpos(x, y);
    showcolor();
    showfig();
}


void edit(void)
{
    int oldx, oldy, c;

    resetvalues();
    showscreen();
    while (!kbhit() || (c = getkey()) != -45) {
        oldx = x; oldy = y;
        switch (c) {
            case -60 : writefile();     break;
            case -61 : if (chksaved() != 27) {
                           inputfilename();
                           readfile();
                           resetvalues();
                           showscreen();
                       }
                       break;
            case -72 : if (y > 0)  --y; setmouse(x, y); break;
            case -80 : if (y < 10) ++y; setmouse(x, y); break;
            case -75 : if (x > 0)  --x; setmouse(x, y); break;
            case -77 : if (x < 15) ++x; setmouse(x, y); break;
            case 'c' :
            case 'C' : gotoxy(1, 1);
                       gprintf("Clear grid? (Y/N)");
                       if (yesno() == 'Y') {
                           cleardata();
                           resetvalues();
                           showscreen();
                           changed = 1;
                       }
                       clear1();
                       break;
            case 'n' :
            case 'N' : inputfilename(); break;
        }
        getmouse(&x, &y);
        if (c == ' ' || mouseleft()) {
            setpoint(x, y, col);
            changed = 1;
            showfig();
        }
        if (c == '+' || mouseright()) {
            if (col < 15)
                ++col;
            showcolor();
            if (c != '+')
                delay(150);
        }
        if (c == '-' || mousemiddle()) {
            if (col > 0)
                --col;
            showcolor();
            if (c != '-')
                delay(150);
        }
        c = 0;
        if (x != oldx || y != oldy) {
            dontshowpos(oldx, oldy);
            showpos(x, y);
        }
    }
    chksaved();
}



int main(int argc, char *argv[])
{
    init_ega10_graph();
    if (argc > 1)
        newfilename(argv[1]);
    if (strlen(filename))
        readfile();
    initmouse();
    edit();
    resetmouse();
    closegraph();
    return 0;
}
