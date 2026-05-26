	Macro AnimCall,p1
		dbb SYSi,syscallAnim
		db \1
	endm
	
	
	
syscallAnim equ 10

anAnimateInit equ 0+regNO
anAnimateIX equ 1+regNO
anAnimateIXIY equ 2+regNO
anAnimateIXIYcs equ 3+regNO

vecANIM:
	dc.l Anim_Init			;0
	dc.l Anim_AnimateIX		;1
	dc.l Anim_AnimateIXIY		;2
	dc.l Anim_AnimateIXIYcs	;3

rkANIMLast equ 4


	
AnimCall:	
	move.l #vecANIM,a6
	jmp ChibiVM_VectorCall
	;ld hl,vecANIM
	;jp DoVectorCall
	


;Animator Byte format: (4 bytes per line)

;%CCCMAAAA

;C = Condition (eg execute if EQUAL / Altmode (eg IY switch)
;M = Multiline (Execute next line in this tick)
;A = Animator command 

;CONDs can only be used on commands which don't use ALT
		
cndAL equ 0*32
cndEQ equ 1*32
cndNE equ 2*32
cndCS equ 3*32
cndCC equ 4*32
cndTz equ 5*32	;AND =0
cndTN equ 6*32	;AND <>0
cndTT equ 7*32	;AND TICKS <>0

;Alts can only be used on commands which don't use COND

altIY equ 128	;use IY instead of IX
;altCORE equ 64	;use 'Core Engine' vars instead of IX (not implemented yet)
;altSPARE equ 32 ;not used

aEXT equ 16		;EXTra command line


aEXTD_nop equ 0			;No operation (empty frames)
aEXTD_loop equ 1		;Loop back to frame 0
aEXTD_halt equ 2		;Stop the animation
aEXTD_anim equ 3		;Switch to animtor pB frame pc
aEXTD_vmexec equ 4		;Execute pBC in the VM (on the virtual cpu)
aEXTD_call equ 5		;Call pBC natively (on the main cpu)
aEXTD_SwapIXIY equ 6	;Set IX=IY registers

						

;Format %cccAAAAA A=Animator cmd /  C=Condition
;Animators 4 bytes... Animator cmd,pA,pB,pC
anmEmpty 	equ 0		;do nothing (Don't use at the end of animator)
anmEXTD	 	equ 1		;see Animator_VectorArrayEXT
anmCondjmp  equ 2		;Conditionally jump to frame Pc if pA compares to pB
anmCondbra  equ 3 		;Conditionally branch to frame +/- Pc if pA compares to pB
anmLD16		equ 4		;Use offset pA Load pBC
anmLD8		equ 5		;Use offset pA Load pB
anmLD8d		equ 6		;Use offset pA Load pB pA2 Load pC (pA is two 4 bit offsets)
anmAdd16	equ 7		;Use offset pA add pBC
anmAdd8d	equ 8		;Use offset pA add pB pA2 add pC (pA is two 4 bit offsets)
anmAddMsked	equ 9		;Use offset pA Add pB AND pC
anmLdAdd8d  equ 10		;Use offset pA Load pB pA2 , add to pC (pA is two 4 bit offsets)
anmCndLD8	equ 11		;Conditional load 8 bit pC to pA if pA compares to pB
anmCndAdd8	equ 12		;Conditional add 8 bit pC to pA if pA compares to pB
anmCndAnim	equ 13		;Conditionally switch to animator Pc if pA compares to pB
;14
;15 unused (15 MAX)

;Animator commands (0-15 only)
Animator_VectorArray:
	dc.l  ObjectAnimator_Update	;0
	dc.l  ObjectAnimator_EXT		;1
	dc.l  ObjectAnimator_CondJmp	;2
	dc.l  ObjectAnimator_CondBra	;3
	dc.l  ObjectAnimator_Load16	;4
	dc.l  ObjectAnimator_Load8		;5
	dc.l  ObjectAnimator_Load8dual	;6
	dc.l  ObjectAnimator_Add16		;7
	dc.l  ObjectAnimator_Add8dual  ;8
	dc.l  ObjectAnimator_AddMasked	;9
	dc.l  ObjectAnimator_LoadAdd8dual	;10
	dc.l  ObjectAnimator_CondLD8		;11
	dc.l  ObjectAnimator_CondAdd8		;12
	dc.l  ObjectAnimator_CondAnim 		;13
	
	
;EXT commands (used by animator command 1 - byte pA)
Animator_VectorArrayEXT:
	dc.l  ObjectAnimator_Update		;0
	dc.l  ObjectAnimator_LoopToStart 	;1
	dc.l  ObjectAnimator_Halt			;2
	dc.l  ObjectAnimator_SetAnim		;3
	dc.l  ObjectAnimator_vmexec		;4
	dc.l  ObjectAnimator_call			;5
	dc.l  ObjectAnimator_SwapIXIY		;6
	
;s0 r0  A	  D0
;s1 r1  B BC  D1 A1
;s2 r2  D DE  D2 A2
;s3 r3  H HL  D3 A3
;s4 r4  C     D4
;s5 r5  E     D5
;s6 r6  L     D6
;s7 r7  IX       A5
;t7 r8  IY       A6
;t8 r9	      D7

;t9/a0 r10	 (Was A0 / r10)
;t9/a1 r11	 (Was A0 / r10)

	
;D3/D6 are HL'
;A1/A4 are BC'
;D7 is D'
	
	
;                                     

;                                     anim_init:
anim_init:

	move.l (VM_RamBaseAddr),a0
	LoadLEA0 VM_rR6,a3
	
	jsr AddressRemapViaTableHLA3
	move.l a3,(animatorpointers)   ;Animator array

	rts

	
anim_animateixiycs:
	move.l (VM_RamBaseAddr),a0
	LoadLEA0 VM_rR6,a3
	jsr AddressRemapViaTableHLA3
	move.l a3,a6
	
	move.l (VM_RamBaseAddr),a0
	LoadLEA0 VM_rR0,a3
	jsr AddressRemapViaTableHLA3	;Animator script
	move.l a3,a6
	
	bra anim_animateixb

	
anim_animateixiy:
	
	move.l (VM_RamBaseAddr),a0
	
	LoadLEA0 VM_rR6,a3
	jsr AddressRemapViaTableHLA3
	move.l a3,a6
	
anim_animateix:
	move.l #0,d3			;Disable CustomSpeed

anim_animateixb:
	clr.l d1
	clr.l d4
	move.l (VM_RamBaseAddr),a0
	
	move.b (vm_rr3,a0),d1
	move.b (vm_rr2,a0),d4    ;d1/b=anim / d4/c=frame
	
	move.b d1,d0

	movem.l a3/d3/d6,-(sp)
		 move.l (VM_RamBaseAddr),a0
		 LoadLEA0 VM_rR4,a3
		
		jsr AddressRemapViaTableHLA3
		move.l a3,a5		;IX
	movem.l (sp)+,a3/d3/d6

	jsr objectanimator
	

	move.l (VM_RamBaseAddr),a0
	
	move.l a4,d4
	move.l a1,d1
	
	move.b d1,(vm_rr3,a0)   ;animator / new frame 
	move.b d4,(vm_rr2,a0)
	move.l #$66660006,d7	;Tell ChibiVM not to update registers 

	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	

	
objectanimator_condloopincresetick:
	addq.l #1,a4		;call objectanimator_increasetick
	jmp objectanimatoragain

	
objectanimator:   ;animate sprite (D1=Anim D4=Frame/tick)
	tst.b d1			;0=No animator
	beq objectanimator_ret

	move.l d1,a1	;B'
	move.l d4,a4	;C'

objectanimatoragain:    ;A1/b=animator number / A4/c=step / hl =animator addr / hl` optional custom speed
	move.l a1,d1	;B'
	move.l a4,d4	;C'
		
	jsr getanimatormempos
	
	move.b (a3),d5      ;check if a tick has occured
	
	cmp.b #255,d3   	;use custom tick speed l ? (255=yes) ;H'
	bne objectanimatoragain_nocustomspeed

	clr.l d0
	move.b (timer_ticksoccured),d0

	and.b d6,d0   		;custom tick speed	;L'
	beq objectanimator_ProcessTick ;tick! process animator
	bra objectanimatoragain_nocustomspeedb

objectanimatoragain_nocustomspeed:
	clr.l d0
	move.b (timer_ticksoccured),d0
	and.b d5,d0    		;apply tick mask

objectanimatoragain_nocustomspeedb:
	beq objectanimator_ProcessTick    ;tick! process animator

	 move.l a1,d1	;BC'
	 move.l a4,d4
objectanimator_ret:
	rts        			;return with a= new animator number
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
objectanimator_ProcessTick:
	addq.l #1,a3    	;move past the 'tick mask'
	
;objectanimator_executetick:
	clr.l d0
	move.b d4,d0  		;c=ticknum
	asl.l #2,d0 		;each tick's commands takes 4 bytes
	add.l d0,a3   		;get tick commands
		
	move.b (a3)+,d0 	;command num
	  
	move.b d0,d7  		;for multiline		;D'
	move.b d0,d4

	and.l #%00001111,d0  ;top bits are condition 
	
	move.l #animator_vectorarray,a0  ;execute sub a from list A0

vectorjump_pushhlfirst:  ;jump to address no a at hl  
	and.l #$000000FF,d0
	asl.l #2,d0
	move.l (a0,d0),d0	;Get address pointer
	
	jmp d0
	;move.l d0,-(sp)		;Switch address onto stack
	;rts					;Effectively Call it

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
objectanimator_ext:
	move.b (a3)+,d0
	move.l #animator_vectorarrayext,a0
	
vectorlookup:   ;get entry a from word list hl
	and.l #$000000FF,d0
	asl.l #2,d0
	move.l (a0,d0),d0	;Get address pointer
	move.l d0,-(sp)		;Switch address onto stack
	rts					;Effectively Call it

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

getanimatormempos:    ;b=animator number / c=frame
	move.l (animatorpointers),a3
	clr.l d0
	move.b d1,d0       ;animator
	subq.l #1,d0       ;1-15 -> 0-14 (zero is no animator)
		
	ifd ChibiVM_16bitAnimatorLinks
		rol.l #1,d0 		;2 bytes per animator
		add.l d0,a3

		clr.l d0	
		move.b (1,a3),d0	;For 16 bit entries (little endian)
		asl.l #8,d0
		move.b (0,a3),d0	;For 16 bit entries
		
		move.l (vm_rambaseAddr),a3
		add.l d0,a3
	else 
		rol.l #2,d0 			;2 bytes per animator
		add.l d0,a3
					
		clr.l d0			;big endian
		move.b (0,a3),d0		;For native 32 bit entries
		asl.l #8,d0
		move.b (1,a3),d0		;For native 32 bit entries
		asl.l #8,d0
		move.b (2,a3),d0		;For native 32 bit entries
		asl.l #8,d0
		move.b (3,a3),d0		;For native 32 bit entries
		move.l d0,a3
		
	endif 
	rts
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


objectanimator_looptostart:
	move.l #0,a4  		 ;C' frame=0
	bra objectanimatoragain

ObjectAnimator_Halt:	;stop this object animating
	move.l #0,a1    	;animator =0 (halt)
	rts

	
ObjectAnimator_SetAnim:   ;set animator / frame
	move.b (a3)+,d0
	move.l d0,a1     	 	;anim

	move.b (a3),d0
	move.l d0,a4    		;frame
	bra objectanimator


objectanimator_vmexec:		;execute an address inside chibivm
	clr.l d1
	move.b (a3)+,d1      ;load an address and execute
	asl.l #8,d1
	move.b (a3),d1
	jsr vm_causecallfromoutsidevm
	bra objectanimator_update


objectanimator_call:		;execute an address natively
	;move.b (a3)+,d5   ;load an address and execute
	;move.b (a3),d2

	movem.l a3/d3/d6,-(sp)
		move.l (VM_RamBaseAddr),a0
		clr.l d0
		move.b (1,a3),d0
		asl.l #8,d0
		move.b (0,a3),d0
		add.l (VM_RamBaseAddr),d0
		move.l d0,a3
		jsr AddressRemapViaTableHLA3
		move.l a3,a2
	movem.l (sp)+,a3/d3/d6
	
	jsr callde

callde:
	move.l a2,-(sp)	;push the address we want to call onto the stack
	rts
	
		
objectanimator_swapixiy
	exg a6,a5				;A5=IX A6=IY
	bra objectanimator_update

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	
;we're done, so update the tick

objectanimator_update:
	addq.l #1,a4 			;IncreaseTick
	
	move.b d7,d0
	and.b #%00010000,d0		;More lines this tick?
	bne objectanimatoragain
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	
ObjectAnimator_CondJmp:	;Jump to frame number if cond true.
	jsr objectanimator_condprocess
	bcc objectanimator_condloopincresetick	;condition false

	addq.l #1,a3
	move.b (a3),d0    	;get new line num
    
	move.l d0,a4   		;new frame nuumber
	jmp objectanimatoragain

		
objectanimator_condbra:	;relative branch +- ticks (1=skip one line)
	jsr objectanimator_condprocess
	bcc objectanimator_condloopincresetick ;condition false
		
	addq.l #1,a3
	move.b (a3),d0     	;get new line num

	addq.l #1,a4 	 	;skip current command
	add.l d0,a4
	jmp objectanimatoragain
		
		 
objectanimator_load16:		;load a 16 bit value
	jsr objectanimator_offsetdestfromhl
	move.b (a3)+,(a2)+
	move.b (a3)+,(a2)+
	jmp objectanimator_update
	
		
objectanimator_load8:  ;load a single 8 bit value
	jsr objectanimator_offsetdestfromhl
	move.b (a3)+,(a2)+
	jmp objectanimator_update

	
objectanimator_load8dual:   ;load 8 bit values to 2 offsets 
	move.b (a3)+,d0  		; eg set x and spritenum
	move.b d0,d1
	jsr objectanimator_offsetdestnibble
	move.b (a3)+,(a2)+
	
	jsr objectanimator_offsetdestnibbletop
	move.b (a3)+,(a2)+

	jmp objectanimator_update
	
	
objectanimator_add8dual:  	;8 bit add to 2 offsets
	move.b (a3)+,d0 		; eg move ey
	move.b d0,d1

	jsr objectanimator_offsetdestnibble
	move.b (a3)+,d0
	add.b d0,(a2)+

objectanimator_add8dual_2ndadd:

	jsr objectanimator_offsetdestnibbletop
	move.b (a3)+,d0
	add.b d0,(a2)+
	jmp objectanimator_update
	

objectanimator_add16:		;add a 16 bit value
	jsr objectanimator_offsetdestfromhl
	move.b (a3)+,d0
	add.b d0,(a2)+			;Add L byte
	bcc objectanimator_add16_NC
	addq.b #1,(a2)
objectanimator_add16_NC:

	move.b (a3)+,d0
	add.b d0,(a2)+			;Add H byte
	jmp objectanimator_update

	
objectanimator_addmasked:   ;add 8 bit then mask
							;(if mask is 255 this acts as 8 bit add)
	jsr objectanimator_offsetdestfromhl	
	;move.b (a2),d0
		
	add.b (a3)+,d0			;Value to ADD
	and.b (a3),d0
	move.b d0,(a2)			;Value to AND
	jmp objectanimator_update

	
objectanimator_loadadd8dual: ;load one, add one
	move.b (a3)+,d0     ;  eg move + spritenum
	move.b d0,d1
	jsr objectanimator_offsetdestnibble

	bra objectanimator_add8dual_2ndadd
		
	
objectanimator_condld8:	;Load 8 bit if condition true
	move.b (a3),d1
	jsr objectanimator_condprocess
	bcs objectanimator_update	 ;Condition false

	move.b d1,d0
	jsr objectanimator_offsetdest
	
	addq.l #1,a3
	move.b (a3)+,(a2)+            ;load the 8 bit
	bra objectanimator_update

	
objectanimator_condadd8:	;add 8 bit if condition true
	move.b (a3),d1
	jsr objectanimator_condprocess
	bcs objectanimator_update ;condition false

	move.b d1,d0
	jsr objectanimator_offsetdest	;Set A2/DE to byte in object
	
	addq.l #1,a3
	move.b (a3),d0			;add 8 bit value 
	add.b d0,(a2)
	bra objectanimator_update

	
objectanimator_condanim:	
	jsr objectanimator_condprocess
	bcc objectanimator_condloopincresetick ;condition false
	
	addq.l #1,a3
	move.b (a3),d0   	;get new anim

	move.l d0,a1     	;anim
	move.l #0,a4   		;frame
	jmp objectanimatoragain

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Double commands use a pair of 4 bit offsets
objectanimator_offsetdestnibbletop: ;get top nibble
    btst #7,d4
	beq lbl_C829xBBC7
		jsr objectanimator_useiy
lbl_C829xBBC7

	move.b d1,d0
	ror.b #4,d0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  
objectanimator_offsetdestnibble:	;get bottom nibble
	and.l #%00001111,d0
	bra objectanimator_offsetdest


ObjectAnimator_OffsetDestFromHL:	;Calculate Dest DE=IX+A
    btst #7,d4
	beq objectanimator_offsetdestfromhlcond
		jsr objectanimator_useiy

objectanimator_offsetdestfromhlcond:    ;don't check c-bit7
	move.b (a3)+,d0        ; (for conditionals)

objectanimator_offsetdest:  	;A2=A5+D0	de=ix+a
	move.l a5,a2
	and.l #$000000FF,d0
	add.l d0,a2
	
	move.b (a2),d0
	rts

	
objectanimator_useiy:
	exg a6,a5   ;switch ix=iy
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

objectanimator_condprocess:
	jsr objectanimator_offsetdestfromhlcond
	move.b (a2),d2  ;param1 (var/off)
	move.b (a3),d5 ;param2 (val)
	
objectanimator_processcondition:  ;c=condition d/e = compare params
	lsr.l #5,d4
	and.l #%00000111,d4
	beq objectanimator_processconditiontrue ;BRA 0

	move.b d2,d0
	
	subq.b #1,d4
	beq objectanimator_processconditioneq ;1 eq

	subq.b #1,d4
	beq objectanimator_processconditionne ;2 ne

	subq.b #1,d4
	beq objectanimator_processconditioncs ;3 cs

	subq.b #1,d4
	beq objectanimator_processconditioncc ;4 cc

	subq.b #1,d4
	beq objectanimator_processconditionteq ;5 tstz

	subq.l #1,d4
	beq objectanimator_processconditiontne ;6 tstnz
	
	
;ObjectAnimator_ProcessConditionTestTicks
	move.b (timer_ticksoccured),d0
	and.b d2,d0
	beq objectanimator_processconditiontrue
	bra objectanimator_processconditionfalse

	
objectanimator_processconditionteq:
	and.b d5,d0
	beq objectanimator_processconditiontrue
	bra objectanimator_processconditionfalse

objectanimator_processconditiontne:
	and.b d5,d0
	bne objectanimator_processconditiontrue
	bra objectanimator_processconditionfalse
	
objectanimator_processconditioncs:
	cmp.b d5,d0
	bcs objectanimator_processconditiontrue
	bra objectanimator_processconditionfalse

objectanimator_processconditioncc:
	cmp.b d5,d0
	bcc objectanimator_processconditiontrue
	bra objectanimator_processconditionfalse

objectanimator_processconditioneq:
	cmp.b d5,d0
	beq objectanimator_processconditiontrue

objectanimator_processconditionfalse:
	;clr.l d4	;used as objectanimator_useiy for non conditions
	and #%11111110,CCR			;Clear carry
	rts

	
objectanimator_processconditionne:
	cmp.b d5,d0
	;bne objectanimator_processconditiontrue
	beq objectanimator_processconditionfalse
	
objectanimator_processconditiontrue:
    ;scf
	;clr.l d4	;used as objectanimator_useiy for non conditions
	or #%00000001,CCR	;Set carry
	rts
	
	
	
	