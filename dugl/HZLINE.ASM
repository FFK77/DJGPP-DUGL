;***** SOLID
;***************************************************************************
; IN : EAX col, ESI long, EDI Dest,
; change : mm0, mm1, ECX
;***************************************************************************
%macro	@SolidHLine	0
%%BcStBAv:	TEST		EDI,3
		JZ		%%FPasStBAv
		DEC		ESI
		STOSB
		JZ		%%FinSHLine
		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		TEST		EDI,4
		JZ		%%PasStDAv
		CMP		ESI,BYTE 3
		JLE		%%StBAp
		MOV		[EDI],EAX
		SUB		ESI,BYTE 4
		ADD		EDI,BYTE 4
%%PasStDAv:
		MOV		ECX,ESI
		SHR		ECX,3
		JECXZ		%%StDAp
		MOVD		mm0,EAX
		PUNPCKLDQ	mm0,mm0
;ALIGN 4
%%StoMMX:	MOVQ		[EDI],mm0
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX
		AND		ESI,BYTE 7
		JZ		%%FinSHLine
%%StDAp: 	TEST		ESI,4
		JZ		%%StBAp
		MOV		[EDI],EAX
		SUB		ESI,BYTE 4
		ADD		EDI,BYTE 4
%%StBAp:	OR		ESI,ESI
		MOV		ECX,ESI
		JZ		%%PasStBAp
		REP		STOSB
%%PasStBAp:
%%FinSHLine:
%endmacro

;****** TEXT
;**IN*TEXTure Horizontal Line***********************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2)
; a ne pas utiliser mm6 & mm7
; utilise mm5,mm4,mm3,mm2,mm1,mm0
;***************************************************************************
%macro	@InTextHLine  0
		MOV		EAX,[YT2]
		MOV		EBP,[XT2]
		SUB		EAX,[YT1]   ; EAX = DY
		JZ		%%CasDYZ
		SUB		EBP,[XT1]   ; EBP = DX
		JZ		%%CasDXZ
%%CasNorm:	@InTextHLineNorm
		JMP		%%FinInTextHLg
%%CasDXZ:	@InTextHLineDXZ
		JMP		%%FinInTextHLg
%%CasDYZ:	@InTextHLineDYZ
%%FinInTextHLg:
%endmacro

%macro	@InTextHLineNorm 0
		MOV		ESI,[YT1]      ; - 1
		SHL 		EAX,Prec
		IMUL		ESI,[SResH]    ; - 2
		OR		ECX,ECX
		CDQ
		JZ		SHORT %%PDivPntPY ;+ S
		IDIV		ECX
		JMP		SHORT %%DivPntPY
%%PDivPntPY:	XOR		EAX,EAX
%%DivPntPY:
		NEG		ESI	       ; - 3
		NEG		EAX
		ADD		ESI,[XT1]      ; - 4
		MOV		[PntPlusY],EAX  ;[PntPlusY]

		XOR		EDX,EDX
		MOV		EAX,EBP

		OR		EDX,BYTE 8
		ADD		ESI,[Svlfb]    ; - 5
		SHL		EAX,Prec
		MOVD		mm5,EDX
		OR		ECX,ECX
		CDQ
		JZ		SHORT %%PDivPntPX ; + S
		IDIV		ECX
		JMP		SHORT %%DivPntPX
%%PDivPntPX:	XOR		EAX,EAX
%%DivPntPX:
		;--- ajuste Cpt Dbrd X et Y pour SAR
		MOV		[PntPlusX],EAX
		XOR		EBX,EBX
		OR		EAX,EAX
		SETL		BL
		MOV		EDX,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr X
		MOV		EAX,[PntPlusY]
		INC		ECX
		OR		EAX,EAX
		SETL		BL
		MOV		EBP,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr Y
		
%%BcStBAv:	TEST		EDI,7
		JZ		SHORT %%FPasStBAv ; +S
		@AjAdNormB
		MOV		AL,[EBX+ESI]
		DEC		ECX
		STOSB
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		TEST		ECX,0xfffffff8
		JZ		%%StBAp
%%PasStDAv:
		MOVD		mm2,ECX  ; save first 3 bits of ECX
		MOVD		mm1,EDI  ; save EDI in mm1
		SHR		ECX,3
;ALIGN 4
%%StoMMX:       @AjAdNormQ
                MOVD		mm3,ECX   ; save ECX
		MOV		AL,[ESI+EBX] ; read byte 0
		@AjAdNormQ
		MOV		CL,[ESI+EBX] ; read byte 1
		@AjAdNormQ
		MOV		AH,[ESI+EBX] ; read byte 2 - AH first because EAX reversed
		@AjAdNormQ
		BSWAP		EAX
		MOV		CH,[ESI+EBX] ; read byte 3
		@AjAdNormQ
		BSWAP		ECX
		MOV		AH,[ESI+EBX] ; read byte 4
		@AjAdNormQ
		MOV		CH,[ESI+EBX] ; read byte 5
		@AjAdNormQ
		MOV		AL,[ESI+EBX] ; read byte 6
		@AjAdNormQ
		MOV		CL,[ESI+EBX] ; read byte 7
		BSWAP		EAX    ; EAX in the right order
		BSWAP		ECX    ; ECX in the right order
		MOVD		mm0,EAX

		MOVD		EDI,mm1
                MOVD            mm4,ECX ; second 4 byte to write
		PADDD		mm1,mm5    ; EDI += 8
		PUNPCKLBW	mm0,mm4 ; make the full 8 bytes to write
                MOVD		ECX,mm3   ; restore ECX
		MOVQ		[EDI],mm0 ; write the 8 bytes
		DEC		ECX
		JNZ		%%StoMMX

		MOVD		ECX,mm2 ; restore first 3 bits of ECX
		LEA		EDI,[EDI+8]
		AND		ECX,BYTE 7
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdNormB
		MOV		AL,[ESI+EBX]
		DEC		ECX
		STOSB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

%macro  @AjAdNormB 0
		MOV		EBX,EBP
		MOV		EAX,EDX
		SAR		EBX,Prec
		SAR		EAX,Prec
		IMUL		EBX,[SResH]
		ADD		EBP,[PntPlusY]
		ADD		EDX,[PntPlusX]
		ADD		EBX,EAX
%endmacro
%macro  @AjAdNormQ 0
		MOV		EBX,EBP
		MOV		EDI,EDX
		SAR		EBX,Prec
		SAR		EDI,Prec
		IMUL		EBX,[SResH]
		ADD		EBP,[PntPlusY]
		ADD		EDX,[PntPlusX]
		ADD		EBX,EDI
%endmacro

;********************************************************

%macro	@InTextHLineDXZ  0
		MOV		ESI,[YT1]    ; - 1
		SHL		EAX,Prec
		IMUL		ESI,[SResH]  ; - 2
		OR		ECX,ECX
		CDQ
		JZ		%%PDivPntPX
		IDIV		ECX
		JMP		SHORT %%DivPntPX
%%PDivPntPX:	XOR		EAX,EAX
%%DivPntPX:
		NEG		ESI	     ; - 3
		MOV		EBP,EAX ; [PntPlusY]
		ADD		ESI,[XT1]    ; - 4
		XOR		EBX,EBX
		OR		EAX,EAX
		ADD		ESI,[Svlfb]  ; - 5
		SETG		BL
		INC		ECX
		MOV		EDX,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr Y
%%BcStBAv:	TEST		EDI,7
		JZ		%%FPasStBAv
		@AjAdDXZ
		MOV		AL,[ESI+EBX]
		DEC		ECX
		STOSB
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		TEST		ECX,0xfffffff8
		JZ		%%StBAp
%%PasStDAv:
		MOVD		mm2,ECX
		SHR		ECX,3
;ALIGN 4
%%StoMMX:	@AjAdDXZ
                MOVD            mm3, ECX   ; save ECX
		MOV		AL,[ESI+EBX] ; read byte 0
		@AjAdDXZ
		MOV		CL,[ESI+EBX] ; read byte 1
		@AjAdDXZ
		MOV		AH,[ESI+EBX] ; read byte 2 - AH first cause EAX reversed
		@AjAdDXZ
		BSWAP		EAX
		MOV		CH,[ESI+EBX] ; read byte 3
		@AjAdDXZ
		BSWAP		ECX
		MOV		AH,[ESI+EBX] ; read byte 4
		@AjAdDXZ
		MOV		CH,[ESI+EBX] ; read byte 5
		@AjAdDXZ
		MOV		AL,[ESI+EBX] ; read byte 6
		@AjAdDXZ
		MOV		CL,[ESI+EBX] ; read byte 7
		BSWAP		EAX ; EAX on the write bytes order
                BSWAP           ECX ; ECX on the write bytes order
                MOVD            mm0, EAX ; first 4 bytes to write
                MOVD            mm1, ECX ; second 4 bytes to write
                MOVD            ECX, mm3   ; restore ECX
		PUNPCKLBW	mm0,mm1 ; make the full 8 bytes to write

		DEC		ECX
		MOVQ		[EDI],mm0 ; write the 8 bytes
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX


		MOVD		ECX,mm2
		AND		ECX,BYTE 7
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdDXZ
		MOV		AL,[ESI+EBX]
		DEC		ECX
		STOSB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

%macro  @AjAdDXZ  0
		MOV		EBX,EDX
		SAR		EBX,Prec
		SUB		EDX,EBP ;-[PntPlusY]
		IMUL		EBX,[SResH]
%endmacro
;********************************************************

%macro	@InTextHLineDYZ 0
		SUB		EBP,[XT1]
		MOV		ESI,[YT1]   ; - 1
		MOV		EAX,EBP
		IMUL		ESI,[SResH] ; - 2
		SHL 		EAX,Prec
		NEG		ESI	    ; - 3
		CDQ
		ADD		ESI,[XT1]   ; - 4
		OR		ECX,ECX
		JZ		%%PDivPntPX
		IDIV		ECX
		JMP		SHORT %%DivPntPX
%%PDivPntPX:	XOR		EAX,EAX
%%DivPntPX:
		ADD		ESI,[Svlfb] ; - 5
		XOR		EBX,EBX
		MOV		EBP,EAX  ;[PntPlusX]
		OR		EAX,EAX			; SAR
		SETL		BL
		INC		ECX
		MOV		EDX,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr X
%%BcStBAv:	TEST		EDI,7
		JZ		%%FPasStBAv
		@AjAdDYZ
		ADD		EDX,EBP
		MOV		AL,[ESI+EBX]
		DEC		ECX
		STOSB
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		TEST		ECX,0xfffffff8
		JZ		%%StBAp
%%PasStDAv:
		MOVD		mm2,ECX
		SHR		ECX,3

;ALIGN 4
%%StoMMX:	@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		MOVD            mm3,ECX  ; save ECX
		MOV		AL,[ESI+EBX] ; read byte 0
		@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		CL,[ESI+EBX] ; read byte 1
		@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		AH,[ESI+EBX]  ; read byte 2 - AH first because EAX reversed
		@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		BSWAP		EAX
		MOV		CH,[ESI+EBX]  ; read byte 3
		@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		BSWAP		ECX
		MOV		AH,[ESI+EBX] ; read byte 4
		@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		CH,[ESI+EBX] ; read byte 5
		@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		AL,[ESI+EBX] ; read byte 6
		@AjAdDYZ
		BSWAP		EAX
		MOV		CL,[ESI+EBX] ; read byte 7
		MOVD		mm0,EAX  ; first 4 bytes to write
		BSWAP		ECX  ; ecx bytes on the right order
		ADD		EDX,EBP ;+[PntPlusX]
		MOVD		mm1,ECX  ; second 4 bytes to write
		PUNPCKLBW	mm0,mm1 ; make the full 8 bytes to write
		MOVD		ECX,mm3  ; restore ECX
		MOVQ		[EDI],mm0 ; write the 8 bytes
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		SHORT %%StoMMX

		MOVD		ECX,mm2
		AND		ECX,BYTE 7
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		AL,[ESI+EBX]
		DEC		ECX
		STOSB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

%macro  @AjAdDYZ  0
		MOV		EBX,EDX
		SAR		EBX,Prec
%endmacro


;**Clip*TEXTure Horizontal Line***********************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2)
; a ne pas utiliser mm6 & mm7 & mm3 & mm4
;***************************************************************************
%macro	@ClipTextHLine  0
		MOV		EAX,[YT2]
		MOV		EBP,[XT2]
		SUB		EAX,[YT1]   ; EAX = DY
		JZ		%%CasDYZ
		SUB		EBP,[XT1]   ; EBP = DX
		JZ		%%CasDXZ
%%CasNorm:	@ClipTextHLineNorm
		JMP		%%FinInTextHLg
%%CasDXZ:	@ClipTextHLineDXZ
		JMP		%%FinInTextHLg
%%CasDYZ:	@ClipTextHLineDYZ
%%FinInTextHLg:
%endmacro

%macro	@ClipTextHLineNorm 0
		SHL 		EAX,Prec
		MOV		ESI,[YT1]      ; - 1'
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusY
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusY
%%PDivPPlusY:	XOR		EAX,EAX
%%DivPPlusY:
		IMUL		ESI,[SResH]    ; - 2'
		NEG		EAX
		MOV		[PntPlusY],EAX  ;[PntPlusY]

		MOV		EAX,EBP
		XOR		EDX,EDX
		OR		EDX,BYTE 8
		NEG		ESI	       ; - 3'
		SHL		EAX,Prec
		ADD		ESI,[XT1]      ; - 4'
		MOVD		mm5,EDX
		ADD		ESI,[Svlfb]    ; - 5'
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusX
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusX
%%PDivPPlusX:	XOR		EAX,EAX
%%DivPPlusX:
		MOV		EBP,[PntPlusY] ; - 1
		MOV		EBX,[Plus]
		MOV		[PntPlusX],EAX
		MOV 		EDX,[PntPlusX] ; - 2
		IMUL		EBP,EBX	       ; - 3
		IMUL		EDX,EBX        ; - 4
		;--- ajuste Cpt Dbrd X et Y pour SAR
		MOV		EAX,[PntPlusY]
		OR		EAX,EAX
		JGE		%%PosPntPlusY
		LEA		EBP,[EBP+((1<<Prec)-1)] ; EBP += 2**N-1
%%PosPntPlusY:
		MOV		EAX,[PntPlusX]
		OR		EAX,EAX
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:	;-----------------------------------
%%BcStBAv:	TEST		EDI,7
		JZ		%%FPasStBAv
		@AjAdNormB
		MOV		AL,[ESI+EBX]
		DEC		ECX
		STOSB
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		TEST		ECX,0xfffffff8
		JZ		%%StBAp
%%PasStDAv:
		MOVD		mm2,ECX
		SHR		ECX,3
;ALIGN 4
%%StoMMX:       MOVD		mm1,EDI  ; save EDI
		@AjAdNormQ
                MOVD		mm5,ECX   ; save ECX
		MOV		AL,[ESI+EBX] ; read byte 0
		@AjAdNormQ
		MOV		AH,[ESI+EBX] ; read byte 1
                BSWAP           EAX  ; reverse EAX bytes
		@AjAdNormQ
		MOV		AH,[ESI+EBX] ; read byte 2 - AH first because EAX reversed
		@AjAdNormQ
		MOV		AL,[ESI+EBX] ; read byte 3
		@AjAdNormQ
		MOV		CL,[ESI+EBX] ; read byte 4
		@AjAdNormQ
		MOV		CH,[ESI+EBX] ; read byte 5
                BSWAP           EAX   ; EAX in the right order
                BSWAP           ECX   ; reverse ECX bytes
                MOVD            mm0,EAX ; first 4 bytes to write
		@AjAdNormQ
		MOV		CH,[ESI+EBX] ; read byte 6
		@AjAdNormQ
		MOV		CL,[ESI+EBX] ; read byte 7
		
		MOVD		EDI,mm1  ; restore EDI
                BSWAP           ECX   ; ECX in the right order
                MOVD            mm1,ECX ; second 4 byte to write
		PUNPCKLDQ	mm0,mm1 ; make the full 8 bytes to write
                MOVD		ECX,mm5   ; restore ECX
		MOVQ		[EDI],mm0 ; write the 8 bytes
		DEC		ECX
                LEA             EDI,[EDI+8]
		JNZ		%%StoMMX

		MOVD		ECX,mm2
		AND		ECX,BYTE 7
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdNormB
		MOV		AL,[ESI+EBX]
		DEC		ECX
		STOSB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;*******************************************************************
%macro	@ClipTextHLineDXZ  0
		MOV		ESI,[YT1]   ; - 1
		SHL		EAX,Prec
		IMUL		ESI,[SResH] ; - 2
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusY
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusY
%%PDivPPlusY:	XOR		EAX,EAX
%%DivPPlusY:
		NEG		ESI	    ; - 3
		MOV		EBP,EAX ; [PntPlusY]
		ADD		ESI,[XT1]   ; - 4
		MOV		EDX,[Plus]
		ADD		ESI,[Svlfb] ; - 5
		NEG		EDX
		IMUL		EDX,EBP ;-[PntPlusY] axe Y montant
		OR		EAX,EAX
		JLE		%%PosPntPlusY
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusY:
%%BcStBAv:	TEST		EDI,7
		JZ		%%FPasStBAv
		@AjAdDXZ
		MOV		AL,[ESI+EBX]
		DEC		ECX
		STOSB
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		TEST		ECX,0xfffffff8
		JZ		%%StBAp
%%PasStDAv:
		MOVD		mm2,ECX
		SHR		ECX,3
;ALIGN 4
%%StoMMX:	@AjAdDXZ
		MOV		AL,[ESI+EBX]
		@AjAdDXZ
		MOV		[Temp],AL
		MOV		AH,[ESI+EBX]
                MOVD            mm5,ECX  ; save ECX
                BSWAP           EAX ; reverse EAX bytes order
		@AjAdDXZ
		MOV		AH,[ESI+EBX]
		@AjAdDXZ
		MOV		AL,[ESI+EBX]
		@AjAdDXZ
		MOV		CL,[ESI+EBX]
		@AjAdDXZ
		MOV		CH,[ESI+EBX]
                BSWAP           EAX ; restore EAX bytes order
                BSWAP           ECX ; reverse ECX bytes order
		@AjAdDXZ
		MOV		CH,[ESI+EBX]
		@AjAdDXZ
		MOV		CL,[ESI+EBX]
                BSWAP           ECX ; restore ECX bytes order
                MOVD            mm0,EAX ; first 4 bytes to write
                MOVD            mm1,ECX
		PUNPCKLDQ	mm0,mm1 ; make the full 8 bytes to write
                MOVD            ECX,mm5  ; restore ECX
		MOVQ		[EDI],mm0 ; write 8 bytes
		DEC		ECX

		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX

		MOVD		ECX,mm2
		AND		ECX,BYTE 7
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdDXZ
		DEC		ECX
		MOV		AL,[ESI+EBX]
		STOSB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro


;********************************************************

%macro	@ClipTextHLineDYZ 0
		SUB		EBP,[XT1]
		MOV		ESI,[YT1]
		MOV		EAX,EBP
		SHL 		EAX,Prec
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusY
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusY
%%PDivPPlusY:	XOR		EAX,EAX
%%DivPPlusY:
		MOV		EBP,EAX  ;[PntPlusX]
		IMUL		ESI,[SResH]
		MOV		EDX,[Plus]
		NEG		ESI
		IMUL		EDX,EBP ;+[PntPlusX]
		ADD		ESI,[XT1]
		ADD		ESI,[Svlfb]
		OR		EAX,EAX
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:
%%BcStBAv:	TEST		EDI,7
		JZ		%%FPasStBAv
		@AjAdDYZ
		ADD		EDX,EBP
		MOV		AL,[ESI+EBX]
		DEC		ECX
		STOSB
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		TEST		ECX,0xfffffff8
		JZ		%%StBAp
%%PasStDAv:
		MOVD		mm2,ECX
		SHR		ECX,3
;ALIGN 4
%%StoMMX:	@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		AL,[ESI+EBX]
		@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		AH,[ESI+EBX]
		MOV		[Temp],AL
		@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		AL,[ESI+EBX]
		MOV		[Temp+1],AH
		@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		AH,[ESI+EBX]
		MOV		[Temp+2],AL
		@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		AL,[ESI+EBX]
		MOV		[Temp+3],AH
		@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		AH,[ESI+EBX]
		MOV		[Temp+4],AL
		@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		AL,[ESI+EBX]
		MOV		[Temp+5],AH
		@AjAdDYZ
		MOV		[Temp+6],AL
		MOV		AH,[ESI+EBX]
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		[Temp+7],AH
		DEC		ECX

		MOVQ		mm0,[Temp]
		MOVQ		[EDI],mm0
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX

		MOVD		ECX,mm2
		AND		ECX,BYTE 7
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		AL,[ESI+EBX]
		DEC		ECX
		STOSB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;****** MASK_TEXT
;**IN*MASK_TEXTure Horizontal Line******************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2)
; a ne pas utiliser mm6 & mm7
;***************************************************************************
%macro	@InMaskTextHLine  0
		MOV		EAX,[YT2]
		MOV		EBP,[XT2]
		SUB		EAX,[YT1]   ; EAX = DY
		JZ		%%CasDYZ
		SUB		EBP,[XT1]   ; EBP = DX
		JZ		%%CasDXZ
%%CasNorm:	@InMaskTextHLineNorm
		JMP		%%FinInTextHLg
%%CasDXZ:	@InMaskTextHLineDXZ
		JMP		%%FinInTextHLg
%%CasDYZ:	@InMaskTextHLineDYZ
%%FinInTextHLg:
%endmacro

%macro	@InMaskTextHLineNorm 0
		MOV		ESI,[YT1]      ; - 1
		SHL 		EAX,Prec
		IMUL		ESI,[SResH]    ; - 2
		OR		ECX,ECX
		JZ		%%PDivPntPX
		CDQ
		IDIV		ECX
		JMP		SHORT %%DivPntPX
%%PDivPntPX:	XOR		EAX,EAX
%%DivPntPX:
		NEG		ESI	       ; - 3
		NEG		EAX
		ADD		ESI,[XT1]      ; - 4
		MOV		[PntPlusY],EAX  ;[PntPlusY]
		ADD		ESI,[Svlfb]    ; - 5

		MOV		EAX,EBP
		SHL		EAX,Prec
		OR		ECX,ECX
		JZ		%%PDivPntPY
		CDQ
		IDIV		ECX
		JMP		SHORT %%DivPntPY
%%PDivPntPY:	XOR		EAX,EAX
%%DivPntPY:
		;--- ajuste Cpt Dbrd X et Y pour SAR
		MOV		[PntPlusX],EAX
		XOR		EBX,EBX
		OR		EAX,EAX
		SETL		BL
		MOV		EDX,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr X
		MOV		EAX,[PntPlusY]
		INC		ECX
		OR		EAX,EAX
		SETL		BL
		MOV		EBP,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr Y
;ALIGN 4
%%BcStB:	@AjAdNormB
		MOV		AL,[ESI+EBX]
		TEST		AL,AL
		JZ		%%PasDB
		MOV		[EDI],AL
%%PasDB:
		DEC		ECX
		LEA		EDI,[EDI+1]
		JNZ		%%BcStB
%%PasStBAp:
%%FinSHLine:
%endmacro

%macro	@InMaskTextHLineDXZ  0
		MOV		ESI,[YT1]    ; - 1
		SHL		EAX,Prec
		IMUL		ESI,[SResH]  ; - 2
		OR		ECX,ECX
		JZ		%%PDivPntPX
		CDQ
		IDIV		ECX
		JMP		SHORT %%DivPntPX
%%PDivPntPX:	XOR		EAX,EAX
%%DivPntPX:
		NEG		ESI	     ; - 3
		MOV		EBP,EAX ; [PntPlusY]
		INC		ECX
		XOR		EBX,EBX
		OR		EAX,EAX 	      ;--- SAR
		ADD		ESI,[XT1]    ; - 4
		SETG		BL
		ADD		ESI,[Svlfb]  ; - 5
		MOV		EDX,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr Y
;ALIGN 4
%%BcStB:	@AjAdDXZ
		MOV		AL,[ESI+EBX]
		OR		AL,AL
		JZ		%%PasDB
		MOV		[EDI],AL
%%PasDB:	DEC		ECX
		LEA		EDI,[EDI+1]
		JNZ		%%BcStB
%%PasStBAp:
%%FinSHLine:
%endmacro

;********************************************************
%macro	@InMaskTextHLineDYZ 0
		MOV		ESI,[YT1]   ; - 1
		SUB		EBP,[XT1]
		IMUL		ESI,[SResH] ; - 2
		MOV		EAX,EBP
		NEG		ESI	    ; - 3
		SHL 		EAX,Prec
		ADD		ESI,[XT1]   ; - 4

		OR		ECX,ECX
		JZ		%%PDivPntPX
		CDQ
		IDIV		ECX
		JMP		SHORT %%DivPntPX
%%PDivPntPX:	XOR		EAX,EAX
%%DivPntPX:
		ADD		ESI,[Svlfb] ; - 5
		INC		ECX
		XOR		EBX,EBX
		MOV		EBP,EAX  ;[PntPlusX]
		OR		EAX,EAX			; SAR
		SETL		BL
		MOV		EDX,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr X
;ALIGN 4
%%BcStB:	@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		AL,[ESI+EBX]
		OR		AL,AL
		JZ		%%PasDB
		MOV		[EDI],AL
%%PasDB:
		DEC		ECX
		LEA		EDI,[EDI+1]
		JNZ		%%BcStB
%%PasStBAp:
%%FinSHLine:
%endmacro

;**Clip*MASK_TEXTure Horizontal Line***********************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2)
; a ne pas utiliser mm6 & mm7
;***************************************************************************
%macro	@ClipMaskTextHLine  0
		MOV		EAX,[YT2]
		MOV		EBP,[XT2]
		SUB		EAX,[YT1]   ; EAX = DY
		JZ		%%CasDYZ
		SUB		EBP,[XT1]   ; EBP = DX
		JZ		%%CasDXZ
%%CasNorm:	@ClipMaskTextHLineNorm
		JMP		%%FinInTextHLg
%%CasDXZ:	@ClipMaskTextHLineDXZ
		JMP		%%FinInTextHLg
%%CasDYZ:	@ClipMaskTextHLineDYZ
%%FinInTextHLg:
%endmacro

%macro	@ClipMaskTextHLineNorm 0
		SHL 		EAX,Prec
		MOV		ESI,[YT1]      ; - 1'
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusY
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusY
%%PDivPPlusY:	XOR		EAX,EAX
%%DivPPlusY:
		IMUL		ESI,[SResH]    ; - 2'
		NEG		EAX
		MOV		[PntPlusY],EAX  ;[PntPlusY]

		MOV		EAX,EBP
		XOR		EDX,EDX
		OR		EDX,BYTE 8
		NEG		ESI	       ; - 3'
		SHL		EAX,Prec
		MOVD		mm5,EDX
		ADD		ESI,[XT1]      ; - 4'
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusX
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusX
%%PDivPPlusX:	XOR		EAX,EAX
%%DivPPlusX:
		MOV		EBP,[PntPlusY] ; - 1
		MOV		EBX,[Plus]
		MOV		[PntPlusX],EAX
		MOV 		EDX,[PntPlusX] ; - 2
		IMUL		EBP,EBX	       ; - 3
		ADD		ESI,[Svlfb]    ; - 5'
		IMUL		EDX,EBX        ; - 4
		;--- ajuste Cpt Dbrd X et Y pour SAR
		MOV		EAX,[PntPlusY]
		OR		EAX,EAX
		JGE		%%PosPntPlusY
		LEA		EBP,[EBP+((1<<Prec)-1)] ; EBP += 2**N-1
%%PosPntPlusY:
		MOV		EAX,[PntPlusX]
		OR		EAX,EAX
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:	;-----------------------------------
;ALIGN 4
%%BcStBAp:	@AjAdNormB
		MOV		AL,[ESI+EBX]
		OR		AL,AL
		JZ		%%PasDr
		MOV		[EDI],AL
%%PasDr:	DEC		ECX
		LEA		EDI,[EDI+1]
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;*******************************************************************
%macro	@ClipMaskTextHLineDXZ  0
		MOV		ESI,[YT1]   ; - 1
		SHL		EAX,Prec
		IMUL		ESI,[SResH] ; - 2
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusY
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusY
%%PDivPPlusY:	XOR		EAX,EAX
%%DivPPlusY:
		NEG		ESI	    ; - 3
		MOV		EBP,EAX ; [PntPlusY]
		ADD		ESI,[XT1]   ; - 4
		MOV		EDX,[Plus]
		ADD		ESI,[Svlfb] ; - 5
		NEG		EDX
		IMUL		EDX,EBP ;-[PntPlusY] axe Y montant
		OR		EAX,EAX 	      ;--- SAR
		JLE		%%PosPntPlusY
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusY:
;ALIGN 4
%%BcStBAp:	@AjAdDXZ
		MOV		AL,[ESI+EBX]
		OR		AL,AL
		JZ		%%PasDr
		MOV		[EDI],AL
%%PasDr:	DEC		ECX
		LEA		EDI,[EDI+1]
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro


;********************************************************

%macro	@ClipMaskTextHLineDYZ 0
		SUB		EBP,[XT1]
		MOV		EAX,EBP
		SHL 		EAX,Prec
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusY
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusY
%%PDivPPlusY:	XOR		EAX,EAX
%%DivPPlusY:
		MOV		EBP,EAX  ;[PntPlusX]
		MOV		ESI,[YT1]
		IMUL		ESI,[SResH]
		MOV		EDX,[Plus]
		NEG		ESI
		IMUL		EDX,EBP ;+[PntPlusX]
		ADD		ESI,[XT1]
		ADD		ESI,[Svlfb]
		OR		EAX,EAX			; SAR
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:
;ALIGN 4
%%BcStBAp:	@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		AL,[ESI+EBX]
		OR		AL,AL
		JZ		%%PasDr
		MOV		[EDI],AL
%%PasDr:	DEC		ECX
		LEA		EDI,[EDI+1]
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro


;***** DEG
;***************************************************************************
; IN : ECX long, EDI Dest, ESI Ptr TbDegCol, Col1 ColDeb, Col2 ColFin
;      EAX Col2, EBP Col1
; A ne pas utiliser mm6, mm7, (mm4, mm3 : clip)
;***************************************************************************
%macro	@InDEGHLine	0
		SUB		EAX,EBP    ; Col2-Col1
		SHL		EAX,Prec
		OR		ECX,ECX
		JZ		%%PDivPntPX
		CDQ
		IDIV		ECX
		JMP		SHORT %%DivPntPX
%%PDivPntPX:	XOR		EAX,EAX
%%DivPntPX:
		MOV		EBX,EBP
		INC		ECX
		SHL		EBX,Prec
		MOV		EBP,EAX
		MOV		EDX,EBX
%%BcStBAv:	TEST		EDI,7
		JZ		%%FPasStBAv
		@AjDEGHLine
		MOV		AL,[ESI+EDX]
		DEC		ECX
		MOV		EDX,EBX
		STOSB
		JZ		%%FinSHLine
		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		TEST		ECX,0xfffffff8
		JZ		%%StBAp
%%PasStDAv:
		MOVD		mm1,ECX
		SHR		ECX,3
;ALIGN 4
%%StoMMX:
		@AjDEGHLine
		MOV		AL,[ESI+EDX] ; read byte 0
		MOV		EDX,EBX
		@AjDEGHLine
		MOV		AH,[ESI+EDX] ; read byte 1
		MOV		EDX,EBX
                BSWAP           EAX
		@AjDEGHLine
		MOV		AH,[ESI+EDX] ; read byte 2
		MOV		EDX,EBX
		@AjDEGHLine
		MOV		AL,[ESI+EDX] ; read byte 3
		MOV		EDX,EBX
                BSWAP           EAX
                MOVD            mm0, EAX
		@AjDEGHLine
		MOV		AL,[ESI+EDX] ; read byte 4
		MOV		EDX,EBX
		@AjDEGHLine
		MOV		AH,[ESI+EDX] ; read byte 5
		MOV		EDX,EBX
                BSWAP           EAX
		@AjDEGHLine
		MOV		AH,[ESI+EDX] ; read byte 6
		MOV		EDX,EBX
		@AjDEGHLine
		MOV		AL,[ESI+EDX] ; read byte 7
		MOV		EDX,EBX
                BSWAP           EAX
                MOVD            mm2,EAX
		DEC		ECX
		PUNPCKLDQ	mm0,mm2
		MOVQ		[EDI],mm0
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX

		MOVD		ECX,mm1
		AND		ECX,BYTE 7
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjDEGHLine
		MOV		AL,[ESI+EDX]
		DEC		ECX
		MOV		EDX,EBX
		STOSB
		JNZ		%%BcStBAp
;%%PasStBAp:
%%FinSHLine:
%endmacro

%macro	@AjDEGHLine	0
		SHR		EDX,Prec
		ADD		EBX,EBP
%endmacro
		
%macro	@ClipDEGHLine	0
		SUB		EAX,EBP    ; Col2-Col1
		SHL		EAX,Prec
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusCOL
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusCOL
%%PDivPPlusCOL:	XOR		EAX,EAX
%%DivPPlusCOL:
		MOV		EBX,EBP
		SHL		EBX,Prec
		MOV		EBP,EAX
		IMUL		EAX,[Plus]
		ADD		EBX,EAX
		MOV		EDX,EBX
%%BcStBAv:	TEST		EDI,7
		JZ		%%FPasStBAv
		@AjDEGHLine
		MOV		AL,[ESI+EDX]
		DEC		ECX
		MOV		EDX,EBX
		STOSB
		JZ		%%FinSHLine
		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		TEST		ECX,0xfffffff8
		JZ		NEAR %%StBAp
%%PasStDAv:
		MOVD		mm1,ECX
		SHR		ECX,3
;ALIGN 4
%%StoMMX:
		@AjDEGHLine
		MOV		AL,[ESI+EDX] ; read byte 0
		MOV		EDX,EBX
		@AjDEGHLine
		MOV		AH,[ESI+EDX] ; read byte 1
		MOV		EDX,EBX
                BSWAP           EAX  ; reverse EAX bytes order
		@AjDEGHLine
		MOV		AH,[ESI+EDX] ; read byte 2
		MOV		EDX,EBX
		@AjDEGHLine
		MOV		AL,[ESI+EDX] ; read byte 3
		MOV		EDX,EBX
                BSWAP           EAX  ; restore EAX bytes order
                MOVD            mm0,EAX  ; first 4 bytes to write
		@AjDEGHLine
		MOV		AL,[ESI+EDX] ; read byte 4
		MOV		EDX,EBX
		@AjDEGHLine
		MOV		AH,[ESI+EDX] ; read byte 5
		MOV		EDX,EBX
                BSWAP           EAX  ; reverse EAX bytes order
		@AjDEGHLine
		MOV		AH,[ESI+EDX] ; read byte 6
		MOV		EDX,EBX
		@AjDEGHLine
		MOV		AL,[ESI+EDX] ; read byte 7
                BSWAP           EAX  ; restore EAX bytes order
		MOV		EDX,EBX
                MOVD            mm2,EAX
		PUNPCKLDQ	mm0,mm2
		DEC		ECX
		MOVQ		[EDI],mm0
		LEA		EDI,[EDI+8]

		JNZ		%%StoMMX

		MOVD		ECX,mm1
		AND		ECX,BYTE 7
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjDEGHLine
		MOV		AL,[ESI+EDX]
		DEC		ECX
		MOV		EDX,EBX
		STOSB
		JNZ		%%BcStBAp
;%%PasStBAp:
%%FinSHLine:
%endmacro


;****** FLAT_DEG_TEXT

;**IN*FLAT_DEG_TEXTure Horizontal Line**************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2), mm3 =Ptr_TbDegCol+Col
; a ne pas utiliser mm6 & mm7
; utilise mm5,mm2,mm1,mm0
;***************************************************************************
%macro	@InFDegTextHLine  0
		MOV		EAX,[YT2]
		MOV		EBP,[XT2]
		SUB		EAX,[YT1]   ; EAX = DY
		;MOVD		mm5,[PtrTbDegCol]
		JZ		%%CasDYZ
		SUB		EBP,[XT1]   ; EBP = DX
		JZ		%%CasDXZ
%%CasNorm:	@InFDegTextHLineNorm
		JMP		%%FinInTextHLg
%%CasDXZ:	@InFDegTextHLineDXZ
		JMP		%%FinInTextHLg
%%CasDYZ:	@InFDegTextHLineDYZ
%%FinInTextHLg:
%endmacro

%macro	@InFDegTextHLineNorm 0
		MOV		ESI,[YT1]      ; - 1
		SHL 		EAX,Prec
		IMUL		ESI,[SResH]    ; - 2
		
		OR		ECX,ECX
		JZ		%%PDivPntPX
		CDQ
		IDIV		ECX
		JMP		SHORT %%DivPntPX
%%PDivPntPX:	XOR		EAX,EAX
%%DivPntPX:
		NEG		ESI	       ; - 3
		NEG		EAX
		ADD		ESI,[XT1]      ; - 4
		MOV		[PntPlusY],EAX  ;[PntPlusY]

		MOV		EAX,EBP
		ADD		ESI,[Svlfb]    ; - 5
		SHL		EAX,Prec
		OR		ECX,ECX
		JZ		%%PDivPntPY
		CDQ
		IDIV		ECX
		JMP		SHORT %%DivPntPY
%%PDivPntPY:	XOR		EAX,EAX
%%DivPntPY:
		INC		ECX
		MOV		[PntPlusX],EAX
		;--- ajuste Cpt Dbrd X et Y pour SAR
		XOR		EDX,EDX     ; Cpt Dbr X
		OR		EAX,EAX
		JGE		%%PosPntPlusX
		MOV		EDX,((1<<Prec)-1) ; EDX += 2**N-1
%%PosPntPlusX:
		MOV		EAX,[PntPlusY]
		XOR		EBP,EBP     ; Cpt Dbr Y
		OR		EAX,EAX
		JGE		%%PosPntPlusY
		MOV		EBP,((1<<Prec)-1) ; EBP += 2**N-1
%%PosPntPlusY:	;-----------------------------------
;ALIGN 4
%%BcStBAv:	TEST		EDI,7
		JZ		%%FPasStBAv
		@AjAdNormB
		@FDegB
		MOV		AL,[EBX+EAX]
		DEC		ECX
		STOSB
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		TEST		ECX,0xfffffff8
		JZ		%%StBAp
%%PasStDAv:
		MOVD		mm5,ECX
		SHR		ECX,3
;ALIGN 4
%%StoMMX:
                MOVD		mm1,EDI  ; save EDI
		MOVD		mm4,ECX ; save ECX
		@AjAdNormB
                @FDegB
		MOV		CL,[EBX+EAX] ; byte 0
		@AjAdNormB
                @FDegB
		MOV		CH,[EBX+EAX] ; byte 1
		@AjAdNormB
                BSWAP           ECX ; reverse ECX bytes order
                @FDegB
		MOV		CH,[EBX+EAX] ; byte 2
		@AjAdNormB
                @FDegB
		MOV		CL,[EBX+EAX] ; byte 3
		@AjAdNormB
                BSWAP           ECX ; restore ECX bytes order
                MOVD            mm0,ECX  ; first 4 bytes to write
                @FDegB
		MOV		CL,[EBX+EAX] ; byte 4
		@AjAdNormB
                @FDegB
		MOV		CH,[EBX+EAX] ; byte 5
		@AjAdNormB
                BSWAP           ECX
                @FDegB
		MOV		CH,[EBX+EAX] ; byte 6
		@AjAdNormB
                @FDegB
		MOV		CL,[EBX+EAX] ; byte 7
                BSWAP           ECX ; restore ECX bytes order
                MOVD		EDI,mm1  ; restore EDI
                MOVD            mm2,ECX  ; second 4 bytes to write
		PUNPCKLDQ	mm0,mm2
                
		MOVD		ECX,mm4 ; restore ECX
		MOVQ		[EDI],mm0
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX
		
		MOVD		ECX,mm5
		AND		ECX,BYTE 7
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdNormB
		@FDegB
		MOV		AL,[EBX+EAX]
		DEC		ECX
		STOSB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

%macro @FDegB 0  ; byte dans AL
                XOR             EAX,EAX
		MOV		AL,BYTE [ESI+EBX]
		MOV		EBX,[PtrTbDegCol]; mm5 ; Ptr TbDegCol
		SHL		EAX,6
%endmacro

;********************************************************

%macro	@InFDegTextHLineDXZ  0
		MOV		ESI,[YT1]    ; - 1
		SHL		EAX,Prec
		IMUL		ESI,[SResH]  ; - 2
		OR		ECX,ECX
		JZ		%%PDivPntPX
		CDQ
		IDIV		ECX
		JMP		SHORT %%DivPntPX
%%PDivPntPX:	XOR		EAX,EAX
%%DivPntPX:
		NEG		ESI	     ; - 3
		INC		ECX
		MOV		EBP,EAX ; [PntPlusY]
		ADD		ESI,[XT1]    ; - 4
		XOR		EDX,EDX      ; Cpt Dbrd Y
		OR		EAX,EAX 	      ;--- SAR
		JLE		%%PosPntPlusY
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusY:
		ADD		ESI,[Svlfb]  ; - 5
%%BcStBAv:	TEST		EDI,7
		JZ		%%FPasStBAv
		@AjAdDXZ
		@FDegB
		DEC		ECX
		MOV		AL,[EBX+EAX]
		STOSB
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		TEST		ECX,0xfffffff8
		JZ		%%StBAp
%%PasStDAv:
		MOVD		mm5,ECX
		SHR		ECX,3
;ALIGN 4
%%StoMMX:	MOVD		mm1,EDI
		@AjAdDXZ
		MOVD		mm4,ECX ; save ECX
		@FDegB
		MOV		CL,[EBX+EAX] ; byte 0
		@AjAdDXZ
		@FDegB
		MOV		CH,[EBX+EAX] ; byte 1
		@AjAdDXZ
                BSWAP           ECX ; swap ECX bytes order
		@FDegB
		MOV		CH,[EBX+EAX] ; byte 2
		@AjAdDXZ
		@FDegB
		MOV		CL,[EBX+EAX] ; byte 3
		@AjAdDXZ
                BSWAP           ECX ; ECX bytes back to the right order
		@FDegB
                MOVD            mm0, ECX ; first 4 bytes to write
		MOV		CL,[EBX+EAX] ; byte 4
		@AjAdDXZ
		@FDegB
		MOV		CH,[EBX+EAX] ; byte 5
		@AjAdDXZ
                BSWAP           ECX ; swap ECX bytes order
		@FDegB
		MOV		CH,[EBX+EAX] ; byte 6
		@AjAdDXZ
		@FDegB
		MOV		CL,[EBX+EAX] ; byte 7
                BSWAP           ECX ; ECX bytes back to the right order
                MOVD            mm2, ECX ; second 4 bytes to write

                MOVD		EDI,mm1  ; restore EDI
		PUNPCKLDQ	mm0,mm2
		MOVD		ECX,mm4 ; restore ECX
		MOVQ		[EDI],mm0
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX

		MOVD		ECX,mm5
		AND		ECX,BYTE 7
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdDXZ
		@FDegB
		DEC		ECX
		MOV		AL,[EBX+EAX]
		STOSB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;********************************************************

%macro	@InFDegTextHLineDYZ 0
		SUB		EBP,[XT1]
		MOV		ESI,[YT1]   ; - 1
		MOV		EAX,EBP
		IMUL		ESI,[SResH] ; - 2
		SHL 		EAX,Prec
		NEG		ESI	    ; - 3
		
		OR		ECX,ECX
		JZ		%%PDivPntPX
		CDQ
		IDIV		ECX
		JMP		SHORT %%DivPntPX
%%PDivPntPX:	XOR		EAX,EAX
%%DivPntPX:
		XOR		EDX,EDX  ;Cpt Dbrd X
		INC		ECX
		ADD		ESI,[XT1]   ; - 4
		MOV		EBP,EAX  ;[PntPlusX]
		ADD		ESI,[Svlfb] ; - 5
		OR		EAX,EAX			; SAR
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:
%%BcStBAv:	TEST		EDI,7
		JZ		%%FPasStBAv
		@AjAdDYZ
		ADD		EDX,EBP
		@FDegB
		DEC		ECX
		MOV		AL,[EBX+EAX]
		STOSB
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		TEST		ECX,0xfffffff8
		JZ		%%StBAp
%%PasStDAv:
		MOVD		mm5,ECX
		SHR		ECX,3
;ALIGN 4
%%StoMMX:	MOVD		mm1,EDI
		@AjAdDYZ
		MOVD		mm4,ECX ; save ECX
		@FDegB
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		CL,[EBX+EAX]  ; byte 0
		@AjAdDYZ
		@FDegB
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		CH,[EBX+EAX]  ; byte 1
		@AjAdDYZ
                BSWAP           ECX ; reverse ECX bytes order
		@FDegB
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		CH,[EBX+EAX]  ; byte 2
		@AjAdDYZ
		@FDegB
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		CL,[EBX+EAX]  ; byte 3
		@AjAdDYZ
                BSWAP           ECX ; restore ECX bytes order
                MOVD            mm0, ECX
		@FDegB
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		CL,[EBX+EAX]  ; byte 4
		@AjAdDYZ
		@FDegB
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		CH,[EBX+EAX]  ; byte 5
		@AjAdDYZ
                BSWAP           ECX ; reverse ECX bytes order
		@FDegB
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		CH,[EBX+EAX]  ; byte 6
		@AjAdDYZ
		@FDegB
		MOV		CL,[EBX+EAX]  ; byte 7
		ADD		EDX,EBP ;+[PntPlusX]
                BSWAP           ECX ; restore ECX bytes order
                MOVD            mm2,ECX
                MOVD		EDI,mm1  ; restore EDI
		PUNPCKLDQ	mm0,mm2
		MOVD		ECX,mm4  ; restore ECX
		MOVQ		[EDI],mm0
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX

		MOVD		ECX,mm5
		AND		ECX,BYTE 7
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		@FDegB
		MOV		AL,[EBX+EAX]
		DEC		ECX
		STOSB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro


;**Clip*FLAT_DEG_TEXTure Horizontal Line************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2)
; a ne pas utiliser mm6 & mm7
;***************************************************************************
%macro	@ClipFDegTextHLine  0
		MOV		EAX,[YT2]
		MOV		EBP,[XT2]
		SUB		EAX,[YT1]   ; EAX = DY
		MOVD		mm5,[PtrTbDegCol]
		JZ		%%CasDYZ
		SUB		EBP,[XT1]   ; EBP = DX
		JZ		%%CasDXZ
%%CasNorm:	@ClipFDegTextHLineNorm
		JMP		%%FinInTextHLg
%%CasDXZ:	@ClipFDegTextHLineDXZ
		JMP		%%FinInTextHLg
%%CasDYZ:	@ClipFDegTextHLineDYZ
%%FinInTextHLg:
%endmacro

%macro	@ClipFDegTextHLineNorm 0
		SHL 		EAX,Prec
		MOV		ESI,[YT1]      ; - 1'
		
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusY
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusY
%%PDivPPlusY:	XOR		EAX,EAX
%%DivPPlusY:
		IMUL		ESI,[SResH]    ; - 2'
		NEG		EAX
		MOV		[PntPlusY],EAX  ;[PntPlusY]

		MOV		EAX,EBP
		NEG		ESI	       ; - 3'
		SHL		EAX,Prec
		ADD		ESI,[XT1]      ; - 4'
		
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusX
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusX
%%PDivPPlusX:	XOR		EAX,EAX
%%DivPPlusX:
		ADD		ESI,[Svlfb]    ; - 5'
		MOV		EBP,[PntPlusY] ; - 1
		MOV		EBX,[Plus]
		MOV		[PntPlusX],EAX
		MOV 		EDX,[PntPlusX] ; - 2
		IMUL		EBP,EBX	       ; - 3
		IMUL		EDX,EBX        ; - 4
		;--- ajuste Cpt Dbrd X et Y pour SAR
		MOV		EAX,[PntPlusY]
		OR		EAX,EAX
		JGE		%%PosPntPlusY
		LEA		EBP,[EBP+((1<<Prec)-1)] ; EBP += 2**N-1
%%PosPntPlusY:
		MOV		EAX,[PntPlusX]
		OR		EAX,EAX
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:	;-----------------------------------
%%BcStBAv:	TEST		EDI,7
		JZ		%%FPasStBAv
		@AjAdNormB
		@FDegB
		DEC		ECX
		MOV		AL,[EBX+EAX]
		STOSB
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		TEST		ECX,0xfffffff8
		JZ		%%StBAp
%%PasStDAv:
		MOVD		mm5,ECX
		SHR		ECX,3
;ALIGN 4
%%StoMMX:
                MOVD		mm1,EDI  ; save EDI
		MOVD		mm4,ECX ; save ECX
		@AjAdNormB
                @FDegB
		MOV		CL,[EBX+EAX] ; byte 0
		@AjAdNormB
                @FDegB
		MOV		CH,[EBX+EAX] ; byte 1
		@AjAdNormB
                BSWAP           ECX ; reverse ECX bytes order
                @FDegB
		MOV		CH,[EBX+EAX] ; byte 2
		@AjAdNormB
                @FDegB
		MOV		CL,[EBX+EAX] ; byte 3
		@AjAdNormB
                BSWAP           ECX ; restore ECX bytes order
                MOVD            mm0,ECX  ; first 4 bytes to write
                @FDegB
		MOV		CL,[EBX+EAX] ; byte 4
		@AjAdNormB
                @FDegB
		MOV		CH,[EBX+EAX] ; byte 5
		@AjAdNormB
                BSWAP           ECX
                @FDegB
		MOV		CH,[EBX+EAX] ; byte 6
		@AjAdNormB
                @FDegB
		MOV		CL,[EBX+EAX] ; byte 7
                BSWAP           ECX ; restore ECX bytes order
                MOVD		EDI,mm1  ; restore EDI
                MOVD            mm2,ECX  ; second 4 bytes to write
		PUNPCKLDQ	mm0,mm2
                
		MOVD		ECX,mm4 ; restore ECX
		MOVQ		[EDI],mm0
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX
		
		MOVD		ECX,mm5
		AND		ECX,BYTE 7
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdNormB
		@FDegB
		DEC		ECX
		MOV		AL,[EBX+EAX]
		STOSB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;*******************************************************************
%macro	@ClipFDegTextHLineDXZ  0
		MOV		ESI,[YT1]   ; - 1
		SHL		EAX,Prec
		IMUL		ESI,[SResH] ; - 2
		
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusY
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusY
%%PDivPPlusY:	XOR		EAX,EAX
%%DivPPlusY:
		NEG		ESI	    ; - 3
		MOV		EBP,EAX ; [PntPlusY]
		ADD		ESI,[XT1]   ; - 4
		MOV		EDX,[Plus]
		ADD		ESI,[Svlfb] ; - 5
		NEG		EDX
		IMUL		EDX,EBP ;-[PntPlusY] axe Y montant
		OR		EAX,EAX 	      ;--- SAR
		JLE		%%PosPntPlusY
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusY:
%%BcStBAv:	TEST		EDI,7
		JZ		%%FPasStBAv
		@AjAdDXZ
		@FDegB
		DEC		ECX
		MOV		AL,[EBX+EAX]
		STOSB
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		TEST		ECX,0xfffffff8
		JZ		%%StBAp
%%PasStDAv:
		MOVD		mm5,ECX
		SHR		ECX,3
;ALIGN 4
%%StoMMX:	MOVD		mm1,EDI
		@AjAdDXZ
		MOVD		mm4,ECX ; save ECX
		@FDegB
		MOV		CL,[EBX+EAX] ; byte 0
		@AjAdDXZ
		@FDegB
		MOV		CH,[EBX+EAX] ; byte 1
		@AjAdDXZ
                BSWAP           ECX ; swap ECX bytes order
		@FDegB
		MOV		CH,[EBX+EAX] ; byte 2
		@AjAdDXZ
		@FDegB
		MOV		CL,[EBX+EAX] ; byte 3
		@AjAdDXZ
                BSWAP           ECX ; ECX bytes back to the right order
		@FDegB
                MOVD            mm0, ECX ; first 4 bytes to write
		MOV		CL,[EBX+EAX] ; byte 4
		@AjAdDXZ
		@FDegB
		MOV		CH,[EBX+EAX] ; byte 5
		@AjAdDXZ
                BSWAP           ECX ; swap ECX bytes order
		@FDegB
		MOV		CH,[EBX+EAX] ; byte 6
		@AjAdDXZ
		@FDegB
		MOV		CL,[EBX+EAX] ; byte 7
                BSWAP           ECX ; ECX bytes back to the right order
                MOVD            mm2, ECX ; second 4 bytes to write

                MOVD		EDI,mm1  ; restore EDI
		PUNPCKLDQ	mm0,mm2
		MOVD		ECX,mm4 ; restore ECX
		MOVQ		[EDI],mm0
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX

		MOVD		ECX,mm5
		AND		ECX,BYTE 7
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdDXZ
		@FDegB
		DEC		ECX
		MOV		AL,[EBX+EAX]
		STOSB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;********************************************************
%macro	@ClipFDegTextHLineDYZ 0
		SUB		EBP,[XT1]
		MOV		EAX,EBP
		SHL 		EAX,Prec
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusY
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusY
%%PDivPPlusY:	XOR		EAX,EAX
%%DivPPlusY:
		MOV		EBP,EAX  ;[PntPlusX]
		MOV		ESI,[YT1]
		MOV		EDX,[Plus]
		IMUL		ESI,[SResH]
		NEG		ESI
		IMUL		EDX,EBP ;+[PntPlusX]
		ADD		ESI,[XT1]
		ADD		ESI,[Svlfb]
		OR		EAX,EAX			; SAR
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:
%%BcStBAv:	TEST		EDI,7
		JZ		%%FPasStBAv
		@AjAdDYZ
		ADD		EDX,EBP
		@FDegB
		DEC		ECX
		MOV		AL,[EBX+EAX]
		STOSB
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		TEST		ECX,0xfffffff8
		JZ		%%StBAp
%%PasStDAv:
		MOVD		mm5,ECX
		SHR		ECX,3
;ALIGN 4
%%StoMMX:	MOVD		mm1,EDI
		@AjAdDYZ
		MOVD		mm4,ECX ; save ECX
		@FDegB
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		CL,[EBX+EAX]  ; byte 0
		@AjAdDYZ
		@FDegB
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		CH,[EBX+EAX]  ; byte 1
		@AjAdDYZ
                BSWAP           ECX ; reverse ECX bytes order
		@FDegB
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		CH,[EBX+EAX]  ; byte 2
		@AjAdDYZ
		@FDegB
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		CL,[EBX+EAX]  ; byte 3
		@AjAdDYZ
                BSWAP           ECX ; restore ECX bytes order
                MOVD            mm0, ECX
		@FDegB
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		CL,[EBX+EAX]  ; byte 4
		@AjAdDYZ
		@FDegB
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		CH,[EBX+EAX]  ; byte 5
		@AjAdDYZ
                BSWAP           ECX ; reverse ECX bytes order
		@FDegB
		ADD		EDX,EBP ;+[PntPlusX]
		MOV		CH,[EBX+EAX]  ; byte 6
		@AjAdDYZ
		@FDegB
		MOV		CL,[EBX+EAX]  ; byte 7
		ADD		EDX,EBP ;+[PntPlusX]
                BSWAP           ECX ; restore ECX bytes order
                MOVD            mm2,ECX
                MOVD		EDI,mm1  ; restore EDI
		PUNPCKLDQ	mm0,mm2
		MOVD		ECX,mm4  ; restore ECX
		MOVQ		[EDI],mm0
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX

		MOVD		ECX,mm5
		AND		ECX,BYTE 7
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		@FDegB
		DEC		ECX
		MOV		AL,[EBX+EAX]
		STOSB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro


;**IN*MASK_FLAT_DEG_TEXTure Horizontal Line*********************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2), mm3 =Ptr_TbDegCol+Col
; a ne pas utiliser mm6 & mm7
; utilise mm5,mm2,mm1,mm0
;***************************************************************************
%macro	@InMASKFDegTextHLine  0
		MOV		EAX,[YT2]
		MOV		EBP,[XT2]
		SUB		EAX,[YT1]   ; EAX = DY
		MOVD		mm5,[PtrTbDegCol]
		JZ		%%CasDYZ
		SUB		EBP,[XT1]   ; EBP = DX
		JZ		%%CasDXZ
%%CasNorm:	@InMASKFDegTextHLineNorm
		JMP		%%FinInTextHLg
%%CasDXZ:	@InMASKFDegTextHLineDXZ
		JMP		%%FinInTextHLg
%%CasDYZ:	@InMASKFDegTextHLineDYZ
%%FinInTextHLg:
%endmacro

%macro	@InMASKFDegTextHLineNorm 0
		MOV		ESI,[YT1]      ; - 1
		SHL 		EAX,Prec
		IMUL		ESI,[SResH]    ; - 2
		OR		ECX,ECX
		JZ		%%PDivPntPY
		CDQ
		IDIV		ECX
		JMP		SHORT %%DivPntPY
%%PDivPntPY:	XOR		EAX,EAX
%%DivPntPY:
		NEG		EAX
		NEG		ESI	       ; - 3
		MOV		[PntPlusY],EAX  ;[PntPlusY]
		ADD		ESI,[XT1]      ; - 4

		MOV		EAX,EBP
		ADD		ESI,[Svlfb]    ; - 5
		SHL		EAX,Prec
		OR		ECX,ECX
		JZ		%%PDivPntPX
		CDQ
		IDIV		ECX
		JMP		SHORT %%DivPntPX
%%PDivPntPX:	XOR		EAX,EAX
%%DivPntPX:
		XOR		EDX,EDX     ; Cpt Dbr X
		INC		ECX
		MOV		[PntPlusX],EAX
		;--- ajuste Cpt Dbrd X et Y pour SAR
		OR		EAX,EAX
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:	MOV		EAX,[PntPlusY]
		XOR		EBP,EBP     ; Cpt Dbr Y
		OR		EAX,EAX
		JGE		%%PosPntPlusY
		LEA		EBP,[EBP+((1<<Prec)-1)] ; EBP += 2**N-1
%%PosPntPlusY:  ;-----------------------------------
%%BcStBAp:	@AjAdNormB
		@MASKFDegB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

%macro @MASKFDegB 0
		XOR		EAX,EAX
		OR		AL,BYTE [ESI+EBX]
		JZ		%%PasDr
		SHL		EAX,6
		MOVD		EBX,mm5 ; Ptr TbDegCol
		MOV		AL,[EBX+EAX]
		MOV		[EDI],AL
%%PasDr:	DEC		ECX
		LEA		EDI,[EDI+1]
%endmacro

;********************************************************
%macro	@InMASKFDegTextHLineDXZ  0
		MOV		ESI,[YT1]    ; - 1
		SHL		EAX,Prec
		IMUL		ESI,[SResH]  ; - 2
		OR		ECX,ECX
		JZ		%%PDivPntPX
		CDQ
		IDIV		ECX
		JMP		SHORT %%DivPntPX
%%PDivPntPX:	XOR		EAX,EAX
%%DivPntPX:
		NEG		ESI	     ; - 3
		MOV		EBP,EAX ; [PntPlusY]
		INC		ECX
		ADD		ESI,[XT1]    ; - 4
		XOR		EDX,EDX      ; Cpt Dbrd Y
		OR		EAX,EAX 	      ;--- SAR
		JLE		%%PosPntPlusY
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusY:
		ADD		ESI,[Svlfb]  ; - 5
;ALIGN 4
%%BcStBAp:	@AjAdDXZ
		@MASKFDegB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;********************************************************
%macro	@InMASKFDegTextHLineDYZ 0
		MOV		ESI,[YT1]   ; - 1
		SUB		EBP,[XT1]
		IMUL		ESI,[SResH] ; - 2
		MOV		EAX,EBP
		NEG		ESI	    ; - 3
		SHL 		EAX,Prec
		ADD		ESI,[XT1]   ; - 4
		OR		ECX,ECX
		JZ		%%PDivPntPX
		CDQ
		IDIV		ECX
		JMP		SHORT %%DivPntPX
%%PDivPntPX:	XOR		EAX,EAX
%%DivPntPX:
		ADD		ESI,[Svlfb] ; - 5
		XOR		EDX,EDX  ;Cpt Dbrd X
		INC		ECX
		MOV		EBP,EAX  ;[PntPlusX]
		OR		EAX,EAX			; SAR
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:
%%BcStBAp:	@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		@MASKFDegB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;**Clip*MASK_FLAT_DEG_TEXTure Horizontal Line************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2)
; a ne pas utiliser mm6 & mm7
;***************************************************************************
%macro	@ClipMASKFDegTextHLine  0
		MOV		EAX,[YT2]
		MOV		EBP,[XT2]
		SUB		EAX,[YT1]   ; EAX = DY
		MOVD		mm5,[PtrTbDegCol]
		JZ		%%CasDYZ
		SUB		EBP,[XT1]   ; EBP = DX
		JZ		%%CasDXZ
%%CasNorm:	@ClipMASKFDegTextHLineNorm
		JMP		%%FinInTextHLg
%%CasDXZ:	@ClipMASKFDegTextHLineDXZ
		JMP		%%FinInTextHLg
%%CasDYZ:	@ClipMASKFDegTextHLineDYZ
%%FinInTextHLg:
%endmacro

%macro	@ClipMASKFDegTextHLineNorm 0
		MOV		ESI,[YT1]      ; - 1'
		SHL 		EAX,Prec
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusY
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusY
%%PDivPPlusY:	XOR		EAX,EAX
%%DivPPlusY:
		IMUL		ESI,[SResH]    ; - 2'
		NEG		EAX
		MOV		[PntPlusY],EAX  ;[PntPlusY]

		NEG		ESI	       ; - 3'
		MOV		EAX,EBP
		ADD		ESI,[XT1]      ; - 4'
		SHL		EAX,Prec
		ADD		ESI,[Svlfb]    ; - 5'
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusX
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusX
%%PDivPPlusX:	XOR		EAX,EAX
%%DivPPlusX:
		MOV		EBP,[PntPlusY] ; - 1
		MOV		EBX,[Plus]
		MOV		[PntPlusX],EAX
		MOV 		EDX,[PntPlusX] ; - 2
		IMUL		EBP,EBX	       ; - 3
		IMUL		EDX,EBX        ; - 4
		;--- ajuste Cpt Dbrd X et Y pour SAR
		MOV		EAX,[PntPlusY]
		OR		EAX,EAX
		JGE		%%PosPntPlusY
		LEA		EBP,[EBP+((1<<Prec)-1)] ; EBP += 2**N-1
%%PosPntPlusY:
		MOV		EAX,[PntPlusX]
		OR		EAX,EAX
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:	;-----------------------------------
;ALIGN 4
%%BcStBAp:	@AjAdNormB
		@MASKFDegB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;*******************************************************************
%macro	@ClipMASKFDegTextHLineDXZ  0
		MOV		ESI,[YT1]   ; - 1
		SHL		EAX,Prec
		IMUL		ESI,[SResH] ; - 2
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusX
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusX
%%PDivPPlusX:	XOR		EAX,EAX
%%DivPPlusX:
		NEG		ESI	    ; - 3
		MOV		EBP,EAX ; [PntPlusY]
		ADD		ESI,[XT1]   ; - 4
		MOV		EDX,[Plus]
		ADD		ESI,[Svlfb] ; - 5
		NEG		EDX
		IMUL		EDX,EBP ;-[PntPlusY] axe Y montant
		OR		EAX,EAX 	      ;--- SAR
		JLE		%%PosPntPlusY
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusY:
;ALIGN 4
%%BcStBAp:	@AjAdDXZ
		@MASKFDegB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;********************************************************
%macro	@ClipMASKFDegTextHLineDYZ 0
		SUB		EBP,[XT1]
		MOV		EAX,EBP
		SHL 		EAX,Prec
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusX
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusX
%%PDivPPlusX:	XOR		EAX,EAX
%%DivPPlusX:
		MOV		EBP,EAX  ;[PntPlusX]
		MOV		ESI,[YT1]
		MOV		EDX,[Plus]
		IMUL		ESI,[SResH]
		NEG		ESI
		IMUL		EDX,EBP ;+[PntPlusX]
		ADD		ESI,[XT1]
		ADD		ESI,[Svlfb]
		OR		EAX,EAX			; SAR
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:
;ALIGN 4
%%BcStBAp:	@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		@MASKFDegB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;****** DEG_TEXT

;**IN*DEG_TEXTure Horizontal Line*******************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2), mm3 =Ptr_TbDegCol+Col
; a ne pas utiliser mm6 & mm7
; utilise mm5,mm2,mm1,mm0
;***************************************************************************
%macro	@InDegTextHLine  0
		MOV		EAX,[YT2]
		MOV		EBP,[XT2]
		SUB		EAX,[YT1]   ; EAX = DY
		JZ		%%CasDYZ
		SUB		EBP,[XT1]   ; EBP = DX
		JZ		%%CasDXZ
%%CasNorm:	@InDegTextHLineNorm
		JMP		%%FinInTextHLg
%%CasDXZ:	@InDegTextHLineDXZ
		JMP		%%FinInTextHLg
%%CasDYZ:	@InDegTextHLineDYZ
%%FinInTextHLg:
%endmacro

%macro	@InDegTextHLineNorm 0
		MOV		ESI,[YT1]      ; - 1
		SHL 		EAX,Prec
		IMUL		ESI,[SResH]    ; - 2
		OR		ECX,ECX
		JZ		%%PClcPntY
		CDQ
		IDIV		ECX
		JMP		SHORT %%ClcPntY
%%PClcPntY:	XOR		EAX,EAX
%%ClcPntY:
		NEG		ESI	       ; - 3
		NEG		EAX
		ADD		ESI,[XT1]      ; - 4
		MOV		[PntPlusY],EAX  ;[PntPlusY]

		MOV		EAX,EBP
		ADD		ESI,[Svlfb]    ; - 5
		SHL		EAX,Prec
		OR		ECX,ECX
		JZ		%%PClcPntX
		CDQ
		IDIV		ECX
		JMP		SHORT %%ClcPntX
%%PClcPntX:	XOR		EAX,EAX
%%ClcPntX:
		XOR		EBP,EBP        ; Cpt Dbr Y
		MOV		[PntPlusX],EAX
		
		MOV		EAX,[Col2]
		SUB		EAX,[Col1]
		SHL		EAX,Prec
		OR		ECX,ECX
		JZ		%%PClcPntC
		CDQ
		IDIV		ECX
		JMP		SHORT %%ClcPntC
%%PClcPntC:	XOR		EAX,EAX
%%ClcPntC:
		MOVD		mm5,[Col1]
		MOVD		mm2,EAX
		INC		ECX
		XOR		EDX,EDX     ; Cpt Dbr X
		PSLLQ		mm5,Prec
		;--- ajuste Cpt Dbrd X et Y pour SAR
		MOV		EAX,[PntPlusY]
		OR		EAX,EAX
		JGE		%%PosPntPlusY
		LEA		EBP,[EBP+((1<<Prec)-1)] ; EBP += 2**N-1
%%PosPntPlusY:
		MOV		EAX,[PntPlusX]
		OR		EAX,EAX
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:	;-----------------------------------
%%BcStBAv:	TEST		EDI,7
		JZ		%%FPasStBAv
		@AjAdNormB
		@DegB
		MOV		AL,[EAX+EBX+_TbDegCol]
		DEC		ECX
		STOSB
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		TEST		ECX,0xfffffff8
		JZ		%%StBAp
%%PasStDAv:
		MOVD		mm4,ECX
		SHR		ECX,3
;ALIGN 4
%%StoMMX:
		@AjAdNormB
                MOVD		mm1,ECX  ; save ECX
		@DegB
		MOV		CL,[EAX+EBX+_TbDegCol]  ; byte 0
		@AjAdNormB
		@DegB
		MOV		CH,[EAX+EBX+_TbDegCol]  ; byte 1
		@AjAdNormB
                BSWAP           ECX  ; Swap ECX bytes order
		@DegB
		MOV		CH,[EAX+EBX+_TbDegCol]  ; byte 2
		@AjAdNormB
		@DegB
		MOV		CL,[EAX+EBX+_TbDegCol]  ; byte 3
		@AjAdNormB
                BSWAP           ECX ; restore ECX bytes order
                MOVD            mm0,ECX
		@DegB
		MOV		CL,[EAX+EBX+_TbDegCol]  ; byte 4
		@AjAdNormB
		@DegB
		MOV		CH,[EAX+EBX+_TbDegCol]  ; byte 5
		@AjAdNormB
                BSWAP           ECX  ; Swap ECX bytes order
		@DegB
		MOV		CH,[EAX+EBX+_TbDegCol]  ; byte 6
		@AjAdNormB
		@DegB
		MOV		CL,[EAX+EBX+_TbDegCol]  ; byte 6
                BSWAP           ECX ; restore ECX bytes order
                MOVD            mm3,ECX  ; second 4 bytes to write
                PUNPCKLDQ	mm0,mm3  ; 8 bytes to write

                MOVD		ECX,mm1  ; restore ECX
		MOVQ		[EDI],mm0
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX

		MOVD		ECX,mm4
		AND		ECX,BYTE 7
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdNormB
		@DegB
		MOV		AL,[EAX+EBX+_TbDegCol]

		DEC		ECX
		STOSB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

%macro @DegB 0  ; byte dans AL
                XOR             EAX,EAX
		MOV		AL,BYTE [ESI+EBX]
		MOVD		EBX,mm5
		SAR		EBX,Prec
		SHL		EAX,6
		PADDD		mm5,mm2
%endmacro

;********************************************************

%macro	@InDegTextHLineDXZ  0
		MOV		ESI,[YT1]    ; - 1
		SHL		EAX,Prec
		IMUL		ESI,[SResH]  ; - 2
		OR		ECX,ECX
		JZ		%%PClcPntY
		CDQ
		IDIV		ECX
		JMP		SHORT %%ClcPntY
%%PClcPntY:	XOR		EAX,EAX
%%ClcPntY:
		NEG		ESI	     ; - 3
		MOV		EBP,EAX ; [PntPlusY]
		ADD		ESI,[XT1]    ; - 4
		ADD		ESI,[Svlfb]  ; - 5
		MOV		EAX,[Col2]
		SUB		EAX,[Col1]
		SHL		EAX,Prec
		OR		ECX,ECX
		JZ		%%PClcPntC
		CDQ
		IDIV		ECX
		JMP		SHORT %%ClcPntC
%%PClcPntC:	XOR		EAX,EAX
%%ClcPntC:
		MOVD		mm5,[Col1]
		INC		ECX
		MOVD		mm2,EAX
		XOR		EDX,EDX ; Cpt Dbrd Y
		PSLLQ		mm5,Prec
		OR		EBP,EBP ;--- SAR
		JLE		%%PosPntPlusY
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusY:
%%BcStBAv:	TEST		EDI,7
		JZ		%%FPasStBAv
		@AjAdDXZ
		@DegB
		MOV		AL,[EAX+EBX+_TbDegCol]
		DEC		ECX
		STOSB
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		TEST		ECX,0xfffffff8
		JZ		%%StBAp
%%PasStDAv:
		MOVD		mm4,ECX
		SHR		ECX,3
;ALIGN 4
%%StoMMX:       MOVD		mm1,ECX  ; save ECX
		@AjAdDXZ
		@DegB
		MOV		CL,[EAX+EBX+_TbDegCol]
		@AjAdDXZ
		@DegB
		MOV		CH,[EAX+EBX+_TbDegCol]
		@AjAdDXZ
                BSWAP           ECX
		@DegB
		MOV		CH,[EAX+EBX+_TbDegCol]
		@AjAdDXZ
		@DegB
		MOV		CL,[EAX+EBX+_TbDegCol]
		@AjAdDXZ
                BSWAP           ECX
                MOVD            mm0,ECX
		@DegB
		MOV		CL,[EAX+EBX+_TbDegCol]
		@AjAdDXZ
		@DegB
		MOV		CH,[EAX+EBX+_TbDegCol]
		@AjAdDXZ
                BSWAP           ECX
		@DegB
		MOV		CH,[EAX+EBX+_TbDegCol]
		@AjAdDXZ
		@DegB
		MOV		CL,[EAX+EBX+_TbDegCol]
                BSWAP           ECX
                MOVD            mm3,ECX
                PUNPCKLDQ	mm0,mm3  ; 8 bytes to write
                MOVD		ECX,mm1  ; restore ECX
		MOVQ		[EDI],mm0
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX

		MOVD		ECX,mm4
		AND		ECX,BYTE 7
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdDXZ
		@DegB
		MOV		AL,[EAX+EBX+_TbDegCol]
		DEC		ECX
		STOSB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;********************************************************

%macro	@InDegTextHLineDYZ 0
		SUB		EBP,[XT1]
		MOV		ESI,[YT1]   ; - 1
		MOV		EAX,EBP
		IMUL		ESI,[SResH] ; - 2
		SHL 		EAX,Prec
		NEG		ESI	    ; - 3
		OR		ECX,ECX
		JZ		%%PClcPntX
		CDQ
		IDIV		ECX
		JMP		SHORT %%ClcPntX
%%PClcPntX:	XOR		EAX,EAX
%%ClcPntX:
		ADD		ESI,[XT1]   ; - 4
		ADD		ESI,[Svlfb] ; - 5
		MOV		EBP,EAX  ;[PntPlusX]
		MOV		EAX,[Col2]
		SUB		EAX,[Col1]
		SHL		EAX,Prec
		OR		ECX,ECX
		JZ		%%PClcPntC
		CDQ
		IDIV		ECX
		JMP		SHORT %%ClcPntC
%%PClcPntC:	XOR		EAX,EAX
%%ClcPntC:
		MOVD		mm5,[Col1]
		INC		ECX
		MOVD		mm2,EAX
		XOR		EDX,EDX  ;Cpt Dbrd X
		PSLLQ		mm5,Prec
		OR		EBP,EBP			; SAR
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:
%%BcStBAv:	TEST		EDI,7
		JZ		%%FPasStBAv
		@AjAdDYZ
		ADD		EDX,EBP
		@DegB
		MOV		AL,[EAX+EBX+_TbDegCol]
		DEC		ECX
		STOSB
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		TEST		ECX,0xfffffff8
		JZ		%%StBAp
%%PasStDAv:
		MOVD		mm4,ECX
		SHR		ECX,3
;ALIGN 4
%%StoMMX:
		MOVD		mm1,ECX
		@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		@DegB
		MOV		CL,[EAX+EBX+_TbDegCol]  ; byte 0
		@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		@DegB
		MOV		CH,[EAX+EBX+_TbDegCol]  ; byte 1
		@AjAdDYZ
                BSWAP           ECX  ; reverse ECX bytes order
		ADD		EDX,EBP ;+[PntPlusX]
		@DegB
		MOV		CH,[EAX+EBX+_TbDegCol]  ; byte 2
		@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		@DegB
		MOV		CL,[EAX+EBX+_TbDegCol]  ; byte 3
                
		@AjAdDYZ
                BSWAP           ECX  ; restore ECX bytes order
		ADD		EDX,EBP ;+[PntPlusX]
                MOVD            mm0,ECX ; first 4 bytes to write
		@DegB
		MOV		CL,[EAX+EBX+_TbDegCol]  ; byte 4
		@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		@DegB
		MOV		CH,[EAX+EBX+_TbDegCol]  ; byte 5
		@AjAdDYZ
                BSWAP           ECX  ; reverse ECX bytes order
		ADD		EDX,EBP ;+[PntPlusX]
		@DegB
		MOV		CH,[EAX+EBX+_TbDegCol]  ; byte 6
		@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		@DegB
		MOV		CL,[EAX+EBX+_TbDegCol]  ; byte 7

                BSWAP           ECX  ; restore ECX bytes order
                MOVD            mm3,ECX  ; second 4 bytes to write
                PUNPCKLDQ	mm0,mm3  ; 8 bytes to write
		
                MOVD		ECX,mm1  ; restore ECX
		MOVQ		[EDI],mm0
		DEC		ECX
		LEA		EDI,[EDI+8]
                
                JNZ		%%StoMMX

		MOVD		ECX,mm4
		AND		ECX,BYTE 7
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		@DegB
		MOV		AL,[EAX+EBX+_TbDegCol]
		DEC		ECX
		STOSB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro


;**Clip*DEG_TEXTure Horizontal Line************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2)
; a ne pas utiliser mm6 & mm7
;***************************************************************************
%macro	@ClipDegTextHLine  0
		MOV		EAX,[YT2]
		MOV		EBP,[XT2]
		SUB		EAX,[YT1]   ; EAX = DY
		JZ		%%CasDYZ
		SUB		EBP,[XT1]   ; EBP = DX
		JZ		%%CasDXZ
%%CasNorm:	@ClipDegTextHLineNorm
		JMP		%%FinInTextHLg
%%CasDXZ:	@ClipDegTextHLineDXZ
		JMP		%%FinInTextHLg
%%CasDYZ:	@ClipDegTextHLineDYZ
%%FinInTextHLg:
%endmacro

%macro	@ClipDegTextHLineNorm 0
		SHL 		EAX,Prec
		MOV		ESI,[YT1]      ; - 1'
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusY
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusY
%%PDivPPlusY:	XOR		EAX,EAX
%%DivPPlusY:
		IMUL		ESI,[SResH]    ; - 2'
		NEG		EAX
		MOV		[PntPlusY],EAX  ;[PntPlusY]

		MOV		EAX,EBP
		NEG		ESI	       ; - 3'
		SHL		EAX,Prec
		ADD		ESI,[XT1]      ; - 4'
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusX
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusX
%%PDivPPlusX:	XOR		EAX,EAX
%%DivPPlusX:
		ADD		ESI,[Svlfb]    ; - 5'
		MOV		EBP,[PntPlusY] ; - 1
		MOV		EBX,[Plus]
		MOV		[PntPlusX],EAX

		MOV		EAX,[Col2]
		SUB		EAX,[Col1]
		SHL		EAX,Prec
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusC
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusC
%%PDivPPlusC:	XOR		EAX,EAX
%%DivPPlusC:
		MOVD		mm2,EAX

		MOV		EDX,EAX
		MOV		EAX,[Col1]
		IMUL		EDX,EBX
		SHL		EAX,Prec
		ADD		EAX,EDX
		MOVD		mm5,EAX

		MOV 		EDX,[PntPlusX] ; - 2
		IMUL		EBP,EBX	       ; - 3
		IMUL		EDX,EBX        ; - 4
		;--- ajuste Cpt Dbrd X et Y pour SAR
		MOV		EAX,[PntPlusY]
		OR		EAX,EAX
		JGE		%%PosPntPlusY
		LEA		EBP,[EBP+((1<<Prec)-1)] ; EBP += 2**N-1
%%PosPntPlusY:
		MOV		EAX,[PntPlusX]
		OR		EAX,EAX
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:	;-----------------------------------
%%BcStBAv:	TEST		EDI,7
		JZ		%%FPasStBAv
		@AjAdNormB
		@DegB
		MOV		AL,[EAX+EBX+_TbDegCol]
		DEC		ECX
		STOSB
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		TEST		ECX,0xfffffff8
		JZ		%%StBAp
%%PasStDAv:
		MOVD		mm4,ECX
		SHR		ECX,3
;ALIGN 4
%%StoMMX:
		@AjAdNormB
                MOVD		mm1,ECX  ; save ECX
		@DegB
		MOV		CL,[EAX+EBX+_TbDegCol]  ; byte 0
		@AjAdNormB
		@DegB
		MOV		CH,[EAX+EBX+_TbDegCol]  ; byte 1
		@AjAdNormB
                BSWAP           ECX  ; Swap ECX bytes order
		@DegB
		MOV		CH,[EAX+EBX+_TbDegCol]  ; byte 2
		@AjAdNormB
		@DegB
		MOV		CL,[EAX+EBX+_TbDegCol]  ; byte 3
		@AjAdNormB
                BSWAP           ECX ; restore ECX bytes order
                MOVD            mm0,ECX
		@DegB
		MOV		CL,[EAX+EBX+_TbDegCol]  ; byte 4
		@AjAdNormB
		@DegB
		MOV		CH,[EAX+EBX+_TbDegCol]  ; byte 5
		@AjAdNormB
                BSWAP           ECX  ; Swap ECX bytes order
		@DegB
		MOV		CH,[EAX+EBX+_TbDegCol]  ; byte 6
		@AjAdNormB
		@DegB
		MOV		CL,[EAX+EBX+_TbDegCol]  ; byte 6
                BSWAP           ECX ; restore ECX bytes order
                MOVD            mm3,ECX  ; second 4 bytes to write
                PUNPCKLDQ	mm0,mm3  ; 8 bytes to write

                MOVD		ECX,mm1  ; restore ECX
		MOVQ		[EDI],mm0
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX
		
		MOVD		ECX,mm4
		AND		ECX,BYTE 7
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdNormB
		@DegB
		MOV		AL,[EAX+EBX+_TbDegCol]
		DEC		ECX
		STOSB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;*******************************************************************
%macro	@ClipDegTextHLineDXZ  0
		SHL		EAX,Prec
		MOV		ESI,[YT1]   ; - 1
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusY
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusY
%%PDivPPlusY:	XOR		EAX,EAX
%%DivPPlusY:
		IMUL		ESI,[SResH] ; - 2
		NEG		ESI	    ; - 3
		MOV		EBP,EAX ; [PntPlusY]
		ADD		ESI,[XT1]   ; - 4
		MOV		EBX,[Plus]
		ADD		ESI,[Svlfb] ; - 5

		MOV		EAX,[Col2]
		SUB		EAX,[Col1]
		SHL		EAX,Prec
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusC
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusC
%%PDivPPlusC:	XOR		EAX,EAX
%%DivPPlusC:
		MOVD		mm2,EAX
		MOV		EDX,EAX
		MOV		EAX,[Col1]
		IMUL		EDX,EBX
		SHL		EAX,Prec
		NEG		EBX
		ADD		EAX,EDX
		IMUL		EBX,EBP ;-[PntPlusY] axe Y montant
		MOVD		mm5,EAX
		MOV		EDX,EBX
		OR		EBP,EBP 	      ;--- SAR
		JLE		%%PosPntPlusY
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusY:
%%BcStBAv:	TEST		EDI,7
		JZ		%%FPasStBAv
		@AjAdDXZ
		@DegB
		MOV		AL,[EAX+EBX+_TbDegCol]
		DEC		ECX
		STOSB
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		TEST		ECX,0xfffffff8
		JZ		%%StBAp
%%PasStDAv:
		MOVD		mm4,ECX
		SHR		ECX,3
;ALIGN 4
%%StoMMX:       MOVD		mm1,ECX  ; save ECX
		@AjAdDXZ
		@DegB
		MOV		CL,[EAX+EBX+_TbDegCol]
		@AjAdDXZ
		@DegB
		MOV		CH,[EAX+EBX+_TbDegCol]
		@AjAdDXZ
                BSWAP           ECX
		@DegB
		MOV		CH,[EAX+EBX+_TbDegCol]
		@AjAdDXZ
		@DegB
		MOV		CL,[EAX+EBX+_TbDegCol]
		@AjAdDXZ
                BSWAP           ECX
                MOVD            mm0,ECX
		@DegB
		MOV		CL,[EAX+EBX+_TbDegCol]
		@AjAdDXZ
		@DegB
		MOV		CH,[EAX+EBX+_TbDegCol]
		@AjAdDXZ
                BSWAP           ECX
		@DegB
		MOV		CH,[EAX+EBX+_TbDegCol]
		@AjAdDXZ
		@DegB
		MOV		CL,[EAX+EBX+_TbDegCol]
                BSWAP           ECX
                MOVD            mm3,ECX
                PUNPCKLDQ	mm0,mm3  ; 8 bytes to write
                MOVD		ECX,mm1  ; restore ECX
		MOVQ		[EDI],mm0
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX

		MOVD		ECX,mm4
		AND		ECX,BYTE 7
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdDXZ
		@DegB
		MOV		AL,[EAX+EBX+_TbDegCol]
		DEC		ECX
		STOSB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;********************************************************
%macro	@ClipDegTextHLineDYZ 0
		SUB		EBP,[XT1]
		MOV		EAX,EBP
		SHL 		EAX,Prec
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusX
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusX
%%PDivPPlusX:	XOR		EAX,EAX
%%DivPPlusX:
		MOV		EBP,EAX  ;[PntPlusX]
		MOV		ESI,[YT1]
		MOV		EBX,[Plus]
		IMUL		ESI,[SResH]

		MOV		EAX,[Col2]
		NEG		ESI
		SUB		EAX,[Col1]
		SHL		EAX,Prec
		ADD		ESI,[XT1]
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusC
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusC
%%PDivPPlusC:	XOR		EAX,EAX
%%DivPPlusC:
		ADD		ESI,[Svlfb]
		MOVD		mm2,EAX
		MOV		EDX,EAX
		MOV		EAX,[Col1]
		IMUL		EDX,EBX
		SHL		EAX,Prec
		ADD		EAX,EDX
		IMUL		EBX,EBP ;[PntPlusX] axe Y montant
		MOVD		mm5,EAX
		MOV		EDX,EBX
		OR		EBP,EBP			; SAR
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:
%%BcStBAv:	TEST		EDI,7
		JZ		%%FPasStBAv
		@AjAdDYZ
		ADD		EDX,EBP
		@DegB
		MOV		AL,[EAX+EBX+_TbDegCol]
		DEC		ECX
		STOSB
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		TEST		ECX,0xfffffff8
		JZ		%%StBAp
%%PasStDAv:
		MOVD		mm4,ECX
		SHR		ECX,3
;ALIGN 4
%%StoMMX:       MOVD		mm1,ECX
		@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		@DegB
		MOV		CL,[EAX+EBX+_TbDegCol]  ; byte 0
		@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		@DegB
		MOV		CH,[EAX+EBX+_TbDegCol]  ; byte 1
		@AjAdDYZ
                BSWAP           ECX  ; reverse ECX bytes order
		ADD		EDX,EBP ;+[PntPlusX]
		@DegB
		MOV		CH,[EAX+EBX+_TbDegCol]  ; byte 2
		@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		@DegB
		MOV		CL,[EAX+EBX+_TbDegCol]  ; byte 3
                
		@AjAdDYZ
                BSWAP           ECX  ; restore ECX bytes order
		ADD		EDX,EBP ;+[PntPlusX]
                MOVD            mm0,ECX ; first 4 bytes to write
		@DegB
		MOV		CL,[EAX+EBX+_TbDegCol]  ; byte 4
		@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		@DegB
		MOV		CH,[EAX+EBX+_TbDegCol]  ; byte 5
		@AjAdDYZ
                BSWAP           ECX  ; reverse ECX bytes order
		ADD		EDX,EBP ;+[PntPlusX]
		@DegB
		MOV		CH,[EAX+EBX+_TbDegCol]  ; byte 6
		@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		@DegB
		MOV		CL,[EAX+EBX+_TbDegCol]  ; byte 7

                BSWAP           ECX  ; restore ECX bytes order
                MOVD            mm3,ECX  ; second 4 bytes to write
                PUNPCKLDQ	mm0,mm3  ; 8 bytes to write
		
                MOVD		ECX,mm1  ; restore ECX
		MOVQ		[EDI],mm0
		DEC		ECX
		LEA		EDI,[EDI+8]


;                MOVD		mm1,EDI
;		@AjAdDYZ
;		ADD		EDX,EBP ;+[PntPlusX]
;		MOV		AL,[ESI+EBX]
;		@AjAdDYZ
;		ADD		EDX,EBP ;+[PntPlusX]
;		MOV		AH,[ESI+EBX]
;		MOV		[Temp],AL
;		@AjAdDYZ
;		ADD		EDX,EBP ;+[PntPlusX]
;		MOV		AL,[ESI+EBX]
;		MOV		[Temp+1],AH
;		@AjAdDYZ
;		ADD		EDX,EBP ;+[PntPlusX]
;		MOV		AH,[ESI+EBX]
;		MOV		[Temp+2],AL
;		@AjAdDYZ
;		ADD		EDX,EBP ;+[PntPlusX]
;		MOV		AL,[ESI+EBX]
;		MOV		[Temp+3],AH
;		@AjAdDYZ
;		ADD		EDX,EBP ;+[PntPlusX]
;		MOV		AH,[ESI+EBX]
;		MOV		[Temp+4],AL
;		@AjAdDYZ
;		ADD		EDX,EBP ;+[PntPlusX]
;		MOV		AL,[ESI+EBX]
;		MOV		[Temp+5],AH
;		@AjAdDYZ
;		MOV		[Temp+6],AL
;		MOV		AH,[ESI+EBX]
;		ADD		EDX,EBP ;+[PntPlusX]
;		MOV		[Temp+7],AH
;		@DegQ
;		MOVQ		[EDI],mm0
;		DEC		ECX
;		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX

		MOVD		ECX,mm4
		AND		ECX,BYTE 7
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		@DegB
		MOV		AL,[EAX+EBX+_TbDegCol]
		DEC		ECX
		STOSB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;****** MASK_DEG_TEXT

;**IN*DEG_TEXTure Horizontal Line*******************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2), mm3 =Ptr_TbDegCol+Col
; a ne pas utiliser mm6 & mm7
; utilise mm5,mm2,mm1,mm0
;***************************************************************************
%macro	@InMaskDegTextHLine  0
		MOV		EAX,[YT2]
		MOV		EBP,[XT2]
		SUB		EAX,[YT1]   ; EAX = DY
		JZ		%%CasDYZ
		SUB		EBP,[XT1]   ; EBP = DX
		JZ		%%CasDXZ
%%CasNorm:	@InMaskDegTextHLineNorm
		JMP		%%FinInTextHLg
%%CasDXZ:	@InMaskDegTextHLineDXZ
		JMP		%%FinInTextHLg
%%CasDYZ:	@InMaskDegTextHLineDYZ
%%FinInTextHLg:
%endmacro

%macro	@InMaskDegTextHLineNorm 0
		MOV		ESI,[YT1]      ; - 1
		SHL 		EAX,Prec
		OR		ECX,ECX
		JZ		%%PClcPntY
		CDQ
		IDIV		ECX
		JMP		SHORT %%ClcPntY
%%PClcPntY:	XOR		EAX,EAX
%%ClcPntY:
		IMUL		ESI,[SResH]    ; - 2
		NEG		ESI	       ; - 3
		NEG		EAX
		ADD		ESI,[XT1]      ; - 4
		MOV		[PntPlusY],EAX  ;[PntPlusY]

		MOV		EAX,EBP
		ADD		ESI,[Svlfb]    ; - 5
		SHL		EAX,Prec
		OR		ECX,ECX
		JZ		%%PClcPntX
		CDQ
		IDIV		ECX
		JMP		SHORT %%ClcPntX
%%PClcPntX:	XOR		EAX,EAX
%%ClcPntX:
		XOR		EBP,EBP        ; Cpt Dbr Y
		MOV		[PntPlusX],EAX
		
		MOV		EAX,[Col2]
		SUB		EAX,[Col1]
		SHL		EAX,Prec
		OR		ECX,ECX
		JZ		%%PClcPntC
		CDQ
		IDIV		ECX
		JMP		SHORT %%ClcPntC
%%PClcPntC:	XOR		EAX,EAX
%%ClcPntC:
		MOVD		mm5,[Col1]
		MOVD		mm2,EAX
		INC		ECX
		XOR		EDX,EDX     ; Cpt Dbr X
		PSLLQ		mm5,Prec
		;--- ajuste Cpt Dbrd X et Y pour SAR
		MOV		EAX,[PntPlusY]
		OR		EAX,EAX
		JGE		%%PosPntPlusY
		LEA		EBP,[EBP+((1<<Prec)-1)] ; EBP += 2**N-1
%%PosPntPlusY:
		MOV		EAX,[PntPlusX]
		OR		EAX,EAX
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:	;-----------------------------------
;ALIGN 4
%%BcStBAp:	@AjAdNormB
		@MaskDegB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

%macro @MaskDegB 0
		XOR		EAX,EAX
		OR		AL,[ESI+EBX]
		JZ		%%PasDr
		MOVD		EBX,mm5
		SHL		EAX,6
		SAR		EBX,Prec
		MOV		AL,[EAX+EBX+_TbDegCol]
		MOV		[EDI],AL
%%PasDr:	PADDD		mm5,mm2
		DEC		ECX
		LEA		EDI,[EDI+1]
%endmacro

;********************************************************

%macro	@InMaskDegTextHLineDXZ  0
		MOV		ESI,[YT1]    ; - 1
		SHL		EAX,Prec
		OR		ECX,ECX
		JZ		%%PClcPntY
		CDQ
		IDIV		ECX
		JMP		SHORT %%ClcPntY
%%PClcPntY:	XOR		EAX,EAX
%%ClcPntY:
		IMUL		ESI,[SResH]  ; - 2
		NEG		ESI	     ; - 3
		MOV		EBP,EAX ; [PntPlusY]
		ADD		ESI,[XT1]    ; - 4
		ADD		ESI,[Svlfb]  ; - 5
		MOV		EAX,[Col2]
		SUB		EAX,[Col1]
		SHL		EAX,Prec
		OR		ECX,ECX
		JZ		%%PClcPntC
		CDQ
		IDIV		ECX
		JMP		SHORT %%ClcPntC
%%PClcPntC:	XOR		EAX,EAX
%%ClcPntC:
		MOVD		mm5,[Col1]
		MOVD		mm2,EAX
		INC		ECX
		XOR		EDX,EDX ; Cpt Dbrd Y
		PSLLQ		mm5,Prec
		OR		EBP,EBP 	      ;--- SAR
		JLE		%%PosPntPlusY
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusY:
;ALIGN 4
%%BcStBAp:	@AjAdDXZ
		@MaskDegB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;********************************************************

%macro	@InMaskDegTextHLineDYZ 0
		SUB		EBP,[XT1]
		MOV		ESI,[YT1]   ; - 1
		MOV		EAX,EBP
		IMUL		ESI,[SResH] ; - 2
		SHL 		EAX,Prec
		NEG		ESI	    ; - 3
		OR		ECX,ECX
		JZ		%%PClcPntX
		CDQ
		IDIV		ECX
		JMP		SHORT %%ClcPntX
%%PClcPntX:	XOR		EAX,EAX
%%ClcPntX:
		ADD		ESI,[XT1]   ; - 4
		MOV		EBP,EAX  ;[PntPlusX]
		ADD		ESI,[Svlfb] ; - 5
		MOV		EAX,[Col2]
		SUB		EAX,[Col1]
		SHL		EAX,Prec
		OR		ECX,ECX
		JZ		%%PClcPntC
		CDQ
		IDIV		ECX
		JMP		SHORT %%ClcPntC
%%PClcPntC:	XOR		EAX,EAX
%%ClcPntC:
		MOVD		mm5,[Col1]
		MOVD		mm2,EAX
		INC		ECX
		XOR		EDX,EDX  ;Cpt Dbrd X
		PSLLQ		mm5,Prec
		OR		EBP,EBP			; SAR
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:
;ALIGN 4
%%BcStBAp:	@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		@MaskDegB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro


;**Clip*DEG_TEXTure Horizontal Line************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2)
; a ne pas utiliser mm6 & mm7
;***************************************************************************
%macro	@ClipMaskDegTextHLine  0
		MOV		EAX,[YT2]
		MOV		EBP,[XT2]
		SUB		EAX,[YT1]   ; EAX = DY
		JZ		%%CasDYZ
		SUB		EBP,[XT1]   ; EBP = DX
		JZ		%%CasDXZ
%%CasNorm:	@ClipMaskDegTextHLineNorm
		JMP		%%FinInTextHLg
%%CasDXZ:	@ClipMaskDegTextHLineDXZ
		JMP		%%FinInTextHLg
%%CasDYZ:	@ClipMaskDegTextHLineDYZ
%%FinInTextHLg:
%endmacro

%macro	@ClipMaskDegTextHLineNorm 0
		SHL 		EAX,Prec
		MOV		ESI,[YT1]      ; - 1'
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusY
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusY
%%PDivPPlusY:	XOR		EAX,EAX
%%DivPPlusY:
		IMUL		ESI,[SResH]    ; - 2'
		NEG		EAX
		MOV		[PntPlusY],EAX  ;[PntPlusY]

		MOV		EAX,EBP
		NEG		ESI	       ; - 3'
		SHL		EAX,Prec
		ADD		ESI,[XT1]      ; - 4'
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusX
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusX
%%PDivPPlusX:	XOR		EAX,EAX
%%DivPPlusX:
		ADD		ESI,[Svlfb]    ; - 5'
		MOV		EBP,[PntPlusY] ; - 1
		MOV		EBX,[Plus]
		MOV		[PntPlusX],EAX

		MOV		EAX,[Col2]
		SUB		EAX,[Col1]
		SHL		EAX,Prec
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusC
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusC
%%PDivPPlusC:	XOR		EAX,EAX
%%DivPPlusC:
		MOVD		mm2,EAX

		MOV		EDX,EAX
		MOV		EAX,[Col1]
		IMUL		EDX,EBX
		SHL		EAX,Prec
		ADD		EAX,EDX
		MOVD		mm5,EAX

		MOV 		EDX,[PntPlusX] ; - 2
		IMUL		EBP,EBX	       ; - 3
		IMUL		EDX,EBX        ; - 4
		;--- ajuste Cpt Dbrd X et Y pour SAR
		MOV		EAX,[PntPlusY]
		OR		EAX,EAX
		JGE		%%PosPntPlusY
		LEA		EBP,[EBP+((1<<Prec)-1)] ; EBP += 2**N-1
%%PosPntPlusY:
		MOV		EAX,[PntPlusX]
		OR		EAX,EAX
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:	;-----------------------------------
;ALIGN 4
%%BcStBAp:	@AjAdNormB
		@MaskDegB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;*******************************************************************
%macro	@ClipMaskDegTextHLineDXZ  0
		SHL		EAX,Prec
		MOV		ESI,[YT1]   ; - 1
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusY
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusY
%%PDivPPlusY:	XOR		EAX,EAX
%%DivPPlusY:
		IMUL		ESI,[SResH] ; - 2
		NEG		ESI	    ; - 3
		MOV		EBP,EAX ; [PntPlusY]
		ADD		ESI,[XT1]   ; - 4
		MOV		EBX,[Plus]
		ADD		ESI,[Svlfb] ; - 5

		MOV		EAX,[Col2]
		SUB		EAX,[Col1]
		SHL		EAX,Prec
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusC
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusC
%%PDivPPlusC:	XOR		EAX,EAX
%%DivPPlusC:
		MOVD		mm2,EAX
		MOV		EDX,EAX
		MOV		EAX,[Col1]
		IMUL		EDX,EBX
		SHL		EAX,Prec
		NEG		EBX
		ADD		EAX,EDX
		IMUL		EBX,EBP ;-[PntPlusY] axe Y montant
		MOVD		mm5,EAX
		MOV		EDX,EBX
		MOVD		EAX,mm2
		OR		EBP,EBP 	      ;--- SAR
		JLE		%%PosPntPlusY
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusY:
;ALIGN 4
%%BcStBAp:	@AjAdDXZ
		@MaskDegB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;********************************************************
%macro	@ClipMaskDegTextHLineDYZ 0
		SUB		EBP,[XT1]
		MOV		EAX,EBP
		SHL 		EAX,Prec
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusX
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusX
%%PDivPPlusX:	XOR		EAX,EAX
%%DivPPlusX:
		MOV		EBP,EAX  ;[PntPlusX]
		MOV		ESI,[YT1]
		MOV		EBX,[Plus]
		IMUL		ESI,[SResH]
		NEG		ESI

		MOV		EAX,[Col2]
		SUB		EAX,[Col1]
		SHL		EAX,Prec
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusC
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusC
%%PDivPPlusC:	XOR		EAX,EAX
%%DivPPlusC:
		MOVD		mm2,EAX
		MOV		EDX,EAX
		MOV		EAX,[Col1]
		IMUL		EDX,EBX
		SHL		EAX,Prec
		ADD		EAX,EDX
		IMUL		EBX,EBP ;[PntPlusX] axe Y montant
		MOVD		mm5,EAX
		MOV		EDX,EBX
		
		ADD		ESI,[XT1]
		ADD		ESI,[Svlfb]
		OR		EBP,EBP			; SAR
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:
;ALIGN 4
%%BcStBAp:	@AjAdDYZ
		ADD		EDX,EBP ;+[PntPlusX]
		@MaskDegB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro


;***** EFF_FDEG
;***************************************************************************
; IN : ECX long, EDI Dest, mm5 Ptr TbDegCol+FDEG,
;***************************************************************************
%macro	@EFF_FDEGHLine 0
		MOVD		EBX,mm5
%%BcStBAv:	TEST		EDI,7
		JZ		%%FPasStBAv
		MOVZX		EDX,BYTE [EDI]
		SHL		EDX,6
		MOV		AL,[EDX+EBX]
		DEC		ECX
		STOSB
		JZ		%%FinSHLine
		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		TEST		ECX,0xfffffff8
		JZ		%%StBAp
%%PasStDAv:
		PUSH		ECX
		SHR		ECX,3
;ALIGN 4
%%StoMMX:
		MOVQ		mm0,[EDI]
		MOVD		EAX,mm0
		SHLD		EDX,EAX,16
		PSRLQ		mm0,32
		@EFF_FDegD
		MOVD		mm1,EAX
		MOVD		EAX,mm0
		SHLD		EDX,EAX,16
		@EFF_FDegD
		MOVD		mm2,EAX
		PUNPCKLDQ	mm1,mm2

		MOVQ		[EDI],mm1
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX

		POP		ECX
		AND		ECX,BYTE 7
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:
		MOVZX		EDX,BYTE [EDI]
		SHL		EDX,6
		MOV		AL,[EDX+EBX]
		DEC		ECX
		STOSB
		JNZ		%%BcStBAp
;%%PasStBAp:
%%FinSHLine:
%endmacro

%macro @EFF_FDegD 0	; AL AH DL DH
		MOVZX		ESI,AL
		MOVZX		EBP,DL
		SHL		ESI,6
		SHL		EBP,6
		MOV		AL,[EBX+ESI]
		MOV		DL,[EBX+EBP]
		MOVZX		ESI,AH
		MOVZX		EBP,DH
		SHL		ESI,6
		SHL		EBP,6
		MOV		AH,[EBX+ESI]
		MOV		DH,[EBX+EBP]
		SHL		EAX,16
		SHRD		EAX,EDX,16
%endmacro

;***** EFF_DEG
;***************************************************************************
; IN : ECX long, EDI Dest, EAX Col2, EBP Col1
;***************************************************************************

%macro	@InEFF_DEGHLine 0
		SUB		EAX,EBP
		SHL		EAX,Prec
		OR		ECX,ECX
		JZ		%%PClcPntD
		CDQ
		IDIV		ECX
		JMP		SHORT %%ClcPntD
%%PClcPntD:	XOR		EAX,EAX
%%ClcPntD:
		MOVD		mm2,EAX
		INC		ECX
		MOV		EAX,EBP
		SHL		EAX,Prec
		MOVD		mm5,EAX
%%BcStBAv:	TEST		EDI,7
		JZ		%%FPasStBAv
		@EFF_DEG_B
		DEC		ECX
		STOSB
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		TEST		ECX,0xfffffff8
		JZ		%%StBAp
%%PasStDAv:
		PUSH		ECX
		SHR		ECX,3
;ALIGN 4
%%StoMMX:
		MOVQ		mm0,[EDI]
		MOVD		EAX,mm0
		SHLD		EDX,EAX,16
		PSRLQ		mm0,32
		@EFF_DEG_D
		MOVD		mm1,EAX
		MOVD		EAX,mm0
		SHLD		EDX,EAX,16
		@EFF_DEG_D
		MOVD		mm0,EAX
		PUNPCKLDQ	mm1,mm0
		MOVQ		[EDI],mm1
		
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX
		
		POP		ECX
		AND		ECX,BYTE 7
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@EFF_DEG_B
		DEC		ECX
		STOSB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

%macro @EFF_DEG_B 0
		MOVZX		EBX,BYTE [EDI]
		MOVD		EDX,mm5
		SHL		EBX,6
		SHR		EDX,Prec
		PADDD		mm5,mm2
		MOV		AL,[EBX+EDX+_TbDegCol]
%endmacro

%macro @EFF_DEG_D 0
		@EFF_DEG_BD AL
		@EFF_DEG_BD AH
		@EFF_DEG_BD DL
		@EFF_DEG_BD DH
		SHL		EAX,16
		SHRD		EAX,EDX,16
%endmacro

%macro @EFF_DEG_BD 1
		MOVZX		EBX,%1
		MOVD		ESI,mm5
		SHL		EBX,6
		SHR		ESI,Prec
		PADDD		mm5,mm2
		MOV		%1,[EBX+ESI+_TbDegCol]
%endmacro
		

%macro	@ClipEFF_DEGHLine 0
		SUB		EAX,EBP
		SHL		EAX,Prec
		CMP		DWORD [Plus2],BYTE 0
		JZ		%%PDivPPlusC
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusC
%%PDivPPlusC:	XOR		EAX,EAX
%%DivPPlusC:
		MOV		EBX,[Plus]
		MOVD		mm2,EAX
		IMUL		EBX,EAX

		MOV		EAX,EBP
		SHL		EAX,Prec
		ADD		EAX,EBX
		MOVD		mm5,EAX
%%BcStBAv:	TEST		EDI,7
		JZ		%%FPasStBAv
		@EFF_DEG_B
		DEC		ECX
		STOSB
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		TEST		ECX,0xfffffff8
		JZ		%%StBAp
%%PasStDAv:
		PUSH		ECX
		SHR		ECX,3
;ALIGN 4
%%StoMMX:
		MOVQ		mm0,[EDI]
		MOVD		EAX,mm0
		SHLD		EDX,EAX,16
		PSRLQ		mm0,32
		@EFF_DEG_D
		MOVD		mm1,EAX
		MOVD		EAX,mm0
		SHLD		EDX,EAX,16
		@EFF_DEG_D
		MOVD		mm0,EAX
		PUNPCKLDQ	mm1,mm0
		MOVQ		[EDI],mm1
		
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX
		
		POP		ECX
		AND		ECX,BYTE 7
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@EFF_DEG_B
		DEC		ECX
		STOSB
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;***** EFF_FDEG
;***************************************************************************
; IN : ECX long, EDI Dest, mm5 PtrTbColConv
;***************************************************************************
%macro	@EFF_COLCONVHLine 0
		MOVD		EBX,mm5
		XOR		EDX,EDX
%%BcStBAv:	TEST		EDI,7
		JZ		%%FPasStBAv
		MOV		DL,[EDI]
		MOV		AL,[EDX+EBX]
		DEC		ECX
		STOSB
		JZ		%%FinSHLine
		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		TEST		ECX,0xfffffff8
		JZ		%%StBAp
%%PasStDAv:
		MOVD		mm3,ECX ; [OLD_ECX]
		SHR		ECX,3
;ALIGN 4
%%StoMMX:
		MOVQ		mm0,[EDI]
		MOVD		EAX,mm0
		SHLD		EDX,EAX,16
		PSRLQ		mm0,32
		@EFF_COLCONVD
		MOVD		mm1,EAX
		MOVD		EAX,mm0
		SHLD		EDX,EAX,16
		@EFF_COLCONVD
		MOVD		mm2,EAX
		PUNPCKLDQ	mm1,mm2

		MOVQ		[EDI],mm1
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX

		MOVD		ECX,mm3 ;[OLD_ECX]
		AND		ECX,BYTE 7
		JZ		%%FinSHLine
%%StBAp:	XOR		EDX,EDX
%%BcStBAp:
		MOV		DL,[EDI]
		MOV		AL,[EDX+EBX]
		DEC		ECX
		STOSB
		JNZ		%%BcStBAp
;%%PasStBAp:
%%FinSHLine:
%endmacro

%macro @EFF_COLCONVD 0	; AL AH DL DH
		MOVZX		ESI,AL
		MOVZX		EBP,DL
		MOV		AL,[EBX+ESI]
		MOV		DL,[EBX+EBP]
		MOVZX		ESI,AH
		MOVZX		EBP,DH
		MOV		AH,[EBX+ESI]
		MOV		DH,[EBX+EBP]
		SHL		EAX,16
		SHRD		EAX,EDX,16
%endmacro

