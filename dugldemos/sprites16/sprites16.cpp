/*  Dust Ultimate Game Library (DUGL) - (C) 2025 Fakhri Feki */
/*  Sprites Sample */
/*  old History : DUGL DOS/DJGPP */
/*  3 september 2006 : first release */
/*  March 2007 : better fps calculation */
/*  History: */
/*  11 February 2023: First port */
/*  12 February 2023: Few optimizations - First demonstration of DUGL Multi Cores rendering by splitting screen */
/*     into left and right view and setting a DWorker to render each view, boosting fps by ~50% */
/*  24 February 2023: Adds quad core rendering capability - Fix bug of zero speed sprites */
/*  25 February 2023: Update Quad core rendering to use the new GetDGCORE function,
       use RenderContext to reduce rendering worker functions to only one function */
/*  2 March 2023: Detect/handle window close request */
/*  3 March 2023: More efficient render DWorker(s) allocation, by allocating only 1 DWorker for dual cores, and 3 DWorkers for quad cores rendering */
/*     and using the main thread as the last DWorker for a better usage of CPU cores and avoiding the overhead of waking-up a DWorker, */
/*     this boosted quad cores rendering performance by up to 30% on QuadCore CPU */
/* 18 April 2023: Add screenshot capability */
/* 17 June 2023: Add capability of switching to any of the 6 possible Put functions (PUT, MASK PUT, COL BLND PUT, MASK COL BLND PUT, TRANSP PUT and MASK TRANSP PUT */
/* 21 January 2026: back ported to DJGPP-DUGL removing some unsupported functions mainly DWOrker/multi-cores rendering */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <DUGL.h>

typedef struct {
    int     x,  // pos x
            y,  // pos y
            xspeed; // delta x
    Surf    *sprite;
} mySprite;

#define MAX_SPRITES  10000
int NbSprites = 0;
mySprite Sprites[MAX_SPRITES];

DFONT F1;
unsigned char rouge,bleu,jaune,noir,blanc; // index of needed colors
//int ScrResH = 640, ScrResV = 480;
int ScrResH = 800, ScrResV = 600;
//int ScrResH = 1024, ScrResV = 768;

// app controle
bool ExitApp = false;
bool dualCoreRender = false;
bool quadCoreRender = false;
bool PauseMove = false;
bool takeScreenShot=false;
int PutFuncIdx = 5; // MASK_PUT
char *PutFuncNames[] = { "PUT", "MASK_PUT", "COL_BLND_PUT", "COL_BLND_MASK_PUT", "TRANSP_PUT", "TRANSP_MASK_PUT" };
// used view *******
int TextViewHeight = 50;
int rendViewHeight = ScrResV - TextViewHeight;
View SpritesView = { 0,0,ScrResH-1,ScrResV-1,0,TextViewHeight },
// utils view
TextView = { 0,0,ScrResH-1,49,0,0 },
AllView = { 0,0,ScrResH-1,ScrResV-1,0,0 };

// render all View, no dworker
void RenderAllView();
Surf *rendSurf = NULL;

// *** memory suface of the Sprites ****************************
Surf *sprites[3];
// *** memory surf rendering
int toggleMemRender = 1;
// synch buffer - to compute fps
char SynchBuff[SIZE_SYNCH_BUFF];


int main(int argc,char *argv[]) {
    // init the lib
    if (!InitVesa())
      { printf("DUGL init error\n"); exit(-1); }

    // load GFX the 3 Sprites
    if (!LoadGIF16(&sprites[0],"man1.GIF")) {
        printf("man1.gif error\n");
        exit(-1);
    }
    if (!LoadGIF16(&sprites[1],"cat1.GIF")) {
        printf("cat1.gif error\n");
        exit(-1);
    }
    if (!LoadGIF16(&sprites[2],"balcat1.GIF")) {
        printf("balcat1.gif error\n");
        exit(-1);
    }
    // load the font
    if (!LoadDFONT(&F1,"HELLO.chr")) {
        printf("HELLOC.chr error loading\n");
        exit(-1);
    }
    SetDFONT(&F1);

    if (!CreateSurf(&rendSurf, ScrResH,ScrResV,16)) {
        printf("no mem: create renderSurf failed\n");
        exit(-1);
    }

    DgInstallTimer(500);
    if (DgTimerFreq == 0) {
        printf("Timer error\n");
        exit(-1);
    }
    if (!InstallKeyboard()) {
        DgUninstallTimer();
        printf("keyboard error\n");
        exit(-1);
    }

    // init video mode
    if (!InitVesaMode(ScrResH,ScrResV,16,1))
      {  printf("VESA mode error\n"); CloseVesa(); exit(-1); }
    SetSurf(&VSurf[0]);
    Clear16(0); // clear by black


    FREE_MMX();
    InitSynch(SynchBuff,NULL,60);

    NbSprites = 0;
    int randY = (ScrResV - 180);
    // set the current active surface for drawing
    SetSurf(rendSurf);


    // start the main loop
    for (int j=0;; j++) {
        FREE_MMX();
        // synchronise
        Synch(SynchBuff,NULL);
        // average time
        float avgFps=SynchAverageTime(SynchBuff);
        // sprites DATA handling progressing
        // add a new sprite if we have not reached the max
        if (!PauseMove) {
            if (NbSprites < MAX_SPRITES) {
                Sprites[NbSprites].x = 0;
                Sprites[NbSprites].y = rand()%randY+20;
                Sprites[NbSprites].xspeed = rand()%10+1;
                Sprites[NbSprites].sprite = sprites[rand()%3];
                NbSprites++; // increase the number of sprites
            }
            // increase pos of the sprites
            for (int i=0; i< NbSprites; i++) {
                Sprites[i].x+=Sprites[i].xspeed;
                if (Sprites[i].x>=SpritesView.MaxX || Sprites[i].x<=SpritesView.MinX)
                    Sprites[i].xspeed = -Sprites[i].xspeed;
            }
        }
        // sprites rendering **********
        // set the view of the sprites for the current drawing surf
        SetSurfView(&CurSurf, &SpritesView);
        // clear sprites View
        ClearSurf16(0);
        // draw all the available sprites
        RenderAllView();

        // display text
        SetSurfView(&CurSurf, &TextView);
        ClearSurf16(0x0);
        ClearText(); // clear test position to upper left
        SetTextCol(RGB16(255,255,255));
        char text[256];

        FREE_MMX();
        sprintf(text, "Sprites %04i, fps %i, Rend Func '%s', '%s'\n\n",NbSprites,
                            (int)((avgFps>0.0)?(1.0f/(avgFps)):-1), PutFuncNames[PutFuncIdx], (!PauseMove)?"Moving..":"Paused");
        OutText16Mode(text, AJ_MID );

        SetTextCol(RGB16(255,255,0));
        OutText16Mode("Esc<Exit> Space<Toggle Pause> F7<switch render Func>", AJ_SRC);

        // get key
        unsigned char keyCode;
        unsigned int keyFLAG;

        GetKey(&keyCode, &keyFLAG);
        switch (keyCode) {
        case KB_KEY_SPACE :
            PauseMove=!PauseMove;
            break;
        case KB_KEY_ESC:
            ExitApp = true;
            break;
        case KB_KEY_F7:
            PutFuncIdx = (PutFuncIdx+1) % 6;
            break;
        }

        // exit if esc pressed
        if (ExitApp) break;
		// need screen shot
		if (takeScreenShot) {
			SaveBMP16(rendSurf,(char*)"Sprites16.bmp");
			takeScreenShot = false;
		}

        // refresh
        SurfCopy(&VSurf[0], rendSurf);
    }

    CloseVesa();
    UninstallKeyboard();
    DgUninstallTimer();
    TextMode();
    return 0;
}

// render sprites on current view (all view)
void RenderAllView() {
    switch(PutFuncIdx) {
        case 0:
            for (int i=0; i< NbSprites; i++)
                PutSurf16(Sprites[i].sprite, Sprites[i].x, Sprites[i].y, (Sprites[i].xspeed<0) ? NORM_PUT : INV_HZ_PUT);
            break;
        case 1:
            for (int i=0; i< NbSprites; i++)
                PutMaskSurf16(Sprites[i].sprite, Sprites[i].x, Sprites[i].y, (Sprites[i].xspeed<0) ? NORM_PUT : INV_HZ_PUT);
            break;
        case 2:
            for (int i=0; i< NbSprites; i++)
                PutSurfBlnd16(Sprites[i].sprite, Sprites[i].x, Sprites[i].y, (Sprites[i].xspeed<0) ? NORM_PUT : INV_HZ_PUT, RGB16(0,255,255) | (10 << 24));
            break;
        case 3:
            for (int i=0; i< NbSprites; i++)
                PutMaskSurfBlnd16(Sprites[i].sprite, Sprites[i].x, Sprites[i].y, (Sprites[i].xspeed<0) ? NORM_PUT : INV_HZ_PUT, RGB16(0,255,255) | (10 << 24));
            break;
        case 4:
            for (int i=0; i< NbSprites; i++)
                PutSurfTrans16(Sprites[i].sprite, Sprites[i].x, Sprites[i].y, (Sprites[i].xspeed<0) ? NORM_PUT : INV_HZ_PUT, 15);
            break;
        case 5:
            for (int i=0; i< NbSprites; i++)
                PutMaskSurfTrans16(Sprites[i].sprite, Sprites[i].x, Sprites[i].y, (Sprites[i].xspeed<0) ? NORM_PUT : INV_HZ_PUT, 15);
            break;

    }
}

