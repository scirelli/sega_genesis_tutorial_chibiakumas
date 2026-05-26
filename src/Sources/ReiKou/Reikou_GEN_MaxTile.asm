;                                     screenbase equ &c000
ScreenBase equ $C000+8+(64*4)	;Tilemap base VRAM address
;                                     

	include "\SrcGEN\Gen_V1_MaxTile_Normal.asm"
	
	
;                                     initmaxtile:
initmaxtile:


	move.l #rkflags,a0
;                                         ld a,(hl)
	move.b (a0),d0
;                                         and rkflags_m
	and.b #rkflags_m,d0
;                                         ret nz            ;qtv already inited?
	beq lbl_BCE7x630C
	rts
lbl_BCE7x630C
;                                         ld a,(hl)
	move.b (a0),d0
;                                         and %00011111
	and.b #%00011111,d0
;                                         or rkflags_m
	or.b #rkflags_m,d0
;                                         ld (hl),a
	move.b d0,(a0)
;                                         
	
	;jsr monitor
	;jmp $

	
;Define our patterns in VRAM
	move.l a3,a0
	move.l d4,d1
	;move.l #Bitmap,a0					;Source data
	;move.w #(Bitmap_End-Bitmap)/4,d1	;Bytecount
	move.l #patterndata*32,a6			;Dest VRAM 32 bytes per tile
	jsr DefineTiles						;Send pattern data
	
	ifd PatternDoubleHeight
		add.l #PatternDoubleHeight*32,a6	;Offset to doubleheight tiles
		jsr DefineTilesDouble
	endif 
	
	
	ifd FillData
		move.l #PatternFill*32,a6			;Offset to fills
		move.l #FillData,a0
		move.l #8,d1			;Fillcount
		jsr DefineTilesFills
	endif 
	
	
	
	move.l #MaxTileTilemap,d3	;Default background tilemap
	move.l d3,(backgroundtilemapbase)
	

	move.l #36*2,d3
	move.b d3,(backgroundtilemapwidth)

;Define the cropping area to use the full window
	
	move.b #vscreenminy,d0
	move.b d0,(cropyh+1)

	move.b #vscreenhei-vscreenheiclip,d0
	move.b d0,(cropyh)

	move.b #vscreenminx,d0
	move.b d0,(cropxw+1)
	
	move.b #vscreenwid-vscreenwidclip,d0
	move.b d0,(cropxw)
	
	rts
	
	
SetPalette:
	rts
	
				
prepareVram:	;To select a memory location D2 we need to calculate 
				;the command byte... depending on the memory location
				;$7FFF0003 = Vram $FFFF.... $40000000=Vram $0000
	move.l a6,d0
	and.w #%1100000000000000,d0	;Shift the top two bits to the far right 
	rol.w #2,d0
	
	move.l a6,d6
	and.l #%0011111111111111,d6	;shift all the other bits left two bytes
	rol.l #8,d6	
	rol.l #8,d6
	
	or.l d0,d6						
	or.l #$40000000,d6	;Set the second bit from the top to 1
						;#%01000000 00000000 00000000 00000000
	move.l d6,(VDP_ctrl) ;$C00004	VDP control, word or longword writes only
	rts