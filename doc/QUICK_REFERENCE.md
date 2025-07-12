# Simple6502 Memory Monitor - Quick Reference

## Command Summary

| Command | Syntax | Description | Example |
|---------|--------|-------------|---------|
| **R** | `R` | Reset system | `R` |
| **H** | `H` | Show help | `H` |
| **D** | `D [addr]` | Display byte | `D 1000` |
| **E** | `E` | Examine $0300 | `E` |
| **S** | `S` | Show status | `S` |
| **W** | `W [addr val]` | Write byte | `W 1000 AA` |
| **L** | `L [from to]` | List range | `L 1000 1010` |
| **G** | `G addr` | Execute code | `G 1000` |

## Address Format
- 4-digit hex: `1000`, `FFFF`, `0200`
- No '$' prefix needed
- Case insensitive: `ABCD` = `abcd`

## Value Format
- 2-digit hex: `AA`, `FF`, `00`
- Case insensitive: `AA` = `aa`

## Memory Map
- **$0000-$7EFF:** RAM (user space)
- **$7F00-$7FFF:** I/O space
- **$8000-$FFFF:** ROM (BIOS)

## Common Operations

### Write and Test Program
```
> W 0300 A9    # LDA #$FF
> W 0301 FF
> W 0302 60    # RTS
> L 0300 0302  # Verify
> G 0300       # Execute
```

### Memory Examination
```
> D 1000       # Single byte
> L 1000 1010  # Range
> E            # Quick check $0300
```

### System Operations
```
> S            # Check status
> R            # Reset system
> H            # Show help
```

## Error Messages
- `Error: Use format D 1234`
- `Error: Use format W 1234 AA`
- `Error: Use format L 1000 1010`
- `Error: Use format G 1234`

All commands are **case-insensitive** and provide helpful error messages.