GEN_BMPscreen equ 1
GEN_UsePalette equ 1

X68_UsePalette equ 1

VscreenMinX equ 64		;Top left of visible screen in logical co-ordinates
VscreenMinY equ 80

VscreenWid equ 128		;Visible Screen Size in logical units
VscreenHei equ 96

;compile with option: VASM GEN

	include "header.asm"
	
	include "srcall/ChibiVm_InstSet.asm"
	include "srcall/BasicMacros.asm"

	ifd BuildSQL
VM_RamBase equ $30000
VM_HostRam equ $003F000	;Variables for our Emulator
	endif
	
	ifd BuildNEO
VM_RamBase equ $100000
VM_HostRam	equ $10FE00	;Variables for our Emulator
	endif
	
	ifd BuildGEN
VM_RamBase equ $00FF0000
VM_HostRam	equ $00FFFE00	;Variables for our Emulator
	endif
	
;	ifd BuildAST
;VM_RamBase equ ramarea+65536	
;VM_HostRam	equ ramarea+$1FE00	;Variables for our Emulator
;SpriteArrayRam equ $300	
;	endif
	
	
VM_ProgLoadAddr equ $400	

	ifnd SpriteArrayRam
	ifd VM_RamBase
HspriteCount equ VM_RamBase+64
HspriteLimit equ VM_RamBase+65
SpriteArrayRam equ VM_RamBase+$300	
	else
SpriteArrayRam equ $300	
	endif
	endif

tempbuffer equ ramarea+128	
	
GEN_SpritePatternVRAM equ $8000
GEN_SpritePatternCount equ 64	
	
SpritePatterns equ 0 ;Remap pointer to Hsprites
;SpriteArrayRam equ $300 ;Remap pointer to SpriteArrayRamR

vmAddressRemap_BigEndian equ 1			;Little endian calculations won't work due to relocatable code


SpritePatternSize equ 32

;	ifd BuildAST
;		and.l  #$FFFF0000,(VM_RamBaseAddr)	;Ensure VM ram ends $????0000
;	endif
	ifnd VM_RamBase
		and.l  #$FFFF0000,(VM_RamBaseAddr)	;Ensure VM ram ends $????0000
	endif

	
	jsr ChibiVM_Init

	
	;move.l #HSprites,a3
	;jsr NativeSpr_Init

	;move.l #$2000,d1
	;move.l d1,(vm_remap_TableAddr)
	
	;move.l #1,a3
	;jsr AddressRemapViaTableHLA3
	
	;ove.l (VM_RamBaseAddr),d6
	;move.l (vm_remap_TableAddr),d7
	
	;We djsr Monitor
	
	;jmp $
	;move.l #SpriteArrayRam,a3
	;jsr NativeSpr_DrawArrayReiKou
	
	
	;jsr Monitor_MemDump		;Dump 6 lines from  $00000000
	;dc.l TestProgram
	;dc.w $2
	
	;jsr Monitor_MemDump		;Dump 6 lines from  $00000000
	;dc.l VM_RamBase+VM_ProgLoadAddr
	;dc.w $2
	;jmp $
	
	;jsr VM_Run_WithMonitor
	
VM_Run:	
	jsr VM_Tick
	jmp VM_Run
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	dwle 1+1
	dwle 2
	dwle 3
	dwle $111
	dwle $222
	dwle $333
	
	even

		
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	

	
	include "sources/ReiKou/Reikou_ALL_MultiplatformBitmap.asm"
	
	
	include "../ChibiVM/Multiplatform_MonitorA.asm"
	include "ChibiVM_AdventureEngine.asm"
	include "sources/ChibiVM/ChibiVM_Host.asm"
	
	
	
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

	
		
ballpos equ			64+16
ballmove equ		64+18
PlayerPaddle equ	64+20
CpuPaddle equ		64+22
PlayerScore equ		64+24
CpuScore equ		64+25
GameTick equ		64+26
GameSpeed equ		64+27		
GameAI equ			64+28
SoundByte equ		64+29 

ProgramLaunch:

	dbbb movx,r3_imm8,191
;                                     testagain:    
testagain:
;                                         ld a,b
	dbb movx,r0_r3
;                                         rrca
	db asrb
;                                         rrca
	db asrb
;                                         rrca
	db asrb
;                                         ;rrca

;                                         and %00001111
	dbb andi,%00001111
;                                         ld d,b
	dbbb movx,zeropg_r3,r5
;                                         ld e,b
	dbb movx,r4_r3
;                                         ld l,0                ;ld = xpos e=ypos
	dbbb movx,r6_imm8,0
;                                         push bc
	;db ph2b
;                                             call mpbitmap_setpixel
	;dbw bsrj,mpbitmap_setpixel
	MBcall mbSetpixel					;Diagonal line
;                                         pop bc
	;db pl2b
;                                         

;                                         

;                                         

;                                         ld a,b
	dbb movx,r0_r3
;                                         rrca
	db asrb
;                                         rrca
	db asrb
;                                         rrca
	db asrb
;                                         ;rrca

;                                         and %00001111
	dbb andi,%00001111
;                                         ld d,b
	dbbb movx,zeropg_r3,r5
;                                         ld e,b
	dbb movx,r4_r3
;                                         srl e
    dbb lsrz,r4
;                                         srl e
    dbb lsrz,r4
;                                         srl e
    dbb lsrz,r4
;                                         ld l,0
	dbbb movx,r6_imm8,0
;                                         

;                                         push bc
;	db ph2b
;                                             call mpbitmap_setpixel
	;dbw bsrj,mpbitmap_setpixel
	MBcall mbSetpixel
;                                         pop bc
	;db pl2b
;                                         

;                                         ld d,b
	dbbb movx,zeropg_r3,r5
;                                         ld e,b
	dbb movx,r4_r3
;                                         ld l,0
	dbbb movx,r6_imm8,0
;                                         

;                                         push bc
	;db ph2b
;                                             call mpbitmap_getpixel
	dbb movi,1
	;dbw bsrj,mpbitmap_getpixel
	MBcall mbGetpixel
;                                         pop bc
	;db pl2b
;                                         inc a
	db incb
;                                         ld d,b
	dbbb movx,zeropg_r3,r5
;                                         inc d
	dbb incz,r5
;                                         inc d 
	dbb incz,r5
;                                         inc d
	dbb incz,r5
;                                         ld e,b
	dbb movx,r4_r3
;                                         ld l,0
	dbbb movx,r6_imm8,0
;                                         push bc
	;db ph2b
;                                             call mpbitmap_setpixel
	;dbw bsrj,mpbitmap_setpixel
	MBcall mbSetpixel
;                                         pop bc
	;db pl2b
;                                         

;                                         

;                                         djnz testagain
	dbb decz,r3
	dbw bnej,testagain-VramBase

	
TileTest:	
	
	dbbw mov16x,r6_imm16,0;bitmap2bitplane
;                                         ld de,&0010
	dbbw mov16x,r4_imm16,$0010
;                                             

;                                         ld c,6
	dbbb movx,r2_imm8,6
;                                     tiletestagainy3:    
tiletestagainy3:
;                                         ld b,6
	dbbb movx,r3_imm8,6
;                                     tiletestagainx3:    
tiletestagainx3:
;                                         ld a,2
	dbb movi,2
;                                         push bc
	db ph2b
;                                         push de
	db ph4b
;                                             call mpbitmap_settile
	;dbw bsrj,mpbitmap_settile
	MBcall mbSettile
;                                         pop de
	db pl4b
;                                         inc d
	dbb incz,r5
;                                         pop bc
	db pl2b
;                                         djnz tiletestagainx3
	dbb decz,r3
	dbw bnej,tiletestagainx3-VramBase
;                                         ld d,0
	dbbbb movx,zeropg_imm8,r5,0
;                                         inc e
	dbb incz,r4
;                                         dec c
	dbb decz,r2
;                                         jr nz,tiletestagainy3
	dbb bnei,tiletestagainy3-lbl_1CD7xD783
lbl_1CD7xD783
;                                         

;                                         

;                                         ld hl,bitmap4bitplane
	dbbw mov16x,r6_imm16,1;bitmap4bitplane
;                                         ld de,&0008
	dbbw mov16x,r4_imm16,$0008
;                                             

;                                         ld c,6
	dbbb movx,r2_imm8,6
;                                     tiletestagainy:    
tiletestagainy:
;                                         ld b,6
	dbbb movx,r3_imm8,6
;                                     tiletestagainx:    
tiletestagainx:
;                                         ld a,4
	dbb movi,4
;                                         push bc
	db ph2b
;                                         push de
	db ph4b
;                                             call mpbitmap_settile
	;dbw bsrj,mpbitmap_settile
	MBcall mbSettile
;                                         pop de
	db pl4b
;                                         inc d
	dbb incz,r5
;                                         pop bc
	db pl2b
;                                         djnz tiletestagainx
	dbb decz,r3
	dbw bnej,tiletestagainx-VramBase
;                                         ld d,0
	dbbbb movx,zeropg_imm8,r5,0
;                                         inc e
	dbb incz,r4
;                                         dec c
	dbb decz,r2
;                                         jr nz,tiletestagainy
	dbb bnei,tiletestagainy-lbl_9803x75B7
lbl_9803x75B7
;                                         

;                                         

;                                         ld de,&0008
	dbbw mov16x,r4_imm16,$0008
;                                         ld c,6
	dbbb movx,r2_imm8,6
;                                     tiletestagainy2:    
tiletestagainy2:
;                                         ld b,6
	dbbb movx,r3_imm8,6
;                                     tiletestagainx2:    
tiletestagainx2:
;                                         

;                                         push bc
	db ph2b
;                                         push de
	db ph4b
;                                             push de
	db ph4b
;                                                 ld hl,tempbuffer
	dbbw mov16x,r6_imm16,2 ;tempbuffer
;                                                 ld a,1
	dbb movi,1
	MBcall mbGettile
;                                             pop de
	db pl4b
;                                             ld hl,tempbuffer
	dbbw mov16x,r6_imm16,2 ;tempbuffer
;                                             ld a,d
	dbbb movx,r0_zeropg,r5
;                                             add 24
	dbb addi,12
;                                             ld d,a
	dbbb movx,zeropg_r0,r5
;                                             

;                                             

;                                             ld a,1
	dbb movi,1
	MBcall mbSettile
;                                         pop de
	db pl4b
;                                         inc d
	dbb incz,r5
;                                         pop bc
	db pl2b
;                                         djnz tiletestagainx2
	dbb decz,r3
	dbw bnej,tiletestagainx2-VramBase
;                                         ld d,0
	dbbbb movx,zeropg_imm8,r5,0
;                                         inc e
	dbb incz,r4
;                                         dec c
	dbb decz,r2
;                                         jr nz,tiletestagainy2
	dbb bnei,tiletestagainy2-lbl_7409xD7E8
lbl_7409xD7E8
;                                         

;                                     


	db hltb
	


	
vm_traps: 	dw ((ProgramLaunch-TestProgram)+VM_ProgLoadAddr)

	align 13
vm_AddressRemapTable:
	ifd VM_RamBase
		dc.l Bitmap2bitplane-VramBase+VM_RamBase	;0
		dc.l Bitmap4bitplane-VramBase+VM_RamBase 	;1
	else
		dc.l Bitmap2bitplane-VramBase
		dc.l Bitmap4bitplane-VramBase
	endif
	dc.l tempbuffer	;2
	even
	
	

Bitmap2bitplane:
	;dc.l $12345678
	incbin "\ResALL\Sprites\RawGB.RAW"
	
Bitmap4bitplane:
	
	incbin "\ResALL\Sprites\RawSMS_16Color.RAW"
	
TestProgram_End:		
	even 
	;align 16
	
	ifd VM_RamBase
		ifnd VM_RamBaseAddr
		even
VM_RamBaseAddr: dc.l VM_RamBase
		endif
	endif

	ifnd VM_RamBase
VM_RamBaseAddr: dc.l VM_RamBase2+65536	
	
		even
; VM_RamBase2:
		; ds.b 65536*2
; VM_HostRam:	
		; ds.b 256
	endif
	
X68_Palette:	
    dc.w %0000000000000000; ;0  %GGGGGRRRRRBBBBB-
    dc.w %0000010000100000; ;1  %GGGGGRRRRRBBBBB-
    dc.w %1111100000111110; ;2  %GGGGGRRRRRBBBBB-
    dc.w %1111111111111110; ;3  %GGGGGRRRRRBBBBB-
    dc.w %0000010000010000; ;4  %GGGGGRRRRRBBBBB-
    dc.w %1000000000100000; ;5  %GGGGGRRRRRBBBBB-
    dc.w %1000010000111110; ;6  %GGGGGRRRRRBBBBB-
    dc.w %0000011111000000; ;7  %GGGGGRRRRRBBBBB-
    dc.w %1111100000010000; ;8  %GGGGGRRRRRBBBBB-
    dc.w %0111111110110010; ;9  %GGGGGRRRRRBBBBB-
    dc.w %1000010000111110; ;10  %GGGGGRRRRRBBBBB-
    dc.w %0000000000111110; ;11  %GGGGGRRRRRBBBBB-
    dc.w %1000000000000000; ;12  %GGGGGRRRRRBBBBB-
    dc.w %1110110110011000; ;13  %GGGGGRRRRRBBBBB-
    dc.w %0000011111100000; ;14  %GGGGGRRRRRBBBBB-
    dc.w %1111011110111100; ;15  %GGGGGRRRRRBBBBB-

	
GEN_Palette:
    dc.w %0000000000000000; ;0  %----BBB-GGG-RRR-
    dc.w %0000100000001000; ;1  %----BBB-GGG-RRR-
    dc.w %0000111011100000; ;2  %----BBB-GGG-RRR-
    dc.w %0000111011101110; ;3  %----BBB-GGG-RRR-
    dc.w %0000010000001000; ;4  %----BBB-GGG-RRR-
    dc.w %0000100010000000; ;5  %----BBB-GGG-RRR-
    dc.w %0000111010001000; ;6  %----BBB-GGG-RRR-
    dc.w %0000000000001110; ;7  %----BBB-GGG-RRR-
    dc.w %0000010011100000; ;8  %----BBB-GGG-RRR-
    dc.w %0000110001101110; ;9  %----BBB-GGG-RRR-
    dc.w %0000111010001000; ;10  %----BBB-GGG-RRR-
    dc.w %0000111000000000; ;11  %----BBB-GGG-RRR-
    dc.w %0000000010000000; ;12  %----BBB-GGG-RRR-
    dc.w %0000011011101010; ;13  %----BBB-GGG-RRR-
    dc.w %0000100000001110; ;14  %----BBB-GGG-RRR-
    dc.w %0000111011101110; ;15  %----BBB-GGG-RRR-
    dc.w %0000111000001110; ;16  %----BBB-GGG-RRR-
    dc.w %0000000000000000; ;17  %----BBB-GGG-RRR-
    dc.w %0000000000000000; ;18  %----BBB-GGG-RRR-
    dc.w %0000000000000000; ;19  %----BBB-GGG-RRR-
    dc.w %0000001000100010; ;20  %----BBB-GGG-RRR-
    dc.w %0000001000100010; ;21  %----BBB-GGG-RRR-
    dc.w %0000001000100010; ;22  %----BBB-GGG-RRR-
    dc.w %0000001000100010; ;23  %----BBB-GGG-RRR-
    dc.w %0000010001000100; ;24  %----BBB-GGG-RRR-
    dc.w %0000010001000100; ;25  %----BBB-GGG-RRR-
    dc.w %0000010001000100; ;26  %----BBB-GGG-RRR-
    dc.w %0000010001000100; ;27  %----BBB-GGG-RRR-
    dc.w %0000011001100110; ;28  %----BBB-GGG-RRR-
    dc.w %0000011001100110; ;29  %----BBB-GGG-RRR-
    dc.w %0000011001100110; ;30  %----BBB-GGG-RRR-
    dc.w %0000011001100110; ;31  %----BBB-GGG-RRR-
    dc.w %0000100010001000; ;32  %----BBB-GGG-RRR-
    dc.w %0000100010001000; ;33  %----BBB-GGG-RRR-
    dc.w %0000100010001000; ;34  %----BBB-GGG-RRR-
    dc.w %0000100010001000; ;35  %----BBB-GGG-RRR-
    dc.w %0000101010101010; ;36  %----BBB-GGG-RRR-
    dc.w %0000101010101010; ;37  %----BBB-GGG-RRR-
    dc.w %0000101010101010; ;38  %----BBB-GGG-RRR-
    dc.w %0000101010101010; ;39  %----BBB-GGG-RRR-
    dc.w %0000110011001100; ;40  %----BBB-GGG-RRR-
    dc.w %0000110011001100; ;41  %----BBB-GGG-RRR-
    dc.w %0000110011001100; ;42  %----BBB-GGG-RRR-
    dc.w %0000110011001100; ;43  %----BBB-GGG-RRR-
    dc.w %0000111011101110; ;44  %----BBB-GGG-RRR-
    dc.w %0000111011101110; ;45  %----BBB-GGG-RRR-
    dc.w %0000111011101110; ;46  %----BBB-GGG-RRR-
    dc.w %0000111011101110; ;47  %----BBB-GGG-RRR-
    dc.w %0000000000000010; ;48  %----BBB-GGG-RRR-
    dc.w %0000000000100100; ;49  %----BBB-GGG-RRR-
    dc.w %0000000000100100; ;50  %----BBB-GGG-RRR-
    dc.w %0000001001000110; ;51  %----BBB-GGG-RRR-
    dc.w %0000010001000100; ;52  %----BBB-GGG-RRR-
    dc.w %0000010001001000; ;53  %----BBB-GGG-RRR-
    dc.w %0000010001101010; ;54  %----BBB-GGG-RRR-
    dc.w %0000011010001010; ;55  %----BBB-GGG-RRR-
    dc.w %0000010010001100; ;56  %----BBB-GGG-RRR-
    dc.w %0000011010001100; ;57  %----BBB-GGG-RRR-
    dc.w %0000101010101010; ;58  %----BBB-GGG-RRR-
    dc.w %0000101010101100; ;59  %----BBB-GGG-RRR-
    dc.w %0000011010101110; ;60  %----BBB-GGG-RRR-
    dc.w %0000011011001110; ;61  %----BBB-GGG-RRR-
    dc.w %0000101011001110; ;62  %----BBB-GGG-RRR-
    dc.w %0000101011001110; ;63  %----BBB-GGG-RRR-
	
	
	even
	include "srcall/ChibiVm_CPU.asm"		
	
	even
	include "core.asm"
	include "footer.asm"
	
	
	;Variables for our Emulator

