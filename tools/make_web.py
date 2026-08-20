#!/usr/bin/env python3
"""Genera la portada de la web, en los dos idiomas.

El diseno es el compartido por la serie (tools/estilo_web.py) y la pagina sale
autocontenida, con las imagenes embebidas como data URI.

Ni el rotulo de la cabecera ni la galeria son ilustraciones traidas de fuera, y
tampoco son capturas: salen de repetir, paso a paso, lo que hace el propio
cartucho. tools/graficos.py reconstruye la memoria de video repitiendo las
copias de la ROM y monta la pantalla con sus mismas listas de rotulos; si un
rango estuviera mal etiquetado, la galeria saldria ruido.

Uso: make_web.py <docs/imagenes> <salida.html> <idioma>
"""
import base64
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estilo_web import ESTILO                                   # noqa: E402

# Las cifras de la portada salen de contar sobre el listado generado, no de
# escribirlas aqui a ojo: 8192 = 4880 + 3312, que es lo que imprime
# tools/presupuesto.py (make sanity).
CODIGO = 4880
DATOS = 3312
TRAZADOS = 4                        # cuatro descripciones para cinco huecos
TIPOS = 14                          # los catorce tipos de la tabla de 0x5748


def mil(n, idioma):
    return f"{n:,}".replace(",", "." if idioma == "es" else ",")


TXT = {
    "es": dict(
        titulo="Frogger — desensamblado comentado",
        aviso="<b>Aquí no hay ni una captura de pantalla.</b> Las imágenes "
              "están dibujadas repitiendo lo que hace el cartucho: se sube a "
              "la memoria de vídeo lo mismo que sube él, con sus mismas "
              "direcciones, y las filas del río y de la carretera se montan "
              "con su mismo motor de carriles. Lo demás —el listado y las "
              "cifras— sale del binario y se reproduce con <code>make</code>.",
        claim="Ocho kilobytes, la mitad que cualquier otro Konami de la "
              "serie. Los troncos y los coches no gastan un solo sprite: se "
              "mueven de dos en dos píxeles con cuatro versiones "
              "pregeneradas de cada dibujo, y la demo entera cabe en quince "
              "bytes.",
        ficha=["Konami · <b>©KONAMI 1983</b>",
               "Cartucho <b>RC-704</b>, 8 KB",
               "MSX1 · <b>página 1</b>", "Volcado <b>0d60ff78…</b>"],
        nav=[("#numbers", "Las cifras"), ("#findings", "Hallazgos"),
             ("#screens", "Lo que dibuja")],
        docnav=[("EMPEZAR.html", "Empezar"), ("EL-JUEGO.html", "El juego"),
                ("EL-CARTUCHO.html", "El cartucho"),
                ("EL-CODIGO.html", "El código"),
                ("HALLAZGOS.html", "Hallazgos"),
                ("PREGUNTAS-ABIERTAS.html", "Preguntas abiertas")],
        otro=("../", "In English"),
        h_num="El juego en cifras", h_find="Lo que apareció al desmontarlo",
        h_scr="Lo que el cartucho dibuja",
        cifras=[("100 %", "del binario explicado"),
                (str(TRAZADOS), "trazados, para cinco huecos"),
                (str(TIPOS), "tipos de obstáculo"),
                (mil(CODIGO, "es"), "bytes de código"),
                (mil(DATOS, "es"), "bytes de datos"),
                ("0", "bytes sin identificar")],
        nota_scr="Cada una de estas imágenes es el cartucho repetido fuera "
                 "de él: los caracteres se suben como los sube la ROM, con "
                 "sus colores, y las filas se montan con el mismo motor de "
                 "carriles. Debajo de cada pie está la dirección de donde "
                 "sale.",
        pie_leg="Esto es trabajo de documentación y preservación: el "
                "código y los gráficos siguen siendo de sus autores y de "
                "Konami, y la imagen del cartucho no se distribuye.",
    ),
    "en": dict(
        titulo="Frogger — a commented disassembly",
        aviso="<b>There is not one screenshot here.</b> The pictures are drawn "
              "by repeating what the cartridge does: the same bytes go up to "
              "video memory at the same addresses, and the river and road rows "
              "are built with its own lane engine. Everything else —the "
              "listing and the numbers— comes from the binary and is "
              "reproducible with <code>make</code>.",
        claim="Eight kilobytes, half of any other Konami cartridge in this "
              "series. Logs and cars do not spend a single sprite: they move "
              "two pixels at a time using four pre-generated versions of "
              "every drawing, and the whole demo fits in fifteen bytes.",
        ficha=["Konami · <b>©KONAMI 1983</b>",
               "An <b>RC-704</b> 8 KB cartridge",
               "MSX1 · <b>page 1</b>", "Dump <b>0d60ff78…</b>"],
        nav=[("#numbers", "The numbers"), ("#findings", "What turned up"),
             ("#screens", "What it draws")],
        docnav=[("GETTING-STARTED.html", "Getting started"),
                ("THE-GAME.html", "The game"),
                ("THE-CARTRIDGE.html", "The cartridge"),
                ("THE-CODE.html", "The code"),
                ("FINDINGS.html", "Findings"),
                ("OPEN-QUESTIONS.html", "Open questions")],
        otro=("es/", "En castellano"),
        h_num="The game in numbers",
        h_find="What turned up when we took it apart",
        h_scr="What the cartridge draws",
        cifras=[("100%", "of the binary explained"),
                (str(TRAZADOS), "layouts for five slots"),
                (str(TIPOS), "kinds of obstacle"),
                (mil(CODIGO, "en"), "bytes of code"),
                (mil(DATOS, "en"), "bytes of data"),
                ("0", "bytes unidentified")],
        nota_scr="Each of these pictures is the cartridge replayed outside it: "
                 "the characters go up the way the ROM sends them, with their "
                 "colours, and the rows are built with the same lane engine. "
                 "Under each caption is the address it comes from.",
        pie_leg="This is documentation and preservation work: the code and "
                "artwork still belong to their authors and to Konami, and the "
                "cartridge image is not distributed.",
    ),
}

HALLAZGOS = {
    "es": [
        ("Frogger y Time Pilot llevan dentro el mismo reproductor de sonido",
         "<p>No se parecen: son <b>el mismo código</b>. Los 163 bytes de "
         "0x4111–0x41B3 de este cartucho y los de 0x4160–0x4202 de Time Pilot "
         "(RC-703) coinciden byte a byte salvo en <b>tres</b>, y dos de esos "
         "tres son el byte bajo de un puntero reubicado: 0x41A1 aquí y 0x41F0 "
         "allí, exactamente el desfase de 0x4F que separa las dos copias.</p>"
         "<p>El tercero es el único que dice algo distinto: el <b>registro 7 "
         "del PSG</b>, la mezcla. Vale 0xA8 aquí y 0x98 allí, o sea que el "
         "<b>ruido suena en el canal B en Frogger y en el C en Time Pilot</b>. "
         "En los dos cartuchos el reproductor está colocado justo antes de "
         "INIT.</p>"),
        ("La demo entera son quince bytes",
         "<p>Cuando el juego se queda solo, la rana no la mueve ningún "
         "generador de números: se lee una lista. Está en 0x584F y son quince "
         "bytes, uno por movimiento y con el mismo formato que los mandos:</p>"
         "<p><code>00 08 01 01 01 01 01 08 01 01 01 01 08 00 01</code></p>"
         "<p>Es decir: espera, derecha, cinco veces arriba, derecha, cuatro "
         "arriba, derecha, espera y una más arriba. El puntero vuelve al "
         "principio al montar cada fase, y como solo se le incrementa el byte "
         "bajo, la lista no puede cruzar de página.</p>"),
        ("Trazados distintos hay cuatro, no cinco",
         "<p>La fase se elige con <code>(fase-1) mod 5</code> sobre una tabla "
         "de cinco palabras… pero <b>la segunda y la tercera apuntan al mismo "
         "sitio</b>, a 0x5CCD. Las fases 2 y 3 llevan exactamente el mismo "
         "trazado de río y carretera.</p>"
         "<p>Lo único que las separa son dos retoques que hace 0x5493 cuando "
         "toca el tercer hueco: el primer objeto de la fila de arriba pasa a "
         "ser <b>cocodrilo</b>, y a la fila 15 se le pone el bit de «último» "
         "al segundo objeto, con lo que esa fila se queda con dos en vez de "
         "tres.</p>"),
        ("Las tortugas que se hunden están elegidas a mano, una por una",
         "<p>Hundirse no es una propiedad de ser tortuga: es un bit. El cuarto "
         "byte de la ficha lleva un contador, y solo se anima si tiene el bit "
         "7 puesto. Al montar la fase, 0x5489 lo pone en <b>exactamente dos "
         "direcciones</b>: 0xE0C3 y 0xE0EB, o sea el primer grupo de la fila 5 "
         "y el segundo de la fila 9.</p>"
         "<p>Y no arrancan iguales: uno empieza en 0x80 y el otro en 0x8A, "
         "para que no se hundan a la vez. A partir de la <b>fase 6</b>, 0x54D6 "
         "añade una tercera (0xE0E7, con el contador en 0x8F).</p>"),
        ("A partir de la fase 11 el juego ya no se endurece más",
         "<p>En todo el cartucho hay <b>cuatro</b> comparaciones contra el "
         "número de fase, y ninguna más: en la <b>2</b> ocho objetos del río "
         "suben dos de tipo (0x54A8), en la <b>3</b> aparece la rana que hay "
         "que rescatar (0x506A), en la <b>6</b> dos carriles pasan a moverse "
         "un paso por turno y se añade la tercera tortuga que se hunde "
         "(0x54C9), y en la <b>11</b> la fila 7 se queda con un solo objeto "
         "(0x54DB).</p>"
         "<p>De ahí en adelante lo único que cambia es cuál de los cuatro "
         "trazados toca, y eso cicla cada cinco fases. La 11, la 47 y la 99 "
         "se juegan exactamente igual.</p>"
         "<p>Y no hay final: en la fase <b>100</b> el contador vuelve a 1 "
         "(0x53F5) y el número del marcador, que es BCD, vuelve a 01. Sin "
         "rótulo, sin música y sin pantalla.</p>"),
        ("Saltar a una casa ya ocupada te mata",
         "<p>Las cinco casas están en las columnas 4, 8, 12, 16 y 20, y cada "
         "una tiene su bit en 0xE080. Cuando la rana entra en una, 0x528F mira "
         "ese bit; si <b>ya estaba puesto</b>, no hay aviso ni rebote: "
         "<code>jp 0x5305</code>, que es la rutina de la muerte.</p>"),
        ("Los troncos y los coches no gastan un solo sprite",
         "<p>El MSX1 solo puede enseñar cuatro sprites en una línea, así que "
         "Frogger los reserva para la rana y el cocodrilo. Todo lo demás son "
         "<b>caracteres</b>.</p>"
         "<p>Para moverlos sin saltos, 0x473C guarda en la memoria de vídeo "
         "<b>cuatro versiones de cada dibujo</b>, desplazadas 0, 2, 4 y 6 "
         "píxeles: corre el juego entero de patrones dos bits y deja que los "
         "bits que se salen entren en el carácter de al lado. La posición de "
         "cada objeto va en <b>cuartos de carácter</b>, y sus dos bits de "
         "abajo eligen la versión.</p>"),
        ("Tres tercios de pantalla igualados con una sola copia",
         "<p>SCREEN 2 tiene los patrones y los colores partidos en tres "
         "tercios de 2 KB, y el juego los quiere iguales. En vez de tres "
         "copias, 0x471A hace <b>una de 4095 bytes</b> con el destino 2 KB por "
         "delante del origen: al pasar del primer tercio ya está leyendo lo "
         "que acaba de escribir, así que el segundo se propaga solo al "
         "tercero.</p>"),
        ("Las mismas letras subidas dos veces, solo por el color",
         "<p>En SCREEN 2 el color va por línea de patrón, no por casilla: dos "
         "casillas con el mismo carácter no pueden tener colores distintos. "
         "Así que INIT sube el juego de letras <b>dos veces</b>, a los "
         "caracteres 0x98 y 0xD8 (0x4235 y 0x4240 repiten los bytes que ya "
         "había subido el bloque anterior).</p>"
         "<p>La tabla de color que se carga justo después da cian a los "
         "primeros y blanco a los segundos: por eso el menú del título sale "
         "en cian y el marcador de la partida en blanco.</p>"),
        ("Una rutina que no llama nadie",
         "<p>En 0x57F7 hay seis bytes de código perfectamente formado: la "
         "versión para tablas de un byte del buscador de 0x57FF, que devuelve "
         "en B el byte número A de una tabla incrustada detrás del "
         "<code>call</code> y salta al byte de después del 0xFF que la "
         "cierra.</p>"
         "<p>Funciona. Pero <b>ninguna instrucción del cartucho la llama</b>: "
         "las cuatro llamadas que hay van todas a la versión de dos bytes.</p>"),
    ],
    "en": [
        ("Frogger and Time Pilot carry the same sound player inside",
         "<p>They are not similar: they are <b>the same code</b>. The 163 "
         "bytes at 0x4111–0x41B3 in this cartridge and those at 0x4160–0x4202 "
         "in Time Pilot (RC-703) match byte for byte except for <b>three</b>, "
         "and two of those three are the low byte of a relocated pointer: "
         "0x41A1 here and 0x41F0 there, exactly the 0x4F offset between the "
         "two copies.</p>"
         "<p>The third is the only one that says something different: <b>PSG "
         "register 7</b>, the mixer. It is 0xA8 here and 0x98 there, which "
         "means <b>the noise is on channel B in Frogger and on channel C in "
         "Time Pilot</b>. In both cartridges the player sits right before "
         "INIT.</p>"),
        ("The whole demo is fifteen bytes",
         "<p>When the game is left alone, no random generator moves the frog: "
         "a list is read. It lives at 0x584F and it is fifteen bytes, one per "
         "move, in the same format as the controls:</p>"
         "<p><code>00 08 01 01 01 01 01 08 01 01 01 01 08 00 01</code></p>"
         "<p>That is: wait, right, five times up, right, four up, right, wait "
         "and one more up. The pointer goes back to the start whenever a stage "
         "is built, and since only its low byte is incremented, the list "
         "cannot cross a page.</p>"),
        ("There are four different layouts, not five",
         "<p>The stage is picked with <code>(stage-1) mod 5</code> over a "
         "five-word table… but <b>the second and third entries point to the "
         "same place</b>, 0x5CCD. Stages 2 and 3 use exactly the same river "
         "and road layout.</p>"
         "<p>The only thing that separates them are two touch-ups 0x5493 makes "
         "on the third slot: the first object in the top row becomes a "
         "<b>crocodile</b>, and the second object of row 15 gets the «last» "
         "bit set, which leaves that row with two objects instead of three.</p>"),
        ("The diving turtles are hand-picked, one by one",
         "<p>Diving is not a property of being a turtle: it is a bit. The "
         "fourth byte of the record holds a counter, and it only animates if "
         "bit 7 is set. When the stage is built, 0x5489 sets it at "
         "<b>exactly two addresses</b>: 0xE0C3 and 0xE0EB, that is the first "
         "group of row 5 and the second of row 9.</p>"
         "<p>And they do not start alike: one begins at 0x80 and the other at "
         "0x8A, so that they never dive together. From <b>stage 6</b> on, "
         "0x54D6 adds a third one (0xE0E7, counter at 0x8F).</p>"),
        ("From stage 11 on, the game stops getting harder",
         "<p>There are <b>four</b> comparisons against the stage number in the "
         "whole cartridge, and no more: on <b>2</b> eight river objects go up "
         "two types (0x54A8), on <b>3</b> the frog you have to rescue shows up "
         "(0x506A), on <b>6</b> two lanes move one step per turn and the third "
         "diving turtle is added (0x54C9), and on <b>11</b> row 7 is left with "
         "a single object (0x54DB).</p>"
         "<p>From there on the only thing that changes is which of the four "
         "layouts comes up, and that cycles every five stages. Stage 11, stage "
         "47 and stage 99 play exactly the same.</p>"
         "<p>And there is no ending: on stage <b>100</b> the counter goes back "
         "to 1 (0x53F5) and the scoreboard number, which is BCD, goes back to "
         "01. No banner, no music, no screen.</p>"),
        ("Jumping into a home that is already taken kills you",
         "<p>The five homes sit at columns 4, 8, 12, 16 and 20, and each has "
         "its own bit in 0xE080. When the frog enters one, 0x528F checks that "
         "bit; if it was <b>already set</b>, there is no warning and no bounce: "
         "<code>jp 0x5305</code>, which is the death routine.</p>"),
        ("Logs and cars do not spend a single sprite",
         "<p>The MSX1 can only show four sprites on a line, so Frogger keeps "
         "them for the frog and the crocodile. Everything else is "
         "<b>characters</b>.</p>"
         "<p>To move them smoothly, 0x473C stores <b>four versions of every "
         "drawing</b> in video memory, shifted 0, 2, 4 and 6 pixels: it rolls "
         "the whole pattern set two bits and lets the bits that fall off enter "
         "the character next door. Each object's position is kept in "
         "<b>quarters of a character</b>, and its low two bits pick the "
         "version.</p>"),
        ("Three screen thirds matched with a single copy",
         "<p>SCREEN 2 splits patterns and colours into three 2 KB thirds, and "
         "the game wants them identical. Instead of three copies, 0x471A does "
         "<b>one of 4095 bytes</b> with the destination 2 KB ahead of the "
         "source: past the first third it is already reading what it has just "
         "written, so the second propagates into the third on its own.</p>"),
        ("The same letters uploaded twice, just for the colour",
         "<p>In SCREEN 2 colour goes per pattern line, not per cell: two cells "
         "holding the same character cannot have different colours. So INIT "
         "uploads the letter set <b>twice</b>, at characters 0x98 and 0xD8 "
         "(0x4235 and 0x4240 repeat bytes the previous block had already "
         "sent).</p>"
         "<p>The colour table loaded right after gives cyan to the first and "
         "white to the second: that is why the title menu comes out cyan and "
         "the in-game scoreboard white.</p>"),
        ("A routine nobody calls",
         "<p>At 0x57F7 there are six bytes of perfectly formed code: the "
         "one-byte-index version of the table lookup at 0x57FF, returning in B "
         "the Ath byte of a table embedded behind the <code>call</code> and "
         "jumping past the 0xFF that closes it.</p>"
         "<p>It works. But <b>no instruction in the cartridge calls it</b>: "
         "all four calls go to the two-byte version.</p>"),
    ],
}

GALERIA = [
    ("titulo.png",
     "0x4A04 y las cuatro listas de 0x4A42 — la pantalla de título, montada "
     "con las mismas listas de rótulos que usa el cartucho. Las teclas 1 y 2 "
     "juegan con joystick y la 3 y la 4 con el teclado",
     "0x4A04 and the four lists from 0x4A42 — the title screen, built from the "
     "very label lists the cartridge uses. Keys 1 and 2 play with a joystick, "
     "3 and 4 with the keyboard"),
    ("partida.png",
     "0x434D y 0x55E5 — la pantalla de partida entera: el decorado de 0x55A4, "
     "el marcador de 0x4B02 y las ocho filas montadas con el motor de "
     "carriles, cada objeto en su versión desplazada",
     "0x434D and 0x55E5 — the whole play screen: the scenery from 0x55A4, the "
     "scoreboard from 0x4B02 and the eight rows built with the lane engine, "
     "each object in its shifted version"),
    ("trazado1.png",
     "0x5C85 — el primer trazado, el de las fases 1, 6, 11… Ninguna fila pasa "
     "de cuatro objetos",
     "0x5C85 — the first layout, used by stages 1, 6, 11… No row holds more "
     "than four objects"),
    ("trazado2.png",
     "0x5CCD — el segundo, que sirve para DOS huecos del ciclo: las fases 2 y "
     "3 son este mismo, y en la 3 el primer tronco de arriba se convierte en "
     "cocodrilo",
     "0x5CCD — the second, serving TWO slots of the cycle: stages 2 and 3 are "
     "this very one, and on stage 3 the first log up top turns into a "
     "crocodile"),
    ("trazado4.png",
     "0x5D11 — el de las fases 4, 9, 14… Ya trae cocodrilo de serie y la fila "
     "15 va a velocidad −3, la más rápida de las cuatro",
     "0x5D11 — stages 4, 9, 14… It ships a crocodile as standard and row 15 "
     "runs at speed −3, the fastest of the four"),
    ("trazado5.png",
     "0x5D55 — el de las fases 5, 10, 15… La fila de arriba se queda con un "
     "solo objeto, y es el cocodrilo: por eso aquí sale vacía, porque el "
     "cocodrilo es lo único del río que va con sprites",
     "0x5D55 — stages 5, 10, 15… The top row is left with a single object, and "
     "it is the crocodile: that is why it looks empty here, since the "
     "crocodile is the only thing in the river drawn with sprites"),
    ("sprites.png",
     "0x59FF — los dibujos de sprite, en blanco porque el MSX1 no da más de un "
     "color por sprite: la rana en sus cuatro sentidos, el cocodrilo y el "
     "bicho del río",
     "0x59FF — the sprite patterns, in white because the MSX1 gives no more "
     "than one colour per sprite: the frog facing four ways, the crocodile and "
     "the river creature"),
    ("caracteres.png",
     "0x585E y 0x2100 — los caracteres del decorado con su color: el agua, la "
     "mediana de ladrillo, la orilla y las cinco casas",
     "0x585E and 0x2100 — the scenery characters with their colour: the water, "
     "the brick median, the bank and the five homes"),
    ("coches.png",
     "0x58D1 — y aquí se ve el truco: cada dibujo aparece cuatro veces "
     "seguidas, desplazado 0, 2, 4 y 6 píxeles. Eso es lo que mueve troncos y "
     "coches sin gastar sprites",
     "0x58D1 — and here the trick shows: every drawing appears four times in a "
     "row, shifted 0, 2, 4 and 6 pixels. That is what moves logs and cars "
     "without spending sprites"),
]


def img64(ruta):
    with open(ruta, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    imgdir, salida, idioma = argv[1:4]
    t = TXT[idioma]

    ruta_logo = os.path.join(imgdir, "logo.png")
    cabecera = (f'<img src="{img64(ruta_logo)}" alt="Frogger">'
                if os.path.exists(ruta_logo) else "<h1>Frogger</h1>")

    nav = "".join(f'<a href="{h}">{x}</a>' for h, x in t["nav"])
    nav += "".join(f'<a href="{h}">{x}</a>' for h, x in t["docnav"])
    nav += (f'<a href="{t["otro"][0]}" style="margin-left:auto;color:var(--oro)">'
            f'{t["otro"][1]}</a>')

    cifras = "".join(f'<div class="cifra"><b>{v}</b><span>{e}</span></div>'
                     for v, e in t["cifras"])
    halls = "".join(f'<div class="hall"><h3>{tit}</h3>{cuerpo}</div>'
                    for tit, cuerpo in HALLAZGOS[idioma])
    imgs = ""
    faltan = []
    for fich, es, en in GALERIA:
        ruta = os.path.join(imgdir, fich)
        if not os.path.exists(ruta):
            faltan.append(fich)
            continue
        pie = es if idioma == "es" else en
        imgs += (f'<figure><img src="{img64(ruta)}" alt="{pie}">'
                 f'<figcaption>{pie}</figcaption></figure>')
    if faltan:
        print("  (faltan %d imagenes: %s)" % (len(faltan), " ".join(faltan)))

    html = f"""<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t['titulo']}</title>
<style>{ESTILO}</style>
<header class="top">
  {cabecera}
  <p class="claim">{t['claim']}</p>
  <p class="ficha">{' · '.join(t['ficha'])}</p>
</header>
<p class="ficha" style="border:1px solid var(--oro);padding:.8em 1em;margin:1.5em 0">
{t['aviso']}</p>
<nav>{nav}</nav>
<section id="numbers">
  <h2>{t['h_num']}</h2>
  <div class="cifras">{cifras}</div>
</section>
<section id="findings"><h2>{t['h_find']}</h2>{halls}</section>
<section id="screens">
  <h2>{t['h_scr']}</h2>
  <p class="n">{t['nota_scr']}</p>
  <div class="galeria">{imgs}</div>
</section>
<footer><p>{t['pie_leg']}</p></footer>
"""
    with open(salida, "w", encoding="utf-8") as f:
        f.write(html)
    print("  %s: %d KB (%s)" % (salida, len(html) // 1024, idioma))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
