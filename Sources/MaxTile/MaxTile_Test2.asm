;;;;;;;;;************ prepspriteix is slow


	;macro dwle ;Define a Little Endian 16 bit word - if a 32 bit long is provided it is truncated
	;	dc.b \1&255
		;dc.b (\1/256)&255
	;endm


;Spr_XY equ 0
;Spr_WH equ 2
;Spr_TilemapHL equ 4
;Spr_PatternHL equ 8
;Spr_CropCache equ 12
;Spr_CropCache_Back equ 12+16


RunTest2:
	move.l #backgroundtilemap2+2,(backgroundtilemapbase)	
	;Default background tilemap
	
	move.b #36*2,(backgroundtilemapwidth)
	jsr setscroll

	move.l #teplateyarita,a3	;Source
	move.l #tileplayer,a2		;Dest
	move.l #$1000+1,d4			;Base tile
	move.b #5,d6				;width
	move.b #8,d7				;height
	jsr expandtilemap			;Expand the object tilemap of 
								; The players 'sprite'

								
;Define the cropping area to use the full window
	move.b #vscreenminy,(cropyh+1)				;MinY
	move.b #vscreenhei-vscreenheiclip,(cropyh)	;Height

	move.b #vscreenminx,(cropxw+1)				;MinX
	move.b #vscreenwid-vscreenwidclip,(cropxw)	;Width
	
	
;Calculate areas covered by sprites	
	move.l #$40+1,d1			;Player pos
	move.l #$70,d4
	
	moveM.l d1/d4,-(sp)
		move.l #sprite1,a4
		move.b d4,(spr_xy,a4)	;Set player sprite pos
		move.b d1,(spr_xy+1,a4)

		move.l #sprite1,a4
		jsr calccropremoveix	;Calculate background area behind sprite

		move.l #sprite2,a4
		jsr calccropremoveix

		move.l #sprite3,a4
		jsr calccropremoveix

		move.l #sprite4,a4
		jsr calccropremoveix

		ifd clearborder
			jsr clearborder 	;Draw a border around the game area
		endif
	moveM.l (sp)+,d1/d4
	
	
infloop:
	move.l #sprite2,a4			;Move the test sprites
	addq.b #2,(spr_xy+1,a4)

	move.l #sprite3,a4
	addq.b #1,(spr_xy,a4)

	move.l #sprite4,a4
	addq.b #1,(spr_xy+1,a4)
	addq.b #1,(spr_xy,a4)


	moveM.l d1/d4,-(sp)
		jsr readjoystick
		move.b d0,d2			;Get Joystick D=%4321RLDU
	moveM.l (sp)+,d1/d4		
	btst #0,d2
	bne joynotup			;Jump if UP not presesd
	subq.l #1,d4			;Move Y Up the screen
	jsr MovePlayerSprite	;UpdateSprite pos, remove old sprite
joynotup:

	btst #1,d2
	bne joynotdown			;Jump if DOWN not presesd
	addq.b #1,d4			;Move Y down the screen
	jsr MovePlayerSprite	;UpdateSprite pos, remove old sprite
joynotdown:

	btst #2,d2
	bne joynotleft 			;Jump if LEFT not presesd
	subq.b #1,d1			;Move X Left 
	jsr MovePlayerSprite	;UpdateSprite pos, remove old sprite
joynotleft:

	btst #3,d2
	bne joynotright			;Jump if RIGHT not presesd
	addq.b #1,d1			;Move X Right
	jsr MovePlayerSprite	;UpdateSprite pos, remove old sprite
joynotright:


	btst #4,d2
	bne joynotfire

	moveM.l d1/d4,-(sp)

		move.b (flipmode),d0		;Flip player sprite
		addq.b #1,d0
		and.b #%00000011,d0
		move.b d0,(flipmode)

		move.l #teplateyarita,a3	;Source
		move.l #tileplayer,a2		;Dest
		move.l #$1000+1,d4			;Base Tile
		move.b #5,d6				;Width
		move.b #8,d7				;Height
		jsr ExpandTilemapA			;D0=Flip

		
		move.l #backgroundtilemapbase,a3
		move.b (backgroundtilemapscrollx),d0 ;Scroll the background
		addq.b #1,d0						 ; a unit
		ifnd allowquartertilescroll
			addq.b #1,d0
		endif
		ifnd allowhalftilescroll
			addq.b #2,d0
		endif
		move.b d0,(backgroundtilemapscrollx)
		
		move.b (backgroundtilemapscrolly),d0
		addq.b #1,d0
		ifnd allowquartertilescroll
			addq.l #1,d0
		endif
		ifnd allowhalftilescroll
			addq.l #1,d0
			addq.l #1,d0
		endif
		move.b d0,(backgroundtilemapscrolly)

		
		ifd allowhalftilescroll
		;This code is only used for 1/2 or 1/4 tile scrolls
			ifnd setspeedscroll
				jsr setscroll			;Full scroll redraw
			else
				move.l #sprite1,a4
				jsr removespriteix		;Remove sprites before redraw

				move.l #sprite2,a4
				jsr removespriteix

				move.l #sprite3,a4
				jsr removespriteix
				
				move.l #sprite4,a4
				jsr removespriteix
			
				jsr setspeedscroll		;Speedscroll (LDIR bitmap copy)
			endif
			
			move.l (backgroundtilemapbase),a3

			ifd vscreenhei76
				move.l #backgroundtilemapwidthv*17*2,d1
			else
				move.l #backgroundtilemapwidthv*22*2,d1
			endif
			add.l d1,d3

			ifnd doublebuffered
				move.l #backgroundtilemapwidthv*2,d1 	;Bottom two lines
				jsr resettilemap	;Flag for redraw D1 tiles of tilemap A3
				
				move.l (backgroundtilemapbase),a3
				move.l #vscreenwid/2-4,d1
				add.l d1,a3
				move.l #backgroundtilemapwidthv*2,d4
				move.b #$01,d2 				;Redraw right hand strip
				move.b #$18,d5

				jsr resettilemappart	;D2/D5=wh D4=tilewidth A3=tile src
			endif
			jsr resetscrollb
		else
			;This code is used for full tile scrolls
			jsr resetscroll				;partial scroll redraw
		endif
	moveM.l (sp)+,d1/d4

	
	moveM.l d1/d2/d4,-(sp)
		move.l #sprite1,a4
		jsr removespriteix				;Remove the player sprite
	moveM.l (sp)+,d1/d2/d4

joynotfire:

	moveM.l d1/d4,-(sp)
		move.l #sprite2,a4
		jsr removespriteix		;Remove the sprites from the screen

		move.l #sprite3,a4
		jsr removespriteix

		move.l #sprite4,a4
		jsr removespriteix
		

		move.l #sprite1,a4		;Calculate the area of tilemap covered
		jsr calccropremoveix	; By the sprite to remove it next time.

		move.l #sprite2,a4
		jsr calccropremoveix

		move.l #sprite3,a4
		jsr calccropremoveix

		move.l #sprite4,a4
		jsr calccropremoveix
	moveM.l (sp)+,d1/d4
	
	moveM.l d1/d4,-(sp)
		move.l #sprite1,a4
		move.b d4,(spr_xy,a4)
		move.b d1,(spr_xy+1,a4)
	moveM.l (sp)+,d1/d4
	moveM.l d1/d4,-(sp)
		jsr drawscreen			;Redraw the screen.
		ifd clearborder
			jsr clearborder		;Draw a border if needed
		endif
	moveM.l (sp)+,d1/d4
	
	
	move.l #$FFFF,d2
Delay:	
	nop
;	dbra d2,Delay
	
	jmp infloop



MovePlayerSprite:
	move.l #sprite1,a4
	move.b d4,(spr_xy,a4)
	move.b d1,(spr_xy+1,a4)
	
	moveM.l d1/d2/d4,-(sp)
		jsr removespriteix	;Remove the player sprite from the screen
	moveM.l (sp)+,d1/d2/d4
	rts
	

DrawScreen:
	move.l #sprite1,a4
	jsr resetdirtyspriteix	;Calculate if the sprite needs
							; drawing due to overlap
	ifd buildzxn
		move.b #%00001100,d0
		move.b d0,(tiletint)
	endif
	
	move.l #sprite1,a4		;Calc crop
	jsr PrepSpriteIX_NoFlag	; ZeroInCache (Don't update background)
	move.l #sprite2,a4		; FlagSprite for redraw (Flag Sprite Tilemap)
	jsr PrepSpriteIX
	move.l #sprite3,a4
	jsr PrepSpriteIX
	move.l #sprite4,a4
	jsr PrepSpriteIX

	move.l #patterndata,a3
	move.l (backgroundtilemapbase),a2
	jsr cache_tilemapcls	;Redraw Tilemap

	;ifd buildzxn
	;	move.l #%00001000,d0	;Tint for 16 color systems
	;	move.b d0,(tiletint)	; with 4 color patterns
	;endif

	move.l #sprite1,a4
	jsr drawspriteix			;Draw player

	move.l #sprite2,a4
	jsr drawspriteix			;Draw Cpu1

	;ifd buildzxn
	;	move.l #%00000000,d0
	;	move.b d0,(tiletint)
	;endif

	move.l #sprite3,a4
	jsr drawspriteix			;Draw Cpu2
	
	move.l #sprite4,a4	
	jsr drawspriteix			;Draw Cpu3
	
	ifd clearunusedhsprites
		jsr clearunusedhsprites		;Remove any unused Hsprites
	endif

	ifnd doublebuffered
redrawcaches:
		ifnd nodrawcache
			move.l #cachetable,a5	;Draw the caches in order
			jmp fastdrawcaches
		else
			rts
		endif
	else
		rts
	endif
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ifnd doublebuffered				;A5/IY= Cachelist
fastdrawcaches:
		move.b #cacheentries,d1		;No Of Caches
redrawcacheagain:
		moveM.l d1/a5,-(sp)
			jsr getcacheiy			;Get Cache from IY into IX
			beq fastdrawcaches_CacheEmpty
			jsr processcache		;Process the cache if not empty
fastdrawcaches_CacheEmpty:

		moveM.l (sp)+,d1/a5
		add.l #cacheentrybytes,a5	;Move to next cache
		subq.b #1,d1
		bne redrawcacheagain		;Repeat

		jmp resetcaches
	endif

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RecalcScroll:
	move.l #backgroundtilemap2,d3
	move.b (backgroundtilemapscrollx),d1
	and.l #%000001100,d1	;%????TTHH  T=whole Tile H=Half/Quarter
	lsr.l #1,d1				;2 bytes per tile
	add.l d1,d3				;%????TTHH  T=whole Tile H=Half/Quarter

	clr.l d1
	move.b (backgroundtilemapwidth),d1
	move.b (backgroundtilemapscrolly),d0
	and.l #%00001100,d0		;%????tthh
	lsr.b #2,d0
	beq recalcscrolldone
	
	mulu d1,d0				;Calc Y pos
	add.l d0,d3
	
recalcscrolldone:
	move.l d3,(backgroundtilemapbase)
	move.l #backgroundtilemapwidthv*24,d1
	move.l d3,a3
	rts
	
	
	
SetScroll:	;full scroll redraw
	jsr recalcscroll		;Recacluate Scroll pos
	ifnd doublebuffered	
		jsr resettilemap	;Force tilemap redraw
	endif

resetscrollb:
	;ifd buildzxn
	;	move.b #%00001100,d0			;Sample tint code
	;	move.b d0,(tiletint)			;for 4->16 color
	;endif
	
	move.l #PatternData,a3				;Tile patterns
	move.l (backgroundtilemapbase),a2	;Tilemap
	move.l #cacheaddr1,a1				;Cache
	jmp cache_tilemapcls				;Draw the tilemap
	

	
	;D1/BC = Tile count
	
ResetScroll:	;partial scroll redraw
	move.l (backgroundtilemapbase),a2
	jsr recalcscroll
	jsr resettilemapshift			;Flag the tilemap for redraw
	bra resetscrollb				; where tile onscreen has changed

resettilemapshift:
	ifnd doublebuffered
		move.w (a2),d0				;Tilemap Src
		and.w #%1111111011111111,d0			;Ignore update flag
		cmp.w (a3),d0				;Tilemap Dest
		beq resettilemapshiftskip	;Changed?

resettilemapchange:
		bset.b #0,(a3)				;Yes -Flag update

resettilemapshiftskip:
		addq.l #2,a3
		addq.l #2,a2

		subq.l #1,d1				;Tile Count
		bne resettilemapshift
	endif
	rts
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


PrepSpriteIX:
	ifnd doublebuffered
		move.l a4,-(sp)
			jsr flagspriteforredraw	;Flag sprite tilemap for redraw
		move.l (sp)+,a4
	endif

PrepSpriteIX_NoFlag:
	move.l a4,-(sp)
		jsr calccropix				;Calculate Sprite draw area
	move.l (sp)+,a4
	move.l a4,-(sp)
		jsr zerospriteincache		;Dont redraw tilemap behind sprite
	move.l (sp)+,a4

	rts
	
	
;init draw crop data for sprite ix

CalcCropIX:
	move.l (spr_tilemaphl,a4),a5	;Get Tilemap source
		
	move.b (spr_wh,a4),d6			;Get WidthHeight
	move.b (spr_wh+1,a4),d3

	move.b (spr_xy,a4),d4			;Get XY Pos
	move.b (spr_xy+1,a4),d1

	add.l #spr_cropcache,a4			;Move to Crop cache
	
	move.b #vscreenhei-vscreenheiclip,(cropyh)
	move.b #vscreenwid-vscreenwidclip,(cropxw)

	jsr calccrop
	
	ifd getscreenposh
		jsr getscreenposh			;For hardware sprites
	else
		jsr getscreenpos			;Get Vram Destination
	endif
	
	move.l a3,(crop_vram,a4)		;Store VRAM draw pos in sprite object
	rts
	
	
;caclulate crop buffer for background behind sprite A4
CalcCropRemoveIX:
	ifnd doublebuffered
		move.b (spr_xy,a4),d4		;Get XyPos
		move.b (spr_xy+1,a4),d1

		move.b (spr_wh,a4),d6		;Get WH
		move.b (spr_wh+1,a4),d3
	
;Area Adjustments if we allow half/quarter tile shift
		ifd hiresx
			move.b d1,d0
			and.b #%00000011,d0
			beq remove_noinch
			add.b #4,d3
remove_noinch:
		endif
		ifd hiresy
			move.b d4,d0
			and.b #%00000011,d0
			beq remove_noincl
			add.b #4,d6
remove_noincl:
		endif

		ifd allowhalftilescroll
			move.b (backgroundtilemapscrollx),d0
			ifd allowquartertilescroll
				not.b d0
				and.b #%00000011,d0
				beq shifttilemapxok
			else
				and.b #%00000011,d0
				bne shifttilemapxok
			endif
			sub.b #4,d1
			add.b #4,d3
shifttilemapxok:

		ifd hiresy
			move.b (backgroundtilemapscrolly),d0
			ifd allowquartertilescroll
				not.b d0
				and.b #%00000011,d0
				beq shifttilemapyok
			else
				and.b #%00000011,d0
				bne shifttilemapyok
			endif
			sub.b #4,d4
			add.b #4,d6
shifttilemapyok:
		endif
	endif
	
		add.l #spr_cropcache_back,a4 	;move  to crop cache2

		move.b #vscreenhei,(cropyh)
		move.b #vscreenwid,(cropxw)
		jmp calccrop					;Calculate the area
	else
		rts
	endif
	

;Remove a sprite from the screen

RemoveSpriteIX:
	ifnd doublebuffered
		move.l a4,-(sp)
			add.l #spr_cropcache_back,a4
			jsr removesprite	;d1/d4= x,y pos ;d2/d5=wid/hei
		move.l (sp)+,a4
	endif
	rts





T_BackgroundTilemap2:			;NEED TO Swap ENDIAN!

	dc.w $0031,$0041,$0051,$0061,$0071,$0081,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080
	dc.w $0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080
	dc.w $0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080
	dc.w $0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080

	;Filled
	dc.w $0003,$0103,$0203,$0303,$0403,$0503,$0603,$0703,$0803,$0903,$0A03,$0B03,$0C03,$0D03,$0E03,$0F03,$1003,$1103,$1203,$1303,$1403,$1503,$1603,$1703,$1803,$1903,$1A03,$1B03,$1C03,$1D03,$1E03,$1F03,$0050,$0050,$0050,$0050
	dc.w $0003,$0103,$0203,$0303,$0403,$0503,$0603,$0703,$0803,$0903,$0A03,$0B03,$0C03,$0D03,$0E03,$0F03,$1003,$1103,$1203,$1303,$1403,$1503,$1603,$1703,$1803,$1903,$1A03,$1B03,$1C03,$1D03,$1E03,$1F03,$0050,$0050,$0050,$0050
	dc.w $0003,$0103,$0203,$0303,$0403,$0503,$0603,$0703,$0803,$0903,$0A03,$0B03,$0C03,$0D03,$0E03,$0F03,$1003,$1103,$1203,$1303,$1403,$1503,$1603,$1703,$1803,$1903,$1A03,$1B03,$1C03,$1D03,$1E03,$1F03,$0050,$0050,$0050,$0050
	dc.w $0003,$0103,$0203,$0303,$0403,$0503,$0603,$0703,$0803,$0903,$0A03,$0B03,$0C03,$0D03,$0E03,$0F03,$1003,$1103,$1203,$1303,$1403,$1503,$1603,$1703,$1803,$1903,$1A03,$1B03,$1C03,$1D03,$1E03,$1F03,$0050,$0050,$0050,$0050

	dc.w $0030,$0040,$0050,$0060,$0070,$0080,$0090,$00A0,$00B0,$00C0,$00D0,$00E0,$00F0,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080
	;Yflip
	dc.w $0037,$0047,$0057,$0067,$0077,$0087,$0097,$00A7,$00B7,$00C7,$00D7,$00E7,$00F7,$0037,$0037,$0037,$0037,$0037,$0037,$0037,$0037,$0037,$0037,$0037,$0037,$0037,$0037,$0037,$0037,$0037,$0037,$0037,$0037,$0037,$0037,$0037
	;Xflip
	dc.w $003B,$004B,$005B,$006B,$007B,$008B,$009B,$00AB,$00BB,$00CB,$00DB,$00EB,$00FB,$003B,$003B,$003B,$003B,$003B,$003B,$003B,$003B,$003B,$003B,$003B,$003B,$003B,$003B,$003B,$003B,$003B,$003B,$003B,$003B,$003B,$003B,$003B
	;XYflip
	dc.w $003F,$004F,$005F,$006F,$007F,$008F,$009F,$00AF,$00BF,$00CF,$00DF,$00EF,$00FF,$003F,$003F,$003F,$003F,$003F,$003F,$003F,$003F,$003F,$003F,$003F,$003F,$003F,$003F,$003F,$003F,$003F,$003F,$003F,$003F,$003F,$003F,$003F

	;More Flips
	dc.w $0030,$0030,$0030,$0030,$0037,$0037,$0037,$0037,$003B,$003B,$003B,$003B,$003F,$003F,$003F,$003F,$0040,$0040,$0040,$0040,$0047,$0047,$0047,$0047,$004B,$004B,$004B,$004B,$004F,$004F,$004F,$004F,$0030,$0030,$0030,$0030

	
	;Double
	dc.w $1213,$2213,$3213,$0813,$1013,$1213,$1413,$0613,$0413,$003B,$003B,$003B,$003F,$003F,$003F,$003F,$0030,$0030,$0030,$0030,$0037,$0037,$0037,$0037,$003B,$003B,$003B,$003B,$003F,$003F,$003F,$003F,$0030,$0030,$0030,$0030
	dc.w $1313,$2313,$3313,$0913,$1113,$1313,$1513,$0713,$0513,$003B,$003B,$003B,$003F,$003F,$003F,$003F,$0030,$0030,$0030,$0030,$0037,$0037,$0037,$0037,$003B,$003B,$003B,$003B,$003F,$003F,$003F,$003F,$0030,$0030,$0030,$0030
	
	
	
	dc.w $0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030
	dc.w $0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030
	dc.w $0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030
	dc.w $0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030

	dc.w $0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080
	dc.w $0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080
	dc.w $0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080
	dc.w $0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080

	dc.w $0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030
	dc.w $0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030
	dc.w $0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030
	dc.w $0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030

	dc.w $0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080
	dc.w $0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080
	dc.w $0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080
	dc.w $0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080

	dc.w $0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030
	dc.w $0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030
	dc.w $0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030
	dc.w $0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030,$0030

	dc.w $0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080
	dc.w $0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080
	dc.w $0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080
	dc.w $0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080,$0030,$0040,$0050,$0060,$0070,$0080

	dc.w 0,0,0,0	
	
	

;One byte per tile sprite object tilemaps 
;	Must be expanded before use

templatechibiko:
	dc.b 1,1,2,3,1
	dc.b 4,5,6,7,8
	dc.b 9,10,11,12,1
	dc.b 13,14,15,16,17
	dc.b 18,19,20,21,22
	dc.b 1,23,24,25,1
	dc.b 1,26,27,28,1
	dc.b 1,29,30,31,1

teplateyarita:
	dc.b 0,1,2,3,0
	dc.b 4,5,6,7,8
	dc.b 9,10,11,12,0
	dc.b 13,14,15,16,17
	dc.b 18,19,20,21,22
	dc.b 0,23,24,25,0
	dc.b 0,26,27,28,0
	dc.b 0,29,30,31,0


	  
;Two byte per tile tilemaps

t_spritetilemaps:
t_tilechibiko3:
	dc.w $fff2,$8133,$0820,$0830,$8433
	dc.w $8533,$0860,$0870,$0880,$8933
	dc.w $8a33,$08b0,$08c0,$08d0,$8e33
	dc.w $8f33,$0900,$0910,$0920,$9333
	dc.w $9433,$0950,$0960,$0970,$9833
	dc.w $9933,$09a0,$09b0,$09c0,$9d33
	dc.w $fff2,$9e33,$9f33,$a033,$fff2
	dc.w $fff2,$a133,$a233,$a333,$fff2

t_tilechibiko2:
	dc.w $0800,$0810,$0820,$0830,$0840
	dc.w $0850,$0860,$0870,$0880,$0890
	dc.w $08a0,$08b0,$08c0,$08d0,$08e0
	dc.w $08f0,$0900,$0910,$0920,$0930
	dc.w $0940,$0950,$0960,$0970,$0980
	dc.w $0990,$09a0,$09b0,$09c0,$09d0
	dc.w $fff2,$09e0,$09f0,$0a00,$fff2
	dc.w $fff2,$0a10,$0a20,$0a30,$fff2

	
	
t_tileplayer:
	dc.w $0800,$0810,$0820,$0830,$0840
	dc.w $0850,$0860,$0870,$0880,$0890
	dc.w $08a0,$08b0,$08c0,$08d0,$08e0
	dc.w $08f0,$0900,$0910,$0920,$0930
	dc.w $0940,$0950,$0960,$0970,$0980
	dc.w $0990,$09a0,$09b0,$09c0,$09d0
	dc.w $fff2,$09e0,$09f0,$0a00,$fff2
	dc.w $fff2,$0a10,$0a20,$0a30,$fff2

t_tilechibiko:
	dc.w $0800,$0810,$0820,$0830,$0840
	dc.w $0850,$0860,$0870,$0880,$0890
	dc.w $08a0,$08b0,$08c0,$08d0,$08e0
	dc.w $08f0,$0900,$0910,$0920,$0930
	dc.w $0940,$0950,$0960,$0970,$0980
	dc.w $0990,$09a0,$09b0,$09c0,$09d0
	dc.w $fff2,$09e0,$09f0,$0a00,$fff2
	dc.w $fff2,$0a10,$0a20,$0a30,$fff2
t_spritetilemaps_end:

	align 4

	
	
	;double test
	;dw &1213,&2213,&3213,&0813,&1013,&1213,&1413
	;dw &1313,&2313,&3313,&0913,&1113,&1313,&1513
	;Filled
	;dw &0003,&0103,&0203,&0303,&0403,&0503,&0603,&0703,&0803,&0903,&0A03,&0B03,&0C03,&0D03,&0E03,&0F03,&1003,&1103,&1203,&1303,&1403,&1503,&1603,&1703,&1803,&1903,&1A03,&1B03,&1C03,&1D03,&1E03,&1F03,&0050,&0050,&0050,&0050
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

