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

.define contadorMapaLow  $0003
.define contadorMapaHigh $0004


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
    LDA #$FC
    LDX #$00
    @LoopResetSprites:
        STA $0200, X
        INX
        BNE @LoopResetSprites

    ; Aguarda a PPU Inicializar
    vblankwait:
        BIT PPUSTATUS
        BPL vblankwait

    ; Carrega as configs do sprite player
    LDX #$00
    @LoopLendoPlayer:
        LDA SpritesPlayer, x
        STA $0200, x
        INX
        CPX #$10
        BCC @LoopLendoPlayer
    
    ; Incializa as variaveis X e Y de acordo com o sprite.
    LDA SpritesPlayer + 3
    STA playerX
    LDA SpritesPlayer
    STA playerY

    ; O tamanho de um nametable é um valor16 bit
    ; Esse contador vai ser usado na leitura do nametable
    LDA #<NameTable
    STA contadorMapaLow
    LDA #>NameTable 
    STA contadorMapaHigh

    ; Seta a PPU para preencher a nametable (nametable 0 é 0x2000).
    LDA PPUSTATUS
    LDA #$20
    STA PPUADDRESS
    LDA #$00
    STA PPUADDRESS

    LDY #$00 ; Leve gambiarra a frente, deixando isso como 0 faz funcionar
    @LoopCarregandoNametable:
        LDA (contadorMapaLow), y ; Carrega o valor atual na nametable, com essa sintaxe ele busca no endereço com o (contadorMapaLow contadorMapaHigh) + y
        CMP #$FF ; Se for FF, acabou a leitura.
        BEQ @FimCarregandoNameTable

        STA PPUDATA ; Do contrário, envia pra PPU

        ; Incrementa os contadores.
        INC contadorMapaLow
        BNE @LoopCarregandoNametable ; Enquanto não houver overflow
        INC contadorMapaHigh ; Se houver overflow, incrementa o highbyte e recomeça o looping
        JMP @LoopCarregandoNametable
    @FimCarregandoNameTable:

    ; Garante que o Scroll não vai ficar cagado
    LDA #$00
    STA $2005
    STA $2005
    
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

    LDX #$00 ; Offset dentre os sprites, incrementa de 4 em 4 (primeiro pos y tá em $0200, segundo $0204...)
    @LoopAtualizandoSpritesPlayer:
        LDA SpritesPlayer + 3, x ; Carrega a posicao X inicial desse sprite
        CLC
        ADC playerX ; Acrescenta nela o X atual do sprite.
        STA $0203, x ; Guarda no endereço do sprite em memória pra atualizar ele.

        LDA SpritesPlayer, x ; Carrega a posicao Y inicial desse sprite
        CLC
        ADC playerY ; Acrescenta nela o Y atual do sprite.
        STA $0200, x ; Guarda no endereço do sprite em memória pra atualizar ele.

        ; Acrescenta 4 no offset pra ir pro proximo sprite.
        TXA
        CLC
        ADC #$04
        TAX

        CPX #$10 ; Verifica se X é menor ou igual a 16, se for continua atualizando
        BCC @LoopAtualizandoSpritesPlayer
    
    JMP main
.endproc

Paletas:
; Paleta de cores Background
.byte $22, $29, $1a, $0f
.byte $22, $36, $17, $0f
.byte $22, $30, $21, $0f  
.byte $22, $27, $17, $0f
; Paleta de cores Sprite.
.byte $22, $1c, $15, $14
.byte $22, $02, $38, $3c
.byte $22, $16, $27, $18
.byte $22, $0f, $0f, $0f
; Fim da paleta
.byte $00

SpritesPlayer:
.byte $36, $32, %00000010, $3a
.byte $36, $33, %00000010, $42
.byte $3e, $4f, %00000010, $3a
.byte $3e, $4f, %01000010, $42

NameTable:
.incbin "map.nam"
.byte $ff

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CHARS"
.incbin "graphics.chr"

.segment "STARTUP"
