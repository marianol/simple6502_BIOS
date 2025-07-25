# Simple6502 Memory Monitor

*Copyright (c) 2025 Mariano Luna - Licensed under the BSD-2-Clause License*

The Simple6502 BIOS includes a comprehensive memory monitor that provides essential debugging and development capabilities for 6502-based systems.

## Overview

The memory monitor is a command-line interface that allows you to:
- Display and examine memory contents
- Write data to memory locations
- List memory ranges in hex dump format
- Execute code at specified addresses
- Monitor system status

## Command Reference

All commands are case-insensitive (R and r work the same).

### R - Reset System
**Syntax:** `R`

Performs a warm reset of the Simple6502 system, reinitializing hardware and returning to the monitor prompt.

**Example:**
```
> R
Resetting Simple6502...
Simple6502 BIOS v1.0
Copyright (c) 2025 Mariano Luna
RAM: $0000-$7EFF, ROM: $8000-$FFFF
I/O: $7F00-$7FFF
Commands: R H D S W L G
Simple6502 Ready
> 
```

### H - Help
**Syntax:** `H`

Displays a summary of all available commands with syntax examples.

**Example:**
```
> H
Commands:
R - Reset system
H - Help
D [addr] - Display byte (continues)
S - Show status
W [addr val] - Write (ex: W 1234 AA)
L [from to] - List range (ex: L 1000 1010)
G addr - Go execute at address (ex: G 1000)
```

### D - Display Memory
**Syntax:** 
- `D` - Display byte at next address (continues from last D command)
- `D addr` - Display byte at specified address

Displays a single byte of memory in hexadecimal format, showing both the address and value. When used without an address, the D command continues from where the last D command left off, making it easy to examine consecutive memory locations.

**Examples:**
```
> D 1000
1000 A9

> D
1001 FF

> D
1002 8D

> D 8000
8000 78

> D
8001 D8
```

### S - Show Status
**Syntax:** `S`

Displays complete processor status information in the format used by professional 6502 debuggers.

**Format:**
```
PC   SR AC XR YR SP  NV-BDIZC
C000 B0 C2 00 00 EE  10110000
```

**Fields:**
- **PC:** Program Counter (address of next instruction)
- **SR:** Status Register (processor flags)
- **AC:** Accumulator register
- **XR:** X index register
- **YR:** Y index register  
- **SP:** Stack Pointer
- **NV-BDIZC:** Status register flags in binary (N=Negative, V=Overflow, B=Break, D=Decimal, I=Interrupt, Z=Zero, C=Carry)

**Example:**
```
> S
PC   SR AC XR YR SP  NV-BDIZC
8123 34 FF 00 01 FE  00110100
```

### W - Write Memory
**Syntax:**
- `W` - Write $AA to default address ($0200)
- `W addr val` - Write specified value to specified address

Writes a byte value to memory and confirms the operation.

**Examples:**
```
> W
Wrote $AA to $0200

> W 1000 A9
Wrote to 1000 A9

> W 0300 FF
Wrote to 0300 FF
```

### L - List Memory Range
**Syntax:**
- `L` - List 8 bytes starting from $0200
- `L from to` - List memory range from 'from' address to 'to' address

Displays memory contents in hex dump format, showing up to 8 bytes per line.

**Examples:**
```
> L
0200 AA 01 02 03 04 05 06 07

> L 1000 1010
1000 A9 FF 8D 70 7F 60 00 EA

> L 8000 8008
8000 78 D8 A2 FF 9A A9 00 AA
```

### G - Go Execute
**Syntax:** `G addr`

Executes code starting at the specified address. The monitor sets up a return address on the stack, so user code can return using RTS or BRK instructions.

**Examples:**
```
> G 1000
Executing at 1000
Returned from user code

> G 0300
Executing at 0300
Returned from user code
```

## Address Format

All addresses are specified as 4-digit hexadecimal numbers without the '$' prefix:
- `1000` represents address $1000
- `FFFF` represents address $FFFF
- `0200` represents address $0200

Both uppercase and lowercase hex digits are accepted:
- `1000` and `1000` are equivalent
- `ABCD` and `abcd` are equivalent

## Value Format

Memory values are specified as 2-digit hexadecimal numbers:
- `AA` represents the value $AA (170 decimal)
- `FF` represents the value $FF (255 decimal)
- `00` represents the value $00 (0 decimal)

## Error Handling

The monitor provides helpful error messages for invalid syntax:

```
> D
Error: Use format D 1234

> W 1000
Error: Use format W 1234 AA

> L 1000
Error: Use format L 1000 1010

> G
Error: Use format G 1234
```

## Usage Examples

### Basic Memory Operations
```
# Write a simple program to memory
> W 0300 A9    # LDA #$FF
> W 0301 FF
> W 0302 60    # RTS

# Verify the program
> L 0300 0302
0300 A9 FF 60

# Execute the program
> G 0300
Executing at 0300
Returned from user code
```

### Memory Examination
```
# Check ROM contents
> L 8000 8010
8000 78 D8 A2 FF 9A A9 00 AA

# Check specific locations
> D 8000
8000 78

> D FFFA
FFFA 00    # NMI vector low byte
```

### System Debugging
```
# Check system status
> S
Processor Status:
SP FE

# Reset if needed
> R
Resetting Simple6502...
```

## Tips and Best Practices

1. **Use consistent addressing:** Always use 4-digit hex addresses (e.g., `0200` not `200`)

2. **Verify writes:** Use D or L commands to verify memory writes were successful

3. **Test code incrementally:** Write small code segments and test with G command

4. **Check stack pointer:** Use S command to monitor stack usage

5. **Use L command for debugging:** List memory ranges to see program flow

6. **Return from user code:** Ensure your programs end with RTS or BRK to return to monitor

## Memory Map Reference

- **$0000-$7EFF:** RAM (available for user programs and data)
- **$7F00-$7FFF:** Hardware I/O space
  - **$7F00-$7F0F:** I/O Slot 1 (expansion)
  - **$7F10-$7F1F:** I/O Slot 2 (expansion)
  - **$7F20-$7F2F:** VIA #1 (6522)
  - **$7F30-$7F3F:** VIA #2 (6522)
  - **$7F70-$7F7F:** UART (MC68B50 ACIA)
- **$8000-$FFFF:** ROM (BIOS code)
- **$FFFA-$FFFF:** Interrupt vectors

## Command Line Interface

The monitor uses a simple command-line interface:
- Commands are entered at the `> ` prompt
- Press Enter to execute commands
- Backspace works for editing
- Commands are case-insensitive
- Invalid commands show helpful error messages

The monitor is designed to be intuitive and forgiving, making it easy to explore and debug 6502 programs on the Simple6502 system.