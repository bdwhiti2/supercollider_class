//Before we begin, we need to make one small alteration to our server's setup for demonstration purposes.
//Don't worry; this won't be necessary going forward.

s.options.numOutputBusChannels_(8);
s.boot;

/*
I. Presentation of HW
II. SynthDef review

SynthDefs are recipes for the sounds and audio signal processes (i.e. Synths) that we create in SuperCollider.
They all adhere to the following syntax:

SynthDef.new(\nameOfSynth, {|arguments|
  var declaredVariable, moreDeclaredVariables;

  declaredVariable = operation;
  //Repeat ad nauseum

  Out.ar(outputBus, outputSig);
}).add;

When you want to play the synth, you instance it like so:

~variable = Synth.new(\nameOfSynth);

Alternatively, if you wish to play the SynthDef immediately upon creation, you can use the .play method instead of .add:

~variable = SynthDef.new(\nameOfSynth, {|args|
  ...
}).play;

This is similar, though not identical, to { }.play. The advantage to { }.play is that you can easily instance further variants, like so:

x = SynthDef.new(\awesomeSynth, {|args|
  ...
}).play;

y = Synth.new(\awesomeSynth, [\args, newValue]);
z = Synth.new(\awesomeSynth, [\args, otherNewValue]);

The disadvantage is that you still need an Out UGen, and a Linen envelope is not applied, resulting in clipping if an
EnvGen is not specified within the recipe (to be discussed below).

REMINDER: If arguments are supplied for SynthDefs (HIGHLY RECOMMENDED), they must be the FIRST items declared
in a SynthDef and use only ONE arg tag or ONE set of | | bookends. For instance:

SynthDef.new(\wonderfulSound, {|freq=440, amp=1,
                                                    out=0|
...
}).add;

...is okay as the arguments lie within one set of | | bookends, even though they use more than one line.

This example, however, is not okay:

SynthDef.new(\wonderfulSound, {arg freq=440, amp=1;
                                                  arg out=0;
...
}).add;

Why might this be? How can it be fixed while still using the arg tag and multiple lines?

Variables are the next to be declared, and must all be declared BEFORE the code proper. Unlike arguments,
variables can use multiple var tags and lines. The following works:*/

(
SynthDef.new(\wonderfulSound, {arg freq=440, amp=1, out=0;
	var sig1, sig2;
	var env = EnvGen.kr(Env.new, timeScale: 5, doneAction: 2);

	sig1 = SinOsc.ar(freq + LFNoise1.kr(0.5, 200), mul: env);
	sig2 = SinOsc.ar(freq + LFNoise1.kr(0.75, 400), mul: env);

	Out.ar(out, [sig1, sig2] * amp);
}).add;
)

//While this does not:

(
SynthDef.new(\wonderfulSound, {arg freq=440, amp=1, out=0;
	var env = EnvGen.kr(Env.new, timeScale: 5, doneAction: 2);
	var sig1;
	sig1 = SinOsc.ar(freq + LFNoise1.kr(0.5, 200), mul: env);

	var sig2;
	sig2 = SinOsc.ar(freq + LFNoise1.kr(0.75, 400), mul: env);

	Out.ar(out, [sig1, sig2] * amp);
}).add;
)

/*
III. Envelopes

An envelope defines the shape of the sound being generated. Its natural analogue in instrument performance is articulation,
though attention is paid not only to the onset of the sound, but also its behavior while sustaining and releasing.
Not defining an envelope can be risky. Speakers cannot go from a point of rest to a point of maximum excitation,
and vice versa, abruptly; attempting to do so will cause a very noticeable artifact when beginning or ending the sound,
often called a 'pop' or a 'clip.' In the SynthDef from last week's class we used an LFPulse generator to shape our sound,
but most often we will want a way to easily, but very specifically, design the attack, sustain, and release of our sound.
To achieve this in SuperCollider, one uses an envelope generator (EnvGen), that instances an envelope (Env).

It will be easiest to work from the "inside out" and discuss Env first. Env takes six arguments, but we really only need to concern
ourselves with the first three.
*/

(
Env.new(
	levels: [0, 1, 0], //Here we specify the amplitude, or Y coordinates (from 0 to 1), of the signal that will be plotted over time. For an audio signal this should ALWAYS begin and end with 0!!
	times: [1, 1], //Here we notate the amount of time taken between each Y coordinate. Note that there must always be one fewer value here than in levels
	curve: 'lin' //This specifies the curvature of the line segments. It can refer to the envelope globally, like here, or one can specify the manner of curve for each segment.
).plot; //Let's plot this to visualize the shape our sound is going to take.
)

Env.new([0, 0.7, 0.3, 1, 0.2, 0.8, 0], [0.1, 0.05, 0.2, 0.2, 0.01, 0.44], [1, -1, 2, -2, 4, -1]).plot; //A far more complex envelope

//Env has some convenience methods for common kinds of envelopes to alleviate tedious plotting of coordinates. A few of these follow:

Env.perc.plot; //An envelope perfect for percussive sounds.
Env.linen.plot; //An envelope suited for finite sounds that have some sustaining time.
Env.sine.plot; //An envelope best suited for sounds that are intended to swell and recede.

//There will be times, however, in which one really needs the powerful control of plotting one's own envelope.
//Don't fall into the trap of relying too much on preset methods!

/*
Plotting envelopes is only half of the battle. Env sets up the coordinates, but does not provide them in a format that
a SynthDef can understand over time. This requires the use of EnvGen, which has its own share of arguments
(though, again, we are only going to concern ourselves with three of them).
*/

EnvGen.kr(
	envelope: Env.new([0, 1, 0], [1, 1], 'lin'), //Here we input our original envelope (which happens to be the default)
	gate: 1, //The gate sends a message to the SynthDef to inform it whether or not a sound should be emanating. During the execution of the envelope, this will be 1. Once the envelope finishes, it automatically switches to 0.
	doneAction: 2 //This sends a message to the server once the gate switches to 0, telling it to automatically free the Synth. FOR NOW, ONLY USE doneAction: 2!!
)

(
SynthDef.new(\hautboy, {|freq=440, atk=0.01, sus=1, rel=0.1, amp=0.3, out=0|
	var freqs, amps, phases;
	var sig, env;

	freqs = Array.fill(8, {|i| freq * (i + 1)});
	amps = [0.8, 1, 0.5, 0.6, 0.3, 0.2, 0.2, 0.1];
	phases = Array.fill(8, {1.rand});
	sig = Klang.ar(`[freqs, amps, phases]);
	env = EnvGen.kr(Env.linen(0.05, sus, rel), doneAction: 2); //try substituting this with other Envs!

	Out.ar(out, sig * env * amp)
}).add;
)

x = Synth.new(\hautboy);

/*
IV. Multichannel Expansion and Spatialization

All UGens in SuperCollider output a monophonic signal by default. When played back through speakers,
the signal gets routed to the left channel; the right speaker remains silent until a second signal gets routed
to it. Compare the following:
*/

x = play({Saw.ar(380, 0.5)}); //Notice the alternate syntax here. {Saw.ar(380, 0.5)}.play; would work just as well!
x.free;

x = play({Saw.ar([380, 440], 0.5)}); //Here we have two Saw waves playing, with one at a frequency of 380Hz outputting through the left speaker, and a 440Hz sawtooth wave emitting from the right.
x.free;

//However, what if we want a single frequency projected from both speakers? Thankfully, that is easy to do with the .dup method.

x = play({Saw.ar(380, 0.5).dup}); //A 380Hz sawtooth wave can now be heard from both speakers!
x.free;

//Keep in mind that .dup is technically a convenience method. It is in effect no different than executing the following:

x = play({Saw.ar([380, 380], 0.5)});
x.free;

/*
This process of supplying an Array (capitalization to be explained later) of inputs to a unit generator,
resulting in multiple copies of that unit generator to be made, each copy routed to the next consecutively allocated
audio rate bus, is what is called multichannel expansion.
It is an indispensable part of the electroacoustic composition process, namely that of *spatialization*. Being able to dictate
precisely where in the audio field a sound should be placed is an important mode of expression in electronic music!

While .dup is often useful in a pinch, one is literally taking an audio signal and duplicating it across two channels.
To effectively place a sound within a stereo field, a much more effective approach is to *pan* the sound using a UGen like Pan2.
*/

x = play({Pan2.ar(Saw.ar(380, 0.5), 0)}); //A perfectly centered, balanced sound
x.free;

x = play({Pan2.ar(Saw.ar(380, 0.5), SinOsc.kr(0.5))}); //The same sound, oscillating evenly between left and right speakers
x.free;

(
x = {
	var specs, freqs, amps, rings;
	var numRes = 5;
	var bells = 12;
	var rate = LFNoise0.kr(0.1).range(0.1, 0.2);
	var scale = [60, 62, 64, 67, 69, 72];

	scale = scale.midicps;

	Mix.fill(bells, {
		freqs = Array.fill(numRes, {rrand(1, 13) * (scale.choose)});
		amps = Array.fill(numRes, {rrand(0.3, 0.9)});
		rings = Array.fill(numRes, {rrand(1.0, 4.0)});
		specs = [freqs, amps, rings].round(0.01);

		Pan2.ar(Klank.ar(`specs, Dust.ar(rate, 0.8)).lag(0.005), LFNoise0.kr(0.2))
	})
}.play;
)

x.free;

/*
As seen above, Mix is a UGen that will take two or more channels of audio output and mix them down to a
monophonic signal. This is important as it not only combines sounds within one channel to create layers of complexity
(as having one frequency, amplitude, and UGen per channel will create a binaural effect instead of stereo),
it also enables one to have more than two signals output over stereo. While the Mix.fill syntax was used above,
it is not typically used---it being a convenience method for Mix(Array.fill()). The syntax for Mix we'll deal with for now
is the following:

Mix([sig1, sig2 ... ]);

Compare the following:
*/

x = {LFTri.ar([780, 960], mul: 0.5)}.play;
x.free;

x = {Mix(LFTri.ar([780, 960], mul: 0.5))}.play;
x.free;

/*
Wait, what's going on? Why are both frequencies being heard over the left channel only?
As we recall, Mix takes multiple channels of audio and mixes it down to a monophonic signal.
In order to expand it over two channels, one needs to either use .dup or Pan2.
*/

x = {Pan2.ar(Mix(LFTri.ar([780, 960], mul: 0.5)), 0)}.play;
x.free;

/*
Remember that each unique audio signal is typically assigned to the next ascending audio bus.
First, let's bring up our audio meters:
*/

s.meter;

//Let us now evaluate the following SynthDef.

(
SynthDef.new(\thick_texture, {|out=0, freq=55|
	var sig, env;

	sig = VarSaw.ar([freq, freq * 2, freq * 3, freq * 4, freq * 5, freq * 6, freq * 7, freq * 8], mul: 0.15);
	env = EnvGen.kr(Env.new([0, 1, 0], [5, 7]), doneAction: 2);

	Out.ar(out, sig * env);
}).add;
)

x = Synth.new(\thick_texture);

/*
As you can no doubt tell from the server meter readings, each component of the audio signal is spread over
an eight-channel field. However, as we don't have an octophonic playback system, six of the eight channels
cannot be heard!

What to do? Mix to the rescue!
*/

(
SynthDef.new(\thick_texture, {|out=0, freq=55|
	var sig, env;

	sig = VarSaw.ar([freq, freq * 2, freq * 3, freq * 4, freq * 5, freq * 6, freq * 7, freq * 8], mul: 0.15);
	sig = Mix(sig);
	env = EnvGen.kr(Env.new([0, 1, 0], [5, 7]), doneAction: 2);

	Out.ar(out, sig * env);
}).add;
)

x = Synth.new(\thick_texture);

/*
While we can now hear all eight partials, the result is still unsatisfactory; everything's coming from the left speaker only!
Remember, Mix mixes an array down to a monophonic signal. We need to make use of either .dup or Pan2 to
properly expand it to a stereo output. Since the resulting texture is quite thick and not so effectively placed via panning,
let's use .dup.
*/

(
SynthDef.new(\thick_texture, {|out=0, freq=55|
	var sig, env;

	sig = VarSaw.ar([freq, freq * 2, freq * 3, freq * 4, freq * 5, freq * 6, freq * 7, freq * 8], mul: 0.15);
	sig = Mix(sig).dup;
	env = EnvGen.kr(Env.new([0, 1, 0], [5, 7]), doneAction: 2);

	Out.ar(out, sig * env);
}).add;
)

x = Synth.new(\thick_texture);

/*
This is fine, but typing out eight constituent parts of the array of partials can be tedious. Thankfully,
SuperCollider has a way to further abstract the creation of arrays through the Array class.
The above can be more efficently written like so:
*/

(
SynthDef.new(\thick_texture, {|out=0, freq=55|
	var sig, env;
	var numComponents = 8;

	sig = VarSaw.ar(Array.fill(numComponents, {|partial| freq * (partial + 1)}), mul: 0.15);
	sig = Mix(sig).dup;
	env = EnvGen.kr(Env.new([0, 1, 0], [5, 7]), doneAction: 2);

	Out.ar(out, sig * env);
}).add;
)

x = Synth.new(\thick_texture);

//The Array class can also easily allow one to inject a great deal of complexity to one's sound, especially when
//dealing with random numbers.

(
SynthDef.new(\thick_texture, {|out=0, freq=55, detune=0|
	var sig, env;
	var numComponents = 12;

	sig = VarSaw.ar(
		freq: Array.fill(numComponents, {(freq * ExpRand(1.0, 10.0)).round(freq * (0.5 + detune))}),
		iphase: Array.fill(numComponents, {Rand(0.0, 1.0)}),
		width: Array.fill(numComponents, {Rand(0.0, 1.0)}),
		mul: Array.fill(numComponents, {Rand(0.05, 0.2)})
	);
	sig = Mix(sig).dup;
	env = EnvGen.kr(Env.new([0, 1, 0], [5, 7]), doneAction: 2);

	Out.ar(out, sig * env);
}).add;
)

x = Synth.new(\thick_texture);

/*
V. In-Class Assignment:

Take the \thick_texture SynthDef (at any of its evolutionary stages) and tinker with it.
Feel free to change anything: the number of components of the texture,
its envelope, the VarSaw UGen itself, &c. Try to come up with a complex sound/texture of your own
to use in future projects.

VI. Homework

Design at least three more sounds, with one new 'legato' sound, one new percussive sound, and one of your choice.
