#ifndef DFONT_H_INCLUDED
#define DFONT_H_INCLUDED

// FONT character loading, handling and drawing functions
// of the DUGL CHR FONT FORMAT
// ---------------------------------------------------------

extern DFONT	CurFONT;
extern int		FntPtr, FntX, FntY, FntCol;
extern unsigned char	FntHaut, FntDistLgn, FntTab;
extern char		FntLowPos, FntHighPos,FntSens;
// Text drawing Mode
#define AJ_CUR_POS	0 // draw starting from the current xy test position
#define AJ_MID		1 // set the text on the middle of the current DgSurf View
#define AJ_SRC		2 // justify to the text source (left in case of left to right)
#define AJ_DST		3 // justify to the text destination
#define AJ_LEFT		4 // justify always to the left
#define AJ_RIGHT	5 // justify always to the right

#ifdef __cplusplus
extern "C" {
#endif

int  LoadMemDFONT(DFONT *F,void *In,int SizeIn);
int  LoadDFONT(DFONT *F,const char *Fname);
void DestroyDFONT(DFONT *F);
void SetDFONT(DFONT *F);
void GetDFONT(DFONT *F);
void ClearText(); // clear text position inside the CurSurf current View
void SetTextAttrib(int TX,int TY,int TCol);
void SetTextPos(int TX,int TY);
void SetTextCol(int TCol); // set text color
int  GetXOutTextMode(const char *str,int Mode);
int  GetFntYMID();
int  WidthText(const char *str); // text width in pixel
int  WidthPosText(const char *str,int Pos);
int  PosWidthText(const char *str,int Larg);
// Outputting Text without altering the CurSurf View
void ViewClearText(DgView *V);
int  ViewGetFntYMID(DgView *V);
int  ViewGetXOutTextMode(DgView *V,const char *str,int Mode);
// 8bpp
void OutText(const char *str);
void OutTextXY(int TX,int TY,const char *str);
int  OutTextMode(const char *str,int Mode);
int  OutTextYMode(int TY,const char *str,int Mode);
void OutTextFormat(char *midStr, unsigned int sizeMidStr, char *fmt, ...);
void OutTextModeFormat(int Mode, char *midStr, unsigned int sizeMidStr, char *fmt, ...);
int  ViewOutTextMode(DgView *V,const char *str,int Mode);
int  ViewOutTextYMode(DgView *V,int TY,const char *str,int Mode);
int  ViewOutTextXY(DgView *V,int TX,int TY,const char *str);
// 16bpp
void OutText16(const char *str);
void OutText16XY(int TX,int TY,const char *str);
int  OutText16Mode(const char *str,int Mode);
int  OutText16YMode(int TY,const char *str,int Mode);
void OutText16Format(char *midStr, unsigned int sizeMidStr, char *fmt, ...);
void OutText16ModeFormat(int Mode, char *midStr, unsigned int sizeMidStr, char *fmt, ...);
int  ViewOutText16Mode(DgView *V,const char *str,int Mode);
int  ViewOutText16YMode(DgView *V,int TY,const char *str,int Mode);
int  ViewOutText16XY(DgView *V,int TX,int TY,const char *str);

#ifdef __cplusplus
           }
#endif


#endif // DFONT_H_INCLUDED
