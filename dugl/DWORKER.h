/*	Dust Ultimate Game Library (DUGL)
    Copyright (C) 2026  Fakhri Feki

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

#ifndef DWORKER_H_INCLUDED
#define DWORKER_H_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

// DWorker support =====================================================================

typedef void (*dworkerFunctionPointer)(void*, int);

unsigned int CreateDWorker(dworkerFunctionPointer workerFunction, void *workerData);
void RunDWorker(unsigned int dworkerID, bool WaitIfBusy);
void SetDWorkerDataPtr(unsigned int dworkerID, void *dataPtr);
void SetDWorkerFunction(unsigned int dworkerID, dworkerFunctionPointer workerFunction);
// Set DWorker thread priority: 0 highest - 3 lowest
void SetDWorkerPriority(int priority);
bool IsBusyDWorker(unsigned int dworkerID);
void WaitDWorker(unsigned int dworkerID);
bool WaitTimeOutDWorker(unsigned int dworkerID, unsigned int timeOut);
void DestroyDWorker(unsigned int dworkerID);
void DWorkerYield();

// Mutex
#define PDMutex void*
void *CreateDMutex();
void  DestroyDMutex(PDMutex DMutexPtr);
int  LockDMutex(PDMutex DMutexPtr);
int  UnlockDMutex(PDMutex DMutexPtr);
bool  TryLockDMutex(PDMutex DMutexPtr);

#ifdef __cplusplus
        }  // extern "C" {
#endif

#endif // DWORKER_H_INCLUDED

