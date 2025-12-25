#ifndef DMOUSE_H_INCLUDED
#define DMOUSE_H_INCLUDED


//***** Mouse event
typedef struct
{       int		MsX,
                        MsY,
                        MsZ;
        unsigned int    MsButton,
                        MsEvents;
} MouseEvent;


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

#ifdef __cplusplus
extern "C" {
#endif

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

#ifdef __cplusplus
           }
#endif


#endif // DMOUSE_H_INCLUDED
