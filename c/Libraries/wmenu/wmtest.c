#include <conio.h>
#include <wmenu.h>

void settoppmenyer()
{
    addmitem(0, "File");
    addmitem(0, "Copy Files  ");
    addmitem(0, "Type Files  ");
    addmitem(0, "Delete Files");
    addmitem(0, "Tra-la-la   ");
    addmitem(1, "Games");
    addmitem(1, "Snake    ");
    addmitem(1, "Exsplorer");
    addmitem(1, "Herbie   ");
    addmitem(1, "PacMan   ");
    addmitem(2, "Ensom");
    addmitem(3, "File 2");
    addmitem(3, "Copy Files  ");
    addmitem(3, "Type Files  ");
    addmitem(3, "Delete Files");
    addmitem(4, "Games 2");
    addmitem(4, "Snake    ");
    addmitem(4, "Exsplorer");
    addmitem(4, "Herbie   ");
    addmitem(4, "PacMan   ");
    addmitem(5, "Ensom 2");
    addmitem(6, "Games 3");
    addmitem(6, "Snake p† nummer 3    ");
    addmitem(6, "Exsplorer p† nummer 3");
    addmitem(6, "Herbie p† nummer 3   ");
    addmitem(6, "PacMan p† nummer 3   ");
    setmenus(7);
}



main()
{
    int m, i;

    clrscr();
    newmenu();
    settoppmenyer();
    m = 0; i = 1;
    menuchoice(&m, &i);
    gotoxy(1, 10);
    cprintf("Valg : meny %d, item %d\r\n", m, i);
}
