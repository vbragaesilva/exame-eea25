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
	player_x: .word 32
	player_y: .word 28
	vidas: .word 5
	existe_tiro: .word 0
	tiro_x: .word 0
	tiro_y: .word 0
	tiro_incremented_position: .word 0
	

.text
main:    #MAIN
	
	jal limpar_tela
	li $a0, AZUL
	jal desenhar_player
	main_loop:
		
		#apagar inimigos
		#movimentar inimigos
		#desenhar_inimigos
		
		jal movimentar_tiro
		
		jal movimentar_player
		
		
		jal sleep1
		j main_loop
	
	j end_program

calcular_index:#(x,y)
	move $t0, $a1
	sll $t0, $t0, 8 # 4(y * 64) 
	sll $t1, $a0, 2 # 4x
	add $t0, $t0, $t1 
	move $v0, $t0 
	jr $ra
	
desenhar_pixel:#(x,y,cor)
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	jal calcular_index
	sw $a2, display($v0)
	
	
	
	lw $ra, 0($sp)
	addi, $sp, $sp, 4
	jr $ra
	
desenhar_player:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	move $a2, $a0
	lw $a0, player_x
	lw $a1, player_y
	#li $a2, AZUL
	jal desenhar_pixel
	addi $a0, $a0, 1
	jal desenhar_pixel
	addi $a0, $a0, -2
	jal desenhar_pixel
	addi $a1, $a1, -1
	jal desenhar_pixel
	addi $a0, $a0, 1
	jal desenhar_pixel
	addi $a0, $a0, 1
	jal desenhar_pixel
	addi $a1, $a1, 1
	addi $a0, $a0, 1
	jal desenhar_pixel
	addi $a0, $a0, -4
	jal desenhar_pixel

	lw $ra, 0($sp)
	addi, $sp, $sp, 4
	jr $ra
	
movimentar_player:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t0, key_pressed
	andi $t0, $t0, 1
	beqz $t0, movimentar_player_fim
	lw $t0, key_code
	beq $t0, 44, movimentar_player_esquerda
	beq $t0, 46, movimentar_player_direita
	beq $t0, 32, movimentar_player_atirar
	movimentar_player_esquerda:
		lw $t7, player_x
		ble, $t7, 2, movimentar_player_fim
		li $a0, PRETO
		jal desenhar_player
		addi $t8, $t7, -1
		sw $t8, player_x
		j movimentar_player_redesenhar
	movimentar_player_direita:
		lw $t7, player_x
		bge $t7, 61, movimentar_player_fim
		li $a0, PRETO
		jal desenhar_player
		addi $t8, $t7, 1
		sw $t8, player_x
		j movimentar_player_redesenhar
	movimentar_player_atirar:
		jal atirar
		j movimentar_player_fim
		
	movimentar_player_redesenhar:
		li $a0, AZUL
		jal desenhar_player
	movimentar_player_fim:
	
	lw $ra, 0($sp)
	addi, $sp, $sp, 4
	jr $ra
	
atirar:
	lw $t0, existe_tiro
	beqz $t0, atirar_criar_tiro
	j atirar_fim
	atirar_criar_tiro:
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
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t0, tiro_incremented_position
	addi $t0, $t0, 1
	sw $t0, tiro_incremented_position
	li $t1, SIZE_INCREMENT
	div $t0, $t1
	mflo $t2
	beqz $t2, movimentar_tiro_fim
	
	li $t0, 0
	sw $t0, tiro_incremented_position
	
	li $a0, PRETO
	jal desenhar_tiro
	
	lw $t0, tiro_y
	addi $t0, $t0, -1
	sw $t0, tiro_y
	
	li $a0, BRANCO
	jal desenhar_tiro
	
	bgez $t0, movimentar_tiro_fim
	
	jal deletar_tiro
	
	movimentar_tiro_fim:
	lw $ra, 0($sp)
	addi, $sp, $sp, 4
	jr $ra
	
deletar_tiro:
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
	

sleep1:
	li $v0, 32
	li $a0, 1
	syscall
	jr $ra

end_program:
	li $v0, 10
	syscall
