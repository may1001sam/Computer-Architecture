.data
prompt: .asciiz "Enter file name: "
exists:     .asciiz "File exists.\n"
not_exists: .asciiz "File does not exist.\n"
filename: .space 100   # buffer to store user input filename
line_buffer: .space 50
newLine: .asciiz "\n"
valid_msg: .asciiz "File is valid\n"
invalid_msg: .asciiz "File is invalid\n"

.text
.globl main

main:
    # Prompt user
    li $v0, 4
    la $a0, prompt
    syscall

    # Read filename from user
    li $v0, 8
    la $a0, filename
    li $a1, 100        # max input size
    syscall

    # Remove newline (optional cleanup)
    # We'll just replace the newline with null terminator if present
    la $t0, filename       # pointer to filename
    
clean_loop:
    lb $t1, 0($t0)
    beq $t1, 10, replace_newline  # newline char?
    beqz $t1, end_clean           # end of string?
    addi $t0, $t0, 1
    j clean_loop

replace_newline:
    sb $zero, 0($t0)  # replace newline with null
    
end_clean:

    # Try opening the file
    li $v0, 13         # syscall to open file
    la $a0, filename
    li $a1, 0          # 0 = read mode
    li $a2, 0          # mode = ignored
    syscall
    move $s0, $v0


	## Validate file existance and path correctness
    # Check if open failed
    li $t0, -1
    beq $v0, $t0, file_not_found

    # File opened successfully
    li $v0, 4
    la $a0, exists
    syscall
    j close_file
    
    	## Validate content of the file
    # start reading lines into buffer
    fileReader_loop:
      li $v0, 14		#read line
      move $a0, $s0
      la $a1, line_buffer	#store line in buffer
      li $a2, 50         # max buffer size
      syscall
      
      bltz $v0, close_file   # EOF reached
      
      li $v0, 4               # syscall: print string
      la $a0, line_buffer
      syscall

      # Optional: Print a newline (for clean output)
      li $v0, 4
      la $a0, newLine
      syscall

      j fileReader_loop

print_invalid:
    li $v0, 4
    la $a0, invalid_msg
    syscall
    j read_loop

print_valid:
    li $v0, 4
    la $a0, valid_msg
    syscall
    j read_loop

exit:
    li $v0, 10
    syscall

file_not_found:
    li $v0, 4
    la $a0, not_exists
    syscall
    j done

close_file:
    # Close the file
    move $a0, $s0      # file descriptor
    li $v0, 16         # syscall to close
    syscall

done:
    li $v0, 10 #exit program
    syscall
