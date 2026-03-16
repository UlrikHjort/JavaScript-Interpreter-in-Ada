# JavaScript Interpreter in Ada - Makefile

PROJECT = jsinterp
MAIN = main

SRC_DIR = src
BIN_DIR = bin
OBJ_DIR = obj

GNATMAKE = gnatmake
GNATFLAGS = -I$(SRC_DIR) -D $(OBJ_DIR) -gnat2022 -gnata -gnatwa

EXECUTABLE = $(BIN_DIR)/$(PROJECT)

.PHONY: all build run clean test

all: build

build: $(BIN_DIR)
	$(GNATMAKE) $(GNATFLAGS) $(SRC_DIR)/$(MAIN).adb -o $(EXECUTABLE)

$(BIN_DIR):
	mkdir -p $(BIN_DIR) $(OBJ_DIR)

run: build
	$(EXECUTABLE)

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
	rm -f *.ali *.o b~*.ad[sb]

test: build
	@echo "Running tests..."
	@# Add test commands here

help:
	@echo "JavaScript Interpreter in Ada"
	@echo "=============================="
	@echo "Available targets:"
	@echo "  make build  - Compile the interpreter"
	@echo "  make run    - Build and run the interpreter"
	@echo "  make clean  - Remove build artifacts"
	@echo "  make test   - Run tests"
	@echo "  make help   - Show this help message"
