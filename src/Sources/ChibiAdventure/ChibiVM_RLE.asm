;+regNO
  
;Extended functions to improve the Adventure Engine, and reduce
; CPU load from ChibiVM

syscallRLE equ 14

rleInit equ 0
rleNextByte equ 1
rleDecodeTile equ 2
rleDrawTile equ 3
rleDrawScreen equ 4
	
vecRLECall:
	dc.l RLEDecompress  ;0 - Start Decompression
	dc.l RLEGetNextByte ;1 - Get another byte
	dc.l RleDoDecodeTile  ;2
	dc.l RleDoDrawTile    ;3
	dc.l RleDoDrawScreen	  ;4


;                                     rledecompress_call:    
rledecompress_call:
	move.l #vecrlecall,a6
	jmp ChibiVM_VectorCall

;de=xy bc=wid/hei h=halfheight l=bitplanes
rledodrawscreen:
	pushbc
	pushhl
		move.l d6,d0
		and #$000000FF,d0		;Bitplane count
		
		;move.l #vm_rambase+16,a3        ;pointer to up to 4 rle files 
		move.l (vm_rambaseAddr),a3
		add.l #16,a3
		
		move.l #rledecoderram,a1        ;6 bytes per rle 
rledecompresstobcfromhl_again:
		movem.l d0,-(sp)
			jsr rledecompresstobcfromhl
		movem.l (sp)+,d0

		subq.l #1,d0
		bne rledecompresstobcfromhl_again
	pophl
	popbc

drawtitley:
	pushde
	pushbc
drawtitlex:
		jsr rledodecodetile
		jsr rledodrawtile

		addq.b #1,d2
		subq.b #1,d1
		bne drawtitlex
	popbc
	popde
	addq.b #1,d5

	subq.b #1,d4
	bne drawtitley
	rts

rledodecodetile:
	pushbc
	pushde
		move.l d6,d5    ;bitplanes
		move.l d3,d2    ;stretch
		move.b d6,d0	;bitplanes 
		pushhl
			move.l #rletilebuffer,a3
			move.l #rledecoderram,a1

nextbitplane:
			movem.l d0,-(sp)
				jsr dorlefilltobc
				addq.l #1,a3
			movem.l (sp)+,d0
			subq.b #1,d0
			bne nextbitplane

		pophl
	popde
	popbc
	rts

rledodrawtile:
	pushbc
	pushde
	pushhl
		move.b d6,d0         ;bitplanes 
		move.l #rletilebuffer,a3
		and.l #$000000FF,d2
		and.l #$000000FF,d5
		jsr mpbitmap_settile
	pophl
	popde
	popbc
	rts

	
;IY = A6

;IXH=d7
;IXL=A5
	
rledecompresstobcfromhl:
		clr.l d0
		move.b (1,a3),d0
		lsl.l #8,d0
		move.b (0,a3),d0
		
		add.l #2,a3
		
		
		
		
		add.l #VramBase,d0
		move.l d0,a6
		;move.l #SpewTubeScreen1,a6
		
rledecompresstobc:
	jsr rledecompress
	bra rledecompresstobcb
;                                         

;                                     dorlefilltobc:
dorlefilltobc:
	pushbc	
		clr.l d0
		move.b (a1)+,d0		;IXL flag (1=repeat 2=linear 3=done)
		move.l d0,a5
		
		move.b (a1)+,d7		;IXH byte count 
		
		
		move.l (a1)+,a6		;IY rle stream current byte
	
		jsr dorlefill
	popbc

rledecompresstobcb:
		move.l a5,d0
		move.b d0,(a1)+		;IXL
		
		move.b d7,(a1)+		;IXH
		
		move.l a6,(a1)+		;IY
	
	rts

	
dorlefill:
	pushhl
		move.l #8,d1         ;lines per tile 

fillrleagain:
		pushde
			
			move.l d2,d4	;ld c,d (Copies / repeated lines)
			and.l #$000000FF,d5			;DE (Skip after each decode)

			move.b (a6),d0		
fillrleagaindupe:
			move.b d0,(a3)
			add.l d5,a3	;add hl,de         ;skips

			subq.b #1,d1

			subq.b #1,d4         ;copies
			bne fillrleagaindupe

			jsr rlegetnextbyte
		popde
		tst.b d1
		bne fillrleagain
	pophl
	rts


