#ifndef SHHWIN_H
#define SHHWIN_H

#define NUM_OF_WIND 10


int  makewindow(int x1, int y1, int x2, int y2, int txtattr, int frmattr,
                char * head, int frm);
void removewindow(void);
void set_exploding_windows(int status);
void set_window_shadow(int status);

#endif
