s.boot;

/*
I. Presentation of HW

II. Envelope and Multichannel Expansion Review

III. Iteration

The ability to iterate over an array of values---in other words, to feed each value of an array into a function---is
one of the most powerful aspects of SuperCollider, and one of the biggest advantages it has over similar
visual programming languages (i.e. Max and Pure Data). For instance, one can create a bank of sine wave
oscillators like so:
*/

(
var freq = exprand(200, 800);

w = {SinOsc.ar(freq).dup};
x = {SinOsc.ar(freq * 2, mul: 0.9).dup};
y = {SinOsc.ar(freq * 3, mul: 0.8).dup};
z = {SinOsc.ar(freq * 4, mul: 0.7).dup};
)

w.play; x.play; y.play; z.play;

/*
This works, but is already reaching the threshold of tedium to type in (and plenty of otherwise useful interpreter variables are being
eaten up!). However, the following is just as effective, and considerably more powerful in the long run.
*/

(
x = {
	var freq = exprand(200, 800);
	var sum = 0; //This is one of the few times that we must initialize a variable to 0 instead of 'nil' (the default), as adding an audio signal to 'nil' will not work!
	var temp;

	4.do{|i|
		temp = SinOsc.ar(freq * (i + 1), mul: 1 - (i * 0.1)).dup;
		sum = sum + temp;
	};

	sum
};
)

x.play

/*
This produces the same result as the method where we manually enter four separate instances of SinOsc,
uses fewer CPU resources, but requires more lines of code. What would happen if we wished to augment this bank of oscillators with
four more SinOscs? Well, we'd need to use up four more variables and enter at least four more lines of code with the first method,
like so:
*/

(
var freq = exprand(200, 800);

w = {SinOsc.ar(freq).dup};
x = {SinOsc.ar(freq * 2, mul: 0.9).dup};
y = {SinOsc.ar(freq * 3, mul: 0.8).dup};
z = {SinOsc.ar(freq * 4, mul: 0.7).dup};
a = {SinOsc.ar(freq * 5, mul: 0.6).dup};
b = {SinOsc.ar(freq * 6, mul: 0.5).dup};
c = {SinOsc.ar(freq * 7, mul: 0.4).dup};
d = {SinOsc.ar(freq * 8, mul: 0.3).dup};
)

w.play; x.play; y.play; z.play; a.play; b.play; c.play; d.play;

//But with iteration, the *only* thing we would have to do is change the integer preceding .do:

(
x = {
	var freq = exprand(200, 800);
	var sum = 0;
	var temp;

	8.do{|i| //we are now producing a bank of four more oscillators without actually adding any code!
		temp = SinOsc.ar(freq * (i + 1), mul: 1 - (i * 0.1)).dup;
		sum = sum + temp;
	};

	sum
};
)

x.play;

/*
That's great, but what if one nevertheless wants to pass specific values into the function that may not be easily
expressed through a formula? As discussed in last week's class, when passing an integer into a function using .do, what
one is really doing is passing an array of indices, beginning from 0 up to one less than the specified integer.
Therefore, 8.do is passing the array [0, 1, 2, 3, 4, 5, 6, 7] into the function. Knowing this, we can tailor the array
to include whatever values we desire:
*/

(
x = {
	var sum = 0;
	var temp;

	[200, 333, 178, 505].do{|freq, i| //see below
		temp = SinOsc.ar(freq, mul: 1 - (i * 0.1)).dup;
		sum = sum + temp;
	};

	sum
}.play;
)

/*
You might have noticed that the iterative function now includes two arguments: freq and i. This is because any array passed
into a function sends two data points for each in the original array: its value, and its index number. The reason why we only
used the first of these before is that, using integer.do, each integer and its corresponding index is identical. Now that we're
passing an array of custom values, the collected data and its corresponding indices are not the same. Since we're still
basing amplitude on a formula making use of the current index value of the frequency array, we must pass both values
into the function.

What should we do, then, if we wanted to send arrays of custom amplitudes and frequencies?
*/

(
x = {
	var sum = 0;
	var temp;

	[200, 333, 178, 505].do{|freq|
		[0.6, 1, 0.3, 0.5].do{|amp|
			temp = SinOsc.ar(freq, mul: amp).dup;
			sum = sum + temp;
		}
	};

	sum
}.play;
)

/*
Why does this work?

Remembering Array.fill from last week, we could rewrite the above to produce a new result each time it's executed:
*/

(
x = {
	var temp;
	var sum = 0;
	var freq_array = Array.fill(4, {exprand(200, 2000)});
	var amp_array = Array.fill(4, {rrand(0.1, 0.5)});

	freq_array.do{|freq|
		amp_array.do{|amp|
			temp = SinOsc.ar(freq, mul: amp).dup;
			sum = sum + temp;
		}
	};

	sum
}.play;
)

//Now let's assign a random envelope to apply to each constiuent oscillator in our bank.

(
x = {
	var temp;
	var sum = 0;
	var freq_array = Array.fill(4, {exprand(200, 2000)});
	var amp_array = Array.fill(4, {rrand(0.1, 0.5)});

	freq_array.do{|freq|
		amp_array.do{|amp|
			var env = [
				Env.sine(4),
				Env.perc(0.1, 3.9),
				Env.new([0, 1, 0.7, 0.3, 0], [0.5, 2, 0.6, 0.3], [4, 1, 1, 1])
			].choose;

			temp = SinOsc.ar(freq, mul: EnvGen.kr(env, doneAction: 2) * amp).dup;
			sum = sum + temp;
		}
	};

	sum
}.play;
)

//Let's increase potential timbral variety even more by invoking random oscillators and filters within our bank.

(
x = {
	var temp;
	var sum = 0;
	var freq_array = Array.fill(4, {exprand(200, 2000)});
	var amp_array = Array.fill(4, {rrand(0.1, 0.5)});

	freq_array.do{|freq|
		amp_array.do{|amp|
			var env = [
				Env.sine(4),
				Env.perc(0.1, 3.9),
				Env.new([0, 1, 0.7, 0.3, 0], [0.5, 2, 0.6, 0.3], [4, 1, 1, 1])
			].choose;

			temp = [
				SinOsc.ar(freq, mul: EnvGen.kr(env) * amp).dup,
				Pulse.ar(freq, rrand(0.3, 0.7), EnvGen.kr(env, doneAction: 2) * amp).dup,
				Ringz.ar(BrownNoise.ar(amp * 0.5), freq, 4, EnvGen.kr(env, doneAction: 2)).dup
			].choose;
			sum = sum + temp;
		}
	};

	sum
}.play;
)

//EXERCISE: Rewrite the above function as a SynthDef instead.

/*
On the surface, .do is reminiscent of the ubiquitous "for loop" found in programming, i.e. (JavaScript example):

for (var i = initialNumber; i < endNumber; i++) {
  operation
}

Indeed, there are many similarities between the two. However, .do passes an array of values into a function; it is not
inherently sequential. SuperCollider does possess more traditional "for loop" functionality if one wishes to use it:

for (initialNumber, endNumber, {|i|
  operation
}

While the syntax is subtly different, it is identical to the JavaScript example above, functionally speaking.
There also exists "forBy," where one can advance the index number by a step size other than 1:

forBy (initialNumber, endNumber, stepValue, {|i|
  operation
}

This is equivalent to the following JavaScript syntax:

for (var i = initialNumber; i < endNumber; i = i + stepValue) {
  operation
}

IV. OSC

OSC (Open Sound Control) is a protocol with which one can network different pieces of software and hardware together.
Scsynth is built upon OSC as a foundation, which is why it can "talk" to other applications and devices with little effort.
We can make use of OSC communication in our programming as well through an "OSC responder node." While there
are several classes that allow for internal and external communcation via OSC, the one we will be focusing on is OSCdef.

As one might expect from the class name, an OSCdef (note the lowercase 'd') is a recipe for
routing and interpreting OSC messages within one's SuperCollider code.
Its syntax is not unlike SynthDef, with a few notable deviations:

OSCdef.new(\nameOfDef, {|arguments|
  var declaredVariable(s);

  declaredVariable(s) = operation(s);
}, '/OSC/listening/path');

(Notice that one does not .add OSCdefs, nor invoke something like OSC.new. Simply declaring the def adds it to the OSCdef library,
and activates the def.)

Unlike SynthDefs, OSCdefs do not by themselves generate audio material. Instead, they listen on the path specified in the def
for incoming information, and they route that information to a Synth or Synths in order to control various parameters. The path
is formatted not unlike a UNIX-based filesystem path (and close enough to an MS-DOS filesystem path save the lack of drive letter and
forward instead of back slashes).

The following is a rudimentary noise gate. As soon as the computer picks up sound that crosses its specified threshold,
it sends an OSC trigger, using the SendTrig class, along path '/tr', and is picked up and interpreted by an accompanying
OSCdef.
*/

s.meter;

(
SynthDef.new(\noise_gate, {
	var sig_in = SoundIn.ar; //use SoundIn to detect audio via the computer's built-in (or attached) microphone(s)
	var threshold = -20.dbamp; //.dbamp takes dB values and converts them to SC's normalized (0 - 1) amplitude scale
	var amp = Amplitude.kr(sig_in, 0.03, 0.03); //Amplitude measures the amplitude of an audio signal.
	var gate = Lag.kr(amp > threshold, 0.01); //Using Lag makes sure that, upon breach of the noise gate, the server waits a ms to catch up with the sound, in order to avoid nasty pops or clips within the audio.

	SendTrig.kr(gate, value: 1); //Whenever the gate is breached, the Synth will send a value of '1' over the path '/tr' (SendTrig's immutable path name)
}).add;

OSCdef.new(\controller, {|msg| //OSCdefs ALWAYS need an argument into which incoming messages are passed.
	if (msg[3] == 1) { //SendTrig sends an OSC array of four bits of information, but only the last bit, at index 3, is of value to us
		"Noise gate breached!".postln;
	}
}, '/tr');
)

x = Synth.new(\noise_gate);
x.free;

/*
Let's take a brief moment to discuss conditionals, as they are particularly useful in OSCdefs (and in functional SuperCollider programming
in general). This is one facet of SuperCollider programming that proves to be *more* difficult and mind-boggling than in most
other programming languages. First, their syntax is as follows:

if (some condition) {
  is true, do this.
}  {
  Otherwise, do this instead.
};

The final clause, the "else" statement, is optional. If omitted, then SuperCollider will only act if the condition is true,
and no special measures will be taken if false.

Second, it is important to understand that conditionals---also known colloquially as
"if-then" statements---reside completely in sclang; scsynth, being entirely based on OSC, does not understand them.
This means that anything passed to the server, from raw OSC messages to SynthDefs, CANNOT include conditionals
in the traditional sense. For instance, the following might make logical sense:
*/

(
SynthDef.new(\whoops, {|out=0|
	var freq, sig;

	freq = SinOsc.kr(2).range(220, 880);
	sig = SinOsc.ar(freq).dup;

	if (freq == 440) {
		"A440".postln;
	} {
		"nope".postln;
	};

	Out.ar(out, sig);
}).add;
)

//...but when we instance the synth...

x = Synth.new(\whoops);
x.free;

//...nothing happens, even if freq clearly reaches 440Hz during its oscillation.

/*
Now, SuperCollider *is* interpreting the conditional, which is why no error was thrown upon evaluating the SynthDef
(In fact, more likely than not a "nope" was posted to the Post window).
However, it only acts *once upon evaluation*, and it doesn't loop. This is where an OSCdef comes in handy,
as that function resides entirely in sclang, and loops at the control rate.
*/

(
SynthDef.new(\phew, {|out=0|
	var freq, sig;

	freq = SinOsc.kr(2).range(220, 880);
	sig = SinOsc.ar(freq).dup;

	freq = Pitch.kr(sig); //as SinOsc doesn't actually produce usable floating-point values, we need to use Pitch to output frequency values that our forthcoming conditional can understand

	SendTrig.kr(Impulse.kr(60), value: freq); //here we send frequency values over '/tr' at 60fps
	Out.ar(out, sig);
}).add;

OSCdef.new(\pitch_detect, {|msg|
	if (msg[3] == 440) { //if the incoming data at any point registers 440Hz,
		"A440".postln; //post "A440" to the Post window.
	} {
		"nope".postln; //Otherwise, post "nope".
	}
}, '/tr')
)

x = Synth.new(\phew);

/*
Despite scsynth not understanding conditionals, there are methods in which one can achieve conditional-like functionality
in SynthDefs. For more information on this, please refer to the following website:

http://supercollider.github.io/tutorials/If-statements-in-a-SynthDef.html

For now, embedding conditionals in OSCdefs may prove simpler.

V. In-Class Project

Using a mixture of a noise gate Synth, OSCdef, and the following SynthDef, program SuperCollider so that
a ping is produced whenever your computer picks up a certain amount of incoming audio signal (adjust the
threshold of the noise gate accordingly).
*/

(
SynthDef.new(\ping, {
	var freq = ExpRand(330, 990);
	var env = EnvGen.kr(Env.perc, doneAction: 2);
	var sig = SinOsc.ar(freq, mul: env).dup;

	Out.ar(0, sig * 0.5);
}).add;
)

/*
VI. Homework

For next week, sample between 6 and 12 found sounds and bring them with you to class.
