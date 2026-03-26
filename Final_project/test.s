global _start
section .data
    prompt db "Enter statement: "
    promptLen equ $-prompt




    errMsg db "Error: out of range", 10
    errLen equ $-errMsg




section .bss
    input resb 50




section .text
_start:




; print prompt
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt
    mov rdx, promptLen
    syscall




; read input
    mov rax, 0
    mov rdi, 0
    mov rsi, input
    mov rdx, 50
    syscall




; -------------------------
; parse operand1
; -------------------------
    mov rsi, input
    mov rax, 0




p1:
    mov bl, [rsi]




    cmp bl, '-'        ;  FIX 1: กันติดลบ
    je error




    cmp bl, '0'
    jl p1_end
    cmp bl, '9'
    jg p1_end




    sub bl, '0'
    movzx rbx, bl
    imul rax, rax, 10
    add rax, rbx




    add rsi, 1
    jmp p1




p1_end:
    cmp rax, 9999
    jg error
    mov r8, rax




; skip space
skip1:
    cmp byte [rsi], ' '
    jne op
    add rsi, 1
    jmp skip1




; operator
op:
    mov r9b, [rsi]
    add rsi, 1




; skip space
skip2:
    cmp byte [rsi], ' '
    jne p2
    add rsi, 1
    jmp skip2




; -------------------------
; parse operand2
; -------------------------
p2:
    mov rax, 0




p2_loop:
    mov bl, [rsi]




    cmp bl, '-'        ;  FIX 2: กันติดลบ
    je error




    cmp bl, '0'
    jl p2_end
    cmp bl, '9'
    jg p2_end




    sub bl, '0'
    movzx rbx, bl
    imul rax, rax, 10
    add rax, rbx




    add rsi, 1
    jmp p2_loop




p2_end:
    cmp rax, 9999
    jg error
    mov r10, rax




; -------------------------
; calculate
; -------------------------
    mov rax, r8




    cmp r9b, '+'
    je addi
    cmp r9b, '-'
    je subi
    cmp r9b, '*'
    je muli
    cmp r9b, '/'
    je divi




addi:
    add rax, r10
    jmp done




subi:
    sub rax, r10
    jmp done




muli:
    imul rax, r10
    jmp done




divi:
    mov rdx, 0
    div r10




done:
    cmp rax, 0          ;  FIX 3: กันผลลัพธ์ติดลบ
    jl error




    cmp rax, 9999
    jg error




; -------------------------
; convert result to string
; -------------------------
    mov rbx, 10
    mov rcx, 0
    mov rdi, input
    mov r11, rdi




conv:
    mov rdx, 0
    div rbx
    add rdx, '0'
    push rdx
    add rcx, 1
    cmp rax, 0
    jne conv




outt:
    pop rax
    mov [rdi], al
    add rdi, 1
    loop outt




    mov byte [rdi], 10
    add rdi, 1




; print result
    mov rax, 1
    mov rsi, r11
    mov rdx, rdi
    sub rdx, r11
    mov rdi, 1
    syscall




    jmp exit




; -------------------------
; error handler
; -------------------------
error:
    mov rax, 1
    mov rdi, 1
    mov rsi, errMsg
    mov rdx, errLen
    syscall




; exit
exit:
    mov rax, 60
    mov rdi, 0
    syscall



