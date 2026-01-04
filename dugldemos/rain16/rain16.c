/*  DUGL Dos Ultimate Game Library - (C) FFK */
/*  Rain : color transparency demo on 16bpp */
/*  History : */
/*  23 november 2008 : first release */
/*  11 august 2009 : Updated fps displaying, move synching with lastFps,
    usage of the fast SurfCopy instead of (SetSurf, PutSurf)*/
/* 25 december 2025 : Fix gcc 12 errors / updates */

#include <stdio.h>
#include <conio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "dugl.h"


// screen resolution
#define SCREEN_WIDTH 640
#define SCREEN_HEIGHT 480
int ScrResH=SCREEN_WIDTH,ScrResV=SCREEN_HEIGHT;

// polygone points and list of drop over screen

#define WT_XTEX (SCREEN_WIDTH/50)
#define WT_YTEX (SCREEN_HEIGHT/50)

// textured poly points
//               X    Y    Z       XT = U           YT = V
int PtWt01[5] = { 0,   0,   0,   WT_XTEX*4, WT_YTEX*2 };
int PtWt02[5] = { 0,   0,   0,   WT_XTEX*4, WT_YTEX*1 };
int PtWt03[5] = { 0,   0,   0,   WT_XTEX*4, WT_YTEX*0 };
int PtWt04[5] = { 0,   0,   0,   WT_XTEX*3, WT_YTEX*0 };
int PtWt05[5] = { 0,   0,   0,   WT_XTEX*2, WT_YTEX*0 };
int PtWt06[5] = { 0,   0,   0,   WT_XTEX*1, WT_YTEX*0 };
int PtWt07[5] = { 0,   0,   0,   WT_XTEX*0, WT_YTEX*0 };
int PtWt08[5] = { 0,   0,   0,   WT_XTEX*0, WT_YTEX*1 };
int PtWt09[5] = { 0,   0,   0,   WT_XTEX*0, WT_YTEX*2 };
int PtWt10[5] = { 0,   0,   0,   WT_XTEX*0, WT_YTEX*3 };
int PtWt11[5] = { 0,   0,   0,   WT_XTEX*0, WT_YTEX*4 };
int PtWt12[5] = { 0,   0,   0,   WT_XTEX*1, WT_YTEX*4 };
int PtWt13[5] = { 0,   0,   0,   WT_XTEX*2, WT_YTEX*4 };
int PtWt14[5] = { 0,   0,   0,   WT_XTEX*3, WT_YTEX*4 };
int PtWt15[5] = { 0,   0,   0,   WT_XTEX*4, WT_YTEX*4 };
int PtWt16[5] = { 0,   0,   0,   WT_XTEX*4, WT_YTEX*3 };


// points List
int ListPtWt1[] =
        {  16,  (int)&PtWt01, (int)&PtWt02, (int)&PtWt03, (int)&PtWt04,
                (int)&PtWt05, (int)&PtWt06, (int)&PtWt07, (int)&PtWt08,
                (int)&PtWt09, (int)&PtWt10, (int)&PtWt11, (int)&PtWt12,
                (int)&PtWt13, (int)&PtWt14, (int)&PtWt15, (int)&PtWt16
        };

// screens drops

typedef struct {
  float x,y;
  int rayx,rayy;
  int speed;
  float TimeToGo,TimeHere;
  bool go;
} scrDrop;

#define NUMBER_SCR_DROPS 15
scrDrop TScr[NUMBER_SCR_DROPS];


// rain drops
typedef struct {
  float x,y;
  int dy, map, speed;
  bool enabled;
} drop;

#define NUMBER_DROPS 1500
drop TRain[NUMBER_DROPS];

// cloud
typedef struct {
  float x,y;
  int rayx, rayy, speed;
  bool enabled,RightCloud;
} cloud;

#define NUMBER_CLOUD 20
cloud TCloud[NUMBER_CLOUD];


// render Surf
Surf *rendSurf16, *blurSurf16;
Surf *BackSurf,tmpBackSurf;
Surf *smallRendSurf16;

//******************
// FONT
FONT F1;
// mouse View
View MsV;
// display parameters
bool SynchScreen=false,BlurDisplay=false,Transparency=true;
// synch buffer
char SynchBuff[SIZE_SYNCH_BUFF];
int PosSynch;
// random generation
void GenRandDrop(drop *pDrop);
void GenRandCloud(cloud *pCloud);
void GenRandScrDrop(scrDrop *pScrDrop);

// rendering function
void ModifiListPtCircle(int *ListPt,int posx, int posy, int rayx,int rayy);
void RenderCloud(cloud *pCloud);
void RenderWirePoly(int *ListPt);
void RenderScrDrop(scrDrop *pScrDrop);

//******* Global function ****************************
// resize a 16bpp Surf into an another Surf
void ResizeSurf16(Surf *SDstSurf,Surf *SSrcSurf);
// load a 8bpp gif into a 16bpp Surf
int LoadGIF16(Surf **S16,char *filename);
// Synch screen Display
void DGWaitRetrace();

int main (int argc, char ** argv)
{
    // init the lib
    if (!InitVesa())
      { printf("DUGL init error\n"); exit(-1); }

    if (CreateSurf(&rendSurf16, ScrResH, ScrResV, 16)==0) {
      printf("no mem\n"); exit(-1);
    }
    if (CreateSurf(&blurSurf16, ScrResH, ScrResV, 16)==0) {
      printf("no mem\n"); exit(-1);
    }
    if (CreateSurf(&smallRendSurf16, ScrResH/10, ScrResV/10, 16)==0) {
      printf("no mem\n"); exit(-1);
    }

    // load GFX
    if (!LoadGIF16(&BackSurf,"jeux1.gif")) {
      printf("Error loading jeux1.gif\n"); exit(-1); }

    // load font
    if (!LoadFONT(&F1,"hello.chr")) {
      printf("Error loading hello.chr\n"); exit(-1); }

    if (!DgInstallTimer(500)) {
       CloseVesa(); printf("Timer error\n"); exit(-1);
    }
    if (!InstallKeyboard()) {
       CloseVesa(); DgUninstallTimer();
       printf("Keyboard error\n");  exit(-1);
    }

    // init video mode
    if (!InitVesaMode(ScrResH,ScrResV,16,1))
      {  printf("VESA mode error\n"); CloseVesa(); exit(-1); }

    SetSurf(&VSurf[0]);
    Clear16(0); // clear by black

    SetFONT(&F1);
    // Init Table of rain
    for (int i=0;i<NUMBER_DROPS;i++) {
      GenRandDrop(&TRain[i]);
    }
    // Init Table of clouds
    for (int i=0;i<NUMBER_CLOUD;i++) {
      GenRandCloud(&TCloud[i]);
    }
    // Init table of Screen Drops
    for (int i=0;i<NUMBER_SCR_DROPS;i++) {
      GenRandScrDrop(&TScr[i]);
    }

    // init synch for synching the screen
    PosSynch=0;
    int LastPos=PosSynch,DeltaPos;

    // init synchro, 30 will be the count of the enabled smoke per sec
    FREE_MMX(); InitSynch(SynchBuff,&PosSynch,30);
    // main loop
    for (int j=0;;j++) {
      // synchronise
      FREE_MMX(); Synch(SynchBuff,&PosSynch);
      //
      DeltaPos=PosSynch-LastPos;
      LastPos=PosSynch;

      // synch screen display
      float avgFps=SynchAverageTime(SynchBuff),
            lastFps=SynchLastTime(SynchBuff);

      // set the current active surface for drawing
      SetSurf(rendSurf16);

      unsigned char keyCode;
      unsigned int keyFLAG;
      // render ///////////////////
      //Clear16(0x1e|0x380);

      // fit the backgroud Surf on the screen
      ResizeSurf16(&CurSurf, BackSurf);
      // render rain
      SetOrgSurf(&CurSurf,0,0);

      bool EnableOneSmk=true;
      for (int i=0;i<NUMBER_DROPS;i++) {
        FREE_MMX();
        int x=(int)(TRain[i].x);
        int y=(int)(TRain[i].y);

        // enable one rain per frame
        if (EnableOneSmk && (!TRain[i].enabled)) {
          TRain[i].enabled=true;
          EnableOneSmk=false;
        }
        // b | g | r | blend
        int col=0xf|(0x1f<<5)|(0xf<<11)|(10<<24);

        // increase position of the enabled smokes
        if (TRain[i].enabled) {
          TRain[i].y+=lastFps*(-TRain[i].speed);
          // if out on the sky reinit
          if (TRain[i].y<0) {
             FREE_MMX();
             GenRandDrop(&TRain[i]);
          }
          if (Transparency)
            linemapblnd16(x,y,x,y+TRain[i].dy, col,TRain[i].map);
          else
            linemap16(x,y,x,y+TRain[i].dy, col,TRain[i].map);

        }

      }
      // render Cloud
      for (int i=0;i<NUMBER_CLOUD;i++) {
          FREE_MMX();
          RenderCloud(&TCloud[i]);
          FREE_MMX();
          TCloud[i].x+=lastFps*(TCloud[i].speed);
          if ((TCloud[i].RightCloud && (TCloud[i].x+TCloud[i].rayx)<0) ||
              ((!TCloud[i].RightCloud) && (TCloud[i].x-TCloud[i].rayx>ScrResH))) {
             GenRandCloud(&TCloud[i]);
          }

      }

      ResizeSurf16(smallRendSurf16,&CurSurf);
//      SetOrgSurf(&smallRendSurf16,10,10);
      // Init table of Screen Drops
      for (int i=0;i<NUMBER_SCR_DROPS;i++) {

        FREE_MMX();
        if (TScr[i].go)
          TScr[i].y-=lastFps*TScr[i].speed;
        else {
          TScr[i].TimeHere+=lastFps;
          if (TScr[i].TimeHere>=TScr[i].TimeToGo)
            TScr[i].go=true;
        }

        RenderScrDrop(&TScr[i]);
        FREE_MMX();
        if ((TScr[i].go) && (TScr[i].y+TScr[i].rayy<=0))
          GenRandScrDrop(&TScr[i]);
      }

      // end render ///////////////
      // get key
      GetKey(&keyCode, &keyFLAG);
      switch (keyCode) {
        case KB_KEY_F5 : // F5 vertical synch e/d
          SynchScreen=!SynchScreen; break;
        case KB_KEY_F6 : // F6 blur
          BlurDisplay=!BlurDisplay; break;
        case KB_KEY_F7 : // F7 transparency
          Transparency=!Transparency; break;
      }


      if (BlurDisplay) {
         Blur16((void*)(blurSurf16->rlfb), (void*)(rendSurf16->rlfb), blurSurf16->ResH, blurSurf16->ResV, 0, (blurSurf16->ResV - 1));
         SetSurf(blurSurf16);
      }
      else {
        SetSurf(rendSurf16);
      }


      // display FPS

      FREE_MMX();
      ClearText();
      char text[100];
      SetTextCol(0xffff);
      if(avgFps!=0.0)
        sprintf(text,"FPS %i",(int)(1.0/avgFps));
      else
        sprintf(text,"FPS ???");
      OutText16Mode(text,AJ_RIGHT);
      ClearText();
      OutText16Mode("Esc Exit\nF5  Vertical Synch\nF6  Blur\nF7  Transparency\n",AJ_LEFT);

      // vertical synch ?
      DGWaitRetrace();
      if (BlurDisplay)
         SurfCopy(&VSurf[0], blurSurf16);
      else
         SurfCopy(&VSurf[0], rendSurf16);
      // esc exit
      if (IsKeyDown(KB_KEY_ESC)) break;
      // ctrl + shift + tab  = BMP screenshot
      if (IsKeyDown(KB_KEY_TAB) && (KbFLAG&KB_SHIFT_PR) && (KbFLAG&KB_CTRL_PR))
         SaveBMP16(&VSurf[0],"rain16.bmp");
    }

    CloseVesa();
    UninstallKeyboard();
    DgUninstallTimer();
    TextMode();

    return 0;
}

// rendering function
void ModifiListPtCircle(int *ListPt,int posx, int posy, int rayx,int rayy) {
   FREE_MMX();
   int nbVertex=ListPt[0];
   float radStep=(3.14*2.0)/((float)(nbVertex));
   int *Point;
   for (int iv=0;iv<nbVertex;iv++) {
     Point=(int*)ListPt[iv+1];
     Point[0]=rayx*cos(radStep*iv)+posx;
     Point[1]=rayy*sin(radStep*iv)+posy;
   }
}

void RenderWirePoly(int *ListPt) {
   FREE_MMX();
   int nbVertex=ListPt[0];
   int *Point1,*Point2;
   int PtZ[2]={ ScrResH/2, ScrResV/2 };
   Point1=(int*)ListPt[1];
   Point2=(int*)ListPt[nbVertex];
   Line16(Point1,Point2,0xffff);
   for (int iv=0;iv<nbVertex-1;iv++) {
     FREE_MMX();
     Point1=(int*)ListPt[iv+1];
     Point2=(int*)ListPt[iv+2];
     Line16(Point1,Point2,0xffff);
   }
}

void RenderCloud(cloud *pCloud) {

    const int nbVertex=20;
    int tCldVertex[nbVertex*2];
    int ListPt[nbVertex+1];

    FREE_MMX();
    // fill vertexes
    float radStep=(3.14*2.0)/((float)(nbVertex));
    for (int iv=0;iv<nbVertex;iv++) {
      tCldVertex[(iv*2)]=pCloud->rayx*cos(radStep*iv)+pCloud->x;
      tCldVertex[(iv*2)+1]=pCloud->rayy*sin(radStep*iv)+pCloud->y;
    }
    // fill list of point structure
    ListPt[0]=nbVertex;
    for (int iv=0;iv<nbVertex;iv++)
      ListPt[iv+1]=(int)(&tCldVertex[iv*2]);
    // render the poly
    if (Transparency)
       Poly16(ListPt,NULL,POLY16_SOLID_BLND|POLY16_FLAG_DBL_SIDED,0x3|(0x7<<5)|(0x3<<11)|(20<<24));
    else
      Poly16(ListPt,NULL,POLY16_SOLID|POLY16_FLAG_DBL_SIDED,0x3|(0x7<<5)|(0x3<<11)|(20<<24));
}

void RenderScrDrop(scrDrop *pScrDrop) {
   SetOrgSurf(smallRendSurf16,((ScrResH-pScrDrop->x)*WT_XTEX)/ScrResH,((ScrResV-pScrDrop->y)*WT_YTEX)/ScrResV);
   ModifiListPtCircle(ListPtWt1,pScrDrop->x,pScrDrop->y, pScrDrop->rayx, pScrDrop->rayy);
   Poly16(ListPtWt1,smallRendSurf16,POLY16_TEXT/*|POLY16_FLAG_DBL_SIDED*/,0);
}
// load a 8bpp gif and convert it to 16 bpp
int LoadGIF16(Surf **S16,char *filename) {
  char tmpBGRA[1024];
  Surf *SGIF8bpp = NULL;
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


// DUGL Util waitRetrace
void DGWaitRetrace() {
  if (!SynchScreen) return;
  if (CurMode.VModeFlag|VMODE_VGA)
     WaitRetrace(); // VGA wait retrace
  else
     ViewSurfWaitVR(0);
}


// resize a 16bpp Surf into an another Surf
void ResizeSurf16(Surf *SDstSurf,Surf *SSrcSurf) {
  Surf OldSurf,SrcSurf;
  Surf *SSrc=SSrcSurf;
  // textured poly points
  //                 X              Y              Z       XT = U           YT = V
  int Pt1[5] = { SDstSurf->MinX, SDstSurf->MinY,   0,   SSrcSurf->MinX, SSrcSurf->MinY };
  int Pt2[5] = { SDstSurf->MaxX, SDstSurf->MinY,   0,   SSrcSurf->MaxX, SSrcSurf->MinY };
  int Pt3[5] = { SDstSurf->MaxX, SDstSurf->MaxY,   0,   SSrcSurf->MaxX, SSrcSurf->MaxY };
  int Pt4[5] = { SDstSurf->MinX, SDstSurf->MaxY,   0,   SSrcSurf->MinX, SSrcSurf->MaxY };
  // points List
  int ListPt1[] = {  4,  (int)&Pt1, (int)&Pt2, (int)&Pt3, (int)&Pt4 };

  // save the source Surf In case the CurSurf is the source
  if (SSrcSurf==&CurSurf) {
     SrcSurf=*SSrcSurf;
     SSrc=&SrcSurf;
  }

  // Get Current Surf
  GetSurf(&OldSurf);

  // set dest Surf as destination
  SetSurf(SDstSurf);

  // draw the resize polygone inside the dest Surf
  Poly16(ListPt1, SSrc, POLY16_TEXT, 0);

  // restore
  SetSurf(&OldSurf);
}


// random generation
void GenRandDrop(drop *pDrop) {
  pDrop->x=rand()%ScrResH;
  pDrop->y=ScrResV+10;
  pDrop->dy=-((rand()%40));
  pDrop->map=rand();
  pDrop->speed=((rand()%200)+150);
  int z=(rand()&511)+10;
  pDrop->speed=(pDrop->speed*255)/z; // more far slower
  pDrop->dy=(pDrop->dy*255)/z; // more far smaller
}

void GenRandCloud(cloud *pCloud) {
  pCloud->rayx=rand()%(ScrResH/4)+(ScrResH/12);
  pCloud->rayy=rand()%(ScrResV/6)+(ScrResV/24);
  pCloud->enabled=true;
  pCloud->RightCloud=rand()&1;
  pCloud->y=ScrResV+10-(rand()%(ScrResV/15));

  if (pCloud->RightCloud) {
     pCloud->x=ScrResH+pCloud->rayx;
     pCloud->speed=-(rand()%(ScrResV/15)+10);
  }
  else {
     pCloud->x=-pCloud->rayx;
     pCloud->speed=(rand()%(ScrResV/15)+10);
  }

}
void GenRandScrDrop(scrDrop *pScrDrop) {
  pScrDrop->x=rand()%((ScrResH*8)/10)+ScrResH/10;
  pScrDrop->y=rand()%(ScrResV*3/4);
  pScrDrop->rayx=(rand()%(ScrResH/150))+ScrResH/85;
  pScrDrop->rayy=(rand()%(ScrResH/120))+ScrResV/65;
  pScrDrop->speed=(rand()%(ScrResV/5))+ScrResV/8;
  pScrDrop->TimeToGo=(float)((rand()%200))/200.0+1.5;
  pScrDrop->TimeHere=0.0;
  pScrDrop->go=false;

}

