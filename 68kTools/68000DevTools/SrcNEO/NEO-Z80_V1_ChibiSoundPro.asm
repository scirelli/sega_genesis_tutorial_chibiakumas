
ChibiOctive:
	;   E     F     G      A     B     C     D   
	dw &3000,&4000,&5000,&6000,&7000,&8000,&9000 ;0
	dw &A1A6,&A6CB,&B096,&B8F4,&C097,&C446,&CAD4 ;1
	dw &D09A,&D32A ,&D816,&DC76,&E058,&E218,&E55B;2
	dw &E843,&E9A7,&EC11,&EE31,&F029,&F10D,&F2AA ;3
	dw &F414,&F4CC,&F60C,&F71C,&F819,&F889,&F95A ;4
	dw &FA04,&FA6C,&FAF3,&FB8E,&FC0C,&FC3E,&FCAC;5
	dw &FCF8,&FD2E,&FD79,&FDCA,&FDFC,&FE1A,&FE4D ;6
	dw &FE40,&FEC0,&FF00,&FF40,&FF80,&FFC0,&FFFF

	
	
;Rules for a ChibiSound V1 Driver:
; No use of shadow registers	
; IX,IY must not be used
; AF/BC/DE/HL all can change during function
; Set may update sound directly, or Update may depending on system
; Octicve lookup mist be provided
; Must function for channel numbers 0-7 (0=highest priority)
	;Channel 1+ can be ignored if preferred
	
;Rules for a ChibiSound V1.2 Driver:
; IX/IY can be used for platform specific functions like Envelope
	
;H=Volume (0-255) 
;L=Channel Num (0-127 unused channels will wrap around) / Top Bit=Noise
;DE=Pitch (0-65535)
ChibiSoundPro_Init:	
	ld a,%10111111		;Set up port directions
	ld (AYCache+7),a
	ret
	
ChibiSoundPro_Set:			
;Channel Remap
	ld a,l
	and %10000000	;Noise bit
	ld c,a
	push hl
		ld a,l
		and %00000111
		ld hl,ChannelMap
		add l
		ld l,a
		ld a,(hl)		;Channel mapping
	pop hl
	or c
	ld l,a
	
	ld a,h
	or a
	jp z,silentPro		;Zero turns off sound

	ifdef ChibiSound_Envelopes
		ld a,ixl
		bit 7,a
		jr z,ChibiSoundProNoEnv

		and %00001111
		ld c,a
		ld a,13
		call AYRegWritePro	
		ld c,0
		ld a,12
		call AYRegWritePro
		ld a,ixh
		ld c,a
		ld a,11
		call AYRegWritePro
	
		ld l,2
		jr ChibiSoundProChannelOK
	
ChibiSoundProNoEnv:				
	endif

	ld a,d 
	cpl
	ld d,a
	ld a,e
	cpl
 	ld e,a
	inc de

	srl d		;Ditch bottom 4 bits
	rr e
	srl d
	rr e
	srl d
	rr e
	srl d
	rr e

	ld c,e
	ld a,l			;TTTTTTTT Tone Lower 8 bits	B
	and %00000011
	rlca
	push af
		call AYRegWritePro

		ld c,d
	pop af
				;----TTTT Tone Upper 4 bits
	inc a
	call AYRegWritePro
	
	bit 7,l			;Noise bit N-------
	jr z,AYNoNoisePro
	push de
		call DoChannelMask
		and %00111111
		cpl
		ld d,a
		ld a,(bc)
		and d		;noise and tone on
		ld c,a
		ld a,7
		call AYRegWritePro
	pop de

	sla e
	rl d
	ld a,d
	and %00011111
	ld c,a
	ld a,6			;Noise ---NNNNN
	call AYRegWritePro

	jr AYMakeTonePro
AYNoNoisePro:
	call DoChannelMask
 	and %00111000
	ld e,a

	ld a,d
	and %00000111
	cpl
	ld d,a

	ld a,(bc)
	and d			;Tone on
	or e			;Noise Off
	ld c,a

	ld a,7			;Mixer  --NNNTTT (1=off) --CBACBA
	call AYRegWritePro
;	jr AYMakeTone
AYMakeTonePro:
	ld c,h	;VVVVVVVV = Volume bits
	srl c
	srl c
	srl c
	srl c

	ifdef ChibiSound_Envelopes	
		ld a,ixl
		bit 7,a
		jr z,AYMakeTone_EnvOff
		set 4,c			;Turn Envelope on
AYMakeTone_EnvOff:
	endif
	
	ld a,l			;4-bit Volume / 1-bit Envelope Select for channel A ---EVVVV
	and %00000011
	add 8			;Channel num 8,9,10
	jp AYRegWritePro



DoChannelMask:
	ld bc,ChannelMask
	ld a,l
	and %00000011
	add c
	ld c,a
	ld a,(bc)
	ld d,a
	ld bc,AYCache+7

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

silentPro:
	;ld c,0
	;ld a,l			;4-bit Volume / 1-bit Envelope Select for channel A ---EVVVV
	;and %00000011
	;add 8			;Channel num 8,9,10
	;jp AYRegWritePro
	;ret
	
	call DoChannelMask
	and %00111111
	ld d,a

	ld a,(bc)
	or d
	
	ld c,a
	ld a,7			;Mixer  --NNNTTT (1=off) --CBACBA		
	jp AYRegWritePro				
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AYRegNochange:
	pop af
	pop hl
	ret

AYRegWritePro:
	push hl
	push af
		ld hl,AYCache
		add l
		ld l,a
		ld a,(hl)
		cp c
		jr z,AYRegNochange
		ld (hl),c
	pop af
	pop hl

	out (4),a	;regnum
	ld a,c
	out (5),a	;value
	ret



	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ifdef VASM
		align 4
	else
		align 16
	endif

	ifndef AYCache
		ifdef ChibiSoundRam
AYCache equ ChibiSoundRam+64	;First 64 bytes reserved for tracker
		else
AYCache: ds 16
		endif 
	endif
ChannelMap:	db 1,0,2,0,2,0,2,0
ChannelMask:	db %00001001,%00010010,%00100100,0

