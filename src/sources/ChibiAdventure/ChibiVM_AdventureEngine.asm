
vm_syscalls: dc.l DummySyscall	;0 - ChipExt
			 dc.l DummySyscall	;1 - VMControl
			 dc.l DummySyscall	;2 - VMMonitor
			 dc.l AdventureCall	;3
			 dc.l DummySyscall ;4 - ChibiSoundCall
			 
			ifd MaxTileCall
				dc.l MaxTileCall
			else
				dc.l DummySyscall ;5 - MaxTileCall  
			endif
			
			ifd qtvcall
				dc.l qtvcall ;6 - QTVCall
			else
				dc.l DummySyscall ;6 - QTVCall
			endif 
			
			 
			 ifd NativeSpriteCall
				dc.l NativeSpriteCall ;7 - NSCall
			 else 
				dc.l DummySyscall ;7 - NSCall
			endif
			ifd LoadMultiReg
				dc.l LoadMultiReg
			else
				dc.l DummySyscall ;8 - LoadMultiReg
			endif
			 
			 ifd MBCall
				dc.l MBCall ;9 - MBCall Multiplatform Bitmap
			 else 
				dc.l DummySyscall ;9 - MBCall
			endif
			
			 ifd AnimCall
				dc.l AnimCall				;10 - Animator
			 else 
				dc.l DummySyscall 
			endif
			
			 ifd AdvX_Call
				dc.l AdvX_Call			;11
			 else 
				dc.l DummySyscall 
			endif
			
				
			ifd AdvInput_Call
				dc.l AdvInput_Call			;12 Chibisound Pro 
			else
				dc.l DummySyscall
			endif 
			
			ifd AdvInput_Call
				dc.l AdvInput_Call			;13
			else
				dc.l DummySyscall
			endif 
			
			ifd RleDecompress_Call
				dc.l RleDecompress_Call			;14
			else
				dc.l DummySyscall
			endif 
			
			
			ifd AdvMaths_Call
				dc.l AdvMaths_Call			;15
			else
				dc.l DummySyscall
			endif 
						
	;dw ChipEXT			;0
	;dw VMControl		;1
	;dw VMMonitor		;2
	;dw AdventureCall	;3
	;dw ChibiSoundCall	;4
	;dw MaxTileCall		;5
	;dw QTVCall			;6
	;dw NSCall			;7
	;dw LoadMultiReg		;8
			
syscallAdventure equ 3		
syscallNativeSprite equ 7
syscallMB equ 9

	Macro MBcall,p1
		dbb SYSi,syscallMB
		db \1
	endm
	
	ifd RleDecompress_Call
		Macro RLECall,p1
			dbb SYSi,syscallRLE
			db \1
		endm
	endif 
	
	Macro AdvCall,p1		
		dbb SYSi,syscallAdventure
		db \1
	endm

	Macro NsCall,p1		
		dbb SYSi,syscallNativeSprite
		db (\1)
	endm
	Macro MaxTileCall,p1
		dbb SYSi,syscallMaxTile
		db \1
	endm
	
	ifd AdvMaths_Call
		Macro Mcall,p1
			dbb SYSi,syscallMaths
			db \1
		endm
	endif 	
	
	Macro AdvInputCall,p1
		dbb SYSi,syscallAdvInput
		db \1
	endm
	
	
	Macro QTVCall,p1
		dbb SYSi,syscallQTV
		db \1
	endm

regRR equ 0
regNO equ 0

aPrintChar equ 0
aPrintSeq equ 1
aPrintNumber equ 2
aPrintSeqNC equ 3
aPrintSeqNL equ 4
aShowDecimal equ 5
aNewLine equ 6
acls equ 7
aFillArea equ 8
aWaitForFire equ 9
aJoyAxis equ 10
aPause50 equ 11
aPauseA equ 12
aDivideAbyH equ 13
aRangedRandom equ 14
aRangeLimit equ 15
aRangeTest equ 16
aDoRandom equ 17
aChibiSoundBeep equ 18
aChibiSound equ 19
aDoLdir equ 20
aDoLddr equ 21
aSlowDown equ 22
aReadJoystick equ 23
aWaitForRelease equ 24
aLastCommand equ 25
	
	
vecAdventureCall:	
	dc.l PrintChar
	dc.l PrintSeqADV
	dc.l PrintNumber
	dc.l PrintSeqNC
	dc.l PrintSeqNL
	dc.l ShowDecimal
	dc.l NewLine
	dc.l cls
	dc.l FillArea
	dc.l WaitForFire
	dc.l JoyAxis
	dc.l Pause50
	dc.l PauseA
	dc.l DivideAbyH
	dc.l RangedRandom
	dc.l RangeLimit
	dc.l RangeTest
	dc.l DoRandom
	dc.l ChibiSoundBeep
	dc.l ChibiSound
	dc.l DoLdirADV
	dc.l DoLddrADV
	dc.l SlowDown
	dc.l ReadJoystick
	dc.l WaitForRelease



DoLdirADV:			;Copy D1 bytes from A3 to A2 (ascending)
	move.b (a3)+,(a2)+
	subq.w #1,d4		
	bne DoLdirADV
	rts

DoLddrADV:			;Copy D1 bytes from A3 to A2 (descending)
	move.b (a3),(a2)
	subq.w #1,a3
	subq.w #1,a2
	subq.w #1,d4
	bne DoLddrADV
	rts		
	
WaitForPress:
	jsr waitforfire
	jsr waitforrelease
	rts
		
; for compatibility with Multiplatform_MonitorA
NewLineA:
	clr.b (Cursor_X)
	addq.b #1,(Cursor_Y)
	rts
PrintCharA:
	pushall
		clr.l d2
		clr.l d5
	
		move.b (Cursor_X),d2
		move.b (Cursor_Y),d5
		jsr PrintChar
		move.b d2,(Cursor_X)
		move.b d5,(Cursor_Y)
	popall
	rts
	



AdventureCall:	 
	move.l #vecAdventureCall,a6
ChibiVM_VectorCall:	 	
	move.l (VM_RamBaseAddr),a3
	move.l (VM_RamBaseAddr),a0
	clr.l d7
	move.b (VM_rPC+1,a3),d7
	asl.l #8,d7
	move.b (VM_rPC,a3),d7
	add.l d7,a0
	
	clr.l d0
	move.b (a0),d0
	addq.l #1,d7
	
	
	move.b d7,(VM_rPC,a3)
	asr.l #8,d7
	move.b d7,(VM_rPC+1,a3)
	
	asl.l #2,d0
		
	move.l (a6,d0),a6
	
	clr.l d0
	clr.l d1
	clr.l d2
	clr.l d3
	clr.l d4
	clr.l d5
	clr.l d6
	
	move.b (VM_rR0,a3),d0
	
	move.b (VM_rR3,a3),d1
	move.b d1,d4
	asl.l #8,d4
	move.b (VM_rR2,a3),d4
	
	move.b (VM_rR5,a3),d2
	move.b d2,d5
	asl.l #8,d5
	move.b (VM_rR4,a3),d5
	
	move.b (VM_rR7,a3),d3
	move.b d3,d6
	asl.l #8,d6
	move.b (VM_rR6,a3),d6
	
	;move.l #VM_RamBase,d7
	;add.l d7,d4
	;add.l d7,d5
	;add.l d7,d6
	
	move.l (VM_RamBaseAddr),d7
	move.l d4,a1
	add.l d7,a1
	
	move.l d5,a2
	add.l d7,a2
	
	move.l d6,a3
	add.l d7,a3
	
	;move.b #1,Cursor_Y
	;clr.b Cursor_X
	;jsr monitor
	clr.l d7
	 
	jsr (a6)
	
	cmp.l #$66660006,d7
	beq AdventureCall_CustomSave	;Allow override for all regs
	
	move.l (VM_RamBaseAddr),a0
	
	;Note: ChibiAdventure was designed for the Z80, so registers mimic A BC DE HL
	move.b d0,(VM_rR0,a0)	;Accumulator is always 8 bits... R1 doesn't exist on Z80
	
	cmp.l #$66660000,d7
	beq AdventureCall_CustomSave	;Allow override for A3/A2/A1 or 16 bit D1/D2/D3
	
	;Store 8 bit regs back to VM
	
	
	
	move.b d3,(VM_rR7,a0)	;HL
	move.b d6,(VM_rR6,a0)
	move.b d2,(VM_rR5,a0)	;DE
	move.b d5,(VM_rR4,a0)
	move.b d1,(VM_rR3,a0)	;BC
	move.b d4,(VM_rR2,a0)
AdventureCall_CustomSave:	
	rts

	
PrintSeqADV:


	;move.b #1,Cursor_Y
	;clr.b Cursor_X
	;jsr monitor

	jsr PrintSeq
	
	
	
	move.l (VM_RamBaseAddr),a0
	
	jsr VM_SaveA3
	
	move.b d2,(VM_rR5,a0)	;DE
	move.b d5,(VM_rR4,a0)
	
	move.b d1,(VM_rR3,a0)	;BC
	move.b d4,(VM_rR2,a0)
	
	move.l #$66660000,d7			;We needto restore A3
	rts
	
VM_SaveA3SetA0:	
	move.l (VM_RamBaseAddr),a0
VM_SaveA3:
	move.l (VM_RamBaseAddr),d7
	sub.l d7,a3
	move.l a3,d6
	move.b d6,(VM_rR6,a0)	;HL (Address)
	asr.l #8,d6
	move.b d6,d3
	move.b d3,(VM_rR7,a0)
	rts
	
DummySyscall:
	rts
	
	
	
	
	