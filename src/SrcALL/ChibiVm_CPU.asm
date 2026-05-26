;TODO: FIX CMP16 with immediate not using 16 bit mode!!!



;ChibiVM simulates an 8 bit cpu, it's design is inspired mostly by the Z80 
;  and 6809	and will be therefore referred to as the AKUC809.R1 (chibi AKUmas Cpu 809 Revision 1)

;It uses the Z80's 8/16 bit register pair combination and core instruction set capabilities, flag functions
; including 16 bit stack pointer and IX+n type addressing - It is also LITTLE ENDIAN
;It uses the 6809's zeropage, three letter instructions mnemnonics, B accumulator and extended byte for flaxible addressing
;It uses the PDP-11's 8 register concept and powerful addressing modes (which also inspired the 6809)
;It uses 68000 style traps for interrupts
;It uses the 2 byte branch ops and vblank counter from Chip-8
;It uses the concept of memory mapped registers of the TMS9900
;It uses Memory mapping / bankswitching based on that of the Enterprise / Mastersystem

	
;Syntax

;First 256 bytes are a 'zeropage' - The zeropage is not relocatable
;First 16 of those bytes are 'register'
;0-7  are register pairs R0-R7
;8-16 are system (SP/PC Flags)
;17-31 are free for user use.
;32-47 are reserved for Virtual memory mapping (when enabled)

;Commands are defined by top 6 bits:
; %CCCCCCAA - C= 6 bit command A=2 bit addressing mode
; So 64 commands max!
; Commands %110000+ are reserved for user extensions.

; AA=0 Params are R0 and R2				 %CCCCCC00
; AA=1 Params are R0 and 8 bit immediate %CCCCCC01 %IIIIIIII
; AA=2 Params are R0 and Zero page Z  	 %CCCCCC10 %ZZZZZZZZ
; AA=3 uses extra Byteparam 			 %CCCCCC11 %PPPPDDDD  - P=Parameter2 D=Param1 & Dest
	;More bytes may be neded depending on parameter selection
	
;Branches use diferent addressing options:
;	AA=0 PC=PC+2
;	AA=1 PC=PC+IMM8
;	AA=2 PC=IMM16
;	AA=3 PC=R6/R7
	
;ByteParam supports 15 options for source & Destination.

;Reg 8 bit 0-3, 16 bit 4,6 (5,7 can be acessed via ZP)
;Zeropage Address / 16 bit address
;RegPair = 16 bit pointer
;RegPair+ = 16 bit pointer with PostInc
;RegPair with imm8 offset = 16 bit pointer with signed immediate offset

;For Parameter only: 	Immediate 8 bit / Immediate 16 bit 
;For Dest only: 		F register / Top of stack

;Warning! Some options may not make sense - Eg 8 bit load command with 16 bit immediate
;16 bit load with 8 bit immediate.
;Results will be unpredictable!

;Flags are in Zeropage:15 in the format ;%HSTEI-ZC
;Flag functions (and all functions in general) should mimic a z80
;Commands that do not set flags leave them unchanged.
;Commands That set one flag may not correctly set both flags, other flag is undefined

;Halt Flag: Set when the CPU halts, can be used to detect when CPU is not running (or check if current command is halt)
;			If you restart the CPU with a new task, you should clear the flags
;			If you HALT the system, you should assume it will never restart (your work is done)
;			If you want to be restarted, set S flag (Sleep) - to tell the host to restart at a good time (By stepping over the HALT command)

;Sleep Flag Use this to mark a HALT as possibly temporary if you want the host to restart your VM at some point

;Trap Flag: you can set this at the start of your traps, and clear it when done
;			This is intended so you can see if the CPU is running an interrupt - and give it higher priority 
;			If doing this, Note the return will not occur when the flag clears, so you should run one extra tick to process the RET command after the flag clears

;			Back up flags before trap with PHF
;			Set Flag with:    vm_ORR+ParamExtByt,Dest_ZeroPg+Param_Imm8,VM_rF,VM_fTrap  
;			Flags should restored with PLF 

;Error Flag 	Set when (1) an unknown command byte was detected
;				(2) A system call or trap was executed with an unsupported parameter (eg bankswitching on a machine that cannot do it)

;Interrupt Disable flag: (I)
;			Stop hardware from sending interrupt traps (Eg Vblank)



;Virtual Memory & Bankswitching:
;			The 64k address range is split into 4 blocks in the format
;			%BBAAAAAA AAAAAAAA BB=Bank AA...AA=Address 
;			4x 32 bit calues in the Zeropage define the Physical address base for each bank
;			This 32 bit value is added to the A bits to give the pysical address
; 			The correct 'normal' values are therefore &0000 &4000 &8000 &C000
;These are HARDWARE addresses, ChipEXT will provide a 'platform independant' bankswitching method 
;WARNING: 	Bankswitching occurs only once for each read/write.
;			This means reading a word spread across a 16k boundary may malfunction, as the second byte will be read from the first bank+1.
;			* Including words in code! *

;Zero page layout:

;First 8 bytes are registers:	AA KK BB CC DD EE HH LL (General Regs)
;Next 8 bytes are system:		FF FU PC PC SP SP VB VB (System Regs)
;Next 16 bytes are for user:    0  0  0  0  0  0  0  0  (User)
;...						    0  0  0  0  0  0  0  0	(User)
;Next 16 bytes are bankswitch   B0 B0 B0 B0 B1 B1 B1 B1 (Bankswitching)
;...						    B2 B2 B2 B2 B3 B3 B3 B3 (Bankswitching)

;Remaining bytes are implementation specific. Stack may share ZP ram. 
;Bankswitch bytes are only used if vm_useVMEM is defined 
; A recomended absolute minimum would be 64 bytes ram total for ZP+Stack

;Traps and systcalls use the 'parameter' to select a numbered function from the vector list
;These are intended to work from an 8 bit immediate, but can also work from a register or memory.

;value in register AK will be used to select 'subfunction' of trap - other regs are parameters as defined by that function

;Traps:
;0 RESET - Used to INIT the program counter
;1 VBLANK?
;3+ - For your own use

;Syscall: (suggestion)
;0 ChipEXT - reserved for system functions (Bankswitching / Debugger / Rand / Mult etc) - comamnd in A, Sets E flag if unknown command
;1 VMControl - For configuring VM functions (Enable/disable interrupts / Shutdown VM / Disk Load etc)
;2 VMMonitor - VM Monitor - dump regs to screen
;3+ - For your own use

VM_fHalt  equ  %10000000	;HALT ocurred (Set Automatically)
VM_fSleep equ  %01000000	;Sleep (Set Manually)
VM_fTrap  equ  %00100000	;Trap Running (Set Manually)
VM_fError equ  %00010000	;Unknown Opcode (Set Automatically) \ Syscall function \ Trap function
VM_fIntDis equ  %00001000	;Interrupts disabled (Set Manually)
VM_fTrace equ  %00000100	;Trace enabled (monitor after each command)
VM_fZero equ  %00000010		;Last command resulted in Zero
VM_fCarry equ  %00000001		;Last command resulted in Carry

;All registers are 8 bit, all can be used as 16 bit pairs
;R0-R3 are intended for 8 bit ops (R2+3 is also ideal for 16 bit)
;R4+5 R6+7 are intended for 16 bit ops
;All are accessible from the Zero page addresses 0-7

;Registers Should be referred to by number, though they are given Z80 style 'Letter pairs' to make them easier to remember
;16 bit ops automatically use the next register (eg R0+R1)
;Acutally, odd combinations will also work in 16 bits (Eg R5+R6 LD), though the indirect addressing modes
;do not support these combos.


;When an operation is performed with no other parameter, it is performed on AB
; EG: XOR   performs A  = A  XOR B (R0 = R0 XOR R2)
;     ADD16 performs AK = AK + UB (R0/1 = R0/1 + R2/3)


VM_rR0 equ 0	;Accumulator A - 16 bit AK pair  (Default Destination for ops)
VM_rR1 equ 1	;K (Counter?)
VM_rR2 equ 2	;Accumulator B  - 16 bit BC Pair  (Default parameter for ops)
VM_rR3 equ 3	;C
VM_rR4 equ 4	;E - 16 bit DE pair 
VM_rR5 equ 5	;D
VM_rR6 equ 6	;L - 16 bit HL Pair
VM_rR7 equ 7	;H

VM_rR8 equ 16	;Zero page entries 
VM_rR9 equ 17
VM_rR10 equ 18
VM_rR11 equ 19
VM_rR12 equ 20
VM_rR13 equ 21
VM_rR14 equ 22
VM_rR15 equ 23

VM_rR16 equ 24	;Zero page entries 
VM_rR17 equ 25
VM_rR18 equ 26
VM_rR19 equ 27
VM_rR20 equ 28
VM_rR21 equ 29
VM_rR22 equ 30
VM_rR23 equ 31


R0 equ 0
R1 equ 1
R2 equ 2
R3 equ 3
R4 equ 4
R5 equ 5
R6 equ 6
R7 equ 7

R8 equ 16	;Zero page entries 
R9 equ 17
R10 equ 18
R11 equ 19
R12 equ 20
R13 equ 21
R14 equ 22
R15 equ 23

R16 equ 24	;Zero page entries 
R17 equ 25
R18 equ 26
R19 equ 27
R20 equ 28
R21 equ 29
R22 equ 30
R23 equ 31

VM_rF equ  8	;Flags %HSTEItZC (Halted) (Halted -Sleeping) (Trap running) (Error - unknown opcode) (Interrupt disabled) (Zero) (Carry) (t=trace)
VM_rFU equ 9	;Flags User (unused by cpu - backed up with PHF / PLF) 
VM_rPC equ 10	;Program Counter
VM_rSP equ 12	;Stack pointer
VM_rVB equ 14	;Vblanks (0-65535)

vm_rBank0 equ 32	;&0000-&3FFF 
vm_rBank1 equ 36	;&4000-&7FFF
vm_rBank2 equ 40	;&8000-&BFFF
vm_rBank3 equ 44	;&C000-&FFFF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	even
vm_ParameterAddressingModes:	;Subtract 5 (First addressing R0-R4)
	dc.l VM_GetAddress_R6							;vm_pR6 equ 5	;Param R6
	dc.l VM_GetAddress_ByteParam_Indir16_R2_BaseImm	;vm_PB2 equ 6 	;Indirect 16 bit pointer R2 (16 bit to anywhere) - Base+imm8 offset
	dc.l VM_GetAddress_ByteParam_Indir16_R4_BaseImm	;vm_PB4 equ 7 	;Indirect 16 bit pointer R4 (16 bit to anywhere) - Base+imm8 offset
	dc.l VM_GetAddress_ByteParam_Indir16_R2_PostInc	;vm_PU2 equ 8 	;Indirect 16 bit pointer R2 (16 bit to anywhere) - PostInc
	dc.l VM_GetAddress_ByteParam_Indir16_R6_PostInc	;vm_PU6 equ 9 	;Indirect 16 bit pointer R6 (16 bit to anywhere) - PostInc
	dc.l VM_GetAddress_ByteParam_Indir16_R4			;vm_PQ4 equ 10 	;Indirect 16 bit pointer R4 (16 bit to anywhere)
	dc.l VM_GetAddress_ByteParam_Indir16_R6			;vm_PQ6 equ 11 	;Indirect 16 bit pointer R6 (16 bit to anywhere)
	dc.l VM_GetAddress_ByteParam_ImmAddr16			;vm_pA6 equ 12	;Address 16
	dc.l VM_GetAddress_ByteParam_ImmAddr8			;vm_pA8 equ 13	;Address 8 (ZeroPage)
	dc.l VM_GetAddress_ByteParam_Imm16				;vm_pI6 equ 14	;Immediate 16 - Source only
	dc.l VM_GetAddress_ByteParam_Imm8				;vm_pI8 equ 15	;Immediate 8 - Source only

	;ifd VASM
; vm_ParameterAddressingModesH equ vm_ParameterAddressingModes>>8
; vm_ParameterAddressingModesL equ vm_ParameterAddressingModes&255
	; else
; vm_ParameterAddressingModesH equ vm_ParameterAddressingModes/256
; vm_ParameterAddressingModesL equ vm_ParameterAddressingModes
	; endif	
	
;%-PPPFFF-
;Prep: (tasks run before command)
prp_Nothing equ 0*16
prp_VM_GetAddress_Branch  equ 1*16
prp_VM_GetAddress equ 2*16
prp_VM_GetAddress_VM_GetFlagC  equ 3*16
prp_VM_GetAddress16 equ 4*16	
prp_VM_GetAddressPrep_ZPDest equ 5*16	;Patched for INC ZP (Dest=Param)
prp_VM_GetAddressPrep_ZPDest_GetFlagC equ 6*16
;Finishers: (tasks run after command)
fin_Nothing equ 0*2
fin_VM_PC_Store equ 1*2
fin_VM_PCINC equ 2*2
fin_VM_PCINC_FZ equ 3*2
fin_VM_PCINC_FZ_LD_IX_E equ 4*2
fin_VM_PCINC_FZ_LD_IX_DE equ 5*2
fin_VM_PCINC_LD_IX_E equ 6*2
fin_VM_PCINC_LD_IX_DE equ 7*2

vm_PrepVectors:				;Subtract 1 - Zero is nothing
	dc.l VM_GetAddress_Branch 		;1 - Branches
	dc.l VM_GetAddressPrep			;2 - Basic
	dc.l VM_GetAddress_VM_GetFlagC	;3 - Get Carry Flag
	dc.l VM_GetAddressPrep16		;4 - Patch for 16 bit imm
	dc.l VM_GetAddressPrepZPDest	;5 - Patch for INC ZP
	dc.l VM_GetAddressPrepZPDest_GetFlagC ;6 patch for ROLz RORz
	
vm_FinVectors:				;Subtract 1 - Zero is nothing
	dc.l VM_PC_Store			;1 store PC
	dc.l VM_PCINC				;2 INC PC
	dc.l VM_PCINC_FZ			;3 store flags
	dc.l VM_PCINC_FZ_LD_IX_E	;4 store flags
	dc.l VM_PCINC_FZ_LD_IX_DE	;5 store flags and save 16 bit
	dc.l VM_PCINC_LD_IX_E 		;6 save
	dc.l VM_PCINC_LD_IX_DE 		;7 save 16 bit

vm_DecoderMatrix:
	dlba cmd_NOP,		0
	dlba cmd_PSH,		fin_VM_PCINC
	dlba cmd_PUL,		fin_VM_PCINC
	dlba cmd_PHF,		fin_VM_PCINC
	dlba cmd_BRA,		prp_VM_GetAddress_Branch+fin_VM_PC_Store
	dlba cmd_BSR,		prp_VM_GetAddress_Branch+fin_VM_PC_Store
	dlba cmd_BEQ,		prp_VM_GetAddress_Branch+fin_VM_PC_Store
	dlba cmd_BNE,		prp_VM_GetAddress_Branch+fin_VM_PC_Store
	dlba cmd_BCS,		prp_VM_GetAddress_Branch+fin_VM_PC_Store
	dlba cmd_BCC,		prp_VM_GetAddress_Branch+fin_VM_PC_Store
	dlba cmd_ADD,		prp_VM_GetAddress+fin_VM_PCINC_FZ_LD_IX_E
	dlba cmd_SUB,		prp_VM_GetAddress+fin_VM_PCINC_FZ_LD_IX_E
	dlba cmd_CMP,		prp_VM_GetAddress+fin_VM_PCINC_FZ
	dlba cmd_MOV,		prp_VM_GetAddress+fin_VM_PCINC_LD_IX_E
	dlba cmd_STO,		prp_VM_GetAddress+fin_VM_PCINC
	dlba cmd_LEA,		prp_VM_GetAddress+fin_VM_PCINC_LD_IX_DE
	dlba cmd_NEG,		prp_VM_GetAddressPrep_ZPDest+fin_VM_PCINC_FZ_LD_IX_E
	dlba cmd_ROL,		prp_VM_GetAddressPrep_ZPDest_GetFlagC+fin_VM_PCINC_FZ_LD_IX_E
	dlba cmd_ROR,		prp_VM_GetAddressPrep_ZPDest_GetFlagC+fin_VM_PCINC_FZ_LD_IX_E
	dlba cmd_ASL,		prp_VM_GetAddressPrep_ZPDest_GetFlagC+fin_VM_PCINC_FZ_LD_IX_E
	dlba cmd_ASR,		prp_VM_GetAddressPrep_ZPDest_GetFlagC+fin_VM_PCINC_FZ_LD_IX_E
	dlba cmd_LSR,		prp_VM_GetAddressPrep_ZPDest_GetFlagC+fin_VM_PCINC_FZ_LD_IX_E
	dlba cmd_INC,		prp_VM_GetAddressPrep_ZPDest+fin_VM_PCINC_FZ_LD_IX_E
	dlba cmd_DEC,		prp_VM_GetAddressPrep_ZPDest+fin_VM_PCINC_FZ_LD_IX_E
	dlba cmd_AND,		prp_VM_GetAddress+fin_VM_PCINC_FZ_LD_IX_E
	dlba cmd_ORR,		prp_VM_GetAddress+fin_VM_PCINC_FZ_LD_IX_E
	dlba cmd_XOR,		prp_VM_GetAddress+fin_VM_PCINC_FZ_LD_IX_E
	dlba cmd_TRP,		prp_VM_GetAddress+fin_VM_PC_Store
	dlba cmd_SYS,		prp_VM_GetAddress
	dlba cmd_MOV16,		prp_VM_GetAddress16+fin_VM_PCINC_LD_IX_DE
	
	dlba cmd_INC16,		prp_VM_GetAddressPrep_ZPDest+fin_VM_PCINC_LD_IX_DE
	dlba cmd_DEC16,		prp_VM_GetAddressPrep_ZPDest+fin_VM_PCINC_LD_IX_DE
	
	dlba cmd_ADD16,		prp_VM_GetAddress16+fin_VM_PCINC_FZ_LD_IX_DE
	dlba cmd_SUB16,		prp_VM_GetAddress16+fin_VM_PCINC_FZ_LD_IX_DE
	dlba cmd_SWP16,		prp_VM_GetAddress16+fin_VM_PCINC_LD_IX_DE
	dlba cmd_STO16,		prp_VM_GetAddress16+fin_VM_PCINC
	dlba cmd_BRA16,		prp_VM_GetAddress16+fin_VM_PC_Store	
	dlba cmd_BSR16,		prp_VM_GetAddress16+fin_VM_PC_Store	
	dlba cmd_TST,		prp_VM_GetAddress+fin_VM_PCINC_FZ
	dlba cmd_CMP16,		prp_VM_GetAddress+fin_VM_PCINC_FZ
	dlba cmd_CLR,		prp_VM_GetAddressPrep_ZPDest+fin_VM_PCINC_LD_IX_E
	dlba cmd_CLR,		prp_VM_GetAddressPrep_ZPDest+fin_VM_PCINC_LD_IX_DE
	dlba cmd_TOR,		prp_VM_GetAddress+fin_VM_PCINC_FZ
	dlba cmd_ADC,		prp_VM_GetAddress_VM_GetFlagC+fin_VM_PCINC_FZ_LD_IX_E
	dlba cmd_SBC,		prp_VM_GetAddress_VM_GetFlagC+fin_VM_PCINC_FZ_LD_IX_E
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Instruction Set

vm_NOP equ %00000000	;No-Operation
vm_RET equ %00000001	;Return from sub
vm_HLT equ %00000010	;Stop Processor
vm_SEC equ %00000011	;Set Carry

vm_PH0 equ %00000100
vm_PH2 equ %00000101
vm_PH4 equ %00000110
vm_PH6 equ %00000111

vm_PL0 equ %00001000
vm_PL2 equ %00001001
vm_PL4 equ %00001010
vm_PL6 equ %00001011

vm_PHF equ %00001100
vm_PLF equ %00001101

vm_BRA equ %00010000
vm_BSR equ %00010100
vm_BEQ equ %00011000
vm_BNE equ %00011100
vm_BCS equ %00100000
vm_BCC equ %00100100
vm_ADD equ %00101000
vm_SUB equ %00101100
vm_CMP equ %00110000
vm_MOV equ %00110100			;Move Param to Dest
vm_STO equ %00111000			;Store Dest To Param
vm_LEA equ %00111100			;Load Effective address
vm_NEG equ %01000000
vm_ROL equ %01000100			;Rotate with carry
vm_ROR equ %01001000
vm_ASL equ %01001100
vm_ASR equ %01010000
vm_LSR equ %01010100
vm_INC equ %01011000
vm_DEC equ %01011100
vm_AND equ %01100000
vm_ORR equ %01100100
vm_XOR equ %01101000
vm_TRP equ %01101100			;Trap #PARAM
vm_SYS equ %01110000			;Syscall #PARAM
vm_MOV16 equ %01110100
vm_INC16 equ %01111000
vm_DEC16 equ %01111100
vm_ADD16 equ %10000000
vm_SUB16 equ %10000100
vm_SWP16 equ %10001000			;Swap 2 16 bit values
vm_STO16 equ %10001100

vm_BRA16 equ %10010000			;Branch To 16 bit Relative offset PARAM
vm_BSR16 equ %10010100			;Branch To Sub 16 bit Relative offset PARAM
vm_TST   equ %10011000
vm_CMP16 equ %10011100

vm_CLR equ   %10100000
vm_CLR16 equ %10100100
vm_TOR equ   %10101000			;Test OR
vm_ADC equ   %10101100	
vm_SBC equ    %10110000	
;Reserved for future use!
;vm_CMD equ   %10110100			;Command switch
;vm_ADR equ   %10111000			;Address switch
;vm_CPU equ   %10111100			;Cpu switch
vm_LastComamnd equ %10110100

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Addressing Modes Branch:
 
vm_b2B equ 0 	;Branch PC+2 
vm_bI8 equ 1	;Branch PC+Imm8 (Signed relative)
vm_bI6 equ 2	;Branch PC+Imm16 (Absolute addr)
vm_bR6 equ 3	;Branch R6/R7 (Absolute addr in R6/7)

;Addressing Modes Command:

vm_aAB equ 0	;AB Accumulator
vm_aIM equ 1	;Immediate
vm_aZP equ 2	;ZeroPage
vm_aBP equ 3	;ByteParam  %PARAM/DEST

;Addressing Modes Parameter:

;Syntax is z80 style eg:
;XOR A,B		A is destination B is parameter

vm_pR0 equ 0	;Param R0
vm_pR1 equ 1	;Param R1
vm_pR2 equ 2	;Param R2
vm_pR3 equ 3	;Param R3
vm_pR4 equ 4	;Param R4
;vm_pR5 equ 5	;Param R5 - Not available use zeropage
vm_pR6 equ 5	;Param R6
;vm_pR7 equ 7	;Param R7 - Not available - use zeropage
vm_PB2 equ 6 	;Indirect 16 bit pointer R2 (16 bit to anywhere) - Base+imm8 offset
vm_PB4 equ 7 	;Indirect 16 bit pointer R4 (16 bit to anywhere) - Base+imm8 offset
vm_PU2 equ 8 	;Indirect 16 bit pointer R2 (16 bit to anywhere) - PostInc
vm_PU6 equ 9 	;Indirect 16 bit pointer R6 (16 bit to anywhere) - PostInc
vm_PQ4 equ 10 	;Indirect 16 bit pointer R4 (16 bit to anywhere)
vm_PQ6 equ 11 	;Indirect 16 bit pointer R6 (16 bit to anywhere)
vm_pA6 equ 12	;Address 16
vm_pA8 equ 13	;Address 8 (ZeroPage)
vm_pI6 equ 14	;Immediate 16 - Source only
vm_pI8 equ 15	;Immediate 8 - Source only

vm_pRF equ 15	;Flags Reg - Dest only
vm_pQS equ 14	;Indirect 16 bit pointer SP - Dest Only

;vm_PP2 equ 8 	;Indirect 8 bit pointer R0 (8 bit to zeropage)
;vm_PP3 equ 9 	;Indirect 8 bit pointer R2 (8 bit to zeropage)

vm_Ppr equ 16	;Parameter 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Friendly names

Param_R0 equ vm_pR0*vm_Ppr
Param_R1 equ vm_pR1*vm_Ppr
Param_R2 equ vm_pR2*vm_Ppr
Param_R3 equ vm_pR3*vm_Ppr
Param_R4 equ vm_pR4*vm_Ppr
Param_R6 equ vm_pR6*vm_Ppr
Param_Imm8 equ vm_pI8*vm_Ppr
Param_Imm16 equ vm_pI6*vm_Ppr
Param_Addr8 equ vm_pA8*vm_Ppr
Param_ZeroPg equ vm_pA8*vm_Ppr
Param_Addr16 equ vm_pA6*vm_Ppr
Param_AtR4 equ vm_PQ4*vm_Ppr
Param_AtR6 equ vm_PQ6*vm_Ppr
Param_AtR2Inc equ vm_PU2*vm_Ppr
Param_AtR6Inc equ vm_PU6*vm_Ppr
Param_AtR2PlusImm8 equ vm_PB2*vm_Ppr
Param_AtR4PlusImm8 equ vm_PB4*vm_Ppr


Dest_R0 equ vm_pR0
Dest_R1 equ vm_pR1
Dest_R2 equ vm_pR2
Dest_R3 equ vm_pR3
Dest_R4 equ vm_pR4
Dest_R6 equ vm_pR6
Dest_Addr8 equ vm_pA8
Dest_ZeroPg equ vm_pA8
Dest_Addr16 equ vm_pA6
Dest_AtR4 equ vm_PQ4
Dest_AtR6 equ vm_PQ6
Dest_AtR2Inc equ vm_PU2
Dest_AtR6Inc equ vm_PU6
Dest_AtR2PlusImm8 equ vm_PB2
Dest_AtR4PlusImm8 equ vm_PB4
Dest_RF equ vm_pRF			;rF
Dest_AtSP equ vm_pQS			;rStackTop



BranchPlus2 equ vm_b2B				;Skip 2 bytes (equivalent of BRAi 2)
BranchImm8 equ vm_bI8
BranchImm16 equ vm_bI6
BranchR6 equ vm_bR6

;Addressing Modes Command:

ParamAB equ vm_aAB					;AK=Dest BC=Param
ParamImm8 equ vm_aIM				;Param= Immediate 8 bit (16 bit for 16 bit commands)
;ParamAddr8 equ vm_aZP ;ZeroPage
ParamZeroPg equ vm_aZP ;ZeroPage	;Param in zero page (Dest for INC/DEC)
ParamExtByt equ vm_aBP ;ByteParam  %PARAM/DEST - Advanced Addressing 16 options for SRC DEST


; End of VM code



    ;IX = A5
	;IY = A6
		
VM_Tick:
	move.l (vm_rambaseAddr),a0
	move.l (vm_rambaseAddr),a3
	loadLEA0 vm_rpc,a3		;Load Little endian A3 from A0
							;(Program Counter)
	ifd vm_usevmem
		jsr vm_virmemgethlbytea
	else
		move.b (a3),d0		;Get A command from the Program
	endif
	clr.l d2
	move.b d0,d2			;D=Command
	and.l #%11111100,d0
	cmp.b #vm_lastcomamnd,d0
	bcc cmd_error			;Command not recognized


;Find the command in the decoder matrix	
	move.l d0,d4			;Command *4
	
	lsr.l #1,d4				;/2 (Command *2)
	add.l d0,d4				;D4=D0*6

	move.l #vm_decodermatrix,a4
	add.l d4,a4
	
;calculate our finisher
	move.b (4,a4),d0		;;%-pppfff-
	and.l #%00001110,d0
	beq vm_nofinish
	;sub.b #%00000010,d0
	asl.l #1,d0				;fff*4
	
	move.l #vm_finvectors-4,a3
	move.l (a3,d0),d0
	
	move.l d0,-(sp)			;Run this after the actual command
vm_nofinish:	


;Calculate our Comamnd Job
	move.l (0,a4),d0	
	move.l d0,-(sp)			;Run the actual command
	

;Calculate our Prep Job
	move.b (4,a4),d0
	and.l #%01110000,d0
	beq vm_noprep
	;sub.b #%00010000,d0
	lsr.l #2,d0				;ppp*4
	
	move.l #vm_prepvectors-4,a3
	move.l (a3,d0),d0
	move.l d0,-(sp)			;run this before the actual command
vm_noprep:


	move.l (VM_RamBaseAddr),a3
	move.l (VM_RamBaseAddr),a0
	loadLEA0 vm_rpc,a3		;A3=PC
	rts						;run the command list

	
cmd_error:
	move.l #vm_ferror,d0	;set error flag.
	jsr vm_setflaga
	jmp vm_pcinc			;skip unknown byte
	
	
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;command processors - push/pull has special rules


cmd_PHF:
	move.l #8,d0
	jsr cmd_Stack_GetRegA	;A6=stack pointer A5 points to reg A
	
	btst #0,d2
	bne cmd_PULtoIX	;cmd_plf2
	bra cmd_PSHfromIX ;jr cmd_phf2

cmd_PSH:
	jsr cmd_Stack_GetReg	;A6=stack pointer A5 points to reg D2
cmd_PSHfromIX:
	subq.l #2,a6		;Stack pointer -2
	loadLE a5,d5		;Load D5 from A5 in LE order
	move.l (VM_RamBaseAddr),a0
	storeLEa0 a6,vm_rsp	;Store Stack pointer
	;bra VM_LD_IY_DE	;D5 onto stack	

cmd_STO16:
VM_LD_IY_DE:	;Save 8 bit resuts, set flags and INC PC
	ifd vm_usevmem
		move.l a3,-(sp)
			jsr vm_virmemgetphysicaliy
			StoreLE d5,a3
		move.l (sp)+,a3
		rts
	else
		StoreLE d5,a6
		rts
	endif
	
cmd_STO:
VM_LD_IY_E:	;Save 8 bit resuts, set flags and INC PC
	ifd vm_usevmem
		move.l a3,-(sp)
			jsr vm_virmemgetphysicaliy
			move.b d5,(a3)
		move.l (sp)+,a3
	else
		move.b d5,(a6)
	endif
	rts
	
cmd_PUL:
	jsr cmd_Stack_GetReg	;A6=stack pointer A5 points to reg D2
cmd_PULtoIX:
	ifd vm_usevmem
		move.l a3,-(sp)
			jsr vm_virmemgetphysicaliy
			move.b (a3),d5
			addq.l #1,a3
			move.b (a3),d2
			
			jsr vm_virmemgetphysicalix
			move.b d5,(a3)
			addq.l #1,a3
			move.b d2,(a3)
			
		move.l (sp)+,a3
	else
		LoadLE a6,d5
		StoreLE d5,a5
	endif
	
	addq.l #2,a6				;inc iy
	
	move.l (VM_RamBaseAddr),a0
	storeLEa0 a6,vm_rsp
	rts

cmd_Stack_GetReg:		;Get D2
	move.b d2,d0
	and.l #%00000011,d0
	asl.l #1,d0

cmd_Stack_GetRegA:		;Get A
	move.l (VM_RamBaseAddr),a5
	add.l d0,a5						;A5 points to reg
	move.l (VM_RamBaseAddr),a6
	move.l (VM_RamBaseAddr),a0
	LoadLEA0 vm_rsp,a6				;A6 points to stack top
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;command processors - general commands

cmd_LEA:
	move.w a6,d5
	rts ;jp vm_pcinc_ld_ix_de

cmd_MOV:
	move.b d4,d5
	rts ;jp vm_pcinc_ld_ix_e

cmd_INC16:
	addq.w #1,d5
	rts ;jp vm_pcinc_fz_ld_ix_de

cmd_DEC16:
	subq.w #1,d5
	rts ;jr vm_pcinc_fz_ld_ix_de

cmd_ADD16:
	add.w d4,d5
	rts ;jr vm_pcinc_fz_ld_ix_de

cmd_SWP16:
	jsr VM_LD_IY_DE
cmd_MOV16:
	move.w d4,d5
	rts ;jp vm_pcinc_ld_ix_de
	
cmd_CLR:	
	clr.l d5
	rts
	
cmd_SBC:
	bcc cmd_SBC2
	addq.b #1,d4
cmd_SBC2:
	sub.b d4,d5
	rts

	
cmd_SUB16:
	sub.w d4,d5
	rts ;jp vm_pcinc_fz_ld_ix_de

cmd_ADC:
	bcc cmd_ADD
	addq.b #1,d4
cmd_ADD:
	add.b d4,d5
	rts ;jp vm_pcinc_fz_ld_ix_e

cmd_CMP16:
	cmp.w d4,d5
	rts

cmd_CMP: ;
cmd_SUB:	
	sub.b d4,d5
	rts ;jp vm_pcinc_fz_ld_ix_e

cmd_NEG:;
	neg.b d5
	rts ;jp vm_pcinc_fz_ld_ix_e

cmd_ROL: ;(F:CZ)
	roxl.b #1,d5
	rts ;jp vm_pcinc_fz_ld_ix_e

cmd_ROR: ;(F:CZ)
	roxr.b #1,d5
	rts ;jp vm_pcinc_fz_ld_ix_e

cmd_ASL: ;(F:CZ)
	asl.b #1,d5
	rts ;jp vm_pcinc_fz_ld_ix_e

cmd_ASR: ;(F:CZ)
	asr.b #1,d5
	rts ;jp vm_pcinc_fz_ld_ix_e

cmd_LSR: ;(F:CZ)
	lsr.b #1,d5
	rts ;jp vm_pcinc_fz_ld_ix_e

cmd_INC: ;(F:Z)
	addq.b #1,d5
	rts ;jp vm_pcinc_fz_ld_ix_e

cmd_DEC: ;(F:Z)
	subq.b #1,d5
	rts ;jp vm_pcinc_fz_ld_ix_e

cmd_TST:
cmd_AND: ;(F:Z)
	and.b d4,d5
	rts ;jp vm_pcinc_fz_ld_ix_e
	
cmd_TOR:
cmd_ORR: ;(F:Z)
	or.b d4,d5
	rts ;jp vm_pcinc_fz_ld_ix_e

cmd_XOR: ;(F:Z)
	eor.b d4,d5
	rts ;jp vm_pcinc_fz_ld_ix_e
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
; Finishing Routines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

	
VM_PCINC_LD_IX_DE:	;Save 16 bit results,  and INC PC
	ifd vm_usevmem
		move.l a3,-(sp)
			jsr vm_virmemgetphysicalix
			StoreLE d5,a3
		move.l (sp)+,a3
		bra vm_pcinc
	else
		StoreLE d5,a5
		bra vm_pcinc
	endif
	
VM_PCINC_LD_IX_E:	;Save 8 bit results, and INC PC
	ifd vm_usevmem
		move.l a3,-(sp)
			jsr vm_virmemgetphysicalix
			move.b d5,(a3)
		move.l (sp)+,a3
	else
		move.b d5,(a5)
	endif
	bra vm_pcinc

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	


VM_PCINC_FZ_LD_IX_DE:	;Save 16 bit results, set flags and INC PC
	jsr GetCCR			;D7=Flags
	ifd vm_usevmem
		movem.l d0/d7/a3,-(sp)
			jsr vm_virmemgetphysicalix
			StoreLE d5,a3
		movem.l (sp)+,d0/d7/a3
		bra vm_pcinc_fzb
	else
		StoreLE d5,a5
		bra vm_pcinc_fzb
	endif
	
	
VM_PCINC_FZ_LD_IX_E:	;Save 8 bit results, set flags and INC PC
	jsr GetCCR			;D7=Flags
	ifd vm_usevmem
		movem.l d0/d7/a3,-(sp)
			jsr vm_virmemgetphysicalix
			move.b d5,(a3)
		movem.l (sp)+,d0/d7/a3
	else
		move.b d5,(a5)
	endif
	bra vm_pcinc_fzb
	
	
VM_PCINC_FZ:			;Set flags and INC PC
	jsr GetCCR				;D7=Flags
vm_pcinc_fzb:
	move.l (VM_RamBaseAddr),a0
	bclr.b #0,(vm_rf,a0)
	move d7,ccr
	bcc vm_pcinc_ff2
	bset #0,(vm_rf,a0)		;-C
	
VM_PCINC_FF2:
	move.l (VM_RamBaseAddr),a0
	bclr.b #1,(vm_rf,a0)
	move d7,ccr
	bne vm_pcinc_ff3
	bset #1,(vm_rf,a0)		;Z-
VM_PCINC_FF3:


VM_PCINC:
	addq.l #1,a3			;PC++
	
VM_PC_Store:
	move.l (VM_RamBaseAddr),a0
	storeLEa0 a3,vm_rpc		;Store PC
vm_pc_nostore:
	rts
	
	
GetCCR:				;D7 %---X-Z-C = Flags %------ZC
	bne GetCCR_NZ
	bset #2,d7		;68000 Z flag
	bra GetCCR_B
GetCCR_NZ:	
	bclr #2,d7		;68000 Z flag
GetCCR_B:
	bclr #0,d7		;68000 C flag
	
	bcc GetCCR_NC
	bset #0,d7		;68000 C flag
GetCCR_NC:	
	
	bclr #4,d7		;68000 X flag
	
	roxl.l #1,d7
	roxr.l #1,d7	;Shift X flag into C
	bcc GetCCR_NX

	
	bset #4,d7		;68000 X flag
GetCCR_NX:	
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;command processors - these commands share the same 6 bit code 
;	addressing bits define which is the command
	
cmd_NOP:
	clr.l d0
	move.b d2,d0
	beq vm_pcinc		;NOP	   0

	subq.b #1,d0 		;cp vm_RET 1
	beq cmd_ret
						;cp vm_HLT 2
		
	subq.b #1,d0 		
	beq cmd_HLT
	
cmd_SEC:
	ORI #%00000001,CCR	;SEC 3 
	jmp VM_PCINC_FZ

	
	
cmd_HLT:
	move.b #vm_fhalt,d0		;Set Halt flag.
	jsr vm_setflaga

	jmp vm_pc_store

cmd_RET:					;Also called RTS
	move.l #vm_rpc,d0
	jsr cmd_stack_getrega
	jmp cmd_pultoix		;get back pc from stack
	

VM_SetFlagA:		;set bits in vm f to the cpu a to 
	move.l (VM_RamBaseAddr),a0
	or.b d0,(vm_rf,a0)
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;command processors - branch commands have special addressing

cmd_BEQ:
	btst #1,d0
	bne cmd_bra_true
	rts ;jp vm_pc_store

cmd_BNE:
	btst #1,d0
	beq cmd_bra_true
	rts ;jp vm_pc_store	

cmd_BCS:
	roxr #1,d0
	bcs cmd_bra_true
	rts ;jp vm_pc_store

cmd_BCC:
	roxr #1,d0
	bcc cmd_bra_true
	rts ;jp vm_pc_store	

cmd_bra_true:
	move.l a5,a3		;Set PC to DEST
	rts ;jr vm_pc_store
	
cmd_BRA16:
	addq.l #1,a3
	add.l d4,a3			;Add 16 bit offset to PC
	rts

cmd_BRA:
	move.l a5,a3		;Branch to DEST
	rts	;jp vm_pc_store

	
	
vm_GetVector:
	and.l #$FF,d4
	asl.l #2,d4			;*4
	move.l (a5,d4),d4
	rts

VM_CauseTrapFromOutsideVM:		;c=trap number
	move.l (VM_RamBaseAddr),a3
	move.l (VM_RamBaseAddr),a0
	loadLEA0 vm_rpc,a3
	subq.l #1,a3

cmd_TRP:				;D4=Trap Number
	addq.l #1,a3
	move.l (vm_trap_TableAddr),a5
	and.l #$FF,d4
	asl.l #1,d4			;*2
	add.l d4,a5
	
	move.l (VM_RamBaseAddr),d4
	move.b (1,a5),d0
	asl.l #8,d0
	move.b (0,a5),d0
	move.w d0,d4
	
	move.l d4,-(sp)		;Execute D4 on return
	jmp  cmd_call

cmd_SYS:				;D4=Syscall Number
	jsr vm_pcinc
	move.l #vm_syscalls,a5
	
	
	
	jsr vm_getvector	;D4= System call address
	move.l d4,-(sp)
	rts

cmd_BSR16:
	addq.l #1,a3
	move.l a3,a5
	add.l d4,a5			;Add 16 bit offset to PC

cmd_BSR:
	move.l a5,-(sp)

cmd_Call:
		jsr vm_pc_store
		move.l #vm_rpc,d0
		jsr cmd_stack_getrega
		jsr cmd_pshfromix	;push pc onto stack
	move.l (sp)+,a3
	rts ;jp vm_pc_store				;hl=new pc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Preparation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VM_GetAddressPrepZPDest_GetFlagC:
	jsr VM_GetAddressPrepZPDest		;Get a zeropage destination
	jmp VM_GetFlagC					;Get the flag C
	
VM_GetAddress_VM_GetFlagC:
	jsr vm_getaddressprep			;Get the address
	
VM_GetFlagC:						;Set the CPU C flag to the VM one
	move.l (VM_RamBaseAddr),a0
	move.b (vm_rf,a0),d0
	roxr.b d0						;Carry-> D0
	rts
	
	
VM_GetAddressPrep16:
	move.l d2,-(sp)
		jsr vm_getaddressprep
	move.l (sp)+,d0
	and.b #%00000011,d0
	subq.b #1,d0			;cp %00000001 (imm8 mode)
	bne lbl43438			
	addq.l #1,a3			;extra byte for imm16
lbl43438	
	rts

	
VM_GetAddressPrepZPDest:	;Patched for Zeropage dest (INC ZP / INC16)
	move.l d2,-(sp)
		jsr vm_getaddressprep
	move.l (sp)+,d0
	and.b #%00000011,d0		;zeropage?
	cmp.b #%00000010,d0
	bne lbl31757
	move.l a6,a5			;Move Param->Dest
	move.l d4,d5
lbl31757
	rts

	
VM_GetAddressPrep:
	move.l (VM_RamBaseAddr),a5		;Dest		R0
	move.l (VM_RamBaseAddr),a6		;Param2		R2
	addq.l #2,a6

	move.b d2,d0
	and.b #%00000011,d0
	beq lbl39573			;0=Accumulator Addressing
	jsr vm_getaddress
lbl39573
	ifd vm_usevmem
		move.l a3,-(sp)
			jsr vm_virmemgetphysicaliy
			LoadLE a3,d4	;D4=param (A6) / D5=dest (A5) / D2=command byte
			jsr vm_virmemgetphysicalix
			LoadLE a3,d5 	;D4=param (A6) / D5=dest (A5)
			
			move.b d2,d0
			and.b #%11111100,d0
		move.l (sp)+,a3
	else
		LoadLE a6,d4		;D4=param (A6) / D5=dest (A5) / D2=command byte
			
		move.b d2,d0
		and.b #%11111100,d0
		LoadLE a5,d5 		;D4=param (A6) / D5=dest (A5) / D0=command byte	
	endif
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Addressing mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VM_GetAddress_ByteAddr:	;Zeropage source
	ifd vm_usevmem
		jsr vm_virmemgethlbytea
	else
		move.b (a3),d0	;get a command from the program
	endif
	move.l a6,d7
	move.b d0,d7		;ld iyl,a
	move.l d7,a6		;IY= parameter in RAM
	rts

VM_GetAddress_IMM:		;8 bit immediate source (after HL / PC)
	move.l a3,a6
	rts
	
VM_GetAddress:		;A5=Dest A6=Param

	

	addq.l #1,a3		;We have a 1 byte parameter (imm / ZP)
	subq.b #1,d0 		;cp  %00000001
	beq vm_getaddress_imm
	subq.b #1,d0		;cp  %00000010
	beq vm_getaddress_byteaddr
	;cp  %00000011
	;jr z,VM_GetAddress_ByteParam
	
	
VM_GetAddress_ByteParam:		;Extended addressing modes
	ifd vm_usevmem
		jsr vm_virmemgethlbytea	
	else
		move.b (a3),d0	;Get A command from the Program
	endif
	move.b d0,d5
	move.l a5,d4		;ppppDDDD
	jsr VM_GetAddress_ByteParam2_Dest
	move.l d4,a5
	move.b d5,d0		;PPPP----
	
	
	
	lsr #4,d0
	move.l a6,d4		;----PPPP
	jsr VM_GetAddress_ByteParam2
	move.l d4,a6
	
	
	
	rts
	
	
	


		
;imm8 imm16 dest don't make sense for destination, here are some alternatives

VM_GetAddress_ByteParam2_Dest:
	and.L #%00001111,d0		;Param
	cmp.b #vm_prf,d0
	bne notvm_getaddress_rf
		move.b #vm_rf,d4		;VM_GetAddress_RF
		rts
notvm_getaddress_rf:
	cmp.b #vm_pqs,d0
	bne notVM_GetAddress_ByteParam_Indir16_RSP
		move.l (VM_RamBaseAddr),a0 ;VM_GetAddress_ByteParam_Indir16_RSP
		LoadLEA0 vm_rsp,d4
		rts
notVM_GetAddress_ByteParam_Indir16_RSP:	
	
	
VM_GetAddress_ByteParam2:
	and.l #%00001111,d0		;param
	move.b d0,d4
	cmp.b #vm_pr6,d0		;0-4=direct register
	bcs lbl65454			;ret c
	sub.l #5,d0				;vm_pR6
	asl.l #2,d0				;4 bytes per table entry

	move.l #vm_ParameterAddressingModes,a4
	move.l (a4,d0),d0
	move.l d0,-(sp)			;Subroutine address on stack / A3=PC
lbl65454	
	rts

	
VM_GetAddress_R6:
	move.b #6,d4			;R6 = Address
	rts

vm_getaddress_byteparam_imm8:
	addq.l #1,a3			
	move.l a3,d4			;Address of param
	rts
	
VM_GetAddress_ByteParam_Imm16:
	addq.l #1,a3
	move.l a3,d4			;Address of param
	addq.l #1,a3			;Skip 1 extra byte
	rts        
	


vm_getaddress_byteparam_immaddr8: ;Zero page addressing
	addq.l #1,a3
	ifd vm_usevmem
		jsr vm_virmemgethlbytea
		move.b d0,d4
	else
		move.b (a3),d4		;get 8 bit address
	endif
	rts

VM_GetAddress_ByteParam_ImmAddr16:
	
	ifd vm_usevmem
		addq.l #1,a3
		move.l a3,-(sp)
			jsr vm_virmemgetphysical
			LoadLE a3,d4
		move.l (sp)+,a3
		addq.l #1,a3
	else
		addq.l #1,a3
		LoadLE a3,d4	;Get 16 bit address 
		addq.l #1,a3
	endif
	
	;clr.l d2
	;clr.l d5
	;jsr monitor 
	
	rts
	
	
VM_GetAddress_ByteParam_Indir16_R4: ;Indirect register pair addressing 
	move.l (VM_RamBaseAddr),a0
	LoadLEA0 vm_rr4,d4			;R4/R5
	rts

VM_GetAddress_ByteParam_Indir16_R6:
	move.l (VM_RamBaseAddr),a0
	LoadLEA0 vm_rr6,d4			;R6/R7
	rts
	
	
VM_GetAddress_ByteParam_Indir16_R2_PostInc: ;@Rn+ postinc
	move.l (VM_RamBaseAddr),a0
	LoadLEA0 vm_rr2,d4
	move.l d4,d0
	addq.w #1,d0
	StoreLEA0 d0,vm_rr2
	rts

VM_GetAddress_ByteParam_Indir16_R6_PostInc:
	move.l (VM_RamBaseAddr),a0
	LoadLEA0 vm_rr6,d4
	move.l d4,d0
	addq.w #1,d0
	StoreLEA0 d0,vm_rr6
	rts
		

VM_GetAddress_ByteParam_Indir16_R2_BaseImm: ;(IX+n) type addressing
	addq.l #1,a3
	movem.l a3/d7,-(sp)
		jsr getsignextendedimm8		;D4=signed value from byte
		move.l (VM_RamBaseAddr),a0
		move.l a0,d7
		LoadLEA0 vm_rr2,d7
		add.l a0,d4
	movem.l (sp)+,a3/d7
	rts
	
VM_GetAddress_ByteParam_Indir16_R4_BaseImm:
	addq.l #1,a3
	movem.l a3/d7,-(sp)
		jsr getsignextendedimm8		;D4=signed value from byte
		move.l (VM_RamBaseAddr),a0
		move.l a0,d7
		LoadLEA0 vm_rr4,d7
		
		add.l d7,d4
		
	movem.l (sp)+,a3/d7
	rts

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Branch addressing
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
VM_GetAddress_Branch:
	addq.l #1,a3		;call VM_PCINC
	move.b d2,d0
	and.l #%00000011,d0		;cp vm_b2B ;0 ;Branch PC+2
	beq vm_getaddress_branch2
	
	subq.l #1,d0 			;cp vm_bi8 ;1 branch pc+imm8 (sined rel)
	beq vm_getaddress_branch8imm
	
	subq.l #1,d0			;cp vm_bi6 ;2 branch pc+imm16 (abs addr)
	beq vm_getaddress_branch16imm
	
;VM_GetAddress_BranchR6:
	move.l (VM_RamBaseAddr),a0
	loadLEA0 vm_rr6,a5			;Get R6->A5 (Branch Dest)
	bra vm_getaddress_branchgetf
	
VM_GetAddress_Branch16imm:
	ifd vm_usevmem
		move.l a3,-(sp)
			jsr vm_virmemgetphysical
			loadLE a3,a5
		move.l (sp)+,a3
		addq.l #2,a3
	else
		loadLE a3,a5			;Get 2 bytes from program
		addq.l #2,a3			;PC+=2
	endif
	bra vm_getaddress_branchgetf
	
VM_GetAddress_Branch8imm:
	jsr getsignextendedimm8	 	;D4= -128 to +127
	move.l a3,a5
	add.l d4,a5
	
vm_getaddress_branchgetf:		;Jump to IX
	move.l (VM_RamBaseAddr),a0
	move.b (vm_rf,a0),d0
	rts

VM_GetAddress_Branch2:			;Skip 2 bytes
	move.l a3,a5
	addq.l #2,a5
	bra vm_getaddress_branchgetf
	
GetSignExtendedImm8:	;D4=signed result
	clr.l d4
	ifd vm_usevmem
		jsr vm_virmemgethlbytea
		move.b d0,d4
	else
		move.b (a3),d4			;get a byte from the program
	endif
	addq.l #1,a3				;PC++
	btst #7,d4
	beq lbl49267
	or.l #$FFFFFF00,d4			;Sign Negative
lbl49267
	rts	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 	Virtual Memory addressing (optional)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
	ifd vm_usevmem
vm_VirMemGetHLByteA:
		move.l a3,-(sp)
			jsr vm_virmemgetphysical
			move.b (a3),d0
		move.l (sp)+,a3
		rts
		
vm_VirMemGetPhysicalIY:		;IY=A6
		move.l a6,a3
		bra vm_virmemgetphysical

vm_VirMemGetPhysicalIX:		;IX=A5
		move.l a5,a3
		
vm_virmemgetphysical:
		move.l a3,d0
		and.l #$C000,d0			;2 Bank Bits
		rol.l #4,d0
		rol.l #8,d0
		
		move.l (VM_RamBaseAddr),a0
		add.l #vm_rbank0,a0
		
		clr.l d7
		move.b (3,a0,d0),d7		;Get Little Endian 32 bit memory address
		asl.l #8,d7
		move.b (2,a0,d0),d7
		asl.l #8,d7
		move.b (1,a0,d0),d7
		asl.l #8,d7
		move.b (0,a0,d0),d7

		move.l a3,d0
		;and.l #$FFFF3FFF,d0			;For relative offset 
		and.l #$00003FFF,d0		;14 address bits
		add.l d7,d0
		
		move.l d0,a3	
	rts
	endif
	
	
