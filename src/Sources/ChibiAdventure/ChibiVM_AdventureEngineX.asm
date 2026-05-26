

	Macro AdvXCall,p1
		dbb SYSi,syscallAdvX
		db \1
	endm

;Extended functions to improve the Adventure Engine, and reduce
; CPU load from ChibiVM

syscallAdvX equ 11
syscallLoadMultiReg equ 8

axCaseBra equ 0+regNO
axCase8bit equ 1+regNO
axCase16bit equ 2+regNO
axDoCpir equ 3+regNO
axMonitor equ 4+regNO
axMemDump equ 5+regNO
axMonitors equ 6+regNO
AxMemDumpCust equ 7
AxMonitorSetCP equ 8
AxBClsl2 equ 9
AxBClsl3 equ 10
AxBClsl4 equ 11
AxBClsl5 equ 12
AxBClsl6 equ 13
AxBClsl7 equ 14
AxPrintSeqCP equ 15
AxPrintSeqCPBC equ 16
AxPrintSeqCPBCDE equ 17
AxSetCP equ 18
AxGetCP equ 19

vecAdvXCall:
	dc.l case_Branch			;0
	dc.l case_8Bit			;1
	dc.l case_16Bit			;2
	dc.l docpir				;3
	dc.l AdxMonitor 			;4 - Show and pause
	dc.l AdxMemDump 			;5
	dc.l AdxMonitorS			;6 - Just show
	dc.l AdxMemDumpCust			;7 - Show Mem from HL BC
	dc.l AdxMonitorSetCP      ;8 - Set CursorPos
	dc.l MaxTileBClsl2		;9
	dc.l MaxTileBClsl3		;10
	dc.l MaxTileBClsl4		;11
	dc.l MaxTileBClsl5		;12
	dc.l MaxTileBClsl6		;13
	dc.l MaxTileBClsl7		;14
	dc.l PrintSeqCP			;15
	dc.l PrintSeqCPBC			;16
	dc.l PrintSeqCPBCDE 	    ;17
	
AdvXLast equ 15

AdvX_Call:	

	move.l #vecAdvXCall,a6
	jmp ChibiVM_VectorCall
	

	

adxmemdump:
	move.l (vm_rambaseAddr),a0
	move.l (vm_rambaseAddr),a3
	loadLEA0 vm_rpc,a3		;Load Little endian A3 from A0
							;(Program Counter)
							;A3=address to show
	move.b (a3)+,d5
	move.b (a3)+,d2			;DE=Address
	
	clr.l d0
	move.b d2,d0			;D2.D5 (LE) -> address
	lsl.l #8,d0
	add.l d5,d0
	add.l a0,d0
	move.l d0,a2
	
	move.b (a3)+,d1			;B=LineCount
	pushde
		move.b (a3)+,d5		;Ypos 
		jsr adxmonitorsetcp
		move.b (a3)+,d4		;Flags

		move.l (VM_RamBaseAddr),a0
		storeLEa0 a3,vm_rpc		;Store new PC
	pophl
	
adxmemdumpcust:
    btst #1,d4				;Header?
	beq adxmonitorb

	jsr memdumpheaderlessadv
	bra adxmonitorc

adxmonitors:
	clr.l d4
	bra adxmonitorsb

	
	
adxmonitor:
	moveq.l #3,d4			;Pause+Header

adxmonitorsb:
	moveq.l #$0c,d5			;Ypos
	jsr adxmonitorsetcp

	move.l (vm_rambaseAddr),a3
	moveq.l #4,d1
	
	jsr memdumpadv   		;show memory to screen

	move.l (vm_rambaseAddr),a0
	add.l #vm_stacktop-16,a3   ;address to show
	moveq.l #2,d1      		;lines to show
	jsr memdumpadv    		;show memory to screen

	move.l (vm_rambaseAddr),a0
	move.l (vm_rambaseAddr),a3
	loadLEA0 vm_rpc,a3		;Load Little endian A3 from A0
							;(Program Counter)
	move.l #1,d1       		;lines to show
adxmonitorb:
	jsr memdumpadv 			;show memory to screen  

adxmonitorc:
    btst #0,d4
	beq lbl_4E4CxF2B3
		jsr waitforfire
lbl_4E4CxF2B3
	move.b (advcursorpos_mon),d5	;Restore CursorPos
	move.b d5,(advcursorpos)
	move.b (advcursorpos_mon+1),d2
	move.b d2,(advcursorpos+1)
	
	move.l #$66660006,d7	;Tell ChibiVM not to update registers 
	rts


	
adxmonitorsetcp:
	move.b (advcursorpos),d7		;Backup CursorPos
	move.b (advcursorpos_mon),d7
	
	move.b (advcursorpos+1),d7
	move.b (advcursorpos_mon+1),d7
	
	clr.l d2
	move.b d2,(advcursorpos+1)		;Xpos=0
	move.b d5,(advcursorpos)		;Store New Ypos 
	rts

