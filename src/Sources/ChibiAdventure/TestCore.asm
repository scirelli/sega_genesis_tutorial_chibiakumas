	
	include "header.asm"
	
	move.l #Message,a3
	jsr PrintSeq

	clr.l d0
	jsr PauseA


	clr.l d3
	clr.l d6
infloop:
	clr.l d2
	move.l #4,d5

		
	jsr ReadJoystick
	jsr ShowDecimal

	move.l #4,a2

	jsr DoRandom
	jsr ShowDecimal


	move.l #50,d0
	jsr PauseA

	jmp infloop



Message:	dc.b 'Hello',$C1,0,'World',$A3,'!',254,255	;String to show

	include "core.asm"
	include "footer.asm"
	