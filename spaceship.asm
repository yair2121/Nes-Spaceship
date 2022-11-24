.segment "HEADER"
.byte "NES"
.byte $1a
.byte $02 ; 2 * 16KB PRG ROM
.byte $01 ; 1 * 8KB CHR ROM
.byte %00000001 ; mapper and mirroring
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00, $00, $00, $00, $00 ; filler bytes
.segment "ZEROPAGE" ; LSB 0 - FF
    current_x: .res 1
    current_y: .res 1
    current_random: .res 1
    A_Flag: .res 1 ; Flag to indicate if A button was pushed 
    B_Flag: .res 1 ; Flag to indicate if B button was pushed
    Lazer1_speed: .res 1
    Is_Shooting_Lazer: .res 1
    LDA #$00
    STA current_x
    STA current_y
    STA A_Flag
    STA B_Flag
    STA Is_Shooting_Lazer
    LDA #$02
    STA Lazer1_speed

.segment "STARTUP"
Reset:
    SEI ; Disables all interrupts
    CLD ; disable decimal mode

    ; Disable sound IRQ
    LDX #$40
    STX $4017

    ; Initialize the stack register
    LDX #$FF
    TXS

    INX ; #$FF + 1 => #$00

    ; Zero out the PPU registers
    STX $2000
    STX $2001

    STX $4010 ; Cancel sound

:
    BIT $2002
    BPL :-

    TXA

CLEARMEM:
    STA $0000, X ; $0000 => $00FF
    STA $0100, X ; $0100 => $01FF
    STA $0300, X
    STA $0400, X
    STA $0500, X
    STA $0600, X
    STA $0700, X
    LDA #$FF
    STA $0200, X ; $0200 => $02FF
    LDA #$00
    INX
    BNE CLEARMEM    
; wait for vblank
:
    BIT $2002
    BPL :-

    LDA #$02
    STA $4014
    NOP

    ; $3F00
    LDA #$3F
    STA $2006
    LDA #$00
    STA $2006

    LDX #$00

LoadPalettes:
    LDA PaletteData, X
    STA $2007 ; $3F00, $3F01, $3F02 => $3F1F
    INX
    CPX #$20
    BNE LoadPalettes    

    LDX #$00
LoadSprites:
    LDA Spaceship, X
    STA $0200, X
    INX
    CPX #$13
    BNE LoadSprites    

; Clear the nametables- this isn't necessary in most emulators unless
; you turn on random memory power-on mode, but on real hardware
; not doing this means that the background / nametable will have
; random garbage on screen. This clears out nametables starting at
; $2000 and continuing on to $2400 (which is fine because we have
; vertical mirroring on. If we used horizontal, we'd have to do
; this for $2000 and $2800)
    LDX #$00
    LDY #$00
    LDA $2002
    LDA #$20
    STA $2006
    LDA #$00
    STA $2006
ClearNametable:
    STA $2007
    INX
    BNE ClearNametable
    INY
    CPY #$08
    BNE ClearNametable
    
; Enable interrupts
    CLI

    LDA #%10010000 ; enable NMI change background to use second chr set of tiles ($1000)
    STA $2000
    ; Enabling sprites and background for left-most 8 pixels
    ; Enable sprites and background
    LDA #%00011110
    STA $2001


    .proc advanceRandomBit ; Update spirtes based on controller input
        LDA #01 ; Check x input
        CLC
        ADC current_x
        STA $020D
        rts
    .endproc
Running:
    JSR advanceRandomBit
    JMP Running


NMI:
    JSR ReadController
    JSR shoot_lazer
    JSR moveSpriteDirection
    JSR updateSprites

    FINISH_NMI:
    LDA #$02 ; copy sprite data from $0200 => PPU memory for display
    STA $4014 
    RTI

    .proc moveSpriteDirection ; Update main sprite based on values in current_x and apply_Y
        LDX #$0C
    :
        LDA current_y
        CLC
        ADC $0200, X 
        STA $0200, X
        LDA current_x
        CLC
        ADC $0203, X
        STA $0203, X
        DEX
        DEX
        DEX
        DEX
        BPL :-
        rts
        .endproc 

    .proc updateSprites ; Update spirtes based on controller input
        LDA #01 ; Check x input
        CLC
        ADC current_x
        STA $020D
        rts
    .endproc
                   
    .proc changeAstroid ; Update 
        LDA current_random ; Check x input
        AND #03
        CLC
        ADC #$20
        STA $0211
        rts
    .endproc               

     .proc   ReadController           ; Read Controller input into variables.
        LDA #$00 ; Zero Direction
        STA current_x
        STA current_y
        LDA #$01 ; Start reading the controller input
        STA $4016
        LDA #$00
        STA $4016
        LDA $4016 ; A
        SEC
        SBC #$40
        STA A_Flag
        LDA $4016 ; B
        SEC
        SBC #$40
        STA B_Flag
        LDA $4016 ; Select
        LDA $4016 ; Start
        LDA $4016 ; UP
        AND #$01
        BEQ DOWN
        LDA #$FF
        STA current_y
        LDA $4016
        JMP LEFT
        DOWN: 
        LDA $4016
        AND #$01
        BEQ LEFT
        LDA #$01
        STA current_y
        LEFT:
        LDA $4016
        AND #$01
        BEQ RIGHT
        LDA #$FF
        STA current_x
        JMP finishReadingController
        RIGHT:
        LDA $4016
        AND #$01
        BEQ finishReadingController
        LDA #$01
        STA current_x
        finishReadingController:
            rts
        .endproc

    .proc advance_lazer ; Update main sprite based on values in current_x and apply_Y
        DEC $0210
        DEC $0210
        ; LDA $0210 ; Lazer 1
        ; SEC
        ; SBC #$02
        ; STA $0210 ; Lazer 1
        rts
        .endproc    

    .proc init_lazer ; init lazer position to be the same as spaceship and activate the Is_Shooting_Lazer flag.
        LDA #$01
        STA Is_Shooting_Lazer ; Activating lazer.
        ; Resetting position to spaceship.
        LDA $0204 
        STA $0210 ; Lazer y
        LDA $0203
        STA $0213 ; Lazer x
        rts
        .endproc
    
    .proc stop_lazer
        LDA #$00
        STA Is_Shooting_Lazer
        LDA #$F0 ; Remove Sprite from screen
        STA $0210
        rts
        .endproc

    .proc shoot_lazer ; Handle the logic of shooting one lazer.
        LDA $0210
        CMP #$FD ; Is out of screen
        BCC dont_stop_lazer
        JSR stop_lazer
        dont_stop_lazer:
        LDA A_Flag
        CMP #$00
        BEQ dont_init_lazer
        JSR init_lazer
        dont_init_lazer:
        LDA Is_Shooting_Lazer
        CMP #$00
        BEQ dont_advance_lazer
        JSR advance_lazer
        dont_advance_lazer:
        finish_shoot_lazer:
        rts
        .endproc 

PaletteData:
  .byte $22,$29,$1A,$0F,$22,$36,$17,$0f,$22,$30,$21,$0f,$22,$27,$17,$0F  ;background palette data
  .byte $0F,$06,$30,$28,$0F,$07,$17,$1F ;Spaceship pallete

Spaceship:
  .byte $08, $12, $00, $0C ; 200 Head
  .byte $10, $10, $00, $08 ; 204 Left wing
  .byte $10, $11, $00, $10 ; 208 Right wing
  .byte $18, $01, $00, $0C ; 20C Fire
  .byte $00, $30, $01, $00 ; 210 Lazer1
;   .byte $00, $30, $01, $00 ; 214 Lazer2
;   .byte $00, $30, $01, $00 ; 218 Lazer3


;   .byte $00, $21, $01, $00 ; 210 astroids //TODO: remove-not 210, 213
;   .byte $18, $00, $01, $0C ; 210 Fire Left
;   .byte $18, $02, $01, $0C ; 214 Fire Right

.segment "VECTORS"
    .word NMI
    .word Reset
    ; 
.segment "CHARS"
    .incbin "spaceship.chr"