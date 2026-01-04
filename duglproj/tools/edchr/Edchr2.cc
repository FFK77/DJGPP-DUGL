/*  DUGL Dos Ultimate Game Library - DUGL CHR font format Editor alpha 0.1 */
/*  History : */
/*  ?? ??   2002 : first release */
/*  11 august 2009 : updated with DUGL Plus 0.3 GUI */

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
#include <dir.h>
#include <dugl.h>
#include <duglplus.h>

#ifdef __cplusplus
extern "C" {
#endif
  void RightShiftLine(void *DD0,void *DD1);
  void LeftShiftLine(void *DD0,void *DD1);
#ifdef __cplusplus
	   }
#endif

int  CalcSizeDataCar();
int  CalcSizeData1Car(int Ascii);
int  SaveCHR(char *FName);
int  ReadCHR(char *FName);
void SetSnsLR(),SetSnsRL();

char *TSChrName[]={ "CHR Font file", "All Files(*.*)" };
char *TSChrMask[]={ "*.chr", "*.*" };
ListString LSChrName(2,TSChrName),LSChrMask(2,TSChrMask);
char *TSImgName[]={ "GIF", "PCX", "All Files(*.*)" };
char *TSImgMask[]={ "*.gif", "*.pcx", "*.*" };
ListString LSImgName(3,TSImgName),LSImgMask(3,TSImgMask);
int car[2][256*64];
Caract InfCar[256];
unsigned int CopyCar[2][64];
Caract CopyInfCar;
unsigned char palette[1024],mpalette[1024];
Surf *SMouse, *SImg;
FONT F1;
KbMAP *KM;
View MsV;
FILE *Pal;
unsigned int OldTime,resh=640,resv=480,Yellow,ExitNow=0;
char FSens;
String SCurFile,SLbFPrinc("Edchr");
// GUI **********************************************
//***************************************************
// evenements -----------
// FPrinc --
void OpenCHR(String *S,int TypeSel);
void MenuNew(),MenuOpen(),MenuSave(),MenuSaveAs(),Exit();
void MenuLoadImage();
void ChgdAscii(int val),GphBDrawMap(GraphBox *Me);
void GphBDrawCar(GraphBox *Me),ScanGphBMap(GraphBox *Me);
void ChgdHeight(int val),ChgdWidth(int val),ChgdPlusX(int val);
void ChgdPlusLn(int val);
void ChgdSensFnt(char vtrue);
// FOuvrImg --
void ExitOuvrImg();
// Gestionnaire des fenˆtres
WinHandler *WH;
// windows -------------
MainWin *FPrinc,*FOuvrImg;
// FPrinc --
Menu *Mn;
Label *LbNmAscii,*LbAscii,*LbNmHeight,*LbHeight,*LbNmWidth,*LbWidth;
Label *LbNmPlusX,*LbPlusX,*LbNmPlusLn,*LbPlusLn;
HzScrollBar *HzSBAscii,*HzSBHeight,*HzSBWidth,*HzSBPlusX;
VtScrollBar *VtSBPlusLn;
ContBox *CtBSensFnt;
OptionButt *OpBtSnsLR,*OpBtSnsRL;
GraphBox *GphBCarMap,*GphBCarDraw;
// FOuvrImg --
Button *BtCancelOI,*BtOIOkOI,*BtSelCol,*BtSelMskCol;

// Menu -----------------
NodeMenu TNM[]= {
  { "",	                    3,  &TNM[1], 1, NULL } ,
  { "File",                 6,  &TNM[4], 1, NULL } ,   // 1
  { "Edit",                 5, &TNM[10], 1, NULL } ,
  { "Help",                 2, &TNM[15], 1, NULL } ,
  { "New",                  0,     NULL, 1, MenuNew } ,
  { "Open        F3",       0,     NULL, 1, MenuOpen } ,
  { "Save        F2",       0,     NULL, 1, MenuSave } ,
  { "Save as...",           0,     NULL, 1, MenuSaveAs } ,
  { "",                     0,     NULL, 1, NULL } ,
  { "Exit     Alt+X",       0,     NULL, 1, Exit } ,
  { "Copy        Ctrl+Ins", 0,     NULL, 1, NULL } ,   // 10
  { "Paste      Shift+Ins", 0,     NULL, 1, NULL } ,
  { "",                     0,     NULL, 1, NULL } ,
  { "Load image        F4", 0,     NULL, 1, MenuLoadImage } ,
  { "Import character  F5", 0,     NULL, 1, NULL } ,
  { "Help   F1",            0,     NULL, 1, NULL } ,
  { "About",                0,     NULL, 1, NULL }
  };

int main(int argc,char *argv[]) {
   int i,j,k,l;
   if (!InitVesa()) { printf("VESA error\n"); exit(-1); }
   if ((Pal=fopen("3dpal.pal","rb"))==NULL) {
     printf("3dpal.pal introuvable\n"); exit(-1); }
   fread(&palette,1024,1,Pal);
   fclose(Pal);
   //InitPaletteGUI(&palette);
   if (!LoadFONT(&F1,"hello.chr")) {
     printf("hello.chr introuvable\n"); exit(-1); }
   if (!LoadKbMAP(&KM,"kbmap.map")) {
     printf("kbmap.map introuvable\n"); exit(-1); }

   if (!InstallMouse()) {
     printf("Mouse error\n"); exit(-1); }
   if (!DgInstallTimer(300)) {
     UninstallMouse(); printf("Timer error\n"); exit(-1); }
   if (!InstallKeyboard()) {
     DgUninstallTimer(); UninstallMouse();
     printf("Keyboard error\n"); exit(-1); }
   if (!SetKbMAP(KM)) {
     DgUninstallTimer(); UninstallMouse();
     printf("Set KbMap error\n"); UninstallKeyboard(); exit(-1); }

   if (!LoadGIF(&SMouse,"mouseimg.gif",&mpalette)) {
     DgUninstallTimer(); UninstallMouse(); UninstallKeyboard();
     printf(" impossible d'ouvrir mouseimg.gif\n");
     exit(-1);
   }


  if (!InitVesaMode(resh,resv,8,3)) {
    DgUninstallTimer(); UninstallMouse(); UninstallKeyboard();
    CloseVesa();
    printf("error init vesa mode\n");
    exit(0);
  }

  FREE_MMX();
  Yellow=FindCol(0,255,0,255,0,&palette);
  FREE_MMX();
  SetPalette(0,256,&palette);
  SetFONT(&F1);
  SetOrgSurf(SMouse,0,SMouse->ResV-1);
  GetSurfView(&VSurf[0],&MsV);
  SetMouseView(&MsV);
  SetMousePos(VSurf[0].ResH/2,VSurf[0].ResV/2);

  FREE_MMX();
  WH = new WinHandler(640,480,8,83,&palette);
//---- Windows
  FPrinc= new MainWin(0,0,640,480,SLbFPrinc.StrPtr,WH);
//  FOuvrImg= new MainWin(50,50,540,380,"Open Image File",WH);
//---- FPrinc
  Mn = new Menu(FPrinc,&TNM[0]);
  LbNmAscii= new Label(5,5,50,25,FPrinc,"Ascii",AJ_LEFT);
  LbAscii=new Label(50,5,80,25,FPrinc,"1",AJ_LEFT);
  HzSBAscii= new HzScrollBar(81,395,8,FPrinc,1,255);
  HzSBAscii->Changed=ChgdAscii;
  LbNmPlusX= new Label(395,94,439,114,FPrinc,"PlusX",AJ_LEFT);
  LbPlusX= new Label(439,94,467,114,FPrinc,"0",AJ_LEFT);
  HzSBPlusX= new HzScrollBar(468,632,97,FPrinc,0,127);
  HzSBPlusX->Changed=ChgdPlusX;
  LbNmHeight= new Label(395,72,445,92,FPrinc,"Height",AJ_LEFT);
  LbHeight= new Label(445,72,465,92,FPrinc,"1",AJ_LEFT);
  HzSBHeight= new HzScrollBar(466,630,75,FPrinc,1,64);
  HzSBHeight->Changed=ChgdHeight;
  LbNmWidth= new Label(395,50,445,70,FPrinc,"Width",AJ_LEFT);
  LbWidth= new Label(445,50,465,70,FPrinc,"1",AJ_LEFT);
  HzSBWidth= new HzScrollBar(466,630,53,FPrinc,1,64);
  HzSBWidth->Changed=ChgdWidth;
  LbNmPlusLn=  new Label(500,143,560,163,FPrinc,"PlusLn",AJ_LEFT);
  LbPlusLn=  new Label(561,143,600,163,FPrinc,"0",AJ_LEFT);
  VtSBPlusLn= new VtScrollBar(483,144,421,FPrinc,-127,127);
  VtSBPlusLn->SetVal(0); VtSBPlusLn->Changed=ChgdPlusLn;
  CtBSensFnt=new ContBox(396,7,630,47,FPrinc,"Direction");
    OpBtSnsLR=new OptionButt(0,0,110,20,FPrinc,CtBSensFnt,"Left-Right",1);
    OpBtSnsLR->Changed=ChgdSensFnt;
    OpBtSnsRL=new OptionButt(110,0,220,20,FPrinc,CtBSensFnt,"Right-Left",0);
    OpBtSnsRL->Changed=ChgdSensFnt;
  GphBCarMap= new GraphBox(5,30,395,420,FPrinc,WH->m_GraphCtxt->WinGris);
  GphBCarMap->GraphBoxDraw=GphBDrawMap;
  GphBCarMap->ScanGraphBox=ScanGphBMap; GphBCarMap->Redraw();
  GphBCarDraw= new GraphBox(500,164,629,420,FPrinc,WH->m_GraphCtxt->WinGris);
  GphBCarDraw->GraphBoxDraw=GphBDrawCar;  GphBCarDraw->Redraw();
//---- FOuvrImg
/*  BtOIOkOI=new Button(440,315,530,340,FOuvrImg,"Ok",0,0);
  BtCancelOI=new Button(440,285,530,310,FOuvrImg,"Cancel",0,1);
  BtCancelOI->Click=ExitOuvrImg;
  BtSelCol=new Button(440,255,530,280,FOuvrImg,"Color",0,0);
  BtSelMskCol=new Button(440,225,530,250,FOuvrImg,"Mask Color",0,0);
  FOuvrImg->Show();*/
//**************
  if (argc>1) {
    SCurFile=argv[1];
    strlwr(SCurFile.StrPtr);
    OpenCHR(&SCurFile,0);
  }
  else
    MenuNew();
  OldTime=DgTime;
  for (j=0;;j++) {
    if ((DgTime-OldTime)<(DgTimerFreq/CurModeVtFreq)) WaitRetrace();
    OldTime=DgTime;

    ViewSurf(j%3);
    SetSurf(&VSurf[(j+1)%3]);

    // create a screenshot
    // tab + ctrl + shift
    if (IsKeyDown(KB_KEY_ESC) && (KbFLAG&KB_SHIFT_PR) && (KbFLAG&KB_CTRL_PR))
       SavePCX(&VSurf[j%3],"edchr.pcx",&palette);

    WH->Scan();
    WH->DrawSurf(&CurSurf);
    PutMaskSurf(SMouse,MsX,MsY,0);
    if (WH->Key== KB_KEY_QWERTY_X && /* 'X'|'x' */ (WH->KeyFLAG&KB_ALT_PR))
       ExitNow=1;

    if (WH->CurWinNode->Item==FPrinc) {
      switch (WH->Key) {
        case KB_KEY_F1 :   // F1
          break;
        case KB_KEY_F2 :   // F2
          MenuSave();
          break;
        case KB_KEY_F3 :   // F3
          MenuOpen();
          break;
        case KB_KEY_F4 :   // F4
          MenuLoadImage();
          break;
        case KB_KEY_F5 :   // F5
//          FOuvrImg->Move(50,50);
//          FOuvrImg->Enable();
          break;
      }
    }
    if (ExitNow==1) break; // quit the app
  }

  DestroySurf(SMouse);
  CloseVesa();

  UninstallKeyboard();
  DgUninstallTimer();
  UninstallMouse();
  return 0;
}

int ReadCHR(char *FName) {
   HeadCHR hchr;
   int i,j,k,l,h,BPtr,Size;
   void *Buff;
   FILE *InCHR;

   if ((InCHR=fopen(FName,"rb"))==NULL) {
       MessageBox(WH,"can't open file", FName,
         "Ok", NULL, NULL, NULL, NULL, NULL);
       return 0;
   }
/*   MessageBox(WH,"file exist", FName,
         "Ok", NULL, NULL, NULL, NULL, NULL);
*/
   fread(&hchr,sizeof(HeadCHR),1,InCHR);
   if (hchr.Sign!='RHCF') { fclose(InCHR); return 0; }

/*   MessageBox(WH,"valid header", FName,
         "Ok", NULL, NULL, NULL, NULL, NULL);
*/
   for (i=0;i<256;i++) InfCar[i]=hchr.C[i];
   if (hchr.SizeDataCar!=CalcSizeDataCar())
   { fclose(InCHR); return 0; }
   if ((Buff=malloc(hchr.SizeDataCar))==NULL) {
        MessageBox(WH,"Error", "No Mem !",
       "Ok", NULL, NULL, NULL, NULL, NULL);
     fclose(InCHR); return 0;
   }
   fseek(InCHR,hchr.PtrBuff,SEEK_SET);
   fread(Buff,hchr.SizeDataCar,1,InCHR);
   for (BPtr=0,i=1;i<256;i++) {
     hchr.C[i].DatCar=BPtr;
     l=(InfCar[i].Lg<=32)?1:2;
     h=InfCar[i].Ht;
     for (k=0;k<h;k++)
       for (j=0;j<l;j++)
         car[j][i*64+k]=((int *)((int)(Buff)+BPtr))[k*l+j];
     BPtr+=CalcSizeData1Car(i);
   }
   FSens=hchr.SensFnt;
   free(Buff);
   fclose(InCHR);
   return 1;
}
int SaveCHR(char *FName) {
   HeadCHR hchr;
   int i,j,k,l,h,BPtr,Size;
   void *Buff;
   FILE *OutCHR;

   if ((OutCHR=fopen(FName,"wb"))==NULL) return 0;
   if ((Buff=malloc(Size=CalcSizeDataCar()))==NULL) {
	  fclose(OutCHR); return 0;
   }
   for (i=0;i<Size/4;i++) ((int*)(Buff))[i]=0;
   for (i=0;i<28;i++) hchr.Resv[i]=0;
   hchr.Sign='RHCF';
   hchr.SensFnt=FSens;
   hchr.PtrBuff=sizeof(HeadCHR);
   for (i=0;i<256;i++) hchr.C[i]=InfCar[i];

   for (h=hchr.C[1].PlusLgn,i=2;i<256;i++)   // Max BasLgn
     h=(h>hchr.C[i].PlusLgn)?hchr.C[i].PlusLgn:h;
   hchr.MinPlusLgn=h;
   for (h=hchr.C[1].PlusLgn+(hchr.C[1].Ht-1),i=2;i<256;i++)// Max HautLgn
   h=(h<(hchr.C[i].PlusLgn+(hchr.C[i].Ht-1))) ?
     (hchr.C[i].PlusLgn+(hchr.C[i].Ht-1)):h;
   hchr.MaxHautLgn=h;

   hchr.MaxHautFnt=hchr.MaxHautLgn-hchr.MinPlusLgn+1;

   for (BPtr=0,i=1;i<256;i++) {
     hchr.C[i].DatCar=BPtr;
     l=(InfCar[i].Lg<=32)?1:2;
     h=InfCar[i].Ht;
     for (k=0;k<h;k++)
       for (j=0;j<l;j++)
         ((int *)((int)(Buff)+BPtr))[k*l+j]=car[j][i*64+k];
     BPtr+=CalcSizeData1Car(i);
   }
   hchr.SizeDataCar=BPtr;
   if (fwrite(&hchr,sizeof(HeadCHR),1,OutCHR)<1) {
     free(Buff); fclose(OutCHR); return 0; }
   if (fwrite(Buff,BPtr,1,OutCHR)<1) {
     free(Buff); fclose(OutCHR); return 0; }
   free(Buff);
   fclose(OutCHR);
   return 1;
}
int CalcSizeDataCar() {
   int i,Sz;
   for (Sz=0,i=1;i<256;i++)
   Sz+=((InfCar[i].Lg<=32)?1:2)*InfCar[i].Ht*4;
   return Sz;
}
int CalcSizeData1Car(int Ascii) {
   return ((InfCar[Ascii].Lg<=32)?1:2)*InfCar[Ascii].Ht*4;
}
void SetSnsLR() {
   for (int i=1;i<256;i++)
     InfCar[i].PlusX=abs(InfCar[i].PlusX);
    OpBtSnsLR->SetTrue(1);
}
void SetSnsRL() {
   for (int i=1;i<256;i++)
     InfCar[i].PlusX=-abs(InfCar[i].PlusX);
    OpBtSnsRL->SetTrue(1);
}
// evenements -----------
// FPrinc --
void MenuNew() {
   int i,j;
   int ht,lg,plsx,plsln;

   ht=HzSBHeight->GetVal();
   lg=HzSBWidth->GetVal();
   plsx=(OpBtSnsLR->True)?HzSBPlusX->GetVal():(-HzSBPlusX->GetVal());
   plsln=VtSBPlusLn->GetVal();
   bzero(car,sizeof(int)*2*256*64);
   for (i=0;i<256;i++) {
     InfCar[i].Ht=ht;
     InfCar[i].Lg=lg;
     InfCar[i].PlusX=plsx;
     InfCar[i].PlusLgn=plsln;
   }
   GphBCarMap->Redraw();
   GphBCarDraw->Redraw();
   SCurFile="";
   FPrinc->Label=SLbFPrinc;
   FPrinc->Redraw();
}
void MenuOpen() {
   FilesBox(WH,"Open", "Open", OpenCHR, "Cancel", NULL, &LSChrName,
            &LSChrMask, 0);
}
void MenuSave() {
   if (strlen(SCurFile.StrPtr)==0) {
     MenuSaveAs();
     return;
   }
   if (!SaveCHR(SCurFile.StrPtr))
     MessageBox(WH,"Error", "can't save file !",
                "Ok", NULL, NULL, NULL, NULL, NULL);
}
void Exit() {
   ExitNow = 1;
}

//-------
void FSaveCHR(String *S,int TypeSel);
void MenuSaveAs() {
   FilesBox(WH,"Save as...", "Save", FSaveCHR, "Cancel", NULL, &LSChrName,
            &LSChrMask, 0);
}
void FSaveCHR(String *S,int TypeSel) {
   String S2=*S;
   char d[MAXDRIVE], p[MAXDIR], f[MAXFILE], e[MAXEXT];
   int which = fnsplit(S2.StrPtr, d, p, f, e);
   if (!(which&EXTENSION))
     S2+=".chr";
   else {
     fnmerge(S2.StrPtr, d, p, f, ".chr");
   }
   if (!SaveCHR(S2.StrPtr))
     MessageBox(WH,"Error", "can't save file !",
                "Ok", NULL, NULL, NULL, NULL, NULL);
   else {
     SCurFile=S2;
     strlwr(SCurFile.StrPtr);
     FPrinc->Label=SLbFPrinc+"  "+SCurFile;
     FPrinc->Redraw();
   }
}
//-------
void MenuLoadImage() {
   FilesBox(WH,"Load image", "Load", NULL, "Cancel", NULL, &LSImgName,
            &LSImgMask, 0);
}
/*void OuvrTextFlBx(String *S,int typesel) {
   int FSize;
   char palbgra[1024],err=0;
   DestroySurf(&SText);
   if (DataFile) { free(DataFile); DataFile=NULL; }
   TypeTextFile=DefTypeText=typesel;
   if ((FlText=fopen(S->StrPtr,"rb"))==NULL) err=1;
   else {
     fseek(FlText,0,SEEK_END);
     SizeTextFile=FSize=ftell(FlText);
     if ((DataFile=malloc(FSize))==NULL) { err=1; fclose(FlText); }
     else {
       fseek(FlText,0,SEEK_SET);
       fread(DataFile,FSize,1,FlText);
       fclose(FlText);
     }
   }
   if (typesel==0) {
     if (!LoadMemGIF(&SText,DataFile,&palbgra,FSize)) err=1;
   }
   else
     if (typesel==1)
       if (!LoadMemPCX(&SText,DataFile,&palbgra,FSize)) err=1;
   if (err) {
     MessageBox(WH,"Erreur", "Fichier introuvable ou invalide !",
                "Ok", NULL, NULL, NULL, NULL, NULL);
     free(DataFile); DataFile=NULL; FSize=0; LbInfText->Text="";
   }
   else {
     TextPlusX=TextPlusY=0;
     GphBTexture->Redraw();
     LbInfText->Text=SText.ResH;
     LbInfText->Text=LbInfText->Text+"x"+SText.ResV+" "+FSize+" octets";
   }
} */
//-------
void ChgdAscii(int val) {
   LbAscii->Text=val;
   HzSBHeight->SetVal(InfCar[val].Ht);
   HzSBWidth->SetVal(InfCar[val].Lg);
   HzSBPlusX->SetVal(abs(InfCar[val].PlusX));
   VtSBPlusLn->SetMinMaxVal(-127,127-InfCar[val].Ht);
   VtSBPlusLn->SetVal(InfCar[val].PlusLgn);
   GphBCarMap->Redraw();
   GphBCarDraw->Redraw();
}
void ChgdHeight(int val) {
   int curascii=HzSBAscii->GetVal();
   LbHeight->Text=val;
   if (InfCar[curascii].Ht!=val) {
     InfCar[curascii].Ht=val;
     VtSBPlusLn->SetMinMaxVal(-127,127-InfCar[curascii].Ht);
     if (InfCar[curascii].Ht+InfCar[curascii].PlusLgn>127)
       VtSBPlusLn->SetVal(127-InfCar[curascii].Ht);
     GphBCarMap->Redraw();
   }
}
void ChgdWidth(int val) {
   int curascii=HzSBAscii->GetVal();
   LbWidth->Text=val;
   if (InfCar[curascii].Lg!=val) {
     InfCar[curascii].Lg=val;
     HzSBPlusX->SetVal(val);
     GphBCarMap->Redraw();
   }
}
void ChgdPlusX(int val) {
   int curascii=HzSBAscii->GetVal();
   LbPlusX->Text=val;
   if (abs(InfCar[curascii].PlusX)!=val) {
     InfCar[curascii].PlusX=(OpBtSnsLR->True)?val:(-val);
     GphBCarDraw->Redraw();
   }
}
void ChgdPlusLn(int val) {
   int curascii=HzSBAscii->GetVal();
   LbPlusLn->Text=val;
   if (InfCar[curascii].PlusLgn!=val) {
     InfCar[curascii].PlusLgn=val;
     GphBCarDraw->Redraw();
   }
}
void GphBDrawMap(GraphBox *Me) {
   int zstep=6;
   int curascii=HzSBAscii->GetVal(),
       LargGB=CurSurf.MaxX-CurSurf.MinX,HautGB=CurSurf.MaxY-CurSurf.MinY;
   int LargChar=InfCar[curascii].Lg,HautChar=InfCar[curascii].Ht;
   int LargRect=LargChar*zstep,HautRect=HautChar*zstep;
   int MidX=(CurSurf.MaxX+CurSurf.MinX)/2,MidY=(CurSurf.MaxY+CurSurf.MinY)/2;
   int DebX=MidX-LargRect/2,DebY=MidY-HautRect/2;
   int i,j;
   ClearSurf(WH->m_GraphCtxt->WinGrisF);
   for (i=0;i<HautChar;i++)
     for (j=0;j<LargChar;j++)
       if (car[j>>5][i+curascii*64]&(1<<(j&0x1f)))
         bar(DebX+j*zstep,DebY+i*zstep,
             DebX+(j+1)*zstep-1,DebY+(i+1)*zstep-1,Yellow);
   rect(DebX,DebY,DebX+LargRect,DebY+HautRect,WH->m_GraphCtxt->WinBlanc);
   for (j=1;j<HautChar;j++)
     for (i=1;i<LargChar;i++)
       cputpixel(DebX+i*zstep,DebY+j*zstep,WH->m_GraphCtxt->WinBleuF);
}
void GphBDrawCar(GraphBox *Me) {
   int i,j,curascii=HzSBAscii->GetVal(),plsx;
   ClearSurf(WH->m_GraphCtxt->WinGrisF);
   line(0,128,128,128,WH->m_GraphCtxt->WinBlanc);
   plsx=(InfCar[curascii].PlusX>=0)?0:(128+InfCar[curascii].PlusX);
   for (i=0;i<InfCar[curascii].Ht;i++)
     for (j=0;j<InfCar[curascii].Lg;j++)
       if (car[j>>5][i+curascii*64]&(1<<(j&0x1f)))
         cputpixel(plsx+j,i+128+InfCar[curascii].PlusLgn,Yellow);
}
void OpenCHR(String *S,int TypeSel) {
   int i;
   if (!ReadCHR(S->StrPtr)) {
     MessageBox(WH,"Error", "File invalide or not found !",
       "Ok", NULL, NULL, NULL, NULL, NULL);
     SCurFile=""; return;
   }
   HzSBAscii->SetVal(1);
   ChgdAscii(1);
   for (i=1;i<256;i++) {
     if (InfCar[i].PlusX>0) { SetSnsLR(); break; }
     if (InfCar[i].PlusX<0) { SetSnsRL(); break; }
   }
   if (i<256) SetSnsLR();
   SCurFile=*S;
   strlwr(SCurFile.StrPtr);
   FPrinc->Label=SLbFPrinc+"  "+SCurFile;
   FPrinc->Redraw();
}
void ChgdSensFnt(char vtrue) {
   if (vtrue) {
     if (OpBtSnsLR->True)
       SetSnsLR();
     else
       SetSnsRL();
     GphBCarDraw->Redraw();
   }
}
void ScanGphBMap(GraphBox *Me) {
   int zstep=6,redr=0;
   int curascii=HzSBAscii->GetVal(),
       LargGB=CurSurf.MaxX-CurSurf.MinX,HautGB=CurSurf.MaxY-CurSurf.MinY;
   int LargChar=InfCar[curascii].Lg,HautChar=InfCar[curascii].Ht;
   int LargRect=LargChar*zstep,HautRect=HautChar*zstep;
   int MidX=(CurSurf.MaxX+CurSurf.MinX)/2,MidY=(CurSurf.MaxY+CurSurf.MinY)/2;
   int DebX=MidX-LargRect/2,DebY=MidY-HautRect/2;
   int x,y,mousex=Me->MouseX,mousey=Me->MouseY;
   int i,j;
   long long LineShift;
   if (MsButton&1)
     if ( mousex>=DebX && mousey>=DebY &&
        mousex<=(DebX+LargRect-1) && mousey<=(DebY+HautRect-1) ) {
       x=(mousex-DebX)/zstep;
       y=(mousey-DebY)/zstep;
       if ( IsKeyDown(32) &&     // D
            (!( car[x>>5][y+curascii*64] & (1<<(x&0x1f)) )) ) {
         if (x>0)
	   for (i=x-1;i>=0;i--) {
	     if (car[i>>5][y+curascii*64] & (1<<(i&0x1f))) break;
	     car[i>>5][y+curascii*64] |= 1<<(i&0x1f);
	   }
         if (x<64)
	   for (i=x+1;i<65;i++) {
	     if (car[i>>5][y+curascii*64] & (1<<(i&0x1f))) break;
	     car[i>>5][y+curascii*64] |= 1<<(i&0x1f);
	   }
         redr=1;
       }
       if (!( car[x>>5][y+curascii*64] & (1<<(x&0x1f)) )) {
         car[x>>5][y+curascii*64] |= 1<<(x&0x1f);
         redr=1;
       }
     }

   if (MsButton&2)
     if ( mousex>=DebX && mousey>=DebY && mousex<=(DebX+LargRect-1) &&
          mousey<=(DebY+HautRect-1) ) {
       x=(Me->MouseX-DebX)/zstep;
       y=(Me->MouseY-DebY)/zstep;
       if ( IsKeyDown(32) &&     // D
          ( car[x>>5][y+curascii*64] & (1<<(x&0x1f)) ) ) {
         if (x>0)
  	   for (i=x-1;i>=0;i--) {
	     if (!(car[i>>5][y+curascii*64] & (1<<(i&0x1f)))) break;
	     car[i>>5][y+curascii*64] &= (1<<(i&0x1f))^0xffffffff;
	   }
         if (x<64)
  	   for (i=x+1;i<65;i++) {
	     if (!(car[i>>5][y+curascii*64] & (1<<(i&0x1f)))) break;
	     car[i>>5][y+curascii*64] &= (1<<(i&0x1f))^0xffffffff;
	   }
         redr=1;
       }
       if ( car[x>>5][y+curascii*64] & (1<<(x&0x1f)) ) {
         car[x>>5][y+curascii*64]&=(1<<(x&0x1f))^0xffffffff; // xor 1111b == NOT
         redr=1;
       }
     }
   if (Me->Focus) {
     if (WH->Key==199) {    // 'Debut'  <28 Enter> <210 Ins>
       redr=1;
       for (i=0;i<64;i++)
         for (j=0;j<2;j++)
           car[j][i+curascii*64]^=0xffffffff;
     }
     if (WH->Key==211) {    // 'Suppr'  <28 Enter>
       redr=1;
       for (i=0;i<64;i++)
         for (j=0;j<2;j++)
           car[j][i+curascii*64]=0;
     }
     if ((WH->Key==0xc8) || (WH->Key==0x48 && (!(WH->Key|KB_NUM_ACT)))) {// up
       redr=1;
       for (i=62;i>=0;i--)
         for (j=0;j<2;j++)
           car[j][(i+1)+curascii*64]=car[j][i+curascii*64];
       car[0][curascii*64]=0; car[1][curascii*64]=0;
     }
     if ((WH->Key==0xd0) || (WH->Key==0x50 && (!(WH->Key|KB_NUM_ACT)))) {// down
       redr=1;
       for (i=0;i<63;i++)
         for (j=0;j<2;j++)
           car[j][i+curascii*64]=car[j][(i+1)+curascii*64];
       car[0][63+curascii*64]=0; car[1][63+curascii*64]=0;
     }
     if ((WH->Key==0xcd) || (WH->Key==0x4d && (!(WH->Key|KB_NUM_ACT)))) {// right
       redr=1;
       for (i=0;i<64;i++)
         RightShiftLine(&car[0][i+curascii*64],&car[1][i+curascii*64]);
     }
     if ((WH->Key==0xcb) || (WH->Key==0x4b && (!(WH->Key|KB_NUM_ACT)))) {// left
       redr=1;
       for (i=0;i<64;i++)
         LeftShiftLine(&car[0][i+curascii*64],&car[1][i+curascii*64]);
     }
     // up = c8, down = d0, right = cd, left = cb
     //      48         50          4d         4b
   }
   if (redr) { GphBCarMap->Redraw(); GphBCarDraw->Redraw(); }
}
// FOuvrImg --
void ExitOuvrImg() {
   FOuvrImg->Hide();
   FPrinc->Enable();
}
