; -----------------------------------
; internal : draw a line in CurMSurf
; in : MXP1,MYP1 - MXP2,MYP2 - MCurCol
;      EAX,EBX,ESI,EDI : XP1,XP2,YP1,YP2
; out : MXP1,MYP1 - MXP2,MYP2,  not preserved
; -----------------------------------
ALIGN 32
mline16:
		MOV		EDX,EAX
		CMP		EAX,EBX
		JL		.VMaxX
		XCHG		EAX,EBX
.VMaxX:		CMP		EAX,[_MMaxX]
		JG		.FinLine
		CMP		EBX,[_MMinX]
		JL		.FinLine
		SUB		EBX,EAX
		MOV		ESI,EBX	   ;calcul de abs(x2-x1)

		MOV		EAX,[MYP1]
		MOV		EBX,EDI ; [YP2]
		MOV		ECX,EAX
		CMP		EAX,EBX
		JL		.VMaxY
		XCHG		EAX,EBX
.VMaxY:		CMP		EAX,[_MMaxY]
		JG		.FinLine
		CMP		EBX,[_MMinY]
		JL		.FinLine       ; fin du test
		SUB		EBX,EAX
		MOV		EDI,EBX		   ;  abs(y2-y1)

		OR		EDI,EDI
		JZ		.cas4
.PasNegEDI:	OR		ESI,ESI
		JZ		.cas2

		INC		ESI			  ; abs(x2-x1)+1
		INC		EDI			  ; abs(y2-y1)+1
		MOV		EAX,EDX			; EDX = [XP1]
		MOV		EBX,[MXP2]	 ; cas 1 et cas 2
		CMP		EAX,EBX
		JL		.ClipMaxX
		XCHG		EAX,EBX
.ClipMaxX:	CMP		EAX,[_MMinX]
		JL		.Aj_1_2
		CMP		EBX,[_MMaxX]
		JG		.Aj_1_2
		MOV		EAX,ECX			; ECX = [YP1]
		MOV		EBX,[MYP2]
		CMP		EAX,EBX
		JL		.ClipMaxY
		XCHG		EAX,EBX
.ClipMaxY:	CMP		EAX,[_MMinY]
		JL		.Aj_1_2
		CMP		EBX,[_MMaxY]
		JG		.Aj_1_2
		JMP		.PasAj_1_2
.Aj_1_2:	MOV		EBX,EDX			; EDX = [XP1]
		MOV		ESI,[MXP2]
		MOV		EDI,[MYP2]
		CMP		EBX,ESI
		JL		.MaxAj1_2X
		XCHG		EBX,ESI
		XCHG		ECX,EDI
.MaxAj1_2X:
;*********Ajustement des X
		CMP       	EBX,[_MMinX]
		JNL       	.PasAjX12
		MOV       	EAX,EDI
		SUB       	EAX,ECX
		SAL       	EAX,Prec
		SUB       	ESI,EBX
		CDQ
		IDIV      	ESI
		ADD       	ESI,EBX
		MOV       	EDX,EAX
		MOV       	EAX,[_MMinX]
		SUB       	EAX,EBX
		IMUL      	EAX,EDX
		SAR       	EAX,Prec
		MOV       	EBX,[_MMinX]
		ADD       	ECX,EAX
.PasAjX12:	CMP       	ESI,[_MMaxX]
		JNG       	.PasAjM12
		MOV       	EAX,EDI
		SUB       	EAX,ECX
		SAL       	EAX,Prec
		SUB       	ESI,EBX
		OR        	ESI,ESI
		JZ        	.FinLine
		CDQ
		IDIV      	ESI
		ADD       	ESI,EBX
		MOV       	EDX,EAX
		MOV       	EAX,ESI
		SUB       	EAX,[_MMaxX]
		IMUL      	EAX,EDX
		SAR       	EAX,Prec
		MOV       	ESI,[_MMaxX]
		SUB       	EDI,EAX
.PasAjM12:	CMP       	ECX,EDI
		JL        	.MaxAj1_2Y
		XCHG      	EBX,ESI
		XCHG      	ECX,EDI
.MaxAj1_2Y:	CMP       	ECX,[_MMaxY]
		JG        	.FinLine
		CMP       	EDI,[_MMinY]
		JL        	.FinLine
;*********Ajustement des Y
		CMP       	ECX,[_MMinY]
		JNL       	.PasAjY12
		MOV       	EAX,ESI
		SUB       	EAX,EBX
		MOV	        EBP,ESI
		SAL       	EAX,Prec
		MOV       	ESI,EDI
		SUB       	ESI,ECX
		CDQ
		IDIV      	ESI
		MOV	        ESI,EBP
		MOV       	EDX,EAX
		MOV       	EAX,[_MMinY]
		SUB       	EAX,ECX
		IMUL      	EAX,EDX
		SAR       	EAX,Prec
		MOV       	ECX,[_MMinY]
		ADD       	EBX,EAX
		CMP       	EBX,[_MMaxX]
		JG        	.FinLine
		CMP       	EBX,[_MMinX]
		JL        	.FinLine
.PasAjY12:      CMP       	EDI,[_MMaxY]
		JNG       	.PasAjY12X
		MOV       	EAX,ESI
		SUB       	EAX,EBX
		MOV		EBP,ESI
		SAL       	EAX,Prec
		MOV		ESI,EDI
		SUB		ESI,ECX
		CDQ
		IDIV		ESI
		MOV		ESI,EBP
		MOV		EDX,EAX
		MOV		EAX,EDI
		SUB		EAX,[_MMaxY]
		IMUL		EAX,EDX
		SAR		EAX,Prec
		MOV		EDI,[_MMaxY]
		SUB		ESI,EAX
.PasAjY12X:
		MOV       	[MXP1],EBX
		MOV       	[MYP1],ECX
		MOV       	[MXP2],ESI
		MOV       	[MYP2],EDI
		SUB       	ESI,EBX
		SUB       	EDI,ECX
		OR        	ESI,ESI
		
		JZ		.cas2
		JNS		.PasNegESI2
		NEG		ESI
.PasNegESI2:
		OR		EDI,EDI
		JZ		.cas4
		JNS		.PasNegEDI2
		NEG		EDI
.PasNegEDI2:
.PasAj_1_2:     CMP       	ESI,EDI
                JB        	.cas2

;*********CAS 1:  (DX > DY)***************************************************
.cas1:
		MOV		EAX,[MXP1]
		MOV		EBP,[_MScanLine] ; plus
		CMP		EAX,[MXP2]
		JL		.PasSwap1
		XCHG		EAX,[MXP2]
		MOV		[MXP1],EAX
		MOV		EAX,[MYP1]
		MOV		EBX,[MYP2]
		MOV		[MYP1],EBX
		MOV		[MYP2],EAX
.PasSwap1:
		MOV		ESI,[MXP2]
		MOV		EAX,[MYP2]
		SUB		ESI,[MXP1]
		SUB		EAX,[MYP1]
		MOV		EDI,[_MOrgY]  ;[_ScanLine]
		JNS		.pstvDyCas1
		NEG		EAX ; abs(deltay)
		JMP		SHORT .ngtvDyCas1
.pstvDyCas1:	NEG		EBP ; = -[_ScanLine] as ascendent y Axis
.ngtvDyCas1:
		INC		EAX
		MOV		EBX,1 << Prec ; EBX = cpt Dbrd
		SHL		EAX,Prec
		INC		ESI ; deltaX + 1
		CDQ
		IDIV		ESI
		MOV		ECX,ESI ; ECX = deltaX = number pixels
		MOV		EDX,EAX ; EDX = pnt
		ADD		EDI,[MYP1]
		MOV		EAX,[MXP1]
		MOV		EDI,[_MTSurfAdDeb+EDI*4]
		MOV		ESI,1 << Prec
		LEA		EDI,[EDI+EAX*2] ; + (2*XP1) as 16bpp
		MOV		EAX,[MCurCol]
ALIGN 4
.lp_line1:
		SUB		EBX,EDX
		MOV		[EDI],AX
		JA		.no_debor1 ; EDI >0
		ADD		EBX,ESI ; +  (1 << Prec)
		ADD		EDI,EBP	 ; EDI + = directional ScanLine
.no_debor1:
		DEC		ECX
		LEA		EDI,[EDI+2]	; EDI + 2
		JNZ		.lp_line1

		JMP		.FinLine

;*********CAS 2:  (DY > DX)***************************************************
.cas2:
		OR		EDI,EDI
		MOV		EAX,[MYP1]
		JZ		.cas5
		CMP		EAX,[MYP2]
		JL		.PasSwap2
		XCHG		EAX,[MYP2]
		MOV		[MYP1],EAX
		MOV		ECX,[MXP2]
		MOV		EAX,[MXP1]
		MOV		[MXP1],ECX
		MOV		[MXP2],EAX
.PasSwap2:
		OR		ESI,ESI
		JNZ		.noClipVert
		MOV		EAX,[_MMinY]
		MOV		EBX,[_MMaxY]
		CMP		EAX,[MYP1]
		JLE		.sava21
		MOV		[MYP1],EAX
.sava21:	CMP		EBX,[MYP2]
		JGE		.sava22
		MOV		[MYP2],EBX
.sava22:
.noClipVert:
		MOV		EAX,[MXP2]
		MOV		ESI,[MYP2]
		SUB		EAX,[MXP1]
		JNS		.pstvDxCas2
		DEC		EAX
		JMP		SHORT .ngtvDxCas2
.pstvDxCas2:	INC		EAX
.ngtvDxCas2:
		SUB		ESI,[MYP1]
		SHL		EAX,Prec
		MOV		EBP,[_MScanLine]
		INC		ESI
		MOV		EDI,[MYP1]
		CDQ
		ADD		EDI,[_MOrgY] ; * ScanLine
		IDIV		ESI
		MOV		ECX,ESI ; ECX = deltaY = number pixels
		MOV		EDX,EAX ; pente in EDX
		MOV		EDI,[_MTSurfAdDeb+EDI*4]
		MOV		EAX,[MXP1]

		; start adress
		NEG		EBP ; = - ScanLine
		LEA		EDI,[EDI+EAX*2] ; add xp1*2 as 16 bpp
		XOR		EBX,EBX ; accum in EBX
		OR		EDX,EDX
		MOV		EAX,[MCurCol] ; draw color
		JNS		.line2_pstvPnt
		MOV		EBX,((1<<Prec)-1)
.line2_pstvPnt:
ALIGN 4
.lp_line2:
		MOV		ESI,EBX
		SAR		ESI,Prec
		ADD		EBX,EDX ; + pnt
		MOV		[EDI+ESI*2],AX
		DEC		ECX
		LEA		EDI,[EDI+EBP]	  ;  Axe Y Montant -ResH
		JNZ		.lp_line2

		JMP		.FinLine

;*******CAS 3 :  (DX=0)*****************************************************
;*******CAS 4 :  (DY=0)*****************************************************
.cas4:		MOV		ECX,ESI
		MOV		EAX,[MXP1]
		CMP		EAX,[MXP2]
		JL		.PasSwap4
		MOV		EAX,[MXP1]
		MOV		EBX,[MXP2]
		MOV		[MXP1],EBX
		MOV		[MXP2],EAX
.PasSwap4:	MOV		EAX,[_MMinX]
		CMP		EAX,[MXP1]
		JLE		.sava41
		MOV		[MXP1],EAX
.sava41:	MOV		EAX,[_MMaxX]
		CMP		EAX,[MXP2]
		JGE		.sava42
		MOV		[MXP2],EAX
.sava42:
		MOV		ESI,[MXP2]
		SUB		ESI,[MXP1]
		OR		ESI,ESI
		JZ		.cas5
		MOV		EDI,[MYP1]
		INC		ESI
		MOVD		mm0,[MCurCol]
		ADD		EDI,[_MOrgY]
		PUNPCKLWD	mm0,mm0
		MOV		EDI,[_MTSurfAdDeb+EDI*4]
		PUNPCKLDQ	mm0,mm0
		MOV		ECX,[MXP1]
		LEA		EDI,[EDI+ECX*2]
		MOVD		EAX,mm0  ; shift high
		@SolidHLine16
		JMP		SHORT .FinLine

;********CAS 5 : (DX=0, DY=0)***********************************************
.cas5:
		MOV		EAX,[_MOrgY]
		MOV		EDX,[MXP1]
		ADD		EAX,[MYP1]
		MOV		ECX,[MCurCol]
		MOV		EAX,[_MTSurfAdDeb+EAX*4]
		MOV		[EAX+EDX*2],CX
.FinLine:
		RET
