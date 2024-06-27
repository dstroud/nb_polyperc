PolyPerc {

    *initClass {

        StartUp.add {
            (Routine.new {
                Server.default.sync;
            }).play;
            SynthDef(\polyPerc, {
                |pitch=440, decay=0.5, pw=0.5, mul=1.0, cutoff=600, gain=1.0, pan=0.0, sendA=0, sendB=0, sendABus=0, sendBBus=0|
                var sound, filt, env;
                
                sound = Pulse.ar(pitch, pw);
                filt = MoogFF.ar(sound, cutoff, gain);
                env = Env.perc(level: mul, releaseTime: decay).kr(2);
                sound = Pan2.ar((filt * env), pan);
                
                Out.ar(0, sound);
                Out.ar(sendABus, sendA * sound);
                Out.ar(sendBBus, sendB * sound);
            }).add;

            OSCFunc.new({ |msg, time, addr, recvPort|
                var args = [
                    \pitch, msg[1],
                    \decay, msg[2],
                    \pw, msg[3],
                    \mul, msg[4],
                    \cutoff, msg[5],
                    \gain, msg[6],
                    \pan, msg[7],
                    \sendA, msg[8],
                    \sendB, msg[9]
                ];
                
                Synth.new(\polyPerc, args ++ [
                    \sendABus, (~sendA ? Server.default.outputBus),
                    \sendBBus, (~sendB ? Server.default.outputBus)
                ]);
            }, "/polyperc/perc");

        }
    }
}