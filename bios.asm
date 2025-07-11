; Simple6502 BIOS - Using jump table to avoid branch distance issues
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

; Simple monitor with jump table approach
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
    
    ; Use jump table approach - store command and use indirect jump
    sta current_cmd
    
    ; Check each command using intermediate jumps
    cmp #'R'
    bne check_r
    jmp jump_reset
check_r:
    cmp #'r'
    bne check_H
    jmp jump_reset
check_H:
    cmp #'H'
    bne check_h
    jmp jump_help
check_h:
    cmp #'h'
    bne check_D
    jmp jump_help
check_D:
    cmp #'D'
    bne check_d
    jmp jump_display
check_d:
    cmp #'d'
    bne check_S
    jmp jump_display
check_S:
    cmp #'S'
    bne check_s
    jmp jump_status
check_s:
    cmp #'s'
    bne check_W
    jmp jump_status
check_W:
    cmp #'W'
    bne check_w
    jmp jump_write
check_w:
    cmp #'w'
    bne check_L
    jmp jump_write
check_L:
    cmp #'L'
    bne check_l
    jmp jump_list
check_l:
    cmp #'l'
    bne jump_unknown
    jmp jump_list

; Intermediate jump points - these are close to the command checks
jump_reset:
    jmp do_reset
jump_help:
    jmp do_help
jump_display:
    jmp do_display
jump_status:
    jmp do_status
jump_write:
    jmp do_write
jump_list:
    ; List 8 bytes starting from $0200 - unrolled to avoid loops
    lda #$02
    jsr print_hex
    lda #$00
    jsr print_hex
    lda #' '
    jsr print_char
    
    ; Print 8 bytes (unrolled)
    lda $0200
    jsr print_hex
    lda #' '
    jsr print_char
    lda $0201
    jsr print_hex
    lda #' '
    jsr print_char
    lda $0202
    jsr print_hex
    lda #' '
    jsr print_char
    lda $0203
    jsr print_hex
    lda #' '
    jsr print_char
    lda $0204
    jsr print_hex
    lda #' '
    jsr print_char
    lda $0205
    jsr print_hex
    lda #' '
    jsr print_char
    lda $0206
    jsr print_hex
    lda #' '
    jsr print_char
    lda $0207
    jsr print_hex
    
    ; New line
    lda #$0a
    jsr print_char
    jmp monitor

jump_unknown:
    jmp do_unknown

; Command implementations - can be placed anywhere now
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
    ; Display byte at $0200
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

do_status:
    ; Show processor status
    ldx #<status_msg
    ldy #>status_msg
    jsr print_string
    
    ; Show stack pointer
    lda #'S'
    jsr print_char
    lda #'P'
    jsr print_char
    lda #' '
    jsr print_char
    tsx
    txa
    jsr print_hex
    lda #$0a
    jsr print_char
    jmp monitor

do_write:
    ; Write $AA to $0200
    lda #$AA
    sta $0200
    
    ; Confirm write
    ldx #<write_msg
    ldy #>write_msg
    jsr print_string
    jmp monitor

do_unknown:
    ; Unknown command
    ldx #<unknown_msg
    ldy #>unknown_msg
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
    .byte "Unknown command. Try: R H D S W L", $0d, $0a, $00

help_msg:
    .byte "Commands:", $0d, $0a
    .byte "R - Reset system", $0d, $0a
    .byte "H - Help", $0d, $0a
    .byte "D - Display byte at $0200", $0d, $0a
    .byte "S - Show status", $0d, $0a
    .byte "W - Write $AA to $0200", $0d, $0a
    .byte "L - List 8 bytes from $0200", $0d, $0a, $00

status_msg:
    .byte "Processor Status:", $0d, $0a, $00

write_msg:
    .byte "Wrote $AA to $0200", $0d, $0a, $00

; Variables
.segment "BSS"
current_cmd: .res 1
addr_lo:     .res 1
addr_hi:     .res 1