
;A1 A2 A3
;D0 D1 D2

;A4=IX
;A2=Tilemap A1=TileOffset A3=Vram dest
			
drawtileh:
	btst #0,d0

	ifnd tiletest_basiconly		;for minimal testing
		bne drawtileadvancedh
	endif
	
	asl.b #1,d0				;%NNBBXYP0 ... Update flag cleared (bit 0)
	move.b d0,(a2)+
	

drawtilebasiconlyh:
	and.b #%11110000,d0		;NNNN----
	clr.l D2	
	move.b d0,D2
	
	clr.l d0
	move.b (a2)+,d0			;NNNNNNNN
		
	asl.l #8,d0
	or.w d0,D2				;NNNNNNNN nnnn----
	lsr.w #4,D2 			;----NNNN NNNNnnnn
	
	add.l a1,D2				;Add Tile Base
	
	
drawtilebasicAllH:
	jsr GetHSprite			;Get Sprite Vram Addr
		
	move.w a3,d0			;XYPos $----XXYY
	and.l #$FF,d0			;Get Ypos
	asl.w #1,d0				;Ypos in pixels
	add.w #128+(2*8),d0
	move.w d0,(VDP_data)	; ------VV VVVVVVVV - Vpos
	
	clr.l d0
	move.b (HSpriteNum),d0	;Next Sprite Link
	addq.b #1,d0
	move.w d0,(VDP_data)	; ----WWHH -LLLLLLL - Width, Height,
							; 					  Link (to next sprite)
	
	move.w d2,(VDP_data)	; PCCVHNNN NNNNNNNN - Priority, Color palette
							;					Vflip, Hflip, tile Number
	
	move.w a3,d0			;XY Pos;$----XXYY
	and.w #$FF00,d0			;Xpos
	lsr.w #7,d0				;Xpos in pixels
	add.w #128+(4*8),d0		
	move.w d0,(VDP_data)	; -------H HHHHHHHH - Hpos
	jmp tiledoneh


drawtileadvancedh:
	and.b #%00000110,d0		;%-NNBBXYP
	beq drawtilecustomh		;X,Y flip 0 = special prog
	
	move.b (a2),d0
	and.b #%11111110,d0
	move.b d0,(a2)+
	
	ifd tiletest_noflip	;for minimal testing
		bra drawtilebasiconlyh
	endif

	clr.l D2
	and.b #%11110000,d0		;nnnn----
	move.b d0,D2
	
	clr.l d0
	move.b (a2),d0			;%NNNNNNNN
	subq.l #1,a2
	
	asl.l #8,d0
	or.w d0,D2				;NNNNNNNN nnnn----
	
	lsr.w #4,D2
	add.l a1,D2				;Add Tile Base
		
	move.b (a2),d0			;%NNBBXYPU
	addq.l #2,a2
	btst #2,d0
	bne drawtileyfliph
	
drawtilexfliph:
	bset #11,D2					;PCCVHNNN NNNNNNNN
	jmp drawtilebasicAllH		;D2=Tilenum

drawtilexyfliph:
	bset #11,D2					;PCCVHNNN NNNNNNNN
	bset #12,D2
	jmp drawtilebasicAllH		;D2=Tilenum

drawtileyfliph:
	btst #3,d0					;PCCVHNNN NNNNNNNN
	bne drawtilexyfliph
	bset #12,D2
	jmp drawtilebasicAllH		;D2=Tilenum

	
	
drawtileemptyh:
	addq.l #1,a2
	move.b (a2)+,d0	;255=empty <255=tilenum

	cmp.b #255,d0
	bne drawtiletransph
	jmp tiledoneh

drawtiletransph:	;;;;;;;;;;;;;;;;;;transparent
	move.b d0,d2				;All sprites transparent anyway!
	add.l a1,D2					;Add Tile Base
	jmp drawtilebasicAllH		;D2=Tilenum


drawtilecustomh:
	move.b (a2),d0				;%NNcc----
	and.b #%11111110,d0			;Clear update flag
	move.b d0,(a2)

	lsl.l #2,d0
	and.l #%0000001100000000,d0	;%NN --------
	move.l d0,D2

	move.b (a2),d0
	and.b #%11111110,d0
	move.b d0,(a2)
	and.b #%00110000,d0			;cmd bits
	beq drawtilefillh

	cmp.b #%00110000,d0
	beq drawtileemptyh

	
drawtiledoubleh:
	addq.l #1,a2
	move.b (a2)+,D2	;------NN nnnnnnnn - tile number
			
	add.l a1,D2					;Add Tile Base
	add.l #patterndoubleheight,D2
	jmp drawtilebasicAllH		;D2=Tilenum

drawtilefillh:
	addq.l #1,a2
	move.b (a2)+,D2	;------NN nnnnnnnn - tile number
	
	add.l #patternFill,D2
	jmp drawtilebasicAllH		;D2=Tilenum

		
		
clearunusedhsprites:	
	clr.l d0
	move.b (HSpriteNum),d0
	cmp.b #-1,d0			;80 sprites total (0-79)
	beq NoHSprites	
	lsl.l #3,d0				;8 bytes per Sprite
	add.l #$D802,d0			;Base Sprite Address
		
		
	move.l d0,d1
	and.w #%1100000000000000,d0	;Shift the top two bits to the far right 
	rol.w #2,d0
	
	and.l #%0011111111111111,d1	;shift all the other bits left two bytes
	rol.l #8,d1		
	rol.l #8,d1
	
	or.l d0,d1					
	or.l #$40000000,d1			;Set the second bit from the top to 1
								;#%01000000 00000000 00000000 00000000
	move.l d1,(VDP_ctrl)
	
	
;Loop back to start of sprites (Link back t 0)
	;clr.w (VDP_data)	; ------VV VVVVVVVV - Vpos
	clr.w (VDP_data)	; ----WWHH -LLLLLLL - Width, Height, Link 
													;(to next sprite)
	;clr.w (VDP_data)	; PCCVHNNN NNNNNNNN - Priority, Color palette 
												  ;Vflip, Hflip, tile Number
	;clr.w (VDP_data)	; -------H HHHHHHHH - Hpos
	
	move.b #-1,(HSpriteNum)
NoHSprites:
	rts
	
	
	
	
GetHSprite:
		clr.l d0				;Hardware Spr Num
		move.b (HSpriteNum),d0
		addq.b #1,d0
		cmp.b #80,d0			;80 sprites total (0-79)
		blt GetHSpriteOver		;< last sprite
		subq.b #1,d0
GetHSpriteOver:	
		move.b d0,(HSpriteNum)	;Move to next Hsprite
		lsl.l #3,d0				;8 bytes per Sprite
		add.l #$D800,d0			;Base Sprite Address
	

prepareVramd0:		;To select a memory location D2 we need to calculate 
					;the command byte... depending on the memory location
	move.l d0,d1
	and.w #%1100000000000000,d0	;Shift the top two bits to the far right 
	rol.w #2,d0
	
	and.l #%0011111111111111,d1	;shift all the other bits left two bytes
	rol.l #8,d1		
	rol.l #8,d1
	
	or.l d0,d1					
	or.l #$40000000,d1			;Set the second bit from the top to 1
								;#%01000000 00000000 00000000 00000000
	move.l d1,(VDP_ctrl)
	rts
	
	

getscreenposh: 			;A3=XYpos in Hsprite format
	clr.l d0
	move.b d1,d0		
	lsl.l #8,d0			;Xpos<<8
	move.b d4,d0		;+Ypos
	move.l d0,a3		;$----XXYY
	rts
	
	
	
	