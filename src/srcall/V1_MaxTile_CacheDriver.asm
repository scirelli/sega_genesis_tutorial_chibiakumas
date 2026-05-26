
;Warning - Tile pattern address must not be &0000. 
;&00 00 will be mistaken as an end of cache command

CacheMaxBytes equ $1D0	;Max Cache size
						;Leave at least 16 bytes!
						; (For overflow and end of stream)

CacheEntries equ 3		;Total Cache sections (1/3rds)

CacheEntryBytes equ 10	;Byte count per cache entry


Cache_ScreenPos equ 1	;Address of 'screenpos' for raster sync
	
Cache_AddrCur equ 2		;Address of the current working Cache section 
						; (Changes during work)
								
Cache_AddrBak equ 6		;Unchanged Start of cache section


	ifd BuildGEN
T_CacheTable:
		dc.b $C2		;Last Hbyte
		dc.b 3			;Vsync pos
		dc.l CacheAddr1	;Working address
		dc.l CacheAddr1 ;Default Addres
		
		dc.b $C4		;Last Hbyte
		dc.b 4			;Vsync pos
		dc.l CacheAddr2 ;Working address
		dc.l CacheAddr2	;Default Addres
		
T_CacheTable_Last:
		dc.b $FF		;Last Hbyte
		dc.b 5			;Vsync pos
		dc.l CacheAddr3 ;Working address
		dc.l CacheAddr3 ;Default Addres
T_CacheTable_End:
	endif
	

	ifd BuildNEO
T_CacheTable:
		dc.b $08		;0800 ;Last Hbyte
		dc.b 3
		dc.l CacheAddr1; equ &FE00
		dc.l CacheAddr1; equ &FE00
		dc.b $10		;1000
		dc.b 4
		dc.l CacheAddr2; equ &F600
		dc.l CacheAddr2; equ &F600
		
T_CacheTable_Last:
		dc.b $FF		;1800
		dc.b 5
		dc.l CacheAddr3; equ &EE00
		dc.l CacheAddr3; equ &EE00
T_CacheTable_End:
	endif

 	ifd BuildX68
T_CacheTable:
		dc.b $01		;0800 ;Last Hbyte
		dc.b 3
		dc.l CacheAddr1; equ &FE00
		dc.l CacheAddr1; equ &FE00
		dc.b $02		;1000
		dc.b 4
		dc.l CacheAddr2; equ &F600
		dc.l CacheAddr2; equ &F600
		
T_CacheTable_Last:
		dc.b $FF		;1800
		dc.b 5
		dc.l CacheAddr3; equ &EE00
		dc.l CacheAddr3; equ &EE00
T_CacheTable_End:
	endif
 	ifd BuildAMI
T_CacheTable:
		dc.b $28	;0800 ;Last Hbyte
		dc.b 3
		dc.l CacheAddr1; equ &FE00
		dc.l CacheAddr1; equ &FE00
		dc.b $50	;1000
		dc.b 4
		dc.l CacheAddr2; equ &F600
		dc.l CacheAddr2; equ &F600
		
T_CacheTable_Last:
		dc.b $FF		;1800
		dc.b 5
		dc.l CacheAddr3; equ &EE00
		dc.l CacheAddr3; equ &EE00
T_CacheTable_End:
	endif	
	
 	ifd BuildAST
T_CacheTable:
		dc.b $28	;0800 ;Last Hbyte
		dc.b 3
		dc.l CacheAddr1; equ &FE00
		dc.l CacheAddr1; equ &FE00
		dc.b $50	;1000
		dc.b 4
		dc.l CacheAddr2; equ &F600
		dc.l CacheAddr2; equ &F600
		
T_CacheTable_Last:
		dc.b $FF		;1800
		dc.b 5
		dc.l CacheAddr3; equ &EE00
		dc.l CacheAddr3; equ &EE00
T_CacheTable_End:
	endif	
	
 	ifd BuildSQL
T_CacheTable:
		dc.b $23		;0800 ;Last Hbyte
		dc.b 3
		dc.l CacheAddr1; equ &FE00
		dc.l CacheAddr1; equ &FE00
		dc.b $25		;1000
		dc.b 4
		dc.l CacheAddr2; equ &F600
		dc.l CacheAddr2; equ &F600
		
T_CacheTable_Last:
		dc.b $FF		;1800
		dc.b 5
		dc.l CacheAddr3; equ &EE00
		dc.l CacheAddr3; equ &EE00
T_CacheTable_End:
	endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;from cachelist iy/A5
;return ix/A4 =cacheaddress z=cache empty?

GetCacheIY:
	move.l (cache_addrbak,a5),a4

	clr.l d0
	move.b (0,a4),d0	;is cache empty?
	or.b (1,a4),d0		;on 68000 system cache marker is 4+2 bytes
	or.b (2,a4),d0
	or.b (3,a4),d0
	or.b (4,a4),d0
	or.b (5,a4),d0
	rts

	
;'draw' a tilemap into the cache 

;A1    = Pattern Source
;DE/A2 = Source Tilemap
;HL/A3 = Vram Dest 
;IXH/D4 =Width IXL/D5 =Height
;IYH/A6=TilemapWidth


drawtilemap:	;a4/ix=tile cache
	move.l #cachetable,(cachetableaddr)

nextcache:
	move.l (cachetableaddr),a0
	move.b (0,a0),d6	;cache end H VRAM byte
	move.l (2,a0),a4 	;IX CACHE pointer
	clr.l d3			;first tile flag

	
nextlinec:
	move.l a3,d0		;Test High byte
	
;Platform Specific commands to shift the 'high' vram byte into bottom
; 8 bits
	ifd BuildNEO
		ifd DefineHspriteTilemap
			lsr.l #1,d0
		endif
		and.l #31,d0
	endif
	ifd BuildGEN
		lsr.l #8,d0
	endif
	ifd BuildX68
		sub.l #ScreenBase,d0
		lsr.l #8,d0		;Top 8 bits of 24 bit address 
		lsr.l #8,d0
	endif	
	ifd BuildAMI
		sub.l #ScreenBase,d0
		lsr.l #8,d0		;Top 8 bits of 24 bit address 
	endif
	ifd BuildAST
		sub.l (ScreenBase),d0
		lsr.l #8,d0		;Top 8 bits of 24 bit address 
	endif
	ifd BuildSQL
		lsr.l #8,d0		;Top 8 bits of 24 bit address 
		lsr.l #8,d0
	endif
	cmp.b d6,d0		;have we reached the end of this cache?
	bcc overthiscache
		
	clr.l d7		;$FFLL $FF-- =first tile, $--LL = last tile
		
		
	move.l d4,d1
	moveM.l a2/a3,-(sp)
	
NextTileC:
		move.b (a2),d0	;A2=tilemap data %nnccxypu	u=update 
						; p=program yx=flip cc=color/more nn nn=tile h
						
		ifnd doublebuffered
			lsr.b #1,d0 	;get the 'needs update' bit
			bcc tileemptyc
		endif
	
		move.w d7,d0		;check if we already found a tile
		lsr.w #8,d0
		bne firsttilefoundc	;Jump if not the first tile
		
		
		move.b d1,d7		;$FFLL $FF-- =first tile, $--LL = last tile
		addq.b #1,d7
		lsl.w #8,d7			;This is the first tile +1
		
		cmp.b #0,d3
		bne notfirstctile	;not first tile in this tilemap?
		
		;Yes - First, so write Pattern settings
		move.l #1,d3		;set 'not first' flag
		clr.w (0,a4)		;$00 $TT ($00= command marker $TT=Tint)
		move.l a1,(2,a4)	;save pattern address
			
		ifd tiletint
			move.b (tiletint),d0 ;If we use a 16 color 'tint'
			move.b d0,(1,a4)	 ; Store it here (otherwise byte 1 unused
		endif					 ; but present to preserve word alignment)
			
		addq.l #6,a4		;1 Command + 1 Tint + 4 address =6
		
		
notfirstctile:				;First tile on the line
		move.l a3,(2,a4)	;vram dest
		move.l a2,(6,a4)	;Tilemap source

		
firsttilefoundc:
		move.b d1,d7	;$FFLL $--LL =first tile, $--LL = last tile
tileemptyc:
		addq.l #2,a2	;A2=tilemap data %nnccxypu %nnnnnnnn

;Platform specific commands to move across 8 pixels (one tile)
		ifd buildGEN
			addq.l #2,a3		;Across one vram tile
		endif
		ifd buildNEO
			ifd DefineHspriteTilemap
				add.l #64,a3	;Across one tile
			else
			add.l #32,a3		;Across one tile
			endif
		endif
		ifd buildX68
			add.l #16,a3		;Across one tile
		endif
		ifd buildSQL
			addq.l #4,a3		;Across one tile
		endif
		ifd buildAMI
			addq.l #1,a3		;Across one tile
		endif
		ifd buildAST
			addq.l #1,a3		;Across one tile
			move.l a3,d0
			btst #0,d0			;Need to jump to next 8 byte block?
			bne TileDoneH
			addq.l #6,a3		;Yes!
TileDoneH:			
		endif
		
		
		subq.b #1,d1		;Width count
		bne nexttilec
		
		;D7= $FF LL 
		move.w d7,d0		;first tile (eg 11)
		lsr.w #8,d0

		sub.b d7,d0			;last tile  (eg 5)
		beq lineemptyc		;no tiles to draw?
		;move.b #4,d0
		move.b d0,(0,a4)	;write tile count

		add.l #10,a4		;we wrote 10 bytes to cache 
							;(vramhl + tilemaphl + count + Empty)

		move.l a4,d0
		and.w #$1FF,d0
		cmp.w #cachemaxbytes,d0
		bcs CacheNotFull
			jsr cachefull	;is the cache full?
CacheNotFull:


lineemptyc:
	moveM.l (sp)+,a2/a3	;tilemap source / screen pos
	
;Platform specific commands to move down 8 pixels

	ifd buildNEO
		ifd DefineHspriteTilemap
			addQ.l #2,a3		;Down one line
		else
			addQ.l #1,a3		;Down one line
		endif
	endif
	ifd buildGEN
		add.l #64*2,a3			;Down one line
	endif
	ifd buildAMI
		add.l #160*8,a3			;Down one line
	endif
	ifd buildAST
			add.l #160*8,a3		;Down one line	
		endif
	ifd buildX68
		add.l #1024*8,a3		;Down one line
	endif
	ifd buildSQL
		add.l #128*8,a3			;Down one line
	endif
	add.l a6,a2					;Down a tilemap line
	
	subq.b #1,d5
	bne nextlinec				;repeat for next line

	
	
WriteCacheEnd2:
	move.l (cachetableaddr),a0
	move.l a4,(2,a0)			;Write final address of cache data
	add.l #cacheentrybytes,a0	;Move to next cache

writecacheend:
	clr.w (0,a4)	;0000 oooooooo - end of cache marker
	clr.l (2,a4)	;oooo 00000000
	rts				;return new cache address in A0

	
;we're at the last line contained in this cache
overthiscache:
	move.l a0,-(sp)
		jsr writecacheend2		;write end of cache
		move.l a0,(cachetableaddr) ;save cache address
	move.l (sp)+,a0

	jmp nextcache				;start the next cache

	
	
;the cache has no more space 
;we'll flush it now, and start again

cachefull:
	jsr writecacheend			;complete the cache

	moveM.l d1/d2/d4-d7/a1-a3/a5/a6,-(sp)
	
		move.l (cachetableaddr),a5
		move.l a5,-(sp)
			jsr getcacheiy		;z=empty
			beq cachefull_Empty
				jsr processcache	;process the cache
cachefull_Empty:
		move.l (sp)+,a5
		move.l (Cache_AddrBak,a5),a4
	
	moveM.l (sp)+,d1/d2/d4-d7/a1-a3/a5/a6
	clr.l d3					;force write of pattern addr
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetCaches:
	move.w #cacheentries-1,d1	;cache entry count (-1 for dbra)
	move.l #cachetable,a4
	
ResetCachesAgain:
	move.l (cache_addrbak,a4),(Cache_AddrCur,a4) ;Reset Address to default
	add.l #cacheentrybytes,a4					 ;Move to next entry
	dbra d1,resetcachesagain
	rts

	
processcache:
	ifd doublebuffered
		rts
	endif
	
	move.l a4,-(sp)
processcacheagain:
		move.b (0,a4),d7			;Cache 0: line length
		beq processcachezero		;0=special action
		
									;Cache 1: Tint if used
		
		move.l (2,a4),a3 			;Cache 2-5: vram dest
		move.l (6,a4),a2 			;Cache 6-10: tilemap src
		
		
		ifd buildAMI
			ifd drawtileShifted
				move.l a3,d4		;Offset in top 2 bits
				rol.l #3,d4
				and.l #%00000110,d4	;Bitshift in D4
			endif
		endif 
		
		ifd buildAST
			ifd drawtileShifted
				move.l a3,d4		;Offset in top 2 bits (pairs of pixels)
				rol.l #3,d4
				and.l #%00000110,d4	;Bitshift in D4 (in bits)
			endif
		endif 
		
		ifd hiresy
			ifd buildcpc
				;btst #5,d3	;special half shift version
				;bne dostriphalf
			endif
		endif
nexttile:


		ifd slowdowntest	;for debugging
			move.l #$1000,d0
slowdown:
			subq.l #1,d0
			bne slowdown
		endif
	

		move.b (a2),d0		;NNNNXYPU
				
		lsr.b #1,d0			;get the 'needs update' bit
		ifd nodrawcache
			bra drawtile
		else
			bcs drawtile
		endif
emptytile:
		addq.l #2,a2		;A2=tilemap data %NNNNXYPU %nnnnnnnn
tiledone:


		ifd buildGEN
			addq.l #2,a3		;Across one tile
		endif
		ifd buildX68
			add.l #16,a3		;Across one tile
		endif
		ifd buildSQL
			addq.l #4,a3		;Across one tile
		endif
		ifd buildNEO
			ifd DefineHspriteTilemap
				add.l #64,a3	;Across one tile
			else
				add.l #32,a3	;Across one tile
			endif
		endif
		ifd buildAMI
			addq.l #1,a3		;Across one tile
		endif
		ifd buildAST
			addq.l #1,a3		;Across one tile
			move.l a3,d0
			btst #0,d0			;Need to jump to next 8 byte block?
			bne TileDoneHc
			add.l #6,a3			;Yes!
TileDoneHc:	
		endif
		
		subq.b #1,d7			;Horizontal count
		bne nexttile
			
			
tiledone2:
		add.l #10,a4			;10 bytes per cache entry
								;Cmd Tint VramAddr TilemapAddr
		jmp processcacheagain

		
		
processcachezero:				;zerobyte read
		ifd tiletint
			move.b (1,a4),d0	;extra byte for 16 color tint 
			move.b d0,(tiletint)
		endif
		
		move.l (2,a4),a1		;>0 pattern address
		cmp.l #0,a1
		beq processcachedone	;==0 end of cache
		
		addq.l #6,a4			;Skip 4 byte Address + Tint + Command
		bra processcacheagain

processcachedone:
	move.l (sp)+,a4
	jmp writecacheend

