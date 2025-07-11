# Simple6502 BIOS

A basic BIOS (Basic Input/Output System) for the Simple6502 homebrew computer.

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

## Monitor Commands

The basic monitor provides a simple prompt. Extend `handle_command` to add:

- Memory dump/edit commands
- Jump to user programs
- Hardware diagnostics
- File loading routines

## Interrupt Handling

The BIOS sets up basic interrupt vectors. Customize the handlers for:

- Timer interrupts
- Hardware interrupts
- Non-maskable interrupts (NMI)

## Next Steps

Consider adding:

- Memory test routines
- Boot loader functionality
- Hardware diagnostics
- Extended monitor commands
- File system support