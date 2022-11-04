int   setup_lzw(int maxbits, long strtabsize);
void  free_lzw(void);

int   setup_lzw_asm(int maxbits, long strtabsize);
void  free_lzw_asm(void);

int   pack_lzw(void);
int   unpack_lzw(void);
