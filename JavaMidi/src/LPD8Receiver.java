import javax.sound.midi.MidiMessage;
import javax.sound.midi.ShortMessage;
import javax.sound.midi.Receiver;

// This one listens to MIDI messages from Traktor...
public class LPD8Receiver
	implements	Receiver
{
	
	static final int DISP_TYPE        = 10;
	static final int BEAT_GROUP       = 11;
	static final int DISP_TYPE_BEATPHASE_0 = 1;   
	static final int DISP_TYPE_BEATPHASE_1 = 2;  
	static final int DISP_TYPE_BEATPATTERN = 3;
	static final int VIBRATE_STATE  = 12;
	static final int VIBRATE_FORCE  = 13;
	static final int DISP_FLASH     = 14;
	
	boolean vibrate = false;
	boolean forceVibrate = false;

	int ActiveColorPads = 0;
	
	public LPD8Receiver() { }
	
	public void close() { }

	public void send(MidiMessage message, long lTimeStamp) {
//		System.out.println("LPD8 message recv.");
		if (message instanceof ShortMessage) {
			decodeMessage((ShortMessage) message);
		}
	}

	public String decodeMessage(ShortMessage message) {
		System.out.println("channel:"+message.getChannel()+ "  command:"+message.getCommand()+"  data1:"+message.getData1());
		if((message.getChannel()+1)==4){
			// Handle display type update => program change message
			switch(message.getCommand()){
			case 0xc0: // program change message
				System.out.println("Displ message " + message.getData1());
			    ControlPC.xbeeHelper.broadcast(DISP_TYPE, message.getData1()+1);
			    break;
			case 0x80: // pad note on
				switch(message.getData1()){
				case 36: // C2 note Off: Disable vibrate on beat
					System.out.println("Vibrate on beat : Disabled");
					ControlPC.xbeeHelper.broadcast(VIBRATE_STATE, 0);
					break;
				case 43: // G2 note off : Always vibrate off
					System.out.println("Vibrate (forced): Disabled");
					ControlPC.xbeeHelper.broadcast(VIBRATE_FORCE, 0);
					break;
				case 38: 
				case 40:
				case 41:
				case 45:
				case 47:
				case 48: // turn light off
					if(ActiveColorPads>0){
						ActiveColorPads--;
						if(ActiveColorPads==0)
							System.out.println("Flash Color: Off");
							ControlPC.xbeeHelper.broadcast(DISP_FLASH, 0x00);
					}
					break;
				}
				break;
			case 0x90: // pad note off
				switch(message.getData1()){
				case 36: // C2 note On: Enable vibrate on beat
					System.out.println("Vibrate on beat : Enabled");
					ControlPC.xbeeHelper.broadcast(VIBRATE_STATE, 1);
					break;
				case 43: // G2 note On : Always vibrate on
					System.out.println("Vibrate (forced): Enabled");
					ControlPC.xbeeHelper.broadcast(VIBRATE_FORCE, 1);
					break;
				case 38: // turn light on
					System.out.println("Flash Color: White");
					ControlPC.xbeeHelper.broadcast(DISP_FLASH, 0xFF);
					ActiveColorPads++;
					break;
				case 40: // turn light on
					System.out.println("Flash Color: Red");
					ControlPC.xbeeHelper.broadcast(DISP_FLASH, 0xE0);
					ActiveColorPads++;
					break;
				case 41: // turn light on
					System.out.println("Flash Color: Blue");
					ControlPC.xbeeHelper.broadcast(DISP_FLASH, 0x03);
					ActiveColorPads++;
					break;
				case 45: // turn light on
					ControlPC.xbeeHelper.broadcast(DISP_FLASH, 0xFF);
					ActiveColorPads++;
					break;
				case 47: // turn light on
					ControlPC.xbeeHelper.broadcast(DISP_FLASH, 0xFF);
					ActiveColorPads++;
					break;
				case 48: // turn light on
					ControlPC.xbeeHelper.broadcast(DISP_FLASH, 0xFF);
					ActiveColorPads++;
					break;
				}
				break;
			}
		}
		return "";
	}
	
}



/*** DumpReceiver.java ***/

