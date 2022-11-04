#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <conio.h>

#include "basic.h"

#define byte unsigned char
#define ON 1
#define OFF 0



void sent(char *format, ...)
{
    va_list argptr;
    char tempstr[400];
    struct text_info ti;

    va_start(argptr, format);
    vsprintf(tempstr, format, argptr);
    gettextinfo(&ti);
    gotoxy(((ti.winright - ti.winleft + 1) / 2) - (strlen(tempstr) / 2) + 1, wherey());
    cprintf(tempstr);
    va_end(argptr);
}

void sentln(char *format, ...)
{
    va_list argptr;
    char tempstr[400];
    struct text_info ti;

    va_start(argptr, format);
    vsprintf(tempstr, format, argptr);
    gettextinfo(&ti);
    gotoxy(((ti.winright - ti.winleft + 1) / 2) - (strlen(tempstr) / 2) + 1, wherey());
    cprintf("%s\r\n", tempstr);
    va_end(argptr);
}
