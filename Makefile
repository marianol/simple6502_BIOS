# Makefile for Simple6502 BIOS
# Requires cc65 toolchain
# Builds in build/ subdirectory to keep project clean

AS = ca65
LD = ld65
OBJCOPY = objcopy

# Build directory
BUILD_DIR = build

# Source files
TARGET = bios
ASM_SRC = $(TARGET).asm
CFG_FILE = $(TARGET).cfg

# Target files in build directory
OBJ_FILE = $(BUILD_DIR)/$(TARGET).o
BIN_FILE = $(BUILD_DIR)/$(TARGET).bin
HEX_FILE = $(BUILD_DIR)/$(TARGET).hex
LST_FILE = $(BUILD_DIR)/$(TARGET).lst
MAP_FILE = $(BUILD_DIR)/$(TARGET).map

# Build rules
all: $(BUILD_DIR) $(BIN_FILE) $(HEX_FILE)

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(OBJ_FILE): $(ASM_SRC) $(BUILD_DIR)
	$(AS) -l $(LST_FILE) -o $(OBJ_FILE) $(ASM_SRC)

$(BIN_FILE): $(OBJ_FILE) $(CFG_FILE)
	$(LD) -C $(CFG_FILE) -m $(MAP_FILE) -o $(BIN_FILE) $(OBJ_FILE)

$(HEX_FILE): $(BIN_FILE)
	xxd -g 1 $(BIN_FILE) > $(HEX_FILE)

clean:
	rm -rf $(BUILD_DIR)

install: $(BIN_FILE)
	# Add commands to program your ROM/EEPROM here
	@echo "Program $(BIN_FILE) to your ROM at address 8000h"
	@echo "Binary size: $$(wc -c < $(BIN_FILE)) bytes"

info: $(BIN_FILE)
	@echo "Build Information:"
	@echo "  Binary: $(BIN_FILE)"
	@echo "  Size: $$(wc -c < $(BIN_FILE)) bytes"
	@echo "  Hex dump: $(HEX_FILE)"
	@echo "  Listing: $(LST_FILE)"
	@echo "  Memory map: $(MAP_FILE)"

.PHONY: all clean install info