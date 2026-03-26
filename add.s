global _start

section .text
_start:   
    mov rax, 5   
    mov rbx, 3    

    add rax, rbx   
       
    mov rax, 60     
    mov rdi, 0      
    syscall