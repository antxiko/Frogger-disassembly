# Open questions

What is not known. None of this is dressed up as a finding anywhere else on
this site.

## Twelve bytes nobody reads

0x49AB–0x49B6, right behind the eight VDP registers:

    49AB  00 70 38 70  00 A0 38 70  00 F0 38 F0

The loop at 0x421E reads **eight** registers and stops, and no other
instruction points here. They have the shape of three sprite records — Y, X,
drawing, colour — all three with Y = 0 and drawing 0x38, which is the
crocodile's head. What they were for is not known.

## Five loose bytes

0x49FF–0x4A03: `01 06 11 16 21`. They sit between the collision margins and the
first label list, and nothing reaches them. The gaps go 5, 11, 5, 11.

## Bit 6 of the type

Layouts 4 and 5 carry `0xCD` where `0x8D` would do: bit 7 marks the last object
of the row and the low nibble is the type, but **no instruction looks at bit
6**. It may be left over from something.

## Why the same character is uploaded B times

0x47DA reads a count and eight bytes of drawing, and pushes that same drawing
to video memory as many times as the count says, then again reversed
(`push hl` / `pop hl` restore the pointer each turn). It has been read, but why
it is worth repeating the same character has not been checked in the emulator.

## Nothing measured in the emulator

There is not one openMSX figure here: not the cost of the interrupt, not the
VDP writes per frame, not how long a lane takes to cross. Everything on this
site comes from reading the binary.
