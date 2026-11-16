# Makefile - Consejero Academico Inteligente (front-end C + back-end SWI-Prolog)
#
# Uso (desde la raiz del proyecto):
#   Windows: mingw32-make [all|run|prolog|test|clean]
#   Linux:   make         [all|run|prolog|test|clean]
#
# Nota: en Windows no se usa swipl-ld porque arma el comando de gcc sin
# comillas alrededor de "C:/Program Files/swipl" y falla. Se usa gcc con
# las mismas rutas que reporta `swipl --dump-runtime-variables`
# (alternativa permitida por el enunciado).

CC       = gcc
CFLAGS   = -std=c11 -Wall -Wextra -g -Ifrontend -Iintegracion
BUILD    = build
BIN      = $(BUILD)/consejero.exe
SRC      = $(wildcard frontend/*.c) $(wildcard integracion/*.c)
OBJ      = $(patsubst %.c,$(BUILD)/%.o,$(notdir $(SRC)))

vpath %.c frontend integracion

ifeq ($(OS),Windows_NT)
  # PLBASE y PLLIBDIR de `swipl --dump-runtime-variables`
  SWI_HOME ?= C:/Program Files/swipl
  CFLAGS   += -I"$(SWI_HOME)/include"
  LDLIBS    = -L"$(SWI_HOME)/bin" -lswipl
  MKDIR     = if not exist $(BUILD) mkdir $(BUILD)
  RMDIR     = if exist $(BUILD) rmdir /s /q $(BUILD)
  EJECUTAR  = $(subst /,\,$(BIN))
  SEP       = \\
else
  BIN       = $(BUILD)/consejero
  CFLAGS   += $(shell pkg-config --cflags swipl)
  LDLIBS    = $(shell pkg-config --libs swipl)
  MKDIR     = mkdir -p $(BUILD)
  RMDIR     = rm -rf $(BUILD)
  EJECUTAR  = ./$(BIN)
  SEP       = /
endif

all: $(BIN)

$(BIN): $(OBJ)
	$(CC) $(OBJ) -o $@ $(LDLIBS)

$(BUILD)/%.o: %.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD):
	@$(MKDIR)

# Se ejecuta desde la raiz para que encuentre backend/ y datos/
run: $(BIN)
	$(EJECUTAR)

prolog:
	swipl backend/main.pl

# Pruebas del back-end (plunit)
test:
	swipl -g run_tests -t halt pruebas/pruebas_prolog.pl

# Pruebas de integracion C <-> Prolog
PRUEBA_C = $(BUILD)/prueba_integracion$(suffix $(BIN))

$(PRUEBA_C): pruebas/prueba_integracion.c $(BUILD)/conexion.o | $(BUILD)
	$(CC) $(CFLAGS) pruebas/prueba_integracion.c $(BUILD)/conexion.o -o $@ $(LDLIBS)

test-c: $(PRUEBA_C)
	$(subst /,$(SEP),$(PRUEBA_C))

# Todas las pruebas
test-todo: test test-c

clean:
	@$(RMDIR)

.PHONY: all run prolog test test-c test-todo clean
