## DOS Ultimate Game Library (DUGL)
DUGL is a super fast, 32bits/DOS only/ C, Assembly Game library using software rasterizer.
Started on 1999 as a **DOS** (https://en.wikipedia.org/wiki/DOS) game library, using **DJGPP** (https://delorie.com/djgpp/) as gcc C/C++ compiler and **NASM** (https://nasm.us/) as the assembly compiler and targeting Intel **MMX+** CPU and DOS compatible OS and VESA 2.0 for graphic initialization.

This is an attempt to Create a new version of DOS DUGL that provide as much as possible functionalities of  Modern DUGL (Dust Ultimate Game library) https://github.com/FFK77/DUGL

### Target platform ###

DOS and compatible OS, intel x86 MMX+ compatible CPU.

### why and Goals ###

As a viable DOS port of SDL2 isn't going to happen soon or at all. The modern DUGL as an SSE4.1+ wipe out about 10 years of legacy/old computer that could benefit from a fast/modern Graphic/game Library.
The Old DJGPP/DOS DUGL provide a good starting point to create a new DOS port/SDL free.
Goal is to allow any project built with modern DUGL to build on this DOS/DJGPP version without source changes.
How ever, according to tests that confirm theory, the usage of only MMX assembly, the lack of multi-core/multi-thread support of DOS make this version Up to 6-7 times slower.

### Features ###

DUGL provide an Ultra-optimized graphic functions, the performance don't come only from the hundreds of cycles optimizing assembly (and learning new tricks every time), but also from algorithmic and technical choices:

- focus on 16bpp rendering: selected as the best of the two worlds (8bpp too few colors and hard to make nice effects with but fast; 32bpp too nice but slow throughput, slower to handle, twice memory consumption ...)
- most of the rendering functions are split into sub uses cases (mostly 2 levels) (completely inside screen / clipped) ( then as for the line dx = 0 or dy = 0 or both or regular line ) each of the sub use case is optimized a part...
- no perspective corrected texture mapping, splitting only near polygones/tries into sub polygones/tries provide a highly acceptable rendering and we avoid the high cost of perspective corrected rendering
- no Z-buffer as this not a feature that complex generic CPU aren't best in


RePoly function is a nice addition to provide both performance and feature: as x86-32bits has few registers, implementing complex effect will be very slow, the idea here is to stack effect one by one. Repoly re-render last polygone but up to 30% faster as borders / (in/out/clipped) are already computed, a user can for example render on flat textured poly, then apply lightening with transparent textures poly, then add masked textured grass ..

Fast anti-aliased rendering is also a possiblity, as DOS games are mostly distinguishable by their pixelized look, DUGL a provide a smooth function (melting RGB of near pixels), doing a cool anti-aliased "like" rendering can be done by rendering into a higher resolution Surface, smooth the surface, then resize the surface to rendering size, .. the performance loss depends, according to benchmarks a nice looking rendering is about 50% to 70% slower than regular rendering

For more details on Features, screenshots please check the Modern DUGL page (https://github.com/FFK77/DUGL)



### Building ###
#####  Under Windows: #####
Requirement:

- **CodeBlocks IDE** (https://www.codeblocks.org) as a very convenient IDE to use for development.
- **Mingw/djgpp** cross compiler (https://github.com/andrewwutw/build-djgpp)
- **Nasm** (https://nasm.us/)
- **DJGPP Pthreads** port (FSU Pthreads (POSIX Threads) 3.14), **LibJpeg**, **LibPNG** and **ZLib** from https://www.delorie.com/pub/djgpp/current/v2tk/

Compiling asm sources:

**CodeBlocks** do not support compiling asm source files using nasm by default. 
You need to (1) Go to **Global compilers Settings** => **Other settings** => **Advanced options..** (2) Add two new **Source ext** "asm" and "ASM" (3) Select 
the **Command** "Compile single file to object file" and (4) set the **Command line macro:** to "nasm $file -f coff -Ox -o $object"


### Contact ###

Please feel free to email the author(s) - libdugl(at)hotmail.com





 
