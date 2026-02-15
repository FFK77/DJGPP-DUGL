%include "param.mac"

; GLOBAL Function****
GLOBAL	_InRLE,_OutRLE,_SizeOutRLE,_InLZW

SECTION .text
[BITS 32]
ALIGN 32

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

	MMX_RETURN

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

		MOV		    EDX,[EBP+LenOutRLE]
		MOV		    EDI,[EBP+OutRLE]
		MOV		    ESI,[EBP+InBuffRLE]
		ADD		    EDX,EDI
.BcInRLE:
        LODSB
		CMP		    AL,0xC0
		JB		    .Isole
		MOV		    CL,AL
		AND		    CL,0x3f
		LODSB
		MOVZX		ECX,CL
		REP		    STOSB
		JMP		    SHORT .PasIsoleRLE
.Isole:
        STOSB
.PasIsoleRLE:
        CMP		    EDI,EDX
		JB 		    .BcInRLE

		POP		    ESI
		POP		    EDI
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

;END PCX

SECTION .bss   ALIGN=32
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

