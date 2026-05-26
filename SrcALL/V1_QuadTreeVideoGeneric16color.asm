debugstream equ 1
;This player uses CPC format pixel data (Nibble-Bitplanes)



	; ifnd PixelblockH
	; ifd VASM
; PixelblockH equ (Pixelblock>>8)&255
; PixelblockL equ Pixelblock&255
	; else
; PixelblockH equ Pixelblock/256
; PixelblockL equ Pixelblock
	; endif
	; endif 
	

	ifd QTV_2ColorScreen
		ifnd QTV16c_2bitplane
QTV16c_2bitplane equ 1				;Need the 4 color decoder for 2 color display
		endif 
	endif 
	

	;ifd QTV16c_2bitplane
	;	ifnd QTV16c_NoPalettes
;QTV16c_NoPalettes equ 1				;No use decoding palettes on 2 bitplane display
		;endif 
	;endif

	; align 8
; paletteLut:
	; db 0,0,0,0
	; db 255,0,0,0
	; db 0,255,0,0
	; db 255,255,0,0


;LUT2X needs 512 bytes ($200)
;LUT4X needs 1024 bytes ($400)

quadtreeinit:
	move.l #palettelut,a5
	clr.l d1  ;first palette entry (total 4)

	

quadtreeinitnextpal:
	move.l d1,d0      ;color to use (0-3)
	jsr qtvsetpaletteonedefault  ;set 4 bitplanes for color a

	addq.l #1,d1
    btst #3,d1
	beq quadtreeinitnextpal
	
	rts

qtvsetpaletteone:       ;a=color de=lut
	movem.l d4/d7,-(sp)

		ifd qtv16c_use16to4colorconv
			and.l #%00001111,d0
			move.l #qtv_4colorto16colorlut,a1    ;convert 16 color to 4 color
			add.l d0,a1
			move.b (a1),d0 ;convert 16 color palette to 4 via lut    
		endif
		jsr qtvsetpaletteonedefault
	movem.l (sp)+,d4/d7
	rts

qtvsetpaletteonedefault:
		move.l #4,d7      ;bitplane count
		move.b d0,d4   ;bits of color number
		
qtvsetpalette_nextbit:
		clr.b d0 ;bit 0=write 0
		roxr.b #1,d4   ;rr c ;test lsb
		bcc qtvsetpaletteonezero
		move.b #255,d0      ;bit 1=write 255
qtvsetpaletteonezero:

		move.b d0,(a5)+       ;store bitplane value

		subq.b #1,d7
		bne qtvsetpalette_nextbit
	
	rts

	
	
ProcessQuadTrees:	;D1,D4/BC=XY Pos ;in tiles, A3/HL=Data Source, D2,D5=Quad Size D3,D6/DE=Quad Width/Height A=Bankswitching Bank
	
	; clr.b (Cursor_X)
	; clr.b (Cursor_Y)
	; jsr monitor 
	; jmp *

	ifd MPBitmap_UseBankswitching	
			
			
			
			add CartRamBitStreamDefault	;
			;or %00100000
			ld (QTV_CartRamStream),a
			ifd BuildCPC
					push bc
						ld b,&7F ;We've selected the rom, we need to page it with the gate array
						ifd ScrColor16
							ld c,%10000100	;OO-IULMM	
						else;OOO 4=set rom/mode  I=interrutps  U=Upper rom, L=Lower Rom  MM=mode
							ld c,%10000101	;OO-IULMM	
						endif
						out (c),c
						
						ld b,&DF
						out (c),a
					pop bc
					;di
					;halt
			endif 
			ifd BuildSMS
				ld (&FFFF),a	;Bank &8000-&BFFF
			endif 
			ifd BuildSAM
				out (251),a		;VRAM to area &8000-&FFFF
			endif 
			ifd ENT_MultiBankProg
				Call ENTBankswitch
			endif 
			ifd BuildMSX
				sla a		;Convert 16k banknum -> 8k banknum
				ld (&9000),a	;&8000-&9FFF
				inc a
				ld (&B000),a	;&A000-&BFFF				
			endif 
			
			
			ifd BuildZXS
				call ZXSBankswitch
			endif 
			
			
			push af
				ld a,h
				and %00111111
				;or  %11000000 ;C000+ (ignore 2 bit bank)
				add MPBitmap_BankswitchingRamBase>>8	;&80 00
				ld h,a
			pop af
			
	endif
	
	
	
	ifd DebugBanks		;Show some ram and bank info for debugging
	push de
		push af
			push hl
			ld de,0
				ld a,(hl)
				call ShowHex
				inc hl
				ld a,(hl)
				call ShowHex
				inc hl
				ld a,(hl)
				call ShowHex
				inc hl
				ld a,(hl)
				call ShowHex
				inc hl
				 
				 ld a,' '
				 call PrintChar
			pop hl
			ld a,h
			call ShowHex
			ld a,l
			call ShowHex
			
			ld a,' '
			call PrintChar
		pop af
		call ShowHex
	pop de
	di 
	halt
	endif 
	
	
nextquady:
	moveM.l d1/d4,-(sp)			;push bc
		moveM.l d3/d6,-(sp)			;push ix
nextquadx:
			moveM.l d1/d4/d2/d5/d3/d6,-(sp)			;pushbc
			
				;clr.l (Color_BMP)
				;clr.w (Color_TILE)
			
				jsr doquadtree	;do a quadtree				
			moveM.l (sp)+,d1/d4/d2/d5/d3/d6

			add.b d2,d1			;move across
			subq.b #1,d3 ;IXH
			bne nextquadx

		moveM.l (sp)+,d3/d6			;pop ix
	moveM.l (sp)+,d1/d4				; pop bc
	

	add.b d5,d4						;Move Down
	subq.b #1,d6		;IXL
	bne nextquady
	rts
	

BankSwitch:
	addq.l #1,a3 ;inc hl
	ifd MPBitmap_UseBankswitching
		ld a,(QTV_CartRamStream)
		inc a
		ld (QTV_CartRamStream),a
		ifd BuildCPC
				push bc
					ld b,&DF
					out (c),a
				pop bc
		endif 
		ifd BuildSMS
			ld (&FFFF),a	;Bank &8000-&BFFF
			ld hl,MPBitmap_BankswitchingRamBase
		endif 
		ifd BuildSAM
			out (251),a		;VRAM to area &8000-&FFFF
			ld hl,MPBitmap_BankswitchingRamBase;&8000
		endif 
		ifd ENT_MultiBankProg
				Call ENTBankswitch
			endif 
		ifd BuildMSX
			sla a		;Convert 16k banknum -> 8k banknum
			ld (&9000),a	;&8000-&9FFF
			inc a
			ld (&B000),a	;&A000-&BFFF
			ld hl,MPBitmap_BankswitchingRamBase;&8000
		endif 
		ifd BuildZXS
			call ZXSBankswitch
		endif 
	endif
	jmp DoQuadTree


;                                     

;                                     quad_dxsimplesequence:
quad_dxsimplesequence:
	move.b (a3)+,d0
	and.l #%00001111,d0    ;bytecount up to 15
	bne quad_simplesequenceone

	move.b (a3)+,d0   ;bytecount up to 255
quad_simplesequenceone:
	move.b d0,(qtv_simplecount)
;                                         


doquadtree:     ;bc=xy pos in tiles, hl=data source, de=quad width/height 

	move.b (qtv_simpletblock),d0
	bne tblocks

	move.b (qtv_simplecount),d0
	beq doquadtreehl

	subq.b #1,d0
	move.b d0,(qtv_simplecount)
	move.b (a3),d7
	
	btst #0,d0
	exg d0,d7		;Doesn't alter flags
	bne doquadtree2nd   ;count0=top count 1=bottom
	lsr.b #4,d0

	addq.l #1,a3

doquadtree2nd:
	and.b #%00001111,d0
	cmp.b #$04,d0
	beq quad_quarterblocknohl
	bcs quad_solidnohl
	
	and.l #%00000111,d0    ;8-15 transp blocks
	addq.l #1,d0

tblocks:   ;transparent blocks
	subq.b #1,d0
	move.b d0,(qtv_simpletblock)
	rts


				
DoQuadTreeHL:	;D1/D4=xy pos in tiles, A3=data source, D2/D5=quad width/height 
	
	clr.l d0
	move.b (a3),d0
	
	ifd debugstream
		movem.l d0-d7/a0-a6,-(sp)
			clr.b (Cursor_X)
			move.b #12,(Cursor_Y)
			
			jsr Monitor
			
			
			
			move.l a3,a0
			moveq.l #2,d0
			jsr Monitor_MemDumpDirect
			
			jsr waitforfire
		movem.l (sp)+,d0-d7/a0-a6
	endif	
	
	and.b #%11110000,d0
	beq quad_solid	;this block is all 1 color
;                                     	cp  &10
	cmp.b #$10,d0
	beq quad_quarterblock	;split into 2x2 blocks
;                                     ;	cp  &20
;                                     ;	jp z,quad_eighthblock		;split into 4x4 blocks
;                                     ;	cp  &30
;                                     ;	jp z,quad_sixteenthblock	;split into 16x16 blocks
;                                     ;	cp  &60
;                                     ;	jp z,tintswitch 		;switch tint for this block 
	
	cmp.b #$80,d0
	beq quad_fullres		;fill with 1x1 pixel bitmap
	cmp.b #$90,d0
	beq quad_halfres		;fill with 2x2 pixel bitmap
	cmp.b #$a0,d0	
	beq quad_quarterres		;fill with 4x4 pixel bitmap
	cmp.b #$c0,d0
	beq quad_fullresdoublev	;fill with 1x2 pixel bitmap 
	ifnd QTV16c_DisableFxSupport
		cmp.b #$F0,d0
		beq FxMode
	endif
	cmp.b #$70,d0
	beq bankswitch		;we've gone over a 16k boundary
	
	rts

quad_fullresdoublev:
	jsr getpixeladdress
	pushhl
		jsr getscreenposqtv

; 8x4 pixel block - draw each line twice

		move.b #4,d0        ;line count in pairs of lines 
		;move.l #palettelut,a1
quad_fullresdoublevl:
		movem.l d0,-(sp)
			jsr qtvdosingleline
			ifnd qtv_2colorscreen
				subq.l #2,a5
				jsr qtvdosingleline
			endif
		movem.l (sp)+,d0
		subq.b #1,d0
		bne quad_fullresdoublevl
		jsr drawbufferqtv
	pophl

    ifd mpbitmap_usebankswitching
		jmp qtv_streambankrestore
    else
		rts
	endif

qtvdosingleline:
	jsr qtv_clearbitplanes
	move.b #%10000000,d3        ;pixel mask
	move.b #2,d6     			;bytes per line

quad_fullresdoublevl_nextbyte:
	movem.l d6,-(sp)
		move.l #4,d5         ;pixels per byte

		move.b (a5),d7	      ;llll----    (cpc format)
		move.b (a5)+,d2 	  ;----hhhh    (cpc format)

		lsl.b #4,d2			  ;hhhh----
		
quad_fullresdoublevl_nextpixel:

			clr.l d0
			
			roxl.b #1,d2      ;h bit
			roxl.b #1,d0
			roxl.b #1,d7      ;l bit
			roxl.b #1,d0
			
	   ifnd qtv16c_2bitplane
			move.b #4,d6
		else
			move.b #2,d6
		endif
		;and.l #$000000FF,d0
		asl.b #2,d0      ;*4 bytes per palette entry
		move.l #PaletteLUT,a1
		add.l d0,a1
	
quad_fullresdoublevl_nextbitplane:
		move.b (a1)+,d0     ;get bitplane color from palette lut
		and.b d3,d0      ;mask this pixel
		or.b d0,(a3)+ ;draw to screen

		subq.b #1,d6
		bne quad_fullresdoublevl_nextbitplane

		ifnd qtv16c_2bitplane
			subq.l #4,a3    ;move back to first bitplane for next pixel
		else
			subq.l #2,a3
		endif
		;exx
		lsr.b #1,d3    ;next pixel

		subq.b #1,d5
		bne quad_fullresdoublevl_nextpixel

	movem.l (sp)+,d6
	subq.b #1,d6
	bne quad_fullresdoublevl_nextbyte

qtv_down1lineexx:
    ifnd qtv16c_2bitplane
		addq.l #4,a3  ;move down 1 line (2/4 bitplanes)
	else 
		addq.l #2,a3  ;move down 1 line (2/4 bitplanes)
	endif
	rts

	
quad_fullres:
	jsr getpixeladdress		;AH

	pushhl
		jsr getscreenposqtv

; 8x4 pixel block - draw each line twice

        ifd qtv_2colorscreen
			move.l #4,d0
        else
			move.l #8,d0
		endif

		move.l #palettelut,a1
quad_fullresvl:
		movem.l d0,-(sp)
			jsr qtvdosingleline
			ifd qtv_2colorscreen
				addq.l #2,a5
			endif
		movem.l (sp)+,d0
		subq.b #1,d0
		bne quad_fullresvl
		
		jsr drawbufferqtv
	pophl
	
    ifd mpbitmap_usebankswitching
		jmp qtv_streambankrestore
    else
		rts
	endif

qtv_clearbitplanes:
	move.l #palettelut,a1 ;bc= palette conversion lut
		
	clr.w (a3)+	;bitplane 0/1
	ifnd qtv16c_2bitplane
		clr.w (a3)	;bitplane 2/3
	endif 
	
	subq.l #2,a3
	rts

quad_halfres:
	jsr getpixeladdress		;IY/A5
	pushhl
		;pushiy
		;pophl

quad_halfresfill:
		jsr getscreenposqtv
		move.l #4,d1         ;4 pairs of lines

pixel2x_nextlinepair:

		ifnd qtv_2colorscreen
			move.l #2,d7       ;2 copies of each line
		endif

pixel2x_doubleline:
		move.l #%11000000,d3
		move.l #4,d6

		jsr qtv_clearbitplanes

pixel2x_nextbyte:
		move.b (a5),d2        ;----hhhh    (cpc format)
		move.b (a5),d5       ;llll----
		
		lsl.b #4,d2
pixel2x_nextpair:
		clr.l d0
		roxl.b #1,d2        ;get a pixel
		roxl.b #1,d0
		roxl.b #1,d5
		roxl.b #1,d0
		
		lsl.l #2,d0   ;*4 bytes per palette entry
		
		move.l #PaletteLUT,a1
		add.l d0,a1      ;color to convert
		
		move.b (a1)+,d0   ;convert via lut
		and.b d3,d0     ;mask the pair we want
		or.b d0,(a3)+  ;write to screen
		
		move.b (a1)+,d0   ;convert via lut
		and.b d3,d0     ;mask the pair we want
		or.b d0,(a3)+  ;write to screen
		
		
		ifnd qtv16c_2bitplane
			move.b (a1)+,d0   ;convert via lut
			and.b d3,d0     ;mask the pair we want
			or.b d0,(a3)+  ;write to screen
			
			move.b (a1)+,d0   ;convert via lut
			and.b d3,d0     ;mask the pair we want
			or.b d0,(a3)+  ;write to screen
			
			sub.l #4,a3
		else 
			sub.l #2,a3
		endif
		
		lsr.b #2,d3
		
		subq.b #1,d6
		bne pixel2x_nextpair

		jsr qtv_down1lineexx  ;add 2/4 to hl'

	   ifnd qtv_2colorscreen
			subq.b #1,d7 ;dec iyl
			bne pixel2x_doubleline   ;draw each line twice
		endif

		addq.l #1,a5        ;next source

		subq.b #1,d1
		bne pixel2x_nextlinepair

		jsr drawbufferqtv
	pophl

    ifd mpbitmap_usebankswitching
qtv_streambankrestore:
		move.l qtv_cartramstream,d0
        ifd buildcpc
			pushbc
				move.l #$df,d1
				move.b d0,(c)
			popbc
		endif
        ifd buildsms
			move.b d0,($ffff)
		endif
        ifd buildsam
			move.b d0,(251)
		endif

        ifd ent_multibankprog
			jsr entbankswitch
		endif

        ifd buildmsx
            sla a
			move.b d0,($9000)
			addq.l #1,d0
			move.b d0,($b000)
		endif

        ifd buildzxs
			jsr zxsbankswitch
		endif
	endif
	rts


;                                     

;                                     quad_quarterres:
quad_quarterres:
	jsr getpixeladdress
	
	pushhl

;quad_quarterresfill:
		lsr.b #1,d2     ;always 2 (width)
		move.b d5,d0 	;always 2 (height)

pixelnextyq:
		movem.l d0,-(sp)
;                                                 call getscreenposqtv
			jsr getscreenposqtv
;                                                 push bc
			pushbc
                clr.l d7        ;first pair of pixels
				jsr doquadblock

				subq.l #2,a5
			popbc

			addq.l #1,d1            ;second tile 
			jsr getscreenposqtv

			pushbc
                move.b #1,d7       ;second pair of pixels
				jsr doquadblock
			popbc
			subq.l #1,d1             ;back to first tile
			addq.l #1,d4
			
		movem.l (sp)+,d0

		subq.b #1,d0       ;next strip
		bne pixelnextyq
	pophl

    ifd mpbitmap_usebankswitching
		jmp qtv_streambankrestore
    else
		rts
	endif

doquadblock:
	move.b #2,d1

pixel4x_nextlinepair:
    ifd qtv_2colorscreen
		move.l #2,d4
    else
		move.l #4,d4           ;duplicate each line 4 times
	endif

pixel4x_doubleline:
	move.b #%11110000,d3    ;pixel mask
	move.b #2,d6         ;two halves per byte

	jsr qtv_clearbitplanes

	move.b (a5),d2         ;----hhhh    (cpc format)
	move.b (a5),d5          ;llll----
	lsl.b #4,d2
	
;                                         ld a,iyl
	clr.l d0
	cmp.b #0,d7		;iyl (1st/2nd block)
	beq pixel4x_nexthalf
	
	lsl.b #2,d2		;shift to right pixels
	lsl.b #2,d5
	
pixel4x_nexthalf:
	clr.l d0
	
	roxl.b #1,d2        ;get a pixel
	roxl.b #1,d0
	roxl.b #1,d5
	roxl.b #1,d0	

	move.l #PaletteLUT,a1
	lsl.l #2,d0 ;4 bytes per color in palette lut
	add.l d0,a1      ;color to convert
	
	
	
    ifnd qtv16c_2bitplane
		move.b (a1)+,d0   ;convert via lut
		and.b d3,d0     ;mask the pair we want
		or.b d0,(a3)+  ;write to screen
		
		move.b (a1)+,d0   ;convert via lut
		and.b d3,d0     ;mask the pair we want
		or.b d0,(a3)+  ;write to screen
		
		move.b (a1)+,d0   ;convert via lut
		and.b d3,d0     ;mask the pair we want
		or.b d0,(a3)+  ;write to screen
		
		move.b (a1)+,d0   ;convert via lut
		and.b d3,d0     ;mask the pair we want
		or.b d0,(a3)+  ;write to screen
				
		sub.l #4,a3
	else 
		move.b (a1)+,d0   ;convert via lut
		and.b d3,d0     ;mask the pair we want
		or.b d0,(a3)+  ;write to screen
		
		move.b (a1)+,d0   ;convert via lut
		and.b d3,d0     ;mask the pair we want
		or.b d0,(a3)+  ;write to screen
		
		sub.l #2,a3       ;back to first bitplane
	endif
	
	
	lsr.b #4,d3    ;next pixel pairs
	
	subq.b #1,d6	;Half
	bne pixel4x_nexthalf     ;do other byte half

	jsr qtv_down1lineexx       ;add 2/4 to hl'

	subq.b #1,d4
	bne pixel4x_doubleline

	addq.l #1,a5          ;next line data

	subq.b #1,d1
	bne pixel4x_nextlinepair
	jmp drawbufferqtv
	
drawbufferqtv:
	movem.l d0-d7/a0-a6,-(sp)

		ifnd qtv16c_2bitplane
			move.l #4,d0        ;bitplane count
		else
			ifd qtv_2colorscreen
				move.l #1,d0
			else
				move.l #2,d0
			endif
		endif
		
		clr.l d2
		clr.l d5
		
		move.l #tempbuffer,a3
		move.b (a3)+,d5   ;ypos
		move.b (a3)+,d2   ;xpos
		;move.b #1,(a3)
		;move.b #2,(4,a3)
		;move.b #3,(8,a3)
		
		
		; movem.l d0-d7/a0-a6,-(sp)
			; clr.b (Cursor_X)
			; move.b #12,(Cursor_Y)
			
			; move.l #tempbuffer,a0
			; moveq.l #4,d0
			; jsr Monitor_MemDumpDirect
			
			; move.l #paletteLut,a0
			; moveq.l #4,d0
			; jsr Monitor_MemDumpDirect
			
			
			; jsr waitforfire
		; movem.l (sp)+,d0-d7/a0-a6
		
		
		jsr mpbitmap_settile
	
	movem.l (sp)+,d0-d7/a0-a6
	rts

	
quad_quarterblock:
	addq.l #1,a3
quad_quarterblocknohl:

	lsr.b #1,d2					;Halve Width
	lsr.b #1,d5					;Halve Height
			
	moveM.l d1/d4,-(sp)		;pushbc
		moveM.l d2/d5,-(sp)		;pushde
			moveM.l d1/d4,-(sp)		;pushbc
				;move.l (Color_BMP),d0
				;move.l d0,-(sp)
				;	move.w (Color_TILE),d0
				;	move.l d0,-(sp)
						jsr doquadtree
				;	move.l (sp)+,d0
				;	move.w d0,(Color_TILE)
				;move.l (sp)+,d0
				;move.l d0,(Color_BMP)
			moveM.l (sp)+,d1/d4		;popbc
		moveM.l (sp)+,d2/d5		;popde
		add.b d2,d1
		moveM.l d2/d5,-(sp)		;pushde
			;move.l (Color_BMP),d0
			;	move.l d0,-(sp)
			;		move.w (Color_TILE),d0
			;		move.l d0,-(sp)
						jsr doquadtree
			;		move.l (sp)+,d0
			;		move.w d0,(Color_TILE)
			;	move.l (sp)+,d0
			;	move.l d0,(Color_BMP)
		moveM.l (sp)+,d2/d5		;popde
	moveM.l (sp)+,d1/d4		;popbc
	add.b d5,d4
	moveM.l d2/d5,-(sp)		;pushde
		moveM.l d1/d4,-(sp)		;pushbc
			;move.l (Color_BMP),d0
			;	move.l d0,-(sp)
			;		move.w (Color_TILE),d0
			;		move.l d0,-(sp)
						jsr doquadtree
			;		move.l (sp)+,d0
			;		move.w d0,(Color_TILE)
			;	move.l (sp)+,d0
			;	move.l d0,(Color_BMP)
		moveM.l (sp)+,d1/d4		;popbc
	moveM.l (sp)+,d2/d5		;popde
	add.b d2,d1
	jmp DoQuadTree
	
quad_solid:
	clr.l d0
	move.b (a3)+,d0
quad_solidnohl:
	cmp.b #15,d0      ;color 15=transparent
	beq quad_solid_RTS
	
	movem.l a3,-(sp)
		movem.l d2/d5,-(sp)
			and.l #$000000FF,d0
			lsl.l #2,d0 ;4 bytes per color in palette lut
			move.l #PaletteLUT,a1
			add.l d0,a1      ;color to convert
		movem.l (sp)+,d3/d6
quad_solid_strip:
		movem.l d3/d6,-(sp)
			movem.l d1/d4,-(sp)
quad_solid_line:
			
				jsr qtvsingleblock
				
				addq.b #1,d1
				subq.b #1,d6
				bne quad_solid_line
			movem.l (sp)+,d1/d4
			addq.l #1,d4
		movem.l (sp)+,d3/d6
		subq.b #1,d3
		bne quad_solid_strip
	movem.l (sp)+,a3
	
	; movem.l d0-d7/a0-a6,-(sp)
		; clr.b (Cursor_X)
		; clr.b (Cursor_Y)
		
		; jsr Monitor
		; jsr waitforfire
	; movem.l (sp)+,d0-d7/a0-a6
	
	
	
quad_solid_RTS:
	rts

	
;fillone:
;		jsr qtvsingleblock
	;pophl
	;rts

qtvsingleblock:
	MoveM.L a3,-(sp)
		jsr getscreenposqtv
		ifd qtv_2colorscreen
			move.l #4,d2
		else
			move.l #8,d2
		endif

quad_solid_lineblock:
		ifnd qtv16c_2bitplane
			move.l #4,d5
		else
			move.l #2,d5
		endif

quad_solid_linebitplane:
		move.b (a1)+,d0
		move.b d0,(a3)+

		subq.b #1,d5
		bne quad_solid_linebitplane

		ifnd qtv16c_2bitplane
			subq.l #4,a1
		else
			subq.l #2,a1	
		endif

		subq.b #1,d2
		bne quad_solid_lineblock
		jsr drawbufferqtv
	MoveM.L (sp)+,a3
	rts 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  ;get 8x8 tile pos b,c
getscreenposqtv:
	move.l #tempbuffer,a3
	move.b d4,(a3)+     ;ypos
	move.b d1,(a3)+       ;xpos	
	rts



	
GetPixelAddress:		;A5/IY= Pixel address
	move.l #pixelblock,a5
	
	ifnd QTV16c_DisableFxSupport
		move.b (QTV_FxFlags),d0
		and.l #%00000010,d0
		bne GetPixelAddressFx
	endif

	clr.l d0
	
	btst.b #3,(a3)			;----cccc
	beq getpixeladdressbyte
		
	move.b (0,a3),d0
	and.l #%00000111,d0	;-----ccc - top bank bits U
	asl.l #8,d0
	move.b (2,a3),d0	;H
	asl.l #8,d0
	move.b (1,a3),d0	;L
	add.l d0,a5
	addq.l #3,a3
	rts

	
	
getpixeladdressbyte:
	move.b (0,a3),d0
	and.l #%00000111,d0	;-----ccc - top bank bits H
	asl.l #8,d0
	move.b (1,a3),d0	;L
	asl.l #2,d0
	
	addq.l #2,a3
GetPixelAddressByte2:	
	add.l d0,a5
	rts

	
	ifnd QTV16c_DisableFxSupport

 ;15/24/32 bit address 
getpixeladdressfx:
	pushde
		move.b (a3)+,d7      ;----cccc
		and.b #%00000011,d7     ; byte count 2/3/4/?

		clr.l d0
		move.b (1,a3),d0
		lsl #8,d0
		move.b (0,a3),d0
	
		addq.l #2,a3
	
		cmp #0,d7
		beq getpixeladdressbyte2        ;2 - 16 bit
		
		clr.l d6
		move.b (a3)+,d6
		lsl #8,d0
		lsl #8,d0
		add d6,d0
		
		subq.b #1,d7
		beq getpixeladdressbyte2        ;3 - 24 bit 
		
		clr.l d6
		move.b (a3)+,d6
		lsl #8,d0
		lsl #8,d0
		lsl #8,d0
		add d6,d0
		jmp GetPixelAddressByte2	  ;4 - 32 bit??????????

		
fxmode:
;                                     ;turn on fx extensions.

;                                     ; takes 1 extra byte %x---cac 

;                                     ;  t=true color on (else off) %rrrrrggggggbbbbb

;                                     ;  a=exteded pixel address bytes

;                                     ;     bottom two bits in %cccc in address is now number of bytes!

;                                     ;     (0=16 1=24 2=32 3=40 bit addr)

;                                     ;  x=2nd extended param byte (for future use)


	move.b (a3)+,d0    ;get the fx byte
	
	cmp.b #$f0,d0
	beq fxmode_f0        ; 0xf0 nn = setting change nn
	
	
;new palette    %1111dcba= colors to change dcba (colors 3-1)

	pushbc
	pushde
		move.l #palettelut,a5
		move.b d0,d4    ;palette entry mask %----3210
		move.l #4,d1       ;palette count (4 colors max)

		move.l #4,d2        ;bytes per instance (4=1 color)

		move.b (qtv_fxflags),d0
		and.l #%00000101,d0    ;fx color mode 1=rgb color
		cmp.b #%00000100,d0          ;  0=256 color
		bne notfxmode_16

		move.l #8,d2    ;2 entries per instance in 16 color mode

notfxmode_16:

fxpaletteagain:
		roxr.b #1,d4
		bcc fxpaletteagainskip ;not changing this color?
	;                                             

	;                                             ld e,(hl)        
		clr.l d5
		move.b (a3)+,d5    ;l byte / color byte in 256/16 color mode 

		move.b (qtv_fxflags),d0
		and.l #%00000101,d0      ;fx color mode 1=rgb color
		beq fxmode_256            ;  5=argb color
		
		cmp.b #%00000100,d0      ;  0=256 color
		beq fxmode_16
		
		
	;true color   %rrrrrggg gggbbbbb=> 0babbbbbgg gggrrrrr
		clr.l d3
		move.b d5,d3
		
	;                                             ld a,(hl)            ;h byte

		clr.l d0
		move.b (a3)+,d0
		lsl.l #8,d0
		add.l d0,d3
		

		move.l #6,d1 ;get the top 4 bits of the g component

truecolorshift:
		lsr.l d1,d3      ;shift to the bits we want
		bra fxmode_256b  ;use the result as a color number

fxmode_256:
		move.b d5,d0

fxmode_256b:

        ifnd qtv16c_nopalettes
			movem.l a5,-(sp)
				jsr qtvsetpaletteone	;D0A=Color A5/DE=LUT
			movem.l (sp)+,a5
		endif

fxpaletteagainskip:
		clr.l d0
		move.b d2,d0    
		add.l d2,a5   ;one palette entry bytecount
			  ;update pointer to palette lut

		subq.b #1,d1
		bne fxpaletteagain
fxmode_palettedone:
	popde
	popbc
	jmp doquadtree

fxmode_16:
    ifnd qtv16c_nopalettes
		move.b d5,d0    ;use %----1111 as color 1
		movem.l a5,-(sp)
			jsr qtvsetpaletteone	;D0A=Color A5/DE=LUT

			clr.l d0
			move.b d5,d0
			lsr.l #4,d0      ;use %2222---- as color 2
			jsr qtvsetpaletteone	;D0A=Color A5/DE=LUT
		movem.l (sp)+,a5
	endif

	subq.l #1,d1   ;we did 2 palettes per byte so skip extra one 
	bra fxpaletteagainskip

fxmode_f0:     ;new setting byte
	move.b (a3)+,d0
	move.b d0,(qtv_fxflags)   ;%x---CAC		C-C = Color mode A=Addressing
							;C 0=256 color (palette)
							;C 1=RGB 16bpp %RRRRRGGGGGGBBBBB
							;C 4=16 color (Palette)
							;C 5=ARGB 16bpp %AAAARRRRGGGGBBBB
	jmp doquadtree

	endif
;                                     


	