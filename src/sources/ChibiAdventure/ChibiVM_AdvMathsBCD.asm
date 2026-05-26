;BCD is in packed Little endian format

;Decimal values for conversions between 32 bit and 8-10 char BCD
BCDLast:	
	dc.b $00,$CA,$9A,$3B		;10 0000 0000  - Max Value 42 9496 7295
	dc.b $00,$E1,$F5,$05		;01 0000 0000 
	dc.b $80,$96,$98,$00		;1000 0000	- 8 digits
	dc.b $40,$42,$0F,$00		;0100 0000
	dc.b $A0,$86,$01,$00		;0010 0000
	dc.b $10,$27,$00,$00		;0000 1000
	dc.b $E8,$03,$00,$00		;0000 1000
	dc.b $64,$00,$00,$00		;0000 0100
	dc.b $0A,$00,$00,$00		;0000 0010
	dc.b $01,$00,$00,$00		;0000 0001
BCDFirst:	

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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Binary2BCD:			;32 bit DEB-> BCD (HL) A=bytecount
                                           
	jsr getbcdlookupa
;                                     binary2bcd_again:
binary2bcd_again:
	movem.l d0,-(sp)
		jsr bcddivdigit
		lsl.b #4,d0
		move.b d0,(a3)

		jsr bcddivdigit
		or.b d0,(a3)
		subq.l #1,a3

	movem.l (sp)+,d0
	subq.l #1,d0
	bne binary2bcd_again
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;s7 r7  IX       A5
;t7 r8  IY       A6

BCDDivDigit:		;Add low BCD nibble A / IX(A5) 32bit value


;                                         xor a            ;a=this digit
	clr.l d0
;                                     bcddivdigit_again:
bcddivdigit_again:
;                                         push af       
	;movem.l d0,-(sp)
	
		movem.l d1/d4/d2/d5,-(sp) ;backup current result in debc
			andi  #%00001111,CCR	; Clear extend
			move.b (0,a5),d7
			sbcd.b d7,d4		  ;try to subtract (ix) from debc
			
			move.b (1,a5),d7
			sbcd.b d7,d1		  ;try to subtract (ix) from debc
			
			move.b (2,a5),d7
			sbcd.b d7,d5		  ;try to subtract (ix) from debc
			
			move.b (3,a5),d7
			sbcd.b d7,d2		  ;try to subtract (ix) from debc
			bcs bcddivdigitfail    ;overflow?

		add.l #4*4,sp	   ;divide ok, so remove backup
	;movem.l (sp)+,d0
			
	addq.l #1,d0
	bra bcddivdigit_again

bcddivdigitfail:
		movem.l (sp)+,d1/d4/d2/d5     ;divide failed, so restore backup
	;movem.l (sp)+,d0
	
	addq.l #4,a5	;inc ix
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BCD2Binary:			; BCD (HL) -> 32 bit DEB A=bytecount
	jsr getbcdlookupa
	clr.l d1   ;debc = result
	clr.l d4
	clr.l d2
	clr.l d5
	
bcd2binary_again:
	movem.l d0,-(sp)
	
		move.b (a3),d0
		jsr bcdmultdigit

		move.b (a3),d0
		lsr.b #4,d0
		jsr bcdmultdigit

		addq.l #1,a3
	movem.l (sp)+,d0
	subq.l #1,d0
	bne bcd2binary_again
	rts
	
GetBCDLookupA:
	move.l #bcdfirst,a5
	movem.l d0,-(sp)
		lsl.b #2,d0		;*4
		and.l #$FF,d0
		sub.l d0,a5
		
bcd2binaryb:
	movem.l (sp)+,d0
    lsr.b #1,d0   ;we work in pairs of bytes
	rts
;                                     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
BCDMultDigit:			;Add low BCD nibble A * IX 32bit value
	and.l #%00001111,d0
;                                     bcdmultdigitb:
bcdmultdigitb:
	beq bcdmultdigitdone

	;movem.l d0,-(sp)
		andi  #%00001111,CCR	; Clear extend
		
		move.b (0,a5),d7
       	abcd.b d7,d4     ;ix=bcd <> 32 bit conversion table 
		
		move.b (1,a5),d7
		abcd.b d7,d1
		
		move.b (2,a5),d7
		abcd.b d7,d5
		
		move.b (3,a5),d7
		abcd.b d7,d2
	;movem.l (sp)+,d0
	subq.b #1,d0
	bra bcdmultdigitb
;                                     bcdmultdigitdone:
bcdmultdigitdone:
    add.l #4,a6 ;inc ix

	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MathBCDShow:		;R6=BCD sequence R0=Bytes to show
	;ld hl,(VM_RamBase+6)
	;ld de,(VM_RamBase+4)		;XYpos for draw
	;ld a,(VM_RamBase+0)
	move.b d0,d1 ;ld b,a
	
	
	
	

BCD_Show:	;Show B bytes of HL
	jsr bcd_getendhl
bcd_show_direct:
	move.b (a3),d0
	and.b #%11110000,d0    ;use the high nibble
	lsr.b #4,d0
	jsr printnumber

	move.b (a3),d0
	subq.l #1,a3
	and.b #%00001111,d0    ;now the low nibble
	jsr printnumber
	
	subq.b #1,d1
	bne bcd_show_direct    ;next byte
	;nop
;                                         

;                                         ld (vm_rambase+4),de    
	;move.w a2,(vm_rambase+4)    ;xypos for draw
	
	move.l #$66660006,d7
	move.l (VM_RamBaseAddr),a0
	
	move.b d5,(VM_rR4,a0)
	move.b d2,(VM_rR5,a0)
	
;                                         ret
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MathBCDSub:		; R4=Dest R6=BCD sequence R0=Bytes to sub
	;ld hl,(VM_RamBase+6)
	;ld de,(VM_RamBase+4)
	;ld a,(VM_RamBase+0)
	
	clr.l d1
	move.b d0,d1 ;ld b,a
	subq.l #1,d1
BCD_Subtract:	;DE=DE-HL (B bytes)

;                                         or a        ;clear carry
	;nop
;                                     bcd_subtract_again:


	;ANDI #%11111110,CCR
	andi  #%00001111,CCR	; Clear extend
bcd_subtract_again:
	move.b (a3)+,d0
	move.b (a2),d7
	SBCD d0,d7  ;subtract hl from de with carry
	move.b d7,(a2)+

	dbra d1,bcd_subtract_again
	
	bra bcd_setflags     ;should return any carry from sbc
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MathBCDAdd:		; R4=Dest R6=BCD sequence R0=Bytes to add
	;ld hl,(VM_RamBase+6)
	;ld de,(VM_RamBase+4)
	;ld a,(VM_RamBase+0)
	
	clr.l d1
	move.b d0,d1 ;ld b,a
	subq.l #1,d1
	
BCD_Add:	;DE=DE+HL (B bytes)
	
	;ANDI #%11111110,CCR
	andi  #%00001111,CCR	; Clear extend
	
BCD_Add_Again:
	move.b (a3)+,d0
	move.b (a2),d7
	ABCD d0,d7  
	move.b d7,(a2)+
	
	dbra d1,BCD_Add_Again
	;ret
	jmp BCD_SetFlags

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MathBCDCp:		; R4=Dest R6=BCD sequence R0=Bytes to compare
	;ld hl,(VM_RamBase+6)
	;ld de,(VM_RamBase+4)
	;ld a,(VM_RamBase+0)
	
	clr.l d1
	move.b d0,d1 ;ld b,a
	subq.l #1,d1
	
	
BCD_Cp:		;DE=DE CP HL (B bytes)
	jsr BCD_GetEndHLDE
BCD_Cp_Direct:		;Start from MSB
	move.b (a2),d0
	move.b (a3),d7
	SBCD d7,d0 ;ld a,(de)
	;cp (hl)
	
	bcs BCD_SetFlags3 ;ret c		;Smaller
	bne BCD_SetFlags3 ;ret nz		;Greater
	subq.l #1,a2; dec de		;equal... move onto next Byte
	subq.l #1,a3 ;dec hl
	dbra d1,BCD_Cp_Direct
	ANDI #%11111110,CCR ;or a ;CCF
	;ret
	
	
;VM_fCarry equ  %00000001
BCD_SetFlags:
	jsr GetCCR				;D7=Flags
	move.l (VM_RamBaseAddr),a0
	bclr.b #0,(vm_rf,a0)
	btst #4,d7		;X flag
	;move d7,ccr
	beq BCD_SetFlags2
	bset #0,(vm_rf,a0)		;-C
	
BCD_SetFlags2:
	move.l (VM_RamBaseAddr),a0
	bclr.b #1,(vm_rf,a0)
	move d7,ccr
	bne BCD_SetFlags3
	bset #1,(vm_rf,a0)		;Z-
BCD_SetFlags3:	

	move.l #$66660006,d7
	rts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BCD_GetEndHL:	;D6=D6+D1
	clr.l d7
	move.b d1,d7
	subq.l #1,d7
	
	add.l d7,a3
	rts

	; push bc
		; ld c,b	;We want to add BC, but we need to add one less than the number of bytes
		; dec c
		; ld b,0
		; add hl,bc
	; pop bc
	; ret 
	
BCD_GetEndHLDE:	
;Some of our commands need to start from the most significant byte
;This will shift HL and DE along b bytes
	clr.l d7
	move.b d1,d7
	subq.l #1,d7
	
	add.l d7,a3
	add.l d7,a2
	rts
	; push bc
		; ld c,b	;We want to add BC, but we need to add one less than the number of bytes
		; dec c
		; ld b,0
		; add hl,bc
		; z_ex_dehl	;We've done HL, but we also want to do DE

		; add hl,bc
		; z_ex_dehl
	; pop bc
	;ret