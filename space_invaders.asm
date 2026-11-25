.data
	.eqv BRANCO 0x00FFFFFF
	.eqv AZUL 0x000000FF
	.eqv VERM 0x00FF0000
	.eqv PRETO 0x00000000
	.eqv display 0x10008000
	.eqv key_pressed 0xFFFF0000
	.eqv key_code 0xFFFF0004
	.eqv DISPLAY_LENGTH 8192
	.eqv TIRO_Y0 26
	.eqv SIZE_INCREMENT 20
	.eqv INIMIGO_SIZE_INCREMENT 20
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
	inimigo_incremented_position: 0
	msg_vitoria: .asciiz "Voce venceu! 20 pontos!"
	msg_derrota: .asciiz "Game over! Acabaram as vidas."


.text
main:    #MAIN
	
	jal limpar_tela
	li $a0, AZUL
	jal desenhar_player
	main_loop:
		
		# TODO movimentar inimigos
		
		# TODO desenhar score
		
		# TODO desenhar vidas
	
		jal movimentar_tiro
		
		jal movimentar_player

		jal checar_fim_de_jogo

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
		bge $s0, 61, movimentar_player_fim
		
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
	
atirar: # cria um tiro caso nao exista
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
	
	atirar_fim:
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
	

checar_fim_de_jogo: # termina o jogo com score >= 20 (vitoria) ou vidas <= 0 (derrota)
	lw $t0, score
	bge $t0, 20, vitoria
	lw $t0, vidas
	blez $t0, derrota
	jr $ra
	vitoria:
		la $a0, msg_vitoria
		j mostrar_msg_e_sair
	derrota:
		la $a0, msg_derrota
	mostrar_msg_e_sair:
		li $a1, 1  # tipo da janela: informacao
		li $v0, 55 # janela de mensagem
		syscall
		j end_program

sleep1:
	li $v0, 32
	li $a0, 1
	syscall
	jr $ra

end_program:
	li $v0, 10
	syscall
