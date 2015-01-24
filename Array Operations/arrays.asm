#Yuen Hsi Chang

#size is $a0
li $a0, 0
#let a1 be 4
li $a1, 4
#let the starting address be $s4
li $s4, 0x10010000

#create an arbitraty array to test first
li $t1, 100
sw $t1, 0($s4)
addi $a0, $a0, 1
li $t1, 50
sw $t1, 4($s4)
addi $a0, $a0, 1
li $t1, 25
sw $t1, 8($s4)
addi $a0, $a0, 1

INSERT: 
	#place the value to add in register $s2
	#place the index to add in register $s3
	li $s2, 99
	li $s3, 2
		#multiply $s3 by 4 to get the appropriate offset
		mult $s3, $a1
		mflo $s3
		add $t7, $s3, 0x10010000	
		#check whether the cell to add to is already occupied
		lw $t6, 0($t7)	
		bne $t6, 0, occupied
		sw $s2, 0($t7)
		addi $a0, $a0, 1
		j target
	#if the cell is already occupied, add the value to the end of the array
	occupied: 
		mult $a0, $a1
		mflo $t7
		add $t7, $t7, 0x10010000
		sw $s2, 0($t7)
		addi $a0, $a0, 1
		target: 

DELETE: 
#specify the item to delete in $a2
li $a2, 50
#create another pointer to the memory locations
li $t2, 0x10010000
		#locate the memory address of the value to be deleted
		increment:
			lw $t5, 0($t2)
			beq $a2, $t5, found 
			mult $a0, $a1
			mflo $t3
			add $t3, $t3, $s4 
			slt $t4, $t2, $t3
			beq $t4 , 0, notFound
			addi $t2, $t2, 4
			j increment
		#if the value to be deleted does not precede the first 0 in the array
		notFound:
			#register $s0 defaults to -1 if the delete method was successfully carried out
			li $s0, -1
			j  end
		#when the memory address of the item to delete is located
		found:
			#register $s0 defaults to 1 if the delete method was successfully carried out
			li $s0, 1
			#register $s1 specifies the value of the data that was deleted
			lw $s1, 0($t2)
		#removes the specified item, and shifts all succeeding cells backwards by one byte
		shift:
		        lw $t7, 4($t2)
			sw $t7, 0($t2)
			add $t2,$t2,4
			beq $t7, 0, done
			j shift
			done: 
				add $a0, $a0, -1
				j end
		end: 

#retrieves the data of the cell in the $s5 index of the array
GET:
	li $s5, 2
	mflo $s5
		add $s5, $s5, 0x10010000
		#the data in the specified cell gets stored in the #s6 register
		lw $s6, 0($s5)

ReimplementedGET: 

	#Put a -1 at the end of the array as this is one of the requirements to part 2
	li $t1, -1
	sw $t1, 12($s4)
		
	li $s5, 2
	mult $s5, $a1
	mflo $s5
	add $s5, $s5, 0x10010000
	li $s7,0x10010000
	#check whether the value lies within the bounds of the array, which ends with a -1
	check:
	lw $s6,0($s7)
	beq $s6,-1,outofbounds
	beq $s7,$s5,inbounds
	add $s7,$s7,4
	j check
	#if the array is inbounds, the data in the specified cell gets stored in the #s6 register
	inbounds:
		lw $s6, 0($s5)
		j finish
	#if the array is out of bounds, the #s6 register	 gets a value of -1
	outofbounds: li $s6,-1
				j finish
	finish:
	
Length: 
	li $s7,0x10010000
	#check whether the value lies within the bounds of the array, which ends with a -1
	status:
	lw $s6,0($s7)
	beq $s6,-1,size
	add $s7,$s7,4
	j status
	size: sub $s7,$s7,0x10010000
		div $s7, $a1
		mflo $s7
		