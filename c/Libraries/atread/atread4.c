#include <conio.h>

#include <basic.h>

#include "atread.h"

#define ON 1
#define OFF 0



int invattr(void)
{
    int tinv, a, ta;

    ta = gettextattr();
    tinv = getinv();
    setinv(1);
    a = gettextattr();
    setinv(tinv);
    textattr(ta);
    return(a);
}

int markattr(void)
{
    if (gettextbackground())
        return(7);
    else
        return(112);
}
