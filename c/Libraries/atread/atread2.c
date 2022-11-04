#include <ctype.h>
#include <conio.h>

#include <basic.h>

#include "atread.h"



#define ON 1
#define OFF 0




int choice(int key, int func)
{
    int c = '\0', stop = 0, cur;

    cur = cursor();
    curson();
    while (!stop) {
        if ((c = getkey()) > 0)
            c = toupper(c);
        if (c == 'J' || c == 'N')
            stop = 1;
        else if (c == 27 || (-c >= 59 && -c <= 58 + func))
            stop = 1;
        else if (key && (c < 0 || c == 13))
            stop = 1;
    }
    if (c == 'J' || c == 'N')
        cprintf("%s", (c == 'J') ? "Ja " : "Nei");
    if (!cur)
        cursoff();
    return(c);
}
