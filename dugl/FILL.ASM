DegMask		EQU		0x3f

; param ESI: source Surf, EDI: Dest Surf
; use mm0, ... , mm7
; return no : surf copied
%macro	CopySurf	0
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
		MOVQ		[EDI+32],mm1
		MOVQ		[EDI+8],mm2
		MOVQ		[EDI+40],mm3
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

;******* POLYTYPE = SOLID
ALIGN 32
InFillSOLID:
		MOV       	EAX,[clr] ; rempli le polygone avec clr
		MOV		EBX,[DebYPoly]	; -
                MOV       	AH,AL
		LEA		EDX,[EBX*4]	; -
		MOV		ECX,EAX
		SUB		EBX,[FinYPoly]	; -
		BSWAP     	EAX
		NEG		EBX		; -
		MOV		AX,CX
;ALIGN 4
.BcFillText:	MOV		EDI,[_TPolyAdDeb+EDX+EBX*4]
		MOV		ESI,[_TPolyAdFin+EDX+EBX*4]
		CMP		ESI,EDI
		JG		.PasSwapAd
		XCHG		EDI,ESI
.PasSwapAd:	SUB		ESI,EDI
		INC		ESI
		@SolidHLine
		DEC		EBX
		JNS		.BcFillText

		RET
ALIGN 32
ClipFillSOLID:
		MOV		EAX,[clr] ; rempli le polygone avec clr
		MOV		AH,AL
		MOV		EBX,EAX
		BSWAP		EAX
		MOV		AX,BX

		MOV		EBP,[FinYPoly]
		MOV		EBX,[DebYPoly]
		SUB		EBP,[_OrgY]
		IMUL		EBP,[_ResH]
		LEA		EDX,[EBX*4]
		SUB		EBX,[FinYPoly]
		NEG		EBP
		NEG		EBX
		ADD		EBP,[_vlfb]
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
		MOVD		ECX,mm3
		SUB		ESI,EDI
		INC		ESI
		ADD		EDI,ECX
		@SolidHLine
.PasDrwClSD:
		DEC		EBX
		PADDD		mm3,[_ResH]
		JNS		.BcFillSolid
.FinClipSOLID:
		RET
                
;******* POLYTYPE = TEXT
ALIGN 32
InFillTEXT:
		@InCalcTextCnt
		MOV		ESI,[SSSurf] ; sauvegarde la surf Source
		MOV		EBX,[DebYPoly] ; -
		MOV		EDI,Svlfb
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
		@InTextHLine
		MOVD		EBX,mm7
		MOVD		EDX,mm6
		DEC		EBX
		JNS		.BcFillText

		RET

ALIGN 32
ClipFillTEXT:
                @ClipCalcTextCnt
		MOV		ESI,[SSSurf] ; sauvegarde la surf Source
		;XOR		ECX,ECX
		MOV		EDI,Svlfb
		;OR		ECX,BYTE 16  ; == MOV ECX,16

		MOV		EBP,[FinYPoly]
		CopySurf  ; copy the source texture surface
		;REP		MOVSD
		SUB		EBP,[_OrgY]
		MOV		EBX,[DebYPoly] ; -
		IMUL		EBP,[_ResH]
		LEA		EDX,[EBX*4]    ; -
		SUB		EBX,[FinYPoly] ; -
		NEG		EBP
		NEG		EBX	       ; -
		ADD		EBP,[_vlfb]
		MOVD		mm3,EBP
		MOVD		mm4,[_ResH]
;ALIGN 4
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
		INC		ECX
		ADD		EDI,ESI
		@ClipTextHLine
.PasDrwClTx:
		MOVD		EBX,mm7
		MOVD		EDX,mm6
		DEC		EBX
		PADDD		mm3,mm4
		JNS		.BcFillText
.FinClipText:
		RET

;******* POLYTYPE = MASK_TEXT
ALIGN 32
InFillMASK_TEXT:
		@InCalcTextCnt
		MOV		ESI,[SSSurf] ; sauvegarde la surf Source
		MOV		EBX,[DebYPoly] ; -
		MOV		EDI,Svlfb
		LEA		EDX,[EBX*4]    ; -
		;MOV		ECX,16
		SUB		EBX,[FinYPoly] ; -
		CopySurf  ; copy the source texture surface
		;REP		MOVSD
		NEG		EBX	       ; -
;ALIGN 4
.BcFillText:	MOV		EDI,[_TPolyAdDeb+EDX+EBX*4]
		MOV		ECX,[_TPolyAdFin+EDX+EBX*4]
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
.PasSwapAd:	MOVD		mm7,EBX
		SUB		ECX,EDI
		MOVD		mm6,EDX
		@InMaskTextHLine
		MOVD		EBX,mm7
		MOVD		EDX,mm6
		DEC		EBX
		JNS		.BcFillText

		RET

ALIGN 32
ClipFillMASK_TEXT:
                @ClipCalcTextCnt
		MOV		ESI,[SSSurf] ; sauvegarde la surf Source
		MOV		EDI,Svlfb
;		MOV		ECX,16

		MOV		EBP,[FinYPoly]
		CopySurf  ; copy the source texture surface
		;REP		MOVSD
		SUB		EBP,[_OrgY]
		MOV		EBX,[DebYPoly] ; -
		IMUL		EBP,[_ResH]
		LEA		EDX,[EBX*4]    ; -
		SUB		EBX,[FinYPoly] ; -
		NEG		EBP
		NEG		EBX	       ; -
		ADD		EBP,[_vlfb]
		MOVD		mm3,EBP
		MOVD		mm4,[_ResH]
;ALIGN 4
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
		INC		ECX
		ADD		EDI,ESI
		@ClipMaskTextHLine
.PasDrwClTx:
		MOVD		EBX,mm7
		MOVD		EDX,mm6
		DEC		EBX
		PADDD		mm3,mm4
		JNS		.BcFillText
.FinClipText:
		RET

;******* POLYTYPE = FLAT_DEG
ALIGN 32
InFillFLAT_DEG:
		MOV		ESI,[PPtrListPt]
		MOV		EDX,[clr]
		MOV		EBX,[ESI]
		AND		EDX,0xff
		MOV		EAX,[EBX+20]
		SHL		EDX,6
		AND		EAX,DegMask
		LEA		EDI,[EAX+_TbDegCol]
		MOV		ESI,InFillSOLID
		MOV		EAX,[EDI+EDX]
		MOV		[clr],EAX
		JMP		ESI

		RET

ALIGN 32
ClipFillFLAT_DEG:
		MOV		ESI,[PPtrListPt]
		MOV		EDX,[clr]
		MOV		EBX,[ESI]
		AND		EDX,0xff
		MOV		EAX,[EBX+20]
		SHL		EDX,6
		AND		EAX,DegMask
		LEA		EDI,[EAX+_TbDegCol]
		MOV		ESI,ClipFillSOLID
		MOV		EAX,[EDI+EDX]
		MOV		[clr],EAX
		JMP		ESI

		RET

;******* POLYTYPE = DEG
;EAX;charge,EBX;l,;ECX;cpt hz,;EDX;l,;ESI;ptrTbDegCol,;EDI;Dest;EBP; l

ALIGN 32
InFillDEG:
		@InCalcDColCnt
		MOV		ESI,[clr]
		MOV		EBX,[DebYPoly] ; -
		AND		ESI,0xff
		LEA		EDX,[EBX*4]    ; -
		SHL		ESI,6 ; ESI*=32 Ptr TbDegCol
		SUB		EBX,[FinYPoly] ; -  EBX = DebYPoly-FinYPoly
		ADD		ESI,_TbDegCol  ; ESI+=OFFSET _TbDegCol
		NEG		EBX	       ; -  EBX = FinYPoly-DebYPoly
		MOVD		mm5,ESI
;ALIGN 4
.BcFillDEG:
		MOV		ECX,[_TPolyAdFin+EDX+EBX*4]
		MOV		EDI,[_TPolyAdDeb+EDX+EBX*4]
		MOV		EBP,[_PColDeb+EDX+EBX*4]
		MOV		EAX,[_PColFin+EDX+EBX*4]
                
		CMP		ECX,EDI
		JG		.PasSwapAd
		XCHG		EDI,ECX
.PasSwapAd:	MOVD		ESI,mm5
		SUB		ECX,EDI
		MOVD		mm7,EBX
		MOVD		mm6,EDX
		@InDEGHLine
		MOVD		EBX,mm7
		MOVD		EDX,mm6
		DEC		EBX
		JNS		.BcFillDEG

		RET

ALIGN 32
ClipFillDEG:
		@ClipCalcDColCnt

		MOV		ESI,[clr]
		AND		ESI,0xff
		SHL		ESI,6 ; ESI*=32 Ptr TbDegCol
		ADD		ESI,_TbDegCol  ; ESI+=OFFSET _TbDegCol
		MOVD		mm5,ESI
		
		MOV		EBP,[FinYPoly]
		SUB		EBP,[_OrgY]
		MOV		EBX,[DebYPoly] ; -
		IMUL		EBP,[_ResH]
		LEA		EDX,[EBX*4]    ; -
		SUB		EBX,[FinYPoly] ; -
		NEG		EBP
		NEG		EBX	       ; -
		ADD		EBP,[_vlfb]
		MOVD		mm3,EBP
		MOVD		mm4,[_ResH]
;ALIGN 4
.BcFillDEG:
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
		INC		ECX
		ADD		EDI,ESI
		MOV		EBP,[Col1]
		MOV		EAX,[Col2]
		MOVD		ESI,mm5
		@ClipDEGHLine
.PasDrwClTx:
		MOVD		EBX,mm7
		MOVD		EDX,mm6
		DEC		EBX
		PADDD		mm3,mm4
		JNS		.BcFillDEG
.FinClipDEG:
		RET
		
;******* POLYTYPE = FLAT_DEG_TEXT
ALIGN 32
InFillFLAT_DEG_TEXT:
		@InCalcTextCnt

		MOV		EDI,[PPtrListPt]  ; *
		MOV		ECX,[EDI]	  ; *
		MOV		ESI,[SSSurf] ; sauvegarde la surf Source
		MOV		EAX,[ECX+20]	  ; * DEG
		MOV		EBX,[DebYPoly] ; -
		AND		EAX,DegMask	  ; **
		;XOR		ECX,ECX
		ADD		EAX,_TbDegCol	  ; ***
		MOV		EDI,Svlfb
		MOV		[PtrTbDegCol],EAX ; ****
		LEA		EDX,[EBX*4]    ; -
		;OR		ECX,BYTE 16    ; == MOV ECX,16
		SUB		EBX,[FinYPoly] ; -  EBX = DebYPoly-FinYPoly
		CopySurf  ; copy the source texture surface
		;REP		MOVSD
		NEG		EBX	       ; -  EBX = FinYPoly-DebYPoly
;ALIGN 4
.BcFillText:	MOV		EDI,[_TPolyAdDeb+EDX+EBX*4]
		MOV		ECX,[_TPolyAdFin+EDX+EBX*4]
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
.PasSwapAd:	MOVD		mm7,EBX
		SUB		ECX,EDI
		MOVD		mm6,EDX
		@InFDegTextHLine
		MOVD		EBX,mm7
		MOVD		EDX,mm6
		DEC		EBX
		JNS		.BcFillText

		RET

ALIGN 32
ClipFillFLAT_DEG_TEXT:
                @ClipCalcTextCnt
		MOV		EDI,[PPtrListPt]  ; *
		MOV		ECX,[EDI]	  ; *
		MOV		ESI,[SSSurf] ; sauvegarde la surf Source
		MOV		EAX,[ECX+20]	  ; * DEG
		AND		EAX,DegMask	  ; **
		;XOR		ECX,ECX
		ADD		EAX,_TbDegCol	  ; ***
		MOV		EDI,Svlfb
		MOV		[PtrTbDegCol],EAX ; ****
		;OR		ECX,BYTE 16  ; == MOV ECX,16

		MOV		EBP,[FinYPoly]
		CopySurf  ; copy the source texture surface

		;REP		MOVSD
		SUB		EBP,[_OrgY]
		MOV		EBX,[DebYPoly] ; -
		IMUL		EBP,[_ResH]
		LEA		EDX,[EBX*4]    ; -
		SUB		EBX,[FinYPoly] ; -
		NEG		EBP
		NEG		EBX	       ; -
		ADD		EBP,[_vlfb]
		MOV		[ChPlus],EBP ; ChPlus=AddLgn
;ALIGN 4
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
		MOV		ESI,[ChPlus]
		SUB		ECX,EDI
		MOV		[Plus],EAX
		INC		ECX
		ADD		EDI,ESI
		@ClipFDegTextHLine
.PasDrwClTx:
		MOVD		EBX,mm7
		MOV		EAX,[_ResH]
		MOVD		EDX,mm6
		ADD		[ChPlus],EAX
		DEC		EBX
		JNS		.BcFillText
.FinClipText:
		RET


;******* POLYTYPE = MASK_FLAT_DEG_TEXT
ALIGN 32
InFillMASK_FLAT_DEG_TEXT:
		@InCalcTextCnt

		MOV		EDI,[PPtrListPt]  ; *
		MOV		ECX,[EDI]	  ; *
		MOV		ESI,[SSSurf] ; sauvegarde la surf Source
		MOV		EAX,[ECX+20]	  ; * DEG

		MOV		EBX,[DebYPoly] ; -
		AND		EAX,DegMask	  ; **
		;XOR		ECX,ECX
		ADD		EAX,_TbDegCol	  ; ***
		MOV		EDI,Svlfb
		MOV		[PtrTbDegCol],EAX ; ****
		LEA		EDX,[EBX*4]    ; -
		;OR		ECX,BYTE 16    ; == MOV ECX,16
		SUB		EBX,[FinYPoly] ; -  EBX = DebYPoly-FinYPoly
		CopySurf  ; copy the source texture surface
		;REP		MOVSD
		NEG		EBX	       ; -  EBX = FinYPoly-DebYPoly
;ALIGN 4
.BcFillText:	MOV		EDI,[_TPolyAdDeb+EDX+EBX*4]
		MOV		ECX,[_TPolyAdFin+EDX+EBX*4]
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
.PasSwapAd:	MOVD		mm7,EBX
		SUB		ECX,EDI
		MOVD		mm6,EDX
		@InMASKFDegTextHLine
		MOVD		EBX,mm7
		MOVD		EDX,mm6
		DEC		EBX
		JNS		.BcFillText

		RET


ALIGN 32
ClipFillMASK_FLAT_DEG_TEXT:
                @ClipCalcTextCnt
		MOV		EDI,[PPtrListPt]  ; *
		MOV		ECX,[EDI]	  ; *
		MOV		ESI,[SSSurf] ; sauvegarde la surf Source
		MOV		EAX,[ECX+20]	  ; * DEG

		AND		EAX,DegMask	  ; **
		;XOR		ECX,ECX
		ADD		EAX,_TbDegCol	  ; ***
		MOV		EDI,Svlfb
		MOV		[PtrTbDegCol],EAX ; ****
		;OR		ECX,BYTE 16  ; == MOV ECX,16

		MOV		EBP,[FinYPoly]
		CopySurf  ; copy the source texture surface
		;REP		MOVSD
		SUB		EBP,[_OrgY]
		MOV		EBX,[DebYPoly] ; -
		IMUL		EBP,[_ResH]
		LEA		EDX,[EBX*4]    ; -
		SUB		EBX,[FinYPoly] ; -
		NEG		EBP
		NEG		EBX	       ; -
		ADD		EBP,[_vlfb]
		MOV		[ChPlus],EBP ; ChPlus=AddLgn
;ALIGN 4
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
		MOV		ESI,[ChPlus]
		SUB		ECX,EDI
		MOV		[Plus],EAX
		INC		ECX
		ADD		EDI,ESI
		@ClipMASKFDegTextHLine
.PasDrwClTx:
		MOVD		EBX,mm7
		MOV		EAX,[_ResH]
		MOVD		EDX,mm6
		ADD		[ChPlus],EAX
		DEC		EBX
		JNS		.BcFillText
.FinClipText:
		RET


;******* POLYTYPE = DEG_TEXT
ALIGN 32
InFillDEG_TEXT:
		@InCalcTextCnt
		@InCalcDColCnt

		MOV		ESI,[SSSurf] ; sauvegarde la surf Source
		MOV		EBX,[DebYPoly] ; -
		;XOR		ECX,ECX
		MOV		EDI,Svlfb
		LEA		EDX,[EBX*4]    ; -
		;OR		ECX,BYTE 16    ; == MOV ECX,16
		SUB		EBX,[FinYPoly] ; -  EBX = DebYPoly-FinYPoly
		CopySurf  ; copy the source texture surface
		;REP		MOVSD
		NEG		EBX	       ; -  EBX = FinYPoly-DebYPoly
;ALIGN 4
.BcFillText:	MOV		EDI,[_TPolyAdDeb+EDX+EBX*4]
		MOV		ECX,[_TPolyAdFin+EDX+EBX*4]
		
		MOV		EBP,[_PColDeb+EDX+EBX*4]
		MOV		EAX,[_PColFin+EDX+EBX*4]
		MOV		[Col1],EBP
		MOV		[Col2],EAX
		
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
.PasSwapAd:	MOVD		mm7,EBX
		SUB		ECX,EDI
		MOVD		mm6,EDX
		@InDegTextHLine
		MOVD		EBX,mm7
		MOVD		EDX,mm6
		DEC		EBX
		JNS		.BcFillText

		RET

ALIGN 32
ClipFillDEG_TEXT:
                @ClipCalcTextCnt
		@ClipCalcDColCnt
		MOV		ESI,[SSSurf] ; sauvegarde la surf Source
		;XOR		ECX,ECX
		MOV		EDI,Svlfb
		;OR		ECX,BYTE 16  ; == MOV ECX,16

		MOV		EBP,[FinYPoly]
		CopySurf  ; copy the source texture surface
		;REP		MOVSD
		SUB		EBP,[_OrgY]
		MOV		EBX,[DebYPoly] ; -
		IMUL		EBP,[_ResH]
		LEA		EDX,[EBX*4]    ; -
		SUB		EBX,[FinYPoly] ; -
		NEG		EBP
		NEG		EBX	       ; -
		ADD		EBP,[_vlfb]
		MOV		[ChPlus],EBP ; ChPlus=AddLgn
;ALIGN 4
.BcFillText:	MOV		EDI,[_TPolyAdDeb+EDX+EBX*4]  ; X1
		MOV		ECX,[_TPolyAdFin+EDX+EBX*4]  ; X2

		MOV		EBP,[_PColDeb+EDX+EBX*4]
		MOV		EAX,[_PColFin+EDX+EBX*4]
		MOV		[Col1],EBP
		MOV		[Col2],EAX

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
		MOV		ESI,[ChPlus]
		SUB		ECX,EDI
		MOV		[Plus],EAX
		INC		ECX
		ADD		EDI,ESI
		@ClipDegTextHLine
.PasDrwClTx:
		MOVD		EBX,mm7
		MOV		EAX,[_ResH]
		MOVD		EDX,mm6
		ADD		[ChPlus],EAX
		DEC		EBX
		JNS		.BcFillText
.FinClipText:
		RET


;******* POLYTYPE = MASK_DEG_TEXT
ALIGN 32
InFillMASK_DEG_TEXT:
		@InCalcTextCnt
		@InCalcDColCnt

		MOV		ESI,[SSSurf] ; sauvegarde la surf Source
		MOV		EBX,[DebYPoly] ; -
		;XOR		ECX,ECX
		MOV		EDI,Svlfb
		LEA		EDX,[EBX*4]    ; -
		;OR		ECX,BYTE 16    ; == MOV ECX,16
		SUB		EBX,[FinYPoly] ; -  EBX = DebYPoly-FinYPoly
		CopySurf  ; copy the source texture surface
		;REP		MOVSD
		NEG		EBX	       ; -  EBX = FinYPoly-DebYPoly
;ALIGN 4
.BcFillText:	MOV		EDI,[_TPolyAdDeb+EDX+EBX*4]
		MOV		ECX,[_TPolyAdFin+EDX+EBX*4]
		
		MOV		EBP,[_PColDeb+EDX+EBX*4]
		MOV		EAX,[_PColFin+EDX+EBX*4]
		MOV		[Col1],EBP
		MOV		[Col2],EAX
		
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
.PasSwapAd:	MOVD		mm7,EBX
		SUB		ECX,EDI
		MOVD		mm6,EDX
		@InMaskDegTextHLine
		MOVD		EBX,mm7
		MOVD		EDX,mm6
		DEC		EBX
		JNS		.BcFillText

		RET

ALIGN 32
ClipFillMASK_DEG_TEXT:
                @ClipCalcTextCnt
		@ClipCalcDColCnt
		MOV		ESI,[SSSurf] ; sauvegarde la surf Source
		;XOR		ECX,ECX
		MOV		EDI,Svlfb
		;OR		ECX,BYTE 16  ; == MOV ECX,16

		MOV		EBP,[FinYPoly]
		;REP		MOVSD
		CopySurf  ; copy the source texture surface
		SUB		EBP,[_OrgY]
		MOV		EBX,[DebYPoly] ; -
		IMUL		EBP,[_ResH]
		LEA		EDX,[EBX*4]    ; -
		SUB		EBX,[FinYPoly] ; -
		NEG		EBP
		NEG		EBX	       ; -
		ADD		EBP,[_vlfb]
		MOV		[ChPlus],EBP ; ChPlus=AddLgn
;ALIGN 4
.BcFillText:	MOV		EDI,[_TPolyAdDeb+EDX+EBX*4]  ; X1
		MOV		ECX,[_TPolyAdFin+EDX+EBX*4]  ; X2

		MOV		EBP,[_PColDeb+EDX+EBX*4]
		MOV		EAX,[_PColFin+EDX+EBX*4]
		MOV		[Col1],EBP
		MOV		[Col2],EAX

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
		MOV		ESI,[ChPlus]
		SUB		ECX,EDI
		MOV		[Plus],EAX
		INC		ECX
		ADD		EDI,ESI
		@ClipMaskDegTextHLine
.PasDrwClTx:
		MOVD		EBX,mm7
		MOV		EAX,[_ResH]
		MOVD		EDX,mm6
		ADD		[ChPlus],EAX
		DEC		EBX
		JNS		.BcFillText
.FinClipText:
		RET

;******* POLYTYPE = EFF_FDEG
ALIGN 32
InFillEFF_FDEG:
		MOV		EDI,[PPtrListPt]  ; *
		MOV		EBX,[DebYPoly] ; -
		MOV		ECX,[EDI]	  ; *
		LEA		EDX,[EBX*4]    ; -
		MOV		ESI,[ECX+20]	  ; * DEG
		SUB		EBX,[FinYPoly] ; -  EBX = DebYPoly-FinYPoly
		AND		ESI,DegMask
		ADD		ESI,_TbDegCol  ; ESI+=OFFSET _TbDegCol
		NEG		EBX	       ; -  EBX = FinYPoly-DebYPoly
		MOVD		mm5,ESI
;ALIGN 4
.BcFillDEG:
		MOV		ECX,[_TPolyAdFin+EDX+EBX*4]
		MOV		EDI,[_TPolyAdDeb+EDX+EBX*4]
                
		CMP		ECX,EDI
		JG		.PasSwapAd
		XCHG		EDI,ECX
.PasSwapAd:	SUB		ECX,EDI
		INC		ECX
		MOVD		mm7,EBX
		MOVD		mm6,EDX
		@EFF_FDEGHLine
		MOVD		EBX,mm7
		MOVD		EDX,mm6
		DEC		EBX
		JNS		.BcFillDEG

		RET

ALIGN 32
ClipFillEFF_FDEG:
		MOV		EDI,[PPtrListPt]  ; *
		MOV		ECX,[EDI]	  ; *
		MOV		ESI,[ECX+20]	  ; * DEG
		AND		ESI,DegMask
		ADD		ESI,_TbDegCol  ; ESI+=OFFSET _TbDegCol
		MOVD		mm5,ESI
		
		MOV		EBP,[FinYPoly]
		SUB		EBP,[_OrgY]
		MOV		EBX,[DebYPoly] ; -
		IMUL		EBP,[_ResH]
		LEA		EDX,[EBX*4]    ; -
		SUB		EBX,[FinYPoly] ; -
		NEG		EBP
		NEG		EBX	       ; -
		ADD		EBP,[_vlfb]
		MOVD		mm3,EBP
		MOVD		mm4,[_ResH]
;ALIGN 4
.BcFillDEG:
		MOV		ECX,[_TPolyAdFin+EDX+EBX*4]  ; X2
		MOV		EDI,[_TPolyAdDeb+EDX+EBX*4]  ; X1

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
		INC		ECX
		MOV		[Plus2],ECX	; Plus2 = DltX sans ajust
		XOR		EAX,EAX
		ADD		ECX,EDI
		DEC		ECX
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
		INC		ECX
		ADD		EDI,ESI
		MOV		EBP,[Col1]
		MOV		EAX,[Col2]
		MOVD		ESI,mm5
		@EFF_FDEGHLine
.PasDrwClTx:
		MOVD		EBX,mm7
		MOVD		EDX,mm6
		DEC		EBX
		PADDD		mm3,mm4
		JNS		.BcFillDEG
.FinClipDEG:
		RET


;******* POLYTYPE = EFF_DEG
ALIGN 32
InFillEFF_DEG:
		@InCalcDColCnt

		MOV		EBX,[DebYPoly] ; -
		LEA		EDX,[EBX*4]    ; -
		SUB		EBX,[FinYPoly] ; -  EBX = DebYPoly-FinYPoly
		NEG		EBX	       ; -  EBX = FinYPoly-DebYPoly
;ALIGN 4
.BcFillDEG:
		MOV		ECX,[_TPolyAdFin+EDX+EBX*4]
		MOV		EDI,[_TPolyAdDeb+EDX+EBX*4]
		MOV		EAX,[_PColFin+EDX+EBX*4]
		MOV		EBP,[_PColDeb+EDX+EBX*4]

		CMP		ECX,EDI
		JG		.PasSwapAd
		XCHG		EDI,ECX
.PasSwapAd:	MOVD		mm7,EBX
		SUB		ECX,EDI
		MOVD		mm6,EDX
		@InEFF_DEGHLine
		MOVD		EBX,mm7
		MOVD		EDX,mm6
		DEC		EBX
		JNS		.BcFillDEG

		RET

ALIGN 32
ClipFillEFF_DEG:
		@ClipCalcDColCnt

		MOV		EBP,[FinYPoly]
		SUB		EBP,[_OrgY]
		MOV		EBX,[DebYPoly] ; -
		IMUL		EBP,[_ResH]
		LEA		EDX,[EBX*4]    ; -
		SUB		EBX,[FinYPoly] ; -
		NEG		EBP
		NEG		EBX	       ; -
		ADD		EBP,[_vlfb]
		MOVD		mm3,EBP
		MOVD		mm4,[_ResH]
;ALIGN 4
.BcFillDEG:
		MOV		ECX,[_TPolyAdFin+EDX+EBX*4]  ; X2
		MOV		EDI,[_TPolyAdDeb+EDX+EBX*4]  ; X1
		MOV		EAX,[_PColFin+EDX+EBX*4]
		MOV		EBP,[_PColDeb+EDX+EBX*4]
		MOV		[Col2],EAX
		MOV		[Col1],EBP

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
		INC		ECX
		ADD		EDI,ESI
		MOV		EBP,[Col1]
		MOV		EAX,[Col2]
		@ClipEFF_DEGHLine
.PasDrwClTx:
		MOVD		EBX,mm7
		MOVD		EDX,mm6
		DEC		EBX
		PADDD		mm3,mm4
		JNS		.BcFillDEG
.FinClipDEG:
		RET

;******* POLYTYPE = EFF_COLCONV
ALIGN 32
InFillEFF_COLCONV:
		MOV		EDI,[_PtrTbColConv] ; *
		MOV		EBX,[DebYPoly] ; -
		OR		EDI,EDI 	    ; *
		LEA		EDX,[EBX*4]    ; -
		JZ		.Fin
		SUB		EBX,[FinYPoly] ; -  EBX = DebYPoly-FinYPoly
		MOVD		mm5,EDI     ; *
		ADD		ESI,_TbDegCol  ; ESI+=OFFSET _TbDegCol
		NEG		EBX	       ; -  EBX = FinYPoly-DebYPoly
;ALIGN 4
.BcFillDEG:
		MOV		ECX,[_TPolyAdFin+EDX+EBX*4]
		MOV		EDI,[_TPolyAdDeb+EDX+EBX*4]
                
		CMP		ECX,EDI
		JG		.PasSwapAd
		XCHG		EDI,ECX
.PasSwapAd:	SUB		ECX,EDI
		INC		ECX
		MOVD		mm7,EBX
		MOVD		mm6,EDX
		@EFF_COLCONVHLine
		MOVD		EBX,mm7
		MOVD		EDX,mm6
		DEC		EBX
		JNS		.BcFillDEG
.Fin:
		RET

ALIGN 32
ClipFillEFF_COLCONV:
		MOV		EDI,[_PtrTbColConv]  ; *
		MOV		EBP,[FinYPoly]
		OR		EDI,EDI
		JZ		.FinClipDEG
		SUB		EBP,[_OrgY]
		MOVD		mm5,EDI        ;*
		MOV		EBX,[DebYPoly] ; -
		IMUL		EBP,[_ResH]
		LEA		EDX,[EBX*4]    ; -
		SUB		EBX,[FinYPoly] ; -
		NEG		EBP
		NEG		EBX	       ; -
		ADD		EBP,[_vlfb]
		MOVD		mm3,EBP
		MOVD		mm4,[_ResH]
;ALIGN 4
.BcFillDEG:
		MOV		ECX,[_TPolyAdFin+EDX+EBX*4]  ; X2
		MOV		EDI,[_TPolyAdDeb+EDX+EBX*4]  ; X1

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
		INC		ECX
		MOV		[Plus2],ECX	; Plus2 = DltX sans ajust
		XOR		EAX,EAX
		ADD		ECX,EDI
		DEC		ECX
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
		INC		ECX
		ADD		EDI,ESI
		MOV		EBP,[Col1]
		MOV		EAX,[Col2]
		MOVD		ESI,mm5
		@EFF_COLCONVHLine
.PasDrwClTx:
		MOVD		EBX,mm7
		MOVD		EDX,mm6
		DEC		EBX
		PADDD		mm3,mm4
		JNS		.BcFillDEG
.FinClipDEG:
		RET

