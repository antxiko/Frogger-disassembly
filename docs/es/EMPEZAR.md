# Empezar

Este repositorio contiene un **desensamblado comentado** de Frogger para MSX
(Konami, 1983, cartucho RC-704). Todo lo que hay aquí sale del binario y se
puede volver a generar desde él.

## Lo que hace falta

- **Python 3** (sin paquetes de terceros)
- **pasmo**, para reensamblar
- **z80dasm**, que solo se usa para los mnemónicos
- la imagen del cartucho, que este repositorio **no distribuye**

La ROM va en la raíz, como `frogger.rom`. Son 8192 bytes exactos:

    sha256  0d60ff78e1ab466bce6e888193ca62d6df71fa07344c8ea31f7a8b486323c5f5

`make comprueba` lo verifica.

## Los comandos

    make                # trazado, listado, reensamblado, comprobaciones y tests
    make listado        # rehace src/frogger.asm a partir de las anotaciones
    make verify         # reensambla y compara con la ROM, byte a byte
    make sanity         # nada declarado como datos puede salir como código,
                        # y ni un byte puede quedarse sin asignar
    make test           # las comprobaciones
    make imagenes       # rehace las imágenes a partir de la ROM
    make web            # rehace esta web

## Qué hay en cada carpeta

| | |
|---|---|
| `src/frogger.entries` | los puntos de entrada, cada uno con su justificación |
| `src/frogger.nocode` | las cuatro tablas que el trazador no debe leer como código |
| `src/frogger.notes` | **lo único que se edita a mano**: todas las anotaciones |
| `src/frogger.asm` | el listado, lo genera `tools/mkasm.py` |
| `tools/` | el trazador, el generador del listado y las herramientas de medida |
| `tests/` | 23 comprobaciones sobre el listado y las anotaciones |
| `docs/` | esta web |

## Cómo se lee el listado

Las anotaciones van **ancladas a una dirección**, así que sobreviven a un
retrazado. Las directivas siguen las pautas de theNestruo:

| | |
|---|---|
| `L` | una etiqueta y qué hace la rutina |
| `C` | un comentario en esa línea |
| `B` | una cabecera de bloque antes de esa dirección |
| `D` | un rango de datos, con su nombre y su explicación |
| `F` | la anchura de las filas de un bloque de datos |

## Cómo se hizo

El trazador sigue el flujo real desde los puntos de entrada. Lo que no se puede
deducir estáticamente —el gancho de la interrupción, las cuatro tablas
incrustadas detrás de un `call`— se declara a mano en el `.entries`, con la
razón escrita al lado.

Aquí no hay ninguna suposición disfrazada de hecho. Lo que no se sabe está en
[Preguntas abiertas](PREGUNTAS-ABIERTAS.html) y lo dice.

## Que se pueda repetir

`make verify` reensambla el listado y compara el resultado con la ROM original.
Tiene que salir **idéntico, byte a byte**. Y `make sanity` comprueba después lo
que el reensamblado no puede cazar: que ningún rango declarado como datos se
esté leyendo como código, y que **ni uno solo de los 8192 bytes** se quede sin
asignar.
