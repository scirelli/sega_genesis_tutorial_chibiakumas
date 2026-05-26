Cursor_X equ VM_HostRam
Cursor_Y equ VM_HostRam+1
vm_trap_TableAddr equ VM_HostRam+4
vm_remap_TableAddr equ VM_HostRam+8


VM_StackTop equ $200
;VM_ProgDest equ VM_ProgLoadAddr


	;clr.b Cursor_X
	;clr.b Cursor_Y
	
ChibiVM_Init:
	
;Clear Low Ram
	move.l (VM_RamBaseAddr),a0	
	move.w #512/4,d0
ChibiVM_Init_Clear:	
	clr.l (a0)+
	dbra d0,ChibiVM_Init_Clear

;Set defaults	
	ifd vm_traps
		move.l #vm_traps,(vm_trap_TableAddr)
		clr.l d0
		move.b (vm_traps+1),d0
		asl #8,d0
		move.b (vm_traps),d0		;Load execute address from Trap 0
		add.l (VM_RamBaseAddr),d0
		move.l d0,d6
		
	else 
		move.l #VM_ProgLoadAddr,d6	;Execute address
		add.l (VM_RamBaseAddr),d6
	endif
	
	move.l #VM_StackTop,d7			;Stack Pointer
	add.l (VM_RamBaseAddr),d7
	
	move.l #VM_ProgLoadAddr,a5		;Program Ram Base (Rom copy address)
	move.l (VM_RamBaseAddr),d0
	add.l d0,a5
	
;Default Memory Mapping
	move.l (VM_RamBaseAddr),a3
	move.l #vm_rBank0,d0		;Memory map settings
	add.l d0,a3
	
	clr.l d0
	move.l (VM_RamBaseAddr),d1
	jsr SetLEA3D0
	addq.l #4,d0
	
	move.l (VM_RamBaseAddr),d1
	add.l #$4000,d1
	jsr SetLEA3D0
	addq.l #4,d0
	
	move.l (VM_RamBaseAddr),d1
	add.l #$8000,d1		;8000
	jsr SetLEA3D0
	addq.l #4,d0
	
	move.l (VM_RamBaseAddr),d1
	add.l #$C000,d1		;C000
	jsr SetLEA3D0
		
;Seek a 'Rom Header'
	move.l #TestProgram,a6		;Start of program ROM
	jsr FindHeader 				;Look for a header key
	
	move.l (VM_RamBaseAddr),a0
	StoreLEA0 d7,VM_rSP			;Stack Pointer
	StoreLEA0 d6,VM_rPC			;Program counter
		
	;jsr Monitor
;Transfer the program to VM Ram
	move.l #TestProgram_End-TestProgram,d1
CopyProgram:
	move.b (a6)+,(a5)+			;Copy D1+1 bytes from A3 to A2
	subq.l #1,d1
	bne CopyProgram
	rts
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;The header can be on any $xx00 boundary, but must start with this
;Key string
HeaderMagicKey: dc.b "!!!!Chibi/VM!!!!"
			
GetLEA3D0:	;Load a 32 bit Little endian value from A3+D0 -> D1
	clr.l d1
	move.b (3,a3,d0),d1
	asl.l #8,d1
	move.b (2,a3,d0),d1
	asl.l #8,d1
	move.b (1,a3,d0),d1
	asl.l #8,d1
	move.b (0,a3,d0),d1
	rts
	
SetLEA3D0:	;Load a 32 bit Little endian value from A3+D0 -> D1
	move.b d1,(0,a3,d0)
	lsr.l #8,d1
	move.b d1,(1,a3,d0)
	lsr.l #8,d1
	move.b d1,(2,a3,d0)
	lsr.l #8,d1
	move.b d1,(3,a3,d0)
	rts

MagicKeyNG:
	add.l #256,a3				;Move to next block
	subq.w #1,d2				;Try 256 times
	bne MagicKeySearchAgain		;Try again
	rts							;Mo Magic Key - return to caller
	
FindHeader:	
	move.l a6,a3		;TestProgram addr
	move.w #256,d2		;Scan $00oo-$FFoo in 256 byte increments
MagicKeySearchAgain:	
	move.l #HeaderMagicKey,a0	;Key to find
	move.l a3,a2
	move.l #4-1,d1				;Longs to scan -1
MagicKeySearching:		
	cmp.l (a0)+,(a2)+			;Check this 4 byte block
	bne MagicKeyNG				;Failed? Then give up!
		
	dbra d1,MagicKeySearching
	
	;Key Found! Header is at A3
	
	
;SP/PC/LoadAddr	
	move.l #$0040,d0
	jsr GetLEA3D0
	add.l (VM_RamBaseAddr),d1
	move.l d1,d6			;Default Program Counter
	move.l d1,a5			;Load address
	
	move.l #$0044,d0
	jsr GetLEA3D0
	move.l d1,d7 			;Stack pointer
		
;Trap Table	
	move.l a6,d2			;Base of ROM addr
	move.l #$0070,d0
	jsr GetLEA3D0
	
	tst.l d1
	beq Header_NoTrapTable
	add.l d2,d1				;For trap table addr relative to prog start
		
	move.l d1,a1
	move.l a1,(vm_trap_TableAddr) ;Trap table in 'ROM'
	
	clr.l d0
	move.b (1,a1),d0			;First entry is execute address
	asl.l #8,d0
	move.b (0,a1),d0
	
	add.l (VM_RamBaseAddr),d0
	move.l d0,d6				;Run address from Trap 0
		
	move.l #$0048,d0			;Address table of Traps in RAM
	jsr GetLEA3D0				; (Recommended $0100)
	tst.l d1
	beq Header_NoTrapTable		;0=Don't copy to RAM
	move.l d1,a2				;RamTrapTable
	add.l (VM_RamBaseAddr),a2
		
Header_CopyTrapTable:		;Copy ROM trap table to RAM
	move.b (a1)+,d0
	move.b d0,(a2)+			;Byte 1 (L)
	move.b (a1)+,d1
	move.b d1,(a2)+			;Byte 2 (H)
		
	or.b d0,d1
	bne Header_CopyTrapTable ; Both Bytes 0 - Yes= End of table?
	
Header_NoTrapTable:
	
;Copy Address space layout
	move.l a3,a0
	add.l #$004C,a0
	move.l (VM_RamBaseAddr),a1 ;Copy Default address map
	add.l #vm_rBank0,a1
	move.l #32-1,d0
Header_CopyAddressMap:	
	move.b (a0)+,(a1)+
	dbra d0,Header_CopyAddressMap
	
;Address Remap table address	
	move.l #$0074,d0		;Address Remap Table
	jsr GetLEA3D0
	;add.l d2,d1		;For remap table addr relative to prog start
	move.l d1,(vm_remap_TableAddr)		;remap table in 'ROM'
	
	rts
		
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
	

VM_Run_WithMonitor:	
	move.b #12,Cursor_Y
	clr.b Cursor_X
	
	;jsr Monitor_MemDump		;Dump 6 lines from  $00000000
	;dc.l MaxTileTilemap
	;dc.w $2
	
	
;ZeroPage
	;jsr Monitor_MemDump		;Dump 6 lines from  $00000000
	;dc.l vm_rambase
	;dc.w $6
	
	move.l (VM_RamBaseAddr),a0
 	moveq.l #6,d0
	jsr Monitor_MemDumpDirect
	
;Stack
	move.l (VM_RamBaseAddr),a0
	add.l #VM_StackTop-16,a0
 	moveq.l #1,d0
	jsr Monitor_MemDumpDirect

	;jsr Monitor_MemDump		;Dump 6 lines from  $00000000
	;dc.l VM_StackTop-16
	;dc.w $2
	
;Program
	move.l (VM_RamBaseAddr),a1
	move.l (VM_RamBaseAddr),a0
	LoadLEA0 VM_rPC,a1
	
	; move.l (VM_RamBaseAddr),a1
	; move.l (VM_RamBaseAddr)+VM_rPC,a2
	; LoadLE a2,a1
	
	move.l #1,d4
	jsr Monitor_MemDumpDraw		;Addr A1, Bytes D4
	
Vm_NoMonitor:	
	jsr VM_Tick
	jsr WaitForPress
	
	jmp VM_Run_WithMonitor	
			
			

AddressRemapViaTableHLA3:
	move.l a3,d6
	and.l #$FFFF,d6
AddressRemapViaTableHL:
	cmp.l #$1FF,d6			;first 511 bytes of VM ram for 32 bit remaps
	bgt AddressRemapViaTableHL_Done
	
	move.l (VM_RamBaseAddr),d7
	add.l (vm_remap_TableAddr),d7
	move.l d7,a3
	
	;move.l #$2000,(vm_remap_TableAddr)
	
	
	; move.l (vm_remap_TableAddr),d0
	 ;jsr Monitor
	 ;jmp $
; iii
	; move.b	d0,$300001		;REG_DIPSW -Kick watchdog
	; jmp iii
		
	asl.l #2,d6 ;*4 bytes per entry
	
	;move.l (a6,d3),a3		;remap table in 'ROM'
	
	ifd vmAddressRemap_BigEndian
		move.l (a3,d6),d7
		
	else
		clr.l d7
		move.b (3,a3,d6),d7
		asl.l #8,d7
		move.b (2,a3,d6),d7
		asl.l #8,d7
		move.b (1,a3,d6),d7
		asl.l #8,d7
		move.b (0,a3,d6),d7
	endif
	move.l d7,a3
	move.l d7,d6
	jmp AddressRemapViaTableHL_16bit
	
AddressRemapViaTableHL_Done:
	move.l a3,d6
	
AddressRemapViaTableHL_16bit:	
	cmp.l #$FFFF,d6	
	bgt AddressRemapViaTableHL_Done2
	add.l (VM_RamBaseAddr),d6
	move.l d6,a3
AddressRemapViaTableHL_Done2:	

	rts