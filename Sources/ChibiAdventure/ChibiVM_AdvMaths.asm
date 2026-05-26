;Extended functions to improve the Adventure Engine, and reduce
; CPU load from ChibiVM

syscallMaths equ 15

mMul equ 0+regNO
mDiv equ 1+regNO
mMulByte equ 2+regNO
mDivByte equ 3+regNO
mMulByte8 equ 4+regNO
mDivByte8 equ 5+regNO
mFraction16 equ 6+regNO
mMulByteSigned equ 7+regNO
mNegateR6 equ 8+regNO

	ifd BCD_Show
mBCDShow equ 9+regNO 		;9 Show B bytes of HL
mBCDSub equ 10+regNO	;10 DE=DE-HL (B bytes)
mBCDAdd equ 11+regNO		;11 DE=DE+HL (B bytes)
mBCDCp equ 12+regNO			;12 DE=DE CP HL (B bytes)
mBinary2BCD equ 13	;13 32 bit DEB-> BCD (HL) A=bytecount
mBCD2Binary equ 14	;14 BCD (HL) -> 32 bit DEB A=bytecount
	endif 
	

	ifd MathLsr32
mLsr32 equ 15
mLsl32 equ 16
mAdd32 equ 17		;11 R6.R4=R6.R4+R2.R0
mSub32 equ 18		;12 R6.R4=R6.R4-R2.R0

mMul32 equ 19		;R6.R4=R6*R4
mDiv32 equ 20		;R6.R4=R6.R4/R2 (R2=Remainder)
mMul32Byte equ 21		;R6.R4=R6*R0 byte
mDiv32Byte equ 22		;R6.R4=R6.R4/R0 byte (R0=Remainder)
mMul32_Sgn equ 23		;R6.R4=R6*R4 (Signed)
mMul32Byte_Sgn equ 24	;R6.R4=R6*R0 byte (Signed)
mNegage32 equ 25		;R6.R4= -R6.R4

	endif 

AdvMathsCall:
	dc.l MathMul			;0 R6=R6*R0
	dc.l MathDiv			;1 R6=R6/R0 R0=Remainder
	dc.l MathMulByte		;2 R0.R1=R0*R1
	dc.l MathDivByte		;3 R0.R1=R0/R1
	dc.l MathMulByte8		;4 R0=R0*R1
	dc.l MathDivByte8		;5 R0=R0/R1
	dc.l MathFraction16	;6 (R6/16) *R0		(Was called Fraction32)
	dc.l MathMulByte_Sgn	;7 R0.R1=R0*R1(signed) (Gives 16 bit result)
	dc.l MathNegateHL		;8 R6=-R6
	
	ifd BCD_Show
		dc.l MathBCDShow	;9  R6=BCD sequence R0=Bytes to show
		dc.l MathBCDSub	;10 R4=R4-R6 (R0 bytes)
		dc.l MathBCDAdd	;11 R4=R4+R6 (R0 bytes)
		dc.l MathBCDCp	;12 R4=R4 CP R6 (R0 bytes)
		dc.l Binary2BCD	;13 32 bit DEB-> BCD (HL) A=bytecount
		dc.l BCD2Binary	;14 BCD (HL) -> 32 bit DEB A=bytecount
	else 
		dc.l Math_Ret		;9
		dc.l Math_Ret		;10
		dc.l Math_Ret		;11
		dc.l Math_Ret		;12
		dc.l Math_Ret		;13
		dc.l Math_Ret		;14
	endif 
	
	
	ifd MathLsr32
		dc.l MathLsr32		;15 R6.R4>>R0
		dc.l MathLsl32		;16 R6.R4<<R0
		dc.l MathAdd32		;17 R6.R4=R6.R4+R2.R0
		dc.l MathSub32		;18 R6.R4=R6.R4-R2.R0
		
		dc.l MathMul32		;19 R6.R4=R6*R4
		dc.l MathDiv32		;20 R6.R4=R6.R4/R2 (R2=Remainder)
		dc.l MathMul32Byte	;21 R6.R4=R6*R0 byte
		dc.l MathDiv32Byte	;22 R6.R4=R6.R4/R0 byte (R0=Remainder)
		dc.l MathMul32_Sgn	;23 R6.R4=R6*R4 (Signed)
		dc.l MathMul32Byte_Sgn;24 R6.R4=R6*R0 byte (Signed)
		dc.l MathNegage32		;25 R6.R4= -R6.R4

	endif 
AdvMaths_Call:	
	;ld hl,AdvMathsCall
	;jp DoVectorCall
	move.l #AdvMathsCall,a6
	jmp ChibiVM_VectorCall
	
MathMul:

	move.l (VM_RamBaseAddr),a0
	clr.l d6
	move.b (VM_rR7,a0),d6
	lsl.l #8,d6
	move.b (VM_rR6,a0),d6
	
	
	;ld hl,(VM_RamBase+6)
MathMulB:

	move.l (VM_RamBaseAddr),a0
	clr.l d0
	move.b (VM_rR0,a0),d0

	;ld a,(VM_RamBase+0)
	jsr Mul8 ;This routine performs the operation HL=HL*A
	;ld (VM_RamBase+6),hl
	;ret
	move.l #$66660006,d7
	move.l (VM_RamBaseAddr),a0
	
	move.b d6,(VM_rR6,a0)
	lsr.l #8,d6		;ld a,h 	;ld (VM_RamBase+0),a
	move.b d6,(VM_rR7,a0)
	rts


MathMulByte_Sgn:		;R0.R1=R0*R1(signed) (Gives 16 bit result)

	move.l (VM_RamBaseAddr),a0
	clr.l d6
	move.b (VM_rR0,a0),d6
	
	

	;ld a,(VM_RamBase+0)		
	;ld l,a
	;ld h,0
	
	
	clr.l d0
	move.b (VM_rR0,a0),d0
	
	btst #7,d0
	
	;ld a,(VM_RamBase+1)
	;bit 7,a
	beq MathMulByte_Sgnb
	neg.l d0
MathMulByte_Sgnb:
	jsr Mul8
MathNegateHL:
	neg d6

	;ld a,h
	;cpl
	;ld h,a
	;ld a,l
	;cpl
	;ld l,a
	;inc hl
Math_Ret:

	move.l #$66660006,d7
	move.l (VM_RamBaseAddr),a0
	
	move.b d6,(VM_rR6,a0)
	lsr.l #8,d6		;ld a,h 	;ld (VM_RamBase+0),a
	move.b d6,(VM_rR7,a0)
	
	rts	
	


	
MathFraction16:		;(HL/16) *A		(Was called Fraction32)
	;ld hl,(VM_RamBase+6)
	;ld a,16
	move.l #16,d0
	jsr Div8
	bra MathMulB

		
	
	
MathDiv:
	move.l (VM_RamBaseAddr),a0
	clr.l d6
	move.b (VM_rR7,a0),d6
	lsl.l #8,d6
	move.b (VM_rR6,a0),d6
	

	;ld a,(VM_RamBase+0)
	;ld hl,(VM_RamBase+6)
	jsr Div8 ;HL=Source	A=Divider (HL=HL/A A=Remainder)
	;ld (VM_RamBase+6),hl
	;ld (VM_RamBase+0),a
	;ret
	
	move.l #$66660006,d7
	move.l (VM_RamBaseAddr),a0
	
	move.b d6,(VM_rR6,a0)
	lsr.l #8,d6		;ld a,h 	;ld (VM_RamBase+0),a
	move.b d6,(VM_rR7,a0)
	
	move.b d0,(VM_rR0,a0)
	rts
	

MathDivByte:				;R0.R1=R0/R1 (Gives fractional result)
	jsr Div8byte ;HL=Source	A=Divider (HL=HL/A A=Remainder)
	;ld (VM_RamBase+0),hl
	
	
	move.l #$66660006,d7
	move.l (VM_RamBaseAddr),a0
	
	move.b d6,(VM_rR6,a0)
	lsr.l #8,d6		;ld a,h 	;ld (VM_RamBase+0),a
	move.b d6,(VM_rR7,a0)
	
	rts

	
MathMulByte:
	jsr Mul8byte
	;call Mul8 ;This routine performs the operation HL=HL*A
	;ld (VM_RamBase+0),hl
	
	move.l #$66660006,d7
	move.l (VM_RamBaseAddr),a0
	
	move.b d6,(VM_rR6,a0)
	lsr.l #8,d6		;ld a,h 	;ld (VM_RamBase+0),a
	move.b d6,(VM_rR7,a0)
	rts	
	
MathMulByte8:
	jsr Mul8byte ;This routine performs the operation HL=HL*A
	
	move.l #$66660006,d7
	move.l (VM_RamBaseAddr),a0
	
	lsr.l #8,d6		;ld a,h 	;ld (VM_RamBase+0),a
	move.b d6,(VM_rR0,a0)
	rts
	
	;ld a,l
	;ld (VM_RamBase+0),a
	;ret	

MathDivByte8:				;R0.R1=R0/R1 (Gives fractional result)
	jsr Div8byte ;HL=Source	A=Divider (HL=HL/A A=Remainder)
	
	
	move.l #$66660006,d7
	move.l (VM_RamBaseAddr),a0
	
	lsr.l #8,d6		;ld a,h 	;ld (VM_RamBase+0),a
	move.b d6,(VM_rR0,a0)
	rts

	
	ifnd Div8
Div8Byte:
	move.l (VM_RamBaseAddr),a0
	clr.l d6
	move.b (VM_rR0,a0),d6
	lsl.l #8,d6
	

	;ld a,(VM_RamBase+0)
	;ld h,a
	;ld l,0
	
	;ld a,(VM_RamBase+1)		
	clr.l d0
	move.b (VM_rR1,a0),d0
	

Div8:	;HL=Source	A=Divider (HL=HL/A A=Remainder)
	and.l #$000000FF,d0
Div16:
	cmp.b #0,d0
	beq DivInfinite
	divu.w d0,d6
	and.l #$0000FFFF,d6
    rts

DivInfinite:
	move.l #$FFFF,d6
	rts
	
	endif 
	
	ifnd Mul8	
Mul8byte:
	move.l (VM_RamBaseAddr),a0
	clr.l d0
	move.b (VM_rR0,a0),d0
	
	clr.l d6
	move.b (VM_rR6,a0),d6
	
	;ld a,(VM_RamBase+0)		;R0.R1=R0*R1 (Gives 16 bit result)
	;ld l,a
	;ld h,0
	;ld a,(VM_RamBase+1)	
		
	
	
Mul8:  	;This routine performs the operation HL=HL*A
	and.l #$000000FF,d0

	mulu.w d0,d6
	and.l #$0000FFFF,d6
	rts
	
	endif 
