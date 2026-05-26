	ifd BuildGEN
		ifd GEN_BMPscreen
			include "sources/ChibiAdventure/GEN_footer_BMP.asm"
		else
			include "sources/ChibiAdventure/GEN_footer.asm"
		endif
	endif
	ifd BuildNEO
		include "sources/ChibiAdventure/NEO_footer.asm"
	endif
	ifd BuildX68
		include "sources/ChibiAdventure/X68_footer.asm"
	endif
	ifd BuildSQL
		include "sources/ChibiAdventure/SQL_footer.asm"
	endif
	ifd BuildAMI
		include "sources/ChibiAdventure/AMI_footer.asm"
	endif
	ifd BuildAST
		include "sources/ChibiAdventure/AST_footer.asm"
	endif