

	include "srcall/BasicMacros.asm"

ScreenBase equ $00020000+(128*32)


PatternDoubleHeight equ 512

;slowdowntest equ 1


;patterndata equ 8
;PatternFill equ 0


;TestChibiko equ 16+1
;TestSprite equ 0

UserRam equ $38000		;Don't try this at home! may corrupt part of the OS if we're unlucky

MaxTileData equ UserRam+$200

;tiletest_basiconly equ 1
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


		

SqlProgbase equ $30000
	org SqlProgbase

QlProg_Start:
	
	Trap #0						;Supervisor mode
	ori #0700,sr				;Disable interrupts
	
		move.b #%00001000,$18063	;Force 8 color mode!
	
		lea QlProg_Start,a1
		move.l #SqlProgbase,a0
		move.l #QlProg_End-QlProg_Start,d0
QlProg_CopyAgain:	
		move.b (a1)+,(a0)+
		dbra d0,QlProg_CopyAgain
		

		jmp (SqlProgbase+(QlProg_Run-QlProg_Start))
QlProg_Run:	

	;move.l #$00039000,sp
	move.l #UserRam,sp	;Set up stack pointer
	
	
	
;Build our X-flip LUT

	move.l #FlipLUT,a0		;256 byte Lookup Table
	clr.b d1				;Byte to flip
FillLut:
	
	move.b d1,d0
	and.b #%00000011,d0		;---D
	rol.b #6,d0				;D---
	move.b d0,d2
	
	move.b d1,d0	
	and.b #%00001100,d0		;--C-
	rol.b #2,d0				;-C--
	or.b d0,d2
	
	move.b d1,d0
	and.b #%00110000,d0		;-B--
	ror.b #2,d0				;--B-
	or.b d0,d2			
	
	move.b d1,d0
	and.b #%11000000,d0		;A---
	ror.b #6,d0				;---A
	or.b d0,d2
	move.b d2,(a0)+			
	
	addq.b #1,d1
	bne FillLut				;Repeat for all 256


	
	
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
	
		

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	


QLJoycommand:
	dc.b $09	;0 - Command
	dc.b $01	;1 - parameter bytes
	dc.l 0		;2345 - send option (%00=low nibble)
	dc.b 1		;6 - Parameter: Row
	dc.b 2		;7 - length of reply (%10=8 bits)
	even
	
ReadJoystick:
	
	
		 lea QLJoycommand,a3
		 move.b #$11,d0	;Command 17
		 Trap #1		;Send Keyrequest to the IO CPU
						;Returns row in D1
		
		clr.l d0		;D0 is our result
		
		move.b d1,d2
		roxr.b #4,d2	; ESC
		roxl.b #1,d0	;Start (4)
		
		roxr.b #2,d2	; \ 
		roxl.b #1,d0	;Fire 3 (6)
		
		move.b d1,d2
		roxr.b #1,d2	; Enter (1)
		roxl.b #1,d0	;Fire 2
		
		roxr.b #6,d2	;Space (7)
		roxl.b #1,d0
		
		move.b d1,d2
		roxr.b #5,d2	;Right (5)
		roxl.b #1,d0
		
		move.b d1,d2
		roxr.b #2,d2	;Left (2)
		roxl.b #1,d0
		
		roxr.b #6,d2	;Down (8)
		roxl.b #1,d0
		
		move.b d1,d2
		roxr.b #3,d2	;Up   (3)
		roxl.b #1,d0
		
		eor.b #$FF,d0		;Flip Player 1 bits
		rts
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

	
	

	ifd DoubleBuffered
		include "srcall/V1_MaxTile_DirectDriver.asm"
	else
		include "srcall/V1_MaxTile_CacheDriver.asm"
	endif 

 	include "srcall/V1_MaxTile.asm"

	include "MaxTile_Test1.asm"

 	include "srcall/BasicFunctions.asm"

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
	include "SrcSQL/SQL_V1_MaxTile_Normal.asm"
	
FlipLUT:		;bottom byte of address must be $????00-???FF
	ds.b 256
	
patterndata:
TestSprite:
	ds.b 32
	incbin "\ResALL\Yquest\SQL_YQuest.RAW"
TestChibiko:
	incbin "\ResALL\SpeedTiles\Chibiko2TilesSQL.RAW"

	

PatternFill:
		; GFGFGFGF  RBRBRBRB  GFGFGFGF  RBRBRBRB
	dc.b %00000000,%00000000,%00000000,%00000000
	dc.b %10101010,%00000000,%00000000,%00000000
	dc.b %10001000,%00000000,%00100010,%00000000
	dc.b %00000000,%10001000,%00000000,%00010001
	dc.b %00000000,%11111111,%00000000,%11111111
	dc.b %10001000,%11111111,%00100010,%11111111	
	even


QlProg_End: