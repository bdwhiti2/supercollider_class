s.boot;

/*
I. Buffers

From the description in the relevant help file:

"A buffer is most often used to hold sampled audio, such as a soundfile loaded into memory,
but can be used to hold other types of data as well. It is a globally available array of floating-point numbers on the server."

While one can engage in some basic audio processing on live audio signals by using SoundIn.ar in conjunction with some
time-domain processes (e.g. Delay, Allpass, FreeVerb), more advanced spectral processing, in addition to the ability to
play back and/or process sound performed in the past (even by only a split second), requires a volatile memory bank
allocated into which such data can be saved. This is what is referred to as a Buffer.

WARNING: It is important to understand that writing data to a buffer is not like writing data to disk storage. As mentioned above,
buffers are *volatile*; they do not reside in a temporary file on one's hard disk, they reside in your computer's RAM. Therefore,
any action taken that would reset a computer's internal memory bank---for instance, a shut down or reboot
(though typically NOT sleep mode)---will wipe all allocated buffers in SuperCollider. In fact, simply shutting down SuperCollider
will result in the same thing, as the application will send an instruction to your computer's operating system that the memory
the OS allocated to the language can now be freed for other tasks. Therefore, if one wishes to save a recording of one's piece
in SuperCollider, one should use a means of more permanent storage again like DiskOut* instead of Buffer. Buffers are intended
for the saving of short spurts of data for *a limited amount of time* in order to be accessible to time- and spectral-based
processes throughout a performance.

* This is not to imply that DiskOut is a superior method for saving real-tme audio for the purposes of live processing, as these
processes require for the relevant audio data to be stored in RAM. Therefore, even if one were to write this data to disk,
one would *still* need to read that same data from disk into an allocated Buffer. Writing to disk and writing to RAM are
two fundamentally different processes used for fundamentally different tasks.

While Buffers may sound complicated, thankfully, in SuperCollider, they are easy to set up and use. As Buffers require
the reservation of important CPU resources, and since SuperCollider has no way of predicting how many buffers you will
be using or how large they are going to need to be, the onus is on the programmer to provide the server this information.
For now, let us set up one audio buffer and place within it one of SuperCollider's sample audio files.
(MAKE SURE YOU'VE BOOTED THE SERVER BEFORE EVALUATING THE FOLLOWING LINE)
*/

b = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav"); //Platform.resourceDir is a shortcut for "path/to/SuperCollider.app/Contents/Resources/" (or whatever the equivalent is in Windows)

/*
This may look imposing, but this is what is being told the computer: To be placed into interpreter variable b, have the server (s) read the
file "path/to/SuperCollider.app/Contents/Resources/sounds/a11wlk01.wav". For instance, if one were going to make use of a sound file
named "example.wav" that's on one's desktop, one would write the following (in macOS/Linux):
*/

b = Buffer.read(s, "~/Desktop/example.wav");

/*
Now the buffer is properly allocated and the desired sound file is placed within. Not too hard, was it? :)

Playing back the contents of an audio buffer requires the use of a playback UGen. There are two options in SuperCollider
to do so: PlayBuf, and BufRd. Of these two options, PlayBuf is simpler, and is fine when wanting to simply play back stored sound data.
However, we will be concentrating on BufRd, as it is ultimately more flexible and powerful (and not that much more difficult
to use). The syntax for BufRd is as follows:
*/

BufRd.ar(numChannels, bufnum, phase, loop, interpolation);

/*
Arguments:
numChannels: The number of audio channels contained in the buffer (1 for mono, 2 for stereo, 4 for quad, &c.)
bufnum: The index of the desired buffer.
phase: The pointer used to scrub through the buffer. It is a 24-bit pointer, therefore it won't work for buffers greater than 6.3 minutes at a 44100Hz sample rate. (One shouldn't even be using buffers that long, anyway)
loop: 1 == loop, 0 == do not loop
interpolation: 1 == none, 2 == linear, 4 == cubic

Inexplicably, unlike its cousin PlayBuf, BufRd does not feature a doneAction argument, so if you set loop to 0 and wish for the
Synth to free itself once the buffer is through playing back, you will have to use the FreeSelfWhenDone class instead,
or apply an envelope and make use of the doneAction argument within EnvGen.
(FreeSelfWhenDone functions identically to doneAction: 2.)
*/

(
x = {
	var buf = BufRd.ar(1, b, Phasor.ar(0, BufRateScale.ir(b), 0, BufFrames.ir(b)), 0); //use .kr instead if you plan on changing the buffer while the Synth is playing

	FreeSelfWhenDone.kr(buf); //helpful if loop is set to 0, as it is here, but pointless if loop is set to 1
	buf
}.play;
)

/*
The above function scrubs through the buffer at its sample rate, thus playing it through beginning to end at full speed.
The pointer can be any audio rate UGen, though for simplicity's sake we're using Phasor, which, in the context of
BufRd, operates as follows:
*/

Phasor.ar(trig, rate, start, end, resetPos);

/*
Arguments:
trig: When condition is met, jump to resetPos.
rate: How fast the Phasor scrubs through the buffer. The default is '1', though this can nevertheless lead to less- or greater-than-full-speed
        playback if the server sample rate != audio file sample rate. BufRateScale mitigates this issue by scaling the sample rate of the
        buffer to match the server's sample rate.
start: The desired frame to commence playback. Note that the first frame is 0, *not* 1 (can make a difference in certain situations, such as reverse playback)
end: The desired frame in which playback will cease.
resetPos: The frame to jump to when the trig conditional is met.

I'd like to take this opportunity to go off on a small tangent and discuss the .ir method, which calls upon the third of SuperCollider's four
data streaming rates to be discussed. .ir stands for Initialization Rate, which is by far the least active of the four. Where .ar streams
at the server sample rate and .kr streams at the server control rate (1/64 the server sample rate), .ir reads from a data stream
only once, when first evaluated, and continues to stream that initial value until the Synth is reevaluated. This leads to real
CPU cycle savings when appropriately used, as the CPU usage to maintain one single value in memory is truly negligable when
compared to calling upon a UGen to supply updated values at even the control rate, which is 689 times a second (at a 44100Hz
sample rate)! Nevertheless, the number of UGens that support initialization rate is vanishingly small, and sometimes one might
wish to use control rate anyway, especially if there is a chance a UGen's value might change at some point during performance.
If one were to expect to alter the buffer read by this.b at some point, then .kr would be the method to use, as it would be
highly unlikely that the new audio file would be of the precise sample rate and duration of the old file.

Playing through a buffer at full speed is great, but if that's all one wanted to do, then PlayBuf would make for the simpler
solution. Let's instead write a Synth that uses the X coordinate of the mouse pointer to adjust playback rate through the sound file.
We'll turn looping on; as such, FreeSelfWhenDone is no longer needed, thus simplifying our function somewhat.
*/

x = {BufRd.ar(1, b, Phasor.ar(0, MouseX.kr(-2, 2) * BufRateScale.ir(b), 0, BufFrames.ir(b)), 1)}.play;
x.free;

/*
Another neat effect is to use the trackpad to literally scrub through the audio file. Here, the X coordinate of the mouse
pointer is mapped to specific frames throughout the audio file, and the Y coordinate determines how smoothly playback
will be. BufRateScale is not needed here, as playback is not occuring in the traditional sense. Think of one's trackpad as
magnetic audio tape, and one's index finger as a tape player's playback head.
Cubic interpolation is used to ensure the smoothest possible playback (despite its additional CPU usage).
*/

x = {BufRd.ar(1, b, K2A.ar(BufFrames.ir(b) * MouseX.kr.lag(MouseY.kr)), interpolation: 4)}.play;
x.free;

//K2A is a UGen that upsamples control rate data to the server's audio sample rate, as BufRd requires an audio rate pointer to work.

/*
As mentioned previously, one can use a myriad of audio rate UGens to index through an audio buffer. As such, one can
achieve some neat effects. Compare the following:
*/

x = {BufRd.ar(1, b, SinOsc.ar(0.1, mul: BufFrames.ir(b)))}.play;
x.free;

x = {BufRd.ar(1, b, LFNoise1.ar(5, mul: BufFrames.ir(b)))}.play;
x.free;

x = {BufRd.ar(1, b, SinOscFB.ar(0.1, 0.5pi, mul: BufFrames.ir(b)))}.play;
x.free;

x = {BufRd.ar(1, b, HenonL.ar(SinOsc.kr(0.5).range(0.5, 5), mul: BufFrames.ir(b)))}.play;
x.free;

//Feel free to experiment with more! (Note: despite the claims of the documentation, not every audio rate UGen works with BufRd)

//Another example:

(
b = Array.newClear(3);
b[0] = Buffer.read(s, "/Users/benjaminwhiting/Dropbox/Sound Files/Found Sounds/dolphins.aif");
b[1] = Buffer.read(s, "/Users/benjaminwhiting/Dropbox/Sound Files/Found Sounds/apes.aif");
b[2] = Buffer.read(s, "/Users/benjaminwhiting/Dropbox/Sound Files/Found Sounds/pigs.aif");
c = Bus.control(s);
)

(
SynthDef.new(\zoo, {|bufnum, out=0, speed=1, amp=0.333|
	var rate = speed * BufRateScale.ir(bufnum);
	var pos = Phasor.ar(0, rate, 0, BufFrames.ir(bufnum));
	var sig = BufRd.ar(2, bufnum, pos);

	Out.ar(out, sig * amp);
}).add;
)

g = Group.new; //By adding a group and adding Synths to it, we are able to give commands to multiple Synths at once instead of setting each Synth one at a time.

x = Synth.new(\zoo, [\bufnum, b[0]], g);
y = Synth.new(\zoo, [\bufnum, b[1]], g);
z = Synth.new(\zoo, [\bufnum, b[2]], g);

g.set(\speed, 0.9);
g.set(\bufnum, b[0]);
x.set(\speed, 1.2);
y.set(\speed, 1.6);
z.set(\speed, 0.4);

(
~variable_rate = {
	Out.kr(c, LFNoise2.kr(0.3).range(0.3, 2.0))
}.play;
)

x.map(\speed, c);

s.freeAll;

//CHALLENGE: What's happening here?
//(Note: requires the SC3 Extensions package in order to run)

b = Buffer.read(s, "/Users/benjaminwhiting/Documents/Sound Files/Jiyeon original.aif");

(
SynthDef.new(\bubblies2, {|out=0, filter=0.5, freq=220, gate1=0, t_gate2=0, dogBiscuits=(-60),
	pitch_curvelength=0.33, threshold=0.5, amp=0.9|
	var trigs, buf;
	var pitch, bubbles;
	var chain, h2o;
	var hasFreq;
	var numbins = 1024;
	var max_threshold = SampleRate.ir * (0.5 / numbins);
	var bubble_wand = Array.fill(200, 0);
	var pan = LFNoise0.kr(3);
	var sig_in = BufRd.ar(2, b, Phasor.ar(0, BufRateScale.ir(b), 0, BufFrames.ir(b)), 0);
	var env = EnvGen.kr(Env.asr, gate1);
	var amp_sig = Amplitude.kr(sig_in);
	var schmidt = Schmidt.kr(amp_sig, dbamp(dogBiscuits - 1), dbamp(dogBiscuits));

	[29, 37, 47, 67, 89, 113, 157, 197].do{|i|
		bubble_wand.put(i, 1);
	};
	Array.fill(64, {|i| rrand(i+1, 199)}).do{|i|
		bubble_wand.put(i, 1);
	};
	Array.fill(12, {|i| i*16}).do{|i|
		bubble_wand.put(i, 1);
	};

	buf = bubble_wand.as(LocalBuf);

	trigs = PlayBuf.kr(1, buf, 0.015.reciprocal / (s.sampleRate / s.options.blockSize), loop: 1);
	trigs = CoinGate.kr(filter, trigs);

	SendReply.kr(Impulse.kr(10), '/spumante', schmidt);
	SendReply.kr(trigs, '/champagne', 1);

	#freq, hasFreq = Tartini.kr(sig_in); //requires SC3 Extensions, though one *could* make do with Pitch.kr instead
	freq = freq * 0.75;
	freq = freq.fold(180, 666);
	amp = amp * EnvGen.ar(Env.perc(releaseTime: 0.08).delay(0.003), t_gate2);
	pitch = freq * EnvGen.ar(Env.new([0, 0, 1], [0, 1]).exprange(1, 2.718), t_gate2, timeScale: pitch_curvelength);
	pitch = pitch.fold(180, 1060);

	bubbles = SinOsc.ar(pitch);
	bubbles = HPF.ar(bubbles, 180, amp) * 0.5;
	bubbles = Pan2.ar(bubbles, pan);
	bubbles = BenVerb.ar(bubbles, 0.06, revtime: 3, lpf: 3000); //if you want to run this on your own machines, change this line to another reverb of your choice

	chain = FFT(LocalBuf(numbins), sig_in);
	chain = PV_PhaseShift(chain, 180);
	chain = PV_PartialSynthF(chain, threshold * max_threshold); //requires SC3 Extensions
	h2o = IFFT(chain);
	h2o = LPF.ar(h2o, 2000, amp) * 10;
	h2o = Pan2.ar(h2o, pan);
	h2o = BenVerb.ar(h2o, 0.03, lpf: 3000); //ditto line 242

	Out.ar(out, XFade2.ar(sig_in * 0.5, bubbles * env, MouseX.kr(-1, 1)));
	Out.ar(out, XFade2.ar(sig_in * 0.5, h2o * env, MouseX.kr(-1, 1)));
}).add;

OSCdef.new(\verdi, {|msg|
	s.sendMsg("/n_set", 0, \gate1, msg[3]);
}, '/spumante');

OSCdef.new(\dom_perignon, {|msg|
	if (msg[3] == 1) {
		s.sendMsg("/n_set", 0, \t_gate2, msg[3])
	}
}, '/champagne');
)

x = Synth.new(\bubblies2);
x.free;

/*
II. OSC part 2

As mentioned in last week's class, the beauty of OSC lies not only in the facility it gives the SuperCollider programmer in
implementing looping conditionsls within their code (a mere fortuitous side effect, really), it allows one to be able to
control one's Synths from other programming languages and applications that are able to send OSC messages across
a computer network. To demonstrate, I am going to control the following Synth using my iPhone equipped with TouchOSC.

First, the Synth:
*/

(
SynthDef.new(\kirakira, {|out=0, rate=1, decay=0.5, offset=7, exOctave=0, amp1=0, amp2=0, lag=0.003|
	var sig = Impulse.ar(rate);
	var seq1 = Dseq([74, 76, 78], inf);
	var seq2 = Dseq([74, 76, 78] + offset, inf);
	var freq1 = Demand.kr(Impulse.kr(rate), Dust.kr(rate * 0.4), seq1.midicps * LFPulse.kr(rate * 0.1667, add: 1 + exOctave)); //We'll go over demand rate, the fourth of four data streaming rates in SC, in a subsequent class
	var freq2 = Demand.kr(Impulse.kr(rate), Dust.kr(rate * 0.2), seq2. midicps * LFPulse.kr(rate * 0.1667, add: 1 + exOctave));
	var out1 = Pan2.ar(Ringz.ar(sig, freq1, decay).lag(lag), LFNoise0.kr(rate)) * amp1;
	var out2 = Pan2.ar(Ringz.ar(sig, freq2, decay).lag(lag), LFNoise0.kr(rate)) * amp2;

	Out.ar(out, Splay.ar([out1, out2]));
}).add;
)

/*
Next, the OSCdefs. Notice that, due to the nature of TouchOSC, in which each control gets assigned its own path, we need
to have a responder node for each parameter we wish to control in the Synth. Thankfully, copy and paste exists.
*/

(
OSCdef.new(\kirarate, {|msg|
	var rate = msg[1].linlin(0, 1, 1, 12);

	rate.postln;
	x.set(\rate, rate);
}, '/1/fader1');

OSCdef.new(\kiradecay, {|msg|
	var decay = msg[1];

	decay.postln;
	x.set(\decay, decay);
}, '/1/fader2');

OSCdef.new(\kiraoffset, {|msg|
	var offset = msg[1].linlin(0, 1, 0, 14).round(1);

	offset.postln;
	x.set(\offset, offset);
}, '/1/fader3');

OSCdef.new(\kiraexOct, {|msg|
	var exOctave = msg[1].round(1);

	exOctave.postln;
	x.set(\exOctave, exOctave);
}, '/1/fader4');

OSCdef.new(\kiraamp1, {|msg|
	var amp1 = msg[1];

	amp1.postln;
	x.set(\amp1, amp1);
}, '/1/rotary2');

OSCdef.new(\kiraamp2, {|msg|
	var amp2 = msg[1];

	amp2.postln;
	x.set(\amp2, amp2);
}, '/1/rotary3');
)

//Now, let us try it out!

x = Synth.new(\kirakira);
x.free;