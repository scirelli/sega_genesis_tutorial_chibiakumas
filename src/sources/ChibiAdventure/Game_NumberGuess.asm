
answer equ ramarea+16
guess equ ramarea+17	;2 bytes (combined into 1 byte value)
tries equ ramarea+19

	include "header.asm"

anothergo:
	move.l #strstart,a3		;show title message
	jsr printseq

	jsr waitforfire

	jsr dorandom
	move.b d0,(answer)	;decide what the answer is 

anotherguess:

	jsr waitforrelease		;wait for joystick release
	
	move.l #strguess,a3
	
	jsr printseq			;show the guess message
guessloop:
	moveM.l d2/d5,-(sp)

		jsr readjoystick		;get keypresses into a
		move.b d0,d4

		move.b (guess+1),d0
		jsr joyaxis		;up/down (+-16)

		move.b d0,d3
		move.b d0,(guess+1)

		move.b (guess),d0	;left/right (+-1)
		jsr joyaxis
		move.b d0,d6
		move.b d0,(guess)

		move.b d6,d0	;lr=+-16
		asl.b #4,d0

		add.b d3,d0		;ud=+-1
		move.b d0,d1	;combine h and l ionto b
	moveM.l (sp)+,d2/d5
	moveM.l d2/d5,-(sp)
		jsr showdecimal
	moveM.l (sp)+,d2/d5
	jsr pause50

	btst #0,d4
	beq testguess	;test fire

	jmp guessloop

testguess:
	
	addq.b #1,(tries);another try used 

	cmp.b (answer),d1
	beq testcorrect	;is answer correct?

	move.l #strlow,a3
	bcs answerlow	;is answer too low

	move.l #strhigh,a3

answerlow:
	jsr printseq
	
	bra anotherguess


testcorrect:
	jsr newline

	move.l #strcorrect,a3
	jsr printseq
	move.b (tries),d0
	jsr showdecimal

	jsr printseq

	jsr waitforfire

	jsr cls

	jmp anothergo

strStart:	dc.b 'Guess My Number!',254
		dc.b 'Press Fire to start',254,255	;String to show
strGuess:	dc.b 'Your Guess >',255	;String to show
strCorrect: 	dc.b 'Correct! You took ',255,' Tries!',255
strLow:		dc.b 253,'Too Low!',254,255
strHigh:	dc.b 253,'Too High!',254,255
	
	even

	include "core.asm"
	include "footer.asm"
 