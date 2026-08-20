# El cartucho

## La cabecera y la máquina

Un cartucho de 8 KB en la **página 1**, de 0x4000 a 0x5FFF. Es el más pequeño
de Konami de toda esta serie: la mitad que cualquiera de los otros.

    4000  41 42 b4 41 00 00 00 00 ...      "AB", y detrás INIT = 0x41B4

Solo se declara INIT; los otros tres vectores van a cero. INIT engancha la
interrupción escribiendo `jp 0x4012` en H.KEYI (0xFD9A) byte a byte, borra los
2 KB de RAM del juego con un solo `LDIR`, deja la pila en 0xE7FF y carga la
pantalla de título.

## La memoria de vídeo

SCREEN 2, con los ocho registros saliendo de 0x49A3:

| | |
|---|---|
| tabla de nombres | 0x3800 |
| tabla de patrones | 0x2000 |
| tabla de color | 0x0000 |
| atributos de sprite | 0x3B00 |
| patrones de sprite | 0x1800, de 16×16 |

SCREEN 2 parte los patrones y los colores en tres tercios de 2 KB, y el juego
los quiere iguales. Lo consigue con **una copia de 4095 bytes** cuyo destino va
2 KB por delante del origen (0x471A): al pasar del primer tercio ya está
leyendo lo que acaba de escribir, así que el segundo se propaga solo al
tercero.

## Los caracteres

Doce bloques con cabecera —destino, tamaño, datos— suben desde 0x4B36 (los lee
0x4956). Y después los mismos bytes suben **otra vez**, a los caracteres 0x98 y
0xB7, porque en SCREEN 2 el color va por línea de patrón y el mismo carácter no
puede tener dos colores. La tabla de color le da cian a una copia y blanco a la
otra.

Las cifras del marcador son los patrones 0xE0 a 0xE9, y por eso pintar un
número BCD es sumarle 0xE0 al dígito (0x4651).

## Los caracteres que se mueven

Los troncos, las tortugas y los coches **no son sprites**. Son caracteres, y
para moverlos de dos en dos píxeles el cartucho guarda en la memoria de vídeo
**cuatro versiones de cada dibujo**, desplazadas 0, 2, 4 y 6 píxeles (0x473C).

La posición de cada objeto va en **cuartos de carácter**: sus dos bits de abajo
eligen la versión y el resto es la columna. Cada fila se monta en un búfer de
RAM de dos filas de 40 columnas (0xE600) y de ahí se vuelcan 22 columnas a la
memoria de vídeo.

## Los sprites

Solo cuatro cosas gastan sprites: la rana (dos), el cocodrilo (cuatro), el
bicho que cruza el río y la rana que hay que rescatar. Para eso se está
guardando el límite de cuatro sprites por línea del MSX1.

## El sonido

Tres canales, cada uno con una ficha de 8 bytes (0xE020, 0xE028, 0xE030). Una
partitura es una tira de **notas de tres bytes**: periodo fino, periodo grueso
con el volumen en el nibble de arriba y el bit 3 para el ruido, y duración. Con
la duración negativa la nota se apaga sola. El 0xFF cierra la partitura.

La prioridad va por dirección: 0x50E7 solo acepta un efecto nuevo si el canal
está callado o si la partitura que se pide está en una dirección **más baja**
que la que suena.

Estos 163 bytes son el mismo código que el de Time Pilot: ver
[Hallazgos](HALLAZGOS.html).

## De qué está hecho

| | bytes | |
|---|---|---|
| código trazado | 4.880 | 59,57 % |
| datos identificados | 3.312 | 40,43 % |
| **sin explicar** | **0** | **0,00 %** |
