/*
Copyright (c) 2012 Mehmet Adil Yalcin

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

// SPI interface coding was written with help from RGB Serial Backpack Matrix code by Ryan Owens, Sparkfun

#include <XBee.h>

XBee xbee = XBee();
XBeeResponse response = XBeeResponse();
Rx16Response rx16 = Rx16Response();

// sending the analog read
uint8_t accelXYZ[] = {0,0,0};
// send all packets to Xbee 1234, in asynch mode
Tx16Request tx = Tx16Request(0x1234, DISABLE_ACK_OPTION, accelXYZ, sizeof(accelXYZ),0);
#define PIN_ACCEL_X 0
#define PIN_ACCEL_Y 1
#define PIN_ACCEL_Z 2

#define BAUD_RATE 57600 // 38400

#define BEAT_DECK_TARGET 23
#define BEAT_DECK_A      24
#define BEAT_DECK_B      25
#define DISP_TYPE        10
#define BEAT_GROUP       11
#define VIBRATE_STATE    12
#define VIBRATE_FORCE    13
#define DISP_FLASH       14

#define DISP_TYPE_BEATPHASE_0 1
#define DISP_TYPE_BEATPHASE_1 2
#define DISP_TYPE_BEATPATTERN 3
#define DISP_TYPE_PIXELORDER  4
#define DISP_TYPE_RAND_LINE   5
#define DISP_TYPE_RAND_SQRE   6
#define DISP_TYPE_SNOW        7
#define DISP_TYPE_PATTERN_INV 8

//Basic Colors
#define BLACK  0
#define RED  0xE0
#define RED_HALF  0x60
#define GREEN  0x1C
#define BLUE  0x03
#define BLUE_HALF  0x01
#define ORANGE  RED|GREEN
#define MAGENTA  RED|BLUE
#define TEAL  BLUE|GREEN
#define WHITE (RED|GREEN|BLUE)

//Define the SPI Pin Numbers
#define DATAOUT 11//MOSI
#define DATAIN  12//MISO 
#define SPICLOCK  13//sck
#define SLAVESELECT 10//ss - cs
#define VIBRATE_PIN_1 8
#define VIBRATE_PIN_2 9

//Define the variables we'll need later in the program
char color_buffer [64];

// vibration state
bool vibrate = true;
bool forcevibrate = false;
char flashColor = 0x00;

// 0: focus
// 1: A
// 2: B
byte beatPhase[3] = {0,0,0};
byte dispType = DISP_TYPE_SNOW;

// 1: 4 beats
// 2: 2 beats
// 4: 1 beat
// 8: 1/2 beat
char beatGroup = 4;

// 0 or 1, use dby DISP_TYPE_BEATPATTERN
char beatPattern = 0;

char phase_1[4][4] = {
	{GREEN,RED  ,RED  ,RED  },
	{BLACK,GREEN,BLUE ,BLUE },
	{BLACK,BLACK,GREEN,BLUE },
	{BLACK,BLACK,BLACK,GREEN}
};

char activePixelOrder = 0;
char pixelOrder[2][64] = {
{  // spiral
   3*8+3, 3*8+4, 4*8+4, 4*8+3, 4*8+2, 3*8+2, 2*8+2, 2*8+3, //8
   2*8+4, 2*8+5, 3*8+5, 4*8+5, 5*8+5, 5*8+4, 5*8+3, 5*8+2,
   5*8+1, 4*8+1, 3*8+1 ,2*8+1, 1*8+1, 1*8+2 ,1*8+3, 1*8+4,
   1*8+5, 1*8+6, 2*8+6, 3*8+6, 4*8+6, 5*8+6, 6*8+6, 6*8+5,
   6*8+4, 6*8+3, 6*8+2, 6*8+1, 6*8+0, 5*8+0, 4*8+0, 3*8+0,
   2*8+0, 1*8+0, 0*8+0, 0*8+1, 0*8+2, 0*8+3, 0*8+4, 0*8+5,
   0*8+6, 0*8+7, 1*8+7, 2*8+7, 3*8+7, 4*8+7, 5*8+7, 6*8+7,
   7*8+7, 7*8+6, 7*8+5, 7*8+4, 7*8+3, 7*8+2, 7*8+1, 7*8+0
},
{  // other
   0*8+0, 7*8+7, 0*8+1, 7*8+6, 0*8+2, 7*8+5, 0*8+3, 7*8+4, //8
   0*8+4, 7*8+3, 0*8+5, 7*8+2, 0*8+6, 7*8+1, 0*8+7, 7*8+0,
   1*8+7, 6*8+0, 1*8+6 ,6*8+1, 1*8+5, 6*8+2 ,1*8+4, 6*8+3,
   1*8+3, 6*8+4, 1*8+2, 6*8+5, 1*8+1, 6*8+6, 1*8+0, 6*8+7,
   2*8+0, 5*8+7, 2*8+1, 5*8+6, 2*8+2, 5*8+5, 2*8+3, 5*8+4,
   2*8+4, 5*8+3, 2*8+5, 5*8+2, 2*8+6, 5*8+1, 2*8+7, 5*8+0,
   3*8+7, 4*8+0, 3*8+6, 4*8+1, 3*8+5, 4*8+2, 3*8+4, 4*8+3,
   3*8+3, 4*8+4, 3*8+2, 4*8+5, 3*8+1, 4*8+6, 3*8+0, 4*8+7
}
};
boolean spiral_inverse = false;

// note: invert <> direction
// note: invert up-down direction
char patterns[5][64] = {
  // X
  { 1,1,0,0,0,0,1,1,
    1,1,1,0,0,1,1,1,
    0,1,1,1,1,1,1,0,
    0,0,1,1,1,1,0,0,
    0,0,1,1,1,1,0,0,
    0,1,1,1,1,1,1,0,
    1,1,1,0,0,1,1,1,
    1,1,0,0,0,0,1,1,
  },
  // Y
  { 
    0,0,0,1,1,0,0,0,
    0,0,0,1,1,0,0,0,
    0,0,0,1,1,0,0,0,
    0,0,0,1,1,0,0,0,
    0,0,1,1,1,1,0,0,
    0,1,1,1,1,1,1,0,
    1,1,1,0,0,1,1,1,
    1,1,0,0,0,0,1,1,
  },
  // Z
  { 1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,
    0,1,1,1,0,0,0,0,
    0,0,1,1,1,0,0,0,
    0,0,0,1,1,1,0,0,
    0,0,0,0,1,1,1,0,
    1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,
  },
  // ABS_1
  { 0,0,0,0,1,0,0,0,
    0,0,0,1,1,0,0,0,
    0,0,1,0,0,1,0,0,
    1,1,0,1,1,0,1,0,
    0,1,0,1,1,0,1,1,
    0,0,1,0,0,1,0,0,
    0,0,0,1,1,0,0,0,
    0,0,0,1,0,0,0,0,
  },
  // ABS_2
  { 0,0,1,1,1,1,0,0,
    0,1,0,0,0,0,1,0,
    1,0,0,1,1,0,0,1,
    1,0,1,0,0,1,0,1,
    1,0,1,0,0,1,0,1,
    1,0,0,1,1,0,0,1,
    0,1,0,0,0,0,1,0,
    0,0,1,1,1,1,0,0,
  },
};

char getRandColor(){
	switch(random(6)){
//	case 0: return BLACK;
	case 0: return RED;
//	case 2: return RED_HALF;
	case 1: return GREEN;
	case 2: return BLUE;
//	case 5: return 0x01;//BLUE_HALF;
//	case 5: return ORANGE;
	case 3: return MAGENTA;
	case 4: return TEAL;
	case 5: return WHITE;
	}
}
char curColor;
char curLine = 0;
int curSqrSeed[2] = {0,0};
char snowData[8][2] = { {0,-1}, {0,-1}, {0,-1}, {0,-1}, {0,-1}, {0,-1}, {0,-1}, {0,-1} };

int squarePhase0[] = {0};
int squarePhase1[] = {-8,+8,-1,+1};
int squarePhase2[8][2] = {
	{-2,0}, {-1,-1}, {0,-2}, {1,-1}, {2,0}, {1,1}, {0,2}, {-1,1}
};
int squarePhase3[12][2] = {
	{-3,0}, {-2,1}, {-1,2},
	{0,3}, {1,2}, {2,1}, 
	{3,0},{2,-1},{1,-2},
	{0,-3},{-1,-2},{-2,-1}
};


void drawSnow(char phaseNo){
	for(int c=0; c<8; c++){
		// reset the snowflake...
		if((phaseNo%32)>30) {
			snowData[c][1] = -1;
		}
		if(snowData[c][1]==-1) continue;
		// advance LED
		snowData[c][1] = (phaseNo%32)/4;
		// light up the LED
		color_buffer[c+8*(7-snowData[c][1])] = snowData[c][0];
	}
}

void drawSquare(char phaseNo){
	char clr = curColor;
	int p = curSqrSeed[1]*8+curSqrSeed[0];
	color_buffer[p] = clr;
	for(int i=0; i<12; i++){
		int r=curSqrSeed[0]+squarePhase3[i][0];
		if(r>7||r<0) continue;
		int c=curSqrSeed[1]+squarePhase3[i][1];
		if(c>7||c<0) continue;
		color_buffer[c*8+r] = BLACK;
	}
	if(phaseNo%32<4) { clr = BLACK; }
	// 4 neighhborhood
	if(curSqrSeed[0]>0) color_buffer[p-1] = clr;
	if(curSqrSeed[0]<7) color_buffer[p+1] = clr;
	if(curSqrSeed[1]>0) color_buffer[p-8] = clr;
	if(curSqrSeed[1]<7) color_buffer[p+8] = clr;
	// 8 neighborhood
	if(phaseNo%32<8) { clr = BLACK; }
	for(int i=0; i<8; i++){
		int r=curSqrSeed[0]+squarePhase2[i][0];
		if(r>7||r<0) continue;
		int c=curSqrSeed[1]+squarePhase2[i][1];
		if(c>7||c<0) continue;
		color_buffer[c*8+r] = clr;
	}
}

void drawLine(char lineNo, char phaseNo){
	// todo: inverse direction
	char clr = curColor;
	char lineWidth = (phaseNo%32)/4+1;
	switch(lineNo){
	case  0: setRect(clr,0,2,0,lineWidth); break;
	case  1: setRect(clr,0,2,0,lineWidth); break;
	case  2: setRect(clr,1,3,0,lineWidth); break;
	case  3: setRect(clr,1,3,0,lineWidth); break;
	case  4: setRect(clr,5,7,0,lineWidth); break;
	case  5: setRect(clr,6,8,0,lineWidth); break;
	case  6: setRect(clr,6,8,0,lineWidth); break;
	case  7: setRect(clr,0,lineWidth,0,2); break;
	case  8: setRect(clr,0,lineWidth,0,2); break;
	case  9: setRect(clr,0,lineWidth,1,3); break;
	case 10: setRect(clr,0,lineWidth,5,7); break;
	case 11: setRect(clr,0,lineWidth,5,7); break;
	case 12: setRect(clr,0,lineWidth,6,8); break;
	case 13: setRect(clr,0,lineWidth,6,8); break;
	// diagonal variants
	case 14: 
	case 15: 
	case 16: 
	case 17: 
		setDiagonal(BLACK,5,lineWidth);
		setDiagonal(BLACK,6,lineWidth);
		setDiagonal(clr,7,lineWidth);
		setDiagonal(BLACK,8,lineWidth);
		setDiagonal(BLACK,9,lineWidth);
		break;
	case 18: 
	case 19: 
	case 20: 
	case 21: 
		setDiagonal2(BLACK,-2,lineWidth);
		setDiagonal2(BLACK,-1,lineWidth);
		setDiagonal2(clr, 0,lineWidth);
		setDiagonal2(BLACK, 1,lineWidth);
		setDiagonal2(BLACK, 2,lineWidth);
		break;
	}
}

unsigned long lastTime=0;
void readAndSendAccel(){
	// send every 250ms only
	unsigned long curTime = millis();
	if(curTime>lastTime+100){
		accelXYZ[0] = analogRead(PIN_ACCEL_X)/4; // reuce resolution 1024 -> 256
		accelXYZ[1] = analogRead(PIN_ACCEL_Y)/4; // reuce resolution 1024 -> 256
		accelXYZ[2] = analogRead(PIN_ACCEL_Z)/4; // reuce resolution 1024 -> 256
		// avoid sending a special +++ message
		// http://arduino.cc/en/Main/ArduinoBoardFioTips
		if(accelXYZ[1]=='+')accelXYZ[1]++;
		xbee.send(tx);
		// won't check if submission is successful or not...
		lastTime = curTime;
	}
}

void setupSPI(){
	//SPI Bus setup
	SPCR = (1<<SPE)|(1<<MSTR)|(1<<SPR1);	//Enable SPI HW, Master Mode, divide clock by 16    //SPI Bus setup
	//Set the pin modes for the RGB matrix
	pinMode(DATAOUT, OUTPUT);
	pinMode(DATAIN, INPUT);
	pinMode(SPICLOCK,OUTPUT);
	pinMode(SLAVESELECT,OUTPUT);
	//Make sure the RGB matrix is deactivated
	digitalWrite(SLAVESELECT,HIGH); 
}
void setupXBee(){
	// Init XBee communication
	Serial.begin(BAUD_RATE);
	xbee.setSerial(Serial);
}
void setup()  {
	setupSPI();
	setupXBee();
	
	pinMode(VIBRATE_PIN_1,OUTPUT);
	pinMode(VIBRATE_PIN_2,OUTPUT);
	setVibrateOff();
}


void clearScreen(char color){
	for(int LED=0; LED<64; LED++) color_buffer[LED] = color;
}
void setRows(char color, char r_first, char r_last){
	for(int r=r_first ; r<r_last;r++){
		for(int c=0 ; c<8;c++) color_buffer[r*8+c] = color;
	}
}
void setCols(char color, char c_first, char c_last){
	for(int c=c_first ; c<c_last;c++){
		for(int r=0 ; r<8;r++) color_buffer[r*8+c] = color;
	}
}
void setRect(char color, char c_first, char c_last, char r_first, char r_last){
	for(int c=c_first ; c<c_last;c++){
		for(int r=r_first ; r<r_last;r++) color_buffer[r*8+c] = color;
	}
}

void setDiagonal(char color, char total, char lim){
	if(lim>total) lim = total;
	if(lim>7) lim = 7;
	for(int c=(total<8?0:total-7); c<=lim ; c++){
		int r = total-c;
		color_buffer[r*8+c] = color;
	}
}
// r = c + diff;
void setDiagonal2(char color, char diff, char lim){
	char lim2 = lim;
	if(lim2>7-diff) lim2=7-diff;
	if(lim2>7) lim2 = 7;
	for(int c=(diff>0?0:-diff); c<=lim2 ; c++){
		int r = c+diff;
		color_buffer[r*8+c] = color;
	}
}

// redcues LED color by one
void reduceLED(int LED, boolean r, boolean g, boolean b){
	if(r && color_buffer[LED]&RED)  { color_buffer[LED] -= 0x20; }
	if(g && color_buffer[LED]&GREEN){ color_buffer[LED] -= 0x04; }
	if(b && color_buffer[LED]&BLUE) { color_buffer[LED] -= 0x01; }
}

// traverses each pixel, and lets each color fade out...
void fadeScreen(char skipColor, int toID){
	for(int LED=0; LED<toID; LED++) {
		if(color_buffer[LED]==skipColor) continue;
		reduceLED(LED,true,true,true);
	}
}
void fadeScreen(char skipColor, char skipColor2, int toID){
	for(int LED=0; LED<toID; LED++) {
		if(color_buffer[LED]==skipColor) continue;
		if(color_buffer[LED]==skipColor2) continue;
		reduceLED(LED,true,true,true);
	}
}
void fadeScreen(int toID){
	for(int LED=0; LED<toID; LED++) {
		reduceLED(LED,true,true,true);
	}
}

int loopNo = 0;

int getRow(int phase){
	int ticks=128/beatGroup;
	int off = phase%ticks;
	return off/(ticks/8); // beatGroup : 4
}

void setVibrateOn(){
	digitalWrite(VIBRATE_PIN_1,HIGH);
	digitalWrite(VIBRATE_PIN_2,HIGH);
}
void setVibrateOff(){
	digitalWrite(VIBRATE_PIN_1,LOW);
	digitalWrite(VIBRATE_PIN_2,LOW);
}

void readXbeePacket(){
	xbee.readPacket();
	XBeeResponse response = xbee.getResponse();
	if (response.isAvailable()) { // got something
		if (response.getApiId() == RX_16_RESPONSE) {
			response.getRx16Response(rx16);
			switch(rx16.getData(0)){
			  case BEAT_DECK_TARGET: beatPhase[0] = rx16.getData(1); break;
			  case BEAT_DECK_A:      beatPhase[1] = rx16.getData(1); break;
			  case BEAT_DECK_B:      beatPhase[2] = rx16.getData(1); break;
			  case DISP_TYPE:        
				dispType = rx16.getData(1);     
				break;
			  case BEAT_GROUP:       beatGroup = rx16.getData(1);    break;
			  case VIBRATE_STATE:    
				vibrate = rx16.getData(1); 
				if(!vibrate) setVibrateOff();
				break;
			  case VIBRATE_FORCE: 
				forcevibrate = rx16.getData(1); 
				if(forcevibrate) setVibrateOn(); else setVibrateOff();
				break;
			  case DISP_FLASH:
				flashColor = rx16.getData(1); 
				break;
			  default: break;
			}
			// Note: it takes time for vibration to begin, so plan ahead!
			if(vibrate && forcevibrate==false){
				if((beatPhase[0]+2)%32<12) {
					setVibrateOn();
				} else {
					setVibrateOff();
				}
			}
		} else {
			// unexpected!
		}
	} else if (response.isError()) {
	}
}

int lastBeatPhase = 0;
char patternColor=RED;
char patternShape=0;
void loop() {
	readAndSendAccel();
	readXbeePacket();
	
	if(flashColor!=0x00){
		for(int LED=0, r=0; r<8; r++){
			for(int c=0; c<8; c++, LED++){
				boolean b = beatPhase[0]%32<16;
				color_buffer[LED] = (b != ((r+c)%2==0))?flashColor:0x00;
			}
		}
	} else {
	switch(dispType){
	case DISP_TYPE_PATTERN_INV:{
		if((beatPhase[0]%32<2) && ((lastBeatPhase%32)>2) && ((lastBeatPhase%32)!=beatPhase[0])) {
			patternColor = getRandColor();
			patternShape = random(5);
		}
		boolean onoff = (beatPhase[0]%16)/8;
		for(int pix=0;pix<64;pix++){
			char p = patterns[patternShape][pix];
			boolean t=onoff;
			if(p==0) t = !t;
			color_buffer[pix] = (t?patternColor:BLACK);
		}
		break;}
	case DISP_TYPE_SNOW:{
		if(beatPhase[0]%8==0){
			fadeScreen(64);
		}
		if((beatPhase[0]%32<2) && ((lastBeatPhase%32)>2) && ((lastBeatPhase%32)!=beatPhase[0])) {
			int numOfSnows = random(3)+2;
			// pick two free columns randomly
			for(int s=0; s<numOfSnows; s++){
				int rr = random(8);
				// pick a non-used row
//				while(snowData[rr][1]==-1) rr=random(8);
				snowData[rr][1] = 0; // set row to 0
				snowData[rr][0] = getRandColor(); // set a random color
			}
		}
		drawSnow(beatPhase[0]);
		break;}
	case DISP_TYPE_RAND_LINE:{
		if((beatPhase[0]%32<3) && ((lastBeatPhase%32)>3) && ((lastBeatPhase%32)!=beatPhase[0])) {
			curLine = random(22);
			curColor = getRandColor();
		}
		drawLine(curLine,beatPhase[0]);
		break;}
	case DISP_TYPE_RAND_SQRE:{
		if((beatPhase[0]%32<3) && ((lastBeatPhase%32)>3) && ((lastBeatPhase%32)!=beatPhase[0])) {
			curSqrSeed[0] = random(8);
			curSqrSeed[1] = random(8);
			curColor = getRandColor();
			fadeScreen(64);
		}
		drawSquare(beatPhase[0]);
		break;}
	case DISP_TYPE_BEATPHASE_0:{
		int row = getRow(beatPhase[0]);
		setRows(BLACK,row,8);
		fadeScreen(RED,BLUE,8*row);
		if(row>=4){
			for(int i=0;i<8*4;i++) color_buffer[i] = BLACK;
		}
		// beat phase - focus
		int rowD = row%4;
		color_buffer[8*row+0]= phase_1[rowD][0];
		color_buffer[8*row+1]= phase_1[rowD][1];
		color_buffer[8*row+2]= phase_1[rowD][2];
		color_buffer[8*row+3]= phase_1[rowD][3];
		
		color_buffer[8*row+4]= phase_1[rowD][3];
		color_buffer[8*row+5]= phase_1[rowD][2];
		color_buffer[8*row+6]= phase_1[rowD][1];
		color_buffer[8*row+7]= phase_1[rowD][0];
		break;}
	case DISP_TYPE_BEATPHASE_1:{
		if(loopNo%20==0) fadeScreen(8*8);
		int rowA = getRow(beatPhase[1]);
		int rowB = getRow(beatPhase[2]);
		// multi beat-phase for two decks
		color_buffer[8*rowA+0]=GREEN;
		color_buffer[8*rowA+1]=GREEN;
		color_buffer[8*rowA+2]=GREEN;
		color_buffer[8*rowA+3]=GREEN;
		color_buffer[8*rowB+4]=RED;
		color_buffer[8*rowB+5]=RED;
		color_buffer[8*rowB+6]=RED;
		color_buffer[8*rowB+7]=RED;
		break;}
	case DISP_TYPE_BEATPATTERN:{
		// change pixel order type every 4 beats...
		if((beatPhase[0]<2) && ((lastBeatPhase)>2) && ((lastBeatPhase)!=beatPhase[0])) {
			beatPattern = random(2);
		}
		if(beatPattern==0){
			displayBeatPattern();
		} else {
			updateDisplaySliding();
		}
		break;}
	case DISP_TYPE_PIXELORDER:{
		// change pixel order type every 4 beats...
		if((beatPhase[0]<2) && ((lastBeatPhase)>2) && ((lastBeatPhase)!=beatPhase[0])) {
			activePixelOrder = random(2);
		}
		int l=beatPhase[0]%64;
		if(beatPhase[0]<64){
//			clearScreen(BLACK);
			for(int i=0; i<l ; i++) color_buffer[pixelOrder[activePixelOrder][i]] = RED;
			if(l>32){
				for(int i=0; i<l-32; i++) color_buffer[pixelOrder[activePixelOrder][i]] = BLUE_HALF;
			}
		} else {
			for(int i=63; i>63-l ; i--) {
				color_buffer[pixelOrder[activePixelOrder][i]] = (i<32)?WHITE:GREEN;
			}
		}
		break;}
	}
	}
	lastBeatPhase = beatPhase[0];
	
	updateDisplay();
//	delay(2);
	loopNo++;
}


void displayBeatPattern(){
	// use focused beat only
	// 4/4 beat
	// each beat has its own animation (8 rows*4 : 32 states)
	int state = beatPhase[0]/4;
	if(state<8) {
		// animation one
		int row = state%8;
		color_buffer[8*row+0]=WHITE;
		color_buffer[8*row+2]=WHITE;
		color_buffer[8*row+4]=WHITE;
		color_buffer[8*row+6]=WHITE;
	} else if(state<16) {
		// animation two
		int row = (7-state%8);
		color_buffer[8*row+1]=BLUE;
		color_buffer[8*row+3]=BLUE;
		color_buffer[8*row+5]=BLUE;
		color_buffer[8*row+7]=BLUE;
	} else if(state<24) {
		int col = (7-state%8);
		for(int k=0;k<8; k++)
			color_buffer[8*k+col]=RED;
	} else {
		// animation four
		int w = (7-state%8);
		if(w%2)  clearScreen(RED);
		else  clearScreen(BLACK);
	}
}



void updateDisplay(){
	//Activate the RGB Matrix
	digitalWrite(SLAVESELECT, LOW);
	// A delay of 0.5ms is recommended between the assertion of CS and the start of data
	// transfer, as well as after the end of data transfer and the negation of CS.
	delayMicroseconds(50);
	//Send the color buffer to the RGB Matrix
	for(int LED=0; LED<64; LED++) spi_transfer(color_buffer[LED]);
	//Deactivate the RGB matrix.
	digitalWrite(SLAVESELECT, HIGH);
}

void updateDisplaySliding(){
	if(beatPhase[0]<32){
		int row;
		row = beatPhase[0]/8;
		for(int i=0; i<8 ; i++) color_buffer[8*row+i] = WHITE;
		row = 7-row;
		for(int i=0; i<8 ; i++) color_buffer[8*row+i] = WHITE;
	} else if(beatPhase[0]<64){
		int row;
		row = 3-(beatPhase[0]%32)/8;
		for(int i=0; i<8 ; i++) color_buffer[8*row+i] = RED;
		row = 7-row;
		for(int i=0; i<8 ; i++) color_buffer[8*row+i] = RED;
	} else if(beatPhase[0]<96){
		int col;
		col = 4-(beatPhase[0]%32)/8;
		for(int i=0; i<8 ; i++) color_buffer[8*i+col] = RED|GREEN;
		col = 7-col;
		for(int i=0; i<8 ; i++) color_buffer[8*i+col] = RED|GREEN;
	} else  {
		int col;
		col = (beatPhase[0]%32)/8;
		for(int i=0; i<8 ; i++) color_buffer[8*i+col] = GREEN;
		col = 7-col;
		for(int i=0; i<8 ; i++) color_buffer[8*i+col] = GREEN;
	}
}

//Use this command to send a single color value to the RGB matrix.
//NOTE: You must send 64 color values to the RGB matrix before it displays an image!
char spi_transfer(volatile char data) {
	SPDR = data;                    // Start the transmission
//	return data;
	while (!(SPSR & (1<<SPIF))) ;   // Wait for the end of the transmission
	return SPDR;                    // return the received byte
}


