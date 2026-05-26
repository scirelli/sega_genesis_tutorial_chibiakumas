
syscallQTV equ 6 
 

qtInitQTV equ 0
;qtDrawFramesQTVfullscreen equ 1
;qtDrawFramesQTVCustomSize equ 2
;qtDrawFramesQTV equ 3
qtPtrocessQuadTreeFrameVM equ 4
;qtReversePlay equ 5
qtPtrocessQuadTreeFrameVMbyFrameNum equ 8
qtSetPaletteMP equ 6


qtvcall:
	move.l #vecqtv,a6
	
	
	
	; move.l (VM_RamBaseAddr),a3
	; move.l (VM_RamBaseAddr),a0
	; clr.l d7
	; move.b (VM_rPC+1,a3),d7
	; asl.l #8,d7
	; move.b (VM_rPC,a3),d7
	; add.l d7,a0
	
	; clr.l d0
	; move.b (a0),d0
	
	; movem.l d7,-(sp)
	; movem.l d0,-(sp)
		; addq.l #1,d7
		
		
		; move.b d7,(VM_rPC,a3)
		; lsr.l #8,d7
		; move.b d7,(VM_rPC+1,a3)
		
		; asl.l #2,d0
			
		; move.l (a6,d0),a6
		; move.l #InitQTV,a4
		; move.l #ProcessQuadTreeFrameVMbyFrameNum,a5
	; movem.l (sp)+,d0
	; movem.l (sp)+,d7
	
	; clr.b (Cursor_X)
	; clr.b (Cursor_Y)
	; jsr monitor 
	
	
	; move.l a6,a0
	; moveq.l #4,d0
	; jsr Monitor_MemDumpDirect
	
	; jmp *
	
	
	jmp ChibiVM_VectorCall	

	
vecqtv:
	dc.l InitQTV					;0
	dc.l QTV_RTS ;DrawFramesQTVfullscreen  ;1
	dc.l QTV_RTS ;DrawFramesQTVCustomSize  ;2
	dc.l QTV_RTS ;DrawFramesQTV  		    ;3
	dc.l ProcessQuadTreeFrameVM   ;4 - Process a single frame
	dc.l QTV_RTS ;QTVReverse				;5
	dc.l SetPaletteMPchibivm			;6 ;//B=Palettecount        ;//C=FirstPaletteNum        ;//HL=PaletteAddress
	dc.l QTV_RTS ;SetVideoAddress			;7 // Top bits only - bottom 14 bits all zero (multiple of 16k) // %00HHHHHH HHLLLLLL LL000000 00000000  //A= Bank size (Banknum * ? in sequence ) 
	dc.l ProcessQuadTreeFrameVMbyFrameNum ;8 - R0=Framenum R14=Sequence addr
	
	
QTV_RTS:
	rts
	
processquadtreeframevmbyframenum:

	; clr.b (Cursor_X)
	; clr.b (Cursor_Y)
	; jsr monitor 
	; jmp *
	
	move.l (VM_RamBaseAddr),a0
	
	clr.l d3
	move.b (23,a0),d3	;ld hl,(vm_rambase+22) ;Sequence
	asl.l #8,d3
	move.b (22,a0),d3
	add.l a0,d3
	move.l d3,a3
	
	clr.l d1
	move.b (VM_rR1,a0),d1	;ld bc,(vm_rambase+0)    ;r0 = frame number
	asl.l #8,d1
	move.b (VM_rR0,a0),d1
	

	lsl.l #2,d1    ;4 bytes per frame 

	add.l d1,a3	
	
	
	
	bra processquadtreeframevmb

processquadtreeframevm:


	move.l (VM_RamBaseAddr),a0
	
	clr.l d3
	move.b (23,a0),d3	;ld hl,(vm_rambase+22) ;tilemap base    
	asl.l #8,d3
	move.b (22,a0),d3
	add.l a0,d3
	
	move.l d3,a3
	
processquadtreeframevmb:

    ;ifdef mpbitmap_usebankswitching
	
	
	
	clr.l d0
	move.b (1,a3),d0
	;and.b #$3F,d0
	lsl.l #8,d0
	move.b (0,a3),d0
	
	add.l d7,d0
	
	move.l #BitStream-FileZero,d7
	sub.l d7,d0
	add.l #BitStream,d0
	
	ifd buildGEN
		move.l #BitStream,d7
		and.l #$FFFF0000,d7
		add.l d7,d0
	endif 
	
	move.b (2,a3),d7
	lsl.l #6,d7			;Number in 16k banks
	lsl.l #8,d7
	and.l #$FFFF0000,d7	;Bank num (in 64k blocks)
	add.l d7,d0
	
	
	move.l d0,a3
	
	;add.l #FileZero,a3
	
	
	move.b (2,a0),d0		;Bank
	
	;endif
	clr.l d1
	clr.l d4
	
	move.b (16,a0),d4 ;xpos,ypos
	move.b (17,a0),d1
	
	clr.l d2
	clr.l d5
	
	move.b (18,a0),d5 ;width,height (in 8x8 tiles=64x64)
	move.b (19,a0),d2
	
	
	clr.l d3
	clr.l d6
	
	move.b (20,a0),d6  ;tilemap size (32x24 in 8x8 quadtrees)
	move.b (21,a0),d3
	
	
	
	
	
	jmp processquadtrees	;D1,D4/BC=XY Pos ;in tiles, A3/HL=Data Source,
							; D2,D5=Quad Siz , D3,D6/DE=Quad Width/Height\
							;  A=Bankswitching Bank

initqtv:
	move.l (VM_RamBaseAddr),a0
	
	clr.l d0
	clr.b (qtv_reverseplay)
	clr.b (qtv_reverseplay+1)

	clr.b (qtv_simplecount)
	clr.b (qtv_simpletblock)
	clr.b (qtv_fxflags)

	move.b (rkflags,a0),d0
		
		
		
	and.b #rkflags_q,d0       ;qtv already inited?
	bne QTV_RTS
	
	
	
	move.b (rkflags,a0),d0
	and.b #%00011111,d0
	or.b #rkflags_q+rkflags_d,d0
	move.b d0,(rkflags,a0)

	
	jmp quadtreeinit

	
	
    ifnd setpalettempchibivm

setpalettempchibivm:
		move.l (VM_RamBaseAddr),a0
		
		
		clr.l d3
		move.b (VM_rR7,a0),d3
		asl.l #8,d3
		move.b (VM_rR6,a0),d3
		add.l a0,d3
		
		move.l d3,a3
		
		clr.l d4
		clr.l d1
		move.b (VM_rR0,a0),d4
		move.b (VM_rR1,a0),d1
		
		
	   ;//b=palettecount        ;//c=firstpalettenum        ;//hl=paletteaddress
setpalettemp:
		pushbc
			move.b (a3)+,d0
			pushhl
				move.b (a3),d3
				move.b d0,d6

				move.b d4,d0
				jsr setpalette
			pophl
			addq.l #1,a3
		popbc
		addq.l #1,d4

		subq.b #1,d1
		bne setpalettemp
		rts

	endif
;                                     

