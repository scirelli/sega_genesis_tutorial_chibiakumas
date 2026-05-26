
	
	
	
	;LOAD MyAddress,d0
	macro LoadLEA0			;Load 16 bits in little endian order 
		move.l d0,-(sp)		;(A0+Offset,DestReg)
			move.l \2,d0
			clr.w d0
			move.b (1+\1,a0),d0
			lsl.w #8,d0
			move.b (0+\1,a0),d0
			move.l d0,\2
		move.l (sp)+,d0
	endm
	
	macro LoadLEia	;Load 16 bits in little endian order (Addr,DestReg)
		move.l d0,-(sp)
			move.l #\1,a0
			move.l \2,d0
			clr.w d0
			move.b (1,a0),d0
			lsl.w #8,d0
			move.b (0,a0),d0
			move.l d0,\2
		move.l (sp)+,d0
	endm
	macro StoreLEia
		move.l d0,-(sp)
			move.w \1,d0
			move.l #\2,a0
			move.b d0,(0,a0)
			lsr #8,d0
			move.b d0,(1,a0)
		move.l (sp)+,d0
	endm
	
	macro StoreLEA0
		move.l d0,-(sp)
			move.w \1,d0
			move.b d0,(0+\2,a0)
			lsr #8,d0
			move.b d0,(1+\2,a0)
		move.l (sp)+,d0
	endm
	
	;LOAD A3,D0
	macro LoadLE	;Load 16 bits in little endian order
		move.l d0,-(sp)
			move.l \2,d0
			clr.w d0
			move.b (1,\1),d0
			lsl.w #8,d0
			move.b (0,\1),d0
			move.l d0,\2
		move.l (sp)+,d0
	endm
	macro StoreLE
		move.l d0,-(sp)
			move.w \1,d0
			move.b d0,(0,\2)
			lsr #8,d0
			move.b d0,(1,\2)
		move.l (sp)+,d0
	endm

; Macros for as single line to define sequences of bytes and words
	macro dwle ;Define a Little Endian 16 bit word - if a 32 bit long is provided it is truncated
	
		dc.b (\1)&255
		dc.b ((\1)>>8)&255
	endm
	
	macro dlle ;Define a Little Endian 32 bit long
		dc.b (\1)&255
		dc.b ((\1)/$100)&255
		dc.b ((\1)/$10000)&255
		dc.b ((\1)/$1000000)&255
	endm
	
	macro dlba	
		;assert \p2<256,Byte Parameter is a word
		;assert \p3<1,Too many parameters
		;assert \p4<1,Too many parameters
		;dc.w \1
		dc.l \1		;Define Long
		dc.b \2		;Byte
		dc.b 0		;Aligned 
	endm
	macro dwb
		;assert \p2<256,Byte Parameter is a word
		;assert \p3<1,Too many parameters
		;assert \p4<1,Too many parameters
		;dc.w \1
		dwle \1
		dc.b \2
	endm
	macro dbw,p1,p2,p3,p4
		;assert \p1<256,Byte Parameter is a word
		;assert \p3<1,Too many parameters
		;assert \p4<1,Too many parameters
		dc.b \1
		dwle \2
	endm
	macro dbb,p1,p2,p3,p4
		;assert \p1<256,Byte Parameter is a word
		;assert \p2<256,Byte Parameter is a word
		;assert \p3<1,Too many parameters
		;assert \p4<1,Too many parameters
		dc.b \1,\2
	endm
		macro db,p1,p2,p3,p4
		;assert \p1<256,Byte Parameter is a word
		;assert \p2<256,Byte Parameter is a word
		;assert \p3<1,Too many parameters
		;assert \p4<1,Too many parameters
		dc.b \1
	endm
	macro dw,p1,p2,p3,p4
		;assert \p1<256,Byte Parameter is a word
		;assert \p2<256,Byte Parameter is a word
		;assert \p3<1,Too many parameters
		;assert \p4<1,Too many parameters
		dwle \1
	endm
	macro dww,p1,p2,p3,p4
		;assert \p1<256,Byte Parameter is a word
		;assert \p2<256,Byte Parameter is a word
		;assert \p3<1,Too many parameters
		;assert \p4<1,Too many parameters
		dwle \1
		dwle \2
	endm
	macro dwww,p1,p2,p3,p4
		;assert \p1<256,Byte Parameter is a word
		;assert \p2<256,Byte Parameter is a word
		;assert \p3<1,Too many parameters
		;assert \p4<1,Too many parameters
		dwle \1
		dwle \2
		dwle \3
	endm
		macro dwwww,p1,p2,p3,p4
		;assert \p1<256,Byte Parameter is a word
		;assert \p2<256,Byte Parameter is a word
		;assert \p3<1,Too many parameters
		;assert \p4<1,Too many parameters
		dwle \1
		dwle \2
		dwle \3
		dwle \4
	endm
	
	macro dbbw,p1,p2,p3,p4
		;assert \p1<256,Byte Parameter is a word
		;assert \p2<256,Byte Parameter is a word
		;assert \p4<1,Too many parameters
		dc.b \1,\2
		dwle \3
	endm
	
	macro dbbb,p1,p2,p3,p4
		;assert \p1<256,Byte Parameter is a word
		;assert \p2<256,Byte Parameter is a word
		;assert \p3<256,Byte Parameter is a word
		;assert \p4<1,Too many parameters
		dc.b \1,\2,\3
	endm
	
	macro dbwb,p1,p2,p3,p4
		;assert \p1<256,Byte Parameter is a word
		;assert \p3<256,Byte Parameter is a word
		;assert \p4<1,Too many parameters
		dc.b \1
		dwle \2
		dc.b \3
	endm
	macro dbww,p1,p2,p3,p4
		;assert \p1<256,Byte Parameter is a word
		;assert \p4<1,Too many parameters
		dc.b \1
		dwle \2
		dwle \3
	endm
	macro dbbww,p1,p2,p3,p4
		;assert \p1<256,Byte Parameter is a word
		;assert \p2<256,Byte Parameter is a word
		dc.b \1,\2
		dwle \3
		dwle \4
	endm
	macro dbbbw,p1,p2,p3,p4
		;assert \p1<256,Byte Parameter is a word
		;assert \p2<256,Byte Parameter is a word
		;assert \p3<256,Byte Parameter is a word
		dc.b \1,\2,\3
		dwle \4
	endm
	macro dbbwb,p1,p2,p3,p4
		;assert \p1<256,Byte Parameter is a word
		;assert \p2<256,Byte Parameter is a word
		;assert \p4<256,Byte Parameter is a word
		dc.b \1,\2
		dwle \3
		dc.b \4
	endm
	macro dbbbb,p1,p2,p3,p4
		;assert \p1<256,Byte Parameter is a word
		;assert \p2<256,Byte Parameter is a word
		;assert \p3<256,Byte Parameter is a word
		;assert \p4<256,Byte Parameter is a word
		dc.b \1,\2,\3,\4
	endm

	;9 params is the limit
	macro dw8,p1,p2,p3,p4,p5,p6,p7,p8
		;assert \p1<256,Byte Parameter is a word
		;assert \p2<256,Byte Parameter is a word
		;assert \p3<1,Too many parameters
		;assert \p4<1,Too many parameters
		dwle \1
		dwle \2
		dwle \3
		dwle \4
		dwle \5
		dwle \6
		dwle \7
		dwle \8
	endm
	
NOPb equ vm_NOP 	;No operation
RETb equ vm_RET 	;Return
RTSb equ vm_RET 	;Return
HLTb equ vm_HLT 	;Halt processor
SECb equ vm_SEC		;Set Carry
PH0b equ vm_PH0 	;Push R0+R1
PH2b equ vm_PH2 	;Push R2+R4
PH4b equ vm_PH4 	;Push R4+R5
PH6b equ vm_PH6 	;Push R6+R7
PL0b equ vm_PL0 	;Pull R0+R1
PL2b equ vm_PL2 	;Pull R2+R3
PL4b equ vm_PL4 	;Pull R4+R5
PL6b equ vm_PL6 	;Pull R6+R7
PHFb equ vm_PHF 	;Push F+FU
PLFb equ vm_PLF 	;Pull F+FU

;2 byte jump
BRA2 equ vm_BRA 	;EG db BRA2
BSR2 equ vm_BSR 
BEQ2 equ vm_BEQ 
BNE2 equ vm_BNE 
BCS2 equ vm_BCS 
BCC2 equ vm_BCC 

;immediate 8
BRAi equ vm_BRA+1	;EG DB BRAi,-32
BSRi equ vm_BSR+1
BEQi equ vm_BEQ+1
BNEi equ vm_BNE+1
BCSi equ vm_BCS+1
BCCi equ vm_BCC+1

;Immediate 16
BRAj equ vm_BRA+2	;EG DB Braj,$5000
BSRj equ vm_BSR+2
BEQj equ vm_BEQ+2
BNEj equ vm_BNE+2
BCSj equ vm_BCS+2
BCCj equ vm_BCC+2

;Immediate 16
JMPj equ vm_BRA+2	;EG DB JMPj,$5000
JSRj equ vm_BSR+2
JEQj equ vm_BEQ+2
JNEj equ vm_BNE+2
JCSj equ vm_BCS+2
JCCj equ vm_BCC+2


;R6
BRAh equ vm_BRA+3	;EG DB BRAh
BSRh equ vm_BSR+3
BEQh equ vm_BEQ+3
BNEh equ vm_BNE+3
BCSh equ vm_BCS+3
BCCh equ vm_BCC+3

;BC reg
ADDb equ vm_ADD 
SUBb equ vm_SUB 
CMPb equ vm_CMP 		;Sets flags like SUB
MOVb equ vm_MOV 		;Move Param to Dest
STOb equ vm_STO 		;Store Dest to address Param (opposite of MOV)
LEAb equ vm_LEA 		;Load Effective address to Dest
NEGb equ vm_NEG 
ROLb equ vm_ROL 		;Rotate with carry
RORb equ vm_ROR 
ASLb equ vm_ASL 
LSLb equ vm_ASL 
ASRb equ vm_ASR 
LSRb equ vm_LSR 
INCb equ vm_INC 
DECb equ vm_DEC 
ANDb equ vm_AND 
TSTb equ vm_TST 
ORRb equ vm_ORR 
XORb equ vm_XOR 
EORb equ vm_XOR 
TRPb equ vm_TRP 		;Execute Trap #param
SYSb equ vm_SYS 		;Execute Systemcall #param
CLRb equ vm_CLR
TORb equ vm_TOR
ADCb equ vm_ADC
SBCb equ vm_SBC

MOV16b equ vm_MOV16 	;Move Param to Dest
INC16b equ vm_INC16 
DEC16b equ vm_DEC16 
ADD16b equ vm_ADD16 
SUB16b equ vm_SUB16 	
SWP16b equ vm_SWP16 	;Swap 16 bit Dest and Param
STO16b equ vm_STO16 	;Store Dest to address Param (opposite of MOV16)
CMP16b equ vm_CMP16		;Sets flags like SUB
CLR16b equ vm_CLR16	
;Immediate 8/16
ADDi equ vm_ADD+1
SUBi equ vm_SUB+1 
CMPi equ vm_CMP+1
MOVi equ vm_MOV+1
;STOi equ vm_STO+1		;Commands don't make sense!
LEAi equ vm_LEA+1
;NEGi equ vm_NEG+1
;ROLi equ vm_ROL+1
;RORi equ vm_ROR+1
;ASLi equ vm_ASL+1
;ASRi equ vm_ASR+1
;LSRi equ vm_LSR+1
;INCi equ vm_INC+1		;Command doesn't make sense!
;DECi equ vm_DEC+1
ANDi equ vm_AND+1
TSTi equ vm_TST+1
ORRi equ vm_ORR+1
XORi equ vm_XOR+1
EORi equ vm_XOR+1
TRPi equ vm_TRP+1
SYSi equ vm_SYS+1
ADCi equ vm_ADC+1
SBCi equ vm_SBC+1

MOV16i equ vm_MOV16+1
INC16i equ vm_INC16+1
DEC16i equ vm_DEC16+1
ADD16i equ vm_ADD16+1
SUB16i equ vm_SUB16+1
SWP16i equ vm_SWP16+1
STO16i equ vm_STO16+1
CMP16i equ vm_CMP16+1		;Sets flags like SUB

BRA16i equ vm_BRA16+1	;Branch to relative imm16
BSR16i equ vm_BSR16+1	;Branch to sub at relative imm16

;Zeropage
ADDz equ vm_ADD+2
SUBz equ vm_SUB+2 
CMPz equ vm_CMP+2
MOVz equ vm_MOV+2
STOz equ vm_STO+2
LEAz equ vm_LEA+2
NEGz equ vm_NEG+2
ROLz equ vm_ROL+2
RORz equ vm_ROR+2
ASLz equ vm_ASL+2
LSLz equ vm_ASL+2
ASRz equ vm_ASR+2
LSRz equ vm_LSR+2
INCz equ vm_INC+2
DECz equ vm_DEC+2
ANDz equ vm_AND+2
TSTz equ vm_TST+2
ORRz equ vm_ORR+2
XORz equ vm_XOR+2
EORz equ vm_XOR+2
TRPz equ vm_TRP+2
SYSz equ vm_SYS+2
CLRz equ vm_CLR+2
TORz equ vm_TOR+2
ADCz equ vm_ADC+2
SBCz equ vm_SBC+2


MOV16z equ vm_MOV16+2
INC16z equ vm_INC16+2
DEC16z equ vm_DEC16+2
ADD16z equ vm_ADD16+2
SUB16z equ vm_SUB16+2
SWP16z equ vm_SWP16+2
STO16z equ vm_STO16+2
CMP16z equ vm_CMP16+2		;Sets flags like SUB
CLR16z equ vm_CLR16+2
;BRA16z equ vm_BRA16+2		;Possible but not recommended!
;BSR16z equ vm_BSR16+2

;Extended parameter byte (one from Multiplexed Parameters)
ADDx equ vm_ADD+3
SUBx equ vm_SUB+3 
CMPx equ vm_CMP+3
MOVx equ vm_MOV+3
STOx equ vm_STO+3
LEAx equ vm_LEA+3
NEGx equ vm_NEG+3
ROLx equ vm_ROL+3
RORx equ vm_ROR+3
LSLx equ vm_ASL+3
ASLx equ vm_ASL+3
ASRx equ vm_ASR+3
LSRx equ vm_LSR+3
INCx equ vm_INC+3
DECx equ vm_DEC+3
ANDx equ vm_AND+3
TSTx equ vm_TST+3
ORRx equ vm_ORR+3
XORx equ vm_XOR+3
EORx equ vm_XOR+3
TRPx equ vm_TRP+3
SYSx equ vm_SYS+3
CLRx equ vm_CLR+3
TORx equ vm_TOR+3
ADCx equ vm_ADC+3
SBCx equ vm_SBC+3

MOV16x equ vm_MOV16+3
INC16x equ vm_INC16+3
DEC16x equ vm_DEC16+3
ADD16x equ vm_ADD16+3
SUB16x equ vm_SUB16+3
SWP16x equ vm_SWP16+3
STO16x equ vm_STO16+3
CMP16x equ vm_CMP16+3		;Sets flags like SUB
CLR16x equ vm_CLR16+3
;BRA16x equ vm_BRA16+3	;Possible but not recommended
;BSR16x equ vm_BSR16+3

;Multiplexed Parameters (Dest,Param)
;Eg dbbww MOV16x,Addr16_imm16,&4200,&6660
;Moves imm16 &6660 to Addr16 &4200

R0_R0 equ Dest_R0+Param_R0		;Dest Reg 0
R1_R0 equ Dest_R1+Param_R0		;Dest Reg 1
R2_R0 equ Dest_R2+Param_R0		;Dest Reg 2
R3_R0 equ Dest_R3+Param_R0		;Dest Reg 3
R4_R0 equ Dest_R4+Param_R0		;Dest Reg 4 (4+5 for 16 bit)
R6_R0 equ Dest_R6+Param_R0		;Dest Reg 6 (6+7 for 16 bit)
;Addr8_R0 equ Dest_Addr8+Param_R0		;Superflouous, same as below
ZeroPg_R0 equ Dest_ZeroPg+Param_R0		;Dest ZeroPage address 	
Addr16_R0 equ Dest_Addr16+Param_R0		;Dest absolute 16 bit address
AtR4_R0 equ Dest_AtR4+Param_R0			;Dest address in R4
AtR6_R0 equ Dest_AtR6+Param_R0			;Dest address in R6
AtR2Inc_R0 equ Dest_AtR2Inc+Param_R0	;Dest address in R2 - Inc R2+1
AtR6Inc_R0 equ Dest_AtR6Inc+Param_R0	;Dest address in R6 - Inc R2+1
AtR2PlIm_R0 equ Dest_AtR2PlusImm8+Param_R0 ;Dest address in R2+imm8
AtR4PlIm_R0 equ Dest_AtR4PlusImm8+Param_R0	;Dest address in R4+imm8
RF_R0 equ Dest_RF+Param_R0					;Dest Flags reg
AtSP_R0 equ Dest_AtSP+Param_R0				;Dest Top item on stack

R0_R1 equ Dest_R0+Param_R1
R1_R1 equ Dest_R1+Param_R1
R2_R1 equ Dest_R2+Param_R1
R3_R1 equ Dest_R3+Param_R1
R4_R1 equ Dest_R4+Param_R1
R6_R1 equ Dest_R6+Param_R1
;Addr8_R1 equ Dest_Addr8+Param_R1
ZeroPg_R1 equ Dest_ZeroPg+Param_R1
Addr16_R1 equ Dest_Addr16+Param_R1
AtR4_R1 equ Dest_AtR4+Param_R1
AtR6_R1 equ Dest_AtR6+Param_R1
AtR2Inc_R1 equ Dest_AtR2Inc+Param_R1
AtR6Inc_R1 equ Dest_AtR6Inc+Param_R1
AtR2PlIm_R1 equ Dest_AtR2PlusImm8+Param_R1
AtR4PlIm_R1 equ Dest_AtR4PlusImm8+Param_R1
RF_R1 equ Dest_RF+Param_R1
AtSP_R1 equ Dest_AtSP+Param_R1

R0_R2 equ Dest_R0+Param_R2
R1_R2 equ Dest_R1+Param_R2
R2_R2 equ Dest_R2+Param_R2
R3_R2 equ Dest_R3+Param_R2
R4_R2 equ Dest_R4+Param_R2
R6_R2 equ Dest_R6+Param_R2
;Addr8_R2 equ Dest_Addr8+Param_R2
ZeroPg_R2 equ Dest_ZeroPg+Param_R2
Addr16_R2 equ Dest_Addr16+Param_R2
AtR4_R2 equ Dest_AtR4+Param_R2
AtR6_R2 equ Dest_AtR6+Param_R2
AtR2Inc_R2 equ Dest_AtR2Inc+Param_R2
AtR6Inc_R2 equ Dest_AtR6Inc+Param_R2
AtR2PlIm_R2 equ Dest_AtR2PlusImm8+Param_R2
AtR4PlIm_R2 equ Dest_AtR4PlusImm8+Param_R2
RF_R2 equ Dest_RF+Param_R2
AtSP_R2 equ Dest_AtSP+Param_R2

R0_R3 equ Dest_R0+Param_R3
R1_R3 equ Dest_R1+Param_R3
R2_R3 equ Dest_R2+Param_R3
R3_R3 equ Dest_R3+Param_R3
R4_R3 equ Dest_R4+Param_R3
R6_R3 equ Dest_R6+Param_R3
;Addr8_R3 equ Dest_Addr8+Param_R3
ZeroPg_R3 equ Dest_ZeroPg+Param_R3
Addr16_R3 equ Dest_Addr16+Param_R3
AtR4_R3 equ Dest_AtR4+Param_R3
AtR6_R3 equ Dest_AtR6+Param_R3
AtR2Inc_R3 equ Dest_AtR2Inc+Param_R3
AtR6Inc_R3 equ Dest_AtR6Inc+Param_R3
AtR2PlIm_R3 equ Dest_AtR2PlusImm8+Param_R3
AtR4PlIm_R3 equ Dest_AtR4PlusImm8+Param_R3
RF_R3 equ Dest_RF+Param_R3
AtSP_R3 equ Dest_AtSP+Param_R3

R0_R4 equ Dest_R0+Param_R4
R1_R4 equ Dest_R1+Param_R4
R2_R4 equ Dest_R2+Param_R4
R3_R4 equ Dest_R3+Param_R4
R4_R4 equ Dest_R4+Param_R4
R6_R4 equ Dest_R6+Param_R4
;Addr8_R4 equ Dest_Addr8+Param_R4
ZeroPg_R4 equ Dest_ZeroPg+Param_R4
Addr16_R4 equ Dest_Addr16+Param_R4
AtR4_R4 equ Dest_AtR4+Param_R4
AtR6_R4 equ Dest_AtR6+Param_R4
AtR2Inc_R4 equ Dest_AtR2Inc+Param_R4
AtR6Inc_R4 equ Dest_AtR6Inc+Param_R4
AtR2PlIm_R4 equ Dest_AtR2PlusImm8+Param_R4
AtR4PlIm_R4 equ Dest_AtR4PlusImm8+Param_R4
RF_R4 equ Dest_RF+Param_R4
AtSP_R4 equ Dest_AtSP+Param_R4

R0_R6 equ Dest_R0+Param_R6
R1_R6 equ Dest_R1+Param_R6
R2_R6 equ Dest_R2+Param_R6
R3_R6 equ Dest_R3+Param_R6
R4_R6 equ Dest_R4+Param_R6
R6_R6 equ Dest_R6+Param_R6
;Addr8_R6 equ Dest_Addr8+Param_R6
ZeroPg_R6 equ Dest_ZeroPg+Param_R6
Addr16_R6 equ Dest_Addr16+Param_R6
AtR4_R6 equ Dest_AtR4+Param_R6
AtR6_R6 equ Dest_AtR6+Param_R6
AtR2Inc_R6 equ Dest_AtR2Inc+Param_R6
AtR6Inc_R6 equ Dest_AtR6Inc+Param_R6
AtR2PlIm_R6 equ Dest_AtR2PlusImm8+Param_R6
AtR4PlIm_R6 equ Dest_AtR4PlusImm8+Param_R6
RF_R6 equ Dest_RF+Param_R6
AtSP_R6 equ Dest_AtSP+Param_R6

R0_imm8 equ Dest_R0+Param_Imm8
R1_imm8 equ Dest_R1+Param_Imm8
R2_imm8 equ Dest_R2+Param_Imm8
R3_imm8 equ Dest_R3+Param_Imm8
R4_imm8 equ Dest_R4+Param_Imm8
R6_imm8 equ Dest_R6+Param_Imm8
;Addr8_imm8 equ Dest_Addr8+Param_Imm8
ZeroPg_imm8 equ Dest_ZeroPg+Param_Imm8
Addr16_imm8 equ Dest_Addr16+Param_Imm8
AtR4_imm8 equ Dest_AtR4+Param_Imm8
AtR6_imm8 equ Dest_AtR6+Param_Imm8
AtR2Inc_imm8 equ Dest_AtR2Inc+Param_Imm8
AtR6Inc_imm8 equ Dest_AtR6Inc+Param_Imm8
AtR2PlIm_imm8 equ Dest_AtR2PlusImm8+Param_Imm8
AtR4PlIm_imm8 equ Dest_AtR4PlusImm8+Param_Imm8
RF_imm8 equ Dest_RF+Param_Imm8
AtSP_imm8 equ Dest_AtSP+Param_Imm8

R0_imm16 equ Dest_R0+Param_Imm16
R1_imm16 equ Dest_R1+Param_Imm16
R2_imm16 equ Dest_R2+Param_Imm16
R3_imm16 equ Dest_R3+Param_Imm16
R4_imm16 equ Dest_R4+Param_Imm16
R6_imm16 equ Dest_R6+Param_Imm16
;Addr8_imm16 equ Dest_Addr8+Param_Imm16
ZeroPg_imm16 equ Dest_ZeroPg+Param_Imm16
Addr16_imm16 equ Dest_Addr16+Param_Imm16
AtR4_imm16 equ Dest_AtR4+Param_Imm16
AtR6_imm16 equ Dest_AtR6+Param_Imm16
AtR2Inc_imm16 equ Dest_AtR2Inc+Param_Imm16
AtR6Inc_imm16 equ Dest_AtR6Inc+Param_Imm16
AtR2PlIm_imm16 equ Dest_AtR2PlusImm8+Param_Imm16
AtR4PlIm_imm16 equ Dest_AtR4PlusImm8+Param_Imm16
RF_imm16 equ Dest_RF+Param_Imm16
AtSP_imm16 equ Dest_AtSP+Param_Imm16

; R0_Addr8 equ Dest_R0+Param_Addr8
; R1_Addr8 equ Dest_R1+Param_Addr8
; R2_Addr8 equ Dest_R2+Param_Addr8
; R3_Addr8 equ Dest_R3+Param_Addr8
; R4_Addr8 equ Dest_R4+Param_Addr8
; R6_Addr8 equ Dest_R6+Param_Addr8
; Addr8_Addr8 equ Dest_Addr8+Param_Addr8
; ZeroPg_Addr8 equ Dest_ZeroPg+Param_Addr8
; Addr16_Addr8 equ Dest_Addr16+Param_Addr8
; AtR4_Addr8 equ Dest_AtR4+Param_Addr8
; AtR6_Addr8 equ Dest_AtR6+Param_Addr8
; AtR2Inc_Addr8 equ Dest_AtR2Inc+Param_Addr8
; AtR6Inc_Addr8 equ Dest_AtR6Inc+Param_Addr8
; AtR2PlIm_Addr8 equ Dest_AtR2PlusImm8+Param_Addr8
; AtR4PlIm_Addr8 equ Dest_AtR4PlusImm8+Param_Addr8
; RF_Addr8 equ Dest_RF+Param_Addr8
; AtSP_Addr8 equ Dest_AtSP+Param_Addr8

R0_ZeroPg equ Dest_R0+Param_ZeroPg
R1_ZeroPg equ Dest_R1+Param_ZeroPg
R2_ZeroPg equ Dest_R2+Param_ZeroPg
R3_ZeroPg equ Dest_R3+Param_ZeroPg
R4_ZeroPg equ Dest_R4+Param_ZeroPg
R6_ZeroPg equ Dest_R6+Param_ZeroPg
;Addr8_ZeroPg equ Dest_Addr8+Param_ZeroPg
ZeroPg_ZeroPg equ Dest_ZeroPg+Param_ZeroPg
Addr16_ZeroPg equ Dest_Addr16+Param_ZeroPg
AtR4_ZeroPg equ Dest_AtR4+Param_ZeroPg
AtR6_ZeroPg equ Dest_AtR6+Param_ZeroPg
AtR2Inc_ZeroPg equ Dest_AtR2Inc+Param_ZeroPg
AtR6Inc_ZeroPg equ Dest_AtR6Inc+Param_ZeroPg
AtR2PlIm_ZeroPg equ Dest_AtR2PlusImm8+Param_ZeroPg
AtR4PlIm_ZeroPg equ Dest_AtR4PlusImm8+Param_ZeroPg
RF_ZeroPg equ Dest_RF+Param_ZeroPg
AtSP_ZeroPg equ Dest_AtSP+Param_ZeroPg

R0_Addr16 equ Dest_R0+Param_Addr16
R1_Addr16 equ Dest_R1+Param_Addr16
R2_Addr16 equ Dest_R2+Param_Addr16
R3_Addr16 equ Dest_R3+Param_Addr16
R4_Addr16 equ Dest_R4+Param_Addr16
R6_Addr16 equ Dest_R6+Param_Addr16
;Addr8_Addr16 equ Dest_Addr8+Param_Addr16
ZeroPg_Addr16 equ Dest_ZeroPg+Param_Addr16
Addr16_Addr16 equ Dest_Addr16+Param_Addr16
AtR4_Addr16 equ Dest_AtR4+Param_Addr16
AtR6_Addr16 equ Dest_AtR6+Param_Addr16
AtR2Inc_Addr16 equ Dest_AtR2Inc+Param_Addr16
AtR6Inc_Addr16 equ Dest_AtR6Inc+Param_Addr16
AtR2PlIm_Addr16 equ Dest_AtR2PlusImm8+Param_Addr16
AtR4PlIm_Addr16 equ Dest_AtR4PlusImm8+Param_Addr16
RF_Addr16 equ Dest_RF+Param_Addr16
AtSP_Addr16 equ Dest_AtSP+Param_Addr16

R0_AtR4 equ Dest_R0+Param_AtR4
R1_AtR4 equ Dest_R1+Param_AtR4
R2_AtR4 equ Dest_R2+Param_AtR4
R3_AtR4 equ Dest_R3+Param_AtR4
R4_AtR4 equ Dest_R4+Param_AtR4
R6_AtR4 equ Dest_R6+Param_AtR4
;Addr8_AtR4 equ Dest_Addr8+Param_AtR4
ZeroPg_AtR4 equ Dest_ZeroPg+Param_AtR4
Addr16_AtR4 equ Dest_Addr16+Param_AtR4
AtR4_AtR4 equ Dest_AtR4+Param_AtR4
AtR6_AtR4 equ Dest_AtR6+Param_AtR4
AtR2Inc_AtR4 equ Dest_AtR2Inc+Param_AtR4
AtR6Inc_AtR4 equ Dest_AtR6Inc+Param_AtR4
AtR2PlIm_AtR4 equ Dest_AtR2PlusImm8+Param_AtR4
AtR4PlIm_AtR4 equ Dest_AtR4PlusImm8+Param_AtR4
RF_AtR4 equ Dest_RF+Param_AtR4
AtSP_AtR4 equ Dest_AtSP+Param_AtR4

R0_AtR6 equ Dest_R0+Param_AtR6
R1_AtR6 equ Dest_R1+Param_AtR6
R2_AtR6 equ Dest_R2+Param_AtR6
R3_AtR6 equ Dest_R3+Param_AtR6
R4_AtR6 equ Dest_R4+Param_AtR6
R6_AtR6 equ Dest_R6+Param_AtR6
;Addr8_AtR6 equ Dest_Addr8+Param_AtR6
ZeroPg_AtR6 equ Dest_ZeroPg+Param_AtR6
Addr16_AtR6 equ Dest_Addr16+Param_AtR6
AtR4_AtR6 equ Dest_AtR4+Param_AtR6
AtR6_AtR6 equ Dest_AtR6+Param_AtR6
AtR2Inc_AtR6 equ Dest_AtR2Inc+Param_AtR6
AtR6Inc_AtR6 equ Dest_AtR6Inc+Param_AtR6
AtR2PlIm_AtR6 equ Dest_AtR2PlusImm8+Param_AtR6
AtR4PlIm_AtR6 equ Dest_AtR4PlusImm8+Param_AtR6
RF_AtR6 equ Dest_RF+Param_AtR6
AtSP_AtR6 equ Dest_AtSP+Param_AtR6

R0_AtR2Inc equ Dest_R0+Param_AtR2Inc
R1_AtR2Inc equ Dest_R1+Param_AtR2Inc
R2_AtR2Inc equ Dest_R2+Param_AtR2Inc
R3_AtR2Inc equ Dest_R3+Param_AtR2Inc
R4_AtR2Inc equ Dest_R4+Param_AtR2Inc
R6_AtR2Inc equ Dest_R6+Param_AtR2Inc
;Addr8_AtR2Inc equ Dest_Addr8+Param_AtR2Inc
ZeroPg_AtR2Inc equ Dest_ZeroPg+Param_AtR2Inc
Addr16_AtR2Inc equ Dest_Addr16+Param_AtR2Inc
AtR4_AtR2Inc equ Dest_AtR4+Param_AtR2Inc
AtR6_AtR2Inc equ Dest_AtR6+Param_AtR2Inc
AtR2Inc_AtR2Inc equ Dest_AtR2Inc+Param_AtR2Inc
AtR6Inc_AtR2Inc equ Dest_AtR6Inc+Param_AtR2Inc
AtR2PlIm_AtR2Inc equ Dest_AtR2PlusImm8+Param_AtR2Inc
AtR4PlIm_AtR2Inc equ Dest_AtR4PlusImm8+Param_AtR2Inc
RF_AtR2Inc equ Dest_RF+Param_AtR2Inc
AtSP_AtR2Inc equ Dest_AtSP+Param_AtR2Inc

R0_AtR6Inc equ Dest_R0+Param_AtR6Inc
R1_AtR6Inc equ Dest_R1+Param_AtR6Inc
R2_AtR6Inc equ Dest_R2+Param_AtR6Inc
R3_AtR6Inc equ Dest_R3+Param_AtR6Inc
R4_AtR6Inc equ Dest_R4+Param_AtR6Inc
R6_AtR6Inc equ Dest_R6+Param_AtR6Inc
;Addr8_AtR6Inc equ Dest_Addr8+Param_AtR6Inc
ZeroPg_AtR6Inc equ Dest_ZeroPg+Param_AtR6Inc
Addr16_AtR6Inc equ Dest_Addr16+Param_AtR6Inc
AtR4_AtR6Inc equ Dest_AtR4+Param_AtR6Inc
AtR6_AtR6Inc equ Dest_AtR6+Param_AtR6Inc
AtR2Inc_AtR6Inc equ Dest_AtR2Inc+Param_AtR6Inc
AtR6Inc_AtR6Inc equ Dest_AtR6Inc+Param_AtR6Inc
AtR2PlIm_AtR6Inc equ Dest_AtR2PlusImm8+Param_AtR6Inc
AtR4PlIm_AtR6Inc equ Dest_AtR4PlusImm8+Param_AtR6Inc
RF_AtR6Inc equ Dest_RF+Param_AtR6Inc
AtSP_AtR6Inc equ Dest_AtSP+Param_AtR6Inc

R0_AtR2PlIm equ Dest_R0+Param_AtR2PlusImm8
R1_AtR2PlIm equ Dest_R1+Param_AtR2PlusImm8
R2_AtR2PlIm equ Dest_R2+Param_AtR2PlusImm8
R3_AtR2PlIm equ Dest_R3+Param_AtR2PlusImm8
R4_AtR2PlIm equ Dest_R4+Param_AtR2PlusImm8
R6_AtR2PlIm equ Dest_R6+Param_AtR2PlusImm8
;Addr8_AtR2PlIm equ Dest_Addr8+Param_AtR2PlusImm8
ZeroPg_AtR2PlIm equ Dest_ZeroPg+Param_AtR2PlusImm8
Addr16_AtR2PlIm equ Dest_Addr16+Param_AtR2PlusImm8
AtR4_AtR2PlIm equ Dest_AtR4+Param_AtR2PlusImm8
AtR6_AtR2PlIm equ Dest_AtR6+Param_AtR2PlusImm8
AtR2Inc_AtR2PlIm equ Dest_AtR2Inc+Param_AtR2PlusImm8
AtR6Inc_AtR2PlIm equ Dest_AtR6Inc+Param_AtR2PlusImm8
AtR2PlIm_AtR2PlIm equ Dest_AtR2PlusImm8+Param_AtR2PlusImm8
AtR4PlIm_AtR2PlIm equ Dest_AtR4PlusImm8+Param_AtR2PlusImm8
RF_AtR2PlIm equ Dest_RF+Param_AtR2PlusImm8
AtSP_AtR2PlIm equ Dest_AtSP+Param_AtR2PlusImm8

R0_AtR4PlIm equ Dest_R0+Param_AtR4PlusImm8
R1_AtR4PlIm equ Dest_R1+Param_AtR4PlusImm8
R2_AtR4PlIm equ Dest_R2+Param_AtR4PlusImm8
R3_AtR4PlIm equ Dest_R3+Param_AtR4PlusImm8
R4_AtR4PlIm equ Dest_R4+Param_AtR4PlusImm8
R6_AtR4PlIm equ Dest_R6+Param_AtR4PlusImm8
;Addr8_AtR4PlIm equ Dest_Addr8+Param_AtR4PlusImm8
ZeroPg_AtR4PlIm equ Dest_ZeroPg+Param_AtR4PlusImm8
Addr16_AtR4PlIm equ Dest_Addr16+Param_AtR4PlusImm8
AtR4_AtR4PlIm equ Dest_AtR4+Param_AtR4PlusImm8
AtR6_AtR4PlIm equ Dest_AtR6+Param_AtR4PlusImm8
AtR2Inc_AtR4PlIm equ Dest_AtR2Inc+Param_AtR4PlusImm8
AtR6Inc_AtR4PlIm equ Dest_AtR6Inc+Param_AtR4PlusImm8
AtR2PlIm_AtR4PlIm equ Dest_AtR2PlusImm8+Param_AtR4PlusImm8
AtR4PlIm_AtR4PlIm equ Dest_AtR4PlusImm8+Param_AtR4PlusImm8
RF_AtR4PlIm equ Dest_RF+Param_AtR4PlusImm8
AtSP_AtR4PlIm equ Dest_AtSP+Param_AtR4PlusImm8






