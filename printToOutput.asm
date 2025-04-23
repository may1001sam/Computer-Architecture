.data 
output_filename: .asciiz "C:/Users/SS/ENCS4370-Computer-Architecture/output.txt"
item_str: .asciiz "print"


.text
  .globl main
  
## Main Function to run the program
main:
      # Open the output file for writing 
    li $v0, 13               # sys_open 
    la $a0, output_filename  # Address of file name (e.g., "output.txt")
    li $a1, 1               
    syscall
    move $s1, $v0            # Store file descriptor in $s1
    
    
    
# Write the string "Item" to the file
li $v0, 15   	            # sys_write
move $a0, $s1            # File descriptor
la $a1, item_str         # Load address of "Item" string
li $a2, 20                # Length of the string "Item"
syscall
