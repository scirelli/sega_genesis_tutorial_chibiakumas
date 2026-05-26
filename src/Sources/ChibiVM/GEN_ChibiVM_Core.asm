	include "\SrcALL\ChibiVm_InstSet.asm"
	
vm_usevmem equ 1

;compile with option: VASM GEN

	include "\SrcALL\BasicMacros.asm"
	org 0
;Ram Variables
;Cursor_X equ $00FFF000		;Ram for Cursor Xpos
;Cursor_Y equ $00FFF000+1	;Ram for Cursor Ypos

VM_RamBase equ $00FF0000
VM_ProgLoadAddr equ $800
VM_HostRam	equ $00FFFE00	;Variables for our Emulator


;VM_StackTop equ $00FF0100
;VM_ProgDest equ $00FF0800

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
	move.l #$C0000000,d0	;Color 0
	move.l d0,VDP_Ctrl
	;        ----BBB-GGG-RRR-
	move.w #%0000011000000000,VDP_data
			
	move.l #$C0020000,d0	;Color 1
	move.l d0,VDP_Ctrl
	move.w #%0000000011101110,VDP_data
	
	move.l #$C0040000,d0	;Color 2
	move.l d0,VDP_Ctrl
	move.w #%0000111011100000,VDP_data
	
	move.l #$C0060000,d0	;Color 3
	move.l d0,VDP_Ctrl
	move.w #%0000000000001110,VDP_data
	
	move.l #$C01E0000,d0	;Color 15 (Font)
	move.l d0,VDP_Ctrl
	move.w #%0000000011101110,VDP_data
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					Set up Font
	lea Font,A1					 ;Font Address in ROM
	move.l #Font_End-Font,d6	 ;Our font contains 96 letters 8 lines each
	
	move.l #$40000000,(VDP_Ctrl);Start writes to address $0000
								;(Patterns in Vram)
NextFont:
	move.b (A1)+,d0		;Get byte from font
	moveq.l #7,d5		;Bit Count (8 bits)
	clr.l d1			;Reset BuildUp Byte
	
Font_NextBit:			;1 color per nibble = 4 bytes

	rol.l #3,d1			;Shift BuildUp 3 bits left
	roxl.b #1,d0		;Shift a Bit from the 1bpp font into the Pattern
	roxl.l #1,d1		;Shift bit into BuildUp
	dbra D5,Font_NextBit;Next Bit from Font
	
	move.l d1,d0		; Make fontfrom Color 1 to color 15
	rol.l #1,d1			;Bit 1
	or.l d0,d1
	rol.l #1,d1			;Bit 2
	or.l d0,d1
	rol.l #1,d1			;Bit 3
	or.l d0,d1
	
	move.l d1,(VDP_Data);Write next Long of char (one line) to VDP
	dbra d6,NextFont	;Loop until done

	

	;clr.b Cursor_X			;Clear Cursor XY
	;clr.b Cursor_Y
	
	;Turn on screen
	move.w	#$8144,(VDP_Ctrl);C00004 reg 1 = 0x44 unblank display
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

	
	jmp VMTest
	
	

	
VMTest:	

	jsr ChibiVM_Init

	; move.l #vm_rambase,a3
	; move.l #TestData,a1
	; StoreLE a1,a3
	
	; jsr Monitor				;Show Registers


	; jsr Monitor_MemDump		;Dump 6 lines from  $00000000
	; dc.l vm_rambase
	; dc.w $6
	
	
	; move.l #TestProgram,a3
	; move.l #VM_ProgDest,a2
	; move.l #TestProgram_End-TestProgram,d1
	
; CopyProgram:
	; move.b (a3)+,(a2)+			;Copy D1+1 bytes from A3 to A2
	; subq.l #1,d1
	; bne CopyProgram
	
	; move.l #VM_StackTop,d0
	; StoreLEia d0,VM_RamBase+VM_rSP
	
	; move.l #VM_RamBase,d1
	; move.l #VM_Traps,a0
	
	; move.b (1,a0),d0
	; asl #8,d0
	; move.b (0,a0),d0
	; move.w d0,d1
	
	;move.l #VM_ProgDest,d0
	; StoreLEia d1,VM_RamBase+VM_rPC
	
	
InfLoop:	
	clr.b Cursor_X
	clr.b Cursor_Y
	
	
;ZeroPage
	jsr Monitor_MemDump		;Dump 6 lines from  $00000000
	dc.l vm_rambase
	dc.w $6
	
	
;Stack
	jsr Monitor_MemDump		;Dump 6 lines from  $00000000
	dc.l VM_StackTop-16
	dc.w $2
	
;Program
	move.l #VM_RamBase,a1
	LoadLEia VM_RamBase+VM_rPC,a1
	
	; move.l #VM_RamBase,a1
	; move.l #VM_RamBase+VM_rPC,a2
	; LoadLE a2,a1
	
	move.l #1,d4
	jsr Monitor_MemDumpDraw		;Addr A1, Bytes D4

	
	jsr VM_Tick
	
	jsr WaitForPress
	jsr WaitForRelease
	
	
	jmp InfLoop

	
	
	jmp *				;Halt CPU
		

	
WaitForPress:
	jsr Player_ReadControlsDual
	and.l #%00111111,d0
	cmp.b #%00111111,d0
	;jsr Monitor
	;jmp *
	beq WaitForPress		;See if no keys are pressed
	
	cmp.b	#%00101111,d0
	beq NoTrapTest
		;ld c,1				;Trap Number
		;call VM_CauseTrapFromOutsideVM	;Cause a Trap interrupt
	
NoTrapTest:
WaitForRelease:

	move.l #$FFF,d1
PauseD1:
	dbra d1,PauseD1

	jsr Player_ReadControlsDual
	and.l #%00111111,d0
	cmp.b #%00111110,d0
	beq WaitForRelease		;See if no keys are pressed
	rts




Player_ReadControlsDual:		;D0=1up D1=2up ---7654S321RLDU
	
	move.b #%01000000,($A1000B)	; Set direction IOIIIIII (I=In O=Out)
	move.l #$A10005,a0			;RW port for player 2
	jsr Player_ReadOne			;Read buttons
	
	move.l d0,-(sp)
		move.b #%01000000,($A10009)	; Set direction IOIIIIII (I=In O=Out)
		move.l #$A10003,a0		;RW port for player 1
		jsr Player_ReadOne		;Read buttons
	move.l (sp)+,d1
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
		
		

;FU records stage being run.
;OK = no problems
;NG = No Good - Problem occurred at stage marked by FU register
	
;NOTE: Using labels won't work unless we have an ORG statement
;The ORG defines the code as non-Relocatable
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
PrintChar:				;Show D0 to screen
	moveM.l d0-d7/a0-a7,-(sp)
		and.l #$FF,d0			;Keep only 1 byte
		sub #32,d0				;No Characters in our font below 32
PrintCharAlt:		
		Move.L  #$40000003,d5	;top 4=write, bottom $3=Cxxx range
		clr.l d4					;Tilemap at $C000+

		Move.B (Cursor_Y),D4	
		rol.L #8,D4				;move $-FFF to $-FFF----
		rol.L #8,D4
		rol.L #7,D4				;2 bytes per tile * 64 tiles per line
		add.L D4,D5				;add $4------3
		
		Move.B (Cursor_X),D4
		rol.L #8,D4				;move $-FFF to $-FFF----
		rol.L #8,D4
		rol.L #1,D4				;2 bytes per tile
		add.L D4,D5				;add $4------3
		
		MOVE.L	D5,(VDP_ctrl)	; C00004 write next character to VDP
		MOVE.W	D0,(VDP_data)	; C00000 store next word of name data

		addq.b #1,(Cursor_X)	;INC Xpos
		move.b (Cursor_X),d0
		cmp.b #39,d0
		bls nextpixel_Xok
		jsr NewLine			;If we're at end of line, start newline
nextpixel_Xok:
	moveM.l (sp)+,d0-d7/a0-a7
	rts
	
PrintString:
		move.b (a3)+,d0			;Read a character in from A3
		cmp.b #255,d0
		beq PrintString_Done	;return on 255
		jsr PrintChar			;Print the Character
		bra PrintString
PrintString_Done:		
	rts
	
NewLine:
	addq.b #1,(Cursor_Y)		;INC Y
	clr.b (Cursor_X)			;Zero X
	rts	
	
Font:							;1bpp font - 8x8 96 characters 
	incbin "\ResALL\Font96.FNT"
Font_End:		

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
	


	include "\SrcALL\Multiplatform_Monitor.asm"

	org $10800
	
	
TestProgram:
	;dbw braj,TestTrapSys
	
;Test 1 - Flags
	dbw mov16i,$0100						;Move $0100 R0
	dc.b mov16x,RF_R0						;move $01 into FU
	dc.b phfb									;Push F onto stack
	dc.b pl4b									;Pop into R4
	dc.b ph4b
	dc.b pl2b										;PUSHPOP
	dbbw cmp16x,R2_imm16,$0100
	dbw bnej,ProgramFailed

TestAdd:
; Test 2 - ADD
	dc.b movx,ZeroPg_imm8,vm_RFU,$02
	
	dc.b movi,$FE
	dc.b addi,1									;ADD
	dc.b cmpx,RF_imm8,$00
	dbw bnej,ProgramFailed
	dc.b addi,1
	dc.b cmpx,RF_imm8,$03							;Carry+Z
	dbw bnej,ProgramFailed

	
; Test 3 - SUB
	dc.b movx,ZeroPg_imm8,vm_RFU,$03
	
	dc.b addi,1
	
	dc.b subi,1									;SUB
	dc.b cmpx,RF_imm8,$02
	dbw bnej,ProgramFailed
	dc.b subi,1
	dc.b cmpx,RF_imm8,$01							;Carry+Z
	dbw bnej,ProgramFailed
	
TestIncDec:
; Test 4 - INC DEC
	dc.b movx,ZeroPg_imm8,vm_RFU,$04
	dbw mov16i,$FF01
	
	dc.b incz,0									;INC
	dc.b incz,0
	dbw beqj,ProgramFailed
	dc.b incz,0
	
	dc.b decz,1									;DEC
	dc.b decz,1
	dbw beqj,ProgramFailed
	dc.b decz,1
	dbbw cmp16x,R0_imm16,$FC04
	dbw bnej,ProgramFailed

TestSTO:
; Test 5 - STO STO16
	dc.b movx,ZeroPg_imm8,vm_RFU,$05
	dbw mov16i,$1234
	dc.b sto16z,2									;STO16
	dc.b stoz,4									;STO
	dbbw cmp16x,R2_imm16,$1234
	dbw bnej,ProgramFailed
	
	dc.b cmpx,R4_imm8,$34
	dbw bnej,ProgramFailed

	
TestLEA:
; Test 6 - LEA
	dc.b movx,ZeroPg_imm8,vm_RFU,$06
	dc.b leaz,2									;LEA
	dbbbw mov16x,ZeroPg_imm16,4,VM_RamBase
	dc.b movx,ZeroPg_Imm8,4,$02
	dbb cmp16x,R0_R4
	dbw bnej,ProgramFailed
	
TestNEG:	
;Test 7 - NEG SWP16
	dc.b movx,ZeroPg_imm8,vm_RFU,$07
	dbw mov16i,$0000
	dc.b incb
	dc.b NEGb										;NEG
	dbbw cmp16x,R0_imm16,$00FF
	dbw bnej,ProgramFailed
	dc.b NEGb
	dc.b NEGb
	dbw beqj,ProgramFailed
	
	dc.b swp16b									;Swp16
	dbbw cmp16x,R2_imm16,$00FF
	dbw bnej,ProgramFailed
		
TestROL:
;Test 8 - ROL ROR
	dc.b movx,ZeroPg_imm8,vm_RFU,$08
	dc.b movx,rF_imm8,3
	dbw mov16i,$0041	
	dc.b rolb										;ROL
	dbbw cmp16x,R0_imm16,$0083
	dbw bnej,ProgramFailed
	dc.b rolb
	dc.b rolb
	dc.b rolb
	dc.b rolb
	dc.b rolb
	dc.b rolb
	dc.b rolb
	dc.b rolb
	dbbw cmp16x,R0_imm16,$0041
	dbw bnej,ProgramFailed
	dbw mov16i,$0080
	dc.b rolb
	dbw bccj,ProgramFailed
	dbw bnej,ProgramFailed
	
	dbw mov16i,$0041	
	dc.b rorb										;ROR
	dc.b rorb
	dc.b rorb
	dc.b rorb
	dc.b rorb
	dc.b rorb
	dc.b rorb
	dc.b rorb
	dc.b rorb
	dbbw cmp16x,R0_imm16,$0041
	dbw bnej,ProgramFailed
	
TestASL:
;Test 9 - ASL ASR LSL
	dc.b movx,ZeroPg_imm8,vm_RFU,$09
	dbw mov16i,$0043	
	dc.b aslb										;ASL
	dc.b aslb
	dc.b aslb
	dc.b aslb
	dbbw cmp16x,R0_imm16,$0030
	dbw bnej,ProgramFailed
	
	dbw mov16i,$0043	
	dc.b lsrb										;LSR
	dc.b lsrb
	dc.b lsrb
	dc.b lsrb
	dbbw cmp16x,R0_imm16,$0004
	dbw bnej,ProgramFailed
	
	dbw mov16i,$0083	
	dc.b asrb										;ASR
	dc.b asrb
	dc.b asrb
	dc.b asrb
	dbbw cmp16x,R0_imm16,$00F8
	dbw bnej,ProgramFailed
	
TestLogOps:
;Test 10 A - AND OR XOR
	dc.b movx,ZeroPg_imm8,vm_RFU,$0A
	dbw mov16i,$0043	
	
	dc.b andi,$0F									;AND
	dbbw cmp16x,R0_imm16,$0003
	dbw bnej,ProgramFailed
	
	dc.b orri,$7F									;OR
	dbbw cmp16x,R0_imm16,$007F
	dbw bnej,ProgramFailed
	
	dc.b xori,$F0									;XOR
	dbbw cmp16x,R0_imm16,$008F
	dbw bnej,ProgramFailed
	
	dc.b tsti,$80									;TST 
	dbw beqj,ProgramFailed
	dc.b tsti,$40
	dbw bnej,ProgramFailed
	

Test16bit:
;Test 11 B - MOV16b INC16b DEC16b ADD16b SUB16b
	dc.b movx,ZeroPg_imm8,vm_RFU,$0B
	dbw mov16i,$8765
	
	dc.b inc16b									;INC 16
	dbbw cmp16x,R0_imm16,$8766
	dbw bnej,ProgramFailed
	
	dc.b dec16b									;DEC 16
	dbbw cmp16x,R0_imm16,$8765
	dbw bnej,ProgramFailed
	
	dbw add16i,$8000							;16bit add
	dbw bccj,ProgramFailed
	dbbw cmp16x,R0_imm16,$0765
	dbw bnej,ProgramFailed
		
	dbw sub16i,$8000							;16 bit subtract
	dbw bccj,ProgramFailed
	dbbw cmp16x,R0_imm16,$8765
	dbw bnej,ProgramFailed
	

TestTrapSys:
;Test 12 C - TRPb SYSb BRA2 BSR2
	dc.b movx,ZeroPg_imm8,vm_RFU,$0C
	dc.b trpi,1									;Trap Test
	dc.b sysi,1									;System Test
	dbbw cmp16x,R0_imm16,$E4F3
	dbw bnej,ProgramFailed
	
	dbw bsrj,TestSub&$FFFF							;Sub test
	dbbw cmp16x,R0_imm16,$7766
	dbw bnej,ProgramFailed
	
	dc.b inc16b,nopb								
	dc.b bra2										;Skip next 2 bytes
	dc.b inc16b,nopb
	dc.b inc16b,nopb
	dbbw cmp16x,R0_imm16,$7768
	dbw bnej,ProgramFailed
	
	dc.b brai,4									;Skip next 4 bytes
	dc.b inc16b,nopb
	dc.b inc16b,nopb
	
	dbbw cmp16x,R0_imm16,$7768
	dbw bnej,ProgramFailed

	dbw bsr16i,(TestSub-AddressCalc1)&$FFFF			;16 bit Relative Sub test
AddressCalc1:
	dbbw cmp16x,R0_imm16,$7766
	dbw bnej,ProgramFailed
	
	dbbw mov16x,r6_imm16,TestSub2
	dc.b bsrh										;branch to sub in R6/7
	dbbw cmp16x,R0_imm16,$8877
	dbw bnej,ProgramFailed
	
TestAddressing:
;Test 13 D - Addressing Modes
	dc.b movx,ZeroPg_imm8,vm_RFU,$0D	
	
	dbbw mov16x,R0_Addr16,TestLoadAddress		;Store to address
	dbbw cmp16x,R0_imm16,$C0C1
	dbw bnej,ProgramFailed
	
	dbbw mov16x,R6_imm16,(TestLoadAddress+2)&$FFFF
	dbb movx,R0_AtR6							;Indirection
	dbbb cmpx,R0_imm8,$C3
	dbw bnej,ProgramFailed
	
	dbbw mov16x,R2_imm16,(VM_RamBase+16)&$FFFF
	dbb movx,AtR2inc_AtR6						;Autoinc
	dbb movx,AtR2inc_AtR6
	dbb movx,AtR2inc_AtR6
	dbb movx,AtR2inc_AtR6
	dbb movx,AtR2inc_AtR6
	dbbwb cmpx,Addr16_imm8,(VM_RamBase+16+4)&$FFFF,$C3	
	dbw bnej,ProgramFailed
	
	dbbw mov16x,R4_imm16,TestLoadAddress
	dbbb mov16x,R0_AtR4PlIm,4					;Base+Offset
	dbbb cmpx,r0_imm8,$C5
	dbw bnej,ProgramFailed
	
	dbbw mov16x,R6_imm16,$7770
	dc.b ph6b
	dbbw cmp16x,AtSP_imm16,$7770				;Compare to top of stack
	dbw bnej,ProgramFailed
	
	
	
	dc.b mov16i
	dc.w 'OK'
	dc.b HLTb
	
TestSub:	
	dbw mov16i,$7766
	dc.b retb
	
TestSub2:	
	dbw mov16i,$8877
	dc.b retb
	
ProgramFailed:
	dc.b mov16i
	dc.w 'NG'
	dc.b HLTb
		

TestLoadAddress:
	dwle $C0C1
	dwle $C2C3
	dwle $C4C5




TestTrap1:
	dc.b MOVi,$F3
	dc.b RETb
	
	even
TestSysCall1:	
	move.b #$E4,d0
	move.b d0,(VM_RamBase+VM_rR1)
	rts 
	
vm_SysCalls:
	dc.l testhello
	dc.l TestSysCall1

testhello:
	;ld hl,Message			;Address of string
	;Call PrintString		;Show String to screen	
	rts
	
Trap1:
	dc.b MOVi,$EE	
	dc.b RETb
	
Trap2:
	dc.b vm_PHF
	;dc.b vm_MOV+ParamExtByt,Dest_ZeroPg+Param_ZeroPg,VM_rFs,VM_rF
	;dc.b vm_PH0
		dc.b vm_ORR+ParamExtByt,Dest_ZeroPg+Param_Imm8,VM_rF,VM_fTrap 

		dc.b vm_MOV+vm_aIM,$DD
	
	;dc.b vm_AND+ParamExtByt,Dest_Addr8+Param_Imm8
	;dc.b 8,%10111111
	;dc.b vm_MOV+ParamExtByt,Dest_ZeroPg+Param_ZeroPg,VM_rF,VM_rFs
	dc.b vm_PLF
	dc.b vm_RET
	
TestProgram_End:
	even
		
;vm_trap_TableAddr: dc.l vm_Traps
VM_RamBaseAddr: dc.l VM_RamBase


vm_Traps:		
	dw TestProgram
	dw TestTrap1	
	
	include "\SrcALL\ChibiVm_CPU.asm"
	include "\Sources\ChibiVM\ChibiVM_Host.asm"
		
		