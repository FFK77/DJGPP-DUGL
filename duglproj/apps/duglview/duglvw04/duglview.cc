/*  DUGL - Dos Ultimate Game Library - DUGL Viewer */
/*  GUI Image Viewer for dos systems */
/*  History      */
/*  21/08/2011 Ver 0.4 : First Official release */


#include <stdio.h>
#include <conio.h>
#include <stdlib.h>
#include <string.h>
#include <dir.h>
#include <dos.h>
#include <ctype.h>
#include <dpmi.h>
#include <dugl/dugl.h>
#include <dugl/duglplus.h>

// config
unsigned int screenX = 640, screenY = 480;
float DefMsPosX = 0.5, DefMsPosY = 0.5;
bool EnableKeyDownNextPage = false, EnableKeyUpPrevPage = false;
bool EnableSmoothDownSize = false, EnableDefaultMultiLoad = false;
float SmoothDownSizeLevel = 0.7, EnhSmoothDownSizeLowLevel = 0.25;
float KeybWaitPrevPage = 0.5, KeybWaitNextPage = 0.5;
float KeyBWaitStartScroll = 0.25;
int   MsWheelScrollDir = 1;
int   iDefTypeOpen = 0;
int   iDisplayMode = 1; // 0 fit width, 1 fit view, 2 As Is
float SmoothZoomLimit = 1.5, EnhSmoothZoomLimit = 3.0;
bool  SmoothResize = false;
bool  CheckWinNT = true;

// screen shot file name
char *scrFileName="DUGLVEWR.BMP";

//unsigned int screenX = 320, screenY = 400;
// full screen frame - quad drawing
int Pt1[] = {   0,   0,   0,   0,   0 };
int Pt2[] = { 639,   0,   0,   0,   0 };
int Pt3[] = { 639, 479,   0,   0,   0 };
int Pt4[] = {   0, 479,   0,   0,   0 };
int ListPt1[] = {  4,  (int)&Pt1, (int)&Pt2, (int)&Pt3, (int)&Pt4 };

Surf MsPtr,MsPtr16,rendSurf16,blurSurf16;

unsigned char palette[1024];

// FONT
FONT F1;
// mouse View
View MsV;
// keyborad map
KbMAP *KM;
unsigned char keyCode;
unsigned int keyFLAG;

// display parameters
bool BlurDisplay=true, SynchScreen=false, DropFrames=false,
     FullScrShowTime=true,FullScrShowFps=false, InterpolateUV=false;
bool MouseSupported;
bool UseCurImg = false;
bool ExitViewer = false;
// GUI or full screen
int EnableGUI = 0;
// synch buffer
char SynchBuff[SIZE_SYNCH_BUFF];
int PosSynch;

// GUI *************************************
// Windows Handler
WinHandler *WH;
// Main window -------------------------------
MainWin *MWDViewer;
GraphBox *GphBVideo;
ImgButton *BtOpen,*BtBack,*BtNext,*BtFirst,*BtLast,*BtAbout,*BtExit;
ComBox *CmbViewMode;
Surf ImgOpen,ImgNext,ImgBack,ImgBegin,ImgEnd,ImgExit,ImgAbout,ImgPCont;
// events
void OnOpen(), OnNext(), OnBack(), OnFirst(), OnLast(), OnAbout(), OnExit();
void GphBDrawVideo(GraphBox *Me),GphBScanVideo(GraphBox *Me);
void OnBtPlayClick();
int OpenImg(char *FileName);
void FBOpenImg(String *S,int TypeSel);
void ChgdCmbViewMode(String *S,int Sel);

// About window -------------------------------
//CAboutDlg *DlgAbout;
MainWin *MWAbout;
GraphBox *GphBAbout;
Button *BtOkAbout;
// events
void BtOkAboutClick(),GphBDrawAbout(GraphBox *Me),OnGphBScanAbout(GraphBox *Me);

// glabal var
int redrawVid=1;
Surf MyIMG,MySmthIMG;
bool validMyIMG = false, redrawIMG = false;
bool DownSize = false;
//------
bool firstUpDown = true, firstDownDown = true;
bool firstLeftDown = true, firstRightDown = true;
int initialIMGPlusDown=0, initialIMGPlusUp=0;
float firstUpTimeBound, firstDownTimeBound;
bool firstUpBound = true, firstDownBound = true;
int MyIMGPlus =0;
int IMGdypos = 0;
int LastScanMsWheel = MsZ;
int MyIMGMaxPlus = 0;
int mdMinOrgX, mdMaxOrgX, mdMinOrgY, mdMaxOrgY;
int startOrgX, startOrgY;
int AppliedMsDownDX=0, AppliedMsDownDY=0;
float timeUp = 0.0;
float timeDown = 0.0;
float timeBoundUp = 0.0;
float timeBoundDown = 0.0;
float curZoom = 1.0;
bool MultiAutoLoad = false;
//--
String MainWinName("DUGL Viewer 0.4");
int CurImgNum = 0;
ListString LSFiles;
String InfImg;
// file filer string
char *TSFBName[]={ "all supported images", "jpeg", "png", "bitmap 8/24bpp", "GIF 8bpp", "PCX 8bpp" ,"All Files(*.*)" };
char *TSFBMask[]={ "*.jpg|*.png|*.bmp|*.gif|*.pcx", "*.jpg", "*.png", "*.bmp", "*.gif", "*.pcx", "*.*" };
ListString LSImgName(7,TSFBName),LSImgMask(7,TSFBMask);

//******* Global function ****************************
void LoadCurImg();
void SmoothCurImg();
void LoadConfig();
//----
void DGWaitRetrace();
void ResizeSurf16(Surf *SDstSurf,Surf *SSrcSurf);
bool IsFileExist(const char *fname);
bool LoadImg(char *filename, Surf *DstSurf);

int main (int argc, char ** argv) {
    LoadConfig();

    if(CheckWinNT && _os_trueversion==0x532) {
       printf("WinNT/2k/XP/Vista/7 not supported!\n"); exit(-1); }

    Init3DMath(); // dugl+
    
    if (!InitVesa())
      { printf("DUGL init error\n"); exit(-1); }

    // init video mode
    if (!InitVesaMode(screenX,screenY,16,1)) {
       screenX = 640; screenY = 480;
       if (!InitVesaMode(screenX,screenY,16,1)) {
          printf("VESA mode error\n"); CloseVesa(); exit(-1);
       }
    }
      
    if (CreateSurf(&rendSurf16, screenX, screenY, 16)==0) {
      printf("no mem\n"); exit(-1);
    }
    if (CreateSurf(&blurSurf16, screenX, screenY, 16)==0) {
      printf("no mem\n"); exit(-1);
    }
    if (!LoadGIF(&MsPtr,"gfx/mouseimg.gif",&palette))
      { printf("Error loading mouseimg.gif\n"); exit(-1); }
    if (CreateSurf(&MsPtr16, MsPtr.ResH, MsPtr.ResV, 16)==0) {
      printf("no mem\n"); exit(-1);
    }
    ConvSurf8ToSurf16Pal(&MsPtr16,&MsPtr,&palette);

    if (LoadBMP16(&ImgOpen,"gfx/open.bmp")==0) {
      printf("Error loading open.bmp\n"); exit(-1);
    }
    if (LoadBMP16(&ImgNext,"gfx/next.bmp")==0) {
      printf("Error loading open.bmp\n"); exit(-1);
    }
    if (LoadBMP16(&ImgBack,"gfx/back.bmp")==0) {
      printf("Error loading open.bmp\n"); exit(-1);
    }
    if (LoadBMP16(&ImgBegin,"gfx/begin.bmp")==0) {
      printf("Error loading open.bmp\n"); exit(-1);
    }
    if (LoadBMP16(&ImgEnd,"gfx/end.bmp")==0) {
      printf("Error loading open.bmp\n"); exit(-1);
    }
    if (LoadBMP16(&ImgExit,"gfx/shut.bmp")==0) {
      printf("Error loading shut.bmp\n"); exit(-1);
    }
    if (LoadBMP16(&ImgAbout,"gfx/about.bmp")==0) {
      printf("Error loading about.bmp\n"); exit(-1);
    }


    if (!LoadKbMAP(&KM,"azertfr.map")) {
      printf("Error loading azertfr.map\n"); exit(-1); }

    // load font
    if (!LoadFONT(&F1,"hello.chr")) {
      printf("Error loading hello.chr\n"); exit(-1); }

    // init the lib

    if (!InstallTimer(200)) {
       CloseVesa(); printf("Timer error\n"); exit(-1);
    }
    if (!InstallKeyboard()) {
       CloseVesa(); UninstallTimer();
       printf("Keyboard error\n");  exit(-1);
    }
    if (!SetKbMAP(KM)) {
       UninstallTimer(); UninstallKeyboard(); CloseVesa();
       printf("Error setting keyborad map\n");  exit(-1);
    }
    MouseSupported = (InstallMouse()!=0);


    SetSurf(&VSurf[0]);
    Clear16(0); // clear by black

    // set font
    SetFONT(&F1);
    // mouse
    if (MouseSupported) {
       // set mouse pointer Orig to the upper left corner
       SetOrgSurf(&MsPtr16,0,MsPtr16.ResV-1);
       // set mouse view
       GetSurfRView(&VSurf[0],&MsV);
       SetMouseRView(&MsV);
       FREE_MMX();
       SetMousePos(DefMsPosX*VSurf[0].ResH, DefMsPosY*VSurf[0].ResV);
    }
    else {
       DestroySurf(&MsPtr16);
       DestroySurf(&MsPtr);
    }

    //** GUI ************************************************
    // create the winHandler
    WH = new WinHandler(screenX,screenY,16,0xF|(0x1F<<5));
    //---- Main Window
    MWDViewer= new MainWin(0,0,screenX,screenY,MainWinName.StrPtr,WH);
    GphBVideo= new GraphBox(1,1,screenX-9,screenY-51,MWDViewer,WH->m_GraphCtxt->WinGris);
    // set drawing handler
    GphBVideo->GraphBoxDraw=GphBDrawVideo;
    // set scan handler (enable redraw when needed)
    GphBVideo->ScanGraphBox=GphBScanVideo;
    GphBVideo->Redraw();
    // buttons
    BtOpen=new ImgButton(1,screenY-50,21,screenY-25,MWDViewer,&ImgOpen);
    BtOpen->Click=OnOpen;
    BtFirst=new ImgButton(22,screenY-50,42,screenY-25,MWDViewer,&ImgBegin);
    BtFirst->Click=OnFirst;
    BtBack=new ImgButton(43,screenY-50,63,screenY-25,MWDViewer,&ImgBack);
    BtBack->Click=OnBack;
    BtNext=new ImgButton(64,screenY-50,84,screenY-25,MWDViewer,&ImgNext);
    BtNext->Click=OnNext;
    BtLast=new ImgButton(85,screenY-50,105,screenY-25,MWDViewer,&ImgEnd);
    BtLast->Click=OnLast;
    CmbViewMode=new ComBox(107,screenY-50,88,23,MWDViewer);
    CmbViewMode->LStr->Add("Fit Width");
    CmbViewMode->LStr->Add("Fit View");
    CmbViewMode->LStr->Add("As Is");
    CmbViewMode->Changed=ChgdCmbViewMode;
    CmbViewMode->Select=iDisplayMode;
    
    BtExit=new ImgButton(screenX-35,screenY-50,screenX-10,screenY-25,MWDViewer,&ImgExit);
    BtExit->Click=OnExit; // set click handler
    BtAbout=new ImgButton(screenX-63,screenY-50,screenX-37,screenY-25,MWDViewer,&ImgAbout);
    BtAbout->Click=OnAbout;
    //*******************************************************

    // init synch for synching the screen
    PosSynch=0;
    InitSynch(SynchBuff,&PosSynch,30);
    // main loop
    for (int j=0;;j++) {
      // synchronise
      Synch(SynchBuff,&PosSynch);
      // synch screen display
      float avgFps=SynchAverageTime(SynchBuff),
            lastFps=SynchLastTime(SynchBuff);

      SetSurf(&rendSurf16);
      
      // scan the GUI for events
      WH->Scan();
      // draw the GUI
      WH->DrawSurf(&CurSurf);
      // draw the mouse pointer
      if(MouseSupported)
         PutMaskSurf16(&MsPtr16,MsX,MsY,0);
      // draw the GUI
      DGWaitRetrace();
      SurfCopy(&VSurf[0], &rendSurf16);

      // alt+ X : exit
      if ((WH->Key==45 && /* 'X'|'x' */ (WH->KeyFLAG&KB_ALT_PR)) || ExitViewer)
         break;
      if (MWDViewer->Key==0x3D) // F3
         OnOpen();
      if (MWDViewer->Key==0x3F) { // F5
        if(validMyIMG) {
          if(SmoothResize) {
            if(curZoom>=SmoothZoomLimit)
              DestroySurf(&MySmthIMG);
            SmoothResize = false;
            redrawIMG = true;
          }
          else {
            SmoothResize = true;
            SmoothCurImg();
            redrawIMG = SmoothResize; // redraw if success smoothing
          }
        }
        else
          SmoothResize = !SmoothResize;
        
      }
      if (MWDViewer->Key==0x40) { // F6 - switch view mode
        CmbViewMode->Select++;
        if(CmbViewMode->Select>2) CmbViewMode->Select=0;
      }
      if (MWDViewer->Key==0xD1) // Page Down
         OnNext();
      if (MWDViewer->Key==0xC9) // Page UP
         OnBack();
      if (MWDViewer->Key==0xC7) // begin
         OnFirst();
      if (MWDViewer->Key==0xCf) // end
         OnLast();
      // Alt + S  = bmp screen shot
      if (WH->Key==0x1f && (WH->KeyFLAG&KB_ALT_PR)) {
         bool bSucc = false;
         for (unsigned int ci='R';ci<='Z';ci++) {
            scrFileName[7]=(char)(ci);
            if (!IsFileExist(scrFileName)) {
               SaveBMP16(&rendSurf16,scrFileName);
               bSucc = true;
               break;
            }
         }
         if(!bSucc)
            SaveBMP16(&rendSurf16,scrFileName);
        FREE_MMX();
      }
    }

    if(validMyIMG) {
      DestroySurf(&MyIMG);
      if(SmoothResize)
        DestroySurf(&MySmthIMG);
    }
    CloseVesa();
    UninstallKeyboard();
    UninstallTimer();
    if(MouseSupported)
       UninstallMouse();
    TextMode();

    return 0;
}



void GphBDrawVideo(GraphBox *Me) {
   if(!validMyIMG || MyIMG.ResV<(Me->VGraphBox.MaxY-Me->VGraphBox.MinY) ||
      MyIMG.ResH<(Me->VGraphBox.MaxX-Me->VGraphBox.MinX))
     ClearSurf16(WH->m_GraphCtxt->WinGrisF);
    // loaded image ?
   if(validMyIMG)
   {
      FREE_MMX();
      if(SmoothResize && curZoom>=SmoothZoomLimit)
        SetOrgSurf(&MySmthIMG,MyIMG.OrgX,MyIMG.OrgY);
      PutSurf16((SmoothResize && curZoom>=SmoothZoomLimit)?(&MySmthIMG):(&MyIMG),
          Me->VGraphBox.MinX, Me->VGraphBox.MaxY - MyIMG.ResV + MyIMGPlus, 0);
   }
   
}

void GphBScanVideo(GraphBox *Me) {
   if(validMyIMG)
   {
     FREE_MMX();
     int gphBoxWidth = Me->VGraphBox.MaxX-Me->VGraphBox.MinX+1;
     int gphBoxHeight = Me->VGraphBox.MaxY-Me->VGraphBox.MinY+1;
     int speedImg = gphBoxHeight / 25;
     int slowSpeedImg = gphBoxHeight / 2;
     int speedXImg = gphBoxWidth / 25;
     int slowSpeedXImg = gphBoxWidth / 2;
     int wheelDir = 0;
     int newOrg = 0;
     if(LastScanMsWheel!=MsZ)
       wheelDir = (LastScanMsWheel-MsZ) / abs(LastScanMsWheel-MsZ);

     if(speedImg<1) speedImg = 1;
     if(slowSpeedImg<10) slowSpeedImg = 10;
     
     if(iDisplayMode==0 || iDisplayMode==1) {
       IMGdypos = MyIMG.ResV;
       MyIMGMaxPlus = MyIMG.ResV - (Me->VGraphBox.MaxY-Me->VGraphBox.MinY+1);

       if((IsKeyDown(0xc8) && Me->Focus) || (wheelDir==MsWheelScrollDir && Me->MsIn)) { // up
         timeUp = (float)(GetCurrTimeKeyDown(0xc8))/(float)(TimerFreq);
         timeUp -= timeBoundUp;
         firstDownBound = true;
         if(timeUp<KeyBWaitStartScroll && firstUpDown) {
           redrawIMG = true;
           firstUpDown = false;
           initialIMGPlusUp = MyIMGPlus;
           MyIMGPlus-=speedImg;
         }
         if(timeUp>KeyBWaitStartScroll) {
           redrawIMG = true;
           MyIMGPlus = initialIMGPlusUp - speedImg - (timeUp-KeyBWaitStartScroll)*slowSpeedImg;
         }
         if(MyIMGPlus<0) {
           if(firstUpBound) {
             MyIMGPlus=0;
             firstUpTimeBound = timeUp;
             firstUpBound = false;
             redrawIMG = true;
           }
           else if(EnableKeyUpPrevPage && !firstUpBound
              && timeUp-firstUpTimeBound>KeybWaitPrevPage && CurImgNum>0) {
             MyIMGPlus = 0;
             initialIMGPlusDown = 0;
             OnBack();
             redrawIMG = true;
             firstUpBound = true;
             timeBoundUp += timeUp;
           }
         }
       }
       else {
         timeBoundUp = 0.0;
         firstUpDown = true;
         firstUpBound = true;
       }

       if((IsKeyDown(0xd0) && Me->Focus) || (wheelDir==-MsWheelScrollDir && Me->MsIn)) { // down
         timeDown = (float)(GetCurrTimeKeyDown(0xd0))/(float)(TimerFreq);
         timeDown -= timeBoundDown;
         firstUpBound = true;
         if(timeDown<KeyBWaitStartScroll && firstDownDown) {
           redrawIMG = true;
           firstDownDown = false;
           initialIMGPlusDown=MyIMGPlus;
           MyIMGPlus+=speedImg;
         }
         if(timeDown>KeyBWaitStartScroll) {
           redrawIMG = true;
           MyIMGPlus = initialIMGPlusDown + speedImg + (timeDown-KeyBWaitStartScroll)*slowSpeedImg;
         }
         if(MyIMGPlus>MyIMGMaxPlus) {
           if(firstDownBound) {
             MyIMGPlus=MyIMGMaxPlus;
             firstDownTimeBound = timeDown;
             firstDownBound = false;
             redrawIMG = true;
           }
           else if(EnableKeyDownNextPage && !firstDownBound && timeDown-firstDownTimeBound>KeybWaitNextPage && CurImgNum < (LSFiles.NbElement()-1)) {
             //MyIMGPlus = 0;
            //initialIMGPlusDown = 0;
             OnNext();
             redrawIMG = true;
             firstDownBound = true;
             timeBoundDown += timeDown;
           }
         }
       }
       else {
         timeBoundDown = 0.0;
         firstDownDown = true;
         firstDownBound = true;
       }
       if(!Me->MsDown)
         AppliedMsDownDY =0;
       else {
         int oldMyIMGPlus = MyIMGPlus;
         MyIMGPlus += (MsY - Me->MsYDown) - AppliedMsDownDY;
         if(oldMyIMGPlus!=MyIMGPlus) {
           AppliedMsDownDY += (MyIMGPlus - oldMyIMGPlus);
           redrawIMG = true;
         }
       }

       if(MyIMGPlus<0) {
          MyIMGPlus=0;
          redrawIMG = true;
       }
       if(MyIMGPlus>MyIMGMaxPlus) {
          MyIMGPlus=MyIMGMaxPlus;
          redrawIMG = true;
       }
     }
     else { // as is display mode ---------------

       if(speedXImg<1) speedXImg = 1;
       if(slowSpeedXImg<10) slowSpeedXImg = 10;
       // up
       if((IsKeyDown(0xc8) && Me->Focus) || (wheelDir==-MsWheelScrollDir && Me->MsIn && (!Me->MsDown && !(MsButton&MS_RIGHT_BUTT)))) {
         timeDown = (float)(GetCurrTimeKeyDown(0xc8))/(float)(TimerFreq);
         if(timeDown<KeyBWaitStartScroll && firstDownDown) {
           if(MyIMG.OrgY+speedImg <= mdMaxOrgY)
             SetOrgSurf(&MyIMG, MyIMG.OrgX, MyIMG.OrgY+speedImg);
           else
             SetOrgSurf(&MyIMG, MyIMG.OrgX, mdMaxOrgY);
           firstDownDown = false;
           redrawIMG = true;
           startOrgY=MyIMG.OrgY;
         }
         if(timeDown>KeyBWaitStartScroll) {
           if((newOrg = startOrgY+((slowSpeedImg*(timeDown-KeyBWaitStartScroll)))) <= mdMaxOrgY)
             SetOrgSurf(&MyIMG, MyIMG.OrgX, newOrg);
           else
             SetOrgSurf(&MyIMG, MyIMG.OrgX, mdMaxOrgY);
           redrawIMG = true;
         }
       }
       else
         firstDownDown = true;
        
       // down
       if((IsKeyDown(0xd0) && Me->Focus) || (wheelDir==MsWheelScrollDir && Me->MsIn && (!Me->MsDown && !(MsButton&MS_RIGHT_BUTT)))) {
         timeDown = (float)(GetCurrTimeKeyDown(0xd0))/(float)(TimerFreq);
         if(timeDown<KeyBWaitStartScroll && firstUpDown) {
           if(MyIMG.OrgY-speedImg >= mdMinOrgY)
             SetOrgSurf(&MyIMG, MyIMG.OrgX, MyIMG.OrgY-speedImg);
           else
             SetOrgSurf(&MyIMG, MyIMG.OrgX, mdMinOrgY);
           redrawIMG = true;
           if(!wheelDir)
             firstUpDown = false;
           startOrgY=MyIMG.OrgY;
         }
         if(timeDown>KeyBWaitStartScroll) {

           if((newOrg = startOrgY-((slowSpeedImg*(timeDown-KeyBWaitStartScroll)))) >= mdMinOrgY)
             SetOrgSurf(&MyIMG, MyIMG.OrgX, newOrg);
           else
             SetOrgSurf(&MyIMG, MyIMG.OrgX, mdMinOrgY);
           redrawIMG = true;
         }
       }
       else
         firstUpDown = true;
       // Right
       if((IsKeyDown(0xcd) && Me->Focus) || (wheelDir==MsWheelScrollDir && Me->MsIn && (Me->MsDown || (MsButton&MS_RIGHT_BUTT)))) {
         timeDown = (float)(GetCurrTimeKeyDown(0xcd))/(float)(TimerFreq);
         if(timeDown<KeyBWaitStartScroll && firstRightDown) {
           if(MyIMG.OrgX+speedXImg <= mdMaxOrgX)
             SetOrgSurf(&MyIMG, MyIMG.OrgX+speedXImg, MyIMG.OrgY);
           else
             SetOrgSurf(&MyIMG, mdMaxOrgX, MyIMG.OrgY);
           redrawIMG = true;
           if(!wheelDir)
             firstRightDown = false;
           startOrgX=MyIMG.OrgX;
         }
         if(timeDown>KeyBWaitStartScroll) {
           if((newOrg = startOrgX+((slowSpeedXImg*(timeDown-KeyBWaitStartScroll)))) <= mdMaxOrgX)
             SetOrgSurf(&MyIMG, newOrg, MyIMG.OrgY);
           else
             SetOrgSurf(&MyIMG, mdMaxOrgX, MyIMG.OrgY);
           redrawIMG = true;
         }
       }
       else
         firstRightDown = true;
       // Left
       if((IsKeyDown(0xcb) && Me->Focus) || (wheelDir==-MsWheelScrollDir && Me->MsIn && (Me->MsDown || (MsButton&MS_RIGHT_BUTT)))) {
         timeDown = (float)(GetCurrTimeKeyDown(0xcb))/(float)(TimerFreq);
         if(timeDown<KeyBWaitStartScroll && firstLeftDown) {
           if(MyIMG.OrgX-speedXImg >= mdMinOrgX)
             SetOrgSurf(&MyIMG, MyIMG.OrgX-speedXImg, MyIMG.OrgY);
           else
             SetOrgSurf(&MyIMG, mdMinOrgX, MyIMG.OrgY);
           redrawIMG = true;
           if(!wheelDir)
             firstLeftDown = false;
           startOrgX=MyIMG.OrgX;
         }
         if(timeDown>KeyBWaitStartScroll) {
           if((newOrg = startOrgX-((slowSpeedXImg*(timeDown-KeyBWaitStartScroll)))) >= mdMinOrgX)
             SetOrgSurf(&MyIMG, newOrg, MyIMG.OrgY);
           else
             SetOrgSurf(&MyIMG, mdMinOrgX, MyIMG.OrgY);
           redrawIMG = true;
         }
       }
       else
         firstLeftDown = true;

       // handle image dragging using mouse
       if(!Me->MsDown) {
         AppliedMsDownDX =0;
         AppliedMsDownDY =0;
       }
       else {
         int oldOrgX = MyIMG.OrgX;
         int oldOrgY = MyIMG.OrgY;
         SetOrgSurf(&MyIMG,
           MyIMG.OrgX-((MsX-Me->MsXDown)-AppliedMsDownDX),
           MyIMG.OrgY-((MsY-Me->MsYDown)-AppliedMsDownDY));
         if(oldOrgX!=MyIMG.OrgX || oldOrgY!=MyIMG.OrgY) {
           AppliedMsDownDX -= (MyIMG.OrgX - oldOrgX);
           AppliedMsDownDY -= (MyIMG.OrgY - oldOrgY);
           redrawIMG = true;
         }
       }
         
       if(MyIMG.OrgX > mdMaxOrgX) {
         SetOrgSurf(&MyIMG, mdMaxOrgX, MyIMG.OrgY);
         redrawIMG = true;
       }
       if(MyIMG.OrgX < mdMinOrgX) {
         SetOrgSurf(&MyIMG, mdMinOrgX, MyIMG.OrgY);
         redrawIMG = true;
       }
       if(MyIMG.OrgY > mdMaxOrgY) {
         SetOrgSurf(&MyIMG, MyIMG.OrgX, mdMaxOrgY);
         redrawIMG = true;
       }
       if(MyIMG.OrgY < mdMinOrgY) {
         SetOrgSurf(&MyIMG, MyIMG.OrgX, mdMinOrgY);
         redrawIMG = true;
       }
     }
     
     if(redrawIMG) {
       if(MyIMGPlus>MyIMGMaxPlus) MyIMGPlus=MyIMGMaxPlus;
       if(MyIMGPlus<0) MyIMGPlus=0;
       Me->Redraw();
       redrawIMG = false;
     }
   }
   LastScanMsWheel = MsZ;
}

void ChgdCmbViewMode(String *S,int Sel)
{
  int oldDisplayMode=iDisplayMode;
  
  iDisplayMode = Sel;
  if(validMyIMG) {
    if(oldDisplayMode==2)
      UseCurImg = true;
    LoadCurImg();
    // if display mode was "AS is" then there is no need to reload the image
    GphBVideo->SetFocus();
  }
}

void OnOpen() {
   MultiAutoLoad = (EnableDefaultMultiLoad && ((KbFLAG & KB_ALT_PR)==0)) ||
                   (!EnableDefaultMultiLoad && ((KbFLAG & KB_ALT_PR)>0));

   if(MultiAutoLoad)
     FilesBox(WH,"Open multi/images", "Open", FBOpenImg, "Cancel", NULL, &LSImgName,
              &LSImgMask, iDefTypeOpen);
   else
     FilesBox(WH,"Open image", "Open", FBOpenImg, "Cancel", NULL, &LSImgName,
              &LSImgMask, iDefTypeOpen);

}

void OnNext() {
  if(CurImgNum < (LSFiles.NbElement()-1)) {
    CurImgNum++;
    LoadCurImg();
  }
}

void OnBack() {
  if(CurImgNum > 0) {
    CurImgNum--;
    LoadCurImg();
  }
}

void OnFirst() {
  if(LSFiles.NbElement()>0) {
    CurImgNum=0;
    LoadCurImg();
  }
}

void OnLast() {
  if(LSFiles.NbElement()>0) {
    CurImgNum=LSFiles.NbElement()-1;
    LoadCurImg();
  }
}

void OnAbout()
{
   // ---- About window
   MWAbout= new MainWin(screenX/2-200,screenY/2-130,400,270,"About",WH);
   if(MWAbout!=NULL) {
     GphBAbout= new GraphBox(5,30,390,240,MWAbout,WH->m_GraphCtxt->WinGris);
     GphBAbout->GraphBoxDraw=GphBDrawAbout; GphBAbout->Redraw();
     GphBAbout->ScanGraphBox=OnGphBScanAbout;
     BtOkAbout=new Button(115,3,275,25,MWAbout,"Ok",1,0);
     BtOkAbout->Click=BtOkAboutClick;
     MWAbout->Show(); // show about
     MWAbout->Enable(); // set as the active window
   }
}

void OnExit()
{
   ExitViewer = true;
}

void FileNumMakeFilter(String *fname, String *filter)
{
   int lngth = fname->Length();
   bool lastNum = false;
   int debScan = lngth-1;
   
   for(;debScan>=0;debScan--) {
     if(fname->StrPtr[debScan] == '\\' || fname->StrPtr[debScan] == '/') {
       debScan++;
       break;
     }
   }

   *filter ="";
   for(int i=debScan;i<lngth;i++) {
      if(isdigit(fname->StrPtr[i]) && !lastNum)
      {
        *filter += "*";
        lastNum = true;
      }
      if(!isdigit(fname->StrPtr[i])) {
        *filter += fname->StrPtr[i];
        lastNum = false;
      }
   }
}

void FillListImg(String *SFilter) {
   struct ffblk f;
   int done;
   LSFiles.ClearListStr();
   
   done= findfirst(SFilter->StrPtr, &f, FA_HIDDEN| FA_SYSTEM);
   while (!done) {
      if (!(f.ff_attrib&FA_DIREC))
        LSFiles.Add(f.ff_name);
      done = findnext(&f);
   }
   LSFiles.Sort(true);
   CurImgNum = 0;
}

void FBOpenImg(String *S,int TypeSel) {
  String ffilter;
  if(MultiAutoLoad) {
    FileNumMakeFilter(S, &ffilter);
    FillListImg(&ffilter);
  }
  else {
    LSFiles.ClearListStr();
    LSFiles.Add(S->StrPtr);
    CurImgNum = 0;
  }
  
  iDefTypeOpen = TypeSel;
  LoadCurImg();
}

void LoadCurImg() {
  String text;
  String *pStrImg;
  Surf tmpImg;
  Surf tmpSmthImg;
  float   rapSize = 1.0;
  int FinalResV = 0;
  int FinalResH = 0;
  int FinalOrgX = 0;
  int FinalOrgY = 0;
  int gphBoxWidth = GphBVideo->VGraphBox.MaxX-GphBVideo->VGraphBox.MinX+1;
  int gphBoxHeight = GphBVideo->VGraphBox.MaxY-GphBVideo->VGraphBox.MinY+1;


  if(validMyIMG) {
    if(!UseCurImg)
      DestroySurf(&MyIMG);
    if(SmoothResize && curZoom>=SmoothZoomLimit)
      DestroySurf(&MySmthIMG);
  }
  validMyIMG = false;
  redrawIMG = true;

  pStrImg = LSFiles[CurImgNum];
  if(!UseCurImg) {
    if(pStrImg != NULL) {
      if(!LoadImg(pStrImg->StrPtr, &tmpImg)) {
        sprintf(text.StrPtr,"Error loading image File %s\n",pStrImg->StrPtr);
        MessageBox(WH,"Error!", text.StrPtr,"Ok",NULL,NULL,NULL,NULL,NULL);
        MWDViewer->Label = MainWinName;
        return;
      }
    }
    if(tmpImg.ResV==0 || tmpImg.ResH==0)
      return;
  }
  else {
    tmpImg = MyIMG;
  }
  

  FREE_MMX();
  if (iDisplayMode==2) {
    MyIMG = tmpImg;
    rapSize = 1.0;
    FinalOrgX = -(gphBoxWidth - MyIMG.ResH) / 2;
    FinalOrgY = (gphBoxHeight - MyIMG.ResV) / 2;
    if (gphBoxWidth>MyIMG.ResH)
      mdMinOrgX = mdMaxOrgX = FinalOrgX;
    else {
      mdMinOrgX = FinalOrgX - ((MyIMG.ResH-gphBoxWidth) / 2);
      mdMaxOrgX = FinalOrgX + ((MyIMG.ResH-gphBoxWidth) / 2);
    }
    if (gphBoxHeight>=MyIMG.ResV)
      mdMinOrgY = mdMaxOrgY = FinalOrgY;
    else {
      mdMinOrgY = FinalOrgY - ((MyIMG.ResV-gphBoxHeight) / 2);
      mdMaxOrgY = FinalOrgY + ((MyIMG.ResV-gphBoxHeight) / 2);
    }
  }
  else {
    FinalResH=gphBoxWidth;
    rapSize = float(gphBoxWidth) / float(tmpImg.ResH);
    FinalResV = tmpImg.ResV * rapSize;

    if (iDisplayMode==1) { // fit
      if (FinalResV>(gphBoxHeight)) {
        rapSize = float(gphBoxHeight) /
                  float(tmpImg.ResV);
       FinalResH = tmpImg.ResH * rapSize;
       FinalResV = tmpImg.ResV * rapSize;
       FinalOrgX = -(gphBoxWidth - FinalResH) / 2;
     }
     else
       FinalOrgY = (gphBoxHeight - FinalResV) / 2;
    }
    if((CreateSurf(&MyIMG, FinalResH, FinalResV, 16)) == 0) {
      DestroySurf(&tmpImg);
      MessageBox(WH,"Error!", "No memory","Ok",NULL,NULL,NULL,NULL,NULL);
      MWDViewer->Label = MainWinName;
      return;
    }
    DownSize = (rapSize <= SmoothDownSizeLevel);
    if(DownSize && EnableSmoothDownSize &&
      (CreateSurf(&tmpSmthImg, tmpImg.ResH, tmpImg.ResV, 16) != 0)) {
      BlurSurf16(&tmpSmthImg,&tmpImg);
      FREE_MMX();
      if(rapSize<=EnhSmoothDownSizeLowLevel)
      {
        BlurSurf16(&tmpImg,&tmpSmthImg);
        DestroySurf(&tmpSmthImg);
        ResizeSurf16(&MyIMG,&tmpImg);
        DestroySurf(&tmpImg);
      }
      else {
        DestroySurf(&tmpImg);
        ResizeSurf16(&MyIMG,&tmpSmthImg);
        DestroySurf(&tmpSmthImg);
      }
    }
    else {
      ResizeSurf16(&MyIMG,&tmpImg);
      DestroySurf(&tmpImg);
    }
  }
  SetOrgSurf(&MyIMG,FinalOrgX,FinalOrgY);

  FREE_MMX();
  curZoom = rapSize;
  UseCurImg = false;
  validMyIMG = true;
  redrawIMG = true;
  firstUpDown = true;
  firstDownDown = true;
  initialIMGPlusDown=0; initialIMGPlusUp=0;
  MyIMGPlus =0;
  SmoothCurImg();
  FREE_MMX();
  curZoom = rapSize;
  if(LSFiles.NbElement()>1)
    sprintf(InfImg.StrPtr,"Img %i/%i - %ix%i %i%%",CurImgNum+1,LSFiles.NbElement(),
       tmpImg.ResH, tmpImg.ResV, (int)(rapSize*100.0));
  else
    sprintf(InfImg.StrPtr,"%ix%i %i%%",tmpImg.ResH, tmpImg.ResV, (int)(rapSize*100.0));
   // extract only filename without path or drive
  char tdrv[MAXDRIVE], tpath[MAXDIR], tfile[MAXFILE], te[MAXEXT];
  int which = fnsplit(pStrImg->StrPtr, tdrv, tpath, tfile, te);
  
  MWDViewer->Label = MainWinName + '<' + tfile + te + '>'+ InfImg;
  MWDViewer->Redraw();
  GphBVideo->SetFocus();
  FREE_MMX();
}

void SmoothCurImg()
{
  String text;
  Surf EnhSmthImg;
  
  FREE_MMX();
  if(SmoothResize && curZoom>=SmoothZoomLimit) {
    if((CreateSurf(&MySmthIMG, MyIMG.ResH, MyIMG.ResV, 16)) == 0) {
      sprintf(text.StrPtr,"Not enough memory to smooth!\n");
      MessageBox(WH,"Error!", text.StrPtr,"Ok",NULL,NULL,NULL,NULL,NULL);
      SmoothResize = false;
      return;
    }
    if(curZoom>=EnhSmoothZoomLimit) {
      if((CreateSurf(&EnhSmthImg, MyIMG.ResH, MyIMG.ResV, 16)) == 0) {
        BlurSurf16(&MySmthIMG,&MyIMG);
        SetOrgSurf(&MySmthIMG,MyIMG.OrgX,MyIMG.OrgY);
      }
      else {
        BlurSurf16(&EnhSmthImg,&MyIMG);
        BlurSurf16(&MySmthIMG,&EnhSmthImg);
        
/*        BlurSurf16(&EnhSmthImg,&MySmthIMG);
        BlurSurf16(&MySmthIMG,&EnhSmthImg);*/
        SetOrgSurf(&MySmthIMG,MyIMG.OrgX,MyIMG.OrgY);
        DestroySurf(&EnhSmthImg);
      }
    }
    else {
      BlurSurf16(&MySmthIMG,&MyIMG);
      SetOrgSurf(&MySmthIMG,MyIMG.OrgX,MyIMG.OrgY);
    }
  }
}

void LoadConfig()
{
  FILE *fConfig = fopen("DUGLVIEW.CFG","rt");
  String lineID(1024);
  String lineInfo(1024);
  String *sInfoName;
  ListString *LSParams;
  ListString *LSTmp;
  int i;
  
  if(fConfig == NULL)
    return;
  for(;;) {
    if(fgets(lineID.StrPtr, 1024, fConfig) == NULL) break;
    if(fgets(lineInfo.StrPtr, 1024, fConfig) == NULL) break;
    lineID.Del13_10();
    lineInfo.Del13_10();
    // remove comments
    LSTmp = lineID.Split(';');
    if(LSTmp != NULL) {
      lineID = *(*LSTmp)[0];
      delete LSTmp;
    }
    LSTmp = lineInfo.Split(';');
    if(LSTmp != NULL) {
      lineInfo = *(*LSTmp)[0];
      delete LSTmp;
    }
    //---
    if(lineID.Length()==0) break;
    if(lineInfo.Length()==0) break;
    // extract config
    sInfoName = lineID.SubString(0, '[', ']');
    LSParams = lineInfo.Split(',');
    
    if(*sInfoName == "VideoMode" && LSParams->NbElement() >= 2) {
      screenX = (*LSParams)[0]->GetInt();
      screenY = (*LSParams)[1]->GetInt();
    }
    else if(*sInfoName == "MousePosition" && LSParams->NbElement() >= 2) {
      DefMsPosX = (float)((*LSParams)[0]->GetDouble());
      if(DefMsPosX<0.0 || DefMsPosX>1.0) DefMsPosX = 0.5;
      DefMsPosY = (float)((*LSParams)[1]->GetDouble());
      if(DefMsPosY<0.0 || DefMsPosY>1.0) DefMsPosY = 0.5;
    }
    else if(*sInfoName == "KeyBWaitPageUP" && LSParams->NbElement() >= 2) {
      EnableKeyUpPrevPage = (bool)((*LSParams)[0]->GetInt());
      KeybWaitPrevPage = (float)((*LSParams)[1]->GetDouble());
      if(KeybWaitPrevPage<0.0) KeybWaitPrevPage = 0.5;
    }
    else if(*sInfoName == "KeyBWaitPageDOWN" && LSParams->NbElement() >= 2) {
      EnableKeyDownNextPage = (bool)((*LSParams)[0]->GetInt());
      KeybWaitNextPage = (float)((*LSParams)[1]->GetDouble());
      if(KeybWaitNextPage<0.0) KeybWaitNextPage = 0.25;
    }
    else if(*sInfoName == "KeyBWaitStartScroll" && LSParams->NbElement() >= 1) {
      KeyBWaitStartScroll = (float)((*LSParams)[0]->GetDouble());
      if(KeyBWaitStartScroll<0.0) KeybWaitNextPage = 0.25;
    }
    else if(*sInfoName == "SmoothDownSize" && LSParams->NbElement() >= 3) {
      EnableSmoothDownSize = (bool)((*LSParams)[0]->GetInt());
      SmoothDownSizeLevel = (float)((*LSParams)[1]->GetDouble());
      EnhSmoothDownSizeLowLevel = (float)((*LSParams)[2]->GetDouble());
      if(SmoothDownSizeLevel<=0.0 || SmoothDownSizeLevel>=1.0)
        SmoothDownSizeLevel = 0.7; // revert to default value
      if(EnhSmoothDownSizeLowLevel <0.0 || EnhSmoothDownSizeLowLevel>=SmoothDownSizeLevel)
        EnhSmoothDownSizeLowLevel = SmoothDownSizeLevel/3.0;
    }
    else if(*sInfoName == "SmoothZoom" && LSParams->NbElement() >= 3) {
      SmoothResize = (bool)((*LSParams)[0]->GetInt());
      SmoothZoomLimit = (float)((*LSParams)[1]->GetDouble());
      EnhSmoothZoomLimit = (float)((*LSParams)[2]->GetDouble());
      if(SmoothZoomLimit<=1.0)
        SmoothDownSizeLevel = 1.6; // revert to default value
      if(EnhSmoothZoomLimit <=SmoothZoomLimit)
        EnhSmoothDownSizeLowLevel = SmoothDownSizeLevel*2.0;
    }
    else if(*sInfoName == "MsWheelScrollDir" && LSParams->NbElement() >= 1) {
      MsWheelScrollDir = (*LSParams)[0]->GetInt();
      if(MsWheelScrollDir!=1 && MsWheelScrollDir!=-1)
        MsWheelScrollDir = 1;
    }
    else if(*sInfoName == "DefaultTypeOpen" && LSParams->NbElement() >= 1) {
      iDefTypeOpen = (*LSParams)[0]->GetInt();
      if(iDefTypeOpen<0 || iDefTypeOpen>7)
        iDefTypeOpen = 0;
    }
    else if(*sInfoName == "EnableDefaultMultiLoad" && LSParams->NbElement() >= 1) {
      EnableDefaultMultiLoad = (*LSParams)[0]->GetInt();
      if(EnableDefaultMultiLoad<0 || EnableDefaultMultiLoad>1)
        EnableDefaultMultiLoad = 0;
    }
    else if(*sInfoName == "ImageDisplayMode" && LSParams->NbElement() >= 1) {
      iDisplayMode = (*LSParams)[0]->GetInt();
      if(iDisplayMode<0 || iDisplayMode>2)
        iDisplayMode = 0;
    }
    else if(*sInfoName == "CheckWinNT" && LSParams->NbElement() >= 1) {
      CheckWinNT = (*LSParams)[0]->GetInt();
    }



    delete sInfoName;
    delete LSParams;
  }
  fclose(fConfig);
}
// DUGL Util ----------------------------------------------------
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

bool LoadImg(char *filename, Surf *DstSurf)
{
   Surf Surf8bpp;
   if(!IsFileExist(filename))
     return false;
   if (LoadBMP16(DstSurf,filename)!=0)
      return true;
   if (LoadPNG16(DstSurf,filename)!=0)
      return true;
   if (LoadJPG16(DstSurf,filename)!=0)
      return true;
      
   if (LoadBMP(&Surf8bpp,filename,palette)!=0) {
      if (CreateSurf(DstSurf, Surf8bpp.ResH, Surf8bpp.ResV, 16)==0) {
        DestroySurf(&Surf8bpp);
        return false;
      }
      ConvSurf8ToSurf16Pal(DstSurf,&Surf8bpp,&palette);
      DestroySurf(&Surf8bpp);
      return true;
   }
   if (LoadGIF(&Surf8bpp,filename,palette)!=0) {
      if (CreateSurf(DstSurf, Surf8bpp.ResH, Surf8bpp.ResV, 16)==0) {
        DestroySurf(&Surf8bpp);
        return false;
      }
      ConvSurf8ToSurf16Pal(DstSurf,&Surf8bpp,&palette);
      DestroySurf(&Surf8bpp);
      return true;
   }
   if (LoadPCX(&Surf8bpp,filename,palette)!=0) {
      if (CreateSurf(DstSurf, Surf8bpp.ResH, Surf8bpp.ResV, 16)==0) {
        DestroySurf(&Surf8bpp);
        return false;
      }
      ConvSurf8ToSurf16Pal(DstSurf,&Surf8bpp,&palette);
      DestroySurf(&Surf8bpp);
      return true;
   }
   return false;
}

bool IsFileExist(const char *fname) {
    struct ffblk f;
    if (findfirst(fname, &f, FA_HIDDEN | FA_SYSTEM)==0)
       return true;
    return false;
}

// about window ---------
// MWAbout events
void BtOkAboutClick() {
  MWDViewer->Enable(); // enable main win and delete About Window
  if(MWAbout!=NULL) {
    MWAbout->Hide();
    delete MWAbout;
    MWAbout=NULL;
  }
}

void OnGphBScanAbout(GraphBox *Me) {

}

void GphBDrawAbout(GraphBox *Me) {
   String text;
   int xImgLic,yImgLic;
   ClearSurf16(WH->m_GraphCtxt->WinNoir);
   ClearText();
   SetTextCol(WH->m_GraphCtxt->WinBlanc);
   OutText16Mode("\n", AJ_MID);
   FntCol=0x3F<<5; // green
   OutText16Mode("DUGL Viewer 0.4 - DOS Image Viewer\n", AJ_MID);
   FntCol=0xFFFF; // white
   OutText16Mode("(C) By FFK 21 August 2011\n\n", AJ_MID);
   OutText16Mode("Developped using :\n", AJ_MID);
   FntCol=0x1F; // green
   sprintf(text.StrPtr,"DUGL %s & DUGL+ %s \n",DUGL_VERSION,DUGLP_VERSION);
   OutText16Mode(text.StrPtr, AJ_MID);
   FntCol=0xFFFF; // white
   OutText16Mode("dugl.50webs.com\n", AJ_MID);
   FntCol=0x1F; // green
   OutText16Mode("DJGPP C/C++ complier \n", AJ_MID);
   FntCol=0xFFFF; // white
   OutText16Mode("www.delorie.com/djgpp/\n", AJ_MID);
   FntCol=0x1F; // green
   sprintf(text.StrPtr,"Libjpeg, Zlib, Libpng\n\n");
   OutText16Mode(text.StrPtr, AJ_MID);
   if(validMyIMG) {
     sprintf(text.StrPtr,"Current Image Inf: %s\n",InfImg.StrPtr);
     FntCol=0xFFFF; // white
     OutText16Mode(text.StrPtr, AJ_MID);
   }
   FREE_MMX();

}

