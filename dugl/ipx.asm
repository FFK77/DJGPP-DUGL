%include "param.mac"

; GLOBAL Function*************************************************************
;*** IPX
GLOBAL _ReverseBuffBytes


; GLOBAL DATA*****************************************************************
;*** IPX

ALIGN 32
SECTION .text
[BITS 32]
;*** IPX

_ReverseBuffBytes:
	ARG	BuffPtr, 4, BuffSize, 4
		MOVD		mm0,ESI
		MOVD		mm1,EDI
		MOVD		mm2,EBX

		MOV		ECX,[EBP+BuffSize]
		MOV		ESI,[EBP+BuffPtr]
		LEA		EDI,[ESI+ECX-1]
		CMP		ECX,1
		JLE		.FinSwapBuff
		SHR		ECX,1
;ALIGN 4
.BcSwapBuff:	MOV		AL,[ESI]
		MOV		BL,[EDI]
		MOV		[EDI],AL
		MOV		[ESI],BL
		DEC		EDI
		DEC		ECX
		LEA		ESI,[ESI+1]
		JNZ		.BcSwapBuff
.FinSwapBuff:
		MOVD		ESI,mm0
		MOVD		EDI,mm1
		MOVD		EBX,mm2
		EMMS
		RETURN

ALIGN 32
SECTION	.data
;*** IPX data


