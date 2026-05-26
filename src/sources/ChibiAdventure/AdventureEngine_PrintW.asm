;alternate cls routine that doesn't use printchar
cls:
	
	clr.l d5
clsy:
	clr.l d2

clsx:
	pushde
		move.l #spacechar,a3
		moveq.l #1,d0              ;bitplanes
		jsr mpbitmap_settile
	popde
	addq.b #1,d2
	cmp.b #32,d2
	bne clsx
	addq.b #1,d5
	cmp.b #24,d5
	bne clsy

	clr.l d2
	clr.l d5
	rts

    ifnd use10bitfont
printnumber:
		add.b #48,d0     ;ascii 0
printchar:
	movem.l d0,-(sp)
	pushbc		
		move.b d0,d1
		and.l #$000000FF,d1
		jsr printchartile
	popbc
	movem.l (sp)+,d0
	rts

printcharw:             ;print word char d1/bc
	movem.l d0,-(sp)
	pushbc
		jsr printchartile
	popbc
	movem.l (sp)+,d0
	rts

printchartile:
;                                             push hl
	pushhl
		move.l #-32,d3            ;32 chars unused
		add.l d1,d3
		lsl.l #3,d3    ;8 bytes per char
		
		move.l #fontdataw,a3
		add.l d3,a3
		pushde
			move.l #1,d0       ;bitplanes
			jsr mpbitmap_settile ;hl = source tile pattern d=xpos (tiles) e=ypos (tiles)
		popde
		ifd font_righttoleft
			subq.l #1,d2
		else
			addq.l #1,d2
		endif
	pophl
	rts
	endif

    ifd use10bitfont

printcharw:       ;print word character d1/bc
	movem.l d0,-(sp)
		movem.l d0-d7,-(sp)
			sub.l #32,d1
			bra printcharw2

printnumber:
	add.b #48,d0          ;ascii 0
;                                     printchar:        
printchar:        ;print byte char a

	; move.l #1,d0
	; move.l #4,d2
	; move.l #4,d5
	; jsr mpbitmap_setpixel       ;ld=xpos e=ypos a=color
	; jmp *

    ifnd font_drawzeropixels
		cmp.b #33,d0
		bcs printcharspace
	endif

	movem.l d0,-(sp)
		movem.l d0-d7,-(sp)
			sub.b #32,d0

			clr.l d1
			move.b d0,d1
	
printcharw2:
		
			lsl.l #2,d1		;*4
			move.l d1,d3
			lsl.l #1,d1		;*8
			add.l d1,d3 		;effectively *12
			
			move.l #font10bit,a1
			add d3,a1
			

;D7 iyh - bits per line 
;D6 ixl - byte total

;A1 bc=bitmap source

;d2 ld = xpos d5 e=ypos
			lsl.l #1,d5	;*2
			move.l d5,d0
			lsl.l #2,d5	;*8
			add.l d0,d5	;effectively *10
			
			lsl.l #1,d2	;*2
			move.l d2,d0
			lsl.l #2,d2	;*8
			add.l d0,d2	;effectively *10


			move.l #10,d7          ;width
			move.l #12,d6    	   ;bytes
			
			jsr printcharspec
		movem.l (sp)+,d0-d7
	movem.l (sp)+,d0

		; move.l #1,d0
	; move.l #4,d2
	; move.l #4,d5
	; jsr mpbitmap_setpixel       ;ld=xpos e=ypos a=color
	; jmp *

printcharspace:
	addq.l #1,d2
	rts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;D7 iyh - bits per line 
;D6 ixl - byte total

;A1 bc=bitmap source

;d2 ld = xpos d5 e=ypos

printcharspec:


	movem.l d2/d5/d7,-(sp)
	;pushde
	;pushiy
		
;                                             inc iyh                    ;line bits 
        add.b #1,d7
;                                         printcharspecb:
printcharspecb:
;                                                 ld a,ixl            ;byte count 
		cmp.b #0,d6 
		beq printcharspec_done
		subq.b #1,d6
		move.b (a1)+,d0
		move.l #8,d3					        ;bit count IXH
				
printcharspecbit:
		subq.b #1,d7 ;dec iyh       ;line bits left?
		beq printcharspec_newline
printcharspecbitb:
;                                                 rlca
		clr.l d1
		roxl.b #1,d0
		
;                                                 ifndef font_drawzeropixels
        ifnd font_drawzeropixels
			bcc specsafesetpixelskip    ;only draw set pixels
		endif
		roxl.b #1,d1        ;set/clear pixel
		movem.l d0,-(sp)
			movem.l d0-d7/a0-a6,-(sp)
				
				
				ifd font10bit_coloroff
					clr.l d0
					move.b (font10bit_coloroff),d0
					cmp.b #0,d1
					beq printcharspec_zero
					move.b (font10bit_coloron),d0
				else 
					move.l d1,d0
				endif
printcharspec_zero:
				move.l d2,d6
				lsr.l #8,d6
				; move.l #1,d0
				; move.l #4,d2
				; move.l #4,d5
				jsr mpbitmap_setpixel       ;ld=xpos e=ypos a=color
			movem.l (sp)+,d0-d7/a0-a6
		movem.l (sp)+,d0
;                                         specsafesetpixelskip:
specsafesetpixelskip:
		addq.l #1,d2  ;x-l
specsafesetpixellok:
		subq.b #1,d3 ;dec ixh
		bne printcharspecbit
	bra printcharspecb

printcharspec_done:
	movem.l (sp)+,d2/d5/d7
	rts

printcharspec_newline:
	movem.l (sp)+,d2/d5/d7
	;popiy
	;popde

		addq.l #1,d5    ;down a pixel line
	movem.l d2/d5/d7,-(sp)
	;pushde
	;pushiy
	bra printcharspecbitb

	endif

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


printcharmultibytep:
	movem.l (sp)+,d0  ;consume ret

	pophl       ;get seq addr
	
	clr.l d1
	move.b (1,a3),d1
	lsl.l #8,d1
	move.b (0,a3),d1
	addq.l #2,a3
	

	pushhl   ;inline address (in seq)
	
		move.l (vm_rambaseAddr),a3
		add.l d1,a3
		jsr printseqmultibyte
	pophl
	bra printcharmultibytei2

printcharmultibytei:
	movem.l (sp)+,d0    ;consume ret
	pophl      ;get seq addr
	jsr printseqmultibyte

printcharmultibytei2:
	popbc
	jmp printseq

printcharmultibytev:
	clr.l d1
	move.b (1,a3),d1
	lsl.l #8,d1
	move.b (0,a3),d1
	addq.l #2,a3

	move.w a3,(printseqxvarram)
	pushhl
		move.l (vm_rambaseAddr),a3   ;string address (in vars)
		add.l d1,a3
		jsr printseqmultibyte
		jsr printseqmultibyte
	pophl
	rts
;                                     

;                                     

;                                     printseqmultibyte:
printseqmultibyte:
	clr.l d0
	move.b (a3)+,d0    ;get l byte
	cmp.b #255,d0        ;255= done
	bne lbl_6750x3969
	rts
lbl_6750x3969
	cmp.b #32,d0
	bcc printseqmultibyte_ok
	move.b d0,d1
	lsl #8,d1
	move.b (a3)+,d1

	jsr printcharw   ;print char &0000-&1fff (8k chars max!)e
	bra printseqmultibyte

printseqmultibyte_ok:
	jsr printchar
	bra printseqmultibyte
;                                     

;                                     

;                                         

;                                         

;                                     

;                                     ;fontdataw:

;                                         ;incbin "\resall\chibiadventures\fontarabic.raw"

;                                         

;                                     ;fontdata:

;                                     ;font10bit:

;                                         ; incbin "\resall\chibiadventures\kanji10pxfrequency.1.raw"

;                                         ; incbin "\resall\chibiadventures\kanji10pxfrequency.2.raw"

;                                         ; incbin "\resall\chibiadventures\kanji10pxfrequency.3.raw"

;                                         ; incbin "\resall\chibiadventures\kanji10pxfrequency.4.raw"

;                                     

