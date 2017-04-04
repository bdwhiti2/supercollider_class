/*
While sclang is launched automatically when booting the IDE, scsynth---the synthesis server---is not.
It's not a bad idea to get into the habit of booting the server as soon as the IDE finishes loading.
This is accomplished via the following command:
*/

s.boot;

//A SuperCollider equivalent to the traditional "Hello World!" first step is the generation of a
//sine wave oscillator at 440Hz (the same frequency as an equal-tempered A4):
//The key combination to evaluate a line or groups of lines of code is CMND-RETURN (macOS) or CTRL-ENTER (Windows, Linux)

x = {SinOsc.ar(freq: 440, mul: 0.5)}.play; //"Let x be a sine wave oscillator, at the audio rate, oscillating at 440Hz and playing at half amplitude."

x.free; //This frees the sounding Synth.

//NOTE: REMEMBER, THE KEY COMBINATION TO KILL ALL RUNNING SYNTHS IS CMND-PERIOD (macOS) or CTRL-PERIOD (Windows, Linux)

//Line 13 can also be represented as the following:

x = {SinOsc.ar(440, 0, 0.5)}.play;
//As one can see, the argument qualifiers "freq:" and "mul:" are nowhere to be found, but, as such, the intervening phase argument has to be filled in.

//Since the default arguments for SinOsc have the frequency set at 440Hz and the phase at 0, only the mul: argument is necessary.
x = {SinOsc.ar(mul: 0.5)}.play;

x = {SinOsc.ar * 0.5}.play; //Multiplying the oscillator by one-half achieves precisely the same result.

x = {SinOsc.ar(350, mul: 0.2)}.play; //As the freq: argument is the first argument listed for the UGen, it's not necessary to add the qualifier.
y = {SinOsc.ar(mul: 0.2)}.play; //This plays a second sine wave oscillator at 440Hz, also at 1/5 amplitude.
x.free; y.free; //This line frees both Synths simultaneously.

//The next line accomplishes the same result as Lines 29 and 30, but by using less CPU:
x = {SinOsc.ar([350, 440], mul: 0.2)}.play;
x.free;

//...Except that there is one subtle difference. Lines 29 and 30 play both sine wave oscillators in the left channel, while Line 34
//has the oscillator at 350Hz placed in the left channel, and the oscillator at 440Hz in the right.
//The addition of the Mix UGen fixes this:
x = {Mix(SinOsc.ar([350, 440], mul: 0.2))}.play;
x.free;

//For those listening over anything that isn't either a monophonic speaker output or substandard laptop external speakers,
//having all sounds eminate over only the left channel will likely lead to some listening discomfort. Using the Pan2 UGen mitigates this:
x = {Pan2.ar(Mix(SinOsc.ar([350, 440], mul: 0.2)))}.play;
x.free;

//(Note: Next week we will be discussing how audio signal busses work, but for now, just take my word for it :) )
//While Line 45 is still fairly easy to parse, it is on the cusp of the threshold of incomprehensibility for many people.
//It might be easier to restructure it as follows:
( //Whenever evaluating more than one line of code at once, one should enclose all relevant lines of code in parentheses, like so.
x = {
	var sig = Mix(SinOsc.ar([350, 440], mul: 0.2)); //Local variables need to be declared using 'var'

	Pan2.ar(sig);
}.play;
)

//As one can see above, splitting a complex chain of UGens into constituent variables, while resulting in longer code, can
//also positively impact its readability and comprehensibility.

x.free;

//The following lines of code deal with subtractive synthesis via the use of filters:
(
x = {
	var sig = WhiteNoise.ar; //Here we are taking a complex WhiteNoise signal...
	var control = MouseX.kr(100, 20000, 1); //...mapping the X coordinates of the computer's mouse/trackpad exponentially from 100Hz (far left) to 20KHz (far right)...

	LPF.ar(sig, control, 0.2) //...and running the above through a low-pass filter (using the mouse/trackpad to control the filter's cutoff frequency)
}.scope(1);
)

x.free;

//The following is identical to the code above, only this time running it all through a high-pass filter:
(
x = {
	var sig = WhiteNoise.ar;
	var control = MouseX.kr(100, 20000, 1);

	HPF.ar(sig, control, 0.2)
}.scope(1);
)

x.free;

//Now running the WhiteNoise generator through a band-pass filter...:
(
x = {
	var sig = WhiteNoise.ar;
	var control = MouseX.kr(100, 20000, 1);

	BPF.ar(sig, control, 0.04, 0.4) //...with a fairly narrow bandwidth (rq of 0.04).
}.scope(1);
)

x.free;

//Now through a band-cut filter...:
(
x = {
	var sig = WhiteNoise.ar;
	var control = MouseX.kr(100, 20000, 1);

	BRF.ar(sig, control, 0.4, 0.2) //...with a fairly wide bandwidth (rq of 0.4).
}.scope(1);
)

x.free;

//Finally, running the WhiteNoise generator through a band-pass filter, with a center frequency of 3000Hz and
//a bandwidth controlled by the X coordinate of the mouse/trackpad:
(
x = {
	var sig = WhiteNoise.ar;
	var control = MouseX.kr(0.01, 0.7, 1);

	BPF.ar(sig, 3000, control, 0.2)
}.scope(1);
)

x.free;