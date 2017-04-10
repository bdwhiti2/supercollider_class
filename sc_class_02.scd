/*
I. Intro to Class
II. Brief reintroduction to SuperCollider
  • booting the server
The interpreter variable 's' is automatically reserved for SuperCollider's synthesis server. Therefore, all you need to do after booting the
IDE is to type the following:
*/

s.boot;

/*Once you initiate the server's boot sequence, the post window will come alive with plenty of scrolling text. Keep an eye on it
for errors, but as long as the server information widget on the bottom right corner of the IDE shows an active green-on-black
display of statistics, everything should be fine.
If ever you wish to clear all running processes on the server---mainly if you find a particular sound gets "stuck", or if things
get WAY too loud and you're in a panic, simply press the keys CMND-period (CTRL-period on Windows/Linux) or type the following: */

s.freeAll;

//To shut down the server, type the following:

s.quit;

//While it is possible to change the value of 's' to be anything else you want, it is generally a bad idea to unassign it from Server.default.
//If this happens by accident, simply evaluate the following line to reassign the default server to 's':

Server.default = s = Server.local;

/*
  • { }.play;
The easiest way to get sound out of SuperCollider is to wrap a unit generator---UGen for short---in two curly braces, thus creating a function,
appending .play, and assigning this all to a variable, like in the following examples:
*/

//You can access help by either typing CMND-d with the cursor over a UGen name, or SHIFT-CMND-d and then type
//in the UGen you wish to look up.

x = {SinOsc.ar(330, 0, 0.4)}.play; //This plays a sine wave at 330Hz, with no alterations to phase, and at 40% amplitude.
x.free; //Make sure to evaluate x.free each time before moving to the next example.

//The following sine wave oscillator is controlled by another sine wave oscillator, at the control rate, oscillating at 5Hz with the resulting values
//scaled between 330 and 550Hz, also at 40% amplitude:
x = {SinOsc.ar(SinOsc.kr(5).exprange(330, 550), mul: 0.4)}.play;
x.free;

//This plays a sine wave at 880Hz, and employs phase modulation to distort the sound.
x = {SinOsc.ar(880, SinOsc.ar(XLine.kr(1, 1000, 9), 0, 2pi), 0.2)}.play;
x.free;

//The third example above can be rewritten, albeit with more lines of code, more clearly and transparently:

( //Whenever you wish to execute multiple lines of code at once, you should enclose the code in parentheses
x = {
	var modulator; //Local variables must be declared first with a 'var' tag before they can be used

	modulator = SinOsc.ar(XLine.kr(1, 1000, 9), 0, 2pi); //Here we store the controlling sine wave oscillator in its own variable, in order to achieve clarity and alleviate clutter in the following line

	SinOsc.ar(880, modulator, 0.2); //The final line in a function is what gets output by the post window and/or the audio playback system
}.play;
)

x.free;

/*Incidentally, because the controlling oscillator goes well beyond half the default control rate frequency of scsynth, we either need to up the
audio sample rate of the system if we really want to use control rate, or we give the task to an audio rate oscillator instead.
There will be times in which the CPU resource gains of control rate might compel us to do the former, but for now, an audio
rate controller will do. (Remember the Nyquist Theorem?)

• Filters

Filters allow you to zero in on a frequency and attenuate parts of the signal that lie below, above, or in a certain area around it.
These provide the foundation of subtractive synthesis.
*/

x = {Saw.ar(200, 0.1)}.play; //First let's listen to an unfiltered sawtooth wave
x.free;

x = {HPF.ar(Saw.ar(200, 0.1), 1600)}.play; //Here's the same sawtooth wave run through a high-pass filter, only letting through all constituent frequencies 1600Hz and above
x.free;

x = {LPF.ar(Saw.ar(200, 0.1), 1600)}.play; //Now through a low-pass filter, only letting through constituent frequencies 1600Hz and below
x.free;

x = {HPF.ar(Saw.ar(200, 0.1), FSinOsc.kr(XLine.kr(0.7, 300, 20), 0, 3600, 4000), 5)}.play; //Complex modulation of the cutoff frequency
 x.free;

x = {BPF.ar(Saw.ar(200, 0.5), MouseX.kr(100, 10000, 1), 0.3)}.play; //Now running through a band-pass filter...

x = {BRF.ar(Saw.ar(200, 0.5), MouseX.kr(100, 10000, 1), 0.3)}.play; //...and a band-reject filter

/*
III. Bussing
  • audio vs control rate busses
While one could use the obvious vehicular analogy when discussing managing signal flow in electronic audio,
I find a more salient---if not appropriate---metaphor is the audio patch cable. When one "busses" signals in SC,
one is inserting a subset of the data being generated into a dedicated "cable" that transfers that data from
one module---in this case, a Synth---to another.

There are two kinds of busses in SuperCollider: audio and control rate busses. These are meant to match the
two most commonly used signal flow rates in the language (initialization rate is not bussed as it is only calculated
upon initialization, and signals to advance demand rate are still given via the control rate). Since the bandwidth
requirements for each signal flow rate is vastly different, and since you never want to mix the two*,
SuperCollider provides separate kinds of these "patch cables" so you're not accidentally routing audio to
control an oscillator, or streaming arrays of integers to one's delicate speakers.

* -- Sometimes the brave soul might want to do this for various glitchy effects, but try this at your own risk!

    • Audio rate bussing

SuperCollider reserves, by default, audio busses 0 and 1 for stereo playback. This can be changed in the server
settings prior to server boot, but unless one is playing back to a surround-sound system, there is no need to do so.
When enclosing a UGen within a function and calling upon the play method, SuperCollider automatically busses
the first output channel to audio bus 0 (corresponding to the left channel), and if it is a stereo signal,
it assigns the second channel to audio bus 1 (right channel). It is important to note that *all* busses in SuperCollider,
UNLIKE in many DAWs, &c., are MONOPHONIC, but SuperCollider automatically pairs busses together when
multiple channels of playback are necessary. This ends up being far more of a boon than anything, as it means
that one can work with mono- and multiphonic signals simultaneously and with little effort.

    • Control rate bussing

Typically less commonly used, but still important, is the control rate bus. SuperCollider keeps these quarantined
from the audio rate bus pool, mainly so that one might not accidentally damage equipment and/or hearing if
control data (which really could be anything) were to be routed to a set of speakers. Therefore, control bus 0
and audio bus 0 are fundamentally different kinds of "patch cables," and therefore do not correspond with each other.
However, unlike with audio bussing, SuperCollider does not automate any control data routing in the { }.play method
of Synth creation, so the Out UGen must be used. (to be covered below)

IV. SynthDefs
  • Why use SynthDefs over function-play?

SynthDefs allow for more complex synthesis by creating a template for a Synth that can be instantiated any number of times,
and interconnected with other Synths to provide some truly deep textures. Using SynthDefs can also allow you to customize
signal flow far more easily than with { }.play, allowing you to be able to alternate effects, controllers, &c. on the fly.
Their extra flexibility and customizability does require a few extra steps be done by hand
(such as having to use an Out UGen in order to produce sound), but as they will become necessary for certain algorithmic
processes later in the course, and make more complex interconnections between applications much easier,
I recommend using SynthDefs whenever possible. (Continuing to use { }.play for quick and easy testing is okay, however)

  • Out.ar/.kr

Out is the UGen necessary to bus the resulting audio signal to either another Synth for further processing, or to the
computer's audio output system. { }.play takes care of this for you if all you want to do is output sound to your speakers,
but if you're using SynthDefs, or if you are using { }.play and want to output to a control bus, you are going to need
to use Out.
*/

//Let's first return to our "Hello world" Synth:

x = {SinOsc.ar(mul: 0.5)}.play; //Remember that the default frequency for SinOsc is 440Hz
x.free;

//The { }.play notation is actually just a shortcut for the following:

(
SynthDef.new(\hello_world, { //Every SynthDef needs a name, which can either begin with a \ or be enclosed in ' ', and which needs a lowercase letter as its first alphanumeric character
	var signal; //Remember: variable declaration MUST precede all other code!

	signal = SinOsc.ar(mul: 0.5);

	Out.ar(0, signal); //Here we are telling scsynth to output the sine wave along audio bus 0, which connects to the left channel of our audio output system.
}).add; //SynthDefs must be added to the server before they can be used.

x = Synth.new(\hello_world); //This line instantiates playback of the SynthDef as a Synth.
)

x.free; //Clearly, for something as trivial as this, { }.play is the better choice.

/*Another benefit to the use of SynthDefs is the ability to change the values of various arguments as the Synth is playing.
Note that arguments must be the *first* items declared---even before variables! There are two different ways one can declare
arguments:

• By using the "arg" tag, with the line ending in a semicolon -- arg freq=50, amp=1;
• By bookending the arguments with vertical lines, WITHOUT a semicolon -- |freq=50, amp=1|

I prefer the second method as it helps arguments, which are inherently different than variables, stand out as such,
but to each their own. Unlike variables, which can use as many lines and var tags as one would like, arguments
MUST be declared by ONLY using either one arg tag or one set of | | bookends, even if you do choose to use multiple lines.
Therefore, the following is LEGAL:

arg out=0, freq=440, amp=0.5;

|out=0, freq=440, amp=0.5|

But the following is ILLEGAL:
arg out=0, freq=440;
arg amp=0.5;

|out=0, freq=440|
|amp=0.5|

(The following SynthDef comes courtesy of Eli Fieldsteel, very slightly modified, and is a brilliant exposition to the basic capabilities of SynthDefs.)*/

//We begin by declaring some default arguments: the frequency of the LFPulse UGens that control the amplitude, the fundamental frequency,
//the highest partial that will be generated, the width of the Pulse waves, and finally the master amplitude of the Synth itself.
//The reason why we declare these as arguments instead of variables is that we want to be able to modulate---or change---them
//while the Synth is running. Variables are immutable upon compilation; arguments are not.
(
SynthDef.new(\pulseTest, {|ampHz=4, fund=40, maxPartial=4, width=0.5, amp=1|
	var amp1, amp2, freq1, freq2, sig1, sig2; //Here must declare the variables we're going to be using in the SynthDef

	amp1 = LFPulse.kr(ampHz, 0, 0.12, 0.75); //This produces a low-frequency pulse wave, at the control rate, oscillating at whatever frequency ampHz is set to at any given point in time.
	amp2 = LFPulse.kr(ampHz, 0.5, 0.12, 0.75); //This does the same, though offsets the phase by half (so that it oscillates when the other LFPulse UGen rests)
	freq1 = LFNoise0.kr(4).exprange(fund, fund * maxPartial).round(fund); //Now we assign a non-interpolating low-freq noise generator to freq1, which randomly produces a value between the fundamental pitch and whatever partial is currently declared as maxPartial, rounded to that partial.
	freq2 = LFNoise0.kr(4).exprange(fund, fund * maxPartial).round(fund); //Even though both freq1 and freq2 SEEM identical, they will be using two independent LFNoise0 UGens, therefore their frequency values will remain distinct

	freq1 = freq1 * LFPulse.kr(8, add: 1); //This will enable periodic octave jumps, as eight times a second (six times for the second signal) the frequency will either be multiplied by 1 or by 2
	freq2 = freq2 * LFPulse.kr(6, add: 1); //(Typically LFPulse returns either 0 or 1, but using the add: argument here allows us to offset the result)

	sig1 = Pulse.ar(freq1, width, amp1); //Finally we are ready to define our audio signals. Our first signal uses the operations defined above for freq1, width, and amp1 to set up the audio rate Pulse wave,
	sig2 = Pulse.ar(freq2, width, amp2); //while the second signal makes use of the variables freq2, width, and amp2. As amp2 has its phase offset by half, both signals are going to be alternating with one another.

	sig1 = FreeVerb.ar(sig1, 0.7, 0.8, 0.25); //Now we're adding reverb to both signals to help it sound richer and in a more believable aural environment.
	sig2 = FreeVerb.ar(sig2, 0.7, 0.8, 0.25);

	Out.ar(0, sig1 * amp); //We patch the first signal through audio bus 0 so that it outputs from the left channel,
	Out.ar(1, sig2 * amp); //while we patch the second through audio bus 1 so that it emanates from the right channel.
}).add;
)

x = Synth.new(\pulseTest, [\ampHz, 2]); //We launch an instance of our new Synth, altering the ampHz argument from the get go so that it oscillates twice a second instead of four times (thus slowing down the pulse waves).

x.set(\ampHz, 4); //As the Synth is playing, we return the frequency of the pulse waves back to its default setting...
x.set(\ampHz, 8); //...and now double the tempo.
x.set(\maxPartial, 12); //Only moving up to the fourth partial gets stale quite quickly, so we increase the maxPartial argument to 12.
x.set(\width, 0.375); //We narrow the width of the pulse waves.
x.set(\fund, 60); //Now we alter the fundamental frequency of the pulses.
x.set(\amp, 0.5); //Finally, we attenuate the output by half,
x.free; //and then free the Synth.

//It is a very good idea, whenever generating or running sound through SuperCollider, to make use of a limiter to prevent accidental
//damage to equipment, whether mechanical, electrical, or biological. Let's make one now:

(
SynthDef.new(\limiter, {|in=0, out=0|
	var sig_in, leaked, limited;

	sig_in = In.ar(in, 2); //Here we make use of the In UGen, which is the complement to Out (in that it brings a signal stream INTO the Synth)
	leaked = LeakDC.ar(sig_in); //This eliminates any built up DC offset (explanation in class)
	limited = Limiter.ar(leaked, 0.99);  //This makes sure the signal maxes out JUST below unity gain.

	ReplaceOut.ar(out, limited); //ReplaceOut MUST be used so that the resulting signal overwrites the previous instead of mixes with it!
}).add;
)

s.meter; //This brings up input and output dB meters
s.plotTree; //This brings up the node tree, showing running Synths and their resulting signal flow.

y = Synth.after(x, \limiter); //You want to make sure the limiter is the LAST item on the node tree, otherwise it will not limit all (or even any if it's at the head) of the audio signals!
y.free;


/*
V. Homework

All students: Using pulseTest as a model, try replacing some more hard-coded values with flexible arguments instead.
(Hint: The phases of the LFPulse UGens may be a good place to start.) Also, feel free to try some subtractive synthesis,
perhaps even using the trackpad as a control surface, to vary the sound even more and come up with a timbre to call
your own.

For those who finish the above and want more practice: Using at least 5 of the following UGens---SinOsc, Saw, LFNoise(0 and/or 1), LFTri, Pulse, LFPulse,
HPF, LPF, BPF, BRF---come up with a unique SynthDef (or multiple if you're feeling ambitious) that you can modulate on the fly.

All students: Read through the Tour of UGens in the Help browser, try them out (avoid the Spectral and Techniques UGens for now), and write at least 2 more SynthDefs
using any combination of them as you deem fit. (Remember to use a Limiter!!)
