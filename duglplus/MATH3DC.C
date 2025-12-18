#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include "Dmath3d.h"

float ftcos[256],ftsin[256];
FMatrix IdentityFMatrix =
      {	{ { 1.0, 0.0, 0.0, 0.0 },
	  { 0.0, 1.0, 0.0, 0.0 },
	  { 0.0, 0.0, 1.0, 0.0 },
	  { 0.0, 0.0, 0.0, 1.0 }}  };


void Init3DMath() {
   int i;
   for (i=0;i<256;i++) {
     ftcos[i]=cos(((i)*M_PI)/128.0); ftsin[i]=sin(((i)*M_PI)/128.0);
   }
}

void FMatrixMul(FMatrix *FM1,FMatrix *FM2,FMatrix *FMR) {
   FMatrix FMTmp;
   int i,j;
   for (i=0;i<4;i++)
     for (j=0;j<4;j++)
       FMTmp.LC[i][j]=FM1->LC[i][0]*FM2->LC[0][j]+
               	      FM1->LC[i][1]*FM2->LC[1][j]+
		      FM1->LC[i][2]*FM2->LC[2][j]+
		      FM1->LC[i][3]*FM2->LC[3][j];
   *FMR=FMTmp;
}

void GetIdentityFMatrix(FMatrix *FMI) {
   *FMI=IdentityFMatrix;
}

void GetXRotFMatrix(FMatrix *FMX, int Rx) {
   int rx=Rx&255;
   *FMX=IdentityFMatrix;
   FMX->LC[1][1]=ftcos[rx];  FMX->LC[2][1]=ftsin[rx];
   FMX->LC[1][2]=-ftsin[rx]; FMX->LC[2][2]=ftcos[rx];
}

void GetYRotFMatrix(FMatrix *FMY, int Ry) {
   int ry=Ry&255;
   *FMY=IdentityFMatrix;
   FMY->LC[0][0]=ftcos[ry]; FMY->LC[2][0]=-ftsin[ry];
   FMY->LC[0][2]=ftsin[ry]; FMY->LC[2][2]=ftcos[ry];
}

void GetZRotFMatrix(FMatrix *FMZ, int Rz) {
   int rz=Rz&255;
   *FMZ=IdentityFMatrix;
   FMZ->LC[0][0]=ftcos[rz];  FMZ->LC[1][0]=ftsin[rz];
   FMZ->LC[0][1]=-ftsin[rz]; FMZ->LC[1][1]=ftcos[rz];
}

void GetGRotFMatrix(FMatrix *FMG, int Rx, int Ry, int Rz) {
   int rx=Rx&255,ry=Ry&255,rz=Rz&255;
   float cx=ftcos[rx],sx=ftsin[rx],cy=ftcos[ry],sy=ftsin[ry],
         cz=ftcos[rz],sz=ftsin[rz],sx_sy=sx*sy,cx_sy=cx*sy;
   *FMG=IdentityFMatrix;
   FMG->LC[0][0]=cy*cz;
   FMG->LC[1][0]=cy*sz;
   FMG->LC[2][0]=-sy;
   FMG->LC[0][1]=(sx_sy*cz)-(cx*sz);
   FMG->LC[1][1]=(sx_sy*sz)+(cx*cz);
   FMG->LC[2][1]=sx*cy;
   FMG->LC[0][2]=(cx_sy*cz)+(sx*sz);
   FMG->LC[1][2]=(cx_sy*sz)-(sx*cz);
   FMG->LC[2][2]=cx*cy;
}
void GetGRotTransFMatrix(FMatrix *FMG, float Tx, float Ty, float Tz,
			 int Rx, int Ry, int Rz) {
   int rx=Rx&255,ry=Ry&255,rz=Rz&255;
   float cx=ftcos[rx],sx=ftsin[rx],cy=ftcos[ry],sy=ftsin[ry],
         cz=ftcos[rz],sz=ftsin[rz],sx_sy=sx*sy,cx_sy=cx*sy;
   *FMG=IdentityFMatrix;
   FMG->LC[0][0]=cy*cz;
   FMG->LC[1][0]=cy*sz;
   FMG->LC[2][0]=-sy;
   FMG->LC[0][1]=(sx_sy*cz)-(cx*sz);
   FMG->LC[1][1]=(sx_sy*sz)+(cx*cz);
   FMG->LC[2][1]=sx*cy;
   FMG->LC[0][2]=(cx_sy*cz)+(sx*sz);
   FMG->LC[1][2]=(cx_sy*sz)-(sx*cz);
   FMG->LC[3][0]=Tx; FMG->LC[3][1]=Ty; FMG->LC[3][2]=Tz;
}

void GetTransFMatrix(FMatrix *FMT, float Tx, float Ty, float Tz) {
   *FMT=IdentityFMatrix;
   FMT->LC[3][0]=Tx; FMT->LC[3][1]=Ty; FMT->LC[3][2]=Tz;
}

void ReverseFMatrix(FMatrix *FI,FMatrix *FO) {
   FMatrix FMTmp;
   int i,j;
   FMTmp=*FI;
   for (i=0;i<4;i++)
     for (j=0;j<4;j++) FO->LC[i][j]=FMTmp.LC[j][i];
}

void FMatrixRot(FMatrix *FM, int *InTXYZA, int *OutTXYZA, int NbPt) {
   int i,f=NbPt*4;
   for (i=0;i<f;i+=4) {
     OutTXYZA[i]=InTXYZA[i]*FM->LC[0][0]+
     	        InTXYZA[i+1]*FM->LC[1][0]+
		InTXYZA[i+2]*FM->LC[2][0];
     OutTXYZA[i+1]=InTXYZA[i]*FM->LC[0][1]+
                InTXYZA[i+1]*FM->LC[1][1]+
		InTXYZA[i+2]*FM->LC[2][1];
     OutTXYZA[i+2]=InTXYZA[i]*FM->LC[0][2]+
                InTXYZA[i+1]*FM->LC[1][2]+
		InTXYZA[i+2]*FM->LC[2][2];
   }
}

void FMatrixRotF(FMatrix *FM, float *InTXYZA, float *OutTXYZA, int NbPt) {
   int i,f=NbPt*4;
   for (i=0;i<f;i+=4) {
     OutTXYZA[i]=InTXYZA[i]*FM->LC[0][0]+
              InTXYZA[i+1]*FM->LC[1][0]+
              InTXYZA[i+2]*FM->LC[2][0];
     OutTXYZA[i+1]=InTXYZA[i]*FM->LC[0][1]+
                InTXYZA[i+1]*FM->LC[1][1]+
		InTXYZA[i+2]*FM->LC[2][1];
     OutTXYZA[i+2]=InTXYZA[i]*FM->LC[0][2]+
                InTXYZA[i+1]*FM->LC[1][2]+
		InTXYZA[i+2]*FM->LC[2][2];
   }
}

void FMatrixRotTrans(FMatrix *FM, int *InTXYZA, int *OutTXYZA, int NbPt) {
   int i,f=NbPt*4;
   for (i=0;i<f;i+=4) {
     OutTXYZA[i]=InTXYZA[i]*FM->LC[0][0]+
              InTXYZA[i+1]*FM->LC[1][0]+
	      InTXYZA[i+2]*FM->LC[2][0]+
	                  FM->LC[3][0];
     OutTXYZA[i+1]=InTXYZA[i]*FM->LC[0][1]+
                InTXYZA[i+1]*FM->LC[1][1]+
		InTXYZA[i+2]*FM->LC[2][1]+
		            FM->LC[3][1];
     OutTXYZA[i+2]=InTXYZA[i]*FM->LC[0][2]+
                InTXYZA[i+1]*FM->LC[1][2]+
		InTXYZA[i+2]*FM->LC[2][2]+
		            FM->LC[3][2];
   }
}

void FMatrixRotTransF(FMatrix *FM, float *InTXYZA, float *OutTXYZA, int NbPt) {
   int i,f=NbPt*4;
   for (i=0;i<f;i+=4) {
     OutTXYZA[i]=InTXYZA[i]*FM->LC[0][0]+
              InTXYZA[i+1]*FM->LC[1][0]+
  	      InTXYZA[i+2]*FM->LC[2][0]+
	                  FM->LC[3][0];
     OutTXYZA[i+1]=InTXYZA[i]*FM->LC[0][1]+
                InTXYZA[i+1]*FM->LC[1][1]+
		InTXYZA[i+2]*FM->LC[2][1]+
		            FM->LC[3][1];
     OutTXYZA[i+2]=InTXYZA[i]*FM->LC[0][2]+
                InTXYZA[i+1]*FM->LC[1][2]+
		InTXYZA[i+2]*FM->LC[2][2]+
		            FM->LC[3][2];
   }
}

