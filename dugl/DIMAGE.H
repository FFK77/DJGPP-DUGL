#ifndef DIMAGE_H

#define DIMAGE_H

#ifdef __cplusplus
extern "C" {
#endif

// PCX
int  LoadMemPCX(DgSurf **S,void *In,void *PalBGR1024,int SizeIn);
int  LoadPCX(DgSurf **S,const char *Fname,void *PalBGR1024);
int  SaveMemPCX(DgSurf *S,void *Out,void *PalBGR1024);
int  SavePCX(DgSurf *S,const char *Fname,void *PalBGR1024);
int  SizeSavePCX(DgSurf *S);
void InRLE(void *InBuffRLE,void *Out,int LenOut);
void OutRLE(void *OutBuffRLE,void *In,int LenIn,int ResHz);
int  SizeOutRLE(void *In,int LenIn,int ResHz);

// GIF
int  LoadMemGIF(DgSurf **S,void *In,void *PalBGR1024,int SizeIn);
int  LoadGIF(DgSurf **S,const char *Fname,void *PalBGR1024);
int  LoadGIF16(DgSurf **S16,char *filename); // load a 8bpp gif and convert it to 16 bpp
int  SaveMemGIF(DgSurf *S,void *Out,void *PalBGR1024); // NI (not implemented)
void InLZW(void *InBuffLZW,void *Out);

// BMP
int  LoadMemBMP(DgSurf **S,void *In,void *PalBGR1024,int SizeIn); // load a 8bpp uncompressed BMP into a 8bpp Surf
int  LoadBMP(DgSurf **S,const char *Fname,void *PalBGR1024);
int  SaveMemBMP(DgSurf *S,void *Out,void *PalBGR1024);
int  SaveBMP(DgSurf *S,const char *Fname,void *PalBGR1024); // save a 8bpp Surf into a 8bpp uncompressed BMP
int  SizeSaveBMP(DgSurf *S); // total size in bytes of a 8bpp bmp saved Surf
int  LoadMemBMP16(DgSurf **S,void *In,int SizeIn); // load a 24bpp uncompressed BMP into a 16bpp Surf
int  LoadBMP16(DgSurf **S,const char *Fname);
int  SaveMemBMP16(DgSurf *S,void *Out); // save  a 16bpp surf into a 24bpp uncompressed BMP
int  SaveBMP16(DgSurf *S,const char *Fname);
int  SizeSaveBMP16(DgSurf *S);

// JPG
int LoadJPG16(DgSurf **S,char *filename);
int LoadMemJPG16(DgSurf **S,void *buffJpeg,int sizeBuff);
int SaveJPG16(DgSurf *S,char *filename,int quality);

// PNG
int LoadPNG16(DgSurf **S,char *filename);
int LoadMemPNG16(DgSurf **S, void *In, int SizeIn);
int LoadPNG(DgSurf **S,char *filename, void *PalBGR1024);
int SavePNG16(DgSurf *S,char *filename);

// WEBP
int LoadWEBP16(DgSurf **S,char *filename);
int LoadMemWEBP16(DgSurf **S,void *buffJpeg,int sizeBuff);

#ifdef __cplusplus
           }
#endif


#endif /*DIMAGE_H*/
