/*
    BIOS Drive Parameter Block

    Finnes med udokumentert funksjon 32h i INT 21h.
*/

typedef unsigned char byte;   /* 1 byte */
typedef unsigned word;        /* 2 bytes */
typedef unsigned long dword;  /* 4 bytes */


typedef struct {
    byte driveno;
    byte unitno;
    word bytesprsect;
    byte highsectinclust;
    byte log2clustsiz;
    word reservedsect;
    byte numFATs;
    word rootentries;
    word firstdatasect;
    word highclust;
    union {
        struct {
            byte  sectprFAT;
            word  firstrootsect;
            dword deviceaddr;
            byte  mediadesc;
            byte  rebuild;
            dword nextdevice;
            word  currdirclust;
            byte  currpath[64];
        } dos2;
        struct {
            byte  sectprFAT;
            word  firstrootsect;
            dword deviceaddr;
            byte  mediadesc;
            byte  rebuild;
            dword nextdevice;
            word  currdirclust;
            word  freeclustsrch;
            word  numfreeclust;
        } dos3;
        struct {
            word  sectprFAT;
            word  firstrootsect;
            dword deviceaddr;
            byte  mediadesc;
            byte  rebuild;
            dword nextdevice;
            word  currdirclust;
            word  freeclustsrch;
            word  numfreeclust;
        } dos4;
    } ver;
} BIOSdpm;


/*
    diskinfo

    Data som returneres av getdiskinfo.
*/
typedef struct {
    int  driveno;       /* Drive number */
    int  bytesprsect;   /* Bytes pr sector */
    int  sectprclust;   /* Sectors pr cluster */
    int  reservedsect;  /* Number of reserved sectors */
    int  numFATs;       /* Number of FATs */
    int  rootentries;   /* Number of root-entries */
    int  firstdatasect; /* First data sector on medium */
    int  numclust;      /* Number of clusters */
    int  FAT16bits;     /* 0 = FAT 12 bits, 1 = FAT 16 bits */
    int  sectprFAT;     /* Sectors pr FAT */
    int  firstrootsect; /* First sector of root dir */
} diskinfo;



int getdiskinfo(int diskno, diskinfo *dd);
