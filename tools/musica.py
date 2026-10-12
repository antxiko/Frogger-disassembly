#!/usr/bin/env python3
"""La musica del cartucho, ejecutando su motor de sonido (ver motor_musica.py).

Frogger no tiene una rutina de "pedir sonido": quien quiere que suene algo
escribe el puntero de su pista en la ficha de un canal (0xE020, 0xE028, 0xE030)
y `PASO_DE_CANAL` (0x4111), que la interrupcion llama una vez por canal desde
0x40ED, 0x40F3 y 0x40F9, la va tocando. Aqui cada pieza es esa lista de
escrituras (PISTAS), con el numero 1, 2... como clave.
Uso:  musica.py registros 1 [cuadros] | mp3 1 f.mp3 | todas docs/audio | emu
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402
from motor_musica import P  # noqa: E402

# Las fichas de los tres canales, de ocho en ocho: puntero (2 bytes), lo que le
# queda a la nota, el registro del PSG del canal (0, 2, 4), volumen, ...
FICHAS = (0xE020, 0xE028, 0xE030)
LIBRES = [("b", f + 2, 0) for f in FICHAS]        # sin nota a medias


def canales(*punteros):
    return LIBRES + [("w", f, p) for f, p in zip(FICHAS, punteros)]


PISTAS = {
    1: canales(0x5D97, 0x5DE9, 0x5E41),       # 0x442B: la musica de arranque
    2: canales(0x5FB6, 0x5FD8),               # FIN_DE_PARTIDA (0x4596)
    3: canales(0x5F18, 0x5F5E),               # la fase superada (0x5411)
}

PIEZAS = [
    P(1, "La música de arranque", "The start-up tune",
      "`Y_LA_FASE_DE_LOS_DOS` (0x442B): tres canales, programas de 0x5D97, "
      "0x5DE9 y 0x5E41"),
    P(2, "El final de la partida", "The end of the game",
      "`FIN_DE_PARTIDA` (0x4596): dos canales, programas de 0x5FB6 y 0x5FD8"),
    P(3, "La fase superada", "Stage cleared",
      "la rutina de 0x5411: dos canales, programas de 0x5F18 y 0x5F5E"),
]

PAGINA = motor_musica.pagina_basica(
    "`PASO_DE_CANAL`, 0x4111, una vez por canal desde la interrupción, y las "
    "pistas que cada rutina apunta en las fichas de 0xE020, 0xE028 y 0xE030",
    "`PASO_DE_CANAL`, 0x4111, once per channel from the interrupt, and the "
    "tracks each routine points the channel records at, 0xE020, 0xE028 and "
    "0xE030",
    "C-BIOS MSX1 japonés",
    [("la música de arranque entera, 362 cuadros",
      "the start-up tune, whole, 362 frames"),
     ("la fase superada entera, 322 cuadros, salvo el canal C, que en la "
      "partida seguía con otro sonido",
      "the stage-cleared tune, whole, 322 frames, except channel C, which "
      "in the game was still on another sound")],
    [("Cómo suena una pieza",
      "Este juego no tiene una rutina que reciba el número de un sonido: quien "
      "quiere que suene algo escribe en la ficha de un canal el puntero de su "
      "pista, y `PASO_DE_CANAL` la va leyendo nota a nota. Cada ficha son ocho "
      "bytes: puntero, lo que queda de la nota, el registro del PSG del canal "
      "(0, 2 o 4), el volumen... Es el mismo reproductor que el de otros "
      "cartuchos de Konami de la época. El cotejo con openMSX se hizo "
      "escribiendo esas mismas fichas en la partida, ya en juego, y "
      "comparando lo que el PSG recibe a partir de ahí. El motor no escribe "
      "el mezclador del PSG salvo para el ruido: lo deja el arranque, y aquí "
      "se parte de su mismo valor, 0xB8.",
      "How a piece plays",
      "This game has no routine that takes a sound number: whoever wants "
      "something to play writes the pointer to its track into a channel "
      "record, and `PASO_DE_CANAL` reads it note by note. Each record is "
      "eight bytes: pointer, what is left of the note, the channel's PSG "
      "register (0, 2 or 4), the volume... It is the same player as in other "
      "Konami cartridges of the time. The openMSX check was done by writing "
      "those same records during play and comparing what the PSG receives "
      "from then on. The engine does not write the PSG mixer except for "
      "noise: start-up leaves it set, and here it starts from the same "
      "value, 0xB8.")])

CFG = dict(rom="frogger.rom", org=0x4000, bp_frame=0x40EA,
           frame=[(0x4111, {"hl": 0xE021}), (0x4111, {"hl": 0xE029}),
                  (0x4111, {"hl": 0xE031})],
           ram=(0xE020, 0xE038), ram0=[(0xE02B, 2), (0xE033, 4)], hz=60,
           psg0={7: 0xB8}, pistas=PISTAS, piezas=PIEZAS, pagina=PAGINA,
           cotejado=[(1, 362, None), (3, 322, None)])

if __name__ == "__main__":
    sys.exit(motor_musica.main(CFG, sys.argv[1:]))
