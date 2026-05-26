
;GEN_BMPscreen equ 1

ChibiVM_16bitAnimatorLinks equ 1



Adv_DisableAutoCLS equ 1

ChibiLife_PetCount equ 4	;14 is limit!!!

NativeSpr_ExtraBytes equ 12	;Bytes skipped after each sprite in the spritearray
NativeSpr_Multiplatform2Bitplane equ 1	;use GB style 2 bitplane / 4 color source data

BackgroundTilemapWidthV equ 32
BackgroundTilemapWidth32 equ 1
DoubleBuffered equ 1		
doubleBuffered_onlychanged equ 1

VscreenWidClip equ 2	;alter right boundary due to working in words
VscreenHeiClip equ 0	



	ifnd DoubleBuffered
CacheTable_Last equ T_CacheTable_Last-T_CacheTable +CacheTable
CacheTable_End equ T_CacheTable_End-T_CacheTable +CacheTable
	endif
Vline equ CacheTable+32;  dc.b 0		;For Screen Draw Sync to crt line
CropYH	equ Vline+2;: dw 0
CropXW equ CropYH+2 ;: dw 0

BackgroundTilemapBase equ CropXW+2;: dw BackgroundTilemap2+2
BackgroundTilemapWidth equ BackgroundTilemapBase+4;:	dc.b 36*2

BackgroundTilemapScrollX equ BackgroundTilemapWidth+1;: dc.b 0
BackgroundTilemapScrollY equ BackgroundTilemapScrollX+1;: dc.b 0

TileTmpW equ BackgroundTilemapScrollY+1 ;: dw 0
SPrestore equ TileTmpW+2
CacheTableAddr equ  SPrestore+2 ;: dw CacheTable
	


sarYPOS equ 0
sarXPOS equ 1
sarSPRI equ 2  ;2+3 16 bit
sarFRAM equ 4
sarANIM equ 5 
sarUNDR equ 6  ;Tile (byte) under sprite
sarCOLL equ 7  ;Collisions (walls/floor)  %DS--MRLDU
				;D=Dying/Angry
				;S=Sad/Not happy 
				;M=NotMoved (Collisions don't need update)
				;RLDU=Direction collision flags
				
sarFICK equ 8  ;Fickle (Time till re-randomiza)
sarRAND equ 9  ;Random seed (used to make decisions)
sarPERC equ 10	;Perseverance (added to fickle)
sarFOOD equ 11	;Food energy (Bloodpack)
sarBORE equ 12	;Bored energy (Toy)
sarSLEE equ 13	;Sleep energy (Coffin)
sarLIFE equ 14	;Life 0=dead
sarMETA equ 15  ;Metabolic rate (Life depletion mask)



VscreenMinX equ 64		;Top left of visible screen in logical co-ordinates
VscreenMinY equ 80

VscreenWid equ 128		;Visible Screen Size in logical units
VscreenHei equ 96

;compile with option: VASM GEN

	include "header.asm"
	
	include "srcall/ChibiVm_InstSet.asm"
	include "srcall/BasicMacros.asm"

	ifd BuildAMI


CacheAddr1 equ $4500
CacheAddr2 equ $4D00
CacheAddr3 equ $4E00
FlipLut equ $3F00
CacheTable equ $3800
MaxTileTilemap equ $4000	;36*28*2+4 (&CE4 ) - loaded to BackgroundTilemapBase
		
		
	
	ifd NativeSpr_Multiplatform2Bitplane
AMI_NativeSprite_PatternOffset equ -1
	endif 
	endif 
	
	
	
	ifd BuildAST

CacheAddr1 equ $4500
CacheAddr2 equ $4D00
CacheAddr3 equ $4E00
FlipLut equ $3F00
CacheTable equ $3800
MaxTileTilemap equ $4000	;36*28*2+4 (&CE4 ) - loaded to BackgroundTilemapBase	
		
	
	ifd NativeSpr_Multiplatform2Bitplane
AST_NativeSprite_PatternOffset equ -1
	endif 
	endif 
	
	ifd BuildSQL

NativeSpr_AltPalette equ 1	
;MaxTile_AltPalette equ 1	
Font_AltPalette equ 1	
	
CacheAddr1 equ VM_RamBase+$4500
CacheAddr2 equ VM_RamBase+$4D00
CacheAddr3 equ VM_RamBase+$4E00
FlipLut equ VM_RamBase+$3F00
CacheTable equ VM_RamBase+$3800
MaxTileTilemap equ VM_RamBase+$4000	;36*28*2+4 (&CE4 ) - loaded to BackgroundTilemapBase

	
	
		ifd NativeSpr_Multiplatform2Bitplane
SQL_NativeSprite_PatternOffset equ -1
		endif 
VM_RamBase equ $30000
VM_HostRam equ $003F000	;Variables for our Emulator
	endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
	ifd BuildNEO
	
	
PatternData equ $28A0
PatternFill equ $1F00
PatternDoubleHeight equ $2000	;offset
	
	
UseHsprite equ 1			;Enable hardware sprites

CacheAddr1 equ VM_RamBase+$4500
CacheAddr2 equ VM_RamBase+$4D00
CacheAddr3 equ VM_RamBase+$4E00
FlipLut equ VM_RamBase+$3F00
CacheTable equ VM_RamBase+$3800
MaxTileTilemap equ VM_RamBase+$5000	;36*28*2+4 (&CE4 ) - loaded to BackgroundTilemapBase

HspriteNum equ FlipLut+256	;db 0 		
	
		ifd NativeSpr_Multiplatform2Bitplane
NEO_NativeSprite_PatternOffset equ $2A00-1
		endif 
		
VM_RamBase equ $100000
VM_HostRam	equ $10FE00	;Variables for our Emulator
NeedReorg equ 1
	endif
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
	ifd BuildGEN

CacheAddr1 equ VM_RamBase+$4500
CacheAddr2 equ VM_RamBase+$4D00
CacheAddr3 equ VM_RamBase+$4E00
FlipLut equ VM_RamBase+$3F00
CacheTable equ VM_RamBase+$3800
MaxTileTilemap equ VM_RamBase+$4000	;36*28*2+4 (&CE4 ) - loaded to BackgroundTilemapBase


	
patterndata equ 8				;Tile offset for normal tiles
;PatternFill equ 0				;Tile offset for fill tiles
;PatternDoubleHeight equ 512		;Tile offset for DoubleHeight Tiles		
GEN_SpritePatternVRAM equ $8000
		ifd NativeSpr_Multiplatform2Bitplane
GEN_NativeSprite_PatternOffset equ 1023
		endif 
VM_RamBase equ $00FF0000
VM_HostRam	equ $00FFFE00	;Variables for our Emulator
NeedReorg equ 1
	endif
	
	ifd BuildX68


CacheAddr1 equ $4500
CacheAddr2 equ $4D00
CacheAddr3 equ $4E00
FlipLut equ $3F00
CacheTable equ $3800
MaxTileTilemap equ $4000	;36*28*2+4 (&CE4 ) - loaded to BackgroundTilemapBase	
	
		ifd NativeSpr_Multiplatform2Bitplane
X68_NativeSprite_PatternOffset equ -1
		endif 
SpritePatternSize equ 128
	endif
	
;	ifd BuildAST
;VM_RamBase equ ramarea+65536	
;VM_HostRam	equ ramarea+$1FE00	;Variables for our Emulator
;SpriteArrayRam equ $300	
;	endif
	
	
VM_ProgLoadAddr equ $400	

	ifnd SpriteArrayRam
	ifd VM_RamBase;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HspriteCount equ VM_RamBase+64
HspriteLimit equ VM_RamBase+65
SpriteArrayRam equ VM_RamBase+$300	
VM_RamBaseB equ VM_RamBase
Timer_TicksOccured equ VM_RamBase+64+32
AnimatorPointers equ VM_RamBase+64+28

	else;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SpriteArrayRam equ $300	

Timer_TicksOccured equ 64+32
AnimatorPointers equ 64+28

NativeSprite_VarsInVMram equ 1

HspriteCount equ 64
HspriteLimit equ 65
;VM_HostRam equ VM_RamBase+$F000
VM_RamBaseB equ 0
	endif;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	endif


	

	
;SpritePatterns equ 0 ;Remap pointer to Hsprites
;SpriteArrayRam equ $300 ;Remap pointer to SpriteArrayRamR

vmAddressRemap_BigEndian equ 1			;Little endian calculations won't work due to relocatable code

	ifnd SpritePatternSize
SpritePatternSize equ 32
	endif

;	ifd BuildAST
;		and.l  #$FFFF0000,(VM_RamBaseAddr)	;Ensure VM ram ends $????0000
;	endif
	ifnd VM_RamBase
		and.l  #$FFFF0000,(VM_RamBaseAddr)	;Ensure VM ram ends $????0000
	endif

	clr.l d2
	clr.l d5
	
	;move.l #testt,a3
	;jsr printseqcp
	
	
;testt:
	;dc.b 'abcdef', 250,3,'gh',250,3,255
	;move.l #HSprites,a3
	;jsr NativeSpr_Init

	;move.l #SpriteArray,a3
	;jsr NativeSpr_DrawArray
	
	;jsr nativespr_hideall
	
	; move.l (vm_rambaseAddr),a3
	; moveq.l #4,d1
	; jsr memdumpadv   ;show memory to screen
	
	; jmp $
	
	;jsr nativespr_hideall
	
	jsr ChibiVM_Init

	
	;move.l #HSprites,a3
	;jsr NativeSpr_Init

	;move.l #$2000,d1
	;move.l d1,(vm_remap_TableAddr)
	
	;move.l #1,a3
	;jsr AddressRemapViaTableHLA3
	
	;ove.l (VM_RamBaseAddr),d6
	;move.l (vm_remap_TableAddr),d7
	
	;jsr Monitor
	
	;jmp $
	;move.l #SpriteArrayRam,a3
	;jsr NativeSpr_DrawArrayReiKou
	
	
	;jsr Monitor_MemDump		;Dump 6 lines from  $00000000
	;dc.l TestProgram
	;dc.w $2
	
	
	
	
	;jsr VM_Run_WithMonitor
	
VM_Run:	
	jsr VM_Tick
	jmp VM_Run
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	even

		
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	include "srcall/V1_NativeSprite.asm"	
	even
	
	
	
	include "../ChibiVM/Multiplatform_MonitorA.asm"
	
	include "sources/ReiKou/Reikou_ALL_MaxTile.asm"
	include "AdventureEngineX_Monitor.asm"
	
	
	include "ChibiVM_AdventureEngineX.asm"	;Must come before  ChibiVM_AdventureEngine.asm
	include "srcall/V1_GenericAnimator.asm"	;Must come before  ChibiVM_AdventureEngine.asm
	include "AdventureEngineX.asm"				;Must come before  ChibiVM_AdventureEngine.asm
	include "ChibiVM_AdventureEngine.asm"
	include "sources/ChibiVM/ChibiVM_Host.asm"

	
	
	
	
	;ifdef DoubleBuffered
		include "srcall/V1_MaxTile_DirectDriver.asm"
	;else
		;read "\SrcAll\V1_MaxTile_CacheDriver.asm"
	;endif 

	
	;read "\SrcAll\V1_MaxTile_Expanders.asm"
 	;read "\SrcAll\V1_MaxTile.asm"

	
	
	
	
vm_causecallfromoutsidevm:		;TODO!!!!!!!!!!!!!!!	
	rts
	
	
	
	;rorg $10000	;Needed for some reason - somethings messing up the next org otherwise
		



	;rorg $10000+VM_ProgLoadAddr
	
	
	ifd NeedReorg 
		rorg $10000
	else 
		align 13
	endif 
VramBase:		
	ds.b VM_ProgLoadAddr
TestProgram:	
	;incbin "\ResAll\ChibiVM\NumberGuess.rom"

	dc.b "!!!!Chibi/VM!!!!"			;Magic key - must be on a $xxxxxx00 boundary
	dc.b "Your product name here          "		;Software Name - 32 bytes

	;rorg $10000+VM_ProgLoadAddr+$30
	dc.b 0			;Header Version
	dc.b %00000011	; config {COpy Vectors to $100}
	dc.b %00111111	;Requirements {adv} {reikou} {maxtile} {QTV} {NS} {memmapper} {ChibiTracks}
	dc.b 0			;Spare
	dc.b 0			;Spare
	dc.b 0			;Cpu Requirements
	dc.b 0			;Ram Requirements
	dc.b 0 			;Vector Requorements {Vblank}
	dc.b 0 			;SysCall Requirements {VmMonitor}{VmControl}{ChipExt}
	dc.b 0 			;SysCall Requirements
	dc.b 0			;ChipExt Requirements ???
	dc.b 0			;ChipExt Requirements ???
	dc.b $11		;Bitmap Modes 0-7 {NS / Maxtile} 0=ZXS 1=CPC 2=GBC 3=SMS 4=SAM 5=VGA 6=GBA 7=RGBA
	dc.b $01		;Bitmap Modes 0-7 {AdvFont / QTV } 0=ZXS 1=CPC 2=GBC 3=SMS 4=SAM 5=VGA 6=GBA 7=RGBA
	dc.b 0			;Bitmap modes (spare)
	dc.b 0			;Bitmap modes (spare)
	
	;rorg $10000+VM_ProgLoadAddr+$40
	dlle $400		;Rom Load Address
	dlle $200		;StackPointer
	dlle $100		;Trap table Ram address (0=none)
	dlle $0000		;Memmap 1
	dlle $4000		;Memmap 2
	dlle $8000		;Memmap 3
	dlle $C000		;Memmap 4

	dc.b 0,0,0,0
	dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	;rorg $10000+VM_ProgLoadAddr+$70
	dlle (vm_traps-TestProgram)	;Vector table (0=none)
	dlle $2000		;Address remap table (0=none)
	dlle 0			;VMAssets (Palette,Font etc)
	dlle 0			;???

	
	;org &800

ProgramLaunch:

	;AdvXCall axMonitor
	;db hltb
	
	
	;dbbw mov16x,r4_imm16,$0014				;Cursorpos for Memdump
	;AdvXCall AxMonitorSetCP
	
	
	; dbbw mov16x,r4_imm16,$0014				;Cursorpos for Memdump
	; AdvXCall AxMonitorSetCP
	
	; dc.b ph6b
		; dbbw mov16x,r2_imm16,$0202
		; AdvXCall axMemDumpCust
		
	; dc.b pl2b
	
	; dbbw mov16x,r4_imm16,$0012
	; dbbw mov16x,r6_imm16,(StatusLine-VramBase)		
	;AdvXCall AxPrintSeqCPBCDE
	;db hltb
	
		
;Init Maxtile 
	dbbw mov16x,r6_imm16,(PatternSourceData-VramBase)
	dbbw mov16x,r2_imm16,(PatternData_End-PatternSourceData)
	MaxTileCall mxMaxTileInit			;INIT Maxtile Engine
	

	
;Copy Default tilemap from ROM to RAM
	dbb SYSi,syscallLoadMultiReg		;This will be better for setting 3+ regs
		dc.b %01111000
		dwwww $0000,$2018,(WorldMap-VramBase),$0040	;XYpos,WidHei,src,SrcTilemapWidth
	MaxTileCall mxMaxTileDrawArea
	
	;MaxTileCall mxMaxTileRedraw+regNO	;Redraw MaxTile Screen
	
	
	
;Init the animator scripts
	dbbw mov16x,r6_imm16,(MyAnimators-VramBase)	;Init animator scripts
	AnimCall anAnimateInit
	
	
	
;Init NativeSprite
	dbbw mov16x,r6_imm16,(SpritePatterns-VramBase)	;Sprite patterns
	dbbw mov16x,r2_imm16,(SpritePatterns_End-SpritePatterns) ;ByteCount
	NSCall nsInit 
	
	;dc.b hltb

;Copy SpriteArray from ROM to RAM	
	dbb SYSi,syscallLoadMultiReg		;This will be better for setting 3+ regs
	dc.b %01110000						;AF,BC,DE,HL mask
	dwww 256,(SpriteArrayRam-VM_RamBaseB),(SpriteArray-VramBase)	;BC,DE,HL
	AdvCall aDoLdir
	
;		AdvXCall axMemDump
;			dw MyVDPCommandsBase			;Address
;			dc.b 3,18,0					;Lines,Ypos,Bit0=Pause/Bit1=headerless 

		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
;Main Loop
	
GameLoop:	
	;dbbw mov16x,r6_imm16,$1234;PatternData
	;dbbw mov16x,r2_imm16,$5678;PatternData_End-PatternData
	;dbbw mov16x,r0_imm16,$1111;PatternData_End-PatternData
	;dbbw mov16x,r4_imm16,$2222;PatternData_End-PatternData
	;dbbw mov16x,r6_imm16,PatternData
	;dbbw mov16x,r2_imm16,PatternData_End-PatternData
	
	
	MaxTileCall mxMaxTileRedraw+regNO	;Redraw MaxTile Screen

	
	

	
	dbbw mov16x,r6_imm16,(SpriteArrayRam-VM_RamBaseB)
	
	
	
	NSCall nsDrawArray+regRR 			;Draw SpriteArray
		
	dbb movi,ChibiLife_PetCount			;Sprite count (loop count)

	dbbw mov16x,r4_imm16,(SpriteArrayRam-VM_RamBaseB)+1+32 ;Pointer to first chibi data
	
	
	
ChibiUpdateLoop:		
	dc.b ph0b
		dbbb movx,r2_AtR4PlIm,+sarYPOS 	;ypos
		dbbb movx,r3_AtR4PlIm,+sarXPOS 	;xpos
		
		
		
		MaxTileCall mxShiftTilemapLU	;Get tile under chiib
		
		
;See what is under chibi - note we recheck every frame even if chibi
;hasn't moved in case another chibi has 'consumed' an object
		
		dc.b ph6b
			dbbw add16x,r6_imm16,64
			MaxTileCall mxGetTileByteFromHL
			dbbb movx,AtR4PlIm_r0,+sarUNDR 	;Store tile (BYTE) under Spr
		dc.b pl6b
		
		
;Collision Detection - test UDLR for walls which stop chibi moving

		dbbb movx,r1_AtR4PlIm,+sarCOLL
		
;We don't update collisions when not needed to save CPU power
		dbbb tstx,r1_imm8,%00010000	;Moved flag
		dbw bnej,(CollisionNotNeeded-VramBase)
		
		dbbb andx,r1_imm8,%11100000
		dbbb orrx,r1_imm8,%00010000	;Flag collisions updated
		
		
		dbbw sub16x,r6_imm16,2		;Left of sprite
		
		dbw bsrj,(WallTest-VramBase)			;Test collision
		dbw bnej,(NoBlockL-VramBase)
		dbbb orrx,r1_imm8,%00000100	;Wall on Left
NoBlockL:

		dbbw add16x,r6_imm16,4		;Right of sprite
		
		dbw bsrj,(WallTest-VramBase)			;Test collision
		dbw bnej,(NoBlockR-VramBase)
		dbbb orrx,r1_imm8,%00001000	;Wall on right
NoBlockR:

		dbbw add16x,r6_imm16,(192-2)		;Below Sprite
		
;Use Walls test only for Climbing up/down
		dbbbb cmpx,AtR4PlIm_imm8,+sarANIM,3	
		dbw beqj,(UDtestWall-VramBase)
		dbbbb cmpx,AtR4PlIm_imm8,+sarANIM,4
		dbw bnej,(UDtestFloor-VramBase)
		
		
;Tests for Climbing (Dont look at ladders)
UDtestWall:		
		dbw bsrj,(WallTest-VramBase)			;Test collision
		dbw bnej,(NoBlockDw-VramBase)
		dbbb orrx,r1_imm8,%00000010	;Wall below
NoBlockDw:

		dbbw add16x,r6_imm16,-(192+64)	;Above sprite
				
		dbw bsrj,(WallTest-VramBase)			;Test collision
		dbw bnej,(NoBlockUw-VramBase)
		dbbb orrx,r1_imm8,%00000001	;Wall above
NoBlockUw:

		dbw braj,(CollisionsDone-VramBase)
		
		
;Tests for walking (Look for ladders as floor)
UDtestFloor:		
		dbw bsrj,(FloorTest-VramBase)			;Test collision
		dbw bnej,(NoBlockDf-VramBase)		
		dbbb orrx,r1_imm8,%00000010	;Wall below
NoBlockDf:

		dbbw add16x,r6_imm16,-(192+64)	;Above sprite
				
		dbw bsrj,(FloorTest-VramBase)			;Test collision
		dbw bnej,(NoBlockUf-VramBase)
		dbbb orrx,r1_imm8,%00000001	;Wall above
NoBlockUf:

CollisionsDone:
		;advxcall axMonitors
		dbbb movx,AtR4PlIm_r1,+sarCOLL 	;Move Collision map to spritedata+7
CollisionNotNeeded:	
	
		
; Object under chibi - Note all objects are 16x16, so we only test
;  Top left tile

		dbbb movx,r0_AtR4PlIm,+sarUNDR  ;Get Under
		dc.b cmpi,0
		dbw beqj,(NoTileUnder-VramBase)			;Nothing under chibi
		
		dc.b cmpi,$46			 ;food?
		dbw beqj,(OnFood-VramBase)
		dc.b cmpi,$48			;toy?
		dbw beqj,(OnToy-VramBase)
		dc.b cmpi,$4A			;coffin?
		dbw beqj,(OnCoffin-VramBase)
		
		dc.b cmpi,$43			;Ladder?
		dbw bnej,(NoTileUnder-VramBase) ;MO? then No known object
		
;We're on a ladder!
		;Are we walking LR?
		dbbb movx,r0_AtR4PlIm,+sarANIM  
		dbb cmpi,1						
		dbw beqj,(ConsiderLadder-VramBase)
		dbb cmpi,2
		dbw beqj,(ConsiderLadder-VramBase)
		dbw braj,(NoLadder-VramBase)				;Not walking LR - can't climb!
		
ConsiderLadder:	
		dbbb movx,r0_AtR4PlIm,+sarRAND
		
		dbbw mov16x,r2_imm16,$0300		;Frame/Anim
		dbb andi,%00000011
		dbw beqj,(LadderSet-VramBase)		;0   = Climb up
		
		dbbw mov16x,r2_imm16,$0400		;Frame/Anim
		dbb cmpi,%00000011
		dbw beqj,(LadderSet-VramBase)		;3   = Climb down 
		
		dbw braj,(NoLadder-VramBase)		;1/2 = no action
		
LadderSet:		;We've decided to climb up/down
		dbbbb andx,AtR4PlIm_imm8,+sarCOLL,%11101111	;Need collision update

		dbbb mov16x,AtR4PlIm_r2,+sarFRAM
		dbw braj,(NoLadder-VramBase)
		
;Coffins allow chibis to sleep (not consumed)
OnCoffin:
		dbbb movx,r0_AtR4PlIm,+sarSLEE
		dbb cmpi,128					;Don't sleep if >128
		dbw bccj,(ObjectDone-VramBase)
		
		dbbbb cmpx,AtR4PlIm_imm8,+sarANIM,$09 ;Already Sleeping?
		dbw beqj,(NoSleepAnim-VramBase)
		dbbbw mov16x,AtR4PlIm_imm16,+sarFRAM,$0900		;snooze
		
NoSleepAnim:
		dbw braj,(ObjectDone-VramBase)

;Toys reduce boredom (consumed)
OnToy:

		dbbb movx,r0_AtR4PlIm,+sarBORE
		dbb cmpi,128	
		dbw bccj,(ObjectDone-VramBase)					;Over Max - don't consume
			dbb addi,128
		dbbb movx,AtR4PlIm_r0,+sarBORE
		dbw braj,(ConsumeObject-VramBase)

;Food reduce hunger (consumed)
OnFood:
		;sarFOOD
		dbbb movx,r0_AtR4PlIm,+sarFOOD
		dbb cmpi,128
		dbw bccj,(ObjectDone-VramBase)					;Over Max - don't consume
			dbb addi,128
		dbbb movx,AtR4PlIm_r0,+sarFOOD
		
;Take the object off playfield
ConsumeObject:
		dc.b ph4b
			dbbb movx,r2_AtR4PlIm,+sarYPOS 	;ypos
			dbbb movx,r3_AtR4PlIm,+sarXPOS 	;xpos
			MaxTileCall mxShiftTilemapLU
			dbbw add16x,r6_imm16,64

			dbbw mov16x,r4_imm16,(MaxTileTilemap-VM_RamBaseB)+(64*16)+(2*26) ;src (empty tile)
			
			dbb swp16x,r4_r6
			dbw bsrj,(DoFireCopyTiles-VramBase)		;Remove 'eaten' object
			
		dc.b pl4b
		dbbbw mov16x,AtR4PlIm_imm16,+sarFRAM,$0800		;Turn away
ObjectDone:
NoLadder:		

;;; Life Depleation
		
NoTileUnder:	

	dbbw movx,r0_addr16,Timer_TicksOccured
	dbbb andx,r0_AtR4PlIm,+sarMETA					;Metabolic rate
	;dbb andi,%00000111
	dbw bnej,(NoLifeTick-VramBase)						;Dont update life this tick
	
	dbw bsrj,(LifeTick-VramBase)						;Upldate life this tick
NoLifeTick:	

;;;;;; AnimZero Check

	dbbb movx,r0_AtR4PlIm,+sarANIM  ;Get Anim
	
	dc.b cmpi,0
	dbw bnej,(NoAnimZero-VramBase)
	
	dbbbb addx,AtR4PlIm_imm8,+sarYPOS,%00000010
	dbbbb andx,AtR4PlIm_imm8,+sarYPOS,%11111100 	;Make sure chibi isn't walking through floor
	
	
	dbbb movx,r0_AtR4PlIm,+sarRAND
	
	dbbw mov16x,r2_imm16,$0200		;Frame/Anim
	dbb cmpi,128
	dbw bcsj,(AnimZeroR-VramBase)
	dbbw mov16x,r2_imm16,$0100		;Frame/Anim
AnimZeroR:
	dbbb mov16x,AtR4PlIm_r2,+sarFRAM
	
NoAnimZero:	
	

;Perform animations	
	dbbb mov16x,r2_AtR4PlIm,+sarFRAM ;Get Frame+Animator 

	AnimCall anAnimateIX		;Animate this sprite
	
	
	dbbb mov16x,AtR4PlIm_r2,+sarFRAM	;Store updated Frame+Animator 
	
;Change Decisions based on 'Fickle timer'

	dbbb decx,AtR4PlIm_r0,+sarFICK
	dbw bnej,(NoReRandom-VramBase)		
	
	advcall aDoRandom
	
	dbb andi,127		;Random patience (Desparate)
	dbbbb tstx,AtR4PlIm_imm8,+sarCOLL,%10000000
	
	dbw bnej,(Desperate-VramBase)
	dbb andi,63			;Random patience (Normal)
Desperate:		
	
	
	dbb addi,32			;minimum patience
	
	dbbb addx,r0_AtR4PlIm,sarPerc
	
	
	dbbb movx,AtR4PlIm_r0,+sarFICK	;Patience (Fickle)
	
	dbbbb addx,AtR4PlIm_imm8,+sarYPOS,%00000010
	dbbbb andx,AtR4PlIm_imm8,+sarYPOS,%11111100 	;Make sure chibi isn't walking through floor
	
	advcall aDoRandom
	dbbb movx,AtR4PlIm_r0,+sarRAND
	
	dbbbb andx,AtR4PlIm_imm8,+sarCOLL,%11101111	;Need collision update
	dbbbw mov16x,AtR4PlIm_imm16,+sarFRAM,0		;Reset action
	
NoReRandom:		
		

;Move to next chibi
			
	dbbw add16x,r4_imm16,4+NativeSpr_ExtraBytes		;Move to next sprite data block
			
	dc.b pl0b
	
	dc.b decb							;Decrease sprite count and repeat
	dbw bnej,(ChibiUpdateLoop-VramBase)				;Repeat for next sprite
	
;Show status bar
	
	dbbw mov16x,r4_imm16,(SpriteArrayRam-VM_RamBaseB)+1+16 ;Pointer to Arrow sprite
	
	dbbb mov16x,r6_atr4plIm,8+2				;Selected Chibi Data addr
	
	dbb mov16x,r0_atr6
	dbbw add16x,r0_imm16,$01FC				;Move Arrow above selected
	dbb mov16x,atr4_r0
	
	dbbw movx,r0_addr16,Timer_TicksOccured
	dc.b addi,4				;So we don't sync with life update
	dbb andi,%00000111		;Don't show status every tick (it's slow!)
	dbw bnej,(NoShowStatus-VramBase)
	;dbw braj,(NoShowStatus-VramBase)
	
	dbbw mov16x,r4_imm16,$0014				;Cursorpos for Memdump
	AdvXCall AxMonitorSetCP
	
	
	dc.b ph6b
		dbbw mov16x,r2_imm16,$0202
		AdvXCall axMemDumpCust
		
	dc.b pl2b
	
	dbbw mov16x,r4_imm16,$0012
	dbbw mov16x,r6_imm16,(StatusLine-VramBase)		
	AdvXCall AxPrintSeqCPBCDE
	
NoShowStatus:

;Move Joystick cursor

	

	dbbw incx,addr16_r0,Timer_TicksOccured	;Increment animation tickcount
	
	advcall aReadJoystick			;Read joystick
	
	dbbw mov16x,r4_imm16,(SpriteArrayRam-VM_RamBaseB)+1 ;Cursor sprite
	
	dbbw mov16x,r6_imm16,(Case_JoyProcess-VramBase)		
	AdvXCall axCaseBra				;branch to joystick processing routine
	
	dbw braj,(GameLoop-VramBase)				;Loop if no case match found

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Life depleation
LifeTick:
	
	dbbb movx,r1_AtR4PlIm,+sarCOLL
	dbbb andx,r1_imm8,%00111111		;Top 2 bits for mood state
	
;Check food 
	dbbb movx,r0_AtR4PlIm,+sarFOOD
	
	dbb cmpi,64
	dbw bccj,(LifeFoodOk-VramBase)
	dbbb orrx,r1_imm8,%01000000		;flag unhappy
LifeFoodOk:

	dc.b decb
	dbw bnej,(LifeFoodNotHurt-VramBase)
		dbbb orrx,r1_imm8,%10000000		;flag hurt
		dc.b incb
LifeFoodNotHurt:	

	dbbb movx,AtR4PlIm_r0,+sarFOOD
	
;Check boredom / entertainemnt
	dbbb movx,r0_AtR4PlIm,+sarBORE
	
	dbb cmpi,64
	dbw bccj,(LifeBoreOk-VramBase)
	dbbb orrx,r1_imm8,%01000000		;flag unhappy
LifeBoreOk:

	dc.b decb
		dbw bnej,(LifeBoreNotHurt-VramBase)
		dbbb orrx,r1_imm8,%10000000		;flag hurt 
		dc.b incb
LifeBoreNotHurt:	
	
	dbbb movx,AtR4PlIm_r0,+sarBORE
	
;Check sleep 
	dbbb movx,r0_AtR4PlIm,+sarSLEE
	
	dbb cmpi,64
	dbw bccj,(LifeSleepOk-VramBase)
	dbbb orrx,r1_imm8,%01000000		;flag unhappy
LifeSleepOk:

	dc.b decb	
		dbw bnej,(LifeSleepNotHurt-VramBase)
		dbbb orrx,r1_imm8,%10000000		;flag hurt 
		dc.b incb
LifeSleepNotHurt:	
	
	dbbb movx,AtR4PlIm_r0,+sarSLEE
	
	
	dbbb movx,AtR4PlIm_r1,+sarCOLL		;Store new collisions
	
	
	dbbb andx,r1_imm8,%10000000			;Was Chibi Hurt?
	dbw bnej,(LifeTick_Depleat-VramBase)			;Depleat life
	
	dbbb movx,r0_AtR4PlIm,+sarLIFE		;Chibi Not hurt!
	dc.b incb							;All needs>0 = increase life
	dbw beqj,(LifeMax-VramBase)	;Life=255?
	dbbb movx,AtR4PlIm_r0,+sarLIFE
LifeMax:
	dc.b rtsb

	
LifeTick_Depleat:
	dbbb movx,r0_AtR4PlIm,+sarLIFE
	dc.b decb								;Depleat life
	dbw beqj,(LifeTick_Dead-VramBase)				;Life 0=dead
	dbbb movx,AtR4PlIm_r0,+sarLIFE
	dc.b rtsb
	
	
LifeTick_Dead:
	dbbbw mov16x,AtR4PlIm_imm16,+sarFRAM,$0600		;Dead anim
	dc.b rtsb

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
DoFire2:	;Switch to another chibi


	dbbw mov16x,r4_imm16,(SpriteArrayRam-VM_RamBaseB)+1+16

	dbbb movx,r0_atr4plIm,8		;Get selected chibi
	dc.b incb
	dbb cmpi,ChibiLife_PetCount	;Over chibi count?
	dbw bcsj,(DoFire2Chibiok-VramBase)
	dc.b clrb						;Yes! zero chibi
DoFire2Chibiok:
	dbbb movx,atr4plIm_r0,8
	
	dbb movx,r2_r0				;C=chibi
	dbb clrx,r3_r3				;B=0
	
	AdvXCall AxBClsl4			;Chibinum * 16 (16 bytes per entry)
	
	dbbw add16x,r2_imm16,(SpriteArrayRam-VM_RamBaseB)+1+32	;First byte of first chibi
	dbbb mov16x,atr4plIm_r2,8+2					;Pointer for status line
	
	dbw braj,(GameLoop-VramBase)				;Loop

	
DoFire: ;Pickup / Drop item
	dbbb movx,r2_AtR4PlIm,+sarYPOS 	;ypos
	dbbb movx,r3_AtR4PlIm,+sarXPOS 	;xpos
	
	;advxcall axMonitor
	
	dbbwb cmpx,addr16_imm8,(SpriteArrayRam-VM_RamBaseB)+1+sarYPOS,80+60+4	;Clicked on playarea?
	dbw bcsj,(DoFireDropItem-VramBase)					;Yes? drop item
	
DoFireSelectItem:		
	dbbwb cmpx,addr16_imm8,(SpriteArrayRam-VM_RamBaseB)+1+sarXPOS,64+96	;Clicked on right?
	dbw bccj,(DoFire2-VramBase)						;Clicked on 'Swap chibi icon'

	dbbb andx,r2_imm8,%11111000		;Round to a 16x16 px tile block
	dbbb andx,r3_imm8,%11111000
	
	MaxTileCall mxShiftTilemapLU	;Get tilemap src
	dbbw mov16x,r4_imm16,(MaxTileTilemap-VM_RamBaseB)+(64*16)+(2*30)	;Far right tile
	dbw bsrj,(DoFireCopyTiles-VramBase)				;Copy to 'selected' tile  R6->R4
	
	dbw braj,(GameLoop-VramBase)			
	
	
DoFireDropItem:
	MaxTileCall mxShiftTilemapLU	
	;Check if 2x2 square is empty
	dbw mov16i,$0002		;Move right
	dbw bsrj,(TestTileR6-VramBase)		 	;TopLeft
	;dbw bnej,GameLoop - automatically performed by TestTileR6
	
	dbw mov16i,$003E 		;Down a line and left
	dbw bsrj,(TestTileR6-VramBase)				;TopRight
	;dbw bnej,GameLoop
	
	dbw mov16i,$0002		;Move right
	dbw bsrj,(TestTileR6-VramBase)				;BottomLeft
	;dbw bnej,GameLoop	
	
	dbw mov16i,$003E 		;Down a line and left
	dbw bsrj,(TestTileR6-VramBase)		 	;BottomRight
	;dbw bnej,GameLoop
	
;We're on a blank block, but is there any floor???
	MaxTileCall mxGetTileByteFromHL	;Get tile below (looking for floor)
	dc.b ph6b
		dbbw mov16x,r6_imm16,(Floors-VramBase)			 ;Get list of walls 
		dbbw mov16x,r2_imm16,FloorsEnd-Floors	;get count of walls
		AdvXCall axDoCpir	;compare R2 bytes from (R6) to R0
	dc.b pl6b
	dbw bnej,(Fire_NotOnFloor-VramBase)		
	
;Copy tile from 'selected' to playarea
	dbw mov16i,-(128)		;Back to topleft of empty block
	dbb add16x,r4_r0		;Dest
	dbb add16x,r6_r0		;Src

	dbbw mov16x,r4_imm16,(MaxTileTilemap-VM_RamBaseB)+(64*16)+(2*30)  ;selected tile src
	dbb swp16x,r4_r6
	dbw bsrj,(DoFireCopyTiles-VramBase) ;Copy R6->R4
	
Fire_NotOnFloor:	
	dbw braj,(GameLoop-VramBase)		
	

DoFireCopyTiles:		;Copy tile from R6->R4

	NSCall (nsHideAllForBackground|regNO); equ %11000000 - Don't Read or Write Regs
	dbw mov16i,$0002
	dbw bsrj,(CopyTileR6toR4-VramBase)		 ;TopLeft
	dbw mov16i,62
	dbw bsrj,(CopyTileR6toR4-VramBase)		 ;TopRight
	dbw mov16i,$0002
	dbw bsrj,(CopyTileR6toR4-VramBase)		 ;BottomLeft
	dbw braj,(CopyTileR6toR4-VramBase)		;BottomRight
		
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
CopyTileR6toR4: ;Set (R4)=(R6) , R4 += R0 , R6 += R0
	dbb mov16x,atr4_atr6			;Copy Tile
	dbbw add16x,AtR4_imm16,$0001	;SetDrawFlag
	dbb add16x,r4_r0		;Dest
	dbb add16x,r6_r0		;Src
	dc.b rtsb

	
TestTileR6:		;Compare (R6) to &0000 , R4 += R0 , R6 += R0
				;Consumes return address on !=0
	dbbw cmp16x,atr6_imm16,0	;Test Tile
	dc.b phfb
		dbb add16x,r4_r0		;Dest
		dbb add16x,r6_r0		;Src
	dc.b plfb
	dbw beqj,(TestTileR6_empty-VramBase)			;This tile empty?
	
	dc.b pl0b						;Consume return address
	dbw braj,(GameLoop-VramBase)		
TestTileR6_empty:
	dc.b rtsb
	
DoUp:
	dbbwb cmpx,addr16_imm8,(SpriteArrayRam-VM_RamBaseB)+1+sarYPOS,80+8	;Can move?
	dbw bcsj,(GameLoop-VramBase)		
	dbbwb addx,addr16_imm8,(SpriteArrayRam-VM_RamBaseB)+1+sarYPOS,-4		;Move!
	dbw braj,(GameLoop-VramBase)		
	
DoDown:
	dbbwb cmpx,addr16_imm8,(SpriteArrayRam-VM_RamBaseB)+1+sarYPOS,80+8+60
	dbw bccj,(GameLoop-VramBase)		
	dbbwb addx,addr16_imm8,(SpriteArrayRam-VM_RamBaseB)+1+sarYPOS,+4
	dbw braj,(GameLoop-VramBase)		

DoLeft:
	dbbwb cmpx,addr16_imm8,(SpriteArrayRam-VM_RamBaseB)+1+sarXPOS,64+4
	dbw bcsj,(GameLoop-VramBase)		
	dbbwb addx,addr16_imm8,(SpriteArrayRam-VM_RamBaseB)+1+sarXPOS,-4
	dbw braj,(GameLoop-VramBase)		

DoRight:	
	dbbwb cmpx,addr16_imm8,(SpriteArrayRam-VM_RamBaseB)+1+sarXPOS,64+128-4
	dbw bccj,(GameLoop-VramBase)		
	
	dbbwb addx,addr16_imm8,(SpriteArrayRam-VM_RamBaseB)+1+sarXPOS,+4
	dbw braj,(GameLoop-VramBase)		


WallTest:
		MaxTileCall mxGetTileByteFromHL	;Get Byte tile 
	
	dc.b ph6b
		dbbw mov16x,r6_imm16,(Walls-VramBase)		 ;Get list of walls 
		dbbw mov16x,r2_imm16,WallsEnd-Walls	;get count of walls
		
		AdvXCall axDoCpir	;compare R2 bytes from (R6) to R0
	dc.b pl6b					; Set Z=true if found ...  Z=false if not
	dc.b rtsb
	

FloorTest:
		MaxTileCall mxGetTileByteFromHL
	dc.b ph6b
		dbbw mov16x,r6_imm16,(Floors-VramBase)	 ;Get list of walls 
		dbbw mov16x,r2_imm16,FloorsEnd-Floors	;get count of walls
		AdvXCall axDoCpir	;compare R2 bytes from (R6) to R0
	dc.b pl6b					; Set Z=true if found ...  Z=false if not
	dc.b rtsb
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Walls:	;Used when clinbing ladder
	dc.b $41,$45				;These will block the player if CPIR used
WallsEnd:	

Floors:	;Used when walking
	dc.b $41,$45,$43,$63 		;These will block the player if CPIR used
FloorsEnd:	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	even
	
MyAnimators:
	ifnd ChibiVM_16bitAnimatorLinks
		
		dc.l PlayerWalkL	;1
		dc.l PlayerWalkR	;2
		dc.l PlayerClimbU	;3
		dc.l PlayerClimbD	;4
		dc.l PlayerDead		;5 UNUSED
		dc.l PlayerDead		;6
		dc.l PlayerMoodChange ;7
		dc.l PlayerPickup	;8
		dc.l PlayerSleep	;9
		
	else
;ChibiVM_16bitAnimatorLinks equ 1	

		dw PlayerWalkL-VramBase		;1
		dw PlayerWalkR-VramBase		;2
		dw PlayerClimbU-VramBase	;3
		dw PlayerClimbD-VramBase	;4
		dw PlayerDead-VramBase		;5 UNUSED
		dw PlayerDead-VramBase		;6
		dw PlayerMoodChange-VramBase ;7
		dw PlayerPickup-VramBase	;8
		dw PlayerSleep-VramBase		;9

	endif
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;First byte is the 'Tick map' which defines when 
	;  the animation should update
	
PlayerDead:
	dc.b %00000011			;Anim Freq
	
	dbbw anmLD16+aEXT,2,Sprite_16-VramBase	;Show dead
	
	dc.b anmLD8,sarFICK,255,255		;Set Fickle to max
	dc.b anmEXTD,aEXTD_loop,0,0		;Anim # Frame
	
	
PlayerPickup:
	dc.b %00000011			;Anim Freq
	
	dbbw anmLD16,2,Sprite_4-VramBase			;Show Chibi looking away
	dbbw anmLD16,2,Sprite_4-VramBase
	dbbw anmLD16,2,Sprite_4-VramBase
	
	dc.b anmEXTD,aEXTD_anim,0,0		;Anim # Frame
	
	
PlayerSleep:
	dc.b %00000001			;Anim Freq
	dc.b anmLD8,sarFICK,255,255	;Set Fickle to max
	
	dbbw anmLD16,2,Sprite_12-VramBase
	dc.b anmCondbra+cndCC,sarSLEE,255-8,1	;At sleep limit?
		dc.b anmAddMsked,sarSLEE,8,255
		
	dbbw anmLD16,2,Sprite_13-VramBase
	
	dc.b anmCondbra+cndCC,sarSLEE,255-8,1 ;At sleep limit?
	dc.b anmAddMsked,sarSLEE,8,255
	
	dc.b anmCondjmp+cndCS,sarSLEE,255-8,0 ;Repeat if can sleep more
	
	dc.b anmEXTD,aEXTD_anim,7,0			;Pick a new action
	
	
PlayerMoodChange:
	dc.b %00000000			;Anim Freq
	dc.b anmLD8+aEXT,sarFICK,99,0			;Force a re-randomize
	
	dc.b anmCondbra+cndTZ,7,%01000000,1	;Sad bit
	dbbw anmLD16,2,Sprite_11-VramBase			;Express Sad 
	
	dc.b anmCondbra+cndTN,7,%01000000,1
	dbbw anmLD16,2,Sprite_9-VramBase				;Express happy
	
	dbbw anmLD16,2,Sprite_8-VramBase
	
	dc.b anmCondbra+cndTZ,7,%01000000,1	
	dbbw anmLD16,2,Sprite_11-VramBase			;Express Sad
	
	dc.b anmCondbra+cndTN,7,%01000000,1
	dbbw anmLD16,2,Sprite_9-VramBase				;Express happy
	
	dc.b anmLD8+aEXT,sarFICK,1,0		;Force a re-randomize
	dc.b anmEXTD,aEXTD_anim,0,0		;Anim # Frame
	
	
PlayerWalkR:
	dc.b %00000000			;Anim Freq
	
	dc.b anmCondbra+cndTN,7,%00000010,2	;On floor?
		dc.b anmAddMsked+aEXT,sarCOLL,0,%11101111
		dc.b anmAddMsked,0,2,255				;Fall
		
	dc.b anmCndAnim+cndTN,7,%00001000,7
	
	dbbw anmLD16,2,Sprite_0-VramBase
	
	dc.b anmAddMsked+aEXT,sarCOLL,0,%11101111	 ;Flag moved (for collisions)
	dc.b anmAddMsked,1,1,255					;Offset,Add,Andmask
	
	dc.b anmCondbra+cndTN,7,%00000010,2		;On floor?
		dc.b anmAddMsked+aEXT,sarCOLL,0,%11101111	 ;Flag moved (for collisions)
		dc.b anmAddMsked,0,2,255				;Fall
		
	dbbw anmLD16,2,Sprite_1-VramBase
			
	dc.b anmEXTD,aEXTD_loop,0,0		;Anim # Frame

	
PlayerWalkL:
	dc.b %00000000			;Anim Freq
	
	dc.b anmCondbra+cndTN,7,%00000010,2	;On floor?
		dc.b anmAddMsked+aEXT,sarCOLL,0,%11101111	 ;Flag moved (for collisions)
		dc.b anmAddMsked,0,2,255				;Fall
	
	dc.b anmCndAnim+cndTN,7,%00000100,7
	
	dbbw anmLD16,2,Sprite_2-VramBase
	
	dc.b anmAddMsked+aEXT,sarCOLL,0,%11101111	 ;Flag moved (for collisions)
	dc.b anmAddMsked,1,-1,255				;Offset,Add,Andmask
		
	dc.b anmCondbra+cndTN,7,%00000010,2	;On floor?
		dc.b anmAddMsked+aEXT,sarCOLL,0,%11101111	 ;Flag moved (for collisions)
		dc.b anmAddMsked,0,2,255			;Fall
	
	dbbw anmLD16,2,Sprite_3-VramBase
		
	dc.b anmEXTD,aEXTD_loop,0,0		;Anim # Frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


PlayerClimbU:
	dc.b %00000000			;Anim Freq
	
	dbbw anmLD16,2,Sprite_4-VramBase
	dc.b anmCndAnim+cndTN,7,%00000001,7	;Force re-randomize if hit roof
	
	dc.b anmAddMsked+aEXT,sarCOLL,0,%11101111	 ;Flag moved (for collisions)
	dc.b anmAddMsked,sarYPOS,-1,255				;Offset,Add,Andmask
		
	dbbw anmLD16,2,Sprite_5-VramBase
	
	dc.b anmEXTD,aEXTD_loop,0,0		;Anim # Frame

	
PlayerClimbD:
	dc.b %00000000			;Anim Freq
		
	dbbw anmLD16,2,Sprite_6-VramBase
	dc.b anmCndAnim+cndTN,7,%00000010,7		;Force re-randomize if hit floor
	
	dc.b anmAddMsked+aEXT,sarCOLL,0,%11101111	 ;Flag moved (for collisions)
	dc.b anmAddMsked,sarYPOS,1,255				;Offset,Add,Andmask
	
	dbbw anmLD16,2,Sprite_7-VramBase
		
	dc.b anmEXTD,aEXTD_loop,0,0		;Anim # Frame

	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
;Case statement to test directions and branch to a VM routine

;For this use the Format is:
;   Command , Match , 16 bit address
	
Case_JoyProcess:
	dbbw srcBC+dstIm+cndEQ,%11111111,GameLoop-VramBase
	dbbw srcBC+dstIm+cndEQ,%11011111,DoFire2-VramBase
	dbbw srcBC+dstIm+cndEQ,%11101111,DoFire-VramBase
	dbbw srcBC+dstIm+cndEQ,%11111110,DoUp-VramBase
	dbbw srcBC+dstIm+cndEQ,%11111101,DoDown-VramBase
	dbbw srcBC+dstIm+cndEQ,%11111011,DoLeft-VramBase
	dbbw srcBC+dstIm+cndEQ,%11110111,DoRight-VramBase
	dc.b 0
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StatusLine: dc.b 5,250,8,11,' Food:',250,1,'  Happy:',250,1,253,5,'Sleep:',250,1,'   Life:',250,1,255
	
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	align 4	;Needed for some sprite renders which need tile alignment
SpritePatterns:	
	ifd NativeSpr_Multiplatform2Bitplane
		incbin "\ResALL\Reikou\AnimTest\ChibiLifeSprites_SMS_4color.RAW"
	else
		;incbin "\ResALL\Reikou\AnimTest\ChibiLifeSprites_SMS.RAW"
		
	endif 
SpritePatterns_End:

	
vm_Traps:
	dw ProgramLaunch-VramBase
	
vm_AddressRemapTable:	

	align 4	
	
	ifnd PatternFill
PatternFill:
	endif 
	
	ifnd PatternData
PatternData:
	endif
	
PatternSourceData:

FontData:	
		incbin "\ResALL\Reikou\Animtest\ChibiLife_SMS.raw"
PatternData_End:

	

FontData_End equ FontData+(16*64)

SpriteArray:
	dc.b ChibiLife_PetCount+2		;Count
	dww $5460,Sprite_14-VramBase	;XXYY,Sprite Cursor
	dc.b 0,1,0,0
	dc.b 0,0,0,0,0,0,0,0
	dww $5460,Sprite_15-VramBase	;XXYY,Sprite Selected Marker
	dc.b 0,2,0,0
		dc.b 0,0
		dw (SpriteArrayRam-VM_RamBaseB)+32+1
		dc.b 0,0,0,0
		
	dww $5068,Sprite_0-VramBase	;XXYY,Sprite 1
	dc.b 0,2,0,0
	;dc.b 64,0,64,0,0,0,0,0
	dc.b 1 ;sarFICK equ 8  ;Fickle (Time till re-randomiza)
	dc.b 0;sarRAND equ 9  ;Random seed (used to make decisions)
	dc.b 32;sarPERC equ 10	;Perseverance (added to fickle)
	dc.b 1;sarFOOD equ 11	;Food energy (Bloodpack)
	dc.b 128 ;sarBORE equ 12	;Bored energy (Toy)
	dc.b 255 ;sarSLEE equ 13	;Sleep energy (Coffin)
	dc.b 128 ;sarLIFE equ 14	;Life (0=dead)
	dc.b %00001111	;sarMETA equ 15 ;metabolic rate
	
	dww $6854,Sprite_0-VramBase	;XXYY,Sprite 2
	dc.b 0,3,0,0
	dc.b 1,0,24,122,128,255,255,%00000111
	dww $6078,Sprite_0-VramBase	;XXYY,Sprite 3
	dc.b 0,3,0,0
	dc.b 1,0,36,192,168,128,255,%00000111
	dww $707C,Sprite_0-VramBase	;XXYY,Sprite 4
	dc.b 0,3,0,0
	dc.b 1,0,40,122,198,160,255,%00000011
	dww $6868,Sprite_0-VramBase	;XXYY,Sprite 5
	dc.b 0,2,0,0
	dc.b 1,0,12,92,58,80,255,%00000011
	dww $6458,Sprite_0-VramBase	;XXYY,Sprite 6
	dc.b 0,3,0,0
	dc.b 1,0,16,72,78,96,255,%00000011
	
	dww $6868,Sprite_0-VramBase	;XXYY,Sprite 7
	dc.b 0,2,0,0
	dc.b 1,0,12,92,58,80,255,%00000011
	dww $6458,Sprite_0-VramBase	;XXYY,Sprite 8
	dc.b 0,3,0,0
	dc.b 1,0,16,72,78,96,255,%00000011
	
	
	dww $5068,Sprite_0-VramBase	;XXYY,Sprite 9
	dc.b 0,2,0,0
	;dc.b 64,0,64,0,0,0,0,0
	dc.b 1 ;sarFICK equ 8  ;Fickle (Time till re-randomiza)
	dc.b 0;sarRAND equ 9  ;Random seed (used to make decisions)
	dc.b 32;sarPERC equ 10	;Perseverance (added to fickle)
	dc.b 1;sarFOOD equ 11	;Food energy (Bloodpack)
	dc.b 128 ;sarBORE equ 12	;Bored energy (Toy)
	dc.b 255 ;sarSLEE equ 13	;Sleep energy (Coffin)
	dc.b 128 ;sarLIFE equ 14	;Life (0=dead)
	dc.b %00001111	;sarMETA equ 15 ;metabolic rate
	
	
	dww $6854,Sprite_0-VramBase	;XXYY,Sprite 10
	dc.b 0,3,0,0
	dc.b 1,0,24,122,128,255,255,%00000111
	dww $6078,Sprite_0-VramBase	;XXYY,Sprite 11
	dc.b 0,3,0,0
	dc.b 1,0,36,192,168,128,255,%00000111
	dww $707C,Sprite_0-VramBase	;XXYY,Sprite 12
	dc.b 0,3,0,0
	dc.b 1,0,40,122,198,160,255,%00000011
	dww $6868,Sprite_0-VramBase	;XXYY,Sprite 13
	dc.b 0,2,0,0
	dc.b 1,0,12,92,58,80,255,%00000011
	dww $6458,Sprite_0-VramBase	;XXYY,Sprite 14
	dc.b 0,3,0,0
	dc.b 1,0,16,72,78,96,255,%00000011
SpriteArray_End:	
	
	ifnd Sprite_0

	  
Sprite_0:
    dc.b 2,3 ;Width,Height
      dc.b 1,2
      dc.b 3,4
      dc.b 5,6

Sprite_1:
    dc.b 2,3 ;Width,Height
      dc.b 1,2
      dc.b 7,8
      dc.b 9,10

Sprite_2:
    dc.b 2,3 ;Width,Height
      dc.b 11,12
      dc.b 13,14
      dc.b 15,16

Sprite_3:
    dc.b 2,3 ;Width,Height
      dc.b 11,12
      dc.b 17,18
      dc.b 19,20

Sprite_4:
    dc.b 2,3 ;Width,Height
      dc.b 21,22
      dc.b 23,24
      dc.b 25,26

Sprite_5:
    dc.b 2,3 ;Width,Height
      dc.b 21,22
      dc.b 27,28
      dc.b 29,30

Sprite_6:
    dc.b 2,3 ;Width,Height
      dc.b 31,32
      dc.b 33,34
      dc.b 35,36

Sprite_7:
    dc.b 2,3 ;Width,Height
      dc.b 31,32
      dc.b 37,38
      dc.b 39,40

Sprite_8:
    dc.b 2,3 ;Width,Height
      dc.b 31,32
      dc.b 41,42
      dc.b 43,44

Sprite_9:
    dc.b 2,3 ;Width,Height
      dc.b 45,46
      dc.b 47,48
      dc.b 43,44

Sprite_10:
    dc.b 2,3 ;Width,Height
      dc.b 49,50
      dc.b 51,52
      dc.b 43,44

Sprite_11:
    dc.b 2,3 ;Width,Height
      dc.b 53,54
      dc.b 55,56
      dc.b 43,44

Sprite_12:
    dc.b 2,3 ;Width,Height
      dc.b 57,0
      dc.b 58,59
      dc.b 60,61

Sprite_13:
    dc.b 2,3 ;Width,Height
      dc.b 62,0
      dc.b 63,59
      dc.b 64,61

Sprite_14:
    dc.b 1,1 ;Width,Height
      dc.b 65

Sprite_15:
    dc.b 1,1 ;Width,Height
      dc.b 66

Sprite_16:
    dc.b 2,3 ;Width,Height
      dc.b 0,0
      dc.b 67,59
      dc.b 60,61



	endif
	

WorldMap:
	dw8 $0411,$0411,$0411,$0411,$0411,$0411,$0411,$0411
	dw8 $0411,$0411,$0411,$0411,$0411,$0411,$0411,$0411
	dw8 $0411,$0411,$0411,$0411,$0411,$0411,$0411,$0411
	dw8 $0411,$0411,$0411,$0411,$0411,$0411,$0411,$0411
    dw8 $0411,$0421,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0421,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0421,$0411
    dw8 $0411,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0411
    dw8 $0411,$0001,$0001,$0001,$0001,$0001,$0001,$0431
	dw8 $0631,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0481,$0491,$0001,$0001,$0431
	dw8 $0631,$0001,$0001,$0001,$0001,$0001,$0001,$0411
    dw8 $0411,$0441,$0441,$0001,$0001,$0001,$0001,$0431
	dw8 $0631,$0001,$0001,$0001,$0441,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0681,$0691,$0001,$0001,$0431
	dw8 $0631,$0001,$0001,$0001,$0001,$0001,$0441,$0411
    dw8 $0411,$0451,$0451,$0451,$0451,$0451,$0451,$0431
	dw8 $0631,$0451,$0451,$0451,$0451,$0451,$0451,$0411
	dw8 $0411,$0451,$0451,$0451,$0451,$0451,$0451,$0431
	dw8 $0631,$0451,$0451,$0451,$0451,$0451,$0451,$0411
    dw8 $0411,$0001,$0001,$0421,$0001,$0001,$0001,$0431
	dw8 $0631,$0001,$0001,$0001,$0001,$0001,$0001,$0411
	dw8 $0411,$0001,$0421,$0001,$0001,$0001,$0001,$0431
	dw8 $0631,$0001,$0001,$0001,$0001,$0421,$0001,$0411
    dw8 $0411,$0001,$0001,$0001,$0001,$0001,$0001,$0431
	dw8 $0631,$0001,$0001,$0001,$0001,$0001,$0001,$0411
	dw8 $0411,$0001,$0001,$0001,$0001,$0001,$0001,$0431
	dw8 $0631,$0001,$0001,$0001,$0001,$0001,$0001,$0411
    dw8 $0411,$0001,$0001,$0001,$0001,$0001,$0001,$0431
	dw8 $0631,$0001,$0001,$0461,$0471,$0001,$0001,$0411
	dw8 $0411,$0001,$0001,$0001,$0001,$0001,$0001,$0431
	dw8 $0631,$0001,$0001,$0001,$0001,$0001,$0001,$0411
    dw8 $0411,$0001,$0001,$0001,$0001,$0001,$0001,$0431
	dw8 $0631,$0001,$0001,$0661,$0671,$0001,$0001,$0411
	dw8 $0411,$0441,$0001,$0001,$0001,$0001,$0001,$0431
	dw8 $0631,$0001,$0001,$0001,$0001,$0001,$0001,$0411
    dw8 $0411,$0451,$0451,$0451,$0451,$0451,$0451,$0431
	dw8 $0631,$0451,$0451,$0451,$0451,$0451,$0451,$0411
	dw8 $0411,$0451,$0451,$0451,$0451,$0451,$0451,$0431
	dw8 $0631,$0451,$0451,$0451,$0451,$0451,$0451,$0411
    dw8 $0411,$0421,$0001,$0001,$0001,$0001,$0001,$0431
	dw8 $0631,$0001,$0001,$0001,$0001,$0001,$0421,$0411
	dw8 $0411,$0421,$0001,$0001,$0001,$0001,$0001,$0431
	dw8 $0631,$0001,$0001,$0001,$0001,$0001,$0001,$0411
    dw8 $0411,$0001,$0001,$0001,$0001,$0001,$0001,$0431
	dw8 $0631,$0001,$0001,$0001,$0001,$0001,$0001,$0411
	dw8 $0411,$0001,$0001,$0001,$0001,$0001,$0001,$0431
	dw8 $0631,$0001,$0001,$0001,$0001,$0001,$0001,$0411
    dw8 $0411,$0001,$0001,$0001,$0001,$0001,$0001,$0431
	dw8 $0631,$0001,$0001,$0001,$0001,$0001,$0001,$0411
	dw8 $0411,$0001,$0001,$0001,$0001,$0001,$0001,$0431
	dw8 $0631,$0001,$0001,$0001,$0001,$04A1,$04B1,$0411
    dw8 $0411,$0001,$0001,$0001,$0441,$0001,$0001,$0431
	dw8 $0631,$0001,$0001,$0001,$0441,$0001,$0001,$0411
	dw8 $0411,$0001,$0001,$0001,$0001,$0001,$0001,$0431
	dw8 $0631,$0001,$0441,$0001,$0001,$06A1,$06B1,$0411
    dw8 $0411,$0411,$0411,$0411,$0411,$0411,$0411,$0411
	dw8 $0411,$0411,$0411,$0411,$0411,$0411,$0411,$0411
	dw8 $0411,$0411,$0411,$0411,$0411,$0411,$0411,$0411
	dw8 $0411,$0411,$0411,$0411,$0411,$0411,$0411,$0411
    dw8 $0461,$0471,$0481,$0491,$04A1,$04B1,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$04C1,$04D1,$0001,$0001
    dw8 $0661,$0671,$0681,$0691,$06A1,$06B1,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$06C1,$06D1,$0001,$0001
    dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
    dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
    dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
    dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
    dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
    dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	dw8 $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001

	
	
TestProgram_End:		
	even

	
	;align 16
	
	ifd VM_RamBase
		ifnd VM_RamBaseAddr
		even
VM_RamBaseAddr: dc.l VM_RamBase
		endif
	endif

	ifnd VM_RamBase
VM_RamBaseAddr: dc.l VM_RamBase2+65536	
	
		even
; VM_RamBase2:
		; ds.b 65536*2
; VM_HostRam:	
		; ds.b 256
	endif
	

	
	even
	
	include "srcall/ChibiVm_CPU.asm"		

	
	even
	include "core.asm"
	include "footer.asm"
	
	
	;Variables for our Emulator

