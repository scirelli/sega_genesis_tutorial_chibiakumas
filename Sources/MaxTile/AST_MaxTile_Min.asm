
	include "\SrcAll\BasicMacros.asm"
		
;tiletest_basiconly equ 1
;slowdowntest equ 1


;patterndata equ 8
;PatternFill equ 0


;TestChibiko equ 16+1
;TestSprite equ 0


DoubleBuffered equ 1
						
CacheAddr1 equ MaxTileData+$0000
CacheAddr2 equ MaxTileData+$0200
CacheAddr3 equ MaxTileData+$0400


CacheTable equ MaxTileData+$0600
	ifnd DoubleBuffered
CacheTable_Last equ T_CacheTable_Last-T_CacheTable +CacheTable
CacheTable_End equ T_CacheTable_End-T_CacheTable +CacheTable
	endif
Vline equ CacheTable+32;  db 0		;For Screen Draw Sync to crt line
CropYH	equ Vline+2;: dw 0
CropXW equ CropYH+2 ;: dw 0

BackgroundTilemapBase equ CropXW+2;: dw BackgroundTilemap2+2
BackgroundTilemapWidth equ BackgroundTilemapBase+4;:	db 36*2
BackgroundTilemapScrollX equ BackgroundTilemapWidth+2;: db 0
BackgroundTilemapScrollY equ BackgroundTilemapScrollX+2;: db 0
TileTmpW equ BackgroundTilemapScrollY+2 ;: dw 0
SPrestore equ TileTmpW+2
CacheTableAddr equ  SPrestore+2 ;: dw CacheTable
	
BackgroundTilemap2 equ MaxTileData+$0800	;36*28*2+4


;Logical units are pairs of pixels

;UseStackMisuse equ 1

VscreenMinX equ 64		;Top left of visible screen in logical co-ordinates
VscreenMinY equ 80

;VscreenWid equ 24		;Visible Screen Size in logical units
;VscreenHei equ 24

;LIMITATION.. The Virtual screen cannot be smaller than the sprite or 
;the crop will malfunction! (It can be the same size)

VscreenWid equ 128		;Visible Screen Size in logical units
VscreenHei equ 96

	
VscreenWidClip equ 2	;alter right boundary due to working in words
VscreenHeiClip equ 0



allowquartertilescroll equ 1
allowhalftilescroll equ 1

hiresx equ 1
hiresy equ 1

BackgroundTilemapWidthV equ 36


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

    SECTION TEXT		;CODE Section

    pea    ST_Start     ;Push address to call to onto stack
    move.w  #$26,-(sp)  ;Supexec (38: set supervisor execution)
    trap    #14         ;XBIOS Trap
    addq.w  #6,sp       ;remove item from stack
	jmp *				;Wait for Supervisor mode to start

ST_Start:
	move.b #$00,$ff8260		;Screen Mode: 00=320x200 4 planes
	
    move.l #screen_mem,d0  	;Move address to screen mem to d0
    add.l #$ff,d0      		;Add 255 d0 address
    clr.b d0           		;Clear lowest byte in address
    move.l d0,ScreenBase	;Save screen start
	
    lsr.w #8,d0       		;we need to convert $00ABCD?? into $00AB00CD
    move.l d0,$ff8200		;store the resulting 16 bits into the screen start register
							;&FF8201 = High byte
							;&FF8203 = Mid  byte
							;Low byte cannot be specified
							
	move.l #$ff8240,a1		;Define palette
	lea Palette,a0
	move.l #16-1,d0
PaletteAgain:						
	move.w (a0)+,(a1)+		;%-----RRR-GGG-BBB
	dbra d0,PaletteAgain
	
	
	jsr KeyboardScanner_AllowJoysticks						;S-----E- ---DCBA	S=Set/Clr E=enable ABCD=Channnels	
										
								
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Build the lookup table
		
	move.l #FlipLUT,a0		;Lookup table
	clr.l d1				;Byte to convert
FillLut:
	move.b d1,d0
	
	move.w #7,d3			;8 bits 
FillLut2:	
		roxr.b #1,d0		;Shift a bit right out of source
		roxl.b #1,d2		;Shift a bit left in to destination
	dbra d3,FillLut2
	
	move.b d2,(a0)+			;Write the byte
	
	addq.b #1,d1			;Repeat for 0-255
	bne FillLut

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
		
	
			
;Clear ram
	move.l #CacheAddr1,a3
	move.l #$A00,d1
	jsr CLDIR0						;Clear D1 bytes from A3
	
;Copy Cachetable template to ram
	ifnd DoubleBuffered
		move.l #T_CacheTable,a3
		move.l #CacheTable,a2
		move.l #T_CacheTable_End-T_CacheTable,d1
		jsr ldir
	endif
	
	move.l #T_BackgroundTilemap2,a3
	move.l #BackgroundTilemap2,a2
	move.l #36*28*2+4,d1
	jsr LdirSwapEndian
	
	;move.l #ScreenBase,a6
	;jsr prepareVram
	;move.w #1,(VDP_data) ;C00000 Select tile for mem loc
	
	
	
	move.l (ScreenBase),a3
	
	move.b #255,(a3)
	
	move.b #255,(160+1,a3)
	
	jmp RunTest1
	
		
	
		
		
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	

	

	
waitVBlank:
	move.l ($DFF004),d0		;VPOSR - Read vert most signif. bit (and frame flop)
	and.l #$1ff00,d0
	cmp.l #$12C00,d0		;Test to see if we're in Vblank
	bne waitVBlank
VblankDone:		
	rts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
	
	
	include "\SrcAST\AST_V1_MaxTile_Normal.asm"
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
	


	ifd DoubleBuffered
		include "\SrcAll\V1_MaxTile_DirectDriver.asm"
	else
		include "\SrcAll\V1_MaxTile_CacheDriver.asm"
	endif 

 	include "\SrcAll\V1_MaxTile.asm"

	include "MaxTile_Test1.asm"

 	include "\SrcAll\BasicFunctions.asm"

PatternFill:
	dc.b $00,$00,$00,$00
	dc.b $00,$00,$00,$FF
	dc.b $00,$00,$FF,$00
	dc.b $00,$00,$FF,$FF
	dc.b $00,$FF,$00,$00
	dc.b $00,$FF,$00,$FF
	dc.b $00,$FF,$FF,$00
	
PatternData:
TestSprite:
	incbin "\ResALL\Yquest\AST_YQuest.RAW"
TestChibiko:
	incbin "\ResALL\SpeedTiles\Chibiko2TilesAST.RAW"

	align 2
	
	
Palette:
    dc.w %0000000000000000; ;0  %-----RRR-GGG-BBB
    dc.w %0000010000000111; ;1  %-----RRR-GGG-BBB
    dc.w %0000000001110111; ;2  %-----RRR-GGG-BBB
    dc.w %0000011101110111; ;3  %-----RRR-GGG-BBB
    dc.w %0000000000000100; ;4  %-----RRR-GGG-BBB
    dc.w %0000010000000100; ;5  %-----RRR-GGG-BBB
    dc.w %0000000001000100; ;6  %-----RRR-GGG-BBB
    dc.w %0000011001100110; ;7  %-----RRR-GGG-BBB
    dc.w %0000010001000100; ;8  %-----RRR-GGG-BBB
    dc.w %0000011100000000; ;9  %-----RRR-GGG-BBB
    dc.w %0000000001110000; ;10  %-----RRR-GGG-BBB
    dc.w %0000011101110000; ;11  %-----RRR-GGG-BBB
    dc.w %0000000000000111; ;12  %-----RRR-GGG-BBB
    dc.w %0000011100000111; ;13  %-----RRR-GGG-BBB
    dc.w %0000000001110111; ;14  %-----RRR-GGG-BBB
    dc.w %0000011101110111; ;15  %-----RRR-GGG-BBB



readJoystick:
	move.b (Joystickdata+1),d0	;Process Joy 1
	
Player_ReadControlsProcessOne:;Joypad bits 			F---RLDU  	?
	or.l #$FFFFFF00,d0
	roxl.b #1,d0			;Fire -> eXtend flag	---RLDU-   	F 
	rol.b #3,d0				;skip Unused bits		RLDU----   	F 
	roxr.b #1,d0			;Get back F				FRLDU---   	- 
	ror.b #3,d0				;Move needed bits back	---FRLDU   	- 
	eor.b #$FF,d0			;Flip the bits of the bottom byte
	rts

		
		
		
KeyboardScanner_AllowJoysticks:	;Install Joystick handler

	move.w	#$14,-(sp)		;IKBD command $14 - set joystick event reporting
	move.w	#4,-(sp)		;Device no 4 (keyboard - Joystick is part of keyboard)
	move.w	#3,-(sp)		;Bconout (send cmd to keyboard)
	trap	#13				;BIOS Trap
	addq.l 	#6,sp			;Fix the stack

	move.w  #34,-(sp)		;return IKBD vector table (KBDVBASE)
	trap  	#14				;XBIOS trap
	addq.l  #2,sp 			;Fix the stack
	
	move.l  d0,IkbdVector 	;store IKBD vectors address for later
	move.l  d0,a0  			;A0 points to IKBD vectors
	move.l  (24,a0),OldJoyVec;backup old joystick vector so we can restore it
	
	move.l  #JoystickHandler,(24,a0); Set our Joystick Handler
	rts
	
JoystickHandler:			;This is our Joystick handler, it will be executed 
							;by the firmware handler

	move.b  (1,a0),Joystickdata  ; store joy 0 data
	move.b  (2,a0),Joystickdata+1; store joy 1 data
	rts  

IkbdVector:	dc.l 0 			; original IKBD vector storage
OldJoyVec:	dc.l 0    		; original joy vector storage
Joystickdata:ds.b 2			;Joypad bits F---RLDU 



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    SECTION BSS ;Block Started by Symbol - Data initialised to Zero
;dc.l won't work in BSS - use DS commands instead
screen_mem:				;Reserve screen memory 
    ds.b    32256
ScreenBase: ds.l 1		;Var for base of screen ram
		
	

	align 8
FlipLUT:
	ds.b 256

MaxTileData:
	ds.b 32768
	
