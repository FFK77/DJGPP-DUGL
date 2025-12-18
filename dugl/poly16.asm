;****************************************************************************
; MACRO UTILISER DANS POLY
;****************************************************************************
; calcule adresse physique du contour

; IN: XP1,YP1,XP2,YP2,EBX: Index _TPolyAdFin,EAX: XP1,ECX: YP1,ESI; [_ScanLine]
; condition XP1<XP2 && YP1<YP2
%macro 	@InContourGchX2Sup16	0
		MOV		EBX,ECX
		MOV		EDI,ECX	; [YP1]
		ADD		EBX,[_OrgY]
		NEG		EAX		; -[XP1]
		IMUL		EDI,ESI ; YP1*_ScanLine
		NEG		ECX     ; -[YP1]
		NEG		EDI
		ADD		ECX,EBP		; = YP2-YP1 compteur dans ECX
		ADD		EDI,[_vlfb]
		ADD		EAX,[XP2]       ; EAX = XP2-XP1
		XOR		EDX,EDX
		SHL		EAX,Prec
		IDIV		ECX
		ADD		EDI,[XP1]
		INC		ECX
		ADD		EDI,[XP1] ; ADD XP1 2 times cause 16 bpp
		XOR		EDX,EDX 	; Compteur debordement dans EDX
		
		LEA		EBP,[_TPolyAdDeb+EBX*4]
		TEST		CL,1
		JZ		%%PasClc1Pt
		MOV		[EBP],EDI
		ADD		EDX,EAX
		ADD		EBP,BYTE 4
		SUB		EDI,ESI
%%PasClc1Pt:
		
		;------
		MOVD		mm4,EDX  ; Cpt Dbrd
		MOVD		mm3,EDI  ; Addr+XP1
		ADD		EDX,EAX  ; += Pnt
		SUB		EDI,ESI
		MOVD		mm6,EDX  ; Cpt Dbrd + Pnt
		MOVD		mm5,EDI  ; Addr+XP1
		PUNPCKLDQ	mm4,mm6 ; mm4 = CptDbrd * 2
		PUNPCKLDQ	mm3,mm5  ; mm3 = (Addr+XP1) * 2
		;------
		;SHL		EAX,1 ; - PntPlusX*=2
		;SHL		ESI,1 ; *2
		ADD		EAX,EAX
		ADD		ESI,ESI
		MOVD		mm0,EAX ; - mm0 = PntPlusX * 2
		SHR		ECX,1
		MOVD		mm6,ESI
		PUNPCKLDQ	mm0,mm0 ; - PntPlusX * 2
		;MOV		EAX,EBP
		PUNPCKLDQ	mm6,mm6 ; (ScanLine*2) * 2
;ALIGN 4
%%BcClcCtDr2:
		MOVQ		mm5,mm4  ; = cptDbrd
		MOVQ		mm7,mm3  ; = Addr addr
		PSRLD		mm5,Prec ; shift r Dbrd
		PSUBD		mm3,mm6  ; -= (ResH*2)
		PADDD		mm5,mm5 ; *2 as we are in 16bpp
		PADDD		mm4,mm0  ; += PntPlus * 2
		PADDD		mm7,mm5  ; + = Addr+XP1

		MOVQ		[EBP],mm7
		DEC		ECX
		LEA		EBP,[EBP+8]
		JNZ		%%BcClcCtDr2
%endmacro
; IN : XP1, YP1, XP2, YP2, EBX: Index dans _TPolyAdFin,	EAX : XP1, ECX : YP1
; condition XP1>XP2 && YP1<YP2
%macro 	@InContourGchX1Sup16	0
		MOV		EBX,ECX
		MOV		EDI,ECX  ; [YP1]
		ADD		EBX,[_OrgY]
		NEG		EAX
		IMUL		EDI,ESI
		NEG		ECX			; -[YP1]
		NEG		EDI
		ADD		ECX,EBP   ; ECX = [YP2]-[YP1]
		ADD		EDI,[_vlfb]
		ADD		EAX,[XP2]
		SHL		EAX,Prec
        	CDQ
        	IDIV   		ECX
		ADD		EDI,[XP1]
		INC		ECX
		ADD		EDI,[XP1] ; 16bpp
		MOV		EDX,((1<<Prec)-1)
		LEA		EBP,[_TPolyAdDeb+EBX*4]
		TEST		CL,1
		JZ		%%PasClc1Pt
		;MOV		[_TPolyAdDeb+EBX*4],EDI
		MOV		[EBP],EDI
		ADD		EDX,EAX
		INC		EBX
		ADD		EBP,BYTE 4
		SUB		EDI,ESI
%%PasClc1Pt:
		MOVD		mm4,EDX  ; Cpt Dbrd
		MOVD		mm3,EDI  ; Addr+XP1
		ADD		EDX,EAX  ; += Pnt
		SUB		EDI,ESI
		MOVD		mm6,EDX  ; Cpt Dbrd + Pnt
		MOVD		mm5,EDI  ; Addr+XP1
		PUNPCKLDQ	mm4,mm6 ; mm4 = CptDbrd * 2
		PUNPCKLDQ	mm3,mm5  ; mm3 = (Addr+XP1) * 2
		;-----
		ADD		EAX,EAX ; - *2
		ADD		ESI,ESI
		MOVD		mm0,EAX ; - mm0 = PntPlusX * 2
		SHR		ECX,1
		MOVD		mm6,ESI
		PUNPCKLDQ	mm0,mm0 ; - PntPlusX * 2
		;LEA		EAX,[_TPolyAdDeb+EBX*4]
		;MOV		EAX,EBP
		PUNPCKLDQ	mm6,mm6 ; (ResH*2) * 2
;ALIGN 4
%%BcClcCtDr2:
		MOVQ		mm5,mm4  ; = cptDbrd
		MOVQ		mm7,mm3  ; = Addr addr
		PSRAD		mm5,Prec ; shift r Dbrd
		PADDD		mm4,mm0  ; += PntPlus * 2
		PADDD		mm5,mm5  ; *2 as we are in 16bpp
		PSUBD		mm3,mm6  ; -= (ResH*2)
		PADDD		mm7,mm5  ; + = Addr+XP1

		MOVQ		[EBP],mm7
		DEC		ECX
		LEA		EBP,[EBP+8]
		JNZ		%%BcClcCtDr2
%endmacro

; IN : XP1, YP1, XP2, YP2, EBX: Index dans _TPolyAdFin,	EAX : XP1, ECX : YP1
; condition XP1<XP2 && YP1>YP2

%macro 	@InContourDrtX2Sup16	0
		MOV		EDI,EBP  ; [YP2]
		MOV		EBX,EBP  ; [YP2]
		IMUL		EDI,ESI
		SUB		ECX,EBP  ; [YP2]
		ADD		EBX,[_OrgY]
		NEG		EDI
		MOV		EBP,[XP2]
		ADD		EDI,[_vlfb]
		SUB		EAX,EBP ; EAX = [XP1]-[XP2]
		CDQ
		SHL		EAX,Prec
        	IDIV   		ECX
		LEA		EDI,[EDI+EBP*2] ; +=2*XP2 as 16bpp
		INC		ECX
		MOV		EDX,((1<<Prec)-1)
		LEA		EBP,[_TPolyAdFin+EBX*4]
		TEST		CL,1
		JZ		%%PasClc1Pt
		MOV		[EBP],EDI
		ADD		EDX,EAX
		INC		EBX
		ADD		EBP,BYTE 4
		SUB		EDI,ESI
%%PasClc1Pt:
		MOVD		mm4,EDX  ; Cpt Dbrd
		MOVD		mm3,EDI  ; Addr+XP1
		ADD		EDX,EAX  ; += Pnt
		SUB		EDI,ESI
		MOVD		mm6,EDX  ; Cpt Dbrd + Pnt
		MOVD		mm5,EDI  ; Addr+XP1
		PUNPCKLDQ	mm4,mm6 ; mm4 = CptDbrd * 2
		PUNPCKLDQ	mm3,mm5  ; mm3 = (Addr+XP1) * 2
		;-------
		ADD		EAX,EAX  ; - *=2
		ADD		ESI,ESI  ;  *=2
		MOVD		mm0,EAX ; - mm0 = PntPlusX * 2
		SHR		ECX,1
		MOVD		mm6,ESI
		PUNPCKLDQ	mm0,mm0 ; - PntPlusX * 2
		;LEA		EAX,[_TPolyAdFin+EBX*4]
		PUNPCKLDQ	mm6,mm6 ; (ResH*2) * 2
;ALIGN 4
%%BcClcCtGc2:
		MOVQ		mm5,mm4  ; = cptDbrd
		MOVQ		mm7,mm3  ; = Addr addr
		PSRAD		mm5,Prec ; shift r Dbrd
		PADDD		mm4,mm0  ; += PntPlus * 2
		PADDD		mm5,mm5  ; *2 as we are in 16bpp
		PSUBD		mm3,mm6  ; -= (ResH*2)
		PADDD		mm7,mm5  ; + = Addr+XP1

		MOVQ		[EBP],mm7
		DEC		ECX
		LEA		EBP,[EBP+8]
		JNZ		%%BcClcCtGc2
%endmacro
; IN : XP1, YP1, XP2, YP2, EBX: Index dans _TPolyAdDeb, EAX : XP1, ECX : YP1
; condition XP1>XP2 && YP1>YP2
%macro 	@InContourDrtX1Sup16	0
		MOV		EDI,EBP  ; [YP2]
		MOV		EBX,EBP  ; [YP2]
		IMUL		EDI,ESI
		SUB		ECX,EBP  ; [YP2]
		ADD		EBX,[_OrgY]
		NEG		EDI
		MOV		EBP,[XP2]
		ADD		EDI,[_vlfb]
		SUB		EAX,EBP; [XP2] ; EAX = [XP1]-[XP2]
		CDQ
		SHL		EAX,Prec
        	IDIV   		ECX
		LEA		EDI,[EDI+EBP*2] ; +=2*XP2 as 16bpp
		INC		ECX
		XOR		EDX,EDX
		LEA		EBP,[_TPolyAdFin+EBX*4]
		TEST		CL,1
		JZ		%%PasClc1Pt
		;MOV		[_TPolyAdFin+EBX*4],EDI
		MOV		[EBP],EDI
		ADD		EDX,EAX
		INC		EBX
		ADD		EBP,BYTE 4
		SUB		EDI,ESI
%%PasClc1Pt:
		MOVD		mm4,EDX  ; Cpt Dbrd
		MOVD		mm3,EDI  ; Addr+XP1
		ADD		EDX,EAX  ; += Pnt
		SUB		EDI,ESI
		MOVD		mm6,EDX  ; Cpt Dbrd + Pnt
		MOVD		mm5,EDI  ; Addr+XP1
		PUNPCKLDQ	mm4,mm6 ; mm4 = CptDbrd * 2
		PUNPCKLDQ	mm3,mm5  ; mm3 = (Addr+XP1) * 2
		;-------
		ADD		EAX,EAX ; - *=2
		ADD		ESI,ESI ;   *=2
		MOVD		mm0,EAX ; - mm0 = PntPlusX * 2
		SHR		ECX,1
		MOVD		mm6,ESI
		PUNPCKLDQ	mm0,mm0 ; - PntPlusX * 2
		;LEA		EAX,[_TPolyAdFin+EBX*4]
		PUNPCKLDQ	mm6,mm6 ; (ScanLine*2) * 2
;ALIGN 4
%%BcClcCtGc2:
		MOVQ		mm5,mm4  ; = cptDbrd
		MOVQ		mm7,mm3  ; = Addr addr
		PSRLD		mm5,Prec ; shift r Dbrd
		PADDD		mm4,mm0  ; += PntPlus * 2
		PADDD		mm5,mm5  ; *2 as we are in 16bpp
		PSUBD		mm3,mm6  ; -= (ResH*2)
		PADDD		mm7,mm5  ; + = Addr+XP1

		MOVQ		[EBP],mm7
		DEC		ECX
		LEA		EBP,[EBP+8]
		JNZ		%%BcClcCtGc2
%endmacro

;**************************
;MACRO DE CALCUL DE CONTOUR
;**************************
;calcule du contour du polygone lorsqu'il est totalement dans l'ecran
%macro	@InCalculerContour16	0
		MOVD		mm1,[_ScanLine]
;ALIGN 4
%%InBcCalCont:	MOVD		mm2,EDX     ; sauvegarde le compteur EDX
		MOV		ECX,[YP1]
		MOVD		ESI,mm1
		CMP		ECX,EBP  ; YP2
		JE		NEAR %%DYZero
		JG		NEAR %%ContDrt; si YP1<YP2 alors drt sinon gch
		MOV		EAX,[XP1]
		CMP		EAX,[XP2]
		JG		NEAR %%CntGchX1Sup
		@InContourGchX2Sup16		; YP1<YP2  &&  XP1<XP2
		JMP		%%FinContr
%%CntGchX1Sup:	@InContourGchX1Sup16		; YP1<YP2  &&  XP1>XP2
		JMP		%%FinContr
%%ContDrt:
		MOV		EAX,[XP1]
		CMP		EAX,[XP2]
		JG		NEAR %%CntDrtX1Sup
		@InContourDrtX2Sup16		; YP1>YP2  &&  XP1<XP2
		JMP		%%FinContr
%%CntDrtX1Sup:	@InContourDrtX1Sup16		; YP1>YP2  &&  XP1>XP2
%%DYZero:
%%FinContr:	MOVD		EDX,mm2     ; restaure le compteur EDX
		DEC		EDX
		JS		NEAR %%FinCalcContr ; EDX < 0
		MOV		ESI,[PPtrListPt]     ; ESI = PtrListPt
		MOV		ECX,[XP2] ;lecture des nouvelle points
		MOV		EBP,[YP2]
		MOV		EAX,[ESI+EDX*4]	; EAX=PtrPt[EDX]
		MOV		[XP1],ECX
		MOV		[YP1],EBP
		MOV		ECX,[EAX]
		MOV 		EBP,[EAX+4]
		MOV		[XP2],ECX
		MOV		[YP2],EBP

		JMP		%%InBcCalCont
%%FinCalcContr:
%endmacro


;*************************************************************
; compute RGB16 Start and end contour in _PColDEb and _PColFin
;*************************************************************

%macro	@InCalcRGB_Cnt16	0
		MOV		ESI,[PPtrListPt]
		MOV		EDX,[NbPPoly]
		MOV		EBX,[ESI]
		DEC		EDX
		MOV		EBP,[EBX+20] ; col_RGB16(1)
		MOV		ECX,[EBX+4]  ; YP1
		;MOV		[Col1],EAX
                
		MOV		EDI,[ESI+EDX*4]
		MOV		[YP1],ECX
		MOV		EAX,[EDI+20] ; col_RGB16(n-1)
		MOV		ECX,[EDI+4] ; YP(n-1)
		MOV		[YP2],ECX
		MOV		[Col2],EAX
		
%%BcClColCnt:	MOV		ECX,[YP2]
		PUSH		ESI
		SUB		ECX,[YP1]
		PUSH		EDX
		JZ		NEAR %%PasClCrLn
		JNS		%%PosDYP
		NEG		ECX  ; DeltaYP <0 => ECX = | DYP |
%%PosDYP:
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
		MOVD		EAX,mm2
		PSLLD		mm3,Prec ; mm3 : DeltaRed<<Prec

		XOR		EBX,EBX
		CDQ
		XOR		EDI,EDI
		IDIV		ECX
		PSRLQ		mm2,32
		OR		EAX,EAX
		MOVD		mm6,EAX ; mm6 = PntBlue | -
		SETL		BL
		
		MOVD		EAX,mm3
		OR		EDI,EBX
		CDQ
		IDIV		ECX
		OR		EAX,EAX
		MOVD		mm7,EAX ; mm7 = PntRed | -
		SETL		BL

		MOVD		EAX,mm2
		LEA		EDI,[EDI+EBX*4]
		CDQ
		IDIV		ECX
		PUNPCKLDQ	mm7,mm7 ; mm7 = PntR | PntR
		OR		EAX,EAX
		MOVD		mm3,EAX ; mm3 = PntGReen | -
		SETL		BL
		PUNPCKLDQ	mm6,mm6 ; mm6 = PntB | PntB
		LEA		EDI,[EDI+EBX*2]
		PUNPCKLDQ	mm3,mm3 ; mm3 = PntGreen | PntGReen
;---------------
		MOV		ESI,[YP1]
		SHL		EDI,4 ; EDI * 16
		INC		ECX	       ; -
		CMP		ESI,[YP2]
		JG		%%CntColFin
		;--- ajuste Cpt Dbrd X  pour SAR
		;MOV		EBP,[Col1] ; -

		PSLLD		mm4,Prec ; mm4 : Col1_B<<Prec | Col1_G<<Prec
		PSLLD		mm5,Prec ; mm5 : Col1_R<<Prec | -
		PADDD		mm4,[RGBDebMask_GGG+EDI]   ; mm4 = cptDbrd B | cptDbrd G ;; += Col1B | Col1G  Shifted
		PADDD		mm5,[RGBDebMask_GGG+EDI+8] ; mm5 = cptDbrd R | - ;; += Col1R | -  Shifted
		MOVQ		mm2,mm4 ; mm2 = cptDbrd B | cptDbrd G
		MOVQ		mm1,mm4 ; = Cpt dbrd B| -
		MOV		EBX,[YP1]
		PUNPCKHDQ	mm2,mm2 ; mm4 = cptDbrd G | cptDbrd G

		MOVQ		mm0,mm5 ; = Cpt dbrd R| -
		PADDD		mm1,mm6 ; += Pnt B | B
		PADDD		mm0,mm7 ; += Pnt R | R
		PUNPCKLDQ	mm4,mm1 ; mm4 = cpt dbrd B | (cpt dbrd B + Pnt B)
		PUNPCKLDQ	mm5,mm0 ; mm5 = cpt dbrd R | (cpt dbrd R + Pnt R)
		MOVQ		mm1,mm2 ; = cpt Dbrd G|G
		ADD		EBX,[_OrgY]
		TEST		CL,1
		PADDD		mm1,mm3
		PUNPCKLDQ	mm2,mm1 ; mm2 = cpt dbrd G | (cpt dbrd G + Pnt G)

;---------------
		JZ		%%NoFDebCol
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
		POR		mm1,mm0
		MOVD		[_PColDeb+EBX*4],mm1
		INC		EBX
%%NoFDebCol:
;---------------
		PADDD		mm6,mm6
		PADDD		mm7,mm7
		SHR		ECX,1
		PADDD		mm3,mm3
%%BcCntRGBDeb:
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
		POR		mm1,mm0

		MOVQ		[_PColDeb+EBX*4],mm1
		DEC		ECX
		LEA		EBX,[EBX+2]
		JNZ		NEAR %%BcCntRGBDeb
		JMP		%%FinCntColFin

%%CntColFin:
		MOV		EAX,[Col2]
		MOVD		mm4,EAX ; *
		MOVD		mm5,EAX ; *
		PUNPCKLDQ	mm4,mm4
		PAND		mm4,[MaskB_RGB16] ; * mm4 : Blue | green
		PAND		mm5,[MaskR_RGB16] ; * mm5 : red | 0
		PSLLD		mm4,Prec ; mm4 : Col2_B<<Prec | Col2_G<<Prec
		PSLLD		mm5,Prec ; mm5 : Col2_R<<Prec | -
		
		PADDD		mm4,[RGBFinMask_GGG+EDI] ; mm4 : CptDbrdBlue | CptDbrdGreen
		PADDD		mm5,[RGBFinMask_GGG+EDI+8] ; mm5 : CptDbrdRed

		MOVQ		mm2,mm4 ; mm2 = cptDbrd B | cptDbrd G
		MOVQ		mm1,mm4 ; = Cpt dbrd B| -

		MOVQ		mm0,mm5 ; = Cpt dbrd R| -
		PUNPCKHDQ	mm2,mm2 ; mm4 = cptDbrd G | cptDbrd G
		PSUBD		mm0,mm7 ; += Pnt R | R
		PSUBD		mm1,mm6 ; += Pnt B | B
		MOV		EBX,[YP2]
		PUNPCKLDQ	mm4,mm1 ; mm4 = cpt dbrd B | (cpt dbrd B - Pnt B)
		PUNPCKLDQ	mm5,mm0 ; mm5 = cpt dbrd R | (cpt dbrd R - Pnt R)
		MOVQ		mm1,mm2 ; = cpt Dbrd G|G
		ADD		EBX,[_OrgY]
		TEST		CL,1
		PSUBD		mm1,mm3
		PUNPCKLDQ	mm2,mm1 ; mm2 = cpt dbrd G | (cpt dbrd G - Pnt G)
		
		JZ		%%NoFFinCol
		MOVQ		mm0,mm2 ; mm0 = cptDbrd G|G
		MOVQ		mm1,mm5 ; mm1 = cptDbrd R,R
		PSRLD		mm0,Prec
		PSRLD		mm1,Prec
		PAND		mm0,[Mask2G_RGB16]
		PAND		mm1,[Mask2R_RGB16]
		POR		mm1,mm0
		PSUBD		mm5,mm7 ; = cptDbrd R|R + Pnt R|R
		MOVQ		mm0,mm4 ; mm0 = cptDbrd B,B
		PSUBD		mm2,mm3 ; = cptDbrd G|G + Pnt G|G
		PSUBD		mm4,mm6 ; = cptDbrd B|B + Pnt B|B
		PSRLD		mm0,Prec
		POR		mm1,mm0
		MOVD		[_PColFin+EBX*4],mm1
		INC		EBX
%%NoFFinCol:
;---------------
		PADDD		mm6,mm6
		PADDD		mm7,mm7
		SHR		ECX,1
		PADDD		mm3,mm3
		
%%BcCntRGBFin:
		MOVQ		mm0,mm2 ; mm0 = cptDbrd G|G
		MOVQ		mm1,mm5 ; mm1 = cptDbrd R,R
		PSRLD		mm0,Prec
		PSRLD		mm1,Prec
		PAND		mm0,[Mask2G_RGB16]
		PAND		mm1,[Mask2R_RGB16]
		POR		mm1,mm0
		PSUBD		mm5,mm7 ; = cptDbrd R|R + Pnt R|R
		MOVQ		mm0,mm4 ; mm0 = cptDbrd B,B
		PSUBD		mm2,mm3 ; = cptDbrd G|G + Pnt G|G
		PSUBD		mm4,mm6 ; = cptDbrd B|B + Pnt B|B
		PSRLD		mm0,Prec
		POR		mm1,mm0
		MOVQ		[_PColFin+EBX*4],mm1
		DEC		ECX
		LEA		EBX,[EBX+2]
		JNZ		%%BcCntRGBFin
		
%%FinCntColFin:
%%PasClCrLn:	POP		EDX
		POP		ESI
		DEC		EDX
		JS		%%FinClColCnt

		MOV		EBX,[ESI+EDX*4]	; EBX=PtrPt[EDX]
		MOV		EAX,[YP2]
		MOV		EBP,[Col2] ; EBP = Col1
		MOV		[YP1],EAX
		MOV		ECX,[EBX+4]   ; YP
		MOV		EAX,[EBX+20]  ; EAX = Col2
		;MOV		[Col1],ECX
		MOV		[YP2],ECX
		MOV		[Col2],EAX

		JMP		%%BcClColCnt
%%FinClColCnt:

%endmacro

%macro	@ClipCalcRGB_Cnt16	0
		MOV		ESI,[PPtrListPt]
		MOV		EDX,[NbPPoly]
		MOV		EBX,[ESI]
		DEC		EDX
		MOV		EAX,[EBX+20] ; col_RGB16(1)
		MOV		ECX,[EBX+4]  ; YP1
		MOV		[YP1],ECX
		MOV		[Col1],EAX
                
		MOV		EBX,[ESI+EDX*4]
		MOV		EAX,[EBX+20] ; col_RGB16(n-1)
		MOV		ECX,[EBX+4] ; YP(n-1)
		MOV		[YP2],ECX
		MOV		[Col2],EAX
		
%%BcClColCnt:	PUSH		ESI
		PUSH		EDX
		
		MOV		ECX,[YP2]
		MOV		EBX,[YP1]
		SUB		ECX,EBX
		JZ		NEAR %%PasClCrLn
		JNS		%%PosDYP
		NEG		ECX  ; DeltaYP <0 => ECX = | DYP |
%%PosDYP:
		MOVD		mm3,[Col2]
		MOVD		mm5,[Col1]
		PXOR		mm2,mm2 ; = 0 | 0
		PUNPCKLDQ	mm3,mm3
		PXOR		mm4,mm4 ; = 0 | 0
		PUNPCKLDQ	mm5,mm5
		POR		mm2,mm3
		POR		mm4,mm5
		
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
		
		XOR		EBX,EBX
		XOR		EDI,EDI
		MOVD		EAX,mm2
		CDQ
		IDIV		ECX
		PSRLQ		mm2,32
		MOVD		mm6,EAX ; mm6 = PntBlue | -
		OR		EAX,EAX
		SETL		BL
		OR		EDI,EBX

		MOVD		EAX,mm3
		CDQ
		IDIV		ECX
		MOVD		mm7,EAX ; mm7 = PntRed | -
		OR		EAX,EAX
		SETL		BL
		LEA		EDI,[EDI+EBX*4]

		MOVD		EAX,mm2
		CDQ
		IDIV		ECX
		MOVD		mm3,EAX ; mm3 = PntGReen | -
		MOV		EBP,EAX ; EBP = PntGReen
		PSLLQ		mm3,32
		POR		mm6,mm3 ; mm6 = PntBlue | PntGReen
		OR		EAX,EAX
		SETL		BL
		LEA		EDI,[EDI+EBX*2] ; EDI : idx initial CptDbrd

		MOV		ESI,[YP1]
		MOV		EAX,[YP2]
		SHL		EDI,4 ; EDI * 16
		;INC		ECX	       ; -
		CMP		ESI,EAX
		JG		%%CntColFin

		;--- ajuste Cpt Dbrd X  pour SAR
		;MOV		EBP,[Col1] ; -

		MOVQ		mm2,[RGBDebMask_GGG+EDI] ; mm2 : CptDbrdBlue | CptDbrdGreen
		MOVD		mm3,[RGBDebMask_GGG+EDI+8] ; mm3 : CptDbrdRed
		
;**** Deb Aj Deb **********************
		CMP		EAX,[_MinY]	; YP2 < _MinY ?
		JL		%%PasClCrLn
		CMP		ESI,[_MaxY]	; YP1 > _MaxY ?
		JG		%%PasClCrLn
		CMP		ESI,[_MinY]	; YP1 >= _MinY ?
		JGE		%%PasAjYP1
		MOV		EBX,[_MinY]	; EBX = _MinY
		MOVD		EDI,mm6		; EDI = Pnt Blue
		SUB		EBX,ESI		; EBX = _MinY - YP1
		MOVD		EDX,mm7		; EDX = Pnt Red
		IMUL		EBP,EBX ; PntGreen*DeltaY
		IMUL		EDI,EBX ; PntBlue*DeltaY
		MOVD		mm1,EBP
		MOVD		mm0,EDI
		;PSLLQ		mm0,32
		IMUL		EDX,EBX ; PntREd*DeltaY
		;POR		mm0,mm1 ; mm0 : +CptDbrdBlue | +CptDbrdGreen
		PUNPCKLDQ	mm0,mm1 ; mm0 : +CptDbrdBlue | +CptDbrdGreen
		MOV		ESI,[_MinY]
		MOVD		mm1,EDX ; mm1 : +CptDbrdRed | -
		PADDD		mm2,mm0 ; mm2+= CptDbrd B | G
		PADDD		mm3,mm1 ; mm3+= CptDbrd R | -
%%PasAjYP1:	CMP		EAX,[_MaxY]  ; YP2 <= _MaxY
		JLE		%%PasAjYP2
		MOV		EAX,[_MaxY]
%%PasAjYP2:
;**** Fin Aj Deb **********************
		MOV		ECX,EAX ; = Clip YP2
		MOV		EBX,ESI ; = clipped YP1
		SUB		ECX,ESI ; - Clip YP1
		ADD		EBX,[_OrgY]
		INC		ECX
		; mm2, mm3 : cptDbrd B,G,R
		; mm6, mm7 : pnt     B,G,R
		; mm4, mm5 : pnt     Col1B,Col1G,Col1R
		; Free EAX,EDX, ESI, EDI, EBP
		MOVD		ESI,mm4 ; Col1B shifted
		MOVD		EBP,mm5 ; Col1R shifted
		PSRLQ		mm4,32
		MOVD		EDI,mm4 ; Col1G shifted
%%BcCntRGBDeb:
		MOVQ		mm5,mm3 ; = cptDbrd R
		MOVQ		mm4,mm2 ; = cptDbrd B,G
		MOVD		EDX,mm3 ; * cptDbrd R
		MOVD		EAX,mm2 ; = cptDbrd B
		ADD		EDX,EBP ; * += ColR Sifted
		ADD		EAX,ESI ; += ColB Sifted
		SHR		EDX,Prec+11 ; *
		SHR		EAX,Prec
		SHL		EDX,11 ; *
		PSRLQ		mm4,32 ; **
		OR		EAX,EDX ; * affect R to EAX

		PADDD		mm2,mm6 ; = cptDbrd B,G - Pnt B,G
		MOVD		EDX,mm4 ; cptDbrd G
		ADD		EDX,EDI ; += ColG Sifted
		SHR		EDX,Prec+5
		SHL		EDX,5
		OR		EAX,EDX ; affect G to EAX

		PADDD		mm3,mm7 ; = cptDbrd R - Pnt R

		MOV		[_PColDeb+EBX*4],EAX
		DEC		ECX
		LEA		EBX,[EBX+1]
		JNZ		NEAR %%BcCntRGBDeb
		JMP		%%FinCntColFin

%%CntColFin:
		
		MOVQ		mm2,[RGBFinMask_GGG+EDI] ; mm2 : CptDbrdBlue | CptDbrdGreen
		MOVD		mm3,[RGBFinMask_GGG+EDI+8] ; mm3 : CptDbrdRed
;**** Deb Aj Fin **********************
		CMP		ESI,[_MinY]	; YP1 < _MinY ?
		JL		%%PasClCrLn
		CMP		EAX,[_MaxY]	; YP2 > _MaxY ?
		JG		%%PasClCrLn
		CMP		EAX,[_MinY]	; YP2 >= _MinY ?
		JGE		%%PasAjYP1Fin
		MOV		EBX,[_MinY]	; EBX = _MinY
		MOVD		EDI,mm6		; EDI = Pnt Blue
		SUB		EBX,EAX		; EBX = _MinY - YP1
		MOVD		EDX,mm7		; EDX = Pnt Red
		IMUL		EBP,EBX ; PntGreen*DeltaY
		IMUL		EDI,EBX ; PntBlue*DeltaY
		MOVD		mm1,EBP
		MOVD		mm0,EDI
		IMUL		EDX,EBX ; PntREd*DeltaY
		PUNPCKLDQ	mm0,mm1 ; mm0 : +CptDbrdBlue | +CptDbrdGreen
		MOV		EAX,[_MinY]
		MOVD		mm1,EDX ; mm1 : +CptDbrdRed | -
		PSUBD		mm2,mm0 ; mm2-= CptDbrd B | G
		PSUBD		mm3,mm1 ; mm3-= CptDbrd R | -
%%PasAjYP1Fin:	CMP		ESI,[_MaxY]  ; YP1 <= _MaxY
		JLE		%%PasAjYP2Fin
		MOV		ESI,[_MaxY]
%%PasAjYP2Fin:
;**** Fin Aj Fin **********************
		
		MOV		ECX,ESI ; clipped YP1
		MOV		EBX,EAX ; clipped YP2
		SUB		ECX,EAX ; - clipped YP2
		ADD		EBX,[_OrgY]
		INC		ECX ; ++
		
		MOV		ESI,[Col2]
		MOV		EDI,[Col2]
		MOV		EBP,[Col2]
		AND		ESI,CMaskB_RGB16 ;  Blue
		AND		EDI,CMaskG_RGB16 ;  green
		AND		EBP,CMaskR_RGB16 ;  red
		SHL		ESI,Prec ; Col2B shifted
		SHL		EDI,Prec ; Col2G shifted
		SHL		EBP,Prec ; Col2R shifted
		
%%BcCntRGBFin:
		MOVQ		mm5,mm3 ; = cptDbrd R
		MOVQ		mm4,mm2 ; = cptDbrd B,G
		MOVD		EDX,mm3 ; * cptDbrd R
		MOVD		EAX,mm2 ; = cptDbrd B
		ADD		EDX,EBP ; * += ColR Sifted
		ADD		EAX,ESI ; += ColB Sifted
		SHR		EDX,Prec+11 ; *
		SHR		EAX,Prec
		SHL		EDX,11 ; *
		PSRLQ		mm4,32 ; **
		OR		EAX,EDX ; * affect R to EAX

		PSUBD		mm2,mm6 ; = cptDbrd B,G - Pnt B,G
		MOVD		EDX,mm4 ; cptDbrd G
		ADD		EDX,EDI ; += ColG Sifted
		SHR		EDX,Prec+5
		SHL		EDX,5
		OR		EAX,EDX ; affect G to EAX

		PSUBD		mm3,mm7 ; = cptDbrd R - Pnt R

		MOV		[_PColFin+EBX*4],EAX
		DEC		ECX
		LEA		EBX,[EBX+1]
		JNZ		%%BcCntRGBFin
		
%%FinCntColFin:
%%PasClCrLn:
		POP		EDX
		POP		ESI
		DEC		EDX
		JS		%%FinClColCnt

		MOV		EBX,[ESI+EDX*4]	; EBX=PtrPt[EDX]
		MOV		ECX,[Col2]
		MOV		EAX,[YP2]
		MOV		[Col1],ECX
		MOV		[YP1],EAX
		MOV		ECX,[EBX+20]  ; Col
		MOV		EAX,[EBX+4]   ; YP
		MOV		[YP2],EAX
		MOV		[Col2],ECX

		JMP		%%BcClColCnt
%%FinClColCnt:

%endmacro


