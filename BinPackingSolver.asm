# Title: Bin Packing Solver
# Authors:
#	Raghad Jamhour - 1220212
#	Maysam Habbash - 1220075

################################## DATA SECTION ###########################################
.data
  # messages to print
  start_msg: .asciiz "----- Bin Packing Solver -----\n"
  menu: .asciiz "\n\nChoose an operation:\n 1. Enter file name to upload.\n 2. Choose Heuristic: FF or BF.\n 3. Enter q to quit the program.\n"
  prompt_fileName_msg: .asciiz "\nEnter file name:\n"
  output_file: .asciiz "C:\\Users\\HP\\Documents\\GitHub\\ENCS4370-Computer-Architecture\\output.txt"
  invalid_option_msg: .asciiz "\nNo Such Option!\n"
  invalid_file_msg: .asciiz "\nInvalid file name!\n"
  invalid_input_msg: .asciiz "\nInvalid file input!\n"
  success_fileOpen_msg: .asciiz "File opened successfully.\n"
  FForBF_msg: .asciiz "\nEnter 'FF' for First-Fit or 'BF' for Best Fit:\n"
  invalid_algo_msg: .asciiz "\nInvalid Algorithm!\n"
  ff_msg: .asciiz "First-Fit Algorithm:"
  bf_msg: .asciiz "Best-Fit Algorithm:"
  empty_msg: .asciiz "\nArray is empty!\n"
  item_str: .asciiz "\nItem "
  bin_str:  .asciiz " -> Bin "
  total_bins_str: .asciiz "\n\nTotal Bins Used: "
  newLine: .asciiz "\n"
  space:  .asciiz " "
  
  # variables to use
  fileName: .space 100
  algorithm: .space 3
  
  # buffer for reading and writing to file
  line_buffer: .space 2000
  word_buffer: .space 50
  output_buffer: .space 1000
  output_index: .word 0
  
  # float comparison data
  zero_float: .float 0.0
  one_float: .float 1.0
  two_float: .float 2.0
  error: .float 0.01
  # float conversion data
  ten: .float 10.0
  one: .float 1.0
  
  # arrays for storing items and bins
  items_array: .space 500
  items_free_index: .word 0
  bins_array: .space 100
  bins_count: .word 1
  bins_free_index: .word 0

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
  
  # Save return address before call
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
  lw $t9, 0($t4)	# t4 is address of free index
  
  mul $t9, $t9, 4
  add $t8, $t8, $t9 # actual address
  s.s $f12, 0($t8)
  
  # update free index
  lw $t9, 0($t4)	# reload index
  addi $t9, $t9, 1 # increment
  sw $t9, 0($t4)
  
  jr $ra
  
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
  # open output file
  li $v0, 13
  la $a0, output_file
  li $a1, 1               
  syscall
  move $s1, $v0 # $s1 is file descriptors
  # write to file
  li $v0, 15
  move $a0, $s1
  la $a1, ff_msg
  li $a2, 21
  syscall

  la $t4, bins_array
 
  la $t5, one_float           
  l.s $f12, 0($t5)
  l.s $f2, 0($t5)              

  # Counter to fill the bins 
  li $t6, 25                    

  fill_bins1:
    beq $t6, $zero, filling_done    
    s.s $f12, 0($t4)             
    addi $t4, $t4, 4             
    sub $t6, $t6, 1              
    j fill_bins1            

  filling_done:
  li $t7, 25
  la $t1, bins_free_index
  sw $t7, 0($t1)

  # Load base addresses
  la $t7, zero_float       
  l.s $f4, 0($t7)    # f4 = 0       
  la $t5, items_array       
  la $t6, items_free_index  
  la $t4, bins_array        
  la $t3, bins_free_index   
  lw $t7, 0($t6)            
  li $s0, 1  
  move $t9, $zero                         

  li $v0, 1
  move $a0, $t7
  syscall

  loop_fill:
    beq $t7, $zero, done # array items is empty      
    l.s $f12, 0($t5) # f12 contains the item value       
    la $t4, bins_array      
    lw $t2, 0($t3)            
    move $t8, $t2 # t8 is number of bins         

  inner_bin:
    beq $t8, $zero, create_new_bin_ff # No bins left
    l.s $f11, 0($t4)          
    sub.s $f0, $f11, $f12 # Bin value - item value  
    c.eq.s $f11, $f2
    bc1t inc
    j dont_inc
    inc: 
    addi $t9, $t9, 1 
    dont_inc:
    c.le.s $f4, $f0 # f4 <= f0
    bc1t place_in_bin         

    addi $t4, $t4, 4          
    sub $t8, $t8, 1       
    j inner_bin

  place_in_bin:
    s.s $f0, 0($t4)                  
       
    # Write to output file
    li $v0, 15
    move $a0, $s1
    la $a1, item_str
    li $a2, 6
    syscall

    move $a0, $s0
    jal write_int_to_file 

    li $v0, 15
    move $a0, $s1
    la $a1, bin_str
    li $a2, 8
    syscall

    la $t1, bins_array
    sub $t2, $t4, $t1
    srl $t2, $t2, 2      # $t4 - t1 / 4 to get the index

    move $a0, $t2 # write index to file
    jal write_int_to_file

    li $v0, 15
    move $a0, $s1
    la $a1, newLine
    li $a2, 1
    syscall    

    j next_item

  create_new_bin_ff:
    la $t1, one_float
    l.s $f11, 0($t1)
    sub.s $f0, $f11, $f12
    la $t4, bins_array      
    s.s $f0, 0($t4)
    addi $t9, $t9, 1         

    li $v0, 15
    move $a0, $s1
    la $a1, item_str
    li $a2, 5
    syscall

    move $a0, $s0
    jal write_int_to_file 

    li $v0, 15
    move $a0, $s1
    la $a1, bin_str
    li $a2, 8
    syscall
    
    move $a0, $t2    
    jal write_int_to_file

    li $v0, 15
    move $a0, $s1
    la $a1, newLine
    li $a2, 1
    syscall   

    la $t3, bins_free_index   
    lw $t2, 0($t3)
    addi $t2, $t2, 1
    sw $t2, 0($t3) # Store it in the free bins index array 
    j next_item

  next_item:
    addi $s0, $s0, 1 # Increment item number
    addi $t5, $t5, 4 # Item index
    sub $t7, $t7, 1 # Decrement number of items
    j loop_fill

  done:
  # write results to output file
    li $v0, 15
    move $a0, $s1
    la $a1, total_bins_str
    li $a2, 19
    syscall

    move $a0, $t9
    jal write_int_to_file

    li $v0, 15
    move $a0, $s1
    la $a1, newLine
    li $a2, 1
    syscall

    # close file
    li $v0, 16
    move $a0, $s1
    syscall

    j loop # Return to main

## Function to run Best-Fit algorithm
best_fit:
  # initialize bins to capacity of 1
  jal initialize_bins
  
  # open output file for writing of results
  li $v0, 13
  la $a0, output_file
  li $a1, 1 # read mode
  syscall
  move $s1, $v0 # file descriptor in s4
  # write to file
  li $v0, 15
  move $a0, $s1
  la $a1, bf_msg
  li $a2, 21
  syscall

  la $t0, items_array
  la $t1, items_free_index
  lw $t2, 0($t1) # t2 = number of items in array
  move $t9, $zero # t9 is item index

  beq $t2, $zero, empty_array # make sure array is not empty
  
  # iterate through items to put in bins
  items_loop:
    beq $t2, $zero, stop_items_loop # all items gone through
    l.s $f0, 0($t0) # current item in f0
    
    li $v0, 4
    la $a0, item_str
    syscall
    mov.s $f12, $f0
    li $v0, 2
    syscall
    
    # write to file
    li $v0, 15
    move $a0, $s1
    la $a1, item_str
    li $a2, 6
    syscall
    move $a0, $t9
    jal write_int_to_file
    
    la $t3, two_float
    l.s $f1, 0($t3) # f1 is min_capacity
    li $t4, -1 # t4 is min_index
    move $t8, $zero # t8 is current index in bins array
    
    la $t5, bins_array
    la $t6, bins_count
    lw $t7, 0($t6)
    # choose the best fit bin
    bins_loop:
      beqz $t7, stop_bins_loop
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
    bgt $t4, -1, available_bin
    
    # no available bin
    create_new_bin:
    la $t5, bins_array # reload address
    la $t6, bins_count
    lw $t7, 0($t6) # reload number of bins
    move $t4, $t7 # new bin is min index
    mul $t8, $t7, 4
    add $t5, $t5, $t8 # address of newly created bin
    # put item in bin
    l.s $f4, one_float
    sub.s $f3, $f4, $f0
    s.s $f3, 0($t5)

    addi $t7, $t7, 1 # increment bins count
    sw $t7, bins_count
    j passed
    
    available_bin:
    # put item in best fitted bin
    la $t5, bins_array # reload address
    mul $t6, $t4, 4
    add $t5, $t5, $t6 # address of best-fit bin
    sub.s $f3, $f1, $f0 # place item in bin
    s.s $f3, 0($t5) # update bin capacity
    
    passed:
    li $v0, 4
    la $a0, bin_str
    syscall
    move $a0, $t4
    li $v0, 1
    syscall
    
    # write to file
    li $v0, 15
    move $a0, $s1
    la $a1, bin_str
    li $a2, 8
    syscall
    move $a0, $t4
    jal write_int_to_file 
    
    jal print_bins_array
    li $v0, 4
    la $a0, newLine
    syscall
    
    addi $t0, $t0, 4 # move to the next item
    subi $t2, $t2, 1 # remaining items
    addi $t9, $t9, 1 # increment index tracker
    j items_loop
    
  stop_items_loop: # all items are placed into bins
  
  li $v0, 4
  la $a0, total_bins_str
  syscall
  la $a0, bins_count
  li $v0, 1
  lw $s7, 0($a0)
  move $a0, $s7
  syscall
  
  # write to file
  li $v0, 15
  move $a0, $s1
  la $a1, total_bins_str
  li $a2, 19
  syscall
  move $a0, $s7
  jal write_int_to_file 
  
  # close output file
  li $v0, 16
  move $a0, $s7
  syscall
  
  j loop
  
## Function to write integers into file
write_int_to_file:
    li $s6, 10
    divu $a0, $s6
    mflo $s2 # tens
    mfhi $s3 # ones

    la $s4, output_buffer
    move $s5, $s4 # pointer for writing

    beqz $s2, skip_tens_char
    addi $s2, $s2, 48 # convert tens to ASCII
    sb $s2, 0($s5)
    addi $s5, $s5, 1
    
    skip_tens_char:
    addi $s3, $s3, 48 # convert ones to ASCII
    sb $s3, 0($s5)
    addi $s5, $s5, 1
    
    subu $a2, $s5, $s4 # length
    move $a0, $s1           
    move $a1, $s4           
    li $v0, 15              
    syscall

    jr $ra

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

## Function to print bins in the array
print_bins_array:
  li $v0, 4
  la $a0, newLine
  syscall
  
  la $t5, bins_array
  la $t6, bins_count
  lw $t7, 0($t6) # t7 is number of bins in the array

  # loop to print each element in the array
  print_bins_loop:
    # Check if we have printed all elements
    beq $t7, $zero, done_printing_bins

    # Load the current element from the array into $f12 (for printing)
    l.s $f12, 0($t5)       # Load the floating-point number at $t0 into $f12
    l.s $f11, zero_float
    c.le.s $f11, $f12
    bc1t print
    mov.s $f12, $f11

    print:
      li $v0, 2
      syscall

      li $v0, 4
      la $a0, space
      syscall
        
    # move to next bin
    addi $t5, $t5, 4
    sub $t7, $t7, 1

    j print_bins_loop

    done_printing_bins:
    jr $ra

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