
; compute the clipped/unclipped put rectangle coordinaates in (PutSurfMinX, PutSurfMinY, PutSurfMaxX, PutSurfMaxY)
;==========================================
; IN EAX,EBX,ECX,EDX (PutMaxX, PutMaxY, PutMinX, PutMinY)
; valid _CurSurf
; out clipped EAX,EBX,ECX,EDX, stored in (PutSurfMaxX, PutSurfMaxY, PutSurfMinX, PutSurfMinY)
; EDI, ESI changed
%macro	ClipStorePutSurfCoords	0

		MOV         EDI,[_MaxX]
		MOV         ESI,[_MaxY]
		CMP         EAX,EDI ; PMaxX <= MaxX ?
		JLE         SHORT %%NoPSMaxXClip
		MOV         [PutSurfMaxX],EDI
		JMP         SHORT %%PSMaxXClip
%%NoPSMaxXClip:
		MOV         [PutSurfMaxX],EAX
%%PSMaxXClip:
		CMP         EBX,ESI ; PMaxY <= MaxY ?
		JLE         SHORT %%NoPSMaxYClip
		MOV         [PutSurfMaxY],ESI
		JMP         SHORT %%PSMaxYClip
%%NoPSMaxYClip:
		MOV         [PutSurfMaxY],EBX
%%PSMaxYClip:
		MOV         EDI,[_MinX]
		MOV         ESI,[_MinY]
		CMP         ECX,EDI ; PMinX >= MinX
		JGE         SHORT %%NoPSMinXClip
		MOV         [PutSurfMinX],EDI
		JMP         SHORT %%PSMinXClip
%%NoPSMinXClip:
		MOV         [PutSurfMinX],ECX
%%PSMinXClip:
		CMP         EDX,ESI ; PMinY >= MinY
		JGE         SHORT %%NoPSMinYClip
		MOV         [PutSurfMinY],ESI
		JMP         SHORT %%PSMinYClip
%%NoPSMinYClip:
		MOV         [PutSurfMinY],EDX
%%PSMinYClip:

%endmacro


; --- compute Put coordinates of the entire SrcSurf (as if source surf is full view)
; IN  (EAX, EBX) (putX, putY), ESI: put Type
; out EAX: MaxX, EBX; MaxY, ECX: MinX, EDX: MinY
; EDI changed
%macro	ComputeFullViewSrcSurfPutCoords	0
		MOV         ECX,EAX           ; ECX = PutMinX / without clipping
		MOV         EDX,EBX           ; EDX = PutMinY / without clipping
		TEST        ESI,1
		MOV         EDI,[SOrgX]
		JZ          SHORT %%FNormHzPut
		SUB         ECX,[SResH]
		ADD         EAX,EDI
		LEA         ECX,[ECX+EDI+1]
		JMP         SHORT %%FInvHzPut
%%FNormHzPut:
		ADD         EAX,[SResH]
		SUB         ECX,EDI ; MinX = ECX = posXPut - SOrgX
		SUB         EAX,EDI
		DEC         EAX         ; MaxX = EAX = posXPut + (SResH -1) - SOrgX
%%FInvHzPut:
		TEST        ESI,2
		MOV         EDI,[SOrgY]
		JZ          %%FNormVtPut
		SUB         EDX,[SResV]
		ADD         EBX,EDI
		LEA         EDX,[EDX+EDI+1]
		JMP         SHORT %%FInvVtPut
%%FNormVtPut:
		ADD         EBX,[SResV]
		SUB         EDX,EDI ; MinX = ECX = posXPut - SOrgX
		SUB         EBX,EDI
		DEC         EBX         ; MaxY = EBX = posYPut + (SResV -1) - SOrgY
%%FInvVtPut:

%endmacro


;****************************************************************************
;****************************************************************************
ALIGN 32
_PutMaskSurf:
	ARG	MSSN, 4, MXPSN, 4, MYPSN, 4, MPSType, 4
		PUSH		EBX
		PUSH		EDI
		PUSH		ESI

		MOV			ESI,[EBP+MSSN]
		MOV			EDI,_SrcSurf
		MOV			EAX,[EBP+MXPSN]
		MOV			EBX,[EBP+MYPSN]

		CopySurf	; copy sprite Surf

		MOV			ECX,EAX
		MOV			EDX,EBX

		MOV			ESI,[EBP+MPSType]
		TEST		ESI,1
		JZ			.NormHzPut
		SUB			EAX,[SMinX]
		SUB			ECX,[SMaxX]
		JMP			SHORT .InvHzPut
.NormHzPut:
		ADD			EAX,[SMaxX]
		ADD			ECX,[SMinX]
.InvHzPut:
		TEST		ESI,2
		JZ			.NormVtPut
		SUB			EBX,[SMinY]
		SUB			EDX,[SMaxY]
		JMP			SHORT .InvVtPut
.NormVtPut:
		ADD			EBX,[SMaxY]
		ADD			EDX,[SMinY]
.InvVtPut:

		CMP			EAX,[_MinX]
		JL			.PasPutSurf
		CMP			EBX,[_MinY]
		JL			.PasPutSurf
		CMP			ECX,[_MaxX]
		JG			.PasPutSurf
		CMP			EDX,[_MaxY]
		JG			.PasPutSurf

		MOVD		mm6,[SMask]
		MOV			[PType],ESI ; save put Type
		PUNPCKLBW	mm6,mm6
		PUNPCKLWD	mm6,mm6
		PUNPCKLDQ	mm6,mm6


		; compute the clipped/unclipped put rectangle coordinaates in (PutSurfMinX, PutSurfMinY, PutSurfMaxX, PutSurfMaxY)
		;==========================================
		ClipStorePutSurfCoords

		;=========================
		; --- compute Put coordinates of the entire SrcSurf (as if source surf is full view)
		MOV         EAX,[EBP+MXPSN]  ; EAX = PutMaxX / without clipping
		MOV         EBX,[EBP+MYPSN]  ; EBX = PutMaxY / without clipping
		MOV			ESI,[PType] ; restore PType
		ComputeFullViewSrcSurfPutCoords

		CMP			EAX,[PutSurfMaxX]
		JG			.PutSurfClip
		CMP			EBX,[PutSurfMaxY]
		JG			.PutSurfClip
		CMP			ECX,[PutSurfMinX]
		JL			.PutSurfClip
		CMP			EDX,[PutSurfMinY]
		JL			.PutSurfClip
; PutSurf un Clipped *****************************
		MOV			EBP,[SResV]
		TEST		ESI,2
		JZ			.NormAdSPut
		MOV			ESI,[Srlfb]
		MOV			EAX,[SResH]
		ADD			ESI,[SSizeSurf]
		SUB			ESI,EAX
		ADD			EAX,EAX
		NEG			EAX
		MOVD		mm7,EAX
		JMP			NEAR .InvAdSPut
.NormAdSPut:
		XOR			EAX,EAX
		MOV			ESI,[Srlfb]
		MOVD		mm7,EAX
.InvAdSPut:
		MOV			EDI,EBX
		IMUL		EDI,[_ResH]
		NEG			EDI
		ADD			EDI,ECX
		ADD			EDI,[_vlfb]

		MOV			EBX,[SResH]
		MOV			EDX,[_ResH]
		SUB			EDX,EBX
		MOVD		mm1,EBX
		TEST		BYTE [PType],1
		MOV			CL,[SMask]
		JNZ        .InvHzPSurf

.BcPutSurf:
		MOVD		EBX,mm1

;**********************
.BcStBAv:
		TEST		EDI,7
		JZ			.FPasStBAv
		MOV			AL,[ESI]
		CMP			AL,[SMask]
		JE			.MaskBAv
		MOV			[EDI],AL
.MaskBAv:
		INC			ESI
		DEC			EBX
		LEA			EDI,[EDI+1]
		JZ			.FinSHLine
		JMP			SHORT .BcStBAv
.FPasStBAv:
		MOV			ECX,EBX
		SHR			ECX,3
		;OR			ECX,ECX
		JZ			SHORT .StBAp
ALIGN 4
.StoMMX:
        MOVQ      	mm2,[ESI]
        MOVQ        mm4,[EDI]
        MOVQ        mm3,[ESI]
        MOVQ        mm0,[ESI]

        PCMPEQB     mm2,mm6 ; [QSMask16]
        PCMPEQB     mm3,mm6 ; [QSMask16]
        PANDN       mm2,mm0
        PAND        mm4,mm3
        POR         mm2,mm4

		DEC			ECX
		MOVQ		[EDI],mm2
		LEA			ESI,[ESI+8]
		LEA			EDI,[EDI+8]
		JNZ			.StoMMX
.StBAp:
		AND			EBX,BYTE 7
		JZ			.FinSHLine
.BcStBAp:
		MOV			AL,[ESI]
		CMP			AL,[SMask]
		JE			.MaskBAp
		MOV			[EDI],AL
.MaskBAp:
		INC			ESI
		DEC			EBX
		LEA			EDI,[EDI+1]
		JNZ			.BcStBAp
.PasStBAp:
.FinSHLine:
;*************************************
		MOVD		EAX,mm7
		ADD			EDI,EDX
		ADD			ESI,EAX
		DEC			EBP
		JNZ			.BcPutSurf

		JMP			.PasPutSurf

.InvHzPSurf:    ; inverser horizontal

		MOV			EAX,[SResH]
		MOVD		mm3,EAX
		ADD			ESI,EAX
		PADDD		mm3,mm3
		PADDD		mm7,mm3 ; += [SResH*2]
.IBcPutSurf:
		MOVD		ECX,mm1 ; [SResH]
.IBcStBAv:
		TEST		EDI,7
		JZ			.IFPasStBAv
		DEC			ESI
		MOV			AL,[ESI]
		CMP			AL,[SMask]
		JE			.IMaskStBAv
		MOV			[EDI],AL
.IMaskStBAv:
		DEC			ECX
		LEA			EDI,[EDI+1]
		JZ			.IFinSHLine
		JMP			SHORT .IBcStBAv
.IFPasStBAv:

.IStoMMX:
		CMP			ECX,BYTE 7
		JLE			.IStBAp

		SUB			ESI,BYTE 8
		MOV			EAX,[ESI]
		MOV			EBX,[ESI+4]
		BSWAP		EAX
		BSWAP		EBX
		MOVD		mm2,EAX
		MOVD		mm0,EBX
		PUNPCKLDQ	mm0,mm2
        MOVQ        mm4,[EDI]
        MOVQ		mm2,mm0
        MOVQ		mm3,mm0

        PCMPEQB     mm2,mm6 ; [QSMask16]
        PCMPEQB     mm3,mm6 ; [QSMask16]
        PANDN       mm2,mm0
        PAND        mm4,mm3
        POR         mm2,mm4

		MOVQ		[EDI],mm2
		SUB			ECX, BYTE 8
		LEA			EDI,[EDI+8]
		JMP			.IStoMMX

.IStBAp:
		JECXZ		.IPasStBAp
.IBcStBAp:
		DEC			ESI
		MOV			AL,[ESI]
		CMP			AL,[SMask]
		JE			.IMaskStBAp
		MOV			[EDI],AL
.IMaskStBAp:
		DEC			ECX
		LEA			EDI,[EDI+1]
		JNZ			.IBcStBAp
.IPasStBAp:
.IFinSHLine:
;******************************
		MOVD		EAX,mm7
		ADD			EDI,EDX
		ADD			ESI,EAX
		DEC			EBP
		JNZ			NEAR .IBcPutSurf

		;JMP			.PasPutSurf
.PasPutSurf:

		POP			ESI
		POP			EDI
		POP			EBX
		;EMMS
	RETURN

.PutSurfClip:
; PutSurf Clipper **********************************************
		XOR			ESI,ESI   ; X deb Source
		XOR			EDI,EDI   ; Y Fin Source

		MOV			EBP,[PutSurfMinX]
		CMP			ECX,EBP
		JGE			.PsInfMinX   ; XP1<_MinX
		TEST		BYTE [PType],1
        JNZ			.InvHzCalcDX
		MOV         ESI,EBP
		SUB         ESI,ECX ; ESI = MinX - XP2
		MOV         ECX,EBP
.InvHzCalcDX:
		MOV			ECX,EBP
.PsInfMinX:
		MOV			EBP,[PutSurfMaxY]
		CMP			EBX,EBP
		JLE			.PsSupMaxY   ; YP2>_MaxY
		MOV			EDI,EBP
		NEG			EDI
		;MOV		[YP2],EBP
		ADD			EDI,EBX
		MOV			EBX,EBP
.PsSupMaxY:
		MOV			EBP,[PutSurfMinY]
		CMP			EDX,EBP      ; YP1<_MinY
		JGE			.PsInfMinY
		MOV			EDX,EBP
.PsInfMinY:
		MOV			EBP,[PutSurfMaxX]
		CMP			EAX,EBP      ; XP2>_MaxX
		JLE			.PsSupMaxX
		TEST		BYTE [PType],1
        JZ			.PsInvHzCalcDX
		MOV			ESI,EAX
		SUB			ESI,EBP	; ESI = XP2 - _MaxX
.PsInvHzCalcDX:
		MOV			EAX,EBP
.PsSupMaxX:
		MOV			EBP,EAX
		SUB			EBP,ECX      ; XP2 - XP1
		INC			EBP
		MOVD		mm1,EBP  ; mm1 = DeltaX
		MOVD		mm3,[SResH]
		PSUBD		mm3,mm1  ; mm3 = SResH-DeltaX, PlusSSurf

		MOV			EBP,EBX
		SUB			EBP,EDX      ; YP2 - YP1
		INC			EBP
		MOVD		mm2,EBP  ; mm2 = DeltaY
		MOVD		mm4,[_ResH]
		PSUBD		mm4,mm1  ; mm4 = _ResH-DeltaX, PlusDSurf

		TEST		BYTE [PType],2
		JZ			.CNormAdSPut
		MOV			EAX,[Srlfb] ; Si inverse vertical
		ADD			EAX,[SSizeSurf]
		SUB			EAX,[SResH]
		ADD			EAX,ESI
		IMUL		EDI,[SResH]
		SUB			EAX,EDI
		MOV			ESI,EAX

		MOV			EAX,[SResH]
		ADD			EAX,EAX
		NEG			EAX
		MOVD		mm7,EAX
		JMP			NEAR .CInvAdSPut
.CNormAdSPut:
		IMUL		EDI,[SResH]
		XOR			EAX,EAX
		ADD			EDI,ESI
		ADD			EDI,[Srlfb]
		MOV			ESI,EDI
		MOVD		mm7,EAX
.CInvAdSPut:
		MOV			EDI,EBX
		IMUL		EDI,[_ResH]
		NEG			EDI
		ADD			EDI,ECX
		ADD			EDI,[_vlfb]


		MOVD		EDX,mm4  ; = PlusDSurf
		TEST		BYTE [PType],1
		JNZ         .CInvHzPSurf
		PADDD		mm7,mm3
		MOV			CL,[SMask]
		JMP			.BcPutSurf

.CInvHzPSurf:   ; clipper et inverser horizontalement
		MOVD		EAX,mm1
		ADD			ESI,EAX
		;PADDD		mm7,mm1
		ADD			EAX,[SResH]
		MOVD		mm3,EAX
		PADDD		mm7,mm3
		MOV			CL,[SMask]
		JMP			.IBcPutSurf


ALIGN 32
_PutSurf:
	ARG	SSN, 4, XPSN, 4, YPSN, 4, PSType, 4
		PUSH		EBX
		PUSH		EDI
		PUSH		ESI

		MOV			ESI,[EBP+SSN]
		MOV			EDI,_SrcSurf
		MOV			EAX,[EBP+XPSN]
		MOV			EBX,[EBP+YPSN]

		CopySurf	; copy surf

		MOV			ECX,EAX
		MOV			EDX,EBX

		MOV         ESI,[EBP+PSType]
		TEST        ESI,1
		JZ          .NormHzPut
		SUB         EAX,[SMinX]
		SUB         ECX,[SMaxX]
		JMP         NEAR .InvHzPut
.NormHzPut:
		ADD			EAX,[SMaxX]
		ADD			ECX,[SMinX]
.InvHzPut:
		TEST        ESI,2
		JZ          .NormVtPut
		SUB         EBX,[SMinY]
		SUB         EDX,[SMaxY]
		JMP         NEAR .InvVtPut
.NormVtPut:
		ADD			EBX,[SMaxY]
		ADD			EDX,[SMinY]
.InvVtPut:


		CMP			EAX,[_MinX]
		JL			.PasPutSurf
		CMP			EBX,[_MinY]
		JL			.PasPutSurf
		CMP			ECX,[_MaxX]
		JG			.PasPutSurf
		CMP			EDX,[_MaxY]
		JG			.PasPutSurf

		MOV			[PType],ESI ; save put Type

		; compute the clipped/unclipped put rectangle coordinaates in (PutSurfMinX, PutSurfMinY, PutSurfMaxX, PutSurfMaxY)
		;==========================================
		ClipStorePutSurfCoords

		; --- compute Put coordinates of the entire Surf (as if source surf is full view)
		; EAX: MaxX, EBX; MaxY, ECX: MinX, EDX: MnY
		MOV         EAX,[EBP+XPSN]  ; EAX = PutMaxX / without clipping
		MOV         EBX,[EBP+YPSN]  ; EBX = PutMaxY / without clipping
		MOV			ESI,[PType] ; restore PType
		ComputeFullViewSrcSurfPutCoords

		CMP			EAX,[PutSurfMaxX]
		JG			.PutSurfClip
		CMP			EBX,[PutSurfMaxY]
		JG			.PutSurfClip
		CMP			ECX,[PutSurfMinX]
		JL			.PutSurfClip
		CMP			EDX,[PutSurfMinY]
		JL			.PutSurfClip

; PutSurf un Clipped *****************************
		MOV			EBP,[SResV]
		TEST		ESI,2
		JZ			SHORT .NormAdSPut
		MOV			ESI,[Srlfb]
		MOV			EAX,[SResH]
		ADD			ESI,[SSizeSurf]
		SUB			ESI,EAX
		ADD			EAX,EAX
		NEG			EAX
		MOVD		mm7,EAX
		JMP			SHORT .InvAdSPut
.NormAdSPut:
		MOV			ESI,[Srlfb]
		PXOR		mm7,mm7 ; = 0
.InvAdSPut:
		MOV			EDI,EBX
		IMUL		EDI,[_ResH]
		NEG			EDI
		ADD			EDI,ECX
		MOV			EAX,[SResH]
		ADD			EDI,[_vlfb]
		MOVD		mm1,EAX
		MOV			EDX,[_ResH]
		SUB			EDX,EAX

		TEST		BYTE [PType],1
        JNZ         .InvHzPSurf

.BcPutSurf:
		MOVD		EBX,mm1 ; mm1 ; = [SResH] or clipped width
.BcStBAv:
		TEST		EDI,3
		JZ			.FPasStBAv
		DEC			EBX
		MOVSB
		JZ			.FinSHLine
		JMP			SHORT .BcStBAv
.FPasStBAv:
		TEST		EDI,4
		JZ			.PasStDAv
		TEST		EBX,0xfffffffc
		JZ			.StBAp
		MOVSD
		SUB			EBX,BYTE 4
.PasStDAv:
		MOV			ECX,EBX
		SHR			ECX,3
		;OR			ECX,ECX
		JZ			SHORT .StDAp
ALIGN 4
.StoMMX:
		MOVQ		mm0,[ESI]
		DEC			ECX
		MOVQ		[EDI],mm0
		LEA			ESI,[ESI+8]
		LEA			EDI,[EDI+8]
		JNZ			.StoMMX
		AND			EBX,BYTE 7
		JZ			.FinSHLine
.StDAp:
		TEST		EBX,4
		JZ			.StBAp
		MOVSD
		SUB			EBX,BYTE 4
.StBAp:
		OR			EBX,EBX
		JZ			.PasStBAp
		MOV			ECX,EBX
		REP			MOVSB
.PasStBAp:
.FinSHLine:
		MOVD		EAX,mm7
		ADD			EDI,EDX
		ADD			ESI,EAX
		DEC			EBP
		JNZ			.BcPutSurf

		JMP			.PasPutSurf

.InvHzPSurf:    ; inversed horizontally

		MOVD		EBX,mm7
		ADD			ESI,EAX ; += [SResH]
		LEA			EBX,[EBX+EAX*2]
		MOVD		mm7,EBX ; mm7 += [SResH*2]
.IBcPutSurf:
		MOVD		ECX,mm1 ; [SResH]
.IBcStBAv:
		TEST		EDI,3
		JZ			.IFPasStBAv
		DEC			ESI
		MOV			AL,[ESI]
		STOSB
		DEC			ECX
		JZ			.IFinSHLine
		JMP			SHORT .IBcStBAv
.IFPasStBAv:
		TEST		EDI,4
		JZ			.IPasStDAv
		TEST		ECX,0xfffffffc
		JZ			.IStBAp
		SUB			ESI,BYTE 4
		MOV			EAX,[ESI]
		SUB			ECX,BYTE 4
		BSWAP		EAX
		STOSD
.IPasStDAv:
		;MOV			ECX,EBX
		;SHR			ECX,3
		;OR			ECX,ECX
.IStoMMX:
		TEST		ECX,0xfffffff8
		JZ			.IStDAp

		SUB			ESI,BYTE 8
		MOV			EAX,[ESI]
		MOV			EBX,[ESI+4]
		BSWAP		EAX
		BSWAP		EBX
		MOV			[EDI+4],EAX
		MOV			[EDI],EBX
		SUB			ECX, BYTE 8
		LEA			EDI,[EDI+8]

		JMP			.IStoMMX

		;AND			EBX,BYTE 7
.IStDAp:
		TEST		ECX,4
		JZ			.IStBAp
		SUB			ESI,4
		MOV			EAX,[ESI]
		BSWAP		EAX
		STOSD
		SUB			ECX,BYTE 4

.IStBAp:
		JECXZ		.IPasStBAp
.IBcStBAp:
		DEC			ESI
		MOV			AL,[ESI]
		STOSB
		DEC			ECX
		JNZ			.IBcStBAp
.IPasStBAp:
.IFinSHLine:
		MOVD		EAX,mm7
		ADD			EDI,EDX
		ADD			ESI,EAX
		DEC			EBP
		JNZ			.IBcPutSurf

.PasPutSurf:
		POP			ESI
		POP			EDI
		POP			EBX
		;EMMS
	RETURN

.PutSurfClip:
; PutSurf Clipped **********************************************
		XOR			EDI,EDI   ; Y Fin Source
		XOR			ESI,ESI   ; X deb Source

		MOV			EBP,[PutSurfMinX]
		CMP			ECX,EBP
		JGE			.PsInfMinX   ; XP1<_MinX
		TEST		BYTE [PType],1
		JNZ			.InvHzCalcDX
		MOV         ESI,EBP
		SUB         ESI,ECX ; ESI = MinX - XP2
		MOV         ECX,EBP
.InvHzCalcDX:
		MOV			ECX,EBP
.PsInfMinX:
		MOV			EBP,[PutSurfMaxY]
		CMP			EBX,EBP
		JLE			.PsSupMaxY   ; YP2>_MaxY
		MOV			EDI,EBP
		NEG			EDI
		;MOV		[YP2],EBP
		ADD			EDI,EBX
		MOV			EBX,EBP
.PsSupMaxY:
		MOV			EBP,[PutSurfMinY]
		CMP			EDX,EBP      ; YP1<_MinY
		JGE			.PsInfMinY
		MOV			EDX,EBP
.PsInfMinY:
		MOV			EBP,[PutSurfMaxX]
		CMP			EAX,EBP      ; XP2>_MaxX
		JLE			.PsSupMaxX
		TEST		BYTE [PType],1
        JZ			.PsInvHzCalcDX
		MOV			ESI,EAX
		SUB			ESI,EBP	; ESI = XP2 - _MaxX
.PsInvHzCalcDX:
		MOV			EAX,EBP
.PsSupMaxX:
		MOV			EBP,EAX
		SUB			EBP,ECX      ; XP2 - XP1
		INC			EBP
		MOVD		mm1,EBP  ; mm1 = DeltaX
		MOVD		mm3,[SResH]
		PSUBD		mm3,mm1  ; mm3 = SResH-DeltaX, PlusSSurf

		MOV			EBP,EBX
		SUB			EBP,EDX      ; YP2 - YP1
		INC			EBP
		MOVD		mm2,EBP  ; mm2 = DeltaY
		MOVD		mm4,[_ResH]
		PSUBD		mm4,mm1  ; mm4 = _ResH-DeltaX, PlusDSurf

		TEST		BYTE [PType],2
		JZ			.CNormAdSPut
		MOV			EAX,[Srlfb] ; Si inverse vertical
		MOV			EDX,[SResH]
		ADD			EAX,[SSizeSurf]
		SUB			EAX,EDX; [SResH]
		ADD			EAX,ESI
		IMUL		EDI,EDX; [SResH]
		SUB			EAX,EDI
		MOV			ESI,EAX

		LEA			EAX,[EDX*2]; [SResH] * 2
		NEG			EAX
		MOVD		mm7,EAX
		JMP			SHORT .CInvAdSPut
.CNormAdSPut:
		IMUL		EDI,[SResH]
		XOR			EAX,EAX
		ADD			EDI,ESI
		ADD			EDI,[Srlfb]
		MOV			ESI,EDI
		MOVD		mm7,EAX
.CInvAdSPut:
		MOV			EDI,EBX
		IMUL		EDI,[_ResH]
		NEG			EDI
		ADD			EDI,ECX
		ADD			EDI,[_vlfb]

		MOVD		EDX,mm4  ; DeltaX
		TEST		BYTE [PType],1
		JNZ        	.CInvHzPSurf
		PADDD		mm7,mm3
		JMP			.BcPutSurf

.CInvHzPSurf:   ; clipper et inverser horizontalement
		MOVD		EAX,mm1
		MOVD		mm0,[SResH]
		PADDD		mm7,mm1
		PADDD		mm7,mm0
		ADD			ESI,EAX
		JMP			.IBcPutSurf



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
		IMUL		EDI,[_NegScanLine] ; * ScanLine
		MOV		ECX,ESI ; ECX = deltaY = number pixels
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


