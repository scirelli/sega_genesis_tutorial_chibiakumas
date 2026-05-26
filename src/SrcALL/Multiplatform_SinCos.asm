
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

;                                     sin_a_times_d:        ;hl=sin(a)*d
sin_a_times_d:
	and.l #$000000FF,d2
    btst #7,d2; bit 7,d
	beq sin_a_times_d_dnotnegative
	
	neg.b d2
	jsr sin_a_times_d_dnotnegative
	
	neg d6
	neg d3	;Equiv of Z80 H
	rts
;                                     sin_a_times_d_dnotnegative:
sin_a_times_d_dnotnegative:
    ifd usesmallangleapprox
		move.b d0,d3
		and.b #%11111110,d0
		cmp.b #$0,d0
		beq reszero
		cmp.b #$80,d0
		beq reszero

		add.b #4,d0
		and.b #%11111000,d0  ;small angle approximation
	
		cmp.b #$40,d0
		beq res127
	
		cmp.b #$c0,d0
		beq resminus127
	
		move.b d3,d0
	endif
	jsr sin    ;y
	move.l d2,d6
;                                         call mul8zeroh_sgn
	jsr mul8zeroh_sgn
	move.l d6,d0
		lsl.b d6
		roxl.b d3			;sla l rl h  
	
	move.l d0,d6
	lsl.w d6
	
    rts

cos_a_times_d: ;;hl=cos(a)*d
	and #$000000FF,d2

    btst #7,d2; bit 7,d
	beq cos_a_times_d_dnotnegative
	neg d2
	
	jsr cos_a_times_d_dnotnegative
	
	neg d3
	rts

cos_a_times_d_dnotnegative:
;                                         ifd usesmallangleapprox
    ifd usesmallangleapprox
		move.b d0,d3
		and.b #%11111110,d0
		cmp.b #$40,d0
		beq reszero
	
		cmp.b #$c0,d0
		beq reszero
	
		add.b #4,d0
		and.b #%11111000,d0     ;small angle   approximation
		beq res127
	
		cmp.b #$80,d0
		beq resminus127
		move.b d3,d0
	endif

	jsr cos       ;y

	move.l d2,d6
	jsr mul8zeroh_sgn
	
	move.l d6,d0
		lsl.b d6
		roxl.b d3
	move.l d0,d6
	lsl.w d6
	rts

reszero:

	clr.l d3           ;anything *0=0
	clr.l d6
	rts

res127:      ;halve d
	clr.l d6
	clr.l d3
	move.b d2,d3
	rts
	
	
;                                     resminus127:            ;halve and negate d
resminus127:
	clr.l d3
	move.b d2,d3
	neg.l d3

	move.l d3,d6
	lsl.l #8,d6
	
	move.b #255,d6
	rts
	

 ;64 byte quarter table ver

    ifd smallsintable

cos:
		add.b #64,d0

sin:
		btst #7,d0
		beq sinec
		jsr sinec
		neg.b d0
		rts

sinec:
		btst #6,d0
		beq sineb

		and.l #%00111111,d0
		move.l d0,d6
		move.l #63,d0
		sub.b d6,d0

sineb:

		move.l #sinetable,a3
		ifd smallsintable32
			and.b #%00111110,d0
			ror #1,d0
		else
			and.b #%00111111,d0
		endif
		and.l #$000000FF,d0
		add.l d0,a3
		move.b (a3),d0

		rts

        align 256
sinetable:

		ifd smallsintable32
			dc.b 0,6,12,19,25,31,37,43,49,54,60,65,71,76,81,85
			dc.b 90,94,98,102,106,109,112,115,117,120,122,123,125,126,126,127
		else
			dc.b 0,3,6,9,12,16,19,22,25,28,31,34,37,40,43,46,49,51,54,57,60,63,65,68,71,73,76,78,81,83,85,88
			dc.b 90,92,94,96,98,100,102,104,106,107,109,111,112,113,115,116,117,118,120,121,122,122,123,124,125,125,126,126,126,127,127,127

		endif
    else
	
	
;256 byte table version

cos:
		add.b #64,d0

sin:
		move.l #sinetable,a3
		and.l #$000000FF,d0
		add.l d0,a3
		move.b (a3),d0
		rts

        align 256
sinetable:
		dc.b 0,3,6,9,12,16,19,22,25,28,31,34,37,40,43,46,49,51,54,57,60,63,65,68,71,73,76,78,81,83,85,88
		dc.b 90,92,94,96,98,100,102,104,106,107,109,111,112,113,115,116,117,118,120,121,122,122,123,124,125,125,126,126,126,127,127,127
		dc.b 127,127,127,127,126,126,126,125,125,124,123,122,122,121,120,118,117,116,115,113,112,111,109,107,106,104,102,100,98,96,94,92
		dc.b 90,88,85,83,81,78,76,73,71,68,65,63,60,57,54,51,49,46,43,40,37,34,31,28,25,22,19,16,12,9,6,3
		dc.b 0,-3,-6,-9,-12,-16,-19,-22,-25,-28,-31,-34,-37,-40,-43,-46,-49,-51,-54,-57,-60,-63,-65,-68,-71,-73,-76,-78,-81,-83,-85,-88
		dc.b -90,-92,-94,-96,-98,-100,-102,-104,-106,-107,-109,-111,-112,-113,-115,-116,-117,-118,-120,-121,-122,-122,-123,-124,-125,-125,-126,-126,-126,-127,-127,-127
		dc.b -127,-127,-127,-127,-126,-126,-126,-125,-125,-124,-123,-122,-122,-121,-120,-118,-117,-116,-115,-113,-112,-111,-109,-107,-106,-104,-102,-100,-98,-96,-94,-92
		dc.b -90,-88,-85,-83,-81,-78,-76,-73,-71,-68,-65,-63,-60,-57,-54,-51,-49,-46,-43,-40,-37,-34,-31,-28,-25,-22,-19,-16,-12,-9,-6,-3

	endif

