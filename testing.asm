.data
prompt:     .asciiz "Enter file name: "
exists:     .asciiz "File exists.\n"
not_exists: .asciiz "File does not exist.\n"
filename:   .space 100   # buffer to store user input filename

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

    # Check if open failed
    li $t0, -1
    beq $v0, $t0, file_not_found

    # File opened successfully
    li $v0, 4
    la $a0, exists
    syscall
    j close_file

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
    li $v0, 10
    syscall
