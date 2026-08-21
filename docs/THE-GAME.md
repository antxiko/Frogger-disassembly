# The game

A frog crosses a road and a river to reach five homes at the top. It is the
1981 arcade game, cut down to eight kilobytes.

## The title screen

The screen is built from label lists (0x4A04 and four more), and it waits for
one of four keys:

| key | players | controls |
|---|---|---|
| **1** | one | joystick |
| **2** | two | joystick |
| **3** | one | keyboard |
| **4** | two | keyboard |

`0xE007` holds which one: 1 reads PSG register 14 (the joystick), 0 reads row 8
of the keyboard (the cursor keys, translated through the table at 0x49B7).

Before the title, and only the first time, there is a short presentation: a
frog climbing the screen a row at a time from row 20 up to row 3 (0x427F).
Pressing any of the four keys cuts it short.

## The screen

The playfield is **22 columns wide**, from column 2 to column 23; the rest of
the screen is the scoreboard down the right-hand side, from column 25.

| rows | |
|---|---|
| 0 | the five homes, four characters each, at columns 4, 8, 12, 16 and 20 |
| 1–2 | the border below them |
| 3, 5, 7, 9 | the river: logs, turtles and the crocodile |
| 11–12 | the median, one character repeated 22 times |
| 13, 15, 17, 19 | the road: four kinds of vehicle |
| 21–23 | the bank the frog starts from |

## The frog

Up and down move **16 pixels** — a whole row. Left and right move only **8**,
half a cell. Each jump changes the drawing: 0x04 facing up, 0x10 down, 0x1C
left and 0x24 right.

The frog is **two sprites**. While a jump lasts, the second one stays behind in
the cell it left.

**Ten points** for every jump forward (`ld bc,0x0010`, in BCD). Jumping
backwards gives nothing.

## The homes

Each of the five has its own bit in 0xE080. Landing on one that is **already
taken** is not a bounce and not a warning: 0x528F reads the bit and, if it was
set, jumps straight to the death routine.

Filling all five ends the stage. Whatever is left on the clock is cashed in at
**ten points a unit**, one every two frames.

## The clock

The time starts at 0x96 and drops by one every 20 frames. The whole count is
BCD —0x5104 subtracts with `add a,099h / daa`, and the thresholds are compared
as `cp 060h` and `cp 032h`— so that 0x96 is **ninety-six** units, not 150: at 20
frames each, 32 seconds on a 60 Hz machine. Running out kills the frog.

Two things happen along the way that are easy to miss: at **0x60** four objects
in row 15 speed up, once per stage; and at **0x32** the character the time bar
is drawn with changes colour.

## Lives and extra lives

Three lives. The extra life threshold lives in 0xE005 and is compared against
the **high byte** of the score, which counts tens of thousands: it starts at 1
and goes up by 5, so the first extra life comes at **10,000** and the rest every
**50,000**.

Only seven lives are ever drawn, however many there are.
