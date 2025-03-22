# Project 1: Bin Packing Solver
# Partners: 
#	Maysam Habbash - 1220075
#	Raghad Jamhour - 1220212
# Section: 1

.data
  # data in memory
  startMessage: .asciiz "Bin Packing Solver\n\n"
  menu: .asciiz "Choose an operation:\n 1. Enter file name or path.\n 2. Choose Heuristic: FF or BF.\n 3. exit.\n"
  promptFileName: .asciiz "Enter file name:\n"
  invalidMessage: .asciiz "No Such Operation!\n"
  invalidFileMsg: .asciiz "Error Opening File.\n"
  fileName: .space 10
  
.text
  .globl main
  
  # Main function to run the program
  main:
    li $v0, 4
    la $a0, startMessage
    syscall
    
   loop:
   # Display menu
    li $v0, 4
    la $a0 menu
    syscall
    
    # read operation
    li $v0, 5   
    syscall
    move $t0, $v0  

   # Switch-case 
    beq $t0, 1, readFile
    beq $t0, 2, FForBF
    beq $t0, 3, exit
    j invalidOperation  
    
   # Handle invalid operations 
  invalidOperation:
    li $v0, 4
    la $a0, invalidMessage
    syscall
    j loop  
  
  
  # Function to validate input file
  readFile:
    # prompt user to input file name
    li $v0, 4
    la $a0, promptFileName
    syscall
    
    # read file name from user
    la $a0, fileName
    li $a1, 10
    li $v0, 8
    syscall
    
    # Open file
    li $v0, 13
    la $a0, fileName
    syscall
    
    
    bltz $v0, invalidFile     
    # return from function
    j loop
  
    # File does not exist 
 invalidFile:
   li $v0,4
   la $a0, invalidFileMsg
   syscall
               
 FForBF:
 
    # Exit the program
 exit:      
    li $v0, 10
    syscall          
  