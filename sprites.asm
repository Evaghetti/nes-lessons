; Constantes
.define PPUCONTROL $2000
.define PPUMASK    $2001
.define PPUSTATUS  $2002
.define PPUADDRESS $2006
.define PPUDATA    $2007

.define OAMADDR    $2003
.define OAMDMA     $4014

.define nmiAconteceu $0000
.define playerX      $0001
.define playerY      $0002


.segment "HEADER"
.byte "NES", 26, 2, 1, 0, 0

.segment "CODE"
.proc irq_handler
    RTI
.endproc

.proc nmi_handler
    LDA #$00
    STA OAMADDR
    LDA #$02
    STA OAMDMA

    LDA #$01
    STA nmiAconteceu
    RTI
.endproc

.proc reset_handler
    SEI
    CLD
    LDX #$00
    STX PPUCONTROL ; Desativa NMI, dentre outras coisas
    STX PPUMASK    ; Desativa rendering

    ; Seta para colocar a primeira cor da paleta de cores.
    LDX PPUSTATUS
    LDX #$3f
    STX PPUADDRESS
    LDX #$00
    STX PPUADDRESS
    
    ; Le tods as cores da paleta que eu configurei
    LDX #$00
    @LoopLendoPaletas:
        LDA Paletas, x ; Carrega a cor da paleta de cores atual.
        BEQ @FimLoopLendoPaletas ; Se a cor da paleta atual for 00, sai do looping
        
        STA PPUDATA
        INX ; Incrementa X pra pegar o proximo index
        JMP @LoopLendoPaletas
    @FimLoopLendoPaletas:

    ; Reseta Sprites
    LDA #$00
    LDX #$00
    @LoopResetSprites:
        STA $0200, X
        INX
        BNE @LoopResetSprites

    ; Aguarda a PPU Inicializar
    vblankwait:
        BIT PPUSTATUS
        BPL vblankwait

    ; Set a posição do player pra 16
    LDA #$10
    STA playerX
    STA playerY

    ; Coloca a mesma posição no sprite em si
    STA $0200
    STA $0203

    ; Sem flip, prioridade normal, paleta de cores 0.
    LDA #%00000000
    STA $0202

    ; Index 7 pra esse sprite.
    LDA #$07
    STA $0201
    
    ; Reativa NMI, Sprites usam a primeira pattern table.
    LDA #%10010000 
    STA PPUCONTROL

    ; Cores normais, nas pontas da tela, foreground e background
    LDA #%00011110
    STA PPUMASK
    
    JMP main ; Vai pro main loop
.endproc

.proc main

    ; Espera um NMI acontecer para seguir com a logica
    LDX nmiAconteceu
    DEX
    BNE main

    ; Se chegou aqui, ocorreu um NMI, reseta a flag.
    STX nmiAconteceu

    ; Incrementa as posições dos players (apenas pra demonstração)
    INC playerX
    INC playerY

    LDA playerX
    STA $0203
    LDA playerY
    STA $0200
    
    JMP main
.endproc

Paletas:
; Paleta de cores Background
.byte $29, $19, $09, $0f
.byte $0f, $0f, $0f, $0f
.byte $0f, $0f, $0f, $0f
.byte $0f, $0f, $0f, $0f
; Paleta de cores Sprite.
.byte $29, $15, $05, $0f
.byte $0f, $0f, $0f, $0f
.byte $0f, $0f, $0f, $0f
.byte $0f, $0f, $0f, $0f
; Fim da paleta
.byte $00

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CHARS"
.incbin "graphics.chr"

.segment "STARTUP"
