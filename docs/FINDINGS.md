# Findings

Everything here is anchored to an address and to a figure that can be checked
against the binary. Where something is a guess, it is in
[Open questions](OPEN-QUESTIONS.html) instead.

## Frogger and Time Pilot carry the same sound player

Not similar — **the same code**. The 163 bytes at 0x4111–0x41B3 here and those
at 0x4160–0x4202 in Time Pilot (RC-703) match byte for byte except for
**three**:

| Frogger | Time Pilot | |
|---|---|---|
| 0x4137: `A1` | 0x4186: `F0` | the low byte of a pointer, 0x41A1 against 0x41F0 |
| 0x4171: `A1` | 0x41C0: `F0` | the same pointer again |
| 0x415D: `A8` | 0x41AC: `98` | **PSG register 7, the mixer** |

The first two are the same routine relocated: 0x41A1 + 0x4F = 0x41F0, exactly
the offset between the two copies. The third is the only one that says
something different — **the noise is on channel B in Frogger and on channel C
in Time Pilot**.

The cross-check: the ten labels the tracer found here on its own (L_4111,
L_412F, L_413E, L_4167, L_4189, L_4190, L_4192, L_41A1, L_41AA, L_41B4) land
one by one on the ten already named in Time Pilot once you subtract 0x4F. None
left over on either side. In both cartridges the player sits immediately
before INIT.

## It does not carry Konami's hidden mark

Many of the house's cartridges hide their catalogue number and the title in katakana at the end of the ROM; **Manuel Pazos** ([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)) found it. This one does not: behind the last byte with any content there are only the 16 bytes of 0xFF padding the cartridge ends with. Nor is it somewhere else: all 8,192 positions were swept with a search that does find it in the cartridges of the series that carry it.

## The whole demo is fifteen bytes

    584F  00 08 01 01 01 01 01 08 01 01 01 01 08 00 01

One byte per move, in the same format as the controls: 0x01 up, 0x08 right,
0x00 nothing. Wait, right, five times up, right, four up, right, wait, one more
up.

## There are four layouts, not five

The stage is picked with `(stage-1) mod 5` over the five-word table at 0x5457 —
but the second and third entries **both point to 0x5CCD**. Stages 2 and 3 use
exactly the same layout.

What separates them are two touch-ups 0x5493 makes on the third slot only: the
first object of the top row becomes a **crocodile**, and the second object of
row 15 gets the "last" bit, leaving that row with two objects instead of three.

## From stage 11 on, the game stops getting harder

There are **four** comparisons against the stage number in the whole cartridge:

| stage | | where |
|---|---|---|
| 2 | eight river objects go up two types | 0x54A8 |
| 3 | the frog you have to rescue appears | 0x506A |
| 6 | two lanes move one step per turn, and a third diving turtle is added | 0x54C9 |
| 11 | row 7 is left with a single object | 0x54DB |

After that the only thing that changes is which of the four layouts comes up,
and that cycles every five. Stage 11, stage 47 and stage 99 play the same.

And there is no ending. On stage **100** the counter goes back to 1 (0x53F5)
and the BCD number on the scoreboard goes back to 01. No banner, no music, no
screen.

## The diving turtles are hand-picked, one by one

Diving is a bit, not a property. When the stage is built, 0x5489 sets it at
**exactly two addresses** — 0xE0C3 and 0xE0EB — with the counters at 0x80 and
0x8A so that the two groups never dive together. From stage 6 on, 0x54D6 adds a
third (0xE0E7, counter 0x8F).

## Logs and cars do not spend a single sprite

Four versions of every drawing, shifted 0, 2, 4 and 6 pixels, generated at
start-up by rolling the whole pattern set two bits at a time and letting the
bits that fall off enter the character next door (0x473C). Positions are kept
in quarters of a character, and their low two bits pick the version.

## Three screen thirds matched with a single copy

One copy of 4095 bytes with the destination 2 KB ahead of the source (0x471A).
Past the first third it is reading what it just wrote, so the second propagates
into the third on its own.

## The same letters uploaded twice, just for the colour

INIT sends the letter set to characters 0xD8 and then **again** to 0x98 (0x4235
and 0x4240 repeat bytes the previous block had already sent). The colour table
loaded right after gives cyan to one range and white to the other. In SCREEN 2
colour goes per pattern line, so that is the only way to have the same letters
in two colours.

## Jumping into a home that is already taken kills you

0x528F reads the bit for that home in 0xE080 and, if it was already set,
`jp 0x5305` — the death routine. No bounce, no warning.

## Two things the clock does that you cannot see

At **0x60**, once per stage, four objects in row 15 get their speed decremented
(0x511A) — they run faster. At **0x32**, the character the time bar is drawn
with is repainted in another colour (0x514B).

## A routine nobody calls

At 0x57F7 there are six bytes of working code: the one-byte-index version of
the table lookup at 0x57FF. `ex (sp),hl / ld c,a / ld b,0 / add hl,bc /
ld b,(hl) / jr 0x5809`. **No instruction in the cartridge calls it** — all four
call sites go to the two-byte version.
