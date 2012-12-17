

/*
 *	MidiInDump.java
 *
 *	This file is part of jsresources.org
 */

/*
 * Copyright (c) 1999 - 2001 by Matthias Pfisterer
 * Copyright (c) 2003 by Florian Bomers
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
|<---            this code is formatted to fit into 80 columns             --->|
*/

import java.io.IOException;

import java.util.Timer; 
import java.util.Scanner;

import javax.sound.midi.Transmitter;
//import javax.sound.midi.Receiver;
import javax.sound.midi.MidiUnavailableException;
import javax.sound.midi.MidiDevice;
import javax.sound.midi.MidiSystem;
import javax.sound.midi.Receiver;

public class ControlPC
{
	private static boolean		DEBUG = true;
	public static Timer autoMidi = null;
	public static TraktorReceiver r;
	public static XBeeHelper xbeeHelper;

	public static void main(String[] args)
		throws Exception
	{
		MidiCommon.listDevices(true, false);

		Scanner inScanner = new Scanner(System.in);
		
		MidiDevice traktorDevice = null;
		MidiDevice lpd8Device = null;
		Receiver rcvLPD8 = null;
		TraktorReceiver rcvTractor = null;
		
		// ********************************************************************************
		// Initialize XBee Module
		{
			out("Initializing XBee module...");
			xbeeHelper = new XBeeHelper();
		}

		// ********************************************************************************
		// Start listening to Traktor MIDI messages
		{
			out("Attaching to Traktor Virtual MIDI Channel...");
			MidiDevice.Info	info;
			info = MidiCommon.getMidiDeviceInfo("In From MIDI Yoke:  3", false);
//			info = MidiCommon.getMidiDeviceInfo("LoopBe Internal MIDI", false);		
			if (info == null) {
				out("Traktor MIDI device not found");
//				System.exit(1);
			}
			try {
				traktorDevice = MidiSystem.getMidiDevice(info);
				traktorDevice.open();
			} catch (MidiUnavailableException e) {
				out(e);
			}
			if (traktorDevice == null) {
				out("Wasn't able to retrieve Traktor MidiDevice");
				System.exit(1);
			}
			rcvTractor = new TraktorReceiver();
			try {
				Transmitter	t = traktorDevice.getTransmitter();
				t.setReceiver(rcvTractor);
			} catch (MidiUnavailableException e) {
				out("wasn't able to connect the device's Transmitter to the Receiver:");
				out(e); 
				traktorDevice.close();
				System.exit(1);
			}
		}
		// ********************************************************************************
		// Start listening to LPD8 MIDI messages
		{
			out("Attaching to LPD8 Virtual MIDI Channel...");
			MidiDevice.Info	info;
			info = MidiCommon.getMidiDeviceInfo("In From MIDI Yoke:  1", false);
//			info = MidiCommon.getMidiDeviceInfo("LPD8", false); // NEVER USE THIS, USE MIDI_OX INSTEAD!
			if (info == null) {
				out("LPD8 MIDI device not found");
				System.exit(1);
			}
			try {
				lpd8Device = MidiSystem.getMidiDevice(info);
				lpd8Device.open();
			} catch (MidiUnavailableException e) {
				out(e);
			}
			if (lpd8Device == null) {
				out("Wasn't able to retrieve LPD8 MidiDevice");
				System.exit(1);
			}
			rcvLPD8 = new LPD8Receiver();
			try {
				Transmitter	t = lpd8Device.getTransmitter();
				t.setReceiver(rcvLPD8);
			} catch (MidiUnavailableException e) {
				out("wasn't able to connect the device's Transmitter to the Receiver:");
				out(e); 
				lpd8Device.close();
				System.exit(1);
			}
		}

		out("now running; interupt the program with [ENTER] when finished");

		try {
			while(true){
				int iChar = System.in.read();
				if(iChar=='z') break;
				if(iChar=='h'){
					int bpm = inScanner.nextInt();
					float period = 60000.f/bpm;
					period = period/32;
					if(autoMidi!=null) autoMidi.cancel();
					autoMidi = new Timer(true);
					autoMidi.schedule(new AutoMidiTask(), 10, (long) period);
					System.out.println("started auto-midi generation on "+ bpm+ " bpm");
				} else if(iChar=='q'){
					xbeeHelper.broadcast(LPD8Receiver.DISP_TYPE,1);
				} else if(iChar=='w'){
					xbeeHelper.broadcast(LPD8Receiver.DISP_TYPE,2);
				} else if(iChar=='e'){
					xbeeHelper.broadcast(LPD8Receiver.DISP_TYPE,3);
				} else if(iChar=='r'){
					xbeeHelper.broadcast(LPD8Receiver.DISP_TYPE,4);
				} else if(iChar=='t'){
					xbeeHelper.broadcast(LPD8Receiver.DISP_TYPE,5);
				} else if(iChar=='y'){
					xbeeHelper.broadcast(LPD8Receiver.DISP_TYPE,6);
				} else if(iChar=='u'){
					xbeeHelper.broadcast(LPD8Receiver.DISP_TYPE,7);
				} else if(iChar=='i'){
					xbeeHelper.broadcast(LPD8Receiver.DISP_TYPE,8);
				} else if(iChar=='b'){
					rcvTractor.beatMult = 0; 
				} else if(iChar=='n'){
					rcvTractor.beatMult = 1; 
				} else if(iChar=='m'){
					rcvTractor.beatMult = 2;
				} else if(iChar=='9'){
					xbeeHelper.broadcast(LPD8Receiver.VIBRATE_STATE,0);
					xbeeHelper.broadcast(LPD8Receiver.VIBRATE_STATE,0);
				} else if(iChar=='0'){
					xbeeHelper.broadcast(LPD8Receiver.VIBRATE_STATE,1);
					xbeeHelper.broadcast(LPD8Receiver.VIBRATE_STATE,1);
				} else if(iChar=='7'){
					xbeeHelper.broadcast(LPD8Receiver.VIBRATE_FORCE,0);
					xbeeHelper.broadcast(LPD8Receiver.VIBRATE_FORCE,0);
				} else if(iChar=='8'){
					xbeeHelper.broadcast(LPD8Receiver.VIBRATE_FORCE,1);
					xbeeHelper.broadcast(LPD8Receiver.VIBRATE_FORCE,1);
				} else if(iChar==10 || iChar==13){
					continue;
				} else {
					autoMidi.cancel();
//					System.out.println("iChar:"+iChar);
				}
			}
		} catch (IOException ioe) {
		}
		traktorDevice.close();
		lpd8Device.close();
		try {
			Thread.sleep(1000);
		} catch (InterruptedException e) {
			if (DEBUG) { out(e); }
		}
	}

	private static void out(String strMessage) {
		System.out.println(strMessage);
	}

	private static void out(Throwable t) {
		if (DEBUG) {
			t.printStackTrace();
		} else {
			out(t.toString());
		}
	}
}



/*** MidiInDump.java ***/

