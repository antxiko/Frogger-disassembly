# Frogger (MSX, Konami 1983) — desensamblado comentado

Desensamblado completo y comentado de **Frogger** para MSX: el cartucho
**RC-704** de Konami, 8 KB en la página 1. Es el más pequeño de Konami de toda
esta serie: la mitad que cualquiera de los otros.

**El 100 % del binario está explicado**, se reensambla en el original byte a
byte, y aquí no hay ninguna suposición disfrazada de hecho.

📖 **[Leer la web](https://antxiko.github.io/Frogger-disassembly/es/)** ·
🇬🇧 **[In English](README.md)**

## Qué hay aquí

| | bytes | |
|---|---|---|
| código trazado | 4.880 | 59,57 % |
| datos identificados | 3.312 | 40,43 % |
| **sin explicar** | **0** | **0,00 %** |

**314 etiquetas** (ninguna sin bautizar), **482 comentarios anclados** —el
18,8 % de las instrucciones— y **69 rangos de datos**, cada uno con su nombre,
su explicación y la anchura de sus filas. **23 comprobaciones** lo vigilan todo.

## Algo de lo que apareció

- **Frogger y Time Pilot llevan dentro el mismo reproductor de sonido.** No se
  parecen: son los mismos 163 bytes, con solo **tres** distintos, y dos de ellos
  el byte bajo de un puntero reubicado. El tercero es el registro 7 del PSG, que
  pone el ruido en el canal B aquí y en el C allí.
- **La demo entera son quince bytes**, uno por movimiento, en 0x584F.
- **Trazados distintos hay cuatro, no cinco**: dos huecos del ciclo apuntan a la
  misma descripción, así que las fases 2 y 3 son el mismo tablero.
- **A partir de la fase 11 el juego ya no se endurece más**, y en la fase 100 el
  contador vuelve a 1 sin más. No hay final.
- **Los troncos y los coches no gastan un solo sprite**: cuatro versiones
  pregeneradas de cada dibujo, desplazadas 0, 2, 4 y 6 píxeles.
- **Una rutina que no llama nadie**, en 0x57F7.

La lista entera, con sus direcciones y sus cifras, está en
[docs/es/HALLAZGOS.md](docs/es/HALLAZGOS.md). Lo que *no* se sabe está en
[docs/es/PREGUNTAS-ABIERTAS.md](docs/es/PREGUNTAS-ABIERTAS.md), y lo dice.

## Cómo se usa

La imagen del cartucho **no se distribuye aquí**. Ponla en la raíz como
`frogger.rom` —8192 bytes, sha256 `0d60ff78…86323c5f5`— y:

    make            # trazado, listado, reensamblado, comprobaciones y tests
    make verify     # reensambla y compara con la ROM, byte a byte
    make sanity     # ni un byte se puede quedar sin asignar
    make web        # rehace la web

Hacen falta Python 3, `pasmo` y `z80dasm`. Las instrucciones completas están en
[docs/es/EMPEZAR.md](docs/es/EMPEZAR.md).

## Aviso legal

Esto es trabajo de documentación y preservación. El código y los gráficos
siguen siendo de sus autores y de Konami, y **la imagen del cartucho no se
distribuye**. Ver [AVISO-LEGAL.md](AVISO-LEGAL.md).
