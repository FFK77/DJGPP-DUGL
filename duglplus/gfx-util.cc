#include <stdio.h>
#include <stdlib.h>
#include <dugl.h>

// resize a 16bpp DgSurf into an another DgSurf
void resizeSurf16(DgSurf *SDstSurf,DgSurf *SSrcSurf, bool swapHz = false, bool swapVt = false)
{

  if (SDstSurf->BitsPixel != 16 || SSrcSurf->BitsPixel != 16)
    return;

  if (!swapHz && !swapVt &&
      SDstSurf->ResH == SSrcSurf->ResH && SDstSurf->ResV == SSrcSurf->ResV) {
     SurfCopy(SDstSurf, SSrcSurf);
     return;
  }

  DgSurf OldSurf,SrcSurf;
  DgSurf *SSrc=SSrcSurf;

  int srcMinX = 0;
  int srcMinY = 0;
  int srcMaxX = 0;
  int srcMaxY = 0;


  if (swapHz) {
    srcMinX = SSrcSurf->MaxX;
    srcMaxX = SSrcSurf->MinX;
  }
  else
  {
    srcMinX = SSrcSurf->MinX;
    srcMaxX = SSrcSurf->MaxX;
  }
  if (swapVt) {
    srcMinY = SSrcSurf->MaxY;
    srcMaxY = SSrcSurf->MinY;
  }
  else
  {
    srcMinY = SSrcSurf->MinY;
    srcMaxY = SSrcSurf->MaxY;
  }
  // textured poly points
  //                 X              Y              Z    XT = U   YT = V
  int Pt1[5] = { SDstSurf->MinX, SDstSurf->MinY,   0,   srcMinX, srcMinY };
  int Pt2[5] = { SDstSurf->MaxX, SDstSurf->MinY,   0,   srcMaxX, srcMinY };
  int Pt3[5] = { SDstSurf->MaxX, SDstSurf->MaxY,   0,   srcMaxX, srcMaxY };
  int Pt4[5] = { SDstSurf->MinX, SDstSurf->MaxY,   0,   srcMinX, srcMaxY };
  // points List
  int ListPt1[] = {  4,  (int)&Pt1, (int)&Pt2, (int)&Pt3, (int)&Pt4 };

  // save the source DgSurf In case the CurSurf is the source
  if (SSrcSurf==&CurSurf) {
     SrcSurf=*SSrcSurf;
     SSrc=&SrcSurf;
  }

  // Get Current DgSurf
  DgGetCurSurf(&OldSurf);

  // set dest DgSurf as destination
  DgSetCurSurf(SDstSurf);

  // draw the resize polygone inside the dest DgSurf
  Poly16(ListPt1, SSrc, POLY16_TEXT, 0);

  // restore
  DgSetCurSurf(&OldSurf);
}
