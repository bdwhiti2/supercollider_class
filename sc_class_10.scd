/*
I. Fast Fourier Transform (FFT)

The Fast Fourier Transform---generally referred to in its abbreviated form, FFT---is a fundamental operation used in
virtually every form of signal analysis. While entire college classes can be, and are, taught on this topic,
we are only going to touch upon on it as a means to an end, that being manipulation of audio signal at the
spectral level. it is still important to have a superficial understanding of what is going on when this transformation
is applied.

Up until now, all of our audio processes have occured in what is called the "time domain." Analyzing a signal in
the time domain means analyzing waveforms with respect to their amplitude over time elapsed. So, for instance,
a sinusoidal wave oscillating at 440Hz means that the waveform completes 440 cycles of its amplitude moving
between 1 and -1 on a frequency oscilloscope every second. The shape names we give certain waveforms refer
specifically to what they look like in a time domain representation; a triangle wave looks triangular, a sawtooth
wave seems similar to a handsaw, and so forth. It is inarguably an important component of signal analysis,
and one we have dealt with extensively in class.

However, sometimes time domain representations of signals are inappropriate for certain situations.
While a time domain graph conveys frequency and amplitude information, what it leaves out is information
relating to the various constituent sinusoidal waveforms that comprise the signal. This of course is unnecessary
for a basic sine wave, but anything more complex than that is a signal comprised of multiple sine waves of
varying frequencies, amplitudes, and phases, and requires a different kind of graph to be able to analyze
its cellular makeup.

A frequency domain graph is still a two-dimensional representation of a signal, but instead of amplitude over time
we instead have amplitude (or, in this case, "magnitudes", or "mags") over frequency groupings (referred to as "bins").
Envision this graph as the more typical time domain graph rotated 90º, so that the line is facing toward you at any given
point in time. The x-axis in a frequency domain graph represents the bins, while the y-axis displays the mags.

To demonstrate, let's first take a gander at the time domain representation of a sawtooth wave:
*/

s.options.memSize_(2 << 19).maxNodes_(2048).sampleRate_(48000);
s.boot;

x = {Saw.ar(333, 0.5)}.scope;
x.free;

//As you can see, this signal maintains the distinctive jagged shape of a sawtooth wave. Now let's look at the
//frequency domain represenation of the same signal:

FreqScope.new(server: s);

x = {Saw.ar(333, 0.5)}.play;
x.free;

/*
A bit different, isn't it? What is going on here?

Frequency domain analyses are paramount to contemporary audio processing tools and techniques, as they allow
for the alteration and resynthesis of any sound down to the molecular level. Time domain pitch shifting techniques,
for instance, are almost always unsatisfactory as all of the frequency content is shifted at a 1:1 ratio in tandem,
but frequency domain pitch shifters are very powerful, as they keep the mags of each of the bins along the
frequency bin spectrum---which is why this kind of editing is often called "spectral processing"---consistent to the
source sound as the fundamental is shifted up or down.

In SuperCollider, spectral processing can be achieved in three ways, depending on the UGen(s) or techniques
used. The language, along with its various extensions, or "quarks", has some classes that take care of the
FFT automatically, so all you have to do is use the UGen in question. For example, the three main pitch tracking
classes---Tartini, Pitch, and Qitch---do not require the user to specify a FFT themselves; simply use the UGen and
continue normally. The vast majority of spectral UGens, however, do require the user to set up an FFT, along
with its complementary inverse FFT (IFFT), before they can work. And finally, the user can perform whatever
custom sets of operations they want on an FFT'd signal utilizing a method like .pvcollect; this is extremely
advanced fare, however, and beyond the scope of this course. We are going to focus on the second category
today as we make use of some of the various phase vocoder (beginning with the prefix PV_) UGens in SuperCollider.

If you've installed the standard SC3Plugins pack, you have literally dozens of these spectral processes at your
disposal. Some of these perform the subtlest of transformations on sound, while others have remarkably
conspicuous effects. For our class, we are going to make use of one of the demo sounds that ships with the language,
which is a (admittedly somewhat creepy) recording of one of the lead developer's sons saying something in
some Scandinavian language (Swedish?). During your own time, however, I *highly* recommend plugging in an
earbud/microphone combo and trying them out using your own voice. Be forewarned: playing with some of
these effects in this manner can result in some lost minutes, if not hours, in one's day. ;)
*/

b = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");  //This is the demo sound file we'll be using

//The following are some potentially useful processes for your projects.
//PV_MagAbove: Pass frequency bins above a certain magnitude threshold.

(
SynthDef("help-magAbove3", { arg out=0, soundBufnum=2;
    var in, chain;
    in = PlayBuf.ar(1, soundBufnum, BufRateScale.kr(soundBufnum), loop: 1);
    chain = FFT(LocalBuf(2048), in);
    chain = PV_MagAbove(chain, MouseX.kr(0, 310)); //notice how the sound becomes increasingly muffled the further up the X axis you go?
    Out.ar(out, 0.1 * IFFT(chain).dup); //IFFT is essential for resynthesis!!
}).play(s, [\soundBufnum, b]);
)

//PV_MagBelow: Pass frequency bins below a certain magnitude threshold.

(
SynthDef("help-magBelow3", { arg out=0, bufnum=0, soundBufnum=2;
    var in, chain;
    in = PlayBuf.ar(1, soundBufnum, BufRateScale.kr(soundBufnum), loop: 1);
    chain = FFT(LocalBuf(2048), in);
    chain = PV_MagBelow(chain, MouseX.kr(0, 310));
    Out.ar(out, 0.5 * IFFT(chain).dup);
}).play(s,[\out, 0, \soundBufnum, b.bufnum]);
)

//PV_MagClip: Clip frequency bins to a certain magnitude threshold.

(
SynthDef("help-magClip2", { arg out=0, soundBufnum=2;
    var in, chain;
    in = PlayBuf.ar(1, soundBufnum, BufRateScale.kr(soundBufnum), loop: 1);
    chain = FFT(LocalBuf(2048), in);
    chain = PV_MagClip(chain, MouseX.kr(0, 50));
    Out.ar(out, 0.5 * IFFT(chain).dup);
}).play(s, [\soundBufnum, b]);
)

//PV_MagFreeze: Freeze magnitudes in place. This is a common, and VERY useful, spectral processing effect!

(
//trig with MouseY
SynthDef("help-magFreeze2", { arg out=0, soundBufnum=2;
    var in, chain;
    in = PlayBuf.ar(1, soundBufnum, BufRateScale.kr(soundBufnum), loop: 1);
    chain = FFT(LocalBuf(2048), in);
    chain = PV_MagFreeze(chain, MouseY.kr > 0.5 );
    Out.ar(out, 0.1 * IFFT(chain).dup);
}).play(s,[\soundBufnum, b]);
)

//PV_MagSmear: Average, or "smear", magnitudes across a range of frequency bins.

(
SynthDef("help-magSmear2", { arg out=0, bufnum=0, soundBufnum=2;
    var in, chain;
    in = PlayBuf.ar(1, soundBufnum, BufRateScale.kr(soundBufnum), loop: 1);
    chain = FFT(LocalBuf(2048), in);
    chain = PV_MagSmear(chain, MouseX.kr(0, 100));
    Out.ar(out, 0.5 * IFFT(chain).dup);
}).play(s,[\out, 0, \soundBufnum, b.bufnum]);
)

//PV_RandComb: Pass random frequency bins.

(
//trig with MouseY
SynthDef("help-randcomb2", { | out=0, soundBufnum=2 |
    var sig, chain;
    sig = PlayBuf.ar(1, soundBufnum, BufRateScale.kr(soundBufnum), loop: 1);
    chain = FFT(LocalBuf(2048), sig);
    chain = PV_RandComb(chain, MouseY.kr, Impulse.kr(0.4));
    Out.ar(out, IFFT(chain).dup);
}).play(s,[\soundBufnum, b.bufnum]);
)

//PV_BinScramble: Scramble frequency bins across the spectrum.

(
//trig with MouseY
SynthDef("help-binScramble", { arg out=0, soundBufnum=2;
    var in, chain;
    in = PlayBuf.ar(1, soundBufnum, BufRateScale.kr(soundBufnum), loop: 1);
    chain = FFT(LocalBuf(2048), in);
    chain = PV_BinScramble(chain, MouseX.kr , 0.1, MouseY.kr > 0.5 );
    Out.ar(out, 0.1 * IFFT(chain).dup);
}).play(s, [\soundBufnum, b]);
)

//PV_XFade: Spectrally morph between two sound sources.

(
SynthDef("help-xfade2", { arg out=0, bufnumA=0, bufnumB=1, soundBufnum=2;
    var inA, chainA, inB, chainB, chain;
    inA = Mix(Formant.ar([120, 180], [1200, 2000], [240, 360], 0.2));
    inB = PlayBuf.ar(1, soundBufnum, BufRateScale.kr(soundBufnum), loop: 1);
    chainA = FFT(LocalBuf(2048), inA);
    chainB = FFT(LocalBuf(2048), inB);
    chain = PV_XFade(chainA, chainB, MouseX.kr);
    Out.ar(out,  IFFT(chain).dup);
}).play(s,[\out, 0, \soundBufnum, b.bufnum]);
)

//PV_ConformalMap: Fun as hell.

(
x = {|bufnum|
	var sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), loop: 1);
	var chain;

	chain = FFT(LocalBuf(2048), sig);
	chain = PV_ConformalMap(chain, MouseX.kr(0.01, 2.0, 'exponential'), MouseY.kr(0.01, 10.0, 'exponential'));
	chain = IFFT(chain);

	Pan2.ar(CombN.ar(chain, 0.1, 0.1, 10, 0.5, chain), 0, 0.3);
}.play(args: [\bufnum, b], fadeTime: 10);
)

x.release;

/*
This is just the tip of the iceberg regarding what one can do with Fast Fourier Transforms. Being able to alter sounds
down to their very core can enable one to engage in some really refined and/or esoteric processes in one's work.
I encourage everyone to test out as many PV_ UGens as you can; this can be a great source of inspiration for
generating sound material for your projects! (NOTE: Some of the PV_ UGens, especially the ones found in
SC3Plugins, might seem as if they're undocumented. In fact, they DO have documentation, but they are old enough
(and seemingly unmaintained) that they use the old-style HTML documentation format instead. To access these files,
one will need to go into their SuperCollider Extensions directory, find whichever plugin they'd like help with, and
search for the .html help file there.)

II. In-Class Project Time