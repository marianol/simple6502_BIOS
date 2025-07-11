; Simple6502 BIOS - Minimal version that compiles
; Basic Input/Output System for Simple6502 Computer

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
    stx $10
    sty $11
    ldy #$00
ps_loop:
    lda ($10),y
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

; Simple monitor
monitor:
    cli
    
    ; Prompt
    lda #'>'
    jsr print_char
    lda #' '
    jsr print_char
    
    ; Read single character command
    jsr read_char
    jsr print_char  ; Echo
    
    ; Newline
    lda #$0a
    jsr print_char
    
    ; Process command
    cmp #'R'
    beq do_reset
    cmp #'r'
    beq do_reset
    cmp #'H'
    beq do_help
    cmp #'h'
    beq do_help
    cmp #'D'
    beq do_display
    cmp #'d'
    beq do_display
    
    ; Unknown command
    ldx #<unknown_msg
    ldy #>unknown_msg
    jsr print_string
    jmp monitor

do_display:
    ; Simple display command - shows byte at fixed address $0200
    lda #$02
    jsr print_hex
    lda #$00
    jsr print_hex
    lda #' '
    jsr print_char
    
    ; Read and display the byte
    lda $0200
    jsr print_hex
    lda #$0a
    jsr print_char
    jmp monitor

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
    .byte "Unknown command. Try: R H D", $0d, $0a, $00

help_msg:
    .byte "Commands:", $0d, $0a
    .byte "R - Reset system", $0d, $0a
    .byte "H - Help", $0d, $0a
    .byte "D - Display byte at $0200", $0d, $0a, $00