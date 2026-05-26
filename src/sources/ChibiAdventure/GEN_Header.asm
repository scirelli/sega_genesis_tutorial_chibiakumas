	
FileZero:

ramarea equ $00FFE000	;Define some space for program vars
						;First 16 bytes reserved for core.
;Video Ports

VDP_data equ $C00000	; VDP data, R/W word or longword access only
VDP_ctrl equ $C00004	; VDP control, word or longword writes only


;Traps

	DC.L	$00000000		;SP register value
	DC.L	ProgramStart	;Start of Program Code
	DS.L	7,IntReturn		; bus err,addr err,illegal inst,divzero,CHK,TRAPV,priv viol
	DC.L	IntReturn		; TRACE
	DC.L	IntReturn		; Line A (1010) emulator
	DC.L	IntReturn		; Line F (1111) emulator
	DS.L	4,IntReturn		; Reserverd /Coprocessor/Format err/ Uninit Interrupt
	DS.L	8,IntReturn		; Reserved
	DC.L	IntReturn		; spurious interrupt
	DC.L	IntReturn		; IRQ level 1
	DC.L	IntReturn		; IRQ level 2 EXT
	DC.L	IntReturn		; IRQ level 3
	DC.L	IntReturn		; IRQ level 4 Hsync
	DC.L	IntReturn		; IRQ level 5
	DC.L	IntReturn		; IRQ level 6 Vsync
	DC.L	IntReturn		; IRQ level 7 
	DS.L	16,IntReturn	; TRAPs
	DS.L	16,IntReturn	; Misc (FP/MMU)

;Header

	DC.B	"SEGA GENESIS    "	;System Name
	DC.B	"(C)CHBI "			;Copyright
 	DC.B	"2024.JAN"			;Date
	DC.B	"ChibiAkumas.com                                 " ; Cart Name
	DC.B	"ChibiAkumas.com                                 " ; Cart Name (Alt)
	DC.B	"GM CHIBI001-00"	;TT NNNNNNNN-RR T=Type (GM=Game) N=game Num  R=Revision
	DC.W	$0000				;16-bit Checksum (Address $000200+)
	DC.B	"J               "	;Control Data (J=3button K=Keyboard 6=6button C=cdrom)
	DC.L	$00000000			;ROM Start
	DC.L	$003FFFFF			;ROM Length
	DC.L	$00FF0000,$00FFFFFF	;RAM start/end (fixed)
	DC.B	"            "		;External RAM Data
	DC.B	"            "		;Modem Data
	DC.B	"                                        " ;MEMO
	DC.B	"JUE             "	;Regions Allowed

IntReturn:
	rte						;Generic Interrupt Handler

	
ProgramStart:

;initialize TMSS (TradeMark Security System)

	move.b ($A10001),D0		;A10001 test the hardware version
	and.b #$0F,D0
	beq	NoTmss				;branch if no TMSS chip
	move.l #'SEGA',($A14000);disable TMSS
NoTmss:


;Set Up Graphics

	lea VDPSettings,A5		;Initialize Screen Registers
	move.l #VDPSettingsEnd-VDPSettings,D1 ;length of Settings
	
	move.w (VDP_ctrl),D0	;C00004 read VDP status (interrupt acknowledge?)
	move.w #$8000,d5	;VDP Reg command (%8rvv)
	
NextInitByte:
	move.b (A5)+,D5			;get next video control byte
	move.w D5,(VDP_ctrl)	;C00004 send write register command to VDP
		;   8RVV - R=Reg V=Value
	add.w #$0100,D5			;point to next VDP register
	dbra D1,NextInitByte	;loop for rest of block


;Set up Font

	lea Font,A1					 ;Font Address in ROM
	move.l #(Font_End-Font)/2,d6 ;Length in words
	
	move.l #$40000000,(VDP_Ctrl);Start writes to address $0000
								;(Patterns in Vram)
NextFont:
	move.w (A1)+,(VDP_Data)	
	dbra d6,NextFont			;Loop until done


;Set up palette
	
	move.l #$C0000000,(VDP_Ctrl)	;Color 0
	;       %----BBB-GGG-RRR-
	move.w #%0000000000000000,(VDP_data)
			
	move.l #$C0020000,(VDP_Ctrl)	;Color 1
	move.w #%0000101000001010,(VDP_data)
	
	move.l #$C0040000,(VDP_Ctrl)	;Color 2
	move.w #%0000111011100000,(VDP_data)
	
	move.l #$C0060000,(VDP_Ctrl)	;Color 3
	move.w #%0000111011101110,(VDP_data)
	
;Turn on screen

	move.w	#$8144,(VDP_Ctrl);C00004 reg 1 = 0x44 unblank display	
		
	jsr ClearRam			;Clear first 256 bytes of ram, and CLS

	