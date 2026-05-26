;                                     mul8zeroh_sgn:
mul8zeroh_sgn:
	btst #7,d0
	beq mul8zeroh
	
	neg.b d0
	jsr mul8zeroh

neghl:
	neg.l d3
	
	neg.l d6		;Equiv of Z80 H
	rts

mul8zeroh:
	and.l #$000000FF,d6

	
Mul8:     ; this routine performs the operation HL=HL*A
	mulu.w d0,d3
	rts
	
	
DivInfinite:
	move.l #$FFFF,d6
	rts
Div8:	;HL=Source	A=Divider (HL=HL/A A=Remainder)
Div16:
	cmp.b #0,d0
	beq DivInfinite
	divu.w d0,d6
	and.l #$0000FFFF,d6
	
	move.l d6,d3	;Equiv of Z80 H
	lsr #8,d3
    rts
	

Fraction32:
	pushaf
		move.l #16,d0	;ld a,16
		jsr Div8
	popaf
	bra Mul8
