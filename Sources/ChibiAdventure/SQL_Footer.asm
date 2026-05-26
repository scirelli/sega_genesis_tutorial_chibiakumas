
NewLine:
	clr.l d2			;Xpos =0
	addq.l #1,d5		;Ypos ++

	cmp.b #$17,d5		;Over bottom of the screen?
	bcc cls
	rts

Cls:
	moveM.l d1/d4/d3/d6,-(sp)
		clr.l d2		;Xpos
		clr.l d5		;Ypos
		
		move.b #$20,d3	;Char (Space)
		clr.b d6		;CharInc (0= all same character)
		
		move.b #$20,d1	;Width
		move.b #$19,d4	;Height
		jsr fillarea
	moveM.l (sp)+,d1/d4/d3/d6
	
SlowDown:				;this exists for systems that run too fast
	rts

	
QLJoycommand:
	dc.b $09	;0 - Command
	dc.b $01	;1 - parameter bytes
	dc.l 0		;2345 - send option (%00=low nibble)
	dc.b 1		;6 - Parameter: Row
	dc.b 2		;7 - length of reply (%10=8 bits)
	even
	
ReadJoystick:			;Returns %--21RLDU
	moveM.l d1/a3,-(sp)
		move.l #QLJoycommand,a3
		move.b #$11,d0	;Command 17
		Trap #1			;Send Keyrequest to the IO CPU
				
		move.b d1,d7
		roxr.b #1,d7	;Enter (1)
		roxl.b #1,d0	; Fire 2
		
		roxr.b #6,d7	;Space (7)
		roxl.b #1,d0	; Fire 1
		
		move.b d1,d7
		roxr.b #5,d7	;Right (5)
		roxl.b #1,d0
		
		move.b d1,d7
		roxr.b #2,d7	;Left (2)
		roxl.b #1,d0
		
		roxr.b #6,d7	;Down (8)
		roxl.b #1,d0
		
		move.b d1,d7
		roxr.b #3,d7	;Up   (3)
		roxl.b #1,d0
		
		eor.b #$FF,d0		;Flip Player 1 bits
	moveM.l (sp)+,d1/a3
	rts
	
	
PrintNumber:
	add.b #48,d0		;ascii 0
	
PrintChar:				;print char a with sprite routine
	tst.b d0
	beq printchar0

	clr.l d7
	move.b d0,d7
	sub.b #32,d7			;Font doesn't have chars below 32
	
	cmp.b #64,d7			;Lowercase?
	bcs notlowercase
		sub.b #32,d7		;convert to upper!
notlowercase:
	ifd NativeSpr_Multiplatform2Bitplane
		rol.l #4,d7				;16 bytes per character
	else 
		rol.l #5,d7				;32 bytes per character
	endif 
	move.l #FontData,a4
	add.l d7,a4				;A4=Bitmap source
	
;VRAM = $20000 + (YposInLines+32) *128 + XposInPixels/4	
	
	move.l #$00020000,a0	;Screen starts at $20000
	clr.l d7
	move.b d5,d7
	addq.l #4,d7			;Move Y down 32 lines to simulate
	rol.l #3,d7				; a 256*192 screen  
	rol.l #7,d7				;Multiply Y*128
	add.l d7,a0
			
	clr.l d7
	move.b d2,d7
	rol.l #2,d7				;Multiply X*2 (2 bytes per 4/8 pixels)
	add.l d7,a0
			
	ifd NativeSpr_Multiplatform2Bitplane
		;movem.l d3/d6,-(sp)
	
			move.l #8,d7
			
FontNextLine:
			ifd Font_AltPalette
				move.b (a4)+,d6		;Bitplane 0
				move.b (a4)+,d3		;Bitplane 1
			else 

				move.b (a4)+,d3		;Bitplane 0
				move.b (a4)+,d6		;Bitplane 1
			endif 
			
			clr.l d0
			roxl.b d3
			roxl.b d0
			roxl.b d6
			roxl.b d0
			roxl.b d3
			roxl.b d0
			roxl.b d6
			roxl.b d0
			roxl.b d3
			roxl.b d0
			roxl.b d6
			roxl.b d0
			roxl.b d3
			roxl.b d0
			roxl.b d6
			roxl.b d0
			move.b d0,(1,a0)
			ifnd Font_AltPalette
				rol.b #1,d0
			endif 
			and.b #%10101010,d0
			move.b d0,(0,a0)
			
			clr.l d0
			roxl.b d3
			roxl.b d0
			roxl.b d6
			roxl.b d0
			roxl.b d3
			roxl.b d0
			roxl.b d6
			roxl.b d0
			roxl.b d3
			roxl.b d0
			roxl.b d6
			roxl.b d0
			roxl.b d3
			roxl.b d0
			roxl.b d6
			roxl.b d0
			move.b d0,(3,a0)
			ifnd Font_AltPalette
				rol.b #1,d0
			endif 
			and.b #%10101010,d0
			move.b d0,(2,a0)
			
			add.l #128,a0
			subq.l #1,d7
			bne FontNextLine
			
			;movem.l (sp)+,d3/d6
		else 
			
		move.l (a4)+,(128*0,a0)	;Transfer 8 lines of our font
		move.l (a4)+,(128*1,a0)
		move.l (a4)+,(128*2,a0)
		move.l (a4)+,(128*3,a0)
		move.l (a4)+,(128*4,a0)
		move.l (a4)+,(128*5,a0)
		move.l (a4)+,(128*6,a0)
		move.l (a4),(128*7,a0)
	endif 
	
printchar0:
	addq.b #1,d2			;Xpos ++
	rts
	
	ifnd FontData
FontData:	;32 bytes per character	
	DC.L $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000     ;  0  - Ofst:&0
	DC.L $02030000,$020180C0,$02018040,$02018040,$02018040,$00000000,$00038040,$00000000     ;  1  - Ofst:&20
	DC.L $080C80C0,$281CA0D0,$08048040,$00000000,$00000000,$00000000,$00000000,$00000000     ;  2  - Ofst:&40
	DC.L $00000000,$080C80C0,$2A15A050,$08048040,$08378070,$000C00C0,$00000000,$00000000     ;  3  - Ofst:&60
	DC.L $020380C0,$0A0DA8DC,$20108040,$0A05A050,$02010804,$08378070,$000300C0,$00000000     ;  4  - Ofst:&80
	DC.L $0000080C,$A0D02010,$A0508040,$02010000,$08040000,$00300834,$00C0003C,$00000000     ;  5  - Ofst:&A0
	DC.L $02030000,$080C80C0,$08048040,$2A150804,$82412010,$80408070,$003F000C,$00000000     ;  6  - Ofst:&C0
	DC.L $0000A0F0,$0201A0D0,$0A050000,$00000000,$00000000,$00000000,$00000000,$00000000     ;  7  - Ofst:&E0
	DC.L $020380C0,$020180C0,$0A050000,$0A050000,$0A050000,$00038040,$000300C0,$00000000     ;  8  - Ofst:&100
	DC.L $020380C0,$020180C0,$0000A050,$0000A050,$0000A050,$00038040,$000300C0,$00000000     ;  9  - Ofst:&120
	DC.L $000080C0,$20308243,$08048844,$0201A050,$02012010,$08040804,$00300003,$00000000     ; 10  - Ofst:&140
	DC.L $00000000,$020180C0,$02018040,$2A15A854,$02018040,$00038040,$00000000,$00000000     ; 11  - Ofst:&160
	DC.L $00000000,$00000000,$00000000,$00000000,$00000000,$00038040,$000300C0,$000F0000     ; 12  - Ofst:&180
	DC.L $00000000,$00000000,$00000000,$2A15A854,$003F00FC,$00000000,$00000000,$00000000     ; 13  - Ofst:&1A0
	DC.L $00000000,$00000000,$00000000,$00000000,$00000000,$00038040,$000300C0,$00000000     ; 14  - Ofst:&1C0
	DC.L $0000080C,$00002010,$00008040,$02010000,$08040000,$00300000,$00C00000,$00000000     ; 15  - Ofst:&1E0
	DC.L $2A3FA0F0,$A0D0281C,$A2512814,$A2512814,$20D3201C,$00F0003C,$003F00F0,$00000000     ; 16  - Ofst:&200
	DC.L $02030000,$020180C0,$02018040,$02018040,$02018040,$00038040,$000000C0,$00000000     ; 17  - Ofst:&220
	DC.L $0A0FA0F0,$2A1DA8DC,$00002814,$0A05A050,$28140000,$08378874,$000F00F0,$00000000     ; 18  - Ofst:&240
	DC.L $0A0FA0F0,$2A1DA8DC,$00002814,$0201A050,$00002814,$08378874,$000F00F0,$00000000     ; 19  - Ofst:&260
	DC.L $020380C0,$0A0DA0D0,$28142010,$A050A050,$2A15A050,$00008070,$000000C0,$00000000     ; 20  - Ofst:&280
	DC.L $0A0FA0F0,$2A1DA8DC,$28140000,$2A15A050,$00002814,$08378874,$000F00FC,$00000000     ; 21  - Ofst:&2A0
	DC.L $0A0FA0F0,$2A1DA8DC,$28140000,$2A15A050,$28142814,$08340834,$000F00F0,$00000000     ; 22  - Ofst:&2C0
	DC.L $0A0FA0F0,$2A1DA8DC,$00002814,$0000A050,$02018040,$00038040,$00030000,$00000000     ; 23  - Ofst:&2E0
	DC.L $0A0FA0F0,$281C281C,$28142814,$0A05A050,$28142814,$08340834,$000F00F0,$00000000     ; 24  - Ofst:&300
	DC.L $0A0FA0F0,$281C281C,$28142814,$0A05A854,$00002814,$08378874,$000F00F0,$00000000     ; 25  - Ofst:&320
	DC.L $00000000,$00000000,$020380C0,$02018040,$00000000,$00038040,$000300C0,$00000000     ; 26  - Ofst:&340
	DC.L $00000000,$00000000,$020380C0,$02018040,$00000000,$00038040,$000300C0,$000F0000     ; 27  - Ofst:&360
	DC.L $0000A0F0,$0201A0D0,$0A058040,$28140000,$0A058040,$00038070,$000000F0,$00000000     ; 28  - Ofst:&380
	DC.L $00000000,$00000000,$2A1DA8DC,$00000000,$00000000,$08378874,$00000000,$00000000     ; 29  - Ofst:&3A0
	DC.L $283C0000,$2A1D0000,$0A058040,$0000A050,$0A058040,$08370000,$003C0000,$00000000     ; 30  - Ofst:&3C0
	DC.L $0A0FA0F0,$2A1D281C,$00002814,$0201A050,$00000000,$020100C0,$000300C0,$00000000     ; 31  - Ofst:&3E0
	DC.L $2A3FA0F0,$A0D0A85C,$88442814,$8A452814,$A050201C,$88770000,$003F00F0,$00000000     ; 32  - Ofst:&400
	DC.L $020380C0,$0A0DA0D0,$28142814,$28142814,$2A15A854,$08340834,$000C0030,$00000000     ; 33  - Ofst:&420
	DC.L $0A0FA0F0,$281C281C,$28142814,$2A15A050,$28142814,$08340834,$000F00F0,$00000000     ; 34  - Ofst:&440
	DC.L $0A0F80C0,$2A1DA0D0,$A0500000,$A0500000,$A0500000,$08378070,$000F00C0,$00000000     ; 35  - Ofst:&460
	DC.L $0A0FA0F0,$281C2010,$28142814,$28142814,$28142814,$08340030,$000F00C0,$00000000     ; 36  - Ofst:&480
	DC.L $0A0FA0F0,$2A1DA8DC,$28140000,$2A158040,$28140000,$08378874,$000F00F0,$00000000     ; 37  - Ofst:&4A0
	DC.L $0A0F80C0,$2A1DA0D0,$28140000,$2A158040,$28140000,$08340000,$000C0000,$00000000     ; 38  - Ofst:&4C0
	DC.L $0A0FA0F0,$281C281C,$A0500000,$A0500000,$A050A050,$08340834,$000F00F0,$00000000     ; 39  - Ofst:&4E0
	DC.L $080C2030,$281C281C,$28142814,$2A15A854,$28142814,$08340834,$000C0030,$00000000     ; 40  - Ofst:&500
	DC.L $02030000,$020180C0,$02018040,$02018040,$02018040,$00038040,$000000C0,$00000000     ; 41  - Ofst:&520
	DC.L $000080C0,$0000A0D0,$0000A050,$0000A050,$2010A050,$88778070,$003F00C0,$00000000     ; 42  - Ofst:&540
	DC.L $080C2030,$281C281C,$2814A050,$2A158040,$2814A050,$08340834,$000C0030,$00000000     ; 43  - Ofst:&560
	DC.L $080C0000,$281C0000,$28140000,$28140000,$28140000,$08378874,$000F00FC,$00000000     ; 44  - Ofst:&580
	DC.L $20302030,$A8DCA8DC,$AA55A854,$A2512814,$A2512814,$82710834,$00300030,$00000000     ; 45  - Ofst:&5A0
	DC.L $20302030,$A8DC281C,$AA552814,$A251A854,$A050A854,$80700834,$00300030,$00000000     ; 46  - Ofst:&5C0
	DC.L $0A0F80C0,$281CA0D0,$A0502814,$A0502814,$A0502814,$08348070,$000F00C0,$00000000     ; 47  - Ofst:&5E0
	DC.L $0A0F80C0,$281CA050,$28142010,$2A15A050,$28140000,$08340000,$000C0000,$00000000     ; 48  - Ofst:&600
	DC.L $0A0F80C0,$281CA0D0,$A0502814,$A0502814,$A0508844,$003F0030,$000F00CC,$00000000     ; 49  - Ofst:&620
	DC.L $0A0FA0F0,$281C281C,$28142814,$2A15A050,$2814A050,$08340834,$000C003C,$00000000     ; 50  - Ofst:&640
	DC.L $0A0FA0F0,$2A1DA85C,$28140000,$0A05A050,$00002814,$08378874,$000F00F0,$00000000     ; 51  - Ofst:&660
	DC.L $0A0FA0F0,$2A1DA8DC,$02018040,$02018040,$02018040,$00038040,$000000C0,$00000000     ; 52  - Ofst:&680
	DC.L $080C2030,$281C281C,$28142814,$28142814,$28142814,$08340834,$000F00F0,$00000000     ; 53  - Ofst:&6A0
	DC.L $080C2030,$281C281C,$28142814,$28142814,$28142814,$08078070,$000300C0,$00000000     ; 54  - Ofst:&6C0
	DC.L $20302030,$A0D0281C,$A2512814,$A2512814,$AA55A854,$20DC20DC,$00300030,$00000000     ; 55  - Ofst:&6E0
	DC.L $A0F0283C,$281CA0D0,$0A058040,$0A058040,$2814A050,$80700834,$00300030,$00000000     ; 56  - Ofst:&700
	DC.L $080C2030,$281C281C,$28142814,$0A05A050,$02018040,$00038040,$000000C0,$00000000     ; 57  - Ofst:&720
	DC.L $2A3FA0F0,$AADDA0D0,$0000A050,$02018040,$0A050000,$08378874,$003F00F0,$00000000     ; 58  - Ofst:&740
	DC.L $0203A0F0,$0A0D0000,$0A050000,$0A050000,$0A050000,$08070000,$000300F0,$00000000     ; 59  - Ofst:&760
	DC.L $80C00000,$20100000,$08040000,$02010000,$00008040,$00000030,$0000000C,$00000000     ; 60  - Ofst:&780
	DC.L $0A0F80C0,$0000A0D0,$0000A050,$0000A050,$0000A050,$00008070,$000F00C0,$00000000     ; 61  - Ofst:&7A0
	DC.L $020380C0,$0A0DA0D0,$2A15A854,$02018040,$02018040,$00038040,$000300C0,$00000000     ; 62  - Ofst:&7C0
	DC.L $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00FF00FF,$00FF00FF     ; 63  - Ofst:&7E0
	endif 

QlProg_End: