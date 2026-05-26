;ScreenBase equ $c00000+(1024*16)	;VRAM destination for full redraw

	include "\SrcAST\AST_V1_MaxTile_Normal.asm"
	
	
;                                     initmaxtile:
initmaxtile:

	move.l (VM_RamBaseAddr),a0
	add.l #rkflags,a0
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
	
	
						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Build the lookup table
		
	move.l #FlipLUT,a0		;Lookup table
	clr.l d1				;Byte to convert
FillLutMX:
	move.b d1,d0
	
	move.w #7,d3			;8 bits 
FillLut2:	
		roxr.b #1,d0		;Shift a bit right out of source
		roxl.b #1,d2		;Shift a bit left in to destination
	dbra d3,FillLut2
	
	move.b d2,(a0)+			;Write the byte
	
	addq.b #1,d1			;Repeat for 0-255
	bne FillLutMX
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	move.l (VM_RamBaseAddr),d3
	add.l #MaxTileTilemap,d3	;Default background tilemap
	
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
	
SetPalette:
	rts
	