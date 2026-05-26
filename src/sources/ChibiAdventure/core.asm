screenwidth equ ramarea+2


WaitForFire:				;Pause for a fire press
	jsr waitforrelease		;Wait for fire to be released
WaitForFire2:
	jsr dorandom			;Re-seed the random generator
	jsr readjoystick		;Read from the joystick

	btst #4,d0				;Test Fire
	bne waitforfire2		;Not Preseed? Then repeat
	rts

WaitForRelease:				;Wait for the joystick to be released
	jsr readjoystick		;Get Joystick input
	cmp.b #255,d0			;Any keys pressed?
	bne waitforrelease		;Yes? then wait for release
	rts




joyaxis:		;A=Value to test C=Joypresses %---FRLDU
	move.b d0,d1			;Backup previous value in R1 (b)

	btst #0,d4				;Up or Left
	bne notupleft
	subq.l #1,d0
notupleft:

	btst #1,d4				;Down or Right
	bne notdownright
	addq.l #1,d0
notdownright:
	lsr #2,d4				;skip 2 direction bits
	rts
	
	
	
pause50:
	move.l #50,d0			;Wait for 50

pausea:						;Pause for D0 
	and.l #$FF,d0
pausea2:
	move.l #1000,d7			;Second delay loop because
pausea3:					; the 68000 is FAST!
	subq.w #1,d7
	bne pausea3
	
	subq.b #1,d0
	bne pausea2
	rts



RangeTest:	;ensure D0 is between D2 and D5 (>=D2 <D5)
	cmp.b d5,d0
	bcc setcarry	;higher or equal to D5
	cmp.b d2,d0		;c=lower than D2
	rts

setcarry:
	ori #%00000001,CCR
	rts
	
	
RangeLimit:				;reset D0=D1 if over range D2/D5
	jsr rangetest
	bcs lbl60376
	rts					;In range, leave unchanged.
lbl60376
	move.l d1,d0		;Our of range! Reset D0
	rts
	
	
ShowDecimal:	;Draw a 3 digit decimal number (non-BCD)
	moveM.l d0/d1/d3,-(sp)
		move.l #100,d3
		jsr divideabyh		;/100

		move.l #10,d3
		move.b d1,d0
		jsr divideabyh		;/10

		move.b d1,d0
		jsr printnumber		;/1
	moveM.l (sp)+,d0/d1/d3
	rts

	
DivideAbyH:
	and.l #$ff,d3
	and.l #$ff,d0

	divu d3,d0			;D0=D0/3 (remainder in top word)

	move.l d0,d1		;Remainder in $RRRR----
	lsr.l #8,d1
	lsr.l #8,d1			;Remainder in $----RRRR
	jmp printnumber

		
	
	
ClearRam:	
	move.l #ramarea,a0
	move.l #256-1,d0
ClearRamB:	
	clr.b (a0)+			;Clear 256 bytes of RamArea
	dbra d0,ClearRamB
	
	clr.l d0			;Clear main regs.
	clr.l d1
	clr.l d2
	clr.l d3
	clr.l d4
	clr.l d5
	clr.l d6
	
	jmp cls				;Clear screen

	
	
	ifnd ChibiSound
ChibiSound:
ChibiSoundBeep:
		rts
	endif
	
	
DoLdir:			;Copy D1 bytes from A3 to A2 (ascending)
	move.b (a3)+,(a2)+
	subq.w #1,d1		
	bne DoLdir
	rts

DoLddr:			;Copy D1 bytes from A3 to A2 (descending)
	move.b (a3),(a2)
	subq.w #1,a3
	subq.w #1,a2
	subq.w #1,d1
	bne DoLddr
	rts	

	
	
PrintSeqNC:
	move.l d4,d5	;restore ypos
	addq.l #1,d2	;inc xpos
	bra printseq

PrintSeqNL:
	move.l d1,d2		;restore xpos
	addq.l #1,d5		;inc ypos

PrintSeq:				;print seq hl at location de
	move.l d2,d1
	move.l d5,d4

PrintSeqB:
	move.b (a3)+,d0		;get a char
	beq doprintchar		;0=empty char

	cmp.b #32,d0
	bcs xposchange		;&01-&1f = new absolute xpos (use nl for xpos=0)

	cmp.b #$e0,d0
	bcc yposchange		;&e0-&f8 = new absolute ypos

	cmp.b #$a0,d0
	bcc sequenceh		;&a0-&bf = horizontal sequence of one char
doprintchar:
	jsr printchar		;&20-&9f = character
	bra printseqb

	
SequenceH:
	moveM.l d1/d4,-(sp)
		cmp.b #$c0,d0
		bcc sequencev		;&c0-&df = vertical sequence of one char
		and.l #$1f,d0
		addq.l #1,d0
		move.b d0,d1		;Count
		
		move.b (a3)+,d0		;get a char

sequenceh2:
		jsr printchar
		subq.b #1,d1
		bne sequenceh2

printseq_poprep:
	moveM.l (sp)+,d1/d4
	bra printseqb

	
SequenceV:
	and.l #$1f,d0
	addq.l #1,d0			;Count
	move.l d0,d1
	
	move.b (a3)+,d0			;get a char

sequencev2:
	moveM.l d2/d5,-(sp)
		jsr printchar
	moveM.l (sp)+,d2/d5
	
	addq.l #1,d5			;Down a line
	subq.b #1,d1
	bne sequencev2
	bra printseq_poprep

	
XposChange:
	move.b d0,d2
	bra printseq

YposChange:
	ifd PrintSeqXVar
		cmp.b #250,d0
		bne notPrintSeqXVar
			jmp PrintSeqXVar	;&FA	 = Show Variables 
NotPrintSeqXVar:				;  (Dec, Hex,Char,String,StringIndir)
	endif 
	
	cmp.b #251,d0
	beq printseqfill	;&fb	 = fill area (w,h,char,inc)

	cmp.b #252,d0				
	beq printseqnc		;&fc 	 = new column (vertical)

	cmp.b #253,d0
	beq printseqcrnl	;&fd     = new line (true)

	cmp.b #254,d0
	beq printseqnl		;&fe     = new line (horizontal)

	cmp.b #255,d0		;&ff     = end of list
	bne lbl22306		;yes? then return
	rts
lbl22306
	move.l d1,d2
	and.b #$1f,d0
	move.b d0,d5		;new ypos
	bra printseqb

	
PrintSeqCrNl:
	jsr newline		;zero x, move down a line
	bra printseq

	
PrintSeqFill:
	moveM.l d1/d4,-(sp)
		move.b (a3)+,d1		;Width
		move.b (a3)+,d4		;Height
		move.b (a3)+,d3		;Character
		move.b (a3)+,d6		;Char-INC
		jsr fillarea
			
		bra printseq_poprep


;d3=Char  d6=Char increment  d2,d5=X,Ypos  d1,d4=Wid,Hei
FillArea:
	moveM.l d2/d5,-(sp)
fillareab:
		moveM.l d1/d4/d2/d5,-(sp)
fillareax:
			move.b d3,d0
			jsr printchar
			add.b d6,d3			;Increment Char
	
			subq.b #1,d1
			bne fillareax		;Xloop
		moveM.l (sp)+,d1/d4/d2/d5
		addq.b #1,d5
		subq.b #1,d4
		bne fillareab			;Yloop 
	moveM.l (sp)+,d2/d5
	rts
	


randomseed equ ramarea	;2 bytes

DoRandom:				;Generate a psuedo random byte
	movem.l d1/d4,-(sp)
		addq.w #1,(randomseed)	;Update the 16 bitseed 
		
		move.b (randomseed),d1
		move.b (randomseed+1),d4
	
	
		eor.b d4,d0
		ror.b #1,d0
		eor.b d3,d0
		ror.b #1,d0
		eor.b d2,d0
		eor.b d1,d0		
		ror.b #1,d0
		eor.b d6,d0
		ror.b #1,d0
		eor.b d5,d0
		eor.b d4,d0
		ror.b #1,d0
		eor.b #%10011101,d0
		eor.b d4,d0
	movem.l (sp)+,d1/d4
	rts

	
;return D0 between D2 and D5 (>=D2 <D5)
RangedRandom:
	jsr dorandom		;Get a number
	jsr rangetest		;Is it in range?
	bcs lbl59467
	rts					;Value OK, so return
lbl59467
	bra rangedrandom	;Value NG, so repeat

