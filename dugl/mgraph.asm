%include "param.mac"
%include "hzline16.asm"

; GLOBAL Function****
; 8bpp
GLOBAL	_SetMSurf,_SetSrcMSurf,_GetMSurf,_MSetDeltaOrgX
GLOBAL	_MSetVectX,_MSetVectY,_MSetVectZ,_MSetVectCol,_MSetCol
GLOBAL	_MPutPixels16,_MCPutPixels16,_MPtrPutPixels16,_MPtrCPutPixels16
GLOBAL	_MLinesList16,_MLinesStrip16,_MPtrLinesList16,_MPtrLinesStrip16
GLOBAL	_MPtrTrisList16

; GLOBAL DATA
GLOBAL	_CurMSurf, _CurMSrcSurf
GLOBAL	_Mvlfb, _MOffVMem, _MResH, _MResV, _MMaxX, _MMaxY, _MMinX, _MMinY
GLOBAL	_MOrgX, _MOrgY, _Mrlfb, _MSizeSurf, _MRMaxX, _MRMaxY, _MRMinX, _MRMinY


; EXTERN DATA
EXTERN	_MTPolyAdDeb, _MTPolyAdFin, _MTSurfAdDeb, _MTSrcSurfAdDeb
EXTERN	_MTexXDeb, _MTexXFin, _MTexYDeb, _MTexYFin
EXTERN	_MPColDeb, _MPColFin
; --GIF------
EXTERN	_Prefix, _Suffix, _DStack
Prec		EQU	12
MaxResV		EQU	2048
BlendMask	EQU	0x1f
SurfUtilSize    EQU     80
MaxDeltaDim	EQU	1<< (31-Prec)
DBL_SIDED_MASK	EQU	1


SECTION .text
[BITS 32]
ALIGN 32

; param ESI: source Surf, EDI: Dest Surf
; use mm0, ... , mm7
; return : ECX = ResV
%macro	CopyMSurf	0
		OR		ESI,ESI
		JZ		%%NoCopySurf
		MOVQ		mm0,[ESI]
		MOVQ		mm1,[ESI+32]
		MOVQ		mm2,[ESI+8]
		MOVQ		mm3,[ESI+40]
		MOVQ		mm4,[ESI+16]
		MOVQ		mm5,[ESI+48]
		MOVQ		mm6,[ESI+24]
		MOVQ		mm7,[ESI+56]

		MOVQ		[EDI],mm0
		MOVQ		[EDI+40],mm3
		MOVQ		[EDI+8],mm2
		MOVD		ECX,mm2
		MOVQ		[EDI+32],mm1
		MOVQ		mm0,[ESI+64]
		MOVQ		mm1,[ESI+72]
		MOVQ		[EDI+16],mm4
		MOVQ		[EDI+48],mm5
		MOVQ		[EDI+24],mm6
		MOVQ		[EDI+56],mm7
		MOVQ		[EDI+64],mm0
		MOVQ		[EDI+72],mm1
%%NoCopySurf:
%endmacro


ALIGN 32
_SetMSurf:
	ARG	S1, 4

		PUSH		EDI
		PUSH	        ESI
		PUSH		EBX

		MOV		ESI,[EBP+S1]
		MOV		EAX,[ESI+_MResV-_CurMSurf]
		CMP		EAX,MaxResV
		JG		.Error
		MOV		EDI,_CurMSurf
                CopyMSurf
		; fill _MTSurfAdDeb
		MOV		ESI,ECX;**
		MOV		EBX,ECX ; = [_MResV]
		AND		ESI, BYTE 0x3;**
		MOV		EAX,[_Mrlfb]
		MOV		EDI,[_MOrgX]
		;-- add OrgX
		CMP		BYTE [_MBitsPixel],16
		JE		SHORT .bpp16
		CMP		BYTE [_MBitsPixel],15
		JE		SHORT .bpp16
		CMP		BYTE [_MBitsPixel],32
		JE		SHORT .bpp32
		LEA		EAX,[EAX+EDI]
		JMP		SHORT .endbpp

.bpp16: 	LEA		EAX,[EAX+EDI*2]
		JMP		SHORT .endbpp
.bpp32: 	LEA		EAX,[EAX+EDI*4]
.endbpp:
		MOV		EDX,[_MScanLine]
		JZ		SHORT .Aligned4
		XOR		ESI,BYTE 0x3
		INC		ESI
		ADD		EBX,ESI
		IMUL		ESI,EDX
.Aligned4:
		SUB		EAX,ESI
		MOVD		mm1,EDX
		MOVD		mm2,EAX  ; aligned rlfb
		PUNPCKLDQ	mm1,mm1  ; [_MScanLine] | [_MScanLine]
		ADD		EAX,EDX ; = aligned rlfb + [_MScanLine]
		MOV		ECX,EBX ; = ALIGN4(_MResV)
		;PSLLD		mm1,1   ; = [_MScanLine] * 2 | [_MScanLine] * 2
		PADDD		mm1,mm1
		MOVD		mm0,EAX
		SHR		ECX,2
		MOV		EDI,_MTSurfAdDeb
		MOV		EAX,4
		PUNPCKLDQ	mm0,mm2  ;
		MOVQ		mm3,mm0
		SUB		EBX,EAX ; = [ALIGN4(_MResV) - 4]
		PADDD		mm3,mm1
		;PSLLD		mm1,1   ; = [_MScanLine] * 4 | [_MScanLine] * 4
		PADDD		mm1,mm1
		NEG		EAX
ALIGN 4
.BcFillDeb:
		MOVQ		[EDI+EBX*4],mm3
		MOVQ		[EDI+EBX*4+8],mm0
		DEC		ECX
		PADDD		mm3,mm1
		PADDD		mm0,mm1
		LEA		EBX,[EBX+EAX] ; -=4
		JNZ		SHORT .BcFillDeb

		OR		EAX,BYTE -1
		JMP		SHORT .Ok
.Error:		XOR		EAX,EAX
.Ok:
		POP		EBX
		POP		ESI
		POP             EDI
		RETURN

ALIGN 32
_SetSrcMSurf:
	ARG	SS1, 4

		PUSH		EDI
		PUSH	        ESI
		PUSH		EBX

		MOV		ESI,[EBP+SS1]
		MOV		EAX,[ESI+_MResV-_CurMSurf]
		CMP		EAX,MaxResV
		JG		.Error
		MOV		EDI,_CurMSrcSurf
                CopyMSurf
		; fill _MTSurfAdDeb
		MOV		ESI,ECX;**
		MOV		EBX,ECX ; = [MSResV]
		AND		ESI, BYTE 0x3;**
		MOV		EAX,[MSrlfb]
		MOV		EDI,[MSOrgX]
		;-- add OrgX
		CMP		BYTE [MSBitsPixel],16
		JE		SHORT .bpp16
		CMP		BYTE [MSBitsPixel],15
		JE		SHORT .bpp16
		CMP		BYTE [MSBitsPixel],32
		JE		SHORT .bpp32
		LEA		EAX,[EAX+EDI]
		JMP		SHORT .endbpp

.bpp16: 	LEA		EAX,[EAX+EDI*2]
		JMP		SHORT .endbpp
.bpp32: 	LEA		EAX,[EAX+EDI*4]
.endbpp:
		
		MOV		EDX,[MSScanLine]
		JZ		SHORT .Aligned4
		XOR		ESI,BYTE 0x3
		INC		ESI
		ADD		EBX,ESI
		IMUL		ESI,EDX
.Aligned4:
		SUB		EAX,ESI
		MOVD		mm1,EDX
		MOVD		mm2,EAX  ; aligned rlfb
		PUNPCKLDQ	mm1,mm1  ; [_MScanLine] | [_MScanLine]
		ADD		EAX,EDX ; = aligned rlfb + [_MScanLine]
		MOV		ECX,EBX ; = ALIGN4(_MResV)
		;PSLLD		mm1,1   ; = [_MScanLine] * 2 | [_MScanLine] * 2
		PADDD		mm1,mm1
		MOVD		mm0,EAX
		SHR		ECX,2
		MOV		EDI,_MTSrcSurfAdDeb
		MOV		EAX,4
		PUNPCKLDQ	mm0,mm2  ;
		MOVQ		mm3,mm0
		SUB		EBX,EAX ; = [ALIGN4(_MResV) - 4]
		PADDD		mm3,mm1
		;PSLLD		mm1,1   ; = [_MScanLine] * 4 | [_MScanLine] * 4
		PADDD		mm1,mm1
		NEG		EAX
ALIGN 4
.BcFillDeb:
		MOVQ		[EDI+EBX*4],mm3
		MOVQ		[EDI+EBX*4+8],mm0
		DEC		ECX
		PADDD		mm3,mm1
		PADDD		mm0,mm1
		LEA		EBX,[EBX+EAX] ; EBX -= 4
		JNZ		SHORT .BcFillDeb

		OR		EAX,BYTE -1
		JMP		SHORT .Ok
.Error:		XOR		EAX,EAX
.Ok:
		POP		EBX
		POP		ESI
		POP             EDI
		RETURN

_MSetDeltaOrgX:
	ARG	PIdMSurf, 4, PDeltaOrgX, 4

		XOR		EAX,EAX
		OR		EAX,[EBP+PIdMSurf]
		JZ		SHORT .IsCurMSrf
.IsCurMSrcSrf:	MOV		ECX,_CurMSrcSurf
		MOV		EDX,_MTSrcSurfAdDeb
		JMP		SHORT .EndIsSurf
.IsCurMSrf:	MOV		ECX,_CurMSurf
		MOV		EDX,_MTSurfAdDeb
.EndIsSurf:
		MOV		EAX,[ECX+_MResV-_CurMSurf]
		MOV		EBP,[EBP+PDeltaOrgX]
		OR		EAX,EAX
		JZ		.EndDeltaOrgX
		CMP		BYTE [ECX+_MBitsPixel-_CurMSurf],16
		JE		SHORT .bpp16
		CMP		BYTE [ECX+_MBitsPixel-_CurMSurf],15
		JE		SHORT .bpp16
		CMP		BYTE [ECX+_MBitsPixel-_CurMSurf],32
		JE		SHORT .bpp32
		JMP		SHORT .endbpp

.bpp16:		ADD		EBP,EBP
		JMP		SHORT .endbpp
.bpp32:		SHL		EBP,2
.endbpp:

		TEST		AL,BYTE 0x1
		JZ		SHORT .NoAlign2
		INC		EAX
.NoAlign2:
		SHR		EAX,1
		XOR		ECX,ECX
ALIGN 4
.BcDeltaOrgX:	ADD		[EDX+ECX],EBP
		ADD		[EDX+ECX+4],EBP
		DEC		EAX
		LEA		ECX,[ECX+8]
		JNZ		SHORT .BcDeltaOrgX
.EndDeltaOrgX:
		RETURN

ALIGN 32
_MSetVectX:
	ARG	PpVectX, 4, PVectXPlus, 4

		MOV		EDX,[EBP+PpVectX]
		MOV		EAX,[EBP+PVectXPlus]
		MOV		[MpVectX],EDX
		MOV		[MVectXPlus],EAX
		RETURN

ALIGN 32
_MSetVectY:
	ARG	PpVectY, 4, PVectYPlus, 4

		MOV		EDX,[EBP+PpVectY]
		MOV		EAX,[EBP+PVectYPlus]
		MOV		[MpVectY],EDX
		MOV		[MVectYPlus],EAX
		RETURN

ALIGN 32
_MSetVectZ:
	ARG	PpVectZ, 4, PVectZPlus, 4

		MOV		EDX,[EBP+PpVectZ]
		MOV		EAX,[EBP+PVectZPlus]
		MOV		[MpVectY],EDX
		MOV		[MVectYPlus],EAX
		RETURN

ALIGN 32
_MSetVectCol:
	ARG	PpVectCol, 4, PVectColPlus, 4

		MOV		EDX,[EBP+PpVectCol]
		MOV		EAX,[EBP+PVectColPlus]
		MOV		[MpVectCol],EDX
		MOV		[MVectColPlus],EAX
		RETURN

ALIGN 32
_MSetCol:
	ARG	PMCol, 4

		MOV		EAX,[EBP+PMCol]
		MOV		[MCurCol],EAX
		RETURN
		
ALIGN 32
_MPutPixels16:
	ARG	PMPixelsCount, 4
		PUSH		EBX
		PUSH		EDI
		PUSH	        ESI

		MOV		EBX,[EBP+PMPixelsCount]
		MOV		EDI,[MpVectY]
		MOV		EBP,[MpVectCol]
		MOV		ESI,[MpVectX]
		OR		EBP,EBP
		JZ		SHORT .NoVectCol
ALIGN 4
.BcVC_PPs:
		MOV		EDX,[EDI]
		MOV		ECX,[ESI]
		MOV		AX,[EBP]
		ADD		EDI,[MVectYPlus]
		ADD		EDX,[_MOrgY]
		ADD		ESI,[MVectXPlus]
		MOV		EDX,[_MTSurfAdDeb+EDX*4]
		ADD		EBP,[MVectColPlus]
		DEC		EBX
		MOV		[EDX+ECX*2],AX
		JNZ		SHORT .BcVC_PPs
		JMP		SHORT .EndPPixels
.NoVectCol:
		MOV		EBP,[_MOrgY]
		MOV		EAX,[MCurCol]
		SHL		EBP,2
ALIGN 4
.BcNVC_PPs:	MOV		EDX,[EDI]
		MOV		ECX,[ESI]
		ADD		EDI,[MVectYPlus]
		ADD		ESI,[MVectXPlus]
		MOV		EDX,[_MTSurfAdDeb+EDX*4+EBP]
		DEC		EBX
		MOV		[EDX+ECX*2],AX
		JNZ		SHORT .BcNVC_PPs
.EndPPixels:
		POP		ESI
		POP             EDI
		POP		EBX
		RETURN

ALIGN 32
_MPtrPutPixels16:
	ARG	TPtrVP, 4, PMPPixelsCount, 4
		PUSH		EBX
		PUSH		EDI
		PUSH	        ESI

		MOV		ESI,[EBP+TPtrVP]
		MOV		EBX,[EBP+PMPPixelsCount]
		MOV		EBP,[_MOrgY]
		SHL		EBP,2
ALIGN 4
.BcVC_PPs:
		MOV		EDI,[ESI]
		MOV		EDX,[MVectYPlus]
		MOV		ECX,[MVectXPlus]
		MOV		EAX,[MVectColPlus]
		MOV		EDX,[EDI+EDX]
		MOV		ECX,[EDI+ECX]
		MOV		AX,[EDI+EAX]
		MOV		EDX,[_MTSurfAdDeb+EDX*4+EBP]
		DEC		EBX
		LEA		ESI,[ESI+4]
		MOV		[EDX+ECX*2],AX
		JNZ		SHORT .BcVC_PPs
		
		POP		ESI
		POP             EDI
		POP		EBX
		RETURN

ALIGN 32
_MPtrCPutPixels16:
	ARG	TPtrVCP, 4, PMPCPixelsCount, 4
		PUSH		EBX
		PUSH		EDI
		PUSH	        ESI

		MOV		ESI,[EBP+TPtrVCP]
		MOV		EBX,[EBP+PMPCPixelsCount]
		MOV		EBP,[_MOrgY]
		SHL		EBP,2
ALIGN 4
.BcVC_PPs:
		MOV		EDI,[ESI]
		MOV		EDX,[MVectYPlus]
		MOV		ECX,[MVectXPlus]
		MOV		EDX,[EDI+EDX]
		MOV		ECX,[EDI+ECX]
		MOV		EAX,[MVectColPlus]
		; clip
		CMP		EDX,[_MMaxY]
		JG		SHORT .NoVC
		CMP		ECX,[_MMaxX]
		JG		SHORT .NoVC
		CMP		EDX,[_MMinY]
		JL		SHORT .NoVC
		CMP		ECX,[_MMinX]
		JL		SHORT .NoVC

		MOV		AX,[EDI+EAX]
		MOV		EDX,[_MTSurfAdDeb+EDX*4+EBP]
		MOV		[EDX+ECX*2],AX
.NoVC:		DEC		EBX
		LEA		ESI,[ESI+4]
		JNZ		SHORT .BcVC_PPs
		
		POP		ESI
		POP             EDI
		POP		EBX
		RETURN


ALIGN 32
_MCPutPixels16:
	ARG	PMCPixelsCount, 4
		PUSH		EBX
		PUSH		EDI
		PUSH	        ESI

		MOV		EBX,[EBP+PMPixelsCount]
		MOV		EDI,[MpVectY]
		MOV		EBP,[MpVectCol]
		MOV		ESI,[MpVectX]
		OR		EBP,EBP
		JZ		SHORT .NoVectCol
ALIGN 4
.BcVC_PPs:	MOV		EDX,[EDI]
		MOV		ECX,[ESI]
		ADD		EDI,[MVectYPlus]
		ADD		ESI,[MVectXPlus]
		; clip
		CMP		EDX,[_MMaxY]
		JG		SHORT .NoVC
		CMP		ECX,[_MMaxX]
		JG		SHORT .NoVC
		CMP		EDX,[_MMinY]
		JL		SHORT .NoVC
		CMP		ECX,[_MMinX]
		JL		SHORT .NoVC
		
		ADD		EDX,[_MOrgY]
		MOV		AX,[EBP]
		MOV		EDX,[_MTSurfAdDeb+EDX*4]
		MOV		[EDX+ECX*2],AX
.NoVC:
		ADD		EBP,[MVectColPlus]
		DEC		EBX
		JNZ		SHORT .BcVC_PPs
		JMP		SHORT .EndPPixels
.NoVectCol:
		MOV		EBP,[_MOrgY]
		MOV		EAX,[MCurCol]
		SHL		EBP,2
ALIGN 4
.BcNVC_PPs:	MOV		EDX,[EDI]
		MOV		ECX,[ESI]
		ADD		EDI,[MVectYPlus]
		ADD		ESI,[MVectXPlus]
		; clip
		CMP		EDX,[_MMaxY]
		JG		SHORT .NoNVC
		CMP		ECX,[_MMaxX]
		JG		SHORT .NoNVC
		CMP		EDX,[_MMinY]
		JL		SHORT .NoNVC
		CMP		ECX,[_MMinX]
		JL		SHORT .NoNVC

		MOV		EDX,[_MTSurfAdDeb+EDX*4+EBP]
		MOV		[EDX+ECX*2],AX
.NoNVC:		DEC		EBX
		JNZ		SHORT .BcNVC_PPs
.EndPPixels:
		POP		ESI
		POP             EDI
		POP		EBX
		RETURN

ALIGN 32
_MLinesList16:
	ARG	PMLinesLPixelsCount, 4
		PUSH		EBX
		PUSH		EDI
		PUSH	        ESI

		MOV		EBX,[EBP+PMLinesLPixelsCount]
		MOV		EDI,[MpVectY]
		CMP		EBX,BYTE 2
		MOV		EBP,[MpVectCol]
		JL		.EndLLines
		MOV		ESI,[MpVectX]
		AND		BL,0xFE ; zero first off bit
		OR		EBP,EBP
		JZ		SHORT .NoVectCol
ALIGN 4
.BcVC_LLs:	MOV		AX,[EBP]
		MOV		EDX,[EDI]
		MOV		[MCurCol],AX
		MOV		ECX,[ESI]
		MOV		EAX,[MVectColPlus]
		MOV		[MYP1],EDX
		LEA		EBP,[EBP+EAX*2]  ; increment color pointer by 2 cases
		MOV		[MXP1],ECX
		MOVD		mm2,EBP ; save Col Ptr
		MOV		EAX,[MVectYPlus]
		MOV		EBP,[MVectXPlus]
		MOV		EDX,[EDI+EAX]
		MOV		ECX,[ESI+EBP]
		MOV		[MYP2],EDX
		LEA		EDI,[EDI+EAX*2] ; increment Y pointer by 2 cases
		MOV		[MXP2],ECX
		LEA		ESI,[ESI+EBP*2] ; increment X pointer by 2 cases
		MOVD		mm5,EBX
		MOVD		mm3,EDI
		MOVD		mm4,ESI
		MOV		EBX,ECX
		MOV		EDI,EDX
		MOV		EAX,[MXP1]
		MOV		ESI,[MYP1]
		CALL		mline16

		MOVD		EBP,mm2
		MOVD		EBX,mm5
		MOVD		EDI,mm3
		MOVD		ESI,mm4
		SUB		EBX,BYTE 2
		JNZ		SHORT .BcVC_LLs
		JMP		SHORT .EndLLines
.NoVectCol:
ALIGN 4
.BcNVC_LLs:	MOV		EDX,[EDI]
		MOV		ECX,[ESI]
		MOV		[MYP1],EDX
		MOV		[MXP1],ECX
		MOV		EAX,[MVectYPlus]
		MOV		EBP,[MVectXPlus]
		MOV		EDX,[EDI+EAX]
		MOV		ECX,[ESI+EBP]
		MOV		[MYP2],EDX
		LEA		EDI,[EDI+EAX*2] ; increment Y pointer by 2 cases
		MOV		[MXP2],ECX
		LEA		ESI,[ESI+EBP*2] ; increment X pointer by 2 cases
		MOVD		mm5,EBX
		MOVD		mm3,EDI
		MOVD		mm4,ESI
		MOV		EBX,ECX
		MOV		EDI,EDX
		MOV		EAX,[MXP1]
		MOV		ESI,[MYP1]
		CALL		mline16

		MOVD		EBX,mm5
		MOVD		EDI,mm3
		MOVD		ESI,mm4
		SUB		EBX,BYTE 2
		JNZ		SHORT .BcNVC_LLs
.EndLLines:
		POP		ESI
		POP             EDI
		POP		EBX
		RETURN

ALIGN 32
_MLinesStrip16:
	ARG	PMLinesSPixelsCount, 4
		PUSH		EBX
		PUSH		EDI
		PUSH	        ESI

		MOV		EBX,[EBP+PMLinesSPixelsCount]
		CMP		EBX,BYTE 2
		JL		.EndLLines
		DEC		EBX
		MOV		EDI,[MpVectY]
		MOV		EBP,[MpVectCol]
		MOV		ESI,[MpVectX]
		OR		EBP,EBP
		JZ		SHORT .NoVectCol
ALIGN 4
.BcVC_LLs:	MOV		AX,[EBP]
		MOV		EDX,[EDI]
		MOV		[MCurCol],AX
		MOV		ECX,[ESI]
		MOV		EAX,[MVectColPlus]
		MOV		[MYP1],EDX
		LEA		EBP,[EBP+EAX*2]  ; increment color pointer by 2 cases
		MOV		[MXP1],ECX
		MOVD		mm2,EBP ; save Col Ptr
		MOV		EAX,[MVectYPlus]
		MOV		EBP,[MVectXPlus]
		MOV		EDX,[EDI+EAX]
		MOV		ECX,[ESI+EBP]
		MOV		[MYP2],EDX
		LEA		EDI,[EDI+EAX*2] ; increment Y pointer by 2 cases
		MOV		[MXP2],ECX
		LEA		ESI,[ESI+EBP*2] ; increment X pointer by 2 cases
		MOVD		mm5,EBX
		MOVD		mm3,EDI
		MOVD		mm4,ESI
		MOV		EBX,ECX
		MOV		EDI,EDX
		MOV		EAX,[MXP1]
		MOV		ESI,[MYP1]
		CALL		mline16

		MOVD		EBP,mm2
		MOVD		EBX,mm5
		MOVD		EDI,mm3
		MOVD		ESI,mm4
		SUB		EBX,BYTE 2
		JNZ		SHORT .BcVC_LLs
		JMP		SHORT .EndLLines
.NoVectCol:
ALIGN 4
.BcNVC_LLs:	MOV		EDX,[EDI]
		MOV		ECX,[ESI]
		MOV		[MYP1],EDX
		MOV		[MXP1],ECX
		MOV		EAX,[MVectYPlus]
		MOV		EBP,[MVectXPlus]
		MOV		EDX,[EDI+EAX]
		MOV		ECX,[ESI+EBP]
		MOV		[MYP2],EDX
		LEA		EDI,[EDI+EAX] ; increment Y pointer by 2 cases
		MOV		[MXP2],ECX
		LEA		ESI,[ESI+EBP] ; increment X pointer by 2 cases
		MOVD		mm5,EBX
		MOVD		mm3,EDI
		MOVD		mm4,ESI
		MOV		EBX,ECX
		MOV		EDI,EDX
		MOV		EAX,[MXP1]
		MOV		ESI,[MYP1]
		CALL		mline16

		MOVD		EBX,mm5
		MOVD		EDI,mm3
		MOVD		ESI,mm4
		DEC		EBX
		JNZ		SHORT .BcNVC_LLs
.EndLLines:
		POP		ESI
		POP             EDI
		POP		EBX
		RETURN

ALIGN 32
_MPtrLinesList16:
	ARG	TPtrVLL, 4, PMPLinesLPixelsCount, 4
		PUSH		EBX
		PUSH		EDI
		PUSH	        ESI

		MOV		EBX,[EBP+PMPLinesLPixelsCount]
		MOV		ESI,[EBP+TPtrVLL]
		CMP		EBX,BYTE 2
		JL		SHORT .EndLLines
		AND		BL,0xFE ; zero first off bit
ALIGN 4
.BcVC_LLs:
		MOV		EBP,[MVectXPlus]
		MOV		EAX,[MVectColPlus]
		MOV		EDI,[ESI]
		MOV		EDX,[MVectYPlus]
		MOV		AX,[EDI+EAX]
		MOV		ECX,[EDI+EBP]
		MOV		[MCurCol],AX
		MOV		EDI,[EDI+EDX]
		MOV		[MYP1],EDI
		MOV		[MXP1],ECX
		MOV		EDI,[ESI+4]

		MOVD		mm5,EBX
		MOVD		mm4,ESI
		MOV		ECX,[EDI+EBP]
		MOV		EDX,[EDI+EDX]
		MOV		[MXP2],ECX
		MOV		[MYP2],EDX
		MOV		EBX,ECX
		MOV		EDI,EDX
		MOV		EAX,[MXP1]
		MOV		ESI,[MYP1]
		CALL		mline16

		MOVD		EBX,mm5
		MOVD		ESI,mm4
		
		SUB		EBX,BYTE 2
		LEA		ESI,[ESI+8]
		JNZ		SHORT .BcVC_LLs
.EndLLines:
		POP		ESI
		POP             EDI
		POP		EBX
		RETURN

ALIGN 32
_MPtrLinesStrip16:
	ARG	TPtrVLS, 4, PMPLinesSPixelsCount, 4
		PUSH		EBX
		PUSH		EDI
		PUSH	        ESI

		MOV		EBX,[EBP+PMPLinesSPixelsCount]
		MOV		ESI,[EBP+TPtrVLS]
		CMP		EBX,BYTE 2
		JL		SHORT .EndLLines
		DEC		EBX
ALIGN 4
.BcVC_LSs:
		MOV		EBP,[MVectXPlus]
		MOV		EAX,[MVectColPlus]
		MOV		EDI,[ESI]
		MOV		EDX,[MVectYPlus]
		MOV		AX,[EDI+EAX]
		MOV		ECX,[EDI+EBP]
		MOV		[MCurCol],AX
		MOV		EDI,[EDI+EDX]
		MOV		[MYP1],EDI
		MOV		[MXP1],ECX
		MOV		EDI,[ESI+4]

		MOVD		mm5,EBX
		MOVD		mm4,ESI
		MOV		ECX,[EDI+EBP]
		MOV		EDX,[EDI+EDX]
		MOV		[MXP2],ECX
		MOV		[MYP2],EDX
		MOV		EBX,ECX
		MOV		EDI,EDX
		MOV		EAX,[MXP1]
		MOV		ESI,[MYP1]
		CALL		mline16

		MOVD		EBX,mm5
		MOVD		ESI,mm4
		
		DEC		EBX
		LEA		ESI,[ESI+4]
		JNZ		SHORT .BcVC_LSs
.EndLLines:
		POP		ESI
		POP             EDI
		POP		EBX
		RETURN

%include "mline16.asm"

;***************************************************************
;***************************************************************
;               \\\\\\\\  TRI & QUAD  //////
;***************************************************************

ALIGN 32
_MPtrTrisList16:
	ARG	TPtrVTriL, 4, PMPTrisLPixelsCount, 4, PtrTriLType, 4
		PUSH		EBX
		PUSH		EDI
		PUSH	        ESI

		MOV		EAX,[EBP+PtrTriLType]
		MOV		ESI,[EBP+TPtrVTriL]
		MOV		ECX,[EBP+PMPTrisLPixelsCount]
		MOV		[MType],EAX
		LEA		EBP,[EAX*4+InFillMTriProc16]
		LEA		EDI,[EAX*4+ClFillMTriProc16]
		MOV		[MFncFillInPtr],EBP
		MOV		[MFncFillClpPtr],EDI
		
ALIGN 4
.BcVC_TLs:
		PUSH		ESI
		PUSH		ECX
		MOV		EDI,[ESI]
		MOV		EBP,[ESI+8]
		MOV		ESI,[ESI+4]
		MOV		[MPtrV1],EDI
		
;----------------
.verifSens:
		MOV		ECX,[MVectXPlus]
		MOV		EDX,[MVectYPlus]
		MOVD		mm1,[ESI+ECX] ; XP2
		MOVD		mm3,[ESI+EDX] ; YP2
		MOVD		mm0,[EDI+ECX] ; XP1
		MOVD		mm5,[EDI+EDX] ; YP1

		PUNPCKLDQ	mm1,mm3
		MOVD		mm2,[EBP+ECX] ; XP3
		MOVD		mm6,[EBP+EDX] ; YP3
		MOVQ		mm4,mm1
		PUNPCKLDQ	mm0,mm5
		PUNPCKLDQ	mm2,mm6

		PSUBD		mm1,mm0 ; = (XP2-XP1) | (YP2 - YP1)
		PSUBD		mm2,mm4 ; = (XP3-XP2) | (YP3 - YP2)
		MOVD		EAX,mm1 ; = (XP2-XP1)
		MOVD		EDX,mm2 ; = (XP3-XP2)
		PSRLQ		mm1,32
		PSRLQ		mm2,32
		MOVD		ECX,mm1 ; = (YP2-YP1)
		MOVD		EBX,mm2 ; = (YP3-YP2)
		IMUL		ECX,EDX
		IMUL		EAX,EBX
		CMP		EAX,ECX
		JG		SHORT .OrientOK ; if > 0  ok
		JZ		.NoDrawTri
		TEST		BYTE [MRenderState],DBL_SIDED_MASK
		JZ		.NoDrawTri
		XCHG		ESI,EBP   ; swap vertex 2 and vertex 3 Ptr
.OrientOK:
;----------------
		MOV		EBX,[MVectXPlus]
		MOV		EDX,[MVectYPlus]
		
		MOV		EAX,[EDI+EBX] ; = maxx ? V1.X
		MOV		ECX,[EBP+EBX] ; = minx ? V3.x
		CMP		ECX,EAX ; minx > maxx ?
		JL		SHORT .MXBornOK
		XCHG		ECX,EAX
.MXBornOK:
		CMP		EAX,[ESI+EBX] ; V2.x > maxx ?
		JG		SHORT .MMaxXOk
		MOV		EAX,[ESI+EBX]
.MMaxXOk:
		CMP		ECX,[ESI+EBX] ; V2.x < minx ?
		JL		SHORT .MMinXOk
		MOV		ECX,[ESI+EBX]
.MMinXOk:
;-------
		MOV		EBX,[EDI+EDX] ; = maxy ? V1.y
		MOV		EDX,[EBP+EDX] ; = miny ? V3.y
		MOV		EDI,[MVectYPlus]
		CMP		EDX,EBX ; miny > maxy ?
		JL		SHORT .MYBornOK
		XCHG		EDX,EBX
.MYBornOK:
		CMP		EBX,[ESI+EDI] ; V2.y > maxy ?
		JG		SHORT .MMaxYOk
		MOV		EBX,[ESI+EDI]
.MMaxYOk:
		CMP		EDX,[ESI+EDI] ; V2.y < miny ?
		JL		SHORT .MMinYOk
		MOV		EDX,[ESI+EDI]
.MMinYOk:
		; restore ptrV1
		MOV		EDI,[MPtrV1]

;-------
; Tri clipped ? inside screen ? outside ?
		CMP		EAX,[_MMaxX]
		JG		.TriClip
		CMP		ECX,[_MMinX]
		JL		.TriClip
		CMP		EBX,[_MMaxY]
		JG		.TriClip
		CMP		EDX,[_MMinY]
		JL		.TriClip
; In draw tri //////////////////
		CALL		DWORD [MFncFillInPtr]
		JMP		.NoDrawTri
.TriClip:
; outside screen ?
		CMP		EAX,[_MMinX]
		JL		.NoDrawTri
		CMP		EBX,[_MMinY]
		JL		.NoDrawTri
		CMP		ECX,[_MMaxX]
		JG		.NoDrawTri
		CMP		EDX,[_MMaxY]
		JG		.NoDrawTri
; Clip draw tri //////////////////
		CALL		DWORD [MFncFillClpPtr]
.NoDrawTri:
		POP		ECX
		POP		ESI
		
		SUB		ECX,BYTE 3
		LEA		ESI,[ESI+12]
		JNZ		.BcVC_TLs

		POP		ESI
		POP             EDI
		POP		EBX
		RETURN

%include "mfill16.asm"

SECTION	.data
ALIGN 32
_CurMSurf:
_Mvlfb		DD	0
_MResH 		DD	0
_MResV 		DD	0
_MMaxX 		DD	0
_MMaxY 		DD	0
_MMinX 		DD	0
_MMinY 		DD	0
_MOrgY		DD	0;-----------------------
_MOrgX		DD	0
_MSizeSurf	DD	0
_MOffVMem	DD	0
_Mrlfb		DD	0
_MRMaxX		DD	0
_MRMaxY		DD	0
_MRMinX		DD	0
_MRMinY		DD	0;-----------------------
_MBitsPixel	DD	0
_MScanLine	DD	0
_MMask		DD	0
_MResv2		DD	0
_MResv3		DD	0
_MResv4		DD	0
_MResv5		DD	0
_MResv6		DD	0;-----------------------
; source texture
_CurMSrcSurf:
MSvlfb		DD	0
MSResH		DD	0
MSResV		DD	0
MSMaxX		DD	0
MSMaxY		DD	0
MSMinX		DD	0
MSMinY		DD	0
MSOrgY		DD	0;-----------------------
MSOrgX		DD	0
MSSizeSurf	DD	0
MSOffVMem	DD	0
MSrlfb		DD	0
MSRMaxX		DD	0
MSRMaxY		DD	0
MSRMinX		DD	0
MSRMinY		DD	0;-----------------------
MSBitsPixel	DD	0
MSScanLine	DD	0
MSMask		DD	0
MSResv2		DD	0
MSResv3		DD	0
MSResv4		DD	0
MSResv5		DD	0
MSResv6		DD	0;-----------------------
MpVectX		DD	0
MVectXPlus	DD	0
MpVectY		DD	0
MVectYPlus	DD	0
MpVectCol	DD	0
MVectColPlus	DD	0
MpVectZ		DD	0
MVectZPlus	DD	0;-----------------------
MCurX		DD	0
MCurY		DD	0
MCurZ		DD	0
MCurCol		DD	0
MCurX2		DD	0
MCurY2		DD	0
MCurZ2		DD	0
MCurCol2	DD	0;-----------------------
MXP1		DD	0
MYP1		DD	0
MZP1		DD	0
MXT1		DD	0
MYT1		DD	0
MCOL1		DD	0
MXP2		DD	0
MYP2		DD	0
MZP2		DD	0
MXT2		DD	0
MYT2		DD	0
MCOL2		DD	0
MXP3		DD	0
MYP3		DD	0
MZP3		DD	0
MXT3		DD	0
MYT3		DD	0
MCOL3		DD	0
MXP4		DD	0
MYP4		DD	0
MZP4		DD	0
MXT4		DD	0
MYT4		DD	0
MCOL4		DD	0 ;----------------------
MPtrV1		DD	0
MPtrV2		DD	0
MPtrV3		DD	0
MPtrV4		DD	0
MType		DD	0
MRenderState	DD	1
MDebYPoly	DD	0
MEndYPoly	DD	0;-----------------------
MFncFillInPtr	DD	0
MFncFillClpPtr  DD	0
MTriDebY	DD	0
MTriEndY	DD	0
Mresv005	DD	0
MTriMaxY	DD	0
MTriMinY	DD	0
Mresv006	DD	0;-----------------------

;* 16bpp poly proc****
InFillMTriProc16:
		DD	InFillMTriSOLID16,InFillMTriSOLID_BLND16
		DD	0,0

ClFillMTriProc16:
		DD	ClipFillMTriSOLID16,ClipFillMTriSOLID_BLND16
		DD	0,0

