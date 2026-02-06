/*  Dust Ultimate Game Library (DUGL)
    Copyright (C) 2025  Fakhri Feki

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

    contact: libdugl(at)hotmail.com    */

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#include "DUGL.h"
#include "intrdugl.h"


// DWorker /////////////////////////////////////////////////

unsigned int countDWorker = 0;
unsigned int MaxDWorkersCount = 0;
unsigned int FirstFreeDWorkerID = 0;
bool *conditionsDWorker = NULL;
bool *killsDWorker = NULL;
pthread_mutex_t  **locksDworker = NULL;
pthread_cond_t  **condsDworker = NULL;
pthread_t  **threadsDWorker = NULL;
dworkerFunctionPointer *funcsDWorker = NULL;
void **paramsDWorker = NULL;
unsigned int *dataThreadsID = NULL;

bool InitDWorkers(unsigned int MAX_DWorkers) {
    if (countDWorker > 0 || (MAX_DWorkers > 0 && MAX_DWorkers < 4))
        return false;
    unsigned int maxDWorkers = (MAX_DWorkers == 0) ? DWORKERS_DEFAULT_MAX_COUNT : MAX_DWorkers;
    conditionsDWorker = (bool *)malloc(sizeof(bool)*maxDWorkers);
    killsDWorker = (bool *)malloc(sizeof(bool)*maxDWorkers);
    locksDworker = (pthread_mutex_t **)malloc(sizeof(pthread_mutex_t *)*maxDWorkers);
    condsDworker = (pthread_cond_t **)malloc(sizeof(pthread_cond_t *)*maxDWorkers);
    threadsDWorker = (pthread_t **)malloc(sizeof(pthread_t *)*maxDWorkers);
    funcsDWorker = (dworkerFunctionPointer *)malloc(sizeof(dworkerFunctionPointer)*maxDWorkers);
    paramsDWorker = (void**)malloc(sizeof(void *)*maxDWorkers);
    dataThreadsID = (unsigned int*)malloc(sizeof(unsigned int)*maxDWorkers);
    if (conditionsDWorker != NULL && locksDworker != NULL && condsDworker != NULL && threadsDWorker != NULL &&
            paramsDWorker != NULL && dataThreadsID != NULL) {
        MaxDWorkersCount = maxDWorkers;
        memset(conditionsDWorker, 0, sizeof(bool)*maxDWorkers);
        memset(killsDWorker, 0, sizeof(bool)*maxDWorkers);
        memset(locksDworker, 0, sizeof(pthread_mutex_t *)*maxDWorkers);
        memset(condsDworker, 0, sizeof(pthread_cond_t *)*maxDWorkers);
        memset(threadsDWorker, 0, sizeof(pthread_t *)*maxDWorkers);
        memset(paramsDWorker, 0, sizeof(void *)*maxDWorkers);
        for (unsigned int i=0; i<maxDWorkers; i++) dataThreadsID[i] = i+1;
        FirstFreeDWorkerID = 0;
        return true;
    }
    DestroyDWorkers();
    return false;
}

void DestroyDWorkers() {
    //unsigned int idx = 0;
    // destroy all current DWorkers
    if (countDWorker > 0) {
        for (int idx = 1; countDWorker > 0 && idx <= MaxDWorkersCount; idx++)
            DestroyDWorker(idx);
    }
    // free allocated mem
    if (conditionsDWorker != NULL)
        free(conditionsDWorker);
    if (killsDWorker != NULL)
        free(killsDWorker);
    if (locksDworker != NULL)
        free(locksDworker);
    if (condsDworker != NULL)
        free(condsDworker);
    if (threadsDWorker != NULL)
        free(threadsDWorker);
    if (paramsDWorker != NULL)
        free(paramsDWorker);
    if (dataThreadsID != NULL)
        free(dataThreadsID);

    countDWorker = 0;
    MaxDWorkersCount = 0;
    conditionsDWorker = NULL;
    killsDWorker = NULL;
    locksDworker = NULL;
    condsDworker = NULL;
    threadsDWorker = NULL;
    paramsDWorker = NULL;
    dataThreadsID = NULL;
}

static int WorkerThreadFunction(void *ptr) {
    unsigned int myIdx = *(unsigned int*)(ptr);
    if (MaxDWorkersCount == 0 || myIdx == 0 || myIdx > MaxDWorkersCount)
        return 0;
    myIdx --;
    for(;!killsDWorker[myIdx];) {
        pthread_mutex_lock(locksDworker[myIdx]);
        while (!conditionsDWorker[myIdx]) {
            pthread_cond_wait(condsDworker[myIdx], locksDworker[myIdx]);
        }
        if (funcsDWorker[myIdx] != NULL && !killsDWorker[myIdx]) {
            funcsDWorker[myIdx](paramsDWorker[myIdx], *(int*)ptr);
        }
        conditionsDWorker[myIdx] = false;
        pthread_mutex_unlock(locksDworker[myIdx]);
    }
    killsDWorker[myIdx] = false;

    return 0;
}

int WorkerPriority[4] = { 0, 1, 2, 3 };

void SetDWorkerPriority(int priority) {
    // dummy
}

void SetDWorkerDataPtr(unsigned int dworkerID, void *dataPtr) {
    if (dworkerID == 0 || dworkerID > MaxDWorkersCount)
        return;
    unsigned int idx = dworkerID - 1;
    if (threadsDWorker[idx] == NULL)
        return;
    paramsDWorker[idx] = dataPtr;
}

void SetDWorkerFunction(unsigned int dworkerID, dworkerFunctionPointer workerFunction) {
    if (MaxDWorkersCount == 0 || dworkerID == 0 || dworkerID > MaxDWorkersCount)
        return;
    unsigned int idx = dworkerID - 1;
    if (threadsDWorker[idx] == NULL)
        return;
    funcsDWorker[idx] = workerFunction;
}

unsigned int findFirstFreeDWorkerID() {
    if (countDWorker >= MaxDWorkersCount)
        return 0xFFFFFFFF;
    unsigned int newID = FirstFreeDWorkerID+1;
    if (newID < MaxDWorkersCount && threadsDWorker[newID] == NULL)
        return newID;
    for (unsigned int i=0; i<MaxDWorkersCount; i++) {
        if (threadsDWorker[i] == NULL)
            return i;
    }
    return 0xFFFFFFFF;
}


unsigned int CreateDWorker(dworkerFunctionPointer workerFunction, void *workerData) {
    unsigned int newWorkerIdx = 0;
    char nameWorker[12];
    if (countDWorker >= MaxDWorkersCount)
        return 0;
    newWorkerIdx = FirstFreeDWorkerID;
    sprintf(nameWorker, "DWorker%d", newWorkerIdx);
    funcsDWorker[newWorkerIdx] = workerFunction;
    paramsDWorker[newWorkerIdx] = workerData;
    conditionsDWorker[newWorkerIdx] = false;
    locksDworker[newWorkerIdx] = (pthread_mutex_t*)malloc(sizeof(pthread_mutex_t));
    condsDworker[newWorkerIdx] = (pthread_cond_t*)malloc(sizeof(pthread_cond_t));
    threadsDWorker[newWorkerIdx] = (pthread_t*)malloc(sizeof(pthread_t));
    if (locksDworker[newWorkerIdx] == NULL || condsDworker[newWorkerIdx] == NULL || threadsDWorker[newWorkerIdx] == NULL) {
        if (locksDworker[newWorkerIdx] == NULL)
            free(locksDworker[newWorkerIdx]);
        if (condsDworker[newWorkerIdx] == NULL)
            free(condsDworker[newWorkerIdx]);
        if (threadsDWorker[newWorkerIdx] == NULL)
            free(threadsDWorker[newWorkerIdx]);

        return 0;
    }
    int retCond = 0;
    int retCreate = 0;
    pthread_mutex_init(locksDworker[newWorkerIdx], NULL);
    retCond = pthread_cond_init(condsDworker[newWorkerIdx],NULL);
    retCreate = pthread_create(*threadsDWorker[newWorkerIdx], NULL, WorkerThreadFunction, &dataThreadsID[newWorkerIdx]);
    if (retCond || retCreate) {
        if (!retCreate)
            pthread_detach(*threadsDWorker[newWorkerIdx]);
        pthread_mutex_destroy(locksDworker[newWorkerIdx]);
        free(locksDworker[newWorkerIdx]);
        locksDworker[newWorkerIdx] = NULL;
        if (!retCond)
            pthread_cond_destroy(condsDworker[newWorkerIdx]);
        free(condsDworker[newWorkerIdx]);
        condsDworker[newWorkerIdx] = NULL;
        free(threadsDWorker[newWorkerIdx]);
        threadsDWorker[newWorkerIdx] = NULL;
        return 0;
    }

    countDWorker++;
    FirstFreeDWorkerID = findFirstFreeDWorkerID();

    return newWorkerIdx+1;
}

void RunDWorker(unsigned int dworkerID, bool WaitIfBusy) {
    if (MaxDWorkersCount == 0 || dworkerID == 0 || dworkerID > MaxDWorkersCount)
        return;
    unsigned int idx = dworkerID - 1;
    if (threadsDWorker[idx] == NULL)
        return;

    if (conditionsDWorker[idx]) {
        if (WaitIfBusy)
            WaitDWorker(dworkerID);
    }
    pthread_mutex_lock(locksDworker[idx]);
    conditionsDWorker[idx] = true;
    pthread_cond_signal(condsDworker[idx]);
    DWorkerYield();
    pthread_mutex_unlock(locksDworker[idx]);
}

bool IsBusyDWorker(unsigned int dworkerID) {
    if (MaxDWorkersCount == 0 || dworkerID == 0 || dworkerID > MaxDWorkersCount)
        return false;
    unsigned int idx = dworkerID - 1;
    if (threadsDWorker[idx] == NULL)
        return false;
    return conditionsDWorker[idx];
}

void WaitDWorker(unsigned int dworkerID) {
    if (MaxDWorkersCount == 0 || dworkerID == 0 || dworkerID > MaxDWorkersCount)
        return;
    unsigned int idx = dworkerID - 1;
    if (threadsDWorker[idx] == NULL)
        return;
    while(conditionsDWorker[idx]) {
        sched_yield();
    };
}

bool WaitTimeOutDWorker(unsigned int dworkerID, unsigned int timeOut) {
    unsigned int idx = dworkerID - 1;
    unsigned int timeout = DgTime + ((timeOut * DgTimerFreq) / 1000);

    if (MaxDWorkersCount == 0 || dworkerID == 0 || dworkerID > MaxDWorkersCount)
        return false; // invalid dworkerID

    while (DgTime < timeout) {
        if (!conditionsDWorker[idx])
            return true;
        sched_yield();
    }
    return false; // timed out
}

void DWorkerYield() {
    sched_yield();
}

void DestroyDWorker(unsigned int dworkerID) {
    if (MaxDWorkersCount == 0 || dworkerID == 0 || dworkerID > MaxDWorkersCount)
        return;
    unsigned int idx = dworkerID - 1;

    if (threadsDWorker[idx] != NULL) {
        // enable killing of DWorked thread loop
        killsDWorker[idx] = true;
        RunDWorker(dworkerID, true);
        // wait until kill thread is set to false by thread loop
        while(killsDWorker[idx]) {
            if (DgTimerFreq<500)
                DgDelay(4);
            else
                DgDelay(2);
        }

        pthread_detach(*threadsDWorker[idx]);
        if (condsDworker[idx] != NULL) {
            pthread_cond_destroy(condsDworker[idx]);
            free(condsDworker[idx]);
            condsDworker[idx] = NULL;
        }
        if (locksDworker[idx] != NULL) {
            pthread_mutex_destroy(locksDworker[idx]);
            free(locksDworker[idx]);
            locksDworker[idx] = NULL;
        }
        countDWorker --;
        if (idx < FirstFreeDWorkerID)
            FirstFreeDWorkerID = idx;
        threadsDWorker[idx] = NULL;
    }
    funcsDWorker[idx] = NULL;
    paramsDWorker[idx] = NULL;
    conditionsDWorker[idx] = false;
}

// Mutex ///////////////////////////////////////////////////

PDMutex CreateDMutex() {
    DMutex *mutex = (DMutex*)malloc(sizeof(DMutex));
    if (mutex != NULL) {
        mutex->Sign = 'XTMD'; // "DMTX"
        pthread_mutex_init(&mutex->mutex, NULL);
    }
    return mutex;
}

void  DestroyDMutex(PDMutex DMutexPtr) {
    DMutex *mutex = (DMutex*)DMutexPtr;
    if (mutex->Sign == 'XTMD') {
        pthread_mutex_destroy(&mutex->mutex);
        mutex->Sign = 0;
        free(mutex);
    }
}

void  LockDMutex(PDMutex DMutexPtr) {
    DMutex *mutex = (DMutex*)DMutexPtr;
    if (mutex->Sign == 'XTMD') {
        pthread_mutex_lock(&mutex->mutex);
    }
}

void  UnlockDMutex(PDMutex DMutexPtr) {
    DMutex *mutex = (DMutex*)DMutexPtr;
    if (mutex->Sign == 'XTMD') {
        pthread_mutex_unlock(&mutex->mutex);
    }
}

bool  TryLockDMutex(PDMutex DMutexPtr) {
    DMutex *mutex = (DMutex*)DMutexPtr;
    if (mutex->Sign == 'XTMD') {
        return (pthread_mutex_trylock(&mutex->mutex) == 0);
    }
    return false;
}
