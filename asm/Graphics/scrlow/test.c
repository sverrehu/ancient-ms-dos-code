#include <conio.h>
#include <stdio.h>
#include <time.h>

#include <scrlow.h>

int q;
time_t ss, se;


void testscreen(void)
{
    clrscr();
    ss = clock();
    for (q = 0; q < 500; q++)
        cputs("Hallo, denne linjen er vel lang nok til † v‘re en god test!?  ");
    se = clock();
}



main()
{
    struct text_info ti;

    textattr(112);
    clrscr();
    testscreen();
    textattr(7);
    clrscr();
    textcolor(1);
    textbackground(8);
    cprintf("cols: %d,    rows: %d\r\n", screencols(), screenrows());
    textattr(7);
    cputs("Hallo");
    cprintf("  x=%d, y=%d\r\n", wherex(), wherey());
    gettextinfo(&ti);
    cprintf("attr=%d\r\n", ti.attribute);
    cprintf("normattr=%d\r\n", ti.normattr);
    cprintf("\r\nscreen: %ld ticks\r\n", se - ss);
}
