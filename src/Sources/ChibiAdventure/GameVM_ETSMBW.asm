;IMG_NoHeader equ 1
;IMG_NoTitle equ 1

;CheatMode equ 1				;Show Stats every week
;CheatMode_Cash equ 1		;Give me money
;I_Am_Very_Rude	equ 1		;Uncensored version

;Game inspired by:
;https://en.wikipedia.org/wiki/Rock_Star_Ate_My_Hamster

;Game title based on:
;https://www.theguardian.com/technology/2019/jul/12/belle-delphine-gamer-girl-instagram-selling-bath-wate

;Hints

;Skill defines how likely you are to make a mistake and get bad PR
;Skill is a hidden value outside of cheat mode

;Investment in research/Gpu increases your skill
;Livestreams pay more, but are more expensive than pre-recorded 

;You win if you get max subs and max reputation



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

	ifd VM_RamBase
	
valViewers equ VM_RamBase+24			;2 bytes 	10-100 / 0-7
valReputation equ valViewers+2		;1 Byte		0-255 
valSkillz equ valReputation+1		;1 byte		0-255 (Chance of f-ups) 
valCash equ valSkillz+1				;4 byte bcd 
valMyName equ valCash+4				;16 byte string 
valWeek equ valMyName+16			;1 byte week 4-0
valGraph equ valWeek+1			;32 bytes ;16 bytepairs for Rep $ viewers
	
	else
	
valViewers equ 24			;2 bytes 	10-100 / 0-7
valReputation equ valViewers+2		;1 Byte		0-255 
valSkillz equ valReputation+1		;1 byte		0-255 (Chance of f-ups) 
valCash equ valSkillz+1				;4 byte bcd 
valMyName equ valCash+4				;16 byte string 
valWeek equ valMyName+16			;1 byte week 4-0
valGraph equ valWeek+1			;32 bytes ;16 bytepairs for Rep $ viewers
	
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
	
	include "SrcALL/ChibiVm_InstSet.asm"
	include "SrcALL/BasicMacros.asm"

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


	
	
	
	
	;jsr monitor 
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

	ifnd SpritePatternSize
SpritePatternSize equ 32
	endif

;; WHY WAS THIS FFFFf000????
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

	
	;move.l #HSprites,a3
	;jsr NativeSpr_Init

	;move.l #$2000,d1
	;move.l d1,(vm_remap_TableAddr)
	
	;move.l #1,a3
	;jsr AddressRemapViaTableHLA3
	
	;ove.l (VM_RamBaseAddr),d6
	;move.l (vm_remap_TableAddr),d7
	
	;jsr Monitor
	
	;jmp $
	;move.l #SpriteArrayRam,a3
	;jsr NativeSpr_DrawArrayReiKou
	
	
	;jsr Monitor_MemDump		;Dump 6 lines from  $00000000
	;dc.l TestProgram
	;dc.w $2
	
	
	
	
	;jsr VM_Run_WithMonitor
	
VM_Run:	
	jsr VM_Tick
	jmp VM_Run
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	even

		
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;include "SrcALL/V1_NativeSprite.asm"	
	even
	
	include "SrcALL/Multiplatform_RLE.asm"
	
	include "../ChibiVM/Multiplatform_MonitorA.asm"
	
	;include "Sources/ReiKou/Reikou_ALL_MaxTile.asm"
	include "AdventureEngineX_Monitor.asm"
	
	include "ChibiVM_AdvMathsBCD.asm"
	include "ChibiVM_AdvMaths.asm"
	include "ChibiVM_AdvancedInput.asm"
	include "SrcALL/Multiplatform_OSK.asm"
	
	include "SrcAll/V1_Palette.asm"
	
	include "Sources/ReiKou/Reikou_ALL_MultiplatformBitmap2.asm"
	include "Sources/ReiKou/Reikou_ALL_MultiplatformBitmap.asm"

	
	
	include "ChibiVM_RLE.asm"
	include "ChibiVM_AdventureEngineX.asm"	;Must come before  ChibiVM_AdventureEngine.asm
	;include "SrcALL/V1_GenericAnimator.asm"	;Must come before  ChibiVM_AdventureEngine.asm
	include "AdventureEngineX.asm"				;Must come before  ChibiVM_AdventureEngine.asm
	include "ChibiVM_AdventureEngine.asm"
	include "Sources/ChibiVM/ChibiVM_Host.asm"

	
	
	
	
	;ifd DoubleBuffered
		;include "SrcAll/V1_MaxTile_DirectDriver.asm"
	;else
		;read "\SrcAll\V1_MaxTile_CacheDriver.asm"
	;endif 

	
	;read "\SrcAll\V1_MaxTile_Expanders.asm"
 	;read "\SrcAll\V1_MaxTile.asm"

	
	
	
	
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
		;dbw bsrj,DrawGraph-VramBase

		; dbbw mov16x,r4_imm16,$0000 
		; dbb movi,'!'
		; advcall aprintchar
		; db hltb


;Init Game Vars
	dbb SYSi,syscallLoadMultiReg	
	dc.b %01110000
		dw 16							;16 bytes
		dw valMyName					;Val in ram
		dw strDefaultName-VramBase		;Default name 
	advcall aDoLdir						;Transfer default streamer name
			
	dbbwb movx,Addr16_imm8,valSkillz,32				;Default skill
		
	dbbww mov16x,Addr16_imm16,valCash,$1000			;Default cash
	
	ifd CheatMode_Cash
		dbbww mov16x,Addr16_imm16,valCash+2,$0100	;Cheat cash!
	else 
		dbbww mov16x,Addr16_imm16,valCash+2,$0000
	endif 
		
	dbbwb movx,addr16_imm8,valReputation,%01100000	;Default reputation
		
	dbbww mov16x,addr16_imm16,valViewers,$000A		;Default viewers 
													; (Should be 10-99)
		
	;dbw braj,GameLoop	;Skip the Name setup / Title 

	
;Show title screen
	
	dbw bsrj,ShowTitle-VramBase					;Show title screen
	
	ifnd IMG_NoTitle
		advcall aWaitForFire
	endif 
	advcall aCls

;Name entry screen
	
	dbbw mov16x,r4_imm16,$0000			;cursorpos
	dbbw mov16x,r6_imm16,strEnterName-VramBase	;Enter name message
	advcall aprintseq

	dbbw mov16x,r4_imm16,$0001			;cursorpos
	dbbw mov16x,r6_imm16,valMyName		;String 
	advcall aprintseq					;Show Default name 
	
	dbb SYSi,syscallLoadMultiReg		
	dc.b %11110000
		dc.b ' ',0		;Char,Unused
		dc.b 15,12		;Charlimit,start Charpos (for Del)
		dc.b 1,0			;Ypos,Xpos			 Default name is 12 chars 
		dw valMyName	;String address 
	AdvInputCall aiGetString
		
		
;Main Game loop
	
GameLoop:
	dbbwb movx,addr16_imm8,valWeek,4	;4 actions per month
	
MonthLoop:	

	
	dbbw mov16x,r6_imm16,Actions-VramBase	;Option List
	dbbb movx,r4_imm8,6				;Max option
	dbw bsrj,ShowSelectCursor-VramBase		;Show list and get response
			
	dc.b cmpi,0
	dbw beqj,MonthResume-VramBase			;0 - Skip this turn
	
	dc.b decb
	dbw beqj,StreamLive-VramBase				;1 High risk, high reward subs, Money
	
	dc.b decb
	dbw beqj,PreRecorded-VramBase			;2 Low risk, Low reward subs, No money
	
	dc.b decb
	dbw beqj,DoSponsor-VramBase				;3 Earn Money, Risk losing rep
	
	dc.b decb
	dbw beqj,DoPromo-VramBase				;4 try to gain subs/rep
	
	dbw braj,DoInvestment-VramBase			;5 Misc tricks
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
MonthResume:		
	ifd CheatMode
		dbw bsrj,DrawGraph-VramBase
	endif 

	dbbw decx,addr16_r0,valWeek
	dbw bnej,MonthLoop-VramBase		;4 ticks per month
	
	dbbb movx,r1_imm8,0		;Payment mult
	dbw bsrj,GetPaid-VramBase
	
	dbbb movx,r2_imm8,-1
	dbw bsrj,ViewersAddR2-VramBase	;Depleat subs as viewers get bored 

	dbw bsrj,GetByteViewers-VramBase
	dbb movx,r1_r0			;Cyan
	dbbw movx,r0_addr16,valReputation	;Purple
	
	dbw bsrj,UpdateGraph-VramBase	;Add items to top of graph
	
	dbw bsrj,DrawGraph-VramBase		;Show Graph
	dbw bsrj,ShowStreamers-VramBase	;Show ranking
	
	dbw braj,GameLoop-VramBase
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

ShowLostGame:		
	dbbw mov16x,r4_imm16,LostGame-VramBase		;Game over Lost (Bankrupt)
	dbw braj,ShowWonGameb-VramBase
	
ShowWonGame:	
	dbbw mov16x,r4_imm16,WonGame-VramBase		;Game Over Won (Top Rep+Subs)
	
ShowWonGameb:		
	dbbw mov16x,r6_imm16,NewsTitle-VramBase
	dbw bsrj,ShowStrNamStr-VramBase				;Show String,Name,String 
	dc.b hltb 
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PreRecorded:	
	dbbw movx,r4_Addr16,valSkillz	;ToRange
	dbw bsrj,MaybeDisaster-VramBase			;Lower risk with pre-recorded 
	
	dbbb movx,r1_imm8,1				;Skill cost
	dbw bsrj,SubSkill-VramBase	;R0=R0-R1 (Limit to 255)
	dbw braj,StreamLive_SubsUp-VramBase
				
StreamLive:	
	dbbb movx,r1_imm8,0			;Pay Level +0
	dbw bsrj,GetPaid-VramBase			;Get paid extra for streaming 
		
	dbbw movx,r4_Addr16,valSkillz	;ToRange
	dbb lsrz,r4						;Higher risk with streaming 
	dbw bsrj,MaybeDisaster-VramBase
	
	dbbb movx,r1_imm8,3				;Skill cost 
	dbw bsrj,SubSkill-VramBase	;R0=R0-R1 (Limit to 255)

StreamLive_SubsUp:
	advcall aDoRandom
	dbb andi,%0000111
	dc.b incb
	dbb movx,r3_r0			;1-8 mult for subs

	dbbb movx,r2_imm8,2		;Subs=subs+ 3*(1-8)
	dbw bsrj,ViewersAddR2R3-VramBase	;Add/sub R2(-10 to +10 max) 
	
	dbbb movx,r1_imm8,1		;Rep++
	dbw bsrj,AddRep-VramBase			;R0=R0+R1 (Limit to 255)
	
	dbw braj,MonthResume-VramBase
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

DoInvestment:
	dbbw mov16x,r6_imm16,Investments-VramBase	;Option List
	dbbb movx,r4_imm8,6				;Max option
	dbw bsrj,ShowSelectCursor-VramBase		;Show list and get response
	
	dbb cmpi,0
	dbw beqj,InvestResearch-VramBase			;0 very cheap,Low skill gain
	
	dc.b decb
	dbw beqj,InvestAds-VramBase				;1 Cheap, low sub/rep gain
	
	dc.b decb
	dbw beqj,InvestGPU-VramBase				;2 Moderate , moderate skill gain
	
	dc.b decb
	dbw beqj,InvestViews-VramBase			;3 High sub gain, High risk of failure
									; 				(Damages sub/rep)
	dc.b decb
	dbw beqj,InvestStaff-VramBase			;4 very Expensive, High skill gain
	
	dc.b decb
	dbw beqj,InvestCrisis-VramBase			;5 very Expensive, Doubles rep up to 96

	dbw braj,MonthResume-VramBase

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

InvestCrisis:
	dbbw mov16x,r6_imm16,Payments100K-VramBase
	dbw bsrj,Cash_Spend-VramBase			;R6=AmountToSpend
	
	dbbw movx,r0_addr16,valReputation
	dc.b lslb						;Rep <<1
	dbb orri,15					;Rep | %00001111
	dbb cmpi,96	
	dbw bcsj,InvestCrisis_NotMax-VramBase
	dbb movi,96					;Can't go above 96 via crisis mgmt
InvestCrisis_NotMax:	
	dbbw movx,addr16_r0,valReputation
	
	dbw braj,MonthResume-VramBase

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
InvestViews:
	dbbw mov16x,r6_imm16,Payments10K-VramBase
	dbw bsrj,Cash_Spend-VramBase			;R6=AmountToSpend
	
	advcall aDoRandom
	dbb andi,3					;1 in 4 chance of failure 
	dbw beqj,InvestViewsFail-VramBase
	
	dbbb movx,r2_imm8,10		;30 subs add 
	dbbb movx,r3_imm8,3
	dbw bsrj,ViewersAddR2R3-VramBase	;Add/sub R2(-10 to +10 max) * R3
	
	dbbb movx,r1_imm8,2			;2 rep add 
	dbw bsrj,AddRep-VramBase	;R0=R0+R1 (Limit to 255)
	dbw braj,MonthResume-VramBase
	
InvestViewsFail:	
	dbbw mov16x,r6_imm16,NewsTitle-VramBase
	dbbw mov16x,r4_imm16,CaughtPaying-VramBase
	dbw bsrj,ShowStrNamStr-VramBase		;Show user caught buying subs msg 

	dbbb movx,r2_imm8,-7		;Lose some subs
	dbbb movx,r3_imm8,3
	dbw bsrj,ViewersAddR2R3-VramBase	;Add/sub R2(-10 to +10 max) 
	
	dbbb movx,r1_imm8,40		;Lose a lot of rep
	dbw bsrj,SubRep-VramBase				;R0=R0-R1 (Limit to 0)
	
	dbw braj,MonthResume-VramBase

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
InvestStaff:
	dbbw mov16x,r6_imm16,Payments40K-VramBase
	dbbb movx,r1_imm8,24		;Skill gain
	dbw braj,InvestResearchB-VramBase
	
	
InvestGPU:	
	dbbw mov16x,r6_imm16,Payments10K-VramBase
	
	dbbw mov16x,r4_imm16,$0030 	;Gain 0-48
	advcall arangedrandom
	dbb movx,r1_r0				;Skill gain
	dbw braj,InvestResearchB-VramBase
	
	
InvestResearch:
	dbbw mov16x,r6_imm16,Payments100-VramBase
	dbbb movx,r1_imm8,3			;Skill gain

InvestResearchB:	;R1=Skill R6=Cost
	dbw bsrj,AddSkill-VramBase			;R0=R0+R1 (Limit to 255)
	
	dbw bsrj,Cash_Spend-VramBase			;R6=AmountToSpend
	
	dbw braj,MonthResume-VramBase
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
InvestAds:
	dbbb movx,r1_imm8,3		;0-3 Result from Ad
	
	advcall aDoRandom		
	dbb andx,r1_r0
	dbw bsrj,AddRep-VramBase			;R0=R0+R1 (Limit to 255)
	
	dbbw mov16x,r6_imm16,Payments1K-VramBase
	dbw bsrj,Cash_Spend-VramBase		;R6=AmountToSpend
	
	dbw braj,MonthResume-VramBase

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoPromo:
	dbbw mov16x,r6_imm16,Promotions-VramBase	;Option List
	dbbb movx,r4_imm8,4				;Max option
	dbw bsrj,ShowSelectCursor-VramBase		;Show list and get response

	dbbw mov16x,r6_imm16,GoodNewsStunt-VramBase	 	;Title
	dbbw mov16x,r4_imm16,StuntList-VramBase			;List
	dbbw mov16x,r2_imm16,Payments100-VramBase		;Cost
	dbbbb movx,Zeropg_imm8,r8,7				;Rep+SubGain
	dbbbb movx,Zeropg_imm8,r9,7				;Risk
	
	dbb cmpi,0			;0 - Stunt High risk, High reward cheap
	dbw beqj,DoPromoApply-VramBase			
	
	dbbw mov16x,r6_imm16,GoodNewsCollab-VramBase		;Title
	dbbw mov16x,r4_imm16,CollabList-VramBase			;List
	dbbw mov16x,r2_imm16,Payments100-VramBase		;Cost
	dbbbb movx,Zeropg_imm8,r8,3				;Rep+SubGain
	dbbbb movx,Zeropg_imm8,r9,3				;Risk
	
	dc.b decb				;1 - Collab Moderate risk, Moderate reward, cheap
	dbw beqj,DoPromoApply-VramBase			
		
	dbbw mov16x,r6_imm16,GoodNewsCharity-VramBase	;Title
	dbbw mov16x,r4_imm16,CharityList-VramBase		;List
	dbbw mov16x,r2_imm16,Payments1K-VramBase			;Cost
	dbbbb movx,Zeropg_imm8,r8,3				;Rep+SubGain
	dbbbb movx,Zeropg_imm8,r9,2				;Risk
	
	dc.b decb				;2 - Charity Low risk, Low reward
	dbw beqj,DoPromoApply-VramBase			
		
	dbbw mov16x,r6_imm16,GoodNewsGiveaway-VramBase	;Title
	dbbw mov16x,r4_imm16,GiveAwayList-VramBase		;List
	dbbw mov16x,r2_imm16,Payments10K-VramBase		;Cost
	dbbbb movx,Zeropg_imm8,r8,7				;Rep+SubGain
	dbbbb movx,Zeropg_imm8,r9,2				;Risk
	
						;3 - Give away Low risk, expensive
DoPromoApply:	
	dc.b ph4b
		dc.b ph6b
			dbb mov16x,r6_r2
			dbw bsrj,Cash_Spend-VramBase			;R6=AmountToSpend
		dc.b pl6b
		dbbw movx,r4_Addr16,valSkillz	;ToRange
		dbbbb movx,ZeroPg_imm8,5,$00	;FromRange
		advcall arangedrandom
	dc.b pl4b
	
	;dbw braj,NoDisasterPromo		;Force promo to succeed
	;dbw braj,NoNewsPromo			;Force promo to fail
	
	dbbb cmpx,r0_Zeropg,r9			;RandVal > risk
	dbw bccj,NoDisasterPromo-VramBase		;Yes, then ok
		
;Promo failed 
	dbb andi,1
	dbw beqj,NoNewsPromo-VramBase			;bit0 = 0 then Promo didn't get seen
		
	dbw bsrj,DoDisaster-VramBase				;bit0 = 1 then Promo caused disaster!
	dbw braj,MonthResume-VramBase
	
NoNewsPromo:	
	dbbw mov16x,r4_imm16,NoNewsHeadlinesListB-VramBase
	dbw bsrj,GetRandomStringR4x4-VramBase	;Get a subject string (4 options)
	dc.b ph4b
		dbbw mov16x,r4_imm16,NoNewsHeadlinesListA-VramBase
		dbw bsrj,GetRandomStringR4x4-VramBase	;Get a subject string (4 options)
		dbb mov16x,r6_r4
	dc.b pl4b
				
	dbw bsrj,ShowStrStr-VramBase		;R6 then R4
	dbw braj,MonthResume-VramBase
	
NoDisasterPromo:		;R4=RandomList R6=Title
	dc.b ph6b
		dc.b ph4b
			advcall aDoRandom		;Random Repgain AND R8
			dbbb andx,r0_ZeroPg,r8	
			dc.b ph0b
				dbb movx,r1_r0
				dbw bsrj,AddRep-VramBase		;Reputation gain
			dc.b pl0b
			
			dbb movx,r2_r0
			dbw bsrj,ViewersAddR2-VramBase	;Viewer gain
		dc.b pl4b
		
		dbw bsrj,GetRandomStringR4x4-VramBase	;Get a subject string (4 options)
		dbb mov16x,r2_r4

		dbbw mov16x,r6_imm16,NewsTitle-VramBase
	dc.b pl4b

	dbw bsrj,ShowStrNamStrStr-VramBase	;Show title with strings R6,Name,R4,R2
	dbw braj,MonthResume-VramBase
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoSponsor:
	dbbw mov16x,r6_imm16,Sponsors-VramBase	;Option List
	dbbb movx,r4_imm8,2				;Max option
	dbw bsrj,ShowSelectCursor-VramBase		;Show list and get response

	dbbw mov16x,r2_imm16,$0001		;Rep Damage / Payment Limit 
	dbbw mov16x,r4_imm16,GoodAdList-VramBase
	
	dc.b cmpi,0						;Legit sponsor?
	dbw beqj,DoSponsor_GetPaid-VramBase		
	
	dbbw mov16x,r2_imm16,$0303		;Rep Damage / Payment Limit 
	dbbw mov16x,r4_imm16,BadAdList-VramBase
	
DoSponsor_GetPaid:
	dc.b ph2b
		dbw bsrj,GetRandomStringR4x4-VramBase	;Get a subject string (4 options)
		dbb mov16x,r2_r4
	
		dbbw mov16x,r6_imm16,AdTitle-VramBase
		dbbw mov16x,r4_imm16,AdSponsor-VramBase
		;dbbw mov16x,r2_imm16,BadAd1
		dbw bsrj,ShowStrNamStrStr-VramBase		;Show title with strings R6,Name,R4,R2
	
	dc.b pl2b 
	
	advcall aDoRandom	
	dbb andx,r0_r2
	dbb movx,r1_r0
	dbw bsrj,SubRep-VramBase	;R0=R0-R1 (Limit to 255)
	
	advcall aDoRandom
	dbb andx,r0_r3
	dbb movx,r1_r0
	dbw bsrj,GetPaid-VramBase	;Get paid for ad (R1=Payment mult)

	dbw braj,MonthResume-VramBase
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
ShowSelectCursor:	;R4= max option
	dc.b ph4b
		dc.b ph6b
			advcall aCls
			dbbw mov16x,r6_imm16,StrSelect-VramBase	;Show select title 
			advcall aprintseq
			dbbw mov16x,r4_imm16,$0202
		dc.b pl6b
		advcall aprintseq					;Show select list 
		
		advcall aNewLine
		dbw bsrj,Cash_ShowStr-VramBase				;Show current cash
		
	dc.b pl4b
	dbbw mov16x,r6_imm16,$0000				;Cursor pos 
	dbbbb movx,ZeroPg_imm8,5,0				;Min val (R4=Max val)
	
SelectLoop:	
	dc.b ph4b
		dbb mov16x,r4_r6
		dbbw add16x,r4_imm16,$0002			;First line is 2
		dc.b ph4b
			dbb movi,'>'
			advcall aPrintChar 				;Show cursor 
			advcall aPause50
		dc.b pl4b
		dbb movi,' '
		advcall aPrintChar 					;Hide cursor 
		
		advcall aDoRandom					;Randomize Seed
		
		advcall areadjoystick				;Get Joystick directions
		dbb movx,r2_r0
	dc.b pl4b									;Min-Max Y range
	dc.b ph4b
		dbb movx,r0_r6
		advcall ajoyaxis					;Process Up/Down joy press
		advcall arangelimit					;Check we're still onscreen
		dbb movx,r6_r0						
	dc.b pl4b 
	
	dbbb tstx,r2_imm8,%00000100				;Fire?
	dbw bnej,SelectLoop-VramBase
		
	dc.b retb 
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
ShowStrStr:		;Show title with strings R6,R4
	dc.b ph4b
		dc.b ph6b
			advcall aCls
			dbw bsrj,ShowSpewTube-VramBase
			dbbw mov16x,r4_imm16,$000A
		dc.b pl6b
		dbw braj,ShowStrStrB-VramBase
		

ShowStrNamStrStr:	;Show title with strings R6,Name,R4,R2
	dc.b ph2b
		dc.b ph4b
			dc.b ph6b
				advcall aCls
				dbw bsrj,ShowSpewTube-VramBase
				dbbw mov16x,r4_imm16,$000A
			dc.b pl6b
			advcall aprintSeq

			dbbw mov16x,r6_imm16,valMyName	;Show our heroic player!
			advcall aprintSeq
			
			advcall aNewLine
		dc.b pl6b
		advcall aprintSeq
		
		dbw braj,ShowStrStrC-VramBase	
	
	
ShowStrNamStr:	;Show title with strings R6,Name,R4
	dc.b ph4b
		dc.b ph6b
			advcall aCls
			dbw bsrj,ShowSpewTube-VramBase
			dbbw mov16x,r4_imm16,$000A
		dc.b pl6b
		advcall aprintSeq
		advcall aNewLine
		
		dbbw mov16x,r6_imm16,valMyName	;Show our heroic player!
		
ShowStrStrB:		
		advcall aprintSeq
		advcall aNewLine
ShowStrStrC:	
	dc.b pl6b
	advcall aprintSeq
	
	advcall aWaitForFire
	dc.b retb
	
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowStreamers:		
	advcall aCls
	dbw bsrj,ShowSpewTube-VramBase		;Show title image 

	dbbw mov16x,r6_imm16,strTopStreamers-VramBase ;Streamer list of subs+name
	advcall aprintSeq			;Show top streamers title 
	
	advcall aNewLine
	
	dbbw mov16x,r6_imm16,StreamerRanking-VramBase
	dbbb movx,r1_imm8,10		;View count 
	
	dbbw mov16x,r2_addr16,valViewers	;Player Sub count in R2
	
ShowStreamersAgain:		
	dc.b ph0b
		dbb mov16x,r0_atr6		;Get fake streamer view count 
		
		dbb cmp16x,r2_r0		;Is our player above this one?
		dbw bccj,ShowUser-VramBase		;Yes? then show user 
ShowUserReturn:
		
		dc.b ph2b
			dbw jsrj,ShowViewers-VramBase	;Show streamer viewers 
			dbbw add16x,r6_imm16,2	;Skip view count bytes 
			
			dbb movi,' '
			advcall aprintchar		
				
			advcall aprintSeq		;Show streamer name 
			advcall aNewLine
		dc.b pl2b
	dc.b pl0b
	
	dc.b decz,r1
	dbw bnej,ShowStreamersAgain-VramBase
	
	advcall aWaitForFire
	
	dbbw mov16x,r0_addr16,valViewers	;Max Viewers?
	dbbw cmp16x,r0_imm16,$0763			;99 x 7 digits
	dbw bnej,NotWonGame-VramBase
	
	dbbw movx,r0_addr16,valReputation	;Max rep?
	dbb cmpi,255
	dbw beqj,ShowWonGame-VramBase
NotWonGame:	
	dc.b retb
	
	
ShowUser:		;Show user in the ranking list 
	dc.b ph6b
	dc.b ph0b
		dbb mov16x,r0_r2
		dbw jsrj,ShowViewers-VramBase 	;Show viewer count 
	
		dbb movi,' '
		advcall aprintchar				;Show zeros	
			
		dbbw mov16x,r6_imm16,valMyName	;Show our heroic player!
		advcall aprintSeq
		advcall aNewLine
	
		dbbw mov16x,r2_imm16,0	;Flag shown so it won't appear again
	dc.b pl0b
	dc.b pl6b
	dbw braj,ShowUserReturn-VramBase
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


Cash_ShowStr:		;Show cash title + value
	advcall aNewLine	
	dbbw mov16x,r6_imm16,strCash-VramBase	;Cash Title 
	advcall aprintSeq
	
;Cash_Show:			;Show cash value
	dbbw mov16x,r6_imm16,valCash	;Cash BCD
	dbb movi,4
	Mcall mBCDShow		;R6=BCD sequence R0=Bytes to show
	dc.b retb
	

GetPaid:	;Streamer Revenue R1=0-3 for Ad value 
	dbbw movx,r0_addr16,(valViewers+1) ;0-7 zerocount of subs
	dbb addx,r0_r1	
	dbbb movx,r1_imm8,0				;R1= offset for how much we're paid 
	dc.b aslb
	dc.b aslb							;4 bytes per BCD val
	
	dbbw add16x,r0_imm16,PaymentsBCD-VramBase
	
	dbb mov16x,r6_r0
	dbbw mov16x,r4_imm16,valCash	;Add chosen value to current cash
	dbb movi,4						;4 BCD bytes 
	Mcall mBCDAdd
	dc.b retb
	
	
Cash_Spend:			;R6=AmountToSpend
	dbb movi,4
	dbbw mov16x,r4_imm16,valCash
	Mcall mBCDSub

	dbw bcsj,ShowLostGame-VramBase		;Cash<0 = Game over 
	dc.b retb
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MaybeDisaster:		;R4=ToRange (eg 8)
	dbbb cmpx,r4_imm8,0
	dbw bnej,MaybeDisasterR4_OK-VramBase
	dbbb movx,r4_imm8,1				;Infloop if R4=0 as well as R5
MaybeDisasterR4_OK:	

	dbbw movx,ZeroPg_imm8,5,$00		;FromRange
	advcall arangedrandom
	
	dbb cmpi,0						;0=Disaster occurred 
	dbw bnej,NoDisaster-VramBase
	
DoDisaster:
	dbbb movx,r1_imm8,7				;8 possible disasters 
	dbbw mov16x,r4_imm16,RandomDisasterList-VramBase
	dbw bsrj,GetRandomStringR4-VramBase
	
	dbbw mov16x,r6_imm16,RandomDisasterTitle-VramBase
	dbw bsrj,ShowStrNamStr-VramBase			;Show the disaster
	
	advcall aDoRandom
	dbb andi,%00000011				;4 possible outcome scales
	
	dbbw mov16x,r2_imm16,$03FF		;-Rep/+Subs
	dbw beqj,DisasterChosen-VramBase
	
	dbbw mov16x,r2_imm16,$06FC		;-Rep/+Subs
	dc.b decb 
	dbw beqj,DisasterChosen-VramBase
	
	dbbw mov16x,r2_imm16,$0AF6		;-Rep/+Subs
	dc.b decb
	dbw beqj,DisasterChosen-VramBase
	
	;Notorious - subs up, rep big drop
	dbbw mov16x,r2_imm16,$200A		;-Rep/+Subs
	
DisasterChosen:	
	dbb movx,r1_r3
	dbw bsrj,SubRep-VramBase					;Drop reputation
		
	dbw bsrj,ViewersAddR2-VramBase			;Alter viewers 
	
NoDisaster:
	dc.b retb
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetRandomStringR4x4:		;R4=Lookup table of string pointers
	dbbb movx,r1_imm8,3		;Get a subject string (4 options)
	
GetRandomStringR4:			;R1= AND mask
	advcall aDoRandom
	dbb andx,r0_r1			;Limit range of random with R1
	dc.b aslb					;2 bytes per address 
	dbbb movx,r1_imm8,0
	dbb add16x,r4_r0
	dbb mov16x,r4_atr4		;Get string address from LUT
	dc.b retb

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DrawGraph:
	advcall aCls

;Draw Graphs 
	dbbw mov16x,r6_imm16,valGraph		;Source data
	dbbb movx,r2_imm8,MPB_Pen1			;Purple line 
	dbw bsrj,DrawGraphLine-VramBase
	
	dbbw mov16x,r6_imm16,valGraph+1		;Source data
	dbbb movx,r2_imm8,MPB_Pen2			;Cyan line 
	dbw bsrj,DrawGraphLine-VramBase
		
;Draw Axis - Vertical line
	dbb SYSi,syscallLoadMultiReg	
	dc.b %10111100
	dw MPB_Pen3	;Color
	dw 0	;X
	dw 0	;Y
	dw 0	;X
	dw 128	;Y
	MBcall mbDrawLine 	;6 (x0,y0, x1,y1) ;Src R4,R6 Dest R8,R10 R0=Color

;Horizontal line 
	dbb SYSi,syscallLoadMultiReg	
	dc.b %10111100
	dw MPB_Pen3	;Color
	dw 0	;X
	dw 128	;Y
	dw 15*8	;X
	dw 128	;Y
	MBcall mbDrawLine 	;6 (x0,y0, x1,y1) ;Src R4,R6 Dest R8,R10 R0=Color

	
	dbbw mov16x,r4_imm16,$0011			;Cursor pos 
	
	dbbw mov16x,r6_imm16,strViewers-VramBase
	advcall aprintSeq					;Viewer string 
		
	dbbw mov16x,r0_addr16,valViewers
	dbw jsrj,ShowViewers-VramBase	;Viewer count 

	advcall aNewLine

	dbbw mov16x,r6_imm16,strRep-VramBase			;Rep title 
	advcall aprintSeq

;Show reputation as a string 
	dbbw movx,r0_addr16,valReputation	;Rep title 
	ifd CheatMode
		dc.b ph0b
		advcall aShowDecimal			;Show Rep as a decimal
		dbb movi,' '
		advcall aPrintChar
		dc.b pl0b
	endif 
		
	dc.b lsrb								;Top 3 bits of reputation
	dc.b lsrb
	dc.b lsrb
	dc.b lsrb
	dbb andi,%00001110					;Pointer to rep name 
	dbbb movx,r1_imm8,0
	
	dbbw mov16x,r6_imm16,RepMatrix-VramBase
		
	dbb add16x,r6_r0
	dbb mov16x,r6_atr6					;Get rep string 
	advcall aprintSeq					;Show rep name 
	
	dbw bsrj,Cash_ShowStr-VramBase

;Skill should be hidden from user,
;it's only shown here for debugging/cheating!
	ifd CheatMode
		advcall aNewLine

		dbbw mov16x,r6_imm16,strSkill-VramBase
		advcall aprintSeq				;Skill title 
		
		dbbw movx,r0_Addr16,valSkillz
		advcall aShowDecimal			;Skill value 
	endif 
	
		
	advcall aWaitForFire
	dc.b retb
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
DrawGraphLine:
	dbbbw mov16x,ZeroPg_imm16,r8,0			;LastXpos
	dbbbw mov16x,ZeroPg_imm16,r10,0			;LastYpos

	dbbw mov16x,r4_imm16,0		;Xpos =0
	
	dc.b movx,r1_imm8,16
DrawGraphAgain:	
	dc.b ph6b
		dc.b movi,255				;Flip Ypos 
		dc.b subx,r0_atR6
		dc.b lsrb					;/2
		dc.b stoz,6				;Set Ypos
		dc.b movx,ZeroPg_imm8,7,0	
		
		dc.b movx,r0_r2		;Set color R0=Color
		MBcall mbDrawLine 	;(x0,y0, x1,y1) Src R4,R6 Dest R8,R10 
		
		dbbb mov16x,ZeroPg_r4,r8	;New Last Xpos
		dbbb mov16x,ZeroPg_r6,r10	;New Last Ypos
	dc.b pl6b
	
	dbbw add16x,r4_imm16,8		;Xpos Across 8
	dbbw add16x,r6_imm16,2		;Next source bytes R6+=2
	
	dc.b decz,r1
	dbw bnej,DrawGraphAgain-VramBase		;Next line 

	dc.b retb
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
UpdateGraph:
	dc.b ph0b
		dbbw mov16x,r6_imm16,valGraph	;Dest
		dbbw mov16x,r2_imm16,(valGraph+2)	;Src
		dbbb movx,r1_imm8,15			;Entry count -1
	
UpdateGraph_Loop:	
		dbb mov16x,AtR6Inc_AtR2Inc		;Copy n+2 to n (move values left)
		dbb incz,r2						;Repeat 
		dbb incz,r6
		
		dbb decz,r1
		dbw bnej,UpdateGraph_Loop-VramBase
	dc.b pl0b
	
	dbb mov16x,AtR6Inc_r0				;Add new entry to list (2 bytes)
	dc.b retb	
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Viwerers is in a fake floating point format
;First byte is top value 0-255 - but we aim to keep it between 10 and 99
;2nd byte is zero count.
;We shift First byte to keep it between 10 and 99, adding and removing zeros from the second 

;It's absurdly crude, but enough for our silly game

ViewersAddR2R3:	;Add/sub R2(-10 to +10 max) * R3
	dbbw mov16x,r0_addr16,valViewers ;R0=topdigits R1=zeros
ViewersAddR2_Again:	
		dc.b ph2b
			dbw bsrj,ViewersAddR2b-VramBase
		dc.b pl2b
		dbb decz,3
		dbw bnej,ViewersAddR2_Again-VramBase
	dbbw mov16x,addr16_r0,valViewers ;R0=topdigits R1=zeros
	dc.b retb

	
ViewersAddR2:	;Add/sub R2(-10 to +10 max) 
	dbbw mov16x,r0_addr16,valViewers ;R0=topdigits R1=zeros
	dbw bsrj,ViewersAddR2b-VramBase
	dbbw mov16x,addr16_r0,valViewers ;R0=topdigits R1=zeros
	dc.b retb

	
ViewersAddR2b:		;R0.R1 viewers +=R2
	dc.b addx,r0_r2
	dc.b cmpi,100				;Top byte too high?
	dbw bccj,ViewersDiv10-VramBase
	dc.b cmpi,10				;Top byte too low?
	dbw bcsj,ViewersMul10-VramBase
	dc.b retb	

	
ViewersDiv10:	;Viwers >100 so /10
	dbb movx,r2_r1
		dbbb movx,r1_imm8,10
		Mcall mDivByte8		
	dbb movx,r1_r2
	dbb incz,r1
	
	dbbb cmpx,r1_imm8,8			;Digits>7?
	dbw bnej,ViewersDiv7OK-VramBase		;<digits 0 ?
	dbbb movx,r1_imm8,7
	dbbb movx,r0_imm8,99
ViewersDiv7OK:

	dc.b retb	
	
	
ViewersMul10:	;Viwers <10 so *10
	dbb movx,r2_r1
		dbbb movx,r1_imm8,10	
		Mcall mMulByte8		
	dbb movx,r1_r2
	dbb decz,r1
	dbb cmpi,0						;Byte=0?
	dbw bnej,ViewersMul10OK-VramBase			;number =0 ?
	dbb movi,90						;Don't let digits hit zero
	
ViewersMul10OK:
	dbbb cmpx,r1_imm8,255			;digits <0 ?
	dbw bnej,ViewersMul10OKb-VramBase	
	dbbb movx,r1_imm8,0
	dbbb movx,r0_imm8,10			;Reset Zeros to 0
ViewersMul10OKb:

	dc.b retb	
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
ShowViewers:
	dc.b ph0b
		dc.b movx,r2_imm8,7				;Preceeding spaces
		dc.b subx,r2_r1
SpaceAgain:	
		dbbb cmpx,r2_imm8,0
		dbw beqj,NoSpace-VramBase

		dbb movi,' '
		advcall aprintchar				;Show zeros
	
		dbb decz,r2						;R2= Space count 
		dbw braj,SpaceAgain-VramBase
NoSpace:		
	
	dc.b pl0b
	dc.b ph0b
		advcall ashowdecimal			;Show top digits
	
ZeroAgain:	
		dbbb cmpx,r1_imm8,0
		dbw beqj,Nozero-VramBase
	
		dbb movi,'0'
		advcall aprintchar				;Show zeros
	
		dbb decz,r1						;R1= Zero count 
		dbw braj,ZeroAgain-VramBase	
Nozero:	
	dc.b pl0b
	dc.b retb
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
GetByteViewers:		;Convert 2 byte 'subs' to 1 byte for graph

	dbbw mov16x,r0_addr16,valViewers	;Bottom nibble=digit
	dc.b lsrb	;100/2 = 50
	dc.b lsrb	;100/2 = 25
	
	dbb lslz,r1 ;0-7					;Top nibble=zeros
	dbb lslz,r1
	dbb lslz,r1
	dbb lslz,r1
	dbb lslz,r1 ;%11110000
	
	dbb addz,r1
	dc.b retb
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddRep:	;R0=R0+R1 (Limit to 255)
	dbbw movx,r0_addr16,valReputation
	dbw jsrj,Limit_Add8-VramBase
	dbbw movx,addr16_r0,valReputation
	dc.b retb
	
SubRep:	;R0=R0-R1 (Limit to 255)
	dbbw movx,r0_addr16,valReputation
	dbw jsrj,Limit_Sub8-VramBase
	dbbw movx,addr16_r0,valReputation
	dc.b retb
	
AddSkill:	;R0=R0+R1 (Limit to 255)
	dbbw movx,r0_addr16,valSkillz
	dbw jsrj,Limit_Add8-VramBase
	dbbw movx,addr16_r0,valSkillz
	dc.b retb
	
SubSkill:	;R0=R0-R1 (Limit to 255)
	dbbw movx,r0_addr16,valSkillz
	dbw jsrj,Limit_Sub8-VramBase
	dbbw movx,addr16_r0,valSkillz
	dc.b retb

Limit_Add8:	;R0=R0+R1 (Limit to 255)
	dbb addx,r0_r1
	dbw bccj,Limit_Add8Ok-VramBase
	dbb movi,255
Limit_Add8Ok:
	dc.b retb 
	
Limit_Sub8:	;R0=R0-R1 (Limit to 0)
	dbb subx,r0_r1
	dbw bccj,Limit_Sub8Ok-VramBase
	dc.b clrb ;dbb movi,0
Limit_Sub8Ok:
	dc.b retb 
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowSpewTube:				;Spew tube Header
	ifnd IMG_NoHeader
		dbb SYSi,syscallLoadMultiReg	;This will be better for setting 3+ regs
		dc.b %01111111
		dw $2009		;Wid/Hei
		dw $0000		;Xpos/Ypos
			
		ifd Use16ColorGraphics
			dc.b 4			;Bitplanes L
		endif
		ifd Use4ColorGraphics
			dc.b 2			;Bitplanes L
		endif 
		ifd Use2ColorGraphics
			dc.b 1			;Bitplanes L
		endif 
		
		ifd UseHalfHeight
			dc.b 2			;Stretch H
		else
			dc.b 1			;Stretch H
		endif 
		
		dwwww SpewTubeScreen1-VramBase,SpewTubeScreen2-VramBase,SpewTubeScreen3-VramBase,SpewTubeScreen4-VramBase
		RLECall rleDrawScreen
	endif
	dc.b retb
	

ShowTitle:					;Game Title screen
	dbw mov16i,$1000		;16 from color 0
	dbbw mov16x,r6_imm16,GamePalette-VramBase
	MBcall mbSetPaletteMP
	
	ifnd IMG_NoTitle
		dbb SYSi,syscallLoadMultiReg		;This will be better for setting 3+ regs
		dc.b %01111111
		dw $2018		;Wid/Hei
		dw $0000		;Xpos/Ypos
			
		ifd Use16ColorGraphics
			dc.b 4			;Bitplanes L
		endif
		ifd Use4ColorGraphics
			dc.b 2			;Bitplanes L
		endif 
		ifd Use2ColorGraphics
			dc.b 1			;Bitplanes L
		endif 
		
		ifd UseHalfHeight
			dc.b 2			;Stretch H
		else
			dc.b 1			;Stretch H
		endif 
		dwwww TitleScreen1-VramBase,TitleScreen2-VramBase,TitleScreen3-VramBase,TitleScreen4-VramBase
		RLECall rleDrawScreen
	endif 
	dc.b retb
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


NoNewsHeadlinesListB:	;Pointers to headlines for failed promos (Titles)
	dw NoNewsHeadlinesB1-VramBase
	dw NoNewsHeadlinesB2-VramBase
	dw NoNewsHeadlinesB3-VramBase
	dw NoNewsHeadlinesB4-VramBase
	
NoNewsHeadlinesListA:	;Pointers to headlines for failed promos (Bodys)
	dw NoNewsHeadlines1-VramBase
	dw NoNewsHeadlines2-VramBase
	dw NoNewsHeadlines3-VramBase
	dw NoNewsHeadlines4-VramBase

RepMatrix:
	dw StrRep_0-VramBase			;List of reputation names 
	dw StrRep_1-VramBase
	dw StrRep_2-VramBase
	dw StrRep_3-VramBase
	dw StrRep_4-VramBase
	dw StrRep_5-VramBase
	dw StrRep_6-VramBase
	dw StrRep_7-VramBase
		
CollabList:
	dw Collab1-VramBase			;Collab names
	dw Collab2-VramBase
	dw Collab3-VramBase
	dw Collab4-VramBase
	
CharityList:
	dw Charity1-VramBase			;Charity names
	dw Charity2-VramBase
	dw Charity3-VramBase
	dw Charity4-VramBase	
		
GiveAwayList:
	dw GiveAway1-VramBase		;Giveaway names
	dw GiveAway2-VramBase
	dw GiveAway3-VramBase
	dw GiveAway4-VramBase

StuntList:
	dw Stunt1-VramBase			;Stunt names 
	dw Stunt2-VramBase
	dw Stunt3-VramBase
	dw Stunt4-VramBase
	
RandomDisasterList:		;Stuff that can go wrong (if Skill is too low)
	dw RandomDisaster1-VramBase
	dw RandomDisaster2-VramBase
	dw RandomDisaster3-VramBase
	dw RandomDisaster4-VramBase
	dw RandomDisaster5-VramBase
	dw RandomDisaster6-VramBase
	dw RandomDisaster7-VramBase
	dw RandomDisaster8-VramBase
	
GoodAdList:
	dw GoodAd1-VramBase			;Reputable advertisers
	dw GoodAd2-VramBase
	dw GoodAd3-VramBase
	dw GoodAd4-VramBase

BadAdList:	
	dw BadAd1-VramBase			;Dodgy advertisers
	dw BadAd2-VramBase
	dw BadAd3-VramBase
	dw BadAd4-VramBase
	
	
;BCD values used for payments 
Payments0:	
	dc.b $00,$00,$00,$00		;0
PaymentsBCD: ;0-7 for fame levels, Plus 0-3 for Ad Value 
	dc.b $30,$00,$00,$00		;0
	dc.b $60,$00,$00,$00		;1
Payments100:
	dc.b $00,$01,$00,$00		;2
	dc.b $00,$04,$00,$00		;3
	dc.b $00,$07,$00,$00		;4
Payments1K:
	dc.b $00,$10,$00,$00		;5
	dc.b $00,$40,$00,$00		;6
	dc.b $00,$70,$00,$00		;7
Payments10K:
	dc.b $00,$00,$01,$00		;A
Payments40K:
	dc.b $00,$00,$04,$00		;B
	dc.b $00,$00,$07,$00		;C
Payments100K:
	dc.b $00,$00,$10,$00		;D
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	ifd I_Am_Very_Rude
		include "GameVM_ETSMBW_Jokes.asm"	;Ruder versions of jokes/names (may not be suitable for my YT Vids)
	else 
	
strCash: dc.b 'Cash:',255	
strViewers: dc.b 'Subs:',255
strRep: dc.b ' Rep:',255
strSkill: dc.b 'Skil:',255	
strDefaultName: dc.b 'Chibiakumas!',255
strEnterName: dc.b 'Enter your name:',255
StrSelect: dc.b 'Select an option:',255

;Reps (selected based on top 3 bits of rep byte)

StrRep_7: dc.b 'Internet god',255
StrRep_6: dc.b 'Podcaster',255
StrRep_5: dc.b 'Tech Influencer',255
StrRep_4: dc.b 'Social commentard',255
StrRep_3: dc.b 'MostlyPointless',255
StrRep_2: dc.b 'WatchAlong V-tuber',255
StrRep_1: dc.b 'E-thot',255
StrRep_0: dc.b 'Lolcow',255

strTopStreamers: dc.b 'This Months trending streamers:',253,255

;Streamers, first two bytes are viewer count

StreamerRanking:
	dc.b 88,7,'Poo da pie',255
	dc.b 90,6,'MrYeast',255
	dc.b 77,5,'SpazMongCold',255
	dc.b 63,5,'Winja',255
	dc.b 88,4,'Smell Dolphine',255
	dc.b 70,4,'Spamoanth',255
	dc.b 68,3,'Bent Sharpeno',255
	dc.b 34,2,'LowBum Paul',255
	dc.b 14,1,'Dork side phil',255
	dc.b 12,0,'BooGut',255
	
Actions:
	dc.b 'Sleep',254				;Null
	dc.b 'Stream Live!',254			;High risk, high reward, Money
	dc.b 'Pre-Recorded vid',254		;Low risk, Low reward, Almost No money
	dc.b 'Find a sponsor',254		;Big Money, Risk losing rep
	dc.b 'Do Promotion',254			
	dc.b 'Investment',255
		
Promotions:
	dc.b 'Do Stunt $100',254					;High risk, High reward cheap
	dc.b 'Do Collab $100',254				;Moderate risk, Moderate reward, cheap
	dc.b 'Do Charity event $1K',254			;Low risk, Low reward
	dc.b 'Do Give away $10K',255				;Low risk, expensive

Investments:
	dc.b 'Do some research $100',254		;very cheap,Low gain,
	dc.b 'Pay for Ads $1K',254			;Cheap, low gain
	dc.b 'Buy new GPU $10K',254		;Moderate , moderate gain
	dc.b 'Pay for views $10K',254		;High gain, High risk of failure (Damages rep)
	dc.b 'Hire staff $40K',254				;very Expensive, High gain
	dc.b 'Hire Crisis management $100K',255 ;very Expensive, Doubles rep up to 96

Sponsors:
		dc.b 'Legit Sponsor',254
		dc.b 'Iffy Sponsor',255
			
NoNewsHeadlines1:	dc.b 'ZOMGWTF!!!111',255
NoNewsHeadlines2:	dc.b 'Reacting to reacters reactions:',255
NoNewsHeadlines3:	dc.b 'cooked crashout of the day:',255
NoNewsHeadlines4:	dc.b 'Watch this now, or you may die:',255

NoNewsHeadlinesB1:	dc.b 'MunterMatt outed as hamster',255
NoNewsHeadlinesB2:	dc.b 'Vestiny dates a horse',255
NoNewsHeadlinesB3:	dc.b 'The young twirps approve of',253,'cannabalism',255
NoNewsHeadlinesB4:	dc.b 'YFPS reviews your furry pr0n',255

	
GoodNewsCollab:	dc.b 'Does Collab with ',253,255
	
Collab1: dc.b 'Assix Jones: Inbred wars',255
Collab2: dc.b 'Candiss Jewens',255
Collab3: dc.b 'Sock on head',255
Collab4: dc.b 'handstand pikestick',255

	
GoodNewsCharity: dc.b 'Does Charity event with ',255
			
Charity1: dc.b 'GPUs for gophers',255
Charity2: dc.b 'Make asparagus great again',255
Charity3: dc.b 'Legalize genocide',255
Charity4: dc.b 'twitchaholics anonymous',255


GoodNewsGiveaway: dc.b 'Does give away of ',255

GiveAway1: dc.b 'Used socks',255
GiveAway2: dc.b 'Weapons grade plutonium',255
GiveAway3: dc.b 'Your mom',255
GiveAway4: dc.b 'All the cheese wizz you can eat',255	
	
GoodNewsStunt: dc.b 'Does Amazing Stunt:',255
	
Stunt1: dc.b 'Survives',253,'Shooting self with a vulcan',253
		dc.b 'cannon using a wet tissue as body',253,'armour',255
Stunt2: dc.b 'Goes without',253,'sleep, food or brain for 31 days',255
Stunt3: dc.b 'Sells their',253,'used socks on lonlyFans for $1',255
Stunt4: dc.b 'shockingly',253,'admits to not being an',253,'extradimentional entity',255


RandomDisasterTitle dc.b 'Shocking truth reveladed:',255

RandomDisaster1: dc.b 'Is outed as a pansexual ',253,'furry with webbed feet, who',253,'watches smellytubbies!',255
RandomDisaster2: dc.b 'DSP Disaster: Left camera on',253,' while performing a foot massage',255
RandomDisaster3: dc.b 'Is cancelled on Twatter for refusing',253,'to condemn the lockness',253,'monster for not existing',255
RandomDisaster4: dc.b 'is really a giraffe in a person suit?',253,'probably not, but we',253,'still hate them now!',255
RandomDisaster5: dc.b 'links to person who once said',253,'something mean are revealed',255
RandomDisaster6: dc.b 'Unbelievable made up truth about',253,'this streamer is outed as',253,'100% factual lie',255
RandomDisaster7: dc.b 'Once Played Smogwarts Lepracy.',254,'crowd angered at unethical',254,'streamer vow to murder them',255
RandomDisaster8: dc.b 'Fails to change Twatter logo',254,'fast enough in solidarity for',254,'trending cause of the minute',255

NewsTitle: dc.b 'Site News:',254,255

CaughtPaying: dc.b 'Is caught paying for views, What a loser!',255
WonGame: dc.b 'Is declared god of the interwebs',254,'Congraturations, your winner!',255
LostGame: dc.b 'Goes Bankrupt! will surely die',254,'in the gutter,so Lets laugh at',254,'their misfortune!',255


AdTitle: dc.b 'Now Watching:',255
AdSponsor: dc.b 'Sponsored by:',254,255
	
GoodAd1: dc.b 'DeafUMax Earphones',255
GoodAd2: dc.b 'UBPoor Credit rating services',255
GoodAd3: dc.b 'Epeen Gaming machines',255
GoodAd4: dc.b 'Spammerly Email software',255

BadAd1: dc.b 'BumScape shaving products',255
BadAd2: dc.b 'PeniMax male enhancements',255
BadAd3: dc.b 'Sh1tCoin Crypto',255
BadAd4: dc.b 'Scamugood suppliments',255

	endif 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

	
	
	
	

	ifnd IMG_NoTitle
	ifd UseHalfHeight			;HalfHeight 256x96
		ifd Use16ColorGraphics
TitleScreen1:
			incbin "\ResALL\Reikou\ETSMBW\Title16Col_Half.RAW.RLE1"
TitleScreen2:
			incbin "\ResALL\Reikou\ETSMBW\Title16Col_Half.RAW.RLE2"
TitleScreen3:
			incbin "\ResALL\Reikou\ETSMBW\Title16Col_Half.RAW.RLE3"
TitleScreen4:
			incbin "\ResALL\Reikou\ETSMBW\Title16Col_Half.RAW.RLE4"
		endif 
		ifd Use4ColorGraphics
TitleScreen1:
			incbin "\ResALL\Reikou\ETSMBW\Title4Col_Half.RAW.RLE1"
TitleScreen2:
TitleScreen3:
TitleScreen4:
			incbin "\ResALL\Reikou\ETSMBW\Title4Col_Half.RAW.RLE2"
		endif 
		ifd Use2ColorGraphics
TitleScreen1:
TitleScreen2:
TitleScreen3:
TitleScreen4: 
			incbin "\ResALL\Reikou\ETSMBW\Title2Col_Half.RAW.RLE"
		endif 
	else						;FullHeight 256x192
		ifd Use16ColorGraphics
TitleScreen1:
			incbin "\ResALL\Reikou\ETSMBW\Title16Col.RAW.RLE1"
TitleScreen2:
			incbin "\ResALL\Reikou\ETSMBW\Title16Col.RAW.RLE2"
TitleScreen3:
			incbin "\ResALL\Reikou\ETSMBW\Title16Col.RAW.RLE3"
TitleScreen4:
			incbin "\ResALL\Reikou\ETSMBW\Title16Col.RAW.RLE4"
		endif 
		ifd Use4ColorGraphics
TitleScreen1:
			incbin "\ResALL\Reikou\ETSMBW\Title4Col.RAW.RLE1"
TitleScreen2:
TitleScreen3:
TitleScreen4:
			incbin "\ResALL\Reikou\ETSMBW\Title4Col.RAW.RLE2"
		endif 
		ifd Use2ColorGraphics
TitleScreen1:
TitleScreen2:
TitleScreen3:
TitleScreen4:
			incbin "\ResALL\Reikou\ETSMBW\Title2Col.RAW.RLE"
		endif 
	endif	
	endif 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
	ifnd IMG_NoHeader
	ifd UseHalfHeight			;HalfHeight 256x96
		ifd Use16ColorGraphics
SpewTubeScreen1:
			incbin "\ResALL\Reikou\ETSMBW\SpewTube16Col_Half.RAW.RLE1"
SpewTubeScreen2:
			incbin "\ResALL\Reikou\ETSMBW\SpewTube16Col_Half.RAW.RLE2"
SpewTubeScreen3:
			incbin "\ResALL\Reikou\ETSMBW\SpewTube16Col_Half.RAW.RLE3"
SpewTubeScreen4:
			incbin "\ResALL\Reikou\ETSMBW\SpewTube16Col_Half.RAW.RLE4"
		endif 
		ifd Use4ColorGraphics
SpewTubeScreen1:
			incbin "\ResALL\Reikou\ETSMBW\SpewTube4Col_Half.RAW.RLE1"
SpewTubeScreen2:
SpewTubeScreen3:
SpewTubeScreen4:
			incbin "\ResALL\Reikou\ETSMBW\SpewTube4Col_Half.RAW.RLE2"
		endif 
		ifd Use2ColorGraphics
SpewTubeScreen1:
SpewTubeScreen2:
SpewTubeScreen3:
SpewTubeScreen4: 
			incbin "\ResALL\Reikou\ETSMBW\SpewTube2Col_Half.RAW.RLE"
		endif 
	else					;FullHeight 256x192
		ifd Use16ColorGraphics
SpewTubeScreen1:
			incbin "\ResALL\Reikou\ETSMBW\SpewTube16Col.RAW.RLE1"
SpewTubeScreen2:
			incbin "\ResALL\Reikou\ETSMBW\SpewTube16Col.RAW.RLE2"
SpewTubeScreen3:
			incbin "\ResALL\Reikou\ETSMBW\SpewTube16Col.RAW.RLE3"
SpewTubeScreen4:
			incbin "\ResALL\Reikou\ETSMBW\SpewTube16Col.RAW.RLE4"
		endif 
		ifd Use4ColorGraphics
SpewTubeScreen1:
			incbin "\ResALL\Reikou\ETSMBW\SpewTube4Col.RAW.RLE1"
SpewTubeScreen2:
SpewTubeScreen3:
SpewTubeScreen4:
			incbin "\ResALL\Reikou\ETSMBW\SpewTube4Col.RAW.RLE2"
		endif 
		ifd Use2ColorGraphics
SpewTubeScreen1:
SpewTubeScreen2:
SpewTubeScreen3:
SpewTubeScreen4:
			incbin "\ResALL\Reikou\ETSMBW\SpewTube2Col.RAW.RLE"
		endif 
	endif	
	endif 
	
	
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
	

	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
	
	
	even
	
	include "SrcALL/ChibiVm_CPU.asm"		
	
	
	even
	include "core.asm"
	include "footer.asm"
	
	
	;Variables for our Emulator

