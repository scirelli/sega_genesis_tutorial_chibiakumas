
	ifd UseHsprite


ScreenBase equ $0000		;First Hsprite
	else
	
PatternData equ $1200		;PTTT Palette+Tile
PatternFill equ $11C0

PatternXflip equ $0200		;Offsets
PatternYflip equ $0400
PatternXYflip equ $0600
PatternDoubleHeight equ $0800

ScreenBase equ $7000+4+(32*4)	;Fix layer base $7084
	endif
	
	ifd UseHsprite
		include "SrcAll/V1_MaxTile_HspriteDriver.asm"
		
		include "SrcNEO/NEO_V1_MaxTile_Hsprite.asm"	
		
		include "SrcNEO/NEO_V1_MaxTile_SpriteTilemap.asm"
	else
		include "SrcNEO/NEO_V1_MaxTile_Fix.asm"
	endif
	
	
	
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
	
	
	move.l (VM_RamBaseAddr),a0
	;jsr monitor
	;jmp $

	
	ifd UseHsprite
		jsr DefineHspriteTilemap
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
	
