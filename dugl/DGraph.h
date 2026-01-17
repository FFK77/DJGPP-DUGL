#ifndef DGRAPH_H
#define DGRAPH_H

typedef struct
{	int	vlfb;
	int	ResH, ResV;
	int	MaxX, MaxY, MinX, MinY;
	int	OrgY, OrgX;
	int	SizeSurf;
	int	OffVMem;
	int	rlfb;
	int	BitsPixel;
	int	ScanLine,Mask,NegScanLine;
} Surf;

typedef struct
{	int	OrgX, OrgY;
	int	MaxX, MaxY, MinX, MinY;
} View;

#define VMODE_SUPPORTED         1
#define VMODE_TTY               4
#define VMODE_COLOR             8
#define VMODE_GRAPHIC           16
#define VMODE_VGA               32
#define VMODE_VGAW              64
#define VMODE_LFB               128

typedef struct
{	int    	ResHz;
	int	    ResVt;
	int	    rlfb;
	short  	Mode;
	short   VModeFlag;
	char	BitPixel;
	char	VtFreq,resv;
} ModeInfo;

//** CHR FONT FORMAT ****************************
typedef struct
{	int		DatCar;
	char	        PlusX,PlusLgn;
	unsigned char   Ht,Lg;
} Caract;

typedef struct
{	int	       	Sign;  		// = "FCHR"
	char	       	MaxHautFnt,
		       	MaxHautLgn,
		       	MinPlusLgn,
		       	SensFnt;
	int	       	SizeDataCar,
			PtrBuff;
	int		Resv[28];
	Caract	       	C[256];
} HeadCHR;

typedef struct {
	int  		FntPtr;
	unsigned char	FntHaut,FntDistLgn;
	char		FntLowPos, FntHighPos,FntSens;
	unsigned char	FntTab,Fntrevb[2];
	int		FntX, FntY, FntCol,FntBCol,FntDresv;
} FONT;

// DUGL Graphics Global vars
extern	int	      NbVSurf,NbMode;
extern	Surf	      *VSurf;
extern	ModeInfo      *TbMode,CurMode;
extern	int	      CurModeVtFreq;
extern	unsigned int  SizeVMem;
extern  unsigned char VesaHiVers,VesaLoVers;

extern Surf CurSurf;
extern int  CurViewVSurf;
extern unsigned char TbDegCol[256*64];
extern void *PtrTbColConv;


#ifdef __cplusplus
extern "C" {
#endif

// *NEW* DUGL 1.1+ should be called before any floating point processing
#define FREE_MMX()  asm("EMMS\n")

// Init all the ressources needed to work with a DUGL VESA LFB Surf
int  InitVesa();
// free all the ressources alloued for VESA LFB
void CloseVesa();
// CPU tools
int  DetectCPUID();
void ExecCPUID(unsigned int VEAX,unsigned int *PEAX, unsigned int *PEBX,
	       unsigned int *PECX,unsigned int *PEDX);
int  DetectMMX();
// Init Any available VESA 8bpp or 16bpp Mode
int  InitVesaMode(int ResHz, int ResVt, char BitPixel,int NbVPage);
// Init the standard mode 0x3 text mode
void TextMode();
// standard VGA Wait Retrace
void WaitRetrace();

// Universal 8bpp 16bpp Surf Manipulation Functions
// ------------------------------------------------

int  SetSurf(Surf *S); // set *S as the current drawing Surf
void SetSrcSurf(Surf *S); // set *S as the current source Surf for texture or PutSurf ..
int  GetMaxResVSetSurf(); // Max Height in pixels for a surf used with SetSurf
void GetSurf(Surf *S); // get the current surf
void SetOrgSurf(Surf *S,int LOrgX,int LOrgY);
void SetSurfView(Surf *S, View *V);
void SetSurfInView(Surf *S, View *V);
void GetSurfView(Surf *S, View *V);
void SetOrgVSurf(int OrgX,int OrgY);
void SetVView(View *V);
void SetVInView(View *V);
int  CreateSurf(Surf **S, int ResHz, int ResVt, char BitPixel);
void DestroySurf(Surf *S);
int  CreateSurfBuff(Surf **S, int ResHz, int ResVt, char BitPixel,void *Buff);
void SurfCopy(Surf *Sdst,Surf *Ssrc);
// ** WARNING ** should be called only after a successfull InitVESA call
// set current visible Surf Index
extern  void (*ViewSurf)(int NbSurf);
// wait vertical retrace and set current visible Surf Index
extern  void (*ViewSurfWaitVR)(int NbSurf);

// Surf conversion Functions
// -------------------------
void ConvSurf16ToSurf8(Surf *S8Dst, Surf *S16Src);
void ConvSurf8ToSurf16(Surf *S16Dst, Surf *S8Src);
void ConvSurf8ToSurf16Pal(Surf *S16Dst, Surf *S8Src,void *PalBGR1024);
void Blur16(void *BuffImgDst, void *BuffImgSrc, int ImgWidth, int ImgHeight, int StartLine, int EndLine);
void BlurSurf16(Surf *S16Dst, Surf *S16Src); // use Blur16

// 16 bpp Surf Copy/Filter
// -----------------------
void SurfCopyBlnd16(Surf *S16Dst, Surf *S16Src,int colBlnd);
void SurfMaskCopyBlnd16(Surf *S16Dst, Surf *S16Src,int colBlnd);
void SurfCopyTrans16(Surf *S16Dst, Surf *S16Src,int trans);
void SurfMaskCopyTrans16(Surf *S16Dst, Surf *S16Src,int trans);

// 8 bpp Color palette and light table helper function
// ---------------------------------------------------
void PrBuildTbColConv(void *PalBGR1024,float PropBonus);
void BuildTbColConv(void *PalBGR1024);
void BuildTbDegCol(void *PalBGR1024);
void PrBuildTbDegCol(void *PalBGR1024,float PropBonus);
int  FindCol(int DebCol,int FinCol,int B,int G,int R,void *PalBGR1024);
int  PrFindCol(int DebCol,int FinCol,
               int B,int G,int R,void *PalBGR1024,float PropBonus);
// Set palette :** WARNING ** should be called only after a successfull InitVESA call
extern  void (*SetPalette)(int Dbcol, int Nbcol, void *BGRA);

// 8 bpp drawing functions
// -----------------------

void Clear(int clrcol);  // Clear All the current Surf with clrcol
// *Point is pointer to a struct { int X, int Y };
void PutPixel(void *Point,int col); // unclipped PutPixel
int  GetPixel(void *Point); // unclipped GetPixel
void Line(void *Point1,void *Point2,int col); // Clipped Line
void LineMap(void *Point1,void *Point2,int col,unsigned int Map); // Mapped line
// TypePoly
#define POLY_SOLID				0
#define POLY_TEXT				1
#define POLY_MASK_TEXT			2
#define POLY_FLAT_DEG			3
#define POLY_DEG				4
#define POLY_FLAT_DEG_TEXT		5
#define POLY_MASK_FLAT_DEG_TEXT	6
#define POLY_DEG_TEXT			7
#define POLY_MASK_DEG_TEXT		8
#define POLY_EFF_FLAT_DEG		9
#define POLY_EFF_DEG			10
#define POLY_EFF_COLCONV		11
#define POLY_MAX_TYPE			11
#define POLY_FLAG_DBL_SIDED		0x80000000
void Poly(void *ListPt, Surf *SS, unsigned int TypePoly, int ColPoly);
int  ValidSPoly(void *ListPt);
int  SensPoly(void *ListPt);

// Surf blitting functions
// PType : How the surf is blitted over the surf
#define NORM_PUT	0 // as it
#define INV_HZ_PUT	1 // reversed horizontally
#define INV_VT_PUT	2 // reversed vertically
void PutSurf(Surf *S,int X,int Y,int PType);
void PutMaskSurf(Surf *S,int X,int Y,int PType);

// 8 bpp Drawing helper functions provided for convenience
// -------------------------------------------------------

void ClearSurf(int clrcol);	// use Poly, clear current View
void line(int X1,int Y1,int X2,int Y2,int LgCol);
void linemap(int X1,int Y1,int X2,int Y2,int LgCol,unsigned int Map);
void putpixel(int X,int Y,int pcol);	// use PutPixel
void cputpixel(int X,int Y,int pcol); // clipped
int  getpixel(int X,int Y);	// use GetPixel
int  cgetpixel(int X,int Y); // clipped
void Bar(void *Pt1,void *Pt2,int bcol);  // use Poly
void bar(int x1,int y1,int x2,int y2,int bcol);  // use Poly
void rect(int x1,int y1,int x2,int y2,int rcol);
void rectmap(int x1,int y1,int x2,int y2,int rcol,unsigned int rmap);

// 16 bpp drawing functions
// ------------------------

#define RGB16(r,g,b) ((r>>3)|((g>>2)<<5)|((b>>3)<<11))

void PutPixel16(void *Point,int col);
int GetPixel16(void *Point);
void Clear16(int clrcol);  // efface tout la surface
void Line16(void *Point1,void *Point2,int col);
void LineMap16(void *Point1,void *Point2,int col,unsigned int Map);
void LineBlnd16(void *Point1,void *Point2,int col);
void LineMapBlnd16(void *Point1,void *Point2,int col,unsigned int Map);

#define POLY16_SOLID			0
#define POLY16_TEXT				1
#define POLY16_MASK_TEXT		2
#define POLY16_TEXT_TRANS       10
#define POLY16_MASK_TEXT_TRANS  11
#define POLY16_RGB              12
#define POLY16_SOLID_BLND		13
#define POLY16_TEXT_BLND		14
#define POLY16_MASK_TEXT_BLND	15
#define POLY16_MAX_TYPE			15
#define POLY16_FLAG_DBL_SIDED	0x80000000
void Poly16(void *ListPt, Surf *SS, unsigned int TypePoly, int ColPoly);

// 16 bpp Drawing helper functions provided for convenience
// -------------------------------------------------------

void ClearSurf16(int clrcol);	// Clear All the current 16bpp Surf view with clrcol
void line16(int X1,int Y1,int X2,int Y2,int LgCol);
void linemap16(int X1,int Y1,int X2,int Y2,int LgCol,unsigned int Map);
void lineblnd16(int X1,int Y1,int X2,int Y2,int LgCol);
void linemapblnd16(int X1,int Y1,int X2,int Y2,int LgCol,unsigned int Map);
void putpixel16(int X,int Y,int pcol);	// use PutPixel
void cputpixel16(int X,int Y,int pcol); // clipped
int  getpixel16(int X,int Y);	// use GetPixel
int  cgetpixel16(int X,int Y); // clipped
void cputpixelblnd16(int X,int Y,int pcol); // clipped
void CPutPixelBlnd16(void *Pt1,int pcol); // clipped

void Bar16(void *Pt1,void *Pt2,int bcol);  // use Poly16
void bar16(int x1,int y1,int x2,int y2,int bcol);  // use Poly16
void BarBlnd16(void *Pt1,void *Pt2,int bcol);  // use Poly16
void barblnd16(int x1,int y1,int x2,int y2,int bcol);  // use Poly16
void rect16(int x1,int y1,int x2,int y2,int rcol);
void rectmap16(int x1,int y1,int x2,int y2,int rcol,unsigned int rmap);
void rectblnd16(int x1,int y1,int x2,int y2,int rcol);
void rectmapblnd16(int x1,int y1,int x2,int y2,int rcol,unsigned int rmap);

// 16bpp Surf blitting functions
void PutSurf16(Surf *S,int X,int Y,int PType);
void PutMaskSurf16(Surf *S,int X,int Y,int PType);
void PutSurfBlnd16(Surf *S,int X,int Y,int PType,int colBlnd);
void PutMaskSurfBlnd16(Surf *S,int X,int Y,int PType,int colBlnd);
void PutSurfTrans16(Surf *S,int X,int Y,int PType,int trans);
void PutMaskSurfTrans16(Surf *S,int X,int Y,int PType,int trans);

// IMAGE Loading saving
// --------------------

// PCX
int  LoadMemPCX(Surf **S,void *In,void *PalBGR1024,int SizeIn);
int  LoadPCX(Surf **S,const char *Fname,void *PalBGR1024);
int  SaveMemPCX(Surf *S,void *Out,void *PalBGR1024);
int  SavePCX(Surf *S,const char *Fname,void *PalBGR1024);
int  SizeSavePCX(Surf *S);
void InRLE(void *InBuffRLE,void *Out,int LenOut);
void OutRLE(void *OutBuffRLE,void *In,int LenIn,int ResHz);
int  SizeOutRLE(void *In,int LenIn,int ResHz);

// GIF
int  LoadMemGIF(Surf **S,void *In,void *PalBGR1024,int SizeIn);
int  LoadGIF(Surf **S,const char *Fname,void *PalBGR1024);
int  LoadGIF16(Surf **S16,char *filename); // load a 8bpp gif and convert it to 16 bpp
int  SaveMemGIF(Surf *S,void *Out,void *PalBGR1024); // NI (not implemented)
int  SaveGIF(Surf *S,const char *Fname,void *PalBGR1024); // NI
int  SizeSaveGIF(Surf *S); // NI
void InLZW(void *InBuffLZW,void *Out);
void OutLZW(void *OutBuffLZW,void *In,int LenIn); // NI
int  SizeOutLZW(void *In,int LenIn,int ResHz); // NI

// BMP
int  LoadMemBMP(Surf **S,void *In,void *PalBGR1024,int SizeIn); // load a 8bpp uncompressed BMP into a 8bpp Surf
int  LoadBMP(Surf **S,const char *Fname,void *PalBGR1024);
int  SaveMemBMP(Surf *S,void *Out,void *PalBGR1024);
int  SaveBMP(Surf *S,const char *Fname,void *PalBGR1024); // save a 8bpp Surf into a 8bpp uncompressed BMP
int  SizeSaveBMP(Surf *S); // total size in bytes of a 8bpp bmp saved Surf
int  LoadMemBMP16(Surf **S,void *In,int SizeIn); // load a 24bpp uncompressed BMP into a 16bpp Surf
int  LoadBMP16(Surf **S,const char *Fname);
int  SaveMemBMP16(Surf *S,void *Out); // save  a 16bpp surf into a 24bpp uncompressed BMP
int  SaveBMP16(Surf *S,const char *Fname);
int  SizeSaveBMP16(Surf *S);

// FONT character loading, handling and drawing functions
// of the DUGL CHR FONT FORMAT
// ---------------------------------------------------------

extern FONT		CurFONT;
extern int		FntPtr, FntX, FntY, FntCol;
extern unsigned char	FntHaut, FntDistLgn, FntTab;
extern char		FntLowPos, FntHighPos,FntSens;
// Text drawing Mode
#define AJ_CUR_POS	0 // draw starting from the current xy test position
#define AJ_MID		1 // set the text on the middle of the current Surf View
#define AJ_SRC		2 // justify to the text source (left in case of left to right)
#define AJ_DST		3 // justify to the text destination
#define AJ_LEFT		4 // justify always to the left
#define AJ_RIGHT	5 // justify always to the right

int  LoadMemFONT(FONT *F,void *In,int SizeIn);
int  LoadFONT(FONT *F,const char *Fname);
void DestroyFONT(FONT *F);
void SetFONT(FONT *F);
void GetFONT(FONT *F);
void ClearText(); // clear text position inside the CurSurf current View
void SetTextAttrib(int TX,int TY,int TCol);
void SetTextPos(int TX,int TY);
void SetTextCol(int TCol); // set text color
int  GetXOutTextMode(const char *str,int Mode);
int  GetFntYMID();
int  LargText(const char *str); // text width in pixel
int  LargPosText(const char *str,int Pos);
int  PosLargText(const char *str,int Larg);
// Outputting Text without altering the CurSurf View
void ViewClearText(View *V);
int  ViewGetFntYMID(View *V);
int  ViewGetXOutTextMode(View *V,const char *str,int Mode);
// 8bpp
void OutText(const char *str);
void OutTextXY(int TX,int TY,const char *str);
int  OutTextMode(const char *str,int Mode);
int  OutTextYMode(int TY,const char *str,int Mode);
int  ViewOutTextMode(View *V,const char *str,int Mode);
int  ViewOutTextYMode(View *V,int TY,const char *str,int Mode);
int  ViewOutTextXY(View *V,int TX,int TY,const char *str);
// 16bpp
void OutText16(const char *str);
void OutText16XY(int TX,int TY,const char *str);
int  OutText16Mode(const char *str,int Mode);
int  OutText16YMode(int TY,const char *str,int Mode);
int  ViewOutText16Mode(View *V,const char *str,int Mode);
int  ViewOutText16YMode(View *V,int TY,const char *str,int Mode);
int  ViewOutText16XY(View *V,int TX,int TY,const char *str);


#ifdef __cplusplus
           }
#endif

#endif //#ifndef DGRAPH_H
