#include <dos.h>
#include <dpmi.h>
#include <dos.h>
#include <go32.h>
#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <crt0.h>
#include <unistd.h>
#include <string.h>
#include <sys/movedata.h>
#include <sys/segments.h>
#include "dugl.h"
#include "intrdugl.h"

int 			MTPolyAdDeb[MaxResV],MTPolyAdFin[MaxResV];
int 			MTSurfAdDeb[MaxResV],MTSrcSurfAdDeb[MaxResV];
int			MTexXDeb[MaxResV],MTexXFin[MaxResV],
                        MTexYDeb[MaxResV],MTexYFin[MaxResV];
int 			MPColDeb[MaxResV],MPColFin[MaxResV];

void SetOrgMSurf(int IDSurf,int LOrgX,int LOrgY) {
   Surf *S = (IDSurf==0)?(&CurMSurf):(&CurMSrcSurf);
   int dox = LOrgX - S->OrgX;
   
   SetOrgSurf(S,LOrgX, LOrgY);
   MSetDeltaOrgX(IDSurf, dox);   
}

void SetMSurfView(int IDSurf, View *V) {
   Surf *S = (IDSurf==0)?(&CurMSurf):(&CurMSrcSurf);
   int dox = V->OrgX - S->OrgX;

   SetSurfView(S, V);
   MSetDeltaOrgX(IDSurf, dox);
}

void SetMSurfRView(int IDSurf, View *V) {
   Surf *S = (IDSurf==0)?(&CurMSurf):(&CurMSrcSurf);
   int dox = V->OrgX - S->OrgX;

   SetSurfRView(S, V);
   MSetDeltaOrgX(IDSurf, dox);
}

void SetMSurfInView(int IDSurf, View *V) {
   Surf *S = (IDSurf==0)?(&CurMSurf):(&CurMSrcSurf);
   int dox = V->OrgX - S->OrgX;

   SetSurfInView(S, V);
   MSetDeltaOrgX(IDSurf, dox);
}

void SetMSurfInRView(int IDSurf, View *V) {
   Surf *S = (IDSurf==0)?(&CurMSurf):(&CurMSrcSurf);
   int dox = V->OrgX - S->OrgX;

   SetSurfInRView(S, V);
   MSetDeltaOrgX(IDSurf, dox);
}



