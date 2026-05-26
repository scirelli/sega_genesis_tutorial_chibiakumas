
NewLine:
	clr.l d2			;Xpos =0
	addq.l #1,d5		;Ypos ++

	cmp.b #$17,d5		;Over bottom of the screen?
	bcc cls
	rts

Cls:
	moveM.l d1/d4/d3/d6,-(sp)
		clr.l d2		;Xpos
		clr.l d5		;Ypos
		
		move.b #$20,d3	;Char (Space)
		clr.b d6		;CharInc (0= all same character)
		
		move.b #$20,d1	;Width
		move.b #$18,d4	;Height
		jsr fillarea
	moveM.l (sp)+,d1/d4/d3/d6
	rts


slowdown:
	move.b	d0,$300001	;REG_DIPSW - Kick the watchdog
	jmp pausea
	

ReadJoystick:		;Returns: %dcbaRLDU

	move.b $300000,d0	;Joy1 - dcbaRLDU
	rts
		
		
PrintNumber:
	add.b #48,d0		;ascii 0
PrintChar:				;print char a with sprite routine
	cmp.b #0,d0
	beq printchar0

	move.l d6,-(sp)			;VRAM address = $7000 + (Xpos * 32) + Ypos
		clr.L d7
		Move.B d2,D7		;Xpos
		add.l #4,d7
		rol.L #5,D7			;X*32
		add.l #$7000,d7		;Fix Layer Tilemap base $7000
	
		clr.L d6
		move.b d5,D6		;Ypos
		add #2+2,d6			;NEO doesn't recommend using top 2 rows
		add.l D6,D7
	
		move.w d7,$3C0000 ;VRAM Address Select
	
	move.l (sp)+,d6
	
	clr.l d7
	move.b d0,d7			;Char num
	sub.b #32,d7			;no char below 32
	cmp.b #64,d7
	bcs notlowercase		;Lowercase?
	sub.b #32,d7			;convert to upper!
notlowercase:
	
	;	PTTT - P=Palette T=TileNum
	add.w #$1800,d7			;Tile Num (Palette 1 - Tile $800+)
	move.w d7,$3C0002		;VRAM Write (tile data)
printchar0:
	addq.l #1,d2
	rts

	
	
