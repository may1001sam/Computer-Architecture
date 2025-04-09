.data
prompt: .asciiz "Enter file name: "
exists:     .asciiz "File exists.\n"
not_exists: .asciiz "File does not exist.\n"
filename: .space 100   # buffer to store user input filename

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
    	
read_loop:
    # --- Read line from file ---
    li $v0, 14
    move $a0, $s0       # file descriptor
    la $a1, buffer      # where to store line
    li $a2, 32          # max bytes
    syscall
    beq $v0, -1, exit   # if EOF, exit

    # --- Try reading a float from the buffer ---
    la $a0, buffer
    li $v0, 6           # syscall: read float
    syscall
    mov.s $f12, $f0     # move result to $f12

    # --- Check if float > 0 ---
    li.s $f1, 0.0
    c.le.s $f12, $f1    # if $f12 <= 0 → invalid
    bc1t print_invalid

    # --- Check if float < 1 ---
    li.s $f2, 1.0
    c.lt.s $f12, $f2    # if $f12 < 1 → valid
    bc1t print_valid

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
    move $a0, $v0      # file descriptor
    li $v0, 16         # syscall to close
    syscall

done:
    li $v0, 10 #exit program
    syscall
