	ifd BuildGEN
		ifd GEN_BMPscreen
			include "\Sources\ChibiAdventure\GEN_header_BMP.asm"
		else
			include "\Sources\ChibiAdventure\GEN_header.asm"
		endif
	endif
	ifd BuildNEO
		include "\Sources\ChibiAdventure\NEO_header.asm"
	endif
	ifd BuildX68
		include "\Sources\ChibiAdventure\X68_header.asm"
	endif
	ifd BuildSQL
		include "\Sources\ChibiAdventure\SQL_header.asm"
	endif
	ifd BuildAMI
		include "\Sources\ChibiAdventure\AMI_header.asm"
	endif
	ifd BuildAST
		include "\Sources\ChibiAdventure\AST_header.asm"
	endif