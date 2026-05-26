FileZero:

;Set up our screen

	;		 FEDCBA9876543210	
	move.w #%0000000000000000,$e80028 ;R20 Memory mode/Display mode control
	move.w #%0000000000000000,$e82400 ;R0 (Screen mode initialization) - Detail
	;		 --SSTTGG44332211
	move.w #%0000001011100100,$e82500 ;R1 (Priority control) - Priority
	;		 FEDCBA9876543210
	;				 BST43210 (0-3 = Layers 4=1024 screen T=Text S=Sprite B=Border)
	move.w #%0000000011000001,$e82600 ;R2 (Special priority/screen display) - Screen On - sprites on
	
	move.w #$025,$E80000 	;R00 Horizontal total 
	move.w #$001,$E80002	;R01 Horizontal synchronization end position timing
	move.w #$000,$E80004	;R02 Horizontal display start position
	move.w #$020,$E80006	;R03 Horizontal display end position
	move.w #$103,$E80008	;R04 Vertical total 
	move.w #$002,$E8000A	;R05 Vertical synchronization end position timing
	move.w #$010,$E8000C	;R06 Vertical display start position
	move.w #$100,$E8000E	;R07 Vertical display end position
	move.w #$024,$E80010	;R08 External synchronization horizontal adjust: Horizontal position tuning
	
;Sprite settings 

	;move.w #$25,$EB080A		; Sprite H Total
	;move.w #$04,$EB080C		; Sprite H Disp
	;move.w #$10,$EB080E		; Sprite V Disp
	;move.w #$00,$EB0810		; Sprite Res %---FVVHH

;Define our palette 

	ifd X68_UsePalette
		move.l #$e82000,a1
		move.l #X68_Palette,a0
		move.l #16-1,d0
DefinePalette:		
		move.w (a0)+,(a1)+
		dbra d0,DefinePalette
		
	else 
				;GGGGGRRRRRBBBBB- 5 bit per channel
		move.w #%0000000000000000,$e82000	;Color 0
		move.w #%0000001110011100,$e82002	;Color 1
		move.w #%1111100000111110,$e82004	;Color 2
		move.w #%1111111111111110,$e82006	;Color 3
	endif 
	
	jsr ClearRam			;Clear first 256 bytes of ram, and CLS
	
	
	
