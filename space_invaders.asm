.data
	.eqv BRANCO 0x00FFFFFF
	.eqv AZUL 0x000000FF
	.eqv VERM 0x00FF0000
	.eqv PRETO 0x00000000
	.eqv ROSA 0x00FF69B4
	.eqv AMARELO 0x00FFFF00
	.eqv HUD_COLOR 0x00FFFFFF
	.eqv display 0x10008000
	.eqv key_pressed 0xFFFF0000
	.eqv key_code 0xFFFF0004
	.eqv DISPLAY_LENGTH 8192
	.eqv TIRO_Y0 26
	.eqv SIZE_INCREMENT 20
	.eqv INIMIGO_SIZE_INCREMENT 80
	.eqv PLAYER_MAX_X 51
	.eqv INIMIGO_MIN_X 2  # o inimigo ocupa de x-2 ate x+2, entao x >= 2 (borda esquerda da tela)
	.eqv INIMIGO_MAX_X 51 # e x <= 51 para nao passar de x=53 (antes da linha do HUD)
	.eqv INIMIGO_RESPAWN 500 # voltas do loop que o inimigo fica morto antes de renascer (~1 s)
	.eqv TIRO_INIMIGO_INTERVALO 1000 # ms entre os tiros do inimigo
	.eqv TIRO_INIMIGO_SIZE_INCREMENT 15 # voltas do loop para o tiro do inimigo descer 1 pixel
	.eqv SCORE_X 60 # x do digito das unidades (a dezena fica 4 colunas a esquerda, em x=56)
	.eqv SCORE_Y 5  # y da linha de baixo dos digitos (ocupam as linhas 1 a 5; linha 0 e 6 livres)
	.eqv CORACAO_X 57 # x dos coracoes
	.eqv CORACAO_Y0 7 # y do primeiro coracao
	.eqv CORACAO_PASSO 5 # altura 4 + 1 de espaco
	player_x: .word 32
	player_y: .word 28
	vidas: .word 5
	coracao_atual_y: .word 27 # y do proximo coracao a apagar
	score: .word 0
	existe_tiro: .word 0
	tiro_x: .word 0
	tiro_y: .word 0
	tiro_incremented_position: .word 0
	inimigo_x: .word 32
	inimigo_y: .word 6
	inimigo_dir: .word 1
	inimigo_incremented_position: .word 0
	inimigo_vivo: .word 1 # 1 = vivo, 0 = morto (esperando renascer)
	inimigo_timer: .word 0 # voltas desde que o inimigo morreu
	existe_tiro_inimigo: .word 0
	tiro_inimigo_x: .word 0
	tiro_inimigo_y: .word 0
	tiro_inimigo_incremented_position: .word 0
	ultimo_tiro_inimigo: .word 0 # tempo (ms, syscall 30) do ultimo tiro do inimigo
	

.text
main:    #MAIN
	
	jal limpar_tela
	li $a0, AZUL
	jal desenhar_player
	li $a0, VERM
	jal desenhar_inimigo
	jal desenhar_hud_linha
	jal desenhar_hud_vidas
	lw $a0, score
	li $a1, BRANCO
	jal desenhar_score

	# ultimo_tiro_inimigo = agora (o primeiro tiro sai 1 s depois do comeco)
	li $v0, 30
	syscall
	sw $a0, ultimo_tiro_inimigo
	main_loop:

		jal movimentar_inimigo

		jal inimigo_atirar

		jal movimentar_tiro_inimigo

		jal movimentar_tiro
		
		jal movimentar_player
		
		
		jal sleep1
		j main_loop
	
	j end_program

calcular_index:#(x,y) calcula o indice do pixel no array de cores dados x e y.
	move $t0, $a1
	sll $t0, $t0, 8 # 4(y * 64) 
	sll $t1, $a0, 2 # 4x
	add $t0, $t0, $t1 
	move $v0, $t0 
	jr $ra
	
desenhar_pixel:# (a0, a1, a2) = (x,y,cor) -> desenha um pixel de cor "cor" em (x,y)
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	jal calcular_index
	sw $a2, display($v0)
	
	
	
	lw $ra, 0($sp)
	addi, $sp, $sp, 4
	jr $ra
	
desenhar_player:# (a0) = (cor) -> desenha a nave na posicao (player_x, player_y) por pixels
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	move $a2, $a0
	#x y
	lw $a0, player_x
	lw $a1, player_y
	#li $a2, AZUL
	jal desenhar_pixel
	
	#x+1 y
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x-1 y
	addi $a0, $a0, -2
	jal desenhar_pixel
	
	#x-1 y-1
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x y-1
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+1 y-1
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y
	addi $a1, $a1, 1
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x-2 y
	addi $a0, $a0, -4
	jal desenhar_pixel

	lw $ra, 0($sp)
	addi, $sp, $sp, 4
	jr $ra

desenhar_coracao:# (a0, a1, a2) = (x,y,cor) -> desenha um coracao 5x4 com canto superior esquerdo em (x,y)
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	#linha 0
	#x+1 y
	addi $a0, $a0, 1
	jal desenhar_pixel

	#x+3 y
	addi $a0, $a0, 2
	jal desenhar_pixel

	#linha 1
	#x+3 y+1
	addi $a1, $a1, 1
	jal desenhar_pixel

	#x+4 y+1
	addi $a0, $a0, 1
	jal desenhar_pixel

	#x+2 y+1
	addi $a0, $a0, -2
	jal desenhar_pixel

	#x+1 y+1
	addi $a0, $a0, -1
	jal desenhar_pixel

	#x y+1
	addi $a0, $a0, -1
	jal desenhar_pixel

	#linha 2
	#x+1 y+2
	addi $a1, $a1, 1
	addi $a0, $a0, 1
	jal desenhar_pixel

	#x+2 y+2
	addi $a0, $a0, 1
	jal desenhar_pixel

	#x+3 y+2
	addi $a0, $a0, 1
	jal desenhar_pixel

	#linha 3
	#x+2 y+3
	addi $a1, $a1, 1
	addi $a0, $a0, -1
	jal desenhar_pixel

	lw $ra, 0($sp)
	addi, $sp, $sp, 4
	jr $ra

movimentar_player:# lógica de movimentação do player, só redesenha caso tenha mudado a posição
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	
	# if not key_pressed return
	lw $t0, key_pressed
	andi $t0, $t0, 1
	beqz $t0, movimentar_player_fim
	
	# switch key_code
	lw $t0, key_code
	beq $t0, 44, movimentar_player_esquerda # "<"
	beq $t0, 46, movimentar_player_direita  # ">"
	beq $t0, 32, movimentar_player_atirar   # " "
	j movimentar_player_fim
	movimentar_player_esquerda:
		lw $s0, player_x
		 # if player_x <= 2 return
		ble, $s0, 2, movimentar_player_fim
		
		#apagar player atual
		li $a0, PRETO 
		jal desenhar_player
		
		#player_x --
		addi $t8, $s0, -1
		sw $t8, player_x
		j movimentar_player_redesenhar
	movimentar_player_direita:
		lw $s0, player_x
		# if player_x >= 61 return
		bge $s0, PLAYER_MAX_X, movimentar_player_fim
		
		#apagar player atual
		li $a0, PRETO
		jal desenhar_player
		
		#player_x ++
		addi $t8, $s0, 1
		sw $t8, player_x
		j movimentar_player_redesenhar
	movimentar_player_atirar:
		jal atirar
		j movimentar_player_fim
		
	movimentar_player_redesenhar:#desenhar player na nova posição
		li $a0, AZUL
		jal desenhar_player
	movimentar_player_fim:
	
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addi, $sp, $sp, 8
	jr $ra
	
atirar: # cria um tiro caso nao exista e toca o som do disparo
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	# if existe_tiro return;
	lw $t0, existe_tiro
	beqz $t0, atirar_criar_tiro
	j atirar_fim
	atirar_criar_tiro:
		# existe_tiro = 1;
		# (tiro_x, tiro_y) = (player_x, TIRO_Y0)
		li $t0, 1
		sw $t0, existe_tiro
		lw $t0, player_x
		li $t1, TIRO_Y0
		sw $t0, tiro_x
		sw $t1, tiro_y

		jal som_tiro

	atirar_fim:
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra

incrementar_score:# score++ e redesenha o score
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	#apagar score atual
	lw $a0, score
	li $a1, PRETO
	jal desenhar_score

	#score ++
	lw $t0, score
	addi $t0, $t0, 1
	sw $t0, score

	#desenhar score novo
	move $a0, $t0
	li $a1, BRANCO
	jal desenhar_score

	# if score >= 20: toca o Rick Roll e encerra o jogo
	# (para mover/remover a feature, basta mexer nesta chamada e na rick_rolling)
	lw $t0, score
	blt $t0, 20, incrementar_score_fim
	jal rick_rolling
	j end_program

	incrementar_score_fim:

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

som_tiro: # toca o som do disparo (syscall 31 = MIDI assincrono, nao trava o jogo)
	li $a0, 84   # nota (tom agudo)
	li $a1, 250  # duracao em ms
	li $a2, 118  # instrumento: Synth Drum (tom que cai rapido = "piu")
	li $a3, 100  # volume (0-127)
	li $v0, 31
	syscall
	jr $ra

som_explosao: # toca o som de explosao quando o inimigo e atingido (syscall 31, nao trava o jogo)
	li $a0, 40   # nota (tom grave)
	li $a1, 500  # duracao em ms
	li $a2, 127  # instrumento: Gunshot
	li $a3, 127  # volume (0-127)
	li $v0, 31
	syscall
	jr $ra

desenhar_tiro:#(cor)
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	move $a2, $a0
	
	# if not exist_tiro return
	lw $t0, existe_tiro
	beqz $t0, desenhar_tiro_fim
	
	lw $a0, tiro_x
	lw $a1, tiro_y
	#li $a2, BRANCO
	jal desenhar_pixel
	
	desenhar_tiro_fim:
		lw $ra, 0($sp)
		addi, $sp, $sp, 4
		jr $ra

movimentar_tiro:
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	
	# if not existe_tiro return
	lw $t0, existe_tiro
	beqz $t0, movimentar_tiro_fim
	
	#tiro_incremented_position++
	#if tiro_incremented_position < SIZE_INCREMENT return
	lw $t0, tiro_incremented_position
	addi $t0, $t0, 1
	sw $t0, tiro_incremented_position
	blt $t0, SIZE_INCREMENT, movimentar_tiro_fim
	
	#tiro_incremented_position = 0
	li $t0, 0
	sw $t0, tiro_incremented_position
	
	#apaga tiro atual
	li $a0, PRETO
	jal desenhar_tiro
	
	#tiro_y --
	lw $s0, tiro_y
	addi $s0, $s0, -1
	sw $s0, tiro_y
	
	# if tiro_y < 0: deletar_tiro; return
	bgez $s0, movimentar_tiro_checar_inimigo
	jal deletar_tiro
	j movimentar_tiro_fim

	movimentar_tiro_checar_inimigo:
	# if acertou o inimigo: deletar_tiro, mata o inimigo, score++; return
	jal tiro_acertou_inimigo
	beqz $v0, movimentar_tiro_desenhar
	jal deletar_tiro
	jal matar_inimigo
	jal incrementar_score
	j movimentar_tiro_fim

	movimentar_tiro_desenhar:
	li $a0, BRANCO
	jal desenhar_tiro
	
	
	
	movimentar_tiro_fim:
	
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addi, $sp, $sp, 8
	jr $ra
	
deletar_tiro: # existe_tiro = 0
	li $t0, 0
	sw $t0, existe_tiro
	jr $ra

inimigo_atirar:# a cada TIRO_INIMIGO_INTERVALO ms cria um tiro logo abaixo do inimigo (se ele estiver vivo e nao tiver outro tiro dele na tela)
	# agora = tempo do sistema em ms (syscall 30: parte baixa em a0)
	li $v0, 30
	syscall

	# if agora - ultimo_tiro_inimigo < TIRO_INIMIGO_INTERVALO return
	lw $t0, ultimo_tiro_inimigo
	subu $t1, $a0, $t0
	bltu $t1, TIRO_INIMIGO_INTERVALO, inimigo_atirar_fim

	# if not inimigo_vivo or existe_tiro_inimigo return
	lw $t0, inimigo_vivo
	beqz $t0, inimigo_atirar_fim
	lw $t0, existe_tiro_inimigo
	bnez $t0, inimigo_atirar_fim

	# ultimo_tiro_inimigo = agora
	sw $a0, ultimo_tiro_inimigo

	# existe_tiro_inimigo = 1
	# (tiro_inimigo_x, tiro_inimigo_y) = (inimigo_x, inimigo_y + 2), logo abaixo do inimigo
	li $t0, 1
	sw $t0, existe_tiro_inimigo
	lw $t0, inimigo_x
	sw $t0, tiro_inimigo_x
	lw $t0, inimigo_y
	addi $t0, $t0, 2
	sw $t0, tiro_inimigo_y
	sw $zero, tiro_inimigo_incremented_position

	inimigo_atirar_fim:
	jr $ra

desenhar_tiro_inimigo:# (a0) = (cor) -> desenha o tiro do inimigo em (tiro_inimigo_x, tiro_inimigo_y)
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	move $a2, $a0

	# if not existe_tiro_inimigo return
	lw $t0, existe_tiro_inimigo
	beqz $t0, desenhar_tiro_inimigo_fim

	lw $a0, tiro_inimigo_x
	lw $a1, tiro_inimigo_y
	jal desenhar_pixel

	desenhar_tiro_inimigo_fim:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

movimentar_tiro_inimigo:# desce o tiro do inimigo 1 pixel a cada TIRO_INIMIGO_SIZE_INCREMENT voltas; some quando sai por baixo da tela
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	# if not existe_tiro_inimigo return
	lw $t0, existe_tiro_inimigo
	beqz $t0, movimentar_tiro_inimigo_fim

	#tiro_inimigo_incremented_position++
	#if tiro_inimigo_incremented_position < TIRO_INIMIGO_SIZE_INCREMENT return
	lw $t0, tiro_inimigo_incremented_position
	addi $t0, $t0, 1
	sw $t0, tiro_inimigo_incremented_position
	blt $t0, TIRO_INIMIGO_SIZE_INCREMENT, movimentar_tiro_inimigo_fim

	#tiro_inimigo_incremented_position = 0
	sw $zero, tiro_inimigo_incremented_position

	#apaga tiro atual
	li $a0, PRETO
	jal desenhar_tiro_inimigo

	#tiro_inimigo_y++
	lw $t0, tiro_inimigo_y
	addi $t0, $t0, 1
	sw $t0, tiro_inimigo_y

	# if tiro_inimigo_y > 31 (saiu por baixo da tela): existe_tiro_inimigo = 0; return
	ble $t0, 31, movimentar_tiro_inimigo_desenhar
	sw $zero, existe_tiro_inimigo
	j movimentar_tiro_inimigo_fim

	movimentar_tiro_inimigo_desenhar:
	li $a0, AMARELO
	jal desenhar_tiro_inimigo

	movimentar_tiro_inimigo_fim:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

tiro_acertou_inimigo:# -> v0 = 1 se o tiro (tiro_x, tiro_y) esta dentro do inimigo vivo, senao v0 = 0
	li $v0, 0

	# if not inimigo_vivo return 0
	lw $t0, inimigo_vivo
	beqz $t0, tiro_acertou_inimigo_fim

	# if tiro_y < inimigo_y or tiro_y > inimigo_y+1 return 0
	lw $t0, tiro_y
	lw $t1, inimigo_y
	blt $t0, $t1, tiro_acertou_inimigo_fim
	addi $t1, $t1, 1
	bgt $t0, $t1, tiro_acertou_inimigo_fim

	# if tiro_x < inimigo_x-2 or tiro_x > inimigo_x+2 return 0
	lw $t0, tiro_x
	lw $t1, inimigo_x
	addi $t2, $t1, -2
	blt $t0, $t2, tiro_acertou_inimigo_fim
	addi $t2, $t1, 2
	bgt $t0, $t2, tiro_acertou_inimigo_fim

	# acertou
	li $v0, 1

	tiro_acertou_inimigo_fim:
	jr $ra

matar_inimigo:# apaga o inimigo, toca o som de explosao e marca como morto (renasce depois de INIMIGO_RESPAWN voltas)
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	#apaga o inimigo
	li $a0, PRETO
	jal desenhar_inimigo

	jal som_explosao

	#inimigo_vivo = 0, inimigo_timer = 0
	sw $zero, inimigo_vivo
	sw $zero, inimigo_timer

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

renascer_inimigo:# o inimigo volta num x aleatorio entre INIMIGO_MIN_X e INIMIGO_MAX_X, andando para a direita
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	# x aleatorio: syscall 42 sorteia 0 <= a0 < a1
	li $a0, 0  # id do gerador de numeros aleatorios
	li $a1, 50 # INIMIGO_MAX_X - INIMIGO_MIN_X + 1 = 51 - 2 + 1 = 50 posicoes
	li $v0, 42
	syscall
	addi $a0, $a0, INIMIGO_MIN_X
	sw $a0, inimigo_x

	#inimigo_dir = 1 (direita), inimigo_vivo = 1, zera o contador de movimento
	li $t0, 1
	sw $t0, inimigo_dir
	sw $t0, inimigo_vivo
	sw $zero, inimigo_incremented_position

	#desenha o inimigo
	li $a0, VERM
	jal desenhar_inimigo

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
	
desenhar_inimigo:# (a0) = (cor) -> desenha o inimigo: retangulo 5x2, colunas inimigo_x-2 ate inimigo_x+2, linhas inimigo_y e inimigo_y+1
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)

	move $a2, $a0
	lw $a1, inimigo_y
	li $s1, 2 # s1 = linhas que faltam
	desenhar_inimigo_linha:
		lw $a0, inimigo_x
		addi $a0, $a0, -2 # comeca na coluna x-2
		li $s0, 5 # s0 = colunas que faltam
		desenhar_inimigo_coluna:
			jal desenhar_pixel
			addi $a0, $a0, 1
			addi $s0, $s0, -1
			bgtz $s0, desenhar_inimigo_coluna
		addi $a1, $a1, 1 # proxima linha
		addi $s1, $s1, -1
		bgtz $s1, desenhar_inimigo_linha

	lw $s1, 8($sp)
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 12
	jr $ra

movimentar_inimigo:# anda 1 pixel na direcao inimigo_dir a cada INIMIGO_SIZE_INCREMENT voltas; inverte a direcao nas bordas
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	# if inimigo morto: inimigo_timer++ e renasce quando chegar em INIMIGO_RESPAWN
	lw $t0, inimigo_vivo
	bnez $t0, movimentar_inimigo_vivo
	lw $t0, inimigo_timer
	addi $t0, $t0, 1
	sw $t0, inimigo_timer
	blt $t0, INIMIGO_RESPAWN, movimentar_inimigo_fim
	jal renascer_inimigo
	j movimentar_inimigo_fim

	movimentar_inimigo_vivo:
	#inimigo_incremented_position++
	#if inimigo_incremented_position < INIMIGO_SIZE_INCREMENT return
	lw $t0, inimigo_incremented_position
	addi $t0, $t0, 1
	sw $t0, inimigo_incremented_position
	blt $t0, INIMIGO_SIZE_INCREMENT, movimentar_inimigo_fim

	#inimigo_incremented_position = 0
	sw $zero, inimigo_incremented_position

	#apaga inimigo atual
	li $a0, PRETO
	jal desenhar_inimigo

	# proximo_x = inimigo_x + inimigo_dir
	lw $t0, inimigo_x
	lw $t1, inimigo_dir
	add $t2, $t0, $t1

	# if proximo_x saiu dos limites: inimigo_dir = -inimigo_dir e recalcula
	bgt $t2, INIMIGO_MAX_X, movimentar_inimigo_inverter
	blt $t2, INIMIGO_MIN_X, movimentar_inimigo_inverter
	j movimentar_inimigo_andar
	movimentar_inimigo_inverter:
		sub $t1, $zero, $t1
		sw $t1, inimigo_dir
		add $t2, $t0, $t1
	movimentar_inimigo_andar:
		sw $t2, inimigo_x

	#desenha inimigo na nova posicao
	li $a0, VERM
	jal desenhar_inimigo

	movimentar_inimigo_fim:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
desenhar_hud_linha:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	
	li $a0, 54
	li $a1, 31
	li $a2, HUD_COLOR
	line_loop:
		jal desenhar_pixel
		addi $a1, $a1, -1
		bgez $a1, line_loop
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

desenhar_hud_vidas:# desenha os 5 coracoes
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)

	li $s0, 5 # 5 coracoes
	li $s1, CORACAO_Y0 # y atual
	desenhar_hud_coracao:
		li $a0, CORACAO_X
		move $a1, $s1
		li $a2, ROSA
		jal desenhar_coracao
		addi $s0, $s0, -1
		addi $s1, $s1, CORACAO_PASSO
		bgtz $s0, desenhar_hud_coracao

	desenhar_hud_vidas_end:
	lw $s1, 8($sp)
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 12
	jr $ra

perder_uma_vida:# vidas-- e apaga o coracao de baixo
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	# if vidas <= 0 return
	lw $t0, vidas
	blez $t0, perder_uma_vida_fim

	#apagar coracao atual
	li $a0, CORACAO_X
	lw $a1, coracao_atual_y
	li $a2, PRETO
	jal desenhar_coracao

	#vidas --
	lw $t0, vidas
	addi $t0, $t0, -1
	sw $t0, vidas

	#coracao_atual_y -= 5
	lw $t0, coracao_atual_y
	addi $t0, $t0, -CORACAO_PASSO
	sw $t0, coracao_atual_y

	# if vidas == 0 end_program
	lw $t0, vidas
	beqz $t0, end_program

	perder_uma_vida_fim:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
	
# ===== numeros do placar =====
# cada numero ocupa uma caixa 3x5; (x, y) e o canto INFERIOR esquerdo da caixa
# (o y da tela cresce para baixo, entao subir 1 pixel = y-1)

desenhar_numero_0:# (a0, a1, a2) = (x, y, cor) -> desenha o numero 0 com o canto inferior esquerdo em (x, y)
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#x y
	jal desenhar_pixel
	
	#x+1 y
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y-1
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x y-1
	addi $a0, $a0, -2
	jal desenhar_pixel
	
	#x y-2
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x+2 y-2
	addi $a0, $a0, 2
	jal desenhar_pixel
	
	#x+2 y-3
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x y-3
	addi $a0, $a0, -2
	jal desenhar_pixel
	
	#x y-4
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x+1 y-4
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y-4
	addi $a0, $a0, 1
	jal desenhar_pixel

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
desenhar_numero_1:# (a0, a1, a2) = (x, y, cor) -> desenha o numero 1 com o canto inferior esquerdo em (x, y)
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#x+2 y
	addi $a0, $a0, 2
	jal desenhar_pixel
	
	#x+2 y-1
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x+2 y-2
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x+2 y-3
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x+2 y-4
	addi $a1, $a1, -1
	jal desenhar_pixel

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
desenhar_numero_2:# (a0, a1, a2) = (x, y, cor) -> desenha o numero 2 com o canto inferior esquerdo em (x, y)
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#x y
	jal desenhar_pixel
	
	#x+1 y
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x y-1
	addi $a0, $a0, -2
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x y-2
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x+1 y-2
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y-2
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y-3
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x y-4
	addi $a0, $a0, -2
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x+1 y-4
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y-4
	addi $a0, $a0, 1
	jal desenhar_pixel

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
desenhar_numero_3:# (a0, a1, a2) = (x, y, cor) -> desenha o numero 3 com o canto inferior esquerdo em (x, y)
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#x y
	jal desenhar_pixel
	
	#x+1 y
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y-1
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x+1 y-2
	addi $a0, $a0, -1
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x+2 y-2
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y-3
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x y-4
	addi $a0, $a0, -2
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x+1 y-4
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y-4
	addi $a0, $a0, 1
	jal desenhar_pixel

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
desenhar_numero_4:# (a0, a1, a2) = (x, y, cor) -> desenha o numero 4 com o canto inferior esquerdo em (x, y)
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#x+2 y
	addi $a0, $a0, 2
	jal desenhar_pixel
	
	#x+2 y-1
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x y-2
	addi $a0, $a0, -2
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x+1 y-2
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y-2
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y-3
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x y-3
	addi $a0, $a0, -2
	jal desenhar_pixel
	
	#x y-4
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x+2 y-4
	addi $a0, $a0, 2
	jal desenhar_pixel

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
desenhar_numero_5:# (a0, a1, a2) = (x, y, cor) -> desenha o numero 5 com o canto inferior esquerdo em (x, y)
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#x y
	jal desenhar_pixel
	
	#x+1 y
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y-1
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x y-2
	addi $a0, $a0, -2
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x+1 y-2
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y-2
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x y-3
	addi $a0, $a0, -2
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x y-4
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x+1 y-4
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y-4
	addi $a0, $a0, 1
	jal desenhar_pixel

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
desenhar_numero_6:# (a0, a1, a2) = (x, y, cor) -> desenha o numero 6 com o canto inferior esquerdo em (x, y)
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#x y
	jal desenhar_pixel
	
	#x+1 y
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y-1
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x y-1
	addi $a0, $a0, -2
	jal desenhar_pixel
	
	#x y-2
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x+1 y-2
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y-2
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x y-3
	addi $a0, $a0, -2
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x y-4
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x+1 y-4
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y-4
	addi $a0, $a0, 1
	jal desenhar_pixel

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
desenhar_numero_7:# (a0, a1, a2) = (x, y, cor) -> desenha o numero 7 com o canto inferior esquerdo em (x, y)
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#x+2 y
	addi $a0, $a0, 2
	jal desenhar_pixel
	
	#x+2 y-1
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x+2 y-2
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x+2 y-3
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x y-4
	addi $a0, $a0, -2
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x+1 y-4
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y-4
	addi $a0, $a0, 1
	jal desenhar_pixel

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
desenhar_numero_8:# (a0, a1, a2) = (x, y, cor) -> desenha o numero 8 com o canto inferior esquerdo em (x, y)
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#x y
	jal desenhar_pixel
	
	#x+1 y
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y-1
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x y-1
	addi $a0, $a0, -2
	jal desenhar_pixel
	
	#x y-2
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x+1 y-2
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y-2
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y-3
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x y-3
	addi $a0, $a0, -2
	jal desenhar_pixel
	
	#x y-4
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x+1 y-4
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y-4
	addi $a0, $a0, 1
	jal desenhar_pixel

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
desenhar_numero_9:# (a0, a1, a2) = (x, y, cor) -> desenha o numero 9 com o canto inferior esquerdo em (x, y)
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#x+2 y
	addi $a0, $a0, 2
	jal desenhar_pixel
	
	#x+2 y-1
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x y-2
	addi $a0, $a0, -2
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x+1 y-2
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y-2
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y-3
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x y-3
	addi $a0, $a0, -2
	jal desenhar_pixel
	
	#x y-4
	addi $a1, $a1, -1
	jal desenhar_pixel
	
	#x+1 y-4
	addi $a0, $a0, 1
	jal desenhar_pixel
	
	#x+2 y-4
	addi $a0, $a0, 1
	jal desenhar_pixel

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	

desenhar_digito:# (a0, a1, a2, a3) = (x, y, cor, digito) -> desenha o digito (0 a 9) com o canto inferior esquerdo em (x, y)
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# switch (digito): chama a desenhar_numero certa
	beq $a3, 0, desenhar_digito_0
	beq $a3, 1, desenhar_digito_1
	beq $a3, 2, desenhar_digito_2
	beq $a3, 3, desenhar_digito_3
	beq $a3, 4, desenhar_digito_4
	beq $a3, 5, desenhar_digito_5
	beq $a3, 6, desenhar_digito_6
	beq $a3, 7, desenhar_digito_7
	beq $a3, 8, desenhar_digito_8
	beq $a3, 9, desenhar_digito_9
	j desenhar_digito_fim # digito invalido: nao desenha nada
	desenhar_digito_0:
		jal desenhar_numero_0
		j desenhar_digito_fim
	desenhar_digito_1:
		jal desenhar_numero_1
		j desenhar_digito_fim
	desenhar_digito_2:
		jal desenhar_numero_2
		j desenhar_digito_fim
	desenhar_digito_3:
		jal desenhar_numero_3
		j desenhar_digito_fim
	desenhar_digito_4:
		jal desenhar_numero_4
		j desenhar_digito_fim
	desenhar_digito_5:
		jal desenhar_numero_5
		j desenhar_digito_fim
	desenhar_digito_6:
		jal desenhar_numero_6
		j desenhar_digito_fim
	desenhar_digito_7:
		jal desenhar_numero_7
		j desenhar_digito_fim
	desenhar_digito_8:
		jal desenhar_numero_8
		j desenhar_digito_fim
	desenhar_digito_9:
		jal desenhar_numero_9
	desenhar_digito_fim:
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
desenhar_score:# (a0, a1) = (score, cor) -> desenha o score (0 a 20) com 2 digitos: unidade em SCORE_X, dezena a esquerda
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	
	move $s1, $a1 # s1 = cor
	
	# score / 10: lo = quociente = dezena, hi = resto (mod 10) = unidade
	li $t0, 10
	div $a0, $t0
	mflo $s0 # s0 = dezena (guardada para a segunda chamada)
	mfhi $a3 # a3 = unidade
	
	# desenha a unidade em (SCORE_X, SCORE_Y)
	li $a0, SCORE_X
	li $a1, SCORE_Y
	move $a2, $s1
	jal desenhar_digito
	
	# desenha a dezena a esquerda da unidade (3 pixels do digito + 1 de espaco = 4 colunas)
	li $a0, SCORE_X
	addi $a0, $a0, -4
	li $a1, SCORE_Y
	move $a2, $s1
	move $a3, $s0
	jal desenhar_digito
	
	lw $s1, 8($sp)
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 12
	jr $ra
	

limpar_tela:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $t0, 0
	limpar_tela_loop:
		
		sw $0, display($t0)
		
		addi $t0, $t0, 4
		blt $t0, DISPLAY_LENGTH, limpar_tela_loop
	
	
	lw $ra, 0($sp)
	addi, $sp, $sp, 4
	jr $ra
	

sleep1:
	li $v0, 32
	li $a0, 1
	syscall
	jr $ra

# ===== rick rolling =====
# Feature independente: tela de vitoria (nave voando para longe + fogos de artificio) tocando
# "Never Gonna Give You Up". Para mover a feature, basta mover a chamada "jal rick_rolling".
# Depende so de helpers genericos (limpar_tela, desenhar_pixel) e das words player_x/player_y
# (so para a nave comecar onde o jogador estava). Tudo que comeca com rick_ pertence a feature.
# O andamento (musica e animacao) e controlado pelo relogio do sistema (syscall 30): a musica
# avanca 1 "passo" (semicolcheia) a cada RICK_UNIDADE_MS e a animacao 1 quadro a cada RICK_FRAME_MS.
# Melodia aproximada, escrita de ouvido (tom de Lab maior); acordes: IV V iii vi (Db Eb Dom Fam).
.data
	.eqv RICK_UNIDADE_MS 133 # 1 passo = semicolcheia (~113 bpm)
	.eqv RICK_FRAME_MS 66    # 1 quadro da animacao
	.eqv RICK_MELODIA_INSTR 85 # Lead 6 (voice): lead "vocal"
	.eqv RICK_BAIXO_INSTR 38   # Synth Bass 1
	.eqv RICK_PAD_INSTR 89     # Pad 2 (warm): acordes ao fundo
	.eqv RICK_BUMBO_INSTR 116  # Taiko Drum: bumbo
	.eqv RICK_CAIXA_INSTR 118  # Synth Drum: caixa
	.eqv RICK_CHIMBAL_INSTR 115 # Woodblock: chimbal
	.eqv RICK_BAIXO_MS 230
	.eqv RICK_PAD_MS 1050
	# melodia: nota (MIDI, 0 = pausa), duracao em passos; duracao 0 = fim. Cada bloco tem 32 passos (2 compassos)
	rick_musica:
	# introducao (64 passos): "tatarantaa tatarantaa taa taa" + pausa so com a batida
	.word 68,2, 68,2, 70,2, 72,4, 0,6
	.word 68,2, 68,2, 70,2, 72,4, 0,6
	.word 75,4, 72,4, 0,8
	.word 0,16
	# "Never gonna give you up" (Mib Fa Lab Fa | Do Do Sib)
	.word 63,2, 65,2, 68,2, 65,2, 72,3, 72,3, 70,6, 0,12
	# "Never gonna let you down" (Mib Fa Lab Fa | Sib Sib Lab)
	.word 63,2, 65,2, 68,2, 65,2, 70,3, 70,3, 68,6, 0,12
	# "Never gonna run around and desert you"
	.word 63,2, 65,2, 68,2, 65,2, 68,3, 70,2, 67,3, 65,3, 63,3, 0,10
	# "Never gonna give you up" de novo
	.word 63,2, 65,2, 68,2, 65,2, 72,3, 72,3, 70,10, 0,8
	.word 0,0
	# acordes, 1 a cada 8 passos: baixo, e 3 notas do acorde
	rick_acordes:
	.word 37,61,65,68 # Db
	.word 39,63,67,70 # Eb
	.word 36,60,63,67 # Dom
	.word 41,65,68,72 # Fam
	# 8 direcoes (dx, dy) das faiscas dos fogos
	rick_dirs: .word 1,0, -1,0, 0,1, 0,-1, 1,1, -1,-1, 1,-1, -1,1
	# cores dos fogos: branco, vermelho, amarelo, rosa, ciano, verde
	rick_cores: .word 0x00FFFFFF, 0x00FF0000, 0x00FFFF00, 0x00FF69B4, 0x0000FFFF, 0x0000FF00
	# 3 fogos, 4 words cada: x, y da explosao, idade (negativa = esperando), cor
	rick_fogos: .word 0,0,0,0, 0,0,0,0, 0,0,0,0
	rick_nave_x: .word 0
	rick_nave_y: .word 0
	rick_frame: .word 0
.text

rick_rolling:# toca a musica inteira enquanto anima a vitoria
	addi $sp, $sp, -32
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	sw $s5, 24($sp)
	sw $s6, 28($sp)

	jal limpar_tela

	# a nave comeca onde o jogador estava
	lw $t0, player_x
	sw $t0, rick_nave_x
	lw $t0, player_y
	sw $t0, rick_nave_y
	sw $zero, rick_frame

	# sorteia os 3 fogos; cada um espera um tempo diferente para comecar
	la $s0, rick_fogos
	li $s1, 3
	li $s2, -10
	rick_rolling_init_fogos:
		move $a0, $s0
		jal rick_fogo_renascer
		sw $s2, 8($s0)
		addi $s0, $s0, 16
		addi $s2, $s2, -20
		addi $s1, $s1, -1
		bgtz $s1, rick_rolling_init_fogos

	# desenha a nave
	lw $a0, rick_nave_x
	lw $a1, rick_nave_y
	li $a2, AZUL
	li $a3, AMARELO
	jal rick_nave

	la $s0, rick_musica # s0 = proxima nota da melodia
	li $s3, 0           # s3 = numero do passo musical
	li $s4, 0           # s4 = passos que faltam para a nota atual acabar
	li $v0, 30
	syscall
	move $s1, $a0       # s1 = instante do proximo passo musical (ms)
	move $s2, $a0       # s2 = instante do proximo quadro da animacao (ms)

	rick_rolling_loop:
		li $v0, 30
		syscall
		move $s6, $a0 # s6 = agora (ms)

		# if agora < s1: ainda nao e hora do proximo passo
		subu $t0, $s6, $s1
		bltz $t0, rick_rolling_anim

		# --- melodia: se a nota atual acabou, toca a proxima ---
		bnez $s4, rick_rolling_ritmo
		lw $t0, 4($s0) # duracao em passos
		beqz $t0, rick_rolling_fim
		move $s4, $t0
		li $t1, RICK_UNIDADE_MS
		mul $a1, $t0, $t1
		addi $a1, $a1, -15 # respiro entre notas iguais
		lw $a0, 0($s0)
		addi $s0, $s0, 8
		beqz $a0, rick_rolling_ritmo # pausa
		li $a2, RICK_MELODIA_INSTR
		li $a3, 100
		jal rick_tocar

		rick_rolling_ritmo:
		# s5 = acorde atual (muda a cada 8 passos, ciclo de 4 acordes)
		srl $t1, $s3, 3
		andi $t1, $t1, 3
		sll $t1, $t1, 4
		la $s5, rick_acordes
		add $s5, $s5, $t1

		# bumbo em toda batida (a cada 4 passos)
		andi $t0, $s3, 3
		bnez $t0, rick_rolling_caixa
		li $a0, 36
		li $a1, 120
		li $a2, RICK_BUMBO_INSTR
		li $a3, 110
		jal rick_tocar
		rick_rolling_caixa:
		# caixa nos tempos 2 e 4
		andi $t0, $s3, 7
		bne $t0, 4, rick_rolling_chimbal
		li $a0, 55
		li $a1, 120
		li $a2, RICK_CAIXA_INSTR
		li $a3, 95
		jal rick_tocar
		rick_rolling_chimbal:
		# chimbal na contratempo (passo 2 de cada batida)
		andi $t0, $s3, 3
		bne $t0, 2, rick_rolling_baixo
		li $a0, 96
		li $a1, 40
		li $a2, RICK_CHIMBAL_INSTR
		li $a3, 55
		jal rick_tocar
		rick_rolling_baixo:
		# baixo em colcheias, subindo uma oitava no contratempo
		andi $t0, $s3, 1
		bnez $t0, rick_rolling_pad
		lw $a0, 0($s5)
		andi $t0, $s3, 3
		bne $t0, 2, rick_rolling_baixo_tocar
		addi $a0, $a0, 12
		rick_rolling_baixo_tocar:
		li $a1, RICK_BAIXO_MS
		li $a2, RICK_BAIXO_INSTR
		li $a3, 95
		jal rick_tocar
		rick_rolling_pad:
		# acorde (3 notas) a cada 8 passos
		andi $t0, $s3, 7
		bnez $t0, rick_rolling_passo_fim
		lw $a0, 4($s5)
		li $a1, RICK_PAD_MS
		li $a2, RICK_PAD_INSTR
		li $a3, 45
		jal rick_tocar
		lw $a0, 8($s5)
		li $a1, RICK_PAD_MS
		li $a2, RICK_PAD_INSTR
		li $a3, 45
		jal rick_tocar
		lw $a0, 12($s5)
		li $a1, RICK_PAD_MS
		li $a2, RICK_PAD_INSTR
		li $a3, 45
		jal rick_tocar

		rick_rolling_passo_fim:
		addi $s4, $s4, -1
		addi $s3, $s3, 1
		addiu $s1, $s1, RICK_UNIDADE_MS

		rick_rolling_anim:
		# if agora >= s2: desenha o proximo quadro da animacao
		subu $t0, $s6, $s2
		bltz $t0, rick_rolling_espera
		jal rick_animar
		addiu $s2, $s2, RICK_FRAME_MS

		rick_rolling_espera:
		li $v0, 32
		li $a0, 1
		syscall
		j rick_rolling_loop

	rick_rolling_fim:
	# deixa a ultima nota terminar de soar
	li $v0, 32
	li $a0, 800
	syscall

	lw $s6, 28($sp)
	lw $s5, 24($sp)
	lw $s4, 20($sp)
	lw $s3, 16($sp)
	lw $s2, 12($sp)
	lw $s1, 8($sp)
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 32
	jr $ra

rick_tocar:# (a0, a1, a2, a3) = (nota, duracao ms, instrumento, volume) -> toca sem travar (syscall 31)
	li $v0, 31
	syscall
	jr $ra

rick_pixel:# (a0, a1, a2) = (x, y, cor) -> desenha o pixel so se estiver dentro da tela
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	bltz $a0, rick_pixel_fim
	bgt $a0, 63, rick_pixel_fim
	bltz $a1, rick_pixel_fim
	bgt $a1, 31, rick_pixel_fim
	jal desenhar_pixel
	rick_pixel_fim:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

rick_linha:# (a0, a1, a2, a3) = (x, y, cor, n) -> desenha n pixels na horizontal a partir de (x, y)
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	move $s0, $a0
	move $s1, $a1
	move $s2, $a2
	move $s3, $a3
	rick_linha_loop:
		move $a0, $s0
		move $a1, $s1
		move $a2, $s2
		jal rick_pixel
		addi $s0, $s0, 1
		addi $s3, $s3, -1
		bgtz $s3, rick_linha_loop
	lw $s3, 16($sp)
	lw $s2, 12($sp)
	lw $s1, 8($sp)
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 20
	jr $ra

rick_nave:# (a0, a1, a2, a3) = (x, y, cor da nave, cor da chama) -> nave igual a do jogador, com chama de 2 pixels embaixo
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	move $s0, $a0
	move $s1, $a1
	move $s2, $a2
	move $s3, $a3

	# linha de cima: x-1 ate x+1 em y-1
	addi $a0, $s0, -1
	addi $a1, $s1, -1
	move $a2, $s2
	li $a3, 3
	jal rick_linha
	# linha de baixo: x-2 ate x+2 em y
	addi $a0, $s0, -2
	move $a1, $s1
	move $a2, $s2
	li $a3, 5
	jal rick_linha
	# chama: (x, y+1) e (x, y+2)
	move $a0, $s0
	addi $a1, $s1, 1
	move $a2, $s3
	li $a3, 1
	jal rick_linha
	move $a0, $s0
	addi $a1, $s1, 2
	move $a2, $s3
	li $a3, 1
	jal rick_linha

	lw $s3, 16($sp)
	lw $s2, 12($sp)
	lw $s1, 8($sp)
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 20
	jr $ra

rick_anel:# (a0, a1, a2, a3) = (x, y, cor, raio) -> 8 faiscas ao redor de (x, y)
	addi $sp, $sp, -28
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	sw $s5, 24($sp)
	move $s0, $a0
	move $s1, $a1
	move $s2, $a2
	move $s3, $a3
	la $s4, rick_dirs
	li $s5, 8
	rick_anel_loop:
		lw $t0, 0($s4)
		lw $t1, 4($s4)
		mul $t0, $t0, $s3
		mul $t1, $t1, $s3
		add $a0, $s0, $t0
		add $a1, $s1, $t1
		move $a2, $s2
		jal rick_pixel
		addi $s4, $s4, 8
		addi $s5, $s5, -1
		bgtz $s5, rick_anel_loop
	lw $s5, 24($sp)
	lw $s4, 20($sp)
	lw $s3, 16($sp)
	lw $s2, 12($sp)
	lw $s1, 8($sp)
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 28
	jr $ra

rick_fogo_renascer:# (a0) = (ponteiro do fogo) -> sorteia x, y e cor e zera a idade
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	move $s0, $a0

	# x entre 8 e 55
	li $a0, 0
	li $a1, 48
	li $v0, 42
	syscall
	addi $a0, $a0, 8
	sw $a0, 0($s0)
	# y da explosao entre 6 e 14
	li $a0, 0
	li $a1, 9
	li $v0, 42
	syscall
	addi $a0, $a0, 6
	sw $a0, 4($s0)
	# cor sorteada da tabela
	li $a0, 0
	li $a1, 6
	li $v0, 42
	syscall
	sll $a0, $a0, 2
	lw $t0, rick_cores($a0)
	sw $t0, 12($s0)
	sw $zero, 8($s0)

	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 8
	jr $ra

rick_fogo_desenhar:# (a0, a1) = (ponteiro do fogo, cor) -> idade 0 a 9: foguete subindo; 10 a 18: explosao crescendo
	addi $sp, $sp, -24
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	lw $s0, 0($a0) # x
	lw $s1, 4($a0) # y da explosao
	lw $s2, 8($a0) # idade
	move $s3, $a1  # cor
	bltz $s2, rick_fogo_desenhar_fim
	bge $s2, 10, rick_fogo_desenhar_explosao

	# foguete: y = 31 - idade * (31 - y_explosao) / 9
	li $t0, 31
	sub $t1, $t0, $s1
	mul $t1, $t1, $s2
	li $t2, 9
	div $t1, $t2
	mflo $t1
	sub $a1, $t0, $t1
	move $a0, $s0
	move $a2, $s3
	jal rick_pixel
	j rick_fogo_desenhar_fim

	rick_fogo_desenhar_explosao:
	addi $s4, $s2, -9 # raio = 1 a 9
	move $a0, $s0
	move $a1, $s1
	move $a2, $s3
	move $a3, $s4
	jal rick_anel
	blt $s4, 3, rick_fogo_desenhar_fim
	# anel interno, para a explosao ficar mais cheia
	move $a0, $s0
	move $a1, $s1
	move $a2, $s3
	srl $a3, $s4, 1
	jal rick_anel

	rick_fogo_desenhar_fim:
	lw $s4, 20($sp)
	lw $s3, 16($sp)
	lw $s2, 12($sp)
	lw $s1, 8($sp)
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 24
	jr $ra

rick_fogo_atualizar:# (a0) = (ponteiro do fogo) -> apaga, avanca 1 quadro e redesenha
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	move $s0, $a0

	lw $t0, 8($s0)
	bgez $t0, rick_fogo_atualizar_ativo
	# esperando: so avanca a idade
	addi $t0, $t0, 1
	sw $t0, 8($s0)
	j rick_fogo_atualizar_fim

	rick_fogo_atualizar_ativo:
	li $a1, PRETO
	jal rick_fogo_desenhar # apaga o quadro anterior (a0 ainda e o ponteiro)
	lw $t0, 8($s0)
	addi $t0, $t0, 1
	sw $t0, 8($s0)
	bgt $t0, 18, rick_fogo_atualizar_renascer
	move $a0, $s0
	lw $a1, 12($s0)
	jal rick_fogo_desenhar
	j rick_fogo_atualizar_fim

	rick_fogo_atualizar_renascer:
	move $a0, $s0
	jal rick_fogo_renascer
	li $t0, -6 # pequena pausa antes do proximo foguete
	sw $t0, 8($s0)

	rick_fogo_atualizar_fim:
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 8
	jr $ra

rick_animar:# 1 quadro: a nave sobe 1 pixel a cada 4 quadros (ate sumir) e os fogos avancam
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)

	lw $t0, rick_frame
	addi $t0, $t0, 1
	sw $t0, rick_frame

	# apaga a nave (se ainda estiver na tela) e a move
	lw $a1, rick_nave_y
	ble $a1, -3, rick_animar_fogos
	lw $a0, rick_nave_x
	li $a2, PRETO
	li $a3, PRETO
	jal rick_nave
	lw $t0, rick_frame
	andi $t0, $t0, 3
	bnez $t0, rick_animar_fogos
	lw $t0, rick_nave_y
	addi $t0, $t0, -1
	sw $t0, rick_nave_y

	rick_animar_fogos:
	la $s0, rick_fogos
	li $s1, 3
	rick_animar_fogos_loop:
		move $a0, $s0
		jal rick_fogo_atualizar
		addi $s0, $s0, 16
		addi $s1, $s1, -1
		bgtz $s1, rick_animar_fogos_loop

	# redesenha a nave por cima dos fogos, com a chama piscando
	lw $a1, rick_nave_y
	ble $a1, -3, rick_animar_fim
	lw $a0, rick_nave_x
	li $a2, AZUL
	li $a3, AMARELO
	lw $t0, rick_frame
	andi $t0, $t0, 1
	beqz $t0, rick_animar_nave
	li $a3, VERM
	rick_animar_nave:
	jal rick_nave

	rick_animar_fim:
	lw $s1, 8($sp)
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 12
	jr $ra

end_program:
	li $v0, 10
	syscall
