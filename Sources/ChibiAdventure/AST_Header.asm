
    SECTION TEXT		;CODE Section
FileZero:	


    move.l #ProgramStart,-(sp)  ;address to call
    move.w #38,-(sp)  		;Supexec (Set supervisor execution)
    trap #14         		;X-BIOS Trap
    addq.l #6,sp       		;Clean up the stack
	jmp *					;Infloop - Supervisor mode will call
							;		   our Start addrress 

							
ProgramStart:
	clr.b $ff8260			;Set Screen Mode: 00=320x200 4 planes
	
    move.l #screen_mem,d0  	;Move address to screen mem to d0
    add.l #$ff,d0      		;Add 255 to the loaded address 
    clr.b d0           		;Clear the lowest byte in our address
							; (ensure we're 8 bit aligned)
    move.l d0,ScreenBase	;Save the new screenbase
	
    lsr.w #8,d0       		;we need to convert $00ABCD?? into $00AB00CD
    move.l d0,$ff8200		; store the resulting 16 bits
							;  into the screen start register
							;&FF8201 = High byte
							;&FF8203 = Mid  byte
							;Low byte cannot be specified (We know its 00)
								
								
	move.l #$ff8240,a1		;Define palette
	move.l #Palette,a0
	move.l #16-1,d0
PaletteAgain:						
	move.w (a0)+,(a1)+		;%-----RRR-GGG-BBB
	dbra d0,PaletteAgain
	
	
	jsr InstallJoysytickHandler	;Enable the Joystick scanner
			
	jsr ClearRam			;Clear the screen and RAM
	
	
	
