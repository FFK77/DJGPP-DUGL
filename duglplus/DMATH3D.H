#ifndef DMATH3D_H

#define DMATH3D_H

typedef struct {
	float LC[4][4];
} FMatrix;

typedef struct {
	float x,y,z,a;
} F3DPoint;

#ifdef __cplusplus
extern "C" {
#endif

extern float ftcos[256],ftsin[256];

void Init3DMath();
void FMatrixMul(FMatrix *FM1,FMatrix *FM2,FMatrix *FMR);
void GetIdentityFMatrix(FMatrix *FMI);
void GetXRotFMatrix(FMatrix *FMX, int Rx);
void GetYRotFMatrix(FMatrix *FMY, int Ry);
void GetZRotFMatrix(FMatrix *FMZ, int Rz);
void GetGRotFMatrix(FMatrix *FMG, int Rx, int Ry, int Rz);
void GetGRotTransFMatrix(FMatrix *FMG, float Tx, float Ty, float Tz,
			 int Rx, int Ry, int Rz);
void GetTransFMatrix(FMatrix *FMT, float Tx, float Ty, float Tz);
void ReverseFMatrix(FMatrix *FI,FMatrix *FO);
// applying FMatrix
void FMatrixRot(FMatrix *FM, int *InTXYZA, int *OutTXYZA, int NbPt);
void FMatrixRotF(FMatrix *FM, float *InTXYZA, float *OutTXYZA, int NbPt);
void FMatrixRotTrans(FMatrix *FM, int *InTXYZA, int *OutTXYZA, int NbPt);
void FMatrixRotTransF(FMatrix *FM, float *InTXYZA, float *OutTXYZA, int NbPt);

#ifdef __cplusplus
           }
#endif

#endif //#ifndef DMATH3D_H
