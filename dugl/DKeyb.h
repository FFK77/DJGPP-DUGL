#ifndef DKEYB_H_INCLUDED
#define DKEYB_H_INCLUDED

// KEYBOARD and Keyboard MAP Functions
// -----------------------------------

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


// KbFLAG Masks
#define KB_RIGHT_SHIFT_PR   0x1	// BIOS STANDARS
#define KB_LEFT_SHIFT_PR    0x2
#define KB_CTRL_PR	        0x4
#define KB_ALT_PR	        0x8
#define KB_SCROLL_ACT	    0x10
#define KB_NUM_ACT	        0x20
#define KB_CAPS_ACT	        0x40
#define KB_INS_ACT	        0x80
#define KB_LEFT_CTRL_PR	    0x100
#define KB_LEFT_ALT_PR	    0x200
#define KB_SYS_REQ_PR	    0x400
#define KB_PAUSE_ACT	    0x800
#define KB_SCROLL_PR	    0x1000
#define KB_NUM_PR	        0x2000
#define KB_CAPS_PR	        0x4000
#define KB_INS_PR	        0x8000
#define KB_TAB_PR	        0x10000 // DUGL Masks
#define KB_ENTER_PR	        0x20000
#define KB_SPACE_PR	        0x40000
#define KB_UP_PR	        0x80000
#define KB_DOWN_PR	        0x100000
#define KB_RIGHT_PR	        0x200000
#define KB_LEFT_PR	        0x400000
#define KB_PAD_INS_PR	    0x800000
#define KB_RIGHT_CTRL_PR    0x1000000
#define KB_RIGHT_ALT_PR	    0x2000000
#define KB_PG_UP_PR	        0x4000000
#define KB_PG_DWN_PR	    0x8000000
#define KB_BEG_PR	        0x10000000
#define KB_END_PR	        0x20000000
#define KB_SUPPR_PR	        0x40000000
#define KB_SHIFT_PR	        0x80000000
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

// Kb key code
#define KB_KEY_ESC          0x01
#define KB_KEY_1            0x02
#define KB_KEY_2            0x03
#define KB_KEY_3            0x04
#define KB_KEY_4            0x05
#define KB_KEY_5            0x06
#define KB_KEY_6            0x07
#define KB_KEY_7            0x08
#define KB_KEY_8            0x09
#define KB_KEY_9            0x0a
#define KB_KEY_0            0x0b
#define KB_KEY_BACKSPACE    0x0e
#define KB_KEY_QWERTY_A     0x1e
#define KB_KEY_QWERTY_B     0x2e
#define KB_KEY_QWERTY_C     0x30
#define KB_KEY_QWERTY_D     0x20
#define KB_KEY_QWERTY_E     0x12
#define KB_KEY_QWERTY_F     0x21
#define KB_KEY_QWERTY_G     0x22
#define KB_KEY_QWERTY_H     0x23
#define KB_KEY_QWERTY_I     0x17
#define KB_KEY_QWERTY_J     0x24
#define KB_KEY_QWERTY_K     0x25
#define KB_KEY_QWERTY_L     0x26
#define KB_KEY_QWERTY_M     0x32
#define KB_KEY_QWERTY_N     0x31
#define KB_KEY_QWERTY_O     0x18
#define KB_KEY_QWERTY_P     0x19
#define KB_KEY_QWERTY_Q     0x10
#define KB_KEY_QWERTY_R     0x13
#define KB_KEY_QWERTY_S     0x1f
#define KB_KEY_QWERTY_T     0x14
#define KB_KEY_QWERTY_U     0x16
#define KB_KEY_QWERTY_V     0x2f
#define KB_KEY_QWERTY_W     0x11
#define KB_KEY_QWERTY_X     0x2d
#define KB_KEY_QWERTY_Y     0x15
#define KB_KEY_QWERTY_Z     0x2c
#define KB_KEY_TAB          0x0f
#define KB_KEY_ENTER        0x1c
#define KB_KEY_LEFT_CTRL    0x1d
#define KB_KEY_LEFT_SHIFT   0x2a
#define KB_KEY_RIGHT_SHIFT  0x36
#define KB_KEY_LEFT_ALT     0x38
#define KB_KEY_SPACE        0x39
#define KB_KEY_F1           0x3b
#define KB_KEY_F2           0x3c
#define KB_KEY_F3           0x3d
#define KB_KEY_F4           0x3e
#define KB_KEY_F5           0x3f
#define KB_KEY_F6           0x40
#define KB_KEY_F7           0x41
#define KB_KEY_F8           0x42
#define KB_KEY_F9           0x43
#define KB_KEY_F10          0x44
#define KB_KEY_F11          0x57
#define KB_KEY_F12          0x58
#define KB_KEY_RIGHT_CTRL   0x9d
#define KB_KEY_RIGHT_ALT    0xb8
#define KB_KEY_HOME         0xc7
#define KB_KEY_UP           0xc8
#define KB_KEY_PGUP         0xc9
#define KB_KEY_END          0xcf
#define KB_KEY_DOWN         0xd0
#define KB_KEY_PGDOWN       0xd1
#define KB_KEY_INSERT       0xd2
#define KB_KEY_DELETE       0xd3
#define KB_KEY_LEFT         0xcb
#define KB_KEY_RIGHT        0xcd

extern unsigned int KbFLAG,KbApp[8],KeyKbFLAG,AsciiKbFLAG;
extern unsigned char LastKey,LastAscii;
extern KbMAP CurKbMAP;

#ifdef __cplusplus
extern "C" {
#endif

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


#endif // DKEYB_H_INCLUDED
