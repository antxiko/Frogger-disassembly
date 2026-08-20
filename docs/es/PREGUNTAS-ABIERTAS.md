# Preguntas abiertas

Lo que no se sabe. Nada de esto está disfrazado de hallazgo en ninguna otra
página de esta web.

## Doce bytes que no lee nadie

0x49AB–0x49B6, justo detrás de los ocho registros del VDP:

    49AB  00 70 38 70  00 A0 38 70  00 F0 38 F0

El bucle de 0x421E lee **ocho** registros y para, y ninguna otra instrucción
apunta aquí. Tienen forma de tres fichas de sprite —Y, X, dibujo, color—, las
tres con Y = 0 y el dibujo 0x38, que es la cabeza del cocodrilo. Para qué eran,
no se sabe.

## Cinco bytes sueltos

0x49FF–0x4A03: `01 06 11 16 21`. Están entre los márgenes de choque y la
primera lista de rótulos, y no los alcanza nada. Los saltos van de 5, 11, 5, 11.

## El bit 6 del tipo

Los trazados 4 y 5 llevan `0xCD` donde bastaría `0x8D`: el bit 7 marca el
último objeto de la fila y el nibble de abajo es el tipo, pero **ninguna
instrucción mira el bit 6**. Puede ser un resto de algo.

## Por qué se sube el mismo carácter B veces

0x47DA lee un contador y ocho bytes de dibujo, y sube ese mismo dibujo a la
memoria de vídeo tantas veces como diga el contador, y después otras tantas del
revés (el `push hl` / `pop hl` le devuelve el puntero en cada vuelta). Está
leído, pero para qué merece la pena repetir el mismo carácter no se ha
comprobado en el emulador.

## Nada medido en el emulador

Aquí no hay ni una cifra de openMSX: ni el coste de la interrupción, ni las
escrituras al VDP por fotograma, ni lo que tarda un carril en cruzar. Todo lo
que hay en esta web sale de leer el binario.
