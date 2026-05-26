FileZero:


;Note Assembled program must not exceed $30000

ramarea equ $2FF00				;Space for game/program vars
								;First 16 bytes reserved for core.


;We can't be sure what address the OS will load us to
;We transfer our program to a fixed run address, and disable the OS!
								
SqlProgbase equ $28000			;The address we relocate to

	org SqlProgbase
	
QlProg_Start:
	
	Trap #0						;Set Supervisor mode
	ori #0700,sr				;Disable interrupts

	lea QlProg_Start,a1		;Start of program
	move.l #SqlProgbase,a0		;Destination address
	move.l #(QlProg_End-QlProg_Start)/4,d0	;Length in words
QlProg_CopyAgain:	
	move.l (a1)+,(a0)+
	dbra d0,QlProg_CopyAgain
	
	;Calculate the new run address, and execute it
	jmp (SqlProgbase+(QlProg_Run-QlProg_Start))
		
QlProg_Run:	


	move.l #$2FE00,sp			;Set up stack pointer
		
	move.b #%00001000,$18063	;Set 8 color mode
		

	move.l #$00020000,a0	
	move.l #((128*256)/4)-1,d0
ClearVramAgain:	
	clr.l (a0)+					;Clear whole VRAM area
	dbra d0,ClearVramAgain
		
	jsr ClearRam				;Clear the ramarea
	
	
	
