
;***** SOLID
;***************************************************************************
; IN : EAX col, ESI long, EDI Dest,
; change : mm0, ECX
;***************************************************************************
%macro	@SolidHLine16	0
		TEST		EDI,2
		JZ		SHORT %%FPasStBAv
		DEC		ESI
		MOV		[EDI],AX
		JZ		SHORT %%FinSHLine
		LEA		EDI,[EDI+2]
%%FPasStBAv:
		TEST		EDI,4
		JZ		SHORT %%PasStDAv
		CMP		ESI,BYTE 2
		JL		SHORT %%StBAp
		MOV		[EDI],EAX
		SUB		ESI,BYTE 2
		LEA		EDI,[EDI+4]
%%PasStDAv:
		MOV		ECX,ESI
		SHR		ECX,2
		OR		ECX,ECX
		JZ		SHORT %%StDAp
ALIGN 4
%%StoMMX:	MOVQ		[EDI],mm0
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		SHORT %%StoMMX
		AND		ESI,BYTE 3
		JZ		SHORT %%FinSHLine
%%StDAp: 	CMP		ESI,BYTE 2
		JL		SHORT %%StBAp
		STOSD
%%StBAp:	AND		ESI,BYTE 1
		JZ		SHORT %%PasStBAp
		MOV		[EDI],AX
%%PasStBAp:
%%FinSHLine:
%endmacro

;****** TEXT
;**IN*TEXTure Horizontal Line***********************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2)
; a ne pas utiliser mm6 & mm7
; utilise mm5,mm4,mm3,mm2,mm1,mm0
;***************************************************************************
%macro	@InTextHLine16  0
		MOV		EAX,[YT2]
		MOV		EBP,[XT2]
		SUB		EAX,[YT1]   ; EAX = DY
		JZ		%%CasDYZ
		SUB		EBP,[XT1]   ; EBP = DX
		JZ		%%CasDXZ
%%CasNorm:	@InTextHLineNorm16
		JMP		%%FinInTextHLg
%%CasDXZ:	@InTextHLineDXZ16
		JMP		%%FinInTextHLg
%%CasDYZ:	@InTextHLineDYZ16
%%FinInTextHLg:
%endmacro

; AX : DYT, EBP : DXT

%macro	@InTextHLineNorm16 0
		MOV		ESI,[YT1]      ; - 1
		SHL 		EAX,Prec
		CDQ
		IMUL		ESI,[SScanLine]    ; - 2
		OR		ECX,ECX
		JZ		%%PDivPntPY
		IDIV		ECX
		JMP		SHORT %%DivPntPY
%%PDivPntPY:	XOR		EAX,EAX
%%DivPntPY:
		NEG		ESI	       ; - 3
		NEG		EAX
		ADD		ESI,[XT1]      ; - 4
		MOV		[PntPlusY],EAX  ;[PntPlusY]
		ADD		ESI,[XT1]      ; - 4(2) as 16bpp

		XOR		EDX,EDX
		MOV		EAX,EBP

		OR		EDX,BYTE 8
		ADD		ESI,[Svlfb]    ; - 5
		SHL		EAX,Prec
		MOVD		mm5,EDX
		CDQ
		OR		ECX,ECX
		JZ		%%PDivPntPX
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

		
%%BcStBAv:	TEST		EDI,6
		JZ		%%FPasStBAv
		@AjAdNormB16
		MOV		AX,[EBX+ESI]
		DEC		ECX
		STOSW
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		CMP		ECX,BYTE 3
		JLE		%%StBAp
		MOVD		mm2,ECX  ; save first 3 bits of ECX
		MOVD		mm1,EDI  ; save EDI in mm1
		SHR		ECX,2
;ALIGN 4
%%StoMMX:       @AjAdNormQ16
                MOVD		mm3,ECX   ; save ECX
		MOV		AX,[ESI+EBX] ; read word 0
		@AjAdNormQ16
		ROR		EAX,16 ; move first word to upper EAX word
		MOV		CX,[ESI+EBX] ; read word 1
		@AjAdNormQ16
		ROR		ECX,16
		MOV		AX,[ESI+EBX] ; read word 2
		@AjAdNormQ16
		ROR		EAX,16 ; EAX words on the right order
		MOV		CX,[ESI+EBX] ; read byte 3
		MOVD		EDI,mm1 ; restore EDI
		ROR		ECX,16   ; ; ECX words on the right order
                MOVD            mm0,EAX ; first 4 bytes to write
                MOVD            mm4,ECX ; second 4 byte to write
		PADDD		mm1,mm5    ; EDI += 8
                MOVD		ECX,mm3   ; restore ECX
		PUNPCKLWD	mm0,mm4 ; make the full 8 bytes to write
		DEC		ECX
		MOVQ		[EDI],mm0 ; write the 8 bytes
		JNZ		%%StoMMX

		MOVD		ECX,mm2 ; restore first 3 bits of ECX
		LEA		EDI,[EDI+8]
		AND		ECX,BYTE 3
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdNormB16
		MOV		AX,[ESI+EBX]
		DEC		ECX
		STOSW
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

%macro  @AjAdNormB16 0
		MOV		EBX,EBP
		MOV		EAX,EDX
		SAR		EBX,Prec
		SAR		EAX,Prec
		IMUL		EBX,[SScanLine]
		ADD		EBP,[PntPlusY]
		LEA		EBX,[EBX+EAX*2] ; xt *2 as 16bpp
		ADD		EDX,[PntPlusX]
%endmacro
%macro  @AjAdNormQ16 0
		MOV		EBX,EBP
		MOV		EDI,EDX
		SAR		EBX,Prec
		SAR		EDI,Prec
		IMUL		EBX,[SScanLine]
		ADD		EBP,[PntPlusY]
		ADD		EDX,[PntPlusX]
		LEA		EBX,[EBX+EDI*2]
%endmacro

;********************************************************

%macro	@InTextHLineDXZ16  0
		MOV		ESI,[YT1]    ; - 1
		SHL		EAX,Prec
		CDQ
		IMUL		ESI,[SScanLine]  ; - 2
		OR		ECX,ECX
		JZ		%%PDivPntPX
		IDIV		ECX
		JMP		SHORT %%DivPntPX
%%PDivPntPX:	XOR		EAX,EAX
%%DivPntPX:
		NEG		ESI	     ; - 3
		MOV		EBP,EAX ; [PntPlusY]
		ADD		ESI,[XT1]    ; - 4
		XOR		EBX,EBX      ; Cpt Dbrd Y
		ADD		ESI,[XT1]    ; - 4 (+XT1*2) as 16bpp
		OR		EAX,EAX
		ADD		ESI,[Svlfb]  ; - 5
		SETG		BL
		INC		ECX
		MOV		EDX,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr Y
%%BcStBAv:	TEST		EDI,6
		JZ		%%FPasStBAv
		@AjAdDXZ16
		MOV		AX,[ESI+EBX]
		DEC		ECX
		STOSW
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		CMP		ECX,BYTE 3
		JLE		%%StBAp
%%PasStDAv:
		MOVD		mm2,ECX
		SHR		ECX,2
;ALIGN 4
%%StoMMX:	@AjAdDXZ16
                MOVD            mm3, ECX   ; save ECX
		MOV		AX,[ESI+EBX] ; read word 0
		@AjAdDXZ16
		ROR		EAX,16
		MOV		CX,[ESI+EBX] ; read word 1
		@AjAdDXZ16
		ROR		ECX,16
		MOV		AX,[ESI+EBX] ; read word 2
		@AjAdDXZ16
		MOV		CX,[ESI+EBX] ; read word 3
		ROR		EAX,16 ; EAX right order
		ROR		ECX,16 ; ECX right order
                MOVD            mm0, EAX ; first 4 bytes to write
                MOVD            mm1, ECX ; second 4 bytes to write
		PUNPCKLWD	mm0,mm1 ; make the full 8 bytes to write
                MOVD            ECX, mm3   ; restore ECX
		MOVQ		[EDI],mm0 ; write the 8 bytes
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX

		MOVD		ECX,mm2
		AND		ECX,BYTE 3
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdDXZ
		MOV		AX,[ESI+EBX]
		DEC		ECX
		STOSW
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

%macro  @AjAdDXZ16  0
		MOV		EBX,EDX
		SAR		EBX,Prec
		SUB		EDX,EBP ;-[PntPlusY]
		IMUL		EBX,[SScanLine]
%endmacro
;********************************************************

%macro	@InTextHLineDYZ16 0
		SUB		EBP,[XT1]
		MOV		ESI,[YT1]   ; - 1
		MOV		EAX,EBP
		IMUL		ESI,[SScanLine] ; - 2
		SHL 		EAX,Prec
		NEG		ESI	    ; - 3
		CDQ
		ADD		ESI,[XT1]   ; - 4
		ADD		ESI,[XT1]   ; - 4 + (XT1*2) as 16bpp
		OR		ECX,ECX
		JZ		%%PDivPntPX
		IDIV		ECX
		JMP		SHORT %%DivPntPX
%%PDivPntPX:	XOR		EAX,EAX
%%DivPntPX:
		XOR		EBX,EBX      ; Cpt Dbrd Y
		ADD		ESI,[Svlfb] ; - 5
		OR		EAX,EAX			; SAR
		MOV		EBP,EAX  ;[PntPlusX]
		SETL		BL
		INC		ECX
		MOV		EDX,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr Y
%%BcStBAv:	TEST		EDI,6
		JZ		%%FPasStBAv
		@AjAdDYZ16
		MOV		AX,[ESI+EBX*2]
		DEC		ECX
		STOSW
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		CMP		ECX,BYTE 3
		JLE		%%StBAp
%%PasStDAv:
		MOVD		mm2,ECX
		SHR		ECX,2
;ALIGN 4
%%StoMMX:	@AjAdDYZ16
		MOVD		mm3,ECX  ; save ECX
		MOV		AX,[ESI+EBX*2] ; read word 0
		@AjAdDYZ16
		ROR		EAX,16
		MOV		CX,[ESI+EBX*2] ; read word 1
		@AjAdDYZ16
		ROR		ECX,16
		MOV		AX,[ESI+EBX*2]  ; read word 2
		@AjAdDYZ16
		MOV		CX,[ESI+EBX*2]  ; read word 3
		ROR		EAX,16 ; right order
		ROR		ECX,16 ; right order
		MOVD		mm0,EAX  ; first 4 bytes to write
		MOVD		mm1,ECX  ; second 4 bytes to write
		PUNPCKLWD	mm0,mm1 ; make the full 8 bytes to write
		MOVD		ECX,mm3  ; restore ECX
		MOVQ		[EDI],mm0 ; write the 8 bytes
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX

		MOVD		ECX,mm2
		AND		ECX,BYTE 3
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdDYZ16
		MOV		AX,[ESI+EBX*2]
		DEC		ECX
		STOSW
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

%macro  @AjAdDYZ16  0
		MOV		EBX,EDX
		SAR		EBX,Prec
		ADD		EDX,EBP ;+[PntPlusX]
%endmacro

;**Clip*TEXTure Horizontal Line***********************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2)
; a ne pas utiliser mm6 & mm7 & mm3 & mm4
;***************************************************************************
%macro	@ClipTextHLine16  0
		MOV		EAX,[YT2]
		MOV		EBP,[XT2]
		SUB		EAX,[YT1]   ; EAX = DY
		JZ		%%CasDYZ
		SUB		EBP,[XT1]   ; EBP = DX
		JZ		%%CasDXZ
%%CasNorm:	@ClipTextHLineNorm16
		JMP		%%FinInTextHLg
%%CasDXZ:	@ClipTextHLineDXZ16
		JMP		%%FinInTextHLg
%%CasDYZ:	@ClipTextHLineDYZ16
%%FinInTextHLg:
%endmacro

%macro	@ClipTextHLineNorm16 0
		SHL 		EAX,Prec
		MOV		ESI,[YT1]      ; - 1'
		CMP		DWORD [Plus2],0
		JZ		%%PDivPPlusY
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusY
%%PDivPPlusY:	XOR		EAX,EAX
%%DivPPlusY:
		IMUL		ESI,[SScanLine]    ; - 2'
		NEG		EAX
		MOV		[PntPlusY],EAX  ;[PntPlusY]

		MOV		EAX,EBP
		XOR		EDX,EDX
		OR		EDX,BYTE 8
		NEG		ESI	       ; - 3'
		SHL		EAX,Prec
		ADD		ESI,[XT1]      ; - 4'
		ADD		ESI,[XT1]      ; - 4' +2*XT : 16bpp
		MOVD		mm5,EDX
		ADD		ESI,[Svlfb]    ; - 5'
		CMP		DWORD [Plus2],0
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
%%BcStBAv:	TEST		EDI,6
		JZ		%%FPasStBAv
		@AjAdNormB16
		MOV		AX,[ESI+EBX]
		DEC		ECX
		STOSW
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		CMP		ECX,BYTE 3
		JLE		%%StBAp
%%PasStDAv:
		MOVD		mm2,ECX
		SHR		ECX,2
;ALIGN 4
%%StoMMX:       MOVD		mm1,EDI  ; save EDI
		@AjAdNormQ16
                MOVD		mm5,ECX   ; save ECX
		MOV		AX,[ESI+EBX] ; read word 0
		@AjAdNormQ16
		ROR		EAX,16 ; swap words order
		MOV		AX,[ESI+EBX] ; read word 1
		@AjAdNormQ16
		MOV		CX,[ESI+EBX] ; read word 2
		@AjAdNormQ16
		ROR		ECX,16
		ROR		EAX,16 ; words on the right order
		MOV		CX,[ESI+EBX] ; read byte 3
		MOVD		EDI,mm1  ; restore EDI
		ROR		ECX,16 ; word 2,3 on the right order
                MOVD            mm0,EAX ; first 4 bytes to write
                MOVD            mm1,ECX ; second 4 byte to write
		PUNPCKLDQ	mm0,mm1 ; make the full 8 bytes to write
                MOVD		ECX,mm5   ; restore ECX
		MOVQ		[EDI],mm0 ; write the 8 bytes
		DEC		ECX
                LEA             EDI,[EDI+8]
		JNZ		%%StoMMX

		MOVD		ECX,mm2
		AND		ECX,BYTE 3
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdNormB16
		MOV		AX,[ESI+EBX]
		DEC		ECX
		STOSW
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;*******************************************************************
%macro	@ClipTextHLineDXZ16  0
		MOV		ESI,[YT1]   ; - 1
		SHL		EAX,Prec
		IMUL		ESI,[SScanLine] ; - 2
		CMP		DWORD [Plus2],0
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
		ADD		ESI,[XT1]   ; - 4(2) 16bpp
		IMUL		EDX,EBP ;-[PntPlusY] axe Y montant
		OR		EAX,EAX
		JLE		%%PosPntPlusY
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusY:
%%BcStBAv:	TEST		EDI,6
		JZ		%%FPasStBAv
		@AjAdDXZ16
		MOV		AX,[ESI+EBX]
		DEC		ECX
		STOSW
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		CMP		ECX,BYTE 3
		JLE		%%StBAp
%%PasStDAv:
		MOVD		mm2,ECX
		SHR		ECX,2
;ALIGN 4
%%StoMMX:	@AjAdDXZ16
                MOVD            mm5, ECX   ; save ECX
		MOV		AX,[ESI+EBX] ; read word 0
		@AjAdDXZ16
		ROR		EAX,16
		MOV		AX,[ESI+EBX] ; read word 1
		@AjAdDXZ16
		MOV		CX,[ESI+EBX] ; read word 2
		@AjAdDXZ16
		ROR		ECX,16
		ROR		EAX,16
		MOV		CX,[ESI+EBX] ; read word 3
		ROR		ECX,16
                MOVD            mm0, EAX ; first 4 bytes to write
                MOVD            mm1, ECX ; second 4 bytes to write
		PUNPCKLDQ	mm0,mm1 ; make the full 8 bytes to write
                MOVD            ECX, mm5   ; restore ECX
		MOVQ		[EDI],mm0 ; write the 8 bytes
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX

		MOVD		ECX,mm2
		AND		ECX,BYTE 3
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdDXZ16
		MOV		AX,[ESI+EBX]
		DEC		ECX
		STOSW
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro


;********************************************************

%macro	@ClipTextHLineDYZ16 0
		SUB		EBP,[XT1]
		MOV		ESI,[YT1]
		MOV		EAX,EBP
		SHL 		EAX,Prec
		CMP		DWORD [Plus2],0
		JZ		%%PDivPPlusY
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusY
%%PDivPPlusY:	XOR		EAX,EAX
%%DivPPlusY:
		MOV		EBP,EAX  ;[PntPlusX]
		IMUL		ESI,[SScanLine]
		MOV		EDX,[Plus]
		NEG		ESI
		IMUL		EDX,EBP ;+[PntPlusX]
		ADD		ESI,[XT1]
		ADD		ESI,[XT1] ; 16bpp
		ADD		ESI,[Svlfb]
		OR		EAX,EAX
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:
%%BcStBAv:	TEST		EDI,6
		JZ		%%FPasStBAv
		@AjAdDYZ16
		MOV		AX,[ESI+EBX*2]
		DEC		ECX
		STOSW
		JZ		%%FinSHLine

		JMP		SHORT %%BcStBAv
%%FPasStBAv:
		CMP		ECX,BYTE 3
		JLE		%%StBAp
%%PasStDAv:
		MOVD		mm2,ECX
		SHR		ECX,2
;ALIGN 4
%%StoMMX:	@AjAdDYZ16
		MOV		AX,[ESI+EBX*2] ; read word 0
		@AjAdDYZ16
		ROR		EAX,16 ; reverse words order
                MOVD            mm5,ECX  ; save ECX
		MOV		AX,[ESI+EBX*2] ; read word 1
		@AjAdDYZ16
		MOV		CX,[ESI+EBX*2]  ; read word 2
		@AjAdDYZ16
		ROR		ECX,16
		ROR		EAX,16 ; back to right words order
		MOV		CX,[ESI+EBX*2]  ; read word 3
		ROR		ECX,16
                MOVD            mm0,EAX  ; first 4 bytes to write
                MOVD            mm1,ECX  ; second 4 bytes to write
		PUNPCKLDQ	mm0,mm1 ; make the full 8 bytes to write
                MOVD            ECX,mm5  ; restore ECX
		MOVQ		[EDI],mm0 ; write the 8 bytes
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX

		MOVD		ECX,mm2
		AND		ECX,BYTE 3
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdDYZ16
		MOV		AX,[ESI+EBX*2]
		DEC		ECX
		STOSW
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro


;****** MASKTEXT
;**IN*TEXTure Horizontal Line***********************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2)
; a ne pas utiliser mm6 & mm7
; utilise mm5,mm4,mm3,mm2,mm1,mm0
;***************************************************************************
%macro	@InMaskTextHLine16  0
		MOV		EAX,[YT2]
		MOV		EBP,[XT2]
		SUB		EAX,[YT1]   ; EAX = DY
		JZ		%%CasDYZ
		SUB		EBP,[XT1]   ; EBP = DX
		JZ		%%CasDXZ
%%CasNorm:	@InMaskTextHLineNorm16
		JMP		%%FinInTextHLg
%%CasDXZ:	@InMaskTextHLineDXZ16
		JMP		%%FinInTextHLg
%%CasDYZ:	@InMaskTextHLineDYZ16
%%FinInTextHLg:
%endmacro

; AX : DYT, EBP : DXT

%macro	@InMaskTextHLineNorm16 0
		MOV		ESI,[YT1]      ; - 1
		SHL 		EAX,Prec
		CDQ
		IMUL		ESI,[SScanLine]    ; - 2
		OR		ECX,ECX
		JZ		%%PDivPntPY
		IDIV		ECX
		JMP		SHORT %%DivPntPY
%%PDivPntPY:	XOR		EAX,EAX
%%DivPntPY:
		NEG		ESI	       ; - 3
		NEG		EAX
		ADD		ESI,[XT1]      ; - 4
		MOV		[PntPlusY],EAX  ;[PntPlusY]
		ADD		ESI,[XT1]      ; - 4(2) as 16bpp

		XOR		EDX,EDX
		MOV		EAX,EBP

		OR		EDX,BYTE 8
		ADD		ESI,[Svlfb]    ; - 5
		SHL		EAX,Prec
		MOVD		mm5,EDX
		CDQ
		OR		ECX,ECX
		JZ		%%PDivPntPX
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
		
%%BcStBAv:	@AjAdNormB16
		MOV		AX,[EBX+ESI]
		CMP		AX,[SMask]
		JZ		%%NoPut
		MOV		[EDI],AX
%%NoPut:	DEC		ECX
		LEA		EDI,[EDI+2]
		JNZ		%%BcStBAv
%endmacro


;********************************************************

%macro	@InMaskTextHLineDXZ16  0
		MOV		ESI,[YT1]    ; - 1
		SHL		EAX,Prec
		CDQ
		IMUL		ESI,[SScanLine]  ; - 2
		OR		ECX,ECX
		JZ		%%PDivPntPX
		IDIV		ECX
		JMP		SHORT %%DivPntPX
%%PDivPntPX:	XOR		EAX,EAX
%%DivPntPX:
		NEG		ESI	     ; - 3
		MOV		EBP,EAX ; [PntPlusY]
		ADD		ESI,[XT1]    ; - 4
		XOR		EDX,EDX      ; Cpt Dbrd Y
		ADD		ESI,[XT1]    ; - 4 (+XT1*2) as 16bpp
		OR		EAX,EAX
		JLE		%%PosPntPlusY
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusY:
		ADD		ESI,[Svlfb]  ; - 5
		INC		ECX
%%BcStBAv:	@AjAdDXZ16
		MOV		AX,[ESI+EBX]
		CMP		AX,[SMask]
		JZ		%%NoDW
		MOV		[EDI],AX
%%NoDW:		DEC		ECX
		LEA		EDI,[EDI+2]
		JNZ		%%BcStBAv

%endmacro

;********************************************************

%macro	@InMaskTextHLineDYZ16 0
		SUB		EBP,[XT1]
		MOV		ESI,[YT1]   ; - 1
		MOV		EAX,EBP
		IMUL		ESI,[SScanLine] ; - 2
		SHL 		EAX,Prec
		NEG		ESI	    ; - 3
		CDQ
		ADD		ESI,[XT1]   ; - 4
		ADD		ESI,[XT1]   ; - 4 + (XT1*2) as 16bpp
		OR		ECX,ECX
		JZ		%%PDivPntPX
		IDIV		ECX
		JMP		SHORT %%DivPntPX
%%PDivPntPX:	XOR		EAX,EAX
%%DivPntPX:
		ADD		ESI,[Svlfb] ; - 5
		XOR		EDX,EDX     ;Cpt Dbrd X
		OR		EAX,EAX			; SAR
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:
		MOV		EBP,EAX  ;[PntPlusX]
		INC		ECX
%%BcStBAv:	@AjAdDYZ16
		MOV		AX,[ESI+EBX*2]
		CMP		AX,[SMask]
		JZ		%%NoDW
		MOV		[EDI],AX
%%NoDW:
		DEC		ECX
		LEA		EDI,[EDI+2]
		JNZ		%%BcStBAv
%endmacro


;**Clip*MaskTEXTure Horizontal Line***********************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2)
; a ne pas utiliser mm6 & mm7 & mm3 & mm4
;***************************************************************************
%macro	@ClipMaskTextHLine16  0
		MOV		EAX,[YT2]
		MOV		EBP,[XT2]
		SUB		EAX,[YT1]   ; EAX = DY
		JZ		%%CasDYZ
		SUB		EBP,[XT1]   ; EBP = DX
		JZ		%%CasDXZ
%%CasNorm:	@ClipMaskTextHLineNorm16
		JMP		%%FinInTextHLg
%%CasDXZ:	@ClipMaskTextHLineDXZ16
		JMP		%%FinInTextHLg
%%CasDYZ:	@ClipMaskTextHLineDYZ16
%%FinInTextHLg:
%endmacro

%macro	@ClipMaskTextHLineNorm16 0
		SHL 		EAX,Prec
		MOV		ESI,[YT1]      ; - 1'
		CMP		DWORD [Plus2],0
		JZ		%%PDivPPlusY
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusY
%%PDivPPlusY:	XOR		EAX,EAX
%%DivPPlusY:
		IMUL		ESI,[SScanLine]    ; - 2'
		NEG		EAX
		MOV		[PntPlusY],EAX  ;[PntPlusY]

		MOV		EAX,EBP
		XOR		EDX,EDX
		OR		EDX,BYTE 8
		NEG		ESI	       ; - 3'
		SHL		EAX,Prec
		ADD		ESI,[XT1]      ; - 4'
		ADD		ESI,[XT1]      ; - 4' +2*XT : 16bpp
		MOVD		mm5,EDX
		ADD		ESI,[Svlfb]    ; - 5'
		CMP		DWORD [Plus2],0
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
%%BcStBAv:	@AjAdNormB16
		MOV		AX,[ESI+EBX]
		CMP		AX,[SMask]
		JZ		%%NoDW
		MOV		[EDI],AX
%%NoDW:
		DEC		ECX
		LEA		EDI,[EDI+2]
		JNZ		%%BcStBAv
%endmacro

;*******************************************************************
%macro	@ClipMaskTextHLineDXZ16  0
		MOV		ESI,[YT1]   ; - 1
		SHL		EAX,Prec
		IMUL		ESI,[SScanLine] ; - 2
		CMP		DWORD [Plus2],0
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
		ADD		ESI,[XT1]   ; - 4(2) 16bpp
		IMUL		EDX,EBP ;-[PntPlusY] axe Y montant
		OR		EAX,EAX
		JLE		%%PosPntPlusY
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusY:
%%BcStBAv:	@AjAdDXZ16
		MOV		AX,[ESI+EBX]
		CMP		AX,[SMask]
		JZ		%%NoDW
		MOV		[EDI],AX
%%NoDW:
		DEC		ECX
		LEA		EDI,[EDI+2]
		JNZ		%%BcStBAv
%endmacro


;********************************************************

%macro	@ClipMaskTextHLineDYZ16 0
		SUB		EBP,[XT1]
		MOV		ESI,[YT1]
		MOV		EAX,EBP
		SHL 		EAX,Prec
		CMP		DWORD [Plus2],0
		JZ		%%PDivPPlusY
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusY
%%PDivPPlusY:	XOR		EAX,EAX
%%DivPPlusY:
		MOV		EBP,EAX  ;[PntPlusX]
		IMUL		ESI,[SScanLine]
		MOV		EDX,[Plus]
		NEG		ESI
		IMUL		EDX,EBP ;+[PntPlusX]
		ADD		ESI,[XT1]
		ADD		ESI,[XT1] ; 16bpp
		ADD		ESI,[Svlfb]
		OR		EAX,EAX
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:
%%BcStBAv:	@AjAdDYZ16
		MOV		AX,[ESI+EBX*2]
		CMP		AX,[SMask]
		JZ		%%NoDW
		MOV		[EDI],AX
%%NoDW:
		DEC		ECX
		LEA		EDI,[EDI+2]
		JNZ		%%BcStBAv
%endmacro

;***** RGB
;***************************************************************************
; IN : ESI long, EDI Dest, EBP col1, EAX col2
;***************************************************************************


%macro	@InRGBHLine16	0
		MOVD		mm2,EAX
		MOVD		mm4,EBP ; *
		MOVD		mm3,EAX
		MOVD		mm5,EBP ; *
		PUNPCKLDQ	mm2,mm2
		PUNPCKLDQ	mm4,mm4
		PAND		mm2,[MaskB_RGB16] ; mm2 : Blue | green
		PAND		mm4,[MaskB_RGB16] ; * mm4 : Blue | green
		PAND		mm3,[MaskR_RGB16] ; mm3 : red | 0
		PAND		mm5,[MaskR_RGB16] ; * mm5 : red | 0

		PSUBD		mm2,mm4 ; mm2 : DeltaBlue | DeltaGreen
		PSUBD		mm3,mm5 ; mm3 : DeltaRed
		PSLLD		mm2,Prec ; mm2 : DeltaBlue<<Prec | DeltaGreed<<Prec
		PSLLD		mm4,Prec ; mm4 : Col1_B<<Prec | Col1_G<<Prec
		MOVD		EAX,mm2
		PSLLD		mm5,Prec ; mm5 : Col1_R<<Prec | -
		PSLLD		mm3,Prec ; mm3 : DeltaRed<<Prec

		XOR		EBX,EBX
		CDQ
		XOR		ECX,ECX
		IDIV		ESI
		PSRLQ		mm2,32
		OR		EAX,EAX
		MOVD		mm6,EAX ; mm6 = PntBlue | -
		SETL		BL

		MOVD		EAX,mm3
		OR		ECX,EBX
		CDQ
		IDIV		ESI
		OR		EAX,EAX
		MOVD		mm7,EAX ; mm7 = PntRed | -
		SETL		BL

		MOVD		EAX,mm2
		LEA		ECX,[ECX+EBX*4]
		CDQ
		IDIV		ESI
		OR		EAX,EAX
		MOVD		mm3,EAX ; mm3 = PntGReen | -
		SETL		BL
		PUNPCKLDQ	mm6,mm6 ; mm6 = PntBlue | PntBlue
		LEA		ECX,[ECX+EBX*2]
		PUNPCKLDQ	mm3,mm3 ; mm3 = PntGreen | PntGReen
		SHL		ECX,4

		; mm6, mm7 : pnt     B | B , R | -
		; mm3      : pnt     G | G
		; mm4, mm5 : init shift  Col1B,Col1G,Col1R
		; Free : EAX,EBX,ECX,EDX,EBP
		PADDD		mm4,[RGBDebMask_GGG+ECX]   ; mm4 = cptDbrd B | cptDbrd G ;; += Col1B | Col1G  Shifted
		PADDD		mm5,[RGBDebMask_GGG+ECX+8] ; mm5 = cptDbrd R | - ;; += Col1R | -  Shifted
		MOVQ		mm2,mm4 ; mm2 = cptDbrd B | cptDbrd G
		PUNPCKLDQ	mm7,mm7 ; mm7 = PntR | PntR
		PUNPCKHDQ	mm2,mm2 ; mm4 = cptDbrd G | cptDbrd G
		; mm4, mm5 : cptDbrd B | B , cptDbrd R | R
		; mm2      : cptDbrd G | G
		; mm3, mm6 : pnt G | G , pnt B | B
		; mm7      : pnt R | R
		
; start drawing the rgb16 hline

%%BcStBAv:	TEST		EDI,2
		JZ		%%FPasStBAv
		@HLnRGB16GEtP
		MOVD		EAX,mm1
		DEC		ESI
		STOSW
		;MOV		[EDI],AX
		;LEA		EDI,[EDI+2]
		JZ		%%FinSHLine
%%FPasStBAv:
		CMP		ESI,BYTE 1
		JLE		%%StBAp
%%PasStDAv:
		MOVQ		mm1,mm4 ; = Cpt dbrd B| -
		MOVQ		mm0,mm5 ; = Cpt dbrd R| -
		MOV		ECX,ESI
		PADDD		mm1,mm6 ; += Pnt B | B
		PADDD		mm0,mm7 ; += Pnt R | R
		PUNPCKLDQ	mm4,mm1 ; mm4 = cpt dbrd B | (cpt dbrd B + Pnt B)
		PUNPCKLDQ	mm5,mm0 ; mm5 = cpt dbrd R | (cpt dbrd R + Pnt R)
		MOVQ		mm1,mm2 ; = cpt Dbrd G|G
		;PSLLD		mm6,1
		PADDD		mm6,mm6
		;PSLLD		mm7,1
		PADDD		mm7,mm7
		PADDD		mm1,mm3
		SHR		ECX,1
		PUNPCKLDQ	mm2,mm1 ; mm2 = cpt dbrd G | (cpt dbrd G + Pnt G)
		;PSLLD		mm3,1
		PADDD		mm3,mm3
;ALIGN 4
%%StoMMX:	@HLnRGB16GEtP		 ; word 0|1
		POR		mm0,mm1
		PSRLQ		mm1,32
		PUNPCKLWD	mm0,mm1
		MOVD		[EDI],mm0 ; write the 2 words
		DEC		ECX
		LEA		EDI,[EDI+4]
		JNZ		%%StoMMX
		PSRLD		mm3,1
		PSRLD		mm6,1
		PSRLD		mm7,1
		
%%StBAp:	AND		ESI,BYTE 1
		JZ		%%PasStBAp
		@HLnRGB16GEtP
		MOVD		EAX,mm1
		MOV		[EDI],AX
%%PasStBAp:

%%FinSHLine:

%endmacro


; get next pixel of a hlineRGB16
%macro	@HLnRGB16GEtP	0
		MOVQ		mm0,mm2 ; mm0 = cptDbrd G|G
		MOVQ		mm1,mm5 ; mm1 = cptDbrd R,R
		PSRLD		mm0,Prec
		PSRLD		mm1,Prec
		PAND		mm0,[Mask2G_RGB16]
		PAND		mm1,[Mask2R_RGB16]
		POR		mm1,mm0
		PADDD		mm5,mm7 ; = cptDbrd R|R + Pnt R|R
		MOVQ		mm0,mm4 ; mm0 = cptDbrd B,B
		PADDD		mm2,mm3 ; = cptDbrd G|G + Pnt G|G
		PADDD		mm4,mm6 ; = cptDbrd B|B + Pnt B|B
		PSRLD		mm0,Prec
		;PAND		mm0,[Mask2B_RGB16]
		POR		mm1,mm0
%endmacro




;***************************************************************************
; Clip RGBHLine : ECX long, EDI Dest, EBP col1, EAX col2, plus2 GlobDeltaX
; plus : number of pixel to jump before starting
;***************************************************************************

%macro	@ClipRGBHLine16	0
		MOVD		mm2,EAX
		MOVD		mm4,EBP ; *
		MOVD		mm3,EAX
		MOVD		mm5,EBP ; *
		PUNPCKLDQ	mm2,mm2
		PUNPCKLDQ	mm4,mm4
		PAND		mm2,[MaskB_RGB16] ; mm2 : Blue | green
		PAND		mm4,[MaskB_RGB16] ; * mm4 : Blue | green
		PAND		mm3,[MaskR_RGB16] ; mm3 : red | 0
		PAND		mm5,[MaskR_RGB16] ; * mm5 : red | 0

		PSUBD		mm2,mm4 ; mm2 : DeltaBlue | DeltaGreen
		PSUBD		mm3,mm5 ; mm3 : DeltaRed
		PSLLD		mm4,Prec ; mm4 : Col1_B<<Prec | Col1_G<<Prec
		PSLLD		mm5,Prec ; mm5 : Col1_R<<Prec | -
		PSLLD		mm2,Prec ; mm2 : DeltaBlue<<Prec | DeltaGreed<<Prec
		PSLLD		mm3,Prec ; mm3 : DeltaRed<<Prec

		MOV		ESI,[Plus2]
		XOR		EBP,EBP
		OR		ESI,ESI
		JZ		%%Plus2Zero
		
		MOVD		EAX,mm2
		XOR		EBX,EBX
		CDQ
		IDIV		ESI
		PSRLQ		mm2,32
		OR		EAX,EAX
		MOVD		mm6,EAX ; mm6 = PntBlue | -
		SETL		BL
		
		MOVD		EAX,mm3
		OR		EBP,EBX
		CDQ
		IDIV		ESI
		OR		EAX,EAX
		MOVD		mm7,EAX ; mm7 = PntRed | -
		SETL		BL

		MOVD		EAX,mm2
		LEA		EBP,[EBP+EBX*4];
		CDQ
		IDIV		ESI
		OR		EAX,EAX
		MOVD		mm3,EAX ; mm3 = PntGReen | -
		SETL		BL
		PUNPCKLDQ	mm6,mm6 ; mm6 = PntB | PntB
		LEA		EBP,[EBP+EBX*2]
		PUNPCKLDQ	mm3,mm3 ; mm6 = PntG | PntG
		SHL		EBP,4
		JMP		SHORT %%Plus2SupZero
%%Plus2Zero:	XOR		EAX,EAX ; PntGReen
		PXOR		mm6,mm6 ; mm6 : PntBlue=0 | PntB=0
		PXOR		mm3,mm3 ; mm3 : PntG=0 | PntG=0
		PXOR		mm7,mm7 ; mm7 : PntRed=0
%%Plus2SupZero:
		; mm6, mm7 : pnt     B | B , R | -
		; mm3      : pnt     G | G
		; mm4, mm5 : init shift  Col1B,Col1G,Col1R
		PADDD		mm4,[RGBDebMask_GGG+EBP]   ; mm4 = cptDbrd B | cptDbrd G ;; += Col1B | Col1G  Shifted
		PADDD		mm5,[RGBDebMask_GGG+EBP+8] ; mm5 = cptDbrd R | - ;; += Col1R | -  Shifted
		MOVQ		mm2,mm4 ; mm2 = cptDbrd B | cptDbrd G
		MOV		EBX,[Plus]
		PUNPCKLDQ	mm7,mm7 ; mm7 = PntR | PntR
		OR		EBX,EBX
		PUNPCKHDQ	mm2,mm2 ; mm4 = cptDbrd G | cptDbrd G
; Adjust CptDbrd if [Plus]>0
		JZ		%%PasAjPlus
		IMUL		EAX,EBX ; PntGReen*DeltaX
		MOVD		ESI,mm6		; EDI = Pnt Blue
		MOVD		mm0,EAX
		MOVD		EDX,mm7		; EDX = Pnt Red
		IMUL		ESI,EBX ; PntBlue*DeltaX
		PADDD		mm2,mm0 ; cpt dbrd G + deltaG | -
		IMUL		EDX,EBX ; PntREd*DeltaY
		MOVD		mm1,ESI
		MOVD		mm0,EDX
		PADDD		mm4,mm1 ; cpt dbrd B + deltaB | -
		PADDD		mm5,mm0 ; cpt dbrd R + deltaR | -
%%PasAjPlus:
		; mm2, mm3 : cptDbrd B,G,R
		; mm6, mm7 : pnt     B,G,R
		; mm4, mm5 : pnt     Col1B,Col1G,Col1R
		
; start drawing the rgb16 hline

%%BcStBAv:	TEST		EDI,2
		JZ		%%FPasStBAv
		@HLnRGB16GEtP
		MOVD		EAX,mm1
		DEC		ECX
		STOSW
		JZ		%%FinSHLine
%%FPasStBAv:
		CMP		ECX,BYTE 1
		JLE		%%StBAp
%%PasStDAv:
		MOVQ		mm1,mm4 ; = Cpt dbrd B| -
		MOVQ		mm0,mm5 ; = Cpt dbrd R| -
		MOV		ESI,ECX
		PADDD		mm1,mm6 ; += Pnt B | B
		PADDD		mm0,mm7 ; += Pnt R | R
		PUNPCKLDQ	mm4,mm1 ; mm4 = cpt dbrd B | (cpt dbrd B + Pnt B)
		PUNPCKLDQ	mm5,mm0 ; mm5 = cpt dbrd R | (cpt dbrd R + Pnt R)
		MOVQ		mm1,mm2 ; = cpt Dbrd G|G
		;PSLLD		mm6,1
		PADDD		mm6,mm6
		;PSLLD		mm7,1
		PADDD		mm7,mm7
		PADDD		mm1,mm3
		SHR		ESI,1
		PUNPCKLDQ	mm2,mm1 ; mm2 = cpt dbrd G | (cpt dbrd G + Pnt G)
		;PSLLD		mm3,1
		PADDD		mm3,mm3
;ALIGN 4
%%StoMMX:	@HLnRGB16GEtP		 ; word 0
		POR		mm0,mm1
		PSRLQ		mm1,32
		PUNPCKLWD	mm0,mm1
		MOVD		[EDI],mm0 ; write the 2 words
		DEC		ESI
		LEA		EDI,[EDI+4]
		JNZ		%%StoMMX
		PSRLD		mm3,1
		PSRLD		mm6,1
		PSRLD		mm7,1
%%StBAp:	AND		ECX,BYTE 1
		JZ		%%PasStBAp
		@HLnRGB16GEtP
		MOVD		EAX,mm1
		MOV		[EDI],AX
%%PasStBAp:

%%FinSHLine:

;%%BcHlineRGB:
;		@HLnRGB16GEtP
;		MOVD		EAX,mm1
;		DEC		ESI
;		MOV		[EDI],AX
;		LEA		EDI,[EDI+2]
;		JNZ		%%BcHlineRGB
%endmacro


;***** SOLID_BLND
;***************************************************************************
; IN : ESI long, EDI Dest, (mm3, mm4, mm5) mul B G R dst, mm7 mul src
;***************************************************************************

%macro	@SolidBlndHLine16	0
		TEST		EDI,2
		JZ		%%FPasStBAv
		MOV		AX,[EDI]
		MOVD		mm0,EAX ; B
		MOVD		mm1,EAX ; G
		;MOVQ		mm2,mm0	  ; R
		MOVD		mm2,EAX	  ; R
		@SolidBlndQ
		MOVD		EAX,mm0
		DEC		ESI
		STOSW
		JZ		%%FinSHLine
%%FPasStBAv:
		TEST		EDI,4
		JZ		SHORT %%PasStDAv
		CMP		ESI,2
		JL		%%StBAp
		MOV		EAX,[EDI]
		MOVD		mm0,EAX ; B
		MOVD		mm1,EAX   ; G
		MOVD		mm2,EAX	  ; R
		@SolidBlndQ
		MOVD		[EDI],mm0
		SUB		ESI,BYTE 2
		LEA		EDI,[EDI+4]
%%PasStDAv:
		MOV		ECX,ESI
		SHR		ECX,2
		OR		ECX,ECX
		JZ		%%StDAp
%%StoMMX:	MOVQ		mm0,[EDI]
		MOVQ		mm1,[EDI]
		MOVQ		mm2,[EDI]
		;MOVQ		mm0,mm1
		;MOVQ		mm2,mm1
		@SolidBlndQ
		MOVQ		[EDI],mm0
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX
		AND		ESI,BYTE 3
		JZ		%%FinSHLine
%%StDAp: 	TEST		ESI,2
		JZ		SHORT %%StBAp
		MOV		EAX,[EDI] ; B
		MOVD		mm0,EAX ; B
		MOVD		mm1,EAX ; G
		MOVD		mm2,EAX  ; R
		@SolidBlndQ
		MOVD		[EDI],mm0
		SUB		ESI,BYTE 2
		LEA		EDI,[EDI+4]
%%StBAp:	TEST		ESI,1
		JZ		SHORT %%PasStBAp
		MOV		AX,[EDI]
		MOVD		mm0,EAX ; B
		MOVD		mm1,EAX ; G
		MOVD		mm2,EAX	  ; R
		@SolidBlndQ
		MOVD		EAX,mm0
		STOSW
%%PasStBAp:
%%FinSHLine:

%endmacro

%macro	@SolidBlndQ 0
		PAND		mm0,[QBlue16Mask]
		PAND		mm1,[QGreen16Mask]
		PAND		mm2,[QRed16Mask]
		PMULLW		mm0,mm7 ; [blend_src]
		PSRLW		mm2,5
		PMULLW		mm1,mm7 ; [blend_src]
		PMULLW		mm2,mm7 ; [blend_src]
		PADDW		mm0,mm3
		PADDW		mm1,mm4
		PADDW		mm2,mm5
		PSRLW		mm0,5
		PSRLW		mm1,5
		PAND		mm2,[QRed16Mask]
		;PAND		mm0,[QBlue16Mask]
		PAND		mm1,[QGreen16Mask]
		POR		mm0,mm2
		POR		mm0,mm1
%endmacro

;****** TEXT BLEND
;**IN*TEXTure BLEND Horizontal Line***********************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2)
; a ne pas utiliser mm6 & mm7
; utilise mm5,mm4,mm3,mm2,mm1,mm0
;***************************************************************************
%macro	@InTextBlndHLine16  0
		MOV		EAX,[YT2]
		MOV		EBP,[XT2]
		SUB		EAX,[YT1]   ; EAX = DY
		JZ		%%CasDYZ
		SUB		EBP,[XT1]   ; EBP = DX
		JZ		%%CasDXZ
%%CasNorm:	@InTextBlndHLineNorm16
		JMP		%%FinInTextHLg
%%CasDXZ:	@InTextBlndHLineDXZ16
		JMP		%%FinInTextHLg
%%CasDYZ:	@InTextBlndHLineDYZ16
%%FinInTextHLg:
%endmacro

; AX : DYT, EBP : DXT

%macro	@InTextBlndHLineNorm16 0
		MOV		ESI,[YT1]      ; - 1
		SHL 		EAX,Prec
		CDQ
		IMUL		ESI,[SScanLine]    ; - 2
		OR		ECX,ECX
		JZ		%%PDivPntPY
		IDIV		ECX
		JMP		SHORT %%DivPntPY
%%PDivPntPY:	XOR		EAX,EAX
%%DivPntPY:
		NEG		ESI	       ; - 3
		NEG		EAX
		ADD		ESI,[XT1]      ; - 4
		MOV		[PntPlusY],EAX  ;[PntPlusY]
		ADD		ESI,[XT1]      ; - 4(2) as 16bpp

		MOV		EAX,EBP

		ADD		ESI,[Svlfb]    ; - 5
		SHL		EAX,Prec
		CDQ
		OR		ECX,ECX
		JZ		%%PDivPntPX
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

		
%%BcStBAv:	TEST		EDI,6
		JZ		%%FPasStBAv
		@AjAdNormB16
		MOV		AX,[EBX+ESI]
		DEC		ECX
		@SolidTextBlndW
		STOSW
		JZ		%%FinSHLine

		JMP		%%BcStBAv
%%FPasStBAv:
		CMP		ECX,BYTE 3
		JLE		%%StBAp
		PUSH		ECX

		SHR		ECX,2
;ALIGN 4
%%StoMMX:	MOVD		mm5,EDI  ; save EDI in mm5
		@AjAdNormQ16
                MOVD		mm3,ECX   ; save ECX
		MOV		AX,[ESI+EBX] ; read word 0
		@AjAdNormQ16
		ROR		EAX,16 ; move first word to upper EAX word
		MOV		CX,[ESI+EBX] ; read word 1
		@AjAdNormQ16
		ROR		ECX,16
		MOV		AX,[ESI+EBX] ; read word 2
		@AjAdNormQ16
		ROR		EAX,16 ; EAX words on the right order
		MOV		CX,[ESI+EBX] ; read byte 3
		MOVD		EDI,mm5 ; restore EDI
		ROR		ECX,16   ; ; ECX words on the right order
                MOVD            mm0,EAX ; first 4 bytes to write
                MOVD            mm4,ECX ; second 4 byte to write
		PUNPCKLWD	mm0,mm4 ; make the full 8 bytes to write
                MOVD		ECX,mm3   ; restore ECX
		@SolidTextBlndQ
		MOVQ		[EDI],mm0 ; write the 8 bytes
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX

		POP		ECX  ; restore first 3 bits of ECX
		AND		ECX,BYTE 3
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdNormB16
		MOV		AX,[ESI+EBX]
		DEC		ECX
		@SolidTextBlndW
		STOSW
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

%macro	@SolidTextBlndQ 0
		MOVQ		mm1,mm0
		MOVQ		mm2,mm0
		PAND		mm0,[QBlue16Mask]
		PAND		mm1,[QGreen16Mask]
		PAND		mm2,[QRed16Mask]
		PMULLW		mm0,[QMulSrcBlend]
		PSRLW		mm2,5
		PMULLW		mm1,[QMulSrcBlend]
		PMULLW		mm2,[QMulSrcBlend]
		PADDW		mm0,[QBlue16Blend]
		PADDW		mm1,[QGreen16Blend]
		PADDW		mm2,[QRed16Blend]
		PSRLW		mm0,5
		PSRLW		mm1,5
		PAND		mm2,[QRed16Mask]
		;PAND		mm0,[QBlue16Mask]
		PAND		mm1,[QGreen16Mask]
		POR		mm0,mm2
		POR		mm0,mm1
%endmacro

%macro	@SolidTextBlndW 0
		MOVD		mm0,EAX
		MOVD		mm1,EAX
		MOVD		mm2,EAX
		PAND		mm0,[QBlue16Mask]
		PAND		mm1,[QGreen16Mask]
		PAND		mm2,[QRed16Mask]
		PMULLW		mm0,[QMulSrcBlend]
		PSRLW		mm2,5
		PMULLW		mm1,[QMulSrcBlend]
		PMULLW		mm2,[QMulSrcBlend]
		PADDW		mm0,[QBlue16Blend]
		PADDW		mm1,[QGreen16Blend]
		PADDW		mm2,[QRed16Blend]
		PSRLW		mm0,5
		PSRLW		mm1,5
		PAND		mm2,[QRed16Mask]
		;PAND		mm0,[QBlue16Mask]
		PAND		mm1,[QGreen16Mask]
		POR		mm0,mm2
		POR		mm0,mm1
		MOVD		EAX,mm0
%endmacro


;********************************************************

%macro	@InTextBlndHLineDXZ16  0
		MOV		ESI,[YT1]    ; - 1
		SHL		EAX,Prec
		CDQ
		IMUL		ESI,[SScanLine]  ; - 2
		OR		ECX,ECX
		JZ		%%PDivPntPX
		IDIV		ECX
		JMP		SHORT %%DivPntPX
%%PDivPntPX:	XOR		EAX,EAX
%%DivPntPX:
		NEG		ESI	     ; - 3
		MOV		EBP,EAX ; [PntPlusY]
		ADD		ESI,[XT1]    ; - 4
		XOR		EBX,EBX      ; Cpt Dbrd Y
		ADD		ESI,[XT1]    ; - 4 (+XT1*2) as 16bpp
		OR		EAX,EAX
		ADD		ESI,[Svlfb]  ; - 5
		SETG		BL
		INC		ECX
		MOV		EDX,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr Y
%%BcStBAv:	TEST		EDI,6
		JZ		%%FPasStBAv
		@AjAdDXZ16
		MOV		AX,[ESI+EBX]
		DEC		ECX
		@SolidTextBlndW
		STOSW
		JZ		%%FinSHLine

		JMP		%%BcStBAv
%%FPasStBAv:
		CMP		ECX,BYTE 3
		JLE		%%StBAp
%%PasStDAv:
		MOVD		mm4,ECX
		SHR		ECX,2
;ALIGN 4
%%StoMMX:	@AjAdDXZ16
                MOVD            mm3, ECX   ; save ECX
		MOV		AX,[ESI+EBX] ; read word 0
		@AjAdDXZ16
		ROR		EAX,16
		MOV		CX,[ESI+EBX] ; read word 1
		@AjAdDXZ16
		ROR		ECX,16
		MOV		AX,[ESI+EBX] ; read word 2
		@AjAdDXZ16
		MOV		CX,[ESI+EBX] ; read word 3
		ROR		EAX,16 ; EAX right order
		ROR		ECX,16 ; ECX right order
		MOVD		mm0, EAX ; first 4 bytes to write
		MOVD		mm1, ECX ; second 4 bytes to write
		PUNPCKLWD	mm0,mm1 ; make the full 8 bytes to write
		MOVD		ECX, mm3   ; restore ECX
		@SolidTextBlndQ
		MOVQ		[EDI],mm0 ; write the 8 bytes
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX

		MOVD		ECX,mm4
		AND		ECX,BYTE 3
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdDXZ
		MOV		AX,[ESI+EBX]
		DEC		ECX
		@SolidTextBlndW
		STOSW
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;%macro  @AjAdDXZ16  0
;		MOV		EBX,EDX
;		SAR		EBX,Prec
;		SUB		EDX,EBP ;-[PntPlusY]
;		IMUL		EBX,[SScanLine]
;%endmacro
;********************************************************

%macro	@InTextBlndHLineDYZ16 0
		SUB		EBP,[XT1]
		MOV		ESI,[YT1]   ; - 1
		MOV		EAX,EBP
		IMUL		ESI,[SScanLine] ; - 2
		SHL 		EAX,Prec
		NEG		ESI	    ; - 3
		CDQ
		ADD		ESI,[XT1]   ; - 4
		ADD		ESI,[XT1]   ; - 4 + (XT1*2) as 16bpp
		OR		ECX,ECX
		JZ		%%PDivPntPX
		IDIV		ECX
		JMP		SHORT %%DivPntPX
%%PDivPntPX:	XOR		EAX,EAX
%%DivPntPX:
		XOR		EBX,EBX      ; Cpt Dbrd Y
		ADD		ESI,[Svlfb] ; - 5
		OR		EAX,EAX			; SAR
		MOV		EBP,EAX  ;[PntPlusX]
		SETL		BL
		INC		ECX
		MOV		EDX,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr Y
%%BcStBAv:	TEST		EDI,6
		JZ		%%FPasStBAv
		@AjAdDYZ16
		MOV		AX,[ESI+EBX*2]
		DEC		ECX
		@SolidTextBlndW
		STOSW
		JZ		%%FinSHLine

		JMP		%%BcStBAv
%%FPasStBAv:
		CMP		ECX,BYTE 3
		JLE		%%StBAp
%%PasStDAv:
		MOVD		mm4,ECX
		SHR		ECX,2
;ALIGN 4
%%StoMMX:	@AjAdDYZ16
		MOVD		mm3,ECX  ; save ECX
		MOV		AX,[ESI+EBX*2] ; read word 0
		@AjAdDYZ16
		ROR		EAX,16
		MOV		CX,[ESI+EBX*2] ; read word 1
		@AjAdDYZ16
		ROR		ECX,16
		MOV		AX,[ESI+EBX*2]  ; read word 2
		@AjAdDYZ16
		MOV		CX,[ESI+EBX*2]  ; read word 3
		ROR		EAX,16 ; right order
		ROR		ECX,16 ; right order
		MOVD		mm0,EAX  ; first 4 bytes to write
		MOVD		mm1,ECX  ; second 4 bytes to write
		PUNPCKLWD	mm0,mm1 ; make the full 8 bytes to write
		MOVD		ECX,mm3  ; restore ECX
		@SolidTextBlndQ
		MOVQ		[EDI],mm0 ; write the 8 bytes
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX

		MOVD		ECX,mm4
		AND		ECX,BYTE 3
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdDYZ16
		MOV		AX,[ESI+EBX*2]
		DEC		ECX
		@SolidTextBlndW
		STOSW
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;%macro  @AjAdDYZ16  0
;		MOV		EBX,EDX
;		SAR		EBX,Prec
;		ADD		EDX,EBP ;+[PntPlusX]
;%endmacro

;**Clip*TEXTure Horizontal Line***********************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2)
; a ne pas utiliser mm6 & mm7 & mm3 & mm4
;***************************************************************************
%macro	@ClipTextBlndHLine16  0
		MOV		EAX,[YT2]
		MOV		EBP,[XT2]
		SUB		EAX,[YT1]   ; EAX = DY
		JZ		%%CasDYZ
		SUB		EBP,[XT1]   ; EBP = DX
		JZ		%%CasDXZ
%%CasNorm:	@ClipTextBlndHLineNorm16
		JMP		%%FinInTextHLg
%%CasDXZ:	@ClipTextBlndHLineDXZ16
		JMP		%%FinInTextHLg
%%CasDYZ:	@ClipTextBlndHLineDYZ16
%%FinInTextHLg:
%endmacro

%macro	@ClipTextBlndHLineNorm16 0
		SHL 		EAX,Prec
		MOV		ESI,[YT1]      ; - 1'
		CMP		DWORD [Plus2],0
		JZ		%%PDivPPlusY
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusY
%%PDivPPlusY:	XOR		EAX,EAX
%%DivPPlusY:
		IMUL		ESI,[SScanLine]    ; - 2'
		NEG		EAX
		MOV		[PntPlusY],EAX  ;[PntPlusY]

		MOV		EAX,EBP
		XOR		EDX,EDX
		OR		EDX,BYTE 8
		NEG		ESI	       ; - 3'
		SHL		EAX,Prec
		ADD		ESI,[XT1]      ; - 4'
		ADD		ESI,[XT1]      ; - 4' +2*XT : 16bpp
		MOVD		mm5,EDX
		ADD		ESI,[Svlfb]    ; - 5'
		CMP		DWORD [Plus2],0
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
%%BcStBAv:	TEST		EDI,6
		JZ		%%FPasStBAv
		@AjAdNormB16
		MOV		AX,[ESI+EBX]
		@SolidTextBlndW
		DEC		ECX
		STOSW
		JZ		%%FinSHLine

		JMP		%%BcStBAv
%%FPasStBAv:
		CMP		ECX,BYTE 3
		JLE		%%StBAp
%%PasStDAv:
		MOVD		mm3,ECX
		SHR		ECX,2
;ALIGN 4
%%StoMMX:       MOVD		mm1,EDI  ; save EDI
		@AjAdNormQ16
                MOVD		mm5,ECX   ; save ECX
		MOV		AX,[ESI+EBX] ; read word 0
		@AjAdNormQ16
		ROR		EAX,16 ; swap words order
		MOV		AX,[ESI+EBX] ; read word 1
		@AjAdNormQ16
		MOV		CX,[ESI+EBX] ; read word 2
		@AjAdNormQ16
		ROR		ECX,16
		ROR		EAX,16 ; words on the right order
		MOV		CX,[ESI+EBX] ; read byte 3
		MOVD		EDI,mm1  ; restore EDI
		ROR		ECX,16 ; word 2,3 on the right order
                MOVD            mm0,EAX ; first 4 bytes to write
                MOVD            mm1,ECX ; second 4 byte to write
		PUNPCKLDQ	mm0,mm1 ; make the full 8 bytes to write
                MOVD		ECX,mm5   ; restore ECX
		@SolidTextBlndQ
		MOVQ		[EDI],mm0 ; write the 8 bytes
		DEC		ECX
                LEA             EDI,[EDI+8]
		JNZ		%%StoMMX

		MOVD		ECX,mm3
		AND		ECX,BYTE 3
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdNormB16
		MOV		AX,[ESI+EBX]
		@SolidTextBlndW
		DEC		ECX
		STOSW
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;*******************************************************************
%macro	@ClipTextBlndHLineDXZ16  0
		MOV		ESI,[YT1]   ; - 1
		SHL		EAX,Prec
		IMUL		ESI,[SScanLine] ; - 2
		CMP		DWORD [Plus2],0
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
		ADD		ESI,[XT1]   ; - 4(2) 16bpp
		IMUL		EDX,EBP ;-[PntPlusY] axe Y montant
		OR		EAX,EAX
		JLE		%%PosPntPlusY
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusY:
%%BcStBAv:	TEST		EDI,6
		JZ		%%FPasStBAv
		@AjAdDXZ16
		MOV		AX,[ESI+EBX]
		@SolidTextBlndW
		DEC		ECX
		STOSW
		JZ		%%FinSHLine

		JMP		%%BcStBAv
%%FPasStBAv:
		CMP		ECX,BYTE 3
		JLE		%%StBAp
%%PasStDAv:
		MOVD		mm3,ECX
		SHR		ECX,2
;ALIGN 4
%%StoMMX:	@AjAdDXZ16
                MOVD            mm5, ECX   ; save ECX
		MOV		AX,[ESI+EBX] ; read word 0
		@AjAdDXZ16
		ROR		EAX,16
		MOV		AX,[ESI+EBX] ; read word 1
		@AjAdDXZ16
		MOV		CX,[ESI+EBX] ; read word 2
		@AjAdDXZ16
		ROR		ECX,16
		ROR		EAX,16
		MOV		CX,[ESI+EBX] ; read word 3
		ROR		ECX,16
		MOVD		mm0, EAX ; first 4 bytes to write
		MOVD		mm1, ECX ; second 4 bytes to write
		PUNPCKLDQ	mm0,mm1 ; make the full 8 bytes to write
		MOVD		ECX, mm5   ; restore ECX
		@SolidTextBlndQ
		MOVQ		[EDI],mm0 ; write the 8 bytes
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX

		MOVD		ECX,mm3
		AND		ECX,BYTE 3
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdDXZ16
		MOV		AX,[ESI+EBX]
		@SolidTextBlndW
		DEC		ECX
		STOSW
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro


;********************************************************

%macro	@ClipTextBlndHLineDYZ16 0
		SUB		EBP,[XT1]
		MOV		ESI,[YT1]
		MOV		EAX,EBP
		SHL 		EAX,Prec
		CMP		DWORD [Plus2],0
		JZ		%%PDivPPlusY
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusY
%%PDivPPlusY:	XOR		EAX,EAX
%%DivPPlusY:
		MOV		EBP,EAX  ;[PntPlusX]
		IMUL		ESI,[SScanLine]
		MOV		EDX,[Plus]
		NEG		ESI
		IMUL		EDX,EBP ;+[PntPlusX]
		ADD		ESI,[XT1]
		ADD		ESI,[XT1] ; 16bpp
		ADD		ESI,[Svlfb]
		OR		EAX,EAX
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:
%%BcStBAv:	TEST		EDI,6
		JZ		%%FPasStBAv
		@AjAdDYZ16
		MOV		AX,[ESI+EBX*2]
		@SolidTextBlndW
		DEC		ECX
		STOSW
		JZ		%%FinSHLine

		JMP		%%BcStBAv
%%FPasStBAv:
		CMP		ECX,BYTE 3
		JLE		%%StBAp
%%PasStDAv:
		MOVD		mm3,ECX
		SHR		ECX,2
;ALIGN 4
%%StoMMX:	@AjAdDYZ16
		MOV		AX,[ESI+EBX*2] ; read word 0
		@AjAdDYZ16
		ROR		EAX,16 ; reverse words order
                MOVD            mm5,ECX  ; save ECX
		MOV		AX,[ESI+EBX*2] ; read word 1
		@AjAdDYZ16
		MOV		CX,[ESI+EBX*2]  ; read word 2
		@AjAdDYZ16
		ROR		ECX,16
		ROR		EAX,16 ; back to right words order
		MOV		CX,[ESI+EBX*2]  ; read word 3
		ROR		ECX,16
		MOVD            mm0,EAX  ; first 4 bytes to write
		MOVD            mm1,ECX  ; second 4 bytes to write
		PUNPCKLDQ	mm0,mm1 ; make the full 8 bytes to write
		MOVD            ECX,mm5  ; restore ECX
		@SolidTextBlndQ
		MOVQ		[EDI],mm0 ; write the 8 bytes
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX

		MOVD		ECX,mm3
		AND		ECX,BYTE 3
		JZ		%%FinSHLine
%%StBAp:
%%BcStBAp:	@AjAdDYZ16
		MOV		AX,[ESI+EBX*2]
		@SolidTextBlndW
		DEC		ECX
		STOSW
		JNZ		%%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro


;****** MASKTEXT BLEND
;**IN*TEXTure Horizontal Line***********************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2)
; a ne pas utiliser mm6 & mm7
; utilise mm5,mm4,mm3,mm2,mm1,mm0
;***************************************************************************
%macro	@InMaskTextBlndHLine16  0
		MOV		EAX,[YT2]
		MOV		EBP,[XT2]
		SUB		EAX,[YT1]   ; EAX = DY
		JZ		%%CasDYZ
		SUB		EBP,[XT1]   ; EBP = DX
		JZ		%%CasDXZ
%%CasNorm:	@InMaskTextBlndHLineNorm16
		JMP		%%FinInTextHLg
%%CasDXZ:	@InMaskTextBlndHLineDXZ16
		JMP		%%FinInTextHLg
%%CasDYZ:	@InMaskTextBlndHLineDYZ16
%%FinInTextHLg:
%endmacro

; AX : DYT, EBP : DXT

%macro	@InMaskTextBlndHLineNorm16 0
		MOV		ESI,[YT1]      ; - 1
		SHL 		EAX,Prec
		CDQ
		IMUL		ESI,[SScanLine]    ; - 2
		OR		ECX,ECX
		JZ		%%PDivPntPY
		IDIV		ECX
		JMP		SHORT %%DivPntPY
%%PDivPntPY:	XOR		EAX,EAX
%%DivPntPY:
		NEG		ESI	       ; - 3
		NEG		EAX
		ADD		ESI,[XT1]      ; - 4
		MOV		[PntPlusY],EAX  ;[PntPlusY]
		ADD		ESI,[XT1]      ; - 4(2) as 16bpp

		MOV		EAX,EBP

		ADD		ESI,[Svlfb]    ; - 5
		SHL		EAX,Prec
		CDQ
		OR		ECX,ECX
		JZ		%%PDivPntPX
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

		
%%BcStBAv:	TEST		CL,3
		JZ		%%FPasStBAv
		@AjAdNormB16
		MOV		AX,[EBX+ESI]
		CMP		AX,[SMask]
		JZ		%%NoDW
		@SolidTextBlndW
		MOV		[EDI],AX
%%NoDW:
		DEC		ECX
		LEA		EDI,[EDI+2]
		
		JZ		%%FinSHLine

		JMP		%%BcStBAv
%%FPasStBAv:
		SHR		ECX,2
		JZ		%%FinSHLine
;ALIGN 4
%%StoMMX:	MOVD		mm5,EDI  ; save EDI in mm5
		@AjAdNormQ16
                MOVD		mm3,ECX   ; save ECX
		MOV		AX,[ESI+EBX] ; read word 0
		@AjAdNormQ16
		ROR		EAX,16 ; move first word to upper EAX word
		MOV		CX,[ESI+EBX] ; read word 1
		@AjAdNormQ16
		ROR		ECX,16
		MOV		AX,[ESI+EBX] ; read word 2
		@AjAdNormQ16
		ROR		EAX,16 ; EAX words on the right order
		MOV		CX,[ESI+EBX] ; read byte 3
		MOVD		EDI,mm5 ; restore EDI
		ROR		ECX,16   ; ; ECX words on the right order
		MOVD            mm0,EAX ; first 4 bytes to write
		MOVD            mm4,ECX ; second 4 byte to write
		PUNPCKLWD	mm0,mm4 ; make the full 8 bytes to write
		MOVQ		mm4,mm0
		@SolidTextBlndQ
		MOVD		ECX,mm4
		MOVD		EAX,mm0
		CMP		CX,[SMask]
		PSRLQ		mm4,32
		JZ		%%NoDW1
		MOV		[EDI],AX

%%NoDW1:	SHR		ECX,16
		SHR		EAX,16
		CMP		CX,[SMask]
		PSRLQ		mm0,32
		JZ		%%NoDW2
		MOV		[EDI+2],AX
%%NoDW2:
		MOVD		ECX,mm4
		MOVD		EAX,mm0
		CMP		CX,[SMask]
		JZ		%%NoDW3
		MOV		[EDI+4],AX
%%NoDW3:	SHR		ECX,16
		SHR		EAX,16
		CMP		CX,[SMask]
		JZ		%%NoDW4
		MOV		[EDI+6],AX
%%NoDW4:
		MOVD		ECX,mm3   ; restore ECX
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX

%%FinSHLine:
%endmacro



;********************************************************

%macro	@InMaskTextBlndHLineDXZ16  0
		MOV		ESI,[YT1]    ; - 1
		SHL		EAX,Prec
		CDQ
		IMUL		ESI,[SScanLine]  ; - 2
		OR		ECX,ECX
		JZ		%%PDivPntPX
		IDIV		ECX
		JMP		SHORT %%DivPntPX
%%PDivPntPX:	XOR		EAX,EAX
%%DivPntPX:
		NEG		ESI	     ; - 3
		MOV		EBP,EAX ; [PntPlusY]
		ADD		ESI,[XT1]    ; - 4
		XOR		EBX,EBX      ; Cpt Dbrd Y
		ADD		ESI,[XT1]    ; - 4 (+XT1*2) as 16bpp
		OR		EAX,EAX
		ADD		ESI,[Svlfb]  ; - 5
		SETG		BL
		INC		ECX
		MOV		EDX,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr Y
%%BcStBAv:	TEST		CL,3
		JZ		%%FPasStBAv
		@AjAdDXZ16
		MOV		AX,[ESI+EBX]
		CMP		AX,[SMask]
		JZ		%%NoDW
		@SolidTextBlndW
		MOV		[EDI],AX
%%NoDW:
		DEC		ECX
		LEA		EDI,[EDI+2]
		JZ		%%FinSHLine

		JMP		%%BcStBAv
%%FPasStBAv:
		SHR		ECX,2
		JZ		%%FinSHLine
;ALIGN 4
%%StoMMX:	@AjAdDXZ16
                MOVD            mm3, ECX   ; save ECX
		MOV		AX,[ESI+EBX] ; read word 0
		@AjAdDXZ16
		ROR		EAX,16
		MOV		CX,[ESI+EBX] ; read word 1
		@AjAdDXZ16
		ROR		ECX,16
		MOV		AX,[ESI+EBX] ; read word 2
		@AjAdDXZ16
		MOV		CX,[ESI+EBX] ; read word 3
		ROR		EAX,16 ; EAX right order
		ROR		ECX,16 ; ECX right order
		MOVD		mm0, EAX ; first 4 bytes to write
		MOVD		mm1, ECX ; second 4 bytes to write
		PUNPCKLWD	mm0,mm1 ; make the full 8 bytes to write
		MOVQ		mm4,mm0
		@SolidTextBlndQ

		MOVD		ECX,mm4
		MOVD		EAX,mm0
		CMP		CX,[SMask]
		PSRLQ		mm4,32
		JZ		%%NoDW1
		MOV		[EDI],AX
%%NoDW1:	SHR		ECX,16
		SHR		EAX,16
		CMP		CX,[SMask]
		PSRLQ		mm0,32
		JZ		%%NoDW2
		MOV		[EDI+2],AX
%%NoDW2:
		MOVD		ECX,mm4
		MOVD		EAX,mm0
		CMP		CX,[SMask]
		JZ		%%NoDW3
		MOV		[EDI+4],AX
%%NoDW3:	SHR		ECX,16
		SHR		EAX,16
		CMP		CX,[SMask]
		JZ		%%NoDW4
		MOV		[EDI+6],AX
%%NoDW4:
		MOVD		ECX,mm3   ; restore ECX
		DEC		ECX
		LEA		EDI,[EDI+8]
		
		JNZ		%%StoMMX

%%FinSHLine:
%endmacro

;%macro  @AjAdDXZ16  0
;		MOV		EBX,EDX
;		SAR		EBX,Prec
;		SUB		EDX,EBP ;-[PntPlusY]
;		IMUL		EBX,[SScanLine]
;%endmacro
;********************************************************

%macro	@InMaskTextBlndHLineDYZ16 0
		SUB		EBP,[XT1]
		MOV		ESI,[YT1]   ; - 1
		MOV		EAX,EBP
		IMUL		ESI,[SScanLine] ; - 2
		SHL 		EAX,Prec
		NEG		ESI	    ; - 3
		CDQ
		ADD		ESI,[XT1]   ; - 4
		ADD		ESI,[XT1]   ; - 4 + (XT1*2) as 16bpp
		OR		ECX,ECX
		JZ		%%PDivPntPX
		IDIV		ECX
		JMP		SHORT %%DivPntPX
%%PDivPntPX:	XOR		EAX,EAX
%%DivPntPX:
		XOR		EBX,EBX      ; Cpt Dbrd Y
		ADD		ESI,[Svlfb] ; - 5
		OR		EAX,EAX			; SAR
		MOV		EBP,EAX  ;[PntPlusX]
		SETL		BL
		INC		ECX
		MOV		EDX,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr Y
%%BcStBAv:	TEST		CL,3
		JZ		%%FPasStBAv
		@AjAdDYZ16
		MOV		AX,[ESI+EBX*2]
		CMP		AX,[SMask]
		JZ		%%NoDW
		@SolidTextBlndW
		MOV		[EDI],AX
%%NoDW:
		DEC		ECX
		LEA		EDI,[EDI+2]
		JZ		%%FinSHLine

		JMP		%%BcStBAv
%%FPasStBAv:
		SHR		ECX,2
		JZ		%%FinSHLine
;ALIGN 4
%%StoMMX:	@AjAdDYZ16
		MOVD		mm3,ECX  ; save ECX
		MOV		AX,[ESI+EBX*2] ; read word 0
		@AjAdDYZ16
		ROR		EAX,16
		MOV		CX,[ESI+EBX*2] ; read word 1
		@AjAdDYZ16
		ROR		ECX,16
		MOV		AX,[ESI+EBX*2]  ; read word 2
		@AjAdDYZ16
		MOV		CX,[ESI+EBX*2]  ; read word 3
		ROR		EAX,16 ; right order
		ROR		ECX,16 ; right order
		MOVD		mm0,EAX  ; first 4 bytes to write
		MOVD		mm1,ECX  ; second 4 bytes to write
		PUNPCKLWD	mm0,mm1 ; make the full 8 bytes to write
		MOVQ		mm4,mm0
		@SolidTextBlndQ
		MOVD		ECX,mm4
		MOVD		EAX,mm0
		CMP		CX,[SMask]
		PSRLQ		mm4,32
		JZ		%%NoDW1
		MOV		[EDI],AX
%%NoDW1:	SHR		ECX,16
		SHR		EAX,16
		CMP		CX,[SMask]
		PSRLQ		mm0,32
		JZ		%%NoDW2
		MOV		[EDI+2],AX
%%NoDW2:
		MOVD		ECX,mm4
		MOVD		EAX,mm0
		CMP		CX,[SMask]
		JZ		%%NoDW3
		MOV		[EDI+4],AX
%%NoDW3:	SHR		ECX,16
		SHR		EAX,16
		CMP		CX,[SMask]
		JZ		%%NoDW4
		MOV		[EDI+6],AX
%%NoDW4:
		MOVD		ECX,mm3   ; restore ECX
		DEC		ECX
		LEA		EDI,[EDI+8]
		
		JNZ		%%StoMMX

%%FinSHLine:
%endmacro

;%macro  @AjAdDYZ16  0
;		MOV		EBX,EDX
;		SAR		EBX,Prec
;		ADD		EDX,EBP ;+[PntPlusX]
;%endmacro

;**Clip*TEXTure Horizontal Line***********************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2)
; a ne pas utiliser mm6 & mm7 & mm3 & mm4
;***************************************************************************
%macro	@ClipMaskTextBlndHLine16  0
		MOV		EAX,[YT2]
		MOV		EBP,[XT2]
		SUB		EAX,[YT1]   ; EAX = DY
		JZ		%%CasDYZ
		SUB		EBP,[XT1]   ; EBP = DX
		JZ		%%CasDXZ
%%CasNorm:	@ClipMaskTextBlndHLineNorm16
		JMP		%%FinInTextHLg
%%CasDXZ:	@ClipMaskTextBlndHLineDXZ16
		JMP		%%FinInTextHLg
%%CasDYZ:	@ClipMaskTextBlndHLineDYZ16
%%FinInTextHLg:
%endmacro

%macro	@ClipMaskTextBlndHLineNorm16 0
		SHL 		EAX,Prec
		MOV		ESI,[YT1]      ; - 1'
		CMP		DWORD [Plus2],0
		JZ		%%PDivPPlusY
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusY
%%PDivPPlusY:	XOR		EAX,EAX
%%DivPPlusY:
		IMUL		ESI,[SScanLine]    ; - 2'
		NEG		EAX
		MOV		[PntPlusY],EAX  ;[PntPlusY]

		MOV		EAX,EBP
		XOR		EDX,EDX
		OR		EDX,BYTE 8
		NEG		ESI	       ; - 3'
		SHL		EAX,Prec
		ADD		ESI,[XT1]      ; - 4'
		ADD		ESI,[XT1]      ; - 4' +2*XT : 16bpp
		MOVD		mm5,EDX
		ADD		ESI,[Svlfb]    ; - 5'
		CMP		DWORD [Plus2],0
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
%%BcStBAv:	TEST		CL,3
		JZ		%%FPasStBAv
		@AjAdNormB16
		MOV		AX,[ESI+EBX]
		CMP		AX,[SMask]
		JZ		%%NoDW
		@SolidTextBlndW
		MOV		[EDI],AX
%%NoDW:
		DEC		ECX
		LEA		EDI,[EDI+2]
		JZ		%%FinSHLine

		JMP		%%BcStBAv
%%FPasStBAv:
		SHR		ECX,2
		JZ		%%FinSHLine
;ALIGN 4
%%StoMMX:       MOVD		mm1,EDI  ; save EDI
		@AjAdNormQ16
                MOVD		mm5,ECX   ; save ECX
		MOV		AX,[ESI+EBX] ; read word 0
		@AjAdNormQ16
		ROR		EAX,16 ; swap words order
		MOV		AX,[ESI+EBX] ; read word 1
		@AjAdNormQ16
		MOV		CX,[ESI+EBX] ; read word 2
		@AjAdNormQ16
		ROR		ECX,16
		ROR		EAX,16 ; words on the right order
		MOV		CX,[ESI+EBX] ; read byte 3
		MOVD		EDI,mm1  ; restore EDI
		ROR		ECX,16 ; word 2,3 on the right order
                MOVD            mm0,EAX ; first 4 bytes to write
                MOVD            mm1,ECX ; second 4 byte to write
		PUNPCKLDQ	mm0,mm1 ; make the full 8 bytes to write
		MOVQ		mm4,mm0

		@SolidTextBlndQ
		MOVD		ECX,mm4
		MOVD		EAX,mm0
		CMP		CX,[SMask]
		PSRLQ		mm4,32
		JZ		%%NoDW1
		MOV		[EDI],AX
%%NoDW1:	SHR		ECX,16
		SHR		EAX,16
		CMP		CX,[SMask]
		PSRLQ		mm0,32
		JZ		%%NoDW2
		MOV		[EDI+2],AX
%%NoDW2:
		MOVD		ECX,mm4
		MOVD		EAX,mm0
		CMP		CX,[SMask]
		JZ		%%NoDW3
		MOV		[EDI+4],AX
%%NoDW3:	SHR		ECX,16
		SHR		EAX,16
		CMP		CX,[SMask]
		JZ		%%NoDW4
		MOV		[EDI+6],AX
%%NoDW4:
		MOVD		ECX,mm5   ; restore ECX
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		%%StoMMX

%%FinSHLine:
%endmacro

;*******************************************************************
%macro	@ClipMaskTextBlndHLineDXZ16  0
		MOV		ESI,[YT1]   ; - 1
		SHL		EAX,Prec
		IMUL		ESI,[SScanLine] ; - 2
		CMP		DWORD [Plus2],0
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
		ADD		ESI,[XT1]   ; - 4(2) 16bpp
		IMUL		EDX,EBP ;-[PntPlusY] axe Y montant
		OR		EAX,EAX
		JLE		%%PosPntPlusY
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusY:
%%BcStBAv:	TEST		CL,3
		JZ		%%FPasStBAv
		@AjAdDXZ16
		MOV		AX,[ESI+EBX]
		CMP		AX,[SMask]
		JZ		%%NoDW
		@SolidTextBlndW
		MOV		[EDI],AX
%%NoDW:
		DEC		ECX
		LEA		EDI,[EDI+2]
		JZ		%%FinSHLine

		JMP		%%BcStBAv
%%FPasStBAv:
		SHR		ECX,2
		JZ		%%FinSHLine
;ALIGN 4
%%StoMMX:	@AjAdDXZ16
		MOVD		mm5, ECX   ; save ECX
		MOV		AX,[ESI+EBX] ; read word 0
		@AjAdDXZ16
		ROR		EAX,16
		MOV		AX,[ESI+EBX] ; read word 1
		@AjAdDXZ16
		MOV		CX,[ESI+EBX] ; read word 2
		@AjAdDXZ16
		ROR		ECX,16
		ROR		EAX,16
		MOV		CX,[ESI+EBX] ; read word 3
		ROR		ECX,16
		MOVD		mm0, EAX ; first 4 bytes to write
		MOVD		mm1, ECX ; second 4 bytes to write
		PUNPCKLDQ	mm0,mm1 ; make the full 8 bytes to write
		MOVQ		mm4,mm0
		@SolidTextBlndQ
		MOVD		ECX,mm4
		MOVD		EAX,mm0
		CMP		CX,[SMask]
		PSRLQ		mm4,32
		JZ		%%NoDW1
		MOV		[EDI],AX
%%NoDW1:	SHR		ECX,16
		SHR		EAX,16
		CMP		CX,[SMask]
		PSRLQ		mm0,32
		JZ		%%NoDW2
		MOV		[EDI+2],AX
%%NoDW2:
		MOVD		ECX,mm4
		MOVD		EAX,mm0
		CMP		CX,[SMask]
		JZ		%%NoDW3
		MOV		[EDI+4],AX
%%NoDW3:	SHR		ECX,16
		SHR		EAX,16
		CMP		CX,[SMask]
		JZ		%%NoDW4
		MOV		[EDI+6],AX
%%NoDW4:
		MOVD		ECX,mm5   ; restore ECX
		DEC		ECX
		LEA		EDI,[EDI+8]
		
		JNZ		%%StoMMX

%%FinSHLine:
%endmacro


;********************************************************

%macro	@ClipMaskTextBlndHLineDYZ16 0
		SUB		EBP,[XT1]
		MOV		ESI,[YT1]
		MOV		EAX,EBP
		SHL 		EAX,Prec
		CMP		DWORD [Plus2],0
		JZ		%%PDivPPlusY
		CDQ
		IDIV		DWORD [Plus2]
		JMP		SHORT %%DivPPlusY
%%PDivPPlusY:	XOR		EAX,EAX
%%DivPPlusY:
		MOV		EBP,EAX  ;[PntPlusX]
		IMUL		ESI,[SScanLine]
		MOV		EDX,[Plus]
		NEG		ESI
		IMUL		EDX,EBP ;+[PntPlusX]
		ADD		ESI,[XT1]
		ADD		ESI,[XT1] ; 16bpp
		ADD		ESI,[Svlfb]
		OR		EAX,EAX
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:
%%BcStBAv:	TEST		CL,3
		JZ		%%FPasStBAv
		@AjAdDYZ16
		MOV		AX,[ESI+EBX*2]
		CMP		AX,[SMask]
		JZ		%%NoDW
		@SolidTextBlndW
		MOV		[EDI],AX
%%NoDW:
		DEC		ECX
		LEA		EDI,[EDI+2]
		JZ		%%FinSHLine

		JMP		%%BcStBAv
%%FPasStBAv:
		SHR		ECX,2
		JZ		%%FinSHLine
;ALIGN 4
%%StoMMX:	@AjAdDYZ16
		MOV		AX,[ESI+EBX*2] ; read word 0
		@AjAdDYZ16
		ROR		EAX,16 ; reverse words order
		MOVD		mm5,ECX  ; save ECX
		MOV		AX,[ESI+EBX*2] ; read word 1
		@AjAdDYZ16
		MOV		CX,[ESI+EBX*2]  ; read word 2
		@AjAdDYZ16
		ROR		ECX,16
		ROR		EAX,16 ; back to right words order
		MOV		CX,[ESI+EBX*2]  ; read word 3
		ROR		ECX,16
		MOVD            mm0,EAX  ; first 4 bytes to write
		MOVD            mm1,ECX  ; second 4 bytes to write
		PUNPCKLDQ	mm0,mm1 ; make the full 8 bytes to write
		MOVQ		mm4,mm0
		@SolidTextBlndQ
		MOVD		ECX,mm4
		MOVD		EAX,mm0
		CMP		CX,[SMask]
		PSRLQ		mm4,32
		JZ		%%NoDW1
		MOV		[EDI],AX
%%NoDW1:	SHR		ECX,16
		SHR		EAX,16
		CMP		CX,[SMask]
		PSRLQ		mm0,32
		JZ		%%NoDW2
		MOV		[EDI+2],AX
%%NoDW2:
		MOVD		ECX,mm4
		MOVD		EAX,mm0
		CMP		CX,[SMask]
		JZ		%%NoDW3
		MOV		[EDI+4],AX
%%NoDW3:	SHR		ECX,16
		SHR		EAX,16
		CMP		CX,[SMask]
		JZ		%%NoDW4
		MOV		[EDI+6],AX
%%NoDW4:
		MOVD		ECX,mm5   ; restore ECX
		DEC		ECX
		LEA		EDI,[EDI+8]
		
		JNZ		%%StoMMX

%%FinSHLine:
%endmacro


