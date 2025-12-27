#ifndef DMGRAPH_H
#define DMGRAPH_H

extern Surf CurMSurf;
extern Surf CurMSrcSurf;


#ifdef __cplusplus
extern "C" {
#endif

int  SetMSurf(Surf *S); // set *S as the current drawing Surf
void SetSrcMSurf(Surf *S); // set *S as the current source Surf for texture or PutSurf ..
int  GetMaxResVSetMSurf(); // Max Height in pixels for a surf used with SetSurf
void GetMSurf(Surf *S); // get the current surf

#define MGRAPH_CURSURF_ID    0
#define MGRAPH_CURSRCSURF_ID 1
void SetOrgMSurf(int IDSurf,int LOrgX,int LOrgY);
void SetMSurfView(int IDSurf, View *V);
void SetMSurfInView(int IDSurf, View *V);
void MSetVectX(void *pVectX, int PlusNextX);
void MSetVectY(void *pVectY, int PlusNextY);
void MSetVectZ(void *pVectZ, int PlusNextZ);
void MSetVectCol(void *pVectCol, int PlusNextCol);
void MSetCol(int pCurCol);

void MPutPixels16(int PixelsCount);
void MCPutPixels16(int PixelsCount);
void MPtrPutPixels16(void *PVertices, int PixelsCount);
void MPtrCPutPixels16(void *PVertices, int PixelsCount);
void MLinesList16(int PointsCount);
void MLinesStrip16(int PointsCount);
void MPtrLinesList16(void *PVertices, int PixelsCount);
void MPtrLinesStrip16(void *PVertices, int PixelsCount);

#define MTRI16_SOLID		0
#define MTRI16_SOLID_BLND	1
#define MTRI16_MAX_TYPE		1

void MPtrTrisList16(void *PVertices, int PixelsCount, int TriType);
#ifdef __cplusplus
           }
#endif

#endif //#ifndef DMGRAPH_H
