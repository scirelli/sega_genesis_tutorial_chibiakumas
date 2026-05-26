
;A1 A2 A3 free for our use
;D0 D1 D2

;A4=IX
;A2=Tilemap A1=TileOffset A3=Vram dest
			
drawtile:			;Select Vram Destination
	move.l a3,d6
	and.w #%1100000000000000,d6	;Shift the top two bits to the far right 
	rol.w #2,d6
		
	move.l a3,d1
	and.l #%0011111111111111,d1	;Shift all the other bits left two bytes
	rol.l #8,d1
	rol.l #8,d1
		
	or.l d6,d1					
	or.l #$40000000,d1	;Set the second bit from the top to 1
							;#%01000000 00000000 00000000 00000000
	move.l d1,(VDP_ctrl) ;$C00004	VDP control, word or longword writes only
		
	
	btst #0,d0
	ifnd tiletest_basiconly		;for minimal testing
		bne drawtileadvanced
	endif
	
	asl.b #1,d0			;%NNBBXYP0 ... Update flag cleared (bit 0)
	move.b d0,(a2)+
	
drawtilebasiconly:
	and.b #%11110000,d0	;nnnn----

	clr.l D2
	move.b d0,D2
	
	clr.l d0
	move.b (a2)+,d0
	
	asl.l #8,d0
	or.w d0,D2			;NNNNNNNN nnnn----
	lsr.w #4,D2 		;----NNNN NNNNnnnn
	
	add.l a1,D2			;Add Tile Base
	
	;LPPVHTTT TTTTTTTT	   T=Tile number  H=Hflip  V=vflip  P=palette number
						  ;L=Layer (in front of /behind sprites)
	move.w D2,(VDP_data) 
	jmp tiledone


drawtileadvanced:	
	and.b #%00000110,d0		;%-NNBBXYP
	beq drawtilecustom		;X,Y flip 0 = special prog
	
	move.b (a2),d0
	and.b #%11111110,d0		;Clear Update Flag
	move.b d0,(a2)+
	

	ifd tiletest_noflip	;for minimal testing
		bra drawtilebasiconly
	endif

	clr.l D2
	and.b #%11110000,d0		;nnnn---
	move.b d0,D2
	
	clr.l d0
	move.b (a2),d0			;%NNNNNNNN
	subq.l #1,a2
	
	asl.l #8,d0
	or.w d0,D2				;NNNNNNNN nnnn----
	
	lsr.w #4,D2
	add.l a1,D2				;Add Tile Base
	
	move.b (a2),d0
	addq.l #2,a2

	
	btst #2,d0
	bne drawtileyflip

drawtilexflip:
	bset #11,D2				;Hflip
	move.w D2,(VDP_data) 	;LPPVHTTT TTTTTTTT
	jmp tiledone

drawtilexyflip:
	bset #11,D2				;Hflip
	bset #12,D2				;Vflip
	move.w D2,(VDP_data) 	;LPPVHTTT TTTTTTTT
	jmp tiledone

drawtileyflip:
	btst #3,d0				
	bne drawtilexyflip
	
	bset #12,D2				;Vflip
	move.w D2,(VDP_data) 	;LPPVHTTT TTTTTTTT
	jmp tiledone

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

drawtileempty:
	addq.l #1,a2

	move.b (a2)+,d0
		
	cmp.b #255,d0			;255=empty <255=tilenum
	bne drawtiletransp
	jmp tiledone
;;;;;;;;;;;;;;;;;;transparent

drawtiletransp:
	move.b d0,d2
	add.l a1,D2				;Add Tile Base
	move.w d2,(VDP_data)	;Draw tile
	jmp tiledone
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

drawtilecustom:
	move.b (a2),d0			;%NNcc----
	and.b #%11111110,d0
	move.b d0,(a2)

	lsl.l #2,d0
	and.l #%0000001100000000,d0	;%NN --------
	move.l d0,D2

	move.b (a2),d0
	and.b #%11111110,d0
	move.b d0,(a2)
	and.b #%00110000,d0		;cmd bits
	beq drawtilefill

	cmp.b #%00110000,d0
	beq drawtileempty

	
drawtiledouble:
	addq.l #1,a2
	move.b (a2)+,D2	;------NN nnnnnnnn - tile number
	
	add.l a1,D2				;Add Tile Base
	add.l #patterndoubleheight,D2
	
	move.w D2,(VDP_data) 	;LPPVHTTT TTTTTTTT
	jmp tiledone

	
drawtilefill:
	addq.l #1,a2
	move.b (a2)+,D2	;------NN nnnnnnnn - tile number
	
	add.l #patternFill,D2
	
	move.w D2,(VDP_data) 	;LPPVHTTT TTTTTTTT
	jmp tiledone

	
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
		

;Tile Addr: VRAM Addr = $C000 + (Ypos * 64* 2) + (Xpos *2)

;d1=x d4=y (in pairs of pixels)
;returns screen address in A3

GetScreenPos: 
	and.l #%11111100,d1		;Round to tilea
	and.l #%11111100,d4
	
	move.l #ScreenBase,a3	;Get screen pointer into a6
	
	asr.l #1,d1				;Xpos in tiles *2
	add.l d1,a3
	
	asl.l #5,d4				;Ypos in tiles *64
	add.l d4,a3
	rts
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	


DefineTiles:			;Copy D1 bytes of data from A0 to VDP memory D2 
						;Regular
	movem.l a0/d1,-(sp)
		jsr prepareVram		;Calculate the memory location we want to write
DefineTilesAgain:			; the tile pattern definitions to
		move.l (a0)+,d0				
		move.l d0,(VDP_data)	;$C00000	Send the tile data to the VDP
		dbra d1,DefineTilesAgain
	movem.l (sp)+,a0/d1
	rts


DefineTilesDouble:		;Copy D1 bytes of data from A0 to VDP memory D2 
						;Double each line
	jsr prepareVram			;Calculate the memory location we want to write
DefineTilesDoubleAgain:		; the tile pattern definitions to
	move.l (a0)+,d0
	;Line 1
	move.l d0,(VDP_data)	;$C00000	Send the tile data to the VDP
	;Line 2
	move.l d0,(VDP_data)	;$C00000	Send the tile data to the VDP
	dbra d1,DefineTilesDoubleAgain
	rts
	

DefineTilesFills:		;Copy D1 bytes of data from A0 to VDP memory D2 
						;2 bytes per tile						
	jsr prepareVram			;Calculate the memory location we want to write
DefineFillsAgain:			; the tile pattern definitions to
	clr.l d0
	
	move.b (a0),d0			;Fill the word  Line 1
	lsl.l #8,d0
	move.b (a0)+,d0
	
	clr.l d2
	move.b (a0),d2			;Fill the word Line 2
	lsl.l #8,d2
	move.b (a0)+,d2
	
	move.w #3,d3			;4x 2 lines
DefineFillsLines:
	;Line 1
	move.w d0,(VDP_data)	;$C00000	Send the tile data to the VDP
	move.w d0,(VDP_data)	;$C00000	Send the tile data to the VDP
	;Line2
	move.w d2,(VDP_data)	;$C00000	Send the tile data to the VDP
	move.w d2,(VDP_data)	;$C00000	Send the tile data to the VDP
	dbra d3,DefineFillsLines
	
	dbra d1,DefineFillsAgain
	rts
	
		
	
	
	
	