s.options.memSize_(2 << 19).maxNodes_(2048);
s.boot;

/*
I. HW
II. Bringing MIDI Messages into SuperCollider

MIDI (Musical Instrument Digital Interface) has been an indispensible component of electronic music
making since its release in 1983. With it, electronic music hardware of diverse brands and types can communicate
using a standardized set of instructions and data values. While OSC is technically more flexible---itself
a software protocol instead of hardware---MIDI is far from obsolete thanks to its ubiquity and ease of
implementation and use. While MIDI has gotten a bad rap over the years (does the phrase "MIDI sound"
seem familiar to you?), most of that comes from a fundamental lack of understanding among the general
public regarding what MIDI actually is. Remember, like OSC, MIDI doesn't generate sound. It is simply a
protocol that allows multiple sound-creating or -controlling pieces of hardware and software to talk
to each other. Those expensive orchestral sound libraries are just as "MIDI" as an early '90's Casio
wavetable synth!

For more information on MIDI, including docuentation on its specs, visit the official MIDI Association site:
https://www.midi.org

Like every multimedia programming language, SuperCollider is capable of both sending and receiving
MIDI messages, though in today's class we are only going to focus on the latter, as it is a property that
two of you have indicated is important to your projects. Using MIDI, you will be able to play
Synths that you create using a MIDI keyboard, adjust parameters of Synths and/or mix multiple Synths
together using a MIDI controller with faders, knobs, &c., and even advance cues in your piece or
trigger certain one-off events using a MIDI pedal.

First, as we are going to be using a virtual MIDI controller for the purposes of today's class, we are
going to need to download some software and create some virtual busses. There is a virtual MIDI keyboard
that is free and open source, and will work nicely for our purposes, called VMPK:

http://vmpk.sourceforge.net/#Download

Download the version appropriate for your platform and install it. Creating a virtual bus differs greatly on
platform. If you're using Windows (requires another piece of software) or Linux (depending on distro,
the software may or may not already be installed), follow the instructions outlined on the VMPK page. Oddly,
they do not list any directions for doing so in macOS, but thankfully the feature is built into the OS and
no further action is needed. (yay, Apple :) ) However, in VMPK's Edit > MIDI Connections you must select
CoreMIDI for Midi OUT.

Alternatively, if you purchased TouchOSC after last class, you can use that as a MIDI controller, or if you have another
MIDI controller on your person feel free to use that, too!

Let's check to see if we were successful:
*/

MIDIClient.init;

/*
If VMPK Output shows up as a MIDI Source and MIDI Destination, then congratulations! Everything's going according
to plan!

So we've initialized the client, but still haven't actually *connected* anything yet. That can be done quite simply.
Since we're only connecting one device, we can go ahead and enter the following commands:
*/

MIDIIn.connectAll;
MIDIClient.sources

MIDIdef.noteOn(\test, {"key down".postln});

//If you got "key down" messages when depressing keys on your virtual keyboard, great! If not, double-check your
//virtual MIDI cabling and try again. To disable the test, simply enter the following:

MIDIdef(\test).free;

//Now that we have our virtual keyboard connected, let's start making some sounds! The easiest way of doing this
//is to simply enclose a { }.play within a MIDIdef, like so:

(
MIDIdef.noteOn(\on, {|vel, note|
	[vel, note].postln; //not strictly necessary, but it can be helpful to see this information posted
	{|decay=0.5, pan=0|
		var sig = Impulse.ar(0.01);
		var env = Linen.kr;

		FreeSelfWhenDone.kr(Line.kr);
		Pan2.ar(Ringz.ar(sig, note.midicps, decay).lag(0.003), pan) * env * vel.linexp(1, 127, 0.01, 1)
	}.play;
})
)

/*
Of course, creating a new MIDIdef for every sound you wish to control would be tedious and ultimately
counterproductive. Much better would be to leave the MIDIdef as a means of bringing in relevant MIDI data,
and then having it control parameters in a Synth, or even multiple Synths, that you can turn on and off.
Let's begin by first transferring the above to the more flexible SynthDef format:
*/

(
SynthDef.new(\patch1, {|out=0, freq=440, decay=0.5, pan=0, amp=1|
	var sig = Impulse.ar(0.01);
	var env = Linen.kr;

	sig = Pan2.ar(Ringz.ar(sig, freq, decay).lag(0.003), pan) * env * amp;

	FreeSelfWhenDone.kr(Line.kr);
	Out.ar(out, sig)
}).add;

MIDIdef.noteOn(\on, {|vel, note|
	[vel, note].postln;
	Synth.new(\patch1, [\freq, note.midicps, \amp, vel.linexp(1, 127, 0.01, 1)])
}).permanent_(true)
)

/*
Like OSCdefs, MIDIdefs automatically clear when subjected to a cmnd-period. However, this can be circumvented by
appending .permanent_(true) to MIDIdefs. (As expected, .permanent_(false) undoes this action.)

This is great, but what if one wishes to perform sounds that sustain? .noteOn sends note on messages, but it is important
to note that releasing a key does NOT send a corresponding note off! Also, as it will be important to keep track of running
Synths so we can close their gates when .noteOff messages are received, we need to first define an array that can
accommodate all possible 7-bit MIDI note values into which these Synths can be placed:
*/

~keyboard = Array.newClear(128);

//Now we can create a new patch, alter our noteOn MIDIdef accordingly, and create a new noteOff MIDIdef:

(
SynthDef.new(\patch2, {|out=0, freq=440, amp=1, gate=0|
	var sig = LFTri.ar([freq, freq*2, freq*3, freq*4, freq*5], mul:[amp, amp*0.8, amp*0.4, amp*0.6, amp*0.2]);
	var env = EnvGen.kr(Env.adsr, gate, doneAction: 2);

	Out.ar(out, sig * env);
}).add;

MIDIdef.noteOn(\on, {|vel, note|
	[vel, note].postln;
	~keyboard[note] = Synth.new(\patch2, [
		\freq, note.midicps,
		\amp, vel.linexp(1, 127, 0.01, 1),
		\gate, 1
	])
});

MIDIdef.noteOff(\off, {|vel, note|
	"off".postln;
	~keyboard[note].set(\gate, 0);
	~keyboard[note] = nil; //needed for proper garbage collection
}).permanent_(true)
)

//Why not throw some pitch bend into the mix?

~bend = 8192; //Pitch wheel in neutral position. The necessity for this will become clear soon

(
SynthDef.new(\patch2, {|out=0, freq=440, amp=1, bend=0, gate=0|
	var sig = LFTri.ar(
		freq: [freq, freq*2, freq*3, freq*4, freq*5] * bend.midiratio,
		mul: [amp, amp*0.8, amp*0.4, amp*0.6, amp*0.2]
	);
	var env = EnvGen.kr(Env.adsr, gate, doneAction: 2);

	Out.ar(out, sig * env);
}).add;

MIDIdef.bend(\bend, {|val|
	val.postln;
	~bend = val;
	~keyboard.do{|synth| synth.set(\bend, val.linlin(0, 16383, -2, 2))}
}).permanent_(true);

MIDIdef.noteOn(\on, {|vel, note|
	[vel, note].postln;
	~keyboard[note] = Synth.new(\patch2, [
		\freq, note.midicps,
		\amp, vel.linexp(1, 127, 0.01, 1),
		\gate, 1,
		\bend, ~bend.linlin(0, 16383, -2, 2) //this is necessary in case the pitch bend wheel/slider is *not* at rest when depressing a note
	])
});
)

/*
Alright! Now we have a working MIDI keyboard with a patch all our own! Of course, playing additive synthesis Synths
is not the limit to what you can do. You can also use your keyboard as a sampler, triggering sound files with noteOn
messages and freeing them with noteOff; you could even use the pitch bender as a method to scrub through the
audio files!

As mentioned before, one can use a MIDI controller as a method to advance cues in a piece. A MIDI foot pedal is
a popular solution employed by composers writing for a live performer, but another, especially when a composer
might want to be in charge of advancing cues themselves, is by using a multi-button MIDI control surface.
Instead of note on and note off messages, in which case the button would technically be "stuck" when depressed
until the latter signal gets through, one should use continuous controller data so that the value when depressed---in
the case of a foot pedal or multi-button controller, this would be 127---returns to 0 as soon as the pedal/key is released.

First, let's test this out, using VMPK as our controller. Change control to '4 - Foot controller' and use the Value wheel
next to it to modulate the output. This isn't quite like hitting a button, but it will work well for our purposes.
*/

(
MIDIdef.cc(\pedal, {|val, num|
	[val, num].postln;
}).permanent_(true)
)

/*
As we can see, the value of the mod wheel is displayed in the first index of the array, while the second rests on 4 (as
it is the channel upon which our desired controller data lies). Let's now import three sound-producing functions from
before, and switch between them using the mod wheel of VMPK:
*/

~num = 1;

(
c = Dictionary.new;

c.add(\cue1 -> {
	Routine{
		~kirakira1 = {|rate=4, decay=0.5, amp=1, lag=0.003|
			var sig = Impulse.ar(rate, mul: amp);
			var seq = Dseq([69, 72, 76], inf);
			var freq = Demand.kr(Impulse.kr(rate), Dust.kr(rate * 0.4), seq.midicps * LFPulse.kr(rate * 0.1667, add: 1));
			var out = Pan2.ar(Ringz.ar(sig, freq, decay).lag(lag), LFNoise0.kr(rate));

			BenVerb.ar(out);
		}.play(fadeTime: 5);

		15.wait;

		~kirakira1.release;

		~kirakira2 = {|rate=8, decay=0.5, amp=1, lag=0.003, offset=1|
			var sig = Impulse.ar(rate, mul: amp);
			var seq1 = Dseq([69, 72, 76], inf);
			var seq2 = Dseq([79, 81, 84], inf);
			var freq1 = Demand.kr(Impulse.kr(rate), Dust.kr(rate * 0.4), seq1.midicps * LFPulse.kr(rate * 0.1667, add: 1));
			var freq2 = Demand.kr(Impulse.kr(rate * offset), Dust.kr(rate * 0.2), seq2.midicps * LFPulse.kr(rate * 0.1667, add: 1) * LFPulse.kr(rate * 0.08, add: 1));
			var out1 = Pan2.ar(Ringz.ar(sig, freq1, decay).lag(lag), LFNoise0.kr(rate));
			var out2 = Pan2.ar(Ringz.ar(sig, freq2, decay).lag(lag), LFNoise0.kr(rate));

			BenVerb.ar(Splay.ar([out1, out2]))
		}.play(fadeTime: 5);
	}.play
});

c.add(\cue2 -> {
	~kirakira2.release;

	~kirakira3 = {|rate=16, decay=0.1, amp=1, lag=0.003, offset=1|
		var sig = Impulse.ar(rate, mul: amp);
		var seq1 = Dseq([69, 72, 76], inf);
		var seq2 = Dseq([79, 81, 84], inf);
		var freq1 = Demand.kr(Impulse.kr(rate), Dust.kr(rate * 0.4), seq1.midicps * LFPulse.kr(rate * 0.1667, add: 1));
		var freq2 = Demand.kr(Impulse.kr(rate * offset), Dust.kr(rate * 0.2), seq2.midicps * LFPulse.kr(rate * 0.1667, add: 1) * LFPulse.kr(rate * 0.08, add: 1));
		var out1 = Pan2.ar(Ringz.ar(sig, freq1, decay).lag(lag), LFNoise0.kr(rate));
		var out2 = Pan2.ar(Ringz.ar(sig, freq2, decay).lag(lag), LFNoise0.kr(rate));

		BenVerb.ar(Splay.ar([out1, out2]))
	}.play(fadeTime: 5);
});

c.add(\cue3 -> {~kirakira3.release});

MIDIdef.cc(\pedal, {|val, num|
	[val, num].postln;
	if ((val == 127) && (num == 4)) {
		c[(\cue ++ ~num).asSymbol].value;
		~num = ~num + 1;
	}
})
)

/*
III. In-Class Assignment

Create a Synth or Synths of your own and control them in various ways with VMPK. Remember, you don't HAVE to
stick to typical conventions. For example, feel free to modulate other parameters than pitch with the pitch bender.