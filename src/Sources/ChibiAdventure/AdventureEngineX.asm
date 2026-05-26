
PrintSeqXVarRam equ ramarea+4
AdvCursorPos equ ramarea+8
AdvCursorPos_Mon equ ramarea+10		;Backup of Cursorpos for monitor use
		
		

printseqcpinline:
	move.l (sp)+,a3			;Print sequence (address after call)
	jsr printseqcp
	move.l a3,-(sp)
	rts

	
printseqcpbcde:	;PrintSeq A3 at pos D2,D5 with vars A1
	move.b d5,(advcursorpos)
	move.b d2,(advcursorpos+1)

printseqcpbc:	;PrintSeq A3 with vars A1
	move.l a1,(printseqxvarram)
	
PrintSeqCP:		;PrintSeq A3 at CursorPos
	pushbc
	pushde
		move.b (advcursorpos),d5
		move.b (advcursorpos+1),d2
		jsr printseq
		move.b d5,(advcursorpos)
		move.b d2,(advcursorpos+1)
	popde
	popbc
	rts

	
GetCP:			;Return CursorPos in D2,D5
	clr.l d5
	clr.l d2
	move.b (advcursorpos),d5
	move.b (advcursorpos+1),d2
	rts

	
PrintCharCP:	;Print char R0 at cursor pos CP
	move.b (advcursorpos),d5
	move.b (advcursorpos+1),d2
	jsr printchar

	
SetCP:			;Set CursorPos to D2,D5
	move.b d5,(advcursorpos)
	move.b d2,(advcursorpos+1)
	rts

	
printseqxvar_showdecimalsigned:
	move.b #' ',d1					;Positive
	btst #7,d0						;Test sign
	beq printseqxvar_showdecimalb

	move.b #'-',d1					;Negative sign
	neg.b d0						
printseqxvar_showdecimalb:
	movem.l d0,-(sp)
		clr.l d0
		move.b d1,d0		
		jsr printchar				;Sbow +-
	movem.l (sp)+,d0
          
	;jmp showdecimal				;Show Digit

printseqxvar_showdecimal:
	jmp showdecimal

	
	
    ifd showbinary
printseqxvar_showbinary:
		move.b (a3)+,d0
		jmp showbinary
	endif

    ifd showflags
printseqxvar_showflags:
		move.b (a3)+,d0
		jmp showflags
	endif

printseqxvar_printseq:
	jmp printseq

printseqx_vec:
	dc.l printseqxvar_null 			;0
	dc.l printseqxvar_showdecimal 	;1 0-255
	dc.l printseqxvar_showdecimalsigned ;2 -128 to +127
	dc.l printseqxvar_showhex 		;3 &00-&FF
	dc.l printseqxvar_printchar 	;4 A-Z
	dc.l printseqxvar_showhex16 	;5 Native (LE/BE 16/32 bit) &0000-&FFFF
	dc.l printseqxvar_printseq 		;6 String inline (sequence in vars)
	dc.l printseqxvar_printseqaddr 	;7 Address of string
									;   (Address in vars - native LE/BE )
	dc.l printseqxvar_addn 			;8 Skip vars +?  eg 250,8,2
	dc.l printseqxvar_subn 			;9 Skip vars -?  eg 250,9,-2
	dc.l printseqxvar_showhex16 	;10 16 bit &0000-&FFFF
	dc.l printseqxvar_printseqaddr 	;11
	dc.l printseqxvar_printseqaddr 	;12
	dc.l printseqxvar_printseqi 	;13 String inline (address in Printeeq)

	
printseqxvar:		
	clr.l d0
	move.b (a3)+,d0			;Get SeqX commmand 
		
	pushbc
	pushhl
		clr.l d4
		move.b (a3),d4  	;for add/sub

		move.l #printseqxvardoner,a0
		move.l a0,-(sp)     	;return addreess

		move.l (printseqxvarram),a3

        ifd showflags
			cmp.b #128,d0
			beq printseqxvar_showflags   ;128 monitor flags
		endif
        ifd showbinary
			cmp.b #129,d0
			beq printseqxvar_showbinary   ;14 binary
		endif
		ifd PrintCharMultiByteI
			cmp.b #130,d0
			beq PrintCharMultiByteI	;Multibyte Inline (in seq)
		endif
		ifd PrintCharMultiByteP
			cmp.b #131,d0
			beq PrintCharMultiByteP	;Multibyte Pointer (in seq) 
		endif
		
		ifd PrintCharMultiByteV
			cmp.b #132,d0
			beq PrintCharMultiByteV	;Multibyte Pointer (in vars) 
		endif
		
		ifd SeqTextTypeSpeed
			cmp.b #133,d0
			beq TypeSpeedSet
			cmp.b #134,d0
			beq TypeSpeedPause
		endif 
		cmp.b #15,d0 		;>=15 = invalid value!
		bcs lbl_6C94x66EB
			rts
lbl_6C94x66EB

        asl #2,d0			;4 bytes per command

		move.l #printseqx_vec,a0
		move.l (a0,d0),d0	;Get the command
		move.l d0,-(sp)		;Run this on ret
		
		clr.l d0
		move.b (a3)+,d0		;Get the variable byte
		
printseqxvar_null:
	rts

	
printseqxvardoner:
		move.l a3,(printseqxvarram)		;Store new Vars address

printseqxvardonea:	
	pophl
	popbc
	jmp printseq			;Continue printSeq 

	
	


	ifd SeqTextTypeSpeed
TypeSpeedSet:	;133
		move.b d4,(SeqTextTypeSpeed)
		bra PrintSeqXVar_CustomFinish
		
TypeSpeedPause:	;134
		move.l #255,d0
		jsr pausea
		subq.b #1,d4
		bne TypeSpeedPause
		bra PrintSeqXVar_CustomFinish
	endif
	
	
	
printseqxvar_subn:
			or.l #$FFFFFF00,d4	;D4 is negative 

printseqxvar_addn:
			subq.l #1,a3        ;we already did an inc A3
			add.l d4,a3			;Add D4
			
PrintSeqXVar_CustomFinish:
			move.l a3,(printseqxvarram)
			movem.l (sp)+,d0   	;remove ret 
		pophl
		addq.l #1,a3			;One byte used for offset
	popbc
	jmp printseq				;Continue printSeq 
	
	
printseqxvar_showhex16:
	move.b d0,d1				;L Byte

	move.b (a3)+,d0				;H byte
	jsr printseqxvar_showhex	;Show H Byte 

	move.b d1,d0				;Show L Byte 
	;jmp showhex
printseqxvar_showhex:
		movem.l d1/d4,-(sp)
			move.w d0,d4
			move.w d4,d1
			and.w #%11110000,d1		;Get High Nibble
			ror.b #4,d1	
			jsr PrintHexCharSeq
			
			move.w d4,d1
			and.w #%00001111,d1		;Get Low Nibble
			jsr PrintHexCharSeq	
		movem.l (sp)+,d1/d4
		rts
		
PrintHexCharSeq:	
		move.l d1,d0				
		and.l #$FF,d0
		cmp.b #9,d0					;0-0?
		ble PrintHexCharLessThan10Seq
		add.w #'A'-10,d0			;Shift to A-F
		jmp PrintChar
PrintHexCharLessThan10Seq:		
		add.w #'0',d0				;Show Char 
		;jmp PrintChar	
	
printseqxvar_printchar:
	jmp printchar

	
printseqxvar_printseqaddr:
	subq.l #1,a3        ;we already did an inc hl
	move.l (a3),d1		;Get address from Vars  

	pushhl
		move.l d1,a3
		jsr printseq
	pophl
	rts
	
	
printseqxvar_printseqi:
	move.l (sp)+,d0    ;consume ret
	
	move.l (sp)+,a0
		move.l (a0)+,a3	;Get address from Sequence
	move.l a0,-(sp)
	
	jsr printseq
	bra printseqxvardonea



		
		
maxtilebclsl7:		;Shift a 16 bit pair in 8 bit registers D1.D4
	asl.b #1,d4
	roxl.b #1,d1
maxtilebclsl6:
	asl.b #1,d4
	roxl.b #1,d1
maxtilebclsl5:
	asl.b #1,d4
	roxl.b #1,d1
maxtilebclsl4:
	asl.b #1,d4
	roxl.b #1,d1
maxtilebclsl3:
	asl.b #1,d4
	roxl.b #1,d1
maxtilebclsl2:
	asl.b #1,d4
	roxl.b #1,d1
	asl.b #1,d4
	roxl.b #1,d1
	rts

	
;use a bitmask to set 16 bit values %0246xxxx
loadmultireg:
	move.l (vm_rambaseAddr),a0
	move.l (vm_rambaseAddr),a3
	loadLEA0 vm_rpc,a3		;Load Little endian A3 from A0
							;(Program Counter)
							
	move.b (a3)+,d0			;get 1 byte after ret addr

	move.l (vm_rambaseAddr),a2
	jsr loadmultireg4 		;r0/r1 r2/r3 r4/r5 r6/r7

	move.l (vm_rambaseAddr),a2
	add.l #16,a2
	;jsr loadmultireg4 		;addr 16+17 18+19 20+21 22+23

loadmultireg4:
	move.l #4,d7			;Number of regpairs to transfer
	
loadmultiregagain:
    roxl.b #1,d0			;Transfer this one?
	bcc loadmultiregskip

	move.b (a3)+,d6			;Transfer this register 
	move.b d6,(a2)+
	move.b (a3)+,d6
	move.b d6,(a2)+

	bra loadmultiregskipb

loadmultiregskip:
	addq.l #2,a2			;Skip a reggpair

loadmultiregskipb:
    subq.b #1,d7
	bne loadmultiregagain
	
	move.l (VM_RamBaseAddr),a0
	storeLEa0 a3,vm_rpc		;Store PC
	rts

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	

;Source/Dest SS/DD
srcBC equ 0 ;BC
SrcIm equ 1 ;Imm
srcDE equ 2 ;DE
SrcIX equ 3 ;IX+n

dstBC equ 0*4 ;BC
dstIm equ 1*4 ;Imm
dstDE equ 2*4 ;DE
dstIX equ 3*4 ;IX+n


case_8bit:
	jsr processcase8
	bra case_16bitb		;Store new R0

case_16bit:
	jsr processcase16

case_16bitb:
	bcc case_RTS_tovm
	move.l (VM_RamBaseAddr),a0
	storeLEa0 d1,vm_rr0   ;new r0
	move.l #$66660006,d7	;Tell ChibiVM not to update registers 
	rts

	
case_branch:
	jsr processcase16
	bcc case_RTS_tovm		 ;CC=mo match? return
	move.l (VM_RamBaseAddr),a0
	storeLEa0 d1,vm_rpc		;Store PC  ;new pc (execute result)
	
case_RTS_tovm:
	move.l #$66660006,d7	;Tell ChibiVM not to update registers 
	rts

	
	
processcase8:
	move.l #0,d3 ;16 bit result marker
	bra processcaseb

processcase16:
	move.l #1,d3	;16 bit result marker
	
processcaseb:
	move.l (vm_rambaseAddr),a0
	move.l (vm_rambaseAddr),a3     ;A3/HL=case array
	loadLEA0 vm_rr6,a3

	loadLEA0 vm_rr0,d4	 ;test byte 1
	loadLEA0 vm_rr2,d5   ;test byte 2
	

processcase:	;for use without vm
processcaseagain:   ;compare D4 to D5 using table (A3)
	move.b (a3)+,d0
	move.b d0,d6  ;command %ccc6ddss
	move.l d5,-(sp)
	move.l d4,-(sp)
		
		move.l d0,-(sp)
			tst.b d0
			beq processcasenotfound

			jsr processcasesrcdest  ;%------ss
			move.l d7,d5

		move.l (sp)+,d0
		lsr.b #2,d0  	;get dest bits %
		jsr processcasesrcdest ;%----dd--

		move.l d6,d4	;Command
		move.l d7,d2    ; d5/d2 d/e = compare params  bhl unused
		jsr objectanimator_processcondition  ;%ccc----- = condition
	
	bcc processcaseng
	move.l (sp)+,d4
	move.l (sp)+,d5
		
	move.b (a3)+,d1      ;match - return result

	tst.b d3    		;16 bit result? (L Byte)
	beq processcasefound
	
	clr.l d0
	move.b (a3),d0		;H byte
	asl.l #8,d0
	add.l d0,d1

processcasefound:
    ORI #%00000001,CCR    ;set carry (found)
	rts

processcasenotfound:
	move.l (sp)+,d0			
	move.l (sp)+,d5
	move.l (sp)+,d4

	ANDI #%11111110,CCR   ;clear carry (not found)
	rts

	
processcaseng:
	move.l (sp)+,d4
	move.l (sp)+,d5

	addq.l #1,a3
	cmp.b #0,d3
	beq processcaseagain
	addq.l #1,a3
	bra processcaseagain

	
	
processcasesrcdest:	 ;a=mode d7=16 bit param
    move.l d4,d7			;0=BC
	and.b #%00000011,d0
	beq processcasesrcdest_Ret
	
	subq.l #1,d0			;1=Imm
	beq processcase_founddestimm
	
    move.l d5,d7			;2=DE
	subq.l #1,d0
	beq processcasesrcdest_Ret
	
	move.l a5,-(sp)			;3=IX+n

		clr.l d0
		move.b (a3)+,d0		;A5+n (IX+n)
		add.l d0,a5
		
		clr.l d7
		move.b (0,a5),d7
		
	move.l (sp)+,a5
processcasesrcdest_Ret:
	rts

processcase_founddestimm:
	move.b (a3)+,d7		;Imm8
	rts
	
	

docpir:
	move.l (vm_rambaseAddr),a0
	move.l (vm_rambaseAddr),a3
	
	loadLEA0 vm_rr6,a3		;Address of values 
	loadLEA0 vm_rr2,d1		;Byte Count
	
	move.b (vm_rr0,a0),d0	;Compare Value 
	
	move.l (vm_rambaseAddr),a6
	add.l #vm_rf,a6
	bclr.b #1,(a6)			;Clear Zero flag (not found)
	
docpirAgain:	
	cmp.b (a3)+,d0   		;compare a to (hl)+ , repeat bc times
	beq docpirDone			; fz=true if found
		
	subq.b #1,d1
	bne docpirAgain
		
docpirDoneFinish:		
	move.l (VM_RamBaseAddr),a0
	storeLEa0 d1,vm_rr2		;Update Bytecount 
	storeLEa0 a3,vm_rr6		;Update Address 

	move.l #$66660006,d7	;Tell ChibiVM not to update registers 
	rts
	
docpirDone:	
	bset.b #1,(a6)			;Set Zero flag on VM (Found)
	jmp docpirDoneFinish	;Not found

	
;CPIR: 
;bc=count of bytes
;(hl) bytes to compare to a
;de is unused
;z is set if a equals (hl); otherwise, it is reset.



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ifnd objectanimator_processcondition
	
objectanimator_processcondition:  ;c=condition d/e = compare params
		lsr.l #5,d4
		and.l #%00000111,d4
		
		; jsr monitor
		; jmp $
		
		beq objectanimator_processconditiontrue ;0

		move.b d2,d0
		
		subq.b #1,d4
		beq objectanimator_processconditioneq ;1 eq

		subq.b #1,d4
		beq objectanimator_processconditionne ;2 ne

		subq.b #1,d4
		beq objectanimator_processconditioncs ;3 cs

		subq.b #1,d4
		beq objectanimator_processconditioncc ;4 cc

		subq.b #1,d4
		beq objectanimator_processconditionteq ;5 tstz

		subq.l #1,d4
		beq objectanimator_processconditiontne ;tstnz
		
		move.b timer_ticksoccured,d0
		and.b d2,d0
		beq objectanimator_processconditiontrue
		bra objectanimator_processconditionfalse

objectanimator_processconditionteq:
		and.b d5,d0
		beq objectanimator_processconditiontrue
		bra objectanimator_processconditionfalse

objectanimator_processconditiontne:
		and.b d5,d0
		bne objectanimator_processconditiontrue
		bra objectanimator_processconditionfalse
		
objectanimator_processconditioncs:
		cmp.b d5,d0
		bcs objectanimator_processconditiontrue
		bra objectanimator_processconditionfalse

;                                     objectanimator_processconditioncc:
objectanimator_processconditioncc:
		cmp.b d5,d0
		bcc objectanimator_processconditiontrue
		bra objectanimator_processconditionfalse

objectanimator_processconditionne:
		cmp.b d5,d0
		bne objectanimator_processconditiontrue
		bra objectanimator_processconditionfalse

objectanimator_processconditioneq:
		cmp.b d5,d0
		beq objectanimator_processconditiontrue

objectanimator_processconditionfalse:
		clr.l d4			;used as objectanimator_useiy for non conditions
		ANDI #%11111110,CCR			;Clear carry
		rts

objectanimator_processconditiontrue:
		;scf
		clr.l d4			;used as objectanimator_useiy for non conditions
		ORI #%00000001,CCR	;Set carry
		rts
	endif	