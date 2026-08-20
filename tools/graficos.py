#!/usr/bin/env python3
"""Reconstruye lo que Frogger dibuja, repitiendo lo que hace el cartucho.

    python3 tools/graficos.py frogger.rom work/gfx

No inventa nada: es la lista de copias del propio cartucho pasada a Python, con
las mismas direcciones y en el mismo orden. Si un rango estuviera mal
etiquetado, estas imagenes saldrian ruido.

  - INIT (0x41B4) borra la VRAM, pone los ocho registros de 0x49A3, sube los
    doce bloques de caracteres de 0x4B36, colorea con las parejas de 0x4DD3 y
    reparte el primer tercio en los otros dos (0x471A).
  - MONTA_LA_PARTIDA (0x434D) carga encima los caracteres de la partida
    (0x585E), genera las cuatro versiones desplazadas de cada dibujo (0x473C
    sobre 0x58D1 y 0x59BB), sube los sprites de 0x59FF y colorea con 0x5C34,
    0x5C46 y 0x5C7C.
  - PINTA_ROTULOS (0x462C) monta la tabla de nombres desde las listas de
    0x4A04 -el titulo-, 0x55A4 -el decorado- y 0x4B02 -el marcador-.
"""
import os
import struct
import sys
import zlib

ORG = 0x4000
# La paleta del TMS9918, tal como la da openMSX.
PAL = [(0, 0, 0), (0, 0, 0), (33, 200, 66), (94, 220, 120), (84, 85, 237),
       (125, 118, 252), (212, 82, 77), (66, 235, 245), (252, 85, 84),
       (255, 121, 120), (212, 193, 84), (230, 206, 128), (33, 176, 59),
       (201, 91, 186), (204, 204, 204), (255, 255, 255)]
FONDO = PAL[1]                                   # R7 = 0xE1: borde negro


def png(w, h, px, fn):
    raw = b"".join(b"\x00" + bytes(v for p in row for v in p) for row in px)

    def chunk(t, d):
        return (struct.pack(">I", len(d)) + t + d
                + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff))
    open(fn, "wb").write(b"\x89PNG\r\n\x1a\n"
                         + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                         + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


# ---------------------------------------------------------------------------
# Las rutinas del cartucho, una por una
# ---------------------------------------------------------------------------

def sube_bloques(rom, a, n, v):
    """0x4956: N bloques de (destino de 16 bits con el ALTO delante, tamano, datos)."""
    p = a - ORG
    for _ in range(n):
        d = (((rom[p] << 8) | rom[p + 1]) & 0x3FFF)
        c = rom[p + 2] or 256
        p += 3
        v[d:d + c] = rom[p:p + c]
        p += c
    return ORG + p


def sube_repetidos(rom, a, n, dst, v):
    """0x4802: N parejas (cuantos, que byte), escritas seguidas desde dst."""
    p, d = a - ORG, dst & 0x3FFF
    for _ in range(n):
        c = rom[p] or 256
        for _ in range(c):
            v[d] = rom[p + 1]
            d += 1
        p += 2
    return ORG + p


def reparte_en_los_tercios(v, org, dst):
    """0x471A: 4095 bytes con el destino 2 KB por delante del origen.

    Al pasar del primer tercio ya se esta leyendo lo que se acaba de escribir,
    asi que el segundo se propaga solo al tercero. Una copia para tres tercios.
    """
    o, d = org & 0x3FFF, dst & 0x3FFF
    for _ in range(0x0FFF):
        v[d] = v[o]
        o += 1
        d += 1


def pinta_rotulos(rom, a, v):
    """0x462C: destino de 16 bits con el ALTO delante, caracteres, 0x1F repite,
    0x0F cierra el trozo y dos 0x0F seguidos cierran la lista."""
    p = a - ORG
    while True:
        d = (((rom[p] << 8) | rom[p + 1]) & 0x3FFF)
        p += 2
        while True:
            b = rom[p]
            if b == 0x1F:
                for _ in range(rom[p + 1] or 256):
                    v[d] = rom[p + 2]
                    d += 1
                p += 3
                continue
            if b == 0x0F:
                p += 1
                break
            v[d] = b
            d += 1
            p += 1
        if rom[p] == 0x0F:
            return ORG + p + 1


def rellena_fila(v, dst, prim, n):
    """0x4964: N caracteres consecutivos a partir de prim."""
    d = dst & 0x3FFF
    for i in range(n):
        v[d + i] = (prim + i) & 0xFF


def sube_y_rota(rom, a, n, dst, v):
    """0x473C: sube cada juego de caracteres y genera sus otras tres versiones.

    El juego se copia a un buffer que tiene OCHO BYTES LIBRES DELANTE (0xE300,
    con los datos en 0xE308). En cada pasada todo el juego se corre dos bits a
    la izquierda y los bits que se salen entran en el caracter de al lado, que
    es para lo que estan esos ocho bytes. Con tres pasadas quedan las cuatro
    versiones: 0, 2, 4 y 6 pixeles.
    """
    p, d = a - ORG, dst & 0x3FFF
    for _ in range(n):
        ini = p
        while rom[p] != 0x11:
            p += 8
        cuantos = (p - ini) // 8
        p += 1
        buf = bytearray(8) + bytearray(rom[ini:ini + cuantos * 8])
        v[d:d + len(buf)] = buf
        d += len(buf)
        for _ in range(3):
            for i in range(len(buf)):
                acarreo = 0
                for _ in range(2):
                    acarreo = ((buf[i] >> 7) & 1) | (acarreo << 1)
                    buf[i] = (buf[i] << 1) & 0xFF
                if i >= 8:
                    buf[i - 8] |= acarreo
            v[d:d + len(buf)] = buf
            d += len(buf)
    return ORG + p


def sube_del_reves(rom, a, n, dst, v):
    """0x47DA: cada grupo -un byte de cuantos y ocho de dibujo- se sube tal cual
    y despues del reves, que es como salen los dibujos mirando al otro lado."""
    p, d = a - ORG, dst & 0x3FFF
    for _ in range(n):
        c = rom[p] or 256
        p += 1
        for _ in range(c):
            v[d:d + 8] = rom[p:p + 8]
            d += 8
        for _ in range(c):
            v[d:d + 8] = rom[p + 7:p - 1:-1] if p else rom[p:p + 8][::-1]
            d += 8
        p += 8
    return ORG + p


# ---------------------------------------------------------------------------
# El motor de los carriles, para poder pintar la pantalla de partida entera
# ---------------------------------------------------------------------------

def monta_los_coches(rom, ram):
    """0x480E y 0x4827: los tres tamanos de vehiculo, contados y no leidos.

    De cada tipo salen cuatro desplazamientos y cuatro listas de parejas
    (caracter de arriba, caracter de abajo), una por version desplazada.
    """
    for hl, n in ((0xE390, 5), (0xE3BE, 7), (0xE3FC, 9)):
        ram[hl] = 4
        hl += 1
        b = (((n << 1) & 0xFF) - 1) & 0xFF
        a = (b + 4) & 0xFF
        ram[hl] = a
        hl += 1
        c = a
        a = (b + 2) & 0xFF
        b = a
        a = (a + c) & 0xFF
        ram[hl] = a
        hl += 1
        ram[hl] = (a + b) & 0xFF
        hl += 1
        b, d = (n - 3) & 0xFF, (n - 2) & 0xFF
        c, a = 0x80, 0x8F
        for _ in range(4):
            ram[hl], ram[hl + 1] = c, a
            hl += 2
            c, a = (c + 1) & 0xFF, (a + 1) & 0xFF
            for _ in range(b):
                ram[hl], ram[hl + 1] = c, a
                hl += 2
            c, a = (c + 1) & 0xFF, (a + 1) & 0xFF
            if a >= 0x92:
                c, a = (c + 1) & 0xFF, (a + 1) & 0xFF
            ram[hl], ram[hl + 1] = c, a
            hl += 2
            ram[hl] = 0xFF
            hl += 1
            b = d
            c, a = (c + 1) & 0xFF, (a + 1) & 0xFF


def monta_largos(rom, p, de, ix, ram):
    """0x48D6: cuatro versiones de un tronco, cada una un caracter mas larga."""
    ap = 4
    ram[ix] = ap
    a = rom[p]
    p += 1
    c = rom[p]
    p += 1
    for k in range(4):
        b = rom[p] + (1 if k else 0)
        aa = a
        for _ in range(b):
            ram[de] = aa
            ram[de + 1] = (aa + c) & 0xFF
            de += 2
            aa = (aa + 1) & 0xFF
            ap = (ap + 2) & 0xFF
        ram[de] = 0xFF
        de += 1
        if k == 3:
            break
        ap = (ap + 1) & 0xFF
        ix += 1
        ram[ix] = ap
    return p + 1, de


def monta_desde_plantilla(rom, p, de, ix, ram):
    """0x490D: cuatro plantillas seguidas, cada caracter con el de abajo 14 mas alla."""
    ap = 4
    ram[ix] = ap
    for k in range(4):
        while rom[p] != 0xFF:
            ram[de] = rom[p]
            ram[de + 1] = (rom[p] + 0x0E) & 0xFF
            de += 2
            p += 1
            ap = (ap + 2) & 0xFF
        ram[de] = 0xFF
        p += 1
        de += 1
        if k == 3:
            break
        ap = (ap + 1) & 0xFF
        ix += 1
        ram[ix] = ap
    return p, de


def copia_y_desplaza(ram, hl, de, suma, cuantos):
    """0x4939: los cuatro desplazamientos tal cual, y los caracteres corridos.

    Con el bit 7 en la suma no se suma nada: se pone el caracter 1, que es el
    del agua. De ahi salen las fases de la tortuga sumergiendose.
    """
    for i in range(4):
        ram[de + i] = ram[hl + i]
    de += 4
    hl += 4
    for _ in range(cuantos):
        a = ram[hl]
        if a == 0xFF:
            pass
        elif suma & 0x80:
            a = 0x01
        else:
            a = (a + suma) & 0xFF
        ram[de] = a
        de += 1
        hl += 1
    return de


def monta_el_rio(rom, ram):
    """0x486D: los troncos y las dos tandas de tortugas, con sus hundimientos."""
    p = 0x4DDF - ORG
    for de, ix in ((0xE304, 0xE300), (0xE322, 0xE31E), (0xE340, 0xE33C), (0xE366, 0xE362)):
        p, _ = monta_largos(rom, p, de, ix, ram)
    p = 0x4DEB - ORG
    monta_desde_plantilla(rom, p, 0xE44E, 0xE44A, ram)
    copia_y_desplaza(ram, 0xE44A, 0xE478, 0x20, 0x2A)
    copia_y_desplaza(ram, 0xE44A, 0xE4A6, 0x80, 0x2A)
    p = 0x4E02 - ORG
    monta_desde_plantilla(rom, p, 0xE4D8, 0xE4D4, ram)
    copia_y_desplaza(ram, 0xE4D4, 0xE512, 0x20, 0x3A)
    copia_y_desplaza(ram, 0xE4D4, 0xE550, 0x80, 0x3A)


def monta_las_fichas(rom, desc, ram):
    """0x5462: la descripcion de un trazado, convertida en fichas de cuatro bytes."""
    p, d = desc - ORG, 0xE0B0
    while True:
        vel = rom[p]
        p += 1
        while rom[p] != 0xFF:
            ram[d] = rom[p]
            ram[d + 1] = rom[p + 1]
            ram[d + 2] = vel
            ram[d + 3] = 0
            d += 4
            p += 2
        p += 1
        if rom[p] == 0xFF:
            break
        d += rom[p]
        p += 1
    ram[0xE0C3] = 0x80                       # 0x5489: las DOS tortugas que se hunden
    ram[0xE0EB] = 0x8A


LISTAS = (0xE300, 0xE31E, 0xE33C, 0xE362, 0xE390, 0xE3BE, 0xE3FC,
          0xE44A, 0xE478, 0xE4A6, 0xE4D4, 0xE512, 0xE550, 0xE58E)


def pinta_carril(ram, ix, iy, v, fondo):
    """0x5736 + 0x5740 + 0x5765 + 0x57C9: monta la fila en el bufer y la vuelca."""
    for i in range(0x50):                                # 0x5736
        ram[0xE600 + i] = fondo
    while True:
        tipo = ram[ix] & 0x0F
        if tipo == 0x0D:                                 # 0x56AE: el cocodrilo
            # no se pinta en el bufer de caracteres: va con cuatro sprites
            # (0x4F8D), que es lo unico del rio que no son caracteres
            if ram[ix] & 0x80:
                break
            ix += 4
            continue
        bc = LISTAS[tipo]                                # 0x5745
        pos = ram[ix + 1]
        ver = pos & 3                                    # 0x5765
        if ver & 1:
            ver ^= 2
        de = bc + ram[bc + ver]
        col = (pos >> 2) & 0x3F
        hl = 0xE600 + col
        while ram[de] != 0xFF:
            ram[hl] = ram[de]
            ram[hl + 0x28] = ram[de + 1]
            de += 2
            hl += 1
        if ram[ix] & 0x80:                               # 0x56C1: la ultima
            break
        ix += 4
    d = iy & 0x3FFF                                      # 0x57C9
    for i in range(0x16):
        v[d + i] = ram[0xE609 + i]
        v[d + 0x20 + i] = ram[0xE631 + i]


# Ficha, fila de la VRAM y caracter de fondo. Las cuatro filas del rio se
# limpian con el caracter 1 -el agua- y las cuatro de la carretera con el 0,
# que esta vacio: por eso el asfalto se ve negro y el rio azul. Sale de con que
# valor de A entra cada carril en 0x5736 (0x5690 y 0x56D2 pasan 1, 0x5694 y
# 0x56D6 pasan 0).
CARRILES = ((0xE0B0, 0x7862, 1), (0xE0C0, 0x78A2, 1), (0xE0D4, 0x78E2, 1),
            (0xE0E4, 0x7922, 1), (0xE0F4, 0x79A2, 0), (0xE108, 0x79E2, 0),
            (0xE11C, 0x7A22, 0), (0xE138, 0x7A62, 0))


# ---------------------------------------------------------------------------
# Las dos pantallas
# ---------------------------------------------------------------------------

def vram_del_titulo(rom):
    """Lo que dejan INIT (0x41B4) y PANTALLA_DE_TITULO (0x42D3)."""
    v = bytearray(0x4000)
    sube_bloques(rom, 0x4B36, 12, v)                  # 0x422F
    # 0x4235 y 0x4240: los MISMOS bytes otra vez, ahora a los caracteres 0x98
    # y 0xB7. El juego de letras se sube dos veces para que salga en dos
    # colores: en SCREEN 2 el color va por linea de patron, no por casilla.
    v[0x24C0:0x24C0 + 256] = rom[0x4B39 - ORG:0x4B39 - ORG + 256]
    v[0x25B8:0x25B8 + 0x48] = rom[0x4C34 - ORG:0x4C34 - ORG + 0x48]
    sube_repetidos(rom, 0x4DD3, 2, 0x0008, v)         # 0x4253
    sube_repetidos(rom, 0x4DD7, 4, 0x0400, v)         # 0x425F
    reparte_en_los_tercios(v, 0x0000, 0x0800)         # 0x426A
    reparte_en_los_tercios(v, 0x2000, 0x2800)         # 0x4273
    pinta_rotulos(rom, 0x4A04, v)                     # 0x461F, las cinco listas
    for a in (0x4A42, 0x4A60, 0x4A7E, 0x4A9C):        # las cuatro del menu
        pinta_rotulos(rom, a, v)
    return v


def vram_de_la_partida(rom, trazado=0x5C85):
    """Lo que deja MONTA_LA_PARTIDA (0x434D), con la fase ya montada."""
    v = vram_del_titulo(rom)
    for i in range(0x3800, 0x3B00):                   # 0x435A: borra los nombres
        v[i] = 0
    sube_bloques(rom, 0x585E, 1, v)                   # 0x435D
    sube_y_rota(rom, 0x58D1, 10, 0x2080, v)           # 0x436B
    sube_y_rota(rom, 0x59BB, 2, 0x24F0, v)            # 0x4381
    sube_y_rota(rom, 0x59CC, 2, 0x25F0, v)            # 0x438C
    sube_bloques(rom, 0x59FF, 20, v)                  # 0x4391
    for i in range(0x20):                             # 0x4399: un sprite macizo
        v[0x19C0 + i] = 0xFF
    sube_repetidos(rom, 0x5C34, 9, 0x0000, v)         # 0x43A9
    sube_del_reves(rom, 0x5C46, 6, 0x0080, v)         # 0x43B7
    sube_del_reves(rom, 0x5C7C, 1, 0x05F0, v)         # 0x43C5
    reparte_en_los_tercios(v, 0x0000, 0x0800)         # 0x43D3
    reparte_en_los_tercios(v, 0x2000, 0x2800)         # 0x43DC
    pinta_rotulos(rom, 0x4B02, v)                     # 0x4403, el marcador
    pinta_rotulos(rom, 0x55A4, v)                     # 0x5544, el decorado
    rellena_fila(v, 0x3822, 0x00, 0)                  # (la fila 1 va aparte)
    d = 0x3822                                        # 0x555E: el borde de las casas
    v[d:d + 0x16] = rom[0x55C4 - ORG:0x55C4 - ORG + 0x16]
    for k in range(5):                                # 0x5550: las cinco casas
        v[0x3804 + k * 4:0x3808 + k * 4] = rom[0x55E1 - ORG:0x55E5 - ORG]
    # y el motor de los carriles, que es lo que pinta el rio y la carretera
    ram = bytearray(0x10000)
    monta_los_coches(rom, ram)                        # 0x43DF
    monta_el_rio(rom, ram)                            # 0x43E2
    monta_las_fichas(rom, trazado, ram)               # 0x5462
    for ix, iy, fondo in CARRILES:                    # 0x55E5
        pinta_carril(ram, ix, iy, v, fondo)
    return v


def pinta_pantalla(v, filas=24, cols=32, esc=2):
    """La tabla de nombres de 0x3800 con los patrones de 0x2000 y el color."""
    w, h = cols * 8 * esc, filas * 8 * esc
    px = [[FONDO] * w for _ in range(h)]
    for f in range(filas):
        tercio = (f // 8) * 0x800
        for c in range(cols):
            n = v[0x3800 + f * 32 + c]
            for y in range(8):
                pat = v[0x2000 + tercio + n * 8 + y]
                col = v[0x0000 + tercio + n * 8 + y]
                tinta = PAL[col >> 4] if (col >> 4) else FONDO
                fdo = PAL[col & 15] if (col & 15) else FONDO
                for x in range(8):
                    color = tinta if pat & (0x80 >> x) else fdo
                    for dy in range(esc):
                        for dx in range(esc):
                            px[(f * 8 + y) * esc + dy][(c * 8 + x) * esc + dx] = color
    return w, h, px


def pinta_sprites(v, prim, n, fn, cols=8, esc=4, color=(255, 255, 255)):
    """N dibujos de sprite de 16x16 seguidos, en un solo color (el MSX no da mas)."""
    filas = (n + cols - 1) // cols
    w, h = cols * 18 * esc, filas * 18 * esc
    px = [[(24, 24, 24)] * w for _ in range(h)]
    for s in range(n):
        base = 0x1800 + 32 * (prim + s)
        cx, cy = (s % cols) * 18, (s // cols) * 18
        for q in range(4):
            ox, oy = (q // 2) * 8, (q % 2) * 8
            for y in range(8):
                b = v[base + q * 8 + y]
                for x in range(8):
                    if b & (0x80 >> x):
                        for dy in range(esc):
                            for dx in range(esc):
                                px[(cy + oy + y) * esc + dy][(cx + ox + x) * esc + dx] = color
    png(w, h, px, fn)


def pinta_caracteres(v, prim, n, fn, cols=16, esc=4):
    """Los caracteres tal como quedan en la VRAM, con su color."""
    filas = (n + cols - 1) // cols
    w, h = cols * 9 * esc, filas * 9 * esc
    px = [[(24, 24, 24)] * w for _ in range(h)]
    for i in range(n):
        c = prim + i
        cx, cy = (i % cols) * 9, (i // cols) * 9
        for y in range(8):
            pat = v[0x2000 + c * 8 + y]
            col = v[0x0000 + c * 8 + y]
            tinta = PAL[col >> 4] if (col >> 4) else FONDO
            fdo = PAL[col & 15] if (col & 15) else FONDO
            for x in range(8):
                color = tinta if pat & (0x80 >> x) else fdo
                for dy in range(esc):
                    for dx in range(esc):
                        px[(cy + y) * esc + dy][(cx + x) * esc + dx] = color
    png(w, h, px, fn)


def main():
    rom = open(sys.argv[1], "rb").read()
    sal = sys.argv[2] if len(sys.argv) > 2 else "work/gfx"
    os.makedirs(sal, exist_ok=True)

    v = vram_del_titulo(rom)
    png(*pinta_pantalla(v), os.path.join(sal, "titulo.png"))

    p = vram_de_la_partida(rom)
    png(*pinta_pantalla(p), os.path.join(sal, "partida.png"))
    pinta_sprites(p, 0, 24, os.path.join(sal, "sprites.png"))
    pinta_caracteres(p, 0x00, 64, os.path.join(sal, "caracteres.png"))
    pinta_caracteres(p, 0x80, 64, os.path.join(sal, "coches.png"))

    # Los cuatro trazados. La tabla de 0x5457 tiene cinco huecos, pero el
    # segundo y el tercero apuntan los dos a 0x5CCD: distintos solo hay cuatro.
    for nom, dir_ in (("trazado1", 0x5C85), ("trazado2", 0x5CCD),
                      ("trazado4", 0x5D11), ("trazado5", 0x5D55)):
        png(*pinta_pantalla(vram_de_la_partida(rom, dir_)),
            os.path.join(sal, nom + ".png"))
    print("imagenes en %s" % sal)


if __name__ == "__main__":
    main()
