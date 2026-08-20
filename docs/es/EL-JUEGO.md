# El juego

Una rana cruza una carretera y un río para llegar a cinco casas. Es el
recreativo de 1981, reducido a ocho kilobytes.

## La pantalla de título

Se monta con listas de rótulos (0x4A04 y cuatro más), y espera una de cuatro
teclas:

| tecla | jugadores | mando |
|---|---|---|
| **1** | uno | joystick |
| **2** | dos | joystick |
| **3** | uno | teclado |
| **4** | dos | teclado |

En 0xE007 se guarda cuál: con 1 se lee el registro 14 del PSG (el joystick) y
con 0 la fila 8 del teclado (los cursores, traducidos por la tabla de 0x49B7).

Antes del título, y solo la primera vez, hay una presentación corta: una rana
que sube la pantalla de fila en fila, de la 20 a la 3 (0x427F). Cualquiera de
las cuatro teclas la corta.

## La pantalla

El terreno de juego ocupa **22 columnas**, de la 2 a la 23; el resto es el
marcador del lateral derecho, desde la columna 25.

| filas | |
|---|---|
| 0 | las cinco casas, cuatro caracteres cada una, en las columnas 4, 8, 12, 16 y 20 |
| 1–2 | el borde de debajo |
| 3, 5, 7, 9 | el río: troncos, tortugas y el cocodrilo |
| 11–12 | la mediana, un solo carácter repetido 22 veces |
| 13, 15, 17, 19 | la carretera: cuatro tipos de vehículo |
| 21–23 | la orilla de la que sale la rana |

## La rana

Arriba y abajo mueven **16 píxeles**, una fila entera. Los lados solo **8**,
media casilla. Cada salto cambia el dibujo: 0x04 mirando arriba, 0x10 abajo,
0x1C a la izquierda y 0x24 a la derecha.

La rana son **dos sprites**. Mientras dura el salto, el segundo se queda
plantado en la casilla de la que salió.

**Diez puntos** por cada salto hacia adelante (`ld bc,0x0010`, en BCD). Los
saltos hacia atrás no dan nada.

## Las casas

Cada una de las cinco tiene su bit en 0xE080. Caer en una que **ya está
ocupada** no es un rebote ni un aviso: 0x528F lee el bit y, si estaba puesto,
salta derecho a la rutina de la muerte.

Llenar las cinco acaba la fase. Lo que quede de tiempo se cobra a **diez puntos
la unidad**, una cada dos fotogramas.

## El reloj

El tiempo arranca en 150 (0x96 en BCD) y baja uno cada 20 fotogramas. Que se
acabe mata a la rana.

Por el camino pasan dos cosas que no se ven jugando: a los **0x60** cuatro
objetos de la fila 15 se hacen más rápidos, una sola vez por fase; y a los
**0x32** el carácter con el que está dibujada la barra del tiempo cambia de
color.

## Vidas y vida extra

Tres vidas. El escalón de la vida extra está en 0xE005 y se compara con el
**byte alto** de los puntos, que son las decenas de millar: arranca en 1 y sube
de 5 en 5, así que la primera vida extra llega a los **10.000** y las demás cada
**50.000**.

Nunca se dibujan más de siete vidas, haya las que haya.
