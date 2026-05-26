
ScreenBase equ $c00000+(1024*16)

;PatternDoubleHeight equ 512

;slowdowntest equ 1


;patterndata equ 8
;PatternFill equ 0


;TestChibiko equ 16+1
;TestSprite equ 0


;DoubleBuffered equ 1
						
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



BackgroundTilemapWidthV equ 36




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
	
	
	jmp RunTest1
	
		
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	


	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
GetScreenPos: 					;d1=x d2=y (in pairs of pixels)
	moveM.l d0-d7,-(sp)
		and.l #$FF,d1
		and.l #$FF,d4
		
		asl.l #2,d1				;2 bytes per pixel
		move.l d1,a3
		
		rol.l #8,d4				;1024 bytes per Y line 
		rol.l #3,d4
		add.l d4,a3
		
		add.l #$c00000+(1024*16),a3	;Graphics Vram – Page 0
	moveM.l (sp)+,d0-d7
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
	include "SrcX68/X68_V1_MaxTile_Normal.asm"
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	

	ifd DoubleBuffered
		include "SrcAll/V1_MaxTile_DirectDriver.asm"
	else
		include "SrcAll/V1_MaxTile_CacheDriver.asm"
	endif 

 	include "SrcAll/V1_MaxTile.asm"

	include "MaxTile_Test1.asm"

 	include "SrcAll/BasicFunctions.asm"

	
patterndata:
TestSprite:
	incbin "\ResALL\Yquest\MSX2_Yquest.raw"
TestChibiko:
	incbin "\ResALL\SpeedTiles\Chibiko2TilesSAM.RAW"

PatternFill:
	dc.b $00,$00
	dc.b $11,$11
	dc.b $22,$22
	dc.b $22,$33
	dc.b $33,$33
	dc.b $44,$44
	dc.b $55,$55
	dc.b $66,$66
	
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
	
	