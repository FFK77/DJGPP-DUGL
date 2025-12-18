/*  DUGL Dos Ultimate Game Library - Adventure game like Sample */
/*  History : */
/*  ?? ??   2002 : first release */
/*  27 aout 2006 : small code cleaning, translating from french to english,
       adding more comments
    19 feb  2008 : small changes to work with DUGL 1.10 alfa
    10 august 2009: updated with DUGL Plus 0.3 and Sound blaster pro driver
*/

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

Surf MsPtr,Menu,NomJeux;
Voice VcMenu,VcBip;

int MasterVol=185,EffectVol=185;

VoicePack VP;
SoundDRV *SD;
void *Buff;
FILE *Pal;
View MsView,SaveView,TextView={ 0,0,320+80,50+120,320-80,50 } ;
View TextView2={ 0,0,320+180,240+100,320-180,240-40 };
FONT F1;
unsigned char palette[1024],Pal3d[1024],rouge,bleu,jaune,noir,blanc;
unsigned char colconv[256];
char s[80];

int OldTime,i,j,k,l,m,choix,CurProc;
int Pt1[] = {   320-  80,  50    ,   0,   0,   0,   17  };
int Pt2[] = {   320+  80,  50    ,   0,   0,   0,   17  };
int Pt3[] = {   320+  80,  50+120,   0,   0,   0,   17  };
int Pt4[] = {   320-  80,  50+120,   0,   0,   0,   17  };
int ListPt1[] = { 4, (int)&Pt1, (int)&Pt2, (int)&Pt3, (int)&Pt4 };
int Pt5[] = {   320- 180,  240-  30,  0,   0,   0,  17  };
int Pt6[] = {   320+ 180,  240-  30,  0,   0,   0,  17  };
int Pt7[] = {   320+ 180,  240+ 100,  0,   0,   0,  17  };
int Pt8[] = {   320- 180,  240+ 100,  0,   0,   0,  17  };
int ListPt2[] = { 4, (int)&Pt5, (int)&Pt6, (int)&Pt7, (int)&Pt8 };
// variable pour jouer
int Pt9[] = {   0   ,  240- 130 , 0, 0   ,0    ,0};
int Pta[] = {   639 ,  240- 130 , 0, 639 ,0    ,0};
int Ptb[] = {   639 ,  240+ 129 , 0, 639 ,259  ,0};
int Ptc[] = {   0   ,  240+ 129 , 0, 0   ,259  ,0};
int ListPt3[] = { 4, (int)&Pt9, (int)&Pta, (int)&Ptb, (int)&Ptc };

View JeuView =     { 0,0,639,240+129,0,240-130 },
     TextJeuxView ={ 0,0,639,240-140,0,0 };
     
Surf ImageJeux1,arbre1,poubelle1,couvpoub1;
int  JouerPremier=1;
char *NoMsg="nothing to say.",*Msg;
char *SprtArbre1="a tree",*SprtPoubelle1="Recycle Bin";
char *SprtCouvpoub1="the hat of the Recyvle Bin";
Voice VcPoub;
int   CovPosX=95,CovPosY=80;
// *** Cat ****************************
char *SprtBalChat1="the balloon of the cat Minocho";
char *SprtChat1="The cat Minocho";
Surf chat1,chat2,balleChat1,*chat;
int  TimeChgEtatChat;
Voice VcChat,VcTchBalChat;
// *** Who is ? "Ana" *********************
Surf ana1;
Voice VcAna1;
int AnaPosX=250,AnaPosY=10,AnaToX=520,AnaPutMode;
char *SprtAna1="Who is ?!!!";
char BuffSynchAna[SIZE_SYNCH_BUFF];
int PosAna;
//**************************************
void AddVoice(Voice *Vc,int State);
void FadePal(void *PalSrc,void *PalDst,int NbEtape);
void MenuPrincipal();
void MenuOptions();
void Jouer();

int main(int argc,char *argv[])
{       // init the lib
        if (!InitVesa())
	  { printf("DUGL init error\n"); exit(-1); }
	if ((Pal=fopen("3dpal.pal","rb"))==NULL) {
	  printf("3dpal.pal error\n"); exit(-1); }
	fread(&Pal3d,1024,1,Pal);
	fclose(Pal);
        // load GFX ressources
	if (!LoadGIF(&Menu,"menu.gif",&palette))
	  { printf("menu.gif error\n"); exit(-1); }
	if (!LoadGIF(&NomJeux,"nomjeux.gif",&palette))
	  { printf("nomjeux.gif error\n"); exit(-1); }
	if (!LoadGIF(&ImageJeux1,"jeux1.gif",&palette))
	  { printf("jeux1.gif error\n"); exit(-1); }
	if (!LoadGIF(&ana1,"moi.gif",&palette))
	  { printf("ana.gif error\n"); exit(-1); }
	SetOrgSurf(&ana1,ana1.ResH/2,0);

	if (!LoadGIF(&arbre1,"arbre1.gif",&palette))
	  { printf("arbre1.gif error\n"); exit(-1); }
	if (!LoadGIF(&chat1,"chat1.gif",&palette))
	  { printf("chat1.gif error\n"); exit(-1); }
	if (!LoadGIF(&chat2,"chat2.gif",&palette))
	  { printf("chat2.gif error\n"); exit(-1); }
	if (!LoadGIF(&balleChat1,"balchat1.gif",&palette))
	  { printf("balchat1.gif error\n"); exit(-1); }
	if (!LoadGIF(&poubelle1,"poubel1.gif",&palette))
	  { printf("poubel1.gif error\n"); exit(-1); }
	if (!LoadGIF(&couvpoub1,"covpoub1.gif",&palette))
	  { printf("covpoub1.gif error\n"); exit(-1); }
        // build the light table of each color
	PrBuildTbDegCol(&Pal3d,0.2);
        // create the red lookup table for each color
        // it means the red most near color to each color
	for (i=0;i<256;i++)
	  colconv[i]=FindCol(0,255,0,0,((unsigned char *)(Pal3d))[i*4+2],&Pal3d);

        // find the colors
	rouge=PrFindCol(0,255,0,0,255,&Pal3d,0.2);
	jaune=PrFindCol(0,255,0,255,0,&Pal3d,0.2);
	bleu=PrFindCol(0,255,255,0,0,&Pal3d,0.2);
	noir=PrFindCol(0,255,0,0,0,&Pal3d,0.2);
	blanc=PrFindCol(0,255,255,255,255,&Pal3d,0.2);
        // load the font
	if (!LoadFONT(&F1,"hello.chr")) {
	  printf("hello.chr introuvable\n"); exit(-1); }
        // load the mouse cursor
	if (!LoadGIF(&MsPtr,"mouseimg.gif",&palette))
	  { printf("msptr.gif introuvable\n"); exit(-1); }
        // change the origin of the image of the mouse cursor
	SetOrgSurf(&MsPtr,0,MsPtr.ResV-1);
        // load sound ressources
	if (!LoadWAV(&VcMenu,"menu.wav"))
	  { printf("menu.wav introuvable\n"); exit(-1); }
	if (!LoadWAV(&VcBip,"bip.wav"))
	  { printf("bip.wav introuvable\n"); exit(-1); }
	if (!LoadWAV(&VcChat,"cat.wav"))
	  { printf("cat.wav introuvable\n"); exit(-1); }
	if (!LoadWAV(&VcTchBalChat,"cats.wav"))
	  { printf("cats.wav introuvable\n"); exit(-1); }
	if (!LoadWAV(&VcPoub,"garbgec1.wav"))
	  { printf("garbgec1.wav introuvable\n"); exit(-1); }
	if (!LoadWAV(&VcAna1,"ana.wav"))
	  { printf("ana.wav introuvable\n"); exit(-1); }

        // load the sound driver
	if (!LoadSoundDRV(&SD,"sb16.drv"))
	  { printf("sb16.drv error loading\n"); exit(-1); }
        // alloc the memory buffer needed by the sound driver
	if ((Buff=malloc(SD->SizeBuff))==NULL)
	  { printf("no mem \n"); exit(-1); }
        // try to install the SB16 sound driver -1 means AUTODETECT
	if (!SD->InstallDriver(Buff,-1,-1,-1,-1)) {
           DestroySoundDRV(SD);
           free(Buff);
	   if (!LoadSoundDRV(&SD,"sbpro.drv"))
	   { printf("sbpro.drv error loading\n"); exit(-1); }
           // alloc the memory buffer needed by the sound driver
	   if ((Buff=malloc(SD->SizeBuff))==NULL)
	   { printf("no mem \n"); exit(-1); }
           // try to install the SB pro sound driver
           // base port autodetct -1 IRQ 5 DMA 1
	   if (!SD->InstallDriver(Buff,-1,5,1,-1)) {
             DestroySoundDRV(SD);
             free(Buff);
             
	     if (!LoadSoundDRV(&SD,"nosound.drv"))
	     { printf("nosound.drv error loading\n"); exit(-1); }
             // alloc the memory buffer needed by the sound driver
             if (SD->SizeBuff>0) {
	       if ((Buff=malloc(SD->SizeBuff))==NULL)
	       { printf("no mem \n"); exit(-1); }
             }
             // try to install the sound driver -1 means AUTODETECT
	     if (!SD->InstallDriver(Buff,-1,-1,-1,-1)) {
               DestroySoundDRV(SD);
               free(Buff);
               printf("No sound card detected :(\n");
               exit(-1);
	     }
           }

	}
          
        // default volume
	SD->SetMasterVolume(MasterVol,MasterVol);
	SD->SetVoiceVolume(EffectVol,EffectVol);
        // prepare sounds : memory locking
	if (!SD->PrepareVoice(&VcMenu))
	  { printf("no mem \n"); exit(-1); }
	if (!SD->PrepareVoice(&VcBip))
	  { printf("no mem \n"); exit(-1); }
	if (!SD->PrepareVoice(&VcChat))
	  { printf("no mem \n"); exit(-1); }
	if (!SD->PrepareVoice(&VcTchBalChat))
	  { printf("no mem \n"); exit(-1); }
	if (!SD->PrepareVoice(&VcPoub))
	  { printf("no mem \n"); exit(-1); }
	if (!SD->PrepareVoice(&VcAna1))
	  { printf("no mem \n"); exit(-1); }

        // Inits
	if (!InstallMouse())
	  { printf("Mouse error\n"); exit(-1); }
	if (!InstallTimer(300))
	  { UninstallMouse(); printf("Timer error\n"); exit(-1); }
	if (!InstallKeyboard())
	  { UninstallTimer(); UninstallMouse();
	    printf("Keyboard error\n");  exit(-1); }

        // start the sound output
	SD->InitSound(DS_OUT8BIT,DS_NOSOUND,DS_STEREO,22050);
	    
        // init the video mode with 3 video pages
	if (!InitVesaMode(640,480,8,3))
	  { CloseVesa(); UninstallTimer(); UninstallMouse(); UninstallKeyboard();
	    printf("VESA mode error\n"); exit(-1); }

	MsX=320; MsY=240;
	SetPalette(0,256,&Pal3d);
	GetSurfRView(&VSurf[0],&MsView);
	SetMouseRView(&MsView);
	
	SetFONT(&F1);
	SetSurf(&VSurf[0]);
	ViewSurf(0);
	for (i=0;i<1024;i++) palette[i]=0;
	SetPalette(0,256,&palette);
	WaitRetrace();
	PutSurf(&Menu,0,0,0);
	FadePal(&palette,&Pal3d,60);
	AddVoice(&VcMenu,DS_VC_LOOPING);
	SetPalette(0,256,&Pal3d);
        float avgFps = 0.0f;
        float lastFps = 0.0f;
        FREE_MMX();
	InitSynch(BuffSynchAna,&PosAna,60.0);
	CurProc=0;
	for (j=0;;j++) {
          FREE_MMX();
          // synchronise
          Synch(BuffSynchAna,&PosAna);
      
           // synch screen display
           avgFps=SynchAverageTime(BuffSynchAna);
           lastFps=SynchLastTime(BuffSynchAna);
//	   if (Time-OldTime<(TimerFreq/CurModeVtFreq))
//	     WaitRetrace();
	   OldTime=Time;
	   ViewSurf(j%3);
           // create a screenshot
           // tab + ctrl + shift
           if (IsKeyDown(0xf) && (KbFLAG&KB_SHIFT_PR) && (KbFLAG&KB_CTRL_PR))
              SavePCX(&VSurf[j%3],"avent.pcx",&Pal3d);
              
	   SetSurf(&VSurf[(j+1)%3]);
	   switch (CurProc) {
	     case 0:  MenuPrincipal(); break;
	     case 1:  Jouer(); break;
	     case 3:  MenuOptions(); break;
	     case -1: break;
	     default: CurProc=0;
	   }
	  if ((LastKey==1) || (CurProc==-1)) break;
	  PutMaskSurf(&MsPtr,MsX,MsY,0);
	}
	SetSurf(&VSurf[0]);
	ViewSurf(0);
	PutSurf(&Menu,0,0,0);
	for (i=0;i<1024;i++) palette[i]=0;
	FadePal(&Pal3d,&palette,60);
	
	SD->UnprepareVoice(&VcMenu);
	SD->UnprepareVoice(&VcBip);
	SD->UnprepareVoice(&VcChat);
	SD->UnprepareVoice(&VcTchBalChat);
	SD->UnprepareVoice(&VcPoub);
	SD->UnprepareVoice(&VcAna1);

	SD->UninstallDriver();
	DestroySoundDRV(SD);
        free(Buff);
	CloseVesa();
	UninstallKeyboard();
	UninstallTimer();
	UninstallMouse();
        TextMode();
        return 0;
}

void MenuPrincipal() {
	  PutSurf(&Menu,0,0,0);
	  PutMaskSurf(&NomJeux,CurSurf.ResH/2-NomJeux.ResH/2,200,0);
	  PtrTbColConv=&colconv;
//	  PtrTbColConv=NULL;
	  Poly(&ListPt1, NULL, POLY_EFF_COLCONV, 17);
	  GetSurfRView(&CurSurf,&SaveView);
	  SetSurfRView(&CurSurf,&TextView);
	  ClearText();
	  FntCol=blanc; // blanc
	  choix=-1;
	  if (MsX>=CurSurf.MinX && MsX<=CurSurf.MaxX) {
	    if (MsY>=(CurSurf.MaxY-1*FntHaut) && MsY<(CurSurf.MaxY-0*FntHaut)) {
	      FntCol=jaune; choix=0;
	      OutTextMode("New Game\n",AJ_MID); FntCol=blanc;
	    } else OutTextMode("New Game\n",AJ_MID);
	    
	    if (MsY>=(CurSurf.MaxY-2*FntHaut) && MsY<(CurSurf.MaxY-1*FntHaut)) {
	      FntCol=jaune; choix=1;
	      OutTextMode("Load\n",AJ_MID); FntCol=blanc;
	    } else OutTextMode("Load\n",AJ_MID);
	    
	    if (MsY>=(CurSurf.MaxY-3*FntHaut) && MsY<(CurSurf.MaxY-2*FntHaut)) {
	      FntCol=jaune; choix=2;
	      OutTextMode("Save\n",AJ_MID); FntCol=blanc;
	    } else OutTextMode("Save\n",AJ_MID);
	    
	    if (MsY>=(CurSurf.MaxY-4*FntHaut) && MsY<(CurSurf.MaxY-3*FntHaut)) {
	      FntCol=jaune; choix=3;
	      OutTextMode("Options\n",AJ_MID); FntCol=blanc;
	    } else OutTextMode("Options\n",AJ_MID);
	    
	    if (MsY>=(CurSurf.MaxY-5*FntHaut) && MsY<(CurSurf.MaxY-4*FntHaut)) {
	      FntCol=jaune; choix=4;
	      OutTextMode("Exit\n",AJ_MID); FntCol=blanc;
	    } else OutTextMode("Exit\n",AJ_MID);
	  }
	  else {
	    OutTextMode("New Game\n",AJ_MID);
	    OutTextMode("Load\n",AJ_MID);
	    OutTextMode("Save\n",AJ_MID);
	    OutTextMode("Options\n",AJ_MID);
	    OutTextMode("Exit\n",AJ_MID);
	  }
	  if (choix!=-1 && (MsButton&1)) {
	     AddVoice(&VcBip,DS_VC_NORMAL);
	     switch (choix) {
	      case 0: CurProc=1; break;
	      case 1: CurProc=0; break;
	      default: CurProc=choix;
	     }
	     if (CurProc==4) CurProc=-1;
	    }
	  SetSurfRView(&CurSurf,&SaveView);
}

void MenuOptions() {
	PutSurf(&Menu,0,0,0);
	PtrTbColConv=&colconv;
	Poly(&ListPt2, NULL, POLY_EFF_COLCONV, 17);
	GetSurfRView(&CurSurf,&SaveView);
	SetSurfRView(&CurSurf,&TextView2);
  	ClearText();
	
	FntCol=bleu; // blanc
	OutTextMode("MENU  OPTIONS\n\n",AJ_MID); FntCol=blanc;
	
	FntCol=blanc; // blanc
	choix=-1;
	if (MsX>=CurSurf.MinX && MsX<=CurSurf.MaxX) {

	    if (MsY>=(CurSurf.MaxY-3*FntHaut) && MsY<(CurSurf.MaxY-2*FntHaut)) {
	      FntCol=jaune; choix=2;
	      OutTextMode(" Master Volume \n",AJ_CUR_POS); FntCol=blanc;
	    } else OutTextMode(" Master Volume \n",AJ_CUR_POS);

	    if (MsY>=(CurSurf.MaxY-4*FntHaut) && MsY<(CurSurf.MaxY-3*FntHaut)) {
	      FntCol=jaune; choix=3;
	      OutTextMode(" Effect Volume\n",AJ_CUR_POS); FntCol=blanc;
	    } else OutTextMode(" Effect Volume\n",AJ_CUR_POS);

	    if (MsY>=(CurSurf.MaxY-5*FntHaut) && MsY<(CurSurf.MaxY-4*FntHaut)) {
	      FntCol=jaune; choix=4;
	      OutTextMode(" Back\n",AJ_CUR_POS); FntCol=blanc;
	    } else OutTextMode(" Back\n",AJ_CUR_POS);
	  }
	  else {
	    OutTextMode(" Master Volume \n",AJ_CUR_POS); FntCol=blanc;
	    OutTextMode(" Effect Volume\n",AJ_CUR_POS); FntCol=blanc;
	    OutTextMode(" Back\n",AJ_CUR_POS);
	  }
	 bar(CurSurf.MinX+150,(CurSurf.MaxY-3*FntHaut+(FntHaut/2)),
	 	  CurSurf.MinX+150+127,(CurSurf.MaxY-2*FntHaut),jaune);
	 bar(CurSurf.MinX+150,(CurSurf.MaxY-4*FntHaut+(FntHaut/2)),
	 	  CurSurf.MinX+150+127,(CurSurf.MaxY-3*FntHaut),jaune);
	 bar(CurSurf.MinX+150,(CurSurf.MaxY-3*FntHaut+(FntHaut/2)),
	 	  CurSurf.MinX+150+(MasterVol/2),(CurSurf.MaxY-2*FntHaut),rouge);
	 bar(CurSurf.MinX+150,(CurSurf.MaxY-4*FntHaut+(FntHaut/2)),
	 	  CurSurf.MinX+150+(EffectVol/2),(CurSurf.MaxY-3*FntHaut),rouge);
	 if (choix==3 || choix==2) {
	   OutText("\n\n");
	   OutTextMode(" Mouse Buttons Left - Right +",AJ_MID);
	  }

	  if (choix!=-1 && ((MsButton&1) ||(MsButton&2)) ) {
	     if (choix==3 && (MsButton&1) && (EffectVol>0))
	       { AddVoice(&VcBip,DS_VC_NORMAL); EffectVol--;
	 	 SD->SetVoiceVolume(EffectVol,EffectVol);
	       }
	     if (choix==3 && (MsButton&2) && (EffectVol<255))
	       { AddVoice(&VcBip,DS_VC_NORMAL); EffectVol++;
	 	 SD->SetVoiceVolume(EffectVol,EffectVol);
	       }
	     if (choix==2 && (MsButton&1) && (MasterVol>0))
	       { AddVoice(&VcBip,DS_VC_NORMAL); MasterVol--;
	 	 SD->SetMasterVolume(MasterVol,MasterVol);
	       }
	     if (choix==2 && (MsButton&2) && (MasterVol<255))
	       { AddVoice(&VcBip,DS_VC_NORMAL); MasterVol++;
	 	 SD->SetMasterVolume(MasterVol,MasterVol);
	       }
	     if (choix==4 && (MsButton&1)) { CurProc=0; AddVoice(&VcBip,DS_VC_NORMAL); }
	    }
	  SetSurfRView(&CurSurf,&SaveView);
}

void Jouer() {
	int VcMenuState;
	if (JouerPremier) { // Section entree en mode jeux ------------------
	  JouerPremier=0;
	  SD->GetVoiceState(&VcMenu,&VcMenuState);
	  VcMenuState|=DS_VC_STOPPED;
	  SD->SetVoiceState(&VcMenu,VcMenuState);
	  for (i=0;i<1024;i++) palette[i]=0;
	  WaitRetrace(); SetPalette(0,256,&palette);
	  for (i=0;i<3;i++) { SetSurf(&VSurf[i]); Clear(noir); }
	  SetSurf(&VSurf[j%3]);
	  for (i=0;i<4;i++) WaitRetrace(); SetPalette(0,256,&Pal3d);
	  Pt9[5]=0; Pta[5]=0; Ptb[5]=0; Ptc[5]=0;
	  for (i=1;i<32;i+=2) {
	    Pt9[5]=i; WaitRetrace();
	    Poly(&ListPt3, &ImageJeux1, POLY_DEG_TEXT, 0);   }
	  for (i=1;i<32;i+=2) {
	    Pta[5]=i; WaitRetrace();
	    Poly(&ListPt3, &ImageJeux1, POLY_DEG_TEXT, 0);   }
	  for (i=1;i<32;i+=2) {
	    Ptb[5]=i; WaitRetrace();
	    Poly(&ListPt3, &ImageJeux1, POLY_DEG_TEXT, 0);   }
	  for (i=1;i<32;i+=2) {
	    Ptc[5]=i; WaitRetrace();
	    Poly(&ListPt3, &ImageJeux1, POLY_DEG_TEXT, 0);   }
	  WaitRetrace(); SetPalette(0,256,&Pal3d);
	  SetSurf(&VSurf[(j+1)%3]);
	  PutSurf(&ImageJeux1,JeuView.MinX,JeuView.MinY,0);
	  // **********demarrage cat
          FREE_MMX();
	  chat=&chat1;
	  TimeChgEtatChat=Time+TimerFreq/2+(TimerFreq*(0.01)*(random()%200));
	  // **** demarrage ana
	  InitSynch(BuffSynchAna,&PosAna,60.0);
          
	  //Synch(BuffSynchAna,&PosAna);
	}
	else {	 // traitement Normal ---------------------------------------
	  GetSurfRView(&CurSurf,&SaveView);

	  SetSurfRView(&CurSurf,&JeuView);
	  Clear(noir);
	  PutSurf(&ImageJeux1,CurSurf.MinX,CurSurf.MinY,0);
	  Msg=NoMsg;
	  PutMaskSurf(&arbre1,CurSurf.MaxX-80,CurSurf.MaxY-185,0);
	  if (InPutMaskSurf(&arbre1,CurSurf.MaxX-80,CurSurf.MaxY-185,0,MsX,MsY))
	    Msg=SprtArbre1;
	    
	  PutMaskSurf(&poubelle1,CurSurf.MinX+95,CurSurf.MinY+40,0);
	  if (InPutMaskSurf(&poubelle1,CurSurf.MinX+95,CurSurf.MinY+40,0,MsX,MsY)) {
	    Msg=SprtPoubelle1;
	    if (MsButton&1) AddVoice(&VcPoub,DS_VC_NORMAL);
	  }
	    
	  PutMaskSurf(&couvpoub1,CurSurf.MinX+CovPosX,CurSurf.MinY+CovPosY,0);
	  if (InPutMaskSurf(&couvpoub1,CurSurf.MinX+CovPosX,CurSurf.MinY+CovPosY,0,MsX,MsY)) {
	    Msg=SprtCouvpoub1;
	    if (MsButton&1) {
	      CovPosX=(CovPosX==95)?170:95;
	      CovPosY=(CovPosY==80)?35:80;
	    }
	  }
	    
	  PutMaskSurf(chat,CurSurf.MinX+50,CurSurf.MinY+20,0);
	  if (InPutMaskSurf(chat,CurSurf.MinX+50,CurSurf.MinY+20,0,MsX,MsY)) {
	    Msg=SprtChat1;
	    if (MsButton&1) AddVoice(&VcChat,DS_VC_NORMAL);
	   }
	  if (TimeChgEtatChat<=Time) {
	    chat=((chat==&chat1)?&chat2:&chat1);
            FREE_MMX();
	    TimeChgEtatChat=Time+TimerFreq/2+(TimerFreq*(0.01)*(random()%200));
	  }
	    
	  PutMaskSurf(&balleChat1,CurSurf.MinX+50,CurSurf.MinY+25,0);
	  if (InPutMaskSurf(&balleChat1,CurSurf.MinX+50,CurSurf.MinY+25,0,MsX,MsY)) {
	    Msg=SprtBalChat1;
	    if (MsButton&1) AddVoice(&VcTchBalChat,DS_VC_NORMAL);
	  }
	  // --------- traitement Ana

          FREE_MMX();
          int deltaXAna=Synch(BuffSynchAna,&PosAna);
	  if (AnaPosX<AnaToX) {
	    AnaPutMode=1;
	    PutMaskSurf(&ana1,CurSurf.MinX+AnaPosX,CurSurf.MinY+AnaPosY,1); // Inv Hz
            AnaPosX+=deltaXAna*2;

	    if (AnaPosX>=AnaToX) {
	      AnaPosX=AnaToX;
	      do {} while ((AnaToX=(random()%500)+60)==AnaPosX);
	     }
	  } else if (AnaPosX>AnaToX) {
	    AnaPutMode=0;
	    PutMaskSurf(&ana1,CurSurf.MinX+AnaPosX,CurSurf.MinY+AnaPosY,0);
	    AnaPosX-=deltaXAna*2;
	    if (AnaPosX<=AnaToX) {
	      AnaPosX=AnaToX;
	      do {} while ((AnaToX=(random()%800)+30)==AnaPosX);
	     }
	  }
	  if (InPutMaskSurf(&ana1,CurSurf.MinX+AnaPosX,CurSurf.MinY+AnaPosY,AnaPutMode,
	                     MsX,MsY)) {
	    Msg=SprtAna1;
	    if (MsButton&1) AddVoice(&VcAna1,DS_VC_NORMAL);
	  }
	  
	  SetSurfRView(&CurSurf,&TextJeuxView);
  	  ClearText();
	  FntCol=blanc; OutTextMode(Msg,AJ_MID);
	  SetSurfRView(&CurSurf,&JeuView);

	  if (LastKey==1) {  // Section sortie du mode jeux -----------------
	    SetSurf(&VSurf[j%3]);
	    for (i=0;i<4;i++) WaitRetrace(); SetPalette(0,256,&Pal3d);
	    for (i=0;i<32;i+=2) {
	      Ptc[5]=32+i; WaitRetrace();
	      Poly(&ListPt3, &ImageJeux1, POLY_DEG_TEXT, 0);   }
	    for (i=0;i<32;i+=2) {
	      Ptb[5]=32+i; WaitRetrace();
	      Poly(&ListPt3, &ImageJeux1, POLY_DEG_TEXT, 0);   }
	    for (i=0;i<32;i+=2) {
	      Pta[5]=32+i; WaitRetrace();
	      Poly(&ListPt3, &ImageJeux1, POLY_DEG_TEXT, 0);   }
	    for (i=0;i<32;i+=2) {
	      Pt9[5]=32+i; WaitRetrace();
	      Poly(&ListPt3, &ImageJeux1, POLY_DEG_TEXT, 0);   }
	    for (i=0;i<1024;i++) palette[i]=0;
	    FadePal(&Pal3d,&palette,30);
	    for (i=0;i<3;i++) { SetSurf(&VSurf[i]); Clear(noir); }
	    SetSurf(&VSurf[(j+1)%3]);
	    for (i=0;i<4;i++) WaitRetrace(); SetPalette(0,256,&Pal3d);
	    CurProc=0; LastKey=0; JouerPremier=1;
	    SD->GetVoiceState(&VcMenu,&VcMenuState);
	    VcMenuState&=~DS_VC_STOPPED;
	    SD->SetVoiceState(&VcMenu,VcMenuState);
	  }
	  SetSurfRView(&CurSurf,&SaveView);
	}
}

void FadePal(void *PalSrc,void *PalDst,int NbEtape) {
	unsigned char PalMid[1024];
	int i,j;
	unsigned char *Psrc=(unsigned char*)PalSrc,*Pdst=(unsigned char*)PalDst;
	SetPalette(0,256,Psrc);
	WaitRetrace();
	for (i=0;i<NbEtape-1;i++)
	{
	  for (j=0;j<1024;j++)
	    PalMid[j]=Psrc[j]+((float)(Pdst[j]-Psrc[j])/(float)(NbEtape))*i;
	  SetPalette(0,256,&PalMid);
	  WaitRetrace();
	}
	SetPalette(0,256,Pdst);
}

void AddVoice(Voice *Vc,int State)
{	if (SD->Cur_SampSpeed!=Vc->Freq) {
	  VP.Speed=(128*Vc->Freq)/SD->Cur_SampSpeed;
	  SD->AddVoice(Vc,DS_EFF_CHG_SPEED,State,&VP,0);
	} else SD->AddVoice(Vc,DS_EFF_NONE,State,NULL,0);
}

