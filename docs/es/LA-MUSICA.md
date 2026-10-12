# La música

Todo lo que suena aquí sale de ejecutar el motor de sonido del cartucho (`PASO_DE_CANAL`, 0x4111, una vez por canal desde la interrupción, y las pistas que cada rutina apunta en las fichas de 0xE020, 0xE028 y 0xE030) en un Z80 emulado, cuadro a cuadro y a 60 por segundo, igual que lo llama el juego. Lo que el motor escribe en el PSG pasa a sonido con un AY-3-8910 (`tools/musica.py`). Cada MP3 es la pieza entera hasta donde vuelve a empezar, más 8 segundos de la vuelta apagándose; las que no se repiten acaban donde acaba el motor.

## Cotejado con openMSX

Las escrituras al PSG se han comparado cuadro a cuadro con las de openMSX (C-BIOS MSX1 japonés). En todos los cuadros el PSG queda igual:

- la música de arranque entera, 362 cuadros;
- la fase superada entera, 322 cuadros, salvo el canal C, que en la partida seguía con otro sonido.

El timbre no está cotejado: es el de un AY-3-8910 de manual, no una grabación del emulador. Las sondas están en `tools/omsx_psg.tcl` y `tools/coteja_psg.py`.

## Cómo suena una pieza

Este juego no tiene una rutina que reciba el número de un sonido: quien quiere que suene algo escribe en la ficha de un canal el puntero de su pista, y `PASO_DE_CANAL` la va leyendo nota a nota. Cada ficha son ocho bytes: puntero, lo que queda de la nota, el registro del PSG del canal (0, 2 o 4), el volumen... Es el mismo reproductor que el de otros cartuchos de Konami de la época. El cotejo con openMSX se hizo escribiendo esas mismas fichas en la partida, ya en juego, y comparando lo que el PSG recibe a partir de ahí. El motor no escribe el mezclador del PSG salvo para el ruido: lo deja el arranque, y aquí se parte de su mismo valor, 0xB8.

## Las músicas

**La música de arranque** (0x01)

Lo pide `Y_LA_FASE_DE_LOS_DOS` (0x442B): tres canales, programas de 0x5D97, 0x5DE9 y 0x5E41; dura 6,0 s.

<audio controls preload="none" src="../audio/musica_01.mp3?v=ef0f1d6a"></audio>

**El final de la partida** (0x02)

Lo pide `FIN_DE_PARTIDA` (0x4596): dos canales, programas de 0x5FB6 y 0x5FD8; dura 2,7 s.

<audio controls preload="none" src="../audio/musica_02.mp3?v=9d67cbd0"></audio>

**La fase superada** (0x03)

Lo pide la rutina de 0x5411: dos canales, programas de 0x5F18 y 0x5F5E; dura 5,4 s.

<audio controls preload="none" src="../audio/musica_03.mp3?v=153ecb43"></audio>
