s.options.memSize_(2 << 19).maxNodes_(2048);
s.boot;

/*
I. Installing SC Extensions
II. Homework Review
III. Patterns

"Patterns describe calculations without explicitly stating every step. They are a higher-level representation of a computational task.
While patterns are not ideally suited for every type of calculation, when they are appropriate they free the user
from worrying about every detail of the process. Using patterns, one writes what is supposed to happen,
rather than how to accomplish it." --Harkins

Unlike Routines in which one constructs a "score" that specifies operations to be completed at specific points in time,
Patterns summarize what one would like to have happen without having to detail every single operation for the
interpreter. Patterns utilize a different set of vocabulary than the rest of the language, but in many ways this
new vocabulary can be more intuitive and easier to master.

(Note: like Routines, Patterns do not have to return a continuous stream of data; one can have Patterns
increment gradually whenever called upon. However, for the scope of this class, we are going to
treat Patterns as continuous running processes, so there won't be the necessity to specify .asStream
as .play will take care of that for us automatically.)

By far the most important class for Patterns is Pbind. Pbind assigns key/value pairs just like an Event;
in fact, Pbind returns an Event when called upon. (See Event in the in-house documentation for more
information on what Events are.) So, within Pbind, one can associate values to different musical parameters.
For instance, take the following:
*/

p = Pbind(\degree, Pwhite(0, 7, inf), \dur, 0.25, \legato, 1).play;
p.stop; //note that you *stop* Patterns, not free them.

/*
Can anyone tell me what is going on here?

While we will be sticking with Pbind for the rest of this class, there is an alternative that might appeal
to those wishing to emulate more of that classic voltage-controlled, monophonic modular synth sound,
and that is Pmono:
*/

p = Pmono(\default, \degree, Pwhite(0, 7, inf), \dur, 0.25).play;
p.stop;

/*
As you can no doubt tell by listening, Pbind executes a new instance of the Synth---in this case, it's using
the SynthDef 'default' (yes, there is one!) as we have not specified one---for every attack, while Pmono
uses one Synth and continually ramps its note values to the next every quarter second.

Returning to Pbind, we can see that its key/value pairs are expressed like so:

Pbind(\keyAsSymbol, value)

This can be extended for as many key/value pairs required for the pattern:

Pbind(\keyAsSymbol, value, \keyAsSymbol, value, \keyAsSymbol, value, &c.)

As with any other class, arguments can be separated by line for greater comprehensibility.
This can be particularly effective with Pbind.
*/

(
p = Pbind(
	\degree, Pwhite(0, 7, inf),
	\dur, 0.25,
	\legato, 1
).play
)

p.stop;

/*
Furthermore, Pbind comes with a syntactical alternative to using symbols that, while requiring a few more
keystrokes at the outset, can make longer Patterns MUCH easier to read and type out in the long run.
*/

(
p = Pbind(*[ //notice the addition of the *[
	degree: Pwhite(0, 7, inf),  //now one can use the same notation used in Events!
	dur: 0.25, //instead of \keyAsSymbol, value, we now can use key: value
	legato: 1
]).play
)

p.stop;

/*
While one can make some surprisingly compelling textures with the default SynthDef alone,
it's never a bad idea to construct your own. As Pbind executes a new Synth every dur seconds
(or beats, if you are playing on a TempoClock), whatever SynthDefs you use will
*absolutely* need to be able to free itself when it is finished sounding, otherwise
the resulting Synths will continue to accumulate, and may very well crash the server or at least
result in audio dropouts. As we recall, this can be achieved through doneAction: 2 in EnvGen
(the most common approach), or by using FreeSelfWhenDone.kr and tying some finite process
to the UGen, like Line.

Let's see what we can do with the following SynthDef:
*/

(
SynthDef.new(\shimmering, {|freq=440, atk=0.01, sus=0.2, rel=0.1, pan=0, amp=0.1, out=0|
	var freqs = Array.fill(6, {(freq * Rand(1, 11)).round(freq) + Rand((freq * 0.05).neg, freq * 0.05)});
	var amps = [0.8 + Rand(-0.20, 0.20), 0.9 + Rand(-0.10, 0.10), 0.5 + Rand(-0.20, 0.20), 0.6 + Rand(-0.20, 0.20), 0.3 + Rand(-0.20, 0.20), 0.2 + Rand(-0.20, 0.20)];
	var phases = Array.fill(6, {Rand(-1.0, 1.0)});
	var sig = Klang.ar(`[freqs, amps, phases]);
	var env = EnvGen.kr(Env.new(
		[0, 1, 0.6, 0.7, 0.3, 0.2, 0],
		[atk, 0.03, 0.05, 0.1, sus, rel],
		[1, -2, 1, 1, -1, -4]
	));

	sig = Pan2.ar(sig, pan) * env * amp;
	sig = BenVerb.ar(sig, mix: 0.3, revtime: 1);

	FreeSelfWhenDone.kr(Line.kr);
	Out.ar(out, sig);
}).add; //note that, for Patterns, you MUST use one of the following add methods: .add, .store, .load(s), or .send(s).asSynthDesc. Just stick to .add ;)
)

x = Synth.new(\shimmering);

//Now that we have our SynthDef, let's set up a rudimentary pattern:

(
p = Pbind(*[
	instrument: 'shimmering',
	dur: 1,
	note: Prand([4, 9], inf),
	pan: Prand([-1, -0.5, 0, 0.5, 1], inf),
	amp: 0.15
]).play;
)

p.stop;

/*
Can anyone tell me what is going on here?

Now let's resume the pattern... and add another one!
*/

p.play;

(
q = Pbind(*[
	instrument: 'shimmering',
	dur: 1,
	note: Prand([7, 11], inf),
	pan: Prand([-1, -0.5, 0, 0.5, 1], inf),
	amp: 0.15
]).play;
)

p.stop; q.stop;

//Next, let's revisit p:

(
p = Pbind(*[
	instrument: 'shimmering',
	dur: Pwrand([0.25, 0.75], [0.8, 0.2], inf), //Pwrand applies weights to each value in the list
	note: Pseq([4, 9, 11, 7, 4, Rest], inf), //Pseq iterates its contents in sequence
	pan: Pxrand([-1, -0.5, 0, 0.5, 1], inf), //Pxrand ensures that a value won't be repeated twice in a row
	amp: 0.15
]).play;
)

p.stop;

/*
As we can see, simply changing the Pattern "blueprint" ever so slightly gives us a livelier, more robust
and flavorful result. Let's continue to tinker with this...
*/

(
p = Pbind(*[
	instrument: 'shimmering',
	dur: Pwrand([0.25, 0.75, 0.5], [0.6, 0.2, 0.2], inf),
	note: Pwrand([4, 9, 7, 11, Rest], [0.3, 0.2, 0.2, 0.1, 0.2], inf),
	pan: Pxrand([-1, -0.5, 0, 0.5, 1], inf),
	amp: Prand([0.1, 0.15, 0.2], inf)
]).play;
)

p.stop;

//Now let's try having one pattern lead into another. This can be achieved through a Routine.

(
p = Pbind(*[
	instrument: 'shimmering',
	dur: Pseq([0.25, 0.25, 0.25, 1, 0.25, 0.25, 0.25, 0.75, 0.25, 0.5, 0.25, 0.5, 0.25, 0.25, 0.5], 1), //notice the repeat of 1!
	note: Pseq([4, 4, 7, 9, 7, 9, 7, 4, 0, 11, 0, 11, 0, 11, 9], 1),
	pan: 0,
	amp:Prand([0.1, 0.15, 0.2], inf) //why do you think we keep an infinite loop here?
]);

q = Pbind(*[
	instrument: 'shimmering',
	dur: Pwrand([0.25, 0.75, 0.5], [0.7, 0.1, 0.2], inf),
	note: Pwrand([4, 9, 7, 11, Rest], [0.3, 0.2, 0.2, 0.2, 0.1], inf),
	pan: Pxrand([-1, -0.5, 0, 0.5, 1], inf),
	amp: Prand([0.1, 0.15, 0.2], inf)
]);

r = Routine{
	p.play;

	5.75.wait;

	q.play;
}.play;
)

//One can also embed patterns in parallel using Ppar, resulting in an even denser, richer texture:

(
a = Pbind(*[
	instrument: 'shimmering',
	dur: Pwrand([0.25, 0.75, 0.5], [0.7, 0.1, 0.2], inf),
	note: Pwrand([4, 9, 7, 11, Rest], [0.3, 0.2, 0.2, 0.2, 0.1], inf),
	pan: Pxrand([-1, -0.5, 0, 0.5, 1], inf),
	amp: Prand([0.1, 0.15, 0.2], inf)
]);

b = Pbind(*[
	instrument: 'shimmering',
	dur: Prand([0.125, 0.25, Rest(0.5)], inf), //if used in a dur stream, Rest can take a duration as an argument
	note: Pwrand([0, 4, 7], [0.5, 0.25, 0.25], inf) + (12 * Pwrand([1, 2], [0.25, 0.75], inf)),
	pan: 0,
	amp: 0.2
]);

p = Ppar([a, b]).play;
)

p.stop;

/*
Patterns sequenced within Routines are a very helpful building block for algorithmic composition.
The Routine sets up the temporal score of the piece, while Patterns determine the content of
the sonic events that make up the piece. The following is an example of a background track I had
written for a videogame I worked on called Hyper Painting:
*/

(
SynthDef.new(\reverb_and_limiter, {|in=0, out=0|
	var sig_in = In.ar(in, 2);
	var reverb = BenVerb.ar(sig_in);
	var leaked = LeakDC.ar(reverb);
	var limited = Limiter.ar(leaked, 0.99);

	ReplaceOut.ar(out, limited);
}).play;

SynthDef.new(\backgroundTrack1, {|out=0, freq=220, amp=1, pan=0,
	atk=2, sus=0, rel=3,
	c1=1, c2=(-1), cfmin=440, cfmax=1760, rqmin=0.1, rqmax=0.2|
	var sig, env;

	env = EnvGen.kr(Env([0, 1, 1, 0], [atk, sus, rel], [c1, 0, c2]), doneAction: 2);
	sig = Saw.ar(freq);
	sig = BPF.ar(sig, {LFNoise1.kr(7).exprange(cfmin, cfmax)}.dup, {LFNoise1.kr(0.1).exprange(rqmin, rqmax)}.dup);
	sig = Balance2.ar(sig[0], sig[1], pan);
	sig = sig * env * amp;
	Out.ar(out, sig);
}).add;

SynthDef.new(\backgroundTrack2, {|out=0, freq=2, detune=0.2, amp=1.5, pan=0,
	atk=2, sus=0, rel=3,
	c1=1, c2=(-1), cfmin=440, cfmax=1760, cfhzmin=500, cfhzmax=2000,
	rqmin=0.1, rqmax=0.2|
	var sig, env;

	env = EnvGen.kr(Env([0, 1, 1, 0], [atk, sus, rel], [c1, 0, c2]), doneAction: 2);
	sig = Saw.ar(freq * {LFNoise1.kr(0.5, detune).midiratio}.dup);
	sig = BPF.ar(sig, {LFNoise1.kr(LFNoise1.kr(4).exprange(cfhzmin, cfhzmax)).exprange(cfmin, cfmax)}.dup, {LFNoise1.kr(0.1).exprange(rqmin, rqmax)}.dup);
	sig = Balance2.ar(sig[0], sig[1], pan);
	sig = sig * env * amp;
	Out.ar(out, sig);
}).add;

SynthDef.new(\footstepsLR,
	{|out=0, freq=2, detune=0.2, amp=1,
		atk=2, sus=0, rel=3,
		c1=1, c2=(-1), cfmin=440, cfmax=1760, cfhzmin=500, cfhzmax=2000,
		rqmin=0.1, rqmax=0.2|
		var sig, env, pan;

		env = EnvGen.kr(Env([0, 1, 1, 0], [atk, sus, rel], [c1, 0, c2]), doneAction: 2);
		pan = Line.kr(-1, 1, 5);
		sig = Saw.ar(freq * {LFNoise1.kr(0.5, detune).midiratio}.dup);
		sig = BPF.ar(sig, {LFNoise1.kr(LFNoise1.kr(4).exprange(cfhzmin, cfhzmax)).exprange(cfmin, cfmax)}.dup, {LFNoise1.kr(0.1).exprange(rqmin, rqmax)}.dup);
		sig = Balance2.ar(sig[0], sig[1], pan);
		sig = sig * env * amp;
		Out.ar(out, sig);
}).add;

SynthDef.new(\footstepsRL,
	{|out=0, freq=2, detune=0.2, amp=1,
		atk=2, sus=0, rel=3,
		c1=1, c2=(-1), cfmin=440, cfmax=1760, cfhzmin=500, cfhzmax=2000,
		rqmin=0.1, rqmax=0.2|
		var sig, env, pan;

		env = EnvGen.kr(Env([0, 1, 1, 0], [atk, sus, rel], [c1, 0, c2]), doneAction: 2);
		pan = Line.kr(1, -1, 5);
		sig = Saw.ar(freq * {LFNoise1.kr(0.5, detune).midiratio}.dup);
		sig = BPF.ar(sig, {LFNoise1.kr(LFNoise1.kr(4).exprange(cfhzmin, cfhzmax)).exprange(cfmin, cfmax)}.dup, {LFNoise1.kr(0.1).exprange(rqmin, rqmax)}.dup);
		sig = Balance2.ar(sig[0], sig[1], pan);
		sig = sig * env * amp;
		Out.ar(out, sig);
}).add;

SynthDef.new(\backgroundTrack3, {|out=0, freq=440, detune=0.2, amp=0.75, pan=0,
	atk=3, sus=2, rel=4,
	c1=2, c2=(-2), cfmin=100, cfmax=1760,
	rqmin=0.1, rqmax=0.2|
	var sig, env;

	env = EnvGen.kr(Env([0, 1, 1, 0], [atk, sus, rel], [c1, 0, c2]), doneAction: 2);
	sig = VarSaw.ar(freq * {LFNoise1.kr(0.5, detune).midiratio}.dup, {Rand(0, 0.2)}.dup);
	sig = BPF.ar(sig, {LFNoise1.kr(3).exprange(cfmin, cfmax)}.dup, {LFNoise1.kr(0.2).exprange(rqmin, rqmax)}.dup);
	sig = Balance2.ar(sig[0], sig[1], pan);
	sig = sig * env * amp;
	Out.ar(out, sig);
}).add;
)

(
r = Routine{
	~bg3op = Pbind(
		\instrument, \backgroundTrack3,
		\dur, Pwhite(4.5, 7.0, inf),
		\midinote, Pseq([[68.426-[24, 12, 0].choose,
			89.708-[36, 24, 12, 0].choose,
			90.659-[36, 24, 12, 0].choose,
			50.572-[24, 12, 0].choose],
			[97.713-[36, 24, 12, 0].choose,
			88.27-[36, 24, 12, 0].choose,
			97.183-[48, 36, 24, 12, 0].choose,
			94.748-[60, 48, 36, 24, 12, 0].choose]
		], 1),
		\detune, Pexprand(0.02, 0.3, inf),
		\cfmin, 145,
		\cfmax, 2200,
		\rqmin, Pexprand(0.01, 0.15, inf),
		\atk, Pwhite(2.0, 2.5, inf),
		\rel, Pwhite(3, 4, inf),
		\ldb, 6,
		\amp, 0.15
	).play;

	12.wait;

	Synth.new(\footstepsLR);

	4.wait;

	~bg2hard = Pbind(
		\instrument, \backgroundTrack2,
		\dur, Prand([1, 0.5], inf),
		\freq, Prand([1/2, 2/3, 1, 4/3, 2, 5/2, 3, 4, 6, 8], inf),
		\detune, 0,
		\cfmin, Prand([68.426, 89.708, 90.659, 50.572, 97.713, 88.27, 97.183, 94.748].midicps, inf) * Prand([0.25, 0.5, 1, 2], inf),
		\cfmax, Pkey(\cfmin) * Pwhite(1.008, 1.025, inf)
	).play;

	20.wait;

	~bg2soft = Pbind(
		\instrument, \backgroundTrack2,
		\dur, Prand([1, 0.5], inf),
		\freq, Prand([1/2, 2/3, 1, 4/3, 2, 5/2, 3, 4, 6, 8], inf),
		\amp, 1.5,
		\detune, 0,
		\rqmin, 0.005,
		\rqmax, 0.008,
		\atk, 3,
		\sus, 1,
		\rel, 5,
		\cfmin, Prand([68.426, 89.708, 90.659, 50.572, 97.713, 88.27, 97.183, 94.748].midicps, inf) * Prand([0.25, 0.5, 1, 2], inf),
		\cfmax, Pkey(\cfmin) * Pwhite(0.976, 1.1, inf)
	).play;

	40.wait;

	~bg2hard.stop;

	5.wait;

	Synth.new(\backgroundTrack1, [\freq, 11]);

	4.wait;

	Synth.new(\backgroundTrack1, [\freq, 11]);
	Synth.new(\backgroundTrack1, [\freq, 14]);

	6.wait;

	~bg3 = Pbind(
		\instrument, \backgroundTrack3,
		\dur, Pwhite(4.5, 7.0, inf),
		\midinote, Pxrand([68.426-[24, 12, 0].choose,
			89.708-[36, 24, 12, 0].choose,
			90.659-[36, 24, 12, 0].choose,
			50.572-[24, 12, 0].choose,
			97.713-[36, 24, 12, 0].choose,
			88.27-[36, 24, 12, 0].choose,
			97.183-[48, 36, 24, 12, 0].choose,
			94.748-[60, 48, 36, 24, 12, 0].choose
		], inf),
		\detune, Pexprand(0.02, 0.3, inf),
		\cfmin, 300 * (0.8..2.0).choose,
		\cfmax, 2200 * (0.5..1).choose,
		\rqmin, Pexprand(0.01, 0.03, inf),
		\rqmax, Pexprand(0.04, 0.08, inf),
		\atk, Pwhite(2.0, 2.5, inf),
		\rel, Pwhite(3, 4, inf),
		\ldb, 6,
		\amp, 0.4
	).play;

	25.wait;

	Synth.new(\backgroundTrack1, [\freq, 11]);
	Synth.new(\backgroundTrack1, [\freq, 14]);
	Synth.new(\backgroundTrack1, [\freq, 12]);
	Synth.new(\backgroundTrack1, [\freq, 13]);

	5.wait;

	~bg2soft.stop;

	Synth.new(\backgroundTrack1, [\freq, 11]);
	Synth.new(\backgroundTrack1, [\freq, 14]);
	Synth.new(\backgroundTrack1, [\freq, 12]);
	Synth.new(\backgroundTrack1, [\freq, 13]);

	0.5.wait;

	Synth.new(\backgroundTrack1, [\freq, 10]);
	Synth.new(\backgroundTrack1, [\freq, 9]);
	Synth.new(\backgroundTrack1, [\freq, 15]);
	Synth.new(\backgroundTrack1, [\freq, 16]);

	0.5.wait;

	~bg2soft2 = Pbind(
		\instrument, \backgroundTrack2,
		\dur, Prand([1, 0.75, 0.5], inf),
		\freq, Prand([1/2, 2/3, 1, 4/3, 2, 5/2, 3, 4, 6, 8], inf),
		\amp, 1.2,
		\detune, Pwhite(0, 0.12, inf),
		\rqmin, 0.005,
		\rqmax, 0.008,
		\atk, 3,
		\sus, 1,
		\rel, 5,
		\cfmin, Prand([68.426, 89.708, 90.659, 50.572, 97.713, 88.27, 97.183, 94.748].midicps, inf) * Prand([0.125, 0.25, 0.5, 1, 2], inf),
		\cfmax, Pkey(\cfmin) * Pwhite(0.949, 1.12, inf)
	).play;

	8.wait;

	~bg2hard2 = Pbind(
		\instrument, \backgroundTrack2,
		\dur, Prand([1, 0.5], inf),
		\freq, Prand([1/2, 2/3, 1, 4/3, 2, 5/2, 3, 4, 6, 8], inf),
		\detune, Pwhite(0, 0.12, inf),
		\amp, 0.9,
		\cfmin, Prand([68.426, 89.708, 90.659, 50.572, 97.713, 88.27, 97.183, 94.748].midicps, inf) * Prand([0.25, 0.5, 1, 2], inf),
		\cfmax, Pkey(\cfmin) * Pwhite(1.005, 1.035, inf)
	).play;

	15.wait;

	Synth.new(\backgroundTrack1, [\freq, 11]);
	Synth.new(\backgroundTrack1, [\freq, 14]);
	Synth.new(\backgroundTrack1, [\freq, 12]);
	Synth.new(\backgroundTrack1, [\freq, 13]);
	Synth.new(\backgroundTrack1, [\freq, 10]);
	Synth.new(\backgroundTrack1, [\freq, 9]);
	Synth.new(\backgroundTrack1, [\freq, 15]);
	Synth.new(\backgroundTrack1, [\freq, 16]);

	5.wait;

	Synth.new(\backgroundTrack1, [\freq, 11]);
	Synth.new(\backgroundTrack1, [\freq, 14]);
	Synth.new(\backgroundTrack1, [\freq, 12]);
	Synth.new(\backgroundTrack1, [\freq, 13]);
	Synth.new(\backgroundTrack1, [\freq, 10]);
	Synth.new(\backgroundTrack1, [\freq, 9]);
	Synth.new(\backgroundTrack1, [\freq, 15]);
	Synth.new(\backgroundTrack1, [\freq, 16]);

	10.wait;

	Synth.new(\footstepsRL);

	~bg3op = Pbind(
		\instrument, \backgroundTrack3,
		\dur, Pwhite(4.5, 7.0, inf),
		\midinote, Pseq([[68.426-[24, 12, 0].choose,
			89.708-[36, 24, 12, 0].choose,
			90.659-[36, 24, 12, 0].choose,
			50.572-[24, 12, 0].choose],
			[97.713-[36, 24, 12, 0].choose,
			88.27-[36, 24, 12, 0].choose,
			97.183-[48, 36, 24, 12, 0].choose,
			94.748-[60, 48, 36, 24, 12, 0].choose]
		], 4),
		\detune, Pexprand(0.02, 0.3, inf),
		\cfmin, 145,
		\cfmax, 2200,
		\rqmin, Pexprand(0.01, 0.15, inf),
		\atk, Pwhite(2.0, 2.5, inf),
		\rel, Pwhite(3, 4, inf),
		\ldb, 6,
		\amp, 0.2
	).play;

	~bg3.stop;

	~bg3 = Pbind(
		\instrument, \backgroundTrack3,
		\dur, Pwhite(4.5, 7.0, inf),
		\midinote, Pxrand([68.426-[24, 12, 0].choose,
			89.708-[36, 24, 12, 0].choose,
			90.659-[36, 24, 12, 0].choose,
			50.572-[24, 12, 0].choose,
			97.713-[36, 24, 12, 0].choose,
			88.27-[36, 24, 12, 0].choose,
			97.183-[48, 36, 24, 12, 0].choose,
			94.748-[60, 48, 36, 24, 12, 0].choose
		], inf),
		\detune, Pexprand(0.02, 0.3, inf),
		\cfmin, 300 * (0.8..2.0).choose,
		\cfmax, 2200 * (0.5..1).choose,
		\rqmin, Pexprand(0.01, 0.03, inf),
		\rqmax, Pexprand(0.04, 0.08, inf),
		\atk, Pwhite(2.0, 2.5, inf),
		\rel, Pwhite(3, 4, inf),
		\ldb, 6,
		\amp, 0.25
	).play;

	~bg2soft2.stop;

	~bg2soft = Pbind(
		\instrument, \backgroundTrack2,
		\dur, Prand([1, 0.75, 0.5], inf),
		\freq, Prand([1/2, 2/3, 1, 4/3, 2, 5/2, 3, 4, 6, 8], inf),
		\amp, 1.2,
		\detune, Pwhite(0, 0.20, inf),
		\rqmin, 0.008,
		\rqmax, 0.013,
		\atk, 3,
		\sus, 1,
		\rel, 5,
		\cfmin, Prand([68.426, 89.708, 90.659, 50.572, 97.713, 88.27, 97.183, 94.748].midicps, inf) * Prand([0.125, 0.25, 0.5, 1, 2], inf),
		\cfmax, Pkey(\cfmin) * Pwhite(0.9, 1.2, inf)
		).play;

	5.wait;

	~bg1 = Pbind(
		\instrument, \backgroundTrack1,
		\dur, Pwhite(3, 9, inf),
		\midinote, Pxrand([44.426, 41.708, 42.659, 50.572, 49.713, 40.27, 49.183, 46.748], inf),
		\amp, 1.05
		).play;

	10.wait;

	~bg1perc = Pbind(
		\instrument, \backgroundTrack1,
		\dur, Pwhite(0.75, 2, inf),
		\freq, Pwhite(10.0, 20.0, inf)
		).play;

	8.wait;

	~bg3.stop;

	20.wait;

	~bg2hard2.stop;

	~bg2hard =  Pbind(
		\instrument, \backgroundTrack2,
		\dur, Prand([1, 0.75, 0.66, 0.33, 0.5], inf),
		\freq, Prand([1/2, 2/3, 1, 4/3, 2, 5/2, 3, 4, 6, 8], inf),
		\detune, Pwhite(0, 0.25, inf),
		\amp, 0.9,
		\cfmin, Prand([68.426, 89.708, 90.659, 50.572, 97.713, 88.27, 97.183, 94.748].midicps, inf) * Prand([0.25, 0.5, 1, 2], inf),
		\cfmax, Pkey(\cfmin) * Pwhite(1, 1.05, inf)
	).play;

	5.wait;

	~bg1perc.stop;

	5.wait;

	~bg2soft.stop;

	10.wait;

	~bg2hard.stop;

	~bg3op = Pbind(
		\instrument, \backgroundTrack3,
		\dur, Pwhite(2.0, 3.75, inf),
		\midinote, Pseq([[68.426-[24, 12, 0].choose,
			89.708-[36, 24, 12, 0].choose,
			90.659-[36, 24, 12, 0].choose,
			50.572-[24, 12, 0].choose],
			[97.713-[36, 24, 12, 0].choose,
			88.27-[36, 24, 12, 0].choose,
			97.183-[48, 36, 24, 12, 0].choose,
			94.748-[60, 48, 36, 24, 12, 0].choose]
		], 3),
		\detune, Pexprand(0.02, 0.8, inf),
		\cfmin, 1000,
		\cfmax, 1500,
		\rqmin, Pexprand(0.01, 0.09, inf),
		\atk, Pwhite(0.4, 0.7, inf),
		\rel, Pwhite(1, 1.3, inf),
		\ldb, 7,
		\amp, 0.2
	).play;

	8.wait;

	~bg3 = Pbind(
		\instrument, \backgroundTrack3,
		\dur, Prand([0.33, 0.66, 0.20, 0.40, 1], inf),
		\midinote, Pxrand([68.426-[24, 12, 0].choose,
			89.708-[36, 24, 12, 0].choose,
			90.659-[36, 24, 12, 0].choose,
			50.572-[24, 12, 0].choose,
			97.713-[36, 24, 12, 0].choose,
			88.27-[36, 24, 12, 0].choose,
			97.183-[48, 36, 24, 12, 0].choose,
			94.748-[60, 48, 36, 24, 12, 0].choose
		], inf),
		\detune, Pexprand(0.02, 0.3, inf),
		\cfmin, 300 * (0.8..2.5).choose,
		\cfmax, 2200 * (0.3..1).choose,
		\rqmin, Pexprand(0.01, 0.03, inf),
		\rqmax, Pexprand(0.04, 0.08, inf),
		\atk, 0.1,
		\rel, 0.1,
		\ldb, 6,
		\amp, 0.2
	).play;

	3.wait;

	~bg1.stop;

	15.wait;

	Synth.new(\footstepsLR);

	4.wait;

	~bg2soft = Pbind(
		\instrument, \backgroundTrack2,
		\dur, Prand([1, 0.5], inf),
		\freq, Prand([1/2, 2/3, 1, 4/3, 2, 5/2, 3, 4, 6, 8], inf),
		\amp, 1.5,
		\detune, 0,
		\rqmin, 0.005,
		\rqmax, 0.008,
		\atk, 3,
		\sus, 1,
		\rel, 5,
		\cfmin, Prand([68.426, 89.708, 90.659, 50.572, 97.713, 88.27, 97.183, 94.748].midicps, inf) * Prand([0.25, 0.5, 1, 2], inf),
		\cfmax, Pkey(\cfmin) * Pwhite(0.976, 1.1, inf)
	).play;

	15.wait;

	~bg2hard = Pbind(
		\instrument, \backgroundTrack2,
		\dur, Prand([1, 0.5], inf),
		\freq, Prand([1/2, 2/3, 1, 4/3, 2, 5/2, 3, 4, 6, 8], inf),
		\detune, 0,
		\cfmin, Prand([68.426, 89.708, 90.659, 50.572, 97.713, 88.27, 97.183, 94.748].midicps, inf) * Prand([0.25, 0.5, 1, 2], inf),
		\cfmax, Pkey(\cfmin) * Pwhite(1.008, 1.025, inf)
	).play;

	15.wait;

	~bg2soft.stop;

	5.wait;

	~bg3op.stop;

	10.wait;

	~bg3.stop;

	5.wait;

	Synth.new(\footstepsRL);

	4.wait;

	~bg2hard.stop;

}
)

r.play;

/*
IV. In-class Assignment

For the rest of class, come up with at least one SynthDef/Pattern combo that ideally will be used in your piece.
If you feel that Patterns simply will not apply to your project, then come up with one regardless that produces
a texture you find interesting. Once finished, take the remainder of class to continue work on your piece.

V. Homework
(REMINDER: CLASS IS CANCELLED NEXT SUNDAY FOR THE MEMORIAL DAY WEEKEND)

Complete at least the first 90 seconds of your piece, and produce a skeletal draft of the remainder.
If your piece deals with live instruments and electronics, then the 90 seconds need only be of the
SuperCollider-generated electronics (though I would HIGHLY RECOMMEND at least a rough
sketch of the instrumentalist's part as well).