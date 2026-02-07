#ifndef DCONTAIN_H_INCLUDED
#define DCONTAIN_H_INCLUDED


#ifdef __cplusplus
extern "C" {
#endif

// DMemChunk

typedef struct DMemChunk {
    struct DMemChunk    *next; // pointer to next Mem Chunk
    char                *chunkPtr;
    unsigned int        chunkSize,
                         used,
                         countUsage;
} DMemChunk;

DMemChunk * CreateDMemChunk(unsigned int size);
void DestroyDMemChunk(DMemChunk * memChunk);
void * mallocDMemChunk(DMemChunk *memChunk, size_t size);
void * mallocAlignedDMemChunk(DMemChunk *memChunk, size_t size, unsigned int align);
void * mallocChainedDMemChunks(DMemChunk **memChunks, size_t size, unsigned int defaultDMemChunkSize);
void * mallocAlignedChainedDMemChunks(DMemChunk **memChunks, size_t size, unsigned int defaultDMemChunkSize, unsigned int align);
void DestroyChainedDMemChunks(DMemChunk * memChunks);

// DSTRDic

#define DHASHSIZE   13

typedef struct nodeValListDSTRDic {
    struct nodeValListDSTRDic   *next; /* next value node*/
    char            *key; /* defined key */
    void            *value; /* data pointer*/
} nodeValListDSTRDic;

typedef struct {
    nodeValListDSTRDic  **hashtab; /* pointer table */
    nodeValListDSTRDic  *currentNodeVal;
    DMemChunk           *chunks; // chained list of mem chunks, first is the last current
    unsigned int        defaultDMemChunkSize,
                        hashbits,
                        hashsize,
                        hashmask,
                        firstHashtabIdx,
                        lastHashtabIdx,
                        currentHashtabIdx,
                        currentCountKeys,
                        countKeys;
} DSTRDic;

DSTRDic *CreateDSTRDic(unsigned int memChunkSize, unsigned int hashTabSize); // memChunkSize = 0 => use default size, hashTabSize = 0 default size
void DestroyDSTRDic(DSTRDic *strDIC);
bool ResetDSTRDic(DSTRDic *ptr); // reset or delete all contents
bool InsertDSTRDic(DSTRDic *ptr, char *key, void *value, bool update);
bool InsertDumpValDSTRDic(DSTRDic *ptr, char *key, void *value, size_t sizeVal, bool update);
bool InsertAlignDumpValDSTRDic(DSTRDic *ptr, char *key, void *value, size_t sizeVal, bool update, unsigned int align);
void *keyValueDSTRDic(DSTRDic *ptr, char *key);
bool GetFirstValueDSTRDic(DSTRDic *ptr, char **key, void **value);
bool GetNextValueDSTRDic(DSTRDic *ptr, char **key, void **value);
void * mallocDSTRDic(DSTRDic *strDIC, size_t size);
void * mallocAlignedDSTRDic(DSTRDic *ptr, size_t size, unsigned int align);
char *strdupDSTRDic(DSTRDic *ptr, char *s);

unsigned int DHashStr(char *str);

// DSplitString

#define DEFAULT_DSPLITSTRING_CHARSCOUNT     256
#define DEFAULT_DSPLITSTRING_GLOBSTRINGSIZE 1024*16

typedef struct {
    char            *globStr;         // global buffer of source string to split
    bool            *multiDelim;      // 256 boolean array of chars used as separator
    unsigned int     globLen,         // current length
                     maxGlobLength,   // max global length
                     maxCountStrings,
                     countStrings;    // result count of splitted strings
    char           **ListStrings;     // result of splitted strings
} DSplitString;


DSplitString * CreateDSplitString(unsigned int maxStrSplitsCount, unsigned int maxStringLength);
DSplitString * CreateStrDSplitString(unsigned int maxStrSplitsCount, const char *str);
int splitDSplitString(DSplitString *splitString, const char *str, char delim, bool addEmpty);
void SetMultiDelimDSplitString(DSplitString *splitString, char *mDelim);
int splitMultiDelimDSplitString(DSplitString *splitString, const char *str, bool addEmpty);
void TrimStringsDSplitString(DSplitString *splitString); // remove (spaces,tabs) from start and (spaces,tabs,'\n','\r') from the end of each splitted string
void TrimGlobStringDSplitString(DSplitString *splitString);
void DestroyDSplitString(DSplitString *splitString);

// DFileBuffer

typedef struct {
    FILE            *m_file;
    char            *m_buffRead;
    unsigned int     m_bytesInBuff;
    unsigned int     m_sizeBuff;
    bool             m_EOF;
} DFileBufferReadJob;

typedef struct  {
    char              *m_buffRead;
    char              *m_buffReadWorker;
    int64_t            m_curPos;
    unsigned int       m_bytesInBuff,
                       m_sizeBuff,
                       m_readWorkerID;
    FILE              *m_file;
    void              *m_data;
    DFileBufferReadJob m_ReadJob;
    bool               m_EOF;
} DFileBuffer;

DFileBuffer* CreateDFileBuffer(unsigned int sizeBuff);
DFileBuffer* CreateMemDFileBuffer(void *buff, unsigned int sizeBuff);
DFileBuffer* CreateMemDFileBufferFromFile(const char *filename, const char *openmode);
void DestroyDFileBuffer(DFileBuffer *ptr);
bool OpenFileDFileBuffer(DFileBuffer *ptr, const char *filename, const char *openmode);
void CloseFileDFileBuffer(DFileBuffer *ptr);
bool FseekDFileBuffer(DFileBuffer *ptr, int64_t offset, int origin);
bool RewindDFileBuffer(DFileBuffer *fbuff);
unsigned int GetBytesDFileBuffer(DFileBuffer *fbuff, void *buff, unsigned int bytesToGet);
unsigned int GetLineDFileBuffer(DFileBuffer *ptr, char *line, unsigned int maxLineSize);
bool IsEndOfFileDFileBuffer(DFileBuffer *ptr);

#ifdef __cplusplus
        }  // extern "C" {
#endif

#endif // DCONTAIN_H_INCLUDED

