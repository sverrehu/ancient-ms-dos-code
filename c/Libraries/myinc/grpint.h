#ifndef GRPINT_H
#define GRPINT_H



#include </C/GRPINT/KEYBOARD.H>
#include </C/GRPINT/GRPSTATE.H>
#include </C/GRPINT/MOUSE.H>
#include </C/GRPINT/BOX.H>
#include </C/GRPINT/WIN.H>
#include </C/GRPINT/BUTTON.H>



void LiftUp(int x1, int y1, int x2, int y2,
            int dwidth, int dark, int lwidth, int light);
void PushDown(int x1, int y1, int x2, int y2,
              int dwidth, int dark, int lwidth, int light);

void SetMessageColors(int back, int text, int bord1, int bord2, int title);
void SetErrorColors(int back, int text, int bord1, int bord2, int title);
void SetYesNoColors(int back, int text, int bord1, int bord2, int title);

void Message(char *title, char *format, ...);
void Error(char *title, char *format, ...);
int  YesNo(char *title, char *format, ...);



#endif
