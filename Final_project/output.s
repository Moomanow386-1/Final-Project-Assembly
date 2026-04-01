global output_func
extern num1
extern num2
extern operator_p

section .data

;reserving space for variables.
section .bss    
	operand1 resq 1    ;input 1
	operand2 resq 1    ;input 2
	operator resb 1    ;operator +,-,*,/
	result   resq 1    ;save_result
	output   resb 50   ;keep info to screen output
section .text
output_func:

    mov r12, qword[num1]
    mov qword[operand1], r12
    mov r12, qword[num2]
    mov qword[operand2], r12
    mov r12b, byte[operator_p]
    mov byte[operator], r12b

operating:	
	mov rax, qword[operand1]
	cmp rax, 0
	jl exit_program
    
    cmp rax, 9999
    jg exit_program
   
	mov rbx, qword[operand2]
	cmp rbx,0
	jl exit_program

    cmp rbx, 9999
    jg exit_program

	mov cl,  byte[operator]

	;switch operator +,-,*,/
	cmp cl, '+'
	je add_function
	cmp cl, '-'
	je sub_function
	cmp cl, '*'
	je mul_function
	cmp cl, '/'
	je div_function

add_function:
	add rax, rbx
    cmp rax, 9999
    jg exit_program
	jmp save_result

sub_function:
	;Jump if Less
	cmp rax, rbx
	jl exit_program

	sub rax, rbx
	jmp save_result

mul_function:
	imul rax, rbx
    cmp rax, 9999
    jg exit_program
	jmp save_result

div_function:
	mov rdx, 0
	div rbx
	jmp save_result

save_result:
	mov qword[result], rax

	mov r8, 10            ; Set the divisor to 10
        mov r9, 0             ; r9 = digit counter
        mov rdi, output       ; rdi points output

convert_loop:
        mov rdx, 0            ; clear rdx
        div r8                ; Divide rax by 10 (quotient in rax, remainder in rdx)
        add dl, '0'           ; Add '0' (48) to the remainder to convert it to an ASCII character
        push rdx              ; Push the remainder onto the Stack
        inc r9                ; Increment the digit counter by 1
        cmp rax, 0            ; Check if the quotient is 0
        jne convert_loop      ; If not, loop back to continue dividing

pop_loop:
        pop rdx               ; Pop the remainder from the Stack (digits will be in the correct order)
        mov byte [rdi], dl    ; Store the character into the output buffer
        inc rdi               ; Move the buffer pointer to the next position
        dec r9                ; Decrement the digit counter
        cmp r9, 0
        jg pop_loop           ; If not all digits are popped, continue looping

        mov byte [rdi], 10    ; Append a newline character (ASCII 10) at the end
        inc rdi               ; Now rdi points to the exact end of the string

        ;print
        mov rax, 1            ;SYS_write   
        mov rsi, output       
        mov rdx, rdi          
        sub rdx, output       
        mov rdi, 1            ;STDOUT (monitor)       
        syscall               

exit_program:
    ret






