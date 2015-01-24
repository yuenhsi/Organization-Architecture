#Yuen Hsi Chang

#let $s2 reference the array's initial address
li $s2, 0x10010000
#let $s0 be the length of the array
li $s0, 0

#create and fill an arbitraty array to test 
li $t1, 100
sw $t1, 0($s2)
li $t1, 50
sw $t1, 4($s2)
li $t1, 25
sw $t1, 8($s2)
li $t1, 20
sw $t1, 12($s2)
li $t1, -1
sw $t1, 16($s2)

#by convention, move the contents of register $s2 to register $a0
move $a0,$s2 

#create an initial return address that references back to the procedure
jal lenr
#the length is moved back to register #s0, where it should belong
add $s0,$t0,$zero	
j Done
	
lenr:
	#move the stack back and store the initial return address as the first element
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	#check whether the current index of the array references the endpoint
	lw $t2, 0($a0)
	beq $t2, -1, base
	#if the end of the array is not yet reached, move to a succeeding index and repeat
	#every other time, the return address would jump to the following line rather than prior the procedure call
	addi $a0, $a0, 4
	jal lenr
	#when the end of the array is reached
	 base:
	 	#increment the length
	 	addi $t0, $t0,1
	 	#ignore one of the components since one of the elements is a -1, which doesn't count towards the final count
	 	#jump to the specified return addresses - and this procedure keeps referencing the base case, till the endpoint is reached
	 	#at the endpoint, the initial return address prior the procedure call is referenced
		lw $ra, 4($sp)
		addi $sp,$sp,4
		jr $ra
		
	Done:
