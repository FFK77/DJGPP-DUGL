#ifndef DTIMER_H_INCLUDED
#define DTIMER_H_INCLUDED

// TIMER & Synch Functions
// -----------------------

#define TIMER_TICK_SEC 1193180
#define SIZE_SYNCH_BUFF 168
extern unsigned int DgTime, DgTimerFreq, DgTimerTickVal;

#ifdef __cplusplus
extern "C" {
#endif

int  DgInstallTimer(unsigned int Freq);  // Min Freq 19
void DgUninstallTimer();
void DgDelay(unsigned int ms); // wait for ms milli seconds, if Timer not installed, exit immediately
int  InitSynch(void *SynchBuff,int *Pos,float Freq); // init Synch buffer and start synching
void StartSynch(void *SynchBuff,int *Pos); // Restart Synching
int  Synch(void *SynchBuff,int *Pos); // synch
float SynchAccTime(void *SynchBuff); // time "in sec" since InitSynch or StartSynch
float SynchAverageTime(void *SynchBuff); // average time "in sec" between Synch calls
float SynchLastTime(void *SynchBuff); // last non zero time "in sec" between Synch calls
int  WaitSynch(void *SynchBuff,int *Pos);

#ifdef __cplusplus
           }
#endif



#endif // DTIMER_H_INCLUDED
