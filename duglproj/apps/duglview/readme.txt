_____
About
-----

DUGL Viewer is a GUI image viewer for DOS systems.

Developped by using :
- DUGL 1.16 and DUGL Plus 0.31 <http://dugl.50webs.com>
- The excellent C/C++ compiler DJGPP <http://www.delorie.com/djgpp/>
- Libjpeg, Zlib and Libpng to provide support for both jpeg and png image format

Visit <http://dugl.50webs.com/appgame.html#DViewer> to check for any update or the
sub forum <http://dugl.1114869.n2.nabble.com/DUGL-softwares-f1122399.html> to ask 
for support.
___________
1 - History
-----------

* 21/02/2011 ver 0.1 :

  - First experimental release

* 23/02/2011 ver 0.2 :

  - Added displaying : page number / total pages. 
  - Added sorting images files by name.
  - Added current picture smoothing with keyboard shortcut F5 (disabled by default).
  - Modified mouse default position to left, bottom.

* 26/02/2011 ver 0.3 :
  
  - Added support for a config file "duglview.cfg".
  - Modified main window label to display current opened file name.
  - Modified auto load files keyboard shortcut to Alt+F3 or Alt+mouse click open button.
  - Added support for 24/8bpp uncompressed BMP image format.
  - Added support for PCX 8bpp image format
  - Added support for GIF 8bpp not interlaced image format.

* 21/08/2011 ver 0.4 (first official) :

  - Redesigned the GUI.
  - Added support for png image format using zlib and libpng
  - Added three viewing mode : fit width, fit view and "As Is"(100% zoom)
    and keyboard shortcut F6 to switch between viewing modes.
  - Added support for better quality downsizing images.
  - Improved Zoom Down/Up display quality by enabling smoothing two times
    (lose some brightness).
  - Added better image navigation using mouse drag, and mouse wheel (require CTMouse)
  - Added about button and dialog
  - Added more parameters inside the duglview.cfg
  - Changed screenshot from jpg to bmp and keyboard from Ctrl+Shift+tab to alt+'S' 
  - Added error message at start-up if we are running WindowsNT/XP/Vista/7
  - Removed displaying Focus when image view get it.
  - Added multiple image mask, to filter all images formats supported.
  - Bug fixes ..

__________________________
2 - Keyboard/Mouse control
--------------------------

- Alt+X  : Exit
- F3     : (*1) Open a single image file 
- Alt+F3 : (*1) Autoload multi-image file (if you choose img001.jpg he will pick all img*.jpg files)
- F5     : Enable/Disable current image up zoom smoothing
- F6     : Switch between viewing modes
- Down   : Scroll current image down or keep pushed for <default 0.25> sec to go to next pic
- Up     : Scroll current image up or keep pushed for <default 0.5> sec to go to previous pic
- Right, Left : Scroll the image right and left.
- begin    : Go to first pic
- End      : Go to last pic
- PageDown : Go to next pic
- PageUp   : Go to previous pic
- Alt+S    : Make a screenshot "duglvew[r]->[z].bmp" on current directory/drive, searching for not used screenshot name.
- MouseWheel     : (*2) Scroll image up/down
- MouseWheel+(Left or Right)MouseButton   : (*2) Scroll image right/left
- Mouse Left Button + Mouse Move : scroll the image according to mouse moves.  

(*1) could be swapped using duglview.cfg
(*2) mouse wheel scroll direction could be swapped using duglview.cfg

___________________________
3 - Supported image formats
---------------------------

- Jpeg
- PNG (some problem with interlaced images)
- Bitmap Uncompressed 8bpp or 24bpp 
- GIF Not interlaced 8bpp 
- PCX 8bpp

______________________
4 - Configuration File
----------------------

DUGLVIEW.CFG should Stored on the same directory as DUGLVIEW.EXE.
It contains severals parameters allowing to customize Dugl viewer,
As Video mode, Default Mouse Postion, Default filtered image format ....
See DUGLVIEW.CFG for more details.

_______________________
5 - System requirements
-----------------------

- DOS or 100% compatible OS : FreeDOS, DRDOS, MSDOS, Windows 9x/Me ..
- CPU with MMX support.
- Graphics card with VESA 2.0 support
- Optional Mouse and driver (CTmouse required for mouse wheel support, Logitech driver, ...)

_________
6 - To do
---------

- Adding support for more images formats  WebP...
- Adding Full screen mode.
- Adding "dynamic zoom" view mode
- Adding more multi-files loading modes. 
- ..

___________
7 - License
-----------

DUGL Viewer is (C) 2011 by FFK. This a freeware, use it at your own risk.

