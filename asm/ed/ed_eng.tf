##pl60##tm4##lm10##rm2












##ceS H H   E D  -  T e x t e d i t o r





##ceWritten using Turbo Assembler by

##ceSverre H. Huseby
##ceBjoelsengt. 17
##ceN-0468 Oslo
##ceNorway

##cePhone: +47 22 23 05 39

##ceInternet: sverrehu@ifi.uio.no
















[ ##lm12Note: This document is a (much too) quick translation from the
original Norwegian text. It probably contains lots of errors and bad English
grammar, but I hope you'll understand enough to get started.##lm10 ]


##ttSHH ED - Users manual                                      PAGE ##pn##nl##nl##nl
##np
##ceINTRODUCTION
##ce============



"SHH ED" (hereafter called ED) is a simple text editor inspired by the editors
in older versions of Borland's compilers. These are based on good old WordStar.

The problem with the newer Borland editors is that they are `stuck' in an
enormous integrated environment. If you wish to use Borland's integrated
editors for other things than writing programs, there's no choice to
leave everything except the editor out. This results in several seconds for
loading.

This is especially annoying when programming using the command line compiler.
Start the editor, edit the text, quit the editor, compile the program,
restart the editor etc. This just takes too long.

With that as a background, i tried to make a _small_ text editor not too
different from (old versions of) Borland's intergrated editors.




##ceRULES
##ce=====



ED is `FreeWare'. This means that you can copy and use the program as much
as you wish, as long as you stick to the following `rules':

##lm13
* ##lm15You are not allowed to sell the program. You might sell diskettes
containing the program and charge a small fee for it.

##lm13
* ##lm15When copying the program, all files must be included. No file must
be changed in any way.

##lm13
* ##lm15I shall not be held liable for any loss or damage due to using
this program. There is no warranty at all.

##lm10
I would be happy if you report any bugs you find. I consider ED a finished
project (not that I mean the program is finished, but I have no intention
extending it), so I will not make any changes or extensions to how ED works.
I will of course try to fix bugs, though.

In addition, I would like you to tell me if you use this program. That's
not too much to ask, is it? :-)
##np
##ceSTARTING ED
##ce===========



ED is started using the command ED. Add a filename if you wish to go directly
into a file.

    ED filename

If no filename is given, ED will check if a pick-file (see USING PICKLISTS
AND PICKFILES below) exists in the current directory. If there is one,
the first file in this list is read in. If no pick-file exists, you are
prompted for a filename.

Filenames can be names of existing files, names of non-existing files,
or filespecs containing wildcards (eg. *.ASM).

If an existing file is specified, it's read into the editor. If the file does
not exist, the editor is emptied, and the current name is set to the one
given. A filespec with wildcards will bring up a window with a list of
matching files. Use the cursor keys to choose.


To abort an operation, it is in most cases possible to press Esc to get
back to the text.





##ceEXITING ED
##ce==========



When finished editing, exit the program using Alt-X (specified at the
bottom of the screen).

If the current file is not saved, you are asked if you want to save it
before the program returns to DOS.

##np
##ceDEFAULT FILENAME EXTENSIONS
##ce===========================



When programming, many files have the same extensions. ED tries to save
some work by remembering the extension of the last file read in.

When a filename is later to be given, there's no need to include the
extension if it matches that of the current file.

To edit a file with no extension at all, give the filename followed by
a dot (.). Then ED won't add no extension.





##ceUSING PICKLISTS AND PICKFILES
##ce=============================



When new files are read into the editor, previous filenames are stored
in a so called `pick-list'. In addition to the filenames, this list
contains information on where the cursor was in the text, where the block
was, and the locations of any position markers.

To get back to one of the previous files, press F4. This opens a window
containing a list of up to the 13 most recent filenames. Position the
cursor on the file you want and press return. This brings back the old
file, with the cursor on the position it was when this file was left.

This list might be saved in a pick-file by pressing Alt-F4. This should
only be done once, since ED will automatically update this file when one
first exists.

The pick-file is created in the current directory, and it's name is ED.PCK.
This can be removed at any time. (Note: The pick-file should be deleted
if the files mentioned in it are moved to another directory).

When ED is started, it will check if there is a pick-file in the current
directory. If there is, it is opened, and if no filename is given on
the command line, the most recently edited file is read in.

##np
##ceTHE STATUS LINE
##ce===============



The uppermost line on the screen contains info on how ED is working at
the moment.

##lm13
Current line and column.

Whether Insert, AutoIndent and Parenthesis Pairing are on or off.

If the file is changed since it was last saved. This is marked by an
asterisk (*) to the left of the filename.

The current filename. This is a short form, containing disk and name only.
Any directories are not displayed.

##lm10
The bottom line lists the most important keys. All other keys are listed
in the help-screens.





##ceUSING A MOUSE
##ce=============



A Microsoft-compatible mouse can be used to move the cursor. Just point at
the new location, and press the left button. It is not possible to move
beyond the last line of text.

The mouse can be used for fast scrolling too. Put the mouse cursor at the
upper or lower status lines, and press the left button to scroll up (closer
to the start of the text), or the right button to scroll down.

Note: The mouse might not work correctly in non-standard screen modes
(other that 80 columns).

(See CONFIGURING ED USING EDSETUP.COM if the mouse doesn't work correctly.)

##np
##cePECULIARITIES
##ce=============



ED'S TREATMENT OF TAB

To ED, the Tab ASCII-code is just another character. All tabs in a file
are displayed as small circles, since this is what ASCII 9 looks like
in the IBM character set.

Pressing Tab when editing, causes ED to indent the current line, that is:
the cursor is moved to the first column where there is a non-blank character
in the preceeding line.





##ceED IN NUMBERS
##ce=============



Max linelength:                255 ##nl
Max number of lines:         10000 ##nl
Max length of search string:    32 ##nl
Max length of filenames:        80 ##nl

The maximum filesize is given by the amount of free conventional memory.
The entire file is always kept in RAM.

##np
##ceSHORT COMMANDREFERENCE
##ce======================



Press F1 to get this list when using ED. Use PgDn and PgUp to move
between the pages.



##lm15
BASIC CURSOR MOVEMENT

##lm20
Character Left             Ctrl-S or Left Arrow        ##nl
Character Right            Ctrl-D or Right Arrow       ##nl
Word Left                  Ctrl-A or Ctrl-Left Arrow   ##nl
Word Right                 Ctrl-F or Ctrl-Right Arrow  ##nl
Line Up                    Ctrl-E or Up Arrow          ##nl
Line Down                  Ctrl-X or Down Arrow        ##nl
Scroll One Line Up         Ctrl-W                      ##nl
Scroll One Line Down       Ctrl-Z                      ##nl
Page Up                    Ctrl-R or PgUp              ##nl
Page Down                  Ctrl-C or PgDn              ##nl
##lm15



OTHER CURSOR MOVEMENT

##lm20
Beginning of Line          Home                     ##nl
End of Line                End                      ##nl
Top of Screen              Ctrl-Home                ##nl
Bottom of Screen           Ctrl-End                 ##nl
Beginning of File          Ctrl-PgUp                ##nl
End of File                Ctrl-PgDn                ##nl
Beginning of Block         Ctrl-Q B                 ##nl
End of Block               Ctrl-Q K                 ##nl
Go to Line                 Ctrl-Q G                 ##nl
##lm15



INSERT AND DELETE

##lm20
Insert Off/On              Ctrl-V or Ins            ##nl
Insert Line                Ctrl-N                   ##nl
Delete Line                Ctrl-Y                   ##nl
Delete to End of Line      Ctrl-Q Y                 ##nl
Delete Character Left      Ctrl-H or BackSpace      ##nl
Delete Character           Ctrl-G or Del            ##nl
Delete Word Right          Ctrl-T                   ##nl
##lm15

##np
BLOCK COMMANDS

##lm20
Mark Start of Block        Ctrl-K B                 ##nl
Mark End of Block          Ctrl-K K                 ##nl
Copy Block                 Ctrl-K C                 ##nl
Move Block                 Ctrl-K V                 ##nl
Delete Block               Ctrl-K Y                 ##nl
Read Block from File       Ctrl-K R                 ##nl
Write Block to File        Ctrl-K W                 ##nl
Hide/Show Block            Ctrl-K H                 ##nl
Indent Block               Ctrl-K I                 ##nl
Unindent Block             Ctrl-K U                 ##nl
##lm15



MISCELLANEOUS

##lm20
Indent                     Ctrl-I or Tab            ##nl
Auto Indent Off/On         Ctrl-O I                 ##nl
Parenthesis Pairing Off/On Ctrl-O P                 ##nl
Set Place Marker           Ctrl-K 1,2               ##nl
Find Place Marker          Ctrl-Q 1,2               ##nl
Control Character Prefix   Ctrl-P c                 ##nl
Search                     Ctrl-Q F                 ##nl
Search and Replace         Ctrl-Q A                 ##nl
Repeat Last Search/Replace Ctrl-L                   ##nl
Show User Screen           F5     or Alt-F5         ##nl
##lm15



FILE HANDLING

##lm20
Save File                  F2                       ##nl
Load File                  F3                       ##nl
Pick Previous File         F4     or Alt-F3         ##nl
Create Pick-file           Alt-F4                   ##nl
##lm10


##np
##ceEXPLANATIONS TO SOME OF THE COMMANDS
##ce====================================



INSERT AND DELETE

"Delete Word Right" first removes non-delimiters, then any space-characters
up to end of line or a non-space. The following are delimiters:
space < > , ; . : ( ) [ ] { } ^ ' = * + - / \ $ #


BLOCK COMMANDS

"Copy Block" / "Move Block" will copy/move the highlighted block to the
current cursor location. Note that a block can not be copied into itself.
The cursor must be _outside_ the block.

"Indent Block" will add a space character to the start of all lines in
the block, thus moving it one column to the right.

"Unindent Block" possibly removes a space character from the start of all
lines in the block, thus moving it one column to the left.


MISCELLANEOUS

"Parenthesis Pairing Off/On" is a bit special. ED will automatically enter
the right version of the parenthesis you enter, and locate the cursor in
between. This might be confusing at first, but it's quite addictive! The
following are considered parenthesis: (), [], {} and "". Pairmaking only
works when Insert is On.

"Control Character Prefix" makes it possible to enter characters with
ASCII-code less than 32. To enter an ASCII 12 printer eject code, press
Ctrl-P followed by L, the 12th letter in the alphabet.

Options to "Search" or "Search and Replace" can be zero or more of the
following:

##lm13
G ##lm15Search Globally, that is: from the start of the document until the
last occurence.

##lm13
N ##lm15Replace with No questions.

##lm10
"Show User Screen" displays the screen that was active before ED was started.
Use this for instance to look at compiler error messages. Press any key to
return to the editor.
##np
##ceCONFIGURING ED USING EDSETUP.COM
##ce================================



It's possible to make permanent changes to ED's setup by using the
program EDSETUP.COM. This is useful if you for instance don't like
the parenthesis pairing.

The first choice in EDSETUP is "Reset mouse at start". If the mouse don't
work with ED (and you want it to work), try enabling this one. This might
increase startup time with a couple of seconds, since some mouse drivers
take some time resetting the mouse.

For EDSETUP to work, ED.COM must be in the current directory, and the file
must not be write protected. All changes are written directly into ED.COM,
to avoid having to read a configuration file at startup.





##ceSUMMARY
##ce=======

##ceFIRST, WHAT'S GOOD.

##ceED is quite small. This results in fast loading.
##ceED is _free_.



##ceTHEN, WHAT'S BAD.

##ceThere's no _real_ mouse support.
##ceAnd, as mentioned, there's no Tab support.
##ceAnd the options to search/replace are limited.
##ceAnd ...

##np