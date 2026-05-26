	ifnd OSK_NoDefaults
OSK_UsePhysical equ 1		;Use physical with OSK (Don't use with keyboardless!)

;OSK_Disable equ 1			;Only use physical
;OSK_DontUsePhysical equ 1

;OSK_HiglightCursor allows full width OSK with 10 bit font

;OSK_HalfWidth equ 1			;8 x 8  /  16 x 4
	
	ifd OSK_HiglightCursor
		ifnd BuildSGG
OSK_Xpos equ 4
OSK_Ypos equ 15
		else 
OSK_Xpos equ 0
OSK_Ypos equ 10
		endif 
	
	else

	ifnd OSK_HalfWidth
OSK_Xpos equ 0
OSK_Ypos equ 20
		else 
OSK_Xpos equ 2
OSK_Ypos equ 10
		endif 
	endif 

KeyChar_Enter equ '_'	
KeyChar_Backspace equ '_'-1

;Fire1=Select key - other fires can be remapped 
	ifnd OSK_UsePhysical
OSK_Fire2 equ ' '
OSK_Fire3 equ KeyChar_Enter
OSK_Fire4 equ KeyChar_Backspace
	endif 


	ifd BuildSMS
OSK_DontUsePhysical equ 1	
	endif 
	ifd BuildSGG
OSK_DontUsePhysical equ 1	
	endif 
	ifd BuildGMB
OSK_DontUsePhysical equ 1	
	endif 
	
	endif 

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

;IXH=A6
;IXL=A5
	

  ;D2 D5=draw position / returns D0=char
getchar:
	move.l #' ',d0
;                                         push de
	pushde
		ifd osk_disable
			jsr keyboard_waitforkey
		else
			jsr showosk
		endif
		movem.l d0,-(sp)
			jsr hideosk
		movem.l (sp)+,d0
	popde
	rts


;D0=char / D4=charlimit  D1=start charpos (for del)
;D2/D5=xypos A3=string

getstring:
	and.l #$000000FF,d1
	and.l #$000000FF,d2
	add.l d1,d2		;Xpos

	add.l d1,a3		;Addr
	
	pushhl
	
		ifd osk_disable
			jsr keyboard_waitforkey
        else
			jsr showosk
		endif

getcharloop:
		cmp.b #'_',d0
		beq getcharloopdone     ;enter pressed?

		movem.l d0,-(sp)
;                                             push de
			pushde
				and #%00111111,d5	; ;clear flags of ypos
				;res 7,e 				res 6,e

				cmp.b #'_'-1,d0
				beq getcharloop_del  ;del pressed?

;                                                 ifd font10bit_coloroff
				ifd font10bit_coloroff

					move.w #$0001,d7   ;on/off (Little endian)
					move.w d7,(font10bit_coloroff)
				endif

				move.b d0,(a3)+

				jsr printchar      ;show this char
				jsr waitforrelease   ;wait for keyup

			popde
			
			cmp.b d4,d1       ;max char
			beq getcharoverlimit
			
			addq.l #1,d2      ;xpos
			addq.l #1,d1        ;charcount
getcharlooprepeatb:
;                                             pop af
		movem.l (sp)+,d0
        ifd osk_usephysical
        ifnd osk_dontusephysical
			move.l #'_',d0      ;if we have a physical keyvoard switch to _
		endif
		endif
;                                             

		ifd osk_disable
			jsr keyboard_waitforkey
        else
			jsr showosk_again
		endif
		jmp getcharloop

getcharloopdone:
		move.b #255,(a3)        ;end entered string with 255


		ifnd osk_disable
			jsr hideosk
		endif
	pophl
	rts

getcharloop_del:
		tst.b d1
		beq getcharlooprepeat   ;deleted all chars?

		
		subq.l #1,d2  ;xpos
		subq.l #1,d1      ;charcount
		subq.l #1,a3
		ifd font10bit_coloroff
			pushbc
				move.l #$0001,a1     ;on/off
				move.w a1,(font10bit_coloroff)
			popbc
		endif
		move.b #' ',d0
		jsr printchar       ;delete cursor
		jsr printchar   ;delete removed char
		jsr waitforrelease
	popde
	subq.l #1,d2     ;xpos--
	bra getcharlooprepeatb

getcharlooprepeat:
	popde
	bra getcharlooprepeatb

getcharoverlimit:
	subq.l #1,a3
	bra getcharlooprepeatb

	ifnd OSK_Disable
hideosk:
		ifd osk_higlightcursor
			move.b #$10,d1
			move.b #$04,d4
		else
			ifd osk_halfwidth
				move.b #$10,d1
				move.b #$08,d4
			else
				move.b #$20,d1
				move.b #$04,d4
			endif
		endif

		move.b #$20,d3
		clr.l d6
		move.b #osk_xpos,d2
		move.b #osk_ypos,d5
		jmp fillarea
	endif
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	
showosk_again:  ;dont redraw the osk
	pushbc
	pushde
		move.l d2,a5		;IXH=A5
		move.l d5,a6		;IXL=A6
		;pushde
		;popix
		
		
		
		pushhl
			move.b d0,d3
			jmp printcharloop

showosk:

	
	
			pushbc

				ifd font10bit_coloroff
					move.w #$0001,d7
					move.w d7,(font10bit_coloroff)
				endif
				pushde
					move.l d2,a5		;IXH=A5
					move.l d5,a6		;IXL=A6
					;pushde
					;popix
					
					
					pushhl

						move.b d0,d3
						
						move.l a6,d0	;IXL
						btst #7,d0    ;no osk 
						bne printgridskip
						pushhl
							move.l #osk_ypos,d5

							move.l #' ',d1      ;char 
;                                         printgridloopy:
printgridloopy:
							ifnd osk_higlightcursor
								move.l #1+osk_xpos,d2
							else
								move.l #osk_xpos,d2
							endif
printgridloopx:
							move.b d1,d0
							
							movem.l a5/a6,-(sp)
								jsr printchar    ;show char
							movem.l (sp)+,a5/a6
   
							addq.l #1,d1       ;next char
							ifnd osk_higlightcursor
								addq.l #1,d2      ;skip 1 char
							endif

							move.b d2,d0
							ifnd osk_higlightcursor
								ifd osk_halfwidth
									cmp.b #16+osk_xpos,d0 ;at end of line
								else
									cmp.b #32+osk_xpos,d0
								endif
							else
								ifd osk_halfwidth
									cmp.b #8+osk_xpos,d0    ;at end of line
								else
									cmp.b #16+osk_xpos,d0
								endif
							endif
							bcs printgridloopx
							addq.l #1,d5           ;down a line 

							ifd osk_halfwidth
								move.l #osk_ypos+8,d0
							else
								move.l #osk_ypos+4,d0
							endif

							cmp.b d5,d0    ;at end of screen
							bne printgridloopy
						pophl
printgridskip:

printcharloop:
						clr.l d6
						movem.l a5/a6,-(sp)
							jsr readjoystick       ;get joysick
						movem.l (sp)+,a5/a6

						move.b d0,d4

						move.b d6,d0
						jsr joyaxis       ;char = ud * 8/16

					move.b d0,d6
					move.b d3,d0
					jsr joyaxis     ;char += lr *1

					
					move.b d0,d3
					move.b d6,d0
					
					and.l #$000000FF,d0
					lsl.b #3,d0

					ifnd osk_halfwidth
						lsl.b #1,d0
					endif

					add.b d3,d0       ;add new offset to char selected

				ifnd osk_dontusephysical
				ifd osk_usephysical
					move.b d0,d3
					jsr keyboard_getkey  ;get physical key
					beq gotnophysical

					cmp.b #64+32,d0     ;lowercase?

					bcs key_notlowercase
					sub.b #32,d0        ;convert to upper!

key_notlowercase:
					move.b d0,d3

					jsr keyboard_waitforrelease
					clr.l d4    ;clear joypad fire
gotnophysical:
					move.b d3,d0
				endif
				endif
				
				
				cmp.b #' ',d0
				bcc printchar_ok1
				move.b #' ',d0 ;don't allow <' '
printchar_ok1:

				cmp.b #'_',d0
				bcs printchar_ok2

				move.b #'_',d0         ;don't allow >'_'
printchar_ok2:

				ifd osk_fire2 ;joyfires can be mapped to keys
					btst #1,d4	;bit 1,c
					bne key_nofire2

					move.b #osk_fire2,d0
key_nofire2:
				endif

				ifd osk_fire3
					btst #2,d4	;bit 2,c
					bne key_nofire3
					move.b #osk_fire3,d0
key_nofire3:
				endif
				ifd osk_fire4
					btst #3,d4	;bit 3,c
					bne key_nofire4
					move.b #osk_fire4,d0
key_nofire4:
				endif

				
				
				move.b d0,d3        ;selected char

				btst #0,d4 ;bit 0,c        ;fire pressed 
				beq showosk_done      ;char selected

				move.l A6,d0;IXL=A6  ;flagged to show chars?
				btst #6,d0
				bne nokeyshowselected
				

				
				and.l #%00111111,d0   ;clear flag bits of ypos
				move.b d0,d5

				move.l A5,d2	;IXH=A5
				move.b d3,d0
				
				movem.l a5/a6,-(sp)
					jsr printchar     ;show selected char
				movem.l (sp)+,a5/a6
nokeyshowselected:

				move.l a6,d0;IXL=A6         ;flagged to show osk?
				btst #7,d0
				bne nokeypadloop
	
				move.b d3,d0
				
				sub.b #' ',d0
				move.b d0,d5
				ifd osk_halfwidth
					and.l #%00000111,d0
				else
					and.l #%00001111,d0
				endif
				ifnd osk_higlightcursor
					asl.b #1,d0
				endif

				add.b #osk_xpos,d0
				move.b d0,d2     ;calculate osx cursor xpos


				clr.l d0
				move.b d5,d0
				ifnd osk_halfwidth
					lsr.b #1,d0
            	endif

				lsr.b #3,d0
				add.b #osk_ypos,d0
				move.b d0,d5         ;calculate osx cursor ypos

				ifd osk_higlightcursor
					pushde
						move.w #$0100,d7    ;on/off
						move.w d7,(font10bit_coloroff)
						move.b d3,d0    ;show cursor
						jsr printchar

						jsr pause50     ;wait
					popde
					move.l #$0001,d7     ;on/off
					move.w d7,(font10bit_coloroff)

					move.b d3,d0
					jsr printchar      ;show cursor
				else
					movem.l a5/a6,-(sp)
						pushde
							move.b #'>',d0
							jsr printchar     ;show cursor
							jsr pause50
						popde
						move.b #' ',d0
						jsr printchar        ;clear cursor
					movem.l (sp)+,a5/a6
				endif
				jmp printcharloop
;                                     nokeypadloop:    
nokeypadloop:
				jsr pause50
				jmp printcharloop
showosk_done:
			pophl
		popde
	popbc
	rts

keyboard_waitforrelease:
	jsr keyboard_getkey       ;key pressed?
	bne keyboard_waitforrelease ;yes! repeat
	rts
;                                         

;                                     keyboard_waitforkey:
keyboard_waitforkey:
	jsr keyboard_getkey
	beq keyboard_waitforkey   ;wait for a keypress 
	movem.l d0,-(sp)
		jsr keyboard_waitforrelease ;wait for a key release
	movem.l (sp)+,d0
	rts

    ifd buildcpc
;                                             include "srccpc/cpc_v2_keyboard.asm"
        include "srccpc/cpc_v2_keyboard.asm"
;                                         endif 
	endif
;                                         ifd buildzxs
    ifd buildzxs
;                                             include "srczx/zx_v2_keyboard.asm"
        include "srczx/zx_v2_keyboard.asm"
;                                         endif 
	endif
;                                         ifd buildsam
    ifd buildsam
;                                             include "srcsam/sam_v2_keyboard.asm"
        include "srcsam/sam_v2_keyboard.asm"
;                                         endif 
	endif
;                                         ifd buildti8
    ifd buildti8
;                                             include "srcti/ti_v2_keyboard.asm"
        include "srcti/ti_v2_keyboard.asm"
;                                         endif
	endif
;                                         ifd buildmsx
    ifd buildmsx
;                                             include "srcmsx/msx_v2_keyboard.asm"
        include "srcmsx/msx_v2_keyboard.asm"
;                                         endif
	endif
;                                         ifd buildent
    ifd buildent
;                                             include "srcent/ent_v2_keyboard.asm"
        include "srcent/ent_v2_keyboard.asm"
;                                         endif
	endif
;                                         ifd buildclx
    ifd buildclx
;                                             include "srcclx/clx_v2_keyboard.asm"
        include "srcclx/clx_v2_keyboard.asm"
;                                         endif
	endif
;                                         

;                                         

;                                         ifnd keyboard_getkey
    ifnd keyboard_getkey
;                                     keyboard_getkey:
keyboard_getkey:
		pushbc
			pushhl
				jsr readjoystick
				move.l #joystick_hardwarekeymap,a3
				move.l #8,d1
;                                     keyboard_getkey_again:
keyboard_getkey_again:
;                                             rrca 
				ror #1,d0
				bcs keyboard_getkey_nopress
;                                             ld a,(hl)
				move.b (a3),d0
;                                             jr keyboard_getkey_found
				bra keyboard_getkey_found
;                                     keyboard_getkey_nopress:
keyboard_getkey_nopress:
;                                             inc hl
				addq.l #1,a3
;                                             djnz keyboard_getkey_again
				subq.b #1,d1
				bne keyboard_getkey_again
;                                             xor a
				clr.l d0
keyboard_getkey_found:
			pophl
		popbc
		rts

joystick_hardwarekeymap:
		dc.b 'q','a','o','p',' ',keychar_enter,keychar_backspace,'z'
	endif
;                                         

;                                     


	
	
	
