


VscreenMinX equ 64		;Top left of visible screen in logical co-ordinates
VscreenMinY equ 80

VscreenWid equ 128		;Visible Screen Size in logical units
VscreenHei equ 96

vmAddressRemap_BigEndian equ 1			;Little endian calculations won't work due to relocatable code

	

;compile with option: VASM GEN

	include "sources/ChibiAdventure/header.asm"
	
	include "srcall/ChibiVm_InstSet.asm"
	include "srcall/BasicMacros.asm"

	
	
VM_ProgLoadAddr equ $400	


	ifd BuildAST
		and.l  #$FFFF0000,(VM_RamBaseAddr)	;Ensure VM ram ends $????0000
	endif
	
	ifnd VM_RamBase
		and.l  #$FFFF0000,(VM_RamBaseAddr)	;Ensure VM ram ends $????0000
	endif

	
	move.l #HSprites,a3
	jsr NativeSpr_Init

	move.l #SpriteArray,a3
	jsr NativeSpr_DrawArray
	
	;jsr nativespr_hideall
	
	jmp *
	
	
	jsr ChibiVM_Init

	
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
	
	
	
NativeSpriteCall:
	move.l #vecNS,a6
	jmp ChibiVM_VectorCall

	
nsInit equ 0	
nsDraw equ 1
nsDrawExtra equ 2
nsDrawArray equ 3
nsHide equ 4
nsClearUnused equ 5
nsHideAll equ 6
	
vecNS:
	dc.l NativeSpr_InitReiKou ;dw NativeSpr_InitReiKou	;0
	dc.l DummySyscall ;dw NativeSpr_Draw	;1
	dc.l DummySyscall ;dw NativeSpr_DrawExtra ;2
	dc.l NativeSpr_DrawArrayReiKou ;dw NativeSpr_DrawArrayReiKou ;3
	dc.l DummySyscall ;dw NativeSpr_Hide ;4
	dc.l DummySyscall ;dw NativeSpr_ClearUnused ;5
	dc.l nativespr_hideAll_Reikou
	
	include "SrcAMI/V1_NativeSprite.asm"	;Put before Adventure Engine inc
	
	include "../ChibiVM/Multiplatform_MonitorA.asm"
	include "sources/ChibiAdventure/ChibiVM_AdventureEngine.asm"
	include "sources/ChibiVM/ChibiVM_Host.asm"
	
	
	
	;rorg $10000	;Needed for some reason - somethings messing up the next org otherwise
		



	;rorg $10000+VM_ProgLoadAddr
	
	

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

	
		
ballpos equ			16
ballmove equ		18
PlayerPaddle equ	20
CpuPaddle equ		22
PlayerScore equ		24
CpuScore equ		25
GameTick equ		26
GameSpeed equ		27		
GameAI equ			28
SoundByte equ		29 

ProgramLaunch:

	;dbbw mov16x,r6_imm16,0
	;NSCall nsInit 	
		
	;dbbw mov16x,r6_imm16,1
	;NSCall nsDrawArray+regRR 			;SpriteArray
;                                     

;                                     newgame:
newgame:

	;advcall acls
	;NSCall nsHideAll
	
;                                     	ld hl,$0000
	dbbw mov16x,r6_imm16,$0000
;                                     titlescreen:
titlescreen:
;                                     	call pause50
	advcall apause50
;                                     	ld de,$0000
	dbbw mov16x,r4_imm16,$0000
;                                     	push hl
	db ph6b
;                                     		ld hl,strstart
	dbbw mov16x,r6_imm16,(strstart-VramBase)
;                                     		call printseq	
	advcall aprintseq
	
;                                     		ld hl,strspeed
	dbbw mov16x,r6_imm16,(strspeed-VramBase)
;                                     		call printseq	
	advcall aprintseq
;                                     	pop hl
	db pl6b
;                                     	ld a,h
	dbbb movx,r0_zeropg,r7
;                                     	call showdecimal
	advcall ashowdecimal
;                                     

;                                     	push hl
	db ph6b
;                                     		ld hl,strai
	dbbw mov16x,r6_imm16,(strai-VramBase)
;                                     		call printseq	
	advcall aprintseq
;                                     	pop hl
	db pl6b
;                                     	ld a,l
	dbb movx,r0_r6
;                                     	call showdecimal
	advcall ashowdecimal
;                                     

;                                     	call readjoystick
	advcall areadjoystick
;                                     	ld c,a
	dbb movx,r2_r0
;                                     

;                                     	ld de,$0004		;range
	dbbw mov16x,r4_imm16,$0004
;                                     	ld a,l
	dbb movx,r0_r6
;                                     	call joyaxis		;up/down
	advcall ajoyaxis
;                                     	call rangelimit	
	advcall arangelimit
;                                     	ld l,a
	dbb movx,r6_r0
;                                     	ld a,h
	dbbb movx,r0_zeropg,r7
;                                     	call joyaxis		;left/right
	advcall ajoyaxis
;                                     	call rangelimit	
	advcall arangelimit
;                                     	ld h,a
	dbbb movx,zeropg_r0,r7
;                                     

;                                     	bit 0,c
	dbbb tstx,r2_imm8,1
	dbw bnej,(titlescreen-VramBase)
	
	
	
	
;                                     

;                                     	ld a,h
	dbbb movx,r0_zeropg,r7
;                                     	call readmask
	dbw bsrj,(readmask-VramBase)
;                                     	ld (gamespeed),a
	dbbw stox,r0_addr16,gamespeed
;                                     

;                                     	ld a,l
	dbb movx,r0_r6
;                                     	call readmask
	dbw bsrj,(readmask-VramBase)
;                                     	ld (gameai),a
	dbbw stox,r0_addr16,gameai
;                                     
	
;                                     	call rezeroball			;init ball pos (center)
	dbw bsrj,(rezeroball-VramBase)
;                                     	ld a,e
	dbb movx,r0_r4
;                                     	ld (ballpos),a
	dbbw stox,r0_addr16,ballpos
;                                     	ld a,d
	dbbb movx,r0_zeropg,r5
;                                     	ld (ballpos+1),a
	dbbw stox,r0_addr16,ballpos+1
;                                     	

;                                     	ld a,$ff				;ball pos -1 = facing player
	dbb movi,$ff
;                                     	ld (ballmove),a
	dbbw stox,r0_addr16,ballmove
;                                     	ld (ballmove+1),a
	dbbw stox,r0_addr16,ballmove+1
;                                     
	
;                                     	ld a,6
	dbb movi,6
;                                     	ld (playerpaddle),a		;ypos
	dbbw stox,r0_addr16,playerpaddle
;                                     	ld (cpupaddle),a
	dbbw stox,r0_addr16,cpupaddle
;                                     	

;                                     	ld a,0
	dbb movi,0
;                                     	ld (cpuscore),a
	dbbw stox,r0_addr16,cpuscore
;                                     	ld (playerscore),a
	dbbw stox,r0_addr16,playerscore
;                                     		

;                                     	ld (playerpaddle+1),a	;cpos
	dbbw stox,r0_addr16,playerpaddle+1
;                                     	ld a,19
	dbb movi,19
;                                     	ld (cpupaddle+1),a
	dbbw stox,r0_addr16,cpupaddle+1
;                                     

;                                     	call cls
	advcall acls
;                                     	ld hl,strwall
	dbbw mov16x,r6_imm16,(strwall-VramBase)
;                                     	call printseq			;draw walls
	advcall aprintseq
;                                     

;                                     	

;                                     gameloop:
gameloop:
;                                     	ld a,(ballpos)				;de=ball pos x,y
	dbbw movx,r0_addr16,ballpos
;                                     	ld e,a
	dbb movx,r4_r0
;                                     	ld a,(ballpos+1)
	dbbw movx,r0_addr16,ballpos+1
;                                     	ld d,a
	dbbb movx,zeropg_r0,r5
;                                     	push de
	db ph4b
;                                     		ld a,'o'
	dbb movi,'o'
;                                     		call printchar			;draw ball
	advcall aprintchar
;                                     

;                                     

;                                     		call getplayerpaddlede
	dbw bsrj,(getplayerpaddlede-VramBase)
;                                     		call drawpaddle			;draw player paddle
	dbw bsrj,(drawpaddle-VramBase)
;                                     

;                                     		call getcpupaddlede
	dbw bsrj,(getcpupaddlede-VramBase)
;                                     		call drawpaddle			;draw cpu paddle
	dbw bsrj,(drawpaddle-VramBase)
;                                     

;                                     		ld de,$0011
	dbbw mov16x,r4_imm16,$0011
;                                     		ld a,(playerscore)		;show player score
	dbbw movx,r0_addr16,playerscore
;                                     		call showdecimal
	advcall ashowdecimal
;                                     

;                                     		ld de,$1111
	dbbw mov16x,r4_imm16,$1111
;                                     		ld a,(cpuscore)			;show cpu score
	dbbw movx,r0_addr16,cpuscore
;                                     		call showdecimal
	advcall ashowdecimal
;                                     	

;                                     		ld a,(soundbyte)
	dbbw movx,r0_addr16,soundbyte
;                                     		call chibisound			;play sound
	advcall achibisound
;                                     	

;                                     		call pause50			;wait a bit
	advcall apause50
;                                     

;                                     		ld a,0
	dbb movi,0
;                                     		ld (soundbyte),a
	dbbw stox,r0_addr16,soundbyte
;                                     	pop de
	db pl4b
;                                     	push de
	db ph4b
;                                     		ld a,' '
	dbb movi,' '
;                                     		call printchar		;remove ball
	advcall aprintchar
;                                     	pop de
	db pl4b
;                                     

;                                     	ld a,(gamespeed)			;l=game speed mask
	dbbw movx,r0_addr16,gamespeed
;                                     	ld l,a
	dbb movx,r6_r0
;                                     

;                                     	ld a,(ballmove)				;bc=ball move x,y
	dbbw movx,r0_addr16,ballmove
;                                     	ld c,a
	dbb movx,r2_r0
;                                     	ld a,(ballmove+1)
	dbbw movx,r0_addr16,ballmove+1
;                                     	ld b,a
	dbb movx,r3_r0
;                                     	

;                                     	ld a,(gametick)
	dbbw movx,r0_addr16,gametick
;                                     	inc a
	db incb
;                                     	ld (gametick),a
	dbbw stox,r0_addr16,gametick
;                                     	and l						;move speed mask
	dbb andz,r6
;                                     	call z,moveball				;update ball pos
	dbb bnei,3
	dbw bsrj,(moveball-VramBase)
lbl53141
;                                     

;                                     	call getplayerpaddlede
	dbw bsrj,(getplayerpaddlede-VramBase)
;                                     	

;                                     	call readjoystick
	advcall areadjoystick
;                                     	ld c,a
	dbb movx,r2_r0
;                                     	call processpaddle			;move paddle from player input
	dbw bsrj,(processpaddle-VramBase)
;                                     	

;                                     	ld a,l
	dbb movx,r0_r6
;                                     	ld (playerpaddle),a
	dbbw stox,r0_addr16,playerpaddle
;                                     	ld a,h
	dbbb movx,r0_zeropg,r7
;                                     	ld (playerpaddle+1),a
	dbbw stox,r0_addr16,playerpaddle+1
;                                     

;                                     	call getcpupaddlede
	dbw bsrj,(getcpupaddlede-VramBase)
;                                     	

;                                     	ld a,(gameai)
	dbbw movx,r0_addr16,gameai
;                                     	ld l,a
	dbb movx,r6_r0
;                                     

;                                     	ld a,(gametick)
	dbbw movx,r0_addr16,gametick
;                                     	and l			;make cpu dumber
	dbb andz,r6
;                                     	jr nz,cpudecided
	dbw bnej,(cpudecided-VramBase)
;                                     

;                                     	ld c,%11111111		;nomove
	dbbb movx,r2_imm8,%11111111
;                                     

;                                     	ld a,(ballpos)
	dbbw movx,r0_addr16,ballpos
;                                     	sub 1
	dbb subi,1
;                                     	cp e
	dbb cmpz,r4
;                                     	jr z,cpudecided	;no move
	dbw beqj,(cpudecided-VramBase)
;                                     

;                                     	jr c,cpuup		;move up
	dbw bcsj,(cpuup-VramBase)
;                                     	ld c,%11111101		;move down
	dbbb movx,r2_imm8,%11111101
;                                     	jr cpudecided
	dbb brai,cpudecided-lbl33183
lbl33183
;                                     cpuup:
cpuup:
;                                     	ld c,%11111110	
	dbbb movx,r2_imm8,%11111110
;                                     cpudecided:
cpudecided:
;                                     	call processpaddle		;move paddle from cpu ai
	dbw bsrj,(processpaddle-VramBase)
;                                     	

;                                     	ld a,l
	dbb movx,r0_r6
;                                     	ld (cpupaddle),a
	dbbw stox,r0_addr16,cpupaddle
;                                     	ld a,h
	dbbb movx,r0_zeropg,r7
;                                     	ld (cpupaddle+1),a
	dbbw stox,r0_addr16,cpupaddle+1
;                                     

;                                     	ld a,(cpuscore)
	dbbw movx,r0_addr16,cpuscore
;                                     	ld hl,playerscore
	dbbw mov16x,r6_imm16,playerscore
;                                     	or (hl)
	dbb orrx,r0_atr6
;                                     	cp 8
	dbb cmpi,8
;                                     	jp c,gameloop		;anyone reached 8 points?
	dbw bcsj,(gameloop-VramBase)
;                                     

;                                     	ld hl,strgameover
	dbbw mov16x,r6_imm16,(strgameover-VramBase)
;                                     	ld de,$0608
	dbbw mov16x,r4_imm16,$0608
;                                     	call printseq
	advcall aprintseq
;                                     

;                                     	call waitforfire
	advcall awaitforfire
;                                     	jp newgame
	dbw braj,(newgame-VramBase)
;                                     

;                                     	

;                                     getplayerpaddlede:
getplayerpaddlede:
;                                     	ld a,(playerpaddle)		;could just use ld de,(playerpaddle) on non gb
	dbbw movx,r0_addr16,playerpaddle
;                                     	ld e,a
	dbb movx,r4_r0
;                                     	ld a,(playerpaddle+1)
	dbbw movx,r0_addr16,playerpaddle+1
;                                     	ld d,a
	dbbb movx,zeropg_r0,r5
;                                     	ret	
	db rtsb
;                                     

;                                     	

;                                     getcpupaddlede:
getcpupaddlede:
;                                     	ld a,(cpupaddle)		;could just use ld de,(cpupaddle) on non gb
	dbbw movx,r0_addr16,cpupaddle
;                                     	ld e,a
	dbb movx,r4_r0
;                                     	ld a,(cpupaddle+1)
	dbbw movx,r0_addr16,cpupaddle+1
;                                     	ld d,a
	dbbb movx,zeropg_r0,r5
;                                     	ret	
	db rtsb
;                                     

;                                     	

;                                     moveball:
moveball:
;                                     	ld a,%10100000
	dbb movi,%10100000
;                                     	ld (soundbyte),a
	dbbw stox,r0_addr16,soundbyte
;                                     

;                                     	ld a,(playerpaddle)
	dbbw movx,r0_addr16,playerpaddle
;                                     	ld l,a
	dbb movx,r6_r0
;                                     	ld a,(playerpaddle+1)
	dbbw movx,r0_addr16,playerpaddle+1
;                                     	ld h,a
	dbbb movx,zeropg_r0,r7
;                                     	

;                                     	ld a,d		
	dbbb movx,r0_zeropg,r5
;                                     	cp 1					;hit player paddle
	dbb cmpi,1
;                                     	jr nz,noplayerpaddlehit
	dbw bnej,(noplayerpaddlehit-VramBase)
;                                     	call z,paddletest
	dbb bnei,3
	dbw bsrj,(paddletest-VramBase)
lbl30054
;                                     	call c,cpuscores		;carry=missed paddle
	dbb bcci,3
	dbw bsrj,(cpuscores-VramBase)
lbl63924
;                                     noplayerpaddlehit:
noplayerpaddlehit:
;                                     

;                                     	ld a,(cpupaddle)
	dbbw movx,r0_addr16,cpupaddle
;                                     	ld l,a
	dbb movx,r6_r0
;                                     	ld a,(cpupaddle+1)
	dbbw movx,r0_addr16,cpupaddle+1
;                                     	ld h,a
	dbbb movx,zeropg_r0,r7
;                                     	ld a,d	
	dbbb movx,r0_zeropg,r5
;                                     	cp 18					;hit cpu paddle
	dbb cmpi,18
;                                     	jr nz,nocpupaddlehit
	dbw bnej,(nocpupaddlehit-VramBase)
;                                     	call z,paddletest
	dbb bnei,3
	dbw bsrj,(paddletest-VramBase)
lbl22357
;                                     	call c,playerscores
	dbb bcci,3
	dbw bsrj,(playerscores-VramBase)
lbl32009
;                                     nocpupaddlehit:
nocpupaddlehit:
;                                     

;                                     	ld a,d
	dbbb movx,r0_zeropg,r5
;                                     	add b			;update ball xpos
	dbb addz,r3
;                                     	ld d,a	
	dbbb movx,zeropg_r0,r5
;                                     

;                                     	ld a,e
	dbb movx,r0_r4
;                                     	add c			;update ball ypos
	dbb addz,r2
;                                     	ld e,a
	dbb movx,r4_r0
;                                     	

;                                     	cp 1			;hit top wall
	dbb cmpi,1
;                                     	call z,flipy
	dbb bnei,3
	dbw bsrj,(flipy-VramBase)
lbl7477
;                                     	cp 16			;hit bottom wall
	dbb cmpi,16
;                                     	call z,flipy
	dbb bnei,3
	dbw bsrj,(flipy-VramBase)
lbl34204
;                                     

;                                     	ld a,e
	dbb movx,r0_r4
;                                     	ld (ballpos),a
	dbbw stox,r0_addr16,ballpos
;                                     	ld a,d
	dbbb movx,r0_zeropg,r5
;                                     	ld (ballpos+1),a
	dbbw stox,r0_addr16,ballpos+1
;                                     	

;                                     	ld a,c
	dbb movx,r0_r2
;                                     	ld (ballmove),a
	dbbw stox,r0_addr16,ballmove
;                                     	ld a,b
	dbb movx,r0_r3
;                                     	ld (ballmove+1),a
	dbbw stox,r0_addr16,ballmove+1
;                                     	ret
	db rtsb
;                                     

;                                     	

;                                     paddletest:		;carry=missed paddle
paddletest:
;                                     	ld a,e
	dbb movx,r0_r4
;                                     	cp l
	dbb cmpz,r6
;                                     	jr c,paddlemiss
	dbw bcsj,(paddlemiss-VramBase)
;                                     	sub 3
	dbb subi,3
;                                     	cp l
	dbb cmpz,r6
;                                     	jr nc,paddlemiss
	dbw bccj,(paddlemiss-VramBase)
;                                     	call flipx
	dbw bsrj,(flipx-VramBase)
;                                     

;                                     	ld a,%01000000
	dbb movi,%01000000
;                                     	ld (soundbyte),a
	dbbw stox,r0_addr16,soundbyte
;                                     	or a		;clear carry
	dbb orrz,r0
;                                     	ret
	db rtsb
;                                     	

;                                     	

;                                     paddlemiss:
paddlemiss:
;                                     	ld a,%01110000
	dbb movi,%01110000
;                                     	ld (soundbyte),a
	dbbw stox,r0_addr16,soundbyte
;                                     	scf		;set carry
	dbbb movx,rF_imm8,3
;                                     	ret
	db rtsb
;                                     	

;                                     cpuscores:
cpuscores:
;                                     	ld hl,cpuscore
	dbbw mov16x,r6_imm16,cpuscore
;                                     	inc (hl)
	dbb incx,atr6_atr6
;                                     	call rezeroball
	dbw bsrj,(rezeroball-VramBase)
;                                     	ret
	db rtsb
;                                     

;                                     	

;                                     playerscores:
playerscores:
;                                     	ld hl,playerscore
	dbbw mov16x,r6_imm16,playerscore
;                                     	inc (hl)
	dbb incx,atr6_atr6
;                                     					;rezero ball

;                                     rezeroball:
rezeroball:
;                                     	ld de,$0a08
	dbbw mov16x,r4_imm16,$0a08
;                                     					;flip direction of ball

;                                     flipx:	
flipx:
;                                     	ld a,b
	dbb movx,r0_r3
;                                     	cpl ;neg
	dbb xori,255
;                                     	inc a
	db incb
;                                     	ld b,a
	dbb movx,r3_r0
;                                     	ret
	db rtsb
;                                     

;                                     	

;                                     flipy:
flipy:
;                                     	ld a,c
	dbb movx,r0_r2
;                                     	cpl ;neg
	dbb xori,255
;                                     	inc a
	db incb
;                                     	ld c,a
	dbb movx,r2_r0
;                                     	ret
	db rtsb
;                                     

;                                     	

;                                     drawpaddle:
drawpaddle:
;                                     	ld hl,strpaddle
	dbbw mov16x,r6_imm16,(strpaddle-VramBase)
;                                     	call printseq
	advcall aprintseq
;                                     	ret
	db rtsb
;                                     

;                                     	

;                                     processpaddle:
processpaddle:
;                                     	push de
	db ph4b
;                                     	push bc
	db ph2b
;                                     		ld hl,strblankpaddle
	dbbw mov16x,r6_imm16,(strblankpaddle-VramBase)
;                                     		call printseq
	advcall aprintseq
;                                     	pop bc
	db pl2b
;                                     	pop hl
	db pl6b
;                                     

;                                     	ld de,$010f
	dbbw mov16x,r4_imm16,$010f
;                                     	ld a,l
	dbb movx,r0_r6
;                                     	call joyaxis		;up/down
	advcall ajoyaxis
;                                     	call rangelimit	
	advcall arangelimit
;                                     	ld l,a
	dbb movx,r6_r0
;                                     	ret
	db rtsb
;                                     

;                                     	

;                                     readmask:
readmask:
;                                     	push hl
	db ph6b
;                                     		ld hl,masks
	dbbw mov16x,r6_imm16,(masks-VramBase)
;                                     		ld d,0
	dbbbb movx,zeropg_imm8,r5,0
;                                     		ld e,a
	dbb movx,r4_r0
;                                     		add hl,de
	dbb add16x,r6_r4
;                                     		ld a,(hl)
	dbb movx,r0_atr6
;                                     	pop hl
	db pl6b
	db rtsb
;                                     

;Speed masks for ball and AI	
Masks:	dc.b %00000111,%00000011,%00000001,%00000000


strGameOver:dc.b 'Game Over',255
strStart:	dc.b 'Pongo!',253,255

strSpeed:	dc.b 253,'Speed:',255
strAi:		dc.b 253,'AI:',255

strWall:	 dc.b $B3,'-',253,$F1	;253=Newline (Xpos=0) $F1= Ypos=17
			 dc.b $B3,'-',255		;$B3=18 char H strip

strPaddle: 	 	 dc.b $C2,'X',255 ;$C2=3 char V strip
strBlankPaddle:  dc.b $C2,' ',255

vm_traps: 	dw ((ProgramLaunch-TestProgram)+VM_ProgLoadAddr)

	
	align 13
vm_AddressRemapTable:
	;Address Remap Table
	;dlle 0
	dc.l HSprites
	dc.l SpriteArrayRK ;SpriteArray
	dc.l SpriteData_Magnify
	
	even


SpriteArray2:
	dc.w 1		;Count
	dc.w $4040
	dc.l SpriteData_Magnify
	dc.w $6060
	dc.l SpriteData_Magnify
	dc.w $A0A0
	dc.l SpriteData_Magnify
	
	
SpriteArray:
	dc.w 5		;Count
	dc.b $50-4,64-4
	dc.l SpriteData_Magnify
	dc.b $50-4,64+120
	dc.l SpriteData_Magnify
	dc.b 80,80
	dc.l SpriteData_Magnify
	dc.b 81,81
	dc.l SpriteData_Magnify
	dc.b 80+96-8,80
	dc.l SpriteData_Magnify
	
	
SpriteArrayRK:
	db 3		;Count
	;dw $4040
	dw $8080
	dc.b 2,0;SpriteData_Magnify
	dw $8090
	dc.b 2,0;SpriteData_Magnify
	dw $B090
	dc.b 2,0;SpriteData_Magnify
	
	
	even

	
SpriteData_Magnify:	
	dc.b 4,4	;WH
	;Stretch,Tiles Down then across
	dc.w 0,1,2,3,4		;$FFFF=unused
	dc.w 5,6,7,8
	dc.w 9,10,11,12
	dc.w 13,14,15,16
	
	even
	
	;Hardware Sprite Patterns
HSprites:
	incbin "\ResALL\Reikou\AMI_Cursors.RAW"
HSprites_end:
	
TestProgram_End:		
	
	;ifd NeedReorg 
;		rorg $10000
;	endif 
	
;TestProgram:	
	;incbin "\ResAll\ChibiVM\NumberGuess.rom"
;TestProgram_End:		
	
	
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
VM_RamBase2:
		ds.b 65536*2
VM_HostRam:	
		ds.b 256
	endif
	
	even
	include "srcall/ChibiVm_CPU.asm"		
	
	even
	include "sources/ChibiAdventure/core.asm"
	include "sources/ChibiAdventure/footer.asm"
	
	
	;Variables for our Emulator

