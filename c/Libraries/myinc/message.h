#ifndef MESSAGE_H
#define MESSAGE_H

#ifdef __cplusplus
extern "C" {
#endif

#include <setjmp.h>

void SetProgName(const char *s);
char *GetProgName(void);

void Error(const char *format, ...);
void Fatal(const char *format, ...);
void Serious(const char *format, ...);
void Perror(const char *format, ...);
void FatalPerror(const char *format, ...);

extern int IsVerbose;
void SetVerbose(int onoff);
void Verbose(const char *format, ...);

jmp_buf *NextSEHandler(void);   /* Don't call this one directly! */
#define SeriousErrorOccurs() (setjmp(*NextSEHandler()))
void    ForgetSeriousError(void);

#ifdef __cplusplus
}
#endif

#endif
