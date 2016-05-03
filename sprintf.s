#______________________________________________________________________________________________

sprintf:
	
	addi $sp, $sp, -24
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $sp, 20($sp)

	sw $a2, 32($sp)
	sw $a3, 36($sp)


	add $s0, $a0, $0
	add $s2, $a1, $0
	add $s3, $0, $0
	
	add	$s1, $sp, $0
	addi	$s1, $s1, 32 #beginning of the replacement args ($a2)
	
	lb $s3, 0($s2)
  

loop:
	beq $s3, $0, null				#is it terminating? (NULL in ascii is 0) -> null
	beq $s3, '%', percent		#is it % ? -> percent
	sb $s3, 0($s0)					#add it to the resulting string
	addi $s0, $s0, 1				#increment output pointer
	j nchar							#get next character -> nchar

nchar:
	addi $s2, $s2, 1				#look at the next character in the format string
	lb $s3, 0($s2)					#take that character and make it the current character
	j loop							#go back to the caller

null:
	sb $0, 0($s0)					#add it to resulting string
										#reload saved registers
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $sp, 20($sp)
	addi $sp, $sp, 24 			#restore stack ptr
	jr $ra

percent:
		addi $s2, $s2, 1			#look at the next character in the format string
		lb $s3, 0($s2)				#take that character and make it the current character

		bne $s3, 'b', tod			#is it b?
				lw $a0, 0($s1)

#				li $v0, 4
#				syscall
				jal bin
				addi $s1, $s1, 4
				j nchar
tod:	bne $s3, 'd', tou			#is it d?
				lw $a0, 0($s1)
				addi $s1, $s1, 4
				bgez	$a0, pos
				addi $t0, $0, '-'
				sb $t0, 0($s0)
				addi $s0, $s0, 1
				neg $a0, $a0
pos:			jal dec
				j nchar			
tou:	bne $s3, 'u', tox			#is it u?
				lw $a0, 0($s1)
				addi $s1, $s1, 4
				jal dec
				j nchar	

	#			lw $a0, 0($s1)
	#			addi $s1, $s1, 4
	#			jal uns
	#			j nchar	
tox:	bne $s3, 'x', too			#is it x?
				lw $a0, 0($s1)
				addi $s1, $s1, 4
				jal hex
				j nchar	
too:	bne $s3, 'o', toc			#is it o?

				lw $a0, 0($s1)


#				li $v0, 4
#				syscall

				jal oct
				addi $s1, $s1, 4
				j nchar	
		
toc:	bne $s3, 'c', tos			#is it c?
			lw $t0, 0($s1)			#put arg into a temporary register
			addi $s1, $s1, 4		#increment pointer to next arg
			sb $t0, 0($s0)			#put the char on the output string
			addi	$s0, $s0, 1		#increment pointer for output string
			j nchar

tos:	bne $s3, 's', top			#is it s?
			lw	$t0, 0($s1)			#put arg into a temporary register
			addi	$s1, $s1, 4		#increment pointer to next arg
			lb	$t1, 0($t0)			#load the first byte of the word
		strl:			
			beq	$t1, $0, strd	#if the byte contains '/0' then end
			sb	$t1, 0($s0)			#put the non-terminating char on the output string
			addi	$s0, $s0, 1		#increment pointer for output string
			addi	$t0, $t0, 1		#point to next byte in the word
			lb	$t1, 0($t0)			#get next byte in the word
			j	strl					#loop
		strd:
			j	nchar					#next char in format array

top:	bne $s3, '%', na			#is it %?
		addi $t0, $0, '%'
		sb $t0, 0($s0)
		addi $s0, $s0, 1
		j nchar
na:									
	sb $s3, 0($s0)
	addi $s0, $s0, 1
	j nchar

#This does the number backward (does not use the stack)
#bin:	addi $sp,$sp,-4
#		sw $ra, 0($sp)
#		
#nbin:	beq $a0, $0, endbin
#		remu $t0, $a0, 2
#		divu $a0, $a0, 2
#		addi $t0,$t0,'0'
#		sb $t0, 0($s0)
#		addi $s0, $s0, 1
#		j nbin
#endbin:
#		lw	$ra,0($sp)	# restore return address
#		addi	$sp,$sp, 4	# restore stack
#		jr	$ra		# return	




bin:	addi	$sp,$sp,-8	# get 2 words of stack
	sw	$ra,0($sp)	# store return address

	remu	$t0,$a0,2	# $t0 <- $a0 % 2
	addi	$t0,$t0,'0'	# $t0 += '0'
	divu	$a0,$a0,2	# $a0 /= 2
	beqz	$a0,onedigbin	# if( $a0 != 0 ) { 
	sw	$t0,4($sp)	#   save $t0 on our stack
	jal	bin		#   bin
	lw	$t0,4($sp)	#   restore $t0
	                        # } 
onedigbin:	sb	$t0, 0($s0)			#put the binary digit on the output string
			addi	$s0, $s0, 1		#increment pointer for output string
	lw	$ra,0($sp)	# restore return address
	addi	$sp,$sp, 8	# restore stack
	jr	$ra		# return

oct:	addi	$sp,$sp,-8	# get 2 words of stack
	sw	$ra,0($sp)	# store return address

	remu	$t0,$a0,8	# $t0 <- $a0 % 2
	addi	$t0,$t0,'0'	# $t0 += '0'
	divu	$a0,$a0,8	# $a0 /= 2
	beqz	$a0,onedigo	# if( $a0 != 0 ) { 
	sw	$t0,4($sp)	#   save $t0 on our stack
	jal	oct		#   oct
	lw	$t0,4($sp)	#   restore $t0
	                        # } 
onedigo:	sb	$t0, 0($s0)			#put the binary digit on the output string
			addi	$s0, $s0, 1		#increment pointer for output string
	lw	$ra,0($sp)	# restore return address
	addi	$sp,$sp, 8	# restore stack
	jr	$ra		# return


dec:	addi	$sp,$sp,-8	# get 2 words of stack
	sw	$ra,0($sp)	# store return address
	remu	$t0,$a0,10	# $t0 <- $a0 % 2
	addi	$t0,$t0,'0'	# $t0 += '0'
	divu	$a0,$a0,10	# $a0 /= 2
	beqz	$a0,onedigd	# if( $a0 != 0 ) { 
	sw	$t0,4($sp)	#   save $t0 on our stack
	jal	dec		#   oct
	lw	$t0,4($sp)	#   restore $t0
	                        # } 
onedigd:	sb	$t0, 0($s0)			#put the binary digit on the output string
			addi	$s0, $s0, 1		#increment pointer for output string
	lw	$ra,0($sp)	# restore return address
	addi	$sp,$sp, 8	# restore stack
	jr	$ra		# return


hex:	addi	$sp,$sp,-8	# get 2 words of stack
		sw	$ra,0($sp)	# store return address
		remu	$t0,$a0,16	# $t0 <- $a0 % 2
		ble	$t0,9, nine
		addi	$t0, $t0, 7

nine:	addi	$t0,$t0,'0'	# $t0 += '0'
		divu	$a0,$a0,16	# $a0 /= 2
		beqz	$a0,onedigh	# if( $a0 != 0 ) { 
		sw	$t0,4($sp)	#   save $t0 on our stack
		jal	hex		#   oct
		lw	$t0,4($sp)	#   restore $t0
	                        # } 
onedigh:	sb	$t0, 0($s0)			#put the binary digit on the output string
			addi	$s0, $s0, 1		#increment pointer for output string
	lw	$ra,0($sp)	# restore return address
	addi	$sp,$sp, 8	# restore stack
	jr	$ra		# return


















#oct:	addi	$sp,$sp,-8	# get 2 words of stack
#	sw	$ra,0($sp)	# store return address
#
#	remu	$t0,$a0,8	
#	addi	$t0,$t0,'0'	
#	divu	$a0,$a0,8	
#	beqz	$a0,onedigoct	 
#	sw	$t0,4($sp)	
#	jal	oct		
#	lw	$t0,4($sp)	
#	                
#onedigoct:	sb	$t1, 0($s0)			#put the octal digit on the output string
#			addi	$s0, $s0, 1		#increment pointer for output string
#	lw	$ra,0($sp)	# restore return address
#	addi	$sp,$sp, 8	# restore stack
#	jr	$ra		# return










#hex:	addi	$sp,$sp,-8	# get 2 words of stack
#	sw	$ra,0($sp)	# store return address
#
#	remu	$t0,$a0,16	
#	addi	$t0,$t0,'0'	
#	divu	$a0,$a0,16	
#	beqz	$a0,onedighex	 
#	sw	$t0,4($sp)	
#	jal	hex		
#	lw	$t0,4($sp)	
#	                
#onedighex:	sb	$t1, 0($s0)			#put the hex digit on the output string
#			addi	$s0, $s0, 1		#increment pointer for output string
#	lw	$ra,0($sp)	# restore return address
#	addi	$sp,$sp, 8	# restore stack
#	jr	$ra		# return
#
#dec:	addi	$sp,$sp,-8	# get 2 words of stack
#	sw	$ra,0($sp)	# store return address
#
#	remu	$t0,$a0,10	
#	addi	$t0,$t0,'0'	
#	divu	$a0,$a0,10	
#	beqz	$a0,onedigdec	 
#	sw	$t0,4($sp)	
#	jal	dec		
#	lw	$t0,4($sp)	
#	                
#onedigdec:	sb	$t1, 0($s0)			#put the decimal digit on the output string
#			addi	$s0, $s0, 1		#increment pointer for output string
#	lw	$ra,0($sp)	# restore return address
#	addi	$sp,$sp, 8	# restore stack
#	jr	$ra		# return

uns:	addi	$sp,$sp,-8	# get 2 words of stack
	sw	$ra,0($sp)	# store return address

	remu	$t0,$a0,10	
	addi	$t0,$t0,'0'	
	divu	$a0,$a0,10	
	beqz	$a0,onediguns	 
	sw	$t0,4($sp)	
	jal	uns		
	lw	$t0,4($sp)	
	                
onediguns:	sb	$t1, 0($s0)			#put the unsigned digit on the output string
			addi	$s0, $s0, 1		#increment pointer for output string
	lw	$ra,0($sp)	# restore return address
	addi	$sp,$sp, 8	# restore stack
	jr	$ra		# return

#___________________________________________________________________________________________

