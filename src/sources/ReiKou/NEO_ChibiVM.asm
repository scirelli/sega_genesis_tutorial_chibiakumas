;compile with option: VASM GEN

	include "sources/ChibiAdventure/header.asm"
	
	include "srcall/ChibiVm_InstSet.asm"
	include "srcall/BasicMacros.asm"
	
	
VM_ProgLoadAddr equ $400	

VM_RamBase equ $100000


VM_HostRam	equ $10FE00	;Variables for our Emulator



	jsr ChibiVM_Init
	
		
	;jsr VM_Run_WithMonitor
	
	jsr VM_Run
	
VM_Run:	
	jsr VM_Tick
	jmp VM_Run
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
VM_RamBaseAddr: dc.l VM_RamBase

	
	include "../ChibiVM/Multiplatform_MonitorA.asm"
	
	include "NativeSprite.asm"
	include "SrcNEO/V1_NativeSprite.asm"	;Put before Adventure Engine inc
	
	include "sources/ChibiAdventure/ChibiVM_AdventureEngine.asm"
	include "sources/ChibiVM/ChibiVM_Host.asm"
	
	org $10000	;Needed for some reason - somethings messing up the next org otherwise
		



	org $10000+VM_ProgLoadAddr
TestProgram:	
;;;;;;;;;;;;;;;;;;;;
;Program Header ; Must be on a ??00 boundary
;;;;;;;;;;;;;;;;;;;;

	dc.b "!!!!Chibi/VM!!!!"			;Magic key - must be on a $xxxxxx00 boundary
	dc.b "Your product name here"		;Software Name - 32 bytes

	org $10000+VM_ProgLoadAddr+$30
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
	
	org $10000+VM_ProgLoadAddr+$40
	dlle $400		;Rom Load Address
	dlle $200		;StackPointer
	dlle $100		;Trap table Ram address (0=none)
	dlle $0000		;Memmap 1
	dlle $4000		;Memmap 2
	dlle $8000		;Memmap 3
	dlle $C000		;Memmap 4

	org $10000+VM_ProgLoadAddr+$70
	dlle (vm_traps-($10000+VM_ProgLoadAddr))	;Vector table (0=none)
	dlle $2000		;Address remap table (0=none)
	dlle 0			;VMAssets (Palette,Font etc)
	dlle 0			;???

	

HspriteCount equ VM_RamBase+64
HspriteLimit equ VM_RamBase+66		
	
	
;Zero page entries for variables	
Answer equ 16
Guess equ 17		;2 bytes (combined into 1 byte value)
Tries equ 19	
	
		
ProgramLaunch:	
	;dbw braj,TestAddressing
	dbbw mov16x,r6_imm16,0
	NSCall nsInit 	
		
	dbbw mov16x,r6_imm16,1
	NSCall nsDrawArray+regRR 			;SpriteArray

		
AnotherGo:
	dbbw mov16x,R6_imm16,strStart	;Show title message
	AdvCall aPrintSeq 
	;dbw braj,TestProgram
	
	AdvCall aWaitForFire 
	
	;db hltb
	
	AdvCall aDoRandom
	dbb stoz,Answer					;Decide what the answer is 
	
AnotherGuess:	
	AdvCall aWaitForRelease			;Wait for joystick release
	
	dbbw mov16x,R6_imm16,strGuess
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
	dbw beqj,TestGuess				;Test Fire

	dbw braj,GuessLoop
	
TestGuess:	
	dbb incz,tries					;Another try used 

	dbbb cmpx,ZeroPg_r3,Answer
	dbw beqj,TestCorrect			;Is answer Correct?
	
	;dbb SYSi,syscallMonitor

	dbbw mov16x,r6_imm16,strLow	
	dbw bccj,AnswerLow				;Is answer too Low
	dbbw mov16x,r6_imm16,strHigh
AnswerLow:
	AdvCall aPrintSeq
	dbw braj,AnotherGuess

TestCorrect:
	AdvCall aNewLine

	dbbw mov16x,r6_imm16,strCorrect	;Problem solved!
	AdvCall aPrintSeq
	dbw movz,tries
	AdvCall aShowDecimal

	AdvCall aPrintSeq

	AdvCall aWaitForFire
	AdvCall aCls
	dbw braj,AnotherGo				;Repeat for next game
		
	db HLTb
	
vm_traps: 	dw (ProgramLaunch-$10000)


strStart:	dc.b 'Guess My Number!',254
		dc.b 'Press Fire to start',254,255	;String to show
strGuess:	dc.b 'Your Guess >',255	;String to show
strCorrect: 	dc.b 'Correct! You took ',255,' Tries!',255
strLow:		dc.b 253,'Too Low!',254,255
strHigh:	dc.b 253,'Too High!',254,255

	org $10000+$2000
vm_AddressRemapTable:
	;Address Remap Table
	dlle 0
	dlle SpriteArrayRK ;SpriteArray

	dlle SpriteData_Magnify
	
TestProgram_End:
	even

	

SpriteArray:
	dc.w 2		;Count
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
	align 2

	
SpriteData_Magnify:	
	dc.b 3,4	;WH
	;Stretch,Tiles Down then across
		
	dc.w $0FFF,$2202,$0100,$2202,$0100,$2204,$0100,$2205,$0100
	dc.w $0FFF,$2202,$0100,$2203,$0100,$2204,$0100,$2205,$0100
	dc.w $0FFF,$2203,$0100,$2203,$0100,$2203,$0100,$2203,$0100
	dc.w $0FFF,$2204,$0100,$2204,$0100,$2204,$0100,$2204,$0100
	
	align 2	
	
	org $20000			;Ensure no label calc problems

	include "srcall/ChibiVm_CPU.asm"	
	
	
	even

	include "sources/ChibiAdventure/core.asm"
	include "sources/ChibiAdventure/footer.asm"
 