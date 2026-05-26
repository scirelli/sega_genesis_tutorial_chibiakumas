
monitormemdumpheaderseq:	dc.b 250,3,250,3,250,3,250,3,':',253,255

monitormemdumpseq:
	dc.b 250,3,' ',250,3,' ',250,3,' ',250,3,' '   ;8 bytes as hex
	dc.b 250,3,' ',250,3,' ',250,3,' ',250,3,' '
	dc.b 250,9,-8 ;back 8 bytes
	dc.b 250,4,250,4,250,4,250,4;8 bytes as chars
	dc.b 250,4,250,4,250,4,250,4
	dc.b 253,255 ;nl and return
	even
	
	
memdumpadv:
	move.l a3,-(sp)
		move.l sp,(printseqxvarram)		;Stack pointer points to hl
		
		move.l #monitormemdumpheaderseq,a3
		jsr printseqcp
	move.l (sp)+,a3

memdumpheaderlessadv:
	move.l a3,(printseqxvarram) ;ram to dump is vars
memdumpadvagain:
	move.l #monitormemdumpseq,a3

	jsr printseqcp
	subq.b #1,d1
	bne memdumpadvagain   ;repueat b times
	rts

monitorreglist:
	dc.b 'F:',250,3,' A:',250,3,' SP:',250,5,253
	dc.b 'BC:',250,5,' DE:',250,5,' HL:',250,5,253
	dc.b 'IX:',250,5,' IY:',250,5
	dc.b ' PC:',250,5
	dc.b 253,255	;NL and return
	even
	
monitoradv:
	rts
