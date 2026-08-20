# Frogger (MSX, Konami 1983) — a commented disassembly

A full, commented disassembly of **Frogger** for MSX: Konami's cartridge
**RC-704**, 8 KB in page 1. It is the smallest Konami cartridge in this series —
half of any of the others.

**100 % of the binary is explained**, it reassembles into the original
byte for byte, and nothing here is a guess dressed up as a fact.

📖 **[Read the site](https://antxiko.github.io/Frogger-disassembly/)** ·
🇪🇸 **[En castellano](README.es.md)**

## What is in here

| | bytes | |
|---|---|---|
| traced code | 4,880 | 59.57 % |
| identified data | 3,312 | 40.43 % |
| **unexplained** | **0** | **0.00 %** |

**314 labels** (not one left unnamed), **482 anchored comments** — 18.8 % of the
instructions — and **69 data ranges**, each with its name, its explanation and
the width of its rows. **23 tests** watch over all of it.

## Some of what turned up

- **Frogger and Time Pilot carry the same sound player.** Not similar: the same
  163 bytes, with only **three** different — two of them the low byte of a
  relocated pointer, and the third PSG register 7, which puts the noise on
  channel B here and on channel C there.
- **The whole demo is fifteen bytes**, one per move, at 0x584F.
- **There are four layouts, not five**: two slots of the cycle point at the same
  description, so stages 2 and 3 are the same board.
- **From stage 11 on the game stops getting harder**, and on stage 100 the
  counter simply goes back to 1. There is no ending.
- **Logs and cars do not spend a single sprite**: four pre-generated versions of
  every drawing, shifted 0, 2, 4 and 6 pixels.
- **A routine nobody calls**, at 0x57F7.

The full list, with addresses and figures, is in
[docs/FINDINGS.md](docs/FINDINGS.md). What is *not* known is in
[docs/OPEN-QUESTIONS.md](docs/OPEN-QUESTIONS.md), and it says so.

## Running it

The cartridge image is **not distributed here**. Put it in the root as
`frogger.rom` — 8192 bytes, sha256 `0d60ff78…86323c5f5` — and:

    make            # trace, listing, reassembly, checks and tests
    make verify     # reassemble and compare against the ROM, byte for byte
    make sanity     # not one byte may be left unassigned
    make web        # rebuild the site

You need Python 3, `pasmo` and `z80dasm`. Full instructions in
[docs/GETTING-STARTED.md](docs/GETTING-STARTED.md).

## Legal notice

This is documentation and preservation work. The code and artwork still belong
to their authors and to Konami, and **the cartridge image is not distributed**.
See [LEGAL-NOTICE.md](LEGAL-NOTICE.md).
