what is ?

This driver format and assembly sources are a proof of concept of a 32bits/protected mode, 
flat, real-time loadable/unloadable and self locate it self Sound driver.

What we have here ?

-sb16.drv : Is sound blaster 16 and 100% compatible driver.
-sbpro.drv : Is sound blaster Pro and 100% compatible driver.
-nosound.drv : is the dummy no sound driver

Requirement ?

- Those drivers can used by any plateform as there is at least a DPMI 0.9 and a 
  DOS compatible operating system.
- The DUGL PLus module DSound.h give an example of the usage/loading/unloading.
  
License:

Those drivers and assembly sources are a part of the DUGL Plus, so see License.txt of the
DUGLPlus Library
