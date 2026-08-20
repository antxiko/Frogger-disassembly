# El código

## La interrupción reparte el trabajo

La BIOS entra en 0x4012 en cada retrazo. Lo primero que decide es de qué se
ocupa este fotograma, leyendo **0xE043**: el bit 0 significa solo la demo y el
sonido, el bit 6 solo el sonido. Sin partida en marcha, lo único que hace es
subir el contador de fotogramas.

Después decide **qué escena** toca, leyendo **0xE040** bit a bit con `rrca`:

| bit | |
|---|---|
| 0 | la muerte |
| 1 | el bonus del tiempo (dentro del juego) |
| 2 | fase superada |
| 3 | se acabó la partida |
| 4 | montar la fase |

Sin ninguno puesto, corre el juego normal: los carriles, la rana, el bicho del
río, la rana que se rescata y los choques, en ese orden.

## El buscador con la tabla detrás del call

0x57FF no es un despachador que salte. Coge **la dirección de retorno como base
de una tabla** incrustada justo detrás del `call`, devuelve en BC la palabra
número A, avanza hasta el 0xFF que cierra la tabla y hace `ret` al byte de
después.

Lo usan cuatro sitios, y es lo único que un trazador no puede seguir solo: esas
cuatro tablas hay que declararlas a mano, o 700 bytes de listas de rótulos se
leen como instrucciones.

## El motor de los carriles

Ocho filas se mueven —cuatro de río y cuatro de carretera— y no caben en un
fotograma, así que van repartidas en tres (0x55E5). Cada fila tiene además **su
propio reloj** en un solo byte: el nibble de abajo cuenta y el de arriba dice
cada cuánto (0x5682).

Cada objeto es una **ficha de cuatro bytes**: tipo y banderas, posición en
cuartos de carácter, velocidad con signo y el contador de hundirse.

## Las tortugas que se hunden

Los tipos 7 a 12 se animan, pero solo si el bit 7 del cuarto byte está puesto —y
ese bit se escribe **a mano, en dos direcciones**, al montar la fase. El
contador da una vuelta de 0x80 a 0xC0 y por el camino el tipo sube uno en 0x90
y otro en 0xA0, y vuelve a bajar en 0xB0 y en 0xC0. Como el tipo es el que
elige el dibujo, la tortuga se hunde y vuelve a salir sola.

Los tipos **9 y 12 tienen los cuatro márgenes de choque a cero** (0x49C7): son
las que están del todo bajo el agua, y por eso no sostienen a la rana.

## El cocodrilo

Lo único del río que va con sprites, y son cuatro. Abre y cierra la boca en un
ciclo de 32 pasos: 22 con el dibujo 0x40 y 10 con el 0x3C. Con la boca abierta,
0x524F comprueba la cabeza aparte y esa **mata** en vez de sostener.

## Los choques

Todo se comprueba contra la rana en el mismo sitio (0x5185): el bicho del río,
la rana que se rescata, los bordes de la pantalla y, si está en el agua, la
fila de troncos que le toque. Cuál es esa fila sale de a qué altura ha llegado
(0xE28A).

En el agua, tocar algo es lo que **salva**. En la carretera es lo que mata.

## La demo

Ningún generador de números. La rana la mueve una lista de **quince bytes** en
0x584F, uno por movimiento y con el mismo formato que los mandos. El puntero de
0xE049 vuelve al principio al montar cada fase, y solo se le incrementa el byte
bajo, así que la lista no puede cruzar de página.
