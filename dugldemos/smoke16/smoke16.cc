/*  DUGL Dos Ultimate Game Library - (C) FFK */
/*  Smoke and solid color blending demo on 16bpp */
/*  History : */
/*  20 march 2008 : first release */
/*  9 november 2008 : make a bmp screenshot unstead of jpg one */
/*  11 august 2009 : updated fps displaying, move synching with lastFPs */

#include <stdio.h>
#include <conio.h>
#include <stdlib.h>
#include <string.h>
#include <dpmi.h>

#include <dugl/dugl.h>


// screen resolution
int ScrResH=640,ScrResV=480;

// an Int table of a couple x,y
int Points[12] =
   {   15,   0,    10,   15,   -10,   15,
      -15,   0,   -10,  -15,    10,  -15
   };
int ListPt1[] =
    {  6,  (int)&Points[0], (int)&Points[2],
           (int)&Points[4], (int)&Points[6],
           (int)&Points[8], (int)&Points[10]
    };
// smoke
typedef struct {
  float x,y;
  float XDevCoef;
  bool enabled;
} smoke;

#define NUMBER_SMOKES 500
smoke TSmokes[NUMBER_SMOKES];

// render Surf
Surf rendSurf16,blurSurf16;

//******************
// FONT
FONT F1;
// mouse View
View MsV;
// display parameters
bool SynchScreen=false,BlurDisplay=false;
// synch buffer
char SynchBuff[SIZE_SYNCH_BUFF];
int PosSynch;


//******* Global function ****************************
// Synch screen Display
void DGWaitRetrace();

int main (int argc, char ** argv)
{
    if (CreateSurf(&rendSurf16, ScrResH, ScrResV, 16)==0) {
      printf("no mem\n"); exit(-1);
    }
    if (CreateSurf(&blurSurf16, ScrResH, ScrResV, 16)==0) {
      printf("no mem\n"); exit(-1);
    }


    // load font
    if (!LoadFONT(&F1,"hello.chr")) {
      printf("Error loading hello.chr\n"); exit(-1); }

    // init the lib
    if (!InitVesa())
      { printf("DUGL init error\n"); exit(-1); }

    if (!InstallTimer(1000)) {
       CloseVesa(); printf("Timer error\n"); exit(-1);
    }
    if (!InstallKeyboard()) {
       CloseVesa(); UninstallTimer();
       printf("Keyboard error\n");  exit(-1);
    }

    // init video mode
    if (!InitVesaMode(ScrResH,ScrResV,16,1))
      {  printf("VESA mode error\n"); CloseVesa(); exit(-1); }

    SetSurf(&VSurf[0]);
    Clear16(0); // clear by black

    SetFONT(&F1);
    // Init Table of smokes
    for (int i=0;i<NUMBER_SMOKES;i++) {
      TSmokes[i].x=rand()%(ScrResH/8)+ScrResH/4;
      TSmokes[i].y=0;
      TSmokes[i].enabled=false;
      TSmokes[i].XDevCoef=(float)(TSmokes[i].x-ScrResH/4)/(float)(ScrResH/8)-0.5;
    }

    // init synch for synching the screen
    PosSynch=0;
    int LastPos=PosSynch,DeltaPos;

    // init synchro, 30 will be the count of the enabled smoke per sec
    InitSynch(SynchBuff,&PosSynch,30);
    // main loop
    for (int j=0;;j++) {
      FREE_MMX();
      // synchronise
      Synch(SynchBuff,&PosSynch);
      //
      DeltaPos=PosSynch-LastPos;
      LastPos=PosSynch;
      
      // synch screen display
      float avgFps=SynchAverageTime(SynchBuff),
            lastFps=SynchLastTime(SynchBuff);

      if (lastFps <= 0.1f)
        __dpmi_yield();

      // set the current active surface for drawing
      SetSurf(&rendSurf16);
      
      unsigned char keyCode;
      unsigned int keyFLAG;
      // render ///////////////////
      Clear16(0x1e|0x380);

      bool EnableOneSmk=true;
      for (int i=0;i<NUMBER_SMOKES;i++) {
        FREE_MMX();
        int x=(int)(TSmokes[i].x);
        int y=(int)(TSmokes[i].y);

        // enable 30 smoke per sec
        if (EnableOneSmk && DeltaPos>0 && (!TSmokes[i].enabled)) {
          TSmokes[i].enabled=true;
          EnableOneSmk=false;
        }
        // compute color and blending
        float coef=float(y)/ScrResV;
        // higher whiter
        int b=(int)(31.0*coef);
        int g=(int)(63.0*coef);
        int r=(int)(31.0*coef);
        // higher more transparent
        int blnd=(int)(30.0-25.0*coef);
        int col=b|(g<<5)|(r<<11)|(blnd<<24);

        // increase position of the enabled smokes
        if (TSmokes[i].enabled) {
          TSmokes[i].y+=lastFps*(60.0); // speed is 60 pixel per sec
          TSmokes[i].x+=(TSmokes[i].XDevCoef*(10.0))*lastFps;
          // if out on the sky reinit
          if (TSmokes[i].y>ScrResV) {
            TSmokes[i].x=rand()%(ScrResH/8)+ScrResH/4;
            TSmokes[i].y=0;
          }
        }
        // change the origin of the screen
        // no need to rebuild the coordinates of the poly :)
        SetOrgSurf(&CurSurf,x,y);
        Poly16(&ListPt1, NULL, POLY16_SOLID_BLND, col);

      }


      // end render ///////////////
      // get key
      GetKey(&keyCode, &keyFLAG);
      switch (keyCode) {
        case 63 : // F5 vertical synch e/d
          SynchScreen=(SynchScreen)?false:true; break;
        case 64 : // F6 blur
          BlurDisplay=(BlurDisplay)?false:true; break;
      }
      
      if (BlurDisplay) {
         BlurSurf16(&blurSurf16,&rendSurf16);
         SetSurf(&blurSurf16);
      }
      else
        SetSurf(&rendSurf16);
      // display AVG FPS

      FREE_MMX();
      ClearText();
      char text[100];
      SetTextCol(0xffff);
      if (avgFps!=0.0)
        sprintf(text,"FPS %i",(int)(1.0/avgFps));
      else
        sprintf(text,"FPS ???");
      
      OutText16Mode(text,AJ_RIGHT);
      ClearText();
      OutText16Mode("Esc Exit\nF5  Vertical Synch\nF6  Blur",AJ_LEFT);

      // blit the rendered to the screen
      SetSurf(&VSurf[0]);
      
      // vertical synch ?
      DGWaitRetrace();
      if (BlurDisplay)
         PutSurf16(&blurSurf16,0,0,0);
      else
         PutSurf16(&rendSurf16,0,0,0);
      // esc exit
      if (IsKeyDown(0x1)) break;
      // ctrl + shift + tab  = BMP screenshot
      if (IsKeyDown(0xf) && (KbFLAG&KB_SHIFT_PR) && (KbFLAG&KB_CTRL_PR))
         SaveBMP16(&VSurf[0],"smoke16.bmp");
    }


    CloseVesa();
    UninstallKeyboard();
    UninstallTimer();
    TextMode();


    return 0;
}


// DUGL Util waitRetrace
void DGWaitRetrace() {
  if (!SynchScreen) return;
  if (CurMode.VModeFlag|VMODE_VGA)
     WaitRetrace(); // VGA wait retrace
  else
     ViewSurfWaitVR(0);
}


