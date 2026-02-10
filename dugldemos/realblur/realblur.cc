/*  Real-time bluring and rendering on DUGL */
/*  History :
    2 march 2008 : first release
    10 february 2026: updates to synch with DUGL changes */

#include <stdio.h>
#include <stdlib.h>
#include <dugl.h>

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
DVEC4 ListFPt[MAX_FPOINT] =
{ { -150.0f, -150.0f , 150.0f, 0.0f },
  { -150.0f,  150.0f , 150.0f, 0.0f },
  {  50.0f,  150.0f , 150.0f, 0.0f },
  {  50.0f, -150.0f , 150.0f, 0.0f },

  { -150.0f, -150.0f , -150.0f, 0.0f },
  { -150.0f,  150.0f , -150.0f, 0.0f },
  {  150.0f,  150.0f , -150.0f, 0.0f },
  {  150.0f, -150.0f , -150.0f, 0.0f }
};

DVEC4 ListRFPt[MAX_FPOINT], ListProjFPt[MAX_FPOINT], ListCamProj[MAX_FPOINT];
DVEC2i ListPtFinal[MAX_FPOINT];


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
DMatrix4 MatTr;
void DGWaitRetrace();

// synch buffer
char SynchBuff[SIZE_SYNCH_BUFF];

DFONT F1;

int i,j; // counters

DgSurf *JpegIMG,*convSurf16,*rendSurf16;
bool bPaused = false, bExitApp = false, bBlur = true;

int main(int argc,char *argv[])
{

   // init the lib
   if (!DgInit())
   { printf("DUGL Init error\n"); exit(-1); }

   if (CreateSurf(&convSurf16,ScrResH,ScrResV,16)==0) {
     printf("no mem\n");
     DgQuit();
     exit(-1);
   }
   if (CreateSurf(&rendSurf16,ScrResH,ScrResV,16)==0) {
     printf("no mem\n");
     DgQuit();
     exit(-1);
   }
   // load GFX
   if (LoadBMP16(&JpegIMG,"player.bmp")==0) {
     printf("player.bmp not found or invalid\n");
     DgQuit();
     exit(-1);
   }

   // load the font
   if (!LoadDFONT(&F1,"hello.chr")) {
     printf("hello.chr not found\n");
     DgQuit();
     exit(-1);
   }

   // Inits
   if (!DgInstallTimer(500)) {
     DgQuit();
     printf("Timer error\n");
     exit(-1);
   }
   if (!InstallKeyboard()) {
     DgQuit(); DgUninstallTimer(); //UninstallMouse();
     printf("Keyboard error\n");  exit(-1);
   }

   // init the video mode
   if (!InitVesaMode(ScrResH,ScrResV,16,1)) {
        DgUninstallTimer();
        UninstallKeyboard();
        DgQuit();
        printf("VESA mode error\n");
        exit(-1);
   }

   // set the used FONT
   SetDFONT(&F1);

   DgSurf *pSurfRend=rendSurf16,
        *pSurfBlur=convSurf16,*pSurfTemp;

   int PosSynch;
   InitSynch(SynchBuff,&PosSynch,60);
   char text[128];
   text[0]=0;

   if (bBlur)
      DgSetCurSurf(pSurfRend);
   else
      DgSetCurSurf(&VSurf[0]);

   DMatrix4 m_matProject, matView, lookAtMat;

   DVEC4 m_eyePosition={0.0f, 0.0f,1000.0f, 0.0f};
   DVEC4 m_target={0.0f,10.0f,0.0f, 0.0f};
   DVEC4 m_up={0.0f, 1.0f, 0.0f, 0.0f};
   GetLookAtDMatrix4(&lookAtMat, &m_eyePosition, &m_target, &m_up);

   DgView m_3dView;
   GetSurfView(&CurSurf, &m_3dView);
   GetViewDMatrix4(&matView, &m_3dView, 0.0f, 1.0f, 0.0f, 1.0f);

   float m_fov = 60.0f, m_aspect = 1.33f, m_znear = 1.0f, m_zfar = 1000.0f; // frustum
   GetPerspectiveDMatrix4(&m_matProject, m_fov, m_aspect, m_znear, m_zfar);

   // start the main loop
   for (j=0;;j++) {

     // synchronise
     Synch(SynchBuff,&PosSynch);
     // average time
     float avgFps=SynchAverageTime(SynchBuff),
           lastFps=SynchLastTime(SynchBuff);

     if (bBlur)
        DgSetCurSurf(pSurfRend);
     else
        DgSetCurSurf(&VSurf[0]);


    // get key
    unsigned char keyCode;
    unsigned int keyFLAG;

    GetKey(&keyCode, &keyFLAG);
    switch (keyCode) {
    case KB_KEY_SPACE :
        bPaused=!bPaused;
        break;
    case KB_KEY_F2 :
        bBlur=!bBlur;
        break;
    case KB_KEY_ESC:
        bExitApp = true;
        break;
    case KB_KEY_TAB:
     // create a screenshot
     // tab + ctrl + shift
        if (IsKeyDown(KB_KEY_TAB) && (keyFLAG&KB_SHIFT_PR) && (keyFLAG&KB_CTRL_PR))
            SaveBMP16(&VSurf[0],"realblur.bmp");
        break;

    }

     // render a moving text
     ClearText(); // clear test position to upper left
     SetTextCol(0xff00);
     FntY=FntY-((RotX*3)&255);
     OutText16("Esc: Exit, Space: Pause, F2:Toggle Blur");

     ClearText(); // clear test position to upper left
     SetTextCol(0xffff);

     sprintf(text,"Last fps %03i, avg fps %03i, Esc to exit",
            (int)((lastFps>0.0)?(1.0/(lastFps)):-1),
            (int)((avgFps>0.0)?(1.0/(avgFps)):-1));
     int Xtext=GetXOutTextMode(text,AJ_RIGHT);
     int Ytext=FntY+FntLowPos-1;
     int widthText=WidthText(text);
     //barblnd16(Xtext,Ytext,Xtext+WidthText,Ytext+FntHaut,0|(5<<24));
     bar16(Xtext,Ytext,Xtext+widthText,Ytext+FntHaut,0);

     OutText16Mode(text,AJ_RIGHT); // clear last text with black

     // exit if esc pressed
     if (bExitApp) break;
     // do nothing if paused
     if (bPaused) continue;

     // 3D **********
     // get cube transformation matrix
     GetRotDMatrix4(&MatTr, RotX, RotY, RotZ);
     // transform
     // rotate/move the cube
     DMatrix4MulDVEC4ArrayRes(&MatTr, ListFPt, 8, ListRFPt);
     // rotate/move according to camera position/orientation
     DMatrix4MulDVEC4ArrayRes(&lookAtMat, ListRFPt, 8, ListCamProj);
     // project into camera plane (x and y) [-1.0 to 1.0]
     DMatrix4MulDVEC4ArrayPerspRes(&m_matProject, ListCamProj, 8, ListProjFPt);
     // projection to screen coordinates/pixels
     DMatrix4MulDVEC4ArrayResDVec2i(&matView, ListProjFPt, 8, ListPtFinal);

     // inc rot
     RotX+=1; RotY+=1; RotZ+=1;
     // copy rotated coordinate
     for (i=0;i<8;i++) {
        ListObjPts[i].x=ListPtFinal[i].x;
        ListObjPts[i].y=ListPtFinal[i].y;
     }
     // set origin to the center
     SetOrgSurf(&CurSurf,CurSurf.ResH/2,CurSurf.ResV/2);
     for (i=0;i<6;i++) {
        Poly16(&ListObjPolys[i], JpegIMG, POLY16_MASK_TEXT_TRANS | POLY16_FLAG_DBL_SIDED, 18);
        if (i==5)
            REPOLY16(NULL, NULL, POLY16_SOLID_BLND, RGB16(255,255,255) | (3<<24));
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

     if (bBlur)
     {
         // blur
         BlurSurf16(pSurfBlur,&CurSurf);

         // display fps
         DgSetCurSurf(pSurfBlur);

         ClearText(); // clear test position to upper left
         SetTextCol(0x0);
         OutText16Mode(text,AJ_RIGHT); // clear last text with black

         // display on the screen the result :)
         //SetSurf(&VSurf[0]);
         //DGWaitRetrace();
         SurfCopy(&VSurf[0],pSurfBlur);
        // swap rend and blur Surf

         pSurfTemp=pSurfRend;
         pSurfRend=pSurfBlur;
         pSurfBlur=pSurfTemp;

     }

//     PutSurf16(pSurfBlur,0,0,0);



   }

   DgQuit();
   UninstallKeyboard();
   DgUninstallTimer();
   TextMode();
   return 0;
}

// DUGL Util waitRetrace
void DGWaitRetrace() {
  //if (!SynchScreen) return;
  if (CurDgfxMode->VModeFlag|VMODE_VGA)
     WaitRetrace(); // VGA wait retrace
  else
     ViewSurfWaitVR(0);
}

