#include <16f84.h>



/* -------------------------------
	HW Pins
		irCarrier		input
		zeroDetectBit	input
		triacOn			output
		led0			output
		led1			output
		led2			output
		led3			output
---------------------------------*/

#define zeroDetectBit	RB0
#define	irCarrier	RB2
#define triacOn		RB1
#define	TIMER0		TMR0
#define led0		RB4
#define led1		RB5
#define led2		RB3

//	IR States
#define	IRS_IDLE	0x00
#define	IRS_CARRIER_ON	0x01
#define	IRS_CARRIER_OFF	0x02

//	IR Codes
#define IRC_ALL_ON	0xB4	//PR+
#define IRC_ALL_OFF	0xB0	//PR-
#define IRC_DIM_UP	0xAC	//Vol+
#define IRC_DIM_DOWN	0xAA	//Vol-
#define IRC_HALT	0x92	//Left menu arrow 

//	Miscellaneus IR
#define IRM_MASK_WORD	0xFF
#define IRM_ADDRESS_MASK	0x1E00
#define IRM_ADDRESS	0x1800	//Thomson DT3300 DVD-remote in TV mode
#define IRM_ON_CYCLES	7	//IRM_ON_CYCLES >= 480us / CYCLE_TIME = 4.8
#define IRM_DATA_THRES	25	//2080us / CYCLE_TIME (= 20.8) < IRM_LAST_THRES < 4600us / CYCLE_TIME (= 46)
#define IRM_LAST_THRES	50	//IRM_LAST_THRES > 4600us / CYCLE_TIME (= 46)


//	Dimmer States
#define	DS_ALL_ON	0x00
#define	DS_ALL_OFF	0x01
#define	DS_DIM_UP	0x02
#define	DS_DIM_DOWN	0x03
#define	DS_HALT		0x04

//	Miscellaneus Dimmer
#define DM_LIGHTS_OFF	84	//DM_LIGHTS_OFF = 10ms / CYCLE_TIME - 1.6ms / CYCLE_TIME = 100 - 16 = 84
							//1.6ms empirical value of lamp off state preheat
#define DM_STAGE_NUM	100	//DM_STAGE_NUM = 10ms / CYCLE_TIME
#define DM_CHANGE_CYCLE	1000	//DM_CHANGE_CYCLE = DIM_TIME / (CYCLE_TIME * DM_STAGE_NUM)

/*---------------------------------------------------------------------
Setup timer (with no prescaler) in 100 us period, 100us * 4M / 4 = 100
Remove timer interrupt overhead = 6 (four for interrupt and two for 
counter write halt) Value to write to timer = 256 - (100 - 6) = 162 = 0xA2
---------------------------------------------------------------------*/
#define DM_TIMER_RELOAD		0xA2


//	IR Variables
char		irState;
unsigned long	irData;
char		irOnCount;
char		irOffCount;
char		remoteCode;
unsigned long	irTemp;

//	Dimmer Variables
char		dimState;
char		dimValue;			//0 = All on, DM_LIGHTS_OFF = All off
unsigned long	cyclesToChange;		//Number of cycles until next change of dimValue during
									//dimming
// Light Control Variables
bit		oldZeroDetect;
char		lightCounter;
bit		armHoldOff;


#pragma origin 4

interrupt int_server( void) {

	// Do not need to save registers on stack unless main
	// is expanded to run continuos code

	//Reset Timer to period minus overhead
	TIMER0 = DM_TIMER_RELOAD;

	T0IF = 0;
	
/*----------------------------------------
	
			IR Section

----------------------------------------*/

	if (irState == IRS_IDLE) {
//		led2 = 1;
		if (irCarrier == 0) {
			irState = IRS_CARRIER_ON;
			irData = 0;
			irOnCount = 1;
		}
	} else if (irState == IRS_CARRIER_ON) {
//		led2 = 0;
		if (irCarrier == 1) {
			irOffCount = 1;
			if (irOnCount >= IRM_ON_CYCLES) {
				irState = IRS_IDLE;
			} else {
				irState = IRS_CARRIER_OFF;
			}
		}
		irOnCount++;
	} else if (irState == IRS_CARRIER_OFF) {
		if (irCarrier == 0) {
			irState = IRS_CARRIER_ON;
			irOnCount = 1;
			if (irOffCount < IRM_DATA_THRES) {
				irTemp = irData << 1;
				irData = irTemp + 1;
			} else {
				irData <<= 1;
			}
		}
		if (irOffCount > IRM_LAST_THRES) {
			irState = IRS_IDLE;
			irData <<= 1;
			irTemp = irData & IRM_ADDRESS_MASK;
			if (irTemp == IRM_ADDRESS) {
				remoteCode = irData & IRM_MASK_WORD;
			}
		}
		irOffCount++;
	}

/*----------------------------------------
	
			Dimmer Section

----------------------------------------*/

	if (dimState == DS_ALL_ON) {
		led0 = 0;
		led1 = 0;
		dimValue = 0;
		if (remoteCode == IRC_ALL_OFF) {
			dimState = DS_ALL_OFF;
		} else if (remoteCode == IRC_DIM_DOWN) {
			dimState = DS_DIM_DOWN;
		}
	} else if (dimState == DS_DIM_DOWN) {
		led0 = 0;
		led1 = 1;
		if (dimValue == DM_LIGHTS_OFF) {
			dimState = DS_ALL_OFF;
		} else if (cyclesToChange == 0) {
			dimValue++;
			cyclesToChange = DM_CHANGE_CYCLE;
		} else {
			cyclesToChange--;
		}
		if (remoteCode == IRC_ALL_ON) {
			dimState = DS_ALL_ON;
		} else if (remoteCode == IRC_ALL_OFF) {
			dimState = DS_ALL_OFF;
		} else if (remoteCode == IRC_DIM_UP) {
			dimState = DS_DIM_UP;
		} else if (remoteCode == IRC_HALT) {
			dimState = DS_HALT;
		}
	} else if (dimState == DS_DIM_UP) {
		led0 = 1;
		led1 = 0;
		if (dimValue == 0) {
			dimState = DS_ALL_ON;
		} else if (cyclesToChange == 0) {
			dimValue--;
			cyclesToChange = DM_CHANGE_CYCLE;
		} else {
			cyclesToChange--;
		}
		if (remoteCode == IRC_ALL_ON) {
			dimState = DS_ALL_ON;
		} else if (remoteCode == IRC_ALL_OFF) {
			dimState = DS_ALL_OFF;
		} else if (remoteCode == IRC_DIM_DOWN) {
			dimState = DS_DIM_DOWN;
		} else if (remoteCode == IRC_HALT) {
			dimState = DS_HALT;
		}
	} else if (dimState == DS_ALL_OFF) {
		led0 = 1;
		led1 = 1;
		dimValue = DM_LIGHTS_OFF;
		if (remoteCode == IRC_ALL_ON) {
			dimState = DS_ALL_ON;
		} else if (remoteCode == IRC_DIM_UP) {
			dimState = DS_DIM_UP;
		}
	} else if (dimState == DS_HALT) {
		if (remoteCode == IRC_ALL_ON) {
			dimState = DS_ALL_ON;
		} else if (remoteCode == IRC_ALL_OFF) {
			dimState = DS_ALL_OFF;
		} else if (remoteCode == IRC_DIM_DOWN) {
			dimState = DS_DIM_DOWN;
		} else if (remoteCode == IRC_DIM_UP) {
			dimState = DS_DIM_UP;
		}
	}

/*----------------------------------------
	
		Light Control Section

----------------------------------------*/

	if (armHoldOff == 1) {
		lightCounter = 0;
		armHoldOff = 0;
	} else if (zeroDetectBit != oldZeroDetect) {
		oldZeroDetect = zeroDetectBit;
		if (zeroDetectBit == 1) {
			lightCounter = DM_STAGE_NUM-1;
			armHoldOff = 1;
		} else {
			lightCounter = 0;
		}
	} else {
		lightCounter++;
	}
	if ((lightCounter > dimValue) && (lightCounter < (dimValue + 2))) {
		triacOn = 1;
		led2 = 0;
	} else {
		triacOn = 0;
		led2 = 1;
	}	
}

void	main( void )
{
	irState = IRS_IDLE;
	irData = 0;
	irOnCount = 0;
	irOffCount = 0;
	remoteCode = 0;
	dimState = DS_ALL_ON;
	dimValue = 0;
	cyclesToChange = DM_CHANGE_CYCLE;
	oldZeroDetect = zeroDetectBit;
	lightCounter = 0;
	armHoldOff = 0;

	PORTB = 0;
	TRISB =  bin( 11000101 );

	OPTION = 0x88;

	TIMER0 = DM_TIMER_RELOAD;
	RTIE = 1;
	GIE = 1;

	// Enable timer interrupt

	while (1);
}



