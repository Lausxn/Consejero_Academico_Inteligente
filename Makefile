# Makefile - proyecto C + Prolog (Windows / MinGW-w64)
# Uso: mingw32-make [all|run|debug|prolog|test|clean]

CC      = gcc
CFLAGS  = -std=c11 -Wall -Wextra -g -Iinclude
LDFLAGS =
SRC     = $(wildcard src/*.c)
OBJ     = $(patsubst src/%.c,build/%.o,$(SRC))
BIN     = build/app.exe

# Para embeber/llamar Prolog desde C:  mingw32-make SWI=1
ifeq ($(SWI),1)
SWI_HOME = C:/Program Files/swipl
CFLAGS  += -I"$(SWI_HOME)/include"
LDFLAGS += -L"$(SWI_HOME)/lib" -L"$(SWI_HOME)/bin" -lswipl
endif

all: $(BIN)

$(BIN): $(OBJ)
	$(CC) $(OBJ) -o $@ $(LDFLAGS)

build/%.o: src/%.c | build
	$(CC) $(CFLAGS) -c $< -o $@

build:
	@if not exist build mkdir build

run: $(BIN)
	./$(BIN)

debug: $(BIN)
	gdb ./$(BIN)

prolog:
	swipl prolog/main.pl

test:
	swipl -g run_tests -t halt tests/test_main.pl

clean:
	@if exist build rmdir /s /q build

.PHONY: all run debug prolog test clean
