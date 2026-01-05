#include <dos.h>
#include <dpmi.h>
#include <dos.h>
#include <go32.h>
#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <crt0.h>
#include <unistd.h>
#include <string.h>
#include <sys/movedata.h>
#include <sys/segments.h>
#include "dugl.h"
#include "intrdugl.h"

//MouseEvent MsEventsStack[256];
//int MsStackNbElt=0,MsStackEnable=0;

int  LoadKbMAP(KbMAP **KMap,const char *Fname)
{	FILE *InKbMAP;
	KbMAP KM;
	int Size,i;
	unsigned int Buff;

	if ((InKbMAP=fopen(Fname,"rb"))==NULL) return 0;
	if (fread(&KM,sizeof(KbMAP),1,InKbMAP)<1) return 0;
	fseek(InKbMAP,0,SEEK_END);
	Size=ftell(InKbMAP);
	if (KM.Sign!='PAMK' || KM.SizeKbMap!=(Size-sizeof(KbMAP)))
	  { fclose(InKbMAP); return 0; }
	if ((*KMap=(KbMAP*) malloc(KM.SizeKbMap+sizeof(KbMAP)))==NULL)
	  { fclose(InKbMAP); return 0; }
	Buff=(unsigned int)(*KMap);

	fseek(InKbMAP,0,SEEK_SET);
	if (fread(*KMap,KM.SizeKbMap+sizeof(KbMAP),1,InKbMAP)<1)
	  { free(*KMap); fclose(InKbMAP); return 0; }

	// Ajuste les pointeur
	(*KMap)->KbMapPtr=(void*)((unsigned int)((*KMap)->KbMapPtr)+Buff);
	if ((*KMap)->TabPrefixKeyb!=NULL)
	  (*KMap)->TabPrefixKeyb=
	    (PrefixKeyb*)((unsigned int)((*KMap)->TabPrefixKeyb)+Buff);
	if ((*KMap)->TabNormPrefixKeyb!=NULL)
	  (*KMap)->TabNormPrefixKeyb=
	    (NormKeyb*)((unsigned int)((*KMap)->TabNormPrefixKeyb)+Buff);
	if ((*KMap)->TabNormKeyb!=NULL)
	  (*KMap)->TabNormKeyb=
	    (NormKeyb*)((unsigned int)((*KMap)->TabNormKeyb)+Buff);

	if ((*KMap)->TabNormKeyb!=NULL)
	  for (i=0;i<(*KMap)->NbNorm;i++)
	    (*KMap)->TabNormKeyb[i].Ptr=
	      (unsigned char*)((unsigned int)((*KMap)->TabNormKeyb[i].Ptr)+Buff);
	if ((*KMap)->TabNormPrefixKeyb!=NULL)
	  for (i=0;i<(*KMap)->NbNormPrefix;i++)
	    (*KMap)->TabNormPrefixKeyb[i].Ptr=
	      (unsigned char*)((unsigned int)((*KMap)->TabNormPrefixKeyb[i].Ptr)+Buff);
	if ((*KMap)->TabPrefixKeyb!=NULL)
	  for (i=0;i<(*KMap)->NbPrefix;i++) {
	    (*KMap)->TabPrefixKeyb[i].TabNormKeyb=
	      (NormKeyb*)((unsigned int)((*KMap)->TabPrefixKeyb[i].TabNormKeyb)+Buff);
	  }
	fclose(InKbMAP);
	return 1;
}

int  LoadMemKbMAP(KbMAP **KMap,void *In,int SizeIn)
{	KbMAP KM;
	int i;
	unsigned int Buff;

	memcpy(&KM,In,sizeof(KbMAP));
	if (KM.Sign!='PAMK' || KM.SizeKbMap!=(SizeIn-sizeof(KbMAP))) return 0;
	if ((*KMap=(KbMAP*)malloc(KM.SizeKbMap+sizeof(KbMAP)))==NULL) return 0;
	Buff=(unsigned int)(*KMap);
	memcpy(*KMap,In,KM.SizeKbMap+sizeof(KbMAP));

	// Ajuste les pointeur
	(*KMap)->KbMapPtr=(void*)((unsigned int)((*KMap)->KbMapPtr)+Buff);
	if ((*KMap)->TabPrefixKeyb!=NULL)
	  (*KMap)->TabPrefixKeyb=
	    (PrefixKeyb*)((unsigned int)((*KMap)->TabPrefixKeyb)+Buff);
	if ((*KMap)->TabNormPrefixKeyb!=NULL)
	  (*KMap)->TabNormPrefixKeyb=
	    (NormKeyb*)((unsigned int)((*KMap)->TabNormPrefixKeyb)+Buff);
	if ((*KMap)->TabNormKeyb!=NULL)
	  (*KMap)->TabNormKeyb=
	    (NormKeyb*)((unsigned int)((*KMap)->TabNormKeyb)+Buff);

	if ((*KMap)->TabNormKeyb!=NULL)
	  for (i=0;i<(*KMap)->NbNorm;i++)
	    (*KMap)->TabNormKeyb[i].Ptr=
	      (unsigned char*)((unsigned int)((*KMap)->TabNormKeyb[i].Ptr)+Buff);
	if ((*KMap)->TabNormPrefixKeyb!=NULL)
	  for (i=0;i<(*KMap)->NbNormPrefix;i++)
	    (*KMap)->TabNormPrefixKeyb[i].Ptr=
	      (unsigned char*)((unsigned int)((*KMap)->TabNormPrefixKeyb[i].Ptr)+Buff);
	if ((*KMap)->TabPrefixKeyb!=NULL)
	  for (i=0;i<(*KMap)->NbPrefix;i++) {
	    (*KMap)->TabPrefixKeyb[i].TabNormKeyb=
	      (NormKeyb*)((unsigned int)((*KMap)->TabPrefixKeyb[i].TabNormKeyb)+Buff);
	  }
	return 1;
}

void DestroyKbMAP(KbMAP *KM) {
   if (KM) free(KM);
}





