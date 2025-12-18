what is ?

DUGL-Plus is the addon/source available library for DUGL the DOS Game library.
it contains :
- GUI : Is a set of C++ classes that i made from scratch, sources and ideas
  having only a few knowledge about GUIs (Ms VB6 and MFC).
  Starting from DUGL Plus 0.3 it has the following features :
  * Capability of both 16bpp/8bpp graphics
  * Contains a set of 14 GUI objects including
    (MAinWindow, Button, Image button, ComboBox, Label, TextBox, Menu, Slider,...)
  * Contains 2 boxes, including MessageBox and FileBox.
- Sound : Is an attempt or a proof of concept of a protected mode/loadable sound driver.
  Now contains Sound Blaster 16, Sound Blaster pro and nosound driver.
  (see : snddrv/readme.txt)
- Image : A set of helpful functions to load and store images format using open source
  Libraries.
- Math : a Garbage math lib, maybe it will be useful for some one :))
   
Requirement ?

- The DUGL library starting from version 1.10 alfa1. Get it from "dugl.50webs.com'.
- Any requirement for the DUGL library it self. see "readme.txt" of DUGL.
- An installed libjpeg6 on your DJGPP devloppment env if you are going to use jpeg,
  you can get the binaries from 'www.delorie.com/djgpp'

How to install ?

1/ copy DGUI.h, DSound.h, DImage.h, DMAth3d.h and DUGLPlus.h to %DJGPP_PATH%/include/DUGL
2/ copy libduglp.a %DJGPP_PATH%/libs