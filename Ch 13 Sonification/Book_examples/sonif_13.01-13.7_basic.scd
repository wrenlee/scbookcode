



	// figure 13.1 - Loading the data
(
q = q ? ();
q.execdata = ();
q.execdata.years = (1977 .. 2008); 
	// data is: [total for each region, 1977 ... 2007];
q.execdata.regions = (
	Total: [1099,1,0,2,0,1,2,5,21,18,18,25,11,16,23,14,31,38,31,
			56,45,74,68,98,85,66,71,65,59,60,53,42,37],
	Northeast: [4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,1,0,0,0,0,0,1,0,0,0],
	Midwest: [129,0,0,0,0,1,0,0,0,1,0,0,0,1,5,1,1,4,3,11,9,10,5,12,5,10,9,7,7,14,6,5,2],
	South: [933,0,0,1,0,0,2,5,21,16,18,24,10,13,17,13,26,30,26,41,29,60,
		55,74,76,50,61,57,50,43,44,36,35],
	West: [67,1,0,1,0,0,0,0,0,1,0,1,1,2,1,0,4,4,2,2,7,4,8,11,4,4,1,0,2,2,3,1,0],
	Texas: [423,0,0,0,0,0,1,0,3,6,10,6,3,4,4,5,12,17,14,19,3,37,20,35,40,17,33,24,23,19,24,26,18]
);
q.getReg = { |q, regName| q.execdata.regions[regName].drop(1) };
)





	// figure 13.2 - Mapping the data to pitch in discrete events
(
Pbindef(\exec, 
	\note, Pseq(q.getReg(\Midwest)), 
	\octave, 3, 
	\dur, 5 / q.execdata.years.size
).play;
)
	// the different regions
Pbindef(\exec, \note, Pseq(q.getReg(\Northeast)));
Pbindef(\exec, \note, Pseq(q.getReg(\West)));
Pbindef(\exec, \note, Pseq(q.getReg(\South)));





	// figure 13.3 - Continuous data sonification
 
b = Buffer.sendCollection(s, q.getReg(\Northeast), 1); 
(
Ndef(\exec, { |dur = 5, scale=50, offset=200| 
	var vals = PlayBuf.ar(1, b, dur / SampleRate.ir );
	Pan2.ar(
		SinOsc.ar(vals  * scale + offset), 0, 
		EnvGen.kr(Env.linen(0.01, dur, 0.01, 0.2), doneAction: 2)
	);
}).play;
)
	// load other regions into buffer
b.sendCollection(q.getReg(\Midwest));   Ndef(\exec).send;

b.sendCollection(q.getReg(\West));   Ndef(\exec).send;

b.sendCollection(q.getReg(\South));   Ndef(\exec).send;






	// figure 13.4 -  Sound design with noise pulses 
(
SynthDef( "noisepulses", { arg out = 0, sustain=1.0, numPulses = 0, pan = 0.0, amp = 0.2; 
	Out.ar(out, 
		PanAz.ar(4, 
			PinkNoise.ar 
			* Decay2.ar(Impulse.ar(numPulses / sustain, 0, numPulses.sign), 0.001, 0.2),
			pan, 
			EnvGen.kr( Env.linen(0.0, 0.995, 0.0), levelScale: amp, timeScale: sustain, doneAction: 2)
		)
	);
}).store;
SynthDef(\tick, { |out, amp=0.2, pan| 
	OffsetOut.ar(out, Pan2.ar(Impulse.ar(0) * Line.kr(amp, amp, 0.001, doneAction: 2), pan)) 
}).store;
)
(instrument: \noisepulses, numPulses: 10, legato: 1, dur: 2).play;
(instrument: \tick).play;






	// figure 13.5 - Four regions in sequence
(
Tdef(\execs, { 
	var yearDur = 2;	// one year is 2 seconds
	var region, numExecs, numyears = q.execdata.years.size; 
	[\Northeast, \Midwest, \West, \South].do { |regName, i| 

		region = q.execdata.regions[regName].postln; 
		q.execdata.years.do { |year, i| 
			numExecs = region[i + 1]; 
			[regName, year, numExecs].postln;
			(instrument: \tick).play;
			if (numExecs > 0) {
				(instrument: \noisepulses, legato: 1, numPulses: numExecs, dur: yearDur).play;
			};
			yearDur.wait;
		};
		yearDur.wait;
	};
}).play;
)





// figure 13.6 - Four regions in parallel
(
// four channels playing, ordered by total number. 
// On stereo systems, only the first 2 channels play.
Tdef(\execs, { 
	var yearDur = 2;	// one year is 2 seconds
	q.execdata.years.do { |year, i| 
	var region, numExecs, numyears = q.execdata.years.size; 
		// ordered by total number, on stereo, only first 2 play.
	[\South, \Midwest,  \West, \Northeast ].do { |regName, j| 

		region = q.execdata.regions[regName].postln; 
			numExecs = region[i + 1]; 
			[regName, year, numExecs].postln;
			(instrument: \tick).play;
			if (numExecs > 0) {
				(instrument: \noisepulses, 
					legato: 1,
					dur: yearDur, 
					numPulses: numExecs, 
					pan: j * 0.5 - 0.25 	// to 4 channels
				).play;
			};
		};
		yearDur.wait;
	};
}).play;
)

	// 2 inline code examples
{ SinOsc.ar([MouseX.kr(200, 3000, 1), MouseY.kr(200, 3000, 1)]) * 0.01 }.play;

{ HenonC.ar(2000, LFNoise2.kr([1, 1], 0.2, 1.4), 0.14) * 0.2 }.play(s);




	// figure 13.7 - Sonification of tag systems
(
// compare two axioms on left and right channels
// μ = 4 (size of alphabet)
// v (deletion number) varies [1..6] with horizontal cursor position
{
	var tag, rules, val;
	rules = [[0, 1, 1], [1, 3, 2, 0], [1, 2], [3, 1, 1]]; // same rule for both
	v = MouseX.kr(1, 6);
	val = dup {
		var axiom = Array.fill(14, { #[0, 1, 2, 3].choose }); axiom.join.postln;
		Duty.ar(1 / SampleRate.ir, 0,  Dtag(7e5, v, axiom, rules), doneAction: 2);
	} * 0.1
}.play;
)
