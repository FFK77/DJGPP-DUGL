%include "param.mac"

; GLOBAL Function*************************************************************
;*** Timer
GLOBAL _DgInstallTimer,_DgUninstallTimer
GLOBAL _FInitSynch,_FSynch,_FWaitSynch

; GLOBAL DATA*****************************************************************
;*** Timer
GLOBAL _DgTime,_DgTimerFreq,_DgTimerTickVal


SECTION .text
ALIGN 32
[BITS 32]
;*** TIMER
TimerSynPrec	EQU	9

_DgInstallTimer:
	ARG	Freq, 4
		PUSH		ESI
		PUSH		EDI
		PUSH		EBX

		MOV		EAX,[EBP+Freq]
		CMP		EAX,BYTE 19
		JB		.TimerError
		MOV		[_DgTimerFreq],EAX

		MOV		AX,6	; Get DS Base Address
		MOV		BX,DS
		INT		0x31
		JC		.TimerError
		SHL		ECX,16
		AND		EDX,0xffff
		OR 		EDX,ECX
		MOV		[DSBaseAddress],EDX
		MOV		EAX,DS	     ; sauvegarde DS
		MOV		[TmMyDSSelector],AX

		MOV		AX,0x600      ; lock code
		MOV		ECX,DebTmLockCode     ; LOW WORD LAddr
		ADD		ECX,[DSBaseAddress]
		MOV		EBX,ECX     ; HIGH WORD LAddr
		SHR		EBX,16
		MOV		EDI,(FinTmLockCode-DebTmLockCode+1)
		MOV		ESI,(FinTmLockCode-DebTmLockCode+1)>>16
		INT		0x31
		JC		.TimerError

		MOV		AX,0x600      ; lock data
		MOV		ECX,DebTmLockData     ; LOW WORD LAddr
		ADD		ECX,[DSBaseAddress]
		MOV		EBX,ECX     ; HIGH WORD LAddr
		SHR		EBX,16
		MOV		EDI,(FinTmLockData-DebTmLockData+1)
		MOV		ESI,(FinTmLockData-DebTmLockData+1)>>16
		INT		0x31
		JC		.TimerError

		MOV		AX,0x204 ; Get Old Timer Handler
		MOV		BL,8
		INT		0x31
		MOV		[OldHdTmOff],EDX
		MOV		[OldHdTmSeg],ECX

		CLI			; New Timer Frequence
		MOV		AL,0x36
		OUT		0x43,AL
		MOV		EBX,[_DgTimerFreq] ; FrqTimer appels par segonde
		MOV		EAX,1193180
		XOR		EDX,EDX
		DIV		EBX

		MOV		[RestTimerTick],EDX
		MOV		[TimerAddCpt],EAX
		MOV		[_DgTimerTickVal],EAX

		OUT		0x40,AL
		MOV		AL,AH
		OUT		0x40,AL
		XOR		EAX,EAX
		MOV		[_DgTime],EAX
		MOV		[CptOldTimer],EAX
		MOV		[CptOldTimer2],EAX
		MOV		[CptOldTimer3],EAX

		MOV		AX,0x205 ; Set New Timer Handler
		MOV		BL,8
		MOV		ECX,CS
		MOV		EDX,TimerHandler  ; offset TimerHandler
		INT		0x31
		STI
		JNC		.TimerOk

.TimerError:	XOR		EAX,EAX
		JMP		SHORT .PasTmOk
.TimerOk:
		OR		EAX,BYTE -1
.PasTmOk:
		POP		EBX
		POP		EDI
		POP		ESI
	RETURN

_DgUninstallTimer:
		PUSH		ESI
		PUSH		EDI
		PUSH		EBX

		CLI

		MOV		AX,0x601      ; unlock code
		MOV		ECX,DebTmLockCode     ; LOW WORD LAddr
		ADD		ECX,[DSBaseAddress]
		MOV		EBX,ECX     ; HIGH WORD LAddr
		SHR		EBX,16
		MOV		EDI,(FinTmLockCode-DebTmLockCode+1)
		MOV		ESI,(FinTmLockCode-DebTmLockCode+1)>>16
		INT		0x31

		MOV		AX,0x601      ; unlock data
		MOV		ECX,DebTmLockData     ; LOW WORD LAddr
		ADD		ECX,[DSBaseAddress]
		MOV		EBX,ECX     ; HIGH WORD LAddr
		SHR		EBX,16
		MOV		EDI,(FinTmLockData-DebTmLockData+1)
		MOV		ESI,(FinTmLockData-DebTmLockData+1)>>16
		INT		0x31

		MOV		AL,0x36
		OUT		0x43,AL
		XOR		EAX,EAX
		MOV		[_DgTimerFreq],EAX
		MOV		[_DgTime],EAX
		OUT		0x40,AL
		OUT		0x40,AL
		MOV		AX,0x205 ; Set Old Timer Handler
		MOV		BL,8
		MOV		ECX,[OldHdTmSeg]
		MOV		EDX,[OldHdTmOff]
		INT		0x31

		STI

		POP		EBX
		POP		EDI
		POP		ESI
		FRETURN

ALIGN 32
DebTmLockCode:;****************************************************************
TimerHandler:
		PUSHF
		PUSH		DS
		PUSH		EAX

		MOV		DS,[CS:TmMyDSSelector]
		INC		DWORD [_DgTime]
		MOV		EAX,[TimerAddCpt]
		ADD		EAX,[CptOldTimer]
		TEST		EAX,0xffff0000
		JNZ		.OldTmHand
		MOV		[CptOldTimer],EAX

		MOV		AL,0x20
		OUT		0x20,AL
		POP		EAX
		POP		DS
		POPF
		STI
		IRET

.OldTmHand:
		ADD		[CptOldTimer2],EAX
		AND		EAX,0xffff
		MOV		[CptOldTimer],EAX
		CMP		DWORD [CptOldTimer2],1193180
		JB		.PasTrtCycle
		PUSH		ECX
		PUSH		EDX

		MOV		EAX,[CptOldTimer3]
		MOV		ECX,[TimerAddCpt]
		ADD		EAX,[RestTimerTick]
		CMP		EAX,ECX
		JB		.PasIncTime
		XOR		EDX,EDX
		DIV		ECX
		INC		DWORD [_DgTime]
		MOV		EAX,EDX
.PasIncTime:	MOV		[CptOldTimer3],EAX

		MOV		EAX,[CptOldTimer2]
		ADD		EAX,[RestTimerTick]
		MOV		ECX,1193180
		XOR		EDX,EDX
		DIV		ECX
		MOV		[CptOldTimer2],EDX
		AND		EDX,0xffff
		MOV		[CptOldTimer],EDX

		POP		EDX
		POP		ECX
.PasTrtCycle:
		POP		EAX
		POP		DS
		POPF
		JMP		DWORD FAR [CS:OldHdTmOff]

FinTmLockCode:;****************************************************************

SECTION	.data
ALIGN 32
;*** TIMER
DebTmLockData:;---------------------
OldHdTmOff		DD	0
OldHdTmSeg		DD	0
CptOldTimer		DD	0
CptOldTimer2	DD	0
CptOldTimer3	DD	0
TimerAddCpt		DD	0
_DgTime			DD	0
_DgTimerFreq	DD	0
_DgTimerTickVal	DD	0
RestTimerTick   DD      0
TmMyDSSelector	DW	0
TmRound			DW	0
FinTmLockData:;---------------------
DSBaseAddress	DD	0
