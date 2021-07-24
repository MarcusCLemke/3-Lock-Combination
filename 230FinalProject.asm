;Marcus Lemke, Gianni Vaiente, Eric R.
;Final Project CSC230
    ;This program is a 3 tiered sequence detector:
    ;It traverses through each state via correct user input
    ;Each state is composed of 3 sub states, meaning each state detects a 3 input sequence.
    ;A light will turn off letting you know youve successfully moved through a state.
    ;Once all 3 state indication lights are turned off it will enter the FINAL STATE
    ;The final state is one of shock and awe, it features a beautiful pulse width modulation
    ;The program will stay in the final state until the user pressed the interrupt button.
    ;The interrupt just restarts the program from the top.
    
#include "p16f18875.inc" 

; CONFIG1 
; __config 0xFFFF 
 __CONFIG _CONFIG1, _FEXTOSC_ECH & _RSTOSC_EXT1X & _CLKOUTEN_OFF & _CSWEN_ON & _FCMEN_ON 
; CONFIG2 
; __config 0xFFFF 
 __CONFIG _CONFIG2, _MCLRE_ON & _PWRTE_OFF & _LPBOREN_OFF & _BOREN_ON & _BORV_LO & _ZCD_OFF & _PPS1WAY_ON & _STVREN_ON 
; CONFIG3 
; __config 0xFF9F 
 __CONFIG _CONFIG3, _WDTCPS_WDTCPS_31 & _WDTE_OFF & _WDTCWS_WDTCWS_7 & _WDTCCS_SC 
; CONFIG4 
; __config 0xFFFF 
 __CONFIG _CONFIG4, _WRT_OFF & _SCANE_available & _LVP_ON 
; CONFIG5 
; __config 0xFFFF 
 __CONFIG _CONFIG5, _CP_OFF & _CPD_OFF 
 
; Variables and Constants
   udata       ; udata
i	          res 1       ;outer loop counter
j	          res 1       ;inner loop counter
oncounter	  res 1	      ;inner loop counter
offcounter	  res 1	      ;inner inner loop
redo	          res 1	      ;Counter for PWN in final state
temp	          res 1	      ;address 0x70
magicbit          res 1	      ;the magic bit, used in PWM to determine on and off counters
W_TEMP	          res 1	      ;used to store W value during interrupt.

;=================Initialiaze an array of states used in PWM====================
  cblock 0x50
    State1
    State2
    State3
    State4
    State5
    State6
    State7
 endc
   
    org	    0x0000 
    goto    Start  ;Skip the interrupt code and go to top of program.
     
    
;=======================Interrupt method========================================
    org	  0x0004	    ;This is where PC points on an interrupt
    movwf     W_TEMP 	    ;Store the value of w temporarily
    banksel   PIR0
    bcf       PIR0,0x00     ;We need to clear this flag to enable
    goto      Start;	    ;Go to top of program, reset.
    movfw     W_TEMP 	    ;Restore w to the value before the interrupt
    retfie 		    ;Come out of the interrupt routine 

;===============================================================================
; Program begins here

Start
;Setting up clock at 1Mhz
     banksel OSCFRQ     ;Select bank  
     movlw b'00000000'  ;1 Mhz clock  
     movwf   OSCFRQ     ;Load new clock
     
;Initialize pointer for indirrect addressing.     
 banksel  	0	     ;Selecting bank 0
 clrf		FSR0	     ;Clearing file select register
 clrf		INDF0	     ;Clearing Indirrect addressing register

 ;Initialize array of states for the PWM in final state and storing values in memory.
 movlw		b'0001'	    
 movwf		State1
 movlw		b'0010'
 movwf		State2
 movlw		b'0100'
 movwf		State3
 movlw		b'0011'
 movwf		State4
 movlw		b'0101'
 movwf		State5
 movlw		b'0110'
 movwf		State6
 movlw		b'0111'
 movwf		State7

 ;===============Setting up everything to enable interrupts=====================
    banksel	INTCON		     ;Selecting inton bank
    bsf		INTCON, 7 	     ;GIE - Global interrupt enable (1=enable)
    bsf		INTCON, 6	     ;PEIE - Peripheral Interupt Enable (1-enable)
    bsf		INTCON, 1	     ;INTEDG - Rising Edge
    
    banksel	PIE0		    
    bsf		PIE0, 0		;Enable periferal interrupts
    banksel	ANSELB		;Select bank 
    clrf  	ANSELB		;Setting all B pins to digital.
    banksel	TRISB		;Select bank
    clrf	TRISB		;Setting all B pins to output.
    bsf		TRISB, 0	;Setting RB0 to an input
    banksel	PORTB		;Select bank
    clrf	PORTB		;Clearing port B
   
 ;====================Configuring input and output pins=========================
     banksel	    PORTC
     bsf  	    PORTC,0	    ;Setting RC0
     bsf	    PORTC,1	    ;Setting RC1 
     bsf	    PORTC,2	    ;Setting RC2
     banksel	    ANSELC	    ;select bank for ANSELC
     clrf	    ANSELC	    ;clear all of ANSELC so we are going digital
     banksel	    ANSELA	    ;select bank for ANSELA
     clrf	    ANSELA	    ;clear all of ANSELA so we are going digital
     banksel	    TRISA	    ;select bank for TRISA
     clrf	    TRISA	    ;set all digital output
     banksel	    LATA	    ;Selecting LATA
     clrf	    LATA	    ;Clearing the output stream   
     banksel	    TRISB	    ;Select bank
     bsf  	    TRISB, 0	    ;Enable input on RB0(Lets do it again to make sure)
;===============================================================================
			
		    ;All setup complete, program begins here.
MAIN  
		    
STATE_1
    movlw	b'0111000'  ;Loading binary value into working reg.
    movwf	LATA	    ;Turning on the 3 leds (Sets RA3 RA4 RA5 HIGH)
    call 	DELAY	    ;Delay before moving into a sub state.
SUB_A
     btfss  PORTC, 1	    ;Checking if RC1 is 1 (Button pressed), skip next when pressed
     goto   SUB_A	    ;Stay inside state A until RC1 is pressed
     call   WAITLOOP	    ;Calling wait loop
     goto   SUB_B	    ;Check next input
SUB_B
     btfss  PORTC, 0	    ;Checking if RC0 is 1 (Button pressed), skip next when pressed
     goto   SUB_B	    ;Stay inside state B until RC0 is pressed
     call   WAITLOOP	    ;Waiitng until button is released before executing next line.
     goto   SUB_C	    ;Check next input
SUB_C
     btfss  PORTC, 2	    ;Checking if RC2 is 1 (Button pressed), skip next when pressed.
     goto   SUB_C	    ;Stay inside state C until RC2 is pressed
     call   WAITLOOP	    ;Call wait loop
     goto   STATE_2	    ;Advance to next Main State

STATE_2
    movlw   b'00011000'	    ;Loading new binary value into working reg.
    movwf   LATA	    ;Passing value from wreg to LATA, RA5 is no longer set high
    call    DELAY	    ;Calling the delay to have program wait before moving to substates.
	
SUB_D
     btfss  PORTC, 0	    ;Checking if RC0 is 1 (Button pressed), skip next when pressed
     goto   SUB_D	    ;Stay inside state D until RC0 is pressed.
     call   WAITLOOP	    ;Call wait loop
     goto   SUB_E	    ;Advance to next state
SUB_E
     btfss  PORTC, 1	    ;Checking if RC1 is 1 (Button pressed), skip next when pressed
     goto   SUB_E	    ;Stay inside state E until RC1 is pressed
     call   WAITLOOP	    ;Call wait loop
     goto   SUB_F	    ;Advance to next state
SUB_F
     btfss  PORTC, 2	    ;Checking if RC2 is 1 (Button pressed), skip next when pressed
     goto   SUB_F	    ;Stay inside state F until RC2 is pressed
     call   WAITLOOP	    ;Call wait loop
     goto   STATE_3	    ;Advance to next Main State

STATE_3
	movlw	b'00001000' ;Moving binary value into working reg
	movwf	LATA	    ;Updating LATA to only have RC3 turned on
	call 	DELAY	    ;Calling delay method
SUB_G
     btfss  PORTC, 2	    ;Checking if RC2 is 1 (Button pressed), skip next when pressed
     goto   SUB_G	    ;Stay inside state G until RC2 is pressed
     call   WAITLOOP	    ;Calling wait loop
     goto   SUB_H	    ;Check next input
SUB_H
     btfss  PORTC, 1	    ;Checking if RC1 is 1 (Button pressed), skip next when pressed
     goto   SUB_H	    ;Stay inside state H until RC1 is pressed
     call   WAITLOOP	    ;Calling wait loop
     goto   SUB_I	    ;Check next input
SUB_I
     btfss  PORTC, 0	    ;Checking if RC0 is 1 (Button pressed), skip next when pressed
     goto   SUB_I	    ;Stay inside state I until RC0 is pressed
     call   WAITLOOP	    ;Call wait loop
     goto   FINAL_STATE	    ;Advance to Final State

     
     ;At this point RA3-5 should all be turned off and the multi-colored led will begin PWM
FINAL_STATE
     movlw	0x07	    ;Moving literal into working register
     movwf	redo	    ;Initializing redo variable, keeps track of how many states are reached.
TOP 
     movlw	0x50	    ;Loading address of array into working register.
     movwf	FSR0	    ;Initializes pointer to start at beginning of array of states
     
     ;INIT prepares the fade out of the PWM
INIT 
     movlb	    0		    ;put a zero in W so we can clear our counters
     clrf	    magicbit	    ;clear delay loop counter
     movlw	    0xE0	    ;Moving value into wReg for OnCounter variable   
     movwf	    oncounter	    ;Assign value to ONCounter
     movlw	    0x01	    ;Moving value into wReg for OffCounter variable
     movwf	    offcounter	    ;Assign value to OFFCounter
     clrw   
FINALOOP1
     movfw	    oncounter	    ;moving oncounter value into the working register
     movwf	    magicbit	    ;moving the working register value into i
     call	    DELAY_FINAL	    ;calling delay method
     clrf	    LATA	    ;Clearing LATA
     movfw	    offcounter	    ;moving off counter into working reg
     movwf	    magicbit	    ;setting offcounter to new delay value
     call	    DELAY_FINAL	    ;calling delay
     call	    UPDATE	    ;Update method to turn on the light
     
     ;code from line 211 - 225 is repeated code used to slow down the PWM
     movfw	    oncounter	    
     movwf	    magicbit
     call	    DELAY_FINAL
     clrf	    LATA
     movfw	    offcounter
     movwf	    magicbit
     call 	    DELAY_FINAL
     call	    UPDATE
     movfw	    oncounter
     movwf	    magicbit
     call	    DELAY_FINAL
     clrf	    LATA
     movfw	    offcounter
     movwf	    magicbit
     call	    DELAY_FINAL
     ;end of duplicated block of code
     
     incfsz	    offcounter	    ;increment the offcounter variable, skip next line if it is 0
     decfsz	    oncounter	    ;increment the oncounter variable, skip next line if it is 0
     goto	    FINALOOP1	    ;return to the top of the loop
     movlw	    0x01	    ;Moving 0x1 into wReg
     addwf	    FSR0	    ;Adding 1 to the pointer address to select next state (Updates color)
     call	    LIMIT	    ;Calling limit method
     goto	    INIT2	    ;Moving to INIT2 label
      
     ;Init 2 is responsible for fading IN the light.
INIT2
     movlb	0		    ;put a zero in W so we can clear our counters
     clrf	magicbit	    ;clear delay loop counter
     movlw	0x01		    ;Mocing value to set into onCounter into wReg
     movwf	oncounter	    ;Moving 0x1 into oncounter
     movlw	0xE0		    ;Moving value to set into OFFcounter into wReg
     movwf	offcounter	    ;Setting 0xE0 to offcounter variable.
     clrw
     
     
FINALOOP2
     movfw	    oncounter	    ;moving oncounter value into the working register
     movwf	    magicbit	    ;moving the working register value into i
     call	    DELAY_FINAL	    ;calling delay method
     clrf	    LATA	    ;Clearing LATA
     movfw	    offcounter	    ;Moving offcounter into wReg
     movwf	    magicbit	    ;Updating delay counter
     call	    DELAY_FINAL	    ;calling delay method
     call	    UPDATE	    ;Calling update method.
     
     ;Code from line 258 - 272 is duplicated code to slow down rate of PWM
     movfw	    oncounter
     movwf	    magicbit
     call	    DELAY_FINAL
     clrf	    LATA
     movfw	    offcounter
     movwf	    magicbit
     call 	    DELAY_FINAL
     call	    UPDATE
     movfw	    oncounter
     movwf	    magicbit
     call	    DELAY_FINAL
     clrf	    LATA
     movfw	    offcounter
     movwf	    magicbit
     call 	    DELAY_FINAL
     ;End of duplicated code block
     
     incfsz	    oncounter	    ;increment the offcounter variable, skip next line if it is 0
     decfsz	    offcounter	    ;increment the oncounter variable, skip next line if it is 0
     goto	    FINALOOP2	    ;return to the top of the FINALOOP2
     goto	    INIT	    ;Go to top of the PWM code.
	
;Delay method to make timing work	
DELAY    
     decfsz    j, F           ; Decrement and skip next instruction on 0    
     goto      DELAY          ; Delay loop    
     decfsz    i, F           ; Decrement and skip next instruction on 0    
     goto      DELAY          ; Delay loop    
     return	
 
;Wait loop implemented to keep input from buttons from streaming high values.
WAITLOOP
     btfsc  PORTC, 1	;Checking if PORTC is 0 (Button released), skip when released
     goto   WAITLOOP	;Stay inside wait loop
     btfsc  PORTC, 0	;Checking if PORTC is 0 (Button released), skip when released
     goto   WAITLOOP	;Stay inside wait loop
     btfsc  PORTC, 2	;Checking if PORTC is 0 (Button released), skip when released
     goto   WAITLOOP	;Stay inside wait loop
     return

;Update method implemented to move pointer through array of states for PWM
UPDATE
     movfw	INDF0	    ;Moving value from INDF0 into working register
     movwf	LATA	    ;Updating the state of the PWM
     return		    ;Return to function call
;Limit method to prevent program from looping past the defined states.
LIMIT
     decfsz	redo	    ;decrement redo variable, at 0 skip the next instruction
     return		    ;return to address function was called from.
     goto	RESTART	    ;if redo == 0 , go to restart method.
     return		    ;return to addredd fucntion was called from.
;Restart method to reset the states of PWM in while in final state.     
RESTART
     movlw	0x07	    ;Moving 0x07 into working register
     movwf	redo	    ;Setting redo to 0x07
     movlw	0x50	    ;Moving 0x50 into working register
     movwf	FSR0	    ;Setting pointer to 0x50
     return		    ;return
;Delay method implemented during the PWM for the final state.   
DELAY_FINAL
    decfsz	magicbit	    ;decrement the magicbit counter until it is 0
    goto        DELAY_FINAL	    ;stay inside the delay until this line is skipped
    return			    ;return to address function was called from.
   
    END	
    ;Ps. It never ends....

