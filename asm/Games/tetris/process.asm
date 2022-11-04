
;==========================================================================
;
;   FILE:           PROCESS.ASM
;
;   MODULE OF:
;
;   DESCRIPTION:
;
;
;   WRITTEN BY:     Sverre H. Huseby
;
;==========================================================================

        IDEAL

        MODEL   MDL, C

        ASSUME  cs: @code, ds: @data





INCLUDE "TIMER.INC"





STRUC       ProcessData
  ProcAddr  DW  ?               ; Address of processfunction
  Counter   DW  ?               ; Counter waiting for next call
  StartCnt  DW  ?               ; Startvalue of TimerTicks
ENDS        ProcessData

PROCSIZ     EQU SIZE ProcessData
MAXPROC     EQU 40              ; Max number of running processes





UDATASEG



;==========================================================================
;
;                        P R I V A T E    D A T A
;
;==========================================================================


ProcTable   DB  (MAXPROC * PROCSIZ) DUP (?)     ; Processtable
NumProcs    DW  ?                               ; Number of processes
StopProcs   DB  ?                       ; Should all processes terminate?










CODESEG



;==========================================================================
;
;                     P U B L I C    F U N C T I O N S
;
;==========================================================================


;--------------------------------------------------------------------------
;
;   NAME:           ClearProcTable
;
;   C-DECL:         void cdecl ClearProcTable(void);
;
;   DESCRIPTION:    Clears the processtable by entering 0's in all
;                   procedure addressfields.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    ClearProcTable
PUBLIC  ClearProcTable

        mov     [NumProcs], 0

        mov     bx, OFFSET ProcTable
        mov     cx, MAXPROC

  @@next:
        mov     [(ProcessData PTR bx).ProcAddr], 0
        add     bx, PROCSIZ
        loop    @@next

        mov     [StopProcs], 0
        ret

ENDP    ClearProcTable





;--------------------------------------------------------------------------
;
;   NAME:           AddProcess
;
;   C-DECL:         int cdecl AddProcess(void (*proc)(void), int freq);
;
;   DESCRIPTION:    Adds the given function to the processtable,
;                   and sets it's callfrequency to freq.
;
;   PARAMETERS:     proc - Function to enter as a process
;                   freq - Startvalue for counter (at least 1 !!!)
;
;   RETURNS:        Processnumber of the new process, or -1 if no more room.
;
;
PROC    AddProcess
PUBLIC  AddProcess

        ARG     proc: PTR, freq: WORD

        push    di

        cmp     [NumProcs], MAXPROC
        je      @@ret_error

    ; Find available location in the table
        xor     di, di

        mov     bx, OFFSET ProcTable
        mov     cx, MAXPROC

  @@next:
        cmp     [(ProcessData PTR bx).ProcAddr], 0
        jz      @@enter_process
        inc     di
        add     bx, PROCSIZ
        loop    @@next

  @@ret_error:
    ; Not more room in the table. Return errorcode.
        mov     ax, 0FFFFh
        jmp     SHORT @@ret

  @@enter_process:
    ; Enter new process in table
        mov     ax, [proc]
        mov     [(ProcessData PTR bx).ProcAddr], ax

        mov     ax, [freq]
        mov     [(ProcessData PTR bx).StartCnt], ax
        mov     [(ProcessData PTR bx).Counter], ax

        inc     [NumProcs]

    ; Return the processnumber
        mov     ax, di

  @@ret:
        pop     di
        ret

ENDP    AddProcess





;--------------------------------------------------------------------------
;
;   NAME:           RemoveProcess
;
;   C-DECL:         void cdecl RemoveProcess(int pnr);
;
;   DESCRIPTION:    Remove the process with the given number
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    RemoveProcess
PUBLIC  RemoveProcess

        ARG     pnr: WORD

        mov     ax, [pnr]
        or      ax, ax
        jl      @@ret

        mov     bl, PROCSIZ
        mul     bl

        mov     bx, ax
        add     bx, OFFSET ProcTable

        mov     [(ProcessData PTR bx).ProcAddr], 0
        dec     [NumProcs]

  @@ret:
        ret

ENDP    RemoveProcess





;--------------------------------------------------------------------------
;
;   NAME:           StopProcesses
;
;   C-DECL:         void cdecl StopProcesses(void);
;
;   DESCRIPTION:    Stop all processes
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    StopProcesses
PUBLIC  StopProcesses

        mov     [StopProcs], 1

  @@ret:
        ret

ENDP    StopProcesses





;--------------------------------------------------------------------------
;
;   NAME:           ProcessLoop
;
;   C-DECL:         void cdecl ProcessLoop(void);
;
;   DESCRIPTION:    Run all the processes until StopProcs is not 0,
;                   or there are no more processes.
;
;   PARAMETERS:     None
;
;   RETURNS:        Nothing
;
;
PROC    ProcessLoop
PUBLIC  ProcessLoop

  @@next:
    ; Check if it is time to stop
        cmp     [StopProcs], 0
        jnz     @@ret
        cmp     [NumProcs], 0
        jz      @@ret

    ; Start counting from 0 before anything is done
        mov     [TimerTicks], 0

        mov     cx, MAXPROC
        mov     bx, OFFSET ProcTable

  @@next_proc:
        push    cx
        push    bx

    ; Is there a process at this location?
        cmp     [(ProcessData PTR bx).ProcAddr], 0
        jz      @@loop_next

    ; Decrease the counter, and perform the process if it becomes 0
        dec     [(ProcessData PTR bx).Counter]
        jnz     @@loop_next

    ; Initiate new startvalue, and call procedure
        mov     ax, [(ProcessData PTR bx).StartCnt]
        mov     [(ProcessData PTR bx).Counter], ax
        call    [(ProcessData PTR bx).ProcAddr]

  @@loop_next:
        pop     bx
        add     bx, PROCSIZ
        pop     cx
        loop    @@next_proc

  @@wait_timer:
    ; Wait until the timer has reached a certain value.
        cmp     [TimerTicks], 2
        jb      @@wait_timer
        jmp     @@next

  @@ret:
    ; Before we return, we tidy up the processtable, so there
    ; won't be any processes left the next time.
        call    ClearProcTable

        ret

ENDP    ProcessLoop





ENDS





        END
