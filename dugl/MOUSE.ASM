%include "param.mac"

; GLOBAL Function*************************************************************
;*** Mouse
GLOBAL _InstallMouse,_UninstallMouse,_SetMouseView,_GetMouseFView
GLOBAL _SetMouseOrg,_SetMousePos,_SetMouseSpeed,_SetMouseAccel,_IsMouseWheelSupported
GLOBAL _EnableMsEvntsStack,_DisableMsEvntsStack,ClearMsEvntsStack,_GetMsEvent

; GLOBAL DATA*****************************************************************
;*** Mouse
GLOBAL _MsX,_MsY,_MsZ,_MsButton,_MsSpeedHz,_MsSpeedVt,_MsAccel


SECTION .text
ALIGN 32
[BITS 32]
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

_SetMouseView:
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

_GetMouseView:
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
.Size:
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


SECTION	.data
ALIGN 32
_V_EDI			DD	0      	;00H      4       DI or EDI
_V_ESI			DD	0	;04H      4       SI or ESI
_V_EBP			DD	0	;08H      4       BP or EBP
_V_RES			DD	0	;0CH      4       reserved, should be zero
_V_EBX			DD	0	;10H      4       BX or EBX
_V_EDX			DD	0	;14H      4       DX or EDX
_V_ECX			DD	0	;18H      4       CX or ECX
_V_EAX			DD	0	;1CH      4       AX or EAX
_V_CPU_STATUS	DW	0       ;20H      2       CPU status flags
_V_ES			DW	0       ;22H      2       ES
_V_DS			DW	0       ;24H      2       DS
_V_FS			DW	0       ;26H      2       FS
_V_GS			DW	0       ;28H      2       GS
_V_IP			DW	0       ;2AH      2       IP (reserved, ignored)
_V_CS			DW	0       ;2CH      2       CS (reserved, ignored)
_V_SP			DW	0       ;2EH      2       SP
_V_SS			DW	0	;30H      2       SS
;****************************************************************************
tmp1Align		DW  0
DSBaseAddress	DD	0
;*** MOUSE
SegMsCallBack	DD	0
OffMsCallBack	DD	0

DebMsLockData:;--------------
OldCptMsTm18	DD	0
OldCptAccel		DD	0
MsCurSpeedVt	DD	0
MsCurSpeedHz	DD	0
MsMyDSSelector	DD	0

VMsH_EDI		DD	0      	;00H      4       DI or EDI
VMsH_ESI		DD	0	;04H      4       SI or ESI
VMsH_EBP		DD	0	;08H      4       BP or EBP
VMsH_RES		DD	0	;0CH      4       reserved, should be zero
VMsH_EBX		DD	0	;10H      4       BX or EBX
VMsH_EDX		DD	0	;14H      4       DX or EDX
VMsH_ECX		DD	0	;18H      4       CX or ECX
VMsH_EAX		DD	0	;1CH      4       AX or EAX
VMsH_CPU_STATUS	DW	0	;20H      2       CPU status flags
VMsH_ES			DW	0	;22H      2       ES
VMsH_DS			DW	0	;24H      2       DS
VMsH_FS			DW	0	;26H      2       FS
VMsH_GS			DW	0	;28H      2       GS
VMsH_IP			DW	0	;2AH      2       IP (reserved, ignored)
VMsH_CS			DW	0	;2CH      2       CS (reserved, ignored)
VMsH_SP			DW	0	;2EH      2       SP
VMsH_SS			DW	0	;30H      2       SS
;*****************************************************************************
tmp2Align		DW  0
_MsX			DD	0
_MsY			DD	0
_MsZ			DD	0
_MsButton		DD	0
_MsSpeedHz		DD	0
_MsSpeedVt		DD	0
_MsAccel		DD	0
MsMickeyX		DD	0
MsMickeyY		DD	0
MsRestMickeyX	DD	0
MsRestMickeyY	DD	0
MsFirstInt		DD	0
MsOrgX			DD	0
MsOrgY			DD	0
MsMaxX			DD	0
MsMaxY			DD	0
MsMinX			DD	0
MsMinY			DD	0
MsEventsStack	TIMES 	MouseEvent.Size*256 DB 0
MsStackStart	DD	0
MsStackNbElt	DD	0
MsStackEnable	DD	0
MsWheelSupp		DD	0

FinMsLockData:;---------------------
