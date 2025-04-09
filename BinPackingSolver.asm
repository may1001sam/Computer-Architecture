# Project 1: Bin Packing Solver
# Partners: 
#	Maysam Habbash - 1220075
#	Raghad Jamhour - 1220212
# Section: 1

.data
  # data in memory
  start_msg: .asciiz "Bin Packing Solver\n\n"
  menu: .asciiz "Choose an operation:\n 1. Enter file name to upload.\n 2. Choose Heuristic: FF or BF.\n 3. Enter q to quit the program.\n"
  prompt_fileName_msg: .asciiz "Enter file name:\n"
  invalid_option_msg: .asciiz "No Such Option!\n"
  invalid_file_msg: .asciiz "Invalid file name.\n"
  fileName: .space 100
  success_fileOpen_msg: .asciiz "File uploaded successfully.\n"
  newLine: .asciiz "\n"
  
.text
  .globl main
  
  # Main function to run the program
  main:
    li $v0, 4
    la $a0, start_msg
    syscall
    
    # loop to keep the program running
    loop:
      #li $v0, 4
      #la $a0, newLine
      #syscall
    
      # Display menu
      li $v0, 4
      la $a0 menu
      syscall
    
      # read user's option
      li $v0, 5   
      syscall
      move $t0, $v0  

      # service user's option 
      beq $t0, 1, read_file
      beq $t0, 2, FForBF
      beq $t0, 3, quit
      j invalid_option 
    
  # Handle invalid operations 
  invalid_option:
    li $v0, 4
    la $a0, invalid_option_msg
    syscall
    j loop  
  
  # Function to operate reading file option
  read_file:
    # prompt user to input file name
    li $v0, 4
    la $a0, prompt_fileName_msg
    syscall
    
    # read file name from user
    la $a0, fileName
    li $a1, 100
    li $v0, 8
    syscall

    la $t0, fileName
    
    clean_string_loop:
      lb $t1, 0($t0)	# load char in file name
      beq $t1, 10, replace_newline	# if char is new line, replace it
      beqz $t1, string_cleaned	# end of string reached
      addi $t0, $t0, 1	# move string pointer to the next char
      j clean_string_loop

    replace_newline:
      sb $zero, 0($t0)  # replace newline char with null
    
    string_cleaned:	# File name is clean to be verified
  
    # Try opening the file
    li $v0, 13
    la $a0, fileName
    li $a1, 0	# open file in read mode
    li $a2, 0	# mode = ignored
    syscall

    # Check if open failed
    li $t0, -1
    beq $v0, $t0, invalid_file

    # File opened successfully
    li $v0, 4
    la $a0, success_fileOpen_msg
    syscall
    
    j close_file
    # return from function
    #j loop
  
   # File does not exist 
   invalid_file:
     li $v0,4
     la $a0, invalid_file_msg
     syscall
     j loop
   
   close_file:
     move $a0, $v0	# file descriptor
     li $v0, 16
     syscall
     j loop
 
  FForBF:
 
  # Quit the program
  quit:   
    li $v0, 10
    syscall          
  
