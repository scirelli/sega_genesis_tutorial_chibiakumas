
NativeSpr_DrawArrayReiKou:	
	;jsr monitor	
	jsr AddressRemapViaTableHLA3
	
	clr.b (HspriteCount)
			
	clr.l d7	;
	move.b (a3)+,d7		;Sprite Count
	
	
NativeSpr_DrawArrayBrk:	
	clr.l d1	
	clr.l d4	
	move.b (a3)+,d4		;Y-pos
	move.b (a3)+,d1		;X-pos
	
	clr.l d3
	clr.l d6
	move.b (1,a3),d3		;NativeSpriteDef H
	move.b (1,a3),d6		;NativeSpriteDef H
	
	asl.l #8,d6
	move.b (0,a3),d6		;NativeSpriteDef L
	
	
	
	addq.l #2,a3
	moveM.l d7/a3/a0,-(sp)
		add.l (VM_RamBaseAddr),d3
		move.l d6,a3
		jsr AddressRemapViaTableHLA3
		
		move.l a3,a2
		
		;move.l #SpriteData_Magnify,a0
		;jsr monitor
		;jmp $
	
		jsr NativeSpr_DrawExtra
	moveM.l (sp)+,a3/d7/a0
	
	subq.b #1,d7
	bne NativeSpr_DrawArrayBrk

	jsr NativeSpr_ClearUnused
	
	move.l #$66660006,d7	;Don't update registers 
	rts
	
	
	
NativeSpr_InitReiKou:
	;jsr monitor	
	jsr AddressRemapViaTableHLA3
	jmp NativeSpr_Init
	
NativeSpriteCall:
	move.l #vecNS,a6
	jmp ChibiVM_VectorCall

	
nsInit equ 0	
nsDraw equ 1
nsDrawExtra equ 2
nsDrawArray equ 3
nsHide equ 4
nsClearUnused equ 5
NativeSpr_HideAll equ 6
	
vecNS:
	dc.l NativeSpr_InitReiKou ;dw NativeSpr_InitReiKou	;0
	dc.l DummySyscall ;dw NativeSpr_Draw	;1
	dc.l DummySyscall ;dw NativeSpr_DrawExtra ;2
	dc.l NativeSpr_DrawArrayReiKou ;dw NativeSpr_DrawArrayReiKou ;3
	dc.l DummySyscall ;dw NativeSpr_Hide ;4
	dc.l DummySyscall ;dw NativeSpr_ClearUnused ;5
