// First AI-assisted sound experiment.
// Evaluate this file in the SuperCollider IDE, or run it with sclang.

(
Server.default.waitForBoot {
    var notes = [48, 55, 60, 64, 67].midicps;

    Pdef(\firstTexture,
        Pbind(
            \instrument, \default,
            \degree, Pseq([0, 2, 4, 7, 9], inf),
            \scale, Scale.minor,
            \octave, Pwhite(3, 5, inf),
            \dur, Pwrand([0.25, 0.5, 1], [5, 3, 1], inf),
            \legato, Pwhite(0.2, 0.8, inf),
            \amp, 0.12,
            \pan, Pwhite(-0.7, 0.7, inf),
            \rel, Pwhite(0.3, 1.5, inf)
        )
    ).play;

    // Stop with: Pdef(\firstTexture).stop;
    notes.postln;
};
)
