

	include "srcall/BasicMacros.asm"

AllowShifted equ 1			;Allow Partial shifts

ScreenBase equ screen_mem+4
	
;DoubleBuffered equ 1		;Disable caches
						
CacheAddr1 equ MaxTileData+$0000	;Cache for top 1/3rd (512 bytes)
CacheAddr2 equ MaxTileData+$0200	;Cache for middle 1/3rd (512 bytes)
CacheAddr3 equ MaxTileData+$0400	;Cache for bottom 1/3rd (512 bytes)


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

FlipMode equ CacheTableAddr+4	;db 0 	
HspriteNum equ FlipMode+2	;db 0 	

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

VscreenMinX equ 64		;Top left of visible screen in logical co-ordinates
VscreenMinY equ 80

VscreenWid equ 128		;Visible Screen Size in logical units
VscreenHei equ 96
	
VscreenWidClip equ 3	;alter right boundary due to working in words
VscreenHeiClip equ 3

BackgroundTilemapWidthV equ 36	;Screen width in tiles (32+4 for scroll)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	


DMACON  EQU $dff096 ;DMA control write (clear or set)
DMACONR  EQU $dff002 

INTENA  EQU $dff09a ;Interrupt enable bits (clear or set bits)
BPLCON0 EQU $dff100 ;Bitplane control register (misc. control bits)
BPLCON1 EQU $dff102 ;Bitplane control reg. (scroll value PF1, PF2)
BPL1MOD EQU $dff108 ;Bitplane modulo (odd planes)
BPL2MOD EQU $dff10a ;Bitplane modulo (even planes)
DIWSTRT EQU $dff08e ;Display window start (upper left vert-horiz position)
DIWSTOP EQU $dff090 ;Display window stop (lower right vert.-horiz. Position)
DDFSTRT EQU $dff092 ;Display bitplane data fetch start (horiz. Position)
DDFSTOP EQU $dff094 ;Display bitplane data fetch stop (horiz. position)
COP1LCH EQU $dff080	;Coprocessor first location register (high 3 bits, high 5 bits if ECS)
;--Bz--P-- --------

;Blitter hardware
	
BLTCON0 equ $DFF040	;Blitter control register 0 
BLTCON1 equ $DFF042	;Blitter control register 1

BLTAFWM equ $DFF044	;First Word Mask for A
BLTALWM equ $DFF046	;Last Word Mask for A

BLTCPTH equ $DFF048 ;Address C H
BLTCPTL equ $DFF04A ;Address C L

BLTBPTH equ $DFF04C ;Address B H
BLTBPTL equ $DFF04E ;Address B L

BLTAPTH equ $DFF050 ;Address A H
BLTAPTL equ $DFF052 ;Address A L

BLTDPTH equ $DFF054 ;Address D H
BLTDPTL equ $DFF056 ;Address D L

BLTSIZE equ $DFF058 ;Size of area + START!

BLTCMOD equ $DFF060 ;Modulo C
BLTBMOD equ $DFF062 ;Modulo B
BLTAMOD equ $DFF064 ;Modulo A
BLTDMOD equ $DFF066 ;Modulo D
	
	
	SECTION TEXT		;CODE Section
	
	
			;Enable the screen display
	
	move.l	#gfxname,a1 	;'graphics.library' defined in chip ram
	moveq.l	#0,d0
	move.l	$4,a6
	jsr	(-552,a6)			;Exec - Openlibrary
	
	move.l	d0,gfxbase
	move.l 	d0,a6
	move.l #0,a1			;Null view
	jsr (-222,a6)			;LoadView - Use a (possibly freshly created) coprocessor 
							;	instruction list to create the current display.
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;Start defining our screen layout
	
; 		      FEDCBA9876543210
; 			  RPPPHDCG----PIE-	 		;four bitPlanes (16 color) Color on
	move.w	#%0100001000000000,BPLCON0	;Bitplane control register (misc. control bits)
	
	move.w	#$0000,BPLCON1				;Horizontal scroll 0 - Bitplane control reg. (scroll value PF1, PF2)
	
;4 bitplanes 
;40 bytes each - so skip 3 bitplanes (3*40=120) after each line
	move.w	#120,BPL1MOD				;Bitplane modulo (odd planes)
	move.w	#120,BPL2MOD				;Bitplane modulo (even planes)
	
	
	move.w	#$2c81,DIWSTRT				;Display window start (upper left vert-horiz position)
	move.w	#$F4C1,DIWSTOP				;Display window stop (lower right vert.-horiz. Position)
	move.w	#$0038,DDFSTRT				;Display bitplane data fetch start (horiz. Position)
	move.w	#$00d0,DDFSTOP				;Display bitplane data fetch stop (horiz. position)
		  	; FEDCBA9876543210
			;-------DbCBSDAAAA
	move.w  #%1000000110000000,DMACON   ;DMA set ON  - DMA control (and blitter status) read 
										;	(Bit 15 defines set/clear for other bits)
			;-------DbCBSDAAAA
	move.w 	#%0000000001011111,DMACON	;DMA set OFF - turn off sound
	move.w 	#%1100000000000000,INTENA	;IRQ set ON  - Interrupt enable bits read - Turn on master
	move.w 	#%0011111111111111,INTENA	;IRQ set OFF - Turn off all others

	
	
	
	lea CopperList,a6					;Copperlist (Commands run by Copper Coprocessor) -all addresses start DFFnnn
   ;Entry format:
   ;Change setting:
   ; %0000000n nnnnnnn0 DDDDDDDD DDDDDDDD	nnn= address to Change ($DFFnnn) DDDD=new value to set address
   
   ;wait for pos:
   ; $VVVVVVVV HHHHHHH1 1vvvvvvv hhhhhhh0   V=Vops H=Hpos v= Vpos Compare enable  h=hpos compare enable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   
   ;Define Memory layout
   ;4 bitplanes are interleaved on concecutive Y lines 
   
	;Send the address of each bitplane in two parts
	move.l #Screen_Mem+(40*0),d0	;Bitplane 0
	move.w #$00e2,(a6)+			;Bitplane 0 pointer (low 15 bits)
	move.w d0,(a6)+		
	swap d0
	move.w #$00e0,(a6)+			;Bitplane 0 pointer (high 3 bits)
	move.w d0,(a6)+		
	
	move.l #Screen_Mem+(40*1),d0	;Bitplane 1
	move.w #$00e6,(a6)+			;Bitplane 1 pointer (low 15 bits)
	move.w d0,(a6)+		
	swap d0
	move.w #$00e4,(a6)+			;Bitplane 1 pointer (high 3 bits)
	move.w d0,(a6)+		

	move.l #Screen_Mem+(40*2),d0	;Bitplane 2
	move.w #$00ea,(a6)+			;Bitplane 2 pointer (low 15 bits)
	move.w d0,(a6)+		
	swap d0
	move.w #$00e8,(a6)+			;Bitplane 2 pointer (low 15 bits)
	move.w d0,(a6)+		
	
	move.l #Screen_Mem+(40*3),d0	;Bitplane 3
	move.w #$00eE,(a6)+			;Bitplane 3 pointer (low 15 bits)
	move.w d0,(a6)+		
	swap d0
	move.w #$00eC,(a6)+			;Bitplane 3 pointer (high 3 bits)
	move.w d0,(a6)+		

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	move.l a6,(a1)			;the copperlist into our pointer for easy changing
	       ; AAAA-RGB		;Address - RGB
    move.l #$01800000,(a6)+ ;0  -RGB
    move.l #$0182080F,(a6)+ ;1  -RGB
    move.l #$018400FF,(a6)+ ;2  -RGB
    move.l #$01860FFF,(a6)+ ;3  -RGB
    move.l #$01880008,(a6)+ ;4  -RGB
    move.l #$018A0808,(a6)+ ;5  -RGB
    move.l #$018C0088,(a6)+ ;6  -RGB
    move.l #$018E0CCC,(a6)+ ;7  -RGB
    move.l #$01900888,(a6)+ ;8  -RGB
    move.l #$01920F00,(a6)+ ;9  -RGB
    move.l #$019400F0,(a6)+ ;10  -RGB
    move.l #$01960FF0,(a6)+ ;11  -RGB
    move.l #$0198000F,(a6)+ ;12  -RGB
    move.l #$019A0F0F,(a6)+ ;13  -RGB
    move.l #$019C00FF,(a6)+ ;14  -RGB
    move.l #$019E0FFF,(a6)+ ;15  -RGB
    move.l #$01A00000,(a6)+ ;16  -RGB
    move.l #$01A20000,(a6)+ ;17  -RGB
    move.l #$01A40111,(a6)+ ;18  -RGB
    move.l #$01A60111,(a6)+ ;19  -RGB
    move.l #$01A80222,(a6)+ ;20  -RGB
    move.l #$01AA0222,(a6)+ ;21  -RGB
    move.l #$01AC0333,(a6)+ ;22  -RGB
    move.l #$01AE0333,(a6)+ ;23  -RGB
    move.l #$01B00444,(a6)+ ;24  -RGB
    move.l #$01B20444,(a6)+ ;25  -RGB
    move.l #$01B40555,(a6)+ ;26  -RGB
    move.l #$01B60555,(a6)+ ;27  -RGB
    move.l #$01B80666,(a6)+ ;28  -RGB
    move.l #$01BA0666,(a6)+ ;29  -RGB
    move.l #$01BC0777,(a6)+ ;30  -RGB
    move.l #$01BE0777,(a6)+ ;31  -RGB

	move.l #$fffffffe,(a6)+		; end of copperlist (COPPER_HALT)

	jsr waitVBlank

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

	;Enable Copperlist
	
	lea CopperList,a6	;Enable the CopperList
	move.l a6,COP1LCH 	;Coprocessor first location register (high 3 bits, high 5 bits if ECS)
			 ;COP1LCL	;Coprocessor first location register (low 15 bits)

			 
			 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Enable BLIT DMA		 
	;        FEDCBA9876543210
	;move.w #%1000000001000000,(DMACON)  ;$DFF096 DMACON - DMA control write (clear or set)
										;S-----E- ---DCBA	S=Set/Clr E=enable ABCD=Channnels	
										
										
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
		
	
	;move.l #ScreenBase,a6
	;jsr prepareVram
	;move.w #1,(VDP_data) ;C00000 Select tile for mem loc
	
	
	
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
	
	

	;include "SrcX68/X68_V1_MaxTile_Normal.asm"
		
	
;Addr = ScreenMem + (Ypos * 40) + Xpos
 ;d1=x d4=y - returns screen address in A3

			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
	ifd AllowShifted
		include "SrcAMI/AMI_V1_MaxTile_Shifted.asm"
		include "SrcAMI/AMI_V1_SpeedTile_ClearBorder.asm"
	endif
	include "SrcAMI/AMI_V1_MaxTile_Normal.asm"	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
	
	

	ifd DoubleBuffered
		include "srcall/V1_MaxTile_DirectDriver.asm"
	else
		include "srcall/V1_MaxTile_CacheDriver.asm"
	endif 

 	include "srcall/V1_MaxTile.asm"
	

	include "MaxTile_Test2.asm"

 	include "srcall/BasicFunctions.asm"

PatternFill:
	dc.b $00,$00,$00,$00		;4 bytes per tile
	dc.b $00,$00,$00,$FF
	dc.b $00,$00,$FF,$00
	dc.b $00,$00,$FF,$FF
	dc.b $00,$FF,$00,$00
	dc.b $00,$FF,$00,$FF
	dc.b $00,$FF,$FF,$00
	
	align 12
PatternData:					;32 bytes per tile
	incbin "\ResALL\Yquest\AST_YQuest.RAW"
	align 12
	incbin "\ResALL\SpeedTiles\Chibiko2TilesAST.RAW"
	align 12
	incbin "\ResALL\ChibiFighter\AMI_Yarita.RAW"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
	include "srcall/V1_MaxTile_Expanders.asm"
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	


ReadJoystick:		;Returns: ---7654S321RLDU
	move.b #%00111111,$BFE201	;Direction for port A (BFE001)....0=in 1=out... 
								;(For fire buttons)

	;move.w $dff00A,d2			;Joystick-mouse 0 data (vert,horiz) (Joy2)
	;move.b $bfe001,d5			;/FIR1 /FIR0  /RDY /TK0  /WPRO /CHNG /LED  OVL
	;rol.b #1,d5					;Fire0 for joy 2
		
	move.w $dff00c,d2		;Joystick-mouse 1 data (vert,horiz) (Joy1)
	move.b $bfe001,d5		;/FIR1 /FIR0  /RDY /TK0  /WPRO /CHNG /LED  OVL

Player_ReadControlsOne:	;Translate HV data into joystick values
	clr.l d0	
	clr.l d1
	clr.l d3
	clr.l d4
	
	;Get the 4 bits that are needed for the directions
	roxr.l #1,d2	;bit 0
	roxl.l #1,d3
	roxr.l #1,d2	;bit 1
	roxl.l #1,d4
	roxr.l #7,d2	;bit 8
	roxl.l #1,d0
	and.l #1,d2		;bit 9
	
	;Calculate the new directions
	move.b d2,d1
	eor.b d0,d1
	roxr.b d1
	roxr.b d0		;Up (Bit 9 Xor 8)
	
	move.b d4,d1
	eor.b d3,d1
	roxr.b d1
	roxr.b d0		;Down (Bit 1 Xor 0)
	
	roxr.b d2
	roxr.b d0		;Left (Bit 9)
	roxr.b d4
	roxr.b d0		;Right (Bit 1)
	
	roxl.b d5
	roxr.b d0		;Fire
	
	ror.b #3,d0
	eor.b #%11101111,d0	;Invert UDLR bits
	or.l #$FFFFFF00,d0	;Set unused bits
	rts
	
	

	CNOP 0,4	; Pad with NOP to next 32 bit boundary
gfxname dc.b 'graphics.library',0

	CNOP 0,4	; Pad with NOP to next 32 bit boundary
gfxbase:	dc.l 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	Section ChipRAM,Data_c		;Request memory within the 'Chip Ram' base memory 
								;This is the only ram our screen and copperlist can use
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	CNOP 0,4					;Pad with NOP to next 32 bit boundary
	
	

Screen_Mem:						;This is our screen
	ds.b    320*200*4			;320x200 4 bitplanes (16 color)

	CNOP 0,4					;Pad with NOP to next 32 bit boundary
CopperList:
	dc.l $ffffffe 				;COPPER_HALT - end of list (new list)
	ds.b 1024					;Define 1024 bytes of chip ram for our copperlist

FlipLUT:
	ds.b 256

MaxTileData:
	ds.b 32768
	

	
	