#ifndef MPU401_H
#define MPU401_H



void cdecl SetDataPort(int port);
void cdecl SetCommPort(int port);
void cdecl SetStatPort(int port);
int  cdecl SendCommand(int cmd);
int  cdecl SendData(int data);
int  cdecl ReadData(void);
void cdecl SetErrorHandler(int (f)(void));

void cdecl SetInterruptHandler(void (f)(void));
void cdecl ResetInterruptHandler(void);



#endif
