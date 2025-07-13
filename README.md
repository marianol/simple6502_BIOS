# Simple6502 BIOS

A comprehensive BIOS (Basic Input/Output System) for the Simple6502 homebrew computer.

**Copyright (c) 2025 Mariano Luna**  
**Licensed under the BSD-2-Clause License**

## Features

- System initialization and hardware setup
- UART serial communication routines
- VIA (Versatile Interface Adapter) initialization
- Simple monitor program with command prompt
- Interrupt vector handling
- Memory clearing on boot

## Memory Map

The BIOS is configured for this specific memory layout:

- `$0000-$7EFF`: RAM (32KB - 256 bytes)
- `$7F00-$7FFF`: Hardware I/O Space (256 bytes)
  - `$7F00-$7F0F`: IO Slot 1
  - `$7F10-$7F1F`: IO Slot 2
  - `$7F20-$7F2F`: VIA #1 (6522)
  - `$7F30-$7F3F`: VIA #2 (6522)
  - `$7F40-$7F4F`: IO Slot 5
  - `$7F50-$7F5F`: IO Slot 6
  - `$7F60-$7F6F`: IO Slot 7
  - `$7F70-$7F7F`: UART (MC68B50 ACIA)
  - `$7F80-$7FFF`: Not Decoded
- `$8000-$FFF9`: ROM (32KB - 6 bytes)
- `$FFFA-$FFFF`: Interrupt vectors

## Hardware Requirements

- 6502 CPU
- MC68B50 ACIA for serial communication
- Two VIA (6522) chips for I/O expansion
- ROM/EEPROM for BIOS storage (32KB)
- RAM (32KB minus I/O space)

## Building

Requires the cc65 toolchain:

```bash
# Install cc65 (on macOS with Homebrew)
brew install cc65

# Build the BIOS
make

# Clean build files
make clean
```

## Programming the ROM

After building, program `bios.bin` to your ROM/EEPROM starting at address `$8000`.

## Customization

The BIOS is pre-configured for your hardware layout, but you can customize:

1. **I/O slot usage** - Add support for cards in IO_SLOT1, IO_SLOT2, etc.
2. **VIA configuration** - Customize VIA port directions and functions
3. **ACIA settings** - Adjust baud rate and communication parameters
4. **Monitor commands** - Extend `handle_command` for custom functionality

## Memory Monitor

The Simple6502 BIOS includes a comprehensive memory monitor with the following commands:

- **D [addr]** - Display memory byte
- **W [addr val]** - Write value to memory
- **L [from to]** - List memory range
- **G addr** - Execute code at address
- **S** - Show processor status
- **E** - Examine memory at $0300
- **R** - Reset system
- **H** - Show help

All commands are case-insensitive and support flexible addressing.

### Documentation

- **[Memory Monitor Guide](doc/MEMORY_MONITOR.md)** - Complete usage documentation
- **[Quick Reference](doc/QUICK_REFERENCE.md)** - Command summary and examples

### Example Usage

```
> W 0300 A9    # Write LDA #$FF instruction
> W 0301 FF
> W 0302 60    # Write RTS instruction
> L 0300 0302  # Verify the program
0300 A9 FF 60
> G 0300       # Execute the program
Executing at 0300
Returned from user code
```

## Interrupt Handling

The BIOS sets up basic interrupt vectors. Customize the handlers for:

- Timer interrupts
- Hardware interrupts
- Non-maskable interrupts (NMI)

## Features

### Core BIOS Functions
- System initialization and hardware setup
- UART serial communication (MC68B50 ACIA)
- Dual VIA (6522) I/O chip support
- Interrupt vector handling
- Memory clearing on boot

### Memory Monitor
- Complete memory examination and editing
- Code execution with return capability
- Flexible address parsing
- Professional command-line interface
- Comprehensive error handling

### Development Features
- Clean build system with organized output
- Zero page optimization for efficiency
- Professional assembly code organization
- Comprehensive documentation

## Binary Information

- **Size:** 1905 bytes (~1.9KB, fits comfortably in ROM)
- **Memory Usage:** Minimal RAM footprint
- **Zero Page:** 13 bytes for variables (efficient addressing)
- **Stack Usage:** Standard 6502 stack operations

## License

Copyright (c) 2025 Mariano Luna

This project is licensed under the BSD-2-Clause License - see the [LICENSE](LICENSE) file for details.

### License Summary

You are free to:
- Use this software for any purpose
- Modify and distribute the source code
- Include it in commercial projects
- Create derivative works

Requirements:
- Include the copyright notice and license in redistributions
- Include the license text in binary distributions

This is a permissive open-source license that allows maximum freedom while protecting the author.