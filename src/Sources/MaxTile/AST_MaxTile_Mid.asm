

	include "SrcAll/BasicMacros.asm"

AllowShifted equ 1			;Allow Partial shifts
						
CacheAddr1 equ MaxTileData+$0000	;Cache for top 1/3rd (512 bytes)
CacheAddr2 equ MaxTileData+$0200	;Cache for middle 1/3rd (512 bytes)
CacheAddr3 equ MaxTileData+$0400	;Cache for bottom 1/3rd (512 bytes)

CacheTable equ MaxTileData+$0600
	ifnd DoubleBuffered
CacheTable_Last equ T_CacheTable_Last-T_CacheTable +CacheTable
CacheTable_End equ T_CacheTable_End-T_CacheTable +CacheTable
	endif
	
CropYH	equ CacheTable+32
CropXW equ CropYH+2 

BackgroundTilemapBase equ CropXW+2 ;4 bytes
BackgroundTilemapWidth equ BackgroundTilemapBase+4
BackgroundTilemapScrollX equ BackgroundTilemapWidth+2
BackgroundTilemapScrollY equ BackgroundTilemapScrollX+2

CacheTableAddr equ  BackgroundTilemapScrollY+2 ;4 bytes

FlipMode equ CacheTableAddr+4	;db 0 	
;HspriteNum equ FlipMode+2	;db 0 	

BackgroundTilemap2 equ MaxTileData+$0800	;36*28*2+4

tileChibiko3 equ MaxTileData+$1000
tileChibiko2 equ tileChibiko3+80
tilePlayer equ tileChibiko2+80
tileChibiko equ tilePlayer+80

Sprite1 equ MaxTileData+$2000
Sprite2 equ Sprite1+40
Sprite3 equ Sprite2+40
Sprite4 equ Sprite3+40

allowquartertilescroll equ 1
allowhalftilescroll equ 1

hiresx equ 1
hiresy equ 1

;Logical units are pairs of pixels

VscreenMinX equ 64		;Top left of visible screen in logical co-ords
VscreenMinY equ 80

VscreenWid equ 128		;Visible Screen Size in logical units
VscreenHei equ 96
	
VscreenWidClip equ 3	;alter right boundary due to working in words
VscreenHeiClip equ 3

BackgroundTilemapWidthV equ 36	;Screen width in tiles (32+4 for scroll)




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

    SECTION TEXT		;CODE Section

    pea     ST_Start     ;Push address to call to onto stack
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
	move.l #$4000,d1
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
	

;Copy Sprite tilemaps to ram
	move.l #T_SpriteTilemaps,a3
	move.l #tileChibiko3,a2
	move.l #80*4,d1
	jsr LdirSwapEndian

;Copy Sprite Object data to ram
	move.l #T_Sprites,a3
	move.l #Sprite1,a2
	move.l #(T_Sprites_End-T_Sprites),d1
	jsr ldir
			
	jmp RunTest2
		
	
			
T_Sprites:
T_Sprite1: 
	dc.b $00,$00	;0 XY
	dc.b $20,$14	;2 WH
	dc.l tilePlayer 	;4 TilemapHL
	dc.l PatternData  ;8 PatternHL
	ds.b 16		;12	CropCache = 10 bytes
	ds.b 12		;28 CropCache_back = 8  bytes

T_Sprite2: 
	dc.b $60,$B0	;0 XY
	dc.b $20,$14	;2 WH
	dc.l tileChibiko	;4 TilemapHL
	dc.l PatternData  ;6 PatternHL
	ds.b 16		;12	CropCache = 10 bytes
	ds.b 12		;28 CropCache_back = 8  bytes

T_Sprite3: 
	dc.b $50,$50	;0 XY
	dc.b $20,$14	;2 WH
	dc.l tileChibiko2	;4 TilemapHL
	dc.l PatternData  ;6 PatternHL
	ds.b 16		;12	CropCache = 10 bytes
	ds.b 12		;28 CropCache_back = 8  bytes
T_Sprite4: 
	dc.b $80,$40	;0 XY
	dc.b $20,$14	;2 WH
	dc.l tileChibiko3	;4 TilemapHL
	dc.l PatternData  ;6 PatternHL
	ds.b 16		;12	CropCache = 10 bytes
	ds.b 12		;28 CropCache_back = 8  bytes
T_Sprites_End:	
		
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
		
waitVBlank:
	move.l ($DFF004),d0		;VPOSR - Read vert most signif. bit (and frame flop)
	and.l #$1ff00,d0
	cmp.l #$12C00,d0		;Test to see if we're in Vblank
	bne waitVBlank
VblankDone:		
	rts
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
	ifd AllowShifted
		include "SrcAST/AST_V1_MaxTile_Shifted.asm"
		include "SrcAST/AST_V1_MaxTile_Shifted2.asm"
		include "SrcAST/AST_V1_SpeedTile_ClearBorder.asm"
	endif
	
	include "SrcAST/AST_V1_MaxTile_Normal.asm"
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
	ifd DoubleBuffered
		include "SrcAll/V1_MaxTile_DirectDriver.asm"
	else
		include "SrcAll/V1_MaxTile_CacheDriver.asm"
	endif 

 	include "SrcAll/V1_MaxTile.asm"

	include "MaxTile_Test2.asm"

	include "SrcAll/V1_MaxTile_Expanders.asm"

 	include "SrcAll/BasicFunctions.asm"

	
PatternFill:
	dc.b $00,$00,$00,$00	;4 bytes per tile
	dc.b $00,$00,$00,$FF
	dc.b $00,$00,$FF,$00
	dc.b $00,$00,$FF,$FF
	dc.b $00,$FF,$00,$00
	dc.b $00,$FF,$00,$FF
	dc.b $00,$FF,$FF,$00
	
	align 12
PatternData:				;32 bytes per tile
	incbin "\ResALL\Yquest\AST_YQuest.RAW"
	align 12
	incbin "\ResALL\SpeedTiles\Chibiko2TilesAST.RAW"
	align 12
	incbin "\ResALL\ChibiFighter\AMI_Yarita.RAW"
	
	
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
	
