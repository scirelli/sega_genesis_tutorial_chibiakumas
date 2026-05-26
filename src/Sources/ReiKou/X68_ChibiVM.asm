;compile with option: VASM GEN

	include "Sources/ChibiAdventure/header.asm"
	
	include "SrcALL/ChibiVm_InstSet.asm"
	include "SrcALL/BasicMacros.asm"
		
vmAddressRemap_BigEndian equ 1			;Little endian calculations won't work due to relocatable code

	
VM_ProgLoadAddr equ $400	


	
	and.l  #$FFFF0000,(VM_RamBaseAddr)	;Ensure VM ram ends $????0000

	;move.l #HSprites,a3
	;jsr NativeSpr_Init

	
	
	;move.l #SpriteArray,a3
	;jsr NativeSpr_DrawArray
	
	
	
	;jsr monitor
	
	;jmp $
	
	jsr ChibiVM_Init

	
	;jsr Monitor_MemDump		;Dump 6 lines from  $00000000
	;dc.l TestProgram
	;dc.w $2
	
	;jsr Monitor_MemDump		;Dump 6 lines from  $00000000
	;dc.l VM_RamBase+VM_ProgLoadAddr
	;dc.w $2
	;jmp $
	
	;jsr VM_Run_WithMonitor
	;jsr monitor	
	;jmp $
VM_Run:	
	
		
	jsr VM_Tick
	jmp VM_Run
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
NativeSpriteCall:
	move.l #vecNS,a6
	jmp ChibiVM_VectorCall

	
nsInit equ 0		;put this before 	include "ChibiVM_AdventureEngine.asm"
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
	
	

	;include "NativeSprite.asm"
	include "SrcX68/V1_NativeSprite.asm"	;Put before Adventure Engine inc
	
	
	include "../ChibiVM/Multiplatform_MonitorA.asm"
	include "Sources/ChibiAdventure/ChibiVM_AdventureEngine.asm"
	include "Sources/ChibiVM/ChibiVM_Host.asm"
	
	
	
	;rorg $10000	;Needed for some reason - somethings messing up the next org otherwise
		


HspriteCount equ VM_RamBase+64
HspriteLimit equ VM_RamBase+66		
	
	rorg $10000		;We Need to do this for relative calculations 
					;(label-VramBase) will calculate correct 16 bit addresses
VramBase:			;$0000 in our final VRAM
	rorg $10000+VM_ProgLoadAddr
TestProgram:	
	;incbin "\ResAll\ChibiVM\NumberGuess.rom"

	dc.b "!!!!Chibi/VM!!!!"			;Magic key - must be on a $xxxxxx00 boundary
	dc.b "Your product name here"		;Software Name - 32 bytes

	rorg $10000+VM_ProgLoadAddr+$30
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
	
	rorg $10000+VM_ProgLoadAddr+$40
	dlle $400		;Rom Load Address
	dlle $200		;StackPointer
	dlle $100		;Trap table Ram address (0=none)
	dlle $0000		;Memmap 1
	dlle $4000		;Memmap 2
	dlle $8000		;Memmap 3
	dlle $C000		;Memmap 4

	rorg $10000+VM_ProgLoadAddr+$70
	dlle (vm_traps-TestProgram)	;Vector table (0=none)
	dlle $2000		;Address remap table (0=none)
	dlle 0			;VMAssets (Palette,Font etc)
	dlle 0			;???

	
	
;Zero page entries for variables
Answer equ 16
Guess equ 17		;2 bytes (combined into 1 byte value)
Tries equ 19	
	
	
;HspriteCount equ VM_RamBase+64
;HspriteLimit equ VM_RamBase+65	
	
ProgramLaunch:	
	;dbw braj,TestAddressing
	
	dbbw mov16x,r6_imm16,0
	NSCall nsInit 	
		
	dbbw mov16x,r6_imm16,1
	NSCall nsDrawArray+regRR 			;SpriteArray

	
AnotherGo:
	dbbw mov16x,R6_imm16,(strStart-VramBase);Show title message
	AdvCall aPrintSeq 
	;dbw braj,TestProgram
	
	AdvCall aWaitForFire 
	
	;db hltb
	
	AdvCall aDoRandom
	dbb stoz,Answer					;Decide what the answer is 
	
AnotherGuess:	
	AdvCall aWaitForRelease			;Wait for joystick release
	
	dbbw mov16x,R6_imm16,(strGuess-VramBase)
	AdvCall aPrintSeq 				;Show the guess message
	
GuessLoop:	
	db ph4b
		AdvCall aReadJoystick		;Get keypresses into A
		dbb stoz,R2
		
		dbb movz,Guess+1
		AdvCall aJoyAxis			;Up/Down (+-16)
		dbb stoz,R7
		dbb stoz,Guess+1

		dbb movz,Guess
		Advcall AJoyAxis			;Left/Right (+-1)
		dbb stoz,R6
		dbb stoz,Guess
		
		dbb movz,R6
		db ASLb						;LR=+-16
		db ASLb
		db ASLb
		db ASLb
		dbb addz,R7					;UD=+-1
		
		dbb stoz,R3					;Combine H and L onto B

	db pl4b
	db ph4b
		Advcall aShowDecimal
	db pl4b

	Advcall aPause50
	
	dbbb TSTx,R2_imm8,%00000001
	dbw beqj,(TestGuess-VramBase)		;Test Fire

	dbw braj,(GuessLoop-VramBase)
	
TestGuess:	
	dbb incz,tries					;Another try used 

	dbbb cmpx,ZeroPg_r3,Answer
	dbw beqj,(TestCorrect-VramBase)		;Is answer Correct?
	
	;dbb SYSi,syscallMonitor

	dbbw mov16x,r6_imm16,(strLow-VramBase)
	dbw bccj,((AnswerLow-VramBase))				;Is answer too Low
	dbbw mov16x,r6_imm16,((strHigh-VramBase))
AnswerLow:
	AdvCall aPrintSeq
	dbw braj,((AnotherGuess-VramBase))

TestCorrect:
	AdvCall aNewLine

	dbbw mov16x,r6_imm16,((strCorrect-VramBase))	;Problem solved!
	AdvCall aPrintSeq
	dbw movz,tries
	AdvCall aShowDecimal

	AdvCall aPrintSeq

	AdvCall aWaitForFire
	AdvCall aCls
	dbw braj,((AnotherGo-VramBase))				;Repeat for next game
		
	db HLTb
	
	
	
	
strStart:	dc.b 'Guess My Number!',254
		dc.b 'Press Fire to start',254,255	;String to show
strGuess:	dc.b 'Your Guess >',255	;String to show
strCorrect: 	dc.b 'Correct! You took ',255,' Tries!',255
strLow:		dc.b 253,'Too Low!',254,255
strHigh:	dc.b 253,'Too High!',254,255

	
	;rorg $14000
vm_traps: 	dw ((ProgramLaunch-TestProgram)+VM_ProgLoadAddr)

	
	align 13
vm_AddressRemapTable:
	;Address Remap Table
	;dlle 0
	dc.l HSprites
	dc.l SpriteArrayRK ;SpriteArray
	dc.l SpriteData_Magnify
	
TestProgram_End:
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
	dc.w 3		;Count
	dc.w $4040
	dc.l SpriteData_Magnify
	dc.w $6060
	dc.l SpriteData_Magnify
	dc.w $A0A0
	dc.l SpriteData_Magnify
	
	
SpriteArrayRK:
	db 3		;Count
	dw $4040
	dw 2;SpriteData_Magnify
	dw $6090
	dw 2;SpriteData_Magnify
	dw $9090
	dw 2;SpriteData_Magnify
	
	even  ;*** WARNING - COUNT WILL MEAN ARRAY is ODD ALIGNED! ***

	
SpriteData_Magnify:	
	dc.b 4,4	;WH
	dc.b 3		;Priority
	dc.b 0 		;spacer
	;Stretch,Tiles Down then across
	dc.w 0,1,4,5 		;$FFFF=unused
	dc.w 2,3,6,7
	dc.w 8,9,12,13
	dc.w 10,11,14,15
	
	align 2	
	
	;Hardware Sprite Patterns
HSprites:
	incbin "\ResALL\Reikou\\X68_Cursors.RAW"
	
HSprites_end:


	include "SrcALL/ChibiVm_CPU.asm"		
	
	even

	include "Sources/ChibiAdventure/core.asm"
	include "Sources/ChibiAdventure/footer.asm"
	
	align 8
	
VM_RamBaseAddr: dc.l VM_RamBase+65536
	
	even
VM_RamBase:
	ds.b 65536*2
VM_HostRam:	
	ds.b 256
	;Variables for our Emulator

