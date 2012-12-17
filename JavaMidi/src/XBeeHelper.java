import java.io.FileOutputStream;
import java.io.PrintStream;
import java.util.Date;

import org.apache.log4j.PropertyConfigurator;

import com.rapplogic.xbee.api.XBee;
import com.rapplogic.xbee.api.ApiId;
import com.rapplogic.xbee.api.wpan.RxResponse16;
import com.rapplogic.xbee.api.wpan.TxRequest16;
import com.rapplogic.xbee.api.wpan.TxRequestBase;
import com.rapplogic.xbee.api.PacketListener;
import com.rapplogic.xbee.api.XBeeAddress16;
import com.rapplogic.xbee.api.XBeeResponse;

public class XBeeHelper {
	XBee xbee;
	long baseTime;
	PrintStream logStream;
	
	public XBeeHelper() {
		try {
			baseTime = System.currentTimeMillis();
			FileOutputStream fs =  new FileOutputStream("sensor_log_"+baseTime+".txt");
			logStream = new PrintStream(fs);
			logStream.println("BaseTime: "+baseTime);
			logStream.println("CurDate: "+new Date());
		} catch(Exception e){
			System.out.println("Cannot open log file?");
		}
		// setup xbee  
		try {
			PropertyConfigurator.configure("log4j.properties");
			
			xbee = new XBee();
			xbee.open("COM12", 57600);
			
			xbee.addPacketListener(new PacketListener() {
			    public void processResponse(XBeeResponse response) {
			        // handle the response
			    	if (response.getApiId() == ApiId.RX_16_RESPONSE) {
			    		RxResponse16 rx16 = (RxResponse16) response;
//			    		System.out.println("rec. from:" + );
			    		int d[] = rx16.getData();
			    		logStream.println(
//			    		System.out.println(
System.currentTimeMillis()-baseTime + " " + rx16.getRemoteAddress().get16BitValue() + " " +d[0]+ ","+d[1]+","+d[2]);
			    	} else if( response.getApiId() == ApiId.TX_STATUS_RESPONSE ){
			    		// may want to check if our messages are correctly transfered... NOT NOW
			    		System.out.println("HEY!!"+ response.getApiId().toString());
			    	} else {
			    		System.out.println("Recv unexpected message type:"+ response.getApiId().toString());
			    	}
			    }
			});

		} catch (Exception e) {
			System.out.println("XBee failed to initialize");
			e.printStackTrace();
		}
	}

	public void broadcast(int i1, int i2){
		int[] a = new int[2];
		a[0] = i1;
		a[1] = i2;
		try {
			// save bandwidth, don't request any ack packets!
			TxRequest16 request = new TxRequest16(XBeeAddress16.BROADCAST,0, TxRequestBase.Option.DISABLE_ACK,a);
//		      TxRequest16 request = new TxRequest16(XBeeAddress16.BROADCAST,0,a);
		      xbee.sendAsynchronous(request);
		    } catch (Exception e){
		    	// Sometimes it fails to send..
		      //System.out.println("XBee failed to send");
		      //e.printStackTrace();
		    }
	}
}
