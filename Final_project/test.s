section .data
    ; --- Messages to display on the screen ---
    prompt      db "Enter statement : "
    prompt_len  equ $ - prompt
    
    ; --- Error message for numbers outside the 0-9999 range ---
    err_msg     db "Error: Out of range (0-9999 only)", 10
    err_len     equ $ - err_msg
    
    ; --- System Call codes for x86-64 Linux ---
    SYS_READ    equ 0
    SYS_WRITE   equ 1
    SYS_EXIT    equ 60
    STDIN       equ 0
    STDOUT      equ 1

section .bss
    ; --- Uninitialized variables (Memory buffers) ---
    in_buf      resb 100    ; Buffer to store raw keyboard input (100 bytes)
    out_buf     resb 20     ; Buffer to store the output string before printing
    op1         resq 1      ; Variable to store Operand 1 as an integer (64-bit)
    op2         resq 1      ; Variable to store Operand 2 as an integer (64-bit)
    operator    resb 1      ; Variable to store the operator character (+, -, *, /)

section .text
    global _start

_start:
    ; 1. Print the prompt "Enter statement : "
    mov rax, SYS_WRITE      ; System call number for sys_write
    mov rdi, STDOUT         ; File descriptor 1 (Standard Output)
    mov rsi, prompt         ; Pointer to the string to print
    mov rdx, prompt_len     ; Length of the string
    syscall

    ; 2. Read the entire user input into in_buf
    mov rax, SYS_READ       ; System call number for sys_read
    mov rdi, STDIN          ; File descriptor 0 (Standard Input)
    mov rsi, in_buf         ; Pointer to the input buffer
    mov rdx, 100            ; Maximum number of bytes to read
    syscall

    ; 3. Parsing Phase (Extracting data from the string)
    mov rsi, in_buf         ; Set rsi as the pointer to the start of the input string

    ; --- Parse Operand 1 ---
    call skip_spaces        ; Ignore any leading spaces
    call parse_number       ; Convert the ASCII number to an integer
    cmp rax, 9999           ; Validate: Is Operand 1 greater than 9999?
    jg .out_of_range        ; If yes (Jump if Greater), go to error handler
    mov [op1], rax          ; Store the integer result into op1

    ; --- Parse the Operator ---
    call skip_spaces        ; Ignore any spaces before the operator
    mov cl, byte [rsi]      ; Fetch 1 byte (the operator character: +, -, *, or /)
    mov [operator], cl      ; Store the character into the operator variable
    inc rsi                 ; Move the pointer to the next character

    ; --- Parse Operand 2 ---
    call skip_spaces        ; Ignore any spaces after the operator
    call parse_number       ; Convert the ASCII number to an integer
    cmp rax, 9999           ; Validate: Is Operand 2 greater than 9999?
    jg .out_of_range        ; If yes, go to error handler
    mov [op2], rax          ; Store the integer result into op2

    ; 4. Calculation Phase (Performing the math)
    mov al, [operator]      ; Load the operator character into al
    cmp al, '+'             ; Compare with '+'
    je .do_add              ; Jump if equal to .do_add
    cmp al, '-'
    je .do_sub
    cmp al, '*'
    je .do_mul
    cmp al, '/'
    je .do_div
    jmp .exit_program       ; If invalid operator, exit the program safely

.do_add:
    mov rax, [op1]
    add rax, [op2]          ; rax = op1 + op2
    jmp .validate_result    ; Jump to validate the final result

.do_sub:
    mov rax, [op1]
    sub rax, [op2]          ; rax = op1 - op2
    jmp .validate_result

.do_mul:
    mov rax, [op1]
    imul rax, [op2]         ; rax = op1 * op2 (Signed multiplication)
    jmp .validate_result

.do_div:
    mov rax, [op1]          ; Dividend (lower 64 bits) in rax
    mov rdx, 0              ; Critical: Clear rdx before division (Dividend upper 64 bits = 0)
    mov r8, [op2]           ; Move divisor into r8
    cmp r8, 0               ; Validate: Prevent division by zero
    je .out_of_range        ; If divisor is 0, go to error handler
    div r8                  ; Unsigned division: rdx:rax / r8. Quotient goes to rax.
    jmp .validate_result

    ; 5. Validate Result and Print
.validate_result:
    cmp rax, 0              ; Check if the result is less than 0 (negative)
    jl .out_of_range        ; If less (Jump if Less), go to error handler
    cmp rax, 9999           ; Check if the result is greater than 9999
    jg .out_of_range        ; If greater, go to error handler

.print_result:
    call int_to_string      ; Pass the validated result in rax to the string conversion function
    
    ; The function returns with rsi pointing to the string and rdx containing the length
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall                 ; Print the final answer!
    jmp .exit_program       ; Skip the error message and exit

    ; --- Error Handling Section ---
.out_of_range:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, err_msg
    mov rdx, err_len
    syscall                 ; Print the "Out of range" error message

.exit_program:
    mov rax, SYS_EXIT       ; System call for exit
    mov rdi, 0              ; Exit code 0 (Success)
    syscall

; Subprograms (Functions)

; --- Function: Skip Spaces ---
; Description: Advances the rsi pointer past any ASCII space characters (32).
skip_spaces:
.loop_skip:
    cmp byte [rsi], ' '     ; Check if the current character is a space
    jne .done_skip          ; If not a space, break the loop
    inc rsi                 ; If it is a space, advance the pointer by 1
    jmp .loop_skip          ; Repeat the check
.done_skip:
    ret                     ; Return to caller

; --- Function: Parse Number (String to Integer) ---
; Input: rsi (Pointer to the string)
; Output: rax (Calculated integer value)
parse_number:
    mov rax, 0              ; Initialize accumulator for the total value to 0
    mov rcx, 0              ; Initialize temporary register to 0
.loop_parse:
    mov cl, byte [rsi]      ; Load the current character into cl
    cmp cl, '0'
    jl .done_parse          ; If character < '0', it's not a digit, stop parsing
    cmp cl, '9'
    jg .done_parse          ; If character > '9', it's not a digit, stop parsing
    
    sub cl, '0'             ; Convert ASCII character to actual integer value
    imul rax, 10            ; Multiply the running total by 10 (shift digits left)
    add rax, rcx            ; Add the new integer value to the units place
    inc rsi                 ; Advance the pointer to the next character
    jmp .loop_parse
.done_parse:
    ret

; --- Function: Integer to String ---
; Input: rax (Integer to convert)
; Output: rsi (Pointer to the resulting string), rdx (Length of the string)
int_to_string:
    mov rdi, out_buf + 19   ; Point rdi to the END of the output buffer (we write backwards)
    mov byte [rdi], 10      ; Place a Newline character (Line Feed) at the very end
    mov rcx, 1              ; Initialize string length counter (starts at 1 for the newline)
    mov r8, 10              ; The divisor (Base 10)
.loop_itoa:
    mov rdx, 0              ; Clear rdx before dividing (Remainder will be stored here)
    div r8                  ; Divide rax by 10. Quotient in rax, Remainder in rdx
    add dl, '0'             ; Convert the remainder (0-9) back into an ASCII character ('0'-'9')
    dec rdi                 ; Move the buffer pointer backwards by 1 byte
    mov byte [rdi], dl      ; Store the ASCII character in the buffer
    inc rcx                 ; Increment the string length
    cmp rax, 0              ; Check if the quotient is 0 (no more digits left)
    jne .loop_itoa          ; If not 0, loop and process the next digit
    
    mov rsi, rdi            ; Set rsi to the starting point of the generated string
    mov rdx, rcx            ; Set rdx to the calculated string length
    ret