
; CC5X Version 3.1C, Copyright (c) B Knudsen Data
; C compiler for the PICmicro family
; ************  14. Sep 2001   0:26  *************

	processor  16F84
	radix  DEC

TMR0        EQU   0x01
OPTION_REG  EQU   0x81
PORTB       EQU   0x06
TRISB       EQU   0x86
Carry       EQU   0
Zero_       EQU   2
RP0         EQU   5
T0IF        EQU   2
RTIE        EQU   5
GIE         EQU   7
RB0         EQU   0
RB1         EQU   1
RB2         EQU   2
RB3         EQU   3
RB4         EQU   4
RB5         EQU   5
irState     EQU   0x0C
irData      EQU   0x0D
irOnCount   EQU   0x0F
irOffCount  EQU   0x10
remoteCode  EQU   0x11
irTemp      EQU   0x12
dimState    EQU   0x14
dimValue    EQU   0x15
cyclesToChange EQU   0x16
oldZeroDetect EQU   0
lightCounter EQU   0x19
armHoldOff  EQU   1

	GOTO main

  ; FILE C:\CC5X\EXEMPEL\RMTDIM\RMTDIM.C
			;#include <16f84.h>
			;
			;
			;
			;/* -------------------------------
			;	HW Pins
			;		irCarrier		input
			;		zeroDetectBit	input
			;		triacOn			output
			;		led0			output
			;		led1			output
			;		led2			output
			;		led3			output
			;---------------------------------*/
			;
			;#define zeroDetectBit	RB0
			;#define	irCarrier	RB2
			;#define triacOn		RB1
			;#define	TIMER0		TMR0
			;#define led0		RB4
			;#define led1		RB5
			;#define led2		RB3
			;
			;//	IR States
			;#define	IRS_IDLE	0x00
			;#define	IRS_CARRIER_ON	0x01
			;#define	IRS_CARRIER_OFF	0x02
			;
			;//	IR Codes
			;#define IRC_ALL_ON	0xB4	//PR+
			;#define IRC_ALL_OFF	0xB0	//PR-
			;#define IRC_DIM_UP	0xAC	//Vol+
			;#define IRC_DIM_DOWN	0xAA	//Vol-
			;#define IRC_HALT	0x92	//Left menu arrow 
			;
			;//	Miscellaneus IR
			;#define IRM_MASK_WORD	0xFF
			;#define IRM_ADDRESS_MASK	0x1E00
			;#define IRM_ADDRESS	0x1800	//Thomson DT3300 DVD-remote in TV mode
			;#define IRM_ON_CYCLES	7	//IRM_ON_CYCLES >= 480us / CYCLE_TIME = 4.8
			;#define IRM_DATA_THRES	25	//2080us / CYCLE_TIME (= 20.8) < IRM_LAST_THRES < 4600us / CYCLE_TIME (= 46)
			;#define IRM_LAST_THRES	50	//IRM_LAST_THRES > 4600us / CYCLE_TIME (= 46)
			;
			;
			;//	Dimmer States
			;#define	DS_ALL_ON	0x00
			;#define	DS_ALL_OFF	0x01
			;#define	DS_DIM_UP	0x02
			;#define	DS_DIM_DOWN	0x03
			;#define	DS_HALT		0x04
			;
			;//	Miscellaneus Dimmer
			;#define DM_LIGHTS_OFF	84	//DM_LIGHTS_OFF = 10ms / CYCLE_TIME - 1.6ms / CYCLE_TIME = 100 - 16 = 84
			;							//1.6ms empirical value of lamp off state preheat
			;#define DM_STAGE_NUM	100	//DM_STAGE_NUM = 10ms / CYCLE_TIME
			;#define DM_CHANGE_CYCLE	1000	//DM_CHANGE_CYCLE = DIM_TIME / (CYCLE_TIME * DM_STAGE_NUM)
			;
			;/*---------------------------------------------------------------------
			;Setup timer (with no prescaler) in 100 us period, 100us * 4M / 4 = 100
			;Remove timer interrupt overhead = 6 (four for interrupt and two for 
			;counter write halt) Value to write to timer = 256 - (100 - 6) = 162 = 0xA2
			;---------------------------------------------------------------------*/
			;#define DM_TIMER_RELOAD		0xA2
			;
			;
			;//	IR Variables
			;char		irState;
			;unsigned long	irData;
			;char		irOnCount;
			;char		irOffCount;
			;char		remoteCode;
			;unsigned long	irTemp;
			;
			;//	Dimmer Variables
			;char		dimState;
			;char		dimValue;			//0 = All on, DM_LIGHTS_OFF = All off
			;unsigned long	cyclesToChange;		//Number of cycles until next change of dimValue during
			;									//dimming
			;// Light Control Variables
			;bit		oldZeroDetect;
			;char		lightCounter;
			;bit		armHoldOff;
			;
			;
			;#pragma origin 4
	ORG 0x0004
			;
			;interrupt int_server( void) {
int_server
			;
			;	// Do not need to save registers on stack unless main
			;	// is expanded to run continuos code
			;
			;	//Reset Timer to period minus overhead
			;	TIMER0 = DM_TIMER_RELOAD;
	MOVLW .162
	BCF   0x03,RP0
	MOVWF TMR0
			;
			;	T0IF = 0;
	BCF   0x0B,T0IF
			;	
			;/*----------------------------------------
			;	
			;			IR Section
			;
			;----------------------------------------*/
			;
			;	if (irState == IRS_IDLE) {
	MOVF  irState,1
	BTFSS 0x03,Zero_
	GOTO  m001
			;//		led2 = 1;
			;		if (irCarrier == 0) {
	BTFSC 0x06,RB2
	GOTO  m008
			;			irState = IRS_CARRIER_ON;
	MOVLW .1
	MOVWF irState
			;			irData = 0;
	CLRF  irData
	CLRF  irData+1
			;			irOnCount = 1;
	MOVLW .1
	MOVWF irOnCount
			;		}
			;	} else if (irState == IRS_CARRIER_ON) {
	GOTO  m008
m001	DECFSZ irState,W
	GOTO  m004
			;//		led2 = 0;
			;		if (irCarrier == 1) {
	BCF   0x03,RP0
	BTFSS 0x06,RB2
	GOTO  m003
			;			irOffCount = 1;
	MOVLW .1
	MOVWF irOffCount
			;			if (irOnCount >= IRM_ON_CYCLES) {
	MOVLW .7
	SUBWF irOnCount,W
	BTFSS 0x03,Carry
	GOTO  m002
			;				irState = IRS_IDLE;
	CLRF  irState
			;			} else {
	GOTO  m003
			;				irState = IRS_CARRIER_OFF;
m002	MOVLW .2
	MOVWF irState
			;			}
			;		}
			;		irOnCount++;
m003	INCF  irOnCount,1
			;	} else if (irState == IRS_CARRIER_OFF) {
	GOTO  m008
m004	MOVF  irState,W
	XORLW .2
	BTFSS 0x03,Zero_
	GOTO  m008
			;		if (irCarrier == 0) {
	BCF   0x03,RP0
	BTFSC 0x06,RB2
	GOTO  m006
			;			irState = IRS_CARRIER_ON;
	MOVLW .1
	MOVWF irState
			;			irOnCount = 1;
	MOVLW .1
	MOVWF irOnCount
			;			if (irOffCount < IRM_DATA_THRES) {
	MOVLW .25
	SUBWF irOffCount,W
	BTFSC 0x03,Carry
	GOTO  m005
			;				irTemp = irData << 1;
	BCF   0x03,Carry
	RLF   irData,W
	MOVWF irTemp
	RLF   irData+1,W
	MOVWF irTemp+1
			;				irData = irTemp + 1;
	MOVF  irTemp+1,W
	MOVWF irData+1
	INCF  irTemp,W
	MOVWF irData
	BTFSC 0x03,Zero_
	INCF  irData+1,1
			;			} else {
	GOTO  m006
			;				irData <<= 1;
m005	BCF   0x03,Carry
	RLF   irData,1
	RLF   irData+1,1
			;			}
			;		}
			;		if (irOffCount > IRM_LAST_THRES) {
m006	MOVLW .51
	SUBWF irOffCount,W
	BTFSS 0x03,Carry
	GOTO  m007
			;			irState = IRS_IDLE;
	CLRF  irState
			;			irData <<= 1;
	BCF   0x03,Carry
	RLF   irData,1
	RLF   irData+1,1
			;			irTemp = irData & IRM_ADDRESS_MASK;
	MOVLW .30
	ANDWF irData+1,W
	MOVWF irTemp+1
	CLRF  irTemp
			;			if (irTemp == IRM_ADDRESS) {
	BTFSS 0x03,Zero_
	GOTO  m007
	MOVF  irTemp+1,W
	XORLW .24
	BTFSS 0x03,Zero_
	GOTO  m007
			;				remoteCode = irData & IRM_MASK_WORD;
	MOVF  irData,W
	MOVWF remoteCode
			;			}
			;		}
			;		irOffCount++;
m007	INCF  irOffCount,1
			;	}
			;
			;/*----------------------------------------
			;	
			;			Dimmer Section
			;
			;----------------------------------------*/
			;
			;	if (dimState == DS_ALL_ON) {
m008	MOVF  dimState,1
	BTFSS 0x03,Zero_
	GOTO  m010
			;		led0 = 0;
	BCF   0x03,RP0
	BCF   0x06,RB4
			;		led1 = 0;
	BCF   0x06,RB5
			;		dimValue = 0;
	CLRF  dimValue
			;		if (remoteCode == IRC_ALL_OFF) {
	MOVF  remoteCode,W
	XORLW .176
	BTFSS 0x03,Zero_
	GOTO  m009
			;			dimState = DS_ALL_OFF;
	MOVLW .1
	MOVWF dimState
			;		} else if (remoteCode == IRC_DIM_DOWN) {
	GOTO  m030
m009	MOVF  remoteCode,W
	XORLW .170
	BTFSS 0x03,Zero_
	GOTO  m030
			;			dimState = DS_DIM_DOWN;
	MOVLW .3
	MOVWF dimState
			;		}
			;	} else if (dimState == DS_DIM_DOWN) {
	GOTO  m030
m010	MOVF  dimState,W
	XORLW .3
	BTFSS 0x03,Zero_
	GOTO  m017
			;		led0 = 0;
	BCF   0x03,RP0
	BCF   0x06,RB4
			;		led1 = 1;
	BSF   0x06,RB5
			;		if (dimValue == DM_LIGHTS_OFF) {
	MOVF  dimValue,W
	XORLW .84
	BTFSS 0x03,Zero_
	GOTO  m011
			;			dimState = DS_ALL_OFF;
	MOVLW .1
	MOVWF dimState
			;		} else if (cyclesToChange == 0) {
	GOTO  m013
m011	MOVF  cyclesToChange,W
	IORWF cyclesToChange+1,W
	BTFSS 0x03,Zero_
	GOTO  m012
			;			dimValue++;
	INCF  dimValue,1
			;			cyclesToChange = DM_CHANGE_CYCLE;
	MOVLW .232
	MOVWF cyclesToChange
	MOVLW .3
	MOVWF cyclesToChange+1
			;		} else {
	GOTO  m013
			;			cyclesToChange--;
m012	DECF  cyclesToChange,1
	INCF  cyclesToChange,W
	BTFSC 0x03,Zero_
	DECF  cyclesToChange+1,1
			;		}
			;		if (remoteCode == IRC_ALL_ON) {
m013	MOVF  remoteCode,W
	XORLW .180
	BTFSS 0x03,Zero_
	GOTO  m014
			;			dimState = DS_ALL_ON;
	CLRF  dimState
			;		} else if (remoteCode == IRC_ALL_OFF) {
	GOTO  m030
m014	MOVF  remoteCode,W
	XORLW .176
	BTFSS 0x03,Zero_
	GOTO  m015
			;			dimState = DS_ALL_OFF;
	MOVLW .1
	MOVWF dimState
			;		} else if (remoteCode == IRC_DIM_UP) {
	GOTO  m030
m015	MOVF  remoteCode,W
	XORLW .172
	BTFSS 0x03,Zero_
	GOTO  m016
			;			dimState = DS_DIM_UP;
	MOVLW .2
	MOVWF dimState
			;		} else if (remoteCode == IRC_HALT) {
	GOTO  m030
m016	MOVF  remoteCode,W
	XORLW .146
	BTFSS 0x03,Zero_
	GOTO  m030
			;			dimState = DS_HALT;
	MOVLW .4
	MOVWF dimState
			;		}
			;	} else if (dimState == DS_DIM_UP) {
	GOTO  m030
m017	MOVF  dimState,W
	XORLW .2
	BTFSS 0x03,Zero_
	GOTO  m024
			;		led0 = 1;
	BCF   0x03,RP0
	BSF   0x06,RB4
			;		led1 = 0;
	BCF   0x06,RB5
			;		if (dimValue == 0) {
	MOVF  dimValue,1
	BTFSS 0x03,Zero_
	GOTO  m018
			;			dimState = DS_ALL_ON;
	CLRF  dimState
			;		} else if (cyclesToChange == 0) {
	GOTO  m020
m018	MOVF  cyclesToChange,W
	IORWF cyclesToChange+1,W
	BTFSS 0x03,Zero_
	GOTO  m019
			;			dimValue--;
	DECF  dimValue,1
			;			cyclesToChange = DM_CHANGE_CYCLE;
	MOVLW .232
	MOVWF cyclesToChange
	MOVLW .3
	MOVWF cyclesToChange+1
			;		} else {
	GOTO  m020
			;			cyclesToChange--;
m019	DECF  cyclesToChange,1
	INCF  cyclesToChange,W
	BTFSC 0x03,Zero_
	DECF  cyclesToChange+1,1
			;		}
			;		if (remoteCode == IRC_ALL_ON) {
m020	MOVF  remoteCode,W
	XORLW .180
	BTFSS 0x03,Zero_
	GOTO  m021
			;			dimState = DS_ALL_ON;
	CLRF  dimState
			;		} else if (remoteCode == IRC_ALL_OFF) {
	GOTO  m030
m021	MOVF  remoteCode,W
	XORLW .176
	BTFSS 0x03,Zero_
	GOTO  m022
			;			dimState = DS_ALL_OFF;
	MOVLW .1
	MOVWF dimState
			;		} else if (remoteCode == IRC_DIM_DOWN) {
	GOTO  m030
m022	MOVF  remoteCode,W
	XORLW .170
	BTFSS 0x03,Zero_
	GOTO  m023
			;			dimState = DS_DIM_DOWN;
	MOVLW .3
	MOVWF dimState
			;		} else if (remoteCode == IRC_HALT) {
	GOTO  m030
m023	MOVF  remoteCode,W
	XORLW .146
	BTFSS 0x03,Zero_
	GOTO  m030
			;			dimState = DS_HALT;
	MOVLW .4
	MOVWF dimState
			;		}
			;	} else if (dimState == DS_ALL_OFF) {
	GOTO  m030
m024	DECFSZ dimState,W
	GOTO  m026
			;		led0 = 1;
	BCF   0x03,RP0
	BSF   0x06,RB4
			;		led1 = 1;
	BSF   0x06,RB5
			;		dimValue = DM_LIGHTS_OFF;
	MOVLW .84
	MOVWF dimValue
			;		if (remoteCode == IRC_ALL_ON) {
	MOVF  remoteCode,W
	XORLW .180
	BTFSS 0x03,Zero_
	GOTO  m025
			;			dimState = DS_ALL_ON;
	CLRF  dimState
			;		} else if (remoteCode == IRC_DIM_UP) {
	GOTO  m030
m025	MOVF  remoteCode,W
	XORLW .172
	BTFSS 0x03,Zero_
	GOTO  m030
			;			dimState = DS_DIM_UP;
	MOVLW .2
	MOVWF dimState
			;		}
			;	} else if (dimState == DS_HALT) {
	GOTO  m030
m026	MOVF  dimState,W
	XORLW .4
	BTFSS 0x03,Zero_
	GOTO  m030
			;		if (remoteCode == IRC_ALL_ON) {
	MOVF  remoteCode,W
	XORLW .180
	BTFSS 0x03,Zero_
	GOTO  m027
			;			dimState = DS_ALL_ON;
	CLRF  dimState
			;		} else if (remoteCode == IRC_ALL_OFF) {
	GOTO  m030
m027	MOVF  remoteCode,W
	XORLW .176
	BTFSS 0x03,Zero_
	GOTO  m028
			;			dimState = DS_ALL_OFF;
	MOVLW .1
	MOVWF dimState
			;		} else if (remoteCode == IRC_DIM_DOWN) {
	GOTO  m030
m028	MOVF  remoteCode,W
	XORLW .170
	BTFSS 0x03,Zero_
	GOTO  m029
			;			dimState = DS_DIM_DOWN;
	MOVLW .3
	MOVWF dimState
			;		} else if (remoteCode == IRC_DIM_UP) {
	GOTO  m030
m029	MOVF  remoteCode,W
	XORLW .172
	BTFSS 0x03,Zero_
	GOTO  m030
			;			dimState = DS_DIM_UP;
	MOVLW .2
	MOVWF dimState
			;		}
			;	}
			;
			;/*----------------------------------------
			;	
			;		Light Control Section
			;
			;----------------------------------------*/
			;
			;	if (armHoldOff == 1) {
m030	BTFSS 0x18,armHoldOff
	GOTO  m031
			;		lightCounter = 0;
	CLRF  lightCounter
			;		armHoldOff = 0;
	BCF   0x18,armHoldOff
			;	} else if (zeroDetectBit != oldZeroDetect) {
	GOTO  m036
m031	BCF   0x03,RP0
	BTFSC 0x06,RB0
	GOTO  m032
	BTFSC 0x18,oldZeroDetect
	GOTO  m033
	GOTO  m035
m032	BTFSC 0x18,oldZeroDetect
	GOTO  m035
			;		oldZeroDetect = zeroDetectBit;
m033	BCF   0x18,oldZeroDetect
	BCF   0x03,RP0
	BTFSC 0x06,RB0
	BSF   0x18,oldZeroDetect
			;		if (zeroDetectBit == 1) {
	BTFSS 0x06,RB0
	GOTO  m034
			;			lightCounter = DM_STAGE_NUM-1;
	MOVLW .99
	MOVWF lightCounter
			;			armHoldOff = 1;
	BSF   0x18,armHoldOff
			;		} else {
	GOTO  m036
			;			lightCounter = 0;
m034	CLRF  lightCounter
			;		}
			;	} else {
	GOTO  m036
			;		lightCounter++;
m035	INCF  lightCounter,1
			;	}
			;	if ((lightCounter > dimValue) && (lightCounter < (dimValue + 2))) {
m036	MOVF  lightCounter,W
	SUBWF dimValue,W
	BTFSC 0x03,Carry
	GOTO  m037
	MOVLW .2
	ADDWF dimValue,W
	SUBWF lightCounter,W
	BTFSC 0x03,Carry
	GOTO  m037
			;		triacOn = 1;
	BCF   0x03,RP0
	BSF   0x06,RB1
			;		led2 = 0;
	BCF   0x06,RB3
			;	} else {
	GOTO  m038
			;		triacOn = 0;
m037	BCF   0x03,RP0
	BCF   0x06,RB1
			;		led2 = 1;
	BSF   0x06,RB3
			;	}	
			;}
m038	RETFIE
			;
			;void	main( void )
			;{
main
			;	irState = IRS_IDLE;
	CLRF  irState
			;	irData = 0;
	CLRF  irData
	CLRF  irData+1
			;	irOnCount = 0;
	CLRF  irOnCount
			;	irOffCount = 0;
	CLRF  irOffCount
			;	remoteCode = 0;
	CLRF  remoteCode
			;	dimState = DS_ALL_ON;
	CLRF  dimState
			;	dimValue = 0;
	CLRF  dimValue
			;	cyclesToChange = DM_CHANGE_CYCLE;
	MOVLW .232
	MOVWF cyclesToChange
	MOVLW .3
	MOVWF cyclesToChange+1
			;	oldZeroDetect = zeroDetectBit;
	BCF   0x18,oldZeroDetect
	BCF   0x03,RP0
	BTFSC 0x06,RB0
	BSF   0x18,oldZeroDetect
			;	lightCounter = 0;
	CLRF  lightCounter
			;	armHoldOff = 0;
	BCF   0x18,armHoldOff
			;
			;	PORTB = 0;
	CLRF  PORTB
			;	TRISB =  bin( 11000101 );
	MOVLW .197
	BSF   0x03,RP0
	MOVWF TRISB
			;
			;	OPTION = 0x88;
	MOVLW .136
	MOVWF OPTION_REG
			;
			;	TIMER0 = DM_TIMER_RELOAD;
	MOVLW .162
	BCF   0x03,RP0
	MOVWF TMR0
			;	RTIE = 1;
	BSF   0x0B,RTIE
			;	GIE = 1;
	BSF   0x0B,GIE
			;
			;	// Enable timer interrupt
			;
			;	while (1);
m039	GOTO  m039

	END
