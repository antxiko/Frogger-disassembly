# The code

## The interrupt shares out the work

The BIOS enters at 0x4012 on every retrace. The first thing it decides is what
this frame is for, by reading **0xE043**: bit 0 means only the demo and the
sound, bit 6 only the sound. With no game running, all it does is bump the
frame counter.

Then it decides **which scene**, by reading **0xE040** one bit at a time with
`rrca`:

| bit | |
|---|---|
| 0 | the death |
| 1 | the time bonus (inside the game) |
| 2 | stage cleared |
| 3 | the game is over |
| 4 | build the stage |

With none of them set, the normal game runs: the lanes, the frog, the river
creature, the frog to be rescued and the collisions, in that order.

## The table lookup behind the call

0x57FF is not a dispatcher that jumps. It takes **the return address as the
base of a table** embedded right behind the `call`, returns the Ath word in BC,
walks forward to the 0xFF that closes the table and `ret`s to the byte after
it.

Four places use it, and it is the one thing a tracer cannot follow on its own:
those four tables have to be declared by hand, or 700 bytes of label lists get
read as instructions.

## The lane engine

Eight rows move — four of river and four of road — and they do not fit in one
frame, so they are spread over three (0x55E5). Each row also has **its own
clock** in a single byte: the low nibble counts down and the high one says how
often (0x5682).

Every object is a **four-byte record**: type and flags, position in quarters of
a character, signed speed, and the diving counter.

## The turtles that dive

Types 7 to 12 animate, but only if bit 7 of the fourth byte is set — and that
bit is written **by hand, at two addresses** when the stage is built. The
counter runs from 0x80 to 0xC0 and on the way the type goes up one at 0x90 and
another at 0xA0, then back down at 0xB0 and 0xC0. Since the type is what picks
the drawing, the turtle sinks and comes back up on its own.

Types **9 and 12 have all four collision margins at zero** (0x49C7): those are
the fully submerged ones, which is why they do not hold the frog up.

## The crocodile

The only thing in the river drawn with sprites — four of them. It opens and
closes its mouth on a 32-step cycle: 22 steps with drawing 0x40 and 10 with
0x3C. With the mouth open, 0x524F checks the head separately and it **kills**
instead of carrying.

## The collisions

Everything is checked against the frog in one place (0x5185): the river
creature, the frog to be rescued, the screen edges and, if the frog is in the
water, whichever row of logs it is standing on. Which row that is comes from
how far up it has got (0xE28A).

In the water, touching something is what **saves** you. On the road it is what
kills you.

## The demo

No random generator. The frog is driven by a list of **fifteen bytes** at
0x584F, one per move, in the same format as the controls. The pointer at 0xE049
is reset to the start whenever a stage is built, and only its low byte is
incremented — so the list cannot cross a page boundary.
