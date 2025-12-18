

;******* TRI_TYPE = SOLID

;-------------------------------------------------------
; in	EDI ptrV1, ESI ptrV2, EBP ptrV3
;	EAX, EBX, ECX, EDX tri(maxx, maxy, minx, miny)

ALIGN 32
InFillMTriSOLID16:

		MOV		EAX,[MVectColPlus]
		MOV		ECX,[MVectYPlus]
		MOVD		mm0,[EDI+EAX] ; V1.col
		; put vertices on a good order : V1 upper
		CMP		EBX,[EDI+ECX] ; maxy == V1.y ?
		PUNPCKLWD	mm0,mm0 ; prepare color mm0 for fastfill
		JE		SHORT .VertexOrdOK
		CMP		EBX,[ESI+ECX]
		JE		.Vertex2Up
.Vertex3Up:	XCHG		EBP,EDI
		XCHG		ESI,EBP
		JMP		SHORT .VertexOrdOK
.Vertex2Up:	XCHG		ESI,EDI
		XCHG		ESI,EBP
.VertexOrdOK:
		;check which kind of triangle is this ?
		; (right, left, down, up)

		CMP		[EBP+ECX],EBX ; v3.y == maxy ? => down tri
		PUNPCKLDQ	mm0,mm0
		JE		.DownTri
		CMP		[ESI+ECX],EBX ; v2.y == maxy ? => down tri
		JE		.DownTri
		
		CMP		[EBP+ECX],EDX ; v3.y != miny ? => right tri
		JNE		.RightTri
		CMP		[ESI+ECX],EDX ; v2.y != miny ? => left tri
		JNE		.LeftTri

.UpTri:
		; case    ^   ~~~~~~~~~~~
		;        / \
		;        ---
		
		MOV		ECX,[MVectXPlus]
		MOV		EAX,[EDI+ECX] ; v1.x
		MOV		EDI,[ESI+ECX] ; V2.x
		MOV		ESI,[EBP+ECX] ; V3.x
		MOV		EBP,[_MOrgY]
		SUB		EDI,EAX ; delta x2-x1
		LEA		EBP,[EBP+EBX] ; EBP = v1.y + _MOrgY : real Y
		SUB		ESI,EAX ; delta x3-x1
		MOVD		mm2,[_MTSurfAdDeb+EBP*4-4] ; = addr deb v1.y - 1
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
		LEA		EDX,[EDX+EBP*2]
		MOVD		EAX,mm0 ; fill color 16bits | 16bits
		MOV		EBP,[_MScanLine]
ALIGN 4
.BcFillUpTri:
		MOVQ		mm2,mm5 ; acc deb
		MOVQ		mm3,mm4 ; acc end
		PSRAD		mm2,Prec
		PSRAD		mm3,Prec
		MOVD		EDI,mm2
		PADDD		mm5,mm7
		MOVD		ESI,mm3
		PADDD		mm4,mm6

		SUB		ESI,EDI
		JZ		SHORT .EndUpTriHLine
		JNS		SHORT .UpTriDebEndOk
		NEG		ESI
		MOVD		EDI,mm3
.UpTriDebEndOk:
		LEA		EDI,[EDI*2+EDX]
		@SolidHLine16
.EndUpTriHLine:
		DEC		EBX
		LEA		EDX,[EDX+EBP] ; += MScanLine or -= MScanLine
		JNZ		SHORT .BcFillUpTri
		RET

.DownTri:
		; case  ----    ~~~~~~~~~~~
		;       \  /
		;        \/
		
		CMP		EDX,[ESI+ECX] ; miny = v2.y ?
		JE		SHORT .Vertex2Down
.Vertex3Down:	XCHG		EBP,EDI ; swap ptr v3, v1
		XCHG		ESI,EBP ; swap ptr v2, v3
		JMP		SHORT .VertexDownOK
.Vertex2Down:	XCHG		ESI,EDI ; swap ptr v2, v1
		XCHG		ESI,EBP ; swap ptr v2, v3
.VertexDownOK:
		MOV		ECX,[MVectXPlus]
		MOV		EAX,[EDI+ECX] ; v1.x
		MOV		EDI,[ESI+ECX] ; V2.x
		MOV		ESI,[EBP+ECX] ; V3.x

		MOV		EBP,[_MOrgY]
		SUB		EDI,EAX ; delta x2-x1
		LEA		EBP,[EBP+EDX]
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
		LEA		EDX,[EDX+EBP*2]
		PXOR		mm4,mm4 ; mm4 : acc pnt right X
		MOV		EBP,[_MScanLine]
		MOVD		EAX,mm0
		NEG		EBP
		JMP		.BcFillUpTri

.RightTri:
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
		MOV		EBP,[_MOrgY]
		SUB		EDI,EAX ; delta x2-x1
		LEA		EBP,[EBP+EBX]
		SUB		ESI,EAX ; delta x3-x1
		MOVD		mm2,[_MTSurfAdDeb+EBP*4-4] ; = addr deb v1.y - 1
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
.BcFillRgtTri:
		MOVQ		mm2,mm5 ; acc deb
		MOVQ		mm3,mm4 ; acc end
		PSRAD		mm2,Prec
		PSRAD		mm3,Prec
		MOVD		EDI,mm2
		PADDD		mm5,mm7
		MOVD		ESI,mm3
		PADDD		mm4,mm6

		SUB		ESI,EDI
		JZ		SHORT .EndRgtTriHLine
		JNS		SHORT .RgtTriDebEndOk
		NEG		ESI
		MOVD		EDI,mm3
.RgtTriDebEndOk:
		LEA		EDI,[EDI*2+EDX]
		@SolidHLine16
.EndRgtTriHLine:
		DEC		EBX
		LEA		EDX,[EDX+EBP] ; += MScanLine or -= MScanLine
		JNZ		SHORT .BcFillRgtTri
		MOVD		EBX,mm1
		MOV		EAX,[MXP2]
		OR		EBX,EBX
		JZ		SHORT .EndRightTri
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
		JMP		.BcFillRgtTri
.EndRightTri:
		RET
.LeftTri:
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
		MOV		EBP,[_MOrgY]
		SUB		EDI,EAX ; delta x2-x1
		LEA		EBP,[EBP+EBX]
		SUB		ESI,EAX ; delta x3-x1
		MOVD		mm2,[_MTSurfAdDeb+EBP*4-4] ; = addr deb v1.y - 1
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
.BcFillLftTri:
		MOVQ		mm2,mm5 ; acc deb
		MOVQ		mm3,mm4 ; acc end
		PSRAD		mm2,Prec
		PSRAD		mm3,Prec
		MOVD		EDI,mm2
		PADDD		mm5,mm7
		MOVD		ESI,mm3
		PADDD		mm4,mm6

		SUB		ESI,EDI
		JZ		SHORT .EndLftTriHLine
		JNS		SHORT .LftTriDebEndOk
		NEG		ESI
		MOVD		EDI,mm3
.LftTriDebEndOk:
		LEA		EDI,[EDI*2+EDX]
		@SolidHLine16
.EndLftTriHLine:
		DEC		EBX
		LEA		EDX,[EDX+EBP] ; += MScanLine or -= MScanLine
		JNZ		SHORT .BcFillLftTri
		
		MOVD		EBX,mm1
		MOV		EAX,[MXP3]
		OR		EBX,EBX
		JZ		SHORT .EndLeftTri
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
		JMP		.BcFillLftTri
.EndLeftTri:
		RET


.EndInFillMTri:
;		MOV		DWORD [_MTPolyAdDeb],36 ;////////////
;		MOV		DWORD [_MTPolyAdFin],EBX ;////////////
;		MOV		DWORD [_MTPolyAdFin+4],EAX ;////////////
;		MOV		DWORD [_MTPolyAdFin+8],EDI ;////////////
;		MOV		DWORD [_MTPolyAdFin+12],ESI ;////////////

		RET

;------------------------------------------------------
; in	EDI ptrV1, ESI ptrV2, EBP ptrV3
;	EAX, EBX, ECX, EDX tri(maxx, maxy, minx, miny)

ALIGN 32
ClipFillMTriSOLID16:
		; drop too BIG tri
		SUB		EBX,EDX  ; deltaY
		SUB		EAX,ECX  ; deltaX
		CMP		EBX,MaxDeltaDim
		JL		SHORT .CDyOK
		RET
.CDyOK:
		CMP		EAX,MaxDeltaDim
		LEA		EBX,[EBX+ECX] ; restore MaxY
		JL		SHORT .CDxOK
		RET
.CDxOK:
		MOV		EAX,[MVectColPlus]
		MOV		ECX,[MVectYPlus]
		MOVD		mm0,[EDI+EAX] ; V1.col
		; put vertices on a good order : V1 upper
		CMP		EBX,[EDI+ECX] ; maxy == V1.y ?
		PUNPCKLWD	mm0,mm0 ; prepare color mm0 for fastfill
		JE		SHORT .VertexOrdOK
		CMP		EBX,[ESI+ECX]
		JE		.Vertex2Up
.Vertex3Up:	XCHG		EBP,EDI
		XCHG		ESI,EBP
		JMP		SHORT .VertexOrdOK
.Vertex2Up:	XCHG		ESI,EDI
		XCHG		ESI,EBP
.VertexOrdOK:
		; save tri Y BoundingBox
		MOV		[MTriMinY],EDX
		MOV		[MTriMaxY],EBX
		; check the special tri corner clipped case ---------------
		MOV		EDX,[MVectXPlus]
		; ## top-right corner ##
		; (v1.x > maxX || v1.y > maxY) && (v2.x > maxX || v2.y > maxY) && (v3.x > maxX || v3.y > maxY)
.TopRghtCrClpT:
		MOV		EBX,[EDI+ECX] ; v1.y
		MOV		EAX,[EDI+EDX] ; v1.x
		CMP		EBX,[_MMaxY]  ; v1.y <= MaxY test faild
		JLE		SHORT .TopLftCrClpT
		CMP		EAX,[_MMaxX]  ; v1.x <= MaxX  => fail
		JLE		SHORT .TopLftCrClpT
		MOV		EBX,[ESI+ECX] ; v2.y
		MOV		EAX,[ESI+EDX] ; v2.x
		CMP		EBX,[_MMaxY]  ; v2.y <= MaxY test faild
		JLE		SHORT .TopLftCrClpT
		CMP		EAX,[_MMaxX]  ; v2.x <= MaxX  => fail
		JLE		SHORT .TopLftCrClpT
		MOV		EBX,[EBP+ECX] ; v3.y
		MOV		EAX,[EBP+EDX] ; v3.x
		CMP		EBX,[_MMaxY]  ; v3.y <= MaxY test faild
		JLE		SHORT .TopLftCrClpT
		CMP		EAX,[_MMaxX]  ; v3.x <= MaxX  => fail
		JLE		SHORT .TopLftCrClpT
		JMP		.TopRghtCrClp
		; ## top-left corner ##
		; (v1.x < minX || v1.y > maxY) && (v2.x < minX || v2.y > maxY) && (v3.x < minX || v3.y > maxY)
.TopLftCrClpT:
		MOV		EBX,[EDI+ECX] ; v1.y
		MOV		EAX,[EDI+EDX] ; v1.x
		CMP		EBX,[_MMaxY]  ; v1.y <= MaxY test faild
		JLE		SHORT .BotLftCrClpT
		CMP		EAX,[_MMinX]  ; v1.x >= MinX  => fail
		JGE		SHORT .BotLftCrClpT
		MOV		EBX,[ESI+ECX] ; v2.y
		MOV		EAX,[ESI+EDX] ; v2.x
		CMP		EBX,[_MMaxY]  ; v2.y <= MaxY test faild
		JLE		SHORT .BotLftCrClpT
		CMP		EAX,[_MMinX]  ; v2.x >= MinX  => fail
		JGE		SHORT .BotLftCrClpT
		MOV		EBX,[EBP+ECX] ; v3.y
		MOV		EAX,[EBP+EDX] ; v3.x
		CMP		EBX,[_MMaxY]  ; v3.y <= MaxY test faild
		JLE		SHORT .BotLftCrClpT
		CMP		EAX,[_MMinX]  ; v3.x >= MinX  => fail
		JGE		SHORT .BotLftCrClpT
		JMP		.TopLftCrClp

		; ## bottom-left corner ##
		; (v1.x < minX || v1.y < minY) && (v2.x < minX || v2.y > minY) && (v3.x < minX || v3.y < minY)
.BotLftCrClpT:
		MOV		EBX,[EDI+ECX] ; v1.y
		MOV		EAX,[EDI+EDX] ; v1.x
		CMP		EBX,[_MMinY]  ; v1.y >= MinY test faild
		JGE		SHORT .BotRghtCrClpT
		CMP		EAX,[_MMinX]  ; v1.x >= MinX  => fail
		JGE		SHORT .BotRghtCrClpT
		MOV		EBX,[ESI+ECX] ; v2.y
		MOV		EAX,[ESI+EDX] ; v2.x
		CMP		EBX,[_MMinY]  ; v2.y >= MinY test faild
		JGE		SHORT .BotRghtCrClpT
		CMP		EAX,[_MMinX]  ; v2.x >= MinX  => fail
		JGE		SHORT .BotRghtCrClpT
		MOV		EBX,[EBP+ECX] ; v3.y
		MOV		EAX,[EBP+EDX] ; v3.x
		CMP		EBX,[_MMinY]  ; v3.y >= MinY test faild
		JGE		SHORT .BotRghtCrClpT
		CMP		EAX,[_MMinX]  ; v3.x >= MinX  => fail
		JGE		SHORT .BotRghtCrClpT
		JMP		.BotLftCrClp

		; ## bottom-right corner ##
		; (v1.x > maxX || v1.y < minY) && (v2.x > maxX || v2.y > minY) && (v3.x > maxX || v3.y < minY)
.BotRghtCrClpT:
		MOV		EBX,[EDI+ECX] ; v1.y
		MOV		EAX,[EDI+EDX] ; v1.x
		CMP		EBX,[_MMinY]  ; v1.y >= MinY test faild
		JGE		SHORT .EndCrClpT
		CMP		EAX,[_MMaxX]  ; v1.x <= MaxX  => fail
		JLE		SHORT .EndCrClpT
		MOV		EBX,[ESI+ECX] ; v2.y
		MOV		EAX,[ESI+EDX] ; v2.x
		CMP		EBX,[_MMinY]  ; v2.y >= MinY test faild
		JGE		SHORT .EndCrClpT
		CMP		EAX,[_MMaxX]  ; v2.x <= MaxX  => fail
		JLE		SHORT .EndCrClpT
		MOV		EBX,[EBP+ECX] ; v3.y
		MOV		EAX,[EBP+EDX] ; v3.x
		CMP		EBX,[_MMinY]  ; v3.y >= MinY test faild
		JGE		SHORT .EndCrClpT
		CMP		EAX,[_MMaxX]  ; v3.x <= MaxX  => fail
		JLE		SHORT .EndCrClpT
		JMP		.BotRghtCrClp
.EndCrClpT:
		; check of corner clipped cases failed restore Y Tri BBox
		MOV		EBX,[MTriMaxY]
		MOV		EDX,[MTriMinY]
		
		;check which kind of triangle is this ?
		; (right, left, down, up)

		CMP		[EBP+ECX],EBX ; v3.y == maxy ? => down tri
		PUNPCKLDQ	mm0,mm0
		JE		.DownTri
		CMP		[ESI+ECX],EBX ; v2.y == maxy ? => down tri
		JE		.DownTri
		
		CMP		[EBP+ECX],EDX ; v3.y != miny ? => right tri
		JNE		.RightTri
		CMP		[ESI+ECX],EDX ; v2.y != miny ? => left tri
		JNE		.LeftTri

.UpTri:
		; case    ^   ~~~~~~~~~~~
		;        / \
		;        ---

		MOV		ECX,[MVectXPlus]
		MOV		ESI,[EBP+ECX] ; V3.x
		MOV		EAX,[EDI+ECX] ; v1.x
		MOV		EDI,[ESI+ECX] ; V2.x
		; compute TriDeb/EndY and PlusY
		XOR		EBP,EBP
		MOV		ECX,[_MMaxY]
		CMP		EBX,ECX ; TRiMaxY <= MMaxY ?
		JLE		SHORT .NoUpClipUtr
		MOV		EBP,EBX
		MOV		[MTriDebY],ECX ; DebY = MMaxY
		SUB		EBP,ECX ; PlusY = TriMaxY - MMaxY
		JMP		SHORT .UpClipDoneUtr
.NoUpClipUtr:	LEA		ECX,[EBX-1] ; DebY if no clip we skip one hline
		OR		EBP, BYTE 1 ; PlusY only one line
		MOV		[MTriDebY],ECX
.UpClipDoneUtr:
		MOV		ECX,[_MMinY]
		CMP		EDX,ECX ; TRiMaxY <= MMaxY ?
		JGE		SHORT .NoDownClipUtr
		MOV		[MTriEndY],ECX ; = MinY
		JMP		SHORT .DownClipDoneUtr
.NoDownClipUtr: MOV		[MTriEndY],EDX ; = Tri.MinY
.DownClipDoneUtr:
		SUB		EDI,EAX ; delta x2-x1
		SUB		ESI,EAX ; delta x3-x1
		SUB		EBX,EDX ; deltaY

		MOV		ECX,EAX ; EBP = v1.x
		SHL		EDI,Prec ; delta x2-x1 << Prec
		SHL		ECX,Prec ; = x1 << prec
		MOV		EAX,EDI
		CDQ
		IDIV		EBX
		SHL		ESI,Prec
		MOVD		mm7,EAX ; mm7 = left or deb X Pnt
		IMUL		EAX,EBP ; PlusY * PntDeb
		MOVD		mm3,ECX ; mm3 = x1 << prec
		MOVD		mm5,EAX ; mm5 : acc pnt left X
		MOV		EAX,ESI
		CDQ
		IDIV		EBX
		PADDD		mm5,mm3 ; AccPntDeb += x1 << Prec
		MOVD		mm6,EAX ; mm6 = right or fin X Pnt
		IMUL		EAX,EBP ; PlusY * PntFin
		MOV		EBX,[MTriDebY]
		MOVD		mm4,EAX ; mm4 : acc pnt right X
		MOV		EDX,EBX
		PADDD		mm4,mm3 ; AccPntFin += x1 << Prec
		MOV		EDX,[_MOrgY] ; y deb + orgY = real Y
		MOV		EBP,[_MScanLine]
		MOV		EDX,[_MTSurfAdDeb+EDX*4] ; EDX = AddrDeb
		INC		EBX
		MOVD		EAX,mm0 ; fill color 16bits | 16bits
		SUB		EBX,[MTriEndY]
ALIGN 4
.BcFillUpTri:
		MOVQ		mm2,mm5 ; acc deb
		MOVQ		mm3,mm4 ; acc end
		PSRAD		mm2,Prec ; x deb
		PSRAD		mm3,Prec ; x end
		MOVD		EDI,mm2  ; x deb
		PADDD		mm5,mm7
		MOVD		ESI,mm3  ; x end
		PADDD		mm4,mm6

		CMP		EDI,[_MMaxX]
		MOV		ECX,[_MMinX]
		JG		.EndUpTriHLine
		CMP		ESI,ECX
		JL		.EndUpTriHLine
		CMP		EDI,ECX
		JGE		.BoundXDebOK
		MOV		EDI,ECX
.BoundXDebOK:
		CMP		ESI,[_MMaxX]
		JLE		.BoundXEndOK
		MOV		ESI,[_MMaxX]
.BoundXEndOK:
		SUB		ESI,EDI
		JZ		SHORT .EndUpTriHLine
		JNS		SHORT .UpTriDebEndOk
		NEG		ESI
		MOVD		EDI,mm3
.UpTriDebEndOk:
		LEA		EDI,[EDI*2+EDX]
		@SolidHLine16
.EndUpTriHLine:
		DEC		EBX
		LEA		EDX,[EDX+EBP] ; += MScanLine or -= MScanLine
		JNZ		.BcFillUpTri
		RET

.DownTri:
		; case  ----    ~~~~~~~~~~~
		;       \  /
		;        \/
		
		RET

.RightTri:
		; case   |\    ~~~~~~~~~~~
		;        | \
		;        | /
		;	 |/

		RET
.LeftTri:
		; case   /|    ~~~~~~~~~~~
		;       / |
		;       \ |
		;	 \|

.EndLeftTri:
		RET
.TopRghtCrClp:
		RET
.TopLftCrClp:
		RET
.BotLftCrClp:
		RET
.BotRghtCrClp:
		RET


;******* POLYTYPE = SOLID BLND
ALIGN 32
InFillMTriSOLID_BLND16:
		RET



ALIGN 32
ClipFillMTriSOLID_BLND16:
		RET
