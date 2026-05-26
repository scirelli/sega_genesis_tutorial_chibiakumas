	
	
	ifnd Spr_XY
;Pointers to sprite 0bject parameters
Spr_XY equ 0				;X/Y Pos in logical units
Spr_WH equ 2				;Width/Height in logical units
Spr_TilemapHL equ 4			;Source Sprite Tilemap
Spr_PatternHL equ 8			;Source pattern data
Spr_CropCache equ 12		;Crop sprite position 
Spr_CropCache_Back equ 12+16 ;Crop background area for tilemap redraw
	endif



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;A3=bgtilemap, D2,D5=width/height ;D4=bg tilemapwidth
GetTilemapUnderSprite:
	tst.b (crop_f,a4)
	bne MaxTileDoRet		;Return if Not onscreen

	move.b (crop_x,a4),d1
	move.b (crop_y,a4),d4
	
	move.b (crop_w,a4),d3
	move.b (crop_h,a4),d6

	jsr docroplogicaltotile	;Convert to tile co-ords (/4)
	beq MaxTileDoRet		;Return if zero tiles

	pushhl
		jsr shifttilemap
	popde					;width/height
	 or #%00000001,CCR 		;Set Carry=1
MaxTileDoRet:
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;redraw the background under a sprite

;A3=bgtilemap D1,D4= x,y pos ;D2,D5=wid/hei

RemoveSprite:
	jsr gettilemapundersprite
	bcc MaxTileDoRet	;carry=something to draw (c=tilemap width)

updatetilecacheb:
	move.l a3,-(sp)
		move.b d2,d1	;width

flagcacheagain:
		bset.b #0,(a3)	;set 'redraw' flag of background tile
		addq.l #2,a3

		subq.b #1,d1	;Loopcount
		bne flagcacheagain

updatetilecachea:
	move.l (sp)+,a3
	add.l d4,a3			;d4.l=tilema[p width
	subq.b #1,d5
	bne updatetilecacheb
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Convert Logical pos to Tilemap tile pos 
; Z=True if size is zero

DoCropLogicalToTile:	;BC=Xypos HL= WH
	and.l #$ff,d1	
	and.l #$ff,d4	
	
	and.l #$ff,d3	
	and.l #$ff,d6	
	
	lsr.l #2,d1		;xpos /4
	lsr.l #2,d4		;ypos /4
	
	lsr.l #2,d3		;width /4
	lsr.l #2,d6		;height /4
	
	tst.b d3		;Is width or height zero?
	beq MaxTileDoRet2
	tst.b d6
MaxTileDoRet2:
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;D5=tilemap width D4=ypos D1=xpos
;hardcoded to 32/36 wide tilemap

ShiftTilemap:
	move.l (backgroundtilemapbase),a3
	
	move.l d4,d5
	and.l #$FF,d5		;ypos

	asl.l #3,d5			;*8 192
	
	ifnd backgroundtilemapwidth32
		add.l d5,a3		;hardcoded to 36*2 wide tilemap
	endif
		
	asl.l #3,d5			;*64 1536
	add.l d5,a3			;add ypos to A3

	move.l #backgroundtilemapwidthv*2,d4
	
	move.b d1,d0		;add xpos D1 to A3
	and.l #$FF,d0
	asl.l #1,d0			;2 bytes per tile
	add.l d0,a3
	rts					;D4/C=Tilemap Width
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ifnd doublebuffered
flagspriteforredraw:	;Flag sprite A4 tiles for redraw
		clr.l d3
		
		move.b (spr_wh,a4),d3 	;Height
		asr.b #2,d3

		clr.l d4
		move.b (spr_wh+1,a4),d4	;Width
		asr.l #2,d4
		mulu d3,d4				;Width*height
		
		move.l (spr_tilemaphl,a4),a3	;A3=tilemap D4=tilecount
		
resettilemapsprite:
		move.w (a3),d0
		and.w #%1111111011111111,d0
		cmp.w #$F2FF,d0			;Transparent
		beq resettilemapskip
		
resettilemapdoit:
		bset.b #0,(a3)			;Set tile to redraw

resettilemapskip:
		addq.l #2,a3
		subq.w #1,d4
		bne resettilemapsprite
		rts
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;reset d1 tiles of tilemap a3

resettilemap:
		bset.b #0,(a3)		;flag tile to redraw
		addq.l #2,a3		;Move to next tile

		subq.w #1,d1
		bne resettilemap
		rts
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;d2,d5=wh d4=tilemapwidth a3=tile src

ResetTilemapPart:
		move.b d2,d1
		and.l #$FF,d4
		move.l a3,a2
resettilemappartb:
			bset.b #0,(a3)	;flag tile for redraw
			addq.l #2,a3
			subq.b #1,d1
			bne resettilemappartb
		move.l a2,a3

		add.l d4,a3			;Down a line
		subq.b #1,d5
		bne ResetTilemapPart
		rts
	endif
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;force refresh of sprite if background changed

ResetDirtySpriteIX:			;A4=sprite object data
	tst.b (spr_cropcache+crop_f,a4)
	bne MaxTileDoRet
	
	add.l #spr_cropcache,a4	;Move to Crop cache
	move.b (crop_x,a4),d1
	move.b (crop_y,a4),d4

	move.b (crop_w,a4),d3
	move.b (crop_h,a4),d6

	move.b (backgroundtilemapscrolly),d0
	and.b #%00000010,d0		;%????tthh
	beq dirty_nohalfy

	addq.l #2,d4			;increase width 1/2 tile
dirty_nohalfy:

	move.b (backgroundtilemapscrollx),d0
	and.b #%00000010,d0		;%????tthh
	beq dirty_nohalfx
	
	addq.l #2,d1			;increase height 1/2 tile
dirty_nohalfx:

	jsr docroplogicaltotile ;convert to tile co-ords
	beq MaxTileDoRet

	addq.l #1,d3			;increase size 1 tile
	addq.l #1,d6

	movem.l d3/d6,-(sp)
		jsr shifttilemap	;c=tilemap width
		
	movem.l (sp)+,d3/d6		;sprite width/height

	move.l (crop_s,a4),a2	;Source Sprite Tilemap Address 

updatetilecachebb:
	movem.l a2/a3,-(sp)
		move.b d3,d1		;Width
flagcacheagainb:
		btst.b #0,(a3) 		;Test background tilemap for redraw
		beq cacheclean
		
		bset.b #0,(a2)		;Set center sprite tile
		bset.b #0,(2,a2)	;Set right sprite tile
		
		move.l a2,-(sp)
			clr.l d0
				move.b (crop_stilew,a4),d0	;Width
				asl.l #1,d0
				add.l d0,a2				;Down one line
				
				bset.b #0,(a2)			;Set linedown center
				bset.b #0,(2,a2)		;Set line down right
		move.l (sp)+,a2
cacheclean:
		addq.l #2,a2	;Across one sprite tile
		addq.l #2,a3	;Across one background tile
		subq.b #1,d1	;Repeat for width
	bne flagcacheagainb
	movem.l (sp)+,a2/a3

	clr.l d0
	move.b (crop_stilew,a4),d0	;Tilemap width
	asl.l #1,d0
	add.l d0,a2					;Down one tilwmap line
		
	add.l #backgroundtilemapwidthv*2,a3
	subq.b #1,d6				;Repeat for height
	bne updatetilecachebb
	rts

	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;set tiles in background cache that will be overlapped by next sprite draw

;a4=sprite object data
ZeroSpriteinCache:
	add.l #spr_cropcache,a4		;move  to crop cache

	tst.b (crop_f,a4)
	bne MaxTileDoRet			;<>0 = all offscreen 
	
	move.b (crop_x,a4),d1
	move.b (crop_y,a4),d4

	ifd hiresx
		addq.b #2,d1			;Xpos + 1/2 tile
	endif
	ifd hiresy
		addq.b #2,d4			;Ypos +1/2 tile
	endif

	move.b (crop_w,a4),d3		;Round down W
	subq.b #1,d3

	move.b (crop_h,a4),d6		;Round down H
	subq.b #1,d6

	jsr docroplogicaltotile		;Convert to tile co-ords
	beq MaxTileDoRet

	movem.l d3/d6,-(sp)
		move.l (backgroundtilemapbase),a3
		jsr shifttilemap
	movem.l (sp)+,d3/d6			;Width/Height
	
	move.l (crop_s,a4),a2		;Source tilemap
	exg a2,a3 ;ex de,hl

;If any of 4 tiles is partially transparent we need to update this tilemap

updatetilecachez:
	moveM.l a2/a3,-(sp) 
		move.b d3,d1			;Width
flagcacheagainz:
		move.b (a3),d0				;A-
		and.b #%00111110,d0
		cmp.b #$32,d0				;Transp tile?
		beq cachecleanz
		addq.l #2,a3

		move.b (a3),d0				;-B
		and.b #%00111110,d0
		cmp.b #$32,d0				;Transp tile?
		beq cachecleanz2

		ifd hiresy
			move.l a3,-(sp) ;pushhl
				clr.l d0
				move.b (crop_stilew,a4),d0
				asl.l #1,d0
			
				add.l d0,a6

				move.b (a3),d0		;-D
				and.b #%00111110,d0
				cmp.b #$32,d0		;Transp tile?
				beq abandonchangez
				
				subq.l #2,a3

				move.b (a3),d0		;-C
				and.b #%00111110,d0
				cmp.b #$32,d0		;Transp tile?
				beq abandonchangez
			move.l (sp)+,a3 ;pophl
			bra dochange
abandonchangez:
			move.l (sp)+,a3 ;pophl
			bra cachecleanz2
dochange:
		endif
		and.b #%11111110,(a2)	;this tile doesn't need update
		bra cachecleanz2		;hl already inced

cachecleanz:
		addq.l #2,a3
cachecleanz2:
		addq.l #2,a2

		subq.b #1,d1
		bne flagcacheagainz	;repeat for width
	moveM.l (sp)+,a2/a3

	clr.l d0
	move.b (crop_stilew,a4),d0		
	asl.l #1,d0
	add.l d0,a3				;A3 (Sprite) down a line

	add.l d4,a2				;A2 (tilemap)+width

	subq.b #1,d6;			;Repeat for Height
	bne updatetilecachez
	rts
		

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DrawSpriteIX:
Cache_DrawSprite:				;A4=sprite object data
	move.l (spr_patternhl,a4),a1 ;Pattern source
	
	add.l #spr_cropcache,a4		 ;Move to crop cache

	tst.b (crop_f,a4)			;All offscreen?
	bne MaxTileDoRet

	move.l (crop_vram,a4),a3	;Vram dest
	move.l (crop_s,a4),a2		;Source tilemap

	move.b (crop_h,a4),d5
	lsr.b #2,d5					;Convert to tile height
	
	move.b (crop_w,a4),d4	
	lsr.b #2,d4 				;Convert to tile width
		
	clr.l d0
	move.b (crop_stilew,a4),d0	;source tilemap width
	asl.b #1,d0
	move.l d0,a6				;Width
	
	ifd drawtilemaph
		jmp drawtilemaph		;hardware sprites
	else
		jmp drawtilemap			;regular
	endif

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


Crop_X equ 1		;XY pos
Crop_Y equ 0		
Crop_W equ 3		;Width Height
Crop_H equ 2
Crop_S equ 4		;Source Tilemap HL
Crop_F equ 8		;Flags 1=offscreen
Crop_STileW equ 9	;SourceTileWidth
Crop_Vram equ 10	;Sprite VRAM Not used by background
;10/14 bytes total



calccrop:
	move.b d3,d0				;Width
	lsr.b #2,d0
	move.b d0,(crop_stilew,a4)	;Width in tiles
	
	jsr docrop
	bcs calccropabort			;Offscreen?
	
	move.b d1,(crop_x,a4)		;XYpos
	move.b d4,(crop_y,a4)
	
	move.b d3,(crop_w,a4)		;Width Height
	move.b d6,(crop_h,a4)

	move.l a5,(crop_s,a4)		;Source tilemap

	clr.b (crop_f,a4)			;flag (onscreen)
	rts

calccropabort:
	move.b #1,(crop_f,a4)		;flag (offscreen)
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;A5 = Tilemap Source
;X,Y=D1,D4  W,H=D3,D6   TileSrc=A5
	
docrop:
	clr.l d2					;D5=top D2=bottom crop
	clr.l d5
	
	
;Crop top side
	clr.l d0
	move.b d4,d0				;X-pos
	sub.b (cropyh+1),d0			;>minimum co-odinate
	bcc notcrop					;nc=nothing needs cropping
	
	neg.b d0
	add.b #3,d0
	move.b d0,d5				;Top Crop
	and.b #%11111100,d0
	
	cmp.b d6,d0					;no pixels onscreen?
	bcc docrop_alloffscreen		;all offscreen
		
;Height calculations split and moved so we can draw
; sprites taller than draw area
	neg.b d0
	add.b d0,d6
	
	move.b d5,d0				
	and.b #%00000011,d0			
	eor.b #%00000011,d0			;Shift amount
notcrop:
	move.b d0,d4				;Draw Ypos
	
	
;crop bottom hand side
	add.b d6,d0					;Add Height
	sub.b (cropyh),d0			;logical height of screen
	bcs nobcrop					;c=nothing needs cropping
	and.b #%11111100,d0
	cmp.b d6,d0					;no pixels onscreen?
	bcc docrop_alloffscreen		;all offscreen
	move.b d0,d2				;amount to remove from bottom 
	
	sub.b d2,d6					;Calculate new height
nobcrop:


;Calculate new IY/A5 Tilemap start
	lsr.b #2,d5					;Lines to remove from top
	beq novclip					;nothing to remove?
	
	clr.l d0
	move.b d3,d0				;Bytes per line	
	lsr.l #1,d0
	
	and.l #$FF,d5				;Calculate amount to remove 
	mulu d0,d5					;(Lines*BytesPerLine)
								
	add.l d5,a5					;Update Start Byte
	
	
NoVClip:
	clr.l d2
	clr.l d5

;Crop Left hand side
	move.b d1,d0
	sub.b (CropXW+1),d0		;VscreenMinX - 64 = Leftmost visible tile
	bcc noLcrop					;nc=nothing needs cropping
	neg.b d0					;Amount to remove
	add.b #3,d0
	move.b d0,d5
	and #%11111100,d0
	cmp.b d3,d0					;no pixels onscreen?
	bcc docrop_alloffscreen		;offscreen
	
	neg.b d0
	add.b d0,d3
	
	move.b d5,d0
	and.l #%00000011,d0			;X shift 
	eor.l #%00000011,d0
noLcrop:
	move.b d0,d1				;Draw Xpos
	
	
;crop right hand side
	add.b d3,d0					;Add Width
	sub.b (CropXW),d0			;logical width of screen
	bcs norcrop					;c=nothing needs cropping
	
	and.b #%11111100,d0
	cmp.b d3,d0					;no pixels onscreen?
	bcc docrop_alloffscreen		;offscreeneen?
	move.b d0,d2
	
	
;Calculate new width
	sub.b d2,d3					;fix Width
norcrop:

;Calculate new IY/A5 Tilemap start
	lsr.b #1,d5
	and.l #%11111110,d5
	add.l d5,a5					;move across
	
nohclip:
	andi #%11111110,ccr			;Clear carry
	rts

docrop_alloffscreen:
	ori #%00000001,ccr			;set carry (nothing to draw)
	rts	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;used to copy tilemap defined as big endian into the little endian used
;by MaxTile


LdirSwapEndian:						;Copy D1+1 bytes from A3 to A2
LdirSwapEndianAgain:
	move.w (a3)+,d0
	ror.w #8,d0
	move.w d0,(a2)+
	subq.l #2,d1
	bne LdirSwapEndianAgain
	rts
