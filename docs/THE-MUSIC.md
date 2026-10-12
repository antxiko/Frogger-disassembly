# The music

Everything you hear here comes from running the cartridge's own sound engine (`PASO_DE_CANAL`, 0x4111, once per channel from the interrupt, and the tracks each routine points the channel records at, 0xE020, 0xE028 and 0xE030) on an emulated Z80, frame by frame at 60 per second, just as the game calls it. What the engine writes to the PSG is turned into sound with an AY-3-8910 (`tools/musica.py`). Each MP3 is the whole piece up to where it starts again, plus 8 seconds of the repeat fading out; those that do not repeat end where the engine ends.

## Checked against openMSX

The PSG writes have been compared frame by frame with those of openMSX (C-BIOS MSX1 japonés). In every frame the PSG ends up the same:

- the start-up tune, whole, 362 frames;
- the stage-cleared tune, whole, 322 frames, except channel C, which in the game was still on another sound.

The timbre is not checked: it is a textbook AY-3-8910, not a recording of the emulator. The probes are `tools/omsx_psg.tcl` and `tools/coteja_psg.py`.

## How a piece plays

This game has no routine that takes a sound number: whoever wants something to play writes the pointer to its track into a channel record, and `PASO_DE_CANAL` reads it note by note. Each record is eight bytes: pointer, what is left of the note, the channel's PSG register (0, 2 or 4), the volume... It is the same player as in other Konami cartridges of the time. The openMSX check was done by writing those same records during play and comparing what the PSG receives from then on. The engine does not write the PSG mixer except for noise: start-up leaves it set, and here it starts from the same value, 0xB8.

## The tunes

**The start-up tune** (0x01)

Asked for by `Y_LA_FASE_DE_LOS_DOS` (0x442B): tres canales, programas de 0x5D97, 0x5DE9 y 0x5E41; lasts 6.0 s.

<audio controls preload="none" src="audio/musica_01.mp3?v=ef0f1d6a"></audio>

**The end of the game** (0x02)

Asked for by `FIN_DE_PARTIDA` (0x4596): dos canales, programas de 0x5FB6 y 0x5FD8; lasts 2.7 s.

<audio controls preload="none" src="audio/musica_02.mp3?v=9d67cbd0"></audio>

**Stage cleared** (0x03)

Asked for by la rutina de 0x5411: dos canales, programas de 0x5F18 y 0x5F5E; lasts 5.4 s.

<audio controls preload="none" src="audio/musica_03.mp3?v=153ecb43"></audio>
