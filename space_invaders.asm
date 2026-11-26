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
	.eqv INIMIGO_SIZE_INCREMENT 80 # velocidade inicial do inimigo
	.eqv INIMIGO_SIZE_INCREMENT_MIN 20 # velocidade maxima do inimigo
	.eqv INIMIGO_ACELERACAO 3 # inimigo_size_increment -= 3 a cada morte
	.eqv PLAYER_MAX_X 51
	.eqv INIMIGO_MIN_X 2  # x-2 >= 0
	.eqv INIMIGO_MAX_X 51 # x+2 <= 53 (antes do HUD)
	.eqv INIMIGO_RESPAWN 500 # voltas morto ate renascer
	.eqv TIRO_INIMIGO_INTERVALO 1000 # ms entre tiros do inimigo
	.eqv TIRO_INIMIGO_SIZE_INCREMENT 15 # voltas por pixel do tiro do inimigo
	.eqv IMAGEM_X 21 # (64 - 7*3)/2
	.eqv IMAGEM_Y 4  # (32 - 8*3)/2
	.eqv SCORE_X 60 # x da unidade (dezena em x-4)
	.eqv SCORE_Y 5  # y de baixo dos digitos
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
	inimigo_size_increment: .word INIMIGO_SIZE_INCREMENT # velocidade atual do inimigo
	inimigo_vivo: .word 1 # 1 vivo, 0 morto
	inimigo_timer: .word 0 # voltas desde que morreu
	existe_tiro_inimigo: .word 0
	tiro_inimigo_x: .word 0
	tiro_inimigo_y: .word 0
	tiro_inimigo_incremented_position: .word 0
	ultimo_tiro_inimigo: .word 0 # ms do ultimo tiro do inimigo
	caveira: .word 0x3E, 0x7F, 0x7F, 0x7F, 0x49, 0x49, 0x36, 0x1C
	trofeu: .word 0x7F, 0x5D, 0x5D, 0x3E, 0x1C, 0x08, 0x1C, 0x3E
	

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

	# ultimo_tiro_inimigo = agora
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


# ===== funcoes de movimentacao =====

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
	# if acertou inimigo: deletar_tiro, matar_inimigo, score++; return
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

movimentar_inimigo:# lógica de movimentação do inimigo, inverte nas bordas
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	# if not inimigo_vivo: inimigo_timer++; if inimigo_timer >= INIMIGO_RESPAWN renascer_inimigo
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
	#if inimigo_incremented_position < inimigo_size_increment return
	lw $t0, inimigo_incremented_position
	addi $t0, $t0, 1
	sw $t0, inimigo_incremented_position
	lw $t1, inimigo_size_increment
	blt $t0, $t1, movimentar_inimigo_fim

	#inimigo_incremented_position = 0
	sw $zero, inimigo_incremented_position

	#apaga inimigo atual
	li $a0, PRETO
	jal desenhar_inimigo

	# proximo_x = inimigo_x + inimigo_dir
	lw $t0, inimigo_x
	lw $t1, inimigo_dir
	add $t2, $t0, $t1

	# if proximo_x fora dos limites: inimigo_dir = -inimigo_dir
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

renascer_inimigo:# inimigo volta num x aleatorio, andando pra direita
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	# x aleatorio (syscall 42: 0 <= a0 < a1)
	li $a0, 0  # id do gerador
	li $a1, 50 # 51 - 2 + 1 posicoes
	li $v0, 42
	syscall
	addi $a0, $a0, INIMIGO_MIN_X
	sw $a0, inimigo_x

	#inimigo_dir = 1, inimigo_vivo = 1, inimigo_incremented_position = 0
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

matar_inimigo:# apaga o inimigo, som_explosao, inimigo_vivo = 0
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	#apaga o inimigo
	li $a0, PRETO
	jal desenhar_inimigo

	jal som_explosao

	#inimigo_vivo = 0, inimigo_timer = 0
	sw $zero, inimigo_vivo
	sw $zero, inimigo_timer

	jal aumentar_dificuldade

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

aumentar_dificuldade:# deixa o inimigo mais rapido
	#inimigo_size_increment -= INIMIGO_ACELERACAO
	lw $t0, inimigo_size_increment
	addi $t0, $t0, -INIMIGO_ACELERACAO

	# if inimigo_size_increment < INIMIGO_SIZE_INCREMENT_MIN: inimigo_size_increment = INIMIGO_SIZE_INCREMENT_MIN
	bge $t0, INIMIGO_SIZE_INCREMENT_MIN, aumentar_dificuldade_fim
	li $t0, INIMIGO_SIZE_INCREMENT_MIN

	aumentar_dificuldade_fim:
	sw $t0, inimigo_size_increment
	jr $ra

inimigo_atirar:# cria um tiro abaixo do inimigo a cada TIRO_INIMIGO_INTERVALO ms
	# agora = tempo em ms (syscall 30)
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
	# (tiro_inimigo_x, tiro_inimigo_y) = (inimigo_x, inimigo_y + 2)
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

movimentar_tiro_inimigo:# lógica de movimentação do tiro do inimigo, desce 1 pixel
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

	# if nave andou pra cima do tiro: acertou (nao apaga)
	jal tiro_inimigo_acertou_nave
	bnez $v0, movimentar_tiro_inimigo_acertou

	#apaga tiro atual
	li $a0, PRETO
	jal desenhar_tiro_inimigo

	#tiro_inimigo_y++
	lw $t0, tiro_inimigo_y
	addi $t0, $t0, 1
	sw $t0, tiro_inimigo_y

	# if tiro_inimigo_y > 31: existe_tiro_inimigo = 0; return
	ble $t0, 31, movimentar_tiro_inimigo_checar_nave
	sw $zero, existe_tiro_inimigo
	j movimentar_tiro_inimigo_fim

	movimentar_tiro_inimigo_checar_nave:
	# if acertou nave: som_dano, perder_uma_vida, redesenha nave; return
	jal tiro_inimigo_acertou_nave
	beqz $v0, movimentar_tiro_inimigo_desenhar
	movimentar_tiro_inimigo_acertou:
	sw $zero, existe_tiro_inimigo
	jal som_dano
	jal perder_uma_vida
	li $a0, AZUL
	jal desenhar_player
	j movimentar_tiro_inimigo_fim

	movimentar_tiro_inimigo_desenhar:
	li $a0, AMARELO
	jal desenhar_tiro_inimigo

	movimentar_tiro_inimigo_fim:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


# ===== funcoes de desenhar =====

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

desenhar_inimigo:# (a0) = (cor) -> desenha o inimigo 5x2 na posicao (inimigo_x, inimigo_y)
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)

	move $a2, $a0
	lw $a1, inimigo_y
	li $s1, 2 # linhas
	desenhar_inimigo_linha:
		lw $a0, inimigo_x
		addi $a0, $a0, -2 # x-2
		li $s0, 5 # colunas
		desenhar_inimigo_coluna:
			jal desenhar_pixel
			addi $a0, $a0, 1
			addi $s0, $s0, -1
			bgtz $s0, desenhar_inimigo_coluna
		addi $a1, $a1, 1 # y+1
		addi $s1, $s1, -1
		bgtz $s1, desenhar_inimigo_linha

	lw $s1, 8($sp)
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 12
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

desenhar_coracao:# (a0, a1, a2) = (x,y,cor) -> desenha um coracao 5x4 em (x,y)
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

desenhar_score:# (a0, a1) = (score,cor) -> desenha o score com 2 digitos
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	
	move $s1, $a1 # cor
	
	# score / 10: lo = dezena, hi = unidade
	li $t0, 10
	div $a0, $t0
	mflo $s0 # dezena
	mfhi $a3 # unidade
	
	#desenhar unidade
	li $a0, SCORE_X
	li $a1, SCORE_Y
	move $a2, $s1
	jal desenhar_digito
	
	#desenhar dezena
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

desenhar_digito:# (a0, a1, a2, a3) = (x,y,cor,digito) -> desenha o digito em (x,y)
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# switch digito
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
	j desenhar_digito_fim # default
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

# numeros 3x5, (x,y) = canto inferior esquerdo
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

desenhar_imagem:# (a0, a1) = (imagem,cor) -> desenha a imagem 7x8 com blocos 3x3 em (IMAGEM_X, IMAGEM_Y)
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)

	move $s3, $a0 # imagem
	move $a2, $a1 # cor

	li $s0, 0 # linha
	desenhar_imagem_linha:
		sll $t0, $s0, 2
		add $t0, $t0, $s3
		lw $s1, 0($t0) # bits da linha
		li $s2, 0 # coluna
		desenhar_imagem_coluna:
			# if bit (6 - coluna) == 0 continue
			li $t0, 6
			sub $t0, $t0, $s2
			srlv $t1, $s1, $t0
			andi $t1, $t1, 1
			beqz $t1, desenhar_imagem_proxima

			# desenhar_bloco(IMAGEM_X + 3*coluna, IMAGEM_Y + 3*linha, cor)
			sll $t0, $s2, 1
			add $t0, $t0, $s2
			addi $a0, $t0, IMAGEM_X
			sll $t0, $s0, 1
			add $t0, $t0, $s0
			addi $a1, $t0, IMAGEM_Y
			jal desenhar_bloco

			desenhar_imagem_proxima:
			addi $s2, $s2, 1
			blt $s2, 7, desenhar_imagem_coluna
		addi $s0, $s0, 1
		blt $s0, 8, desenhar_imagem_linha

	lw $s3, 16($sp)
	lw $s2, 12($sp)
	lw $s1, 8($sp)
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 20
	jr $ra

desenhar_bloco:# (a0, a1, a2) = (x,y,cor) -> desenha um bloco 3x3 em (x,y)
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

	#x+2 y+1
	addi $a1, $a1, 1
	jal desenhar_pixel
	#x+1 y+1
	addi $a0, $a0, -1
	jal desenhar_pixel
	#x y+1
	addi $a0, $a0, -1
	jal desenhar_pixel

	#x y+2
	addi $a1, $a1, 1
	jal desenhar_pixel
	#x+1 y+2
	addi $a0, $a0, 1
	jal desenhar_pixel
	#x+2 y+2
	addi $a0, $a0, 1
	jal desenhar_pixel

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


# ===== funcoes ferramenta =====

calcular_index:#(x,y) calcula o indice do pixel no array de cores dados x e y.
	move $t0, $a1
	sll $t0, $t0, 8 # 4(y * 64) 
	sll $t1, $a0, 2 # 4x
	add $t0, $t0, $t1 
	move $v0, $t0 
	jr $ra

tiro_acertou_inimigo:# -> (v0) = 1 se o tiro acertou o inimigo, senao 0
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

	# return 1
	li $v0, 1

	tiro_acertou_inimigo_fim:
	jr $ra

tiro_inimigo_acertou_nave:# -> (v0) = 1 se o tiro do inimigo acertou a nave, senao 0
	# nave: linha y (x-2 ate x+2), linha y-1 (x-1 ate x+1)
	li $v0, 0
	lw $t0, tiro_inimigo_x
	lw $t1, tiro_inimigo_y
	lw $t2, player_x
	lw $t3, player_y

	# dx = |tiro_inimigo_x - player_x|
	sub $t4, $t0, $t2
	abs $t4, $t4

	# if tiro_inimigo_y == player_y and dx <= 2 return 1
	bne $t1, $t3, tiro_inimigo_acertou_nave_cima
	ble $t4, 2, tiro_inimigo_acertou_nave_sim
	j tiro_inimigo_acertou_nave_fim

	# if tiro_inimigo_y == player_y-1 and dx <= 1 return 1
	tiro_inimigo_acertou_nave_cima:
	addi $t3, $t3, -1
	bne $t1, $t3, tiro_inimigo_acertou_nave_fim
	bgt $t4, 1, tiro_inimigo_acertou_nave_fim

	tiro_inimigo_acertou_nave_sim:
	li $v0, 1

	tiro_inimigo_acertou_nave_fim:
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

	# if score >= 20 vitoria
	lw $t0, score
	bge $t0, 20, vitoria

	lw $ra, 0($sp)
	addi $sp, $sp, 4
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

	# if vidas == 0 game_over
	lw $t0, vidas
	beqz $t0, game_over

	perder_uma_vida_fim:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

som_tiro: # toca o som do disparo (syscall 31 = MIDI assincrono, nao trava o jogo)
	li $a0, 84   # nota (tom agudo)
	li $a1, 250  # duracao em ms
	li $a2, 118  # instrumento: Synth Drum
	li $a3, 100  # volume (0-127)
	li $v0, 31
	syscall
	jr $ra

som_explosao: # toca o som da explosao do inimigo (syscall 31)
	li $a0, 40   # nota (tom grave)
	li $a1, 500  # duracao em ms
	li $a2, 127  # instrumento: Gunshot
	li $a3, 127  # volume (0-127)
	li $v0, 31
	syscall
	jr $ra

som_dano: # toca o som da nave atingida (syscall 31)
	li $a0, 50   # nota (grave)
	li $a1, 400  # duracao em ms
	li $a2, 81   # instrumento: Saw Lead
	li $a3, 127  # volume (0-127)
	li $v0, 31
	syscall
	jr $ra

sleep1:
	li $v0, 32
	li $a0, 1
	syscall
	jr $ra

game_over:# caveira e end_program
	jal limpar_tela
	la $a0, caveira
	li $a1, BRANCO
	jal desenhar_imagem
	j end_program

vitoria:# trofeu e end_program
	jal limpar_tela
	la $a0, trofeu
	li $a1, AMARELO
	jal desenhar_imagem
	j end_program

end_program:
	li $v0, 10
	syscall
