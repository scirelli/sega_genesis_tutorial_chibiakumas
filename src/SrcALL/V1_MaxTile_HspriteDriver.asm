;                                     drawtilemap:			;draw straight to vram
drawtilemaph:
;A1    = Pattern Source
;DE/A2 = Source Tilemap
;HL/A3 = Vram Dest 
;IXH=Width IXL=Height
;IYH=TilemapWidth

	;move.l #BackgroundTilemap2,a2
nextlinedh:
	
	
	
	move.b d4,d7	;width 

	move.l a3,-(sp)
	move.l a2,-(sp)
	
	ifd hiresy
			ifd buildcpc
				btst #5,a3		;&c000 /&e000
				bne dostriphalf
			endif
		endif

nexttileh:
		;exx

		ifd slowdowntest	;for debugging
			move.l #$1000,d0
	slowdownh:
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			subq.l #1,d0
			bne slowdownh
		endif
		move.b (a2),d0	;bc=tilemap data %upyxccnn	u=update p=program yx=flip cc=color/more nn nn=tile h
			lsr.b #1,d0	;get the 'needs update' bit
			
			
			;A4=IX
			;A2=Tilemap A1=TileOffset A3=Vram dest
			
			ifd doublebuffered
				bra drawtileh		;update even if not needed!
			else
				bcs drawtileh	;update if needed
			endif
emptytileh:
		addq.l #2,a2		;bc=tilemap data %upyxccnn %nnnnnnnn
	
tiledoneh:

		ifd buildGEN
			add.w #$0400,a3		;Across one tile
		endif
		ifd buildNEO
			add.w #$0400,a3		;Across one tile
		endif
		subq.b #1,d7
		bne nexttileh
tiledone2h:
	move.l (sp)+,a2		;tilemap source
	move.l (sp)+,a3		;screen pos
		
	ifd buildGEN
		add.w #$4,a3		;Down one line
	endif
	ifd buildNEO
		add.w #$4,a3		;Down one line
	endif
	
	add.l a6,a2	;update tilemap source (add width)

	subq.b #1,d5		;next v-line
	bne nextlinedh	;repeat for next line
	rts


