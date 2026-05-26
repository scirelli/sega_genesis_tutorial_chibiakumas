NativeSpr_Multiplatform2Bitplane equ 1	;use GB style 2 bitplane / 4 color source data


UseCPIR equ 1


NativeSpr_ExtraBytes equ 4	;Bytes skipped after each sprite in the spritearray

GEN_BMPscreen equ 1


VscreenMinX equ 64		;Top left of visible screen in logical co-ordinates
VscreenMinY equ 80

VscreenWid equ 128		;Visible Screen Size in logical units
VscreenHei equ 96

;compile with option: VASM GEN

	include "header.asm"
	
	include "\SrcALL\ChibiVm_InstSet.asm"
	include "\SrcALL\BasicMacros.asm"

	ifd BuildAMI
	ifd NativeSpr_Multiplatform2Bitplane
AMI_NativeSprite_PatternOffset equ -1
	endif 
	endif 
	ifd BuildAST
	ifd NativeSpr_Multiplatform2Bitplane
AST_NativeSprite_PatternOffset equ -1
	endif 
	endif 
	
	ifd BuildSQL
		ifd NativeSpr_Multiplatform2Bitplane
SQL_NativeSprite_PatternOffset equ -1
		endif 
VM_RamBase equ $30000
VM_HostRam equ $003F000	;Variables for our Emulator
	endif
	
	ifd BuildNEO
		ifd NativeSpr_Multiplatform2Bitplane
NEO_NativeSprite_PatternOffset equ $237F
		endif 
VM_RamBase equ $100000
VM_HostRam	equ $10FE00	;Variables for our Emulator
NeedReorg equ 1
	endif
	
	ifd BuildGEN
		ifd NativeSpr_Multiplatform2Bitplane
GEN_NativeSprite_PatternOffset equ 1023
		endif 
VM_RamBase equ $00FF0000
VM_HostRam	equ $00FFFE00	;Variables for our Emulator
NeedReorg equ 1
	endif
	
	ifd BuildX68
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
	
	even

		
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	include "\SrcALL\V1_NativeSprite.asm"	
	even
	
	
	
	include "..\ChibiVM\Multiplatform_MonitorA.asm"
	include "AdventureEngine_PrintW.asm"
	include "AdventureEngineX_Monitor.asm"
	include "ChibiVM_AdventureEngineX.asm"	;Must come before  ChibiVM_AdventureEngine.asm
	include "\SrcALL\V1_GenericAnimator.asm"	;Must come before  ChibiVM_AdventureEngine.asm
	include "AdventureEngineX.asm"				;Must come before  ChibiVM_AdventureEngine.asm
	include "ChibiVM_AdventureEngine.asm"
	include "\Sources\ChibiVM\ChibiVM_Host.asm"

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
		; dbbww mov16x,addr16_imm16,$0014,$1234
		; dbbw mov16x,r4_imm16,$0010
		
		
		; dbbb mov16x,r2_AtR4PlIm,+4	;Get Frame+Animator 
		
		; dbbb mov16x,AtR4PlIm_r2,+6 	;Store updated Frame+Animator 

;		dbbw mov16x,r6_imm16,(WorldMap-VramBase)
;		dbb movx,r0_atr6
;		dbw bsrj,(WallTest-VramBase)

	;dbb SYSi,syscallLoadMultiReg		;This will be better for setting 3+ regs
	;db %01110000						;AF,BC,DE,HL mask
	;dw 256
	;dw (SpriteArrayRam-VM_RamBase)
	;dw (SpriteArray-VramBase)		;BC,DE,HL
	;AdvCall aDoLdir
	
	
	;dbbw mov16x,r4_imm16,(SpriteArrayRam-VM_RamBase)+1	;Pointer to first sprite data
	;dbbb mov16x,AtR4PlIm_r2,+4 	;Store updated Frame+Animator 
	
	;dc.b hltb
		
	dbb SYSi,syscallLoadMultiReg		;This will be better for setting 3+ regs
	db %01110000						;AF,BC,DE,HL mask
	dwww 256,(SpriteArrayRam-VM_RamBaseB),(SpriteArray-VramBase)	;BC,DE,HL
	;dwww $1111,$2222,$3333
	
	AdvCall aDoLdir
	
	
	
	
	
	dbbw mov16x,r6_imm16,(MyAnimators-VramBase)		;Init animator scripts
	AnimCall anAnimateInit
	
	dbbw mov16x,r6_imm16,SpritePatterns		;Sprite patterns
	dbbw mov16x,r2_imm16,16*SpritePatternSize	;ByteCount
	NSCall nsInit 
	
	dbbw mov16x,r4_imm16,0					;XY Pos
	dbbw mov16x,r6_imm16,(WorldMap-VramBase)
	advcall aprintseq						;Draw Worldmap
	
	;dbbw mov16x,r6_imm16,(SpriteArrayRam-VM_RamBase)	
	;NSCall nsDrawArray+regRR 		;Draw SpriteArray
	;dc.b hltb
	
	
TestLoop:	
	; dbbw mov16x,r4_imm16,((SpriteArrayRam-VM_RamBase)+1)	;Pointer to first sprite data
		; dbbb mov16x,r2_AtR4PlIm,+4	;Get Frame+Animator 
;		dbbw mov16x,r2_imm16,$1111
		; AnimCall anAnimateIX		;Animate this sprite
		; dbbb mov16x,AtR4PlIm_r2,+4 	;Store updated Frame+Animator 
		
		; dbbw mov16x,r6_imm16,(SpriteArrayRam-VM_RamBase)	
		; NSCall nsDrawArray+regRR 		;Draw SpriteArray
	; dbw braj,(TestLoop-VramBase)
	
	
	
	dbb movi,8								;Sprite count

	dbbw mov16x,r4_imm16,(SpriteArrayRam-VM_RamBaseB)+1	;Pointer to first sprite data
	
TestLoopB:		
	dc.b ph0b
		dbbw mov16x,r6_imm16,(WorldMap-VramBase);WorldMap		;For collision detection
	
		dbb clr16x,r2_r2
		dbbb movx,r2_AtR4PlIm,+0		;ypos
		dbbb subx,r2_imm8,VscreenMinY
		dbbb andx,r2_imm8,%11111100		;Ypos to bytes
		dbb lslz,r2
		dbb lslz,r2	 					;Ypos *16
		
		dbb add16x,r6_r2
		
		
		dbbb movx,r2_AtR4PlIm,1		;xpos
		dbbb subx,r2_imm8,(VscreenMinX-3)
		
		dbb lsrz,r2
		dbb lsrz,r2						;xpos to bytes
		dbb add16x,r6_r2	
		
		
	
		dbbb cmpx,atr6_imm8,'H'			;Reached home?
		dbw bnej,(NoHome-VramBase)
		dbbbw mov16x,AtR4PlIm_imm16,4,$0700	;Yes? Animator=7 tick=0
NoHome:

		
		dc.b clrz,r1					;Buildup for collisions %----RLDU
		
		dbb dec16z,r6				;Left of sprite
		
		
	ifd UseCPIR;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
;Use CPIR to detect walls, slower but more flexible	
	
		dbw bsrj,(WallTest-VramBase)			;Test collision
		dbw bnej,(NoBlockL-VramBase)
		dbbb orrx,r1_imm8,%00000100	;Wall on Left
NoBlockL:

		dbbw add16x,r6_imm16,2		;Right of sprite
		
		dbw bsrj,(WallTest-VramBase)			;Test collision
		dbw bnej,(NoBlockR-VramBase)
		dbbb orrx,r1_imm8,%00001000	;Wall on right
NoBlockR:

		dbbw add16x,r6_imm16,15		;Below Sprite
		
		dbw bsrj,(WallTest-VramBase)			;Test collision
		dbw bnej,(NoBlockD-VramBase)
		dbbb orrx,r1_imm8,%00000010	;Wall below
NoBlockD:

		dbbw add16x,r6_imm16,-32	;Above sprite
				
		dbw bsrj,(WallTest-VramBase)			;Test collision
		dbw bnej,(NoBlockU-VramBase)	
		dbbb orrx,r1_imm8,%00000001	;Wall above
NoBlockU:

	else ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
;This version does the same, however it uses two compares instead
; of CPIR, this is faster but more limiting
		
		dbbb cmpx,atr6_imm8,' '
		dbw beqj,(NoBlockL-VramBase)
		dbbb cmpx,atr6_imm8,'A'
		dbw bccj,(NoBlockL-VramBase)
		dbbb orrx,r1_imm8,%00000100
NoBlockL:

		dbbw add16x,r6_imm16,2
				
		dbbb cmpx,atr6_imm8,' '
		dbw beqj,(NoBlockR-VramBase)
		dbbb cmpx,atr6_imm8,'A'
		dbw bccj,(NoBlockR-VramBase)
		dbbb orrx,r1_imm8,%00001000
NoBlockR:

		dbbw add16x,r6_imm16,15
		
		dbbb cmpx,atr6_imm8,' '
		dbw beqj,(NoBlockD-VramBase)
		dbbb cmpx,atr6_imm8,'A'
		dbw bccj,(NoBlockD-VramBase)
		dbbb orrx,r1_imm8,%00000010
NoBlockD:

		dbbw add16x,r6_imm16,-32
		
		dbbb cmpx,atr6_imm8,' '
		dbw beqj,(NoBlockU-VramBase)
		dbbb cmpx,atr6_imm8,'A'
		dbw bccj,(NoBlockU-VramBase)
		dbbb orrx,r1_imm8,%00000001
		
NoBlockU:
	endif ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	
	;dbbb orrx,r1_imm8,%00001100
	dbbb movx,AtR4PlIm_r1,+7		;Move Collision map to spritedata+7
	
		dbbb mov16x,r2_AtR4PlIm,+4	;Get Frame+Animator 
		
		;dbw mov16i,$FF07			;Sample Speed override
		;AnimCall anAnimateIXIYcs
		
		AnimCall anAnimateIX		;Animate this sprite
		
		dbbb mov16x,AtR4PlIm_r2,+4 	;Store updated Frame+Animator 
		
		
		
		dbbw add16x,r4_imm16,8		;Move to next sprite data block
	dc.b pl0b
	
	dc.b decb							;Decrease sprite count and repeat
	dbw bnej,(TestLoopB-VramBase)
	
	
	
	
	dbbw mov16x,r6_imm16,(SpriteArrayRam-VM_RamBaseB)	
	NSCall nsDrawArray+regRR 		;Draw SpriteArray
	
	;advcall aWaitForFire
	
	dbbw incx,addr16_r0,(Timer_TicksOccured-VM_RamBaseB)	;Increment animation tickcount
	
	advcall aReadJoystick			;Read joystick
	
	dbbw orrx,r0_addr16,(SpriteArrayRam-VM_RamBaseB)+1+7	;Block directions based on
											; collisions on sprite o
	;dc.b movi,%11111110								
	dbbw mov16x,r6_imm16,(Case_JoyProcess-VramBase)
	AdvXCall axCaseBra				;branch to joystick processing routine
	
	dbw braj,(TestLoop-VramBase)				;Loop if no case match found

	
DoFire:
	dbbwb xorx,addr16_imm8,(SpriteArrayRam-VM_RamBaseB)+6,3	;Flip move direction
	dbw braj,(TestLoop-VramBase)
	
DoUp:
	dbbwb orrx,addr16_imm8,(SpriteArrayRam-VM_RamBaseB)+6,$04	;Switch to Jump L/R
	dbbwb movx,addr16_imm8,(SpriteArrayRam-VM_RamBaseB)+5,$00	;Frame to 0
	dbw braj,(TestLoop-VramBase)
	
DoDown:
	;dbbwb addx,addr16_imm8,SpriteArrayRam+1,3	;This would move player
	dbw braj,(TestLoop-VramBase)							; down (testcode)

DoLeft:
	dbbww mov16x,addr16_imm16,(SpriteArrayRam-VM_RamBaseB)+5,$0100 ;Switch to walkleft
	dbw braj,(TestLoop-VramBase)

DoRight:	
	dbbww mov16x,addr16_imm16,(SpriteArrayRam-VM_RamBaseB)+5,$0200 ;Switch to walkright
	dbw braj,(TestLoop-VramBase)


WallTest:
	dbb movx,r0_atr6	;Get block at (R6)
	dc.b ph6b
		dbbw mov16x,r6_imm16,(Walls-VramBase)	 ;Get list of walls 
		dbbw mov16x,r2_imm16,WallsEnd-Walls	;get count of walls
		AdvXCall axDoCpir	;compare R2 bytes from (R6) to R0
		;AdvXCall axMonitor
	dc.b pl6b					; Set Z=true if found ...  Z=false if not
	dc.b rtsb
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Walls:	
	dc.b '-',':','#'		;These will block the player if CPIR used
WallsEnd:	



WorldMap:
	dc.b '---------------',253	;16 bytes wide (15 chars + NL 253)
	dc.b ':             :',253
	dc.b ':             :',253
	dc.b ':             :',253
	dc.b ':      #      :',253
	dc.b ':-----------  :',253
	dc.b ':             :',253
	dc.b ':             :',253
	dc.b ':  -----------:',253
	dc.b ':             :',253
	dc.b ':             :',253
	dc.b ':-----------  :',253
	dc.b ':             :',253
	dc.b ':  H          :',253
	dc.b '---------------',253
	dc.b 255
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	align 4
MyAnimators:
	dc.l PlayerWalkL	;1
	dc.l PlayerWalkR	;2
	dc.l PlayerFlyL		;3
	dc.l PlayerFlyR		;4
	dc.l PlayerJumpL		;5
	dc.l PlayerJumpR		;6
	dc.l PlayerHome		;7
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;First byte is the 'Tick map' which defines when 
	;  the animation should update
PlayerWalkR:
	dc.b %00000000			;Anim Freq
	
	dc.b anmCondbra+cndTN,7,%00000010,1	;On floor?
		dc.b anmAddMsked,0,2,255				;Fall
	
	
	dbbw anmLD16,2,(SpriteData_WalkR1-VramBase)
	
	dc.b anmAddMsked,1,1,255				;Offset,Add,Andmask
	dbbw anmLD16,2,(SpriteData_WalkR2-VramBase)
	
	dc.b anmCondbra+cndTN,7,%00000010,1	;On floor?
		dc.b anmAddMsked,0,2,255				;Fall
	
	dc.b anmCndAnim+cndTN,7,%00001000,1
		
	dbbw anmLD16,2,(SpriteData_WalkR3-VramBase)
	dc.b anmEXTD,aEXTD_loop,0,0		;Anim # Frame

	
PlayerWalkL:
	dc.b %00000000			;Anim Freq
		dc.b anmCondbra+cndTN,7,%00000010,1	;On floor?
		dc.b anmAddMsked,0,2,255				;Fall
	
	dbbw anmLD16,2,(SpriteData_WalkL1-VramBase)
	
	dc.b anmAddMsked,1,-1,255				;Offset,Add,Andmask
	dbbw anmLD16,2,(SpriteData_WalkL2-VramBase)
	
	dc.b anmCondbra+cndTN,7,%00000010,1	;On floor?
		dc.b anmAddMsked,0,2,255				;Fall
		
	dc.b anmCndAnim+cndTN,7,%00000100,2
	
	dbbw anmLD16,2,(SpriteData_WalkL3-VramBase)
	dc.b anmEXTD,aEXTD_loop,0,0		;Anim # Frame

	
	
PlayerJumpR:
	dc.b %00000000			;Anim Freq
	dbbw anmLD16,2,(SpriteData_WalkR1-VramBase)
	dc.b anmAdd8d,0+16,-2,1				;Ychange, Xchange
	dbbw anmLD16,2,(SpriteData_WalkR2-VramBase)
	dc.b anmAdd8d,0+16,-2,1
	
	dc.b anmCndAnim+cndTN,7,%00001000,1	;hit wall?
	dc.b anmCndAnim+cndTN,7,%00000001,2	;Hit roof?
	
	dbbw anmLD16,2,(SpriteData_WalkR3-VramBase)
	dc.b anmAdd8d,0+16,-2,1
	dc.b anmEXTD,aEXTD_loop,0,0		;Anim # Frame

	
PlayerJumpL:
	dc.b %00000000			;Anim Freq
	dbbw anmLD16,2,(SpriteData_WalkL1-VramBase)
	dc.b anmAdd8d,0+16,-2,-1				;Ychange, Xchange
	dbbw anmLD16,2,(SpriteData_WalkL2-VramBase)
	dc.b anmAdd8d,0+16,-2,-1
	
	dc.b anmCndAnim+cndTN,7,%00001000,2	;hit wall?
	dc.b anmCndAnim+cndTN,7,%00000001,1	;Hit roof?
	
	dbbw anmLD16,2,(SpriteData_WalkL3-VramBase)
	dc.b anmAdd8d,0+16,-2,-1
	dc.b anmEXTD,aEXTD_loop,0,0		;Anim # Frame

	
PlayerFlyL:
	dc.b %00000000			;Anim Freq
	dc.b anmAdd8d+aEXT,0+16,-1,-2			;Ychange, Xchange
	dbbw anmLD16,2,(SpriteData_Fly2L-VramBase)
	dc.b anmAdd8d+aEXT,0+16,-1,-2
	dbbw anmLD16,2,(SpriteData_Fly1L-VramBase)
	dc.b anmAdd8d+aEXT,0+16,-1,-2
	dbbw anmLD16,2,(SpriteData_Fly3L-VramBase)
	dc.b anmAdd8d+aEXT,0+16,-1,-2
	dbbw anmLD16,2,(SpriteData_Fly1L-VramBase)
	dc.b anmCndAnim+cndTN,7,%00000100,4	;Hit roof?
	
	dc.b anmAdd8d+aEXT,0+16,1,-2			;Ychange, Xchange
	dbbw anmLD16,2,(SpriteData_Fly2L-VramBase)
	dc.b anmAdd8d+aEXT,0+16,1,-2
	dbbw anmLD16,2,(SpriteData_Fly1L-VramBase)
	dc.b anmAdd8d+aEXT,0+16,1,-2
	dbbw anmLD16,2,(SpriteData_Fly3L-VramBase)
	dc.b anmAdd8d+aEXT,0+16,1,-2
	dbbw anmLD16,2,(SpriteData_Fly1L-VramBase)
	dc.b anmCndAnim+cndTN,7,%00000100,4	;Hit roof?
		
	dc.b anmEXTD,aEXTD_loop,0,0		;Anim # Frame

PlayerFlyR:
	dc.b %00000000			;Anim Freq
	dc.b anmAdd8d+aEXT,0+16,-1,2
	dbbw anmLD16,2,(SpriteData_Fly2R-VramBase)
	dc.b anmAdd8d+aEXT,0+16,-1,2
	dbbw anmLD16,2,(SpriteData_Fly1R-VramBase)
	dc.b anmAdd8d+aEXT,0+16,-1,2
	dbbw anmLD16,2,(SpriteData_Fly3R-VramBase)
	dc.b anmAdd8d+aEXT,0+16,-1,2
	dbbw anmLD16,2,(SpriteData_Fly1R-VramBase)
	dc.b anmCndAnim+cndTN,7,%00001000,3	;Hit roof?
	
	dc.b anmAdd8d+aEXT,0+16,1,2
	dbbw anmLD16,2,(SpriteData_Fly2R-VramBase)
	dc.b anmAdd8d+aEXT,0+16,1,2
	dbbw anmLD16,2,(SpriteData_Fly1R-VramBase)
	dc.b anmAdd8d+aEXT,0+16,1,2
	dbbw anmLD16,2,(SpriteData_Fly3R-VramBase)
	dc.b anmAdd8d+aEXT,0+16,1,2
	dbbw anmLD16,2,(SpriteData_Fly1R-VramBase)
	dc.b anmCndAnim+cndTN,7,%00001000,3	;Hit roof?
	
	
	dc.b anmEXTD,aEXTD_loop,0,0		;Anim # Frame

PlayerHome:
	dc.b %00000000					;Anim Freq
	dbbw anmLD16,0,0				;Move sprite offscreen
	dc.b anmEXTD,aEXTD_halt,0,0		;Anim # Frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
;Case statement to test directions and branch to a VM routine

;For this use the Format is:
;   Command , Match , 16 bit address
	
Case_JoyProcess:
	dbbw srcBC+dstIm+cndEQ,%11101111,(DoFire-VramBase)
	dbbw srcBC+dstIm+cndEQ,%11111110,(DoUp-VramBase)
	dbbw srcBC+dstIm+cndEQ,%11111101,(DoDown-VramBase)
	dbbw srcBC+dstIm+cndEQ,%11111011,(DoLeft-VramBase)
	dbbw srcBC+dstIm+cndEQ,%11110111,(DoRight-VramBase)
	dc.b 0
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


SpriteArray:
	dc.b 8	;Count
	dw $5460
	dw (SpriteData_WalkL1-VramBase)	;XXYY,Sprite 5
	dc.b 0,1,0,0
	dw $4864
	dw (SpriteData_WalkL1-VramBase)	;XXYY,Sprite 6
	dc.b 0,2,0,0
	dw $5070
	dw (SpriteData_WalkL1-VramBase)	;XXYY,Sprite 1
	dc.b 0,2,0,0
	dw $6874
	dw (SpriteData_WalkL1-VramBase)	;XXYY,Sprite 2
	dc.b 0,1,0,0
	dw $6078
	dw (SpriteData_WalkL1-VramBase)	;XXYY,Sprite 3
	dc.b 0,2,0,0
	dw $707C
	dw (SpriteData_WalkL1-VramBase)	;XXYY,Sprite 4
	dc.b 0,2,0,0
	
	dw $6868
	dw (SpriteData_WalkL1-VramBase)	;XXYY,Sprite 7 
	dc.b 0,2,0,0
	dw $6458
	dw (SpriteData_Fly1L-VramBase)	;XXYY,Sprite 8
	dc.b 0,3,0,0
	

	
	
vm_traps: 	dw ((ProgramLaunch-TestProgram)+VM_ProgLoadAddr)

	align 13
vm_AddressRemapTable:	;16 bit pointers (ChibiVM)
	dc.l HSprites			;0
	dc.l SpriteArrayRam 	;1
	dc.l 0;SpriteData_Bat1	;2 SpritePointer
	dc.l 0;SpriteData_Bat2	;3 SpritePointer
	dc.l 0;SpriteData_Ball	;4 SpritePointer
	dc.l SpriteArray 	;5
	dc.l MyAnimators 	;6
	dc.l WorldMap		;7
	dc.l	0 ;8
	dc.l	0 ;9
	dc.l	0 ;10
	
	
	dc.l PlayerWalkL	;11
	dc.l PlayerWalkR	;12
	dc.l PlayerFlyL		;13
	dc.l PlayerFlyR		;14
	dc.l PlayerJumpL		;15
	dc.l PlayerJumpR		;16
	dc.l PlayerHome		;17
	even
	
	ifd NativeSpr_Multiplatform2Bitplane
	

SpriteData_WalkL1:
	dc.b 1,1		;Width,Height
	dc.b 1		;Tile patterns (0=Empty)
SpriteData_WalkL2:
	dc.b 1,1		;Width,Height
	dc.b 2		;Tile patterns (0=Empty)
SpriteData_WalkL3:
	dc.b 1,1		;Width,Height
	dc.b 3		;Tile patterns (0=Empty)
	
SpriteData_WalkR1:
	dc.b 1,1		;Width,Height
	dc.b 4		;Tile patterns (0=Empty)
SpriteData_WalkR2:
	dc.b 1,1		;Width,Height
	dc.b 5		;Tile patterns (0=Empty)
SpriteData_WalkR3:
	dc.b 1,1		;Width,Height
	dc.b 6		;Tile patterns (0=Empty)
	
SpriteData_Fly1L:
	dc.b 1,1		;Width,Height
	dc.b 7		;Tile patterns (0=Empty)
SpriteData_Fly2L:
	dc.b 1,1		;Width,Height
	dc.b 8		;Tile patterns (0=Empty)
SpriteData_Fly3L:
	dc.b 1,1		;Width,Height
	dc.b 9		;Tile patterns (0=Empty)
	
SpriteData_Fly1R:
	dc.b 1,1		;Width,Height
	dc.b 10		;Tile patterns (0=Empty)
SpriteData_Fly2R:
	dc.b 1,1		;Width,Height
	dc.b 11		;Tile patterns (0=Empty)
SpriteData_Fly3R:
	dc.b 1,1		;Width,Height
	dc.b 12		;Tile patterns (0=Empty)
	
	even
	
	else;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	ifd BuildGEN
SpriteData_WalkL1:
	dc.b 1,1		;Width,Height
	dc.b 0,0 ;WidthHeight attrib, empty
	dc.w 1+1023		;Tile patterns (0=Empty)
SpriteData_WalkL2:
	dc.b 1,1		;Width,Height
	dc.b 0,0 ;WidthHeight attrib, empty
	dc.w 2+1023		;Tile patterns (0=Empty)
SpriteData_WalkL3:
	dc.b 1,1		;Width,Height
	dc.b 0,0 ;WidthHeight attrib, empty
	dc.w 3+1023		;Tile patterns (0=Empty)
	
SpriteData_WalkR1:
	dc.b 1,1		;Width,Height
	dc.b 0,0 ;WidthHeight attrib, empty
	dc.w 4+1023		;Tile patterns (0=Empty)
SpriteData_WalkR2:
	dc.b 1,1		;Width,Height
	dc.b 0,0 ;WidthHeight attrib, empty
	dc.w 5+1023		;Tile patterns (0=Empty)
SpriteData_WalkR3:
	dc.b 1,1		;Width,Height
	dc.b 0,0 ;WidthHeight attrib, empty
	dc.w 6+1023		;Tile patterns (0=Empty)
	
SpriteData_Fly1L:
	dc.b 1,1		;Width,Height
	dc.b 0,0 ;WidthHeight attrib, empty
	dc.w 7+1023		;Tile patterns (0=Empty)
SpriteData_Fly2L:
	dc.b 1,1		;Width,Height
	dc.b 0,0 ;WidthHeight attrib, empty
	dc.w 8+1023		;Tile patterns (0=Empty)
SpriteData_Fly3L:
	dc.b 1,1		;Width,Height
	dc.b 0,0 ;WidthHeight attrib, empty
	dc.w 9+1023		;Tile patterns (0=Empty)
	
SpriteData_Fly1R:
	dc.b 1,1		;Width,Height
	dc.b 0,0 ;WidthHeight attrib, empty
	dc.w 10+1023		;Tile patterns (0=Empty)
SpriteData_Fly2R:
	dc.b 1,1		;Width,Height
	dc.b 0,0 ;WidthHeight attrib, empty
	dc.w 11+1023		;Tile patterns (0=Empty)
SpriteData_Fly3R:
	dc.b 1,1		;Width,Height
	dc.b 0,0 ;WidthHeight attrib, empty
	dc.w 12+1023		;Tile patterns (0=Empty)
	endif
	

	
	ifd BuildX68
SpriteData_WalkL1:
	dc.b 1,1		;Width,Height
	dc.b 3,0 ; Priority, Spacer
	dc.w 0
SpriteData_WalkL2:
	dc.b 1,1		;Width,Height
	dc.b 3,0 ; Priority, Spacer
	dc.w 1
SpriteData_WalkL3:
	dc.b 1,1		;Width,Height
	dc.b 3,0 ; Priority, Spacer
	dc.w 2
	
SpriteData_WalkR1:
	dc.b 1,1		;Width,Height
	dc.b 3,0 ; Priority, Spacer
	dc.w 3
SpriteData_WalkR2:
	dc.b 1,1		;Width,Height
	dc.b 3,0 ; Priority, Spacer
	dc.w 4
SpriteData_WalkR3:
	dc.b 1,1		;Width,Height
	dc.b 3,0 ; Priority, Spacer
	dc.w 5
	
SpriteData_Fly1L:
	dc.b 1,1		;Width,Height
	dc.b 3,0 ; Priority, Spacer
	dc.w 6
SpriteData_Fly2L:
	dc.b 1,1		;Width,Height
	dc.b 3,0 ; Priority, Spacer
	dc.w 7
SpriteData_Fly3L:
	dc.b 1,1		;Width,Height
	dc.b 3,0 ; Priority, Spacer
	dc.w 8
	
SpriteData_Fly1R:
	dc.b 1,1		;Width,Height
	dc.b 3,0 ; Priority, Spacer
	dc.w 9
SpriteData_Fly2R:
	dc.b 1,1		;Width,Height
	dc.b 3,0 ; Priority, Spacer
	dc.w 10
SpriteData_Fly3R:
	dc.b 1,1		;Width,Height
	dc.b 3,0 ; Priority, Spacer
	dc.w 11
	endif
	
	
	ifd BuildSQL
SpriteData_WalkL1:
	dc.b 1,1		;Width,Height
	dc.w 0
SpriteData_WalkL2:
	dc.b 1,1		;Width,Height
	dc.w 1
SpriteData_WalkL3:
	dc.b 1,1		;Width,Height
	dc.w 2
	
SpriteData_WalkR1:
	dc.b 1,1		;Width,Height
	dc.w 3
SpriteData_WalkR2:
	dc.b 1,1		;Width,Height
	dc.w 4
SpriteData_WalkR3:
	dc.b 1,1		;Width,Height
	dc.w 5
	
SpriteData_Fly1L:
	dc.b 1,1		;Width,Height
	dc.w 6
SpriteData_Fly2L:
	dc.b 1,1		;Width,Height
	dc.w 7
SpriteData_Fly3L:
	dc.b 1,1		;Width,Height
	dc.w 8
	
SpriteData_Fly1R:
	dc.b 1,1		;Width,Height
	dc.w 9
SpriteData_Fly2R:
	dc.b 1,1		;Width,Height
	dc.w 10
SpriteData_Fly3R:
	dc.b 1,1		;Width,Height
	dc.w 11
	endif
	
		
	
	ifd BuildNEO
SpriteData_WalkL1:
		dc.b 1,1		;W,H
		dc.w $0FFF		;Shrnk
			; Tile,PAL
		dc.w $2380,$0100
SpriteData_WalkL2:
	dc.b 1,1		;W,H
		dc.w $0FFF		;Shrnk
			; Tile,PAL
		dc.w $2381,$0100
SpriteData_WalkL3:
	dc.b 1,1		;W,H
		dc.w $0FFF		;Shrnk
			; Tile,PAL
		dc.w $2382,$0100
	
SpriteData_WalkR1:
	dc.b 1,1		;W,H
		dc.w $0FFF		;Shrnk
			; Tile,PAL
		dc.w $2383,$0100
SpriteData_WalkR2:
	dc.b 1,1		;W,H
		dc.w $0FFF		;Shrnk
			; Tile,PAL
		dc.w $2384,$0100
SpriteData_WalkR3:
	dc.b 1,1		;W,H
		dc.w $0FFF		;Shrnk
			; Tile,PAL
		dc.w $2385,$0100
	
SpriteData_Fly1L:
	dc.b 1,1		;W,H
		dc.w $0FFF		;Shrnk
			; Tile,PAL
		dc.w $2386,$0100
SpriteData_Fly2L:
	dc.b 1,1		;W,H
		dc.w $0FFF		;Shrnk
			; Tile,PAL
		dc.w $2387,$0100
SpriteData_Fly3L:
	dc.b 1,1		;W,H
		dc.w $0FFF		;Shrnk
			; Tile,PAL
		dc.w $2388,$0100
	
SpriteData_Fly1R:
	dc.b 1,1		;W,H
		dc.w $0FFF		;Shrnk
			; Tile,PAL
		dc.w $2389,$0100
SpriteData_Fly2R:
	dc.b 1,1		;W,H
		dc.w $0FFF		;Shrnk
			; Tile,PAL
		dc.w $238A,$0100
SpriteData_Fly3R:
	dc.b 1,1		;W,H
		dc.w $0FFF		;Shrnk
			; Tile,PAL
		dc.w $238B,$0100
	endif
	

	ifd BuildAMI
SpriteData_WalkL1:
	dc.b 1,1		;Width,Height
	dc.w 0
SpriteData_WalkL2:
	dc.b 1,1		;Width,Height
	dc.w 1
SpriteData_WalkL3:
	dc.b 1,1		;Width,Height
	dc.w 2
	
SpriteData_WalkR1:
	dc.b 1,1		;Width,Height
	dc.w 3
SpriteData_WalkR2:
	dc.b 1,1		;Width,Height
	dc.w 4
SpriteData_WalkR3:
	dc.b 1,1		;Width,Height
	dc.w 5
	
SpriteData_Fly1L:
	dc.b 1,1		;Width,Height
	dc.w 6
SpriteData_Fly2L:
	dc.b 1,1		;Width,Height
	dc.w 7
SpriteData_Fly3L:
	dc.b 1,1		;Width,Height
	dc.w 8
	
SpriteData_Fly1R:
	dc.b 1,1		;Width,Height
	dc.w 9
SpriteData_Fly2R:
	dc.b 1,1		;Width,Height
	dc.w 10
SpriteData_Fly3R:
	dc.b 1,1		;Width,Height
	dc.w 11
	endif
	
	ifd BuildAST
SpriteData_WalkL1:
	dc.b 1,1		;Width,Height
	dc.w 0
SpriteData_WalkL2:
	dc.b 1,1		;Width,Height
	dc.w 1
SpriteData_WalkL3:
	dc.b 1,1		;Width,Height
	dc.w 2
	
SpriteData_WalkR1:
	dc.b 1,1		;Width,Height
	dc.w 3
SpriteData_WalkR2:
	dc.b 1,1		;Width,Height
	dc.w 4
SpriteData_WalkR3:
	dc.b 1,1		;Width,Height
	dc.w 5
	
SpriteData_Fly1L:
	dc.b 1,1		;Width,Height
	dc.w 6
SpriteData_Fly2L:
	dc.b 1,1		;Width,Height
	dc.w 7
SpriteData_Fly3L:
	dc.b 1,1		;Width,Height
	dc.w 8
	
SpriteData_Fly1R:
	dc.b 1,1		;Width,Height
	dc.w 9
SpriteData_Fly2R:
	dc.b 1,1		;Width,Height
	dc.w 10
SpriteData_Fly3R:
	dc.b 1,1		;Width,Height
	dc.w 11
	endif
	endif 
	
	
TestProgram_End:		
	even
HSprites:
	ifd NativeSpr_Multiplatform2Bitplane
	
		incbin "\ResALL\Reikou\AnimTest\Sprites_SMS_4Color.raw"

	else
	
	ifd BuildGEN
		incbin "\ResALL\Reikou\AnimTest\Sprites_GEN.raw"
	endif
	ifd BuildX68
		incbin "\ResALL\Reikou\AnimTest\Sprites_X68.raw"
	endif
	ifd BuildSQL
		incbin "\ResALL\Reikou\AnimTest\Sprites_SQL.raw"
	endif
	ifd BuildAST
		incbin "\ResALL\Reikou\AnimTest\Sprites_AST.raw"
	endif
	ifd BuildAMI
		incbin "\ResALL\Reikou\AnimTest\Sprites_AST.raw"
	endif
	endif
	; ifd BuildSQL
		; incbin "\ResALL\Reikou\Sprong\SQL_Sprites.RAW"
	; endif
	; ifd BuildAMI
		; incbin "\ResALL\Reikou\Sprong\AMI_Sprites.RAW"
	; endif
	; ifd BuildAST
		; incbin "\ResALL\Reikou\Sprong\AMI_Sprites.RAW"
	; endif
	; ifd BuildGEN
		; incbin "\ResALL\Reikou\Sprong\GEN_Sprites.RAW"
	; endif
	; ifd BuildX68
		; incbin "\ResALL\Reikou\Sprong\X68_Sprites.RAW"
	; endif
HSprites_end:	
	even

; SpriteData_WalkL1:
	; dc.b 1,1		;Width,Height
	; dw 1		;Tile patterns (0=Empty)
; SpriteData_WalkL2:
	; dc.b 1,1		;Width,Height
	; dw 2		;Tile patterns (0=Empty)
; SpriteData_WalkL3:
	; dc.b 1,1		;Width,Height
	; dw 3		;Tile patterns (0=Empty)
	
; SpriteData_WalkR1:
	; dc.b 1,1		;Width,Height
	; dw 4		;Tile patterns (0=Empty)
; SpriteData_WalkR2:
	; dc.b 1,1		;Width,Height
	; dw 5		;Tile patterns (0=Empty)
; SpriteData_WalkR3:
	; dc.b 1,1		;Width,Height
	; dw 6		;Tile patterns (0=Empty)
	
; SpriteData_Fly1L:
	; dc.b 1,1		;Width,Height
	; dw 7		;Tile patterns (0=Empty)
; SpriteData_Fly2L:
	; dc.b 1,1		;Width,Height
	; dw 8		;Tile patterns (0=Empty)
; SpriteData_Fly3L:
	; dc.b 1,1		;Width,Height
	; dw 9		;Tile patterns (0=Empty)
	
; SpriteData_Fly1R:
	; dc.b 1,1		;Width,Height
	; dw 10		;Tile patterns (0=Empty)
; SpriteData_Fly2R:
	; dc.b 1,1		;Width,Height
	; dw 11		;Tile patterns (0=Empty)
; SpriteData_Fly3R:
	; dc.b 1,1		;Width,Height
	; dw 12		;Tile patterns (0=Empty)
	
	
; Sprite_0:
    ; dc.b 0,6 ;Width,Height
    ; dc.b %1111,0 ;WidthHeight attrib, empty
          ; dc.w 1024
          ; dc.w 1040
          ; dc.w 1056
          ; dc.w 1072
          ; dc.w 1088
          ; dc.w 1104

	
	
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

