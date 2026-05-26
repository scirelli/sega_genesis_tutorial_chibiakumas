
ScreenBase equ $c00000+(1024*16)	;VRAM destination for full redraw
						
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

BackgroundTilemapWidthV equ 36	;Screen width in tiles (32+4 for scroll)

allowquartertilescroll equ 1
allowhalftilescroll equ 1

hiresx equ 1
hiresy equ 1

;Logical units are pairs of pixels

VscreenMinX equ 64		;Top left of visible screen in logical co-ordinates
VscreenMinY equ 80

VscreenWid equ 128		;Visible Screen Size in logical units
VscreenHei equ 96
	
VscreenWidClip equ 2	;alter right boundary due to working in words
VscreenHeiClip equ 3

tileChibiko3 equ MaxTileData+$1000
tileChibiko2 equ tileChibiko3+80
tilePlayer equ tileChibiko2+80
tileChibiko equ tilePlayer+80

Sprite1 equ MaxTileData+$2000
Sprite2 equ Sprite1+40
Sprite3 equ Sprite2+40
Sprite4 equ Sprite3+40





	include "SrcAll/BasicMacros.asm"
		


			;		 FEDCBA9876543210	
			move.w #%0000000000000000,$e80028 ;R20 Memory mode/Display mode control
			move.w #%0000000000000000,$e82400 ;R0 (Screen mode initialization) - Detail
			;		 --SSTTGG44332211
			move.w #%0000001011100100,$e82500 ;R1 (Priority control) - Priority
			;		 FEDCBA9876543210	
			;				  ST43210		
			move.w #%0000000011000001,$e82600 ;R2 (Special priority/screen display) - Screen On - sprites on
			
			move.w #$025,$E80000 	;R00 Horizontal total 
			move.w #$001,$E80002	;R01 Horizontal synchronization end position timing
			move.w #$000,$E80004	;R02 Horizontal display start position
			move.w #$020,$E80006	;R03 Horizontal display end position
			move.w #$103,$E80008	;R04 Vertical total 
			move.w #$002,$E8000A	;R05 Vertical synchronization end position timing
			move.w #$010,$E8000C	;R06 Vertical display start position
			move.w #$100,$E8000E	;R07 Vertical display end position	
			move.w #$024,$E80010	;R08 External synchronization horizontal adjust: Horizontal position tuning
			
			;move.w #$25,$EB080A		; Sprite H Total
			;move.w #$04,$EB080C		; Sprite H Disp
			;move.w #$10,$EB080E		; Sprite V Disp
			;move.w #$00,$EB0810		; Sprite Res %---FVVHH

;Palette	
			;GGGGGRRRRRBBBBB- 5 bit per channel
	move.w #%0000000000000000,$e82000	;Color 0
	move.w #%0000001110011100,$e82002	;Color 1
	move.w #%1111100000111110,$e82004	;Color 2
	move.w #%1111111111111110,$e82006	;Color 3



	
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
	

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
	include "SrcX68/X68_V1_MaxTile_Normal.asm"
	include "SrcX68/x68_V1_SpeedTile_ClearBorder.asm"
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	

	ifd DoubleBuffered
		include "SrcAll/V1_MaxTile_DirectDriver.asm"
	else
		include "SrcAll/V1_MaxTile_CacheDriver.asm"
	endif 

 	include "SrcAll/V1_MaxTile.asm"

	include "MaxTile_Test2.asm"

 	include "SrcAll/BasicFunctions.asm"
	include "SrcAll/V1_MaxTile_Expanders.asm"

	
PatternFill:
	dc.b $00,$00	;2 bytes per tile (one per line)
	dc.b $11,$11
	dc.b $22,$22
	dc.b $22,$33
	dc.b $33,$33
	dc.b $44,$44
	dc.b $55,$55
	dc.b $66,$66
	
	align 12	;32 bytes per tile
patterndata:
	incbin "\ResALL\Yquest\MSX2_Yquest.RAW"
	align 12
	incbin "\ResALL\SpeedTiles\Chibiko2TilesSAM.RAW"
	align 12
	incbin "\ResALL\ChibiFighter\GEN_Yarita.RAW"

	
		align 4
MaxTileData:
	ds.b 32768


ReadJoystick:		;Returns: ---7654S321RLDU

	;move.l #$E9A003,a0			;Select Joystick # 2
	move.l #$E9A001,a0		;Select Joystick # 1
	
JoystickProcessOne:			;Returns: ---7654S321RLDU
	clr.l d0
	
;	         76543210
	move.b #%00000000,$E9A005	;8255 Port C (Default Controls)
	move.b (a0),d1				;-21-RLDU
	roxr.b d1
	roxr.b d0	;U
	roxr.b d1
	roxr.b d0	;D
	roxr.b d1
	roxr.b d0	;L
	roxr.b d1
	roxr.b d0	;R
	roxr.b #2,d1				;skip -
	
	roxr.b d0	;F1
	roxr.b d1
	roxr.b d0	;F2
	
	;	     76543210
	move.b #%00110000,$E9A005	;8255 Port C (Get Extra Controls)
	move.b (a0),d1				;-S3-M654 ?
	move.b d1,d3
	roxr.b #6,d1				;-------S 3	
	roxr.b d0	;F3
	roxr.b d1
	roxr.b d0	;Start
	
	and.l #$0000000F,d3			;____M654
	rol.l #8,d3
	
	or.l d3,d0
	or.l #$FFFFF000,d0
KeyboardScanner_AllowJoysticks:

	rts	
	