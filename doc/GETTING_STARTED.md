# Getting Started with Simple6502 BIOS

*Copyright (c) 2025 Mariano Luna - Licensed under the BSD-2-Clause License*

## Prerequisites

- **cc65 toolchain** - Required for building the BIOS
- **ROM/EEPROM programmer** - For programming the binary to ROM
- **Simple6502 hardware** - Or compatible 6502-based system

## Installation

### 1. Install cc65 Toolchain

**On macOS (using Homebrew):**
```bash
brew install cc65
```

**On Linux (Ubuntu/Debian):**
```bash
sudo apt-get install cc65
```

**On Windows:**
Download from [cc65 website](https://cc65.github.io/)

### 2. Build the BIOS

```bash
# Clone or download the Simple6502 BIOS
cd simple6502-bios

# Build the BIOS
make

# Check build information
make info
```

### 3. Program to ROM

Program the `build/bios.bin` file to your ROM/EEPROM starting at address **$8000**.

**Binary Details:**
- **Start Address:** $8000
- **Size:** ~1.7KB
- **Format:** Raw binary

## First Boot

When you power on your Simple6502 system, you should see:

```
Simple6502 BIOS v1.0
Copyright (c) 2025 Mariano Luna
RAM: $0000-$7EFF, ROM: $8000-$FFFF
I/O: $7F00-$7FFF
Commands: R H D E S W L G
Simple6502 Ready
> 
```

## Basic Usage

### 1. Get Help
```
> H
Commands:
R - Reset system
H - Help
D [addr] - Display byte (ex: D 1234)
E - Examine byte at $0300
S - Show status
W [addr val] - Write (ex: W 1234 AA)
L [from to] - List range (ex: L 1000 1010)
G addr - Go execute at address (ex: G 1000)
```

### 2. Examine Memory
```
# Look at ROM start
> D 8000
8000 78

# List a range of ROM
> L 8000 8010
8000 78 D8 A2 FF 9A A9 00 AA
```

### 3. Write a Simple Program
```
# Write a simple program that loads $FF into accumulator
> W 0300 A9    # LDA #$FF
> W 0301 FF    # Immediate value $FF
> W 0302 60    # RTS (return to monitor)

# Verify the program
> L 0300 0302
0300 A9 FF 60

# Execute the program
> G 0300
Executing at 0300
Returned from user code
```

### 4. Check System Status
```
> S
Processor Status:
SP FF
```

## Hardware Configuration

The BIOS is configured for this memory map:

- **$0000-$7EFF:** RAM (32KB - 256 bytes)
- **$7F00-$7FFF:** Hardware I/O Space
  - **$7F00-$7F0F:** I/O Slot 1 (expansion)
  - **$7F10-$7F1F:** I/O Slot 2 (expansion)
  - **$7F20-$7F2F:** VIA #1 (6522)
  - **$7F30-$7F3F:** VIA #2 (6522)
  - **$7F70-$7F7F:** UART (MC68B50 ACIA)
- **$8000-$FFFF:** ROM (32KB)

## Troubleshooting

### No Output on Serial Terminal
- Check UART connections
- Verify baud rate (typically 9600, 8N1)
- Ensure ACIA is properly initialized

### System Doesn't Boot
- Verify ROM is programmed correctly at $8000
- Check power supply and clock signals
- Verify interrupt vectors at $FFFA-$FFFF

### Commands Don't Work
- Ensure you're typing at the `> ` prompt
- Commands are case-insensitive
- Use proper hex format (4 digits for addresses, 2 for values)

## Next Steps

Once you have the basic monitor working:

1. **Write Assembly Programs** - Use the W command to enter machine code
2. **Test Hardware** - Use memory-mapped I/O addresses
3. **Develop Tools** - Create utilities using the monitor commands
4. **Expand Functionality** - Add custom commands to the BIOS

## Support

For detailed command usage, see:
- [Memory Monitor Guide](MEMORY_MONITOR.md)
- [Quick Reference](QUICK_REFERENCE.md)

The Simple6502 BIOS provides a solid foundation for 6502 development and experimentation!