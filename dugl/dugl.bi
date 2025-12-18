#inclib "dugl" ' add the libdugl.a to the link

''  FreeBAsic translation of "DGraph.h" '''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
type Surf
	vlfb as integer ' could be also "any ptr"
	ResH as integer
	ResV as integer
	MaxX as integer
	MaxY as integer
	MinX as integer
	MinY as integer
	OrgY as integer
	OrgX as integer
	SizeSurf as integer ' size in bytes
	OffVMem as integer
	rlfb as integer ' could be also "any ptr"
	RMaxX as integer
	RMaxY as integer
	RMinX as integer
	RMinY as integer
	BitsPixel as integer
	ScanLine as integer ' size in bytes of a scanline
	Mask as integer
	Resv2 as integer
end type

type View
	OrgX as integer
	OrgY as integer
	MaxX as integer
	MaxY as integer
	MinX as integer
	MinY as integer
end type

''  graphics mode informations
#define VMODE_SUPPORTED 1
#define VMODE_TTY 4
#define VMODE_COLOR 8
#define VMODE_GRAPHIC 16
#define VMODE_VGA 32
#define VMODE_VGAW 64
#define VMODE_LFB 128

type ModeInfo
	ResHz as integer
	ResVt as integer
	rlfb as integer
	Mode as short
	VModeFlag as short
	BitPixel as byte
	VtFreq as byte
	resv as byte
end type


Extern "C" '' otherwise LD gets upset on case sensitivity :-(

extern CurSurf as Surf ' current drawing Surf
extern VSurf as Surf ptr ' an array of VRAM surf filled after InitVesaMode
extern NbVSurf as integer ' size of the array VSurf
extern NbMode as integer ' size of the array TbMode
extern TbMode as ModeInfo ptr ' array of the available video mode - filled after InitVesa
extern CurMode as ModeInfo ' current video mode
extern SizeVMem as uinteger ' size of VRAM on bytes
extern CurViewVSurf as integer ' index of the current viewer video page

' initialisation ''''''
Declare Function DetectCPUID As Uinteger
Declare Function DetectMMX   As Uinteger
Declare Sub ExecCPUID (Byval As Uinteger, Byval As Uinteger Ptr, Byval As Uinteger Ptr, Byval As Uinteger Ptr, Byval As Uinteger Ptr)
Declare Function InitVesa    As Uinteger
Declare Function InitVesaMode (Byval ResHz As Uinteger, Byval ResVt As Uinteger, Byval BitsPixel as UBYTE,Byval NbVP As Uinteger) As Uinteger
declare Sub WaitRetrace() ' VGA compatible wait retrace
Declare sub CloseVesa 
Declare Sub TextMode

' Surf Handling ''''''''''''''
Declare function SetSurf(byval S as Surf ptr) as integer
Declare function GetMaxResVSetSurf () as integer ' get max vertical resolution of a Surf that could be set as the CurSurf
Declare function CreateSurf(byval S as Surf ptr, byval ResHz as integer, byval ResVt as integer, byval BitPixel as byte) as integer
declare function CreateSurfBuff (byval S as Surf ptr, byval ResHz as integer, byval ResVt as integer, byval BitPixel as byte, byval Buff as any ptr) as integer
Declare sub DestroySurf(byval S as Surf ptr)

' View port ''''''''''''''''''
Declare sub SetOrgSurf (byval S as Surf ptr, byval LOrgX as integer, byval LOrgY as integer)
Declare sub SetSurfView (byval S as Surf ptr, byval V as View ptr)
Declare sub SetSurfRView (byval S as Surf ptr, byval V as View ptr)
Declare sub GetSurfView (byval S as Surf ptr, byval V as View ptr)
Declare sub GetSurfRView (byval S as Surf ptr, byval V as View ptr)
Declare sub SetSurfInView (byval S as Surf ptr, byval V as View ptr)
Declare sub SetSurfInRView (byval S as Surf ptr, byval V as View ptr)

' Surf Conversion ''''''''''''
Declare sub ConvSurf8ToSurf16Pal (byval S16Dst as Surf ptr, byval S8Src as Surf ptr, byval PalBGR1024 as any ptr)

' Drawing ''''''''''''''''''''
Declare sub Clear16 (byval clrcol as integer) ' clear all the current Surf
Declare sub ClearSurf16 (byval clrcol as integer) ' clear the current Surf View port
''Declare sub PutPixel16 (byval Point as any ptr, byval col as integer) '' isn't FreeBASIC case-sensitive :-( ?
Declare sub putpixel16 (byval X as integer, byval Y as integer, byval pcol as integer)
Declare sub cputpixel16 (byval X as integer, byval Y as integer, byval pcol as integer)
Declare sub cputpixelblnd16 (byval X as integer, byval Y as integer, byval pcol as integer)

Declare function getpixel16 (byval X as integer, byval Y as integer) as integer
Declare function cgetpixel16 (byval X as integer, byval Y as integer) as integer
Declare sub line16 (byval X1 as integer, byval Y1 as integer, byval X2 as integer, byval Y2 as integer, byval Col as integer)
Declare sub linemap16 (byval X1 as integer, byval Y1 as integer, byval X2 as integer, byval Y2 as integer, byval Col as integer,byval Mask as Uinteger )
Declare sub lineblnd16 (byval X1 as integer, byval Y1 as integer, byval X2 as integer, byval Y2 as integer, byval Col as integer)
Declare sub linemapblnd16 (byval X1 as integer, byval Y1 as integer, byval X2 as integer, byval Y2 as integer, byval Col as integer,byval Mask as Uinteger )

Declare sub bar16 (byval X1 as integer, byval Y1 as integer, byval X2 as integer, byval Y2 as integer, byval Col as integer)
Declare sub barblnd16 (byval X1 as integer, byval Y1 as integer, byval X2 as integer, byval Y2 as integer, byval Col as integer)
Declare sub rect16 (byval x1 as integer, byval y1 as integer, byval x2 as integer, byval y2 as integer, byval rcol as integer)
Declare sub rectmap16 (byval x1 as integer, byval y1 as integer, byval x2 as integer, byval y2 as integer, byval rcol as integer, byval rmap as uinteger)
Declare sub rectblnd16 (byval x1 as integer, byval y1 as integer, byval x2 as integer, byval y2 as integer, byval rcol as integer)
Declare sub rectmapblnd16 (byval x1 as integer, byval y1 as integer, byval x2 as integer, byval y2 as integer, byval rcol as integer, byval rmap as uinteger)
Declare sub PutSurf16 (byval S as Surf ptr, byval X as integer, byval Y as integer, byval PType as integer)
Declare sub PutMaskSurf16 (byval S as Surf ptr, byval X as integer, byval Y as integer, byval PType as integer)
' Poly16 ''''''''
' TypePoly''
#define POLY16_SOLID 0
#define POLY16_TEXT 1
#define POLY16_MASK_TEXT 2
#define POLY16_RGB 12
#define POLY16_SOLID_BLND 13
#define POLY16_TEXT_BLND 14
#define POLY16_MASK_TEXT_BLND 15
#define POLY16_MAX_TYPE 15
#define POLY16_FLAG_DBL_SIDED &h80000000 ' Or(ed) with typePoly set the poly as double sided
Declare sub Poly16 (byval ListPt as any ptr, byval SS as Surf ptr, byval TypePoly as uinteger, byval ColPoly as integer)
'' ListPt structure :
'' uinteger pointCount,  Point1 as any ptr, Point2 as any ptr, ... PointN as any ptr
'' point Structure
'' POLY16_SOLID          : (x as integer, y as integer)
'' POLY16_TEXT           : (x as integer, y as integer, z as integer, xt as integer, yt as integer)
'' POLY16_MASK_TEXT      : (x as integer, y as integer, z as integer, xt as integer, yt as integer)
'' POLY16_RGB            : (x as integer, y as integer, z as integer, xt as integer, yt as integer, col as integer)
'' POLY16_SOLID_BLND     : (x as integer, y as integer)
'' POLY16_TEXT_BLND      : (x as integer, y as integer, z as integer, xt as integer, yt as integer)
'' POLY16_MASK_TEXT_BLND : (x as integer, y as integer, z as integer, xt as integer, yt as integer)


' Image Load&Save ''''''''''''
' PCX
Declare function LoadMemPCX (byval S as Surf ptr, byval In as any ptr, byval PalBGR1024 as any ptr, byval SizeIn as integer) as integer
Declare function LoadPCX  (byval S as Surf ptr, byval Fname as zstring ptr, byval PalBGR1024 as any ptr) as integer
Declare function SaveMemPCX (byval S as Surf ptr, byval Out as any ptr, byval PalBGR1024 as any ptr) as integer
Declare function SavePCX (byval S as Surf ptr, byval Fname as zstring ptr, byval PalBGR1024 as any ptr) as integer
Declare function SizeSavePCX (byval S as Surf ptr) as integer
Declare sub InRLE (byval InBuffRLE as any ptr, byval Out as any ptr, byval LenOut as integer)
Declare sub OutRLE (byval OutBuffRLE as any ptr, byval In as any ptr, byval LenIn as integer, byval ResHz as integer)
Declare function SizeOutRLE (byval In as any ptr, byval LenIn as integer, byval ResHz as integer) as integer
' GIF
Declare function LoadMemGIF (byval S as Surf ptr, byval In as any ptr, byval PalBGR1024 as any ptr, byval SizeIn as integer) as integer
Declare function LoadGIF (byval S as Surf ptr, byval Fname as zstring ptr, byval PalBGR1024 as any ptr) as integer
Declare sub InLZW (byval InBuffLZW as any ptr, byval Out as any ptr)
' BMP 
Declare function LoadMemBMP (byval S as Surf ptr, byval In as any ptr, byval PalBGR1024 as any ptr, byval SizeIn as integer) as integer
Declare function LoadBMP (byval S as Surf ptr, byval Fname as zstring ptr, byval PalBGR1024 as any ptr) as integer
Declare function SaveMemBMP (byval S as Surf ptr, byval Out as any ptr, byval PalBGR1024 as any ptr) as integer
Declare function SaveBMP (byval S as Surf ptr, byval Fname as zstring ptr, byval PalBGR1024 as any ptr) as integer
Declare function SizeSaveBMP (byval S as Surf ptr) as integer
Declare function LoadMemBMP16 (byval S as Surf ptr, byval In as any ptr, byval SizeIn as integer) as integer
Declare function LoadBMP16 (byval S as Surf ptr, byval Fname as zstring ptr) as integer
Declare function SaveMemBMP16 (byval S as Surf ptr, byval Out as any ptr) as integer
Declare function SaveBMP16 (byval S as Surf ptr, byval Fname as zstring ptr) as integer
Declare function SizeSaveBMP16 (byval S as Surf ptr) as integer

End Extern
''  End DGraph.h ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
