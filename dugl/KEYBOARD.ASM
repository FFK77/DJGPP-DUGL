%include "param.mac"

; GLOBAL Function*************************************************************
;*** Keyboard
GLOBAL _InstallKeyboard,_UninstallKeyboard,_IsKeyDown,_PauseKeyPressed
GLOBAL _WaitKeyPressed,_SetKeybRateDelay,_GetKey,_WaitGetKey
GLOBAL _SetKbMAP,_GetKbMAP,_DisableCurKbMAP,_GetAscii,_WaitGetAscii
GLOBAL _GetKeyNbElt,_ClearKeyCircBuff,_GetAsciiNbElt,_ClearAsciiCircBuff
GLOBAL _GetCurrTimeKeyDown,_GetTimedKeyDown,_GetTimedKeyNbElt,_ClearTimedKeyCircBuff

; GLOBAL DATA*****************************************************************
;*** Keyboard
GLOBAL _KbFLAG,_KbApp,_LastKey,_LastAscii,_CurKbMAP

; EXTERN DATA

EXTERN _DgTime

;EXTERN

SECTION .text
ALIGN 32
[BITS 32]
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
		MOV		EAX,[_DgTime]
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
		MOV		EDX,[_DgTime]
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
		MOV		EDX,[_DgTime]
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
.Size:
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
.Size:
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
		MOV		ESI,[_DgTime]
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
;*** KEYBOARD
DebKbLockData:;---------------------
; test KbFLAG avec 2em val si zero alors inverse etat avec XOR 3em VAL
NbKbFLAGLock	DD	3
KbFLAGLock:		DD	0x46,0x1000,0x10       	;SCROLL_ACT
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

NbKbFLAGRel		DD	25
KbFLAGRel:		DD	0x36,~0x00000001,    0x2a,~0x00000002 ;RG_SH, LF_SH
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
TbNonAscii:		DB	0x36,0x2a,0x1d,0x38, 0xb7,0x46,0x45,0x3a
				DB	0xd2,0x9d,0xb8,0xdb, 0xdc,0xdd,0,0

OldHdKbOff		DD	0
OldHdKbSeg		DD	0
SelBiosDatArea	DD	0

_CurKbMAP:		 ;-----------------------
SignKb			DD	0; == 'KMAP'
SizeKb			DD	0
KbMapPtr		DD	0
NbPrefixKb		DD	0
TabPrefixKb		DD	0
NbNrmPrefixKb	DD	0
TabNrmPrefixKb	DD	0
NbNrmKb			DD	0
TabNrmKb		DD	0
resv2Kb			DD	0,0,0
CurPrefixKb		DD	0
ValidCurKbMAP	DD	0
resvKb			DD	0,0;-------------------
_KbFLAG			DD	0
_KbApp			DD	0,0,0,0,0,0,0,0
KeyFrstDownTime	TIMES	256	DD	0
KeyTimeEvents	TIMES 	32 	DD	0
KeyTimeKyEvents	TIMES 	32 	DB	0
AsciiCircBuff	DD	0,0,0,0,0,0,0,0
AsciiKbFLAG:	DD	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
				DD	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
KeyCircBuff		DD	0,0,0,0,0,0,0,0
KeyKbFLAG:		DD	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
				DD	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
AsciiCBDeb		DD	0
AsciiCBFin		DD	0
KeyCBDeb		DD	0
KeyCBFin		DD	0
KeyTimeCBDeb	DD	0
KeyTimeCBFin	DD	0
AsciiNbElt		DD	0
KeyNbElt		DD	0
KeyTimeNbElt	DD	0

_LastKey		DB	0
_LastAscii		DB	0
ScanAscii		DB	0
ExtKey			DB	0
PauseKey		DB	0
PausePressed	DB	0
KbMyDSSelector	DW	0
KeyPressed		DB	0
KeyFLAG			DB	0
KeyAlignMem		DW	0
FinKbLockData:;---------------------
DSBaseAddress	DD	0
