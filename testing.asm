# Title: Bin Packing Solver
# Authors:
#	Raghad Jamhour - 122
#	Maysam Habbash - 1220075

################################## DATA SECTION ###########################################
.data
  # messages to print
  start_msg: .asciiz "----- Bin Packing Solver -----\n"
  menu: .asciiz "\n\nChoose an operation:\n 1. Enter file name to upload.\n 2. Choose Heuristic: FF or BF.\n 3. Enter q to quit the program.\n"
  prompt_fileName_msg: .asciiz "\nEnter file name:\n"
  invalid_option_msg: .asciiz "\nNo Such Option!\n"
  invalid_file_msg: .asciiz "\nInvalid file name!\n"
  invalid_input_msg: .asciiz "\nInvalid file input!\n"
  success_fileOpen_msg: .asciiz "File opened successfully.\n"
  FForBF_msg: .asciiz "\nEnter 'FF' for First-Fit or 'BF' for Best Fit:\n"
  invalid_algo_msg: .asciiz "\nInvalid Algorithm!\n"
  ff_msg: .asciiz "\nFF chosen\n"
  empty_msg: .asciiz "\nArray is empty!\n"
  item: .asciiz "\nitem: "
  bin: .asciiz ", bin: "
  newLine: .asciiz "\n"
  space:  .asciiz " "
  
  # variables to use
  fileName: .space 100
  algorithm: .space 3
  
  # buffer for reading lines in file
  line_buffer: .space 100
  word_buffer: .space 50
  
  # float comparison data
  zero_float: .float 0.0
  one_float: .float 1.0
  two_float: .float 2.0
  error: .float 0.01
  # float conversion data
  ten: .float 10.0
  one: .float 1.0
  
  # arrays for storing items and bins
  items_array: .space 100
  items_free_index: .word 0
  bins_array: .space 100
  bins_count: .word 25

################################## CODE SECTION ###########################################
.text
.globl main
  
## Main Function to run the program
main:
  li $v0, 4
  la $a0, start_msg
  syscall
  
  loop:
    # print menu until user quits the program
    li $v0, 4
    la $a0, menu
    syscall

    # read user's option (as a character)
    li $v0, 12
    syscall
    move $t0, $v0

    # switch between user options
    beq $t0, '1', read_file
    beq $t0, '2', FForBF
    beq $t0, 'q', quit
    beq $t0, 'Q', quit
    j invalid_option	# handle invalid options

## Function to notify user of invalid option
invalid_option:
  li $v0, 4
  la $a0, invalid_option_msg
  syscall
  j loop

## Function to handle data upload from file
read_file:
  li $v0, 4
  la $a0, prompt_fileName_msg
  syscall

  # read file name
  la $a0, fileName
  li $a1, 100
  li $v0, 8
  syscall

  # clean input
  la $s1, fileName
  jal remove_newline
  
  # open file for upload
  li $v0, 13
  la $a0, fileName
  li $a1, 0
  li $a2, 0
  syscall
  move $s0, $v0

  # make sure file could be open
  bltz $v0, invalid_file

  li $v0, 4
  la $a0, success_fileOpen_msg
  syscall

fileReader_loop:
  li $v0, 14
  move $a0, $s0
  la $a1, line_buffer
  li $a2, 100
  syscall

  blez $v0, close_file

  la $t0, line_buffer
  j parse_words

parse_words:

  lb $t1, 0($t0)
  beqz $t1, fileReader_loop

skip_spaces:
  lb $t1, 0($t0)
  beqz $t1, fileReader_loop
  li $t2, 32
  bne $t1, $t2, word_start
  addi $t0, $t0, 1
  j skip_spaces

word_start:
  la $a1, word_buffer
  move $t3, $a1

copy_word:
  lb $t1, 0($t0)
  beqz $t1, finish_word
  li $t2, 32
  beq $t1, $t2, finish_word
  sb $t1, 0($t3)
  addi $t0, $t0, 1
  addi $t3, $t3, 1
  j copy_word

finish_word:

  sb $zero, 0($t3)
  move $a0, $a1
  jal string_to_float
  j parse_words


string_to_float:
  li $t1, 0
  li $t2, 0
  la $t7, zero_float
  l.s $f2, 0($t7)
  la $t7, one_float
  l.s $f4, 0($t7)

loopValid:
  lb $t7, 0($a0)
  beq $t7, 0, finish
  beq $t7, 46, set_decimal

  li $t5, 48
  sub $t6, $t7, $t5
  mtc1 $t6, $f6
  cvt.s.w $f6, $f6

  beq $t2, 0, before_dot

  l.s $f7, ten
  mul.s $f4, $f4, $f7
  div.s $f6, $f6, $f4
  add.s $f2, $f2, $f6
  j next_char

before_dot:
  mul $t1, $t1, 10
  add $t1, $t1, $t6

next_char:
  addi $a0, $a0, 1
  j loopValid

set_decimal:
  li $t2, 1
  addi $a0, $a0, 1
  j loopValid

finish:
  mtc1 $t1, $f1
  cvt.s.w $f1, $f1
  add.s $f12, $f1, $f2
  
  
  la $t7, zero_float
  l.s $f1, 0($t7)
  c.lt.s $f12, $f1
  bc1t invalid_input

  la $t7, one_float
  l.s $f1, 0($t7)
  c.le.s $f1, $f12
  bc1t invalid_input
  
 # li $v0 , 2
 # syscall
  
  # Save return address before calling
  addi $sp, $sp, -4
  sw $ra, 0($sp)
  # item is valid
  
  # add to the array of valid items
  jal add_item_to_array
  
  # Restore return address
  lw $ra, 0($sp)
  addi $sp, $sp, 4

  jr $ra

## Function to add valid items into array
add_item_to_array:
  # get address of next available cell in array (index)
  la $t8, items_array
  la $t4, items_free_index
  lw $t9, 0($t4)	# t4 is now address of free index
  
  mul $t9, $t9, 4 #move forward 4 bytes for single precision floats
  add $t8, $t8, $t9 # actual address
  s.s $f12, 0($t8)
  
  # update free index
  lw $t9, 0($t4)	# reload index
  addi $t9, $t9, 1 # increment
  sw $t9, 0($t4)
  
  # li $v0, 2          # syscall code for print float
  #syscall
  
  jr $ra
  
# Function to print an array of floating-point numbers
print_float_array:
    # Load the base address of the array (starting address of the array)
    la $t5, items_array       # $t0 = base address of the array
    la $t6, items_free_index  # $t1 = address of the index tracker
    lw $t7, 0($t6)            # $t2 = number of elements in the array

    # Loop to print each element in the array
    loop_print:
        # Check if we have printed all elements
        beq $t7, $zero, done_printing

        # Load the current element from the array into $f12 (for printing)
        l.s $f12, 0($t5)       # Load the floating-point number at $t0 into $f12

        # Print the floating-point number
        li $v0, 2              # syscall code for print float
        syscall

        # Move to the next element in the array (increment by 4 bytes for single precision float)
        addi $t5, $t5, 4       # Increment address of the next float in the array
        sub $t7, $t7, 1        # Decrement the counter of remaining elements
        
        li $v0, 4
        la $a0, space
        syscall
        
        j loop_print           # Continue the loop

    done_printing:
        jr $ra                 # Return from function
  

## Function to specify First-Fit or Best-Fit algorithm
FForBF:
  li $v0, 4
  la $a0, FForBF_msg
  syscall

  # read choice of algorithm
  la $a0, algorithm
  li $a1, 3 # two-characters sized input
  li $v0, 8
  syscall
  
  la $s1, algorithm
  jal remove_newline
  
  lb $s2, algorithm
  # switch between algorithms
  beq $s2, 'F', first_fit
  beq $s2, 'f', first_fit
  beq $s2, 'B', best_fit
  beq $s2, 'b', best_fit
  j invalid_algorithm

## Function to run First-Fit algorithm
first_fit:
  #### Queen Raghad <3
	# ...
  j loop

############################################################################################################
############################################################################################################
## Function to run Best-Fit algorithm
best_fit:
  # initialize bins to capacity of 1
  jal initialize_bins
  
  la $t0, items_array
  la $t1, items_free_index
  lw $t2, 0($t1) # t2 = number of items in array

  beq $t2, $zero, empty_array # make sure array is not empty
  
  # iterate through items to put in bins
  items_loop:
    beq $t2, $zero, stop_items_loop # all items gone through
    l.s $f0, 0($t0) # current item in f0
    
    li $v0, 4
    la $a0, item
    syscall
    mov.s $f12, $f0
    li $v0, 2
    syscall
    
    la $t3, two_float
    l.s $f1, 0($t3) # f1 is min_capacity
    li $t4, -1 # t4 is min_index
    move $t8, $zero # t8 is current index in bins array
    
    la $t5, bins_array
    la $t6, bins_count
    lw $t7, 0($t6)
    # choose the best fit bin
    bins_loop:
      ble $t7, $zero, stop_bins_loop
      l.s $f2, 0($t5) # current bin in f2
      
      c.lt.s $f2, $f0
      bc1t check_error # item does not fit in bin
      check_error:
      sub.s $f4, $f0, $f2
      l.s $f5, error
      c.lt.s $f5, $f4
      bc1t continue
      
      # items fits in bin
      c.le.s $f1, $f2
      bc1t skip
      mov.s $f1, $f2 # new min_capacity
      move $t4, $t8 # new min_index
      
      continue:
      skip:
      addi $t5, $t5, 4 # move to the next bin
      addi $t8, $t8, 1 # update index
      subi $t7, $t7, 1 # remaining bins
      j bins_loop
    
    stop_bins_loop:
    
    li $v0, 4
    la $a0, bin
    syscall
    move $a0, $t4
    li $v0, 1
    syscall
    
    
    # put item in best fitted bin
    la $t5, bins_array # reload address
    mul $t4, $t4, 4
    add $t5, $t5, $t4 # address of best-fit bin
    sub.s $f3, $f1, $f0 # place item in bin
    s.s $f3, 0($t5) # update bin capacity
    
    addi $t0, $t0, 4 # move to the next item
    subi $t2, $t2, 1 # remaining items
    
    
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    jal print_bins_array #print the item array
  
    lw $ra, 0($sp)
    addi $sp, $sp, 4

    li $v0, 4
    la $a0, newLine
    syscall
    
    j items_loop

  stop_items_loop: # all items are placed into bins
  #jal print_bins_array
  j loop

## Function to initialize bins to capacity of 1
initialize_bins:
  la $t0, bins_array
  la $t1, bins_count
  lw $t5, 0($t1)
  l.s $f0, one_float
  
  bins_init_loop:
    ble $t5, $zero, stop_init
    s.s $f0, 0($t0)
    addi $t0, $t0, 4
    subi $t5, $t5, 1
    j bins_init_loop
    
  stop_init:
  jr $ra

print_bins_array:
	li $v0, 4
        la $a0, newLine
        syscall
    # Load the base address of the array (starting address of the array)
    la $t5, bins_array       # $t0 = base address of the array
    la $t6, bins_count  # $t1 = address of the index tracker
    lw $t7, 0($t6)            # $t2 = number of elements in the array

    # Loop to print each element in the array
    loop_print_bins:
        # Check if we have printed all elements
        beq $t7, $zero, done_printing_bins

        # Load the current element from the array into $f12 (for printing)
        l.s $f12, 0($t5)       # Load the floating-point number at $t0 into $f12
        l.s $f11, zero_float
        c.le.s $f11, $f12
        bc1t print
        mov.s $f12, $f11

        print:
        # Print the floating-point number
        li $v0, 2              # syscall code for print float
        syscall

        li $v0, 4
        la $a0, space
        syscall
        
        # Move to the next element in the array (increment by 4 bytes for single precision float)
        addi $t5, $t5, 4       # Increment address of the next float in the array
        sub $t7, $t7, 1        # Decrement the counter of remaining elements

        j loop_print_bins          # Continue the loop

    done_printing_bins:
        jr $ra                 # Return from function
  
## Function to notify user of empty arrays
empty_array:
  li $v0, 4
  la $a0, empty_msg
  syscall
  j loop
  
## Function to remove newline from string
remove_newline:
  clean_string_loop:
    lb $t1, 0($s1) # take one char to examine
    beq $t1, 10, replace_newline # check if char is new line
    beqz $t1, string_cleaned # check if char is null termination
    
    addi $s1, $s1, 1 # move to the next char in string
    j clean_string_loop

  replace_newline:
    sb $zero, 0($s1)

  string_cleaned: # end of string reached
  jr $ra
  
## Function to notify user if invalid file paths
invalid_file:
  li $v0, 4
  la $a0, invalid_file_msg
  syscall
  j loop

## Function to notify user of invalid input in file
invalid_input:
  li $v0, 4
  la $a0, invalid_input_msg
  syscall
  j loop

## Function to notify user of invalid algorihtm
invalid_algorithm:
  li $v0, 4
  la $a0, invalid_algo_msg
  syscall
  j loop

## Function to close the file after upload
close_file:
  move $a0, $s0
  li $v0, 16
  syscall
  j loop

quit:
  li $v0, 10
  syscall
