PolyPerc {

    *initClass {

        StartUp.add {
            (Routine.new {
                Server.default.sync;
            }).play;
            SynthDef(\polyPerc, {
                |pitch=440, decay=0.5, pw=0.5, mul=1.0, cutoff=600, gain=1.0, pan=0.0, sendA=0, sendB=0, sendABus=0, sendBBus=0|
                var out = [pitch, pw, mul, cutoff, gain, decay, pan];
                var sound = Pulse.ar(pitch, pw);
                var filt = MoogFF.ar(sound,cutoff,gain);
                var env = Env.perc(level: mul, releaseTime: decay).kr(2);      
				sound = Pan2.ar((filt*env), pan);
                Out.ar(out, sound);
                Out.ar(sendABus, sendA*sound);
                Out.ar(sendBBus, sendB*sound);
            }).add;

            OSCFunc.new({ |msg, time, addr, recvPort|
                var args = [
                    [\pitch, \decay, \pw, \mul, \cutoff, \gain, \pan, \sendA, \sendB], 
                    msg[1..]
                    ].lace;
                Synth.new(
                    \polyPerc,
                    args 
                    ++ [
                     \sendABus, (~sendA ? Server.default.outputBus), 
                     \sendBBus, (~sendB ? Server.default.outputBus)]);
            }, "/polyperc");

        }
    }
}