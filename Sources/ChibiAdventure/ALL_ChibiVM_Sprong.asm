GEN_BMPscreen equ 1


VscreenMinX equ 64		;Top left of visible screen in logical co-ordinates
VscreenMinY equ 80

VscreenWid equ 128		;Visible Screen Size in logical units
VscreenHei equ 96

;compile with option: VASM GEN

	include "header.asm"
	
	include "\SrcALL\ChibiVm_InstSet.asm"
	include "\SrcALL\BasicMacros.asm"

	ifd BuildSQL
VM_RamBase equ $30000
VM_HostRam equ $003F000	;Variables for our Emulator
	endif
	
	ifd BuildNEO
VM_RamBase equ $100000
VM_HostRam	equ $10FE00	;Variables for our Emulator
NeedReorg equ 1
	endif
	
	ifd BuildGEN
VM_RamBase equ $00FF0000
VM_HostRam	equ $00FFFE00	;Variables for our Emulator
NeedReorg equ 1
	endif
	
	ifd BuildX68
SpritePatternSize equ 128
	endif
	
;	ifd BuildAST
;VM_RamBase equ ramarea+65536	
;VM_HostRam	equ ramarea+$1FE00	;Variables for our Emulator
;SpriteArrayRam equ $300	
;	endif
	
	
VM_ProgLoadAddr equ $400	

	ifnd SpriteArrayRam
	ifd VM_RamBase
HspriteCount equ VM_RamBase+64
HspriteLimit equ VM_RamBase+65
SpriteArrayRam equ VM_RamBase+$300	
	else
SpriteArrayRam equ $300	
	endif
	endif

	
GEN_SpritePatternVRAM equ $8000
GEN_SpritePatternCount equ 64	
	
SpritePatterns equ 0 ;Remap pointer to Hsprites
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

	
	move.l #SpriteArray,a3
;	ifd BuildAST	
;		move.l (VM_RamBaseAddr),a2
;		add.l #SpriteArrayRam,a2
;	else
		ifd VM_RamBase
			move.l #SpriteArrayRam,a2
		else
			move.l (VM_RamBaseAddr),a2
			add.l #SpriteArrayRam,a2
		endif
;	endif
	move.l #32,d1
	jsr doldir
	
	
	;move.l #HSprites,a3
	;jsr NativeSpr_Init

	;move.l #SpriteArray,a3
	;jsr NativeSpr_DrawArray
	
	;jsr nativespr_hideall
	
	;jmp $
	
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
	
	;jsr Monitor_MemDump		;Dump 6 lines from  $00000000
	;dc.l VM_RamBase+VM_ProgLoadAddr
	;dc.w $2
	;jmp $
	
	;jsr VM_Run_WithMonitor
	
VM_Run:	
	jsr VM_Tick
	jmp VM_Run
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	dwle 1+1
	dwle 2
	dwle 3
	dwle $111
	dwle $222
	dwle $333
	

	even

		
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	include "\SrcALL\V1_NativeSprite.asm"	
	
	
	include "..\ChibiVM\Multiplatform_MonitorA.asm"
	include "ChibiVM_AdventureEngine.asm"
	include "\Sources\ChibiVM\ChibiVM_Host.asm"
	
	
	
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

	
		
ballpos equ			64+16
ballmove equ		64+18
PlayerPaddle equ	64+20
CpuPaddle equ		64+22
PlayerScore equ		64+24
CpuScore equ		64+25
GameTick equ		64+26
GameSpeed equ		64+27		
GameAI equ			64+28
SoundByte equ		64+29 

ProgramLaunch:


	dbbw mov16x,r6_imm16,SpritePatterns		;Sprite patterns
	dbbw mov16x,r2_imm16,4*SpritePatternSize	;ByteCount
	NSCall nsInit 
	
	
	
	;dbbw mov16x,r6_imm16,SpriteArrayRam	;Ram
	;NSCall nsDrawArray+regRR 			;SpriteArray
	
	;dbbw mov16x,r6_imm16,1;5	;Ram
	;NSCall nsDrawArray+regRR 			;SpriteArray
		
	;db hltb
	; ld hl,SpritePatterns		;Sprite patterns
	; ld bc,4*SpritePatternSize	;ByteCount
	; call NativeSpr_Init
	
;                                     

;                                     newgame:
newgame:
	;NSCall nsHideAll+regNO
	
	;dbbw mov16x,r6_imm16,SpriteArrayRam	;Ram
	;NSCall nsDrawArray+regRR 			;SpriteArray

;                                     	advcall acls
	;advcall acls
;                                     	mov16x r6,#$0000		;speed - ai
	dbbw mov16x,r6_imm16,$0000
;                                     titlescreen:

titlescreen:
;                                     	advcall apause50
	advcall apause50
;                                     	mov16x r4,#$0000		;cursorpos
	dbbw mov16x,r4_imm16,$0000
;                                     	ph6
	db ph6b
;                                     		mov16x r6,#strstart
	dbbw mov16x,r6_imm16,strstart-VramBase
;                                     		advcall aprintseq
	advcall aprintseq
;                                     		mov16x r6,#strspeed
	dbbw mov16x,r6_imm16,strspeed-VramBase
;                                     		advcall aprintseq
	advcall aprintseq
;                                     	pl6
	db pl6b
;                                     	movx r0,r7
	dbbb movx,r0_zeropg,r7
;                                     	advcall ashowdecimal
	advcall ashowdecimal
;                                     	ph6
	db ph6b
;                                     		mov16x r6,#strai
	dbbw mov16x,r6_imm16,strai-VramBase
;                                     		advcall aprintseq
	advcall aprintseq
;                                     	pl6
	db pl6b
;                                     	movx r0,r6
	dbb movx,r0_r6
;                                     	advcall ashowdecimal
	advcall ashowdecimal
;                                     

;                                     	advcall areadjoystick	;%---frldu
	advcall areadjoystick
;                                     	movx r2,r0
	dbb movx,r2_r0
;                                     

;                                     	mov16x r4,#$0004		;cursorpos
	dbbw mov16x,r4_imm16,$0004
;                                     

;                                     	movx r0,r6
	dbb movx,r0_r6
;                                     	advcall ajoyaxis		;ud
	advcall ajoyaxis
;                                     	advcall arangelimit
	advcall arangelimit
;                                     	movx r6,r0
	dbb movx,r6_r0
;                                     

;                                     	movx r0,r7
	dbbb movx,r0_zeropg,r7
;                                     	advcall ajoyaxis		;lr
	advcall ajoyaxis
;                                     	advcall arangelimit
	advcall arangelimit
;                                     	movx r7,r0
	dbbb movx,zeropg_r0,r7
;                                     

;                                     	tstx r2,#1			;fire?
	dbbb tstx,r2_imm8,1
;                                     	bnei titlescreen
	dbb bnei,titlescreen-lbl35419
lbl35419



	dbbb movx,r0_zeropg,r7
	dbw bsrj,readmask-VramBase
	dbbw stox,r0_addr16,gamespeed

	dbb movx,r0_r6
	dbw bsrj,readmask-VramBase
	dbbw stox,r0_addr16,gameai

	dbw bsrj,rezeroball-VramBase

 	dbbw sto16x,r4_addr16,ballpos

	dbbww mov16x,addr16_imm16,ballmove,$ffff	;ball pos -1 = facing player

	dbbwb movx,addr16_imm8,playerpaddle,6*4		;ypos
	dbbwb movx,addr16_imm8,cpupaddle,6*4

	dbbw clrx,addr16_r0,cpuscore
	dbbw clrx,addr16_r0,playerscore

	dbbwb movx,addr16_imm8,playerpaddle+1,0*4	;Xpos
	dbbwb movx,addr16_imm8,cpupaddle+1,19*4

	advcall acls
	dbbw mov16x,r6_imm16,strwall-VramBase				;Draw Walls
	advcall aprintseq
	
	dbw bsrj,ShowScores-VramBase							;ShowScores

gameloop:

	dbbw mov16x,r4_addr16,ballpos
	db ph4b
		
	dbbbb addx,zeropg_imm8,r4,VscreenMinY
	dbbbb addx,zeropg_imm8,r5,VscreenMinX
	
	dbbw sto16x,r4_addr16,SpriteArrayRam+9
	
	dbw bsrj,getplayerpaddlede-VramBase
	
	dbbbb addx,zeropg_imm8,r4,VscreenMinY
	dbbbb addx,zeropg_imm8,r5,VscreenMinX
	
	dbbw sto16x,r4_addr16,SpriteArrayRam+1
		
	dbw bsrj,getcpupaddlede-VramBase
		
	dbbbb addx,zeropg_imm8,r4,VscreenMinY
	dbbbb addx,zeropg_imm8,r5,VscreenMinX
	
	dbbw sto16x,r4_addr16,SpriteArrayRam+5
		
	dbbw mov16x,r6_imm16,SpriteArrayRam	;Ram
	NSCall nsDrawArray+regRR 			;SpriteArray

	dbbw mov16x,r6_imm16,SpriteArrayRam	;Ram
	NSCall nsDrawArray+regRR 			;SpriteArray
	
	;dbw bsrj,drawpaddle

	

	dbbw movx,r0_addr16,soundbyte
	advcall achibisound+regRR
	dbbw clrx,addr16_r0,soundbyte
	
	
	db pl4b

	;db ph4b
	;dbb movi,' '
	;advcall aprintchar
	;db pl4b

	
	
	
	dbbw movx,r0_addr16,gametick
	db incb
	dbbw stox,r0_addr16,gametick

	dbbw andx,r0_addr16,gamespeed

	dbb bnei,noballmove-lbl65191
lbl65191
	dbbw mov16x,r2_addr16,ballmove
	dbw bsrj,moveball-VramBase
noballmove:

	dbw bsrj,getplayerpaddlede-VramBase

	advcall areadjoystick
	dbb movx,r2_r0
	dbw bsrj,processpaddle-VramBase

 	dbbw sto16x,r6_addr16,playerpaddle
	dbw bsrj,getcpupaddlede-VramBase

	dbbw movx,r0_addr16,gametick
	dbbw andx,r0_addr16,gameai

	dbb bnei,cpudecided-lbl61257
lbl61257

	dbbb movx,r2_imm8,%11111111	;nomove
	dbbw movx,r0_addr16,ballpos
	dbb subi,1
	dbb cmpz,r4
	dbb beqi,cpudecided-lbl43064
lbl43064
	dbb bcsi,cpuup-lbl27499
lbl27499
	dbbb movx,r2_imm8,%11111101
	dbb brai,cpudecided-lbl36249
lbl36249

cpuup:
	dbbb movx,r2_imm8,%11111110

cpudecided:
	dbw bsrj,processpaddle-VramBase

	dbbw mov16x,addr16_r6,cpupaddle

	dbbw movx,r0_addr16,cpuscore
	dbbw orrx,r0_addr16,playerscore
	dbb cmpi,8
	dbw bcsj,gameloop-VramBase
	
	
	
	dbbw mov16x,r6_imm16,strgameover-VramBase
	dbbw mov16x,r4_imm16,$0608
	advcall aprintseq
	advcall awaitforfire
	dbw braj,newgame-VramBase

	
getplayerpaddlede:
	dbbw mov16x,r4_addr16,playerpaddle
	db rtsb

getcpupaddlede:
	dbbw mov16x,r4_addr16,cpupaddle
	db rtsb

	
moveball:
	dbbwb movx,addr16_imm8,soundbyte,%10100000
	dbbw mov16x,r6_addr16,playerpaddle
	
	;dbbb movx,r0_zeropg,r5
	;dbb cmpi,1*4
	dbbbb cmpx,zeropg_imm8,r5,1*4-1
	
	dbb bnei,noplayerpaddlehit-lbl50130
lbl50130

	dbw bsrj,paddletest-VramBase
	dbb bcci,noplayerpaddlehit-lbl28645
lbl28645
	dbw bsrj,cpuscores-VramBase		;cs=hit


noplayerpaddlehit:
	dbbw mov16x,r6_addr16,cpupaddle

	dbbbb cmpx,zeropg_imm8,r5,18*4+1
	
	dbb bnei,nocpupaddlehit-lbl7460
lbl7460
	dbw bsrj,paddletest-VramBase
	dbb bcci,nocpupaddlehit-lbl16183
lbl16183
	dbw bsrj,playerscores-VramBase

	
nocpupaddlehit:
	dbbb addx,zeropg_r3,r5
	dbb  addx,r4_r2		;update ball ypos
	dbbb cmpx,r4_imm8,1*4			;hit top wall
	dbb bnei,lbl5063-lbl23676
lbl23676
	dbw bsrj,flipy-VramBase
lbl5063
	dbbb cmpx,r4_imm8,16*4	;hit bottom wall
	dbb bnei,lbl16101-lbl21583
lbl21583
	dbw bsrj,flipy-VramBase
lbl16101
 	dbbw sto16x,r4_addr16,ballpos		;Old cursor pos
 	dbbw sto16x,r2_addr16,ballmove	
	db rtsb

paddletest:	;carry=missed paddle
	dbb movx,r0_r4
	dbb cmpz,r6
	dbb bcsi,paddlemiss-lbl22097
lbl22097
	dbb subi,3*4
	dbb cmpz,r6
	dbb bcci,paddlemiss-lbl59932
lbl59932
	dbw bsrj,flipx-VramBase

	dbbwb movx,addr16_imm8,soundbyte,%01000000
	dbb orrz,r0	;clear carry
	db rtsb

paddlemiss:
	dbbwb movx,addr16_imm8,soundbyte,%01110000
	dbbb movx,rf_imm8,3
	db rtsb

cpuscores:
	dbbw incx,addr16_r0,cpuscore
	dbw bsrj,rezeroball-VramBase
	dbw bsrj,ShowScores-VramBase							;ShowScores
	db rtsb

playerscores:
	dbbw incx,addr16_r0,playerscore
	dbw bsrj,ShowScores-VramBase							;ShowScores

rezeroball:
	dbbw mov16x,r4_imm16,$0a08*4

flipx:
	dbb negz,r3
	db rtsb

flipy:
	dbb negz,r2
	db rtsb
	

processpaddle:
	dbb mov16x,r6_r4

	dbbw mov16x,r4_imm16,$010e*4
	dbb movx,r0_r6
		advcall ajoyaxis
		advcall arangelimit
	dbb movx,r6_r0
	db rtsb

readmask:
	dbbbb movx,zeropg_imm8,r5,0
	dbb movx,r4_r0
	dbbw add16x,r4_imm16,masks-VramBase
	dbb movx,r0_atr4
	db rtsb
	
ShowScores:
	db ph4b
		dbbw mov16x,r4_imm16,$0011
		dbbw movx,r0_addr16,playerscore
		advcall ashowdecimal+regRR

		dbbw mov16x,r4_imm16,$1111
		dbbw movx,r0_addr16,cpuscore
		advcall ashowdecimal+regRR
	db pl4b
	db rtsb

;Speed masks for ball and AI	
Masks:	dc.b %00000111,%00000011,%00000001,%00000000


strGameOver:dc.b 'Game Over',255
strStart:	dc.b 'Sprong - Sprite Pong!',253,255

strSpeed:	dc.b 253,'Speed:',255
strAi:		dc.b 253,'AI:',255

strWall:	 dc.b $B3,'-',253,$F1	;253=Newline (Xpos=0) &F1= Ypos=17
			 dc.b $B3,'-',255		;&B3=18 char H strip

	
vm_traps: 	dw ((ProgramLaunch-TestProgram)+VM_ProgLoadAddr)

	align 13
vm_AddressRemapTable:	;16 bit pointers (ChibiVM)
	dc.l HSprites			;0
	dc.l SpriteArrayRam 	;1
	dc.l SpriteData_Bat1	;2 SpritePointer
	dc.l SpriteData_Bat2	;3 SpritePointer
	dc.l SpriteData_Ball	;4 SpritePointer
	dc.l SpriteArray 	;5
	even
	

SpriteArrayAlt:			;32 bit pointers 
	dc.w 3		;Count
	dc.w $4040
	dc.l SpriteData_Bat1
	dc.w $6060
	dc.l SpriteData_Bat2
	dc.w $A0A0
	dc.l SpriteData_Ball	
	
SpriteArray:
	dc.b 3		;Count	
	dw $7080	;XXYY
		dc.b 2,0	;SpritePointer (SpriteData_Bat1)
	dw $9080	;XXYY
		dc.b 3,0	;SpritePointer (SpriteData_Bat2)
	dw $8080	;XXYY
		dc.b 4,0	;SpritePointer (SpriteData_Ball)
	
	even  ;*** WARNING - COUNT WILL MEAN ARRAY is ODD ALIGNED! ***
	
	
	
	ifd BuildGEN
SpriteData_Bat2:	
SpriteData_Bat1:
		dc.b 1,3		;Width in sprites , Height in sprites
		dc.b %0010,0 	;Sprite WidthHeight, Spacer
		dc.w $0400,$0401,$0402	;TileNumber/Palette/Priority
	
SpriteData_Ball:
		dc.b 1,1		;Width in sprites , Height in sprites
		dc.b %000,0 	;Sprite WidthHeight, Spacer
		dc.w $0403		;TileNumber/Palette/Priority
	endif
	
	
	
	ifd BuildNEO
SpriteData_Bat2:	
SpriteData_Bat1:
		dc.b 1,2		;W,H
		dc.w $0FFF		;Shrn
			; Tile,PAL  ,Tile ,PAL
		dc.w $2300,$0100,$2301,$0100
	
SpriteData_Ball:
		dc.b 1,1		;W,H
		dc.w $0FFF		;Shrnk
			; Tile,PAL
		dc.w $2302,$0100
	endif
	
	
	ifd BuildX68
SpriteData_Bat2:	
SpriteData_Bat1:
		dc.b 1,2		;W,H
		dc.b 3,0 			;Priority, 0=Spacer
		dc.w $0000,$0001	;Sprite Pattern Number
	
SpriteData_Ball:
		dc.b 1,1		;W,H
		dc.b 3,0 			;Priority, 0=Spacer
		dc.w $0002			;Sprite Pattern Number
		
HspriteCount: dc.b 0		
HspriteLimit: dc.b 0		
		
	endif
	
	
;XOR format Object Definition

	ifnd SpriteData_Bat1	
		even
SpriteData_Bat2:	
SpriteData_Bat1:
		dc.b 1,3		;W,H
		dc.w 0,1,2		;Pattern Numbers
	
SpriteData_Ball:
		dc.b 1,1		;W,H
		dc.w 3			;Pattern Numbers
	endif
	
		
	even

	
TestProgram_End:		
	
HSprites:
	ifd BuildSQL
		incbin "\ResALL\Reikou\Sprong\SQL_Sprites.RAW"
	endif
	ifd BuildAMI
		incbin "\ResALL\Reikou\Sprong\AMI_Sprites.RAW"
	endif
	ifd BuildAST
		incbin "\ResALL\Reikou\Sprong\AMI_Sprites.RAW"
	endif
	ifd BuildGEN
		incbin "\ResALL\Reikou\Sprong\GEN_Sprites.RAW"
	endif
	ifd BuildX68
		incbin "\ResALL\Reikou\Sprong\X68_Sprites.RAW"
	endif
HSprites_end:	
	
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
	include "\SrcALL\ChibiVm_CPU.asm"		
	
	even
	include "core.asm"
	include "footer.asm"
	
	
	;Variables for our Emulator

