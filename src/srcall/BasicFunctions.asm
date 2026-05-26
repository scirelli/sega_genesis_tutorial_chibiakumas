CLDIR0:						;Clear D1 bytes from A3
	clr.l d0
CLDIR:
	move.l a3,a2
	move.b d0,(a2)+
LDIR:						;Copy D1+1 bytes from A3 to A2
LDIRAgain:
	move.b (a3)+,(a2)+
	subq.l #1,d1
	bne LDIRAgain
	rts
