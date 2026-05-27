# Tutorials by Chibiakumas
I'm attempting to get these Window Sega Genesis tutorials working on Linux. The original project is made to work with many different machines, I'm only concerned with the Genesis right now. I think I will mode the source to focus on the 68000.

Seems easy enough so far, need to convert some Window paths in the source files to Unix/Linux style.
Also need to extract the assembler params/flags. There seems to be a main toolkit/project source [here 68000DevTools](https://chibiakumas.com/68000/68000DevTools.7z)

### Original setup
From the [website](https://chibiakumas.com/68000/68000DevTools.php)
```
* Please Download both and extract - and copy the files in Sources.7z OVER those in 68000DevTools.7z *
Getting Started
1. Extract the files from the [DevTools](https://chibiakumas.com/68000/68000DevTools.7z) archive into a folder on your machine - you need to preserve the directory structure

2. Extract the [sources.7z](https://chibiakumas.com/68000/sources.7z) into the same folder, overwriting existing files

3. To start run "Xdrive.bat" this will create a virtual X drive on your machine... if X is in use, V or W will be ued.

4. From that X drive use "Notepad++" to edit files, F6 will open the Assembly menu
The simplest examples are in the HelloWorld folder

5. when you are done use "Xdrive-remove" to remove the X drive

For Legal Reasons I cannot provide the NeoGeo.zip rom file... The rom file I use has the size 1,347,250 bytes
```
