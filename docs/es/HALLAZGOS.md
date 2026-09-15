# Hallazgos

Todo lo que hay aquí va anclado a una dirección y a una cifra que se puede
comprobar contra el binario. Lo que es una suposición está en
[Preguntas abiertas](PREGUNTAS-ABIERTAS.html), no aquí.

## Frogger y Time Pilot llevan dentro el mismo reproductor de sonido

No se parecen: son **el mismo código**. Los 163 bytes de 0x4111–0x41B3 de aquí
y los de 0x4160–0x4202 de Time Pilot (RC-703) coinciden byte a byte salvo en
**tres**:

| Frogger | Time Pilot | |
|---|---|---|
| 0x4137: `A1` | 0x4186: `F0` | el byte bajo de un puntero, 0x41A1 contra 0x41F0 |
| 0x4171: `A1` | 0x41C0: `F0` | el mismo puntero otra vez |
| 0x415D: `A8` | 0x41AC: `98` | **el registro 7 del PSG, la mezcla** |

Los dos primeros son la misma rutina reubicada: 0x41A1 + 0x4F = 0x41F0,
exactamente el desfase que separa las dos copias. El tercero es el único que
dice algo distinto: **el ruido suena en el canal B en Frogger y en el C en Time
Pilot**.

La prueba cruzada: las diez etiquetas que el trazador encontró aquí él solo
(L_4111, L_412F, L_413E, L_4167, L_4189, L_4190, L_4192, L_41A1, L_41AA,
L_41B4) caen una por una en las diez que ya tenían nombre en Time Pilot al
restarles 0x4F. No sobra ninguna por ninguno de los dos lados. Y en los dos
cartuchos el reproductor está colocado justo antes de INIT.

## No lleva la marca oculta de Konami

Muchos cartuchos de la casa esconden al final de la ROM su número de catálogo y el título en katakana; lo descubrió **Manuel Pazos** ([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)). Este no: detrás del último byte con contenido solo quedan los 16 bytes de relleno 0xFF con los que acaba el cartucho. Y no es que esté en otro sitio: se rastrearon las 8.192 posiciones con un buscador que sí la encuentra en los cartuchos de la serie que la llevan.

## La demo entera son quince bytes

    584F  00 08 01 01 01 01 01 08 01 01 01 01 08 00 01

Un byte por movimiento, con el mismo formato que los mandos: 0x01 arriba, 0x08
a la derecha, 0x00 quieta. Espera, derecha, cinco veces arriba, derecha, cuatro
arriba, derecha, espera y una más arriba.

## Trazados distintos hay cuatro, no cinco

La fase se elige con `(fase-1) mod 5` sobre la tabla de cinco palabras de
0x5457 —pero la segunda y la tercera **apuntan las dos a 0x5CCD**. Las fases 2
y 3 llevan exactamente el mismo trazado.

Lo que las separa son dos retoques que hace 0x5493 solo en el tercer hueco: el
primer objeto de la fila de arriba pasa a ser **cocodrilo**, y al segundo de la
fila 15 se le pone el bit de «último», con lo que esa fila se queda con dos
objetos en vez de tres.

## A partir de la fase 11 el juego ya no se endurece más

En todo el cartucho hay **cuatro** comparaciones contra el número de fase:

| fase | | dónde |
|---|---|---|
| 2 | ocho objetos del río suben dos de tipo | 0x54A8 |
| 3 | aparece la rana que hay que rescatar | 0x506A |
| 6 | dos carriles pasan a moverse un paso por turno, y se añade una tercera tortuga que se hunde | 0x54C9 |
| 11 | la fila 7 se queda con un solo objeto | 0x54DB |

De ahí en adelante lo único que cambia es cuál de los cuatro trazados toca, y
eso cicla cada cinco. La fase 11, la 47 y la 99 se juegan igual.

Y no hay final: en la fase **100** el contador vuelve a 1 (0x53F5) y el número
BCD del marcador vuelve a 01. Sin rótulo, sin música y sin pantalla.

## Las tortugas que se hunden están elegidas a mano, una por una

Hundirse es un bit, no una propiedad. Al montar la fase, 0x5489 lo pone en
**exactamente dos direcciones** —0xE0C3 y 0xE0EB— con los contadores en 0x80 y
0x8A para que los dos grupos no se hundan a la vez. A partir de la fase 6,
0x54D6 añade una tercera (0xE0E7, con el contador en 0x8F).

## Los troncos y los coches no gastan un solo sprite

Cuatro versiones de cada dibujo, desplazadas 0, 2, 4 y 6 píxeles, generadas al
arrancar corriendo el juego entero de patrones dos bits cada vez y dejando que
los bits que se salen entren en el carácter de al lado (0x473C). Las posiciones
van en cuartos de carácter, y sus dos bits de abajo eligen la versión.

## Tres tercios de pantalla igualados con una sola copia

Una copia de 4095 bytes con el destino 2 KB por delante del origen (0x471A).
Pasado el primer tercio ya está leyendo lo que acaba de escribir, así que el
segundo se propaga solo al tercero.

## Las mismas letras subidas dos veces, solo por el color

INIT manda el juego de letras a los caracteres 0xD8 y después **otra vez** al
0x98 (0x4235 y 0x4240 repiten bytes que el bloque anterior ya había subido). La
tabla de color que se carga justo después le da cian a un rango y blanco al
otro. En SCREEN 2 el color va por línea de patrón, así que esa es la única
forma de tener las mismas letras en dos colores.

## Saltar a una casa ya ocupada te mata

0x528F lee el bit de esa casa en 0xE080 y, si ya estaba puesto, `jp 0x5305`: la
rutina de la muerte. Sin rebote y sin aviso.

## Dos cosas que hace el reloj y no se ven

A los **0x60**, una sola vez por fase, cuatro objetos de la fila 15 pierden un
punto de velocidad (0x511A): van más rápido. Y a los **0x32** se repinta con
otro color el carácter con el que está dibujada la barra del tiempo (0x514B).

## Una rutina que no llama nadie

En 0x57F7 hay seis bytes de código que funciona: la versión para índices de un
byte del buscador de tablas de 0x57FF. `ex (sp),hl / ld c,a / ld b,0 /
add hl,bc / ld b,(hl) / jr 0x5809`. **Ninguna instrucción del cartucho la
llama**: las cuatro llamadas que hay van todas a la versión de dos bytes.
