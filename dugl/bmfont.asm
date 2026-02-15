


_SetCurBMFont:
    ARG PSrcBMFONT, 4

            MOV         EAX,[EBP+PSrcBMFONT]
            MOV         ECX,97 ; sizeof(DBMFONT) / 64
            OR          EAX,EAX
            MOV         EDX,_CurDBMFONT
            JZ          .NotSet
.BcCopyCurBMF:
            MOVQ		mm0,[EAX]
            MOVQ		mm1,[EAX+32]
            MOVQ		mm2,[EAX+8]
            MOVQ		mm3,[EAX+40]
            MOVQ		mm4,[EAX+16]
            MOVQ		[EDX],mm0
            MOVQ		mm5,[EAX+48]
            MOVQ		[EDX+32],mm1
            MOVQ		mm6,[EAX+24]
            MOVQ		[EDX+8],mm2
            MOVQ		mm7,[EAX+56]

            MOVQ		[EDX+40],mm3
            MOVQ		[EDX+16],mm4
            MOVQ		[EDX+48],mm5
            MOVQ		[EDX+24],mm6
            MOVQ		[EDX+56],mm7

            DEC         ECX
            LEA         EAX,[EAX+64]
            LEA         EDX,[EDX+64]
            JNZ         .BcCopyCurBMF

.NotSet:
    MMX_RETURN

; PUT Bitmap character in SrcSurf into CurSurf at (BMCharsRendX, BMCharsRendY)  and (ECX, EDX)
;*****************

;********************************************************
%macro  @PutBMChar16 0
        MOV         EAX,ECX
        MOV         EBX,EDX

; --- compute Put coordinates of the View inside the Surf
; EAX: MaxX, EBX; MaxY, ECX: MinX, EDX: MnY
        ADD         EAX,[SMaxX] ; EAX = PutMaxX
        ADD         ECX,[SMinX] ; ECX = PutMinX
        ADD         EBX,[SMaxY] ; EBX = PutMaxY
        ADD         EDX,[SMinY] ; EDX = PutMinY

		CMP			EAX,[_MinX]
		JL			%%PasPutSurf
		CMP			EBX,[_MinY]
		JL			%%PasPutSurf
		CMP			ECX,[_MaxX]
		JG			%%PasPutSurf
		CMP			EDX,[_MaxY]
		JG			%%PasPutSurf


		; compute the clipped/unclipped put rectangle coordinaates in (PutSurfMinX, PutSurfMinY, PutSurfMaxX, PutSurfMaxY)
		;==========================================
		ClipStorePutSurfCoords

		;=========================
		; --- compute Put coordinates of the entire SrcSurf (as if source surf is full view)
        MOV         EAX,[BMCharsRendX]
        MOV         EBX,[BMCharsRendY]
        MOV         ECX,EAX
        MOV         EDX,EBX
        MOV         EDI,[SOrgX]

        ADD         EAX,[SResH]
        SUB         ECX,EDI ; MinX = ECX = posXPut - SOrgX
        SUB         EAX,EDI
        DEC         EAX         ; MaxX = EAX = posXPut + (SResH -1) - SOrgX

        MOV         EDI,[SOrgY]
        ADD         EBX,[SResV]
        SUB         EDX,EDI ; MinX = ECX = posXPut - SOrgX
        SUB         EBX,EDI
        DEC         EBX         ; MaxX = EAX = posXPut + (SResH -1) - SOrgX

		MOVD		mm7,[SMask]
		PUNPCKLWD	mm7,mm7
		PUNPCKLDQ	mm7,mm7 ; = [QSMask16]

		CMP			EAX,[PutSurfMaxX]
		JG			%%PutSurfClip
		CMP			EBX,[PutSurfMaxY]
		JG			%%PutSurfClip
		CMP			ECX,[PutSurfMinX]
		JL			%%PutSurfClip
		CMP			EDX,[PutSurfMinY]
		JL			%%PutSurfClip
; PutSurf non Clipper *****************************
		MOV			EBP,[SResV]
		XOR			EAX,EAX
		MOV			ESI,[Srlfb] ; ESI : start copy adress

		MOV			EDI,EBX ; PutMaxY or the top left corner
		IMUL		EDI,[_NegScanLine]
		MOV			EDX,[_ScanLine]
		LEA			EDI,[EDI+ECX*2] ; += PutMinX*2 top left croner
		SUB			EDX,[SScanLine] ; EDX : dest adress plus
		ADD			EDI,[_vlfb]
		MOV			[Plus2],EDX

		MOV			EDX,[SResH]
		MOV			[Plus],EAX

%%BcPutSurf:
		MOV			EBX,EDX ; = [SResH]
%%BcStBAv:
		TEST		EDI,6  		; qword aligned ?
		JZ			%%FPasStBAv
		MOV			AX,[ESI]
		CMP			AX,[SMask]
		JE			%%MaskBAv
		MOV			[EDI],AX
%%MaskBAv:
		DEC			EBX
		LEA			ESI,[ESI+2]
		LEA			EDI,[EDI+2]
		JZ			%%FinSHLine
		JMP			SHORT %%BcStBAv
%%FPasStBAv:

%%StoMMX:
		CMP			EBX,BYTE 3
		JLE			%%StBAp

		MOVQ		mm0,[ESI]
        MOVQ        mm6,[EDI]
        MOVQ      	mm2,[ESI]
        MOVQ        mm1,[ESI]

        PCMPEQW     mm2,mm7; [QSMask16]
        PCMPEQW     mm1,mm7; [QSMask16]
        PANDN       mm2,mm0
        PAND        mm6,mm1
        POR         mm2,mm6

		SUB			EBX, BYTE 4
		MOVQ		[EDI],mm2
		LEA			ESI,[ESI+8]
		LEA			EDI,[EDI+8]
		JMP			%%StoMMX
%%StBAp:
		AND			EBX,BYTE 3
		JZ			%%FinSHLine
%%BcStBAp:
		MOV			AX,[ESI]
		CMP			AX,[SMask]
		JE			%%MaskBAp
		MOV			[EDI],AX
%%MaskBAp:
		DEC			EBX
		LEA			ESI,[ESI+2]
		LEA			EDI,[EDI+2]
		JNZ			%%BcStBAp
%%PasStBAp:

%%FinSHLine:
		ADD			EDI,[Plus2]
		ADD			ESI,[Plus]
		DEC			EBP
		JNZ			%%BcPutSurf

		JMP			%%PasPutSurf

%%PutSurfClip:

; PutSurf Clipper **********************************************
		XOR			EDI,EDI   ; Y Fin Source
		XOR			ESI,ESI   ; X deb Source

		MOV			EBP,[PutSurfMinX]
		CMP			ECX,EBP ; CMP minx, _MinX
		JGE			%%PsInfMinX   ; XP1<_MinX
        MOV         ESI,EBP
        SUB         ESI,ECX ; ESI = MinX - XP2
        MOV         ECX,EBP
%%PsInfMinX:
		MOV			EBP,[PutSurfMaxY]
		CMP			EBX,EBP ; cmp maxy, _MaxY
		JLE			%%PsSupMaxY   ; YP2>_MaxY
		MOV			EDI,EBP
		NEG			EDI
		;MOV		[YP2],EBP
		ADD			EDI,EBX
		MOV			EBX,EBP
%%PsSupMaxY:
		MOV			EBP,[PutSurfMinY]
		CMP			EDX,EBP      ; YP1<_MinY
		JGE			%%PsInfMinY
		MOV			EDX,EBP
%%PsInfMinY:
		MOV			EBP,[PutSurfMaxX]
		CMP			EAX,EBP      ; XP2>_MaxX
		JLE			%%PsSupMaxX
		MOV			EAX,EBP
%%PsSupMaxX:
		SUB			EAX,ECX      ; XP2 - XP1
		MOV			EBP,[SScanLine]
		LEA			EAX,[EAX*2+2]
		SUB			EBP,EAX  ; EBP = SResH-DeltaX, PlusSSurf
		MOV			[Plus],EBP
		MOV			EBP,EBX
		SUB			EBP,EDX      ; YP2 - YP1
		INC			EBP   ; EBP = DeltaY
		MOV			EDX,[_ScanLine]
		MOVD        mm0,EAX ; = DeltaX
		SUB			EDX,EAX ; EDX = _ResH-DeltaX, PlusDSurfS
		MOV			[Plus2],EDX

		IMUL        EDI,[SScanLine]
		XOR			EAX,EAX
		LEA			EDI,[EDI+ESI*2]
		ADD			EDI,[Srlfb]
		MOV			ESI,EDI
%%CInvAdSPut:
		MOV			EDI,EBX
		IMUL        EDI,[_NegScanLine]
		LEA			EDI,[EDI+ECX*2] ; + XP1*2 as 16bpp
		PSRLD       mm0,1 ; (deltaX*2) / 2
		ADD			EDI,[_vlfb]

		MOVD        EDX,mm0  ; DeltaX
		ADD			[Plus],EAX
		JMP			%%BcPutSurf

%%PasPutSurf:
%endmacro ; @PutBMChar16



ALIGN 4
_OutTextBM16:
    ARG PBMStr, 4

            PUSH        ESI
            PUSH        EDI
            PUSH        EBX

            MOV         EDX,[EBP+PBMStr]
            XOR         EAX,EAX
            OR          EDX,EDX
            JZ          .End              ; NULL pointer ?
            OR          AL,[EDX]
            JNZ         .SetSrcSurfAndRend   ; not empty string ?
            JMP         .End

.RendStrLoop:
            PUSH        EDX
            MOV         ECX,[BMCharsXOffset+EAX*4]
            MOV         EDX,[BMCharY]
            ADD         ECX,[BMCharX]                ; = CurDBMFONT.CharX + myBMFont->CharsXOffset[*str];
            ADD         EDX,[BMCharsGHeight]
            MOV         [BMCharsRendX],ECX
            SUB         EDX,[BMCharsHeight+EAX*4]
            SUB         EDX,[BMCharsYOffset+EAX*4]
            MOV         [BMCharsRendY],EDX                 ; BMCharsRendY = BMCharY + CurDBMFONT.CharsGHeight - (CurDBMFONT.CharsHeight[*str] + CurDBMFONT.CharsYOffset[*str]);

            @PutBMChar16

            MOV         EAX,[BMCharCurChar]           ; current rendered char
            POP         EDX                           ; restore str pointer
            MOV         EBP,[BMCharsPlusX+EAX*4]
            INC         EDX                           ; increment str pointer
            XOR         AL,AL
            ADD         [BMCharX],EBP                 ; CurDBMFONT.CharX += CurDBMFONT.CharsPlusX[*str]
            OR          AL,[EDX]                      ; end of the string ?
            JZ          SHORT .End
            CMP         AL,[BMCharCurChar]
            JE          SHORT .NotSetSrcSurf
.SetSrcSurfAndRend:
            MOV         ESI,[BMCharsSSurfs+EAX*4]
            MOV         EDI,_SrcSurf
            CopySurf    ; copy surf
            MOV         [BMCharCurChar],EAX
.NotSetSrcSurf:
            JMP         .RendStrLoop

.End:
            POP         EBX
            POP         EDI
            POP         ESI

    RETURN

