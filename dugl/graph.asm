%include "param.mac"

; GLOBAL Function****
; 8bpp
GLOBAL	_PutPixel,_GetPixel,_line,_Line,_linemap,_LineMap,_DgSetCurSurf,_SurfCopy
GLOBAL	_DgSetSrcSurf,_DgGetCurSurf,_Clear,_ProtectSetPalette,_ProtectViewSurf
GLOBAL	_ProtectViewSurfWaitVR,_WaitRetrace,_GetMaxResVSetSurf
;********************
GLOBAL	_Poly, _RePoly, _SensPoly,_ValidSPoly,_PutSurf,_PutMaskSurf
GLOBAL	_InRLE,_OutRLE,_SizeOutRLE,_InLZW
; 16bpp
GLOBAL	_PutPixel16,_GetPixel16
GLOBAL	_PutSurf16,_PutMaskSurf16,_PutSurfBlnd16,_PutMaskSurfBlnd16
GLOBAL	_PutSurfTrans16,_PutMaskSurfTrans16
GLOBAL	_SurfCopyBlnd16,_SurfMaskCopyBlnd16,_SurfCopyTrans16,_SurfMaskCopyTrans16
GLOBAL	_line16,_Line16,_linemap16,_LineMap16,_lineblnd16,_LineBlnd16
GLOBAL	_linemapblnd16,_LineMapBlnd16,_Poly16, _RePoly16, _Clear16
GLOBAL	_ResizeViewSurf16,_MaskResizeViewSurf16,_BlndResizeViewSurf16


; GLOBAL DATA
GLOBAL	_CurViewVSurf, _CurSurf, _SrcSurf
GLOBAL	_PtrTbColConv, _LastPolyStatus
; intern global DATA
; _CurSurf
GLOBAL	_vlfb,_ResH,_ResV,_MaxX,_MaxY,_MinX, _MinY, _OrgY, _OrgX, _SizeSurf
GLOBAL	_OffVMem, _rlfb, _BitsPixel, _ScanLine, _Mask, _NegScanLine


; EXTERN DATA
EXTERN	_SetPalPMI, _CurPalette, _ShiftPal, _ViewAddressPMI, _VSurf, _NbVDgSurf
EXTERN	_EnableMPIO,_SelMPIO
; --Poly-----
EXTERN	_TPolyAdDeb, _TPolyAdFin, _TexXDeb, _TexXFin, _TexYDeb, _TexYFin
EXTERN	_PColDeb, _PColFin, _TbDegCol
; --GIF------
Prec					EQU	12
MaxResV					EQU	4096
BlendMask				EQU	0x1f
SurfUtilSize    		EQU 64
CMaskB_RGB16			EQU	0x1f	 ; blue bits 0->4
CMaskG_RGB16			EQU	0x3f<<5  ; green bits 5->10
CMaskR_RGB16			EQU	0x1f<<11 ; red bits 11->15
MaxDeltaDim				EQU	1<< (31-Prec)
MaxDblSidePolyPts    	EQU 256

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

;*********** DEF LZW*****************************
;************************************************
ClrAb			EQU	256
EndOF			EQU	257

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
		MOV		[DStack+EDI],AL
		INC		EDI
.PasCasSpecial:
.BoucDecodLZW:	CMP		EDX,ClrAb
		JA		.PasConcret
.Concret:	MOV		[DStack+EDI],EDX
		MOV		[CasSpecial],EDX
		MOV		[DStackPtr],EDI
		JMP		.FinDecodeLZW
.PasConcret:	MOV		AL,[Suffix+EDX]
		MOV		EDX,[Prefix+EDX*4]
		MOV		[DStack+EDI],AL
		INC		EDI
		JMP		.BoucDecodLZW
.FinDecodeLZW:
		; vide la pile de decodage dans le buff out
		MOV		ESI,[DStackPtr]
		MOVD		EDI,mm4
.BoucVidStack:	MOV		AL,[DStack+ESI]
		STOSB
		DEC		ESI
		JNS		.BoucVidStack
		MOVD		mm4,EDI       ; [OutBuffIndex]
;**** DECODAGE ------ FIN
		MOV		EAX,[FreeAb]
		MOV		ECX,[Prefix_Code]
		MOV		[Prefix+EAX*4],ECX
		MOV		DL,[CasSpecial]
		MOV		[Suffix+EAX],DL

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

_DgSetCurSurf:
	ARG	S1, 4

		PUSH		EDI
		PUSH	    ESI

		MOV			ESI,[EBP+S1]
		MOV			EAX,[ESI+_ResV-_CurSurf]
		CMP			EAX,MaxResV
		JG			.Error
		MOV			EDI,_CurSurf
		CopySurf
		OR			EAX,BYTE -1
		JMP			SHORT .Ok
.Error:
		XOR		EAX,EAX
.Ok:
		POP		ESI
		POP     EDI

	RETURN

ALIGN 32
_DgSetSrcSurf:
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

_DgGetCurSurf:
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
		CMP			ECX,[_NbVDgSurf]
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
		CMP			ECX,[_NbVDgSurf]
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

		MOV		EDX,[EBP+PtrPoint]
		MOV		CL,[EBP+col]
		MOV		EAX,[EDX+4]
		MOV		EDX,[EDX]
		IMUL	EAX,[_NegScanLine]
		ADD		EAX,[_vlfb]
		MOV		[EAX+EDX],CL
		RETURN

_GetPixel:
	ARG	PtrGPoint, 4

		MOV		EDX,[EBP+PtrGPoint]
		MOV		ECX,[_NegScanLine]
		IMUL	ECX,[EDX+4]
		XOR		EAX,EAX
		MOV		EDX,[EDX]
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




_ValidSPoly:
	ARG	VPtrListPt, 4
		MOVD		mm7,ESI
		MOVD		mm6,EBX

		MOV			ESI,[EBP+VPtrListPt]

		MOV			ECX,[ESI+8]
		MOV			EAX,[ESI]
		MOV			EBX,[ESI+4]
		MOVQ		mm0,[EAX] ; = XP1, YP1
		MOVQ		mm1,[EBX] ; = XP2, YP2
		MOVQ		mm2,[ECX] ; = XP3, YP3
		MOVQ		mm3,mm0 ; = XP1, YP1
		MOVQ		mm4,mm1 ; = XP2, YP2

;(XP2-XP1)*(YP3-YP2)-(XP3-XP2)*(YP2-YP1)
; s'assure que les points suive le sens inverse de l'aiguille d'une montre
.verifSens:
		PSUBD		mm1,mm0 ; = (XP2-XP1) | (YP2 - YP1)
		PSUBD		mm2,mm4 ; = (XP3-XP2) | (YP3 - YP2)
		MOVD		ECX,mm1 ; = (XP2-XP1)
		MOVD		EDX,mm2 ; = (XP3-XP2)
		PSRLQ		mm1,32
		PSRLQ		mm2,32
		MOVD		ESI,mm1 ; = (YP2-YP1)
		MOVD		EBX,mm2 ; = (YP3-YP2)
		IMUL		ESI,EDX
		IMUL		ECX,EBX
		XOR			EAX,EAX
		CMP			ECX,ESI
		SETG		AL

		MOVD		EBX,mm6
		MOVD		ESI,mm7
		;EMMS
	RETURN

_SensPoly:
	ARG	VSPtrListPt, 4

		MOVD		mm7,ESI
		MOVD		mm6,EBX

		MOV			ESI,[EBP+VSPtrListPt]

		MOV			ECX,[ESI+8]
		MOV			EAX,[ESI]
		MOV			EBX,[ESI+4]
		MOVQ		mm0,[EAX] ; = XP1, YP1
		MOVQ		mm1,[EBX] ; = XP2, YP2
		MOVQ		mm2,[ECX] ; = XP3, YP3
		MOVQ		mm3,mm0 ; = XP1, YP1
		MOVQ		mm4,mm1 ; = XP2, YP2

;(XP2-XP1)*(YP3-YP2)-(XP3-XP2)*(YP2-YP1)
; s'assure que les points suive le sens inverse de l'aiguille d'une montre
.verifSens:
		PSUBD		mm1,mm0 ; = (XP2-XP1) | (YP2 - YP1)
		PSUBD		mm2,mm4 ; = (XP3-XP2) | (YP3 - YP2)
		MOVD		EAX,mm1 ; = (XP2-XP1)
		MOVD		EDX,mm2 ; = (XP3-XP2)
		PSRLQ		mm1,32
		PSRLQ		mm2,32
		MOVD		ESI,mm1 ; = (YP2-YP1)
		MOVD		EBX,mm2 ; = (YP3-YP2)
		IMUL		ESI,EDX
		IMUL		EAX,EBX
		SUB			EAX,ESI

		MOVD		EBX,mm6
		MOVD		ESI,mm7
		;EMMS
	RETURN

_RePoly:
    ARG RePtrListPt, 4, ReSSurf, 4, ReTypePoly, 4, ReColPoly, 4

            PUSH        ESI
            PUSH        EBX
            PUSH        EDI

            ;CMP         [LastPolyStatus], BYTE 'N'
            MOV         EAX,[EBP+ReTypePoly]
            MOV			EBX,[EBP+ReColPoly]
            ;JE			_Poly16.PasDrawPoly
            TEST		EAX,POLY_FLAG_DBL_SIDED
            JZ			SHORT .DblSideCheck ; not a double-sided RePoly16 ?
.doRePoly:
            AND         EAX,DEL_POLY_FLAG_DBL_SIDED
            MOV         ECX,[EBP+ReSSurf]
            MOV         [clr],EBX
            MOV         [SSSurf],ECX
            CMP         [_LastPolyStatus], BYTE 'I' ; last render IN ?
            JNE			.ClipRepoly
            JMP			[InFillPolyProc+EAX*4]
.ClipRepoly:
			JMP			[ClFillPolyProc+EAX*4]
.DblSideCheck:
			; if this is a reversed dbl_sided then skip repoly
			CMP			DWORD [PPtrListPt], ReversedPtrListPt
			JNE			SHORT .doRePoly
			JMP			_Poly.PasDrawPoly

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

		PUSH        ESI
		PUSH        EBX
		MOV			ESI,[EBP+PtrListPt]
		PUSH        EDI

		LODSD		; MOV EAX,[ESI];  ADD ESI,4
        MOV         [_LastPolyStatus], BYTE 'N' ; default no render
		MOV			[NbPPoly],EAX
		MOV			ECX,[ESI+8]
		MOV			EAX,[ESI]
		MOV			EBX,[ESI+4]
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
		CMP			EAX,EDI

		JL			.TstSiDblSide ; si <= 0 alors pas ok
		JZ			.PasDrawPoly ; ignore poly if first 3 points aligned

;****************
.DrawPoly:
		; Sauvegarde les parametre et libere EBP
		MOV			EAX,[EBP+TypePoly]
		MOV			EBX,[EBP+ColPoly]
		AND     	EAX,DEL_POLY_FLAG_DBL_SIDED16
		MOV			ECX,[EBP+SSurf]
		MOV			[PType],EAX
		MOV			[clr],EBX
		MOV			[PPtrListPt],ESI
		MOV			EDI,[NbPPoly]
		MOV			[SSSurf],ECX
;-new born determination--------------
		MOV			EBP,EDI
		MOVQ		mm1,mm3 ; init min = XP1 | YP1
		MOVQ		mm2,mm3 ; init max = XP1 | YP1
		DEC			EBP ; = [NbPPoly] - 1
		DEC			EDI ; " "
.PBoucMnMxXY:
		MOV			EAX,[ESI+EBP*4] ; = XN, YN
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
		DEC			EBP
		POR			mm1,mm5
		POR			mm2,mm6
		JNZ			.PBoucMnMxXY

		MOVD		EAX,mm2 ; maxx
		MOVD		ECX,mm1 ; minx
		PSRLQ		mm2,32
		PSRLQ		mm1,32
		MOVD		EBX,mm2 ; maxy
		MOVD		EDX,mm1 ; miny

; poly clipper ? dans l'ecran ? hors de l'ecran ?
; poly clipper ?
		CMP			EAX,[_MaxX]
		JG			.PolyClip
		CMP			EBX,[_MaxY]
		JG			.PolyClip
		CMP			ECX,[_MinX]
		JL			.PolyClip
		CMP			EDX,[_MinY]
		JL			.PolyClip

; trace Poly non Clipper  **************************************************
		;JMP		.PolyClip

		MOV			ECX,[_OrgY]	 ; calcule DebYPoly, FinYPoly
		MOV			EAX,[ESI+EDI*4]
		ADD			EDX,ECX
		ADD			EBX,ECX
		MOV			[DebYPoly],EDX
		MOV			[FinYPoly],EBX
; calcule les bornes horizontal du poly
		MOV			EDX,EDI	; EDX compteur de point = NbPPoly-1
		MOV 		ECX,[EAX]
		MOV 		EBP,[EAX+4]
		MOV			[XP2],ECX
		MOV			[YP2],EBP
		@InCalculerContour
		MOV			EAX,[PType]
        MOV         [_LastPolyStatus], BYTE 'I'; In render
		JMP			[InFillPolyProc+EAX*4]
		;JMP			.PasDrawPoly
.PolyClip:
; hors de l'ecran ? alors fin
		CMP			EAX,[_MinX]
		JL			.PasDrawPoly
		CMP			EBX,[_MinY]
		JL			.PasDrawPoly
		CMP			ECX,[_MaxX]
		JG			.PasDrawPoly
		CMP			EDX,[_MaxY]
		JG			.PasDrawPoly

; trace Poly Clipper  ******************************************************
		MOV			EAX,[_MaxY]	; determine DebYPoly, FinYPoly
		MOV			ECX,[_MinY]
		CMP			EBX,EAX
		JL			.PasSupMxY
		MOV			EBX,EAX
.PasSupMxY:
		CMP			EDX,ECX
		JG			.PasInfMnY
		MOV			EDX,ECX
.PasInfMnY:
		MOV			EBP,[_OrgY]	  ; Ajuste [DebYPoly],[FinYPoly]
		MOV			EAX,[ESI+EDI*4]
		ADD			EDX,EBP
		ADD			EBX,EBP
		MOV			[DebYPoly],EDX
		MOV			[FinYPoly],EBX
		MOV			EDX,EDI ; ; EDX compteur de point = NbPPoly-1
		MOV 		ECX,[EAX]
		MOV 		EBP,[EAX+4]
		MOV			[XP2],ECX
		MOV			[YP2],EBP
		MOVD		mm4,ECX
		MOVD		mm5,EBP		; sauvegarde xp2,yp2
		@ClipCalculerContour

		CMP			DWORD [DebYPoly],BYTE (-1)
		MOV			EAX,[PType]
		JE			.PasDrawPoly
        MOV         [_LastPolyStatus], BYTE 'C' ; Clip render
		JMP			[ClFillPolyProc+EAX*4]
.PasDrawPoly:

		POP         EDI
		POP         EBX
        POP         ESI
		;EMMS
	RETURN

.TstSiDblSide:
		TEST		BYTE [EBP+TypePoly+3],POLY_FLAG_DBL_SIDED >> 24
		MOV			ECX,[NbPPoly]
		JZ			.PasDrawPoly
		; swap all points except P1 !
		MOV         EAX,[ESI]
		MOV         EDX,ReversedPtrListPt
		DEC         ECX
		MOV         [EDX],EAX

		LEA         EDI,[ESI+ECX*4]
		LEA         EBX,[EDX+4] ; P1 already copied
		MOV         ESI,EDX ; update [PPtrListPt] In ESI
.BcSwapPts:
		MOV         EAX,[EDI]
		MOV         [EBX],EAX
		SUB         EDI,BYTE 4
		DEC         ECX
		LEA         EBX,[EBX+4]
		JNZ         SHORT .BcSwapPts
		JMP         .DrawPoly


; structure point { DWORD X, DWORD Y }
_PutPixel16:
	ARG	PtrPoint16, 4, col16, 4

		MOV		EAX,[EBP+PtrPoint16]
		MOV		EDX,[_NegScanLine]
		MOV		ECX,[EAX]
		IMUL	EDX,[EAX+4]
		MOV		EAX,[EBP+col16]
		ADD		EDX,[_vlfb]
		MOV		[EDX+ECX*2],AX
	RETURN

_GetPixel16:
	ARG	PtrGPoint16, 4

		MOV		EDX,[EBP+PtrGPoint16]
		MOV		ECX,[_NegScanLine]
		XOR		EAX,EAX
		IMUL	ECX,[EDX+4]
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
		MOV			ESI,[_SizeSurf]
		PUNPCKLDQ	mm0,mm0
		MOV			EDI,[_rlfb]
		MOVD		EAX,mm0
		SHR			ESI,1

		@SolidHLine16

		MOVD		EDI,mm7
		MOVD		ESI,mm6
		MOVD		EBX,mm5
		;EMMS
	RETURN
; == xxxResizeViewSurf16 =====================================

_ResizeViewSurf16:
    ARG SrcResizeSurf16, 4, ResizeRevertHz, 4, ResizeRevertVt, 4

            PUSH        ESI
            PUSH        EBX
            PUSH        EDI

            MOV         ESI,[EBP+SrcResizeSurf16]
            MOV         EDI,_SrcSurf
            XOR         EBX,EBX ; store flags revert Hz and Vt
            CopySurf  ; copy the source surface


            MOV         EAX,[EBP+ResizeRevertHz]
            MOV         EDX,[EBP+ResizeRevertVt]
            OR          EAX,EAX
            ; compute horizontal pnt in EBP
            MOV         EBP,[_MaxY]
            SETNZ       BL ; BL = RevertHz ?
            OR          EDX,EDX
            MOV         EAX,[SMaxX]
            SETNZ       BH ; BH = RevertVt ?
            MOV         EDI,[_MinY]
            MOV         ESI,[SMinX]
            PUSH        EBX ; save FLAGS Revert
            MOV         ECX,[_MaxX]
            SUB         EBP,EDI ; = (MaxY - MinY)
            MOV         EBX,[_MinX]
            INC         EBP ; = Delta_Y = (MaxY - MinY) + 1
            SUB         EAX,ESI
            IMUL        EDI,[_NegScanLine]
            SUB         ECX,EBX
            ADD         EDI,[_vlfb]
            MOV         [HzLinesCount],EBP ; count of hline
            MOVD        mm5,ESI ; SMinX
            INC         EAX
            LEA         EDI,[EDI+EBX*2]
            INC         ECX
            MOVD        mm6,EDI ; mm6 = start Hline dest
            MOVD        mm2,ECX ; mm2 = dest hline size
            MOV         EBX,[SMaxY]
            SHL         EAX,Prec
            MOV         EDI,EBP ; EDI = DeltaY
            XOR         EDX,EDX
            SUB         EBX,[SMinY]
            DIV         ECX
            INC         EBX ; Source DeltaYT
            SHL         EBX,Prec
            MOV         EBP,EAX
            XOR         EDX,EDX
            MOV         EAX,EBX
            DIV         EDI
            POP         EBX
            XOR         EDX,EDX ; EDX = acc PntX
            MOVD        mm7,[SMinY]
            PXOR        mm4,mm4 ; mm4 = acc pnt
            ;MOVD        ECX,mm5
            CMP         BL,0
            JZ          SHORT .NoRevertHz
            MOVD        mm5,[SMaxX] ; SMaxX
            MOV         EDX,[PntInitCPTDbrd+4] ; ((1<<Prec)-1)
            NEG         EBP ; revert Horizontal Pnt X
.NoRevertHz:
            CMP         BH,0
            MOV			DWORD [HzPntInit],EDX
            JZ          SHORT .NoRevertVt
            NEG         EAX ; negate PntY
            MOVD        mm7,[SMaxY] ; SMaxX
            MOVD        mm4,[PntInitCPTDbrd+4] ; ((1<<Prec)-1)
.NoRevertVt:
            MOVD        mm3,EAX ; xmm3  = pntY
            MOV			[PntPlusX],EBP

.BcResize:
            MOVQ        mm0,mm4
            MOVD        EBX,mm5 ; + [SMinX] | [SMaxX] (if RevertHz)
            PSRAD       mm0,Prec
            PADDD       mm0,mm7 ; + [SMinY] | [SMaxY] (if RevertVt)
            MOVD        EDI,mm6 ; start hline
            MOVD        ESI,mm0
            MOVD        ECX,mm2 ; dest hline size
            IMUL        ESI,[SNegScanLine] ; - 2
            LEA         ESI,[ESI+EBX*2]   ; - 4 + (XT1*2) as 16bpp
            ADD         ESI,[Svlfb] ; - 5

            @InFastTextHLineDYZ16

            PADDD       mm4,mm3 ; next source hline
            PADDD       mm6,[_NegScanLine] ; next hline
            ;DEC         ECX
            DEC			DWORD [HzLinesCount]
            MOV			EDX,DWORD [HzPntInit]
            JNZ         .BcResize

            EMMS
            POP         EDI
            POP         EBX
            POP         ESI
    RETURN

_MaskResizeViewSurf16:
    ARG SrcMResizeSurf16, 4, MResizeRevertHz, 4, MResizeRevertVt, 4

            PUSH        ESI
            PUSH        EBX
            PUSH        EDI

            MOV         ESI,[EBP+SrcMResizeSurf16]
            MOV         EDI,_SrcSurf
            XOR         EBX,EBX ; store flags revert Hz and Vt
            CopySurf  ; copy the source surface

            MOV         EAX,[EBP+MResizeRevertHz]
            MOV         EDX,[EBP+MResizeRevertVt]
            OR          EAX,EAX
            ; compute horizontal pnt in EBP
            MOV         EBP,[_MaxY]
            SETNZ       BL ; BL = RevertHz ?
            OR          EDX,EDX
            MOV         EAX,[SMaxX]
            SETNZ       BH ; BH = RevertVt ?
            MOV         EDI,[_MinY]
            MOV         ESI,[SMinX]
            PUSH        EBX ; save FLAGS Revert
            MOV         ECX,[_MaxX]
            SUB         EBP,EDI ; = (MaxY - MinY)
            MOV         EBX,[_MinX]
            INC         EBP ; = Delta_Y = (MaxY - MinY) + 1
            SUB         EAX,ESI
            IMUL        EDI,[_NegScanLine]
            SUB         ECX,EBX
            ADD         EDI,[_vlfb]
            MOV         [HzLinesCount],EBP ; count of hline
            MOVD        mm5,ESI ; SMinX
            INC         EAX
            LEA         EDI,[EDI+EBX*2]
            INC         ECX
            MOV         [HzLineDstAddr],EDI ; start Hline dest
            MOV         [HzLineLength],ECX ; dest hline size
            MOV         EBX,[SMaxY]
            SHL         EAX,Prec
            MOV         EDI,EBP ; EDI = DeltaY
            XOR         EDX,EDX
            SUB         EBX,[SMinY]
            DIV         ECX
            INC         EBX ; Source DeltaYT
            SHL         EBX,Prec
            MOV         EBP,EAX
            XOR         EDX,EDX
            MOV         EAX,EBX
            DIV         EDI
            POP         EBX
            XOR         EDX,EDX ; EDX = acc PntX
            MOVD        mm7,[SMinY]
            PXOR        mm4,mm4 ; mm4 = acc pnt
            ;MOVD        ECX,mm5
            CMP         BL,0
            JZ          SHORT .NoRevertHz
            MOVD        mm5,[SMaxX] ; SMaxX
            MOV         EDX,[PntInitCPTDbrd+4] ; ((1<<Prec)-1)
            NEG         EBP ; revert Horizontal Pnt X
.NoRevertHz:
            CMP         BH,0
            MOV			DWORD [HzPntInit],EDX
            JZ          SHORT .NoRevertVt
            NEG         EAX ; negate PntY
            MOVD        mm7,[SMaxY] ; SMaxX
            MOVD        mm4,[PntInitCPTDbrd+4] ; ((1<<Prec)-1)
.NoRevertVt:
            MOVD		[YT1],mm7
            MOV			[PntPlusX],EBP
			MOVD		mm7,[SMask]
            MOVD        mm3,EAX ; xmm3  = pntY
			PUNPCKLWD	mm7,mm7
			PUNPCKLDQ	mm7,mm7 ; = [QSMask16]
			;MOVQ		[QSMask16],mm7

.BcResize:
            MOVQ        mm0,mm4
            MOVD        EBX,mm5 ; + [SMinX] | [SMaxX] (if RevertHz)
            PSRAD       mm0,Prec
            MOVD        ESI,mm0
            MOV         EDI,[HzLineDstAddr] ; start hline
            ADD         ESI,[YT1] ; + [SMinY] | [SMaxY] (if RevertVt)
            MOV         ECX,[HzLineLength] ; dest hline size
            IMUL        ESI,[SNegScanLine] ; - 2
            LEA         ESI,[ESI+EBX*2]   ; - 4 + (XT1*2) as 16bpp
            ADD         ESI,[Svlfb] ; - 5

            @InFastMaskTextHLineDYZ16

			MOV			EAX,[_NegScanLine]
            PADDD       mm4,mm3 ; next source hline
            ADD         [HzLineDstAddr],EAX ; next dst hline
            ;DEC         ECX
            DEC			DWORD [HzLinesCount]
            MOV			EDX,[HzPntInit]
            JNZ         .BcResize

            EMMS
            POP         EDI
            POP         EBX
            POP         ESI
    RETURN

_BlndResizeViewSurf16:
    ARG SrcBResizeSurf16, 4, BResizeRevertHz, 4, BResizeRevertVt, 4, BResizeColBlnd, 4

            PUSH        ESI
            PUSH        EBX
            PUSH        EDI

            MOV         ESI,[EBP+SrcBResizeSurf16]
            MOV         EDI,_SrcSurf
            CopySurf  ; copy the source surface

; prepare blending
			MOV       	EAX,[EBP+BResizeColBlnd] ;
			MOV       	EBX,EAX ;
			MOV       	ECX,EAX ;
			MOV       	EDX,EAX ;
			AND			EBX,[QBlue16Mask] ; EBX = Bclr16 | Bclr16
			SHR			EAX,24
			AND			ECX,[QGreen16Mask] ; ECX = Gclr16 | Gclr16
			AND			AL,BlendMask ; remove any ineeded bits

			AND			EDX,[QRed16Mask] ; EDX = Rclr16 | Rclr16
			XOR			ESI,ESI
			XOR			AL,BlendMask ; 31-blendsrc
			MOV			SI,AX
			SHL			ESI,16
			OR			SI,AX
			XOR			AL,BlendMask ; 31-blendsrc

			INC			AL
			SHR			DX,5 ; right shift red 5bits
			IMUL		BX,AX
			IMUL		CX,AX
			IMUL		DX,AX
			MOVD		mm7,ESI
			MOVD		mm3,EBX
			MOVD		mm4,ECX
			MOVD		mm5,EDX
			PUNPCKLWD	mm3,mm3
			PUNPCKLWD	mm4,mm4
			PUNPCKLWD	mm5,mm5
			PUNPCKLDQ	mm7,mm7
			PUNPCKLDQ	mm3,mm3
			PUNPCKLDQ	mm4,mm4
			PUNPCKLDQ	mm5,mm5

			MOVQ		[QBlue16Blend],mm3
			MOVQ		[QGreen16Blend],mm4
			MOVQ		[QRed16Blend],mm5
			;============


            XOR         EBX,EBX ; store flags revert Hz and Vt
            MOV         EAX,[EBP+BResizeRevertHz]
            MOV         EDX,[EBP+BResizeRevertVt]
            OR          EAX,EAX
            ; compute horizontal pnt in EBP
            MOV         EBP,[_MaxY]
            SETNZ       BL ; BL = RevertHz ?
            OR          EDX,EDX
            MOV         EAX,[SMaxX]
            SETNZ       BH ; BH = RevertVt ?
            MOV         EDI,[_MinY]
            MOV         ESI,[SMinX]
            PUSH        EBX ; save FLAGS Revert
            MOV         ECX,[_MaxX]
            SUB         EBP,EDI ; = (MaxY - MinY)
            MOV         EBX,[_MinX]
            INC         EBP ; = Delta_Y = (MaxY - MinY) + 1
            SUB         EAX,ESI
            IMUL        EDI,[_NegScanLine]
            SUB         ECX,EBX
            ADD         EDI,[_vlfb]
            MOV         [HzLinesCount],EBP ; count of hline
            MOVD        mm5,ESI ; SMinX
            INC         EAX
            LEA         EDI,[EDI+EBX*2]
            INC         ECX
            MOV         [HzLineDstAddr],EDI ; start Hline dest
            MOV         [HzLineLength],ECX ; dest hline size
            MOV         EBX,[SMaxY]
            SHL         EAX,Prec
            MOV         EDI,EBP ; EDI = DeltaY
            XOR         EDX,EDX
            SUB         EBX,[SMinY]
            DIV         ECX
            INC         EBX ; Source DeltaYT
            SHL         EBX,Prec
            MOV         EBP,EAX
            XOR         EDX,EDX
            MOV         EAX,EBX
            DIV         EDI
            POP         EBX
            XOR         EDX,EDX ; EDX = acc PntX
            MOVD        mm1,[SMinY]
            PXOR        mm4,mm4 ; mm4 = acc pnt
            ;MOVD        ECX,mm5
            CMP         BL,0
            JZ          SHORT .NoRevertHz
            MOVD        mm5,[SMaxX] ; SMaxX
            MOV         EDX,[PntInitCPTDbrd+4] ; ((1<<Prec)-1)
            NEG         EBP ; revert Horizontal Pnt X
.NoRevertHz:
            CMP         BH,0
            MOV			DWORD [HzPntInit],EDX
            JZ          SHORT .NoRevertVt
            NEG         EAX ; negate PntY
            MOVD        mm1,[SMaxY] ; SMaxX
            MOVD        mm4,[PntInitCPTDbrd+4] ; ((1<<Prec)-1)
.NoRevertVt:
            MOV			[PntPlusX],EBP
            MOVD		[YT1],mm1
            MOVD        mm3,EAX ; xmm3  = pntY
.BcResize:
            MOVD        ESI,mm4
            MOVD        EBX,mm5 ; + [SMinX] | [SMaxX] (if RevertHz)
            SAR       	ESI,Prec
            MOV         EDI,[HzLineDstAddr] ; start hline
            ADD         ESI,[YT1] ; + [SMinY] | [SMaxY] (if RevertVt)
            MOV         ECX,[HzLineLength] ; dest hline size
            IMUL        ESI,[SNegScanLine] ; - 2
            LEA         ESI,[ESI+EBX*2]   ; - 4 + (XT1*2) as 16bpp
            ADD         ESI,[Svlfb] ; - 5

            @InFastTextBlndHLineDYZ16

			MOV			EAX,[_NegScanLine]
            PADDD       mm4,mm3 ; next source hline
            ADD         [HzLineDstAddr],EAX ; next dst hline
            ;DEC         ECX
            DEC			DWORD [HzLinesCount]
            MOV			EDX,[HzPntInit]
            JNZ         .BcResize

            EMMS
            POP         EDI
            POP         EBX
            POP         ESI
    RETURN

; ==== Poly16 and RePoly16 =============================

_RePoly16:
    ARG RePtrListPt16, 4, ReSSurf16, 4, ReTypePoly16, 4, ReColPoly16, 4

            PUSH        ESI
            PUSH        EBX
            PUSH        EDI

            ;CMP         [LastPolyStatus], BYTE 'N'
            MOV         EAX,[EBP+ReTypePoly16]
            MOV			EBX,[EBP+ReColPoly16]
            ;JE			_Poly16.PasDrawPoly
            TEST		EAX,POLY_FLAG_DBL_SIDED16
            JZ			SHORT .DblSideCheck ; not a double-sided RePoly16 ?
.doRePoly:
            AND         EAX,DEL_POLY_FLAG_DBL_SIDED16
            MOV         ECX,[EBP+ReSSurf16]
            MOV         [clr],EBX
            MOV         [SSSurf],ECX
            CMP         [_LastPolyStatus], BYTE 'I' ; last render IN ?
            JNE			.ClipRepoly16
            JMP			[InFillPolyProc16+EAX*4]
.ClipRepoly16:
			JMP			[ClFillPolyProc16+EAX*4]
.DblSideCheck:
			; if this is a reversed dbl_sided then skip repoly
			CMP			DWORD [PPtrListPt], ReversedPtrListPt
			JNE			SHORT .doRePoly
			JMP			_Poly16.PasDrawPoly

;****************************************************************************
;struct of PtrlistPt
;0‚		  DWORD : n count of PtrPoint
;1‚.. n‚  DWORD : PtrP1(X1,Y1,Z1,XT1,YT1)...PtrPn(Xn,Yn,Zn,XTn,YTn)
;****************************************************************************
; TypePoly POLY16_SOLID				= 0	 FIELDS USED (X,Y)
; TypePoly POLY16_TEXT				= 1	 FIELDS USED (X,Y,XT,YT)
; TypePoly POLY16_MASK_TEXT			= 2	 FIELDS USED (X,Y,XT,YT)
; TypePoly POLY16_TEXT_TRANS		= 10 FIELDS USED (X,Y,XT,YT)
; TypePoly POLY16_MASK_TEXT_TRANS	= 11 FIELDS USED (X,Y,XT,YT)
; TypePoly POLY16_SOLID_BLND		= 13 FIELDS USED (X,Y)
; TypePoly POLY16_TEXT_BLND			= 14 FIELDS USED (X,Y,XT,YT)
; TypePoly POLY16_MASK_TEXT_BLND	= 15 FIELDS USED (X,Y,XT,YT)
;****************************************************************************
; FLAGS :
POLY_FLAG_DBL_SIDED16		EQU	0x80000000
DEL_POLY_FLAG_DBL_SIDED16	EQU	0x7FFFFFFF

;****************************************************************************
ALIGN 32
_Poly16:
	ARG	PtrListPt16, 4, SSurf16, 4, TypePoly16, 4, ColPoly16, 4

		PUSH        ESI
		PUSH        EBX
		MOV			ESI,[EBP+PtrListPt16]
		PUSH        EDI

		LODSD		; MOV EAX,[ESI];  ADD ESI,4
        MOV         [_LastPolyStatus], BYTE 'N' ; default no render
		MOV			[NbPPoly],EAX
		MOV			ECX,[ESI+8]
		MOV			EAX,[ESI]
		MOV			EBX,[ESI+4]
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
		CMP			EAX,EDI

		JL			.TstSiDblSide ; si <= 0 alors pas ok
		JZ			.PasDrawPoly ; ignore poly if first 3 points aligned
;****************
.DrawPoly:
		; Sauvegarde les parametre et libere EBP
		MOV			EAX,[EBP+TypePoly16]
		MOV			EBX,[EBP+ColPoly16]
		AND     	EAX,DEL_POLY_FLAG_DBL_SIDED16
		MOV			ECX,[EBP+SSurf16]
		MOV			[PType],EAX
		MOV			[clr],EBX
		MOV			[PPtrListPt],ESI
		MOV			EDI,[NbPPoly]
		MOV			[SSSurf],ECX
;-new born determination--------------
		MOV			EBP,EDI
		MOVQ		mm1,mm3 ; init min = XP1 | YP1
		MOVQ		mm2,mm3 ; init max = XP1 | YP1
		DEC			EBP ; = [NbPPoly] - 1
		DEC			EDI ; " "
.PBoucMnMxXY:
		MOV			EAX,[ESI+EBP*4] ; = XN, YN
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
		DEC			EBP
		POR			mm1,mm5
		POR			mm2,mm6
		JNZ			.PBoucMnMxXY
		MOVD		EAX,mm2 ; maxx
		MOVD		ECX,mm1 ; minx
		PSRLQ		mm2,32
		PSRLQ		mm1,32
		MOVD		EBX,mm2 ; maxy
		MOVD		EDX,mm1 ; miny
;-----------------------------------------

; poly clipper ? dans l'ecran ? hors de l'ecran ?
		CMP			EAX,[_MaxX]
		JG			.PolyClip
		CMP			ECX,[_MinX]
		JL			.PolyClip
		CMP			EBX,[_MaxY]
		JG			.PolyClip
		CMP			EDX,[_MinY]
		JL			.PolyClip

; trace Poly non Clipper  **************************************************
		;JMP		.PolyClip

		MOV			ECX,[_OrgY]	 ; calcule DebYPoly, FinYPoly
		MOV			EAX,[ESI+EDI*4]
		ADD			EDX,ECX
		ADD			EBX,ECX
		MOV			[DebYPoly],EDX
		MOV			[FinYPoly],EBX
; calcule les bornes horizontal du poly
		MOV			EDX,EDI ; = NbPPoly - 1
		MOV			ECX,[EAX]
		MOV			EBP,[EAX+4]
		MOV			[XP2],ECX
		MOV			[YP2],EBP
		@InCalculerContour16
		MOV			EAX,[PType]
        MOV         [_LastPolyStatus], BYTE 'I'; In render
		JMP			[InFillPolyProc16+EAX*4]
		;JMP			.PasDrawPoly

.PolyClip:
; outside view ? now draw !
		CMP			EAX,[_MinX]
		JL			.PasDrawPoly
		CMP			EBX,[_MinY]
		JL			.PasDrawPoly
		CMP			ECX,[_MaxX]
		JG			.PasDrawPoly
		CMP			EDX,[_MaxY]
		JG			.PasDrawPoly
; Drop too big poly
		; drop too BIG tri
		SUB			ECX,EAX  ; deltaY
		SUB			EDX,EBX  ; deltaX
		CMP			ECX,MaxDeltaDim
		JGE			.PasDrawPoly
		CMP			EDX,MaxDeltaDim
		JGE			.PasDrawPoly
		ADD			ECX,EAX ; restor MaxY
		ADD			EDX,EBX ; restor MaxX

; trace Poly Clipper  ******************************************************
		MOV			EAX,[_MaxY]	; determine DebYPoly, FinYPoly
		MOV			ECX,[_MinY]
		CMP			EBX,EAX
		JL			.PasSupMxY
		MOV			EBX,EAX
.PasSupMxY:
		CMP			EDX,ECX
		JG			.PasInfMnY
		MOV			EDX,ECX
.PasInfMnY:
		MOV			EBP,[_OrgY]	  ; Ajuste [DebYPoly],[FinYPoly]
		MOV			EAX,[ESI+EDI*4]
		ADD			EDX,EBP
		ADD			EBX,EBP
		MOV			[DebYPoly],EDX
		MOV			[FinYPoly],EBX
		MOV			EDX,EDI ; EDX compteur de point = NbPPoly-1
		MOV 		ECX,[EAX]
		MOV 		EBP,[EAX+4]
		MOV			[XP2],ECX
		MOV			[YP2],EBP
		MOVD		mm4,ECX
		MOVD		mm5,EBP		; sauvegarde xp2,yp2
		@ClipCalculerContour ; use same as 8bpp as it compute xdeb and xfin for eax hzline

		CMP			DWORD [DebYPoly],BYTE (-1)
		MOV			EAX,[PType]
		JE			.PasDrawPoly
        MOV         [_LastPolyStatus], BYTE 'C' ; Clip render
		JMP			[ClFillPolyProc16+EAX*4]

.PasDrawPoly:
        POP         EDI
		POP         EBX
        POP         ESI
		;EMMS
		RETURN

.TstSiDblSide:
		TEST		BYTE [EBP+TypePoly+3],POLY_FLAG_DBL_SIDED16 >> 24
		MOV			ECX,[NbPPoly]
		JZ			.PasDrawPoly
		; swap all points except P1 !
		MOV         EAX,[ESI]
		MOV         EDX,ReversedPtrListPt
		DEC         ECX
		MOV         [EDX],EAX

		LEA         EDI,[ESI+ECX*4]
		LEA         EBX,[EDX+4] ; P1 already copied
		MOV         ESI,EDX ; update [PPtrListPt] In ESI
.BcSwapPts:
		MOV         EAX,[EDI]
		MOV         [EBX],EAX
		SUB         EDI,BYTE 4
		DEC         ECX
		LEA         EBX,[EBX+4]
		JNZ         SHORT .BcSwapPts
		JMP         .DrawPoly



SECTION .bss   ALIGN=32
_CurSurf:
_ScanLine          	RESD   1
_rlfb              	RESD   1
_OrgX              	RESD   1
_OrgY              	RESD   1
_MaxX              	RESD   1
_MaxY              	RESD   1
_MinX              	RESD   1
_MinY              	RESD   1;-----------------------
_Mask              	RESD   1
_ResH              	RESD   1
_ResV              	RESD   1
_vlfb              	RESD   1
_NegScanLine       	RESD   1
_OffVMem           	RESD   1
_BitsPixel         	RESD   1
_SizeSurf          	RESD   1 ;-----------------------
; source texture
_SrcSurf:
SScanLine         	RESD   1
Srlfb             	RESD   1
SOrgX             	RESD   1
SOrgY             	RESD   1
SMaxX             	RESD   1
SMaxY             	RESD   1
SMinX             	RESD   1
SMinY             	RESD   1;-----------------------
SMask             	RESD   1
SResH             	RESD   1
SResV             	RESD   1
Svlfb             	RESD   1
SNegScanLine      	RESD   1
SOffVMem          	RESD   1
SBitsPixel        	RESD   1
SSizeSurf         	RESD   1;-----------------------

XP1					RESD   1
YP1					RESD   1
XP2					RESD   1
YP2					RESD   1
XP3					RESD   1
YP3					RESD   1
Plus				RESD   1
clr					RESD   1;-----------------------
XT1					RESD   1
YT1					RESD   1
XT2					RESD   1
YT2					RESD   1
Col1				RESD   1
Col2				RESD   1
revCol				RESD   1
_CurViewVSurf		RESD   1;-----------------------
PutSurfMaxX     	RESD   1
PutSurfMaxY     	RESD   1
PutSurfMinX     	RESD   1
PutSurfMinY     	RESD   1
NbPPoly				RESD   1
DebYPoly			RESD   1
FinYPoly			RESD   1
PType				RESD   1;-----------------------
PType2				RESD   1
PPtrListPt			RESD   1
SSSurf				RESD   1
PntPlusX			RESD   1
PntPlusY			RESD   1
PlusX				RESD   1
PlusY				RESD   1
Plus2				RESD   1;-----------------------
Temp				RESD   2
QMulSrcBlend		RESD   2
QMulDstBlend		RESD   2
PlusCol				RESD   1
PtrTbDegCol			RESD   1;-----------------------
; LZW
Prefix_Code			RESD   1
Suffix_Code			RESD   1
Old_Code			RESD   1
CasSpecial			RESD   1
DStackPtr			RESD   1
NbBitCode			RESD   1
MaxCode				RESD   1
BuffPtrLZW			RESD   1
BuffIndexLZW		RESD   1
OutBuffLZW			RESD   1
OutBuffIndex		RESD   1
FreeAb				RESD   1
UtlBitCurAdd		RESD   1
RestBytes			RESD   1
CPTLZW				RESD   1
CPTCLR				RESD   1
Prefix				RESD	4096
Suffix				RESB	4096
DStack				RESB	4096  ; end LZW DATA -----



; used by Poly and Poly16
_TbDegCol			RESB	256*64
_TPolyAdDeb			RESD	MaxResV
_TPolyAdFin			RESD	MaxResV
_TexXDeb 			RESD	MaxResV
_TexXFin 			RESD	MaxResV
_TexYDeb 			RESD	MaxResV
_TexYFin 			RESD	MaxResV
_PColDeb 			RESD	MaxResV
_PColFin 			RESD	MaxResV

; reversed PPtrListPt pointer
ReversedPtrListPt   RESD  MaxDblSidePolyPts

; glob variables for Poly/Poly16 ..
QBlue16Blend		RESD	2
QGreen16Blend		RESD	2
QRed16Blend			RESD	2
QSMask16			RESD	2
QHLineOrg			RESD	2
DebStartAddr		RESD	1
HzLinesCount		RESD	1
HzLineLength		RESD	1
HzLineDstAddr		RESD	1
HzPntInit			RESD	1
HzLineLengthCount	RESD	1
ClipHStartAddr		RESD	1
_PtrTbColConv		RESD	1
_LastPolyStatus 	RESD  	1
ChPlus				RESD	1

SECTION .data   ALIGN=32


PntInitCPTDbrd		DD	0,((1<<Prec)-1)
Temp2				DD	0
MaskB_RGB16			DD	0x1f	 ; blue bits 0->4
MaskG_RGB16			DD	0x3f<<5  ; green bits 5->10
MaskR_RGB16			DD	0x1f<<11 ; red bits 11->15
RGB16_PntNeg		DD	((1<<Prec)-1) ;----------
Mask2B_RGB16		DD	0x1f,0x1f ; blue bits 0->4
Mask2G_RGB16		DD	0x3f<<5,0x3f<<5  ; green bits 5->10 ;----------
Mask2R_RGB16		DD	0x1f<<11,0x1f<<11 ; red bits 11->15
RGBDebMask_GGG		DD	0,0,0,0
RGBDebMask_IGG		DD	((1<<Prec)-1),0,0,0
RGBDebMask_GIG		DD	0,((1<<(Prec+5))-1),0,0
RGBDebMask_IIG		DD	((1<<Prec)-1),((1<<(Prec+5))-1),0,0
RGBDebMask_GGI		DD	0,0,((1<<(Prec+11))-1),0
RGBDebMask_IGI		DD	((1<<Prec)-1),0,((1<<(Prec+11))-1),0
RGBDebMask_GII		DD	0,((1<<(Prec+5))-1),((1<<(Prec+11))-1),0
RGBDebMask_III		DD	((1<<Prec)-1),((1<<(Prec+5))-1),((1<<(Prec+11))-1),0

RGBFinMask_GGG		DD	((1<<Prec)-1),((1<<(Prec+5))-1),((1<<(Prec+11))-1),0
RGBFinMask_IGG		DD	0,((1<<(Prec+5))-1),((1<<(Prec+11))-1),0
RGBFinMask_GIG		DD	((1<<Prec)-1),0,((1<<(Prec+11))-1),0
RGBFinMask_IIG		DD	0,0,((1<<(Prec+11))-1),0
RGBFinMask_GGI		DD	((1<<Prec)-1),((1<<(Prec+5))-1),0,0
RGBFinMask_IGI		DD	0,((1<<(Prec+5))-1),0,0
RGBFinMask_GII		DD	((1<<Prec)-1),0,0,0
RGBFinMask_III		DD	0,0,0,0
; BLENDING 16BPP ----------
QBlue16Mask			DW	CMaskB_RGB16,CMaskB_RGB16,CMaskB_RGB16,CMaskB_RGB16
QGreen16Mask		DW	CMaskG_RGB16,CMaskG_RGB16,CMaskG_RGB16,CMaskG_RGB16
QRed16Mask			DW	CMaskR_RGB16,CMaskR_RGB16,CMaskR_RGB16,CMaskR_RGB16

;* 8bpp poly proc****
InFillPolyProc:
					DD	InFillSOLID,InFillTEXT,InFillMASK_TEXT,InFillFLAT_DEG,InFillDEG
					DD	InFillFLAT_DEG_TEXT,InFillMASK_FLAT_DEG_TEXT
					DD	InFillDEG_TEXT,InFillMASK_DEG_TEXT,InFillEFF_FDEG
					DD	InFillEFF_DEG,InFillEFF_COLCONV
ClFillPolyProc:		DD	ClipFillSOLID,ClipFillTEXT,ClipFillMASK_TEXT,ClipFillFLAT_DEG,ClipFillDEG
					DD	ClipFillFLAT_DEG_TEXT,ClipFillMASK_FLAT_DEG_TEXT
					DD	ClipFillDEG_TEXT,ClipFillMASK_DEG_TEXT
					DD	ClipFillEFF_FDEG,ClipFillEFF_DEG,ClipFillEFF_COLCONV

;* 16bpp poly proc****
InFillPolyProc16:
					DD	InFillSOLID16,InFillTEXT16,InFillMASK_TEXT16,dummyFill16,dummyFill16
					DD	dummyFill16,dummyFill16
					DD	dummyFill16,dummyFill16
					DD	dummyFill16,InFillTEXT_TRANS16,InFillMASK_TEXT_TRANS16
					DD	InFillRGB16,InFillSOLID_BLND16,InFillTEXT_BLND16,InFillMASK_TEXT_BLND16

ClFillPolyProc16:
					DD	ClipFillSOLID16,ClipFillTEXT16,ClipFillMASK_TEXT16,dummyFill16,dummyFill16
					DD	dummyFill16,dummyFill16
					DD	dummyFill16,dummyFill16
					DD	dummyFill16,ClipFillTEXT_TRANS16, ClipFillMASK_TEXT_TRANS16
					DD	ClipFillRGB16,ClipFillSOLID_BLND16,ClipFillTEXT_BLND16,ClipFillMASK_TEXT_BLND16

