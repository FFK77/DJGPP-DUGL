#ifndef DCONTROL_H

#define DCONTROL_H

//** CONTROL : KEYBOARD-MOUSE-TIMER-(JOYSTICK)  ****************************
//**************************************************************************
//***** Mouse event
typedef struct
{       int		MsX,
                        MsY,
                        MsZ;
        unsigned int    MsButton,
                        MsEvents;
} MouseEvent;

//***** Keyboard MAP *** MAP*********************************
typedef struct
{	unsigned int	MaskYes,MaskNo,
			DefActiv,
			NbAscii;
	unsigned char	*Ptr;	  // struct uchar code bouton, code ascii
} NormKeyb;

typedef struct
{	int		MaskYes,MaskNo,
			DefActiv,
			NbKeybNorm;
	NormKeyb	*TabNormKeyb;
	int		resv2;
	unsigned char	DefaultAscii,code;
	char		resv[2];
} PrefixKeyb;

typedef struct
{	unsigned int 	Sign,		   // == 'KMAP'
			SizeKbMap;
	void		*KbMapPtr;
	int		NbPrefix;
	PrefixKeyb	*TabPrefixKeyb;
	int		NbNormPrefix;
	NormKeyb	*TabNormPrefixKeyb;
	int		NbNorm;
	NormKeyb	*TabNormKeyb;
	int		resv2[3];
	PrefixKeyb	*CurPrefix;
	int		resv[3];
} KbMAP;


#ifdef __cplusplus
extern "C" {
#endif

// Mouse Handling installing functions
// -----------------------------------

#define MS_LEFT_BUTT 	1
#define MS_RIGHT_BUTT 	2
#define MS_MID_BUTT 	4

/*Mouse events*/
#define MS_EVNT_MOUSE_MOVE  1
#define MS_EVNT_LBUTT_PRES  2
#define MS_EVNT_LBUTT_RELS  4
#define MS_EVNT_RBUTT_PRES  8
#define MS_EVNT_RBUTT_RELS  16
#define MS_EVNT_MBUTT_PRES  32
#define MS_EVNT_MBUTT_RELS  64
#define MS_EVNT_WHEEL_MOVE  128

extern int MsX,MsY,MsZ,MsButton,MsSpeedHz,MsSpeedVt,MsAccel;
int  InstallMouse();
void UninstallMouse();
int IsMouseWheelSupported(); // return 1 if mouse wheel supported
void SetMouseRView(View *V);
void GetMouseRView(View *V);
void SetMouseOrg(int MsOrgX,int MsOrgY);
void SetMousePos(int MouseX,int MouseY);
void SetMouseSpeed(int MouseHzSpeed,int MouseVtSpeed);
//void SetMouseAccel(int MouseAccel);
void EnableMsEvntsStack();
void DisableMsEvntsStack();
void ClearMsEvntsStack();
int GetMsEvent(MouseEvent *MsEvnt);

// TIMER & Synch Functions
// -----------------------

#define TIMER_TICK_SEC 1193180
#define SIZE_SYNCH_BUFF 168
extern unsigned int Time,TimerFreq,TimerTickVal;

int  InstallTimer(unsigned int Freq);  // Min Freq 19
void UninstallTimer();
int  InitSynch(void *SynchBuff,int *Pos,float Freq); // init Synch buffer and start synching
void StartSynch(void *SynchBuff,int *Pos); // Restart Synching
int  Synch(void *SynchBuff,int *Pos); // synch
float SynchAccTime(void *SynchBuff); // time "in sec" since InitSynch or StartSynch
float SynchAverageTime(void *SynchBuff); // average time "in sec" between Synch calls
float SynchLastTime(void *SynchBuff); // last non zero time "in sec" between Synch calls
int  WaitSynch(void *SynchBuff,int *Pos);

// KEYBOARD and Keyboard MAP Functions
// -----------------------------------

// KbFLAG Masks
#define KB_RIGHT_SHIFT_PR 0x1	// BIOS STANDARS
#define KB_LEFT_SHIFT_PR 0x2
#define KB_CTRL_PR	 0x4
#define KB_ALT_PR	 0x8
#define KB_SCROLL_ACT	 0x10
#define KB_NUM_ACT	 0x20
#define KB_CAPS_ACT	 0x40
#define KB_INS_ACT	 0x80
#define KB_LEFT_CTRL_PR	 0x100
#define KB_LEFT_ALT_PR	 0x200
#define KB_SYS_REQ_PR	 0x400
#define KB_PAUSE_ACT	 0x800
#define KB_SCROLL_PR	 0x1000
#define KB_NUM_PR	 0x2000
#define KB_CAPS_PR	 0x4000
#define KB_INS_PR	 0x8000
#define KB_TAB_PR	 0x10000 // DUGL Masks
#define KB_ENTER_PR	 0x20000
#define KB_SPACE_PR	 0x40000
#define KB_UP_PR	 0x80000
#define KB_DOWN_PR	 0x100000
#define KB_RIGHT_PR	 0x200000
#define KB_LEFT_PR	 0x400000
#define KB_PAD_INS_PR	 0x800000
#define KB_RIGHT_CTRL_PR 0x1000000
#define KB_RIGHT_ALT_PR	 0x2000000
#define KB_PG_UP_PR	 0x4000000
#define KB_PG_DWN_PR	 0x8000000
#define KB_BEG_PR	 0x10000000
#define KB_END_PR	 0x20000000
#define KB_SUPPR_PR	 0x40000000
#define KB_SHIFT_PR	 0x80000000
// Kb Delay Rate
#define KB_DELAY_250MS  0x00
#define KB_DELAY_500MS  0x20
#define KB_DELAY_750MS  0x40
#define KB_DELAY_1000MS 0x60
#define KB_RATE_30_0    0x00
#define KB_RATE_26_7    0x01
#define KB_RATE_24_0    0x02
#define KB_RATE_20_0    0x04
#define KB_RATE_15_0    0x08
#define KB_RATE_10_0    0x0A
#define KB_RATE_9_2     0x0D
#define KB_RATE_7_5     0x10
#define KB_RATE_5_0     0x14
#define KB_RATE_2_0     0x1F

extern unsigned int KbFLAG,KbApp[8],KeyKbFLAG,AsciiKbFLAG;
extern unsigned char LastKey,LastAscii;
extern KbMAP CurKbMAP;

int  InstallKeyboard();
void UninstallKeyboard();
int  IsKeyDown(unsigned int NumKey);
int  PauseKeyPressed();
int  WaitKeyPressed();
void SetKeybRateDelay(int RateDelay);
void GetKey(unsigned char *Key,unsigned int *KeyFLAG);
void WaitGetKey(unsigned char *Key,unsigned int *KeyFLAG);
int  GetKeyNbElt();
void ClearKeyCircBuff();
unsigned int GetCurrTimeKeyDown(unsigned int Key);
void GetTimedKeyDown(unsigned char *Key,unsigned int *KeyTime);
int GetTimedKeyNbElt();
void ClearTimedKeyCircBuff();
// keyboar MAP
int  LoadMemKbMAP(KbMAP **KM,void *In,int SizeIn);
int  LoadKbMAP(KbMAP **KM,const char *Fname);
void DestroyKbMAP(KbMAP *KM);
int  SetKbMAP(KbMAP *KM);
int  GetKbMAP(KbMAP *KM);
void DisableCurKbMAP();
unsigned char GetAscii(unsigned char *Ascii,unsigned int *AsciiFLAG);
unsigned char WaitGetAscii(unsigned char *Ascii,unsigned int *AsciiFLAG);
int  GetAsciiNbElt();
void ClearAsciiCircBuff();

#ifdef __cplusplus
           }
#endif

#endif // #define DCONTROL_H
