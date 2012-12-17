import javax.sound.midi.MidiMessage;
import javax.sound.midi.ShortMessage;
import javax.sound.midi.Receiver;

// This one listens to MIDI messages from Traktor...
public class TraktorReceiver
	implements	Receiver
{
	static final int BEAT_DECK_TARGET = 23;
	static final int BEAT_DECK_A      = 24;
	static final int BEAT_DECK_B      = 25;
	static final int DISP_TYPE        = 10;
	static final int BEAT_GROUP       = 11;
	static final int DISP_TYPE_BEATPHASE_0 = 1;   
	static final int DISP_TYPE_BEATPHASE_1 = 2;  
	static final int DISP_TYPE_BEATPATTERN = 3;
	
	int[] beatNo = new int[]{0,0,0};
	int[] phaseNo = new int[]{0,0,0};
	
	// if 0: half, 1:normal, 2:double
	public int beatMult = 1;
	boolean beatHalf = false;

	public TraktorReceiver() { }

	public void close() { }

	public void send(MidiMessage message, long lTimeStamp) {
		if (message instanceof ShortMessage) {
			decodeMessage((ShortMessage) message);
		}
	}

	public String decodeMessage(ShortMessage message) {
		if(message.getChannel()+1==2){
			if(message.getStatus()==177){
//			    tempo phase monitor / channel 2
			    int[] a = new int[2];
			    a[0] = message.getData1(); // CC no 
			    a[1] = message.getData2(); // beat phase
			    // adjust the beat-grid so that 0 is the beat-start
			    a[1] = (a[1]+16)%32;
			    if(beatMult==2){
			    	a[1] = (a[1]*2)%32;
			    }
			    if(beatMult==0){
			    	a[1] = a[1]/2; // todo
			    	if(phaseNo[0]>13) a[1]+=16;
			    }
			    
			    if(a[0]==BEAT_DECK_TARGET && a[1]%4==0) System.out.println("Beat-Phase:" + a[1]);
			    
			    // update beatNo;
			    switch(a[0]){
			      case BEAT_DECK_TARGET:   
//			        if(phaseNo[0]<16 && a[1]>=16 && a[1]<21) {
			        if(phaseNo[0]>=30 && a[1]<=2) {
			          beatNo[0]++;
//			          System.out.println("FW");
			        } 
//			        if(phaseNo[0]>16 && a[1]<=16 && a[1]>10){ 
			        if(phaseNo[0]<=2 && a[1]>=30){ 
			          beatNo[0]--; // back 
//			          System.out.println("BACK");
			        }
			        phaseNo[0]=a[1]; break;
			      case BEAT_DECK_A:
			        if(phaseNo[1]>=30 && a[1]<=2 ) beatNo[1]++; 
			        if(phaseNo[1]<=2  && a[1]>=30) beatNo[1]--;
			        phaseNo[1]=a[1]; break;
			      case BEAT_DECK_B:
			    	if(phaseNo[2]>=30 && a[1]<=2 ) beatNo[2]++; 
			    	if(phaseNo[2]<=2  && a[1]>=30) beatNo[2]--; 
			        phaseNo[2]=a[1]; break;
			      default: break;
			    }
			    switch(a[0]){
			    // adjust the 32-phase to cover 4 beats into 128-phase
			      case BEAT_DECK_TARGET:
			      case BEAT_DECK_A:
			      case BEAT_DECK_B:
				        a[1] += (beatNo[a[0]-BEAT_DECK_TARGET]%4)*32;
			        break;
			      default: break;
			    }
//			    System.out.println("Beat phase:" + a[1]);
			    ControlPC.xbeeHelper.broadcast(a[0], a[1]);
			}
		}
		return "";
	}

}


