;compile with option: VASM GEN
vm_usevmem equ 1

	include "\Sources\ChibiAdventure\header.asm"
	
	include "\SrcALL\ChibiVm_InstSet.asm"
	include "\SrcALL\BasicMacros.asm"
	
	
VM_ProgLoadAddr equ $400

VM_RamBase equ $00FF0000


VM_HostRam	equ $00FFFE00	;Variables for our Emulator


GEN_SpritePatternVRAM equ $8000
GEN_SpritePatternCount equ 64

	jsr ChibiVM_Init

	;move.l #MySprites,a3
	;jsr NativeSpr_Init
	
	
	;move.l #SpriteArray,a3
	;jsr NativeSpr_DrawArray
	
	

;Define palette
	lea Palette,a1
	move.l #16,d1
	move.l #$C0000000,d0		;Color 0
PaletteAgain:	
	move.l d0,(VDP_Ctrl)
	move.w (a1)+,(VDP_data)		;----BBB-GGG-RRR-
	add.l #$00020000,d0
	dbra d1,PaletteAgain
	
	
	jsr VM_Run_WithMonitor
	
VM_Run:	
	jsr VM_Tick
	jmp VM_Run
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
VM_RamBaseAddr: dc.l VM_RamBase

	
	

	; out (vdpControl),a
	; ld a,&30+&40
	; out (vdpControl),a	
		
; NativeSpr_Initb:
	; ld a,(hl)
	; out (vdpData),a
	; inc hl
	; dec bc
	; ld a,b
	; or c
	; jr nz,NativeSpr_Initb
	; jr NativeSpr_ClearUnused	
	
	
	
	include "..\ChibiVM\Multiplatform_MonitorA.asm"
	
	
	include "NativeSprite.asm"
	include "\SrcGEN\V1_NativeSprite.asm"
	include "\Sources\ChibiAdventure\ChibiVM_AdventureEngine.asm"
	include "\Sources\ChibiVM\ChibiVM_Host.asm"
	
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

	
	
;Zero page entries for variables
Answer equ 16
Guess equ 17		;2 bytes (combined into 1 byte value)
Tries equ 19	
	
	
HspriteCount equ VM_RamBase+64
HspriteLimit equ VM_RamBase+65	
		
ProgramLaunch:	
	;dbw braj,TestAddressing
	dbbw mov16x,r6_imm16,0
	NSCall nsInit 	
		
	dbbw mov16x,r6_imm16,1
	NSCall nsDrawArray+regRR 			;SpriteArray

	;db hltb
	
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
	dlle MySprites
	dlle SpriteArrayRK ;SpriteArray
	dlle SpriteData_Magnify
	
TestProgram_End:
	even

	
MySprites:
	incbin "\ResAll\Reikou\GEN_Cursors.RAW"
	

SpriteArray:
	dc.w 2		;Count
	dc.w $6060
	dc.l SpriteData_Magnify
	dc.w $A0A0
	dc.l SpriteData_Magnify
	
	
SpriteArrayRK:
	db 3		;Count
	dw $6060
	dw 2;SpriteData_Magnify
	dw $6090
	dw 2;SpriteData_Magnify
	dw $9090
	dw 2;SpriteData_Magnify
	align 2

	
SpriteData_Magnify:	
	dc.b 2,2	;WH
	dc.b %1111,0 ; WidthHeight attrib,empty
	
	dc.w $400,$410
	dc.w $420,$430
	
	align 2	

	
Palette:	
    dc.w %0000000000000000; ;0  %----BBB-GGG-RRR-
    dc.w %0000000000001010; ;1  %----BBB-GGG-RRR-
    dc.w %0000000010100000; ;2  %----BBB-GGG-RRR-
    dc.w %0000000001001010; ;3  %----BBB-GGG-RRR-
    dc.w %0000000010101100; ;4  %----BBB-GGG-RRR-
    dc.w %0000100000001000; ;5  %----BBB-GGG-RRR-
    dc.w %0000101001001100; ;6  %----BBB-GGG-RRR-
    dc.w %0000110011001100; ;7  %----BBB-GGG-RRR-
    dc.w %0000100010001000; ;8  %----BBB-GGG-RRR-
    dc.w %0000000000001110; ;9  %----BBB-GGG-RRR-
    dc.w %0000000011100000; ;10  %----BBB-GGG-RRR-
    dc.w %0000000011101110; ;11  %----BBB-GGG-RRR-
    dc.w %0000111000000000; ;12  %----BBB-GGG-RRR-
    dc.w %0000010000000100; ;13  %----BBB-GGG-RRR-
    dc.w %0000111011100000; ;14  %----BBB-GGG-RRR-
    dc.w %0000111011101110; ;15  %----BBB-GGG-RRR-
    dc.w %0000000000000010; ;16  %----BBB-GGG-RRR-
	
	
	org $20000			;Ensure no label calc problems

	include "\SrcALL\ChibiVm_CPU.asm"		
	
	even

	include "\Sources\ChibiAdventure\core.asm"
	include "\Sources\ChibiAdventure\footer.asm"
 
 