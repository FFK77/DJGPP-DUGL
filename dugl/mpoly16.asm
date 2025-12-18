;**************************
;MACRO DE CALCUL DE CONTOUR
;**************************
;calcule du contour du polygone lorsqu'il est totalement dans l'ecran
%macro	@InMCalculerContour16	0
		MOV		EAX,[_MOrgY]
		LEA		ECX,[EAX+EDX] ; miny
		LEA		EAX,[EAX+EBX-1] ; maxy - 1
		MOV		[MEndYPoly],ECX
		MOV		[MDebYPoly],EAX ; save deb and end y
		
		MOV		EAX,[MVectColPlus]
		MOV		ECX,[MVectYPlus]
		MOVD		mm0,[EDI+EAX] ; V1.col
		; put vertices on a good order : V1 upper
		CMP		EBX,[EDI+ECX] ; maxy == V1.y ?
		PUNPCKLWD	mm0,mm0
		JE		SHORT %%VertexOrdOK
		CMP		EBX,[ESI+ECX]
		JE		%%Vertex2Up
%%Vertex3Up:	XCHG		EBP,EDI
		XCHG		ESI,EBP
		JMP		SHORT %%VertexOrdOK
%%Vertex2Up:	XCHG		ESI,EDI
		XCHG		ESI,EBP
%%VertexOrdOK:
		;check which kind of triangle is this ?
		; (right, left, down, up)

		CMP		[EBP+ECX],EBX ; v3.y == maxy ? => down tri
		PUNPCKLDQ	mm0,mm0
		JE		%%DownTri
		CMP		[ESI+ECX],EBX ; v2.y == maxy ? => down tri
		JE		%%DownTri
		
		CMP		[EBP+ECX],EDX ; v3.y != miny ? => right tri
		JNE		%%RightTri
		CMP		[ESI+ECX],EDX ; v2.y != miny ? => left tri
		JNE		%%LeftTri

%%UpTri:
		; case    ^   ~~~~~~~~~~~
		;        / \
		;        ---
		
		MOV		ECX,[MVectXPlus]
		MOV		EAX,[EDI+ECX] ; v1.x
		MOV		EDI,[ESI+ECX] ; V2.x
		MOV		ESI,[EBP+ECX] ; V3.x
		MOV		EBP,[MDebYPoly]
		SUB		EDI,EAX ; delta x2-x1
		SUB		ESI,EAX ; delta x3-x1
		MOVD		mm2,[_MTSurfAdDeb+EBP*4] ; = addr deb v1.y - 1
		SUB		EBX,EDX ; deltaY

		MOV		EBP,EAX
		SHL		EDI,Prec
		MOV		EAX,EDI
		CDQ
		IDIV		EBX
		SHL		ESI,Prec
		MOVD		mm7,EAX ; mm7 = left or deb X Pnt

		MOV		EAX,ESI
		CDQ
		IDIV		EBX
		MOVQ		mm5,mm7 ; mm5 : acc pnt left X
		MOVD		mm6,EAX ; mm6 = right or fin X Pnt
		MOVD		EDX,mm2 ; Add Deb
		MOVD		mm4,EAX ; mm4 : acc pnt right X
		LEA		EDX,[MDebYPoly]
		MOVD		EAX,mm0
		MOV		EBP,-1 ; EBP = index plus
ALIGN 4
%%BcFillUpTri:
		MOVQ		mm2,mm5 ; acc deb
		MOVQ		mm3,mm4 ; acc end
		PSRAD		mm2,Prec
		PSRAD		mm3,Prec
		MOVD		EDI,mm2
		PADDD		mm5,mm7
		MOVD		ESI,mm3
		PADDD		mm4,mm6

		MOV		[_MTPolyAdDeb+EDX*4],EDI
		MOV		[_MTPolyAdFin+EDX*4],ESI
%%EndUpTriHLine:
		DEC		EBX
		LEA		EDX,[EDX+EBP] ; index up or down
		JNZ		SHORT %%BcFillUpTri
		RET

%%DownTri:
		; case  ----    ~~~~~~~~~~~
		;       \  /
		;        \/
		
		CMP		EDX,[ESI+ECX] ; miny = v2.y ?
		JE		SHORT %%Vertex2Down
%%Vertex3Down:	XCHG		EBP,EDI
		XCHG		ESI,EBP
		JMP		SHORT %%VertexDownOK
%%Vertex2Down:	XCHG		ESI,EDI
		XCHG		ESI,EBP
%%VertexDownOK:
		MOV		ECX,[MVectXPlus]
		MOV		EAX,[EDI+ECX] ; v1.x
		MOV		EDI,[ESI+ECX] ; V2.x
		MOV		ESI,[EBP+ECX] ; V3.x

		MOV		EBP,[MEndYPoly]
		SUB		EDI,EAX ; delta x2-x1
		SUB		ESI,EAX ; delta x3-x1
		MOVD		mm2,[_MTSurfAdDeb+EBP*4] ; = addr deb v1.y - 1
		SUB		EBX,EDX ; deltaY

		MOV		EBP,EAX
		SHL		EDI,Prec
		MOV		EAX,EDI
		CDQ
		IDIV		EBX
		SHL		ESI,Prec
		MOVD		mm6,EAX ; mm7 = left or deb X Pnt

		MOV		EAX,ESI
		CDQ
		IDIV		EBX
		PXOR		mm5,mm5 ; mm5 : acc pnt left X
		MOVD		EDX,mm2 ; Add Deb
		MOVD		mm7,EAX ; mm6 = right or fin X Pnt
		LEA		EDX,[MEndYPoly]
		PXOR		mm4,mm4 ; mm4 : acc pnt right X
		MOV		EBP,1 ; EBP = index plus
		MOVD		EAX,mm0
		JMP		%%BcFillUpTri

%%RightTri:
		; case   |\    ~~~~~~~~~~~
		;        | \
		;        | /
		;	 |/

		MOV		EAX,[EBP+ECX] ; v3.y
		MOV		[MYP3],EAX
		MOV		[MYP1],EBX
		SUB		EAX,EDX ; v3.y - v2.y
		MOV		ECX,[MVectXPlus]
		MOVD		mm1,EAX
		MOV		EAX,[EDI+ECX] ; v1.x
		MOV		EDI,[ESI+ECX] ; V2.x
		MOV		ESI,[EBP+ECX] ; V3.x
		MOV		[MXP2],EDI
		MOV		[MXP3],ESI
		MOV		EBP,[MDebYPoly]
		SUB		EDI,EAX ; delta x2-x1
		SUB		ESI,EAX ; delta x3-x1
		MOVD		mm2,[_MTSurfAdDeb+EBP*4] ; = addr deb v1.y - 1
		SUB		EBX,EDX ; deltaY

		MOV		EBP,EAX
		SHL		EDI,Prec
		MOV		EAX,EDI
		CDQ
		IDIV		EBX
		SHL		ESI,Prec
		MOVD		mm7,EAX ; mm7 = left or deb X Pnt
		MOV		EBX,[MYP1]

		MOV		EAX,ESI
		SUB		EBX,[MYP3]
		CDQ
		IDIV		EBX
		MOVQ		mm5,mm7 ; mm5 : acc pnt left X
		MOVD		mm6,EAX ; mm6 = right or fin X Pnt
		MOVD		EDX,mm2 ; Add Deb
		MOVD		mm4,EAX ; mm4 : acc pnt right X
		LEA		EDX,[EDX+EBP*2]
		MOVD		EAX,mm0
		MOV		EBP,[_MScanLine]
ALIGN 4
%%BcFillRgtTri:
		MOVQ		mm2,mm5 ; acc deb
		MOVQ		mm3,mm4 ; acc end
		PSRAD		mm2,Prec
		PSRAD		mm3,Prec
		MOVD		EDI,mm2
		PADDD		mm5,mm7
		MOVD		ESI,mm3
		PADDD		mm4,mm6

		LEA		EDI,[EDI*2+EDX]
		;@SolidHLine16
%%EndRgtTriHLine:
		DEC		EBX
		LEA		EDX,[EDX+EBP] ; += MScanLine or -= MScanLine
		JNZ		SHORT %%BcFillRgtTri
		MOVD		EBX,mm1
		MOV		EAX,[MXP2]
		OR		EBX,EBX
		JZ		SHORT %%EndRightTri
		SUB		EAX,[MXP3]
		MOV		ESI,EDX ; save curr addr deb
		SHL		EAX,Prec
		PSUBD		mm4,mm6 ; remove the last added right pnt
		CDQ
		IDIV		EBX
		MOVD		mm6,EAX ; mm4 : pnt right X
		MOV		EDX,ESI ; restore curr addr deb
		PXOR		mm1,mm1 ; set v3.y - v2.y = 0 to end next time
		MOVD		EAX,mm0
		JMP		%%BcFillRgtTri
%%EndRightTri:
		RET
%%LeftTri:
		; case   /|    ~~~~~~~~~~~
		;       / |
		;       \ |
		;	 \|

		MOV		EAX,[ESI+ECX] ; v2.y
		MOV		[MYP2],EAX
		MOV		[MYP1],EBX
		SUB		EAX,EDX ; v2.y - v3.y
		MOV		ECX,[MVectXPlus]
		MOVD		mm1,EAX
		MOV		EAX,[EDI+ECX] ; v1.x
		MOV		EDI,[ESI+ECX] ; V2.x
		MOV		ESI,[EBP+ECX] ; V3.x
		MOV		[MXP2],EDI
		MOV		[MXP3],ESI
		MOV		EBP,[MDebYPoly]
		SUB		EDI,EAX ; delta x2-x1
		SUB		ESI,EAX ; delta x3-x1
		MOVD		mm2,[_MTSurfAdDeb+EBP*4] ; = addr deb v1.y - 1
		SUB		EBX,EDX ; deltaY

		MOV		EBP,EAX
		SHL		ESI,Prec
		MOV		EAX,ESI
		CDQ
		IDIV		EBX
		SHL		EDI,Prec
		MOVD		mm6,EAX ; mm6 = Right/End X Pnt
		MOV		EBX,[MYP1]

		MOV		EAX,EDI
		SUB		EBX,[MYP2]
		CDQ
		IDIV		EBX
		MOVQ		mm4,mm6 ; mm4 : acc pnt right X
		MOVD		mm7,EAX ; mm7 = left/deb X Pnt
		MOVD		EDX,mm2 ; Add Deb
		MOVD		mm5,EAX ; mm5 : acc pnt left/deb X
		LEA		EDX,[EDX+EBP*2]
		MOVD		EAX,mm0
		MOV		EBP,[_MScanLine]
ALIGN 4
%%BcFillLftTri:
		MOVQ		mm2,mm5 ; acc deb
		MOVQ		mm3,mm4 ; acc end
		PSRAD		mm2,Prec
		PSRAD		mm3,Prec
		MOVD		EDI,mm2
		PADDD		mm5,mm7
		MOVD		ESI,mm3
		PADDD		mm4,mm6

		LEA		EDI,[EDI*2+EDX]
		;@SolidHLine16
%%EndLftTriHLine:
		DEC		EBX
		LEA		EDX,[EDX+EBP] ; += MScanLine or -= MScanLine
		JNZ		SHORT %%BcFillLftTri
		
		MOVD		EBX,mm1
		MOV		EAX,[MXP3]
		OR		EBX,EBX
		JZ		SHORT %%EndLeftTri
		SUB		EAX,[MXP2]
		MOV		ESI,EDX ; save curr addr deb
		SHL		EAX,Prec
		PSUBD		mm5,mm7 ; remove the last added left pnt
		CDQ
		IDIV		EBX
		MOVD		mm7,EAX ; update mm7 : pnt left/Deb X
		MOV		EDX,ESI ; restore curr addr deb
		PXOR		mm1,mm1 ; set v3.y - v2.y = 0 to end next time
		MOVD		EAX,mm0
		JMP		%%BcFillLftTri
%%EndLeftTri:
;/////////////////////////////

%endmacro
