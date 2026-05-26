	ifd BuildGEN
		ifd GEN_BMPscreen
			include "Sources/ChibiAdventure/GEN_footer_BMP.asm"
		else
			include "Sources/ChibiAdventure/GEN_footer.asm"
		endif
	endif
	ifd BuildNEO
		include "Sources/ChibiAdventure/NEO_footer.asm"
	endif
	ifd BuildX68
		include "Sources/ChibiAdventure/X68_footer.asm"
	endif
	ifd BuildSQL
		include "Sources/ChibiAdventure/SQL_footer.asm"
	endif
	ifd BuildAMI
		include "Sources/ChibiAdventure/AMI_footer.asm"
	endif
	ifd BuildAST
		include "Sources/ChibiAdventure/AST_footer.asm"
	endif