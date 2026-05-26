;SQL_UseExtraRam equ 1
;Use10BitFont equ 1
UseHQGraphics equ 1
UseJapanese equ 1

QTV_Use16ColorDecoder equ 1		;Use the 16 color decoder version

_speed equ 1
VideoFx16 equ 1

;rkFlags equ VM_rFU
rkFlags_Q equ %10000000
rkFlags_D equ %00100000

; QTV_Ram equ ramarea+96					;RAM for the QTV decoder

; QTV_SimpleCount  equ QTV_Ram	;1 byte
; QTV_SimpleTblock  equ QTV_Ram+1	;1 byte
; QTV_FxFlags   equ QTV_Ram+2		;1 byte
; QTV_ReversePlay equ QTV_Ram+3	;2 bytes 

tempbuffer equ ramarea+128
paletteLut equ ramarea+512		;16 bytes MUST be zero aligned $XX00 -	For 16 color Ver	

LineDrawingRam equ ramarea+64 ;Need 26 bytes
MPBitmap_AbsPacket equ 1				;Use Absolute co-ordinates rather than relative
							; (Allows 1px movements in a 256x192 range rather than 2px)


;Use2ColorGraphics equ 1


OSK_DontUsePhysical equ 1

GEN_BMPscreen equ 1



;RleDecoderRAM equ ramarea+96	;4 bytes per decoder, 16 for four 
;RLETileBuffer equ ramarea+64		;32 bytes for 16 color 
	
RleDecoderRAM equ ramarea+96	;6 bytes per decoder, 24 for four 
RLETileBuffer equ ramarea+64		;32 bytes for 16 color 	

SeqTextTypeSpeed equ ramarea+125
Font10Bit_ColorOff equ ramarea+126		;Drawing color 
Font10Bit_ColorOn equ ramarea+127

	ifd VM_RamBase
	

Use10BitFont equ 1
Font_DrawZeroPixels equ 1

rkFlags equ VM_RamBase+VM_rFU

Game_Cash equ VM_RamBase+32				;How much money we have for gifts
Game_CurrentRoom equ Game_Cash+1		;Room number (background graphic)
Game_CurrentChar  equ Game_CurrentRoom+1;The character in the room
Game_ChibikoHeart equ Game_CurrentChar+1;Chibiko player score (0=Like 255=Hate)
Game_BochanHeart equ Game_ChibikoHeart+1;Bochan player score (0=Like 255=Hate)
Game_Gift equ Game_BochanHeart+1		;The gift you currently hold

Game_ShopItem1 equ Game_Gift+1			;4 random items sold in the shop
Game_ShopItem2 equ Game_ShopItem1+1
Game_ShopItem3 equ Game_ShopItem2+1
Game_ShopItem4 equ Game_ShopItem3+1

Game_ChibikoGifts equ Game_ShopItem4+1	;Already given gifts 2 bytes (16 gifts)
Game_BochanGifts equ Game_ChibikoGifts+2
Game_GameTime equ Game_BochanGifts+2	;Time point in the game (until bad end)

Font10Bit_ColorOff equ Game_GameTime+1		;Drawing color 
Font10Bit_ColorOn equ Font10Bit_ColorOff+1

MPBitmap_BankSwitchRestore equ Font10Bit_ColorOn+1	;For Bankswitcher

QTV_CartRamStream equ MPBitmap_BankSwitchRestore+8	;QTV stream current banknum

QTV_Ram equ ramarea+96					;RAM for the QTV decoder

QTV_SimpleCount  equ QTV_Ram	;1 byte
QTV_SimpleTblock  equ QTV_Ram+1	;1 byte
QTV_FxFlags   equ QTV_Ram+2		;1 byte
QTV_ReversePlay equ QTV_Ram+3	;2 bytes 


	else
	

Use10BitFont equ 1
Font_DrawZeroPixels equ 1

rkFlags equ VM_rFU

Game_Cash equ 32				;How much money we have for gifts
Game_CurrentRoom equ Game_Cash+1		;Room number (background graphic)
Game_CurrentChar  equ Game_CurrentRoom+1;The character in the room
Game_ChibikoHeart equ Game_CurrentChar+1;Chibiko player score (0=Like 255=Hate)
Game_BochanHeart equ Game_ChibikoHeart+1;Bochan player score (0=Like 255=Hate)
Game_Gift equ Game_BochanHeart+1		;The gift you currently hold

Game_ShopItem1 equ Game_Gift+1			;4 random items sold in the shop
Game_ShopItem2 equ Game_ShopItem1+1
Game_ShopItem3 equ Game_ShopItem2+1
Game_ShopItem4 equ Game_ShopItem3+1

Game_ChibikoGifts equ Game_ShopItem4+1	;Already given gifts 2 bytes (16 gifts)
Game_BochanGifts equ Game_ChibikoGifts+2
Game_GameTime equ Game_BochanGifts+2	;Time point in the game (until bad end)

MPBitmap_BankSwitchRestore equ Game_GameTime+1	;For Bankswitcher

QTV_CartRamStream equ MPBitmap_BankSwitchRestore+8	;QTV stream current banknum

QTV_Ram equ ramarea+96					;RAM for the QTV decoder

QTV_SimpleCount  equ QTV_Ram	;1 byte
QTV_SimpleTblock  equ QTV_Ram+1	;1 byte
QTV_FxFlags   equ QTV_Ram+2		;1 byte
QTV_ReversePlay equ QTV_Ram+3	;2 bytes 


	else
	endif 
	
	
	
	ifd BuildSQL
Use4ColorGraphics equ 1
VM_RamBase equ $0070000		;Requires 384k 
VM_HostRam equ $007F000		;Requires 384k 

;VM_RamBase equ $0030000	; Ok for 128k machine
;VM_HostRam equ $003F000	;Variables for our Emulator
	endif

	
	ifd BuildGEN
VM_RamBase equ $00FF0000
VM_HostRam	equ $00FFFE00	;Variables for our Emulator
NeedReorg equ 1
	endif
	
	

	ifnd Use4ColorGraphics
	ifnd Use2ColorGraphics
Use16ColorGraphics equ 1
 	endif 
	endif 	
	
	
	include "header.asm"
	
	include "srcall/ChibiVm_InstSet.asm"
	include "srcall/BasicMacros.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
	
	
VM_ProgLoadAddr equ $400	

	ifnd SpriteArrayRam
	ifd VM_RamBase;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HspriteCount equ VM_RamBase+64
HspriteLimit equ VM_RamBase+65
SpriteArrayRam equ VM_RamBase+$300	
VM_RamBaseB equ VM_RamBase
Timer_TicksOccured equ VM_RamBase+64+32
AnimatorPointers equ VM_RamBase+64+28

	else;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SpriteArrayRam equ $300	

Timer_TicksOccured equ 64+32
AnimatorPointers equ 64+28


HspriteCount equ 64
HspriteLimit equ 65
;VM_HostRam equ VM_RamBase+$F000
VM_RamBaseB equ 0
	endif;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	endif

	; move.l #1,d0
	; move.l #4,d2
	; move.l #4,d5
	; jsr mpbitmap_setpixel       ;ld=xpos e=ypos a=color
	; jmp *
	
	;clr.l d2
	;clr.l d5
	;move.l #'a',d0
	;jsr PrintChar
	
	; move.l #1,d0
	; move.l #40,d2
	; move.l #40,d5
	; jsr mpbitmap_setpixel       ;ld=xpos e=ypos a=color
	; jmp *
	
	;move.l #4,d2
	;move.l #4,d5
	;move.l #'b',d0
	;jsr PrintChar
	
	; clr.b (Cursor_X)
	; clr.b (Cursor_Y)
	; jsr monitor 
	;jmp *
	
	
	
	; move.l #TitleScreen1-VramBase,d0
	; move.w d0,(vm_rambase+16)
	
	; move.l #TitleScreen2-VramBase,d0
	; move.w d0,(vm_rambase+16+2)
	
	; move.l #TitleScreen3-VramBase,d0
	; move.w d0,(vm_rambase+16+4)
	
	; move.l #TitleScreen4-VramBase,d0
	; move.w d0,(vm_rambase+16+6)
	
	; move.l #0,d2	;Xpos/Ypos
	; move.l #0,d5
			
	; move.l #$20,d1	;Wid/Hei
	; move.l #$18,d4
	
			
	; ifd UseHalfHeight
		; move.l #2,d3
	; else
		; move.l #1,d3
	; endif 
	
	; ifd Use16ColorGraphics
		; move.l #4,d6
	; endif
	; ifd Use4ColorGraphics
		; move.l #2,d6			;Bitplanes
	; endif 
	; ifd Use2ColorGraphics
		; move.l #1,d6		;Bitplanes
	; endif 
	
	; jsr rledodrawscreen		;DE=XY BC=Wid/Hei H=halfheight L=Bitplanes
			
	
	;move.l #100,d2	;Y
	;move.l #50,d3	;X
	
	;move.l #50,d6	;Y
	;move.l #50,d7	;X
	
	;move.l #1,d0
	;jsr mpbitmap_drawline	;(x0,y0, x1,y1) ;src D3,D2/hl,de dest D6,D7/ix,iy=yoffset 

	
	
	;jmp $
	
;SpritePatterns equ 0 ;Remap pointer to Hsprites
;SpriteArrayRam equ $300 ;Remap pointer to SpriteArrayRamR

vmAddressRemap_BigEndian equ 1			;Little endian calculations won't work due to relocatable code

;	ifd BuildAST
;		and.l  #$FFFF0000,(VM_RamBaseAddr)	;Ensure VM ram ends $????0000
;	endif
	ifnd VM_RamBase
		and.l  #$FFFF0000,(VM_RamBaseAddr)	;Ensure VM ram ends $????0000
	endif

	clr.l d2
	clr.l d5
	
	;move.l #testt,a3
	;jsr printseqcp
	
	
;testt:
	;dc.b 'abcdef', 250,3,'gh',250,3,255
	;move.l #HSprites,a3
	;jsr NativeSpr_Init

	;move.l #SpriteArray,a3
	;jsr NativeSpr_DrawArray
	
	;jsr nativespr_hideall
	
	; move.l (vm_rambaseAddr),a3
	; moveq.l #4,d1
	; jsr memdumpadv   ;show memory to screen
	
	; jmp $
	
	;jsr nativespr_hideall
	
	jsr ChibiVM_Init

	
	
	
	
	;jsr VM_Run_WithMonitor
	
VM_Run:	
	jsr VM_Tick
	jmp VM_Run
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MpBitmap_TileTints:
SpaceChar:
	ds 16 ;First 10 bytes of font are 0 anyway!	
FontData:
Font10Bit:	;10x10 Don't save Part bytes! 
	ifnd UseJapanese
		incbin "\ResALL\ChibiAdventures\Ascii10px.Raw"	
	else 
		;incbin "\ResALL\ChibiAdventures\Kana10px.Raw"
		incbin "\ResALL\ChibiAdventures\Kanji10pxFrequency.1.Raw"
		;incbin "\ResALL\ChibiAdventures\Kanji10pxFrequency.2.Raw"
		;incbin "\ResALL\ChibiAdventures\Kanji10pxFrequency.3.Raw"
		;incbin "\ResALL\ChibiAdventures\Kanji10pxFrequency.4.Raw"
	endif 
	
	

	even

		
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;include "srcall/V1_NativeSprite.asm"	
	even
	
	;include "srcall/Multiplatform_RLE.asm"
	
	include "../ChibiVM/Multiplatform_MonitorA.asm"
	
	include "AdventureEngineX_Monitor.asm"
	
;	include "ChibiVM_AdvMathsBCD.asm"
;	include "ChibiVM_AdvMaths.asm"
;	include "ChibiVM_AdvancedInput.asm"
;	include "srcall/Multiplatform_OSK.asm"
	
	include "srcall/V1_Palette.asm"
	
;	include "sources/ReiKou/Reikou_ALL_MultiplatformBitmap2.asm"
	include "sources/ReiKou/Reikou_ALL_MultiplatformBitmap.asm"

	even
	include "AdventureEngine_PrintW.asm"
	include "ChibiVM_QTV_Minimal.asm"
	include "srcall/V1_QuadTreeVideoGeneric16color.asm"
	;include "ChibiVM_RLE.asm"
	include "ChibiVM_AdventureEngineX.asm"	;Must come before  ChibiVM_AdventureEngine.asm
	;include "srcall/V1_GenericAnimator.asm"	;Must come before  ChibiVM_AdventureEngine.asm
	include "AdventureEngineX.asm"				;Must come before  ChibiVM_AdventureEngine.asm
	include "ChibiVM_AdventureEngine.asm"
	include "sources/ChibiVM/ChibiVM_Host.asm"

	
	
	
	
	
vm_causecallfromoutsidevm:		;TODO!!!!!!!!!!!!!!!	
	rts
	
	
	
	;rorg $10000	;Needed for some reason - somethings messing up the next org otherwise
		



	;rorg $10000+VM_ProgLoadAddr
	
	
	ifd NeedReorg 
		rorg $10000
	else 
		align 13
	endif 
VramBase:		
	ds.b VM_ProgLoadAddr
TestProgram:	

	;incbin "\ResAll\ChibiVM\NumberGuess.rom"

	dc.b "!!!!Chibi/VM!!!!"			;Magic key - must be on a $xxxxxx00 boundary
	dc.b "Your product name here          "		;Software Name - 32 bytes

	;rorg $10000+VM_ProgLoadAddr+$30
	dc.b 0			;Header Version
	dc.b %00000011	; config {COpy Vectors to $100}
	dc.b %00111111	;Requirements {adv} {reikou} {maxtile} {QTV} {NS} {memmapper} {ChibiTracks}
	dc.b 0			;Spare
	dc.b 0			;Spare
	dc.b 0			;Cpu Requirements
	dc.b 0			;Ram Requirements
	dc.b 0 			;Vector Requorements {Vblank}
	dc.b 0 			;SysCall Requirements {VmMonitor}{VmControl}{ChipExt}
	dc.b 0 			;SysCall Requirements
	dc.b 0			;ChipExt Requirements ???
	dc.b 0			;ChipExt Requirements ???
	dc.b $11		;Bitmap Modes 0-7 {NS / Maxtile} 0=ZXS 1=CPC 2=GBC 3=SMS 4=SAM 5=VGA 6=GBA 7=RGBA
	dc.b $01		;Bitmap Modes 0-7 {AdvFont / QTV } 0=ZXS 1=CPC 2=GBC 3=SMS 4=SAM 5=VGA 6=GBA 7=RGBA
	dc.b 0			;Bitmap modes (spare)
	dc.b 0			;Bitmap modes (spare)
	
	;rorg $10000+VM_ProgLoadAddr+$40
	dlle $400		;Rom Load Address
	dlle $200		;StackPointer
	dlle $100		;Trap table Ram address (0=none)
	dlle $0000		;Memmap 1
	dlle $4000		;Memmap 2
	dlle $8000		;Memmap 3
	dlle $C000		;Memmap 4

	dc.b 0,0,0,0
	dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	;rorg $10000+VM_ProgLoadAddr+$70
	dlle (vm_traps-TestProgram)	;Vector table (0=none)
	dlle $2000		;Address remap table (0=none)
	dlle 0			;VMAssets (Palette,Font etc)
	dlle 0			;???

vm_Traps:
	dw ProgramLaunch-VramBase
	
vm_AddressRemapTable:	

	
	;org $800

ProgramLaunch:
	; dbw mov16i,$1000		;16 from color 0
	; dbbw mov16x,r6_imm16,GamePalette-VramBase
	; MBcall mbSetPaletteMP

	; dbbw mov16x,r2_imm16,0
	; dbb movi,'>'
	; advcall aPrintChar 		;Show cursor 
	
	
	; QTVCall qtInitQTV+regNO				;Init the QTV decoder 

	; dbb movi,1
	
	; dbb clrz,r1

	; dbb SYSi,syscallLoadMultiReg	;R6=Source R8=XY R10=WH R12=TS
	; dc.b %00001111
	; dw $0000	;Xpos,Ypos
	; dw $0808	;W,H of supertiles 
	; dw $0403	;W,H in supertiles 
	; dw Sequence-VramBase
	
	
	
	; QTVCall qtPtrocessQuadTreeFrameVMbyFrameNum
	
	;	dc.b hltb
		
	QTVCall qtInitQTV+regNO				;Init the QTV decoder 
	
	dbw mov16i,$1000					;16 from color 0
	dbbw mov16x,r6_imm16,GamePalette-VramBase
	MBcall mbSetPaletteMP				;Init the 16 color palette
	
	dbw mov16i,MPB_Pen3*256				;Set Text color 
	MBcall mbSetFontColors
	
	
;Init Game Defaults
	dbbwb movx,Addr16_imm8,Game_Gift,255	;255=No gift 
	dbbwb movx,Addr16_imm8,Game_GameTime,0	;250=Game over 
		
	dbbwb movx,Addr16_imm8,Game_Cash,0
	
	dbbwb movx,Addr16_imm8,Game_ChibikoHeart,32
	dbbwb movx,Addr16_imm8,Game_BochanHeart,32
		
	dbbww mov16x,Addr16_imm16,Game_ChibikoGifts,0;65535=have all gifts
	dbbww mov16x,Addr16_imm16,Game_BochanGifts,0;65535=have all gifts
		
;Show Title screen
	dbw mov16i,5							;Show Title Pic
	dbw bsrj,ShowPic-VramBase
	advcall aWaitForFire
	
	dbw bsrj,ClearTextArea-VramBase
		
;Main Game loop
MapLoop:
	dbbw incx,addr16_r0,Game_GameTime	;Time inc
	
	dbbwb cmpx,addr16_imm8,Game_GameTime,250	
	dbw beqj,GameLost-VramBase					;Game Time Run out?

	dbbw incx,addr16_r0,Game_Cash		;Give player More Cash!

	dbbw mov16x,r6_imm16,MapSeq-VramBase	;Option List
	dbbb movx,r4_imm8,5				;Max option
	dbw bsrj,ShowSelectCursor-VramBase		;Let user select a room
	
	dbw bsrj,ShowRoom-VramBase				;Show the room back
	dbw bsrj,ShowRoomChar-VramBase			;Show any char in the room
	
	dbbwb cmpx,addr16_imm8,Game_GameTime,255
	dbw beqj,GameWon-VramBase				;Has the Character reached Max Mood?
	
	dc.b cmpi,3						;No-one in this room?
	dbw beqj,MapLoop-VramBase
	
	dc.b cmpi,15						;In the shop?
	dbw beqj,ShowRoom_ShopText-VramBase
		
	dbw bsrj,ShowTalkOptionsGift-VramBase	;Show the Talk options screen
		
	dc.b ph0b
		dbw bsrj,ClearTextArea-VramBase
	dc.b pl0b
	dc.b cmpi,1						;1=Move?
	dbw beqj,MapLoop-VramBase
	
	dc.b cmpi,2						;2=Use Gift?
	dbw beqj,UseGift-VramBase
									;0=Talk
	
	
	dbbw movx,r0_addr16,Game_CurrentChar
	dc.b cmpi,2	;Sakuya?
	dbw beqj,SakuyaGossip-VramBase
	
	dc.b cmpi,0	;Chibiko
	dbw beqj,ChibikoText-VramBase
	
	dc.b cmpi,1	;Bochan
	dbw beqj,BochanText-VramBase
	
	;Getting here should be impossible!

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ChibikoText:	
	dbbw mov16x,r6_imm16,SeqChibikoChatList-VramBase
	dbw braj,OtherChat-VramBase

	
BochanText:
	dbbw mov16x,r6_imm16,SeqBochanChatList-VramBase
	dbw braj,OtherChat-VramBase

	
SakuyaGossip:
	dbbw mov16x,r6_imm16,SeqSakuyaGossipList-VramBase
OtherChat:
	advcall aDoRandom
	dbb andx,r0_atr6inc		;Appply count mask (2/4/8/16 etc)
	dbb clrz,r1
	
	dbb add16x,r6_r0	;*2 (2 bytes per seq)
	dbb add16x,r6_r0	;*2 (2 bytes per seq)
	dbb mov16x,r6_atr6
		
	dbw bsrj,ShowTextSeqs-VramBase
	
	dbw braj,MapLoop-VramBase
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

ShowTalkOptionsGift:
	dbbw movx,r0_addr16,Game_CurrentChar
	dc.b cmpi,2	;Sakuya?
	dbw beqj,ShowTalkOptionsGiftNoItem-VramBase ;Can't give gifts to sakuya

	dbbw movx,r0_addr16,Game_Gift
	dc.b cmpi,255						;Do we have a gift?
	dbw beqj,ShowTalkOptionsGiftNoItem-VramBase
	
	
	dbbw mov16x,r6_imm16,TalkOptionSeqGift-VramBase	;Option List (Gift)
	dbbb movx,r4_imm8,3				;Max option
	dbw braj,ShowSelectCursor-VramBase
	
	
ShowTalkOptionsGiftNoItem:
	dbbw mov16x,r6_imm16,TalkOptionSeq-VramBase	;Option List (nogift)
	dbbb movx,r4_imm8,2				;Max option
	dbw braj,ShowSelectCursor-VramBase
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
; Gifts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UseGiftAlreadyGiven:			
	dbw bsrj,ShowRoomAgain-VramBase		;Reshow the background
	dbw bsrj,ShowRoomCharAgain-VramBase
	
	dbbw movx,r6_addr16,Game_CurrentChar
	dbb clrz,r7
	dbb add16x,r6_r6			;*2 (2 bytes per char)
	dbbw add16x,r6_imm16,txtGiftReplyAgainList-VramBase	;Messages for Characters
	dbb mov16x,r6_atr6
	
	dbw bsrj,ShowTextSeqs-VramBase		;Show 'You already gave me this'
	dbw braj,MapLoop-VramBase
	
	
UseGift:		
	dbb clrz,R5
	dbbw movx,r4_addr16,Game_Gift	;R4/R5=Gift
		
	dbbw movx,r6_addr16,Game_CurrentChar
	dbb clrz,r7
	dbb add16x,r6_r6	;*2 (2 bytes per char)
	dbbw add16x,r6_imm16,Game_ChibikoGifts
	
	dbw bsrj,GetGiftMaskOffset-VramBase		;Convert to a mask
		
	dbb tstx,r0_atr6				;Test bit for this gift
	dbw bnej,UseGiftAlreadyGiven-VramBase	;Has Gift already been given
	
	dbb orrx,atr6_r0				;Flag the gift given
	
	dbbwb movx,Addr16_imm8,Game_Gift,255	;Remove gift
	
	dbbw add16x,r4_imm16,LstGifts-VramBase	;Find the character response
	dbb mov16x,r6_atr4				; To this gift 
	
	dbbw movx,r0_addr16,Game_CurrentChar
	dbb clrz,r1		
	dc.b lslb							;4 bytes per char
	dc.b lslb
	dbb add16x,r6_r0
	
	dc.b ph6b
		dbw bsrj,ShowRoomAgain-VramBase		;Show background
	dc.b pl6b
	dc.b ph4b
	dc.b ph6b
		dbb movx,r0_atr6
		dbw bsrj,ShowChar-VramBase			;Show char with appropriate
	dc.b pl6b							; expression
	dc.b pl4b
	
	dbw bsrj,UpdateHeartR2CurrentCharFromR6-VramBase ;Update players mood 
	
	dbw inc16x,r6_r0				;R6++
	;dc.b movx,r0_atr6
	dbb mov16x,r6_atr6				;Get pointer to reply 
	dbw bsrj,ShowTextSeqs-VramBase			;Show reply 
	dbw braj,MapLoop-VramBase
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetGiftMaskOffset:
	dc.b ph4b
		dbb lsrz,r5		;*1 (usually gift is 0/2/4/8)
		dbb rorz,r4
		
		dbb movx,r0_r4 ;Gift Bit offset 
		
		dbb andi,%00000111
		dbb clrz,r1
		dbbw addx,r0_addr16,BitMasks-VramBase
			
		
		dbb movx,r1_r0 				;R0=Mask for this gift
		dbbb eorx,r1_imm8,%00000111	;R1=Mask for unchanged gifts
		
		dbb lsrz,r5		;/2
		dbb rorz,r4
		dbb lsrz,r5		;/4
		dbb rorz,r4
		dbb lsrz,r5		;/8
		dbb rorz,r4		
	
		dbb add16x,r6_r4  ;Gift byte offset - 8 gifts per byte 
	
	dc.b pl4b
	dc.b retb
	
BitMasks: dc.b 1,2,4,8,16,32,64,128	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateHeartR2CurrentCharFromR6:
	dbb inc16x,r6_r0
	dbb movx,r0_atr6	;Get Change size
	
	dbbw movx,r2_addr16,Game_CurrentChar	;Select Heart addr for 
	dbb clrz,r3								; Current char 
	dbbw add16x,r2_imm16,Game_ChibikoHeart
	
;UpdateHeartR2:
	dbbb addx,r0_AtR2PlIm,0		;R0=R0+(R2+0)  ;Note ChibiVM can't just do (R2)
	dbb cmpi,240	;>240?
	dbw bccj,UpdateHeartR2Limit-VramBase
	
		dbbb movx,AtR2PlIm_r0,0	;Over limit, so don't change 
UpdateHeartR2Limit:
	dc.b retb
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Shop
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
ShowRoom_ShopText:
	dbbw movx,r0_addr16,Game_Gift
	dc.b cmpi,255						;Does the user already have an item?
	dbw beqj,ShowRoom_ShopHaveNoItem-VramBase
	
	dbbw mov16x,r6_imm16,SeqShopSell-VramBase	;Offer to buy back item
	dbw bsrj,ShowTextSeqs-VramBase

	dbbw mov16x,r6_imm16,SeqShopSellOptions-VramBase	;Option List
	dbbb movx,r4_imm8,2				;Max option
	dbw bsrj,ShowSelectCursor-VramBase
	
	dbb cmpi,1						;No to sell - back to map
	dbw beqj,MapLoop-VramBase
	
	dbbw incx,addr16_r0,Game_Cash	;Sell item +1 credit 
	dbbwb movx,addr16_imm8,Game_Gift,255 	;Release item
	dbw bsrj,ClearTextArea-VramBase
	
	
ShowRoom_ShopHaveNoItem:
	dbbw mov16x,r6_imm16,Game_ShopItem1
	dbbb movx,r1_imm8,4				;4 random items for sale 
ShowRoom_ShopRandomItem:
	advcall aDoRandom
	dc.b lslb
	dbb andi,%00001110				;item address 0/2/4/6/8 etc
	dbb movx,atr6Inc_r0
	dbb decz,r1
	dbw bnej,ShowRoom_ShopRandomItem-VramBase
	
		
	dbbwb cmpx,Addr16_imm8,Game_Cash,10	;All items cost 10 credits
	dbw bcsj,ShowRoom_Shop_NoMoney-VramBase		;Does player have enough money?

	
	dbbw mov16x,r6_imm16,SeqShopBuy-VramBase 
	dbw bsrj,ShowTextSeqs-VramBase			;Welcome msg
	
	dbbw mov16x,r4_imm16,$000D
	dbbw mov16x,r6_imm16,SeqShopBuy2-VramBase ;What do you want to buy?
	advcall APrintSeq
	
	dbbw mov16x,r4_imm16,$020E		;Start of item list 
	advXcall AxSetCP
	
	dbbw mov16x,r2_imm16,Game_ShopItem1
	
	dbbb movx,r1_imm8,4				;Item count
	
ShowRoom_Shop_ShowItem:	
	dbb clrz,R5
	dbb movx,r4_atR2Inc			;Item number 0/2/4/6
	dbbw add16x,r4_imm16,LstGifts-VramBase
	
	dbb mov16x,r6_atr4			;Get String Addr 
	
	dbbw add16x,r6_imm16,8		;1st 8 bytes are commands (before string)
	advXcall AxPrintSeqCP
		
	dbb decz,r1
	dbw bnej,ShowRoom_Shop_ShowItem-VramBase
	
	dbbw mov16x,r6_imm16,SeqShop_None-VramBase	;Show Nothing (Don't buy)
	advXcall AxPrintSeqCP
	
	dbbb movx,r4_imm8,5				;Max option
	dbw bsrj,ShowSelectCursorOnly-VramBase
	
	
	dc.b ph0b
		dbw bsrj,ClearTextArea-VramBase
	dc.b pl0b 
	
	dbb cmpi,4						;Selected Nothing?
	dbw beqj,MapLoop-VramBase
	
	dbb movx,r2_r0
	dbb clrz,r3
	dbbw add16x,r2_imm16,Game_ShopItem1	;Get the selected itemNum
	
	dbbw mov16x,Addr16_atR2inc,Game_Gift;Save Selected Item Num
	
	dbbwb subx,Addr16_imm8,Game_Cash,10	;Spend the money
	
	dbw braj,MapLoop-VramBase
	
	
ShowRoom_Shop_NoMoney:
	dbbw mov16x,r6_imm16,SeqShopPoverty-VramBase		;User can't afford an item
	dbw bsrj,ShowTextSeqs-VramBase
	dbw braj,MapLoop-VramBase
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ShowChar
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

ShowRoom_Shop:
	dc.b movi,15		;Yume?
	dc.b ph0b
	dbw braj,ShowRoom_ShopB-VramBase	;Branch to shop code
	
	
	
ShowRoomChar:	
	dbbwb cmpx,addr16_imm8,Game_CurrentRoom,4
	dbw beqj,ShowRoom_Shop-VramBase	;Are we in the shop? (Yume char)
	
	
	dbbw mov16x,r4_imm16,$0004	;Select a random character 
	advcall arangedrandom
	;dbb movi,2		;Test Force a charater
	
	dc.b cmpi,3					;0=Chibiko 1=Bochan 2=Yume 3=noone
	dbw beqj,ShowRoom_NoChar-VramBase
	dbbw movx,addr16_r0,Game_CurrentChar	;Save current char
	
ShowRoomCharAgain:
	dbbw movx,r0_addr16,Game_CurrentChar	;Load current char
	dc.b ph0b
	
;Get base sprite 
		dbb movx,r6_r0
		dbb clrz,r7
		dbbw add16x,r6_imm16,CharList-VramBase
		dbb movx,r1_atr6				;Charnum
		
		dbbb cmpx,r0_imm8,2			;No heart for Yume/Sakuya
		dbw bccj,ShowRoom_HeartDone-VramBase
		
		
;Check heart level and charnge char graphic 
		dbb movx,r6_r0
		dbb clrz,r7
		dbbw add16x,r6_imm16,Game_ChibikoHeart 
		
		dbb movi,0		;0=happy, 1=sad 2=angry
		dbbb cmpx,atr6_imm8,56
		dbw bcsj,ShowRoom_HeartDoneB-VramBase
		
		dbb movi,1		;0=happy, 1=sad 2=angry
		dbbb cmpx,atr6_imm8,72
		dbw bcsj,ShowRoom_HeartDoneB-VramBase
		
		dbb movi,2		;0=happy, 1=sad 2=angry
		dbbb cmpx,atr6_imm8,96
		dbw bcsj,ShowRoom_HeartDoneB-VramBase

;WonGame Heart>96
		dbbwb movx,addr16_imm8,Game_GameTime,255
		
		
ShowRoom_HeartDoneB:
		dbb addx,r1_r0	;Final char img
		
ShowRoom_HeartDone:		
		dbb movx,r0_r1
	
ShowRoom_ShopB:	
		dc.b ph0b ;dbb stoz,r8	;r0->r8
		
		dbbw mov16x,r4_imm16,$0212	;Xpos for the chracter 
		advcall arangedrandom
		dbb movx,r1_r0	;xpos
		
		dc.b pl0b ;dbb movz,r8	;r0<-r8
		dbw bsrj,ShowChar-VramBase
	dc.b pl0b
ShowRoom_NoChar:
	dc.b retb
	

CharList:		;Frames for Chibiko,Bochan and Yume
	dc.b 9,12,16		;15=Yumi
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
	
	
	
	
	
	
ShowTextSeqs:
	dc.b ph6b
		dbbw mov16x,r6_imm16,seqType-VramBase
		advcall aprintseq		;Default speed
	dc.b pl6b 

	dbbw mov16x,r4_imm16,$000D	;XY post
	advcall aprintseq			;Show text
	
	dbbb cmpx,atr6_imm8,255		;255=More Text
	dbw beqj,ShowTextSeqsNoChoice-VramBase
	
	dbbb cmpx,atr6_imm8,128		;>128 = Options 128+4 = 4 options
	dbw bccj,ShowTextSeqsChoice-VramBase ;128+64 =  Clear after 
	
ShowTextSeqsNoChoice:	
	dbbb cmpx,atr6_imm8,0		;0 = Seq Done?
	dbw beqj,ShowTextSeqsNoChar-VramBase

	dbbb cmpx,atr6_imm8,64		;1-63 = Seq Char,Mood
	dbw bcsj,ShowTextSeqsCharMood-VramBase
	
ShowTextSeqsNoChar:	
	dc.b ph6b
		dbbw mov16x,r6_imm16,seqPause-VramBase
		advcall aprintseq				;Generic pause
		dbw bsrj,ClearTextArea-VramBase
	dc.b pl6b
	
	dbbb cmpx,atr6_imm8,0		;0 = Seq Done?
	dbw beqj,ShowTextSeqsDone-VramBase
	
	dbbb cmpx,atr6_imm8,255		;255 = More Text
	dbw beqj,ShowTextSeqsContinue-VramBase

	
ShowTextSeqsCharMood:	
;1-254 = New Char , Mood Change 
	dc.b ph6b
		dbw bsrj,ShowRoomAgain-VramBase	;Reshow background 
	dc.b pl6b
	dc.b ph4b
	dc.b ph6b
		dbb movx,r0_atr6
		dbw bsrj,ShowChar-VramBase		;Show the new character image
	dc.b pl6b
	dc.b pl4b
	
	dbw bsrj,UpdateHeartR2CurrentCharFromR6-VramBase ;Alter charater mood
	
ShowTextSeqsContinue:	
	dbb incz,r6
	dbw braj,ShowTextSeqs-VramBase		;Resume the text sequence
ShowTextSeqsDone:
	dc.b retb

	
ShowTextSeqsChoice:   ;Give the user a choice, followed by a reply 
	dbb movx,r4_atr6
	dbb incz,r6
	
	dbbb tstx,r4_imm8,%01000000				;Max option
	dbw bnej,ShowTextSeqsChoice_ClearAfter-VramBase

;No clear after text
	dbbb andx,r4_imm8,%00000111				;Max option
	dc.b ph6b
		dbw bsrj,ShowSelectCursorOnly-VramBase
ShowTextSeqsChoice_Done:
	dc.b pl6b
	
	dbb clrz,r1			;R0=Chosen answer 
	
	dbb add16x,r6_r0	;*2 (2 bytes per seq)
	dbb add16x,r6_r0	;*2 (2 bytes per seq)
	dbb mov16x,r6_atr6	;Get Response sequence
	dbw braj,ShowTextSeqs-VramBase ;Show the answer to the players choice
	
	
;Clear after text
ShowTextSeqsChoice_ClearAfter:
	dbbb andx,r4_imm8,%00000111				;Max option
	dc.b ph6b
		dbw bsrj,ShowSelectCursorOnly-VramBase
		dc.b ph0b
			dbw bsrj,ClearTextArea-VramBase
		dc.b pl0b
	dbw braj,ShowTextSeqsChoice_Done-VramBase
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearTextArea:
	dbbw mov16x,r4_imm16,$0010	;X/Y start 
ClearTextAreaY:	
	dc.b ph4b
ClearTextAreaX:	
		dbbw mov16x,r6_imm16,SpaceChar-VramBase
		dbb movi,1				;R0=Bitplane count
		
		dc.b ph4b
			MBcall mbSettile 	;HL = Source Pattern D=Xpos (tiles)
		dc.b pl4b				 	; E=Ypos (Tiles) A=Bitplane count
		dbb incz,r5				;Xpos++
		dbbbb cmpx,ZeroPg_imm8,r5,32
		dbw bnej,ClearTextAreaX-VramBase
	dc.b pl4b
	dbb incz,r4					;Xpos++
	dbbb cmpx,r4_imm8,24
	dbw bnej,ClearTextAreaY-VramBase		
	
	dbbw mov16x,r4_imm16,$000D	;Reset X/Y pos
	dc.b retb
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GameLost:
	dbb movi,8
	dbw bsrj,ShowPic-VramBase
	dc.b hltb

	
GameWon:
	dbbw movx,r0_addr16,Game_CurrentChar	
	dc.b cmpi,0	;Chibiko
	dbw beqj,ChibikoWin-VramBase
	
BochanWin:
	dbbw mov16x,r6_imm16,txtBochanWin-VramBase
	dbw bsrj,ShowTextSeqs-VramBase
	
	dbb movi,7
	dbw bsrj,ShowPic-VramBase
	dc.b hltb
	
txtBochanWin:
	dc.b 'Leave me alone stupid!'
	dc.b 255,0
	
ChibikoWin:
	dbbw mov16x,r6_imm16,txtChibikoWin-VramBase
	dbw bsrj,ShowTextSeqs-VramBase
	
	dbb movi,6
	dbw bsrj,ShowPic-VramBase
	dc.b hltb

txtChibikoWin:
	dc.b 'Thats it!',254,'Im sick of your shit!'
	dc.b 255,0
	
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	
SetPicPal:		;R0 = Room number 
	dc.b ph0b
		advcall acls 

		ifnd VideoFx16
			dc.b pl0b
			dc.b ph0b			
			
			dbbw mov16x,r6_imm16,PicPalettes
			
			dbb clrz,r1
			dc.b lslb		;*2
			dc.b lslb		;*4
			dc.b lslb		;*8 bytes per palette
			dbb add16x,r6_r0
			
			dbw mov16i,$0400		;4 from color 0
			
			MBcall mbSetPaletteMP	
		endif 
	dc.b pl0b
	dc.b rtsb 
		
		
	;16 color palette
GamePalette:
    dw $0000 ;0  -GRB
    dw $0188 ;1  -GRB
    dw $0F1F ;2  -GRB
    dw $0FFF ;3  -GRB
    dw $0888 ;4  -GRB
    dw $0939 ;5  -GRB
    dw $0D44 ;6  -GRB
    dw $04E4 ;7  -GRB
    dw $08EA ;8  -GRB
    dw $0BE6 ;9  -GRB
    dw $0FF6 ;10  -GRB
    dw $0CCC ;11  -GRB
    dw $01FF ;12  -GRB
    dw $041D ;13  -GRB
    dw $0A7D ;14  -GRB
    dw $0383 ;15  -GRB

	
	;Per picture palettes for 4 color systems
PicPalettes:
	dw $0000 ;0  -GRB 0 - Forest
    dw $0280 ;1  -GRB
    dw $0F44 ;2  -GRB
    dw $0FEE ;3  -GRB
	
    dw $0000 ;0  -GRB 1 - Mountain
    dw $0508 ;1  -GRB
    dw $0F4F ;2  -GRB
    dw $0FDF ;3  -GRB
	
    dw $0000 ;0  -GRB 2 - School
    dw $0381 ;1  -GRB
    dw $08C3 ;2  -GRB
    dw $0FCF ;3  -GRB
	
	dw $0000 ;0  -GRB 3 Street 
    dw $0668 ;1  -GRB
    dw $0AAC ;2  -GRB
    dw $0FFF ;3  -GRB
	
	dw $0000 ;0  -GRB 4 - Shop
    dw $0084 ;1  -GRB
    dw $08CC ;2  -GRB
    dw $0FFF ;3  -GRB
	
	dw $0000 ;0  -GRB 5 - Title
    dw $0188 ;1  -GRB
    dw $06F6 ;2  -GRB
    dw $0FFC ;3  -GRB
	
	dw $0000 ;0  -GRB 6 - Chibiko Mad End 
    dw $0188 ;1  -GRB
    dw $06F6 ;2  -GRB
    dw $0FFC ;3  -GRB
	
	dw $0000 ;0  -GRB 7 - Bochan Mad
    dw $0282 ;1  -GRB
    dw $0888 ;2  -GRB
    dw $0FCC ;3  -GRB
	
	dw $0000 ;0  -GRB 8 - Crud end
    dw $0181 ;1  -GRB
    dw $0C03 ;2  -GRB
    dw $0CFC ;3  -GRB
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	
ShowPic:		;Used for Title/Gameover
	dbw jsrj,SetPicPal-VramBase				;Set 4 color palette
	dbb clrz,r1	
	
	dbb SYSi,syscallLoadMultiReg	;R6=Source R8=XY R10=WH R12=TS
	dc.b %00001111
	dw $0000	;Xpos,Ypos
	dw $0808	;W,H of supertiles 
	dw $0403	;W,H in supertiles 
	dw Sequence-VramBase
	
	QTVCall qtPtrocessQuadTreeFrameVMbyFrameNum
	advcall aWaitForFire
	dc.b retb 

	

ShowRoom:		;Show 
	dbbw movx,addr16_r0,Game_CurrentRoom
ShowRoomAgain:	
	dbbw movx,r0_addr16,Game_CurrentRoom
	;dbw bsrj,ShowScreen	
	;dc.b retb

	
ShowScreen:		;Used for Background 
	dbw jsrj,SetPicPal-VramBase				;Set 4 color palette
	
	dbb clrz,r1

	dbb SYSi,syscallLoadMultiReg	;R6=Source R8=XY R10=WH R12=TS
	dc.b %00001111
	dw $0000	;Xpos,Ypos
	dw $0808	;W,H of supertiles 
	dw $0402	;W,H in supertiles 
	dw Sequence-VramBase
	
	QTVCall qtPtrocessQuadTreeFrameVMbyFrameNum
	dc.b retb 
	

ShowChar:		;Used for Character overlay 
	dbbbb movx,ZeroPg_imm8,r8,4		;R8 = Ypos 
	dbbb movx,ZeroPg_r1,r9			;R9 = Xpos
	
	dbbb movx,r1_imm8,0				;R0/R1 = Frame (Char)
	
	dbb SYSi,syscallLoadMultiReg	;R6=Source R8=XY R10=WH R12=TS
	dc.b %00000111
	dw $0101	;W,H of supertiles 
	dw $0C0C	;W,H in supertiles 
	dw Sequence-VramBase
	
	QTVCall qtPtrocessQuadTreeFrameVMbyFrameNum	;Show the character img
	dc.b retb 
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
ShowSelectCursorOnly:
	dbb movi,19						;Bottom of the screen
	dbb subx,r0_r4					;Move up by option count
	dbb stoz,r8						;Cursor Ypos backup
	dbw braj,ShowSelectCursorOnlyb-VramBase
	
ShowSelectSeq1:
	dbb movi,19						;Bottom of the screen
	dbb subx,r0_r4					;Move up by option count
	dbb stoz,r8						;Cursor Ypos backup
	dbbw mov16x,r4_imm16,$000D		;XYpos for the select list 
	advcall aprintseq				;Show select list 
	dc.b retb

ShowSelectCursor:	
	dc.b ph4b
		dbw bsrj,ShowSelectSeq1-VramBase		;Show a select message
	dc.b pl4b
ShowSelectCursorOnlyb:
	dbbw mov16x,r6_imm16,$0000		;Cursor pos 
	dbbbb movx,ZeroPg_imm8,5,0		;Min val (R4=Max val)
SelectLoop:	
	dc.b ph4b
		dbb mov16x,r4_r6
		dbbb addx,r4_ZeroPg,r8		;Add First line Pos
		dc.b ph4b
			dbb movi,'>'
			advcall aPrintChar 		;Show cursor 
			
			advcall aDoRandom		;Randomize Seed
			advcall aDoRandom		;Randomize Seed
			advcall aDoRandom		;Randomize Seed
			
			advcall aPause50
		dc.b pl4b
		dbb movi,' '
		advcall aPrintChar 			;Hide cursor 
			
		advcall areadjoystick		;Get Joystick directions
		dbb movx,r2_r0
	dc.b pl4b							;Min-Max Y range
	
	dc.b ph4b
		dbb movx,r0_r6
		advcall ajoyaxis			;Process Up/Down joy press
		advcall arangelimit			;Check we're still onscreen
		dbb movx,r6_r0						
	dc.b pl4b 
	
	dbbb tstx,r2_imm8,%00000100		;Fire?
	dbw bnej,SelectLoop-VramBase				;Repeat until fire
	dc.b retb 	
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Scripts

SeqBochanChatList:
	dc.b %00000011		;Mask for possible options (%00=1 %10=2 %11=4)
	dw SeqBochanChat4-VramBase
	dw SeqBochanChat3-VramBase
	dw SeqBochanChat2-VramBase
	dw SeqBochanChat1-VramBase

	
SeqBochanChat4:
;       01234567890123456789012345
	dc.b "Do You like Cake?"
	dc.b 255,255
		
	dbbw 250,131,seqhenji-VramBase
	dc.b 254,254,254,254
	
	dc.b 2 ;Xpos =2 
	dc.b 250,133,0	;Typing Speed
		dc.b 'Yes',254
		dc.b 'No'
	dc.b 255,128+2		;128+4=4Choice
	dw SeqBochanChat4_Cake-VramBase
	dw SeqBochanChat4_NoCake-VramBase
	
SeqBochanChat4_NoCake:
	dc.b 255,12,-8	;14=bochanmad 13=bochansad 12=bochannhappy
;       01234567890123456789012345
	dc.b "Yeah, Cake sucks!"
	dc.b 255,0
	
SeqBochanChat4_Cake:
;       01234567890123456789012345
	dc.b 255,13,8	;14=bochanmad 13=bochansad 12=bochannhappy
	dc.b "Eww Gross!",254
	dc.b "I thought you had better",254,'Taste!'
	dc.b 255,0
	
	
	
SeqBochanChat3:
;       01234567890123456789012345
	dc.b "Hey Whacha want?"
	dc.b 255,255
		
	dbbw 250,131,seqhenji-VramBase
	dc.b 254,254,254,254
	
	dc.b 2 ;Xpos =2 
	dc.b 250,133,0	;Typing Speed
		dc.b 'I was looking for you',254
		dc.b 'Looking for dead bugs'
	dc.b 255,128+2		;128+4=4Choice
	dw SeqBochanChat3_You-VramBase
	dw SeqBochanChat3_Bugs-VramBase
	
SeqBochanChat3_Bugs:
	dc.b 255,12,-8	;14=bochanmad 13=bochansad 12=bochannhappy
;       01234567890123456789012345
	dc.b "Wow Tasty!",254
	dc.b "Gimme! I want, I want!!"
	dc.b 255,0
	
SeqBochanChat3_You:
;       01234567890123456789012345
	dc.b 255,13,8	;14=bochanmad 13=bochansad 12=bochannhappy
	dc.b "Ack! You look shifty",254
	dc.b "I'm gonna keep an eye",254,"on you!!"
	dc.b 255,0
	
	
	
	
SeqBochanChat2:
;       01234567890123456789012345
	dc.b "Tell me! What do you think",254
	dc.b "of chibiko?"
	dc.b 255,255				;255,255= Pause+Clear followed by more text
	
	dbbw 250,131,seqhenji-VramBase	;250,131 = Show Multibyte Sequence
	dc.b 254,254,254;,254
	
	dc.b 2 ;Xpos =2 
	dc.b 250,133,0			;250,133=Typing Speed
		dc.b 'I Love her',254
		dc.b "I don't care",254
		dc.b 'I hate her',254
	dc.b 255,128+3			;255,128+3=3 Choice
	dw SeqBochanChat2_Love-VramBase
	dw SeqBochanChat2_Hate-VramBase
	dw SeqBochanChat2_Hate-VramBase
	
SeqBochanChat2_Love:
	dc.b 255,12,-8			;255,Char,MoodChange								14=bochanmad 13=bochansad 12=bochannhappy
	dc.b "Oh really!",254
	dc.b "Wow! I didn't know that!"
	dc.b 255,0				;255,0 = End
				
SeqBochanChat2_Hate:
;       01234567890123456789012345
	dc.b 255,13,8	;14=bochanmad 13=bochansad 12=bochannhappy
	dc.b "That's mean!",254
	dc.b "My sister is awesome!",254
	dc.b 255,0
		
		
seqhenji:
	;dc.b 183,210,151,255		;henji (romaji)
	dc.b 1,221,1,64,255		;henji (kanji)
	;dc.b 'Reply',255
	

		
SeqBochanChat1:
;       01234567890123456789012345
	dc.b "I'm hungry, got any food?"
	dc.b 255,255
	
	dbbw 250,131,seqhenji-VramBase
	dc.b 254,254,254,254
	
	dc.b 2 ;Xpos =2 
	dc.b 250,133,0	;Typing Speed
		dc.b 'Offer Candy',254
		dc.b 'Say No'
	dc.b 255,128+2		;128+4=4Choice
	dw SeqBochanChat1_Candy-VramBase
	dw SeqBochanChat1_No-VramBase
	
SeqBochanChat1_Candy:
	dc.b 255,14,8	;14=bochanmad 13=bochansad 12=bochannhappy
	dc.b "Bleh, What's this?",254
	dc.b "Who wants yuck like that!",254
	dc.b 255,0
	
SeqBochanChat1_No:
;       01234567890123456789012345
	dc.b 255,13,-1	;14=bochanmad 13=bochansad 12=bochannhappy
	dc.b "Bah! No fair",254
	dc.b "I'm gonna hunt for tasty",254
	dc.b "corpses!",254
	dc.b 255,0
		
	
SeqChibikoChatList:	
	dc.b %00000011			;Mask for possible options (%11=4)
	dw SeqChibikoChat4-VramBase
	dw SeqChibikoChat3-VramBase
	dw SeqChibikoChat2-VramBase
	dw SeqChibikoChat1-VramBase
	
SeqChibikoChat1:
;       01234567890123456789012345
	dc.b 'Hey you! Im Hungry, let',254,'me drink your blood!'
	dc.b 255,255
	
	dbbw 250,131,seqhenji-VramBase
	dc.b 254,254,254,254
	
	dc.b 2 ;Xpos =2 
	dc.b 250,133,0	;Typing Speed
		dc.b 'Yes',254
		dc.b 'No'
	dc.b 255,128+2		;128+4=4Choice
	dw SeqChibikoChat1_Yes-VramBase
	dw SeqChibikoChat1_No-VramBase
	
SeqChibikoChat1_Yes:
	dc.b 255,11,8	;11=chibimad 10=Chibisad 9=chibihappy
	dc.b 'Hey, you stink! damn,',254
	dc.b 'Do you ever wash?',254
	dc.b 'No way Im biting you!!',254
	dc.b 255,0
	
SeqChibikoChat1_No:
;       01234567890123456789012345
	dc.b 255,10,-2	;11=chibimad 10=Chibisad 9=chibihappy
	dc.b 'Yeah, thinking about it',254
	dc.b 'your pretty thin,I doubt',254
	dc.b 'Youre worth the effort!'
	dc.b 255,0
	
		
SeqChibikoChat2:
;       01234567890123456789012345
	dc.b 'Why are you hassling me?'
	dc.b 255,255
	
	dbbw 250,131,seqhenji-VramBase
	dc.b 254,254,254,254
	
	dc.b 2 ;Xpos =2 
	dc.b 250,133,0	;Typing Speed
		dc.b 'I want to kill you',254
		dc.b 'I really like you'
	dc.b 255,128+2		;128+4=4Choice
	dw SeqChibikoChat2_Kill-VramBase
	dw SeqChibikoChat2_Like-VramBase
	
SeqChibikoChat2_Like:
	dc.b 255,11,8	;11=chibimad 10=Chibisad 9=chibihappy
;       01234567890123456789012345	
	dc.b "God danm you're lame,",254
	dc.b "Go bother sakuya, she's,",254
	dc.b 'always begging for simps'
	dc.b 255,0
	
SeqChibikoChat2_Kill:
;       01234567890123456789012345
	dc.b 255,9,-8	;11=chibimad 10=Chibisad 9=chibihappy
	dc.b 'Bring it on Motherfunker!',254
	dc.b 'Ill kick your ass so hard',254
	dc.b 'you wont sit down for a',254,'lifetime!'
	dc.b 255,0
	
	

SeqChibikoChat3:
;       01234567890123456789012345
	dc.b 'You again?'
	dc.b 255,255
	
	dbbw 250,131,seqhenji-VramBase
	dc.b 254,254,254,254
	
	dc.b 2 ;Xpos =2 
	dc.b 250,133,0	;Typing Speed
		dc.b 'Make me a vampire!',254
		dc.b 'How can I kill you?'
	dc.b 255,128+2		;128+4=4Choice
	dw SeqChibikoChat3_Vamp-VramBase
	dw SeqChibikoChat3_Kill-VramBase
	
SeqChibikoChat3_Vamp:
	dc.b 255,9,-8	;11=chibimad 10=Chibisad 9=chibihappy
;       01234567890123456789012345	
	dc.b "No way,this world is only",254
	dc.b "big enough for one",254
	dc.b "vampire! And I'm so",254
	dc.b "awesome no other is",254,"even needed!!"
	dc.b 255,0
	
SeqChibikoChat3_Kill:
;       01234567890123456789012345
	dc.b 255,11,8	;11=chibimad 10=Chibisad 9=chibihappy
	dc.b "Kill me? You can't I'm",254
	dc.b "Immortal! Are you so",254
	dc.b "stupid you didn't know",254,"that?"
	dc.b 255,0
	
SeqChibikoChat4:
;       01234567890123456789012345
	dc.b 'Hey!What are you lurking',254
	dc.b 'around for?'
	dc.b 255,255
	
	dbbw 250,131,seqhenji-VramBase
;	dc.b 250,130, 183,210,151,255		;henji (romaji)
	;dc.b 'Reply:'
	dc.b 254,254,254,254
	
	dc.b 2 ;Xpos =2 
	dc.b 250,133,0	;Typing Speed
		dc.b 'Nothing!',254
		dc.b 'Looking for you!'
	dc.b 255,128+2		;128+4=4Choice
	dw SeqChibikoChat4_Nothing-VramBase
	dw SeqChibikoChat4_You-VramBase
	
SeqChibikoChat4_Nothing:
	dc.b 255,9,-8	;11=chibimad 10=Chibisad 9=chibihappy
;       01234567890123456789012345	
	dc.b "Good! Keep it up then,",254
	dc.b "and go away!"
	dc.b 255,0
	
SeqChibikoChat4_You:
;       01234567890123456789012345
	dc.b 255,11,8	;11=chibimad 10=Chibisad 9=chibihappy
	dc.b "WTF? Are you some wierd",254
	dc.b "Perverted twilight fan,",254
	dc.b "or something? I'm gonna",254
	dc.b "Keep an eye on you!sicko!",254
	dc.b 255,0
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Sakuya
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
SeqSakuyaGossipList:
	dc.b %0000011				;Mask for possible options (%11=4)
	dw SeqSakuyaGossip2-VramBase
	dw SeqSakuyaGossip4-VramBase
	dw SeqSakuyaGossip1-VramBase
	dw SeqSakuyaGossip3-VramBase
		
SeqSakuyaGossip2:
	dc.b 'I know all the gossip',254
	dc.b 'Who do you wanna hear',254,'about?'
;       01234567890123456789012345
	dc.b 255,255
	dc.b 'Reply:',254,254
	dc.b 254,254
	dc.b 2 ;Xpos =2 
	dc.b 250,133,0	;Typing Speed
		dc.b 'Chibiko',254
		dc.b 'Bochan'
	dc.b 255,128+2+64		;128+4=4Choice +64 =clear after pick
	dw SeqSakuyaGossip_Chibiko-VramBase
	dw SeqSakuyaGossip_Bochan-VramBase
	
SeqSakuyaGossip3:
	dc.b 'Bochan is weird!',254
;       01234567890123456789012345
	dc.b 'I suggested he get a ',254
	dc.b 'nicer hat, and he got',254,'super mad!'
	dc.b 255,0

SeqSakuyaGossip_Chibiko:
	dc.b 'Chibiko is so evil',254
;       01234567890123456789012345
	dc.b 'I saw her baiting animal',254
	dc.b 'traps with teddy bears!'
	dc.b 255,255
;       01234567890123456789012345
	dc.b 'Shes catching kids with',254
	dc.b 'them so she can drink',254,'their blood!'
	dc.b 255,0
SeqSakuyaGossip_Bochan:
;       01234567890123456789012345
	dc.b 'Bochan said hes lonely',254
	dc.b 'he said he wants a new',254,'pet',254
	dc.b 255,0
	
SeqSakuyaGossip4:
	dc.b 'I know chibikos secret!',254
;       01234567890123456789012345
	dc.b 'Shes so scared of stakes',254
	dc.b 'she hates everything',254,'pointed!'
	dc.b 255,0

	
SeqSakuyaGossip1:
	;   01234567890123456789012345
	dc.b 'Sakuya: So I was at the',254
	dc.b 'Mall,',250,134,3,'And you wont',254
	dc.b 'believe who I saw!',254
	dc.b 255,255	;2nd 255 = more text
	dc.b 'and she said so,',254
	dc.b 'and I sad no way',254
	dc.b 'and she said yes way',254
	dc.b 255,255	;2nd 255 = more text
	;   01234567890123456789012345
	dc.b 'and I said you cant be for',254
	dc.b 'real, and she said, its',254
	dc.b '100% true',254
	dc.b 'so it looks like that',254,'what happened!',255,0

	
SeqShopPoverty:
	dc.b 'Yume: I smell poverty!',254
	dc.b 250,134,3;Wait a bit
	dc.b 'Hey You! Poor!',254
	dc.b 250,134,3;Wait a bit
	dc.b 'Get lost ya bum!',254,'We dont serve your kind',254,'here!',254
	
	dc.b 255,255	;2nd 255 = more text
	dc.b 'Really where do those',254,'losers come from?'
	dc.b 255,0
	
SeqShopSell:
	dc.b 'Yume: Oh a customer!',254
	dc.b 250,134,3;Wait a bit
	;   01234567890123456789012345
	dc.b 'Whoa, who sold you that',254,'crappy item?',254
	dc.b 250,134,3;Wait a bit
	dc.b 'Oh, I did? Well Ill take',254
	dc.b 'it off your hands for $1',254,'Whacha say?',254
	dc.b 255,0
	
SeqShopBuy:
;       01234567890123456789012345
	dc.b 'Yume: Greetings customer!',254	
	dc.b 'Please feel free to',254
	dc.b 'overspend on any of our',254
	dc.b 'fine and proffitable',254,'products!'
	dc.b 255,0
SeqShopBuy2:
	dc.b 'What do you want to buy?',255
	
	
LstGifts:
	dw txtGift1-VramBase
	dw txtGift2-VramBase
	dw txtGift3-VramBase
	dw txtGift4-VramBase
	dw txtGift5-VramBase
	dw txtGift6-VramBase
	dw txtGift7-VramBase
	dw txtGift8-VramBase
	
txtGift1: 
	dc.b 10,1				;Char/Mood		;11=chibimad 10=Chibisad 9=chibihappy
	dw txtGiftReply_ChibikoNG-VramBase	;Chibiko reply
	dc.b 14,1				;Char/Mood
	dw txtGiftReply_BochanNG-VramBase	;Bochan reply
	dc.b 'Cake',254,255
	
		
txtGift2: 
	dc.b 9,-8				;Char/Mood		;11=chibimad 10=Chibisad 9=chibihappy
	dw txtGift2_Chibiko-VramBase	;Chibiko reply
	dc.b 13,0				;Char/Mood		14=bochanmad 13=bochansad 12=bochannhappy
	dw txtGiftReply_BochanNG-VramBase	;Bochan reply
	dc.b 'Teddy',254,255
	
	
txtGift2_Chibiko: 	
;       01234567890123456789012345
	dc.b 'Wow thanks!',254
	dc.b 'I needed more teddies!'
	dc.b 255,0	
	
txtGift3: 
	dc.b 9,-8				;Char/Mood		;11=chibimad 10=Chibisad 9=chibihappy
	dw txtGift3_Chibiko-VramBase	;Chibiko reply
	dc.b 13,0				;Char/Mood		14=bochanmad 13=bochansad 12=bochannhappy
	dw txtGiftReply_BochanNG-VramBase	;Bochan reply
	dc.b 'Pakurimon',254,255
	

txtGift3_Chibiko: 
;       01234567890123456789012345
	dc.b 'This is great!',254
	dc.b 'I can make Yume super',254,'jealous!'
	dc.b 255,0	

	
txtGift4: 
	dc.b 11,8				;Char/Mood		;11=chibimad 10=Chibisad 9=chibihappy
	dw txtGift4_Chibiko-VramBase	;Chibiko reply
	dc.b 13,0				;Char/Mood		14=bochanmad 13=bochansad 12=bochannhappy
	dw txtGiftReply_BochanNG-VramBase	;Bochan reply
	dc.b 'Crucifix earring',254,255
	

txtGift4_Chibiko: 
;       01234567890123456789012345
	dc.b 'What the fcuk can I do',254,'with this?',254
	dc.b 'My ears arent pierced',254,'dumbass!'
	dc.b 255,0	
	
txtGift5: 
	dc.b 10,0				;Char/Mood		;11=chibimad 10=Chibisad 9=chibihappy
	dw txtGiftReply_ChibikoNG-VramBase	;Chibiko reply
	dc.b 14,8				;Char/Mood		14=bochanmad 13=bochansad 12=bochannhappy
	dw txtGift5_Bochan-VramBase	;Bochan reply
	dc.b 'Funky Hat',254,255
	

txtGift5_Bochan: 
;       01234567890123456789012345
	dc.b 'This sucks!',254
	dc.b 'My hat is way better!'
	dc.b 255,0	
	
	
txtGift6: 
	dc.b 10,1				;Char/Mood		;11=chibimad 10=Chibisad 9=chibihappy
	dw txtGiftReply_ChibikoNG-VramBase	;Chibiko reply
	dc.b 13,1				;Char/Mood		14=bochanmad 13=bochansad 12=bochannhappy
	dw txtGiftReply_BochanNG-VramBase	;Bochan reply
	dc.b 'Cheese',254,255
	
txtGift7: 
	dc.b 11,8				;Char/Mood		;11=chibimad 10=Chibisad 9=chibihappy
	dw txtGift7_Chibiko-VramBase	;Chibiko reply
	dc.b 13,1				;Char/Mood		14=bochanmad 13=bochansad 12=bochannhappy
	dw txtGiftReply_BochanNG-VramBase	;Bochan reply
	dc.b 'Stinger Missile',254,255
	
txtGift7_Chibiko: 
;       01234567890123456789012345
	dc.b 'I can invoke fire with my',254
	dc.b 'bare hands! why would I',254,'want this crap'
	dc.b 255,0	
	
txtGift8: 
	dc.b 10,1				;Char/Mood		;11=chibimad 10=Chibisad 9=chibihappy
	dw txtGiftReply_ChibikoNG-VramBase	;Chibiko reply
	dc.b 12,-8			;Char/Mood		14=bochanmad 13=bochansad 12=bochannhappy
	dw txtGift8_Bochan-VramBase	;Bochan reply
	dc.b 'Rabid Weasel',254,255
	
txtGift8_Bochan: 	
;       01234567890123456789012345
	dc.b 'Oooh! Its so cute!',254
	dc.b 'I shall name him bob!'
	dc.b 255,0
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
txtGiftReply_ChibikoNG: 
	dc.b 'Whats this junk?'
	dc.b 255,0
	
txtGiftReply_BochanNG: 
	dc.b 'I dont want this!'
	dc.b 255,0
	
txtGiftReplyAgainList:
	dw txtGiftReplyAgain_Chibiko-VramBase
	dw txtGiftReplyAgain_Bochan-VramBase
		
txtGiftReplyAgain_Chibiko: 
	dc.b 'You already gave me this',254,'dumbass!'
	dc.b 255,0

txtGiftReplyAgain_Bochan: 
	dc.b 'Bleh! I already have this'
	dc.b 255,0

SeqShop_None: dc.b 'None',255
	
seqPause:
	dc.b 250,134,3,255;Wait a bit
	
seqType:
	dc.b 250,133,0,255 ;Type speed
	;dc.b 250,133,30,255 ;Type speed
	
	
TalkOptionSeq:	
	dc.b 254,'What now?',254;,254
	dc.b 254,254,2 	;Xpos =2 
	dc.b 250,133,0	;Typing Speed
	dc.b 'Talk',254
	dc.b 'Move',254
	dc.b 255

TalkOptionSeqGift:			
	dc.b 254,'What now?',254;,254
	dc.b 254,2 ;Xpos =2 
	dc.b 250,133,0	;Typing Speed
	dc.b 'Talk',254
	dc.b 'Move',254
	dc.b 'Give Gift',254
	dc.b 255
		
		
SeqShopSellOptions:
	dc.b 254,'Sell?',254,254
	dc.b 254,2 ;Xpos =2 
	dc.b 250,133,0	;Typing Speed
	dc.b 'Yes',254
	dc.b 'No',254
	dc.b 255
		
MapSeq:  
	dc.b 'Where to now?',254;,254
	dc.b 2 ;Xpos =2 
	dc.b 250,133,0	;Typing Speed
	dc.b 'Forest',254
	dc.b 'Mountains',254
	dc.b 'School',254
	dc.b 'Street',254
	dc.b 'Shop',255

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Sequence:
	ifd VideoFx16
		ifnd UseHQGraphics	
			include "resall/Reikou/ShindeKure/Images16_FrameDefs.asm"
			include "resall/Reikou/ShindeKure/Images16_FrameList.asm"
		else 
			include "resall/Reikou/ShindeKure/Images16HQ_FrameDefs.asm"
			include "resall/Reikou/ShindeKure/Images16HQ_FrameList.asm"
		endif 
	else 
		ifnd UseHQGraphics
			include "resall/Reikou/ShindeKure/Images_FrameDefs.asm"
			include "resall/Reikou/ShindeKure/Images_FrameList.asm"
		else 
			include "resall/Reikou/ShindeKure/Images4HQ_FrameDefs.asm"
			include "resall/Reikou/ShindeKure/Images4HQ_FrameList.asm"		
		endif 
	endif 
	
	

TestProgram_End:		
	even

	
	;align 16
;QTVData_base:	
	ifd VideoFx16
		ifnd UseHQGraphics	
BitStream:
			incbin "\ResALL\Reikou\ShindeKure\Images16_Stream.raw"
PixelBlock:
			incbin "\ResALL\Reikou\ShindeKure\Images16_Pixels.raw"
		endif 
	else 

		ifnd UseHQGraphics
BitStream:
			incbin "\ResALL\Reikou\ShindeKure\Images_Stream.raw"
PixelBlock:
			incbin "\ResALL\Reikou\ShindeKure\Images_Pixels.raw"
		endif 
	endif 
	
	ifd UseHQGraphics
			align 14
BitStream:

			incbin "\ResALL\Reikou\ShindeKure\Images16HQ_Stream.raw"
			align 14
PixelBlock:
			incbin "\ResALL\Reikou\ShindeKure\Images16HQ_Pixels.raw"
	endif 
	
	;align 16
	
	ifd VM_RamBase
		ifnd VM_RamBaseAddr
		even
VM_RamBaseAddr: dc.l VM_RamBase
		endif
	endif

	ifnd VM_RamBase
		even
VM_RamBaseAddr: dc.l VM_RamBase2+65536	
			
	
;VM_RamBase2:
		;ds.b 65536*2
;VM_HostRam:	
;		ds.b 256
	endif
	
	
	even
	include "srcall/ChibiVm_CPU.asm"		
	
	
	even
	include "core.asm"
	include "footer.asm"
	
	
	;Variables for our Emulator

