%include "param.mac"

; GLOBAL Function*************************************************************
;*** BLUR
GLOBAL _Blur16,_TransfB8ToB16,_TransfB8ToB15,_TransfB16ToB8,_TransfB8ToB16Pal
;** DATA
GLOBAL _TrBuffImgSrc,_TrBuffImgDst,_TrImgResHz,_TrImgResVt,_TrBuffImgSrcPal
;** Extern DATA
EXTERN _Col8To15bpp,_Col8To16bpp,_Col8To32bpp,_Col15To8bpp

;** CONSTANT
Prec            EQU     12  ; precision of fixed calc
Div9		EQU	(1 << Prec)/9
Div6		EQU	(1 << Prec)/6
Blue16_MASK	EQU	0x1f
Green16_MASK	EQU	0x07e0
BGreen16_MASK	EQU	0x03e0
Red16_MASK	EQU	0xf800
; GLOBAL DATA*****************************************************************

ALIGN 32
SECTION .text
[BITS 32]


; convert a 8bpp paletted buffer to 16bpp (5:6:5:rgb) buffer
_TransfB8ToB16Pal:
		MOVD		mm5,EBP
                
		MOVD		mm0,ESI
		MOVD		mm1,EDI
		MOVD		mm2,EBX

		; valid params ?
		MOV             ESI,[_TrBuffImgSrc]
		MOV             EDI,[_TrBuffImgDst]
		OR              ESI,ESI
		MOV             EBP,[_TrImgResVt]
		JZ              .errorEnd
		OR              EDI,EDI
		MOV             EBX,[_TrImgResHz]
		JZ              .errorEnd
		OR              EBP,EBP
		JZ              .errorEnd
		OR              EBX,EBX
		JZ              .errorEnd

;-----------------
		IMUL		EBP,EBX
		XOR		ECX,ECX
		MOV		EBX,[_TrBuffImgSrcPal]
		MOVD		mm4,EBP
		SHR		EBP,1

.loop8To16B:
		MOV		CL,BYTE [ESI]
		MOV		EAX,[EBX+ECX*4]
		SHR		AH,2
		MOV		CL,BYTE [ESI+1] ; -
		ROR		EAX,3+11
		MOV		EDX,[EBX+ECX*4] ; -
		SHR		AX,3+2
		SHR		DH,2 ; -
		ROL		EAX,11
		ROR		EDX,3+11 ; -
		AND		EAX,0xFFFF
		SHR		DX,3+2 ; -
		ROL		EDX,11
		SHL		EDX,16
		OR		EAX,EDX
		
		ADD		ESI,BYTE 2
		MOV		[EDI],EAX
		DEC		EBP
		LEA		EDI,[EDI+4]
		JNZ		.loop8To16B

		MOVD		EBP,mm4
		AND		EBP,BYTE 1
		JZ		.errorEnd
		
		MOV		CL,BYTE [ESI]
		MOV		EAX,[EBX+ECX*4]
		SHR		AH,2
		ROR		EAX,3+11
		SHR		AX,3+2
		ROL		EAX,11
		MOV		[EDI],AX
.errorEnd:
		MOVD		ESI,mm0
		MOVD		EDI,mm1
		MOVD		EBX,mm2
		MOVD		EBP,mm5
		;EMMS

		RET

; convert a 8bpp paletted buffer to 16bpp (5:6:5:rgb) buffer
_TransfB8ToB16:
		MOVD		mm5,EBP
                
		MOVD		mm0,ESI
		MOVD		mm1,EDI
		MOVD		mm2,EBX

		; valid params ?
		MOV             ESI,[_TrBuffImgSrc]
		MOV             EDI,[_TrBuffImgDst]
		OR              ESI,ESI
		MOV             EBP,[_TrImgResVt]
		JZ              .errorEnd
		OR              EDI,EDI
		MOV             EBX,[_TrImgResHz]
		JZ              .errorEnd
		OR              EBP,EBP
		JZ              .errorEnd
		OR              EBX,EBX
		JZ              .errorEnd

		MOV		ECX,EBX
		IMUL		ECX,EBP
		PUSH		ECX
		SHR		ECX,2
.loop8To16:
		MOV		EAX,[ESI]
		MOV		EBX,[ESI]
		MOVD		mm4,EDI
		MOVZX		EBP,AL
		MOVZX		EDI,AH
		SHR		EBX,16
		XOR		EAX,EAX
		MOV		DX,[_Col8To16bpp+EDI*2]
		MOV		AX,[_Col8To16bpp+EBP*2]
		SHL		EDX,16
		MOVZX		EBP,BL
		OR		EAX,EDX
		MOVD		mm6,EAX
		MOVZX		EDI,BH
		XOR		EAX,EAX
		MOV		DX,[_Col8To16bpp+EDI*2]
		MOV		AX,[_Col8To16bpp+EBP*2]
		SHL		EDX,16
		OR		EAX,EDX
		MOVD		mm7,EAX
		;PSLLQ		mm7,32
		MOVD		EDI,mm4
		PUNPCKLDQ	mm6,mm7
		;POR		mm7,mm6
		ADD		ESI,BYTE 4
		MOVQ		[EDI],mm6
		DEC		ECX
		LEA		EDI,[EDI+8]
		JNZ		.loop8To16
		
		POP		ECX

		AND		ECX,BYTE 3
		JZ		.errorEnd
.loop8To16B:
		MOVZX		EBP,BYTE [ESI]
		MOV		AX,[_Col8To16bpp+EBP*2]
		MOV		WORD [EDI],AX
		INC		ESI
		DEC		ECX
		LEA		EDI,[EDI+2]
		JNZ		.loop8To16B
		
.errorEnd:
		MOVD		ESI,mm0
		MOVD		EDI,mm1
		MOVD		EBX,mm2
		MOVD		EBP,mm5
		;EMMS

		RET

_TransfB8ToB15:
		MOVD		mm5,EBP
                
		MOVD		mm0,ESI
		MOVD		mm1,EDI
		MOVD		mm2,EBX

		; valid params ?
		MOV             ESI,[_TrBuffImgSrc]
		MOV             EDI,[_TrBuffImgDst]
		OR              ESI,ESI
		MOV             EBP,[_TrImgResVt]
		JZ              .errorEnd
		OR              EDI,EDI
		MOV             EBX,[_TrImgResHz]
		JZ              .errorEnd
		OR              EBP,EBP
		JZ              .errorEnd
		OR              EBX,EBX
		JZ              .errorEnd

		MOV		ECX,EBX
		IMUL		ECX,EBP
		MOV		EBX,_Col8To15bpp ; EBX lookup conv Table
.loop8To15:
		MOVZX		EBP,BYTE [ESI]
		MOV		AX,[EBX+EBP*2]
		MOV		WORD [EDI],AX
		INC		ESI
		DEC		ECX
		LEA		EDI,[EDI+2]
		JNZ		.loop8To15
		
.errorEnd:
		MOVD		ESI,mm0
		MOVD		EDI,mm1
		MOVD		EBX,mm2
		MOVD		EBP,mm5
		;EMMS

		RET

_TransfB16ToB8:
		MOVD		mm5,EBP
                
		MOVD		mm0,ESI
		MOVD		mm1,EDI
		MOVD		mm2,EBX

		; valid params ?
		MOV             ESI,[_TrBuffImgSrc]
		MOV             EDI,[_TrBuffImgDst]
		OR              ESI,ESI
		MOV             EBP,[_TrImgResVt]
		JZ              .errorEnd
		OR              EDI,EDI
		MOV             EBX,[_TrImgResHz]
		JZ              .errorEnd
		OR              EBP,EBP
		JZ              .errorEnd
		OR              EBX,EBX
		JZ              .errorEnd

		MOV		ECX,EBX
		IMUL		ECX,EBP
		MOV		EBX,_Col15To8bpp ; EBX lookup conv Table
.loop16To8:
		MOVZX		EDX,WORD [ESI]
		MOV		EBP,EDX; convert
		SHR		EBP,6
		AND		EDX,BYTE 0x1F
		SHL		EBP,5
		OR		EDX,EBP ; to 15bits
		LEA		ESI,[ESI+2]
		MOV		AL,[EBX+EDX]
		MOV		[EDI],AL
		DEC		ECX
		LEA		EDI,[EDI+1]
		JNZ		.loop16To8
		
.errorEnd:
		MOVD		ESI,mm0
		MOVD		EDI,mm1
		MOVD		EBX,mm2
		MOVD		EBP,mm5
		;EMMS

		RET

; BLUR MACRO

; param ESI: source, EBX: source ResH
; use EAX,EDX,EDI
; return EAX AVG 4 point ESI,ESI+2, ESI+ResH*2,ESI+ResH*2+2
%macro	AVG_4	2  ; %0 bit pos, %1 number of bits to take
	MOVZX		EAX,WORD [ESI]
	MOVZX		EDX,WORD [ESI+2]
	MOVZX		EDI,WORD [ESI+EBX*2]
        %if %1>0
	SHR		EAX,%1
	SHR		EDX,%1
	SHR		EDI,%1
     	%endif
	AND		EAX,BYTE (1<<%2)-1
	AND		EDX,BYTE (1<<%2)-1
	AND		EDI,BYTE (1<<%2)-1
	ADD		EAX,EDX
	ADD		EAX,EDI
	MOVZX		EDX,WORD [ESI+EBX*2+2]
	%if %1>0
	SHR		EDX,%1
	%endif
	AND		EDX,BYTE (1<<%2)-1
	ADD		EAX,EDX
	SHR		EAX,2 ; EAX~=EAX/4
%endmacro

; param ESI: source, EBX: source ResH
; use EAX,EDX,EDI
; return EAX AVG 6 points horizontal
%macro	AVG_6HB 0  ; %0 bit pos, %1 number of bits to take
	MOVQ		mm0,mm2
	MOVQ		mm1,mm5
	PAND		mm0,[QBlue16Mask]
	PAND		mm1,[QBlue16Mask]
	PADDW		mm0,mm1
	MOVD		EDX,mm0
	MOVD		EAX,mm0
	SHR		EDX,16
	AND		EAX,0xFFFF
	PSRLQ		mm0,32
	ADD		EAX,EDX
	MOVD		EDI,mm0
	AND		EDI,0xFFFF
	ADD		EAX,EDI
	
	MOVQ		mm0,mm2 ; AVG_6HG
	IMUL		EAX,Div6 ;
	MOVQ		mm1,mm5 ; AVG_6HG
	PAND		mm0,[QGreen16Mask] ; AVG_6HG
	SHR		EAX,Prec ; EAX~=EAX/6
	PAND		mm1,[QGreen16Mask] ; AVG_6HG
	AND		EAX,Blue16_MASK
	PADDW		mm0,mm1 ; AVG_6HG
%endmacro

%macro	AVG_6HG 0  ; %0 bit pos, %1 number of bits to take
	MOVD		EDX,mm0
	MOVD		EAX,mm0
	SHR		EDX,16
	AND		EAX,0xFFFF
	PSRLQ		mm0,32
	ADD		EAX,EDX
	MOVD		EDI,mm0
	AND		EDI,0xFFFF
	ADD		EAX,EDI
	
	MOVQ		mm0,mm2 ; AVG_6HR
	IMUL		EAX,Div6 ;
	MOVQ		mm1,mm5 ; AVG_6HR
	PAND		mm0,[QRed16Mask] ; AVG_6HR
	SHR		EAX,Prec ; EAX~=EAX/6
	PAND		mm1,[QRed16Mask] ; AVG_6HR
	AND		EAX,Green16_MASK
	PSRLW		mm0,5 ; AVG_6HR
	PSRLW		mm1,5 ; AVG_6HR
%endmacro

%macro	AVG_6HR 0  ; %0 bit pos, %1 number of bits to take
	PADDW		mm0,mm1
	MOVD		EDX,mm0
	MOVD		EAX,mm0
	SHR		EDX,16
	AND		EAX,0xFFFF
	PSRLQ		mm0,32
	ADD		EAX,EDX
	MOVD		EDI,mm0
	AND		EDI,0xFFFF
	ADD		EAX,EDI
	
	IMUL		EAX,Div6 ;
	SHR		EAX,Prec-5 ; EAX~=EAX/6
	AND		EAX,Red16_MASK
%endmacro


; param ESI: source, EBX: source ResH
; use EAX,EDX,EDI
; return EAX AVG 6 points vertical
%macro	AVG_6V 2  ; %0 bit pos, %1 number of bits to take
	MOVZX		EAX,WORD [ESI]
	MOVZX		EDX,WORD [ESI+2]
	MOVZX		EDI,WORD [ESI+EBX*2]
        %if %1>0
	SHR		EAX,%1
	SHR		EDX,%1
	SHR		EDI,%1
	%endif
	AND		EAX,BYTE (1<<%2)-1
	AND		EDX,BYTE (1<<%2)-1
	AND		EDI,BYTE (1<<%2)-1
	ADD		EAX,EDX
	ADD		EAX,EDI
	MOVZX		EDX,WORD [ESI+EBX*2+2]
	MOVZX		EDI,WORD [ESI+EBX*4]
	%if %1>0
	SHR		EDX,%1
	SHR		EDI,%1
	%endif
	AND		EDX,BYTE (1<<%2)-1
	AND		EDI,BYTE (1<<%2)-1
	ADD		EAX,EDX
	ADD		EAX,EDI
	MOVZX		EDX,WORD [ESI+EBX*4+2]
	%if %1>0
	SHR		EDX,%1
	%endif
	AND		EDX,BYTE (1<<%2)-1
	ADD		EAX,EDX
	IMUL		EAX,Div6 ;
	SHR		EAX,Prec ; EAX~=EAX/6
%endmacro

; param mm3, mm4, mm5 : source colors, EBX: source ResH

%macro	AVG_9VB  0
	MOVQ		mm0,mm3
	MOVQ		mm1,mm4
	MOVQ		mm2,mm5
	PAND		mm0,[QBlue16Mask]
	PAND		mm1,[QBlue16Mask]
	PAND		mm2,[QBlue16Mask]
	PADDW		mm0,mm1
	PADDW		mm0,mm2
	MOVQ		[LastAddMM_B],mm0
	MOVD		EAX,mm0
	MOVD		EDX,mm0
	AND		EAX,0xffff
	SHR		EDX,16
	PSRLQ		mm0,32
	ADD		EAX,EDX
	MOVD		EDX,mm0
	AND		EDX,0xffff
	ADD		EAX,EDX
	
	MOVQ		mm0,mm3 ; AVG_9VG
	IMUL		EAX,Div9 ;
	MOVQ		mm1,mm4 ; AVG_9VG
	MOVQ		mm2,mm5 ; AVG_9VG
	SHR		EAX,Prec ; EAX~=EAX/9
	AND		EAX,Blue16_MASK
%endmacro

%macro	AVG_9VG  0  ; %0 bit pos, %1 number of bits to take
	PAND		mm3,[QRed16Mask]
	PAND		mm4,[QRed16Mask]
	PAND		mm5,[QRed16Mask]
	PSRLW		mm3,5
	PAND		mm0,[QGreen16Mask]
	PSRLW		mm4,5
	PAND		mm1,[QGreen16Mask]
	PSRLW		mm5,5
	PAND		mm2,[QGreen16Mask]
	PADDW		mm0,mm1
	PADDW		mm4,mm3
	PADDW		mm0,mm2
	PADDW		mm4,mm5
	MOVQ		mm3,mm0 ; mm3 = LastAddMM_G
	MOVD		EAX,mm0
	MOVD		EDX,mm0
	AND		EAX,0xffff
	SHR		EDX,16
	PSRLQ		mm0,32
	ADD		EAX,EDX
	MOVQ		mm5,mm4 ; mm5 = LastAddMM_R
	MOVD		EDX,mm0
	AND		EDX,0xffff
	ADD		EAX,EDX
	
	IMUL		EAX,Div9 ;
	SHR		EAX,Prec ; EAX~=EAX/9 => -1 to get 6bits
	AND		EAX,Green16_MASK
%endmacro

%macro	AVG_9VR  0  ; %0 bit pos, %1 number of bits to take
	MOVD		EAX,mm4
	MOVD		EDX,mm4
	AND		EAX,0xffff
	SHR		EDX,16
	PSRLQ		mm4,32
	ADD		EAX,EDX
	MOVD		EDX,mm4
	AND		EDX,0xffff
	ADD		EAX,EDX
	
	MOVQ		mm0,[LastAddMM_B] ; AVG_9VB2
	IMUL		EAX,Div9 ;
	PSRLQ		mm0,16	; AVG_9VB2
	SHR		EAX,Prec-5; EAX~=EAX/9
	AND		EAX,Red16_MASK
%endmacro


%macro	AVG_9VB2  0
	MOVD		EAX,mm0
	MOVD		EDX,mm0
	AND		EAX,0xffff
	SHR		EDX,16
	PSRLQ		mm0,32
	ADD		EAX,EDX
	MOVD		EDX,mm0
	ADD		EAX,EDX
	
	IMUL		EAX,Div9 ;
	SHR		EAX,Prec ; EAX~=EAX/9
	AND		EAX,Blue16_MASK
%endmacro

%macro	AVG_9VG2  0  ; %0 bit pos, %1 number of bits to take
	MOVD		EAX,mm3
	MOVD		EDX,mm3
	AND		EAX,0xffff
	SHR		EDX,16
	PSRLQ		mm3,32
	ADD		EAX,EDX
	MOVD		EDX,mm3
	ADD		EAX,EDX
	
	IMUL		EAX,Div9 ;
	SHR		EAX,Prec ; EAX~=EAX/9 => -1 to get 6bits
	AND		EAX,Green16_MASK
%endmacro

%macro	AVG_9VR2  0  ; %0 bit pos, %1 number of bits to take
	MOVD		EAX,mm5
	MOVD		EDX,mm5
	AND		EAX,0xffff
	SHR		EDX,16
	PSRLQ		mm5,32
	ADD		EAX,EDX
	MOVD		EDX,mm5
	ADD		EAX,EDX
	
	IMUL		EAX,Div9 ;
	SHR		EAX,Prec-5; EAX~=EAX/9
	AND		EAX,Red16_MASK
%endmacro

_Blur16:
		PUSH		ESI
		PUSH		EDI
		PUSH		EBX
		PUSH		EBP

                ; valid params ?
                MOV             ESI,[_TrBuffImgSrc]
                MOV             EDI,[_TrBuffImgDst]
                OR              ESI,ESI
                MOV             EBP,[_TrImgResVt]
                JZ              .errorEnd
                OR              EDI,EDI
                MOV             EBX,[_TrImgResHz]
                JZ              .errorEnd
                OR              EBP,EBP
                JZ              .errorEnd
                OR              EBX,EBX
                JZ              .errorEnd

                MOV             EAX,2
                MOVD            mm3,EDI ; mm3, EDI
                MOVD            mm4,EAX ; mm4 EDI step +2

; BLUR first Horizontal Line ---------------------------------------------
; all params ok :)
; first pixel line 1 -------------------------------------
		AVG_4		0,5 ; red AVG
		MOVD		mm6,EAX
		AVG_4		5,6 ; green comp
		SHL		EAX,5
		MOVD		mm7,EAX
		AVG_4		11,5 ; blue comp
		POR		mm6,mm7
		SHL		EAX,11
		MOVD		EDX,mm6
		OR		EAX,EDX
		MOVD		EDI,mm3
		MOV		[EDI],AX
		PADDD		mm3,mm4 ; EDI += 2
; first line loop ----------------------------------

		LEA		ECX,[EBX-2]
.loopLine1:
		MOVQ		mm2,[ESI]
		MOVQ		mm5,[ESI+EBX*2]

		AVG_6HB		;0,5 ; blue AVG
		MOVD		mm6,EAX
		AVG_6HG		;5,6 ; green comp
		MOVD		mm7,EAX
		AVG_6HR		;11,5 ; red comp
		POR		mm6,mm7
		MOVD		EDX,mm6
		PSRLQ		mm2,16 ; next 3 words
		OR		EAX,EDX
		MOVD		EDI,mm3 ; restore dest EDI
		LEA		ESI,[ESI+2] ; increment source
		MOV		[EDI],AX
		DEC		ECX
		PADDD		mm3,mm4 ; EDI(dest) += 2
		JZ		.EndloopLine1
		
		PSRLQ		mm5,16 ; next 3 words
		AVG_6HB		;0,5 ; blue AVG
		MOVD		mm6,EAX
		AVG_6HG		;5,6 ; green comp
		MOVD		mm7,EAX
		AVG_6HR		;11,5 ; red comp
		POR		mm6,mm7
		MOVD		EDX,mm6
		MOVD		EDI,mm3 ; restore dest EDI
		OR		EAX,EDX
		LEA		ESI,[ESI+2] ; increment source
		MOV		[EDI],AX
		DEC		ECX
		PADDD		mm3,mm4 ; EDI(dest) += 2
		JNZ		.loopLine1
.EndloopLine1:

; last pixel line 1 --------------------------------------
		AVG_4		0,5 ; red AVG
		MOVD		mm6,EAX
		AVG_4		5,6 ; green comp
		SHL		EAX,5
		MOVD		mm7,EAX
		AVG_4		11,5 ; blue comp
		POR		mm6,mm7
		SHL		EAX,11
		MOVD		EDX,mm6
		MOVD		EDI,mm3
		OR		EAX,EDX
		MOV		ESI,[_TrBuffImgSrc] ; restore source adress
		MOV		[EDI],AX
		PADDD		mm3,mm4 ; EDI += 2 - jump to the next line
; END BLUR first Horizontal Line ------------------------------------------


; BLUR (ResVt-2) Middle Horizontal Lines -----------------------------------

		SUB		EBP,2 ; EBP the counter for the middle lines
.MidLinesLoop:
; first pixel middle line
		AVG_6V		0,5 ; red AVG
		MOVD		mm6,EAX
		AVG_6V		5,6 ; green comp
		SHL		EAX,5
		MOVD		mm7,EAX
		AVG_6V		11,5 ; blue comp
		POR		mm6,mm7
		SHL		EAX,11
		MOVD		EDX,mm6
		OR		EAX,EDX
		
		MOVD		EDI,mm3
		MOV		[EDI],AX
		PADDD		mm3,mm4 ; EDI += 2
		LEA		EDI,[EDI+2]

		LEA             ECX,[EBX-2]  ; resHz - 2
.loopMidLines:
		MOVQ		mm3,[ESI]
		MOVQ		mm4,[ESI+EBX*2]
		MOVQ		mm5,[ESI+EBX*4]
		AVG_9VB		 ; blue
		MOVD		mm6,EAX
		AVG_9VG		; green comp
		MOVD		mm7,EAX
		AVG_9VR		; red
		POR		mm6,mm7
		PSRLQ		mm3,16 ; next word 0
		MOVD		EDX,mm6
		PSRLQ		mm5,16 ; next word 0
		OR		EAX,EDX

		LEA		ESI,[ESI+2] ; increment source
		DEC		ECX
		STOSW
		JZ		.endMidLines

		AVG_9VB2		 ; blue
		MOVD		mm6,EAX
		AVG_9VG2		; green comp
		MOVD		mm7,EAX
		AVG_9VR2	; red
		POR		mm6,mm7
		MOVD		EDX,mm6
		OR		EAX,EDX

		LEA		ESI,[ESI+2] ; increment source
		DEC		ECX
		STOSW
		JNZ		.loopMidLines

		;JMP		.loopMidLines
.endMidLines:

                MOV             EAX,2
		MOVD		mm3,EDI
                MOVD            mm4,EAX ; mm4 EDI step +2
		
; last pixel middle line
		AVG_6V		0,5 ; red AVG
		MOVD		mm6,EAX
		AVG_6V		5,6 ; green comp
		SHL		EAX,5
		MOVD		mm7,EAX
		AVG_6V		11,5 ; blue comp
		POR		mm6,mm7
		SHL		EAX,11
		MOVD		EDX,mm6
		OR		EAX,EDX
                LEA             ESI,[ESI+4] ; go to next hz line
                MOVD            EDI,mm3
                MOV             [EDI],AX
                PADDD           mm3,mm4 ; EDI += 2

                DEC             EBP
                JNZ             .MidLinesLoop
; END BLUR (ResVt-2) Middle Horizontal Lines -------------------------------

; BLUR last line -----------------------------------------------------------
; first pixel last line 1 --------------------------
		AVG_4		0,5 ; blue AVG
		MOVD		mm6,EAX
		AVG_4		5,6 ; green comp
		SHL		EAX,5
		MOVD		mm7,EAX
		AVG_4		11,5 ; red comp
		POR		mm6,mm7
		SHL		EAX,11
		MOVD		EDX,mm6
		OR		EAX,EDX
		MOVD		EDI,mm3
		MOV		[EDI],AX
		PADDD		mm3,mm4 ; EDI += 2
; first line loop ----------------------------------
		LEA		ECX,[EBX-2]
.looplastLine:
		MOVQ		mm2,[ESI]
		MOVQ		mm5,[ESI+EBX*2]
		AVG_6HB		;0,5 ; blue AVG
		MOVD		mm6,EAX
		AVG_6HG		;5,6 ; green comp
		MOVD		mm7,EAX
		AVG_6HR		;11,5 ; red comp
		POR		mm6,mm7
		MOVD		EDX,mm6
		PSRLQ		mm2,16 ; next 3 words
		OR		EAX,EDX
		MOVD		EDI,mm3 ; restore dest EDI
		LEA		ESI,[ESI+2] ; increment source
		MOV		[EDI],AX
		DEC		ECX
		PADDD		mm3,mm4 ; EDI(dest) += 2
		JZ		.EndlooplastLine
		
		PSRLQ		mm5,16 ; next 3 words
		AVG_6HB		;0,5 ; blue AVG
		MOVD		mm6,EAX
		AVG_6HG		;5,6 ; green comp
		MOVD		mm7,EAX
		AVG_6HR		;11,5 ; red comp
		POR		mm6,mm7
		MOVD		EDX,mm6
		OR		EAX,EDX
		MOVD		EDI,mm3 ; restore dest EDI
		LEA		ESI,[ESI+2] ; increment source
		MOV		[EDI],AX
		DEC		ECX
		PADDD		mm3,mm4 ; EDI(dest) += 2
		JNZ		.looplastLine
.EndlooplastLine:

; last pixel last line -------------------------------------
		AVG_4		0,5 ; red AVG
		MOVD		mm6,EAX
		AVG_4		5,6 ; green comp
		SHL		EAX,5
		MOVD		mm7,EAX
		AVG_4		11,5 ; blue comp
		POR		mm6,mm7
		SHL		EAX,11
		MOVD		EDX,mm6
		OR		EAX,EDX
		MOVD		EDI,mm3
		MOV		[EDI],AX

; END BLUR last Horizontal Line -------------------------------------------

.errorEnd:
		POP		EBP
		POP		EBX
		POP		EDI
		POP		ESI
		;EMMS

		RET

ALIGN 32
SECTION	.data
QBlue16Mask		DW	Blue16_MASK,Blue16_MASK,Blue16_MASK,Blue16_MASK
QGreen16Mask		DW	Green16_MASK,Green16_MASK,Green16_MASK,Green16_MASK
QRed16Mask		DW	Red16_MASK,Red16_MASK,Red16_MASK,Red16_MASK
LastAddMM_B		DQ	0
LastAddMM_G		DQ	0
LastAddMM_R		DQ	0
MaskLastDW		DQ	0x0000ffffffffffff
_TrBuffImgSrc		DD	0
_TrBuffImgDst		DD	0
_TrBuffImgSrcPal	DD	0
_TrImgResHz		DD	0
_TrImgResVt		DD	0




