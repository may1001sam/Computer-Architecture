# Project 1: Bin Packing Solver
# Partners: 
#	Maysam Habbash - 1220075
#	Raghad Jamhour - 1220212
# Section: 1

.data
  # data in memory
  promptFileName: .asciiz "Enter file name:\n"
  fileName: .space 10
  
.text
  .globl main
  
  # Main function to run the program
  main:
    
    # prompt user to input file name
    li $v0, 4
    la $a0, promptFileName
    syscall
    
    # read file name from user
    la $a0, fileName
    li $a1, 10
    li $v0, 8
    syscall

    # return from main
    li $v0, 10
    syscall
   
  # Function to display menu on screen
  displayMenu:
  
    jr $ra
  
  # Function to validate input file
  validateFile:
  
    jr $ra
  