# Makefile for Simple6502 BIOS
# Requires cc65 toolchain

AS = ca65
LD = ld65
OBJCOPY = objcopy

# Target files
TARGET = bios
ASM_SRC = $(TARGET).asm
CFG_FILE = $(TARGET).cfg
OBJ_FILE = $(TARGET).o
BIN_FILE = $(TARGET).bin
HEX_FILE = $(TARGET).hex

# Build rules
all: $(BIN_FILE) $(HEX_FILE)

$(OBJ_FILE): $(ASM_SRC)
	$(AS) -o $(OBJ_FILE) $(ASM_SRC)

$(BIN_FILE): $(OBJ_FILE) $(CFG_FILE)
	$(LD) -C $(CFG_FILE) -o $(BIN_FILE) $(OBJ_FILE)

$(HEX_FILE): $(BIN_FILE)
	xxd -g 1 $(BIN_FILE) > $(HEX_FILE)

clean:
	rm -f $(OBJ_FILE) $(BIN_FILE) $(HEX_FILE)

install: $(BIN_FILE)
	# Add commands to program your ROM/EEPROM here
	@echo "Program $(BIN_FILE) to your ROM at address E000h"

.PHONY: all clean install