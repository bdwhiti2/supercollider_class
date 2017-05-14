/*
I. Introduction to Part II of Class

Now that we've finished going over SuperCollider essentials and all of you are comfortable with the basic operating functions of
the language, it is now time to cover some intermediate topics that will help you realize the projects of your dreams!
This is why it is important to begin thinking about the kind of piece you'd like to write. That way, I can focus the remaining
weeks on covering topics important to your personal composition goals. We will begin today discussing more advanced
server setup strategies and Routines, then follow up with listening to/watching excerpts of a variety of projects that
make use of multimedia programming languages. Now, without further ado!

II. Advanced Server Setup

While using s.boot or cmnd-B/ctrl-B are convenient ways to get started quickly, you will most likely want a bit more juice and
customization out of SuperCollider as one can run out of allocated memory quickly by sticking with the default settings
(that have been current since 2004 or so, back when single-core 1.5GHz PowerBook G4s were brand-new and
1GB of RAM was considered luxurious).
Therefore, before booting the server it might be a good idea to set some server options to help SuperCollider get the most out of
our dual-core+ Intel x86 behemoths.
*/

s.options.memSize = 2 pow: 20; //This option changes the memory allocated to the server from 8MiB(!!!) to a far more reasonable 1GiB.
s.options.maxNodes = 2048; //This doubles the amount of nodes SC will allow to run at once on its server. This will become particularly useful once we start delving into Patterns.
s.options.sampleRate = 48000; //This increases the audio sample rate to 48KHz and control rate to 750Hz.

//These are just three of the several options you can tweak; see ServerOptions in the documentation for more details.
//Note that you can use the variable setter notation to set these options instead, which allows for the following syntactical shortcut:

(
s.options.memSize_(2 pow: 20)
.maxNodes_(2048)
.sampleRate_(48000);
) //You can also combine these on one line if you wish, though that can get unwieldy quickly when more options are added!

//Finally, the following setting is quite helpful, though it isn't *technically* under the ServerOptions umbrella:

s.latency_(0.05); //Changing this from the default of 0.2 can help reduce lag when working with timing-specific processes.

/*
Now, you can simply boot the server from here, especially if you are still in the prototyping stage and aren't interested in
any further preconfiguration. However, let us pretend for a moment that you are ready to generate a performance-ready
file that automates more basic setup and safety mechanisms for you. In that case, I recommend the following lines follow
the options for the server you just set:
*/

(
s.newBusAllocators;
ServerBoot.removeAll;
ServerTree.removeAll;
ServerQuit.removeAll;
//The above ensures that you are starting from a clean slate with regard to allocated busses and various custom Server functions (more below)

~audio_out = 0; //On the off-chance that your default hardware audio out *isn't* how you wish to pipe your generated sound, you can globally change the bus number here.
)

/*
III. Routines

Before we finish our server setup, it would be prudent to cover Routines. A Routine is a "Function that can return
in the middle and then resume where [it leaves] off." Another way of describing it is a sequence of operations that
can be scheduled temporally against a Clock, thus empowering the programmer to construct an automated "score" of sorts.
Routines are important to master if one wishes to use SuperCollider for more than a stand-alone audio processor
or synthesizer.

Thankfully, Routines' syntax is little different from typical SuperCollider syntax. They are constructed like so:
*/

(
Routine{
	"This is a Routine.".postln; //SuperCollider begins by executing this line...

	3.wait; //...then waits for three seconds...

	"Isn't it cool?".postln; //...and finally executes this line.
}.play //If you don't wish to play your Routine immediately upon execution, leave off .play and store in a variable instead.
)

/*
N.B.: Routines do not necessarily need to be scheduled on a clock, though for now this kind of functionality is what we will
be focusing on.

Within a Routine, one can specify any kind of operation one would typically execute manually, such as the evaluation of
SynthDefs, the construction of Synths, setting of arguments, and so on. For instance, consider the following:
*/

(
Routine{
	SynthDef.new(\texture1, {|freq_lo=50.0, freq_hi=150.0, amp=1|
		var numPartials = 10;
		var numChannels = 5;
		var env = EnvGen.kr(Env.sine(15), levelScale: 0.06, doneAction: 2);
		var sig = Klang.ar(`[ { {rrand(freq_lo, freq_hi)}.dup(numPartials)}.dup(numChannels), nil, nil]);

		sig = Splay.ar(sig * env, center: 1.0.rand2);

		Out.ar(~audio_out, sig * amp)
	}).add;

	SynthDef.new(\texture2, {|amp=0.1, ampscale_lo=0.1, ampscale_hi=1.0, durscale_lo=0.5, durscale_hi=0.1, t_trig=1, dur=10, run=1|
		Out.ar(~audio_out, Pan2.ar(Gendy4.ar(
			ampdist: 4,
			durdist: 4,
			adparam: 1.0.rand,
			ddparam: 1.0.rand,
			minfreq: LFNoise2.kr(0.5).range(30, 300),
			maxfreq: LFNoise2.kr(0.8).range(300, 3000),
			ampscale: Sweep.kr(t_trig, 1 / dur * run).linlin(0, 1, ampscale_lo, ampscale_hi, \minmax),
			durscale: Sweep.kr(t_trig, 1 / dur * run).linlin(0, 1, durscale_lo, durscale_hi, \minmax),
			initCPs: 12,
			knum: LFNoise1.kr(LFNoise0.kr(0.2)).range(1, 12),
			mul: amp
		)))
	}).add;

	s.sync; //Necessary to ensure that the server has time to process the SynthDefs before it tries to instance them as Synths.

	x = Synth.new(\texture1);
	y = Synth.new(\texture2);

	12.wait;

	x = Synth.new(\texture1, [\freq_lo, 150.0, \freq_hi, 300.0]);
	y.set(\ampscale_lo, 1.0);
	y.set(\ampscale_hi, 0.3);
	y.set(\durscale_lo, 0.1);
	y.set(\durscale_hi, 0.8);
	y.set(\amp, 0.05);
	y.set(\run, 0);
	y.set(\run, 1);
	y.set(\t_trig, 1);

	12.wait;

	y.free;
}.play;
)

/*
It should be noted that Routines do not generate sounds themselves; they provide means of scheduling the instancing and freeing
of Synths, among other things. Therefore, they do not need to be freed upon termination.

Now that we have a basic understanding of Routines, let's revisit our server configuration. This introduces a few new concepts,
the most important one being s.waitForBoot{}. waitForBoot{} boots the server and runs a Routine, enclosed within the
curly braces, upon successful boot. For performance-ready files one typically uses waitForBoot as it automates much of the
setup process, thus eliminating the need of finding and executing every fragment of necessary code to get one's piece to play.
Note that, unlike with most Routines, one does not need to either specify it as a Routine nor use the .play method.
*/

s.quit;

(
s.options.memSize_(2 pow: 20)
.maxNodes_(2048)
.sampleRate_(48000);

s.latency_(0.05);

s.newBusAllocators;
ServerBoot.removeAll;
ServerTree.removeAll;
ServerQuit.removeAll;

~audio_out = 0;

////////////////////////
//BUSSES AND BUFFERS
////////////////////////

~make_busses = {
	~mono_bus = Bus.audio(s, 1); //Within this function you'd place whatever Busses you wish to allocate for your piece. I'm allocating a monophonic audio bus for demonstration purposes.
};

~make_buffers = {
	~play_buffer = Buffer.read(s, "~/path/to/buffer.wav"); //Within this function you'd specify the Buffers you wish to allocate for your piece.
	~record_buffer = Buffer.alloc(s, s.sampleRate * 5, 1); //Here I'm allocating a 5 second buffer into which live audio can be placed for processing.
};

////////
//CUES
////////

~make_cues = {
	c = Dictionary.new; //We're going to set up a Dictionary, which is an associative collection similar to an Array, into which we will put our cues.

	//The syntax for adding an entry into a Dictionary is ~variable.add(\cueName -> {Function})

	c.add(\cue1 -> Routine{
		"Here is an action.".postln;

		3.wait;

		"Here is another action.".postln;
	});

	c.add(\cue2 -> {
		"Now we finish the piece.".postln;
	})
};

~cleanup = {
	c = nil;
	r = nil;
	s.newBusAllocators;
	ServerBoot.removeAll;
	ServerTree.removeAll;
	ServerQuit.removeAll;
};

/////////////////////////////
//FUNCTION REGISTRATION
/////////////////////////////

ServerBoot.add(~make_busses); //This ensures that the busses will be properly allocated upon booting the server.
ServerBoot.add(~make_buffers); //This ensures that the buffers will be properly allocated upon booting the server.
ServerQuit.add(~cleanup); //This ensures the proper cleanup procedures will be enacted upon quitting the server.

/////////
//SCORE
/////////

r = Routine{
	c[\cue1].play;

	5.wait;

	c[\cue2].value;
};

//////////////////////////////////////////
//SERVER AND SYNTHDEF INITIALIZATION
//////////////////////////////////////////

s.waitForBoot{
	s.sync; //It's never a bad idea to pepper one's waitForBoot function with s.sync, which makes sure that the server waits until all preceding operations have been completed before continuing.

	SynthDef.new(\texture1, {|freq_lo=50.0, freq_hi=150.0, amp=1|
		var numPartials = 10;
		var numChannels = 5;
		var env = EnvGen.kr(Env.sine(15), levelScale: 0.06, doneAction: 2);
		var sig = Klang.ar(`[ { {rrand(freq_lo, freq_hi)}.dup(numPartials)}.dup(numChannels), nil, nil]);

		sig = Splay.ar(sig * env, center: 1.0.rand2);

		Out.ar(~audio_out, sig * amp)
	}).add;

	SynthDef.new(\texture2, {|amp=0.1, ampscale_lo=0.1, ampscale_hi=1.0, durscale_lo=0.5, durscale_hi=0.1, t_trig=1, dur=10, run=1|
		Out.ar(~audio_out, Pan2.ar(Gendy4.ar(
			ampdist: 4,
			durdist: 4,
			adparam: 1.0.rand,
			ddparam: 1.0.rand,
			minfreq: LFNoise2.kr(0.5).range(30, 300),
			maxfreq: LFNoise2.kr(0.8).range(300, 3000),
			ampscale: Sweep.kr(t_trig, 1 / dur * run).linlin(0, 1, ampscale_lo, ampscale_hi, \minmax),
			durscale: Sweep.kr(t_trig, 1 / dur * run).linlin(0, 1, durscale_lo, durscale_hi, \minmax),
			initCPs: 12,
			knum: LFNoise1.kr(LFNoise0.kr(0.2)).range(1, 12),
			mul: amp
		)))
	}).add;

	ServerTree.add(~make_cues); //We add this to the ServerTree so that the cues remain in memory even in case of a cmnd-period.
	s.freeAll; //This effecitvely forces a cmnd-period, thus triggering the addition of the cues into the server's memory.

	s.sync;

	"Ready.".speak.postln; //It's a good idea to provide some sort of indication that the boot sequence is done, so that one doesn't start the composition's main Routine prematurely
}
)

/*
This merely scratches the surface of how Routines and cues work in SuperCollider. If you are planning on writing a piece for
a live performer or an interactive installation, you will most likely rely on different kinds of triggers, from physical devices
to spectral analysis, to advance your cues, perhaps using the time-based method as a backup.

IV. Homework

Decide on the piece you would like to compose for this class and write a Routine that posts a description to the Post window,
in real time, of how you plan on your composition to unfold. This composition should be 3.5 minutes long AT A MINIMUM,
but preferably 5 -- 9 minutes for a strong, portfolio-ready piece that is universally eligible for festivals, competitions, &c.