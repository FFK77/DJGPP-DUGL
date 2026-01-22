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
#include <dpmi.h>
#include <dugl.h>

typedef struct
{	unsigned char AscHG,AscHD,AscBG,AscBD;
	unsigned char DefPrefix,ShifCapsPrefix,AltGRPrefix,AltLfPrefix,ShifNumPrefix,
		      CtrlPrefix;
	unsigned char DefAscii,ShifCapsAscii,AltGRAscii,AltLfAscii,ShifNumAscii,
		      CtrlAscii;
	unsigned int  MaskYesDef,MaskYesShifCaps,MaskYesAltGR,MaskYesAltLf,MaskYesShifNum,
		      MaskYesCtrl;
	unsigned int  MaskNoDef,MaskNoShifCaps,MaskNoAltGR,MaskNoAltLf,MaskNoShifNum,
		      MaskNoCtrl;

	unsigned int  DefNbElDefPrefix,DefNbElShifCapsPrefix,DefNbElAltGrPrefix,DefNbElAltLfPrefix,
		      DefNbElShifNumPrefix,DefNbElCtrlPrefix;
	unsigned int  ShifCapsNbElDefPrefix,ShifCapsNbElShiftCapsPrefix,ShifCapsNbElAltGrPrefix,ShifCapsNbElAltLfPrefix,
		      ShifCapsNbElShifNumPrefix,ShifCapsNbElCtrlPrefix;
	unsigned int  AltGrNbElDefPrefix,AltGrNbElShifCapsPrefix,AltGrNbElAltGrPrefix,AltGrNbElAltLfPrefix,
		      AltGrNbElShifNumPrefix,AltGrNbElCtrlPrefix;
	unsigned int  AltLfNbElDefPrefix,AltLfNbElShifCapsPrefix,AltLfNbElAltGrPrefix,AltLfNbElAltLfPrefix,
		      AltLfNbElShifNumPrefix,AltLfNbElCtrlPrefix;
	unsigned int  ShifNumNbElDefPrefix,ShifNumNbElShifCapsPrefix,ShifNumNbElAltGrPrefix,ShifNumNbElAltLfPrefix,
		      ShifNumNbElShifNumPrefix,ShifNumNbElCtrlPrefix;
	unsigned int  CtrlNbElDefPrefix,CtrlNbElShifCapsPrefix,CtrlNbElAltGrPrefix,CtrlNbElAltLfPrefix,
		      CtrlNbElShifNumPrefix,CtrlNbElCtrlPrefix;

	unsigned char DefAscDefTbDefPrefix, DefAscDefTbShifCapsPrefix, DefAscDefTbAltGRPrefix, DefAscDefTbAltLfPrefix,
		      DefAscDefTbShifNumPrefix, DefAscDefTbCtrlPrefix;
	unsigned char DefAscShifCapsTbDefPrefix, DefAscShifCapsTbShifCapsPrefix,DefAscShifCapsTbAltGRPrefix, DefAscShifCapsTbAltLfPrefix,
		      DefAscShifCapsTbShifNumPrefix, DefAscShifCapsTbCtrlPrefix;
	unsigned char DefAscAltGRTbDefPrefix, DefAscAltGRTbShifCapsPrefix, DefAscAltGRTbAltGRPrefix, DefAscAltGRTbAltLfPrefix,
		      DefAscAltGRTbShifNumPrefix, DefAscAltGRTbCtrlPrefix ;
	unsigned char DefAscAltLfTbDefPrefix, DefAscAltLfTbShifCapsPrefix, DefAscAltLfTbAltGRPrefix, DefAscAltLfTbAltLfPrefix,
		      DefAscAltLfTbShifNumPrefix, DefAscAltLfTbCtrlPrefix ;
	unsigned char DefAscShifNumTbDefPrefix, DefAscShifNumTbShifCapsPrefix, DefAscShifNumTbAltGRPrefix, DefAscShifNumTbAltLfPrefix,
		      DefAscShifNumTbShifNumPrefix, DefAscShifNumTbCtrlPrefix;
	unsigned char DefAscCtrlTbDefPrefix, DefAscCtrlTbShifCapsPrefix, DefAscCtrlTbAltGRPrefix, DefAscCtrlTbAltLfPrefix,
		      DefAscCtrlTbShifNumPrefix, DefAscCtrlTbCtrlPrefix;

	unsigned char *DefTbDefPrefix, *DefTbShifCapsPrefix, *DefTbAltGRPrefix, *DefTbAltLfPrefix,
		      *DefTbShifNumPrefix, *DefTbCtrlPrefix;
	unsigned char *ShifCapsTbDefPrefix, *ShifCapsTbShifCapsPrefix, *ShifCapsTbAltGRPrefix, *ShifCapsTbAltLfPrefix,
		      *ShifCapsTbShifNumPrefix, *ShifCapsTbCtrlPrefix;
	unsigned char *AltGRTbDefPrefix, *AltGRTbShifCapsPrefix, *AltGRTbAltGRPrefix, *AltGRTbAltLfPrefix,
		      *AltGRTbShifNumPrefix, *AltGRTbCtrlPrefix ;
	unsigned char *AltLfTbDefPrefix, *AltLfTbShifCapsPrefix, *AltLfTbAltGRPrefix, *AltLfTbAltLfPrefix,
		      *AltLfTbShifNumPrefix, *AltLfTbCtrlPrefix ;
	unsigned char *ShifNumTbDefPrefix, *ShifNumTbShifCapsPrefix, *ShifNumTbAltGRPrefix, *ShifNumTbAltLfPrefix,
		      *ShifNumTbShifNumPrefix, *ShifNumTbCtrlPrefix;
	unsigned char *CtrlTbDefPrefix, *CtrlTbShifCapsPrefix, *CtrlTbAltGRPrefix, *CtrlTbAltLfPrefix,
		      *CtrlTbShifNumPrefix, *CtrlTbCtrlPrefix;
} InfoButt;

typedef struct
{	unsigned int  code;
	int  x1,y1,x2,y2;
	char *nom;
	unsigned int GenAscii,CanGenAscii;
	InfoButt *IB;
} KeybButton;

typedef struct
{	char *Msg;
	int  x1,y1,x2,y2,MsDownIn;
	void (*Proced)();
} Bouton;

int NbElKbTb=104,MaxGenAscii;
NormKeyb NK;

#define MYesDef 	KB_SHIFT_PR|KB_CAPS_ACT
#define MYesShifCaps 	KB_SHIFT_PR|KB_CAPS_ACT
#define MYesAltGR	KB_RIGHT_ALT_PR
#define MYesAltLf	KB_LEFT_ALT_PR
#define MYesShifNum	KB_SHIFT_PR|KB_NUM_ACT
#define MYesCtrl	KB_CTRL_PR

#define MNoDef		KB_CTRL_PR|KB_ALT_PR
#define MNoShifCaps	KB_CTRL_PR|KB_ALT_PR
#define MNoAltGR	KB_SHIFT_PR|KB_CTRL_PR|KB_LEFT_ALT_PR
#define MNoAltLf	KB_SHIFT_PR|KB_CTRL_PR|KB_RIGHT_ALT_PR
#define MNoShifNum	KB_CTRL_PR|KB_ALT_PR
#define MNoCtrl 	KB_ALT_PR|KB_SHIFT_PR

#define MDefActDef	1
#define MDefActShifCaps	0
#define MDefActAltGR	0
#define MDefActAltLf	0
#define MDefActShifNum	0
#define MDefActCtrl	0

unsigned int TabMDefAct[] = { MDefActDef, MDefActShifCaps, MDefActAltGR,
	                      MDefActAltLf, MDefActShifNum, MDefActCtrl };

InfoButt KbInf[68],
	 InitKbInf={	0,0,0,0, 0,0,0,0,0,0, 0,0,0,0,0,0,
	   MYesDef,MYesShifCaps,MYesAltGR,MYesAltLf,MYesShifNum,MYesCtrl,
	   MNoDef,MNoShifCaps,MNoAltGR,MNoAltLf,MNoShifNum,MNoCtrl,
	   0,0,0,0,0,0, 0,0,0,0,0,0, 0,0,0,0,0,0, 0,0,0,0,0,0,
	   0,0,0,0,0,0, 0,0,0,0,0,0,
	   0,0,0,0,0,0, 0,0,0,0,0,0, 0,0,0,0,0,0, 0,0,0,0,0,0,
	   0,0,0,0,0,0, 0,0,0,0,0,0,

	   NULL,NULL,NULL,NULL,NULL,NULL,
	   NULL,NULL,NULL,NULL,NULL,NULL,
	   NULL,NULL,NULL,NULL,NULL,NULL,
	   NULL,NULL,NULL,NULL,NULL,NULL,
	   NULL,NULL,NULL,NULL,NULL,NULL,
	   NULL,NULL,NULL,NULL,NULL,NULL
	   };

KeybButton KbTb[]={
// --------------------------------------------------------------------
	    { 0x01,  2+  0,477- 40,  2+ 25,477 ,"Esc" ,0 ,0 ,NULL  },  // Echap
	    { 0x3b,  2+ 50,477- 40,  2+ 75,477 ,"F1" ,0 ,0 ,NULL },     // F1
	    { 0x3c,  2+ 75,477- 40,  2+100,477 ,"F2" ,0 ,0 ,NULL },     // F2
	    { 0x3d,  2+100,477- 40,  2+125,477 ,"F3" ,0 ,0 ,NULL },     // F3
	    { 0x3e,  2+125,477- 40,  2+150,477 ,"F4" ,0 ,0 ,NULL },     // F4
	    { 0x3f,  2+150,477- 40,  2+175,477 ,"F5" ,0 ,0 ,NULL },     // F5
	    { 0x40,  2+175,477- 40,  2+200,477 ,"F6" ,0 ,0 ,NULL },     // F6
	    { 0x41,  2+200,477- 40,  2+225,477 ,"F7" ,0 ,0 ,NULL },     // F7
	    { 0x42,  2+225,477- 40,  2+250,477 ,"F8" ,0 ,0 ,NULL },     // F8
	    { 0x43,  2+250,477- 40,  2+275,477 ,"F9" ,0 ,0 ,NULL },     // F9
	    { 0x44,  2+275,477- 40,  2+300,477 ,"F10" ,0 ,0 ,NULL },    // F10

	    { 0x57,  2+325,477- 40,  2+350,477 ,"F11" ,0 ,0 ,NULL },    // F11
	    { 0x58,  2+350,477- 40,  2+375,477 ,"F12" ,0 ,0 ,NULL },    // F12

	    { 0xb7,  2+400,477- 40,  2+425,477 ,"PrntScr" ,0 ,0 ,NULL },   // Impr
	    { 0x46,  2+425,477- 40,  2+450,477 ,"Stop" ,0 ,0 ,NULL },     // Arret Defil
// --------------------------------------------------------------------
	    { 0x29,  2+  0,477- 88,  2+ 25,477 -48,"ý" ,0 ,1 ,&KbInf[ 0] },     // ý
	    { 0x02,  2+ 25,477- 88,  2+ 50,477 -48,"1" ,0 ,1 ,&KbInf[ 1] },     // 1
	    { 0x03,  2+ 50,477- 88,  2+ 75,477 -48,"2" ,0 ,1 ,&KbInf[ 2] },     // 2
	    { 0x04,  2+ 75,477- 88,  2+100,477 -48,"3" ,0 ,1 ,&KbInf[ 3] },     // 3
	    { 0x05,  2+100,477- 88,  2+125,477 -48,"4" ,0 ,1 ,&KbInf[ 4] },     // 4
	    { 0x06,  2+125,477- 88,  2+150,477 -48,"5" ,0 ,1 ,&KbInf[ 5] },     // 5
	    { 0x07,  2+150,477- 88,  2+175,477 -48,"6" ,0 ,1 ,&KbInf[ 6] },     // 6
	    { 0x08,  2+175,477- 88,  2+200,477 -48,"7" ,0 ,1 ,&KbInf[ 7] },     // 7
	    { 0x09,  2+200,477- 88,  2+225,477 -48,"8" ,0 ,1 ,&KbInf[ 8] },     // 8
	    { 0x0a,  2+225,477- 88,  2+250,477 -48,"9" ,0 ,1 ,&KbInf[ 9] },     // 9
	    { 0x0b,  2+250,477- 88,  2+275,477 -48,"0" ,0 ,1 ,&KbInf[10] },     // 0
	    { 0x0c,  2+275,477- 88,  2+300,477 -48,"0->1" ,0 ,1 ,&KbInf[11]},     // 0 -> 1
	    { 0x0d,  2+300,477- 88,  2+325,477 -48,"=" ,0 ,1 ,&KbInf[12] },     // 0 -> 2
	    { 0x0e,  2+325,477- 88,  2+375,477 -48,"Back" ,0 ,1 ,&KbInf[13] },     // Back

	    { 0xd2,  2+400,477- 88,  2+425,477 -48,"Ins" ,0 ,0 ,NULL },     // Ins
	    { 0xc7,  2+425,477- 88,  2+450,477 -48,"Deb" ,0 ,0 ,NULL },     // Deb
	    { 0xc9,  2+450,477- 88,  2+475,477 -48,"PG UP" ,0 ,0 ,NULL },     // PG UP

	    { 0x45,  2+500,477- 88,  2+525,477 -48,"Verr Num" ,0 ,0 ,NULL },     // Verr Num
	    { 0xb5,  2+525,477- 88,  2+550,477 -48,"Num /" ,0 ,1 ,&KbInf[14] },     // Num /
	    { 0x37,  2+550,477- 88,  2+575,477 -48,"Num *" ,0 ,1 ,&KbInf[15] },     // Num *
	    { 0x4a,  2+575,477- 88,  2+600,477 -48,"Num -" ,0 ,1 ,&KbInf[16] },     // Num -
// --------------------------------------------------------------------
	    { 0x0f,  2+  0,477-136,  2+ 35,477 -96,"TAB" ,0 ,1  ,&KbInf[17] },     // TAB
	    { 0x10,  2+ 35,477-136,  2+ 60,477 -96,"A" ,0 ,1  ,&KbInf[18] },     // a
	    { 0x11,  2+ 60,477-136,  2+ 85,477 -96,"Z" ,0 ,1  ,&KbInf[19] },     // z
	    { 0x12,  2+ 85,477-136,  2+110,477 -96,"E" ,0 ,1  ,&KbInf[20] },     // e
	    { 0x13,  2+110,477-136,  2+135,477 -96,"R" ,0 ,1  ,&KbInf[21] },     // r
	    { 0x14,  2+135,477-136,  2+160,477 -96,"T" ,0 ,1  ,&KbInf[22] },     // t
	    { 0x15,  2+160,477-136,  2+185,477 -96,"Y" ,0 ,1  ,&KbInf[23] },     // y
	    { 0x16,  2+185,477-136,  2+210,477 -96,"U" ,0 ,1  ,&KbInf[24] },     // u
	    { 0x17,  2+210,477-136,  2+235,477 -96,"I" ,0 ,1  ,&KbInf[25] },     // i
	    { 0x18,  2+235,477-136,  2+260,477 -96,"O" ,0 ,1  ,&KbInf[26] },     // o
	    { 0x19,  2+260,477-136,  2+285,477 -96,"P" ,0 ,1  ,&KbInf[27] },     // p
	    { 0x1a,  2+285,477-136,  2+310,477 -96,"^" ,0 ,1  ,&KbInf[28] },     // ^
	    { 0x1b,  2+310,477-136,  2+335,477 -96,"$" ,0 ,1  ,&KbInf[29] },     // $
	    { 0x1c,  2+345,477-184,  2+375,477 -96,"Enter" ,0 ,1 ,&KbInf[30] },     // Entree

	    { 0xd3,  2+400,477-136,  2+425,477 -96,"Del" ,0 ,0 ,NULL },     // Suppr
	    { 0xcf,  2+425,477-136,  2+450,477 -96,"End" ,0 ,0 ,NULL  },     // Fin
	    { 0xd1,  2+450,477-136,  2+475,477 -96,"PG DWN" ,0 ,0 ,NULL },     // PG DWN

	    { 0x47,  2+500,477-136,  2+525,477 -96,"Num 7" ,0 ,1 ,&KbInf[31] },     // Num 7
	    { 0x48,  2+525,477-136,  2+550,477 -96,"Num 8" ,0 ,1 ,&KbInf[32] },     // Num 8
	    { 0x49,  2+550,477-136,  2+575,477 -96,"Num 9" ,0 ,1 ,&KbInf[33] },     // Num 9
	    { 0x4e,  2+575,477-184,  2+600,477 -96,"Num +" ,0 ,1 ,&KbInf[34] },     // Num +
// --------------------------------------------------------------------
	    { 0x3a,  2+  0,477-184,  2+ 40,477-144,"Caps" ,0 ,0 ,NULL },     // Caps
	    { 0x1e,  2+ 40,477-184,  2+ 65,477-144,"Q" ,0 ,1 ,&KbInf[35] },     // a
	    { 0x1f,  2+ 65,477-184,  2+ 90,477-144,"S" ,0 ,1 ,&KbInf[36] },     // z
	    { 0x20,  2+ 90,477-184,  2+115,477-144,"D" ,0 ,1 ,&KbInf[37] },     // e
	    { 0x21,  2+115,477-184,  2+140,477-144,"F" ,0 ,1 ,&KbInf[38] },     // r
	    { 0x22,  2+140,477-184,  2+165,477-144,"G" ,0 ,1 ,&KbInf[39] },     // t
	    { 0x23,  2+165,477-184,  2+190,477-144,"H" ,0 ,1 ,&KbInf[40] },     // y
	    { 0x24,  2+190,477-184,  2+215,477-144,"J" ,0 ,1 ,&KbInf[41] },     // u
	    { 0x25,  2+215,477-184,  2+240,477-144,"K" ,0 ,1 ,&KbInf[42] },     // i
	    { 0x26,  2+240,477-184,  2+265,477-144,"L" ,0 ,1 ,&KbInf[43] },     // o
	    { 0x27,  2+265,477-184,  2+290,477-144,"M" ,0 ,1 ,&KbInf[44] },     // p
	    { 0x28,  2+290,477-184,  2+315,477-144,"—" ,0 ,1 ,&KbInf[45] },     // ^
	    { 0x2b,  2+315,477-184,  2+340,477-144,"*" ,0 ,1 ,&KbInf[46] },     // $

	    { 0x4b,  2+500,477-184,  2+525,477-144,"Num 4" ,0 ,1 ,&KbInf[47] },     // Num 4
	    { 0x4c,  2+525,477-184,  2+550,477-144,"Num 5" ,0 ,1 ,&KbInf[48] },     // Num 5
	    { 0x4d,  2+550,477-184,  2+575,477-144,"Num 6" ,0 ,1 ,&KbInf[49] },     // Num 6
// --------------------------------------------------------------------
	    { 0x2a,  2+  0,477-232,  2+ 40,477-192,"LF_SHIFT" ,0 ,0 ,NULL },     // LF_SHIFT
	    { 0x56,  2+ 40,477-232,  2+ 65,477-192,"<>" ,0 ,1 ,&KbInf[50] },     // ><
	    { 0x2c,  2+ 65,477-232,  2+ 90,477-192,"W" ,0 ,1 ,&KbInf[51] },     // w
	    { 0x2d,  2+ 90,477-232,  2+115,477-192,"X" ,0 ,1 ,&KbInf[52]  },     // x
	    { 0x2e,  2+115,477-232,  2+140,477-192,"C" ,0 ,1 ,&KbInf[53]  },     // c
	    { 0x2f,  2+140,477-232,  2+165,477-192,"V" ,0 ,1 ,&KbInf[54]  },     // v
	    { 0x30,  2+165,477-232,  2+190,477-192,"B" ,0 ,1 ,&KbInf[55]  },     // b
	    { 0x31,  2+190,477-232,  2+215,477-192,"N" ,0 ,1 ,&KbInf[56]  },     // n
	    { 0x32,  2+215,477-232,  2+240,477-192,"," ,0 ,1 ,&KbInf[57]  },     // ,
	    { 0x33,  2+240,477-232,  2+265,477-192,";" ,0 ,1 ,&KbInf[58]  },     // ;
	    { 0x34,  2+265,477-232,  2+290,477-192,":" ,0 ,1 ,&KbInf[59]  },     // :
	    { 0x35,  2+290,477-232,  2+315,477-192,"!" ,0 ,1 ,&KbInf[60]  },     // !
	    { 0x36,  2+315,477-232,  2+375,477-192,"RG_SHIFT" ,0 ,0 ,NULL },     // RG_SHIFT

	    { 0xc8,  2+425,477-232,  2+450,477-192,"UP" ,0 ,0 ,NULL  },     // UP

	    { 0x4f,  2+500,477-232,  2+525,477-192,"Num 1" ,0 ,1 ,&KbInf[61]  },     // Num 1
	    { 0x50,  2+525,477-232,  2+550,477-192,"Num 2" ,0 ,1 ,&KbInf[62] },     // Num 2
	    { 0x51,  2+550,477-232,  2+575,477-192,"Num 3" ,0 ,1 ,&KbInf[63] },     // Num 3
	    { 0x9c,  2+575,477-280,  2+600,477-192,"Num Enter" ,0 ,1 ,&KbInf[64] },     // Num Enter
// --------------------------------------------------------------------
	    { 0x1d,  2+  0,477-280,  2+ 35,477-240,"LF_CTRL" ,0 ,0 ,NULL },  // LF_CTRL
	    { 0xdb,  2+ 35,477-280,  2+ 60,477-240,"LF_WIN" ,0 ,0 ,NULL  },  // WIN
	    { 0x38,  2+ 60,477-280,  2+ 85,477-240,"LF_ALT" ,0 ,0 ,NULL  },  // LF_ALT
	    { 0x39,  2+ 85,477-280,  2+260,477-240,"Space" ,0 ,1 ,&KbInf[65] },    // Space
	    { 0xb8,  2+260,477-280,  2+285,477-240,"RG_ALT" ,0 ,0 ,NULL },   // RG_ALT
	    { 0xdc,  2+285,477-280,  2+310,477-240,"RG_WIN" ,0 ,0 ,NULL },   // WIN
	    { 0xdd,  2+310,477-280,  2+335,477-240,"Menu" ,0 ,0 ,NULL  },    // Menu
	    { 0x9d,  2+335,477-280,  2+375,477-240,"RG_CTRL" ,0 ,0 ,NULL },  // RG_CTRL

	    { 0xcb,  2+400,477-280,  2+425,477-240,"LEFT" ,0 ,0 ,NULL },     // LF
	    { 0xd0,  2+425,477-280,  2+450,477-240,"DOWN" ,0 ,0 ,NULL },     // DWN
	    { 0xcd,  2+450,477-280,  2+475,477-240,"RIGHT" ,0 ,0 ,NULL },    // RG

	    { 0x52,  2+500,477-280,  2+550,477-240,"Num 0" ,0 ,1 ,&KbInf[66] },    // Num 0
	    { 0x53,  2+550,477-280,  2+575,477-240,"Num Del" ,0 ,1 ,&KbInf[67] },  // Num Suppr
};


FILE *Pal;
Surf *MsPtr;
View MsV,SaveView;
DFONT F1;
unsigned char Pal3d[1024],palette[1024];
char *LoadKbConfig="kbconfig.cfg",*CreateKbMap="kbmap.map",
     *SaveKbConfig="kbconfig.cfg";
int rouge,jaune,bleu,noir,blanc,gris,grisf,grisc;
int i,j,k,l,m,n;
int CurProc,SelKbButt,SelMsDown;
int choixBM,choixBMMsDown;

unsigned int OldTime;
char s[40];
// Variable Choisir Ascii
int OldCurProc,OldSelKbButt,OldChoixBM,MsDownInChxAscii,SelAscEnter;
unsigned int SelAscii;
// Variable Tab Prefix Menu
char 	      *Msg;
unsigned char *TAscDef,*TAscShifCaps,*TAscAltGR,*TAscAltLf,*TAscShifNum,
              *TAscCtrl;
unsigned int  *NbTAscDef,*NbTAscShifCaps,*NbTAscAltGR,*NbTAscAltLf,
	      *NbTAscShifNum,*NbTAscCtrl;
unsigned char *DefAscAscDef,*DefAscAscShifCaps,*DefAscAscAltGR,*DefAscAscAltLf,
	      *DefAscAscShifNum,*DefAscAscCtrl;
unsigned int  MsDwnTbPrefix;
// Variable Fill Tab Prefix
int		ChoixBMFill,MsDownFill;
char		*MsgFill;
unsigned char   *TFill;
unsigned int    *NbElFill;
// Var cree Kb MAP --------
// *************************************************************************
int 	NbAscDef,NbAscShifCaps,NbAscAltGR,NbAscAltLf,NbAscShifNum,NbAscCtrl;
int 	NbPrefixDef,NbPrefixShifCaps,NbPrefixAltGR,NbPrefixAltLf,
	NbPrefixShifNum,NbPrefixCtrl;
unsigned char AscDef[68*2],AscShifCaps[68*2],AscAltGR[68*2],
	      AscAltLf[68*2],AscShifNum[68*2],AscCtrl[68*2];
int  Plus1Bit(unsigned int Mask);
void PrepNormKeybPrefix(unsigned int *NbElPrefix,unsigned char *TbPrefix[],
     unsigned char DefAscPrefix,unsigned int MYes,unsigned int MNo,unsigned int MDefAct,
     unsigned char code,unsigned int *TbMYes,unsigned int *TbMNo);

PrefixKeyb	*TabPrefixKeyb;
NormKeyb	*TabNormPrefixKeyb,*TabNormKeyb;
int  CptNrmPrfx,CptPrfx;
//-------------------------------------------------------------------------
//--------- BOUTON --------
void ProcedQuit();
Bouton ButtQuit={ "Exit", 525,30,600,60, 0,&ProcedQuit };
void ProcedCreateKeybmap();
Bouton ButtCreateKeybmap={ "Create keybmap", 390,30,520,60, 0,&ProcedCreateKeybmap };
void ProcedSauveConfig();
Bouton ButtSauveConfig={ "Save config", 285,30,385,60, 0,&ProcedSauveConfig };
void ProcedLoadConfig();
Bouton ButtLoadConfig={ "Load config",  180,30,280,60, 0,&ProcedLoadConfig };
//----------------
void NormScan();
int  InPos(int x1,int y1,int x2,int y2,int X,int Y);
void FillTabPrefix();
void BoutonMenu(KeybButton *Bt);
void TabPrefixMenu();
void ButtonScan(Bouton *Bt);
void ZeroBuff(unsigned char *Buff);
void BoutonAllocMem(KeybButton *Bt);
void BoutonFreeMem(KeybButton *Bt);
void ChoisirAscii();
void SaveKeybButton(FILE *FSave,KeybButton *Bt);
void LoadKeybButton(FILE *FLoad,KeybButton *Bt);

int main(int argc,char *argv[])
{	if (argc>=2) LoadKbConfig=argv[1];
	if (argc>=3) CreateKbMap=argv[2];
	if (argc>=4) SaveKbConfig=argv[3];
	if ((Pal=fopen("3dpal.pal","rb"))==NULL) {
	  printf("3dpal.pal error\n"); exit(-1); }
	fread(&Pal3d,1024,1,Pal);
	fclose(Pal);
	rouge=PrFindCol(0,255,0,0,255,&Pal3d,0.4f);
	rouge=PrFindCol(0,255,0,0,255,&Pal3d,0.4f);
	jaune=PrFindCol(0,255,0,255,0,&Pal3d,0.4f);
	bleu=PrFindCol(0,255,255,0,0,&Pal3d,0.4f);
	noir=PrFindCol(0,255,0,0,0,&Pal3d,0.4f);
	blanc=PrFindCol(0,255,255,255,255,&Pal3d,0.4f);
	gris=PrFindCol(0,255,127,127,127,&Pal3d,0.4f);
	grisf=PrFindCol(0,255,64,64,64,&Pal3d,0.4f);
	grisc=PrFindCol(0,255,127+64,127+64,127+64,&Pal3d,0.4f);

	FREE_MMX();
	if (!InitVesa())
	  { printf("error init graphics\n"); exit(0); }

	for (i=0,MaxGenAscii=0;i<NbElKbTb;i++)
	   if (KbTb[i].CanGenAscii) MaxGenAscii++;
	for (i=0;i<MaxGenAscii;i++) KbInf[i]=InitKbInf;
	for (i=0;i<NbElKbTb;i++)
	   if (KbTb[i].CanGenAscii) BoutonAllocMem(&KbTb[i]);

	FREE_MMX();
	ProcedLoadConfig(); // charge Config par defaut

	if (!LoadGIF(&MsPtr,"mouseimg.gif",&palette))
	  { printf("mouseimg.gif error\n"); exit(-1); }
	SetOrgSurf(MsPtr,0,MsPtr->ResV-1);
	if (!LoadDFONT(&F1,"hello.chr"))
	  { printf("hello.chr error\n"); exit(-1); }

	if (!InstallMouse())
	  { printf("Mouse error\n"); exit(-1); }
	if (!DgInstallTimer(300))
	  { UninstallMouse(); printf("Timer error\n"); exit(-1); }

	if (!InstallKeyboard())
	  { DgUninstallTimer(); UninstallMouse(); printf("Keyboard error\n");
	    exit(-1);
	  }

	if (!InitVesaMode(640,480,8,3)) {
	  DgUninstallTimer(); UninstallMouse(); UninstallKeyboard();
	  CloseVesa();
	  printf("error init vesa mode\n");
	  exit(0);
	}
	SetPalette(0,256,&Pal3d);
	SetDFONT(&F1);
	GetSurfView(&VSurf[0],&MsV);
	SetMouseView(&MsV);
	FREE_MMX();
	SelAscEnter=MsDownInChxAscii=choixBMMsDown=SelMsDown=CurProc=0;
	SelKbButt=-1;
	for (j=0;;j++) {
//	   if (Time-OldTime<(TimerFreq/CurModeVtFreq))
		FREE_MMX();
	     WaitRetrace();
		OldTime=DgTime;
		ViewSurf(j%3);
		SetSurf(&VSurf[(j+1)%3]);
		Clear(noir);
        // create a screenshot
        // tab + ctrl + shift
        if (IsKeyDown(0xf) && (KbFLAG&KB_SHIFT_PR) && (KbFLAG&KB_CTRL_PR))
            SavePCX(&VSurf[j%3],"keybmap.pcx",&Pal3d);

	    switch (CurProc) {
			case 0: NormScan(); break;
			case 1: BoutonMenu(&KbTb[SelKbButt]); break;
			case 2: ChoisirAscii(); break;
			case 3: TabPrefixMenu(); break;
			case 4: FillTabPrefix(); break;
			default: CurProc=0;
	    }

	   FntCol=blanc;
	   FntY=10;
	   sprintf(s,"LastKey %x, KbFLAG %x",LastKey,KbFLAG);
	   OutTextMode(s,AJ_MID);
	   PutMaskSurf(MsPtr,MsX,MsY,0);
	}
	CloseVesa();

	UninstallMouse();
	DgUninstallTimer();
	UninstallKeyboard();
    TextMode();
}

void FillTabPrefix() {
        unsigned char key;
        unsigned int keymsk;
	View V1;
	V1.OrgX=V1.OrgY=0;
	s[1]=0;
	GetSurfView(&CurSurf,&SaveView);
	if (SelAscEnter) {
	  SelAscEnter=0;
	  if (!TFill[ChoixBMFill*2+1] && SelAscii) (*NbElFill)++;
	    else if (TFill[ChoixBMFill*2+1] && (!SelAscii)) (*NbElFill)--;
	  TFill[ChoixBMFill*2+1]=SelAscii;
	}

	ChoixBMFill=-1;
	for (m=n=0;m<NbElKbTb;m++) {
	  V1.MinX=KbTb[m].x1+1; V1.MinY=KbTb[m].y1+1;
	  V1.MaxX=KbTb[m].x2-1; V1.MaxY=KbTb[m].y2-1;
	  SetSurfView(&CurSurf,&V1);

	  if (KbTb[m].CanGenAscii) {
	    TFill[n*2]=KbTb[m].code;
	    if (InPos(KbTb[m].x1,KbTb[m].y1,KbTb[m].x2,KbTb[m].y2,MsX,MsY))
	      ChoixBMFill=n;
	    if (TFill[n*2+1]) {
	      ClearSurf(blanc);
	      ClearText();
	      FntY--; FntCol=noir; s[0]=TFill[n*2+1];
	      OutTextMode(s,AJ_MID);
	    } else ClearSurf(grisc);
	    n++;
	  } else ClearSurf(gris);
	  if (ChoixBMFill!=-1 && MsButton&1) MsDownFill=1;
	  if (ChoixBMFill!=-1 && (!(MsButton&1)) && MsDownFill) {
	    MsDownFill=0; OldCurProc=CurProc; OldSelKbButt=SelKbButt;
	    ClearKeyCircBuff();
	    CurProc=2;
	  }
	  SetSurfView(&CurSurf,&SaveView);
	  rect(KbTb[m].x1,KbTb[m].y1,KbTb[m].x2,KbTb[m].y2,noir);
	}
        GetKey(&key,&keymsk);
	if (key==1) { CurProc=3; ClearKeyCircBuff(); }
	SetSurfView(&CurSurf,&SaveView);
	FntCol=blanc; FntY=40;
	sprintf(s,"%s Nb Element %i",MsgFill,*NbElFill);
	OutTextMode(s,AJ_MID);
}

void TabPrefixMenu()
{	int x1,y1,x2,y2;
	View V1;
        unsigned char key;
        unsigned int keymsk;
	GetSurfView(&CurSurf,&SaveView);
	V1.OrgX=V1.OrgY=0;
	V1.MinX=60; V1.MinY=90;
	V1.MaxX=320; V1.MaxY=360;
	SetSurfView(&CurSurf,&V1);
	ClearSurf(gris);
	if (SelAscEnter) {
	  SelAscEnter=0;
	  switch (choixBM) {
	   case 6: (*DefAscAscDef)=SelAscii; break;
/*	   case 7: (*DefAscAscShifCaps)=SelAscii; break;
	   case 8: (*DefAscAscAltGR)=SelAscii; break;
	   case 9: (*DefAscAscAltLf)=SelAscii; break;
	   case 10: (*DefAscAscShifNum)=SelAscii; break;
	   case 11: (*DefAscAscCtrl)=SelAscii; break;*/
	  }
	}

//	if (InPos(MinX,MinY,MaxX,MaxY-FntHaut,MsX,MsY))
//	  choixBM=((MaxY-FntHaut)-MsY)/FntHaut;
	if (InPos(CurSurf.MinX,CurSurf.MinY,CurSurf.MaxX,CurSurf.MaxY-FntHaut,MsX,MsY))
	  choixBM=((CurSurf.MaxY-FntHaut)-MsY)/FntHaut;
	else choixBM=-1;
	if (choixBM!=-1) {
/*	  x1=MinX;
	  y1=MaxY-(FntHaut*(choixBM+2));
	  x2=MaxX;
	  y2=MaxY-(FntHaut*(choixBM+1));*/
	  x1=CurSurf.MinX;
	  y1=CurSurf.MaxY-(FntHaut*(choixBM+2));
	  x2=CurSurf.MaxX;
	  y2=CurSurf.MaxY-(FntHaut*(choixBM+1));
	  bar(x1,y1,x2,y2,bleu);
	}
	if ((MsButton&1) && (choixBM!=-1)) MsDwnTbPrefix=1;
	if ((!(MsButton&1)) && (choixBM!=-1) && MsDwnTbPrefix) {
	  MsDwnTbPrefix=0;
	  switch (choixBM) {
	    case 0:
	      CurProc=4; MsgFill="Tab Ascii default"; ClearKeyCircBuff();
	      NbElFill=NbTAscDef;  TFill=TAscDef; break;
	    case 1:
	      CurProc=4; MsgFill="Tab Ascii Shift,Caps"; ClearKeyCircBuff();;
	      NbElFill=NbTAscShifCaps;  TFill=TAscShifCaps; break;
	    case 2:
	      CurProc=4; MsgFill="Tab Ascii Alt Gr"; ClearKeyCircBuff();
	      NbElFill=NbTAscAltGR;  TFill=TAscAltGR; break;
	    case 3:
	      CurProc=4; MsgFill="Tab Ascii Alt Lf"; ClearKeyCircBuff();
	      NbElFill=NbTAscAltLf;  TFill=TAscAltLf; break;
	    case 4:
	      CurProc=4; MsgFill="Tab Ascii Shift,Num"; ClearKeyCircBuff();
	      NbElFill=NbTAscShifNum;  TFill=TAscShifNum; break;
	    case 5:
	      CurProc=4; MsgFill="Tab Ascii Ctrl"; ClearKeyCircBuff();
	      NbElFill=NbTAscCtrl;  TFill=TAscCtrl; break;
	    case 6 /*... 11*/:
	      OldCurProc=CurProc; OldSelKbButt=SelKbButt; ClearKeyCircBuff();
	      OldChoixBM=choixBM; CurProc=2; break;
	  }
	}
	ClearText();
	FntCol=blanc; OutText(Msg);
	FntCol=noir;

	OutText("Table ascii default");
	if ((*NbTAscDef)) { sprintf(s,"%i\n",(*NbTAscDef)); OutTextMode(s,AJ_RIGHT); }
	else OutText("\n");
	OutText("Table ascii Shift,Caps");
	if ((*NbTAscShifCaps)) { sprintf(s,"%i\n",(*NbTAscShifCaps)); OutTextMode(s,AJ_RIGHT); }
	else OutText("\n");
	OutText("Table ascii Alt Gr");
	if ((*NbTAscAltGR)) { sprintf(s,"%i\n",(*NbTAscAltGR)); OutTextMode(s,AJ_RIGHT); }
	else OutText("\n");
	OutText("Table ascii Alt Lf");
	if ((*NbTAscAltLf)) { sprintf(s,"%i\n",(*NbTAscAltLf)); OutTextMode(s,AJ_RIGHT); }
	else OutText("\n");
	OutText("Table ascii Shift,Num");
	if ((*NbTAscShifNum)) { sprintf(s,"%i\n",(*NbTAscShifNum)); OutTextMode(s,AJ_RIGHT); }
	else OutText("\n");
	OutText("Table ascii Ctrl");
	if ((*NbTAscCtrl)) { sprintf(s,"%i\n",(*NbTAscCtrl)); OutTextMode(s,AJ_RIGHT); }
	else OutText("\n");

	s[0]='\''; s[2]='\''; s[3]='\n'; s[4]=0;
	OutText("Default ascii");
	if ((*DefAscAscDef)) { s[1]=(*DefAscAscDef); OutTextMode(s,AJ_RIGHT); }
	   else OutText("\n");
/*	OutText("Defaut ascii Shift,Caps");
	if ((*DefAscAscShifCaps)) { s[1]=(*DefAscAscShifCaps); OutTextMode(s,AJ_RIGHT); }
	   else OutText("\n");
	OutText("Defaut ascii Alt Gr");
	if ((*DefAscAscAltGR)) { s[1]=(*DefAscAscAltGR); OutTextMode(s,AJ_RIGHT); }
	   else OutText("\n");
	OutText("Defaut ascii Alt Lf");
	if ((*DefAscAscAltLf)) { s[1]=(*DefAscAscAltLf); OutTextMode(s,AJ_RIGHT); }
	   else OutText("\n");
	OutText("Defaut ascii Shift,Num");
	if ((*DefAscAscShifNum)) { s[1]=(*DefAscAscShifNum); OutTextMode(s,AJ_RIGHT); }
	   else OutText("\n");
	OutText("Defaut ascii Ctrl");
	if ((*DefAscAscCtrl)) { s[1]=(*DefAscAscCtrl); OutTextMode(s,AJ_RIGHT); }
	   else OutText("\n");*/
	SetSurfView(&CurSurf,&SaveView);
        GetKey(&key,&keymsk);
	if (key) { CurProc=1; ClearKeyCircBuff(); }
}


void BoutonMenu(KeybButton *Bt)
{	int x1,y1,x2,y2;
	View V1;
        unsigned char key;
        unsigned int keymsk;
	GetSurfView(&CurSurf,&SaveView);
	V1.OrgX=V1.OrgY=0;
	V1.MinX=50; V1.MinY=20;
	V1.MaxX=460; V1.MaxY=460;
	SetSurfView(&CurSurf,&V1);
	ClearSurf(gris);
	if (SelAscEnter) {
	  SelAscEnter=0;
	  switch (choixBM) {
	   case 1: Bt->IB->AscHG=SelAscii; break;
	   case 2: Bt->IB->AscHD=SelAscii; break;
	   case 3: Bt->IB->AscBG=SelAscii; break;
	   case 4: Bt->IB->AscBD=SelAscii; break;
	   case 6: if (!Bt->IB->DefPrefix) Bt->IB->DefAscii=SelAscii; break;
	   case 8: if (!Bt->IB->ShifCapsPrefix) Bt->IB->ShifCapsAscii=SelAscii; break;
	   case 10: if (!Bt->IB->AltGRPrefix) Bt->IB->AltGRAscii=SelAscii; break;
	   case 12: if (!Bt->IB->AltLfPrefix) Bt->IB->AltLfAscii=SelAscii; break;
	   case 14: if (!Bt->IB->ShifNumPrefix) Bt->IB->ShifNumAscii=SelAscii; break;
	   case 16: if (!Bt->IB->CtrlPrefix) Bt->IB->CtrlAscii=SelAscii; break;
	  }
	}

//	if (InPos(MinX,MinY,MaxX,MaxY-FntHaut,MsX,MsY))
	if (InPos(CurSurf.MinX,CurSurf.MinY,CurSurf.MaxX,CurSurf.MaxY-FntHaut,MsX,MsY))
	  choixBM=((CurSurf.MaxY-FntHaut)-MsY)/FntHaut;
	else choixBM=-1;
	if (choixBM!=-1) {
	  x1=CurSurf.MinX;
	  y1=CurSurf.MaxY-(FntHaut*(choixBM+2));
	  x2=CurSurf.MaxX;
	  y2=CurSurf.MaxY-(FntHaut*(choixBM+1));
	  bar(x1,y1,x2,y2,bleu);
	}
	ClearText();
	FntCol=blanc; OutText("Name : "); OutText(Bt->nom);
	sprintf(s,", Code : 0x%x \n",Bt->code); OutText(s);
	FntCol= (Bt->CanGenAscii)? noir:grisf;
	if (Bt->GenAscii) {
	  s[0]='\''; s[2]='\''; s[3]='\n'; s[4]=0;
	  OutText("Disable Ascii Gen \n");
	  OutText("Visible Ascii (Up,Left)");
	  if (Bt->IB->AscHG) { s[1]=Bt->IB->AscHG; OutTextMode(s,AJ_RIGHT); }
  	    else OutText("\n");
	  OutText("Visible Ascii (Up,right)");
	  if (Bt->IB->AscHD) { s[1]=Bt->IB->AscHD; OutTextMode(s,AJ_RIGHT); }
	    else OutText("\n");
	  OutText("Visible Ascii (Down,Left)");
	  if (Bt->IB->AscBG) { s[1]=Bt->IB->AscBG; OutTextMode(s,AJ_RIGHT); }
	    else OutText("\n");
	  OutText("Visible Ascii (Down,Right)");
	  if (Bt->IB->AscBD) { s[1]=Bt->IB->AscBD; OutTextMode(s,AJ_RIGHT); }
	    else OutText("\n");
	  if (!Bt->IB->DefPrefix) {
	    OutText("Prefix Default\n");
	    OutText("Ascii Default");
	    if (Bt->IB->DefAscii) { s[1]=Bt->IB->DefAscii; OutTextMode(s,AJ_RIGHT); }
	      else OutText("\n");
	  } else {
	    OutText("Normal Default\n"); OutText("Table Ascii Prefix Default\n");
	  }
	  if (!Bt->IB->ShifCapsPrefix) {
	    OutText("Prefix Shift,Caps\n");
	    OutText("Ascii Shift,Caps");
	    if (Bt->IB->ShifCapsAscii) { s[1]=Bt->IB->ShifCapsAscii; OutTextMode(s,AJ_RIGHT); }
	      else OutText("\n");

	  } else {
	    OutText("Normal Shift,Caps\n"); OutText("Table Ascii Prefix Shift,Caps\n");
	  }
	  if (!Bt->IB->AltGRPrefix) {
	    OutText("Prefix Alt Gr\n");
	    OutText("Ascii Alt Gr");
	    if (Bt->IB->AltGRAscii) { s[1]=Bt->IB->AltGRAscii; OutTextMode(s,AJ_RIGHT); }
	      else OutText("\n");
	  } else {
	    OutText("Normal Alt Gr\n"); OutText("Table Ascii Prefix Alt Gr\n");
	  }
	  if (!Bt->IB->AltLfPrefix) {
	    OutText("Prefix Alt Lf\n");
	    OutText("Ascii Alt Lf");
	    if (Bt->IB->AltLfAscii) { s[1]=Bt->IB->AltLfAscii; OutTextMode(s,AJ_RIGHT); }
	      else OutText("\n");
	  } else {
	    OutText("Normal Alt Lf\n"); OutText("Table Ascii Prefix Alt Lf\n");
	  }
	  if (!Bt->IB->ShifNumPrefix) {
	    OutText("Prefix Shift,Num\n");
	    OutText("Ascii Shift,Num");
	    if (Bt->IB->ShifNumAscii) { s[1]=Bt->IB->ShifNumAscii; OutTextMode(s,AJ_RIGHT); }
	      else OutText("\n");
	  } else {
	    OutText("Normal Shift,Num\n"); OutText("Table Ascii Prefix Shift,Num\n");
	  }
	  if (!Bt->IB->CtrlPrefix) {
	    OutText("Prefix Ctrl\n");
	    OutText("Ascii Ctrl");
	    if (Bt->IB->CtrlAscii) { s[1]=Bt->IB->CtrlAscii; OutTextMode(s,AJ_RIGHT); }
	      else OutText("\n");
	  } else {
	    OutText("Normal Ctrl\n"); OutText("Table Ascii Prefix Ctrl\n");
	  }

	} else OutText("Enable Ascii Gen\n");

	if (choixBM!=-1 && (MsButton&1)) choixBMMsDown=1;
	if (choixBMMsDown && choixBM!=-1 && (!(MsButton&1))) {
	  choixBMMsDown=0;
	  switch (choixBM) {
	   case 0:
	     if (Bt->CanGenAscii) { Bt->GenAscii^=0xffffffff; } break;
	   case 1 ... 4 :
	     if (Bt->GenAscii) { OldCurProc=CurProc; OldSelKbButt=SelKbButt;
	       CurProc=2; ClearKeyCircBuff(); OldChoixBM=choixBM; } break;

	   case 6:
	     if (!Bt->IB->DefPrefix) { OldCurProc=CurProc; OldSelKbButt=SelKbButt;
	       CurProc=2; ClearKeyCircBuff(); OldChoixBM=choixBM; }
	     else { CurProc=3; Msg="Table Default Prefix\n"; ClearKeyCircBuff();
//***************************************************************************
	 	TAscDef=Bt->IB->DefTbDefPrefix;
		TAscShifCaps=Bt->IB->DefTbShifCapsPrefix;
		TAscAltGR=Bt->IB->DefTbAltGRPrefix;
		TAscAltLf=Bt->IB->DefTbAltLfPrefix;
		TAscShifNum=Bt->IB->DefTbShifNumPrefix;
		TAscCtrl=Bt->IB->DefTbCtrlPrefix;

	 	DefAscAscDef=&Bt->IB->DefAscDefTbDefPrefix;
		DefAscAscShifCaps=&Bt->IB->DefAscDefTbShifCapsPrefix;
		DefAscAscAltGR=&Bt->IB->DefAscDefTbAltGRPrefix;
		DefAscAscAltLf=&Bt->IB->DefAscDefTbAltLfPrefix;
		DefAscAscShifNum=&Bt->IB->DefAscDefTbShifNumPrefix;
		DefAscAscCtrl=&Bt->IB->DefAscDefTbCtrlPrefix;

		NbTAscDef=&Bt->IB->DefNbElDefPrefix;
		NbTAscShifCaps=&Bt->IB->DefNbElShifCapsPrefix;
		NbTAscAltGR=&Bt->IB->DefNbElAltGrPrefix;
		NbTAscAltLf=&Bt->IB->DefNbElAltLfPrefix;
	        NbTAscShifNum=&Bt->IB->DefNbElShifNumPrefix;
		NbTAscCtrl=&Bt->IB->DefNbElCtrlPrefix;
	     }
	     break;
	   case 8:
	     if (!Bt->IB->ShifCapsPrefix) { OldCurProc=CurProc; OldSelKbButt=SelKbButt;
	       CurProc=2; ClearKeyCircBuff(); OldChoixBM=choixBM; }
	     else { CurProc=3; Msg="Table Shift,Caps Prefix\n"; ClearKeyCircBuff();
//***************************************************************************
	 	TAscDef=Bt->IB->ShifCapsTbDefPrefix;
		TAscShifCaps=Bt->IB->ShifCapsTbShifCapsPrefix;
		TAscAltGR=Bt->IB->ShifCapsTbAltGRPrefix;
		TAscAltLf=Bt->IB->ShifCapsTbAltLfPrefix;
		TAscShifNum=Bt->IB->ShifCapsTbShifNumPrefix;
		TAscCtrl=Bt->IB->ShifCapsTbCtrlPrefix;

	 	DefAscAscDef=&Bt->IB->DefAscShifCapsTbDefPrefix;
		DefAscAscShifCaps=&Bt->IB->DefAscShifCapsTbShifCapsPrefix;
		DefAscAscAltGR=&Bt->IB->DefAscShifCapsTbAltGRPrefix;
		DefAscAscAltLf=&Bt->IB->DefAscShifCapsTbAltLfPrefix;
		DefAscAscShifNum=&Bt->IB->DefAscShifCapsTbShifNumPrefix;
		DefAscAscCtrl=&Bt->IB->DefAscShifCapsTbCtrlPrefix;

		NbTAscDef=&Bt->IB->ShifCapsNbElDefPrefix;
		NbTAscShifCaps=&Bt->IB->ShifCapsNbElShiftCapsPrefix;
		NbTAscAltGR=&Bt->IB->ShifCapsNbElAltGrPrefix;
		NbTAscAltLf=&Bt->IB->ShifCapsNbElAltLfPrefix;
	        NbTAscShifNum=&Bt->IB->ShifCapsNbElShifNumPrefix;
		NbTAscCtrl=&Bt->IB->ShifCapsNbElCtrlPrefix;
	     }
	     break;
	   case 10:
	     if (!Bt->IB->AltGRPrefix) { OldCurProc=CurProc; OldSelKbButt=SelKbButt;
	       CurProc=2; ClearKeyCircBuff(); OldChoixBM=choixBM; }
	     else { CurProc=3; Msg="Table Alt Gr Prefix\n"; ClearKeyCircBuff();
//***************************************************************************
	 	TAscDef=Bt->IB->AltGRTbDefPrefix;
		TAscShifCaps=Bt->IB->AltGRTbShifCapsPrefix;
		TAscAltGR=Bt->IB->AltGRTbAltGRPrefix;
		TAscAltLf=Bt->IB->AltGRTbAltLfPrefix;
		TAscShifNum=Bt->IB->AltGRTbShifNumPrefix;
		TAscCtrl=Bt->IB->AltGRTbCtrlPrefix;

	 	DefAscAscDef=&Bt->IB->DefAscAltGRTbDefPrefix;
		DefAscAscShifCaps=&Bt->IB->DefAscAltGRTbShifCapsPrefix;
		DefAscAscAltGR=&Bt->IB->DefAscAltGRTbAltGRPrefix;
		DefAscAscAltLf=&Bt->IB->DefAscAltGRTbAltLfPrefix;
		DefAscAscShifNum=&Bt->IB->DefAscAltGRTbShifNumPrefix;
		DefAscAscCtrl=&Bt->IB->DefAscAltGRTbCtrlPrefix;

		NbTAscDef=&Bt->IB->AltGrNbElDefPrefix;
		NbTAscShifCaps=&Bt->IB->AltGrNbElShifCapsPrefix;
		NbTAscAltGR=&Bt->IB->AltGrNbElAltGrPrefix;
		NbTAscAltLf=&Bt->IB->AltGrNbElAltLfPrefix;
	        NbTAscShifNum=&Bt->IB->AltGrNbElShifNumPrefix;
		NbTAscCtrl=&Bt->IB->AltGrNbElCtrlPrefix;
	     }
	     break;
	   case 12:
	     if (!Bt->IB->AltLfPrefix) { OldCurProc=CurProc; OldSelKbButt=SelKbButt;
	       CurProc=2; ClearKeyCircBuff(); OldChoixBM=choixBM; }
	     else { CurProc=3; Msg="Table Alt Lf Prefix\n"; ClearKeyCircBuff();
//***************************************************************************
	 	TAscDef=Bt->IB->AltLfTbDefPrefix;
		TAscShifCaps=Bt->IB->AltLfTbShifCapsPrefix;
		TAscAltGR=Bt->IB->AltLfTbAltGRPrefix;
		TAscAltLf=Bt->IB->AltLfTbAltLfPrefix;
		TAscShifNum=Bt->IB->AltLfTbShifNumPrefix;
		TAscCtrl=Bt->IB->AltLfTbCtrlPrefix;

	 	DefAscAscDef=&Bt->IB->DefAscAltLfTbDefPrefix;
		DefAscAscShifCaps=&Bt->IB->DefAscAltLfTbShifCapsPrefix;
		DefAscAscAltGR=&Bt->IB->DefAscAltLfTbAltGRPrefix;
		DefAscAscAltLf=&Bt->IB->DefAscAltLfTbAltLfPrefix;
		DefAscAscShifNum=&Bt->IB->DefAscAltLfTbShifNumPrefix;
		DefAscAscCtrl=&Bt->IB->DefAscAltLfTbCtrlPrefix;

		NbTAscDef=&Bt->IB->AltLfNbElDefPrefix;
		NbTAscShifCaps=&Bt->IB->AltLfNbElShifCapsPrefix;
		NbTAscAltGR=&Bt->IB->AltLfNbElAltGrPrefix;
		NbTAscAltLf=&Bt->IB->AltLfNbElAltLfPrefix;
	        NbTAscShifNum=&Bt->IB->AltLfNbElShifNumPrefix;
		NbTAscCtrl=&Bt->IB->AltLfNbElCtrlPrefix;
	     }
	     break;
	   case 14:
	     if (!Bt->IB->ShifNumPrefix) { OldCurProc=CurProc; OldSelKbButt=SelKbButt;
	       CurProc=2; ClearKeyCircBuff(); OldChoixBM=choixBM; }
	     else { CurProc=3; Msg="Table Shift,Num Prefix\n"; ClearKeyCircBuff();
//***************************************************************************
	 	TAscDef=Bt->IB->ShifNumTbDefPrefix;
		TAscShifCaps=Bt->IB->ShifNumTbShifCapsPrefix;
		TAscAltGR=Bt->IB->ShifNumTbAltGRPrefix;
		TAscAltLf=Bt->IB->ShifNumTbAltLfPrefix;
		TAscShifNum=Bt->IB->ShifNumTbShifNumPrefix;
		TAscCtrl=Bt->IB->ShifNumTbCtrlPrefix;

	 	DefAscAscDef=&Bt->IB->DefAscShifNumTbDefPrefix;
		DefAscAscShifCaps=&Bt->IB->DefAscShifNumTbShifCapsPrefix;
		DefAscAscAltGR=&Bt->IB->DefAscShifNumTbAltGRPrefix;
		DefAscAscAltLf=&Bt->IB->DefAscShifNumTbAltLfPrefix;
		DefAscAscShifNum=&Bt->IB->DefAscShifNumTbShifNumPrefix;
		DefAscAscCtrl=&Bt->IB->DefAscShifNumTbCtrlPrefix;

		NbTAscDef=&Bt->IB->ShifNumNbElDefPrefix;
		NbTAscShifCaps=&Bt->IB->ShifNumNbElShifCapsPrefix;
		NbTAscAltGR=&Bt->IB->ShifNumNbElAltGrPrefix;
		NbTAscAltLf=&Bt->IB->ShifNumNbElAltLfPrefix;
	        NbTAscShifNum=&Bt->IB->ShifNumNbElShifNumPrefix;
		NbTAscCtrl=&Bt->IB->ShifNumNbElCtrlPrefix;
	     }
	     break;
	   case 16:
	     if (!Bt->IB->CtrlPrefix) { OldCurProc=CurProc; OldSelKbButt=SelKbButt;
	       CurProc=2; ClearKeyCircBuff(); OldChoixBM=choixBM; }
	     else { CurProc=3; Msg="Table Ctrl Prefix\n"; ClearKeyCircBuff();
//***************************************************************************
	 	TAscDef=Bt->IB->CtrlTbDefPrefix;
		TAscShifCaps=Bt->IB->CtrlTbShifCapsPrefix;
		TAscAltGR=Bt->IB->CtrlTbAltGRPrefix;
		TAscAltLf=Bt->IB->CtrlTbAltLfPrefix;
		TAscShifNum=Bt->IB->CtrlTbShifNumPrefix;
		TAscCtrl=Bt->IB->CtrlTbCtrlPrefix;

	 	DefAscAscDef=&Bt->IB->DefAscCtrlTbDefPrefix;
		DefAscAscShifCaps=&Bt->IB->DefAscCtrlTbShifCapsPrefix;
		DefAscAscAltGR=&Bt->IB->DefAscCtrlTbAltGRPrefix;
		DefAscAscAltLf=&Bt->IB->DefAscCtrlTbAltLfPrefix;
		DefAscAscShifNum=&Bt->IB->DefAscCtrlTbShifNumPrefix;
		DefAscAscCtrl=&Bt->IB->DefAscCtrlTbCtrlPrefix;

		NbTAscDef=&Bt->IB->CtrlNbElDefPrefix;
		NbTAscShifCaps=&Bt->IB->CtrlNbElShifCapsPrefix;
		NbTAscAltGR=&Bt->IB->CtrlNbElAltGrPrefix;
		NbTAscAltLf=&Bt->IB->CtrlNbElAltLfPrefix;
	        NbTAscShifNum=&Bt->IB->CtrlNbElShifNumPrefix;
		NbTAscCtrl=&Bt->IB->CtrlNbElCtrlPrefix;
	     }
	     break;

	   case 5: if (Bt->GenAscii) Bt->IB->DefPrefix^=0xffffffff; break;
	   case 7: if (Bt->GenAscii) Bt->IB->ShifCapsPrefix^=0xffffffff; break;
	   case 9: if (Bt->GenAscii) Bt->IB->AltGRPrefix^=0xffffffff; break;
	   case 11: if (Bt->GenAscii) Bt->IB->AltLfPrefix^=0xffffffff; break;
	   case 13: if (Bt->GenAscii) Bt->IB->ShifNumPrefix^=0xffffffff; break;
	   case 15: if (Bt->GenAscii) Bt->IB->CtrlPrefix^=0xffffffff; break;
	  }
	}

	SetSurfView(&CurSurf,&SaveView);
        GetKey(&key,&keymsk);
	if (key==1) CurProc=0;
}



int  InPos(int x1,int y1,int x2,int y2,int X,int Y)
{	if (X<=x1 || X>=x2 || Y<=y1 || Y>=y2) return 0;
	return 1;
}

void ButtonScan(Bouton *Bt)
{	View V1;
	GetSurfView(&CurSurf,&SaveView);
	V1.OrgX=V1.OrgY=0;
	V1.MinX=Bt->x1; V1.MinY=Bt->y1;
	V1.MaxX=Bt->x2; V1.MaxY=Bt->y2;
	SetSurfView(&CurSurf,&V1);

	if (Bt->MsDownIn) bar(Bt->x1,Bt->y1,Bt->x2,Bt->y2,jaune);
	else bar(Bt->x1,Bt->y1,Bt->x2,Bt->y2,gris);

	rect(Bt->x1,Bt->y1,Bt->x2,Bt->y2,grisf);
	ClearText();
	FntCol=noir;
	FntY=(Bt->y1+Bt->y2)/2-FntHaut/2-FntLowPos;
	OutTextMode(Bt->Msg,AJ_MID);
	if (InPos(Bt->x1,Bt->y1,Bt->x2,Bt->y2,MsX,MsY) && (MsButton&1))
	  Bt->MsDownIn=1;

	if (Bt->MsDownIn && (!(MsButton&1))) {
	  Bt->MsDownIn=0;
	  if ((InPos(Bt->x1,Bt->y1,Bt->x2,Bt->y2,MsX,MsY)))
	    Bt->Proced();
	}

	SetSurfView(&CurSurf,&SaveView);
}


void ProcedQuit()
{	CloseVesa();
	UninstallMouse();
	DgUninstallTimer();
	UninstallKeyboard();
        TextMode();
	exit(0);
}


void NormScan() {
	View V1;
	V1.OrgX=V1.OrgY=0;
	s[1]=0;
	GetSurfView(&CurSurf,&SaveView);
	ButtonScan(&ButtQuit);
	ButtonScan(&ButtCreateKeybmap);
	ButtonScan(&ButtSauveConfig);
	ButtonScan(&ButtLoadConfig);

	if (KbFLAG & KB_NUM_ACT) bar(502,477- 16,  2+516,477,jaune);
	else bar(502,477- 16,  2+516,477,grisf);
	if (KbFLAG & KB_CAPS_ACT) bar(542,477- 16,  2+556,477,jaune);
	else bar(542,477- 16,  2+556,477,grisf);
	if (KbFLAG & KB_SCROLL_ACT) bar(582,477- 16,  2+596,477,jaune);
	else bar(582,477- 16,  2+596,477,grisf);

	for (i=0;i<NbElKbTb;i++) {
	  V1.MinX=KbTb[i].x1+1; V1.MinY=KbTb[i].y1+1;
	  V1.MaxX=KbTb[i].x2-1; V1.MaxY=KbTb[i].y2-1;
	  SetSurfView(&CurSurf,&V1);

	  if (IsKeyDown(KbTb[i].code)) ClearSurf(rouge);
	  else if (KbTb[i].GenAscii) ClearSurf(grisc);
	       else ClearSurf(gris);
	  if (KbTb[i].GenAscii) {
	    ClearText(); FntCol=noir;
	    s[0]=KbTb[i].IB->AscHG; OutTextMode(s,AJ_LEFT);
	    s[0]=KbTb[i].IB->AscHD; OutTextMode(s,AJ_RIGHT);
	    FntY=CurSurf.MinY-FntLowPos+2;
	    s[0]=KbTb[i].IB->AscBG; OutTextMode(s,AJ_LEFT);
	    s[0]=KbTb[i].IB->AscBD; OutTextMode(s,AJ_RIGHT);
	  }
	  SetSurfView(&CurSurf,&SaveView);
	  rect(KbTb[i].x1,KbTb[i].y1,KbTb[i].x2,KbTb[i].y2,noir);
	}
	for (i=0;i<NbElKbTb;i++) {
	  if (InPos(KbTb[i].x1,KbTb[i].y1,KbTb[i].x2,KbTb[i].y2,MsX,MsY)) {
	      FntX=KbTb[i].x1; FntY=KbTb[i].y1; FntCol=noir; OutText(KbTb[i].nom);
	      FntX=KbTb[i].x1+1; FntY=KbTb[i].y1+1; FntCol=blanc; OutText(KbTb[i].nom);
	      if (MsButton&1) { SelMsDown=1; SelKbButt=i; }
	      if (SelMsDown && (!(MsButton&1))) { CurProc=1; ClearKeyCircBuff(); SelMsDown=0; }
 	  } else if (SelKbButt==i && SelMsDown)
	           { SelMsDown=0; SelKbButt=-1; }
	}
	SetSurfView(&CurSurf,&SaveView);
}

void ChoisirAscii() {
	View V1;
	int ProbChoice;
        unsigned char key;
        unsigned int keymsk;
	GetSurfView(&CurSurf,&SaveView);
	int GrX1=30,GrY1=40,asciiChoix;
	char s2[20],s3[60];
	s2[1]=s3[0]=0;
	SelAscEnter=1;
	V1.OrgX=V1.OrgY=asciiChoix=0;
	for (i=0;i<(FntHaut+2)*17;i+=(FntHaut+2)) {
          line(GrX1,GrY1+i,GrX1+(FntHaut+2)*16,GrY1+i,bleu);
          line(GrX1+i,GrY1,GrX1+i,GrY1+(FntHaut+2)*16,bleu);
	}
	FntCol=blanc;
	ProbChoice=0;
	for (k=0;k<(FntHaut+2)*16;k+=(FntHaut+2))
	  for (l=0;l<(FntHaut+2)*16;l+=(FntHaut+2)) {
	    V1.MinX=l+1+GrX1; V1.MinY=k+GrY1+1;
	    V1.MaxX=V1.MinX+FntHaut; V1.MaxY=V1.MinY+16;
	    SetSurfView(&CurSurf,&V1);
	    ClearText();
	    s2[0]=asciiChoix;
	    OutText(s2);
	    if (InPos(V1.MinX,V1.MinY,V1.MaxX,V1.MaxY,MsX,MsY) && asciiChoix) {
	      sprintf(s3,"ascii %i char '%c' \n",asciiChoix,asciiChoix);
	      ProbChoice=asciiChoix;
	    }
	    asciiChoix++;
	  }
	if (MsButton&1 && ProbChoice) MsDownInChxAscii=1;
	if (MsDownInChxAscii && ProbChoice && (!(MsButton&1)) ) {
	  CurProc=OldCurProc; SelKbButt=OldSelKbButt; MsDownInChxAscii=0;
	  choixBM=OldChoixBM; SelAscii=ProbChoice;
	} else if (!(MsButton&1)) MsDownInChxAscii=0;
        GetKey(&key,&keymsk);
	if (key==1) {
	  CurProc=OldCurProc; SelKbButt=OldSelKbButt; SelAscii=0;
	  choixBM=OldChoixBM;
	}
	SetSurfView(&CurSurf,&SaveView);
	ClearText();
	OutText(s3);
}

void ZeroBuff(unsigned char *Buff)
{	for (int ii=0;ii<MaxGenAscii*2;ii++) Buff[ii]=0; }

// 1‚ u char code bouton 2‚ code ascii
void BoutonAllocMem(KeybButton *Bt)
{	int erreur=0;

	if ( (Bt->IB->DefTbDefPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->DefTbShifCapsPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->DefTbAltGRPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->DefTbAltLfPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->DefTbShifNumPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->DefTbCtrlPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
//*******************************
	if ( (Bt->IB->ShifCapsTbDefPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->ShifCapsTbShifCapsPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->ShifCapsTbAltGRPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->ShifCapsTbAltLfPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->ShifCapsTbShifNumPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->ShifCapsTbCtrlPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
//*******************************
	if ( (Bt->IB->AltGRTbDefPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->AltGRTbShifCapsPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->AltGRTbAltGRPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->AltGRTbAltLfPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->AltGRTbShifNumPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->AltGRTbCtrlPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
//*******************************
	if ( (Bt->IB->AltLfTbDefPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->AltLfTbShifCapsPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->AltLfTbAltGRPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->AltLfTbAltLfPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->AltLfTbShifNumPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->AltLfTbCtrlPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
//*******************************
	if ( (Bt->IB->ShifNumTbDefPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->ShifNumTbShifCapsPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->ShifNumTbAltGRPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->ShifNumTbAltLfPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->ShifNumTbShifNumPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->ShifNumTbCtrlPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
//*******************************
	if ( (Bt->IB->CtrlTbDefPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->CtrlTbShifCapsPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->CtrlTbAltGRPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->CtrlTbAltLfPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->CtrlTbShifNumPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
	if ( (Bt->IB->CtrlTbCtrlPrefix=(unsigned char *)malloc(MaxGenAscii*2))==NULL) erreur=1;
//*******************************

	if (erreur) { printf("no mem \n"); exit(-1); }
//********************************************
	 ZeroBuff(Bt->IB->DefTbDefPrefix     );
	 ZeroBuff(Bt->IB->DefTbShifCapsPrefix);
	 ZeroBuff(Bt->IB->DefTbAltGRPrefix   );
	 ZeroBuff(Bt->IB->DefTbAltLfPrefix   );
	 ZeroBuff(Bt->IB->DefTbShifNumPrefix );
	 ZeroBuff(Bt->IB->DefTbCtrlPrefix    );
//*******************************
	 ZeroBuff(Bt->IB->ShifCapsTbDefPrefix	  );
	 ZeroBuff(Bt->IB->ShifCapsTbShifCapsPrefix);
	 ZeroBuff(Bt->IB->ShifCapsTbAltGRPrefix   );
	 ZeroBuff(Bt->IB->ShifCapsTbAltLfPrefix   );
	 ZeroBuff(Bt->IB->ShifCapsTbShifNumPrefix );
	 ZeroBuff(Bt->IB->ShifCapsTbCtrlPrefix	  );
//*******************************
	 ZeroBuff(Bt->IB->AltGRTbDefPrefix	  );
	 ZeroBuff(Bt->IB->AltGRTbShifCapsPrefix   );
	 ZeroBuff(Bt->IB->AltGRTbAltGRPrefix	  );
	 ZeroBuff(Bt->IB->AltGRTbAltLfPrefix	  );
	 ZeroBuff(Bt->IB->AltGRTbShifNumPrefix	  );
	 ZeroBuff(Bt->IB->AltGRTbCtrlPrefix	  );
//*******************************
	 ZeroBuff(Bt->IB->AltLfTbDefPrefix	  );
	 ZeroBuff(Bt->IB->AltLfTbShifCapsPrefix   );
	 ZeroBuff(Bt->IB->AltLfTbAltGRPrefix	  );
	 ZeroBuff(Bt->IB->AltLfTbAltLfPrefix	  );
	 ZeroBuff(Bt->IB->AltLfTbShifNumPrefix	  );
	 ZeroBuff(Bt->IB->AltLfTbCtrlPrefix	  );
//*******************************
	 ZeroBuff(Bt->IB->ShifNumTbDefPrefix	  );
	 ZeroBuff(Bt->IB->ShifNumTbShifCapsPrefix );
	 ZeroBuff(Bt->IB->ShifNumTbAltGRPrefix	  );
	 ZeroBuff(Bt->IB->ShifNumTbAltLfPrefix	  );
	 ZeroBuff(Bt->IB->ShifNumTbShifNumPrefix  );
	 ZeroBuff(Bt->IB->ShifNumTbCtrlPrefix	  );
//*******************************
	 ZeroBuff(Bt->IB->CtrlTbDefPrefix	  );
	 ZeroBuff(Bt->IB->CtrlTbShifCapsPrefix	  );
	 ZeroBuff(Bt->IB->CtrlTbAltGRPrefix	  );
	 ZeroBuff(Bt->IB->CtrlTbAltLfPrefix	  );
	 ZeroBuff(Bt->IB->CtrlTbShifNumPrefix	  );
	 ZeroBuff(Bt->IB->CtrlTbCtrlPrefix	  );
//*******************************
	Bt->IB->DefNbElDefPrefix=Bt->IB->DefNbElShifCapsPrefix=Bt->IB->DefNbElAltGrPrefix=Bt->IB->DefNbElAltLfPrefix=
	Bt->IB->DefNbElShifNumPrefix=Bt->IB->DefNbElCtrlPrefix=0;
	Bt->IB->ShifCapsNbElDefPrefix=Bt->IB->ShifCapsNbElShiftCapsPrefix=Bt->IB->ShifCapsNbElAltGrPrefix=Bt->IB->ShifCapsNbElAltLfPrefix=
	Bt->IB->ShifCapsNbElShifNumPrefix=Bt->IB->ShifCapsNbElCtrlPrefix=0;
	Bt->IB->AltGrNbElDefPrefix=Bt->IB->AltGrNbElShifCapsPrefix=Bt->IB->AltGrNbElAltGrPrefix=Bt->IB->AltGrNbElAltLfPrefix=
	Bt->IB->AltGrNbElShifNumPrefix=Bt->IB->AltGrNbElCtrlPrefix=0;
	Bt->IB->AltLfNbElDefPrefix=Bt->IB->AltLfNbElShifCapsPrefix=Bt->IB->AltLfNbElAltGrPrefix=Bt->IB->AltLfNbElAltLfPrefix=
	Bt->IB->AltLfNbElShifNumPrefix=Bt->IB->AltLfNbElCtrlPrefix=0;
	Bt->IB->ShifNumNbElDefPrefix=Bt->IB->ShifNumNbElShifCapsPrefix=Bt->IB->ShifNumNbElAltGrPrefix=Bt->IB->ShifNumNbElAltLfPrefix=
	Bt->IB->ShifNumNbElShifNumPrefix=Bt->IB->ShifNumNbElCtrlPrefix=0;
	Bt->IB->CtrlNbElDefPrefix=Bt->IB->CtrlNbElShifCapsPrefix=Bt->IB->CtrlNbElAltGrPrefix=Bt->IB->CtrlNbElAltLfPrefix=
	Bt->IB->CtrlNbElShifNumPrefix=Bt->IB->CtrlNbElCtrlPrefix=0;

}

void ProcedSauveConfig() {
	FILE *FSC;
	if ((FSC=fopen(SaveKbConfig,"wb"))==NULL) return;
	for (i=0;i<NbElKbTb;i++) SaveKeybButton(FSC,&KbTb[i]);
	fclose(FSC);
}

void ProcedLoadConfig() {
	FILE *FLC;
	if ((FLC=fopen(LoadKbConfig,"rb"))==NULL) return;
	for (i=0;i<NbElKbTb;i++) LoadKeybButton(FLC,&KbTb[i]);
	fclose(FLC);
}

void SaveKeybButton(FILE *FSave,KeybButton *Bt) {
	fwrite(Bt,sizeof(KeybButton),1,FSave);
	if (Bt->CanGenAscii) {
	  fwrite(Bt->IB,sizeof(InfoButt),1,FSave);

	  fwrite(Bt->IB->DefTbDefPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->DefTbShifCapsPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->DefTbAltGRPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->DefTbAltLfPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->DefTbShifNumPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->DefTbCtrlPrefix,MaxGenAscii*2,1,FSave);

	  fwrite(Bt->IB->ShifCapsTbDefPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->ShifCapsTbShifCapsPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->ShifCapsTbAltGRPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->ShifCapsTbAltLfPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->ShifCapsTbShifNumPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->ShifCapsTbCtrlPrefix,MaxGenAscii*2,1,FSave);

	  fwrite(Bt->IB->AltGRTbDefPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->AltGRTbShifCapsPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->AltGRTbAltGRPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->AltGRTbAltLfPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->AltGRTbShifNumPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->AltGRTbCtrlPrefix,MaxGenAscii*2,1,FSave);

	  fwrite(Bt->IB->AltLfTbDefPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->AltLfTbShifCapsPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->AltLfTbAltGRPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->AltLfTbAltLfPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->AltLfTbShifNumPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->AltLfTbCtrlPrefix,MaxGenAscii*2,1,FSave);

	  fwrite(Bt->IB->ShifNumTbDefPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->ShifNumTbShifCapsPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->ShifNumTbAltGRPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->ShifNumTbAltLfPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->ShifNumTbShifNumPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->ShifNumTbCtrlPrefix,MaxGenAscii*2,1,FSave);

	  fwrite(Bt->IB->CtrlTbDefPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->CtrlTbShifCapsPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->CtrlTbAltGRPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->CtrlTbAltLfPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->CtrlTbShifNumPrefix,MaxGenAscii*2,1,FSave);
	  fwrite(Bt->IB->CtrlTbCtrlPrefix,MaxGenAscii*2,1,FSave);

	}

}

void LoadKeybButton(FILE *FLoad,KeybButton *Bt) {
	KeybButton SaveKB;
	InfoButt SaveIB;
	SaveKB=*Bt;
	fread(Bt,sizeof(KeybButton),1,FLoad);
	Bt->IB=SaveKB.IB; // restore les pointeurs
	Bt->nom=SaveKB.nom;
	if (Bt->CanGenAscii) {
	  SaveIB=*Bt->IB;
	  fread(Bt->IB,sizeof(InfoButt),1,FLoad);
	  // restore les pointeurs
	  Bt->IB->DefTbDefPrefix=SaveIB.DefTbDefPrefix;
	  Bt->IB->DefTbShifCapsPrefix=SaveIB.DefTbShifCapsPrefix;
	  Bt->IB->DefTbAltGRPrefix=SaveIB.DefTbAltGRPrefix;
	  Bt->IB->DefTbAltLfPrefix=SaveIB.DefTbAltLfPrefix;
	  Bt->IB->DefTbShifNumPrefix=SaveIB.DefTbShifNumPrefix;
	  Bt->IB->DefTbCtrlPrefix=SaveIB.DefTbCtrlPrefix;

	  Bt->IB->ShifCapsTbDefPrefix=SaveIB.ShifCapsTbDefPrefix;
	  Bt->IB->ShifCapsTbShifCapsPrefix=SaveIB.ShifCapsTbShifCapsPrefix;
	  Bt->IB->ShifCapsTbAltGRPrefix=SaveIB.ShifCapsTbAltGRPrefix;
	  Bt->IB->ShifCapsTbAltLfPrefix=SaveIB.ShifCapsTbAltLfPrefix;
	  Bt->IB->ShifCapsTbShifNumPrefix=SaveIB.ShifCapsTbShifNumPrefix;
	  Bt->IB->ShifCapsTbCtrlPrefix=SaveIB.ShifCapsTbCtrlPrefix;

	  Bt->IB->AltGRTbDefPrefix=SaveIB.AltGRTbDefPrefix;
	  Bt->IB->AltGRTbShifCapsPrefix=SaveIB.AltGRTbShifCapsPrefix;
	  Bt->IB->AltGRTbAltGRPrefix=SaveIB.AltGRTbAltGRPrefix;
	  Bt->IB->AltGRTbAltLfPrefix=SaveIB.AltGRTbAltLfPrefix;
	  Bt->IB->AltGRTbShifNumPrefix=SaveIB.AltGRTbShifNumPrefix;
	  Bt->IB->AltGRTbCtrlPrefix=SaveIB.AltGRTbCtrlPrefix;

	  Bt->IB->AltLfTbDefPrefix=SaveIB.AltLfTbDefPrefix;
	  Bt->IB->AltLfTbShifCapsPrefix=SaveIB.AltLfTbShifCapsPrefix;
	  Bt->IB->AltLfTbAltGRPrefix=SaveIB.AltLfTbAltGRPrefix;
	  Bt->IB->AltLfTbAltLfPrefix=SaveIB.AltLfTbAltLfPrefix;
	  Bt->IB->AltLfTbShifNumPrefix=SaveIB.AltLfTbShifNumPrefix;
	  Bt->IB->AltLfTbCtrlPrefix=SaveIB.AltLfTbCtrlPrefix;

	  Bt->IB->ShifNumTbDefPrefix=SaveIB.ShifNumTbDefPrefix;
	  Bt->IB->ShifNumTbShifCapsPrefix=SaveIB.ShifNumTbShifCapsPrefix;
	  Bt->IB->ShifNumTbAltGRPrefix=SaveIB.ShifNumTbAltGRPrefix;
	  Bt->IB->ShifNumTbAltLfPrefix=SaveIB.ShifNumTbAltLfPrefix;
	  Bt->IB->ShifNumTbShifNumPrefix=SaveIB.ShifNumTbShifNumPrefix;
	  Bt->IB->ShifNumTbCtrlPrefix=SaveIB.ShifNumTbCtrlPrefix;

	  Bt->IB->CtrlTbDefPrefix=SaveIB.CtrlTbDefPrefix;
	  Bt->IB->CtrlTbShifCapsPrefix=SaveIB.CtrlTbShifCapsPrefix;
	  Bt->IB->CtrlTbAltGRPrefix=SaveIB.CtrlTbAltGRPrefix;
	  Bt->IB->CtrlTbAltLfPrefix=SaveIB.CtrlTbAltLfPrefix;
	  Bt->IB->CtrlTbShifNumPrefix=SaveIB.CtrlTbShifNumPrefix;
	  Bt->IB->CtrlTbCtrlPrefix=SaveIB.CtrlTbCtrlPrefix;
	  // restore les Mask Yes et No
	  Bt->IB->MaskYesDef=SaveIB.MaskYesDef;
	  Bt->IB->MaskYesShifCaps=SaveIB.MaskYesShifCaps;
	  Bt->IB->MaskYesAltGR=SaveIB.MaskYesAltGR;
	  Bt->IB->MaskYesAltLf=SaveIB.MaskYesAltLf;
	  Bt->IB->MaskYesShifNum=SaveIB.MaskYesShifNum;
	  Bt->IB->MaskYesCtrl=SaveIB.MaskYesCtrl;

	  Bt->IB->MaskNoDef=SaveIB.MaskNoDef;
	  Bt->IB->MaskNoShifCaps=SaveIB.MaskNoShifCaps;
	  Bt->IB->MaskNoAltGR=SaveIB.MaskNoAltGR;
	  Bt->IB->MaskNoAltLf=SaveIB.MaskNoAltLf;
	  Bt->IB->MaskNoShifNum=SaveIB.MaskNoShifNum;
	  Bt->IB->MaskNoCtrl=SaveIB.MaskNoCtrl;
	// *************
	  fread(Bt->IB->DefTbDefPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->DefTbShifCapsPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->DefTbAltGRPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->DefTbAltLfPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->DefTbShifNumPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->DefTbCtrlPrefix,MaxGenAscii*2,1,FLoad);

	  fread(Bt->IB->ShifCapsTbDefPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->ShifCapsTbShifCapsPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->ShifCapsTbAltGRPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->ShifCapsTbAltLfPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->ShifCapsTbShifNumPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->ShifCapsTbCtrlPrefix,MaxGenAscii*2,1,FLoad);

	  fread(Bt->IB->AltGRTbDefPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->AltGRTbShifCapsPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->AltGRTbAltGRPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->AltGRTbAltLfPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->AltGRTbShifNumPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->AltGRTbCtrlPrefix,MaxGenAscii*2,1,FLoad);

	  fread(Bt->IB->AltLfTbDefPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->AltLfTbShifCapsPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->AltLfTbAltGRPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->AltLfTbAltLfPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->AltLfTbShifNumPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->AltLfTbCtrlPrefix,MaxGenAscii*2,1,FLoad);

	  fread(Bt->IB->ShifNumTbDefPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->ShifNumTbShifCapsPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->ShifNumTbAltGRPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->ShifNumTbAltLfPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->ShifNumTbShifNumPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->ShifNumTbCtrlPrefix,MaxGenAscii*2,1,FLoad);

	  fread(Bt->IB->CtrlTbDefPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->CtrlTbShifCapsPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->CtrlTbAltGRPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->CtrlTbAltLfPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->CtrlTbShifNumPrefix,MaxGenAscii*2,1,FLoad);
	  fread(Bt->IB->CtrlTbCtrlPrefix,MaxGenAscii*2,1,FLoad);

	}
}

void ProcedCreateKeybmap() {
	FILE *FSKMAP;
	KbMAP HeadKbMap;
	int CptNbNormAscii=0,NbPrefix=0,NbNormPrefixKeyb=0,CptNbNorm=0;
	unsigned int  *TabPosSaveNormKeyb,*TabPosSaveNormPrefixKeyb;
	unsigned int  CptTabPos,CptTabPrefixPos,PosSave,CalcAlign;
	unsigned char AlignFile[]={ 0,0,0,0 };

//**************************************************************************
	NbAscDef=NbAscShifCaps=NbAscAltGR=NbAscAltLf=NbAscShifNum=NbAscCtrl=0;
	NbPrefixDef=NbPrefixShifCaps=NbPrefixAltGR=NbPrefixAltLf=NbPrefixShifNum=NbPrefixCtrl=0;
	for (int i=0;i<NbElKbTb;i++)
	if (KbTb[i].CanGenAscii) {
	  if ((!KbTb[i].IB->DefPrefix) && KbTb[i].IB->DefAscii) {
	    AscDef[NbAscDef*2]=KbTb[i].code;
	    AscDef[NbAscDef*2+1]=KbTb[i].IB->DefAscii;
	    NbAscDef++;  }
	  if (KbTb[i].IB->DefPrefix) NbPrefixDef++;
	  if ((!KbTb[i].IB->ShifCapsPrefix) && KbTb[i].IB->ShifCapsAscii) {
	    AscShifCaps[NbAscShifCaps*2]=KbTb[i].code;
	    AscShifCaps[NbAscShifCaps*2+1]=KbTb[i].IB->ShifCapsAscii;
	    NbAscShifCaps++;  }
	  if (KbTb[i].IB->ShifCapsPrefix) NbPrefixShifCaps++;
	  if ((!KbTb[i].IB->AltGRPrefix) && KbTb[i].IB->AltGRAscii) {
	    AscDef[NbAscAltGR*2]=KbTb[i].code;
	    AscDef[NbAscAltGR*2+1]=KbTb[i].IB->AltGRAscii;
	    NbAscAltGR++;  }
	  if (KbTb[i].IB->AltGRPrefix) NbPrefixAltGR++;
	  if ((!KbTb[i].IB->AltLfPrefix) && KbTb[i].IB->AltLfAscii) {
	    AscDef[NbAscAltLf*2]=KbTb[i].code;
	    AscDef[NbAscAltLf*2+1]=KbTb[i].IB->AltLfAscii;
	    NbAscAltLf++;  }
	  if (KbTb[i].IB->AltLfPrefix) NbPrefixAltLf++;
	  if ((!KbTb[i].IB->ShifNumPrefix) && KbTb[i].IB->ShifNumAscii) {
	    AscDef[NbAscShifNum*2]=KbTb[i].code;
	    AscDef[NbAscShifNum*2+1]=KbTb[i].IB->ShifNumAscii;
	    NbAscShifNum++;  }
	  if (KbTb[i].IB->ShifNumPrefix) NbPrefixShifNum++;
	  if ((!KbTb[i].IB->CtrlPrefix) && KbTb[i].IB->CtrlAscii) {
	    AscDef[NbAscCtrl*2]=KbTb[i].code;
	    AscDef[NbAscCtrl*2+1]=KbTb[i].IB->CtrlAscii;
	    NbAscCtrl++;  }
	  if (KbTb[i].IB->CtrlPrefix) NbPrefixCtrl++;

//*************** compte nombre Norm Prefix Keyb
//**********************************************
	  if (KbTb[i].IB->DefNbElDefPrefix) NbNormPrefixKeyb++;	if (KbTb[i].IB->DefNbElShifCapsPrefix) NbNormPrefixKeyb++;
	  if (KbTb[i].IB->DefNbElAltGrPrefix) NbNormPrefixKeyb++; if (KbTb[i].IB->DefNbElAltLfPrefix) NbNormPrefixKeyb++;
	  if (KbTb[i].IB->DefNbElShifNumPrefix) NbNormPrefixKeyb++; if (KbTb[i].IB->DefNbElCtrlPrefix) NbNormPrefixKeyb++;

	  if (KbTb[i].IB->ShifCapsNbElDefPrefix) NbNormPrefixKeyb++; if (KbTb[i].IB->ShifCapsNbElShiftCapsPrefix) NbNormPrefixKeyb++;
	  if (KbTb[i].IB->ShifCapsNbElAltGrPrefix) NbNormPrefixKeyb++; if (KbTb[i].IB->ShifCapsNbElAltLfPrefix) NbNormPrefixKeyb++;
	  if (KbTb[i].IB->ShifCapsNbElShifNumPrefix) NbNormPrefixKeyb++; if (KbTb[i].IB->ShifCapsNbElCtrlPrefix) NbNormPrefixKeyb++;

	  if (KbTb[i].IB->AltGrNbElDefPrefix) NbNormPrefixKeyb++; if (KbTb[i].IB->AltGrNbElShifCapsPrefix) NbNormPrefixKeyb++;
	  if (KbTb[i].IB->AltGrNbElAltGrPrefix) NbNormPrefixKeyb++; if (KbTb[i].IB->AltGrNbElAltLfPrefix) NbNormPrefixKeyb++;
	  if (KbTb[i].IB->AltGrNbElShifNumPrefix) NbNormPrefixKeyb++; if (KbTb[i].IB->AltGrNbElCtrlPrefix) NbNormPrefixKeyb++;

	  if (KbTb[i].IB->AltLfNbElDefPrefix) NbNormPrefixKeyb++; if (KbTb[i].IB->AltLfNbElShifCapsPrefix) NbNormPrefixKeyb++;
	  if (KbTb[i].IB->AltLfNbElAltGrPrefix) NbNormPrefixKeyb++; if (KbTb[i].IB->AltLfNbElAltLfPrefix) NbNormPrefixKeyb++;
          if (KbTb[i].IB->AltLfNbElShifNumPrefix) NbNormPrefixKeyb++; if (KbTb[i].IB->AltLfNbElCtrlPrefix) NbNormPrefixKeyb++;

	  if (KbTb[i].IB->ShifNumNbElDefPrefix) NbNormPrefixKeyb++; if (KbTb[i].IB->ShifNumNbElShifCapsPrefix) NbNormPrefixKeyb++;
	  if (KbTb[i].IB->ShifNumNbElAltGrPrefix) NbNormPrefixKeyb++; if (KbTb[i].IB->ShifNumNbElAltLfPrefix) NbNormPrefixKeyb++;
	  if (KbTb[i].IB->ShifNumNbElShifNumPrefix) NbNormPrefixKeyb++; if (KbTb[i].IB->ShifNumNbElCtrlPrefix) NbNormPrefixKeyb++;

	  if (KbTb[i].IB->CtrlNbElDefPrefix) NbNormPrefixKeyb++; if (KbTb[i].IB->CtrlNbElShifCapsPrefix) NbNormPrefixKeyb++;
	  if (KbTb[i].IB->CtrlNbElAltGrPrefix) NbNormPrefixKeyb++; if (KbTb[i].IB->CtrlNbElAltLfPrefix) NbNormPrefixKeyb++;
	  if (KbTb[i].IB->CtrlNbElShifNumPrefix) NbNormPrefixKeyb++; if (KbTb[i].IB->CtrlNbElCtrlPrefix) NbNormPrefixKeyb++;
	}
	if (NbAscDef) CptNbNormAscii++;
	if (NbAscShifCaps) CptNbNormAscii++;
	if (NbAscAltGR) CptNbNormAscii++;
	if (NbAscAltLf) CptNbNormAscii++;
	if (NbAscShifNum) CptNbNormAscii++;
	if (NbAscCtrl) CptNbNormAscii++;
	NbPrefix=NbPrefixDef+NbPrefixShifCaps+NbPrefixAltGR+NbPrefixAltLf+NbPrefixShifNum+NbPrefixCtrl;
//******Allocation Memoire**************************************************
//**************************************************************************
	if ((TabNormKeyb=(NormKeyb*)alloca(sizeof(NormKeyb)*6))==NULL) return;
	for (int i=0;i<6;i++) {
	  if ((TabNormKeyb[i].Ptr=(unsigned char*) alloca(MaxGenAscii*2))==NULL) return;
	  TabNormKeyb[i].NbAscii=0; }
	if (NbPrefix) {
	  if ((TabPrefixKeyb=(PrefixKeyb*)alloca(NbPrefix*sizeof(PrefixKeyb)))==NULL)
	  { for (int i=0;i<6;i++) free(TabNormKeyb[i].Ptr);
	    free(TabNormKeyb);  return; }
	}
	if (NbNormPrefixKeyb) {
	  if ((TabNormPrefixKeyb=(NormKeyb*)alloca(sizeof(NormKeyb)*NbNormPrefixKeyb))==NULL) return;
	  for (int i=0;i<NbNormPrefixKeyb;i++) {
	    if ((TabNormPrefixKeyb[i].Ptr=(unsigned char*) alloca(MaxGenAscii*2))==NULL) return;
	    TabNormPrefixKeyb[i].NbAscii=0; }
	}
	CptNrmPrfx=CptPrfx=0;
//******Remplis PREFIX & NORM PREFIX KEYB***********************************
//**************************************************************************
	for (int i=0,CptNrmPrfx=0;i<NbElKbTb;i++)
	  if (KbTb[i].CanGenAscii) {
	    if (KbTb[i].IB->DefPrefix )
	      PrepNormKeybPrefix(&KbTb[i].IB->DefNbElDefPrefix,&KbTb[i].IB->DefTbDefPrefix,
     		KbTb[i].IB->DefAscDefTbDefPrefix,MYesDef,MNoDef,MDefActDef,
		KbTb[i].code,&KbTb[i].IB->MaskYesDef,&KbTb[i].IB->MaskNoDef);
	    if (KbTb[i].IB->ShifCapsPrefix )
	      PrepNormKeybPrefix(&KbTb[i].IB->ShifCapsNbElDefPrefix,&KbTb[i].IB->ShifCapsTbDefPrefix,
     		KbTb[i].IB->DefAscShifCapsTbDefPrefix,MYesShifCaps,MNoShifCaps,MDefActShifCaps,
		KbTb[i].code,&KbTb[i].IB->MaskYesDef,&KbTb[i].IB->MaskNoDef);
	    if (KbTb[i].IB->AltGRPrefix )
	      PrepNormKeybPrefix(&KbTb[i].IB->AltGrNbElDefPrefix,&KbTb[i].IB->AltGRTbDefPrefix,
     		KbTb[i].IB->DefAscAltGRTbDefPrefix,MYesAltGR,MNoAltGR,MDefActAltGR,
		KbTb[i].code,&KbTb[i].IB->MaskYesDef,&KbTb[i].IB->MaskNoDef);
	    if (KbTb[i].IB->AltLfPrefix )
	      PrepNormKeybPrefix(&KbTb[i].IB->AltLfNbElDefPrefix,&KbTb[i].IB->AltLfTbDefPrefix,
     		KbTb[i].IB->DefAscAltLfTbDefPrefix,MYesAltLf,MNoAltLf,MDefActAltLf,
		KbTb[i].code,&KbTb[i].IB->MaskYesDef,&KbTb[i].IB->MaskNoDef);
	    if (KbTb[i].IB->ShifNumPrefix )
	      PrepNormKeybPrefix(&KbTb[i].IB->ShifNumNbElDefPrefix,&KbTb[i].IB->ShifNumTbDefPrefix,
     		KbTb[i].IB->DefAscShifNumTbDefPrefix,MYesShifNum,MNoShifNum,MDefActShifNum,
		KbTb[i].code,&KbTb[i].IB->MaskYesDef,&KbTb[i].IB->MaskNoDef);
	    if (KbTb[i].IB->CtrlPrefix )
	      PrepNormKeybPrefix(&KbTb[i].IB->CtrlNbElDefPrefix,&KbTb[i].IB->CtrlTbDefPrefix,
     		KbTb[i].IB->DefAscCtrlTbDefPrefix,MYesCtrl,MNoCtrl,MDefActCtrl,
		KbTb[i].code,&KbTb[i].IB->MaskYesDef,&KbTb[i].IB->MaskNoDef);
	  }
//******Remplis NORM KEYB***************************************************
//**************************************************************************

	for (int i=0;i<NbElKbTb;i++)
	  if (KbTb[i].CanGenAscii) {

	    if ((!KbTb[i].IB->DefPrefix) && KbTb[i].IB->DefAscii) {
	      TabNormKeyb[0].MaskYes=KbTb[i].IB->MaskYesDef; TabNormKeyb[0].MaskNo=KbTb[i].IB->MaskNoDef;
	      TabNormKeyb[0].DefActiv=MDefActDef;
	      TabNormKeyb[0].Ptr[TabNormKeyb[0].NbAscii*2]=KbTb[i].code;
	      TabNormKeyb[0].Ptr[TabNormKeyb[0].NbAscii*2+1]=KbTb[i].IB->DefAscii;
	      TabNormKeyb[0].NbAscii++;  }
	    if ((!KbTb[i].IB->ShifCapsPrefix) && KbTb[i].IB->ShifCapsAscii) {
	      TabNormKeyb[1].MaskYes=KbTb[i].IB->MaskYesShifCaps; TabNormKeyb[1].MaskNo=KbTb[i].IB->MaskNoShifCaps;
	      TabNormKeyb[1].DefActiv=MDefActShifCaps;
	      TabNormKeyb[1].Ptr[TabNormKeyb[1].NbAscii*2]=KbTb[i].code;
	      TabNormKeyb[1].Ptr[TabNormKeyb[1].NbAscii*2+1]=KbTb[i].IB->ShifCapsAscii;
	      TabNormKeyb[1].NbAscii++;  }
	    if ((!KbTb[i].IB->AltGRPrefix) && KbTb[i].IB->AltGRAscii) {
	      TabNormKeyb[2].MaskYes=KbTb[i].IB->MaskYesAltGR; TabNormKeyb[2].MaskNo=KbTb[i].IB->MaskNoAltGR;
	      TabNormKeyb[2].DefActiv=MDefActAltGR;
	      TabNormKeyb[2].Ptr[TabNormKeyb[2].NbAscii*2]=KbTb[i].code;
	      TabNormKeyb[2].Ptr[TabNormKeyb[2].NbAscii*2+1]=KbTb[i].IB->AltGRAscii;
	      TabNormKeyb[2].NbAscii++;  }
	    if ((!KbTb[i].IB->AltLfPrefix) && KbTb[i].IB->AltLfAscii) {
	      TabNormKeyb[3].MaskYes=KbTb[i].IB->MaskYesAltLf; TabNormKeyb[3].MaskNo=KbTb[i].IB->MaskNoAltLf;
	      TabNormKeyb[3].DefActiv=MDefActAltLf;
	      TabNormKeyb[3].Ptr[TabNormKeyb[3].NbAscii*2]=KbTb[i].code;
	      TabNormKeyb[3].Ptr[TabNormKeyb[3].NbAscii*2+1]=KbTb[i].IB->AltLfAscii;
	      TabNormKeyb[3].NbAscii++;  }
	    if ((!KbTb[i].IB->ShifNumPrefix) && KbTb[i].IB->ShifNumAscii) {
	      TabNormKeyb[4].MaskYes=KbTb[i].IB->MaskYesShifNum; TabNormKeyb[4].MaskNo=KbTb[i].IB->MaskNoShifNum;
	      TabNormKeyb[4].DefActiv=MDefActShifNum;
	      TabNormKeyb[4].Ptr[TabNormKeyb[4].NbAscii*2]=KbTb[i].code;
	      TabNormKeyb[4].Ptr[TabNormKeyb[4].NbAscii*2+1]=KbTb[i].IB->ShifNumAscii;
	      TabNormKeyb[4].NbAscii++;  }
	    if ((!KbTb[i].IB->CtrlPrefix) && KbTb[i].IB->CtrlAscii) {
	      TabNormKeyb[5].MaskYes=KbTb[i].IB->MaskYesCtrl; TabNormKeyb[5].MaskNo=KbTb[i].IB->MaskNoCtrl;
	      TabNormKeyb[5].DefActiv=MDefActCtrl;
	      TabNormKeyb[5].Ptr[TabNormKeyb[5].NbAscii*2]=KbTb[i].code;
	      TabNormKeyb[5].Ptr[TabNormKeyb[5].NbAscii*2+1]=KbTb[i].IB->CtrlAscii;
	      TabNormKeyb[5].NbAscii++;  }
	  }
//**************************************************************************
//****SAUVEGARDE ***********************************************************
//**************************************************************************

	TabPosSaveNormKeyb=(unsigned int*)alloca(4*CptNbNormAscii);
	TabPosSaveNormPrefixKeyb=(unsigned int*)alloca(4*CptNrmPrfx);

	if ((FSKMAP=fopen(CreateKbMap,"wb"))==NULL) return;
	HeadKbMap.Sign='PAMK';

	HeadKbMap.TabPrefixKeyb=NULL;
	HeadKbMap.TabNormPrefixKeyb=HeadKbMap.TabNormKeyb=NULL,
	HeadKbMap.SizeKbMap=sizeof(KbMAP);
	HeadKbMap.NbPrefix=NbPrefix;
	HeadKbMap.NbNormPrefix=NbNormPrefixKeyb;
	HeadKbMap.NbPrefix=CptPrfx;
	HeadKbMap.NbNormPrefix=CptNrmPrfx;
	HeadKbMap.NbNorm=CptNbNormAscii;

	HeadKbMap.KbMapPtr=(void*)(sizeof(KbMAP));
	HeadKbMap.NbNorm=CptNbNormAscii;

	fseek(FSKMAP,sizeof(KbMAP),SEEK_SET); // saute l'entete
	CptTabPos=CptTabPrefixPos=0;
	// Sauvegarde DAT Norm KEYB -----------------------------------------
	for (int i=0;i<6;i++)
	  if (TabNormKeyb[i].NbAscii) {
	    TabPosSaveNormKeyb[CptTabPos]=ftell(FSKMAP);
	    fwrite(TabNormKeyb[i].Ptr,TabNormKeyb[i].NbAscii*2,1,FSKMAP);
	    TabNormKeyb[i].Ptr=(unsigned char*)TabPosSaveNormKeyb[CptTabPos];
	    CptTabPos++;
	  }
	// Sauvegarde DAT Norm PREFIX KEYB ----------------------------------
	for (int i=0;i<CptNrmPrfx;i++) {
	  TabPosSaveNormPrefixKeyb[CptTabPrefixPos]=ftell(FSKMAP);
	  fwrite(TabNormPrefixKeyb[i].Ptr,TabNormPrefixKeyb[i].NbAscii*2,1,FSKMAP);
	  TabNormPrefixKeyb[i].Ptr=
	    (unsigned char*)TabPosSaveNormPrefixKeyb[CptTabPrefixPos];
	  CptTabPrefixPos++;
	}
	// Aligne Position Fichier ------------------------------------------
	PosSave=ftell(FSKMAP);
	if (PosSave&3) {
	  CalcAlign=PosSave+3; CalcAlign&=0xfffffffc;
	  CalcAlign-=PosSave;
	  fwrite(AlignFile,1,CalcAlign,FSKMAP);
	}
	// Sauvegarde Enreg Norm KEYB ---------------------------------------
	CptTabPos=0;
	for (int i=0;i<6;i++)
	  if (TabNormKeyb[i].NbAscii) {
	    if (!CptTabPos) HeadKbMap.TabNormKeyb=(NormKeyb*)ftell(FSKMAP);
	    fwrite(&TabNormKeyb[i],sizeof(NormKeyb),1,FSKMAP);
	    CptTabPos++;
	  }

	// Sauvegarde Enreg Norm PREFIX KEYB --------------------------------
	if (CptNrmPrfx) HeadKbMap.TabNormPrefixKeyb=(NormKeyb*)ftell(FSKMAP);
	for (int i=0;i<CptPrfx;i++)
	  for (int j=0;j<TabPrefixKeyb[i].NbKeybNorm;j++) {
	    PosSave=ftell(FSKMAP);
	    fwrite(&TabPrefixKeyb[i].TabNormKeyb[j],sizeof(NormKeyb),1,FSKMAP);
	    if (j==0) TabPrefixKeyb[i].TabNormKeyb=(NormKeyb*)PosSave;
	  }
	// Sauvegarde Enreg PREFIX ------------------------------------------
	if (CptPrfx) HeadKbMap.TabPrefixKeyb=(PrefixKeyb*)ftell(FSKMAP);
	for (int i=0;i<CptPrfx;i++) {
	  fwrite(&TabPrefixKeyb[i],sizeof(PrefixKeyb),1,FSKMAP);
	}
	// MAJ entete
//DefMaskYes,DefMaskNo;
	HeadKbMap.CurPrefix= NULL;
	HeadKbMap.resv[0]= HeadKbMap.resv[1]= HeadKbMap.resv[2] =0;
	HeadKbMap.resv2[0]= HeadKbMap.resv2[1]= HeadKbMap.resv2[2] =0;

	HeadKbMap.SizeKbMap=ftell(FSKMAP)-sizeof(KbMAP);
	fseek(FSKMAP,0,SEEK_SET);
	fwrite(&HeadKbMap,sizeof(KbMAP),1,FSKMAP);

//***************************************************************************
//***************************************************************************

	fclose(FSKMAP);
}

int  Plus1Bit(unsigned int Mask) {
	int  TrouvBit=0,TestVal=Mask;
	for (;;) {
	  if (TestVal&1) TrouvBit=1;
	  TestVal>>=1;
	  if (TrouvBit && TestVal) return 1;
	  if (!TestVal) return 0;
	}
}



void PrepNormKeybPrefix(unsigned int *NbElPrefix,unsigned char *TbPrefix[],
     unsigned char DefAscPrefix,unsigned int MYes,unsigned int MNo, unsigned int MDefAct,
     unsigned char code,unsigned int *TbMYes,unsigned int *TbMNo)
{	unsigned char *CdChr;
	unsigned int  NbElAscPrefix=0,NbNrm=0,CptAsc;
        int FirstNorm=-1;
//	CptNrmPrfx,CptPrfx;
	for (int i=0;i<6;i++) {
	  if ((NbElAscPrefix=NbElPrefix[i])) {
	    CdChr=TbPrefix[i];
	    if (FirstNorm==-1) FirstNorm=CptNrmPrfx;
	    TabNormPrefixKeyb[CptNrmPrfx].MaskYes=TbMYes[i];
	    TabNormPrefixKeyb[CptNrmPrfx].MaskNo=TbMNo[i];
	    TabNormPrefixKeyb[CptNrmPrfx].DefActiv=TabMDefAct[i];
	    TabNormPrefixKeyb[CptNrmPrfx].NbAscii=NbElAscPrefix;
	    CptAsc=0;
	    for (int j=0;j<MaxGenAscii;j++) {
	      if (CdChr[j*2+1]) {
	      	TabNormPrefixKeyb[CptNrmPrfx].Ptr[CptAsc*2]=CdChr[j*2];
	      	TabNormPrefixKeyb[CptNrmPrfx].Ptr[CptAsc*2+1]=CdChr[j*2+1];
		CptAsc++; }
	      if (CptAsc==NbElAscPrefix) break;
	    }
	    NbNrm++;
	    CptNrmPrfx++;
	  }
	}
	if (NbNrm) {
	  TabPrefixKeyb[CptPrfx].MaskYes=MYes;
	  TabPrefixKeyb[CptPrfx].MaskNo=MNo;
	  TabPrefixKeyb[CptPrfx].DefActiv=MDefAct;
	  TabPrefixKeyb[CptPrfx].code=code;
	  TabPrefixKeyb[CptPrfx].DefaultAscii=DefAscPrefix;
	  TabPrefixKeyb[CptPrfx].NbKeybNorm=NbNrm;
	  TabPrefixKeyb[CptPrfx].TabNormKeyb=&TabNormPrefixKeyb[FirstNorm];
	  TabPrefixKeyb[CptPrfx].resv[0]=TabPrefixKeyb[CptPrfx].resv[1]=0;
	  TabPrefixKeyb[CptPrfx].resv2=0;
	  CptPrfx++;
	}
}

/*typedef struct
{	unsigned int	MaskYes,MaskNo,
			DefIfNbBitPair,
			NbAscii;
	unsigned char	*Ptr;	  // struct uchar code bouton, code ascii
} NormKeyb;

typedef struct
{	int		MaskYes,MaskNo,
			DefIfNbBitPair,
			NbKeybNorm;
	NormKeyb	*TabNormKeyb,
			*DefNormKeyb;
	unsigned char	DefaultAscii,code;
	char		resv[2];
} PrefixKeyb;

typedef struct
{	unsigned int	Sign,		   // == 'KMAP'
			Size;
	void		*KbMapPtr;
	int		NbPrefix;
	PrefixKeyb	*TabPrefixKeyb;
	int		NbNormPrefix;
	NormKeyb	*TabNormPrefixKeyb;
	int		NbNorm;
	NormKeyb	*TabNormKeyb;
	NormKeyb	*DefNormKeyb;
	int		resv[8];
} KbMAP;*/

