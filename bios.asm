; Simple6502 BIOS
; Basic Input/Output System for Simple6502 Computer
; Assembled with ca65 (cc65 suite)

.segment "VECTORS"
    .word nmi_handler    ; NMI vector
    .word reset_handler  ; RESET vector  
    .word irq_handler    ; IRQ vector

.segment "BIOS"

; Memory map constants
; Hardware I/O space: $7F00 - $7FFF
IO_SLOT1    = $7F00     ; IO Slot 1 base
IO_SLOT2    = $7F10     ; IO Slot 2 base

; VIA #1 (6522)
VIA1_PORTB  = $7F20     ; VIA1 Port B
VIA1_PORTA  = $7F21     ; VIA1 Port A
VIA1_DDRB   = $7F22     ; VIA1 Data Direction B
VIA1_DDRA   = $7F23     ; VIA1 Data Direction A
VIA1_T1CL   = $7F24     ; VIA1 Timer 1 Counter Low
VIA1_T1CH   = $7F25     ; VIA1 Timer 1 Counter High
VIA1_T1LL   = $7F26     ; VIA1 Timer 1 Latch Low
VIA1_T1LH   = $7F27     ; VIA1 Timer 1 Latch High
VIA1_T2CL   = $7F28     ; VIA1 Timer 2 Counter Low
VIA1_T2CH   = $7F29     ; VIA1 Timer 2 Counter High
VIA1_SR     = $7F2A     ; VIA1 Shift Register
VIA1_ACR    = $7F2B     ; VIA1 Auxiliary Control
VIA1_PCR    = $7F2C     ; VIA1 Peripheral Control
VIA1_IFR    = $7F2D     ; VIA1 Interrupt Flag
VIA1_IER    = $7F2E     ; VIA1 Interrupt Enable
VIA1_PORTA2 = $7F2F     ; VIA1 Port A (no handshake)

; VIA #2 (6522)
VIA2_PORTB  = $7F30     ; VIA2 Port B
VIA2_PORTA  = $7F31     ; VIA2 Port A
VIA2_DDRB   = $7F32     ; VIA2 Data Direction B
VIA2_DDRA   = $7F33     ; VIA2 Data Direction A
VIA2_T1CL   = $7F34     ; VIA2 Timer 1 Counter Low
VIA2_T1CH   = $7F35     ; VIA2 Timer 1 Counter High
VIA2_T1LL   = $7F36     ; VIA2 Timer 1 Latch Low
VIA2_T1LH   = $7F37     ; VIA2 Timer 1 Latch High
VIA2_T2CL   = $7F38     ; VIA2 Timer 2 Counter Low
VIA2_T2CH   = $7F39     ; VIA2 Timer 2 Counter High
VIA2_SR     = $7F3A     ; VIA2 Shift Register
VIA2_ACR    = $7F3B     ; VIA2 Auxiliary Control
VIA2_PCR    = $7F3C     ; VIA2 Peripheral Control
VIA2_IFR    = $7F3D     ; VIA2 Interrupt Flag
VIA2_IER    = $7F3E     ; VIA2 Interrupt Enable
VIA2_PORTA2 = $7F3F     ; VIA2 Port A (no handshake)

; UART (MC68B50 ACIA)
ACIA_DATA   = $7F70     ; ACIA Data register
ACIA_STATUS = $7F71     ; ACIA Status/Control register

; ACIA Status register bits
ACIA_RDRF   = $01       ; Receive Data Register Full
ACIA_TDRE   = $02       ; Transmit Data Register Empty
ACIA_DCD    = $04       ; Data Carrier Detect
ACIA_CTS    = $08       ; Clear To Send
ACIA_FE     = $10       ; Framing Error
ACIA_OVRN   = $20       ; Receiver Overrun
ACIA_PE     = $40       ; Parity Error
ACIA_IRQ    = $80       ; Interrupt Request

; BIOS entry point - called on system reset
reset_handler:
    sei                 ; Disable interrupts
    cld                 ; Clear decimal mode
    ldx #$ff           ; Initialize stack pointer
    txs
    
    ; Clear RAM (zero page to $7EFF)
    lda #$00
    tax
clear_zp:
    sta $00,x           ; Clear zero page
    inx
    bne clear_zp
    
    ; Clear stack page
clear_stack:
    sta $0100,x
    inx
    bne clear_stack
    
    ; Initialize hardware
    jsr init_acia
    jsr init_via1
    jsr init_via2
    
    ; Print boot message
    ldx #<boot_msg
    ldy #>boot_msg
    jsr print_string
    
    ; Jump to monitor/user program
    jmp monitor

; Initialize MC68B50 ACIA for serial communication
init_acia:
    ; Reset ACIA
    lda #$03           ; Master reset
    sta ACIA_STATUS
    
    ; Configure ACIA: 8N1, /16 clock, RTS low, TX interrupt disabled, RX interrupt disabled
    lda #$15           ; 8N1, /16 clock divider, RTS=0, no interrupts
    sta ACIA_STATUS
    rts

; Initialize VIA #1
init_via1:
    ; Clear all registers
    lda #$00
    sta VIA1_DDRA      ; Port A as input
    sta VIA1_DDRB      ; Port B as input
    sta VIA1_PORTA     ; Clear Port A
    sta VIA1_PORTB     ; Clear Port B
    sta VIA1_ACR       ; Clear auxiliary control
    sta VIA1_PCR       ; Clear peripheral control
    sta VIA1_IER       ; Disable all interrupts
    lda #$7F
    sta VIA1_IER       ; Clear interrupt enable bits
    rts

; Initialize VIA #2
init_via2:
    ; Clear all registers
    lda #$00
    sta VIA2_DDRA      ; Port A as input
    sta VIA2_DDRB      ; Port B as input
    sta VIA2_PORTA     ; Clear Port A
    sta VIA2_PORTB     ; Clear Port B
    sta VIA2_ACR       ; Clear auxiliary control
    sta VIA2_PCR       ; Clear peripheral control
    sta VIA2_IER       ; Disable all interrupts
    lda #$7F
    sta VIA2_IER       ; Clear interrupt enable bits
    rts

; Print null-terminated string
; X = low byte of string address, Y = high byte
print_string:
    stx $10            ; Store string pointer in zero page
    sty $11
    ldy #$00
print_loop:
    lda ($10),y
    beq print_done     ; Exit if null terminator
    jsr print_char
    iny
    bne print_loop
print_done:
    rts

; Print single character in A register
print_char:
    pha                ; Save A
wait_tx:
    lda ACIA_STATUS    ; Check ACIA status
    and #ACIA_TDRE     ; Test Transmit Data Register Empty
    beq wait_tx        ; Wait until ready
    pla                ; Restore A
    sta ACIA_DATA      ; Send character
    rts

; Read character from ACIA (blocking)
read_char:
wait_rx:
    lda ACIA_STATUS    ; Check ACIA status
    and #ACIA_RDRF     ; Test Receive Data Register Full
    beq wait_rx        ; Wait for character
    lda ACIA_DATA      ; Read character
    rts

; Simple monitor program
monitor:
    cli                ; Enable interrupts
    
    ; Print prompt
    lda #'>'
    jsr print_char
    lda #' '
    jsr print_char
    
    ; Initialize command buffer
    ldx #$00
    stx cmrex
    
    ; Read and echo characters
monitor_loop:
    jsr read_char      ; Get character
    cmp #$0d           ; Check for carriage return
    beq handle_command
    cmp #$08           ; Check for backspace
    beq handle_backspace
    cmp #$7f           ; Check for delete
    beq handle_backspace
    
    ; Store character in command buffer
    ldx cmd_index
    cpx #15            ; Check buffer limit (16 chars max)
    bcs monitor_loop   ; Ignore if buffer full
    sta command_buffer,x
    inx
    stx cmd_index
    
    jsr print_char     ; Echo character
    jmp monitor_loop

handle_backspace:
    ldx cmd_index
    beq monitor_loop   ; Ignore if buffer empty
    dex
    stx cmd_index
    
    ; Echo backspace sequence
    lda #$08           ; Backspace
    jsr print_char
    lda #' '           ; Space
    jsr print_char
    lda #$08           ; Backspace again
    jsr print_char
    jmp monitor_loop

handle_command:
    ; Null-terminate command buffer
    ldx cmd_index
    lda #$00
    sta command_buffer,x
    
    ; Print line feed
    lda #$0a
    jsr print_char
    
    ; Skip if empty command
    ldx cmd_index
    beq monitor        ; Return to prompt if no command
    
    ; Check commands
    lda command_buffer ; Get first character of command
    cmp #'R'           ; Reset
    beq do_reset
    cmp #'r'
    beq do_reset
    cmp #'D'           ; Display memory
    beq do_display
    cmp #'d'
    beq do_display
    cmp #'L'           ; List memory range
    beq do_list
    cmp #'l'
    beq do_list
    cmp #'S'           ; Show processor status
    beq do_status
    cmp #'s'
    beq do_status
    cmp #':'           ; Write to memory
    beq do_write
    cmp #'G'           ; Go (execute)
    beq do_go
    cmp #'g'
    beq do_go
    
    ; Unknown command
    ldx #<unknown_msg
    ldy #>unknown_msg
    jsr print_string
    
    jmp monitor        ; Return to prompt

do_reset:
    ; Print reset message
    ldx #<reset_msg
    ldy #>reset_msg
    jsr print_string
    
    ; Small delay to let message transmit
    lda #10            ; 10ms delay
    jsr delay_ms
    
    ; Jump to reset vector (cold boot)
    jmp reset_handler

do_display:
    ; D [address] - Display memory at address
    jsr parse_hex_address
    bcc display_addr   ; If valid address parsed
    jmp syntax_error

display_addr:
    ; Print address
    lda mem_addr_hi
    jsr print_hex_byte
    lda mem_addr_lo
    jsr print_hex_byte
    lda #' '
    jsr print_char
    
    ; Print value at address
    lda (mem_addr_lo)  ; Read from address
    jsr print_hex_byte
    lda #$0a
    jsr print_char
    jmp monitor

do_list:
    ; L [from] [to] - List memory range
    jsr parse_hex_address
    bcc list_got_from
    jmp syntax_error

list_got_from:
    ; Store start address
    lda mem_addr_lo
    sta list_start_lo
    lda mem_addr_hi
    sta list_start_hi
    
    ; Parse end address
    jsr skip_space
    jsr parse_hex_address
    bcc list_got_to
    jmp syntax_error

list_got_to:
    ; Store end address
    lda mem_addr_lo
    sta list_end_lo
    lda mem_addr_hi
    sta list_end_hi
    
    ; Display memory range
    jsr display_memory_range
    jmp monitor

do_status:
    ; S - Show processor status
    ; Note: We can't show actual CPU registers during execution
    ; This shows saved state or current stack/memory info
    ldx #<status_msg
    ldy #>status_msg
    jsr print_string
    
    ; Show current stack pointer area
    lda #$01
    sta mem_addr_hi
    tsx
    stx mem_addr_lo
    
    lda #'S'
    jsr print_char
    lda #'P'
    jsr print_char
    lda #' '
    jsr print_char
    lda mem_addr_lo
    jsr print_hex_byte
    lda #$0a
    jsr print_char
    
    jmp monitor

do_write:
    ; :[address] [value] - Write to memory
    jsr parse_hex_address
    bcc write_got_addr
    jmp syntax_error

write_got_addr:
    ; Parse hex values and write them
write_loop:
    jsr skip_space
    jsr parse_hex_byte
    bcc write_byte
    jmp monitor        ; Done writing

write_byte:
    ; Write parsed byte to current address
    sta (mem_addr_lo)
    
    ; Increment address
    inc mem_addr_lo
    bne write_loop
    inc mem_addr_hi
    jmp write_loop

do_go:
    ; G [address] - Execute code at address
    jsr parse_hex_address
    bcc go_execute
    jmp syntax_error

go_execute:
    ; Set up return address on stack for BRK
    lda #>monitor_return-1
    pha
    lda #<monitor_return-1
    pha
    
    ; Jump to user code
    jmp (mem_addr_lo)

monitor_return:
    ; Return point from user code
    ldx #<return_msg
    ldy #>return_msg
    jsr print_string
    jmp monitor

syntax_error:
    ldx #<syntax_msg
    ldy #>syntax_msg
    jsr print_string
    jmp monitor

; Interrupt handlers
nmi_handler:
    rti

irq_handler:
    rti

; VIA utility functions
; Set VIA1 Port A as output and write value
via1_porta_out:
    pha                ; Save value
    lda #$ff           ; Set all bits as output
    sta VIA1_DDRA
    pla                ; Restore value
    sta VIA1_PORTA     ; Write to port
    rts

; Read VIA1 Port A (set as input first)
via1_porta_in:
    lda #$00           ; Set all bits as input
    sta VIA1_DDRA
    lda VIA1_PORTA     ; Read port
    rts

; Set VIA2 Port B as output and write value
via2_portb_out:
    pha                ; Save value
    lda #$ff           ; Set all bits as output
    sta VIA2_DDRB
    pla                ; Restore value
    sta VIA2_PORTB     ; Write to port
    rts

; Read VIA2 Port B (set as input first)
via2_portb_in:
    lda #$00           ; Set all bits as input
    sta VIA2_DDRB
    lda VIA2_PORTB     ; Read port
    rts

; Simple delay routine using VIA1 Timer 1
delay_ms:
    ; A register contains delay in milliseconds (approximate)
    ; Assumes 1MHz system clock
    sta VIA1_T1LL      ; Set low latch
    lda #$03           ; Set high latch (1000 cycles ≈ 1ms at 1MHz)
    sta VIA1_T1LH
    lda VIA1_T1CL      ; Start timer by reading low counter
delay_wait:
    lda VIA1_IFR       ; Check interrupt flag
    and #$40           ; Timer 1 timeout flag
    beq delay_wait     ; Wait for timeout
    lda VIA1_T1CL      ; Clear interrupt flag by reading counter
    rts

; Hex parsing and display utilities

; Parse hex address from command buffer
; Returns: Carry clear if success, address in mem_addr_lo/hi
parse_hex_address:
    ; Skip command character and spaces
    lda #1
    sta parse_index
    jsr skip_space
    
    ; Parse 4-digit hex address
    jsr parse_hex_byte
    bcs parse_addr_fail
    sta mem_addr_hi
    
    jsr parse_hex_byte
    bcs parse_addr_fail
    sta mem_addr_lo
    
    clc                ; Success
    rts

parse_addr_fail:
    sec                ; Failure
    rts

; Parse single hex byte from command buffer
; Returns: Carry clear if success, value in A
parse_hex_byte:
    ldx parse_index
    cpx cmd_index
    bcs parse_byte_fail
    
    ; Parse first hex digit
    lda command_buffer,x
    jsr hex_char_to_val
    bcs parse_byte_fail
    asl
    asl
    asl
    asl
    sta hex_temp
    
    ; Parse second hex digit
    inx
    cpx cmd_index
    bcs parse_byte_fail
    lda command_buffer,x
    jsr hex_char_to_val
    bcs parse_byte_fail
    ora hex_temp
    
    ; Update parse index
    inx
    stx parse_index
    
    clc                ; Success
    rts

parse_byte_fail:
    sec                ; Failure
    rts

; Convert hex character to value
; Input: A = hex character
; Output: A = value (0-15), Carry set if invalid
hex_char_to_val:
    cmp #'0'
    bcc hex_invalid
    cmp #'9'+1
    bcc hex_digit
    cmp #'A'
    bcc hex_invalid
    cmp #'F'+1
    bcc hex_upper
    cmp #'a'
    bcc hex_invalid
    cmp #'f'+1
    bcs hex_invalid
    ; Lowercase a-f
    sec
    sbc #'a'-10
    clc
    rts
hex_upper:
    ; Uppercase A-F
    sec
    sbc #'A'-10
    clc
    rts
hex_digit:
    ; Digit 0-9
    sec
    sbc #'0'
    clc
    rts
hex_invalid:
    sec
    rts

; Skip spaces in command buffer
skip_space:
    ldx parse_index
skip_loop:
    cpx cmd_index
    bcs skip_done
    lda command_buffer,x
    cmp #' '
    bne skip_done
    inx
    jmp skip_loop
skip_done:
    stx parse_index
    rts

; Print hex byte in A register
print_hex_byte:
    pha                ; Save original value
    lsr
    lsr
    lsr
    lsr                ; Get upper nibble
    jsr print_hex_digit
    pla                ; Restore original
    and #$0f           ; Get lower nibble
    jsr print_hex_digit
    rts

; Print hex digit (0-15) in A register
print_hex_digit:
    cmp #10
    bcc print_digit
    ; A-F
    clc
    adc #'A'-10
    jsr print_char
    rts
print_digit:
    ; 0-9
    clc
    adc #'0'
    jsr print_char
    rts

; Display memory range from list_start to list_end
display_memory_range:
    ; Copy start address to current address
    lda list_start_lo
    sta mem_addr_lo
    lda list_start_hi
    sta mem_addr_hi
    
display_range_loop:
    ; Check if we've reached the end
    lda mem_addr_hi
    cmp list_end_hi
    bcc display_line
    bne display_done
    lda mem_addr_lo
    cmp list_end_lo
    bcs display_done
    
display_line:
    ; Print address at start of line
    lda mem_addr_hi
    jsr print_hex_byte
    lda mem_addr_lo
    jsr print_hex_byte
    lda #' '
    jsr print_char
    
    ; Print 16 bytes
    ldx #0
display_byte_loop:
    ; Check if we've reached the end address
    lda mem_addr_hi
    cmp list_end_hi
    bcc display_this_byte
    bne display_line_done
    lda mem_addr_lo
    cmp list_end_lo
    bcs display_line_done
    
display_this_byte:
    lda (mem_addr_lo)  ; Read byte
    jsr print_hex_byte
    lda #' '
    jsr print_char
    
    ; Increment address
    inc mem_addr_lo
    bne display_next_byte
    inc mem_addr_hi
    
display_next_byte:
    inx
    cpx #16
    bcc display_byte_loop
    
display_line_done:
    lda #$0a           ; New line
    jsr print_char
    jmp display_range_loop
    
display_done:
    rts

; Boot message
boot_msg:
    .byte "Simple6502 BIOS v1.0", $0d, $0a
    .byte "RAM: $0000-$7EFF, ROM: $8000-$FFFF", $0d, $0a
    .byte "I/O: $7F00-$7FFF", $0d, $0a
    .byte "Commands: D L S : G R", $0d, $0a
    .byte "Simple6502 Ready", $0d, $0a, $00

; Command messages
reset_msg:
    .byte "Resetting Simple6502...", $0d, $0a, $00

unknown_msg:
    .byte "Unknown command. Try: D L S : G R", $0d, $0a, $00

syntax_msg:
    .byte "Syntax error", $0d, $0a, $00

status_msg:
    .byte "Processor Status:", $0d, $0a, $00

return_msg:
    .byte "Returned to monitor", $0d, $0a, $00

; Command buffer and variables
.segment "BSS"
command_buffer: .res 16    ; Command input buffer
cmd_index:      .res 1     ; Current position in buffer
parse_index:    .res 1     ; Parser position
mem_addr_lo:    .res 1     ; Memory address low byte
mem_addr_hi:    .res 1     ; Memory address high byte
list_start_lo:  .res 1     ; List start address low
list_start_hi:  .res 1     ; List start address high
list_end_lo:    .res 1     ; List end address low
list_end_hi:    .res 1     ; List end address high
hex_temp:       .res 1     ; Temporary hex parsing