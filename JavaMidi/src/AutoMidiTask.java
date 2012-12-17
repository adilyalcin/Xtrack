import java.util.TimerTask;

class AutoMidiTask extends TimerTask {
	private int phase = 0;
    public void run() {
    	int sendPhase = (phase++)%32;
    	ControlPC.xbeeHelper.broadcast(TraktorReceiver.BEAT_DECK_TARGET,sendPhase);
        if(sendPhase==0)System.out.println("sendPhase.. : " + sendPhase);
    }
}
