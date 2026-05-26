;Put this in your header
	;Macro NSCall,p1
		;dbb SYSi,syscallNS
		;db \p1
	;endm


	
;syscallMB equ 9
	

;As these commands are likely to be time sensitive, we've overriden the register loads
;with our own minimal ones.	
	
mbSetpixel equ 0;+regNO
mbGetpixel equ 1;+regNO
mbSettile equ 2;+regNO
mbGettile equ 3;+regNO

vecMB:
	dc.l mpbitmap_setpixel_Reikou	;0
	dc.l mpbitmap_getpixel_Reikou	;1
	dc.l mpbitmap_settile_Reikou	;2
	dc.l mpbitmap_gettile_Reikou	;3



	
MBCall:	
	move.l #vecMB,a6
	jmp ChibiVM_VectorCall
	
	
	
;regNO equ %11000000		;Don't Read or Write Regs
;regRR equ %10000000		;Only Read Regs
;regWW equ %01000000		;Only Write Regs


mpbitmap_setpixel_Reikou:
	jsr mpbitmap_setpixel
	move.l #$66660006,d7
	rts
	
mpbitmap_getpixel_Reikou:	

	jsr mpbitmap_getpixel	
	move.l #$66660006,d7
	move.l (VM_RamBaseAddr),a0
	move.b d0,(VM_rR0,a0)
	rts

mpbitmap_settile_Reikou:
	jsr AddressRemapViaTableHLA3
	
	;jsr monitor
	;jmp $
	jsr mpbitmap_settile
	
	;jsr monitor
	
	move.l (VM_RamBaseAddr),a0
	jsr VM_SaveA3
	 move.l #$66660006,d7
	
	; clr.l d0
	; clr.l d1
	; clr.l d2
	; clr.l d3
	; clr.l d4
	; clr.l d5
	; clr.l d6
	
	; move.l (VM_RamBaseAddr),a3
	; move.b (VM_rR7,a3),d3
	; move.b d3,d6
	; asl.l #8,d6
	; move.b (VM_rR6,a3),d6
	; jsr monitor
	;jmp $
	
	rts
	
mpbitmap_gettile_Reikou:
	jsr AddressRemapViaTableHLA3
	jsr mpbitmap_gettile
	
	move.l (VM_RamBaseAddr),a0
	jsr VM_SaveA3
	 move.l #$66660006,d7
	rts
	
	ifd BuildGEN
		include "srcgen/GEN_V1_MultiplatformBitmap.asm"
	endif
	
	ifd BuildX68
		include "SrcX68/X68_V1_MultiplatformBitmap.asm"
	endif
	
	ifd BuildSQL
		include "SrcSQL/SQL_V1_MultiplatformBitmap.asm"
	endif
	
	ifd BuildAMI
		include "SrcAMI/AMI_V1_MultiplatformBitmap.asm"
	endif
	
	
	ifd BuildAST
		include "SrcAST/AST_V1_MultiplatformBitmap.asm"
	endif
	
	