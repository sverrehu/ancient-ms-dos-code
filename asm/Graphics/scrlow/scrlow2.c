#include <stdarg.h>

#include "scrlow.h"


int cdecl cprintf(const char *format, ...)
{
    va_list argptr;
    char tempstr[400];

    va_start(argptr, format);
    vsprintf(tempstr, format, argptr);
    cputs(tempstr);
    va_end(argptr);
    return(strlen(tempstr));
}

