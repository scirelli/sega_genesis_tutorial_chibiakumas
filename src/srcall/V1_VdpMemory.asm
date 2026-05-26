	ifd BuildGEN
		include "srcgen/V1_VdpMemory.asm"
	endif
	ifd BuildNEO
		include "SrcNEO/V1_VdpMemory.asm"
	endif
	