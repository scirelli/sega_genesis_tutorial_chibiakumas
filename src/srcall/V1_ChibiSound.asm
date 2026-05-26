	ifd BuildX68
		include "SrcX68/V1_ChibiSound.asm"
	endif
	ifd BuildAST
		include "SrcAST/V1_ChibiSound.asm"
	endif
	ifd BuildNEO
		include "SrcNEO/V1_ChibiSound.asm"
	endif
	ifd BuildGEN
	ifd ChibiSoundUseFMZ80
			include "srcgen/V1_ChibiSoundFMZ80.asm"
		else
			ifd ChibiSoundUseFM
				include "srcgen/V1_ChibiSoundFM.asm"
			else
				include "srcgen/V1_ChibiSound.asm"
			endif	
			endif
	endif
	ifd BuildAMI
		include "SrcAMI/V1_ChibiSound.asm"
	endif
	ifd BuildSQL
		include "SrcSQL/V1_ChibiSound.asm"
	endif