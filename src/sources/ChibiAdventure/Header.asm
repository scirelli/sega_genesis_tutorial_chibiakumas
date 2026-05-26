	ifd BuildGEN
		ifd GEN_BMPscreen
			include "sources/ChibiAdventure/GEN_header_BMP.asm"
		else
			include "sources/ChibiAdventure/GEN_header.asm"
		endif
	endif
	ifd BuildNEO
		include "sources/ChibiAdventure/NEO_header.asm"
	endif
	ifd BuildX68
		include "sources/ChibiAdventure/X68_header.asm"
	endif
	ifd BuildSQL
		include "sources/ChibiAdventure/SQL_header.asm"
	endif
	ifd BuildAMI
		include "sources/ChibiAdventure/AMI_header.asm"
	endif
	ifd BuildAST
		include "sources/ChibiAdventure/AST_header.asm"
	endif