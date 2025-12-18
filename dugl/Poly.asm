;****************************************************************************
; MACRO UTILISER DANS POLY
;****************************************************************************
; calcule adresse physique du contour

; IN: XP1,YP1,XP2,YP2,EBX: Index _TPolyAdFin,EAX: XP1,ECX: YP1,ESI; [_ResH]
; condition XP1<XP2 && YP1<YP2
%macro 	@InContourGchX2Sup	0
		MOV		EBX,ECX
		MOV		EDI,ECX	; [YP1]
		ADD		EBX,[_OrgY]
		NEG		EAX		; -[XP1]
		IMUL		EDI,ESI ; YP1*_ResH
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
		XOR		EDX,EDX 	; Compteur debordement dans EDX
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
;---
		MOVD		mm4,EDX  ; Cpt Dbrd
		MOVD		mm3,EDI  ; Addr+XP1
		ADD		EDX,EAX  ; += Pnt
		SUB		EDI,ESI
		MOVD		mm6,EDX  ; Cpt Dbrd + Pnt
		MOVD		mm5,EDI  ; Addr+XP1
		PUNPCKLDQ	mm4,mm6 ; mm4 = CptDbrd * 2
		PUNPCKLDQ	mm3,mm5  ; mm3 = (Addr+XP1) * 2
;---
		;SHL		EAX,1   ; - *=2
		ADD		EAX,EAX
		;SHL		ESI,1   ; *=2
		ADD		ESI,ESI
		MOVD		mm0,EAX ; - mm0 = PntPlusX * 2
		;MOVD		mm7,EAX ; - Pnt * 2
		SHR		ECX,1
		MOVD		mm6,ESI
		PUNPCKLDQ	mm0,mm0 ; - PntPlusX * 2 | PntPlusX * 2
		;MOVD		mm7,ESI
		;LEA		EAX,[_TPolyAdDeb+EBX*4]
		;MOV		EAX,EBP
		PUNPCKLDQ	mm6,mm6 ; (ResH*2) | (ResH*2)
;ALIGN 4
%%BcClcCtDr2:
		MOVQ		mm5,mm4  ; pnt dbrd in mm5
		MOVQ		mm7,mm3  ; addr1 addr2 in mm7
		PSRLD		mm5,Prec ; right shift Pnt In mm5
		PADDD		mm4,mm0  ; += PntPlus * 2
		PADDD		mm7,mm5  ; + = Addr+XP1
		PSUBD		mm3,mm6  ; -= (ResH*2)
		MOVQ		[EBP],mm7

		DEC		ECX
		LEA		EBP,[EBP+8]
		JNZ		%%BcClcCtDr2
		
%endmacro
; IN : XP1, YP1, XP2, YP2, EBX: Index dans _TPolyAdFin,	EAX : XP1, ECX : YP1
; condition XP1>XP2 && YP1<YP2
%macro 	@InContourGchX1Sup	0
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
;----
		MOVD		mm4,EDX  ; Cpt Dbrd
		MOVD		mm3,EDI  ; Addr+XP1
		ADD		EDX,EAX  ; += Pnt
		SUB		EDI,ESI
		MOVD		mm6,EDX  ; Cpt Dbrd + Pnt
		MOVD		mm5,EDI  ; Addr+XP1
		PUNPCKLDQ	mm4,mm6 ; mm4 = CptDbrd * 2
		PUNPCKLDQ	mm3,mm5  ; mm3 = (Addr+XP1) * 2
;----
		;SHL		EAX,1   ; - *=2
		;SHL		ESI,1   ; *=2
		ADD		EAX,EAX
		ADD		ESI,ESI
		MOVD		mm0,EAX ; - mm0 = PntPlusX * 2
		;MOVD		mm7,EAX ; - Pnt * 2
		SHR		ECX,1
		MOVD		mm6,ESI
		PUNPCKLDQ	mm0,mm0 ; - PntPlusX * 2 | PntPlusX * 2
		;MOVD		mm7,ESI
		;LEA		EAX,[_TPolyAdDeb+EBX*4]
		PUNPCKLDQ	mm6,mm6 ; (ResH*2) | (ResH*2)
;ALIGN 4
%%BcClcCtDr2:
		MOVQ		mm5,mm4  ; pnt dbrd in mm5
		MOVQ		mm7,mm3  ; addr1 addr2 in mm7
		PSRAD		mm5,Prec ; right shift Pnt In mm5
		PADDD		mm4,mm0  ; += PntPlus * 2
		PADDD		mm7,mm5  ; + = Addr+XP1
		PSUBD		mm3,mm6  ; -= (ResH*2)
		MOVQ		[EBP],mm7
		
		DEC		ECX
		LEA		EBP,[EBP+8]
		JNZ		%%BcClcCtDr2
%endmacro

; IN : XP1, YP1, XP2, YP2, EBX: Index dans _TPolyAdFin,	EAX : XP1, ECX : YP1
; condition XP1<XP2 && YP1>YP2

%macro 	@InContourDrtX2Sup	0
		MOV		EDI,EBP  ; [YP2]
		MOV		EBX,EBP  ; [YP2]
		IMUL		EDI,ESI
		ADD		EBX,[_OrgY]
		NEG		EDI
		SUB		ECX,EBP  ; [YP2]
		ADD		EDI,[_vlfb]
		SUB		EAX,[XP2] ; EAX = [XP1]-[XP2]
		CDQ
		SHL		EAX,Prec
        	IDIV   		ECX
		ADD		EDI,[XP2]
		INC		ECX
		MOV		EDX,((1<<Prec)-1)
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
;---
		MOVD		mm4,EDX  ; Cpt Dbrd
		MOVD		mm3,EDI  ; Addr+XP1
		ADD		EDX,EAX  ; += Pnt
		SUB		EDI,ESI
		MOVD		mm6,EDX  ; Cpt Dbrd + Pnt
		MOVD		mm5,EDI  ; Addr+XP1
		PUNPCKLDQ	mm4,mm6 ; mm4 = CptDbrd * 2
		PUNPCKLDQ	mm3,mm5  ; mm3 = (Addr+XP1) * 2
;---
		;SHL		EAX,1   ; - *=2
		;SHL		ESI,1   ; *=2
		ADD		EAX,EAX
		ADD		ESI,ESI
		MOVD		mm0,EAX ; - mm0 = PntPlusX * 2
		;MOVD		mm7,EAX ; - Pnt * 2
		SHR		ECX,1
		MOVD		mm6,ESI
		PUNPCKLDQ	mm0,mm0 ; - PntPlusX * 2 | PntPlusX * 2
		;MOVD		mm7,ESI
		;LEA		EAX,[_TPolyAdFin+EBX*4]
		PUNPCKLDQ	mm6,mm6 ; (ResH*2) | (ResH*2)
;ALIGN 4
%%BcClcCtGc2:
		MOVQ		mm5,mm4  ; pnt dbrd in mm5
		MOVQ		mm7,mm3  ; addr1 addr2 in mm7
		PSRAD		mm5,Prec ; right shift Pnt In mm5
		PADDD		mm4,mm0  ; += PntPlus * 2
		PADDD		mm7,mm5  ; + = Addr+XP1
		PSUBD		mm3,mm6  ; -= (ResH*2)
		MOVQ		[EBP],mm7
		DEC		ECX
		LEA		EBP,[EBP+8]
		JNZ		%%BcClcCtGc2
%endmacro
; IN : XP1, YP1, XP2, YP2, EBX: Index dans _TPolyAdDeb, EAX : XP1, ECX : YP1
; condition XP1>XP2 && YP1>YP2
%macro 	@InContourDrtX1Sup	0
		MOV		EDI,EBP  ; [YP2]
		MOV		EBX,EBP  ; [YP2]
		IMUL		EDI,ESI
		ADD		EBX,[_OrgY]
		NEG		EDI
		SUB		ECX,EBP  ; [YP2]
		ADD		EDI,[_vlfb]
		SUB		EAX,[XP2] ; EAX = [XP1]-[XP2]
		CDQ
		SHL		EAX,Prec
        	IDIV   		ECX
		ADD		EDI,[XP2]
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
;----
		MOVD		mm4,EDX  ; Cpt Dbrd
		MOVD		mm3,EDI  ; Addr+XP1
		ADD		EDX,EAX  ; += Pnt
		SUB		EDI,ESI
		MOVD		mm6,EDX  ; Cpt Dbrd + Pnt
		MOVD		mm5,EDI  ; Addr+XP1
		PUNPCKLDQ	mm4,mm6 ; mm4 = CptDbrd * 2
		PUNPCKLDQ	mm3,mm5  ; mm3 = (Addr+XP1) * 2
;----
		;SHL		EAX,1   ; - *=2
		;SHL		ESI,1   ; *=2
		ADD		EAX,EAX
		ADD		ESI,ESI
		MOVD		mm0,EAX ; - mm0 = PntPlusX * 2
		;MOVD		mm7,EAX ; - Pnt * 2
		SHR		ECX,1
		MOVD		mm6,ESI
		PUNPCKLDQ	mm0,mm0 ; - PntPlusX * 2 | PntPlusX * 2
		;MOVD		mm7,ESI
		;LEA		EAX,[_TPolyAdFin+EBX*4]
		PUNPCKLDQ	mm6,mm6 ; (ResH*2) | (ResH*2)
;ALIGN 4
%%BcClcCtGc2:
		MOVQ		mm5,mm4  ; pnt dbrd in mm5
		MOVQ		mm7,mm3  ; addr1 addr2 in mm7
		PSRLD		mm5,Prec ; right shift Pnt In mm5
		PADDD		mm4,mm0  ; += PntPlus * 2
		PADDD		mm7,mm5  ; + = Addr+XP1
		PSUBD		mm3,mm6  ; -= (ResH*2)
		MOVQ		[EBP],mm7

		DEC		ECX
		LEA		EBP,[EBP+8]
		JNZ		%%BcClcCtGc2
%endmacro

;**CLIP*****************************************************
;GLOB DebYPoly : MinY_temporaire, _MaxY : MaxY_temporaire
;     DebYPoly = -1 : Poly hors de l'ecran
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; calcule X debut et X fin du contour

; IN : XP1, YP1, XP2, YP2, EAX : XP1, ECX : YP1
; condition XP1<XP2 && YP1<YP2
%macro 	@ClipContourGchX2Sup	0
		CMP		ECX,[_MaxY]  ; [YP1]
		JG		NEAR %%Fin
		CMP		EBP,[_MinY]
		JL		NEAR %%Fin
				; Calcule la pente
		NEG		EAX		; -[XP1]
		NEG		ECX     ; -[YP1]
		ADD		EAX,[XP2]
		XOR     	EDX,EDX
		ADD		ECX,EBP			; ECX = YP2-YP1
		SHL		EAX,Prec
		IDIV   		ECX   		; Pente dans EAX
				; Ajustement de <YP1>  =>& XP1
		MOV		EBP,[_MinY]
		MOV		ECX,[YP1]
		XOR		EDX,EDX		; reste 0
		MOV		EBX,EBP
		SUB		EBP,ECX		 ; [_MinY]-[YP1]
		JLE		%%PasAjYP1
		MOV		[YP1],EBX	 ; [YP1] = [_MinY]
		IMUL		EBP,EAX		 ; EBP = DeltaY*Pente
		MOV		EDX,EBP
		AND		EDX,(1 << Prec) - 1
		SHR		EBP,Prec
		ADD		[XP1],EBP
		MOV		ECX,[XP1]
		CMP		ECX,[_MaxX]
		JL 		%%PasPolyOut
		MOV		DWORD [DebYPoly],-1
		JMP		%%Fin
%%PasPolyOut:
%%PasAjYP1:	; Ajustement de <YP2>  =>& XP2
		MOV		ECX,[YP2]
		MOV		EBP,[_MaxY]
		SUB		ECX,EBP			  ;ECX= [YP2]-[_MaxY]
		JLE		%%PasAjYP2
		MOV		[YP2],EBP
		IMUL		ECX,EAX
		SHR		ECX,Prec
		SUB		[XP2],ECX
%%PasAjYP2:
      		; Pente deja en EAX
		MOV		ECX,[YP2]
		MOV		EBX,[YP1]
		MOV		EDI,[XP1]
		SUB		ECX,EBX	  ; ECX= DeltaY
		ADD		EDX,(1<<Prec)	; Compteur debordement dans EDX
		ADD		EBX,[_OrgY]
%%BcClcCtDr2:	DEC		ECX
		MOV		[_TPolyAdDeb+EBX*4],EDI
		JS		%%Fin
		SUB		EDX,EAX		 ; EDX-Pente
		JG 		%%NoDebord
		MOV		EBP,EDX
		NEG		EBP
		SHR		EBP,Prec
		INC		EBP
		ADD		EDI,EBP
		SHL		EBP,Prec
		ADD		EDX,EBP
%%NoDebord:	INC		EBX
		JMP		SHORT %%BcClcCtDr2
%%Fin:
%endmacro
; IN : XP1, YP1, XP2, YP2, EAX : XP1, ECX : YP1
; condition XP1>XP2 && YP1<YP2
%macro 	@ClipContourGchX1Sup	0
		CMP		ECX,[_MaxY]	 ; [YP1]
		JG		NEAR %%Fin
		CMP		EBP,[_MinY]	 ; [YP2]
		MOV		EBX,[XP2]
		JL		NEAR %%Fin
		; Calcule la pente
		SUB		EAX,EBX		; [XP1]-[XP2]
       		XOR     	EDX,EDX		; reste = 0
		NEG		ECX     ; -[YP1]
		ADD		ECX,EBP		; = YP2-YP1 compteur dans ECX
		SHL		EAX,Prec
       		IDIV   		ECX		; Pente dans EAX
		; Ajustement de <YP1>  =>& XP1
		MOV		EBP,[_MinY]
		MOV		ECX,[YP1]
		XOR		EDX,EDX
		MOV		EBX,EBP
		SUB		EBP,ECX	  ; [_MinY]-[YP1]
		JLE		%%PasAjYP1
		IMUL		EBP,EAX
		MOV		[YP1],EBX
		MOV		EDX,EBP
		AND		EDX,(1 << Prec) - 1	 ; calcule reste
		SHR		EBP,Prec
		NEG		EDX
		SUB		[XP1],EBP
%%PasAjYP1:		; Ajustement de <YP2>  =>& XP2
		MOV		ECX,[YP2]
		MOV		EBP,[_MaxY]
		SUB		ECX,EBP			; [YP2]-[_MaxY]
		JLE		%%PasAjYP2
		IMUL		ECX,EAX
		MOV		[YP2],EBP
		SHR		ECX,Prec
		ADD		[XP2],ECX
		MOV		ECX,[XP2]
		CMP		ECX,[_MaxX]
		JL 		%%PasPolyOut
		MOV		DWORD [DebYPoly],-1
		JMP		%%Fin
%%PasPolyOut:
%%PasAjYP2:
; Pente deja dans EAX
		MOV		ECX,[YP2]
		MOV		EBX,[YP1]
		MOV		EDI,[XP1]
		SUB		ECX,EBX
		ADD		EDX,1 << Prec	; Compteur debordement dans EDX
		ADD		EBX,[_OrgY]
%%BcClcCtDr2:	DEC		ECX
		MOV		[_TPolyAdDeb+EBX*4],EDI
		JS		%%Fin
		SUB		EDX,EAX
		JG 		%%NoDebord
		MOV		EBP,EDX
		NEG		EBP
		SHR		EBP,Prec
		INC		EBP
		SUB		EDI,EBP
		SHL		EBP,Prec
		ADD		EDX,EBP
%%NoDebord:	INC		EBX
		JMP		SHORT %%BcClcCtDr2
%%Fin:
%endmacro

; IN : XP1, YP1, XP2, YP2, EAX : XP1, ECX : YP1
; condition XP1<XP2 && YP1>YP2
%macro 	@ClipContourDrtX2Sup	0
		CMP		ECX,[_MinY]
		JL		NEAR %%Fin
		CMP		EBP,[_MaxY]
		MOV		EBX,[XP2]
		JG		NEAR %%Fin
		; Calcule la pente
		NEG		EAX		; -[XP1]
		SUB		ECX,EBP     ; [YP1]-[YP2]
		ADD		EAX,EBX       ; EAX = XP2-XP1
		XOR     	EDX,EDX
		SHL		EAX,Prec
       		IDIV   		ECX	   		; Pente dans EAX
		; Ajustement de <YP1>  =>& XP1
		MOV		ECX,[YP1]
		MOV		EBP,[_MaxY]
		XOR		EDX,EDX
		SUB		ECX,EBP	 ; [YP1]-[_MaxY]
		JLE		%%PasAjYP1
		IMUL		ECX,EAX
		MOV		[YP1],EBP
		MOV		EDX,ECX
		AND		EDX,(1 << Prec) - 1
		SHR		ECX,Prec
		NEG		EDX
		ADD		[XP1],ECX
%%PasAjYP1:		; Ajustement de <YP2>  =>& XP2
		MOV		EBP,[_MinY]
		MOV		ECX,[YP2]
		MOV		EBX,EBP
		SUB		EBP,ECX
		JLE		%%PasAjYP2
		IMUL		EBP,EAX
		MOV		[YP2],EBX
		SHR		EBP,Prec
		SUB		[XP2],EBP
		MOV		ECX,[XP2]
		CMP		ECX,[_MinX]
		JG 		%%PasPolyOut
		MOV		DWORD [DebYPoly],-1
		JMP		SHORT %%Fin
%%PasPolyOut:
%%PasAjYP2:
		; Pente deja en EAX
		MOV		ECX,[YP2]
		MOV		EDI,[XP2]
		MOV		EBX,ECX
		ADD		EDX,1 << Prec	; Compteur debordement dans EDX
		NEG		ECX
		ADD		EBX,[_OrgY]
		ADD		ECX,[YP1]
%%BcClcCtDr2:	DEC		ECX
		MOV		[_TPolyAdFin+EBX*4],EDI
		JS		%%Fin
		SUB		EDX,EAX
		JG 		%%NoDebord
		MOV		EBP,EDX
		NEG		EBP
		SHR		EBP,Prec
		INC		EBP
		SUB		EDI,EBP
		SHL		EBP,Prec
		ADD		EDX,EBP
%%NoDebord:	INC		EBX
		JMP		SHORT %%BcClcCtDr2
%%Fin:
%endmacro
; IN : XP1, YP1, XP2, YP2, EAX : XP1, ECX : YP1
; condition XP1>XP2 && YP1>YP2
%macro 	@ClipContourDrtX1Sup	0
		CMP		ECX,[_MinY]  ; [YP1]
		JL		NEAR %%Fin
		CMP		EBP,[_MaxY]
		JG 		NEAR %%Fin

		; Calcule la pente
		SUB		EAX,[XP2]		; [XP1]-[XP2]
      		XOR     	EDX,EDX
		SUB		ECX,[YP2]		; [YP1]-[YP2]
		SHL		EAX,Prec
      		IDIV   		ECX	   		; Pente dans EAX
		; Ajustement de <YP1>  =>& XP1
		MOV		EBP,[_MaxY]
		MOV		ECX,[YP1]
		XOR		EDX,EDX
		SUB		ECX,EBP		   	;[YP1]-[_MaxY]
		JLE		%%PasAjYP1
		IMUL		ECX,EAX
		MOV		[YP1],EBP
		MOV		EDX,ECX
		AND		EDX,(1 << Prec) - 1
		SHR		ECX,Prec
		SUB		[XP1],ECX
		MOV		ECX,[XP1]
		CMP		ECX,[_MinX]
		JG 		%%PasPolyOut
		MOV		DWORD [DebYPoly],-1
		JMP		%%Fin
%%PasPolyOut:
%%PasAjYP1:		; Ajustement de <YP2>  =>& XP2
		MOV		EBP,[_MinY]
		MOV		ECX,[YP2]
		MOV		EBX,EBP
		SUB		EBP,ECX
		JLE		%%PasAjYP2
		IMUL		EBP,EAX
		MOV		[YP2],EBX
		SHR		EBP,Prec
		ADD		[XP2],EBP
%%PasAjYP2:
		; Pente deja dans EAX
		MOV		ECX,[YP2]
		MOV		EDI,[XP2]
		MOV		EBX,ECX
		ADD		EDX,1 << Prec	; Compteur debordement dans EDX
		NEG		ECX
		ADD		EBX,[_OrgY]
		ADD		ECX,[YP1]
%%BcClcCtDr2:	DEC		ECX
		MOV		[_TPolyAdFin+EBX*4],EDI
		JS		%%Fin
		SUB		EDX,EAX
		JG 		%%NoDebord
		MOV		EBP,EDX
		NEG		EBP
		SHR		EBP,Prec
		INC		EBP
		ADD		EDI,EBP
		SHL		EBP,Prec
		ADD		EDX,EBP
%%NoDebord:	INC		EBX
		JMP		SHORT %%BcClcCtDr2
%%Fin:
%endmacro
;**************************
;MACRO DE CALCUL DE CONTOUR
;**************************
;calcule du contour du polygone lorsqu'il est totalement dans l'ecran
%macro	@InCalculerContour	0
		MOVD		mm1,[_ResH]
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
		@InContourGchX2Sup		; YP1<YP2  &&  XP1<XP2
		JMP		%%FinContr
%%CntGchX1Sup:	@InContourGchX1Sup		; YP1<YP2  &&  XP1>XP2
		JMP		%%FinContr
%%ContDrt:
		MOV		EAX,[XP1]
		CMP		EAX,[XP2]
		JG		NEAR %%CntDrtX1Sup
		@InContourDrtX2Sup		; YP1>YP2  &&  XP1<XP2
		JMP		%%FinContr
%%CntDrtX1Sup:	@InContourDrtX1Sup		; YP1>YP2  &&  XP1>XP2
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


;calcule du contour du polygone lorsqu'il a une partie qui est hors de l'ecran
%macro	@ClipCalculerContour	0
;ALIGN 4
%%ClipBcCalCont:
		MOVD		mm2,EDX     ; sauvegarde le compteur EDX
		MOV		ECX,[YP1]
		CMP		ECX,[YP2]
		JE		NEAR %%DYZero
		JG		NEAR %%ContDrt; si YP1<YP2 alors drt sinon gch
		MOV		EAX,[XP1]
		CMP		EAX,[XP2]
		JG		NEAR %%CntGchX1Sup
		@ClipContourGchX2Sup		; YP1<YP2  &&  XP1<XP2
		JMP		%%FinContr
%%CntGchX1Sup:	@ClipContourGchX1Sup		; YP1<YP2  &&  XP1>XP2
		JMP		%%FinContr
%%ContDrt:
		MOV		EAX,[XP1]
		CMP		EAX,[XP2]
		JG		NEAR %%CntDrtX1Sup
		@ClipContourDrtX2Sup		; YP1>YP2  &&  XP1<XP2
		JMP		%%FinContr
%%CntDrtX1Sup:	@ClipContourDrtX1Sup		; YP1>YP2  &&  XP1>XP2
%%DYZero:
%%FinContr:	CMP		DWORD [DebYPoly],-1
		JE		%%FinCalcContr
		MOVD		EDX,mm2     ; restaure le compteur EDX
		DEC		EDX
		JS		NEAR %%FinCalcContr ; EDX < 0
		MOV		ESI,[PPtrListPt]     ; ESI = PtrListPt

		MOV		EAX,[ESI+EDX*4]	; EAX=PtrPt[EDX]
		MOVD		[XP1],mm4	; restaure xp2,yp2
		MOVD		[YP1],mm5

		MOV 		ECX,[EAX]
		MOV 		EBP,[EAX+4]
		MOV		[XP2],ECX
		MOV		[YP2],EBP

		MOVD		mm4,ECX
		MOVD		mm5,EBP		; sauvegarde les nouv xp2,yp2

		JMP		%%ClipBcCalCont
%%FinCalcContr:
%endmacro

; calcule la position debut et fin dans le texture lorsque le poly est In
%macro	@InCalcTextCnt	0
		MOV		ESI,[PPtrListPt]
		MOV		EDX,[NbPPoly]
		MOV		EBX,[ESI]
		DEC		EDX
		MOV		EAX,[EBX+12] ; XT1
		MOV		EBP,[EBX+16] ; YT1
		MOV		[XT1],EAX
		MOV		ECX,[EBX+4] ; YP(n-1)
		MOV		[YT1],EBP
		MOV		EBX,[ESI+EDX*4]
		MOV		[YP1],ECX
		; EAX EBP ECX XT2 YT2 YP2
		MOV		EAX,[EBX+12] ; XT(n-1)
		MOV		EBP,[EBX+16] ; YT(n-1)
		MOV		[XT2],EAX
		MOV		ECX,[EBX+4] ; YP(n-1)
		MOV		[YT2],EBP
		MOV		[YP2],ECX
%%BcClTxtCnt:	MOVD		mm0,EDX
		MOVD		mm1,ESI

		SUB		EAX,[XT1]
		;MOV		ECX,[YP2]
		SUB		EBP,[YT1]
		SUB		ECX,[YP1]
		JZ		NEAR %%PasClCrLn
		JNS		%%PosDYP
		NEG		ECX  ; DeltaYP <0 => ECX = | DYP |
%%PosDYP:
		;SUB		EAX,[XT1]   ; calcule delta XT
		;SUB		ESI,[YT1]   ; calcule delta YT
		SHL		EAX,Prec
		SHL		EBP,Prec
		CDQ
		IDIV		ECX
		MOVD		mm5,EAX ; [PntPlusX],
		MOV		EAX,EBP
		CDQ
		IDIV		ECX

		XOR		EBX,EBX
                MOVD		mm4,EAX ; [PntPlusY]
		INC		ECX
		MOV		EAX,[YP1]
		PUNPCKLDQ	mm5,mm4 ; = [PntPlusX] | [PntPlusY]
		CMP		EAX,[YP2]
		JG		%%CntTxtFin    ; YP1>YP2

		;--- ajuste Cpt Dbrd X et Y pour SAR
		MOVD		EAX,mm5 ; [PntPlusX]
		OR		EAX,EAX
		SETL		BL
		MOVD		EAX,mm4 ; [PntPlusY]
		MOV		EDX,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr X
		OR		EAX,EAX
		MOVQ		mm2,[XT1] ; mm2 = XT1, YT1
		SETL		BL
		MOV		EBP,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr Y
		
		;MOVQ		mm5,[PntPlusX] ; mm5 = PntPlusX, PntPlusY
		MOV		EBX,[YP1]
		MOVD		mm3,EDX
		MOVD		mm4,EBP
		ADD		EBX,[_OrgY]
		PUNPCKLDQ	mm3,mm4
		LEA		ESI,[_TexXDeb+EBX*4]
		LEA		EDI,[_TexYDeb+EBX*4]
;ALIGN 4
%%BcCntTxtDeb:	MOVQ		mm6,mm3
		MOVQ		mm4,mm2
		PSRAD		mm6,Prec
		DEC		ECX
		PADDD		mm4,mm6
		PADDD		mm3,mm5
		MOVD		[ESI],mm4
		PSRLQ		mm4,32
		MOVD		[EDI],mm4
		LEA		ESI,[ESI+4]
		LEA		EDI,[EDI+4]
		JNZ		%%BcCntTxtDeb
		JMP		%%FinCntTxtFin
%%FnCntTxtDeb:
%%CntTxtFin:
		MOVD		EAX,mm5 ; [PntPlusX]
		OR		EAX,EAX
		SETG		BL
		MOVD		EAX,mm4 ; [PntPlusY]
		MOV		EDX,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr X
		OR		EAX,EAX
		MOVQ		mm2,[XT2] ; mm2 = XT2, YT2
		SETG		BL
		MOV		EBP,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr Y

		;MOVQ		mm5,[PntPlusX] ; mm5 = PntPlusX, PntPlusY
		MOV		EBX,[YP2]
		MOVD		mm3,EDX
		MOVD		mm4,EBP
		ADD		EBX,[_OrgY]
		PUNPCKLDQ	mm3,mm4
		LEA		EDI,[_TexYFin+EBX*4]
		LEA		ESI,[_TexXFin+EBX*4]
;ALIGN 4
%%BcCntTxtFin:	MOVQ		mm6,mm3
		MOVQ		mm4,mm2
		PSRAD		mm6,Prec
		DEC		ECX
		PADDD		mm4,mm6
		PSUBD		mm3,mm5
		MOVD		[ESI],mm4
		PSRLQ		mm4,32
		MOVD		[EDI],mm4
		LEA		ESI,[ESI+4]
		LEA		EDI,[EDI+4]
		JNZ		%%BcCntTxtFin
%%FinCntTxtFin:
%%PasClCrLn:	MOVD		EDX,mm0
		MOVD		ESI,mm1
		DEC		EDX
		JS		%%FinClTxtCnt

		MOV		EBX,[ESI+EDX*4]	; EBX=PtrPt[EDX]
		MOV		EAX,[XT2]
		MOV		ECX,[YP2]
		MOV		EBP,[YT2]
		MOV		[XT1],EAX
		MOV		[YP1],ECX
		MOV		[YT1],EBP
		MOV		EAX,[EBX+12]  ; XT
		MOV		ECX,[EBX+4]   ; YP
		MOV		EBP,[EBX+16]  ; YT
		MOV		[XT2],EAX
		MOV		[YP2],ECX
		MOV		[YT2],EBP

		JMP		%%BcClTxtCnt
%%FinClTxtCnt:

%endmacro

; calcule la position debut et fin dans le texture lorsque le poly est In
%macro	@InCalcTextCntSmallSlow	0
		MOV		EDX,[NbPPoly]
		MOV		ESI,[PPtrListPt]
		DEC		EDX
		MOV		EBX,[ESI]
		MOV		ECX,[ESI+EDX*4]
		MOVQ		mm3,[ECX+12] ; = XT2 | YT2
		MOVQ		mm2,[EBX+12] ; = XT1 | YT1
		MOV		EBP,[EBX+4] ; YP1
		MOV		EAX,[ECX+4] ; YP2
		MOV		[YP1],EBP ; YP1
		MOV		[YP2],EAX ; YP2
		MOVQ		[XT2],mm3 ; = XT1 | YT1
%%BcClTxtCnt:	MOVD		mm0,EDX
		MOVD		mm1,ESI

		MOV		ECX,[YP2]
		PSUBD		mm3,mm2 ; = DXT | DYT
		SUB		ECX,[YP1]
		PSLLD		mm3,Prec
		JZ		%%PasClCrLn
		MOVD		EAX,mm3
		JNS		%%PosDYP
		NEG		ECX  ; DeltaYP <0 => ECX = | DYP |
%%PosDYP:
		CDQ
		PSRLQ		mm3,32
		IDIV		ECX
		MOVD		mm5,EAX ; [PntPlusX],
		MOVD		EAX,mm3 ; ESI
		CDQ
		IDIV		ECX

		XOR		EBX,EBX
                MOVD		mm4,EAX ; [PntPlusY]
		INC		ECX
		MOV		EAX,[YP1]
		PUNPCKLDQ	mm5,mm4 ; = [PntPlusX] | [PntPlusY]
		CMP		EAX,[YP2]
		JG		%%CntTxtFin    ; YP1>YP2

		;--- ajuste Cpt Dbrd X et Y pour SAR
		MOVD		EAX,mm5 ; [PntPlusX]
		OR		EAX,EAX
		SETL		BL
		MOVD		EAX,mm4 ; [PntPlusY]
		MOV		EDX,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr X
		OR		EAX,EAX
		SETL		BL
		MOV		EBP,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr Y
		
		MOV		EBX,[YP1]
		MOVD		mm3,EDX
		MOVD		mm4,EBP
		ADD		EBX,[_OrgY]
		PUNPCKLDQ	mm3,mm4
		LEA		ESI,[_TexXDeb+EBX*4]
		LEA		EDI,[_TexYDeb+EBX*4]
;ALIGN 4
%%BcCntTxtDeb:	MOVQ		mm6,mm3
		MOVQ		mm4,mm2
		PSRAD		mm6,Prec
		DEC		ECX
		PADDD		mm4,mm6
		PADDD		mm3,mm5
		MOVD		[ESI],mm4
		PSRLQ		mm4,32
		MOVD		[EDI],mm4
		LEA		ESI,[ESI+4]
		LEA		EDI,[EDI+4]
		JNZ		%%BcCntTxtDeb
		JMP		%%FinCntTxtFin
%%FnCntTxtDeb:
%%CntTxtFin:
		MOVD		EAX,mm5 ; [PntPlusX]
		OR		EAX,EAX
		SETG		BL
		MOVD		EAX,mm4 ; [PntPlusY]
		MOV		EDX,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr X
		OR		EAX,EAX
		MOVQ		mm2,[XT2] ; mm2 = XT2, YT2
		SETG		BL
		MOV		EBP,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr Y

		MOV		EBX,[YP2]
		MOVD		mm3,EDX
		MOVD		mm4,EBP
		ADD		EBX,[_OrgY]
		PUNPCKLDQ	mm3,mm4
		LEA		EDI,[_TexYFin+EBX*4]
		LEA		ESI,[_TexXFin+EBX*4]
;ALIGN 4
%%BcCntTxtFin:	MOVQ		mm6,mm3
		MOVQ		mm4,mm2
		PSRAD		mm6,Prec
		PADDD		mm4,mm6
		PSUBD		mm3,mm5
		MOVD		[ESI],mm4
		PSRLQ		mm4,32
		LEA		ESI,[ESI+4]
		MOVD		[EDI],mm4
		DEC		ECX
		LEA		EDI,[EDI+4]
		JNZ		%%BcCntTxtFin
%%FinCntTxtFin:
%%PasClCrLn:	MOVD		EDX,mm0
		MOVD		ESI,mm1
		DEC		EDX
		JS		%%FinClTxtCnt

		MOV		EBX,[ESI+EDX*4]	; EBX=PtrPt[EDX]
		MOVQ		mm3,[EBX+12]  ; XT2 | YT2
		MOVQ		mm2,[XT2] ; new XT1, YT1
		MOV		EAX,[YP2] ; new YP1
		MOV		ECX,[EBX+4]  ; YP2
		MOV		[YP1],EAX
		MOV		[YP2],ECX
		MOVQ		[XT2],mm3 ; save XT2, YT2
		
		JMP		%%BcClTxtCnt
%%FinClTxtCnt:

%endmacro




;calcule la position debut et fin dans le texture lorsque le poly est Clipper
%macro	@ClipCalcTextCntMM	0
		MOV		ESI,[PPtrListPt]
		MOV		EDX,[NbPPoly]
		MOV		EBX,[ESI]
		DEC		EDX
		MOV		EAX,[EBX+12] ; XT1
		MOV		ECX,[EBX+16] ; YT1
		MOV		[XT1],EAX
		MOV		[YT1],ECX
		MOV		ECX,[EBX+4] ; YP(n-1)
		MOV		[YP1],ECX
                
		MOV		EBX,[ESI+EDX*4]
		MOV		EAX,[EBX+12] ; XT(n-1)
		MOV		ECX,[EBX+16] ; YT(n-1)
		MOV		[XT2],EAX
		MOV		[YT2],ECX
		MOV		ECX,[EBX+4] ; YP(n-1)
		MOV		[YP2],ECX
%%BcClTxtCnt:	MOVD		mm0,EDX
		MOVD		mm1,ESI

		MOV		ECX,[YP2]
		SUB		ECX,[YP1]
		JZ		NEAR %%PasClCrLn
		JNS		%%PosDYP
		NEG		ECX  ; DeltaYP <0 => ECX = | DYP |
%%PosDYP:
		MOV		EAX,[XT2]
		SUB		EAX,[XT1]   ; calcule delta XT
		CDQ
		SHL		EAX,Prec
		IDIV		ECX
		MOV		[PntPlusX],EAX

		MOV		EAX,[YT2]
		SUB		EAX,[YT1]   ; calcule delta YT
		CDQ
		SHL		EAX,Prec
		IDIV		ECX
		XOR		EBP,EBP        ; compteur debordement Y
		MOV		[PntPlusY],EAX

		MOV		EAX,[YP1]
		XOR		EDX,EDX        ; compteur debordement X
		CMP		EAX,[YP2]
		JG		NEAR %%CntTxtFin
;**** Deb Aj Deb **********************
		MOV		ESI,[YP2]
		CMP		EAX,[_MaxY]
		JG		NEAR %%PasClCrLn
		CMP		ESI,[_MinY]
		JL		NEAR %%PasClCrLn
		CMP		EAX,[_MinY]
		JGE		%%PasAjYP1   ; YP1 >= _MinY
		MOV		EDI,[_MinY]  ; EDI = _MinY
		MOV		EDX,[PntPlusX]
		SUB		EDI,EAX      ; EDI = _MinY - YP1
		IMUL		EDX,EDI
		MOV		EBP,[PntPlusY]
		IMUL		EBP,EDI
		MOV		EAX,[_MinY]
%%PasAjYP1:	CMP		ESI,[_MaxY]  ; YP2 <= _MaxY
		JLE		%%PasAjYP2
		MOV		ESI,[_MaxY]
%%PasAjYP2:
;**** Fin Aj Deb **********************
		;--- ajuste Cpt Dbrd X et Y pour SAR
		MOV		EBX,[PntPlusY]
		OR		EBX,EBX
		JGE		%%PosPntPlusY
		LEA		EBP,[EBP+((1<<Prec)-1)] ; EBP += N-1
%%PosPntPlusY:
		MOV		EBX,[PntPlusX]
		OR		EBX,EBX
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EBP += N-1
%%PosPntPlusX:	;-----------------------------------
		MOV		EBX,EAX     ; YP1
		MOV		ECX,ESI     ; ECX = YP2
		MOVQ		mm2,[XT1] ; mm2 = XT1, YT1
		MOV		EDI,_TexYDeb
		MOVQ		mm5,[PntPlusX] ; mm5 = PntPlusX, PntPlusY
		MOV		ESI,_TexXDeb
		MOVD		mm3,EBP
		MOVD		mm4,EDX
		PSLLQ		mm3,32
		SUB		ECX,EAX     ; ECX = YP2-YP1
		POR		mm3,mm4   ; mm3 = EDX , EBP
		ADD		EBX,[_OrgY]
;ALIGN 4
%%BcCntTxtDeb:	MOVQ		mm4,mm3
		PSRAD		mm4,Prec
		PADDD		mm4,mm2
		PADDD		mm3,mm5
		MOVD		[ESI+EBX*4],mm4
		PSRLQ		mm4,32
		DEC		ECX
		MOVD		[EDI+EBX*4],mm4
		LEA		EBX,[EBX+1]
		JNS		%%BcCntTxtDeb
		JMP		%%FinCntTxtFin
%%FnCntTxtDeb:
%%CntTxtFin:
;**** Deb Aj Fin **********************
		XOR		EDI,EDI
		MOV		EAX,[YP2]
		MOV		ESI,[YP1]
		CMP		EAX,[_MaxY]
		JG		NEAR %%PasClCrLn
		CMP		ESI,[_MinY]
		JL		NEAR %%PasClCrLn
		CMP		EAX,[_MinY]
		JGE		%%FPasAjYP2   ; YP2 >= _MinY
		MOV		EDI,EAX  ; EDI = YP2
		MOV		EDX,[PntPlusX]
		SUB		EDI,[_MinY]      ; EDI = YP2 - _MinY
		MOV		EBP,[PntPlusY]
		IMUL		EDX,EDI
		MOV		EAX,[_MinY]
		IMUL		EBP,EDI
%%FPasAjYP2:
		CMP		ESI,[_MaxY]   ; YP1 <= _MaxY
		JLE		%%FPasAjYP1
		MOV		ESI,[_MaxY]
%%FPasAjYP1:
;**** Fin Aj Fin **********************
		;--- ajuste Cpt Dbrd X et Y pour SAR
		MOV		EBX,[PntPlusY]
		OR		EBX,EBX
		JLE		%%FPosPntPlusY
		LEA		EBP,[EBP+((1<<Prec)-1)] ; EDX += 2**N-1
%%FPosPntPlusY:
		MOV		EBX,[PntPlusX]
		OR		EBX,EBX
		JLE		%%FPosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%FPosPntPlusX:	;-----------------------------------
		MOV		EBX,EAX  ; YP2
		MOV		ECX,ESI  ; ECX = YP1
		MOVQ		mm2,[XT2] ; mm2 = XT1, YT1
		MOV		EDI,_TexYFin
		MOVQ		mm5,[PntPlusX] ; mm5 = PntPlusX, PntPlusY
		MOV		ESI,_TexXFin
		MOVD		mm3,EBP
		MOVD		mm4,EDX
		PSLLQ		mm3,32
		SUB		ECX,EAX  ; ECX = YP1 - YP2
		POR		mm3,mm4   ; mm3 = EDX , EBP
		ADD		EBX,[_OrgY]
;ALIGN 4
%%BcCntTxtFin:	MOVQ		mm4,mm3
		PSRAD		mm4,Prec
		PADDD		mm4,mm2
		PSUBD		mm3,mm5
		MOVD		[ESI+EBX*4],mm4
		PSRLQ		mm4,32
		DEC		ECX
		MOVD		[EDI+EBX*4],mm4
		LEA		EBX,[EBX+1]
		JNS		%%BcCntTxtFin
%%FinCntTxtFin:
%%PasClCrLn:
		MOVD		EDX,mm0
		MOVD		ESI,mm1
		DEC		EDX
		JS		%%FinClTxtCnt

		MOV		EBX,[ESI+EDX*4]	; EBX=PtrPt[EDX]
		MOV		ECX,[XT2]
		MOV		EBP,[YT2]
		MOV		EAX,[YP2]
		MOV		[XT1],ECX
		MOV		[YT1],EBP
		MOV		[YP1],EAX
		MOV		ECX,[EBX+12]  ; XT
		MOV		EBP,[EBX+16]  ; YT
		MOV		EAX,[EBX+4]   ; YP
		MOV		[XT2],ECX
		MOV		[YT2],EBP
		MOV		[YP2],EAX

		JMP		%%BcClTxtCnt

%%FinClTxtCnt:
%endmacro

%macro @ClipCalcTextCnt	0
		CALL		ClipCalcTextCntPRC
%endmacro

ALIGN 32
ClipCalcTextCntPRC:
		@ClipCalcTextCntMM
		RET

;************************************************************************
; calcule la deg debut et fin dans le poly lorsqu'il est In
%macro	@InCalcDColCnt	0
		MOV		ESI,[PPtrListPt]
		MOV		EDX,[NbPPoly]
		MOV		EBX,[ESI]
		DEC		EDX
		MOV		EAX,[EBX+20] ; Col1
		MOV		ECX,[EBX+4]  ; YP1
		AND		EAX,DegMask
		MOV		[YP1],ECX
		MOV		[Col1],EAX
                
		MOV		EBX,[ESI+EDX*4]
		MOV		EAX,[EBX+20] ; Col(n-1)
		MOV		ECX,[EBX+4] ; YP(n-1)
		AND		EAX,DegMask
		MOV		[YP2],ECX
		MOV		[Col2],EAX
		
%%BcClColCnt:	MOVD		mm0,EDX
		MOVD		mm1,ESI
		
		MOV		ECX,[YP2]
		MOV		EBX,[YP1]
		SUB		ECX,EBX
		JZ		NEAR %%PasClCrLn
		JNS		%%PosDYP
		NEG		ECX  ; DeltaYP <0 => ECX = | DYP |
%%PosDYP:
		MOV		EAX,[Col2]
		SUB		EAX,[Col1]   ; calcule delta Col
		ADD		EBX,[_OrgY]
		SHL		EAX,Prec
		CDQ
		IDIV		ECX

		MOV		ESI,[YP1]
		XOR		EDX,EDX        ; compteur debordement X
		INC		ECX	       ; -
		CMP		ESI,[YP2]
		JG		%%CntColFin
		;--- ajuste Cpt Dbrd X  pour SAR
		OR		EAX,EAX
		MOV		EBP,[Col1] ; -
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EBP += N-1
%%PosPntPlusX:	;-----------------------------------
		TEST		CL,1
		JZ		%%DPasClc1Pt
		MOV		ESI,EDX
		SAR		ESI,Prec
		ADD		EDX,EAX  ; pente X
		ADD		ESI,EBP  ; += Col1
		MOV		[_PColDeb+EBX*4],ESI
		LEA		EBX,[EBX+1]
%%DPasClc1Pt:
		MOVD		mm6,EDX
		SHR		ECX,1
		ADD		EDX,EAX
		MOVD		mm5,EBP ; Col1
		MOVD		mm4,EDX
		LEA		EAX,[EAX*2] ; -
		MOVD		mm3,EBP ; Col1
		MOVD		mm7,EAX ; -
		PSLLQ		mm4,32
		MOVD		mm2,EAX ; - mm2 = PntPlusX * 2
		PSLLQ		mm5,32
		PSLLQ		mm2,32
		POR		mm4,mm6        ; mm4 = CptPntX * 2
		POR		mm2,mm7 ; -
		POR		mm3,mm5        ; mm3 = Col1 * 2
		MOV		EAX,_PColDeb
%%BcCntColDeb:
		MOVQ		mm7,mm4
		PSRAD		mm7,Prec
		PADDD		mm7,mm3
		PADDD		mm4,mm2
		MOVQ		[EAX+EBX*4],mm7
		DEC		ECX
		LEA		EBX,[EBX+2]
		JNZ		NEAR %%BcCntColDeb
		JMP		%%FinCntColFin
%%FnCntColDeb:
%%CntColFin:
		;--- ajuste Cpt Dbrd X  pour SAR
		OR		EAX,EAX
		MOV		EBP,[Col2] ; -
		JLE		%%FPosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EBP += N-1
%%FPosPntPlusX:	;-----------------------------------
		MOV		EBX,[YP2]
		ADD		EBX,[_OrgY]
		TEST		CL,1
		JZ		%%FPasClc1Pt
		MOV		ESI,EDX
		SAR		ESI,Prec
		SUB		EDX,EAX  ; -= pente X
		ADD		ESI,EBP  ; += Col2
		MOV		[_PColFin+EBX*4],ESI
		LEA		EBX,[EBX+1]
%%FPasClc1Pt:
		MOVD		mm6,EDX
		SHR		ECX,1
		SUB		EDX,EAX
		MOVD		mm5,EBP ; Col2
		MOVD		mm4,EDX
		LEA		EAX,[EAX*2] ; -
		MOVD		mm3,EBP ; Col2
		MOVD		mm2,EAX ; - mm2 = PntPlusX * 2
		PSLLQ		mm4,32
		MOVD		mm7,EAX ; -
		PSLLQ		mm5,32
		PSLLQ		mm2,32	; -
		POR		mm4,mm6 ; mm4 = CptPntX * 2
		POR		mm2,mm7 ; -
		POR		mm3,mm5        ; mm3 = Col2 * 2
		MOV		EAX,_PColFin
%%BcCntColFin:
		MOVQ		mm7,mm4
		PSRAD		mm7,Prec
		PADDD		mm7,mm3
		PSUBD		mm4,mm2
		MOVQ		[EAX+EBX*4],mm7
		DEC		ECX
		LEA		EBX,[EBX+2]
		JNZ		%%BcCntColFin
%%FinCntColFin:
%%PasClCrLn:	MOVD		EDX,mm0
		MOVD		ESI,mm1
		DEC		EDX
		JS		%%FinClColCnt

		MOV		EBX,[ESI+EDX*4]	; EBX=PtrPt[EDX]
		MOV		ECX,[Col2]
		MOV		EAX,[YP2]
		MOV		[Col1],ECX
		MOV		[YP1],EAX
		MOV		ECX,[EBX+20]  ; Col
		MOV		EAX,[EBX+4]   ; YP
		AND		ECX,DegMask
		MOV		[YP2],EAX
		MOV		[Col2],ECX

		JMP		%%BcClColCnt
%%FinClColCnt:

%endmacro

; calcule la deg debut et fin dans le poly lorsqu'il est In Clipper
%macro	@ClipCalcDColCntMM	0
		MOV		ESI,[PPtrListPt]
		MOV		EDX,[NbPPoly]
		MOV		EBX,[ESI]
		DEC		EDX
		MOV		EAX,[EBX+20] ; Col1
		MOV		ECX,[EBX+4] ; YP(n-1)
		AND		EAX,DegMask
		MOV		[YP1],ECX
		MOV		[Col1],EAX
                
		MOV		EBX,[ESI+EDX*4]
		MOV		EAX,[EBX+20] ; Col(n-1)
		MOV		ECX,[EBX+4] ; YP(n-1)
		AND		EAX,DegMask
		MOV		[YP2],ECX
		MOV		[Col2],EAX
%%BcClColCnt:	MOVD		mm0,EDX
		MOVD		mm1,ESI

		MOV		ECX,[YP2]
		SUB		ECX,[YP1]
		JZ		NEAR %%PasClCrLn
		JNS		%%PosDYP
		NEG		ECX  ; DeltaYP <0 => ECX = | DYP |
%%PosDYP:
		MOV		EAX,[Col2]
		SUB		EAX,[Col1]   ; calcule delta Col
		SHL		EAX,Prec
		CDQ
		IDIV		ECX
		MOV		[PntPlusX],EAX

		MOV		EAX,[YP1]
		XOR		EDX,EDX        ; compteur debordement X
		CMP		EAX,[YP2]
		JG		NEAR %%CntColFin
;**** Deb Aj Deb **********************
		MOV		ESI,[YP2]
		CMP		EAX,[_MaxY]
		JG		NEAR %%PasClCrLn
		CMP		ESI,[_MinY]
		JL		NEAR %%PasClCrLn
		CMP		EAX,[_MinY]
		JGE		%%PasAjYP1   ; YP1 >= _MinY
		MOV		EDI,[_MinY]  ; EDI = _MinY
		MOV		EDX,[PntPlusX]
		SUB		EDI,EAX      ; EDI = _MinY - YP1
		IMUL		EDX,EDI
		MOV		EAX,[_MinY]
%%PasAjYP1:	CMP		ESI,[_MaxY]  ; YP2 <= _MaxY
		JLE		%%PasAjYP2
		MOV		ESI,[_MaxY]
%%PasAjYP2:
;**** Fin Aj Deb **********************
		;--- ajuste Cpt Dbrd X  pour SAR
		MOV		EBX,[PntPlusX]
		OR		EBX,EBX
		JGE		%%PosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EBP += N-1
%%PosPntPlusX:	;-----------------------------------
		MOV		EBX,EAX     ; YP1
		MOV		ECX,ESI     ; ECX = YP2
		SUB		ECX,EAX     ; ECX = YP2-YP1
		ADD		EBX,[_OrgY]
%%BcCntColDeb:
		MOV		ESI,EDX
		SAR		ESI,Prec
		ADD		ESI,[Col1]
		DEC		ECX
		MOV		[_PColDeb+EBX*4],ESI
		JS		NEAR %%FinCntColFin
		ADD		EDX,[PntPlusX]  ; pente X
		INC		EBX
		JMP		SHORT %%BcCntColDeb
%%FnCntColDeb:

%%CntColFin:
;**** Deb Aj Fin **********************
		XOR		EDI,EDI
		MOV		EAX,[YP2]
		MOV		ESI,[YP1]
		CMP		EAX,[_MaxY]
		JG		NEAR %%PasClCrLn
		CMP		ESI,[_MinY]
		JL		%%PasClCrLn
		CMP		EAX,[_MinY]
		JGE		%%FPasAjYP2   ; YP2 >= _MinY
		MOV		EAX,[_MinY]
%%FPasAjYP2:	CMP		ESI,[_MaxY]   ; YP1 <= _MaxY
		JLE		%%FPasAjYP1
		MOV		EDI,ESI       ; EDI = YP1
		MOV		EDX,[PntPlusX]
		SUB		EDI,[_MaxY]   ; EDI = YP1 - _MaxY
		IMUL		EDX,EDI
		MOV		ESI,[_MaxY]
%%FPasAjYP1:
;**** Fin Aj Fin **********************
		;--- ajuste Cpt Dbrd X  pour SAR
		MOV		EBX,[PntPlusX]
		OR		EBX,EBX
		JGE		%%FPosPntPlusX
		LEA		EDX,[EDX+((1<<Prec)-1)] ; EBP += N-1
%%FPosPntPlusX:	;-----------------------------------
		MOV		EBX,ESI  ; YP1
		MOV		ECX,ESI  ; ECX = YP1
		SUB		ECX,EAX  ; ECX = YP1 - YP2
		ADD		EBX,[_OrgY]
%%BcCntColFin:
		MOV		ESI,EDX
		SAR		ESI,Prec
		ADD		ESI,[Col1]
		DEC		ECX
		MOV		[_PColFin+EBX*4],ESI
		JS		%%FinCntColFin
		ADD		EDX,[PntPlusX]  ; pente X
		DEC		EBX
		JMP		SHORT %%BcCntColFin
%%FinCntColFin:
%%PasClCrLn:
		MOVD		EDX,mm0
		MOVD		ESI,mm1
		DEC		EDX
		JS		%%FinClColCnt

		MOV		EBX,[ESI+EDX*4]	; EBX=PtrPt[EDX]
		MOV		ECX,[Col2]
		MOV		EAX,[YP2]
		MOV		[Col1],ECX
		MOV		[YP1],EAX
		MOV		ECX,[EBX+20]  ; Col
		MOV		EAX,[EBX+4]   ; YP
		AND		ECX,DegMask
		MOV		[YP2],EAX
		MOV		[Col2],ECX

		JMP		%%BcClColCnt

%%FinClColCnt:
%endmacro

%macro @ClipCalcDColCnt	0
		CALL		ClipCalcDColCntPRC
%endmacro

ALIGN 32
ClipCalcDColCntPRC:
		@ClipCalcDColCntMM
		RET

