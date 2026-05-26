	; move.l #teplateyarita,a3	;source
	; move.l #tileplayer,a2;dest
	; move.l #$1000+1,d4
	; move.b #5,d6	;width
	; move.b #8,d7		;height
	; jsr expandtilemap

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;D6,D7/iyh,iyl = Width / Height

;D4/ix	= first tile pattern num
;A3/hl	= source tilemap (1 byte per tile)
;A2/de	= temptilemap (2 byte per tile)

ExpandTilemap:
	move.b d6,d1
templatetileloop:
	jsr expandone
	addq.l #1,a3			;Source Tilemap
	subq.b #1,d1			;Width
	bne templatetileloop
	subq.b #1,d7			;Height
	bne expandtilemap
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;a=mode (0/1/2/3 = normal/xflip/yflip/xyflip)

ExpandTilemapA:
	tst.b d0
	beq expandtilemap
	subq.b #1,d0
	beq expandtilemapx
	subq.b #1,d0
	beq expandtilemapy

expandtilemapxy:
	or.b #%00001110,d4	;set xyflip

	move.b d7,d0

	clr.l d0
	move.b d7,d0		;Height
	
	and.l #$FF,d6
	mulu d6,d0			;Height*Width
	
	add.l d0,a3	
	subq.l #1,a3		;hl points to last tile

expandtilemapxyagain:
	move.b d6,d1		;width in tiles
	move.l a3,-(sp)

templatetileloopxy:
		jsr expandone	;expand a line
		subq.l #1,a3
		subq.b #1,d1
		bne templatetileloopxy
	move.l (sp)+,a3 
	and.l #$FF,d6
	sub.l d6,a3
	
	subq.b #1,d7		;height in lines
	bne expandtilemapxyagain
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ExpandTilemapX:
	or.l #%00001010,d4		;set xflip
	
	clr.l d0
	move.b d6,d0			;width
	subq.l #1,d0
	add.l d0,a3				;move to last tile on line

expandtilemapxloop:
	move.b d6,d1			;width in tiles
	move.l a3,-(sp)
templatetileloopx:
		jsr expandone		;expand a line
		subq.l #1,a3
		subq.b #1,d1
		bne  templatetileloopx
	move.l (sp)+,a3
	and.l #$FF,d6
	add.l d6,a3
	subq.b #1,d7			;height in lines
	bne expandtilemapxloop
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


ExpandTilemapY:
	or.b #%00000110,d4	;set xyflip
	
	clr.l d0
	move.b d7,d0	
	cmp.b #2,d0			;height <2 lines?
	bcs expandtilemapyagain	;yes
	subq.b #1,d0

	and.l #$FF,d6
	mulu d6,d0
	add.l d0,a3			;width*(Height-1)

expandtilemapyagain:
	move.b d6,d1		;width in tiles
	move.l a3,-(sp) 
templatetileloopy:
		jsr expandone	;expand a line
		addq.l #1,a3
		subq.b #1,d1
		bne  templatetileloopy
	move.l (sp)+,a3	 
	and.l #$FF,d6
	sub.l d6,a3
	
	subq.b #1,d7		;height in lines
	bne expandtilemapyagain
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;a3 hl=tilemap source (1 byte per tile)
;a2 de=tilemap destination (2 bytes per tile)
;d4 ix=tile mask/offset... de=(hl)+ix

;expand 1 byte tile -> 2 byte

ExpandOne:
	move.b (a3),d0
	bne templatetileloopok	;0=transparent
	move.w #$f2ff,(a2)+	;transp = &ff f2 (Little Endian)
	rts

templatetileloopok:
	and.l #$FF,d0 		;tile *16
	asl.l #4,d0			;&tt -> &0tt_
	
;add d4 tile mask/base
	add.w d4,d0
	
	move.b d0,(a2)+		;Write Little endian
	lsr.w #8,d0
	move.b d0,(a2)+
	rts

	
	
