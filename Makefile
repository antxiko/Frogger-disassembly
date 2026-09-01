# Frogger (Konami, MSX1) - desensamblado
#
# El orden de las cosas: trazar el flujo -> generar el listado -> comprobar que
# vuelve a dar la ROM byte a byte -> las comprobaciones que el reensamblado NO
# cubre.
#
# La ROM no se distribuye. Hace falta en la raiz como frogger.rom, y
# `make comprueba` verifica el sha256.

ROM      = frogger.rom
SHA      = 0d60ff78e1ab466bce6e888193ca62d6df71fa07344c8ea31f7a8b486323c5f5
SRC      = src
WORK     = work
ORG      = 0x4000
TITULO   = FROGGER - Konami - MSX1 - cartucho RC-704 de 8 KB en la pagina 1

OMSX     = $(WORK)/omsx

all: listado verify sanity test

$(ROM):
	@echo "=================================================================="
	@echo " Falta $(ROM), y este repositorio NO lo distribuye."
	@echo ""
	@echo " Es Frogger (Konami, RC-704) para MSX, 8192 bytes exactos."
	@echo " Ponlo aqui con ese nombre. Para comprobar que es el mismo:"
	@echo "     shasum -a 256 $(ROM)"
	@echo "     $(SHA)"
	@echo ""
	@echo " Sin el se puede leer el listado ya generado en $(SRC)/, y los"
	@echo " tests que no dependen del binario siguen pasando."
	@echo "=================================================================="
	@false

comprueba: $(ROM)
	@echo "$(SHA)  $(ROM)" | shasum -a 256 -c -

# El trazado sigue el flujo desde los puntos de entrada. Los que no se pueden
# deducir estaticamente -ganchos de interrupcion, destinos de saltos
# indirectos- estan declarados en el .entries, cada uno con su justificacion.
$(WORK)/frogger.trace.json: $(ROM) $(SRC)/frogger.entries $(SRC)/frogger.nocode
	@mkdir -p $(WORK)
	python3 tools/z80trace.py $(ROM) $(ORG) $(SRC)/frogger.entries \
	        $(WORK)/frogger $(SRC)/frogger.nocode

trace: $(WORK)/frogger.trace.json

listado: $(WORK)/frogger.trace.json $(SRC)/frogger.notes
	python3 tools/mkasm.py $(ROM) $(ORG) $(WORK)/frogger.trace.json \
	        $(SRC)/frogger.notes work/msx.sym $(SRC)/frogger.asm "$(TITULO)"

# La prueba que decide si el desensamblado es fiable.
verify: $(SRC)/frogger.asm $(ROM)
	@sh tools/verify_build.sh $(SRC)/frogger.asm $(ROM) $(ORG)

# Lo que el reensamblado NO puede cazar: que unos datos se esten leyendo como
# codigo. El binario sale identico igual, porque los bytes no cambian; lo unico
# que cambia es lo que decimos de ellos.
sanity: $(WORK)/frogger.trace.json
	@echo "=================================================================="
	@echo " ningun byte declarado como datos puede salir como codigo"
	@echo "=================================================================="
	@python3 tools/check_trace.py $(WORK)/frogger.trace.json $(SRC)/frogger.nocode
	@python3 tools/check_datos_como_codigo.py $(WORK) $(SRC)
	@echo "=================================================================="
	@echo " ningun punto de entrada puede caer dentro de una zona de datos"
	@echo "=================================================================="
	@python3 tools/check_entradas.py $(SRC)/frogger.entries $(SRC)/frogger.notes \
	        $(SRC)/frogger.nocode
	@echo "=================================================================="
	@echo " ni un byte del cartucho sin asignar"
	@echo "=================================================================="
	@python3 tools/presupuesto.py $(WORK) $(SRC)

test:
	@echo "=================================================================="
	@echo " Tests"
	@echo "=================================================================="
	@python3 -m unittest discover -s tests -v

clean:
	rm -rf $(WORK)/frogger.trace.json $(WORK)/frogger.map $(WORK)/png

.PHONY: all comprueba trace listado verify sanity test clean imagenes web

# ---------------------------------------------------------------------------
# Las imagenes y la web
# ---------------------------------------------------------------------------
# No hacen falta capturas de emulador: tools/graficos.py sube a una memoria de
# video de mentira lo mismo que sube el cartucho, con sus mismas direcciones, y
# monta la pantalla con sus mismas listas de rotulos.
imagenes: $(ROM)
	@mkdir -p docs/imagenes work/gfx
	python3 tools/graficos.py $(ROM) work/gfx
	@cp work/gfx/titulo.png work/gfx/rotulo.png docs/imagenes/
	@cp work/gfx/partida.png work/gfx/sprites.png docs/imagenes/
	@cp work/gfx/caracteres.png work/gfx/coches.png docs/imagenes/
	@cp work/gfx/trazado1.png work/gfx/trazado2.png docs/imagenes/
	@cp work/gfx/trazado4.png work/gfx/trazado5.png docs/imagenes/

web: imagenes
	python3 tools/md2html.py docs en
	python3 tools/md2html.py docs/es es
	python3 tools/make_web.py docs/imagenes docs/index.html en
	python3 tools/make_web.py docs/imagenes docs/es/index.html es
	@touch docs/.nojekyll
	@python3 tools/check_enlaces.py docs
