# The cartridge

## The header and the machine

An 8 KB cartridge in **page 1**, from 0x4000 to 0x5FFF. It is the smallest
Konami cartridge in this series — half of any of the others.

    4000  41 42 b4 41 00 00 00 00 ...      "AB", then INIT = 0x41B4

Only INIT is declared; the other three vectors are zero. INIT hooks the
interrupt by writing `jp 0x4012` into H.KEYI (0xFD9A) one byte at a time, wipes
the 2 KB of game RAM with a single `LDIR`, puts the stack at 0xE7FF and loads
the title screen.

## Video memory

SCREEN 2, with the eight registers coming from 0x49A3:

| | |
|---|---|
| name table | 0x3800 |
| pattern table | 0x2000 |
| colour table | 0x0000 |
| sprite attributes | 0x3B00 |
| sprite patterns | 0x1800, 16×16 |

SCREEN 2 splits patterns and colours into three 2 KB thirds and the game wants
them identical. It gets that with **one copy of 4095 bytes** whose destination
runs 2 KB ahead of the source (0x471A): past the first third it is already
reading what it just wrote, so the second propagates into the third by itself.

## The characters

Twelve blocks with a header — destination, size, data — go up from 0x4B36
(0x4956 reads them). Then the same bytes go up **a second time**, at characters
0x98 and 0xB7, because in SCREEN 2 colour goes per pattern line and the same
character cannot be two colours. The colour table gives cyan to one copy and
white to the other.

The digits of the scoreboard are patterns 0xE0 to 0xE9, which is why printing a
BCD number is just adding 0xE0 to the digit (0x4651).

## The moving characters

Logs, turtles and cars are **not sprites**. They are characters, and to move
them two pixels at a time the cartridge keeps **four versions of every drawing**
in video memory, shifted 0, 2, 4 and 6 pixels (0x473C).

Each object's position is stored in **quarters of a character**: the low two
bits pick the version and the rest is the column. Each row is assembled in a
RAM buffer of two rows of 40 columns (0xE600) and 22 columns of it are then
pushed to video memory.

## The sprites

Only four things use sprites: the frog (two), the crocodile (four), the
creature that crosses the river and the frog you rescue. That is what the MSX1's
limit of four sprites per line is being saved for.

## The sound

Three channels, each with an 8-byte record (0xE020, 0xE028, 0xE030). A tune is
a string of **three-byte notes**: fine period, coarse period with the volume in
the top nibble and bit 3 for noise, and duration. A negative duration makes the
note fade on its own. 0xFF ends the tune.

Priority is by address: 0x50E7 only takes a new effect if the channel is quiet
or if the tune being asked for sits at a **lower address** than the one playing.

These 163 bytes are the same code as Time Pilot's — see
[Findings](FINDINGS.html).

## What it is made of

| | bytes | |
|---|---|---|
| traced code | 4,880 | 59.57 % |
| identified data | 3,312 | 40.43 % |
| **unexplained** | **0** | **0.00 %** |
