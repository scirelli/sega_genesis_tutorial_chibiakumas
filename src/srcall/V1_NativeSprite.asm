
NativeSpriteCall:
	move.l #vecNS,a6
	jmp ChibiVM_VectorCall

	
nsInit equ 0		;put this before 	include "ChibiVM_AdventureEngine.asm"
nsDraw equ 1
nsDrawExtra equ 2
nsDrawArray equ 3
nsHide equ 4
nsClearUnused equ 5
nsHideAll equ 6
nsHideAllForBackground equ 7
	
vecNS:
	dc.l NativeSpr_InitReiKou ;dw NativeSpr_InitReiKou	;0
	dc.l DummySyscall ;dw NativeSpr_Draw	;1
	dc.l DummySyscall ;dw NativeSpr_DrawExtra ;2
	dc.l NativeSpr_DrawArrayReiKou ;dw NativeSpr_DrawArrayReiKou ;3
	dc.l DummySyscall ;dw NativeSpr_Hide ;4
	dc.l DummySyscall ;dw NativeSpr_ClearUnused ;5
	dc.l nativespr_hideAll_Reikou
	dc.l nativespr_hideAllForBackground_Reikou
	
	ifd BuildNEO
		include "SrcNEO/NEO_V1_NativeSprite.asm"	;Put before Adventure Engine inc
	endif
	ifd BuildX68
		include "SrcX68/X68_V1_NativeSprite.asm"	;Put before Adventure Engine inc
	endif
	ifd BuildGEN
		include "srcgen/GEN_V1_NativeSprite.asm"	;Put before Adventure Engine inc
	endif
	ifd BuildSQL
		include "SrcSQL/SQL_V1_NativeSprite.asm"	;Put before Adventure Engine inc
	endif
	ifd BuildAMI
		include "SrcAMI/AMI_V1_NativeSprite.asm"	;Put before Adventure Engine inc
	endif
	ifd BuildAST
		include "SrcAST/AST_V1_NativeSprite.asm"	;Put before Adventure Engine inc
	endif
	
	