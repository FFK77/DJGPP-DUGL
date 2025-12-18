SECTION .text
[BITS 32]
; ENTETE DU DRIVER ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Signature		DD	"FSDR"		; FLAT SOUND DRIVER
SizeDrv			DD	FinDrv
Capabilities		DD	Out8|Out16|OutMono|OutStereo|In8|In16|InMono|InStereo|FullDuplex
Capabilities2		DD	0
SizeBuff                DD      0
Min8BitMono		DD	5000
Max8BitMono		DD	45454
Min16BitMono		DD	5000
Max16BitMono		DD	45454
Min8BitStereo		DD	5000
Max8BitStereo		DD	45454
Min16BitStereo		DD	5000
Max16BitStereo		DD	45454
SB_BasePort		DD	0
SB_IRQ			DD	0
SB_DMA8			DD	0
SB_DMA16		DD	0
SB_SampSpeed		DD	0
Error			DD	0
resv:			DD	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
			DD	0,0,0,0,0,0,0,0,0,0
PtrCardName		DD	CardName
GlobFonc:		DD	InitDriver,NS,NS,InitSound,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
VoiceMixer:		DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS

; CODE ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%include "param.mac"

InitDriver:
		PUSH		EBX
		PUSH		ESI
		PUSH		EDI

		; Patch des adresses des fonctions--- ***** -----------------
		; et de la procedure GetBaseAddress--------------------------
		CALL		.BaseAdressEIP  ; Base adress dans la pile
.BaseAdressEIP:	POP		EBX
		SUB		EBX,.BaseAdressEIP
		; patche l'instruction  MOV EBX,(0 -> adress base)
		MOV		[EBX+GetBaseAddress+1],EBX
		LEA		ESI,[EBX+PtrCardName]
		MOV		ECX,193
.BcPatchAdd:	ADD		[ESI],EBX
		DEC		ECX
		LEA		ESI,[ESI+4]
		JNZ		.BcPatchAdd

		POP		EDI
		POP		ESI
		POP		EBX
		RET


InitSound:
	ARG	Type8Bits, 4, Type16Bits, 4, GenType, 4, SampleSpeed, 4
		; Sampling Speed -------------------------------------------
		CALL		GetBaseAddress
		MOV		EAX,[EBP+SampleSpeed]
		MOV		[EBX+SB_SampSpeed],EAX
.InitSndOk:	OR		EAX,BYTE -1

		RETURN

GetBaseAddress:
		MOV		EBX,0
		RET

NS:		; fonction ((N)on (S)upporte) retourne 1 dans EAX
		MOV		EAX,1
		RET


; CONSTANT~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; ----- Capabilities ----------------
Out8			EQU	1
Out16			EQU	2
OutMono			EQU	4
OutStereo		EQU	8
In8			EQU	16
In16			EQU	32
InMono			EQU	64
InStereo		EQU	128
FullDuplex		EQU	256

; NOM DE LA CARTE ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CardName                DB      "No Sound",0
FinDrv:

