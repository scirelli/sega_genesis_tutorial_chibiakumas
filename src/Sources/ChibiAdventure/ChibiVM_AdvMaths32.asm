;                                     mathlsr32:        ;9 r6.r4>>r0
mathlsr32:
	cmp.b #0,d0
	bne lbl_751ExB803
	rts
lbl_751ExB803

	lsr.b d3
	roxr.b d6
	roxr.b d2
	roxr.b d5

	subq.l #1,d0
	bra mathlsr32

mathlsl32:    ;10 r6.r4<<r0
	cmp.b #0,d0
	bne lbl_7FD0xE996
	rts
lbl_7FD0xE996
	lsl.b d5
	roxl.b d2
	roxl.b d6
	roxl.b d3

	subq.l #1,d0
	bra mathlsl32
	
	
     ;11 r6.r4=r6.r4+r2.r0
mathadd32:

	move.l (VM_RamBaseAddr),a0
	clr.l d0
	move.b (VM_rR3,a0),d0
	lsl.l #8,d0
	move.b (VM_rR2,a0),d0
	lsl.l #8,d0
	move.b (VM_rR1,a0),d0
	lsl.l #8,d0
	move.b (VM_rR0,a0),d0
	
	clr.l d7
	move.b (VM_rR7,a0),d7
	lsl.l #8,d7
	move.b (VM_rR6,a0),d7
	lsl.l #8,d7
	move.b (VM_rR5,a0),d7
	lsl.l #8,d7
	move.b (VM_rR4,a0),d7
	
	add.l d0,d7
	
	move.b (VM_rR4,a0),d7
	lsr.l #8,d7
	move.b (VM_rR5,a0),d7
	lsr.l #8,d7
	move.b (VM_rR6,a0),d7
	lsr.l #8,d7
	move.b (VM_rR7,a0),d7

	move.l #$66660006,d7	
	rts

 ;12 r6.r4=r6.r4-r2.r0
mathsub32:

	move.l (VM_RamBaseAddr),a0
	clr.l d0
	move.b (VM_rR3,a0),d0
	lsl.l #8,d0
	move.b (VM_rR2,a0),d0
	lsl.l #8,d0
	move.b (VM_rR1,a0),d0
	lsl.l #8,d0
	move.b (VM_rR0,a0),d0
	
	clr.l d7
	move.b (VM_rR7,a0),d7
	lsl.l #8,d7
	move.b (VM_rR6,a0),d7
	lsl.l #8,d7
	move.b (VM_rR5,a0),d7
	lsl.l #8,d7
	move.b (VM_rR4,a0),d7
	
	sub.l d0,d7
	
	move.b d7,(VM_rR4,a0)
	lsr.l #8,d7
	move.b d7,(VM_rR5,a0)
	lsr.l #8,d7
	move.b d7,(VM_rR6,a0)
	lsr.l #8,d7
	move.b d7,(VM_rR7,a0)

	move.l #$66660006,d7	
	
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


mathmul32:   ;r6.r4=r6*r4

	move.l (VM_RamBaseAddr),a0
	
	clr.l d6
	move.b (VM_rR7,a0),d6
	lsl.l #8,d6
	move.b (VM_rR6,a0),d6
	
	clr.l d5
	move.b (VM_rR5,a0),d5
	lsl.l #8,d5
	move.b (VM_rR4,a0),d5
	
	mulu d5,d6
	
	move.b d6,(VM_rR4,a0)
	lsr.l #8,d6
	move.b d6,(VM_rR5,a0)
	lsr.l #8,d6
	move.b d6,(VM_rR6,a0)
	lsr.l #8,d6
	move.b d6,(VM_rR7,a0)

	move.l #$66660006,d7
	rts

  ;r6.r4=r6.r4/r2 (r2=remainder)
mathdiv32:
 
	rts

mathmul32byte:     ;r6.r4=r6*r0 byte

	move.l (VM_RamBaseAddr),a0

	clr.l d6
	move.b (VM_rR6,a0),d6
	lsr.l #8,d6
	move.b (VM_rR7,a0),d6
	
	clr.l d0
	move.b (VM_rR0,a0),d0
	
	mulu d0,d6		;de.hl=hl*a
	
	
	move.b d6,(VM_rR4,a0)
	lsr.l #8,d6
	move.b d6,(VM_rR5,a0)
	lsr.l #8,d6
	move.b d6,(VM_rR6,a0)
	lsr.l #8,d6
	move.b d6,(VM_rR7,a0)

	move.l #$66660006,d7	
	rts

 ;r6.r4=r6.r4/r0 byte (r0=remainder)
mathdiv32byte:

	move.l (VM_RamBaseAddr),a0
	
	clr.l d6
	move.b (VM_rR4,a0),d6
	lsr.l #8,d6
	move.b (VM_rR5,a0),d6
	lsr.l #8,d6
	move.b (VM_rR6,a0),d6
	lsr.l #8,d6
	move.b (VM_rR7,a0),d6

	clr.l d2
	move.b (VM_rR0,a0),d2
	
	divu d2,d6			;$RRRRQQQQ
	move.l d6,d2
	
	lsr.l #8,d2 	;Remainder
	lsr.l #8,d2 	;Remainder
	and.l #$0000FFFF,d6	;Quotient
	
	
	move.b d6,(VM_rR4,a0)
	lsr.l #8,d6
	move.b d6,(VM_rR5,a0)
	lsr.l #8,d6
	move.b d6,(VM_rR6,a0)
	lsr.l #8,d6
	move.b d6,(VM_rR7,a0)

	move.b d2,(VM_rR0,a0)
	
	move.l #$66660006,d7
	rts

Mul32_8_Sgn:				;This routine performs the operation DE.HL=HL*A (Signed)	
	
;r6.r4=r6*r4 (signed)
mathmul32_sgn:

	move.l (VM_RamBaseAddr),a0
	
	clr.l d6
	move.b (VM_rR7,a0),d6
	lsl.l #8,d6
	move.b (VM_rR6,a0),d6
	ext.l d6
	
	clr.l d5
	move.b (VM_rR5,a0),d5
	lsl.l #8,d5
	move.b (VM_rR4,a0),d5
	ext.l d5
	
	muls d5,d6
	
	move.b d6,(VM_rR4,a0)
	lsr.l #8,d6
	move.b d6,(VM_rR5,a0)
	lsr.l #8,d6
	move.b d6,(VM_rR6,a0)
	lsr.l #8,d6
	move.b d6,(VM_rR7,a0)

	move.l #$66660006,d7
	rts

;r6.r4=r6*r0 byte (signed)
mathmul32byte_sgn:

	move.l (VM_RamBaseAddr),a0
	
	clr.l d6
	move.b (VM_rR7,a0),d6
	lsl.l #8,d6
	move.b (VM_rR6,a0),d6
	ext.l d6
	
	clr.l d5
	move.b (VM_rR0,a0),d5
	ext.w d5
	ext.l d5
	
	muls d5,d6
	
	move.b d6,(VM_rR4,a0)
	lsr.l #8,d6
	move.b d6,(VM_rR5,a0)
	lsr.l #8,d6
	move.b d6,(VM_rR6,a0)
	lsr.l #8,d6
	move.b d6,(VM_rR7,a0)

	move.l #$66660006,d7
	rts


;r6.r4= -r6.r4
mathnegage32:

	move.l (VM_RamBaseAddr),a0
	
	clr.l d6
	move.b (VM_rR4,a0),d6
	lsr.l #8,d6
	move.b (VM_rR5,a0),d6
	lsr.l #8,d6
	move.b (VM_rR6,a0),d6
	lsr.l #8,d6
	move.b (VM_rR7,a0),d6
	
	neg.l d6
		
	move.b d6,(VM_rR4,a0)
	lsr.l #8,d6
	move.b d6,(VM_rR5,a0)
	lsr.l #8,d6
	move.b d6,(VM_rR6,a0)
	lsr.l #8,d6
	move.b d6,(VM_rR7,a0)

	move.l #$66660006,d7
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
