

;BC/A1  = Pattern Source
;DE/A2  = Source Tilemap
;HL/A3  = Vram Dest 
;IXH/D4 = Draw Width IXL/D5=Draw Height
;IYH/A6 = TilemapWidth

DrawTilemap:						;Draw straight to VRAM
	move.l d4,d7					;width 
NextLineD:
	moveM.l d7/a3/a2,-(sp)
		ifd buildAMI
			ifd drawtileShifted
				move.l a3,d4		;Offset in top 2 bits
				rol.l #3,d4
				and.l #%00000110,d4	;Bitshift in D4
			endif
		endif 
			ifd buildAST
			ifd drawtileShifted
				move.l a3,d4		;Offset in top 2 bits
				rol.l #3,d4
				and.l #%00000110,d4	;Bitshift in D4
			endif
		endif 
		; ifd hiresy
			; ifd buildcpc
				; btst #5,a3		;&c000 /&e000
				; bne dostriphalf	;Example for systems with two
			; endif					;Draw routines
		; endif
nexttile:
		
		
		ifd slowdowntest		;for debugging
			move.l #$4000,d0
slowdown:
			nop
			nop
			nop
			nop
			nop
			nop
			subq.l #1,d0
			bne slowdown
		endif
		
		move.b (a2),d0		;A2=tilemap data 
		lsr.b #1,d0			;get the 'needs update' bit
					
		ifd doublebuffered
			ifd doubleBuffered_onlychanged
				bcs drawtile	;update if needed
			else 
				bra drawtile	;update even if not needed!
			endif 
		else
			bcs drawtile	;update if needed
		endif
emptytile:
		addq.l #2,a2		;a2=tilemap data %NNNNXYPU %nnnnnnnn
TileDone:


;Platform specific commands to move across 8 pixels (one tile)

		ifd buildNEO
			ifd DefineHspriteTilemap
				add.l #64,a3	;Across one tile
			else
				add.l #32,a3	;Across one tile
			endif
		endif
		ifd buildGEN
			addq.l #2,a3		;Across one tile
		endif
		ifd buildX68
			add.l #16,a3		;Across one tile
		endif
		ifd buildAMI
			addq.l #1,a3		;Across one tile
		endif
		ifd buildAST
			addq.l #1,a3		;Across one tile
			move.l a3,d0
			btst #0,d0			;Need to jump to next 8 byte block?
			bne TileDoneH
			add.l #6,a3			;Yes!
TileDoneH:			
		endif
		ifd buildSQL
			addq.l #4,a3		;Across one tile
		endif
		subq.b #1,d7
		bne nexttile
tiledone2:
	moveM.l (sp)+,a2/a3/d7	;tilemap source / screen pos / width
	
	
;Platform specific commands to move down 8 pixels (one strip of tiles)
	
	ifd buildAMI
		add.l #160*8,a3			;Down one line
	endif
	ifd buildAST
		add.l #160*8,a3			;Down one line
	endif
	ifd buildGEN
		add.l #64*2,a3			;Down one line
	endif
	ifd buildNEO
		ifd DefineHspriteTilemap
			addQ.l #2,a3		;Down one line
		else
			addQ.l #1,a3		;Down one line
		endif
	endif
	ifd buildX68
		add.l #1024*8,a3		;Down one line
	endif
	ifd buildSQL
		add.l #128*8,a3			;Down one line
	endif
	add.l a6,a2					;Update tilemap source (add width)

	subq.b #1,d5				;Next v-line
	bne nextlined				;Repeat for next line
	rts


