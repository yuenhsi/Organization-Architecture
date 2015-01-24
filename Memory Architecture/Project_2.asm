# Let $t0 store the location of data in RAM
# Let $t1 be the wanted data

# $t5 and $t6 used to locate data in L1 & L2 caches
# Let $s0 be a "no-hit" counter; or tries that require loading from RAM
# Let $s1 be the hit counter for L1 
# Let $s2 be the hit counter for L2 

# Let $s3 be the LRU  data address (L1 cache)
# Let $s4 be the LRU tag address (L1 cache)
# Let $s5 be the LRU tag data
# Let $s6 be the L2 tag data
# Let $s7 be the L2 tag address


LOAD:
	#Load data into RAM 
	li $t9, 0x100100a0
	li $t7, 5
	li $t8, 0x10010200
	loadLoop : 
		sw $t7, 0($t9)
		addi $t9, $t9, 4
	        addi $t7, $t7, 5
	        bne $t8, $t9, loadLoop 

MAIN_2:
	# $t4 and $t5 is used, because this is part of the preload architecture and not part of our program. 
	# due to inclusion, all items that are exist in the L1 cache exist in the L2 cache as well. 
	# $t1 refers to the memory address, $t2 refers to the L1 cache address,  $t3 refers to the L2 cache address. 
	# only 4 data items are loaded in cache, so $t4 keeps count and the loop iterates 4 times. 
	li $t1, 0x100100a0  
	li $t2, 0x10010000
	li $t4, 0
	preFetch:
	beq $t4, 4, donePreFetchStartProgram # when 4 data items are loaded into cache
	lw $t0, 0($t1)		# retrieve the data from memory
	srl $t5, $t1, 2		# compute the L1 tag data
	sw $t5, 0($t2)		# store the L1 tag data in the L1 cache
	addi $t2, $t2, 4		
	sw $t0, 0($t2)		# store the acutal data in the L1 cache
	
	srl $t5, $t1, 6 		# compute the L2 tag data
	srl $t3, $t1, 3
	addi $t3, $t3, -0x0000000F	
	sll $t3, $t3, 3		# compute the L2 tag address
	sw $t5, 0($t3)		# store the L2 tag data in the L2 cache
	addi $t3, $t3, 4	
	sw $t0, 0($t3)		# store the actual data in the L2 cache
	addi $t1, $t1, 4		# jump to the succeeding memory address
	addi $t2, $t2, 4		# jump to the succeeding L1 cache address
	addi $t4, $t4, 1		# increment the counter by one
	j preFetch
	
	donePreFetchStartProgram:
	li $t0, 0x100100c0	# location of data in RAM
	li $t1, 5			# the wanted data is 5
	li $t2, 0
	li $t3, 3			# the search for the wanted data (5) iterates 3 times
	Loop:
		jal L1_Lookup
		addi $t2, $t2, 1
		bne $t2, $t3, Loop
		j END
	# without prefetching, the hitrate of the data in cache is 66%, as could be seen by the value of $s0 (no-hit-counter) being 1 and $s1 being 2. 
	# with prefetching, the hitrate of the data in cache is 100%, as could be seen by the value of $s0 being 0 and $s1 being 3. 
	# memory performance improvement: 33%. 

L1_Lookup:
	# Let $s3 refer to the least recently used location in the L1 cache
	li $s3, 0x10010004                   	     #Put LRU in $s3
	li $t6, 0x10010004                           #Set $t6 as the first address of L1 cache 
	lw $t5, 0($t6)                               #Set $t5 as the data stored at address in $t6 

searchUpL1:                                          #Search L1 Cache for wanted data 
	beq $t6, 0x10010024, L2_Lookup               #Once you look through all the data in L1 and can't find wanted one, branch to L2_lookup 
	beq $t5, $t1, foundInL1		             #if data is found, branch to foundInL1
	addi $t6, $t6, 8                             #increment address by 8 inorder to look through entire cache 
	j searchUpL1
	
foundInL1: 
	addi $s1, $s1, 1                             #Increment L1 hit counter by 1 
	beq $t6, $s3, change_temp                    #branch to change_temp to update LRU
	j DONE                                      
	
change_temp:
	add $s3,$s3, 8                               #update LRU to next data address (just so its not the most recently used)
	beq $s3, 0x10010024, tooHigh                 #if succeeding address belongs in the L2 cache, branch to "tooHigh"
	tooHigh:
		li $s3, 0x10010004                   #set it to the first address of L1 (or, anything but the third entry, which is the most recently used entry)
	j DONE
	
L2_Lookup:	                                                                                      
	li $t6, 0x10010024                           #Set $t6 as the first address of L2 cache 
	lw $t5, 0($t6)                               #Set $t5 as the data stored at address in $t6 

searchUpL2:                                          #Search L2 Cache for wanted data 
	beq $t6, 0x100100a4, notInL2              #Once you look through all the data in L1 and can't find wanted one, branch to ADD_L2
	beq $t5, $t1, foundInL2                      #If data is found, branch to foundInL2 
	addi $t6, $t6, 8                             #increment address by 8 in order to look through entire cache 
	j searchUpL2                                 #loop 
	
foundInL2:			
        addi $s2,$s2, 1                              #increment hit counter 
	sw $t1 0($s3)					#put data in the LRU location in the L1 cache
	addi $s4, $s3, -4				#find tag location from LRU by subtracting the address by 4, and store it in $s4
	srl $s5, $t0, 2					#store the data in the L1 cache's tag in $s5

notInL2:
	#increment the no-hit counter
	addi $s0, $s0, 1
	#the data is in RAM, so place it in the L1 cache but don't increment the hit counter
	sw $t1 0($s3)					#put data in the LRU location in the L1 cache
	addi $s4, $s3, -4				#find tag location from LRU by subtracting the address by 4, and store it in $s4
	srl $s5, $t0, 2					#store the data in the L1 cache's tag in $s5
	sw $s5, 0($s4)
	#the data is in RAM, so place it in the L2 cache
	srl $s6, $t0, 6					#compute the L2 tag data with the known RAM address, and sotre it in register $s6
	srl $s7, $t0, 3					#compute the L2 tag address with the known RAM address, and store it in register $s7
	addi $s7, $s7, -0x0000000F
	sll $s7, $s7, 3
	sw $s6, 0($s7)					#store the L2 tag data into the L2 tag address
	sw $t1, 4($s7)					#store the data into the L2 data address, which is the tag address + 4
	j DONE
	
DONE: 
	jr $ra
	
END:
