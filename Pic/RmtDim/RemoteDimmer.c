

/*-------------------------------------------------------------

Total dim time = Cycle time * DM_LIGHTS_OFF * DM_CHANGE_CYCLE

			   = 160 us * 62 * 504 = 5s
--------------------------------------------------------------*/


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


extern char	irCarrier;
extern char	zeroDetectBit;
extern char	triacOn;
extern char	led0;
extern char	led1;
extern char	led2;
extern char	led3;

extern char	TIMER0;






//	IR States
#define	IRS_IDLE			0x00
#define	IRS_CARRIER_ON		0x01
#define	IRS_CARRIER_OFF		0x02

//	IR Codes
#define IRC_ALL_ON			0xB4	//PR+
#define IRC_ALL_OFF			0xB0	//PR-
#define IRC_DIM_UP			0xAC	//Vol+
#define IRC_DIM_DOWN		0xAA	//Vol-
#define IRC_HALT			0x92	//Left menu arrow 

//	Miscellaneus IR
#define IRM_MASK_WORD		0xFF
#define IRM_ADDRESS_MASK	0x1E00
#define IRM_ADDRESS			0x1800	//Thomson DT3300 DVD-remote in TV mode

//	Dimmer States
#define	DS_ALL_ON			0x00
#define	DS_ALL_OFF			0x01
#define	DS_DIM_UP			0x02
#define	DS_DIM_DOWN			0x03
#define	DS_HALT				0x04

//	Miscellaneus Dimmer
#define DM_LIGHTS_OFF		62
#define DM_CHANGE_CYCLE		500

/*---------------------------------------------------------------------
Setup timer (with no prescaler) in 160 us period, 160us * 4M / 4 = 160
Remove timer interrupt overhead = 4
Value to write to timer = 256 - (160 - 4) = 100 = 0x64
---------------------------------------------------------------------*/
#define DM_TIMER_RELOAD		0x64




//	IR Variables
char			irState;
unsigned int	irData;
char			irOnCount;
char			irOffCount;
char			remoteCode;

//	Dimmer Variables
char			dimState;
char			dimValue;			//0 = All on, DM_LIGHTS_OFF = All off
unsigned int	cyclesToChange;		//Number of cycles until next change of dimValue during
									//dimming
// Light Control Variables
char			oldZeroDetect;
char			lightCounter;



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

	TIMER0 = DM_TIMER_RELOAD;

	// Enable timer interrupt

	while (1);
}


void interrupt ( void ) {

	// Do not need to save registers on stack unless main
	// is expanded to run continuos code

	//Reset Timer to period minus overhead
	TIMER0 = DM_TIMER_RELOAD;
	
/*----------------------------------------
	
			IR Section

----------------------------------------*/

	if (irState == IRS_IDLE) {
		if (irCarrier == 1) {
			irState = IRS_CARRIER_ON;
			irData = 0;
			irOnCount = 1;
		}
	} else if (irState == IRS_CARRIER_ON) {
		if (irCarrier == 0) {
			irOffCount = 1;
			if (irOnCount >= 5) {
				irState = IRS_IDLE;
			} else {
				irState = IRS_CARRIER_OFF;
			}
		}
		irOnCount++;
	} else if (irState == IRS_CARRIER_OFF) {
		if (irCarrier == 1) {
			irState = IRS_CARRIER_ON;
			irOnCount = 1;
			if (irOffCount < 15) {
				irData = (irData << 1) + 1;
			} else {
				irData <<= 1;
			}
		}
		if (irOffCount > 35) {
			irState = IRS_IDLE;
			if ((irData & IRM_ADDRESS_MASK) == IRM_ADDRESS) {
				remoteCode = irData & IRM_MASK_WORD;
			}
		}
		irOffCount++;
	}

/*----------------------------------------
	
			Dimmer Section

----------------------------------------*/

	if (dimState == DS_ALL_ON) {
		dimValue = 0;
		if (remoteCode == IRC_ALL_OFF) {
			dimState = DS_ALL_OFF;
		} else if (remoteCode == IRC_DIM_DOWN) {
			dimState = DS_DIM_DOWN;
		}
	} else if (dimState == DS_DIM_DOWN) {
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
		dimValue = DM_LIGHTS_OFF;
		if (remoteCode == IRC_ALL_ON) {
			dimState = DS_ALL_OFF;
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

	if (zeroDetectBit != oldZeroDetect) {
		oldZeroDetect = zeroDetectBit;
		lightCounter = 0;
		if (dimValue == 0) triacOn = 1;
		else triacOn = 0;
	} else {
		lightCounter++;
	}
	if (dimValue == lightCounter) triacOn = 1;
}
