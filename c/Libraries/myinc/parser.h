#define MAXVAR  26
#define MAXFUNC 26

#define VARTYPE double
#define STACKSIZE 100



enum funcs { ABS, ACOS, ASIN, ATAN, COS, COSH, EXP,
             LN, LOG, SIN, SINH, SQRT, TAN, TANH, NEG };

enum types { CONSTANT, VARIABLE, STDFUNC, USRFUNC, OPERATOR };

enum parserror { OK, SYMB_TOO_LONG, UNKNOWN_SYMB, UNMATCHED_PARA,
                 UNKNOWN_CHAR, FUNC_NEED_PARA, OUT_MEM, EXPR_SYNTAX };




/* Rutiner for lavt niv† (brukes internt) */

void     push(VARTYPE t);
VARTYPE  pop(void);
void     set_func_var(int no, int var);
int      get_func_var(int no);
void     add_symb_to_func(int nr, char *s);
int      translate(char *src, char *dst);


/* Rutiner for bruk i andre programmer */

void     set_var(int nr, VARTYPE t);
VARTYPE  get_var(int nr);
void     clear_func(int nr);
VARTYPE  calc_func(int nr);
int      set_func(int nr, char *expression, int var);
