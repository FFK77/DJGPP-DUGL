%include "param.mac"

; GLOBAL Function*************************************************************
;*** Mouse
GLOBAL _InstallMouse,_UninstallMouse,_SetMouseRView,_GetMouseRView
GLOBAL _SetMouseOrg,_SetMousePos,_SetMouseSpeed,_SetMouseAccel,_IsMouseWheelSupported
GLOBAL _EnableMsEvntsStack,_DisableMsEvntsStack,ClearMsEvntsStack,_GetMsEvent
;*** Timer
GLOBAL _InstallTimer,_UninstallTimer
GLOBAL _FInitSynch,_FSynch,_FWaitSynch
;*** Keyboard
GLOBAL _InstallKeyboard,_UninstallKeyboard,_IsKeyDown,_PauseKeyPressed
GLOBAL _WaitKeyPressed,_SetKeybRateDelay,_GetKey,_WaitGetKey
GLOBAL _SetKbMAP,_GetKbMAP,_DisableCurKbMAP,_GetAscii,_WaitGetAscii
GLOBAL _GetKeyNbElt,_ClearKeyCircBuff,_GetAsciiNbElt,_ClearAsciiCircBuff
GLOBAL _GetCurrTimeKeyDown,_GetTimedKeyDown,_GetTimedKeyNbElt,_ClearTimedKeyCircBuff

; GLOBAL DATA*****************************************************************
;*** Mouse
GLOBAL _MsX,_MsY,_MsZ,_MsButton,_MsSpeedHz,_MsSpeedVt,_MsAccel
;*** Timer
GLOBAL _Time,_TimerFreq,_TimerTickVal
;*** Keyboard
GLOBAL _KbFLAG,_KbApp,_LastKey,_LastAscii,_CurKbMAP

; EXTERN DATA
;*** Mouse
;EXTERN _MsEventsStack,_MsStackNbElt,_MsStackEnable

;EXTERN

SECTION .text
ALIGN 32
[BITS 32]
;*** TIMER
TimerSynPrec	EQU	9

_InstallTimer:
	ARG	Freq, 4
		PUSH		ESI
		PUSH		EDI
		PUSH		EBX

		MOV		EAX,[EBP+Freq]
		CMP		EAX,BYTE 19
		JB		.TimerError
		MOV		[_TimerFreq],EAX

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
		MOV		EBX,[_TimerFreq] ; FrqTimer appels par segonde
		MOV		EAX,1193180
		XOR		EDX,EDX
		DIV		EBX

		MOV		[RestTimerTick],EDX
		MOV		[TimerAddCpt],EAX
		MOV		[_TimerTickVal],EAX

		OUT		0x40,AL
		MOV		AL,AH
		OUT		0x40,AL
		XOR		EAX,EAX
		MOV		[_Time],EAX
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

_UninstallTimer:
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
		MOV		[_TimerFreq],EAX
		MOV		[_Time],EAX
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
		RET

ALIGN 32
DebTmLockCode:;****************************************************************
TimerHandler:
		PUSHF
		PUSH		DS
		PUSH		EAX

		MOV		DS,[CS:TmMyDSSelector]
		INC		DWORD [_Time]
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
		INC		DWORD [_Time]
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
;*** MOUSE
MsPrec		EQU	5 ; Precision de la souris
_InstallMouse:
		PUSH		ESI
		PUSH		EDI
		PUSH		EBX

		MOV		[MsMyDSSelector],DS ; sauvegarde DS
		XOR		EAX,EAX
		MOV		[_V_EAX],EAX	  ; func 0 initmouse
		MOV		DWORD [_V_RES],EAX
		MOV		WORD [_V_SS],AX
		MOV		WORD [_V_SP],AX
		MOV		EAX,DS
		MOV		ES,EAX
		MOV		AX,0x300           ; DPMI 300h
		MOV		BX,0x33
		XOR		ECX,ECX
		MOV		EDI,_V_EDI
		INT		0x31
		CMP		WORD [_V_EAX],0
		JE		.MouseError
		; detect wheel API
		XOR		EAX,EAX
		MOV		WORD [_V_EAX],0x11
		MOV		DWORD [_V_RES],EAX
		MOV		WORD [_V_SS],AX
		MOV		WORD [_V_SP],AX
		MOV		EAX,DS
		MOV		ES,EAX
		MOV		AX,0x300           ; DPMI 300h
		MOV		BX,0x33
		XOR		ECX,ECX
		MOV		EDI,_V_EDI
		INT		0x31
		CMP		WORD [_V_EAX],0x574D ; "WM" wheel API supported
		JNE		.NoWheelAPI
		TEST		BYTE [_V_ECX], 1 ; check first capabilities bit
						 ; pointing device supports wheel

		SETNZ		[MsWheelSupp]
.NoWheelAPI:
		; end wheel detection

		MOV		AX,6	; Get DS Base Address
		MOV		EBX,DS
		INT		0x31
		JC		.MouseError
		SHL		ECX,16
		AND		EDX,0xffff
		OR 		EDX,ECX
		MOV		[DSBaseAddress],EDX

		MOV		AX,0x600      ; lock code
		MOV		ECX,DebMsLockCode     ; LOW WORD LAddr
		ADD		ECX,[DSBaseAddress]
		MOV		EBX,ECX     ; HIGH WORD LAddr
		SHR		EBX,16
		MOV		EDI,(FinMsLockCode-DebMsLockCode+1)
		MOV		ESI,(FinMsLockCode-DebMsLockCode+1)>>16
		INT		0x31
		JC		.MouseError

		MOV		AX,0x600      ; lock data
		MOV		ECX,DebMsLockData     ; LOW WORD LAddr
		ADD		ECX,[DSBaseAddress]
		MOV		EBX,ECX     ; HIGH WORD LAddr
		SHR		EBX,16
		MOV		EDI,(FinMsLockData-DebMsLockData+1)
		MOV		ESI,(FinMsLockData-DebMsLockData+1)>>16
		INT		0x31
		JC		.MouseError

		PUSH		DS
		MOV		ESI,MouseHandler
		MOV		EDI,VMsH_EDI
		MOV		EAX,DS
		MOV		ES,EAX
		MOV		EAX,CS
		MOV		DS,EAX
		MOV		AX,0x303      ; alloc real mode callback
		INT		0x31
		POP		DS
		JC		.MouseError
		MOV		[SegMsCallBack],CX
		MOV		[OffMsCallBack],DX

		MOV		WORD [_V_EAX],0xC
		MOV		WORD [_V_ECX],0xFF ; install rm CallBack
		MOV		WORD [_V_ES],CX
		MOV		WORD [_V_EDX],DX
		XOR		EAX,EAX
		MOV		DWORD [_V_RES],EAX
		MOV		WORD [_V_SS],AX
		MOV		WORD [_V_SP],AX
		MOV		EAX,DS
		MOV		ES,EAX
		MOV		AX,0x300           ; DPMI 300h
		MOV		BX,0x33
		XOR		ECX,ECX
		MOV		EDI,_V_EDI
		INT		0x31

		JNC		.MouseOk

.MouseError:	XOR		EAX,EAX
		JMP		SHORT .PasMsOk
.MouseOk:
		XOR		EAX,EAX
		MOV		ECX,(MsOrgX-_MsX)/4
		MOV		EDI,_MsX
		REP		STOSD
		MOV		BYTE [MsFirstInt],1
		MOV		BYTE [_MsSpeedHz],32
		MOV		BYTE [_MsSpeedVt],32

		OR		EAX,BYTE -1
.PasMsOk:
		POP		EBX
		POP		EDI
		POP		ESI
		RET

_UninstallMouse:
		PUSH		ESI
		PUSH		EDI
		PUSH		EBX

		MOV		EAX,0x21      ; reset software
		INT		0x33

		MOV		EAX,0x601      ; unlock code
		MOV		ECX,DebMsLockCode     ; LOW WORD LAddr
		ADD		ECX,[DSBaseAddress]
		MOV		EBX,ECX     ; HIGH WORD LAddr
		SHR		EBX,16
		MOV		EDI,(FinMsLockCode-DebMsLockCode+1)
		MOV		ESI,(FinMsLockCode-DebMsLockCode+1)>>16
		INT		0x31

		MOV		EAX,0x601      ; unlock data
		MOV		ECX,DebMsLockData     ; LOW WORD LAddr
		ADD		ECX,[DSBaseAddress]
		MOV		EBX,ECX     ; HIGH WORD LAddr
		SHR		EBX,16
		MOV		EDI,(FinMsLockData-DebMsLockData+1)
		MOV		ESI,(FinMsLockData-DebMsLockData+1)>>16
		INT		0x31

		MOV		EAX,0x304      ; free real mode callback
		MOV		CX,[SegMsCallBack]
		MOV		DX,[OffMsCallBack]
		INT		0x31

		POP		EBX
		POP		EDI
		POP		ESI

		RET

_IsMouseWheelSupported:
		XOR		EAX,EAX
		MOV		AL,[MsWheelSupp]
		RET

_SetMouseRView:
	ARG	V1, 4

		PUSH		EDI
		PUSH		ESI
		PUSH		EBX

		MOV		ESI,[EBP+V1]
		MOV		EDI,MsOrgX
		MOV		ECX,6
		REP		MOVSD
		MOV		EAX,[_MsX]
		MOV		EBX,[_MsY]
		MOV		ECX,[MsMaxX]
		MOV		EDX,[MsMaxY]
		CMP		EAX,ECX
		JLE		.MsPasSupMxX
		MOV		EAX,ECX
.MsPasSupMxX:	CMP		EBX,EDX
		JLE		.MsPasSupMxY
		MOV		EBX,EDX
.MsPasSupMxY:
		MOV		ECX,[MsMinX]
		MOV		EDX,[MsMinY]
		CMP		EAX,ECX
		JGE		.MsPasInfMnX
		MOV		EAX,ECX
.MsPasInfMnX:	CMP		EBX,EDX
		JGE		.MsPasInfMnY
		MOV		EBX,EDX
.MsPasInfMnY:
		MOV		[_MsY],EBX
		MOV		[_MsX],EAX

		POP		EBX
		POP		ESI
		POP		EDI
		RETURN

_GetMouseRView:
	ARG	V2, 4
		PUSH		ESI
		PUSH		EDI

		MOV		ECX,6
		MOV		ESI,MsOrgX
		MOV		EDI,[EBP+V2]
		REP		MOVSD

		POP		EDI
		POP		ESI
		RETURN

_SetMouseOrg:
	ARG	MsXOrg, 4, MsYOrg, 4

		MOV		EAX,[EBP+MsXOrg]
		MOV		ECX,[EBP+MsYOrg]
		MOV		EDX,EAX
		MOV		EBP,ECX

		SUB		EAX,[MsOrgX] ; DX
		SUB		ECX,[MsOrgY] ; DY
		SUB		[MsMaxX],EAX
		SUB		[MsMinX],EAX
		SUB		[MsMaxY],ECX
		SUB		[MsMinY],ECX
		MOV		[MsOrgX],EDX
		MOV		[MsOrgY],EBP

		RETURN

_SetMousePos:
	ARG	MouseX, 4, MouseY, 4

		MOV		EAX,[EBP+MouseX]
		MOV		ECX,[EBP+MouseY]

		CMP		EAX,[MsMaxX]
		JLE		.MsPasSupMxX
		MOV		EAX,[MsMaxX]
.MsPasSupMxX:	CMP		ECX,[MsMaxY]
		JLE		.MsPasSupMxY
		MOV		ECX,[MsMaxY]
.MsPasSupMxY:	CMP		EAX,[MsMinX]
		JGE		.MsPasInfMnX
		MOV		EAX,[MsMinX]
.MsPasInfMnX:	CMP		ECX,[MsMinY]
		JGE		.MsPasInfMnY
		MOV		ECX,[MsMinY]
.MsPasInfMnY:
		MOV		[_MsX],EAX
		MOV		[_MsY],ECX

		RETURN

_SetMouseSpeed:
	ARG	MsHzSpeed, 4, MsVtSpeed, 4

		MOV		ECX,[EBP+MsHzSpeed]
		MOV		EDX,[EBP+MsVtSpeed]
		CMP		ECX,BYTE (1<<MsPrec)
		JAE		.PSetHzSp2Min
		MOV		ECX,1<<MsPrec
.PSetHzSp2Min:
		CMP		EDX,BYTE (1<<MsPrec)
		JAE		.PSetVtSp2Min
		MOV		EDX,1<<MsPrec
.PSetVtSp2Min:
		CLI
		MOV		DWORD [_MsSpeedHz],ECX
		MOV		DWORD [_MsSpeedVt],EDX
		STI

		RETURN

_SetMouseAccel:
	ARG	MsAccel, 4

		MOV		EAX,[EBP+MsAccel]
		MOV		[_MsAccel],EAX

		RETURN

; mouse event stack function
_EnableMsEvntsStack:
		XOR		EAX,EAX
		MOV		[MsStackNbElt],EAX
		MOV		[MsStackStart],EAX
		OR		AL,1
		MOV		[MsStackEnable],EAX
		RET

_DisableMsEvntsStack:
		XOR		EAX,EAX
		MOV		[MsStackEnable],EAX
		MOV		[MsStackNbElt],EAX
		MOV		[MsStackStart],EAX
		RET

_ClearMsEvntsStack:
		XOR		EAX,EAX
		MOV		[MsStackNbElt],EAX
		MOV		[MsStackStart],EAX
		RET

_GetMsEvent:
		ARG	MsEvnt, 4
		CLI ; critique function

		MOV		EAX,[MsStackNbElt]
		OR		EAX,EAX
		JZ		.finNoMsEvt

		PUSH		EDI
		DEC		EAX ; _MsStackNbElt-1
		PUSH		ESI
		MOV		EDX,[MsStackStart]
		MOV		[MsStackNbElt],EAX
		MOV		ECX,EDX ; MsStackSart
		PUSH		EBX
		IMUL		EDX,MouseEvent.Size
		INC		ECX
		ADD		EDX,MsEventsStack
		AND		ECX,0xFF ; rotate value 255->0
		MOV		EDI,[EBP+MsEvnt]
		MOV		[MsStackStart],ECX
		MOV		ESI,EDX
		MOV		EBX,[ESI+4] ; Y
		MOV		ECX,[ESI+8] ; Z
		MOV		EDX,[ESI+12] ; Button
		MOV		EAX,[ESI] ; X
		MOV		[EDI+4],EBX
		MOV		[EDI+8],ECX
		MOV		[EDI+12],EDX
		MOV		EBX,[ESI+16] ; Ms Evnt
		MOV		[EDI],EAX
		MOV		[EDI+16],EBX ; Ms Evnt
		MOV		AL,1 ; return true

.finGetMs:	POP		EBX
		POP		ESI
		POP		EDI
.finNoMsEvt:
		STI ; end critique
		RETURN

; Mouse Event Structure **************************
		struc MouseEvent
.MsX		resd	1
.MsY		resd	1
.MsZ		resd	1
.MsButton	resd	1
.MsEvents	resd	1
.Size
		endstruc
ALIGN 32
DebMsLockCode:;****************************************************************
MouseHandler:
		PUSH		ES
		PUSH		EDI

		LODSD
		MOV		[ES:EDI+0x2A],EAX   ; CS:IP
		ADD		WORD [ES:EDI+0x2E],4 ; REAL SP+4

		MOV		EAX,[CS:MsMyDSSelector]
		MOV		DS,EAX
		MOV		ES,EAX

		MOV		EAX,[MsFirstInt]
		OR		EAX,EAX
		JZ		.NormMs
		MOV		EAX,[VMsH_ESI]
		MOV		EBP,[VMsH_EDI]
		MOV		[MsMickeyX],EAX
		XOR		ECX,ECX
		MOV		[MsMickeyY],EBP
		MOV		[MsFirstInt],ECX
		JMP		.PasMovMouse
.NormMs:
		TEST		BYTE [VMsH_EAX],1
		JZ		.PasMovMouse

		XOR		EAX,EAX
		XOR		EBP,EBP
		MOV		EAX,[VMsH_ESI]
		MOV		EBP,[VMsH_EDI]
		MOV		ECX,EAX  ;MsMickeyX
		MOV		EBX,EBP  ;MsMickeyY
		SUB		AX,[MsMickeyX]
		MOVSX		EAX,AX
		SHL		EAX,MsPrec
		ADD		EAX,[MsRestMickeyX]
		CDQ
		IDIV		DWORD [_MsSpeedHz]
		MOV		[MsRestMickeyX],EDX
		MOV		ESI,EAX

		SUB		BP,[MsMickeyY]
		MOVSX		EAX,BP
		SHL		EAX,MsPrec
		ADD		EAX,[MsRestMickeyY]
		CDQ
		IDIV		DWORD [_MsSpeedVt]
		MOV		[MsRestMickeyY],EDX

		ADD		[_MsX],ESI
		SUB		[_MsY],EAX

		MOV		EAX,[_MsX]
		MOV		EDX,[_MsY]
		CMP		EAX,[MsMaxX]
		JLE		.MsPasSupMxX
		MOV		EAX,[MsMaxX]
.MsPasSupMxX:	CMP		EDX,[MsMaxY]
		JLE		.MsPasSupMxY
		MOV		EDX,[MsMaxY]
.MsPasSupMxY:	CMP		EAX,[MsMinX]
		JGE		.MsPasInfMnX
		MOV		EAX,[MsMinX]
.MsPasInfMnX:	CMP		EDX,[MsMinY]
		JGE		.MsPasInfMnY
		MOV		EDX,[MsMinY]
.MsPasInfMnY:
		MOV		[_MsX],EAX
		MOV		[_MsY],EDX

		MOV		[MsMickeyX],ECX
		MOV		[MsMickeyY],EBX
.PasMovMouse:
		TEST		BYTE [VMsH_EAX],0x80
		JZ		.NoWheelEvent
		CMP		BYTE [MsWheelSupp],0
		JZ		.NoSuppWheel
		MOVSX		EAX,BYTE [VMsH_EBX+1]
		ADD		[_MsZ],EAX
.NoSuppWheel:
.NoWheelEvent:
		MOV		EBX,[VMsH_EBX]
		AND		EBX,0xff
		MOV		[_MsButton],EBX
; handle mouse events stack *******************
		MOV		EAX,[MsStackEnable]
		OR		EAX,EAX
		JZ		.EndMs  ; Mouse Evt Stack Disabled
		MOV		ECX,[MsStackNbElt]
		CMP		ECX,256
		JGE		.EndMs ; Mouse Evt Stack Full
		ADD		ECX,[MsStackStart]
		AND		ECX,0xFF ; rotate value 256->0
		IMUL		ECX,MouseEvent.Size
		LEA		EDI,[MsEventsStack+ECX] ; EDI point to the new Evt Elmnt
		MOV		EAX,[_MsX]
		MOV		EBX,[_MsY]
		CMP		BYTE [MsWheelSupp],0
		JE		.WheelNotSupp
		MOV		ECX,[_MsZ]
		JMP		SHORT .WheelSupp
.WheelNotSupp:
		XOR		ECX,ECX ; MsZ
.WheelSupp:
		MOV		EDX,[_MsButton]
		MOV		[EDI+MouseEvent.MsX],EAX
		MOV		[EDI+MouseEvent.MsY],EBX
		MOV		[EDI+MouseEvent.MsZ],ECX
		MOV		[EDI+MouseEvent.MsButton],EDX
		MOV		EAX,[VMsH_EAX] ; event
		INC		DWORD [MsStackNbElt]
		MOV		[EDI+MouseEvent.MsEvents],EAX

.EndMs:
		POP		EDI
		POP		ES
		IRET
FinMsLockCode:;****************************************************************

;*** KEYBOARD
_InstallKeyboard:
		PUSH		ESI
		PUSH		EDI
		PUSH		EBX

		XOR		EAX,EAX ; reset to zero all kb vars
		MOV		ECX,(FinKbLockData-_CurKbMAP) / 4
		MOV		EDI,_CurKbMAP
		REP		STOSD

		MOV		AX,6	; Get DS Base Address
		MOV		BX,DS
		INT		0x31
		JC		.KeyboardError
		SHL		ECX,16
		AND		EDX,0xffff
		OR 		EDX,ECX
		MOV		[DSBaseAddress],EDX
		MOV		EAX,DS	     ; sauvegarde DS
		MOV		[KbMyDSSelector],AX

		MOV		AX,2	; Get BIOS Data Area Selector
		MOV		BX,0x40
		INT		0x31
		JC		.KeyboardError
		MOV		[SelBiosDatArea],EAX

		PUSH		ES     ; avoir etat clavier
		MOV		ES,EAX
		XOR		EBX,EBX
		MOV		BX,[ES:0x17]
		MOV		[_KbFLAG],EBX
		POP		ES

		MOV		AX,0x600      ; lock code
		MOV		ECX,DebKbLockCode     ; LOW WORD LAddr
		ADD		ECX,[DSBaseAddress]
		MOV		EBX,ECX     ; HIGH WORD LAddr
		SHR		EBX,16
		MOV		EDI,(FinKbLockCode-DebKbLockCode+1)
		MOV		ESI,(FinKbLockCode-DebKbLockCode+1)>>16
		INT		0x31
		JC		.KeyboardError

		MOV		AX,0x600      ; lock data
		MOV		ECX,DebKbLockData     ; LOW WORD LAddr
		ADD		ECX,[DSBaseAddress]
		MOV		EBX,ECX     ; HIGH WORD LAddr
		SHR		EBX,16
		MOV		EDI,(FinKbLockData-DebKbLockData+1)
		MOV		ESI,(FinKbLockData-DebKbLockData+1)>>16
		INT		0x31
		JC		.KeyboardError

		MOV		AX,0x204 ; Get Old Keyboard Handler
		MOV		BL,9
		INT		0x31
		MOV		[OldHdKbOff],EDX
		MOV		[OldHdKbSeg],ECX

		CLI

		MOV		AX,0x205 ; Set New Keyboard Handler
		MOV		BL,9
		MOV		ECX,CS
		MOV		EDX,KeyboardHandler ; offset KeyboardHandler
		INT		0x31

		STI
		JNC		.KeyboardOk

.KeyboardError:	XOR		EAX,EAX
		JMP		SHORT .PasKbOk
.KeyboardOk:
		OR		EAX,BYTE -1
.PasKbOk:
		POP		EBX
		POP		EDI
		POP		ESI
		RET


_UninstallKeyboard:
		PUSH		ESI
		PUSH		EDI
		PUSH		EBX

		CLI

		MOV		EAX,[SelBiosDatArea] ; MAJ etat clavier
		PUSH		ES
		MOV		ES,EAX
		MOV		BX,[_KbFLAG]
		AND		BX,~0x800    ; desactive le bit PAUSE
		MOV		[ES:0x17],BX
		POP		ES

		MOV		AX,0x601      ; unlock code
		MOV		ECX,DebKbLockCode     ; LOW WORD LAddr
		ADD		ECX,[DSBaseAddress]
		MOV		EBX,ECX     ; HIGH WORD LAddr
		SHR		EBX,16
		MOV		EDI,(FinKbLockCode-DebKbLockCode+1)
		MOV		ESI,(FinKbLockCode-DebKbLockCode+1)>>16
		INT		0x31

		MOV		AX,0x601      ; unlock data
		MOV		ECX,DebKbLockData     ; LOW WORD LAddr
		ADD		ECX,[DSBaseAddress]
		MOV		EBX,ECX     ; HIGH WORD LAddr
		SHR		EBX,16
		MOV		EDI,(FinKbLockData-DebKbLockData+1)
		MOV		ESI,(FinKbLockData-DebKbLockData+1)>>16
		INT		0x31

                ; disable current keybmap
		XOR		EAX,EAX
		MOV		[AsciiCBDeb],EAX
		MOV		[AsciiCBFin],EAX
		MOV		[AsciiNbElt],EAX
		MOV		[_LastAscii],AL
		CMP		[ValidCurKbMAP],EAX
		JE		.PasExistOthMp
		MOV		[ValidCurKbMAP],EAX
		CALL		UnlockCurKbMAP
.PasExistOthMp:
                ; Set Old Keyboard Handler
                MOV		AX,0x205
		MOV		BL,9
		MOV		ECX,[OldHdKbSeg]
		MOV		EDX,[OldHdKbOff]
		INT		0x31

		STI

		POP		EBX
		POP		EDI
		POP		ESI
		RET

_IsKeyDown:
	ARG	NumKey, 4

		MOVZX		EAX,BYTE [EBP+NumKey]
		MOV		ECX,EAX
		MOV		EDX,EAX
		SHR		ECX,3
		AND		EDX,BYTE 0x7
		MOV		CL,[_KbApp+ECX]
		BT		ECX,EDX
		SETC		AL

		RETURN

_SetKeybRateDelay:
	ARG	KbRateDelay, 4
		CALL		WaitKbBuffEmpty
		MOV		AL,0xF3
		OUT		0x60,AL
		CALL		WaitKbBuffEmpty
		MOV		AL,[EBP+KbRateDelay]
		OUT		0x60,AL

		RETURN

_PauseKeyPressed:
		XOR		EAX,EAX
		CLI
		MOV		AL,[PausePressed]
		MOV		[PausePressed],AH
		STI

		RET

_WaitKeyPressed:
		XOR		EAX,EAX
.BcWKP:		MOV		AL,[_LastKey]
		OR		AL,AL
		JZ		.BcWKP
		MOV		[_LastKey],AH

		RET

;		MOV		DWORD [KeyFrstDownTime+EAX*4],ESI
;		MOV		[KeyTimeEvents+ECX*4],ESI
;		AND		EDX,BYTE 0x1f ; rotate value
;		MOV		[KeyTimeKyEvents+ECX],AL

_GetTimedKeyNbElt:
		MOV		EAX,[KeyTimeNbElt]
		RET

_ClearTimedKeyCircBuff:
		XOR		EAX,EAX
		CLI
		MOV		[KeyTimeCBDeb],EAX
		MOV		[KeyTimeCBFin],EAX
		MOV		[KeyTimeNbElt],EAX
		STI
		RET

_GetCurrTimeKeyDown:
	ARG	TmNumKey, 4

		MOVZX		EAX,BYTE [EBP+TmNumKey]
		MOV		ECX,EAX
		MOV		EDX,EAX
		SHR		ECX,3
		AND		EDX,BYTE 0x7
		CLI
		MOV		CL,[_KbApp+ECX]
		BT		ECX,EDX
		JC		.KeyDown
		SETC		AL
		JMP		SHORT .End
.KeyDown:	MOV		EBX,[KeyFrstDownTime+EAX*4]
		MOV		EAX,[_Time]
		SUB		EAX,EBX
.End:		STI
		RETURN

_GetTimedKeyDown:
	ARG	PTmKey, 4, PKeyTIME, 4
		PUSH		ESI
		PUSH		EDI
		PUSH		EBX

		XOR		EAX,EAX
		MOV		ESI,[EBP+PTmKey]
		MOV		EDI,[EBP+PKeyTIME]
		MOV		EDX,[KeyTimeNbElt]
		MOV		[ESI],AL   ; key
		MOV		[EDI],EAX  ; keyTIME
		OR		EDX,EDX
		JZ		.CircBuffEmpty
		CLI
		MOV		ECX,[KeyTimeCBDeb]
		DEC		DWORD [KeyTimeNbElt]
		LEA		EBX,[ECX+1]
		MOV		EDX,[KeyTimeEvents+ECX*4]
		MOV		AL,[KeyTimeKyEvents+ECX]
		AND		EBX,BYTE 0x1f
		MOV		[EDI],EDX  ; keyFLAG
		MOV		[ESI],AL   ; key
		MOV		[KeyTimeCBDeb],EBX
		STI
.CircBuffEmpty:
		POP		EBX
		POP		EDI
		POP		ESI
		RETURN

_GetKey:
	ARG	PKey, 4, PKeyFLAG, 4
		PUSH		ESI
		PUSH		EDI
		PUSH		EBX

		XOR		EAX,EAX
		MOV		ESI,[EBP+PKey]
		MOV		EDI,[EBP+PKeyFLAG]
		MOV		EDX,[KeyNbElt]
		MOV		[ESI],AL   ; key
		MOV		[EDI],EAX  ; keyFLAG
		OR		EDX,EDX
		JZ		.CircBuffEmpty
		CLI
		MOV		ECX,[KeyCBDeb]
		DEC		DWORD [KeyNbElt]
		LEA		EBX,[ECX+1]
		MOV		EDX,[KeyKbFLAG+ECX*4]
		MOV		AL,[KeyCircBuff+ECX]
		AND		EBX,BYTE 0x1f
		MOV		[EDI],EDX  ; keyFLAG
		MOV		[ESI],AL   ; key
		MOV		[KeyCBDeb],EBX
		STI
.CircBuffEmpty:
		POP		EBX
		POP		EDI
		POP		ESI
		RETURN

_WaitGetKey:
	ARG	WPKey, 4, WPKeyFLAG, 4
		PUSH		ESI
		PUSH		EDI
		PUSH		EBX

		MOV		ESI,[EBP+WPKey]
		MOV		EDI,[EBP+WPKeyFLAG]
		XOR		EAX,EAX
.BcWaitKey:	MOV		EDX,[KeyNbElt]
		OR		EDX,EDX
		JZ		.BcWaitKey
		CLI
		MOV		ECX,[KeyCBDeb]
		DEC		DWORD [KeyNbElt]
		MOV		EBX,ECX
		MOV		EDX,[KeyKbFLAG+ECX*4]
		MOV		AL,[KeyCircBuff+ECX]
		MOV		[EDI],EDX ; keyFLAG
		MOV		[ESI],AL  ; key
		INC		EBX
		AND		EBX,BYTE 0x1f
		MOV		[KeyCBDeb],EBX
		STI
		POP		EBX
		POP		EDI
		POP		ESI

		RETURN

_GetKeyNbElt:
		MOV		EAX,[KeyNbElt]
		RET

_ClearKeyCircBuff:
		CLI
		XOR		EAX,EAX ; Initialisation des vars
		MOV		[KeyCBDeb],EAX
		MOV		[KeyCBFin],EAX
		MOV		[KeyNbElt],EAX
		MOV		[_LastKey],AL
		STI
		RET

;-------------------------------------
_SetKbMAP:
	ARG	PSetKM, 4
		PUSH		ESI
		PUSH		EDI
		PUSH		EBX

		CLI
		XOR		EAX,EAX
		MOV		[AsciiCBDeb],EAX
		MOV		[AsciiCBFin],EAX
		MOV		[AsciiNbElt],EAX
		MOV		[_LastAscii],AL
		CMP		DWORD [ValidCurKbMAP],EAX
		JE		.PasExistOthMp
		CALL		UnlockCurKbMAP
.PasExistOthMp:
		MOV		ESI,[EBP+PSetKM]
		MOV		EDI,_CurKbMAP
		MOV		ECX,16
		REP		MOVSD
		CALL		LockCurKbMAP
		MOV		[ValidCurKbMAP],EAX
		STI

		POP		EBX
		POP		EDI
		POP		ESI
		RETURN

_GetKbMAP:
	ARG	PGetKM, 4
		PUSH		ESI
		PUSH		EDI

		MOV		ESI,_CurKbMAP
		MOV		EDI,[EBP+PGetKM]
		MOV		ECX,16
		REP		MOVSD

		POP		EDI
		POP		ESI
		RETURN

_DisableCurKbMAP:
		PUSH		ESI
		PUSH		EDI
		PUSH		EBX

		CLI
		XOR		EAX,EAX
		MOV		[AsciiCBDeb],EAX
		MOV		[AsciiCBFin],EAX
		MOV		[AsciiNbElt],EAX
		MOV		[_LastAscii],AL
		CMP		[ValidCurKbMAP],EAX
		JE		.PasExistOthMp
		MOV		[ValidCurKbMAP],EAX
		CALL		UnlockCurKbMAP
.PasExistOthMp:
		STI

		POP		EBX
		POP		EDI
		POP		ESI
		RET

_GetAscii:
	ARG	PAscii, 4, PAsciiFLAG, 4
		CMP		DWORD [ValidCurKbMAP],BYTE 0
		JNE		.KbMapActv
		XOR		EDX,EDX
		MOV		EAX,[EBP+PAscii]
		MOV		[EAX],DL
		MOV		EAX,[EBP+PAsciiFLAG]
		MOV		[EAX],EDX
		RETURN
.KbMapActv:
		PUSH		ESI
		PUSH		EDI
		PUSH		EBX
		MOV		ESI,[EBP+PAscii]
		MOV		EDI,[EBP+PAsciiFLAG]
		MOV		EDX,[AsciiNbElt]
		XOR		EAX,EAX
		MOV		[EDI],EAX  ; AsciiFLAG 0
		MOV		[ESI],AL   ; Ascii 0
		OR		EDX,EDX
		JZ		.CircBuffFree
		PUSH		EBX
		CLI
		MOV		ECX,[AsciiCBDeb]
		DEC		DWORD [AsciiNbElt]
		MOV		EBX,ECX
		MOV		EDX,[AsciiKbFLAG+ECX*4]
		MOV		AL,[AsciiCircBuff+ECX]
		MOV		[EDI],EDX  ; AsciiFLAG
		MOV		[ESI],AL   ; Ascii
		INC		EBX
		AND		EBX,BYTE 0x1f
		MOV		[AsciiCBDeb],EBX
		STI
		POP		EBX
.CircBuffFree:
		POP		EBX
		POP		EDI
		POP		ESI
		RETURN


_WaitGetAscii:
	ARG	WPAscii, 4, WPAsciiFLAG, 4
		XOR		EAX,EAX
		CMP		[ValidCurKbMAP],EAX
		JNE		.KbMapActv
		XOR		EDX,EDX
		MOV		EAX,[EBP+PAscii]
		MOV		[EAX],DL
		MOV		EAX,[EBP+PAsciiFLAG]
		MOV		[EAX],EDX
		RETURN

.KbMapActv:	PUSH		ESI
		PUSH		EDI
		PUSH		EBX
		MOV		ESI,[EBP+WPAscii]
		MOV		EDI,[EBP+WPAsciiFLAG]

.BcWaitAscii:	MOV		EDX,[AsciiNbElt]
		OR		EDX,EDX
		JZ		.BcWaitAscii
		PUSH		EBX
		CLI
		MOV		ECX,[AsciiCBDeb]
		DEC		DWORD [AsciiNbElt]
		MOV		EBX,ECX
		MOV		EDX,[AsciiKbFLAG+ECX*4]
		MOV		AL,[AsciiCircBuff+ECX]
		MOV		[EDI],EDX  ; AsciiFLAG
		MOV		[ESI],AL   ; Ascii
		INC		EBX
		AND		EBX,BYTE 0x1f
		MOV		[AsciiCBDeb],EBX
		STI
		POP		EBX

		RETURN

_GetAsciiNbElt:
		MOV		EAX,[AsciiNbElt]
		RET

_ClearAsciiCircBuff:
		CLI
		XOR		EAX,EAX ; Initialisation des vars
		MOV		[AsciiCBDeb],EAX
		MOV		[AsciiCBFin],EAX
		MOV		[AsciiNbElt],EAX
		MOV		[_LastAscii],AL
		STI
		RET

LockCurKbMAP:
		MOV		AX,0x600
		MOV		ECX,[KbMapPtr]
		ADD		ECX,[DSBaseAddress]
		MOV		EBX,ECX     ; HIGH WORD LAddr
		SHR		EBX,16
		MOV		EDI,[SizeKb]
		MOV		ESI,[SizeKb]
		SHR		ESI,16
		INT		0x31
		JC		.LockCurKbErr
		OR		EAX,BYTE -1
		JMP		SHORT .LockCurKbOk
.LockCurKbErr:	XOR		EAX,EAX
.LockCurKbOk:
		RET

UnlockCurKbMAP:
		MOV		AX,0x601
		MOV		ECX,[KbMapPtr]
		ADD		ECX,[DSBaseAddress]
		MOV		EBX,ECX     ; HIGH WORD LAddr
		SHR		EBX,16
		MOV		EDI,[SizeKb]
		MOV		ESI,[SizeKb]
		SHR		ESI,16
		INT		0x31

		RET


ALIGN 32
DebKbLockCode:;****************************************************************
KeyboardHandler:
		PUSHF
		PUSHAD
		PUSH		DS

		;IN		AL,0x64
		MOV		DS,[CS:KbMyDSSelector]
		XOR		EAX,EAX
		;TEST 		AL,0x20   ; 00100000b - mouse interface
		;JNZ		NEAR .OldKbHand

		CMP		BYTE [ExtKey],1
		JE		.ExtKey
		CMP		BYTE [PauseKey],1
		JE		.PauseKey
.NormKey:	IN		AL,0x60
		CMP		AL,0xE0
		JNZ		.PExtKey
		MOV		BYTE [ExtKey],1
		JMP		.FinKey
.PExtKey:	CMP		AL,0xE1
		JNZ		.PPauseKey
		MOV		BYTE [PauseKey],1
		JMP		.FinKey
.PPauseKey:
.Norm:		OR		AL,AL
		JS		.RelNorm

.AppNorm:
		MOV		[_LastKey],AL
		XOR		EBX,EBX
		MOV		EDX,EAX
		MOV		ECX,EAX
		AND		EDX,BYTE 0x7
		SHR		ECX,3
		BTS		EBX,EDX

		TEST		BL,[_KbApp+ECX]
		JNZ		.AlreadyApp
		MOV		EDX,[_Time]
		OR		[_KbApp+ECX],BL
		MOV		[KeyFrstDownTime+EAX*4],EDX
.AlreadyApp:
		CALL		TraitApp
		CALL		TraitKey
		CALL		TraitAscii
		JMP		.FinKey
.RelNorm:	SUB		AL,128
		XOR		EBX,EBX
		MOV		EDX,EAX
		MOV		ECX,EAX
		MOV		BYTE [_LastKey],BL
		AND		EDX,BYTE 0x7
		SHR		ECX,3
		BTS		EBX,EDX
		NOT		EBX

		AND		[_KbApp+ECX],BL
		CALL		TraitTimeKey
		CALL		TraitRel

		JMP		.FinKey
.ExtKey:	MOV		BYTE [ExtKey],0
		IN		AL,0x60
		CMP		AL,42
		JZ		.FinKey
		CMP		AL,170
		JZ		.FinKey
		OR		AL,AL
		JS		.RelExt
.AppExt:	ADD		AL,128
		XOR		EBX,EBX
		MOV		EDX,EAX
		MOV		ECX,EAX
		MOV		[_LastKey],AL
		AND		EDX,BYTE 0x7
		SHR		ECX,3
		BTS		EBX,EDX
		TEST		BL,[_KbApp+ECX]
		JNZ		.AlreadyAppExt
		MOV		EDX,[_Time]
		OR		[_KbApp+ECX],BL
		MOV		[KeyFrstDownTime+EAX*4],EDX
.AlreadyAppExt:

		CALL		TraitApp
		CALL		TraitKey
		CALL		TraitAscii
		JMP		SHORT .FinKey
.RelExt:
		XOR		EBX,EBX
		MOV		EDX,EAX
		MOV		ECX,EAX
		MOV		BYTE [_LastKey],BL
		AND		EDX,BYTE 0x7
		SHR		ECX,3
		BTS		EBX,EDX
		NOT		EBX
		AND		[_KbApp+ECX],BL
		CALL		TraitTimeKey
		CALL		TraitRel

		JMP		SHORT .FinKey
.PauseKey:	IN		AL,0x60
		CMP		AL,197
		JNZ		.EncPause
		MOV		WORD [PauseKey],0x100 	; PauseKey=0
					; PausePressed=1
		XOR		DWORD [_KbFLAG],0x800
.EncPause:
.FinKey:	MOV		AL,0x20
		OUT		0x20,AL

		POP		DS
		POPAD
		POPF
		STI
		IRET

.OldKbHand:	POP		DS
		POPAD
		POPF
		JMP		DWORD FAR [CS:OldHdKbOff]

;---- Traitement Ascii ---------------***************************************
;****************************************************************************

		struc NormKeyb
.MaskYes	resd	1
.MaskNo		resd	1
.DefActiv	resd	1
.NbAscii	resd	1
.Ptr		resd	1
.Size
		endstruc

		struc PrefixKeyb
.MaskYes	resd	1
.MaskNo		resd	1
.DefActiv	resd	1
.NbKeybNorm	resd	1
.TabNormKeyb	resd	1
.resv2		resd	1
.DefaultAscii	resb	1
.code		resb	1
.resv		resb	2
.Size
		endstruc

TraitAscii:
		PUSH		EAX
		CMP		DWORD [ValidCurKbMAP],0
		JE		.PasTraitAscii ;-----------------------

		; test si Code Key Ascii ----------
		MOV		ESI,TbNonAscii
		MOV		ECX,[NbKbNonAscii]
		XOR		EDX,EDX
		MOV		DL,AL
.BcSrNonAscii:	LODSB
		CMP		AL,DL
		JE		.PasTraitAscii
		DEC		ECX
		JNZ		.BcSrNonAscii
		MOV		AL,DL

		CMP		DWORD [CurPrefixKb],0
		JNE		.TraitPrefix

;***************************************************************************
;-DEB---------- Traitement Normal ------------------------------------------
.NormScan:
		MOV		ECX,[NbNrmKb]
		XOR		EAX,EAX
		MOV		EDI,[TabNrmKb]
		OR		ECX,ECX
		JZ		.PasAddAscii
.BcScanNormKb:
		MOV		EBX,[_KbFLAG]
		TEST		EBX,[EDI+NormKeyb.MaskNo]
		JNZ		.PasScanNormKb

		AND		EBX,[EDI+NormKeyb.MaskYes]
		MOV		EBP,[EDI+NormKeyb.DefActiv]
.BcTestMYes:	TEST		EBX,1
		JZ		.PasIncActiv
		INC		EBP
.PasIncActiv:	SHR		EBX,1
		JNZ		.BcTestMYes
		TEST		EBP,1
		JZ		.PasScanNormKb
.PasTestKbMYes:
		CALL		ScanNormKb
		OR		EAX,EAX
		JNZ		.FinScanNormKb
.PasScanNormKb:
		ADD		EDI,NormKeyb.Size
		DEC		ECX
		JNZ		.BcScanNormKb
.FinScanNormKb:
		OR		EAX,EAX
		JZ		.PasAddAscii
		CALL		AddAsciiCB
		JMP		.PasTraitAscii
.PasAddAscii:
		;--- Test si Bouton Prefix ---------------------------------
		MOV		ECX,[NbPrefixKb]
		MOV		EDI,[TabPrefixKb]
		OR		ECX,ECX
		JZ		.PasTraitAscii
.BcScanPrefix:
		CMP		DL,[EDI+PrefixKeyb.code]
		JNE		.PasTstPrefix
		MOV		EBX,[_KbFLAG]
		TEST		EBX,[EDI+PrefixKeyb.MaskNo]
		JNZ		.PasTstPrefix
		AND		EBX,[EDI+PrefixKeyb.MaskYes]
		MOV		EBP,[EDI+PrefixKeyb.DefActiv]
.BcTestMYes2:	TEST		EBX,1
		JZ		.PasIncActiv2
		INC		EBP
.PasIncActiv2:	SHR		EBX,1
		JNZ		.BcTestMYes2
		TEST		EBP,1
		JZ		.PasTstPrefix
		MOV		[CurPrefixKb],EDI
		JMP		.PasTraitAscii
.PasTstPrefix:
		ADD		EDI,PrefixKeyb.Size
		DEC		ECX
		JNZ		.BcScanPrefix

		JMP		.PasTraitAscii

;-FIN---------- Traitement Normal ------------------------------------------
;***************************************************************************
.TraitPrefix:
;-----------------------------------------------
		XOR		EAX,EAX
		MOV		ESI,[CurPrefixKb]
		MOV		[CurPrefixKb],EAX
		MOV		ECX,[ESI+PrefixKeyb.NbKeybNorm]
		OR		ECX,ECX
		JZ		.PPasAddAscii
		MOV		EDI,[ESI+PrefixKeyb.TabNormKeyb]
		MOV		DH,[ESI+PrefixKeyb.DefaultAscii]
.PBcScanNormKb:
		MOV		EBX,[_KbFLAG]
		TEST		EBX,[EDI+NormKeyb.MaskNo]
		JNZ		.PPasScanNormKb

		AND		EBX,[EDI+NormKeyb.MaskYes]
		MOV		EBP,[EDI+NormKeyb.DefActiv]
.PBcTestMYes:	TEST		EBX,1
		JZ		.PPasIncActiv
		INC		EBP
.PPasIncActiv:	SHR		EBX,1
		JNZ		.PBcTestMYes
		TEST		EBP,1
		JZ		.PPasScanNormKb
.PPasTestKbMYes:
		CALL		ScanNormKb
		OR		EAX,EAX
		JNZ		.PFinScanNormKb
.PPasScanNormKb:
		ADD		EDI,NormKeyb.Size
		DEC		ECX
		JNZ		.PBcScanNormKb
.PFinScanNormKb:
		OR		EAX,EAX
		JZ		.PPasAddAscii
		CALL		AddAsciiCB
		JMP		.PasTraitAscii
.PPasAddAscii:
		;--- Test si Bouton Prefix II-------------------------------
		MOV		ECX,[NbPrefixKb]
		MOV		EDI,[TabPrefixKb]
.BcScanPrefix3:
		CMP		DL,[EDI+PrefixKeyb.code]
		JNE		.PasTstPrefix3
		MOV		EBX,[_KbFLAG]
		TEST		EBX,[EDI+PrefixKeyb.MaskNo]
		JNZ		.PasTstPrefix3
		AND		EBX,[EDI+PrefixKeyb.MaskYes]
		MOV		EBP,[EDI+PrefixKeyb.DefActiv]
.BcTestMYes3:	TEST		EBX,1
		JZ		.PasIncActiv3
		INC		EBP
.PasIncActiv3:	SHR		EBX,1
		JNZ		.BcTestMYes3
		TEST		EBP,1
		JZ		.PasTstPrefix3
		XOR		EAX,EAX
		MOV		AL,DH
		PUSH		EDI
		CALL		AddAsciiCB
		XOR		EAX,EAX
		POP		EDI
		MOV		AL,[EDI+PrefixKeyb.DefaultAscii]
		CALL		AddAsciiCB

		JMP		.PasTraitAscii
.PasTstPrefix3:
		ADD		EDI,PrefixKeyb.Size
		DEC		ECX
		JNZ		.BcScanPrefix3
		; si aucun alors ajout ascii defaut -----------------------
		XOR		EAX,EAX
		MOV		AL,DH
		PUSH		EDX
		CALL		AddAsciiCB
		POP		EDX
		JMP		.NormScan ; et cherche normal ascii -------
;-------------------------------------------------------------------

.PasTraitAscii:	POP		EAX

		RET

;IN  : EDX code butt,EDI Ptr NrmKb
;OUT : EAX Ascii ou 0 ------------

ScanNormKb:
		PUSH		ECX
		PUSH		ESI
		MOV		ECX,[EDI+NormKeyb.NbAscii]
		MOV		ESI,[EDI+NormKeyb.Ptr]
		XOR		EAX,EAX
.BcScan:	LODSW
		CMP		AL,DL
		JE		.TrouvAscii
		DEC		ECX
		JNZ		.BcScan
.PasTrouv:	XOR		EAX,EAX
		POP		ESI
		POP		ECX
		RET		; Pas trouve
.TrouvAscii:	XOR		AL,AL
		MOV		AL,AH
		POP		ESI
		POP		ECX

		RET

;---------------------------------
AddAsciiCB:
		PUSH		EAX
		OR		AL,AL
		JZ		.FinAddAsc
		CMP		DWORD [AsciiNbElt],0
		JE		.TrtFreeCBuff
		MOV		ECX,[AsciiCBFin]
		MOV		EBX,[AsciiNbElt]
		LEA		EDX,[ECX+1]
		MOV		ESI,[_KbFLAG]
		MOV		[AsciiCircBuff+ECX],AL
		MOV		[AsciiKbFLAG+ECX*4],ESI

		AND		EDX,BYTE 0x1f
		CMP		EDX,[AsciiCBDeb]
		JNE		.PasSature


		JMP		SHORT .Sature
.PasSature:	INC		EBX
		MOV		[AsciiCBFin],EDX
		MOV		[AsciiNbElt],EBX
.Sature:
		JMP		SHORT .FinAddAsc
.TrtFreeCBuff:
		MOV		ECX,[AsciiCBDeb]
		XOR		EBX,EBX
		LEA		EDX,[ECX+1]
		MOV		ESI,[_KbFLAG]
		MOV		[AsciiCircBuff+ECX],AL
		MOV		[AsciiKbFLAG+ECX*4],ESI
		AND		EDX,BYTE 0x1f
		OR		EBX,BYTE 1
		MOV		[AsciiCBFin],EDX
		MOV		[AsciiNbElt],EBX
.FinAddAsc:
		POP		EAX
		RET

;-------------------------------------***************************************
;****************************************************************************
;		struc TimedKeyDownEvent
;.Time		resd	1
;.KeyCode	resb	1
;.Size
;		endstruc

TraitTimeKey:
		OR		EAX,EAX
		JZ		.FinTimeTrtKey ; sature
		CMP		DWORD [KeyTimeNbElt],32
		JGE		.FinTimeTrtKey
		MOV		ESI,[_Time]
		MOV		ECX,[KeyTimeCBFin]
		SUB		ESI,[KeyFrstDownTime+EAX*4]
		JZ		.NoKbTime
		MOV		ECX,[KeyTimeCBFin]
		MOV		EBX,[KeyTimeNbElt]
		LEA		EDX,[ECX+1]
		MOV		DWORD [KeyFrstDownTime+EAX*4],ESI
		MOV		[KeyTimeEvents+ECX*4],ESI
		AND		EDX,BYTE 0x1f ; rotate value
		MOV		[KeyTimeKyEvents+ECX],AL
		INC		EBX
		MOV		[KeyTimeCBFin],EDX
		MOV		[KeyTimeNbElt],EBX
		JMP		SHORT .FinTimeTrtKey
.NoKbTime:	MOV		DWORD [KeyFrstDownTime+EAX*4],0
.FinTimeTrtKey:
		RET

TraitKey:
		OR		EAX,EAX
		MOV		EBX,[KeyNbElt]
		JZ		.FinTrtKey
		CMP		EBX,BYTE 32
		JGE		.FinTrtKey ; satured
		MOV		ECX,[KeyCBFin]
		MOV		ESI,[_KbFLAG]
		LEA		EDX,[ECX+1]
		MOV		[KeyCircBuff+ECX],AL
		MOV		[KeyKbFLAG+ECX*4],ESI
		AND		EDX,BYTE 0x1f
		INC		EBX
		MOV		[KeyCBFin],EDX
		MOV		[KeyNbElt],EBX
.FinTrtKey:
		RET
;-------------------------------------
TraitApp:
		PUSH		EAX

		XOR		EDX,EDX
		MOV		DL,AL
		MOV		ECX,[NbKbFLAGLock] ; traite lock ------------
		MOV		ESI,KbFLAGLock
.BcTrtLock:	LODSD
		CMP		EAX,EDX
		JE		.TrouveLock
		DEC		ECX
		LEA		ESI,[ESI+8]
		JNZ		.BcTrtLock
		JMP		SHORT .FinTrtLock
.TrouveLock:	LODSD
		TEST		[_KbFLAG],EAX
		JNZ		.PasInvLock
		LODSD
		XOR		[_KbFLAG],EAX
		CALL		UpDateLEDS
.PasInvLock:
.FinTrtLock:
;--Deb Test INS************--
		MOV		ECX,[NbMskNoYsDefAct]
		MOV		ESI,MskNoYsDefAct

.BcTstIns:
		LEA		ESI,[ECX-1]
		IMUL		ESI,20
		ADD		ESI,MskNoYsDefAct

		LODSD
		CMP		EAX,EDX
		JNE		.PasTstIns
		MOV		EBX,[_KbFLAG]
		LODSD
		TEST		EBX,EAX   ; MaskNo
		JNZ		.PasTstIns
		LODSD
		AND		EBX,EAX   ; MaskYes
		LODSD
		MOV		EBP,EAX   ; DefActiv
.PBcTestMYes:	TEST		EBX,1
		JZ		.PPasIncActiv
		INC		EBP
.PPasIncActiv:	SHR		EBX,1
		JNZ		.PBcTestMYes
		LODSD
		TEST		EBP,1
		JZ		.FinTstIns
		XOR		[_KbFLAG],EAX
.PasInvIns:	JMP		SHORT .FinTstIns
.PasTstIns:	DEC		ECX
		JNZ		.BcTstIns
.FinTstIns:
;--Fin Test INS************--
		MOV		ECX,[NbKbFLAGAppScan] ; traite Norm ---------
		MOV		ESI,KbFLAGAppScan
.BcTrtNorm:	LODSD
		CMP		EAX,EDX
		JE		.TrouveNorm
		DEC		ECX
		LEA		ESI,[ESI+4]
		JNZ		.BcTrtNorm
		JMP		SHORT .FinTrtNorm
.TrouveNorm:
		LODSD
		OR		[_KbFLAG],EAX
		DEC		ECX
		JNZ		.BcTrtNorm
.FinTrtNorm:
		POP		EAX
		RET

WaitKbBuffEmpty:
.BcWait:	IN		AL,0x64
		TEST		AL,2
		JNZ		.BcWait
		RET

UpDateLEDS:
		CALL		WaitKbBuffEmpty
		MOV		AL,0xed
		OUT		0x60,AL
		MOV		BL,[_KbFLAG]
		SHR		BL,4
		AND		BL,7
		CALL		WaitKbBuffEmpty
		MOV		AL,BL
		OUT		0x60,AL
		RET

TraitRel:
		XOR		EDX,EDX
		MOV		DL,AL
		MOV		ECX,[NbKbFLAGSpRel] ; traite Sp -------------
		MOV		ESI,KbFLAGSpRel
.BcTrtSp:	LODSD
		CMP		EAX,EDX
		JE		.TrouveSp
		DEC		ECX
		LEA		ESI,[ESI+8]
		JNZ		.BcTrtSp
		JMP		SHORT .FinTrtSp
.TrouveSp:	LODSD
		TEST		[_KbFLAG],EAX
		JNZ		.PasDesacSp
		LODSD
		AND		[_KbFLAG],EAX
.PasDesacSp:
.FinTrtSp:	MOV		ECX,[NbKbFLAGRel] ; traite Norm -------------
		MOV		ESI,KbFLAGRel
.BcTrtNorm:	LODSD
		CMP		EAX,EDX
		JE		.TrouveNorm
		DEC		ECX
		LEA		ESI,[ESI+4]
		JNZ		.BcTrtNorm
		JMP		SHORT .FinTrtNorm
.TrouveNorm:	LODSD
		AND		[_KbFLAG],EAX
		DEC		ECX
		JNZ		.BcTrtNorm
.FinTrtNorm:

		RET

FinKbLockCode:;****************************************************************

SECTION	.data
ALIGN 32
_V_EDI		DD	0      	;00H      4       DI or EDI
_V_ESI		DD	0	;04H      4       SI or ESI
_V_EBP		DD	0	;08H      4       BP or EBP
_V_RES		DD	0	;0CH      4       reserved, should be zero
_V_EBX		DD	0	;10H      4       BX or EBX
_V_EDX		DD	0	;14H      4       DX or EDX
_V_ECX		DD	0	;18H      4       CX or ECX
_V_EAX		DD	0	;1CH      4       AX or EAX
_V_CPU_STATUS	DW	0       ;20H      2       CPU status flags
_V_ES		DW	0       ;22H      2       ES
_V_DS		DW	0       ;24H      2       DS
_V_FS		DW	0       ;26H      2       FS
_V_GS		DW	0       ;28H      2       GS
_V_IP		DW	0       ;2AH      2       IP (reserved, ignored)
_V_CS		DW	0       ;2CH      2       CS (reserved, ignored)
_V_SP		DW	0       ;2EH      2       SP
_V_SS		DW	0	;30H      2       SS
;****************************************************************************
ALIGN 4
DSBaseAddress	DD	0
;*** TIMER
DebTmLockData:;---------------------
OldHdTmOff	DD	0
OldHdTmSeg	DD	0
CptOldTimer	DD	0
CptOldTimer2	DD	0
CptOldTimer3	DD	0
TimerAddCpt	DD	0
_Time		DD	0
_TimerFreq	DD	0
_TimerTickVal	DD	0
RestTimerTick   DD      0
TmMyDSSelector	DW	0
TmRound		DW	0
FinTmLockData:;---------------------
;*** MOUSE
SegMsCallBack	DD	0
OffMsCallBack	DD	0

DebMsLockData:;--------------
OldCptMsTm18	DD	0
OldCptAccel	DD	0
MsCurSpeedVt	DD	0
MsCurSpeedHz	DD	0
MsMyDSSelector	DD	0

VMsH_EDI	DD	0      	;00H      4       DI or EDI
VMsH_ESI	DD	0	;04H      4       SI or ESI
VMsH_EBP	DD	0	;08H      4       BP or EBP
VMsH_RES	DD	0	;0CH      4       reserved, should be zero
VMsH_EBX	DD	0	;10H      4       BX or EBX
VMsH_EDX	DD	0	;14H      4       DX or EDX
VMsH_ECX	DD	0	;18H      4       CX or ECX
VMsH_EAX	DD	0	;1CH      4       AX or EAX
VMsH_CPU_STATUS	DW	0	;20H      2       CPU status flags
VMsH_ES		DW	0	;22H      2       ES
VMsH_DS		DW	0	;24H      2       DS
VMsH_FS		DW	0	;26H      2       FS
VMsH_GS		DW	0	;28H      2       GS
VMsH_IP		DW	0	;2AH      2       IP (reserved, ignored)
VMsH_CS		DW	0	;2CH      2       CS (reserved, ignored)
VMsH_SP		DW	0	;2EH      2       SP
VMsH_SS		DW	0	;30H      2       SS
;*****************************************************************************
ALIGN 4
_MsX		DD	0
_MsY		DD	0
_MsZ		DD	0
_MsButton	DD	0
_MsSpeedHz	DD	0
_MsSpeedVt	DD	0
_MsAccel	DD	0
MsMickeyX	DD	0
MsMickeyY	DD	0
MsRestMickeyX	DD	0
MsRestMickeyY	DD	0
MsFirstInt	DD	0
MsOrgX		DD	0
MsOrgY		DD	0
MsMaxX		DD	0
MsMaxY		DD	0
MsMinX		DD	0
MsMinY		DD	0
MsEventsStack	TIMES 	MouseEvent.Size*256 DB 0
MsStackStart	DD	0
MsStackNbElt	DD	0
MsStackEnable	DD	0
MsWheelSupp	DD	0

FinMsLockData:;---------------------
;*** KEYBOARD
DebKbLockData:;---------------------
; test KbFLAG avec 2em val si zero alors inverse etat avec XOR 3em VAL
NbKbFLAGLock	DD	3
KbFLAGLock:	DD	0x46,0x1000,0x10       	;SCROLL_ACT
		DD	0x45,0x2000,0x20	;NUM_ACT
		DD	0x3a,0x4000,0x40	;CAPS_ACT
; 2‚ Mask Yes, 3‚ Mask No, 4‚ Def Activ
NbMskNoYsDefAct	DD	2
MskNoYsDefAct:	DD	0xd2,0x0000800C,0x80000000,1,0x80 ;INS_ACT
		DD	0x52,0x0080800C,0x80000020,1,0x80 ;PAD_INS_ACT

NbKbFLAGAppScan	DD	30
KbFLAGAppScan:	DD	0x36,0x00000001,    0x2a,0x00000002; RG_SH, LF_SH
		DD	0x1d,0x00000004,    0x9d,0x00000004; CTRL
		DD	0x38,0x00000008,    0xb8,0x00000008; ALT
		DD	0x1d,0x00000100,    0x38,0x00000200; LF_CTRL,LF_ALT
		DD	0xb7,0x00000400 		   ; SYS_REQ
		DD	0x46,0x00001000,    0x45,0x00002000; SCR, NUM
		DD	0x3a,0x00004000,    0xd2,0x00008000; CAPS, INS
		DD	0x0f,0x00010000,    0x1c,0x00020000; TAB, ENTER
		DD	0x39,0x00040000,    0xc8,0x00080000; SPACE, UP
		DD	0xd0,0x00100000,    0xcd,0x00200000; DOWN, RIGHT
		DD	0xcb,0x00400000,    0x52,0x00800000; LEFT, PAD_INS
		DD	0x9d,0x01000000,    0xb8,0x02000000; RG_CTR, RG_ALT
		DD	0xc9,0x04000000,    0xd1,0x08000000; PG_UP, PG_DWN
		DD	0xc7,0x10000000,    0xcf,0x20000000; BEG, END
		DD	0xd3,0x40000000 		   ; SUPP
		DD	0x36,0x80000000,    0x2a,0x80000000; SHIFT

; test KbFLAG avec 2em val si zero alors desactive bit avec AND 3em VAL
NbKbFLAGSpRel	DD	6
KbFLAGSpRel:	DD	0x1d,0x1000000,~0x4       	;LF_CTRL
		DD	0x38,0x2000000,~0x8		;LF_ALT
		DD	0x9d,0x100,~0x4			;RG_CTRL
		DD	0xb8,0x200,~0x8			;RG_ALT
		DD	0x36,0x2,~(0x80000000)		;LF_SH
		DD	0x2a,0x1,~0x80000000		;RG_SH

NbKbFLAGRel	DD	25
KbFLAGRel:	DD	0x36,~0x00000001,    0x2a,~0x00000002 ;RG_SH, LF_SH
		DD	0x1d,~0x00000100,    0x38,~0x00000200; LF_CTRL,LF_ALT
		DD	0xb7,~0x00000400 		     ; SYS_REQ
		DD	0x46,~0x00001000,    0x45,~0x00002000; SCR, NUM
		DD	0x3a,~0x00004000,    0xd2,~0x00008000; CAPS, INS
		DD	0x0f,~0x00010000,    0x1c,~0x00020000; TAB, ENTER
		DD	0x39,~0x00040000,    0xc8,~0x00080000; SPACE, UP
		DD	0xd0,~0x00100000,    0xcd,~0x00200000; DOWN, RIGHT
		DD	0xcb,~0x00400000,    0x52,~0x00800000; LEFT, PAD_INS
		DD	0x9d,~0x01000000,    0xb8,~0x02000000; RG_CTR, RG_ALT
		DD	0xc9,~0x04000000,    0xd1,~0x08000000; PG_UP, PG_DWN
		DD	0xc7,~0x10000000,    0xcf,~0x20000000; BEG, END
		DD	0xd3,~0x40000000,    0x0e,~0x80000000; SUPP, BACK

NbKbNonAscii	DD	14
TbNonAscii:	DB	0x36,0x2a,0x1d,0x38, 0xb7,0x46,0x45,0x3a
		DB	0xd2,0x9d,0xb8,0xdb, 0xdc,0xdd,0,0

OldHdKbOff	DD	0
OldHdKbSeg	DD	0
SelBiosDatArea	DD	0

_CurKbMAP:		 ;-----------------------
SignKb		DD	0; == 'KMAP'
SizeKb		DD	0
KbMapPtr	DD	0
NbPrefixKb	DD	0
TabPrefixKb	DD	0
NbNrmPrefixKb	DD	0
TabNrmPrefixKb	DD	0
NbNrmKb		DD	0
TabNrmKb	DD	0
resv2Kb		DD	0,0,0
CurPrefixKb	DD	0
ValidCurKbMAP	DD	0
resvKb		DD	0,0;-------------------
_KbFLAG		DD	0
_KbApp		DD	0,0,0,0,0,0,0,0
KeyFrstDownTime	TIMES	256	DD	0
KeyTimeEvents	TIMES 	32 	DD	0
KeyTimeKyEvents	TIMES 	32 	DB	0
AsciiCircBuff	DD	0,0,0,0,0,0,0,0
AsciiKbFLAG:	DD	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		DD	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
KeyCircBuff	DD	0,0,0,0,0,0,0,0
KeyKbFLAG:	DD	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		DD	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
AsciiCBDeb	DD	0
AsciiCBFin	DD	0
KeyCBDeb	DD	0
KeyCBFin	DD	0
KeyTimeCBDeb	DD	0
KeyTimeCBFin	DD	0
AsciiNbElt	DD	0
KeyNbElt	DD	0
KeyTimeNbElt	DD	0

_LastKey	DB	0
_LastAscii	DB	0
ScanAscii	DB	0
ExtKey		DB	0
PauseKey	DB	0
PausePressed	DB	0
KbMyDSSelector	DW	0
KeyPressed	DB	0
KeyFLAG		DB	0
KeyAlignMem	DW	0
FinKbLockData:;---------------------

