
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	


;DMACON  EQU $dff096 ;DMA control write (clear or set)
;DMACONR  EQU $dff002 

;INTENA  EQU $dff09a ;Interrupt enable bits (clear or set bits)
;BPLCON0 EQU $dff100 ;Bitplane control register (misc. control bits)
;BPLCON1 EQU $dff102 ;Bitplane control reg. (scroll value PF1, PF2)
;BPL1MOD EQU $dff108 ;Bitplane modulo (odd planes)
;BPL2MOD EQU $dff10a ;Bitplane modulo (even planes)
;DIWSTRT EQU $dff08e ;Display window start (upper left vert-horiz position)
;DIWSTOP EQU $dff090 ;Display window stop (lower right vert.-horiz. Position)
;DDFSTRT EQU $dff092 ;Display bitplane data fetch start (horiz. Position)
;DDFSTOP EQU $dff094 ;Display bitplane data fetch stop (horiz. position)
;COP1LCH EQU $dff080	;Coprocessor first location register (high 3 bits, high 5 bits if ECS)
;--Bz--P-- --------

;Blitter hardware
	
;BLTCON0 equ $DFF040	;Blitter control register 0 
;BLTCON1 equ $DFF042	;Blitter control register 1

;BLTAFWM equ $DFF044	;First Word Mask for A
;BLTALWM equ $DFF046	;Last Word Mask for A

;BLTCPTH equ $DFF048 ;Address C H
;BLTCPTL equ $DFF04A ;Address C L

;BLTBPTH equ $DFF04C ;Address B H
;BLTBPTL equ $DFF04E ;Address B L

;BLTAPTH equ $DFF050 ;Address A H
;BLTAPTL equ $DFF052 ;Address A L

;BLTDPTH equ $DFF054 ;Address D H
;BLTDPTL equ $DFF056 ;Address D L

;BLTSIZE equ $DFF058 ;Size of area + START!

;BLTCMOD equ $DFF060 ;Modulo C
;BLTBMOD equ $DFF062 ;Modulo B
;BLTAMOD equ $DFF064 ;Modulo A
;BLTDMOD equ $DFF066 ;Modulo D
	
	
	section text		;'Text' means code!
FileZero:	
	
;Set up our screen
	
	move.l #gfxname,a1 	;'graphics.library' defined in chip ram
	clr.l d0
	move.l $000004,a6
	jsr	(-552,a6)		;Exec - Openlibrary
	
	move.l d0,gfxbase
	move.l d0,a6
	move.l #0,a1		;Null view
	jsr (-222,a6)		;LoadView - Use a coprocessor list for display
			
;Start defining our screen layout
	
; 			  RPPPHDCG----PIE-	 		;four bitPlanes (16 color) Color on
	move.w	#%0100001000000000,$dff100	;BPLCON0 -Bitplane control register
	
	clr.w $dff102			;BPLCON1 - Hscroll 0 
	
;4 bitpanes 40 bytes each, so skip 3 bitplanes (3*40=120) after each line
	move.w	#120,$dff108	;BPL1MOD - Bitplane modulo (odd planes)
	move.w	#120,$dff10a	;BPL2MOD - Bitplane modulo (even planes)
	
	
	move.w	#$2c81,$dff08e	;DIWSTRT - Display window start (TopLeft)
	move.w	#$F4C1,$dff090	;DIWSTOP - Display window stop (Bottom Right)
	move.w	#$0038,$dff092	;DDFSTRT - Disp bitplane data fetch Horiz-start 
	move.w	#$00d0,$dff094	;DDFSTOP - Disp bitplane data fetch Horiz-stop 
		  	;-------DbCBSDAAAA
	move.w  #%1000000110000000,$dff096	;DMACON - DMA set ON  - DMA control (and blitter status) read 
										;	(Bit 15 defines set/clear for other bits)
			;-------DbCBSDAAAA
	move.w 	#%0000000001011111,$dff096 ;DMACON - DMA set OFF - turn off sound
	move.w 	#%1100000000000000,$dff09a ;INTENA IRQ set ON  - Interrupt enable bits read - Turn on master
	move.w 	#%0011111111111111,$dff09a ;INTENA IRQ set OFF - Turn off all others
	
	
	
;Entry format:
;Change setting:
; %0000000n nnnnnnn0 DDDDDDDD DDDDDDDD	nnn= address to Change ($DFFnnn) DDDD=new value to set address
   
;wait for pos:
; $VVVVVVVV HHHHHHH1 1vvvvvvv hhhhhhh0   V=Vops H=Hpos v= Vpos Compare enable  h=hpos compare enable

;Define Memory layout: 4 bitplanes on concecutive lines
   
	lea CopperList,a6	;Copperlist (Commands run by Copper Coprocessor) 
						; all specified addresses start DFFnnn
						
	move.l #Screen_Mem+(40*0),d0	;Bitplane 0
	move.w #$00e2,(a6)+			;Bitplane 0 pointer (low 15 bits)
	move.w d0,(a6)+		
	swap d0
	move.w #$00e0,(a6)+			;Bitplane 0 pointer (high 3 bits)
	move.w d0,(a6)+		
	
	move.l #Screen_Mem+(40*1),d0	;Bitplane 1
	move.w #$00e6,(a6)+			;Bitplane 1 pointer (low 15 bits)
	move.w d0,(a6)+		
	swap d0
	move.w #$00e4,(a6)+			;Bitplane 1 pointer (high 3 bits)
	move.w d0,(a6)+		

	move.l #Screen_Mem+(40*2),d0	;Bitplane 2
	move.w #$00ea,(a6)+			;Bitplane 2 pointer (low 15 bits)
	move.w d0,(a6)+		
	swap d0
	move.w #$00e8,(a6)+			;Bitplane 2 pointer (low 15 bits)
	move.w d0,(a6)+		
	
	move.l #Screen_Mem+(40*3),d0	;Bitplane 3
	move.w #$00eE,(a6)+			;Bitplane 3 pointer (low 15 bits)
	move.w d0,(a6)+		
	swap d0
	move.w #$00eC,(a6)+			;Bitplane 3 pointer (high 3 bits)
	move.w d0,(a6)+		

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	lea PalettePointer,a1	;Load the address of the palette data in
	move.l a6,(a1)			;the copperlist into our pointer for easy changing
	
	       ; AAAA-RGB		;Address - RGB
    move.l #$01800000,(a6)+ ;0  -RGB
    move.l #$0182080F,(a6)+ ;1  -RGB
    move.l #$018400FF,(a6)+ ;2  -RGB
    move.l #$01860FFF,(a6)+ ;3  -RGB
    move.l #$01880008,(a6)+ ;4  -RGB
    move.l #$018A0808,(a6)+ ;5  -RGB
    move.l #$018C0088,(a6)+ ;6  -RGB
    move.l #$018E0CCC,(a6)+ ;7  -RGB
    move.l #$01900888,(a6)+ ;8  -RGB
    move.l #$01920F00,(a6)+ ;9  -RGB
    move.l #$019400F0,(a6)+ ;10  -RGB
    move.l #$01960FF0,(a6)+ ;11  -RGB
    move.l #$0198000F,(a6)+ ;12  -RGB
    move.l #$019A0F0F,(a6)+ ;13  -RGB
    move.l #$019C00FF,(a6)+ ;14  -RGB
    move.l #$019E0FFF,(a6)+ ;15  -RGB
	
    ; move.l #$01A00000,(a6)+ ;16  -RGB
    ; move.l #$01A20000,(a6)+ ;17  -RGB
    ; move.l #$01A40111,(a6)+ ;18  -RGB
    ; move.l #$01A60111,(a6)+ ;19  -RGB
    ; move.l #$01A80222,(a6)+ ;20  -RGB
    ; move.l #$01AA0222,(a6)+ ;21  -RGB
    ; move.l #$01AC0333,(a6)+ ;22  -RGB
    ; move.l #$01AE0333,(a6)+ ;23  -RGB
    ; move.l #$01B00444,(a6)+ ;24  -RGB
    ; move.l #$01B20444,(a6)+ ;25  -RGB
    ; move.l #$01B40555,(a6)+ ;26  -RGB
    ; move.l #$01B60555,(a6)+ ;27  -RGB
    ; move.l #$01B80666,(a6)+ ;28  -RGB
    ; move.l #$01BA0666,(a6)+ ;29  -RGB
    ; move.l #$01BC0777,(a6)+ ;30  -RGB
    ; move.l #$01BE0777,(a6)+ ;31  -RGB

	move.l #$fffffffe,(a6)+		; end of copperlist (COPPER_HALT)
	

	

;Enable Copperlist

	jsr waitVBlank		;Wait for Vblank before loading our copperlist
	
	lea CopperList,a6	;Enable the CopperList
	move.l a6,$dff080	;COP1LCH - Coprocessor 1st loc(high 3 bits, high 5 bits if ECS)
						;COP1LCL	;Coprocessor 1st loc (low 15 bits)
		
	jsr ClearRam		;Clear the screen and RAM
	
	
	
