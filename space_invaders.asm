.data
	.eqv BRANCO 0x00FFFFFF
	.eqv AZUL 0x000000FF
	.eqv VERM 0x00FF0000
	.eqv PRETO 0x00000000
	.eqv ROSA 0x00FF69B4
	.eqv HUD_COLOR 0x00FFFFFF
	.eqv display 0x10008000
	.eqv key_pressed 0xFFFF0000
	.eqv key_code 0xFFFF0004
	.eqv DISPLAY_LENGTH 8192
	.eqv TIRO_Y0 26
	.eqv SIZE_INCREMENT 20
	.eqv INIMIGO_SIZE_INCREMENT 80
	.eqv PLAYER_MAX_X 51
	.eqv SCORE_X 60 # x do digito das unidades (a dezena fica 4 colunas a esquerda, em x=56)
	.eqv SCORE_Y 4  # y da linha de baixo dos digitos (ocupam as linhas 0 a 4, topo da tela)
	player_x: .word 32
	player_y: .word 28
	vidas: .word 5
	score: .word 0
	existe_tiro: .word 0
	tiro_x: .word 0
	tiro_y: .word 0
	tiro_incremented_position: .word 0
	inimigo_x: .word 32
	inimigo_y: .word 6
	inimigo_dir: .word 1
	inimigo_incremented_position: .word 0
	

.text
main:    #MAIN
	
	jal limpar_tela
	li $a0, AZUL
	jal desenhar_player
	main_loop:
		
		jal movimentar_inimigo
		
		# TODO desenhar score
		
		# TODO desenhar vidas
		
		jal desenhar_hud
	
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

desenhar_coracao:# (a0, a1, a2) = (x, y, cor) -> desenha um coracao 5x4 com canto superior esquerdo em (x, y)
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	#linha 0: colunas 1 e 3
	#x+1 y
	addi $a0, $a0, 1
	jal desenhar_pixel

	#x+3 y
	addi $a0, $a0, 2
	jal desenhar_pixel

	#linha 1: colunas 0 a 4
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

	#linha 2: colunas 1 a 3
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

	#linha 3: coluna 2
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

som_tiro: # toca o som do disparo (syscall 31 = MIDI assincrono, nao trava o jogo)
	li $a0, 80   # nota (tom agudo)
	li $a1, 150  # duracao em ms
	li $a2, 127  # instrumento: Gunshot
	li $a3, 100  # volume (0-127)
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
	bgez $s0, movimentar_tiro_desenhar
	jal deletar_tiro
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
	
	
movimentar_inimigo:
	jr $ra
	
desenhar_hud:
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
