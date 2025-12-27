
;****************************************************************************
;****************************************************************************
ALIGN 32
_PutMaskSurf:
	ARG	MSSN, 4, MXPSN, 4, MYPSN, 4, MPSType, 4
		PUSH		EBX
		PUSH		EDI
		PUSH		ESI

		MOV		EAX,[_MinX]
		MOV		EBX,[_MinY]
		CMP		EAX,[_MaxX]
		MOV		ESI,[EBP+MSSN]
		JG		NEAR .PasPutSurf
		CMP		EBX,[_MaxY]
		MOV		EDI,Svlfb
		JG		NEAR .PasPutSurf

		CopySurf	; copy sprite Surf
		;MOV		ECX,16
		;REP		MOVSD

		MOV		EAX,[EBP+MXPSN]
		MOV		EBX,[EBP+MYPSN]
		MOV		ECX,EAX
		MOV		EDX,EBX

		MOV		ESI,[EBP+MPSType]
		TEST		ESI,1
		JZ		.NormHzPut
		SUB		EAX,[SMinX]
		SUB		ECX,[SMaxX]
		JMP		NEAR .InvHzPut
.NormHzPut:	ADD		EAX,[SMaxX]
		ADD		ECX,[SMinX]
.InvHzPut:
		TEST		ESI,2
		JZ		.NormVtPut
		SUB		EBX,[SMinY]
		SUB		EDX,[SMaxY]
		JMP		NEAR .InvVtPut
.NormVtPut:	ADD		EBX,[SMaxY]
		ADD		EDX,[SMinY]
.InvVtPut:
		CMP		EAX,[_MaxX]
		JG		NEAR .PutSurfClip
		CMP		EBX,[_MaxY]
		JG		NEAR .PutSurfClip
		CMP		ECX,[_MinX]
		JL		NEAR .PutSurfClip
		CMP		EDX,[_MinY]
		JL		NEAR .PutSurfClip
; PutSurf non Clipper *****************************
		MOV		[PType],ESI
		MOV		EBP,[SResV]
		TEST		ESI,2
		JZ		.NormAdSPut
		MOV		ESI,[Srlfb]
		MOV		EAX,[SResH]
		ADD		ESI,[SSizeSurf]
		SUB		ESI,EAX
		ADD		EAX,EAX
		NEG		EAX
		MOVD		mm7,EAX
		JMP		NEAR .InvAdSPut
.NormAdSPut:
		XOR		EAX,EAX
		MOV		ESI,[Srlfb]
		MOVD		mm7,EAX
.InvAdSPut:
		MOV		EDI,EBX
		IMUL		EDI,[_ResH]
		NEG		EDI
		ADD		EDI,ECX
		ADD		EDI,[_vlfb]

		MOV		EDX,[_ResH]
		SUB		EDX,[SResH]

		TEST		BYTE [PType],1
                JNZ             .InvHzPSurf

.BcPutSurf:	MOV		EBX,[SResH]
;**********************
		TEST		EBX,0xfffffffc
		JZ		.BcStB
.BcStB4:	LODSD
		SHLD		ECX,EAX,16
		OR		AL,AL	 ;*******
		JZ		.PasDrB1
		MOV		[EDI],AL
.PasDrB1:	OR		AH,AH	 ;*******
		JZ		.PasDrB2
		MOV		[EDI+1],AH
.PasDrB2:	OR		CL,CL	 ;*******
		JZ		.PasDrB3
		MOV		[EDI+2],CL
.PasDrB3:	OR		CH,CH	 ;*******
		JZ		.PasDrB4
		MOV		[EDI+3],CH
.PasDrB4:
		SUB		EBX,BYTE 4
		LEA		EDI,[EDI+4]
		TEST		EBX,0xfffffffc
		JNZ		.BcStB4
		OR		BL,BL
		JZ		.FinSHLine
ALIGN 4
.BcStB:		LODSB
		OR		AL,AL
		JZ		.PasDrB
		MOV		[EDI],AL
.PasDrB:
		DEC		EBX
		LEA		EDI,[EDI+1]
		JNZ		.BcStB
.FinSHLine:
;*************************************
		MOVD		EAX,mm7
		ADD		EDI,EDX
                ADD		ESI,EAX
		DEC		EBP
		JNZ		.BcPutSurf

		JMP		.PasPutSurf

.InvHzPSurf:    ; inverser horizontal
                ADD		ESI,[SResH]
.IBcPutSurf:	MOV		EBX,[SResH]
;****************************
		TEST		EBX,0xfffffffc
		JZ		.IBcStB
.IBcStB4:	SUB		ESI,BYTE 4
		MOV		EAX,[ESI]
		SHLD		ECX,EAX,16

		OR		CH,CH	 ;*******
		JZ		.IPasDrB4
		MOV		[EDI],CH
.IPasDrB4:	OR		CL,CL	 ;*******
		JZ		.IPasDrB3
		MOV		[EDI+1],CL
.IPasDrB3:	OR		AH,AH	 ;*******
		JZ		.IPasDrB2
		MOV		[EDI+2],AH
.IPasDrB2:	OR		AL,AL	 ;*******
		JZ		.IPasDrB1
		MOV		[EDI+3],AL
.IPasDrB1:
		SUB		EBX,BYTE 4
		LEA		EDI,[EDI+4]
		TEST		EBX,0xfffffffc
		JNZ		.IBcStB4
		OR		BL,BL
		JZ		.IFinSHLine
ALIGN 4
.IBcStB:        DEC		ESI
		MOV		AL,[ESI]
		OR		AL,AL
		JZ		.IPasDrB
		MOV		[EDI],AL
.IPasDrB:
		DEC		EBX
		LEA		EDI,[EDI+1]
		JNZ		.IBcStB
.IFinSHLine:
;******************************
		MOVD		EAX,mm7
		ADD		EDI,EDX
                ADD		ESI,EAX
                ADD		ESI,[SResH]
                ADD		ESI,[SResH]
		DEC		EBP
		JNZ		NEAR .IBcPutSurf

		JMP		.PasPutSurf

.PutSurfClip:	CMP		EAX,[_MinX]
		JL		NEAR .PasPutSurf
		CMP		EBX,[_MinY]
		JL		NEAR .PasPutSurf
		CMP		ECX,[_MaxX]
		JG		NEAR .PasPutSurf
		CMP		EDX,[_MaxY]
		JG		NEAR .PasPutSurf
; PutSurf Clipper **********************************************
		MOV		[PType],ESI ; sauvegarde le type
		XOR		ESI,ESI   ; X deb Source
		XOR		EDI,EDI   ; Y Fin Source

		MOV		EBP,[_MinX]
		CMP		ECX,EBP
		JGE		.PsInfMinX   ; XP1<_MinX
                TEST		BYTE [PType],1
                JNZ		.InvHzCalcDX
		MOV		ESI,EBP
		;MOV		[XP1],ESI    ; XP1 = _MinX
		SUB		ESI,ECX	; ESI = _MinX - XP2
.InvHzCalcDX:
		MOV		ECX,EBP
.PsInfMinX:	MOV		EBP,[_MaxY]
		CMP		EBX,EBP
		JLE		.PsSupMaxY   ; YP2>_MaxY
		MOV		EDI,EBP
		NEG		EDI
		;MOV		[YP2],EBP
		ADD		EDI,EBX
		MOV		EBX,EBP
.PsSupMaxY:	MOV		EBP,[_MinY]
		CMP		EDX,EBP      ; YP1<_MinY
		JGE		.PsInfMinY
		MOV		EDX,EBP
.PsInfMinY:   	MOV		EBP,[_MaxX]
		CMP		EAX,EBP      ; XP2>_MaxX
		JLE		.PsSupMaxX
                TEST		BYTE [PType],1
                JZ		.PsInvHzCalcDX
		MOV		ESI,EAX
		SUB		ESI,EBP	; ESI = XP2 - _MaxX
.PsInvHzCalcDX:
		MOV		EAX,EBP
.PsSupMaxX:
		MOV		EBP,EAX
		SUB		EBP,ECX      ; XP2 - XP1
		INC		EBP
		MOVD		mm4,EBP  ; mm4 = DeltaX
		MOVD		mm3,[SResH]
		PSUBD		mm3,mm4  ; mm3 = SResH-DeltaX, PlusSSurf

		MOV		EBP,EBX
		SUB		EBP,EDX      ; YP2 - YP1
		INC		EBP
		MOVD		mm2,EBP  ; mm2 = DeltaY
		MOVD		mm1,[_ResH]
		PSUBD		mm1,mm4  ; mm1 = _ResH-DeltaX, PlusDSurf

		TEST		BYTE [PType],2
		JZ		.CNormAdSPut
		MOV		EAX,[Srlfb] ; Si inverse vertical
		ADD		EAX,[SSizeSurf]
		SUB		EAX,[SResH]
		ADD		EAX,ESI
		IMUL		EDI,[SResH]
                SUB		EAX,EDI
		MOV		ESI,EAX

		MOV		EAX,[SResH]
		ADD		EAX,EAX
		NEG		EAX
		MOVD		mm7,EAX
		JMP		NEAR .CInvAdSPut
.CNormAdSPut:
		IMUL		EDI,[SResH]
		XOR		EAX,EAX
		ADD		EDI,ESI
		ADD		EDI,[Srlfb]
		MOV		ESI,EDI
		MOVD		mm7,EAX
.CInvAdSPut:
		MOV		EDI,EBX
		IMUL		EDI,[_ResH]
		NEG		EDI
		ADD		EDI,ECX
		ADD		EDI,[_vlfb]

		MOVD		EDX,mm4  ; DeltaX
		TEST		BYTE [PType],1
                JNZ             .CInvHzPSurf
.CBcPutSurf:	MOV		EBX,EDX
;******************************
		TEST		EBX,0xfffffffc
		JZ		.CBcStB
.CBcStB4:	LODSD
		SHLD		ECX,EAX,16
		OR		AL,AL	 ;*******
		JZ		.CPasDrB1
		MOV		[EDI],AL
.CPasDrB1:	OR		AH,AH	 ;*******
		JZ		.CPasDrB2
		MOV		[EDI+1],AH
.CPasDrB2:	OR		CL,CL	 ;*******
		JZ		.CPasDrB3
		MOV		[EDI+2],CL
.CPasDrB3:	OR		CH,CH	 ;*******
		JZ		.CPasDrB4
		MOV		[EDI+3],CH
.CPasDrB4:
		SUB		EBX,BYTE 4
		LEA		EDI,[EDI+4]
		TEST		EBX,0xfffffffc
		JNZ		.CBcStB4
		OR		BL,BL
		JZ		.CFinSHLine
ALIGN 4
.CBcStB:        LODSB
		OR		AL,AL
		JZ		.CPasDrB
		MOV		[EDI],AL
.CPasDrB:
		DEC		EBX
		LEA		EDI,[EDI+1]
		JNZ		.CBcStB
.CFinSHLine:
;******************************
		MOVD		EAX,mm3 ; EAX = PlusSSurf
		MOVD		ECX,mm1 ; ECX = PlusDSurf
		MOVD		EBX,mm7
		ADD		ESI,EAX
		ADD		EDI,ECX
		ADD		ESI,EBX
		DEC		EBP
		JNZ		.CBcPutSurf
		JMP		.PasPutSurf
.CInvHzPSurf:   ; clipper et inverser horizontalement
                ADD		ESI,EDX
.CIBcPutSurf:	MOV		EBX,EDX
;******************************
		TEST		EBX,0xfffffffc
		JZ		.CIBcStB
.CIBcStB4:	SUB		ESI,BYTE 4
		MOV		EAX,[ESI]
		SHLD		ECX,EAX,16

		OR		CH,CH	 ;*******
		JZ		.CIPasDrB4
		MOV		[EDI],CH
.CIPasDrB4:	OR		CL,CL	 ;*******
		JZ		.CIPasDrB3
		MOV		[EDI+1],CL
.CIPasDrB3:	OR		AH,AH	 ;*******
		JZ		.CIPasDrB2
		MOV		[EDI+2],AH
.CIPasDrB2:	OR		AL,AL	 ;*******
		JZ		.CIPasDrB1
		MOV		[EDI+3],AL
.CIPasDrB1:
		SUB		EBX,BYTE 4
		LEA		EDI,[EDI+4]
		TEST		EBX,0xfffffffc
		JNZ		.CIBcStB4
		OR		BL,BL
		JZ		.CIFinSHLine
ALIGN 4
.CIBcStB:	DEC		ESI
		MOV		AL,[ESI]
		OR		AL,AL
		JZ		.CIPasDrB
		MOV		[EDI],AL
.CIPasDrB:
		DEC		EBX
		LEA		EDI,[EDI+1]
		JNZ		.CIBcStB
.CIFinSHLine:
;******************************
		MOVD		EAX,mm3
		MOVD		ECX,mm1
                ADD		ESI,[SResH]
                ADD		ESI,EDX
                MOVD		EBX,mm7
		ADD		EDI,ECX
                ADD		ESI,EBX
		DEC		EBP
		JNZ		NEAR .CIBcPutSurf

.PasPutSurf:	POP		ESI
		POP		EDI
		POP		EBX
		;EMMS
		RETURN
ALIGN 32
_PutSurf:
	ARG	SSN, 4, XPSN, 4, YPSN, 4, PSType, 4
		PUSH		EBX
		PUSH		EDI
		PUSH		ESI

		MOV		EAX,[_MinX]
		MOV		EBX,[_MinY]
		CMP		EAX,[_MaxX]
		MOV		ESI,[EBP+SSN]
		JG		NEAR .PasPutSurf
		CMP		EBX,[_MaxY]
		MOV		EDI,Svlfb
		JG		NEAR .PasPutSurf

		CopySurf	; copy surf
		;MOV		ECX,16
		;REP		MOVSD

		MOV		EAX,[EBP+XPSN]
		MOV		EBX,[EBP+YPSN]
		MOV		ECX,EAX
		MOV		EDX,EBX

		MOV             ESI,[EBP+PSType]
		TEST            ESI,1
		JZ              .NormHzPut
		SUB             EAX,[SMinX]
		SUB             ECX,[SMaxX]
		JMP             NEAR .InvHzPut
.NormHzPut:	ADD		EAX,[SMaxX]
		ADD		ECX,[SMinX]
.InvHzPut:
		TEST            ESI,2
		JZ              .NormVtPut
		SUB             EBX,[SMinY]
		SUB             EDX,[SMaxY]
		JMP             NEAR .InvVtPut
.NormVtPut:	ADD		EBX,[SMaxY]
		ADD		EDX,[SMinY]
.InvVtPut:
		CMP		EAX,[_MaxX]
		JG		NEAR .PutSurfClip
		CMP		EBX,[_MaxY]
		JG		NEAR .PutSurfClip
		CMP		ECX,[_MinX]
		JL		NEAR .PutSurfClip
		CMP		EDX,[_MinY]
		JL		NEAR .PutSurfClip
; PutSurf non Clipper *****************************
		MOV		[PType],ESI
		MOV		EBP,[SResV]
		TEST		ESI,2
		JZ		.NormAdSPut
		MOV		ESI,[Srlfb]
		MOV		EAX,[SResH]
		ADD		ESI,[SSizeSurf]
		SUB		ESI,EAX
		ADD		EAX,EAX
		NEG		EAX
		MOVD		mm7,EAX
		JMP		NEAR .InvAdSPut
.NormAdSPut:
		XOR		EAX,EAX
		MOV		ESI,[Srlfb]
		MOVD		mm7,EAX
.InvAdSPut:
		MOV		EDI,EBX
		IMUL		EDI,[_ResH]
		NEG		EDI
		ADD		EDI,ECX
		ADD		EDI,[_vlfb]

		MOV		EDX,[_ResH]
		SUB		EDX,[SResH]

		TEST		BYTE [PType],1
                JNZ             .InvHzPSurf

.BcPutSurf:	MOV		EBX,[SResH]
.BcStBAv:	TEST		EDI,3
		JZ		.FPasStBAv
		DEC		EBX
		MOVSB
		JZ		.FinSHLine
		JMP		SHORT .BcStBAv
.FPasStBAv:	TEST		EDI,4
		JZ		.PasStDAv
		TEST		EBX,0xfffffffc
		JZ		.StBAp
		MOVSD
		SUB		EBX,BYTE 4
.PasStDAv:	MOV		ECX,EBX
		SHR		ECX,3
		OR		ECX,ECX
		JZ		.StDAp
ALIGN 4
.StoMMX:	MOVQ		mm4,[ESI]
		DEC		ECX
		MOVQ		[EDI],mm4
		LEA		ESI,[ESI+8]
		LEA		EDI,[EDI+8]
		JNZ		.StoMMX
		AND		EBX,BYTE 7
		JZ		.FinSHLine
.StDAp: 	TEST		EBX,4
		JZ		.StBAp
		MOVSD
		SUB		EBX,BYTE 4
.StBAp:		OR		EBX,EBX
		JZ		.PasStBAp
		MOV		ECX,EBX
		REP		MOVSB
.PasStBAp:
.FinSHLine:     MOVD		EAX,mm7
		ADD		EDI,EDX
		ADD		ESI,EAX
		DEC		EBP
		JNZ		.BcPutSurf

		JMP		.PasPutSurf

.InvHzPSurf:    ; inverser horizontal
                ADD		ESI,[SResH]
.IBcPutSurf:	MOV		EBX,[SResH]
.IBcStBAv:	TEST		EDI,3
		JZ		.IFPasStBAv
		DEC		ESI
		MOV		AL,[ESI]
		STOSB
		DEC		EBX
		JZ		.IFinSHLine
		JMP		SHORT .IBcStBAv
.IFPasStBAv:	TEST		EDI,4
		JZ		.IPasStDAv
		TEST		EBX,0xfffffffc
		JZ		.IStBAp
                SUB		ESI,BYTE 4
                MOV		EAX,[ESI]
		SUB		EBX,BYTE 4
                BSWAP		EAX
		STOSD
.IPasStDAv:	MOV		ECX,EBX
		SHR		ECX,3
		OR		ECX,ECX
		JZ		.IStDAp
ALIGN 4
.IStoMMX:
		SUB		ESI,BYTE 8
		MOV		EAX,[ESI]
		BSWAP		EAX
		DEC		ECX
		MOVD		mm6,EAX
		MOV		EAX,[ESI+4]
		BSWAP		EAX
		MOVD		mm4,EAX
		PUNPCKLDQ	mm4,mm6
		MOVQ		[EDI],mm4
		LEA		EDI,[EDI+8]

		JNZ		.IStoMMX

		AND		EBX,BYTE 7
		JZ		.IFinSHLine
.IStDAp:	TEST		EBX,4
		JZ		.IStBAp
		SUB		ESI,4
		MOV		EAX,[ESI]
		BSWAP		EAX
		STOSD
		SUB		EBX,BYTE 4

.IStBAp:	OR		EBX,EBX
		JZ		.IPasStBAp
.IBcStBAp:	DEC		ESI
		MOV		AL,[ESI]
		STOSB
		DEC		EBX
		JNZ		.IBcStBAp
.IPasStBAp:
.IFinSHLine:    MOVD		EAX,mm7
		ADD		EDI,EDX
		ADD		ESI,EAX
		ADD		ESI,[SResH]
		ADD		ESI,[SResH]
		DEC		EBP
		JNZ		NEAR .IBcPutSurf

		JMP		.PasPutSurf

.PutSurfClip:	CMP		EAX,[_MinX]
		JL		NEAR .PasPutSurf
		CMP		EBX,[_MinY]
		JL		NEAR .PasPutSurf
		CMP		ECX,[_MaxX]
		JG		NEAR .PasPutSurf
		CMP		EDX,[_MaxY]
		JG		NEAR .PasPutSurf
; PutSurf Clipper **********************************************
		MOV		[PType],ESI ; sauvegarde le type
		XOR		EDI,EDI   ; Y Fin Source
		XOR		ESI,ESI   ; X deb Source

		MOV		EBP,[_MinX]
		CMP		ECX,EBP
		JGE		.PsInfMinX   ; XP1<_MinX
		TEST		BYTE [PType],1
		JNZ		.InvHzCalcDX
		MOV		ESI,EBP
		;MOV		[XP1],ESI    ; XP1 = _MinX
		SUB		ESI,ECX	; ESI = _MinX - XP2
.InvHzCalcDX:
		MOV		ECX,EBP
.PsInfMinX:	MOV		EBP,[_MaxY]
		CMP		EBX,EBP
		JLE		.PsSupMaxY   ; YP2>_MaxY
		MOV		EDI,EBP
		NEG		EDI
		;MOV		[YP2],EBP
		ADD		EDI,EBX
		MOV		EBX,EBP
.PsSupMaxY:	MOV		EBP,[_MinY]
		CMP		EDX,EBP      ; YP1<_MinY
		JGE		.PsInfMinY
		MOV		EDX,EBP
.PsInfMinY:   	MOV		EBP,[_MaxX]
		CMP		EAX,EBP      ; XP2>_MaxX
		JLE		.PsSupMaxX
                TEST		BYTE [PType],1
                JZ		.PsInvHzCalcDX
		MOV		ESI,EAX
		SUB		ESI,EBP	; ESI = XP2 - _MaxX
.PsInvHzCalcDX:
		MOV		EAX,EBP
.PsSupMaxX:
		MOV		EBP,EAX
		SUB		EBP,ECX      ; XP2 - XP1
		INC		EBP
		MOVD		mm4,EBP  ; mm4 = DeltaX
		MOVD		mm3,[SResH]
		PSUBD		mm3,mm4  ; mm3 = SResH-DeltaX, PlusSSurf

		MOV		EBP,EBX
		SUB		EBP,EDX      ; YP2 - YP1
		INC		EBP
		MOVD		mm2,EBP  ; mm2 = DeltaY
		MOVD		mm1,[_ResH]
		PSUBD		mm1,mm4  ; mm1 = _ResH-DeltaX, PlusDSurf

		TEST		BYTE [PType],2
		JZ		.CNormAdSPut
		MOV		EAX,[Srlfb] ; Si inverse vertical
		ADD		EAX,[SSizeSurf]
		SUB		EAX,[SResH]
		ADD		EAX,ESI
		IMUL		EDI,[SResH]
                SUB		EAX,EDI
		MOV		ESI,EAX

		MOV		EAX,[SResH]
		ADD		EAX,EAX
		NEG		EAX
		MOVD		mm7,EAX
		JMP		NEAR .CInvAdSPut
.CNormAdSPut:
		IMUL		EDI,[SResH]
		XOR		EAX,EAX
		ADD		EDI,ESI
		ADD		EDI,[Srlfb]
		MOV		ESI,EDI
		MOVD		mm7,EAX
.CInvAdSPut:
		MOV		EDI,EBX
		IMUL		EDI,[_ResH]
		NEG		EDI
		ADD		EDI,ECX
		ADD		EDI,[_vlfb]

		MOVD		EDX,mm4  ; DeltaX
		TEST		BYTE [PType],1
                JNZ             .CInvHzPSurf
.CBcPutSurf:	MOV		EBX,EDX
.CBcStBAv:	TEST		EDI,3
		JZ		.CFPasStBAv
		DEC		EBX
		MOVSB
		JZ		.CFinSHLine
		JMP		SHORT .CBcStBAv
.CFPasStBAv:	TEST		EDI,4
		JZ		.CPasStDAv
		TEST		EBX,0xfffffffc
		JZ		.CStBAp
		MOVSD
		SUB		EBX,BYTE 4
.CPasStDAv:	MOV		ECX,EBX
		SHR		ECX,3
		OR		ECX,ECX
		JZ		.CStDAp
ALIGN 4
.CStoMMX:	MOVQ		mm0,[ESI]
		DEC		ECX
		MOVQ		[EDI],mm0
		LEA		ESI,[ESI+8]
		LEA		EDI,[EDI+8]
		JNZ		.CStoMMX

		AND		EBX,BYTE 7
		JZ		.CFinSHLine
.CStDAp: 	TEST		EBX,4
		JZ		.CStBAp
		MOVSD
		SUB		EBX,BYTE 4
.CStBAp:	OR		EBX,EBX
		JZ		.CPasStBAp
		MOV		ECX,EBX
		REP		MOVSB
.CPasStBAp:
.CFinSHLine:
		MOVD		EAX,mm3 ; EAX = PlusSSurf
		MOVD		ECX,mm1 ; ECX = PlusDSurf
		MOVD		EBX,mm7
		ADD		ESI,EAX
		ADD		EDI,ECX
		ADD		ESI,EBX
		DEC		EBP
		JNZ		.CBcPutSurf
		JMP		.PasPutSurf

.CInvHzPSurf:   ; clipper et inverser horizontalement
                ADD		ESI,EDX
.CIBcPutSurf:	MOV		EBX,EDX
.CIBcStBAv:	TEST		EDI,3
		JZ		.CIFPasStBAv
		DEC		ESI
		MOV		AL,[ESI]
		STOSB
		DEC		EBX
		JZ		.CIFinSHLine
		JMP		SHORT .CIBcStBAv
.CIFPasStBAv:	TEST		EDI,4
		JZ		.CIPasStDAv
		TEST		EBX,0xfffffffc
		JZ		.CIStBAp
		SUB		ESI,BYTE 4
		MOV		EAX,[ESI]
		BSWAP		EAX
		STOSD
		SUB		EBX,BYTE 4
.CIPasStDAv:	MOV		ECX,EBX
		SHR		ECX,3
		OR		ECX,ECX
		JZ		.CIStDAp
ALIGN 4
.CIStoMMX:	SUB		ESI,BYTE 8
		MOV		EAX,[ESI]
		BSWAP		EAX
		DEC		ECX
		MOVD		mm6,EAX
		MOV		EAX,[ESI+4]
		BSWAP		EAX
		MOVD		mm0,EAX
		PUNPCKLDQ	mm0,mm6
		MOVQ		[EDI],mm0
		LEA		EDI,[EDI+8]
		JNZ		.CIStoMMX

		AND		EBX,BYTE 7
		JZ		.CIFinSHLine
.CIStDAp: 	TEST		EBX,4
		JZ		.CIStBAp
		SUB		ESI,BYTE 4
		MOV		EAX,[ESI]
		BSWAP		EAX
		STOSD
		SUB		EBX,BYTE 4
.CIStBAp:	OR		EBX,EBX
		JZ		.CIPasStBAp
.CIBcStBAp:	DEC		ESI
		MOV		AL,[ESI]
		STOSB
		DEC		EBX
		JNZ		.CIBcStBAp
.CIPasStBAp:
.CIFinSHLine:
		MOVD		EAX,mm3
		MOVD		ECX,mm1
		ADD		ESI,[SResH]
		ADD		ESI,EDX
		MOVD		EBX,mm7
		ADD		EDI,ECX
		ADD		ESI,EBX
		DEC		EBP
		JNZ		NEAR .CIBcPutSurf

.PasPutSurf:	POP		ESI
		POP		EDI
		POP		EBX
		;EMMS
		RETURN

ALIGN 32
_line:
	ARG   	LXP1, 4, LYP1, 4, LXP2, 4, LYP2, 4, lnCol, 4

		MOVD		mm7,EBX
		MOVD		mm6,EDI
		MOVD		mm5,ESI

		MOV		EAX,[EBP+LXP1]
		MOV		EBX,[EBP+LXP2]
		MOV		ESI,[EBP+LYP1]
		MOV		EDI,[EBP+LYP2]
		MOV		ECX,[EBP+lnCol]

		MOV		[XP1],EAX
		MOV		[XP2],EBX
		MOV		[YP1],ESI
		MOV		[YP2],EDI
		MOV		[clr],ECX
		JMP		SHORT _Line.DoLine


ALIGN 32
_Line:
	ARG   	PtrP1, 4, PtrP2, 4, Col, 4

		MOVD		mm7,EBX
		MOVD		mm6,EDI
		MOVD		mm5,ESI


		;MOV		EAX,[_MinX]
		;MOV		EBX,[_MinY]
		;CMP		EAX,[_MaxX]
		MOV		EAX,[EBP+Col]
		MOV		EDX,[EBP+PtrP1]
		MOV		[clr],EAX
		;JG		NEAR .FinLine
		;CMP		EBX,[_MaxY]
		MOV		ECX,[EBP+PtrP2]
		;JG		NEAR .FinLine

		MOV		EAX,[EDX]   ; X1
		MOV		EBX,[ECX]   ; X2
		MOV		ESI,[EDX+4] ; Y1
		MOV		EDI,[ECX+4] ; Y2
		MOV		[XP1],EAX   ; X1
		MOV		[XP2],EBX   ; X2
		MOV		[YP1],ESI 	; Y1
		MOV		[YP2],EDI 	; Y2

.DoLine:	;MOV		EAX,[XP1]   ; ligne en dehors de la fenetre ?
		;MOV		EBX,[XP2]
		MOV		EDX,EAX
		CMP		EAX,EBX
		JL		.VMaxX
		XCHG		EAX,EBX
.VMaxX:		CMP		EAX,[_MaxX]
		JG		NEAR .FinLine
		CMP		EBX,[_MinX]
		JL		NEAR .FinLine
		SUB		EBX,EAX
		MOV		ESI,EBX	   ;calcul de abs(x2-x1)

		MOV		EAX,[YP1]
		MOV		EBX,EDI;[YP2]
		MOV		ECX,EAX
		CMP		EAX,EBX
		JL		.VMaxY
		XCHG		EAX,EBX
.VMaxY:		CMP		EAX,[_MaxY]
		JG		NEAR .FinLine
		CMP		EBX,[_MinY]
		JL		NEAR .FinLine       ; fin du test
		SUB		EBX,EAX
		MOV		EDI,EBX		   ;  abs(y2-y1)

		OR		EDI,EDI
		JZ		NEAR .cas4
.PasNegEDI:	OR		ESI,ESI
		JZ		NEAR .cas2

		INC		ESI			  ; abs(x2-x1)+1
		INC		EDI			  ; abs(y2-y1)+1
		MOV		EAX,EDX			; EDX = [XP1]
		MOV		EBX,[XP2]	 ; cas 1 et cas 2
		CMP		EAX,EBX
		JL		.ClipMaxX
		XCHG		EAX,EBX
.ClipMaxX:	CMP		EAX,[_MinX]
		JL		.Aj_1_2
		CMP		EBX,[_MaxX]
		JG		.Aj_1_2
		MOV		EAX,ECX			; ECX = [YP1]
		MOV		EBX,[YP2]
		CMP		EAX,EBX
		JL		.ClipMaxY
		XCHG		EAX,EBX
.ClipMaxY:	CMP		EAX,[_MinY]
		JL		.Aj_1_2
		CMP		EBX,[_MaxY]
		JG		.Aj_1_2
		JMP		.PasAj_1_2
.Aj_1_2:	MOV		EBX,EDX			; EDX = [XP1]
		MOV		ESI,[XP2]
		MOV		EDI,[YP2]
		CMP		EBX,ESI
		JL		.MaxAj1_2X
		XCHG		EBX,ESI
		XCHG		ECX,EDI
.MaxAj1_2X:
;*********Ajustement des X
		CMP       	EBX,[_MinX]
		JNL       	.PasAjX12
		MOV       	EAX,EDI
		SUB       	EAX,ECX
		SAL       	EAX,Prec
		SUB       	ESI,EBX
		CDQ
		IDIV      	ESI
		ADD       	ESI,EBX
		MOV       	EDX,EAX
		MOV       	EAX,[_MinX]
		SUB       	EAX,EBX
		IMUL      	EAX,EDX
		SAR       	EAX,Prec
		MOV       	EBX,[_MinX]
		ADD       	ECX,EAX
.PasAjX12:	CMP       	ESI,[_MaxX]
		JNG       	.PasAjM12
		MOV       	EAX,EDI
		SUB       	EAX,ECX
		SAL       	EAX,Prec
		SUB       	ESI,EBX
		OR        	ESI,ESI
		JZ        	NEAR .FinLine
		CDQ
		IDIV      	ESI
		ADD       	ESI,EBX
		MOV       	EDX,EAX
		MOV       	EAX,ESI
		SUB       	EAX,[_MaxX]
		IMUL      	EAX,EDX
		SAR       	EAX,Prec
		MOV       	ESI,[_MaxX]
		SUB       	EDI,EAX
.PasAjM12:	CMP       	ECX,EDI
		JL        	.MaxAj1_2Y
		XCHG      	EBX,ESI
		XCHG      	ECX,EDI
.MaxAj1_2Y:	CMP       	ECX,[_MaxY]
		JG        	NEAR .FinLine
		CMP       	EDI,[_MinY]
		JL        	NEAR .FinLine
;*********Ajustement des Y
		CMP       	ECX,[_MinY]
		JNL       	.PasAjY12
		MOV       	EAX,ESI
		SUB       	EAX,EBX
		MOV	        EBP,ESI ; save ESI
		SAL       	EAX,Prec
		MOV       	ESI,EDI
		SUB       	ESI,ECX
		CDQ
		IDIV      	ESI
		MOV	        ESI,EBP ; rest ESI
		MOV       	EDX,EAX
		MOV       	EAX,[_MinY]
		SUB       	EAX,ECX
		IMUL      	EAX,EDX
		SAR       	EAX,Prec
		MOV       	ECX,[_MinY]
		ADD       	EBX,EAX
		CMP       	EBX,[_MaxX]
		JG        	NEAR .FinLine
		CMP       	EBX,[_MinX]
		JL        	NEAR .FinLine
.PasAjY12:      CMP       	EDI,[_MaxY]
		JNG       	.PasAjY12X
		MOV       	EAX,ESI
		SUB       	EAX,EBX
		MOV	        EBP,ESI ; save ESI
		SAL       	EAX,Prec
		MOV       	ESI,EDI
		SUB       	ESI,ECX
		CDQ
		IDIV      	ESI
		MOV	        ESI,EBP ; rest ESI
		MOV       	EDX,EAX
		MOV       	EAX,EDI
		SUB       	EAX,[_MaxY]
		IMUL      	EAX,EDX
		SAR       	EAX,Prec
		MOV       	EDI,[_MaxY]
		SUB       	ESI,EAX
.PasAjY12X:
		MOV       	[XP1],EBX
		MOV       	[YP1],ECX
		MOV       	[XP2],ESI
		MOV       	[YP2],EDI
		SUB       	ESI,EBX
		SUB       	EDI,ECX
		OR        	ESI,ESI

		JZ		NEAR .cas2
		JNS		.PasNegESI2
		NEG		ESI
.PasNegESI2:
		OR		EDI,EDI
		JZ		NEAR .cas4
		JNS		.PasNegEDI2
		NEG		EDI
.PasNegEDI2:
.PasAj_1_2:     CMP       	ESI,EDI
                JB        	NEAR .cas2

;*********CAS 1:  (DX > DY)***************************************************
.cas1:
		MOV		EAX,[XP1]
		MOV		EBP,[_ScanLine] ; plus
		CMP		EAX,[XP2]
		JL		.PasSwap1
		XCHG		EAX,[XP2]
		MOV		[XP1],EAX
		MOV		EAX,[YP1]
		MOV		EBX,[YP2]
		MOV		[YP1],EBX
		MOV		[YP2],EAX
.PasSwap1:
		MOV		ESI,[XP2]
		MOV		EAX,[YP2]
		SUB		ESI,[XP1]
		SUB		EAX,[YP1]
		MOV		EDI,EBP  ;[_ScanLine]
		JNS		.pstvDyCas1
		NEG		EAX ; abs(deltay)
		JMP		SHORT .ngtvDyCas1
.pstvDyCas1:	NEG		EBP ; = -[_ScanLine] as ascendent y Axis
.ngtvDyCas1:
		INC		EAX
		MOV		EBX,1 << Prec ; EBX = cpt Dbrd
		SHL		EAX,Prec
		INC		ESI ; deltaX + 1
		CDQ
		IDIV		ESI
		MOV		ECX,ESI ; ECX = deltaX = number pixels
		IMUL		EDI,[YP1]
		MOV		EDX,EAX ; EDX = pnt
		NEG		EDI    ; // Y Axis  ascendent
		ADD		EDI,[XP1]
		MOV		EAX,[clr]
		MOV		ESI,1 << Prec
		ADD		EDI,[_vlfb]
ALIGN 4
.lp_line1:
		SUB		EBX,EDX
		MOV		[EDI],AL
		JA		.no_debor1 ; EDI >0
		ADD		EBX,ESI ; +  (1 << Prec)
		ADD		EDI,EBP	 ; EDI + = directional ScanLine
.no_debor1:
		DEC		ECX
		LEA		EDI,[EDI+1]	; EDI + 1 => 8bpp
		JNZ		.lp_line1

		JMP		.FinLine
;*********CAS 2:  (DY > DX)***************************************************
.cas2:
		OR		EDI,EDI
		MOV		EAX,[YP1]
		JZ		.cas5
		CMP		EAX,[YP2]
		JL		.PasSwap2
		XCHG		EAX,[YP2]
		MOV		[YP1],EAX
		MOV		ECX,[XP2]
		MOV		EAX,[XP1]
		MOV		[XP1],ECX
		MOV		[XP2],EAX
.PasSwap2:
		OR		ESI,ESI
		JNZ		.noClipVert
		MOV		EAX,[_MinY]
		MOV		EBX,[_MaxY]
		CMP		EAX,[YP1]
		JLE		.sava21
		MOV		[YP1],EAX
.sava21:	CMP		EBX,[YP2]
		JGE		.sava22
		MOV		[YP2],EBX
.sava22:
.noClipVert:
		MOV		EAX,[XP2]
		MOV		ESI,[YP2]
		SUB		EAX,[XP1]
		JNS		.pstvDxCas2
		DEC		EAX
		JMP		SHORT .ngtvDxCas2
.pstvDxCas2:	INC		EAX
.ngtvDxCas2:
		SUB		ESI,[YP1]
		SHL		EAX,Prec
		INC		ESI
		CDQ
		IDIV		ESI
		MOV		ECX,ESI ; ECX = deltaY = number pixels
		MOV		EDI,[YP1]
		MOV		EBP,[_ScanLine]
		MOV		EDX,EAX ; pente in EDX
		IMUL		EDI,EBP ; * ScanLine
		XOR		EBX,EBX ; accum in EBX
		; start adress
		NEG		EDI
		NEG		EBP ; = - ScanLine
		ADD		EDI,[XP1]
		ADD		EDI,[_vlfb]
		OR		EDX,EDX
		MOV		EAX,[clr] ; draw color
		JNS		.line2_pstvPnt
		MOV		EBX,((1<<Prec)-1)
.line2_pstvPnt:
ALIGN 4
.lp_line2:
		MOV		ESI,EBX
		SAR		ESI,Prec
		ADD		EBX,EDX ; + pnt
		MOV		[EDI+ESI],AL
		DEC		ECX
		LEA		EDI,[EDI+EBP]	  ;  Axe Y Montant -ResH
		JNZ		.lp_line2

		JMP		.FinLine
;*******CAS 3 :  (DX=0)*****************************************************
;*******CAS 4 :  (DY=0)*****************************************************
.cas4:		MOV		ECX,ESI
		MOV		EAX,[XP1]
		CMP		EAX,[XP2]
		JL		.PasSwap4
		MOV		EAX,[XP1]
		MOV		EBX,[XP2]
		MOV		[XP1],EBX
		MOV		[XP2],EAX
.PasSwap4:	MOV		EAX,[_MinX]
		CMP		EAX,[XP1]
		JLE		.sava41
		MOV		[XP1],EAX
.sava41:	MOV		EAX,[_MaxX]
		CMP		EAX,[XP2]
		JGE		.sava42
		MOV		[XP2],EAX
.sava42:
		MOV		ESI,[XP2]
		SUB		ESI,[XP1]
		OR		ESI,ESI
		JZ		NEAR .cas5
		INC		ESI
		MOV		EDI,[YP1]
		IMUL		EDI,[_ResH]
		MOV		EAX,[clr]
		NEG		EDI
		ADD		EDI,[_vlfb]
		ADD		EDI,[XP1]
		MOV		AH,AL
		MOV		EBX,EAX
		BSWAP		EAX
		SHRD		EAX,EBX,16
		@SolidHLine
		JMP		SHORT .FinLine
;********CAS 5 : (DX=0, DY=0)***********************************************
.cas5:
		MOV		EAX,[YP1]
		IMUL		EAX,[_ResH]
		MOV		EBX,[clr]
		NEG		EAX
		ADD		EAX,[XP1]
		ADD		EAX,[_vlfb]
		MOV		[EAX],BL
.FinLine:
		MOVD		EBX,mm7
		MOVD		EDI,mm6
		MOVD		ESI,mm5
		;EMMS
                RETURN

ALIGN 32
_linemap:
	ARG   	LMXP1, 4, LMYP1, 4, LMXP2, 4, LMYP2, 4, lnMCol, 4, LMMap, 4

		MOVD		mm7,EBX
		MOVD		mm6,EDI
		MOVD		mm5,ESI

		MOV		EAX,[EBP+LMXP1]
		MOV		EBX,[EBP+LMXP2]
		MOV		ESI,[EBP+LMYP1]
		MOV		EDI,[EBP+LMYP2]
		MOV		ECX,[EBP+lnMCol]
		MOV		EDX,[EBP+LMMap]

		MOV		[XP1],EAX
		MOV		[XP2],EBX
		MOV		[YP1],ESI
		MOV		[YP2],EDI
		MOV		[clr],ECX
		MOV		[Plus2],EDX
		JMP		SHORT _LineMap.DoLine

ALIGN 32
_LineMap:
	ARG   	MapPtrP1, 4, MapPtrP2, 4, MapCol, 4, LineMap, 4

		MOVD		mm7,EBX
		MOVD		mm6,EDI
		MOVD		mm5,ESI


		;MOV		EAX,[_MinX]
		;MOV		EBX,[_MinY]
		;CMP		EAX,[_MaxX]
		MOV		EDX,[EBP+MapPtrP1]
		;JG		NEAR .FinLine
		;CMP		EBX,[_MaxY]
		MOV		ECX,[EBP+MapPtrP2]
		;JG		NEAR .FinLine

		MOV		EAX,[EDX]   ; X1
		MOV		EBX,[ECX]   ; X2
		MOV		ESI,[EDX+4] ; Y1
		MOV		EDI,[ECX+4] ; Y2
		MOV		[XP1],EAX   ; X1
		MOV		[XP2],EBX   ; X2
		MOV		[YP1],ESI 	; Y1
		MOV		[YP2],EDI 	; Y2
		MOV		EDX,[EBP+MapCol]
		MOV		ECX,[EBP+LineMap]
		MOV		[clr],EDX
		MOV		[Plus2],ECX

.DoLine:	;MOV		EAX,[XP1]   ; ligne en dehors de la fenetre ?
		;MOV		EBX,[XP2]
		MOV		EDX,EAX
		CMP		EAX,EBX
		JL		.VMaxX
		XCHG		EAX,EBX
.VMaxX:		CMP		EAX,[_MaxX]
		JG		NEAR .FinLine
		CMP		EBX,[_MinX]
		JL		NEAR .FinLine
		SUB		EBX,EAX
		MOV		ESI,EBX	   ;calcul de abs(x2-x1)

		MOV		EAX,[YP1]
		MOV		EBX,EDI ; [YP2]
		MOV		ECX,EAX
		CMP		EAX,EBX
		JL		.VMaxY
		XCHG		EAX,EBX
.VMaxY:		CMP		EAX,[_MaxY]
		JG		NEAR .FinLine
		CMP		EBX,[_MinY]
		JL		NEAR .FinLine       ; fin du test
		SUB		EBX,EAX
		MOV		EDI,EBX		   ;  abs(y2-y1)

		OR		EDI,EDI
		JZ		NEAR .cas4
.PasNegEDI:	OR		ESI,ESI
		JZ		NEAR .cas2

		INC		ESI			  ; abs(x2-x1)+1
		INC		EDI			  ; abs(y2-y1)+1
		MOV		EAX,EDX			; EDX = [XP1]
		MOV		EBX,[XP2]	 ; cas 1 et cas 2
		CMP		EAX,EBX
		JL		.ClipMaxX
		XCHG		EAX,EBX
.ClipMaxX:	CMP		EAX,[_MinX]
		JL		.Aj_1_2
		CMP		EBX,[_MaxX]
		JG		.Aj_1_2
		MOV		EAX,ECX			; ECX = [YP1]
		MOV		EBX,[YP2]
		CMP		EAX,EBX
		JL		.ClipMaxY
		XCHG		EAX,EBX
.ClipMaxY:	CMP		EAX,[_MinY]
		JL		.Aj_1_2
		CMP		EBX,[_MaxY]
		JG		.Aj_1_2
		JMP		.PasAj_1_2
.Aj_1_2:	MOV		EBX,EDX			; EDX = [XP1]
		MOV		ESI,[XP2]
		MOV		EDI,[YP2]
		CMP		EBX,ESI
		JL		.MaxAj1_2X
		XCHG		EBX,ESI
		XCHG		ECX,EDI
.MaxAj1_2X:
;*********Ajustement des X
		CMP       	EBX,[_MinX]
		JNL       	.PasAjX12
		MOV       	EAX,EDI
		SUB       	EAX,ECX
		SAL       	EAX,Prec
		SUB       	ESI,EBX
		CDQ
		IDIV      	ESI
		ADD       	ESI,EBX
		MOV       	EDX,EAX
		MOV       	EAX,[_MinX]
		SUB       	EAX,EBX
		IMUL      	EAX,EDX
		SAR       	EAX,Prec
		MOV       	EBX,[_MinX]
		ADD       	ECX,EAX
.PasAjX12:	CMP       	ESI,[_MaxX]
		JNG       	.PasAjM12
		MOV       	EAX,EDI
		SUB       	EAX,ECX
		SAL       	EAX,Prec
		SUB       	ESI,EBX
		OR        	ESI,ESI
		JZ        	NEAR .FinLine
		CDQ
		IDIV      	ESI
		ADD       	ESI,EBX
		MOV       	EDX,EAX
		MOV       	EAX,ESI
		SUB       	EAX,[_MaxX]
		IMUL      	EAX,EDX
		SAR       	EAX,Prec
		MOV       	ESI,[_MaxX]
		SUB       	EDI,EAX
.PasAjM12:	CMP       	ECX,EDI
		JL        	.MaxAj1_2Y
		XCHG      	EBX,ESI
		XCHG      	ECX,EDI
.MaxAj1_2Y:	CMP       	ECX,[_MaxY]
		JG        	NEAR .FinLine
		CMP       	EDI,[_MinY]
		JL        	NEAR .FinLine
;*********Ajustement des Y
		CMP       	ECX,[_MinY]
		JNL       	.PasAjY12
		MOV       	EAX,ESI
		SUB       	EAX,EBX
		MOV	        EBP,ESI ; save ESI
		SAL       	EAX,Prec
		MOV       	ESI,EDI
		SUB       	ESI,ECX
		CDQ
		IDIV      	ESI
		MOV	        ESI,EBP ; rest ESI
		MOV       	EDX,EAX
		MOV       	EAX,[_MinY]
		SUB       	EAX,ECX
		IMUL      	EAX,EDX
		SAR       	EAX,Prec
		MOV       	ECX,[_MinY]
		ADD       	EBX,EAX
		CMP       	EBX,[_MaxX]
		JG        	NEAR .FinLine
		CMP       	EBX,[_MinX]
		JL        	NEAR .FinLine
.PasAjY12:      CMP       	EDI,[_MaxY]
		JNG       	.PasAjY12X
		MOV       	EAX,ESI
		SUB       	EAX,EBX
		MOV	        EBP,ESI ; save ESI
		SAL       	EAX,Prec
		MOV       	ESI,EDI
		SUB       	ESI,ECX
		CDQ
		IDIV      	ESI
		MOV		ESI,EBP ; rest ESI
		MOV       	EDX,EAX
		MOV       	EAX,EDI
		SUB       	EAX,[_MaxY]
		IMUL      	EAX,EDX
		SAR       	EAX,Prec
		MOV       	EDI,[_MaxY]
		SUB       	ESI,EAX
.PasAjY12X:
		MOV       	[XP1],EBX
		MOV       	[YP1],ECX
		MOV       	[XP2],ESI
		MOV       	[YP2],EDI
		SUB       	ESI,EBX
		SUB       	EDI,ECX
		OR        	ESI,ESI

		JZ		NEAR .cas2
		JNS		.PasNegESI2
		NEG		ESI
.PasNegESI2:
		OR		EDI,EDI
		JZ		NEAR .cas4
		JNS		.PasNegEDI2
		NEG		EDI
.PasNegEDI2:
.PasAj_1_2:     CMP       	ESI,EDI
                JB        	NEAR .cas2
;*********CAS 1:  (DX > DY)***************************************************
.cas1:
		MOV		EAX,[XP1]
		MOV		EBP,[_ScanLine] ; plus
		CMP		EAX,[XP2]
		JL		.PasSwap1
		XCHG		EAX,[XP2]
		MOV		[XP1],EAX
		MOV		EAX,[YP1]
		MOV		EBX,[YP2]
		MOV		[YP1],EBX
		MOV		[YP2],EAX
.PasSwap1:
		MOV		ESI,[XP2]
		MOV		EAX,[YP2]
		SUB		ESI,[XP1]
		SUB		EAX,[YP1]
		MOV		EDI,EBP  ;[_ScanLine]
		JNS		.pstvDyCas1
		NEG		EAX ; abs(deltay)
		JMP		SHORT .ngtvDyCas1
.pstvDyCas1:	NEG		EBP ; = -[_ScanLine] as ascendent y Axis
.ngtvDyCas1:
		INC		EAX
		MOV		EBX,[Plus2]  ; Line MAP
		SHL		EAX,Prec
		INC		ESI ; deltaX + 1
		CDQ
		IDIV		ESI
		MOV		ECX,ESI ; ECX = deltaX = number pixels
		IMUL		EDI,[YP1]
		MOV		ESI,1 << Prec ; EBX = cpt Dbrd
		NEG		EDI    ; // Y Axis  ascendent
		MOV		EDX,EAX ; EDX = pnt
		ADD		EDI,[XP1]
		MOV		EAX,[clr]
		ADD		EDI,[_vlfb]
.lp_line1:
		TEST		BL,1
		JZ		.PasDrl1
		MOV		[EDI],AL
.PasDrl1:
		SUB		ESI,EDX
		JA		.no_debor1 ; EDI >0
		ADD		ESI,(1 << Prec)
		ADD		EDI,EBP	 ; EDI + = directional ScanLine
.no_debor1:
		ROR		EBX,1
		DEC		ECX
		LEA		EDI,[EDI+1]	; EDI + 1
		JNZ		.lp_line1

		JMP		.FinLine
;*********CAS 2:  (DY > DX)***************************************************
.cas2:
		OR		EDI,EDI
		MOV		EAX,[YP1]
		JZ		.cas5
		CMP		EAX,[YP2]
		JL		.PasSwap2
		XCHG		EAX,[YP2]
		MOV		[YP1],EAX
		MOV		ECX,[XP2]
		MOV		EAX,[XP1]
		MOV		[XP1],ECX
		MOV		[XP2],EAX
.PasSwap2:
		OR		ESI,ESI
		JNZ		.noClipVert
		MOV		EAX,[_MinY]
		MOV		EBX,[_MaxY]
		CMP		EAX,[YP1]
		JLE		.sava21
		MOV		[YP1],EAX
.sava21:	CMP		EBX,[YP2]
		JGE		.sava22
		MOV		[YP2],EBX
.sava22:
.noClipVert:
		MOV		EAX,[XP2]
		MOV		ESI,[YP2]
		SUB		EAX,[XP1]
		JNS		.pstvDxCas2
		DEC		EAX
		JMP		SHORT .ngtvDxCas2
.pstvDxCas2:	INC		EAX
.ngtvDxCas2:
		SUB		ESI,[YP1]
		SHL		EAX,Prec
		INC		ESI
		CDQ
		MOV		EDI,[YP1]
		IDIV		ESI
		IMUL		EDI,[_ScanLine] ; * ScanLine
		MOV		ECX,ESI ; ECX = deltaY = number pixels
		NEG		EDI
		MOV		EDX,EAX ; pente in EDX

		ADD		EDI,[XP1]
		XOR		EBP,EBP ; accum in EBX
		ADD		EDI,[_vlfb]
		OR		EDX,EDX
		JNS		.line2_pstvPnt
		MOV		EBP,((1<<Prec)-1)
.line2_pstvPnt:
		; draw color
		MOV		EBX,[clr]
		MOV		EAX,[Plus2] ; Line Map

.lp_line2:	MOV		ESI,EBP
		SAR		ESI,Prec
		ADD		EBP,EDX ; + pnt
		TEST		AL,1
		JZ		.PasDrPx2
		MOV		[EDI+ESI],BL
.PasDrPx2:
		ROR		EAX,1
		SUB		EDI,[_ScanLine]	  ;  Axe Y Montant -ResH
		DEC		ECX
		JNZ		.lp_line2

		JMP		.FinLine
;*******CAS 3 :  (DX=0)*****************************************************
;*******CAS 4 :  (DY=0)*****************************************************
.cas4:		MOV		ECX,ESI
		MOV		EAX,[XP1]
		CMP		EAX,[XP2]
		JL		.PasSwap4
		MOV		EAX,[XP1]
		MOV		EBX,[XP2]
		MOV		[XP1],EBX
		MOV		[XP2],EAX
.PasSwap4:	MOV		EAX,[_MinX]
		CMP		EAX,[XP1]
		JLE		.sava41
		MOV		[XP1],EAX
.sava41:	MOV		EAX,[_MaxX]
		CMP		EAX,[XP2]
		JGE		.sava42
		MOV		[XP2],EAX
.sava42:
		MOV		ESI,[XP2]
		SUB		ESI,[XP1]
		OR		ESI,ESI
		JZ		NEAR .cas5
		INC		ESI
		MOV		EDI,[YP1]
		MOV		ECX,[Plus2] ; Line Map
		IMUL		EDI,[_ResH]
		MOV		EAX,[clr]
		NEG		EDI
		ADD		EDI,[_vlfb]
		ADD		EDI,[XP1]
.lp4:		TEST		CL,1
		JZ		.PasDrl4
		MOV		[EDI],AL
.PasDrl4:
		ROR		ECX,1
		DEC		ESI
		LEA		EDI,[EDI+1]
		JNZ		.lp4

		JMP		SHORT .FinLine
;********CAS 5 : (DX=0, DY=0)***********************************************
.cas5:
		TEST		BYTE [Plus2],1
		JZ		.FinLine
		MOV		EAX,[YP1]
		IMUL		EAX,[_ResH]
		MOV		EBX,[clr]
		NEG		EAX
		ADD		EAX,[XP1]
		ADD		EAX,[_vlfb]
		MOV		[EAX],BL
.FinLine:
		MOVD		EBX,mm7
		MOVD		EDI,mm6
		MOVD		ESI,mm5
		;EMMS
                RETURN


