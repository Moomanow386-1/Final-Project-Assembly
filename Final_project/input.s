global input_func
global clean

section .data
  prompt db "Enter statement: "
  promptLen equ $-prompt

  errMsg db "Error: invalid input", 10
  errLen equ $-errMsg

  SYS_write equ 1
  SYS_read equ 0

  STD_write equ 1
  STD_read equ 0

  maxInput equ 50

  Enter_ASCII equ 10
  Null_ASCII equ 0
  Space_ASCII equ 32
  Zero_ASCII equ 48
  Nine_ASCII equ 57
  Plus_ASCII equ 43
  Minus_ASCII equ 45
  Mul_ASCII equ 42
  Div_ASCII equ 47
 
section .bss
  input resb 50
  clean resb 50

section .text
input_func:

; main loop
input_start:

; print prompt
  mov rax, SYS_write              
  mov rdi, STD_write            
  mov rsi, prompt
  mov rdx, promptLen
  syscall              

; read input
  mov rax, SYS_read          
  mov rdi, STD_read  
  mov rsi, input        
  mov rdx, maxInput          
  syscall              

; check overflow buffer (case>buffer)
  cmp rax, maxInput
  jb ok_read

;Delete overflow buffer
  flush_loop:
    mov rax, SYS_read
    mov rdi, STD_read
    mov rsi, input
    mov rdx, 1
    syscall

    ; if != /n
    cmp byte [input], Enter_ASCII
    jne flush_loop

; loop read input
ok_read:

  ;check buffer overflow (case==buffer full but no \n)
  cmp rax, maxInput          
  je error_input        

;set pointers
  mov rsi, input      
  mov rdi, clean  

;reset registers == 0
  xor rcx, rcx
  xor rbx, rbx

;loop check case input
clean_loop:
  ;read char
  mov al, byte [rsi]

;case char = Enter(/n)
  cmp al, Enter_ASCII
  je done_check          

;case char = null
  cmp al, Null_ASCII
  je done_check

;case char = space
  cmp al, Space_ASCII            
  je skip_char        

;case char = digit range '0'-'9' ASCII 48-57
  cmp al, Zero_ASCII          
  jb check_operator  ; >'0' go to operator
  cmp al, Nine_ASCII
  jbe is_digit       ; <= '9' go to digit

;case char = operator + - * /
check_operator:
  cmp al, Plus_ASCII
  je is_operator
  cmp al, Minus_ASCII
  je is_operator
  cmp al, Mul_ASCII
  je is_operator
  cmp al, Div_ASCII
  je is_operator

  ;other char = error
  jmp error_input        

; digit
is_digit:
  inc rbx            
  jmp copy_char          

; operator
is_operator:
  inc rcx    
  ;check operator must be only 1          
  cmp rcx, 1
  ja error_input        

; copy char to clean
copy_char:
  mov byte [rdi], al  
  inc rdi              

;next char because space
skip_char:
  inc rsi            
  jmp clean_loop        

;loop check end
done_check:

;check operator must be only 1
  cmp rcx, 1
  jne error_input

;check digit must be at least 2
  cmp rbx, 2
  jb error_input

;check space only
  mov rax, rdi          
  sub rax, clean    
  cmp rax, 0
  je error_input

; check operator position first
  mov al, byte [clean]
  cmp al, Plus_ASCII
  je error_input
  cmp al, Minus_ASCII
  je error_input
  cmp al, Mul_ASCII
  je error_input
  cmp al, Div_ASCII
  je error_input

; check operator position last
  mov rax, rdi            
  dec rax                ; point to last char
  mov al, byte [rax]
  cmp al, Plus_ASCII
  je error_input
  cmp al, Minus_ASCII
  je error_input
  cmp al, Mul_ASCII
  je error_input
  cmp al, Div_ASCII
  je error_input

; null terminate clean string
mov byte [rdi], 0

; DEBUG print clean string
mov rax, SYS_write
mov rdi, STD_write
mov rsi, clean    
mov rdx, maxInput
syscall

ret

; ERROR case, print error message and loop back to input
error_input:
  mov rax, SYS_write    
  mov rdi, STD_write    
  mov rsi, errMsg         ; error message
  mov rdx, errLen
  syscall

  jmp input_start


