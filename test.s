global _start

section .text
_start:
    mov rax, 7
    mov rbx, 4
    mul rbx

    mov rax, 60
    mov rdi, 0
    syscall