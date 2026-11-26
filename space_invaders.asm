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
	.eqv INIMIGO_SIZE_INCREMENT 80 # valor inicial de inimigo_size_increment
	.eqv INIMIGO_SIZE_INCREMENT_MIN 20 # mais rapido que o inimigo pode ficar
	.eqv INIMIGO_ACELERACAO 3 # quanto inimigo_size_increment diminui a cada inimigo morto
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
	inimigo_size_increment: .word INIMIGO_SIZE_INCREMENT # voltas por passo do inimigo, diminui a cada morte
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

	# if score >= 20 end_program
	lw $t0, score
	bge $t0, 20, end_program

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

som_dano: # toca o som quando a nave e atingida (syscall 31, nao trava o jogo)
	li $a0, 50   # nota (grave)
	li $a1, 400  # duracao em ms
	li $a2, 81   # instrumento: Saw Lead
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

	# if a nave andou pra cima do tiro: acertou (nao apaga, o pixel agora e da nave)
	jal tiro_inimigo_acertou_nave
	bnez $v0, movimentar_tiro_inimigo_acertou

	#apaga tiro atual
	li $a0, PRETO
	jal desenhar_tiro_inimigo

	#tiro_inimigo_y++
	lw $t0, tiro_inimigo_y
	addi $t0, $t0, 1
	sw $t0, tiro_inimigo_y

	# if tiro_inimigo_y > 31 (saiu por baixo da tela): existe_tiro_inimigo = 0; return
	ble $t0, 31, movimentar_tiro_inimigo_checar_nave
	sw $zero, existe_tiro_inimigo
	j movimentar_tiro_inimigo_fim

	movimentar_tiro_inimigo_checar_nave:
	# if acertou a nave: apaga o tiro, toca o som de dano, perde uma vida e redesenha a nave; return
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

tiro_inimigo_acertou_nave:# -> v0 = 1 se o tiro do inimigo esta dentro da nave, senao v0 = 0
	# a nave tem 2 linhas: player_y (x-2 ate x+2) e player_y-1 (x-1 ate x+1)
	li $v0, 0
	lw $t0, tiro_inimigo_x
	lw $t1, tiro_inimigo_y
	lw $t2, player_x
	lw $t3, player_y

	# dx = |tiro_inimigo_x - player_x|
	sub $t4, $t0, $t2
	abs $t4, $t4

	# if tiro_inimigo_y == player_y and dx <= 2: acertou
	bne $t1, $t3, tiro_inimigo_acertou_nave_cima
	ble $t4, 2, tiro_inimigo_acertou_nave_sim
	j tiro_inimigo_acertou_nave_fim

	# if tiro_inimigo_y == player_y-1 and dx <= 1: acertou
	tiro_inimigo_acertou_nave_cima:
	addi $t3, $t3, -1
	bne $t1, $t3, tiro_inimigo_acertou_nave_fim
	bgt $t4, 1, tiro_inimigo_acertou_nave_fim

	tiro_inimigo_acertou_nave_sim:
	li $v0, 1

	tiro_inimigo_acertou_nave_fim:
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

	jal aumentar_dificuldade

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

aumentar_dificuldade:# inimigo_size_increment -= INIMIGO_ACELERACAO (o inimigo fica mais rapido), sem passar de INIMIGO_SIZE_INCREMENT_MIN
	#inimigo_size_increment -= INIMIGO_ACELERACAO
	lw $t0, inimigo_size_increment
	addi $t0, $t0, -INIMIGO_ACELERACAO

	# if inimigo_size_increment < INIMIGO_SIZE_INCREMENT_MIN: inimigo_size_increment = INIMIGO_SIZE_INCREMENT_MIN
	bge $t0, INIMIGO_SIZE_INCREMENT_MIN, aumentar_dificuldade_fim
	li $t0, INIMIGO_SIZE_INCREMENT_MIN

	aumentar_dificuldade_fim:
	sw $t0, inimigo_size_increment
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

movimentar_inimigo:# anda 1 pixel na direcao inimigo_dir a cada inimigo_size_increment voltas; inverte a direcao nas bordas
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

end_program:
	li $v0, 10
	syscall
