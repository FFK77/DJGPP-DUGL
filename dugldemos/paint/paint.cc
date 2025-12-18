/*  DUGL Dos Ultimate Game Library - Paint Sample */
/*  demonstrate how to use the Mouse Events StackL */
/*  History : */
/*  Apr 2007 : first release */


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

typedef struct {
  int x,  // pos x
      y,  // pos y
      z;  // pos z
  int xt, // x inside the texture
      yt; // y inside the texture
  int light; // 0 to 63 light value : 0 black .. 63 white
} PolyPt;

typedef struct {
  int NbPt;
  PolyPt *P1,*P2,*P3,*P4;
} QuadPoly;

#define MAX_POINTS 5
#define MAX_POLYS  2
int NbPolys = 0, NbPts = 0;
int ShowGrid = 1;
int GridNbCols=10,GridNbRows=10;
PolyPt ListPts[4];
QuadPoly ListPolys[MAX_POLYS];


FILE *Pal;
FONT F1;
unsigned char Pal3d[1024], // used palette
              palette[1024]; // where to store sprites loaded palette
unsigned char rouge,bleu,jaune,noir,blanc; // index of needed colors

int ScrResH = 640, ScrResV = 480;
int i,j; // counters

// used view *******
View GridView = { 0,0,ScrResH-40,ScrResV-30,40,50 },
     TextView = { 0,0,ScrResH-1,39,0,0 },
     AllView = { 0,0,ScrResH-1,ScrResV-1,0,0 };
     
// *** memory suface of the Sprites ****************************
Surf MsPtr;  // mouse pointer

// *** Paint
Surf PaintImg; // image to apply lights over
int PaintResHz=600,PaintResVt=400,PaintX=20,PaintY=70;

// *** memory surf rendering
Surf rendSurf;
int toggleMemRender = 1;

// synch buffer
char SynchBuff[SIZE_SYNCH_BUFF];


int main(int argc,char *argv[])
{       // init the lib
        if (!InitVesa())
	  { printf("VESA error\n"); exit(-1); }
        // load GFX
	if (!LoadGIF(&MsPtr,"mouseimg.gif",&palette))
	  { printf("msptr.gif error\n"); exit(-1); }

	rouge=PrFindCol(0,255,0,0,255,&palette,0.2); // red
	jaune=PrFindCol(0,255,0,255,0,&palette,0.2); // yellow
	bleu=PrFindCol(0,255,255,0,0,&palette,0.2); // blue
	noir=PrFindCol(0,255,0,0,0,&palette,0.2); // black
	blanc=PrFindCol(0,255,255,255,255,&palette,0.2);  // white
        // paint surface
        if (!CreateSurf(&PaintImg, PaintResHz,PaintResVt,8)) {
           CloseVesa(); UninstallTimer(); UninstallKeyboard();
           printf("no mem\n"); exit(-1);
        }
        SetSurf(&PaintImg); // current painting
        Clear(bleu);
        
        // load the font
	if (!LoadFONT(&F1,"hello.chr")) {
	  printf("hello.chr not found\n"); exit(-1); }

        // Inits
	if (!InstallMouse()) {
           CloseVesa(); printf("Mouse error\n"); exit(-1);
        }
        EnableMsEvntsStack();
	if (!InstallTimer(300)) {
           UninstallMouse(); CloseVesa(); printf("Timer error\n"); exit(-1);
        }
	if (!InstallKeyboard()) {
           CloseVesa(); UninstallTimer(); UninstallMouse();
	   printf("Keyboard error\n");  exit(-1);
        }

        // create mem Surf
        if (!CreateSurf(&rendSurf, ScrResH,ScrResV,8)) {
           CloseVesa(); UninstallTimer(); UninstallKeyboard();
           printf("no mem\n"); exit(-1);
        }
        // init the video mode with 3 video pages
        if (!InitVesaMode(ScrResH,ScrResV,8,3))
          { UninstallTimer(); UninstallKeyboard();
            printf("VESA mode error\n"); exit(-1); }

        SetSurf(&VSurf[0]);
        ViewSurfWaitVR(0);
        // set the used FONT
        SetFONT(&F1);

        // set the used palette
        SetPalette(0,256,&palette);
        // build the light table of each color
	PrBuildTbDegCol(&palette,0.6);
        // mouse init
        // change the origin of the surf of the mouse pointer
        View MsView;
        SetOrgSurf(&MsPtr,0,MsPtr.ResV-1);
        GetSurfRView(&VSurf[0],&MsView);
        SetMouseRView(&MsView);

        int PosSynch;
        InitSynch(SynchBuff,&PosSynch,CurModeVtFreq);
        // start the main loop
        for (j=0;;j++) {
           // synchronise
           Synch(SynchBuff,NULL);
           // average time
           float avgFps=SynchAverageTime(SynchBuff),
                 lastFps=SynchLastTime(SynchBuff);
           // set the index of the visible video surf
           // wait retrace if fps is greater than the screen refresh /*(1.0/avgFps)>=CurModeVtFreq*/
	   if (lastFps==0.0 || (1.0/lastFps)>=CurModeVtFreq)
           {
              // use VGA registers if available (better compatiblity)
              if (CurMode.VModeFlag|VMODE_VGA) {
                ViewSurf(j%3);//ViewSurf(0);
	        WaitRetrace(); // VGA wait retrace
              }
              else
                ViewSurfWaitVR(j%3);//ViewSurfWaitVR(0);
           }
           else
             ViewSurf(j%3);//ViewSurf(0);

           // handle the paint Suface with mouse events ****************
           SetSurf(&PaintImg); // current painting
           
           MouseEvent MsEvt;
           for (;GetMsEvent(&MsEvt);) {
             // draw a mouse pointer if the mouse left butt pressed
             if (MsEvt.MsButton&MS_LEFT_BUTT) {
                PutMaskSurf(&MsPtr,MsEvt.MsX-PaintX,MsEvt.MsY-PaintY,0);
             }
             // draw a POLY_EFF_DEG darker if the mouse left butt pressed
             if (MsEvt.MsButton&MS_RIGHT_BUTT) {
               // point 0
               ListPts[0].x=MsEvt.MsX-PaintX;
               ListPts[0].y=MsEvt.MsY-PaintY;
               ListPts[0].light=20; // go a little darker
               // point 1
               ListPts[1].x=MsEvt.MsX-PaintX+10;
               ListPts[1].y=MsEvt.MsY-PaintY;
               ListPts[1].light=20; // go a little darker
               // point 2
               ListPts[2].x=MsEvt.MsX-PaintX+10;
               ListPts[2].y=MsEvt.MsY-PaintY+10;
               ListPts[2].light=20; // go a little darker
               // point 3
               ListPts[3].x=MsEvt.MsX-PaintX;
               ListPts[3].y=MsEvt.MsY-PaintY+10;
               ListPts[3].light=20; // go a little darker
               // poly
               ListPolys[0].NbPt=4;
               ListPolys[0].P1=&ListPts[0];
               ListPolys[0].P2=&ListPts[1];
               ListPolys[0].P3=&ListPts[2];
               ListPolys[0].P4=&ListPts[3];
               // draw
               Poly(&ListPolys[0], NULL, POLY_EFF_DEG, 0);
             }
           }

           // end painting **********************************************

           // set the current active surface for drawing
           if (!toggleMemRender)
	     SetSurf(&VSurf[(j+1)%3]);//SetSurf(&VSurf[0]);
           else
             SetSurf(&rendSurf);

           // clear all the current Surf, does not care of any view
           Clear(noir); // clear with black
           // create a screenshot
           // tab + ctrl + shift
           if (BoutApp(0xf) && (KbFLAG&SHIFT_PR) && (KbFLAG&CTRL_PR))
              SavePCX(&VSurf[j%3],"paint.pcx",&palette);

           // draw the paint surf
           PutSurf(&PaintImg,PaintX,PaintY,0);
           // draw a black and white rects around
           rect(PaintX-1,PaintY-1,PaintX+PaintResHz,PaintY+PaintResVt,noir);
           rect(PaintX-2,PaintY-2,PaintX+PaintResHz+1,PaintY+PaintResVt+1,blanc);

           // set the view of the sprites for the current drawing surf
           SetSurfRView(&CurSurf, &GridView);
           
           // display text
           SetSurfRView(&CurSurf, &TextView);
           ClearText(); // clear test position to upper left
           SetTextCol(blanc);
           char text[100];
           FREE_MMX();
           sprintf(text,"fps %03i, screen refresh %03i",(int)((avgFps>0.0)?(1.0/(avgFps)):-1),CurModeVtFreq);
           OutTextMode(text,AJ_MID);
           if (toggleMemRender)
              OutTextMode("RAM rendering\n",AJ_RIGHT);
           else
              OutTextMode("VRAM rendering\n",AJ_RIGHT);
           OutTextMode("F1 VRAM render|F2 RAM render|F3 save IMG.PCX|DEL clear Screen|Esc exit",AJ_RIGHT);
           // set a full view to draw the mouse pointer
           SetSurfRView(&CurSurf, &AllView);
           // render mouse cursor
           PutMaskSurf(&MsPtr,MsX,MsY,0);
           
           // if memory rendering toggled, then copy the mem surf to vmem
           if (toggleMemRender) {
             SetSurf(&VSurf[(j+1)%3]);
             SetSurfRView(&CurSurf, &AllView);
             PutSurf(&rendSurf,0,0,NORM_PUT);
           }
           unsigned char keyCode;
           unsigned int keyFLAG;
           GetKey(&keyCode,&keyFLAG);
           switch (keyCode) {
              case 0x3d : // F3 save IMG.PCX
                SavePCX(&PaintImg,"IMG.PCX",&palette);
                break;
              case 0xd3 : // extended del
              case 0x53 : // "NumPad" Del
                SetSurf(&PaintImg); // current painting
                Clear(bleu);
                break;
           }
           // if F1 pressed 0x3b toggle VRAM rendering
           if (BoutApp(0x3b)) toggleMemRender=0;
           // if F2 pressed 0x3c toggle memory rendering
           if (BoutApp(0x3c)) toggleMemRender=1;
           // exit if esc pressed
           if (BoutApp(0x1)) break;
        }
        DestroySurf(&rendSurf);
        CloseVesa();

        UninstallKeyboard();
        UninstallMouse();
        UninstallTimer();
        TextMode();
        return 0;
}



