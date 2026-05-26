
;s0 r0  A	  D0
;s1 r1  B BC  D1 A1
;s2 r2  D DE  D2 A2
;s3 r3  H HL  D3 A3
;s4 r4  C     D4
;s5 r5  E     D5
;s6 r6  L     D6
;s7 r7  IX       A5
;t7 r8  IY       A6
;t8 r9	      D7

;t9/a0 r10	 (Was A0 / r10)
;t9/a1 r11	 (Was A0 / r10)

	
;D3/D6 are HL'
;A1/A4 are BC'
;D7 is D'
	


;IY = A6

;IXH=d7
;IXL=A5
	
rlegetnextbyte:
	move.l a5,d0	;IXL=A5
	and.l #$000000FF,d0
;                                         dec a    
	subq.b #1,d0    ;1=repeat
	beq rledecompress_rleagain_rep
	subq.b #1,d0    ;2=linear 
	beq rledecompress_linearagain_rep

	rts       ;3=done

rledecompress:
	clr.l d0
	move.b (A6)+,d0   ;load a header byte
	beq rleeof    ;zero byte=sequence done - return

	btst #7,d0	;#%10000000	   jp m,rledecompress_rle 
	bne rledecompress_rle                 ;m=jump if sign negative (top bit 1)

;                                     

;                                     rledecompress_linear:    ;top bit = 0
rledecompress_linear:
	clr.l d7
	move.b d0,d7    ;byte count (1-127)
	
	move.l #2,a5		;IXL ;ld ixl,2    ;linear marker
    ;ld ixl,2
;                                     rledecompress_linearagain:
rledecompress_linearagain:
	clr.l d0
	move.b (a6),d0  ;copy b bytes from source
	rts

rledecompress_linearagain_rep:
	addq.l #1,a6    ;inc iy
	subq.b #1,d7    ;dec ixh

	bne rledecompress_linearagain   ;repeat until b=0
	bra rledecompress ;get next header byte

rledecompress_rle:  ;top bit = 1
	and.b #%01111111,d0  ;byte count (1-127)
	move.l d0,d7	;IXH=d7
    
	move.l #1,a5 ;IXL    ;rle marker

rledecompress_rleagain:
	clr.l d0
	move.b (a6),d0   ;get the byte
	rts

rleeof:

	move.l #3,a5	;IXL   ;eof marker

rledecompress_rleagain_rep:
    subq.b #1,d7 ;dec ixh
	bne rledecompress_rleagain    ;repeat until b=0

    addq.l #1,a6 ;inc iy
	bra rledecompress ;get next header byte
;                                     

;                                     

