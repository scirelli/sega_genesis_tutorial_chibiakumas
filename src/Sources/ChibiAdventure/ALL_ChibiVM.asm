;compile with option: VASM GEN

	include "header.asm"
	
	include "SrcALL/ChibiVm_InstSet.asm"
	include "SrcALL/BasicMacros.asm"

	ifd BuildSQL
VM_RamBase equ $30000
VM_HostRam equ $003F000	;Variables for our Emulator
	endif
	
	ifd BuildNEO
VM_RamBase equ $100000
VM_HostRam	equ $10FE00	;Variables for our Emulator
	endif
	
	ifd BuildGEN
VM_RamBase equ $00FF0000
VM_HostRam	equ $00FFFE00	;Variables for our Emulator
	endif
	
	ifd BuildAST
VM_RamBase equ ramarea+65536	
VM_HostRam	equ ramarea+$1FE00	;Variables for our Emulator
	endif
	
	
VM_ProgLoadAddr equ $400	


	ifd BuildAST
		and.l  #$FFFF0000,(VM_RamBaseAddr)	;Ensure VM ram ends $????0000
	endif
	ifnd VM_RamBase
		and.l  #$FFFF0000,(VM_RamBaseAddr)	;Ensure VM ram ends $????0000
	endif

	jsr ChibiVM_Init

	
	;jsr Monitor_MemDump		;Dump 6 lines from  $00000000
	;dc.l TestProgram
	;dc.w $2
	
	;jsr Monitor_MemDump		;Dump 6 lines from  $00000000
	;dc.l VM_RamBase+VM_ProgLoadAddr
	;dc.w $2
	;jmp $
	
	jsr VM_Run_WithMonitor
	
VM_Run:	
	jsr VM_Tick
	jmp VM_Run
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	

	
	include "../ChibiVM/Multiplatform_MonitorA.asm"
	include "ChibiVM_AdventureEngine.asm"
	include "Sources/ChibiVM/ChibiVM_Host.asm"
	
	
	
	;rorg $10000	;Needed for some reason - somethings messing up the next org otherwise
		



	;rorg $10000+VM_ProgLoadAddr
	
	
	ifd NeedReorg 
		rorg $10000
	endif 
	
TestProgram:	
	incbin "\ResAll\ChibiVM\NumberGuess.rom"
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
VM_RamBase2:
		ds.b 65536*2
VM_HostRam:	
		ds.b 256
	endif
	
	even
	include "SrcALL/ChibiVm_CPU.asm"		
	
	even
	include "core.asm"
	include "footer.asm"
	
	
	;Variables for our Emulator

