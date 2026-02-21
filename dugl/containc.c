#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#include "DUGL.h"
#include "intrdugl.h"

// DMemChunk

#define DEFAULT_MEMCHUNK_SIZE   1024*32


DMemChunk * CreateDMemChunk(unsigned int size) {
    char *buffChunk = (char*) malloc(sizeof(DMemChunk)+(size_t)(size));
    DMemChunk *memChunk = NULL;
    if (buffChunk != NULL) {
        memChunk = (DMemChunk *)buffChunk;
        memChunk->chunkPtr = &buffChunk[sizeof(DMemChunk)];
        memChunk->chunkSize = size;
        memChunk->used = 0;
        memChunk->countUsage = 0;
        memChunk->next = NULL;
    }
    return memChunk;
}

void DestroyDMemChunk(DMemChunk * memChunk) {
    memset(memChunk, 0, sizeof(DMemChunk));
    /*memChunk->chunkPtr = NULL;
    memChunk->chunkSize = 0;
    memChunk->used = 0;
    memChunk->countUsage = 0;
    memChunk->next = NULL;*/
    free(memChunk);
}

void * mallocDMemChunk(DMemChunk *memChunk, size_t size) {
    char *memAllocated = NULL;
    if ((memChunk->chunkSize - memChunk->used) >= size) {
        memAllocated = &memChunk->chunkPtr[memChunk->used];
        memChunk->used += (unsigned int)size;
        memChunk->countUsage ++;
    }
    return memAllocated;
}

void * mallocAlignedDMemChunk(DMemChunk *memChunk, size_t size, unsigned int align) {
    char *memAllocated = NULL;
    unsigned int currAlign = ((unsigned int)(memChunk->chunkPtr) + memChunk->used) % align;
    unsigned int alignRequiredBytes = (currAlign != 0) ? (align - currAlign) : 0;
    if ((memChunk->chunkSize - memChunk->used - alignRequiredBytes) >= size) {
        memAllocated = &memChunk->chunkPtr[memChunk->used+alignRequiredBytes];
        memChunk->used += (unsigned int)size + alignRequiredBytes;
        memChunk->countUsage ++;
    }
    return memAllocated;
}

void * mallocChainedDMemChunks(DMemChunk **memChunks, size_t size, unsigned int defaultDMemChunkSize) {
    DMemChunk *memChunk = NULL;
    char *buff = NULL;
    // special case: alloc a chunk with the required BIG size
    if (size > defaultDMemChunkSize) {
        memChunk = CreateDMemChunk(size);
        if (memChunk != NULL) {
            // insert after the current chunk
            memChunk->next = (*memChunks)->next;
            (*memChunks)->next = memChunk;
            buff = mallocDMemChunk(memChunk, size);
        }
    } else {
        buff = mallocDMemChunk((*memChunks), size);
        // free space isn't enough in current chunk, create and insert new one
        if (buff == NULL) {
            memChunk = CreateDMemChunk(defaultDMemChunkSize);
            if (memChunk != NULL) {
                // new chunk become the last current one
                memChunk->next = (*memChunks);
                (*memChunks) = memChunk;
                buff = mallocDMemChunk(memChunk, size);
            }
        }
    }

    return buff;
}

void * mallocAlignedChainedDMemChunks(DMemChunk **memChunks, size_t size, unsigned int defaultDMemChunkSize, unsigned int align) {
    DMemChunk *memChunk = NULL;
    char *buff = NULL;
    // special case: alloc a chunk with the required BIG size
    if ((size + (align - 1)) > defaultDMemChunkSize) {
        memChunk = CreateDMemChunk(size+ (align - 1));
        if (memChunk != NULL) {
            // insert after the current chunk
            memChunk->next = (*memChunks)->next;
            (*memChunks)->next = memChunk;
            buff = mallocAlignedDMemChunk(memChunk, size, align);
        }
    } else {
        buff = mallocAlignedDMemChunk((*memChunks), size, align);
        // free space isn't enough in current chunk, create and insert new one
        if (buff == NULL) {
            memChunk = CreateDMemChunk(defaultDMemChunkSize);
            if (memChunk != NULL) {
                // new chunk become the last current one
                memChunk->next = (*memChunks);
                (*memChunks) = memChunk;
                buff = mallocAlignedDMemChunk(memChunk, size, align);
            }
        }
    }

    return buff;
}

void DestroyChainedDMemChunks(DMemChunk * memChunks) {
    DMemChunk *memChunk = NULL,
               *tmpChunk = NULL;

    for (memChunk = memChunks; memChunk != NULL;) {
        tmpChunk = memChunk->next;
        DestroyDMemChunk(memChunk);
        memChunk = tmpChunk;
    }
}

// DSTRDic

void InitDSTRDic(DSTRDic *ptr) {
    memset(ptr->hashtab, 0, sizeof(nodeValListDSTRDic*)*ptr->hashsize);
}

DSTRDic *CreateDSTRDic(unsigned int memChunkSize, unsigned int hashTabSize) {
    DSTRDic *ptr = NULL;
    DMemChunk *firstMemChunk = NULL;
    unsigned int chunkSize = (memChunkSize>0) ? memChunkSize : DEFAULT_MEMCHUNK_SIZE;
    // hash tab size between 256 and 16 milions main hash entry
    unsigned int hashbits = (hashTabSize >= 8 && hashTabSize <= 24) ? (hashTabSize) : (DHASHSIZE);
    unsigned int hashSize = (1 << hashbits);
    unsigned int hashMask = hashSize - 1;

    firstMemChunk = CreateDMemChunk(chunkSize + sizeof(DSTRDic) + (sizeof(nodeValListDSTRDic*)*hashSize));
    if (firstMemChunk != NULL) {
        ptr = mallocDMemChunk(firstMemChunk, sizeof(DSTRDic));
        if (ptr!=NULL) {
            ptr->hashtab = (nodeValListDSTRDic **)mallocDMemChunk(firstMemChunk, (sizeof(nodeValListDSTRDic*)*hashSize));
            ptr->hashbits = hashbits;
            ptr->hashsize = hashSize;
            ptr->hashmask = hashMask;
            ptr->countKeys = 0;
            InitDSTRDic(ptr);
            ptr->chunks = firstMemChunk;
            ptr->defaultDMemChunkSize = chunkSize;
        }
    }
    return ptr;
}

bool ResetDSTRDic(DSTRDic *ptr) {
    DMemChunk *memChunk = NULL,
               *tmpChunk = NULL,
                *mainChunk = (DMemChunk *)((char*)(ptr)-sizeof(DMemChunk));
    unsigned int hashsizeBytes = sizeof(nodeValListDSTRDic*)*ptr->hashsize;

    // destroy all memChunks except the first Main where DSTRDic it self is located
    for (memChunk = ptr->chunks; memChunk != NULL;) {
        tmpChunk = memChunk->next;
        if (memChunk != mainChunk)
            DestroyDMemChunk(memChunk);
        memChunk = tmpChunk;
    }
    // succefully found mainChunk ?
    if (mainChunk != NULL) {
        ptr->chunks = mainChunk;
        ptr->countKeys = 0;
        mainChunk->countUsage = 2;
        mainChunk->used = sizeof(DSTRDic)+hashsizeBytes;
        memset(ptr->hashtab, 0, hashsizeBytes);
        return true;
    }
    return false;
}

void DestroyDSTRDic(DSTRDic *ptr) {
    DestroyChainedDMemChunks(ptr->chunks);
}

void * mallocDSTRDic(DSTRDic *ptr, size_t size) {
    return mallocChainedDMemChunks(&ptr->chunks, size, ptr->defaultDMemChunkSize);
}

void * mallocAlignedDSTRDic(DSTRDic *ptr, size_t size, unsigned int align) {
    return mallocAlignedChainedDMemChunks(&ptr->chunks, size, ptr->defaultDMemChunkSize, align);
}

unsigned int DHashStr(char *s) {
    unsigned int hashval = 0;
    for (; *s != 0; s++)
        hashval = 31 * hashval + *s;
    return hashval;
}

/* lookup: look for key in hashtab */
nodeValListDSTRDic *lookupNodeValDSTRDic(DSTRDic *ptr, unsigned int hashval, char *key) {
    nodeValListDSTRDic *np;
    for (np = ptr->hashtab[hashval]; np != NULL; np = np->next)
        if (strcmp(key, np->key) == 0)
            return np; /* found */
    return NULL; /* not found */
}

void *keyValueDSTRDic(DSTRDic *ptr, char *key) {
    nodeValListDSTRDic *np;
    for (np = ptr->hashtab[DHashStr(key)&(ptr->hashmask)]; np != NULL; np = np->next)
        if (strcmp(key, np->key) == 0)
            return np->value; /* found */
    return NULL; /* not found */
}

bool GetFirstValueDSTRDic(DSTRDic *ptr, char **key, void **value) {
    if (ptr->countKeys == 0)
        return false;
    ptr->currentHashtabIdx = ptr->firstHashtabIdx;
    ptr->currentNodeVal = ptr->hashtab[ptr->currentHashtabIdx];
    *key = ptr->currentNodeVal->key;
    *value = ptr->currentNodeVal->value;
    ptr->currentCountKeys = 1;
    return true;
}

bool GetNextValueDSTRDic(DSTRDic *ptr, char **key, void **value) {
    int idxHash = 0;
    if (ptr->countKeys == 0 || ptr->currentCountKeys >= ptr->countKeys)
        return false;
    // search for next hash NodeVal idx
    if (ptr->currentNodeVal->next == NULL) {
        for (idxHash = ptr->currentHashtabIdx+1; idxHash <= ptr->lastHashtabIdx; idxHash++) {
            if (ptr->hashtab[idxHash] != NULL) {
                ptr->currentNodeVal = ptr->hashtab[idxHash];
                ptr->currentHashtabIdx = idxHash;
                break;
            }
        }
        if (idxHash > ptr->lastHashtabIdx || ptr->hashtab[idxHash] == NULL) {
            return false;
        }
    } else {
        ptr->currentNodeVal = ptr->currentNodeVal->next;
    }

    *key = ptr->currentNodeVal->key;
    *value = ptr->currentNodeVal->value;
    ptr->currentCountKeys++;
    return true;
}

// duplicate *s
char *strdupDSTRDic(DSTRDic *ptr, char *s) {
    unsigned int slen = strlen(s); /* +1 for ’\0’ */
    char *p;
    p = (char *) mallocDSTRDic(ptr, (size_t)(slen+1));
    if (p != NULL) {
        memcpy(p, s, slen);
        p[slen] = '\0';
    }
    return p;
}

// insert new (key value) or update
bool InsertDSTRDic(DSTRDic *ptr, char *key, void *value, bool update) {
    nodeValListDSTRDic *np = NULL;
    unsigned int hashval = DHashStr(key)&(ptr->hashmask);
    if ((np = lookupNodeValDSTRDic(ptr, hashval, key)) == NULL) { /* not found */
        np = (nodeValListDSTRDic *) mallocDSTRDic(ptr, sizeof(nodeValListDSTRDic));
        if (np == NULL || (np->key = strdupDSTRDic(ptr, key)) == NULL)
            return NULL;
        np->next = ptr->hashtab[hashval];
        np->value = value;
        ptr->hashtab[hashval] = np;
        if (ptr->countKeys == 0) {
            ptr->countKeys = 1;
            ptr->firstHashtabIdx = hashval;
            ptr->lastHashtabIdx = hashval;
        } else {
            if (hashval < ptr->firstHashtabIdx)
                ptr->firstHashtabIdx = hashval;
            if (hashval > ptr->lastHashtabIdx)
                ptr->lastHashtabIdx = hashval;
            ptr->countKeys++;
        }
        return true;
    } else if (update) {
        np->value = value;
        return true;
    }
    return false;
}

bool InsertDumpValDSTRDic(DSTRDic *ptr, char *key, void *value, size_t sizeVal, bool update) {
    void *dumpVal = mallocDSTRDic(ptr, sizeVal);
    if (dumpVal != NULL) {
        memcpy(dumpVal, value, sizeVal);
        return InsertDSTRDic(ptr, key, dumpVal, update);
    }
    return false;
}

bool InsertAlignDumpValDSTRDic(DSTRDic *ptr, char *key, void *value, size_t sizeVal, bool update, unsigned int align) {
    void *dumpVal = mallocAlignedDSTRDic(ptr, sizeVal, align);
    if (dumpVal != NULL) {
        memcpy(dumpVal, value, sizeVal);
        return InsertDSTRDic(ptr, key, dumpVal, update);
    }
    return false;
}

// DSplitString

DSplitString * CreateDSplitString(unsigned int maxStrSplitsCount, unsigned int maxStringLength) {
    DSplitString *splitString = NULL;
    unsigned int maxSplits = (maxStrSplitsCount > 0) ? maxStrSplitsCount : DEFAULT_DSPLITSTRING_CHARSCOUNT;
    unsigned int maxString = (maxStringLength > 0) ? maxStringLength : DEFAULT_DSPLITSTRING_GLOBSTRINGSIZE;
    char *allBuff = (char*)malloc(sizeof(DSplitString) + (sizeof(bool)*256) + maxString + (sizeof(char*)*maxSplits));
    if (allBuff != NULL) {
        splitString = (DSplitString *)allBuff;
        splitString->globStr = &allBuff[sizeof(DSplitString)];
        splitString->globStr[0]='\0';
        splitString->multiDelim = (bool*)&allBuff[sizeof(DSplitString)+maxString];
        splitString->ListStrings = (char **)&allBuff[sizeof(DSplitString)+maxString+(sizeof(bool)*256)];
        splitString->globLen = 0;
        splitString->maxGlobLength = maxString - 1;
        splitString->maxCountStrings = maxSplits;
        splitString->countStrings = 0;
    }
    return splitString;
}

DSplitString * CreateStrDSplitString(unsigned int maxStrSplitsCount, const char *str) {
    DSplitString *splitString = NULL;
    unsigned int maxSplits = (maxStrSplitsCount > 0) ? maxStrSplitsCount : DEFAULT_DSPLITSTRING_CHARSCOUNT;
    unsigned int lenStr = strlen(str);
    unsigned int maxStringLength = (str != NULL) ? ((lenStr+1+4)&0xfffffffc) : DEFAULT_DSPLITSTRING_GLOBSTRINGSIZE; // round 4 (strlen+1) to keep alignement
    char *allBuff = (char*)malloc(sizeof(DSplitString) + (sizeof(bool)*256) + maxStringLength + (sizeof(char*)*maxSplits));
    if (allBuff != NULL) {
        splitString = (DSplitString *)allBuff;
        splitString->globStr = &allBuff[sizeof(DSplitString)];
        if (str != NULL) {
            memcpy(splitString->globStr, str, lenStr);
            splitString->globStr[lenStr] = '\0';
            splitString->globLen = lenStr;
        } else {
            splitString->globStr[0]='\0';
            splitString->globLen = 0;
        }
        splitString->multiDelim = (bool*)&allBuff[sizeof(DSplitString)+maxStringLength];
        splitString->ListStrings = (char **)&allBuff[sizeof(DSplitString)+maxStringLength+(sizeof(bool)*256)];
        splitString->maxGlobLength = maxStringLength - 1;
        splitString->maxCountStrings = maxSplits;
        splitString->countStrings = 0;
    }
    return splitString;
}

int splitDSplitString(DSplitString *splitString, const char *str, char delim, bool addEmpty) {
    int idx =0;
    // if str NULL use current globStr
    if (str != NULL) {
        splitString->globLen = strlen(str);
        if (splitString->globLen > splitString->maxGlobLength)
            splitString->globLen = splitString->maxGlobLength;
        memcpy(splitString->globStr, str, splitString->globLen);
        splitString->globStr[splitString->globLen] = '\0';
    }
    splitString->countStrings = 0;
    unsigned int startIdx = 0;
    unsigned int countNotDelim = 0;
    for (idx =0; idx < splitString->globLen; idx++) {
        if (splitString->globStr[idx] == delim) {
            if ((addEmpty || (idx > startIdx && countNotDelim > 0)) && splitString->countStrings < splitString->maxCountStrings) {
                splitString->globStr[idx] = '\0';
                splitString->ListStrings[splitString->countStrings] = &splitString->globStr[startIdx];
                splitString->countStrings++;
            }
            startIdx = idx+1;
            countNotDelim = 0;
        } else {
            countNotDelim ++;
        }
    }
    if ((addEmpty || (startIdx <= splitString->globLen && countNotDelim > 0)) && splitString->countStrings < splitString->maxCountStrings) {
        splitString->ListStrings[splitString->countStrings] = &splitString->globStr[startIdx];
        splitString->countStrings++;
    }

    return splitString->countStrings;
}

void SetMultiDelimDSplitString(DSplitString *splitString, char *mDelim) {
    unsigned char *s = (unsigned char*)mDelim;
    // set all possible char to false
    memset(splitString->multiDelim, 0, (sizeof(char)*256));
    // enable splitting for each char on the *mDelim string
    for (; *s != 0; s++)
        splitString->multiDelim[(unsigned char)(*s)] = true;
}

int splitMultiDelimDSplitString(DSplitString *splitString, const char *str, bool addEmpty) {
    int idx =0;
    // if str NULL use current globStr
    if (str != NULL) {
        splitString->globLen = strlen(str);
        if (splitString->globLen > splitString->maxGlobLength)
            splitString->globLen = splitString->maxGlobLength;
        memcpy(splitString->globStr, str, splitString->globLen);
        splitString->globStr[splitString->globLen] = '\0';
    }
    splitString->countStrings = 0;
    unsigned int startIdx = 0;
    unsigned int countNotDelim = 0;
    for (idx =0; idx < splitString->globLen; idx++) {
        if (splitString->multiDelim[(unsigned char)(splitString->globStr[idx])]) {
            if ((addEmpty || (idx > startIdx && countNotDelim > 0)) && splitString->countStrings < splitString->maxCountStrings) {
                splitString->globStr[idx] = '\0';
                splitString->ListStrings[splitString->countStrings] = &splitString->globStr[startIdx];
                splitString->countStrings++;
            }
            startIdx = idx+1;
            countNotDelim = 0;
        } else {
            countNotDelim ++;
        }
    }
    if ((addEmpty || (startIdx <= splitString->globLen && countNotDelim > 0)) && splitString->countStrings < splitString->maxCountStrings) {
        splitString->ListStrings[splitString->countStrings] = &splitString->globStr[startIdx];
        splitString->countStrings++;
    }

    return splitString->countStrings;
}

void TrimGlobStringDSplitString(DSplitString *splitString) {
    unsigned int sdx = 0;
    char c;
    splitString->globLen = strlen(splitString->globStr);
    if (splitString->globLen == 0)
        return;
    // remove from space,tabs,\n and \r the end
    for (sdx = splitString->globLen-1; sdx >0 ; sdx--) {
        if ((c = splitString->globStr[sdx]) == ' ' || c == '\t' || c == '\n' || c == '\r') {
            splitString->globStr[sdx] = '\0';
            splitString->globLen--;
            if (splitString->globLen == 0)
                return;
        } else
            break;
    }
    // remove from space,tabs from start
    for (sdx = 0; sdx < splitString->globLen; sdx++) {
        if ((c = splitString->globStr[sdx]) != ' ' && c != '\t')
            break;
    }
    if (sdx > 0) {
        // empty ?
        if (sdx == splitString->globLen - 1) {
            splitString->globStr[0] = '\0';
            splitString->globLen = 0;
        } else {
            splitString->globLen -= sdx;
            memcpy(splitString->globStr, &splitString->globStr[sdx], splitString->globLen);
        }
    }
}

void TrimStringsDSplitString(DSplitString *splitString) {
    unsigned int idx = 0;
    unsigned int sdx = 0;
    unsigned int lenCurString = 0;
    char c;
    for (idx =0; idx < splitString->countStrings; idx++) {
        lenCurString = strlen(splitString->ListStrings[idx]);
        if (lenCurString == 0)
            continue;
        // remove from space,tabs,\n and \r the end
        for (sdx = lenCurString-1; sdx >0 ; sdx--) {
            if ((c = splitString->ListStrings[idx][sdx]) == ' ' || c == '\t' || c == '\n' || c == '\r')
                splitString->ListStrings[idx][sdx] = '\0';
            else
                break;
        }
        // remove from space,tabs from start by incrementing string pointer
        for (; *splitString->ListStrings[idx] != '\0'; splitString->ListStrings[idx]++) {
            if ((c = *splitString->ListStrings[idx]) == ' ' || c == '\t')
                continue;
            else
                break;
        }
    }
}

void DestroyDSplitString(DSplitString *splitString) {
    free(splitString);
}

// DFileBuffer

#define MAX_MEM_DFILEBUFFER_SIZE ((1<<31)-1)
#define DEFAULT_DFILEBUFFER_BUFFER_SIZE 64*1024
#define DROUND16(x) ((x+16)&0xFFFFFFF0)
#define SIZE_DFB16 DROUND16(sizeof(DFileBuffer))

void readWorkerFunctionDFBuff(void *job/*(FileBufferReadJob*)*/, int idx) {
    if (job == NULL)
        return;
    SetDWorkerPriority(0);
    DFileBufferReadJob *myjob = (DFileBufferReadJob*)(job);
    if (myjob->m_sizeBuff == 0 || myjob->m_file == NULL)
        return;
    myjob->m_bytesInBuff = (unsigned int)fread(myjob->m_buffRead, 1, myjob->m_sizeBuff, myjob->m_file);
    // error read ?
    if (myjob->m_bytesInBuff > myjob->m_sizeBuff)
        myjob->m_bytesInBuff = 0;
    // end of file ?
    if (myjob->m_bytesInBuff < myjob->m_sizeBuff) {
        myjob->m_EOF = true;
    }
}

DFileBuffer* CreateDFileBuffer(unsigned int sizeBuff) {
    unsigned int sizebf = (sizeBuff > 0) ? DROUND16(sizeBuff) : DEFAULT_DFILEBUFFER_BUFFER_SIZE;
    DFileBuffer* fileBuff = (DFileBuffer*)malloc(SIZE_DFB16+(2*sizebf));
    if (fileBuff != NULL) {
        memset(fileBuff, 0, SIZE_DFB16);
        fileBuff->m_buffRead = &((char*)fileBuff)[SIZE_DFB16];
        fileBuff->m_buffReadWorker = &((char*)fileBuff)[SIZE_DFB16+sizebf];
        fileBuff->m_sizeBuff = (sizeBuff > 0) ? sizeBuff : DEFAULT_DFILEBUFFER_BUFFER_SIZE;
        fileBuff->m_bytesInBuff = 0;
        fileBuff->m_curPos = 0;
        fileBuff->m_file = NULL;
        fileBuff->m_data = NULL;
        fileBuff->m_EOF = false;
        fileBuff->m_readWorkerID = CreateDWorker(readWorkerFunctionDFBuff, &fileBuff->m_ReadJob);
    }

    return fileBuff;
}

DFileBuffer* CreateMemDFileBuffer(void *buff, unsigned int sizeBuff) {
    if (buff == NULL || sizeBuff < 1)
        return NULL;
    DFileBuffer* fileBuff = (DFileBuffer*)malloc(SIZE_DFB16);
    if (fileBuff != NULL) {
        memset(fileBuff, 0, SIZE_DFB16);
        fileBuff->m_buffRead = (char*)(buff);
        fileBuff->m_buffReadWorker = NULL;
        fileBuff->m_sizeBuff = sizeBuff;
        fileBuff->m_bytesInBuff = sizeBuff;
        fileBuff->m_curPos = 0;
        fileBuff->m_file = NULL;
        fileBuff->m_data = buff;
        fileBuff->m_EOF = true;
        fileBuff->m_readWorkerID = 0;
    }

    return fileBuff;
}

DFileBuffer* CreateMemDFileBufferFromFile(const char *filename, const char *openmode) {
    DFileBuffer *pfileBuff = NULL;
    FILE *dmemFILE = fopen(filename, openmode);
    unsigned int dmemFileSize = 0;
    if (dmemFILE != NULL) {
        if (fseek(dmemFILE, 0, SEEK_END) == 0) {
            dmemFileSize = (unsigned int)ftell(dmemFILE);
            if (dmemFileSize > 0 && dmemFileSize <= MAX_MEM_DFILEBUFFER_SIZE) {
                if (fseek(dmemFILE, 0, SEEK_SET) == 0) {
                    char *buff = (char*)malloc(dmemFileSize);
                    if (buff != NULL) {
                        if ((pfileBuff = CreateMemDFileBuffer(buff, (unsigned int)(dmemFileSize))) == NULL)
                            free(buff);
                        else
                            fread(buff, 1, (size_t)dmemFileSize, dmemFILE); \
                    }
                }
            }
        }
        fclose(dmemFILE);
    }
    return pfileBuff;
}

void DestroyDFileBuffer(DFileBuffer *pFileBuff) {
    if (pFileBuff->m_readWorkerID != 0) {
        DestroyDWorker(pFileBuff->m_readWorkerID);
        pFileBuff->m_readWorkerID = 0;
    }
    CloseFileDFileBuffer(pFileBuff);
    memset(pFileBuff, 0, SIZE_DFB16);
    free(pFileBuff);
}

void CloseFileDFileBuffer(DFileBuffer *pFileBuff) {
    if (pFileBuff->m_file != NULL) {
        fclose(pFileBuff->m_file);
        pFileBuff->m_file = NULL;
    }
    pFileBuff->m_bytesInBuff = 0;
    pFileBuff->m_curPos = 0;
}

void ReadChunkDFileBuffer(DFileBuffer *pFileBuff) {
    char *tmpBuff = NULL;
    // EndOfFile or memory DFileBuffer
    if (pFileBuff->m_EOF || pFileBuff->m_file == NULL) {
        return;
    }
    WaitDWorker(pFileBuff->m_readWorkerID);
    // swap buffer pointer
    tmpBuff = pFileBuff->m_buffRead;
    pFileBuff->m_buffRead = pFileBuff->m_ReadJob.m_buffRead;
    pFileBuff->m_buffReadWorker = tmpBuff;

    pFileBuff->m_bytesInBuff = pFileBuff->m_ReadJob.m_bytesInBuff;
    pFileBuff->m_EOF = pFileBuff->m_ReadJob.m_EOF;
    pFileBuff->m_curPos = 0;

    // read next buff
    if (!pFileBuff->m_EOF) {
        pFileBuff->m_ReadJob.m_buffRead = pFileBuff->m_buffReadWorker;
        RunDWorker(pFileBuff->m_readWorkerID, false);
    }
}

void InitFirstReadDFileBuffer(DFileBuffer *fbuff) {
    if (fbuff->m_file == NULL)
        return;
    fbuff->m_ReadJob.m_buffRead = fbuff->m_buffReadWorker;
    fbuff->m_ReadJob.m_file = fbuff->m_file;
    fbuff->m_ReadJob.m_sizeBuff = fbuff->m_sizeBuff;
    fbuff->m_ReadJob.m_EOF = false;
    fbuff->m_EOF = false;
    RunDWorker(fbuff->m_readWorkerID, false);
    ReadChunkDFileBuffer(fbuff);
}

bool OpenFileDFileBuffer(DFileBuffer *fbuff, const char *filename, const char *openmode) {
    // fail if memory DFileBuffer or already open or failed to allocated read DWorker
    if (fbuff->m_data != NULL || fbuff->m_file != NULL || fbuff->m_readWorkerID == 0) {
        return false;
    }
    if ((fbuff->m_file = fopen(filename, openmode)) == NULL) {
        return false;
    }
    InitFirstReadDFileBuffer(fbuff);
    return true;
}

bool FseekDFileBuffer(DFileBuffer *fbuff, int64_t offset, int origin) {
    // handle memory DFileBuffer
    if (fbuff->m_file == NULL) {
        if (fbuff->m_data != NULL) {
            // nothing todo ?
            if (offset == 0)
                return true;
            // handle mem seek ========================
            switch (origin) {
            case SEEK_SET:
                if (offset < (int64_t)fbuff->m_sizeBuff && offset >= 0) {
                    fbuff->m_curPos = offset;
                    fbuff->m_bytesInBuff = fbuff->m_sizeBuff - (unsigned int)fbuff->m_curPos;
                    return true;
                } else
                    return false;
                break;
            case SEEK_END:
                if (offset < (off64_t)fbuff->m_sizeBuff && offset >= 0) {
                    fbuff->m_curPos = fbuff->m_sizeBuff - 1 - (unsigned int)offset;
                    fbuff->m_bytesInBuff = fbuff->m_sizeBuff - fbuff->m_curPos;
                    return true;
                } else
                    return false;
                break;
            case SEEK_CUR:
                if (offset < 0) {
                    if (fbuff->m_curPos >= (-offset)){
                        fbuff->m_curPos -= (-offset);
                    } else
                        return false;
                } else { // (offset > 0)
                    if ((fbuff->m_curPos + offset) < fbuff->m_sizeBuff) {
                        fbuff->m_curPos += offset;
                    } else
                        return false;
                }
                fbuff->m_bytesInBuff = fbuff->m_sizeBuff - fbuff->m_curPos;
                return true;
                break;
            }

        } else
            return false;
    }
    // else handle FILE seek ================================
    if (fseeko64(fbuff->m_file, offset, origin) != 0) {
        fbuff->m_bytesInBuff = 0;
        fbuff->m_EOF = true;
        return false;
    }
    InitFirstReadDFileBuffer(fbuff);
    return true;
}

bool RewindDFileBuffer(DFileBuffer *fbuff) {
    return FseekDFileBuffer(fbuff, 0, SEEK_SET);
}

unsigned int GetBytesDFileBuffer(DFileBuffer *fbuff, void *buff, unsigned int bytesToGet) {
    unsigned int bytesCopied = 0,
                 remainBytesToGet = bytesToGet;
    char * cbuff = (char*) buff;
    if (fbuff->m_file == NULL && fbuff->m_data == NULL)
        return 0;
    if (fbuff->m_bytesInBuff == 0) {
        if (fbuff->m_EOF)
            return 0;
        ReadChunkDFileBuffer(fbuff);
        if (fbuff->m_bytesInBuff == 0)
            return 0;
    }
    while (remainBytesToGet > 0) {
        // last block
        if (remainBytesToGet <= fbuff->m_bytesInBuff) {
            memcpy(&cbuff[bytesCopied], &fbuff->m_buffRead[fbuff->m_curPos], remainBytesToGet);
            fbuff->m_curPos += remainBytesToGet;
            fbuff->m_bytesInBuff -= remainBytesToGet;
            if (fbuff->m_bytesInBuff == 0) {
                if (!fbuff->m_EOF)
                    ReadChunkDFileBuffer(fbuff);
            }
            return bytesToGet; // success to get all bytes !!
        } else { // get all available bytes and try to get more
            memcpy(&cbuff[bytesCopied], &fbuff->m_buffRead[fbuff->m_curPos], fbuff->m_bytesInBuff);
            remainBytesToGet -= fbuff->m_bytesInBuff;
            bytesCopied += fbuff->m_bytesInBuff;
            // not the last chunk, try to read more
            if (!fbuff->m_EOF) {
                ReadChunkDFileBuffer(fbuff);
                if (fbuff->m_EOF && fbuff->m_bytesInBuff == 0) {
                    break;
                }
            } else {
                break;
            }
        }
    }
    // read next possible chunk if buff is emty
    if (fbuff->m_bytesInBuff == 0) {
        ReadChunkDFileBuffer(fbuff);
    }

    return bytesCopied;
}

unsigned int GetLineDFileBuffer(DFileBuffer *fbuff, char *line, unsigned int maxLineSize) {
    unsigned int    sizeLine = 0,
                    bytesCopied = 0,
                    i = 0,
                    startPos = fbuff->m_curPos;
    bool            endLine = false;

    if (fbuff->m_file == NULL && fbuff->m_data == NULL)
        return 0;
    if (fbuff->m_bytesInBuff == 0) {
        if (fbuff->m_EOF)
            return 0;
        ReadChunkDFileBuffer(fbuff);
        if (fbuff->m_bytesInBuff == 0)
            return 0;
        startPos = 0;
    }
    for (i=0; i <maxLineSize-1; i++) {
        if (fbuff->m_buffRead[fbuff->m_curPos] == '\n' || fbuff->m_buffRead[fbuff->m_curPos] == '\r') {
            fbuff->m_curPos++;
            fbuff->m_bytesInBuff--;
            // read next chunk if required and copy
            if (fbuff->m_bytesInBuff < 1) {
                memcpy(&line[bytesCopied], &fbuff->m_buffRead[startPos], sizeLine - bytesCopied);
                bytesCopied += sizeLine;
                ReadChunkDFileBuffer(fbuff);
            }
            // check if next byte too is one of line terminator
            if (fbuff->m_bytesInBuff > 0 && (fbuff->m_buffRead[fbuff->m_curPos] == '\n' || fbuff->m_buffRead[fbuff->m_curPos] == '\r')) {
                fbuff->m_curPos++;
                fbuff->m_bytesInBuff--;
            }
            endLine = true;
        }
        if (endLine)
            break;
        sizeLine ++;
        if (fbuff->m_bytesInBuff > 1) {
            fbuff->m_curPos++;
            fbuff->m_bytesInBuff--;
        } else if (fbuff->m_bytesInBuff == 1) {
            memcpy(&line[bytesCopied], &fbuff->m_buffRead[startPos], sizeLine - bytesCopied);
            bytesCopied = sizeLine;
            startPos = 0;
            if (!fbuff->m_EOF) {
                ReadChunkDFileBuffer(fbuff);
            } else {
                fbuff->m_bytesInBuff = 0;
            }
        } else {
            break;
        }
    }
    if (bytesCopied < sizeLine)
        memcpy(&line[bytesCopied], &fbuff->m_buffRead[startPos], sizeLine - bytesCopied);
    line[sizeLine] = 0;
    // read next possible chunk if buff is emty
    if (fbuff->m_bytesInBuff == 0) {
        ReadChunkDFileBuffer(fbuff);
    }
    return sizeLine;
}

bool IsEndOfFileDFileBuffer(DFileBuffer *fbuff) {
    return fbuff->m_EOF && (fbuff->m_bytesInBuff == 0);
};
