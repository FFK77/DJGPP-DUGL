#ifndef DBMFONT_H_INCLUDED
#define DBMFONT_H_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    DgSurf*     CharsSSurfs[256]; // array of pointer of DGSurf* of each char
    int         CharsPlusX[256]; // array of integer of delta x in pixels after rendering the char
    int         CharsWidth[256]; // array of integer of char width in pixels
    int         CharsHeight[256]; // array of integer of char height in pixels
    int         CharsXOffset[256]; // x position of the char Surf on the square charsWidth[i] x CharsGHeight
    int         CharsYOffset[256]; // y position of the char Surf on the square charsWidth[i] x CharsGHeight
    int         CharsGHeight; // Global Height of this list of chars or distance between lines
    int         CharsGLineHeight; // Global Height starting from ground line
    int         CharX; // X position of next char to render
    int         CharY; // Y position of next char to render
    int         CharCurChar; // current char to render
    DgSurf*     CharsMainSurf; // pointer to single DGSurf, if all chars DGSurf point/share to/same single DGSurf
    int         RendX;
    int         RendY;
} DBMFONT;

typedef enum {
    BMFONT_ADJUST_SRC = 0,
    BMFONT_ADJUST_DST = 1,
    BMFONT_ADJUST_MID = 2
} DBMFONT_ADJUST;

typedef void (*OutTextBM16PTR)(const char*);

extern DBMFONT       CurDBMFONT; // current active Bitmap FONT
extern DBMFONT       dummyDBMFONT; // dummy output less font

bool LoadBMFONT(DBMFONT **resDBMFONT, char *fileDescName, DgSurf *AllCharsSurf);
void DestroyBMFONT(DBMFONT *pBMFONT);
void SetCurBMFont(DBMFONT *pBMFONT);
// text width in pixels
int  WidthBMText(DBMFONT *pBMFONT, char *str);
// text width taking only Pos characters
int  WidthPosBMText(DBMFONT *pBMFONT, char *str,int pos);
// Position in *str if we progress by "width" pixels, return -1 if we crossed string boundaries
int  PosWidthBMText(DBMFONT *pBMFONT, char *str,int  width);
// output str in (CurDBMFONT.CharX, CurDBMFONT.CharY)
void OutTextBM16(char *str);
// output str in current CharY, charX will depend on text with and adjust mode
void OutTextBMMode16(char *str, DBMFONT_ADJUST bmfont_adjust);
// output multilines str ('\n' as line separator) between (CurDBMFONT.CharX, CurDBMFONT.CharY) depending on adjust param
void OutMultiLinesTextBM16(char *str, int MaxLines, DBMFONT_ADJUST bmfont_adjust);
// output formatted str in (CurDBMFONT.CharX, CurDBMFONT.CharY)
#define OutTextBM16Format(OutTextBM16, midStr, sizeMidStr, fmt, ...) snprintf(midStr, sizeMidStr, fmt, __VA_ARGS__); OutTextBM16(midStr);
// output formatted multilines str between depending on adjust param
#define OutMultiLinesTextBM16Format(maxLines, BMFONT_ADJUST, midStr, sizeMidStr, fmt, ...)\
        snprintf(midStr, sizeMidStr, fmt, __VA_ARGS__);\
        OutMultiLinesTextBM16(midStr, maxLines, BMFONT_ADJUST);
// reset text pos on CurSurf view
#define BMFONT_RESET_TEXTPOS(BMFONT, DGCURSURF) BMFONT.CharX = DGCURSURF.MinX;  BMFONT.CharY = DGCURSURF.MaxY - BMFONT.CharsGHeight;
// set text pos (x, y) for next output
#define BMFONT_SET_TEXTPOS(BMFONT, X, Y) BMFONT.CharX = (X);  BMFONT.CharY = (Y);

#ifdef __cplusplus
        }  // extern "C" {
#endif

#endif // DBMFONT_H_INCLUDED

