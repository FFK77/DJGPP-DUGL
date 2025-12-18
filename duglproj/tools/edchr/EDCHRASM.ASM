%include "param.mac"

; GLOBAL Function*************************************************************
;***
GLOBAL _RightShiftLine,_LeftShiftLine

; GLOBAL DATA*****************************************************************
;***

SECTION .text ALIGN 32
[BITS 32]
;***

_RightShiftLine:
	ARG	DD0PtrR, 4, DD1PtrR, 4
		MOVD		mm0,ESI
		MOVD		mm1,EDI
		MOVD		mm2,EBX

		MOV		ESI,[EBP+DD0PtrR]
		MOV		EDI,[EBP+DD1PtrR]
		MOV		EAX,[ESI]
		MOV		EBX,[EDI]
		SHLD		EBX,EAX,1
		SHL		EAX,1
		MOV		[EDI],EBX
		MOV		[ESI],EAX

		MOVD		ESI,mm0
		MOVD		EDI,mm1
		MOVD		EBX,mm2
		EMMS
		RETURN

_LeftShiftLine:
	ARG	DD0PtrL, 4, DD1PtrL, 4
		MOVD		mm0,ESI
		MOVD		mm1,EDI
		MOVD		mm2,EBX

		MOV		ESI,[EBP+DD0PtrL]
		MOV		EDI,[EBP+DD1PtrL]
		MOV		EAX,[ESI]
		MOV		EBX,[EDI]
		SHRD		EAX,EBX,1
		SHR		EBX,1
		MOV		[ESI],EAX
		MOV		[EDI],EBX

		MOVD		ESI,mm0
		MOVD		EDI,mm1
		MOVD		EBX,mm2
		EMMS
		RETURN

SECTION	.data  ALIGN 32
;*** data


