Mul32_8_Sgn:				;This routine performs the operation D3=D3*D0 (Signed) DE.HL=HL*A (Signed)
	and.l #$000000FF,d0
	btst #7,d0
	beq Mul32_8_Sgn_MULS
	
	eor.b #$FF,d0
	addq.b #1,d0
		
	jsr Mul32_8_Sgn_MULS
	neg.l d3
	rts
	
Mul32_8_Sgn_MULS:
	muls d0,d3
	rts

; D3 = SIN(D0)*D2 / de.hl=sin(a)*de (d not useful in result)
sin_a_times_de:
	and.l #$0000FFFF,d2
    btst #15,d2; bit 7,d
	
	beq sin_a_times_de_dnotnegative
	
	eor.w #$0000FFFF,d2
	addq.w #1,d2
	
	jsr sin_a_times_de_dnotnegative
	
	neg.l d3
	rts 
	
sin_a_times_de_dnotnegative:
    ifd usesmallangleapprox
		move.l d0,d3

		and.b #%11111110,d0
		cmp.b #$0,d0
		beq reszero_32

		cmp.b #$80,d0
		beq reszero_32

		add.b #4,d0
		and.b #%11111000,d0       ;small angle approximation

		cmp.b #$40,d0
		beq res127_32

		cmp.b #$c0,d0
		beq resminus127_32

		move.l d3,d0
	endif

	jsr sin    ;y
	
	move.l d2,d3
	
	jsr mul32_8_sgn ;D3=D3*D0 (Signed)
	
	lsl #1,d3
	rts


; D3 = COS(D0)*D2 / de.hl=cos(a)*de  (d not useful in result)
cos_a_times_de:
	and.l #$0000FFFF,d2
    btst #15,d2; bit 7,d
	
	beq cos_a_times_de_dnotnegative
	
	eor.w #$0000FFFF,d2
	addq.w #1,d2
	
	jsr cos_a_times_de_dnotnegative
	
	neg.l d3
	rts
	

cos_a_times_de_dnotnegative:
;                                         ifdef usesmallangleapprox
    ifd usesmallangleapprox
		move.l d0,d3
		
		and.b #%11111110,d0
		cmp.b #$40,d0
		beq reszero_32

		cmp.b #$c0,d0
		beq reszero_32

		add.b #4,d0
		and.b #%11111000,d0
		beq res127_32

		cmp.b #$80,d0
		beq resminus127_32
		
		move.l d3,d0
	endif

	jsr cos       ;y

	move.l d2,d3
	
	jsr mul32_8_sgn ;D3=D3*D0 (Signed)
	
	lsl #1,d3
	rts
	


    ifd usesmallangleapprox

reszero_32:
		clr.l d3 ;anything *0=0
		rts

res127_32:        ;shift dehl >>8
		lsl.l #8,d3
		and.l #$00FFFF00,d3
		rts

resminus127_32:            ;shift and negate de
		lsl.l #8,d3
		neg.l d3
		rts
	endif
