#ifndef DIMAGE_H

#define DIMAGE_H

#ifdef __cplusplus
extern "C" {
#endif

int LoadJPG16(DgSurf **S,char *filename);
int LoadMemJPG16(DgSurf **S,void *buffJpeg,int sizeBuff);
int SaveJPG16(DgSurf *S,char *filename,int quality);

int LoadPNG16(DgSurf **S,char *filename);
int LoadMemPNG16(DgSurf **S, void *In, int SizeIn);
int LoadPNG(DgSurf **S,char *filename, void *PalBGR1024);
int SavePNG16(DgSurf *S,char *filename);

#ifdef __cplusplus
           }
#endif


#endif /*DIMAGE_H*/
