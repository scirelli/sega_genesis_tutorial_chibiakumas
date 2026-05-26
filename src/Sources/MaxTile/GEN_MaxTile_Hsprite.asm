
patterndata equ 8				;Tile offset for normal tiles
PatternFill equ 0				;Tile offset for fill tiles
PatternDoubleHeight equ 512		;Tile offset for DoubleHeight Tiles

ScreenBase equ $C000+8+(64*4)	;Tilemap base VRAM address

DoubleBuffered equ 1		;Draw background even if overlapped by sprite
						
CacheAddr1 equ $00FF0000
CacheAddr2 equ $00FF0200
CacheAddr3 equ $00FF0400

CacheTable equ $00FF0600
	ifnd DoubleBuffered
CacheTable_Last equ T_CacheTable_Last-T_CacheTable +CacheTable
CacheTable_End equ T_CacheTable_End-T_CacheTable +CacheTable
	endif
	
Vline equ CacheTable+32;  db 0		;For Screen Draw Sync to crt line
CropYH	equ Vline+1;: dw 0
CropXW equ CropYH+2 ;: dw 0

BackgroundTilemapBase equ CropXW+2;: dw BackgroundTilemap2+2
BackgroundTilemapWidth equ BackgroundTilemapBase+4;:	db 36*2
BackgroundTilemapScrollX equ BackgroundTilemapWidth+1;: db 0
BackgroundTilemapScrollY equ BackgroundTilemapScrollX+1;: db 0
TileTmpW equ BackgroundTilemapScrollY+1 ;: dw 0
SPrestore equ TileTmpW+2
CacheTableAddr equ  SPrestore+2 ;: dw CacheTable
FlipMode equ CacheTableAddr+4	;db 0 	

HspriteNum equ FlipMode+2	;Counter for hardware sprites.

BackgroundTilemap2 equ $00FF0800	;36*28*2+4

tileChibiko3 equ $00FF1000
tileChibiko2 equ tileChibiko3+80
tilePlayer equ tileChibiko2+80
tileChibiko equ tilePlayer+80

Sprite1 equ $00FF2000
Sprite2 equ Sprite1+40
Sprite3 equ Sprite2+40
Sprite4 equ Sprite3+40

;Logical units are pairs of pixels
VscreenMinX equ 64		;Top left of visible screen in logical co-ordinates
VscreenMinY equ 80

VscreenWid equ 128		;Visible Screen Size in logical units
VscreenHei equ 96

VscreenWidClip equ 2	;alter right boundary due to working in words
VscreenHeiClip equ 0

BackgroundTilemapWidthV equ 36	;Width in tiles.


	include "SrcAll/BasicMacros.asm"
		

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

;Video Ports
VDP_data	EQU	$C00000	; VDP data, R/W word or longword access only
VDP_ctrl	EQU	$C00004	; VDP control, word or longword writes only

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 					Traps
	DC.L	$FFFFFE00		;SP register value
	DC.L	ProgramStart	;Start of Program Code
	DS.L	7,IntReturn		; bus err,addr err,illegal inst,divzero,CHK,TRAPV,priv viol
	DC.L	IntReturn		; TRACE
	DC.L	IntReturn		; Line A (1010) emulator
	DC.L	IntReturn		; Line F (1111) emulator
	DS.L	4,IntReturn		; Reserverd /Coprocessor/Format err/ Uninit Interrupt
	DS.L	8,IntReturn		; Reserved
	DC.L	IntReturn		; spurious interrupt
	DC.L	IntReturn		; IRQ level 1
	DC.L	IntReturn		; IRQ level 2 EXT
	DC.L	IntReturn		; IRQ level 3
	DC.L	IntReturn		; IRQ level 4 Hsync
	DC.L	IntReturn		; IRQ level 5
	DC.L	IntReturn		; IRQ level 6 Vsync
	DC.L	IntReturn		; IRQ level 7 
	DS.L	16,IntReturn	; TRAPs
	DS.L	16,IntReturn	; Misc (FP/MMU)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					Header
	DC.B	"SEGA GENESIS    "	;System Name
	DC.B	"(C)CHBI "			;Copyright
 	DC.B	"2019.JAN"			;Date
	DC.B	"ChibiAkumas.com                                 " ; Cart Name
	DC.B	"ChibiAkumas.com                                 " ; Cart Name (Alt)
	DC.B	"GM CHIBI001-00"	;TT NNNNNNNN-RR T=Type (GM=Game) N=game Num  R=Revision
	DC.W	$0000				;16-bit Checksum (Address $000200+)
	DC.B	"J               "	;Control Data (J=3button K=Keyboard 6=6button C=cdrom)
	DC.L	$00000000			;ROM Start
	DC.L	$003FFFFF			;ROM Length
	DC.L	$00FF0000,$00FFFFFF	;RAM start/end (fixed)
	DC.B	"            "		;External RAM Data
	DC.B	"            "		;Modem Data
	DC.B	"                                        " ;MEMO
	DC.B	"JUE             "	;Regions Allowed

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					Generic Interrupt Handler
IntReturn:
	rte
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					Program Start
ProgramStart:
	;initialize TMSS (TradeMark Security System)
	move.b ($A10001),D0		;A10001 test the hardware version
	and.b #$0F,D0
	beq	NoTmss				;branch if no TMSS chip
	move.l #'SEGA',($A14000);A14000 disable TMSS 
NoTmss:


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					Set Up Graphics

	lea VDPSettings,A5		;Initialize Screen Registers
	move.l #VDPSettingsEnd-VDPSettings,D1 ;length of Settings
	
	move.w (VDP_ctrl),D0	;C00004 read VDP status (interrupt acknowledge?)
	move.l #$00008000,d5	;VDP Reg command (%8rvv)
	
NextInitByte:
	move.b (A5)+,D5			;get next video control byte
	move.w D5,(VDP_ctrl)	;C00004 send write register command to VDP
		;   8RVV - R=Reg V=Value
	add.w #$0100,D5			;point to next VDP register
	dbra D1,NextInitByte	;loop for rest of block


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					Set up palette
	
;Define palette
	lea Palette,a1
	move.l #16,d1
	move.l #$C0000000,d0		;Color 0
PaletteAgain:	
	move.l d0,(VDP_Ctrl)
	move.w (a1)+,(VDP_data)		;----BBB-GGG-RRR-
	add.l #$00020000,d0
	dbra d1,PaletteAgain

;Turn on screen	
	
	move.w	#$8144,(VDP_Ctrl)	;C00004 reg 1 = 0x44 unblank display
	
;Define our patterns in VRAM
	
	move.l #Bitmap,a0					;Source data
	move.w #(Bitmap_End-Bitmap)/4,d1	;Bytecount
	move.l #patterndata*32,a6					;Dest VRAM 32 bytes per tile
	jsr DefineTiles					;Send pattern data
	
	add.l #PatternDoubleHeight*32,a6
	
	
	jsr DefineTilesDouble
	
	
	move.l #PatternFill*32,a6
	move.l #FillData,a0
	move.l #8,d1			;Fillcount
	jsr DefineTilesFills
	
		
	; move.l #xChibicloneDef,a1
	; move.l #ChibicloneDef,a2
	; move.l #64-1,d0
; CopyAgain:
	; move.b (a1)+,(a2)+
	; dbra d0,CopyAgain
	

	
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
	
	
	; move.l #ScreenBase,a6
	; jsr prepareVram
	; move.w #1,(VDP_data) ;C00000 Select tile for mem loc
	

	
	
	jmp RunTest2
	
; Spr_XY equ 0
; Spr_WH equ 2
; Spr_TilemapHL equ 4
; Spr_PatternHL equ 8
; Spr_CropCache equ 12
; Spr_CropCache_Back equ 12+16	
	
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
	

	
	
ReadJoystick:		;D0=1up D1=2up ---7654S321RLDU
	
	;move.b #%01000000,($A1000B)	; Set direction IOIIIIII (I=In O=Out)
	;move.l #$A10005,a0			;RW port for player 2
	;jsr Player_ReadOne			;Read buttons
	
	;move.l d0,-(sp)
		move.b #%01000000,($A10009)	; Set direction IOIIIIII (I=In O=Out)
		move.l #$A10003,a0		;RW port for player 1
		jsr Player_ReadOne		;Read buttons
	;move.l (sp)+,d1
	rts
	
Player_ReadOne:			;Read in and reformat a players buttons
	move.b  #$40,(a0)	; TH = 1
	nop		;Delay
	nop
	move.b  (a0),d2		; d0.b = --CBRLDU	Store in D2
	
	move.b	#$0,(a0)	; TH = 0
	nop		;Delay
	nop
	move.b	(a0),d1		; d1.b = --SA--DU	Store in D1
	
	move.b  #$40,(a0)	; TH = 1
	nop		;Delay
	nop
	move.b	#$0,(a0)	; TH = 0
	nop		;Delay
	nop
	move.b  #$40,(a0)	; TH = 1
	nop		;Delay
	nop
	
	move.b	(a0),d3		; d1.b = --CBXYZM	Store in D3
	move.b	#$0,(a0)	; TH = 0
	
	clr.l d0			;Clear buildup byte
	roxr.b d2
	roxr.b d0			;U
	roxr.b d2
	roxr.b d0			;D
	roxr.b d2
	roxr.b d0			;L
	roxr.b d2
	roxr.b d0			;R
	roxr.b #5,d1
	roxr.b d0			;A
	roxr.b d2
	roxr.b d0			;B
	roxr.b d2
	roxr.b d0			;C
	roxr.b d1
	roxr.b d0			;S
	
	move.l d3,d1
	roxl.l #7,d1		;XYZ
	and.l #%0000011100000000,d1
	or.l d1,d0			
	
	move.l d3,d1
	roxl.l #8,d1		;M
	roxl.l #3,d1		
	and.l #%0000100000000000,d1
	or.l d1,d0
	
	or.l #$FFFFF000,d0	;Set unused bits to 1
	rts
	

	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	

	
waitVBlank:
	move.l ($DFF004),d0		;VPOSR - Read vert most signif. bit (and frame flop)
	and.l #$1ff00,d0
	cmp.l #$12C00,d0		;Test to see if we're in Vblank
	bne waitVBlank
VblankDone:		
	rts

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
				
prepareVram:	;To select a memory location D2 we need to calculate 
				;the command byte... depending on the memory location
				;$7FFF0003 = Vram $FFFF.... $40000000=Vram $0000
	move.l a6,d0
	and.w #%1100000000000000,d0	;Shift the top two bits to the far right 
	rol.w #2,d0
	
	move.l a6,d6
	and.l #%0011111111111111,d6	;shift all the other bits left two bytes
	rol.l #8,d6	
	rol.l #8,d6
	
	or.l d0,d6						
	or.l #$40000000,d6	;Set the second bit from the top to 1
						;#%01000000 00000000 00000000 00000000
	move.l d6,(VDP_ctrl) ;$C00004	VDP control, word or longword writes only
	rts
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	

;Tile Addr: VRAM Addr = $C000 + (Ypos * 64* 2) + (Xpos *2)

;d1=x d4=y (in pairs of pixels)
;returns screen address in A3

			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
	
 	;include "SrcAll/V1_MinimalTile.asm"

	include "SrcAll/V1_MaxTile_HspriteDriver.asm"
	
	ifd DoubleBuffered
		include "SrcAll/V1_MaxTile_DirectDriver.asm"
	else
		include "SrcAll/V1_MaxTile_CacheDriver.asm"
	endif 


	
	;read "\SrcMSX\MSX1_V1_MaxTile_Normal.asm"
	;ifd HiresY
;		read "\SrcCPC\CPC_V1_MaxTile_HalfShift.asm";
	;endif
	include "SrcAll/V1_MaxTile_Expanders.asm"

 	include "SrcAll/V1_MaxTile.asm"

	
	
	
	
	
	
	include "SrcGEN/Gen_V1_MaxTile_Hsprite.asm"
	include "SrcGEN/Gen_V1_MaxTile_Normal.asm"
	
	
	
 	include "SrcAll/BasicFunctions.asm"

	include "MaxTile_Test2.asm"



	
Palette:	
    dc.w %0000000000000000; ;0  %----BBB-GGG-RRR-
    dc.w %0000111000001000; ;1  %----BBB-GGG-RRR-
    dc.w %0000111011100000; ;2  %----BBB-GGG-RRR-
    dc.w %0000111011101110; ;3  %----BBB-GGG-RRR-
    dc.w %0000100000000000; ;4  %----BBB-GGG-RRR-
    dc.w %0000100000001000; ;5  %----BBB-GGG-RRR-
    dc.w %0000100010000000; ;6  %----BBB-GGG-RRR-
    dc.w %0000110011001100; ;7  %----BBB-GGG-RRR-
    dc.w %0000100010001000; ;8  %----BBB-GGG-RRR-
    dc.w %0000000000001110; ;9  %----BBB-GGG-RRR-
    dc.w %0000000011100000; ;10  %----BBB-GGG-RRR-
    dc.w %0000000011101110; ;11  %----BBB-GGG-RRR-
    dc.w %0000111000000000; ;12  %----BBB-GGG-RRR-
    dc.w %0000111000001110; ;13  %----BBB-GGG-RRR-
    dc.w %0000111011100000; ;14  %----BBB-GGG-RRR-
    dc.w %0000111011101110; ;15  %----BBB-GGG-RRR-
	
	
	
	
VDPSettings:
	DC.B $04 ; 0 mode register 1											---H-1M-
	DC.B $04 ; 1 mode register 2											-DVdP---
	DC.B $30 ; 2 name table base for scroll A (A=top 3 bits)				--AAA--- = $C000
	DC.B $3C ; 3 name table base for window (A=top 4 bits / 5 in H40 Mode)	--AAAAA- = $F000
	DC.B $07 ; 4 name table base for scroll B (A=top 3 bits)				-----AAA = $E000
	DC.B $6C ; 5 sprite attribute table base (A=top 7 bits / 6 in H40)		-AAAAAAA = $D800
	DC.B $00 ; 6 unused register											--------
	DC.B $00 ; 7 background color (P=Palette C=Color)						--PPCCCC
	DC.B $00 ; 8 unused register											--------
	DC.B $00 ; 9 unused register											--------
	DC.B $FF ;10 H interrupt register (L=Number of lines)					LLLLLLLL
	DC.B $00 ;11 mode register 3											----IVHL
	DC.B $81 ;12 mode register 4 (C bits both1 = H40 Cell)					C---SIIC
	DC.B $37 ;13 H scroll table base (A=Top 6 bits)							--AAAAAA = $FC00
	DC.B $00 ;14 unused register											--------
	DC.B $02 ;15 auto increment (After each Read/Write)						NNNNNNNN
	DC.B $01 ;16 scroll size (Horiz & Vert size of ScrollA & B)				--VV--HH = 64x32 tiles
	DC.B $00 ;17 window H position (D=Direction C=Cells)					D--CCCCC
	DC.B $00 ;18 window V position (D=Direction C=Cells)					D--CCCCC
	DC.B $FF ;19 DMA length count low										LLLLLLLL
	DC.B $FF ;20 DMA length count high										HHHHHHHH
	DC.B $00 ;21 DMA source address low										LLLLLLLL
	DC.B $00 ;22 DMA source address mid										MMMMMMMM
	DC.B $80 ;23 DMA source address high (C=CMD)							CCHHHHHH
VDPSettingsEnd:
	even
	

	align 14		;Patterns (32 bytes per tile)
Bitmap:
	incbin "\ResALL\Yquest\MSX2_Yquest.RAW"
	align 12
	incbin "\ResALL\SpeedTiles\Chibiko2TilesSAM.RAW"
	align 12
	incbin "\ResALL\ChibiFighter\GEN_Yarita.RAW"
Bitmap_End:

FillData:			;2 byte per tile fills
	dc.b $00,$00
	dc.b $11,$11
	dc.b $22,$22
	dc.b $22,$33
	dc.b $33,$33
	dc.b $44,$44
	dc.b $55,$55
	dc.b $66,$66