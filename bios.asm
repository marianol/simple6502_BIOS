; Simple6502 BIOS - Using XOR trick for case-insensitive commands
; Basic Input/Output System for Simple6502 Computer

; Zero page variables - MUST be defined first for single-pass assembler
.segment "ZEROPAGE"
addr_lo:     .res 1     ; Address low byte - will be at $00
addr_hi:     .res 1     ; Address high byte - will be at $01  
cmd_len:     .res 1     ; Command length - will be at $02
end_lo:      .res 1     ; End address low byte - will be at $03
end_hi:      .res 1     ; End address high byte - will be at $04
; Saved processor state for S command
saved_a:     .res 1     ; Saved accumulator
saved_x:     .res 1     ; Saved X register
saved_y:     .res 1     ; Saved Y register
saved_p:     .res 1     ; Saved processor status
saved_s:     .res 1     ; Saved stack pointer
saved_pc_lo: .res 1     ; Saved program counter low
saved_pc_hi: .res 1     ; Saved program counter high

.segment "VECTORS"
    .word nmi_handler
    .word reset_handler
    .word irq_handler

.segment "BIOS"

; Hardware constants
ACIA_DATA   = $7F70
ACIA_STATUS = $7F71
ACIA_RDRF   = $01
ACIA_TDRE   = $02

; Entry point
reset_handler:
    sei
    cld
    ldx #$ff
    txs
    
    ; Clear zero page
    lda #$00
    tax
clear_loop:
    sta $00,x
    inx
    bne clear_loop
    
    ; Init ACIA
    lda #$03
    sta ACIA_STATUS
    lda #$15
    sta ACIA_STATUS
    
    ; Boot message
    ldx #<boot_msg
    ldy #>boot_msg
    jsr print_string
    
    ; Start monitor
    jmp monitor

; I/O routines
print_char:
    pha
wait_tx:
    lda ACIA_STATUS
    and #ACIA_TDRE
    beq wait_tx
    pla
    sta ACIA_DATA
    rts

read_char:
    lda ACIA_STATUS
    and #ACIA_RDRF
    beq read_char
    lda ACIA_DATA
    rts

print_string:
    stx $12            ; Use $12/$13 to avoid conflict with addr_lo/addr_hi
    sty $13
    ldy #$00
ps_loop:
    lda ($12),y
    beq ps_done
    jsr print_char
    iny
    bne ps_loop
ps_done:
    rts

print_hex:
    pha
    lsr
    lsr
    lsr
    lsr
    jsr print_hex_digit
    pla
    and #$0f
print_hex_digit:
    cmp #10
    bcs hex_letter
    clc
    adc #'0'
    jsr print_char
    rts
hex_letter:
    clc
    adc #'A'-10
    jsr print_char
    rts

; Monitor with XOR case conversion trick
monitor:
    cli
    
    ; Prompt
    lda #'>'
    jsr print_char
    lda #' '
    jsr print_char
    
    ; Read command line (up to 8 characters)
    ldx #0
read_cmd_loop:
    jsr read_char
    cmp #$0d           ; Enter?
    beq cmd_ready
    cmp #$08           ; Backspace?
    beq handle_backspace
    
    ; Store character
    cpx #7             ; Max 8 chars
    bcs read_cmd_loop
    sta cmd_buffer,x
    inx
    
    ; Echo
    jsr print_char
    jmp read_cmd_loop
    
handle_backspace:
    cpx #0
    beq read_cmd_loop
    dex
    lda #$08
    jsr print_char
    lda #' '
    jsr print_char
    lda #$08
    jsr print_char
    jmp read_cmd_loop
    
cmd_ready:
    stx cmd_len
    
    ; Newline
    lda #$0a
    jsr print_char
    
    ; Skip if empty
    cpx #0
    beq monitor
    
    ; Capture processor state before processing command
    ; This allows the S command to show the state from before the monitor was entered
    jsr capture_state
    
    ; Get first character for command processing
    lda cmd_buffer
    
    ; Convert to uppercase using XOR trick - MUCH more compact!
    ; AND with $DF clears bit 5, converting lowercase to uppercase
    and #$DF           ; Convert to uppercase (clear bit 5)
    
    ; Now check only uppercase commands - half the code size!
    cmp #'R'
    bne check_H
    jmp jump_reset
check_H:
    cmp #'H'
    bne check_D
    jmp jump_help
check_D:
    cmp #'D'
    bne check_E
    jmp jump_display
check_E:
    cmp #'E'
    bne check_S
    jmp jump_examine
check_S:
    cmp #'S'
    bne check_W
    jmp jump_status
check_W:
    cmp #'W'
    bne check_L
    jmp jump_write
check_L:
    cmp #'L'
    bne check_G
    jmp jump_list
check_G:
    cmp #'G'
    bne jump_unknown
    jmp jump_go

; Intermediate jump points - keep close to checks above
jump_reset:
    jmp do_reset
jump_help:
    jmp do_help
jump_display:
    jmp do_display
jump_examine:
    jmp do_examine
jump_status:
    jmp do_status
jump_write:
    jmp do_write
jump_list:
    jmp do_list
jump_go:
    jmp do_go
jump_unknown:
    jmp do_unknown

; Command implementations
do_reset:
    ldx #<reset_msg
    ldy #>reset_msg
    jsr print_string
    jmp reset_handler

do_help:
    ldx #<help_msg
    ldy #>help_msg
    jsr print_string
    jmp monitor

do_display:
    ; Enhanced D command with optional address parsing
    lda cmd_len
    cmp #1             ; Just 'D'?
    beq display_default
    cmp #5             ; 'D 1234'?
    beq display_parse
    jmp display_error
    
display_parse:
    ; Simple parsing: expect 'D 1234' format
    lda cmd_buffer+1   ; Should be space
    cmp #' '
    bne display_error
    
    ; Parse 4 hex digits manually to avoid complex parsing
    lda cmd_buffer+2
    jsr hex_char_to_val
    bcc parse_ok1
    jmp display_error
parse_ok1:
    asl
    asl
    asl
    asl
    sta addr_hi
    
    lda cmd_buffer+3
    jsr hex_char_to_val
    bcc parse_ok2
    jmp display_error
parse_ok2:
    ora addr_hi
    sta addr_hi
    
    lda cmd_buffer+4
    jsr hex_char_to_val
    bcc parse_ok3
    jmp display_error
parse_ok3:
    asl
    asl
    asl
    asl
    sta addr_lo
    
    lda cmd_buffer+5
    jsr hex_char_to_val
    bcc parse_ok4
    jmp display_error
parse_ok4:
    ora addr_lo
    sta addr_lo
    
    jmp display_addr
    
display_default:
    ; Use default address $0200
    lda #$02
    sta addr_hi
    lda #$00
    sta addr_lo
    
display_addr:
    ; Print address
    lda addr_hi
    jsr print_hex
    lda addr_lo
    jsr print_hex
    lda #' '
    jsr print_char
    
    ; Read and display the byte - addr_lo/addr_hi are already in zero page!
    ldy #0
    lda (addr_lo),y    ; Direct zero page indirect addressing
    jsr print_hex
    lda #$0a
    jsr print_char
    jmp return_to_monitor
    
display_error:
    ldx #<error_msg
    ldy #>error_msg
    jsr print_string
    jmp return_to_monitor

return_to_monitor:
    jmp monitor

do_examine:
    ; Examine byte at $0300
    lda #$03
    jsr print_hex
    lda #$00
    jsr print_hex
    lda #' '
    jsr print_char
    
    ; Read and display the byte
    lda $0300
    jsr print_hex
    lda #$0a
    jsr print_char
    jmp monitor

do_status:
    ; Show complete processor status
    ldx #<status_header
    ldy #>status_header
    jsr print_string
    
    ; Print saved program counter
    lda saved_pc_hi
    jsr print_hex
    lda saved_pc_lo
    jsr print_hex
    lda #' '
    jsr print_char
    
    ; Print saved processor status register
    lda saved_p
    jsr print_hex
    lda #' '
    jsr print_char
    
    ; Print saved accumulator
    lda saved_a
    jsr print_hex
    lda #' '
    jsr print_char
    
    ; Print saved X register
    lda saved_x
    jsr print_hex
    lda #' '
    jsr print_char
    
    ; Print saved Y register
    lda saved_y
    jsr print_hex
    lda #' '
    jsr print_char
    
    ; Print saved stack pointer
    lda saved_s
    jsr print_hex
    lda #' '
    jsr print_char
    lda #' '
    jsr print_char
    
    ; Print processor flags in binary (NV-BDIZC)
    lda saved_p
    jsr print_flags_binary
    
    lda #$0a
    jsr print_char
    jmp monitor

; Write command helpers - keep close to avoid branch distance issues
write_default:
    ; Default: Write $AA to $0200
    lda #$AA
    sta $0200
    ldx #<write_msg
    ldy #>write_msg
    jsr print_string
    jmp monitor

write_error:
    ldx #<write_error_msg
    ldy #>write_error_msg
    jsr print_string
    jmp monitor

do_write:
    ; Enhanced W command with address and value parsing
    lda cmd_len
    cmp #1             ; Just 'W'?
    bne check_w_parse
    jmp write_default
check_w_parse:
    cmp #8             ; 'W 1234 AA'?
    bne write_err_jmp
    jmp write_parse
    
write_parse:
    ; Parse format: 'W 1234 AA'
    lda cmd_buffer+1   ; Should be space
    cmp #' '
    bne write_error
    
    ; Parse address (4 hex digits) - reuse display parsing logic
    lda cmd_buffer+2
    jsr hex_char_to_val
    bcs write_err_jmp
    jmp write_addr1_ok
write_err_jmp:
    jmp write_error
write_addr1_ok:
    asl
    asl
    asl
    asl
    sta addr_hi
    
    lda cmd_buffer+3
    jsr hex_char_to_val
    bcs write_err_jmp
write_addr2_ok:
    ora addr_hi
    sta addr_hi
    
    lda cmd_buffer+4
    jsr hex_char_to_val
    bcs write_err_jmp
write_addr3_ok:
    asl
    asl
    asl
    asl
    sta addr_lo
    
    lda cmd_buffer+5
    jsr hex_char_to_val
    bcs write_err_jmp
write_addr4_ok:
    ora addr_lo
    sta addr_lo
    
    ; Check for space before value
    lda cmd_buffer+6
    cmp #' '
    bne write_error
    
    ; Parse value (2 hex digits)
    lda cmd_buffer+7
    jsr hex_char_to_val
    bcs write_err_jmp
write_val1_ok:
    asl
    asl
    asl
    asl
    sta $14            ; Temp storage
    
    lda cmd_buffer+8
    jsr hex_char_to_val
    bcs write_err_jmp
write_val2_ok:
    ora $14
    
    ; Write the value to the address
    ldy #0
    sta (addr_lo),y
    
    ; Show confirmation
    ldx #<write_confirm_msg
    ldy #>write_confirm_msg
    jsr print_string
    
    ; Print address and value
    lda addr_hi
    jsr print_hex
    lda addr_lo
    jsr print_hex
    lda #' '
    jsr print_char
    ldy #0
    lda (addr_lo),y
    jsr print_hex
    lda #$0a
    jsr print_char
    jmp monitor

; G command helpers - keep close to avoid branch distance issues
go_error:
    ldx #<go_error_msg
    ldy #>go_error_msg
    jsr print_string
    jmp monitor

do_go:
    ; Enhanced G command to execute code at address
    lda cmd_len
    cmp #1             ; Just 'G'?
    beq go_error       ; G requires an address
    cmp #5             ; 'G 1234'?
    beq go_parse
    jmp go_error
    
go_parse:
    ; Parse format: 'G 1234'
    lda cmd_buffer+1   ; Should be space
    cmp #' '
    bne go_error
    
    ; Parse address (4 hex digits) - reuse parsing logic
    lda cmd_buffer+2
    jsr hex_char_to_val
    bcs go_error
    asl
    asl
    asl
    asl
    sta addr_hi
    
    lda cmd_buffer+3
    jsr hex_char_to_val
    bcs go_error
    ora addr_hi
    sta addr_hi
    
    lda cmd_buffer+4
    jsr hex_char_to_val
    bcs go_error
    asl
    asl
    asl
    asl
    sta addr_lo
    
    lda cmd_buffer+5
    jsr hex_char_to_val
    bcs go_error
    ora addr_lo
    sta addr_lo
    
    ; Set up return address on stack for RTS or BRK
    ; Push monitor return address - 1 (RTS adds 1)
    lda #>go_return-1
    pha
    lda #<go_return-1
    pha
    
    ; Show execution message
    ldx #<go_msg
    ldy #>go_msg
    jsr print_string
    
    ; Print target address
    lda addr_hi
    jsr print_hex
    lda addr_lo
    jsr print_hex
    lda #$0a
    jsr print_char
    
    ; Jump to user code
    jmp (addr_lo)
    
go_return:
    ; Return point from user code - capture final state
    sta saved_a        ; Save accumulator from user program
    stx saved_x        ; Save X register from user program  
    sty saved_y        ; Save Y register from user program
    
    ; Save stack pointer
    tsx
    stx saved_s
    
    ; Save processor status
    php
    pla
    sta saved_p
    
    ; Save the return address (where user program ended)
    lda addr_hi
    sta saved_pc_hi
    lda addr_lo
    sta saved_pc_lo
    
    ldx #<go_return_msg
    ldy #>go_return_msg
    jsr print_string
    jmp monitor

do_list:
    ; Enhanced L command with optional address range
    lda cmd_len
    cmp #1             ; Just 'L'?
    beq list_default
    cmp #10            ; 'L 1000 1010'?
    beq list_range
    jmp list_error
    
list_range:
    ; Parse format: 'L 1000 1010'
    lda cmd_buffer+1   ; Should be space
    cmp #' '
    bne list_error
    
    ; Parse start address (reuse parsing logic)
    jsr parse_start_addr
    bcs list_error
    
    ; Check for space before end address
    lda cmd_buffer+6
    cmp #' '
    bne list_error
    
    ; Parse end address
    jsr parse_end_addr
    bcs list_error
    
    jmp display_range
    
list_default:
    ; Default: List 8 bytes from $0200
    lda #$02
    sta addr_hi
    lda #$00
    sta addr_lo
    
    ; Set end address to $0207 (8 bytes)
    lda #$02
    sta end_hi
    lda #$07
    sta end_lo
    
    jmp display_range
    
list_error:
    ldx #<list_error_msg
    ldy #>list_error_msg
    jsr print_string
    jmp monitor

do_unknown:
    ; Unknown command
    ldx #<unknown_msg
    ldy #>unknown_msg
    jsr print_string
    jmp monitor

; Capture processor state for S command
capture_state:
    ; Save current monitor state (best approximation we can do)
    sta saved_a        ; Save accumulator
    stx saved_x        ; Save X register
    sty saved_y        ; Save Y register
    
    ; Save stack pointer
    tsx
    stx saved_s
    
    ; Save processor status
    php                ; Push processor status
    pla                ; Pull it into A
    sta saved_p        ; Save it
    
    ; Set a reasonable PC value (current monitor location)
    lda #>monitor
    sta saved_pc_hi
    lda #<monitor
    sta saved_pc_lo
    
    rts

; Print processor flags in binary format (NV-BDIZC)
print_flags_binary:
    ; Print each bit of the processor status register
    ldx #8             ; 8 bits to print
    
print_bit_loop:
    asl                ; Shift left, MSB goes to carry
    pha                ; Save the shifted value
    
    ; Print '1' if carry set, '0' if clear
    lda #'0'
    adc #0             ; Add carry (0 or 1)
    jsr print_char
    
    pla                ; Restore the value
    dex
    bne print_bit_loop
    
    rts

; Address parsing functions for L command
parse_start_addr:
    ; Parse start address from cmd_buffer+2 to +5
    lda cmd_buffer+2
    jsr hex_char_to_val
    bcs parse_fail
    asl
    asl
    asl
    asl
    sta addr_hi
    
    lda cmd_buffer+3
    jsr hex_char_to_val
    bcs parse_fail
    ora addr_hi
    sta addr_hi
    
    lda cmd_buffer+4
    jsr hex_char_to_val
    bcs parse_fail
    asl
    asl
    asl
    asl
    sta addr_lo
    
    lda cmd_buffer+5
    jsr hex_char_to_val
    bcs parse_fail
    ora addr_lo
    sta addr_lo
    
    clc
    rts

parse_end_addr:
    ; Parse end address from cmd_buffer+7 to +10
    lda cmd_buffer+7
    jsr hex_char_to_val
    bcs parse_fail
    asl
    asl
    asl
    asl
    sta end_hi
    
    lda cmd_buffer+8
    jsr hex_char_to_val
    bcs parse_fail
    ora end_hi
    sta end_hi
    
    lda cmd_buffer+9
    jsr hex_char_to_val
    bcs parse_fail
    asl
    asl
    asl
    asl
    sta end_lo
    
    lda cmd_buffer+10
    jsr hex_char_to_val
    bcs parse_fail
    ora end_lo
    sta end_lo
    
    clc
    rts

parse_fail:
    sec
    rts

; Display memory range from addr_lo/hi to end_lo/hi
display_range:
    ; Print address and up to 8 bytes per line
    lda addr_hi
    jsr print_hex
    lda addr_lo
    jsr print_hex
    lda #' '
    jsr print_char
    
    ; Print up to 8 bytes or until end address
    ldx #0
display_byte_loop:
    ; Check if we've reached end address
    lda addr_hi
    cmp end_hi
    bcc display_this_byte
    bne display_done
    lda addr_lo
    cmp end_lo
    bcs display_done
    
display_this_byte:
    ldy #0
    lda (addr_lo),y
    jsr print_hex
    lda #' '
    jsr print_char
    
    ; Increment address
    inc addr_lo
    bne display_next
    inc addr_hi
    
display_next:
    inx
    cpx #8             ; Max 8 bytes per line
    bcc display_byte_loop
    
display_done:
    lda #$0a
    jsr print_char
    jmp monitor

; Simple hex character to value conversion
hex_char_to_val:
    ; Convert single hex character to value (0-15)
    cmp #'0'
    bcc hctv_fail
    cmp #'9'+1
    bcc hctv_digit
    ; Convert to uppercase first
    and #$DF
    cmp #'A'
    bcc hctv_fail
    cmp #'F'+1
    bcs hctv_fail
    ; A-F
    sec
    sbc #'A'-10
    clc
    rts
hctv_digit:
    ; 0-9
    sec
    sbc #'0'
    clc
    rts
hctv_fail:
    sec
    rts

; Interrupt handlers
nmi_handler:
    rti

irq_handler:
    rti

; Messages
boot_msg:
    .byte "Simple6502 BIOS v1.0", $0d, $0a
    .byte "RAM: $0000-$7EFF, ROM: $8000-$FFFF", $0d, $0a
    .byte "I/O: $7F00-$7FFF", $0d, $0a
    .byte "Simple6502 Ready", $0d, $0a, $00

reset_msg:
    .byte "Resetting Simple6502...", $0d, $0a, $00

unknown_msg:
    .byte "Unknown command. Try: R H D E S W L G", $0d, $0a, $00

help_msg:
    .byte "Commands:", $0d, $0a
    .byte "R - Reset system", $0d, $0a
    .byte "H - Help", $0d, $0a
    .byte "D [addr] - Display byte (ex: D 1234)", $0d, $0a
    .byte "E - Examine byte at $0300", $0d, $0a
    .byte "S - Show status", $0d, $0a
    .byte "W [addr val] - Write (ex: W 1234 AA)", $0d, $0a
    .byte "L [from to] - List range (ex: L 1000 1010)", $0d, $0a
    .byte "G addr - Go execute at address (ex: G 1000)", $0d, $0a, $00

status_msg:
    .byte "Processor Status:", $0d, $0a, $00

status_header:
    .byte "PC   SR AC XR YR SP  NV-BDIZC", $0d, $0a, $00

write_msg:
    .byte "Wrote $AA to $0200", $0d, $0a, $00

write_confirm_msg:
    .byte "Wrote to ", $00

write_error_msg:
    .byte "Error: Use format W 1234 AA", $0d, $0a, $00

error_msg:
    .byte "Error: Use format D 1234", $0d, $0a, $00

list_error_msg:
    .byte "Error: Use format L 1000 1010", $0d, $0a, $00

go_msg:
    .byte "Executing at ", $00

go_return_msg:
    .byte "Returned from user code", $0d, $0a, $00

go_error_msg:
    .byte "Error: Use format G 1234", $0d, $0a, $00

; Regular RAM variables
.segment "BSS"
cmd_buffer:  .res 8     ; Command input buffer