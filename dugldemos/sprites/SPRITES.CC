/*  DUGL Dos Ultimate Game Library - Sprites Sample */
/*  History : */
/*  3 september 2006 : first release */
/*  mars 2007 : better fps calculation */

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
      xspeed; // delta x
  int type; // 0 the man, 1 the cat, the ball of the cat
} mySprite;

#define MAX_SPRITES  5000
int NbSprites = 0;
mySprite Sprites[MAX_SPRITES];

FILE *Pal;
FONT F1;
unsigned char Pal3d[1024], // used palette
              palette[1024]; // where to store sprites loaded palette
unsigned char rouge,bleu,jaune,noir,blanc; // index of needed colors

int ScrResH = 640, ScrResV = 480;
int i,j; // counters

// used view *******
View SpritesView = { 0,0,ScrResH-1,ScrResV-1,0,40 },
     TextView = { 0,0,ScrResH-1,39,0,0 },
     AllView = { 0,0,ScrResH-1,ScrResV-1,0,0 };

// *** memory suface of the Sprites ****************************
Surf *ana1,  // sprites of the man
     *chat1, // cat
     *balleChat1;  // ball of the cat
// *** memory surf rendering
Surf *rendSurf;
int toggleMemRender = 1;
// synch buffer - to compute fps
char SynchBuff[SIZE_SYNCH_BUFF];

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
        // load GFX the 3 Sprites
	if (!LoadGIF(&ana1,"moi.gif",&palette))
	  { printf("ana.gif error\n"); exit(-1); }
	if (!LoadGIF(&chat1,"chat1.gif",&palette))
	  { printf("chat1.gif error\n"); exit(-1); }
	if (!LoadGIF(&balleChat1,"balchat1.gif",&palette))
	  { printf("balchat1.gif error\n"); exit(-1); }
        // find the colors
	rouge=PrFindCol(0,255,0,0,255,&Pal3d,0.2); // red
	jaune=PrFindCol(0,255,0,255,0,&Pal3d,0.2); // yellow
	bleu=PrFindCol(0,255,255,0,0,&Pal3d,0.2); // blue
	noir=PrFindCol(0,255,0,0,0,&Pal3d,0.2); // black
	blanc=PrFindCol(0,255,255,255,255,&Pal3d,0.2);  // white
        // load the font
	if (!LoadFONT(&F1,"hello.chr")) {
	  printf("hello.chr introuvable\n"); exit(-1); }

	if (!DgInstallTimer(300))
	  { CloseVesa(); printf("Timer error\n"); exit(-1); }
	if (!InstallKeyboard()) {
        CloseVesa(); DgUninstallTimer(); UninstallMouse();
	    printf("Keyboard error\n");  exit(-1); }

    // create mem Surf
    if (!CreateSurf(&rendSurf, ScrResH,ScrResV,8)) {
       CloseVesa(); DgUninstallTimer(); UninstallKeyboard();
	   printf("no mem\n"); exit(-1);
    }
        // init the video mode with 3 video pages
	if (!InitVesaMode(ScrResH,ScrResV,8,3)) {
        DgUninstallTimer(); UninstallKeyboard();
	    printf("VESA mode error\n"); exit(-1);
    }


	SetPalette(0,256,&Pal3d);

    InitSynch(SynchBuff,NULL,60);

	SetFONT(&F1);
        unsigned int OldTime = DgTime;
        NbSprites = 0;
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
	   if (lastFps==0.0 || (1.0/lastFps)>=CurModeVtFreq) {
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
            SetSurf(&VSurf[(j+1)%3]);
        else
             SetSurf(rendSurf);

        // clear all the current Surf, does not care of any view
        Clear(noir); // clear with black
       // create a screenshot
       // tab + ctrl + shift
       if (IsKeyDown(0xf) && (KbFLAG&KB_SHIFT_PR) && (KbFLAG&KB_CTRL_PR))
          SavePCX(&VSurf[j%3],"sprites.pcx",&Pal3d);
       // set the view of the sprites for the current drawing surf
       SetSurfView(&CurSurf, &SpritesView);
       // add a new sprite if we have not reached the max
       if (NbSprites < MAX_SPRITES) {
          Sprites[NbSprites].x = 0;
          Sprites[NbSprites].y = random()%300+20;
          Sprites[NbSprites].xspeed = random()%10;
          Sprites[NbSprites].type = random()%3;
          NbSprites++; // increase the number of sprites
       }
       // draw all the available sprites
       for (i=0;i< NbSprites;i++) {
             Surf *mySprite = NULL;
             int SpriteDType = INV_HZ_PUT;
             // who is our sprite ?
             switch  (Sprites[i].type) {
               case 0 : mySprite = ana1; break;
               case 1 : mySprite = chat1; break;
               case 2 : mySprite = balleChat1;
             };
             // the sprite will be draw inversed horizontally if going back
             if (Sprites[i].xspeed<0) SpriteDType = NORM_PUT;
             if (mySprite!=NULL)
               PutMaskSurf(mySprite,Sprites[i].x,Sprites[i].y,SpriteDType);
        }
       // increase pos of the sprites
       for (i=0;i< NbSprites;i++) {
         Sprites[i].x+=Sprites[i].xspeed;
         if (Sprites[i].x>=CurSurf.MaxX || Sprites[i].x<=CurSurf.MinX)
           Sprites[i].xspeed = -Sprites[i].xspeed;
       }
        // display text
        SetSurfView(&CurSurf, &TextView);
        ClearText(); // clear test position to upper left
        SetTextCol(blanc);
        char text[100];

        FREE_MMX();
        sprintf(text,"Sprites %04i, fps %03i, screen refresh %03iHz",NbSprites,
              (int)((avgFps>0.0)?(1.0/(avgFps)):-1),CurModeVtFreq);
        OutTextMode(text,AJ_MID);
        if (toggleMemRender)
            OutTextMode("RAM rendering\n",AJ_RIGHT);
        else
            OutTextMode("VRAM rendering\n",AJ_RIGHT);
        OutTextMode("(F1 VRAM render)(F2 RAM render)(Esc to exit)",AJ_RIGHT);

           // if memory rendering toggled, then copy the mem surf to vmem
        if (toggleMemRender) {
            SetSurf(&VSurf[(j+1)%3]);
            SetSurfView(&CurSurf, &AllView);
            PutSurf(rendSurf,0,0,NORM_PUT);
        }
           // if F1 pressed 0x3b toggle VRAM rendering
           if (IsKeyDown(KB_KEY_F1)) toggleMemRender=0;
           // if F2 pressed 0x3c toggle memory rendering
           if (IsKeyDown(KB_KEY_F1)) toggleMemRender=1;
           // exit if esc pressed
           if (IsKeyDown(KB_KEY_ESC)) break;
        }

	CloseVesa();
	UninstallKeyboard();
	DgUninstallTimer();
    TextMode();
    return 0;
}


