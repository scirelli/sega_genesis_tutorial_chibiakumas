MPB_Pen0 equ 0
MPB_Pen1 equ 1
MPB_Pen2 equ 2
MPB_Pen3 equ 3
MPB_Pen4 equ 4
MPB_Pen5 equ 5
MPB_Pen6 equ 6
MPB_Pen7 equ 7
MPB_Pen8 equ 8
MPB_Pen9 equ 9
MPB_PenA equ 10
MPB_PenB equ 11
MPB_PenC equ 12
MPB_PenD equ 13
MPB_PenE equ 14
MPB_PenF equ 15

MpBitmap_TileTints:
	dc.b 255,0,0

	align 4
	
;A3=pattern source / D1=Xpos (tiles) / D4=Ypos (tiles) / D0=Bitplane count
mpbitmap_settile:		
	jsr mpbitmap_GetScreenPosTile
	jsr prepareVram
	move.l #8-1,d6		;Lines

mpbitmap_settile_nextline:
	ifd mpbitmap_tiletints 
		move.b (mpbitmap_tiletints+0),d2
		move.b (mpbitmap_tiletints+1),d3
		move.b (mpbitmap_tiletints+2),d4
	else
	   clr.b d2			;Bitplane 1 default
	   clr.b d3			;Bitplane 2 default
	   clr.b d4			;Bitplane 3 default
	endif 	
   
	move.b (a3)+,d1		;Load Bitplane 0
	cmp.b #1,d7
	beq mpbitmap_settile_loaddone
	
	move.b (a3)+,d2		;Load Bitplane 1
	cmp.b #2,d7
	beq mpbitmap_settile_loaddone
	
	move.b (a3)+,d3		;Load Bitplane 2
	cmp.b #3,d7
	beq mpbitmap_settile_loaddone
	
	move.b (a3)+,d4		;Load Bitplane 3
	
mpbitmap_settile_loaddone:

	move.l #8-1,d5		;Pixels per line

	clr.l d0
mpbitmap_settile_nextpixel:
		
	roxr.l d1			;Bitplane 0
	roxr.l d0
	roxr.l d2			;Bitplane 1
	roxr.l d0
	roxr.l d3			;Bitplane 2
	roxr.l d0
	roxr.l d4			;Bitplane 3
	roxr.l d0

	dbra d5,mpbitmap_settile_nextpixel

	move.l d0,($C00000)	;Store line to VRAM
	
	dbra d6,mpbitmap_settile_nextline
	rts
	
	
	
;A3=pattern destination / D1=Xpos (tiles) / D4=Ypos (tiles) / D0= Bitplane count

mpbitmap_gettile:
	jsr mpbitmap_GetScreenPosTile
	jsr prepareVramRead
	
	move.l #8-1,d6
mpbitmap_gettile_nextline:
	
	move.l ($C00000),d0	;Get Line from VRAM
	
	move.l #8-1,d5		;Pixels per line
mpbitmap_gettile_nextpixel:
	roxr.l d0		
	roxr.b d1			;Bitplane 0
	roxr.l d0
	roxr.b d2			;Bitplane 1
	roxr.l d0
	roxr.b d3			;Bitplane 2
	roxr.l d0
	roxr.b d4			;Bitplane 3

	dbra d5,mpbitmap_gettile_nextpixel

	move.b d1,(a3)+		;Store Bitplane 0
	cmp.b #1,d7
	beq mpbitmap_gettile_loaddone
	
	move.b d2,(a3)+		;Store Bitplane 1
	cmp.b #2,d7
	beq mpbitmap_gettile_loaddone
	
	move.b d3,(a3)+		;Store Bitplane 2
	cmp.b #3,d7
	beq mpbitmap_gettile_loaddone
	
	move.b d4,(a3)+		;Store Bitplane 3
	
mpbitmap_gettile_loaddone:	
	dbra d6,mpbitmap_gettile_nextline
	rts

	

;D2=Xpos in tiles / D5=Ypos in tiles
mpbitmap_GetScreenPosTile:
	move.l d0,d7			;Bitplane count
	asl.l #3,d2				;Tiles To Pixels *8
	asl.l #3,d5

;D2=Xpos in pixels / D5=Ypos in pixels
mpbitmap_GetScreenPos:	
	and.l #255,d2			;Xpos
	and.l #255,d5			;Ypos
	
	move.l #256*32,a6		;+Tile 256 (First tile of BMP screen)
	
	move.l d5,d0
	and.l #%00000111,d0		;Ypos within tile
	asl.l #2,d0				;Ypos *4 (4 bytes per line )
	add.l d0,a6
	
	move.l d5,d0
	and.l #%11111000,d0		;Ypos in tiles
	asl.l #7,d0				;Ypos *1024 (32 bytes * 32 tiles)
	add.l d0,a6
	
	move.l d2,d0				
	and.l #%11111000,d0		;Xpos in tiles
	lsl.l #2,d0				; *32
	add.l d0,a6
	rts
	
			
prepareVramRead:	;To select a memory location  we need to calculate 
				; the command byte... depending on the memory location
				; $7FFF0003 = Vram $FFFF... $40000000=Vram $0000
	movem.l d0/d6,-(sp)
	
		move.l a6,d0
		and.w #%1100000000000000,d0	;Shift the top two bits to far right 
		rol.w #2,d0
		
		move.l a6,d6
		and.l #%0011111111111111,d6	;shift the other bits left two bytes
		rol.l #8,d6	
		rol.l #8,d6
		
		or.w d0,d6						
		move.l d6,(VDP_ctrl) ;$C00004 VDP control
	movem.l (sp)+,d0/d6
	rts
	
	
;D0=Color to set / D2=Xpos / D5=Ypos
mpbitmap_setpixel:
	move.l d0,d1			;Color
	and.l  #$0000000F,d1	;Mask for pixel to set
	move.l #$FFFFFFF0,d4	;Mask for pixels to keep
	
	move.l d2,d7			;Xpos 0-7
	and.l #%00000111,d7		
	eor.l #%00000111,d7		;Pixel in 32 bit long (0-7)
    beq mpbitmap_setpixel0

	lsl.l #2,d7		;4 bits per pixel

	rol.l d7,d1     ;shift color to left pixel
	rol.l d7,d4     ;shift mask to left pixel

mpbitmap_setpixel0:
	jsr mpbitmap_GetScreenPos
	jsr prepareVramRead
	
	move.l ($C00000),d7	;Get Long from screen
	and.l d4,d7			;Mask to clear pixel
	or.l d1,d7			;Set pixel to new value
	
	jsr prepareVram
	move.l d7,($C00000)	;Write Long to screen
	rts

	
;D2=Xpos / D5=Ypos / D0=Returned color
mpbitmap_getpixel:
	jsr mpbitmap_GetScreenPos
	jsr prepareVramRead
	
	move.l ($C00000),d0		;Get Long from screen
	
	move.l d2,d7			;Xpos 0-7
	and.l #%00000111,d7
	eor.l #%00000111,d7		;Pixel in 32 bit long (0-7)
    beq mpbitmap_getpixel0
	
	lsl.l #2,d7				;4 bits per pixel
	lsr.l d7,d0  		   	;shift color to left pixel
mpbitmap_getpixel0:

	and.l #$0000000F,d0		;Returned color from screen
	rts

	

	
	
