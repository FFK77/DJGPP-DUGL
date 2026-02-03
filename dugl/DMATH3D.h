
#ifndef DMATH3D_H_INCLUDED
#define DMATH3D_H_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

// 3D Math support =====================================================================

typedef union {
    struct { float x, y, z, d; };
    float v[4];
} DVEC4;

typedef union {
    struct { int x, y, z, d; };
    int v[4];
} DVEC4i;

typedef union {
    struct { float x, y; };
    float v[2];
} DVEC2;

typedef union {
    struct { int x, y; };
    int v[2];
} DVEC2i;

typedef union {
    struct { DVEC4 min; DVEC4 max; };
    DVEC4 v[2];
} DAAMinBBox;

typedef union {
    struct {
        DVEC4 front_bottom_left;    DVEC4 front_bottom_right;
        DVEC4 front_top_right;      DVEC4 front_top_left;
        DVEC4 back_bottom_left;     DVEC4 back_bottom_right;
        DVEC4 back_top_right;       DVEC4 back_top_left;
    };
    DVEC4 v[8];
} DAABBox;

typedef union {
    struct { DVEC4 rows[4]; };
    float rc[4][4];
    float raw[16];
} DMatrix4;

// create/Init/Destroy
void *CreateDVEC4();
void *CreateDVEC4Array(int count);
DVEC4 *CreateInitDVEC4(float x, float y, float z, float d);
DVEC4 *CreateInitDVEC4Array(DVEC4 *vec4init, int count);
DVEC4i *CreateInitDVEC4i(int x, int y, int z, int d);
DVEC4i *CreateInitDVEC4iArray(DVEC4i *vec4init, int count);
void DestroyDVEC4(void *vec4);
void *CreateDVEC2();
void *CreateDVEC2Array(int count);
void DestroyDVEC2(void *vec2);

// Math op : Mul/Add/Sub/Cross/Distance/Dot ..
float *DistanceDVEC4(DVEC4 *v1, DVEC4 *v2, float *distanceRes);
float *DistancePow2DVEC4(DVEC4 *v1, DVEC4 *v2, float *distancePow2Res);
//  store dot of v1 and v2 in [dotRes]
float *DotDVEC4(DVEC4 *v1, DVEC4 *v2, float *dotRes);
// normalize v1 and v2 then store dot in [dotRes], if any of v1 and v2 length is zero, dotRes will be 0.0f
float *DotNormalizeDVEC4(DVEC4 *v1, DVEC4 *v2, float *dotRes);
float *LengthDVEC4(DVEC4 *vec4, float *lengthRes);
DVEC4 *NormalizeDVEC4(DVEC4 *vec4);
DVEC4 *NormalizeDVEC4Res(DVEC4 *vec4, DVEC4 *nvres);
DVEC4 *CrossDVEC4(DVEC4 *v1, DVEC4 *v2, DVEC4 *vcrossRes);
DVEC4 *CrossNormalizeDVEC4(DVEC4 *v1, DVEC4 *v2, DVEC4 *vcrossRes);
// vRes = v1 + ((v2 - v1) * alpha)
DVEC4 *LerpDVEC4Res(float alpha, DVEC4 *v1, DVEC4 *v2, DVEC4 *vlerpRes);
DVEC4 *MulValDVEC4(DVEC4 *vec4, float val);
DVEC4 *MulValDVEC4Res(DVEC4 *v, float val, DVEC4 *vres);
void MulValDVEC4Array(DVEC4 *vec4array, int count, float val);
void MulDVEC4Array(DVEC4 *vec4array, int count, DVEC4 *vmul);
DVEC4 *MulDVEC4(DVEC4 *v1, DVEC4 *v2);
DVEC4 *MulDVEC4Res(DVEC4 *v1, DVEC4 *v2, DVEC4 *vresMul);
DVEC4 *AddDVEC4(DVEC4 *v1, DVEC4 *v2);
DVEC4 *AddDVEC4Res(DVEC4 *v1, DVEC4 *v2, DVEC4 *vresAdd);
void AddDVEC4Array(DVEC4 *vec4array, int count, DVEC4 *vplus);
DVEC4 *SubDVEC4(DVEC4 *v1, DVEC4 *v2); // v1 = v1 - v2
DVEC4 *SubDVEC4Res(DVEC4 *v1, DVEC4 *v2, DVEC4 *vresSub); // vresSub = v1 - v2
DVEC4 *SubNormalizeDVEC4(DVEC4 *v1, DVEC4 *v2); // v1 = Normalize(v1 - v2)
DVEC4 *SubNormalizeDVEC4Res(DVEC4 *v1, DVEC4 *v2, DVEC4 *vresSubNormalize); // vresSubNormalize = Normalize(v1 - v2)
void MulVEC2ArrayVEC2ValDVec2iArrayRes(DVEC2 *vec2array, int count, DVEC2 *MulVal, DVEC2i *vec2iArrayRes);
void MulVEC2ArrayVEC2ValDVec2iArrayResNT(DVEC2 *vec2array, int count, DVEC2 *MulVal, DVEC2i *vec2iArrayRes);
// Conversion/Copy/Clip /////////////////////////////////////////
void DVEC42DVec4i(DVEC4i *vec4iDst, DVEC4 *vec4Src);
void DVec4i2DVEC4(DVEC4 *vec4Dst, DVEC4i *vec4iSrc);
void DVEC22DVec2i(DVEC2i *vec2iDst, DVEC2 *vec2Src);
void DVec2i2DVEC2(DVEC2 *vec2Dst, DVEC2i *vec2iSrc);
void DVEC4Array2DVec4i(DVEC4i *vec4iArrayDst, DVEC4 *vec4ArraySrc, int count);
#define DVEC4Array2DVec4iNT DVEC4Array2DVec4i
void DVEC4iArray2DVec4(DVEC4 *vec4ArrayDst, DVEC4i *vec4ArraySrc, int count);
#define DVEC4iArray2DVec4NT DVEC4iArray2DVec4
void ClipDVEC4Array(DVEC4 *vec4Array, int count, DVEC4 *vec4_min, DVEC4 *vec4_max);
void CopyDVEC4(void *vec4ArrayDst, void *vec4ArraySrc, int count);
#define CopyDVEC4NT CopyDVEC4
void StoreDVEC4(void *vec4ArrayDst, void *vec4ElemSrc, int count);
#define StoreDVEC4NT StoreDVEC4

// search/AABBox/Filtering/compare ///////////////////////////////////////
bool EqualDVEC4(DVEC4 *v1, DVEC4 *v2);
void FetchDAAMinBBoxDVEC4Array(DVEC4 *vec4Array, int count, DAAMinBBox *aaMinBboxRes);
void FetchDAABBoxDVEC4Array(DVEC4 *vec4Array, int count, DAABBox *aaBboxRes);
/* return min of the x, y, z, d components merged in res DVEC4 */
void DVEC4MinRes(DVEC4 *v1, DVEC4 *v2, DVEC4 *vec4_minRes);
/* return max of the x, y, z, d components merged in res DVEC4 */
void DVEC4MaxRes(DVEC4 *v1, DVEC4 *v2, DVEC4 *vec4_maxRes);
/* return min value of x, y, z components in minXYZRes */
void DVEC4MinXYZ(DVEC4 *v, float *minXYZRes);
/* return max value of x, y, z components in maxXYZRes */
void DVEC4MaxXYZ(DVEC4 *v, float *maxXYZRes);
// Ray/plane functions ////////////////////////////////////////////////////
/* return true if [plane] intersect with ray ([raypos], [raydir]) */
bool IntersectRayPlane(DVEC4 *plane, DVEC4 *raypos, DVEC4 *raydir);
/* return true if [plane] intersect with ray ([raypos], [raydir]) and store interesction pos in intrscPos */
bool IntersectRayPlaneRes(DVEC4 *plane, DVEC4 *raypos, DVEC4 *raydir, DVEC4 *intrscPos);
/* project Ray ([rpos], [rdir]) vResProj = rdir * t + rpos */
DVEC4 *RayProjectDVEC4Res(float t, DVEC4 *rpos, DVEC4 *rdir, DVEC4 *vResProj);
// build plane equation from (v1, v2, v3) giving the equation (a*x)+(b*y)+(c*z)+d = 0 in vPlaneRes
// CrossNormalize(v3-v2, v2-v1, vPlaneNorm) then compute  d = - ((vPlaneNorm.x*v1.x) + (vPlaneNorm.y*v1.y) + (vPlaneNorm.z*v1.z))
DVEC4 *GetPlaneDVEC4(DVEC4 *v1, DVEC4 *v2, DVEC4 *v3, DVEC4 *vPlaneRes);
// culling / collision / clipping //////////////////////////////////////
bool DVEC4InAAMinBBox(DVEC4 *vec4Pos, DAAMinBBox *aaMinBbox);
#define DVEC4_IN_MASK_X 0x0001
#define DVEC4_IN_MASK_Y 0x0010
#define DVEC4_IN_MASK_Z 0x0100
#define DVEC4_IN_MASK_D 0x1000
bool DVEC4MaskInAAMinBBox(DVEC4 *vec4Pos, DAAMinBBox *aaMinBbox, int Mask); // 0x1111 => (d,z,y,x) ex: 0x110 => test in for (z,y)

int DVEC4ArrayIdxCountInAAMinBBox(DVEC4 *vec4Array, int *idxsVec4, int countIdxs, DAAMinBBox *aaMinBbox);
int DVEC4ArrayIdxCountInMapAAMinBBox(DVEC4 *vec4Array, int *idxsVec4, int countIdxs, DAAMinBBox *aaMinBbox, char *InMap);
// DMatrix4 4x4 3x3 ///////////////////////////////////////////////

DMatrix4 *CreateDMatrix4();
DMatrix4 *CreateDMatrix4Array(size_t count);
void DestroyDMatrix4(DMatrix4 *matrix4);

DMatrix4 *GetIdentityDMatrix4(DMatrix4 *mat4x4Dst);
DMatrix4 *GetLookAtDMatrix4(DMatrix4 *mat4x4Dst, DVEC4 *eye, DVEC4 *center, DVEC4 *up);
DMatrix4 *GetLookAtDMatrix4Val(DMatrix4 *mat4x4, float eye_x, float eye_y, float eye_z, float center_x, float center_y, float center_z, float up_x, float up_y, float up_z);
DMatrix4 *GetPerspectiveDMatrix4(DMatrix4 *mat4x4, float fov, float aspect, float znear, float zfar);
DMatrix4 *GetOrthoDMatrix4(DMatrix4 *mat4x4, float left, float right, float bottom, float top, float znear, float zfar);
DMatrix4 *GetViewDMatrix4(DMatrix4 *mat4x4, DgView *view, float startX, float endX, float startY, float endY);
DMatrix4 *GetRotDMatrix4(DMatrix4 *FMG, float Rx, float Ry, float Rz);
DMatrix4 *GetXRotDMatrix4(DMatrix4 *FMX, float Rx);
DMatrix4 *GetYRotDMatrix4(DMatrix4 *FMY, float Ry);
DMatrix4 *GetZRotDMatrix4(DMatrix4 *FMZ, float Rz);
DMatrix4 *GetTranslateDMatrix4(DMatrix4 *mat4x4Trans, DVEC4 *vecTrans);
DMatrix4 *GetTranslateDMatrix4Val(DMatrix4 *mat4x4Trans, float tx, float ty, float tz);
DMatrix4 *GetScaleDMatrix4(DMatrix4 *mat4x4Trans, DVEC4 *vecScale);
DMatrix4 *GetScaleDMatrix4Val(DMatrix4 *mat4x4Trans, float sx, float sy, float sz);

DMatrix4 *DMatrix4MulDMatrix4(DMatrix4 *mat4x4_left, DMatrix4 *mat4x4_right);
DMatrix4 *DMatrix4MulDMatrix4Res(DMatrix4 *mat4x4_left, DMatrix4 *mat4x4_right, DMatrix4 *mat4x4_res);

void DMatrix4MulDVEC4Array(DMatrix4 *mat4x4, DVEC4 *vec4Array, int count);
// apply rotation/scale/translation DMatrix4 to an array of DVEC4 and store result on another result DVEC4 array
// this mean that last column of DMatrix4 is ignored in transformation
// usually the DMatrix4 is computed using GetLookAtDMatrix4
void DMatrix4MulDVEC4ArrayRes(DMatrix4 *mat4x4, DVEC4 *vec4ArraySrc, int count, DVEC4 *vec4ArrayDst);
#define DMatrix4MulDVEC4ArrayResNT DMatrix4MulDVEC4ArrayRes
// apply projection matrix (perspective or orthogonal) to a VEC4 array
// usually transformation matrix is computed using GetPerspectiveDMatrix4 or GetOrthoDMatrix4
void DMatrix4MulDVEC4ArrayPersp(DMatrix4 *mat4x4, DVEC4 *vec4Array, int count);
#define DMatrix4MulDVEC4ArrayPerspNT DMatrix4MulDVEC4ArrayPersp
void DMatrix4MulDVEC4ArrayPerspRes(DMatrix4 *mat4x4, DVEC4 *vec4ArraySrc, int count, DVEC4 *vec4ArrayDst);
#define DMatrix4MulDVEC4ArrayPerspResNT DMatrix4MulDVEC4ArrayPerspRes
// apply projection to screen matrix to a DVEC4 array and store result on integer DVEC4i array
void DMatrix4MulDVEC4ArrayResDVec4i(DMatrix4 *mat4x4, DVEC4 *vec4ArraySrc, int count, DVEC4i *vec4ArrayDst);
#define DMatrix4MulDVEC4ArrayResDVec4iNT DMatrix4MulDVEC4ArrayResDVec4i
// apply projection to screen matrix to a DVEC4 array and store result on integer DVEC2i array
// usally transformation matrix is computed using GetViewDMatrix4
void DMatrix4MulDVEC4ArrayResDVec2i(DMatrix4 *mat4x4, DVEC4 *vec4ArraySrc, int count, DVEC2i *vec2iArrayDst);
#define DMatrix4MulDVEC4ArrayResDVec2iNT DMatrix4MulDVEC4ArrayResDVec2i


#ifdef __cplusplus
        }  // extern "C" {
#endif

#endif // DMATH3D_H_INCLUDED

