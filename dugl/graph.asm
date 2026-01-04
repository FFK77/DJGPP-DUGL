%include "param.mac"

; GLOBAL Function****
; 8bpp
GLOBAL	_PutPixel,_GetPixel,_line,_Line,_linemap,_LineMap,_SetSurf,_SurfCopy
GLOBAL	_SetSrcSurf,_GetSurf,_Clear,_ProtectSetPalette,_ProtectViewSurf
GLOBAL	_ProtectViewSurfWaitVR,_WaitRetrace,_GetMaxResVSetSurf
;********************
GLOBAL	_Poly,_SensPoly,_ValidSPoly,_PutSurf,_PutMaskSurf
GLOBAL	_InRLE,_OutRLE,_SizeOutRLE,_InLZW
GLOBAL	_SetFONT, _GetFONT,_OutText,_LargText,_LargPosText,_PosLargText
; 16bpp
GLOBAL	_PutPixel16,_GetPixel16
GLOBAL	_PutSurf16,_PutMaskSurf16,_PutSurfBlnd16,_PutMaskSurfBlnd16
GLOBAL	_PutSurfTrans16,_PutMaskSurfTrans16
GLOBAL	_SurfCopyBlnd16,_SurfMaskCopyBlnd16,_SurfCopyTrans16,_SurfMaskCopyTrans16
GLOBAL	_line16,_Line16,_linemap16,_LineMap16,_lineblnd16,_LineBlnd16
GLOBAL	_linemapblnd16,_LineMapBlnd16,_Poly16
GLOBAL	_Clear16,_OutText16


; GLOBAL DATA
GLOBAL	_CurViewVSurf, _CurSurf, _SrcSurf
GLOBAL	_CurFONT, _FntPtr, _FntHaut, _FntDistLgn, _FntLowPos, _FntHighPos
GLOBAL	_FntSens, _FntTab, _FntX, _FntY, _FntCol
GLOBAL	_PtrTbColConv

; EXTERN DATA
EXTERN	_SetPalPMI, _CurPalette, _ShiftPal, _ViewAddressPMI, _VSurf, _NbVSurf
EXTERN	_EnableMPIO,_SelMPIO
; --Poly-----
EXTERN	_TPolyAdDeb, _TPolyAdFin, _TexXDeb, _TexXFin, _TexYDeb, _TexYFin
EXTERN	_PColDeb, _PColFin, _TbDegCol
; --GIF------
EXTERN	_Prefix, _Suffix, _DStack
Prec			EQU	12
MaxResV			EQU	4096
BlendMask		EQU	0x1f
SurfUtilSize    EQU 64
CMaskB_RGB16	EQU	0x1f	 ; blue bits 0->4
CMaskG_RGB16	EQU	0x3f<<5  ; green bits 5->10
CMaskR_RGB16	EQU	0x1f<<11 ; red bits 11->15
MaxDeltaDim		EQU	1<< (31-Prec)


SECTION .text
[BITS 32]
ALIGN 32

%include "poly.asm"
%include "hzline.asm"
%include "fill.asm"
%include "pts_line.asm"
%include "poly16.asm"
%include "hzline16.asm"
%include "line16.asm"
%include "pts16.asm"
%include "fill16.asm"

;*********** Donnee DEF LZW*****************************
;*******************************************************
Prefix_Code	DD	0
Suffix_Code	DD	0
Old_Code	DD	0
CasSpecial	DD	0
DStackPtr	DD	0
NbBitCode	DD	0
MaxCode		DD	0
BuffPtrLZW	DD	0
BuffIndexLZW	DD	0
OutBuffLZW	DD	0
OutBuffIndex	DD	0
FreeAb		DD	0
UtlBitCurAdd	DD	0
RestBytes	DD	0
CPTLZW		DD	0
CPTCLR		DD	0
ClrAb		EQU	256
EndOF		EQU	257

_InLZW:
	ARG    InBuffLZW, 4, OutLZW, 4

		PUSH		EDI
		PUSH		ESI
		PUSH		EBX

		MOV		EAX,[EBP+OutLZW]
		MOV		[OutBuffIndex],EAX
		MOVD		mm4,EAX     ; [OutBuffIndex]
		MOV		EAX,[EBP+InBuffLZW]
		MOV		[BuffPtrLZW],EAX
		MOV		EBX,EAX
		XOR		EAX,EAX
		MOV		DWORD [UtlBitCurAdd],EAX
		MOV		DWORD [NbBitCode],9
		CALL		GetLZWCode	; saute le premier clear code
.ClrAbLZW:
		MOV		DWORD [NbBitCode],9
		MOV		DWORD [FreeAb],258
		MOV		DWORD [MaxCode],511
		CALL		GetLZWCode
		MOVD		EDI,mm4  ; [OutBuffIndex]
		STOSB
		MOV		[Suffix_Code],EAX
		MOV		[CasSpecial],EAX
		MOVD		mm4,EDI
.BcGtCodeLZW:
		CALL		GetLZWCode
		CMP		EAX,ClrAb
		JE		.ClrAbLZW
		CMP		EAX,EndOF
		JE		.FinInLZW
		XCHG		EAX,[Suffix_Code]
		MOV		[Prefix_Code],EAX
		MOV		[Old_Code],EAX
		MOV		EDX,[Suffix_Code]
		MOV		ECX,[FreeAb]
;**** DECODAGE ------ DEBUT
		XOR		EDI,EDI 	   ; DStackPtr =0
		CMP		EDX,ECX
		JB 		.PasCasSpecial
.CasSpecial:	MOV		AL,[CasSpecial]
		MOV		EDX,[Old_Code]
		MOV		[_DStack+EDI],AL
		INC		EDI
.PasCasSpecial:
.BoucDecodLZW:	CMP		EDX,ClrAb
		JA		.PasConcret
.Concret:	MOV		[_DStack+EDI],EDX
		MOV		[CasSpecial],EDX
		MOV		[DStackPtr],EDI
		JMP		.FinDecodeLZW
.PasConcret:	MOV		AL,[_Suffix+EDX]
		MOV		EDX,[_Prefix+EDX*4]
		MOV		[_DStack+EDI],AL
		INC		EDI
		JMP		.BoucDecodLZW
.FinDecodeLZW:
		; vide la pile de decodage dans le buff out
		MOV		ESI,[DStackPtr]
		MOVD		EDI,mm4
.BoucVidStack:	MOV		AL,[_DStack+ESI]
		STOSB
		DEC		ESI
		JNS		.BoucVidStack
		MOVD		mm4,EDI       ; [OutBuffIndex]
;**** DECODAGE ------ FIN
		MOV		EAX,[FreeAb]
		MOV		ECX,[Prefix_Code]
		MOV		[_Prefix+EAX*4],ECX
		MOV		DL,[CasSpecial]
		MOV		[_Suffix+EAX],DL

		MOV		EAX,[FreeAb]   ; si [FreeAb]+1>[MaxCode] ?
		INC		EAX
		CMP		EAX,[MaxCode]
		MOV		[FreeAb],EAX
		JBE		.BcGtCodeLZW;   ; alors
		CMP		DWORD [NbBitCode],BYTE 12
		JE		.PasExtNbBit
		MOV		ECX,[NbBitCode]
		INC		ECX
		MOV		EDX,1
		MOV		[NbBitCode],ECX
		SHL		EDX,CL
		DEC		EDX
		MOV		[MaxCode],EDX  ; fin si
.PasExtNbBit:	JMP		.BcGtCodeLZW
.FinInLZW:
		POP		EBX
		POP		ESI
		POP		EDI
		;EMMS
		RETURN

GetLZWCode:
		MOV		ECX,[UtlBitCurAdd]
		CMP		ECX,BYTE 32
		JE		.SpecialLire
		ADD		ECX,[NbBitCode]
		CMP		ECX,BYTE 32
		MOV		EAX,[EBX]
		MOV		ECX,[UtlBitCurAdd]
		JBE		.LireNorm
		MOV		EDX,[EBX+4]
		SHRD		EAX,EDX,CL
		ADD		EBX,BYTE 4
		SUB		DWORD [UtlBitCurAdd],BYTE 32
		JMP		SHORT .FinLireLZW
.SpecialLire:	ADD		EBX,BYTE 4
		MOV		EAX,[EBX]
		MOV		DWORD [UtlBitCurAdd],0
		JMP		SHORT .FinLireLZW
.LireNorm:	SHR		EAX,CL
.FinLireLZW:	MOV		ECX,[NbBitCode]
		AND		EAX,[MaxCode]
		ADD		DWORD [UtlBitCurAdd],ECX
		RET
;************Fin GIF*********************************

;************* PCX***********************************
;****************************************************
_InRLE:
	ARG	InBuffRLE, 4, OutRLE, 4, LenOutRLE, 4

		PUSH		EDI
		PUSH		ESI

		MOV		EDX,[EBP+LenOutRLE]
		MOV		EDI,[EBP+OutRLE]
		MOV		ESI,[EBP+InBuffRLE]
		ADD		EDX,EDI
.BcInRLE:	LODSB
		CMP		AL,0xC0
		JB		.Isole
		MOV		CL,AL
		AND		CL,0x3f
		LODSB
		MOVZX		ECX,CL
		REP		STOSB
		JMP		SHORT .PasIsoleRLE
.Isole:		STOSB
.PasIsoleRLE:	CMP		EDI,EDX
		JB 		.BcInRLE

		POP		ESI
		POP		EDI
		RETURN

_OutRLE:
	ARG	OutBuffRLE, 4, InRLE, 4, LenInRLE, 4, ResHzRLE, 4

		PUSH		EDI
		PUSH		ESI
		PUSH		EBX

		MOV		ESI,[EBP+InRLE]
		MOV		EDI,[EBP+OutBuffRLE]
		MOV		EDX,[EBP+LenInRLE]
.BcOutRLEResH:	MOV		ECX,[EBP+ResHzRLE]
		LODSB
		DEC		EDX
		DEC		ECX
		MOV		AH,AL
		XOR		BL,BL
.BcOutRLEGn:
		LODSB

		CMP		BL,62
		JAE		.PrcOutRLE
		CMP		AL,AH
		JNE		.PrcOutRLE
		INC		BL
		JMP		SHORT .PrcBoucle
.PrcOutRLE:
		MOV		BH,AL
		OR		BL,BL
		JNZ		.PasIsole
		MOV		AL,AH
		AND		AL,0xC0
		CMP		AL,0xC0
		JE		.PasIsole
		JMP		SHORT .Isole
.PasIsole:	MOV		AL,BL
		INC		AL
		OR		AL,0xC0
		STOSB
.Isole:		MOV		AL,AH
		STOSB

.AjNext:	MOV		AH,BH
		XOR		BL,BL
		JMP		SHORT .PrcBoucle

.PrcBoucle:	DEC		EDX
		DEC		ECX
		JNZ		.BcOutRLEGn
.LastByte:
		OR 		BL,BL
		JNZ		.FPasIsole

		MOV		AL,AH
		AND		AL,0xC0
		CMP		AL,0xC0
		JE		.FPasIsole
		JMP		SHORT .FIsole
.FPasIsole:	MOV		AL,BL
		INC		AL
		OR		AL,0xC0
		STOSB
.FIsole:	MOV		AL,AH
		STOSB

		OR		EDX,EDX
		JNZ		.BcOutRLEResH

		MOV		EAX,EDI
.FinOutRLE:
		POP		EBX
		POP		ESI
		POP		EDI
		RETURN

_SizeOutRLE:
	ARG    SzInRLE, 4, SzLenInRLE, 4, SzResHzRLE, 4

		PUSH		EDI
		PUSH		ESI
		PUSH		EBX

		MOV		ESI,[EBP+SzInRLE]
		XOR		EDI,EDI
		MOV		EDX,[EBP+SzLenInRLE]
.BcOutRLEResH:	MOV		ECX,[EBP+SzResHzRLE]
		LODSB
		DEC		EDX
		DEC		ECX
		MOV		AH,AL
		XOR		BL,BL
.BcOutRLEGn:
		LODSB

		CMP		BL,62
		JAE		.PrcOutRLE
		CMP		AL,AH
		JNE		.PrcOutRLE
		INC		BL
		JMP		SHORT .PrcBoucle
.PrcOutRLE:
		MOV		BH,AL
		OR		BL,BL
		JNZ		.PasIsole
		MOV		AL,AH
		AND		AL,0xC0
		CMP		AL,0xC0
		JE		.PasIsole
		JMP		SHORT .Isole
.PasIsole:	INC		EDI
.Isole:		INC		EDI

.AjNext:	MOV		AH,BH
		XOR		BL,BL
		JMP		SHORT .PrcBoucle

.PrcBoucle:	DEC		EDX
		DEC		ECX
		JNZ		.BcOutRLEGn
.LastByte:
		OR 		BL,BL
		JNZ		.FPasIsole

		MOV		AL,AH
		AND		AL,0xC0
		CMP		AL,0xC0
		JE		.FPasIsole
		JMP		SHORT .FIsole
.FPasIsole:
		INC		EDI
.FIsole:	INC		EDI

		OR		EDX,EDX
		JNZ		.BcOutRLEResH

		MOV		EAX,EDI
.FinOutRLE:
		POP		EBX
		POP		ESI
		POP		EDI
		RETURN

;**********Fin PCX*********************************

ALIGN 32
_SetSurf:
	ARG	S1, 4

		PUSH		EDI
		PUSH	        ESI

		MOV		ESI,[EBP+S1]
		MOV		EAX,[ESI+_ResV-_CurSurf]
		CMP		EAX,MaxResV
		JG		.Error
		MOV		EDI,_CurSurf
                CopySurf
		OR		EAX,BYTE -1
		JMP		SHORT .Ok
.Error:		XOR		EAX,EAX
.Ok:
		POP		ESI
		POP             EDI
		RETURN

ALIGN 32
_SetSrcSurf:
	ARG	SrcS, 4
		PUSH		EDI
		PUSH	        ESI

		MOV		ESI,[EBP+SrcS]
		MOV		EDI, _SrcSurf
		CopySurf

		POP		ESI
		POP		EDI
		RETURN

ALIGN 32
_SurfCopy:
	ARG	PDstSrf, 4, PSrcSrf, 4
		PUSH		EDI
		PUSH	        ESI
		PUSH		EBX

		MOV		ESI,[EBP+PSrcSrf]
		MOV		EDI,[EBP+PDstSrf]
		MOV		EBX,[ESI+_SizeSurf-_CurSurf]

		MOV		EDI,[EDI+_rlfb-_CurSurf]
		MOV		ESI,[ESI+_rlfb-_CurSurf]
		TEST		EDI,0x7
		JZ		.CpyMMX
.CopyBAv:	TEST		EDI,0x1
		JZ		.PasCopyBAv
		OR		EBX,EBX
		JZ		.FinSurfCopy
		DEC		EBX
		MOVSB
.PasCopyBAv:
.CopyWAv:	TEST		EDI,0x2
		JZ		.PasCopyWAv
		CMP		EBX,BYTE 2
		JL		.CopyBAp
		SUB		EBX,BYTE 2
		MOVSW
.PasCopyWAv:
.CopyDAv:	TEST		EDI,0x4
		JZ		.PasCopyDAv
		CMP		EBX,BYTE 4
		JL		.CopyWAp
		SUB		EBX,BYTE 4
		MOVSD
.PasCopyDAv:
.CpyMMX:	MOV		ECX,EBX
		SHR		ECX,6
		JZ		.PasCpyMMXBloc
		AND		EBX,BYTE 0x3F
.BcCpyMMXBloc:
		MOVQ		mm0,[ESI]
		MOVQ		mm1,[ESI+32]
		MOVQ		mm2,[ESI+8]
		MOVQ		mm3,[ESI+40]
		MOVQ		mm4,[ESI+16]
		MOVQ		mm5,[ESI+48]
		MOVQ		mm6,[ESI+24]
		MOVQ		mm7,[ESI+56]
		MOVQ		[EDI],mm0
		MOVQ		[EDI+32],mm1
		MOVQ		[EDI+8],mm2
		MOVQ		[EDI+40],mm3
		MOVQ		[EDI+16],mm4
		MOVQ		[EDI+48],mm5
		MOVQ		[EDI+24],mm6
		MOVQ		[EDI+56],mm7
		DEC		ECX
		LEA		ESI,[ESI+64]
		LEA		EDI,[EDI+64]
		JNZ		.BcCpyMMXBloc
.PasCpyMMXBloc:
		MOV		ECX,EBX
		SHR		ECX,3
		JZ		.PasCpyMMX
		AND		EBX,BYTE 7
.BcCpyMMX:
		MOVQ		mm0,[ESI]
		MOVQ		[EDI],mm0
		DEC		ECX
		LEA		ESI,[ESI+8]
		LEA		EDI,[EDI+8]
		JNZ		.BcCpyMMX

.PasCpyMMX:
.CopyDAp:	CMP		EBX,BYTE 4
		JL		.CopyWAp
		SUB		EBX,BYTE 4
		MOVSD
.PasCopyDAp:
.CopyWAp:	CMP		EBX,BYTE 2
		JL		.CopyBAp
		SUB		EBX,BYTE 2
		MOVSW
.PasCopyWAp:
.CopyBAp:	OR		EBX,EBX
		JZ		.FinSurfCopy
		MOVSB
.PasCopyBAp:
.FinSurfCopy:
		POP		EBX
		POP		ESI
		POP		EDI
		RETURN

_GetMaxResVSetSurf:
		MOV		EAX,MaxResV
		RET

_GetSurf:
	ARG	S2, 4
                PUSH            EDI
                PUSH            ESI

		MOV		ESI,_CurSurf
		MOV		EDI,[EBP+S2]
                CopySurf

                POP             ESI
                POP             EDI
		;EMMS
		RETURN

_ProtectSetPalette:
	ARG	Dbcol, 4, Nbcol, 4, Tcol, 4

		PUSH		EDI
		PUSH		ESI
		PUSH		EBX
		PUSH		ES

		MOV		EDX,[EBP+Dbcol]
		AND		EDX,BYTE -1
		MOV		ECX,[EBP+Nbcol]
		OR		ECX,ECX
		JS		.FinProtectSP
		JZ		.FinProtectSP
		CMP		ECX,256
		JG		.FinProtectSP

		MOV		AL,[_ShiftPal]
		OR		AL,AL
		JZ		.CopyPal

		MOV		ESI,[EBP+Tcol]
		LEA		EDI,[_CurPalette+EDX*4]
.BcShiftPal:	LODSD
		MOV		EBX,EAX
		SHR		AL,2
		SHR		EBX,16
		SHR		AH,2
		SHR		BL,2
		BSWAP		EAX
		MOV		AH,BL
		DEC		ECX
		BSWAP		EAX
		STOSD
		JNZ		.BcShiftPal
		JMP		SHORT .PasCopyPal
.CopyPal:
		MOV		ESI,[EBP+Tcol]
		LEA		EDI,[_CurPalette+EDX*4]
		REP		MOVSD
.PasCopyPal:
		MOV		EDX,[EBP+Dbcol]
		MOV		ECX,[EBP+Nbcol]
		AND		EDX,BYTE -1
		CMP		BYTE [_EnableMPIO],0
		JE		SHORT .NoMPIOSel
		MOV		AX,[_SelMPIO]
		MOV		ES,AX
.NoMPIOSel:
		MOV		EAX,[_SetPalPMI]
		LEA		EDI,[_CurPalette+EDX*4]
		XOR		EBX,EBX
		CALL		EAX
.FinProtectSP:
		POP		ES
		POP		EBX
		POP		ESI
		POP		EDI
		;EMMS
		RETURN

_ProtectViewSurf:
	ARG	NbSurf, 4
		MOVD		mm0,EBX
		MOVD		mm2,ESI
		PUSH		ES

		MOV			ECX,[EBP+NbSurf]
		CMP			ECX,[_NbVSurf]
		JNB			.FInNbSurf
		MOV			[_CurViewVSurf],ECX
		IMUL    	ECX,BYTE SurfUtilSize ;SHL ECX,6
		ADD			ECX,_OffVMem - _CurSurf ; OffVMem
		ADD			ECX,[_VSurf]
		MOV			EAX,[ECX]   ; EAX = VSurf[NbSurf].OffVMem
		ROR			EAX,2
		XOR			ECX,ECX
		MOV			CX,AX ; CX = OffVMem[2..17]
		SHR			EAX,16
		XOR			EDX,EDX
		MOV			DX,AX ; DX = OffVMem[18..31][0..1]
		XOR			EBX,EBX ; EBX 0
		CMP			BYTE [_EnableMPIO],0
		JE			SHORT .NoMPIOSel
		MOV			AX,[_SelMPIO]
		MOV			ES,AX
.NoMPIOSel:
		MOV			EAX,[_ViewAddressPMI]
		CALL		EAX

.FInNbSurf:
		POP			ES
		MOVD		EBX,mm0
		MOVD		ESI,mm2
		;EMMS
		RETURN

_ProtectViewSurfWaitVR:
	ARG	NbVRSurf, 4
		MOVD		mm0,EBX
		MOVD		mm2,ESI
		PUSH		ES

		MOV			ECX,[EBP+NbVRSurf]
		CMP			ECX,[_NbVSurf]
		JNB			.FInNbSurf
		MOV			[_CurViewVSurf],ECX
		IMUL		ECX,BYTE SurfUtilSize ;SHL		ECX,6
		ADD			ECX,_OffVMem - _CurSurf ; OffVMem
		ADD			ECX,[_VSurf]
		MOV			EAX,[ECX]   ; EAX = VSurf[NbSurf].OffVMem
		ROR			EAX,2
		XOR			ECX,ECX
		MOV			CX,AX ; CX = OffVMem[2..17]
		SHR			EAX,16
		XOR			EDX,EDX
		MOV			DX,AX ; DX = OffVMem[18..31][0..1]
		XOR             EBX,EBX
		MOV			BL,0x80
		CMP			BYTE [_EnableMPIO],0
		JE			SHORT .NoMPIOSel
		MOV			AX,[_SelMPIO]
		MOV			ES,AX
.NoMPIOSel:
		MOV			EAX,[_ViewAddressPMI]
		CALL		EAX

.FInNbSurf:	POP		ES
		MOVD		EBX,mm0
		MOVD		ESI,mm2
		;EMMS
		RETURN

; structure point { DWORD X, DWORD Y }
_PutPixel:
	ARG	PtrPoint, 4, col, 4

		MOV		EAX,[_ResH]
		MOV		EDX,[EBP+PtrPoint]
		IMUL		EAX,[EDX+4]
		MOV		EDX,[EDX]
		NEG		EAX
		MOV		ECX,[EBP+col]
		ADD		EAX,[_vlfb]
		MOV		[EAX+EDX],CL
		RETURN

_GetPixel:
	ARG	PtrGPoint, 4

		MOV		EDX,[EBP+PtrGPoint]
		MOV		ECX,[_ResH]
		IMUL		ECX,[EDX+4]
		XOR		EAX,EAX
		MOV		EDX,[EDX]
		NEG		ECX
		;ADD		ECX,EDX
		ADD		ECX,[_vlfb]
		MOV		AL,[ECX+EDX]
		RETURN

_Clear:
	ARG	clrcol, 4

		PUSH		EDI
		PUSH		ESI
		PUSH		EBX

		MOV		EAX,[EBP+clrcol]
		MOV		AH,AL
		MOV		ECX,EAX
		MOV		ESI,[_SizeSurf]
		BSWAP		EAX
		MOV		EDI,[_rlfb]
		MOV		AX,CX
		@SolidHLine

		POP		EBX
		POP		ESI
		POP		EDI

		;EMMS
		RETURN


_WaitRetrace:
		MOV		EDX,0x3da
.wait1:		IN		AL,DX
		TEST		AL,0x08
		JNZ		.wait1
.wait2:		IN		AL,DX
		TEST		AL,0x08
		JZ		.wait2
		RET


;***************** FONT
_SetFONT:
	ARG	SF, 4
		MOVD		mm0,ESI
		MOVD		mm1,EDI

		MOV		ESI,[EBP+SF]
		MOV		EDI,_CurFONT
		MOV		ECX,8
		REP		MOVSD

		MOVD		ESI,mm0
		MOVD		EDI,mm1
		;EMMS
		RETURN

_GetFONT:
	ARG	CF, 4
		MOVD		mm0,ESI
		MOVD		mm1,EDI

		MOV		ESI,_CurFONT
		MOV		EDI,[EBP+CF]
		MOV		ECX,8
		REP		MOVSD

		MOVD		ESI,mm0
		MOVD		EDI,mm1
		;EMMS
		RETURN
ALIGN 32
_OutText:
	ARG	Str, 4
		MOVD		mm0,ESI
		MOVD		mm1,EDI
		MOVD		mm2,EBX

		MOV		EBX,[_FntPtr]
		OR		EBX,EBX
		JZ		.FinOutText
		MOV		ESI,[EBP+Str]
		XOR		EAX,EAX
.BcOutChar:
		LODSB
		MOVD		mm3,ESI
		MOVD		mm4,EAX
		MOVD		mm5,EBX
		OR		AL,AL
		JZ		.FinOutText
;**************** Affichage et traitement **********************************
;***************************************************************************
		CMP		AL,13		 ;** Debut Cas Special
		MOVSX		ESI,BYTE [EBX+EAX*8+4] ; PlusX
		JE		.DebLigne
		XOR		EDX,EDX
		CMP		AL,10
		MOV		DL,[EBX+EAX*8+7] ;Largeur
		JE		.DebNextLigne
		XOR		ECX,ECX
		CMP		AL,9
		MOV		CL,[EBX+EAX*8+6] ; Haut
		JE		.TabCar	 ;** Fin   Cas Special
		MOVSX		EDI,BYTE [EBX+EAX*8+5] ; PlusLgn
		MOV		[ChLarg],EDX
		MOV		[ChPlusX],ESI
		MOVD		mm6,[EBX+EAX*8]        ; PtrDat
		OR		ESI,ESI
		MOV		[ChPlusLgn],EDI
		MOV		[ChHaut],ECX
		JNS		.GauchDroit
		JZ		.RienZero1
		LEA		EAX,[ESI+1]
		ADD		[_FntX],EAX
.GauchDroit:
.RienZero1:
		MOV		EBP,[_FntX]  ; MinX
		ADD		EDI,[_FntY]  ; MinY
		LEA		EBX,[EBP+EDX-1] ; MaxX: EBX=MinX+Larg-1
		LEA		ESI,[EDI+ECX-1] ; MaxY: ESI=MinY+Haut-1

		CMP		EBX,[_MaxX]
		JG		.CharClip
		CMP		ESI,[_MaxY]
		JG		.CharClip
		CMP		EBP,[_MinX]
		JL		.CharClip
		CMP		EDI,[_MinY]
		JL		.CharClip
;****** trace caractere IN *****************************
.CharIn:
		MOV		ECX,[_ResH]
		MOV		EBP,EDX ;Largeur
		IMUL		EDI,ECX
		ADD		ECX,EDX
		NEG		EDI
		MOV		[ChPlus],ECX
		ADD		EDI,[_FntX]
		MOV		EDX,[ChHaut]
		ADD		EDI,[_vlfb]
		XOR		EAX,EAX
		MOVD		ESI,mm6
		MOV		AL,[_FntCol]
.LdNext:	MOV		EBX,[ESI]
		MOV		CL,32
		ADD		ESI,BYTE 4
;ALIGN 4
.BcDrCarHline:	TEST		BL,1
		JZ		.PasDrPixel
		MOV		[EDI],AL
.PasDrPixel:
		SHR		EBX,1
		INC		EDI
		DEC		EBP
		JZ		.FinDrCarHline
		DEC		CL
		JNZ		.BcDrCarHline
		JZ		.LdNext
;ALIGN 4
.FinDrCarHline:	MOV		EBX,[ESI]
		SUB		EDI,[ChPlus]
		MOV		CL,32
		LEA		ESI,[ESI+4]
		DEC		DL
		MOV 		EBP,[ChLarg]
		JNZ		.BcDrCarHline
		JMP		.FinDrChar
;****** Trace Caractere Clip ***************************
.CharClip:
		CMP		EBX,[_MinX]
		JL		.FinDrChar
		CMP		ESI,[_MinY]
		JL		.FinDrChar
		CMP		EBP,[_MaxX]
		JG		.FinDrChar
		CMP		EDI,[_MaxY]
		JG		.FinDrChar
		; traitement MaxX********************************************
		CMP		EBX,[_MaxX]	; MaxX>_MaxX
		MOV		EAX,EBX
		JLE		.PasApPlus
		SUB		EAX,[_MaxX]	; DXAp = EAX = MaxX-_MaxX
		SUB		EDX,EAX 	; EDX = Larg-DXAp
		CMP		EAX,BYTE 32
		JL		.PasApPlus
		MOV		DWORD [ChApPlus],4
		JMP		SHORT .ApPlus
.PasApPlus:	XOR		EAX,EAX
		MOV		[ChApPlus],EAX
.ApPlus:
		; traitement MinX********************************************
		MOV		EAX,[_MinX]
		SUB		EAX,EBP
		JLE		.PasAvPlus
		SUB		EDX,EAX

		CMP		EAX,BYTE 32
		JL		.PasAvPlus2
		MOV		DWORD [ChAvPlus],4
		SUB		AL,32
		MOV		AH,32
		MOV		[ChAvDecal],AL
		SUB		AH,AL
		MOV		[ChNbBitDat],AH
		JMP		SHORT .AvPlus
.PasAvPlus2:
		MOV		AH,32
		MOV		[ChAvDecal],AL
		SUB		AH,AL
		MOV		[ChNbBitDat],AH
		XOR		EAX,EAX
		MOV		[ChAvPlus],EAX
		JMP		SHORT .AvPlus
.PasAvPlus:	XOR		EAX,EAX
		MOV		BYTE [ChNbBitDat],32
		MOV		[ChAvPlus],EAX
		MOV		[ChAvDecal],AL
.AvPlus:
		; traitement MaxY********************************************
		CMP		ESI,[_MaxY]	; MaxY>_MaxY
		MOV		EAX,ESI
		JLE		.PasSupMaxY
		SUB		EAX,[_MaxY]	; DY = EAX = MaxY-_MaxY
		SUB		ECX,EAX 	; ECX = Haut-DY
.PasSupMaxY:
		; traitement MinY********************************************
		MOV		EAX,[_MinY]
		SUB		EAX,EDI
		JLE		.PasInfMinY
		SUB		ECX,EAX
		MOV		EDI,[_MinY]
		CMP		DWORD [ChLarg],BYTE 32
		JLE		.Larg1DD
.Larg2DD:	IMUL		EAX,8
		MOVD		mm7,EAX
		PADDD		mm6,mm7
		JMP		SHORT .PasInfMinY
.Larg1DD:	IMUL		EAX,4
		MOVD		mm7,EAX
		PADDD		mm6,mm7
.PasInfMinY:
		MOV		[ChHaut],ECX
		MOV		[ChLarg],EDX
;************************************************
		MOV		ECX,[_ResH]
		MOV		EBP,EDX ;Largeur
		IMUL		EDI,ECX
		XOR		EAX,EAX
		ADD		ECX,EDX
		MOV		AL,[ChAvDecal]
		NEG		EDI
		MOV		[ChPlus],ECX
		ADD		EDI,[_FntX]
		ADD		EDI,EAX      ; EDI +=ChAvDecal
		MOV		EDX,[ChHaut]
		ADD		EDI,[_vlfb]
		MOVD		ESI,mm6

		MOV		AL,[_FntCol]  ;*************
		ADD		ESI,[ChAvPlus]
		MOV		EBX,[ESI]
		MOV		CL,[ChAvDecal]
		MOV		CH,[ChNbBitDat]
		ADD		ESI,BYTE 4
		SHR		EBX,CL
		JMP		SHORT .CBcDrCarHline

.CLdNext:	MOV		EBX,[ESI]
		MOV		CH,32
		ADD		ESI,BYTE 4
;ALIGN 4
.CBcDrCarHline:	TEST		BL,1
		JZ		.CPasDrPixel
		MOV		[EDI],AL
.CPasDrPixel:
		SHR		EBX,1
		INC		EDI
		DEC		EBP
		JZ		.CFinDrCarHline
		DEC		CH
		JNZ		.CBcDrCarHline
		JZ		.CLdNext
;ALIGN 4
.CFinDrCarHline:
		ADD		ESI,[ChApPlus]
		SUB		EDI,[ChPlus]
		ADD		ESI,[ChAvPlus]
		MOV		EBX,[ESI]
		MOV		CL,[ChAvDecal]
		MOV		CH,[ChNbBitDat]
		SHR		EBX,CL
		LEA		ESI,[ESI+4]
		DEC		DL
		MOV 		EBP,[ChLarg]
		JNZ		.CBcDrCarHline

.FinDrChar:;********************************************
		MOV		ESI,[ChPlusX]
		OR		ESI,ESI
		JS		.DroitGauch
		JZ		.RienZero2
		ADD		[_FntX],ESI
.DroitGauch:
.RienZero2:	OR		ESI,ESI
		JNS		.GauchDroit2
		JZ		.RienZero3
		MOV		EAX,[_FntX]
		DEC		EAX
		MOV		[_FntX],EAX
.GauchDroit2:
.RienZero3:
		JMP		SHORT .Norm

.DebNextLigne:	XOR		EAX,EAX 	      ;***debut trait Cas sp
		MOV		AL,[_FntDistLgn]
		MOV		EBX,[_FntY]
		SUB		EBX,EAX
		MOV		[_FntY],EBX
.DebLigne:	MOV		AL,[_FntSens]
		OR		AL,AL
		JZ		.GchDrt
		MOV		EBX,[_MaxX]
		JMP		SHORT .DrtGch
.GchDrt:	MOV		EBX,[_MinX]
.DrtGch:
		MOV		[_FntX],EBX
		JMP		SHORT .Norm
.TabCar:	MOV		AL,32	     ; TAB
		MOV		ESI,[_FntX]
		MOVZX		ECX,BYTE [_FntTab]
		MOVSX		EAX,BYTE [EBX+EAX*8+4] ; PlusX
		IMUL		ECX,EAX
		ADD		ESI,ECX
		MOV		[_FntX],ESI	;***********fin trait Cas sp
;*** FIN ******** Affichage et traitement **********************************
;***************************************************************************
.Norm:		MOVD		ESI,mm3
		MOVD		EAX,mm4
		MOVD		EBX,mm5
		JMP		.BcOutChar
.FinOutText:
		MOVD		ESI,mm0
		MOVD		EDI,mm1
		MOVD		EBX,mm2
		;EMMS
		RETURN

_LargText:
	ARG	LStr, 4
		MOVD		mm0,ESI
		MOVD		mm2,EBX

		MOV		EBX,[_FntPtr]
		XOR		ECX,ECX
		OR		EBX,EBX
		JZ		.FinLargText
		MOV		ESI,[EBP+LStr]
		XOR		EAX,EAX
.BcCalcLarg:
		LODSB
		OR		AL,AL
		JZ		.FinLargText
		CMP		AL,13
		JZ		.FinLargText
		CMP		AL,10
		JZ		.FinLargText
		CMP		AL,9	   ; Tab
		JNE		.PasTrtTab
		MOV		AL,32
		MOVSX		EDX,BYTE [EBX+EAX*8+4] ; space
		XOR		EAX,EAX
		MOV		AL,[_FntTab]
		IMUL		EDX,EAX
		ADD		ECX,EDX
		JMP		SHORT .BcCalcLarg
.PasTrtTab:
		MOVSX		EDX,BYTE [EBX+EAX*8+4]
		ADD		ECX,EDX
		JMP		SHORT .BcCalcLarg
.FinLargText:
		OR		ECX,ECX
		JNS		.Positiv
		NEG		ECX
.Positiv:	MOV		EAX,ECX
		OR		EAX,EAX
		JZ		.ZeroRien
		DEC		EAX
.ZeroRien:
		MOVD		ESI,mm0
		MOVD		EBX,mm2
		;EMMS
		RETURN

_LargPosText:
	ARG	LPStr, 4, LPPos, 4
		MOVD		mm0,ESI
		MOVD		mm1,EDI
		MOVD		mm2,EBX

		MOV		EBX,[_FntPtr]
		XOR		ECX,ECX
		OR		EBX,EBX
		JZ		.FinLargText
		MOV		ESI,[EBP+LPStr]
		MOV		EDI,[EBP+LPPos]
		XOR		EAX,EAX
		OR		EDI,EDI
		JZ		.FinLargText
		ADD		EDI,ESI
.BcCalcLarg:	XOR		EAX,EAX
		CMP		EDI,ESI
		JBE		.FinLargText
		LODSB
		OR		AL,AL
		JZ		.FinLargText
		CMP		AL,13
		JE		.FinLargText
		CMP		AL,10
		JE		.FinLargText
		CMP		AL,9	   ; Tab
		JNE		.PasTrtTab
		MOV		AL,32
		MOVSX		EDX,BYTE [EBX+EAX*8+4] ; space
		XOR		EAX,EAX
		MOV		AL,[_FntTab]
		IMUL		EDX,EAX
		ADD		ECX,EDX
		JMP		SHORT .BcCalcLarg
.PasTrtTab:
		MOVSX		EDX,BYTE [EBX+EAX*8+4]
		ADD		ECX,EDX
		JMP		SHORT .BcCalcLarg
.FinLargText:
		OR		ECX,ECX
		JNS		.Positiv
		NEG		ECX
.Positiv:	MOV		EAX,ECX
		OR		EAX,EAX
		JZ		.ZeroRien
		DEC		EAX
.ZeroRien:
		MOVD		ESI,mm0
		MOVD		EDI,mm1
		MOVD		EBX,mm2
		;EMMS
		RETURN

_PosLargText:
	ARG	PLStr, 4, PLLarg, 4
		MOVD		mm0,ESI
		MOVD		mm1,EDI
		MOVD		mm2,EBX

		MOV		EBX,[_FntPtr]
		XOR		ECX,ECX
		OR		EBX,EBX
		JZ		.FinPosLargText
		MOV		ESI,[EBP+PLStr]
		XOR		EDI,EDI
.BcCalcLarg:	XOR		EAX,EAX
		CMP		ECX,[EBP+PLLarg]
		JAE		.FinPosLargText
		LODSB
		INC		EDI
		OR		AL,AL
		JZ		.FinPosLargText
		CMP		AL,13
		JE		.FinPosLargText
		CMP		AL,10
		JE		.FinPosLargText
		CMP		AL,9	   ; Tab
		JNE		.PasTrtTab
		MOV		AL,32
		MOVSX		EDX,BYTE [EBX+EAX*8+4] ; space
		XOR		EAX,EAX
		MOV		AL,[_FntTab]
		IMUL		EDX,EAX
		OR		EDX,EDX
		JS		.NegTab
		ADD		ECX,EDX
		JMP		SHORT .BcCalcLarg
.NegTab:	SUB		ECX,EDX
		JMP		SHORT .BcCalcLarg
.PasTrtTab:
		MOVSX		EDX,BYTE [EBX+EAX*8+4]
		OR		EDX,EDX
		JS		.NegNorm
		ADD		ECX,EDX
		JMP		SHORT .BcCalcLarg
.NegNorm:	SUB		ECX,EDX
		JMP		SHORT .BcCalcLarg

.FinPosLargText:
		OR		EDI,EDI
		JZ		.PosZero
		DEC		EDI
.PosZero:
		MOV		EAX,EDI

		MOVD		ESI,mm0
		MOVD		EDI,mm1
		MOVD		EBX,mm2
		;EMMS
		RETURN


_ValidSPoly:
	ARG	VPtrListPt, 4
		MOVD		mm7,ESI
		MOVD		mm6,EBX
		MOVD		mm5,EDI

		MOV		ESI,[EBP+VPtrListPt]
		XOR		EDX,EDX
		LODSD		; MOV EAX,[ESI];  ADD ESI,4
		OR		EDX,BYTE 2     ; == MOV EDX,2
		MOV		[NbPPoly],EAX
.BcGtP123:	MOV		EAX,[ESI+EDX*4]  ; lecture P1,P2,P3
		MOV		EBX,[EAX]
		MOV		ECX,[EAX+4]
		MOV		[XP1+EDX*8],EBX
		MOV		[YP1+EDX*8],ECX
		DEC		EDX
		JNS		.BcGtP123
	;(XP2-XP1)*(YP3-YP2)-(XP3-XP2)*(YP2-YP1)
; s'assure que les points suive le sens inverse de l'aiguille d'une montre
		MOV		ECX,[XP2]
		MOV		ESI,ECX
		MOV		EBX,[YP3]
		SUB		ESI,[XP1]
		SUB		EBX,[YP2]
		MOV		EDX,[XP3]
		MOV		EDI,[YP2]
		IMUL		ESI,EBX
		SUB		EDX,ECX
		SUB		EDI,[YP1]
		XOR		EAX,EAX
		IMUL		EDI,EDX
		SUB		ESI,EDI
		SETG		AL

		MOVD		ESI,mm7
		MOVD		EBX,mm6
		MOVD		EDI,mm5
		;EMMS
		RETURN

_SensPoly:
	ARG	VSPtrListPt, 4
		MOVD		mm7,ESI
		MOVD		mm6,EBX
		MOVD		mm5,EDI

		MOV		ESI,[EBP+VSPtrListPt]
		XOR		EDX,EDX
		LODSD		; MOV EAX,[ESI];  ADD ESI,4
		OR		EDX,BYTE 2     ; == MOV EDX,2
		MOV		[NbPPoly],EAX
.BcGtP123:	MOV		EAX,[ESI+EDX*4]  ; lecture P1,P2,P3
		MOV		EBX,[EAX]
		MOV		ECX,[EAX+4]
		MOV		[XP1+EDX*8],EBX
		MOV		[YP1+EDX*8],ECX
		DEC		EDX
		JNS		.BcGtP123
	;(XP2-XP1)*(YP3-YP2)-(XP3-XP2)*(YP2-YP1)
; s'assure que les points suive le sens inverse de l'aiguille d'une montre
		MOV		ECX,[XP2]
		MOV		ESI,ECX
		MOV		EBX,[YP3]
		SUB		ESI,[XP1]
		SUB		EBX,[YP2]
		MOV		EDX,[XP3]
		MOV		EDI,[YP2]
		IMUL		ESI,EBX
		SUB		EDX,ECX
		SUB		EDI,[YP1]
		XOR		EAX,EAX
		IMUL		EDI,EDX
		SUB		ESI,EDI
		MOV		EAX,ESI

		MOVD		ESI,mm7
		MOVD		EBX,mm6
		MOVD		EDI,mm5
		;EMMS
		RETURN

;****************************************************************************
; struct of PtrlistPt
; 0‚		  DWORD : n count of PtrPoint
; 1‚.. n‚  DWORD : PtrP1(X1,Y1,Z1,XT1,YT1)...PtrPn(Xn,Yn,Zn,XTn,YTn)
;****************************************************************************
; TypePoly POLY_SOLID				= 0	 FIELDS USED (X,Y)
; TypePoly POLY_TEXT				= 1	 FIELDS USED (X,Y,XT,YT)
; TypePoly POLY_MASK_TEXT			= 2	 FIELDS USED (X,Y,XT,YT)
; TypePoly POLY_FLAT_DEG			= 3	 FIELDS USED (X,Y,DEG)
; TypePoly POLY_DEG		    		= 4	 FIELDS USED (X,Y,DEG)
; TypePoly POLY_FLAT_DEG_TEXT		= 5	 FIELDS USED (X,Y,XT,YT,DEG)
; TypePoly POLY_MASK_FLAT_DEG_TEXT 	= 6	 FIELDS USED (X,Y,XT,YT,DEG)
; TypePoly POLY_DEG_TEXT			= 7	 FIELDS USED (X,Y,XT,YT,DEG)
; TypePoly POLY_MASK_DEG_TEXT		= 8	 FIELDS USED (X,Y,XT,YT,DEG)
; TypePoly POLY_EFF_FDEG			= 9	 FIELDS USED (X,Y,XT,YT,DEG)
; TypePoly POLY_EFF_DEG				= 10 FIELDS USED (X,Y,XT,YT,DEG)
; TypePoly POLY_EFF_COLCONV			= 11 FIELDS USED (X,Y)
;****************************************************************************
; FLAGS :
POLY_FLAG_DBL_SIDED	EQU	0x80000000
DEL_POLY_FLAG_DBL_SIDED	EQU	0x7FFFFFFF

;****************************************************************************
ALIGN 32
_Poly:
	ARG	PtrListPt, 4, SSurf, 4, TypePoly, 4, ColPoly, 4

		PUSH            ESI
		PUSH            EBX
		MOV		ESI,[EBP+PtrListPt]
		PUSH            EDI

		LODSD		; MOV EAX,[ESI];  ADD ESI,4
		MOV		[NbPPoly],EAX
		MOV		ECX,[ESI+8]
		MOV		EAX,[ESI]
		MOV		EBX,[ESI+4]
		MOVQ		mm0,[EAX] ; = XP1, YP1
		MOVQ		mm1,[EBX] ; = XP2, YP2
		MOVQ		mm2,[ECX] ; = XP3, YP3
		MOVQ		mm3,mm0 ; = XP1, YP1
		MOVQ		mm4,mm1 ; = XP2, YP2
		MOVQ		[XP1],mm0 ; XP1, YP1

;(XP2-XP1)*(YP3-YP2)-(XP3-XP2)*(YP2-YP1)
; s'assure que les points suive le sens inverse de l'aiguille d'une montre
.verifSens:
		PSUBD		mm1,mm0 ; = (XP2-XP1) | (YP2 - YP1)
		PSUBD		mm2,mm4 ; = (XP3-XP2) | (YP3 - YP2)
		MOVD		EAX,mm1 ; = (XP2-XP1)
		MOVD		EDX,mm2 ; = (XP3-XP2)
		PSRLQ		mm1,32
		PSRLQ		mm2,32
		MOVD		EDI,mm1 ; = (YP2-YP1)
		MOVD		EBX,mm2 ; = (YP3-YP2)
		IMUL		EDI,EDX
		IMUL		EAX,EBX
		CMP		EAX,EDI

		JL		.TstSiDblSide ; si <= 0 alors pas ok
		JZ		.SpecialCase

;****************
.DrawPoly:
		; Sauvegarde les parametre et libere EBP
		MOV		EAX,[EBP+TypePoly]
		MOV		EBX,[EBP+ColPoly]
                AND             EAX,DEL_POLY_FLAG_DBL_SIDED16
		MOV		ECX,[EBP+SSurf]
		MOV		[PType],EAX
		MOV		[clr],EBX
		MOV		[PPtrListPt],ESI
		MOV		EDI,[NbPPoly]
		MOV		[SSSurf],ECX
;-new born determination--------------
		MOV		EBP,EDI
		MOVQ		mm1,mm3 ; init min = XP1 | YP1
		MOVQ		mm2,mm3 ; init max = XP1 | YP1
		DEC		EBP ; = [NbPPoly] - 1
		DEC		EDI ; " "
.PBoucMnMxXY:
		MOV		EAX,[ESI+EBP*4] ; = XN, YN
		MOVQ		mm0,[EAX] ; = XN, YN
		MOVQ		mm3,mm1 ; = min (x|y)
		MOVQ		mm4,mm2 ; = max (x|y)
		PCMPGTD		mm3,mm0 ; mm3 = min(x|y) > (xn|yn)
		PCMPGTD		mm4,mm0 ; mm4 = max(x|y) > (xn|yn)
		MOVQ		mm5,mm3 ;
		MOVQ		mm6,mm4 ;
		PAND		mm3,mm0 ; mm3 = ((xn|yn) < min(x|y)) ? (xn|yn) : (0|0)
		PANDN		mm4,mm0 ; mm4 = ((xn|yn) > max(x|y)) ? (xn|yn) : (0|0)
		PANDN		mm5,mm1 ; mm5 = ((xn|yn) > min(x|y)) ? min (x|y) : (0|0)
		PAND		mm6,mm2 ; mm6 = ((xn|yn) < max(x|y)) ? max (x|y) : (0|0)
		MOVQ		mm1,mm3
		MOVQ		mm2,mm4
		DEC		EBP
		POR		mm1,mm5
		POR		mm2,mm6
		JNZ		.PBoucMnMxXY

		MOVD		EAX,mm2 ; maxx
		MOVD		ECX,mm1 ; minx
		PSRLQ		mm2,32
		PSRLQ		mm1,32
		MOVD		EBX,mm2 ; maxy
		MOVD		EDX,mm1 ; miny

; poly clipper ? dans l'ecran ? hors de l'ecran ?
; poly clipper ?
		CMP		EAX,[_MaxX]
		JG		.PolyClip
		CMP		EBX,[_MaxY]
		JG		.PolyClip
		CMP		ECX,[_MinX]
		JL		.PolyClip
		CMP		EDX,[_MinY]
		JL		.PolyClip

; trace Poly non Clipper  **************************************************
		;JMP		.PolyClip

		MOV		ECX,[_OrgY]	 ; calcule DebYPoly, FinYPoly
		MOV		EAX,[ESI+EDI*4]
		ADD		EDX,ECX
		ADD		EBX,ECX
		MOV		[DebYPoly],EDX
		MOV		[FinYPoly],EBX
; calcule les bornes horizontal du poly
		MOV		EDX,EDI	; EDX compteur de point = NbPPoly-1
		MOV 		ECX,[EAX]
		MOV 		EBP,[EAX+4]
		MOV		[XP2],ECX
		MOV		[YP2],EBP
		@InCalculerContour
		MOV		EAX,[PType]
		CALL		[InFillPolyProc+EAX*4]
		JMP		.PasDrawPoly
.PolyClip:
; hors de l'ecran ? alors fin
		CMP		EAX,[_MinX]
		JL		.PasDrawPoly
		CMP		EBX,[_MinY]
		JL		.PasDrawPoly
		CMP		ECX,[_MaxX]
		JG		.PasDrawPoly
		CMP		EDX,[_MaxY]
		JG		.PasDrawPoly

; trace Poly Clipper  ******************************************************
		MOV		EAX,[_MaxY]	; determine DebYPoly, FinYPoly
		MOV		ECX,[_MinY]
		CMP		EBX,EAX
		JL		.PasSupMxY
		MOV		EBX,EAX
.PasSupMxY:	CMP		EDX,ECX
		JG		.PasInfMnY
		MOV		EDX,ECX
.PasInfMnY:
		MOV		EBP,[_OrgY]	  ; Ajuste [DebYPoly],[FinYPoly]
		MOV		EAX,[ESI+EDI*4]
		ADD		EDX,EBP
		ADD		EBX,EBP
		MOV		[DebYPoly],EDX
		MOV		[FinYPoly],EBX
		MOV		EDX,EDI ; ; EDX compteur de point = NbPPoly-1
		MOV 		ECX,[EAX]
		MOV 		EBP,[EAX+4]
		MOV		[XP2],ECX
		MOV		[YP2],EBP
		MOVD		mm4,ECX
		MOVD		mm5,EBP		; sauvegarde xp2,yp2
		@ClipCalculerContour

		CMP		DWORD [DebYPoly],BYTE (-1)
		JE		.PasDrawPoly
		MOV		EAX,[PType]
		CALL		[ClFillPolyProc+EAX*4]
.PasDrawPoly:
                POP             EDI
		POP             EBX
                POP             ESI
		;EMMS
		RETURN

.TstSiDblSide:	TEST		BYTE [EBP+TypePoly+3],POLY_FLAG_DBL_SIDED >> 24
		MOV		ECX,[NbPPoly]
		JZ		.PasDrawPoly
		DEC		ECX
		MOV		EBX,ESI ; = PtrListPt16 + 4
		LEA		EDI,[EBX+ECX*4]
		ADD		EBX,BYTE 4
		SHR		ECX,1

.BcSwapPts:	MOV		EAX,[EBX]
		MOV		EDX,[EDI]
		MOV		[EDI],EAX
		MOV		[EBX],EDX
		SUB		EDI,BYTE 4
		DEC		ECX
		LEA		EBX,[EBX+4]
		JNZ		.BcSwapPts
		JMP		.DrawPoly
.SpecialCase:
		MOV		ECX,[NbPPoly]
		CMP		ECX,BYTE 3
		JLE		.PasDrawPoly
; first loop fin any x or y not equal to P1
		DEC		ECX
		MOV		EAX,[XP1]
		MOV		ESI,[EBP+PtrListPt]
		MOV		EBX,[YP1]
		ADD		ESI,BYTE 8 ; jump over number of points + p1
.lpAnydiff:	MOV		EDI,[ESI]  ;
		CMP		EAX,[EDI] ; XP1 != XP[N]
		JNE		.finddiffP3
		CMP		EBX,[EDI+4] ; YP1 != YP[N]
		JNE		.finddiffP3
		DEC		ECX
		LEA		ESI,[ESI+4]
		JNZ		.lpAnydiff
		JMP		.PasDrawPoly ; failed

.finddiffP3:	MOV		EAX,[EDI]
		MOV		EBX,[EDI+4]
		MOV		[XP2],EAX
		MOV		[YP2],EBX
		DEC		ECX
		LEA		ESI,[ESI+4]
		JZ		.PasDrawPoly ; no more points ? :(
		SUB		EAX,[XP1] ; = XP2-XP1
		SUB		EBX,[YP1] ; = YP2-YP1

.lpPdiff:	MOV		EDI,[ESI]
		MOV		EDX,[EDI] ; XP3
		MOV		EDI,[EDI+4] ; YP3
		SUB		EDX,[XP2] ; XP3-XP2
		SUB		EDI,[YP2] ; YP3-YP2
		IMUL		EDX,EBX ; = (YP2-YP1)*(XP3-XP2)
		IMUL		EDI,EAX ; = (XP2-XP1)*(YP3-YP2)
		SUB		EDI,EDX
		JNZ		.P3ok
		DEC		ECX
		LEA		ESI,[ESI+4]
		JNZ		.lpPdiff
		JMP		.PasDrawPoly ; failed
.P3ok:		MOV		ESI,[EBP+PtrListPt]
		LEA		ESI,[ESI+4]
		JL		.TstSiDblSide
		JMP		.DrawPoly

;************************************************
;------------------------------------------------
; 16bpp *****************************************
;------------------------------------------------
;************************************************

ALIGN 32
_OutText16:
	ARG	Str16, 4
		MOVD		mm0,ESI
		MOVD		mm1,EDI
		MOVD		mm2,EBX

		MOV		EBX,[_FntPtr]
		OR		EBX,EBX
		JZ		.FinOutText
		MOV		ESI,[EBP+Str16]
		XOR		EAX,EAX
.BcOutChar:
		LODSB
		MOVD		mm3,ESI
		MOVD		mm4,EAX
		MOVD		mm5,EBX
		OR		AL,AL
		JZ		.FinOutText
;**************** Affichage et traitement **********************************
;***************************************************************************
		CMP		AL,13		 ;** Debut Cas Special
		MOVSX		ESI,BYTE [EBX+EAX*8+4] ; PlusX
		JE		.DebLigne
		XOR		EDX,EDX
		CMP		AL,10
		MOV		DL,[EBX+EAX*8+7] ;Largeur
		JE		.DebNextLigne
		XOR		ECX,ECX
		CMP		AL,9
		MOV		CL,[EBX+EAX*8+6] ; Haut
		JE		.TabCar	 ;** Fin   Cas Special
		MOVSX		EDI,BYTE [EBX+EAX*8+5] ; PlusLgn
		MOV		[ChLarg],EDX
		MOV		[ChPlusX],ESI
		MOVD		mm6,[EBX+EAX*8]        ; PtrDat
		OR		ESI,ESI
		MOV		[ChPlusLgn],EDI
		MOV		[ChHaut],ECX
		JNS		.GauchDroit
		JZ		.RienZero1
		LEA		EAX,[ESI+1]
		ADD		[_FntX],EAX
.GauchDroit:
.RienZero1:
		MOV		EBP,[_FntX]  ; MinX
		ADD		EDI,[_FntY]  ; MinY
		LEA		EBX,[EBP+EDX-1] ; MaxX: EBX=MinX+Larg-1
		LEA		ESI,[EDI+ECX-1] ; MaxY: ESI=MinY+Haut-1

		CMP		EBX,[_MaxX]
		JG		.CharClip
		CMP		ESI,[_MaxY]
		JG		.CharClip
		CMP		EBP,[_MinX]
		JL		.CharClip
		CMP		EDI,[_MinY]
		JL		.CharClip
;****** trace caractere IN *****************************
.CharIn:
		MOV		ECX,[_ScanLine]
		MOV		EBP,EDX ;Largeur
		IMUL		EDI,ECX
		LEA		ECX,[ECX+EDX*2]
		NEG		EDI
		MOV		[ChPlus],ECX
		ADD		EDI,[_FntX]
		ADD		EDI,[_FntX]
		MOV		EDX,[ChHaut]
		ADD		EDI,[_vlfb]
		XOR		EAX,EAX
		MOVD		ESI,mm6
		MOV		EAX,[_FntCol]
.LdNext:	MOV		EBX,[ESI]
		MOV		CL,32
		ADD		ESI,BYTE 4
;ALIGN 4
.BcDrCarHline:	TEST		BL,1
		JZ		.PasDrPixel
		MOV		[EDI],AX
.PasDrPixel:
		SHR		EBX,1
		DEC		EBP
		LEA		EDI,[EDI+2]
		JZ		.FinDrCarHline
		DEC		CL
		JNZ		.BcDrCarHline
		JZ		.LdNext
;ALIGN 4
.FinDrCarHline:	MOV		EBX,[ESI]
		SUB		EDI,[ChPlus]
		MOV		CL,32
		LEA		ESI,[ESI+4]
		DEC		DL
		MOV 		EBP,[ChLarg]
		JNZ		.BcDrCarHline
		JMP		.FinDrChar
;****** Trace Caractere Clip ***************************
.CharClip:
		CMP		EBX,[_MinX]
		JL		.FinDrChar
		CMP		ESI,[_MinY]
		JL		.FinDrChar
		CMP		EBP,[_MaxX]
		JG		.FinDrChar
		CMP		EDI,[_MaxY]
		JG		.FinDrChar
		; traitement MaxX********************************************
		CMP		EBX,[_MaxX]	; MaxX>_MaxX
		MOV		EAX,EBX
		JLE		.PasApPlus
		SUB		EAX,[_MaxX]	; DXAp = EAX = MaxX-_MaxX
		SUB		EDX,EAX 	; EDX = Larg-DXAp
		CMP		EAX,BYTE 32
		JL		.PasApPlus
		MOV		DWORD [ChApPlus],4
		JMP		SHORT .ApPlus
.PasApPlus:	XOR		EAX,EAX
		MOV		[ChApPlus],EAX
.ApPlus:
		; traitement MinX********************************************
		MOV		EAX,[_MinX]
		SUB		EAX,EBP
		JLE		.PasAvPlus
		SUB		EDX,EAX

		CMP		EAX,BYTE 32
		JL		.PasAvPlus2
		MOV		DWORD [ChAvPlus],4
		SUB		AL,32
		MOV		AH,32
		MOV		[ChAvDecal],AL
		SUB		AH,AL
		MOV		[ChNbBitDat],AH
		JMP		SHORT .AvPlus
.PasAvPlus2:
		MOV		AH,32
		MOV		[ChAvDecal],AL
		SUB		AH,AL
		MOV		[ChNbBitDat],AH
		XOR		EAX,EAX
		MOV		[ChAvPlus],EAX
		JMP		SHORT .AvPlus
.PasAvPlus:	XOR		EAX,EAX
		MOV		BYTE [ChNbBitDat],32
		MOV		[ChAvPlus],EAX
		MOV		[ChAvDecal],AL
.AvPlus:
		; traitement MaxY********************************************
		CMP		ESI,[_MaxY]	; MaxY>_MaxY
		MOV		EAX,ESI
		JLE		.PasSupMaxY
		SUB		EAX,[_MaxY]	; DY = EAX = MaxY-_MaxY
		SUB		ECX,EAX 	; ECX = Haut-DY
.PasSupMaxY:
		; traitement MinY********************************************
		MOV		EAX,[_MinY]
		SUB		EAX,EDI
		JLE		.PasInfMinY
		SUB		ECX,EAX
		MOV		EDI,[_MinY]
		CMP		DWORD [ChLarg],BYTE 32
		JLE		.Larg1DD
.Larg2DD:	IMUL		EAX,8
		MOVD		mm7,EAX
		PADDD		mm6,mm7
		JMP		SHORT .PasInfMinY
.Larg1DD:	IMUL		EAX,4
		MOVD		mm7,EAX
		PADDD		mm6,mm7
.PasInfMinY:
		MOV		[ChHaut],ECX
		MOV		[ChLarg],EDX
;************************************************
		MOV		ECX,[_ScanLine]
		MOV		EBP,EDX ;Largeur
		IMUL		EDI,ECX
		XOR		EAX,EAX
		LEA		ECX,[ECX+EDX*2] ;
		MOV		AL,[ChAvDecal]
		NEG		EDI
		MOV		[ChPlus],ECX
		ADD		EDI,[_FntX]
		ADD		EDI,[_FntX]  ; 2*_FntX 16bpp
		LEA		EDI,[EDI+EAX*2]      ; EDI +=2*ChAvDecal
		MOV		EDX,[ChHaut]
		ADD		EDI,[_vlfb]
		MOVD		ESI,mm6

		MOV		EAX,[_FntCol]  ;*************
		ADD		ESI,[ChAvPlus]
		MOV		EBX,[ESI]
		MOV		CL,[ChAvDecal]
		MOV		CH,[ChNbBitDat]
		ADD		ESI,BYTE 4
		SHR		EBX,CL
		JMP		SHORT .CBcDrCarHline

.CLdNext:	MOV		EBX,[ESI]
		MOV		CH,32
		ADD		ESI,BYTE 4
;ALIGN 4
.CBcDrCarHline:	TEST		BL,1
		JZ		.CPasDrPixel
		MOV		[EDI],AX
.CPasDrPixel:
		SHR		EBX,1
		DEC		EBP
		LEA		EDI,[EDI+2]
		JZ		.CFinDrCarHline
		DEC		CH
		JNZ		.CBcDrCarHline
		JZ		.CLdNext
;ALIGN 4
.CFinDrCarHline:
		ADD		ESI,[ChApPlus]
		SUB		EDI,[ChPlus]
		ADD		ESI,[ChAvPlus]
		MOV		EBX,[ESI]
		MOV		CL,[ChAvDecal]
		MOV		CH,[ChNbBitDat]
		SHR		EBX,CL
		LEA		ESI,[ESI+4]
		DEC		DL
		MOV 		EBP,[ChLarg]
		JNZ		.CBcDrCarHline

.FinDrChar:;********************************************
		MOV		ESI,[ChPlusX]
		OR		ESI,ESI
		JS		.DroitGauch
		JZ		.RienZero2
		ADD		[_FntX],ESI
.DroitGauch:
.RienZero2:	OR		ESI,ESI
		JNS		.GauchDroit2
		JZ		.RienZero3
		MOV		EAX,[_FntX]
		DEC		EAX
		MOV		[_FntX],EAX
.GauchDroit2:
.RienZero3:
		JMP		SHORT .Norm

.DebNextLigne:	XOR		EAX,EAX 	      ;***debut trait Cas sp
		MOV		AL,[_FntDistLgn]
		MOV		EBX,[_FntY]
		SUB		EBX,EAX
		MOV		[_FntY],EBX
.DebLigne:	MOV		AL,[_FntSens]
		OR		AL,AL
		JZ		.GchDrt
		MOV		EBX,[_MaxX]
		JMP		SHORT .DrtGch
.GchDrt:	MOV		EBX,[_MinX]
.DrtGch:
		MOV		[_FntX],EBX
		JMP		SHORT .Norm
.TabCar:	MOV		AL,32	     ; TAB
		MOV		ESI,[_FntX]
		MOVZX		ECX,BYTE [_FntTab]
		MOVSX		EAX,BYTE [EBX+EAX*8+4] ; PlusX
		IMUL		ECX,EAX
		ADD		ESI,ECX
		MOV		[_FntX],ESI	;***********fin trait Cas sp
;*** FIN ******** Affichage et traitement **********************************
;***************************************************************************
.Norm:		MOVD		ESI,mm3
		MOVD		EAX,mm4
		MOVD		EBX,mm5
		JMP		.BcOutChar
.FinOutText:
		MOVD		ESI,mm0
		MOVD		EDI,mm1
		MOVD		EBX,mm2
		;EMMS
		RETURN


; structure point { DWORD X, DWORD Y }
_PutPixel16:
	ARG	PtrPoint16, 4, col16, 4

		MOV		EDX,[EBP+PtrPoint16]
		MOV		EAX,[_ScanLine]
		IMUL		EAX,[EDX+4]
		MOV		ECX,[EDX]
		NEG		EAX
		MOV		EDX,[EBP+col16]
		ADD		EAX,[_vlfb]
		MOV		[EAX+ECX*2],DX
		RETURN

_GetPixel16:
	ARG	PtrGPoint16, 4

		MOV		EDX,[EBP+PtrGPoint16]
		MOV		ECX,[_ScanLine]
		IMUL		ECX,[EDX+4]
		NEG		ECX
		XOR		EAX,EAX
		MOV		EDX,[EDX]
		ADD		ECX,[_vlfb]
		MOV		AX,[ECX+EDX*2]

		RETURN

_Clear16:
	ARG	clrcol16, 4

		MOVD		mm7,EDI
		MOVD		mm0,[EBP+clrcol16]
		MOVD		mm6,ESI
		MOVD		mm5,EBX

		PUNPCKLWD	mm0,mm0 ; save firt 2 bytes color 16bpp
		MOV		ESI,[_SizeSurf]
		PUNPCKLDQ	mm0,mm0
		MOV		EDI,[_rlfb]
		MOVD		EAX,mm0
		SHR		ESI,1

		@SolidHLine16

		MOVD		EDI,mm7
		MOVD		ESI,mm6
		MOVD		EBX,mm5
		;EMMS
		RETURN


;****************************************************************************
;struct of PtrlistPt
;0‚		  DWORD : n count of PtrPoint
;1‚.. n‚  DWORD : PtrP1(X1,Y1,Z1,XT1,YT1)...PtrPn(Xn,Yn,Zn,XTn,YTn)
;****************************************************************************
; TypePoly POLY16_SOLID				= 0	FIELDS USED (X,Y)
; TypePoly POLY16_TEXT				= 1	FIELDS USED (X,Y,XT,YT)
; TypePoly POLY16_MASK_TEXT			= 2	FIELDS USED (X,Y,XT,YT)
; TypePoly POLY16_SOLID_BLND		= 13	CHAMPS UTILISER (X,Y)
; TypePoly POLY16_TEXT_BLND			= 14	CHAMPS UTILISER (X,Y)
; TypePoly POLY16_MASK_TEXT_BLND	= 15	CHAMPS UTILISER (X,Y)
;****************************************************************************
; FLAGS :
POLY_FLAG_DBL_SIDED16		EQU	0x80000000
DEL_POLY_FLAG_DBL_SIDED16	EQU	0x7FFFFFFF

;****************************************************************************
ALIGN 32
_Poly16:
	ARG	PtrListPt16, 4, SSurf16, 4, TypePoly16, 4, ColPoly16, 4

		PUSH            ESI
		PUSH            EBX
		MOV		ESI,[EBP+PtrListPt16]
		PUSH            EDI

		LODSD		; MOV EAX,[ESI];  ADD ESI,4
		MOV		[NbPPoly],EAX
		MOV		ECX,[ESI+8]
		MOV		EAX,[ESI]
		MOV		EBX,[ESI+4]
		MOVQ		mm0,[EAX] ; = XP1, YP1
		MOVQ		mm1,[EBX] ; = XP2, YP2
		MOVQ		mm2,[ECX] ; = XP3, YP3
		MOVQ		mm3,mm0 ; = XP1, YP1
		MOVQ		mm4,mm1 ; = XP2, YP2
		MOVQ		[XP1],mm0 ; XP1, YP1

;(XP2-XP1)*(YP3-YP2)-(XP3-XP2)*(YP2-YP1)
; s'assure que les points suive le sens inverse de l'aiguille d'une montre
.verifSens:
		PSUBD		mm1,mm0 ; = (XP2-XP1) | (YP2 - YP1)
		PSUBD		mm2,mm4 ; = (XP3-XP2) | (YP3 - YP2)
		MOVD		EAX,mm1 ; = (XP2-XP1)
		MOVD		EDX,mm2 ; = (XP3-XP2)
		PSRLQ		mm1,32
		PSRLQ		mm2,32
		MOVD		EDI,mm1 ; = (YP2-YP1)
		MOVD		EBX,mm2 ; = (YP3-YP2)
		IMUL		EDI,EDX
		IMUL		EAX,EBX
		CMP		EAX,EDI

		JL		.TstSiDblSide ; si <= 0 alors pas ok
		JZ		.SpecialCase
;****************
.DrawPoly:
		; Sauvegarde les parametre et libere EBP
		MOV		EAX,[EBP+TypePoly16]
		MOV		EBX,[EBP+ColPoly16]
                AND             EAX,DEL_POLY_FLAG_DBL_SIDED16
		MOV		ECX,[EBP+SSurf16]
		MOV		[PType],EAX
		MOV		[clr],EBX
		MOV		[PPtrListPt],ESI
		MOV		EDI,[NbPPoly]
		MOV		[SSSurf],ECX
;-new born determination--------------
		MOV		EBP,EDI
		MOVQ		mm1,mm3 ; init min = XP1 | YP1
		MOVQ		mm2,mm3 ; init max = XP1 | YP1
		DEC		EBP ; = [NbPPoly] - 1
		DEC		EDI ; " "
.PBoucMnMxXY:
		MOV		EAX,[ESI+EBP*4] ; = XN, YN
		MOVQ		mm0,[EAX] ; = XN, YN
		MOVQ		mm3,mm1 ; = min (x|y)
		MOVQ		mm4,mm2 ; = max (x|y)
		PCMPGTD		mm3,mm0 ; mm3 = min(x|y) > (xn|yn)
		PCMPGTD		mm4,mm0 ; mm4 = max(x|y) > (xn|yn)
		MOVQ		mm5,mm3 ;
		MOVQ		mm6,mm4 ;
		PAND		mm3,mm0 ; mm3 = ((xn|yn) < min(x|y)) ? (xn|yn) : (0|0)
		PANDN		mm4,mm0 ; mm4 = ((xn|yn) > max(x|y)) ? (xn|yn) : (0|0)
		PANDN		mm5,mm1 ; mm5 = ((xn|yn) > min(x|y)) ? min (x|y) : (0|0)
		PAND		mm6,mm2 ; mm6 = ((xn|yn) < max(x|y)) ? max (x|y) : (0|0)
		MOVQ		mm1,mm3
		MOVQ		mm2,mm4
		DEC		EBP
		POR		mm1,mm5
		POR		mm2,mm6
		JNZ		.PBoucMnMxXY
		MOVD		EAX,mm2 ; maxx
		MOVD		ECX,mm1 ; minx
		PSRLQ		mm2,32
		PSRLQ		mm1,32
		MOVD		EBX,mm2 ; maxy
		MOVD		EDX,mm1 ; miny
;-----------------------------------------

; poly clipper ? dans l'ecran ? hors de l'ecran ?
		CMP		EAX,[_MaxX]
		JG		.PolyClip
		CMP		ECX,[_MinX]
		JL		.PolyClip
		CMP		EBX,[_MaxY]
		JG		.PolyClip
		CMP		EDX,[_MinY]
		JL		.PolyClip

; trace Poly non Clipper  **************************************************
		;JMP		.PolyClip

		MOV		ECX,[_OrgY]	 ; calcule DebYPoly, FinYPoly
		MOV		EAX,[ESI+EDI*4]
		ADD		EDX,ECX
		ADD		EBX,ECX
		MOV		[DebYPoly],EDX
		MOV		[FinYPoly],EBX
; calcule les bornes horizontal du poly
		MOV		EDX,EDI ; = NbPPoly - 1
		MOV		ECX,[EAX]
		MOV		EBP,[EAX+4]
		MOV		[XP2],ECX
		MOV		[YP2],EBP
		@InCalculerContour16
		MOV		EAX,[PType]
		CALL		[InFillPolyProc16+EAX*4]
		JMP		.PasDrawPoly
.PolyClip:
; outside view ? now draw !
		CMP		EAX,[_MinX]
		JL		.PasDrawPoly
		CMP		EBX,[_MinY]
		JL		.PasDrawPoly
		CMP		ECX,[_MaxX]
		JG		.PasDrawPoly
		CMP		EDX,[_MaxY]
		JG		.PasDrawPoly
; Drop too big poly
		; drop too BIG tri
		SUB		ECX,EAX  ; deltaY
		SUB		EDX,EBX  ; deltaX
		CMP		ECX,MaxDeltaDim
		JGE		.PasDrawPoly
		CMP		EDX,MaxDeltaDim
		JGE		.PasDrawPoly
		ADD		ECX,EAX ; restor MaxY
		ADD		EDX,EBX ; restor MaxX

; trace Poly Clipper  ******************************************************
		MOV		EAX,[_MaxY]	; determine DebYPoly, FinYPoly
		MOV		ECX,[_MinY]
		CMP		EBX,EAX
		JL		.PasSupMxY
		MOV		EBX,EAX
.PasSupMxY:	CMP		EDX,ECX
		JG		.PasInfMnY
		MOV		EDX,ECX
.PasInfMnY:
		MOV		EBP,[_OrgY]	  ; Ajuste [DebYPoly],[FinYPoly]
		MOV		EAX,[ESI+EDI*4]
		ADD		EDX,EBP
		ADD		EBX,EBP
		MOV		[DebYPoly],EDX
		MOV		[FinYPoly],EBX
		MOV		EDX,EDI ; EDX compteur de point = NbPPoly-1
		MOV 		ECX,[EAX]
		MOV 		EBP,[EAX+4]
		MOV		[XP2],ECX
		MOV		[YP2],EBP
		MOVD		mm4,ECX
		MOVD		mm5,EBP		; sauvegarde xp2,yp2
		@ClipCalculerContour ; use same as 8bpp as it compute xdeb and xfin for eax hzline

		CMP		DWORD [DebYPoly],BYTE (-1)
		JE		.PasDrawPoly
		MOV		EAX,[PType]
		CALL		[ClFillPolyProc16+EAX*4]
.PasDrawPoly:
        POP             EDI
		POP             EBX
        POP             ESI
		;EMMS
		RETURN

.TstSiDblSide:	TEST		BYTE [EBP+TypePoly+3],POLY_FLAG_DBL_SIDED16 >> 24
		MOV		ECX,[NbPPoly]
		JZ		.PasDrawPoly
		DEC		ECX
		MOV		EBX,ESI ; = PtrListPt16 + 4
		LEA		EDI,[EBX+ECX*4]
		ADD		EBX,BYTE 4
		SHR		ECX,1
.BcSwapPts:	MOV		EAX,[EBX]
		MOV		EDX,[EDI]
		MOV		[EDI],EAX
		MOV		[EBX],EDX
		SUB		EDI,BYTE 4
		DEC		ECX
		LEA		EBX,[EBX+4]
		JNZ		.BcSwapPts
		JMP		.DrawPoly

.SpecialCase:
		MOV		ECX,[NbPPoly]
		CMP		ECX,BYTE 3
		JLE		.PasDrawPoly
; first loop fin any x or y not equal to P1
		DEC		ECX
		MOV		EAX,[XP1]
		MOV		ESI,[EBP+PtrListPt16]
		MOV		EBX,[YP1]
		ADD		ESI,BYTE 8 ; jump over number of points + p1
.lpAnydiff:	MOV		EDI,[ESI]  ;
		CMP		EAX,[EDI] ; XP1 != XP[N]
		JNE		.finddiffP3
		CMP		EBX,[EDI+4] ; YP1 != YP[N]
		JNE		.finddiffP3
		DEC		ECX
		LEA		ESI,[ESI+4]
		JNZ		.lpAnydiff
		JMP		.PasDrawPoly ; failed

.finddiffP3:	MOV		EAX,[EDI]
		MOV		EBX,[EDI+4]
		MOV		[XP2],EAX
		MOV		[YP2],EBX
		DEC		ECX
		LEA		ESI,[ESI+4]
		JZ		.PasDrawPoly ; no more points ? :(
		SUB		EAX,[XP1] ; = XP2-XP1
		SUB		EBX,[YP1] ; = YP2-YP1

.lpPdiff:	MOV		EDI,[ESI]
		MOV		EDX,[EDI] ; XP3
		MOV		EDI,[EDI+4] ; YP3
		SUB		EDX,[XP2] ; XP3-XP2
		SUB		EDI,[YP2] ; YP3-YP2
		IMUL		EDX,EBX ; = (YP2-YP1)*(XP3-XP2)
		IMUL		EDI,EAX ; = (XP2-XP1)*(YP3-YP2)
		SUB		EDI,EDX
		JNZ		.P3ok
		DEC		ECX
		LEA		ESI,[ESI+4]
		JNZ		.lpPdiff
		JMP		.PasDrawPoly ; failed
.P3ok:		MOV		ESI,[EBP+PtrListPt16]
		LEA		ESI,[ESI+4]
		JL		.TstSiDblSide
		JMP		.DrawPoly


SECTION	.data
ALIGN 32
_CurSurf:
_vlfb			DD	0
_ResH 			DD	0
_ResV 			DD	0
_MaxX 			DD	0
_MaxY 			DD	0
_MinX 			DD	0
_MinY 			DD	0
_OrgY			DD	0;-----------------------
_OrgX			DD	0
_SizeSurf		DD	0
_OffVMem		DD	0
_rlfb			DD	0
_BitsPixel  	DD  0
_ScanLine   	DD	0
_Mask  			DD	0
_Resv2  		DD	0 ;-----------------------
; source texture
_SrcSurf:
Svlfb			DD	0
SResH			DD	0
SResV			DD	0
SMaxX			DD	0
SMaxY			DD	0
SMinX			DD	0
SMinY			DD	0
SOrgY			DD	0;-----------------------
SOrgX			DD	0
SSizeSurf		DD	0
SOffVMem		DD	0
Srlfb			DD	0
SBitsPixel  	DD  0
SScanLine   	DD	0
SMask			DD	0
SResv2  		DD	0;-----------------------

XP1				DD	0
YP1				DD	0
XP2				DD	0
YP2				DD	0
XP3				DD	0
YP3				DD	0
Plus			DD	0
clr				DD	0;-----------------------
XT1				DD	0
YT1				DD	0
XT2				DD	0
YT2				DD	0
Col1			DD	0
Col2			DD	0
revCol			DD	0
_CurViewVSurf	DD	0;-----------------------
PMaxX			DD	0
PMaxY			DD	0
PMinX			DD	0
PMinY			DD	0
NbPPoly			DD	0
DebYPoly		DD	0
FinYPoly		DD	0
PType			DD	0;-----------------------
PType2			DD	0
PPtrListPt		DD	0
SSSurf			DD	0
PntPlusX		DD	0
PntPlusY		DD	0
PlusX			DD	0
PlusY			DD	0
Plus2			DD	0;-----------------------
_CurFONT:
_FntPtr			DD	0
_FntHaut		DB	0
_FntDistLgn		DB	0
_FntLowPos		DB	0
_FntHighPos		DB	0
_FntSens		DB	0
_FntTab			DB	0,0,0 ; 2 DB reserv
_FntX			DD	0
_FntY			DD	0
_FntCol			DD	0
FntResv			DD	0,0;---------------------
ChHaut			DD	0
ChLarg			DD	0
ChPlus			DD	0
ChPlusX			DD	0
ChPlusLgn		DD	0
ChAvPlus		DD	0
ChApPlus		DD	0
ChAvDecal		DB	0
ChNbBitDat		DB	0
ChResvW			DW	0;-----------------------
Temp			DD	0,0
QMulSrcBlend	DD	0,0
QMulDstBlend	DD	0,0
PlusCol			DD	0
PtrTbDegCol		DD	0;-----------------------
_PtrTbColConv	DD	0
PntInitCPTDbrd	DD	0,((1<<Prec)-1)
Temp2			DD	0
MaskB_RGB16		DD	0x1f	 ; blue bits 0->4
MaskG_RGB16		DD	0x3f<<5  ; green bits 5->10
MaskR_RGB16		DD	0x1f<<11 ; red bits 11->15
RGB16_PntNeg	DD	((1<<Prec)-1) ;----------
Mask2B_RGB16	DD	0x1f,0x1f ; blue bits 0->4
Mask2G_RGB16	DD	0x3f<<5,0x3f<<5  ; green bits 5->10 ;----------
Mask2R_RGB16	DD	0x1f<<11,0x1f<<11 ; red bits 11->15
RGBDebMask_GGG	DD	0,0,0,0
RGBDebMask_IGG	DD	((1<<Prec)-1),0,0,0
RGBDebMask_GIG	DD	0,((1<<(Prec+5))-1),0,0
RGBDebMask_IIG	DD	((1<<Prec)-1),((1<<(Prec+5))-1),0,0
RGBDebMask_GGI	DD	0,0,((1<<(Prec+11))-1),0
RGBDebMask_IGI	DD	((1<<Prec)-1),0,((1<<(Prec+11))-1),0
RGBDebMask_GII	DD	0,((1<<(Prec+5))-1),((1<<(Prec+11))-1),0
RGBDebMask_III	DD	((1<<Prec)-1),((1<<(Prec+5))-1),((1<<(Prec+11))-1),0

RGBFinMask_GGG	DD	((1<<Prec)-1),((1<<(Prec+5))-1),((1<<(Prec+11))-1),0
RGBFinMask_IGG	DD	0,((1<<(Prec+5))-1),((1<<(Prec+11))-1),0
RGBFinMask_GIG	DD	((1<<Prec)-1),0,((1<<(Prec+11))-1),0
RGBFinMask_IIG	DD	0,0,((1<<(Prec+11))-1),0
RGBFinMask_GGI	DD	((1<<Prec)-1),((1<<(Prec+5))-1),0,0
RGBFinMask_IGI	DD	0,((1<<(Prec+5))-1),0,0
RGBFinMask_GII	DD	((1<<Prec)-1),0,0,0
RGBFinMask_III	DD	0,0,0,0
; BLENDING 16BPP ----------
QBlue16Mask		DW	CMaskB_RGB16,CMaskB_RGB16,CMaskB_RGB16,CMaskB_RGB16
QGreen16Mask	DW	CMaskG_RGB16,CMaskG_RGB16,CMaskG_RGB16,CMaskG_RGB16
QRed16Mask		DW	CMaskR_RGB16,CMaskR_RGB16,CMaskR_RGB16,CMaskR_RGB16
QBlue16Blend	DD	0,0
QGreen16Blend	DD	0,0
QRed16Blend		DD	0,0

;* 8bpp poly proc****
InFillPolyProc:	DD	InFillSOLID,InFillTEXT,InFillMASK_TEXT,InFillFLAT_DEG,InFillDEG
				DD	InFillFLAT_DEG_TEXT,InFillMASK_FLAT_DEG_TEXT
				DD	InFillDEG_TEXT,InFillMASK_DEG_TEXT,InFillEFF_FDEG
				DD	InFillEFF_DEG,InFillEFF_COLCONV
ClFillPolyProc:	DD	ClipFillSOLID,ClipFillTEXT,ClipFillMASK_TEXT,ClipFillFLAT_DEG,ClipFillDEG
				DD	ClipFillFLAT_DEG_TEXT,ClipFillMASK_FLAT_DEG_TEXT
				DD	ClipFillDEG_TEXT,ClipFillMASK_DEG_TEXT
				DD	ClipFillEFF_FDEG,ClipFillEFF_DEG,ClipFillEFF_COLCONV

;* 16bpp poly proc****
InFillPolyProc16:
				DD	InFillSOLID16,InFillTEXT16,InFillMASK_TEXT16,InFillFLAT_DEG,InFillDEG
				DD	InFillFLAT_DEG_TEXT,InFillMASK_FLAT_DEG_TEXT
				DD	InFillDEG_TEXT,InFillMASK_DEG_TEXT,InFillEFF_FDEG
				DD	InFillEFF_DEG,InFillEFF_COLCONV
				DD	InFillRGB16,InFillSOLID_BLND16,InFillTEXT_BLND16,InFillMASK_TEXT_BLND16

ClFillPolyProc16:
				DD	ClipFillSOLID16,ClipFillTEXT16,ClipFillMASK_TEXT16,ClipFillFLAT_DEG,ClipFillDEG
				DD	ClipFillFLAT_DEG_TEXT,ClipFillMASK_FLAT_DEG_TEXT
				DD	ClipFillDEG_TEXT,ClipFillMASK_DEG_TEXT
				DD	ClipFillEFF_FDEG,ClipFillEFF_DEG,ClipFillEFF_COLCONV
				DD	ClipFillRGB16,ClipFillSOLID_BLND16,ClipFillTEXT_BLND16,ClipFillMASK_TEXT_BLND16

