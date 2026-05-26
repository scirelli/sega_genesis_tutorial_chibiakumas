;Extended functions to improve the Adventure Engine, and reduce
; CPU load from ChibiVM

syscallAdvInput equ 13

aiGetString equ 0;+regRR
aiGetChar equ 1
aiGetKey equ 2;+regWW
aiWaitForKey equ 3;+regWW
aiWaitForKeyRelease equ 4;+regNO

vecAdvInpCall:
	dc.l GetString			;0
	dc.l GetChar
	dc.l Keyboard_GetKey
	dc.l Keyboard_WaitForKey
	dc.l Keyboard_WaitForRelease
	
AdvInpLast equ 1

AdvInput_Call:	

	
	
	move.l #vecAdvInpCall,a6
	jmp ChibiVM_VectorCall
	
