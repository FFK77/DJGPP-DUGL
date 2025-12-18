/*  DUGL Dos Ultimate Game Library -  version 1.10+ */
/*  Real-time bluring and rendering on DUGL */
/*  History :
    2 march 2008 : first release */

#include <dos.h>
#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <unistd.h>
#include <bios.h>
#include <math.h>
#include <string.h>
#include <sys/movedata.h>
#include <sys/segments.h>
#include <dugl/dugl.h>
#include <dugl/duglplus.h>

typedef struct {
  int x,  // pos x
      y,  // pos y
      z;  // pos z
  int xt, // x inside the texture
      yt; // y inside the texture
  int RGB; // RGB VAlue
} PolyPt;

typedef struct {
  int NbPt;
  PolyPt *P1,*P2,*P3,*P4;
} QuadPoly;


int ScrResH = 640, ScrResV = 480;

#define MAX_FPOINT 100
F3DPoint ListFPt[MAX_FPOINT] =
{ { -150.0, -150.0 , 150.0, 0.0 },
  { -150.0,  150.0 , 150.0, 0.0 },
  {  50.0,  150.0 , 150.0, 0.0 },
  {  50.0, -150.0 , 150.0, 0.0 },

  { -150.0, -150.0 , -150.0, 0.0 },
  { -150.0,  150.0 , -150.0, 0.0 },
  {  150.0,  150.0 , -150.0, 0.0 },
  {  150.0, -150.0 , -150.0, 0.0 }
};

F3DPoint ListRFPt[MAX_FPOINT];

PolyPt ListObjPts[8]= {
  { 0, 0, 0,  30,   0, 0 },
  { 0, 0, 0,  80,   0, 0 },
  { 0, 0, 0,  80,  30, 0 },
  { 0, 0, 0,  30,  30, 0 },
  { 0, 0, 0,  80, 120, 0 },
  { 0, 0, 0, 120, 120, 0 },
  { 0, 0, 0, 120,  80, 0 },
  { 0, 0, 0,  80,  80, 0 }
};

QuadPoly ListObjPolys[8] = {
  { 4, &ListObjPts[0], &ListObjPts[1], &ListObjPts[2], &ListObjPts[3] },
  { 4, &ListObjPts[4], &ListObjPts[5], &ListObjPts[1], &ListObjPts[0] },
  { 4, &ListObjPts[5], &ListObjPts[6], &ListObjPts[2], &ListObjPts[1] },
  { 4, &ListObjPts[6], &ListObjPts[7], &ListObjPts[3], &ListObjPts[2] },
  { 4, &ListObjPts[7], &ListObjPts[4], &ListObjPts[0], &ListObjPts[3] },
  { 4, &ListObjPts[7], &ListObjPts[6], &ListObjPts[5], &ListObjPts[4] }

};


//RGB 16
PolyPt ListObjRGB[4]= {
  { 320, 0, 0,  0,   0, 0xffff },
  { 639, 479, 0,  80,   0, 0xffff },
  { 0, 479, 0,  80,  30, 0x0 },
  { 8, 150, 0,  80,  30, 0x0 }
};

QuadPoly ListObjPolysRGB[1] = {
  { 3, &ListObjRGB[0], &ListObjRGB[1], &ListObjRGB[2], &ListObjRGB[3] } };

int RotX=40,RotY=0,RotZ=0;
FMatrix MatTr;
void DGWaitRetrace();

// synch buffer
char SynchBuff[SIZE_SYNCH_BUFF];

FONT F1;

int i,j; // counters

Surf JpegIMG,convSurf16,rendSurf16;

int main(int argc,char *argv[])
{
   if (CreateSurf(&convSurf16,ScrResH,ScrResV,16)==0) {
     printf("no mem\n"); exit(-1); }
   if (CreateSurf(&rendSurf16,ScrResH,ScrResV,16)==0) {
     printf("no mem\n"); exit(-1); }

   // load GFX
   if (LoadBMP16(&JpegIMG,"player.bmp")==0) {
     printf("player.bmp not found or invalid\n"); exit(-1); }

   // load the font
   if (!LoadFONT(&F1,"hello.chr")) {
     printf("hello.chr not found\n"); exit(-1); }


   Init3DMath(); // init cos sin tables

   // init the lib
   if (!InitVesa())
   { printf("VESA error\n"); exit(-1); }


   // Inits
   if (!InstallTimer(500)) {
     CloseVesa(); printf("Timer error\n"); exit(-1);
   }
   if (!InstallKeyboard()) {
     CloseVesa(); UninstallTimer(); //UninstallMouse();
     printf("Keyboard error\n");  exit(-1);
   }

   // init the video mode
   if (!InitVesaMode(ScrResH,ScrResV,16,1))
       { UninstallTimer(); UninstallKeyboard();
         printf("VESA mode error\n"); exit(-1); }
         
   // set the used FONT
   SetFONT(&F1);
   
   Surf *pSurfRend=&rendSurf16,
        *pSurfBlur=&convSurf16,*pSurfTemp;

   int PosSynch;
   InitSynch(SynchBuff,&PosSynch,60);
   char text[100];
   text[0]=0;

   // start the main loop
   for (j=0;;j++) {
   
     FREE_MMX();
     // synchronise
     Synch(SynchBuff,NULL);
     // average time
     float avgFps=SynchAverageTime(SynchBuff),
           lastFps=SynchLastTime(SynchBuff);

     SetSurf(pSurfRend);
   
     // render a moving text
     ClearText(); // clear test position to upper left
     SetTextCol(0xff00);
     FntY=FntY-((RotX*3)&255);
     OutText16("Esc to Exit");


     // 3D **********
     // get transformation matrix
     FREE_MMX();
     GetGRotTransFMatrix(&MatTr, 0.0, 0.0, 700.0, RotX, RotY, RotZ);
     //ReverseFMatrix(&MatTr,&MatTr);
     // rotate points
     FMatrixRotTransF(&MatTr, (float *)ListFPt, (float *)ListRFPt, 8);
     // inc rot
     RotX+=1; RotY+=1; RotZ+=1;
     // copy rotated coordinate
     for (i=0;i<8;i++) {
       ListObjPts[i].x=(((int)ListRFPt[i].x)*(CurSurf.ResH/2))/((int)ListRFPt[i].z);
       ListObjPts[i].y=(((int)ListRFPt[i].y)*(CurSurf.ResV/2))/((int)ListRFPt[i].z);
     }
     // set origin to the center
     SetOrgSurf(&CurSurf,CurSurf.ResH/2,CurSurf.ResV/2);
     for (i=0;i<6;i++) {
        Poly16(&ListObjPolys[i], &JpegIMG, POLY16_TEXT, 0);
     }
     SetOrgSurf(&CurSurf,0,0);

     // END 3D *******

     // render a single RGB poly
     ListObjRGB[0].x = (rand()&255)+10;
     ListObjRGB[0].y = (rand()&255)+10;
     ListObjRGB[1].x = (rand()&255)+10;
     ListObjRGB[1].y = (rand()&255)+10;
     ListObjRGB[2].x = (rand()&255)+10;
     ListObjRGB[2].y = (rand()&255)+10;
       
     ListObjRGB[0].RGB=rand()&0xffff;
     ListObjRGB[1].RGB=rand()&0xffff;
     ListObjRGB[2].RGB=rand()&0xffff;
     ListObjRGB[3].RGB=rand()&0xffff;
     Poly16(&ListObjPolysRGB[0], NULL, POLY16_RGB|POLY16_FLAG_DBL_SIDED, rand());

     // blur
     BlurSurf16(pSurfBlur,&CurSurf);
     
     // display fps
     SetSurf(pSurfBlur);

     ClearText(); // clear test position to upper left
     SetTextCol(0x0);
     OutText16Mode(text,AJ_RIGHT); // clear last text with black
           
     FREE_MMX();

     ClearText(); // clear test position to upper left
     SetTextCol(0xffff);
     sprintf(text,"Last fps %03i, avg fps %03i, Esc to exit",
            (int)((lastFps>0.0)?(1.0/(lastFps)):-1),
            (int)((avgFps>0.0)?(1.0/(avgFps)):-1));
     OutText16Mode(text,AJ_RIGHT); // clear last text with black

     // display on the screen the result :)
     //SetSurf(&VSurf[0]);
     //DGWaitRetrace();
     SurfCopy(&VSurf[0],pSurfBlur);
     
//     PutSurf16(pSurfBlur,0,0,0);

     // exit if esc pressed
     if (BoutApp(0x1)) break;
     // swap rend and blur Surf
     pSurfTemp=pSurfRend;
     pSurfRend=pSurfBlur;
     pSurfBlur=pSurfTemp;
     
     // create a screenshot
     // tab + ctrl + shift
     if (BoutApp(0xf) && (KbFLAG&SHIFT_PR) && (KbFLAG&CTRL_PR))
       SaveBMP16(&VSurf[0],"realblur.bmp");
      
   }

   CloseVesa();
   UninstallKeyboard();
   UninstallTimer();
   TextMode();
   return 0;
}

// DUGL Util waitRetrace
void DGWaitRetrace() {
  //if (!SynchScreen) return;
  if (CurMode.VModeFlag|VMODE_VGA)
     WaitRetrace(); // VGA wait retrace
  else
     ViewSurfWaitVR(0);
}

