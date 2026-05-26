
;UseHsprite equ 1


	

	ifd UseHsprite
	
PatternData equ $2000		
PatternFill equ $1F00

PatternDoubleHeight equ $2000	;offset

ScreenBase equ 0
	else
	
PatternData equ $1200		;PTTT Palette+Tile
PatternFill equ $11C0

PatternXflip equ $0200		;Offsets
PatternYflip equ $0400
PatternXYflip equ $0600
PatternDoubleHeight equ $0800

ScreenBase equ $7000+4+(32*4)
	endif


MaxTileData equ $100000

	include "\SrcAll\BasicMacros.asm"
		
;tiletest_basiconly equ 1
;slowdowntest equ 1


;patterndata equ 8
;PatternFill equ 0


;TestChibiko equ 16+1
;TestSprite equ 0



DoubleBuffered equ 1
						
CacheAddr1 equ MaxTileData+$0000
CacheAddr2 equ MaxTileData+$0200
CacheAddr3 equ MaxTileData+$0400


CacheTable equ MaxTileData+$0600
	ifnd DoubleBuffered
CacheTable_Last equ T_CacheTable_Last-T_CacheTable +CacheTable
CacheTable_End equ T_CacheTable_End-T_CacheTable +CacheTable
	endif
Vline equ CacheTable+32;  db 0		;For Screen Draw Sync to crt line
CropYH	equ Vline+2;: dw 0
CropXW equ CropYH+2 ;: dw 0

BackgroundTilemapBase equ CropXW+2;: dw BackgroundTilemap2+2
BackgroundTilemapWidth equ BackgroundTilemapBase+4;:	db 36*2
BackgroundTilemapScrollX equ BackgroundTilemapWidth+2;: db 0
BackgroundTilemapScrollY equ BackgroundTilemapScrollX+2;: db 0
TileTmpW equ BackgroundTilemapScrollY+2 ;: dw 0
SPrestore equ TileTmpW+2
CacheTableAddr equ  SPrestore+2 ;: dw CacheTable
	
BackgroundTilemap2 equ MaxTileData+$0800	;36*28*2+4


;Logical units are pairs of pixels

;UseStackMisuse equ 1

VscreenMinX equ 64		;Top left of visible screen in logical co-ordinates
VscreenMinY equ 80

;VscreenWid equ 24		;Visible Screen Size in logical units
;VscreenHei equ 24

;LIMITATION.. The Virtual screen cannot be smaller than the sprite or 
;the crop will malfunction! (It can be the same size)

VscreenWid equ 128		;Visible Screen Size in logical units
VscreenHei equ 96

	
VscreenWidClip equ 2	;alter right boundary due to working in words
VscreenHeiClip equ 0



allowquartertilescroll equ 1
allowhalftilescroll equ 1

hiresx equ 1
hiresy equ 1

BackgroundTilemapWidthV equ 36



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	



;Ram Variables

flag_VBlank	equ  $100600   	;(byte) vblank flag in ram


; This Header is based on the work from 
; "Neo-Geo Assembly Programming for the Absolute Beginner" by freem
; http://ajworld.net/neogeodev/beginner/

	
	dc.l	$0010F300		; Initial Supervisor Stack Pointer (SSP)
	dc.l	$00C00402		; Initial PC			(BIOS $C00402)
	dc.l	$00C00408		; Bus error/Monitor		(BIOS $C00408)
	dc.l	$00C0040E		; Address error			(BIOS $C0040E)
	dc.l	$00C00414		; Illegal Instruction	(BIOS $C00414)
	dc.l	$00C00426		; Divide by 0
	dc.l	$00C00426		; CHK Instruction
	dc.l	$00C00426		; TRAPV Instruction
	dc.l	$00C0041A		; Privilege Violation	(BIOS $C0041A)
	dc.l	$00C00420		; Trace					(BIOS $C00420)
	dc.l	$00C00426		; Line 1010 Emulator
	dc.l	$00C00426		; Line 1111 Emulator
	dc.l	$00C00426		; Reserved
	dc.l	$00C00426		; Reserved
	dc.l	$00C00426		; Reserved
	dc.l	$00C0042C		; Uninitialized Interrupt Vector

	dc.l	$00C00426		; Reserved
	dc.l	$00C00426		; Reserved
	dc.l	$00C00426		; Reserved
	dc.l	$00C00426		; Reserved
	dc.l	$00C00426		; Reserved
	dc.l	$00C00426		; Reserved
	dc.l	$00C00426		; Reserved
	dc.l	$00C00426		; Reserved
	dc.l	$00C00432		; Spurious Interrupt
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 									Interrupts
	dc.l	VBlank			; Level 1 interrupt (VBlank)
	dc.l	IRQ2			; Level 2 interrupt (HBlank)
	dc.l	IRQ3			; Level 3 interrupt
	dc.l	$00000000		; Level 4 interrupt
	dc.l	$00000000		; Level 5 interrupt
	dc.l	$00000000		; Level 6 interrupt
	dc.l	$00000000		; Level 7 interrupt (NMI)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;									 Traps
	dc.l	$FFFFFFFF		; TRAP #0 Instruction
	dc.l	$FFFFFFFF		; TRAP #1 Instruction
	dc.l	$FFFFFFFF		; TRAP #2 Instruction
	dc.l	$FFFFFFFF		; TRAP #3 Instruction
	dc.l	$FFFFFFFF		; TRAP #4 Instruction
	dc.l	$FFFFFFFF		; TRAP #5 Instruction
	dc.l	$FFFFFFFF		; TRAP #6 Instruction
	dc.l	$FFFFFFFF		; TRAP #7 Instruction
	dc.l	$FFFFFFFF		; TRAP #8 Instruction
	dc.l	$FFFFFFFF		; TRAP #9 Instruction
	dc.l	$FFFFFFFF		; TRAP #10 Instruction
	dc.l	$FFFFFFFF		; TRAP #11 Instruction
	dc.l	$FFFFFFFF		; TRAP #12 Instruction
	dc.l	$FFFFFFFF		; TRAP #13 Instruction
	dc.l	$FFFFFFFF		; TRAP #14 Instruction
	dc.l	$FFFFFFFF		; TRAP #15 Instruction
	dc.l	$FFFFFFFF		; Reserved
	dc.l	$FFFFFFFF		; Reserved
	dc.l	$FFFFFFFF		; Reserved
	dc.l	$FFFFFFFF		; Reserved
	dc.l	$FFFFFFFF		; Reserved
	dc.l	$FFFFFFFF		; Reserved
	dc.l	$FFFFFFFF		; Reserved
	dc.l	$FFFFFFFF		; Reserved
	dc.l	$FFFFFFFF		; Reserved
	dc.l	$FFFFFFFF		; Reserved
	dc.l	$FFFFFFFF		; Reserved
	dc.l	$FFFFFFFF		; Reserved
	dc.l	$FFFFFFFF		; Reserved
	dc.l	$FFFFFFFF		; Reserved
	dc.l	$FFFFFFFF		; Reserved
	dc.l	$FFFFFFFF		; Reserved
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;							Cart Header
	dc.b "NEO-GEO"
	dc.b $00 			;System Version (0=cart; 1/2 are used for CD games)
	dc.w $0FFF 			;NGH number ($0000 is prohibited)
	dc.l $00080000 		;game prog size in bytes (4Mbits/512KB)
	dc.l $00108000 		;pointer to backup RAM block (first two bytes are debug dips)
	dc.w $0000 			;game save size in bytes
	dc.b $00 			;Eye catcher anim flag (0=BIOS,1=game,2=nothing)
	dc.b $00 			;Sprite bank for eyecatch if done by BIOS
	dc.l softDips_All  	;Software dips for Japan
	dc.l softDips_All   ;Software dips for USA
	dc.l softDips_All 	;Software dips for Europe
	jmp USER 			; $122
	jmp PLAYER_START 	; $128
	jmp DEMO_END 		; $12E
	jmp COIN_SOUND 		; $134

	dc.l $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
	dc.l $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
	dc.l $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
	dc.l $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
	dc.l $FFFFFFFF,$FFFFFFFF

	;org $00000182
	dc.l TRAP_CODE 				;pointer to TRAP_CODE

	; security code required by Neo-Geo games
TRAP_CODE:
	dc.l $76004A6D,$0A146600,$003C206D,$0A043E2D
	dc.l $0A0813C0,$00300001,$32100C01,$00FF671A
	dc.l $30280002,$B02D0ACE,$66103028,$0004B02D
	dc.l $0ACF6606,$B22D0AD0,$67085088,$51CFFFD4
	dc.l $36074E75,$206D0A04,$3E2D0A08,$3210E049
	dc.l $0C0100FF,$671A3010,$B02D0ACE,$66123028
	dc.l $0002E048,$B02D0ACF,$6606B22D,$0AD06708
	dc.l $588851CF,$FFD83607
	dc.w $4E75
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 				Software Dip Switches (a.k.a. "soft dip")
softDips_All:
	dc.b "EXAMPLE SET A   " 		; Game Name
	dc.w $FFFF 						; Special Option 1
	dc.w $FFFF 						; Special Option 2
	dc.b $FF 						; Special Option 3
	dc.b $FF 						; Special Option 4
	dc.b $02 						; Option 1: 2 choices, default #0
	dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00 ; filler
	dc.b "OPTION 1A   " 			; Option 1 description
	dc.b "CHOICE1 A   " 			; Option choices
	dc.b "CHOICE2 A   "

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 									USER
; Needs to perform actions according to the value in BIOS_USER_REQUEST.
; Must jump back to SYSTEM_RETURN at the end so the BIOS can have control.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

USER:	
	move.b	d0,$300001			;Kick watchdog
	lea		$10F300,sp			;Set stack pointer to BIOS_WORKRAM
	move.w	#0,$3C0006			;LSPC_MODE - Disable auto-animation, timer interrupts
									;set auto-anim speed to 0 frames
	move.w	#7,$3C000C			;LSPC_IRQ_ACK - acknowledge all IRQs

	move.w	#$2000,sr			; Enable VBlank interrupt, go Supervisor

	; Handle user request
	moveq	#0,d0
	move.b	($10FDAE).l,d0		;BIOS_USER_REQUEST
	lsl.b	#2,d0				; shift value left to get offset into table
	lea		cmds_USER_REQUEST,a0
	movea.l	(a0,d0),a0
	jsr		(a0)
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 							BIOS_USER_REQUEST commands

cmds_USER_REQUEST:
	dc.l	userReq_StartupInit	; Command 0 (Initialize)
	dc.l	userReq_StartupInit	; Command 1 (Custom eyecatch)
	dc.l	userReq_Game		; Command 2 (Demo Game/Game)
	dc.l	userReq_Game		; Command 3 (Title Display)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 							userReq_StartupInit

userReq_StartupInit:
	move.b	d0,$300001		;REG_DIPSW - kick watchdog
	jmp		$C00444			;SYSTEM_RETURN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;				Handle Interrupts and system events	
	
PLAYER_START:					;Player pressed start on title
	move.b	d0,$300001;REG_DIPSW		; kick the watchdog
	rts
	
COIN_SOUND:					
DEMO_END:						
	rts

VBlank:
	btst	#7,$10FD80			;BIOS_SYSTEM_MODE - check if the BIOS wants to run its vblank
	bne		gamevbl
	jmp		$C00438				;SYSTEM_INT1 - run BIOS vblank
gamevbl:						;run the game's vblank
	movem.l d0-d7/a0-a6,-(sp)	;save registers
		move.w	#4,$3C000C		;LSPC_IRQ_ACK - acknowledge the vblank interrupt
		move.b	d0,$300001		;REG_DIPSW - kick the watchdog	
		jsr		$C0044A 		;"Call SYSTEM_IO every 1/60 second."
		jsr		$C004CE			;Puzzle Bobble calls MESS_OUT just after SYSTEM_IO
		move.b	#0,flag_VBlank	;clear vblank flag so waitVBlank knows to stop
	movem.l (sp)+,d0-d7/a0-a6	;restore registers
	rte

IRQ2:
	move.w	#2,$3C000C		;LSPC_IRQ_ACK - ack. interrupt #2 (HBlank)
	move.b	d0,$300001		;REG_DIPSW - kick watchdog
	rte
IRQ3:
	move.w  #1,$3C000C		;LSPC_IRQ_ACK - acknowledge interrupt 3
	move.b	d0,$300001		;REG_DIPSW - kick watchdog
	rte
	 	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 							UserReq_Game

userReq_Game:
	move.b	d0,$300001		;REG_DIPSW -Kick watchdog
	
	
	jsr $C004C2 			;FIX_CLEAR - clear fix layer
	jsr $C004C8				;LSP_1st   - clear first sprite

		
	;        -RGB			
	move.w #$0000,$401FFE	;0 - Common Background color
	
	lea Palette,a3
	move.l #$400020,a2
	move.l #16-1,d0
PaletteAgain:	
	move.w (a3)+,(a2)+	
	dbra d0,PaletteAgain
	
		
	
;Clear ram
	move.l #CacheAddr1,a3
	move.l #$A00,d1
	jsr CLDIR0						;Clear D1 bytes from A3
	
;Copy Cachetable template to ram
	ifnd DoubleBuffered
		move.l #T_CacheTable,a3
		move.l #CacheTable,a2
		move.l #T_CacheTable_End-T_CacheTable,d1
		jsr ldir
	endif
	
	move.l #T_BackgroundTilemap2,a3
	move.l #BackgroundTilemap2,a2
	move.l #36*28*2+4,d1
	jsr LdirSwapEndian
	
	;move.l #ScreenBase,a6
	;jsr prepareVram
	;move.w #1,(VDP_data) ;C00000 Select tile for mem loc
	
	
	ifd UseHsprite
		jsr DefineHspriteTilemap
		
		move.w #1,$3C0004 	;Set AutoInc
		
	endif 
	
	jmp RunTest1
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	

	
ReadJoystick:		;D0=1up D1=2up ---7654S321RLDU
	
		move.b $300000,d0	;Joy1 - DCBARLDU
	
	rts
	
	ifd UseHsprite
		include "\SrcNEO\NEO_V1_MaxTile_SpriteTilemap.asm"
	else
		include "\SrcNEO\NEO_V1_MaxTile_Fix.asm"
	endif
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	


	ifd DoubleBuffered
		include "\SrcAll\V1_MaxTile_DirectDriver.asm"
	else
		include "\SrcAll\V1_MaxTile_CacheDriver.asm"
	endif 

 	include "\SrcAll\V1_MaxTile.asm"

	include "MaxTile_Test1.asm"

 	include "\SrcAll\BasicFunctions.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	

	

Palette:
    dc.w $0000; ;0  -RGB
    dc.w $080F; ;1  -RGB
    dc.w $00FF; ;2  -RGB
    dc.w $0FFF; ;3  -RGB
    dc.w $0008; ;4  -RGB
    dc.w $0808; ;5  -RGB
    dc.w $0088; ;6  -RGB
    dc.w $0CCC; ;7  -RGB
    dc.w $0888; ;8  -RGB
    dc.w $0F00; ;9  -RGB
    dc.w $00F0; ;10  -RGB
    dc.w $0FF0; ;11  -RGB
    dc.w $000F; ;12  -RGB
    dc.w $0F0F; ;13  -RGB
    dc.w $00FF; ;14  -RGB
    dc.w $0FFF; ;15  -RGB
