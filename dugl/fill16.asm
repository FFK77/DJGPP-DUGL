%macro  @FILLRET16   0
    JMP _Poly16.PasDrawPoly
%endmacro

; ****** DUMMY
dummyFill16:
      @FILLRET16


;******* POLYTYPE = SOLID
ALIGN 32
InFillSOLID16:
		MOVD       	mm0,[clr] ; mm0 = clr16 | - | - | -
		MOV			EBX,[DebYPoly]	; -
		PUNPCKLWD	mm0,mm0 ; mm0 = clr16 | clr16 | - | -
		LEA			EDX,[EBX*4]	; -
		PUNPCKLDQ	mm0,mm0 ; mm0 = clr16 | clr16 | clr16 | clr16
		SUB			EBX,[FinYPoly]	; -
		MOVD		EAX,mm0 ; assign the 16bpp color to the low
		NEG			EBX		; -
;ALIGN 4
.BcFillSolid16:
		MOV			EDI,[_TPolyAdDeb+EDX+EBX*4]
		MOV			ESI,[_TPolyAdFin+EDX+EBX*4]
		CMP			ESI,EDI
		JG			.PasSwapAd
		XCHG		EDI,ESI
.PasSwapAd:
		SUB			ESI,EDI
		SHR			ESI,1
		INC			ESI
		@SolidHLine16
		DEC			EBX
		JNS			.BcFillSolid16

	@FILLRET16


ALIGN 32
ClipFillSOLID16:
		MOV		EBP,[FinYPoly]
		MOV		EBX,[DebYPoly]
		SUB		EBP,[_OrgY]
		MOVD       	mm0,[clr] ; mm0 = clr16 | - | - | -
		IMUL		EBP,[_NegScanLine]
		LEA		EDX,[EBX*4]
		PUNPCKLWD	mm0,mm0 ; mm0 = clr16 | clr16 | - | -
		SUB		EBX,[FinYPoly]
		PUNPCKLDQ	mm0,mm0 ; mm0 = clr16 | clr16 | clr16 | clr16
		NEG		EBX
		ADD		EBP,[_vlfb]
		MOVD		EAX,mm0 ; assign the 16bpp color to the low
		;INC		EBX
		MOVD		mm3,EBP
;ALIGN 4
.BcFillSolid:	MOV		EDI,[_TPolyAdDeb+EDX+EBX*4]
		MOV		ESI,[_TPolyAdFin+EDX+EBX*4]
		CMP		ESI,EDI
		JG		.PasSwapAd
		XCHG		EDI,ESI
.PasSwapAd:
		CMP		ESI,[_MinX]	  	; [XP2] < [_MinX]
		JL		.PasDrwClSD
		CMP		EDI,[_MaxX]		; [XP1] > [_MaxX]
		JG		.PasDrwClSD

		CMP		ESI,[_MaxX]
		JLE		.PasAJX2
		MOV		ESI,[_MaxX]
.PasAJX2:	CMP		EDI,[_MinX]
		JGE		.PasAJX1
		MOV		EDI,[_MinX]
.PasAJX1:
		SUB		ESI,EDI
		MOVD		ECX,mm3
		;SHL		EDI,1 ; 16bpp => xDeb*= 2
		INC		ESI
		LEA		EDI,[ECX+EDI*2]
		;ADD		EDI,ECX
		@SolidHLine16
.PasDrwClSD:
		DEC		EBX
		PADDD		mm3,[_ScanLine]
		JNS		.BcFillSolid
.FinClipSOLID:

	@FILLRET16

;******* POLYTYPE = TEXT
ALIGN 32

InFillTEXT16:
		@InCalcTextCnt
		MOV			ESI,[SSSurf] ; sauvegarde la surf Source
		MOV			EBX,[DebYPoly] ; -
		MOV			EDI,_SrcSurf
		LEA			EDX,[EBX*4]    ; -
		CopySurf  ; copy the source texture surface
		SUB			EBX,[FinYPoly] ; -  EBX = DebYPoly-FinYPoly
		NEG			EBX	       ; -  EBX = FinYPoly-DebYPoly
		MOVD		mm6,EDX
;ALIGN 4
.BcFillText:
		MOVD		mm7,EBX
		LEA			EBX,[EDX+EBX*4]
		MOV			EDI,[_TPolyAdDeb+EBX]
		MOV			ECX,[_TPolyAdFin+EBX]
		MOV			EAX,[_TexXDeb+EBX]
		MOV			ESI,[_TexYDeb+EBX]
		MOV			[XT1],EAX
		MOV			[YT1],ESI
		MOV			EAX,[_TexXFin+EBX]
		MOV			ESI,[_TexYFin+EBX]
		MOV			[XT2],EAX
		MOV			[YT2],ESI

		CMP			ECX,EDI
		JG			.PasSwapAd
		XCHG		EDI,ECX
.PasSwapAd:
		SUB			ECX,EDI
		SHR			ECX,1
		@InTextHLine16
		MOVD		EBX,mm7
		MOVD		EDX,mm6
		DEC			EBX
		JNS			.BcFillText

	@FILLRET16

ALIGN 32
ClipFillTEXT16:
		@ClipCalcTextCnt
		MOV			ESI,[SSSurf] ; sauvegarde la surf Source
		MOV			EDI,_SrcSurf

		MOV			EBP,[FinYPoly]
		CopySurf  ; copy the source texture surface
		SUB			EBP,[_OrgY]
		MOV			EBX,[DebYPoly] ; -
		IMUL		EBP,[_NegScanLine]
		LEA			EDX,[EBX*4]    ; -
		SUB			EBX,[FinYPoly] ; -
		ADD			EBP,[_vlfb]
		NEG			EBX	       ; -
		MOVD		mm3,EBP
		MOVD		mm4,[_ScanLine]
.BcFillText:
		MOV			EDI,[_TPolyAdDeb+EDX+EBX*4]  ; X1
		MOV			ECX,[_TPolyAdFin+EDX+EBX*4]  ; X2
		MOV			EAX,[_TexXDeb+EDX+EBX*4]
		MOV			ESI,[_TexYDeb+EDX+EBX*4]
		MOV			[XT1],EAX
		MOV			[YT1],ESI
		MOV			EAX,[_TexXFin+EDX+EBX*4]
		MOV			ESI,[_TexYFin+EDX+EBX*4]
		MOV			[XT2],EAX
		MOV			[YT2],ESI

		CMP			ECX,EDI
		JG			.PasSwapAd
		XCHG		EDI,ECX
.PasSwapAd:
		MOVD		mm7,EBX
		MOVD		mm6,EDX
		MOV			EBX,[_MinX]
		MOV			EDX,[_MaxX]
		CMP			ECX,EBX	  	; [XP2] < [_MinX]
		JL			.PasDrwClTx
		CMP			EDI,EDX		; [XP1] > [_MaxX]
		JG			.PasDrwClTx
		SUB			ECX,EDI
		MOV			[Plus2],ECX	; Plus2 = DltX sans ajust
		XOR			EAX,EAX
		ADD			ECX,EDI
		CMP			ECX,EDX 	; [XP2] > [_MaxX]
		JLE			.PasAJX2
		MOV			ECX,EDX
.PasAJX2:
		CMP			EDI,EBX 	; [XP1] < [_MinX]
		JGE			.PasAJX1
		MOV			EAX,EBX
		SUB			EAX,EDI         ; EAX = [_MinX] - [XP1]
		MOV			EDI,EBX
.PasAJX1:
		MOVD		ESI,mm3
		SUB			ECX,EDI
		MOV			[Plus],EAX
		;SHL		EDI,1 ; 16bpp : xdeb*2
		INC			ECX
		;ADD		EDI,ESI
		LEA			EDI,[ESI+EDI*2]
		@ClipTextHLine16
.PasDrwClTx:
		MOVD		EBX,mm7
		MOVD		EDX,mm6
		DEC			EBX
		PADDD		mm3,mm4
		JNS			.BcFillText
.FinClipText:

	@FILLRET16


		;******* POLYTYPE = MASK_TEXT
ALIGN 32
InFillMASK_TEXT16:
		@InCalcTextCnt
		MOV		ESI,[SSSurf] ; sauvegarde la surf Source
		MOV		EBX,[DebYPoly] ; -
		MOV		EDI,_SrcSurf
		LEA		EDX,[EBX*4]    ; -
		CopySurf  ; copy the source texture surface
		SUB		EBX,[FinYPoly] ; -  EBX = DebYPoly-FinYPoly
		NEG		EBX	       ; -  EBX = FinYPoly-DebYPoly
;ALIGN 4
.BcFillText:	MOVD		mm7,EBX
		LEA		EBX,[EDX+EBX*4]
		MOV		EDI,[_TPolyAdDeb+EBX]
		MOV		ECX,[_TPolyAdFin+EBX]
		MOV		EAX,[_TexXDeb+EBX]
		MOV		ESI,[_TexYDeb+EBX]
		MOV		[XT1],EAX
		MOV		[YT1],ESI
		MOV		EAX,[_TexXFin+EBX]
		MOV		ESI,[_TexYFin+EBX]
		MOV		[XT2],EAX
		MOV		[YT2],ESI

		CMP		ECX,EDI
		JG		.PasSwapAd
		XCHG		EDI,ECX
.PasSwapAd:
		MOVD		mm6,EDX
		SUB		ECX,EDI
		SHR		ECX,1
		@InMaskTextHLine16
		MOVD		EBX,mm7
		MOVD		EDX,mm6
		DEC		EBX
		JNS		.BcFillText

	@FILLRET16

ALIGN 32
ClipFillMASK_TEXT16:
                @ClipCalcTextCnt
		MOV		ESI,[SSSurf] ; sauvegarde la surf Source
		MOV		EDI,_SrcSurf

		MOV		EBP,[FinYPoly]
		CopySurf  ; copy the source texture surface
		SUB		EBP,[_OrgY]
		MOV		EBX,[DebYPoly] ; -
		IMUL		EBP,[_NegScanLine]
		LEA		EDX,[EBX*4]    ; -
		SUB		EBX,[FinYPoly] ; -
		ADD		EBP,[_vlfb]
		NEG		EBX	       ; -
		MOVD		mm3,EBP
		MOVD		mm4,[_ScanLine]
.BcFillText:	MOV		EDI,[_TPolyAdDeb+EDX+EBX*4]  ; X1
		MOV		ECX,[_TPolyAdFin+EDX+EBX*4]  ; X2
		MOV		EAX,[_TexXDeb+EDX+EBX*4]
		MOV		ESI,[_TexYDeb+EDX+EBX*4]
		MOV		[XT1],EAX
		MOV		[YT1],ESI
		MOV		EAX,[_TexXFin+EDX+EBX*4]
		MOV		ESI,[_TexYFin+EDX+EBX*4]
		MOV		[XT2],EAX
		MOV		[YT2],ESI

		CMP		ECX,EDI
		JG		.PasSwapAd
		XCHG		EDI,ECX
.PasSwapAd:
		MOVD		mm7,EBX
		MOVD		mm6,EDX
		MOV		EBX,[_MinX]
		MOV		EDX,[_MaxX]
		CMP		ECX,EBX	  	; [XP2] < [_MinX]
		JL		.PasDrwClTx
		CMP		EDI,EDX		; [XP1] > [_MaxX]
		JG		.PasDrwClTx
		SUB		ECX,EDI
		MOV		[Plus2],ECX	; Plus2 = DltX sans ajust
		XOR		EAX,EAX
		ADD		ECX,EDI
		CMP		ECX,EDX 	; [XP2] > [_MaxX]
		JLE		.PasAJX2
		MOV		ECX,EDX
.PasAJX2:	CMP		EDI,EBX 	; [XP1] < [_MinX]
		JGE		.PasAJX1
		MOV		EAX,EBX
		SUB		EAX,EDI         ; EAX = [_MinX] - [XP1]
		MOV		EDI,EBX
.PasAJX1:
		MOVD		ESI,mm3
		SUB		ECX,EDI
		MOV		[Plus],EAX
		;SHL		EDI,1 ; 16bpp : xdeb*2
		INC		ECX
		;ADD		EDI,ESI
		LEA		EDI,[ESI+EDI*2]
		@ClipMaskTextHLine16
.PasDrwClTx:
		MOVD		EBX,mm7
		MOVD		EDX,mm6
		DEC		EBX
		PADDD		mm3,mm4
		JNS		.BcFillText
.FinClipText:

	@FILLRET16


; POLY TYPE : RGB16

ALIGN 32
InFillRGB16:
		@InCalcRGB_Cnt16

		MOV		EBX,[DebYPoly]	; -
		LEA		EDX,[EBX*4]	; -
		SUB		EBX,[FinYPoly]	; -
		NEG		EBX		; -
;ALIGN 4
.BcFillRGB16:	MOV		EDI,[_TPolyAdDeb+EDX+EBX*4]
		MOV		ESI,[_TPolyAdFin+EDX+EBX*4]
		MOV		EBP,[_PColDeb+EDX+EBX*4] ; col1
		MOV		EAX,[_PColFin+EDX+EBX*4] ; col2
		CMP		ESI,EDI
		JG		.PasSwapAd
		XCHG		EDI,ESI
.PasSwapAd:	SUB		ESI,EDI
		PUSH		EDX
		SHR		ESI,1
		PUSH		EBX
		INC		ESI

		@InRGBHLine16

		POP		EBX
		POP		EDX
		DEC		EBX
		JNS		.BcFillRGB16

	@FILLRET16


ALIGN 32
ClipFillRGB16:
		@ClipCalcRGB_Cnt16

		MOV		EBP,[FinYPoly]
		SUB		EBP,[_OrgY]
		MOV		EBX,[DebYPoly] ; -
		IMUL		EBP,[_ScanLine]
		LEA		EDX,[EBX*4]    ; -
		SUB		EBX,[FinYPoly] ; -
		NEG		EBP
		NEG		EBX	       ; -
		ADD		EBP,[_vlfb]
		MOV		ESI,EBP
.BcFillRGB16:
		MOV		ECX,[_TPolyAdFin+EDX+EBX*4]  ; X2
		MOV		EDI,[_TPolyAdDeb+EDX+EBX*4]  ; X1
		MOV		EBP,[_PColDeb+EDX+EBX*4]
		MOV		EAX,[_PColFin+EDX+EBX*4]
		MOV		[Col1],EBP
		MOV		[Col2],EAX

		CMP		ECX,EDI
		JG		.PasSwapAd
		XCHG		EDI,ECX
.PasSwapAd:
		PUSH		EDX
		PUSH		EBX
		MOV		EBX,[_MinX]
		MOV		EDX,[_MaxX]
		CMP		ECX,EBX	  	; [XP2] < [_MinX]
		JL		.PasDrwClTx
		CMP		EDI,EDX		; [XP1] > [_MaxX]
		JG		.PasDrwClTx
		SUB		ECX,EDI
		MOV		[Plus2],ECX	; Plus2 = DltX sans ajust
		XOR		EAX,EAX
		ADD		ECX,EDI
		CMP		ECX,EDX 	; [XP2] > [_MaxX]
		JLE		.PasAJX2
		MOV		ECX,EDX
.PasAJX2:	CMP		EDI,EBX 	; [XP1] < [_MinX]
		JGE		.PasAJX1
		MOV		EAX,EBX
		SUB		EAX,EDI         ; EAX = [_MinX] - [XP1]
		MOV		EDI,EBX
.PasAJX1:
		SUB		ECX,EDI ; XFin-xDeb
		MOV		[Plus],EAX
		;SHL		EDI,1 ; xDeb*2 as 16bpp
		INC		ECX
		;ADD		EDI,ESI
		LEA		EDI,[ESI+EDI*2]
		MOV		EBP,[Col1]
		MOV		EAX,[Col2]
		PUSH		ESI
		@ClipRGBHLine16
		POP		ESI
.PasDrwClTx:
		POP		EBX
		POP		EDX
		ADD		ESI,[_ScanLine]
		DEC		EBX
		JNS		.BcFillRGB16
.FinClipDEG:

	@FILLRET16



;******* POLYTYPE = SOLID_BLND
ALIGN 32
InFillSOLID_BLND16:
; prepare blending
		MOV       	EAX,[clr] ;
		MOV       	EBX,EAX ;
		MOV       	ECX,EAX ;
		MOV       	EDX,EAX ;
		AND			EBX,[QBlue16Mask] ; EBX = Bclr16 | Bclr16
		SHR			EAX,24
		AND			ECX,[QGreen16Mask] ; ECX = Gclr16 | Gclr16
		AND			AL,BlendMask ; remove any ineeded bits
		JZ			.EndInBlend ; nothing 0 is the source
		AND			EDX,[QRed16Mask] ; EDX = Rclr16 | Rclr16
		XOR			EBP,EBP
		XOR			AL,BlendMask ; 31-blendsrc
		MOV			BP,AX
		SHL			EBP,16
		OR			BP,AX
		XOR			AL,BlendMask ; 31-blendsrc
		INC			AL
		SHR			DX,5 ; right shift red 5bits
		IMUL		BX,AX
		IMUL		CX,AX
		IMUL		DX,AX
		MOVD		mm3,EBX
		MOVD		mm4,ECX
		MOVD		mm5,EDX
		PUNPCKLWD	mm3,mm3
		PUNPCKLWD	mm4,mm4
		PUNPCKLWD	mm5,mm5
		PUNPCKLDQ	mm3,mm3
		MOV			EBX,[DebYPoly]	; -
		PUNPCKLDQ	mm4,mm4
		LEA			EDX,[EBX*4]	; -
		MOVD		mm7,EBP
		PUNPCKLDQ	mm5,mm5
		SUB			EBX,[FinYPoly]	; -
		PUNPCKLDQ	mm7,mm7
		NEG			EBX		; -
		XOR			ECX,ECX
;ALIGN 4
.BcFillSolid16:
		MOV			EDI,[_TPolyAdDeb+EDX+EBX*4]
		MOV			ESI,[_TPolyAdFin+EDX+EBX*4]
		CMP			ESI,EDI
		JG			.PasSwapAd
		XCHG		EDI,ESI
.PasSwapAd:
		SUB			ESI,EDI
		SHR			ESI,1
		INC			ESI
		@SolidBlndHLine16
		DEC			EBX
		JNS			.BcFillSolid16
.EndInBlend:

	@FILLRET16


ALIGN 32
ClipFillSOLID_BLND16:
		MOV       	EAX,[clr] ;
		MOV       	EBX,EAX ;
		MOV       	ECX,EAX ;
		MOV       	EDX,EAX ;
		AND			EBX,[QBlue16Mask] ; EBX = Bclr16 | Bclr16
		SHR			EAX,24
		AND			ECX,[QGreen16Mask] ; ECX = Gclr16 | Gclr16
		AND			AL,BlendMask ; remove any ineeded bits
		JZ			.FinClipSOLID ; nothing 0 is the source
		AND			EDX,[QRed16Mask] ; EDX = Rclr16 | Rclr16
		XOR			EBP,EBP
		XOR			AL,BlendMask ; 31-blendsrc
		MOV			BP,AX
		SHL			EBP,16
		OR			BP,AX
		XOR			AL,BlendMask ; 31-blendsrc
		INC			AL
		SHR			DX,5 ; right shift red 5bits
		IMUL		BX,AX
		IMUL		CX,AX
		IMUL		DX,AX
		MOVD		mm3,EBX
		MOVD		mm4,ECX
		MOV			EAX,[FinYPoly]
		MOVD		mm5,EDX
		PUNPCKLWD	mm3,mm3
		PUNPCKLWD	mm4,mm4
		PUNPCKLWD	mm5,mm5
		PUNPCKLDQ	mm3,mm3
		MOV			EBX,[DebYPoly]
		PUNPCKLDQ	mm4,mm4
		SUB			EAX,[_OrgY]
		PUNPCKLDQ	mm5,mm5
		IMUL		EAX,[_ScanLine]
		MOVD		mm7,EBP
		LEA			EDX,[EBX*4]
		SUB			EBX,[FinYPoly]
		NEG			EAX
		PUNPCKLDQ	mm7,mm7

		ADD			EAX,[_vlfb]
		NEG			EBX
		XOR			ECX,ECX
		;INC		EBX
		MOVD		mm6,EAX
;ALIGN 4
.BcFillSolid:
		MOV			EDI,[_TPolyAdDeb+EDX+EBX*4]
		MOV			ESI,[_TPolyAdFin+EDX+EBX*4]
		CMP			ESI,EDI
		JG			.PasSwapAd
		XCHG		EDI,ESI
.PasSwapAd:
		CMP			ESI,[_MinX]	  	; [XP2] < [_MinX]
		JL			.PasDrwClSD
		CMP			EDI,[_MaxX]		; [XP1] > [_MaxX]
		JG			.PasDrwClSD

		CMP			ESI,[_MaxX]
		JLE			.PasAJX2
		MOV			ESI,[_MaxX]
.PasAJX2:
		CMP			EDI,[_MinX]
		JGE			.PasAJX1
		MOV			EDI,[_MinX]
.PasAJX1:
		SUB			ESI,EDI
		MOVD		EAX,mm6
		;SHL		EDI,1 ; 16bpp => xDeb*= 2
		INC			ESI
		;ADD		EDI,ECX
		LEA			EDI,[EAX+EDI*2]
		@SolidBlndHLine16
.PasDrwClSD:
		DEC			EBX
		PADDD		mm6,[_ScanLine]
		JNS			.BcFillSolid
.FinClipSOLID:

	@FILLRET16

;******* POLYTYPE = TEXT_BLND
ALIGN 32
InFillTEXT_BLND16:
; prepare blending
		MOV       	EAX,[clr] ;
		MOV       	EBX,EAX ;
		MOV       	ECX,EAX ;
		MOV       	EDX,EAX ;
		AND			EBX,[QBlue16Mask] ; EBX = Bclr16 | Bclr16
		SHR			EAX,24
		AND			ECX,[QGreen16Mask] ; ECX = Gclr16 | Gclr16
		AND			AL,BlendMask ; remove any ineeded bits
		;JZ			InFillTEXT16
		AND			EDX,[QRed16Mask] ; EDX = Rclr16 | Rclr16
		XOR			EBP,EBP
		XOR			AL,BlendMask ; 31-blendsrc
		MOV			BP,AX
		SHL			EBP,16
		OR			BP,AX
		XOR			AL,BlendMask ; 31-blendsrc
		;JZ			InFillSOLID16 ; 31 mean no blend flat color
		INC			AL
		SHR			DX,5 ; right shift red 5bits
		IMUL		BX,AX
		IMUL		CX,AX
		IMUL		DX,AX
		MOVD		mm7,EBP
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

		MOVQ		[QMulSrcBlend],mm7
		MOVQ		[QBlue16Blend],mm3
		MOVQ		[QGreen16Blend],mm4
		MOVQ		[QRed16Blend],mm5

; end prepare blend
		@InCalcTextCnt

		MOV			ESI,[SSSurf] ; sauvegarde la surf Source
		MOV			EBX,[DebYPoly] ; -
		MOV			EDI,_SrcSurf
		LEA			EDX,[EBX*4]    ; -
		CopySurf  ; copy the source texture surface
		SUB			EBX,[FinYPoly] ; -  EBX = DebYPoly-FinYPoly
		NEG			EBX	       ; -  EBX = FinYPoly-DebYPoly
;ALIGN 4
.BcFillText:
		MOVD		mm7,EBX
		LEA			EBX,[EDX+EBX*4]
		MOV			EDI,[_TPolyAdDeb+EBX]
		MOV			ECX,[_TPolyAdFin+EBX]
		MOV			EAX,[_TexXDeb+EBX]
		MOV			ESI,[_TexYDeb+EBX]
		MOV			[XT1],EAX
		MOV			[YT1],ESI
		MOV			EAX,[_TexXFin+EBX]
		MOV			ESI,[_TexYFin+EBX]
		MOV			[XT2],EAX
		MOV			[YT2],ESI

		CMP			ECX,EDI
		JG			.PasSwapAd
		XCHG		EDI,ECX
.PasSwapAd:
		MOVD		mm6,EDX
		SUB			ECX,EDI
		SHR			ECX,1
		@InTextBlndHLine16
		MOVD		EBX,mm7
		MOVD		EDX,mm6
		DEC			EBX
		JNS			.BcFillText

	@FILLRET16

ALIGN 32
ClipFillTEXT_BLND16:
		@ClipCalcTextCnt
; prepare blending
		MOV       	EAX,[clr] ;
		MOV       	EBX,EAX ;
		MOV       	ECX,EAX ;
		MOV       	EDX,EAX ;
		AND			EBX,[QBlue16Mask] ; EBX = Bclr16 | Bclr16
		SHR			EAX,24
		AND			ECX,[QGreen16Mask] ; ECX = Gclr16 | Gclr16
		AND			AL,BlendMask ; remove any ineeded bits
		AND			EDX,[QRed16Mask] ; EDX = Rclr16 | Rclr16
		XOR			EBP,EBP
		XOR			AL,BlendMask ; 31-blendsrc
		MOV			BP,AX
		SHL			EBP,16
		OR			BP,AX
		XOR			AL,BlendMask ; 31-blendsrc
		INC			AL
		SHR			DX,5 ; right shift red 5bits
		IMUL		BX,AX
		IMUL		CX,AX
		IMUL		DX,AX
		MOVD		mm7,EBP
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

		MOVQ		[QMulSrcBlend],mm7
		MOVQ		[QBlue16Blend],mm3
		MOVQ		[QGreen16Blend],mm4
		MOVQ		[QRed16Blend],mm5
; end prepare blend
		MOV		ESI,[SSSurf] ; sauvegarde la surf Source
		MOV		EDI,_SrcSurf

		MOV		EBP,[FinYPoly]
		CopySurf  ; copy the source texture surface
		SUB		EBP,[_OrgY]
		MOV		EBX,[DebYPoly] ; -
		IMUL		EBP,[_ScanLine]
		LEA		EDX,[EBX*4]    ; -
		SUB		EBX,[FinYPoly] ; -
		NEG		EBP
		NEG		EBX	       ; -
		ADD		EBP,[_vlfb]
		MOVD		mm6,EBP
		MOVD		mm7,[_ScanLine]
.BcFillText:	MOV		EDI,[_TPolyAdDeb+EDX+EBX*4]  ; X1
		MOV		ECX,[_TPolyAdFin+EDX+EBX*4]  ; X2
		MOV		EAX,[_TexXDeb+EDX+EBX*4]
		MOV		ESI,[_TexYDeb+EDX+EBX*4]
		MOV		[XT1],EAX
		MOV		[YT1],ESI
		MOV		EAX,[_TexXFin+EDX+EBX*4]
		MOV		ESI,[_TexYFin+EDX+EBX*4]
		MOV		[XT2],EAX
		MOV		[YT2],ESI

		CMP		ECX,EDI
		JG		.PasSwapAd
		XCHG		EDI,ECX
.PasSwapAd:
		PUSH		EBX
		PUSH		EDX
		MOV		EBX,[_MinX]
		MOV		EDX,[_MaxX]
		CMP		ECX,EBX	  	; [XP2] < [_MinX]
		JL		.PasDrwClTx
		CMP		EDI,EDX		; [XP1] > [_MaxX]
		JG		.PasDrwClTx
		SUB		ECX,EDI
		MOV		[Plus2],ECX	; Plus2 = DltX sans ajust
		XOR		EAX,EAX
		ADD		ECX,EDI
		CMP		ECX,EDX 	; [XP2] > [_MaxX]
		JLE		.PasAJX2
		MOV		ECX,EDX
.PasAJX2:	CMP		EDI,EBX 	; [XP1] < [_MinX]
		JGE		.PasAJX1
		MOV		EAX,EBX
		SUB		EAX,EDI         ; EAX = [_MinX] - [XP1]
		MOV		EDI,EBX
.PasAJX1:
		MOVD		ESI,mm6
		SUB		ECX,EDI
		MOV		[Plus],EAX
		;SHL		EDI,1 ; 16bpp : xdeb*2
		INC		ECX
		;ADD		EDI,ESI
		LEA		EDI,[ESI+EDI*2]
		@ClipTextBlndHLine16
.PasDrwClTx:
		POP		EDX
		POP		EBX
		DEC		EBX
		PADDD		mm6,mm7
		JNS		.BcFillText
.FinClipText:

	@FILLRET16


		;******* POLYTYPE = MASK_TEXT_BLND
ALIGN 32
InFillMASK_TEXT_BLND16:
; prepare blending
		MOV       	EAX,[clr] ;
		MOV       	EBX,EAX ;
		MOV       	ECX,EAX ;
		MOV       	EDX,EAX ;
		AND		EBX,[QBlue16Mask] ; EBX = Bclr16 | Bclr16
		SHR		EAX,24
		AND		ECX,[QGreen16Mask] ; ECX = Gclr16 | Gclr16
		AND		AL,BlendMask ; remove any ineeded bits
		;JZ		InFillTEXT16
		AND		EDX,[QRed16Mask] ; EDX = Rclr16 | Rclr16
		XOR		AL,BlendMask ; 31-blendsrc
		MOV		BP,AX
		SHL		EBP,16
		OR		BP,AX
		XOR		AL,BlendMask ; 31-blendsrc
		;JZ		InFillSOLID16 ; 31 mean no blend flat color
		INC		AL
		SHR		DX,5 ; right shift red 5bits
		IMUL		BX,AX
		IMUL		CX,AX
		IMUL		DX,AX

		MOVD		mm7,EBP
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

		MOVQ		[QMulSrcBlend],mm7
		MOVQ		[QBlue16Blend],mm3
		MOVQ		[QGreen16Blend],mm4
		MOVQ		[QRed16Blend],mm5

; end prepare blend
		@InCalcTextCnt

		MOV		ESI,[SSSurf] ; sauvegarde la surf Source
		MOV		EBX,[DebYPoly] ; -
		MOV		EDI,_SrcSurf
		LEA		EDX,[EBX*4]    ; -
		CopySurf  ; copy the source texture surface
		SUB		EBX,[FinYPoly] ; -  EBX = DebYPoly-FinYPoly
		NEG		EBX	       ; -  EBX = FinYPoly-DebYPoly
;ALIGN 4
.BcFillText:	MOVD		mm7,EBX
		LEA		EBX,[EDX+EBX*4]
		MOV		EDI,[_TPolyAdDeb+EBX]
		MOV		ECX,[_TPolyAdFin+EBX]
		MOV		EAX,[_TexXDeb+EBX]
		MOV		ESI,[_TexYDeb+EBX]
		MOV		[XT1],EAX
		MOV		[YT1],ESI
		MOV		EAX,[_TexXFin+EBX]
		MOV		ESI,[_TexYFin+EBX]
		MOV		[XT2],EAX
		MOV		[YT2],ESI

		CMP		ECX,EDI
		JG		.PasSwapAd
		XCHG		EDI,ECX
.PasSwapAd:
		MOVD		mm6,EDX
		SUB		ECX,EDI
		SHR		ECX,1
		@InMaskTextBlndHLine16
		MOVD		EBX,mm7
		MOVD		EDX,mm6
		DEC		EBX
		JNS		.BcFillText

	@FILLRET16


ALIGN 32
ClipFillMASK_TEXT_BLND16:
                @ClipCalcTextCnt
; prepare blending
		MOV       	EAX,[clr] ;
		MOV       	EBX,EAX ;
		MOV       	ECX,EAX ;
		MOV       	EDX,EAX ;
		AND		EBX,[QBlue16Mask] ; EBX = Bclr16 | Bclr16
		SHR		EAX,24
		AND		ECX,[QGreen16Mask] ; ECX = Gclr16 | Gclr16
		AND		AL,BlendMask ; remove any ineeded bits
		AND		EDX,[QRed16Mask] ; EDX = Rclr16 | Rclr16
		XOR		AL,BlendMask ; 31-blendsrc
		MOV		BP,AX
		SHL		EBP,16
		OR		BP,AX
		XOR		AL,BlendMask ; 31-blendsrc
		INC		AL
		SHR		DX,5 ; right shift red 5bits
		IMUL		BX,AX
		IMUL		CX,AX
		IMUL		DX,AX

		MOVD		mm7,EBP
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

		MOVQ		[QMulSrcBlend],mm7
		MOVQ		[QBlue16Blend],mm3
		MOVQ		[QGreen16Blend],mm4
		MOVQ		[QRed16Blend],mm5
; end prepare blend
		MOV		ESI,[SSSurf] ; sauvegarde la surf Source
		MOV		EDI,_SrcSurf

		MOV		EBP,[FinYPoly]
		CopySurf  ; copy the source texture surface
		SUB		EBP,[_OrgY]
		MOV		EBX,[DebYPoly] ; -
		IMUL		EBP,[_ScanLine]
		LEA		EDX,[EBX*4]    ; -
		SUB		EBX,[FinYPoly] ; -
		NEG		EBP
		NEG		EBX	       ; -
		ADD		EBP,[_vlfb]
		MOVD		mm6,EBP
		MOVD		mm7,[_ScanLine]
.BcFillText:	MOV		EDI,[_TPolyAdDeb+EDX+EBX*4]  ; X1
		MOV		ECX,[_TPolyAdFin+EDX+EBX*4]  ; X2
		MOV		EAX,[_TexXDeb+EDX+EBX*4]
		MOV		ESI,[_TexYDeb+EDX+EBX*4]
		MOV		[XT1],EAX
		MOV		[YT1],ESI
		MOV		EAX,[_TexXFin+EDX+EBX*4]
		MOV		ESI,[_TexYFin+EDX+EBX*4]
		MOV		[XT2],EAX
		MOV		[YT2],ESI

		CMP		ECX,EDI
		JG		.PasSwapAd
		XCHG		EDI,ECX
.PasSwapAd:
		PUSH		EBX
		PUSH		EDX
		MOV		EBX,[_MinX]
		MOV		EDX,[_MaxX]
		CMP		ECX,EBX	  	; [XP2] < [_MinX]
		JL		.PasDrwClTx
		CMP		EDI,EDX		; [XP1] > [_MaxX]
		JG		.PasDrwClTx
		SUB		ECX,EDI
		MOV		[Plus2],ECX	; Plus2 = DltX sans ajust
		XOR		EAX,EAX
		ADD		ECX,EDI
		CMP		ECX,EDX 	; [XP2] > [_MaxX]
		JLE		.PasAJX2
		MOV		ECX,EDX
.PasAJX2:	CMP		EDI,EBX 	; [XP1] < [_MinX]
		JGE		.PasAJX1
		MOV		EAX,EBX
		SUB		EAX,EDI         ; EAX = [_MinX] - [XP1]
		MOV		EDI,EBX
.PasAJX1:
		MOVD		ESI,mm6
		SUB		ECX,EDI
		MOV		[Plus],EAX
		;SHL		EDI,1 ; 16bpp : xdeb*2
		INC		ECX
		;ADD		EDI,ESI
		LEA		EDI,[ESI+EDI*2]
		@ClipMaskTextBlndHLine16
.PasDrwClTx:
		POP		EDX
		POP		EBX
		DEC		EBX
		PADDD		mm6,mm7
		JNS		.BcFillText
.FinClipText:

	@FILLRET16


;******* POLYTYPE = TEXT_TRANS

ALIGN 32
InFillTEXT_TRANS16:
        AND         DWORD [clr],BYTE BlendMask ;
		MOV			EDI,_SrcSurf
        JZ          .End ; zero transparency no need to draw any thing
		MOV			ESI,[SSSurf] ;
		CopySurf  		; copy the source texture surface

		@InCalcTextCnt
		; prepare transparency
		MOV         AX,[clr]
		MOV			DX,AX ;
		INC			AX
		XOR			DX,BlendMask ; 31-blendsrc
		MOV			EBX,[DebYPoly] ; -
		MOVD		mm7,EAX
		MOVD		mm6,EDX
		PUNPCKLWD	mm7,mm7
		PUNPCKLWD	mm6,mm6
		PUNPCKLDQ	mm7,mm7
		PUNPCKLDQ	mm6,mm6
		; counter/indexes
		LEA			EDX,[EBX*4]    ; -
		SUB			EBX,[FinYPoly] ; -  EBX = DebYPoly-FinYPoly
		NEG			EBX	       ; -  EBX = FinYPoly-DebYPoly
		MOV			[DebStartAddr],EDX
		MOV			[HzLinesCount],EBX
;ALIGN 4
.BcFillText:
		LEA			EBX,[EDX+EBX*4]
		MOV			EDI,[_TPolyAdDeb+EBX]
		MOV			ECX,[_TPolyAdFin+EBX]
		MOV			EAX,[_TexXDeb+EBX]
		MOV			ESI,[_TexYDeb+EBX]
		MOV			[XT1],EAX
		MOV			[YT1],ESI
		MOV			EAX,[_TexXFin+EBX]
		MOV			ESI,[_TexYFin+EBX]
		MOV			[XT2],EAX
		MOV			[YT2],ESI

		CMP			ECX,EDI
		JG			.PasSwapAd
		XCHG		EDI,ECX
.PasSwapAd:
		SUB			ECX,EDI
		SHR			ECX,1
		@InTransTextHLine16
		DEC			DWORD [HzLinesCount]
		MOV			EDX,[DebStartAddr]
		MOV			EBX,[HzLinesCount]
		JNS			.BcFillText
.End:
    @FILLRET16

ALIGN 32
ClipFillTEXT_TRANS16:
        AND         DWORD [clr],BYTE BlendMask ;
		MOV			EDI,_SrcSurf
        JZ          .End ; zero transparency no need to draw any thing
		MOV			ESI,[SSSurf] ; sauvegarde la surf Source
		MOV			EDI,_SrcSurf
		CopySurf  ; copy the source texture surface

		@ClipCalcTextCnt
		; prepare transparency
		MOV         AX,[clr]
		MOV			DX,AX ;
		INC			AX
		XOR			DX,BlendMask ; 31-blendsrc
		MOVD		mm7,EAX
		MOVD		mm6,EDX
		PUNPCKLWD	mm7,mm7
		PUNPCKLWD	mm6,mm6
		PUNPCKLDQ	mm7,mm7
		PUNPCKLDQ	mm6,mm6
		; counter/indexes

		MOV			EBP,[FinYPoly]
		SUB			EBP,[_OrgY]
		MOV			EBX,[DebYPoly] ; -
		IMUL		EBP,[_ScanLine]
		LEA			EDX,[EBX*4]    ; -
		SUB			EBX,[FinYPoly] ; -
		NEG			EBP
		NEG			EBX	       ; -
		MOV			[DebStartAddr],EDX
		MOV			[HzLinesCount],EBX

		ADD			EBP,[_vlfb]
		MOV			[ClipHStartAddr],EBP
.BcFillText:
		MOV			EDI,[_TPolyAdDeb+EDX+EBX*4]  ; X1
		MOV			ECX,[_TPolyAdFin+EDX+EBX*4]  ; X2
		MOV			EAX,[_TexXDeb+EDX+EBX*4]
		MOV			ESI,[_TexYDeb+EDX+EBX*4]
		MOV			[XT1],EAX
		MOV			[YT1],ESI
		MOV			EAX,[_TexXFin+EDX+EBX*4]
		MOV			ESI,[_TexYFin+EDX+EBX*4]
		MOV			[XT2],EAX
		MOV			[YT2],ESI

		CMP			ECX,EDI
		JG			.PasSwapAd
		XCHG		EDI,ECX
.PasSwapAd:
		MOV			EBX,[_MinX]
		MOV			EDX,[_MaxX]
		CMP			ECX,EBX	  	; [XP2] < [_MinX]
		JL			.PasDrwClTx
		CMP			EDI,EDX		; [XP1] > [_MaxX]
		JG			.PasDrwClTx
		SUB			ECX,EDI
		MOV			[Plus2],ECX	; Plus2 = DltX sans ajust
		XOR			EAX,EAX
		ADD			ECX,EDI
		CMP			ECX,EDX 	; [XP2] > [_MaxX]
		JLE			.PasAJX2
		MOV			ECX,EDX
.PasAJX2:
		CMP			EDI,EBX 	; [XP1] < [_MinX]
		JGE			.PasAJX1
		MOV			EAX,EBX
		SUB			EAX,EDI         ; EAX = [_MinX] - [XP1]
		MOV			EDI,EBX
.PasAJX1:
		MOV			ESI,EBP 	; hz start adress
		SUB			ECX,EDI
		MOV			[Plus],EAX
		;SHL		EDI,1 ; 16bpp : xdeb*2
		INC			ECX
		;ADD		EDI,ESI
		LEA			EDI,[ESI+EDI*2]
		@ClipTransTextHLine16
.PasDrwClTx:
		MOV			EBP,[_ScanLine]
		MOV			EDX,[DebStartAddr]
		ADD			EBP,[ClipHStartAddr] ; EBP = new hz start adress
		DEC			DWORD [HzLinesCount]
		MOV			[ClipHStartAddr],EBP ; save hz start adress
		MOV			EBX,[HzLinesCount]
		JNS			.BcFillText
.FinClipText:

.End:
    @FILLRET16

;******* POLYTYPE = MASK_TEXT_TRANS
ALIGN 32
InFillMASK_TEXT_TRANS16:

        AND         DWORD [clr],BYTE BlendMask ;
		MOV			EDI,_SrcSurf
        JZ          .End ; zero transparency no need to draw any thing
		MOV			ESI,[SSSurf] ;
		CopySurf  		; copy the source texture surface

		@InCalcTextCnt
		; prepare transparency / mask
		MOV         AX,[clr]
		MOV			DX,AX ;
		INC			AX
		XOR			DX,BlendMask ; 31-blendsrc
		MOVD		mm0,[SMask]
		MOVD		mm7,EAX
		MOVD		mm6,EDX
		PUNPCKLWD	mm0,mm0
		PUNPCKLWD	mm7,mm7
		PUNPCKLWD	mm6,mm6
		PUNPCKLDQ	mm0,mm0
		PUNPCKLDQ	mm7,mm7
		PUNPCKLDQ	mm6,mm6
		MOVQ		[QSMask16],mm0
		; counter/indexes
		MOV			EBX,[DebYPoly] ; -
		LEA			EDX,[EBX*4]    ; -
		SUB			EBX,[FinYPoly] ; -  EBX = DebYPoly-FinYPoly
		NEG			EBX	       ; -  EBX = FinYPoly-DebYPoly
		MOV			[DebStartAddr],EDX
		MOV			[HzLinesCount],EBX
;ALIGN 4
.BcFillText:
		LEA			EBX,[EDX+EBX*4]
		MOV			EDI,[_TPolyAdDeb+EBX]
		MOV			ECX,[_TPolyAdFin+EBX]
		MOV			EAX,[_TexXDeb+EBX]
		MOV			ESI,[_TexYDeb+EBX]
		MOV			[XT1],EAX
		MOV			[YT1],ESI
		MOV			EAX,[_TexXFin+EBX]
		MOV			ESI,[_TexYFin+EBX]
		MOV			[XT2],EAX
		MOV			[YT2],ESI

		CMP			ECX,EDI
		JG			.PasSwapAd
		XCHG		EDI,ECX
.PasSwapAd:
		SUB			ECX,EDI
		SHR			ECX,1
		@InMaskTransTextHLine16
		DEC			DWORD [HzLinesCount]
		MOV			EDX,[DebStartAddr]
		MOV			EBX,[HzLinesCount]
		JNS			.BcFillText
.End:
    @FILLRET16


ALIGN 32
ClipFillMASK_TEXT_TRANS16:
        AND         DWORD [clr],BYTE BlendMask ;
		MOV			EDI,_SrcSurf
        JZ          .End ; zero transparency no need to draw any thing
		MOV			ESI,[SSSurf] ; sauvegarde la surf Source
		MOV			EDI,_SrcSurf
		CopySurf  ; copy the source texture surface

		@ClipCalcTextCnt
		; prepare transparency / mask
		MOV         AX,[clr]
		MOV			DX,AX ;
		INC			AX
		XOR			DX,BlendMask ; 31-blendsrc
		MOVD		mm0,[SMask]
		MOVD		mm7,EAX
		MOVD		mm6,EDX
		PUNPCKLWD	mm0,mm0
		PUNPCKLWD	mm7,mm7
		PUNPCKLWD	mm6,mm6
		PUNPCKLDQ	mm0,mm0
		PUNPCKLDQ	mm7,mm7
		PUNPCKLDQ	mm6,mm6
		MOVQ		[QSMask16],mm0
		; counter/indexes

		MOV			EBP,[FinYPoly]
		MOV			EBX,[DebYPoly] ; -
		SUB			EBP,[_OrgY]
		MOV			EBX,[DebYPoly] ; -
		IMUL		EBP,[_ScanLine]
		LEA			EDX,[EBX*4]    ; -
		SUB			EBX,[FinYPoly] ; -
		NEG			EBP
		NEG			EBX	       ; -
		MOV			[DebStartAddr],EDX
		MOV			[HzLinesCount],EBX

		ADD			EBP,[_vlfb]
		MOV			[ClipHStartAddr],EBP
.BcFillText:
		MOV			EDI,[_TPolyAdDeb+EDX+EBX*4]  ; X1
		MOV			ECX,[_TPolyAdFin+EDX+EBX*4]  ; X2
		MOV			EAX,[_TexXDeb+EDX+EBX*4]
		MOV			ESI,[_TexYDeb+EDX+EBX*4]
		MOV			[XT1],EAX
		MOV			[YT1],ESI
		MOV			EAX,[_TexXFin+EDX+EBX*4]
		MOV			ESI,[_TexYFin+EDX+EBX*4]
		MOV			[XT2],EAX
		MOV			[YT2],ESI

		CMP			ECX,EDI
		JG			.PasSwapAd
		XCHG		EDI,ECX
.PasSwapAd:
		MOV			EBX,[_MinX]
		MOV			EDX,[_MaxX]
		CMP			ECX,EBX	  	; [XP2] < [_MinX]
		JL			.PasDrwClTx
		CMP			EDI,EDX		; [XP1] > [_MaxX]
		JG			.PasDrwClTx
		SUB			ECX,EDI
		MOV			[Plus2],ECX	; Plus2 = DltX sans ajust
		XOR			EAX,EAX
		ADD			ECX,EDI
		CMP			ECX,EDX 	; [XP2] > [_MaxX]
		JLE			.PasAJX2
		MOV			ECX,EDX
.PasAJX2:
		CMP			EDI,EBX 	; [XP1] < [_MinX]
		JGE			.PasAJX1
		MOV			EAX,EBX
		SUB			EAX,EDI         ; EAX = [_MinX] - [XP1]
		MOV			EDI,EBX
.PasAJX1:
		MOV			ESI,EBP 	; hz start adress
		SUB			ECX,EDI
		MOV			[Plus],EAX
		INC			ECX
		LEA			EDI,[ESI+EDI*2]
		@ClipMaskTransTextHLine16
.PasDrwClTx:
		MOV			EBP,[_ScanLine]
		ADD			EBP,[ClipHStartAddr] ; EBP = new hz start adress
		DEC			DWORD [HzLinesCount]
		MOV			EDX,[DebStartAddr]
		MOV			[ClipHStartAddr],EBP ; save hz start adress
		MOV			EBX,[HzLinesCount]
		JNS			.BcFillText
.FinClipText:

.End:
    @FILLRET16
