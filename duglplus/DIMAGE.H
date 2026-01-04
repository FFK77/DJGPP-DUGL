#ifndef DIMAGE_H

#define DIMAGE_H

#ifdef __cplusplus
extern "C" {
#endif

int LoadJPG16(Surf **S,char *filename);
int LoadMemJPG16(Surf **S,void *buffJpeg,int sizeBuff);
int SaveJPG16(Surf *S,char *filename,int quality);

int LoadPNG16(Surf **S,char *filename);
int LoadPNG(Surf **S,char *filename, void *PalBGR1024);
int SavePNG16(Surf *S,char *filename);

#ifdef __cplusplus
           }
#endif


#endif /*DIMAGE_H*/
