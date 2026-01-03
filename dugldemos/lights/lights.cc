/*  DUGL Dos Ultimate Game Library - lights Sample */
/*  demonstrate how to draw polygones on DUGL */
/*  History : */
/*  6 september 2006 : first release */
/*  nov 2006 : corrected a bug computing light matrice */
/*  mar 2007 : better fps computing */

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
#include <dugl.h>

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

#define MAX_POINTS 2500
#define MAX_POLYS  2000
int NbPolys = 0, NbPts = 0;
int ShowGrid = 1;
int GridNbCols=10,GridNbRows=10;
PolyPt ListPts[MAX_POINTS*2];
QuadPoly ListPolys[MAX_POLYS*2];


FILE *Pal;
FONT F1;
unsigned char Pal3d[1024], // used palette
              palette[1024]; // where to store sprites loaded palette
unsigned char rouge,bleu,jaune,noir,blanc; // index of needed colors

int ScrResH = 640, ScrResV = 480;
//int ScrResH = 1280, ScrResV = 1024;
int i,j; // counters

// used view *******
View GridView = { 0,0,ScrResH-40,ScrResV-30,40,50 },
     TextView = { 0,0,ScrResH-1,39,0,0 },
     AllView = { 0,0,ScrResH-1,ScrResV-1,0,0 };

// *** memory suface of the Sprites ****************************
Surf MsPtr,  // mouse pointer
     LightImg; // image to apply lights over

// *** memory surf rendering
Surf rendSurf;
int toggleMemRender = 1;

// synch buffer
char SynchBuff[SIZE_SYNCH_BUFF];

// proc and function
void BuildPtsPolys(); // fill table of points and and polys
void DrawGrid(); // draw the poly grid

int main(int argc,char *argv[])
{       // init the lib
        if (!InitVesa())
	  { printf("VESA error\n"); exit(-1); }
        // load the sound driver
        // load the BGRA 256 color palette
	if ((Pal=fopen("3dpal.pal","rb"))==NULL) {
	  printf("3dpal.pal error\n"); exit(-1); }
	fread(&Pal3d,1024,1,Pal);
	fclose(Pal);
        // load GFX
	if (!LoadGIF(&MsPtr,"mouseimg.gif",&palette))
	  { printf("msptr.gif error\n"); exit(-1); }
	if (!LoadGIF(&LightImg,"jeux1.gif",&palette))
	  { printf("jeux1.gif error\n"); exit(-1); }

	rouge=PrFindCol(0,255,0,0,255,&palette,0.2); // red
	jaune=PrFindCol(0,255,0,255,0,&palette,0.2); // yellow
	bleu=PrFindCol(0,255,255,0,0,&palette,0.2); // blue
	noir=PrFindCol(0,255,0,0,0,&palette,0.2); // black
	blanc=PrFindCol(0,255,255,255,255,&palette,0.2);  // white
        // load the font
	if (!LoadFONT(&F1,"hello.chr")) {
	  printf("hello.chr not found\n"); exit(-1); }

        // Inits
	if (!InstallMouse()) {
           CloseVesa(); printf("Mouse error\n"); exit(-1);
        }
	if (!DgInstallTimer(300)) {
           UninstallMouse(); CloseVesa(); printf("Timer error\n"); exit(-1);
        }
	if (!InstallKeyboard()) {
           CloseVesa(); DgUninstallTimer(); UninstallMouse();
	   printf("Keyboard error\n");  exit(-1);
        }

        // create mem Surf
        if (!CreateSurf(&rendSurf, ScrResH,ScrResV,8)) {
           CloseVesa(); DgUninstallTimer(); UninstallKeyboard();
           printf("no mem\n"); exit(-1);
        }
        // init the video mode with 3 video pages
        if (!InitVesaMode(ScrResH,ScrResV,8,3))
          { DgUninstallTimer(); UninstallKeyboard();
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
        GetSurfView(&VSurf[0],&MsView);
        SetMouseView(&MsView);

        int PosSynch;
        InitSynch(SynchBuff,&PosSynch,CurModeVtFreq);
        // start the main loop
        for (j=0;;j++) {
           FREE_MMX();
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


           // set the current active surface for drawing
           if (!toggleMemRender)
            SetSurf(&VSurf[(j+1)%3]);//SetSurf(&VSurf[0]);
           else
             SetSurf(&rendSurf);

           // clear all the current Surf, does not care of any view
           Clear(noir); // clear with black
           // create a screenshot
           // tab + ctrl + shift
           if (IsKeyDown(KB_KEY_TAB) && (KbFLAG&KB_SHIFT_PR) && (KbFLAG&KB_CTRL_PR))
//              SavePCX(&VSurf[j%3],"lights.pcx",&Pal3d);
              SaveBMP(&VSurf[j%3],"lights.bmp",&palette);

           // set the view of the sprites for the current drawing surf
           SetSurfView(&CurSurf, &GridView);

           // build points, polygones and compute lightening of each point
           BuildPtsPolys();

           // draw lighted polygones
           for (i=0;i<NbPolys;i++)
              Poly(&ListPolys[i], &LightImg, POLY_DEG_TEXT, rouge);
           // draw the grid
           if (ShowGrid) DrawGrid();
           // display text
           SetSurfView(&CurSurf, &TextView);
           ClearText(); // clear test position to upper left
           SetTextCol(blanc);
           char text[100];

           FREE_MMX();
           sprintf(text,"igrid size %02ix%02i, fps %03i, screen refresh %03i",GridNbCols,
             GridNbRows,(int)((avgFps>0.0)?(1.0/(avgFps)):-1),CurModeVtFreq);
           OutTextMode(text,AJ_MID);
           if (toggleMemRender)
              OutTextMode("RAM rendering\n",AJ_RIGHT);
           else
              OutTextMode("VRAM rendering\n",AJ_RIGHT);
           OutTextMode("space show/hide grid|F1 VRAM render|F2 RAM render|NumPad +/- grid size|Esc exit",AJ_RIGHT);
           // set a full view to draw the mouse pointer
           SetSurfView(&CurSurf, &AllView);
           PutMaskSurf(&MsPtr,MsX,MsY,0);

           // if memory rendering toggled, then copy the mem surf to vmem
           if (toggleMemRender) {
             SetSurf(&VSurf[(j+1)%3]);
             SetSurfView(&CurSurf, &AllView);
             PutSurf(&rendSurf,0,0,NORM_PUT);
           }
           unsigned char keyCode;
           unsigned int keyFLAG;
           GetKey(&keyCode,&keyFLAG);
           switch (keyCode) {
              case 0x39 : // 0x39 space pressed (hide or show) grid
                ShowGrid = (ShowGrid)?0:1;
                break;
              case 0x4a : // 0x4a "NumPad -" grid size -
                if (GridNbCols>5) {
                   GridNbCols=GridNbCols/2;
                   GridNbRows=GridNbRows/2;
                }
                break;
              case 0x4e : // 0x4e "NumPad +" grid size +
                if (GridNbCols<40) {
                   GridNbCols=GridNbCols*2;
                   GridNbRows=GridNbRows*2;
                }
                break;
           }
           // if F1 pressed 0x3b toggle VRAM rendering
           if (IsKeyDown(0x3b)) toggleMemRender=0;
           // if F2 pressed 0x3c toggle memory rendering
           if (IsKeyDown(0x3c)) toggleMemRender=1;
           // exit if esc pressed
           if (IsKeyDown(0x1)) break;
        }
        DestroySurf(&rendSurf);
        CloseVesa();

        UninstallKeyboard();
        UninstallMouse();
        DgUninstallTimer();
        TextMode();
        return 0;
}

// fill table of points and and polys
void BuildPtsPolys() {
     int countcol, xstep, xtstep;
     int countrow, ystep, ytstep;
     int idx;

     FREE_MMX();
     if (GridNbCols>1 && GridNbRows>1) {
        xstep = (CurSurf.MaxX - CurSurf.MinX)/GridNbCols;
        ystep = (CurSurf.MaxY - CurSurf.MinY)/GridNbRows;
        xtstep = (LightImg.MaxX - LightImg.MinX)/GridNbCols;
        ytstep = (LightImg.MaxY - LightImg.MinY)/GridNbRows;

        // build points
        //NbPts = 0;
        for (countrow=0;countrow<GridNbRows+1;countrow++) {
           for (countcol=0;countcol<GridNbCols+1;countcol++) {
              idx=countrow*(GridNbCols+1)+countcol;
              //idx=NbPts;
              ListPts[idx].x = CurSurf.MinX+countcol*xstep;
              ListPts[idx].y = CurSurf.MinY+countrow*ystep;
              ListPts[idx].xt = LightImg.MinX+countcol*xtstep;
              ListPts[idx].yt = LightImg.MinY+countrow*ytstep;
              ListPts[idx].light = 0;
              //NbPts++;
           }
        }
        // build polygones
        NbPolys = 0;
        for (countrow=0;countrow<GridNbRows;countrow++) {
           for (countcol=0;countcol<GridNbCols;countcol++) {
              idx=countrow*(GridNbCols+1)+countcol;
              ListPolys[NbPolys].NbPt = 4;
              ListPolys[NbPolys].P1 = &ListPts[idx];
              ListPolys[NbPolys].P2 = &ListPts[idx+1];
              ListPolys[NbPolys].P3 = &ListPts[idx+GridNbCols+1+1];
              ListPolys[NbPolys].P4 = &ListPts[idx+GridNbCols+1];
              NbPolys++;
           }
        }
        int lightDist=100*100;
        // calc lights
        int dist;
        for (countrow=0;countrow<GridNbRows+1;countrow++) {
           for (countcol=0;countcol<GridNbCols+1;countcol++) {
              idx=countrow*(GridNbCols+1)+countcol;
              dist = (MsX-ListPts[idx].x)*(MsX-ListPts[idx].x)+
                abs(MsY-ListPts[idx].y)*abs(MsY-ListPts[idx].y);
              if (dist>=lightDist)
                //ListPts[idx].light= 3;
                ListPts[idx].light= 1;
              else
                ListPts[idx].light=(int)(30.0-((float)(dist)/(float)(lightDist))*30.0)+1;
           }
        }
     }
}

void DrawGrid() {
     // draw the grid
     linemap(CurSurf.MinX,CurSurf.MinY,CurSurf.MinX,CurSurf.MaxY,blanc,0xf0f0f0f0);
     linemap(CurSurf.MinX,CurSurf.MaxY,CurSurf.MaxX,CurSurf.MaxY,blanc,0xf0f0f0f0);
     linemap(CurSurf.MaxX,CurSurf.MaxY,CurSurf.MaxX,CurSurf.MinY,blanc,0xf0f0f0f0);
     linemap(CurSurf.MaxX,CurSurf.MinY,CurSurf.MinX,CurSurf.MinY,blanc,0xf0f0f0f0);
     // cut the rect into columns
     int countcol, xstep;
     if (GridNbCols>1) {
        xstep = (CurSurf.MaxX - CurSurf.MinX)/GridNbCols;
        for (countcol=1;countcol<GridNbCols;countcol++)
           linemap(CurSurf.MinX+countcol*xstep,CurSurf.MinY,
              CurSurf.MinX+countcol*xstep,CurSurf.MaxY,blanc,0xf0f0f0f0);
     }
     // cut the rect into rows
     int countrow, ystep;
     if (GridNbRows>1) {
        ystep = (CurSurf.MaxY - CurSurf.MinY)/GridNbRows;
        for (countrow=1;countrow<GridNbRows;countrow++)
           linemap(CurSurf.MinX,CurSurf.MinY+countrow*ystep,
              CurSurf.MaxX,CurSurf.MinY+countrow*ystep,blanc,0xf0f0f0f0);
     }
}


