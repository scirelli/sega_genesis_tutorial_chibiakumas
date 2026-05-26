
rkFlags equ VM_rFU

rkFlags_Q equ %10000000
rkFlags_M equ %01000000
rkFlags_D equ %00100000


mxMaxTileInit equ 0				;NoParams (sets up LUTs
mxMaxTileRedraw equ 1			;NoParams
mxMaxTileFillArea equ 2			;B,C=X,Y pos HL=Tile to fill with  D,E=Wid,Hei
mxMaxTileDrawArea equ 3			;B,C=X,Y pos HL=SourceTilemap (2 byte per tile)  D,E=Wid,Hei 
mxMaxTilePrint equ 4			;HL=source tilemap BC=xy pos de=offset (255 terminated string - 1 byte per tile DE=Offset)
mxSetPalette equ 5				;HL=Platform specific palette
mxSetScroll equ 6				;HL=TileMap Base Addr (if A=255 else unchanged) DE = Xoffset,Yoffset (only bottom 4 bits used)
mxMaxTilePrintArea equ 7
mxShiftTilemap equ 8
mxShiftTilemapLU equ 9
mxTileBClsr2 equ 10
mxTileBClsr3 equ 11
mxTileBClsr4 equ 12
mxTileBClsr5 equ 13
mxTileBClsr6 equ 14
mxTileBClsr7 equ 15
mxGetTileByteFromHL equ 16
vecMaxTile:
	dc.l InitMaxTile				;0
	dc.l MaxTileRedraw			;1
	dc.l MaxTileFillArea			;2
	dc.l MaxTileDrawArea			;3
	dc.l MaxTilePrint				;4
	dc.l SetPalette				;5
	dc.l 0;setscroll				;6
	dc.l MaxTilePrintArea			;7
	dc.l ShiftTilemap ;8 C=Ypos B=Xpos... Returns HL address
	dc.l ShiftTilemapLU ;9 C=YposLU B=XposLU... Returns HL address
	dc.l MaxTileBClsr2	;10 BC>>2
	dc.l MaxTileBClsr3	;11 BC>>3
	dc.l MaxTileBClsr4	;12 BC>>4
	dc.l MaxTileBClsr5	;13 BC>>5
	dc.l MaxTileBClsr6	;14 BC>>6
	dc.l MaxTileBClsr7	;15 BC>>7
	dc.l GetTileByteFromHL ;16
	
	
rkMaxTileLast equ 17


	
syscallMaxTile equ 5

MaxTileCall:
	move.l #vecMaxTile,a6
	jmp ChibiVM_VectorCall

	
    ;IX = A5
	;IY = A6
		
	
	
	
;                                     

;                                     gettilebytefromhl:
gettilebytefromhl:
	pushbc
	
	
		move.b (0,a3),d4
		move.b (1,a3),d1
		
	; move.l (backgroundtilemapbase),a0
	; move.b (0,a0),d0
	; move.b (1,a0),d1
	; jsr monitor 
	; jmp $
		
		jsr maxtilebclsr4
		clr.l d0
		move.b d4,d0
	popbc
	rts
;                                         

;                                         

;                                     maxtilebclsr7:
maxtilebclsr7:
	lsr.b #1,d1
	roxr.b #1,d4
maxtilebclsr6:
	lsr.b #1,d1
	roxr.b #1,d4
maxtilebclsr5:
	lsr.b #1,d1
	roxr.b #1,d4
maxtilebclsr4:
	lsr.b #1,d1
	roxr.b #1,d4
maxtilebclsr3:
	lsr.b #1,d1
	roxr.b #1,d4
maxtilebclsr2:
	lsr.b #1,d1
	roxr.b #1,d4
	lsr.b #1,d1
	roxr.b #1,d4
	rts

	
;this version is for printing 'strings' of characters to the screen

;hl=source tilemap bc=xy pos de=offset
maxtileprint:	
	move.l a2,-(sp)	;push de
		jsr addressremapviatablehl
		pushhl
		jsr shifttilemap   ;c=ypos b=xpos... returns hl address
		popde
	move.l (sp)+,a6 ;popiy
maxtileprinty:
	pushhl

maxtileprintx:
	clr.l d1
	move.b (a2)+,d1
	cmp.b #255,d1    ;255=line end
	beq maxtileprintxdone
		lsl.l #4,d1
		add.l a6,d1
		
		move.b d1,(a3)+
		lsr.l #8,d1
		move.b d1,(a3)+
		
	jmp maxtileprintx
maxtileprintxdone:
	pophl
	add.l #backgroundtilemapwidthv*2,a3

	move.b (a2),d0
	cmp.b #255,d0        ;255,255=sequence end
	bne maxtileprinty
	rts


;this version is for copying all/part of a 1byte source tilemap

;hl=source tilemap bc=xy pos de=offset
maxtileprintarea:

;offset / sourcetilemapskip
	movem.l d2/d5,-(sp)		;push de
		jsr addressremapviatablehl
		pushhl
			jsr shifttilemap      ;c=ypos b=xpos... returns hl address
			popde
	movem.l d3/d6,-(sp)	;popiy
;                                         ld ix,(vm_rambase+16)
	move.l (VM_RamBaseAddr),a0
	move.b (16,a0),d6
	move.b (16+1,a0),d3
;                                     maxtileprintya:
maxtileprintya:
	movem.l d3/d6,-(sp)	
		pushde
		pushhl
maxtileprintxa:
			clr.l d1
			move.b (a2)+,d1
			lsl.l #4,d1
			add.l a6,d1
			
			
			
			move.b d1,(a3)+
			lsr.l #8,d1
			move.b d1,(a3)+
				
			subq.b #1,d3 ;dec ixh
			bne maxtileprintxa

maxtileprintxdonea:
		pophl
		popde
		pushbc
			add.l #backgroundtilemapwidthv*2,a2
			clr.l d1
			move.l (VM_RamBaseAddr),a0
			move.b (18+1,a0),d1
			lsl.l #8,d1
			move.b (18,a0),d1
			add.l d1,a2
		popbc
	movem.l (sp)+,d3/d6
	subq.b #1,d6 ; dec ixl
	bne maxtileprintya
	rts

  ;b,c=x,y pos hl=sourcetilema  d,e=wid,hei
maxtiledrawarea:
	
	
	;jmp $
	movem.l d2/d5,-(sp)			;pushde
		jsr addressremapviatablehl

		pushhl
			
			jsr shifttilemap      ;c=ypos b=xpos... returns hl address

			
			exg a3,a2 ;ex de,hl
			
		pophl
	movem.l (sp)+,d3/d6 ;popix
	
maxtiledrawareay:
	clr.l d1
	move.b d3,d1
	lsl.l #1,d1	    ;2 bytes per tile
	
	
	
	pushhl
		pushde
			jsr doldir 
		popde
		add.l #backgroundtilemapwidthv*2,a2
	pophl
	
	move.l (VM_RamBaseAddr),a0
	clr.l d1
	move.b (16+1,a0),d1    ;space between lines
	lsl.l #8,d1
	move.b (16,a0),d1
	
	
	;jsr monitor
	;jmp $
	
	add.l d1,a3
    subq.b #1,d6 ;dec ixl
	bne maxtiledrawareay
	
	
	
	
	rts

	
	
;b,c=x,y pos hl=tile to fill with  d,e=wid,hei
MaxTileFillArea:


	movem.l d2/d5,-(sp)			;pushde
	pushde
	pushhl
		jsr shifttilemap        ;c=ypos b=xpos... returns hl address
	popde
	movem.l (sp)+,d3/d6 ;popix

	
	
	
maxtilefillareay:
	move.b d3,d1
	pushhl
maxtilefillareax:
		move.b d5,(a3)+
		move.b d2,(a3)+
		subq.b #1,d1
		bne maxtilefillareax
	pophl

	add.l #backgroundtilemapwidthv*2,a3

    subq.b #1,d6 ;dec ixl
	bne maxtilefillareay
	rts

maxtileredraw:
	move.l #patterndata,a3
	move.l (backgroundtilemapbase),a2
	move.l #cacheaddr1,a1
	
    ifnd doublebuffered
		jsr cache_tilemapcls   ;draw the tilemap

		;move.l #vm_rambase,a3  ;address tzo show
		;move.l #32,d4   ;bytes to show
		;jsr monitor_memdumpdirect    ;show memory to screen

		move.l #cachetable,a5
		jmp fastdrawcaches    ;draw the caches in order
    else
		jmp cache_tilemapcls    ;draw the tilemap  ;hl=pattern data / de=tilemap
	endif
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ifnd cache_tilemapcls
	
	
;A3=pattern data / A2=tilemap
Cache_TilemapCLS:
	ifd BuildNEO
		ifd hspritenum
			clr.w (hspritenum)		;Hardware Sprite Count
		endif
	endif

	move.l a3,a1	;pattern data

	ifd BuildAST
		move.l (screenbase),a3	;vram destination (A6)
		add.l #4*4,a3
	else
		move.l #screenbase,a3		;&vram base (c000)
	endif
	
	move.l #backgroundtilemapwidthv*2,a6 	;tilemap width (bytes)
	move.l #vscreenwid/4,d4				 	;draw width (tiles)
	move.l #vscreenhei/4,d5					;draw height (tiles)

;A2=tilemap  A1=pattern data  D4/D5=wh  A6=tilemap width  A3=vram dest
	ifd allowhalftilescroll
		ifd hiresy
			move.b (backgroundtilemapscrolly),d0
			ifd allowquartertilescroll
				not.b d0
				and.b #%00000011,d0		;%????TTHQ
				beq cls_nohalfy
				subq.b #1,d5
				and.b #%00000010,d0		;%????TTHQ
				beq cls_nohalfy
			else
				and.b #%00000010,d0		;%????TTHQ
				bne cls_nohalfy
				subq.b #1,d5
			endif
			ifd buildx68
				add.l #1024*4,a3
			endif
			ifd buildAMI
				add.l #160*4,a3
			endif
			ifd buildAST
				add.l #160*4,a3
			endif
			ifd buildSQL
				add.l #128*4,a3
			endif
		endif
cls_nohalfy:
		move.b (backgroundtilemapscrollx),d0

		ifd allowquartertilescroll
			not.b d0
			and.b #%00000011,d0		;%????TTHQ
			beq cls_nohalfx
			subq.b #1,d4
			and.b #%00000010,d0		;%????TTHQ
			beq cls_nohalfx
		else
			and.b #%00000010,d0		;%????TTHQ
			bne cls_nohalfx
			subq.b #1,d4
		endif
		ifd buildx68
			addq.l #8,a3
		endif
		ifd buildSQL
			addq.l #2,a3
		endif
		ifd buildAMI
			ifd drawtileShifted
				add.l #$80000000,a3
			endif 
		endif
		ifd buildAST
			ifd drawtileShifted
				add.l #$80000000,a3
			endif 
		endif
		
cls_nohalfx:
	endif
	ifd allowquartertilescroll
		ifd hiresy
			move.b (backgroundtilemapscrolly),d0
			and.b #%00000001,d0		;%????tthq
			bne cls_noquartery
			ifd buildzxn
				addq.l #2,d3
			endif
		ifd buildx68
			add.l #2*1024,a3
		endif
		ifd buildSQL
			add.l #128*2,a3
		endif
		ifd buildAMI
			add.l #160*2,a3
		endif
		ifd buildAST
			add.l #160*2,a3
		endif
cls_noquartery:
		endif

		move.b (backgroundtilemapscrollx),d0
		and.b #%00000001,d0		;%????tthq
		bne cls_noquarterx
		ifd buildx68
			addq.l #4,a3
		endif
		
		ifd buildsam
			addq.l #1,d6
		endif
		ifd buildAMI
			ifd drawtileShifted
				add.l #$40000000,a3
			endif 
		endif
		ifd buildAST
			ifd drawtileShifted
				add.l #$40000000,a3
			endif 
		endif
cls_noquarterx:

	ifd buildAMI
		ifd drawtileShifted
			move.l a3,d0
			eor.l #$C0000000,d0
			move.l d0,a3
		endif 
	endif
	ifd buildAST
		ifd drawtileShifted
			move.l a3,d0
			eor.l #$C0000000,d0
			move.l d0,a3
		endif 
	endif
	endif
	jmp drawtilemap 
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;c=ypos b=xpos... returns hl address
shifttilemaplu:
	pushde	
		sub.b #vscreenminx-3,d1
		lsr.b #2,d1   ;lu to tiles
	                                          

		sub.b #vscreenminy,d4
		lsr.b #2,d4   ;lu to tiles
		jsr shifttilemap
		;jsr monitor 
		;jmp $
		jsr VM_SaveA3SetA0
		move.l #$66660006,d7	;Tell ChibiVM not to update registers
	popde
	rts
	
	
	
;hardcoded to 32/36 wide tilemap

ShiftTilemap:
	
;	move.l #$FFFFFFFF,$20000
	move.l (backgroundtilemapbase),a3
	
	
	move.l d4,d0
	and.l #$FF,d0		;ypos

	asl.l #3,d0			;*8 192
	
	ifnd backgroundtilemapwidth32
		add.l d0,a3		;hardcoded to 36*2 wide tilemap
	endif
		
	asl.l #3,d0			;*64 1536
	add.l d0,a3			;add ypos to A3

	move.l #backgroundtilemapwidthv*2,d4
	
	move.b d1,d0		;add xpos D1 to A3
	and.l #$FF,d0
	asl.l #1,d0			;2 bytes per tile
	add.l d0,a3
	rts					;D4/C=Tilemap Width
	
	
	
;Build our X-flip LUT

	move.l #FlipLUT,a0		;256 byte Lookup Table
	clr.b d1				;Byte to flip
FillLut:
	
	move.b d1,d0
	and.b #%00000011,d0		;---D
	rol.b #6,d0				;D---
	move.b d0,d2
	
	move.b d1,d0	
	and.b #%00001100,d0		;--C-
	rol.b #2,d0				;-C--
	or.b d0,d2
	
	move.b d1,d0
	and.b #%00110000,d0		;-B--
	ror.b #2,d0				;--B-
	or.b d0,d2			
	
	move.b d1,d0
	and.b #%11000000,d0		;A---
	ror.b #6,d0				;---A
	or.b d0,d2
	move.b d2,(a0)+			
	
	addq.b #1,d1
	bne FillLut				;Repeat for all 256

	endif


	ifd BuildGEN
		include "\Sources\Reikou\Reikou_GEN_MaxTile.asm"
	endif
	ifd BuildX68
		include "\Sources\Reikou\Reikou_X68_MaxTile.asm"
	endif
	ifd BuildSQL
		include "\Sources\Reikou\Reikou_SQL_MaxTile.asm"
	endif
	
	ifd BuildAST
		include "\Sources\Reikou\Reikou_AST_MaxTile.asm"
	endif
	ifd BuildAMI
		include "\Sources\Reikou\Reikou_AMI_MaxTile.asm"
	endif
	ifd BuildNEO
		include "\Sources\Reikou\Reikou_NEO_MaxTile.asm"
	endif