/*
I. Sending MIDI Messages out of SuperCollider

Last week we looked into how to route MIDI messages into SuperCollider, turning SuperCollider into an incredibly
versatile engine for a custom synthesizer/sampler, allowing one to control the flow of one's composition via
external hardware devices, and so on. This week we are going to be exploring the potential inherent in sending
MIDI data out of SuperCollider; in other words, having SuperCollider control some *other* synthesis/sampling engine
using its powerful algorithmic composition tools.

Since we're going to be using another piece of software to generate sound, for once we are not going to need
to boot the server! (Though you can if you would really like to; it won't hurt anything!) For ease of demonstration
and accessibility we are once again going to use VMPK, but keep in mind that you can use *any* synthesis engine
or sampler that accepts MIDI input, software or hardware.

To set up VMPK so it will accept incoming MIDI signals and output sound, follow these steps (macOS):

1. Open VMPK
2. Under Edit > MIDI Connections choose CoreMIDI for the MIDI In driver and FluidSynth for the MIDI Out driver.
3. Evaluate the following in SuperCollider:
*/

MIDIClient.init;
m = MIDIOut(0); //this sends MIDI messages out along MIDIchannel 1 (remember that SC is zero-indexed!)

/*
If you saw VMPK Input as a MIDI Destination then congratulations, you're in!

Windows and Linux users will need to set up virtual busses in a third-party utility like Jack. VMPK's website
has some suggestions as to how to go about doing this.

Once you've gotten everthing connected properly, let's test it!
*/

m.noteOn(0, 60, 127); //order of args: MIDIchannel-1, MIDInote, velocity (between 1 and 127!)
m.noteOff(0, 60);

/*
If you heard VMPK output a middle C---or really anything at all---then you know your connection is sound.
If not, check VMPK's MIDI settings and try again!

One thing to keep in mind with how SuperCollider handles MIDI messages: it, by default, imposes a 0.2 second delay on
all outgoing messages. This most likely has to do with ensuring that older hardware has time to properly receive and
interpret these messages. You can change the amount of latency by using the following method:
*/

m.latency_(0); //We're just sending these messages to VMPK, so we don't need any latency whatsoever.

//Let's use our new-found capability to play a chord!

(
Routine{
	[58, 60, 62, 65, 68].do{|note|
		m.noteOn(0, note, 127);
		0.5.wait;
	}
}.play;
)

//Of course, we should cancel these noteOn messages with corresponding noteOff instructions
//(especially if the sound you're using does not release while the noteOn message is active!)

(
Routine{
	[58, 60, 62, 65, 68].reverse.do{|note|
		m.noteOff(0, note);
		0.5.wait;
	}
}.play;
)

/*
Keep in mind that SuperCollider is *only* sending out MIDI messages. If you want to change the sound itself,
you're going to have to make changes on whatever MIDI device/in whatever MIDI software you're using.
SuperCollider is *not* acting as the synthesis engine in this case!

This can lead to a potentially awkward situation. Remember that SuperCollider sends both noteOn and noteOff
messages. However, let's say a message-generating routine terminates just before a necessary noteOff message
is sent, thus leading to a stuck note. You can't cmnd-period/ctrl-period your way out of this, as it won't do anything;
cmnd-period is the same as 's.freeAll', and the server isn't producing the sound; it isn't even running!
So, what can we do?

Thankfully, just like we can add certain functionality to the server boot, refresh, and quit routines (see class 6's notes),
we can also add functionality to the cmnd-period keystroke:
*/

CmdPeriod.add({(0..127).do{|note| m.noteOff(0, note)}});

//Alternatively, you can try this approach:

m.allNotesOff(0);

/*
But I find cmnd-period/ctrl-period feels better as a "panic" button of sorts, *and* it has the added effect of stopping running
routines, while m.allNotesOff *only* sends noteOff messages at that point in time; any routines in progress will still keep
playing. Nevertheless, sometimes m.allNotesOff may be a more elegant and appropriate solution.

Any MIDI message can be sent via MIDIOut, including continuous control messages. However, today I mainly
want to cover sending note information out. Feel free to experiment with MIDIOut.control if this functionality
is appropriate for your project!

This is all great, but MIDIOut's usefulness is limited if one has to go through the laborious process of coding
everything as a routine. One of SuperCollider's strengths is its facility in algorithmic music composition;
thankfully, one can very easily use Patterns to send MIDI data out.
*/

CmdPeriod.add({(0..127).do{|note| m.noteOff(1, note)}});

(
~vmpk = Pbind(*[
	type: 'midi',
	midicmd: 'noteOn',
	midiout: m,
	chan: 0,
	midinote: Pwrand([62, 69, 74, 81, 86], [0.2, 0.1, 0.4, 0.2, 0.1], inf),
	amp: 1,
	sustain: 0.07,
	dur: 0.15
]).play;
)

(
~vmpk2 = Pbind(*[
	type: 'midi',
	midicmd: 'noteOn',
	midiout: m,
	chan: 0,
	midinote: Pwrand([
		[60, 64, 66], 67, 69, [67, 70, 72], 62
	], [
		0.4, 0.1, 0.2, 0.1, 0.2
	], inf
	) + Prand([-12, 0, 12], inf),
	amp: Pxrand([0.2, 0.5, 0.7, 1], inf),
	dur: Pwrand([0.25, 0.333, 0.5, 0.667, 0.75, Rest(0.25)], [0.3, 0.2, 0.2, 0.1, 0.1, 0.1], inf),
	sustain: Pkey(\dur) * Prand([0.25, 0.5, 1], inf)
	]);
)

~vmpk2.play;

(
~vmpk3 = Pbind(*[
	type: 'midi',
	midicmd: 'noteOn',
	midiout: m,
	chan: 1,
	midinote: Pseq([60, 62, 67, 66, 70, 69, 67, 72], inf) * Pwrand([1, 2], [0.7, 0.3], inf),
	amp: Pbrown(0.1, 1),
	dur: Prand([0.25, 0.5, 1], inf),
	sustain: Pkey(\dur) * Pwrand([0.25, 0.5, 1], [0.1, 0.2, 0.7], inf)
]);
)

~vmpk3.play;

p = Ppar([~vmpk2, ~vmpk3]).play;

p.stop;

//II. In-class Project Work