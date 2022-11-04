@ECHO OFF
IF "%1" == "" GOTO INFO

FILETIME ED.COM /D /T:%1
FILETIME ED.DOC /D /T:%1
FILETIME EDSETUP.COM /D /T:%1
FILETIME README.TXT /D /T:%1
FILETIME \MYTEX\ED.* /D /T:%1
rem FILETIME BETA.TXT /D /T:%1
GOTO END

:INFO

ECHO.
ECHO Setter tiden p† "SHH ED" og dens filer til angitt tall.
ECHO.
ECHO Syntaks: VERSJON tid
ECHO.

:END
