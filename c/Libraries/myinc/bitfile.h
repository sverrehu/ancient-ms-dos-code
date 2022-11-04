int openrbitfile(char *filename);
int closerbitfile(void);
int setposrbitfile(long pos);
int readbitfile(unsigned *dest, int numbits);

int openwbitfile(char *filename);
int closewbitfile(void);
int setposwbitfile(long pos);
int writebitfile(unsigned dest, int numbits);
