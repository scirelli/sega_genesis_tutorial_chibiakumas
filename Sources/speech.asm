;Note on changes to table stucture.

;The table structure of the sequences have been changed so that the 
;long addresses are now 16 bit aligned.

;Lack of alignment was rectifiable on the genesis, however this caused major
;issues on systems like the X68 and ST

;This seems to be because the 'relocation table' with addresses to update after load
;could not correctly work with unaligned values
;(even though those values were correct in the assembled binary)
;it seems it was corrupting data in an unpredictable way.
	
Cursor_X equ UserRam
Cursor_Y equ UserRam+2

	include "\SrcALL\BasicMacros.asm"
	include "\SrcALL\V1_Header.asm"

	
uservars equ userram+32



HLSwitchToggle equ Uservars			;Used by the ?. pitch shifter
RawStringpos equ HLSwitchToggle+2	;The string before convertion to phonetics
ConvAddr equ RawStringpos+4 		;Temp addr used during conversion
CharFromString equ ConvAddr+4		;A character from the string during coversion
SpeechDelay	equ CharFromString+2	;Speed during playback
SpeechSpeed equ SpeechDelay+2		;The default speed setting
TranslatedStringAddr equ SpeechSpeed+2	;Current pos in string for playback
TranslatedStringAddr2 equ TranslatedStringAddr+4 ;Current pos in string for playback #2
												; (for pitch shiffts)

AltOffset1 equ TranslatedStringAddr2+4	;3 offsets used for Alt sound samples
AltOffset2 equ AltOffset1+1 			; (short'wavy' sound)
AltOffset3 equ AltOffset2+1

HLSwitchAddr1 equ AltOffset1+4 			;Used to calculate point for .? pitch
HLSwitchAddr2 equ HLSwitchAddr1+4 		;Used to calculate point for .? pitch

LastChar equ HLSwitchAddr2+4			;Remember if last char is .?
TxtRawString equ LastChar+2				;Memory for the Uppercase+phonetic conversion


loop:
	move.l #mystring,a3		;zero terminated string to play
	move.b #6,d0			;D0=speed
	jsr saystringfromhl		;A3=string a=speed (0-15)
	jmp loop
	
mystring:
	ifd BuildGEN
		dc.b "I am a Genesis, you are a worm."	
	endif
	ifd BuildAST
		dc.b "I am an Attarreey Ess Tee, you are a worm."	
	endif
	ifd BuildAMI
		dc.b "I am an Ameegah, you are a worm."	
	endif
	dc.b "You will bow to my Sixty Eight Thousand superiority."
	dc.b 0
	even 		;Align to 16 bit boundary
	

	even
	include "\SrcALL\V1_Palette.asm"
	include "\SrcALL\V1_BitmapMemory.asm"
	include "\SrcALL\V1_VdpMemory.asm"
	include "\SrcALL\V1_Functions.asm"
	include "\SrcALL\Multiplatform_Monitor.asm"
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	
playspeechpartfromtext:
	move.b (speechspeed),(speechdelay)	;Reset default pause

	move.l #table_all,a2
	jsr tablescansimple				;Use table A2 to find a match

	addq.l #1,a3					;No match if we got here
	move.l a3,(translatedstringaddr)
	move.b #4,d0					;Silence Count


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

playwavsilent_atimes				;Silence player
	move.l #l9863_silence,a3
playwavhl_atimes_onebyte
	jsr soundinit
playwavhl_again_onebyte	
	move.b #$3f,d5					;63
soundplaysampleagainc:
	jsr soundplaysample
	subq.b #1,d5					;Play next sample loop
	bne soundplaysampleagainc
	subq.b #1,d2					;repeat 63 bytes loop
	bne playwavhl_again_onebyte
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


playwavhl_5times_alt:		;Distorted player
	move.b #5,d0
playwavhl_atimes_alt:		;ss / h type sounds 
	add.b d0,d0
	add.b d0,d0
	add.b d0,d0				;*8
	jsr soundinit
playwavhl_alt_again:
	move.l #altoffset1,a0
	move.b (a0),d0			;'random' offset
	eor.b #$65,d0
	add.b #$25,d0
	move.b d0,(a0)
		
	move.b (a0),d0			;AltOffset1
	roxl.b d0
	move.b d0,(a0)
	
	move.b (1,a0),d0		;AltOffset2
	roxl.b d0
	move.b d0,(1,a0)
	
	move.b (2,a0),d0		;AltOffset3
	roxl.b d0
	move.b d0,(2,a0)
	
	move.b (a0),d0			;AltOffset1
	and.l #%00001111,d0

	move.l a3,a6
		add.l d0,a3			;wave offset
		move.b #8,d5
soundplaysampleagain:
		jsr soundplaysample
		addq.l #1,a3
		subq.b #1,d5
		bne soundplaysampleagain
	move.l a6,a3
	subq.b #1,d2
	bne playwavhl_alt_again
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


playwavhl_atimes:					;Normal player
	jsr soundinit
playwavhl_again
	move.l a3,a6
		move.b #$3f,d5				;63
soundplaysampleagainb:
		jsr soundplaysample
		addq.l #1,a3
		subq.b #1,d5				;Play next sample loop
		bne soundplaysampleagainb
	move.l a6,a3
	subq.b #1,d2					;repeat 63 bytes loop
	bne playwavhl_again
	rts
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ifd BuildGEN
	
soundplaysample:
		move.b (a3),d0			;Low nibble (Sample 1)
		jsr setvolumewav

		move.b (a3),d0			;High nibble (Sample 2)
		lsr.b #4,d0
setvolumewav:
		and.b #$0f,d0
		or.b #%11010000,d0		;Set Volume %1101VVVV
		move.b d0,($C00011)
		clr.l d0
		move.b (speechdelay),d0
		asl.l #1,d0 			;Slow down playback
soundplaysample_pause
		subq.l #1,d0
		bne soundplaysample_pause
		rts

	
soundinit:
		move.b d0,d2			;D2 = Loop count

		move.b #%11000000,d0	; Low tone
		move.b d0,($C00011)
		move.b #%00000000,d0	; Low tone
		move.b d0,($C00011)
		rts
		
	endif
	
	
	
	ifd BuildAST
soundplaysample:
	move.b (a3),d0	;low nibble
	jsr setvolumewav

	move.b (a3),d0	;high nibble
	lsr.b #4,d0
setvolumewav:
	and.b #$0f,d0
	move.b d0,d1
	move.b #$09,d0
	jsr SetAYRegister
	

	
	move.b (speechdelay),d0
soundplaysample_pause
	nop
	nop
	nop
	nop
	nop
	nop
	
	subq.b #1,d0
	bne soundplaysample_pause
	rts

soundinit:
	move.b d0,d2

	move.b #$01,d0
	move.b #$00,d1
	jsr SetAYRegister
	
	move.b #$00,d0
	move.b #$00,d1
	jsr SetAYRegister
	
	move.b #$07,d0
	move.b #$3E,d1
	jsr SetAYRegister
	
		
	rts

	
	
SetAYRegister:
	move.b d0,$FF8800			;Reg Num
	move.b d1,$FF8802			;Reg Val
	rts		
		
	endif
	
	
	
	ifd BuildX68
	
	;Doesn't work right! I can't figure out how to do plain PCM (not adpcm)
	
soundplaysample:
	move.b (a3),d0	;low nibble
	jsr setvolumewav

	move.b (a3),d0	;high nibble
	lsr.b #4,d0
setvolumewav:
	eor.b #$0f,d0
	and.b #$0f,d0
	
	move.b #$60+24+7,$E90001 	;-VVVVVVV - [Slot] Volume (0=Max)
	lsl.b #3,d0
	move.b d0,$E90003
	
	move.b (speechdelay),d0
soundplaysample_pause
	nop
	nop
	nop
	nop
	
	subq.b #1,d0
	bne soundplaysample_pause
	rts

soundinit:
	move.b d0,d2

	move.b #$E0+24+7,$E90001	;DDDDRRRR - [Slot] Decay / Release rate
	move.b #%00001111,$E90003				;(15=Constant tone)
;	
	move.b #$1B,$E90001			;DC----WW - D=fdD force ready, C=Clock (4mhz/8mhz) 
	move.b #%01000001,$E90003				;W=Waveform (0=Saw 1=Square,2=Tri, 3=Noise)
	
	move.b #$0F,$E90001			;E--FFFFF - Noise Enable Freq 
	move.b #%00000000,$E90003				;(Slot 3 - channel 7)
	
	move.b #$08,$E90001			;-SSSSCCC - Channel / Slot
	move.b #%01000111,$E90003				;(Channel 7 - Slot 3)
	
	move.b #$28+7,$E90001		;-OOONNNN - Key Octave + Note
	move.b #%01111111,$E90003
	
	
	;move.b #$0F,$E90001			;E--FFFFF - Noise Enable Freq 
	;move.b #%10011111,$E90003
	
	
	rts	
	
	
	
	endif
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	ifd BuildAMI
	
	;Doesn't work right! I can't figure out how to do plain PCM (not adpcm)
	
soundplaysample:
	move.b (a3),d0	;low nibble
	jsr setvolumewav

	move.b (a3),d0	;high nibble
	lsr.b #4,d0
setvolumewav:
	and.w #$0f,d0
	lsl.b #4,d0
	move.b d0,d1
	lsl.w #8,d0
	or.b d1,d0
	move.w d0,(WaveSample)
	;move.w d0,($DFF0AA)
	;move.w d0,($DFF0AA+16)		;Direct steramed data - can't get thsi to work!
	move.b (speechdelay),d0
soundplaysample_pause
	nop
	nop
	nop
	nop
	
	subq.b #1,d0
	bne soundplaysample_pause
	rts

soundinit:
	move.b d0,d2

	move.w #1,d0
	;move.w #1,d0
	move.w d0,($DFF0A6)		; AUD0PER $DFF0A6	Audio channel 0 (L) period
	move.w d0,($DFF0A6+16)	; AUD1PER $DFF0B6	Audio channel 1 (R) period
		
	move.w #64,d0
	move.w d0,($DFF0A8)		; AUD0VOL $DFF0A8	Audio channel 0 (L) volume (#64=max)
	move.w d0,($DFF0A8+16)	; AUD0VOL $DFF0B8	Audio channel 1 (L) volume (#64=max)
	
	lea WaveSample,a0			;Load the address of the sample

	move.l a0,($DFF0A0)		; AUD0LCH $DFF0A0 	Audio channel 0 (L) location
	move.l a0,($DFF0A0+16)	; AUD1LCH $DFF0B0 	Audio channel 1 (R) location

	move.w #1,d0
	
	move.w d0,($DFF0A4)		; AUD0LEN $DFF0A4	Audio channel 0 (L) length
	move.w d0,($DFF0A4+16)	; AUD1LEN $DFF0B4	Audio channel 1 (R) length
	
							;Turn on sound DMA
	
	;        FEDCBA9876543210
	move.w #%1000001000000011,$DFF096	; $DFF096 DMACON - DMA control write (clear or set)
										;S-----E- ---DCBA	S=Set/Clr E=enable ABCD=Channnels
										
	;        FEDCBA9876543210
	;move.w #%0000000000001111,$DFF096	; $DFF096 DMACON - DMA control write (clear or set)
										;S-----E- ---DCBA	S=Set/Clr E=enable ABCD=Channnels
	rts
	
; AUD0LCH $DFF0A0 	Audio channel 0 (L) location (high 3 bits, 5 if ECS)
; AUD0LCL $DFF0A2 	Audio channel 0 (L) location (low 15 bits)
; AUD0LEN $DFF0A4	Audio channel 0 (L) length
; AUD0PER $DFF0A6	Audio channel 0 (L) period
; AUD0VOL $DFF0A8	Audio channel 0 (L) volume (#64=max)
; AUD0DAT $DFF0AA	Audio channel 0 (L) data

; AUD1LCH $DFF0B0 	Audio channel 1 (R) location (high 3 bits, 5 if ECS)
; AUD1LCL $DFF0B2 	Audio channel 1 (R) location (low 15 bits)
; AUD1LEN $DFF0B4	Audio channel 1 (R) length
; AUD1PER $DFF0B6	Audio channel 1 (R) period
; AUD1VOL $DFF0B8	Audio channel 1 (R) volume (#64=max)
; AUD1DAT $DFF0BA	Audio channel 1 (R) data

	endif



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

subtractswtichers:
	moveq.l #1,d4				;shift
	move.l (translatedstringaddr2),d5
	move.l d5,d0
	
	sub.l (hlswitchaddr1),d5	;2nd to last vowel?
	beq pitchshiftapply			;1 pitch shift
	
	moveq.l #2,d4				;shift
	sub.l (hlswitchaddr2),d0	;last vowel?
	beq pitchshiftapply			;2 pitch shift
	rts

pitchshiftapply:
	move.l #speechdelay,a0
	move.b (lastchar),d0

	cmp.b #$3f,d0			;?
	beq pitchquestion
	cmp.b #$2e,d0			;.
	beq pitchstatement
	rts

pitchquestion
	sub.b d4,(a0)		;pitch up
	rts

pitchstatement
	add.b d4,(a0)		;Pitch down
	rts
		
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
processdigitdelays:				;Digits are an additional delay
	jsr subtractswtichers			; to the playback speed
	move.b (a3),d0	
	cmp.b #$31,d0	;<1?
	bcs DoRet1
	
	cmp.b #$39,d0	;>9?
	bcc DoRet1
	rts

	sub.b #$34,d0				;Convert to digit from ascii
		
	add.b d0,(speechdelay)		;Add to current delay
								;Delay change is effectively -4 to +5
	addq.l #1,a3
	move.l a3,(translatedstringaddr)
DoRet1:
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

tablescaninchl:			;INC A3 and execute TableScan
	move.b (a3)+,d1
	move.l a3,(translatedstringaddr)
	jsr processdigitdelays
	jsr tablescan		;Wont return if matches
						; (also consumes caller to tablescan)
tablematchfailed:
	subq.l #1,a3					 ;Couldn't find a match for
	move.l a3,(translatedstringaddr) ; the letter in the table
DoRet2:
	rts

tablescansimple:
	move.l (translatedstringaddr),a3
	move.b (a3)+,d1
	move.l a3,(translatedstringaddr)

	jsr tablescan			;Wont return if matches
	bra tablematchfailed	; (also consumes caller to tablescan)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
tablescan:
	move.b (a2)+,d0
	beq DoRet2
	cmp.b d1,d0
	beq tablescanfound
	addq.l #5,a2			;skip command+addr
	bra tablescan

	
tablescanfound:
	move.l (sp)+,d0			;consume table launcher
	move.l (sp)+,d0			;consume return addr
	
	exg a3,a2
	move.b (a3)+,d0			;Cmd
	move.l (a3)+,d1			;Addr
	
	cmp.b #0,d0
	beq tablescanfoundjump
	
	move.l d1,a3

	cmp.b #255,d0
	beq playsequence

	btst #4,d0				;+16 for ALT player 
	beq playwavhl_atimes
	and.b #%00001111,d0		;Get loop count
	jmp playwavhl_atimes_alt

tablescanfoundjump:
	move.l (translatedstringaddr),a3
	move.l d1,-(sp)			;jump to addr
	rts
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


tablescaninchlret:
	jsr tablescaninchl
	rts			;ret will be consumed on success
				; dummy ret on failure so we can jp here

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_a
	move.l #table_a,a2		;TableScan Consumes 
	bra tablescaninchlret	; return address on sucess

process_e
	move.l #table_e,a2
	bra tablescaninchlret	

process_i
	move.l #table_i,a2
	bra tablescaninchlret

process_o
	move.l #table_o,a2
	bra tablescaninchlret

process_u
	move.l #table_u,a2
	bra tablescaninchlret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_slash		;/

	move.l #table_slash,a2
	bra tablescaninchlret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_d
	move.l #table_d,a2
	jsr tablescansimple	;consumes return address on sucess

	move.l #sequence_d,a3
	bra playsequence
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_c
	move.l #table_c,a2
	jsr tablescansimple	;consumes return address on sucess
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_t
	move.l #table_t,a2
	jsr tablescansimple	;consumes return address on sucess
	
	move.l #sequence_t,a3
	bra playsequence
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_z
	move.l #table_z,a2
	jsr tablescansimple	;consumes return address on sucess
	
	move.l #l9142_m,a3
	move.b #5,d0
	jsr playwavhl_atimes

	move.l #l95d0_z,a3
	jmp playwavhl_5times_alt

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_s
	move.l #table_s,a2
	jsr tablescansimple	;consumes return address on sucess

	subq.b #2,(speechdelay)	;Faliled? alter pitch and play Z sample
	
	move.l #l95d0_z,a3
	jmp playwavhl_5times_alt
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_n
	move.l #table_n,a2
	jsr tablescansimple	;consumes return address on sucess

	move.l #sequence_n,a3
	bra playsequence
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

playsequence:
	move.b (a3),d0		;Count / +16 =Alt +32 = onebyte
	bne lbl29252
	rts
lbl29252
	addq.l #2,a3 ;added 1 dummy byte because byte unaligned addresses
						;were messing up the ELFs
	
	;move.b (a3)+,d2		;May not be properly aligned
	;asl.l #8,d2
	;move.b (a3)+,d2		;May not be properly aligned
	;asl.l #8,d2
	;move.b (a3)+,d2		;May not be properly aligned
	;asl.l #8,d2
	;move.b (a3)+,d2		;May not be properly aligned
	;move.l d2,a2
	
	move.l (a3)+,a2

	move.l a3,-(sp)
		move.l a2,a3
		
		btst #4,d0			;+16 = Alt player
		bne playsequencealt
		
		btst #5,d0			;+32= OneByte player
		bne playsequenceonebyte
		
		jsr playwavhl_atimes	;Play the sample
	move.l (sp)+,a3
	bra playsequence

playsequencealt:
		and.b #%00001111,d0		;PlayCount
		jsr playwavhl_atimes_alt
	move.l (sp)+,a3
	bra playsequence

playsequenceonebyte:
		and.b #%00001111,d0		;PlayCount
		jsr playwavhl_atimes_onebyte
	move.l (sp)+,a3
	bra playsequence

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

saystringfromhl:	;a=speed (0-15)
	not.b d0		;convert the speed into something we can use
	add.b #$1a,d0
	move.b d0,(speechspeed)	;speed
	
	
	exg a2,a3				;Source String in A2
	
	move.l #txtrawstring,a3	;temp store
	move.b #' ',(a3)+
	
copystringagain:
	move.b (a2),d0			;copy char from src to dest
	beq copystringdone
	move.b d0,d1
	move.b d0,(a3)+
	addq.l #1,a2
	bra copystringagain		;repeat until all chars copied

copystringdone:
	move.b d1,(lastchar)
	move.b #' ',(a3)+		;store a space
	
	move.b #13,(a3)			;store an endline

	jsr charfix				;fix case and non pronouncable
	
	
	addq.l #1,a3			;store phonetic version immedately
							; after 'fixed' (uppercase version
							
	move.l a3,-(sp)
		jsr converttophonetics
	move.l (sp)+,a3

	jsr Monitor_MemDump		;Dump for checking phonetics
	dc.l TxtRawString+64
	dc.w $12
	
speakpart:
	move.l a3,(translatedstringaddr)
	move.l #altoffset1,a3	;used by the alt player to select offsets
	move.b #$65,(a3)+			;01100101
	move.b #$25,(a3)+			;00100101
	move.b #$63,(a3)+			;01100011

speakpart_again
	move.l (translatedstringaddr),a3	;next part
	move.l a3,(translatedstringaddr2)
	move.b (a3),d0
	cmp.b #13,d0				;end of string?
	beq DoRet3
	jsr playspeechpartfromtext	;play this bit
	bra speakpart_again

DoRet3:
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



charfix:				;first stage - fix chars in string
	move.l #txtrawstring,a3
charfixagain:
	move.b (a3),d0
	cmp.b #13,d0			;cr= done?
	beq DoRet3				;Return
	
	cmp.b #'/',d0
	beq charfix_space		;/ = - space
	cmp.b #'a',d0
	bcs charfix_ok			;upper case?
	cmp.b #'{',d0			;<=z
	bcc charfix_ok
	sub.b #$20,d0			;convert lower case -> upper
	move.b d0,(a3)

charfix_ok:
	addq.l #1,a3
	bra charfixagain		;repeat 
	
charfix_space:
	move.b #' ',(a3)+		;store a space!
	bra charfixagain
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


converttophonetics:
	move.l #txtrawstring,(rawstringpos)	;temp store (raw string)
	
	clr.l (hlswitchaddr2)			;reset the switchpos 
	clr.l (hlswitchaddr1)

	move.l a3,(translatedstringaddr)

	jsr translatetophonetics		;translate to phonetics

	move.l (translatedstringaddr),a3
	move.b #13,(a3)					;end the string with a 13
DoRet4:
	rts

	
translatetophonetics:
	move.l (rawstringpos),a3
	cmp.b #13,(a3)					;atendofstring?
	beq DoRet4
	jsr phoneticlookupentry			;lookup entry
	jsr phonetictransferentry		;build translated string
	
	bra translatetophonetics	
	
	
phoneticlookupentry:
	move.l (rawstringpos),a3
	clr.l d0
	move.b (a3),d0		;we need to calculate a lut offset
	cmp.b #'A',d0		;<A
	bcs lookupnonletter
	cmp.b #'[',d0		;>Z?
	bcc lookupnonletter
	sub.b #'A',d0
	
	asl.l #2,d0 				;*4 bytes per address
	move.l #alphabetpointers,a3	;char offset in lookup (4 bytes per entry)
	move.l (a3,d0),(convaddr)	;Get address of conversion
	
	
scanforaphoneticmatch:
	jsr PhoneticMatchTest			;get a phonetic?
	bcs DoRet4						;Carry set=? matched!
	
	
	move.l (convaddr),a3

	move.w #2-1,d4					;we need 2 entries
									; (dbra loops on 0 so 2-1)
scanforaphoneticmatchAgain:
	cmp.b #0,(a3)+					;Find 0
	bne scanforaphoneticmatchAgain
	dbra d4,scanforaphoneticmatchAgain
	
	move.l a3,(convaddr)			;We skipped two 0s
	bra scanforaphoneticmatch
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lookupnonletter:
	move.l #l9e89_spc,a1			;space list
	cmp.b #' ',d0
	beq phoneticlookupselectcustom
	move.l #la68d_numbers,a1		;numbers list

phoneticlookupselectcustom:
	move.l a1,(convaddr)			;Select the list
	bra scanforaphoneticmatch
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

phoneticmatchtest:
	move.l (rawstringpos),a3 ;source
	move.l (convaddr),a1	;converter

	move.b (a1),d0			;get an entry in coversion

phoneticmatchtestrepeat:
	cmp.b #' ',d0			;space?
	beq phoneticmatchtest_space
	cmp.b #'?',d0			;?
	beq phoneticmatchtest_question
	cmp.b (a3),d0			;matches char?
	bne phoneticnomatch 	;no - clear carry and return

phoneticmatchtest_movetonext:
	addq.l #1,a1			;move to next
	addq.l #1,a3

	move.b (a1),d0			;nonzero?
	beq phoneticfoundmatch
	
	move.b (a3),d0			;yes! get a source char
	cmp.b #13,d0
	beq phoneticnomatch		;give up if end of source

	move.b (a1),d0			;get a entry from conversion
	bra phoneticmatchtestrepeat	;repeat

	
phoneticfoundmatch
	addq.l #1,a1				;Next entry
	subq.l #1,a3				;Walk back through string

	move.l a1,(convaddr)
	move.l a3,(rawstringpos)
	move.b (a3),d0

	jsr validphentest		;a-z 0-9? in source (all we can convert)
	bcc phoneticmatchtest_skip ;skip source char

	move.b (-3,a1),d0			;get 3 chars back
	beq phoneticmatchtest_skip	;yes? then forward 1 char
	subq.l #1,a3
phoneticmatchtest_skip:
	addq.l #1,a3
	move.l a3,(rawstringpos)
	
	ori #%00000001,CCR			;carry=matched
	rts
	
	
phoneticmatchtest_question	;?
	cmp.b #13,(a3)
	beq phoneticnomatch
	move.b (a3),(charfromstring)
	bra phoneticmatchtest_movetonext ;move to next

phoneticmatchtest_space:	;space in converter
	move.b (a3),d0
	jsr validphentest		;a-z, 0-9? (all we can convert)
	bcs phoneticmatchtest_movetonext
	
phoneticnomatch				;no match
	move.l a1,(convaddr)
	ANDI #%11111110,CCR		;clear carry=nomatch
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


validphentest:			;see if this source char can be converted
	cmp.b #'0',d0		;<0?
	bcs validphentest_ng
	cmp.b #'[',d0		;>z?
	bcc validphentest_ng
	cmp.b #'A',d0		;<a?
	bcc validphentest_ok
	cmp.b #':',d0		;>9?
	bcc validphentest_ng
validphentest_ok
	ANDI #%11111110,CCR
	rts

validphentest_ng
	ORI #%00000001,CCR	;c=no good
	rts

	
phonetictransferentry:
	move.l (convaddr),a1
	move.l (translatedstringaddr),a3

phonetictransferentryagain:
	move.b (a1),d0					;get a phonetic
	beq phonetictransferentrydone	;phonetic 0?= end of phonetic
	cmp.b #'?',d0					;? = copy char from string?
	bne phonetictransferentry_noqm
	move.b (charfromstring),d0		;?=char from string
phonetictransferentry_noqm:

	jsr vowelswitcher
	move.b d0,(a3)+					;store the phonetic
	addq.l #1,a1
	bra phonetictransferentryagain

phonetictransferentrydone:
	move.l a3,(translatedstringaddr)
	rts
	

vowelswitcher:				;used to remember last two vowels
	cmp.b #'E',d0			; for ?. pitch change
	beq hlswitcher
	cmp.b #'A',d0
	beq hlswitcher
	cmp.b #'O',d0
	beq hlswitcher
	cmp.b #'I',d0
	beq hlswitcher
	cmp.b #'U',d0
	beq hlswitcher
	
hlswitcherb:
	clr.l d7
hlswitcherc:
	move.b d7,(hlswitchtoggle) ;flip the state of the switcher
	rts

hlswitcher:
	move.b (hlswitchtoggle),d7
	bne hlswitcherb
	move.l (hlswitchaddr2),(hlswitchaddr1)	;first pitch shift point
	move.l a3,(hlswitchaddr2)				;2nd pitch shift point
	moveq.l #1,d7
	bra hlswitcherc
	
	
	
	even
	include "\SrcALL\V1_DataArea.asm"
	
	even

AlphabetPointers:	;26 entries, 4 bytes per entry
	 dc.l la17c_a	;A	;Pointers to data
	 dc.l la2f0_b	;B
	 dc.l la475_c	;C
	 dc.l la5ff_d	;D
	 dc.l la3ad_e	;E
	 dc.l la38e_f	;F
	 dc.l la0f4_g	;G
	 dc.l la5ba_h	;H
	 dc.l l9df2_i	;I
	 dc.l la6f2_j	;J
	 dc.l la42c_k	;K
	 dc.l la626_l	;L
	 dc.l la314_m	;M
	 dc.l la136_n	;N
	 dc.l l9C90_O	;O
	 dc.l la5d3_p	;P
	 dc.l la683_q	;Q
	 dc.l la5a6_r	;R
	 dc.l la4cf_s	;S
	 dc.l la332_t	;T
	 dc.l la529_u	;U
	 dc.l la6f6_v	;V
	 dc.l la637_w	;W
	 dc.l la43f_x	;X
	 dc.l la44a_y	;Y
	 dc.l la674_z	;Z

l9E89_spc:
	 dc.b ' ','D','A','V','I','D',' '     ;391  - Ofst.&1870
	 dc.b 000,' ','D','A','Y','V','I','H','D',000,' ','P','S','Y',000,' '     ;392  - Ofst.&1880
	 dc.b 'S','I','Y',000,' ','G','I','V','E',000,' ','G','I','H','V',000     ;393  - Ofst.&1890
	 dc.b ' ','Y','O','U','R',' ',000,' ','Y','A','O','R',000,' ','C','H'     ;394  - Ofst.&18A0
	 dc.b 'A','I','R',' ',000,' ','C','H','A','I','R',000,' ','W','H','Y'     ;395  - Ofst.&18B0
	 dc.b ' ',000,' ','W','I','Y',000,' ','E',' ',000,' ','E','E',000,' '     ;396  - Ofst.&18C0
	 dc.b '?','E','R','E',000,' ','?','E','E','3','E','R',000,' ','O','U'     ;397  - Ofst.&18D0
	 dc.b 'G','H','T',000,' ','A','O','2','T',000,' ','C','O','U','G','H'     ;398  - Ofst.&18E0
	 dc.b ' ',000,' ','K','O','O','F',000,' ','?','O','U','G','H',' ',000     ;399  - Ofst.&18F0
	 dc.b ' ','?','A','H','F',000,' ','S','C','I',000,' ','S','I','Y',000     ;400  - Ofst.&1900
	 dc.b ' ','Y','E','S',' ',000,' ','Y','E','H','3','S',000,' ','?','I'     ;401  - Ofst.&1910
	 dc.b 'E',000,' ','?','I','Y',000,' ','A','B','L','E',000,' ','A','Y'     ;402  - Ofst.&1920
	 dc.b '3','B','L',000,' ','G','E','T',000,' ','G','E','H','T',000,' '     ;403  - Ofst.&1930
	 dc.b 'A','N','Y',000,' ','E','H','2','N','E','E',000,' ','U','?','E'     ;404  - Ofst.&1940
	 dc.b 000,' ','Y','U','X','W','?',000,' ','O','U','R',000,' ','A','W'     ;405  - Ofst.&1950
	 dc.b '3','R',000,' ','O','N','E',000,' ','W','O','O','N',000,' ','T'     ;406  - Ofst.&1960
	 dc.b 'O',' ',000,' ','T','U','X','3',000,' ','B','E',' ',000,' ','B'     ;407  - Ofst.&1970
	 dc.b 'E','E','3',000,' ','O','F',' ',000,' ','O','O','3','V',000,' '     ;408  - Ofst.&1980
	 dc.b 'A',' ',000,' ','A','E',000,' ','A','R','E',' ',000,' ','A','A'     ;409  - Ofst.&1990
	 dc.b '3','R',000,' ','W','O','R',000,' ','W','E','R','3',000,' ','M'     ;410  - Ofst.&19A0
	 dc.b 'E',' ',000,' ','M','E','E','3',000,' ','G','I',000,' ','J','I'     ;411  - Ofst.&19B0
	 dc.b 'Y',000,' ','M','Y',' ',000,' ','M','I','Y',000,' ','I','S',' '     ;412  - Ofst.&19C0
	 dc.b 000,' ','I','X','4','S',000,' ','S','C',000,' ','S','K',000,' '     ;413  - Ofst.&19D0
	 dc.b 'A','S',' ',000,' ','A','E','S',000,' ','W','I','T','H',' ',000     ;414  - Ofst.&19E0
	 dc.b ' ','W','I','X','3','D','H',000,' ','H','A','V','E',' ',000,' '     ;415  - Ofst.&19F0
	 dc.b '/','H','A','E','3','V',000,' ','B','Y',' ',000,' ','B','I','Y'     ;416  - Ofst.&1A00
	 dc.b '1',000,' ','T','H','I','S',' ',000,' ','D','H','I','X','S',000     ;417  - Ofst.&1A10
	 dc.b ' ','W','E',' ',000,' ','W','E','E','3',000,' ','T','H','E','Y'     ;418  - Ofst.&1A20
	 dc.b ' ',000,' ','D','H','A','Y','2',000,' ','H','A','S',' ',000,' '     ;419  - Ofst.&1A30
	 dc.b '/','H','A','E','S',000,' ','T','H','E','I','R',' ',000,' ','D'     ;420  - Ofst.&1A40
	 dc.b 'H','A','I','2','R',000,' ','T','H','A','N',' ',000,' ','D','H'     ;421  - Ofst.&1A50
	 dc.b 'A','E','4','N',000,' ','O','N','L','Y',' ',000,' ','O','W','3'     ;422  - Ofst.&1A60
	 dc.b 'N','L','E','E',000,' ','P','E','O',000,' ','P','E','E','2',000     ;423  - Ofst.&1A70
	 dc.b ' ','S','H','E',' ',000,' ','S','H','E','E','3',000,' ','S','A'     ;424  - Ofst.&1A80
	 dc.b 'I','D',' ',000,' ','S','A','I','4','D',000,' ','S','O','M','E'     ;425  - Ofst.&1A90
	 dc.b ' ',000,' ','S','A','H','3','M',000,' ','T','H','E','N',' ',000     ;426  - Ofst.&1AA0
	 dc.b ' ','D','H','E','H','3','N',000,' ','M','E',' ',000,' ','M','E'     ;427  - Ofst.&1AB0
	 dc.b 'E',000,' ','G','O','T','O',' ',000,' ','G','O','W','T','U','W'     ;428  - Ofst.&1AC0
	 dc.b 000,' ','M','O','S','T',' ',000,' ','M','O','W','2','S','T',000     ;429  - Ofst.&1AD0
	 dc.b ' ',000,' ',000

l9C90_O: ;Phonetic conversions
	 dc.b 'O','U','S',' ',000,'U','U','3','S',000,'O','C','A',000,'O','W'     ;360  - Ofst.&1680
        dc.b '2','K','A','H',000,'O','C','O',' ',000,'O','W','K','O','W',000     ;361  - Ofst.&1690
        dc.b 'O','C','O',000,'O','W','K',000,'O','C','U',000,'O','W','K','U'     ;362  - Ofst.&16A0
        dc.b 'U',000,'O','Q','U',000,'O','W','K',000,'O','X','U',000,'O','O'     ;363  - Ofst.&16B0
        dc.b 'K','S','U','U',000,'O','?','U',000,'O','W','3','?',000,'O','U'     ;364  - Ofst.&16C0
        dc.b 'G','H',' ',000,'O','H','3','W',000,'O','G','Y',000,'O','J','E'     ;365  - Ofst.&16D0
        dc.b 'E',000,'O','U','G','H',000,'A','H',000,'O','L','E',' ',000,'O'     ;366  - Ofst.&16E0
        dc.b 'W','2','L',000,'O','E',000,'O','W','3',000,'O','U','L','D',' '     ;367  - Ofst.&16F0
        dc.b 000,'U','H','3','D',000,'O','X','O',000,'O','O','K','S','O','W'     ;368  - Ofst.&1700
        dc.b 000,'O','?','O',' ',000,'O','W','?','O','W',000,'O','?','O',000     ;369  - Ofst.&1710
        dc.b 'O','W','2','?',000,'O','X','A',000,'O','O','K','S','A','E',000     ;370  - Ofst.&1720
        dc.b 'O','?','A',000,'O','W','2','?',000,'O','C','E',000,'O','W','S'     ;371  - Ofst.&1730
        dc.b 'H',000,'O','X','E',000,'O','O','K','S',000,'O','?','E',000,'O'     ;372  - Ofst.&1740
        dc.b 'W','3','?',000,'O','O','K',000,'U','H','3','K',000,'O','U',000     ;373  - Ofst.&1750
        dc.b 'A','E','2','U','X',000,'O','U','R',000,'A','O','3','R',000,'O'     ;374  - Ofst.&1760
        dc.b 'I','C',000,'O','Y','S',000,'O',' ',000,'O','W',000,'O','A',000     ;375  - Ofst.&1770
        dc.b 'O','H','3','W',000,'O','R','E',' ',000,'A','O','2','R',000,'O'     ;376  - Ofst.&1780
        dc.b 'W',000,'O','W',000,'O','R','I',000,'A','O','R','I','X','2',000     ;377  - Ofst.&1790
        dc.b 'O','O',000,'U','X',000,'O','R',000,'A','O','R',000,'O','H',000     ;378  - Ofst.&17A0
        dc.b 'O','H',000,'O','O','R',000,'A','O','3','R',000,'O','I',000,'O'     ;379  - Ofst.&17B0
        dc.b 'Y','3',000,'O','Y',000,'O','Y',000,'O','T','H','E','R',000,'A'     ;380  - Ofst.&17C0
        dc.b 'H','D','H','E','R',000,'O','R','R',000,'O','R',000,'O',000,'O'     ;381  - Ofst.&17D0
        dc.b 'O',000
l9df2_i
	 dc.b 'I','C','E',000,'I','Y','S',000,'I','C','Y',000,'I','Y'     ;382  - Ofst.&17E0
        dc.b 'S','E','E','4',000,'I','X','Y',000,'I','H','K','S','E','E',000     ;383  - Ofst.&17F0
        dc.b 'I','?','Y',000,'I','Y','?','E','E',000,'I','R','O',000,'I','Y'     ;384  - Ofst.&1800
        dc.b 'R','O','O',000,'I','Y',000,'I','Y',000,'I','T','L','E',000,'I'     ;385  - Ofst.&1810
        dc.b 'Y','T','U','U','L',000,'I','E','D',000,'A','Y','3','D',000,'I'     ;386  - Ofst.&1820
        dc.b 'X','E',000,'I','H','K','S',000,'I','?','E',000,'I','Y','3','?'     ;387  - Ofst.&1830
        dc.b 000,'I','E',000,'E','E',000,'I','G','I',000,'I','X','2','J','I'     ;388  - Ofst.&1840
        dc.b 'H',000,'I',' ',000,'I','Y','4',000,'I','S','M',000,'I','X','3'     ;389  - Ofst.&1850
        dc.b 'S','U','U','M',000,'I','G','H',000,'I','Y','2',000,'I','R',000     ;390  - Ofst.&1860
        dc.b 'E','R','4',000,'I',000,'I','H',000

la0f4_g
	 dc.b 'G','T','H',' ',000,'T','H',000,'G','H','O','T'     ;430  - Ofst.&1AE0
        dc.b 'I',000,'F','I','H','4','S','H',000,'G','U','E',' ',000,'G',000     ;431  - Ofst.&1AF0
        dc.b 'G','O','O',000,'G','U','H','2',000,'G','E','N',000,'J','E','H'     ;432  - Ofst.&1B00
        dc.b '3','N',000,'G','H','O',000,'G','O','H','2','W',000,'G','G',000     ;433  - Ofst.&1B10
        dc.b 'G',000,'G',000,'G',000
la136_n:
	 dc.b 'N','G','E','R',000,'N','X','G','E','R'     ;434  - Ofst.&1B20
        dc.b 000,'N','G','S',' ',000,'N','X','Z',000,'N','O','W',000,'N','A'     ;435  - Ofst.&1B30
        dc.b 'W',000,'N','G','E',000,'N','J',000,'N','I','O','N',000,'N','I'     ;436  - Ofst.&1B40
        dc.b 'X','U','U','N',000,'N','N',000,'N',000,'N','G',' ',000,'N','X'     ;437  - Ofst.&1B50
        dc.b 000,'N','G',000,'N','X','G',000,'N',000,'N',000
la17c_a
	 dc.b 'A','G','E',' '     ;438  - Ofst.&1B60
        dc.b 000,'A','Y','J',000,'A','U','G','H',000,'A','A','3','F',000,'A'     ;439  - Ofst.&1B70
        dc.b 'I','G','H',000,'A','Y',000,'A','B','L','E',000,'A','H','B','U'     ;440  - Ofst.&1B80
        dc.b 'U','L',000,'A','C','I',000,'A','E','S','I','H',000,'A','X','I'     ;441  - Ofst.&1B90
        dc.b 000,'A','E','K','S','I','H',000,'A','?','I',000,'A','Y','3','?'     ;442  - Ofst.&1BA0
        dc.b 000,'A','R','E',000,'A','I','3','R',000,'A',' ',000,'A','H',000     ;443  - Ofst.&1BB0
        dc.b 'A','N','G','E',' ',000,'A','Y','2','N','J',000,'A','N','G','E'     ;444  - Ofst.&1BC0
        dc.b 000,'A','Y','2','N','J','U','U',000,'A','L','L','Y',000,'A','E'     ;445  - Ofst.&1BD0
        dc.b '2','L','E','E',000,'A','X','A',000,'A','E','K','S','A','E',000     ;446  - Ofst.&1BE0
        dc.b 'A','C','A',000,'A','E','K','A','E',000,'A','?','A',000,'A','Y'     ;447  - Ofst.&1BF0
        dc.b '?',000,'A','C','E',000,'A','Y','S',000,'A','X','E',000,'A','E'     ;448  - Ofst.&1C00
        dc.b 'K','S',000,'A','?','E',000,'A','Y','4','?',000,'A','C','Y',000     ;449  - Ofst.&1C10
        dc.b 'A','Y','S','E','E',000,'A','C','H',000,'A','E','C','H',000,'A'     ;450  - Ofst.&1C20
        dc.b 'C','K',000,'A','E','K',000,'A','C','C',000,'A','E','K',000,'A'     ;451  - Ofst.&1C30
        dc.b 'C',000,'A','E','K',000,'A','X','O',000,'A','E','K','S','O','W'     ;452  - Ofst.&1C40
        dc.b 000,'A','?','O',000,'A','Y','?',000,'A','U',000,'A','O','3',000     ;453  - Ofst.&1C50
        dc.b 'A','V','I',000,'A','Y','2','V','I','X',000,'A','L','K',000,'A'     ;454  - Ofst.&1C60
        dc.b 'O','R','K',000,'A','R',000,'A','A','3',000,'A','F',000,'A','A'     ;455  - Ofst.&1C70
        dc.b '2','F',000,'A','Z','Y',000,'A','Y','3','Z','E','E',000,'A','L'     ;456  - Ofst.&1C80
        dc.b 'L',000,'A','O','2','L',000,'A','X','Y',000,'A','E','K','S','E'     ;457  - Ofst.&1C90
        dc.b 'E',000,'A','?','Y',000,'A','I','I','X','?','E','E',000,'A','W'     ;458  - Ofst.&1CA0
        dc.b 000,'A','W',000,'A','I',000,'A','Y','2',000,'A','I','R',000,'A'     ;459  - Ofst.&1CB0
        dc.b 'I','R',000,'A','Y',000,'A','Y',000,'A','R',' ',000,'A','A','3'     ;460  - Ofst.&1CC0
        dc.b 'R',000,'A','R','R',000,'A','E','3','R',000,'A',000,'A','E',000     ;461  - Ofst.&1CD0
la2f0_b
        dc.b 'B','B','C',000,'B','E','E','%','%','B','E','E','%','S','E','E'     ;462  - Ofst.&1CE0
        dc.b 000,'B','B',000,'B',000,'B','E','Y',' ',000,'B','E','E','Y',000     ;463  - Ofst.&1CF0
        dc.b 'B',000,'B',000
la314_m
	 dc.b 'M','I','C','R','O',000,'M','I','Y','3','K','R'     ;464  - Ofst.&1D00
        dc.b 'O','W',000,'M','B',' ',000,'M',000,'M','M',000,'M',000,'M',000     ;465  - Ofst.&1D10
        dc.b 'M',000
la332_t
	 dc.b 'T','W','O',000,'T','U','W',000,'T','H','R','E','E',000     ;466  - Ofst.&1D20
        dc.b 'T','H','R','E','E',000,'T','C','H',000,'C','H',000,'T','L','E'     ;467  - Ofst.&1D30
        dc.b 000,'T','L',000,'T','U','?','E',000,'C','H','U','W','?',000,'T'     ;468  - Ofst.&1D40
        dc.b 'I','O',000,'S','H','A','H',000,'T','I','A',000,'S','H','I','X'     ;469  - Ofst.&1D50
        dc.b 'U','U',000,'T','H','E',' ',000,'D','H','U','U','%',' ',000,'T'     ;470  - Ofst.&1D60
        dc.b 'H',000,'T','H',000,'T','T',000,'T',000,'T',000,'T',000
la38e_f:
	 dc.b 'F','O'     ;471  - Ofst.&1D70
        dc.b 'U','R',000,'F','A','O','3','R',000,'F','O','O','T',000,'F','U'     ;472  - Ofst.&1D80
        dc.b 'H','2','T',000,'F','F',000,'F',000,'F',000,'F',000
la3ad_e:
	 dc.b 'E','I','G'     ;473  - Ofst.&1D90
        dc.b 'H','T',000,'A','Y','T','E',000,'E','R','Y',' ',000,'E','H','2'     ;474  - Ofst.&1DA0
        dc.b 'R','E','E',000,'E','R','R',000,'E','H','2','R',000,'E','S',' '     ;475  - Ofst.&1DB0
        dc.b 000,'S',000,'E','F','U','L',' ',000,'F','U','U','L',000,'E','A'     ;476  - Ofst.&1DC0
        dc.b 'S','E',' ',000,'E','E','Z',000,'E',' ',000,'%',000,'E','W',000     ;477  - Ofst.&1DD0
        dc.b 'I','H','U','W',000,'E','U',000,'I','H','U','H','2',000,'E','E'     ;478  - Ofst.&1DE0
        dc.b 000,'E','E','4',000,'E','R','E',000,'A','I','R',000,'E','R',000     ;479  - Ofst.&1DF0
        dc.b 'E','R',000,'E','Y',000,'A','Y',000,'E','A',000,'E','E','3',000     ;480  - Ofst.&1E00
        dc.b 'E','D',' ',000,'%','D',000,'E',000,'E','H',000
la42c_k
	 dc.b 'K','N',000,'N'     ;481  - Ofst.&1E10
        dc.b 000,'K','E','Y',' ',000,'K','E','E','Y',000,'K',000,'K',000
la43f_x
	 dc.b 'X','C',000,'K','S',000,'X',000,'K','S',000
la44a_y:
	 dc.b 'Y','S',000,'I','H','2'     ;483  - Ofst.&1E30
        dc.b 'S',000,'Y','P','E',000,'I','Y','2','P',000,'Y','E',' ',000,'I'     ;484  - Ofst.&1E40
        dc.b 'Y',000,'Y',' ',000,'E','E',000,'Y','O','U',' ',000,'Y','U','W'     ;485  - Ofst.&1E50
        dc.b 000,'Y',000,'Y',000
la475_c:
	 dc.b 'C','H','N',000,'K','N',000,'C','I',000,'S'     ;486  - Ofst.&1E60
        dc.b 'I','H',000,'C','H','R',000,'K','R',000,'C','O','M','E',' ',000     ;487  - Ofst.&1E70
        dc.b 'K','A','H','M',000,'C','O','W',000,'K','A','W',000,'C','E',' '     ;488  - Ofst.&1E80
        dc.b 000,'S',000,'C','E',000,'S','E','H','2',000,'C','H',000,'C','H'     ;489  - Ofst.&1E90
        dc.b 000,'C','C',000,'K',000,'C','K',000,'K',000

	 dc.b 'C','P','C',000,'S','E','E',' ','P','E','E',' ','S','E','E',000 ;Speccy fans won't want this!

	 dc.b 'C',000,'K',000
la4cf_s:
	 dc.b 'S','U','P','E','R','I','O','R',000,'S','U','X','2','P','E','E','3'     ;492  - Ofst.&1EC0
        dc.b 'R','I','H','A','O','R',000,'S','H','A','L','L',000,'S','H','A'     ;493  - Ofst.&1ED0
        dc.b 'E','L',000,'S','T','I','O','N',000,'S','%','C','H','U','U','N'     ;494  - Ofst.&1EE0
        dc.b 000,'S','E','S',' ',000,'S','I','X','Z',000,'S','S',000,'S',000     ;495  - Ofst.&1EF0
        dc.b 'S','I','O',000,'Z','H','U','U',000,'S','H',000,'S','H',000,'S'     ;496  - Ofst.&1F00
        dc.b 'C',000,'S','K',000,'S',000,'S',000
la529_u
	 dc.b 'U','E',' ',000,'U','W','6'     ;497  - Ofst.&1F10
        dc.b 000,'U','R','E',' ',000,'U','H','3','R',000,'U','Y',000,'I','Y'     ;498  - Ofst.&1F20
        dc.b '3',000,'U','C','E',000,'U','W','S',000,'U','?','E',000,'Y','U'     ;499  - Ofst.&1F30
        dc.b 'W','3','?',000,'U','?','A',000,'U','X','W','?',000,'U','C','I'     ;500  - Ofst.&1F40
        dc.b 000,'U','W','S','I','H',000,'U','?','I',000,'Y','U','X','W','?'     ;501  - Ofst.&1F50
        dc.b 000,'U','L','L',000,'U','H','3','L',000,'U','H',000,'U','H',000     ;502  - Ofst.&1F60
        dc.b 'U','L',' ',000,'U','U','L',000,'U','A','L',000,'Y','U','U','L'     ;503  - Ofst.&1F70
        dc.b 000,'U','R',000,'E','R','3','R',000,'U','R','R',000,'A','H','R'     ;504  - Ofst.&1F80
        dc.b 000,'U',000,'A','H',000
la5a6_r
	 dc.b 'R','E','A','T',000,'R','A','Y','3','T'     ;505  - Ofst.&1F90
        dc.b 000,'R','R',000,'R',000,'R',000,'R',000
la5ba_h
	 dc.b 'H','O','W',000,'/','H'     ;506  - Ofst.&1FA0
        dc.b 'A','W','2',000,'H','E',' ',000,'/','H','E','E','4',000,'H',000     ;507  - Ofst.&1FB0
        dc.b '/','H',000
la5d3_p:
	 dc.b 'P','O','W',000,'P','A','W','3',000,'P','R','O','G'     ;508  - Ofst.&1FC0
        dc.b 000,'P','R','O','W','2','G',000,'P','H',000,'F',000,'P','P',000     ;509  - Ofst.&1FD0
        dc.b 'P',000,'P','L','Y',000,'P','L','I','Y',000,'P',000,'P',000
la5ff_d
	 dc.b 'D'     ;510  - Ofst.&1FE0
        dc.b 'O','W',000,'D','A','W','2',000,'D','O',' ',000,'D','U','H','4'     ;511  - Ofst.&1FF0
        dc.b 'W',000,'D','G',000,'J',000,'D','H',000,'D','H',000,'D','D',000     ;512  - Ofst.&2000
        dc.b 'D',000,'D',000,'D',000,'L','E',' ',000,'U','U','L',000
la626_l
	 dc.b 'L','L'     ;513  - Ofst.&2010
        dc.b 000,'L',000,'L',000,'L',000
la637_w
	 dc.b 'W','H','O',000,'/','H','U','H','W'     ;514  - Ofst.&2020
        dc.b 000,'W','A','S',' ',000,'W','O','O','Z',000,'W','H','A',000,'W'     ;515  - Ofst.&2030
        dc.b 'O','O','3',000,'W','A','T',000,'W','A','O','4','T',000,'W','H'     ;516  - Ofst.&2040
        dc.b 000,'W',000,'W','R',000,'R',000,'W','O','O',000,'W','U','H',000     ;517  - Ofst.&2050
        dc.b 'W',000,'W',000
la674_z:
	 dc.b 'Z','Z',000,'Z',000,'Z','H',000,'Z','H',000     ;518  - Ofst.&2060
        dc.b 'Z','8','0',000,'Z','A','Y','D',' ','A','Y','3','T',' ','I','Y',' ',000
        dc.b 'Z',000,'Z',000
la683_q:
	 dc.b 'Q','U',000,'K','W',000,'Q',000,'K',000
la68d_numbers:
	 dc.b '0',000,'Z'     ;519  - Ofst.&2070
        dc.b 'I','H','5','R','O','W','2',' ',000,'1',000,'W','O','O','3','N'     ;520  - Ofst.&2080
        dc.b ' ',000,'2',000,'T','U','H','2','W',' ',000,'3',000,'T','H','R'     ;521  - Ofst.&2090
        dc.b 'E','E','3',' ',000,'4',000,'F','A','O','3','R',' ',000,'5',000     ;522  - Ofst.&20A0
        dc.b 'F','I','Y','3','V',' ',000,'6',000,'S','I','H','4','K','S',' '     ;523  - Ofst.&20B0
        dc.b 000,'7',000,'S','E','H','3','V','U','U','N',' ',000,'8',000,'A'     ;524  - Ofst.&20C0
        dc.b 'Y','3','T',' ',000,'9',000,'N','I','Y','3','N',' ',000,'?',000     ;525  - Ofst.&20D0
        dc.b '?',000
la6f2_j:
	 dc.b 'J',000,'J',000
la6f6_v
	 dc.b 'V',000,'V',000

;TxtRawString = Temp Store (unaltered)

	even
	

;First byte = Comparison, 2nd=Repeat/command, 3rd/4th=addr
;255=Sequence ; 0=call ; all other=single sample  1-15 = loop  16-31 = LoopAlt 32-47 = LoopSingleByte

Table_All:	
	 dc.b 'A',0
	  dc.l Process_A
	 dc.b 'U',0
	  dc.l Process_U
	 dc.b 'I',0
	  dc.l Process_I
	 dc.b 'E',0
	  dc.l Process_E
	 dc.b 'O',0
	  dc.l Process_O
	 dc.b 'S',0
	  dc.l Process_S
	 dc.b '/',0
	  dc.l Process_Slash
	 dc.b 'D',0
	  dc.l Process_D
	 dc.b 'C',0
	  dc.l Process_C
	 dc.b 'T',0
	  dc.l Process_T
	 dc.b 'N',0
	  dc.l Process_N
	 dc.b 'Z',0
	  dc.l Process_Z
	 dc.b 'B',255
	  dc.l Sequence_B ;l8e1b
	 dc.b 'F',5
 	  dc.l l9618_F	;l8ec4
	 dc.b 'G',255
	  dc.l Sequence_G ;l8ed1
	 dc.b 'J',255
	  dc.l Sequence_J ;l8e9f
	 dc.b 'K',255
	  dc.l Sequence_K ;l8e6a
	 dc.b 'L',7
	  dc.l l90c3_L ;l8e3b
	 dc.b 'M',7
	  dc.l l9142_M	;l8e48
	 dc.b 'P',255
	  dc.l Sequence_P ;l8e7d
	 dc.b 'R',7
	  dc.l l8fc3_R	;l8e2e
	 dc.b 'V',255
	  dc.l Sequence_V ;l8e55
	 dc.b 'W',7
	  dc.l l92d2_W ;l8e92
 	 dc.b 'Y',7
	  dc.l l9353_Y	;l8eb7
	 dc.b '%',255
 	  dc.l Sequence_Percent ;l8ad2
	 dc.b 0
	 even
	 	 
	;dc.l 0
Table_A:
	 dc.b 'Y',255
	  dc.l Sequence_AY ;l8b22
	 dc.b 'E',7
	  dc.l l8958_A
	 dc.b 'A',9
	  dc.l l8f43_AA
	 dc.b 'W',255
	  dc.l Sequence_AW ;l8b3b
	 dc.b 'H',7
	  dc.l l9182_AH
	 dc.b 'O',9
	  dc.l l9043_AO
	 dc.b 'I',9
	  dc.l l8f83_AI
	 dc.b 0
	 even


Table_E:
	 dc.b 'E',7
	  dc.l l9083_EE
	 dc.b 'H',7
	  dc.l l97e3_EH
	 dc.b 'R',9
	  dc.l l9510_ER
	 dc.b 0
	even


Table_I:
	 dc.b 'Y',255
	  dc.l Sequence_IY ;l8bb8
	 dc.b 'X',5
	  dc.l l9392_IH
	 dc.b 'H',7
 	  dc.l l9392_IH
	 dc.b 0
	even

Table_O:
	 dc.b 'W',255
	  dc.l Sequence_OW ;l8bfa
	 dc.b 'Y',255
	  dc.l Sequence_OY ;l8c0b
	 dc.b 'H',8
 	  dc.l l94d0_OH
	 dc.b 'O',8
	  dc.l l94d0_OO
	 dc.b 0
	even

Table_U:
	 dc.b 'X',8
	  dc.l l9003_U
	 dc.b 'W',255
	  dc.l Sequence_UW ;l8c5e
	 dc.b 'H',7
  	  dc.l l9823_UH
	 dc.b 'U',8
  	  dc.l l9761_UU
	 dc.b 0
	 even

Table_Slash:
	 dc.b 'H',4+16
 	  dc.l l9252_slashH
	 dc.b 0
	even

Table_D:
	 dc.b 'H',255
	  dc.l Sequence_DH ;l8cb7
	 dc.b 'R',255
	  dc.l Sequence_DR ;l8ccc
	 dc.b 'U',255
 	  dc.l Sequence_DU ;l8ce9
	 dc.b 0
	even
	 
Table_C
	 dc.b 'H',255
	  dc.l Sequence_CH;l8d3b
	 dc.b 'T',255
	  dc.l Sequence_CT ;l8d1a
  	 dc.b 0
	even
	 
Table_T:
	 dc.b 'H',5+16
	  dc.l l96e0_TH
	 dc.b 'R',255
	  dc.l Sequence_TR ;l8d7f
	 dc.b 0
	 even

Table_Z:
	 dc.b 'H',255
	  dc.l Sequence_ZH ;l8db6
	 dc.b 0
	 even

Table_S
	 dc.b 'H',6+16
	  dc.l l9550_SH
	 dc.b 0
	 even

Table_N:
	 dc.b 'X',7
	  dc.l l9450_NX
	 dc.b 0
	even
	 
	 


;First byte = Repeat, 2nd byte = spacer
;3rd-6th addr
;Repeat 0=End of sequence  1-15 = loop  16-31 = LoopAlt 32-47 = LoopSingleByte

Sequence_Percent:
	 dc.b 2+32,0
	 dc.l l9863_Silence
	 dc.b 0,0
	

Sequence_AY
	 dc.b 9,0
	  dc.l l9311_A
	 dc.b 5,0
	  dc.l l9392_IH
	 dc.b 2,0
	  dc.l l9353_Y
	 dc.b 0,0
Sequence_AW:
	 dc.b 9,0
	  dc.l l8958_A
	 dc.b 6,0
 	  dc.l l92d2_W
	 dc.b 0,0


Sequence_IY
	 dc.b 9,0
	  dc.l l8f43_AA
	 dc.b 6,0
	  dc.l l9392_IH
	 dc.b 0,0

Sequence_OW
	 dc.b 9,0
	  dc.l l94d0_OH
	 dc.b 5,0
 	  dc.l l92d2_W
	 dc.b 0,0

Sequence_OY
	 dc.b 9,0
	  dc.l l9043_AO
	 dc.b 4,0
	  dc.l l9392_IH
	 dc.b 2,0
 	  dc.l l9353_Y
	 dc.b 0,0

Sequence_UW
	 dc.b 7,0
	  dc.l l9003_U
	 dc.b 6,0
 	  dc.l l92d2_W
	 dc.b 0,0

Sequence_D:
	 dc.b 3+32,0
 	  dc.l l9863_Silence
	 dc.b 1,0
	  dc.l l9410_D
	 dc.b 3+32,0
 	  dc.l l9863_Silence
	 dc.b 0,0

Sequence_DH:
	 dc.b 4,0
	  dc.l l9720_DH
	 dc.b 1+16,0
	  dc.l l9252_slashH
	 dc.b 0,0

Sequence_DR
	 dc.b 2+32,0
	  dc.l l96a0_T
	 dc.b 3,0
	  dc.l l93d0_D
	 dc.b 7,0
  	  dc.l l8fc3_R
	 dc.b 0,0

Sequence_DU
	 dc.b 5+32,0
	  dc.l l96a0_T
	 dc.b 2,0
	  dc.l l93d0_D
	 dc.b 8,0
	  dc.l l9003_U
 	 dc.b 0,0




Sequence_CT
	 dc.b 2+32,0
	  dc.l l96a0_T
	 dc.b 1,0
	  dc.l l8997_K
	 dc.b 1+32,0
  	  dc.l l96a0_T
	 dc.b 1,0
 	  dc.l l89d7_T
	 dc.b 0,0



Sequence_CH
	 dc.b 6+32,0
	  dc.l l96a0_T
	 dc.b 3,0
	  dc.l l9550_SH
	 dc.b 1,0
	  dc.l l8958_A
	 dc.b 0,0






Sequence_T:
	 dc.b 3+32,0
 	  dc.l l9863_Silence
	 dc.b 1,0
	  dc.l l89d7_T
	 dc.b 3+32,0
 	  dc.l l9863_Silence
	 dc.b 0,0

Sequence_TR
	 dc.b 4+32,0
	  dc.l l96a0_T
	 dc.b 3,0
  	  dc.l l9550_SH
	 dc.b 7,0
	  dc.l l8fc3_R
	 dc.b 0,0


Sequence_ZH
	 dc.b 3,0
	  dc.l l9353_Y
	 dc.b 3+16,0
 	  dc.l l9550_SH
	 dc.b 0,0


Sequence_N
	 dc.b 1+32,0
	  dc.l l9863_Silence
	 dc.b 7,0
	  dc.l l9103_N
	 dc.b 1+32,0
	  dc.l l9863_Silence
	 dc.b 0,0


Sequence_B:
	 dc.b 3+32,0
 	  dc.l l9863_Silence
	 dc.b 1,0
	  dc.l l9212_B
	 dc.b 3+32,0
 	  dc.l l9863_Silence
	 dc.b 0,0

Sequence_V:
	 dc.b 5,0
	  dc.l l91c2_V
	 dc.b 1+16,0
 	  dc.l l9252_slashH
	 dc.b 0,0

Sequence_K
	 dc.b 3+32,0
	  dc.l l9863_Silence
	 dc.b 1,0
	  dc.l l8997_K
	 dc.b 3+32,0
	  dc.l l9863_Silence
	 dc.b 0,0

Sequence_P
	 dc.b 3+32,0
	  dc.l l9863_Silence
	 dc.b 1,0
	  dc.l l9292_P
	 dc.b 3+32,0
	  dc.l l9863_Silence
	 dc.b 0,0

Sequence_J
	 dc.b 3+32,0
	  dc.l l9863_Silence
	 dc.b 1,0
	  dc.l l9410_D
	 dc.b 4+16,0
	  dc.l l9550_SH
	 dc.b 0,0


Sequence_G
	 dc.b 3+32,0
	  dc.l l9863_Silence
	 dc.b 1,0
	  dc.l l9590_G
	 dc.b 3+32,0
	  dc.l l9863_Silence
;	 dc.w 0
		
l9863_Silence:					;Silence
	 dc.b $00,0
	even





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

l9392_IH
	 dc.b $a4,$58,$d5,$1f,$d7,$8f
	 dc.b $a5,$88,$84,$34,$8b,$34,$b6,$5a
	 dc.b $b7,$6c,$89,$89,$87,$55,$67,$44
	 dc.b $87,$58,$99,$89,$99,$99,$88,$86
	 dc.b $88,$65,$88,$98,$89,$ab,$9b,$b9
	 dc.b $89,$86,$58,$65,$55,$54,$55,$67
	 dc.b $66,$88,$66,$87,$55,$56,$64,$46
	 dc.b $75,$46,$84,$59,$75,$89,$74,$67
	; dc.b $74
l8958_A:
	 dc.b $74,$ff,$ff,$04,$30,$fb,$cf,$88
	 dc.b $88,$78,$45,$95,$cd,$6a,$44,$85
	 dc.b $aa,$68,$65,$76,$88,$88,$88,$68
	 dc.b $55,$86,$a9,$8a,$56,$65,$87,$a8
	 dc.b $cb,$8a,$56,$85,$ba,$8a,$78,$87
	 dc.b $88,$88,$66,$55,$76,$88,$56,$54
	 dc.b $65,$65,$56,$55,$44,$54,$66,$56
	 dc.b $55,$65,$56,$54,$86,$46;,$44
	
l9003_U:
	 dc.b $44,$54,$55,$55,$76
	 dc.b $b9,$fd,$ff,$ff,$ee,$de,$cd,$ab
	 dc.b $68,$45,$23,$32,$44,$44,$55,$76
	 dc.b $a9,$ba,$bb,$ab,$aa,$9a,$89,$68
	 dc.b $55,$44,$44,$54,$65,$66,$87,$98
	 dc.b $a9,$aa,$aa,$9a,$a9,$aa,$aa,$9a
	 dc.b $89,$88,$88,$88,$88,$66,$55,$55
	 dc.b $55,$55,$45,$44,$54,$55,$55,$45
	 dc.b $44;,$44
l9450_NX
	 dc.b $44,$a6,$aa,$bb,$cb,$bd,$bd,$ab
	 dc.b $aa,$ba,$9a,$89,$88,$88,$88,$66
	 dc.b $66,$66,$66,$67,$87,$78,$88,$88
	 dc.b $88,$66,$87,$77,$77,$77,$77,$88
	 dc.b $88,$88,$99,$aa,$aa,$aa,$aa,$99
	 dc.b $99,$99,$88,$88,$66,$66,$55,$55
	 dc.b $55,$55,$55,$55,$55,$55,$55,$55
	 dc.b $55,$55,$65,$56,$55;,$55,$55
l90c3_L
	 dc.b $55,$55,$75,$a8,$db
	 dc.b $fe,$ef,$be,$8b,$68,$55,$54,$54
	 dc.b $55,$55,$66,$87,$99,$aa,$ab,$aa
	 dc.b $89,$66,$55,$55,$55,$65,$76,$87
	 dc.b $88,$99,$99,$99,$9a,$99,$99,$98
	 dc.b $88,$88,$68,$67,$67,$77,$76,$66
	 dc.b $66,$66,$66,$66,$66,$66,$66,$66
	 dc.b $66,$66,$66,$66,$66,$66,$66,$66
	; dc.b $66,$66
	
l94d0_OH
	 dc.b $66,$66,$f7,$ff,$9e,$5b,$74
	 dc.b $88,$56,$54,$75,$db,$bd,$88,$46
	 dc.b $b1,$58,$45,$65,$b7,$cb,$8a,$68
	 dc.b $56,$76,$56,$54,$87,$ba,$ab,$78
	 dc.b $77,$66,$66,$56,$96,$da,$bd,$8b
	 dc.b $56,$75,$67,$76,$98,$9a,$88,$66
	 dc.b $65,$77,$66,$56,$66,$87,$66,$55
	 dc.b $65,$66,$56,$65,$66,$77,$88;,$67
	
l9720_DH
	 dc.b $67,$98,$99,$a9,$aa,$9a,$aa,$89
	 dc.b $88,$78,$67,$76,$67,$76,$87,$88
	 dc.b $99,$9a,$a9,$aa,$99,$99,$89,$77
	 dc.b $77,$77,$66,$76,$77,$77,$88,$88
	 dc.b $a9,$aa,$a9,$aa,$89,$88,$78,$77
	 dc.b $77,$66,$76,$77,$87,$99,$99,$a9
	 dc.b $aa,$99,$9a,$89,$88,$77,$66,$87
	 dc.b $99,$99,$aa,$aa,$a9,$9a;,$88
	

l96a0_T
	; dc.b $88
l96e0_TH
	 dc.b $88,$88,$87,$88,$79,$86,$88,$76
	 dc.b $86,$86,$66,$66,$76,$78,$98,$88
	 dc.b $8a,$99,$88,$89,$79,$7a,$8a,$99
	 dc.b $89,$a8,$98,$98,$68,$88,$89,$79
	 dc.b $78,$78,$88,$86,$88,$67,$68,$87
	 dc.b $87,$85,$67,$7a,$88,$8a,$8b,$9a
	 dc.b $a9,$99,$a9,$98,$a9,$a9,$a8,$98
	 dc.b $a8,$96,$86,$76,$76,$78;,$76

	
l93d0_D
	 dc.b $76,$66,$67,$66,$77,$87,$77,$89
	 dc.b $88,$89,$89,$89,$a8,$99,$9a,$a9
	 dc.b $9a,$ba,$9a,$9a,$a9,$89,$89,$88
	 dc.b $79,$87,$77,$67,$66,$67,$76,$76
	 dc.b $67,$77,$77,$88,$97,$89,$99,$99
	 dc.b $aa,$a9,$9a,$aa,$a9,$9a,$99,$89
	 dc.b $99,$87,$78,$77,$67,$77,$12,$66
	 dc.b $67,$66,$77,$87,$77,$89;,$88

l9292_P
	 dc.b $88,$99,$99,$a9,$da,$bc
	 dc.b $ed,$cd,$bb,$cc,$dc,$fd,$ff,$ff
	 dc.b $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	 dc.b $ff,$ff,$ff,$ff,$8c,$04,$00,$00
	 dc.b $00,$00,$00,$00,$00,$00,$00,$00
	 dc.b $10,$32,$45,$13,$00,$00,$00,$00
	 dc.b $00,$00,$00,$00,$00,$00,$00,$00
	 dc.b $10,$11,$10,$11,$11,$32,$54,$55
	; dc.b $76
	
l9590_G	;G
	 dc.b $76,$87,$88,$98,$99,$aa,$aa,$aa
	 dc.b $aa,$99,$89,$88,$88,$77,$66,$66
	 dc.b $55,$45,$41,$b7,$dc,$be,$99,$b9
	 dc.b $bb,$8a,$45,$43,$54,$55,$24,$42
	 dc.b $65,$76,$56,$54,$65,$77,$66,$86
	 dc.b $cb,$ed,$ce,$bb,$ba,$ab,$99,$68
	 dc.b $65,$66,$76,$86,$77,$87,$88,$89
	 dc.b $88,$78,$99,$99,$99,$98;,$99


l8997_K
	 dc.b $99
	 dc.b $58,$65,$88,$48,$a3,$ab,$76,$c9
	 dc.b $4a,$21,$84,$69,$44,$c7,$4a,$52
	 dc.b $a9,$48,$72,$ed,$8b,$78,$55,$24
	 dc.b $32,$f4,$cf,$10,$fb,$4f,$54,$98
	 dc.b $68,$74,$88,$56,$85,$89,$56,$87
	 dc.b $78,$76,$98,$99,$99,$89,$68,$76
	 dc.b $67,$65,$98,$78,$44,$54,$b8,$ab
	 dc.b $69,$55,$76,$88,$56;,$65
	
l9618_F
	 dc.b $65,$66,$6a,$66,$a7,$98,$66,$6a
	 dc.b $66,$a7,$a6,$67,$66,$68,$a6,$6a
	 dc.b $67,$a7,$98,$66,$66,$a7,$9a,$a5
	 dc.b $86,$66,$77,$68,$a6,$9a,$59,$66
	 dc.b $89,$a7,$89,$65,$68,$86,$a6,$76
	 dc.b $68,$86,$66,$aa,$68,$6a,$76,$86
	 dc.b $76,$7a,$66,$a6,$6a,$7a,$66,$a6
	 dc.b $8a,$76,$7a,$8a,$95,$6a,$a6


l92d2_W:
	 dc.b $44,$55,$76,$b9,$dc,$fe
	 dc.b $ff,$de,$cd,$ab,$9a,$88,$56,$45
	 dc.b $23,$22,$43,$54,$86,$98,$a9,$aa
	 dc.b $9a,$99,$99,$89,$88,$56,$45,$44
	 dc.b $54,$55,$66,$76,$87,$88,$98,$99
	 dc.b $99,$a9,$aa,$aa,$aa,$9a,$89,$78
	 dc.b $66,$66,$66,$66,$56,$55,$55,$55
	 dc.b $66,$66,$66,$56,$55,$55,$55,$55
;	 dc.b $55

l9353_Y
	 dc.b $55,$95,$54,$5c,$87
	 dc.b $a9,$a8,$ad,$bb,$bd,$9d,$9f,$ab
	 dc.b $ab,$8a,$8b,$88,$88,$46,$47,$44
	 dc.b $55,$44,$55,$40,$65,$55,$87,$86
	 dc.b $97,$88,$99,$98,$a9,$99,$9a,$98
	 dc.b $99,$98,$9a,$99,$99,$98,$8a,$88
	 dc.b $88,$78,$68,$66,$56,$55,$45,$54
	 dc.b $44,$54,$44,$55,$54,$55,$44,$64
	 dc.b $54,$47
	


l9761_UU
	 dc.b $d6,$fc,$cd,$9c,$88,$88,$56
	 dc.b $44,$76,$ba,$ab,$99,$89,$78,$56
	 dc.b $44,$65,$98,$99,$99,$99,$89,$56
	 dc.b $45,$64,$87,$88,$98,$99,$99,$68
	 dc.b $55,$65,$86,$a9,$bb,$ab,$8a,$68
	 dc.b $56,$66,$87,$88,$88,$78,$56,$55
	 dc.b $55,$55,$65,$66,$66,$56,$66,$55
	 dc.b $55,$56,$45,$65,$87,$88,$66;,$55


l97e3_EH
	 dc.b $55,$87,$f4,$8f,$95
	 dc.b $8f,$23,$67,$86,$75,$fb,$79,$b8
	 dc.b $29,$53,$76,$66,$b8,$9c,$78,$88
	 dc.b $45,$65,$87,$97,$aa,$89,$87,$56
	 dc.b $55,$76,$88,$99,$8a,$68,$66,$55
	 dc.b $76,$ab,$98,$ba,$58,$65,$56,$76
	 dc.b $99,$89,$88,$68,$55,$66,$66,$98
	 dc.b $88,$77,$66,$55,$56,$66,$66,$86
	 dc.b $57,$87

l8fc3_R:
	 dc.b $44,$75,$ea,$ff,$ac
	 dc.b $da,$ee,$5a,$32,$65,$56,$55,$76
	 dc.b $ba,$cd,$8b,$87,$99,$48,$22,$53
	 dc.b $77,$66,$97,$aa,$ab,$8a,$66,$76
	 dc.b $57,$44,$75,$98,$88,$98,$aa,$bb
	 dc.b $ab,$89,$87,$88,$56,$75,$88,$88
	 dc.b $88,$88,$68,$56,$55,$55,$55,$55
	 dc.b $55,$66,$56,$66,$56,$55,$55,$44
	 dc.b $65;,$66


l8f83_AI:		
	 dc.b $66,$96,$b8,$ff,$cb
	 dc.b $fb,$9a,$85,$73,$78,$58,$ba,$9d
	 dc.b $99,$89,$88,$44,$64,$58,$86,$a9
	 dc.b $aa,$88,$86,$58,$54,$76,$87,$88
	 dc.b $99,$9a,$78,$88,$67,$66,$86,$88
	 dc.b $9a,$ca,$aa,$a8,$88,$86,$76,$88
	 dc.b $89,$88,$89,$67,$66,$65,$65,$65
	 dc.b $66,$66,$66,$56,$55,$55,$55,$44
	 dc.b $77,$68
	

l9103_N
	 dc.b $55,$66,$66,$76,$9a
	 dc.b $a6,$bb,$cb,$bb,$de,$ed,$dd,$dd
	 dc.b $bc,$bc,$ba,$9a,$99,$78,$68,$66
	 dc.b $56,$55,$55,$55,$55,$55,$66,$65
	 dc.b $66,$76,$77,$88,$88,$88,$98,$99
	 dc.b $aa,$aa,$aa,$ba,$ba,$ab,$aa,$aa
	 dc.b $99,$89,$88,$68,$66,$55,$55,$44
	 dc.b $44,$44,$44,$44,$44,$44,$54,$45
	; dc.b $55,$65

l9043_AO:
	 dc.b $55,$65,$66,$67,$87
	 dc.b $b9,$ec,$ff,$ff,$cf,$8a,$24,$01
	 dc.b $31,$75,$da,$fe,$ff,$ce,$8a,$56
	 dc.b $44,$54,$65,$88,$99,$aa,$aa,$bb
	 dc.b $bb,$aa,$89,$57,$45,$54,$75,$a8
	 dc.b $cb,$dd,$dd,$bc,$9a,$68,$56,$55
	 dc.b $65,$87,$a9,$bb,$bb,$9a,$88,$66
	 dc.b $55,$55,$66,$87,$98,$99,$99,$88
	 dc.b $67,$56	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

l89d7_T
	 dc.b $96
	 dc.b $78,$78,$b9,$b8,$78,$89,$76,$65
	 dc.b $78,$4b,$87,$75,$8b,$b5,$76,$a8
	 dc.b $a9,$44,$5d,$49,$8b,$83,$95,$78
	 dc.b $1a,$6c,$7a,$c2,$b4,$55,$7b,$85
	 dc.b $a8,$78,$98,$85,$87,$c4,$85,$85
	 dc.b $3b,$b8,$47,$78,$a4,$94,$68,$87
	 dc.b $66,$7a,$7a,$89,$67,$c8,$a6,$83
	 dc.b $7b,$c5,$c1,$b4,$98,$87

l8f43_AA:
	 dc.b $96,$ee,$ff,$ed,$44
	 dc.b $10,$52,$d9,$ef,$bd,$58,$45,$66
	 dc.b $86,$88,$77,$a8,$ba,$9b,$48,$44
	 dc.b $53,$a7,$cb,$ab,$68,$55,$65,$87
	 dc.b $99,$89,$88,$88,$a9,$99,$88,$78
	 dc.b $98,$a9,$99,$78,$66,$87,$98,$88
	 dc.b $68,$66,$76,$88,$88,$78,$67,$66
	 dc.b $66,$66,$66,$66,$76,$77,$66,$67
	 dc.b $67,$87
	


l9083_EE
	 dc.b $35,$43,$07,$e1,$a4
	 dc.b $79,$bd,$e8,$fd,$da,$cf,$db,$fb
	 dc.b $9a,$ab,$68,$96,$45,$54,$25,$52
	 dc.b $44,$54,$56,$65,$87,$76,$9a,$98
	 dc.b $aa,$99,$aa,$89,$a9,$89,$88,$68
	 dc.b $86,$68,$65,$67,$85,$77,$79,$a9
	 dc.b $87,$aa,$aa,$9a,$a9,$98,$88,$88
	 dc.b $67,$66,$55,$55,$55,$54,$55,$44
	 dc.b $45,$54



l9142_M
	 dc.b $32,$43,$34,$43,$44,$55
	 dc.b $55,$65,$76,$b9,$a8,$9a,$bb,$cd
	 dc.b $dd,$dd,$ee,$ed,$dd,$dc,$bb,$ab
	 dc.b $99,$89,$88,$66,$56,$55,$45,$44
	 dc.b $54,$55,$55,$55,$65,$66,$87,$88
	 dc.b $88,$99,$99,$aa,$aa,$ba,$ab,$bb
	 dc.b $ab,$bb,$bb,$aa,$9a,$89,$88,$78
	 dc.b $66,$56,$55,$44,$44,$34,$33,$33
	 dc.b $34

l9182_AH:
	 dc.b $55,$d7,$ff,$bf,$49,$33
	 dc.b $67,$68,$89,$a9,$dd,$8b,$24,$22
	 dc.b $95,$aa,$9a,$89,$99,$58,$34,$54
	 dc.b $a7,$bb,$8a,$68,$66,$66,$65,$97
	 dc.b $ba,$ab,$68,$55,$76,$98,$89,$98
	 dc.b $88,$68,$56,$75,$88,$89,$68,$66
	 dc.b $66,$66,$66,$76,$88,$67,$56,$55
	 dc.b $76,$67,$76,$66,$77,$66,$66,$56
	 dc.b $66

l91c2_V:
	 dc.b $99,$99,$99,$78,$77,$77
	 dc.b $67,$66,$77,$77,$77,$98,$99,$99
	 dc.b $a9,$aa,$99,$99,$99,$78,$77,$77
	 dc.b $67,$66,$77,$77,$77,$98,$99,$99
	 dc.b $a9,$aa,$89,$99,$99,$99,$aa,$9a
	 dc.b $99,$99,$89,$77,$77,$77,$66,$76
	 dc.b $77,$77,$87,$99,$99,$99,$aa,$9a
	 dc.b $99,$99,$89,$77,$77,$77,$66,$76
	 dc.b $77

l9212_B	;B
	 dc.b $86,$88,$98,$88,$88,$88
	 dc.b $99,$89,$88,$88,$88,$88,$99,$88
	 dc.b $88,$98,$99,$88,$88,$88,$88,$88
	 dc.b $88,$88,$88,$88,$88,$78,$88,$87
	 dc.b $77,$77,$88,$88,$77,$87,$88,$88
	 dc.b $77,$66,$66,$66,$56,$55,$55,$55
	 dc.b $66,$b8,$fe,$ff,$ce,$9a,$89,$48
	 dc.b $24,$01,$20,$55,$66,$56,$55,$55
	 dc.b $24

l9252_slashH
	 dc.b $88,$88,$68,$86,$78,$97
	 dc.b $89,$88,$76,$76,$88,$89,$99,$88
	 dc.b $68,$56,$87,$99,$a9,$89,$66,$56
	 dc.b $76,$88,$88,$89,$78,$77,$88,$88
	 dc.b $99,$88,$68,$55,$75,$a9,$9a,$89
	 dc.b $68,$55,$66,$86,$a9,$9a,$88,$56
	 dc.b $86,$88,$88,$68,$75,$77,$98,$aa
	 dc.b $98,$89,$58,$55,$66,$b9,$ab,$8a
	 dc.b $58

	
l9311_A
	 dc.b $45,$b6,$ff,$a5,$fb,$6a,$84
	 dc.b $95,$56,$73,$d9,$69,$b8,$8c,$56
	 dc.b $66,$67,$44,$a6,$8a,$96,$aa,$68
	 dc.b $65,$76,$46,$75,$99,$88,$a9,$8a
	 dc.b $67,$76,$67,$65,$97,$88,$d2,$9a
	 dc.b $a9,$a9,$59,$65,$89,$55,$98,$88
	 dc.b $67,$66,$46,$54,$66,$55,$66,$55
	 dc.b $86,$56,$76,$56,$55,$56,$65,$45


	
l9410_D
	 dc.b $3a,$fb,$98,$6c,$a9,$a5,$5a,$89
	 dc.b $a8,$58,$67,$67,$55,$55,$66,$56
	 dc.b $76,$88,$76,$86,$87,$54,$55,$47
	 dc.b $55,$85,$65,$66,$88,$8a,$a8,$aa
	 dc.b $89,$98,$89,$67,$88,$89,$98,$ba
	 dc.b $ab,$ba,$bc,$ab,$aa,$aa,$78,$87
	 dc.b $78,$66,$86,$88,$87,$98,$88,$77
	 dc.b $78,$56,$55,$56,$44,$54,$45


l94d0_OO
	 dc.b $95,$db,$ff,$ff,$4a,$02,$00,$73
	 dc.b $fb,$ff,$af,$48,$23,$42,$75,$88
	 dc.b $99,$98,$aa,$aa,$68,$25,$22,$53
	 dc.b $b8,$ed,$bd,$69,$24,$32,$75,$a9
	 dc.b $ab,$9a,$88,$88,$a9,$89,$67,$66
	 dc.b $87,$89,$89,$69,$67,$66,$66,$66
	 dc.b $55,$66,$86,$78,$66,$55,$55,$55
	 dc.b $66,$66,$66,$66,$66,$66,$56

l9510_ER
	 dc.b $67,$d7,$ff,$ab,$cb,$ac,$89,$26
	 dc.b $52,$87,$56,$86,$ba,$cb,$8b,$76
	 dc.b $88,$48,$44,$55,$76,$89,$88,$b9
	 dc.b $ab,$88,$67,$66,$66,$45,$75,$98
	 dc.b $99,$99,$99,$ba,$8a,$87,$88,$78
	 dc.b $77,$76,$98,$89,$87,$88,$78,$66
	 dc.b $55,$65,$66,$65,$66,$66,$66,$56
	 dc.b $65,$56,$55,$65,$56,$66,$66

l9550_SH
	 dc.b $8b,$43,$97,$3b,$93,$4c,$55,$3f
	 dc.b $74,$59,$58,$c8,$03,$c7,$26,$c3
	 dc.b $18,$77,$7a,$34,$c9,$82,$a1,$2b
	 dc.b $81,$2d,$76,$a8,$38,$78,$7a,$e0
	 dc.b $48,$a6,$83,$47,$3b,$a5,$3a,$85
	 dc.b $3b,$98,$64,$89,$56,$b8,$88,$83
	 dc.b $67,$87,$27,$77,$0d,$73,$5e,$72
	 dc.b $cc,$70,$d8,$44,$47,$59,$98

l95d0_Z
	 dc.b $b6,$75,$5a,$4b,$99,$b5,$58,$5b
	 dc.b $89,$a6,$96,$68,$88,$a6,$78,$4a
	 dc.b $8b,$a5,$a5,$4a,$4b,$b7,$b4,$7a
	 dc.b $4c,$87,$c3,$78,$2c,$4b,$c5,$a4
	 dc.b $3a,$5b,$99,$95,$88,$49,$b7,$b4
	 dc.b $68,$8a,$a7,$b5,$78,$4c,$9a,$a5
	 dc.b $78,$5a,$87,$b5,$78,$5c,$6b,$a6
	 dc.b $78,$5a,$a7,$b3,$58,$2d,$89

l9823_UH
	 dc.b $21,$32,$44,$44,$64
	 dc.b $86,$aa,$9a,$77,$b9,$fd,$ff,$cd
	 dc.b $ba,$cb,$cb,$8a,$55,$65,$a7,$aa
	 dc.b $89,$98,$b9,$cc,$ab,$68,$66,$88
	 dc.b $78,$57,$55,$97,$ba,$ab,$9a,$99
	 dc.b $aa,$9a,$68,$66,$86,$98,$99,$db
	 dc.b $fd,$ff,$df,$ab,$89,$88,$68,$55
	 dc.b $55,$76,$88,$78,$56,$66,$66,$56
	 dc.b $34,$22

	even
	ifnd BuildNEO			;NeoGeo Doesn't use font
Font:
	incbin "\ResALL\Font96.FNT"
	endif
	
	
	include "\SrcALL\V1_RamArea.asm"
	
	ifd BuildAMI
WaveSample: dc.w 0	
	endif
	
	
	include "\SrcALL\V1_Footer.asm"
	