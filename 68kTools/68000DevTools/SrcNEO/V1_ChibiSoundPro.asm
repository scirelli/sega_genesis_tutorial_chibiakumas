;We have to send our byte in 2 parts because the NeoGeo Z80 uses commands 0-31 as system commands

chibisoundpro_set:					;NVVTTTTT	Noise Volume Tone 
	moveM.l d0-d5,-(sp)
	
		jsr ChibiSoundInit		;Reset Z80 Driver (Chibisound Pro command)
		
;Frequency		
		move.w d2,d0
		jsr ChibiSoundSendLow			;L1
		move.w d2,d0
		jsr ChibiSoundSendHigh			;L2
		
		move.w d2,d0
		lsr.w #8,d0
		jsr ChibiSoundSendLow			;H1
		move.w d2,d0
		lsr.w #8,d0
		jsr ChibiSoundSendHigh			;H2
		

;Channel / Noise
		move.w d6,d0
		jsr ChibiSoundSendLow			;H1
		move.w d6,d0
		jsr ChibiSoundSendHigh			;H2

;Volume
		move.w d3,d0
		jsr ChibiSoundSendLow			;L1
		move.w d3,d0
		jsr ChibiSoundSendHigh			;L2
		
		
		
		jsr ChibiSoundExecute	;Execute command
		
	moveM.l (sp)+,d0-d5
	rts
	

ChibiSoundInit:	
	move.b #%10010000,d0
	move.b	d0,$320000 		;Send a byte to the Z80
	
	clr.l d7				;First command!
	jmp ChibiSoundWait
	
	
ChibiSoundExecute:	
	move.b #%10110000,d0
	move.b	d0,$320000 		;Send a byte to the Z80
	jmp ChibiSoundWait		
	
	
	
ChibiSoundSendLow:
	and.b #%00001111,d0		;Send Low nibble
	or.b  #%10100000,d0		;10--DDDD	=DDDD is bottom nibble
	move.b	d0,$320000 		;Send a byte to the Z80
	jmp ChibiSoundWait
	
ChibiSoundSendHigh:	
	and.b #%11110000,d0		;Send High nibble
	ror.b #4,d0
	or.b  #%10100000,d0		;11--DDDD	=DDDD is top nibble
	move.b	d0,$320000 		;Send a byte to the Z80 
	jmp ChibiSoundWait

ChibiSoundWait:		
	
	move.b	$320000,d0 		;Get byte from Z80
	cmp.b d0,d7
	bne ChibiSoundWait		;Wait until procesed (Returns Command num)
	addq.l #1,d7			;Inc command num
	rts
	