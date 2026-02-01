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

// used to convert color
// lookup table to convert from 8bits paletted BGRA to true color 15,16, 24, 32 bits
// and from 15bits true color to 8bits paletted
unsigned short      Col8To15bpp[256];
unsigned short      Col8To16bpp[256];
unsigned int        Col8To32bpp[256];
unsigned char       Col15To8bpp[256*128];

// *************
unsigned char		CurPalette[1024];
int			        WindowControlPMI=0,ViewAddressPMI=0,SetPalPMI=0;
int			        CurModeVtFreq=0,NbVDgSurf=0,NbDgfxModes=0;
unsigned int 		addr;
unsigned int     	lfb,Sizelfb,SizeVMem;
void			    *VesaPMI=0;
unsigned short		SizeVesaPMI=0;
short              	dgfxMode = 0;
unsigned short		SelMPIO,
                    SizeMPIO;
unsigned int		AddMPIO,
                    MAPAddMPIO,
                    EnableMPIO;

DgSurf			    *VSurf=0;
ModeInfo		    *TbDgfxModes = NULL;
ModeInfo		    *CurDgfxMode = NULL;
__dpmi_meminfo	    dpinf;
VesaIntro 		    VesaInt;

char				ShiftPal=0,VesaPMIOk=0,MTRRa=0,Video=0,Buff_Accel=0;
unsigned char		VesaHiVers,VesaLoVers;
unsigned char		tmpAlignDD;

void (*ViewSurf)(int NSurf);
void (*ViewSurfWaitVR)(int NSurf);
void (*SetPalette)(int Dbcol, int Nbcol, void *Tcol);

int  DetectMMX();
int  EnableMTRR();
int EnableVesaMTRR();
void InitVesaPMI();
void GetPaletteDAC();
void RealSetPalette(int Dbcol, int Nbcol, void *Tcol);
void RealViewSurfSched(int NbSurf);
void RealViewSurf(int NbSurf);
void ProtectSetPalette(int Dbcol, int Nbcol, char* Tcol);
void ProtectViewSurf(int NbSurf);
void ProtectViewSurfWaitVR(int NbSurf);

void BlurSurf16(DgSurf *S16Dst, DgSurf *S16Src) {
    if (S16Dst==NULL || S16Src==NULL ||
            S16Dst->BitsPixel!=16 || S16Src->BitsPixel!=16 ||
            S16Dst->ResH!=S16Src->ResH ||
            S16Dst->ResV!=S16Src->ResV) return;
    Blur16((void*)(S16Dst->rlfb), (void*)(S16Src->rlfb), S16Src->ResH, S16Src->ResV, 0, (S16Src->ResV - 1));
}

void ConvSurf16ToSurf8(DgSurf *S8Dst, DgSurf *S16Src)
{	if (S8Dst==NULL || S16Src==NULL ||
	    S8Dst->BitsPixel!=8 || S16Src->BitsPixel!=16 ||
	    S8Dst->ResH!=S16Src->ResH ||
	    S8Dst->ResV!=S16Src->ResV) return;
	// convert buffers
	TrImgResHz=S8Dst->ResH;
	TrImgResVt=S8Dst->ResV;
	TrBuffImgSrc=(void*)(S16Src->rlfb);
	TrBuffImgDst=(void*)(S8Dst->rlfb);
	TransfB16ToB8();
}

void ConvSurf8ToSurf16(DgSurf *S16Dst, DgSurf *S8Src)
{	if (S8Src==NULL || S16Dst==NULL ||
	    S16Dst->BitsPixel!=16 || S8Src->BitsPixel!=8 ||
	    S8Src->ResH!=S16Dst->ResH ||
	    S8Src->ResV!=S16Dst->ResV) return;
	// convert buffers
	TrImgResHz=S8Src->ResH;
	TrImgResVt=S8Src->ResV;
	TrBuffImgSrc=(void*)(S8Src->rlfb);
	TrBuffImgDst=(void*)(S16Dst->rlfb);
	TransfB8ToB16();
}

void ConvSurf8ToSurf16Pal(DgSurf *S16Dst, DgSurf *S8Src,void *PalBGR1024)
{	if (S8Src==NULL || S16Dst==NULL ||
	    S16Dst->BitsPixel!=16 || S8Src->BitsPixel!=8 ||
	    S8Src->ResH!=S16Dst->ResH ||
	    S8Src->ResV!=S16Dst->ResV) return;
	// convert buffers
	TrImgResHz=S8Src->ResH;
	TrImgResVt=S8Src->ResV;
	TrBuffImgSrc=(void*)(S8Src->rlfb);
	TrBuffImgDst=(void*)(S16Dst->rlfb);
	TrBuffImgSrcPal=PalBGR1024;
	TransfB8ToB16Pal();
}

void PrBuildTbColConv(void *PalBGR1024,float PropBonus)
{	int	i,j;
	unsigned char *Pal=PalBGR1024;
	FREE_MMX();
	// 8bpp -> 15bpp
	for (i=0;i<256;i++)
	  Col8To15bpp[i]= ((short)(Pal[i*4])>>3)|
	  	(((short)(Pal[i*4+1])>>3)<<5)|(((short)(Pal[i*4+2])>>3)<<10);
	// 8bpp -> 16bpp
	for (i=0;i<256;i++)
	  Col8To16bpp[i]= ((short)(Pal[i*4])>>3)|(((short)(Pal[i*4+1])>>2)<<5)|(((short)(Pal[i*4+2])>>3)<<11);
	// 8bpp -> 16bpp
	for (i=0;i<256;i++)
	  Col8To32bpp[i]= ((int)(Pal[i*4]))|((int)(Pal[i*4+1])<<8)|
	  	((int)(Pal[i*4+2])<<16);
	// 15bpp -> 8bpp
	for (i=0;i<256*128;i++)
//	  Col15To8bpp[i] = PrFindCol(1,255,((i>>10)&0x1f)<<3,((i>>5)&0x1f)<<3,(i&0x1f)<<3,Pal,PropBonus);
	  Col15To8bpp[i] = PrFindCol(1,255,(i&0x1f)<<3,((i>>5)&0x1f)<<3,((i>>10)&0x1f)<<3,Pal,PropBonus);
}

void BuildTbColConv(void *PalBGR1024)
{	int	i,j;
	unsigned char *Pal=PalBGR1024;
	FREE_MMX();
	// 8bpp -> 15bpp
	for (i=0;i<256;i++)
	  Col8To15bpp[i]= ((short)(Pal[i*4])>>3)|
	  	(((short)(Pal[i*4+1])>>3)<<5)|(((short)(Pal[i*4+2])>>3)<<10);
	// 8bpp -> 16bpp
	for (i=0;i<256;i++)
	  Col8To16bpp[i]= ((short)(Pal[i*4])>>3)|(((short)(Pal[i*4+1])>>2)<<5)|(((short)(Pal[i*4+2])>>3)<<11);
	// 8bpp -> 16bpp
	for (i=0;i<256;i++)
	  Col8To32bpp[i]= ((int)(Pal[i*4]))|((int)(Pal[i*4+1])<<8)|
	  	((int)(Pal[i*4+2])<<16);
	// 15bpp -> 8bpp
	for (i=0;i<256*128;i++)
	  Col15To8bpp[i] = FindCol(0,255,(i&0x1f)<<3,((i>>5)&0x1f)<<3,((i>>10)&0x1f)<<3,Pal);
}

void BuildTbDegCol(void *PalBGR1024)
{	int i,j,c,Black,White,ray,ray2,DB,DG,DR;
	float sb,sg,sr,db,dg,dr,pb,pg,pr;
	unsigned char *Pal=PalBGR1024;
	int ND=64;
	FREE_MMX();

	Black=FindCol(1,255,0,0,0,Pal);
	White=FindCol(1,255,255,255,255,Pal);
	for (i=0;i<256;i++) {
	  TbDegCol[i*ND]=Black;
	  TbDegCol[i*ND+ND-1]=White;
	  TbDegCol[i*ND+(ND/2)-1]=TbDegCol[i*ND+(ND/2)]=i;
	}
	for (i=0;i<256;i++) {
	  sb=Pal[TbDegCol[i*ND+(ND/2)-1]*4];
	  sg=Pal[TbDegCol[i*ND+(ND/2)-1]*4+1];
	  sr=Pal[TbDegCol[i*ND+(ND/2)-1]*4+2];
	  db=Pal[TbDegCol[i*ND]*4];
	  dg=Pal[TbDegCol[i*ND]*4+1];
	  dr=Pal[TbDegCol[i*ND]*4+2];
	  pb=(db-sb)/(float)((ND/2)-1); pg=(dg-sg)/(float)((ND/2)-1); pr=(dr-sr)/(float)((ND/2)-1);
	  for (j=(ND/2)-2;j>0;j--) {
	    sb+=pb; sg+=pg; sr+=pr;
	    TbDegCol[i*ND+j]=FindCol(1,255,sb,sg,sr,Pal);
	  }

	  sb=Pal[TbDegCol[i*ND+((ND/2)-1)]*4];
	  sg=Pal[TbDegCol[i*ND+((ND/2)-1)]*4+1];
	  sr=Pal[TbDegCol[i*ND+((ND/2)-1)]*4+2];
	  db=Pal[TbDegCol[i*ND+(ND-1)]*4];
	  dg=Pal[TbDegCol[i*ND+(ND-1)]*4+1];
	  dr=Pal[TbDegCol[i*ND+(ND-1)]*4+2];
	  pb=(db-sb)/(float)((ND/2)-1); pg=(dg-sg)/(float)((ND/2)-1); pr=(dr-sr)/(float)((ND/2)-1);
	  for (j=(ND/2+1);j<ND-1;j++) {
	    sb+=pb; sg+=pg; sr+=pr;
	    TbDegCol[i*ND+j]=FindCol(1,255,sb,sg,sr,Pal);
	  }
	}
}

void PrBuildTbDegCol(void *PalBGR1024,float PropBonus)
{	int i,j,Black,White;
	float sb,sg,sr,db,dg,dr,pb,pg,pr;
	unsigned char *Pal=PalBGR1024;
	int ND=64;
	FREE_MMX();
	Black=FindCol(1,255,0,0,0,Pal);
	White=FindCol(1,255,255,255,255,Pal);
	for (i=0;i<256;i++) {
	  TbDegCol[i*ND]=Black;
	  TbDegCol[i*ND+ND-1]=White;
	  TbDegCol[i*ND+(ND/2)-1]=TbDegCol[i*ND+(ND/2)]=i;
	}
	for (i=0;i<256;i++) {
	  sb=Pal[TbDegCol[i*ND+(ND/2)-1]*4];
	  sg=Pal[TbDegCol[i*ND+(ND/2)-1]*4+1];
	  sr=Pal[TbDegCol[i*ND+(ND/2)-1]*4+2];
	  db=Pal[TbDegCol[i*ND]*4];
	  dg=Pal[TbDegCol[i*ND]*4+1];
	  dr=Pal[TbDegCol[i*ND]*4+2];
	  pb=(db-sb)/(float)((ND/2)-1); pg=(dg-sg)/(float)((ND/2)-1); pr=(dr-sr)/(float)((ND/2)-1);
	  for (j=(ND/2)-2;j>0;j--) {
	    sb+=pb; sg+=pg; sr+=pr;
	    TbDegCol[i*ND+j]=PrFindCol(1,255,sb,sg,sr,Pal,PropBonus);
	  }

	  sb=Pal[TbDegCol[i*ND+((ND/2)-1)]*4];
	  sg=Pal[TbDegCol[i*ND+((ND/2)-1)]*4+1];
	  sr=Pal[TbDegCol[i*ND+((ND/2)-1)]*4+2];
	  db=Pal[TbDegCol[i*ND+(ND-1)]*4];
	  dg=Pal[TbDegCol[i*ND+(ND-1)]*4+1];
	  dr=Pal[TbDegCol[i*ND+(ND-1)]*4+2];
	  pb=(db-sb)/(float)((ND/2)-1); pg=(dg-sg)/(float)((ND/2)-1); pr=(dr-sr)/(float)((ND/2)-1);
	  for (j=(ND/2+1);j<ND-1;j++) {
	    sb+=pb; sg+=pg; sr+=pr;
	    TbDegCol[i*ND+j]=PrFindCol(1,255,sb,sg,sr,Pal,PropBonus);
	  }
	}
}


int FindCol(int DebCol,int FinCol,int B,int G,int R,void *PalBGR1024)
{	int i,c=DebCol,ray,ray2;
	int bs,gs,rs;
	unsigned char *Pal=PalBGR1024;
	ray=17000000;
	DebCol&=0xff; FinCol&=0xff; B&=0xff; G&=0xff; R&=0xff;
	for (i=DebCol;i<FinCol+1;i++) {
	  bs=B-Pal[i*4]; gs=G-Pal[i*4+1]; rs=R-Pal[i*4+2];
          ray2=bs*bs+gs*gs+rs*rs;
	  if (ray2<ray) { c=i; ray=ray2; }
	  if (ray==0) break;
	}
	return c;
}

int Prop(int B,int G,int R) {
	int ind=0;
	if (B > G)
		ind=0x1;
	else
		ind = (B == G) ? 0x2 : 0x3;
	if (B > R)
		ind |= 0x10;
	else
	    ind |= (B == R) ? 0x20 : 0x30;
	if (G > R)
		ind |= 0x100;
	else
	    ind |= (G == R) ? 0x200 : 0x300;

	return ind;
}

int PrFindCol(int DebCol,int FinCol,int SearchB,int SearchG,int SearchR,
            void *PalBGR1024, float PropBonus)
{	int i = 0,
		PropBGR = 0,
		ray = 0,
		ray2 = 0,
		deltaB = 0,
		deltaG = 0,
		deltaR = 0,
		colB = 0,
		colG = 0,
		colR = 0,
		c = DebCol;
	unsigned char *Pal=PalBGR1024;
	float bonusPow2 = PropBonus * PropBonus;

	ray=17000000; // ~ 255*255*255 highest possible
	DebCol&=0xff; FinCol&=0xff; SearchB&=0xff; SearchG&=0xff; SearchR&=0xff;
	PropBGR=Prop(SearchB,SearchG,SearchR);
	for (i=DebCol;i<=FinCol;i++) {
	    colB=(int)Pal[i*4];
	    colG=(int)Pal[i*4+1];
	    colR=(int)Pal[i*4+2];
	    deltaB=SearchB-colB;
	    deltaG=SearchG-colG;
	    deltaR=SearchR-colR;
		ray2=(deltaB*deltaB)+(deltaG*deltaG)+(deltaR*deltaR);
		if (PropBGR == Prop(colB,colG,colR)) {
			ray2 = (int)((float)(ray2) * bonusPow2);
		}
		if (ray2<ray) {
			c=i;
			ray=ray2;
		}
		if (ray==0) break;
	}
	return c;
}




/*void line(int X1,int Y1,int X2,int Y2,int LgCol)
{	int P[4];
 	P[0]=X1; P[1]=Y1;
 	P[2]=X2; P[3]=Y2;
	Line(&P[0],&P[2],LgCol);
}

void linemap(int X1,int Y1,int X2,int Y2,int LgCol,unsigned int Map)
{	int P[4];
 	P[0]=X1; P[1]=Y1;
 	P[2]=X2; P[3]=Y2;
	LineMap(&P[0],&P[2],LgCol,Map);
}*/

void ClearSurf(int clrcol) {
	bar(CurSurf.MinX,CurSurf.MinY,CurSurf.MaxX,CurSurf.MaxY,clrcol);
}

void Bar(void *Pt1,void *Pt2,int bcol)
{	bar(((int*)(Pt1))[0], ((int*)(Pt1))[1],
		((int*)(Pt2))[0],((int*)(Pt2))[1], bcol);
}

void bar(int x1,int y1,int x2,int y2,int bcol)
{	int CBar[8], ACBar[5];
	if (x1==x2 || y1==y2) {
	  line(x1,y1,x2,y2,bcol); return; }
	CBar[0]= CBar[6]= x2;
	CBar[2]= CBar[4]= x1;
	CBar[5]= CBar[7]= y1;
	CBar[1]= CBar[3]= y2;
 	ACBar[0]=4;
	ACBar[1]=&CBar[0]; ACBar[2]=&CBar[2];
	ACBar[3]=&CBar[4]; ACBar[4]=&CBar[6];
	Poly(&ACBar, NULL, POLY_SOLID|POLY_FLAG_DBL_SIDED, bcol);
}

void rect(int x1,int y1,int x2,int y2,int rcol) {
    line(x1,y1,x2,y1,rcol);
    line(x1,y2,x2,y2,rcol);
    if (y2>y1) {
      line(x1,y1+1,x1,y2-1,rcol);
      line(x2,y1+1,x2,y2-1,rcol);
    }
    else
      if (y2<y1) {
        line(x1,y1-1,x1,y2+1,rcol);
        line(x2,y1-1,x2,y2+1,rcol);
      }
}

void rectmap(int x1,int y1,int x2,int y2,int rcol,unsigned int rmap) {
    linemap(x1,y1,x2,y1,rcol,rmap);
    linemap(x1,y2,x2,y2,rcol,rmap);
    if (y2>y1) {
      linemap(x1,y1+1,x1,y2-1,rcol,rmap);
      linemap(x2,y1+1,x2,y2-1,rcol,rmap);
    }
    else
      if (y2<y1) {
        linemap(x1,y1-1,x1,y2+1,rcol,rmap);
        linemap(x2,y1-1,x2,y2+1,rcol,rmap);
      }
}


int GetPixelSize(int bitsPixel) {
   switch (bitsPixel) {
      case 8:  return 1;
      case 15: return 2;
      case 16: return 2;
      case 24: return 3;
      case 32: return 4;
      default : return 0;
   }

}

void SetOrgSurf(DgSurf *S,int LOrgX,int LOrgY)
{	int dx,dy;
	int pixelsize=GetPixelSize(S->BitsPixel);
	dx=LOrgX-S->OrgX;
	dy=LOrgY-S->OrgY;
	S->MinX-= dx;
	S->MaxX-= dx;
	S->MinY-= dy;
	S->MaxY-= dy;
	S->OrgX= LOrgX;
	S->OrgY= LOrgY;
	if (pixelsize>1)
		S->vlfb= S->rlfb+(S->OrgX*pixelsize)-((S->OrgY-(S->ResV-1))*S->ResH*pixelsize);
	else
		S->vlfb= S->rlfb+S->OrgX-(S->OrgY-(S->ResV-1))*S->ResH;
}

void SetOrgVSurf(int OrgX,int OrgY)
{	int i;
 	for (i=0;i<NbVDgSurf;i++)
	   SetOrgSurf(&VSurf[i],OrgX,OrgY);
}

int  CreateSurf(DgSurf **S, int ResHz, int ResVt, char BitsPixel)
{	int cvlfb;
    int pixelsize=GetPixelSize(BitsPixel);
    if (BitsPixel != 8 && BitsPixel != 16)
		return 0;
	if (pixelsize == 0 || ResHz<1 || ResVt<1)
		return 0;
    *S = (DgSurf*)malloc(sizeof(DgSurf)+ResHz*ResVt*pixelsize);
    if ((*S) == NULL)
        return 0;
	cvlfb=(void*)(&(*S)[1]);
	if (cvlfb!=NULL) {
	  (*S)->vlfb=(*S)->rlfb= cvlfb;
	  (*S)->OffVMem= -1;
	  (*S)->ResH= ResHz;
	  (*S)->ResV= ResVt;

	  (*S)->MaxX= ResHz-1;
	  (*S)->MaxY= (*S)->MinX= 0;
	  (*S)->MinY= -ResVt+1;      //axe Y montant
	  (*S)->SizeSurf= ResHz*ResVt*pixelsize;
	  (*S)->Mask= 0;
	  (*S)->OrgX= 0;
	  (*S)->OrgY= ResVt-1;
      (*S)->BitsPixel= BitsPixel;
	  (*S)->ScanLine= ResHz *pixelsize;
	  (*S)->NegScanLine = -((*S)->ScanLine);
	  SetOrgSurf((*S),0,0);
	  return 1;
	}
	free((*S));
	return 0;
}

void DestroySurf(DgSurf *S) {
    if (S != NULL && S->OffVMem == -1) {
	  S->vlfb=S->rlfb=S->OffVMem=0;
	  free(S);
	}
}

int  CreateSurfBuff(DgSurf **S, int ResHz, int ResVt, char BitsPixel,void *Buff) {
    int pixelsize=GetPixelSize(BitsPixel);

    if (BitsPixel != 8 && BitsPixel != 16)
		return 0;
	if (pixelsize == 0 || ResHz<1 || ResVt<1)
		return 0;
    *S = (DgSurf*)malloc(sizeof(DgSurf));
    if ((*S) == NULL)
        return 0;
    (*S)->vlfb=(*S)->rlfb= Buff;
    (*S)->OffVMem= -1;
    (*S)->ResH= ResHz;
    (*S)->ResV= ResVt;
    (*S)->MaxX= ResHz-1;
    (*S)->MaxY= (*S)->MinX= 0;
    (*S)->MinY= -ResVt+1;      //axe Y montant
    (*S)->SizeSurf= ResHz*ResVt*pixelsize;
    (*S)->Mask= 0;
    (*S)->OrgX= 0;
    (*S)->OrgY= ResVt-1;
    (*S)->BitsPixel= BitsPixel;
    (*S)->ScanLine= ResHz *pixelsize;
    (*S)->NegScanLine = -((*S)->ScanLine);
    SetOrgSurf((*S),0,0);
    return 1;
}

void SetSurfView(DgSurf *S, DgView *V) {
    int pixelsize = GetPixelSize(S->BitsPixel);
    // clip if required
    int RMaxX= ((V->MaxX+V->OrgX)<S->ResH) ? V->MaxX+V->OrgX : S->ResH-1;
    int RMaxY= ((V->MaxY+V->OrgY)<S->ResV) ? V->MaxY+V->OrgY : S->ResV-1;
    int RMinX= ((V->MinX+V->OrgX)>=0) ? V->MinX+V->OrgX : 0;
    int RMinY= ((V->MinY+V->OrgY)>=0) ? V->MinY+V->OrgY : 0;

    S->OrgX= V->OrgX;
    S->OrgY= V->OrgY;
    S->MaxX= RMaxX-S->OrgX;
    S->MinX= RMinX-S->OrgX;
    S->MaxY= RMaxY-S->OrgY;
    S->MinY= RMinY-S->OrgY;
    if (pixelsize > 1)
        S->vlfb= S->rlfb+(S->OrgX*pixelsize)-((S->OrgY-(S->ResV-1))*S->ResH*pixelsize);
    else
        S->vlfb= S->rlfb+S->OrgX-(S->OrgY-(S->ResV-1))*S->ResH;
}

// les coordonnees des limite sont relative a l'origine de l'ecran
void SetSurfInView(DgSurf *S, DgView *V) {
    int pixelsize = GetPixelSize(S->BitsPixel);
    int RMaxX= S->MaxX+S->OrgX;
    int RMaxY= S->MaxY+S->OrgY;
    int RMinX= S->MinX+S->OrgX;
    int RMinY= S->MinY+S->OrgY;

    // clip DgView if required
    if ((V->MaxX+V->OrgX)<RMaxX) {
        RMaxX = V->MaxX+V->OrgX;
    }
    if ((V->MaxY+V->OrgY)<RMaxY) {
        RMaxY= V->MaxY+V->OrgY;
    }
    if ((V->MinX+V->OrgX)>RMinX) {
        RMinX= V->MinX+V->OrgX;
    }
    if ((V->MinY+V->OrgY)>RMinY) {
        RMinY= V->MinY+V->OrgY;
    }
    S->OrgX= V->OrgX;
    S->OrgY= V->OrgY;
    S->MaxX= RMaxX-S->OrgX;
    S->MaxY= RMaxY-S->OrgY;
    S->MinX= RMinX-S->OrgX;
    S->MinY= RMinY-S->OrgY;
    if (pixelsize > 1)
        S->vlfb= S->rlfb+(S->OrgX*pixelsize)-((S->OrgY-(S->ResV-1))*S->ResH*pixelsize);
    else
        S->vlfb= S->rlfb+S->OrgX-(S->OrgY-(S->ResV-1))*S->ResH;
}

void SetSurfViewBounds(DgSurf *S, DgView *V) {
    // clip if required
    int RMaxX= ((V->MaxX+S->OrgX)<S->ResH) ? V->MaxX+S->OrgX : S->ResH-1;
    int RMaxY= ((V->MaxY+S->OrgY)<S->ResV) ? V->MaxY+S->OrgY : S->ResV-1;
    int RMinX= ((V->MinX+S->OrgX)>=0) ? V->MinX+S->OrgX : 0;
    int RMinY= ((V->MinY+S->OrgY)>=0) ? V->MinY+S->OrgY : 0;

    S->MaxX= RMaxX-S->OrgX;
    S->MinX= RMinX-S->OrgX;
    S->MaxY= RMaxY-S->OrgY;
    S->MinY= RMinY-S->OrgY;
}

void SetSurfInViewBounds(DgSurf *S, DgView *V) {
    int RMaxX= S->MaxX+S->OrgX;
    int RMaxY= S->MaxY+S->OrgY;
    int RMinX= S->MinX+S->OrgX;
    int RMinY= S->MinY+S->OrgY;

    // clip View if required
    if ((V->MaxX+S->OrgX)<RMaxX) {
        RMaxX = V->MaxX+S->OrgX;
    }
    if ((V->MaxY+S->OrgY)<RMaxY) {
        RMaxY= V->MaxY+S->OrgY;
    }
    if ((V->MinX+S->OrgX)>RMinX) {
        RMinX= V->MinX+S->OrgX;
    }
    if ((V->MinY+S->OrgY)>RMinY) {
        RMinY= V->MinY+S->OrgY;
    }
    S->MaxX= RMaxX-S->OrgX;
    S->MaxY= RMaxY-S->OrgY;
    S->MinX= RMinX-S->OrgX;
    S->MinY= RMinY-S->OrgY;
}


void GetSurfView(DgSurf *S, DgView *V)
{	V->OrgX=S->OrgX;  V->OrgY=S->OrgY;
	V->MaxX=S->MaxX;  V->MaxY=S->MaxY;
	V->MinX=S->MinX;  V->MinY=S->MinY;
}

void RealViewSurf(int NbSurf) {
	__dpmi_regs r;
	if (NbSurf>=NbVDgSurf) return;
	CurViewVSurf=NbSurf;
   	bzero(&r,sizeof(__dpmi_regs));
	r.d.eax = 0x4f07;
	r.h.bl = 0;
	r.h.bh = 0;
	r.d.ecx = 0; // x = 0
        r.d.edx = VSurf[0].ResV*NbSurf; // y


   	_go32_dpmi_simulate_int(0x10, &r);
}

void RealViewSurfSched(int NbSurf) {
	__dpmi_regs r;
	if (NbSurf>=NbVDgSurf) return;
	CurViewVSurf=NbSurf;
	addr= VSurf[NbSurf].OffVMem;

	asm (" push  %ebx \n"
	     "  mov   $0x4f07,%eax \n"
	     "  mov   _addr,%ecx   \n"
	     "  mov   $0x2,%ebx	   \n"
	     "  int   $0x10	  \n"
	     "  pop   %ebx         \n");
}


void RealViewSurfWaitVR(int NbSurf) {
	__dpmi_regs r;
	if (NbSurf>=NbVDgSurf) return;
	CurViewVSurf=NbSurf;
   	bzero(&r,sizeof(__dpmi_regs));
	r.d.eax = 0x4f07;
	r.h.bl = 0x80;
	r.h.bh = 0;
	r.d.ecx = 0; // x = 0
        r.d.edx = VSurf[0].ResV*NbSurf; // y

   	_go32_dpmi_simulate_int(0x10, &r);
}

void RealSetPalette(int Dbcol, int Nbcol, void *Tcol) {
	__dpmi_regs r;
	int i,j;
	Dbcol&=0xff;
//        if (CurMode.VModeFlag|VMODE_VGA) ShiftPal=1;
	if (Nbcol<1 || Nbcol>256) return;
	if (ShiftPal) {
		for (i=Dbcol;i<Dbcol+Nbcol;i++) {
			j=i-Dbcol;
			CurPalette[i*4]=(((unsigned char*)(Tcol))[j*4])>>2; // B
			CurPalette[i*4+1]=(((unsigned char*)(Tcol))[j*4+1])>>2; // G
			CurPalette[i*4+2]=(((unsigned char*)(Tcol))[j*4+2])>>2; // R
		}
	} else memcpy(&CurPalette[Dbcol*4],Tcol,Nbcol*4);

//        if (CurMode.VModeFlag|VMODE_VGA)
//        {
			outb(0x3c8,Dbcol);
			for (i=Dbcol;i<Dbcol+Nbcol;i++) {
				outb(0x3c9,CurPalette[i*4+2]);
				outb(0x3c9,CurPalette[i*4+1]);
				outb(0x3c9,CurPalette[i*4]);
			}
//        }
//        else {
			dosmemput(&CurPalette[Dbcol*4], 4*Nbcol, __tb);
			bzero(&r,sizeof(__dpmi_regs));
			r.d.eax = 0x4f09;
			r.d.ebx = 0;
			r.d.ecx = Nbcol;
			r.d.edx = Dbcol;
			r.x.es = (__tb>>4) & 0xffff;
			r.d.edi = __tb & 0xf;
			_go32_dpmi_simulate_int(0x10, &r);
//        }
}

// standard VESA Mode
#define SIZE_STD_VBE8BPP  5
#define SIZE_STD_VBE16BPP 5
int std8bppVESAMode[SIZE_STD_VBE8BPP]=
//640x400-640x480-800x600-1024x768-1280x1024
  { 0x100,0x101,0x103,0x105,0x107 }; // 8bpp
int std16bppVESAMode[SIZE_STD_VBE16BPP]=
//320x200-640x480-800x600-1024x768-1280x1024
  { 0x10E,0x111,0x114,0x117,0x11A }; // 16bpp

int DgInit() {
	VesaInfo VesaInf;
	__dpmi_regs r;
	unsigned int i,j,CptMode,curMode,LimitDS,BaseDS,TbMemCopy=1000,TbModeCopy=512;
	char Error=0;
	short *ListMode;

	if (!DetectMMX()) return 0;

	bzero(&r,sizeof(__dpmi_regs));
   	r.d.eax = 0x4f00;
	r.x.es = (__tb>>4)  & 0xffff;
	r.d.edi = __tb & 0xf;
   	__dpmi_int(0x10, &r);
	if (r.h.al!=0x4f) return 0;
	dosmemget(__tb,sizeof(VesaIntro),&VesaInt);
	if ((ListMode=(short *)malloc(1024*sizeof(short)))==NULL) return 0;

	if ((VesaInt.VideoPtr&0xFFFF)>(0xffff-1024)) {
	  TbMemCopy=0xffff-(VesaInt.VideoPtr&0xFFFF);
	  TbModeCopy=TbMemCopy/2; }
	dosmemget(((VesaInt.VideoPtr&0xffff0000)>>12)+
	             (VesaInt.VideoPtr&0xFFFF), TbMemCopy,ListMode);
	if ((VesaInt.Sign!='ASEV') || (VesaInt.HiVers<2)) return 0;
	VesaHiVers=VesaInt.HiVers;
	VesaLoVers=VesaInt.LoVers;

	bzero(&r,sizeof(__dpmi_regs));
	r.d.eax = 0x4f01;
	r.d.ecx = 0x101;
	r.x.es = (__tb>>4) & 0xffff;
	r.d.edi = __tb & 0xf;
   	__dpmi_int(0x10, &r);
	if (r.h.al!=0x4f)  return 0;
	dosmemget(__tb,sizeof(VesaInfo),&VesaInf);

   	dpinf.address=VesaInf.PhysBasePtr; // map LFB
   	dpinf.size=VesaInt.Memory*64*1024;

   	if (__dpmi_physical_address_mapping(&dpinf))  Error=1;
	if (__dpmi_get_segment_base_address(_my_ds(),&BaseDS)==-1) Error=1;
	LimitDS=dpinf.address+dpinf.size-1-BaseDS;
	if (__dpmi_set_segment_limit(_my_ds(),LimitDS)==-1) Error=1;
	if (!__djgpp_nearptr_enable())
	  _crt0_startup_flags |=_CRT0_FLAG_NEARPTR;
	lfb=dpinf.address-BaseDS;
	SizeVMem=Sizelfb=dpinf.size;

	if (Error) { free(ListMode); return 0; }
	i=0; while (ListMode[i]!=-1 && i<TbModeCopy) i++;
	NbDgfxModes=i;
	// add standard 8bpp VESA mode if they does not exist
	CptMode=0;
	for (j=0;j<SIZE_STD_VBE8BPP;j++) {
	  curMode=std8bppVESAMode[j];
	  for (i=0;i<NbDgfxModes;i++) {
	    if (ListMode[i]==curMode) { CptMode = curMode; }
	  }
	  if (CptMode!=curMode) {
	    ListMode[NbDgfxModes]=curMode; NbDgfxModes++; }
	}
	// add standard 16bpp VESA mode if they does not exist
	CptMode=0;
	for (j=0;j<SIZE_STD_VBE16BPP;j++) {
	  curMode=std16bppVESAMode[j];
	  for (i=0;i<NbDgfxModes;i++) {
	    if (ListMode[i]==curMode) { CptMode = curMode; }
	  }
	  if (CptMode!=curMode) {
	    ListMode[NbDgfxModes]=curMode; NbDgfxModes++; }
	}

	if ((TbDgfxModes=(ModeInfo *)malloc(sizeof(ModeInfo)*(NbDgfxModes+2)))==NULL)
	  return 0;

	for (CptMode=i=0;i<NbDgfxModes;i++)
	   { bzero(&r,sizeof(__dpmi_regs));
	     r.x.ax = 0x4f01;
	     r.x.cx = ListMode[i];
	     r.x.es = (__tb>>4) & 0xffff;
	     r.d.edi = __tb & 0xf;
     	     __dpmi_int(0x10, &r);
	     dosmemget(__tb,sizeof(VesaInfo),&VesaInf);

	     if ( (VesaInf.ModeFlag& FLAG_SUPP)    &&
	          (VesaInf.ModeFlag& FLAG_COLOR)   &&
	          (VesaInf.ModeFlag& FLAG_GRAPH)   &&
	          (VesaInf.ModeFlag& FLAG_LFB)     &&
	          ((VesaInf.BitPixel==8) ||       // 8 Bpp or 16bpp
		   (VesaInf.BitPixel==16 && VesaInf.RedMaxSize==5 &&
 		    VesaInf.GreenMaxSize==6 && VesaInf.BlueMaxSize==5)) ) {
			TbDgfxModes[CptMode].Mode=ListMode[i];
	        TbDgfxModes[CptMode].ResHz=VesaInf.ResX;
	        TbDgfxModes[CptMode].ResVt=VesaInf.ResY;
	        TbDgfxModes[CptMode].VModeFlag=VesaInf.ModeFlag;
		    TbDgfxModes[CptMode].VModeFlag^=VMODE_VGA; // reverse VGA compatible bit
	        TbDgfxModes[CptMode].BitPixel=VesaInf.BitPixel;
	        TbDgfxModes[CptMode].rlfb=VesaInf.PhysBasePtr;
	        TbDgfxModes[CptMode].VtFreq = 60;
	        CptMode++;
	     }
	}
	// final count of valid gfx modes
	NbDgfxModes=CptMode;
	free(ListMode);

	InitVesaPMI();
//	if (VesaPMIOk) {
//	  SetPalette=ProtectSetPalette;
//	  ViewSurf=ProtectViewSurf;
//	  ViewSurfWaitVR=ProtectViewSurfWaitVR;
//	} else {
	  SetPalette=RealSetPalette;
	  ViewSurf=RealViewSurf;
	  ViewSurfWaitVR=RealViewSurfWaitVR;
//	}
	//if (VesaHiVers>=3) ViewSurf=RealViewSurfSched;
	EnableVesaMTRR();
	return 1;
}

int InitVesaMode(int ResHz, int ResVt, char BitPixel, int NbPage)
{
	__dpmi_regs r;
	int i,j,ScreenSize;
	int pixelsize;
 	unsigned int cvlfb;

 	for (i=0;i<NbDgfxModes;i++) {

		if ( TbDgfxModes[i].ResHz==ResHz &&   TbDgfxModes[i].ResVt==ResVt && TbDgfxModes[i].BitPixel==BitPixel)  {
			pixelsize=GetPixelSize(BitPixel);
			ScreenSize = ResHz*ResVt*pixelsize;
			if ((ScreenSize*NbPage)>Sizelfb)
				return 0;

			if (Video==1 && VSurf!=NULL) { free(VSurf); VSurf=NULL; }
			VSurf=(DgSurf *)malloc(sizeof(DgSurf)*(NbPage+1));
			if (VSurf==NULL)
				return 0;

			Video==1; cvlfb=lfb;
			for (j=0;j<NbPage;j++) {
				VSurf[j].vlfb=VSurf[j].rlfb= cvlfb;
				VSurf[j].OffVMem= cvlfb-lfb;
				VSurf[j].ResH= ResHz;
				VSurf[j].ResV= ResVt;

				VSurf[j].MaxX= ResHz-1;
				VSurf[j].MaxY= VSurf[j].MinX= 0;
				VSurf[j].MinY= -ResVt+1; //axe Y montant
				VSurf[j].SizeSurf= ScreenSize;
				VSurf[j].OrgX= 0;
				VSurf[j].OrgY= ResVt-1;
				VSurf[j].BitsPixel=BitPixel;
				VSurf[j].ScanLine=ResHz*pixelsize;
  			    VSurf[j].NegScanLine = -VSurf[j].ScanLine;


				SetOrgSurf(&VSurf[j],0,0);
				cvlfb+= ScreenSize;
			}
			VSurf[j].vlfb= cvlfb;
			VSurf[j].ResH= lfb+Sizelfb-cvlfb;
			VSurf[j].ResV= 1;
			NbVDgSurf= NbPage;
			DgSetCurSurf(&VSurf[0]);
			CurDgfxMode=&TbDgfxModes[i];
			CurModeVtFreq=TbDgfxModes[i].VtFreq;
			dgfxMode=CurDgfxMode->Mode|VesaLFB;
			bzero(&r,sizeof(__dpmi_regs));
			r.x.ax = 0x4f02;
			r.x.bx = dgfxMode;
			__dpmi_int(0x10, &r);
			if ((r.x.ax&0x4f)!=0x4f) return 0;

			// Get DAC Palette format
			if (BitPixel==8) GetPaletteDAC();
			return 1;
		}
	}
	return 0;
}

int dgCurDisplayMode = -1;

int DgGetFirstDisplayMode(int *width, int *height, int *bpp, int *refreshRate) {
    if (TbDgfxModes != NULL && NbDgfxModes > 0) {
			*width = TbDgfxModes[0].ResHz;
			*height = TbDgfxModes[0].ResVt;
			*bpp = TbDgfxModes[0].BitPixel;
			*refreshRate = TbDgfxModes[0].VtFreq;
			dgCurDisplayMode = 1;
			return NbDgfxModes;
    }

    dgCurDisplayMode = -1;
    return 0;
}

bool DgGetNextDisplayMode(int *width, int *height, int *bpp, int *refreshRate) {
    if (TbDgfxModes != NULL && NbDgfxModes > 0 && dgCurDisplayMode != -1 && dgCurDisplayMode < NbDgfxModes) {
			*width = TbDgfxModes[dgCurDisplayMode].ResHz;
			*height = TbDgfxModes[dgCurDisplayMode].ResVt;
			*bpp = TbDgfxModes[dgCurDisplayMode].BitPixel;
			*refreshRate = TbDgfxModes[dgCurDisplayMode].VtFreq;
			dgCurDisplayMode++;
			return true;
    }

    dgCurDisplayMode = -1;
    return false;
}

void InitVesaPMI() {
// initialise VESA PMI
	__dpmi_regs r;
	__dpmi_meminfo memMPIO;
	unsigned short *PortMem;
	int *adressMPIO;
	unsigned short *sizeMPIO;
	unsigned short *markerMPIO;
	int i;
	bzero(&r,sizeof(__dpmi_regs));
	r.x.ax = 0x4f0a;
	r.h.bl = 0x0;
	_go32_dpmi_simulate_int(0x10, &r);
	EnableMPIO=0;
	VesaPMIOk=0;
	if (r.h.ah==0) {	  // VESA PMI failed ?
        if ((VesaPMI=malloc(r.x.cx))==NULL) return;
           _go32_dpmi_lock_data( VesaPMI, r.x.cx);
		dosmemget(((unsigned int)(r.x.es)<<4)+(unsigned int)(r.x.di),
		  (unsigned int)(r.x.cx), VesaPMI);
	    WindowControlPMI=VesaPMI+((unsigned short*)(VesaPMI))[0];
	    ViewAddressPMI=VesaPMI+((unsigned short*)(VesaPMI))[1];
	    SizeVesaPMI=r.x.cx;
	    SetPalPMI=VesaPMI+((unsigned short*)(VesaPMI))[2];
	    // scan for io ports
	    PortMem=VesaPMI+((unsigned short*)(VesaPMI))[3];

	    // jump over io ports
	    for (i=0;;i++) {
			if (PortMem[i]==0xffff) {
			break;
			}
	    }
		if (PortMem[i+1]!=0xffff) {
			adressMPIO=(int*)&PortMem[i+1];
			sizeMPIO=&PortMem[i+3];
			markerMPIO=&PortMem[i+4];
			SizeMPIO=(*sizeMPIO)*2;
			AddMPIO=*adressMPIO;
			// map the MPIO
			memMPIO.address=AddMPIO;
			memMPIO.size=SizeMPIO;
			// mapped
			if (__dpmi_physical_address_mapping(&memMPIO)==0) {
				MAPAddMPIO=memMPIO.address;
				__dpmi_lock_linear_region(&memMPIO);
				// create a selector
				SelMPIO = __dpmi_allocate_ldt_descriptors(1);
				if (SelMPIO!=-1) {
					__dpmi_set_segment_base_address(SelMPIO, MAPAddMPIO);
					__dpmi_set_segment_limit(SelMPIO, 0xffff);
					EnableMPIO=1;
				}
				else
				__dpmi_free_physical_address_mapping(&memMPIO);

			}
	   }
	   else {
	     EnableMPIO=0;
	   }
		VesaPMIOk=1;
	}
}

int EnableVesaMTRR() {
    if (DetectCPUID())
	  if (!(_my_cs()&3)) {
	    return (MTRRa=EnableMTRR()); }
	return 0;
}

/*int EnableMTRR() {
	asm ("	push	%ebx\n"
             "  mov	$1,%eax\n"
             "  cpuid\n"
             "  xor	%cl,%cl\n"
             "   test	$0x20,%edx\n"
             "  jz	fin\n"
             "  mov	$1,%eax\n"
             "	cpuid\n"
             "	xor	%cl,%cl\n"
             "	test	$0x1000,%edx\n"
             "	jz	fin\n"
             "	mov	$0xfe,%ecx\n"
             "	rdmsr\n"
             "	test    $400,%eax\n"
             "	jz	fin\n"
             "	mov	$0x2ff,%ecx\n"
             "	rdmsr\n"
             "	cli\n"
             "	wbinvd\n"
             "	mov	%al,_OldCachMode\n"
             "	mov	$1,%al\n"
             "	wrmsr\n"
             "	sti\n"
             "	mov	$1,%cl  \n");
fin:
	asm("	movzx	%cl,%eax\n"
	    "	pop	%ebx		");
}*/

void DgQuit() {
   __dpmi_meminfo memMPIO;
   if (MTRRa) {
     MTRRa=0;
     asm ("	cli \n"
	  "	wbinvd \n"
	  " 	movl	$0x2ff,%ecx \n"
	  "	rdmsr  \n"
	  "	mov	_OldCachMode,%al \n"
	  "	wrmsr \n"
	  "	sti				\n");
   }
   if (TbDgfxModes!=NULL) {
	 free(TbDgfxModes);
	 TbDgfxModes = NULL;
   }
   CurDgfxMode = NULL;
   if (VesaPMIOk) {
     free(VesaPMI); VesaPMIOk=0;
     if (EnableMPIO) {
	EnableMPIO=0;
	memMPIO.address=MAPAddMPIO;
	__dpmi_free_physical_address_mapping(&memMPIO);
	__dpmi_free_ldt_descriptor(SelMPIO);
     }
   }
   if (Video) { free(VSurf); VSurf=NULL; Video=0; }
   __djgpp_nearptr_disable();
   __dpmi_free_physical_address_mapping(&dpinf);
   ShiftPal=0;
   TextMode();
}

int DetectMMX() {
   unsigned int reax,rebx,recx,redx;
   unsigned int MaxVEAX,stackA;
   if (DetectCPUID()) {
     ExecCPUID(0,&MaxVEAX,&rebx,&recx,&redx);
     if (MaxVEAX>0) {
       ExecCPUID(1,&reax,&rebx,&recx,&redx);
       if (redx&0x800000) return 1;   // check if bit 23 of edx
     }
     ExecCPUID(0x80000000,&MaxVEAX,&rebx,&recx,&redx); // check extended cpuid
     if (MaxVEAX>0x80000000) {
       ExecCPUID(0x80000001,&reax,&rebx,&recx,&redx);
       if (redx&0x800000) return 1;   // check if bit 23 of edx
     }
   }
   return 0;
}

void TextMode()
{	if (Video) { free(VSurf); VSurf=CurModeVtFreq=Video=0; }
	asm ("	mov	$0x3,%eax \n"
	     "	int	$0x10	");
}

void GetPaletteDAC()
{	__dpmi_regs r;
	if (VesaInt.Capabilities & 1) {  // D0 ( DAC switch)
	  bzero(&r,sizeof(__dpmi_regs));
   	  r.x.ax = 0x4f08;
	  r.h.bl = 0;	// Set Palette format
	  r.h.bh = 8;	// to 8 Bit
   	  _go32_dpmi_simulate_int(0x10, &r);
	  ShiftPal=(r.h.bh==8)?0:1;
	} else ShiftPal=1;
}

void putpixel(int X,int Y,int pcol) { // utilise PutPixel
	int P[2];
	P[0]=X; P[1]=Y;
	PutPixel(&P,pcol);
}

void cputpixel(int X,int Y,int pcol) { // avec clip
	int P[2];
	if (X>CurSurf.MaxX || X<CurSurf.MinX || Y>CurSurf.MaxY || Y<CurSurf.MinY) return;
	P[0]=X; P[1]=Y;
	PutPixel(&P,pcol);
}

int getpixel(int X,int Y) { // utilise GetPixel
	int P[2];
	P[0]=X; P[1]=Y;
	return GetPixel(&P);
}

int cgetpixel(int X,int Y) { // avec clip
	int P[2];
	if (X>CurSurf.MaxX || X<CurSurf.MinX || Y>CurSurf.MaxY || Y<CurSurf.MinY) return 0;
	P[0]=X; P[1]=Y;
	return GetPixel(&P);
}

// -----------------------
// 16 bpp helper function
// -----------------------

/*void line16(int X1,int Y1,int X2,int Y2,int LgCol) {
	int P[4];
	P[0]=X1; P[1]=Y1;
	P[2]=X2; P[3]=Y2;
	Line16(&P[0],&P[2],LgCol);
}

void linemap16(int X1,int Y1,int X2,int Y2,int LgCol,unsigned int Map) {
	int P[4];
	P[0]=X1; P[1]=Y1;
	P[2]=X2; P[3]=Y2;
	LineMap16(&P[0],&P[2],LgCol,Map);
}

void lineblnd16(int X1,int Y1,int X2,int Y2,int LgCol) {
	int P[4];
 	P[0]=X1; P[1]=Y1;
 	P[2]=X2; P[3]=Y2;
	LineBlnd16(&P[0],&P[2],LgCol);
}

void linemapblnd16(int X1,int Y1,int X2,int Y2,int LgCol,unsigned int Map) {
	int P[4];
 	P[0]=X1; P[1]=Y1;
 	P[2]=X2; P[3]=Y2;
	LineMapBlnd16(&P[0],&P[2],LgCol,Map);
}*/

void cputpixelblnd16(int X,int Y,int pcol) {
	int Pt[2];
	Pt[0]=X; Pt[0]=Y;
	LineBlnd16(Pt,Pt,pcol);
}

void CPutPixelBlnd16(void *Pt1,int pcol) {
	LineBlnd16(Pt1,Pt1,pcol);
}


void ClearSurf16(int clrcol) {
	bar16(CurSurf.MinX,CurSurf.MinY,CurSurf.MaxX,CurSurf.MaxY,clrcol);
}

void Bar16(void *Pt1,void *Pt2,int bcol)
{	bar16(((int*)(Pt1))[0], ((int*)(Pt1))[1],
		((int*)(Pt2))[0],((int*)(Pt2))[1], bcol);
}

void bar16(int x1,int y1,int x2,int y2,int bcol)
{	int CBar[8], ACBar[5];
	if (x1==x2 || y1==y2) {
	  line16(x1,y1,x2,y2,bcol); return; }
	CBar[0]= CBar[6]= x2;
	CBar[2]= CBar[4]= x1;
	CBar[5]= CBar[7]= y1;
	CBar[1]= CBar[3]= y2;
 	ACBar[0]=4;
	ACBar[1]=&CBar[0]; ACBar[2]=&CBar[2];
	ACBar[3]=&CBar[4]; ACBar[4]=&CBar[6];
	Poly16(&ACBar, NULL, POLY16_SOLID|POLY16_FLAG_DBL_SIDED, bcol);
}

void BarBlnd16(void *Pt1,void *Pt2,int bcol) {
	barblnd16(((int*)(Pt1))[0], ((int*)(Pt1))[1],
		((int*)(Pt2))[0],((int*)(Pt2))[1], bcol);
}
void barblnd16(int x1,int y1,int x2,int y2,int bcol) {
	int CBar[8], ACBar[5];
	if (x1==x2 || y1==y2) {
	  lineblnd16(x1,y1,x2,y2,bcol); return; }
	CBar[0]= CBar[6]= x2;
	CBar[2]= CBar[4]= x1;
	CBar[5]= CBar[7]= y1;
	CBar[1]= CBar[3]= y2;
 	ACBar[0]=4;
	ACBar[1]=&CBar[0]; ACBar[2]=&CBar[2];
	ACBar[3]=&CBar[4]; ACBar[4]=&CBar[6];
	Poly16(&ACBar, NULL, POLY16_SOLID_BLND|POLY16_FLAG_DBL_SIDED, bcol);
}

void rect16(int x1,int y1,int x2,int y2,int rcol) {
    line16(x1,y1,x2,y1,rcol);
    line16(x1,y2,x2,y2,rcol);
    if (y2>y1) {
      line16(x1,y1+1,x1,y2-1,rcol);
      line16(x2,y1+1,x2,y2-1,rcol);
    }
    else
      if (y2<y1) {
        line16(x1,y1-1,x1,y2+1,rcol);
        line16(x2,y1-1,x2,y2+1,rcol);
      }
}

void rectmap16(int x1,int y1,int x2,int y2,int rcol,unsigned int rmap) {
    linemap16(x1,y1,x2,y1,rcol,rmap);
    linemap16(x1,y2,x2,y2,rcol,rmap);
    if (y2>y1) {
      linemap16(x1,y1+1,x1,y2-1,rcol,rmap);
      linemap16(x2,y1+1,x2,y2-1,rcol,rmap);
    }
    else
      if (y2<y1) {
        linemap16(x1,y1-1,x1,y2+1,rcol,rmap);
        linemap16(x2,y1-1,x2,y2+1,rcol,rmap);
      }
}

void rectblnd16(int x1,int y1,int x2,int y2,int rcol) {
    lineblnd16(x1,y1,x2,y1,rcol);
    lineblnd16(x1,y2,x2,y2,rcol);
    if (y2>y1) {
      lineblnd16(x1,y1+1,x1,y2-1,rcol);
      lineblnd16(x2,y1+1,x2,y2-1,rcol);
    }
    else
      if (y2<y1) {
        lineblnd16(x1,y1-1,x1,y2+1,rcol);
        lineblnd16(x2,y1-1,x2,y2+1,rcol);
      }
}

void rectmapblnd16(int x1,int y1,int x2,int y2,int rcol,unsigned int rmap) {
    linemapblnd16(x1,y1,x2,y1,rcol,rmap);
    linemapblnd16(x1,y2,x2,y2,rcol,rmap);
    if (y2>y1) {
      linemapblnd16(x1,y1+1,x1,y2-1,rcol,rmap);
      linemapblnd16(x2,y1+1,x2,y2-1,rcol,rmap);
    }
    else
      if (y2<y1) {
        linemapblnd16(x1,y1-1,x1,y2+1,rcol,rmap);
        linemapblnd16(x2,y1-1,x2,y2+1,rcol,rmap);
      }
}


void putpixel16(int X,int Y,int pcol) { // utilise PutPixel
	int P[2];
	P[0]=X; P[1]=Y;
	PutPixel16(&P,pcol);
}

void cputpixel16(int X,int Y,int pcol) { // avec clip
	int P[2];
	if (X>CurSurf.MaxX || X<CurSurf.MinX || Y>CurSurf.MaxY || Y<CurSurf.MinY) return;
	P[0]=X; P[1]=Y;
	PutPixel16(&P,pcol);
}

int getpixel16(int X,int Y) { // utilise GetPixel
	int P[2];
	P[0]=X; P[1]=Y;
	return GetPixel16(&P);
}

int cgetpixel16(int X,int Y) { // avec clip
	int P[2];
	if (X>CurSurf.MaxX || X<CurSurf.MinX || Y>CurSurf.MaxY || Y<CurSurf.MinY) return 0;
	P[0]=X; P[1]=Y;
	return GetPixel16(&P);
}

//*********************** IMAGE
int  LoadMemPCX(DgSurf **S,void *In,void *PalBGR1024,int SizeIn)
{	HeadPCX hpcx;
	char PalRGB[768];
	int ResHz,ResVt,i;

    memcpy(&hpcx,In,sizeof(HeadPCX));
	if (hpcx.Sign!=0xa || hpcx.Ver<5 || hpcx.BitPixel!=8) return 0;
	ResHz=hpcx.X2-hpcx.X1+1;
	ResVt=hpcx.Y2-hpcx.Y1+1;
	memcpy(&PalRGB,&((char*)(In))[SizeIn-768],768);
	for (i=0;i<256;i++) {
	   ((char*)(PalBGR1024))[i*4]=PalRGB[i*3+2];
	   ((char*)(PalBGR1024))[i*4+1]=PalRGB[i*3+1];
	   ((char*)(PalBGR1024))[i*4+2]=PalRGB[i*3];
	  }
	if (!CreateSurf(S,ResHz,ResVt,8))
        return 0;
	if (hpcx.Comp==1)
	   InRLE(In+sizeof(HeadPCX),(*S)->rlfb,(*S)->SizeSurf);
	else
        return 0;
	return 1;
}

int  LoadPCX(DgSurf **S,const char *Fname,void *PalBGR1024)
{	FILE *InPCX;
	HeadPCX hpcx;
	void *BuffIn = NULL;
	char PalRGB[768];
	int FinIn,ResHz,ResVt,i;

	if ((InPCX=fopen(Fname,"rb"))==NULL) return 0;
	fread(&hpcx,sizeof(HeadPCX),1,InPCX);
	if (hpcx.Sign!=0xa || hpcx.Ver<5 || hpcx.BitPixel!=8)
	  { fclose(InPCX); return 0; }
	ResHz=hpcx.X2-hpcx.X1+1;
	ResVt=hpcx.Y2-hpcx.Y1+1;
	fseek(InPCX,-769,SEEK_END);
	fseek(InPCX,1,SEEK_CUR);
	fread(&PalRGB,768,1,InPCX);
	for (i=0;i<256;i++) {
	   ((char*)(PalBGR1024))[i*4]=PalRGB[i*3+2];
	   ((char*)(PalBGR1024))[i*4+1]=PalRGB[i*3+1];
	   ((char*)(PalBGR1024))[i*4+2]=PalRGB[i*3];
	}
	FinIn=ftell(InPCX);
	if (!CreateSurf(S,ResHz,ResVt,8)) {
        fclose(InPCX); return 0;
	}
  	fseek(InPCX,sizeof(HeadPCX),SEEK_SET);
	if (hpcx.Comp==1) {
		BuffIn=malloc(FinIn-sizeof(HeadPCX)+1);
		if (BuffIn==NULL) {
			DestroySurf(*S);
			fclose(InPCX);
			return 0;
		}
		fread(BuffIn,FinIn-sizeof(HeadPCX)+1,1,InPCX);
		InRLE(BuffIn,(*S)->rlfb,ResHz*ResVt);
	 }
	 else {
	   fclose(InPCX);
	   return 0;
	 }
   	free(BuffIn);
	fclose(InPCX);
	return 1;
}

int  SavePCX(DgSurf *S,const char *Fname,void *PalBGR1024)
{	FILE *OutPCX;
	HeadPCX hpcx;
	void *BuffOut;
	char PalRGB[768];
	int FinIn,ResHz,ResVt,i;

	for (i=0;i<256;i++) {
	   PalRGB[i*3]=(((char*)(PalBGR1024))[i*4+2]);
	   PalRGB[i*3+1]=(((char*)(PalBGR1024))[i*4+1]);
	   PalRGB[i*3+2]=(((char*)(PalBGR1024))[i*4]);
	}
	hpcx.Sign=0xa; hpcx.Ver=5; hpcx.BitPixel=8;
	hpcx.X1=hpcx.Y1=0;
	hpcx.X2=S->ResH-1;	hpcx.Y2=S->ResV-1;
	hpcx.ResHzDPI=S->ResH; 	hpcx.ResVtDPI=S->ResV;
	hpcx.ResHz=S->ResH;	hpcx.ResVt=S->ResV;
	hpcx.TypePal=1;
	hpcx.NbPlan=1;
	hpcx.OctLgImg=S->ResH;
	hpcx.resv=0;
	for (i=0;i<54;i++) hpcx.resv2[i]=0;
	memcpy(&hpcx.Pal,&PalRGB,48);

	i=SizeOutRLE((void*)(S->rlfb),S->SizeSurf,S->ResH);
	hpcx.Comp=1;
	BuffOut=(void*) malloc(i);
	if (BuffOut==NULL) return 0;
	OutPCX=fopen(Fname,"wb");
	if (OutPCX==NULL) return 0;
	fwrite(&hpcx,sizeof(HeadPCX),1,OutPCX);
	OutRLE(BuffOut,(void*)(S->rlfb),S->SizeSurf,S->ResH);
	fwrite(BuffOut,i,1,OutPCX);
	i=0xc;
	fwrite(&i,1,1,OutPCX);
	fwrite(PalRGB,768,1,OutPCX);
	free(BuffOut); fclose(OutPCX);
	return 1;
}

int  SaveMemPCX(DgSurf *S,void *Out,void *PalBGR1024)
{	HeadPCX hpcx;
	char PalRGB[768];
	int PtrOut,ResHz,ResVt,i;

	for (i=0;i<256;i++) {
	   PalRGB[i*3]=(((char*)(PalBGR1024))[i*4+2]);
	   PalRGB[i*3+1]=(((char*)(PalBGR1024))[i*4+1]);
	   PalRGB[i*3+2]=(((char*)(PalBGR1024))[i*4]);
	  }
	hpcx.Sign=0xa; hpcx.Ver=5; hpcx.BitPixel=8;
	hpcx.X1=hpcx.Y1=0;
	hpcx.X2=S->ResH-1;	hpcx.Y2=S->ResV-1;
	hpcx.ResHzDPI=S->ResH;	hpcx.ResVtDPI=S->ResV;
	hpcx.ResHz=S->ResH;	hpcx.ResVt=S->ResV;
	hpcx.TypePal=1;
	hpcx.NbPlan=1;
	hpcx.OctLgImg=S->ResH;
	hpcx.resv=0;
	for (i=0;i<54;i++) hpcx.resv2[i]=0;
	memcpy(&hpcx.Pal,&PalRGB,48);
	i=SizeOutRLE((void*)(S->rlfb),S->SizeSurf,S->ResH);
	hpcx.Comp=1;
	memcpy(Out,&hpcx,(PtrOut=sizeof(HeadPCX)));
	OutRLE(Out+PtrOut,(void*)(S->rlfb),S->SizeSurf,S->ResH);
	PtrOut+=i;
	((char*)(Out+PtrOut))[i]=0xc;
	PtrOut++;
	memcpy(Out+PtrOut,&PalRGB,768);
	return 1;
}

int  SizeSavePCX(DgSurf *S)
{	return (SizeOutRLE((void*)(S->rlfb),S->SizeSurf,S->ResH)+128+769);
}

// GIF

int  LoadMemGIF(DgSurf **S,void *In,void *PalBGR1024,int SizeIn)
{	HeadGIF hgif;
	ExtBlock ExtBGif;
	DescImgGIF descimg;
	void *BuffIn,*BuffS,*BuffD,*BuffLZW;
	char PalRGB[768];
	unsigned char SizeExt,BuffExt[255],SizeBl;
	int OldCurInGIF,CurInGIF,ResHz,ResVt,i,j;

	if (SizeIn<sizeof(HeadGIF)) return 0;
	memcpy(&hgif,In,sizeof(HeadGIF));
	CurInGIF=sizeof(HeadGIF);
	if (hgif.Sign!='8FIG' || (hgif.IndicRes&7)!=7) return 0;
	if ((sizeof(HeadGIF)+768)>SizeIn) return 0;
	if (hgif.IndicRes&128) {
           memcpy(&PalRGB,In+CurInGIF,768);
           CurInGIF+=768;
	}
	for (;;) {
	   memcpy(&ExtBGif,In+CurInGIF,sizeof(ExtBlock));
	   if (ExtBGif.SignExt!='!') break;
	   CurInGIF+=sizeof(ExtBlock);
	   SizeExt=ExtBGif.Size;
	   for (;;) {
              if ((CurInGIF+=SizeExt)>SizeIn) return 0;
              memcpy(&SizeExt,In+CurInGIF,1); CurInGIF++;
	      if (SizeExt==0) break;
	   }
	}
	memcpy(&descimg,In+CurInGIF,sizeof(DescImgGIF));
	CurInGIF+=sizeof(DescImgGIF);
	if (CurInGIF>SizeIn) return 0;
	if (descimg.Sign!=','/* || (descimg.Indicateur&7)!=7*/)
	   return 0;

	if (descimg.Indicateur&128) {
           if (CurInGIF+768>SizeIn) return 0;
           memcpy(&PalRGB,(void*)(In+CurInGIF),768);
           CurInGIF+=768;
          }
	for (i=0;i<256;i++) {
	   ((char*)(PalBGR1024))[i*4]=PalRGB[i*3+2];
	   ((char*)(PalBGR1024))[i*4+1]=PalRGB[i*3+1];
	   ((char*)(PalBGR1024))[i*4+2]=PalRGB[i*3];
	  }
	ResHz=descimg.ResHz; ResVt=descimg.ResVt;
	if (!CreateSurf(S,ResHz,ResVt,8))
        return 0;
	if ((BuffIn=malloc(SizeIn+1-CurInGIF))==NULL) return 0;
// Preparation du buffer
	SizeBl=((unsigned char*)(In+CurInGIF+1))[0];
	memcpy(BuffIn,In+CurInGIF,SizeBl+2);
	BuffD=BuffIn+SizeBl+2;
	BuffS=In+CurInGIF+SizeBl+2;
	for (;;) {
	   SizeBl=((unsigned char*)(BuffS))[0];
	   if (SizeBl==0) break;
	   BuffS++;
	   memcpy(BuffD,BuffS,SizeBl);
	   BuffS+=SizeBl;
	   BuffD+=SizeBl;
	  }
	InLZW(BuffIn+2,(*S)->rlfb);
	free(BuffIn);
	return 1;
}


int  LoadGIF(DgSurf **S,const char *Fname,void *PalBGR1024)
{	FILE *InGIF;
	HeadGIF hgif;
	ExtBlock ExtBGif;
	DescImgGIF descimg;
	void *BuffIn,*BuffS,*BuffD,*BuffLZW;
	char PalRGB[768];
	unsigned char SizeExt,BuffExt[255],SizeBl;
	int FinInGIF,DebInGIF,CurInGIF,ResHz,ResVt,i,j;

	if ((InGIF=fopen(Fname,"rb"))==NULL) {
        printf("no file\n");
        return 0;
	}
	fread(&hgif,sizeof(HeadGIF),1,InGIF);
	if (hgif.Sign!='8FIG' || (hgif.IndicRes&7)!=7)
	  { fclose(InGIF); return 0; }
	if (hgif.IndicRes&128) fread(&PalRGB,768,1,InGIF);
   	CurInGIF=ftell(InGIF);
	for (;;) {
	   CurInGIF=ftell(InGIF);
	   fread(&ExtBGif,sizeof(ExtBlock),1,InGIF);
	   if (ExtBGif.SignExt!='!') break;
	   SizeExt=ExtBGif.Size;
	   for (;;) {
	      fread(&BuffExt,SizeExt,1,InGIF);
	      fread(&SizeExt,1,1,InGIF);
	      if (SizeExt==0) break;
	   }
	}
	fseek(InGIF,CurInGIF,SEEK_SET);
	fread(&descimg,sizeof(DescImgGIF),1,InGIF);
	if (descimg.Sign!=','/* || (descimg.Indicateur&7)!=7*/) {
        printf("no sign\n");
        return 0;
    }
	if (descimg.Indicateur&128) fread(&PalRGB,768,1,InGIF);
	for (i=0;i<256;i++) {
	   ((char*)(PalBGR1024))[i*4]=PalRGB[i*3+2];
	   ((char*)(PalBGR1024))[i*4+1]=PalRGB[i*3+1];
	   ((char*)(PalBGR1024))[i*4+2]=PalRGB[i*3];
	  }
	ResHz=descimg.ResHz; ResVt=descimg.ResVt;
	if (!CreateSurf(S,ResHz,ResVt,8)) {
        fclose(InGIF);
        printf("no mem\n");
        return 0;
    }
	DebInGIF=ftell(InGIF);
	fseek(InGIF,0,SEEK_END);
	FinInGIF=ftell(InGIF);
	fseek(InGIF,DebInGIF,SEEK_SET);
	BuffIn=malloc(FinInGIF-DebInGIF+4);

	if (BuffIn==NULL) {
        DestroySurf(*S);
        fclose(InGIF);
        printf("no mem2\n");
        return 0;
    }
	fread(BuffIn,FinInGIF-DebInGIF+1,1,InGIF);
// Preparation du buffer
	SizeBl=((unsigned char*)(BuffIn+1))[0];
	BuffD=BuffS=BuffIn+SizeBl+2;
	for (;;) {
	   SizeBl=((unsigned char*)(BuffS))[0];
	   if (SizeBl==0) break;
	   BuffS++;
	   memcpy(BuffD,BuffS,SizeBl);
	   BuffS+=SizeBl;
	   BuffD+=SizeBl;
	  }
	InLZW(BuffIn+2,(*S)->rlfb);
	free(BuffIn); fclose(InGIF);
	return 1;
}


int LoadGIF16(DgSurf **S16,char *filename) {
  char tmpBGRA[1024];
  DgSurf *SGIF8bpp = NULL;
  if (LoadGIF(&SGIF8bpp,filename,tmpBGRA)==0) return 0;
  if (CreateSurf(S16,SGIF8bpp->ResH,SGIF8bpp->ResV,16)==0) {
    DestroySurf(SGIF8bpp);
    return 0;
  }
  // use the new DUGL 1.12 + conversion function
  ConvSurf8ToSurf16Pal(*S16,SGIF8bpp,tmpBGRA);
  DestroySurf(SGIF8bpp);

  return 1;
}


// BMP
int  LoadMemBMP(DgSurf **S,void *In,void *PalBGR1024,int SizeIn) {
	FILE *InBMP;
	int i,j,padd,CurInBMP;
	HeadBMP hbmp;
	InfoBMP ibmp;
	char *Linedata;

	if (In==NULL || SizeIn<=sizeof(HeadBMP)+sizeof(InfoBMP)+1024)
	  return 0;

	bzero(&hbmp,sizeof(HeadBMP));
	bzero(&ibmp,sizeof(InfoBMP));

	// read head
	memcpy(&hbmp,In,sizeof(HeadBMP));

	// verify signature and data offset
	if (hbmp.Sign!='MB' ||
	    (hbmp.DataOffset<sizeof(HeadBMP)+sizeof(InfoBMP)) ||
	     hbmp.DataOffset>hbmp.SizeFile)
	  return 0;

	// read info
	memcpy(&ibmp,In+sizeof(HeadBMP),sizeof(InfoBMP));

	if (ibmp.ImgWidth==0 || ibmp.ImgHeight==0 ||
	    ibmp.BitsPixel!=8 || ibmp.Compression!=0)
	   return 0;

	// no mem
	if (!CreateSurf(S,ibmp.ImgWidth,ibmp.ImgHeight,8))
	   return 0;

	// copy palette
	memcpy(PalBGR1024,In+sizeof(HeadBMP)+sizeof(InfoBMP),1024);

	// seek to data
	CurInBMP=hbmp.DataOffset;
	// read data
	padd=ibmp.ImgWidth&3;
	for (j=ibmp.ImgHeight-1;j>=0;j--) {
	  if (CurInBMP+ibmp.ImgWidth>SizeIn) break;
	  Linedata=(char*)((*S)->rlfb+(j*ibmp.ImgWidth));
	  memcpy(Linedata,In+CurInBMP,ibmp.ImgWidth);
	  CurInBMP+=ibmp.ImgWidth;
	  if (padd) CurInBMP+=(4-padd);
	}

	return 1;
}
int  LoadBMP(DgSurf **S,const char *Fname,void *PalBGR1024) {
	FILE *InBMP;
	int i,j,padd;
	HeadBMP hbmp;
	InfoBMP ibmp;
	char *Linedata;

	if ((InBMP=fopen(Fname,"rb"))==NULL) return 0;

	bzero(&hbmp,sizeof(HeadBMP));
	bzero(&ibmp,sizeof(InfoBMP));

	// read head
	fread(&hbmp,sizeof(HeadBMP),1,InBMP);

	// verify signature and data offset
	if (hbmp.Sign!='MB' ||
	    (hbmp.DataOffset<sizeof(HeadBMP)+sizeof(InfoBMP)) ||
	     hbmp.DataOffset>hbmp.SizeFile)
	  { fclose(InBMP); return 0; }

	// read info
	fread(&ibmp,sizeof(InfoBMP),1,InBMP);

	if (ibmp.ImgWidth==0 || ibmp.ImgHeight==0 ||
	    ibmp.BitsPixel!=8 || ibmp.Compression!=0) {
	   fclose(InBMP); return 0;
	}

	// no mem
	if (!CreateSurf(S,ibmp.ImgWidth,ibmp.ImgHeight,8)) {
	   fclose(InBMP); return 0;
	}

	// read palette
	fread(PalBGR1024,1024,1,InBMP);

	// seek to data
	fseek(InBMP,hbmp.DataOffset,SEEK_SET);
	// read data
	padd=ibmp.ImgWidth&3;
	for (j=ibmp.ImgHeight-1;j>=0;j--) {
	  Linedata=(char*)((*S)->rlfb+(j*ibmp.ImgWidth));
	  fread(Linedata,ibmp.ImgWidth,1,InBMP);
	  if (padd) fseek(InBMP,4-padd,SEEK_CUR);
	}

	fclose(InBMP);
	return 1;
}
int  SaveMemBMP(DgSurf *S,void *Out,void *PalBGR1024) {
	int irow,j,padd,BfPos,sizeBMPFile,sizeline;
	HeadBMP *hbmp;
	InfoBMP *ibmp;
	void *palBMP,*lineOut;

	char *Linedata;
	unsigned char *tempLine;

	if ((sizeBMPFile=SizeSaveBMP(S))==0) return 0;

	if (Out==NULL) return 0;

	hbmp=(HeadBMP*)(Out);
	ibmp=(InfoBMP*)(Out+sizeof(HeadBMP));
	palBMP=(Out+sizeof(HeadBMP)+sizeof(InfoBMP));

	bzero(hbmp,sizeof(HeadBMP));
	bzero(ibmp,sizeof(InfoBMP));

	// init header
	hbmp->Sign='MB';
	hbmp->SizeFile=sizeBMPFile;
	hbmp->DataOffset=sizeof(HeadBMP)+sizeof(InfoBMP)+1024;
	// init info
	ibmp->SizeInfo=sizeof(InfoBMP);
	ibmp->ImgWidth=S->ResH;  ibmp->ImgHeight=S->ResV;
	ibmp->Planes=1;
	ibmp->BitsPixel=8;

	// write palette
	memcpy(palBMP,PalBGR1024,1024);

	// compute padd
	padd=(ibmp->ImgWidth)&3;
	if (padd>0) padd=4-padd;
	sizeline=ibmp->ImgWidth+padd;
	// alloc temporary
	tempLine = (unsigned char*)malloc(sizeline);
	// clear
	bzero(tempLine,sizeline);

	// write data
	if (tempLine!=NULL) {
	  lineOut=Out+hbmp->DataOffset;
	  for (j=ibmp->ImgHeight-1;j>=0;j--) {
	    Linedata=(char*)(S->rlfb+(j*ibmp->ImgWidth));
	    memcpy(tempLine,Linedata,ibmp->ImgWidth);
	    memcpy(lineOut,tempLine,sizeline);
	    lineOut+=sizeline;
	  }
	  free(tempLine);
	}

	//fclose(OutBMP);
	return 1;
}

int  SaveBMP(DgSurf *S,const char *Fname,void *PalBGR1024) {
	FILE *OutBMP;
	int irow,j,padd,BfPos,sizeBMPFile,sizeline;
	HeadBMP hbmp;
	InfoBMP ibmp;
	short *Linedata;
	unsigned char *tempLine;

	if ((sizeBMPFile=SizeSaveBMP(S))==0) return 0;

	if ((OutBMP=fopen(Fname,"wb"))==NULL) return 0;

	bzero(&hbmp,sizeof(HeadBMP));
	bzero(&ibmp,sizeof(InfoBMP));

	// init header
	hbmp.Sign='MB';
	hbmp.SizeFile=sizeBMPFile;
	hbmp.DataOffset=sizeof(HeadBMP)+sizeof(InfoBMP)+1024;
	// init info
	ibmp.SizeInfo=sizeof(InfoBMP);
	ibmp.ImgWidth=S->ResH;  ibmp.ImgHeight=S->ResV;
	ibmp.Planes=1;
	ibmp.BitsPixel=8;


	// write header
	fwrite(&hbmp,sizeof(HeadBMP),1,OutBMP);
	// write info
	fwrite(&ibmp,sizeof(InfoBMP),1,OutBMP);
	// write palette
	fwrite(PalBGR1024,1024,1,OutBMP);

	// compute padd
	padd=(ibmp.ImgWidth)&3;
	if (padd>0) padd=4-padd;
	sizeline=ibmp.ImgWidth+padd;
	// alloc temporary
	tempLine = (unsigned char*)malloc(sizeline);
	// clear
	bzero(tempLine,sizeline);

	// write data
	if (tempLine!=NULL) {
	  for (j=ibmp.ImgHeight-1;j>=0;j--) {
	    Linedata=(char*)(S->rlfb+(j*ibmp.ImgWidth));
	    memcpy(tempLine,Linedata,ibmp.ImgWidth);
	    fwrite(tempLine,sizeline,1,OutBMP);
	  }
	  free(tempLine);
	}

	fclose(OutBMP);
	return 1;
}
int  SizeSaveBMP(DgSurf *S) {
	int padd=0;
	if (S->rlfb==0 || S->BitsPixel!=8 || S->ResH<=0 || S->ResV<=0)
	  return 0;
	padd=(S->ResH)&3;
	if (padd>0) padd=4-padd;
	return sizeof(HeadBMP)+sizeof(InfoBMP)+(((S->ResH)+padd)*S->ResV)+1024;
}

int  LoadMemBMP16(DgSurf **S,void *In,int SizeIn) {
	int irow,j,padd,CurInBMP,BfPos;
	HeadBMP hbmp;
	InfoBMP ibmp;
	unsigned short *Linedata;
	unsigned char *tempLine;

	if (In==NULL || SizeIn<=sizeof(HeadBMP)+sizeof(InfoBMP))
	  return 0;

	bzero(&hbmp,sizeof(HeadBMP));
	bzero(&ibmp,sizeof(InfoBMP));

	// read head
	memcpy(&hbmp,In,sizeof(HeadBMP));

	// verify signature and data offset
	if (hbmp.Sign!='MB' ||
	    (hbmp.DataOffset<sizeof(HeadBMP)+sizeof(InfoBMP)) ||
	     hbmp.DataOffset>hbmp.SizeFile)
	  return 0;

	// read info
	memcpy(&ibmp,In+sizeof(HeadBMP),sizeof(InfoBMP));


	if (ibmp.ImgWidth==0 || ibmp.ImgHeight==0 ||
	    ibmp.BitsPixel!=24 || ibmp.Compression!=0)
	   return 0;

	// no mem
	if (!CreateSurf(S,ibmp.ImgWidth,ibmp.ImgHeight,16))
	   return 0;


	// seek to data
	CurInBMP=hbmp.DataOffset;
	// read data
	padd=(ibmp.ImgWidth*3)&3;
	for (j=ibmp.ImgHeight-1;j>=0;j--) {
	  if (CurInBMP+ibmp.ImgWidth*3>SizeIn) break;
	  Linedata=(unsigned short*)((*S)->rlfb+(j*ibmp.ImgWidth*2));
	  tempLine=(unsigned char*)(In+CurInBMP);
	  BfPos=0;
	  for (irow=0;irow<ibmp.ImgWidth;irow++) {
	    Linedata[irow]=(tempLine[BfPos]>>3)|((tempLine[BfPos+1]>>2)<<5)|
		((tempLine[BfPos+2]>>3)<<11);
	      BfPos+=3;
	  }

	  CurInBMP+=ibmp.ImgWidth*3;
	  if (padd) CurInBMP+=(4-padd);
	}

	return 1;
}
int  LoadBMP16(DgSurf **S,const char *Fname) {
	FILE *InBMP;
	int irow,j,padd,BfPos;
	HeadBMP hbmp;
	InfoBMP ibmp;
	short *Linedata;
	unsigned char *tempLine;

	if ((InBMP=fopen(Fname,"rb"))==NULL) return 0;

	bzero(&hbmp,sizeof(HeadBMP));
	bzero(&ibmp,sizeof(InfoBMP));

	// read head
	fread(&hbmp,sizeof(HeadBMP),1,InBMP);

	// verify signature and data offset
	if (hbmp.Sign!='MB' ||
	    (hbmp.DataOffset<sizeof(HeadBMP)+sizeof(InfoBMP)) ||
	     hbmp.DataOffset>hbmp.SizeFile)
	  { fclose(InBMP); return 0; }

	// read info
	fread(&ibmp,sizeof(InfoBMP),1,InBMP);

	if (ibmp.ImgWidth==0 || ibmp.ImgHeight==0 ||
	    ibmp.BitsPixel!=24 || ibmp.Compression!=0) {
	   fclose(InBMP); return 0;
	}

	// no mem
	if (!CreateSurf(S,ibmp.ImgWidth,ibmp.ImgHeight,16)) {
	   fclose(InBMP); return 0;
	}

	// seek to data
	fseek(InBMP,hbmp.DataOffset,SEEK_SET);
	// alloc temporary
	tempLine = (unsigned char*)malloc(ibmp.ImgWidth*3);

	// read data
	if (tempLine!=NULL) {
	  padd=(ibmp.ImgWidth*3)&3;
	  for (j=ibmp.ImgHeight-1;j>=0;j--) {
	    Linedata=(short*)((*S)->rlfb+(j*ibmp.ImgWidth*2));
	    fread(tempLine,ibmp.ImgWidth*3,1,InBMP);
	    if (padd) fseek(InBMP,4-padd,SEEK_CUR);
	    BfPos=0;
	    for (irow=0;irow<ibmp.ImgWidth;irow++) {
	      Linedata[irow]=(tempLine[BfPos]>>3)|((tempLine[BfPos+1]>>2)<<5)|
		((tempLine[BfPos+2]>>3)<<11);
	      BfPos+=3;
	    }
	  }
	  free(tempLine);
	}

	fclose(InBMP);
	return 1;

}
int  SaveMemBMP16(DgSurf *S,void *Out) {
	int irow,j,padd,BfPos,sizeBMPFile,sizeline;
	HeadBMP *hbmp;
	InfoBMP *ibmp;
	short *Linedata;
	unsigned char *tempLine;

	if (Out==NULL || (sizeBMPFile=SizeSaveBMP16(S))==0) return 0;

	hbmp=(HeadBMP*)(Out);
	ibmp=(InfoBMP*)(Out+sizeof(HeadBMP));

	bzero(hbmp,sizeof(HeadBMP));
	bzero(ibmp,sizeof(InfoBMP));

	// init header
	hbmp->Sign='MB';
	hbmp->SizeFile=sizeBMPFile;
	hbmp->DataOffset=sizeof(HeadBMP)+sizeof(InfoBMP);
	// init info
	ibmp->SizeInfo=sizeof(InfoBMP);
	ibmp->ImgWidth=S->ResH;  ibmp->ImgHeight=S->ResV;
	ibmp->Planes=1;
	ibmp->BitsPixel=24;

	// compute padd
	padd=(ibmp->ImgWidth*3)&3;
	if (padd>0) padd=4-padd;
	sizeline=ibmp->ImgWidth*3+padd;
	tempLine =
	  (unsigned char*)(Out+sizeof(HeadBMP)+sizeof(InfoBMP));

	// read data
	if (tempLine!=NULL) {
	  for (j=ibmp->ImgHeight-1;j>=0;j--) {
	    Linedata=(short*)(S->rlfb+(j*ibmp->ImgWidth*2));
	    BfPos=0;
	    // BGR 16 -> RGB 24
	    for (irow=0;irow<S->ResH;irow++) {
	      tempLine[BfPos]=(Linedata[irow]&0x1f)<<3;
	      tempLine[BfPos+1]=(Linedata[irow]&0x7e0)>>3;
	      tempLine[BfPos+2]=(Linedata[irow]&0xf800)>>8;
	      BfPos+=3;
	    }
	    tempLine+=sizeline;
	  }
	}

	return 1;
}

int  SaveBMP16(DgSurf *S,const char *Fname) {
	FILE *OutBMP;
	int irow,j,padd,BfPos,sizeBMPFile,sizeline;
	HeadBMP hbmp;
	InfoBMP ibmp;
	short *Linedata;
	unsigned char *tempLine;

	if ((sizeBMPFile=SizeSaveBMP16(S))==0) return 0;

	if ((OutBMP=fopen(Fname,"wb"))==NULL) return 0;

	bzero(&hbmp,sizeof(HeadBMP));
	bzero(&ibmp,sizeof(InfoBMP));

	// init header
	hbmp.Sign='MB';
	hbmp.SizeFile=sizeBMPFile;
	hbmp.DataOffset=sizeof(HeadBMP)+sizeof(InfoBMP);
	// init info
	ibmp.SizeInfo=sizeof(InfoBMP);
	ibmp.ImgWidth=S->ResH;  ibmp.ImgHeight=S->ResV;
	ibmp.Planes=1;
	ibmp.BitsPixel=24;


	// write header
	fwrite(&hbmp,sizeof(HeadBMP),1,OutBMP);
	// read info
	fwrite(&ibmp,sizeof(InfoBMP),1,OutBMP);

	// compute padd
	padd=(ibmp.ImgWidth*3)&3;
	if (padd>0) padd=4-padd;
	sizeline=ibmp.ImgWidth*3+padd;
	// alloc temporary
	tempLine = (unsigned char*)malloc(sizeline);

	// read data
	if (tempLine!=NULL) {
	  for (j=ibmp.ImgHeight-1;j>=0;j--) {
	    Linedata=(short*)(S->rlfb+(j*ibmp.ImgWidth*2));
	    //if (padd) fseek(InBMP,4-padd,SEEK_CUR);
	    BfPos=0;
	    // BGR 16 -> RGB 24
	    for (irow=0;irow<S->ResH;irow++) {
	      tempLine[BfPos]=(Linedata[irow]&0x1f)<<3;
	      tempLine[BfPos+1]=(Linedata[irow]&0x7e0)>>3;
	      tempLine[BfPos+2]=(Linedata[irow]&0xf800)>>8;
	      BfPos+=3;
	    }
	    fwrite(tempLine,sizeline,1,OutBMP);
	  }
	  free(tempLine);
	}

	fclose(OutBMP);
	return 1;
}

int  SizeSaveBMP16(DgSurf *S) {
	int padd=0;
	if (S->rlfb==0 || S->BitsPixel!=16 || S->ResH<=0 || S->ResV<=0)
	  return 0;
	padd=(S->ResH*3)&3;
	if (padd>0) padd=4-padd;
	return sizeof(HeadBMP)+sizeof(InfoBMP)+(((S->ResH*3)+padd)*S->ResV);
}

