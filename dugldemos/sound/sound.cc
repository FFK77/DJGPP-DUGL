/*  DUGL Dos Ultimate Game Library - sound Sample */
/*  History : */
/*  26 august  2008 : first release */
/*  11 august  2009 : update with DUGL Plus 0.3 and Sound blaster pro driver */

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
#include <dugl/dsound.h>
#include <dugl/dugl.h>


int MasterVol=200,EffectVol=200;

VoicePack VP;
SoundDRV *SD;
void *Buff;


Voice VcMenu;
int voiceMenuPos;

void AddVoice(Voice *Vc,int State);

int main(int argc,char *argv[])
{

        // load the sound driver
	if (!LoadSoundDRV(&SD,"sbpro.drv"))
	  { printf("ac97.drv error loading\n"); exit(-1); }
        printf("pass1\n");
        // alloc the memory buffer needed by the sound driver
	if ((Buff=malloc(SD->SizeBuff))==NULL)
	  { printf("no mem \n"); exit(-1); }
        // try to install the sound driver -1 means AUTODETECT
	if (!SD->InstallDriver(Buff,-1,5,1,-1)) {
           DestroySoundDRV(SD);
           free(Buff);
           printf("No sound card detected :(\n");
           exit(-1);
	}

        printf("Playing sound with : %s\nEsc to exit\n",
                SD->CardName);
/*        printf("config space:\n");
        printf("IRQ %x, Base Port adress %x\n",SD->Card_IRQ,SD->Card_BasePort);
        for(int i=0;i<16;i++)
          printf("%02x:%08x\n",i*4,SD->resv[i]);
        exit(-1);*/
	if (!InstallKeyboard())
	  { printf("Keyboard error\n");  exit(-1); }
        
        // load sound ressources
	if (!LoadWAV(&VcMenu,"sounder.wav"))
	  { printf("menu.wav introuvable\n"); exit(-1); }
        // default volume
	SD->SetMasterVolume(MasterVol,MasterVol);
	SD->SetVoiceVolume(EffectVol,EffectVol);
        // prepare sounds : memory locking
	if (!SD->PrepareVoice(&VcMenu))
	  { printf("no mem \n"); exit(-1); }

        // start the sound output

	SD->InitSound(DS_OUT8BIT,DS_NOSOUND,DS_MONO,22100);
	AddVoice(&VcMenu,DS_VC_LOOPING);
        for (;;) {
           // exit if no sound inside the mixer
           if (SD->GetNbVoice()==0) break;
           if (BoutApp(1)) break;
        }

	// unlock memory
	SD->UnprepareVoice(&VcMenu);

	SD->UninstallDriver();
	DestroySoundDRV(SD);
        free(Buff);

        //UninstallKeyboard();
        return 0;
}


void AddVoice(Voice *Vc,int State)
{
        // adjust the speed of the voice if it's speed is inequal with
        // the current sampling speed
        if (SD->Cur_SampSpeed!=Vc->Freq) {
	  VP.Speed=(128*Vc->Freq)/SD->Cur_SampSpeed;
	  SD->AddVoice(Vc,DS_EFF_CHG_SPEED,State,&VP,0);
	}
        else // else add as it*/
          SD->AddVoice(Vc,0,State,NULL,0);
}

