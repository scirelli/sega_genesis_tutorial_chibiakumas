	ifd BuildNEO
		include "SrcNEO/V1_ChibiSoundPro.asm"
	endif
	ifd BuildGEN
		;include "srcgen/V1_ChibiSoundPro.asm"
		include "srcgen/V1_ChibiSoundProFM.asm"
	endif
	ifd BuildAST
		include "SrcAST/V1_ChibiSoundPro.asm"
	endif
	ifd BuildAMI
		include "SrcAMI/V1_ChibiSoundPro.asm"
	endif
	ifd Buildx68
		include "SrcX68/V1_ChibiSoundPro.asm"
	endif
	ifd BuildSQL
		include "SrcSQL/V1_ChibiSoundPro.asm"
	endif